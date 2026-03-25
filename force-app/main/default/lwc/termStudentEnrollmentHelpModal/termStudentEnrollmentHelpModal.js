/**
 * @Author 		WDCi ()
 * @Date 		Jan 2024
 * @group 		
 * @Description 
 * @changehistory
 * ISS-XXXXXX dd-mm-yyyy name - description
 */
import { api } from 'lwc';
import LightningModal from 'lightning/modal';

import { logInfo } from 'c/loggingUtil';

import CLOSE_LABEL from '@salesforce/label/c.Close';
import LOADING_LABEL from '@salesforce/label/c.Loading';
import HELP_LABEL from '@salesforce/label/c.Help';

import TERM_STUDENT_ENROLLMENT_OVERVIEW_HELP from '@salesforce/label/c.Term_Student_Enrollment_Overview_Help';
import TERM_STUDENT_ENROLLMENT_STEP1_HELP from '@salesforce/label/c.Term_Student_Enrollment_Step1_Help';
import TERM_STUDENT_ENROLLMENT_STEP2_HELP from '@salesforce/label/c.Term_Student_Enrollment_Step2_Help';
import TERM_STUDENT_ENROLLMENT_STEP3_HELP from '@salesforce/label/c.Term_Student_Enrollment_Step3_Help';
import TERM_STUDENT_ENROLLMENT_STEP4_HELP from '@salesforce/label/c.Term_Student_Enrollment_Step4_Help';

export default class TermStudentEnrollmentHelpModal extends LightningModal {
	
	//configurable attributes
	@api enableDebugMode = false;
	
	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false
	loadedLists = 0;
		
	//js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'jquery', 'tooltips'
    modules = [];
	
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
     * @description Return TERM_STUDENT_ENROLLMENT_OVERVIEW_HELP
     */
    get termStudentOverviewHelp() {
        return TERM_STUDENT_ENROLLMENT_OVERVIEW_HELP;
    }

    /**
     * @description Return termStudentEnrollmentStep1Help
     */
    get termStudentEnrollmentStep1Help() {
        return TERM_STUDENT_ENROLLMENT_STEP1_HELP;
    }

    /**
     * @description Return termStudentEnrollmentStep2Help
     */
    get termStudentEnrollmentStep2Help() {
        return TERM_STUDENT_ENROLLMENT_STEP2_HELP;
    }

    /**
     * @description Return termStudentEnrollmentStep3Help
     */
    get termStudentEnrollmentStep3Help() {
        return TERM_STUDENT_ENROLLMENT_STEP3_HELP;
    }

    /**
     * @description Return termStudentEnrollmentStep4Help
     */
    get termStudentEnrollmentStep4Help() {
        return TERM_STUDENT_ENROLLMENT_STEP4_HELP;
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
        logInfo('TermStudentEnrollmentHelpModal', anything, this.enableDebugMode, isJson);
    }
	
}