/**
 * @author      WDCi (Lean)
 * @date        Jun 2024
 * @group       Study Session Scheduler
 * @description Study session scheduler session component
 * @changehistory
 * ISS-001920 11-06-2024 Lean - new class
 * ISS-002202 06-12-2024 XW - fixed variable name mismatch with sessionGroup lwc
 * ISS-002270 13-02-2025 XW - Fixed bug where sse display name format is not working
 * ISS-002299 18-02-2025 XW - Fixed typo of customActionFlowFinishBehavior
 * ISS-002661 23-10-2025 XW - icon class shows red if the study event from different timezone has conflict
 */
import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

import { promptError, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo } from 'c/loggingUtil';
import { sessionSchedulerLabels, sessionSchedulerConstants } from 'c/studySessionSchedulerHelper';
import TIME_ZONE from '@salesforce/i18n/timeZone';

import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getMergeKeys, mergeValues} from 'c/lwcUtil';
import SSE_OBJECT from '@salesforce/schema/Study_Session__c';

import customActionModal from 'c/studySessionSchedulerCustomActionModal';
import sessionEditModal from 'c/studySessionSchedulerSessionEditModal';
import genericConfirmationModal from 'c/genericConfirmationModal';
import assignFacilityModal from 'c/studySessionSchedulerAssignFacilityModal'
import assignFacultyModal from 'c/studySessionSchedulerAssignFacultyModal'
import sendAnnouncementModal from 'c/studySessionSchedulerAnnouncementModal';
import previewModal from 'c/studySessionSchedulerPreviewModal';
import doubleBookedModal from 'c/studySessionSchedulerSessionDoubleBookedModal';

//refresh module
import { refreshApex } from '@salesforce/apex';
import { RefreshEvent, registerRefreshHandler, unregisterRefreshHandler } from 'lightning/refresh';

//Apex methods
import ctrlDeleteStudySession from '@salesforce/apex/REDU_SessionSchedulerSession_LCTRL.deleteStudySession';
import ctrlCheckDoubleBooking from '@salesforce/apex/REDU_SessionSchedulerSession_LCTRL.checkDoubleBooking';

//label
import DOUBLE_BOOKED_LABEL from '@salesforce/label/c.Double_Booked';


const ERROR_CLASS = 'slds-icon-text-error';
const WARNING_CLASS = 'slds-icon-text-warning';
const SUCCESS_CLASS = 'slds-icon-text-success';

export default class StudySessionSchedulerSession extends NavigationMixin(LightningElement) {
	
	//configurable attributes
    @api allowEditSession = false;
    @api allowDeleteSession = false;
    @api allowFacilityAssignment = false;
    @api allowFacultyContactAssignment = false;
    @api allowPreviewSession = false;
    @api allowSendAnnouncement = false;
    @api allowCustomAction = false;

    @api customActionLabel;
    @api customActionFlowName; //ISS-002202
    @api customActionFlowFinishBehavior = 'NONE'; //Allows NONE and RESTART
    @api customActionShowCloseButton;

    //session edit form
    @api editFormStudySessionFieldSetName;
    @api editFormStudySessionTimeFieldSetName;
    @api editFormSseColumnNo;
    @api editFormSstColumnNo;
    @api accordionBackgroundColor;
    @api accordionTextColor;
    @api accordionButtonVariant;

    @api studySessionNameFormat;
    @api facilityDefaultCriteria;
    @api allowCrossCampusFacilityAllocation = false;

    @api neutralizedCurrentCalendarStartDate;
    @api neutralizedCurrentCalendarEndDate;

    @api timelineMinTime;
    @api timelineMaxTime;

    /**
     * @description To make the object reactive to changes from parent
     */
    @api
    set sseObj(val) {
        this._sseObj = val;
    }

    get sseObj() {
        return this._sseObj;
    }

    /**
     * @description strigified json data
     */
    @api 
    set hiddenGroupsAndStudySessions(val) {
        this.consoleLog('hiddenGroupsAndStudySessions');
        this.consoleLog(val, true);

        this._hiddenGroupsAndStudySessions = JSON.parse(val);
    }

    get hiddenGroupsAndStudySessions() {
        return this._hiddenGroupsAndStudySessions;
    }

    @api parentIds; //stringified array
	@api enableDebugMode = false;
	
	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false;
	loadedLists = 0;
	
    //refresh handler
    refreshHandlerID;
    
    //double booking attribute
    doubleBookingWireResult;
    doubleBookingRawData;
    doubleBookedSerList = {};
    
	//labels
	label = sessionSchedulerLabels;
	
	//js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'tooltips'
    modules = ['stringutil'];

    @track _sseObj;
    @track _hiddenGroupsAndStudySessions;
    @track _parentIds = [];

    //we don't use getter method to avoid performance issue
    facilityIconClass;
    facultyIconClass;

    //wired object
    @wire(getObjectInfo, {objectApiName: SSE_OBJECT})
    sseObjInfo;

	/**
     * @descripton library loader
     */
    handleLibLoadSuccess() {
        this.isScriptLoaded = true;
        this.isInitSuccess = true;
        
        this.updateCssVars();
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
		this.refreshHandlerID = registerRefreshHandler(this, this.refreshData);

        //we store the parent hierarchy here
        if (this.parentIds) {
            this._parentIds = JSON.parse(this.parentIds);
        }
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
        refreshApex(this.doubleBookingWireResult);

        return new Promise((resolve) => {
            resolve(true);
        });

    }

    /**
     * @description Return true if needs to render button menu
     */
    get showMenuItems() {
        return this.allowEditSession ||
            this.allowDeleteSession ||
            this.allowFacilityAssignment ||
            this.allowFacultyContactAssignment ||
            this.allowPreviewSession ||
            this.allowCustomAction ||
            this.allowPreviewSession
    }

    /**
     * @description Return session name
     */
    get studySessionLabel() {
        let mergeKeys = getMergeKeys(this.studySessionNameFormat);
        if(this.sseObj) {
            return mergeValues(this.studySessionNameFormat, mergeKeys, this.sseObj);
        }
        return null;
    }

    /**
     * @description Return the value for the visibility checkbox
     */
    get isVisible() {
        if (this._hiddenGroupsAndStudySessions && this._hiddenGroupsAndStudySessions.includes(this.sseObj.Id)) {
            return false;
        }

        return true;
    }

    /**
     * @description Return stringified _hiddenGroupsAndStudySessions
     */
    get stringifiedHiddenGroupsAndStudySessions() {
        return JSON.stringify(this._hiddenGroupsAndStudySessions);
    }

    /**
     * @description Return session background color
     */
    get studySessionBackgroundColor() {
        return this._sseObj?.reduivy__Background_Colour__c;
    }

    /**
     * @description Return session font color
     */
    get studySessionColor() {
        return this._sseObj?.reduivy__Text_Colour__c;
    }

    /**
     * @description Return delete record title
     */
    get deleteRecordTitle() {
        if (this.sseObjInfo?.data) {
            return this.label.DELETE_RECORD_LABEL.format([this.sseObjInfo.data.label]);
        }

        return null;
    }

    /**
     * @description Return delete record confirmation message
     */
    get deleteRecordConfirmation() {
        if (this.sseObjInfo?.data) {
            return this.label.DELETE_RECORD_CONFIRMATION_LABEL.format([this.sseObjInfo.data.label, this.sseObj.Name]);
        }

        return null;
    }

    /**
     * @description Return study session deleted message
     */
    get sseDeletedMessage() {
        if (this.sseObjInfo?.data) {
            return this.label.RECORD_DELETED_LABEL.format([this.sseObjInfo.data.label]);
        }

        return null;
    }

    /**
    * @description Return true if faculty is double booked
    */
    get facultyIsDoubleBooked() {
        return this.facultyIconClass === ERROR_CLASS;
    }

    /**
    * @description Return true if faculty is double booked
    */
    get facilityIsDoubleBooked() {
        return this.facilityIconClass === ERROR_CLASS;
    }

    /**
    * @description return true if faculty is loading
    */
    get facultyIsLoading() {
        return !this.facultyIconClass;
    }

    /**
    * @description return true if facility is loading
    */
    get facilityIsLoading() {
        return !this.facilityIconClass;
    }

    /**
    * @description return sseId
    */
    get sseId() {
        return this.sseObj.Id;
    }

    /**
     * @description check the status of double booking and return data if any
     */
    @wire(ctrlCheckDoubleBooking, {studySessionId: "$sseId"})
	checkDoubleBooking(result){
        this.doubleBookingWireResult = result;

        if(result.data){
            this.doubleBookingRawData = JSON.parse(result.data.responseData);

            //we won't use getter here to avoid performance when checking/unchecking the visibility checkbox as lwc will revalidate all getter methods
            this.facilityIconClass = this.getIconClass(sessionSchedulerConstants.FACILITY, 'reduivy__Facility__c');
            this.facultyIconClass = this.getIconClass(sessionSchedulerConstants.FACULTY, 'reduivy__Contact__c');

        } else if(result.error){
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }
    }
    
    /**
    * @description List to pass to double booked modal
    */
    doubleBookedInfoList(type){
        if(this.doubleBookedSerList[type]){
            return this.doubleBookedSerList[type].map(function(ser){
                let resourceId, resourceName;
                if(type === sessionSchedulerConstants.FACULTY) {
                    
                    resourceId = ser.reduivy__Contact__c;
                    resourceName = ser.reduivy__Contact__r.Name ;
                } else{
                    resourceId = ser.reduivy__Facility__c;
                    resourceName = ser.reduivy__Facility__r.Name;
                }

                return {
                    id: ser.Id,
                    datetime: ser.reduivy__Event_Start_Datetime__c,
                    resourceId: resourceId,
                    resourceName: resourceName,
                }
            });
        }
        return [];
    }

    /**
     * @description Update css var
     */
    updateCssVars() {
        let css = this.template.host.style;

        css.setProperty('--session-label-background-color', this.studySessionBackgroundColor);
        css.setProperty('--session-label-color', this.studySessionColor);
    }

    /**
     * @description Handle visibility checkbox onchange
     * @param {*} event 
     */
    handleVisibilityCheckboxChange(event) {
        this.consoleLog('handleVisibilityCheckboxChange');

        try {
            let checked = event.target.checked;

            let updatedObjects = [{id: this.sseObj.Id, visible: checked}];
            
            this.consoleLog(updatedObjects, true);

            let tempHolder = this.stringifiedHiddenGroupsAndStudySessions ? JSON.parse(this.stringifiedHiddenGroupsAndStudySessions) : [];
            for (let obj of updatedObjects) {

                if (obj.visible) {
                    let idx = tempHolder.indexOf(obj.id);
                    if (idx > -1) {
                        tempHolder.splice(idx, 1);
                    }
                } else {
                    tempHolder.push(obj.id);
                }
            }

            this.consoleLog(tempHolder, true);

            this.dispatchEvent(
                new CustomEvent("visibilityupdated", {
                    detail: {
                        groupOrStudySessions: tempHolder,
                        isVisible: checked
                    }
                })
            );
        } catch (err) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(err));
        }
    }

    /**
     * @descrition Remove slds-truncate when mouse in
     * @param {} event 
     */
    onSessionLabelMouseOver(event){
        let divEl = event.currentTarget;
        divEl.classList.toggle("slds-truncate");
    }

    /**
     * @descrition Add slds-truncate when mouse in
     * @param {} event 
     */
    onSessionLabelMouseOut(event){
        let divEl = event.currentTarget;
        divEl.classList.toggle("slds-truncate");
    }

    /**
     * @description Handle session label onclick to view the record
     */
    handleSessionLabelClick() {

        let classId = this.sseObj.Id;

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: classId,
                objectApiName: 'reduivy__Study_Session__c',
                actionName: 'view',
            },
        });
    }

    /**
     * @description Handle menu item action
     */
    handleMenuItemSelect(event) {

        let selectedItemValue = event.detail.value;
        
        if (selectedItemValue === 'edit') {
            this.handleSessionEdit();

        } else if (selectedItemValue === 'assignFacility') {
            this.handleAssignFacility();

        } else if (selectedItemValue === 'assignFacultyContact') {
            this.handleAssignFaculty();

        } else if (selectedItemValue === 'preview') {

            previewModal.open({
                size: 'small',
                studySessionId: this.sseObj.Id,
                modalTitle: this.label.PREVIEW_LABEL,
                sseObjId: this.sseObj.Id,
                enableDebugMode: this.enableDebugMode
            }).then(result=>{
                if(result){

                    const {operation, eventData} = result;
                    if(eventData){
                        let detail = {...eventData.detail};
                        detail.studySessionId = this.sseObj.Id
                        
                        if(operation === "submit"){
                            this.dispatchEvent(new CustomEvent('previewclicked',{
                                detail: detail
                            }));
                        }
                    }
                }
            });

        } else if (selectedItemValue === 'announcement') {
            //call studySessionSchedulerAnnouncementModal
            sendAnnouncementModal.open({
                size: 'small',
                studySessionId: this.sseObj.Id,
                modalTitle: this.label.SEND_ANNOUNCEMENT_LABEL,
                enableDebugMode: this.enableDebugMode
            });

        } else if (selectedItemValue === 'delete') {
            //call genericConfirmationModal
            genericConfirmationModal.open({
                size: 'small',
                modalTitle: this.deleteRecordTitle,
                confirmationText1: this.deleteRecordConfirmation,
                eventSource: 'studySessionSchedulerSessionDelete',
                eventData: this.sseObj,
                showSubmitButton: true,
                submitButtonLabel: this.label.DELETE_LABEL,
                showCancelButton: true,
                cancelButtonLabel: this.label.CANCEL_LABEL,
                enableDebugMode: this.enableDebugMode
            })
            .then((result) => {
                if(result){

                    const {operation, eventSource, eventData} = result;
                    if(operation === 'submit'){
                        this.deleteStudySession();
                    }
                }
            });

        } else if (selectedItemValue === 'customAction') {
            //call studySessionSchedulerCustomActionModal
            customActionModal.open({
                size: 'small',
                studySessionId: this.sseObj.Id,
                schedulerStartDate: this.neutralizedCurrentCalendarStartDate,
                schedulerEndDate: this.neutralizedCurrentCalendarEndDate,
                modalTitle: this.customActionLabel,
                flowName: this.customActionFlowName,  //ISS-002202
                flowFinishBehavior: this.customActionFlowFinishBehavior,
                showCloseButton: this.customActionShowCloseButton,
                enableDebugMode: this.enableDebugMode
            });
        }
    }

    /**
     * @description Delete study session
     */
    deleteStudySession() {
        
        this.toggleSpinner(1);

        try {
            ctrlDeleteStudySession({
                studySessionId: this.sseObj.Id
            })
            .then(deleteResult => {
                this.toggleSpinner(-1);
                promptSuccess(this.sseDeletedMessage);

                //notify the parent component about the deletion
                this.dispatchEvent(
                    new CustomEvent("studysessiondeleted", {
                        detail: {
                            studySessionId: this.sseObj.Id
                        }
                    })
                );

            })
            .catch(error => {
                promptError(sessionSchedulerLabels.ERROR_LABEL, getErrorMessage(error));
                this.toggleSpinner(-1);
                
            })            

        } catch (error) {
            this.toggleSpinner(-1);
            promptError(sessionSchedulerLabels.ERROR_LABEL, getErrorMessage(error));
        }
    }


    /**
     * @description Return class for session icon to display color
     */
    get sessionIconClass(){
        if(this.sseObj){
            if(this.sseObj.reduivy__Study_Event_Generation_Status__c === 'Draft'){
                return ERROR_CLASS;
            } else if (this.sseObj.reduivy__Study_Event_Generation_Status__c === 'Generated'){
                return SUCCESS_CLASS;
            }
        }
        
        return ERROR_CLASS;
    }
    
    /**
     * @description Handle Edit Session Button
     */
    handleSessionEdit() {
        //call studySessionSchedulerSessionEditModal
        sessionEditModal.open({
            size: 'large',
            modalTitle: sessionSchedulerLabels.EDIT_LABEL,
            facilityDefaultCriteria: this.facilityDefaultCriteria,
            allowCrossCampusFacilityAllocation: this.allowCrossCampusFacilityAllocation,
            studySessionFieldSetName: this.editFormStudySessionFieldSetName,
            studySessionTimeFieldSetName: this.editFormStudySessionTimeFieldSetName,
            sseColumnNo: this.editFormSseColumnNo,
            sstColumnNo: this.editFormSstColumnNo,
            sseObj: this.sseObj,
            accordionBackgroundColor: this.accordionBackgroundColor,
            accordionTextColor: this.accordionTextColor,
            accordionButtonVariant: this.accordionButtonVariant,
            timelineMaxTime: this.timelineMaxTime,
            timelineMinTime: this.timelineMinTime,
            enableDebugMode: this.enableDebugMode
        }).then((result) => {
            if (result) {
                this.consoleLog(result);
                const { operation, eventData } = result;

                if(operation !== 'cancel'){
                    promptSuccess(this.label.SUCCESS_LABEL, this.label.YOUR_CHANGES_ARE_SAVED_LABEL);

                    if(Array.isArray(eventData)){
                        notifyRecordUpdateAvailable(eventData);
                    }

                    this.dispatchEvent(new RefreshEvent());
                }
            }

        });
    }

    /**
     * @description Handle view facility double book info
     */
    handleViewFacilityDoubleBookInfo() {

        doubleBookedModal.open({
            label: DOUBLE_BOOKED_LABEL,
            size: 'small',
            modalTitle: DOUBLE_BOOKED_LABEL,
            doubleBookedInfoList: this.doubleBookedInfoList(sessionSchedulerConstants.FACILITY),
            type: sessionSchedulerLabels.FACILITY_LABEL,
            enableDebugMode: this.enableDebugMode
        }).then(result=>{
            this.consoleLog(result);

            if (result) {
                const { operation } = result;

                if (operation === 'assignfacility') {
                    this.handleAssignFacility();
                } else if (operation === 'assignfaculty') {
                    this.handleAssignFaculty();
                }
            }
        });
    }

    /**
     * @description Handle view faculty double book info
     */
    handleViewFacultyDoubleBookInfo() {

        doubleBookedModal.open({
            label: DOUBLE_BOOKED_LABEL,
            size: 'small',
            modalTitle: DOUBLE_BOOKED_LABEL,
            doubleBookedInfoList: this.doubleBookedInfoList(sessionSchedulerConstants.FACULTY),
            type: sessionSchedulerLabels.FACULTY_LABEL,
            enableDebugMode: this.enableDebugMode
        }).then(result=>{
            this.consoleLog(result);

            if (result) {
                const { operation } = result;

                if (operation === 'assignfacility') {
                    this.handleAssignFacility();
                } else if (operation === 'assignfaculty') {
                    this.handleAssignFaculty();
                }
            }
        });
    }

    /**
     * @description Handle Assign Facility Button
     */
    handleAssignFacility() {
        assignFacilityModal.open({
            size: 'small',
            sseObj: this.sseObj,
            modalTitle: this.label.ASSIGN_FACILITY_LABEL,
            facilityDefaultCriteria: this.facilityDefaultCriteria,
            allowCrossCampusFacilityAllocation: this.allowCrossCampusFacilityAllocation,
            enableDebugMode: this.enableDebugMode
        }).then(result=>{
            if(result){
                this.consoleLog(result);
                const { operation, eventData } = result;
                if (operation === "submit") {
                    promptSuccess(this.label.SUCCESS_LABEL, this.label.YOUR_CHANGES_ARE_SAVED_LABEL);
                    notifyRecordUpdateAvailable(eventData);
                    
                    this.dispatchEvent(new RefreshEvent());
                }
            }
        });
    }
        
    /**
     * @description Handle Assign Faculty Button
     */
    handleAssignFaculty(){
        assignFacultyModal.open({
            size: 'medium',
            sseObj: this.sseObj,
            modalTitle: this.label.ASSIGN_FACULTY_LABEL,
            enableDebugMode: this.enableDebugMode
        }).then(result=>{
            if(result){
                this.consoleLog(result);
                const {operation, eventData} = result;
                if(operation === "submit" && eventData.length > 0 ){
                    this.dispatchEvent(new RefreshEvent());
                }
            }
        });
    }
    
    /**
     * @description The generic function for facility or faculty icon color
     * @param {String} type sessionSchedulerConstants.FACILITY or sessionSchedulerConstants.FACULTY
     * @returns The class that represents Error, Warning or Success
     */
    getIconClass(type, resourceFieldName){

        //double booking checking
        if(this.doubleBookingRawData){   
            let totalTrueConflict = [];
            for(let sessionSer of this.doubleBookingRawData.sessionData[type]){

                //consider study event from different timezone
                let sessionStart = sessionSer.reduivy__Event_Start_Datetime__c;
                let sessionEnd = sessionSer.reduivy__Event_End_Datetime__c;

                let trueConflict = this.doubleBookingRawData.conflictData[type].filter(function(conflictSer){
                    //not conflicted if they are the same ser
                    if(conflictSer.Id === sessionSer.Id) {
                        return false;
                    }

                    //not conflicted if they are not shared by a same resource
                    if(conflictSer[resourceFieldName] !== sessionSer[resourceFieldName]) {
                        return false;
                    }
                    
                    let conflictStart = conflictSer.reduivy__Event_Start_Datetime__c;
                    let conflictEnd = conflictSer.reduivy__Event_End_Datetime__c;
                    
                    //conflicted if time overlap occur. datetime format = YYYY-MM-DDTHH:mm:ss.sss+00:00
                    return (sessionStart < conflictEnd && sessionEnd > conflictStart);
                });
                totalTrueConflict.push(trueConflict);
            }

            //to remove any empty list;
            totalTrueConflict = totalTrueConflict.filter(conflict => conflict.length > 0);

            if(totalTrueConflict.length > 0){
                this.doubleBookedSerList[type] = totalTrueConflict.flat();
                return ERROR_CLASS;
            }   

        }

        //unallocated checking
        let createdSers = [];
        let hasNoSer = false;

        for(let studyEvent of this.sseObj.studyEvents){
            if(!studyEvent.reduivy__Study_Event_Relations__r || !studyEvent.reduivy__Study_Event_Relations__r.records){
                hasNoSer = true;
                break;
            }
            
            createdSers.push([]);
            for(let ser of studyEvent.reduivy__Study_Event_Relations__r.records){
                
                if(ser.reduivy__Relation_Type__c){
                    if(ser.reduivy__Relation_Type__c.toLowerCase() === type.toLowerCase()){
                        createdSers[createdSers.length - 1].push(ser);
                    }
                }
            }
        }
        
        if(hasNoSer || createdSers.filter(evt => evt.length === 0).length > 0){
            return WARNING_CLASS;
        }

        return SUCCESS_CLASS;
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
        logInfo('StudySessionSchedulerSession', anything, this.enableDebugMode, isJson);
    }
	
}