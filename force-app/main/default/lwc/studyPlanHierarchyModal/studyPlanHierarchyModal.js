/**
 * @Author 		WDCi (Jordan)
 * @Date 		Dec 2024
 * @group 		Study Plan
 * @Description Study plan hierarchy wizard modal
 * @changehistory
 * ISS-002152 16-12-2024 Jordan - new modal
 */

import { LightningElement, api, wire, track } from 'lwc';
import LightningModal from 'lightning/modal';
import { promptInfo, promptError, promptWarning, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';
import { getFormDataFieldOnChangeValue } from 'c/lwcUtil';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { studyPlanHierarchyConstants } from 'c/studyPlanHierarchyHelper';

import { customLabels } from 'c/labelLoader';

import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import SPS_OBJECT from '@salesforce/schema/Study_Plan_Structure__c';

//Apex methods
import upsertStudyPlanStructure from '@salesforce/apex/REDU_StudyPlanHierarchy_LCTRL.upsertStudyPlanStructure';

export default class StudyPlanHierarchyModal extends LightningModal {
    //configurable attributes
    @api modalTitle;
    @api actionType;
    @api studyPlanId;
    @api spsId;
    @api spsParentId;
    @api spsType;
    @api recordFormColumns;
	@api enableDebugMode = false;

    //internal attributes
    isScriptLoaded = false;
    isInitSuccess = false;
    loadedLists = 0;
    newSpsData = {};

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
     * @descripton rendered callback
     */
	renderedCallback(){
        
    }

    /**
     * @descripton connected callback
     */
    connectedCallback(){

        this.consoleLog(this.modalTitle);
        this.consoleLog(this.actionType);
        this.consoleLog(this.studyPlanId);
        this.consoleLog(this.spsId);
        this.consoleLog(this.spsParentId);
        this.consoleLog(this.spsType);
        this.consoleLog(this.recordFormColumns, true);
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
     * @description Return save label
     */
    get saveLabel() {
        return customLabels.SAVE_LABEL;
    }

    /**
     * @description Return cancel label
     */
    get cancelLabel() {
        return customLabels.CANCEL_LABEL;
    }

    /**
     * @description Return delete label
     */
    get deleteLabel() {
        return customLabels.DELETE_LABEL;
    }

    /**
     * @description Return SPS object label
     */
    get spsObjectLabel() {
        return this.spsObjInfo?.data?.label;
    }

    /**
     * @description Get object info
     */
    @wire(getObjectInfo, { objectApiName: SPS_OBJECT })
    spsObjInfo;

    /**
     * @description This function will be called to handle the changed data in record edit form
     */
    handleFormFieldChange(event) {
        let dataFieldName = event.target.fieldName;
        let dataDisplayType = event.target.dataset.displaytype;
        let dataFieldValue = getFormDataFieldOnChangeValue(dataDisplayType, event.detail);

        this.newSpsData[dataFieldName] = dataFieldValue;

        this.consoleLog(this.newSpsData, true);
    }

    /**
     * @description Handle save click
     */
    handleSaveClick() {
        this.toggleSpinner(1);

        let validated = this.validateSpsFields();

        if (validated) {
            upsertStudyPlanStructure({ 
                spsId: this.spsId,
                studyPlanId: this.studyPlanId,
                spsParentId: this.spsParentId,
                actionType: this.actionType, 
                spsRecord: this.newSpsData
            }).then(result => {
                this.toggleSpinner(-1);

                if (result.isSuccess && result.responseData) {
                    if (this.actionType === studyPlanHierarchyConstants.EDIT_ACTION) {
                        notifyRecordUpdateAvailable([{recordId: this.spsId}]);
                        promptSuccess(customLabels.SUCCESS_LABEL, customLabels.RECORD_SAVED_LABEL);
                    } else if (this.actionType === studyPlanHierarchyConstants.NEW_UNIT_ACTION) {
                        promptSuccess(customLabels.SUCCESS_LABEL, customLabels.RECORD_CREATED_LABEL.format([this.spsObjectLabel]));
                    } else {
                        promptSuccess(customLabels.SUCCESS_LABEL, customLabels.RECORD_CREATED_LABEL.format([this.spsObjectLabel]));
                    }

                    this.close({
                        operation: 'save'
                    });
                } else if (!result.isSuccess) {
                    promptError(customLabels.ERROR_LABEL, result.message);
                }

            }).catch((error) => {
                this.toggleSpinner(-1);
                promptError(customLabels.ERROR_LABEL, getErrorMessage(error));
            })
        } else {
            this.toggleSpinner(-1);
            promptError(customLabels.ERROR_LABEL, customLabels.MISSING_REQUIRED_FIELDS_LABEL);
        }
    }

    /**
    * @description Validate Study Plan Structure fields and return true if it is validated
    */
    validateSpsFields() {
        let element = [...this.template.querySelectorAll('[data-save-required="true"]')];
        let requiredFieldsValid = element.reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            this.consoleLog('validateRequiredDataFields :: ' + inputCmp.name + ' - ' + inputCmp.value);
            return validSoFar && inputCmp.value;

        }, true);

        return requiredFieldsValid;
    }

    /**
     * @description Handle cancel click
     */
    handleCancelClick() {
        this.close({
            operation: 'cancel'
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
        logInfo('StudyPlanHierarchyModal', anything, this.enableDebugMode, isJson);
    }
}