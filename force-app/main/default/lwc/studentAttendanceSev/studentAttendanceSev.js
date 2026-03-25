/**
 * @Author 		WDCi (Lean)
 * @Date 		July 2024
 * @group 		Attendance
 * @Description Attendance taking wizard for faculty
 * @changehistory
 * ISS-001919 31-07-2024 Lean - new wizard
 */
import { LightningElement, api, wire, track } from 'lwc';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';
import { customLabels } from 'c/labelLoader';

//refresh module
import { refreshApex } from '@salesforce/apex';
import { RefreshEvent, registerRefreshHandler, unregisterRefreshHandler } from 'lightning/refresh';

export default class StudentAttendanceSev extends LightningElement {
	
	//configurable attributes
    @api sevObj;
    @api attendanceTileIcon;
    @api attendanceButtonLabel;
    @api sevTileInfoFields;
    @api showNoAttendanceWarning = false;
    @api noAttendanceWarningText;
    @api noAttendanceWarningIcon;
    @api noAttendanceWarningIconVariant;
    @api studyEventTileClickAction; //support View Info and View Record
    @api infoModalFieldsForStudyEvent;
    @api infoModalSectionNameForStudyEvent;

	@api enableDebugMode = false;
	
	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false
	loadedLists = 0;
	
    //refresh handler
    refreshHandlerID;

    //wire attribute
    sampleWireResult;
    sampleResponse;

	//labels
	label = customLabels;
	
	//js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'tooltips'
    modules = [];
	
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

        refreshApex(this.sampleWireResult);

        return new Promise((resolve) => {
            resolve(true);
        });

    }

    /**
     * @description Return tile title
     */
    get tileTitle() {
        return this.sevObj?.Name;
    }

    /**
     * @description Return tile info fields
     */
    get tileInfoFields() {
        let infos = [];
        if (this.sevTileInfoFields) {
            infos = this.sevTileInfoFields.split(';');
        }

        return infos;
    }

    /**
     * @description Return tile colour
     */
    get tileHighlightColour() {
        if (this.sevObj?.reduivy__Study_Session_Time__r?.reduivy__Study_Session__r?.reduivy__Background_Colour__c) {
            return this.sevObj?.reduivy__Study_Session_Time__r?.reduivy__Study_Session__r?.reduivy__Background_Colour__c;
        }

        return this.sevObj?.reduivy__Study_Session_Time__r?.reduivy__Study_Session__r?.reduivy__Study_Offering__r?.reduivy__Study_Unit__r?.reduivy__Background_Colour__c;
    }

    /**
     * @description Return true if has attendance taken
     */
    get hasAttendanceMarked() {
        if (this.showNoAttendanceWarning) {
            if (this.sevObj?.reduivy__Study_Event_Relations__r && this.sevObj.reduivy__Study_Event_Relations__r.records.length > 0) {
                return true;
            }
        } else {
            return true;
        }

        return false;
    }

    /**
     * @description Handle view attendance registry button click
     */
    handleAttendanceRegistryClick() {
        this.dispatchEvent(new CustomEvent("viewattendanceregistry", {
            detail: {
                sevObj: this.sevObj
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
        logInfo('StudentAttendanceSev', anything, this.enableDebugMode, isJson);
    }
	
}