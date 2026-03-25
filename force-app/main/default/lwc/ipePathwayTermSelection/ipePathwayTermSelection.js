/**
 * @Author 		WDCi (Lean)
 * @Date 		Oct 2023
 * @group 		Enrollment Wizard
 * @Description Student enrollment wizard
 * @changehistory
 * ISS-001752 05-10-2022 Lean - new component
 * ISS-002330 20-03-2025 XW - Show Study Term translation name if found
 */
import { LightningElement, api, wire, track } from 'lwc';
import LightningModal from 'lightning/modal';

import { promptInfo, promptError, promptWarning, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';
import { customLabels } from 'c/labelLoader';
import { commonConstants } from 'c/lwcUtil';

import { refreshApex } from '@salesforce/apex';
import { notifyRecordUpdateAvailable, updateRecord } from 'lightning/uiRecordApi';

import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import IPW_OBJECT from '@salesforce/schema/Individual_Pathway__c';

//Apex methods
import ctrlGetAcademicTerms from '@salesforce/apex/REDU_IpePathwayTermSelection_LCTRL.getAcademicTerms';
import ctrlGetTranslationFieldForNameByObjPrefix from '@salesforce/apex/REDU_Translation_LCTRL.getTranslationFieldForNameByObjPrefix';

import SELECT_A_TERM_LABEL from '@salesforce/label/c.Select_An_Academic_Term';

const OBJ_TRANSLATION = [
    "STM"
];

export default class IpePathwayTermSelection extends LightningModal {
	
	//configurable attributes
    @api individualPeId;
    @api individualPathwayId;
    @api userMode = 'Admin'; //supported options: Admin, Student
	@api enableDebugMode = false;
	
	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false;
	loadedLists = 0;

    selectedTermId;
    @track academicTerms = [];
	@track academicTermsWireResult = [];
    
    @track objectTranslatedNameResult;
    @track objectTranslatedNameResponse;
	
	//js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'tooltips'
    modules = ['stringutil'];
	
    /**
     * @descripton Get the object info
     */
    @wire(getObjectInfo, {objectApiName: IPW_OBJECT})
    ipwObjInfo;

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
		
	}
	
    /**
     * @descripton disconnected callback
     */
	disconnectedCallback() {
		
	}

    /**
     * @description Refresh data
     */
    refreshData() {
        this.notifyRecordChanges();

        refreshApex(this.academicTermsWireResult);

        return new Promise((resolve) => {
            resolve(true);
        });
    }

    /**
     * @description Return term combobox field placeholder text
     */
    get termComboPlaceholder() {
        return SELECT_A_TERM_LABEL.format([customLabels.ACADEMICTERM_LABEL]);
    }

    /**
     * @description Return term combobox field label
     */
    get termComboLabel() {
        return customLabels.ACADEMICTERM_LABEL;
    }

    /**
     * @description Return overlay model hearder
     */
    get headerLabel() {
        return SELECT_A_TERM_LABEL.format([customLabels.ACADEMICTERM_LABEL]);
    }

    /**
     * @description Return loading label
     */
    get loadingLabel() {
        return customLabels.LOADING_LABEL;
    }

    /**
     * @description Return cancel button label
     */
    get cancelButtonLabel() {
        return customLabels.CANCEL_LABEL;
    }

    /**
     * @description Return confirm button label
     */
    get confirmButtonLabel() {
        return customLabels.CONFIRM_LABEL;
    }

    /**
     * @description Return individual pathway saved message
     */
    get ipwSavedMessage() {
        if (this.ipwObjInfo.data) {
            return customLabels.RECORD_SAVED_LABEL.format([this.ipwObjInfo.data.label]);
        }

        return null;
    }

    /**
     * @description Handle close button click
     */
    handleCloseClick(event) {
        this.close({operation: 'cancel'});
    }

    /**
     * @description Handle confirm button click
     */
    handleConfirmClick(event) {
        if (this.validateInputFields()) {
            this.saveIndividualPathwayTerm();

            this.close({
                operation: 'confirm',
                academicTermId: this.selectedTermId
            });
        }
    }

    /**
     * @description Validate the input fields on the modal to ensure that all required fields are filled.
     * @returns boolean
     */
    validateInputFields() {
        const allValid = [...this.template.querySelectorAll('lightning-combobox')]
            .reduce((validSoFar, inputField) => {
                inputField.reportValidity();
                return validSoFar && inputField.checkValidity();
            }, true);

        return allValid;
    }

    /**
     * @description Get the available academic terms based on individual program enrollment id
     */
    @wire(ctrlGetAcademicTerms, {individualPeId: '$individualPeId'})
    wireAcademicTerms (result) {
        this.academicTermsWireResult = result;

        if (result.data) {
            let response = result.data;
            if (response.responseData) {
                this.academicTerms = JSON.parse(response.responseData);
            }

            this.consoleLog(this.academicTerms, true);

        } else if (result.error) {
            this.academicTerms = [];
            promptError(customLabels.ERROR_LABEL, getErrorMessage(result.error));
        }
    }


    /**
     * @description Get Study Term Translation
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
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    /**
     * @description Return term combobox options
     */
    get termComboOptions() {

        let termOptions = [];
        if (this.academicTerms) {
            for (let term of this.academicTerms) {
                if (term.reduivy__For_Internal_Only__c && this.userMode !== commonConstants.USER_MODE_ADMIN) {
                    continue;
                }
                let termName = '';
                if(this.stmNameTranslationField && Object.hasOwn(term, this.stmNameTranslationField)) {
                    termName = term[this.stmNameTranslationField];
                } else {
                    termName = term.reduivy__Display_Name__c
                }
                
                termOptions.push({
                    id: term.Id,
                    value: term.Id,
                    label: termName,
                    selected: false
                });
            }
        }

        return termOptions;
    }

    /**
     * @description Handle term combobox on change
     */
    handleTermComboOnchange(event) {
        this.selectedTermId = event.detail.value;
    }

    /**
     * @description Notify lightning service about record changes
     */
    notifyRecordChanges() {
        let recordIds = [
            {recordId: this.individualPeId},
            {recordId: this.individualPathwayId}
        ];

        notifyRecordUpdateAvailable(recordIds);
    }

    /**
     * @descripton Sample method that invoke apex controller
     */
    saveIndividualPathwayTerm() {
        this.toggleSpinner(1);

        try {
            
            const fields = {
                Id: this.individualPathwayId,
                reduivy__Academic_Term__c: this.selectedTermId
            };

            const ipwObject = {fields};

            updateRecord(ipwObject)
            .then(() => {
                this.toggleSpinner(-1);
                this.refreshData();
                promptSuccess(this.ipwSavedMessage, null);
            })
            .catch(error => {
                promptError(customLabels.ERROR_LABEL, getErrorMessage(error));
                this.toggleSpinner(-1);
            });       

        } catch (error) {
            this.toggleSpinner(-1);
            promptError(customLabels.ERROR_LABEL, getErrorMessage(error));
        }
    }
     
    /**
     * @description return the study term translation field for display name
     */
    get stmNameTranslationField() {
        return this.objectTranslatedNameResponse?.STM;
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
        logInfo('ipePathwayTermSelection', anything, this.enableDebugMode, isJson);
    }
	
}