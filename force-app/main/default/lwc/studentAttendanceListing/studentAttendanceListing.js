/**
 * @Author 		WDCi (Lean)
 * @Date 		July 2024
 * @group 		Attendance
 * @Description Attendance taking wizard for faculty
 * @changehistory
 * ISS-001919 31-07-2024 Lean - new wizard
 * ISS-002650 10-11-2025 XW - replace refreshHandler to refreshContainer
 */
import { LightningElement, api, wire, track } from 'lwc';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';
import { customLabels } from 'c/labelLoader';

import FIRST_DAY_OF_WEEK from '@salesforce/i18n/firstDayOfWeek'
import TIME_ZONE from '@salesforce/i18n/timeZone';
import DT_FORMAT from '@salesforce/i18n/dateTime.shortDateFormat';

//refresh module
import { RefreshEvent, registerRefreshContainer, unregisterRefreshContainer } from 'lightning/refresh';

export default class StudentAttendanceListing extends LightningElement {
	
	//configurable attributes
    @api recordId;
    @api userMode;
    @api modalTitle;
    @api modalIconName;
    @api attendanceTileIcon;
    @api attendanceButtonLabel;
    @api attendanceStatuses;
    @api sevTileInfoFields;
    @api studyEventRelationEditFieldSetName;
    @api showNoAttendanceWarning = false;
    @api noAttendanceWarningText;
    @api noAttendanceWarningIcon;
    @api noAttendanceWarningIconVariant;
    @api studyEventTileClickAction; //support View Info and View Record
    @api infoModalFieldsForStudyEvent;
    @api infoModalSectionNameForStudyEvent;
    @api showRecordsBasedOnAllocation;
    @api validFacultyIsnStatus;
    
	@api enableDebugMode = false;
	
	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false
	loadedLists = 0;

    //for date picker
    selectedDate;
	
    //for accordion
    weekDays = [];
    activeSections = [];

    //refresh Container
    refreshContainerID;

    //wire attribute
    sampleWireResult;
    sampleResponse;

	//labels
	label = customLabels;
	
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

        this.initData();
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
     * @description Return first day of week, 0 = Sunday, 1 = Monday and etc..
     */
    get firstDayOfWeek() {
        //salesforce first day of week 1 = Sunday, 2 = Monday, we convert it to javascript standard which is 0 = Sunday, 1 = Monday
        return FIRST_DAY_OF_WEEK === 1 ? 0: 1;
    }

    /**
     * @description return javascript datetime format
     */
    get dtFormat() {
        this.consoleLog('dtFormat :: ' + DT_FORMAT);

        return DT_FORMAT.replace(/d/g, "D");
    }

    /**
     * @description Return date object based on the selectedDate as it is a string
     */
    get selectedDateObj() {
        if (this.selectedDate) {
            return new Date(this.selectedDate);
        }

        return null;
    }

    /**
     * @description Init component data
     */
    async initData() {
        await this.setWeekDays();
        await this.setActiveSections();
    }

    /**
     * @description Generate list of days for a week based on the selected date
     */
    async setWeekDays() {
        // this.weekDays = [];
        let _weekDays = [];
        let dtFormat = this.dtFormat;

        if (this.selectedDateObj) {
            let selectedDateObj = this.selectedDateObj;
            let currentDay = selectedDateObj.getDay();

            let dateCounter = selectedDateObj;
            dateCounter.setDate(dateCounter.getDate() + (this.firstDayOfWeek - currentDay));

            _weekDays.push({
                dateLocaleFormat: moment(dateCounter).format(dtFormat),
                date: dateCounter,
                dateIsoFormat: moment(dateCounter).format('yyyy-MM-DD')
            });

            for (let i = 0; i < 6; i ++) {
                dateCounter.setDate(dateCounter.getDate() + 1);

                _weekDays.push({
                    dateLocaleFormat: moment(dateCounter).format(dtFormat),
                    date: dateCounter,
                    dateIsoFormat: moment(dateCounter).format('yyyy-MM-DD')
                });
            }

            this.consoleLog('_weekDays');
            this.consoleLog(_weekDays, true);
        }

        this.weekDays = _weekDays;
    }

    /**
     * @description Set the accordion active sections
     */
    async setActiveSections() {
        if (this.selectedDate) {
            this.activeSections = [this.selectedDate];
        }
    }

    /**
     * @description Sample handle refresh button
     */
    handleRefreshOnclick() {
        this.dispatchEvent(new RefreshEvent());
    }

    /**
     * @description Handle date field onchange
     */
    handleDateFieldOnchange(event) {
        this.selectedDate = event.detail.value;

        this.initData();
    }

    /**
     * @description Handle previous week button click
     */
    handlePreviousWeekClick() {
        let currentDate = this.selectedDateObj;

        let newDate = (moment.tz(currentDate, this.timezone)).add(-7, 'days');
        this.selectedDate = newDate.format('yyyy-MM-DD'); //the input field only accept string
        this.initData();
    }

    /**
     * @description Handle next week button click
     */
    handleNextWeekClick() {
        let currentDate = this.selectedDateObj;

        let newDate = (moment.tz(currentDate, this.timezone)).add(7, 'days');
        this.selectedDate = newDate.format('yyyy-MM-DD'); //the input field only accept string
        this.initData();
    }

    /**
     * @description Handle view attendance registry button click from child
     */
    handleViewAttendanceRegistry(event) {
        this.dispatchEvent(new CustomEvent("viewattendanceregistry", {
            detail: {
                sevObj: event.detail.sevObj
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
        logInfo('StudentAttendanceListing', anything, this.enableDebugMode, isJson);
    }
	
}