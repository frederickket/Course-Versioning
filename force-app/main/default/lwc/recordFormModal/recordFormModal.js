/**
 * @Author 		WDCi (XW)
 * @Date 		Nov 2025
 * @group 		Record Form Modal
 * @Description Edit or View Record Form in Modal
 * @changehistory
 * ISS-002670 11-11-2025 XW - new component
 */
import { api, wire, track } from 'lwc';
import { promptInfo, promptError, promptWarning, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';
import { initCacheIdx } from 'c/lwcUtil';
import { customLabels } from 'c/labelLoader';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';

import LightningModal from 'lightning/modal';
//refresh module
import { refreshApex } from '@salesforce/apex';
import { RefreshEvent, registerRefreshHandler, unregisterRefreshHandler } from 'lightning/refresh';

export default class RecordFormModal extends LightningModal {
	
	//configurable attributes
    @api headerLabel;

    @api columns = 2;
    @api density = "auto";
    @api fields;
    @api layoutType = "Full";
    @api mode;
    @api objectApiName;
    @api recordId;
    @api recordTypeId;

	@api enableDebugMode = false;

	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false
	loadedLists = 0;
    selectedRecordTypeId;
    @track recordTypeIdIsSelected = false;
	
    @track objectInfoResult;
    @track objectInfoResponse;
    //refresh handler
    refreshHandlerID;

    //local cache idx to force rerendering
    _cacheIdx;

	//js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'jquery', 'tooltips'
    modules = [];
	
    get loadingLabel() {
        return customLabels.LOADING_LABEL;
    }

    @wire(getObjectInfo, { objectApiName:'$objectApiName' })
    wiredObjectInfo(result) {
        this.objectInfoResult = result;
        this.objectInfoResponse = null;
        if(result.data) {
            this.objectInfoResult = result;
            this.objectInfoResponse = result.data;
        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    //show record type radio group if record type is not selected and is creating a new record
    get showRecordTypeSelection(){
        return !this.recordTypeIdIsSelected && !this.recordId && Object.keys(this.recordTypeOptions).length > 0;
    }

    //options for radio group (remove master if length > 1)
    get recordTypeOptions() {
        let result = [];
        if(this.objectInfoResponse){
            for (let recordTypeId of Object.keys(this.objectInfoResponse?.recordTypeInfos)){
                let recordType = this.objectInfoResponse?.recordTypeInfos[recordTypeId];
                if(!recordType.master && recordType.available) {
                    result.push({label: recordType.name, value: recordTypeId})
                }
            }
        }
        return result;
    }

    get targetRecordTypeId() {
        return this.recordTypeId ?? this.selectedRecordTypeId;
    }

    //next label for button
    get nextLabel() {
        return customLabels.NEXT_LABEL;
    }

    //previous label for button
    get previousButtonLabel(){
        return customLabels.PREVIOUS_LABEL;
    }
    
    //cancel label for button
    get cancelButtonLabel(){
        return customLabels.CANCEL_LABEL;
    }
    
    //save label for button
    get saveButtonLabel(){
        return customLabels.SAVE_LABEL;
    }

    //handle record type selection
    handleRecordTypeChange(event) {
        this.selectedRecordTypeId = event.detail.value;
    }

    handleNext() {
        if(this.selectedRecordTypeId) {
            this.recordTypeIdIsSelected = true;
        }
    }

    handleSuccess(event) {
        promptSuccess(customLabels.SUCCESS_LABEL, customLabels.RECORD_SAVED_LABEL);
        this.close({
            operation: "created",
            id: event.detail.id
        });
    }

    handleCancel(event) {
        event.preventDefault();
        this.close({
            operation: "cancel"
        });
    }

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
     * @descripton connected callback
     */
    connectedCallback(){
		this.refreshHandlerID = registerRefreshHandler(this, this.refreshData);
        this._cacheIdx = initCacheIdx();
	}
	
    /**
     * @descripton disconnected callback
     */
	disconnectedCallback() {
		unregisterRefreshHandler(this.refreshHandlerID);
	}

    /**
     * @description Refresh data
     */
    refreshData() {
        this.consoleLog('refreshData');
        
        //update the cacheIdx if you need to force the wire method to get new data from apex
        this._cacheIdx = initCacheIdx();

        return new Promise((resolve) => {
            resolve(true);
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
        logInfo('RecordFormModal', anything, this.enableDebugMode, isJson);
    }
	
}