/**
 * @Author 		WDCi (XW)
 * @Date 		June 2025
 * @group 		Requirement Checklist
 * @Description Item of Requirement Checklist component
 * @changehistory
 * ISS-002128 06-06-2025 XW - new class
 * ISS-002604 12-09-2025 Lean - fixed download url
 * ISS-002665 10-11-2025 XiRouh - Added submissionStatusType() and statusTypeIconAlternateTextAndTitle() updated the reviewStatusTypeIcon() to returns the icon while also considering the submission type
 */
import { LightningElement, api, wire, track } from 'lwc';
import { promptInfo, promptError, promptWarning, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';
import { initCacheIdx, commonConstants, getFileDownloadUrl } from 'c/lwcUtil';
import { notifyRecordUpdateAvailable, updateRecord, deleteRecord } from 'lightning/uiRecordApi';
import { customLabels } from 'c/labelLoader';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { NavigationMixin } from 'lightning/navigation';

//object and fields
import IRQ_SUBMISSION_STATUS_FIELD from '@salesforce/schema/Individual_Requirement__c.Submission_Status__c';
import IRQ_REVIEW_STATUS_FIELD from '@salesforce/schema/Individual_Requirement__c.Review_Status__c';
import IRQ_ID_FIELD from '@salesforce/schema/Individual_Requirement__c.Id';
import IRQ_OBJ from '@salesforce/schema/Individual_Requirement__c';
import IAC_OBJ from '@salesforce/schema/Individual_Achievement__c';

//refresh module
import { refreshApex } from '@salesforce/apex';
import { RefreshEvent, registerRefreshHandler, unregisterRefreshHandler } from 'lightning/refresh';

import MESSAGE_CHANNEL from "@salesforce/messageChannel/c__privateLwcMessageChannel__c"

//apex method
import ctrlGetExistingUploadedFiles from '@salesforce/apex/REDU_RequirementChecklistFile_LCTRL.getExistingUploadedFiles';

//custom label
import DETAILS_LABEL from '@salesforce/label/c.Requirement_Checklist_Details';
import UPLOAD_LABEL from '@salesforce/label/c.Requirement_Checklist_Upload';
import PREVIEW_LABEL from '@salesforce/label/c.Requirement_Checklist_Preview';
import DOWNLOAD_LABEL from '@salesforce/label/c.Download';
import SHOW_UPLOADED_FILES_LABEL from '@salesforce/label/c.Requirement_Checklist_Show_Uploaded_Files';
import HIDE_UPLOADED_FILES_LABEL from '@salesforce/label/c.Requirement_Checklist_Hide_Uploaded_Files';
import LINK_TO_IAC_LABEL from '@salesforce/label/c.Requirement_Checklist_Link_To_IAC';
import INVALID_VALUE_DEFINED_LABEL from '@salesforce/label/c.Invalid_Value_Defined_In_Field';
import UPDATE_REMARKS_LABEL from '@salesforce/label/c.Requirement_Checklist_Update_Remarks';

import requirementChecklistFileModal from 'c/requirementChecklistFileModal';
import requirementChecklistFieldUpdateModal from 'c/requirementChecklistFieldUpdateModal'
import requirementChecklistIdvAchievementModal from 'c/requirementChecklistIdvAchievementModal'
import genericConfirmationModal from 'c/genericConfirmationModal';
import recordEditModal from 'c/recordEditModal'

const REVIEW_STATUS_TYPE_ACCEPTED = 'Accepted';
const REVIEW_STATUS_TYPE_REJECTED = 'Rejected';
const REVIEW_STATUS_TYPE_CANCELLED = 'Cancelled';
const REVIEW_STATUS_TYPE_OPEN = 'Open';
const REVIEW_STATUS_TYPE_REVIEWING = 'Reviewing';
const REVIEW_STATUS_TYPE_SUBMITTED = 'Submitted';

const SUBMISSION_STATUS_TYPE_SUBMITTED = 'Submitted';
const SUBMISSION_STATUS_TYPE_RESUBMISSION_REQUESTED = 'Resubmission_Requested';
const SUBMISSION_STATUS_TYPE_CANCELLED = 'Cancelled';

const REQUIREMENT_TYPE_FILE_UPLOAD = 'File Upload';
const REQUIREMENT_TYPE_ACTION = 'Action';
const REQUIREMENT_TYPE_FIELD_UPDATE = 'Field Update';

const IRQ_LINK_TO_IAC_YES = 'Yes'
const IRQ_LINK_TO_IAC_NO = 'No'

export default class RequirementChecklistItem extends NavigationMixin(LightningElement) {
	
	//configurable attributes
    @api userMode;
    @api parentId;
    @api irqWrapper;
    @api requirementTitleField;
    @api requirementDetailsFields;

    @api openIcon;
    @api submittedIcon;
    @api reviewingIcon;
    @api acceptedIcon;
    @api rejectedIcon;
    @api cancelledIcon;
    @api resubmissionRequestedIcon;
	
    @api showRequirementRowDetailsButton;
    @api showRequirementUserActionButton;
    @api showRequirementApprovalActionButton;

    @api achievementDetailsFields;
    @api createAchievementDetailsFieldSet;

    @api isCommunity = false;
    @api sitePath;
    
    //ISS-002604
    @api downloadUrl;

    //ISS-002666
    @api promptRemarksAfterReviewStatusUpdate;
    @api showRemarksAction;
    @api remarksFieldSetName;

    // ISS-002665 - To set the submission status based on the configured status in the wizard or the custom metadata configuration when the buttons are clicked in the requirement checklist wizard.
    @api submissionStatus;
    @api defaultSubmittedStatus; //fallback status if the submissionStatus is blank

	@api enableDebugMode = false;
    @api recordId; //the record id of the component is being placed

	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false
	loadedLists = 0;
    showUploadedFiles = false;
	
    //refresh handler
    refreshHandlerID;

    //wire attribute
    irqReviewStatusPicklistResult;
    irqReviewStatusPicklistResponse;
    existingUploadedFilesResult;
    existingUploadedFilesResponse;

	//labels
	label = {
        DETAILS_LABEL,
        UPLOAD_LABEL,
        PREVIEW_LABEL,
        DOWNLOAD_LABEL,
        SHOW_UPLOADED_FILES_LABEL,
        HIDE_UPLOADED_FILES_LABEL,
        UPDATE_REMARKS_LABEL,
        ...customLabels
    };
	
	//js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'jquery', 'tooltips'
    modules = ['stringutil'];

    @wire(getObjectInfo, { objectApiName: IRQ_OBJ })
    wireIrqObj;

    @wire(getObjectInfo, { objectApiName: IAC_OBJ })
    iacObj;

    /**
     * @description label of individual achievement
     */
    get iacObjectLabel() {
        return this.iacObj?.data?.label;
    }

    /**
     * @description api name of individual requirement
     */
    get irqObjectApiName() {
        return this.wireIrqObj?.data?.apiName;
    }

    /**
     * @description default record type of individual requirement
     */
    get irqDefaultRecordTypeId() {
        return this.wireIrqObj?.data?.defaultRecordTypeId;
    }

    /**
     * @description object fields label
     */
    get irqObjectFieldsLabel() {
        return this.wireIrqObj?.data?.fields?.reduivy__Object_Fields__c?.label;
    }

    /**
     * @description object relation field label
     */
    get irqObjectRelationFieldLabel() {
        return this.wireIrqObj?.data?.fields?.reduivy__Object_Relation_Field__c?.label;
    }
    
    /**
     * @description get the picklist values of the review status field 
     */
    @wire(getPicklistValues, { recordTypeId: '$irqDefaultRecordTypeId', fieldApiName: IRQ_REVIEW_STATUS_FIELD })
    wireIrqReviewStatusPicklist(result) {
        this.irqReviewStatusPicklistResult = result;
        this.irqReviewStatusPicklistResponse = null;
        this.consoleLog('wireIrqReviewStatusPicklist');

        if(result.data) {
            this.irqReviewStatusPicklistResponse = result.data;
            this.consoleLog(this.irqReviewStatusPicklistResponse, true)
        } else if(result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    /**
     * @description get the menu item for the review status
     */
    get irqReviewStatusMenuItems() {
        this.consoleLog('irqReviewStatusMenuItems');
        if(this.irqReviewStatusPicklistResponse) {
            let result = [];
            if(this.wireIrqObj.data && this.wireIrqObj?.data?.fields?.reduivy__Review_Status__c) {
                result.push({
                    isSubHeader: true,
                    label: this.wireIrqObj?.data?.fields?.reduivy__Review_Status__c?.label,
                    value: this.wireIrqObj?.data?.fields?.reduivy__Review_Status__c?.value
                });
            }

            for(let opt of this.irqReviewStatusPicklistResponse.values){
                let menuItem = {
                    isSubHeader: false,
                    label: opt.label,
                    value: opt.value,
                    disabled: opt.value === this.irqWrapper.irq.reduivy__Review_Status__c
                }
                result.push(menuItem);
            }
            this.consoleLog(result, true);
            return result;
        }

        return [];
    }

    /**
     * @description return true if the subcategory action should be shown
     */
    get showActionMenuItem() {
        return this.showLinkToIac || this.showRemarksAction;
    }

    /**
     * @description return true if show link to individual achievement should be shown
     */
    get showLinkToIac() {
        return this.irqWrapper?.irq?.reduivy__Link_To_Individual_Achievement__c === IRQ_LINK_TO_IAC_YES && this.userMode === commonConstants.USER_MODE_ADMIN;
    }

    /**
     * @description label of link to individual achievement label
     */
    get linkToIacLabel() {
        return LINK_TO_IAC_LABEL.format([this.iacObjectLabel]);
    }

    /**
     * @description get uploaded files
     */
    @wire(ctrlGetExistingUploadedFiles, {
        recordId: "$irqWrapper.irq.Id"
    })
    wireGetExistingUploadedFiles(result) {
        
        this.existingUploadedFilesResult = result;
        this.existingUploadedFilesResponse = null;

        if (result.data) {
            this.existingUploadedFilesResponse = JSON.parse(result.data.responseData);
            this.consoleLog(this.existingUploadedFilesResponse, true);
        } else if (result.error) {
            promptError(customLabels.ERROR_LABEL, getErrorMessage(result.error));
        }

    }

    /**
     * @description the existing uploaded files of the individual requirement record
     */
    get existingUploadedFiles() {
        if(this.existingUploadedFilesResponse) {
            return this.existingUploadedFilesResponse;
        }
        return [];
    }

    /**
     * @description the list of uploaded files of the individual requirement
     */
    get existingUploadedFilesWrapperList(){
        
        let result = [];

        try {
            for(let file of this.existingUploadedFiles) {
                let fullPath = getFileDownloadUrl(this.sitePath, this.downloadUrl, file.LatestPublishedVersionId);

                result.push({
                    Title: file.Title,
                    FileExtension: file.FileExtension,
                    id: file.Id,
                    ContentVersionId: file.ContentVersionId,
                    download: fullPath
                })
            }

            return result;
        } catch (error) {
            logError(getErrorMessage(error));
            return result;
        }
    }


    /**
     * @description get field api name of the individual requirement to displayed on the details
     */
    get requirementDetailsFieldsList(){
        if(this.requirementDetailsFields) {
            return this.requirementDetailsFields.split(';');
        }
        return [];
    }

    /**
     * @description the review status type of the current individual requirement
     */
    get reviewStatusType() {
        if(this.irqWrapper) {
            return this.irqWrapper?.reviewStatusType;
        }
        return "";
    }

    /**
     * @description the submission status type of the current individual requirement
     */
    get submissionStatusType() {
        if(this.irqWrapper) {
            return this.irqWrapper?.submissionStatusType;
        }
        return "";
    }

    /**
     * @description the Alternate Text And Title of the status type
     */
    get statusTypeIconAlternateTextAndTitle() {
        if(this.submissionStatusType && this.submissionStatusType === SUBMISSION_STATUS_TYPE_RESUBMISSION_REQUESTED) {

            return this.submissionStatusType;

        } else if(this.reviewStatusType) {
            
            return this.reviewStatusType;
        }

        return "";
    }

    /**
     * @description the icon of the current review status type
     */
    get statusTypeIcon() {
        let resultIconName = this.openIcon;

        if(this.submissionStatusType && this.submissionStatusType === SUBMISSION_STATUS_TYPE_RESUBMISSION_REQUESTED) {
            resultIconName = this.resubmissionRequestedIcon;

            return resultIconName;
        }
        
        if (this.reviewStatusType === REVIEW_STATUS_TYPE_ACCEPTED) {
            resultIconName = this.acceptedIcon;
        }
        else if (this.reviewStatusType === REVIEW_STATUS_TYPE_REJECTED) {
            resultIconName = this.rejectedIcon
        }
        else if (this.reviewStatusType === REVIEW_STATUS_TYPE_CANCELLED) {
            resultIconName = this.cancelledIcon
        }
        else if (this.reviewStatusType === REVIEW_STATUS_TYPE_OPEN) {
            resultIconName = this.openIcon
        }
        else if (this.reviewStatusType === REVIEW_STATUS_TYPE_REVIEWING) {
            resultIconName = this.reviewingIcon
        }
        else if (this.reviewStatusType === REVIEW_STATUS_TYPE_SUBMITTED) {
            resultIconName = this.submittedIcon
        }
          
        return resultIconName;
    }

    /**
     * @description the individual requirement title to be displayed
     */
    get irqTitle(){
        return this.irqWrapper?.irq?.[this.requirementTitleField];
    }

    /**
     * @description return true if the submit button (upload/done) should be disabled
     */
    get isSubmitDisabled(){
        if(this.irqWrapper?.irq){
            return this.submissionStatusType === SUBMISSION_STATUS_TYPE_SUBMITTED || this.submissionStatusType === SUBMISSION_STATUS_TYPE_CANCELLED || this.reviewStatusType !== REVIEW_STATUS_TYPE_OPEN;
        }
        return false;
    }

    /**
     * @description return true if the done button should be shown (requirement type is action)
     */
    get showDoneButton() {
        if(this.irqWrapper?.irq.reduivy__Requirement_Type__c === REQUIREMENT_TYPE_ACTION) {
            return true;
        }
        return false;
    }

    /**
     * @description return true if the upload button should be shown (requirement type is file upload)
     */
    get showUploadButton() {
        if(this.irqWrapper?.irq.reduivy__Requirement_Type__c === REQUIREMENT_TYPE_FILE_UPLOAD) {
            return true;
        }
        return false;
    }

    /**
     * @description return true if the upload button should be shown (requirement type is field update)
     */
    get showUpdateButton() {
        if(this.irqWrapper?.irq.reduivy__Requirement_Type__c === REQUIREMENT_TYPE_FIELD_UPDATE) {
            return true;
        }
        return false;
    }

    get showUploadedFilesButton() {
        return this.showUploadButton && this.existingUploadedFiles.length > 0;
    }

    get showUploadedFilesSection() {
        return this.showUploadedFiles;
    }

    /**
     * @description Return submitted status
     */
    get submittedStatus() {
        if (this.submissionStatus) {
            return this.submissionStatus;
        }

        return this.defaultSubmittedStatus;
    }

    /**
     * @description navigate to the individual requirement record page when the title or detail button is clicked
     */
    handleRequirementTitleClick() {
        this.consoleLog('handleRequirementTitleClick');
        if(this.irqWrapper?.irq?.Id){
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.irqWrapper?.irq?.Id,
                    actionName: 'view',
                },
            });
        }
    }

    /**
     * @description update the individual requirement to submitted if done button is cliked
     */
    async handleRequirementDoneClick() {
        this.consoleLog('handleRequirementDoneClick');
        try {
            this.toggleSpinner(1);
        
            //update to submitted
            const fields = {};
            fields[IRQ_ID_FIELD.fieldApiName] = this.irqWrapper.irq.Id;

            // ISS-002665 - To set the submission status based on the configured status in the wizard or the custom metadata configuration when the buttons are clicked in the requirement checklist wizard.
            let submissionStatus = this.submittedStatus;

            fields[IRQ_SUBMISSION_STATUS_FIELD.fieldApiName] = submissionStatus;

            const recordInput = { fields };
            
            await updateRecord(recordInput);
            this.consoleLog('updated record');
            this.consoleLog(recordInput, true);
            promptSuccess(this.label.SUCCESS_LABEL, this.label.YOUR_CHANGES_ARE_SAVED_LABEL);
            this.dispatchEvent(new RefreshEvent());
            this.publishRefresh();
            notifyRecordUpdateAvailable([{recordId: this.irqWrapper.irq.Id}]);
            this.toggleSpinner(-1);
        } catch(error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
            this.toggleSpinner(-1);
        }
    }

    /**
     * @description update the individual requirement to submitted if upload button is cliked
     */
    async handleRequirementUploadClick() {
        this.consoleLog('handleRequirementUploadClick');
        try{
            let result = await requirementChecklistFileModal.open({
                size: "small",
                headerLabel: this.irqTitle,
                parentId: this.parentId,
                uploadedFiles: this.existingUploadedFiles,
                irq : this.irqWrapper?.irq,
                enableDebugMode: this.enableDebugMode
            });
            this.toggleSpinner(1);
            
            if (result) {
                this.consoleLog(result, true);

                const {operation, eventSource, eventData} = result;
                if(operation === 'save' && eventSource === 'submit') {
                    //update to submitted
                    const fields = {};
                    fields[IRQ_ID_FIELD.fieldApiName] = eventData.Id;

                    // ISS-002665 - To set the submission status based on the configured status in the wizard or the custom metadata configuration when the buttons are clicked in the requirement checklist wizard.
                    let submissionStatus = this.submittedStatus;

                    fields[IRQ_SUBMISSION_STATUS_FIELD.fieldApiName] = submissionStatus;
                    
                    const recordInput = { fields };
                    this.consoleLog(recordInput, true);
                    
                    await updateRecord(recordInput);
                    promptSuccess(this.label.SUCCESS_LABEL, this.label.YOUR_CHANGES_ARE_SAVED_LABEL);
                    notifyRecordUpdateAvailable([{recordId: eventData.Id}]);
                }
            }
            this.dispatchEvent(new RefreshEvent());
            this.publishRefresh();
            this.toggleSpinner(-1);
            
        } catch(error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
            this.toggleSpinner(-1);
        }
        
    }

    /**
     * @description open the field update modal. if mark as done button is clicked, update irq to submitted
     */
    async handleRequirementFieldUpdateClick(){
        this.consoleLog('handleRequirementFieldUpdateClick');
        try{
            let objectFields = this.irqWrapper?.irq?.reduivy__Object_Fields__c;
            let objectRelationField = this.irqWrapper?.irq?.reduivy__Object_Relation_Field__c;
            if(!objectFields) {
                promptError(this.label.ERROR_LABEL, INVALID_VALUE_DEFINED_LABEL.format([this.irqObjectFieldsLabel]));
                return;
            } else if(!objectRelationField) {
                promptError(this.label.ERROR_LABEL, INVALID_VALUE_DEFINED_LABEL.format([this.irqObjectRelationFieldLabel]));
                return;
            }

            let result = await requirementChecklistFieldUpdateModal.open({
                size: "small",
                headerLabel: this.irqWrapper?.irq?.Name,
                irqId : this.irqWrapper?.irq?.Id,
                objectFields: this.irqWrapper?.irq?.reduivy__Object_Fields__c,
                objectRelationField: this.irqWrapper?.irq?.reduivy__Object_Relation_Field__c,
                enableDebugMode: this.enableDebugMode
            });

            this.consoleLog('handleRequirementFieldUpdateClick closed');

            if(result) {
                const { operation, eventData } = result;

                if(operation === 'buttonSave' || operation === 'buttonSaveDone') {
                    if (operation === 'buttonSaveDone') {
                        this.toggleSpinner(1);
                        this.consoleLog('buttonSaveDone');
                        //update to submitted
                        const fields = {};
                        fields[IRQ_ID_FIELD.fieldApiName] = this.irqWrapper?.irq?.Id;

                        // ISS-002665 - To set the submission status based on the configured status in the wizard or the custom metadata configuration when the buttons are clicked in the requirement checklist wizard.
                        let submissionStatus = this.submittedStatus;

                        fields[IRQ_SUBMISSION_STATUS_FIELD.fieldApiName] = submissionStatus;
                        
                        const recordInput = { fields };
                        this.consoleLog(recordInput, true);
                        
                        await updateRecord(recordInput);
                        this.toggleSpinner(-1);
                    }

                    this.dispatchEvent(new RefreshEvent());
                    this.publishRefresh();
                    notifyRecordUpdateAvailable([{recordId: eventData.id}]);
                    promptSuccess(this.label.SUCCESS_LABEL, this.label.YOUR_CHANGES_ARE_SAVED_LABEL);
                }
            }
            
        } catch(error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
            this.toggleSpinner(-1);
        }
    }

    /**
     * @description update the review status when the menu item review status is updated
     */
    async handleApprovalStatusClick(event) {
        this.consoleLog('handleApprovalStatusClick');
        let selectedValue = event.detail.value;
        this.toggleSpinner(1);
        if(selectedValue && selectedValue === 'iac') {
            await this.handleLinkIndividualAchievement();
        } else if (selectedValue && selectedValue === 'remarks') {
            await this.handleUpdateRemarks();
        } else if(selectedValue && this.irqWrapper?.irq?.Id) {
            const fields = {};
            fields[IRQ_ID_FIELD.fieldApiName] = this.irqWrapper?.irq?.Id;
            fields[IRQ_REVIEW_STATUS_FIELD.fieldApiName] = selectedValue;

            
            const recordInput = { fields };
            this.consoleLog(recordInput, true);

            try{   
                await updateRecord(recordInput);
                this.dispatchEvent(new RefreshEvent());
                this.publishRefresh();
                promptSuccess(this.label.SUCCESS_LABEL, this.label.YOUR_CHANGES_ARE_SAVED_LABEL);
                notifyRecordUpdateAvailable([{recordId: this.irqWrapper?.irq?.Id}]);

                if(this.promptRemarksAfterReviewStatusUpdate) {
                    await this.handleUpdateRemarks();
                }

            } catch(error) {
                promptError(this.label.ERROR_LABEL, getErrorMessage(error));
                this.toggleSpinner(-1);
            }

        }
        
        this.toggleSpinner(-1);
    }
    
    publishRefresh(){
        this.dispatchEvent(new CustomEvent('publishrefresh'));
    }                                                                          


    /**
     * @description pop up the preview file
     */
    handleFilePreview(event){
        this.consoleLog('handleFilePreview');
        try{
            if(!this.isCommunity){
                this[NavigationMixin.Navigate]({
                    type: 'standard__namedPage',
                    attributes:{ 
                        pageName:'filePreview'
                    },
                    state: {
                        selectedRecordId: event.currentTarget.dataset.id
                    }
                })
            }

        } catch(error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
            this.toggleSpinner(-1);
        }
    }

    /**
     * @description download the file selected
     */
    handleFileDownload(event){
        this.consoleLog('handleFileDownload');
        window.open(event.currentTarget.dataset.download, '_blank');
    }

    /**
     * @description delete the file selected
     */
    handleFileDelete(event){
        this.consoleLog('handleFileDelete');
        
        let contentDocumentId = event.currentTarget.dataset.id;
        let fileTitle = event.currentTarget.dataset.filetitle;
        let fileExtension = event.currentTarget.dataset.fileextension;

        let record = {
            Name: `${fileTitle}.${fileExtension}`,
            Id: contentDocumentId
        }

        this.openDeleteConfirmation(this.label.FILE_LABEL, record);
    }

    /**
     * @description open a modal to confirm delete action
     * @param {*} objLabel object label
     * @param {*} record row object of the delete record
     */
    openDeleteConfirmation(objLabel, record){

        let confirmationText1 = this.label.DELETE_RECORD_CONFIRMATION_LABEL.format([objLabel, record.Name]);
        genericConfirmationModal.open({
            size: 'small',
            modalTitle: this.label.DELETE_LABEL,
            confirmationText1: confirmationText1,
            confirmationText2: null,
            confirmationText3: null,
            showSubmitButton: true,
            submitButtonLabel: this.label.DELETE_LABEL,
            showCancelButton: true,
            cancelButtonLabel: this.label.CANCEL_LABEL,
            eventSource: 'deleteChildRecord',
            eventData: record,
            enableDebugMode: this.enableDebugMode
        }).then(result=>{
            if (result){
                const { operation, eventSource, eventData } = result; 
                if(operation === 'submit' && eventSource === 'deleteChildRecord') {
                    this.deleteRecord(objLabel, eventData.Id);
                }
            }
        })
    }

    /**
     * @description Delete a record
     * @param {*} objLabel object label
     * @param {*} recordId record id
     */
    deleteRecord(objLabel, recordId){
        try{

            let deletedMsg = this.label.RECORD_DELETED_LABEL.format([objLabel]);

            deleteRecord(recordId).then(()=>{
                promptSuccess(this.label.SUCCESS_LABEL, deletedMsg);

                this.toggleSpinner(1);
                this.refreshData();
                this.toggleSpinner(-1);

            }).catch(error=>{
                
                logError('Delete child record error: ', error);
                promptError(this.label.ERROR_LABEL, getErrorMessage(error));
            })
        } catch (error) {
                
            logError('Delete child record error: ', error);
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
        }
    }
    
    /**
     * @description toggle the show uploaded files button status
     */
    handleToggleShowUploadedFiles(){
        this.consoleLog('handleToggleShowUploadedFiles');
        this.showUploadedFiles = !this.showUploadedFiles;
    }

    /**
     * @description open the link individual achievement modal
     */
    async handleLinkIndividualAchievement(){
        this.consoleLog('handleLinkIndividualAchievement');
        this.toggleSpinner(1);
        try{
            let result = await requirementChecklistIdvAchievementModal.open({
                size: "small",
                headerLabel: this.irqWrapper?.irq?.Name,
                irqId : this.irqWrapper?.irq?.Id,
                conId : this.irqWrapper?.irq?.reduivy__Individual_Requirement_Set__r?.reduivy__Contact__c,
                achievementDetailsFields: this.achievementDetailsFields,
                createAchievementDetailsFieldSet: this.createAchievementDetailsFieldSet,
                enableDebugMode: this.enableDebugMode
            });
            this.consoleLog(result);
            if (result) {
                this.consoleLog('requirementChecklistIdvAchievementModal.close');
                this.consoleLog(result, true);
                
                const {operation, eventSource, eventData} = result;
                if(operation === 'close' && eventSource === 'submit' && eventData.length > 0) {
                    
                    promptSuccess(this.label.SUCCESS_LABEL, this.label.YOUR_CHANGES_ARE_SAVED_LABEL);
                    notifyRecordUpdateAvailable([{recordId: eventData.id}]);
                    this.consoleLog(eventData, true);
                    this.dispatchEvent(new RefreshEvent());
                    this.publishRefresh();
                }
            }
            this.toggleSpinner(-1);


        } catch(error) {
            this.consoleLog('requirementChecklistIdvAchievementModal error');
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
            this.toggleSpinner(-1);
        }
    }

    /**
     * @description open the record edit modal
     */
    async handleUpdateRemarks() {
        this.consoleLog('handleUpdateRemarks');
        try{
            this.toggleSpinner(1);

            let result = await recordEditModal.open({
                size: "small",
                headerLabel: UPDATE_REMARKS_LABEL,
                enableDebugMode: this.enableDebugMode,
                objectApiName: this.irqObjectApiName,
                fieldSetName: this.remarksFieldSetName,
                editFormColumnNo: 2,
                recordId: this.irqWrapper.irq.Id
            });

            if(result) {
                const {operation, eventResult, eventData} = result;
                if(operation === 'submit' && eventResult === 'success') {
                    this.consoleLog('eventData');
                    this.consoleLog(eventData, true);
                    promptSuccess(this.label.SUCCESS_LABEL, this.label.YOUR_CHANGES_ARE_SAVED_LABEL);
                    notifyRecordUpdateAvailable([{recordId: this.irqWrapper.irq.Id}]);
                }
            }

            this.consoleLog('handleUpdateRemarks.close');
            this.refreshData();
            
            this.toggleSpinner(-1);

        } catch(error) {
            this.consoleLog('requirementChecklistRemarksModal error');
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
            this.toggleSpinner(-1);
        }
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
        this.toggleSpinner(1);
        
        refreshApex(this.irqReviewStatusPicklistResult);
        refreshApex(this.existingUploadedFilesResult)
        
        this.toggleSpinner(-1);
        
        return new Promise((resolve) => {
            resolve(true);
        });

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
        logInfo('RequirementChecklistItem', anything, this.enableDebugMode, isJson);
    }
	
}