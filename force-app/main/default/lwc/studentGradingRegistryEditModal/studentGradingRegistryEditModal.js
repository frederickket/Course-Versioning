/**
 * @Author 		WDCi (CM)
 * @Date 		Aug 2024
 * @group 		Grade Management
 * @Description Student Grading Wizard - Modal for adding Notes to a student's IGI record.
 * @changehistory
 * ISS-001918 23-08-2024 CM - new class
 * ISS-002259 20-03-2025 Jordan - allow admin to configure more fields in the note screen
 */
import { api, wire, track } from 'lwc';
import LightningModal from 'lightning/modal';
import { promptError } from 'c/toasterUtil';
import { logInfo, getErrorMessage } from 'c/loggingUtil';
import { getFormDataFieldOnChangeValue } from 'c/lwcUtil';

import { customLabels } from 'c/labelLoader';

import ctrlGetFields from '@salesforce/apex/REDU_StudentGradingRegistry_LCTRL.getFields'; //ISS-002259

export default class StudentGradingRegistryEditModal extends LightningModal {
	
	//configurable attributes
    @api modalTitle;

    @api igiNotes;
    @api individualGradeItemNotesFieldSetName; //ISS-002259

    //ISS-002259
    @api
    set draftIgiObj(val) {
        this._draftIgiObj = JSON.parse(JSON.stringify(val));

        this.consoleLog('set _draftIgiObj');
        this.consoleLog(this._draftIgiObj, true);
    }

    //ISS-002259
    get draftIgiObj() {
        return this._draftIgiObj;
    }

	@api enableDebugMode = false;
	
	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false
	loadedLists = 0;
    updatedNotes = false;
    newNotes;

    //wire attributes
    igiFieldsResult; //ISS-002259
    igiFieldsResponse; //ISS-002259

    @track _draftIgiObj; //ISS-002259
		
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

    _igiFieldsData = []; //ISS-002259

    /**
     * @description ISS-002259 Set individual grade item fields
     */
    set igiFieldsData(val) {
        if (val) {
            this._igiFieldsData = JSON.parse(JSON.stringify(val));

            for (let field of this._igiFieldsData) {
                if (Object.hasOwn(this.draftIgiObj, field.fieldName)) {
                    field.value = this.draftIgiObj[field.fieldName];
                }
            }
        } else {
            this._igiFieldsData = [];
        }
    }

    /**
     * @description ISS-002259 Return individual grade item field objects
     */
    get igiFieldsData() {
        return this._igiFieldsData;
    }

    /**
     * @description ISS-002259 Return individual grade item fields array
     */
    get igiFields() {
        let fields = [];
        for (let field of this.igiFieldsData) {
            fields.push(field.fieldName);
        }

        return fields;
    }

    /**
     * @description ISS-002259 Get fields from field set
     */
    @wire(ctrlGetFields, {
        fieldSetName: '$individualGradeItemNotesFieldSetName',
        objectName: 'reduivy__Individual_Grade_Item__c'
    })
    wiredIgiFields(result) {
        this.igiFieldsResult = result;
        this.igiFieldsResponse = null;

        if (result.data) {
            this.igiFieldsResponse = JSON.parse(result.data.responseData);
            this.igiFieldsData = this.igiFieldsResponse;

            this.consoleLog(this.igiFieldsResponse, true);
        } else if (result.error) {
            promptError(customLabels.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    /**
     * @description ISS-002259 Handle form field change
     */
    handleFieldChange(event) {
        let dataFieldName = event.target.fieldName;
        let dataDisplayType = event.target.dataset.displaytype;
        let dataFieldValue = getFormDataFieldOnChangeValue(dataDisplayType, event.detail);
        
        this._draftIgiObj[dataFieldName] = dataFieldValue;
        this.updatedNotes = true;

        this.consoleLog('handleFieldChange');
        this.consoleLog(dataFieldValue);
        this.consoleLog(this.draftIgiObj, true);
    }
    
    /**
     * @description Handle cancel click to close the modal with operation = cancel, eventSource and eventData
     * @param {*} event 
     */
    handleCancelClick() {
        this.close();
    }

    /**
     * @description Handle save click to close the modal with operation = save, eventSource and eventData
     * @param {*} event 
     */
    handleDoneClick() {
        this.close({
            operation: 'done',
            updatedNotes: this.updatedNotes,
            draftIgiObj: this.draftIgiObj //ISS-002259
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
        logInfo('StudentGradingRegistryEditModal', anything, this.enableDebugMode, isJson);
    }
	
}