/**
 * @Author 		WDCi (XW)
 * @Date 		Nov 2024
 * @group 		Custom Single Related List
 * @Description 
 * @changehistory
 * ISS-002104 27-11-2024 XW - create new component. refer: https://developer.salesforce.com/docs/platform/lwc/guide/use-flow-custom-property-editor-sobject-lwc-example.html
 * ISS-002387 11-04-2025 XW - exposed record id field
 * ISS-002605 10-09-2025 XW - fixed bug where default value is set if the field is updated to empty
 */
import { LightningElement, api } from 'lwc';
import { logInfo } from 'c/loggingUtil';
import { customLabels } from 'c/labelLoader';
import INVALID_OBJECT_TYPE_LABEL from '@salesforce/label/c.Custom_Related_Invalid_Object_Type';
import NOT_A_COLLECTION from '@salesforce/label/c.Custom_Related_Not_A_Collection';

const DATA_TYPE_REFERENCE = 'reference';
const DATA_TYPE_NUMBER = 'Number';
const DATA_TYPE_STRING = 'String';
const DATA_TYPE_BOOLEAN = 'Boolean';

const MANUAL_VALUE = 'manual'
const AUTO_VALUE = 'auto'

export default class CustomSingleRelatedListConfigurationEditor extends LightningElement {

    //configurable attributes
    @api inputVariables;
    @api genericTypeMappings;
    @api builderContext;

    //labels
    label = customLabels;

    //internal attributes
    isScriptLoaded = false;
    isInitSuccess = false;

    //js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'jquery', 'tooltips'
    modules = ['stringutil'];

    //options of recordsSource combobox
    get recordsSourceOptions(){
        return [
            {label: 'Manual', value: MANUAL_VALUE},
            {label: 'Auto', value: AUTO_VALUE},
        ]
    }

    //return true if is manual (pass records into datatable)
    get sourceManual(){
        return this.recordsSourceValue === MANUAL_VALUE;
    }
    
    //return true if is auto (query in datatable)
    get sourceAuto(){
        return this.recordsSourceValue === AUTO_VALUE;
    }

    //value of recordsSource
    get recordsSourceValue(){
        const param = this.inputVariables.find(({ name }) => name === "useSourceCollectionRecords");
        if(param){
            if(param.value){
                return MANUAL_VALUE;
            } 
            return AUTO_VALUE;
        }
        
        return AUTO_VALUE;    
    }


    //options of sortedDirection combobox
    get sortedDirectionOptions() {
        return [
            {label: 'asc', value: 'asc'},
            {label: 'desc', value: 'desc'}
        ]
    }
    
    //options of reftargetoptions combobox
    get refTargetOptions() {
        return [
            {label: '_blank', value: '_blank'},
            {label: '_self', value: '_self'},
            {label: '_parent', value: '_parent'},
            {label: '_top', value: '_top'},
        ]
    }

    //options of viewMode combobox
    get viewModeOptions() {
        return [
            {label: 'Related List', value: 'Related List'},
            {label: 'Datatable', value: 'Datatable'}
        ]
    }
    
    //modalTitle value
    get modalTitle() {
        return this.genericValueGetter("modalTitle");
    }

    //modalIconName
    get modalIconName() {
        return this.genericValueGetter("modalIconName");
    }
    
    //parentObjectRefField value
    get parentObjectRefField() {
        return this.genericValueGetter("parentObjectRefField");
    }
    
    //recordId value
    get recordId() {
        return this.genericValueGetter("recordId");
    }

    //targetRecordIdField value
    get targetRecordIdField() {
        return this.genericValueGetter("targetRecordIdField");
    }
    
    //childObjectFields value
    get childObjectFields() {
        return this.genericValueGetter("childObjectFields");
    }
    
    //childObjectApiName value
    get childObjectApiName() {
        return this.genericValueGetter("childObjectApiName");
    }
    
    //sortedBy value
    get sortedBy() {
        return this.genericValueGetter("sortedBy");
    }
    
    //childObjectFilterCriteria value
    get childObjectFilterCriteria() {
        return this.genericValueGetter("childObjectFilterCriteria");
    }
    
    //sortedDirection value
    get sortedDirection() {
        return this.genericValueGetter("sortedDirection");
    }
    
    //enableRowViewButton value
    get enableRowViewButton() {
        return this.genericValueGetter("enableRowViewButton");
    }
    
    //enableNewButton value
    get enableNewButton() {
        return this.genericValueGetter("enableNewButton");
    }
    
    //editFieldSetName value
    get editFieldSetName() {
        return this.genericValueGetter("editFieldSetName");
    }
    
    //enableRowEditButton value
    get enableRowEditButton() {
        return this.genericValueGetter("enableRowEditButton");
    }
    
    //enableRowDownloadButton value
    get enableRowDownloadButton() {
        return this.genericValueGetter("enableRowDownloadButton");  
    }
    
    //enableRowDeleteButton value
    get enableRowDeleteButton() {
        return this.genericValueGetter("enableRowDeleteButton");
    }

    //downloadUrl value
    get downloadUrl() {
        return this.genericValueGetter("downloadUrl");
    }
    
    //showRowNumber value
    get showRowNumber() {
        return this.genericValueGetter("showRowNumber"); 
    }
    
    //maxHeight value
    get maxHeight() {
        return this.genericValueGetter("maxHeight"); 
    }
    
    //rowsToLoad value
    get rowsToLoad() {
        return this.genericValueGetter("rowsToLoad");  
    }
    
    //enableInfiniteLoading value
    get enableInfiniteLoading() {
        return this.genericValueGetter("enableInfiniteLoading"); 
    }
    
    //enableClickableRefField value
    get enableClickableRefField() {
        return this.genericValueGetter("enableClickableRefField"); 
    }
    
    //noRecordFoundMessage value
    get noRecordFoundMessage() {
        return this.genericValueGetter("noRecordFoundMessage");
        
    }
    
    //enableInlineEditing value
    get enableInlineEditing() {
        return this.genericValueGetter("enableInlineEditing");
    }
    
    //enableRowSelection value
    get enableRowSelection() {
        return this.genericValueGetter("enableRowSelection"); 
    }
    
    //enableQuickSearch value
    get enableQuickSearch() {
        return this.genericValueGetter("enableQuickSearch");
    }
    
    //refTarget value
    get refTarget() {
        return this.genericValueGetter("refTarget")
    }
    
    //enableDebugMode value
    get enableDebugMode() {
        return this.genericValueGetter("enableDebugMode");
    }
    
    //sourceCollection value
    get sourceCollection() {
        return this.genericValueGetter("sourceCollection");
    }
    
    //viewMode value
    get viewMode() {
        return this.genericValueGetter("viewMode");
    }

    //generic value for all of the getter value
    genericValueGetter(value){
        const param = this.inputVariables.find(({ name }) => name === value);
        if (param && param.valueDataType === DATA_TYPE_REFERENCE) {
            return '{!' + param.value + '}';
        } else if (param && param.valueDataType === DATA_TYPE_NUMBER && !param.value){
            return '';
        }
        return param && param.value;
    }

    /**
     * @description handle manual or auto records source change
     * @param {*} event 
     */
    handleRecordsSourceChange(event) {
        let useSourceCollectionRecords = event.detail.value === MANUAL_VALUE;
        this.dispatchInputChanged('useSourceCollectionRecords', useSourceCollectionRecords, DATA_TYPE_BOOLEAN);
        if(useSourceCollectionRecords) {
            this.dispatchInputChanged('enableClickableRefField', false, DATA_TYPE_BOOLEAN);
            this.dispatchInputChanged('enableInfiniteLoading', false, DATA_TYPE_BOOLEAN);
            this.dispatchInputChanged('targetRecordIdField', 'Id', DATA_TYPE_STRING);
            this.dispatchInputChanged('parentObjectRefField', '', DATA_TYPE_STRING);
            this.dispatchInputChanged('childObjectApiName', '', DATA_TYPE_STRING);
            this.dispatchInputChanged('childObjectFilterCriteria', '', DATA_TYPE_STRING);
            this.dispatchInputChanged('rowsToLoad', '', DATA_TYPE_STRING);
            this.dispatchInputChanged('recordId', '', DATA_TYPE_STRING);
        } else {
            this.dispatchInputChanged('sourceCollection', '', DATA_TYPE_STRING);
            this.dispatchInputChanged('recordId', '{!recordId}', DATA_TYPE_STRING);
        }

    }

    /**
     * @description notify salesforce that value has been changed
     * @param {string} name name of the variable to change
     * @param {*} newValue new value to be changed
     * @param {string} newValueDataType data type of the new value
     */
    dispatchInputChanged(name, newValue, newValueDataType) {
        const valueChangedEvent = new CustomEvent(
            'configuration_editor_input_value_changed',
            {
                bubbles: true,
                cancelable: false,
                composed: true,
                detail: {
                    name: name,
                    newValue,
                    newValueDataType: newValueDataType
                }
            }
        );
        this.dispatchEvent(valueChangedEvent);
    }
    
    /**
     * @description notify salesforce that value has been changed
     * @param {string} typeName name of the type to change
     * @param {*} newValue new value to be changed
     * @param {string} newValueDataType data type of the new value
     */
    dispatchTypeChanged(typeName, newValue) {
        const typeChangedEvent = new CustomEvent(
            'configuration_editor_generic_type_mapping_changed',
            {
                bubbles: true,
                cancelable: false,
                composed: true,
                detail: {
                    typeName: typeName,
                    typeValue: newValue
                },
            }
        );
        this.dispatchEvent(typeChangedEvent);
    }

    /**
     * @description handle any variable change
     * @param {*} event 
     */
    handleChange(event) {
        if (event && event.detail) {
            let variableName = event.target.dataset.id;
            let newValueDataType = event.target.dataset.type;
            let newValue;

            if(newValueDataType === DATA_TYPE_BOOLEAN){
                newValue = event.target.checked;
            } else {
                newValue = event.detail.value;
                if (newValue.startsWith('{!') && !newValue.startsWith('{!$') && newValue.endsWith('}') && newValue !== '{!}') {
                    newValueDataType = DATA_TYPE_REFERENCE;
                } else if( newValueDataType === DATA_TYPE_NUMBER && !isNaN(newValue)) {
                    newValue = parseInt(newValue, 10);
                }
                
            }
            this.dispatchInputChanged(variableName, newValue, newValueDataType);

            if (variableName === 'sourceCollection') {
                const param = this.inputVariables.find(({ name }) => name === 'sourceCollection');
                if (param) {
                    let newObjectType = this.getVariableObjectType(newValue.replace('{!','').replace('}',''));
                    if(newObjectType) {
                        this.dispatchTypeChanged('T', newObjectType);
                        this.dispatchInputChanged('childObjectApiName', newObjectType, 'String');
                    }
                }
            } else if(variableName === 'childObjectApiName'){
                if(newValue) {
                    this.dispatchTypeChanged('T', newValue);
                }
            }
        }
    }


    /**
    * @description to validate input when user click on done button
    * @returns {string[]} key and error string of the errors if any
    */
    @api validate(){
        const validity = [];
        const componentList = this.template.querySelectorAll('lightning-input, lightning-combobox');
        for(let cmp of componentList){
            
            //check is the component required
            if(cmp.required && !cmp.value){
                validity.push({
                    key:cmp.label,
                    errorString: 'required'
                });
                cmp.reportValidity();
                continue;
            } else {
                cmp.setCustomValidity('');
                cmp.reportValidity();
            }

            //check validity of the sourceCollection (datatype)
            if(cmp.dataset.id === 'sourceCollection'){
                const {valid, isCollection} = this.sourceCollectionAreValidObject();
                if(!valid){
                    let errorMsg = INVALID_OBJECT_TYPE_LABEL;
                    cmp.setCustomValidity(errorMsg);
                    validity.push({
                        key: cmp.label,
                        errorString: errorMsg
                    });
                    cmp.reportValidity();
                    continue;
                } else if (!isCollection) {
                    let errorMsg = NOT_A_COLLECTION.format([cmp.value]);
                    cmp.setCustomValidity(errorMsg);
                    validity.push({
                        key: cmp.label,
                        errorString: errorMsg
                    });
                    cmp.reportValidity();
                    continue;
                } else {
                    cmp.setCustomValidity('');
                    cmp.reportValidity();
                }
            }
        }

        return validity;
    }

    /**
     * check and get is valid type, is collection
     * @returns validated flags 
     */
    sourceCollectionAreValidObject(){
        const tParam = this.genericTypeMappings.find(({typeName}) => typeName === 'T');
        if(!tParam) {
            return {valid: false, isCollection: false};
        }
        
        let variableName = '';
        let inputVariableParam = this.inputVariables.find(({name}) => name === 'sourceCollection');
        if(inputVariableParam) variableName = inputVariableParam.value;
        if(!variableName) {
            return {valid: false, isCollection: false};
        }

        let isCollection = false;
        

        let variableLookup = this.builderContext.recordLookups.find(({name}) => name === variableName);
        if(variableLookup){

            if(!variableLookup.getFirstRecordOnly){
                isCollection = true;
            }
            return {valid: true, isCollection: isCollection};
        }
        
        let variableVariable = this.builderContext.variables.find(({name}) => name === variableName);
        if(variableVariable){

            if(variableVariable.isCollection){
                isCollection = true;
            }
            return {valid: true, isCollection: isCollection};
        }

        //we are not able to get the output variable of a component,
        //so we will not stop them if it is refer to a screen component
        let screenFieldName = variableName.split('.')[0];
        for(let screen of this.builderContext.screens){
            if(screen.fields.find(({name}) => name === screenFieldName)){
                return {valid: true, isCollection: true};
            }
        }

        return {valid: false, isCollection: isCollection};
    }

    /**
     * 
     * @param {string} variableName collection / lookup api name without '{!' and '}'
     * @returns 
     */
    getVariableObjectType(variableName){
        let variableLookup = this.builderContext.recordLookups.find(({name}) => name === variableName);
        if(variableLookup){
            return variableLookup.object;
        }
        
        let variableVariable = this.builderContext.variables.find(({name}) => name === variableName);
        if(variableVariable){
            return variableVariable.objectType;
        }

        //if the variableName is xxxxx.selectedRows (selectedRows from another custom single related list)
        //we need to find the origin type from the component
        if(variableName.endsWith('.selectedRows')) {

            let originCmpName = variableName.split('.')[0];
            for(let screenCmp of this.builderContext.screens){
                if(screenCmp.fields?.length > 0) {
                    let fieldObject = screenCmp.fields?.find(field => field.name === originCmpName);
                    if(fieldObject && fieldObject.dataTypeMappings && fieldObject.dataTypeMappings.length > 0) {
                        let typeObject = fieldObject.dataTypeMappings.find(dataType => dataType.typeName === 'T');
                        if(typeObject) {
                            return typeObject.typeValue;
                        }
                    }
                }
            }
        }

        return '';
    }

    /**
    * @descripton library loader
    */
    handleLibLoadSuccess() {
        this.isScriptLoaded = true;
        this.isInitSuccess = true;
        if(this.inputVariables?.length === 0) {
            //length of inputVariables can only be 0 if the related list is first initialize
            this.initSource();
        }
    }

    //initialisation, set default
    initSource() {
        this.setDefault('recordId', '{!recordId}', DATA_TYPE_STRING);
        this.setDefault('targetRecordIdField', 'Id', DATA_TYPE_STRING);
        this.setDefault('sortedBy', 'Name', DATA_TYPE_STRING);
        this.setDefault('sortedDirection', 'asc', DATA_TYPE_STRING);

        this.setDefault('enableNewButton', true,  DATA_TYPE_BOOLEAN);
        this.setDefault('enableRowViewButton', true,  DATA_TYPE_BOOLEAN);
        this.setDefault('enableRowEditButton', true,  DATA_TYPE_BOOLEAN);
        this.setDefault('enableRowDeleteButton', true,  DATA_TYPE_BOOLEAN);
        this.setDefault('enableRowDownloadButton', true,  DATA_TYPE_BOOLEAN);
        this.setDefault('downloadUrl', '/sfc/servlet.shepherd/version/download/{0}?operationContext=S1',  DATA_TYPE_STRING);
        
        this.setDefault('maxHeight', 300,  DATA_TYPE_NUMBER);
        this.setDefault('showRowNumber', true,  DATA_TYPE_BOOLEAN);
        this.setDefault('rowsToLoad', 10,  DATA_TYPE_NUMBER);
        this.setDefault('enableClickableRefField', false,  DATA_TYPE_BOOLEAN);

        this.setDefault('useSourceCollectionRecords', false, DATA_TYPE_BOOLEAN);
        this.setDefault('refTarget', '_blank', DATA_TYPE_STRING);
        this.setDefault('viewMode', 'Related List', DATA_TYPE_STRING);
    }

    /**
     * @descritipon set default value if variable not found
     * @param {string} variableName name of the variable to change
     * @param {*} value new value to be changed
     * @param {string} dataType data type of the new value
     */
    setDefault(variableName, value, dataType){
        const param = this.inputVariables.find(({ name }) => name === variableName);
        if(!param){
            this.dispatchInputChanged(variableName, value, dataType);
        }
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
    get isLoading() {
        return this.loadedLists === 0 ? false : true;
    }

    /**
     * @descripton Console log for debugging
     */
    consoleLog(anything, isJson) {
        logInfo('CustomSingleRelatedListConfigurationEditor', anything, this.enableDebugMode, isJson);
    }

}