/**
 * @author 		WDCi (Sueanne)
 * @date 		Aug 2024
 * @group 		Contact Calendar
 * @description to render student and faculty calendar with study events
 * @changehistory
 * ISS-001925 01-08-2024 Sueanne - new component
 * ISS-002330 21-03-2025 XW - show study event and facility translation name if found
 * ISS-002523 20-06-2025 XW - remove addevent listener and bind it in the calendar object
 * ISS-002650 10-11-2025 XW - replace refreshHandler to refreshContainer
 * ISS-002736 25-11-2025 XiRouh - Added tableTextDisplayMode configurable attribute
 * ISS-002797 13-02-2025 Lean - Standardize language code format to POSIX
 */

import { LightningElement, api, track, wire } from 'lwc';
import { promptInfo, promptError, promptWarning, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';
import { customLabels } from 'c/labelLoader';
import { sessionSchedulerConstants } from 'c/studySessionSchedulerHelper';
import { initCacheIdx } from 'c/lwcUtil';

import { RefreshEvent, registerRefreshContainer, unregisterRefreshContainer } from 'lightning/refresh';

import FIRST_DAY_OF_WEEK from '@salesforce/i18n/firstDayOfWeek';
import TIME_ZONE from '@salesforce/i18n/timeZone';
import DT_FORMAT from '@salesforce/i18n/dateTime.shortDateTimeFormat';
import LANG from "@salesforce/i18n/lang";

import DAY_BUTTON_LABEL from '@salesforce/label/c.Calendar_Day_button';
import WEEK_BUTTON_LABEL from '@salesforce/label/c.Calendar_Week_button';
import MONTH_BUTTON_LABEL from '@salesforce/label/c.Calendar_Month_button';
import LIST_WEEK_BUTTON_LABEL from '@salesforce/label/c.Calendar_List_Week_Button';
import TODAY_BUTTON_LABEL from '@salesforce/label/c.Calendar_Today_button';

//Apex methods
import ctrlGetCalendarEvents from '@salesforce/apex/REDU_ContactCalendar_LCTRL.getCalendarEvents';

//Modals
import studyEventInfoModal from 'c/studyEventInfoModal';


const STUDY_EVENT_PARAM = 'studyEvents';
const TRANSLATION_NAME_PARAM = 'translationNames';

export default class TimelineCalendar extends LightningElement {
    
    //configurable attributes
    @api recordId;
    @api modalTitle;
    @api modalIconName = 'standard:event';
    @api timelineMaxTime = '17:00';
    @api timelineMinTime = '09:00';
    @api studySessionInfoFields = 'reduivy__Available_Places__c;reduivy__Primary_Faculty__c';
    @api studySessionTimeInfoFields = 'reduivy__Recurrence__c';
    @api studyEventInfoFields = 'Name;reduivy__Start_Date_Non_TZ__c;reduivy__Start_Time_Non_TZ__c;reduivy__End_Time_Non_TZ__c';
    @api enrollmentStatuses = 'Enrolled;Completed'; //Individual Session Enrollment status
    @api calendarView = 'listWeek'; //'listWeek', 'timeGridDay', 'timeGridWeek', 'dayGridMonth'
    @api calendarHeaderButtonLeft = 'timeGridDay,timeGridWeek,dayGridMonth,listWeek';
    @api calendarHeaderButtonCenter = 'title';
    @api calendarHeaderButtonRight = 'today prev,next';
    @api useIsoWeek = false;
    //ISS-002736
    @api tableTextDisplayMode;

    @api enableDebugMode = false;
    
    //internal attributes
    isScriptLoaded = false;
    isInitSuccess = false;
    loadedLists = 0;
    calendarEvents = [];
    @track objectTranslatedNameResponse;

    //refresh Container
    refreshContainerID;

    //local cache idx to force rerendering
    _cacheIdx;

    //labels
    label = {
        DAY_BUTTON_LABEL, 
        WEEK_BUTTON_LABEL, 
        MONTH_BUTTON_LABEL, 
        LIST_WEEK_BUTTON_LABEL, 
        TODAY_BUTTON_LABEL,
        ...customLabels
    }

    //calendar attribute
    fullCalendarLwcObj;
    calendarCurrentStartDate; //to store fullcalendar v5 datetime in 12AM GMT format
    calendarCurrentEndDate; //to store fullcalendar v5 datetime in 12AM GMT format
    calendarCurrentView;

    //variable to bind event
    calViewChangedBindEvent;
    eventClickBindEvent;

    //js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'tooltips'
    modules = ['moment', 'stringutil', 'fullcalendar'];
    
    //cmp namespace
    cmpNsAttr = 'reduivy-contactcalendar_contactcalendar';

    /**
     * @descripton library loader
     */
    handleLibLoadSuccess(event) {
        this.isScriptLoaded = true;
        this.isInitSuccess = true;

        //we will load the calendar for the first time to get the date range for retrieving data
        this.loadCalendar();
    }

    /**
     * @descripton library loader
     */
    handleLibLoadFail(event) {
        this.isScriptLoaded = true;
        this.isInitSuccess = false;
    }
 
    /**
     * @descripton connected callback
     */
    connectedCallback(){
        this.refreshContainerID = registerRefreshContainer(this, this.refreshData); 
        this._cacheIdx = initCacheIdx();
    }

    /**
     * @descripton disconnected callback
     */
    disconnectedCallback(){
        unregisterRefreshContainer(this.refreshContainerID); 
    }

    /** 
     * @description Refreh data
     */
    async refreshData() {
        this.consoleLog('refreshData');

        //update the cacheIdx to force the data reload from apex controller
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
     * @description return the study event name translation field for name
     */
    get sevNameTranslationField() {
        return this.objectTranslatedNameResponse?.SEV;
    }

    /**
     * @description return the facility name translation field for name
     */
    get facNameTranslationField() {
        return this.objectTranslatedNameResponse?.FAC;
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
     * @descripton Spinner loading status
     */
    get isLoading(){
        return this.loadedLists === 0 ? false : true;
    }

    /**
     * @descripton get calendar element
     */
    get calendarDivElement(){
        return this.template.querySelector('[data-id="calendar"]');
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
     * @description Return list of calendar events
     */
    generateCalendarEvents() {
        
        let events = [];
        if (this.calendarEventsResponse && this.calendarEventsResponse.length > 0) {
            
            for (let studyEvent of this.calendarEventsResponse) {

                if (studyEvent.reduivy__Start__c && studyEvent.reduivy__End__c) {

                    let startDt = moment.tz(studyEvent.reduivy__Start__c, this.timezone);
                    let endDt = moment.tz(studyEvent.reduivy__End__c, this.timezone);

                    let display = 'auto';

                    let backgroundColour = studyEvent?.reduivy__Study_Session_Time__r?.reduivy__Study_Session__r?.reduivy__Background_Colour__c;
                    let textColour = studyEvent?.reduivy__Study_Session_Time__r?.reduivy__Study_Session__r?.reduivy__Text_Colour__c; 

                    if (!backgroundColour) {
                        backgroundColour = studyEvent?.reduivy__Study_Session_Time__r?.reduivy__Study_Session__r?.reduivy__Study_Offering__r?.reduivy__Study_Unit__r?.reduivy__Background_Colour__c
                    }

                    if (!textColour) {
                        textColour = studyEvent?.reduivy__Study_Session_Time__r?.reduivy__Study_Session__r?.reduivy__Study_Offering__r?.reduivy__Study_Unit__r?.reduivy__Text_Colour__c
                    }
                    
                    let sevName;
                    if(studyEvent && Object.hasOwn(studyEvent, this.sevNameTranslationField)) {
                        sevName = studyEvent[this.sevNameTranslationField];
                    } 

                    if(!sevName) {
                        sevName = studyEvent.Name;
                    }

                    let evt = {
                        id: studyEvent.Id,
                        name: sevName,
                        title: sevName,
                        display: display,
                        start: startDt.format(),
                        end: endDt.format(),
                        editable: false,
                        durationEditable: false,
                        resourceEditable: false,
                        backgroundColor: backgroundColour,
                        borderColor: backgroundColour,
                        textColor: textColour,
                        studyEvent: studyEvent,
                        studySessionId: studyEvent?.reduivy__Study_Session_Time__r?.reduivy__Study_Session__c,
                        studySessionTimeId: studyEvent?.reduivy__Study_Session_Time__c
                    };

                    let facilityNames = [];
                    let facultyContactNames = [];

                    if (studyEvent?.reduivy__Study_Event_Relations__r) {
                        for (let ser of studyEvent.reduivy__Study_Event_Relations__r.records) {
                            if (ser.reduivy__Facility__c) {
                                let facName;
                                if(ser.reduivy__Facility__r && Object.hasOwn(ser.reduivy__Facility__r, this.facNameTranslationField)){
                                    facName = ser.reduivy__Facility__r[this.facNameTranslationField];
                                }
                                
                                if(!facName) {
                                    facName = ser.reduivy__Facility__r.Name;
                                }
                                facilityNames.push(facName);

                            } else if (ser.reduivy__Contact__c && ser.reduivy__Relation_Type__c === sessionSchedulerConstants.FACULTY) {
                                facultyContactNames.push(ser.reduivy__Contact__r.Name);
                            }
                        }
                    }

                    let tooltip = sevName + '\n' +
                        startDt.format(this.dtFormat) + '\n' +
                        endDt.format(this.dtFormat) + '\n' +
                        facultyContactNames.join(', ') + '\n' +
                        facilityNames.join(', ');

                    evt.tooltip = tooltip;

                    events.push(evt);
                }
            }
        }

        this.consoleLog('events :: ');
        this.consoleLog(events, true);

        return events;
    }
    
    /**
     * @description load calendar
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

            let _timezone = this.timezone;
            let _language = this.languageWebFormat;
            let _schedMinTime = this.timelineMinTime;
            let _schedMaxTime = this.timelineMaxTime;
            let _firstDay = this.firstDayOfWeek;
            let _headerLeft = this.calendarHeaderButtonLeft;
            let _headerCenter = this.calendarHeaderButtonCenter;
            let _headerRight = this.calendarHeaderButtonRight;
            let _initialView = (this.calendarCurrentView ? this.calendarCurrentView : this.calendarView);
            let _events = this.calendarEvents; 
            
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

            let _nsAttr = this.cmpNsAttr;

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

            this.consoleLog('_defaultDate ' + _defaultDate.toISOString());
            this.consoleLog('_hourPart ' + _hourPart);
            this.consoleLog('_minPart ' + _minPart);
            this.consoleLog('_initialView ' + _initialView);
            this.consoleLog('_firstDay ' + _firstDay);
            this.consoleLog('calendarCurrentStartDate ' + new Date(Number(this.calendarCurrentStartDate)));
            this.consoleLog('calendarCurrentEndDate ' + new Date(Number(this.calendarCurrentEndDate)));
            this.consoleLog('neutralizedCurrentCalendarStartDate ' + this.neutralizedCurrentCalendarStartDate?.toISOString());
            this.consoleLog('neutralizedCurrentCalendarEndDate ' + this.neutralizedCurrentCalendarEndDate?.toISOString());
            this.consoleLog('_timezone ' + _timezone);

            let calObj = {
                schedulerLicenseKey: '0661963955-fcs-1676077477',
                selectable: false,
                navLinks: true, 
                editable: false, 
                allDaySlot: false, 
                nowIndicator: false, 
                aspectRatio: 0.5,
                height: 500, 
                firstDay: _firstDay,
                weekNumbers: true,
                contentHeight: '680px',
                slotMinTime: _schedMinTime,
                slotMaxTime: _schedMaxTime,
                timeZone: _timezone,
                initialView: _initialView,
                locale: _language,
                events: _events,
                headerToolbar: {
                    left: _headerLeft,
                    center: _headerCenter,
                    right: _headerRight
                },
                eventTimeFormat: {
                    hour: 'numeric',
                    minute: '2-digit',
                    omitZeroMinute: true,
                    meridiem: 'short'
                },
                eventClick: this.handleCalendarEventClick.bind(this),
                eventDidMount: function(arg) { 
                    if (_debugMode) {
                        console.log('eventDidMount - ' + JSON.stringify(arg.event));
                    }
                    
                    if (arg.el) {
                        if (arg.event) {
                            if (arg.event?.extendedProps?.tooltip) {
                                arg.el.setAttribute("title", arg.event?.extendedProps?.tooltip);
                           }
                        }

                        arg.el.setAttribute(_nsAttr, "");
                    }
                },
                datesSet: this.handleCalendarViewChanged.bind(this)
            };
            
            _calendarObj = new FullCalendar5.Calendar(_calendarDiv, calObj);
            
            this.fullCalendarLwcObj = _calendarObj;
            this.fullCalendarLwcObj.render();
            
        } catch (error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
        }
        
    }

    /**
     * @description Handle calendar view change
     */
    handleCalendarViewChanged(event) {
        this.consoleLog('handleCalendarViewChanged');
        let viewName = event.view.type;
        let start = event.start.getTime();
        let end = event.end.getTime();


        if (this.calendarCurrentStartDate !== start ||
            this.calendarCurrentEndDate !== end ||
            this.calendarCurrentView !== viewName
        ) {
            
            this.calendarCurrentStartDate = start;
            this.calendarCurrentEndDate = end;
            this.calendarCurrentView = viewName;

            this.loadCalendarData(); 
        }
    }

    /**
     * @description Method to get calendar events data from apex controller
     */
    async getCalendarEvents() {
        this.consoleLog('getCalendarEvents start');

        this.toggleSpinner(1);

        try {
            this.calendarEventsResult = await ctrlGetCalendarEvents({
                recordId: this.recordId,
                fromDate: this.neutralizedCurrentCalendarStartDate,
                toDate: this.neutralizedCurrentCalendarEndDate,
                enrollmentStatuses: this.enrollmentStatusList,
                cacheIdx: this._cacheIdx
            });
            let responseJson = JSON.parse(this.calendarEventsResult.responseData);
            this.objectTranslatedNameResponse = responseJson[TRANSLATION_NAME_PARAM];
            this.calendarEventsResponse = responseJson[STUDY_EVENT_PARAM];
            this.consoleLog('getCalendarEvents');
            this.consoleLog(this.responseJson, true);

        } catch (error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
        }
        
        this.toggleSpinner(-1);
    }

    /**
     * @description Get calendar events from apex and update the calendar
     */
    async loadCalendarData() {
        this.consoleLog('loadCalendarData');
        try {
            await this.getCalendarEvents();

            let calendarObj = this.fullCalendarLwcObj;

            let newFcEvents = this.calendarEvents;
            let existingFcEvents = calendarObj.getEvents();
            

            calendarObj.batchRendering(function(){
                for(let oldEvt of existingFcEvents){
                    oldEvt.remove();
                }

                for(let newEvt of newFcEvents) {
                    calendarObj.addEvent(newEvt);
                }
            });

        } catch(error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
        }
    }

    /**
     * @descripton load session details when event click
     */
    handleCalendarEventClick(event){
        this.consoleLog('handleCalendarEventClick');
        
        let calEvent = event.event.toPlainObject({collapseExtendedProps: true});
        
        if(calEvent.studySessionTimeId && calEvent.studySessionId && calEvent.studyEvent){
            try{
                this.launchStudyEventInfoModal(calEvent.studyEvent, calEvent.studySessionTimeId, calEvent.studySessionId, this.tableTextDisplayMode);
            }catch(error){
                promptError(this.label.ERROR_LABEL, getErrorMessage(error));
            }
        }
    }

    /**
     * @description Launch the study event info modal
     * @param studyEvent 
     * @param studySessionInfoFields 
     * @param studySessionTimeInfoFields 
     * @param studyEventInfoFields 
     * @param studySessionTimeId 
     * @param studySessionId
     */
    launchStudyEventInfoModal(studyEvent, studySessionTimeId, studySessionId, tableTextDisplayMode) {
        
        studyEventInfoModal.open({
            size: 'small',
            modalTitle: 'Info',
            studySessionInfoFields: this.studySessionInfoFields,
            studySessionTimeInfoFields: this.studySessionTimeInfoFields,
            studyEventInfoFields: this.studyEventInfoFields,
            studySessionTimeId: studySessionTimeId,
            studySessionId: studySessionId,
            studyEvent: studyEvent,
            tableTextDisplayMode: tableTextDisplayMode,
            enableDebugMode: this.enableDebugMode
        }).then((result) => {
            
            if (result) {
                this.consoleLog('launchStudyEventInfoModal.close');
                this.consoleLog(result, true);
            }
        }).catch((error) => {
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
        });
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
     * @description Return a list of enrollment status
     */
    get enrollmentStatusList() {
        if (this.enrollmentStatuses) {
            return this.enrollmentStatuses.split(';');
        }

        return [];
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
     * @description Handle the refresh
     */
    handleRefreshOnclick(event) {
        this.dispatchEvent(new RefreshEvent());
    }

    /**
     * @descripton Console log for debugging
     */
	consoleLog(anything, isJson){
        logInfo('ContactCalendar', anything, this.enableDebugMode, isJson);
    }
}