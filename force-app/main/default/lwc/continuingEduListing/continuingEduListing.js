/**
 * @Author 		WDCi (Jordan)
 * @Date 		Mar 2024
 * @group 		Continuing Education
 * @Description Lwc for continuing education listing
 * @changehistory
 * ISS-001844 06-03-2024 Jordan - new lwc
 * ISS-002495 10-10-2025 XW - support translation for long text
 */

import { LightningElement, api, wire, track } from 'lwc';
import { promptInfo, promptError, promptWarning, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';
import { NavigationMixin } from 'lightning/navigation';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { customLabels } from 'c/labelLoader';
import { formatLanguageCodeToPosix } from 'c/lwcUtil';

import LANG from '@salesforce/i18n/lang';

import SOONEST_FILTERING_OPTION_LABEL from '@salesforce/label/c.Continuing_Education_Sorting_Option_Soonest';
import ASCENDING_NAME_FILTERING_OPTION_LABEL from '@salesforce/label/c.Continuing_Education_Sorting_Option_A_Z';
import DESCENDING_NAME_FILTERING_OPTION_LABEL from '@salesforce/label/c.Continuing_Education_Sorting_Option_Z_A';

//Apex methods
import ctrlFetchingObjectRecords from '@salesforce/apex/REDU_ContinuingEduListing_LCTRL.fetchingObjectRecords';


export default class ContinuingEduListing extends NavigationMixin(LightningElement) {
    //configurable attributes
    @api objectApiName;
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
    @api searchFieldApiName;
    @api searchValue;
    @api customFilterConfigs;
    @api enableDebugMode = false;

    //internal attributes
	isScriptLoaded = false;
	isInitSuccess = false;
	loadedLists = 0;

    @track rawData;
    @track translationInfo;
    //Attributes used to show data
    fieldApiNamesArray = [];
    //Pagination attributes
    currentPage = 1;
    
    //Attributes used for sorting

    sortByField;

    //for refreshing the data from parent component
    _refreshRecordsFlag = false;

    @api
    get refreshRecordsFlag() {
        return this._refreshRecordsFlag;
    }

    set refreshRecordsFlag(value) {
        this._refreshRecordsFlag = value;
        if (this._refreshRecordsFlag === true) {
            this.searchRecords();
            this.sendRecordsRefreshedEvent();
        }
    }

    //labels
	label = {
        SOONEST_FILTERING_OPTION_LABEL,
        ASCENDING_NAME_FILTERING_OPTION_LABEL,
        DESCENDING_NAME_FILTERING_OPTION_LABEL,
        ...customLabels
    };
	
	//js library module 'lodash', 'stringutil', 'noheadercss', 'continuingeducss', 'moment', 'fullcalendar', 'fcmoment', 'tooltips'
    modules = ['stringutil', 'continuingeducss'];

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
        this.initFields();
	}
	
    /**
     * @descripton disconnected callback
     */
	disconnectedCallback() {
        
	}
    
    /**
     * @descripton return fields for view from
     */
    get infoFields(){
        let fields = [];

        if(this.field1ApiName){
            fields.push(this.field1ApiName);
        }

        if(this.field2ApiName){
            fields.push(this.field2ApiName);
        }

        if(this.field3ApiName){
            fields.push(this.field3ApiName);
        }

        if(this.field4ApiName){
            fields.push(this.field4ApiName);
        }
        
        return fields;
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
        logInfo('ContinuingEduListing', anything, this.enableDebugMode, isJson);
    }

    /**
     * @descripton Get the object info
     */
    @wire(getObjectInfo, { objectApiName: '$objectApiName' })
    objectInfo;

    //This method is used to show the dropdown values for sorting.
    get sortingOptions() {
        let options = [];
        
        if (this.objectInfo.data && this.objectInfo.data.fields) {
            const fieldsMap = this.objectInfo.data.fields;

            if (this.sortByField1ApiName) {
                let fieldLabel = fieldsMap[this.sortByField1ApiName].label;

                if (fieldsMap[this.sortByField1ApiName].dataType === 'Date') {
                    options.push({ label: this.label.SOONEST_FILTERING_OPTION_LABEL.format([fieldLabel]), value: this.label.SOONEST_FILTERING_OPTION_LABEL.format([this.sortByField1ApiName]) });
                } else {
                    options.push({ label: this.label.ASCENDING_NAME_FILTERING_OPTION_LABEL.format([fieldLabel]), value: this.label.ASCENDING_NAME_FILTERING_OPTION_LABEL.format([this.sortByField1ApiName]) });
                    options.push({ label: this.label.DESCENDING_NAME_FILTERING_OPTION_LABEL.format([fieldLabel]), value: this.label.DESCENDING_NAME_FILTERING_OPTION_LABEL.format([this.sortByField1ApiName]) });
                }
            }
            
            if (this.sortByField2ApiName) {
                let fieldLabel = fieldsMap[this.sortByField2ApiName].label;

                if (fieldsMap[this.sortByField2ApiName].dataType === 'Date') {
                    options.push({ label: this.label.SOONEST_FILTERING_OPTION_LABEL.format([fieldLabel]), value: this.label.SOONEST_FILTERING_OPTION_LABEL.format([this.sortByField2ApiName]) });
                } else {
                    options.push({ label: this.label.ASCENDING_NAME_FILTERING_OPTION_LABEL.format([fieldLabel]), value: this.label.ASCENDING_NAME_FILTERING_OPTION_LABEL.format([this.sortByField2ApiName]) });
                    options.push({ label: this.label.DESCENDING_NAME_FILTERING_OPTION_LABEL.format([fieldLabel]), value: this.label.DESCENDING_NAME_FILTERING_OPTION_LABEL.format([this.sortByField2ApiName]) });
                }
            }
        }

        return options;
    }

    get showShortingDropdown() {
        if (this.sortByField1ApiName || this.sortByField2ApiName) {
            return true;
        }

        return false;
    }

    initFields() {
        try {

            if (this.field1ApiName && !this.fieldApiNamesArray.includes(this.field1ApiName)) {
                this.fieldApiNamesArray.push(this.field1ApiName);
            }

            if (this.field2ApiName && !this.fieldApiNamesArray.includes(this.field2ApiName)) {
                this.fieldApiNamesArray.push(this.field2ApiName);
            }

            if (this.field3ApiName && !this.fieldApiNamesArray.includes(this.field3ApiName)) {
                this.fieldApiNamesArray.push(this.field3ApiName);
            }

            if (this.field4ApiName && !this.fieldApiNamesArray.includes(this.field4ApiName)) {
                this.fieldApiNamesArray.push(this.field4ApiName);
            }

            if (this.imageFieldApiName && !this.fieldApiNamesArray.includes(this.imageFieldApiName)) {
                this.fieldApiNamesArray.push(this.imageFieldApiName);
            }

            if (this.fieldApiNamesArray.length) {
                this.searchRecords();
            }

        } catch (error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
        }
    }

    //Apex backend method.
    searchRecords() {
        this.consoleLog('searchRecords');

        this.toggleSpinner(1);

        try {
            ctrlFetchingObjectRecords({ 
                objectName: this.objectApiName, 
                fieldApiNames: this.fieldApiNamesArray, 
                sortByField1ApiName: this.sortByField1ApiName, 
                sortByField2ApiName: this.sortByField2ApiName, 
                predefinedFilters: this.predefinedFilters, 
                searchFieldApiName: this.searchFieldApiName, 
                searchValue: this.searchValue, 
                customFilterConfigs: this.customFilterConfigs,
                language: this.language
            }).then(response => {
                this.toggleSpinner(-1);

                if (response.isSuccess) {
                    if (response.responseData) {
                        this.currentPage = 1;
                        this.sortByField = null;
                        let responseData = JSON.parse(response.responseData);

                        this.rawData = responseData.rawData;
                        this.translationInfo = responseData.translationInfo;
                        
                        this.consoleLog(this.rawData, true);

                    } else {
                        this.rawData = [];
                    }

                } else if (!response.isSuccess) {
                    promptError(this.label.ERROR_LABEL, response.message);
                }

            }).catch((error) => {
                this.toggleSpinner(-1);
                promptError(this.label.ERROR_LABEL, getErrorMessage(error));
            })

        } catch(error) {
            this.toggleSpinner(-1);
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
        }
    }

    get hasMore() {
        if (this.currentPage < this.totalPage) {
            return true;
        }

        return false;
    }

    get totalRecordCount() {
        if (this.rawData) {
            return this.rawData.length;
        }

        return 0;
    }

    get totalPage() {

        if (this.rawData) {
            return this.rawData.length / this.noOfRecordsPerPage;
        }

        return 0;
    }

    get mainData() {
        this.consoleLog('get mainData');

        if (this.rawData) {
            let startIdx = 0;
            let endIdx = this.currentPage * this.noOfRecordsPerPage;

            let visibleRecords = this.rawData.slice(startIdx, endIdx);
            let translation = this.translationInfo?.translations?.find(tln => tln.languageCode === this.language);
            let visibleObjRecords = visibleRecords.map(item => ({
                Id: item.Id, 
                field1Value: translation?.data?.[item.Id]?.[this.field1ApiName] ? translation?.data?.[item.Id]?.[this.field1ApiName] : item[this.field1ApiName] ?? null, 
                field2Value: translation?.data?.[item.Id]?.[this.field2ApiName] ? translation?.data?.[item.Id]?.[this.field2ApiName] : item[this.field2ApiName] ?? null, 
                field3Value: translation?.data?.[item.Id]?.[this.field3ApiName] ? translation?.data?.[item.Id]?.[this.field3ApiName] : item[this.field3ApiName] ?? null, 
                field4Value: translation?.data?.[item.Id]?.[this.field4ApiName] ? translation?.data?.[item.Id]?.[this.field4ApiName] : item[this.field4ApiName] ?? null, 
                imageValue: item[this.imageFieldApiName] ? item[this.imageFieldApiName] : null, 
                field1Name: this.field1ApiName, 
                field2Name: this.field2ApiName, 
                field3Name: this.field3ApiName, 
                field4Name: this.field4ApiName
            }));

            this.consoleLog(visibleObjRecords, true);

            return visibleObjRecords;
        }

        return [];
    }

    //This method is used to get the next records when the user click on the show more button.
    handleShowMore() {
        if (this.currentPage < this.totalPage) {
            this.currentPage = this.currentPage + 1;
        }        
    }

    //This method is used to capture the user input in sorting dropdown.
    handleSortingChange(event) {
        this.sortByField = event.target.value;

        this.performDataSorting(this.sortByField);
    }

    performDataSorting(fieldToSort) {
        this.consoleLog('performDataSorting');
        
        let targetSortBy;
        if (fieldToSort.includes(this.sortByField1ApiName)) {
            targetSortBy = this.sortByField1ApiName;
        } else if (fieldToSort.includes(this.sortByField2ApiName)) {
            targetSortBy = this.sortByField2ApiName;
        }

        this.consoleLog(targetSortBy);

        let textAZ = this.label.ASCENDING_NAME_FILTERING_OPTION_LABEL.format([targetSortBy]);
        let textZA = this.label.DESCENDING_NAME_FILTERING_OPTION_LABEL.format([targetSortBy]);
        let dateSoonest = this.label.SOONEST_FILTERING_OPTION_LABEL.format([targetSortBy]);

        if (fieldToSort === textAZ) {
            this.sortData(targetSortBy, 'asc');

        } else if (fieldToSort === textZA) {
            this.sortData(targetSortBy, 'desc');

        } else if (fieldToSort === dateSoonest) {
            this.sortData(targetSortBy, 'asc');
        }
    }

    //This is the generic method used in sorting.
    sortData(fieldName, sortDirection) {
        let reverse = sortDirection !== 'asc';

        this.rawData = this.rawData.sort(this.sortBy(fieldName, reverse));
    }
    
    sortBy(field, reverse, primer) {
        
        let key = primer ?
            function(x) {return primer(x[field])} :
            function(x) {return x[field]};
        reverse = !reverse ? 1 : -1;

        return function (a, b) {
            return a = key(a), b = key(b), reverse * ((a > b) - (b > a));
        }
    }

    navigateToDetailPage(event) {
        this.consoleLog('navigateToDetailPage');
        this.consoleLog(event.currentTarget.dataset.id);

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: event.currentTarget.dataset.id,
                objectApiName: this.objectApiName,
                actionName: 'view'
            }
        });
    }

    /**
     * @description Notify parent that records have been refreshed
     */
    sendRecordsRefreshedEvent(){
        this.dispatchEvent(new CustomEvent("recordsrefreshed"));
    }

}