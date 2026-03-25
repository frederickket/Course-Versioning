/**
 * @Author 		WDCi (VTan)
 * @Date 		Jan 2023
 * @group 		Credit Transfer Wizard
 * @Description Handle creation and modification of credit transfer application in credit transfer wizard.
 * @changehistory
 * ISS-001659 17-01-2024 VTan - Inital Built.
 * ISS-002045 24-07-2024 Sueanne - added fields in credit transfer approve modal
 * ISS-002230 22-01-2025 XW - replaced hardcoded 'unknown' to label
 * ISS-002330 21-03-2025 XW - display translation study unit if found name in approval modal
 * ISS-002383 08-04-2025 XW - fixed bug where the wizard is infinite loading when creating Manual Assignment CTA in student mode
 * ISS-002434 30-04-2025 XiRouh - Added handleError(), removed lightning-messages for lightning-record-edit-form in html
 */
import { api, track, wire } from 'lwc';
import { promptError, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo } from 'c/loggingUtil';
import { getRecord } from "lightning/uiRecordApi";
import { RefreshEvent } from 'lightning/refresh';
import { refreshApex } from '@salesforce/apex';
import LightningModal from 'lightning/modal';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';

import { commonConstants } from 'c/lwcUtil';
import { conCreditTransferConstants } from 'c/conCreditTransferHelper';
import { customLabels } from 'c/labelLoader';
import ADDNEWAGREEMENT_LABEL from '@salesforce/label/c.Add_New_Agreement';
import ADDNEWAGREEMENTUNIT_LABEL from '@salesforce/label/c.Add_New_Agreement_Unit_Equivalent';
import ADDEDIT_CT_APPLICATION_NOTE_LABEL from '@salesforce/label/c.New_Credit_Transfer_Application_Notes';
import APPROVE_CT_APPLICATION_CONFIRMATION_LABEL from '@salesforce/label/c.Approve_CTA_Confirmation_With_SU';
import APPROVE_CT_APPLICATION_CONFIRMATION_2_LABEL from '@salesforce/label/c.Approve_CTA_Confirmation_With_Multi_SU';
import APPROVE_CT_APPLICATION_CONFIRMATION_ERR_LABEL from '@salesforce/label/c.Approve_CTA_Confirmation_Error';
import APPROVE_CT_APPLICATION_CONFIRMATION_IPS_LABEL from '@salesforce/label/c.Approve_CTA_Confirmation_With_IPS';

import STUDYUNIT_OBJECT from '@salesforce/schema/Study_Unit__c';
import IPS_OBJECT from '@salesforce/schema/Individual_Plan_Structure__c';
import CTA_OBJECT from '@salesforce/schema/Credit_Transfer_Application__c';
import AUE_OBJECT from '@salesforce/schema/Agreement_Unit_Equivalent__c';
import ctrlGetFields from '@salesforce/apex/REDU_ConCreditTransferModal_LCTRL.getFields';
import ctrlGetTranslationFieldForNameByObjPrefix from '@salesforce/apex/REDU_Translation_LCTRL.getTranslationFieldForNameByObjPrefix';

const OBJ_TRANSLATION = [
    "SUN"
];

export default class ConCreditTransferModal extends LightningModal {

    //configurable attributes
    @api userMode;
    @api modalType;
    @api recordId;
    @api contactId;
    @api modalTitle;
    @api enableDebugMode = false;

    @api agreementRpPrimaryField;
    @api agreementRpAdditionalField;
    @api agreementUnitRpPrimaryField;
    @api agreementUnitRpAdditionalField;
    @api ipeRpPrimaryField;
    @api ipeRpAdditionalField;
    @api ipsRpPrimaryField;
    @api ipsRpAdditionalField;

    @api applicationFormFieldSetName;
    @api approvalFormFieldSetName;

    //wire attributes
    @track aueWireResult = [];
    @track aueRecord = null;
    ctaFieldsWireResult;
    ctaFieldsData;
    
    //internal attributes
    @track fields;
    ShowBtn = false;
    loadedLists = 0;
    selectedAgreement = null;
    selectedAgreementUnit = null;
    selectedIPE = null;
    selectedIPS = null;
    aueFilter;
    ipeFilter;
    ipsFilter;
    isContentVisible = false;

    hasStudyUnit = false;
    selectedStudyUnit;
    selectedStudyUnits = [];
    aueType;

    @track objectTranslatedNameResult;
    @track objectTranslatedNameResponse;

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
    connectedCallback() {
        this.isContentVisible = false;
        refreshApex(this.ctaFieldsWireResult);
    }

    /**
     * @description Refresh data
     */
    refreshModalData() {
        this.consoleLog('refreshModalData');

        this.toggleSpinner(1);
        refreshApex(this.ctaFieldsWireResult);

        this.toggleSpinner(-1);
        return new Promise((resolve) => {
            resolve(true);
        });
    }

    /**
     * @descripton Get the object info
     */
    @wire(getObjectInfo, {objectApiName: STUDYUNIT_OBJECT})
    studyUnitInfo;

    /**
     * @descripton Get the object info
     */
    @wire(getObjectInfo, {objectApiName: IPS_OBJECT})
    ipsInfo;

    /**
     * @descripton Get the object info
     */
    @wire(getObjectInfo, {objectApiName: CTA_OBJECT})
    ctaInfo;

    /**
     * @descripton Get the object info
     */
    @wire(getObjectInfo, {objectApiName: AUE_OBJECT})
    aueInfo;

    /**
     * @description Get type of the selected agreement unit equivalent
     */
    @wire(getRecord, { recordId: "$selectedAgreementUnit", fields: ["reduivy__Agreement_Unit_Equivalent__c.reduivy__Type__c"] })
    wiredRecord(result) {
        
        this.aueWireResult = result;

        if (result.data) {
            this.aueRecord = result.data;
            this.consoleLog(this.aueRecord, true);
            
        } else if (result.error) {
            this.aueRecord = null;
            promptError(customLabels.ERROR_LABEL, getErrorMessage(result.error));
        }

    }

    /**
     * @descripton Get the child Individual Plan Structure (Both Group and Unit)
     */
    @wire(ctrlGetFields, { 
        fieldSetName: "$applicationFormFieldSetName",
        approveModalFieldSetName: "$approvalFormFieldSetName",
        objectName: "reduivy__Credit_Transfer_Application__c",
        recordId: "$recordId",
    })
    wiredGetFields(result) {

        this.toggleSpinner(1);
        this.ctaFieldsWireResult = result;
        this.ctaFieldsData = null;
   
        if (result.data) {

            let ctaFieldMember = JSON.parse(result.data.responseData);
            this.consoleLog(ctaFieldMember.lookupFields, true);
            this.consoleLog(ctaFieldMember.approvableUnits, true);
            this.consoleLog(ctaFieldMember.approveModalFieldMember, true);

            //Assign the selected values for record picker component
            if(ctaFieldMember.lookupFields){

                if(ctaFieldMember.lookupFields.reduivy__Agreement_Unit_Equivalent__c === undefined){

                    this.selectedAgreementUnit = null;
                    this.selectedAgreement = null;

                }else{

                    this.selectedAgreementUnit = ctaFieldMember.lookupFields.reduivy__Agreement_Unit_Equivalent__c;
                    this.aueType = ctaFieldMember.lookupFields.reduivy__Agreement_Unit_Equivalent__r.reduivy__Type__c;

                    if(ctaFieldMember.lookupFields.reduivy__Agreement_Unit_Equivalent__r.reduivy__Agreement__c === undefined){
                        this.selectedAgreement = null;
                    }else{
                        this.selectedAgreement = ctaFieldMember.lookupFields.reduivy__Agreement_Unit_Equivalent__r.reduivy__Agreement__c;
                    }
                }
                
                if(ctaFieldMember.lookupFields.reduivy__Individual_Program_Enrollment__c === undefined){
                    this.selectedIPE = null;
                }else{
                    this.selectedIPE = ctaFieldMember.lookupFields.reduivy__Individual_Program_Enrollment__c;
                }

                if(ctaFieldMember.lookupFields.reduivy__Individual_Plan_Structure__c === undefined){
                    this.selectedIPS = null;
                }else{
                    this.selectedIPS = ctaFieldMember.lookupFields.reduivy__Individual_Plan_Structure__c;
                }
            }

            if(ctaFieldMember.approvableUnits){
                if(
                    Array.isArray(ctaFieldMember.approvableUnits) && 
                    ctaFieldMember.approvableUnits.length > 0
                ) {
                    this.hasStudyUnit = true;
                }
            }

            this.ctaFieldsData = ctaFieldMember;

        } else if (result.error) {

            promptError(customLabels.ERROR_LABEL, getErrorMessage(result.error));
        }

        this.toggleSpinner(-1);
    }

    /**
     * @description Get Study Unit Translation Name
     */
    @wire(ctrlGetTranslationFieldForNameByObjPrefix, { objectPrefixes: OBJ_TRANSLATION})
    wiredTranslationFieldResult(result) {
        
        this.objectTranslatedNameResult = result;
        this.objectTranslatedNameResponse = null;

        if (result.data) {
            let response = result.data;
            if (response.responseData) {
                this.objectTranslatedNameResponse = JSON.parse(response.responseData);
            }
            this.consoleLog(this.objectTranslatedNameResponse, true);
            
        } else if (result.error) {
            promptError(customLabels.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    /**
     * @description study unit options for checkboxes
     */
    get studyUnitOptions(){
        let options = [];

        if(this.ctaFieldsDataReady && this.ctaFieldsData.approvableUnits){

            for (let studyUnit of this.ctaFieldsData.approvableUnits) {
                let sunName = studyUnit?.[this.sunNameTranslationField];
                if(!sunName) {
                    sunName = studyUnit?.Name;
                }
                options.push({label: sunName + ' (' + studyUnit.reduivy__Unit_Code__c + ')', value: studyUnit.reduivy__Unit_Code__c});
                this.hasStudyUnit = true;
            }

            if (options.length === 1) {
                this.selectedStudyUnit = options[0].value;
            }
        }

        return options;
    }


    /**
     * @descripton handle changes of agreement record picker
     */
    handleAgreementChange(event) {
        
        this.selectedAgreement = event.detail.recordId;
        this.refs.agreementUnitRP.clearSelection();
        this.selectedAgreementUnit = null;
    }

    /**
     * @descripton handle changes of agreement unit record picker
     */
    handleAgreementUnitChange(event) {
        
        this.selectedAgreementUnit = event.detail.recordId;
    }

    /**
     * @descripton handle changes of individual program enrollment record picker
     */
    handleIpeChange(event) {
        
        this.selectedIPE = event.detail.recordId;
        this.refs.individualPsRP.clearSelection();
        this.selectedIPS = null;
    }

    /**
     * @descripton handle changes of individual plan structure record picker
     */
    handleIPSChange(event) {

        this.selectedIPS = event.detail.recordId;
    }

    /**
     * @descripton Spinner loading status
     */
	get isLoading(){
        return (this.loadedLists === 0 && this.isContentVisible) ? false : true;
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
     * @descripton to show edit form content
     */
    handleLoad() {
        this.isContentVisible = true; 
    }

    /**
     * @description return the study event translation field for name
     */
    get sunNameTranslationField() {
        return this.objectTranslatedNameResponse?.SUN;
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
     * @description Return true if the selected agreement unit equivalent is manual
     */
    get isManuaAssignment() {
        
        if(this.selectedAgreementUnit && this.aueRecord && this.aueRecord.fields.reduivy__Type__c.value === conCreditTransferConstants.AUE_TYPE_MANUAL){
            this.consoleLog(this.aueRecord.fields.reduivy__Type__c.value);
            return true;
        }

        return false;
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
        return customLabels.LOADING_LABEL;
    }

    /**
     * @description Return save label
     */
    get saveButtonLabel() {

        if(this.isApproveModal){
            return customLabels.APPROVE_LABEL;
        }
        
        return customLabels.SAVE_LABEL;
    }

    /**
     * @description Return true if save is not allowed
     */
    get saveButtonDisabled() {

        return this.isLoading || (this.isApproveModal && this.manualAssignment && !this.showipsGroupField);
    }

    /**
     * @description Return add new agreement label
     */
    get newAgreementLabel() {

        return ADDNEWAGREEMENT_LABEL;
    }

    /**
     * @description Return add new agreement unit label
     */
    get newAgreementUnitLabel() {

        return ADDNEWAGREEMENTUNIT_LABEL;
    }

    /**
     * @description Return add new agreement unit label
     */
    get ctaNoteLabel() {

        return ADDEDIT_CT_APPLICATION_NOTE_LABEL;
    }

    /**
     * @description Return agreement field label
     */
    get agreementFieldLabel() {

        if(this.aueInfo.data){
            return this.aueInfo.data.fields.reduivy__Agreement__c.label;
        }

        return null;
    }

    /**
     * @description Return agreement field's placeholder label
     */
    get agreementPlaceholderLabel() {

        return customLabels.SEARCHPLACEHOLDER_LABEL.format([this.agreementFieldLabel]);
    }

    /**
     * @description Return agreement unit field label
     */
    get agreementUnitFieldLabel() {

        if(this.ctaInfo.data){
            return this.ctaInfo.data.fields.reduivy__Agreement_Unit_Equivalent__c.label;
        }

        return null;
    }

    /**
     * @description Return agreement unit field's placeholder label
     */
    get agreementUnitPlaceholderLabel() {

        return customLabels.SEARCHPLACEHOLDER_LABEL.format([this.agreementUnitFieldLabel]);
    }

    /**
     * @description Return individual program enrollment field label
     */
    get ipeFieldLabel() {

        if(this.ctaInfo.data){
            return this.ctaInfo.data.fields.reduivy__Individual_Program_Enrollment__c.label;
        }

        return null;
    }

    /**
     * @description Return individual program enrollment field's placeholder label
     */
    get ipePlaceholderLabel() {

        return customLabels.SEARCHPLACEHOLDER_LABEL.format([this.ipeFieldLabel]);
    }

    /**
     * @description Return individual plan structure field label
     */
    get ipsFieldLabel() {

        if(this.ctaInfo.data){
            return this.ctaInfo.data.fields.reduivy__Individual_Plan_Structure__c.label;
        }

        return null;
    }

    /**
     * @description Return individual plan structure field's placeholder label
     */
    get ipsPlaceholderLabel() {

        return customLabels.SEARCHPLACEHOLDER_LABEL.format([this.ipsFieldLabel]);
    }

    /**
     * @description Return cancel label
     */
    get cancelButtonLabel() {

        return customLabels.CANCEL_LABEL;
    }

    /**
     * @description Return study unit object plural label
     */
    get sunLabelPlural() {
        if (this.studyUnitInfo && this.studyUnitInfo.data) {
            return this.studyUnitInfo.data.labelPlural;
        }

        return customLabels.UNKNOWN_LABEL;
    }

    /**
     * @description Return study unit object plural label
     */
    get sunLabel() {
        if (this.studyUnitInfo && this.studyUnitInfo.data) {
            return this.studyUnitInfo.data.label;
        }

        return customLabels.UNKNOWN_LABEL;
    }

    /**
     * @description Return individual plan structure object label
     */
    get ipsLabel() {
        if (this.ipsInfo && this.ipsInfo.data) {
            return this.ipsInfo.data.label;
        }

        return customLabels.UNKNOWN_LABEL;
    }

    /**
     * @description Return current filter for agreement unit equivalent search
     */
    get agreementUnitfilter() {

        // filter for agreement unit equivalent
        this.aueFilter = {
            criteria: [
                {
                    fieldPath: 'reduivy__Agreement__c',
                    operator: 'eq',
                    value: this.selectedAgreement,
                }
            ],
        };
        return this.aueFilter;
    }

    /**
     * @description Return current filter for individual program enrollment search
     */
    get individualPefilter() {

        // filter for individual plan structure
        this.ipeFilter = {
            criteria: [
                {
                    fieldPath: 'reduivy__Contact__c',
                    operator: 'eq',
                    value: this.contactId,
                }
            ],
        };
        return this.ipeFilter;
    }

    /**
     * @description Return matching field for agreement search
     */
    get agreementMatchingInfo() {

        // filter for individual plan structure
        let agreementMatchingInfo = {
            primaryField: { fieldPath: this.agreementRpPrimaryField },
            additionalFields: [{ fieldPath: this.agreementRpAdditionalField }],
        };
        return agreementMatchingInfo;
    }

    /**
     * @description Return current display field for agreement search
     */
    get agreementDisplayInfo() {

        // filter for individual plan structure
        let agreementDisplayInfo = {
            primaryField: this.agreementRpPrimaryField,
            additionalFields: [this.agreementRpAdditionalField],
        };
        return agreementDisplayInfo;
    }

    /**
     * @description Return matching field for agreement unit search
     */
    get agreementUnitMatchingInfo() {

        // filter for individual plan structure
        let agreementUnitMatchingInfo = {
            primaryField: { fieldPath: this.agreementUnitRpPrimaryField },
            additionalFields: [{ fieldPath: this.agreementUnitRpAdditionalField }],
        };
        return agreementUnitMatchingInfo;
    }

    /**
     * @description Return current display field for agreement unitsearch
     */
    get agreementUnitDisplayInfo() {

        // filter for individual plan structure
        let agreementUnitDisplayInfo = {
            primaryField: this.agreementUnitRpPrimaryField,
            additionalFields: [this.agreementUnitRpAdditionalField],
        };
        return agreementUnitDisplayInfo;
    }

    /**
     * @description Return current filter for individual program enrollment search
     */
    get individualPeMatchingInfo() {

        // filter for individual plan structure
        let ipeMatchingInfo = {
            primaryField: { fieldPath: this.ipeRpPrimaryField },
            additionalFields: [{ fieldPath: this.ipeRpAdditionalField }],
        };
        return ipeMatchingInfo;
    }

    /**
     * @description Return current filter for individual program enrollment search
     */
    get individualPeDisplayInfo() {

        // filter for individual plan structure
        let ipeDisplayInfo = {
            primaryField: this.ipeRpPrimaryField,
            additionalFields: [this.ipeRpAdditionalField],
        };
        return ipeDisplayInfo;
    }

    /**
     * @description Return matching field for agreement unit search
     */
    get individualPsMatchingInfo() {

        // filter for individual plan structure
        let individualPsMatchingInfo = {
            primaryField: { fieldPath: this.ipsRpPrimaryField },
            additionalFields: [{ fieldPath: this.ipsRpAdditionalField }],
        };
        return individualPsMatchingInfo;
    }

    /**
     * @description Return current display field for agreement unitsearch
     */
    get individualPsDisplayInfo() {

        // filter for individual plan structure
        let individualPsDisplayInfo = {
            primaryField: this.ipsRpPrimaryField,
            additionalFields: [this.ipsRpAdditionalField],
        };
        return individualPsDisplayInfo;
    }

    /**
     * @description Return current filter for individual plan structure search
     */
    get individualPsfilter() {

        // filter for agreement unit equivalent
        this.ipsFilter = {
            criteria: [
                {
                    fieldPath: 'reduivy__Individual_Program_Enrollment__c',
                    operator: 'eq',
                    value: this.selectedIPE,
                }
            ],
        };
        return this.ipsFilter;
    }

    /**
     * @description Return true if the ctaFieldsData is fetched by the wire method
     */
    get ctaFieldsDataReady() {
        
        if (this.contactId && this.ctaFieldsData) {
            return true;
        }

        return false;
    }

    /**
     * @description Return list of lightning input fields from field set
     */
    get ctaFieldMember(){

        if(this.ctaFieldsDataReady && this.ctaFieldsData.fieldMember){
            return this.ctaFieldsData.fieldMember;
        }

        return null;
    }

    /**
     * @description return fields for view from
     */
    get infoFields(){
        if(this.ctaFieldMember){
            return this.ctaFieldMember.map(field => field.fieldName);
        }
        return null;
    }

    /**
     * @description Return list of lightning input fields from field set
     */
    get approveModalFieldMember(){

        if(this.ctaFieldsDataReady && this.ctaFieldsData.approveModalFieldMember){
            return this.ctaFieldsData.approveModalFieldMember;
        }

        return null;
    }

    /**
     * @description return fields for view from
     */
    get approveModalInfoFields(){
        if(this.approveModalFieldMember){
            return this.approveModalFieldMember.map(field => field.fieldName);
        }
        return null;
    }

    /**
     * @description return approved status for credit transfer application
     */
    get ctaApprovedStatus(){
        if(this.ctaFieldsDataReady && this.ctaFieldsData.approveModalFieldMember){
            return this.ctaFieldsData.approvalStatus;
        }
        return null;
    }

    /**
     * @description Return sps field value from ctaFieldsData
     */
    get ctaFieldsDataSpsFieldValue() {

        if (this.ctaFieldsDataReady && this.ctaFieldsData.lookupFields) {
            return this.ctaFieldsData.lookupFields.reduivy__Individual_Plan_Structure__r.reduivy__Study_Plan_Structure__r.Name;
        }

        return null;
    }

    /**
     * @description Return true if this is a create new or edit modal
     */
    get isNewEditModal(){

        if(this.modalType === conCreditTransferConstants.CTAMODAL_NEW || this.modalType === conCreditTransferConstants.CTAMODAL_EDIT){
            return true;
        }

        return false;
    }

    /**
     * @description Return true if this is credit transfer application approval modal
     */
    get isApproveModal(){

        if(this.modalType === conCreditTransferConstants.CTAMODAL_APPROVAL){
            return true;
        }

        return false;
    }

    /**
     * @description Return true if this is the related agreement unit equivalent has matching study unit
     */
    get showUnitOptions() {

        if (this.isApproveModal && this.hasStudyUnit) {
            return true;
        }

        return false;
    }
    
    /**
     * @description Get confirmation message during the application approval
     */
    get confirmationMessage() {

        if(this.manualAssignment && this.showipsGroupField && this.ipsLabel) {
            return APPROVE_CT_APPLICATION_CONFIRMATION_IPS_LABEL.format([this.ipsLabel]);

        } else if(this.manualAssignment && !this.showipsGroupField && this.ipsLabel) {
            return APPROVE_CT_APPLICATION_CONFIRMATION_ERR_LABEL.format([this.ipsLabel, this.ipsLabel]);

        } else if(!this.manualAssignment && this.multiStudyUnitSelect && this.sunLabelPlural && this.sunLabel) {
            return APPROVE_CT_APPLICATION_CONFIRMATION_2_LABEL.format([this.sunLabelPlural, this.sunLabel]);

        } else if(!this.manualAssignment && this.sunLabel) {
            return APPROVE_CT_APPLICATION_CONFIRMATION_LABEL.format([this.sunLabel]);
        }
        
        return null;
    }

    /**
     * @description Return true if allow user to select multiple study unit during the application approval
     */
    get multiStudyUnitSelect() {
        
        return this.aueType === 'One to Many';
    }

    /**
     * @description Return true if the individual plan structure lookup is required
     */
    get manualAssignment() {

        return this.aueType === 'Manual Assignment';
    }

    /**
     * @description Return true if this is the application is for individual plan structure group
     */
    get showipsGroupField() {
        if(this.selectedIPS){
            return true;
        }

        return false;
    }

    /**
     * @description Return credit transfer application saved message
     */
    get ctaSavedMessage() {
        if (this.ctaInfo.data) {
            return customLabels.RECORD_SAVED_LABEL.format([this.ctaInfo.data.label]);
        }

        return null;
    }

    /**
     * @description Combine selected study unit code
     */
    handleMultiStudyUnitOnChange(event){
        this.selectedStudyUnits = event.detail.value;
        this.selectedStudyUnit = this.selectedStudyUnits.join(';');
    }

    /**
     * @description Handle study unit on change
     */
    handleCourseOnChange(event){
        this.selectedStudyUnit = event.detail.value;
    }

    /**
     * @description Handle cancel click to close the modal with operation = cancel, eventSource and eventData
     * @param {*} event 
     */
    handleCloseClick() {
        this.close({
            operation: 'close',
            eventSource: this.eventSource,
            eventData: this.eventData
        });
    }

    /**
     * @description Handle save click to close the modal with operation = cancel, eventSource and eventData
     * @param {*} event 
     */
    handleSaveClick() {

        this.toggleSpinner(1);

        if(this.isNewEditModal){
            
            this.consoleLog('Edit Credit Transfer Application');
            if(!this.validateFields()){
                this.toggleSpinner(-1);
                return;
            }
    
            if(!this.refs.agreementRP.reportValidity()){
                this.toggleSpinner(-1);
                return;
            }
    
            if(!this.refs.agreementUnitRP.reportValidity()){
                this.toggleSpinner(-1);
                return;
            }

            if(this.isManuaAssignment && this.isAdminMode && !this.refs.individualPeRP?.reportValidity()){
                this.toggleSpinner(-1);
                return;
            }

            if(this.isManuaAssignment && this.isAdminMode && !this.refs.individualPsRP?.reportValidity()){
                this.toggleSpinner(-1);
                return;
            }
    
            const btn = this.template.querySelector( ".submitFormHidden" );
    
            if( btn ){ 
                btn.click();
            }
        }else if(this.isApproveModal){

            this.consoleLog('Approve Credit Transfer Application1');
            if(!this.validateFields()){
                this.toggleSpinner(-1);
                return;
            }
            
            if(!this.manualAssignment){
                if(this.multiStudyUnitSelect && !this.refs.suCheckboxGroup.reportValidity()){
                    this.toggleSpinner(-1);
                    return;
                }
    
                if(!this.multiStudyUnitSelect && !this.refs.suRadioGroup.reportValidity() && !this.manualAssignment){
                    this.toggleSpinner(-1);
                    return;
                }
            }
            
            try {
                this.consoleLog('Approve Credit Transfer Application2');
                
                const btn = this.template.querySelector( ".submitApproveFormHidden" );
                
                if( btn ){ 
                    btn.click();
                    this.dispatchEvent(new RefreshEvent());
                }
            } catch (error) { 
                this.toggleSpinner(-1);
                promptError(customLabels.ERROR_LABEL, getErrorMessage(error));
            }
        }
        
    }

    /**
     * @description Handle submit click
     * @param {*} event 
     */
    handleSubmit(event) {
        this.consoleLog('handleSubmit');
        
        event.preventDefault();
        let fields = event.detail.fields;
        fields.reduivy__Contact__c = this.contactId;
        fields.reduivy__Agreement_Unit_Equivalent__c = this.selectedAgreementUnit;
        fields.reduivy__Individual_Program_Enrollment__c = this.selectedIPE;
        fields.reduivy__Individual_Plan_Structure__c = this.selectedIPS;

        this.consoleLog(fields, true);

        this.template.querySelector('[data-id="ctapplicationeditform"]').submit(fields);

    }

    /**
     * @description Handle submit click
     * @param {*} event 
     */
    handleApproveSubmit(event) {

        event.preventDefault();
        let fields = event.detail.fields;
        fields.reduivy__Approved_Unit_Codes__c = this.selectedStudyUnit;
        fields.reduivy__Status__c = this.ctaApprovedStatus;

        this.template.querySelector('[data-id="ctapproveeditform"]').submit(fields);

    }

    /**
     * @description prompt an error if error occured while saving
     * @param {*} event 
     */
    handleError(event){
        promptError(customLabels.ERROR_LABEL, getErrorMessage(event.detail));
        this.toggleSpinner(-1);
    }
    
    /**
     * @description Handle save successful action
     * @param {*} event 
     */
    handleSaveSuccess() {

        this.toggleSpinner(-1);

        refreshApex(this.ctaFieldsWireResult);
        this.dispatchEvent(new RefreshEvent());
        promptSuccess(this.ctaSavedMessage, null);

        this.close({
            operation: 'close',
            eventSource: this.eventSource,
            eventData: this.eventData
        }); 

    }

    /**
     * @description Dispatch event to parent component. To navigate to the create new record modal.
     */
    handleNewOnclick(event) {

        this.dispatchAddNewRecordEvent(event);
    }

    /**
     * @description Dispatch event to parent component. To navigate to the create new record modal.
     */
    dispatchAddNewRecordEvent(event) {
        // e.target might represent an input with an id and value
        const { id, value } = event.target;
        const addNewRecordEvent = new CustomEvent('addnewrecord', {
            detail: { id, value }
        });
        this.dispatchEvent(addNewRecordEvent);
    }

    /**
     * @description Validation of the input fields
     */
    validateFields() {
        let requiredFieldsValid = [...this.template.querySelectorAll('[data-customform-save-required="true"]')]
        .reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            this.consoleLog('validateRequiredCustomFormDataFields :: ' + inputCmp.name + ' - ' + inputCmp.value);
            return validSoFar && inputCmp.value;
        }, true);

        return requiredFieldsValid;
    }

    /**
     * @descripton Console log for debugging
     */
	consoleLog(anything, isJson){
        logInfo('conCreditTransferModal', anything, this.enableDebugMode, isJson);
    }

}