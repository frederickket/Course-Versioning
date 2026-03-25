/**
 * @Author 		WDCi (XW)
 * @Date 		Jan 2024
 * @group 		Study Session Scheduler
 * @Description 
 * @changehistory
 * ISS-001920 05-08-2024 XW - create new class
 * ISS-002230 22-01-2025 XW - replace hardcoded label to custom label
 * ISS-002263 21-02-2025 XW - start time and end time of a sst in timeedit is limited to the eduinst operation time or timeline start and end time
 * ISS-002654 03-10-2025 Lean - Column number shared util
 * ISS-002719 07-11-2025 XW - ensure that facility name is displayed if the facility doesnt match the default criteria
 * ISS-002738 20-11-2025 XW - the default facility options are refreshed when modal is opened
 */
import { LightningElement, api, wire, track } from 'lwc';
import { promptError } from 'c/toasterUtil';
import { getErrorMessage, logInfo } from 'c/loggingUtil';
import { initCacheIdx, setupPicklistOptionsFromRecords, getFormDataFieldOnChangeValue, getColumnSize } from 'c/lwcUtil';
import { sessionSchedulerLabels } from 'c/studySessionSchedulerHelper';

import { getObjectInfo, getPicklistValuesByRecordType } from "lightning/uiObjectInfoApi";
import SST_OBJECT from '@salesforce/schema/Study_Session_Time__c';

//Apex methods
import ctrlGetFacilities from '@salesforce/apex/REDU_SessionScheduler_LCTRL.getFacilities';


export default class StudySessionSchedulerSessionTimeEdit extends LightningElement {
	
	//configurable attributes
    @api idx;
    @api campusId;
    @api requiredFacilityType;
    @api facilityDefaultCriteria;
    @api allowCrossCampusFacilityAllocation = false;
    
    @api accordionBackgroundColor;
    @api accordionTextColor;
    @api accordionButtonVariant;
    @api sstColumnNo;

    @api timelineMinTime;
    @api timelineMaxTime;
    @api eduInstStartTime;
    @api eduInstEndTime;

    /**
     * @description To make the object reactive to changes from parent
     */
    @api
    set sstObj(val) {
        this._sstObj = JSON.parse(JSON.stringify(val));
    }

    get sstObj() {
        return this._sstObj;
    }

    /**
     * @description To make the object reactive to changes from parent
     */
    @api
    set sstFieldsData(val) {
        let fieldsData = JSON.parse(JSON.stringify(val));

        for(let field of fieldsData) {
            //we will use the custom searchable lookup to render the options
            if (field.fieldName === 'reduivy__Default_Facility__c') {
                field.isDefaultFacility = true;
            } else if(field.fieldName === 'reduivy__Start_Time__c' || field.fieldName === 'reduivy__End_Time__c') {
                field.isSystemTimeField = true;
            }
            
        }

        this._sstFieldsData = fieldsData;
    }

    get sstFieldsData() {
        return this._sstFieldsData;
    }

	@api enableDebugMode = false;

	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false
	loadedLists = 0;
    sstDefaultRecordTypeId;
    defaultFacilityRecordId = null;
    defaultFacilityMetDefaultCriteria = true;

    //local cache idx to force rerendering
    _cacheIdx;
	
    @track _sstObj;
    @track _sstFieldsData;

    //wire attribute
    facilityWireResult;
    faciityResponse;
    educationalInstitutionWireResult;
    educationalInstitutionOperationStartTime;
    educationalInstitutionOperationEndTime;

	//labels
	label = sessionSchedulerLabels;
	
	//js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'tooltips'
    modules = ['stringutil', 'moment'];
	
    connectedCallback() {
        this.consoleLog(this.idx);
        this.consoleLog(this.campusId);
        this.consoleLog(this.requiredFacilityType);
        this.consoleLog(this.facilityDefaultCriteria);
        this.consoleLog(this.allowCrossCampusFacilityAllocation);
        this._cacheIdx = initCacheIdx();
    }

    /**
     * @description get study session time object info to get the record type id
     */
    @wire(getObjectInfo, { 
        objectApiName: SST_OBJECT
    })
    getSstObjectInfo({ error, data }) {
        if (data) {
            this.sstDefaultRecordTypeId = data.defaultRecordTypeId;
        } else if (error) {
            promptError(sessionSchedulerLabels.ERROR_LABEL, getErrorMessage(error));
        }
    }

    /**
     * @description get all picklist label and value for study session time
     */
    @wire(getPicklistValuesByRecordType, {
        objectApiName: SST_OBJECT,
        recordTypeId: "$sstDefaultRecordTypeId",
    })
    sstPicklistsInfo;

	/**
     * @descripton library loader
     */
    handleLibLoadSuccess() {
        this.isScriptLoaded = true;
        this.isInitSuccess = true;

        this.setDefaultValues();
        this.updateCssVars();
        
    }

    /**
     * @descripton library loader
     */
    handleLibLoadFail() {
        this.isScriptLoaded = true;
        this.isInitSuccess = false;
    }
	
    /**
     * @description Update css var
     */
    updateCssVars() {
        let css = this.template.host.style;
        css.setProperty('--accordion-background-color', this.accordionBackgroundColor);
        css.setProperty('--accordion-text-color', this.accordionTextColor);
    }

    /**
     * @description Set default values
     */
    setDefaultValues() {
        
        this.consoleLog(JSON.stringify(this.sstObj));
        this.consoleLog(JSON.stringify(this.sstFieldsData));

        for(let field of this.sstFieldsData) {
            if (Object.hasOwn(this.sstObj, field.fieldName)) {
                if(field.displayType === 'TIME') {
                    let timeVal = this.sstObj[field.fieldName];
                    if (timeVal && timeVal.endsWith('Z')) {
                        timeVal = timeVal.slice(0, -1);
                    }

                    field.value = timeVal;
                } else {
                    field.value = this.sstObj[field.fieldName];
                }

                if(field.isDefaultFacility) { // get the record id of the default facility if found
                    this.defaultFacilityRecordId = field.value;
                }
            }
            
        }

        this.consoleLog(JSON.stringify(this.sstFieldsData));
    }

    /**
     * @description study session time column size
     */
    get sstColumnSize(){
        return getColumnSize(this.sstColumnNo, 4);
    }

    /**
     * @description Return day of week picklist options
     */
    get dayOfWeekOptions() {
        let options = this.sstPicklistsInfo?.data?.picklistFieldValues?.reduivy__Day_of_Week__c?.values;
        if (options) {
            this.consoleLog('dayOfWeekOptions');
            this.consoleLog(options, true);
        }

        return options;
    }

    /**
     * @description Return recurrence picklist options
     */
    get recurrenceOptions() {
        let options = this.sstPicklistsInfo?.data?.picklistFieldValues?.reduivy__Recurrence__c?.values;
        if (options) {
            this.consoleLog('recurrenceOptions');
            this.consoleLog(options, true);
        }

        return options;
    }

    /**
     * @description Return start time label
     */
    get startTimeOptionLabel() {
        if (this.sstObj?.reduivy__Start_Time__c) {
            let dt = moment.utc('2024-01-01T' + this.sstObj?.reduivy__Start_Time__c);

            return dt.format('hh:mm A');
        }

        return '';
    }

    /**
     * @description Return end time label
     */
    get endTimeOptionLabel() {
        if (this.sstObj?.reduivy__End_Time__c) {
            let dt = moment.utc('2024-01-01T' + this.sstObj?.reduivy__End_Time__c);

            return dt.format('hh:mm A');
        }

        return '';
    }

    /**
     * @description Return picklist option label
     */
    getPicklistLabel(options, value) {
        this.consoleLog('getPicklistLabel');
        this.consoleLog(options);
        this.consoleLog(value);

        let label;
        if(options){
            for(let opt of options) {
                if (opt.value === value) {
                    label = opt.label;
                    break;
                }
            }
        }

        return label;
    }

    /**
     * @description Return accordion section label
     */
    get accordionSectionLabel() {

        let sstName = (this.sstObj?.Name ? this.sstObj?.Name : null);
        let sstDow = (this.sstObj?.reduivy__Day_of_Week__c ? this.getPicklistLabel(this.dayOfWeekOptions, this.sstObj?.reduivy__Day_of_Week__c) : null);
        let sstRecur = (this.sstObj?.reduivy__Recurrence__c ? this.getPicklistLabel(this.recurrenceOptions, this.sstObj?.reduivy__Recurrence__c) : null);
        let sstStart = this.startTimeOptionLabel;
        let sstEnd = this.endTimeOptionLabel;

        let acclabel = '';
        let accDay = '';
        let accTime = '';
        
        if (sstDow && sstRecur) {
            accDay = sessionSchedulerLabels.SST_TIME_EDIT_DAY_LABEL.format([sstDow,sstRecur]);
        }

        if (sstStart && sstEnd) {
            accTime = sessionSchedulerLabels.SST_TIME_EDIT_TIME_LABEL.format([sstStart,sstEnd]);
        }

        acclabel = sessionSchedulerLabels.SST_TIME_EDIT_TITLE_LABEL.format([sstName ? sstName : sessionSchedulerLabels.UNKNOWN_LABEL, accDay, accTime]);

        return acclabel;
    }

    /**
     * @description Return form record id
     */
    get targetRecordId() {
        if (this.sstObj.Id && this.sstObj.Id.startsWith('newsst_')) {
            return null;
        }

        return this.sstObj.Id;
    }
    
    /**
    * @description get facility filter values to wire for get facility
    * */
    get facilityFilterValues() {
        let filters = {
            campusId: (this.allowCrossCampusFacilityAllocation ? null : this.campusId)
        };

        return JSON.stringify(filters);
    }

    /**
    * @description Return facility picklist options, the facility will be highlighted with asterik * if the required facility type matches
    */
    get facilityOptions() {
        if (this.faciityResponse) {
            let facilities = JSON.parse(JSON.stringify(this.faciityResponse));

            for (let fac of facilities) {
                if (fac.reduivy__Facility_Type__c === this.requiredFacilityType) {
                    fac.Name = '* ' + fac.Name;
                }
                if(!this.defaultFacilityMetDefaultCriteria && this.defaultFacilityRecordId === fac.Id) {
                    fac.isSelectable = false;
                }
            }

            facilities.sort((a, b) => a.Name.localeCompare(b.Name));

            return setupPicklistOptionsFromRecords(facilities, null, [{field: 'reduivy__Capacity__c', label: 'Capacity'}]);
        }

        return [];
    }

    /** 
     * @description the earliest possible time to select. (EduInst Operation Start Hour, or timeline start time)
     */
    get earliestSelectableTime() {
        if(this.eduInstStartTime) {
            return this.eduInstStartTime;
        } else if(this.timelineMinTime) {
            return this.timelineMinTime;
        }

        return '00:00:00.000Z';
    }

    /** 
     * @description the latest possible time to select. (EduInst Operation Start Hour, or timeline start time)
     */
    get latestSelectableTime() {
        if(this.eduInstEndTime) {
            return this.eduInstEndTime;
        } else if(this.timelineMaxTime) {
            return this.timelineMaxTime;
        }

        return '23:59:59.999Z';
    }


    /**
     * @description Wire method to get study offerings
     */
    @wire(ctrlGetFacilities, {
        nameFormat: '{Name}',
        defaultCriteria: '$facilityDefaultCriteria',
        filterValueStr: '$facilityFilterValues',
        selectedFacilityId: '$defaultFacilityRecordId',
        cacheIdx: '$_cacheIdx'
    })
    wireFacilities(result) {
        
        this.facilityWireResult = result;
        this.faciityResponse = null;

        if (result.data) {
            let responseJson = JSON.parse(result.data.responseData);
            this.faciityResponse = responseJson.facilities;
            this.defaultFacilityMetDefaultCriteria = responseJson.selectedFacilityMetDefaultCriteria;
            this.consoleLog(this.faciityResponse, true);

        } else if (result.error) {
            promptError(sessionSchedulerLabels.ERROR_LABEL, getErrorMessage(result.error));
        }

    }

    /**
     * @description Handle session time field changes
     */
    handleSessionTimeFieldChange(event) {

        let dataFieldName = event.target.fieldName;
        let dataDisplayType = event.target.dataset.displaytype;
        let dataFieldValue = getFormDataFieldOnChangeValue(dataDisplayType, event.detail);

        this._sstObj[dataFieldName] = dataFieldValue;

        this.consoleLog('handleSessionTimeFieldChange');
        this.consoleLog(this._sstObj, true);

        this.dispatchEvent(new CustomEvent('studysessiontimechange', {
            detail: {
                idx: this.idx,
                sstObj: this.sstObj
            }
        }));

    }

    /**
     * @description handle combobox changes
     */
    handleCustomSessionTimeFieldChange(event) {

        const { fieldName, fieldLabel, selectedOpt } = event.detail;

        if (fieldName) {
            this._sstObj[fieldName] = selectedOpt?.value ?? null;

            this.consoleLog('handleCustomSessionTimeFieldChange');
            this.consoleLog(this._sstObj, true);

            this.dispatchEvent(new CustomEvent('studysessiontimechange', {
                detail: {
                    idx: this.idx,
                    sstObj: this.sstObj
                }
            }));
        }
    }

    /**
     * @description Handle session time delete
     */
    handleDeleteStudySessionTimeClick() {
        this.dispatchEvent(new CustomEvent('studysessiontimedelete', {
            detail: {
                idx: this.idx,
                sstObj: this.sstObj
            }
        }));
    }
 
    /**
     * @description The public method for parent to invoke the required fields validation
     * @returns boolean
     */
    @api
    validateRequiredDataFields(){
        
        let element = [...this.template.querySelectorAll('[data-save-required="true"]')];
        let requiredFieldsValid = element
        .reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            this.consoleLog('validateRequiredDataFields :: ' + inputCmp.name  + ' - ' + inputCmp.tagName + ' - ' + inputCmp.value + ' - ' + validSoFar);

            if(inputCmp?.tagName?.toLowerCase() === 'lightning-input') {
                //only lightning-input has checkValidity method
                return validSoFar && inputCmp.value && inputCmp.checkValidity();
            } 
            return validSoFar && inputCmp.value;
        }, true);
        
        this.consoleLog("requiredFieldsValid :: " + requiredFieldsValid);

        return requiredFieldsValid;


    }
	
    /**
     * @descripton Spinner loading status
     */
	get isLoading(){
        return this.loadedLists === 0 && this.sstPicklistsInfo.data ? false : true;
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
        logInfo('StudySessionSchedulerSessionTimeEdit', anything, this.enableDebugMode, isJson);
    }
	
}