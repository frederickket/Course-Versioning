/**
 * @Author 		WDCi (Lean)
 * @Date 		July 2024
 * @group 		Attendance
 * @Description Attendance taking wizard for faculty
 * @changehistory
 * ISS-001919 31-07-2024 Lean - new wizard
 * ISS-002252 16-01-2025 XW - convert search string to lowercase to achieve case insensitive searching
 * ISS-002230 22-01-2025 XW - replace hardcoded label to custom label
 */
import { LightningElement, api, wire, track } from 'lwc';
import { getObjectInfo, getPicklistValues } from "lightning/uiObjectInfoApi";
import { getRecord } from "lightning/uiRecordApi";

import SER_OBJECT from "@salesforce/schema/Study_Event_Relation__c";
import ATTENDANCE_STATUS_FIELD from "@salesforce/schema/Study_Event_Relation__c.Attendance_Status__c";

import { promptInfo, promptError, promptWarning, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';
import { initCacheIdx } from 'c/lwcUtil';
import { customLabels } from 'c/labelLoader';

import genericConfirmationModal from 'c/genericConfirmationModal';

const SEV_FIELDS = [
    "reduivy__Study_Event__c.Id",
    "reduivy__Study_Event__c.Name"
];

//refresh module
import { refreshApex } from '@salesforce/apex';
import { RefreshEvent, registerRefreshHandler, unregisterRefreshHandler } from 'lightning/refresh';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';

//Apex methods
import ctrlGetStudentAttendances from '@salesforce/apex/REDU_StudentAttendanceRegistry_LCTRL.getStudentsAttendances';
import ctrlSaveStudentAttendances from '@salesforce/apex/REDU_StudentAttendanceRegistry_LCTRL.saveStudentAttendances';

import TAKING_ATTENDANCE_FOR_LABEL from '@salesforce/label/c.Taking_Attendance_For_Title';
import SORTING_NAME_ASCENDING_LABEL from '@salesforce/label/c.Sorting_Name_Ascending';
import SORTING_NAME_DESCENDING_LABEL from '@salesforce/label/c.Sorting_Name_Descending';
import MASS_ACTION_LABEL from '@salesforce/label/c.Mass_Action';
import MASS_ACTION_HELP_LABEL from '@salesforce/label/c.Mass_Action_Help';

export default class StudentAttendanceRegistry extends LightningElement {
	
	//configurable attributes
    @api recordId;
    @api userMode = 'Admin';
    @api modalTitle;
    @api modalIconName;
    @api sevInfoFields;
    @api studyEventRelationEditFieldSetName;
    @api attendanceStatuses;
    @api contactTileInfoFields;
    @api contactImageFileName;
    @api contactImageUrlFieldName;
    @api contactTileClickAction; //support View Info and View Record
    @api infoModalFieldsForContact;
    @api infoModalSectionNameForContact;
    @api infoModalFieldsForIndividualSessionEnrollment;
    @api infoModalSectionNameForIndividualSessionEnrollment;

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
    studentAttendanceStatusOptionWireResult;
    studentAttendanceStatusOptionResponse;
    studentAttendancesWireResult;
    studentAttendancesResponse;
    studyEventWireResult;
    studyEventResponse;

    _reactor;

    //draft student attendance for modication
    draftStudentAttendances;

    //to hold the value for quick search
    studentSearchValue;
    studentSortingInfo = this.SORTING_NAME_ASCENDING_VALUE;

    SORTING_NAME_ASCENDING_VALUE = 'reduivy__Relation_Name__c|asc';
    SORTING_NAME_DESCENDING_VALUE = 'reduivy__Relation_Name__c|desc';

    //track unsaved changes
    hasUnsavedChanges = false;

	//labels
	label = customLabels;
	
	//js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'tooltips'
    modules = ['lodash', 'stringutil'];
	
	/**
     * @descripton library loader
     */
    handleLibLoadSuccess(event) {
        this.isScriptLoaded = true;
        this.isInitSuccess = true;
        
        this._reactor = initCacheIdx();
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
        // Add the event listener for the 'beforeunload' event
        window.addEventListener('beforeunload', this.handleBeforeUnload);

		this.refreshHandlerID = registerRefreshHandler(this, this.refreshData);

        this._cacheIdx = initCacheIdx();
	}
	
    /**
     * @descripton disconnected callback
     */
	disconnectedCallback() {
        // Remove the event listener when the component is destroyed
        window.removeEventListener('beforeunload', this.handleBeforeUnload);

		unregisterRefreshHandler(this.refreshHandlerID);
	}

    /**
     * @description Refresh data
     */
    refreshData() {
        this.consoleLog('refreshData');

        refreshApex(this.studentAttendanceStatusOptionWireResult)
        refreshApex(this.studentAttendancesWireResult);

        return new Promise((resolve) => {
            resolve(true);
        });

    }

    /**
     * @description Return true to show modal title and icon
     */
    get showModalHeader(){
        if(this.modalTitle){
            return true;
        }
        return false;
    }

    /**
     * @description Return study event record name
     */
    get studyEventName() {
        return this.studyEventResponse?.fields?.Name?.value;
    }

    /**
     * @description Return info fields
     */
    get infoFields() {
        let infos = [];
        if (this.sevInfoFields) {
            infos = this.sevInfoFields.split(';');
        }

        return infos;
    }

    /**
     * @description Return taking attendance title text
     */
    get takingAttendanceText() {
        return TAKING_ATTENDANCE_FOR_LABEL.format([this.studyEventName]);
    }

    /**
     * @description Return sorting ascending text
     */
    get sortingNameAscendingText() {
        return SORTING_NAME_ASCENDING_LABEL;
    }

    /**
     * @description Return sorting descending text
     */
    get sortingNameDescendingText() {
        return SORTING_NAME_DESCENDING_LABEL;
    }

    /**
     * @description Return mass action label
     */
    get massActionLabel() {
        return MASS_ACTION_LABEL;
    }

    /**
     * @description Return mass action help text
     */
    get massActionHelptext() {
        return MASS_ACTION_HELP_LABEL;
    }

    /**
     * @description Return student name search field placeholder text
     */
    get quickSearchPlaceholderText() {
        return customLabels.SEARCHPLACEHOLDER_LABEL.format([customLabels.STUDENT_LABEL]);
    }

    /**
     * @description Return total students
     */
    get studentCountTotal() {
        if (this.studentAttendancesResponse) {
            return this.studentAttendancesResponse.length;
        }

        return 0;
    }

    /**
     * @description Return students count by attendance status
     */
    get studentsCountByAttendanceStatus() {
        let statistics = []

        if (this.attendanceStatusOptions) {
            for (let attendanceStatus of this.attendanceStatusOptions) {
                let attStat = {
                    label: attendanceStatus.label,
                    count: 0,
                }
                
                let count = 0;
                if (this.draftStudentAttendances) {
                    for (let studentAttendance of this.draftStudentAttendances) {
                        if (studentAttendance.reduivy__Attendance_Status__c === attendanceStatus.value) {
                            count ++;
                        }
                    }
                }

                attStat.count = count;

                statistics.push(attStat);
            }
        }

        return statistics;
    }

    /**
     * @description Wire method to get study event relation object info
     */
    @wire(getObjectInfo, { objectApiName: SER_OBJECT })
    serObjInfo;

    /**
     * @description Wire method to get attendance status picklist options
     */
    @wire(getPicklistValues, { recordTypeId: "$serObjInfo.data.defaultRecordTypeId", fieldApiName: ATTENDANCE_STATUS_FIELD })
    wireAttendanceStatusOptions({error, data}) {
        if (data) {
            this.studentAttendanceStatusOptionResponse = data.values;
            this.consoleLog(this.studentAttendanceStatusOptionResponse, true);

        } else if (error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
        }
    }

    /**
     * @description Get study event record
     */
    @wire(getRecord, { recordId: "$recordId", fields: SEV_FIELDS })
    wiredRecord(result) {
        
        this.studyEventWireResult = result;

        if (result.data) {
            this.studyEventResponse = result.data;
            this.consoleLog(this.studyEventResponse, true);
            
        } else if (result.error) {
            this.studyEventResponse = null;
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }

    }

    /**
     * @description Retrieve student attendance records
     */
    @wire(ctrlGetStudentAttendances, {
        cacheIdx: "$_cacheIdx",
        studyEventId: "$recordId",
        studyEventRelationEditFieldSetName: "$studyEventRelationEditFieldSetName"
    })
    wireGetStudentAttendances(result) {
        
        this.studentAttendancesWireResult = result;
        this.studentAttendancesResponse = null;

        if (result.data) {
            this.studentAttendancesResponse = JSON.parse(result.data.responseData);
            this.consoleLog(this.studentAttendancesResponse, true);

            this.draftStudentAttendances = JSON.parse(result.data.responseData);

        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }

    }

    /**
     * @description Return the attendance status picklist option and label
     */
    get attendanceStatusOptions() {

        let options = [];

        if (this.attendanceStatuses && this.studentAttendanceStatusOptionResponse) {
            for (let status of this.attendanceStatuses.split(';')) {
                for (let attStatusOpt of this.studentAttendanceStatusOptionResponse) {
                    if (status === attStatusOpt.value) {
                        options.push(attStatusOpt);
                    }
                }
            }
        }

        this.consoleLog('attendanceStatusOptions');
        this.consoleLog(options, true);

        return options;
    }

    /**
     * @description Return the list of students for attendance marking
     */
    get studentAttendances() {
        let forceUpdate = this._reactor;

        let attendanceRecords = [];

        if (this.studentAttendancesResponse) {

            for (let i = 0; i < this.studentAttendancesResponse.length; i ++) {
                let serObj = this.studentAttendancesResponse[i];
                let draftSerObj = _.find(this.draftStudentAttendances, { 'reduivy__Individual_Session_Enrollment__c': serObj.reduivy__Individual_Session_Enrollment__c });

                let studentName = serObj.reduivy__Relation_Name__c;

                let attendanceCss = 'slds-p-bottom_small ';
                if (!this.studentSearchValue || (this.studentSearchValue && studentName.toLowerCase().includes(this.studentSearchValue))) { // ISS-002252
                    attendanceCss += ' studentattendanceregistry-student-visible';
                } else {
                    attendanceCss += ' studentattendanceregistry-student-invisible';
                }

                let attendance = {
                    key: serObj.reduivy__Individual_Session_Enrollment__c,
                    serObj: serObj,
                    draftSerObj: draftSerObj,
                    cssClass: attendanceCss
                }

                attendanceRecords.push(attendance);
            }
        }

        this.consoleLog('studentAttendances');
        this.consoleLog(attendanceRecords, true);

        return attendanceRecords;
    }

    /**
     * @description Return true when data is ready for rendering
     */
    get isDataReady() {
        return this.studentAttendances && this.attendanceStatusOptions;
    }

    /**
     * @descripton List of Student sort by options
     */
    get studentSortOptions() {
        return [
            {label: this.sortingNameAscendingText, value: this.SORTING_NAME_ASCENDING_VALUE, iconName: (this.studentSortingInfo === this.SORTING_NAME_ASCENDING_VALUE ? 'utility:check' : '')},
            {label: this.sortingNameDescendingText, value: this.SORTING_NAME_DESCENDING_VALUE, iconName: (this.studentSortingInfo === this.SORTING_NAME_DESCENDING_VALUE ? 'utility:check' : '')}
        ];
    }

    /**
     * @description Handle the attendance status change submitted from child component
     * @param {*} event 
     */
    handleAttendanceRecordChange(event) {
        const {draftSerObj} = event.detail;

        for (let i = 0; i < this.draftStudentAttendances.length; i ++) {
            if (this.draftStudentAttendances[i].reduivy__Individual_Session_Enrollment__c === draftSerObj.reduivy__Individual_Session_Enrollment__c) {
                this.draftStudentAttendances[i] = draftSerObj;

                break;
            }
        }

        this.consoleLog('handleAttendanceRecordChange');
        this.consoleLog(draftSerObj, true);
        this.consoleLog(this.draftStudentAttendances, true);

        this.hasUnsavedChanges = true;
        this._reactor = initCacheIdx();
    }

    /**
     * @description Handle the quick search on commit
     */
    handleStudentSearchCommit(event) {
        this.studentSearchValue = event.target.value;
        if(this.studentSearchValue) {
            this.studentSearchValue = this.studentSearchValue.toLowerCase();
        }
        this.consoleLog('handleStudentSearchCommit :: ' + this.studentSearchValue);
    }

    /**
     * @description Handle sorting button menu on select
     */
    handleSortingSelect(event) {
        this.studentSortingInfo = event.detail.value;

        if (this.studentSortingInfo) {
            let sortingInfo = this.studentSortingInfo.split("|");
            let sortingField = sortingInfo[0];
            let sortingOrder = sortingInfo[1];

            this.consoleLog('studentSortingInfo :: ' + sortingField + ' ' + sortingOrder);
            this.studentAttendancesResponse = _.orderBy(this.studentAttendancesResponse, [sortingField], [sortingOrder]);
        }
    }

    /**
     * @description Handle all attended button
     */
    handleMassActionClick(event) {

        let selectedValue = event.detail.value;

        for (let i = 0; i < this.draftStudentAttendances.length; i ++) {
            let draftSerObj = JSON.parse(JSON.stringify(this.draftStudentAttendances[i]));
            draftSerObj.reduivy__Attendance_Status__c = selectedValue;
            this.draftStudentAttendances[i] = draftSerObj;
        }

        this.consoleLog('handleMassActionClick');
        this.consoleLog(this.draftStudentAttendances, true);

        this.hasUnsavedChanges = true;
        this._reactor = initCacheIdx();

    }

    /**
     * @descripton Save attendance records
     */
    saveAttendances() {
        this.toggleSpinner(1);

        try {
            
            ctrlSaveStudentAttendances({
                studentAttendancesData: JSON.stringify(this.draftStudentAttendances)
            })
            .then(saveResult => {
                this.toggleSpinner(-1);
                promptSuccess(this.label.SUCCESS_LABEL, saveResult.message);

                if (saveResult.responseData) {
                    //notify the record update for study event and study event relation
                    let recordIds = [{recordId: this.recordId}];
                    for (let savedSer of JSON.parse(saveResult.responseData)) {
                        recordIds.push({recordId: savedSer.Id});
                    }

                    notifyRecordUpdateAvailable(recordIds);
                }
                
                this.hasUnsavedChanges = false;

                this._cacheIdx = initCacheIdx();
                
                //fire refresh event so that all data is refreshed
                this.dispatchEvent(new RefreshEvent());
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

    /**
     * @description Handle close button click
     */
    handleCloseClick() {
        if (this.hasUnsavedChanges) {
            this.promptUnsavedChangesConfirmation();

        } else {
            this.doCloseRegistry();
        }
        
    }

    /**
     * @description Handle save button click
     */
    handleSaveClick() {
        
        this.saveAttendances();
    }

    /**
     * @description Handle browser tab unload event to check for unsaved changes
     * @param {*} event 
     */
    handleBeforeUnload = (event) => {
        if (this.hasUnsavedChanges) {
            event.preventDefault();
            // For most browsers, a custom message is ignored, but still need to set it
            event.returnValue = customLabels.UNSAVED_CHANGES_WARNING_TEXT_LABEL;
        }
    };

    /**
     * @description Prompt unsaved changes warning
     */
    promptUnsavedChangesConfirmation() {
        genericConfirmationModal.open({
            size: 'small',
            modalTitle: customLabels.UNSAVED_CHANGES_WARNING_TITLE_LABEL,
            confirmationText1: customLabels.UNSAVED_CHANGES_WARNING_TEXT_LABEL,
            showSubmitButton: true,
            submitButtonLabel: customLabels.UNSAVED_CHANGES_STAY_BUTTON_LABEL,
            showCancelButton: true,
            cancelButtonLabel: customLabels.UNSAVED_CHANGES_LEAVE_BUTTON_LABEL,
            eventSource: 'closeattendanceregistry',
            enableDebugMode: this.enableDebugMode
        }).then((result) => {
            
            if (result) {
                this.consoleLog('promptUnsavedChangesConfirmation.close');
                this.consoleLog(result, true);

                const {operation, eventSource} = result;

                if (operation === 'cancel' && eventSource === 'closeattendanceregistry') {
                    this.doCloseRegistry();
                }
            }
        });
    }

    /**
     * @description fire the close attendance registry event
     */
    doCloseRegistry() {
        this.dispatchEvent(new CustomEvent("closeattendanceregistry", {}));
    }

    /**
     * @descripton Spinner loading status
     */
	get isLoading(){
        return this.loadedLists === 0 && this.studentAttendancesResponse ? false : true;
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
        logInfo('StudentAttendanceRegistry', anything, this.enableDebugMode, isJson);
    }
	
}