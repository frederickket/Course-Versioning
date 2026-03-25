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

export default class StudentAttendance extends LightningElement {
	
	//configurable attributes
    @api recordId;
    @api userMode = 'Admin';
    @api modalTitle;
    @api modalIconName = 'standard:product_required';

    //configurable attributes for studyAttendanceListing
    @api attendanceTileIcon = 'standard:product_required';
    @api attendanceButtonLabel = 'Attendance';
    @api sevTileInfoFields = 'Name;reduivy__Start__c;reduivy__End__c;reduivy__Status__c';
    @api studyEventTileClickAction = 'View Info'; //support View Info and View Record
    @api showNoAttendanceWarning = false;
    @api noAttendanceWarningText = 'No attendance marked.';
    @api noAttendanceWarningIcon = 'utility:warning';
    @api noAttendanceWarningIconVariant = 'warning';
    @api infoModalFieldsForStudyEvent = 'Name;reduivy__Start__c;reduivy__End__c';
    @api infoModalSectionNameForStudyEvent = 'Study Event';
    @api validFacultyIsnStatus = 'Enrolled';

    //configurable attributes for studentAttendanceRegistry
    @api attendanceStatuses = 'Attended;Absent;Late';
    @api studyEventRelationEditFieldSetName = 'reduivy__AttendanceWizard_Notes';
    @api contactTileInfoFields = 'FirstName;LastName;Email';
    @api contactImageFileName = 'Profile';
    @api contactImageUrlFieldName;
    @api contactTileClickAction = 'View Info'; //support View Info and View Record
    @api infoModalFieldsForContact = 'FirstName;LastName;Email';
    @api infoModalSectionNameForContact = 'Contact';
    @api infoModalFieldsForIndividualSessionEnrollment = 'Name;reduivy__Enrollment_Status__c';
    @api infoModalSectionNameForIndividualSessionEnrollment = 'Individual Session Enrollment';
    @api showRecordsBasedOnAllocation = false;

	@api enableDebugMode = false;
	
	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false
	loadedLists = 0;

    sevObj;
    showAttendanceRegistry = false;

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
        
	}
	
    /**
     * @descripton disconnected callback
     */
	disconnectedCallback() {
		
	}

    /**
     * @description Return css class
     */
    get studentAttendanceListingClasses() {
        if (this.showAttendanceRegistry) {
            return 'studentattendancelisting-holder slds-hide';
        }

        return 'studentattendancelisting-holder';
    }

    /**
     * @description Return css class
     */
    get studentAttendanceRegistryClasses() {
        if (this.showAttendanceRegistry) {
            return 'studentattendanceregistry-holder';
        }

        return 'studentattendanceregistry-holder slds-hide';
    }

    /**
     * @description Return the selected study event id
     */
    get selectedStudyEventId() {
        return this.sevObj?.Id;
    }

    /**
     * @description Handle view attendance registry button click from child
     */
    handleViewAttendanceRegistry(event) {
        this.sevObj = event.detail.sevObj;
        this.showAttendanceRegistry = true;
    }

    /**
     * @description Handle view attendance registry button click from child
     */
    handleCloseAttendanceRegistry(event) {
        
        this.sevObj = null;
        this.showAttendanceRegistry = false;
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
        logInfo('StudentAttendance', anything, this.enableDebugMode, isJson);
    }
	
}