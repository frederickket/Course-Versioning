/**
 * @Author 		WDCi (Lean)
 * @Date 		Jan 2025
 * @group 		Job Queue Framework
 * @Description Cancel job quick action
 * @changehistory
 * ISS-002219 06-01-2025 Lean - cancel job quick action
 */
import { LightningElement, api, wire, track } from 'lwc';
import { promptInfo, promptError, promptWarning, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import { customLabels } from 'c/labelLoader';
import { CloseActionScreenEvent } from 'lightning/actions';

import ctrlCancelJob from '@salesforce/apex/REDU_JqhCancelJob_LCTRL.cancelJob';

import CONFIRMATION_TEXT from '@salesforce/label/c.Job_Cancel_Confirmation_Text';
import CONFIRMATION_TITLE from '@salesforce/label/c.Job_Cancel_Confirmation';

export default class JqhCancelJob extends LightningElement {
	
    //LWC quick actions don’t pass in recordId in connectedCallback(), this is official workaround
    _recordId;

    @api
    get recordId() {
        return this._recordId;
    }

    set recordId(recordId) {
        if (recordId !== this._recordId) {
            this._recordId = recordId;
        }
    }

	//configurable attributes
	@api enableDebugMode = false;
	
	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false
	loadedLists = 0;
	
    //wire attribute
    sampleWireResult;
    sampleResponse;

	//labels
	label = customLabels;
	
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
        this.consoleLog(this._recordId);
	}
	
    /**
     * @descripton disconnected callback
     */
	disconnectedCallback() {
		
	}

    /**
     * @description Return confirmation title
     */
    get confirmationTitle() {
        return CONFIRMATION_TITLE;
    }

    /**
     * @description Return confirmation text
     */
    get confirmationText() {
        return CONFIRMATION_TEXT;
    }

    /**
     * @description Handle cancel
     */
    handleCancelClick() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    /**
     * @description Handle cancel
     */
    async handleConfirmClick() {
        await this.cancelJob();
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    /**
     * @description Cancel job
     */
    async cancelJob() {

        this.toggleSpinner(1);

        ctrlCancelJob({
            jobQueueId: this._recordId
        })
        .then(cancelResult => {
            this.toggleSpinner(-1);
            promptSuccess(this.label.SUCCESS_LABEL, cancelResult.message);
            
            this.consoleLog(cancelResult, true);

            getRecordNotifyChange([{recordId: this._recordId}]);
        })
        .catch(error => {
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
            this.toggleSpinner(-1);
        });

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
        logInfo('JqhCancelJob', anything, this.enableDebugMode, isJson);
    }
	
}