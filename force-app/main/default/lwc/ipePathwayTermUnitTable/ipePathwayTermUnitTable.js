/**
 * @Author 		WDCi (Lean)
 * @Date 		Oct 2023
 * @group 		Enrollment Wizard
 * @Description Student enrollment wizard
 * @changehistory
 * ISS-001752 05-10-2022 Lean - new component
 * ISS-002254 16-01-2025 XW - fixed bug where enrollment wizard keeps loading when reattempting the enrollment
 * ISS-002230 18-02-2025 XW - custom requirement description can be specify
 * ISS-002330 20-03-2025 XW - Show Study Offering, Study Term and Study Unit translation name if found
 * ISS-002345 21-03-2025 XiRouh - Added masterIndividualPeId param and pass to ctrlGetIpsUnits
 * ISS-002336 24-03-2024 Lean - Added missed/failed unit
 * ISS-002374 14-04-2025 XiRouh - Added ctrlFinalGradeReleasedStatuses and ienGradeResultPicklistValues
 * ISS-002514 10-06-2025 XW - Updated upsertEnrollment to accept enrollment status to change to
 * ISS-002495 22-09-2025 XW - support translation for long text field
 * ISS-002724 13-11-2025 XW - get ienDefaultRecordTypeId for ienGradeResultPicklistValues
 * ISS-002797 13-02-2025 Lean - Standardize language code format to POSIX
 */
import { LightningElement, api, wire, track } from 'lwc';
import { promptInfo, promptError, promptWarning, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';
import { customLabels } from 'c/labelLoader';
import { updatedObjReactor, removeLabelAttributes, commonConstants, formatLanguageCodeToPosix } from 'c/lwcUtil';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import LANG from '@salesforce/i18n/lang';

//wire refresh
import { refreshApex } from '@salesforce/apex';
import { RefreshEvent, registerRefreshHandler, unregisterRefreshHandler } from 'lightning/refresh';

import SOF_OBJECT from '@salesforce/schema/Study_Offering__c';
import IEN_OBJ from '@salesforce/schema/Individual_Enrollment__c';
import IEN_GRADE_RESULT_FIELD from '@salesforce/schema/Individual_Enrollment__c.Grade_Result__c'

import NO_SOF_AVAIL_LABEL from '@salesforce/label/c.No_Study_Offering_is_Available';
import STATUS_COL_LABEL from '@salesforce/label/c.Status_Column';
import ENROLLMENT_ERRORS_FOR_RETRY_LABEL from '@salesforce/label/c.Enrollment_Errors_For_Retry';

//Apex methods
import ctrlGetIpsUnits from '@salesforce/apex/REDU_IpePathwayTermUnitTable_LCTRL.getIndividualPlanStructureUnits';
import ctrlSofStatuses from '@salesforce/apex/REDU_IpePathwayTermUnitTable_LCTRL.getStudyOfferingStatuses';
import ctrlIntenalGradeReleasedStatuses from '@salesforce/apex/REDU_IpePathwayTermUnitTable_LCTRL.getInternalGradeReleasedStatuses';
import ctrlFinalGradeReleasedStatuses from '@salesforce/apex/REDU_IpePathwayTermUnitTable_LCTRL.getFinalGradeReleasedStatuses';
import ctrlIpsUnitStatuses from '@salesforce/apex/REDU_IpePathwayTermUnitTable_LCTRL.getIndividualPlanStructureUnitStatuses';
import ctrlIenEnrollmentStatuses from '@salesforce/apex/REDU_IpePathwayTermUnitTable_LCTRL.getIndividualEnrollmentStatuses';
import ctrlUpsertEnrollment from '@salesforce/apex/REDU_IpePathwayTermUnitTable_LCTRL.upsertEnrollment';
import ctrlGetTranslationFieldForNameByObjPrefix from '@salesforce/apex/REDU_Translation_LCTRL.getTranslationFieldForNameByObjPrefix';

const OBJ_TRANSLATION = [
    "SOF",
    "STM",
    "SUN"
];

export default class IpePathwayTermUnitTable extends LightningElement {
	
	//configurable attributes
    @api masterIndividualPeId; //ISS-002345
    @api individualPeId;
    @api individualPlanStructureGroupId;
    @api individualPathwayId;
    @api ipwAcademicTermId;
    
    @api tableFields;
    @api userMode;
    @api studyUnitQuickSearchValue; //ISS-002188
    @api unitListingMode;
    @api campusId;
    @api set restrictedToUnits(val){
        //Restrict the listing to the specified usits when viewing in pathway mode
        if (val) {
            this._restrictedToUnits = val;
        } else {
            this._restrictedToUnits = [];
        }

        this.updateCacheIdx();
    } 

    get restrictedToUnits() {
        return this._restrictedToUnits;
    }

    //configurable attributes - view info fields
    @api studyUnitInfoFields;
    @api studyOfferingInfoFields;
    @api studyPlanStructureUnitInfoFields;

    //configurable attributes - enrollment button icon and label
    @api showEnrollmentButtons = false;
    @api preEnrollButtonIconName;
    @api preEnrollButtonLabel;
    @api preEnrollEnrollmentStatus
    @api withdrawPreEnrollButtonIconName;
    @api withdrawPreEnrollButtonLabel;
    @api withdrawPreEnrollEnrollmentStatus
    @api enrollButtonIconName;
    @api enrollButtonLabel;
    @api enrollEnrollmentStatus
    @api unenrollButtonIconName;
    @api unenrollButtonLabel;
    @api unenrollEnrollmentStatus
    @api unenrollRequestButtonIconName;
    @api unenrollRequestButtonLabel;
    @api unenrollRequestEnrollmentStatus
    @api waitlistButtonIconName;
    @api waitlistButtonLabel;
    @api waitlistEnrollmentStatus
    @api withdrawWaitlistButtonIconName;
    @api withdrawWaitlistButtonLabel;
    @api withdrawWaitlistEnrollmentStatus

    //configurable attributes - request reattempt settings
    @api requestAttemptMax = 3;
    @api requestAttemptWaitingTime = 5; //in seconds
    
    //custom filters
    @api customFilters;

    @api missedFailedUnitListingOption;

    //configurable attributes - debugging
	@api enableDebugMode = false;
	
	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false;
	loadedLists = 0;

    spinnerCssClass;

    @track requestAttemptCount = 1;
    @track _restrictedToUnits = [];

    //object wire info attributes
    ipsUnitTableWireResult;
    ipsUnitTableResponse;

    sofStatusesWireResult;
    sofStatusesResponse;

    internalGradeReleasedStatusesWireResult;
    internalGradeReleasedStatusesResponse;

    finalGradeReleasedStatusesWireResult;
    finalGradeReleasedStatusesResponse;

    ipsUnitStatusesWireResult;
    ipsUnitStatusesResponse;

    ienEnrollmentStatusesWireResult;
    ienEnrollmentStatusesResponse;

    @track objectTranslatedNameResult;
    @track objectTranslatedNameResponse;

    //refresh module
    refreshHandlerID;

    //local cache idx to force rerendering
    cacheIdx;
    
	//labels
	label = {
        STATUS_COL_LABEL,
        ...customLabels
    };
	
	//js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'tooltips'
    modules = ['moment'];
	
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
     * @descripton rendered callback
     */
	renderedCallback(){

    }

    /**
     * @descripton connected callback
     */
    connectedCallback(){
		this.refreshHandlerID = registerRefreshHandler(this, this.refreshData);

        // if (!this.restrictedToUnits) {
        //     this._restrictedToUnits = []; //need to set the null list to empty list to ensure that the wire methods work
        // } else {
        //     this._restrictedToUnits = this.restrictedToUnits;
        // }

        this.updateCacheIdx();
	}
	
    /**
     * @descripton disconnected callback
     */
	disconnectedCallback() {
		unregisterRefreshHandler(this.refreshHandlerID);
	}

    updateCacheIdx() {
        this.cacheIdx = Date.now() + '_ipepathway';
    }

    /**
     * @description Refresh data
     */
    refreshData() {
        this.consoleLog('refreshData');

        refreshApex(this.ipsUnitTableWireResult);
        refreshApex(this.sofStatusesWireResult);
        refreshApex(this.ipsUnitStatusesWireResult);
        refreshApex(this.ienEnrollmentStatusesWireResult);
        refreshApex(this.internalGradeReleasedStatusesWireResult);
        refreshApex(this.finalGradeReleasedStatusesWireResult);

        return new Promise((resolve) => {
            resolve(true);
        });
    }

    //Object Labels
    @wire(getObjectInfo, {objectApiName: SOF_OBJECT})
    sofObjInfo;

    /**
     * @description get the object info for the Study Offering
     */
    @wire(getObjectInfo, {objectApiName: IEN_OBJ})
    ienObjectInfo;

    //get the default record type id of the Study Session to get picklist value
    get ienDefaultRecordTypeId(){
        return this.ienObjectInfo?.data?.defaultRecordTypeId;
    }

    /**
     * @description get the picklist value of the Session Type
     */
    @wire(getPicklistValues, { recordTypeId: '$ienDefaultRecordTypeId', fieldApiName: IEN_GRADE_RESULT_FIELD })
    ienGradeResultPicklistValues;

    /**
     * @description Get individual plan structure group record
     */
    @wire(ctrlGetIpsUnits, { 
        masterIndividualPeId: "$masterIndividualPeId",
        individualPeId: "$individualPeId", 
        individualPlanStructureGroupId: "$individualPlanStructureGroupId",
        individualPathwayId: "$individualPathwayId",
        campusId: "$campusId",
        tableFields: "$tableFields",
        restrictedToUnits: "$restrictedToUnits",
        userMode: "$userMode",
        unitListingMode: "$unitListingMode",
        customFilters: "$customFilters",
        missedFailedUnitListingOption: "$missedFailedUnitListingOption",
        language: "$language",
        cacheIdx: "$cacheIdx"
    })
    wiredRecord(result) {

        this.ipsUnitTableWireResult = result;
        this.ipsUnitTableResponse = null;

        if (result.data) {
            this.ipsUnitTableResponse = JSON.parse(result.data.responseData);

            this.consoleLog(this.masterIndividualPeId);
            this.consoleLog(this.individualPeId);
            this.consoleLog(this.individualPlanStructureGroupId);
            this.consoleLog(this.ipsUnitTableResponse, true);
            
        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }

    }

    /**
     * @description the user language
     */
    get language() {
        return formatLanguageCodeToPosix(LANG);
    }

    /**
     * @description Get study offering status map by type
     */
    @wire(ctrlSofStatuses, {})
    wireSofStatus(result) {

        this.sofStatusesWireResult = result;
        this.sofStatusesResponse = null;

        if (result.data) {
            this.sofStatusesResponse = JSON.parse(result.data.responseData);
            this.consoleLog(this.sofStatusesResponse, true);
        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    /**
     * @description Get internal grade released statuses
     */
    @wire(ctrlIntenalGradeReleasedStatuses, {})
    wireIntenalGradeReleasedStatuses(result) {

        this.internalGradeReleasedStatusesWireResult = result;
        this.internalGradeReleasedStatusesResponse = null;

        if (result.data) {
            this.internalGradeReleasedStatusesResponse = JSON.parse(result.data.responseData);
            this.consoleLog(this.internalGradeReleasedStatusesResponse, true);
        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    /**
     * @description Get final grade released statuses
     */
    @wire(ctrlFinalGradeReleasedStatuses, {})
    wireFinalGradeReleasedStatuses(result) {

        this.finalGradeReleasedStatusesWireResult = result;
        this.finalGradeReleasedStatusesResponse = null;

        if (result.data) {
            this.finalGradeReleasedStatusesResponse = JSON.parse(result.data.responseData);
            this.consoleLog(this.finalGradeReleasedStatusesResponse, true);
        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    /**
     * @description Get individual plan structure unit status map by type
     */
    @wire(ctrlIpsUnitStatuses, {})
    wireIpsStatus(result) {

        this.ipsUnitStatusesWireResult = result;
        this.ipsUnitStatusesResponse = null;

        if (result.data) {
            this.ipsUnitStatusesResponse = JSON.parse(result.data.responseData);
            this.consoleLog(this.ipsUnitStatusesResponse, true);
        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    /**
     * @description Get individual enrollment status map by type
     */
    @wire(ctrlIenEnrollmentStatuses, {})
    wireIenStatus(result) {

        this.ienEnrollmentStatusesWireResult = result;
        this.ienEnrollmentStatusesResponse = null;

        if (result.data) {
            this.ienEnrollmentStatusesResponse = JSON.parse(result.data.responseData);
            this.consoleLog(this.ienEnrollmentStatusesResponse, true);
        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
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
     * @description Return the translation field for study offering name
     */
    get sofNameTranslationField() {
        return this.objectTranslatedNameResponse?.SOF;
    }

    /**
     * @description Return the translation field for study term name
     */
    get stmNameTranslationField() {
        return this.objectTranslatedNameResponse?.STM;
    }

    /**
     * @description Return the translation field for study unit name
     */
    get sunNameTranslationField() {
        return this.objectTranslatedNameResponse?.SUN;
    }

    /**
     * @description Return true if the ips list has records
     */
    get hasDataRows() {
        if (this.filteredIpsUnitList && this.filteredIpsUnitList.length > 0) {
            return true;
        }

        return false;
    }

    /**
     * @description Return No Study Offering is Available text
     */
    get noStudyOfferingAvailableText() {
        if(this.sofObjInfo.data){
            return NO_SOF_AVAIL_LABEL.format([this.sofObjInfo.data.label]);
        }

        return '';
    }

    /**
     * @description Return list of enrollment table column metadata
     */
    get unitTableColumns() {
        if (this.ipsUnitTableReady && this.ipsUnitTableResponse.unitTableColumns) {
            return this.ipsUnitTableResponse.unitTableColumns;
        }

        return null;
    }

    get ipsUnitList() {
        if (this.ipsUnitTableReady && this.ipsUnitTableResponse.childUnitsIps) {
            return this.ipsUnitTableResponse.childUnitsIps;
        }

        return null;
    }

    /** ISS-002188
     * @description Return filtered list of study unit based on the quick search value
     */
    get filteredIpsUnitList() {
        if(!this.studyUnitQuickSearchValue) {
            return this.ipsUnitList;
        }
        
        let filteredList = [];
        if(this.ipsUnitTableReady && this.ipsUnitList) {
            let studyUnitQuickSearchValueList = this.studyUnitQuickSearchValue.toLowerCase().split(' ');
            for(let ipsUnit of this.ipsUnitList) {
                for(let word of studyUnitQuickSearchValueList) {
                    if(
                        ipsUnit.sun?.reduivy__Unit_Code__c?.toLowerCase().includes(word) ||
                        ipsUnit.sun?.[this.sunNameTranslationField]?.toLowerCase().includes(word)
                    ){
                        filteredList.push(ipsUnit);
                        break;
                    }
                }
            }
        }
        return filteredList;
    }

    /**
     * @description Return true if the ipsGroupResponse is fetched by the wire method
     */
    get ipsUnitTableReady() {
        
        if (this.individualPlanStructureGroupId && this.ipsUnitTableResponse) {
            return true;
        }

        return false;
    }

    /**
     * @description Return ipe eligible to enroll
     */
    get isEligibleToEnroll() {
        if ((this.ipsUnitTableResponse && this.ipsUnitTableResponse.masterIpe && this.ipsUnitTableResponse.masterIpe.reduivy__Eligible_To_Enroll__c) || this.userMode === commonConstants.USER_MODE_ADMIN) {
            return true;
        }

        return false;
    }

    /**
     * @description Return study cohort enrollment setting
     */
    get sceSetting() {
        if (this.ipsUnitStatusesResponse && this.ipsUnitTableResponse.sce) {
            return this.ipsUnitTableResponse.sce;
        }

        return null;
    }

    /**
     * @description Return study cohort enrollment setting
     */
    get ipwRecord() {
        if (this.ipsUnitStatusesResponse && this.ipsUnitTableResponse.ipw) {
            return this.ipsUnitTableResponse.ipw;
        }

        return null;
    }

    /**
     * @description Return translation info of the individual plan structure
     */
    get translationInfo() {
        if(this.ipsUnitTableResponse && this.ipsUnitTableResponse.translationInfo) {
            return this.ipsUnitTableResponse.translationInfo;
        }

        return {};
    }

    /**
     * @description Return study offering statuses
     */
    get sofStatuses() {

        if (this.sofStatusesResponse) {
            return this.sofStatusesResponse;
        }

        return null;
    }

    /**
     * @description Return internal grade released statuses
     */
    get internalGradeReleasedStatuses() {

        if (this.internalGradeReleasedStatusesResponse) {
            return this.internalGradeReleasedStatusesResponse;
        }

        return null;
    }

    /**
     * @description Return final grade released statuses
     */
    get finalGradeReleasedStatuses() {

        if (this.finalGradeReleasedStatusesResponse) {
            return this.finalGradeReleasedStatusesResponse;
        }

        return null;
    }

    /**
     * @description Return individual plan structure statuses
     */
    get ipsUnitStatuses() {

        if (this.ipsUnitStatusesResponse) {
            return this.ipsUnitStatusesResponse;
        }

        return null;
    }

    /**
     * @description Return individual plan structure statuses
     */
    get ienEnrollmentStatuses() {

        if (this.ienEnrollmentStatusesResponse) {
            return this.ienEnrollmentStatusesResponse;
        }

        return null;
    }

    /**
     * @description Return true to show action column
     */
    get showActionColumn() {
        return this.isEligibleToEnroll && this.showEnrollmentButtons ? true : false;
    }

    /**
     * @description Return true to show indicator column
     */
    get showIndicatorColumn() {
        return this.missedFailedUnitListingOption && this.missedFailedUnitListingOption === 'All' ? true : false;
    }
	
    /**
     * @description Handle the sof option expansion or collapse
     */
    handleOptionClick(event) {
        this.toggleSpinner(1);
        this.consoleLog('handleOptionClick');
        this.consoleLog(event.detail, true);
        let targetIpsRecord = event.detail.ipsRecord;
        
        for (let ipsUnit of this.ipsUnitList) {
            if (ipsUnit.seq === targetIpsRecord.seq) {
                ipsUnit.isOptionsExpanded = !targetIpsRecord.isOptionsExpanded;
                this.consoleLog('found');
                this.consoleLog(ipsUnit, true);

                //after updating the object attribte, we need to update the reactor too
                this.updateReactor(ipsUnit);

                break;
            }
        }

        this.toggleSpinner(-1);
    }

    /**
     * @description Handle create/update enrollment record
     * @param {*} event 
     */
    handleUpsertEnrollment(event) {
        if (event.detail) {
            const {ipsRecord, enrollmentAction, enrollmentStatus} = event.detail;

            this.startUpsertEnrollment(ipsRecord, enrollmentAction, enrollmentStatus);
        }
    }

    /**
     * @description start to perform enrollment
     */     
    startUpsertEnrollment(ipsRecord, enrollmentAction, enrollmentStatus) {
        this.notifyEnrollActionStarted();

        let cleansedIpsRecord = removeLabelAttributes(JSON.parse(JSON.stringify(ipsRecord)));
        this.upsertEnrollment(cleansedIpsRecord, enrollmentAction, enrollmentStatus);
    }

    /**
     * @descripton Upsert enrollment records
     */
    upsertEnrollment(targetIpsRecord, enrollmentAction, enrollmentStatus) {
        this.notifyEnrollAttemptStarted();

        try {
            this.consoleLog('upsertEnrollment');
            this.consoleLog(targetIpsRecord, true);

            ctrlUpsertEnrollment({
                individualPathwayId: this.individualPathwayId,
                requestIpsRecord: JSON.stringify(targetIpsRecord),
                enrollmentAction: enrollmentAction,
                enrollmentStatus: enrollmentStatus
                
            })
            .then(saveResult => {
                this.notifyEnrollAttemptEnded();
                this.notifyEnrollActionEnded();
                promptSuccess(this.label.SUCCESS_LABEL, saveResult.message);

                this.resetRequestAttemptCount();

                if (saveResult.responseData) {
                    let recordIds = [];
                    for (let recId of JSON.parse(saveResult.responseData)) {
                        recordIds.push({recordId: recId});
                    }

                    notifyRecordUpdateAvailable(recordIds);
                }

                this.updateCacheIdx();
                this.dispatchEvent(new RefreshEvent());

            })
            .catch(error => {
                let errorMsg = getErrorMessage(error);

                //check if we can retry if for lock contention error
                if (this.canRetry(errorMsg)) {
                    this.notifyEnrollAttemptEnded();
                    this.consoleLog('attempting retry ips and ien enrollment.. ' + this.requestAttemptCount);
                    this.requestAttemptCount ++;

                    setTimeout(() => {
                        if (this.requestAttemptCount === 2) {
                            promptWarning(this.label.PROCESSING_LABEL, this.label.LONG_PROCESSING_WARNING_LABEL);
                        }

                        this.upsertEnrollment(targetIpsRecord, enrollmentAction);
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
     * @description Update the object with new lwcReactor value to force the rerendering
     * @param obj
     */
    updateReactor(obj){
        updatedObjReactor(obj);

        this.consoleLog('updateReactor');
        this.consoleLog(obj, true);
    }

    /**
     * @description Notify other components about the enrollment action status
     */
    notifyEnrollActionStarted() {
        //notify ipePathwayTermListing to enable spinner to avoid multiple enrollment
        this.spinnerCssClass = 'slds-is-fixed'; //this is to ensure the spinner cover the full page to avoid user to clicking other enroll button

        this.consoleLog('enrollactionstarted');
        this.toggleSpinner(1);
    }

    /**
     * @description Notify other components about the enrollment action status
     */
    notifyEnrollActionEnded() {
        //notify ipePathwayTermListing to disable spinner
        this.spinnerCssClass = null;

        this.consoleLog('enrollactionended');
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
     * @description ipsUnitTableResponse for debugging
     */
    get ipsUnitTableResponseForDebugging() {
        return this.enableDebugMode ? JSON.stringify(this.ipsUnitTableResponse) : null;
    }

    /**
     * @descripton Spinner loading status
     */
	get isLoading(){
        return this.loadedLists === 0 && this.ipsUnitTableResponse && this.sofStatusesResponse && this.ipsUnitStatusesResponse && this.ienEnrollmentStatusesResponse ? false : true;
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
        logInfo('ipePathwayTermUnitTable', anything, this.enableDebugMode, isJson);
    }
	
}