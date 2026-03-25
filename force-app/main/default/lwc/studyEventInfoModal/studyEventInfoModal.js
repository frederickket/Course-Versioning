/**
 * @author      WDCi (Sueanne)
 * @date        Aug 2024
 * @group       Contact Calendar
 * @description contact calendar event info modal
 * @changehistory
 * ISS-001925 02-08-2024 Sueanne - new component
 * ISS-002736 25-11-2025 XiRouh - Added tableTextDisplayMode configurable attribute
 * ISS-002779 21-01-2026 Lean - Make table header to respect tableTextDisplayMode
 */
import { api, wire, track } from 'lwc';
import { promptError } from 'c/toasterUtil';
import LightningModal from 'lightning/modal';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';
import { isWrapTextEnabled, getTableHeaderDisplayMode } from 'c/lwcUtil';

//labels
import { customLabels } from 'c/labelLoader';
import { sessionSchedulerConstants, sessionSchedulerLabels } from 'c/studySessionSchedulerHelper';
import ctrlGetTranslationFieldForNameByObjPrefix from '@salesforce/apex/REDU_Translation_LCTRL.getTranslationFieldForNameByObjPrefix';

const OBJ_TRANSLATION = [
    "FAC"
];

export default class studyEventInfoModal extends LightningModal {
	
	//configurable attributes
    @api modalTitle;
    @api studySessionInfoFields;
    @api studySessionTimeInfoFields;
    @api studyEventInfoFields;
    @api studySessionId;
    @api studySessionTimeId;
    @api studyEvent;
	@api enableDebugMode = false;
	
	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false;
	loadedLists = 0;

    @track objectTranslatedNameResult;
    @track objectTranslatedNameResponse;

    @api tableTextDisplayMode;
	
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
     * @description Get Faculty and Facility Translation
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
     * @description return the study event translation field for name
     */
    get facNameTranslationField() {
        return this.objectTranslatedNameResponse?.FAC;
    }
    /**
     * @description Return loading label
     */
    get loadingLabel() {
        return customLabels.LOADING_LABEL;
    }

    /**
     * @description Return close label
     */
    get closeLabel() {
        return customLabels.CLOSE_LABEL;
    }

    /**
    * @description Handle cancel click to close the modal
    * @param {*} event 
    */
    handleClose(event){
        this.close();
    }

    /**
     * @description Return a list of study session fields
     */
    get studySessionFields(){
        if (this.studySessionInfoFields) {
            return this.studySessionInfoFields.split(';');
        }

        return [];
    }

    /**
     * @description Return a list of study session time fields
     */
    get studySessionTimeFields(){
        if (this.studySessionTimeInfoFields) {
            return this.studySessionTimeInfoFields.split(';');
        }

        return [];
    }

    /**
     * @description Return a list of study event fields
     */
    get studyEventFields() {
        if (this.studyEventInfoFields) {
            return this.studyEventInfoFields.split(';');
        }

        return [];
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
     * @description get facility data table
     */
    get facilityDatatable() {
        let result = {};
        result.columns = [{label: sessionSchedulerLabels.FACILITY_LABEL, fieldName: 'Name', hideDefaultActions:"true", wrapText: this.enableWrapText}];
        result.data = [];

        if(this.studyEvent?.reduivy__Study_Event_Relations__r?.records){
            for(let ser of this.studyEvent?.reduivy__Study_Event_Relations__r?.records){
                
                if(ser.reduivy__Relation_Type__c === sessionSchedulerConstants.FACILITY){
                    let facName = '';
                    if(ser.reduivy__Facility__r && Object.hasOwn(ser.reduivy__Facility__r, this.facNameTranslationField)){
                        facName = ser.reduivy__Facility__r[this.facNameTranslationField];
                    }
                    
                    if(!facName) {
                        facName = ser.reduivy__Facility__r.Name;
                    }
                    result.data.push({Name:facName});
                } 
            }
        }

        return result;
    }

    /**
     * @description get faculty data table
     */
    get facultyDatatable() {
        let result = {};
        result.columns = [{label: sessionSchedulerLabels.FACULTY_LABEL, fieldName: 'Name', hideDefaultActions:"true", wrapText: this.enableWrapText}];
        result.data = [];

        if(this.studyEvent?.reduivy__Study_Event_Relations__r?.records){
            for(let ser of this.studyEvent?.reduivy__Study_Event_Relations__r?.records){
                if(ser.reduivy__Relation_Type__c === sessionSchedulerConstants.FACULTY){
                    result.data.push({Name:ser.reduivy__Contact__r.Name});
                }
            }
        }

        return result;
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
        logInfo('StudyEventInfoModal', anything, this.enableDebugMode, isJson);
    }
	
}