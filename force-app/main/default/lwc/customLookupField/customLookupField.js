/**
 * @Author 		WDCi (XW)
 * @Date 		Nov 2025
 * @group 		Custom Lookup Field
 * @Description search and select lookup value. can be fallback
 * @changehistory
 * ISS-002633 12-11-2025 XW - new class
 */
import { LightningElement, api, wire, track } from 'lwc';
import { promptInfo, promptError, promptWarning, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';
import { getMergeKeys, mergeValues } from 'c/lwcUtil';
import { customLabels } from 'c/labelLoader';
import LANG from '@salesforce/i18n/lang';
import recordFormModal from 'c/recordFormModal';

//Apex methods
import ctrlGetRecords from '@salesforce/apex/REDU_CustomLookupField_LCTRL.getRecords';
import ctrlGetSelectedRecord from '@salesforce/apex/REDU_CustomLookupField_LCTRL.getSelectedRecord';
import ctrlGetLookupFieldInfo from '@salesforce/apex/REDU_CustomLookupField_LCTRL.getLookupFieldInfo';
import ctrlUpdateRecordLastViewed from '@salesforce/apex/REDU_CustomLookupField_LCTRL.updateRecordLastViewed';

//labels
import CREATE_NEW_RECORD_LABEL from '@salesforce/label/c.Create_New_Record';
import COMPLETE_THIS_FIELD_LABEL from '@salesforce/label/c.Complete_This_Field';
import NO_RECORDS_TO_DISPLAY_LABEL from '@salesforce/label/c.No_Records_To_Display';
import RECORD_IS_NOT_LISTED_LABEL from '@salesforce/label/c.Student_Achievement_Record_Is_Not_Listed';

const ID_CREATE_NEW_RECORD = 'newRecord';
const ADD_ICON = 'utility:add';

export default class CustomLookupField extends LightningElement {
	
    //configurable attributes
    @api rootObjectName; //the root object name 
    @api lookupFieldName; //the lookup field name

    @api titleFormat; //title format string that enclose field name with {}
    @api subtitleFormat; //title format string that enclose field name with {}
    @api searchFields = 'Name'; //the fields name to be search by. seperated by semi colon(;)
    @api required = false; //is required 

    @api defaultIconName; //icon name 
    @api disabled = false;
    @api customFilter;
    @api customFilterBindMap;
    @api customLabel;
    @api enableNewRecordCreation = false; //allow user to create new record if record is not found
    @api preselectedRecordId = ''; //preselcted record id to the custom lookup field
    @api hideLabel = false;     
    @api lookupFieldData; //any data that will be pass back to the parent when dispatching event
    @api enableFallback = false; //allow fallback value
    @api searchFieldPlaceholder; //
    @api fallbackPlaceholder;
    @api fallbackLabel;
    @api defaultFallbackValue;
    @api helpText;

    @api set readOnly(value) {
        if(typeof value === "string" && value?.toLowerCase() === "true") {
            this._readOnly = true;
        } else if (typeof value === "string" && value?.toLowerCase() === "false") {
            this._readOnly = false;
        } else {
            this._readOnly = !!value;
        }
    }

    get readOnly() {
        return this._readOnly;
    }
    
    @api isNotListed; //true to tick the is not listed
    @api defaultSearchKeyword;
        
	@api enableDebugMode = false;
	
	//internal attributes
    _readOnly = false;
	isScriptLoaded = false;
	isInitSuccess = false
	loadedLists = 0;
    @track openOptions = false;
    spanningClassOpen = "slds-form-element slds-lookup slds-is-open";
    spanningClassClose = "slds-form-element slds-lookup slds-is-close";
    @track searchKeywordValue;
    @track rawRecords = [];
    fieldObjectIconName;
    @track selectedRecordId;
    @track translationInfo;
    @track fieldLabel;
    @track fieldObjectName;
    isNotListedValue = false;

	//labels
	label = customLabels;
	
	//js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'jquery', 'tooltips'
    modules = ['stringutil'];

    get searchPlaceholder() {
        return this.readOnly ? '' : this.searchFieldPlaceholder;
    }

    get fallbackLabelToDisplay() {
        return this.fallbackLabel ?? this.labelToDisplay;
    }    

    get labelToDisplay() {
        return this.customLabel ?? this.fieldLabel;
    }

    get fieldsToQuery() {
        let result = ['Id', 'Name'];
        if(this.titleFormat) {
            result = result.concat(getMergeKeys(this.titleFormat, true));
        }
        if(this.subtitleFormat) {
            result = result.concat(getMergeKeys(this.subtitleFormat, true));
        }
        if(this.searchFields) {
            result = result.concat(this.searchFields.split(';'));
        }
        return result;
    }

    //the selected record based on the id
    get selectedRecord() {
        if(this.selectedRecordId) {
            return this.selectableRecords?.find(rec => rec.id === this.selectedRecordId);
        }
        return null;
    }

    get hasSelectedRecord() {
        return !!this.selectedRecord;
    }

    get spanningClass() {
        if(this.openOptions) {
            return this.spanningClassOpen;
        } 
        return this.spanningClassClose;
        
    }

    get noRecordsToDisplayLabel() {
        return NO_RECORDS_TO_DISPLAY_LABEL;
    }

    /**
     * @description the user language
     */
    get language() {
        return LANG;
    }

    //-----------------------------------fallback-------------------------------

    get showFallbackInput() {
        return this.enableFallback && this.isNotListedValue;
    }

    get showFallbackCheckbox() {
        return this.enableFallback && !this.readOnly;
    }

    get fallbackInputSize() {
        return this.enableFallback ? 6 : 12;
    }

    get fallbackCheckboxSize() {
        return this.enableFallback ? 6 : 0;
    }

    get isNotListedLabel() {
        return RECORD_IS_NOT_LISTED_LABEL.format([this.labelToDisplay]);
    }

    get disableNotListedCheckbox() {
        return this.selectedRecordId || this.readOnly;
    }

    handleNotListedCheckboxChange(event) {
        let checked = event.detail.checked;
        this.isNotListedValue = checked;
        if(this.defaultFallbackValue && checked) {
            this.searchKeywordValue = this.defaultFallbackValue;
        }
        this.dispatchLookupChangeEvent(true);
    }

    handleFallbackFieldChange(event) {
        this.searchKeywordValue = event.detail.value;
        this.dispatchLookupChangeEvent();
    }

    //---------------------------------base function---------------------------------------------

    get inputClass() {
        return this.showFallbackCheckbox ? "slds-p-right_small" : "";
    }

    /**
     * @description set custom validity from parent cmp
     */
    @api setCustomValidity(value) {
        let element = this.template.querySelector('lightning-input');
        element?.setCustomValidity(value);
    }

    /**
     * @description set custom validity from parent cmp
     */
    @api reportValidity() {
        if(this.selectedRecordId) {
            return true;
        }
        
        let element = this.template.querySelector('lightning-input');
        let required = element.dataset.required === 'true';
        if(this.searchKeywordValue && !this.selectedRecordId && !this.isNotListedValue) {
            element.setCustomValidity(COMPLETE_THIS_FIELD_LABEL);
        } else if(this.selectedRecordId || (!required && !this.selectedRecordId && !this.searchKeywordValue)) {
            element.setCustomValidity('');
        }
        
        return element.reportValidity();
    }

    /**
     * @description clear
     */
    @api clear() {
        this.consoleLog('clear');
        this.searchKeywordValue = null;
        if(this.selectedRecordId) {
            this.rawRecords = null;
            this.selectedRecordId = null;
            this.openOptions = false;

            this.dispatchLookupChangeEvent();
        }
    }
    
    handleClear() {
        this.clear();
    }

    /**
     * @description focus on the lookup field
     */
    handleFocus(){
        if(!this.readOnly) {
            this.consoleLog('handleFocus');
            this.doOpenOptions();
            this.getRecords();
        }
    }

    doOpenOptions() {
        this.consoleLog('doOpenOptions');
        this.setComboDropdownStyle();
        this.openOptions = true;
    }

	/**
	 * @description Set the style for combobox dropdown so that the options appear at the correct position and not blocked by modal footer
	 */
	setComboDropdownStyle() {
		let comboDiv = this.refs.combobodydiv;
		let dropdownDiv = this.refs.combodropdowndiv;

		if (comboDiv && dropdownDiv) {
			let rect = comboDiv.getBoundingClientRect();
			let divTop = rect.top + 30;
			let divWidth = rect.width;

			this.consoleLog(divTop);
			this.consoleLog(divWidth);

			dropdownDiv.style.left = 'auto';
			dropdownDiv.style.right = 'auto';
			dropdownDiv.style.top = `${divTop}px`;
			dropdownDiv.style.width = `${divWidth}px`;
			dropdownDiv.style.position = 'fixed';
            dropdownDiv.style.zIndex = 100;
		}
	}

    /**
     * @description handle when a key is pressed from keyboard
     */
    handleKeyPress(event) {
        this.consoleLog('handleKeyPress');
        this.searchKeywordValue = event.target.value;

        if(this.searchKeywordValue && this.searchKeywordValue.length > 0) {
            this.openOptions = true;
        }
        this.getRecords();
    }

    /**
     * @description handle when record is selected in ui. create record if is create record item is selected.
     */
    async handleSelectRecord(event) {
        this.consoleLog('handleSelectRecord');
        let selectedRecordFromEvent = event.currentTarget.dataset.id;

        if(selectedRecordFromEvent === ID_CREATE_NEW_RECORD) {
            this.selectedRecordId = await this.createNewParentRecord();
            await this.setSelectedRecord(this.selectedRecordId);
        } else {
            this.selectedRecordId = selectedRecordFromEvent; 

            this.searchKeywordValue = "";
            
            this.openOptions = false
            
        }
        if(this.selectedRecordId) {
            try {
                await ctrlUpdateRecordLastViewed({recordId: this.selectedRecordId});
            } catch (error) {
                promptError(this.label.ERROR_LABEL, getErrorMessage(error));
            }
            this.dispatchLookupChangeEvent();
        }

    }

    /**
     * @description get the label and the referenced object name of the lookup field
     */
    async getLookupFieldInfo() {
        if(this.fieldLabel && this.fieldObjectName){
            return;
        }
        
        try{
            let result = await ctrlGetLookupFieldInfo({rootObjectName: this.rootObjectName, lookupFieldName: this.lookupFieldName});

            let responseData = JSON.parse(result.responseData);
            this.fieldLabel = responseData?.fieldLabel;
            this.fieldObjectName = responseData?.fieldReferenceObjectName;
            this.consoleLog(`fieldLabel:${this.fieldLabel} - fieldObjectName:${this.fieldObjectName}`);
        } catch (error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
        }
    }

    /**
     * @description to create the new parent record
     * @returns 
     */
    async createNewParentRecord() {
        let newRecordId;
        await this.getLookupFieldInfo();
        try {
            let result = await recordFormModal.open({
                headerLabel: CREATE_NEW_RECORD_LABEL,
                columns: 2,
                layoutType: "Full",
                objectApiName: this.fieldObjectName
            });

            if(result) {
                this.consoleLog(result, true);
                const {operation, id} = result;
                if(operation !== "cancel") {
                    newRecordId = id;
                    this.consoleLog('newid');
                    this.consoleLog(id);
                    this.handleBlur();
                }
            }

        } catch(err) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(err));
        }
        return newRecordId;
    }

    handleBlur() {
        this.consoleLog('handleBlur');
        this.openOptions = false;
    }

    /**
     * @description find possible records based on the search keyword
     */
    async getRecords() {
        try {
            this.consoleLog('getRecords');

            let result = await ctrlGetRecords({
                lookupObjectName: this.fieldObjectName,
                fields: this.fieldsToQuery,
                searchFields: this.searchFields,
                searchKeyword: this.searchKeywordValue,
                customFilter: this.customFilter,
                customFilterBindMap: this.customFilterBindMap,
                language: this.language
            });
            
                
            if(result) {
                let responseData = JSON.parse(result.responseData);
                this.rawRecords = responseData.sobjList;
                this.fieldObjectIconName = responseData.objectIconName;
                this.translationInfo = responseData.translationInfo;
                
                this.consoleLog('rawRecords');
                this.consoleLog(this.rawRecords, true);
            }

        } catch (error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
        }
    }

    get selectableRecords() {
        let resultList = [];
        if(this.rawRecords && this.rawRecords.length) {
            let titleMergeKeys = getMergeKeys(this.titleFormat);
            let subtitleMergeKeys = getMergeKeys(this.subtitleFormat);
            
            for(let record of this.rawRecords) {
                let title = mergeValues(this.titleFormat, titleMergeKeys, record, true, this.translationInfo, this.language);
                let subtitle = mergeValues(this.subtitleFormat, subtitleMergeKeys, record, true, this.translationInfo, this.language);
                let result = {
                    iconName: this.fieldObjectIconName,
                    id: record.Id,
                    title: title,
                    subtitle: subtitle,
                    hoverTitle: title ?? subtitle ?? record.Id
                }
                resultList.push(result)
            }
        }

        //add new record
        if(this.enableNewRecordCreation) {
            let addNewRecordOption = {
                iconName: ADD_ICON,
                id: ID_CREATE_NEW_RECORD,
                title: CREATE_NEW_RECORD_LABEL,
                subtitle: null
            };
            resultList.push(addNewRecordOption);
        }
        return resultList;
    }

    get haveSelectableRecords() {
        return this.selectableRecords.length > 0;
    }

    dispatchLookupChangeEvent(isTogglingFallbackCheckbox){
        let msg = {
            detail: {
                isTogglingFallbackCheckbox: isTogglingFallbackCheckbox ?? false,
                rootObjectName: this.rootObjectName,
                lookupFieldName: this.lookupFieldName,
                fieldObjectName: this.fieldObjectName,
                value: this.selectedRecordId,
                lookupFieldData: this.lookupFieldData,
                isFallback: this.isNotListedValue,
                fallbackValue: this.searchKeywordValue,
            }
        }

        this.consoleLog('dispatchLookupChangeEvent')
        this.consoleLog(msg, true)
        this.dispatchEvent(new CustomEvent('lookupchange', msg));
    }

    /**
     * 
     * @param {*} newSearchKeyword the search keyword to be set
     * @param {*} setRecordIfFoundOne set the only record if found one
     * @param {*} openOptions open the selectable list if found any records
     * @returns 
     */
    @api async setSearchKeyword(newSearchKeyword, setRecordIfFoundOne, openOptions) {

        this.consoleLog('setSearchKeyword')
        if(this.searchKeywordValue !== newSearchKeyword) {
            this.searchKeywordValue = newSearchKeyword;
        }
        if(newSearchKeyword) {
            this.toggleSpinner(1);
            await this.getRecords();
            this.toggleSpinner(-1);

            //set the record if the setRecordIfFoundOne is true and there is only 1 selectable record 
            if(
                setRecordIfFoundOne && (
                    (this.selectableRecords.length === 1 && !!(this.enableNewRecordCreation) === false) || 
                    (this.selectableRecords.length === 2 && !!(this.enableNewRecordCreation) === true)
                
                )
            ) {
                this.selectedRecordId = this.selectableRecords[0].id;
                this.dispatchLookupChangeEvent();
                return;
            }
            
            //open the list if selectable list is not empty
            if(openOptions && this.selectableRecords.length > 0) {
                this.doOpenOptions();
            }
        }
        this.refs.searchbox?.focus();
    }
    
    /**
     * @descripton library loader
     */
    @api setIsNotListed(isNotListed) {
        if(isNotListed !== this.isNotListedValue) {
            this.isNotListedValue = isNotListed;
            this.dispatchLookupChangeEvent(true);
        }
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
     * @descripton connected callback
     */
    async connectedCallback(event){
        this.isNotListedValue = this.isNotListed;
        this.searchKeywordValue = this.defaultSearchKeyword;
        this.toggleSpinner(1);
        await this.getLookupFieldInfo();
        if(this.preselectedRecordId) {
            await this.setSelectedRecord(this.preselectedRecordId);
        }

        this.toggleSpinner(-1);
	}

    /**
     * @description set the record id
     * @param {*} recordId the record id to be set
     */
    @api async setSelectedRecord(recordId) {
        if(recordId && this.selectedRecordId !== recordId) {

            await this.getLookupFieldInfo();
            try{
                let result = await ctrlGetSelectedRecord({
                    lookupObjectName: this.fieldObjectName,
                    fields: this.fieldsToQuery,
                    selectedRecordId: recordId,
                    language: this.language
                })
            
                if(result) {
                    let responseData = JSON.parse(result.responseData);
                    this.rawRecords = responseData.sobjList;
                    this.fieldObjectIconName = responseData.objectIconName;
                    this.translationInfo = responseData.translationInfo;
                    this.selectedRecordId = recordId;
                    
                    this.consoleLog('rawRecords');
                    this.consoleLog(this.rawRecords, true);
                    this.dispatchLookupChangeEvent();
                }
            } catch(error) {
                
                promptError(this.label.ERROR_LABEL, getErrorMessage(error));
            }
        }
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
        logInfo('CustomLookupField', anything, this.enableDebugMode, isJson);
    }
	
}