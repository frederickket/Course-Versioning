/**
 * @Author 		WDCi (CM)
 * @Date 		Aug 2024
 * @group 		Grade Management
 * @Description Student Grading Wizard
 * @changehistory
 * ISS-001918 01-08-2024 CM - new class
 * ISS-002259 20-03-2025 Jordan - allow admin to configure more fields in the note screen
 * ISS-002650 10-11-2025 XW - replace refreshHandler to refreshContainer
 */
import { LightningElement, api } from 'lwc';
import { promptError } from 'c/toasterUtil';
import { getErrorMessage, logInfo } from 'c/loggingUtil';
import { customLabels } from 'c/labelLoader';

import TIME_ZONE from '@salesforce/i18n/timeZone';

//refresh module
import { refreshApex } from '@salesforce/apex';
import { registerRefreshContainer, unregisterRefreshContainer } from 'lightning/refresh';

//Apex methods
import ctrlGetListings from '@salesforce/apex/REDU_StudentGrading_LCTRL.getListings';

//additional labels
import NO_RECORD_LABEL from '@salesforce/label/c.No_Records_To_Display';
import GO_TO_LABEL from '@salesforce/label/c.Go_to';

export default class StudentGrading extends LightningElement {
	
    //Automatically set
    @api recordId; //Can be automatically set via record page
    @api objectApiName; //Can be automatically set via record page

	//configurable attributes
    @api modalTitle;
    @api modalIconName;
    @api userMode = 'Admin';
    @api contactId; //Faculty user contact Id for searching listings
    @api listingIconName;
    @api showNoGradeWarning = false;
    @api noGradeWarningText;
    @api noGradeWarningIcon;
    @api noGradeWarningIconVariant;
    @api validStudentIenStatus;
    @api validStudentIsnStatus;
    @api validFacultyIenStatus;
    @api validFacultyIsnStatus;
    @api sofListingNameField;
    @api sofListingInfoFields;
    @api sseListingNameField;
    @api sseListingInfoFields;
    @api individualEnrollmentGradeFieldSet;
    @api individualGradeItemNotesFieldSetName; //ISS-002259
    
    @api contactTileInfoFields;
    @api contactImageFileName;
    @api contactImageUrlFieldName;
    @api contactTileClickAction;
    @api infoModalFieldsForContact;
    @api infoModalSectionNameForContact;

    showCloseButton = true;
    @api showSaveButton = false;
    @api showSaveAndSubmitButton = false;
    @api saveButtonIgdStatus;
    @api saveAndSubmitButtonIgdStatus;
    @api showRecordsBasedOnAllocation = false;

    @api enableDebugMode = false;
    
	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false
	loadedLists = 0;
    hasDoneGetListings = false;

    selectedRecordId;
    selectedObjectApiName;

    //for date picker
    selectedDate;
	
    //refresh handler
    refreshContainerID;

    //wire attribute
    listingsResponse;

	//labels
	label = {
        ...customLabels,
        NO_RECORD_LABEL,
        GO_TO_LABEL
    };
	
	//js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'tooltips'
    modules = ['moment'];
	
	/**
     * @descripton library loader
     */
    handleLibLoadSuccess() {
        this.isScriptLoaded = true;
        this.isInitSuccess = true;
        
        //default to today
        let currentDate = moment.tz((new Date()).toISOString(), this.timezone);
        this.selectedDate = currentDate.format('yyyy-MM-DD'); //the input field only accept string

        //If placed on a record page, immediately load the currrent record
        if (this.recordId != null && this.objectApiName != null){
            this.showCloseButton = false;
            this.selectedObjectApiName = this.objectApiName;
            this.selectedRecordId = this.recordId;
        } else {
            //Otherwise, get a list of records
            this.getListings();
        }
        

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
		this.refreshContainerID = registerRefreshContainer(this, this.refreshData);
	}
	
    /**
     * @descripton disconnected callback
     */
	disconnectedCallback() {
		unregisterRefreshContainer(this.refreshContainerID);
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
     * @description Return true to show modal title and icon
     */
    get showModalHeader(){
        if(this.modalTitle){
            return true;
        }
        return false;
    }

    /**
     * @description Return timezone
     */
    get timezone() {
        return TIME_ZONE;
    }

    /**
     * @descripton Get list of Study Sessions and Study Offerings to grade
     */
    getListings() {
        this.toggleSpinner(1);

        try {

            ctrlGetListings({
                contactId: this.contactId,
                filterDate: this.selectedDate,
                showNoGradeWarning: this.showNoGradeWarning,
                validStudentIenStatus: this.validStudentIenStatus,
                validStudentIsnStatus: this.validStudentIsnStatus,
                validFacultyIenStatus: this.validFacultyIenStatus,
                validFacultyIsnStatus: this.validFacultyIsnStatus,
                sofListingNameField: this.sofListingNameField,
                sofListingInfoFields: this.sofListingInfoFields,
                sseListingNameField: this.sseListingNameField,
                sseListingInfoFields: this.sseListingInfoFields,
                showRecordsBasedOnAllocation: this.showRecordsBasedOnAllocation
            })
            .then(result => {
                this.toggleSpinner(-1);
                this.listingsResponse = JSON.parse(result.responseData);
                this.hasDoneGetListings = true;

                this.consoleLog('getListings');
                this.consoleLog(this.listingsResponse, true);

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
     * @descripton Returns true if a record has been selected
     */
    get showRecordForGrading() {
        return this.selectedRecordId != null;
    }

    /**
     * @descripton List of Study Sessions and Study Offerings for use in .html
     */
    get listings() {
        if (this.listingsResponse) {
            return this.listingsResponse;
        }

        return [];
    }

    get hasListings() {
        return this.listings && this.listings.length > 0;
    }

    /**
     * @description Handle date field onchange
     */
    handleDateFieldOnchange(event) {
        this.selectedDate = event.detail.value;
        this.getListings();
    }

    //Placeholder, replace with a regular method from the recordTile
    handleListingClick(event){
        this.selectedObjectApiName = event.currentTarget.dataset.objectapiname;
        this.selectedRecordId = event.currentTarget.dataset.id;
    }

    /**
     * @description Handle closing and discarding changes from studentGradingRegistry
     */
    handleClose(){
        this.clearSelectedRecord();
        //If we're on a record page, we haven't gotten listings yet
        if (!this.hasDoneGetListings){
            this.getListings();
        }
    }
	
    /**
     * @description Clear selected record details
     */
    clearSelectedRecord(){
        this.selectedRecordId = null;
        this.selectedObjectApiName = null;
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
        logInfo('StudentGrading', anything, this.enableDebugMode, isJson);
    }
	
}