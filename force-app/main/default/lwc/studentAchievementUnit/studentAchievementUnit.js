/**
 * @Author 		WDCi (XW)
 * @Date 		Jan 2026
 * @group 		Student Achievement
 * @Description Student Achievement Unit
 * @changehistory
 * ISS-002633 26-01-2026 XW - new component
 */
import { LightningElement, api, wire, track } from 'lwc';
import { promptInfo, promptError, promptWarning, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';
import { commonConstants, hasOwnNestedProperty, extractFieldValue, getFileDownloadUrl } from 'c/lwcUtil';
import { deleteRecord, notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { shadeHexColorCode } from 'c/cssUtil';
import { customLabels } from 'c/labelLoader';
import LANG from '@salesforce/i18n/lang';
import { NavigationMixin } from "lightning/navigation";
import genericConfirmationModal from 'c/genericConfirmationModal';
import studentAchievementUnitAdminModal from 'c/studentAchievementUnitAdminModal'
import studentAchievementUnitStudentModal from 'c/studentAchievementUnitStudentModal'

//refresh module
import { refreshApex } from '@salesforce/apex';
import { RefreshEvent, registerRefreshHandler, unregisterRefreshHandler } from 'lightning/refresh';

//objects and fields
import IAU_OBJ from "@salesforce/schema/Individual_Achievement_Unit__c";
import IAC_OBJ from '@salesforce/schema/Individual_Achievement__c'
import IAU_VERIFICATION_STATUS_FIELD from "@salesforce/schema/Individual_Achievement_Unit__c.Verification_Status__c";

//Apex methods
import ctrlGetIndividualAchievementUnit from '@salesforce/apex/REDU_StudentAchievementUnit_LCTRL.getIndividualAchievementUnit';

//labels
import SHOW_UPLOADED_FILES_LABEL from '@salesforce/label/c.Student_Achievement_Show_Uploaded_Files';
import HIDE_UPLOADED_FILES_LABEL from '@salesforce/label/c.Student_Achievement_Hide_Uploaded_Files';
import THE_RECORD_IS_LOCKED_LABEL from '@salesforce/label/c.The_Record_Is_Locked';
import COMPLETE_ALL_REQUIREMENTS_LABEL from '@salesforce/label/c.Student_Achievement_Complete_All_Requirements';

const LOCKING_MODE_LOCKED = 'Locked';
const LOCKING_MODE_UNLOCKED = 'Unlocked';

const IRQ_SUBMITTED_STATUS_TYPE_SUBMITTED = 'Submitted';
const IRQ_SUBMITTED_STATUS_TYPE_CANCELLED = 'Cancelled';
const IRQ_REVIEW_STATUS_TYPE_OPEN = 'Open';

const IRQ_VERIFICATION_STATUS_BADGE_TYPE_INFO = 'slds-theme_info';
const IRQ_VERIFICATION_STATUS_BADGE_TYPE_SUCCESS = 'slds-theme_success';
const IRQ_VERIFICATION_STATUS_BADGE_TYPE_ERROR = 'slds-theme_error';
const IRQ_VERIFICATION_STATUS_BADGE_TYPE_WARNING = 'slds-theme_warning';
const IRQ_VERIFICATION_STATUS_BADGE_TYPE_BASE = 'slds-theme_base';
const IRQ_VERIFICATION_STATUS_BADGE_TYPE_INVERSE = 'slds-badge_inverse';
const IRQ_VERIFICATION_STATUS_BADGE_TYPE_LIGHTEST = 'slds-badge_lightest';

const VERIFICATION_STATUS_TYPE_OPEN = 'Open';
const VERIFICATION_STATUS_TYPE_SUBMITTED = 'Submitted';
const VERIFICATION_STATUS_TYPE_REVIEW = 'Review';
const VERIFICATION_STATUS_TYPE_VERIFIED = 'Verified';
const VERIFICATION_STATUS_TYPE_REJECTED = 'Rejected';
const VERIFICATION_STATUS_TYPE_CANCELLED = 'Cancelled';

const IRQ_VERIFICATION_STATUS_BADGE_TYPE_MAP = {
    'info': IRQ_VERIFICATION_STATUS_BADGE_TYPE_INFO,
    'success': IRQ_VERIFICATION_STATUS_BADGE_TYPE_SUCCESS,
    'error': IRQ_VERIFICATION_STATUS_BADGE_TYPE_ERROR,
    'warning': IRQ_VERIFICATION_STATUS_BADGE_TYPE_WARNING,
    'base': IRQ_VERIFICATION_STATUS_BADGE_TYPE_BASE,
    'inverse': IRQ_VERIFICATION_STATUS_BADGE_TYPE_INVERSE,
    'lightest': IRQ_VERIFICATION_STATUS_BADGE_TYPE_LIGHTEST
}

export default class StudentAchievementUnit extends NavigationMixin(LightningElement) {
	
	//configurable attributes
    @api individualAchievementUnitId;

    @api userMode;
    @api unitTableFields;

    @api individualAchievementId;
    @api matchedWizardFormConfig;
    @api individualAchievementVerificationStatusesInfo;
    @api verificationDetailsFieldSetName;
    @api agreementRecognitionUnitCreationFieldSetName;
    @api isCommunity;
    @api sitePath;

    @api individualAchievementUnitVerificationStatusesInfo;


	@api enableDebugMode = false;
	
	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false
	loadedLists = 0;
    @track showFilesValue = false;
	
    //refresh handler
    refreshHandlerID;

    //wire attribute
    @track individualAchievementUnitResult;
    @track individualAchievementUnitResponse;

	//labels
	label = customLabels;
	
	//js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'jquery', 'tooltips'
    modules = [];

    //---------------------------------------base--------------------------------
    
    get individualAchievementUnitLockedVerificationStatuses() {
        return this.individualAchievementUnitVerificationStatusesInfo?.lockingMode?.[LOCKING_MODE_LOCKED] ?? [];
    }

    get individualAchievementUnitUnlockedVerificationStatuses() {
        return this.individualAchievementUnitVerificationStatusesInfo?.lockingMode?.[LOCKING_MODE_UNLOCKED] ?? [];
    }

    get individualAchievementUnitVerificationStatusType() {
        return this.individualAchievementUnitVerificationStatusesInfo?.verificationStatusType ?? {};
    }

    get individualAchievementUnitVerifiedStatuses() {
        return this.individualAchievementUnitVerificationStatusType[VERIFICATION_STATUS_TYPE_VERIFIED] ?? [];
    }
    
    get individualAchievementUnitVerificationStatusesBadgeType() {
        return this.individualAchievementUnitVerificationStatusesInfo?.verificationStatusBadgeType ?? {};
    }

    get individualAchievementLockedVerificationStatuses() {
        return this.individualAchievementVerificationStatusesInfo?.lockingMode?.[LOCKING_MODE_LOCKED] ?? [];
    }

    get individualAchievementUnlockedVerificationStatuses() {
        return this.individualAchievementVerificationStatusesInfo?.lockingMode?.[LOCKING_MODE_UNLOCKED] ?? [];
    }

    get individualAchievementVerificationStatusType() {
        return this.individualAchievementVerificationStatusesInfo?.verificationStatusType ?? {};
    }

    get individualAchievementIsLocked() {
        return this.individualAchievementLockedVerificationStatuses.includes(this.individualAchievementVerificationStatus);
    }

    get individualAchievementUnitIsLocked() {
        return this.individualAchievementUnitLockedVerificationStatuses.includes(this.individualAchievementUnitVerificationStatus);
    }

    get isAdminMode() {
        return this.userMode === commonConstants.USER_MODE_ADMIN;
    }

    get preventEditingIndividualAchievement() {
        return this.individualAchievementIsLocked && !this.isAdminMode;
    }

    get preventEditingIndividualAchievementUnit() {
        if(this.individualAchievementUnitResponse && this.individualAchievementUnitTableFields) {
            return this.individualAchievementUnitIsLocked && !this.isAdminMode;
        }
        return false;
    }

    @wire(getObjectInfo, { objectApiName: IAU_OBJ })
    individualAchievementUnitObj;

    get individualAchievementUnitObjLabel() {
        return this.individualAchievementUnitObj?.data?.label ?? IAU_OBJ.objectApiName;
    }

    //-------------------------------------matched wizard config------------------------------
    
    get additionalUnitFieldSetName() {
        return this.matchedWizardFormConfig?.unitAdditionalInfoFieldSet ?? '';
    }

    get unitCodeFallbackField() {
        return this.matchedWizardFormConfig?.unitCode?.fallbackField ?? '';
    }

    get unitNameFallbackField() {
        return this.matchedWizardFormConfig?.unitName?.fallbackField ?? '';
    }

    get showUnitCodeField() {
        return this.matchedWizardFormConfig?.unitCode?.showSubgroup;
    }

    get showUnitNameField() {
        return this.matchedWizardFormConfig?.unitName?.showSubgroup;
    }
    
    get unitRequired() {
        return this.matchedWizardFormConfig?.unitRequired ?? false;
    }

    //-------------------------------------individualAchievementUnit record------------------------------

    get individualAchievementUnitAdditionalFields(){
        let result = [];
        if(this.unitCodeFallbackField) {
            result.push(this.unitCodeFallbackField);
        }
        if(this.unitNameFallbackField) {
            result.push(this.unitNameFallbackField);
        }

        return result;
    }

    @wire(ctrlGetIndividualAchievementUnit, {
        individualAchievementUnitId: '$individualAchievementUnitId',
        additionalFields: '$individualAchievementUnitAdditionalFields',
        userMode: '$userMode',
        unitTableFields: '$unitTableFields',
        language: '$language'
    })
    wiredGetIndividualAchievementUnit(result) {
        this.individualAchievementUnitResult = result;
        this.individualAchievementUnitResponse = null;

        if (result.data) {
            this.individualAchievementUnitResponse = JSON.parse(result.data.responseData);
            this.consoleLog(this.individualAchievementUnitResponse, true);
        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }

    }

    get individualAchievementUnitRecord() {
        return this.individualAchievementUnitResponse?.individualAchievementUnitRecord ?? {};
    }

    get individualAchievementUnitTranslationInfo() {
        return this.individualAchievementUnitResponse?.translationInfo ?? {};
    }
    
    get individualAchievementUnitTranslationData() {
        return this.individualAchievementUnitTranslationInfo?.translations?.find(t => t.languageCode === this.language)?.data ?? {}
    }

    get individualAchievementUnitTableFields() {
        return this.individualAchievementUnitResponse?.unitTableFields ?? null;
    }

    get individualAchievementUnitExistingFiles() {
        return this.individualAchievementUnitResponse?.existingFiles ?? {}
    }
    
    get individualAchievementUnitName() {
        return this.individualAchievementUnitRecord?.Name;
    }

    get aruId() {
        return this.individualAchievementUnitRecord?.reduivy__Agreement_Recognition_Unit__c;
    }

    get individualAchievementName() {
        return this.individualAchievementUnitRecord?.reduivy__Individual_Achievement__r?.Name;
    }

    get individualAchievementVerificationStatus() {
        return this.individualAchievementUnitRecord?.reduivy__Individual_Achievement__r?.reduivy__Verification_Status__c;
    }

    get individualAchievementUnitVerificationStatus() {
        return this.individualAchievementUnitRecord?.reduivy__Verification_Status__c;
    }

    get unitCodeDisplayValue() {
        let linkedUnitCodeValue;
        
        if(this.individualAchievementUnitTranslationInfo) {
            linkedUnitCodeValue = this.individualAchievementUnitTranslationData?.[this.individualAchievementUnitRecord.reduivy__Agreement_Recognition_Unit__c]?.reduivy__Unit_Code__c;
        }
        linkedUnitCodeValue = linkedUnitCodeValue ?? this.individualAchievementUnitRecord.reduivy__Agreement_Recognition_Unit__r?.reduivy__Unit_Code__c;
        let unitCodeFallbackValue = this.individualAchievementUnitRecord?.[this.unitCodeFallbackField];
        
        return linkedUnitCodeValue ?? unitCodeFallbackValue;
    }

    get unitNameDisplayValue() {
        let linkedUnitNameValue;
        if(this.individualAchievementUnitTranslationInfo) {
            linkedUnitNameValue = this.individualAchievementUnitTranslationData?.[this.individualAchievementUnitRecord.reduivy__Agreement_Recognition_Unit__c]?.Name;
        }
        linkedUnitNameValue = linkedUnitNameValue ?? this.individualAchievementUnitRecord.reduivy__Agreement_Recognition_Unit__r?.Name;
        
        let unitNameFallbackValue = this.individualAchievementUnitRecord?.[this.unitNameFallbackField];
        return linkedUnitNameValue ?? unitNameFallbackValue;
    }

    get additionalFields() {

        let additionalFields = [];
        if(this.individualAchievementUnitTableFields) {

        
            for(let field of this.individualAchievementUnitTableFields) {
                let isReference = field.displayType === 'REFERENCE';

                let fieldNamePicklist = field.fieldName + commonConstants.PICKLIST_LABEL;
                let additionalFieldDisplayValue;
                let additionalFieldRawValue;
                if(hasOwnNestedProperty(this.individualAchievementUnitRecord, fieldNamePicklist)) {
                    additionalFieldDisplayValue = extractFieldValue(this.individualAchievementUnitRecord, field.fieldName + commonConstants.PICKLIST_LABEL, this.individualAchievementUnitTranslationInfo, this.language);
                    additionalFieldRawValue = extractFieldValue(this.individualAchievementUnitRecord, field.fieldName);
                    
                } else if(isReference) {
                    let referenceFieldName = field.fieldName.endsWith('__c') ? field.fieldName.slice(0, -3) + '__r.Name' : field.fieldName.slice(0, -2) + '.Name';
                    additionalFieldDisplayValue = extractFieldValue(this.individualAchievementUnitRecord, referenceFieldName, this.individualAchievementUnitTranslationInfo, this.language);
                } else {
                    additionalFieldDisplayValue = extractFieldValue(this.individualAchievementUnitRecord, field.fieldName, this.individualAchievementUnitTranslationInfo, this.language);
                }

                let tableField = {
                    displayType: field.displayType,
                    value: additionalFieldDisplayValue,
                    fractionDigits: field.fractionDigits,
                };

                //verification status badge
                if(field.fieldName === IAU_VERIFICATION_STATUS_FIELD.fieldApiName) {
                    tableField.isVerificationStatus = true;

                    let type = this.individualAchievementUnitVerificationStatusesBadgeType[additionalFieldRawValue] ?? "base";
                    tableField.badgeClass = IRQ_VERIFICATION_STATUS_BADGE_TYPE_MAP[type] ?? IRQ_VERIFICATION_STATUS_BADGE_TYPE_BASE;
                }
                

                additionalFields.push(tableField);
            }
        }
        return additionalFields;
    }

    get irqWrapperList() {
        let irqWrapperList = this.individualAchievementUnitResponse?.irqWrapperList;
        return irqWrapperList;
    }

    get contentDocumentList() {
        let contentDocumentList = []
        if(this.irqWrapperList && this.irqWrapperList?.length > 0) {

            for(let irqWrapper of this.irqWrapperList) {
                
                let irq = irqWrapper.irq;
                //individualAchievementUnit existing files
                if(Object.keys(this.individualAchievementUnitExistingFiles).length > 0) {
                    let irqCdList = this.individualAchievementUnitExistingFiles[irq.Id] ?? [];
                    
                    if(irqCdList) {
                        for(let cd of irqCdList) {
                            cd.fileDeleteDisabled = (
                                irqWrapper.submissionStatusType === IRQ_SUBMITTED_STATUS_TYPE_SUBMITTED ||
                                irqWrapper.submissionStatusType === IRQ_SUBMITTED_STATUS_TYPE_CANCELLED ||
                                irqWrapper.reviewStatusType !== IRQ_REVIEW_STATUS_TYPE_OPEN
                            )
                            cd.displayName = `${cd.Title}.${cd.FileExtension}`
                        }
                    }
                    contentDocumentList = contentDocumentList?.length > 0 ? [...contentDocumentList, ...irqCdList] : irqCdList;

                }
            }
        }
        return contentDocumentList;
    }

    get haveExistingFiles() {
        return this.contentDocumentList?.length > 0 ?? false;
    }
    
    get isRequirementCompleted() {
        let result = false;
        if(this.irqWrapperList && this.irqWrapperList.length > 0) {
            for(let irqWrapper of this.irqWrapperList) {
                if(irqWrapper.submissionStatusType === IRQ_SUBMITTED_STATUS_TYPE_SUBMITTED) {
                    result = true;
                    break;
                }
            }
        }
        return result;
    }
    
    //---------------------------------------label-------------------------------
    
    get showUploadedFilesLabel() {
        return SHOW_UPLOADED_FILES_LABEL;
    }

    get hideUploadedFilesLabel() {
        return HIDE_UPLOADED_FILES_LABEL;
    }

    get completeAllRequirementsLabel() {
        return COMPLETE_ALL_REQUIREMENTS_LABEL;
    }
    //-----------------------------------------------------------------

    handleFilePreview(event) {
        this.consoleLog('handleFilePreview');
        try{
            if(!this.isCommunity){
                this[NavigationMixin.Navigate]({
                    type: 'standard__namedPage',
                    attributes:{ 
                        pageName:'filePreview'
                    },
                    state: {
                        selectedRecordId: event.currentTarget.dataset.documentid
                    }
                })
            }

        } catch(error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
            this.toggleSpinner(-1);
        }
    }

    handleFileDownload(event) {
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

        this.openDeleteConfirmation(this.label.FILE_LABEL, contentDocumentId, recordName);
    }
    
    handleToggleShowFiles(event) {
        this.showFilesValue = !this.showFilesValue;
    }

    async handleEditButtonIcon(event) {
        try{
            if(this.preventEditingIndividualAchievementUnit) {
                let recordIsLockedMsg = THE_RECORD_IS_LOCKED_LABEL.format([this.individualAchievementObjectLabel, this.individualAchievementName]);
                promptError(recordIsLockedMsg);
                return;
            }

            let modalTitle = this.label.EDIT_RECORD_LABEL.format([this.individualAchievementUnitObjLabel]);
            let result;
            if(this.isAdminMode) {
                result = await studentAchievementUnitAdminModal.open({
                    size: 'small',
                    modalTitle: modalTitle,
                    additionalUnitFieldSetName: this.additionalUnitFieldSetName,
                    unitCodeFallbackField: this.unitCodeFallbackField,
                    unitNameFallbackField: this.unitNameFallbackField,
                    verificationDetailsFieldSetName: this.verificationDetailsFieldSetName,
                    agreementRecognitionUnitCreationFieldSetName: this.agreementRecognitionUnitCreationFieldSetName,
                    individualAchievementId: this.individualAchievementId,
                    individualAchievementUnitId: this.individualAchievementUnitId,
                    aruId: this.aruId,
                    unitRequired: this.unitRequired,
                    enableDebugMode: this.enableDebugMode,
                    onfilepreview: (previewEvent) => {
                        this[NavigationMixin.Navigate]({
                            type: 'standard__namedPage',
                            attributes:{ 
                                pageName:'filePreview'
                            },
                            state: {
                                selectedRecordId: previewEvent.detail.documentId
                            }
                        })
                    }
                    
                });
            } else {
                result = await studentAchievementUnitStudentModal.open({
                    size: 'small',
                    modalTitle: modalTitle,

                    fieldSetName: this.additionalUnitFieldSetName,
                    editFormColumnNo: 2,
                    enableDebugMode: this.enableDebugMode,
                    enableNewParentCreation: false,
                    unitNameFallbackField : this.unitNameFallbackField,
                    unitCodeFallbackField : this.unitCodeFallbackField,
                    unitRequired: this.unitRequired,
                    individualAchievementUnitId: this.individualAchievementUnitId,
                    individualAchievementId: this.individualAchievementId,
                    aruId: this.aruId
                });
            }

            if(result) {
                const { operation, eventResult, eventData } = result;
                const updatedIndividualAchievementUnit = eventData;
             
                if(operation === 'submit' && eventResult === 'success') {
                    
                    this.consoleLog('individualAchievementUnitId: ' + updatedIndividualAchievementUnit.Id);

                    promptSuccess(this.label.SUCCESS_LABEL, this.label.RECORD_SAVED_LABEL);
                    notifyRecordUpdateAvailable([{recordId: updatedIndividualAchievementUnit.Id}]);
                    
                }   
            }
            this.toggleSpinner(1);
            this.dispatchEvent(new RefreshEvent());
            this.publishRefresh();
            this.toggleSpinner(-1);
        } catch (err) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(err));
        }
    }

    async handleDeleteButtonIcon(event) {
        try {
            if(this.preventEditingIndividualAchievementUnit) {
                let recordIsLockedMsg = THE_RECORD_IS_LOCKED_LABEL.format([this.individualAchievementObjectLabel, this.individualAchievementName]);
                promptError(recordIsLockedMsg);
                return;
            }


            await this.openDeleteConfirmation(this.individualAchievementUnitObjLabel, this.individualAchievementUnitId, this.individualAchievementUnitName);
        } catch(error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
        }
    }

	
    /**
     * @description open a modal to confirm delete action
     * @param {*} objLabel object label
     * @param {*} record row object of the delete record
     */
    async openDeleteConfirmation(objLabel, recordId, recordName){

        try{

            let confirmationText1 = this.label.DELETE_RECORD_CONFIRMATION_LABEL.format([objLabel, recordName]);
            let result = await genericConfirmationModal.open({
                size: 'small',
                modalTitle: this.label.DELETE_LABEL,
                confirmationText1: confirmationText1,
                confirmationText2: null,
                confirmationText3: null,
                showSubmitButton: true,
                submitButtonLabel: this.label.DELETE_LABEL,
                showCancelButton: true,
                cancelButtonLabel: this.label.CANCEL_LABEL,
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
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
        }
    }

    /**
     * @description Delete a record
     * @param {*} objLabel object label
     * @param {*} recordId record id
     */
    async deleteRecord(objLabel, recordId){
        try{

            let deletedMsg = this.label.RECORD_DELETED_LABEL.format([objLabel]);

            await deleteRecord(recordId);

            promptSuccess(this.label.SUCCESS_LABEL, deletedMsg);

            this.toggleSpinner(1);
            notifyRecordUpdateAvailable([{recordId: recordId}]);
            this.dispatchEvent(new RefreshEvent());
            this.publishRefresh();
            this.toggleSpinner(-1);

        } catch (error) {
                
            logError('Delete child record error: ', error);
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
        }
    }

    publishRefresh() {
       this.dispatchEvent(new CustomEvent('publishrefresh'));
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

    /**
     * @descripton connected callback
     */
    connectedCallback(){
		this.refreshHandlerID = registerRefreshHandler(this, this.refreshData);
	}
	
    /**
     * @descripton disconnected callback
     */
	disconnectedCallback() {
		unregisterRefreshHandler(this.refreshHandlerID);
	}

    /**
     * @description Refresh data
     */
    refreshData() {
        this.consoleLog('refreshData');
        
        refreshApex(this.individualAchievementUnitResult);

        return new Promise((resolve) => {
            resolve(true);
        });

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
        logInfo('StudentAchievementUnit', anything, this.enableDebugMode, isJson);
    }
	
}