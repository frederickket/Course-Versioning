/**
 * @Author 		WDCi (Lean)
 * @Date 		July 2024
 * @group 		Attendance
 * @Description Attendance taking wizard for faculty
 * @changehistory
 * ISS-001919 31-07-2024 Lean - new wizard
 */
import { api, wire, track } from 'lwc';
import LightningModal from 'lightning/modal';
import { promptInfo, promptError, promptWarning, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';
import { getFormDataFieldOnChangeValue } from 'c/lwcUtil';

import { customLabels } from 'c/labelLoader';

import ctrlGetFields from '@salesforce/apex/REDU_StudentAttendanceRegistry_LCTRL.getFields';

export default class StudentAttendanceRegistryEditModal extends LightningModal {
	
	//configurable attributes
    @api modalTitle;
    @api studyEventRelationEditFieldSetName;
    
    @api
    set draftSerObj(val) {
        this._draftSerObj = JSON.parse(JSON.stringify(val));

        this.consoleLog('set _draftSerObj');
        this.consoleLog(this._draftSerObj, true);
    }

    get draftSerObj() {
        return this._draftSerObj;
    }

	@api enableDebugMode = false;
	
	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false
	loadedLists = 0;
	
    //wire attributes
    serFieldsResult;
    serFieldsResponse;

    @track _draftSerObj;

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
     * @description Return modal title
     */
    get headerLabel() {
        return this.modalTitle;
    }

    /**
     * @description Return loading label
     */
    get loadingLabel() {
        return customLabels.LOADING_LABEL;
    }

    /**
     * @description Return cancel label
     */
    get cancelButtonLabel() {
        return customLabels.CANCEL_LABEL;
    }

    /**
     * @description Return done label
     */
    get doneButtonLabel() {
        return customLabels.DONE_LABEL;
    }

    _serFieldsData = [];

    /**
     * @description Set study event relation fields
     */
    set serFieldsData(val) {
        if (val) {
            this._serFieldsData = JSON.parse(JSON.stringify(val));

            for (let field of this._serFieldsData) {
                if (Object.hasOwn(this.draftSerObj, field.fieldName)) {
                    field.value = this.draftSerObj[field.fieldName];
                }
            }
        } else {
            this._serFieldsData = [];
        }
    }

    /**
     * @description Return study event relation field objects
     */
    get serFieldsData() {
        return this._serFieldsData;
    }

    /**
     * @description Return study event relation fields array
     */
    get serFields() {
        let fields = [];
        for (let field of this.serFieldsData) {
            fields.push(field.fieldName);
        }

        return fields;
    }

    /**
     * @description Get fields from field set
     */
    @wire(ctrlGetFields, {
        fieldSetName: '$studyEventRelationEditFieldSetName',
        objectName: 'reduivy__Study_Event_Relation__c'
    })
    wiredSerFields(result) {
        this.serFieldsResult = result;
        this.serFieldsResponse = null;

        if (result.data) {
            this.serFieldsResponse = JSON.parse(result.data.responseData);
            this.serFieldsData = this.serFieldsResponse;

            this.consoleLog(this.serFieldsResponse, true);
        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    /**
     * @description Handle form field change
     */
    handleFieldChange(event) {
        let dataFieldName = event.target.fieldName;
        let dataDisplayType = event.target.dataset.displaytype;
        let dataFieldValue = getFormDataFieldOnChangeValue(dataDisplayType, event.detail);
        
        this._draftSerObj[dataFieldName] = dataFieldValue;

        this.consoleLog('handleFieldChange');
        this.consoleLog(dataFieldValue);
        this.consoleLog(this.draftSerObj, true);
    }

    /**
     * @description Handle close click
     */
    handleCancelClick() {
        this.close({operation: 'close'});
    }

    /**
     * @description Handle close click
     */
    handleDoneClick() {
        this.close({
            operation: 'submit',
            draftSerObj: this.draftSerObj
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
        logInfo('StudentAttendanceRegistryEditModal', anything, this.enableDebugMode, isJson);
    }
	
}