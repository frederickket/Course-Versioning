/**
 * @author      WDCi (Lean)
 * @date        Apr 2024
 * @group       Session Management
 * @description Study session scheduler
 * @changehistory
 * ISS-001920 23-04-2024 Lean - new class
 * ISS-002188 13-12-2024 XW - replaced modal with panel to improve usability
 * ISS-002230 05-02-2025 XW - display picklist value label if field type is picklist
 * ISS-002736 25-11-2025 XiRouh - Added tableTextDisplayMode configurable attribute
 */
import { LightningElement, api, wire, track } from 'lwc';
import { promptError, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo } from 'c/loggingUtil';
import { initCacheIdx, hasOwnNestedProperty, commonConstants } from 'c/lwcUtil';
import { sessionSchedulerLabels, sessionSchedulerConstants } from 'c/studySessionSchedulerHelper';

import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import sessionEditModal from 'c/studySessionSchedulerSessionEditModal';

import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import SSE_OBJECT from '@salesforce/schema/Study_Session__c'; 

//refresh module
import { RefreshEvent, registerRefreshContainer, unregisterRefreshContainer } from 'lightning/refresh';

//Apex methods
import ctrlGetStudySessions from '@salesforce/apex/REDU_SessionScheduler_LCTRL.getStudySessions';


export default class StudySessionScheduler extends LightningElement {
	
	//configurable attributes
    @api modalTitle;
    @api modalIconName;
    @api defaultSchedulingType = sessionSchedulerConstants.FACILITY;
    @api defaultCalendarView = 'resourceTimelineWeek'; //v5
    @api calendarHeaderButtonLeft = 'today prev next'; //ISS-000695 //v5
    @api calendarHeaderButtonCenter = 'title'; //ISS-000695 //v5
    @api calendarHeaderButtonRight = 'resourceTimelineDay,resourceTimelineWeek,resourceTimelineMonth'; //ISS-000695
    @api slotLabelFormat1 = '[WK] GGWW';
    @api slotLabelFormat2 = 'ddd D';
    @api slotLabelFormat3 = 'ha';
    @api timelineMinTime = '07:00';
    @api timelineMaxTime = '19:00';
    @api timelineSlotWidth;
    @api resourceAreaWidth = 15;
    @api useIsoWeek = false;
    @api calendarSnapDuration = '00:30';
    @api calendarSlotDuration = '00:30';

    @api allowCrossCampusFacilityAllocation = false;
    @api respectResourceAvailability = false;
    @api enableStickyPreview = false;
    
    @api hiddenEventBackgroundColor;
    @api resourceAvailabilityBackgroundColor;

    //resource listing and default criteria
    @api facultyContactNameFormat = '{Name}';
    @api facultyContactDefaultCriteria = "reduivy__Contact_Type__c = 'Faculty'";
    @api facilityNameFormat = '{Name}';
    @api facilityDefaultCriteria = "Active__c = true";
    @api studySessionNameFormat = '{Name}';
    @api studySessionDefaultCriteria = "";

    //event info
    @api studyEventInfoFields = "Name;reduivy__Start_Date_Non_TZ__c;reduivy__Start_Time_Non_TZ__c;reduivy__End_Time_Non_TZ__c";

    //session filters
    @api studySessionFilterFields = 'Name;reduivy__Type__c;reduivy__Capacity__c';
    @api studySessionGroupByFields = 'Name;reduivy__Type__c;reduivy__Study_Offering__c';
    @api facultyContactFilterFields = 'FirstName;LastName;Email';
    @api facilityFilterFields = 'Name;reduivy__Active__c';

    //study session menu items
    @api allowNewSession = false;
    @api allowEditSession = false;
    @api allowDeleteSession = false;
    @api allowFacilityAssignment = false;
    @api allowFacultyContactAssignment = false;
    @api allowPreviewSession = false;
    @api allowSendAnnouncement = false;
    @api allowCustomAction = false;
    
    //custom action
    @api customActionLabel;
    @api customActionFlowName;
    @api customActionFlowFinishBehavior = 'NONE'; //Allows NONE and RESTART
    @api customActionShowCloseButton = false;

    //session edit form
    @api editFormStudySessionFieldSetName = 'reduivy__SessionScheduler_Form';
    @api editFormStudySessionTimeFieldSetName = 'reduivy__SessionScheduler_Form';
    @api editFormSseColumnNo = 2;
    @api editFormSstColumnNo = 4;
    @api accordionBackgroundColor;
    @api accordionTextColor;
    @api accordionButtonVariant;

    @api tableTextDisplayMode;

	@api enableDebugMode = false;

	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false;
	loadedLists = 0;
    showFilterPanel = false; //ISS-002188
    showStudySessionPanel = true; //ISS-002188
	
    //variable to store selected values
    selectedSchedulingType;

    //filter modeal attribute
    @track filterValues;
    groupByValues;
    neutralizedCurrentCalendarStartDate;
    neutralizedCurrentCalendarEndDate;

    //quick search attributes
    quickSearchKeyword;

    //refresh Container
    refreshContainerID;
    _cacheIdx;

    //wire attribute
    studySessionsResult;
    studySessionsResponse;
    @track studySessionsHolder;

    //store the visible group and study session id based on the checkboxes
    hiddenGroupsAndStudySessions = [];

	//labels
	label = sessionSchedulerLabels;
	
	//js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'tooltips'
    modules = ['lodash', 'stringutil', 'noheadercss'];
	
    //wired object
    @wire(getObjectInfo, {objectApiName: SSE_OBJECT})
    sseObjInfo;

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

		this.refreshContainerID = registerRefreshContainer(this, this.refreshData);
        this._cacheIdx = initCacheIdx();

        this.initDefaultValues();
	}
	
    /**
     * @descripton disconnected callback
     */
	disconnectedCallback() {
		unregisterRefreshContainer(this.refreshContainerID);
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
     * @description Return study session label
     */
    get ssePluralLabel() {
        return this.sseObjInfo?.data?.labelPlural;
    }

    /**
     * @description Return false if init success to disable button
     */
    get buttonDisabled(){
        return !this.isInitSuccess;
    }

    /**
     * @description Return the scheduling type radio button options
     */
    get schedulingTypeOptions(){
        return [
            {'label': this.label.FACILITY_LABEL, 'value': sessionSchedulerConstants.FACILITY},
            {'label': this.label.FACULTY_LABEL, 'value': sessionSchedulerConstants.FACULTY}
        ];
    }

    /**
     * @description Return stringified hiddenGroupsAndStudySessions
     */
    get stringifiedHiddenGroupsAndStudySessions() {
        return JSON.stringify(this.hiddenGroupsAndStudySessions);
    }

    /**
     * @description Return new study session label
     */
    get newStudySessionLabel() {
        if (this.sseObjInfo.data) {
            return sessionSchedulerLabels.NEW_RECORD_LABEL.format([this.sseObjInfo.data.label]);
        }

        return null;
    }

    /**
     * @description Return formatted slot duration
     */
    get formattedSlotDuration() {
        let duration = '00:01:00';

        if (this.calendarSlotDuration && this.calendarSlotDuration.length !== 8) {
            return this.calendarSlotDuration + ':00';
        }

        return duration;
    }

    /**
     * @description Init default value for scheduler
     */
    initDefaultValues() {
        this.selectedSchedulingType = this.defaultSchedulingType;

        this.filterValues = {
            schedulingType: this.selectedSchedulingType
        }
    }

    /**
     * @description Refresh data
     */
    refreshData() {
        this.consoleLog('refreshData');

        this._cacheIdx = initCacheIdx();

        this.loadData()
        .then(result => {
            this.consoleLog('refreshData.loadData complete');
        })
        .catch(error => {
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
        });

        return new Promise((resolve) => {
            resolve(true);
        });

    }

    /**
     * @description load scheduling data
     */
    async loadData() {
        
        try {
            await this.getStudySessions();

        } catch(error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
        }
    }

    /**
     * @description Reload calendar timeline component
     */
    refreshCalendarTimeline() {
        this.template.querySelector('[data-id="studySessionSchedulerTimeline"]').reloadCalendar(JSON.stringify(this.filterValues));
    }

    /**
     * @description Handle the scheduling type change
     * @param {*} event 
     */
    handleSchedulingTypeChange(event) {
        this.selectedSchedulingType = event.target.value;

        this.filterValues.schedulingType = this.selectedSchedulingType;

        this.refreshCalendarTimeline();
    }

    /**
     * @descripton Sample method that invoke apex controller
     */
    async getStudySessions() {
        this.toggleSpinner(1);

        try {
            
            this.studySessionsResult = await ctrlGetStudySessions({
                nameFormat: this.studySessionNameFormat,
                defaultCriteria: this.studySessionDefaultCriteria,
                fromDate: this.neutralizedCurrentCalendarStartDate,
                toDate: this.neutralizedCurrentCalendarEndDate,
                filterValueStr: JSON.stringify(this.filterValues),
                studySessionGroupByFields: this.studySessionGroupByFields,
                cacheIdx: this._cacheIdx
            });  

            this.studySessionsResponse = JSON.parse(this.studySessionsResult.responseData);
            this.consoleLog('getStudySessions');
            this.consoleLog(this.studySessionsResponse, true);

            let combinedResult = [];
            let sessions = this.studySessionsResponse.sessions;
            let sessionsEvents = this.studySessionsResponse.sessionStudyEvents;
            let sessionsTimes = this.studySessionsResponse.sessionTimes;
            let sseIdToSse = {}
            for (let sse of sessions) {
                let newSse = JSON.parse(JSON.stringify(sse));

                if (Object.hasOwn(sessionsEvents, newSse.Id)) {
                    newSse.studyEvents = sessionsEvents[newSse.Id];
                }

                if(Object.hasOwn(sessionsTimes, newSse.Id)){
                    newSse.reduivy__Study_Session_Times__r = sessionsTimes[newSse.Id];
                }
                newSse.display = true;

                sseIdToSse[sse.Id] = sse;

                combinedResult.push(newSse);
            }



            this.studySessionsHolder = combinedResult;
            
            if(this.quickSearchKeyword){
                this.quickSearchFilter(this.quickSearchKeyword);
            }
            

        } catch (error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
        }

        this.toggleSpinner(-1);
    }

    /**
     * @description Return the study sessions grouped by All by default or group by the fields if defined in the filter modal
     */
    get groupedStudySessions() {
        this.consoleLog('groupedStudySessions');
        
        if (this.studySessionsHolder) {
            let groupedSessions = this.groupArrayList(this.studySessionsHolder, this.groupByDetails);

            this.consoleLog(groupedSessions, true);

            return groupedSessions;
        }

        return [];
    }

    /**
     * @description Return the group by details
     */
    get groupByDetails() {

        if (this.groupByValues) {
            return this.groupByValues;
        }

        return [];
    }

    /**
     * @description Group the classes by the group by fields
     * @param {*} studySessionList 
     * @param {*} groupFields 
     * @returns 
     */
    groupArrayList(studySessionList, groupFields){
        let tempTopGroupObj = {};
        let groupFieldsLabel = [];

        for(let groupField of groupFields) {
            let groupFieldLabel = groupField + commonConstants.PICKLIST_LABEL;
            if(hasOwnNestedProperty(studySessionList[0], groupFieldLabel)) {
                groupFieldsLabel.push(groupFieldLabel);
            } else {
                groupFieldsLabel.push(groupField);
            }
        }

        let groupedStudySessions = _.nesting(studySessionList, groupFieldsLabel, false);

        this.consoleLog("groupArrayList");
        this.consoleLog(groupedStudySessions);

        this.extractGroupDetails(tempTopGroupObj, groupedStudySessions);

        return tempTopGroupObj;
    }

    /**
     * @description Check if the group has child classes or it is a group
     * @param {*} groupObj 
     * @param {*} groupedStudySessions 
     */
    extractGroupDetails(groupObj, groupedStudySessions){

        if(Array.isArray(groupedStudySessions)){
            this.defineClassArrayInfo(groupObj, groupedStudySessions);
        } else {
            this.defineParentGroupInfo(groupObj, groupedStudySessions);
        }
    }

    /**
     * @description Define the parent group 
     * @param {*} parentGroupObj 
     * @param {*} groupedStudySessions 
     */
    defineParentGroupInfo(parentGroupObj, groupedStudySessions){
        this.consoleLog('defineParentGroupInfo');
        this.consoleLog(parentGroupObj);
        this.consoleLog(groupedStudySessions);

        for(let firstLevelAttr in groupedStudySessions){

            if(Object.hasOwn(groupedStudySessions, firstLevelAttr)){
                let groupObj = this.initGroupObj(firstLevelAttr, firstLevelAttr, (parentGroupObj.uniquename ? parentGroupObj.uniquename : ''));

                if(parentGroupObj.groups){
                    parentGroupObj.groups.push(groupObj);
                } else {
                    parentGroupObj.groups = [groupObj];
                }

                parentGroupObj.groups = _.orderBy(parentGroupObj.groups, ['name'], ['asc']);

                let firstLevelResult = groupedStudySessions[firstLevelAttr];
                this.extractGroupDetails(groupObj, firstLevelResult);
            }
        }
    }

    /**
     * @description Define the classes array under a group
     * @param {*} groupObj 
     * @param {*} groupedStudySessions 
     */
    defineClassArrayInfo(groupObj, groupedStudySessions){

        groupedStudySessions = _.orderBy(groupedStudySessions, ['name'], ['asc']);

        if(!groupObj.name){
            //this is to handle no grouping scenario
            let nogroupObj = this.initGroupObj(sessionSchedulerLabels.PICKLIST_OPTION_ALL_LABEL, 'all', '');
            nogroupObj.studySessions = groupedStudySessions;

            groupObj.groups = [nogroupObj];

        } else {
            groupObj.studySessions = groupedStudySessions;
        }      

    }

    /**
     * @description Return the groupBy group 
     * @param {@} name 
     * @param {*} uniqueName 
     * @param {*} parentUniqueName 
     * @returns 
     */
    initGroupObj(name, uniqueName, parentUniqueName){

        uniqueName = (parentUniqueName ? parentUniqueName + '_' : '' ) + uniqueName.replace(/[^a-zA-Z0-9]/g, '');
        this.consoleLog('uniqueName - ' + uniqueName);

        let newGroupObj = {
            name: name,
            uniquename: uniqueName
        };

        return newGroupObj;
    }

    /** ISS-002188
     * @description Handle filter onclick 
     */
    handleFilterOnClick(event) {
        this.consoleLog('handleFilterOnClick');
        this.consoleLog(event, true);

        const {operation, filterValues, groupByValues} = event.detail;

        if (operation === 'submit') {
            this.groupByValues = groupByValues;

            if (JSON.stringify(this.filterValues) !== JSON.stringify(filterValues)) {
                this.filterValues = filterValues;
                this.refreshCalendarTimeline();
                this.loadData();
            }                    
        }

    }

    /**
     * @description Handle refresh button
     */
    handleRefreshOnclick() {
        this.consoleLog('handleRefreshOnclick');
        
        this.dispatchEvent(new RefreshEvent());
    }

    /**
     * @description Handle timeline updated event
     */
    handleTimelineUpdated(event) {
        this.consoleLog('handleTimelineUpdated');

        const {start, end} = event.detail;

        if (this.neutralizedCurrentCalendarStartDate !== start ||
            this.neutralizedCurrentCalendarEndDate !== end
        ) {
            this.neutralizedCurrentCalendarStartDate = start;
            this.neutralizedCurrentCalendarEndDate = end;

            this.loadData();
        }
    }

    /**
     * @description Handle group and session visibility update based on checkboxes
     */
    handleVisibilityUpdated(event) {
        this.consoleLog('handleVisibilityUpdated');

        const {groupOrStudySessions} = event.detail;

        this.hiddenGroupsAndStudySessions = groupOrStudySessions;
        
        this.consoleLog(this.hiddenGroupsAndStudySessions, true);
    }

    /**
     * @description Handle study session deleted event from child components
     * @param {*} event 
     */
    handleStudySessionDeleted(event) {
        const { studySessionId } = event.detail;

        //remove the session from the list here to avoid retrieving from server again
        let studySessions = this.studySessionsHolder;
        studySessions = studySessions.filter(sseObj => sseObj.Id !== studySessionId);

        this.studySessionsHolder = studySessions;

        this.refreshCalendarTimeline();
    }

    /**
     * @description Handle new study session button click
     */
    handleNewStudySesssionButtonClick() {

        sessionEditModal.open({
            size: 'large',
            modalTitle: this.newStudySessionLabel,
            facilityDefaultCriteria: this.facilityDefaultCriteria,
            allowCrossCampusFacilityAllocation: this.allowCrossCampusFacilityAllocation,
            studySessionFieldSetName: this.editFormStudySessionFieldSetName,
            studySessionTimeFieldSetName: this.editFormStudySessionTimeFieldSetName,
            sseColumnNo: this.editFormSseColumnNo,
            sstColumnNo: this.editFormSstColumnNo,
            accordionBackgroundColor: this.accordionBackgroundColor,
            accordionTextColor: this.accordionTextColor,
            accordionButtonVariant: this.accordionButtonVariant,
            timelineMinTime: this.timelineMinTime,
            timelineMaxTime: this.timelineMaxTime,
            enableDebugMode: this.enableDebugMode
        }).then(result=>{
            if (result) {

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
     * @description Handle search keyword from search field
     * @param {} event Event from LWC
     */
    handleQuickSearchCommit(event){
        let searchVal = event.target.value.toLowerCase();
        this.quickSearchKeyword = searchVal;

        this.quickSearchFilter(searchVal);
    }

    /**
     * @description Filter the study sessions based on search keyword and update display attribute in sessionsHolder
     * @param {String} searchVal Keyword to filter
     */
    quickSearchFilter(searchVal){
        if(this.studySessionsHolder && this.studySessionsHolder.length > 0){
            for(let session of this.studySessionsHolder){
                session.display = true;
                if(!session.Name.toLowerCase().includes(searchVal)){
                    session.display = false;
                }
            }
        }
    }

    /**
     * @description handle when preview is clicked
     */
    handlePreviewClicked(event){
        try{
            this.template.querySelector('c-study-session-scheduler-timeline').handlePreviewClicked(event);
        }catch(error){
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
        }
    }

    handleJumpToDate(event){
        this.selectedSchedulingType = event.detail.value;
        this.filterValues.schedulingType = this.selectedSchedulingType;
        this.refreshCalendarTimeline();
        
    }

    /** ISS-002188
     * @description Toggle the filter panel
     */
    handleToggleFilterPanel(){
        this.showFilterPanel = !this.showFilterPanel;
    }

    /** ISS-002188
     * @description Toggle the study session panel
     */
    handleToggleStudySessionPanel(){
        this.showStudySessionPanel = !this.showStudySessionPanel;
    }

    /** ISS-002188
     * @description get study session panel classes
     */
    get studySessionPanelClassess() {
        let classes = 'studysessionscheduler-studysessionpanel slds-panel slds-size_medium slds-panel_docked slds-panel_docked-left slds-panel_drawer';
        if(this.showStudySessionPanel) {
            classes += ' slds-is-open';
        }
        return classes;
    }

    /** ISS-002188
     * @description get filter panel classes
     */
    get filterPanelClasses(){
        let baseClasses = 'studysessionscheduler-filterpanel slds-panel slds-size_medium slds-panel_docked slds-panel_docked-right slds-panel_drawer'
        if(this.showFilterPanel) {
            return baseClasses + ' slds-is-open';
        }

        return baseClasses;
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
        logInfo('StudySessionScheduler', anything, this.enableDebugMode, isJson);
    }
	
}