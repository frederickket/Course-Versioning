/**
 * @Author 		WDCi (XW)
 * @Date 		Jan 2026
 * @group 		Student Achievement
 * @Description Student Achievement modal to edit individual achievement unit as student
 * @changehistory
 * ISS-002633 09-01-2026 XW - create new class (clone from record edit modal)
 */
import { api, wire, track } from 'lwc';
import { promptError } from 'c/toasterUtil';
import { getErrorMessage, logInfo } from 'c/loggingUtil';
import { customLabels } from 'c/labelLoader';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getColumnSize } from 'c/lwcUtil';
import genericConfirmationModal from 'c/genericConfirmationModal';
import { getFieldValue, getRecord } from 'lightning/uiRecordApi';

import IAU_OBJ from '@salesforce/schema/Individual_Achievement_Unit__c'
import IAU_AGREEMENT_RECOGNITION_UNIT_FIELD from '@salesforce/schema/Individual_Achievement_Unit__c.Agreement_Recognition_Unit__c'
import IAC_VERIFICATION_STATUS_FIELD from '@salesforce/schema/Individual_Achievement__c.Verification_Status__c'
import IAU_VERIFICATION_STATUS_FIELD from '@salesforce/schema/Individual_Achievement_Unit__c.Verification_Status__c'
import IAC_NAME_FIELD from '@salesforce/schema/Individual_Achievement__c.Name'
import IAC_AGREEMENT_RECOGNITION_FIELD from '@salesforce/schema/Individual_Achievement__c.Agreement_Recognition__c'

import LightningModal from 'lightning/modal';

import ctrlGetFieldSetMembers from '@salesforce/apex/REDU_RecordEditModal_LCTRL.getFieldSetMembers';
import ctrlGetIndividualAchievementVerificationStatusesInfo from '@salesforce/apex/REDU_StudentAchievement_LCTRL.getIndividualAchievementVerificationStatusesInfo';
import ctrlGetIndividualAchievementUnitVerificationStatusesInfo from '@salesforce/apex/REDU_StudentAchievementUnitTable_LCTRL.getIndividualAchievementUnitVerificationStatusesInfo';



import NO_FIELDS_LABEL from '@salesforce/label/c.No_Fields_In_Field_Set'
import CREATE_NEW_PARENT_LABEL from '@salesforce/label/c.Create_New_Record'
import INVALID_OBJECT_FIELD_SET_LABEL from '@salesforce/label/c.Invalid_Object_Field_Set_Error'
import STUDENT_ACHIEVEMENT_UNIT_NAME_LABEL from '@salesforce/label/c.Student_Achievement_Unit_Name'
import STUDENT_ACHIEVEMENT_UNIT_CODE_LABEL from '@salesforce/label/c.Student_Achievement_Unit_Code'
import WARNING_CREATE_OPEN_IAU_LABEL from '@salesforce/label/c.Student_Achievement_Warning_Create_Open_Iau';


const LOCKING_MODE_LOCKED = 'Locked';
const LOCKING_MODE_UNLOCKED = 'Unlocked';

const VERIFICATION_STATUS_TYPE_OPEN = 'Open';
const VERIFICATION_STATUS_TYPE_VERIFIED = 'Verified';

const STATUS_ACTIVE = 'Active';

export default class StudentAchievementUnitStudentModal extends LightningModal {
	
	//configurable attributes
    @api modalTitle;
	@api enableDebugMode = false;
    
    @api fieldSetName;
    @api editFormColumnNo;
    @api enableNewParentCreation = false;
    @api unitNameFallbackField;
    @api unitCodeFallbackField;
    @api unitRequired;
    @api individualAchievementId;

    @api individualAchievementUnitId;
    @api aruId;

	
	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false
	loadedLists = 0;
    recordTypeIsSelected = false;
    selectedRecordTypeId;
    lookupFieldObjectName;
    lookupFieldRecordTypeId;
    @track originalIndividualAchievementUnitVerificationStatus;
    isLoaded = false;

    @track customLookupFieldValue = {};
    @track agreementRecognitionUnitIsNotListed = false;
    @track unitNameFallbackValue;
    @track unitCodeFallbackValue;
    
    //wired
    @track objectInfoResult;
    @track objectInfoData;
    @track fieldSetMembersResult;
    @track fieldSetMembersResponse;
    @track individualAchievementRecordResult;
    @track individualAchievementRecordResponse;
    @track individualAchievementVerificationStatusesInfoResult;
    @track individualAchievementVerificationStatusesInfoResponse;
    @track individualAchievementUnitVerificationStatusesInfoResult;
    @track individualAchievementUnitVerificationStatusesInfoResponse;
	
	
	//js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'jquery', 'tooltips'
    modules = ['stringutil'];

    @wire(getObjectInfo, { objectApiName: IAU_OBJ })
    individualAchievementUnitObjectInfo;
    
    get individualAchievementUnitObjectLabel() {
        return this.individualAchievementUnitObjectInfo?.data?.label ?? IAU_OBJ.objectApiName;
    }

    get individualAchievementUnitObjectName() {
        return IAU_OBJ.objectApiName;
    }

    @wire(ctrlGetIndividualAchievementVerificationStatusesInfo) 
    wiredGetIndividualAchievementVerificationStatusesInfo(result) {
        this.individualAchievementVerificationStatusesInfoResult = result;
        this.individualAchievementVerificationStatusesInfoResponse = null;
        
        if (result.data) {
            this.individualAchievementVerificationStatusesInfoResponse = JSON.parse(result.data.responseData);
            this.consoleLog('wiredGetIndividualAchievementVerificationStatusesInfo');
            this.consoleLog(this.individualAchievementVerificationStatusesInfoResponse, true);
        } else if (result.error) {
            promptError(customLabels.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    get individualAchievementLockedVerificationStatuses() {
        return this.individualAchievementVerificationStatusesInfoResponse?.lockingMode?.[LOCKING_MODE_LOCKED] ?? [];
    }

    get individualAchievementUnlockedVerificationStatuses() {
        return this.individualAchievementVerificationStatusesInfoResponse?.lockingMode?.[LOCKING_MODE_UNLOCKED] ?? [];
    }

    get individualAchievementVerificationStatusType() {
        return this.individualAchievementVerificationStatusesInfoResponse?.verificationStatusType ?? {};
    }
    
    get individualAchievementIsLocking() {
        let status = this.individualAchievementRecord?.[IAC_VERIFICATION_STATUS_FIELD.fieldApiName];
        return this.individualAchievementLockedVerificationStatuses.includes(status);
    }

    @wire(ctrlGetIndividualAchievementUnitVerificationStatusesInfo)
    wiredGetIndividualAchievementUnitVerificationStatusesInfo(result) {
        this.individualAchievementUnitVerificationStatusesInfoResult = result;
        this.individualAchievementUnitVerificationStatusesInfoResponse = null;
        
        if (result.data) {
            this.individualAchievementUnitVerificationStatusesInfoResponse = JSON.parse(result.data.responseData);
            this.consoleLog('wiredGetIndividualAchievementUnitVerificationStatusesInfo');
            this.consoleLog(this.individualAchievementUnitVerificationStatusesInfoResponse, true);
        } else if (result.error) {
            promptError(customLabels.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    get individualAchievementUnitLockedVerificationStatuses() {
        return this.individualAchievementUnitVerificationStatusesInfoResponse?.lockingMode?.[LOCKING_MODE_LOCKED] ?? [];
    }

    get individualAchievementUnitUnlockedVerificationStatuses() {
        return this.individualAchievementUnitVerificationStatusesInfoResponse?.lockingMode?.[LOCKING_MODE_UNLOCKED] ?? [];
    }

    get individualAchievementUnitVerificationStatusType() {
        return this.individualAchievementUnitVerificationStatusesInfoResponse?.verificationStatusType ?? {};
    }
    
    @wire(getRecord, {recordId: '$individualAchievementId', fields: [IAC_VERIFICATION_STATUS_FIELD, IAC_NAME_FIELD, IAC_AGREEMENT_RECOGNITION_FIELD]}) 
    wiredGetIndividualAchievementRecord(result) {
        
        this.individualAchievementRecordResult = result;
        this.individualAchievementRecordResponse = null;
        
        if(result.data){
            this.individualAchievementRecordResponse = result.data;
            this.consoleLog(this.individualAchievementRecordResponse, true);
        } else if (result.error) {
            promptError(customLabels.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    get individualAchievementVerificationStatus() {
        return getFieldValue(this.individualAchievementRecordResponse, IAC_VERIFICATION_STATUS_FIELD);
    }

    get individualAchievementName() {
        return getFieldValue(this.individualAchievementRecordResponse, IAC_NAME_FIELD);
    }

    get individualAchievementAgreementRecognitionId() {
        return getFieldValue(this.individualAchievementRecordResponse, IAC_AGREEMENT_RECOGNITION_FIELD);
    }

    //get field set member
    @wire(ctrlGetFieldSetMembers, { objName:'$individualAchievementUnitObjectName', fieldSetName: '$fieldSetName' })
    wiredFieldSetMembers(result){
        this.fieldSetMembersResult = result;
        this.fieldSetMembersResponse = null;
        
        if(result.data){
            this.fieldSetMembersResponse = JSON.parse(result.data.responseData);
            if(this.fieldSetMembersResponse.length === 0){
                promptError(customLabels.ERROR_LABEL, NO_FIELDS_LABEL.format([this.fieldSetName]));
            }

            if(this.fieldSetMembersResponse) {
                for(let field of this.fieldSetMembersResponse) {
                    field.isReference = field.displayType === 'REFERENCE';

                    field.isAgreementRecognitionUnit = field.fieldName === this.agreementRecognitionUnitFieldName;
                }
            }
        
        } else if (result.error) {
            promptError(customLabels.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    get fieldSetMemberFieldsName() {
        let result = [];
        if(this.fieldSetMembersResponse?.length > 0) {
            for(let fieldSetMember of this.fieldSetMembersResponse) {
                result.push(fieldSetMember.fieldName);
            }
        }
        return result;
    }

    get agreementRecognitionUnitFieldName() {
        return IAU_AGREEMENT_RECOGNITION_UNIT_FIELD.fieldApiName;
    }

    // Check whether the field set name is passed
    get showInvalidFieldSetNameMessage() {
        return !this.fieldSetName;
    }

    // Invalid Field Set Name Message
    get invalidFieldSetNameMessage() {
        return INVALID_OBJECT_FIELD_SET_LABEL.format(['', this.individualAchievementUnitObjectLabel]);
    }

    //show record type radio group if record type is not selected and is creating a new record
    get showRecordTypeSelection(){
        return !this.recordTypeIsSelected && !this.individualAchievementUnitId && Object.keys(this.recordTypeOptions).length > 0;
    }

    //options for radio group (remove master if length > 1)
    get recordTypeOptions() {
        let result = [];
        if(this.individualAchievementUnitObjectInfo?.data){
            for (let recordTypeId of Object.keys(this.individualAchievementUnitObjectInfo?.data?.recordTypeInfos)){
                let recordType = this.individualAchievementUnitObjectInfo?.data?.recordTypeInfos[recordTypeId];
                if(!recordType.master && recordType.available) {
                    result.push({label: recordType.name, value: recordTypeId})
                }
            }
        }
        return result;
    }

    //next label for button
    get nextLabel() {
        return customLabels.NEXT_LABEL;
    }
    
    //calculate the size of each field
    get defaultInputSize(){
        return getColumnSize(this.editFormColumnNo);
    }

    //fields to be displayed in the form
    get fields(){
        if(this.fieldSetMembersResponse) {
            return this.fieldSetMembersResponse;
        }
        return [];
    }

    //previous label for button
    get previousButtonLabel(){
        return customLabels.PREVIOUS_LABEL;
    }
    
    //cancel label for button
    get cancelButtonLabel(){
        return customLabels.CANCEL_LABEL;
    }
    
    //save label for button
    get saveButtonLabel(){
        return customLabels.SAVE_LABEL;
    }

    get loadingLabel() {
        return customLabels.LOADING_LABEL;
    }

    get unitCodeLabel() {
        return STUDENT_ACHIEVEMENT_UNIT_CODE_LABEL;
    }

    get unitNameLabel() {
        return STUDENT_ACHIEVEMENT_UNIT_NAME_LABEL;
    }

    get agreementRecognitionUnitFallbackLabel() {
        return this.unitNameFallbackField ? this.unitNameLabel : this.unitCodeLabel;
    }

    /**
     * @description return 
     */
    get showPreviousButton() {
        return this.individualAchievementUnitId && this.recordTypeOptions.length > 0;
    }

    /**
     * @description Return true if the button should be clickable
     */
    get hasFields() {
        
        if (this.fields && this.fields.length > 0) {
            return true;
        }

        return false;
    }

    //disable save or next button if no fields are set in the field set or is loading
    get disableButtons() {
        return this.isLoading || !this.hasFields;
    }

    get createNewParentLabel() {
        return CREATE_NEW_PARENT_LABEL;
    }

    get enableAgreementRecognitionUnitFallback() {
        return this.unitCodeFallbackField || this.unitNameFallbackField;
    }

    get showSecondFallbackField() {
        return this.unitCodeFallbackField && this.unitNameFallbackField && this.agreementRecognitionUnitIsNotListed;
    }

    //go back to record type selection page
    handlePreviousClick(){
        if(this.selectedRecordTypeId) {
            this.recordTypeIsSelected = false;
        }
    }

    //handle record type selection
    handleRecordTypeChange(event) {
        this.selectedRecordTypeId = event.detail.value;
    }

    //enter the value of fields after record type is selected
    handleNextClick() {
        this.consoleLog('handleNextClick');
        if(this.selectedRecordTypeId) {
            this.recordTypeIsSelected = true;
        }
    }

    get agreementRecognitionUnitDefaultFallbackValue() {
        if(this.unitNameFallbackField) {
            return this.unitNameFallbackValue;
        }
        if(this.unitCodeFallbackField) {
            return this.unitCodeFallbackValue;
        }
        return '';
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

    handleAgreementRecognitionUnitLookupChange(event) {
        this.consoleLog('handleAgreementRecognitionUnitLookupChange')
        let isFallback = event.detail.isFallback;
        if(isFallback) {
            this.agreementRecognitionUnitIsNotListed = true;
            let fallbackFieldName = this.unitNameFallbackField ? this.unitNameFallbackField : this.unitCodeFallbackField;
            let fallbackValue = event.detail.fallbackValue;

            //the moment fallback checkbox is checked, we need to set the fallback value to the custom lookup field and the unit code fallback input
            if(event.detail.isTogglingFallbackCheckbox && this.enableAgreementRecognitionUnitFallback) {
                let agreementRecognitionUnitCmp = this.template.querySelector(`c-custom-lookup-field[data-type="agreementRecognitionUnit"]`);
                let unitCodeFallbackFieldCmpList = Object.values(this.template.querySelectorAll(`lightning-input-field[data-field-name="${this.unitCodeFallbackField}"]`));

                if(agreementRecognitionUnitCmp) {
                    if(this.unitNameFallbackField) {
                        agreementRecognitionUnitCmp.setSearchKeyword(this.unitNameFallbackValue);
                    } else {
                        agreementRecognitionUnitCmp.setSearchKeyword(this.unitCodeFallbackValue);
                    }
                }
                if(unitCodeFallbackFieldCmpList) {
                    for(let unitCodeFallbackFieldCmp of unitCodeFallbackFieldCmpList) {
                        unitCodeFallbackFieldCmp.value = this.unitCodeFallbackValue;
                    }
                }
            } else {
                
                //set fallback field in lightning input 
                let fallbackFieldCmp = Object.values(this.template.querySelectorAll(`lightning-input-field[data-field-name="${fallbackFieldName}"]`)).find(cmp => cmp.fieldName === fallbackFieldName);

                if(fallbackFieldCmp){
                    fallbackFieldCmp.value = fallbackValue;
                }
                if(fallbackFieldName === this.unitNameFallbackField) {
                    this.unitNameFallbackValue = fallbackValue;
                } else {
                    this.unitCodeFallbackValue = fallbackValue;
                }
            }

        } else {
            this.agreementRecognitionUnitIsNotListed = false;
            let parentRecordId = event.detail.value;
            let lookupFieldName = event.detail.lookupFieldName;
            this.customLookupFieldValue[lookupFieldName] = parentRecordId;
            
            let agreementRecognitionUnitCmp = Object.values(this.template.querySelectorAll(`c-custom-lookup-field[data-type="details"]`)).find(cmp => cmp.dataset.fieldName === this.agreementRecognitionUnitFieldName);
            if(agreementRecognitionUnitCmp){
                if(parentRecordId) {
                    agreementRecognitionUnitCmp.setSelectedRecord(parentRecordId);
                } else {
                    agreementRecognitionUnitCmp.clear();
                }
            }
        }

    }

    handleUnitCodeFallbackChange(event) {
        this.consoleLog('handleUnitCodeFallbackChange');
        this.unitCodeFallbackValue = event.detail.value;
        let inputFieldUnitCodeFallbackCmp = this.template.querySelector(`lightning-input-field[data-field-name=${this.unitCodeFallbackField}]`);
        if(inputFieldUnitCodeFallbackCmp) {
            inputFieldUnitCodeFallbackCmp.value = this.unitCodeFallbackValue;
        }
    }
    
    /**
     * @description if input field in additional details is unit code fallback field, change the unit code fallback input
     */
    handleInputFieldChange(event) {
        this.consoleLog('handleInputFieldChange');
        if(event.target.dataset.fieldName === this.unitCodeFallbackField) {
            this.unitCodeFallbackValue = event.detail.value;
            let agreementRecognitionUnitCodeFallbackCmp = this.template.querySelector('lightning-input[data-name="unitCodeFallback"]');
            if(agreementRecognitionUnitCodeFallbackCmp) {
                agreementRecognitionUnitCodeFallbackCmp.value = this.unitCodeFallbackValue;
            }
        }
    }

    /**
     * @description handle additional details lookup field change. if is agreement recognition unit, set the selected record id to the system agreement recognition unit
     */
    handleDetailsLookupChange(event) {
        this.consoleLog('handleDetailsLookupChange');
        let lookupFieldName = event.detail.lookupFieldName;

        let parentRecordId = event.detail.value;
        this.customLookupFieldValue[lookupFieldName] = parentRecordId;
        
        if(lookupFieldName === 'reduivy__Agreement_Recognition_Unit__c') {
            let agreementRecognitionUnitCmp = this.template.querySelector(`c-custom-lookup-field[data-type="agreementRecognitionUnit"]`);
            if(agreementRecognitionUnitCmp){
                if(parentRecordId){
                    agreementRecognitionUnitCmp.setSelectedRecord(parentRecordId);
                } else {
                    agreementRecognitionUnitCmp.clear();
                }
            }
        }
        
    }

    handleOnLoad(event) {
        this.consoleLog('handleOnLoad');
        this.toggleSpinner(1);
        
        let fields = event?.detail?.records?.[this.individualAchievementUnitId]?.fields ?? event?.detail?.record?.fields;
        let customLookupFieldElements = Object.values(this.template.querySelectorAll('c-custom-lookup-field'));
        if(fields) {
            for(let fieldName of Object.keys(fields)) {
                if(fieldName.endsWith('__r') || fieldName.endsWith('Id')) {
                    let targetFieldName = fieldName.endsWith('__r') ? fieldName.slice(0, -1) + 'c' : fieldName;
                    let fieldValue = fields?.[targetFieldName].value
                    let element = customLookupFieldElements.find(ele => ele.lookupFieldName === targetFieldName);
                    if(element) {
                        element.setSelectedRecord(fieldValue);
                    }
                }
            }
            //the individual Achievement lookup field
            if(!this.customLookupFieldValue.reduivy__Individual_Achievement__c && this.individualAchievementId) {
                //this is to set the individual achievement 
                this.customLookupFieldValue.reduivy__Individual_Achievement__c = this.individualAchievementId;
                let individualAchievementFieldCmps = customLookupFieldElements.filter(ele => ele.lookupFieldName === 'reduivy__Individual_Achievement__c');
                if(individualAchievementFieldCmps.length > 0) {
                    individualAchievementFieldCmps.forEach(individualAchievementFieldCmp => {
                        individualAchievementFieldCmp.setSelectedRecord(this.individualAchievementId);
                    })
                }
            }
            

            //unit name and unit code fallback value;
            if(this.unitNameFallbackField) {
                this.unitNameFallbackValue = fields[this.unitNameFallbackField]?.value;
            }
            if(this.unitCodeFallbackField) {
                this.unitCodeFallbackValue = fields[this.unitCodeFallbackField]?.value;
            }

            if(!this.aruId && this.individualAchievementUnitId && (
                    this.unitNameFallbackValue || this.unitCodeFallbackValue
                ) && (
                    (this.unitNameFallbackField && this.unitNameFallbackValue !== undefined) ||
                    (this.unitCodeFallbackField && this.unitCodeFallbackValue !== undefined)
                ) && !this.isLoaded
            ) {
                let agreementRecognitionUnitCmp = this.template.querySelector(`c-custom-lookup-field[data-type="agreementRecognitionUnit"]`);
                if(agreementRecognitionUnitCmp) {
                    agreementRecognitionUnitCmp.setIsNotListed(true);
                }
                this.isLoaded = true;
            }

            this.originalIndividualAchievementUnitVerificationStatus = fields.reduivy__Verification_Status__c?.value;
        }
        this.toggleSpinner(-1);
    }

    //handle when user click on save
    handleSaveClick(){
        this.template.querySelector('.editFormSave').click();
    }

    async handleSaveSubmit(event) {
        this.consoleLog('handleSaveSubmit');

        event.preventDefault();

        let element = [...this.template.querySelectorAll('[data-save-required="true"]')];
        let requiredFieldsValid = element.reduce((validSoFar, inputCmp) => {

            return validSoFar && inputCmp.reportValidity();

        }, true);

        if(!requiredFieldsValid){
            return;
        }

        //add all custom lookup field value
        const fieldsToBeSubmitted = event.detail.fields;
        for(const [key, value] of Object.entries(this.customLookupFieldValue)) {
            fieldsToBeSubmitted[key] = value;
        }

        //add the unit code fallback value
        if(this.unitCodeFallbackValue && this.unitCodeFallbackField) {
            fieldsToBeSubmitted[this.unitCodeFallbackField] = this.unitCodeFallbackValue;
        }
        if(this.unitNameFallbackValue && this.unitNameFallbackField) {
            fieldsToBeSubmitted[this.unitNameFallbackField] = this.unitNameFallbackValue;
        }

        //add individualAchievement lookup if is creating individualAchievementUnit
        if(!fieldsToBeSubmitted.reduivy__Individual_Achievement__c && this.individualAchievementId && !this.individualAchievementUnitId && 
            !this.fieldSetMemberFieldsName.includes('reduivy__Individual_Achievement__c')
        ) {
            fieldsToBeSubmitted.reduivy__Individual_Achievement__c = this.individualAchievementId
        }
        
        ///ask for confirmation if the individualAchievementUnit verification status is updated from verified to unverified
        if(
            this.originalIndividualAchievementUnitVerificationStatus && 
            this.individualAchievementUnitUnlockedVerificationStatuses?.includes(this.originalIndividualAchievementUnitVerificationStatus) &&
            this.individualAchievementUnitVerificationStatusType?.[VERIFICATION_STATUS_TYPE_VERIFIED]?.includes(this.originalIndividualAchievementUnitVerificationStatus)
        ) {
            let allowSave = true;
            allowSave = await this.promptSaveConfirmation(fieldsToBeSubmitted.reduivy__Verification_Status__c);
        
            if(!allowSave) {
                return;
            }   
            
            //set verification status to unverified
            fieldsToBeSubmitted[IAU_VERIFICATION_STATUS_FIELD.fieldApiName] = this.individualAchievementUnitVerificationStatusType?.[VERIFICATION_STATUS_TYPE_OPEN]?.[0];
        }

        this.toggleSpinner(1);
        this.template.querySelector('lightning-record-edit-form').submit(fieldsToBeSubmitted);

    }

    async promptSaveConfirmation() {

        let allowSaving = false;
        let confirmationText = WARNING_CREATE_OPEN_IAU_LABEL.format([this.individualAchievementUnitObjectLabel]);
        let result = await genericConfirmationModal.open({
            size: "small",
            modalTitle: customLabels.CONFIRMATION_LABEL,
            confirmationText1: confirmationText,
            showSubmitButton: true,
            submitButtonLabel: customLabels.CONFIRM_LABEL,
            showCancelButton: true,
            cancelButtonLabel: customLabels.CANCEL_LABEL,
            eventSource: "saveIndividualAchievement",
            enableDebugMode: this.enableDebugMode
        });

        if (result){
            const { operation, eventSource, eventData } = result; 
            if(operation === 'submit' && eventSource === 'saveIndividualAchievement') {
                allowSaving = true;
            }
        }

        return allowSaving;
    }

    //close the modal when user click on cancel
    handleCancelClick(){
        this.close({
            operation: 'cancel',
            eventResult: 'cancel'
        });
    }

    //prompt an error if error occured while saving
    handleSaveError(event){
        promptError(customLabels.ERROR_LABEL, getErrorMessage(event.detail));
        this.toggleSpinner(-1);
    }
    
    //return the saved record and close the modal
    handleSaveSuccess(event){
        let data = {}
        for(const [key, value] of Object.entries(event.detail.fields)){
            data[key] = value.value;
        }
        data.Id = event.detail.id;

        this.close({
            operation: 'submit',
            eventResult: 'success',
            eventData: data
        });
    }

	/**
     * @descripton library loader
     */
    handleLibLoadSuccess() {
        this.isScriptLoaded = true;
        this.isInitSuccess = true;
    }

    /**
     * @descripton library loader
     */
    handleLibLoadFail() {
        this.isScriptLoaded = true;
        this.isInitSuccess = false;
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
        logInfo('StudentAchievementUnitStudentModal', anything, this.enableDebugMode, isJson);
    }
	
}