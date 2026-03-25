/**
 * @Author 		WDCi (XW)
 * @Date 		June 2025
 * @group 		Requirement Checklist
 * @Description Requirement Checklist modal for field update action
 * @changehistory
 * ISS-002128 30-06-2025 XW - new cmp
 */
import { LightningElement, api, wire, track } from 'lwc';
import { promptInfo, promptError, promptWarning, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';
import { customLabels } from 'c/labelLoader';
import LightningModal from 'lightning/modal';

//Apex methods
import ctrlGetObjectNameAndRecord from '@salesforce/apex/REDU_RequirementChecklistField_LCTRL.getObjectNameAndRecord';

import SAVE_AND_MARK_AS_DONE_LABEL from '@salesforce/label/c.Save_And_Mark_As_Done';


const RESPONSE_RECORD_ID = 'RESPONSE_RECORD_ID';
const RESPONSE_OBJECT_API_NAME = 'RESPONSE_OBJECT_API_NAME';

export default class RequirementChecklistFieldUpdateModal extends LightningModal {
	
	//configurable attributes
    @api headerLabel;
    @api irqId;
    @api objectFields;
    @api objectRelationField;
    
	@api enableDebugMode = false;
	
	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false
	loadedLists = 0;
    buttonClicked;

    buttonSave = 'buttonSave';
    buttonSaveDone = 'buttonSaveDone';

    //wire attribute
    objectNameAndRecordResult;
    objectNameAndRecordResponse;
	
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
     * @description remove the spinner after record edit form is loaded
     */
    handleLoading() {
        this.consoleLog('handleLoading');
        this.toggleSpinner(-1);
    }
	
    /**
     * @description get the object name and record id
     */
    @wire(ctrlGetObjectNameAndRecord, {
        irqId: "$irqId",
        objectRelationField: '$objectRelationField'
    })
    wireGetObjectNameAndRecord(result) {
        
        this.objectNameAndRecordResult = result;
        this.objectNameAndRecordResponse = null;

        if (result.data) {
            this.objectNameAndRecordResponse = JSON.parse(result.data.responseData);
            this.consoleLog(this.objectNameAndRecordResponse, true);
        } else if (result.error) {
            promptError(customLabels.ERROR_LABEL, getErrorMessage(result.error));
        }

    }

    /**
     * @description the object name of the record to be updated
     */
    get targetObjectName() {
        return this.objectNameAndRecordResponse?.[RESPONSE_OBJECT_API_NAME];
    }

    /**
    * @description the record id of the record to be updated
    */
    get targetRecordId() {
        return this.objectNameAndRecordResponse?.[RESPONSE_RECORD_ID];
    }

    /**
    * @description the fields to be updated in list form
    */
    get objectFieldList() {
        return this.objectFields ? this.objectFields.split(';') : [];
    }
    
    /**
    * @description close label
    */
    get closeLabel() {
        return customLabels.CLOSE_LABEL;
    }

    /**
    * @description save label
    */
    get saveLabel() {
        return customLabels.SAVE_LABEL;
    }

    /**
    * @description save and mark as done label
    */
    get saveAndMarkAsDoneLabel() {
        return SAVE_AND_MARK_AS_DONE_LABEL;
    }

    /**
     * @description handle the save click buttons and validate error before submitting the form
     */
    handleSaveClick(event){
        this.consoleLog('handleSaveClick');
        //validate field
        const fields = this.template.querySelectorAll('lightning-input-field');
        let noError = true;
        for(let field of fields) {
            if(!field.reportValidity()) {
                noError = false;
                break
            }
        }

        if(!noError) {
            this.consoleLog(`error occurs`);
            return;
        }

        this.consoleLog(`buttonClicked = ${event.target.value}`);
        this.toggleSpinner(1);
        this.buttonClicked = event.target.value;
        const btn = this.template.querySelector('.requirementchecklistfieldupdatemodal-hiddensubmitbutton');
        if(btn) {
            btn.click();
        }
    }

    /**
     * @description handle when form is saved successfully (close the modal)
     */
    handleSaveSuccess(event) {
        this.consoleLog('handleSaveSuccess');
        this.toggleSpinner(-1);
        const result = event.detail;
        this.close({
            operation: this.buttonClicked,
            eventData: result
        });
    }

    /**
     * @description handle error occurs when trying to save the form (prompt error)
     */
    handleSaveError(event) {
        
        this.consoleLog('handleSaveError');
        this.consoleLog(getErrorMessage(event.detail));
        promptError(customLabels.ERROR_LABEL, getErrorMessage(event.detail));
        this.toggleSpinner(-1);
    }

    /**
     * @description handle close click
     */
    handleCloseClick() {
        this.close({
            operation: 'cancel'
        });
    }

    /**
     * @description add the spinner before record edit form is loaded
     */
    connectedCallback(){
        this.toggleSpinner(1);
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
        logInfo('RequirementChecklistFieldUpdateModal', anything, this.enableDebugMode, isJson);
    }
	
}