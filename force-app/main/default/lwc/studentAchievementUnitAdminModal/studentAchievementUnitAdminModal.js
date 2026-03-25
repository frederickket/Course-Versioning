/**
 * @Author 		WDCi (XW)
 * @Date 		Jan 2026
 * @group 		Student Achievement
 * @Description Student Achievement modal to edit unit as admin
 * @changehistory
 * ISS-002633 09-01-2026 XW - new component
 */
import { LightningElement, api, wire, track } from 'lwc';
import { promptInfo, promptError, promptWarning, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';
import { initCacheIdx, extractFieldValue, commonConstants, getFileDownloadUrl } from 'c/lwcUtil';
import { getFieldValue, getRecord, notifyRecordUpdateAvailable, deleteRecord } from 'lightning/uiRecordApi';
import { customLabels } from 'c/labelLoader';
import LightningModal from 'lightning/modal';
import LANG from '@salesforce/i18n/lang';
import recordEditModal from 'c/recordEditModal';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import genericConfirmationModal from 'c/genericConfirmationModal';

import ARU_OBJ from '@salesforce/schema/Agreement_Recognition_Unit__c'
import IAU_OBJ from '@salesforce/schema/Individual_Achievement_Unit__c'
import IAU_VERIFICATION_STATUS_FIELD from '@salesforce/schema/Individual_Achievement_Unit__c.Verification_Status__c'
import IAC_AGREEMENT_RECOGNITION_FIELD from '@salesforce/schema/Individual_Achievement__c.Agreement_Recognition__c'

import { RefreshEvent, registerRefreshContainer, unregisterRefreshContainer } from 'lightning/refresh';
import { refreshApex } from '@salesforce/apex';

//Apex methods
import ctrlGetFieldSet from '@salesforce/apex/REDU_StudentAchievement_LCTRL.getFieldSet';
import ctrlGetAgreementRecognitionUnit from '@salesforce/apex/REDU_StudentAchievementUnitAdmin_LCTRL.getAgreementRecognitionUnit';
import ctrlGetTranslationFieldForName from '@salesforce/apex/REDU_Translation_LCTRL.getTranslationFieldForNameByObjPrefix';
import ctrlGetExistingUploadedFiles from '@salesforce/apex/REDU_StudentAchievementUnitAdmin_LCTRL.getExistingUploadedFiles';
import ctrlGetIndividualRequirementWrappers from '@salesforce/apex/REDU_StudentAchievementUnitAdmin_LCTRL.getIndividualRequirementWrappers';

//label
import DETAILS_LABEL from '@salesforce/label/c.Student_Achievement_Details';
import VERIFICATION_DETAILS_LABEL from '@salesforce/label/c.Student_Achievement_Verification_Details';
import OPTIONS_LABEL from '@salesforce/label/c.Options';
import UNIT_NAME_LABEL from '@salesforce/label/c.Student_Achievement_Unit_Name';
import LINKED_LABEL from '@salesforce/label/c.Student_Achievement_Linked';
import LINK_LABEL from '@salesforce/label/c.Student_Achievement_Link';
import UPLOADED_FILES_LABEL from '@salesforce/label/c.Student_Achievement_Uploaded_Files';
import NO_UPLOADED_FILES_LABEL from '@salesforce/label/c.Student_Achievement_No_Uploaded_Files';
import STUDENT_ACHIEVEMENT_LINKED_SUCCESSFULLY_LABEL from '@salesforce/label/c.Student_Achievement_Linked_Successfully'

const OBJ_TRANSLATION = [
    "ARU"
];

const IRQ_SUBMITTED_STATUS_TYPE_SUBMITTED = 'Submitted';
const IRQ_SUBMITTED_STATUS_TYPE_CANCELLED = 'Cancelled';
const IRQ_REVIEW_STATUS_TYPE_OPEN = 'Open';

const STATUS_ACTIVE = 'Active';

export default class StudentAchievementUnitAdminModal extends LightningModal {
	
	//configurable attributes
    @api modalTitle;

    @api additionalUnitFieldSetName;
    @api unitCodeFallbackField;
    @api unitNameFallbackField;
    @api verificationDetailsFieldSetName;
    @api agreementRecognitionUnitCreationFieldSetName;
    @api individualAchievementId;
    @api individualAchievementUnitId;
    @api aruId;
    @api unitRequired;

	@api enableDebugMode = false;
	
	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false
	loadedLists = 0;
    @track activeAccordion = ["details", "uploadedFiles", "verificationDetails"]

    //local cache idx to force rerendering
    _cacheIdx;
    refreshContainerID;

    @track additionalInfoFieldSetResult;
    @track additionalInfoFieldSetResponse = [];
    @track verificationDetailsFieldsResult;
    @track verificationDetailsFieldsResponse = [];
    @track agreementRecognitionUnitResult;
    @track agreementRecognitionUnitResponse;
    @track objectTranslatedNameResult;
    @track objectTranslatedNameResponse;
    @track individualAchievementUnitRecordResult = {};
    @track individualAchievementUnitRecordResponse = {};
    @track individualAchievementRecordResult = {};
    @track individualAchievementRecordResponse = {};
    @track existingUploadedFilesResult;
    @track existingUploadedFilesResponse = {};
    @track individualRequirementWrappersResult;
    @track individualRequirementWrappersResponse;
    
    @track individualAchievementUnitLookupFieldValue = {};

	
	//js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'jquery', 'tooltips'
    modules = ['stringutil'];

    @wire(getRecord, { recordId: '$individualAchievementId', fields: [IAC_AGREEMENT_RECOGNITION_FIELD] })
    wiredIndividualAchievementRecord(result) {
        this.individualAchievementRecordResult = result;
        this.individualAchievementRecordResponse = null; 

        if(result.data)  {
            this.individualAchievementRecordResponse = result.data;
            this.consoleLog(this.individualAchievementRecordResponse);
        } else if (result.error) {
            promptError(customLabels.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    get individualAchievementAgreementRecognitionId() {
        return getFieldValue(this.individualAchievementRecordResponse, IAC_AGREEMENT_RECOGNITION_FIELD);
    }

    //--------------------------edit form------------------------

    /**
     * @description when a lightning input field has value changed, and there are other input fields that shares the same field name, change their value to be the latest modified value
     */
    handleInputFieldChange(event) {
        let value = event.detail.value;
        let sectionType = event.target.dataset.type;
        let fieldName = event.target.dataset.fieldName;
        let fields = Object.values(this.template.querySelectorAll(`lightning-input-field:not([data-type=${sectionType}])`)).filter(cmp => cmp.fieldName === fieldName);
        if(fields.length > 0) {
            fields.forEach(field => {
                field.value = value
            });
        }
    }

    //----------------------details-------------------------------

    get detailsLabel() {
        return DETAILS_LABEL;
    }
    
    /**
     * @description unit name and unit code fallback field if exists
     */
    get individualAchievementUnitFields() {
        let result = [IAU_VERIFICATION_STATUS_FIELD];
        
        if(this.unitNameFallbackField) {
            result.push(IAU_OBJ.objectApiName + "." + this.unitNameFallbackField);
        }
        if(this.unitCodeFallbackField) {
            result.push(IAU_OBJ.objectApiName + "." + this.unitCodeFallbackField);
        }
        return result;
    }

    /**
     * @description query individual achievement unit based on individualAchievementUnit id
     */
    @wire(getRecord, { recordId: '$individualAchievementUnitId', fields: '$individualAchievementUnitFields' })
    wiredIndividualAchievementUnitRecord(result) {
        this.individualAchievementUnitRecordResult = result;
        this.individualAchievementUnitRecordResponse = null; 

        if(result.data)  {
            this.individualAchievementUnitRecordResponse = result.data;
            this.consoleLog(this.individualAchievementUnitRecordResponse);
        } else if (result.error) {
            promptError(customLabels.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    get unitNameFallbackValue() {
        return getFieldValue(this.individualAchievementUnitRecordResponse, IAU_OBJ.objectApiName + '.' + this.unitNameFallbackField);
    }

    get unitCodeFallbackValue() {
        return getFieldValue(this.individualAchievementUnitRecordResponse, IAU_OBJ.objectApiName + '.' + this.unitCodeFallbackField);
    }

    //-----------------------------------agreement Recognition unit--------------------------

    /**
     * @description get agreement recognition unit name
     */
    get agreementRecognitionUnitName() {
        if(Object.keys(this.agreementRecognitionUnitRecord).includes(this.aruNameTranslationField)) {
            return extractFieldValue(this.agreementRecognitionUnitRecord, this.aruNameTranslationField, this.agreementRecognitionUnitTranslationInfo, this.language);
        }
        return extractFieldValue(this.agreementRecognitionUnitRecord, 'Name', this.agreementRecognitionUnitTranslationInfo, this.language);

    }

    /**
     * @description the agreement recognition unit name displayed in the readonly input
     */
    get agreementRecognitionUnitDisplayValue() {
        return this.agreementRecognitionUnitName ?? this.unitNameFallbackValue;
    }

    get agreementRecognitionUnitLinkButtonDisabled() {
        return this.individualAchievementUnitLookupFieldValue.reduivy__Agreement_Recognition_Unit__c;
    }

    get unitNameLabel() {
        return UNIT_NAME_LABEL;
    }

    get optionsLabel() {
        return OPTIONS_LABEL;
    }

    get linkButtonLabel() {
        return this.agreementRecognitionUnitLinkButtonDisabled ? LINKED_LABEL : LINK_LABEL;
    }

    get newLabel()  {
        return customLabels.NEW_LABEL;
    }

    /**
     * @description query agreement recognition unit so that we can display its name
     */
    @wire(ctrlGetAgreementRecognitionUnit, { aruId: "$aruId", language: "$language" })
    wiredGetAgreementRecognitionUnit(result) {
        this.agreementRecognitionUnitResult = result;
        this.agreementRecognitionUnitResponse = null;

        if (result.data) {
            this.agreementRecognitionUnitResponse = JSON.parse(result.data.responseData);
            this.consoleLog(this.agreementRecognitionUnitResponse, true);
        } else if (result.error) {
            promptError(customLabels.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    get agreementRecognitionUnitRecord() {
        return this.agreementRecognitionUnitResponse?.records?.[0] ?? {};
    }

    get agreementRecognitionUnitTranslationInfo() {
        return this.agreementRecognitionUnitResponse?.translationInfo ?? {};
    }

    /**
    * @description Get Study Unit Translation Name
    */
    @wire(ctrlGetTranslationFieldForName, { objectPrefixes: OBJ_TRANSLATION})
    wiredTranslationFieldResult(result) {
        
        this.objectTranslatedNameResult = result;
        this.objectTranslatedNameResponse = null;

        if (result.data) {
            let response = result.data;
            if (response.responseData) {
                this.objectTranslatedNameResponse = JSON.parse(response.responseData);
            }
            this.consoleLog(this.objectTranslatedNameResponse, true);
            
        } else if (result.error) {
            promptError(customLabels.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    /**
     * @description return the agreement recognition unit translation field for name
     */
    get aruNameTranslationField() {
        return this.objectTranslatedNameResponse?.ARU;
    }

    /**
     * @description set the agreement recognition unit display value (name or fallback value ) to the lookup field
     */
    handleLinkButton(){
        this.consoleLog('handleLinkButton');

        let element = this.template.querySelector(`c-custom-lookup-field[data-type="agreementRecognitionUnit"]`);
        element?.setSearchKeyword(this.agreementRecognitionUnitDisplayValue, true, true);
    }
    
    get agreementRecognitionUnitCustomFilter() {
        let customFilter = 'reduivy__Status__c = :statusActive'
        if(this.individualAchievementAgreementRecognitionId) {
            customFilter += ' AND reduivy__Agreement_Recognition__c = :individualAchievementAgreementRecognitionId';
        }
        return customFilter;
    }

    get agreementRecognitionUnitCustomFilterBindMap() {
        let bindMap = {'statusActive': STATUS_ACTIVE};
        if(this.individualAchievementAgreementRecognitionId) {
            bindMap.individualAchievementAgreementRecognitionId = this.individualAchievementAgreementRecognitionId;
        }
        return bindMap;
    }
    

    /**
     * @description handle when system agreement recognition unit lookup field is changed. set other existing agreement recognition unit lookup field if found.
     */
    async handleAgreementRecognitionUnitLookupChange(event) {
        this.consoleLog('handleAgreementRecognitionUnitLookupChange');
        this.consoleLog(event, true);

        let lookupRecordId = event.detail.value;
        this.individualAchievementUnitLookupFieldValue.reduivy__Agreement_Recognition_Unit__c = lookupRecordId;
        let extraAgreementRecognitionUnitCmpList = Object.values(this.template.querySelectorAll(`c-custom-lookup-field:not([data-type="agreementRecognitionUnit"])`)).filter(cmp => cmp.lookupFieldName === 'reduivy__Agreement_Recognition_Unit__c');
        if(extraAgreementRecognitionUnitCmpList.length > 0){
            extraAgreementRecognitionUnitCmpList.forEach(extraAgreementRecognitionUnitCmp => {
                if(lookupRecordId) {
                    extraAgreementRecognitionUnitCmp.setSelectedRecord(lookupRecordId);
                } else {
                    extraAgreementRecognitionUnitCmp.clear();
                }
            });
        }
    }

    /**
     * @description create new agreement recognition unit
     */
    async handleNewAgreementRecognitionUnitButton() {
        
        let referenceObjectName = ARU_OBJ.objectApiName;
        let referenceObjectLabel = this.aruObjectLabel;
        this.consoleLog(`handleLookupChange: referenceObjectName:${referenceObjectName} - referenceObjectLabel:${referenceObjectLabel}`)

        if(referenceObjectName) {
            try {
                
                let result = await recordEditModal.open({
                    
                    size: "small",
                    headerLabel: customLabels.NEW_RECORD_LABEL.format([referenceObjectLabel]),
                    enableDebugMode: this.enableDebugMode,
                    objectApiName: referenceObjectName,
                    fieldSetName: this.agreementRecognitionUnitCreationFieldSetName,
                    editFormColumnNo: 2,
                    enableNewParentCreation: false,
                    defaultValue: { Name: this.agreementRecognitionUnitDisplayValue }
                });
                this.consoleLog('recordEditModal.close');
                this.consoleLog(result, true);

                if(result) {
                    const { operation, eventResult, eventData } = result;
                    if(operation === 'submit' && eventResult === 'success') {
                        let recordId = eventData.Id;
                        this.consoleLog('recordEditModal.close.recordId = ' + recordId);

                        promptSuccess(customLabels.SUCCESS_LABEL, STUDENT_ACHIEVEMENT_LINKED_SUCCESSFULLY_LABEL.format([referenceObjectLabel]));
                        notifyRecordUpdateAvailable([{recordId: recordId}]);
                        
                        let element = this.template.querySelector(`c-custom-lookup-field[data-type="agreementRecognitionUnit"]`);
                        await element.setSelectedRecord(recordId);
                    }

                }
            } catch(error) {
                promptError(customLabels.ERROR_LABEL, getErrorMessage(error));
            }
        }


    }

    @wire(getObjectInfo, {objectApiName: ARU_OBJ})
    aruObjectInfo;

    get aruObjectLabel() {
        return this.aruObjectInfo?.data?.label;
    }

    //----------------------------------------- unit additional info ------------------------

    /**
     * @description handle when lookup fields in additional details is set. set for others lookup fields with same field name
     */
    handleAdditionalDetailsLookupChange(event) {
        this.consoleLog('handleAdditionalDetailsLookupChange');
        let lookupFieldName = event.detail.lookupFieldName;
    
        let lookupRecordId = event.detail.value;
        this.individualAchievementUnitLookupFieldValue[lookupFieldName] = lookupRecordId;
        let verificationDetailsCmpList = Object.values(this.template.querySelectorAll(`c-custom-lookup-field:not([data-type="additionalInfo"])`)).filter(cmp => cmp.lookupFieldName === lookupFieldName);
        if(verificationDetailsCmpList.length > 0){
            verificationDetailsCmpList.forEach(verificationDetailsCmp => {

                if(lookupRecordId) {
                    verificationDetailsCmp.setSelectedRecord(lookupRecordId);
                } else {
                    verificationDetailsCmp.clear();
                }
            });
        }
        
    }
    
    /**
     * @description get additional field info from field set name
     */
    @wire(ctrlGetFieldSet, {fieldSetName: "$additionalUnitFieldSetName", objectApiName: 'reduivy__Individual_Achievement_Unit__c'}) 
    wiredAdditionalInfoFieldSet(result) {
        this.additionalInfoFieldSetResult = result;
        this.additionalInfoFieldSetResponse = null;
        
        if (result.data) {
            this.additionalInfoFieldSetResponse = JSON.parse(result.data.responseData);
            this.consoleLog('wiredAdditionalInfoFieldSet');
            this.consoleLog(this.additionalInfoFieldSetResponse, true);
        } else if (result.error) {
            promptError(customLabels.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    /**
     * @description get list of additional details field name
     */
    get additionalInfoFieldList() {
        let result = [];
        if(this.additionalInfoFieldSetResponse) {
            for(let field of this.additionalInfoFieldSetResponse) {
                result.push(field.fieldName);
            }
        }

        return result;
    }

    get hasAdditionalInfo(){
        return this.additionalInfoFieldSetResponse?.length > 0;
    }

    get additionalInfoFieldSetWrapperList() {
        let result = [];
        if(this.additionalInfoFieldSetResponse) {
            for(let field of this.additionalInfoFieldSetResponse) {
                
                let value = this.individualAchievementUnitLookupFieldValue[field.fieldName];
                result.push({
                    ...field,
                    value: value,
                    isReference: field.displayType === 'REFERENCE',
                })
            }
        }

        return result;
    }

    //------------------------------uploaded files--------------------------------------------
    

    /**
     * @description get list of individual requirement wrapper based on individual achievement unit id
     */
    @wire(ctrlGetIndividualRequirementWrappers, {
        individualAchievementUnitId: "$individualAchievementUnitId"
    })
    wiredGetIndividualRequirementWrappers(result) {
        this.individualRequirementWrappersResult = result;
        this.individualRequirementWrappersResponse = {};
        
        if (result.data) {
            this.individualRequirementWrappersResponse = JSON.parse(result.data.responseData);
            this.consoleLog('wiredGetIndividualRequirementWrappers');
            this.consoleLog(this.individualRequirementWrappersResponse, true);
        } else if (result.error) {
            promptError(customLabels.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    /**
     * @description list of irq id 
     */
    get irqIdList() {
        return Object.keys(this.individualRequirementWrappersResponse);
    }

    /**
     * @description get list of uploaded files
     */
    @wire(ctrlGetExistingUploadedFiles, {recordIds: "$irqIdList"})
    wiredGetExistingUploadedFiles(result) {
        this.existingUploadedFilesResult = result;
        this.existingUploadedFilesResponse = {};
        
        if (result.data) {
            this.existingUploadedFilesResponse = JSON.parse(result.data.responseData);
            this.consoleLog('wiredGetExistingUploadedFiles');
            this.consoleLog(this.existingUploadedFilesResponse, true);
        } else if (result.error) {
            promptError(customLabels.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    get hasExistingFiles() {
        return Object.keys(this.existingUploadedFilesResponse)?.length > 0;
    }
    
    get uploadedFilesLabel() {
        return UPLOADED_FILES_LABEL;
    }
    
    get noUploadedFilesLabel() {
        return NO_UPLOADED_FILES_LABEL;
    }

    get existingUploadedFiles() {
        let result = [];
        if(this.hasExistingFiles) {
            for(let [irqId, cvsList] of Object.entries(this.existingUploadedFilesResponse)) {
                let irqWrapper = this.individualRequirementWrappersResponse?.[irqId];
                if(irqWrapper) {
                    for(let cvs of cvsList) {
                        
                        cvs.fileDeleteDisabled = (
                            irqWrapper.submissionStatusType === IRQ_SUBMITTED_STATUS_TYPE_SUBMITTED ||
                            irqWrapper.submissionStatusType === IRQ_SUBMITTED_STATUS_TYPE_CANCELLED ||
                            irqWrapper.reviewStatusType !== IRQ_REVIEW_STATUS_TYPE_OPEN
                        )
                        cvs.displayName = `${cvs.Title}.${cvs.FileExtension}`
                        result.push(cvs);
                    }
                }
            }
            
        }

        return result;
    }

    handleFilePreview(event) {
        this.consoleLog('handleFilePreview');
        this.dispatchEvent(new CustomEvent('filepreview', {
            detail: {
                documentId: event.target.dataset.documentid
            },
            bubbles: false,
            composed: false
        }));
    }

    handleFileDownload(event) {
        this.consoleLog('handleFileDownload');
        let fullUrl = getFileDownloadUrl(this.sitePath, this.downloadUrl, event.target.dataset.cvsId);
        if(fullUrl) {
            window.open(fullUrl, '_blank');
        }
    }

    handleFileDelete(event) {
        this.consoleLog('handleFileDelete');
        
        let contentDocumentId = event.currentTarget.dataset.documentid;
        let fileTitle = event.currentTarget.dataset.filetitle;
        let fileExtension = event.currentTarget.dataset.fileextension;

        let recordName = `${fileTitle}.${fileExtension}`;

        this.openDeleteConfirmation(customLabels.FILE_LABEL, contentDocumentId, recordName);
    }
    
    /**
     * @description open a modal to confirm delete action
     * @param {*} objLabel object label
     * @param {*} record row object of the delete record
     */
    async openDeleteConfirmation(objLabel, recordId, recordName){

        try{

            this.consoleLog('openDeleteConfirmation');
            let confirmationText1 = customLabels.DELETE_RECORD_CONFIRMATION_LABEL.format([objLabel, recordName]);
            let result = await genericConfirmationModal.open({
                size: 'small',
                modalTitle: customLabels.DELETE_LABEL,
                confirmationText1: confirmationText1,
                confirmationText2: null,
                confirmationText3: null,
                showSubmitButton: true,
                submitButtonLabel: customLabels.DELETE_LABEL,
                showCancelButton: true,
                cancelButtonLabel: customLabels.CANCEL_LABEL,
                eventSource: 'deleteRecord',
                eventData: recordId,
                enableDebugMode: this.enableDebugMode
            })

            if (result){
                const { operation, eventSource, eventData } = result; 
                if(operation === 'submit' && eventSource === 'deleteRecord') {
                    await this.deleteRecord(objLabel, eventData);
                }
            }
        
        } catch (error) {
                
            logError('Delete child record error: ', error);
            promptError(customLabels.ERROR_LABEL, getErrorMessage(error));
        }
    }

    /**
     * @description Delete a record
     * @param {*} objLabel object label
     * @param {*} recordId record id
     */
    async deleteRecord(objLabel, recordId){
        try{

            this.consoleLog('deleteRecord');
            let deletedMsg = customLabels.RECORD_DELETED_LABEL.format([objLabel]);

            await deleteRecord(recordId);

            promptSuccess(customLabels.SUCCESS_LABEL, deletedMsg);

            this.toggleSpinner(1);
            notifyRecordUpdateAvailable([{recordId: recordId}]);
            this.dispatchEvent(new RefreshEvent());
            this.toggleSpinner(-1);

        } catch (error) {
                
            logError('Delete child record error: ', error);
            promptError(customLabels.ERROR_LABEL, getErrorMessage(error));
        }
    }
    //----------------------------------- verification details---------------------------

    @wire(ctrlGetFieldSet, {fieldSetName:"$verificationDetailsFieldSetName", objectApiName: 'reduivy__Individual_Achievement_Unit__c'})
    wiredGetVerificationDetailsFields(result) {
        this.verificationDetailsFieldsResult = result;
        this.verificationDetailsFieldsResponse = null;
        
        if (result.data) {
            this.verificationDetailsFieldsResponse = JSON.parse(result.data.responseData);
            this.consoleLog('wiredGetVerificationDetailsFields');
            this.consoleLog(this.verificationDetailsFieldsResponse, true);
        } else if (result.error) {
            promptError(customLabels.ERROR_LABEL, getErrorMessage(result.error));
        }

    }

    get verificationDetailsLabel() {
        return VERIFICATION_DETAILS_LABEL;
    }

    get verificationDetailsFieldList() {
        let result = [];
        if(this.verificationDetailsFieldsResponse) {
            for(let field of this.verificationDetailsFieldsResponse) {
                result.push(field.fieldName);
            }
        }

        return result;
    }

    get hasVerificationDetails() {
        return this.verificationDetailsFieldsResponse?.length > 0;
    }
    
    get verificationDetailsFieldSetWrapperList() {
        let result = [];
        if(this.verificationDetailsFieldsResponse) {
            for(let field of this.verificationDetailsFieldsResponse) {
                
                let value = this.individualAchievementUnitLookupFieldValue[field.fieldName]
                result.push({
                    ...field,
                    value: value,
                    isReference: field.displayType === 'REFERENCE',
                })
            }
        }

        return result;
    }

    /**
     * @description handle when lookup fields in verification details is set. set for others lookup fields with same field name
     */
    handleVerificationFieldLookupChange(event) {
        this.consoleLog('handleVerificationFieldLookupChange');
        let lookupFieldName = event.detail.lookupFieldName;
        let lookupRecordId = event.detail.value;
        this.individualAchievementUnitLookupFieldValue[lookupFieldName] = lookupRecordId;

        if(lookupFieldName === 'reduivy__Agreement_Recognition_Unit__c' || this.verificationDetailsFieldList.includes(lookupFieldName)) {
            let additionalInfoCmpList = Object.values(this.template.querySelectorAll(`c-custom-lookup-field:not([data-type="verificationDetails"])`)).filter(cmp => cmp.lookupFieldName === lookupFieldName);
            if(additionalInfoCmpList.length){
                additionalInfoCmpList.forEach(additionalInfoCmp => {
                    if(lookupRecordId) {
                        additionalInfoCmp.setSelectedRecord(lookupRecordId);
                    } else {
                        additionalInfoCmp.clear();
                    }
                });
            }
        }
    }


    // --------------------------------- buttons -------------------------

    get cancelButtonLabel() {
        return customLabels.CANCEL_LABEL;
    }

    get saveButtonLabel() {
        return customLabels.SAVE_LABEL;
    }

    handleCancelClick() {
        this.consoleLog('handleCancelClick');
        this.close();
    }

    handleSaveClick() {
        this.consoleLog('handleSaveClick')
        this.refs.editFormButton.click();
    }
    
    handleSaveRecordEditForm(event) {
        this.consoleLog('handleSaveRecordEditForm');
        event.preventDefault();

        let element = [...this.template.querySelectorAll('[data-required="true"]')];
        let requiredFieldsValid = element.reduce((validSoFar, inputCmp) => {
            return validSoFar && inputCmp?.reportValidity();

        }, true);

        if(!requiredFieldsValid){
            return;
        }

        //add all custom lookup field value
        const fields = event.detail.fields;
        for(const [key, value] of Object.entries(this.individualAchievementUnitLookupFieldValue)) {
            fields[key] = value;
        }

        //add individualAchievement lookup if is creating individualAchievementUnit
        if(!fields.reduivy__Individual_Achievement__c && this.individualAchievementId && !this.individualAchievementUnitId && 
            !this.verificationDetailsFieldList.includes('reduivy__Individual_Achievement__c') && !this.additionalInfoFieldList.includes('reduivy__Individual_Achievement__c')
        ) {
            fields.reduivy__Individual_Achievement__c = this.individualAchievementId
        }

        this.toggleSpinner(1);
        this.refs.recordEditForm.submit(fields);
    }

    handleRecordEditFormSuccess(event) {

        let data = {}
        for(const [key, value] of Object.entries(event.detail.fields)){
            data[key] = value.value;
        }
        data.Id = event.detail.id;

        this.close({
            operation: 'submit',
            eventResult: 'success',
            eventData: data
        })
    }

    handleRecordEditFormFail(event) {
        promptError(customLabels.ERROR_LABEL, getErrorMessage(event.detail));
        this.toggleSpinner(-1);
    }
    
    handleRecordEditFormLoad(event) {
        this.activeAccordion = [...this.activeAccordion];
        this.individualAchievementUnitLookupFieldValue = {};

        let customLookupFieldElements = Object.values(this.template.querySelectorAll('c-custom-lookup-field'));

        
        for(let additionalField of this.additionalInfoFieldSetWrapperList) {

            if(additionalField.fieldName && additionalField.isReference) {
                let referenceFieldName = additionalField.fieldName;
                let value = event.detail.records?.[this.individualAchievementUnitId].fields[referenceFieldName].value;
                this.individualAchievementUnitLookupFieldValue[referenceFieldName] = value;
            }

            if(this.individualAchievementUnitLookupFieldValue[additionalField.fieldName]) {
                
                additionalField.value = this.individualAchievementUnitLookupFieldValue[additionalField.fieldName];
                if(additionalField.isReference) {
                    
                    let targetFieldName = additionalField.fieldName.endsWith('__r') ? additionalField.fieldName.slice(0, -1) + 'c' : additionalField.fieldName;
                    let fieldValue = this.individualAchievementUnitLookupFieldValue[targetFieldName]
                    let elementList = customLookupFieldElements.filter(ele => ele.lookupFieldName === targetFieldName);
                    if(elementList && elementList.length > 0) {
                        elementList.forEach(ele => ele.setSelectedRecord(fieldValue));
                    }
                }
            }
        }

        //the agreement recognition unit lookup field
        let agreementRecognitionUnitField = "reduivy__Agreement_Recognition_Unit__c";
        let agreementRecognitionUnitCmpList = customLookupFieldElements.filter(ele => ele.lookupFieldName === agreementRecognitionUnitField);
        if(agreementRecognitionUnitCmpList.length > 0 && this.aruId) {
            agreementRecognitionUnitCmpList.forEach(agreementRecognitionUnitCmp => {
                agreementRecognitionUnitCmp.setSelectedRecord(this.aruId);
            });
        }

        //the individual Achievement lookup field
        if(!this.individualAchievementUnitLookupFieldValue.reduivy__Individual_Achievement__c && this.individualAchievementId) {
            //this is to set the individual achievement 
            this.individualAchievementUnitLookupFieldValue.reduivy__Individual_Achievement__c = this.individualAchievementId;
            let individualAchievementFieldCmps = customLookupFieldElements.filter(ele => ele.lookupFieldName === 'reduivy__Individual_Achievement__c');
            if(individualAchievementFieldCmps.length > 0) {
                individualAchievementFieldCmps.forEach(individualAchievementFieldCmp => {
                    individualAchievementFieldCmp.setSelectedRecord(this.individualAchievementId);
                })
            }
        }

    }

    //-------------------------------------------------------
	
    /**
     * @descripton connected callback
     */
    connectedCallback(){
		this.refreshContainerID = registerRefreshContainer(this, this.refreshData);
	}

    disconnectedCallback() {
        unregisterRefreshContainer(this.refreshContainerID)
    }

    refreshData() {
        
        this.consoleLog('refreshData');

        this.toggleSpinner(1);
        
        refreshApex(this.additionalInfoFieldSetResult);
        refreshApex(this.verificationDetailsFieldsResult);
        refreshApex(this.agreementRecognitionUnitResult);
        refreshApex(this.objectTranslatedNameResult);
        refreshApex(this.individualAchievementUnitRecordResult);
        refreshApex(this.existingUploadedFilesResult);

        this.toggleSpinner(-1);
        return new Promise((resolve) => {
            resolve(true);
        });

    }
	/**
     * @descripton library loader
     */
    handleLibLoadSuccess(event) {
        this.isScriptLoaded = true;
        this.isInitSuccess = true;
        
    }

    /**
     * @descripton library loader
     */
    handleLibLoadFail(event) {
        this.isScriptLoaded = true;
        this.isInitSuccess = false;
    }

    get loadingLabel() {
        return customLabels.LOADING_LABEL;
    }
	
    /**
    * @description the user language
    */
    get language() {
        return LANG;
    }

    /**
     * @descripton Spinner loading status
     */
	get isLoading(){
        return this.loadedLists === 0 ? false : true;
    }

    /**
     * @descripton Spinner toggler
     */
	toggleSpinner(loadCount){
        this.loadedLists += loadCount;

        if(this.loadedLists <= 0){
            this.loadedLists = 0;
        }
    }
	
    /**
     * @descripton Console log for debugging
     */
	consoleLog(anything, isJson){
        logInfo('StudentAchievementUnitAdminModal', anything, this.enableDebugMode, isJson);
    }
	
}