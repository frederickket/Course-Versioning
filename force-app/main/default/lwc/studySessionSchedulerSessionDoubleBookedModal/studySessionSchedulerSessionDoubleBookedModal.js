/**
 * @Author 		WDCi (XW)
 * @Date 		Aug 2024
 * @group 		Study Session Scheduler
 * @Description Modal to show the double booked study events
 * @changehistory
 * ISS-001920 28-08-2024 XW - create new class
 * ISS-002729 14-11-2025 XW - renamed event name to avoid possible confusion
 */
import { api, wire } from 'lwc';
import { logInfo } from 'c/loggingUtil';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { customLabels } from 'c/labelLoader';
import LightningModal from 'lightning/modal';
import timezone from '@salesforce/i18n/timeZone';
import SSE_OBJ from '@salesforce/schema/Study_Session__c';
import SEV_OBJ from '@salesforce/schema/Study_Event__c';

import DOUBLE_BOOKED_DESCRIPTION_LABEL from '@salesforce/label/c.Double_Booked_Description';
import DOUBLE_BOOKED_TITLE_LABEL from '@salesforce/label/c.Double_Booked_Title';
import DOUBLE_BOOKED_ICON_HINT_LABEL from '@salesforce/label/c.Double_Booked_Icon_Hint';
import ASSIGN_FACILITY_LABEL from '@salesforce/label/c.Study_Session_Scheduler_Assign_Facility';
import ASSIGN_FACULTY_LABEL from '@salesforce/label/c.Study_Session_Scheduler_Assign_Faculty';

export default class StudySessionSchedulerSessionDoubleBookedModal extends LightningModal {
	
	//configurable attributes
    @api modalTitle;
    @api doubleBookedInfoList;
    @api type;
	@api enableDebugMode = false;    
	
	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false
	loadedLists = 0;

	//labels
	label = customLabels;
	
	//js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'jquery', 'tooltips'
    modules = ['stringutil', 'moment'];
        
    /**
    * @description wire to get study session label
    */
    @wire(getObjectInfo, { objectApiName: SSE_OBJ })
    sseObjInfo;  

    /**
    * @description wire to get study event plural label
    */
    @wire(getObjectInfo, { objectApiName: SEV_OBJ })
    sevObjInfo;

    /**
    * @description Cancel Button Label
    */
    get closeButtonLabel() {
        return customLabels.CLOSE_LABEL;
    }

    /**
     * @description Assign facility label
     */
    get assignFacilityLabel() {
        return ASSIGN_FACILITY_LABEL;
    }

    /**
     * description Assign faculty label
     */
    get assignFacultyLabel() {
        return ASSIGN_FACULTY_LABEL;
    }

    /**
    * @description List of Double booked description to be 
    */
    get doubleBookedDescriptionList() {
        
        if(this.doubleBookedInfoList && this.doubleBookedTitle){

            let _doubleBookedInfoList = this.doubleBookedInfoList;
            let _result = this.doubleBookedInfoList.map(
                function (item, index) {
                    let _resourceName = _doubleBookedInfoList[index].resourceName;
                    let _datetime = _doubleBookedInfoList[index].datetime;
                    let _formattedDatetime = moment.tz(new Date(_datetime), timezone).format('D/M/YYYY hh:mm A');


                    let _description = DOUBLE_BOOKED_DESCRIPTION_LABEL.format(
                        [_resourceName, _formattedDatetime]
                    );

                    
                    return {
                        id: item.id,
                        description: _description,
                        datetime: _datetime
                    }
                }
            )
            return _result;
        }
        return []
    }

    /**
    * @description The title in the modal body
    */
    get doubleBookedTitle(){
        if(this.sseObjInfo?.data && this.sevObjInfo?.data){
            return DOUBLE_BOOKED_TITLE_LABEL.format([this.sseObjInfo.data.label, this.sevObjInfo.data.labelPlural]);
        }
        return null;
    }

    /**
    * @description Icon hint text
    */
    get doubleBookedIconHint(){
        return DOUBLE_BOOKED_ICON_HINT_LABEL;
    }

    /**
    * @description handle study event description click
    */
    handleStudyEventClick(event){
        this.dispatchEvent(new CustomEvent('sessionscheduler-doublebookedjumptodateclicked',{
            detail:{
                jumpToDate: event.currentTarget.dataset.datetime,
                schedulingType: this.type
            },
            bubbles: true,
            composed: true
        }));

        this.close({operation:'cancel'});
    }

    /**
     * Handle Assign Facility Button Click
     */
    handleAssignFacilityClick(){
        this.close({operation: 'assignfacility'});
    }

    /**
     * Handle Assign Faculty Button Click
     */
    handleAssignFacultyClick(){
        this.close({operation: 'assignfaculty'});
    }

    /**
     * Handle Close Button Click
     */
    handleCloseClick(){
        this.close({operation: 'cancel'});
    }

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
        logInfo('StudySessionSchedulerSessionDoubleBookedModal', anything, this.enableDebugMode, isJson);
    }
	
}