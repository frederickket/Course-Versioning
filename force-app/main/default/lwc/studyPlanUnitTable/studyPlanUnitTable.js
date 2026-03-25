/**
 * @Author 		WDCi (Lean)
 * @Date 		Nov 2023
 * @group 		Study Plan
 * @Description Study plan hierarchy wizard
 * @changehistory
 * ISS-001617 10-11-2023 Lean - new component
 * ISS-002152 04-11-2024 Jordan - Study Plan Wizard to support modification
 * ISS-002230 05-02-2025 XW - display picklist value label if field type is picklist
 * ISS-002330 24-03-2025 XW - display sps translation name in delete confirmation if found
 * ISS-002495 22-09-2025 XW - support translation for long text field
 * ISS-002736 25-11-2025 XiRouh - Added tableTextDisplayMode configurable attribute
 * ISS-002779 21-01-2026 Lean - Make table header to respect tableTextDisplayMode
 * ISS-002797 13-02-2025 Lean - Standardize language code format to POSIX
 */
import { LightningElement, api, wire, track } from 'lwc';
import { promptError } from 'c/toasterUtil';
import { getErrorMessage, logInfo } from 'c/loggingUtil';
import { updateDatatableConfig, isWrapTextEnabled, getTableHeaderDisplayMode, formatLanguageCodeToPosix } from 'c/lwcUtil';
import { customLabels } from 'c/labelLoader';
import LANG from '@salesforce/i18n/lang';

//refresh module
import { refreshApex } from '@salesforce/apex';
import { registerRefreshHandler, unregisterRefreshHandler } from 'lightning/refresh';

//Apex methods
import ctrlGetUnitTableData from '@salesforce/apex/REDU_StudyPlanUnitTable_LCTRL.getUnitTableData';

import NO_GROUP_UNIT_FOUND_LABEL from '@salesforce/label/c.No_Group_or_Unit_Found';
import ctrlGetTranslationFieldForNameByObjPrefix from '@salesforce/apex/REDU_Translation_LCTRL.getTranslationFieldForNameByObjPrefix';

const OBJ_TRANSLATION = [
    "SPS"
];

export default class StudyPlanUnitTable extends LightningElement {
	
	//configurable attributes
    @api spsParentId;
    @api spsRecordTypeInfo;
    @api spsUnitTableFields;
    @api enableClickableRefField = false;
    @api hrefTargetType;
    @api isCommunity;
    @api isModeView;
    @api unitModalFields;

    //ISS-002736
    @api tableTextDisplayMode;

	@api enableDebugMode = false;
	
	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false;
	loadedLists = 0;

    @track objectTranslatedNameResult;
    @track objectTranslatedNameResponse;

	
    //refresh handler
    refreshHandlerID;

    //wire attribute
    spsUnitTableWireResult;
    spsUnitTableData;

    //for table sorting
    @track sortBy;
    @track sortDirection;

	//labels
	label = {
        NO_GROUP_UNIT_FOUND_LABEL,
        ...customLabels
    };
	
	//js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'tooltips'
    modules = ['stringutil'];
	
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

        this.consoleLog(this.spsParentId);
        this.consoleLog(this.spsUnitTableFields);
        this.consoleLog(this.enableClickableRefField);
        this.consoleLog(this.hrefTargetType);
        this.consoleLog(this.isModeView);
        this.consoleLog(this.unitModalFields, true);
		
        this.refreshHandlerID = registerRefreshHandler(this, this.refreshData);
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
    refreshData() {
        this.consoleLog('refreshData');

        refreshApex(this.spsUnitTableWireResult);

        return new Promise((resolve) => {
            resolve(true);
        });

    }

    /**
     * @description Sample wire method that invoke apex controller to retrieve data
     */
    @wire(ctrlGetUnitTableData, {
        spsParentId: "$spsParentId",
        spsUnitTableFields: "$spsUnitTableFields",
        enableClickableRefField: "$enableClickableRefField",
        hrefTargetType: "$hrefTargetType",
        isModeView: "$isModeView",
        language: '$language',
        enableWrapText: '$enableWrapText'
    })
    wireUnitTableData(result) {
        
        this.spsUnitTableWireResult = result;
        this.spsUnitTableData = null;

        if (result.data) {
            let datatableConfig = JSON.parse(result.data.responseData);
            this.consoleLog(datatableConfig, true);
            
            let isCommunity = this.isCommunity;

            this.spsUnitTableData = updateDatatableConfig(datatableConfig, isCommunity, this.language);

            this.consoleLog(this.spsUnitTableData, true);

        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }

    }

    /**
     * @description the user language
     */
    get language() {
        return formatLanguageCodeToPosix(LANG);
    }

    /**
     * @descripton return Table display mode - enable wrap text
     */
    get enableWrapText() {
        return isWrapTextEnabled(this.tableTextDisplayMode);
    }

    /**
     * @description ISS-002779 return Table header display mode - enable wrap text
     */
    get tableHeaderDisplayMode() {
        return getTableHeaderDisplayMode(this.tableTextDisplayMode);
    }

    /**
     * @description Get Study Unit Translation Name
     */
    @wire(ctrlGetTranslationFieldForNameByObjPrefix, { objectPrefixes: OBJ_TRANSLATION})
    wiredTranslationFieldResult(result) {
        
        this.objectTranslatedNameResult = result;
        this.objectTranslatedNameResponse = null;

        if (result.data) {
            let response = result.data;
            if (response.responseData) {
                this.objectTranslatedNameResponse = JSON.parse(response.responseData);
            }
            this.consoleLog(this.objectTranslatedNameResponse, true);
            
        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    
    /**
     * @description return the study plan structure translation field for name
     */
    get spsNameTranslationField() {
        return this.objectTranslatedNameResponse?.SPS;
    }

    get tableColumns() {
        if (this.spsUnitTableData && this.spsUnitTableData.columns) {
            return this.spsUnitTableData.columns;
        }

        return null;
    }

    get spsUnits() {
        if (this.spsUnitTableData && this.spsUnitTableData.records) {
            return this.spsUnitTableData.records;
        }

        return null;
    }

    get hasSpsUnits() {
        if (this.spsUnits && this.spsUnits.length > 0 ) {
            return true;
        }

        return false;
    }

    /**
     * @description Return SPS Unit record type id
     */
    get spsUnitRecordTypeId() {
        return this.spsRecordTypeInfo?.spsUnitRecordTypeId;
    }

    /**
     * @description Return SPS Unit record type label
     */
    get spsUnitRecordTypeLabel() {
        return this.spsRecordTypeInfo?.spsUnitRecordTypeLabel;
    }
	
    /**
     * @description Sorting for datatable
     */
    doSorting(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortData(this.sortBy, this.sortDirection);
    }

    /**
     * @description Sorting for datatable
     */
    sortData(fieldname, direction) {
        let parseData = JSON.parse(JSON.stringify(this.spsUnitTableData.records));
        // Return the value stored in the field
        let keyValue = (a) => {
            return a[fieldname];
        };
        // cheking reverse direction
        let isReverse = direction === 'asc' ? 1: -1;
        // sorting data
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; // handling null values
            y = keyValue(y) ? keyValue(y) : '';
            // sorting values based on direction
            return isReverse * ((x > y) - (y > x));
        });
        this.spsUnitTableData.records = parseData;
    }

    /**
     * @descripton ISS-002152 Handle selected row action in the data table
     */
    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;
        
        const detail = {
            actionType: action.name,
            spsId: row.Id,
            spsName: row.Name,
            spsTranslationName: row[this.spsNameTranslationField],
            spsParentId: this.spsParentId,
            spsType: this.spsUnitRecordTypeId
        }

        const selectEvent = new CustomEvent('selection', {
            detail: detail
        });
        
        // Fire the custom event
        this.dispatchEvent(selectEvent);
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
        logInfo('StudyPlanUnitTable', anything, this.enableDebugMode, isJson);
    }
	
}