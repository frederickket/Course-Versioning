/**
 * @Author 		WDCi (Sueanne)
 * @Date 		May 2024
 * @group 		Util
 * @Description Major Minor Enrollment modal
 * @changehistory
 * ISS-001924 24-05-2024 Sueanne - new component
 */
import { LightningElement, api, wire, track } from 'lwc';
import LightningModal from 'lightning/modal';
import { promptInfo, promptError, promptWarning, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';

import LOADING_LABEL from '@salesforce/label/c.Loading';

export default class ipePathwayChildEnrollmentModal extends LightningModal {

    //configurable attributes
    @api modalTitle;
    
    @api showApplyButton;
    @api applyButtonLabel;
    @api showCancelButton;
    @api cancelButtonLabel;

    @api eventSource;
    @api eventData;
	@api enableDebugMode = false;
	
	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false
	loadedLists = 0;
	
    //other attribute
    enrollDataBeforeUpdate;
 
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

        this.enrollDataBeforeUpdate = this.eventData;
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
     * @description whether to enable apply button
     */
    get isEnableApplyBtn() {
        if(this.enrollDataBeforeUpdate && this.eventData){
            return JSON.stringify(this.enrollDataBeforeUpdate) === JSON.stringify(this.eventData);
        }
        return false;
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
     * @description Handle submit click to close the modal with operation = apply, eventSource and eventData
     * @param {*} event 
     */
    handleApplyClick(event) {
        this.close({
            operation: 'apply',
            eventSource: this.eventSource,
            eventData: this.eventData
        });
    }

    /**
     * @description Handle enrollment button click to change isEnrolled
     * @param {*} event 
     */
    handleEnrollBtn(event) {
        const spoId = event.target.value;

        let updatedArr = this.eventData.map(wrapper => {
            if (spoId === wrapper.studyPlan.Id) {
                // Update isEnrolled
                return { ...wrapper, isEnrolled: !wrapper.isEnrolled };
            }
            return wrapper;
        });

        this.eventData = updatedArr;
    }

    /**
     * @description Return spo enrollment array for display in modal
     */
    get spoDisplayArray() {
        if (this.eventData) {
            return this.eventData.map(wrapper => ({
                Id: wrapper.studyPlan.Id,
                name: wrapper.studyPlan.Name,
                isEnrolled: wrapper.isEnrolled
            }));
        }
        return null;
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
        logInfo('ipePathwayChildEnrollmentModal', anything, this.enableDebugMode, isJson);
    }
}