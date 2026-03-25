/**
 * @Author 		WDCi (XW)
 * @Date 		Jan 2025
 * @group 		Custom Record View Form
 * @Description 
 * @changehistory
 * ISS-002495 23-09-2025 XW - new class
 * ISS-002746 27-11-2025 Lean - Standardize the CurrencyIsoCode detection
 * ISS-002797 13-02-2025 Lean - Standardize language code format to POSIX
 */
import { LightningElement, api, wire, track } from 'lwc';
import { promptInfo, promptError, promptWarning, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';
import { initCacheIdx, flattenObj, commonConstants, formatLanguageCodeToPosix } from 'c/lwcUtil';
import { customLabels } from 'c/labelLoader';
import LANG from '@salesforce/i18n/lang';

//refresh module
import { refreshApex } from '@salesforce/apex';
import { RefreshEvent, registerRefreshHandler, unregisterRefreshHandler } from 'lightning/refresh';

//Apex methods
import ctrlGetRecordFieldValue from '@salesforce/apex/REDU_RecordViewForm_LCTRL.getRecordFieldValue';

const RECORDS_PARAM = 'records';
const FIELDS_OBJECT_PARAM = 'fieldsObject';
const TRANSLATION_INFO_PARAM = 'translationInfo';

export default class RecordViewForm extends LightningElement {
	
	//configurable attributes
    @api recordId;
    @api objectApiName;
    @api set fields(value){ //in list<string>
        //we need to do this to ensure that the record view form is updated when fields is updated
        if(!value) {
            value = [];
        }
        if(value.join(';') === this._fields.join(';')){
            return;
        }
        this._fields = value;
        this.consoleLog('fields updated: ');
        this.consoleLog(value, true);
        this.enableRefreshSlot = true;
        setTimeout(() => this.enableRefreshSlot = false, 0);
            
        
    }

    get fields() {
        return this._fields;
    }

    @api modalTitle;
    @api modalIconName;
	@api enableDebugMode = false;
	
	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false
	loadedLists = 0;
    _fields = []
	
    //refresh handler
    refreshHandlerID;

    //local cache idx to force rerendering
    _cacheIdx;

    //wire attribute
    recordFieldValueResult;
    recordFieldValueResponse;

	//labels
	label = customLabels;
	
	//js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'jquery', 'tooltips'
    modules = [];

    @track enableRefreshSlot = false;
    @track outputFieldElements = {};
	
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
    @api refreshData() {
        this.consoleLog('refreshData');
        //update the cacheIdx if you need to force the wire method to get new data from apex
        this._cacheIdx = initCacheIdx();

        refreshApex(this.recordFieldValueResult);

        return new Promise((resolve) => {
            resolve(true);
        });

    }

    /**
     * @description handle when the slot is updated
     * @param {*} event 
     */
    handleOutputFieldChanged(event) {
        
        this.outputFieldElements = {};
        const outputFieldElements = {};
        let fieldsUsed = this.fields;
        let recordFieldValueResponse = this.recordFieldValueResponse;
        
        function traverse(node) {
            // Check if the node is an element (nodeType 1)
            if (node.nodeType === Node.ELEMENT_NODE && node.fieldName && node.tagName === 'C-OUTPUT-FIELD') {
                if(!Object.prototype.hasOwnProperty.call(outputFieldElements, node.fieldName)) {
                    outputFieldElements[node.fieldName] = [];
                }
                outputFieldElements[node.fieldName].push(node);
            }

            // Recursively call traverse for each child node
            for (let i = 0; i < node.children.length; i++) {
                traverse(node.children[i]);
            }
        }
        for(let node of event.target.assignedElements()) {
            traverse(node); // Start the traversal from the given element
        }

        this.outputFieldElements = outputFieldElements;
        if(Object.keys(outputFieldElements).length > 0 && recordFieldValueResponse && Object.keys(this.recordFieldValueResponse).length > 0) {
            this.replaceFieldValue(recordFieldValueResponse, fieldsUsed);
        }

    }

    /**
     * @description get record and translation to be displayed on the form
     * @param {*} result 
     */
    @wire(ctrlGetRecordFieldValue, { 
        recordId: '$recordId',
        objectApiName: '$objectApiName',
        fields: '$fields',
        language: '$language'
    })
    wireGetRecordFieldValue(result) {
        
        this.recordFieldValueResult = result;
        this.recordFieldValueResponse = null;

        if (result.data) {
            this.recordFieldValueResponse = JSON.parse(result.data.responseData);
            this.consoleLog('recordFieldValueResponse');
            this.consoleLog(this.recordFieldValueResponse, true);
            if(Object.keys(this.recordFieldValueResponse).length > 0){
                this.replaceFieldValue(this.recordFieldValueResponse, this.fields)
            }

        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }

    }

    /**
     * @description Return record from response result so that we can display the correct symbol
     */
    get recordCurrencyIsoCode() {
        let record = this.recordFieldValueResponse?.[RECORDS_PARAM]?.[0];

        if (record) {
            return record?.CurrencyIsoCode; 
        }

        return null;
    }

    /**
     * @description replace the output field attribute 
     * @param {*} recordFieldValueResponse 
     * @param {*} fieldsUsed 
     * @returns 
     */
    replaceFieldValue(recordFieldValueResponse, fieldsUsed) {
        this.consoleLog('recordFieldValueResponse');
        this.consoleLog(recordFieldValueResponse, true);
        this.consoleLog('fieldsUsed');
        this.consoleLog(fieldsUsed, true);
        
        let fieldWrapperMap = this.generateFieldWrapperMap(recordFieldValueResponse, fieldsUsed);
        this.consoleLog('fieldWrapperMap');
        this.consoleLog(fieldWrapperMap, true);
        if(Object.keys(this.outputFieldElements).length === 0 || Object.keys(fieldWrapperMap).length === 0) {
            return;
        }

        this.toggleSpinner(1);

        //prepare the information that we need to pass to child components
        //we only support passing to c-output-field at the moment
        let parentContextData = { 
            CurrencyIsoCode: this.recordCurrencyIsoCode
        };

        for(let fieldUsed of fieldsUsed) {
            let wrapper = fieldWrapperMap[fieldUsed];
            if (this.outputFieldElements[fieldUsed] && wrapper) {

                for(let outputField of this.outputFieldElements[fieldUsed]){
                    outputField.fieldLabel = wrapper.fieldLabel;
                    outputField.displayType = wrapper.displayType;
                    outputField.fieldValue = wrapper.fieldValue;
                    outputField.fieldDisplayValue = wrapper.fieldDisplayValue;
                    outputField.fieldHelpText = wrapper.fieldHelpText;
                    outputField.fractionDigits = wrapper.fractionDigits;
                    outputField.parentContextData = JSON.stringify(parentContextData); //pass the context to child as serialized string
                    outputField.isFormula = wrapper.isFormula;
                    outputField.enableDebugMode = this.enableDebugMode;

                }
            }
        }
        this.toggleSpinner(-1);
    }

    /**
     * @description generate field wrapper map to be used in output field
     * @param {*} recordFieldValueResponse 
     * @param {*} fieldsUsed 
     * @returns 
     */
    generateFieldWrapperMap(recordFieldValueResponse, fieldsUsed) {
        let fieldsObjectMap = recordFieldValueResponse?.[FIELDS_OBJECT_PARAM];

        let record = recordFieldValueResponse?.[RECORDS_PARAM]?.[0];
        if(!record) {
            return {};
        }
        let result = {};
        let translation = recordFieldValueResponse[TRANSLATION_INFO_PARAM]?.translations?.find(t => t.languageCode === this.language);
        let flattenRecord = flattenObj(record);

        //convert field ends with __c to __r, or from ...Id to ...
        function fieldToRelation(fieldName){
            if(!fieldName) {
                return '';
            }
            return fieldName.endsWith('__c') ? fieldName.slice(0, -3) + '__r' : fieldName.slice(0, -2);
        }

        for(let field of fieldsUsed) {
            let fieldObject = fieldsObjectMap[field];
            if(!fieldObject) {
                continue;
            }

            let lastDotIndex = field.lastIndexOf('.');
            let actualPath = lastDotIndex < 0 ? '' : field.substring(0, lastDotIndex);
            let isReference = fieldObject.displayType === 'REFERENCE';
            let isPicklist = fieldObject.displayType === 'PICKLIST';

            let fieldNameForLabel;                          //the field name of the label 
            let fieldNameForDisplayValue;                   //the field name of the display value (parent.name if field is reference)
            let fieldRefId;                                 //the record id of the field is referring to (parent.id if field is reference)
            let fieldDisplayValue;                          //the field value to be displayed on the output field
            let fieldLabel = fieldObject.label;             //the field label to be displayed on the output field
            let fieldHelpText = fieldObject.helpText;       //the field helptext

            if(!field.includes('.') && !isReference) {
                //first level field, and the field is not a lookup / master detail field
                fieldRefId = this.recordId;
                fieldNameForLabel = field;
                fieldDisplayValue = flattenRecord[field];
                fieldNameForDisplayValue = field;
            } else if(!field.includes('.') && isReference) {
                //first level field, and the field is a lookup / master detail field
                fieldRefId = flattenRecord[field];
                actualPath = fieldToRelation(field);
                let parentNameField = 'Name';
                fieldNameForDisplayValue = parentNameField;
                fieldDisplayValue = flattenRecord[actualPath + '.' + parentNameField];
                fieldNameForLabel = field;
            } else if (!isReference){
                //nested field, and the field is not a lookup / master detail field
                fieldNameForLabel = field.slice(lastDotIndex + 1);
                fieldRefId = flattenRecord[actualPath + '.Id'];
                fieldNameForDisplayValue = fieldNameForLabel;
                fieldDisplayValue = flattenRecord[field];
            } else {
                //nested field, and the field is a lookup / master detail field
                fieldRefId = flattenRecord[fieldToRelation(field) + '.Id'];
                fieldNameForLabel = field.slice(lastDotIndex + 1);
                fieldNameForDisplayValue = 'Name';
                let parentNameField = 'Name';
                fieldDisplayValue = flattenRecord[fieldToRelation(field) + '.' + parentNameField];
            }

            //find the translation
            if(translation) {

                let config = translation?.configs?.find(c => c.path === actualPath)
                fieldLabel = config?.fields?.find(f => f.fieldName === fieldNameForLabel)?.fieldLabel ?? fieldObject.label;
                
                fieldDisplayValue = translation?.data?.[fieldRefId]?.[fieldNameForDisplayValue] ?? fieldDisplayValue;
            }
            
            if(isPicklist) {
                //change the display value to the picklist label
                fieldDisplayValue = flattenRecord[field + commonConstants.PICKLIST_LABEL];
            }

            result[[field]] = {
                displayType: fieldObject.displayType,
                fieldLabel: fieldLabel,
                fieldValue: fieldRefId,
                fieldDisplayValue: fieldDisplayValue,
                fieldName: field,
                fieldHelpText: fieldHelpText,
                fractionDigits: fieldObject.doubleDecimalPlaces ?? 0,
                isFormula: fieldObject.isFormula
            };
        }
        
        return result;
    }

    /**
     * @description the user language
     */
    get language() {
        return formatLanguageCodeToPosix(LANG);
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
        logInfo('RecordViewForm', anything, this.enableDebugMode, isJson);
    }
	
}