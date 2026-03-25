/**
 * @Author 		WDCi (Sueanne)
 * @Date 		Sept 2024
 * @group 		Enrollment Wizard
 * @Description to render study session with session time info in session enrollment wizard
 * @changehistory
 * ISS-002050 17-09-2024 Sueanne - new component
 * ISS-002254 16-01-2025 XW - fixed bug where enrollment wizard keeps loading when reattempting the enrollment
 * ISS-002255 16-01-2025 XW - do not show waitlist button if enroll/unenroll button is showing
 * ISS-002330 20-03-2025 XW - study session title and study session time title are configurable
 * ISS-002370 08-04-2025 XW - added notifyRecordUpdateAvailable after upsertEnrollment for isn
 * ISS-002401 22-04-2025 Lean - Respect the allow enrollment config from enrollment action status
 * ISS-002397 22-04-2025 XiRouh - Removed the check for the number of available places and the unlimited places flag in the showPreEnrollButton getter
 */
import { LightningElement, api, wire, track } from 'lwc';
import { promptInfo, promptError, promptWarning, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';
import { customLabels } from 'c/labelLoader';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { initCacheIdx, commonConstants, extractFieldValue } from 'c/lwcUtil';

import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import SSE_OBJECT from '@salesforce/schema/Study_Session__c';
import ISN_OBJECT from '@salesforce/schema/Individual_Session_Enrollment__c';

import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import ENROLLMENT_STATUS_FIELD from '@salesforce/schema/Individual_Session_Enrollment__c.Enrollment_Status__c';

import { refreshApex } from '@salesforce/apex';
import { RefreshEvent, registerRefreshHandler, unregisterRefreshHandler } from 'lightning/refresh';

import { ipePathwayConstants, sseStatusTypes, isnEnrollmentStatusTypes } from 'c/ipePathwaysHelper';

//Apex method
import ctrlInitStudySession from '@salesforce/apex/REDU_IpePathwayStudySession_LCTRL.initStudySession';
import ctrlGetStudySessionTime from '@salesforce/apex/REDU_IpePathwayStudySession_LCTRL.getStudySessionTime';
import ctrlSseStatuses from '@salesforce/apex/REDU_IpePathwayStudySession_LCTRL.getStudySessionStatuses';
import ctrlIsnStatuses from '@salesforce/apex/REDU_IpePathwayStudySession_LCTRL.getIndividualSessionEnrollmentStatuses';
import ctrlUpsertEnrollment from '@salesforce/apex/REDU_IpePathwayStudySession_LCTRL.upsertEnrollment';
import ctrlCheckEventConflict from '@salesforce/apex/REDU_IpePathwayStudySession_LCTRL.checkEventConflict';
import ctrlGetTranslationFieldForNameByObjPrefix from '@salesforce/apex/REDU_Translation_LCTRL.getTranslationFieldForNameByObjPrefix';

//Labels
import ENROLLMENT_ERRORS_FOR_RETRY_LABEL from '@salesforce/label/c.Enrollment_Errors_For_Retry';
import PREENROLL_CONFIRMATION_LABEL from '@salesforce/label/c.Pre_Enrollment_Confirmation';
import WITHDRAW_PREENROLL_CONFIRMATION_LABEL from '@salesforce/label/c.Withdraw_Pre_Enrollment_Confirmation';
import ENROLL_CONFIRMATION_LABEL from '@salesforce/label/c.Enrollment_Confirmation';
import UNENROLL_CONFIRMATION_LABEL from '@salesforce/label/c.Unenrollment_Confirmation';
import REQUEST_UNENROLL_CONFIRMATION_LABEL from '@salesforce/label/c.Request_Unenrollment_Confirmation';
import JOIN_WAITLIST_CONFIRMATION_LABEL from '@salesforce/label/c.Join_Waitlist_Confirmation';
import WITHDRAW_WAITLIST_CONFIRMATION_LABEL from '@salesforce/label/c.Withdraw_Waitlist_Confirmation';
import STUDY_SESSION_CONFLICT_WARNING_LABEL from '@salesforce/label/c.Study_Session_Conflict_Warning';

//Modal
import confirmationModal from 'c/genericConfirmationModal';

/**
 * @description the object to get the translation name
 */
const OBJ_TRANSLATION = [
    "SSE"
];

export default class IpePathwayStudySession extends LightningElement {

    //configurable attributes
    @api userMode;
    @api studySessionTitleField;
    @api studySessionInfoFields;
    @api studySessionIcon;
    @api studySessionTimeTitleField;
    @api studySessionTimeInfoFields;
    @api studySessionTimeIcon;
    @api showStudySessionTimeFieldLabel;

    //configurable attributes - enrollment button icon and label
    @api showEnrollmentButtons = false; //ISS-002401
    @api preEnrollButtonIconName;
    @api preEnrollButtonLabel;
    @api withdrawPreEnrollButtonIconName;
    @api withdrawPreEnrollButtonLabel;
    @api enrollButtonIconName;
    @api enrollButtonLabel;
    @api unenrollButtonIconName;
    @api unenrollButtonLabel;
    @api waitlistButtonIconName;
    @api waitlistButtonLabel;
    @api withdrawWaitlistButtonIconName;
    @api withdrawWaitlistButtonLabel;
    @api studySessionTimeIconSize = 'small';

    //configurable attributes - request reattempt settings
    @api requestAttemptMax = 3;
    @api requestAttemptWaitingTime = 5; //in seconds

    //configurable attributes - debugging
	@api enableDebugMode = false;

    //js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'tooltips'
    modules = ['stringutil'];

    //internal attributes
    @api masterIpeId;
    @api individualPathwayId;
    @api studySessionId;
    @api individualEnrollmentId;
    @api contactId;
    isScriptLoaded = false;
	isInitSuccess = false;
	loadedLists = 0;
    refreshHandlerID;
    requestAttemptCount = 1;
    spinnerCssClass;

    sseWireResult;
    sseWireRecord;
    sstWireResult;
    sstWireRecord;  
    sseStatusesWireResult;
    sseStatusesWireRecord;
    isnStatusesWireResult;
    isnStatusesWireRecord;
    sevWireResult;
    sevWireRecord;
    enrollmentStatusOptions;

    @track objectTranslatedNameResult;
    @track objectTranslatedNameResponse;

    //local cache idx to force rerendering
    _cacheIdx;

    //labels
	label = {
        PREENROLL_CONFIRMATION_LABEL,
        WITHDRAW_PREENROLL_CONFIRMATION_LABEL,
        ENROLL_CONFIRMATION_LABEL,
        UNENROLL_CONFIRMATION_LABEL,
        REQUEST_UNENROLL_CONFIRMATION_LABEL,
        JOIN_WAITLIST_CONFIRMATION_LABEL,
        WITHDRAW_WAITLIST_CONFIRMATION_LABEL,
        ...customLabels
    };

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
     * @description Refresh data
     */
    refreshData() {
        this.consoleLog('refreshData');

        refreshApex(this.sseWireResult);
        refreshApex(this.sevWireResult);

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
        logInfo('ipePathwayStudySession', anything, this.enableDebugMode, isJson);
    }

    //wired object
    @wire(getObjectInfo, {objectApiName: SSE_OBJECT})
    sseObjInfo;

    @wire(getObjectInfo, {objectApiName: ISN_OBJECT})
    isnObjInfo;
    

    /**
     * @description Get study session record
     */
    @wire(ctrlInitStudySession, {
        studySessionId: "$studySessionId",
        individualEnrollmentId: "$individualEnrollmentId",
        masterIpeId: "$masterIpeId",
        individualPathwayId: "$individualPathwayId",
        studySessionTitleField: "$studySessionTitleField",
        cacheIdx: "$_cacheIdx"
    })
    wiredStudySession(result){

        this.sseWireResult = result;
        this.sseWireRecord = null;

        if(result.data){
            this.sseWireRecord = JSON.parse(result.data.responseData);
            this.consoleLog(this.sseWireRecord, true);

        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    /**
     * @description Get related study session time
     */
    @wire(ctrlGetStudySessionTime, {studySessionId: "$studySessionId"})
    wiredStudySessionTime(result){

        this.sstWireResult = result;
        this.sstWireRecord = null;

        if(result.data){
            this.sstWireRecord = JSON.parse(result.data.responseData);
            this.consoleLog(this.sstWireRecord, true);

        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    /**
     * @description Get study offering status map by type
     */
    @wire(ctrlSseStatuses, {})
    wireSseStatus(result) {

        this.sseStatusesWireResult = result;
        this.sseStatusesWireRecord = null;

        if (result.data) {
            this.sseStatusesWireRecord = JSON.parse(result.data.responseData);
            this.consoleLog(this.sseStatusesWireRecord, true);
        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    /**
     * @description Get individual session enrollment status map by type
     */
    @wire(ctrlIsnStatuses, {})
    wireIsnStatus(result) {

        this.isnStatusesWireResult = result;
        this.isnStatusesWireRecord = null;

        if (result.data) {
            this.isnStatusesWireRecord = JSON.parse(result.data.responseData);
            this.consoleLog(this.isnStatusesWireRecord, true);
        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    /**
     * @description get enrollment status picklist values
     */
    @wire(getPicklistValues, { recordTypeId: "$isnObjInfo.data.defaultRecordTypeId", fieldApiName: ENROLLMENT_STATUS_FIELD})
    getEnrollmentStatusPicklistValues({data, error}){
        if(data){
            this.enrollmentStatusOptions = data.values;
        } else if(error){
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
        }
    }

    /**
     * @description Get object translation record
     */
    @wire(ctrlGetTranslationFieldForNameByObjPrefix, { objectPrefixes: OBJ_TRANSLATION})
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
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    /**
     * @description Return the translation field for name
     */
    get sseNameTranslationField() {
        return this.objectTranslatedNameResponse?.SSE;
    }

    /**
     * @description Return translated study session name value
     */
    get translatedStudySessionName() {
        if (this.sse && Object.hasOwn(this.sse, this.sseNameTranslationField)) {
            return this.sse[this.sseNameTranslationField];
        } else if (this.sse) {
            return this.sse?.Name;
        }

        return null;
    }

    /**
     * @description Return study session card title based on the configured title field
     */
    get sessionCardTitle() {
        if (this.sse) {
            return extractFieldValue(this.sse, this.studySessionTitleField);
        }

        return null;
    }

    /**
     * @description Return enrollment status field label
     */
    get enrollmentStatusFieldLabel(){
        if(this.isnObjInfo?.data) {
            return this.isnObjInfo.data.fields.reduivy__Enrollment_Status__c.label;
        }
        return null;
    }

    /**
     * @description Return study session label
     */
    get ssePluralLabel() {
        return this.sseObjInfo?.data?.labelPlural;
    }

    /**
     * @description Return session conflict tooltips
     */
    get sessionConflictWarningText() {
        if (this.ssePluralLabel) {
            return STUDY_SESSION_CONFLICT_WARNING_LABEL.format([this.ssePluralLabel]);
        }

        return '';
    }

    /**
     * @description return fields for view from
     */
    get sseInfoFields(){
        if(this.studySessionInfoFields){
            return this.studySessionInfoFields.split(';');
        }
        return [];
    }
    
    /**
     * @description Return study session status type
     */
    get sseStatusType() {

        let statusType;
        
        if (this.sseWireRecord) {
            let currentStatus = this.sseStatus ? this.sseStatus : null;
            
            if (this.sceStatus) {
                //if there is study cohort enrollment found, we will override the sse status

                if (this.sseNotStartedStatuses.includes(this.sceStatus)
                    || this.ssePreEnrollmentOpenedStatuses.includes(this.sceStatus)
                    || this.sseEnrollmentOpenedStatuses.includes(this.sceStatus)
                    || this.sseEnrollmentClosedStatuses.includes(this.sceStatus)
                ) {
                    currentStatus = this.sceStatus;
                }
            }

            if (this.sseNotStartedStatuses.includes(currentStatus)) {
                statusType = sseStatusTypes.SSE_STATUS_TYPE_NOTSTARTED;

            } else if (this.ssePreEnrollmentOpenedStatuses.includes(currentStatus)) {
                statusType = sseStatusTypes.SSE_STATUS_TYPE_PREENROLLMENT_OPENED;

            } else if (this.sseEnrollmentOpenedStatuses.includes(currentStatus)) {
                statusType = sseStatusTypes.SSE_STATUS_TYPE_ENROLLMENT_OPENED;

            } else if (this.sseEnrollmentClosedStatuses.includes(currentStatus)) {
                statusType = sseStatusTypes.SSE_STATUS_TYPE_ENROLLMENT_CLOSED;

            } else if (this.sseRunningStatuses.includes(currentStatus)) {
                statusType = sseStatusTypes.SSE_STATUS_TYPE_RUNNING;
            }
        }

        return statusType;
    }

    /**
     * @description Return study session statuses
     */
    get sseStatuses(){
        if(this.sseStatusesWireRecord){
            return this.sseStatusesWireRecord;
        }
        return null;
    }

    /**
     * @description Return individual session enrollment statuses
     */
    get isnEnrollmentStatuses(){
        if(this.isnStatusesWireRecord){
            return this.isnStatusesWireRecord;
        }
        return null;
    }
 
    /**
     * @description Return sse not started type status
     */
    get sseNotStartedStatuses() {
        if (this.sseStatuses && Object.hasOwn(this.sseStatuses, sseStatusTypes.SSE_STATUS_TYPE_NOTSTARTED)) {
            return this.sseStatuses[sseStatusTypes.SSE_STATUS_TYPE_NOTSTARTED];
        }

        return [];
    }

    /**
     * @description Return sse pre enrollment opened type status
     */
    get ssePreEnrollmentOpenedStatuses() {
        if (this.sseStatuses && Object.hasOwn(this.sseStatuses, sseStatusTypes.SSE_STATUS_TYPE_PREENROLLMENT_OPENED)) {
            return this.sseStatuses[sseStatusTypes.SSE_STATUS_TYPE_PREENROLLMENT_OPENED];
        }

        return [];
    }

    /**
     * @description Return sse enrollment opened type status
     */
    get sseEnrollmentOpenedStatuses() {
        if (this.sseStatuses && Object.hasOwn(this.sseStatuses, sseStatusTypes.SSE_STATUS_TYPE_ENROLLMENT_OPENED)) {
            return this.sseStatuses[sseStatusTypes.SSE_STATUS_TYPE_ENROLLMENT_OPENED];
        }

        return [];
    }

    /**
     * @description Return sse enrollment closed type status
     */
    get sseEnrollmentClosedStatuses() {
        if (this.sseStatuses && Object.hasOwn(this.sseStatuses, sseStatusTypes.SSE_STATUS_TYPE_ENROLLMENT_CLOSED)) {
            return this.sseStatuses[sseStatusTypes.SSE_STATUS_TYPE_ENROLLMENT_CLOSED];
        }

        return [];
    }

    /**
     * @description Return sse running type status
     */
    get sseRunningStatuses() {
        if (this.sseStatuses && Object.hasOwn(this.sseStatuses, sseStatusTypes.SSE_STATUS_TYPE_RUNNING)) {
            return this.sseStatuses[sseStatusTypes.SSE_STATUS_TYPE_RUNNING];
        }

        return [];
    }

    /**
     * @description Return isn open/not started type status
     */
    get isnOpenStatuses() {
        if (this.isnEnrollmentStatuses && Object.hasOwn(this.isnEnrollmentStatuses, isnEnrollmentStatusTypes.ISN_STATUS_TYPE_OPEN)) {
            return this.isnEnrollmentStatuses[isnEnrollmentStatusTypes.ISN_STATUS_TYPE_OPEN];
        }

        return [];
    }

    /**
     * @description Return isn in progress/enrolled type status
     */
    get isnInProgressStatuses() {
        if (this.isnEnrollmentStatuses && Object.hasOwn(this.isnEnrollmentStatuses, isnEnrollmentStatusTypes.ISN_STATUS_TYPE_INPROGRESS)) {
            return this.isnEnrollmentStatuses[isnEnrollmentStatusTypes.ISN_STATUS_TYPE_INPROGRESS];
        }

        return [];
    }

    /**
     * @description Return isn enrollment requested type status
     */
    get isnEnrollmentRequestedStatuses() {
        if (this.isnEnrollmentStatuses && Object.hasOwn(this.isnEnrollmentStatuses, isnEnrollmentStatusTypes.ISN_STATUS_TYPE_ENROLLMENT_REQUESTED)) {
            return this.isnEnrollmentStatuses[isnEnrollmentStatusTypes.ISN_STATUS_TYPE_ENROLLMENT_REQUESTED];
        }

        return [];
    }

    /**
     * @description Return isn enrollment requested type status
     */
    get isnWaitlistedStatuses() {
        if (this.isnEnrollmentStatuses && Object.hasOwn(this.isnEnrollmentStatuses, isnEnrollmentStatusTypes.ISN_STATUS_TYPE_WAITLISTED)) {
            return this.isnEnrollmentStatuses[isnEnrollmentStatusTypes.ISN_STATUS_TYPE_WAITLISTED];
        }

        return [];
    }

    /**
     * @description Return isn completed enrollment type status
     */
    get isnCompletedStatuses() {
        if (this.isnEnrollmentStatuses && Object.hasOwn(this.isnEnrollmentStatuses, isnEnrollmentStatusTypes.ISN_STATUS_TYPE_COMPLETED)) {
            return this.isnEnrollmentStatuses[isnEnrollmentStatusTypes.ISN_STATUS_TYPE_COMPLETED];
        }

        return [];
    }

    /**
     * @description Return true if study session able to enroll 
     */
    get isEnrollable(){ 
        if(this.userMode === commonConstants.USER_MODE_ADMIN || this.sseWireRecord?.sse?.reduivy__Enable_Self_Enrollment__c){
            return true;
        }

        return false;
    }

    /**
     * @description Return sse status
     */
    get sseStatus(){
        if(this.sseWireRecord && this.sseWireRecord.sse){
            return this.sseWireRecord.sse.reduivy__Status__c;
        }
        return null;
    }

    /**
     * @description Return isn enrollment status api value
     */
    get isnStatus(){
        if(this.sseWireRecord?.isn?.reduivy__Enrollment_Status__c){
            return this.sseWireRecord.isn.reduivy__Enrollment_Status__c;
        }
        return null;
    }

    /**
     * @description Return isn enrollment status value label
     */
    get isnStatusValueLabel(){
        if(this.sseWireRecord?.isn?.reduivy__Enrollment_Status__c && this.enrollmentStatusOptions){
            for (let opt of this.enrollmentStatusOptions) {
                if (opt.value === this.sseWireRecord.isn.reduivy__Enrollment_Status__c) {
                    return opt.label;
                }
            }
        }

        return null;
    }

    /**
     * @description Return sce status
     */
    get sceStatus(){
        if(this.sseWireRecord && this.sseWireRecord.sce){
            return this.sseWireRecord.sce.reduivy__Study_Offering_Status__c;
        }
        return null;
    }

    /**
     * @description Return sse record
     */
    get sse(){
        if(this.sseWireRecord && this.sseWireRecord?.sse){
            return this.sseWireRecord.sse;
        }
        return null;
    }

    /**
     * @description Show pre-enrollment button
     */
    get showPreEnrollButton(){
        
        if(
            !(this.isnStatus && this.isnEnrollmentRequestedStatuses.includes(this.isnStatus))
            && this.sseStatusType === sseStatusTypes.SSE_STATUS_TYPE_PREENROLLMENT_OPENED 
        ){
            return true;
        }

        return false;
    }

    /**
     * @description Show withdraw from pre-enrollment button
     */
    get showWithdrawPreEnrollButton() {
        if (this.isnStatus && this.isnEnrollmentRequestedStatuses.includes(this.isnStatus)) {
            return true;
        }

        return false;
    }

    /**
     * @description Show enroll button
     */
    get showEnrollButton() {
        
        if (this.sse && (this.sse.reduivy__Available_Places__c > 0 || this.sse.reduivy__Unlimited_Places__c)
            && !(this.isnStatus && this.isnInProgressStatuses.includes(this.isnStatus))
            && this.sseStatusType === sseStatusTypes.SSE_STATUS_TYPE_ENROLLMENT_OPENED
        ) {
            return true;
        }

        return false;
    }
    
    /**
     * @description Show unenroll button
     */
    get showUnenrollButton() {
        if (this.isnStatus && this.isnInProgressStatuses.includes(this.isnStatus)
        ) {
            return true;
        }

        return false;
    }

    /**
     * @description Show join waiting list button
     */
    get showWaitlistButton() {
        if (this.sse
            && this.sse.reduivy__Enable_Waitlist__c
            && !(this.sse.reduivy__Available_Places__c > 0 || this.sse.reduivy__Unlimited_Places__c)
            && !(this.isnStatus && this.isnWaitlistedStatuses.includes(this.isnStatus)) 
            && this.sseStatusType === sseStatusTypes.SSE_STATUS_TYPE_ENROLLMENT_OPENED 
            && !(this.showUnenrollButton || this.showEnrollButton) //ISS-002255
        ) {
            return true;
        }

        return false;
    }
    
    /**
     * @description Show withdraw from waiting list button
     */
    get showWithdrawWaitlistButton() {
        if (this.isnStatus && this.isnWaitlistedStatuses.includes(this.isnStatus)) {
            return true;
        }

        return false;
    }

    /**
     * @description Notify other components about the enrollment action status
     */
    notifyEnrollActionStarted() {
        //notify ipePathwayTermListing to enable spinner to avoid multiple enrollment
        this.spinnerCssClass = 'slds-is-fixed'; //this is to ensure the spinner cover the full page to avoid user to clicking other enroll button

        this.consoleLog('session enroll action started');
        this.toggleSpinner(1);
    }

    /**
     * @description Notify other components about the enrollment action status
     */
    notifyEnrollActionEnded() {
        //notify ipePathwayTermListing to disable spinner
        this.spinnerCssClass = null;

        this.consoleLog('session enroll action ended');
        this.toggleSpinner(-1);
    }
    
    /**
     * @description Notify other components about the enrollment attempt status
     */
    notifyEnrollAttemptStarted() {
        this.consoleLog('session enroll attempt started: Attempt ' + this.requestAttemptCount);
        this.toggleSpinner(1);
    }

    /**
     * @description Notify other components about the enrollment attempt status
     */
    notifyEnrollAttemptEnded(){
        this.consoleLog('session enroll attempt ended: Attempt ' + this.requestAttemptCount);
        this.toggleSpinner(-1);
    }

    /**
     * @description Validate the error to see if it is eligible for retry
     * @param {*} errorMsg 
     * @returns Boolean
     */
    canRetry(errorMsg) {
        if (errorMsg && this.requestAttemptCount <= this.requestAttemptMax) {
            for (let retryErr of this.retryErrors) {
                if (errorMsg.toLowerCase().includes(retryErr)) {
                    this.consoleLog('found error for retry - ' + retryErr);
                    
                    return true;
                }
            }
        }

        return false;
    }

    /**
     * @description Reset the requestAttemptCount to 1
     */
    resetRequestAttemptCount() {
        this.requestAttemptCount = 1;
    }

    /**
     * @description Replace the retry errors with server to busy error
     * @param {*} errorMsg 
     * @returns String
     */
    replaceRetryErrors(errorMsg){

        let cleansedMsg = errorMsg;

        for (let retryErr of this.retryErrors) {
            if (cleansedMsg.toLowerCase().includes(retryErr)) {
                this.consoleLog('found error for replacement - ' + retryErr);
                
                cleansedMsg = this.label.SERVER_TOO_BUSY_LABEL;
            }
        }

        return cleansedMsg;
    }

    /**
     * @description Return list of errors that are eligible for retry
     */
    get retryErrors() {
        let errorList = [];
        if (ENROLLMENT_ERRORS_FOR_RETRY_LABEL) {
            for (let err of ENROLLMENT_ERRORS_FOR_RETRY_LABEL.split(";")) {
                errorList.push(err.trim().toLowerCase());
            }
        }

        return errorList;
    }

    /**
     * @description Launch the confirmation modal
     * @param title 
     * @param text1 
     * @param text2 
     * @param text3 
     * @param showSubmit 
     * @param submitLabel 
     * @param showCancel 
     * @param cancelLabel 
     * @param lEventSource 
     * @param lEventData 
     */
    launchConfirmationModal(title, text1, text2, text3, showSubmit, submitLabel, showCancel, cancelLabel, lEventSource, lEventData) {

        confirmationModal.open({
            size: 'small',
            modalTitle: title,
            confirmationText1: text1,
            confirmationText2: text2,
            confirmationText3: text3,
            showSubmitButton: showSubmit,
            submitButtonLabel: submitLabel,
            showCancelButton: showCancel,
            cancelButtonLabel: cancelLabel,
            eventSource: lEventSource,
            eventData: lEventData,
            enableDebugMode: this.enableDebugMode            
        }).then((result) => {

            if (result) {
                this.consoleLog('launchConfirmationModal.close');
                this.consoleLog(result, true);

                const {operation, eventSource, eventData} = result;

                if (operation === 'submit') {
                    this.startUpsertEnrollment(eventSource, eventData);
                }
            }
        });
        
    }

    /**
     * @description start to perform enrollment
     */
    startUpsertEnrollment(enrollmentAction, sseRecord) {
        this.notifyEnrollActionStarted();

        this.upsertEnrollment(enrollmentAction, sseRecord);
    }

    /**
     * @descripton Upsert enrollment records
     */
    upsertEnrollment(enrollmentAction, sseRecord) {
        this.notifyEnrollAttemptStarted();

        try {
            this.consoleLog('upsertEnrollment');
            this.consoleLog(sseRecord, true);

            ctrlUpsertEnrollment({
                individualEnrollmentId: this.individualEnrollmentId,
                sseRecord: JSON.stringify(sseRecord),
                enrollmentAction: enrollmentAction
            })
            .then(saveResult => {
                this.notifyEnrollAttemptEnded();
                this.notifyEnrollActionEnded();
                
                this.resetRequestAttemptCount();
                if (saveResult.responseData) {
                    let recordIds = [];
                    for (let recId of JSON.parse(saveResult.responseData)) {
                        recordIds.push({recordId: recId});
                    }

                    recordIds.push({recordId: this.sse.Id});

                    notifyRecordUpdateAvailable(recordIds);
                }
                
                //update the cacheIdx to force the data reload from apex controller
                this._cacheIdx = initCacheIdx();
                
                this.dispatchEvent(new RefreshEvent());
                
                promptSuccess(this.label.SUCCESS_LABEL, saveResult.message);
                
            })
            .catch(error => {
                let errorMsg = getErrorMessage(error);

                //check if we can retry if for lock contention error
                if (this.canRetry(errorMsg)) {
                    this.notifyEnrollAttemptEnded();
                    this.consoleLog('attempting retry isn enrollment.. ' + this.requestAttemptCount);
                    this.requestAttemptCount ++;

                    setTimeout(() => {
                        if (this.requestAttemptCount === 2) {
                            promptWarning(this.label.PROCESSING_LABEL, this.label.LONG_PROCESSING_WARNING_LABEL);
                        }

                        this.upsertEnrollment(enrollmentAction, sseRecord);
                    }, (this.requestAttemptCount * this.requestAttemptWaitingTime * 1000)); //increate the retry waiting period based on the attempt count

                } else {

                    promptError(this.label.ERROR_LABEL, this.replaceRetryErrors(errorMsg));
                    this.notifyEnrollAttemptEnded();
                    this.notifyEnrollActionEnded();

                    this.resetRequestAttemptCount();

                    this.dispatchEvent(new RefreshEvent());
                }                
                
            });

        } catch (error) {
            this.notifyEnrollAttemptEnded();
            this.notifyEnrollActionEnded();
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
        }
    }

    /**
     * @description Handle pre enrollment click
     */
    handlePreEnrollClick(event) {
        let confirmationMsg1 = this.label.PREENROLL_CONFIRMATION_LABEL.format([this.translatedStudySessionName]);

        this.launchConfirmationModal(this.label.CONFIRMATION_LABEL, confirmationMsg1, null, null, true, this.label.CONFIRM_LABEL, true, this.label.CANCEL_LABEL, ipePathwayConstants.ENROLLMENT_ACTION_ENROLLREQUESTED, this.sse);
    }

    /**
     * @description Handle withdraw pre enrollment click
     */
    handleWithdrawPreEnrollClick(event) {
        let confirmationMsg1 = this.label.WITHDRAW_PREENROLL_CONFIRMATION_LABEL.format([this.translatedStudySessionName]);

        this.launchConfirmationModal(this.label.CONFIRMATION_LABEL, confirmationMsg1, null, null, true, this.label.CONFIRM_LABEL, true, this.label.CANCEL_LABEL, ipePathwayConstants.ENROLLMENT_ACTION_WITHDRAWENROLLREQUESTED, this.sse);
    }

    /**
     * @description Handle enroll click
     */
    handleEnrollClick(event) {
        let confirmationMsg1 = this.label.ENROLL_CONFIRMATION_LABEL.format([this.translatedStudySessionName]);

        this.launchConfirmationModal(this.label.CONFIRMATION_LABEL, confirmationMsg1, null, null, true, this.label.CONFIRM_LABEL, true, this.label.CANCEL_LABEL, ipePathwayConstants.ENROLLMENT_ACTION_ENROLL, this.sse);
    }

    /**
     * @description Handle unenroll click
     */
    handleUnenrollClick(event) {
        let confirmationMsg1 = this.label.UNENROLL_CONFIRMATION_LABEL.format([this.translatedStudySessionName]);

        this.launchConfirmationModal(this.label.CONFIRMATION_LABEL, confirmationMsg1, null, null, true, this.label.CONFIRM_LABEL, true, this.label.CANCEL_LABEL, ipePathwayConstants.ENROLLMENT_ACTION_UNENROLL, this.sse);
    }

    /**
     * @description Handle unenroll click
     */
    handleJoinWaitListClick(event) {
        let confirmationMsg1 = this.label.JOIN_WAITLIST_CONFIRMATION_LABEL.format([this.translatedStudySessionName]);

        this.launchConfirmationModal(this.label.CONFIRMATION_LABEL, confirmationMsg1, null, null, true, this.label.CONFIRM_LABEL, true, this.label.CANCEL_LABEL, ipePathwayConstants.ENROLLMENT_ACTION_JOINWAITLIST, this.sse);
    }

    /**
     * @description Handle unenroll click
     */
    handleWithdrawWaitListClick(event) {
        let confirmationMsg1 = this.label.WITHDRAW_WAITLIST_CONFIRMATION_LABEL.format([this.translatedStudySessionName]);

        this.launchConfirmationModal(this.label.CONFIRMATION_LABEL, confirmationMsg1, null, null, true, this.label.CONFIRM_LABEL, true, this.label.CANCEL_LABEL, ipePathwayConstants.ENROLLMENT_ACTION_WITHDRAWWAITLIST, this.sse);
    }

    /**
     * @description check study event conflict
     */
    @wire(ctrlCheckEventConflict, {
        studySessionId: "$studySessionId",
        contactId: "$contactId",
        cacheIdx: "$_cacheIdx"
    })
    wiredDoubleBookingEvents(result){

        this.sevWireResult = result;
        this.sevWireRecord = null;

        if (result.data) {
            this.sevWireRecord = JSON.parse(result.data.responseData);
            this.consoleLog(this.sevWireRecord, true);
            
        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    /**
     * @description Return true if there is a double booking warning
     */
    get showDoubleBookingWarning(){
        
        if(
            this.sevWireRecord 
            && this.sevWireRecord.length > 0
        ){
            return true;
        }

        return false;
    }
}