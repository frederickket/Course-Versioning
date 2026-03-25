/**
 * @Author 		WDCi (Jordan)
 * @Date 		Nov 2024
 * @group 		Study Plan Cloning
 * @Description Study plan cloning wizard
 * @changehistory
 * ISS-002153 13-11-2024 Jordan - new component
 * ISS-002230 05-02-2025 XW - display picklist value label if field type is picklist
 * ISS-002396 17-04-2025 XW - fix infinite loading in managed package instance after cloning
 * ISS-002495 22-09-2025 XW - support translation for long text field
 * ISS-002736 25-11-2025 XiRouh - Added tableTextDisplayMode configurable attribute
 * ISS-002779 21-01-2026 Lean - Make table header to respect tableTextDisplayMode
 * ISS-002797 13-02-2025 Lean - Standardize language code format to POSIX
 */
import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { promptError, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo } from 'c/loggingUtil';
import { updateDatatableConfig, getFormDataFieldOnChangeValue, isWrapTextEnabled, commonConstants, getTableHeaderDisplayMode, formatLanguageCodeToPosix } from 'c/lwcUtil';
import { customLabels } from 'c/labelLoader';
import LANG from '@salesforce/i18n/lang';

//refresh module
import { refreshApex } from '@salesforce/apex';
import { registerRefreshContainer, unregisterRefreshContainer } from 'lightning/refresh';

//Apex methods
import getStudyPlanData from '@salesforce/apex/REDU_SplStudyPlanCloning_LCTRL.getStudyPlanData';
import insertStudyPlanCloneData from '@salesforce/apex/REDU_SplStudyPlanCloning_LCTRL.insertStudyPlanCloneData';

import { getObjectInfo } from 'lightning/uiObjectInfoApi';

//Import object
import STUDY_PLAN_OBJECT from '@salesforce/schema/Study_Plan__c';
import STUDY_PATHWAY_OBJECT from '@salesforce/schema/Study_Pathway__c';
import STUDY_PLAN_OPTION_OBJECT from '@salesforce/schema/Study_Plan_Option__c';
import STUDY_PLAN_UNIT_REQUIREMENT_OBJECT from '@salesforce/schema/Study_Plan_Unit_Requirement__c';

import { CloseActionScreenEvent } from 'lightning/actions';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';

//Import labels
import STUDY_PLAN_CLONING_MODAL_TITLE_LABEL from '@salesforce/label/c.Study_Plan_Cloning_Modal_Title'; //ISS-002153
import STUDY_PLAN_CLONING_COPY_NAME_LABEL from '@salesforce/label/c.Study_Plan_Cloning_Copy_Name'; //ISS-002153
import STUDY_PLAN_CLONING_RELATED_CHILD_DESCRIPTION_LABEL from '@salesforce/label/c.Study_Plan_Cloning_Related_Child_Description'; //ISS-002153
import STUDY_PLAN_CLONING_NO_RELATED_DATA_LABEL from '@salesforce/label/c.Study_Plan_Cloning_No_Related_Data'; //ISS-002153
import INCLUDE_EXISTING_STUDY_PLAN_UNIT_REQUIREMENTS_LABEL from '@salesforce/label/c.Include_Existing_Study_Plan_Unit_Requirements'; //ISS-002153
import CLONE_CHILD_STUDY_PLANS from '@salesforce/label/c.Clone_Child_Study_Plans'; //ISS-002153
import STUDY_PLAN_CLONING_SUCCESS_MESSAGE_LABEL from '@salesforce/label/c.Study_Plan_Cloning_Success_Message'; //ISS-002153


export default class SplStudyPlanCloning extends NavigationMixin(LightningElement) {
	
	//configurable attributes
    @api recordId;
    @api modalIconName;
	@api enableDebugMode = false;
	
	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false
	loadedLists = 0;
    modalTitle;
    studyPlanEditableDetailsFieldSetName = 'reduivy__StudyPlanCloning_EditableDetails';
    studyPathwayListingTableFieldSetName = 'reduivy__StudyPlanCloning_ListingTable';
    studyPlanOptionListingTableFieldSetName = 'reduivy__StudyPlanCloning_ListingTable';
    objectName = STUDY_PLAN_OBJECT;
    @track studyPlanColumns;
    @track studyPlanData;
    studyPathwayList;
    studyPathwayColumns;
    @track selectedPathwayIdsArray = [];
    studyPlanOptionList;
    studyPlanOptionColumns;
    @track selectedPlanOptionIdsArray = [];
    newClonedStudyPlanId;
    includeExistingStudyPlanUnitRequirements;
    cloneChildStudyPlans;
    
    //refresh Container
    refreshContainerID;

    //wire attribute
    studyPlanWireResult;
    studyPlanResponse;

	//labels
	label = {
        STUDY_PLAN_CLONING_MODAL_TITLE_LABEL,
        STUDY_PLAN_CLONING_COPY_NAME_LABEL,
        STUDY_PLAN_CLONING_RELATED_CHILD_DESCRIPTION_LABEL,
        STUDY_PLAN_CLONING_NO_RELATED_DATA_LABEL,
        INCLUDE_EXISTING_STUDY_PLAN_UNIT_REQUIREMENTS_LABEL,
        CLONE_CHILD_STUDY_PLANS,
        STUDY_PLAN_CLONING_SUCCESS_MESSAGE_LABEL,
        ...customLabels
    };

    tableTextDisplayMode = commonConstants.TABLE_TEXT_DISPLAY_MODE_WRAP_TEXT;
	
	//js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'jquery'
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
		this.refreshContainerID = registerRefreshContainer(this, this.refreshData);
        this.registerErrorListener();
        this.handleSubscribe();
	}
	
    /**
     * @descripton disconnected callback
     */
	disconnectedCallback() {
		unregisterRefreshContainer(this.refreshContainerID);
        this.handleUnsubscribe();
	}

    /**
     * @description Refresh data
     */
    refreshData() {
        this.consoleLog('refreshData');

        refreshApex(this.studyPlanWireResult);

        return new Promise((resolve) => {
            resolve(true);
        });

    }

    /**
     * @description To obtain the study plan object values
     */
    @wire(getObjectInfo, { objectApiName: STUDY_PLAN_OBJECT })
    studyPlanObjectInfo;

    /**
     * @description To obtain the study pathway object values
     */
    @wire(getObjectInfo, { objectApiName: STUDY_PATHWAY_OBJECT })
    studyPathwayObjectInfo;

    /**
     * @description To obtain the study plan option object values
     */
    @wire(getObjectInfo, { objectApiName: STUDY_PLAN_OPTION_OBJECT })
    studyPlanOptionObjectInfo;

    /**
     * @description To obtain the study plan unit req object values
     */
    @wire(getObjectInfo, { objectApiName: STUDY_PLAN_UNIT_REQUIREMENT_OBJECT })
    studyPlanUnitReqObjectInfo;

    /**
     * @description Sample wire method that invoke apex controller to retrieve data
     */
    @wire(getStudyPlanData, {
        studyPlanId: "$recordId",
        studyPlanEditableDetailsFieldSetName: "$studyPlanEditableDetailsFieldSetName",
        studyPathwayListingTableFieldSetName: "$studyPathwayListingTableFieldSetName",
        studyPlanOptionListingTableFieldSetName: "$studyPlanOptionListingTableFieldSetName",
        language: '$language',
        enableWrapText: "$enableWrapText"
    })
    wireStudyPlan(result) {
        
        this.studyPlanWireResult = result;
        this.studyPlanResponse = null;

        if (result.data) {
            this.studyPlanResponse = JSON.parse(result?.data?.responseData);
            this.consoleLog(this.studyPlanResponse, true);

            //Storing study plan columns and data
            this.studyPlanColumns = this.studyPlanResponse.columns;
            this.studyPlanData = this.studyPlanResponse.studyPlan;

            //Set modal title
            this.modalTitle = this.label.STUDY_PLAN_CLONING_MODAL_TITLE_LABEL.format([this.studyPlanData.Name]);

            //Setting values in the record edit form
            this.studyPlanColumns.forEach(field => {
                if (field.fieldName === 'Name') {
                    field.fieldValue = this.label.STUDY_PLAN_CLONING_COPY_NAME_LABEL.format([this.studyPlanData[field.fieldName]]);
                } else {
                    field.fieldValue = this.studyPlanData[field.fieldName];
                }
            })
            
            this.studyPlanData.Name = this.label.STUDY_PLAN_CLONING_COPY_NAME_LABEL.format([this.studyPlanData.Name]);

            //Related study pathways
            if (this.studyPlanResponse.studyPathwayList) {
                let studyPathwayDatatableConfig = JSON.parse(this.studyPlanResponse.studyPathwayList);
                let studyPathwayData = updateDatatableConfig(studyPathwayDatatableConfig, false, this.language);

                this.studyPathwayList = studyPathwayData.records;
                this.studyPathwayColumns = studyPathwayData.columns;
            }

            //Related study plan options
            if (this.studyPlanResponse.studyPlanOptionList) {
                let studyPlanOptionDatatableConfig = JSON.parse(this.studyPlanResponse.studyPlanOptionList);
                let studyPlanOptionData = updateDatatableConfig(studyPlanOptionDatatableConfig, false);

                this.studyPlanOptionList = studyPlanOptionData.records;
                this.studyPlanOptionColumns = studyPlanOptionData.columns;
            }
        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }

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
     * @description the user language
     */
    get language() {
        return formatLanguageCodeToPosix(LANG);
    }

    /**
     * @description Return study pathway title
     */
    get studyPathwayTitle (){
        return this.studyPathwayObjectInfo?.data?.labelPlural;
    }

    /**
     * @description Return study pathway description
     */
    get studyPathwayDescription (){
        return this.label.STUDY_PLAN_CLONING_RELATED_CHILD_DESCRIPTION_LABEL.format([this.studyPathwayTitle, this.studyPlanObjectInfo?.data?.label]);
    }

    /**
     * @description Return study pathway error
     */
    get studyPathwayError (){
        return this.label.STUDY_PLAN_CLONING_NO_RELATED_DATA_LABEL.format([this.studyPathwayObjectInfo?.data?.labelPlural, this.studyPlanObjectInfo?.data?.label]);
    }

    /**
     * @description Return study plan option title
     */
    get studyPlanOptionTitle (){
        return this.studyPlanOptionObjectInfo?.data?.labelPlural
    }

    /**
     * @description Return study plan option description
     */
    get studyPlanOptionDescription (){
        return this.label.STUDY_PLAN_CLONING_RELATED_CHILD_DESCRIPTION_LABEL.format([this.studyPlanOptionTitle, this.studyPlanObjectInfo?.data?.label]);
    }

    /**
     * @description Return study plan option error
     */
    get studyPlanOptionError (){
        return this.label.STUDY_PLAN_CLONING_NO_RELATED_DATA_LABEL.format([this.studyPlanOptionObjectInfo?.data?.labelPlural, this.studyPlanObjectInfo?.data?.label]);
    }

    /**
     * @description Return active sections
     */
    get activeSections (){
        return ["studypathwaysection", "studyplanoptionsection"];
    }

    /**
     * @description Return Include Existing Study Plan Unit Requirements label
     */
    get includeExistingStudyPlanUnitRequirementsLabel (){
        return this.label.INCLUDE_EXISTING_STUDY_PLAN_UNIT_REQUIREMENTS_LABEL.format([this.studyPlanUnitReqObjectInfo?.data?.labelPlural]);
    }

    /**
     * @description Return Clone Child Study Plans label
     */
    get cloneChildStudyPlansLabel (){
        return this.label.CLONE_CHILD_STUDY_PLANS.format([this.studyPlanObjectInfo?.data?.labelPlural]);
    }

    /**
     * @description Return Cancel button label
     */
    get cancelButtonLabel (){
        return this.label.CANCEL_LABEL;
    }

    /**
     * @description Return Clone button label
     */
    get cloneButtonLabel (){
        return this.label.CLONE_LABEL;
    }

    /**
     * @description Return cloning success label
     */
    get cloningSuccessLabel (){
        return this.label.STUDY_PLAN_CLONING_SUCCESS_MESSAGE_LABEL.format([this.studyPlanObjectInfo?.data?.label]);
    }

    /**
     * @description Method to handle the change of study plan record data
     */
    handleFormFieldChange(event) {

        let dataFieldName = event.target.fieldName;
        let dataDisplayType = event.target.dataset.displaytype;

        let dataFieldValue = getFormDataFieldOnChangeValue(dataDisplayType, event.detail);

        this.studyPlanData[dataFieldName] = dataFieldValue;
    }

    /**
     * @description Method to get the selected study pathway records
     */
    handleStudyPathwayRowSelected(event) {
        var selectedRowsArray = event.detail.selectedRows;
        this.selectedPathwayIdsArray = [];
        
        for (let i = 0; i < selectedRowsArray.length; i++) {
            this.selectedPathwayIdsArray.push(selectedRowsArray[i].Id);
        }
    }

    /**
     * @description Method to get the selected study plan option records
     */
    handleStudyPlanOptionRowSelected(event) {
        var selectedRowsArray = event.detail.selectedRows;
        this.selectedPlanOptionIdsArray = [];
        
        for (let i = 0; i < selectedRowsArray.length; i++) {
            this.selectedPlanOptionIdsArray.push(selectedRowsArray[i].Id);
        }
    }

    /**
     * @description Method to handle the change of the "Include Existing Study Plan Unit Requirements" checkbox
     */
    handleIncludeExistingRequirementsChange(event) {
        this.includeExistingStudyPlanUnitRequirements = event.target.checked;
    }

    /**
     * @description Method to handle the change of the "Clone Child Study Plans" checkbox
     */
    handleCloneChildStudyPlansChange(event) {
        this.cloneChildStudyPlans = event.target.checked;
    }

    /**
     * @description Method to send the data which is to be cloned to apex class
     */
    submitHandler() {
        delete this.studyPlanData.Id;
        let validated = this.validateStudyPlanFields();

        if (validated) {
            this.insertData();
        } else {
            promptError(this.label.ERROR_LABEL, this.label.MISSING_REQUIRED_FIELDS_LABEL);
        }
    }

    /**
    * @description Validate Study Plan fields and return true if it is validated
    */
    validateStudyPlanFields() {
        let element = [...this.template.querySelectorAll('[data-save-required="true"]')];
        let requiredFieldsValid = element.reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            this.consoleLog('validateRequiredDataFields :: ' + inputCmp.name + ' - ' + inputCmp.value);
            return validSoFar && inputCmp.value;

        }, true);

        return requiredFieldsValid;
    }

    insertData() {
        this.toggleSpinner(1);

        try {
            insertStudyPlanCloneData({
                studyPlanId: this.recordId,
                studyPlanData: JSON.stringify(this.studyPlanData),
                studyPathwayArray: this.selectedPathwayIdsArray,
                studyPlanOptionArray: this.selectedPlanOptionIdsArray,
                includeExistingStudyPlanUnitRequirements: this.includeExistingStudyPlanUnitRequirements,
                cloneChildStudyPlans: this.cloneChildStudyPlans
            })
            .then(result => {
                if (!result.isSuccess || !result.responseData) {
                    if (result.message) {
                        promptError(this.label.ERROR_LABEL, result.message);
                    } else {
                        promptError(this.label.ERROR_LABEL, this.label.UNKNOWN_EXCEPTIONS_LABEL);
                    }
                    this.toggleSpinner(-1);
                }
            })
            .catch(error => {
                promptError(this.label.ERROR_LABEL, getErrorMessage(error));
                this.toggleSpinner(-1);
                
            })            
        } catch (error) {
            this.toggleSpinner(-1);
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
        }
    }

    //Subscribe to platform event
    subscription = {};

    registerErrorListener() {
        // Invoke onError empApi method
        onError(error => {
            console.error('Received error from server: ' + JSON.stringify(error));
            // Error contains the server-side error
        });
    }

    // Handles subscribe button click
    handleSubscribe() {
        // Callback invoked whenever a new event message is received
        const messageCallback = (response) => {
            this.handleResponse(response);
        }

        // Invoke subscribe method of empApi. Pass reference to messageCallback
        subscribe('/event/reduivy__Operation_Channel__e', -1, messageCallback).then(response => {
            // Response contains the subscription information on subscribe call
            this.consoleLog('Subscription request sent to: ' + JSON.stringify(response.channel));
            this.subscription = response;
        });
    }

    // Handles unsubscribe button click
    handleUnsubscribe() {

        // Invoke unsubscribe method of empApi
        unsubscribe(this.subscription, response => {
            this.consoleLog('unsubscribe() response: ' + JSON.stringify(response));
            // Response is true for successful unsubscribe
        });
    }

    handleResponse(response){
        this.consoleLog('New message received: ' + JSON.stringify(response));

        // Response contains the payload of the new message received
        if(response && response.data && response?.data?.payload){
            let optType = response?.data?.payload?.reduivy__Operation_Type__c;

            if(optType === 'StudyPlanCloning'){
                let resourceId = response?.data?.payload?.reduivy__Resource_ID__c;

                if (resourceId == this.recordId) {
                    let optStatus = response?.data?.payload?.reduivy__Status__c;

                    if(optStatus === 'Completed'){
                        this.toggleSpinner(-1);
                        
                        let clonedStudyPlan = JSON.parse(response?.data?.payload?.reduivy__Message__c);
                        this.newClonedStudyPlanId = clonedStudyPlan.Id;

                        this.doPostCloning();
                    } else {
                        //TODO we may prompt error in the future
                        promptError(this.label.ERROR_LABEL, response?.data?.payload?.reduivy__Message__c);
                    }
                }
            }
        }
    }

    doPostCloning() {
        this.closeQuickAction()
        promptSuccess(this.label.SUCCESS_LABEL, this.cloningSuccessLabel);

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.newClonedStudyPlanId,
                actionName: 'view'
            }
        });
    }

    /**
     * @description Method to close the study plan clone wizard quick action
     */
    closeStudyPlanAction() {
        this.closeQuickAction();
    }

    /**
     * @description Close quick action
     */
    closeQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
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
        logInfo('SplStudyPlanCloning', anything, this.enableDebugMode, isJson);
    }
	
}