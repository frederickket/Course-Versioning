/**
 * @Author 		WDCi (XW)
 * @Date 		Jan 2025
 * @group 		Custom Record View Form
 * @Description the output field of the custom record view form
 * @changehistory
 * ISS-002495 23-09-2025 XW - new class
 * ISS-002746 27-11-2025 Lean - Standardize the CurrencyIsoCode detection
 * ISS-002747 28-11-2025 Lean - Added fraction for both currency and percent field
 */
import { LightningElement, api, wire, track } from 'lwc';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';
import { customLabels } from 'c/labelLoader';
import { NavigationMixin } from "lightning/navigation";
import TIMEZONE from '@salesforce/i18n/timeZone'

const VARIANT_LABEL_HIDDEN = "label-hidden";
const VARIANT_RECORD_DETAILS_READONLY = "recordDetailsReadonly"
const VARIANT_RECORD_DETAILS_EDIT = "recordDetailsEdit"

export default class OutputField extends NavigationMixin(LightningElement) {
	
	//configurable attributes
    @api set fieldValue(value){
        this._fieldValue = value;
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: value,
                actionName: 'view',
            },
        }).then((url) => {
            this.fieldValueLink = url;
        });
    }

    get fieldValue(){
        return this._fieldValue;
    }

    @api fieldDisplayValue;
    @api fieldLabel;
    @api fieldName;
    @api displayType;
    @api fieldHelpText;
    @api variant;
    @api fractionDigits;
    @api parentContextData; //additional parent context data in json serialized string
    @api hideForBlankValue;
    @api isFormula;
	@api enableDebugMode = false;
	
	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false
	loadedLists = 0;

	//labels
	label = customLabels;
	
	//js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'jquery', 'tooltips'
    modules = [];
	
    _fieldValue;
    @track fieldValueLink;

    /**
     * @description Return parent context data object deserialized from string
     */
    get parentContextDataObject() {
        this.consoleLog(this.parentContextData);
        
        if (this.parentContextData) {
            return JSON.parse(this.parentContextData);
        }

        return {};
    }

    get hideOutputField() {
        return this.hideForBlankValue && !this.fieldDisplayValue;
    }

    get hideLabel(){
        return this.variant === VARIANT_LABEL_HIDDEN;
    }

    get showAsRecordDetails() {
        return this.variant === VARIANT_RECORD_DETAILS_EDIT || this.variant === VARIANT_RECORD_DETAILS_READONLY;
    }

    get showPencilIcon() {
        return this.variant === VARIANT_RECORD_DETAILS_EDIT && !this.isFormula;
    }

    get fieldCssClass() {
        if(this.hideLabel) {
            return 'slds-form-element';
        }
        else if (this.showAsRecordDetails) {
            return 'slds-form-element slds-form-element_edit slds-form-element_readonly slds-hint-parent';
        }
        return 'slds-form-element slds-form-element_stacked';
    }
    
    /**
     * @description Return true if the field is boolean type
     */
    get isBooleanField() {
        if (this.displayType === 'BOOLEAN') {
            return true;
        }

        return false;
    }

    /**
     * @description Return true if the field is date type
     */
    get isDateField() {
        if (this.displayType === 'DATE') {
            return true;
        }

        return false;
    }

    /**
     * @description Return true if the field is datetime type
     */
    get isDateTimeField() {
        if (this.displayType === 'DATETIME') {
            return true;
        }

        return false;
    }

    /**
     * @description Return true if the field is time type
     */
    get isTimeField() {
        if (this.displayType === 'TIME') {
            return true;
        }

        return false;
    }

    /**
     * @description Return true if the field is integer, long and double type
     */
    get isDecimalField() {
        if (
            this.displayType === 'INTEGER' ||
            this.displayType === 'LONG' ||
            this.displayType === 'DOUBLE'
        ) {
            return true;
        }

        return false;
    }

    /**
     * @description Return true if the field is currency type
     */
    get isCurrencyField() {
        if (this.displayType === 'CURRENCY') {
            return true;
        }

        return false;
    }

    /**
     * @description Return true if the field is percent type
     */
    get isPercentField() {
        if (this.displayType === 'PERCENT') {
            return true;
        }

        return false;
    }

    /**
     * @description Return true if the field is email
     */
    get isEmailField() {
        if (this.displayType === 'EMAIL') {
            return true;
        }

        return false;
    }

    /**
     * @description Return true if the field is phone
     */
    get isPhoneField() {
        if (this.displayType === 'PHONE') {
            return true;
        }

        return false;
    }

    /**
     * @description Return true if the field is string
     */
    get isTextField() {
        if (this.displayType === 'STRING' ||
            this.displayType === 'URL' ||
            this.displayType === 'TEXTAREA' ||
            this.displayType === 'PICKLIST' ||
            this.displayType === 'MULTIPICKLIST'
        ) {
            return true;
        }

        return false;
    }

    /**
     * @description Return true if the field is reference, and the link is generated successfully
     */
    get isReferenceField() {
        if (this.displayType === 'REFERENCE' && this.fieldValueLink && !this.fieldValueLink.startsWith('javascript')) {
            return true;
        }

        return false;
    }
    
    /**
     * @description Return record CurrencyIsoCode if available
     */
    get currencyCode() {
        return this.parentContextDataObject?.CurrencyIsoCode;
    }

    get timezone() {
        return TIMEZONE;
    }

    /**
    * @description the actual result to be displayed.
     */
    get actualDisplayValue() {
        if(this.isTimeField) {
            return new Date(`1970-01-01T${this.fieldDisplayValue.replace('Z', '')}`)
        } else if (this.isDateTimeField) { 
            return new Date(this.fieldDisplayValue);
        }
        return this.fieldDisplayValue;
    }

    handlePencilClick() {
        this.dispatchEvent(new CustomEvent('edit', {
            detail: {
                fieldValue: this.fieldValue,
                fieldDisplayValue: this.fieldDisplayValue,
                fieldLabel: this.fieldLabel,
                fieldName: this.fieldName,
                displayType: this.displayType,
                fieldHelpText: this.fieldHelpText,
                parentContextData: this.parentContextData
            }
        }));
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
        logInfo('OutputField', anything, this.enableDebugMode, isJson);
    }
	
}