/**
 * @Author 		WDCi (Lean)
 * @Date 		Oct 2023
 * @group 		Enrollment Wizard
 * @Description Help modal for enrollment wizard
 * @changehistory
 * ISS-001752 24-10-2023 Lean - new lwc
 * ISS-002401 22-04-2025 Lean - added new help content
 */
import { LightningElement, api, wire, track } from 'lwc';
import LightningModal from 'lightning/modal';
import { promptInfo, promptError, promptWarning, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';

import CLOSE_LABEL from '@salesforce/label/c.Close';
import LOADING_LABEL from '@salesforce/label/c.Loading';
import HELP_LABEL from '@salesforce/label/c.Help';
import ACTION_LABEL from '@salesforce/label/c.Action';
import INDICATOR_LABEL from '@salesforce/label/c.Indicator';
import LOCKED_LABEL from '@salesforce/label/c.Locked';
import ENROLLMENT_LOCKED_MSG_LABEL from '@salesforce/label/c.Enrollment_Is_Locked_For_The_Academic_Term';
import MISSED_FAILED_UNIT_LABEL from '@salesforce/label/c.Missed_Failed_Study_Unit_Warning';

export default class IpePathwayHelpModal extends LightningModal {
	
    //configurable attributes - enrollment button icon and label
    @api preEnrollButtonIconName;
    @api preEnrollButtonLabel;
    @api withdrawPreEnrollButtonIconName;
    @api withdrawPreEnrollButtonLabel;
    @api enrollButtonIconName;
    @api enrollButtonLabel;
    @api unenrollButtonIconName;
    @api unenrollButtonLabel;
    @api unenrollRequestButtonIconName;
    @api unenrollRequestButtonLabel;
    @api waitlistButtonIconName;
    @api waitlistButtonLabel;
    @api withdrawWaitlistButtonIconName;
    @api withdrawWaitlistButtonLabel;

	//configurable attributes
	@api enableDebugMode = false;
	
	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false;
	loadedLists = 0;
		
	//js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'tooltips'
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
     * @description Return action label
     */
    get actionLabel() {
        return ACTION_LABEL;
    }

    /**
     * @description Return indicator label
     */

    get indicatorLabel() {
        return INDICATOR_LABEL;
    }

    /**
     * @description Return locked label
     */
    get lockedLabel() {
        return LOCKED_LABEL;
    }

    /**
     * @description Return enrollment locked message
     */
    get enrollmentLockedMsgLabel() {
        return ENROLLMENT_LOCKED_MSG_LABEL;
    }

    /**
     * @description Return missed/failed unit message
     */
    get missedFailedUnitMsgLabel() {
        return MISSED_FAILED_UNIT_LABEL;
    }
    
    /**
     * @description Handle close click to close the modal
     * @param {*} event 
     */
    handleCloseClick(event) {
        this.close({});
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
        logInfo('ipePathwayHelp', anything, this.enableDebugMode, isJson);
    }
	
}