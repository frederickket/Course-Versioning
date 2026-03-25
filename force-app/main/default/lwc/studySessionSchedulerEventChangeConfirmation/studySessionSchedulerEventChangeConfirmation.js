/**
 * @author      WDCi (Lean)
 * @date        Jun 2024
 * @group       Study Session Scheduler
 * @description Study session scheduler event change confirmation modal
 * @changehistory
 * ISS-001920 11-06-2024 Lean - new class
 * ISS-002230 22-01-2025 XW - replace hardcoded label to custom label
 */
import { api, wire } from 'lwc';
import LightningModal from 'lightning/modal';

import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import SUN_OBJECT from '@salesforce/schema/Study_Unit__c';
import SSE_OBJECT from '@salesforce/schema/Study_Session__c';
import SST_OBJECT from '@salesforce/schema/Study_Session_Time__c';

import { promptError } from 'c/toasterUtil';
import { getErrorMessage, logInfo } from 'c/loggingUtil';
import { sessionSchedulerLabels, sessionSchedulerConstants, getSchedulingTypeLabel } from 'c/studySessionSchedulerHelper';

//Apex methods
import ctrlGetStudySessionTimes from '@salesforce/apex/REDU_SessionScheduler_LCTRL.getStudySessionTimes';


export default class StudySessionSchedulerEventChangeConfirmation extends LightningModal {
	
	//configurable attributes
    @api calendarEvents;
    @api eventActionType;
    @api timeChangedDetails;
	@api enableDebugMode = false;
	
	//internal attributes
    _timeChangedDetails;
    _calendarEvents;
    _eventActionType;

    selectedChangeType = sessionSchedulerConstants.EVENTCHANGE_SINGLE;
    selectedSessionTimes = [];

    allSessionTimesSelected = false;

	isScriptLoaded = false;
	isInitSuccess = false;
	loadedLists = 0;
	
    //wire attribute
    studySessionTimesWireResult;
    studySessionTimesResponse;
	
	//js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'tooltips'
    modules = ['stringutil', 'moment'];
	
    //wired object
    @wire(getObjectInfo, {objectApiName: SUN_OBJECT})
    sunInfo;

    @wire(getObjectInfo, {objectApiName: SSE_OBJECT})
    sseInfo;

    @wire(getObjectInfo, {objectApiName: SST_OBJECT})
    sstInfo;

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
     * @descripton rendered callback
     */
	renderedCallback(){

    }

    /**
     * @descripton connected callback
     */
    connectedCallback(){

		this.consoleLog(this.calendarEvents, true);
        this.consoleLog(this.eventActionType, true);
        this.consoleLog(this.timeChangedDetails, true);

        this._timeChangedDetails = JSON.parse(JSON.stringify(this.timeChangedDetails));
        this._calendarEvents = JSON.parse(JSON.stringify(this.calendarEvents));
        this._eventActionType = this.eventActionType;

        this.selectedSessionTimes.push(this.studySessionTimeId);
	}
	
    /**
     * @descripton disconnected callback
     */
	disconnectedCallback() {
		
	}

    /**
     * @description Return title
     */
    get modalTitle() {
        return sessionSchedulerLabels.CONFIRMATION_LABEL;
    }

    /**
     * @description Return loading label
     */
    get loadingLabel() {
        return sessionSchedulerLabels.LOADING_LABEL;
    }

    /**
     * @description Return close label
     */
    get cancelButtonLabel() {
        return sessionSchedulerLabels.CANCEL_LABEL;
    }

    /**
     * @description Return confirm label
     */
    get confirmButtonLabel() {
        return sessionSchedulerLabels.CONFIRM_LABEL;
    }

    /**
     * @description Return current info label
     */
    get currentInfoLabel() {
        return sessionSchedulerLabels.CURRENT_INFO_LABEL;
    }

    /**
     * @description Return new info label
     */
    get newInfoLabel() {
        return sessionSchedulerLabels.NEW_INFO_LABEL;
    }

    /**
     * @description Return apply this for label
     */
    get applyThisForLabel() {
        return sessionSchedulerLabels.APPLY_THIS_FOR_LABEL;
    }

    /**
     * @description Return all picklist option label
     */
    get allOptionLabel() {
        return sessionSchedulerLabels.PICKLIST_OPTION_ALL_LABEL;
    }

    /**
     * 
     */
    get schedulingTypeLabel() {
        return getSchedulingTypeLabel(this._timeChangedDetails?.schedulingType);
    }

    /**
     * 
     */
    get currentResourceName() {
        return this._timeChangedDetails?.oldResource?.name;
    }

    /**
     * 
     */
    get newResourceName() {
        return this._timeChangedDetails?.newResource?.name || this._timeChangedDetails?.newResource?.extendedProps?.name;
    }

    /**
     * 
     */
    get startTimeLabel() {
        return this.sstInfo?.data?.fields?.reduivy__Start_Time__c?.label;
    }

    /**
     * 
     */
    get endTimeLabel() {
        return this.sstInfo?.data?.fields?.reduivy__End_Time__c?.label;
    }

    /**
     * @description Return study unit info rediness
     */
    get isSunInfoReady() {
        return this.sunInfo?.data ? true : false;
    }

    /**
     * @description Return study session info rediness
     */
    get isSseInfoReady() {
        return this.sseInfo?.data ? true : false;
    }

    /**
     * @description Return study session time info rediness
     */
    get isSstInfoReady() {
        return this.sstInfo?.data ? true : false;
    }

    /**
     * @description Return study session id from event
     */
    get studySessionId() {
        return this._calendarEvents[0]?.studySessionId;
    }

    /**
     * @description Return study session time id from event
     */
    get studySessionTimeId() {
        return this._calendarEvents[0]?.studySessionTimeId;
    }

    /**
     * @description Sample wire method that invoke apex controller to retrieve data
     */
    @wire(ctrlGetStudySessionTimes, {
        studySessionId: "$studySessionId"
    })
    wireGetStudySessionTimes(result) {
        
        this.studySessionTimesWireResult = result;
        this.studySessionTimesResponse = null;

        if (result.data) {
            this.studySessionTimesResponse = JSON.parse(result.data.responseData);
            this.consoleLog(this.studySessionTimesResponse, true);
        } else if (result.error) {
            promptError(sessionSchedulerLabels.ERROR_LABEL, getErrorMessage(result.error));
        }

    }

    /**
     * @description Return true if the resource is not qualified
     */
    get isUnqualified() {
        let calEvtSession = this._calendarEvents[0]?.eventSobj?.reduivy__Study_Session_Time__r?.reduivy__Study_Session__r;
        let resource = this._timeChangedDetails?.newResource?.resourceSobj;

        if (calEvtSession && resource) {

            if (this._timeChangedDetails?.schedulingType === sessionSchedulerConstants.FACILITY) {
                this.consoleLog(calEvtSession.reduivy__Required_Facility_Type__c);
                this.consoleLog(resource.reduivy__Facility_Type__c);

                if (calEvtSession?.reduivy__Required_Facility_Type__c) {
                    return calEvtSession.reduivy__Required_Facility_Type__c !== resource.reduivy__Facility_Type__c;
                }
            
            } else if (this._timeChangedDetails?.schedulingType === sessionSchedulerConstants.FACULTY) {
                if (resource?.reduivy__Qualified_Faculties__r?.records) {
                    let sunId = calEvtSession?.reduivy__Study_Offering__r?.reduivy__Study_Unit__c;

                    for (let qfa of resource.reduivy__Qualified_Faculties__r.records) {
                        if (qfa.reduivy__Study_Unit__c === sunId) {
                            return false;
                        }
                    }
                }
            }

            return true;
        }

        return false;
    }

    /**
     * @description Return unqualified message
     */
    get unqualifiedMsg() {
        let msg = sessionSchedulerLabels.UNQUALIFIED_RESOURCE_LABEL;

        if (this._eventActionType === sessionSchedulerConstants.EVENTACTION_ALLOCATE || 
            this._eventActionType === sessionSchedulerConstants.EVENTACTION_CHANGETIME_DROP ||
            this._eventActionType === sessionSchedulerConstants.EVENTACTION_CHANGETIME_RESIZE
        ) {
            let mergeValues = [this.schedulingTypeLabel.toLowerCase()];

            if (this._timeChangedDetails?.schedulingType === sessionSchedulerConstants.FACILITY) {
                mergeValues.push(this.sseInfo?.data?.fields?.reduivy__Required_Facility_Type__c.label.toLowerCase());
            } else {
                mergeValues.push(this.sunInfo?.data?.label.toLowerCase());
            }
            
            return msg.format(mergeValues);
        }

        return '';
    }

    /**
     * @description Return true if time has changed
     */
    get timeChanged() {
        return this._eventActionType === sessionSchedulerConstants.EVENTACTION_CHANGETIME_DROP || this._eventActionType === sessionSchedulerConstants.EVENTACTION_CHANGETIME_RESIZE ? true : false;
    }

    /**
     * @description Return true if the start time has changed
     */
    get isNewStart() {
        return this._timeChangedDetails?.newStart ? true : false;
    }

    /**
     * @description Return confirmation message
     */
    get confirmationMsg() {

        if (this._eventActionType === sessionSchedulerConstants.EVENTACTION_ALLOCATE) {
            return sessionSchedulerLabels.EVENT_ALLOCATION_CONFIRMATION_LABEL.format([this.newResourceName]);
            
        } else if (this._eventActionType === sessionSchedulerConstants.EVENTACTION_UNALLOCATE) {
            return sessionSchedulerLabels.EVENT_UNALLOCATION_CONFIRMATION_LABEL.format([this.newResourceName]);

        } else if (this._eventActionType === sessionSchedulerConstants.EVENTACTION_CHANGETIME_DROP || this._eventActionType === sessionSchedulerConstants.EVENTACTION_CHANGETIME_RESIZE) {
            return sessionSchedulerLabels.EVENT_TIME_CHANGE_CONFIRMATION_LABEL;

        }

        return sessionSchedulerLabels.UNSUPPORTED_ACTION_LABEL.format([this._eventActionType]);
    }

    /**
     * @description Event change options
     */
    get changeTypeOptions(){
        
        return [
            { label: sessionSchedulerLabels.EVENT_CHANGE_OPTION_THISEVENT_LABEL, value: sessionSchedulerConstants.EVENTCHANGE_SINGLE },
            { label: sessionSchedulerLabels.EVENT_CHANGE_OPTION_ALLTHISDAY_LABEL, value: sessionSchedulerConstants.EVENTCHANGE_ALLTHISDAY },
            { label: sessionSchedulerLabels.EVENT_CHANGE_OPTION_THISWEEK_LABEL, value: sessionSchedulerConstants.EVENTCHANGE_THISWEEK },
            { label: sessionSchedulerLabels.EVENT_CHANGE_OPTION_THISANDNEXTWEEK_LABEL, value: sessionSchedulerConstants.EVENTCHANGE_TWOWEEKS },
            { label: sessionSchedulerLabels.EVENT_CHANGE_OPTION_THISANDNEXT3WEEKS_LABEL, value: sessionSchedulerConstants.EVENTCHANGE_FOURWEEKS },
            { label: sessionSchedulerLabels.EVENT_CHANGE_OPTION_THISANDFUTURE_LABEL, value: sessionSchedulerConstants.EVENTCHANGE_FUTURE }
        ];

        
    }

    /**
     * @description Return the option for session time combobox
     */
    get sessionTimeOptions() {
        let options = [];

        if (this.studySessionTimesResponse) {
            options = this.studySessionTimesResponse.map(sst => ({
                label: sessionSchedulerLabels.SST_EVENT_CHANGE_TITLE_LABEL.format([
                    sst.Name,
                    sst.reduivy__Day_of_Week__c_PicklistLabel,
                    moment(sst.reduivy__Start_Date_Calculated__c + ' ' + sst.reduivy__Start_Time__c.replace('Z', '')).format('h:mm a'),
                    moment(sst.reduivy__End_Date_Calculated__c + ' ' + sst.reduivy__End_Time__c.replace('Z', '')).format('h:mm a'),
                    sst.reduivy__Recurrence__c_PicklistLabel
                ]),
                value: sst.Id,
                default: (sst.Id === this.studySessionTimeId ? true : false),
                selected: this.selectedSessionTimes.includes(sst.Id)
            }));
        }

        return options;
    }

    /**
     * @description Return true to show session time picklist option if the selectedChangeType is not equal to this event/this day events
     */
    get showSessionTimeOptions() {
        return this.selectedChangeType !== sessionSchedulerConstants.EVENTCHANGE_SINGLE && this.selectedChangeType !== sessionSchedulerConstants.EVENTCHANGE_ALLTHISDAY;
    }

    /**
     * @description Handle change type radio button on change action
     */
    handleChangeTypeOptionChange(event) {
        this.selectedChangeType = event.detail.value;
    }

    /**
     * @description Handle change session time combobox on change action
     */
    handleSessionTimeChangeOnChange(event) {

        let sessionTimeId = event.target.value;
        let isChecked = event.target.checked;

        if (sessionTimeId === 'all') {
            //handle all checkbox
            this.allSessionTimesSelected = isChecked;

            if (isChecked) {
                this.selectedSessionTimes = this.studySessionTimesResponse.map(sst => sst.Id);
            } else {
                //we reset the selected list with default session time
                this.selectedSessionTimes = [this.studySessionTimeId];
            }
        } else {
            if (isChecked){
                //Add to selected types
                this.selectedSessionTimes.push(sessionTimeId);
            } else {
                //Remove from selected types
                let filteredOpts = this.selectedSessionTimes.filter(sstId => sstId !== sessionTimeId);
                this.selectedSessionTimes = filteredOpts;
            }

            const includesAll = (arr, values) => values.every(v => arr.includes(v));
            this.allSessionTimesSelected = includesAll(this.selectedSessionTimes, this.studySessionTimesResponse.map(sst => sst.Id));
            
            this.consoleLog(this.allSessionTimesSelected);
        }
    }

    /**
     * @description Handle time picker change
     */
    handleTimeChange(event) {
        this._timeChangedDetails[event.target.dataset.fieldname] = event.detail.value;

        this.consoleLog(event.detail.value);
    }
    
    /**
     * @description Handle close click to close the modal
     * @param {*} event 
     */
    handleCancelClick() {
        this.close({});
    }

    /**
     * @description Handle close click to close the modal
     * @param {*} event 
     */
    handleConfirmClick() {
        this.close({
            operation: 'submit',
            eventActionType: this._eventActionType,
            selectedChangeType: this.selectedChangeType,
            timeChangedDetails: this._timeChangedDetails,
            selectedSessionTimes: this.selectedSessionTimes
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
        logInfo('StudySessionSchedulerEventChangeConfirmation', anything, this.enableDebugMode, isJson);
    }
	
}