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

import studentAttendanceRegistryEditModal from 'c/studentAttendanceRegistryEditModal';

export default class StudentAttendanceRegistryEntry extends LightningElement {
	
	//configurable attributes
    @api attendanceStatusOptions;
    @api serObj;
    @api
    set draftSerObj(val) {
        this._draftSerObj = JSON.parse(JSON.stringify(val));
        this.selectedAttendanceStatus = this._draftSerObj?.reduivy__Attendance_Status__c;

        this.consoleLog('set _draftSerObj');
        this.consoleLog(this._draftSerObj, true);
    }

    get draftSerObj() {
        return this._draftSerObj;
    }

    @api studyEventRelationEditFieldSetName;
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

    @track selectedAttendanceStatus;
    @track _draftSerObj;

	//labels
	label = customLabels;
	
	//js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'tooltips'
    modules = [];
	
	/**
     * @descripton library loader
     */
    handleLibLoadSuccess(event) {
        this.isScriptLoaded = true;
        this.isInitSuccess = true;
        
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
		
	}
	
    /**
     * @descripton disconnected callback
     */
	disconnectedCallback() {
		
	}

    /**
     * @description Return the unique key for the radio button
     */
    get entryKey() {
        return this.serObj.reduivy__Individual_Session_Enrollment__c;
    }

    /**
     * @description Return contact id
     */
    get contactId() {
        return this.serObj?.reduivy__Contact__c;
    }

    /**
     * @description Return individual session enrollment id
     */
    get individualSessionEnrollmentId() {
        return this.serObj?.reduivy__Individual_Session_Enrollment__c;
    }

    /**
     * @description handle attendance status change
     */
    handleAttendanceRecordChange(event) {
        // this.selectedAttendanceStatus = event.detail.value;
        this._draftSerObj.reduivy__Attendance_Status__c = event.detail.value;

        this.dispatchEvent(new CustomEvent("attendancerecordchange", {
            detail: {
                serObj: this.serObj,
                draftSerObj: this.draftSerObj
            }
        }));
    }

    /**
     * @description Handle menu item selection
     */
    handleMenuSelect(event) {
        const selectedItemValue = event.detail.value;

        if (selectedItemValue === "addnotes") {
            this.doAddNotes();
        } else if (selectedItemValue === "undo") {
            this.doUndo();
        }
    }

    /**
     * @description Launch add notes modal
     */
    doAddNotes() {

        studentAttendanceRegistryEditModal.open({
            size: 'small',
            modalTitle: customLabels.ADD_NOTES_LABEL,
            draftSerObj: this.draftSerObj,
            studyEventRelationEditFieldSetName: this.studyEventRelationEditFieldSetName,
            enableDebugMode: this.enableDebugMode
        }).then((result) => {

            if (result) {
                this.consoleLog('studentAttendanceRegistryEditModal.close');
                this.consoleLog(result, true);

                const {operation, draftSerObj} = result;

                if (operation === 'submit') {
                    this._draftSerObj = JSON.parse(JSON.stringify(draftSerObj));

                    this.dispatchEvent(new CustomEvent("attendancerecordchange", {
                        detail: {
                            serObj: this.serObj,
                            draftSerObj: this.draftSerObj
                        }
                    }));
                }
            }
        });
    }

    /**
     * @description Undo data for all fields back to original state 
     */
	doUndo() {
        this._draftSerObj = JSON.parse(JSON.stringify(this.serObj));

        this.dispatchEvent(new CustomEvent("attendancerecordchange", {
            detail: {
                serObj: this.serObj,
                draftSerObj: this.draftSerObj
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
        logInfo('StudentAttendanceRegistryEntry', anything, this.enableDebugMode, isJson);
    }
	
}