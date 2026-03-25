/**
 * @Author 		WDCi (XiRouh)
 * @Date 		March 2025
 * @group 		Term Offerings Cloning
 * @Description 
 * @changehistory
 * ISS-002200 17-03-2025 XiRouh - XiRouh
 */
import { api, wire } from 'lwc';
import LightningModal from 'lightning/modal';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';

import { logInfo } from 'c/loggingUtil';

import STUDY_UNIT_OBJECT from '@salesforce/schema/Study_Unit__c';
import STUDY_OFFERING_OBJECT from '@salesforce/schema/Study_Offering__c';
import STUDY_SESSION_OBJECT from '@salesforce/schema/Study_Session__c';
import STUDY_EVENT_OBJECT from '@salesforce/schema/Study_Event__c';

import { customLabels } from 'c/labelLoader';
import TERM_OFFERINGS_CLONING_OVERVIEW_HELP from '@salesforce/label/c.Term_Offerings_Cloning_Overview_Help';
import TERM_OFFERINGS_CLONING_STEP1_HELP from '@salesforce/label/c.Term_Offerings_Cloning_Step1_Help';
import TERM_OFFERINGS_CLONING_STEP2_HELP from '@salesforce/label/c.Term_Offerings_Cloning_Step2_Help';
import TERM_OFFERINGS_CLONING_STEP3_HELP from '@salesforce/label/c.Term_Offerings_Cloning_Step3_Help';
import TERM_OFFERINGS_CLONING_STEP4_HELP from '@salesforce/label/c.Term_Offerings_Cloning_Step4_Help';
import MANUAL_SELECTION_LABEL from '@salesforce/label/c.Term_Offerings_Cloning_Manual_Selection'
import TERM_OFFERINGS_CLONING_WIZARD_NAME from '@salesforce/label/c.Term_Offerings_Cloning';
import ACADEMIC_TERM_COMMON_TERM from '@salesforce/label/c.Academic_Term'
import CAMPUS_COMMON_TERM from '@salesforce/label/c.Campus'

export default class TermOfferingsCloningHelpModal extends LightningModal {
	
	//configurable attributes
	@api enableDebugMode = false;
	
	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false
	loadedLists = 0;
		
	//js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'jquery', 'tooltips'
    modules = ['stringutil'];
	
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
     * @description Handle close click to close the modal
     * @param {*} event 
     */
    handleCloseClick(event) {
        this.close();
    }

    /**
    * @descripton To get study unit object info
    */
    @wire(getObjectInfo, {objectApiName: STUDY_UNIT_OBJECT})
    studyUnitObjInfo;

    /**
    * @descripton To get study offering object info
    */
    @wire(getObjectInfo, {objectApiName: STUDY_OFFERING_OBJECT})
    studyOfferingObjInfo;

    /**
     * @descripton To get study offering object info
     */
    @wire(getObjectInfo, {objectApiName: STUDY_SESSION_OBJECT})
    studySessionObjInfo;

    /**
     * @descripton To get study event object info
     */
    @wire(getObjectInfo, {objectApiName: STUDY_EVENT_OBJECT})
    studyEventObjInfo;

    /**
     * @description Return study unit object label
     */
    get studyUnitLabel() {
        return this.studyUnitObjInfo?.data?.labelPlural;
    }

    /**
     * @description Return study offering object label
     */
    get studyOfferingLabel() {
        return this.studyOfferingObjInfo?.data?.labelPlural;
    }

    /**
     * @description Return study session object plural label
     */
    get studySessionsLabel() {
        return this.studySessionObjInfo?.data?.labelPlural;
    }

    /**
     * @description Return study session object label
     */
    get studySessionLabel() {
        return this.studySessionObjInfo?.data?.label;
    }

    /**
     * @description Return study event generation status field label
     */
    get studyEventGenerationStatusFieldLabel() {
        return this.studySessionObjInfo?.data?.fields.reduivy__Study_Event_Generation_Status__c?.label;
    }

    /**
     * @description Return study event object label
     */
    get studyEventsLabel() {
        return this.studyEventObjInfo?.data?.labelPlural;
    }

    /**
     * @description Return termOfferingsCloningOverviewHelp
     */
    get termOfferingsCloningOverviewHelp() {
        return TERM_OFFERINGS_CLONING_OVERVIEW_HELP.format([TERM_OFFERINGS_CLONING_WIZARD_NAME, this.studyOfferingLabel, ACADEMIC_TERM_COMMON_TERM]);
    }

    /**
     * @description Return termOfferingsCloningStep1Help
     */
    get termOfferingsCloningStep1Help() {
        return TERM_OFFERINGS_CLONING_STEP1_HELP.format([ACADEMIC_TERM_COMMON_TERM, this.studyOfferingLabel, CAMPUS_COMMON_TERM, this.studyUnitLabel, customLabels.ALL_LABEL, MANUAL_SELECTION_LABEL]);
    }

    /**
     * @description Return termOfferingsCloningStep2Help
     */
    get termOfferingsCloningStep2Help() {
        return TERM_OFFERINGS_CLONING_STEP2_HELP.format([this.studyOfferingLabel, this.studyUnitLabel, ACADEMIC_TERM_COMMON_TERM, CAMPUS_COMMON_TERM, MANUAL_SELECTION_LABEL]);
    }

    /**
     * @description Return termOfferingsCloningStep4Help
     */
    get termOfferingsCloningStep3Help() {
        return TERM_OFFERINGS_CLONING_STEP3_HELP.format([
            this.studySessionsLabel,
            this.studyOfferingLabel,
            this.studyEventsLabel,
            this.studyEventGenerationStatusFieldLabel,
            this.studySessionLabel,
            ACADEMIC_TERM_COMMON_TERM
        ]);
    }

    /**
     * @description Return termOfferingsCloningStep4Help
     */
    get termOfferingsCloningStep4Help() {
        return TERM_OFFERINGS_CLONING_STEP4_HELP;
    }

    /**
    * @description Return modal title text Help
    */
    get headerLabel() {
        return customLabels.HELP_LABEL;
    }

    /**
     * @description Return loading label
     */
    get loadingLabel() {
        return customLabels.LOADING_LABEL;
    }

    /**
     * @description Return close label
     */
    get closeButtonLabel() {
        return customLabels.CLOSE_LABEL;
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
        logInfo('TermOfferingsCloningHelpModal', anything, this.enableDebugMode, isJson);
    }
}