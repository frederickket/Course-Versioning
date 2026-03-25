/**
 * @Author 		WDCi (XiRouh)
 * @Date 		March 2025
 * @group 		Term Grade Release
 * @Description 
 * @changehistory
 * ISS-002311 12-03-2025 XiRouh - new class
 */
import { api, wire } from 'lwc';
import LightningModal from 'lightning/modal';

import { logInfo } from 'c/loggingUtil';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';

import CLOSE_LABEL from '@salesforce/label/c.Close';
import LOADING_LABEL from '@salesforce/label/c.Loading';
import HELP_LABEL from '@salesforce/label/c.Help';

import TERM_GRADE_RELEASE_OVERVIEW_HELP from '@salesforce/label/c.Term_Grade_Release_Overview_Help';
import TERM_GRADE_RELEASE_STEP1_HELP from '@salesforce/label/c.Term_Grade_Release_Step1_Help';
import TERM_GRADE_RELEASE_STEP2_HELP from '@salesforce/label/c.Term_Grade_Release_Step2_Help';
import TERM_GRADE_RELEASE_STEP3_HELP from '@salesforce/label/c.Term_Grade_Release_Step3_Help';
import MANUAL_SELECTION_LABEL from '@salesforce/label/c.Term_Grade_Release_Manual_Selection'

import STUDY_UNIT_OBJECT from '@salesforce/schema/Study_Unit__c';
import STUDY_OFFERING_OBJECT from '@salesforce/schema/Study_Offering__c';
import CREDIT_TRANSFER_APPLICATION_OBJECT from '@salesforce/schema/Credit_Transfer_Application__c';

export default class TermGradeReleaseHelpModal extends LightningModal {
	
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
    * @descripton To get credit transfer application object info
    */
    @wire(getObjectInfo, {objectApiName: CREDIT_TRANSFER_APPLICATION_OBJECT})
    creditTransferApplicationObjInfo;

    /**
     * @description Return study unit object label
     */
    get studyUnitLabel() {
        return this.studyUnitObjInfo.data ? this.studyUnitObjInfo.data.labelPlural : '';
    }

    /**
     * @description Return study offering object label
     */
    get studyOfferingLabel() {
        return this.studyOfferingObjInfo.data ? this.studyOfferingObjInfo.data.labelPlural : '';
    }

    /**
     * @description Return credit transfer application object label
     */
    get creditTransferApplicationLabel() {
        return this.creditTransferApplicationObjInfo.data ? this.creditTransferApplicationObjInfo.data.labelPlural : '';
    }

    /**
     * @description Return modal title text Help
     */
    get headerLabel() {
        return HELP_LABEL;
    }

    /**
     * @description Return loading label
     */
    get loadingLabel() {
        return LOADING_LABEL;
    }

    /**
     * @description Return close label
     */
    get closeButtonLabel() {
        return CLOSE_LABEL;
    }

    /**
     * @description Return termGradeReleaseOverviewHelp
     */
    get termGradeReleaseOverviewHelp() {
        return TERM_GRADE_RELEASE_OVERVIEW_HELP;
    }

    /**
     * @description Return termGradeReleaseStep1Help
     */
    get termGradeReleaseStep1Help() {
        return TERM_GRADE_RELEASE_STEP1_HELP.format([this.studyUnitLabel, this.studyOfferingLabel, MANUAL_SELECTION_LABEL]);
    }

    /**
     * @description Return termGradeReleaseStep2Help
     */
    get termGradeReleaseStep2Help() {
        return TERM_GRADE_RELEASE_STEP2_HELP.format([this.studyOfferingLabel, this.studyUnitLabel, MANUAL_SELECTION_LABEL]);
    }

    /**
     * @description Return termGradeReleaseStep3Help
     */
    get termGradeReleaseStep3Help() {
        return TERM_GRADE_RELEASE_STEP3_HELP.format([this.creditTransferApplicationLabel]);
    }
	
    /**
     * @description Handle close click to close the modal
     * @param {*} event 
     */
    handleCloseClick(event) {
        this.close();
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
        logInfo('TermGradeReleaseHelpModal', anything, this.enableDebugMode, isJson);
    }
	
}