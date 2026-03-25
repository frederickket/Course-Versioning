/**
 * @Author 		WDCi (Lean)
 * @Date 		Oct 2023
 * @group 		Custom Filter
 * @Description Generic lwc for custom filter
 * @changehistory
 * ISS-001752 28-10-2023 Lean - new lwc
 * ISS-002188 17-12-2024 XW - to handle changes made if custom filter is set
 */
import { LightningElement, api, wire, track } from 'lwc';
import { promptInfo, promptError, promptWarning, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';
import { extractFieldValue } from 'c/lwcUtil';
import { customLabels } from 'c/labelLoader';

import TIME_ZONE from '@salesforce/i18n/timeZone';

export default class CustomFilterField extends LightningElement {
	
	//configurable attributes
    @api showPicklistAsMultiSelect = false;
	@api enableDebugMode = false;

    @track _customFilter;

    @api
    get customFilter() {
        return this._customFilter;
    }

    set customFilter(val) {
        this._customFilter = JSON.parse(JSON.stringify(val));
        this.initiateFieldValue(); //ISS-002188
    }
	
    //internal attributes
    @api lwcReactor; //for reactive rerender only
    
	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false;
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
        if (this._customFilter && this._customFilter.sourceSobj) {
            let rawValue = extractFieldValue(this._customFilter.sourceSobj, this._customFilter.sourceFieldName);
            
            this.consoleLog('initiateFieldValue');
            this.consoleLog(this._customFilter.sourceSobj, true);
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
        if (this._customFilter && this._customFilter.label) {
            return this._customFilter.label;
        }

        return null;
    }

    /**
     * @description Return source field type
     */
    get fieldType() {
        if (this._customFilter && this._customFilter.targetFieldType) {
            return this._customFilter.targetFieldType;
        }

        return null;
    }

    /**
     * @description Return source field API name
     */
    get fieldName() {
        if (this._customFilter && this._customFilter.sourceFieldName) {
            return this._customFilter.sourceFieldName;
        }

        return null;
    }

    /**
     * @description Return target object API name
     */
    get targetObjectType() {
        if (this._customFilter && this._customFilter.targetObjectType) {
            return this._customFilter.targetObjectType;
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
     * @description Return true if the field is string, textarea, email, phone and url type
     */
    get isTextField() {
        if (this.fieldType === 'STRING' ||
            this.fieldType === 'TEXTAREA' ||
            this.fieldType === 'EMAIL' ||
            this.fieldType === 'PHONE' ||
            this.fieldType === 'URL'
        ) {
            return true;
        }

        return false;
    }

    /**
     * @description Return true if the field is picklist 
     */
    get isPicklistField() {
        if (this.fieldType === 'PICKLIST' && !this.showPicklistAsMultiSelect) {
            return true;
        }

        return false;
    }

    /**
     * @description Return true if the field is multi picklist type
     */
    get isMultiPicklistField() {
        if (this.fieldType === 'MULTIPICKLIST' || (this.fieldType === 'PICKLIST' && this.showPicklistAsMultiSelect)) {
            return true;
        }

        return false;
    }

    /**
     * @description Return picklist options
     */
    get picklistOptions() {
        if ((this.isPicklistField || this.isMultiPicklistField) && this._customFilter.picklistOptions) {
            return this._customFilter.picklistOptions;
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
     * @description Update the customFilter value
     * @param {@} event 
     */
    handleOnChange(event){
        //Blank strings can cause issues when sending data back to apex. We need to specify it as null so we can ignore it in the filter.
        let newValue = event.detail.value;
        if (newValue === ""){
            newValue = null;
        }
        this.fieldValue = newValue;
        //Also map back to pe object
        //Original object is read only, need to create a copy to make changes
        let tempCustomFilter = this._customFilter;
        tempCustomFilter.sourceSobj[this.fieldName] = newValue;
        
        this._customFilter = tempCustomFilter;

        this.notifyParent();
    }

    /**
     * @description Update the customFilter value
     * @param {@} event 
     */
    handlePicklistOnChange(event){
        //Blank strings can cause issues when sending data back to apex. We need to specify it as null so we can ignore it in the filter.
        let newValue = event.detail.value;
        if (newValue === ""){
            newValue = null;
        }
        
        this.fieldValue = newValue;
        //Also map back to pe object
        //Original object is read only, need to create a copy to make changes
        let tempCustomFilter = this._customFilter;

        tempCustomFilter.sourceSobj[this.fieldName] = newValue;
        
        this._customFilter = tempCustomFilter;

        this.notifyParent();
    }

    /**
     * @description Update the customFilter value
     * @param {@} event 
     */
    handleMultiPicklistOnChange(event){
        //Blank strings can cause issues when sending data back to apex. We need to specify it as null so we can ignore it in the filter.
        let newValue = event.detail.value;

        this.fieldValue = newValue;
        //Also map back to pe object
        //Original object is read only, need to create a copy to make changes
        let tempCustomFilter = this._customFilter;
        tempCustomFilter.sourceSobj[this.fieldName] = newValue.length ? newValue.join(";") : null;
        
        this._customFilter = tempCustomFilter;

        this.notifyParent();
    }

    /**
     * @description Checkbox uses .checked instead of .value
     * @param {*} event 
     */
    handleOnChangeCheckbox(event){
        this.fieldValue = event.detail.checked;
        //Also map back to pe object
        //Original object is read only, need to create a copy to make changes
        let tempCustomFilter = this._customFilter;
        tempCustomFilter.sourceSobj[this.fieldName] = event.detail.checked;
        this._customFilter = tempCustomFilter;

        this.notifyParent();
    }

    /**
     * @description Time needs to be handled specially, as the return value doesn't automatically have a neutral UTC timezone.
     * @param {*} event 
     */
    handleOnChangeTime(event){
        this.fieldValue = (event.detail.value ? event.detail.value + 'Z' : null);
        //Also map back to pe object
        //Original object is read only, need to create a copy to make changes
        let tempCustomFilter = this._customFilter;
        tempCustomFilter.sourceSobj[this.fieldName] = this.fieldValue;
        this._customFilter = tempCustomFilter;

        this.notifyParent();
    }

    /**
     * @description Post the filter details to parent component
     */
    notifyParent(){
        this.consoleLog(this.fieldValue);
        //Create event to send back to parent component
        let filterChangeEvent = new CustomEvent("filterchange", {
            "detail": { 
                customFilter: this._customFilter 
            }
        });
        //Fire the event
        this.dispatchEvent(filterChangeEvent);
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
        logInfo('customFilterField', anything, this.enableDebugMode, isJson);
    }
	
}