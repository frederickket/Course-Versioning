/**
 * @Author 		WDCi (VTan)
 * @Date 		January 2024
 * @group 		Credit Transfer Wizard
 * @Description 
 * @changehistory
 * ISS-001659 08-01-2024 VTan - New Component
 * ISS-002230 05-02-2025 XW - display picklist value label if field type is picklist
 * ISS-002218 04-03-2025 XW - get for community from apex
 * ISS-002495 22-09-2025 XW - support translation for long text field
 * ISS-002650 10-11-2025 XW - replace refreshHandler to refreshContainer
 * ISS-002797 13-02-2025 Lean - Standardize language code format to POSIX
 */
import { LightningElement, wire, track, api } from 'lwc';
import { promptError, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo } from 'c/loggingUtil';
import { updateDatatableConfig, commonConstants, formatLanguageCodeToPosix } from 'c/lwcUtil';
import { customLabels } from 'c/labelLoader';
import { refreshApex } from '@salesforce/apex';
import { RefreshEvent, registerRefreshContainer, unregisterRefreshContainer } from 'lightning/refresh';
import { notifyRecordUpdateAvailable } from "lightning/uiRecordApi";
import { NavigationMixin } from 'lightning/navigation';
import LANG from '@salesforce/i18n/lang';

import { conCreditTransferConstants } from 'c/conCreditTransferHelper';
import NO_RECORD_LABEL from '@salesforce/label/c.No_Records_To_Display';
import NEW_CT_APPLICATION_LABEL from '@salesforce/label/c.New_Credit_Transfer_Application';
import EDIT_CT_APPLICATION_LABEL from '@salesforce/label/c.Edit_Credit_Transfer_Application';
import REJECT_CT_APPLICATION_CONFIRMATION_LABEL from '@salesforce/label/c.Reject_CTA_Confirmation';
import SUBMIT_CT_APPLICATION_CONFIRMATION_LABEL from '@salesforce/label/c.Submit_CTA_Confirmation';
import ADDNEWAGREEMENT_LABEL from '@salesforce/label/c.Add_New_Agreement';
import ADDNEWAGREEMENTUNIT_LABEL from '@salesforce/label/c.Add_New_Agreement_Unit_Equivalent';

//Apex methods
import ctrlGetCreditTransferList from '@salesforce/apex/REDU_ConCreditTransferList_LCTRL.getCreditTransferList';
import ctrlRejectCTApplication from '@salesforce/apex/REDU_ConCreditTransferList_LCTRL.rejectCTApplication';
import ctrlSubmitCTApplication from '@salesforce/apex/REDU_ConCreditTransferList_LCTRL.submitCTApplication';

//for credit transfer application modal
import conCreditTransferModal from 'c/conCreditTransferModal';
import confirmationModal from 'c/genericConfirmationModal';

const IS_COMMUNITY_PARAM = 'isCommunity';

export default class ConCreditTransferList extends NavigationMixin(LightningElement) {

    @api recordId;
    @api objectApiName;

    //configurable attributes
    @api userMode;
    @api enableDebugMode = false;
    @api contactFieldApiName;
    @api componentLabel;
    @api componentIcon;
    @api componentIconSize;
    @api ctAppListFields;
    @api showCreateNew;
    @api createNewLabel;
    @api forCommunity = false; //ISS-002218 obsoleted 
    @api enableClickableRefField = false;
    @api hrefTargetType = '_self';
    @api enableNewButton;

    @api agreementRpPrimaryField;
    @api agreementRpAdditionalField;
    @api agreementUnitRpPrimaryField;
    @api agreementUnitRpAdditionalField;
    @api ipeRpPrimaryField;
    @api ipeRpAdditionalField;
    @api ipsRpPrimaryField;
    @api ipsRpAdditionalField;

    @api applicationFormFieldSetName = 'reduivy__CreditTransferApplicationModal';
    @api approvalFormFieldSetName = 'reduivy__CreditTransferApproveModal';

    //wire attributes
    ctaDataWireResult;
    ctaData;
    contactId;

    //internal attributes
    refreshContainerID;
    isScriptLoaded = false;
	isInitSuccess = false;
    loadedLists = 0;
    ctaDataEmpty = false;
    approvedStatuses;
    rejectedStatuses;
    submittedStatuses;
    draftStatuses;
    modalType;
    @track sortBy;
    @track sortDirection;

    //custom label from SF
	label = {
        NO_RECORD_LABEL,
        NEW_CT_APPLICATION_LABEL,
        EDIT_CT_APPLICATION_LABEL,
        REJECT_CT_APPLICATION_CONFIRMATION_LABEL,
        SUBMIT_CT_APPLICATION_CONFIRMATION_LABEL,
        ADDNEWAGREEMENT_LABEL,
        ADDNEWAGREEMENTUNIT_LABEL,
        ...customLabels
    };

    //js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'tooltips'
    modules = ['stringutil'];

    /**
     * @descripton library loader
     */
    handleLibLoadSuccess() {

        this.isScriptLoaded = true;
        this.isInitSuccess = true;
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
	}

    disconnectedCallback() {
        unregisterRefreshContainer(this.refreshContainerID)
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
     * @description Refresh data
     */
    refreshData() {
        this.consoleLog('refreshData');

        this.toggleSpinner(1);
        refreshApex(this.ctaDataWireResult);

        this.toggleSpinner(-1);
        return new Promise((resolve) => {
            resolve(true);
        });
    }

    /**
     * @description Handle the refresh
     */
    handleRefreshOnclick() {
        this.dispatchEvent(new RefreshEvent());
    }

    /**
     * @description Handle the create new or edit credit transfer application
     */
    handleNewOnclick() {
        
        this.launchCreditTransferModal(this.label.NEW_CT_APPLICATION_LABEL, this.contactId, null, conCreditTransferConstants.CTAMODAL_NEW);

    }

    /**
     * @descripton Handle selected row action in the data table
     */
    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;

        switch (action.name) {
            case conCreditTransferConstants.EDIT_ACTION:
                this.launchCreditTransferModal(this.label.EDIT_CT_APPLICATION_LABEL, this.contactId, row.Id, conCreditTransferConstants.CTAMODAL_EDIT);
                break;

            case conCreditTransferConstants.SUBMIT_ACTION:
                this.launchConfirmationModal(this.label.CONFIRMATION_LABEL, this.label.SUBMIT_CT_APPLICATION_CONFIRMATION_LABEL.format([row.Name]), null, null, true, this.label.SUBMIT_LABEL, true, this.label.CANCEL_LABEL, 'submitCTApplication', JSON.stringify(row));
                break;

            case conCreditTransferConstants.APPROVE_ACTION:
                this.launchCreditTransferModal(this.label.CONFIRMATION_LABEL, this.contactId, row.Id, conCreditTransferConstants.CTAMODAL_APPROVAL);
                break;

            case conCreditTransferConstants.REJECT_ACTION:
                this.launchConfirmationModal(this.label.CONFIRMATION_LABEL, this.label.REJECT_CT_APPLICATION_CONFIRMATION_LABEL.format([row.Name]), null, null, true, this.label.REJECT_LABEL, true, this.label.CANCEL_LABEL, 'rejectCTApplication', JSON.stringify(row));
                break;

            case conCreditTransferConstants.VIEW_ACTION:
                this.navigateToRecordPage(row);
                break;
            default:
                //do nothing

        }
    }

    /**
     * @description Launch the view individual enrollment history modal
     * @param title Title of the modal
     * @param enableDebugMode Enable debug log
     * @param contactId Current contact Id
     * @param recordId Current credit transfer application Id
     */
    launchCreditTransferModal(title, contactId, recordId, modalType) {

        conCreditTransferModal.open({
            size: 'small',
            label: title,
            modalTitle: title,
            modalType: modalType,
            recordId: recordId,
            contactId: contactId,
            userMode: this.userMode,
            enableDebugMode: this.enableDebugMode,
            agreementRpPrimaryField: this.agreementRpPrimaryField,
            agreementRpAdditionalField: this.agreementRpAdditionalField,
            agreementUnitRpPrimaryField: this.agreementUnitRpPrimaryField,
            agreementUnitRpAdditionalField: this.agreementUnitRpAdditionalField,
            ipeRpPrimaryField: this.ipeRpPrimaryField,
            ipeRpAdditionalField: this.ipeRpAdditionalField,
            ipsRpPrimaryField: this.ipsRpPrimaryField,
            ipsRpAdditionalField: this.ipsRpAdditionalField,
            applicationFormFieldSetName: this.applicationFormFieldSetName,
            approvalFormFieldSetName: this.approvalFormFieldSetName,
            onaddnewrecord: (e) => {
                
                e.stopPropagation();
                this.handleAddNewRecordEvent(e.detail);
              }
        }).then((result) => {

            if (result) {

                refreshApex(this.ctaDataWireResult);
            }
        });
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

                const {operation, eventSource, eventData} = result;

                if (operation === 'submit' && eventSource === 'rejectCTApplication') {
                    this.rejectCTApplication(eventData);
                }else if (operation === 'submit' && eventSource === 'submitCTApplication') {
                    this.submitCTApplication(eventData);
                }
            }

            this.refreshData();
        });
    }

    /**
     * @description Navigate to a modal to create new record
     */
    handleAddNewRecordEvent(detail) {
        const { id, value } = detail;

        switch (value) {
            case this.label.ADDNEWAGREEMENT_LABEL:
                this.navigateToNewRecordPage('reduivy__Agreement__c');
                break;

            case this.label.ADDNEWAGREEMENTUNIT_LABEL:
                this.navigateToNewRecordPage('reduivy__Agreement_Unit_Equivalent__c');
                break;
            default:
                //do nothing
        }
      }

    /**
     * @description Row action to reject the credit transfer application from the data table
     */
    rejectCTApplication(eventData) {

        this.toggleSpinner(1);

        try {
            this.consoleLog('Reject Credit Transfer Application');

            ctrlRejectCTApplication({
                ctApplicationRecord: eventData
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
     * @description Row action to submit the credit transfer application from the data table
     */
    submitCTApplication(eventData) {

        this.toggleSpinner(1);

        try {
            this.consoleLog('Reject Credit Transfer Application');

            ctrlSubmitCTApplication({
                ctApplicationRecord: eventData
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
     * @description Row action to view the credit transfer application from the data table
     */
    navigateToRecordPage(eventData) {

        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: eventData.Id,
                objectApiName: eventData.attributes.type,
                actionName: 'view'
            }
        }).then(url => {
            window.open(url, "_blank");
        });

    }

    /**
     * @description Action to navigate to new record page
     * @param dataType The object API name of the new record page
     */
    navigateToNewRecordPage(dataType) {

        this.consoleLog('navigateToNewRecordPage');
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: dataType,
                actionName: 'new'
            }
        }).then(url => {
            window.open(url, "_blank");
        });
    }

    /**
     * @descripton Get the data for displaying in the data table
     */
    @wire(ctrlGetCreditTransferList, { 
        objectApiName: "$objectApiName",
        recordId: "$recordId",
        contactFieldApiName: "$contactFieldApiName",
        ctAppListFields: "$ctAppListFields",
        enableClickableRefField: "$enableClickableRefField",
        hrefTargetType: "$hrefTargetType",
        language: "$language"
    })
    wiredCtApplicationRecord(result) {

        this.toggleSpinner(1);
        this.ctaDataWireResult = result;
        this.ctaData = null;
   
        if (result.data) {

            let datatableConfig = JSON.parse(result.data.responseData);
            this.consoleLog(datatableConfig, true);

            let isCommunity = datatableConfig[IS_COMMUNITY_PARAM];

            this.ctaData = updateDatatableConfig(datatableConfig, isCommunity, this.language);
            this.contactId = datatableConfig.contactId;
            this.approvedStatuses = datatableConfig.approvedStatuses;
            this.rejectedStatuses = datatableConfig.rejectedStatuses;
            this.submittedStatuses = datatableConfig.submittedStatuses;
            this.draftStatuses = datatableConfig.draftStatuses;

            if (this.ctaData.records.length === 0){
                this.ctaDataEmpty = true;
            } else{
                this.ctaDataEmpty = false;
            }

            this.consoleLog(this.contactId, true);

            this.ctaData.columns = this.ctaData.columns.concat( [
                { type: 'action', typeAttributes: { rowActions: this.getRowActions.bind(this) } }
            ] );

            this.consoleLog(this.ctaData.records, true);

        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
            
        }
        this.toggleSpinner(-1);
    }

    /**
     * @description Action to get row action for the data table
     * @param row 
     * @param doneCallback 
     */
    getRowActions( row, doneCallback ) {

        const actions = [];
        if(this.isAdminMode || this.isStudentMode){
            actions.push( {
                'label': this.label.VIEW_LABEL,
                'name': conCreditTransferConstants.VIEW_ACTION
            } );
        }
        
        if (this.isAdminMode || this.isStudentMode) {

            let disableEdit = false;

            if(!this.draftStatuses.includes(row?.reduivy__Status__c) && this.isStudentMode){
                disableEdit = true;
            }
            actions.push( {
                'label': this.label.EDIT_LABEL,
                'name': conCreditTransferConstants.EDIT_ACTION,
                'disabled': disableEdit
            } );
        }

        if (this.isAdminMode) {

            let disableApprove = false;

            if(this.approvedStatuses.includes(row?.reduivy__Status__c)){
                disableApprove = true;
            }
            actions.push( {
                'label': this.label.APPROVE_LABEL,
                'name': conCreditTransferConstants.APPROVE_ACTION,
                'disabled': disableApprove
            } );
        }

        if (this.isAdminMode) {

            let disableReject = false;

            if(this.rejectedStatuses.includes(row?.reduivy__Status__c)){
                disableReject = true;
            }
            actions.push( {
                'label': this.label.REJECT_LABEL,
                'name': conCreditTransferConstants.REJECT_ACTION,
                'disabled': disableReject
            } );
        }

        if (this.isAdminMode || this.isStudentMode) {

            let disableSubmit = false;

            if(!this.draftStatuses.includes(row?.reduivy__Status__c) && this.isStudentMode){
                disableSubmit = true;
            }
            actions.push( {
                'label': this.label.SUBMIT_LABEL,
                'name': conCreditTransferConstants.SUBMIT_ACTION,
                'disabled': disableSubmit
            } );
        }

        setTimeout( () => {
            doneCallback( actions );
        }, 200 );

    }

    /**
     * @description Return true to show modal title and icon
     */
    get showModalHeader(){
        if(this.componentLabel){
            return true;
        }
        return false;
    }

    /**
     * @description Return admin mode
     */
    get isAdminMode() {
        
        if(this.userMode === commonConstants.USER_MODE_ADMIN){
            return true;
        }

        return false;
        
    }

    /**
     * @description Return admin mode
     */
    get isStudentMode() {
        
        if(this.userMode === commonConstants.USER_MODE_STUDENT){
            return true;
        }

        return false;
        
    }

    /**
     * @description Return true if the ctaData is fetched by the wire method
     */
    get isCtaDataReady() {
        
        if (this.recordId && this.ctaData) {
            return true;
        }

        return false;
    }

    /**
     * @description Return list of credit transfer application
     */
    get ctaList(){

        if(this.isCtaDataReady && this.ctaData.records){
            return this.ctaData.records;
        }

        return null;
    }

    /**
     * @description Return column metadata to be used for data table
     */
    get tableColumns(){

        if(this.isCtaDataReady && this.ctaData.columns){

            return this.ctaData.columns;
        }

        return null;
    }

    /**
     * @description the user language
     */
    get language() {
        return formatLanguageCodeToPosix(LANG);
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
        let parseData = JSON.parse(JSON.stringify(this.ctaData.records));
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
        this.ctaData.records = parseData;
    }

    /**
     * @description Return no record label
     */
    get noRecordLabel() {
        return this.label.NO_RECORD_LABEL;
    }

    /**
     * @descripton Console log for debugging
     */
	consoleLog(anything, isJson){
        logInfo('conCreditTransferWizard', anything, this.enableDebugMode, isJson);
    }

}