/**
 * @Author 		WDCi (XW)
 * @Date 		Dec 2025
 * @group 		
 * @Description 
 * @changehistory
 * ISS-002633 12-05-2025 XW - new class
 */
import { LightningElement, api, wire, track } from 'lwc';
import { promptInfo, promptError, promptWarning, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';
import { initCacheIdx, commonConstants, getMergeKeys, mergeValues } from 'c/lwcUtil';
import { notifyRecordUpdateAvailable, deleteRecord, updateRecord } from 'lightning/uiRecordApi';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import { customLabels } from 'c/labelLoader';
import LANG from "@salesforce/i18n/lang";
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';

//refresh module
import { refreshApex } from '@salesforce/apex';
import { RefreshEvent, registerRefreshHandler, unregisterRefreshHandler } from 'lightning/refresh';

import IAC_OBJ from '@salesforce/schema/Individual_Achievement__c';


import IRS_TOTAL_REQUIREMENT_FIELD from '@salesforce/schema/Individual_Requirement_Set__c.Total_Requirement__c';
import IRS_TOTAL_REQUIREMENT_STUDENT_FIELD from '@salesforce/schema/Individual_Requirement_Set__c.Total_Requirement_Student__c';
import IRS_TOTAL_REVIEWED_FIELD from '@salesforce/schema/Individual_Requirement_Set__c.Total_Reviewed__c';
import IRS_TOTAL_REVIEWED_STUDENT_FIELD from '@salesforce/schema/Individual_Requirement_Set__c.Total_Reviewed_Student__c';
import IRS_TOTAL_SUBMITTED_FIELD from '@salesforce/schema/Individual_Requirement_Set__c.Total_Submitted__c';
import IRS_TOTAL_SUBMITTED_STUDENT_FIELD from '@salesforce/schema/Individual_Requirement_Set__c.Total_Submitted_Student__c';


import IAC_VERIFICATION_STATUS_FIELD from '@salesforce/schema/Individual_Achievement__c.Verification_Status__c'

import RECORD_IS_LOCKED_LABEL from "@salesforce/label/c.The_Record_Is_Locked";
import COMPLETE_REQUIREMENTS_BEFORE_SUBMIT_LABEL from "@salesforce/label/c.Student_Achievement_Complete_Requirements_Before_Submit";

import ctrlGetIndividualRequirementSets from '@salesforce/apex/REDU_StudentAchievementItem_LCTRL.getIndividualRequirementSets';
import ctrlGetIndividualAchievementVerificationStatusesInfo from '@salesforce/apex/REDU_StudentAchievement_LCTRL.getIndividualAchievementVerificationStatusesInfo';
import genericConfirmationModal from 'c/genericConfirmationModal';

const VERIFICATION_STATUS_TYPE_OPEN = 'Open';
const VERIFICATION_STATUS_TYPE_SUBMITTED = 'Submitted';
const VERIFICATION_STATUS_TYPE_REVIEW = 'Review';
const VERIFICATION_STATUS_TYPE_VERIFIED = 'Verified';
const VERIFICATION_STATUS_TYPE_REJECTED = 'Rejected';
const VERIFICATION_STATUS_TYPE_CANCELLED = 'Cancelled';

const IAC_VERIFICATION_STATUS_BADGE_TYPE_INFO = 'slds-theme_info';
const IAC_VERIFICATION_STATUS_BADGE_TYPE_SUCCESS = 'slds-theme_success';
const IAC_VERIFICATION_STATUS_BADGE_TYPE_ERROR = 'slds-theme_error';
const IAC_VERIFICATION_STATUS_BADGE_TYPE_WARNING = 'slds-theme_warning';
const IAC_VERIFICATION_STATUS_BADGE_TYPE_BASE = 'slds-theme_base';
const IAC_VERIFICATION_STATUS_BADGE_TYPE_INVERSE = 'slds-badge_inverse';
const IAC_VERIFICATION_STATUS_BADGE_TYPE_LIGHTEST = 'slds-badge_lightest';

const IAC_VERIFICATION_STATUS_BADGE_TYPE_MAP = {
    'info': IAC_VERIFICATION_STATUS_BADGE_TYPE_INFO,
    'success': IAC_VERIFICATION_STATUS_BADGE_TYPE_SUCCESS,
    'error': IAC_VERIFICATION_STATUS_BADGE_TYPE_ERROR,
    'warning': IAC_VERIFICATION_STATUS_BADGE_TYPE_WARNING,
    'base': IAC_VERIFICATION_STATUS_BADGE_TYPE_BASE,
    'inverse': IAC_VERIFICATION_STATUS_BADGE_TYPE_INVERSE,
    'lightest': IAC_VERIFICATION_STATUS_BADGE_TYPE_LIGHTEST
}


const LOCKING_MODE_LOCKED = "Locked";
const LOCKING_MODE_UNLOCKED = "Unlocked";

const RESPONSE_IRS_DATA_PARAM = 'irsData';
export default class StudentAchievementItem extends NavigationMixin(LightningElement) {
	
	//configurable attributes
    @api set individualAchievement(value){
        if(value) {
            this._individualAchievement = JSON.parse(value);
        }
    }

    get individualAchievement() {
        return this._individualAchievement;
    }

    @api userMode;
    @api individualAchievementTitleFormat;
    @api individualAchievementSubtitleFormat;
    @api individualAchievementInfoFields1;
    @api individualAchievementInfoFields2;
    
    @api showVerificationIndicator;
    @api showViewButton;
    @api showDeleteButton;
    
    //internal attribute from parent
    @api targetContactId;
    @api translationInfo;


	@api enableDebugMode = false;
	
	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false
	loadedLists = 0;
    @track _individualAchievement;
	
    //refresh handler
    refreshHandlerID;

    //local cache idx to force rerendering
    _cacheIdx;

	//labels
	label = customLabels;
	
	//js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'jquery', 'tooltips'
    modules = ["stringutil"];

    @track individualRequirementSetsResult;
    @track individualRequirementSetsResponse;
    @track individualAchievementVerificationStatusesInfoResult;
    @track individualAchievementVerificationStatusesInfoResponse;

    get individualAchievementTitleFields() {
        return getMergeKeys(this.individualAchievementTitleFormat, true);
    }

    get individualAchievementSubtitleFields() {
        return getMergeKeys(this.individualAchievementSubtitleFormat, true);
    }

    /**
     * @description Return language
     */
    get language() {
        return LANG;
    }

    /**
     * @description individual achievement id
     */
    get individualAchievementId() {
        return this.individualAchievement.Id;
    }

    /**
     * @description individualAchievement locking mode is locked
     */
    get individualAchievementIsLocked() {
        let verificationStatus = this.individualAchievement?.[IAC_VERIFICATION_STATUS_FIELD.fieldApiName];
        return this.lockedStatuses?.includes(verificationStatus);
    }

    get disableActionButton() {
        return !this.isAdminMode && this.individualAchievementIsLocked;
    }

    get isAdminMode() {
        return this.userMode === commonConstants.USER_MODE_ADMIN;
    }

    get titleLabel() {
        let mergeKeys = getMergeKeys(this.individualAchievementTitleFormat)
        return mergeValues(this.individualAchievementTitleFormat, mergeKeys, this.individualAchievement, true, this.translationInfo, this.language);
    }

    get subtitleLabel() {
        let mergeKeys = getMergeKeys(this.individualAchievementSubtitleFormat)
        return mergeValues(this.individualAchievementSubtitleFormat, mergeKeys, this.individualAchievement, true, this.translationInfo, this.language);
    }

    get showButtonMenu() {
        return this.showDeleteButton;
    }

    get verificationStatusType() {
        if(this.individualAchievement) {
            if(this.verificationStatusTypeMapping?.[VERIFICATION_STATUS_TYPE_OPEN]?.includes(this.individualAchievement.reduivy__Verification_Status__c)) {
                return VERIFICATION_STATUS_TYPE_OPEN;
            }
            if(this.verificationStatusTypeMapping?.[VERIFICATION_STATUS_TYPE_SUBMITTED]?.includes(this.individualAchievement.reduivy__Verification_Status__c)) {
                return VERIFICATION_STATUS_TYPE_SUBMITTED;
            }
            if(this.verificationStatusTypeMapping?.[VERIFICATION_STATUS_TYPE_REVIEW]?.includes(this.individualAchievement.reduivy__Verification_Status__c)) {
                return VERIFICATION_STATUS_TYPE_REVIEW;
            }
            if(this.verificationStatusTypeMapping?.[VERIFICATION_STATUS_TYPE_VERIFIED]?.includes(this.individualAchievement.reduivy__Verification_Status__c)) {
                return VERIFICATION_STATUS_TYPE_VERIFIED;
            }
            if(this.verificationStatusTypeMapping?.[VERIFICATION_STATUS_TYPE_REJECTED]?.includes(this.individualAchievement.reduivy__Verification_Status__c)) {
                return VERIFICATION_STATUS_TYPE_REJECTED;
            }
            if(this.verificationStatusTypeMapping?.[VERIFICATION_STATUS_TYPE_CANCELLED]?.includes(this.individualAchievement.reduivy__Verification_Status__c)) {
                return VERIFICATION_STATUS_TYPE_CANCELLED;
            }
        }

        return VERIFICATION_STATUS_TYPE_OPEN;
    }

    get badgeClasses() {
        if(this.individualAchievement) {
            
            let type = this.verificationStatusBadgeType?.[this.verificationStatusType] ?? "base";
            return IAC_VERIFICATION_STATUS_BADGE_TYPE_MAP[type] ?? IAC_VERIFICATION_STATUS_BADGE_TYPE_BASE;
        }
        return 'slds-badge ' + IAC_VERIFICATION_STATUS_BADGE_TYPE_BASE;
    }

    @wire(getPicklistValues, { recordTypeId: "012000000000000AAA", fieldApiName: IAC_VERIFICATION_STATUS_FIELD })
    individualAchievementVerificationStatusInfo;

    @wire(ctrlGetIndividualAchievementVerificationStatusesInfo)
    wiredGetIndividualAchievementVerificationStatusesInfo(result) {

        this.consoleLog('wiredGetIndividualAchievementVerificationStatusesInfo');
        this.individualAchievementVerificationStatusesInfoResult = result;
        this.individualAchievementVerificationStatusesInfoResponse = null;
        
        if (result.data) {
            this.individualAchievementVerificationStatusesInfoResponse = JSON.parse(result.data.responseData);
            this.consoleLog(this.individualAchievementVerificationStatusesInfoResponse, true);
        } else if (result.error) {
            promptError(customLabels.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    get verificationStatusTypeMapping() {
        return this.individualAchievementVerificationStatusesInfoResponse?.verificationStatusType;
    }

    get verificationStatusBadgeType() {
        return this.individualAchievementVerificationStatusesInfoResponse?.verificationStatusBadgeType;
    }

    get badgeLabel() {
        let verificationStatusValue = this.individualAchievement.reduivy__Verification_Status__c ? this.individualAchievement.reduivy__Verification_Status__c : this.verificationStatusTypeMapping?.[VERIFICATION_STATUS_TYPE_NOT_VERIFIED]?.[0];
        let verificationStatusLabel = this.individualAchievementVerificationStatusInfo?.data?.values?.find(field => field.value === verificationStatusValue)?.label ?? verificationStatusValue;

        return verificationStatusLabel
    }

    get lockedStatuses() {
        return this.individualAchievementVerificationStatusesInfoResponse?.lockingMode?.[LOCKING_MODE_LOCKED];
    }

    get individualAchievementInfo1List() {
        return this.individualAchievementInfoFields1.split(';');
    }

    get individualAchievementInfo1IsSet() {
        return this.individualAchievementInfo1List.length > 0;
    }

    get individualAchievementInfo2List() {
        return this.individualAchievementInfoFields2.split(';');
    }

    get individualAchievementInfo2IsSet() {
        return this.individualAchievementInfo2List.length > 0;
    }

    get individualAchievementInfoList() {
        let result = [];
        if(this.individualAchievementInfoFields1) {
            result = result.concat(this.individualAchievementInfoFields1.split(';'));
        }
        if(this.individualAchievementInfoFields2) {
            result = result.concat(this.individualAchievementInfoFields2.split(';'));
        }
        return result;
    }

    get showWarningIcon() {
        return !this.isAllRequirementsSubmitted;
    }

    get completeRequirementsBeforeSubmitLabel() {
        return COMPLETE_REQUIREMENTS_BEFORE_SUBMIT_LABEL;
    }
    
    @wire(getObjectInfo, { objectApiName: IAC_OBJ })
    individualAchievementObjectInfo;

    get individualAchievementObjectLabel() {
        return this.individualAchievementObjectInfo?.data?.label;
    }

    get individualAchievementObjectApiName() {
        return this.individualAchievementObjectInfo?.data?.apiName;
    }


    //=====================================IRQ=========================================
    get requirementSetReferencedFields() {
        return ['Id'];
    }


    @wire(ctrlGetIndividualRequirementSets, {
        individualAchievementId: '$individualAchievementId',
        cacheIdx: '$_cacheIdx'
    })
    wiredGetIndividualRequirementSets(result) {
        this.consoleLog('wiredIndividualRequirements');
        this.individualRequirementSetsResult = result;
        this.individualRequirementSetsResponse = null;

        if (result.data) {
            this.individualRequirementSetsResponse = JSON.parse(result.data.responseData);
            this.consoleLog(this.individualRequirementSetsResponse, true);
        } else if (result.error) {
            promptError(customLabels.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    get totalRequirementsFieldUsed() {
        if(this.isAdminMode) {
            return IRS_TOTAL_REQUIREMENT_FIELD.fieldApiName;
        }
        return IRS_TOTAL_REQUIREMENT_STUDENT_FIELD.fieldApiName
    }

    get totalSubmittedFieldUsed() {
        if(this.isAdminMode) {
            return IRS_TOTAL_SUBMITTED_FIELD.fieldApiName;
        }
        return IRS_TOTAL_SUBMITTED_STUDENT_FIELD.fieldApiName
    }

    get totalReviewedFieldUsed() {
        if(this.isAdminMode) {
            return IRS_TOTAL_REVIEWED_FIELD.fieldApiName;
        }
        return IRS_TOTAL_REVIEWED_STUDENT_FIELD.fieldApiName
    }

    get totalRequirements() {
        let total = 0;
        if(this.individualRequirementSetsResponse) {
            for(let irs of this.individualRequirementSetsResponse) {
                total += irs?.[this.totalRequirementsFieldUsed] ?? 0;
            }
        }
        return total;
    }

    get totalReviewed() {
        let total = 0;
        if(this.individualRequirementSetsResponse) {
            for(let irs of this.individualRequirementSetsResponse) {
                total += irs?.[this.totalReviewedFieldUsed] ?? 0;
            }
        }
        return total;
    }

    get totalSubmitted() {
        
        let total = 0;
        if(this.individualRequirementSetsResponse) {
            for(let irs of this.individualRequirementSetsResponse) {
                total += irs?.[this.totalSubmittedFieldUsed] ?? 0;
            }
        }
        return total;
    }

    get irsData() {
        return this.individualRequirementSetsResponse?.[RESPONSE_IRS_DATA_PARAM] ?? [];
    }

    get isAllRequirementsSubmitted() {
        return this.totalRequirements === this.totalSubmitted;
    }

    //==============================Wizard Config===================================================

    async handleViewClick() {
        this.consoleLog('handleViewClick')

        try {

            const individualAchievementPageRef = {
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.individualAchievementId,
                    actionName: 'view'
                }
            }

            this[NavigationMixin.Navigate] (individualAchievementPageRef);

        } catch (error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
        }
    }

    async handleActionMenuSelected(event) {
        
        let selectedItemValue = event.detail.value;
        this.consoleLog('handleActionMenuSelected: selectedItemValue:' + selectedItemValue)

        if(this.individualAchievementIsLocked && !this.isAdminMode) {
            this.consoleLog(`individualAchievementIsLocked:${this.individualAchievementIsLocked} - isAdminMode:${this.isAdminMode}`)
            let errorMessage = RECORD_IS_LOCKED_LABEL.format([this.individualAchievementObjectLabel, this.individualAchievement.Name]);
            promptError(this.label.ERROR_LABEL, errorMessage);
            return;
        } 
        if (selectedItemValue === "delete") {
            this.deleteIndividualAchievementConfirmation();
        }
        
    }

    async deleteIndividualAchievementConfirmation() {
        let deleteMessage = this.label.DELETE_RECORD_CONFIRMATION_LABEL.format([this.individualAchievementObjectLabel, this.individualAchievement.Name]);
        this.consoleLog('deleteIndividualAchievementConfirmation')
        let result = await genericConfirmationModal.open({
            size: 'small',
            modalTitle: this.label.DELETE_LABEL,
            confirmationText1: deleteMessage,
            confirmationText2: null,
            confirmationText3: null,
            showSubmitButton: true,
            submitButtonLabel: this.label.DELETE_LABEL,
            showCancelButton: true,
            cancelButtonLabel: this.label.CANCEL_LABEL,
            eventSource: 'deleteIndividualAchievement',
            eventData: this.individualAchievement,
            enableDebugMode: this.enableDebugMode
        });

        this.consoleLog('genericConfirmationModal close');
        this.consoleLog(result, true);

        if (result){
            const { operation, eventSource, eventData } = result; 
            if(operation === 'submit' && eventSource === 'deleteIndividualAchievement') {
                this.deleteRecord(eventData.Id);
            }
        }
    }

    /**
    * @description Delete a record
    * @param {*} objLabel object label
    * @param {*} recordId record id
    */
    deleteRecord(recordId){
        try{

            let deletedMsg = this.label.RECORD_DELETED_LABEL.format([this.individualAchievementObjectLabel]);

            deleteRecord(recordId).then(()=>{
                promptSuccess(this.label.SUCCESS_LABEL, deletedMsg);

                this.toggleSpinner(1);
                notifyRecordUpdateAvailable([{recordId: recordId}]);
                this.dispatchEvent(new RefreshEvent());
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
        this._cacheIdx = initCacheIdx();
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
        
        //update the cacheIdx if you need to force the wire method to get new data from apex
        this._cacheIdx = initCacheIdx();

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
        logInfo('StudentAchievementItem', anything, this.enableDebugMode, isJson);
    }
	
}