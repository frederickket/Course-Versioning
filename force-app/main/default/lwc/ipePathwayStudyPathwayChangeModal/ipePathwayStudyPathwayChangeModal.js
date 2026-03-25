/**
 * @Author 		WDCi (Lean)
 * @Date 		Jan 2026
 * @group 		Enrollment Wizard
 * @Description Study Pathway change modal for enrollment wizard
 * @changehistory
 * ISS-002740 13-01-2026 Lean - New component
 */

import {api, wire, track } from 'lwc';
import LightningModal from 'lightning/modal';

import { getRecord, getFieldValue, updateRecord, notifyRecordUpdateAvailable } from "lightning/uiRecordApi";
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';

import { getErrorMessage, logInfo } from 'c/loggingUtil';
import { promptError, promptSuccess } from 'c/toasterUtil';
import { customLabels } from 'c/labelLoader';

import ctrlGetTranslationFieldForNameByObjPrefix from '@salesforce/apex/REDU_Translation_LCTRL.getTranslationFieldForNameByObjPrefix';

import CHANGE_PATHWAY_LABEL from '@salesforce/label/c.Change_Pathway';
import SELECT_ONE_PATHWAY_LABEL from '@salesforce/label/c.Change_Pathway_Select_One_Pathway';
import NO_PATHWAY_AVAILABLE_LABEL from '@salesforce/label/c.Change_Pathway_No_Pathway_Available';

//wire attributes for querying individual program enrollment
const IPE_FIELDS = [
    "reduivy__Individual_Program_Enrollment__c.Id",
    "reduivy__Individual_Program_Enrollment__c.reduivy__Study_Plan__c",
    "reduivy__Individual_Program_Enrollment__c.reduivy__Study_Pathway__c"
];

const SPW_FIELDS = [
    "reduivy__Study_Pathway__c.Id",
    "reduivy__Study_Pathway__c.Name",
    "reduivy__Study_Pathway__c.reduivy__Study_Mode__c"
];

const OBJ_TRANSLATION = [
    "SPW"
];

export default class IpePathwayStudyPathwayChangeModal extends LightningModal {

    @api masterIpeId;
    @api studyPathwayInfoFields;
    
    @api enableDebugMode = false;

    //internal attributes
    isScriptLoaded = false;
	isInitSuccess = false
	loadedLists = 0;

    selectedStudyPathwayId;

    //wire attributes
    @track masterIpeWireResult;
    @track masterIpeRecord;

    @track spwListResult;
    @track spwListResponse;

    @track objectTranslatedNameResult;
    @track objectTranslatedNameResponse;

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
     * @description Get individual program enrollment record
     */
    @wire(getRecord, { recordId: "$masterIpeId", fields: IPE_FIELDS })
    wiredMasterIpeRecord(result) {
        
        this.masterIpeWireResult = result;
        this.masterIpeRecord = null;

        if (result.data) {
            this.masterIpeRecord = result.data;
            this.consoleLog(this.masterIpeRecord, true);
            
        } else if (result.error) {
            promptError(customLabels.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    /**
     * @description Get Study Plan Translation
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

    /** ISS-002740
     * @description get related study pathway records by study plan id
     */
    @wire(getRelatedListRecords, {
        parentRecordId: '$masterIpeStudyPlanId',
        relatedListId: 'reduivy__Study_Pathways__r',
        fields: '$studyPathwayFieldsWithTranslationName',
        where: '$studyPathwayFilter',
        sortBy: ['reduivy__Study_Pathway__c.Name']
    })
    wiredStudyPathways(result) {
        this.spwListResult = result;
        if(result.data){
            this.spwListResponse = result.data;

            this.consoleLog('wiredStudyPathways');
            this.consoleLog(this.spwListResponse, true);
        } else if (result.error){
            promptError(customLabels.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    /**
     * @description ISS-002740 Return study pathway fields with translation
     */
    get studyPathwayFieldsWithTranslationName(){
        let fields = SPW_FIELDS;
        if(this.spwNameTranslationField) {
            fields.push('reduivy__Study_Pathway__c.' + this.spwNameTranslationField);
        }
        return fields;
    }

    /** ISS-002189
     * @description ISS-002740 Return study pathway query filter
     */
    get studyPathwayFilter(){
        let filter = {};

        if (this.masterIpeStudyPathwayId) {

            let currentSpwIdToSkip = this.masterIpeStudyPathwayId;
            let status = 'Active';
            filter.and = [];
            filter.and.push({'Id': {ne: currentSpwIdToSkip}});
            filter.and.push({'reduivy__Status__c': {eq: status}});
        }
        
        this.consoleLog('studyPathwayFilter');
        this.consoleLog(filter, true);

        return JSON.stringify(filter);
    }

    /**
     * @description handle close
     */
    handleCloseClick() {
        this.close('close');
    }

    /**
     * @description Handle apply button click
     */
    handleApplyClick() {

        try {
            
            let recordObj = {
                fields: {
                    Id: this.masterIpeId,
                    reduivy__Study_Pathway__c: this.selectedStudyPathwayId,
                }
            };

            let selectedSpws = this.studyPathwayOptions.filter(spw => spw.Id === this.selectedStudyPathwayId);
            let studyMode = (selectedSpws ? selectedSpws[0]?.reduivy__Study_Mode__c : null);

            if (studyMode) {
                recordObj.fields.reduivy__Study_Mode__c = studyMode;
            } 

            this.toggleSpinner(1);

            updateRecord(recordObj)
            .then(() => {
                promptSuccess(customLabels.SUCCESS_LABEL, customLabels.RECORD_SAVED_LABEL);
                
                //notify lightning data service
                notifyRecordUpdateAvailable([{recordId: this.masterIpeId}]);

                this.close({
                    operation: 'confirmed',
                    studyPathwayId: this.selectedStudyPathwayId
                });

                this.toggleSpinner(-1);
            })
            .catch((error) => {
                this.toggleSpinner(-1);

                this.consoleLog(error);
                promptError(customLabels.ERROR_LABEL, getErrorMessage(error));
            });

        } catch (error) {
            this.toggleSpinner(-1);
            promptError(customLabels.ERROR_LABEL, getErrorMessage(error));
        }
    }

    handlePathwayOnSelect(event){
        this.consoleLog('handlePathwayOnSelect');
        this.consoleLog(event.target.value);

        this.selectedStudyPathwayId = event.target.value;
    }

    /**
     * @description Return modal title
     */
    get headerLabel() {
        return CHANGE_PATHWAY_LABEL;
    }

    /**
     * @description Cancel button label
     */
    get cancelButtonLabel() {
        return customLabels.CANCEL_LABEL;
    }

    /**
     * @description Apply button label
     */
    get applyButtonLabel() {
        return customLabels.APPLY_LABEL;
    }

    /**
     * @description Return the study plan id for the master ipe
     */
    get masterIpeStudyPlanId() {
        if (this.masterIpeRecord) {
            return getFieldValue(this.masterIpeRecord, 'reduivy__Individual_Program_Enrollment__c.reduivy__Study_Plan__c');
        }

        return null;
    }

    /**
     * @description Return the study pathway id for the master ipe
     */
    get masterIpeStudyPathwayId() {
        if (this.masterIpeRecord) {
            return getFieldValue(this.masterIpeRecord, 'reduivy__Individual_Program_Enrollment__c.reduivy__Study_Pathway__c');
        }

        return null;
    }

    /**
     * @description return the study pathway translation field for name
     */
    get spwNameTranslationField() {
        return this.objectTranslatedNameResponse?.SPW;
    }

    /**
     * @description Return true if there is other study pathway available for selection
     */
    get hasStudyPathways() {
        if (this.spwListResponse?.records && this.spwListResponse?.records?.length > 0) {
            return true;
        }

        return false;
    }

    /**
     * @description Return list of study pathways
     */
    get studyPathwayOptions() {
        
        let options = [];
        if (this.hasStudyPathways) {
            options = this.spwListResponse?.records?.map(spw => {
                return {
                    Id: getFieldValue(spw, 'reduivy__Study_Pathway__c.Id'),
                    reduivy__Study_Mode__c: getFieldValue(spw, 'reduivy__Study_Pathway__c.reduivy__Study_Mode__c')
                };
            });
        }

        return options;
    }

    /**
     * @description Return true to make all button disabled
     */
    get isButtonDisabled() {
        return this.isLoading;
    }

    /**
     * @description Return true to make the apply button disabled
     */
    get isApplyDisabled() {
        return !(this.hasStudyPathways && this.selectedStudyPathwayId) || this.isButtonDisabled;
    }

    /**
     * @description Return description text
     */
    get descriptionText() {
        return SELECT_ONE_PATHWAY_LABEL;
    }

    /**
     * @description Return no study pathway available text
     */
    get noAvailableStudyPathwayText() {
        return NO_PATHWAY_AVAILABLE_LABEL;
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
        logInfo('ipePathwayStudyPathwayChangeModal', anything, this.enableDebugMode, isJson);
    }
}