/**
 * @author      WDCi (Lean)
 * @date        Apr 2024
 * @group       Session Management
 * @description Study session scheduler
 * @changehistory
 * ISS-001920 23-04-2024 Lean - new class
 * ISS-002230 22-01-2025 XW - replace hardcoded label to custom label
 * ISS-002269 18-02-2025 XW - study sessions which do not met the filter value criteria will be grey out
 * ISS-002263 12-03-2025 XW - timeline start and end time will be aspect to the filtered educational institution start and end time
 * ISS-002523 23-06-2025 XW - remove add and remove event listener and replace it with ()=>{}
 * ISS-002523 23-06-2025 XW - implemented jump to date
 * ISS-002661 23-10-2025 XW - consider double booking for study event that have different timezone
 * ISS-002729 14-11-2025 XW - handle jump to date from the double booked modal
 * ISS-002736 25-11-2025 XiRouh - Added tableTextDisplayMode configurable attribute
 * ISS-002797 13-02-2025 Lean - Standardize language code format to POSIX
 */
import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord, notifyRecordUpdateAvailable } from "lightning/uiRecordApi";
import { promptError, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo } from 'c/loggingUtil';
import { getMergeKeys, mergeValues, initCacheIdx, formatLanguageCodeToPosix } from 'c/lwcUtil';
import { sessionSchedulerLabels, sessionSchedulerConstants, getSchedulingTypeLabel } from 'c/studySessionSchedulerHelper';
import { calendarLabels } from 'c/calendarHelper';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';

import FIRST_DAY_OF_WEEK from '@salesforce/i18n/firstDayOfWeek';
import TIME_ZONE from '@salesforce/i18n/timeZone';
import DT_FORMAT from '@salesforce/i18n/dateTime.shortDateTimeFormat';
import LANG from "@salesforce/i18n/lang";

import CAV_OBJ from '@salesforce/schema/Contact_Availability__c'
import FAV_OBJ from '@salesforce/schema/Facility_Availability__c'
import SER_OBJ from '@salesforce/schema/Study_Event_Relation__c'

import EDUINST_START_TIME from '@salesforce/schema/Account.Start_Time__c';
import EDUINST_END_TIME from '@salesforce/schema/Account.End_Time__c';

//refresh module
import { RefreshEvent, registerRefreshHandler, unregisterRefreshHandler } from 'lightning/refresh';

import eventChangeConfirmationModal from 'c/studySessionSchedulerEventChangeConfirmation';
import eventInfoModal from 'c/studySessionSchedulerEventInfo';

import jumpToDateModal from 'c/studySessionSchedulerJumpToDateModal'

//Apex methods
import ctrlGetCalendarEvents from '@salesforce/apex/REDU_SessionSchedulerTimeline_LCTRL.getCalendarEvents';

import ctrlGetFacultyContacts from '@salesforce/apex/REDU_SessionScheduler_LCTRL.getFacultyContacts';
import ctrlGetFacilities from '@salesforce/apex/REDU_SessionScheduler_LCTRL.getFacilities';
import ctrlGetSessionPreview from '@salesforce/apex/REDU_SessionSchedulerTimeline_LCTRL.getSessionPreview';
import ctrlUnallocateStudyEvent from '@salesforce/apex/REDU_SessionSchedulerTimeline_LCTRL.unallocateStudyEvent';
import ctrlAllocateStudyEventRelation from '@salesforce/apex/REDU_SessionSchedulerTimeline_LCTRL.allocateStudyEventRelation';
import ctrlChangeStudyEventTime from '@salesforce/apex/REDU_SessionSchedulerTimeline_LCTRL.changeStudyEventTime';

export default class StudySessionSchedulerTimeline extends NavigationMixin(LightningElement) {
	
	//configurable attributes
    @api calendarView;
    @api calendarHeaderButtonLeft;
    @api calendarHeaderButtonCenter;
    @api calendarHeaderButtonRight;
    @api slotLabelFormat1;
    @api slotLabelFormat2;
    @api slotLabelFormat3;
    @api timelineMinTime;
    @api timelineMaxTime;
    @api timelineSlotWidth;
    @api resourceAreaWidth;
    @api useIsoWeek = false;
    @api calendarSnapDuration;
    @api calendarSlotDuration;
    @api hiddenEventBackgroundColor;
    @api resourceAvailabilityBackgroundColor;

    @api allowCrossCampusFacilityAllocation = false;
    @api respectResourceAvailability = false;
    @api enableStickyPreview = false;

    @api studySessionDefaultCriteria = "";
    @api facultyContactNameFormat = '{FirstName} {LastName}';
    @api facultyContactDefaultCriteria;
    @api facilityNameFormat = '{Name}';
    @api facilityDefaultCriteria;
    @api studyEventInfoFields;

    @api
    set defaultFilterValues(val) {
        this._filterValues = val;
    }

    get defaultFilterValues() {
        return this._filterValues;
    }

    @api
    set hiddenGroupsAndStudySessions(val) {
        this._hiddenGroupsAndStudySessions = JSON.parse(val);
        if(this.calendarEventsResponse){
            this.handleEventVisibility();
        }
    }

    get hiddenGroupsAndStudySessions() {
        return this._hiddenGroupsAndStudySessions;
    }

    //ISS-002736
    @api tableTextDisplayMode;
    
	@api enableDebugMode = false;
	
	//internal attributes
	isInitSuccess = false;
	loadedLists = 0;
	
    //refresh handler
    refreshHandlerID;
    _cacheIdx;

    //Ctrl response attribute
    calendarEvents = [];
    calendarResources = [];
    filteredStudySessionIds = [];

    _calendarEventsResult;
    _calendarEventsResponse;
    _facultyContactsResult;
    _facultyContactsResponse;
    _facilitiesResult;
    _facilitiesResponse;

    @track _filterValues;
    @track _hiddenGroupsAndStudySessions;

	//labels
	label = {
        ...sessionSchedulerLabels,
        ...calendarLabels
    }
	
    //calendar attribute
    fullCalendarLwcObj;
    calendarCurrentStartDate; //to store fullcalendar v5 datetime in 12AM GMT format
    calendarCurrentEndDate; //to store fullcalendar v5 datetime in 12AM GMT format
    calendarCurrentView;
    calendarLoadingCount = 0;
    
    workpadResourceIds = [];

    //for scrolling
    scrollLeftIdx;
	scrollTopIdx;

    //previewing session Id
    placeholderSessionId;
    previewFromDate;
    previewUnallocatedOnly = false;
    _previewEventsResult;
    _previewEventsResponse;
    previewEvents = [];
    removedFromPreviewEvents = [];
    
    //cmp namespace
    cmpNsAttr = 'reduivy-studysessionschedulertimeline_studysessionschedulertimeline';
    PLH_ID = 'placeholder';
    

    //double booked
    doublebooked_class = 'doublebooked_event';
    fc_hidden_event_class = 'fc-hidden-event';
    fc_resources_availability_event = 'fc-resources-availability-event';

    //wire 
    educationalInstitutionResult;
    educationalInstitutionResponse;

    //variable to bind event so that we can load and unload them
    @track calScrollingBindEvent;
    @track doubleBookedJumpToDateBindEvent

    //js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'tooltips'
    modules = ['moment', 'fullcalendar', 'fcmoment', 'jquery'];
    
    /**
    * @description get Contact Availability object info to get the label
    */
    @wire(getObjectInfo, { objectApiName: CAV_OBJ })
    cavObjectInfo;
        
    /**
    * @description get Facility Availability object info to get the label
    */
    @wire(getObjectInfo, { objectApiName: FAV_OBJ })
    favObjectInfo;

    /**
    * @description get Study Event Relation object info to get the label
    */
    @wire(getObjectInfo, { objectApiName: SER_OBJ })
    serObjectInfo;

    /**
     * @description get the operation hours of the filtered education institution
     */
    @wire(getRecord, { recordId: '$filteredEduInstId', fields: [EDUINST_START_TIME, EDUINST_END_TIME] })
    wireEducationalInstitutionResult(result) {
        this.educationalInstitutionResult = result
        this.educationalInstitutionResponse = null;

        if(result.data) {
            this.educationalInstitutionResponse = result.data;
            this.consoleLog(this.educationalInstitutionResponse);
        } else if (result.error) {
            promptError(sessionSchedulerLabels.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

	/**
     * @descripton library loader
     */
    handleLibLoadSuccess() {
        this.isScriptLoaded = true;
        this.isInitSuccess = true;
    
        this.loadCalendar();
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
     * @descripton rendered callback
     */
	renderedCallback(){
        this.consoleLog(this.schedulingType);
    }

    /**
     * @descripton connected callback
     */
    connectedCallback(){
		this.refreshHandlerID = registerRefreshHandler(this, this.refreshData);
        this._cacheIdx = initCacheIdx();

        this.doubleBookedJumpToDateBindEvent = this.handleDoubleBookedJumpToDate.bind(this);
        window.addEventListener('sessionscheduler-doublebookedjumptodateclicked', this.doubleBookedJumpToDateBindEvent);
	}
	
    /**
     * @descripton disconnected callback
     */
	disconnectedCallback() {
		unregisterRefreshHandler(this.refreshHandlerID);
        
        window.removeEventListener('sessionscheduler-doublebookedjumptodateclicked', this.doubleBookedJumpToDateBindEvent);
        this.deregisterFcScrolling();
        
	}

    /**
     * @description Getter for calendarEventsResult
     */
    get calendarEventsResult() {
        return this._calendarEventsResult;
    }

    /**
     * @description Setter for calendarEventsResult
     */
    set calendarEventsResult(value) {
        this._calendarEventsResult = value;
    }

    /**
     * @description Getter for calendarEventsResponse
     */
    get calendarEventsResponse() {
        return this._calendarEventsResponse;
    }

    /**
     * @description Setter for calendarEventsResponse
     */
    set calendarEventsResponse(value) {
        this._calendarEventsResponse = value;

        this.calendarEvents = this.generateCalendarEvents();
    }

    /**
     * @description Getter for facultyContactsResult
     */
    get facultyContactsResult() {
        return this._facultyContactsResult;
    }

    /**
     * @description Setter for facultyContactsResult
     */
    set facultyContactsResult(value) {
        this._facultyContactsResult = value;
    }

    /**
     * @description Getter for facultyContactsResponse
     */
    get facultyContactsResponse() {
        return this._facultyContactsResponse;
    }

    /**
     * @description Setter for facultyContactsResponse
     */
    set facultyContactsResponse(value) {
        this._facultyContactsResponse = value;

        this.calendarResources = this.generateCalendarResources();
    }

    /**
     * @description Getter for facilitiesResult
     */
    get facilitiesResult() {
        return this._facilitiesResult;
    }

    /**
     * @description Setter for facilitiesResult
     */
    set facilitiesResult(value) {
        this._facilitiesResult = value;
    }
    
    /**
     * @description Getter for facilitiesResponse
     */
    get facilitiesResponse() {
        return this._facilitiesResponse;
    }

    /**
     * @description Setter for facilitiesResponse
     */
    set facilitiesResponse(value) {
        this._facilitiesResponse = value;

        this.calendarResources = this.generateCalendarResources();
    }

    /**
     * @description Getter for previewEventsResult
     */
    get previewEventsResult() {
        return this._previewEventsResult;
    }

    /**
     * @description Setter for previewEventsResult
     */
    set previewEventsResult(value) {
        this._previewEventsResult = value;
    }

    /**
     * @description Getter for previewEventsResponse
     */
    get previewEventsResponse() {
        return this._previewEventsResponse;
    }

    /**
     * @description Setter for previewEventsResponse
     */
    set previewEventsResponse(value) {
        this._previewEventsResponse = value;

        this.previewEvents = this.generatePreviewEvents();
    }

    /**
     * @description Return language in web format
     */
    get languageWebFormat() {
        return LANG;
    }

    /**
     * @description Return timezone
     */
    get timezone() {
        return TIME_ZONE;
    }

    /**
     * @description return javascript datetime format
     */
    get dtFormat() {
        return DT_FORMAT.replace(/d/g, "D");
    }

    /**
     * @description return first days of week in salesforce format
     */
    get sfFirstDayOfWeek() {
        if (this.useIsoWeek) {
            return '2';
        }

        return FIRST_DAY_OF_WEEK;   
    }

    /**
    * @description return converted fullcalendar day 
    */
    get firstDayOfWeek() {
        return this.sfFirstDayOfWeek - 1;
    }

    /**
     * @description Return calendar slot format
     */
    get calendarSlotFormat(){

        let slotFormats = [];

        if(this.slotLabelFormat1){
            slotFormats.push(this.slotLabelFormat1);
        }

        if(this.slotLabelFormat2){
            slotFormats.push(this.slotLabelFormat2);
        }

        if(this.slotLabelFormat3){
            slotFormats.push(this.slotLabelFormat3);
        }

        return slotFormats;
    }

    /**
     * @description Return scheduling type
     */
    get schedulingType() {
        return this._filterValues?.schedulingType;
    }

    /**
     * @description Return scheduling type label
     */
    get schedulingTypeLabel() {

        return getSchedulingTypeLabel(this.schedulingType);
    }

    /**
     * @description Return calendar start date in current user timezone
     */
    get neutralizedCurrentCalendarStartDate() {
        if (this.calendarCurrentStartDate) {
            return moment.tz((new Date(this.calendarCurrentStartDate)).toISOString().split('Z')[0], this.timezone);
        }

        return null;
    }

    /**
     * @description Return calendar end date in current user timezone
     */
    get neutralizedCurrentCalendarEndDate() {
        if (this.calendarCurrentEndDate) {
            return moment.tz((new Date(this.calendarCurrentEndDate)).toISOString().split('Z')[0], this.timezone);
        }

        return null;
    }

    /**
    * @description get the facility availability label as tooltip
    */
    get facilityAvailabilityLabel(){
        if(this.favObjectInfo?.data){
            return this.favObjectInfo.data.label;
        }
        return null;
    }

    /**
    * @description get the contact availability label as tooltip
    */
    get contactAvailabilityLabel(){
        if(this.cavObjectInfo?.data){
            return this.cavObjectInfo.data.label;
        }
        return null;
    }

    /**
    * @description get the Study Event Relation label
    */
    get studyEventRelationLabel(){
        if(this.serObjectInfo?.data){
            return this.serObjectInfo.data.label;
        }
        return null;
    }

    /**
     * @description the educational institution id that is selected to filter in filter panel
     */
    get filteredEduInstId() {
        return this._filterValues?.educationalInstitutionId;
    }

    /**
     * @description the filtered educational institution start time
     */
    get eduInstStartTime() {
        return this.educationalInstitutionResponse?.fields?.reduivy__Start_Time__c.value;
    }

    /**
     * @description the filtered educational institution end time
     */
    get eduInstEndTime() {
        return this.educationalInstitutionResponse?.fields?.reduivy__End_Time__c.value;
    }


    /**
     * @description Make the preview panel sticky
     */
    setPreviewStickyPanel(){
        let calendarDiv = this.calendarDivElement;
        if (calendarDiv && this.enableStickyPreview) {
            let phResLabel = this.template.querySelector('.fc-datagrid-cell.fc-resource[data-resource-id="placeholder"]');
            let phResBody = this.template.querySelector('.fc-timeline-lane.fc-resource[data-resource-id="placeholder"]');

            if (phResLabel) {
                phResLabel.setAttribute(this.cmpNsAttr, "");
                phResLabel.classList.add('freezepanellabel');
            }

            if (phResBody) {
                phResBody.setAttribute(this.cmpNsAttr, "");
                phResBody.classList.add('freezepanelbody');
            }
        }
    }

    /**
     * @description for retaining scrolling position
     */
    getFcScrollerElement(){
        let calendarDiv = this.calendarDivElement;

        if(calendarDiv){
            let fcScroller = calendarDiv.getElementsByClassName('fc-scroller-liquid-absolute')[1];

            return fcScroller;
        }

        return null;
    }

    /**
     * @description for retaining scrolling position
     */
    deregisterFcScrolling(){
        
        if(this.getFcScrollerElement()){
            this.getFcScrollerElement().removeEventListener("scroll", this.calScrollingBindEvent);

            this.consoleLog("deregisterFcScrolling");
        }
    }

    /**
     * @description for retaining scrolling position
     */
    registerFcScrolling(){
        let fcScroller = this.getFcScrollerElement();

        if(fcScroller){
            this.deregisterFcScrolling();

            this.calScrollingBindEvent = this.handleScrollingEvent.bind(this);
            fcScroller.addEventListener("scroll", this.calScrollingBindEvent);      

            this.consoleLog("registerFcScrolling");
        }
    }

    /**
     * @description for retaining scrolling position
     */
    handleScrollingEvent(event){
        this.consoleLog('handleScrollingEvent: ' + event.target.scrollLeft + ' - ' + event.target.scrollTop + ' - ' + this.isLoading);

        if(!this.isLoading){
            this.scrollLeftIdx = event.target.scrollLeft;
            this.scrollTopIdx = event.target.scrollTop;
        }
        
    }

    /**
     * @description for retaining scrolling position
     */
    setScrollingPosition(){
        let fcScroller = this.getFcScrollerElement();

        if(fcScroller){

            this.consoleLog("setScrollingPosition: " + this.scrollLeftIdx + ' ' + this.scrollTopIdx);

            if(this.scrollLeftIdx || this.scrollTopIdx){
                fcScroller.scrollLeft = this.scrollLeftIdx ? this.scrollLeftIdx : 0;
                fcScroller.scrollTop = this.scrollTopIdx ? this.scrollTopIdx : 0;
            }
        }
    }

    /**
     * @description Refresh data
     */
    async refreshData() {
        this.consoleLog('refreshData for ' + this.schedulingType);

        this._cacheIdx = initCacheIdx();

        this.loadCalendarData()
        .then(result => {
            this.consoleLog('refreshData.loadCalendarData complete');
        })
        .catch(error => {
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
        });

        return new Promise((resolve) => {
            resolve(true);
        });

    }

    @api
    reloadCalendar(paramsStr) {

        try {
            this.toggleSpinner(1);

            //workaround to accept the params changes from parent
            if (paramsStr) {
                let params = JSON.parse(paramsStr);

                this._filterValues = params;
            }

            this.consoleLog('reloadCalendar for ' + this.schedulingType);

            this.loadCalendarData()
            .then(result => {
                this.consoleLog('reloadCalendar.loadCalendarData complete');

                this.toggleSpinner(-1);
            })
            .catch(error => {
                promptError(this.label.ERROR_LABEL, getErrorMessage(error));

                this.toggleSpinner(-1);
            });

        } catch(error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));

            this.toggleSpinner(-1);
        }
    }

    async loadCalendarData() {
        
        try {
            if (this.schedulingType === sessionSchedulerConstants.FACILITY) {
                await this.getFacilities();
            } else {
                await this.getfacultyContacts();
            }

            await this.getCalendarEvents();
            await this.getPreviewEvents();

            this.loadCalendar();

        } catch(error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
        }
    }

    /**
     * @description Method to get facilities data from apex controller
     */
    async getFacilities(){
        
        this.toggleSpinner(1);

        try {
            
            this.facilitiesResult = await ctrlGetFacilities({
                nameFormat: this.facilityNameFormat,
                defaultCriteria: this.facilityDefaultCriteria,
                filterValueStr: JSON.stringify(this._filterValues),
                cacheIdx: this._cacheIdx
            });  

            this.facilitiesResponse = JSON.parse(this.facilitiesResult.responseData).facilities;
            this.consoleLog('getFacilities');
            this.consoleLog(this.facilitiesResponse, true);

        } catch (error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
        }

        this.toggleSpinner(-1);
    }

    /**
     * @description Method to get facilities data from apex controller
     */
    async getfacultyContacts(){
        
        this.toggleSpinner(1);

        try {
            
            this.facultyContactsResult = await ctrlGetFacultyContacts({
                nameFormat: this.facultyContactNameFormat,
                defaultCriteria: this.facultyContactDefaultCriteria,
                filterValueStr: JSON.stringify(this._filterValues),
                cacheIdx: this._cacheIdx
            });

            this.facultyContactsResponse = JSON.parse(this.facultyContactsResult.responseData);
            this.consoleLog('getfacultyContacts');
            this.consoleLog(this.facultyContactsResponse, true);

        } catch (error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
        }

        this.toggleSpinner(-1);
    }

    /**
     * @description Method to get calendar events data from apex controller
     */
    async getCalendarEvents() {

        this.toggleSpinner(1);

        try {
            
            this.calendarEventsResult = await ctrlGetCalendarEvents({
                calendarResourceIds: this.calendarResourceIds,
                fromDate: this.neutralizedCurrentCalendarStartDate,
                toDate: this.neutralizedCurrentCalendarEndDate,
                filterValueStr: JSON.stringify(this._filterValues),
                studySessionDefaultCriteria: this.studySessionDefaultCriteria,
                cacheIdx: this._cacheIdx
            });

            let calEvtResponse = JSON.parse(this.calendarEventsResult.responseData);
            this.consoleLog('getCalendarEvents');
            this.consoleLog(calEvtResponse, true);

            this.filteredStudySessionIds = calEvtResponse?.filteredStudySessionIds;
            this.calendarEventsResponse = calEvtResponse?.studyEvents;
            

        } catch (error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
        }

        this.toggleSpinner(-1);
    }

    /**
     * @description Return list of resources
     */
    generateCalendarResources() {
        let resources = [];

        if (this.schedulingType === sessionSchedulerConstants.FACILITY) {
            if (this.facilitiesResponse) {
                let mergeKeys = getMergeKeys(this.facilityNameFormat);

                let counter = 1;
                for (let fac of this.facilitiesResponse) {

                    let parentName = fac?.reduivy__Parent_Facility__r?.Name;
                    if (!parentName) {
                        parentName = fac?.reduivy__Campus__r?.Name;
                    }

                    let res = {
                        id: fac.Id,
                        title: mergeValues(this.facilityNameFormat, mergeKeys, fac),
                        name: fac.Name,
                        seq: counter,
                        parentName: this.workpadResourceIds.includes(fac.Id) ? this.label.WORKPAD_LABEL : parentName,
                        oriParentName: parentName,
                        resourceSobj: fac,
                        supportedCampusIds: [fac.reduivy__Campus__c]
                    };

                    resources.push(res);
                    counter ++;
                }
            }
        } else {
            if (this.facultyContactsResponse) {
                let mergeKeys = getMergeKeys(this.facultyContactNameFormat);

                let counter = 1;
                for (let fac of this.facultyContactsResponse) {

                    let parentName = fac?.Account?.Name;

                    let res = {
                        id: fac.Id,
                        title: mergeValues(this.facultyContactNameFormat, mergeKeys, fac),
                        name: fac.Name,
                        seq: counter,
                        parentName: this.workpadResourceIds.includes(fac.Id) ? this.label.WORKPAD_LABEL : parentName,
                        oriParentName: parentName,
                        resourceSobj: fac
                    };

                    resources.push(res);
                    counter ++;
                }
            }
        }

        this.consoleLog('resources :: ');
        this.consoleLog(resources, true);

        return resources;
        
    }

    

    /**
     * @description Return list of resource ids
     */
    get calendarResourceIds() {
        let resIds = [];

        if (this.calendarResources) {
            resIds = this.calendarResources.map(rec => rec.id);
        }

        return resIds ? resIds : [];
        
    }

    /**
     * @description Return list of calendar events
     */
    generateCalendarEvents() {
        
        let events = [];

        if (this.calendarEventsResponse) {
            let serGroupByResourceDate = {};
            for (let studyEvent of this.calendarEventsResponse) {
                
                if (studyEvent.reduivy__Start__c && studyEvent.reduivy__End__c) {
                    
                    let facilityNames = [];
                    let facultyContactNames = [];
                    let subEvents = [];

                    let startDt = moment.tz(studyEvent.reduivy__Start__c, this.timezone);
                    let endDt = moment.tz(studyEvent.reduivy__End__c, this.timezone);

                    let matchesFilter = this.filteredStudySessionIds.includes(studyEvent?.reduivy__Study_Session_Time__r?.reduivy__Study_Session__c);
                    let isAlwaysBackground = this.isAlwaysBackground(studyEvent, matchesFilter);
                    let isVisibilityHidden = this.isVisibilityHidden(studyEvent);
                    let isBackground = isAlwaysBackground || isVisibilityHidden;
                    
                    let display = (
                        isBackground ? 'background' : 'auto'
                    );

                    if (studyEvent.reduivy__Study_Event_Relations__r?.records) {
                        for (let ser of studyEvent.reduivy__Study_Event_Relations__r.records) {

                            let resourceId;
                            if (ser.reduivy__Facility__c) {
                                resourceId = ser.reduivy__Facility__c;
                                facilityNames.push(ser.reduivy__Facility__r.Name);

                            } else if (ser.reduivy__Contact__c && ser.reduivy__Relation_Type__c === sessionSchedulerConstants.FACULTY) {
                                resourceId = ser.reduivy__Contact__c;
                                facultyContactNames.push(ser.reduivy__Contact__r.Name);
                            }

                            if (this.calendarResourceIds.includes(resourceId)) {


                                let backgroundColour = studyEvent?.reduivy__Study_Session_Time__r?.reduivy__Study_Session__r?.reduivy__Background_Colour__c;
                                let textColour = studyEvent?.reduivy__Study_Session_Time__r?.reduivy__Study_Session__r?.reduivy__Text_Colour__c; 

                                if (!backgroundColour) {
                                    backgroundColour = studyEvent?.reduivy__Study_Session_Time__r?.reduivy__Study_Session__r?.reduivy__Study_Offering__r?.reduivy__Study_Unit__r?.reduivy__Background_Colour__c
                                }

                                if (!textColour) {
                                    textColour = studyEvent?.reduivy__Study_Session_Time__r?.reduivy__Study_Session__r?.reduivy__Study_Offering__r?.reduivy__Study_Unit__r?.reduivy__Text_Colour__c
                                }

                                let classNames = [];
                                if(isBackground) {
                                    classNames.push(this.fc_hidden_event_class);
                                }
                                //the list will return all study event relations, but we should only initiate the fc event based on the resources
                                let evt = {
                                    id: ser.Id,
                                    name: studyEvent.Name,
                                    title: display === 'auto' ? studyEvent.Name: '',
                                    display: display,
                                    start: startDt.format(),
                                    end: endDt.format(),
                                    resourceIds: [resourceId],
                                    editable: true,
                                    durationEditable: true,
                                    resourceEditable: true,
                                    backgroundColor: backgroundColour,
                                    borderColor: backgroundColour,
                                    textColor: textColour,
                                    eventSobj: studyEvent,
                                    studySessionId: studyEvent?.reduivy__Study_Session_Time__r?.reduivy__Study_Session__c,
                                    studySessionTimeId: studyEvent?.reduivy__Study_Session_Time__c,
                                    campusId: studyEvent?.reduivy__Study_Session_Time__r?.reduivy__Study_Session__r?.reduivy__Study_Offering__r?.reduivy__Campus__c,
                                    classNames: classNames,
                                    isAlwaysBackground: isAlwaysBackground
                                };

                                if (this.respectResourceAvailability) {
                                    evt.constraint = 'availableForAllocation';
                                }

                                subEvents.push(evt);

                                //check for double booking                                
                                //to consider study event from different time zone
                                let currentEventNeutralizedStart = studyEvent.reduivy__Start__c;
                                let currentEventNeutralizedEnd = studyEvent.reduivy__End__c;
                                let currentEventNeutralizedStartDate = currentEventNeutralizedStart.substring(0, currentEventNeutralizedStart.indexOf('T'));
                                let currentEventNeutralizedEndDate = currentEventNeutralizedEnd.substring(0, currentEventNeutralizedStart.indexOf('T'));
                                
                                //continue checking if study event with the same resource exists
                                if(Object.hasOwn(serGroupByResourceDate, evt.resourceIds[0])){
                                    //continue checking if study event with the same start date exists
                                    if(Object.hasOwn(serGroupByResourceDate[evt.resourceIds[0]], currentEventNeutralizedStartDate)){
                                        for(let addedSer of serGroupByResourceDate[evt.resourceIds[0]][currentEventNeutralizedStartDate]) {
                                            let isOverlap = this.isOverlap(
                                                addedSer.start, addedSer.end,
                                                evt.start, evt.end
                                            );

                                            if(isOverlap) {
                                                evt.classNames.push(this.doublebooked_class);
                                                if(!(addedSer.classNames.includes(this.doublebooked_class))){
                                                    addedSer.classNames.push(this.doublebooked_class);
                                                }
                                            }
                                        }
                                        serGroupByResourceDate[evt.resourceIds[0]][currentEventNeutralizedStartDate].push(evt);
                                    } else {
                                        serGroupByResourceDate[evt.resourceIds[0]][currentEventNeutralizedStartDate] = [evt];
                                    }

                                    //continue checking if study event with the same end date exists
                                    if (currentEventNeutralizedStartDate !== currentEventNeutralizedEndDate){
                                        if(Object.hasOwn(serGroupByResourceDate[evt.resourceIds[0]], currentEventNeutralizedEndDate)) {
                                            for(let addedSer of serGroupByResourceDate[evt.resourceIds[0]][currentEventNeutralizedEndDate]) {
                                                let isOverlap = this.isOverlap(
                                                    addedSer.start, addedSer.end,
                                                    evt.start, evt.end
                                                );

                                                if(isOverlap) {
                                                    evt.classNames.push(this.doublebooked_class);
                                                    if(!(addedSer.classNames.includes(this.doublebooked_class))){
                                                        addedSer.classNames.push(this.doublebooked_class);
                                                    }
                                                }
                                            }
                                            serGroupByResourceDate[evt.resourceIds[0]][currentEventNeutralizedEndDate].push(evt);
                                        } else {
                                            serGroupByResourceDate[evt.resourceIds[0]][currentEventNeutralizedEndDate] = [evt];
                                        }
                                    }
           
                                } else {
                                    serGroupByResourceDate[evt.resourceIds[0]] = {[currentEventNeutralizedStartDate] :  [evt]};
                                    
                                    if(currentEventNeutralizedStartDate !== currentEventNeutralizedEndDate){
                                        serGroupByResourceDate[evt.resourceIds[0]][currentEventNeutralizedEndDate] = [evt];
                                    }
                                }
                            }
                        }
                    }

                    let tooltipTimezone = studyEvent.reduivy__Timezone__c ? studyEvent.reduivy__Timezone__c : 
                        studyEvent.reduivy__Study_Session_Time__r.reduivy__Timezone__c ? studyEvent.reduivy__Study_Session_Time__r.reduivy__Timezone__c :
                        studyEvent.reduivy__Study_Session_Time__r.reduivy__Study_Session__r.reduivy__Study_Offering__r.reduivy__Campus__r.reduivy__Timezone__c;

                    let tooltip = this.label.SEV_TIMELINE_TOOLTIP_LABEL.format([
                        studyEvent.Name,
                        startDt.format(this.dtFormat),
                        endDt.format(this.dtFormat),
                        tooltipTimezone,
                        facultyContactNames.join(', '),
                        facilityNames.join(', ')
                    ])

                    tooltip = tooltip.split('\\n').join('\n');

                    for (let subEvt of subEvents) {
                        subEvt.tooltip = tooltip;

                        events.push(subEvt);
                    }
                }
            }

            if (this.respectResourceAvailability) {
                let calFromDate = this.neutralizedCurrentCalendarStartDate;
                let calToDate = this.neutralizedCurrentCalendarEndDate;

                this.consoleLog('calFromDate :: ' + calFromDate.format());
                this.consoleLog('calToDate :: ' + calToDate.format());

                for (let resource of this.calendarResources) {
                    //prepare availability events here
                    if (resource.resourceSobj) {
                        let availabilities;
                        let tooltip;
                        if (resource.resourceSobj.reduivy__Contact_Availabilities__r) {
                            availabilities = resource.resourceSobj.reduivy__Contact_Availabilities__r.records;
                            tooltip = this.contactAvailabilityLabel;
                        } else if (resource.resourceSobj.reduivy__Facility_Availabilities__r) {
                            availabilities = resource.resourceSobj.reduivy__Facility_Availabilities__r.records;
                            tooltip = this.facilityAvailabilityLabel;
                        }
                        
                        if (availabilities) {
                            this.consoleLog('availabilities :: ');
                            this.consoleLog(availabilities, true);

                            for (let avail of availabilities) {
                                let availFrom;
                                let availTo;

                                if (avail.reduivy__From_Date__c) {
                                    availFrom = moment.tz(avail.reduivy__From_Date__c + 'T00:00:00', this.timezone);
                                    if (availFrom < calFromDate) {
                                        availFrom = calFromDate.clone();
                                    }
                                } else {
                                    availFrom = calFromDate.clone();
                                }

                                if (avail.reduivy__To_Date__c) {
                                    availTo = moment.tz(avail.reduivy__To_Date__c + 'T24:00:00', this.timezone);
                                    if (availTo > calToDate) {
                                        availTo = calToDate.clone();
                                    }
                                } else {
                                    availTo = calToDate.clone();
                                }

                                this.consoleLog('availFrom :: ' + availFrom.format());
                                this.consoleLog('availTo :: ' + availTo.format());
                                
                                while (availFrom < availTo) {
                                    let weekday = availFrom.format('dddd');

                                    let fromKey = 'reduivy__' + weekday + '_From__c';
                                    let toKey = 'reduivy__' + weekday + '_To__c';

                                    if (avail[fromKey] && avail[toKey]) {
                                        this.consoleLog('generating availability event :: ' + availFrom.format() + ' ' + weekday);

                                        let availEvt = {
                                            groupId: 'availableForAllocation',
                                            overlap: true,
                                            display: 'background',
                                            start: availFrom.format('YYYY-MM-DD') + 'T' + avail[fromKey].replace('Z', ''),
                                            end: availFrom.format('YYYY-MM-DD') + 'T' + avail[toKey].replace('Z', ''),
                                            resourceIds: [resource.id],
                                            classNames: [this.fc_resources_availability_event],
                                            tooltip: tooltip
                                        }

                                        events.push(availEvt);
                                    }

                                    availFrom.add(1, 'days');
                                }
                            }
                        }
                    }
                }
            }
        }

        this.consoleLog('events :: ');
        this.consoleLog(events, true);

        return events;
    }

    generatePreviewEvents(){
        let events = [];
        if(this.previewEventsResponse){
            
            for (let previewSev of this.previewEventsResponse){
                if(this.removedFromPreviewEvents.includes(previewSev.Id)) {
                    continue;
                }

                let backgroundColour = previewSev?.reduivy__Study_Session_Time__r?.reduivy__Study_Session__r?.reduivy__Background_Colour__c;
                let textColour = previewSev?.reduivy__Study_Session_Time__r?.reduivy__Study_Session__r?.reduivy__Text_Colour__c; 

                if (!backgroundColour) {
                    backgroundColour = previewSev?.reduivy__Study_Session_Time__r?.reduivy__Study_Session__r?.reduivy__Study_Offering__r?.reduivy__Study_Unit__r?.reduivy__Background_Colour__c
                }

                if (!textColour) {
                    textColour = previewSev?.reduivy__Study_Session_Time__r?.reduivy__Study_Session__r?.reduivy__Study_Offering__r?.reduivy__Study_Unit__r?.reduivy__Text_Colour__c
                }
                
                let startDt = moment.tz(previewSev.reduivy__Start__c, this.timezone);
                let endDt = moment.tz(previewSev.reduivy__End__c, this.timezone);
                let event = {
                    id: previewSev.Id,
                    name: previewSev.Name,
                    title: previewSev.Name,
                    start: startDt.format(),
                    end: endDt.format(),
                    resourceIds: [this.PLH_ID],
                    durationEditable: false,
                    resourceEditable: true,
                    backgroundColor: backgroundColour,
                    borderColor: backgroundColour,
                    textColor: textColour,
                    eventSobj: previewSev,
                    studySessionId: previewSev?.reduivy__Study_Session_Time__r?.reduivy__Study_Session__c,
                    studySessionTimeId: previewSev?.reduivy__Study_Session_Time__c,
                    campusId: previewSev?.reduivy__Study_Session_Time__r?.reduivy__Study_Session__r?.reduivy__Study_Offering__r?.reduivy__Campus__c
                };


                let tooltip = this.label.SEV_TIMELINE_PREVIEW_TOOLTIP_LABEL.format([
                    previewSev.Name,
                    startDt.format(this.dtFormat),
                    endDt.format(this.dtFormat)
                ]);
                tooltip = tooltip.split('\\n').join('\n');

                event.tooltip = tooltip;
                events.push(event);
            }
        }
        return events;
    }

    /**
     * @description Return the calendar div element
     */
    get calendarDivElement(){
        return this.template.querySelector('[data-id="calendarDiv"]');
    }

    /**
     * @description load the timeline scheduler
     */
    loadCalendar() {
        this.consoleLog('loadCalendar start');

        try {
            let _calendarObj;
            if (this.fullCalendarLwcObj) {
                _calendarObj = this.fullCalendarLwcObj;
                _calendarObj.destroy();
            }

            let _calendarDiv = this.calendarDivElement;

            //local variables for fullcalendar object as it can't access via this.xxx
            let _debugMode = this.enableDebugMode;
            let _allowCrossCampusFacilityAllocation = this.allowCrossCampusFacilityAllocation;

            let _schedulingType = this.schedulingType;
            let _timezone = this.timezone;
            let _language = this.languageWebFormat; //ISS-002797 fc needs web format en-US instead, we use lang instead of locale
            let _schedMinTime = this.eduInstStartTime && this.filteredEduInstId ? this.eduInstStartTime : this.timelineMinTime;
            let _schedMaxTime = this.eduInstEndTime && this.filteredEduInstId ? this.eduInstEndTime : this.timelineMaxTime;
            let _snapDuration = this.calendarSnapDuration;
            let _slotDuration = this.calendarSlotDuration;
            let _weekNumCalculation = (this.isIsoWeek ? 'ISO' : 'local');
            let _firstDay = this.firstDayOfWeek;
            let _headerLeft = this.calendarHeaderButtonLeft;
            let _headerCenter = this.calendarHeaderButtonCenter;
            let _headerRight = this.calendarHeaderButtonRight;
            let _slotLabelFormat = this.calendarSlotFormat;
            let _slotMinWidth = this.timelineSlotWidth;
            let _initialView = (this.calendarCurrentView ? this.calendarCurrentView : this.calendarView);
            
            let _resourceAreaWidth = this.resourceAreaWidth + '%';
            let _resourceAreaHeaderContent = this.schedulingTypeLabel;
            let _events = [...this.calendarEvents, ...this.previewEvents];
            let _resources = this.calendarResources;
            
            let _jumpToDateText = this.label.JUMP_TO_BUTTON_LABEL;
            let _workpadLabel = this.label.WORKPAD_LABEL;
            let _addWpLabel = this.label.ADD_TO_WORKPAD_LABEL;
            let _removeWpLabel = this.label.REMOVE_FROM_WORKPAD_LABEL;

            let _nsAttr = this.cmpNsAttr;
            let _plhId = this.PLH_ID;

            //add workpad resource to the top of the list
            _resources = [{id: _plhId, title: _workpadLabel, parentName: _workpadLabel, seq: 0, eventAllow: false}, ..._resources];

            //set the day border, workaround is to use business hour as suggested by fullcalendar
            let _hourPart = parseInt(_schedMaxTime.substring(0, 2), 10);
            let _minPart = parseInt(_schedMaxTime.substring(3, 5), 10);

            if (_minPart !== 0 || _hourPart === 24) {
                _hourPart += 1;
                if (_hourPart >= 24) {
                    _schedMaxTime = '23:59';
                } else {
                    _schedMaxTime = (_hourPart < 10 ? '0' + _hourPart : _hourPart) + ':00';
                }
            }

            //set the calendar default date during initiation
            let _defaultDate = new Date();
            if(this.calendarCurrentStartDate){
                //in fullcalendar v5, the unix timestampt return is always 12AM in current machine timezone
                _defaultDate = new Date(Number(this.calendarCurrentStartDate));
                this.consoleLog('_defaultDate - calendarCurrentStartDate');
            } else {
                //Add timezone offset to prevent changing the date when calendar converts today's date to GMT
                let gmtDefaultDate = new Date(_defaultDate.getTime() - (_defaultDate.getTimezoneOffset() * 60000));
                _defaultDate = gmtDefaultDate;
                this.consoleLog('_defaultDate - gmtDefaultDate');
            }

            //set the calendar count to fire the calendar loaded event
            let _calendarEventsLoadedCount = 0;
            let _calendarEventsCount = (this.calendarEvents ? this.calendarEvents.length : 0);
            for (let evt of this.calendarEvents) {
                if (evt.display && evt.display === 'inverse-background') { //minus inverse event as fc doesn't count that in eventDidMount
                    _calendarEventsCount --;
                }
            }            

            this.consoleLog('_defaultDate ' + _defaultDate.toISOString());
            this.consoleLog('_hourPart ' + _hourPart);
            this.consoleLog('_minPart ' + _minPart);
            this.consoleLog('_initialView ' + _initialView);
            this.consoleLog('_firstDay ' + _firstDay);
            this.consoleLog('calendarCurrentStartDate ' + this.calendarCurrentStartDate);
            this.consoleLog('calendarCurrentEndDate ' + this.calendarCurrentEndDate);
            this.consoleLog('neutralizedCurrentCalendarStartDate ' + this.neutralizedCurrentCalendarStartDate?.toISOString());
            this.consoleLog('neutralizedCurrentCalendarEndDate ' + this.neutralizedCurrentCalendarEndDate?.toISOString());
            this.consoleLog('_timezone ' + _timezone);
            this.consoleLog('_schedulingType ' + _schedulingType);

            let calObj = {
                selectable: false,
                schedulerLicenseKey: '0661963955-fcs-1676077477',
                firstDay: _firstDay,
                weekNumbers: true,
                weekNumberCalculation: _weekNumCalculation,
                initialDate: _defaultDate,
                slotMinTime: _schedMinTime,
                slotMaxTime: _schedMaxTime,
                snapDuration: _snapDuration,
                slotDuration: _slotDuration,
                timeZone: _timezone,
                businessHours: [
                    {
                        daysOfWeek: [ 0, 1, 2, 3, 4, 5, 6 ],
                        startTime: _schedMaxTime,
                        endTime: '24:00'
                    }
                ],
                customButtons: {
                    cJumpToDate: {
                        text: _jumpToDateText,
                        click: this.handleJumpToDateButtonClick.bind(this)
                    }
                },
                headerToolbar: {
                    left: _headerLeft,
                    center: _headerCenter,
                    right: _headerRight
                },
                initialView: _initialView,
                locale: _language,
                slotMinWidth: _slotMinWidth,
                slotLabelFormat: _slotLabelFormat,
                stickyHeaderDates: true,
                stickyFooterScrollbar: true,
                resourceAreaWidth: _resourceAreaWidth,
                resourceAreaHeaderContent: _resourceAreaHeaderContent,
                resourceGroupField: 'parentName',
                resourceOrder: 'seq',
                resources: _resources,
                resourceLabelDidMount: (arg) => {

                    let resource = arg.resource;

                    if(arg.resource.id !== _plhId){
                        arg.el.setAttribute("title", resource.title + ' - ' + resource.extendedProps.parentName );

                        let resLabel = $(arg.el).find('.fc-datagrid-cell-main');
                        resLabel.css({'cursor': 'pointer'});
                        resLabel.click(() => {
                            const event = {
                                detail :{
                                    resourceRecord: resource.toPlainObject({collapseExtendedProps: true})
                                }
                            }

                            this.handleCalendarResourceClick(event);
                        });

                        let resIcon = $(arg.el).find('.fc-datagrid-cell-cushion > .fc-icon');
                        resIcon.css({'font-size': '1rem'});
                        if(resource.extendedProps.parentName === _workpadLabel){
                            resIcon.html('&#8794;');
                            resIcon.attr('title', _removeWpLabel);
                        } else {
                            resIcon.html('&#8793;');
                            resIcon.attr('title', _addWpLabel);
                        }

                        resIcon.css({'cursor': 'pointer'});
                        resIcon.click(() => {
                            const event = {
                                detail: {
                                    resourceRecord: resource.toPlainObject({collapseExtendedProps: true})
                                }
                            }
                            this.handleCalendarResourceWorkpadClick(event);

                        });
                    }
                },
                events: _events,
                eventClick: (eci) => {
                    //the workaround for fc to get the resource when an event has multiple resources
                    //arg.el.closest('.fc-resource').dataset.resourceId

                    if (_debugMode) {
                        console.log('eventClick - ' + JSON.stringify(eci.event));
                    }

                    //prevent background event from clickable in v5
                    if (eci.event.display === "inverse-background" || eci.event.display === "background") {
                        return;
                    }

                    let resourceId;
                    let timeChangedDetails = {};
                    
                    for (let res of eci.event.getResources()) {
                        resourceId = res.id; 
                        timeChangedDetails.newResource = res;
                    }
                    
                    eci.event.setExtendedProp("resourceIdsNew", [resourceId]);
                    eci.event.setExtendedProp("resourceId", resourceId);

                    let eventRecord = eci.event.toPlainObject({collapseExtendedProps: true});

                    const event = {
                        detail: {
                            eventRecord: eventRecord, //convert from fullcalendar v5 to plain object
                            timeChangedDetails: timeChangedDetails
                        }
                    }

                    this.handleSessionBookingInfoClick(event);
                    

                },
                eventAllow: function(dLoc, dEvt){

                    try {
                        
                        if(sessionSchedulerConstants.FACILITY === _schedulingType){
                            let allowed = true;
                            let dropLocationResource = dLoc.resource;
                            
                            if(dropLocationResource.extendedProps.parentName === _workpadLabel){
                                allowed = true
                            }
                            else if (!_allowCrossCampusFacilityAllocation && dEvt.extendedProps.campusId && !dropLocationResource.extendedProps.supportedCampusIds.includes(dEvt.extendedProps.campusId)) {
                                
                                allowed = false;
                            }

                            return allowed;
                        }

                    } catch(error) {
                        console.error(getErrorMessage(error));
                    }

                    return true;
                },
                eventDrop: (edi) => {

                    try {

                        let calEvent = edi.event;
                        let oldCalEvent = edi.oldEvent;
                        let timeChanged = calEvent.start.getTime() !== oldCalEvent.start.getTime() ? true : false;

                        let oldStart = moment.tz(oldCalEvent.start.toISOString().split('Z')[0], _timezone);
                        let oldEnd = moment.tz(oldCalEvent.end.toISOString().split('Z')[0], _timezone);

                        let newStart = moment.tz(calEvent.start.toISOString().split('Z')[0], _timezone);
                        let newEnd = moment.tz(calEvent.end.toISOString().split('Z')[0], _timezone);

                        //using new time to prepare the min and max as we dont' allow them to drop outside of the time range
                        let minDtAllowed = moment.tz(newStart.format('YYYY-MM-DD') + 'T' + _schedMinTime + ':00', _timezone);
                        let maxDtAllowed = moment.tz(newEnd.format('YYYY-MM-DD') + 'T' + (_schedMaxTime === '23:59' ? '24:00' : _schedMaxTime) + ':00', _timezone);

                        if (_debugMode) {
                            console.log('eventDrop - ' + JSON.stringify(calEvent));
                            console.log(newStart.toISOString());
                            console.log(newEnd.toISOString());
                            console.log(minDtAllowed.toISOString());
                            console.log(maxDtAllowed.toISOString());
                        }

                        //to ensure the event can only drop within the time range on a the day
                        if (!(newStart >= minDtAllowed && newEnd <= maxDtAllowed)) {
                            edi.revert();
                            return;
                        }

                        let oldResource;
                        if (edi.oldResource) {
                            oldResource = edi.oldResource;
                        } else {
                            for (let res of oldCalEvent.getResources()) {
                                oldResource = res;
                            }
                        }

                        let newResource;
                        if (edi.newResource) {
                            newResource = edi.newResource;
                        } else {
                            for (let res of calEvent.getResources()) {
                                newResource = res;
                            }
                        }

                        let timeChangedDetails = {
                            newResource: newResource.toPlainObject({collapseExtendedProps: true}),
                            oldResource: oldResource.toPlainObject({collapseExtendedProps: true}),
                            schedulingType: _schedulingType
                        };

                        if (timeChanged){
                            timeChangedDetails.oldStart = oldStart;
                            timeChangedDetails.oldEnd = oldEnd;
                            timeChangedDetails.newStart = newStart;
                            timeChangedDetails.newEnd = newEnd;
                            timeChangedDetails.minDtAllowed = minDtAllowed;
                            timeChangedDetails.maxDtAllowed = maxDtAllowed;
                            timeChangedDetails.serId = calEvent.id;

                            if (_debugMode) {
                                console.log(calEvent.start.toISOString());
                                console.log(calEvent.end.toISOString());
                            }
                        }
                        const event = {
                            detail : {
                                eventRecord: calEvent.toPlainObject({collapseExtendedProps: true}),
                                edi: edi,
                                actionType: timeChanged ? sessionSchedulerConstants.EVENTACTION_CHANGETIME_DROP : sessionSchedulerConstants.EVENTACTION_ALLOCATE,
                                timeChangedDetails: timeChangedDetails
                            }
                        }


                        this.handleChangeEventConfirmation(event);

                    } catch (err) {
                        console.error(err.message);
                    }
                },
                eventResize: (eri) => {
                    try {

                        let calEvent = eri.event;
                        let oldCalEvent = eri.oldEvent;
                        let timeChanged = calEvent.start.getTime() !== oldCalEvent.start.getTime() || calEvent.end.getTime() !== oldCalEvent.end.getTime() ? true : false;

                        let oldStart = moment.tz(eri.event.extendedProps.eventSobj.reduivy__Start__c, _timezone);
                        let oldEnd = moment.tz(eri.event.extendedProps.eventSobj.reduivy__End__c, _timezone);

                        let newStart = moment.tz(eri.event.start.toISOString().split('Z')[0], _timezone);
                        let newEnd = moment.tz(eri.event.end.toISOString().split('Z')[0], _timezone);

                        //using old time to prepare the min and max as we dont' allow them to resize to another day
                        let minDtAllowed = moment.tz(oldStart.format('YYYY-MM-DD') + 'T' + _schedMinTime + ':00.000', _timezone);
                        let maxDtAllowed = moment.tz(oldEnd.format('YYYY-MM-DD') + 'T' + (_schedMaxTime === '23:59' ? '24:00' : _schedMaxTime) + ':00.000', _timezone);

                        if (_debugMode) {
                            console.log('eventResize - ' + JSON.stringify(eri.event));
                            console.log(newStart.toISOString());
                            console.log(newEnd.toISOString());
                            console.log(minDtAllowed.toISOString());
                            console.log(maxDtAllowed.toISOString());
                        }
                        
                        //to ensure the event can only resize on the same day
                        if (!(newStart >= minDtAllowed && newEnd <= maxDtAllowed)) {
                            eri.revert();
                            return;
                        }

                        let oldResource;
                        if (eri.oldResource) {
                            oldResource = eri.oldResource;
                        } else {
                            for (let res of oldCalEvent.getResources()) {
                                oldResource = res;
                            }
                        }

                        let newResource;
                        if (eri.newResource) {
                            newResource = eri.newResource;
                        } else {
                            for (let res of calEvent.getResources()) {
                                newResource = res;
                            }
                        }

                        let timeChangedDetails = {
                            newResource: newResource.toPlainObject({collapseExtendedProps: true}),
                            oldResource: oldResource.toPlainObject({collapseExtendedProps: true}),
                            schedulingType: _schedulingType
                        };

                        if (timeChanged){
                            timeChangedDetails.oldStart = oldStart;
                            timeChangedDetails.oldEnd = oldEnd;
                            timeChangedDetails.newStart = newStart;
                            timeChangedDetails.newEnd = newEnd;
                            timeChangedDetails.minDtAllowed = minDtAllowed;
                            timeChangedDetails.maxDtAllowed = maxDtAllowed;
                            timeChangedDetails.serId = calEvent.id;

                            if (_debugMode) {
                                console.log(calEvent.start.toISOString());
                                console.log(calEvent.end.toISOString());
                            }
                        }

                        const event = {
                            detail: {
                                eventRecord: calEvent.toPlainObject({collapseExtendedProps: true}),
                                edi: eri,
                                actionType: sessionSchedulerConstants.EVENTACTION_CHANGETIME_RESIZE,
                                timeChangedDetails: timeChangedDetails
                            }
                        }

                        this.handleChangeEventConfirmation(event);


                    } catch (err) {
                        console.error(err.message);
                    }


                },
                eventDidMount: (arg) => { //replace eventRender
                    _calendarEventsLoadedCount ++;

                    if (_debugMode) {
                        console.log('eventDidMount - ' + JSON.stringify(arg.event));
                        console.log('calendarEventsCount :: ' + _calendarEventsCount);
                        console.log('calendarEventsLoadedCount :: ' + _calendarEventsLoadedCount);
                    }
                    
                    if (arg.el) {
                        if (arg.event) {
                            if (arg.event?.extendedProps?.tooltip) {
                                arg.el.setAttribute("title", arg.event?.extendedProps?.tooltip);
                           }
                        }

                        arg.el.setAttribute(_nsAttr, "");
                    }

                    //workaround for eventAfterAllRender
                    if (_calendarEventsCount <= _calendarEventsLoadedCount) {
                        this.handleCalendarLoaded();
                    }
                },
                datesSet: this.handleCalendarViewChanged.bind(this),  //replace viewRender
                handleWindowResize: true,
                windowResizeDelay: 100,
                windowResize: function(arg) {
                    _calendarObj.updateSize();
                }
            };
            
            _calendarObj = new FullCalendar5.Calendar(_calendarDiv, calObj);

            this.fullCalendarLwcObj = _calendarObj;
            this.fullCalendarLwcObj.render();
            
            this.setScrollingPosition();
            this.registerFcScrolling();
            this.setPreviewStickyPanel();

            //Also load the placeholder events if needed
            // if(this.placeholderSessionId){
            //     this.loadPreviewData(false);
            // }

        } catch (error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
        }
    }

    /**
     * @description Handle event change
     */
    handleChangeEventConfirmation(event){

        this.consoleLog('handleChangeEventConfirmation');

        let eventDropInfo = event.detail.edi;
        let events = [event.detail.eventRecord];
        let lEventActionType = event.detail.actionType; //ISS-000530
        let lTimeChangedDetails = event.detail.timeChangedDetails;

        eventChangeConfirmationModal.open({
            size: 'small',
            timeChangedDetails: lTimeChangedDetails,
            calendarEvents: events,
            eventActionType: lEventActionType,
            enableDebugMode: this.enableDebugMode
        }).then((result) => {
            
            this.consoleLog('eventChangeConfirmationModal.close');
            if (result) {
                this.consoleLog(result, true);

                const {operation, eventActionType, selectedChangeType, timeChangedDetails, selectedSessionTimes} = result;

                if (operation === 'submit') {
                    this.calendarEventsResponse = null;
                    if(eventActionType === sessionSchedulerConstants.EVENTACTION_ALLOCATE){
                        this.handleAllocate(events, selectedChangeType, timeChangedDetails, selectedSessionTimes);
                    } else if (eventActionType === sessionSchedulerConstants.EVENTACTION_CHANGETIME_DROP ||
                        eventActionType === sessionSchedulerConstants.EVENTACTION_CHANGETIME_RESIZE){
                        this.handleChangeTime(timeChangedDetails);
                    }
                } else {
                    this.handleCancelCalendarEventChange(eventDropInfo);
                }
            } else if(result === undefined) {
                this.handleCancelCalendarEventChange(eventDropInfo);
            }
        });
    }

    handleChangeTime(timeChangedDetails){
        this.toggleSpinner(1);
        ctrlChangeStudyEventTime({
            serId: timeChangedDetails.serId,
            schedulingType: this.schedulingType,
            oldResourceId: timeChangedDetails.oldResource.id,
            newResourceId: timeChangedDetails.oldResource.id !== timeChangedDetails.newResource.id ? timeChangedDetails.newResource.id : null,
            newStart: timeChangedDetails.newStart,
            newEnd: timeChangedDetails.newEnd,
        }).then(result=>{
            let responseData = JSON.parse(result.responseData);
            this.consoleLog('changeTimeResponseData :: ');
            this.consoleLog(responseData);

            promptSuccess(this.label.SUCCESS_LABEL, this.label.YOUR_CHANGES_ARE_SAVED_LABEL);

            this.dispatchEvent(new RefreshEvent());

            this.toggleSpinner(-1);
        }).catch(error=>{
            this.consoleLog(error);

            promptError(this.label.ERROR_LABEL, getErrorMessage(error));

            this.toggleSpinner(-1);
        })
    }

    handleAllocate(events, selectedChangeType, timeChangedDetails, selectedSessionTimes) {
        let eventSobj = {...events[0].eventSobj};

        this.toggleSpinner(1);
        ctrlAllocateStudyEventRelation({
            studySessionTimeList: selectedSessionTimes,
            eventChange: selectedChangeType,
            schedulingType: this.schedulingType,
            ignoredStudyEventList: this.removedFromPreviewEvents,
            parentSevString: JSON.stringify(eventSobj),
            weekStart: this.sfFirstDayOfWeek,
            oldResourceId: timeChangedDetails.oldResource.id === this.PLH_ID ? null: timeChangedDetails.oldResource.id,
            unallocatedOnly: timeChangedDetails.oldResource.id === this.PLH_ID,
            newResourceId: timeChangedDetails.newResource.id
        }).then(allocateResult => {
            this.consoleLog('ctrlAllocateStudyEventRelation.close');

            if(allocateResult) {
                let allocateResponseData = JSON.parse(allocateResult.responseData);
                let allocateResponseDataSer = allocateResponseData.upsertedStudyEventRelation;
                let allocateResponseDataNotifyId = allocateResponseData.notifyRecordUpdateAvailableId;
                this.consoleLog('allocateResponseData :: ');
                this.consoleLog(allocateResponseData);
                
                //insert into the ignored list if the event is previously unallocated
                if(timeChangedDetails.oldResource.id === this.PLH_ID){
                    this.removedFromPreviewEvents.push(...allocateResponseDataSer.map(ser => ser.reduivy__Study_Event__c));
                }

                let recordIds = []
                for(let id of allocateResponseDataNotifyId){
                    recordIds.push({recordId: id});
                }

                notifyRecordUpdateAvailable(recordIds);
                this.dispatchEvent(new RefreshEvent());

                promptSuccess(this.label.SUCCESS_LABEL, this.label.YOUR_CHANGES_ARE_SAVED_LABEL);

                this.toggleSpinner(-1);
            }
        }).catch(error =>{
            this.consoleLog(error);
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
            this.toggleSpinner(-1);
        })
    }

    /**
     * @description Cancel the calendar event drop by calling the revert()
     */
    handleCancelCalendarEventChange(eventDropInfo){
        if(eventDropInfo){
            eventDropInfo.revert();
        }
    }

    /**
     * @description Handle session booking click
     */
    handleSessionBookingInfoClick(event){
        
        this.consoleLog('handleSessionBookingInfoClick');

        let studyEvent = event.detail.eventRecord.eventSobj;
        let eventRecord = event.detail.eventRecord;
        let timeChangedDetails = event.detail.timeChangedDetails;

        eventInfoModal.open({
            label: this.label.STUDY_EVENT_INFO_LABEL,
            size: 'small',
            modalTitle: this.label.STUDY_EVENT_INFO_LABEL,
            enableDebugMode: this.enableDebugMode,
            studyEventInfoFields: this.studyEventInfoFields,
            eventRecord: eventRecord,
            timeChangedDetails: timeChangedDetails,
            showUnallocatedButton: eventRecord.resourceId !== this.PLH_ID,
            studyEvent: studyEvent,
            tableTextDisplayMode: this.tableTextDisplayMode,
        }).then((result)=>{
            this.consoleLog('eventInfoModal.close');

            if(result){
                this.consoleLog(result,true);
                const {operation} = result;

                if(operation === 'unallocate'){
                    this.handleUnallocated(eventRecord, timeChangedDetails);
                }
            }
        })
    }

    handleUnallocated(eventRecord, lTimeChangedDetails){

        let events = [eventRecord];
        
        eventChangeConfirmationModal.open({
            size: 'small',
            timeChangedDetails: lTimeChangedDetails,
            calendarEvents: events,
            eventActionType: sessionSchedulerConstants.EVENTACTION_UNALLOCATE,
            enableDebugMode: this.enableDebugMode
        }).then(result =>{
            
            this.consoleLog('eventChangeConfirmationModal.close');
            if(result){

                this.consoleLog(result,true);
                
                const {operation, eventActionType, timeChangedDetails, selectedChangeType, selectedSessionTimes} = result;
                
                if(operation === 'submit'){
                   this.handleUnallocatedSubmit(events, selectedChangeType, selectedSessionTimes);
                }
            }
        });
    }

    handleUnallocatedSubmit(events, selectedChangeType, selectedSessionTimes) {
        
        try{
            this.toggleSpinner(1);
            let selectedSer = events[0].eventSobj.reduivy__Study_Event_Relations__r?.records.filter(ser => ser.Id === events[0].id);
            let eventSobj = {...events[0].eventSobj};

            ctrlUnallocateStudyEvent({
                studySessionTimeIdsList: selectedSessionTimes,
                eventChange: selectedChangeType,
                schedulingType: this.schedulingType,
                selectedSerString: JSON.stringify(selectedSer[0]),
                parentSevString: JSON.stringify(eventSobj),
                weekStart: this.sfFirstDayOfWeek
            }).then(result =>{
                let response = JSON.parse(result.responseData);
                this.consoleLog(response);
                
                //remove them from removedFromPreviewEvents
                if(!Array.isArray(response)){
                    response = [response];
                }
                this.removedFromPreviewEvents = this.removedFromPreviewEvents.filter(x => {
                    return response.findIndex(serObj => serObj.reduivy__Study_Event__c === x) === -1;
                });
                
                promptSuccess(this.label.SUCCESS_LABEL, this.label.RECORD_DELETED_LABEL.format([this.studyEventRelationLabel]));
                this.dispatchEvent(new RefreshEvent());
                this.toggleSpinner(-1);
                
            }).catch(error =>{
                
                this.consoleLog(error);
                promptError(this.label.ERROR_LABEL, getErrorMessage(error));
                this.toggleSpinner(-1);
                
            });
        }catch(error){
            this.consoleLog(error);
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
        }
    }
        
    /**
     * @description Handle calendar loading
     */
    handleCalendarLoading(event){

        this.consoleLog('handleCalendarLoading');

        this.toggleSpinner(1);
    }

    /**
     * @description Handle calendar loaded
     */
    handleCalendarLoaded(event){

        this.consoleLog('handleCalendarLoaded');

        this.toggleSpinner(-1);
    }

    /**
     * @description Handle calendar resource click
     */
    handleCalendarResourceClick(event){
        
        this.consoleLog('handleCalendarResourceClick');

        let targetRecordId = event.detail.resourceRecord.id;
        
        if(targetRecordId){
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: targetRecordId,
                    actionName: 'view',
                },
            });
        }
    }

    /**
     * @description Handle calendar resource workpad click
     */
    handleCalendarResourceWorkpadClick(event){

        this.consoleLog('handleCalendarResourceWorkpadClick');

        try{
            let targetResource = event.detail.resourceRecord;

            if(targetResource.parentName === targetResource.oriParentName){
                targetResource.parentName = this.label.WORKPAD_LABEL;
                this.workpadResourceIds.push(targetResource.id);

            } else {
                targetResource.parentName = targetResource.oriParentName;

                if(this.workpadResourceIds){

                    let index = this.workpadResourceIds.indexOf(targetResource.id);
                    if (index > -1) {
                        this.workpadResourceIds.splice(index, 1);
                    }
                }
            }

            this.consoleLog(this.workpadResourceIds);

            let existingResource = this.fullCalendarLwcObj.getResourceById(targetResource.id);
            existingResource.remove();

            this.fullCalendarLwcObj.addResource(targetResource);

        } catch(err){
            console.error(err.message);
        }
    }

    /**
     * @description Handle calendar view change
     */
    handleCalendarViewChanged(di) {
        this.consoleLog('handleCalendarViewChanged');
        
        let start = di.start.getTime();
        let end = di.end.getTime();
        let viewName = di.view.type;
        
        if (this.calendarCurrentStartDate !== start ||
            this.calendarCurrentEndDate !== end ||
            this.calendarCurrentView !== viewName
        ) {
            this.calendarCurrentStartDate = start;
            this.calendarCurrentEndDate = end;
            this.calendarCurrentView = viewName;

            this.notifyParent();
            this.reloadCalendar();
        }
    }

    /**
     * @description Notify parent component about the timeline changes, this is important as it is used to retrieve the session records
     */
    notifyParent() {
        this.dispatchEvent(
            new CustomEvent("timelineupdated", {
                detail: {
                    viewName: this.calendarCurrentView,
                    start: this.neutralizedCurrentCalendarStartDate,
                    end: this.neutralizedCurrentCalendarEndDate
                }
            })
        );
    }

    /**
     * @description handle jumping to date and facility/faculty from double booked modal
     */
    handleDoubleBookedJumpToDate(event) {
        this.consoleLog('handleDoubleBookedJumpToDate');
        let jumpToDate = event.detail.jumpToDate;
        this.fullCalendarLwcObj.gotoDate(jumpToDate);
        if(event.detail.schedulingType !== this.schedulingType){
            let newEvent = {
                detail:{
                    value: event.detail.schedulingType
                }
            }
            this.dispatchEvent(new CustomEvent('jumptodate',newEvent));
        }
    }

    /**
     * @description Handle jump to date button click
     */
    handleJumpToDateButtonClick(event) {
        this.consoleLog('handleJumpToDateButtonClick');

        jumpToDateModal.open({
            size: 'small',
            enableDebugMode: this.enableDebugMode
        }).then(result => {
            if(result) {
                const {operation, eventData} = result;
                if(operation === 'submit' && eventData) {
                    let jumpToDate = eventData;
                    this.fullCalendarLwcObj.gotoDate(jumpToDate);
                }
            }
        }).catch(error=>{
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
        });
    }

    @api
    async handlePreviewClicked(event){
        try{

            this.consoleLog('handlePreviewClicked');
            if(this.placeholderSessionId){
                this.removePreviewEvent();
            }
            
            this.placeholderSessionId = event.detail.studySessionId;
            this.previewFromDate = event.detail.date;
            this.previewUnallocatedOnly = event.detail.unallocatedOnly;
            this.removedFromPreviewEvents = [];
            
            await this.getPreviewEvents();
            this.addEvents(this.previewEvents);

        } catch(error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
        }
        
    }

    /**
     * @description Retrieve events for preview
     */
    async getPreviewEvents(){
        try{
            if(this.placeholderSessionId){
                let result = await ctrlGetSessionPreview({
                    studySessionId: this.placeholderSessionId,
                    fromDate: this.previewFromDate,
                    schedulingType: this.schedulingType,
                    unallocatedOnly: this.previewUnallocatedOnly
                });
                    
                this.consoleLog('handlePreviewClicked');
                this.previewEventsResult = result;
                this.previewEventsResponse = JSON.parse(result.responseData);
                
                this.consoleLog(this.previewEventsResponse, true);
                 
            } else {
                this.previewEventsResponse = null;
            }
        }catch(error){            
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
        }
    }
    
    /**
     * @description Handle the change of event visibility when the checkbox is toggled
     */
    handleEventVisibility(){
        let calendar = this.fullCalendarLwcObj;
        let _hiddenGroupsAndStudySessions = this._hiddenGroupsAndStudySessions;
        let _fc_hidden_event_class = this.fc_hidden_event_class;
        calendar.batchRendering(function(){
            let events = calendar.getEvents();
            let eventsLength = events.length;
            
            
            for(let i = 0; i < eventsLength; i++) {
                let event = events[i];
                let sevObj = event?.extendedProps?.eventSobj;

                if(event?.extendedProps?.isAlwaysBackground)  {
                    continue;
                }

                if(sevObj){

                    let display = (
                        sevObj.reduivy__Type__c !== sessionSchedulerConstants.STUDYSESSION_TYPE_SESSION || 
                        (_hiddenGroupsAndStudySessions && _hiddenGroupsAndStudySessions.includes(sevObj.reduivy__Study_Session_Time__r.reduivy__Study_Session__c))
                        ? 'background' : 'auto'
                    );
                    event.setProp('display',display);
                    if(display === 'auto'){
                        event.setProp('title', sevObj.Name);
                        let _classIndex = event.classNames.indexOf(_fc_hidden_event_class);
                        if(_classIndex > -1){
                            let _classNames = [...event.classNames];
                            _classNames.splice(_classIndex, 1);
                            event.setProp('classNames', _classNames);
                        }
                        
                    } else if (display === 'background') {
                        event.setProp('title', '');
                        let _classNames = [...event.classNames];
                        if(_classNames.indexOf(_fc_hidden_event_class) === -1){
                            _classNames.push(_fc_hidden_event_class);
                        }
                        event.setProp('classNames',_classNames);
                        
                    }
                }
                
            }
        });
    }
        
    /**
     * @description Remove preview events from calendar
     */
    removePreviewEvent(){
        if(this.placeholderSessionId) {
        let events = this.fullCalendarLwcObj.getResourceById(this.PLH_ID).getEvents();
        let calendar = this.fullCalendarLwcObj;

            calendar.batchRendering(function (){
                for (let evt of events) {
                    evt.remove();
                }
            });
        }
    }

    /**
     * @description Add events to calendar
     */
    addEvents(events){
        let calendar = this.fullCalendarLwcObj;

        calendar.batchRendering(function (){
            for (let evt of events) {
                calendar.addEvent(evt);
            }
        });
    }

    /**
     * @description Check if event has overlap
     * @param {*} start1 
     * @param {*} end1 
     * @param {*} start2 
     * @param {*} end2 
     * @returns boolean
     */
    isOverlap(start1, end1, start2, end2) {
        return (start1 < end2 && end1 > start2);
    }

    /**
     * @description return true if the study event is always background and cant be toggle on
     * @param {*} studyEvent the study event object
     * @param {*} matchesFilter if the study event matches the filter
     * @returns Boolean
     */
    isAlwaysBackground(studyEvent, matchesFilter) {

        return studyEvent.reduivy__Type__c !== sessionSchedulerConstants.STUDYSESSION_TYPE_SESSION || 
        !studyEvent?.reduivy__Study_Session_Time__r?.reduivy__Study_Session__c ||
        !matchesFilter
    }
    
    /**
     * @description return true if the study session is not checked in scheduler group to be hidden (visibility)
     * @param {*} studyEvent the study event object
     * @returns Boolean
     */
    isVisibilityHidden(studyEvent){
        return (this._hiddenGroupsAndStudySessions && this._hiddenGroupsAndStudySessions.includes(studyEvent.reduivy__Study_Session_Time__r.reduivy__Study_Session__c))
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
     * @description Update css variables
     */
    updateCssVars(){
        let css = this.template.host.style;
        css.setProperty('--fc-hidden-event-bg-color', this.hiddenEventBackgroundColor);
        css.setProperty('--fc-resources-availability-bg-color', this.resourceAvailabilityBackgroundColor);
    }


    /**
     * @descripton Console log for debugging
     */
	consoleLog(anything, isJson){
        logInfo('StudySessionSchedulerTimeline', anything, this.enableDebugMode, isJson);
    }
	
}