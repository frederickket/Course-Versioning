/**
 * @Author 		WDCi (XW)
 * @Date 		Nov 2024
 * @group 		Record Edit Modal
 * @Description A modal to edit a record based on selected field set
 * @changehistory
 * ISS-002104 11-11-2024 XW - create new class
 * ISS-002322 17-04-2025 XW - prompt an error if no fields are selected in the field set
 * ISS-002654 03-10-2025 Lean - Column number shared util
 */
import { api, wire, track } from 'lwc';
import { promptError } from 'c/toasterUtil';
import { getErrorMessage, logInfo } from 'c/loggingUtil';
import { customLabels } from 'c/labelLoader';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getColumnSize, getFormDataFieldOnChangeValue } from 'c/lwcUtil';

import LightningModal from 'lightning/modal';

import ctrlGetFieldSetMembers from '@salesforce/apex/REDU_RecordEditModal_LCTRL.getFieldSetMembers';

import NO_FIELDS_LABEL from '@salesforce/label/c.No_Fields_In_Field_Set'
import CREATE_NEW_PARENT_LABEL from '@salesforce/label/c.Create_New_Record'
import INVALID_OBJECT_FIELD_SET_LABEL from '@salesforce/label/c.Invalid_Object_Field_Set_Error'

export default class RecordEditModal extends LightningModal {
	
	//configurable attributes
    @api headerLabel;
	@api enableDebugMode = false;

    @api objectApiName;
    
    @api fieldSetName;
    @api editFormColumnNo;
    @api enableNewParentCreation = false;
    @api defaultValue;
    
    //create only
    recordTypeList;

    //edit only
    @api recordId;

	
	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false
	loadedLists = 0;
    recordTypeIsSelected = false;
    selectedRecordTypeId;
    lookupFieldObjectName;
    lookupFieldRecordTypeId;
    @track customLookupFieldValue = {};
    
    //wired
    @track objectInfoResult;
    @track objectInfoData;
    @track fieldSetMembersResult;
    @track fieldSetMembersResponse;
	
	
	//js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'jquery', 'tooltips'
    modules = [];

    //get field set member
    @wire(ctrlGetFieldSetMembers, { objName:'$objectApiName', fieldSetName: '$fieldSetName' })
    wiredFieldSetMembers(result){
        this.fieldSetMembersResult = result;
        this.fieldSetMembersResponse = null;
        
        if(result.data){
            this.fieldSetMembersResponse = JSON.parse(result.data.responseData);
            if(this.fieldSetMembersResponse.length === 0){
                promptError(customLabels.ERROR_LABEL, NO_FIELDS_LABEL.format([this.fieldSetName]));
            }

            if(this.fieldSetMembersResponse) {
                for(let field of this.fieldSetMembersResponse) {
                    field.isReference = field.displayType === 'REFERENCE';

                    field.defaultValue = this.defaultValue?.[field.fieldName] ?? undefined;
                }
            }
        
        } else if (result.error) {
            promptError(customLabels.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    @wire(getObjectInfo,{objectApiName: '$objectApiName'})
    wiredObjectInfo(result) {
        this.objectInfoResult = result;
        if(result.data) {
            this.objectInfoData = result.data;
        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    // Child Object Label
    get childObjectLabel() {
        return this.objectInfoData?.label || this.objectApiName;
    }

    // Check whether the field set name is passed
    get showInvalidFieldSetNameMessage() {
        return !this.fieldSetName;
    }

    // Invalid Field Set Name Message
    get invalidFieldSetNameMessage() {
        return INVALID_OBJECT_FIELD_SET_LABEL.format(['', this.childObjectLabel]);
    }

    //show record type radio group if record type is not selected and is creating a new record
    get showRecordTypeSelection(){
        return !this.recordTypeIsSelected && !this.recordId && Object.keys(this.recordTypeOptions).length > 0;
    }

    //options for radio group (remove master if length > 1)
    get recordTypeOptions() {
        let result = [];
        if(this.objectInfoData){
            for (let recordTypeId of Object.keys(this.objectInfoData?.recordTypeInfos)){
                let recordType = this.objectInfoData?.recordTypeInfos[recordTypeId];
                if(!recordType.master && recordType.available) {
                    result.push({label: recordType.name, value: recordTypeId})
                }
            }
        }
        return result;
    }

    //next label for button
    get nextLabel() {
        return customLabels.NEXT_LABEL;
    }
    
    //calculate the size of each field
    get defaultInputSize(){
        return getColumnSize(this.editFormColumnNo);
    }

    //fields to be displayed in the form
    get fields(){
        if(this.fieldSetMembersResponse) {
            return this.fieldSetMembersResponse;
        }
        return [];
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

    get loadingLabel() {
        return customLabels.LOADING_LABEL;
    }

    /**
     * @description return 
     */
    get showPreviousButton() {
        return this.recordId && this.recordTypeOptions.length > 0;
    }

    /**
     * @description Return true if the button should be clickable
     */
    get hasFields() {
        
        if (this.fields && this.fields.length > 0) {
            return true;
        }

        return false;
    }

    //disable save or next button if no fields are set in the field set or is loading
    get disableButtons() {
        return this.isLoading || !this.hasFields;
    }

    get createNewParentLabel() {
        return CREATE_NEW_PARENT_LABEL;
    }

    //go back to record type selection page
    handlePreviousClick(){
        if(this.selectedRecordTypeId) {
            this.recordTypeIsSelected = false;
        }
    }

    //handle record type selection
    handleRecordTypeChange(event) {
        this.selectedRecordTypeId = event.detail.value;
    }

    //enter the value of fields after record type is selected
    handleNextClick() {
        if(this.selectedRecordTypeId) {
            this.recordTypeIsSelected = true;
        }
    }

    handleLookupChange(event) {
        let parentRecordId = event.detail.value;
        let lookupFieldName = event.detail.lookupFieldName;
        this.customLookupFieldValue[lookupFieldName] = parentRecordId;
    }

    handleOnLoad(event) {
        this.toggleSpinner(1);
        let fields = event?.detail?.records?.[this.recordId]?.fields;
        let customLookupFieldElements = Object.values(this.template.querySelectorAll('c-custom-lookup-field'));
        if(fields) {
            for(let fieldName of Object.keys(fields)) {
                if(fieldName.endsWith('__r') || fieldName.endsWith('Id')) {
                    let targetFieldName = fieldName.endsWith('__r') ? fieldName.slice(0, -1) + 'c' : fieldName;
                    let fieldValue = event.detail.records?.[this.recordId]?.fields?.[targetFieldName].value
                    let element = customLookupFieldElements.find(ele => ele.lookupFieldName === targetFieldName);
                    if(element) {
                        element.setSelectedRecord(fieldValue);
                    }
                }
            }
        }
        this.toggleSpinner(-1);
    }

    //handle when user click on save
    handleSaveClick(event){
        this.template.querySelector('.editFormSave').click();
    }

    handleSaveSubmit(event) {

        event.preventDefault();


        let element = [...this.template.querySelectorAll('[data-save-required="true"]')];
        let requiredFieldsValid = element.reduce((validSoFar, inputCmp) => {

            this.consoleLog('validateRequiredDataFields :: ' + inputCmp.name + ' - ' + inputCmp.value);
            return validSoFar && inputCmp.reportValidity();

        }, true);

        if(!requiredFieldsValid){
            return;
        }

        //add all custom lookup field value
        const fieldsToBeSubmitted = event.detail.fields;
        for(const [key, value] of Object.entries(this.customLookupFieldValue)) {
            fieldsToBeSubmitted[key] = value;
        }

        //add default values if the default values is not in the form
        if(this.defaultValue && typeof this.defaultValue === 'object' && Object.keys(this.defaultValue).length > 0) {
            for(let defaultFieldName of Object.keys(this.defaultValue)) {
                if(!Object.keys(fieldsToBeSubmitted).includes(defaultFieldName)) {
                    fieldsToBeSubmitted[defaultFieldName] = this.defaultValue[defaultFieldName];
                }
            }
        }

        this.toggleSpinner(1);
        this.template.querySelector('lightning-record-edit-form').submit(fieldsToBeSubmitted);

    }

    //close the modal when user click on cancel
    handleCancelClick(){
        this.close({
            operation: 'cancel',
            eventResult: 'cancel'
        });
    }

    //prompt an error if error occured while saving
    handleSaveError(event){
        promptError(customLabels.ERROR_LABEL, getErrorMessage(event.detail));
        this.toggleSpinner(-1);
    }
    
    //return the saved record and close the modal
    handleSaveSuccess(event){
        let data = {}
        for(const [key, value] of Object.entries(event.detail.fields)){
            data[key] = value.value;
        }
        data.Id = event.detail.id;

        this.close({
            operation: 'submit',
            eventResult: 'success',
            eventData: data
        });
    }

	/**
     * @descripton library loader
     */
    handleLibLoadSuccess() {
        this.isScriptLoaded = true;
        this.isInitSuccess = true;
    }

    /**
     * @descripton library loader
     */
    handleLibLoadFail() {
        this.isScriptLoaded = true;
        this.isInitSuccess = false;
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
        logInfo('RecordEditModal', anything, this.enableDebugMode, isJson);
    }
	
}