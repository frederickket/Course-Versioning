/**
 * @author      WDCi (Lean)
 * @date        Jun 2024
 * @group       Study Session Scheduler
 * @description Study session scheduler session edit modal
 * @changehistory
 * ISS-001920 11-06-2024 Lean - new class
 * ISS-002263 12-03-2025 XW - gete eduinst start and end time, and pass it to timeedit
 * ISS-002654 03-10-2025 Lean - Column number shared util
 */
import { api, wire, track } from 'lwc';
import LightningModal from 'lightning/modal';
import { promptError } from 'c/toasterUtil';
import { getErrorMessage, logInfo } from 'c/loggingUtil';
import { setupPicklistOptionsFromRecords, getFormDataFieldOnChangeValue, getColumnSize } from 'c/lwcUtil';
import { sessionSchedulerLabels } from 'c/studySessionSchedulerHelper';

import { getObjectInfo } from 'lightning/uiObjectInfoApi';

import SSE_OBJECT from '@salesforce/schema/Study_Session__c';
import SST_OBJECT from '@salesforce/schema/Study_Session_Time__c';
import SUN_OBJECT from '@salesforce/schema/Study_Unit__c';
import SOF_OBJECT from '@salesforce/schema/Study_Offering__c';

import { getRecord } from "lightning/uiRecordApi";

//wire attributes for querying individual pathway using getRecord
const SOF_FIELDS = [
    "reduivy__Study_Offering__c.Id",
    "reduivy__Study_Offering__c.reduivy__Campus__c",
    "reduivy__Study_Offering__c.reduivy__Campus__r.Parent.reduivy__Start_Time__c",
    "reduivy__Study_Offering__c.reduivy__Campus__r.Parent.reduivy__End_Time__c",
    "reduivy__Study_Offering__c.reduivy__Start_Date_Calculated__c",
    "reduivy__Study_Offering__c.reduivy__End_Date_Calculated__c"
];

//Apex methods
import ctrlGetFields from '@salesforce/apex/REDU_SessionSchedulerSessionEdit_LCTRL.getFields';
import ctrlGetEducationalInstitutions from '@salesforce/apex/REDU_SessionScheduler_LCTRL.getEducationalInstitutions';
import ctrlGetStudyUnits from '@salesforce/apex/REDU_SessionScheduler_LCTRL.getStudyUnits';
import ctrlGetAcademicTerms from '@salesforce/apex/REDU_SessionScheduler_LCTRL.getAcademicTerms';
import ctrlGetStudyOfferings from '@salesforce/apex/REDU_SessionScheduler_LCTRL.getStudyOfferings';
import ctrlUpsertSessionsAndSessionTimes from '@salesforce/apex/REDU_SessionSchedulerSessionEdit_LCTRL.upsertSessionsAndSessionTimes';
import ctrlGenerateStudyEvent from '@salesforce/apex/REDU_SessionSchedulerSessionEdit_LCTRL.generateStudyEvent';


//import ctrlGetEditSseData from '@salesforce/apex/REDU_SessionScheduler_LCTRL.getEditSseData';


export default class StudySessionSchedulerSessionEditModal extends LightningModal {
	
	//configurable attributes
    @api modalTitle;
    
    /**
     * @description To make the object reactive to changes from parent
     */
    @api
    set sseObj(val) {
        this._sseObj = JSON.parse(JSON.stringify(val));
    }

    get sseObj() {
        if (this._sseObj) {
            return this._sseObj;
        }

        this._sseObj = {};
        return this._sseObj;
    }

    @api facilityDefaultCriteria;
    @api allowCrossCampusFacilityAllocation = false;
    @api studySessionFieldSetName;
    @api studySessionTimeFieldSetName;
    @api sseColumnNo;
    @api sstColumnNo;
    @api accordionBackgroundColor;
    @api accordionTextColor;
    @api accordionButtonVariant;
    
    @api timelineMinTime;
    @api timelineMaxTime;

	@api enableDebugMode = false;
	
	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false;
	loadedLists = 0;
		
    @track _sseObj;
    _sseFieldsData;
    _sstFieldsData;

    //sst obj to delete
    sstToDelete = [];

    //combobox options
    @track educationalInstitutionOptions = [];
    @track studyUnitOptions = [];
    @track academicTermOptions = [];
    @track studyOfferingOptions = [];

    //selected values
    educationalInstitutionId;
    studyUnitId;
    academicTermId;
    studyOfferingId;
    recordTypeId;
    doneNewStudySessionSelection = false;

    //wire attribute
    sseFieldsResponse;
    sseFieldsResult;
    sstFieldsResponse;
    sstFieldsResult;
    educationalInstitutionWireResult;
    educationalInstitutionResponse;
    studyUnitWireResult;
    studyUnitResponse;
    academicTermWireResult;
    academicTermResponse;
    studyOfferingWireResult;
    studyOfferingResponse;
    sofRecordWireResult;
    sofRecordResponse;

	//js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'tooltips'
    modules = ['stringutil'];

    //wired object
    @wire(getObjectInfo, {objectApiName: SSE_OBJECT})
    sseObjInfo;

    @wire(getObjectInfo, {objectApiName: SST_OBJECT})
    sstObjInfo;

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
     * @description Return modal header
     */
    get headerLabel() {
        return this.modalTitle;
    }

    /**
     * @description study session column size
     */
    get sseColumnSize(){
        return getColumnSize(this.sseColumnNo, 2);
    }

    /**
     * @description Return save label
     */
    get saveButtonLabel() {
        return sessionSchedulerLabels.SAVE_LABEL;
    }

    /**
     * @description Return save and update schedules label
     */
    get saveAndUpdateSchedulesButtonLabel() {
        return sessionSchedulerLabels.SAVE_AND_UPDATE_LABEL;
    }

    /**
     * @description Return cancel label
     */
    get cancelButtonLabel() {
        return sessionSchedulerLabels.CANCEL_LABEL;
    }

    /**
     * @description Return next label
     */
    get nextButtonLabel() {
        return sessionSchedulerLabels.NEXT_LABEL;
    }

    /**
     * @description Return study session time plural label
     */
    get studySessionTimePluralLabel() {
        return this.sstObjInfo?.data?.labelPlural;
    }

    /**
     * @description Return study session time label
     */
    get studySessionTimeLabel() {
        return this.sstObjInfo?.data?.label;
    }

    /**
     * @description Return new study session time label
     */
    get newStudySessionTimeLabel() {
        if (this.studySessionTimeLabel) {
            return sessionSchedulerLabels.NEW_RECORD_LABEL.format([this.studySessionTimeLabel]);
        }
        return null;
    }

    /**
     * @description Return educational institution label
     */
    get educationalInstitutionLabel() {
        return sessionSchedulerLabels.EDUCATIONAL_INSTITUTION_LABEL;
    }

    /**
     * @description Return academic term label
     */
    get academicTermLabel() {
        return sessionSchedulerLabels.ACADEMICTERM_LABEL;
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
     * @description Return true for new record
     */
    get isNew() {
        return this.sseObj?.Id ? false : true;
    }

    get studySessionId(){
        return this.sseObj?.Id
    }

    /**
     * @description Return record type picklist options
     */
    get recordTypeOptions() {

        let options = [];

        if (this.sseObjInfo.data) {
            let recordTypeInfos = this.sseObjInfo.data.recordTypeInfos;
            this.consoleLog('recordTypeOptions');
            this.consoleLog(recordTypeInfos, true);

            Object.keys(recordTypeInfos).forEach(rtId => {
                let rtObj = recordTypeInfos[rtId];

                if (rtObj.available && !rtObj.master) {
                    options.push({label: rtObj.name, value: rtObj.recordTypeId});
                }
            });
        }

        return options;
    }

    /**
     * @description Return true if needs to prompt record type selection for new record
     */
    get showRecordTypeSelection() {
        this.consoleLog('showRecordTypeSelection');
        this.consoleLog(this.recordTypeOptions);

        if (this.recordTypeOptions && this.recordTypeOptions.length > 0) {
            return true;
        }

        return false;
    }

    /**
     * @description Return true if needs to prompt record type selection for new record
     */
    get showNewRecordSelection() {
        this.consoleLog('showNewRecordSelection');
        this.consoleLog(this.isNew);

        return this.isNew && !this.doneNewStudySessionSelection;
    }

    /**
     * @description Return record type id for the record-edit-form
     */
    get finalRecordTypeId() {
        return this.recordTypeId ? this.recordTypeId : this.sseObj?.data?.defaultRecordTypeId;
    }

    /**
     * @description Return new study session label
     */
    get newStudySessionLabel() {
        if (this.sseObjInfo.data) {
            return sessionSchedulerLabels.NEW_RECORD_LABEL.format([this.sseObjInfo.data.label]);
        }

        return null;
    }

    /**
     * @description Return true to show next button
     */
    get showNextButton() {
        return this.showNewRecordSelection;
    }

    /**
     * @description Set study session fields
     */
    set sseFieldsData(val) {
        this._sseFieldsData = JSON.parse(JSON.stringify(val));
    }

    /**
     * @description Return study session fields
     */
    get sseFieldsData() {
        return this._sseFieldsData;
    }

    /**
     * @description Set study session time fields
     */
    set sstFieldsData(val) {
        this._sstFieldsData = JSON.parse(JSON.stringify(val));
    }

    /**
     * @description Return study session time fields
     */
    get sstFieldsData() {
        return this._sstFieldsData;
    }

    /**
     * @description Return list of study session times
     */
    get studySessionTimes() {
        return this.sseObj?.reduivy__Study_Session_Times__r;
    }

    /**
     * @description Return study offering id from the study session
     */
    get sseStudyOfferingId() {
        return this.sseObj?.reduivy__Study_Offering__c;
    }

    /**
     * @description Return session's required facility type
     */
    get sseRequiredFacilityType() {
        return this.sseObj?.reduivy__Required_Facility_Type__c;
    }

    /**
     * @description Return study offering campus id
     */
    get sofCampusId() {
        return this.sofRecordResponse?.fields.reduivy__Campus__c.value;
    }

    /**
     * @description Return study offering start date
     */
    get sofStartDate() {
        return this.sofRecordResponse?.fields.reduivy__Start_Date_Calculated__c.value;
    }

    /**
     * @description Return study offering end date
     */
    get sofEndDate() {
        return this.sofRecordResponse?.fields.reduivy__End_Date_Calculated__c.value;
    }

    /**
     * @description Return list of fields for record edit form to avoid error during loading
     */
    get sseOptionalFields(){
        return this.sseFieldsData.map(item => item.fieldName);
    }

    /**
     * @description Return missing data error
     */
    get missingInfoErrorText() {
        return sessionSchedulerLabels.MISSING_INFO_ERROR_LABEL.format([this.studySessionTimeLabel]);
    }

    /**
     * @description the selected educational institution start time
     */
    get eduInstStartTime() {
        return this.sofRecordResponse?.fields?.reduivy__Campus__r?.value?.fields?.Parent?.value?.fields?.reduivy__Start_Time__c?.value;
    }

    /**
     * @description the selected educational institution start time
     */
    get eduInstEndTime() {
        return this.sofRecordResponse?.fields?.reduivy__Campus__r?.value?.fields?.Parent?.value?.fields?.reduivy__End_Time__c?.value;
    }

    /**
     * @description Get study offering record
     */
    @wire(getRecord, { recordId: "$sseStudyOfferingId", fields: SOF_FIELDS })
    wiredRecord(result) {
        
        this.sofRecordWireResult = result;
        this.sofRecordResponse = null;

        if (result.data) {
            this.sofRecordResponse = result.data;
            this.consoleLog(this.sofRecordResponse, true);
            
        } else if (result.error) {
            promptError(sessionSchedulerLabels.ERROR_LABEL, getErrorMessage(result.error));
        }

    }

    /**
     * @description Get Study Session fields set
     */
    @wire(ctrlGetFields, {
        fieldSetName: '$studySessionFieldSetName',
        objectName: '$sseObjInfo.data.apiName'
    })
    wiredSseFields(result) {
        this.sseFieldsResult = result;
        this.sseFieldsResponse = null;

        if (result.data) {
            this.sseFieldsResponse = JSON.parse(result.data.responseData);
            this.sseFieldsData = this.sseFieldsResponse;
            this.consoleLog(this.sseFieldsResponse, true);
        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }

    }

    /**
     * @description Get Study Session Time fields set
     */
    @wire(ctrlGetFields, {
        fieldSetName: '$studySessionTimeFieldSetName',
        objectName: '$sstObjInfo.data.apiName'
    })
    wiredSstFields(result) {
        this.sstFieldsResult = result;
        this.sstFieldsResponse = null;

        if (result.data) {
            this.sstFieldsResponse = JSON.parse(result.data.responseData);
            this.sstFieldsData = this.sstFieldsResponse;

            this.consoleLog(this.sstFieldsResponse, true);
        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }

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

    /**
     * @description Handle record type selection
     */
    handleRecordTypeOnchange(event) {
        this.recordTypeId = event.detail.value;
    }

    /**
     * @description handle combobox changes
     */
    handleComboboxChange(event) {

        const { fieldName, fieldLabel, selectedOpt } = event.detail;

        if (fieldName) {
            this[fieldName] = selectedOpt?.value;

            if (fieldName === 'studyOfferingId') {
                this._sseObj.reduivy__Study_Offering__c = selectedOpt?.value;
            }
        }
    }

    /**
     * @description Handle session field change
     */
    handleSessionFieldChange(event) {

        let dataFieldName = event.target.fieldName;
        let dataDisplayType = event.target.dataset.displaytype;
        let dataFieldValue = getFormDataFieldOnChangeValue(dataDisplayType, event.detail);

        this._sseObj[dataFieldName] = dataFieldValue;

        this.consoleLog('handleSessionFieldChange');
        this.consoleLog(this.sseObj, true);
    }

    /**
     * @description Handle new study session time click
     */
    handleAddNewStudySessionTimeClick() {
        let newIdx = (this._sseObj.reduivy__Study_Session_Times__r ? this._sseObj.reduivy__Study_Session_Times__r.length : 0) + 1;
        let newSstObj = {
            Id: 'newsst_' + newIdx,
            Name: this.sseObj.Name
        };

        if (this._sseObj.reduivy__Study_Session_Times__r) {
            this._sseObj.reduivy__Study_Session_Times__r.push(newSstObj);
        } else {
            this._sseObj.reduivy__Study_Session_Times__r = [newSstObj];
        }
    }

    /**
     * @description Handle Study Sesssion Time change
     */
    handleStudySessionTimeChange(event) {
        const {idx, sstObj} = event.detail;
        this.consoleLog('handleStudySessionTimeChange');
        this.consoleLog(idx);

        if (idx > -1) {
            this._sseObj.reduivy__Study_Session_Times__r[idx] = sstObj;
        }
    }

    /**
     * @description Handle study session time deletion
     */
    handleStudySessionTimeDelete(event) {
        const {idx, sstObj} = event.detail;
        this.consoleLog('handleStudySessionTimeDelete');
        this.consoleLog(idx);

        if (idx > -1) {
            this._sseObj.reduivy__Study_Session_Times__r.splice(idx, 1);
            if(!sstObj.Id.startsWith('newsst_')){
                this.sstToDelete.push(sstObj);
            }
        }
    }

    /**
     * @description Set default values
     */
    setDefaultValues() {
        for(let field of this.sseFieldsData) {
            if (Object.hasOwn(this.sseObj, field.fieldName)) {
                field.value = this.sseObj[field.fieldName];
            }
        }
    }

    /**
     * @description Handle cancel button click
     */
    handleCancel() {
        this.close({operation:'cancel'});
    }

    /**
     * @description Handle next button click after selecting record type
     */
    handleNext() {
        if (
            this.studyOfferingId && (
                (this.recordTypeOptions.length > 0 && this.recordTypeId) ||
                (this.recordTypeOptions.length === 0 && !this.recordTypeId)
            )
        ) {
            this.doneNewStudySessionSelection = true;

            this.setDefaultValues();
        } else {
            this.doneNewStudySessionSelection = false;
        }
    }

    /**
     * @description Handle save button click to save the study session with/without study session time without generating study events
     */
    handleSave() {
        this.genericHandleSave(false);
    }

    /**
     * @description Handle save button click to save the study session with/without study session time and generate study events
     */
    handleSaveAndUpdateSchedules() {
        this.genericHandleSave(true);
    }

    /**
     * @description Save the study session with/without study session time and generate study events 
     * @param {Boolean} generateStudyEvent True if generate study event is clicked
     */
    async genericHandleSave(generateStudyEvent){
        this.toggleSpinner(1);
        let validated = this.validateSessionAndTime();

        if (validated) {
            let deserializeableSseObj = {...this.sseObj};
            deserializeableSseObj.reduivy__Study_Session_Times__r = this.rewriteSubquery(deserializeableSseObj.reduivy__Study_Session_Times__r);
            this.removeExtraFieldsInStudySession(deserializeableSseObj);

            let sessionsWithSessionTimesString = JSON.stringify([deserializeableSseObj]);

            try {
                let upsertResult = await ctrlUpsertSessionsAndSessionTimes({
                    sessionsWithSessionTimesString: sessionsWithSessionTimesString, 
                    sstIdsToDelete: this.sstToDelete.map(sst=> sst.Id)
                });

                let responseData = JSON.parse(upsertResult.responseData);
  
                if(generateStudyEvent){
                    await ctrlGenerateStudyEvent({
                        studySessionIds: responseData.sseIdList
                    });
                }

                let modifiedIdsList = [];
                let idsList = responseData.idsToNotifyUpdate;
                for (let id of idsList) {
                    modifiedIdsList.push({ recordId: id });
                }
                
                this.toggleSpinner(-1);
                this.close({ operation: 'submit', eventData: modifiedIdsList });
                
            } catch (error) {
                promptError(sessionSchedulerLabels.ERROR_LABEL, getErrorMessage(error));
                this.toggleSpinner(-1);
            }

        } else {
            promptError(sessionSchedulerLabels.ERROR_LABEL, this.missingInfoErrorText);
            this.toggleSpinner(-1);
        }
    }

    removeExtraFieldsInStudySession(sseObj){
        delete sseObj.studyEvents;

        //remove the parent record stated in group by fields
        for(let field of Object.keys(sseObj)){
            if(field.endsWith('__r') && field !== 'reduivy__Study_Session_Times__r'){
                delete sseObj[field];
            }
        }

        return sseObj
    }

    
    /**
    * @description Validate Study Session fields and time edit fields and return true if they are validated
    */
    validateSessionAndTime() {
        let sessionIsValidated = this.validateSession();
        let timeEditIsValidated = this.validateTimeEdit();

        return sessionIsValidated && timeEditIsValidated;
    }

    /**
    * @description Validate Study Session fields and return true if it is validated
    */
    validateSession() {
        let element = [...this.template.querySelectorAll('[data-save-required="true"]')];
        let requiredFieldsValid = element.reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            this.consoleLog('validateRequiredDataFields :: ' + inputCmp.name + ' - ' + inputCmp.value);
            return validSoFar && inputCmp.value;

        }, true);

        return requiredFieldsValid;
    }

    /**
    * @description Validate Time Edit fields and return true if it is validated
    */
    validateTimeEdit() {

        let sstElements = this.template.querySelectorAll('c-study-session-scheduler-session-time-edit');
        
        if (sstElements && sstElements.length > 0) {
            let valid = true;
            
            for (let ele of sstElements) {
                let isValid = ele.validateRequiredDataFields();

                if (!isValid) {
                    valid = false;
                }
            }

            return valid;
        }

        return false;
    }

    /**
    * @description Validate required data fields and return true if they are validated
    */
    validateRequiredDataFields() {
        let element = [...this.template.querySelectorAll('[data-save-required="true"]')];
        let requiredFieldsValid = element.reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            this.consoleLog('validateRequiredDataFields :: ' + inputCmp.name + ' - ' + inputCmp.value);
            return validSoFar && inputCmp.value;

        }, true);

        return requiredFieldsValid;

    }

    /**
     * @description Rewrite a sub object before passing to Apex controller, so that deserialize into Study Session will be successful
     */
    rewriteSubquery(sobjArray) {
        if (sobjArray && !Object.hasOwn(sobjArray, 'records')) {
            let tempArray = sobjArray;
            sobjArray = {
                totalSize: tempArray.length,
                done: true,
                records: tempArray
            }
        }

        return sobjArray;
    }

    /**
     * @description Return true when form fields are loaded
     */
    get areFieldsLoaded() {
        return this.sseFieldsResponse && this.sstFieldsResponse;
    }

    /**
     * @descripton Spinner loading status
     */
	get isLoading() {
        return this.loadedLists === 0 && this.areFieldsLoaded ? false : true;
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
        logInfo('StudySessionSchedulerSessionEditModal', anything, this.enableDebugMode, isJson);
    }
	
}