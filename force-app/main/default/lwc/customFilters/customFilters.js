/**
 * @Author 		WDCi (Lean)
 * @Date 		Oct 2023
 * @group 		Custom Filter
 * @Description Generic lwc for custom filter
 * @changehistory
 * ISS-001752 28-10-2023 Lean - new lwc
 * ISS-002188 14-01-2025 XW - added resetToDefault function
 */
import { LightningElement, api, wire, track } from 'lwc';
import { promptInfo, promptError, promptWarning, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';
import { updatedObjReactor } from 'c/lwcUtil';
import { customLabels } from 'c/labelLoader';

import { refreshApex } from '@salesforce/apex';
import { registerRefreshHandler, unregisterRefreshHandler } from 'lightning/refresh';

//Apex methods
import ctrlInitFilters from '@salesforce/apex/REDU_CustomFilters_LCTRL.initCustomFilterConfigs';


export default class CustomFilters extends LightningElement {
	
	//configurable attributes
    @api messageOperationName;
    @api sourceRecordId;
    @api sourceObjectType;
    @api targetObjectType;
    @api customFilterConfigs; //stringified json data
    @api defaultColumnSize = 12;
    @api largeDeviceColumnSize = 3;
    @api showPicklistAsMultiSelect = false;
    @api includeNoneOption = false;
	@api enableDebugMode = false;
	
	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false;
	loadedLists = 0;
	
    @track customFiltersResult;
    @track customFiltersResponse;
    customFiltersDefault; //ISS-002188

    //refresh handler
    refreshHandlerID;

	//labels
	label = customLabels;
    
    /**
     * @descripton rendered callback
     */
	renderedCallback(){

    }

    /**
     * @descripton connected callback
     */
    connectedCallback(){
        this.consoleLog(this.sourceRecordId);
        this.consoleLog(this.sourceObjectType);
        this.consoleLog(this.targetObjectType);
        this.consoleLog(this.customFilterConfigs);

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
     * @returns Promise
     */
    refreshData() {
        this.consoleLog('refreshData');

        refreshApex(this.customFiltersResult);

        return new Promise((resolve) => {
            resolve(true);
        });
    }

    /**
     * @description Initiate custom filter configs based on the minimum customFilterConfigs JSON serialized string
     * @param {*} result 
     */
    @wire(ctrlInitFilters, {
        sourceRecordId: "$sourceRecordId", 
        sourceObjectType: "$sourceObjectType",
        targetObjectType: "$targetObjectType",
        customFilterConfigs: "$customFilterConfigs",
        includeNoneOption: "$includeNoneOption"
    })
    wireFiltersConfig(result) {
        this.customFiltersResult = result;
        this.customFiltersResponse = null;

        if (result.data && result.data.responseData) {
            this.customFiltersResponse = JSON.parse(result.data.responseData);

            this.consoleLog('wireFiltersConfig');
            this.customFiltersDefault = JSON.parse(JSON.stringify(this.customFiltersResponse));
            //we notify the parent when the data is initiated for the first time
            this.notifyParent();
        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    /**
     * @description Return custom filters configs
     */
    get customFilters() {
        if (this.customFiltersResponse) {
            return this.customFiltersResponse;
        }

        return null;
    }

    /**
     * @description Return layout item css class
     */
    get cssClass() {
        if (this.largeDeviceColumnSize && this.largeDeviceColumnSize >= 12) {
            return 'customfilters-layout-item';
        }

        return 'customfilters-layout-item slds-p-right_small';
    }

    /**
     * @description Handle filter field change
     * @param {*} event 
     */
    handleFilterChange(event) {
        this.consoleLog('handleFilterChange');

        if (event.detail) {
            let updatedCf = event.detail.customFilter;
            this.consoleLog(updatedCf, true);

            for (let cf of this.customFilters) {
                if (cf.seq === updatedCf.seq) {
                    cf.sourceSobj = updatedCf.sourceSobj;

                    this.consoleLog('found');
                }
            }

            this.notifyParent();
        }
    }

    /**
     * @description Post the filter details to parent component
     */
    notifyParent(){

        //Create event to send back to parent component
        let filtersUpdatedEvent = new CustomEvent("filtersupdated", {
            "detail": { 
                customFilters: this.customFilters 
            }
        });
        //Fire the event
        this.dispatchEvent(filtersUpdatedEvent);
    }

    /**
     * @description Unset the source sobject field on all custom filter configs
     */
    @api
    unsetSourceSobjField() {
        for (let cf of this.customFilters) {
            cf.sourceSobj[cf.sourceFieldName] = null;
        }

        this.notifyParent();
        
        let cfFields = this.template.querySelectorAll('c-custom-filter-field');
        cfFields.forEach( cfField=>cfField.initiateFieldValue() );
    }

    /** ISS-002188
     * @description reset to the default filters
     */
    @api resetToDefault() {
        this.customFiltersResponse = JSON.parse(JSON.stringify(this.customFiltersDefault));
        this.notifyParent();
    }

    /**
     * @descripton Spinner loading status
     */
	get isLoading(){
        return this.loadedLists === 0 && this.customFiltersResponse ? false : true;
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
        logInfo('customFilters', anything, this.enableDebugMode, isJson);
    }
	
}