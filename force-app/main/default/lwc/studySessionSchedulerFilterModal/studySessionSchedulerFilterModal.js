/**
 * @author      WDCi (Lean)
 * @date        Jun 2024
 * @group       Study Session Scheduler
 * @description Study session scheduler filter modal
 * @changehistory
 * ISS-001920 11-06-2024 Lean - new class
 * ISS-002188 13-12-2024 XW - replaced modal with panel to improve usability
 */
import { api, wire, track, LightningElement } from 'lwc';
import { promptError } from 'c/toasterUtil';
import { getErrorMessage, logInfo } from 'c/loggingUtil';
import { setupPicklistOptionsFromRecords } from 'c/lwcUtil';
import { sessionSchedulerLabels } from 'c/studySessionSchedulerHelper';

import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import CON_OBJECT from '@salesforce/schema/Contact';
import FAC_OBJECT from '@salesforce/schema/Facility__c';
import SSE_OBJECT from '@salesforce/schema/Study_Session__c';
import SUN_OBJECT from '@salesforce/schema/Study_Unit__c';
import SOF_OBJECT from '@salesforce/schema/Study_Offering__c';

//Apex methods
import ctrlGetEducationalInstitutions from '@salesforce/apex/REDU_SessionScheduler_LCTRL.getEducationalInstitutions';
import ctrlGetCampuses from '@salesforce/apex/REDU_SessionScheduler_LCTRL.getCampuses';
import ctrlGetStudyUnits from '@salesforce/apex/REDU_SessionScheduler_LCTRL.getStudyUnits';
import ctrlGetAcademicTerms from '@salesforce/apex/REDU_SessionScheduler_LCTRL.getAcademicTerms';
import ctrlGetStudyOfferings from '@salesforce/apex/REDU_SessionScheduler_LCTRL.getStudyOfferings';

export default class StudySessionSchedulerFilterModal extends LightningElement {
	
	//configurable attributes
    @api defaultFilterValues;
    @api defaultGroupByValues;
    @api contactFilterFields;
    @api facilityFilterFields;
    @api studySessionFilterFields;
    @api studySessionGroupByFields;
	@api enableDebugMode = false;
    @api showFilterPanel; //ISS-002188
	
	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false;
	loadedLists = 0;
	
    //wire attribute
    educationalInstitutionWireResult;
    educationalInstitutionResponse;
    campusWireResult;
    campusResponse;
    studyUnitWireResult;
    studyUnitResponse;
    academicTermWireResult;
    academicTermResponse;
    studyOfferingWireResult;
    studyOfferingResponse;

    //filter value
    @track _filterValues = {};
    @track _groupByValues = [];
    
    @track educationalInstitutionOptions = [];
    @track campusOptions = [];
    @track studyUnitOptions = [];
    @track academicTermOptions = [];
    @track studyOfferingOptions = [];

    @track educationalInstitutionId = '';
    @track studyUnitId = '';
    @track academicTermId = '';
    @track studyOfferingId = '';
    @track campusId = '';

    groupByField1;
    groupByField2;
    groupByField3;
	

	//js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'tooltips'
    modules = [];
	
    //wired object
    @wire(getObjectInfo, {objectApiName: SSE_OBJECT})
    sseObjInfo;

    @wire(getObjectInfo, {objectApiName: CON_OBJECT})
    conObjInfo;

    @wire(getObjectInfo, {objectApiName: FAC_OBJECT})
    facObjInfo;

    @wire(getObjectInfo, {objectApiName: SUN_OBJECT})
    sunObjInfo;

    @wire(getObjectInfo, {objectApiName: SOF_OBJECT})
    sofObjInfo;

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
     * @descripton rendered callback
     */
	renderedCallback(){

    }

    /**
     * @descripton connected callback
     */
    connectedCallback(){
        this.consoleLog('connectedCallback');

        this.mapFilterValuesToPanel();
        this.mapGroupValuesToPanel();

	}

    /** ISS-002188
     * Initialize the filter values to the panel
     */
    mapFilterValuesToPanel(){
		if (this.defaultFilterValues) {
            this._filterValues = JSON.parse(JSON.stringify(this.defaultFilterValues));
            this.consoleLog(this._filterValues, true);

            for (const [key, value] of Object.entries(this._filterValues)) {
                this[key] = value;
            }
        }
    }

    /** ISS-002188
     * Initialize the group values to the panel
     */
    mapGroupValuesToPanel(){
        if (this.defaultGroupByValues) {
            this._groupByValues = JSON.parse(JSON.stringify(this.defaultGroupByValues));
            this.consoleLog(this._groupByValues, true);

            if (this.defaultGroupByValues.length >= 1) {
                this.groupByField1 = this.defaultGroupByValues[0];
            }

            if (this.defaultGroupByValues.length >= 2) {
                this.groupByField2 = this.defaultGroupByValues[1];
            }

            if (this.defaultGroupByValues.length >= 3) {
                this.groupByField3 = this.defaultGroupByValues[2];
            }
        }
    }
	
    /**
     * @descripton disconnected callback
     */
	disconnectedCallback() {
		
	}

    get modalTitle() {
        return sessionSchedulerLabels.FILTER_LABEL;
    }

    /**
     * @description Return loading label
     */
    get loadingLabel() {
        return sessionSchedulerLabels.LOADING_LABEL;
    }

    /**
     * @description Return clear label
     */
    get clearButtonLabel() {
        return sessionSchedulerLabels.CLEAR_LABEL;
    }

    /**
     * @description Return apply label
     */
    get applyButtonLabel() {
        return sessionSchedulerLabels.APPLY_LABEL;
    }

    /**
     * @description Return contact label
     */
    get contactLabel() {
        return this.conObjInfo?.data?.label;
    }

    /**
     * @description Return facility label
     */
    get facilityLabel() {
        return this.facObjInfo?.data?.label;
    }

    /**
     * @description Return study unit label
     */
    get sunLabel() {
        return this.sunObjInfo?.data?.label;
    }

    /**
     * @description Return study unit label
     */
    get sofLabel() {
        return this.sofObjInfo?.data?.label;
    }

    /**
     * @description Return study session label
     */
    get sseLabel() {
        return this.sseObjInfo?.data?.label;
    }

    /**
     * @description Return educational institution label
     */
    get educationalInstitutionLabel() {
        return sessionSchedulerLabels.EDUCATIONAL_INSTITUTION_LABEL;
    }

    get campusLabel() {
        return sessionSchedulerLabels.CAMPUS_LABEL;
    }

    /**
     * @description Return academic term label
     */
    get academicTermLabel() {
        return sessionSchedulerLabels.ACADEMICTERM_LABEL;
    }

    /**
     * @description Return group by label
     */
    get groupByLabel() {
        return sessionSchedulerLabels.GROUPBY_LABEL;
    }

    /**
     * @description Return group by field 1 label
     */
    get groupByField1Label() {
        return sessionSchedulerLabels.GROUPBY_FIELD_1_LABEL;
    }

    /**
     * @description Return group by field 2 label
     */
    get groupByField2Label() {
        return sessionSchedulerLabels.GROUPBY_FIELD_2_LABEL;
    }

    /**
     * @description Return group by field 3 label
     */
    get groupByField3Label() {
        return sessionSchedulerLabels.GROUPBY_FIELD_3_LABEL;
    }

    /**
     * @description Return contact filter config
     * @return Array
     */
    get contactCustomFilterConfigs() {

        if (this._filterValues.contactFilter) {
            return JSON.stringify(this._filterValues.contactFilter);
        }

        let configs = this.generateCustomFilterConfigsForObject(this.contactFilterFields, this.conObjInfo);
        if (configs && configs.length > 0) {
            return JSON.stringify(configs);
        }

        return null;
    }

    /**
     * @description Return session filter config
     * @return Array
     */
    get studySessionCustomFilterConfigs() {

        if (this._filterValues.sessionFilter) {
            return JSON.stringify(this._filterValues.sessionFilter);
        }

        let configs = this.generateCustomFilterConfigsForObject(this.studySessionFilterFields, this.sseObjInfo);
        if (configs && configs.length > 0) {
            return JSON.stringify(configs);
        }

        return null;
    }

    /**
     * @description Return facility filter config
     * @return Array
     */
    get facilityCustomFilterConfigs() {

        if (this._filterValues.facilityFilter) {
            return JSON.stringify(this._filterValues.facilityFilter);
        }

        let configs = this.generateCustomFilterConfigsForObject(this.facilityFilterFields, this.facObjInfo);
        if (configs && configs.length > 0) {
            return JSON.stringify(configs);
        }

        return null;
    }

    /**
     * @description Generate custom filter configs
     * @return Array
     */
    generateCustomFilterConfigsForObject(filterFields, objInfo) {

        let configs = [];

        if (filterFields && objInfo?.data?.fields) {
            let fieldsMap = objInfo.data.fields;
            let counter = 1;
            for (let field of filterFields.split(';')) {
                if (Object.hasOwn(fieldsMap, field)) {
                    let config = {
                        seq: counter,
                        showFilter: true,
                        label: fieldsMap[field].label,
                        mapping: field + '=' + field
                    }
                    
                    configs.push(config);

                    counter ++;
                }
            }
        }

        return configs;
    }

    /**
     * @description Wire method to get educational institutions
     */
    @wire(ctrlGetEducationalInstitutions, {
    })
    wireEducationalInstitutions(result) {
        
        this.educationalInstitutionWireResult = result;
        this.educationalInstitutionResponse = null;

        if (result.data) {
            this.educationalInstitutionResponse = JSON.parse(result.data.responseData);
            this.consoleLog(this.educationalInstitutionResponse, true);

            this.educationalInstitutionOptions = setupPicklistOptionsFromRecords(this.educationalInstitutionResponse, 'reduivy__Code__c');

        } else if (result.error) {
            promptError(sessionSchedulerLabels.ERROR_LABEL, getErrorMessage(result.error));
        }

    }

    /**
     * @description Wire method to get campuses
     */
    @wire(ctrlGetCampuses,{
        educationalInstitutionId: "$educationalInstitutionId"
    })
    wireCampuses(result){
        this.campusWireResult = result;
        this.campusResponse = null;

        if(result.data){
            this.campusResponse = JSON.parse(result.data.responseData);
            this.consoleLog(this.campusResponse, true);

            this.campusOptions = setupPicklistOptionsFromRecords(this.campusResponse, 'reduivy__Code__c');

        } else if (result.error){
            promptError(sessionSchedulerLabels.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    /**
     * @description Wire method to get study units
     */
    @wire(ctrlGetStudyUnits, {
        educationalInstitutionId: "$educationalInstitutionId"
    })
    wireStudyUnits(result) {
        
        this.studyUnitWireResult = result;
        this.studyUnitResponse = null;

        if (result.data) {
            this.studyUnitResponse = JSON.parse(result.data.responseData);
            this.consoleLog(this.studyUnitResponse, true);

            this.studyUnitOptions = setupPicklistOptionsFromRecords(this.studyUnitResponse, 'reduivy__Unit_Code__c');

        } else if (result.error) {
            promptError(sessionSchedulerLabels.ERROR_LABEL, getErrorMessage(result.error));
        }

    }

    /**
     * @description Wire method to get academic terms
     */
    @wire(ctrlGetAcademicTerms, {
        educationalInstitutionId: "$educationalInstitutionId"
    })
    wireAcademicTerms(result) {
        
        this.academicTermWireResult = result;
        this.academicTermResponse = null;

        if (result.data) {
            this.academicTermResponse = JSON.parse(result.data.responseData);
            this.consoleLog(this.academicTermResponse, true);

            this.academicTermOptions = setupPicklistOptionsFromRecords(this.academicTermResponse, 'reduivy__Academic_Year__r.Name');

        } else if (result.error) {
            promptError(sessionSchedulerLabels.ERROR_LABEL, getErrorMessage(result.error));
        }

    }

    /**
     * @description Wire method to get study offerings
     */
    @wire(ctrlGetStudyOfferings, {
        campusId: "$campusId",
        academicTermId: "$academicTermId",
        studyUnitId: "$studyUnitId",
    })
    wireStudyOfferings(result) {
        
        this.studyOfferingWireResult = result;
        this.studyOfferingResponse = null;

        if (result.data) {
            this.studyOfferingResponse = JSON.parse(result.data.responseData);
            this.consoleLog(this.studyOfferingResponse, true);

            this.studyOfferingOptions = setupPicklistOptionsFromRecords(this.studyOfferingResponse, 'reduivy__Code__c');

        } else if (result.error) {
            promptError(sessionSchedulerLabels.ERROR_LABEL, getErrorMessage(result.error));
        }

    }


    get groupByFieldOptions() {
        let options = [];
        
        if (this.studySessionGroupByFields && this.sseObjInfo && this.sseObjInfo.data) {
            let fieldsMap = this.sseObjInfo.data?.fields;

            for (let field of this.studySessionGroupByFields.split(';')) {
                if (Object.hasOwn(fieldsMap, field)) {
                    let value = field;
                    if (fieldsMap[field].dataType === "Reference"){
                        value = value.replace("__c", "__r.Name");
                    }
                    options.push({
                        label: fieldsMap[field].label,
                        value: value
                    })
                }
            }
        }

        return options;
    }

    /** ISS-002188
     * @description Handle clear to clear all the filter
     * @param {*} event 
     */
    handleClearClick() {
        this._filterValues = JSON.parse(JSON.stringify(this.defaultFilterValues));
        
        this.groupByField1 = "";
        this.groupByField2 = "";
        this.groupByField3 = "";

        this.educationalInstitutionId = "";
        this.studyUnitId = "";
        this.academicTermId = "";
        this.studyOfferingId = "";
        this.campusId = "";

        
        this._filterValues.educationalInstitutionId = this.educationalInstitutionId;
        this._filterValues.studyUnitId = this.studyUnitId;
        this._filterValues.academicTermId = this.academicTermId;
        this._filterValues.studyOfferingId = this.studyOfferingId;
        this._filterValues.campusId = this.campusId;
        
        for (let comboboxCmp of this.template.querySelectorAll('c-searchable-combobox')){
            comboboxCmp.changeValue(null);
        }

        for (let filterCmp of this.template.querySelectorAll('c-custom-filters')) {
            filterCmp.unsetSourceSobjField();
        }
    }

    /** ISS-002188
     * @description Handle apply to apply the changes
     * @param {*} event 
     */
    handleApplyClick() {

        this._groupByValues = [];
        if (this.groupByField1) {
            this._groupByValues.push(this.groupByField1);
        } 
        
        if (this.groupByField2) {
            this._groupByValues.push(this.groupByField2);
        } 
        
        if (this.groupByField3) {
            this._groupByValues.push(this.groupByField3);
        }

        this._filterValues.schedulingType = this.defaultFilterValues.schedulingType;

        this.dispatchEvent(new CustomEvent('confirm', {
            detail: {
                operation: 'submit',
                filterValues: JSON.parse(JSON.stringify(this._filterValues)),
                groupByValues: JSON.parse(JSON.stringify(this._groupByValues))
            },
        }));
    }

    /**
     * @description Handle filter update for study session
     * @param {*} event 
     */
    handleFiltersUpdateForStudySession(event) {
        this._filterValues.sessionFilter = event.detail.customFilters;
    }

    /**
     * @description Handle filter update for facility
     * @param {*} event 
     */
    handleFiltersUpdateForFacility(event) {
        this._filterValues.facilityFilter = event.detail.customFilters;
    }

    /**
     * @description Handle filter update for faculty
     * @param {*} event 
     */
    handleFiltersUpdateForContact(event) {
        this._filterValues.contactFilter = event.detail.customFilters;
    }

    /**
     * @description handle combobox changes
     */
    handleComboboxChange(event) {

        const { fieldName, fieldLabel, selectedOpt } = event.detail;

        if (fieldName) {
            let value = selectedOpt?.value;
            if(value === undefined) {
                value = '';
            }
            this._filterValues[fieldName] = value;
            this[fieldName] = value;
            
        }
    }

    /**
     * @description handle combobox changes
     */
    handleGroupByComboChange(event) {

        const { fieldName, selectedOpt } = event.detail;

        if (fieldName) {
            this[fieldName] = selectedOpt?.value;
        }
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
        logInfo('StudySessionSchedulerFilterModal', anything, this.enableDebugMode, isJson);
    }
	
}