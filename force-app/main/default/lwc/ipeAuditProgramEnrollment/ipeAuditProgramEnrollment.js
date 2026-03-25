/**
 * @Author 		WDCi (VTan)
 * @Date 		October 2023
 * @group 		Program Completion Wizard
 * @Description Handler individual program enrollment information in program completion wizard.
 * @changehistory
 * ISS-001753 23-10-2023 VTan - New Component
 * ISS-002186 08-01-2025 XW - added progress ring for ipe
 * ISS-002186 24-02-2025 XW - added configurable ips group title format and progress ring color
 * ISS-002356 17-04-2025 XW - added configurable progress ring field name
 * ISS-002562 23-07-2025 XiRouh - Added ipfInfoFields and ipfInfoColumnNo
 * ISS-002654 03-10-2025 Lean - Column number shared util
 * ISS-002736 25-11-2025 XiRouh - Added tableTextDisplayMode configurable attribute
 */
import { LightningElement, wire, track, api } from 'lwc';
import { promptInfo, promptError, promptWarning, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';
import { customLabels } from 'c/labelLoader';
import { getColumnSize } from 'c/lwcUtil';

import ctrlGetIdvPlanStructureParentGroups from '@salesforce/apex/REDU_IpeAuditProgramEnrollment_LCTRL.getIdvPlanStructureParentGroups';
import { refreshApex } from '@salesforce/apex';
import { registerRefreshHandler, unregisterRefreshHandler } from 'lightning/refresh';

import { getFieldValue, getRecord } from 'lightning/uiRecordApi';

export default class IpeAuditProgramEnrollment extends LightningElement {
    
    //configurable attributes
    @api ipeId;
    @api ipfId;
    @api ipsGroupTitleField;
    @api ipsGroupTitleFormat;
    @api showIpsGroupInfo;
    @api ipfInfoFields;
    @api ipfInfoColumnNo;
    @api ipeInfoFields;
    @api ipeInfoColumnNo;
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
    @api progressRingColor;
    @api progressRingPercentageField;
    @api hrefTargetType;
    @api isCommunity = false;

    //ISS-002736
    @api tableTextDisplayMode;

	@api enableDebugMode = false;

    //internal attributes
    isScriptLoaded = false;
    isInitSuccess = false;
    loadedLists = 0;
    PROGRESS_RING_SIZE = '7rem'; //ISS-002186
    PROGRESS_RING_THICKNESS = '0.6rem'; //ISS-002186
    
    //refresh handler
    refreshHandlerID;

    //wire attributes
    ipsGroupWireResult
    ipsGroupList;
    progressRingWireResult;
    progressRingData;

    //custom label from SF
    label = customLabels;

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
		this.refreshHandlerID = registerRefreshHandler(this, this.refreshData);
	}
	
    /**
     * @descripton disconnected callback
     */
	disconnectedCallback() {
		unregisterRefreshHandler(this.refreshHandlerID);
	}

    /**
     * @description Get individual plan structure group record
     */
    @wire(ctrlGetIdvPlanStructureParentGroups, {
        individualPEId: "$ipeId"
    })
    wiredRecord(result) {
        
        this.ipsGroupWireResult = result;
        this.ipsGroupList = null;

        if (result.data) {
            this.ipsGroupList = JSON.parse(result.data.responseData);
            this.consoleLog(this.ipsGroupResponse, true);

        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }
    }
    
    /**
     * @description wire to get progress ring value
     */
    @wire(getRecord,{recordId: "$ipeId", fields: '$progressRingPercentageFieldQueryList'})
    wiredCompletionPercentage(result){
        this.progressRingWireResult = result;
        if(result.data) {
            this.progressRingData = result.data;
            this.consoleLog(this.progressRingData, true);
        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    //progress ring percentage field with object name
    get progressRingPercentageFieldQuery(){
        if(this.progressRingPercentageField) {
            return 'reduivy__Individual_Program_Enrollment__c.' + this.progressRingPercentageField;
        }

        return '';
    }

    //progress ring percentage field for wired method
    get progressRingPercentageFieldQueryList(){
        if(this.progressRingPercentageFieldQuery) {
            return [this.progressRingPercentageFieldQuery];
        }
        return [];
    }

    /**
     * @description get progress ring value from response
     */
    get progressRingValue() {
        if(this.progressRingWireResult && this.progressRingData && this.progressRingPercentageField) {
            return getFieldValue(this.progressRingData, this.progressRingPercentageFieldQuery) || 0;
        }
        return 0;
    }

    /**
     * @description get progress ring label
     */
    get progressRingLabel() {
        if(this.progressRingWireResult && this.progressRingData) {
            return Math.round(this.progressRingValue) + '%';
        }
        return '';
    }

    /**
     * @description Refresh data
     */
    refreshData() {
        this.consoleLog('refreshData');
        
        this.toggleSpinner(1);
        setTimeout(() => {

            refreshApex(this.ipsGroupWireResult);
            this.toggleSpinner(-1);

        }, 500);

        return new Promise((resolve) => {
            resolve(true);
        });

    }

    /**
     * @description Return list of individual plan structure group
     */
    get individualPSList(){

        if(this.ipsGroupList){
            return this.ipsGroupList;
        }

        return null;
    }
    
    /**
     * @description Return a list of individual Program Enrollment fields
     */
    get ipeInfoFieldsList() {
        if (this.ipeInfoFields) {
            return this.ipeInfoFields.split(';');
        }

        return [];
    }

    /**
     * @description Return if the individual program enrollment info fields are set
     */
    get hasIpeInfoFields() {
        return this.ipeInfoFields && this.ipeInfoFields.length > 0;
    }

    /**
     * @description Return the layout item size for ipe info
     */
    get ipeInfoFieldSize() {
        return getColumnSize(this.ipeInfoColumnNo, 4);
    }

    /**
     * @description Return a list of individual Academic Profile fields
     */
    get ipfInfoFieldsList() {
        if (this.ipfInfoFields) {
            return this.ipfInfoFields.split(';');
        }

        return [];
    }

    /**
     * @description Return if the individual academic profile info fields are set
     */
    get hasIpfInfoFields() {
        return this.ipfInfoFieldsList && this.ipfInfoFieldsList.length > 0;
    }
 
    /**
     * @description Return the layout item size for ipf info
     */
    get ipfInfoFieldSize() {
        return getColumnSize(this.ipfInfoColumnNo, 4);
    }

    /**
     * @descripton Spinner loading status
     */
	get isLoading(){
        return this.loadedLists === 0 && this.ipsGroupList ? false : true;
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
        logInfo('ipeAuditProgramEnrollment', anything, this.enableDebugMode, isJson);
    }

}