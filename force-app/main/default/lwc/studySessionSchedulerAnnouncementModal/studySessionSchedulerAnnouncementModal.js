/**
 * @author      WDCi (Lean)
 * @date        Jun 2024
 * @group       Study Session Scheduler
 * @description Study session scheduler announcement modal controller
 * @changehistory
 * ISS-001920 11-06-2024 Lean - new class
 */
import { api, wire} from 'lwc';
import LightningModal from 'lightning/modal';
import {promptError, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo } from 'c/loggingUtil';
import { customLabels } from 'c/labelLoader';

import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';

import ANNOUNCEMENT_OBJECT from '@salesforce/schema/Announcement__c';
import ANNOUNCEMENT_SUMMARY_FIELD from '@salesforce/schema/Announcement__c.Name';
import ANNOUNCEMENT_DETAILS_FIELD from '@salesforce/schema/Announcement__c.Details__c';
import NOTIFICATION_CHANNEL_TYPE_FIELD from '@salesforce/schema/Announcement__c.Channel_Type__c';

import ANNOUNCEMENT_SETTINGS_LABEL from '@salesforce/label/c.Announcement_Settings';
import ANNOUNCEMENT_AUDIENCE_LABEL from '@salesforce/label/c.Announcement_Audience';
import INCLUDE_STUDENTS_LABEL from '@salesforce/label/c.Announcement_Include_students';
import INCLUDE_FACULTIES_LABEL from '@salesforce/label/c.Announcement_Include_faculties';
import ANNOUNCEMENT_ADVANCED_SETTINGS_LABEL from '@salesforce/label/c.Announcement_Advanced_Settings';
import ANNOUNCEMENT_FORM_SELECT_DATES_LABEL from '@salesforce/label/c.Announcement_Form_Select_Dates';
import ANNOUNCEMENT_START_DATE_LABEL from '@salesforce/label/c.Announcement_Start_Date';
import ANNOUNCEMENT_END_DATE_LABEL from '@salesforce/label/c.Announcement_End_Date';

//Apex methods
import ctrSendAnnouncement from '@salesforce/apex/REDU_SessionSchedulerAnnouncement_LCTRL.sendAnnouncement';


export default class StudySessionSchedulerSessionAnnouncementModal extends LightningModal {
	
	//configurable attributes
    @api modalTitle;
    @api studySessionId;
	@api enableDebugMode = false;
	
	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false;
	loadedLists = 0;

    activeSections = ['announcementDetails', 'notificationSettings'];

    //Form fields
    announcementObject = ANNOUNCEMENT_OBJECT;
    announcementSummaryField = ANNOUNCEMENT_SUMMARY_FIELD;
    announcementDetailsField = ANNOUNCEMENT_DETAILS_FIELD;

    //Form variables
    announcementSummary;
    announcementDetails;
    notifyStudents = false;
    notifyFaculties = false;
    isnStartDate;
    isnEndDate;

    selectedChannelTypes = [];
	
    nctWireResult;
    nctWireResponse;

    //js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'tooltips'
    modules = ['stringutil'];

    @wire(getObjectInfo, {objectApiName: ANNOUNCEMENT_OBJECT})
    annObjInfo;

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
     * @description notification channel type
     */
    channelTypesPicklist = [];
    @wire(getPicklistValues, {
        recordTypeId: '$annObjInfo.data.defaultRecordTypeId',
        fieldApiName: NOTIFICATION_CHANNEL_TYPE_FIELD
    })
    wiredNctOptions({error, data}){
        if(data){
            this.channelTypesPicklist = [];
            
            //Find default picklist option
            let defaultValue;
            if (data.defaultValue){
                defaultValue = data.defaultValue.value;
            }

            for(let opt of data.values){
                this.consoleLog(opt.value);

                //Convert proxy to editable object
                let editableOpt = JSON.parse(JSON.stringify(opt));

                //Set checked for the default picklist option
                if (editableOpt.value === defaultValue){
                    editableOpt.isDefault = true;
                    this.selectedChannelTypes.push(editableOpt.value);
                } else {
                    editableOpt.isDefault = false;
                }
                this.channelTypesPicklist.push(editableOpt);
            }
        } else if(error) {
            promptError(customLabels.ERROR_LABEL, getErrorMessage(error));
        }
    }

    /**
     * @description title
     */
    get headerLabel() {
        return this.modalTitle;
    }

    /**
     * @description Cancel button
     */
    get cancelButtonLabel() {
        return customLabels.CANCEL_LABEL;
    }

    /**
     * @description Send button
     */
    get sendButtonLabel() {
        return customLabels.SEND_LABEL;
    }

    /**
     * @description announcement details field label
     */
    get announcementDetailsLabel() {
        return this.annObjInfo?.data?.fields?.reduivy__Details__c?.label;
    }

    /**
     * @description announcement summary field label
     */
    get announcementSummaryLabel() {
        return this.annObjInfo?.data?.fields?.Name?.label;
    }

    /**
     * @description notification channel field label
     */
    get notificationChannelLabel() {
        return this.annObjInfo?.data?.fields?.reduivy__Channel_Type__c?.label;
    }

    /**
     * @description notification setting field label
     */
    get notificationSettingsLabel() {
        return ANNOUNCEMENT_SETTINGS_LABEL;
    }

    /**
     * @description notification audience field label
     */
    get notificationAudienceLabel() {
        return ANNOUNCEMENT_AUDIENCE_LABEL;
    }

    /**
     * @description include students field label
     */
    get includeStudentsLabel() {
        return INCLUDE_STUDENTS_LABEL;
    }

    /**
     * @description include faculties field label
     */
    get includeFacultiesLabel() {
        return INCLUDE_FACULTIES_LABEL;
    }

    /**
     * @description notification advanced settings  label
     */
    get notificationAdvancedSettingsLabel() {
        return ANNOUNCEMENT_ADVANCED_SETTINGS_LABEL;
    }

    /**
     * @description date label
     */
    get announcementFormSelectDatesLabel() {
        return ANNOUNCEMENT_FORM_SELECT_DATES_LABEL;
    }

    /**
     * @description date label
     */
    get startDateLabel() {
        return ANNOUNCEMENT_START_DATE_LABEL;
    }

    /**
     * @description date label
     */
    get endDateLabel() {
        return ANNOUNCEMENT_END_DATE_LABEL;
    }

    /**
     * @description Announcement success message
     */
    get announcementCreatedSuccessfullyLabel() {
        if (this.annObjInfo && this.annObjInfo.data) {
            return customLabels.RECORD_CREATED_LABEL.format([this.annObjInfo.data.label]);
        }

        return null;
    }

    /**
     * @description Handle summary field change
     */
    handleSummaryChange(event) {
        this.announcementSummary = event.detail.value;
    }

    /**
     * @description Handle details field change
     */
    handleDetailsChange(event) {
        this.announcementDetails = event.detail.value;
    }

    /**
     * @description Handle channel type field change
     */
    handleChannelTypeChange(event){
        let channelType = event.target.value;
        let isChecked = event.target.checked;
        //Add to selected types
        if (isChecked){
            this.selectedChannelTypes.push(channelType);
        //Remove from selected types
        } else {
            let filteredChannels = this.selectedChannelTypes.filter(el => el !== channelType);
            this.selectedChannelTypes = filteredChannels;
        }
    }

    /**
     * @description Handle notify student field change
     */
    handleNotifyStudentsChange(event) {
        this.notifyStudents = event.target.checked;

        if (this.notifyStudents === undefined) {
            this.notifyStudents = false;
        }
    }

    /**
     * @description Handle notify faculty field change
     */
    handleNotifyFacultiesChange(event) {
        this.notifyFaculties = event.target.checked;

        if (this.notifyFaculties === undefined) {
            this.notifyFaculties = false;
        }
    }

    /**
     * @description Handle start date field change
     */
    handleStartDateChange(event) {
        this.isnStartDate = event.detail.value;
    }

    /**
     * @description Handle end date field change
     */
    handleEndDateChange(event) {
        this.isnEndDate = event.detail.value;
    }

    /**
     * @description Handle send click
     */
    handleSend() {
        this.toggleSpinner(1);

        //Convert list of selected Notification Channel Types to appropriate value for a multi-picklist
        let channelTypes = this.selectedChannelTypes.join(";");

        ctrSendAnnouncement({
            studySessionId: this.studySessionId,
            announcementSummary: this.announcementSummary,
            announcementDetails: this.announcementDetails,
            notifyStudents: this.notifyStudents,
            notifyFaculties: this.notifyFaculties,
            isnStartDate: this.isnStartDate,
            isnEndDate: this.isnEndDate,
            channelTypes: channelTypes
        })
        .then(result => {
            promptSuccess(this.announcementCreatedSuccessfullyLabel);
            this.close('success');
        })
        .catch(error => {
            this.toggleSpinner(-1);
            promptError(customLabels.ERROR_LABEL, getErrorMessage(error));
        });
    }

    /**
     * @description Handle cancel
     */
    handleCancel() {
        this.close('cancel');
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
        logInfo('StudySessionSchedulerSessionAnnouncementModal', anything, this.enableDebugMode, isJson);
    }
	
}