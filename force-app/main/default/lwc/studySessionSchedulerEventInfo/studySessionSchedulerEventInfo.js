/**
 * @author      WDCi (Lean)
 * @date        Jun 2024
 * @group       Study Session Scheduler
 * @description Study session scheduler preview modal
 * @changehistory
 * ISS-001920 11-06-2024 Lean - new class
 * ISS-002736 25-11-2025 XiRouh - Added tableTextDisplayMode configurable attribute
 * ISS-002779 21-01-2026 Lean - Make table header to respect tableTextDisplayMode
 */
import { api } from 'lwc';
import LightningModal from 'lightning/modal';
import { logInfo } from 'c/loggingUtil';
import { sessionSchedulerLabels, sessionSchedulerConstants } from 'c/studySessionSchedulerHelper';
import { isWrapTextEnabled, getTableHeaderDisplayMode } from 'c/lwcUtil';

export default class StudySessionSchedulerEventInfo extends LightningModal {
	
	//configurable attributes
    @api modalTitle = this.label.STUDY_EVENT_INFO_LABEL;
	@api enableDebugMode = false;
    @api studyEventInfoFields = 'Name;reduivy__Start_Date_Non_TZ__c;reduivy__Start_Time_Non_TZ__c;reduivy__End_Time_Non_TZ__c';
    @api showUnallocatedButton = false;
    @api studyEvent;
    
    @api tableTextDisplayMode;

    eventInfoFieldsList = [];
    
    //datatable
    facilityDatatable = {};
    facultyDatatable = {};
	
	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false;
	loadedLists = 0;


	//labels
	label = sessionSchedulerLabels;
	
	//js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'tooltips'
    modules = [];

    /**
     * @description close button
     */
	get closeButtonLabel(){
        return sessionSchedulerLabels.CLOSE_LABEL;
    }

    /**
     * @description unallocate button
     */
	get unallocateButtonLabel(){
        return sessionSchedulerLabels.UNALLOCATE_LABEL;
    }

    /**
     * @description faculty datatable
     */
    get facultyDatatableData(){
        let datatable = {};
        datatable.columns = [{label: sessionSchedulerLabels.FACULTY_LABEL, fieldName: 'Name', hideDefaultActions:"true", wrapText: this.enableWrapText}];
        datatable.data = [];

        if(this.studyEvent?.reduivy__Study_Event_Relations__r?.records){
            for(let ser of this.studyEvent.reduivy__Study_Event_Relations__r.records){
                if(ser.reduivy__Relation_Type__c === sessionSchedulerConstants.FACULTY){
                    datatable.data.push({Name:ser.reduivy__Relation_Name__c});
                }
            }  
        }

        return datatable;
    }

    /**
     * @description facility datatable
     */
    get facilityDatatableData(){
        let datatable = {};
        datatable.columns = [{label: sessionSchedulerLabels.FACILITY_LABEL, fieldName: 'Name', hideDefaultActions:"true", wrapText: this.enableWrapText}];
        datatable.data = [];

        if(this.studyEvent?.reduivy__Study_Event_Relations__r?.records){
            for(let ser of this.studyEvent.reduivy__Study_Event_Relations__r.records){
                if(ser.reduivy__Relation_Type__c === sessionSchedulerConstants.FACILITY){
                    datatable.data.push({Name:ser.reduivy__Relation_Name__c});
                }
            }  
        }

        return datatable;
    }

    /**
     * @descripton return Table display mode - enable wrap text
     */
    get enableWrapText() {
        return isWrapTextEnabled(this.tableTextDisplayMode);
    }

    /**
     * @description ISS-002779 return Table header display mode - enable wrap text
     */
    get tableHeaderDisplayMode() {
        return getTableHeaderDisplayMode(this.tableTextDisplayMode);
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
     * @descripton connected callback
     */
    connectedCallback(){
        this.eventInfoFieldsList = this.studyEventInfoFields.split(';');
	}

    /**
     * @description handle close
     */
    handleClose(){
        this.close({operation: 'cancel'});
    }

    /**
     * @description Handle unallocate
     */
    handleUnallocateBooking(){
        this.close({operation: 'unallocate'});
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
        logInfo('StudySessionSchedulerSessionPreviewModal', anything, this.enableDebugMode, isJson);
    }
	
}