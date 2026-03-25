/**
 * @Author 		WDCi (Jordan)
 * @Date 		Mar 2024
 * @group 		Continuing Education
 * @Description Lwc for continuing education filtering
 * @changehistory
 * ISS-001844 06-03-2024 Jordan - new lwc
 */

import { LightningElement, api, wire, track } from 'lwc';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';
import { customLabels } from 'c/labelLoader';

//refresh module
import { RefreshEvent, registerRefreshHandler, unregisterRefreshHandler } from 'lightning/refresh';

export default class ContinuingEduFiltering extends LightningElement {
    //configurable attributes
    @api objectApiName;
    @api backgroundImageUrl;
    @api headerLabel;
    @api clearAllFilterLabel;
    @api searchButtonLabel;
    @api globalSearchFieldApiName;
    @api globalSearchBoxLabel;

    @api customFilter1Active;
    @api customFilter1Label;
    @api customField1ApiName;

    @api customFilter2Active;
    @api customFilter2Label;
    @api customField2ApiName;

    @api customFilter3Active;
    @api customFilter3Label;
    @api customField3ApiName;

    @api customFilter4Active;
    @api customFilter4Label;
    @api customField4ApiName;

    @api enableDebugMode = false;

    //internal attributes
	isScriptLoaded = false;
	isInitSuccess = false;
	loadedLists = 0;
    searchValue = '';
    customFilters;
	
    //refresh handler
    refreshHandlerID;

	//labels
	label = customLabels;
	
	//js library module 'lodash', 'stringutil', 'noheadercss', 'continuingeducss', 'moment', 'fullcalendar', 'fcmoment', 'tooltips'
    modules = ['continuingeducss'];

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
     * @descripton rendered callback
     */
	renderedCallback(){

    }

    /**
     * @descripton connected callback
     */
    connectedCallback(){
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
        
        return new Promise((resolve) => {
            resolve(true);
        });

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
        logInfo('ContinuingEduFiltering', anything, this.enableDebugMode, isJson);
    }

    /**
     * @description Has active custom filters
     */
    get hasActiveCustomFilters() {
        return (
            (this.customFilter1Active) || 
            (this.customFilter2Active) || 
            (this.customFilter3Active) || 
            (this.customFilter4Active)
        );
    }

    /**
     * @description Return custom filters config
     */
    get customFilterConfigs() {
        this.consoleLog('get customFilterConfigs');
        
        if (this.hasActiveCustomFilters) {
            
            let configs = [];

            if (this.customFilter1Active) {
                configs.push({
                    seq: 1,
                    showFilter: this.customFilter1Active,
                    label: this.customFilter1Label,
                    mapping: this.customField1ApiName + '=' + this.customField1ApiName
                });
            }

            if (this.customFilter2Active) {
                configs.push({
                    seq: 2,
                    showFilter: this.customFilter2Active,
                    label: this.customFilter2Label,
                    mapping: this.customField2ApiName + '=' + this.customField2ApiName
                });
            }

            if (this.customFilter3Active) {
                configs.push({
                    seq: 3,
                    showFilter: this.customFilter3Active,
                    label: this.customFilter3Label,
                    mapping: this.customField3ApiName + '=' + this.customField3ApiName
                });
            }

            if (this.customFilter4Active) {
                configs.push({
                    seq: 4,
                    showFilter: this.customFilter4Active,
                    label: this.customFilter4Label,
                    mapping: this.customField4ApiName + '=' + this.customField4ApiName
                });
            }

            this.consoleLog(configs, true);

            return JSON.stringify(configs);
        }

        return null;
    }

    /**
     * @description This method is used to handle the message/data coming from other component.
     */
    handleFiltersUpdate(event) {
        this.consoleLog('continuingEduFilterUpdate');
        if (event.detail) {
            this.consoleLog(event.detail.customFilters, true);
            this.customFilters = JSON.stringify(event.detail.customFilters);

            this.consoleLog(this.customFilters, true);
        }
    }

    //This method is used to get the updated value which user will input.
    handleSearchBoxChange(event) {
        if (event.target.name === this.globalSearchFieldApiName) {
            this.searchValue = event.target.value;
        }
    }

    /**
     * @description Post the filter details to parent component
     */
    sendEvent(){
        //Create event to send back to parent component
        let ceFiltersUpdatedEvent = new CustomEvent("cefiltersupdated", {
            "detail": { 
                searchFieldApiName: this.globalSearchFieldApiName,
                searchValue: this.searchValue,
                customFilters: this.customFilters 
            }
        });
        //Fire the event
        this.dispatchEvent(ceFiltersUpdatedEvent);
    }

    /**
     * @description Post the filter details to parent component (clear)
     */
    unSendEvent() {
        this.template.querySelector("c-custom-filters").unsetSourceSobjField();
        this.searchValue = '';

        //Create event to send back to parent component
        let ceFiltersUpdatedEvent = new CustomEvent("cefiltersupdated", {
            "detail": { 
                searchFieldApiName: this.globalSearchFieldApiName,
                searchValue: this.searchValue,
                customFilters: this.customFilters 
            }
        });
        //Fire the event
        this.dispatchEvent(ceFiltersUpdatedEvent);
    }

    get searchBoxCss() {

        if (this.backgroundImageUrl) {
            return 'continuingedufiltering-searchboxes continuingedufiltering-searchboxes-with-img slds-container_center';
        }

        return 'continuingedufiltering-searchboxes slds-container_center';
    }
}