/**
 * @Author 		WDCi (CM)
 * @Date 		Aug 2024
 * @group 		Grade Management
 * @Description Student Grading Wizard - Study Session or Study Offering record page
 * @changehistory
 * ISS-001918 14-08-2024 CM - new class
 * ISS-002198 13-12-2024 XW - If the study grade period setting is not started yet, hide the save and submit button (show if today = start date)
 * ISS-002257 29-01-2025 Jordan - allow admin to lock/unlock a grading period setting and individual enrollment grade
 * ISS-002259 20-03-2025 Jordan - allow admin to configure more fields in the note screen
 * ISS-002744 13-01-2026 Lean - Handle unsaved changes
 */
import { LightningElement, api, wire, track } from 'lwc';
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { promptError, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo } from 'c/loggingUtil';
import { customLabels } from 'c/labelLoader';

import genericConfirmationModal from 'c/genericConfirmationModal';

import TIME_ZONE from '@salesforce/i18n/timeZone';

import SGP_OBJECT from "@salesforce/schema/Study_Grade_Period_Setting__c";

//refresh module
import { RefreshEvent, registerRefreshHandler, unregisterRefreshHandler } from 'lightning/refresh';

//Apex methods
import ctrlGetGradingData from '@salesforce/apex/REDU_StudentGradingRegistry_LCTRL.getGradingData';
import ctrlSaveGradingData from '@salesforce/apex/REDU_StudentGradingRegistry_LCTRL.saveGradingData';

//additional labels
import SORTING_NAME_ASCENDING from '@salesforce/label/c.Sorting_Name_Ascending';
import SORTING_NAME_DESCENDING from '@salesforce/label/c.Sorting_Name_Descending';
import SAVE_AND_SUBMIT_LABEL from '@salesforce/label/c.Save_and_Submit';
import NO_RECORD_LABEL from '@salesforce/label/c.No_Records_To_Display';

export default class StudentGradingRegistry extends LightningElement {
	
    //Automatically set
    @api recordId; //Can be automatically set via record page
    @api objectApiName; //Can be automatically set via record page

	//configurable attributes
    @api modalIconName;
    @api userMode;
    @api validStudentIenStatus;
    @api validStudentIsnStatus;
    @api individualEnrollmentGradeFieldSet;// = "reduivy__customIgdFieldset" //For testing
    @api individualGradeItemNotesFieldSetName; //ISS-002259
    @api saveButtonIgdStatus;
    @api saveAndSubmitButtonIgdStatus;
    @api showSaveButton = false;
    @api showSaveAndSubmitButton = false;
    @api showCloseButton = false;

    @api contactTileInfoFields;
    @api contactImageFileName;
    @api contactImageUrlFieldName;
    @api contactTileClickAction;
    @api infoModalFieldsForContact;
    @api infoModalSectionNameForContact;

    @api enableDebugMode = false;
    
	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false
	loadedLists = 0;
    selectedSgp;
    studentSearchKey;
    studentSortingInfo = this.SORTING_NAME_ASCENDING_VALUE;

    //Constants
    SAVE_BUTTON = "Save";
    SAVEANDSUBMIT_BUTTON = "Save and Submit";
    SEARCH_FIELD = "Search";
    SORT_FIELD = "Sort";
    
    SORTING_NAME_ASCENDING_VALUE = 'ien.reduivy__Contact__r.Name|asc';
    SORTING_NAME_DESCENDING_VALUE = 'ien.reduivy__Contact__r.Name|desc';
    
    //ISS-002744
    hasUnsavedChanges = false;
	
    //refresh handler
    refreshHandlerID;

    //wire attribute
    @track dataWrapper;

	//labels
	label = {
        ...customLabels,
        SORTING_NAME_ASCENDING,
        SORTING_NAME_DESCENDING,
        SAVE_AND_SUBMIT_LABEL,
        NO_RECORD_LABEL
    };
	
	//js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'tooltips'
    modules = ['lodash', 'stringutil', 'moment'];
	
	/**
     * @descripton library loader
     */
    handleLibLoadSuccess() {
        this.isScriptLoaded = true;
        this.isInitSuccess = true;
        
        this.consoleLog(this.recordId, false);
        this.consoleLog(this.objectApiName, false);

        //default to today
        let currentDate = moment.tz((new Date()).toISOString(), this.timezone);
        this.selectedDate = currentDate.format('yyyy-MM-DD'); //the input field only accept string

        this.getGradingData();

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

        // ISS-002744 Add the event listener for the 'beforeunload' event
        window.addEventListener('beforeunload', this.handleBeforeUnload);

		this.refreshHandlerID = registerRefreshHandler(this, this.refreshData);
	}
	
    /**
     * @descripton disconnected callback
     */
	disconnectedCallback() {
        // ISS-002744 Remove the event listener when the component is destroyed
        window.removeEventListener('beforeunload', this.handleBeforeUnload);

		unregisterRefreshHandler(this.refreshHandlerID);
	}

    /**
     * @description Refresh data
     */
    refreshData() {
        this.consoleLog('refreshData');

        this.getGradingData();

        return new Promise((resolve) => {
            resolve(true);
        });

    }

    /**
     * @description Return timezone
     */
    get timezone() {
        return TIME_ZONE;
    }

    /**
     * @description Wire method to get Study Grade Period Setting object info
     */
    @wire(getObjectInfo, { objectApiName: SGP_OBJECT })
    sgpObjInfo;

    /**
     * @descripton Get necessary data - Selected record, grading items, student enrollments, existing grades
     */
    getGradingData() {
        this.toggleSpinner(1);
        if (this.hasDataWrapper){
            //Clear old student data, ensuring page re-renders correctly
            this.dataWrapper.studentWrappers = [];
        }

        try {

            ctrlGetGradingData({
                recordId: this.recordId,
                sObjectName: this.objectApiName,
                gradingPeriod: this.selectedSgp,
                validStudentIenStatus: this.validStudentIenStatus,
                validStudentIsnStatus: this.validStudentIsnStatus,
                individualEnrollmentGradeFieldSet: this.individualEnrollmentGradeFieldSet,
                individualGradeItemNotesFieldSetName: this.individualGradeItemNotesFieldSetName
            })
            .then(result => {
                this.toggleSpinner(-1);
                this.dataWrapper = JSON.parse(result.responseData);

                this.consoleLog('getGradingData');
                this.consoleLog(this.dataWrapper, true);

                //Selected Study Grade Period Setting
                this.selectedSgp = this.dataWrapper.sgp.Id;

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
     * @description Return student name search field placeholder text
     */
    get quickSearchPlaceholderText() {
        return customLabels.SEARCHPLACEHOLDER_LABEL.format([customLabels.STUDENT_LABEL]);
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

    get hasDataWrapper() {
        return this.dataWrapper != null;
    }

    get studentWrappers(){
        if (this.hasDataWrapper) {
            return this.dataWrapper.studentWrappers;
        }

        return [];
    }

    get modalTitle(){
        if (this.hasDataWrapper){
            return this.dataWrapper.recordName;
        }

        return null;
    }

    /**
     * @descripton List of Study Grade Period Settings for selection
     */
    get sgpOptions() {
        
        if (this.hasDataWrapper) {
            return this.dataWrapper.gradingPeriodOptions;
        }

        return [];
    }

    /** ISS-002198
     * @description If the study grade period setting is not started yet, hide the save and submit button
     */
    get showSaveAndSubmitButtonCalculated(){
        let startDate = this.dataWrapper?.sgp?.reduivy__Start_Date__c;
        if(!startDate) {
            return false;
        }

        let currentDate = moment.tz((new Date()).toISOString(), this.timezone);
        startDate = moment(startDate);
        let tooEarly = false;
        if(!currentDate.isAfter(startDate)){
            tooEarly = true;
        }

        return this.showSaveAndSubmitButton && !tooEarly;
    }

    /**
     * @description ISS-002744 Return unsaved changes button icon
     */
    get unsavedChangesIcon() {
        if (this.hasUnsavedChanges) {
            return 'utility:warning';
        }
    }

    /**
     * @description ISS-002744 Return false to make button disabled if there is no changes to save
     */
    get unsavedChangesButtonState() {
        if (this.hasUnsavedChanges) {
            return false;
        }

        return true;
    }

    /**
     * @description Handle Study Grade Period Setting selection onchange
     */
    handleSgpOnChange(event) {
        if (this.hasUnsavedChanges) {
            //ISS-002744
            this.promptUnsavedChangesConfirmation('changesgp', event.detail.value);

        } else {
            this.doSgpChange(event.detail.value);
        }
    }

    doSgpChange(selectedSgp) {
        this.selectedSgp = selectedSgp;
        //Do we need the filter button? We can just retrigger here
        this.getGradingData();
    }

    /**
     * @descripton List of Student sort by options
     */
    get studentSortOptions() {
        return [
            {label: this.label.SORTING_NAME_ASCENDING, value: this.SORTING_NAME_ASCENDING_VALUE, iconName: (this.studentSortingInfo === this.SORTING_NAME_ASCENDING_VALUE ? 'utility:check' : '')},
            {label: this.label.SORTING_NAME_DESCENDING, value: this.SORTING_NAME_DESCENDING_VALUE, iconName: (this.studentSortingInfo === this.SORTING_NAME_DESCENDING_VALUE ? 'utility:check' : '')}
        ];
    }

    /**
     * @description Handle Student sort by selection onchange
     */
    handleSortByOnChange(event) {
        this.studentSortingInfo = event.detail.value;
        //We will try to sort the students client side without going back to apex
        
        if (this.studentSortingInfo) {
            let sortingInfo = this.studentSortingInfo.split("|");
            let sortingField = sortingInfo[0];
            let sortingOrder = sortingInfo[1];

            this.dataWrapper.studentWrappers = _.orderBy(this.studentWrappers, [sortingField], [sortingOrder]);
        }
    }

    /**
     * @description Handle Save button click 
     */
    handleSaveClick() {
        // Call apex's save method with the "Save" configured IGD status
        this.doSave(this.SAVE_BUTTON);
    }

    /**
     * @description Handle Save And Submit button click 
     */
    handleSaveAndSubmitClick() {
        // Call apex's save method with the "Save and Submit" configured IGD status
        this.doSave(this.SAVEANDSUBMIT_BUTTON);
    }

    /**
     * @description Handle grade entry update
     */
    handleGradeEntryUpdate(event) {
        const {gradeEntryInfo} = event.detail;

        if (this.hasDataWrapper && gradeEntryInfo){

            this.toggleSpinner(1);

            //Clone read-only object so we can update it
            let updatedStudentWrappers = JSON.parse(JSON.stringify(this.studentWrappers));
            //Map<Id, Map<Id, reduivy__Individual_Grade_Item__c>> Map of IEN Id to a Map SGI Id to IGI record
            let ienToSgiToIgiMap = new Map();
            //Map<Id, Map<String, Object> Map of IEN Id to a Map of IGD field to fieldValue
            let ienToIgdFieldToValueMap = new Map();

            this.consoleLog(gradeEntryInfo, true);
            if (gradeEntryInfo.hasUpdate){

                if (gradeEntryInfo.igi != null){
                    //handle IGI cell
                    let ienId = gradeEntryInfo.ien_sgi.split("_")[0];
                    let sgiId = gradeEntryInfo.ien_sgi.split("_")[1];

                    //Add IEN to the map
                    if (!ienToSgiToIgiMap.has(ienId)){
                        ienToSgiToIgiMap.set(ienId, new Map());
                    }
                    //Add SGI => IGI to map
                    ienToSgiToIgiMap.get(ienId).set(sgiId, gradeEntryInfo.igi);
                    
                } else if (gradeEntryInfo.igd != null){
                    //handle IGD cell
                    let ienId = gradeEntryInfo.ienId;
                    
                    //Add IEN to the map
                    if (!ienToIgdFieldToValueMap.has(ienId)){
                        ienToIgdFieldToValueMap.set(ienId, new Map());
                    }
                    //Add IGD field => fieldValue to map
                    ienToIgdFieldToValueMap.get(ienId).set(gradeEntryInfo.igdField, gradeEntryInfo.igd[gradeEntryInfo.igdField]);
                }

            }

            //Update studentWrappers
            let studentWrappersLength = updatedStudentWrappers.length;
            for (let sw = 0; sw < studentWrappersLength; sw++){
                //Update IGI
                if (ienToSgiToIgiMap.has(updatedStudentWrappers[sw].ien.Id)){
                    let ienId = updatedStudentWrappers[sw].ien.Id;
                    let gradeWrappersLength = updatedStudentWrappers[sw].gradeWrapperList.length;
                    for (let gw = 0; gw < gradeWrappersLength; gw++){
                        if (ienToSgiToIgiMap.get(ienId).has(updatedStudentWrappers[sw].gradeWrapperList[gw].sgiId)){
                            updatedStudentWrappers[sw].gradeWrapperList[gw].igi = ienToSgiToIgiMap.get(ienId).get(updatedStudentWrappers[sw].gradeWrapperList[gw].sgiId);
                        }
                    }
                }
                //Update IGD
                if (ienToIgdFieldToValueMap.has(updatedStudentWrappers[sw].ien.Id)){
                    let ienId = updatedStudentWrappers[sw].ien.Id;
                    //Loop through and populate each IGD field
                    for (let [fieldName, value] of  ienToIgdFieldToValueMap.get(ienId).entries()) {
                        updatedStudentWrappers[sw].igd[fieldName] = value;
                    }
                }
                
                this.consoleLog(updatedStudentWrappers[sw], true);
            }

            this.dataWrapper.studentWrappers = updatedStudentWrappers;

            this.toggleSpinner(-1);

            this.hasUnsavedChanges = true;
        }
    }

    doSave(source) {
        this.toggleSpinner(1);

        //Get IGD status
        let igdStatus;
        if (source === this.SAVE_BUTTON){
            igdStatus = this.saveButtonIgdStatus;
        } else if (source === this.SAVEANDSUBMIT_BUTTON){
            igdStatus = this.saveAndSubmitButtonIgdStatus;
        }

        //Call Apex to save records
        try {
            //ISS-002259 store IGI ids
            let igiIds = [];

            for (let sw of this.studentWrappers) {
                if (sw?.gradeWrapperList) {
                    for (let igiWrapper of sw.gradeWrapperList) {
                        if (igiWrapper?.igi?.Id) {
                            let igiIdObj = {recordId: igiWrapper.igi.Id}
                            igiIds.push(igiIdObj);
                        }
                    }
                }
            }

            ctrlSaveGradingData({
                studentWrappersString: JSON.stringify(this.studentWrappers),
                individualEnrollmentGradeFieldSet: this.individualEnrollmentGradeFieldSet,
                igdStatus: igdStatus,
                igdLockedStatus: this.saveAndSubmitButtonIgdStatus
            })
            .then(result => {
                this.toggleSpinner(-1);
                //Success message
                promptSuccess(this.label.SUCCESS_LABEL, this.label.YOUR_CHANGES_ARE_SAVED_LABEL);

                this.hasUnsavedChanges = false;

                //ISS-002259 refresh IGI data for modal
                if (igiIds.length > 0){
                    notifyRecordUpdateAvailable(igiIds);
                }

                //Update the student wrappers on the screen with any changes from Apex (e.g. Inserted Ids)
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
     * @description Handle Filter button click 
     */
    handleCloseClick() {
        if (this.hasUnsavedChanges) {
            //ISS-002744
            this.promptUnsavedChangesConfirmation('closegraderegistry');

        } else {
            //Discard changes and go back to the parent component - studentGrading
            this.doCloseRegistry();
        }
    }

    /**
     * @description ISS-002744 fire the close attendance registry event
     */
    doCloseRegistry() {
        this.dispatchEvent(new CustomEvent("close", {}));
    }

    /**
     * @description ISS-002744 Handle browser tab unload event to check for unsaved changes
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
     * @description ISS-002744 Prompt unsaved changes warning
     */
    promptUnsavedChangesConfirmation(sourceName, sourceData) {
        genericConfirmationModal.open({
            size: 'small',
            modalTitle: customLabels.UNSAVED_CHANGES_WARNING_TITLE_LABEL,
            confirmationText1: customLabels.UNSAVED_CHANGES_WARNING_TEXT_LABEL,
            showSubmitButton: true,
            submitButtonLabel: customLabels.UNSAVED_CHANGES_STAY_BUTTON_LABEL,
            showCancelButton: true,
            cancelButtonLabel: customLabels.UNSAVED_CHANGES_LEAVE_BUTTON_LABEL,
            eventSource: sourceName,
            eventData: sourceData,
            enableDebugMode: this.enableDebugMode
        }).then((result) => {
            
            if (result) {
                this.consoleLog('promptUnsavedChangesConfirmation.close');
                this.consoleLog(result, true);

                const {operation, eventSource, eventData} = result;

                if (operation === 'cancel') {
                    if (eventSource === 'closegraderegistry'){
                        this.doCloseRegistry();
                    } else if (eventSource === 'changesgp') {
                        this.doSgpChange(eventData);
                    }

                    this.hasUnsavedChanges = false;
                    
                } else if (operation === 'submit') {
                    if (eventSource === 'changesgp') {
                        //reset it back to the current value so that the picklist stays as it is
                        this.template.querySelector('[data-id="sgppicklist"]').value = this.selectedSgp;
                    }
                }
            }
        });
    }

    /**
     * @description Handle Student Search (after pressing the Enter key)
     */
    handleSearch(event) {
        // Filter shown students based on studentSearchKey
        // the value will be passed down to studentGradingRegistryEntry.js to show or hide the entry
        this.studentSearchKey = event.target.value;
        if (this.studentSearchKey){
            this.studentSearchKey = this.studentSearchKey.toLowerCase();
        }
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
        logInfo('StudentGradingRegistry', anything, this.enableDebugMode, isJson);
    }
	
}