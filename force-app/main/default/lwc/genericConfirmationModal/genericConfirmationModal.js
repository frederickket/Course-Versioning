/**
 * @Author 		WDCi (Lean)
 * @Date 		Oct 2023
 * @group 		Util
 * @Description Generic confirmation modal
 * @changehistory
 * ISS-001752 24-10-2023 Lean - new lwc
 */
import { LightningElement, api, wire, track } from 'lwc';
import LightningModal from 'lightning/modal';
import { promptInfo, promptError, promptWarning, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';

import LOADING_LABEL from '@salesforce/label/c.Loading';

export default class GenericConfirmationModal extends LightningModal {
	
	//configurable attributes
    @api modalTitle;
    @api confirmationText1;
    @api confirmationText2;
    @api confirmationText3;
    
    @api showSubmitButton;
    @api submitButtonLabel;
    @api showCancelButton;
    @api cancelButtonLabel;

    @api eventSource;
    @api eventData;
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
		this.consoleLog(this.eventSource);
        this.consoleLog(this.eventData);
	}
	
    /**
     * @descripton disconnected callback
     */
	disconnectedCallback() {
		
	}

    /**
     * @description Return modal title
     */
    get headerLabel() {
        return this.modalTitle;
    }

    /**
     * @description Return loading label
     */
    get loadingLabel() {
        return LOADING_LABEL;
    }
    
    /**
     * @description Handle cancel click to close the modal with operation = cancel, eventSource and eventData
     * @param {*} event 
     */
    handleCancelClick(event) {
        this.close({
            operation: 'cancel',
            eventSource: this.eventSource,
            eventData: this.eventData
        });
    }

    /**
     * @description Handle submit click to close the modal with operation = submit, eventSource and eventData
     * @param {*} event 
     */
    handleSubmitClick(event) {
        this.close({
            operation: 'submit',
            eventSource: this.eventSource,
            eventData: this.eventData
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
        logInfo('genericConfirmationModal', anything, this.enableDebugMode, isJson);
    }
	
}