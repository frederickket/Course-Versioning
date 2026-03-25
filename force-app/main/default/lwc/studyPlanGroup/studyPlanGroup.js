/**
 * @Author 		WDCi (Lean)
 * @Date 		Nov 2023
 * @group 		Study Plan
 * @Description Study plan hierarchy wizard
 * @changehistory
 * ISS-001617 10-11-2023 Lean - new component
 * ISS-002152 30-10-2024 Jordan - Study Plan Wizard to support modification
 * ISS-002230 05-02-2025 XW - added spsGroupTitleField 
 * ISS-002330 24-03-2025 XW - use sps translation name if found
 * ISS-002654 03-10-2025 Lean - Column number shared util
 * ISS-002736 25-11-2025 XiRouh - Added tableTextDisplayMode configurable attribute
 */
import { LightningElement, api, wire, track } from 'lwc';
import { promptError } from 'c/toasterUtil';
import { getErrorMessage, logInfo } from 'c/loggingUtil';
import { studyPlanHierarchyConstants } from 'c/studyPlanHierarchyHelper';
import { shadeHexColorCode } from 'c/cssUtil';
import { customLabels } from 'c/labelLoader';
import { getColumnSize } from 'c/lwcUtil';

import { getRecord } from "lightning/uiRecordApi";
import { getObjectInfo } from 'lightning/uiObjectInfoApi';

//refresh module
import { refreshApex } from '@salesforce/apex';
import { registerRefreshHandler, unregisterRefreshHandler } from 'lightning/refresh';

//Apex methods
import ctrlGetChildRecords from '@salesforce/apex/REDU_StudyPlanGroup_LCTRL.getChildRecords';

import SUN_OBJECT from '@salesforce/schema/Study_Unit__c';

import GROUP_TITLE_LABEL from '@salesforce/label/c.Study_Plan_Group_Title';

//wire attributes for querying individual pathway using getRecord
const SPS_FIELDS = [
    "reduivy__Study_Plan_Structure__c.Id",
    "reduivy__Study_Plan_Structure__c.Name",
    "reduivy__Study_Plan_Structure__c.reduivy__Credits__c",
    "reduivy__Study_Plan_Structure__c.reduivy__Parent_Study_Plan_Structure__c",
    "reduivy__Study_Plan_Structure__c.reduivy__Study_Plan__c",
    "reduivy__Study_Plan_Structure__c.reduivy__Units_Required__c",
];

import CREDIT_OR_UNITS_REQUIRED_LABEL from '@salesforce/label/c.Number_of_Credits_or_Study_Units_Required_For_Completion';
import ctrlGetTranslationFieldForNameByObjPrefix from '@salesforce/apex/REDU_Translation_LCTRL.getTranslationFieldForNameByObjPrefix';

const OBJ_TRANSLATION = [
    "SPS"
];

export default class StudyPlanGroup extends LightningElement {
	
	//configurable attributes
    @api spsId; // study plan recordId
    @api level; // limit of 3 levels of groups
    @api spsRecordTypeInfo;

    @api showSpsGroupInfo;
    @api spsGroupTitleField;
    @api spsGroupInfoFields; // Semi-colon separated list of field API names for study plan structure group highlights
    @api groupModalFields;
    @api unitModalFields;
    @api spsGroupInfoColumnNo;
    @api accordionBackgroundColor;
    @api accordionTextColor;

    @api spsUnitTableFields; // Semi-colon separated list of field API names for study plan structure unit table
    @api enableClickableRefField = false;
    @api hrefTargetType;
    @api isCommunity;
    @api isModeView;

    //ISS-002736
    @api tableTextDisplayMode;
    
	@api enableDebugMode = false;
	
	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false;
	loadedLists = 0;
	
    //refresh handler
    refreshHandlerID;

    //wire attribute
    spsChildWireResult;
    spsChildResponse;

    spsWireResult;
    spsRecord;
    
    @track objectTranslatedNameResult;
    @track objectTranslatedNameResponse;

	//labels
	label = {
        CREDIT_OR_UNITS_REQUIRED_LABEL,
        ...customLabels
    };
	
	//js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'tooltips'
    modules = ['stringutil'];
	
	/**
     * @descripton library loader
     */
    handleLibLoadSuccess(event) {
        this.isScriptLoaded = true;
        this.isInitSuccess = true;

        this.updateCssVars();
        
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
        this.refreshHandlerID = registerRefreshHandler(this, this.refreshData);
	}
	
    /**
     * @descripton disconnected callback
     */
	disconnectedCallback() {
		unregisterRefreshHandler(this.refreshHandlerID);
	}

    /**
     * @description Refresh data
     */
    refreshData() {
        this.consoleLog('refreshData');

        refreshApex(this.spsChildWireResult);

        return new Promise((resolve) => {
            resolve(true);
        });

    }

    /**
     * @description Get study unit object info
     */
    @wire(getObjectInfo, {objectApiName: SUN_OBJECT})
    sunObjInfo;

    get sunLabelPlural() {
        if (this.sunObjInfo && this.sunObjInfo.data) {
            return this.sunObjInfo.data.labelPlural;
        }

        return null;
    }

    /**
     * @description Sample wire method that invoke apex controller to retrieve data
     */
    @wire(ctrlGetChildRecords, {
        spsId: "$spsId"
    })
    wireChildGroups(result) {
        
        this.spsChildWireResult = result;
        this.spsChildResponse = null;

        if (result.data) {
            this.spsChildResponse = JSON.parse(result.data.responseData);
            this.consoleLog(this.spsChildResponse, true);
        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }

    }

    /**
     * @description Get study plan structure record
     */
    @wire(getRecord, { recordId: "$spsId", fields: "$spsFields" })
    wiredSpsRecord(result) {
        
        this.spsWireResult = result;
        this.spsRecord = null;

        if (result.data) {
            this.spsRecord = result.data;
            this.consoleLog(this.spsRecord, true);
        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }

    }

    /**
     * @description Get Study plan structure Translation Name
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
     * @description return the study plan structure translation field for name
     */
    get spsNameTranslationField() {
        return this.objectTranslatedNameResponse?.SPS;
    }

    /**
     @description return sps fields to be queried
     */
    get spsFields() {
        let fields = [...SPS_FIELDS];

        if(this.spsGroupTitleField) {
            fields.push('reduivy__Study_Plan_Structure__c.' + this.spsGroupTitleField);
        }

        if(this.spsNameTranslationField) {
            fields.push('reduivy__Study_Plan_Structure__c.' + this.spsNameTranslationField);
        }

        return fields;
    }

    /**
     * @description Return current sps name
     */
    get spsName() {
        return this.spsRecord?.fields?.Name?.value;
    }

    /**
     * @description Return current sps translation name
     */
    get spsTranslationName() {
        return this.spsRecord?.fields?.[this.spsNameTranslationField]?.value;
    }

    /**
     * @description Return current sps's parent record id
     */
    get spsParentId() {
        return this.spsRecord?.fields?.reduivy__Parent_Study_Plan_Structure__c?.value;
    }

    /**
     * @description Return SPS Group record type id
     */
    get spsGroupRecordTypeId() {
        return this.spsRecordTypeInfo?.spsGroupRecordTypeId;
    }

    /**
     * @description Return SPS Group record type label
     */
    get spsGroupRecordTypeLabel() {
        return this.spsRecordTypeInfo?.spsGroupRecordTypeLabel;
    }

    /**
     * @description Return SPS Unit record type id
     */
    get spsUnitRecordTypeId() {
        return this.spsRecordTypeInfo?.spsUnitRecordTypeId;
    }

    /**
     * @description Return SPS Unit record type label
     */
    get spsUnitRecordTypeLabel() {
        return this.spsRecordTypeInfo?.spsUnitRecordTypeLabel;
    }

    /**
     * @description Return true if the spsRecord is fetched by the wire method
     */
    get isSpsRecordReady() {
        if (this.spsId && this.spsRecord && this.spsRecord.fields) {
            return true;
        }

        return false;
    }

    get title() {
        if (this.isSpsRecordReady && 
            (this.spsRecord.fields[this.spsGroupTitleField]?.displayValue || this.spsRecord.fields[this.spsGroupTitleField]?.value)
        ) {

            let groupName = this.spsRecord.fields[this.spsGroupTitleField]?.displayValue || this.spsRecord.fields[this.spsGroupTitleField]?.value;
            let requiredLabel = '';
            
            if (this.noOfcredits) {
                requiredLabel = CREDIT_OR_UNITS_REQUIRED_LABEL.format([this.noOfcredits, this.label.CREDITS_LABEL.toLowerCase()]);
            } else if (this.noOfUnits) {
                requiredLabel = CREDIT_OR_UNITS_REQUIRED_LABEL.format([this.noOfUnits, this.sunLabelPlural.toLowerCase()]);
            }

            return GROUP_TITLE_LABEL.format([groupName, requiredLabel]);

        }

        return null;
    }

    get noOfcredits() {
        if (this.isSpsRecordReady && this.spsRecord.fields.reduivy__Credits__c.value) {
            return this.spsRecord.fields.reduivy__Credits__c.value;
        }

        return null;
    }

    get noOfUnits() {
        if (this.isSpsRecordReady && this.spsRecord.fields.reduivy__Units_Required__c.value) {
            return this.spsRecord.fields.reduivy__Units_Required__c.value;
        }

        return null;
    }

    get hasChildSps() {
        if (this.spsChildResponse && this.spsChildResponse.length > 0) {
            return true;
        }

        return false;
    }

    get childGroups() {
        if (this.spsChildResponse) {
            return this.spsChildResponse.filter(childSps => childSps.RecordType.Id === this.spsGroupRecordTypeId);
        }

        return null;
    }

    get hasChildGroups() {
        if (this.childGroups && this.childGroups.length > 0) {
            return true;
        }

        return false;
    }

    get newGroupAvailable() {
        if ((!this.hasChildSps || (this.hasChildGroups)) && this.level < 3) {
            return true;
        }

        return false;
    }

    get newUnitAvailable() {
        if (!this.hasChildSps || !(this.hasChildGroups)) {
            return true;
        }

        return false;
    }

    /**
     * @description Return a list of individual pathway fields
     */
    get infoFields() {
        if (this.spsGroupInfoFields) {
            return this.spsGroupInfoFields.split(';');
        }

        return [];
    }

    /**
     * @description Return the layout item size
     */
    get infoFieldSize() {
        return getColumnSize(this.spsGroupInfoColumnNo, 4);
    }

    /**
     * @description Return the shaded accordion background color for child groups
     */
    get accordionBackgroundColorShaded() {
        
        return shadeHexColorCode(this.accordionBackgroundColor, 0.3);
    }

    /**
     * @description Return ipe accordion section name
     */
    get accordionSectionName() {
        return this.spsId;
    }

    /**
     * @description Return ipe according default active sections
     */
    get activeSectionName() {
        return [this.spsId];
    }

    /**
     * @description ISS-002152 Return new group label
     */
    get newGroupLabel(){
        return this.label.NEW_RECORD_LABEL.format([this.spsGroupRecordTypeLabel]);
    }

    /**
     * @description ISS-002152 Return new unit label
     */
    get newUnitLabel(){
        return this.label.NEW_RECORD_LABEL.format([this.spsUnitRecordTypeLabel]);
    }

    /**
     * @description ISS-002152 Return new group constant
     */
    get newGroupActionName(){
        return studyPlanHierarchyConstants.NEW_GROUP_ACTION;
    }

    /**
     * @description ISS-002152 Return new unit constant
     */
    get newUnitActionName(){
        return studyPlanHierarchyConstants.NEW_UNIT_ACTION;
    }

    /**
     * @description ISS-002152 Return edit constant
     */
    get editActionName(){
        return studyPlanHierarchyConstants.EDIT_ACTION;
    }

    /**
     * @description ISS-002152 Return delete constant
     */
    get deleteActionName(){
        return studyPlanHierarchyConstants.DELETE_ACTION;
    }

    /**
     * @description Level of child group
     */
    get nextLevel(){
        return this.level + 1;
    }

    /**
     * @description ISS-002152 This funtion is called when user clicks on button menu item
     */
    handleButtonEvent(event) {

        let actionType = event.detail.value;

        let detail = {
            actionType: actionType
        }

        if (actionType === studyPlanHierarchyConstants.NEW_UNIT_ACTION) {
            detail.spsId = null;
            detail.spsParentId = this.spsId;
            detail.spsName = null;
            detail.spsTranslationName = null;
            detail.spsType = this.spsUnitRecordTypeId;

        } else if (actionType === studyPlanHierarchyConstants.NEW_GROUP_ACTION) {
            detail.spsId = null;
            detail.spsParentId = this.spsId;
            detail.spsName = null;
            detail.spsTranslationName = null;
            detail.spsType = this.spsGroupRecordTypeId;

        } else {
            detail.spsId = this.spsId;
            detail.spsName = this.spsName;
            detail.spsParentId = this.spsParentId;
            detail.spsTranslationName = this.spsTranslationName;
            detail.spsType = this.spsGroupRecordTypeId;
        }

        const selectEvent = new CustomEvent('selection', {
            detail: detail
        });

        // Fire the custom event
        this.dispatchEvent(selectEvent);
    }

    /**
     * @description ISS-002152 This funtion is called when user clicks on button menu item
     */
    handleChildButtonEvent(event) {
        const selectEvent = new CustomEvent('selection', {
            detail: event.detail
        });
        // Fire the custom event
        this.dispatchEvent(selectEvent);
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
     * @descripton Spinner loading status
     */
	get isLoading(){
        return this.loadedLists === 0 && this.spsChildResponse ? false : true;
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
        logInfo('StudyPlanGroup', anything, this.enableDebugMode, isJson);
    }
	
}