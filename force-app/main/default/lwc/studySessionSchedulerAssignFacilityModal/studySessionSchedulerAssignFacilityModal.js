/**
 * @Author 		WDCi (XW)
 * @Date 		Jan 2024
 * @group 		Study Session Scheduler
 * @Description 
 * @changehistory
 * ISS-001920 05-08-2024 XW - create new class
 */
import { api } from 'lwc';
import LightningModal from 'lightning/modal';
import { promptError } from 'c/toasterUtil';
import { getErrorMessage, logInfo } from 'c/loggingUtil';

import { sessionSchedulerLabels, sessionSchedulerConstants } from 'c/studySessionSchedulerHelper';
import { setupPicklistOptionsFromRecords } from 'c/lwcUtil';
import ctrlGetFacilities from '@salesforce/apex/REDU_SessionScheduler_LCTRL.getFacilities';
import ctrlUpdateAssignFacility from '@salesforce/apex/REDU_SessionFacilityAssignment_LCTRL.updateAssignFacility';


export default class StudySessionSchedulerAssignFacilityModal extends LightningModal {
	
	//configurable attributes
    @api modalTitle;
    @api modalIconName;
    @api facilityDefaultCriteria;
    @api allowCrossCampusFacilityAllocation = false;

    @api
    set sseObj(val) {
        this._sseObj = JSON.parse(JSON.stringify(val));
    }

    get sseObj() {
        if (this._sseObj) {
            return this._sseObj;
        }

        this._sseObj = {};
        return this._sseObj;
    }

	@api enableDebugMode = false;

    //internal attributes
	isScriptLoaded = false;
	isInitSuccess = false
	loadedLists = 0;

    //js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'jquery', 'tooltips'
    modules = ['stringutil', 'moment'];

    //action attributes
    ACTION_UPDATE_UNALLOCATED = 'UPDATE_UNALLOCATED';
    ACTION_ADD_INTO_ALL = 'ADD_INTO_ALL';
    ACTION_REPLACE_ALL = 'REPLACE_ALL';
    actionValue = this.ACTION_UPDATE_UNALLOCATED;

    //study session time attributes
    ALL_SESSION_TIME_VALUE = 'all'
    sessionTimeValue = this.ALL_SESSION_TIME_VALUE;

    //facility searchable attributes
    facilityOptions = [];
    facilityValue = '';

    /**
     * @descripton library loader
     */
    handleLibLoadSuccess(event) {
        this.isScriptLoaded = true;
        this.isInitSuccess = true;

        ctrlGetFacilities({
            nameFormat: '{Name}',
            defaultCriteria: this.facilityDefaultCriteria,
            filterValueStr: this.facilityFilterValues
        }).then(result => {
            let responsesJson = JSON.parse(result.responseData);
            let facilities = responsesJson.facilities;
            this.facilityOptions = setupPicklistOptionsFromRecords(facilities, 'Name');
            
        })
        
    }

    /**
     * @descripton library loader
     */
    handleLibLoadFail(event) {
        this.isScriptLoaded = true;
        this.isInitSuccess = false;
    }

    /**
     * @description Return sof campus id
     */
    get sofCampusId() {
        return this.sseObj?.reduivy__Study_Offering__r?.reduivy__Campus__c;
    }

    /**
    * @description get facility filter values to wire for get facility
    * */
    get facilityFilterValues() {
        let filters = {
            campusId: (this.allowCrossCampusFacilityAllocation ? null : this.sofCampusId)
        };

        return JSON.stringify(filters);
    }

    /**
     * @description Return modal header
     */
    get headerLabel() {
        return this.modalTitle;
    }

    /**
     * @description Description text
     */
    get actionLabel(){
        return sessionSchedulerLabels.SELECT_STUDY_EVENT_TO_UPDATE_LABEL;
    }
	
    /**
     * @description Facility label
     */
    get facilityLabel() {
        return sessionSchedulerLabels.FACILITY_LABEL;
    }
	
    /**
     * @description facility assignment option
     */
    get actionOptions(){
        let options = [];
        if(this.sseObj){

            options = [
                {
                    label: sessionSchedulerLabels.UPDATE_UNALLOCATED_STUDY_EVENTS_LABEL, 
                    value: this.ACTION_UPDATE_UNALLOCATED
                },
                {
                    label: sessionSchedulerLabels.ADD_INTO_ALL_STUDY_EVENTS_LABEL, 
                    value: this.ACTION_ADD_INTO_ALL
                },
                {
                    label: sessionSchedulerLabels.REPLACE_ALL_STUDY_EVENTS_LABEL, 
                    value: this.ACTION_REPLACE_ALL
                }
            ];
        }else{
            options = [
                {label: "", value: this.ACTION_UPDATE_UNALLOCATED},
                {label: "", value: this.ACTION_ADD_INTO_ALL},
                {label: "", value: this.ACTION_REPLACE_ALL}
            ];
        }

        return options;
    }

    /**
     * @description Study session time option
     */
    get sessionTimeOptions(){
        let options = [];
        if(this.sseObj){
            options.push({label: sessionSchedulerLabels.ALL_LABEL, value: this.ALL_SESSION_TIME_VALUE});
            let sstList = this.sseObj.reduivy__Study_Session_Times__r
            for(let sst of sstList){
                options.push({label: sst.Name, value: sst.Id});
            }
        }

        return options;
    }

    /**
     * @description Cancel button
     */
    get cancelButtonLabel() {
        return sessionSchedulerLabels.CANCEL_LABEL;
    }

    /**
     * @description Save button
     */
    get saveButtonLabel() {
        return sessionSchedulerLabels.SAVE_LABEL;
    }

    connectedCallback(){
        
    }

    /**
     * @description Action change event handler
     */
    handleActionsChange(event) {
        this.actionValue = event.target.value;
    }

    /**
     * @description Study session tim change event handler
     */
    handleSessionTimeChange(event) {
        this.sessionTimeValue = event.target.value;
    }

    /**
     * @description Facility change event handler
     */
    handleFacilityChange(event){
        const { fieldName, fieldLabel, selectedOpt } = event.detail;

        if (fieldName) {
            let value = selectedOpt?.value;
            if(value === undefined) {
                value = '';
            }
            this.facilityValue = value;
            
        }
    }

    /**
     * @description Cancel button click event handler
     */
    handleCancelClick() {
        this.close({operation: 'cancel'});
    }

    /**
     * @description Save button click event handler
     */
    handleSaveClick() {
        let studySessionTime;
        if( this.sessionTimeValue === this.ALL_SESSION_TIME_VALUE){
            studySessionTime = this.sessionTimeOptions.map(item => {return item.value});
            studySessionTime.splice(studySessionTime.indexOf(this.ALL_SESSION_TIME_VALUE), 1);
        } else {
            studySessionTime = [this.sessionTimeValue];
        }
         
        ctrlUpdateAssignFacility({
            studySessionTimeIds: studySessionTime,
            actionType: this.actionValue, 
            facilityId: this.facilityValue
        }).then(result => {
            if(result.responseData){
                let updatedEvent = [];
                let sstIdList = JSON.parse(result.responseData);
                for(let sstId of sstIdList) {
                    updatedEvent.push({recordId: sstId});
                }

                this.close({operation: 'submit', eventData: updatedEvent});
            }else{
                this.close({operation: 'cancel'});
            }
        }).catch(error => {
            promptError(sessionSchedulerLabels.ERROR_LABEL, getErrorMessage(error));

            this.close({operation: 'cancel'});
        })

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
        logInfo('StudySessionSchedulerAssignFacilityModal', anything, this.enableDebugMode, isJson);
    }
	
}