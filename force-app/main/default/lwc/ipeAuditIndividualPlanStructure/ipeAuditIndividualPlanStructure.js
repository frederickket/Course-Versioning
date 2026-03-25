/**
 * @Author 		WDCi (VTan)
 * @Date 		October 2023
 * @group 		Program Completion Wizard
 * @Description 
 * @changehistory
 * ISS-001753 23-10-2023 VTan - New Component
 * ISS-002230 05-02-2025 XW - display picklist value label if field type is picklist
 * ISS-002186 24-02-2025 XW - added configurable ips group title format
 * ISS-002356 17-04-2025 XW - completionPercentage decimal is rounded to nearest integer
 * ISS-002654 03-10-2025 Lean - Column number shared util
 * ISS-002736 25-11-2025 XiRouh - Added tableTextDisplayMode configurable attribute
 * ISS-002779 21-01-2026 Lean - Make table header to respect tableTextDisplayMode
 * ISS-002797 13-02-2025 Lean - Standardize language code format to POSIX
 */
import { LightningElement, api, wire, track } from 'lwc';
import { promptInfo, promptError, promptWarning, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';
import { customLabels } from 'c/labelLoader';
import { shadeHexColorCode } from 'c/cssUtil';
import { updateDatatableConfig, getColumnSize, isWrapTextEnabled, getTableHeaderDisplayMode, formatLanguageCodeToPosix } from 'c/lwcUtil';
import { ipeAuditConstants } from 'c/ipeAuditHelper';

import { refreshApex } from '@salesforce/apex';
import { RefreshEvent, registerRefreshHandler, unregisterRefreshHandler, sortRecords } from 'lightning/refresh';

import { notifyRecordUpdateAvailable, getRecord, getFieldValue } from "lightning/uiRecordApi";

import ctrlGetIdvPlanStructureChilds from '@salesforce/apex/REDU_IpeAuditIdvPlanStructure_LCTRL.getIdvPlanStructureChildren';
import ctrlSetPrimaryIpsUnit from '@salesforce/apex/REDU_IpeAuditIdvPlanStructure_LCTRL.setPrimaryIpsUnit';

import LANG from '@salesforce/i18n/lang';

//for confirmation modal
import confirmationModal from 'c/genericConfirmationModal';
import SET_PRIMARY_CONFIRMATION_LABEL from '@salesforce/label/c.Set_Primary_Confirmation';
import INDIVIDUAL_ENROLLMENT_HISTORY_LABEL from '@salesforce/label/c.Individual_Enrollment_History';

//for unit enrollment history modal
import enrollmentHistoryModal from 'c/ipeAuditUnitHistoryModal';

import COMPLETION_PERCENTAGE_IPS_FIELD from '@salesforce/schema/Individual_Plan_Structure__c.Completion_Percentage__c';

//wire attributes for querying individual plan structure using getRecord
const IPS_FIELDS = [
    "reduivy__Individual_Plan_Structure__c.Id",
    "reduivy__Individual_Plan_Structure__c.Name",
    "reduivy__Individual_Plan_Structure__c.reduivy__Credits__c",
    "reduivy__Individual_Plan_Structure__c.reduivy__Units_Required__c",
    "reduivy__Individual_Plan_Structure__c.reduivy__Study_Plan_Structure__r.Name",
    "reduivy__Individual_Plan_Structure__c.reduivy__Completion_Percentage__c"
];

export default class IpeAuditIndividualPlanStructure extends LightningElement {
    //configurable attributes
    @api recordId;
    @api ipsGroupTitleField;
    @api ipsGroupTitleFormat;
    @api showIpsGroupInfo;
    @api ipsInfoFields;
    @api ipsInfoFieldsUnit;
    @api ipsInfoColumnNo;
    @api ipsUnitFields;
    @api idvEnrollmentFields;
    @api accordionBackgroundColor;
    @api accordionTextColor;

    @api enableClickableRefField = false;
    @api enableSetPrimaryIps = false;
    @api enableViewEnrollmentHistory = false;
    @api hrefTargetType;
    @api isCommunity = false;

    //ISS-002736
    @api tableTextDisplayMode;

	@api enableDebugMode = false;

    //internal attributes
    @track activeSections = [];
    @track sortBy;
    @track sortDirection;

    //wire attributes
    @track ipsWireResult = [];
    @track ipsRecord = null;
    ipsDataWireResult;
    ipsData;

    isScriptLoaded = false;
	isInitSuccess = false;
    loadedLists = 0;

    //refresh handler
    refreshHandlerID;

    //custom label from SF
	label = {
        SET_PRIMARY_CONFIRMATION_LABEL,
        INDIVIDUAL_ENROLLMENT_HISTORY_LABEL, 
        ...customLabels
    };

    //js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'tooltips'
    modules = ['stringutil'];

    /* @descripton library loader
    */
    handleLibLoadSuccess(event) {

        this.isScriptLoaded = true;
        this.isInitSuccess = true;

        this.updateCssVars();
    }

    /**
    * @descripton library loader
    */
    handleLibLoadFail(event) {

        this.isScriptLoaded = true;
        this.isInitSuccess = false;
    }

    /**
     * @description Get current individual plan structure Group record
     */
    @wire(getRecord, { recordId: "$recordId", fields: "$ipsFieldsForQuery" })
    wiredRecord(result) {
        
        this.ipsWireResult = result;

        if (result.data) {
            this.ipsRecord = result.data;
            this.consoleLog(this.ipsRecord, true);
            
        } else if (result.error) {
            this.ipsRecord = null;
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }

    }

    /**
     * @description Return Group title field format for wire object
     */
    get ipsGroupTitleFieldForQuery() {
        if (this.ipsGroupTitleField) {
            return 'reduivy__Individual_Plan_Structure__c.' + this.ipsGroupTitleField;
        }

        return null;
    }

    /**
     * @description Return a list of fields to be queried by the getRecord wire method
     */
    get ipsFieldsForQuery() {
        let fields = IPS_FIELDS;
        if (this.ipsGroupTitleFieldForQuery) {

            if (!fields.includes(this.ipsGroupTitleFieldForQuery)) {
                fields.push(this.ipsGroupTitleFieldForQuery);
            }
        }

        return fields;
    }

    /**
     * @descripton Get the child Individual Plan Structure (Both Group and Unit)
     */
    @wire(ctrlGetIdvPlanStructureChilds, { 
        ipsGroupId: "$recordId",
        ipsUnitTableFields: "$ipsUnitFields",
        enableClickableRefField: "$enableClickableRefField",
        enableSetPrimaryIps: "$enableSetPrimaryIps",
        enableViewEnrollmentHistory: "$enableViewEnrollmentHistory",
        hrefTargetType: "$hrefTargetType",
        language: '$language',
        enableWrapText: '$enableWrapText'
    })
    wiredIPSDataRecord(result) {

        this.toggleSpinner(1);
        this.ipsDataWireResult = result;
        this.ipsData = null;
   
        let isCommunity = this.isCommunity;
        if (result.data) {

            let datatableConfig = JSON.parse(result.data.responseData);
            this.consoleLog(datatableConfig, true);
            
            this.ipsData = updateDatatableConfig(datatableConfig, isCommunity, this.language);

            this.consoleLog(this.ipsData, true);

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

        this.toggleSpinner(1);
        refreshApex(this.ipsDataWireResult);
        refreshApex(this.ipsWireResult);

        this.toggleSpinner(-1);
        return new Promise((resolve) => {
            resolve(true);
        });
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
        let parseData = JSON.parse(JSON.stringify(this.ipsData.records));
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
        this.ipsData.records = parseData;
    }

    /**
     * @description Return the layout item size
     */
    get infoFieldSize() {
        return getColumnSize(this.ipsInfoColumnNo, 4);
    }

    /**
     * @descripton Spinner loading status
     */
	get isLoading(){
        return this.loadedLists === 0 && this.ipsData && this.ipsRecord ? false : true;
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

    handleSectionToggle (event) {
        this.activeSections = event.detail.openSections;
    }

    /**
     * @descripton Handle selected row action in the data table
     */
    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;
        switch (action.name) {
            case ipeAuditConstants.SET_PRIMARY_ROW_ACTION_LABEL:{

                let confirmationMsg1 = this.label.SET_PRIMARY_CONFIRMATION_LABEL.format([row.Name]);
                this.launchConfirmationModal(this.label.CONFIRMATION_LABEL, confirmationMsg1, null, null, true, this.label.CONFIRM_LABEL, true, this.label.CANCEL_LABEL, 'setPrimaryIps', JSON.stringify(row));
                break;

            }
            case ipeAuditConstants.VIEW_HISTORY_ROW_ACTION_LABEL:{

                let confirmationMsg2 = this.label.INDIVIDUAL_ENROLLMENT_HISTORY_LABEL;

                if(row.eduivy__Alternate_Study_Unit__r !== undefined){

                    confirmationMsg2 = confirmationMsg2.concat(': ', row.eduivy__Alternate_Study_Unit__r.reduivy__Unit_Code__c);
                }else if(row.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__r.reduivy__Unit_Code__c  !== undefined){

                    confirmationMsg2 = confirmationMsg2.concat(': ', row.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__r.reduivy__Unit_Code__c);
                }
                
                this.launchEnrollmentHistoryModal(confirmationMsg2, row.Id, row.reduivy__Individual_Enrollment__c, this.idvEnrollmentFields, this.enableClickableRefField, this.hrefTargetType, this.label.CLOSE_LABEL, this.tableTextDisplayMode);
                break;
            }
            default:{
                break;
            }
        }
    }

    /**
     * @description Launch the set primary individual plan structure confirmation modal
     * @param title 
     * @param text1 
     * @param text2 
     * @param text3 
     * @param showSubmit 
     * @param submitLabel 
     * @param showCancel 
     * @param cancelLabel 
     * @param lEventSource 
     * @param lEventData 
     */
    launchConfirmationModal(title, text1, text2, text3, showSubmit, submitLabel, showCancel, cancelLabel, lEventSource, lEventData) {

        confirmationModal.open({
            size: 'small',
            modalTitle: title,
            confirmationText1: text1,
            confirmationText2: text2,
            confirmationText3: text3,
            showSubmitButton: showSubmit,
            submitButtonLabel: submitLabel,
            showCancelButton: showCancel,
            cancelButtonLabel: cancelLabel,
            eventSource: lEventSource,
            eventData: lEventData,
            enableDebugMode: this.enableDebugMode            
        }).then((result) => {

            if (result) {
                this.consoleLog('launchConfirmationModal.close');
                this.consoleLog(result, true);

                const {operation, eventSource, eventData} = result;

                if (operation === 'submit' && eventSource === 'setPrimaryIps') {
                    this.setPrimaryIps(eventData);
                }
            }
        });
    }

    setPrimaryIps(eventData) {

        this.toggleSpinner(1);

        try {
            this.consoleLog('set primary IPS');

            let rowData = JSON.parse(eventData);
            let ipsRecord = {Id: rowData?.Id, Name: rowData?.Name};

            this.consoleLog(ipsRecord, true);

            ctrlSetPrimaryIpsUnit({
                ipsUnitRecord: JSON.stringify(ipsRecord)
            })
            .then(saveResult => {
                this.toggleSpinner(-1);
                promptSuccess(this.label.SUCCESS_LABEL, saveResult.message);

                if (saveResult.responseData) {
                    let recordIds = [];
                    for (let recId of JSON.parse(saveResult.responseData)) {
                        recordIds.push({recordId: recId});
                    }

                    notifyRecordUpdateAvailable(recordIds);
                }

            })
            .catch(error => {
                promptError(this.label.ERROR_LABEL, getErrorMessage(error));
                this.toggleSpinner(-1);
                
            });

            this.dispatchEvent(new RefreshEvent());

        } catch (error) {
            this.toggleSpinner(-1);
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
        }
    }

    /**
     * @description Launch the view individual enrollment history modal
     * @param title Title of the modal
     * @param ipsUnitId Selected individual plan structure (unit) Id
     * @param idvEnId Individual enrollment of the selected ips unit
     * @param idvEnrollmentFields Individual enrollment fields to be used as the data table column
     * @param enableClickableRefField Enable clickable ref field in data table
     * @param hrefTargetType href target type
     * @param showCancel Display cancel button in the modal
     * @param cancelLabel Label of the cancel button if it's enabled
     */
    launchEnrollmentHistoryModal(title, ipsUnitId, idvEnId, idvEnrollmentFields, enableClickableRefField, hrefTargetType, closeLabel, tableTextDisplayMode) {

        enrollmentHistoryModal.open({
            size: 'medium',
            modalTitle: title,
            ipsUnitId: ipsUnitId,
            idvEnId: idvEnId,
            idvEnrollmentFields: idvEnrollmentFields,
            enableClickableRefField: enableClickableRefField,
            hrefTargetType: hrefTargetType,
            closeButtonLabel: closeLabel,
            tableTextDisplayMode: tableTextDisplayMode,
            enableDebugMode: this.enableDebugMode,
            isCommunity: this.isCommunity   
        }).then((result) => {

            if (result) {
                this.consoleLog('launchEnrollmentHistoryModal.close');
                this.consoleLog(result, true);

            }
        });
    }

    /**
     * @description Return a list of individual plan structure fields for type of credit required
     */
    get infoFieldsByCreditRequired() {
        if (this.ipsInfoFields) {
            return this.ipsInfoFields.split(';');
        }

        return [];
    }

    /**
     * @description Return a list of individual plan structure fields for type of # of units required
     */
    get infoFieldsByUnitRequired() {
        if (this.ipsInfoFieldsUnit) {
            return this.ipsInfoFieldsUnit.split(';');
        }

        return [];
    }

    /**
     * @description Return list of individual plan structure unit
     */
    get ipsUnitList(){

        if(this.isIpsDataReady && this.ipsData.records){
            return this.ipsData.records;
        }

        return null;
    }

    /**
     * @description Return list of individual plan structure group
     */
    get ipsGroupList(){

        if(this.isIpsDataReady && this.ipsData.groupData){
            return this.ipsData.groupData;
        }

        return null;
    }

    /**
     * @description Return column metadata to be used for data table
     */
    get tableColumns(){

        if(this.isIpsDataReady && this.ipsData.columns){
            return this.ipsData.columns;
        }

        return null;
    }

    /**
     * @description Get study plan structure label
     */
    get ipsLabel() {
        if (this.ipsRecord && this.ipsGroupTitleFormat) {
            let completionPercentage = getFieldValue(this.ipsRecord, COMPLETION_PERCENTAGE_IPS_FIELD);
            if(!completionPercentage) {
                completionPercentage = 0;
            } else {
                completionPercentage = Math.round(completionPercentage);
            }
            let title = getFieldValue(this.ipsRecord, this.ipsGroupTitleFieldForQuery);
            
            return this.ipsGroupTitleFormat.format([completionPercentage, title]);
        }

        return null;
    }

    /**
     * @description Get individual plan structure type
     */
    get ipsInfoFieldsList() {
        
        if (this.ipsRecord && this.ipsRecord.fields.reduivy__Credits__c.value != null) {
            return this.infoFieldsByCreditRequired;
        }

        return this.infoFieldsByUnitRequired;
    }

    /**
     * @description Return true if the ipsGroupResponse is fetched by the wire method
     */
    get isIpsDataReady() {
        
        if (this.recordId && this.ipsData) {
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
     * @descripton Console log for debugging
     */
	consoleLog(anything, isJson){
        logInfo('ipeAuditIndividualPlanStructure', anything, this.enableDebugMode, isJson);
    }

    /**
     * @descripton Shade the accordion color, to be used for the child group
     */
    get shadedHexColor() {
        
        return shadeHexColorCode(this.accordionBackgroundColor, 0.30);
    }

    /**
     * @description Update css var
     */
    updateCssVars() {

        let css = this.template.host.style;
        css.setProperty('--accordion-background-color', this.accordionBackgroundColor);
        css.setProperty('--accordion-text-color', this.accordionTextColor);
    }
}