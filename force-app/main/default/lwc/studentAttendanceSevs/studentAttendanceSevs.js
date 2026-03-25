/**
 * @Author 		WDCi (Lean)
 * @Date 		July 2024
 * @group 		Attendance
 * @Description Attendance taking wizard for faculty
 * @changehistory
 * ISS-001919 31-07-2024 Lean - new wizard
 */
import { LightningElement, api, wire, track } from 'lwc';
import { promptInfo, promptError, promptWarning, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';
import { initCacheIdx } from 'c/lwcUtil';
import { customLabels } from 'c/labelLoader';

//refresh module
import { RefreshEvent, registerRefreshHandler, unregisterRefreshHandler } from 'lightning/refresh';

//Apex methods
import ctrlGetStudyEvents from '@salesforce/apex/REDU_StudentAttendance_LCTRL.getStudyEvents';

import NO_EVENT_FOUND_LABEL from '@salesforce/label/c.No_Event_Found';

export default class StudentAttendanceSevs extends LightningElement {
	
	//configurable attributes
    @api recordId;
    @api userMode;
    @api forDate;
    @api attendanceTileIcon;
    @api attendanceButtonLabel;
    @api sevTileInfoFields;
    @api showNoAttendanceWarning = false;
    @api noAttendanceWarningText;
    @api noAttendanceWarningIcon;
    @api noAttendanceWarningIconVariant;
    @api studyEventTileClickAction;
    @api infoModalFieldsForStudyEvent;
    @api infoModalSectionNameForStudyEvent;
    @api showRecordsBasedOnAllocation;
    @api validFacultyIsnStatus;
    
	@api enableDebugMode = false;
	
	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false
	loadedLists = 0;
	
    //refresh handler
    refreshHandlerID;
    
    //local cache idx to force rerendering
    _cacheIdx;

    //wire attribute
    studyEventsResponse;

	//labels
	label = customLabels;
	
	//js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'tooltips'
    modules = ['moment'];
	
	/**
     * @descripton library loader
     */
    handleLibLoadSuccess() {
        this.isScriptLoaded = true;
        this.isInitSuccess = true;
        
        this.initData();
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
        this._cacheIdx = initCacheIdx();

        this.initData();

        return new Promise((resolve) => {
            resolve(true);
        });

    }

    /**
     * @description Return no event found text
     */
    get noEventFoundText() {
        return NO_EVENT_FOUND_LABEL;
    }

    /**
     * @descripton Init data, not using wire method as some of the params could be empty
     */
    initData() {
        this.toggleSpinner(1);

        try {
            ctrlGetStudyEvents({
                recordId: this.recordId,
                userMode: this.userMode,
                forDate: this.forDate,
                validFacultyIsnStatus: this.validFacultyIsnStatus,
                showRecordsBasedOnAllocation: this.showRecordsBasedOnAllocation,
                cacheIdx: this._cacheIdx
            })
            .then(result => {
                this.toggleSpinner(-1);
                this.studyEventsResponse = JSON.parse(result.responseData);

                this.consoleLog('initData');
                this.consoleLog(this.studyEventsResponse, true);

            })
            .catch(error => {
                promptError(this.label.ERROR_LABEL, getErrorMessage(error));
                this.toggleSpinner(-1);
                
            })            

        } catch (error) {
            this.toggleSpinner(-1);
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
        }
    }

    get studyEvents() {
        if (this.studyEventsResponse) {
            return this.studyEventsResponse;
        }

        return [];
    }

    get hasStudyEvents() {
        return this.studyEvents && this.studyEvents.length > 0;
    }

    /**
     * @description Handle view attendance registry button click from child
     */
    handleViewAttendanceRegistry(event) {
        this.dispatchEvent(new CustomEvent("viewattendanceregistry", {
            detail: {
                sevObj: event.detail.sevObj
            }
        }));
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
        logInfo('StudentAttendanceSevs', anything, this.enableDebugMode, isJson);
    }
	
}