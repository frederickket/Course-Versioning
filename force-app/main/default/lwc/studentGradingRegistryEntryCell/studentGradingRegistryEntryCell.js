/**
 * @Author 		WDCi (CM)
 * @Date 		Aug 2024
 * @group 		Grade Management
 * @Description Student Grading Wizard - Cell inside StudentGradingRegistry for either an IGI, or an IGD custom field
 * @changehistory
 * ISS-001918 19-08-2024 CM - new class
 * ISS-002230 22-01-2025 XW - display picklist value label if field type is picklist
 * ISS-002257 29-01-2025 Jordan - allow admin to lock/unlock a grading period setting and individual enrollment grade
 * ISS-002259 20-03-2025 Jordan - allow admin to configure more fields in the note screen
 */
import { LightningElement, api, track } from 'lwc';
import { logInfo } from 'c/loggingUtil';
import { customLabels } from 'c/labelLoader';
import { commonConstants } from 'c/lwcUtil';

import cellModal from 'c/studentGradingRegistryEditModal';

export default class StudentGradingRegistryEntryCell extends LightningElement {
	
	//configurable attributes
    @api userMode;
	@api studentWrapper;
    @api sgiRecord;
    @api studyGradingSchemeList; //For letter grade
    @api igiStatusList;
    @api isSgpLocked;
    @api lockedIgdStatus;
    @api cellType; //Either IGI or IGD
    @api customField; //REDU_DynamicFieldValue_OBJ
    @api gradeItemStatusColourMap;
    @api individualGradeItemNotesFieldSetName; //ISS-002259

    //ISS-002259
    @api
    set draftIgiObj(val) {
        this._draftIgiObj = JSON.parse(JSON.stringify(val));

        this.consoleLog('set _draftIgiObj');
        this.consoleLog(this._draftIgiObj, true);
    }

    //ISS-002259
    get draftIgiObj() {
        return this._draftIgiObj;
    }

	@api enableDebugMode = false;

	//internal attributes
	loadedLists = 0;
    newStatus;
    updatedStatus = false;
    newValue;
    updatedValue = false;
    newCustomFieldValue;
    updatedCustomFieldValue = false;
    hideCustomFieldLabel = true;
    updatedNotes = false;
    showNotesModal = false;

    @track _draftIgiObj; //ISS-002259

    //Constants
    IGI_TYPE = "reduivy__Individual_Grade_Item__c";
    IGD_TYPE = "reduivy__Individual_Enrollment_Grade__c";
    ADD_NOTES_BUTTON = "ADD_NOTES";
    LETTERGRADE_HIGHER_RANGE = "Higher Range";
    LETTERGRADE_LOWER_RANGE = "Lower Range";
    LOCKING_MODE_LOCKED = "Locked"; //ISS-002257
    LOCKING_MODE_UNLOCKED = "Unlocked"; //ISS-002257

	//labels
	label = customLabels;
	
	//js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'tooltips'
    modules = [];
	
	
    /**
     * @descripton rendered callback
     */
	renderedCallback(){

    }

    /**
     * @descripton connected callback
     */
    connectedCallback(){
        //Create editable version of the custom field
        if (this.customField != null){
            this.newCustomFieldValue = JSON.parse(JSON.stringify(this.customField));
        }

        //ISS-002259
        if (this.igiRecord != null) {
            this._draftIgiObj = JSON.parse(JSON.stringify(this.igiRecord));
        } else {
            this._draftIgiObj = {};
        }

        this.updateCssVars();
	}
	
    /**
     * @descripton disconnected callback
     */
	disconnectedCallback() {
		
	}

    /**
     * @descripton Returns true if this is an Individual Grade Item field
     */
    get isIgiType(){
        return this.cellType === this.IGI_TYPE;
    }
    
    /**
     * @descripton Returns true if this is an Individual Enrollment Grade field
     */
    get isIgdType(){
        return this.cellType === this.IGD_TYPE;
    }

    /**
     * @descripton Display type (Numerical Grade or Letter Grade)
     */
	get sgiDisplayType(){
        if (this.sgiRecord){
            return this.sgiRecord.reduivy__Display_Type__c;
        }
        return null;
        
    }

    /**
     * @descripton Returns true if this is a Numerical Grade study grade item
     */
	get isNumericalDisplayType(){
        return this.sgiDisplayType === "Numerical Grade";
    }

    /**
     * @descripton Returns true if this is a Letter Grade study grade item
     */
	get isLetterDisplayType(){
        return this.sgiDisplayType === "Letter Grade";
    }

    /**
     * @descripton Returns true if a status is selected
     */
	get showStatus(){
        return ((!this.updatedStatus && this.igiOriginalStatus) || (this.updatedStatus && this.newStatus));
    }

    /**
     * @descripton Displays the correct status
     */
    get displayedStatus(){
        if ((!this.updatedStatus && this.igiOriginalStatus)){
            let igiStatus = this.igiStatusList.find(igi => igi.value === this.igiOriginalStatus);
            if(igiStatus) {
                return igiStatus.label;
            }
            return this.igiOriginalStatus;
        } else if ((this.updatedStatus && this.newStatus)){
            let igiStatus = this.igiStatusList.find(igi => igi.value === this.newStatus);
            if(igiStatus) {
                return igiStatus.label;
            }
            return this.newStatus;
        }

        return null;
    }
    
    /**
     * @descripton Returns Letter options for the Letter Grade picklist
     */
	get letterOptions(){
        let options = [];
        if (this.studyGradingSchemeList != null){
            let sgsListLength = this.studyGradingSchemeList.length;
            for (let i = 0; i < sgsListLength; i++){
                //Make sure Study Grade Setting matches the one in IEN
                if (this.studyGradingSchemeList[i].reduivy__Study_Grade_Setting__c === this.studentWrapper.ien.reduivy__Study_Grade_Setting__c){
                    options.push({label: this.studyGradingSchemeList[i].reduivy__Letter_Grade__c, value: this.studyGradingSchemeList[i].reduivy__Letter_Grade__c});
                }
            }
        }
        return options;
    }

    /**
     * @descripton Finds the relevant individual grade item
     */
    get igiRecord(){
        if (this.studentWrapper && this.studentWrapper.gradeWrapperList && this.sgiRecord){
            //Loop through individual grade items to find the one linked to the study grade item
            let gradeWrapperLength = this.studentWrapper.gradeWrapperList.length;
            for (let i = 0; i < gradeWrapperLength; i++){
                if (this.studentWrapper.gradeWrapperList[i].igi.reduivy__Study_Grade_Item__c === this.sgiRecord.Id){
                    return this.studentWrapper.gradeWrapperList[i].igi;
                }
            }
        }
        return null;
    }

    /**
     * @descripton Get the (original) grade for this individual grade item
     */
	get igiOriginalValue(){
        if (this.igiRecord){
            //Number
            if (this.isNumericalDisplayType){
                return this.igiRecord.reduivy__Numerical_Grade__c;
            //Letter
            } else if (this.isLetterDisplayType){
                return this.igiRecord.reduivy__Letter_Grade__c;
            }
        }
        return null;
    }

    /**
     * @descripton Get the (original) status for this individual grade item
     */
	get igiOriginalStatus(){
        if (this.igiRecord){
            return this.igiRecord.reduivy__Status__c;
        }
        return null;
    }

    /**
     * @descripton Disabled grade input fields when Study Grade Period Setting is out of date, or Individual Enrollment Grades have been submitted
     */
    get isGradeLocked(){
        if (this.userMode === commonConstants.USER_MODE_ADMIN) {
            return false;
        }

        //ISS-002257
        if (this.isSgpLocked && this.studentWrapper.igd.reduivy__Locking_Mode_Override__c === this.LOCKING_MODE_UNLOCKED) {
            return false;
        }

        //ISS-002257
        if (!this.isSgpLocked && this.studentWrapper.igd.reduivy__Locking_Mode_Override__c === this.LOCKING_MODE_LOCKED) {
            return true;
        }
        
        return this.isSgpLocked || this.studentWrapper.igd.reduivy__Status__c === this.lockedIgdStatus;
    }

    /**
     * @descripton Get background colour based on selected status
     */
    get backgroundColourStyle(){
        if (this.showStatus && this.gradeItemStatusColourMap && this.gradeItemStatusColourMap[this.displayedStatus]){
            //Add padding so it stretchs to cover the full cell
            return this.gradeItemStatusColourMap[this.displayedStatus];
        }
        return null;
    }
    
    /**
     * @description Update css var
     */
    updateCssVars() {
        let css = this.template.host.style;
        css.setProperty('--cell-background-color', this.backgroundColourStyle);
    }

    /**
     * @descripton Handles updating a letter value
     */
    handleLetterValueChange(event){
        this.newValue = event.detail.value;
        this.updatedValue = true;

        this.sendChangesToParent();
    }

    /**
     * @descripton Handles updating a numerical value
     */
    handleNumericalValueChange(event){
        this.newValue = event.detail.value;
        this.updatedValue = true;

        this.sendChangesToParent();
    }

    /**
     * @descripton Handles selection of a button menu item (Setting status or Add Notes modal)
     */
    handleGradeMenuSelect(event){
        //Adding Notes
        if (event.detail.value === this.ADD_NOTES_BUTTON){
            this.openAddNotesModal();
        //Status
        } else {
            //Set Status for the IGI
            this.newStatus = event.detail?.value;
            this.updatedStatus = true;

            this.updateCssVars();
            this.sendChangesToParent();
        }
    }

    /**
     * @descripton Opens the Add Notes modal
     */
    openAddNotesModal(){
        
        cellModal.open({
            size: "small",
            modalTitle: this.label.ADD_NOTES_LABEL,
            draftIgiObj: this.draftIgiObj, //ISS-002259
            individualGradeItemNotesFieldSetName: this.individualGradeItemNotesFieldSetName, //ISS-002259
            enableDebugMode: this.enableDebugMode,
        }).then((result) => {
            
            if (result) {
                this.consoleLog("cellModal.close");
                this.consoleLog(result, true);

                const {operation, updatedNotes, draftIgiObj} = result;

                if (operation === "done") {
                    this.updatedNotes = updatedNotes;
                    this._draftIgiObj = JSON.parse(JSON.stringify(draftIgiObj)); //ISS-002259

                    this.sendChangesToParent();
                }
            }
        });
        
    }

    handleIgdValueChange(event){
        this.newCustomFieldValue = event.detail.sobjRecord;
        this.updatedCustomFieldValue = true;

        this.sendChangesToParent();
    }

    /**
     * @descripton Sends changes to the parent component (studentGradingRegistryEntry)
     */
    sendChangesToParent(){

        let returnObj = {
            hasUpdate: false
        };
        //Return updated Individual Grade Item value
        if (this.isIgiType){
            //Clone read-only object so we can update it
            let returnIgi = JSON.parse(JSON.stringify(this.igiRecord));
            //Update Grade value
            if (this.updatedValue){
                returnObj.hasUpdate = true;
                let matchingStudyGradeScheme = this.getStudyGradingSchemeRecord(this.newValue);
                if (this.isNumericalDisplayType){
                    returnIgi.reduivy__Numerical_Grade__c = this.newValue;
                    //Also set letter grade based on the Grading Scheme
                    if (matchingStudyGradeScheme != null){
                        returnIgi.reduivy__Letter_Grade__c = matchingStudyGradeScheme.reduivy__Letter_Grade__c;
                    } else {
                        returnIgi.reduivy__Letter_Grade__c = null;
                    }
                } else if (this.isLetterDisplayType){
                    returnIgi.reduivy__Letter_Grade__c = this.newValue;
                    //Also set numerical grade based on the Grading Scheme
                    let foundNumericalValue = false;
                    if (matchingStudyGradeScheme != null){
                        if (matchingStudyGradeScheme.reduivy__Letter_Grade_Scoring_Range__c === this.LETTERGRADE_HIGHER_RANGE){
                            returnIgi.reduivy__Numerical_Grade__c = matchingStudyGradeScheme.reduivy__Numerical_Grade_Higher_Range__c;
                            foundNumericalValue = true;
                        } else if (matchingStudyGradeScheme.reduivy__Letter_Grade_Scoring_Range__c === this.LETTERGRADE_LOWER_RANGE){
                            returnIgi.reduivy__Numerical_Grade__c = matchingStudyGradeScheme.reduivy__Numerical_Grade_Lower_Range__c;
                            foundNumericalValue = true;
                        }
                    }
                    //Reset numerical value if Letter grade is cleared (or value not found)
                    if (!foundNumericalValue){
                        returnIgi.reduivy__Numerical_Grade__c = null;
                    }
                }
            }
            //Update Status
            if (this.updatedStatus){
                returnObj.hasUpdate = true;
                returnIgi.reduivy__Status__c = this.newStatus;
            }
            //Update Notes
            if (this.updatedNotes){
                returnObj.hasUpdate = true;

                //ISS-002259 update all notes fields
                for (let fieldName of Object.keys(this._draftIgiObj)) {
                    returnIgi[fieldName] = this._draftIgiObj[fieldName];
                }
            }
            //We need to send an identifiable string in case no IGI id exists
            let ien_sgi = this.studentWrapper.ien.Id + "_" + this.sgiRecord.Id;
            
            returnObj.ien_sgi = ien_sgi;
            returnObj.igi = returnIgi;
        //Return updated Individual Grade Item value
        } else if (this.isIgdType){

            //Updated custom field
            if (this.updatedCustomFieldValue){
                returnObj.hasUpdate = true;
            }
            //We need to send an identifiable string in case no IGD id exists
            let ienId = this.studentWrapper.ien.Id;
            returnObj.ienId = ienId;
            returnObj.igd = this.newCustomFieldValue;
            returnObj.igdField = this.customField.fieldName;
            
        }

        this.dispatchEvent(new CustomEvent("gradeentrycellupdate", {
            detail: {
                gradeEntryInfo: returnObj
            }
        }));
    }

    getStudyGradingSchemeRecord(value){
        let sgsListLength = this.studyGradingSchemeList.length;
        for (let i = 0; i < sgsListLength; i++){
            //Make sure Study Grade Setting matches the one in IEN
            if (this.studyGradingSchemeList[i].reduivy__Study_Grade_Setting__c === this.studentWrapper.ien.reduivy__Study_Grade_Setting__c
            && ((this.isLetterDisplayType && value === this.studyGradingSchemeList[i].reduivy__Letter_Grade__c)
            || (this.isNumericalDisplayType && value >= this.studyGradingSchemeList[i].reduivy__Numerical_Grade_Lower_Range__c && value <= this.studyGradingSchemeList[i].reduivy__Numerical_Grade_Higher_Range__c))){
                return this.studyGradingSchemeList[i];
            }
        }
        return null;
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
        logInfo('StudentGradingRegistryEntryCell', anything, this.enableDebugMode, isJson);
    }
	
}