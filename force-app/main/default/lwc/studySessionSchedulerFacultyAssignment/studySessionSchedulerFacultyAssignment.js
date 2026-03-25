/**
 * @Author 		WDCi (XW)
 * @Date 		Jan 2024
 * @group 		Study Session Scheduler
 * @Description 
 * @changehistory
 * ISS-001920 05-08-2024 XW - create new class
 */
import { LightningElement, api, wire } from 'lwc';
import { promptError, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo } from 'c/loggingUtil';
import { getObjectInfo, getPicklistValues } from "lightning/uiObjectInfoApi";
import { notifyRecordUpdateAvailable } from "lightning/uiRecordApi";
import { sessionSchedulerLabels } from 'c/studySessionSchedulerHelper';
import { RefreshEvent } from "lightning/refresh";

import RESPONSE_STATUS_FIELD from '@salesforce/schema/Study_Event_Relation__c.Response_Status__c';
import FACULTY_ROLE_FIELD from '@salesforce/schema/Qualified_Faculty__c.Faculty_Role__c';

import STUDY_EVENT_RELATION_OBJ from '@salesforce/schema/Study_Event_Relation__c';
import QUALIFIED_FACULTY_OBJ from '@salesforce/schema/Qualified_Faculty__c';
import STUDY_SESSION_TIME_OBJ from '@salesforce/schema/Study_Session_Time__c';
import STUDY_SESSION_OBJ from '@salesforce/schema/Study_Session__c';
import INDIVIDUAL_SESSION_ENROLLMENT_OBJ from '@salesforce/schema/Individual_Session_Enrollment__c';
import STUDY_UNIT_OBJ from '@salesforce/schema/Study_Unit__c';

import ctrlGetStudySessionTimes from '@salesforce/apex/REDU_SessionScheduler_LCTRL.getStudySessionTimes';
import ctrlGetAllQualifiedFaculty from '@salesforce/apex/REDU_SessionFacultyAssignment_LCTRL.getAllQualifiedFaculty';
import ctrlAssignNewFaculty from '@salesforce/apex/REDU_SessionFacultyAssignment_LCTRL.assignNewFaculty';

import FILTER_BY_FACULTY_ROLES_LABEL from '@salesforce/label/c.Filter_by_Faculty_Roles';
import QUALIFIED_ROLES_LABEL from '@salesforce/label/c.Qualified_Roles';
import MAKE_PRIMARY_FOR_STUDY_SESSION_LABEL from '@salesforce/label/c.Make_Primary_for_Study_Session';
import MAKE_PRIMARY_FOR_STUDY_OFFERING_LABEL from '@salesforce/label/c.Make_Primary_for_Study_Offering';
import ASSIGN_NEW_FACULTY_LABEL from '@salesforce/label/c.Assign_New_Faculty';
import NOT_QUALIFIED_STUDY_UNIT_LABEL from '@salesforce/label/c.Not_Qualified_Study_Unit';
import NOT_QUALIFIED_ROLES_LABEL from '@salesforce/label/c.Not_Qualified_Role';


export default class StudySessionSchedulerFacultyAssignment extends LightningElement {
	
	//configurable attributes
    @api modalTitle;
    @api modalIconName = 'custom:custom47';
	@api enableDebugMode = false;

    @api recordId;
    @api objectApiName;
    @api showHeader = false;
    
	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false
	loadedLists = 0;
    filterAllRoles = true; //true = show faculty if all role match (NOT ANY ROLE)
    
    label = sessionSchedulerLabels;
	
	//js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'jquery'
    modules = ['stringutil'];

    //show message
    facultyIsQualifiedFaculty = true;
    facultyIsQualifiedRole = true;
    unqualifiedRoleLabel;

    //study unit attributes
    studyUnitLabel;

    //qualified faculty attributes
    qualifiedFacultyResult;
    qualifiedFacultyStudyUnit;
    allQualifiedFacultyList = [];
    allQualifiedFacultyContactIdList = [];

    //faculty attributes
    recordPickerFacultyValue;

    //study session time value
    studySessionTimeLabel;
    studySessionTimeValue = this.label.PICKLIST_OPTION_NONE_LABEL;
    studySessionTimeIdList = [];
    studySessionTimeOptions = [];
    selectedStudySessionTimeIds = new Set();

    //study event relation response status
    responseStatusValue;
    sevRecordTypeId;
    responseStatusOptions;

    //object info data attributes
    serObjectInfoData;
    isnObjectInfoData;
    qfaObjectInfoData;
    
    //start date attributes
    startDateValue;
    
    //end date attributes
    endDateValue;
    
    //faculty roles to filter attributes
    qfaRecordTypeId;
    facultyRolesValue = [];
    facultyRolesOptions = [];
    facultyRolesApiToLabelMap = {};

    //primary faculty
    makePrimaryStudySessionValue = false;
    makePrimaryStudyOfferingValue = false;
    
    /**
    * @description get study event object info to get default record type id
    */
    @wire(getObjectInfo, { objectApiName: STUDY_EVENT_RELATION_OBJ })
    getSevObjectInfoWire({ error, data }) {
        if (data) {
            this.serObjectInfoData = data;
            this.sevRecordTypeId = data.defaultRecordTypeId;
        } else if (error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
        }
    }

    /**
    * @description get qualified faculty obj info to get default record type id
    */
    @wire(getObjectInfo, { objectApiName: QUALIFIED_FACULTY_OBJ })
    getQfaObjectInfoWire({ error, data }) {
        if (data) {
            this.qfaObjectInfoData = data;
            this.qfaRecordTypeId = data.defaultRecordTypeId;
        } else if (error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
        }
    }

    /**
    * @description get study session time object info to get label
    */
    @wire(getObjectInfo, { objectApiName: STUDY_SESSION_TIME_OBJ })
    getSstObjectInfoWire({ error, data }) {
        if (data) {
            this.studySessionTimeLabel = data.label;
        } else if (error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
        }
    }
    
    /**
    * @description get study session time object info to get label
    */
    @wire(getObjectInfo, { objectApiName: STUDY_SESSION_OBJ })
    getSseObjectInfoWire({ error, data }) {
        if (data) {
            this.sseObjectInfoData = data;
        } else if (error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
        }
    }

    /**
    * @description get study unit object info to get label
    */
    @wire(getObjectInfo, { objectApiName: STUDY_UNIT_OBJ })
    getSunObjectInfoWire({ error, data }) {
        if (data) {
            this.studyUnitLabel = data.label;
        } else if (error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
        }
    }

    /**
    * @description get isn object info to get start date and label
    */
    @wire(getObjectInfo, { objectApiName: INDIVIDUAL_SESSION_ENROLLMENT_OBJ })
    getIsnObjectInfoWire({ error, data }) {
        if (data) {
            this.isnObjectInfoData = data;
        } else if (error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
        }
    }

    /**
    * @description get response status picklist values
    */
    @wire(getPicklistValues, { recordTypeId: "$sevRecordTypeId", fieldApiName: RESPONSE_STATUS_FIELD})
    getResponseStatusPicklistValues({data, error}){
        if(data){
            this.responseStatusOptions = data.values;
            this.responseStatusValue = data.defaultValue.value;
        } else if(error){
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
        }
    }
    
    /**
    * @description get faculty role picklist values
    */
    @wire(getPicklistValues, { recordTypeId: "$qfaRecordTypeId", fieldApiName: FACULTY_ROLE_FIELD})
    getFacultyRolePicklistValues({data, error}){
        if(data){
            this.facultyRolesOptions = data.values;

            for(let fr of this.facultyRolesOptions){
                this.facultyRolesApiToLabelMap[fr.value] = fr.label;
            }

        } else if(error){
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
        }
    }    
    

    /**
    * @description Label of assign new faculty
    */
    get assignNewFacultyLabel(){
        return ASSIGN_NEW_FACULTY_LABEL;
    }

    /**
    * @description Label of select
    */
    get selectButtonLabel(){
        return this.label.SELECT_LABEL;
    }

    /**
    * @description Label of Unselect
    */
    get unselectButtonLabel(){
        return this.label.UNSELECT_LABEL;
    }

    /**
    * @description True if message box should be shown
    */
    get showingMessageBox(){
        return this.recordPickerFacultyValue && (!this.facultyIsQualifiedFaculty || !this.facultyIsQualifiedRole);
    }

    /**
    * @description Label of Filter by Faculty Roles
    */
    get filterByFacultyRolesLabel(){
        return FILTER_BY_FACULTY_ROLES_LABEL;
    }

    /**
    * @description Label of QUalified Faculty
    */
    get qualifiedFacultyLabel(){
        if(this.qfaObjectInfoData){
            return this.qfaObjectInfoData.label;
        }
        return null;
    }

    /**
    * @description Label of Qualified Roles
    */
    get qualifiedRolesLabel(){
        return QUALIFIED_ROLES_LABEL;
    }

    /**
    * @description Label of Faculty
    */
    get recordPickerFacultyLabel(){
        return this.label.FACULTY_LABEL;
    }

    /**
    * @description Label of Start Date
    */
    get startDateLabel(){
        if(this.isnObjectInfoData) {
            return this.isnObjectInfoData.fields.reduivy__Start_Date__c.label;
        }
        return null;
    }

    /**
    * @description Label of End Date
    */
    get endDateLabel(){
        if(this.isnObjectInfoData) {
            return this.isnObjectInfoData.fields.reduivy__End_Date__c.label;
        }
        return null;
    }

    /**
    * @description Label of Response Status
    */
    get statusLabel(){
        if(this.serObjectInfoData){
            return this.serObjectInfoData.fields.reduivy__Response_Status__c.label;
        }
        return null;
    }

    /**
    * @description Label of Faculty Roles
    */
    get facultyRolesLabel(){
        if(this.qfaObjectInfoData){
            return this.qfaObjectInfoData.fields.reduivy__Faculty_Role__c.label;
        }
        return null;
    }

    /**
    * @description Label of Primary Faculty
    */
    get primaryFacultyLabel(){
        if(this.sseObjectInfoData){
            return this.sseObjectInfoData.fields.reduivy__Primary_Faculty__c.label;
        }
        return null;
    }
    
    /**
    * @description Label of make primary for study offset
    */
    get makePrimaryForStudyOfferingLabel(){
        return MAKE_PRIMARY_FOR_STUDY_OFFERING_LABEL;
    }

    /**
    * @description Label of make primary for study session
    */
    get makePrimaryForStudySessionLabel(){
        return MAKE_PRIMARY_FOR_STUDY_SESSION_LABEL;
    }

    /**
    * @description Title of the modal
    */
    get modalTitleLabel() {
        return this.modalTitle ? this.modalTitle : this.assignNewFacultyLabel
    }


    get recordPickerFacultyFilter() {
        return {
            criteria: [
                {
                    fieldPath: 'reduivy__Contact_Type__c',
                    operator: 'eq',
                    value: 'Faculty'
                },
                {
                    fieldPath: 'reduivy__Active__c',
                    operator: 'eq',
                    value: true
                }
            ]
        }
    }

    /**
    * @description The message of the message box
    */
    get messageBoxMessage() {
        if(!this.recordPickerFacultyValue){
            return null;
        }
        if(!this.facultyIsQualifiedFaculty) {
            return NOT_QUALIFIED_STUDY_UNIT_LABEL.format([this.label.FACULTY_LABEL, this.studyUnitLabel]);
        } else if (!this.facultyIsQualifiedRole) {
            return NOT_QUALIFIED_ROLES_LABEL.format([this.label.FACULTY_LABEL, this.unqualifiedRoleLabel]);
        }
        
        return null;
    }

    /**
    * @description The title of the message box
    */
    get messageBoxTitle() {
        if(!this.recordPickerFacultyValue){
            return null;
        }
        if(!this.facultyIsQualifiedFaculty || !this.facultyIsQualifiedRole) {
            return this.label.WARNING_LABEL;
        }
        
        return null;
    }
    
    
    /**
    * @description the save button label
    */
    get saveButtonLabel() {
        return sessionSchedulerLabels.SAVE_LABEL;
    }
    
    /**
     * @description filter qualified faculty based on the faculty roles
     */
    get filteredQualifiedFaculty(){
        if(this.allQualifiedFacultyList && this.allQualifiedFacultyList.length > 0){
            if(
                this.filterRoles &&
                this.facultyRolesValue.length > 0 &&
                this.facultyRolesValue.length <= this.facultyRolesOptions.length
            ){
                let filteredQualifiedFaculty = [];
                for(let qualifiedFaculty of this.allQualifiedFacultyList){
                    let qualifiedRoleList = [];
                    if(qualifiedFaculty.reduivy__Faculty_Role__c){
                        qualifiedRoleList = qualifiedFaculty.reduivy__Faculty_Role__c.split(';');
                    }

                    if(!this.filterAllRoles){
                        //If any roles match, show faculty
                        for(let facultyRole of this.facultyRolesValue){
                            if(!qualifiedRoleList.includes(facultyRole)){
                                filteredQualifiedFaculty.push(qualifiedFaculty);
                                break;
                            }
                        }
                    } else {
                        //If all roles match, show faculty
                        let showFaculty = true
                        for(let facultyRole of this.facultyRolesValue){
                            if(!qualifiedRoleList.includes(facultyRole)){
                                showFaculty = false;
                                break;
                            }
                        }

                        if(showFaculty){
                            filteredQualifiedFaculty.push(qualifiedFaculty)
                        }
                    }
                }
                return filteredQualifiedFaculty;
            }

            return this.allQualifiedFacultyList;
        }
        return [];
    }

    /**
    @description Get selected study session times to display using pill container
    */
    get selectedStudySessionTimes(){
        let items = [];

        if(this.selectedStudySessionTimeIds && this.selectedStudySessionTimeIds.size > 0){
            items = this.studySessionTimeOptions.filter(sstObj => this.selectedStudySessionTimeIds.has(sstObj.value));
        }

        return items;
    }

    
    /**
     * @description load initialization data
     */
    async loadData(){
        this.getStudySessionTimes();
        this.getAllQualifiedFaculty();
    }

    /**
     * @description Get the study session time based on record id and 
     */
    getStudySessionTimes(){
        ctrlGetStudySessionTimes({studySessionId: this.recordId}).then(result=>{
            let sstList = JSON.parse(result.responseData);
            this.studySessionTimeIdList = [];
            let options = [];

            options.push({label: this.label.PICKLIST_OPTION_NONE_LABEL, value: this.label.PICKLIST_OPTION_NONE_LABEL});
            options.push({label: this.label.PICKLIST_OPTION_ALL_LABEL, value: this.label.PICKLIST_OPTION_ALL_LABEL});
            for(let sst of sstList) {
                this.studySessionTimeIdList.push(sst.Id);
                options.push({label:sst.Name, value:sst.Id});
            }
            
            this.studySessionTimeOptions = options;
            
        }).catch(error => {
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
        });
        
    }
        
    /**
     * @description get all the qualified faculty based on the selected study session
     */
    getAllQualifiedFaculty(){
        ctrlGetAllQualifiedFaculty({studySessionId: this.recordId}).then(result =>{
            this.allQualifiedFacultyList = JSON.parse(result.responseData);
            if(this.allQualifiedFacultyList){
                for(let faculty of this.allQualifiedFacultyList){
                    faculty.isSelected = false;
                    if(faculty.reduivy__Faculty_Role__c){
                        let facultyRoleApiList = faculty.reduivy__Faculty_Role__c.split(';');
                        let facultyRoleLabelList = [];
                        for(let apiName of facultyRoleApiList) {
                            facultyRoleLabelList.push(this.facultyRolesApiToLabelMap[apiName]);
                        }
                        faculty.qualifiedRoles = facultyRoleLabelList.join(';');
                    }
                    this.allQualifiedFacultyContactIdList.push(faculty.reduivy__Contact__c);
                }
            }
        }).catch(error=>{
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
        })
    }

 
    
    /**
     * @description handle select button in the qualified faculty table
    */
    handleSelectButton(event){
        this.recordPickerFacultyValue = event.target.value;
        this.updateFacultySelectButtons();
    }
    
    /**
    * @description handle unselect button in the qualified faculty table
    */
    handleUnselectButton(){
        this.recordPickerFacultyValue = null;
        this.refs.recordPickerFaculty.clearSelection();
        this.updateFacultySelectButtons();
    }

    /**
    * @description handle toggle button to filter based on faculty roles
    */
    handleFilterChange(event){
        this.filterRoles = event.target.checked
    }

    /**
    * @description handle faculty roles checkbox group
    */
    handleFacultyRolesChange(event){
        this.facultyRolesValue = event.detail.value;
        this.checkSelectedFaculty();
    }

    /**
    * @description handle study session time picklist
    */
    handleStudySessionTime(event){
        this.studySessionTimeValue = event.detail.value;
        if(this.studySessionTimeValue === this.label.PICKLIST_OPTION_ALL_LABEL){
            this.selectedStudySessionTimeIds = new Set(this.studySessionTimeOptions.map(sstObj => sstObj.value));
            this.selectedStudySessionTimeIds.delete(this.label.PICKLIST_OPTION_NONE_LABEL);
            this.selectedStudySessionTimeIds.delete(this.label.PICKLIST_OPTION_ALL_LABEL);
        } else if(this.studySessionTimeValue === this.label.PICKLIST_OPTION_NONE_LABEL) {
            this.selectedStudySessionTimeIds = new Set();
        } else {
            this.selectedStudySessionTimeIds.add(this.studySessionTimeValue);
            this.selectedStudySessionTimeIds = new Set(Array.from(this.selectedStudySessionTimeIds));
        }
        
        
        this.template.querySelector('lightning-combobox[data-name="sstcombobox"]').value = null;
        this.studySessionTimeValue = null;
        this.dispatchEvent(new RefreshEvent());
    }

    /**
    * @description handle study session time pill container
    */
    handleSstPillRemoved(event){
        this.selectedStudySessionTimeIds.delete(event.detail.item.value);
        this.selectedStudySessionTimeIds = new Set(Array.from(this.selectedStudySessionTimeIds));
    }
    
    /**
    * @description handle status picklist
    */
    handleResponseStatus(event){
        this.responseStatusValue = event.detail.value;
    }

    /**
    * @description handle contact record picker
    */
    handleRecordPicker(event){
        this.recordPickerFacultyValue = event.detail.recordId;
        this.updateFacultySelectButtons();
    }

    /**
    * @description handle date change (start or end date)
    */
    handleDateChange(event){
        if(event.target.name === 'startDateInput'){
            this.startDateValue = event.target.value;
        } else if (event.target.name === 'endDateInput') {
            this.endDateValue = event.target.value;

        }
    }

    /**
    * @description update the qualifed faculty button to select or unselect based on the record picker value
    */
    updateFacultySelectButtons(){
        if(this.recordPickerFacultyValue) {
            for(let faculty of this.allQualifiedFacultyList){
                if(faculty.reduivy__Contact__c === this.recordPickerFacultyValue){
                    faculty.isSelected = true;
                } else {
                    faculty.isSelected = false;
                }
            }
         }else {
            for(let faculty of this.allQualifiedFacultyList){
                faculty.isSelected = false;
            }
        }
        this.checkSelectedFaculty();
    }

    /**
     * @description check the selected faculty and prompt message if the faculty is not qualified
     */
    checkSelectedFaculty(){
        let qualifiedFacultyObjOfFaculty;
        
        this.facultyIsQualifiedFaculty = false;
        for(let qualifiedFaculty of this.allQualifiedFacultyList){
            if(qualifiedFaculty.reduivy__Contact__c === this.recordPickerFacultyValue){
                this.facultyIsQualifiedFaculty = true;
                qualifiedFacultyObjOfFaculty = qualifiedFaculty;
                break;
            }
        }

        if(!this.facultyIsQualifiedFaculty) {
            return;
        }

        this.facultyIsQualifiedRole = true;
        //check if the selected faculty roles is not matching the filtering faculty roles
        if(qualifiedFacultyObjOfFaculty.reduivy__Faculty_Role__c){
            let facultyRolesList = qualifiedFacultyObjOfFaculty.reduivy__Faculty_Role__c.split(';');

            for(let filteredFacultyRole of this.facultyRolesValue){
                if(!facultyRolesList.includes(filteredFacultyRole)) {
                    this.facultyIsQualifiedRole = false;
                    this.unqualifiedRoleLabel = this.facultyRolesApiToLabelMap[filteredFacultyRole];
                    break;
                }
            }
        }
    }

    /**
     * @description handle save button
     */
    @api handleSave(){

        if(!this.recordPickerFacultyValue || this.selectedStudySessionTimeIds.size === 0 ){
            return;
        }
        
        try{
            this.toggleSpinner(1);
            ctrlAssignNewFaculty({
                contactId: this.recordPickerFacultyValue,
                studySessionTimeIds: Array.from(this.selectedStudySessionTimeIds),
                status: this.responseStatusValue,
                startDate: this.startDateValue,
                endDate: this.endDateValue,
                primaryForStudyOffering: this.makePrimaryStudyOfferingValue,
                primaryForStudySession: this.makePrimaryStudySessionValue,
                facultyRoles: this.facultyRolesValue
                
            }).then(result =>{
                this.consoleLog(result);
                let recordIds = JSON.parse(result.responseData);

                if(recordIds && recordIds.length > 0){
                    let recordIdsToNotify = [];

                    for(let recordId of recordIds){
                        recordIdsToNotify.push({recordId: recordId});
                    }

                    notifyRecordUpdateAvailable(recordIdsToNotify);
                    this.dispatchEvent(new RefreshEvent());
                }

                this.dispatchToModal(recordIds);
                
                promptSuccess(this.label.SUCCESS_LABEL, this.label.RECORD_SAVED_LABEL);
                this.toggleSpinner(-1);
            }).catch(error =>{
                this.toggleSpinner(-1);
                promptError(this.label.ERROR_LABEL, getErrorMessage(error));
            });

        }catch(error){
            this.toggleSpinner(-1);
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
        }
    }

    /**
     * @description dispatch to modal if this is inside a modal
     */
    dispatchToModal(recordIds){
        this.dispatchEvent(new CustomEvent('facultyassigned',{
            detail: {
                recordIds: recordIds
            }
        }));
    }

    /**
     * @description handle make primary faculty for study session checkbox
     */
    handleMakePrimaryStudySession(event){
        this.makePrimaryStudySessionValue = event.target.checked;
    }

    /**
     * @description handle make primary faculty for study offering checkbox
     */
    handleMakePrimaryStudyOffering(event){
        this.makePrimaryStudyOfferingValue = event.target.checked;
    }

	
	/**
     * @descripton library loader
     */
    handleLibLoadSuccess() {
        this.isScriptLoaded = true;
        this.isInitSuccess = true;
        this.loadData();
    }

    /**
     * @descripton library loader
     */
    handleLibLoadFail() {
        this.isScriptLoaded = true;
        this.isInitSuccess = false;
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
        logInfo('AssignNewFaculty', anything, this.enableDebugMode, isJson);
    }
	
}