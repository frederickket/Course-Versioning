/**
 * @Author 		WDCi (Lean)
 * @Date 		Oct 2023
 * @group 		Enrollment Wizard
 * @Description Student enrollment wizard
 * @changehistory
 * ISS-001752 05-10-2022 Lean - new component
 * ISS-002230 22-01-2025 XW - get picklist value label if field type is picklist
 * ISS-002351 25-03-2025 XW - make translation name clickable
 * ISS-002359 26-03-2025 XW - remove button border and stop truncate text if too long
 * ISS-002495 29-09-2025 XW - support translation for long text field
 * ISS-002746 27-11-2025 Lean - Enhanced to display currency symbol correctly
 */
import { LightningElement, api, wire, track } from 'lwc';
import { promptInfo, promptError, promptWarning, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';
import { extractFieldValue, formatLanguageCodeToPosix } from 'c/lwcUtil';
import { customLabels } from 'c/labelLoader';
import LANG from '@salesforce/i18n/lang'

import TIME_ZONE from '@salesforce/i18n/timeZone';

//Apex methods
// import ctrlSample from '@salesforce/apex/REDU_IpePathwayTermListingUnitCell_LCTRL.sample';


export default class IpePathwayTermUnitCell extends LightningElement {
	
	//configurable attributes
    @api ipsRecord;
    @api tableColumn;
    @api sunNameTranslationField;
    @api translationInfo;
	@api enableDebugMode = false;
	
	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false;
	loadedLists = 0;
	
	//labels
	label = customLabels;

    /**
     * @description Return user timezone
     */
    get timeZone() {
        return TIME_ZONE;
    }

    /**
     * @description the user language
     */
    get language() {
        return formatLanguageCodeToPosix(LANG);
    }

    /**
     * @description Return field label
     */
    get fieldLabel() {
        if (this.tableColumn && this.tableColumn.label) {
            return this.tableColumn.label;
        }

        return null;
    }

    /**
     * @description Return field type
     */
    get fieldType() {
        if (this.tableColumn && this.tableColumn.displayType) {
            return this.tableColumn.displayType;
        }

        return null;
    }

    /**
     * @description Return object API name
     */
    get objectName() {
        if (this.tableColumn && this.tableColumn.objectName) {
            return this.tableColumn.objectName;
        }

        return null;
    }

    /**
     * @description Return field API name
     */
    get fieldName() {
        if (this.tableColumn && this.tableColumn.fieldName) {
            return this.tableColumn.fieldName;
        }

        return null;
    }

    /**
     * @description Return field value
     */
    get fieldValue() {
        let val;
        if (this.objectName === 'reduivy__Study_Unit__c') {
            val = extractFieldValue(this.ipsRecord.sun, this.fieldName, this.translationInfo?.reduivy__Study_Unit__c, this.language);

        } else if (this.objectName === 'reduivy__Study_Plan_Structure__c') {
            val = extractFieldValue(this.ipsRecord.sps, this.fieldName, this.translationInfo?.reduivy__Study_Plan_Structure__c, this.language);

        } else if (this.objectName === 'reduivy__Study_Offering__c') {
            val = extractFieldValue(this.ipsRecord.sof, this.fieldName, this.translationInfo?.reduivy__Study_Offering__c, this.language);

        }

        if (this.fieldType === 'BOOLEAN') {
            if (val) {
                val = this.label.YES_LABEL;
            } else {
                val = this.label.NO_LABEL;
            }
        }
        else if (this.fieldType === 'PICKLIST') {
            let label = this.tableColumn.picklistOptions.find(option => option.value === val)?.label
            if(label) {
                val = label;
            }
        }

        return val;
    }

    /**
     * @description Return currency iso code
     */
    get currencyIsoCode() {
        let val;
        if (this.objectName === 'reduivy__Study_Unit__c') {
            val = extractFieldValue(this.ipsRecord.sun, 'CurrencyIsoCode', this.translationInfo?.reduivy__Study_Unit__c, this.language);

        } else if (this.objectName === 'reduivy__Study_Plan_Structure__c') {
            val = extractFieldValue(this.ipsRecord.sps, 'CurrencyIsoCode', this.translationInfo?.reduivy__Study_Plan_Structure__c, this.language);

        } else if (this.objectName === 'reduivy__Study_Offering__c') {
            val = extractFieldValue(this.ipsRecord.sof, 'CurrencyIsoCode', this.translationInfo?.reduivy__Study_Offering__c, this.language);

        }

        return val;
    }

    /**
     * @description Return true if the field is study unit's name field
     */
    get isUnitNameField() {
        if (this.objectName === 'reduivy__Study_Unit__c' && (this.fieldName === 'Name' || this.fieldName === this.sunNameTranslationField)) {
            return true;
        }

        return false;
    }

    /**
     * @description Return true if the field is study unit's unit code field
     */
    get isUnitCodeField() {
        if (this.objectName === 'reduivy__Study_Unit__c' && this.fieldName === 'reduivy__Unit_Code__c') {
            return true;
        }

        return false;
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
     * @description Return true if the field is url type
     */
    get isUrlField() {
        if (this.fieldType === 'URL') {
            return true;
        }

        return false;
    }

    /**
     * @description Handle study unit name field click e.g., launch unitInfo modal
     * @param {*} event 
     */
    handleUnitNameOnclick(event) {
        this.dispatchEvent(new CustomEvent("unitcellclick", {
            detail: {
                ipsRecord: this.ipsRecord,
                fieldName: this.fieldName,
                objectName: this.objectName
            }
        }));
    }

    /**
     * @description Handle study unit code field click e.g., launch unitInfo modal
     * @param {*} event 
     */
    handleUnitCodeOnclick(event) {
        this.dispatchEvent(new CustomEvent("unitcellclick", {
            detail: {
                ipsRecord: this.ipsRecord,
                fieldName: this.fieldName,
                objectName: this.objectName
            }
        }));
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
        logInfo('ipePathwayTermUnitCell', anything, this.enableDebugMode, isJson);
    }
	
}