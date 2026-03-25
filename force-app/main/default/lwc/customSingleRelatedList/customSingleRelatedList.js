/**
 * @Author 		WDCi (XW)
 * @Date 		Nov 2024
 * @group 		Custom Single Related List
 * @Description Custom Single Related List component
 * @changehistory
 * ISS-002104 05-11-2024 XW - create new class
 * ISS-002387 09-04-2025 XW - fixed bug where checkbox is not ticked even if row is selected
 * ISS-002350 25-03-2025 XW - fixed bug where error prompted when picklist is updated inline
 * ISS-002604 10-09-2025 XW - fixed download url domain issue
 * ISS-002603 12-09-2025 Lean - Support user id and fixed records total stats
 * ISS-002495 22-09-2025 XW - support translation for long text field
 * ISS-002736 25-11-2025 XiRouh - Added tableTextDisplayMode configurable attribute
 * ISS-002779 21-01-2026 Lean - Make table header to respect tableTextDisplayMode
 */
import { LightningElement, api, wire, track } from 'lwc';
import { promptError, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';
import { initCacheIdx, updateDatatableConfig, commonConstants, removeLabelAttributes, getFileDownloadUrl, isWrapTextEnabled, getTableHeaderDisplayMode, formatLanguageCodeToPosix } from 'c/lwcUtil';
import { customLabels } from 'c/labelLoader';
import { NavigationMixin } from 'lightning/navigation';
import { updateRecord, notifyRecordUpdateAvailable, deleteRecord } from 'lightning/uiRecordApi';
import { getObjectInfo, getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import { FlowAttributeChangeEvent } from "lightning/flowSupport";
import LANG from '@salesforce/i18n/lang';

//modals
import RecordEditModal from 'c/recordEditModal'
import genericConfirmationModal from 'c/genericConfirmationModal';

//refresh module
import { registerRefreshContainer, unregisterRefreshContainer } from 'lightning/refresh';

import ctrlInitDatatable from '@salesforce/apex/REDU_CustomSingleRelatedList_LCTRL.initDatatable';

//labels
import NUMBER_OF_ITEMS_SELECTED_LABEL from '@salesforce/label/c.Number_of_Items_Selected';
import NUMBER_OF_ITEMS_LABEL from '@salesforce/label/c.Number_of_Items';

//for request
const RECORD_ID_PARAM = 'recordId';
const TARGET_RECORD_ID_PARAM = 'targetRecordIdField';
const PARENT_OBJECT_REF_FIELD_PARAM = 'parentObjectRefField';
const CHILD_OBJECT_API_NAME_PARAM = 'childObjectApiName';
const CHILD_OBJECT_FIELDS_PARAM = 'childObjectFields';
const CHILD_OBJECT_FILTER_CRITERIA_PARAM = 'childObjectFilterCriteria';
const ENABLE_VIEW_PARAM = 'enableRowViewButton';
const ENABLE_EDIT_PARAM = 'enableRowEditButton';
const ENABLE_DELETE_PARAM = 'enableRowDeleteButton';
const ENABLE_DOWNLOAD_PARAM = 'enableRowDownloadButton';
const REFERENCE_TARGET = 'refTarget'; 

const ROWS_TO_LOAD_PARAM = 'rowsToLoad';
const CURRENT_OFFSET_PARAM = 'currentOffset';

const ENABLE_CLICKABLE_REFFIELD_PARAM = 'enableClickableRefField';

const ENABLE_INLINE_EDIT_PARAM = 'enableInlineEditing';

const LANGUAGE_PARAM = 'language';

const WRAPTEXT_PARAM = 'wrapText';

//flow
const USE_SOURCE_COLLECTION_RECORDS = 'useSourceCollectionRecords';

//for response
const COLUMNS_PARAM = 'columns';
const REFLINKS_PARAM = 'refLinks';
const IS_COMMUNITY_PARAM = 'isCommunity';
const SITE_PATH_PARAM = 'sitePath';


const VIEW_MODE_RELATED_LIST = 'Related List';

const MASTER_RECORD_TYPE_ID = "012000000000000AAA";
export default class CustomSingleRelatedList extends NavigationMixin(LightningElement) {
	
    @api recordId;
    @api targetRecordId;

	//configurable attributes
    @api viewMode;
    @api modalTitle;
    @api modalIconName;
    @api targetRecordIdField;
    @api parentObjectRefField;
    @api childObjectApiName;
    @api childObjectFields;
    
    @api childObjectFilterCriteria;
    
    @api sortedBy;
    @api sortedDirection;

    @api enableRefreshButton = false;
    @api enableNewButton = false;
    @api enableRowViewButton = false;
    
    @api enableRowEditButton = false;
    @api editFieldSetName;
    @api editFormColumnNo = 2;
    @api editFormSize = 'small';

    @api enableRowDeleteButton = false;
    @api enableRowDownloadButton = false;
    @api downloadUrl;

    @api rowsToLoad;

    @api set maxHeight(value) {
        if(value){
            this._maxHeight = value;
            this.handleCardHeight();
        }
    }
    get maxHeight(){
        return this._maxHeight;
    }
    @api showRowNumber = false;
    @api enableInfiniteLoading = false;
    @api noRecordFoundMessage;
    @api enableClickableRefField = false;
    @api enableInlineEditing = false;
    @api refTarget;

    @api enableQuickSearch = false;

    @api tableTextDisplayMode;
    
	@api enableDebugMode = false;
    
    set datatableResponse(value){
        this._datatableResponse = value;
        if(Object.keys(value).length > 0) this.datatableResponsePostProcess();
        
    }

    get datatableResponse() {
        return this._datatableResponse;
    }
	
    //flow only
    @api enableRowSelection = false;
    @api set selectedRows(selectedRows){
        if(selectedRows){
            this._selectedRows = selectedRows;
            this._selectedRowsId = this._selectedRows.map(row => {
                return row.Id;
            });
        } else {
            this._selectedRows = [];
            this._selectedRowsId = [];
        }
    }

    get selectedRows(){
        return this._selectedRows;
    }

    @api set selectedRowsId(selectedRowsId) {
        if (selectedRowsId) {
            this._selectedRowsId = selectedRowsId;
        } else {
            this._selectedRowsId = [];
        }
    }

    get selectedRowsId() {
        return this._selectedRowsId;
    }

    @api useSourceCollectionRecords = false;

    @api set sourceCollection(sourceCollection){
        if(sourceCollection){
            this._sourceCollection = JSON.parse(JSON.stringify(sourceCollection));
            if(Object.keys(this.datatableResponse).length > 0) {
                this.doRefresh = true;
                this.datatableResponsePostProcess();
            }
        }
    }

    get sourceCollection(){
        return this._sourceCollection;
    }



	//internal attributes
    _maxHeight;
    _datatableResponse = {};
    @track _selectedRows = [];
    @track _selectedRowsId = [];
    @track _sourceCollection = [];


	isScriptLoaded = false;
	isInitSuccess = false
	loadedLists = 0;
    latestLoadedOffset = -1;
    draftValues = [];
    @track data;
    loadMoreOffset = 20;
    modifiedSortedBy;
    modifiedSortedDirection;
    quickSearchKeywords = ''
    doRefresh = false;
    hasQueried = false;
    relatedListData; //processed by updateDatatableConfig
	
    //refresh Container
    refreshContainerID;

    //local cache idx to force rerendering
    _cacheIdx;

	//labels
	label = customLabels;
	
	//js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'jquery', 'tooltips'
    modules = ['stringutil'];

    @wire(getObjectInfo,{objectApiName: '$childObjectApiName'})
    childObjectInfo

    //get all of the picklist values and labels
    @wire(getPicklistValuesByRecordType, {
        objectApiName: '$childObjectApiName',
        recordTypeId: MASTER_RECORD_TYPE_ID, //get all the picklist values regarding of the record type
    })
    childObjectPicklistValues;

    /**
     * @description Return the record id to be used
     */
    get finalRecordId() {
        if (this.targetRecordId) {
            return this.targetRecordId;
        }

        return this.recordId;
    }

    //true if display as related list
    get isRelatedList(){
        return this.viewMode === VIEW_MODE_RELATED_LIST;
    }

    /**
     * @description the user language
     */
    get language() {
        return formatLanguageCodeToPosix(LANG);
    }

    //config to be sent to apex controller
    get datatableConfig () {
        let config = {
            [RECORD_ID_PARAM] : this.finalRecordId,
            [TARGET_RECORD_ID_PARAM] : this.targetRecordIdField,
            [PARENT_OBJECT_REF_FIELD_PARAM] : this.parentObjectRefField,
            [CHILD_OBJECT_API_NAME_PARAM] : this.childObjectApiName,
            [CHILD_OBJECT_FIELDS_PARAM] : this.childObjectFields,
            [CHILD_OBJECT_FILTER_CRITERIA_PARAM] : this.childObjectFilterCriteria,

            [ENABLE_VIEW_PARAM] : !!this.enableRowViewButton,
            [ENABLE_EDIT_PARAM] : !!this.enableRowEditButton,
            [ENABLE_DELETE_PARAM] : !!this.enableRowDeleteButton,
            [ENABLE_DOWNLOAD_PARAM] : !!this.enableRowDownloadButton,

            [ROWS_TO_LOAD_PARAM] : this.rowsToLoad,
            [CURRENT_OFFSET_PARAM] : this.currentOffset,

            [ENABLE_CLICKABLE_REFFIELD_PARAM] : !!this.enableClickableRefField,
            [ENABLE_INLINE_EDIT_PARAM] : !!this.enableInlineEditing,
            [REFERENCE_TARGET] : this.refTarget,
            [USE_SOURCE_COLLECTION_RECORDS] : !!this.useSourceCollectionRecords,
            [LANGUAGE_PARAM] : this.language,
            [WRAPTEXT_PARAM] : this.enableWrapText,

            'cacheIdx': this._cacheIdx
        }

        return JSON.stringify(config);
    }

    /**
     * @descripton return Table display mode - enable wrap text
     */
    get enableWrapText() {
        return isWrapTextEnabled(this.tableTextDisplayMode);
    }

    /**
     * @description return Table header display mode - enable wrap text
     */
    get tableHeaderDisplayMode() {
        return getTableHeaderDisplayMode(this.tableTextDisplayMode);
    }

    //quick search bump if it is enabled
    get quickSearchBump(){
        return this.enableQuickSearch ? 'left' : '';
    }
    
    //refresh/new button bump if quick search is not enabled
    get buttonsBump() {
        return this.enableQuickSearch ? '' : 'left';
    }


    //label to show the total records and number of selected records
    get selectedItemsLabel(){
        let totalSize = this.filteredData ? this.filteredData.length : 0;
        let numberSelected = this.selectedRowCount;
        
        //ISS-002603 enhance label
        let numberOfItems = NUMBER_OF_ITEMS_LABEL.format([totalSize]);
        let numberOfSelected = NUMBER_OF_ITEMS_SELECTED_LABEL.format([numberSelected]);
        
        return this.enableRowSelection ? numberOfItems + numberOfSelected : numberOfItems;
    }

    /**
     * @description Return selected row count
     */
    get selectedRowCount() {
        return this._selectedRows?.length ?? 0;
    }
    
    //current records offset
    get currentOffset(){
        return !this.datatableResponseIsEmpty ? this.datatableResponse?.[CURRENT_OFFSET_PARAM] : 0;
    }

    //return true if no datatable response
    get datatableResponseIsEmpty(){
        return Object.keys(this.datatableResponse).length === 0;
    }

    //Child object label
    get childObjectLabel(){
        return this.childObjectInfo?.data?.label;
    }

    //if no data is display, stop the infinite loading
    get infiniteLoading(){
        return this.datatableData?.length < 0 ? false : this.enableInfiniteLoading;
    }

    //columns used in datatable
    _datatableColumns = [];
    get datatableColumns(){
        return this._datatableColumns;
    }

    set datatableColumns(value) {
        if(value){
            this._datatableColumns = value
        }
    }
    
    //data used in datatable
    get datatableData(){
        return this.data;
    }

    get datatableDataIsEmpty(){
        if(this.filteredData){
            return this.filteredData.length === 0;
        }
        return true;
    }

    //the filtered data after filter with quick search
    get filteredData(){
        this.consoleLog('filteredData: ');
        if(!this.quickSearchKeywords){
            this.consoleLog(this.datatableData, true);
            return this.datatableData;
        }

        let result = [];

        for(let row of this.datatableData){
            if(row.quickSearchString && row.quickSearchString.includes(this.quickSearchKeywords.toUpperCase())) {
                result.push(row);
            }
        }

        this.consoleLog(result, true);
        return result;
    }

    //get the reference link (to display name if the field is REFERENCE)
    get datatableRefLinks() {
        return !this.datatableResponseIsEmpty ? this.datatableResponse?.[REFLINKS_PARAM] : '';
    }

    //if sorted by is modified in datatable, use that instead
    get datatableSortedby(){
        return this.modifiedSortedBy ? this.modifiedSortedBy : this.sortedBy;
    }
    
    //if sorted direction is modified in datatable, use that instead
    get datatableSortedDirection(){
        return this.modifiedSortedDirection ? this.modifiedSortedDirection : this.sortedDirection;
    }

    //hide checkbox if inline edit is disabled and row selection is disabled
    get hideCheckbox(){
        return !(this.enableInlineEditing || this.enableRowSelection);
    }

    //is this component for community?
    get isCommunity() {
        return !this.datatableResponseIsEmpty ? this.datatableResponse?.[IS_COMMUNITY_PARAM] : false;
    }

    get sitePath() {
        return !this.datatableResponseIsEmpty ? this.datatableResponse?.[SITE_PATH_PARAM] : '';
    }
    
    get newLabel() {
        return this.label.NEW_LABEL;
    }

    get showRefreshButton() {
        if (this.useSourceCollectionRecords) {
            return false;
        }

        return this.enableRefreshButton;
    }
    
    /**
     * @description get records, either start from 0, or concat
     * @returns 
     */
    initDatatable(showSpinner) {
        //Proceed only if this offset is greater than the previous one
        if (this.currentOffset > this.latestLoadedOffset){
            this.latestLoadedOffset = this.currentOffset;
        } else {
            return;
        }

        if (showSpinner) {
            this.toggleSpinner(1);
        }

        try{
            ctrlInitDatatable({datatableConfig:this.datatableConfig}).then(result =>{
                if (showSpinner) {
                    this.toggleSpinner(-1);
                }

                this.hasQueried = true;

                this.consoleLog(result.responseData, true);

                this.datatableResponse = JSON.parse(result.responseData);
            }).catch(error=>{
                if (showSpinner) {
                    this.toggleSpinner(-1);
                }

                promptError(this.label.ERROR_LABEL, getErrorMessage(error));
            });
        }catch(error){
            if (showSpinner) {
                this.toggleSpinner(-1);
            }
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
        }
    }

    /**
     * @description process raw data from apex controller
     */
    datatableResponsePostProcess(){
        this.consoleLog("datatableResponse:");
        this.consoleLog(this.datatableResponse, true);    
        
        //WARNING: The if the sourceCollection is from flow's query shape, we wont'be able to get build the clickable fields correctly
        this.datatableColumns = this.datatableResponse[COLUMNS_PARAM];
        this.consoleLog(this.datatableColumns, true);

        this.relatedListData = {...this.datatableResponse};
        
        if(this.useSourceCollectionRecords) {
            this.relatedListData.records = this.sourceCollection;

            this.consoleLog('useSourceCollectionRecords.datatableColumns');
            this.consoleLog(this.datatableColumns, true);
        } else {
            this.relatedListData.records = JSON.parse(this.relatedListData.records);
        }

        this.consoleLog('relatedListData - pre');
        this.consoleLog(this.relatedListData, true);

        this.relatedListData = updateDatatableConfig(this.relatedListData, this.isCommunity, this.language);

        this.consoleLog('relatedListData - post');
        this.consoleLog(this.relatedListData, true);


        for(let record of this.relatedListData.records) {

            let quickSearchString = this.calculateQuickSearch(this.datatableColumns, record);
            record.quickSearchString = quickSearchString.toUpperCase();

        }

        if(this.datatableData && !this.doRefresh){
            this.data = this.data.concat(this.relatedListData.records);
        } else {
            this.data = this.relatedListData.records;
        }

        if(this.datatableSortedby){
            this.sortData(this.datatableSortedby, this.datatableSortedDirection);
        }

        this.handleCardHeight();
    }

    /**
     * @description calculate quick search string (concat all the value of the field)
     * @param {*} columns this.datatableColumns
     * @param {*} record the record to be calculated
     * @returns quick search string
     */
    calculateQuickSearch(columns, record){
        let quickSearchStringList = []
        for(let element of columns){
            if(!element.fieldName) continue;
            let fieldApiName = '';

                if(element.fieldName.startsWith('link')){
                    fieldApiName = element.fieldName.replace('link', '');
                    if(fieldApiName.endsWith('__c')){
                        fieldApiName = fieldApiName.replace('__c', '__r.Name');
                    } else if(fieldApiName !== 'Name') {
                        fieldApiName = fieldApiName + '.Name';
                    }
                } else {
                    fieldApiName = element.fieldName;
                }
            
            if(record[fieldApiName]){
                quickSearchStringList.push(record[fieldApiName].toString());
            }
        }
        return quickSearchStringList.join(';');
    }


    get newRecordLabel(){
        return this.label.NEW_RECORD_LABEL.format([this.childObjectLabel]);
    }

    get recordSavedLabel(){
        return this.label.RECORD_SAVED_LABEL.format([this.childObjectLabel]);
    }
    /**
     * @description open a modal to create new record 
     */
    handleNewRecord(){
        RecordEditModal.open({
            headerLabel: this.newRecordLabel,
            label: this.label.EDIT_LABEL,
            objectApiName: this.childObjectApiName,
            fieldSetName: this.editFieldSetName,
            editFormColumnNo: this.editFormColumnNo,
            size: this.editFormSize,
            enableDebugMode: this.enableDebugMode
        }).then(result=>{
            if(result){
                const { operation, eventData, eventResult } = result;
                if(operation === 'submit' && eventData?.Id && eventResult === 'success') {
                    promptSuccess(this.label.SUCCESS_LABEL, this.recordSavedLabel);
                    notifyRecordUpdateAvailable([{recordId: eventData.Id}]);
                    
                    if(this.useSourceCollectionRecords){
                        //if records are from flow, we need to add the new record to the source collection
                        eventData.quickSearchString = this.calculateQuickSearch(this.datatableColumns, eventData);
                        this._sourceCollection.push(eventData);
                        this.data = this._sourceCollection;
                        this.consoleLog('created record:');
                        this.consoleLog(eventData, true);
                    } else {
                        //if not, we simply refresh the data
                        this.toggleSpinner(1);
                        this.refreshData();
                        this.toggleSpinner(-1);
                    }

                }
            }
        });
    }

    /**
     * @description generic row action handler
     * @param {*} event 
     */
    handleRowAction(event){

        let actionName = event.detail.action.name;
        let row = event.detail.row;
        
        if(actionName === 'view') {
            this.handleViewAction(row);
        } else if(actionName === 'edit') {
            this.handleEditAction(row);
        } else if(actionName === 'delete') {
            this.openDeleteConfirmation(row);
        } else if(actionName === 'download') {
            this.handleDownloadAction(row);
        }
        

    }

    /**
     * @description open record page
     * @param {*} row row object of the delete record
     */
    handleViewAction(row){
        let rowId = row.ContentDocumentId || row.Id;
        
        /*this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: rowId,
                objectApiName: this.childObjectApiName,
                actionName: 'view'
            }
        }).then((generatedUrl) =>{
            let url = generatedUrl;
            if(generatedUrl.includes("javascript")){
                url = '/' + rowId;
            }
            window.open(url, this.refTarget);
        })*/

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: rowId,
                objectApiName: this.childObjectApiName,
                actionName: 'view'
            }
        });
    }

    /**
     * @description open the edit modal with a record for editing
     * @param {*} row row object of the delete record
     */
    handleEditAction(row){
        let headerLabel = this.label.EDIT_RECORD_LABEL.format([row.Name ? row.Name : this.childObjectLabel ]) ;
        RecordEditModal.open({
            headerLabel: headerLabel,
            label: this.label.EDIT_LABEL,
            recordId: row.Id,
            objectApiName: this.childObjectApiName,
            fieldSetName: this.editFieldSetName,
            editFormColumnNo: this.editFormColumnNo,
            size: this.editFormSize,
            enableDebugMode: this.enableDebugMode
        }).then(result=>{
            if(result){
                let { operation, eventData } = result;
                if(operation === 'submit' && eventData?.Id) {
                    this.consoleLog('modified record:');
                    this.consoleLog(eventData, true);
                    promptSuccess(this.label.SUCCESS_LABEL, this.recordSavedLabel);
                    notifyRecordUpdateAvailable([{recordId: eventData.Id}]);
                    
                    if(this.useSourceCollectionRecords) {
                        //if records are from flow, we need to find the record from the source collection and edit it
                        let index = this._sourceCollection.findIndex(record => record.Id === eventData.Id);
                        if(index > -1) {
                            eventData.quickSearchString = this.calculateQuickSearch(this.datatableColumns, eventData);
                            this._sourceCollection[index] = eventData;
                            this.data = this._sourceCollection;
                            this.sortData(this.datatableSortedby, this.datatableSortedDirection);
                        }
                    } else {
                        //if not, we simply refresh the data
                        this.toggleSpinner(1);
                        this.refreshData();
                        this.toggleSpinner(-1);
                    }
                }
            } 
            
        })
    }
    
    /**
     * @description open a modal to confirm delete action
     * @param {*} row row object of the delete record
     */
    openDeleteConfirmation(row){

        let confirmationText1 = this.label.DELETE_RECORD_CONFIRMATION_LABEL.format([this.childObjectLabel, row.Name]);
        genericConfirmationModal.open({
            size: 'small',
            modalTitle: this.label.DELETE_LABEL,
            confirmationText1: confirmationText1,
            confirmationText2: null,
            confirmationText3: null,
            showSubmitButton: true,
            submitButtonLabel: this.label.DELETE_LABEL,
            showCancelButton: true,
            cancelButtonLabel: this.label.CANCEL_LABEL,
            eventSource: 'deleteChildRecord',
            eventData: row,
            enableDebugMode: this.enableDebugMode
        }).then(result=>{
            if (result){
                const { operation, eventSource, eventData } = result; 
                if(operation === 'submit' && eventSource === 'deleteChildRecord') {
                    this.deleteChildRecord(eventData.ContentDocumentId || eventData.Id);

                }
            }
        })
    }

    get recordDeletedLabel(){
        return this.label.RECORD_DELETED_LABEL.format([this.childObjectLabel]);
    }

    /**
     * @description Delete a record
     * @param {*} recordId record id
     */
    deleteChildRecord(recordId){
        try{

            deleteRecord(recordId).then(()=>{
                promptSuccess(this.label.SUCCESS_LABEL, this.recordDeletedLabel);
                if(this.useSourceCollectionRecords){
                    this._sourceCollection = this._sourceCollection.filter(record => record.Id !== recordId);
                    this.data = this._sourceCollection
                    if(this.datatableSortedby){
                        this.sortData(this.datatableSortedby, this.datatableSortedDirection);
                    }
                } else {
                    this.toggleSpinner(1);
                    this.refreshData();
                    this.toggleSpinner(-1);
                }
            }).catch(error=>{
                
                logError('Delete child record error: ', error);
                promptError(this.label.ERROR_LABEL, getErrorMessage(error));
            })
        } catch (error) {
             
            logError('Delete child record error: ', error);
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
        }
    }

    /**
     * @description handle download action
     * @param {*} row 
     */
    handleDownloadAction(row){
        let fullPath = getFileDownloadUrl(this.sitePath, this.downloadUrl, row.Id);
        window.open(fullPath, '_blank');

    }


    /**
     * @description Handle the Inline save. 
     * reference: https://github.com/trailheadapps/lwc-recipes/blob/main/force-app/main/default/lwc/datatableInlineEditWithUiApi/datatableInlineEditWithUiApi.js
     */
    async handleInlineSave(event){
        if(this.enableInlineEditing) {
            const records = event.detail.draftValues.slice().map((draftValue) => {
                //replace picklist value to the one that matches the updated picklist label
                let picklistLabelPostFix = commonConstants?.PICKLIST_LABEL;
                if(this.childObjectPicklistValues?.data?.picklistFieldValues && picklistLabelPostFix) {
                    let picklistFieldValues = this.childObjectPicklistValues?.data?.picklistFieldValues;
                    for(let key of Object.keys(draftValue)) {
                        //find attribute name of the picklist value
                        let picklistFieldApiName = key.replace(picklistLabelPostFix, ''); 
                        if(Object.hasOwn(picklistFieldValues, picklistFieldApiName)) {
                            let picklistLabel = draftValue[key];
                            let picklistObject = picklistFieldValues[picklistFieldApiName]?.values?.find(picklist => picklist.label === picklistLabel);
                            if(picklistObject) {
                                draftValue[picklistFieldApiName] = picklistObject?.value;
                            }
                        }
                    }
                }
                const fields = Object.assign({}, draftValue);
                return { fields };
            });
            
            this.consoleLog(records, true);
            
            this.draftValues = [];
            let cleanseRecords = removeLabelAttributes(records);
            
            try {
                this.toggleSpinner(1);
                const recordUpdatePromises = cleanseRecords.map((record) =>
                    updateRecord(record)
                );
                await Promise.all(recordUpdatePromises);

                if(this.useSourceCollectionRecords){
                    for(let modifiedRecord of event.detail.draftValues){
                        let id = modifiedRecord.Id;
                        let index = this._sourceCollection.findIndex(record => record.Id === id);
                        if(index > -1) {
                            let unmodifiedRecord = this._sourceCollection[index];

                            for(let [modifiedField, newValue] of Object.entries(modifiedRecord)) {
                                unmodifiedRecord[modifiedField] = newValue;
                                unmodifiedRecord.quickSearchString = this.calculateQuickSearch(this.datatableColumns, unmodifiedRecord);
                            }
                            this._sourceCollection[index] = unmodifiedRecord;
                        }
                    }
                    this.data = this._sourceCollection;
                } else {
                    this.toggleSpinner(1);
                    await this.refreshData();
                    this.toggleSpinner(-1);
                }
                this.toggleSpinner(-1);
                
                promptSuccess(this.label.SUCCESS_LABEL, this.label.YOUR_CHANGES_ARE_SAVED_LABEL);
                
            } catch (error) {
                promptError(this.label.ERROR_LABEL, getErrorMessage(error));
                this.toggleSpinner(-1);
            }
        }
    }

    //handle sorting in datatable
    handleOnSort(event){
        let fieldName = event.detail.fieldName;
        let sortDirection = event.detail.sortDirection;

        this.modifiedSortedBy = fieldName;
        this.modifiedSortedDirection = sortDirection;

        this.sortData(this.datatableSortedby, this.datatableSortedDirection);
    }

    //handle quicksearch input
    handleQuickSearch(event){
        this.quickSearchKeywords = event.detail.value;
        this.handleCardHeight();
    }

    //reset data. initdatatable should be called after this
    resetData(){
        this.data = [];
        this._datatableResponse = {};
        this.latestLoadedOffset = -1;
    }

    //continue to load more data from offset
    handleLoadMoreData(){
        if(this.datatableData){
            this.doRefresh = false
            this.initDatatable(false);
        }
    }

    /**
     * @description handleCardHeight
     */
    handleCardHeight() {
        let css = this.template.host.style;

        if((this.filteredData?.length * 30 > this._maxHeight) && (this._maxHeight !== 0)){
            css.setProperty('--card-height', this._maxHeight + 'px');
        } else {
            css.setProperty('--card-height', 'auto');
        }

    }

    /**
     * @description handle multiple row selection
     * @param {*} event 
     */
    handleRowsSelected(event){

        this._selectedRows = event.detail.selectedRows;

        const attributeChangeEvent = new FlowAttributeChangeEvent(
            "selectedRows",
            this._selectedRows,
        );

        this.dispatchEvent(attributeChangeEvent);
        this.dispatchEvent(new CustomEvent("rowselection", {
            detail: {
                selectedRows: this._selectedRows
            }
        }));
    }

    /**
     * @description sort data and replace the datatable data
     * @param {*} sortedBy this.datatableSortedby
     * @param {*} sortedDirection this.datatableSortedDirection
     */
    sortData(sortedBy, sortedDirection){

        if (this.datatableRefLinks.length !== 0 && Array.isArray(this.datatableRefLinks)) {
            for (let refLk of this.datatableRefLinks) {
                if (refLk.linkFieldName === sortedBy) {
                    sortedBy = refLk.linkFieldLabel;
                    break;
                }
            }
        }

        
        let reverse = sortedDirection !== 'asc';
        let cloneData = [...this.data];
        this.data = cloneData.sort(this.sortBy(sortedBy, reverse));
    }

    /**
     * @description sorting algorithm
     */
	sortBy(field, reverse, primer) {
        var key = primer ?
            function(x) {return primer(x[field])} :
            function(x) {return x[field]};
        reverse = !reverse ? 1 : -1;
        return function (a, b) {
            a = key(a);
            b = key(b);
            
            if (a == null || a === '') {
                return reverse;
            } else if (b == null || b === '') {
                return (-reverse);
            }
            return reverse * ((a > b) - (b > a));
        }
    }

	/**
     * @descripton library loader
     */
    handleLibLoadSuccess() {
        this.isScriptLoaded = true;
        this.isInitSuccess = true;
        this.doRefresh = false;
        this.initDatatable(true);
    }

    /**
     * @descripton library loader
     */
    handleLibLoadFail() {
        this.isScriptLoaded = true;
        this.isInitSuccess = false;
    }
	
    /**
     * @descripton connected callback
     */
    connectedCallback(){
		this.refreshContainerID = registerRefreshContainer(this, this.refreshData);
        this._cacheIdx = initCacheIdx();
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
        
        //update the cacheIdx if you need to force the wire method to get new data from apex
        this._cacheIdx = initCacheIdx();
        
        this.resetData();
        this.doRefresh = true;
        this.hasQueried = false;
        this.initDatatable(true);
        
        return new Promise((resolve) => {
            resolve(true);
        });

    }

    /**
     * @description Sample handle refresh button
     */
    handleRefreshOnclick() {
        this.resetData();
        
        this.refreshData();
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
        logInfo('CustomSingleRelatedList', anything, this.enableDebugMode, isJson);
    }
	
}