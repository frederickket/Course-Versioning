/**
 * @Author 		WDCi (VTan)
 * @Date 		Nov 2023
 * @group 		Program Completion Wizard
 * @Description Handle individual enrollment history information in program completion wizard.
 * @changehistory
 * ISS-001824 04-12-2023 VTan - Inital Built. Modal to display unit enrollment history in program completion wizard.
 * ISS-002230 05-02-2025 XW - display picklist value label if field type is picklist
 * ISS-002495 22-09-2025 XW - support translation for long text field
 * ISS-002736 25-11-2025 XiRouh - Added tableTextDisplayMode configurable attribute
 * ISS-002745 26-11-2025 Lean - Enforce cache update when the component is loaded
 * ISS-002779 21-01-2026 Lean - Make table header to respect tableTextDisplayMode
 * ISS-002797 13-02-2025 Lean - Standardize language code format to POSIX
 */
import { LightningElement, api, wire, track } from 'lwc';
import LightningModal from 'lightning/modal';
import { promptInfo, promptError, promptWarning, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';
import { initCacheIdx, updateDatatableConfig, isWrapTextEnabled, getTableHeaderDisplayMode, formatLanguageCodeToPosix } from 'c/lwcUtil';
import LANG from '@salesforce/i18n/lang';
import { customLabels } from 'c/labelLoader';

import LOADING_LABEL from '@salesforce/label/c.Loading';
import NO_RECORD_LABEL from '@salesforce/label/c.No_Records_To_Display';
import IDV_EN_CURRENT_IPS_LABEL from '@salesforce/label/c.Individual_Enrollment_For_Current_IPS';

import ctrlGetIdvEnrollmentHistory from '@salesforce/apex/REDU_IpeAuditUnitHistoryModal_LCTRL.getIdvEnrollmentHistory';

export default class IpeAuditUnitHistoryModal extends LightningModal {
	
	//configurable attributes
    @api modalTitle;
    @api ipsUnitId;
    @api idvEnId;
    @api idvEnrollmentFields;
    @api enableClickableRefField;
    @api hrefTargetType;
    @api isCommunity;
    
    @api closeButtonLabel;

    //ISS-002736
    @api tableTextDisplayMode;

    @api eventSource;
    @api eventData;
	@api enableDebugMode = false;
	
	//internal attributes
    @track sortBy;
    @track sortDirection;
	isScriptLoaded = false;
	isInitSuccess = false;
	loadedLists = 0;
    idvEnDataEmpty = false;

    //wire attributes
    idvEnWireResult;
    idvEnData;
	
    //local cache idx to force rerendering
    _cacheIdx;

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
        this.consoleLog(this.ipsUnitId);
        this.consoleLog(this.idvEnrollmentFields);

        this._cacheIdx = initCacheIdx(); //ISS-002745
	}
	
    /**
     * @descripton disconnected callback
     */
	disconnectedCallback() {
		
	}

    /**
     * @description Return modal title
     */
    get headerLabel() {
        return this.modalTitle;
    }

    /**
     * @description Return loading label
     */
    get loadingLabel() {
        return LOADING_LABEL;
    }

    /**
     * @description Return no record label
     */
    get noRecordLabel() {
        return NO_RECORD_LABEL;
    }

    /**
     * @description Return no record label
     */
    get idvEnCurrentIpsLabel() {
        return IDV_EN_CURRENT_IPS_LABEL;
    }
    
    /**
     * @description Handle cancel click to close the modal with operation = cancel, eventSource and eventData
     * @param {*} event 
     */
    handleCloseClick(event) {
        this.close({
            operation: 'close',
            eventSource: this.eventSource,
            eventData: this.eventData
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
     * @descripton Get the individual enrollments
     */
    @wire(ctrlGetIdvEnrollmentHistory, { 
        ipsUnitId: "$ipsUnitId",
        idvEnrollmentFields: "$idvEnrollmentFields",
        enableClickableRefField: "$enableClickableRefField",
        hrefTargetType: "$hrefTargetType",
        language: '$language',
        enableWrapText: '$enableWrapText',
        cacheIdx: '$_cacheIdx' //ISS-002745
    })
    wiredidvEnDataRecord(result) {

        this.toggleSpinner(1);
        this.idvEnDataWireResult = result;
        this.idvEnData = null;
   
        let isCommunity = this.isCommunity;
        if (result.data) {

            let datatableConfig = JSON.parse(result.data.responseData);
            this.consoleLog(datatableConfig, true);
            
            this.idvEnData = updateDatatableConfig(datatableConfig, isCommunity, this.language);

            for(let i = 0; i < this.idvEnData.records.length; i ++) {
                if(this.idvEnData.records[i].Id === this.idvEnId){

                    this.idvEnData.records[i].helpTextColIconVisible = true;
                    this.idvEnData.records[i].helpTextColIconName = "utility:bookmark";
                    this.idvEnData.records[i].helpTextColContent = this.idvEnCurrentIpsLabel;
                }
            }
            
            this.consoleLog(this.idvEnData, true);
            
            if (this.idvEnData.records.length === 0){
                this.idvEnDataEmpty = true;
            }else{
                this.idvEnDataEmpty = false;
            }

        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
            
        }
        this.toggleSpinner(-1);
    }

    /**
     * @description the user language
     */
    get language() {
        return formatLanguageCodeToPosix(LANG);
    }

    /**
     * @description Return list of individual enrollment
     */
    get idvEnList(){

        if(this.isIdvEnDataReady && this.idvEnData.records){
            return this.idvEnData.records;
        }

        return null;
    }

    /**
     * @description Return column metadata to be used for data table
     */
    get tableColumns(){

        if(this.isIdvEnDataReady && this.idvEnData.columns){
            return this.idvEnData.columns;
        }

        return null;
    }

    /**
     * @description Return true if the ipsGroupResponse is fetched by the wire method
     */
    get isIdvEnDataReady() {
        
        if (this.ipsUnitId && this.idvEnData) {

            return true;
        }

        return false;
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
        let parseData = JSON.parse(JSON.stringify(this.idvEnData.records));
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
        this.idvEnData.records = parseData;
    }

    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;
    }
	
    /**
     * @descripton Console log for debugging
     */
	consoleLog(anything, isJson){
        logInfo('ipeAuditUnitHistory', anything, this.enableDebugMode, isJson);
    }
}