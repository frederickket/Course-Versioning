/**
 * @Author 		WDCi (Jordan)
 * @Date 		Jan 2024
 * @group 		Continuing Education
 * @Description Parent component for continuingEduFiltering and continingEduListing
 * @changehistory
 * ISS-001844 21-03-2024 Jordan - new component
 */
import { LightningElement, api, wire, track } from 'lwc';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';
import { customLabels } from 'c/labelLoader';

//refresh module
import { RefreshEvent, registerRefreshContainer, unregisterRefreshContainer } from 'lightning/refresh';


export default class ContinuingEduCatalog extends LightningElement {
	
	@api objectApiName;
    
    //configurable attributes (filtering component)
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

    //configurable attributes (listing component)
    @api predefinedFilters;
    @api noOfRecordsPerPage;
    @api imageFieldApiName;

    @api field1ApiName;
    @api field2ApiName;
    @api field3ApiName;
    @api field4ApiName;

    @api sortByField1ApiName;
    @api sortByField2ApiName;
    @api sortByFieldLabel;
    @api showMoreButtonLabel;
    @api filteredResultFoundHeading;
    
    @api enableDebugMode = false;
	
	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false;
	loadedLists = 0;

    //track the filters from filtering component
    refreshRecordsFlag = false;
    searchFieldApiName;
    searchValue;
    customFilterConfigs;
	
    //refresh Container
    refreshContainerID;

	//labels
	label = customLabels;
	
	//js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'tooltips'
    modules = [];
	
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
		this.refreshContainerID = registerRefreshContainer(this, this.refreshData);
	}
	
    /**
     * @descripton disconnected callback
     */
	disconnectedCallback() {
		unregisterRefreshContainer(this.refreshContainerID);
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
        logInfo('ContinuingEduCatalog', anything, this.enableDebugMode, isJson);
    }

    /**
     * @description This method is used to handle the message/data coming from other component.
     */
    handleCeFiltersUpdate(event) {
        this.consoleLog('handleCeFiltersUpdate');
        if (event.detail) {
            this.searchFieldApiName = event.detail.searchFieldApiName;
            this.searchValue = event.detail.searchValue;
            this.customFilterConfigs = event.detail.customFilters;

            this.refreshRecordsFlag = true;

            this.consoleLog('searchFieldApiName :: ' + this.searchFieldApiName);
            this.consoleLog('searchValue :: ' + this.searchValue);
            this.consoleLog('customFilterConfigs :: ' + this.customFilterConfigs);
        }
    }

    /**
     * @description This method is used to handle the message/data coming from other component.
     */
    handleRecordsRefreshed() {
        this.consoleLog('handleRecordsRefreshed');
        this.refreshRecordsFlag = false;
    }
	
}