/**
 * @Author 		WDCi (Lean)
 * @Date 		Oct 2023
 * @group 		Custom Form Field
 * @Description Generic lwc for custom field
 * @changehistory
 * ISS-001918 21-08-2024 CM - new lwc
 * ISS-002261 08-03-2025 Jordan - added isFieldDisabled
 */
import { LightningElement, api, wire, track } from 'lwc';
import { promptInfo, promptError, promptWarning, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';
import { extractFieldValue } from 'c/lwcUtil';
import { customLabels } from 'c/labelLoader';

import TIME_ZONE from '@salesforce/i18n/timeZone';

export default class CustomFormField extends LightningElement {
	
	//configurable attributes
    @api hideLabel = false;
    @api disabled = false;
	@api enableDebugMode = false;

    @track _fieldObj;
    @track _sobjRecord;

    //REDU_DynamicFieldValue_OBJ
    @api
    get fieldObj() {
        return this._fieldObj;
    }

    set fieldObj(val) {
        this._fieldObj = JSON.parse(JSON.stringify(val));
    }

    @api
    get sobjRecord() {
        return this._sobjRecord;
    }

    set sobjRecord(val) {
        this._sobjRecord = JSON.parse(JSON.stringify(val));
    }
	
    //internal attributes
    @api lwcReactor; //for reactive rerender only
    
	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false
	loadedLists = 0;

    //store field value
    fieldValue;
	
	//labels
	label = customLabels;

    //js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'tooltips'
    modules = ['stringutil'];
	
	/**
     * @descripton library loader
     */
    handleLibLoadSuccess(event) {
        this.isScriptLoaded = true;
        this.isInitSuccess = true;
        
        this.initiateFieldValue();
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
     * @description Initiate field value from object
     */
    @api
    initiateFieldValue() {
        if (this._fieldObj && this._sobjRecord) {
            let rawValue = extractFieldValue(this._sobjRecord, this._fieldObj.fieldName);
            
            this.consoleLog('initiateFieldValue');
            this.consoleLog(this._sobjRecord, true);
            this.consoleLog(rawValue);
            this.consoleLog(this.isMultiPicklistField);

            if (this.isMultiPicklistField) {
                if (rawValue) {
                    this.fieldValue = rawValue.split(';');
                } else {
                    this.fieldValue = [];
                }
            } else {
                this.fieldValue = rawValue;
            }
        }
    }

    /**
     * @description Return user timezone
     */
    get timeZone() {
        return TIME_ZONE;
    }

    /**
     * @description Return field label
     */
    get fieldLabel() {
        if (this._fieldObj && this._fieldObj.label) {
            return this._fieldObj.label;
        }

        return null;
    }

    /**
     * @description Return field type
     */
    get fieldType() {
        if (this._fieldObj && this._fieldObj.displayType) {
            return this._fieldObj.displayType;
        }

        return null;
    }

    /**
     * @description Return field API name
     */
    get fieldName() {
        if (this._fieldObj && this._fieldObj.fieldName) {
            return this._fieldObj.fieldName;
        }

        return null;
    }

    /**
     * @description Return object API name (I don't believe this is used anywhere)
     */
    get targetObjectType() {
        if (this._fieldObj && this._fieldObj.objectName) {
            return this._fieldObj.objectName;
        }

        return null;
    }

    /**
     * @description Return true if the field is boolean type
     */
    get isBooleanField() {
        if (this.fieldType === 'BOOLEAN') {
            return true;
        }

        return false;
    }

    /**
     * @description Return true if the field is date type
     */
    get isDateField() {
        if (this.fieldType === 'DATE') {
            return true;
        }

        return false;
    }

    /**
     * @description Return true if the field is datetime type
     */
    get isDateTimeField() {
        if (this.fieldType === 'DATETIME') {
            return true;
        }

        return false;
    }

    /**
     * @description Return true if the field is time type
     */
    get isTimeField() {
        if (this.fieldType === 'TIME') {
            return true;
        }

        return false;
    }

    /**
     * @description Return true if the field is integer, long and double type
     */
    get isDecimalField() {
        if (
            this.fieldType === 'INTEGER' ||
            this.fieldType === 'LONG' ||
            this.fieldType === 'DOUBLE'
        ) {
            return true;
        }

        return false;
    }

    /**
     * @description Return true if the field is currency type
     */
    get isCurrencyField() {
        if (this.fieldType === 'CURRENCY') {
            return true;
        }

        return false;
    }

    /**
     * @description Return true if the field is percent type
     */
    get isPercentField() {
        if (this.fieldType === 'PERCENT') {
            return true;
        }

        return false;
    }

    /**
     * @description Return true if the field is string, email, phone and url type
     */
    get isTextField() {
        if (this.fieldType === 'STRING' ||
            this.fieldType === 'EMAIL' ||
            this.fieldType === 'PHONE' ||
            this.fieldType === 'URL'
        ) {
            return true;
        }

        return false;
    }

    /**
     * @description Return true if the field is textarea type
     */
    get isTextAreaField() {
        if (this.fieldType === 'TEXTAREA') {
            return true;
        }

        return false;
    }

    /**
     * @description Return true if the field is picklist 
     */
    get isPicklistField() {
        if (this.fieldType === 'PICKLIST') {
            return true;
        }

        return false;
    }

    /**
     * @description Return true if the field is multi picklist type
     */
    get isMultiPicklistField() {
        if (this.fieldType === 'MULTIPICKLIST') {
            return true;
        }

        return false;
    }

    /**
     * @description Return picklist options
     */
    get picklistOptions() {
        if ((this.isPicklistField || this.isMultiPicklistField) && this._fieldObj.picklistOptions) {
            return this._fieldObj.picklistOptions;
        }

        return [];
    }

    /**
     * @description Return unsupported field type error message
     */
    get unsuportedTypeError() {
        if (this.isScriptLoaded && this.fieldType && this.fieldLabel) {
            return this.label.UNSUPPORTED_FIELD_TYPE_LABEL.format([this.fieldType, this.fieldLabel]);
        }

        return null;
    }

    /**
     * @description Returns the lightning-input variant param
     */
    get inputVariant(){
        if (this.hideLabel){
            return "label-hidden";
        } else if (this.isBooleanField){
            return "label-stacked";
        }
        return "standard";
    }

    /**
     * @description ISS-002261 Returns disabled
     */
    get isFieldDisabled(){
        return (this.disabled || !this._fieldObj.isCreateable || !this._fieldObj.isUpdateable);
    }

    /**
     * @description Update the customFormField value
     * @param {@} event 
     */
    handleOnChange(event){
        //Blank strings can cause issues when sending data back to apex. We need to specify it as null so we can avoid unexpected behaviour.
        let newValue = event.detail.value;
        if (newValue === ""){
            newValue = null;
        }
        this.fieldValue = newValue;
        //Also map back to source object
        //Original object is read only, need to create a copy to make changes
        let tempSobjRecord = this._sobjRecord;
        tempSobjRecord[this.fieldName] = newValue;
        
        this._sobjRecord = tempSobjRecord;

        //ISS-002261 skip if the field is disabled
        if (!this.isFieldDisabled) {
            this.notifyParent();
        }
    }

    /**
     * @description Update the customFormField value
     * @param {@} event 
     */
    handlePicklistOnChange(event){
        //Blank strings can cause issues when sending data back to apex. We need to specify it as null so we can avoid unexpected behaviour.
        let newValue = event.detail.value;
        if (newValue === ""){
            newValue = null;
        }
        
        this.fieldValue = newValue;
        //Also map back to source object
        //Original object is read only, need to create a copy to make changes
        let tempSobjRecord = this._sobjRecord;
        tempSobjRecord[this.fieldName] = newValue;
        
        this._sobjRecord = tempSobjRecord;

        //ISS-002261 skip if the field is disabled
        if (!this.isFieldDisabled) {
            this.notifyParent();
        }
    }

    /**
     * @description Update the customFormField value
     * @param {@} event 
     */
    handleMultiPicklistOnChange(event){
        //Blank strings can cause issues when sending data back to apex. We need to specify it as null so we can avoid unexpected behaviour.
        let newValue = event.detail.value;

        this.fieldValue = newValue;
        //Also map back to source object
        //Original object is read only, need to create a copy to make changes
        let tempSobjRecord = this._sobjRecord;
        tempSobjRecord[this.fieldName] = newValue.length ? newValue.join(";") : null;
        
        this._sobjRecord = tempSobjRecord;

        //ISS-002261 skip if the field is disabled
        if (!this.isFieldDisabled) {
            this.notifyParent();
        }
    }

    /**
     * @description Checkbox uses .checked instead of .value
     * @param {*} event 
     */
    handleOnChangeCheckbox(event){
        this.fieldValue = event.detail.checked;
        //Also map back to source object
        //Original object is read only, need to create a copy to make changes
        let tempSobjRecord = this._sobjRecord;
        tempSobjRecord[this.fieldName] = event.detail.checked;
        this._sobjRecord = tempSobjRecord;

        //ISS-002261 skip if the field is disabled
        if (!this.isFieldDisabled) {
            this.notifyParent();
        }
    }

    /**
     * @description Time needs to be handled specially, as the return value doesn't automatically have a neutral UTC timezone.
     * @param {*} event 
     */
    handleOnChangeTime(event){
        this.fieldValue = (event.detail.value ? event.detail.value + 'Z' : null);
        //Also map back to source object
        //Original object is read only, need to create a copy to make changes
        let tempSobjRecord = this._sobjRecord;
        tempSobjRecord[this.fieldName] = this.fieldValue;
        this._sobjRecord = tempSobjRecord;

        //ISS-002261 skip if the field is disabled
        if (!this.isFieldDisabled) {
            this.notifyParent();
        }
    }

    /**
     * @description Post the filter details to parent component
     */
    notifyParent(){
        this.consoleLog(this.fieldValue);
        //Create event to send back to parent component
        let fieldChangeEvent = new CustomEvent("fieldchange", {
            "detail": { 
                sobjRecord: this._sobjRecord 
            }
        });
        //Fire the event
        this.dispatchEvent(fieldChangeEvent);
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
        logInfo('customFormField', anything, this.enableDebugMode, isJson);
    }
	
}