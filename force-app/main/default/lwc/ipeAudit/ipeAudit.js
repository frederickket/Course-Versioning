/**
 * @Author 		WDCi (VTan)
 * @Date 		October 2023
 * @group 		Program Completion Wizard
 * @Description Handler individual program enrollment information in program completion wizard.
 * @changehistory
 * ISS-001753 23-10-2023 VTan - New Component
 * ISS-002230 22-01-2025 XW - display picklist value label if field type is picklist
 * ISS-002186 24-02-2025 XW - added configurable ips group title format and progress ring color
 * ISS-002218 04-03-2025 XW - get for community from apex
 * ISS-002562 18-07-2025 XiRouh - Added new configurable attributes ipfInfoFields and ipfInfoColumnNo
 * ISS-002650 10-11-2025 XW - replace refreshHandler to refreshContainer
 * ISS-002736 25-11-2025 XiRouh - Added tableTextDisplayMode configurable attribute
 */
import { LightningElement, wire, track, api } from 'lwc';
import { promptInfo, promptError, promptWarning, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';
import { extractFieldValue, hasOwnNestedProperty, commonConstants } from 'c/lwcUtil';
import { customLabels } from 'c/labelLoader';

import { refreshApex } from '@salesforce/apex';
import { RefreshEvent, registerRefreshContainer, unregisterRefreshContainer } from 'lightning/refresh';

//Apex methods
import ctrlGetIndividualPEs from '@salesforce/apex/REDU_IpeAudit_LCTRL.getIndividualPEs';

export default class IpeAudit extends LightningElement {

    //configurable attributes
    @api modalTitle;
    @api modalIconName = 'standard:sales_path';
    @api tabVariant = 'default';
    @api recordId;
    @api ipeTitleField = 'reduivy__Study_Plan__r.Name'; 
    @api ipsGroupTitleField = 'reduivy__Study_Plan_Structure__r.Name';
    @api ipsGroupTitleFormat;
    @api showIpsGroupInfo = false;
    @api ipeInfoFields;
    @api ipeInfoColumnNo;
    @api ipfInfoFields;
    @api ipfInfoColumnNo;
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

    //ISS-002736
    @api tableTextDisplayMode;
    
    @api hrefTargetType = '_self';
    @api forCommunity = false; //ISS-002218 obsoleted

	@api enableDebugMode = false;

    //internal attributes
    isScriptLoaded = false;
	isInitSuccess = false;
    loadedLists = 0;

    //refresh handler
    refreshContainerID;

    //wire attribute
    ipeListWireResult;
    ipeList;
    isCommunity;

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

        refreshApex(this.ipeListWireResult);

        return new Promise((resolve) => {
            resolve(true);
        });

    }
    
    /**
     * @description Get individual plan structure group record
     */
    @wire(ctrlGetIndividualPEs, {
        individualPEId: "$recordId",
        titleField: '$ipeTitleField'
    })
    wiredIpeList(result) {
        
        this.ipeListWireResult = result;
        this.ipeList = null;

        if (result.data) {
            let responseData = JSON.parse(result.data.responseData);
            this.ipeList = responseData.individualPEs;
            this.isCommunity = responseData.isCommunity;
            this.consoleLog(this.ipeList, true);

        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }

    }

    /**
     * @description Return list of individual program enrollment
     */
    get individualPEList(){

        if(this.ipeList){
            if (this.ipeTitleField) {
                for (let ipe of this.ipeList) {
                    let titleField = this.ipeTitleField;
                    if(hasOwnNestedProperty(ipe, this.ipeTitleField + commonConstants.PICKLIST_LABEL)) {
                        titleField += commonConstants.PICKLIST_LABEL;
                    }
                    //we set the record as a custom attribute since we need to loop the records to generate tab
                    //note that Title is not an actual field in the object
                    ipe.Title = extractFieldValue(ipe, titleField);

                    //ISS-002562
                    // Set the IPF ID based on whether the master enrollment field is populated or not
                    // If master enrollment is null, this is a master IPE, so we can use the IPF ID directly from the record
                    // If it's a child IPE and the IPF is not populated, get the IPF ID from the master enrollment
                    // If the child IPE has the IPF field populated, use that directly
                    ipe.ipfId = ipe.reduivy__Individual_Academic_Profile__c || 
                            (ipe.reduivy__Master_Enrollment__r && ipe.reduivy__Master_Enrollment__r.reduivy__Individual_Academic_Profile__c);
                }
            }

            return this.ipeList;
        }

        return null;
    }

    /**
     * @description Handle the refresh
     */
    handleRefreshOnclick(event) {
        this.dispatchEvent(new RefreshEvent());
    }

    /**
     * @description Return true to show modal title and icon
     */
    get showModalHeader(){
        if(this.modalTitle){
            return true;
        }
        return false;
    }

    /**
     * @descripton Spinner loading status
     */
	get isLoading(){
        return this.loadedLists === 0 && this.ipeList ? false : true;
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
        logInfo('ipeAudit', anything, this.enableDebugMode, isJson);
    }
}