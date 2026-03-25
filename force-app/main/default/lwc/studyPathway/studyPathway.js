/**
 * @Author 		WDCi (Sueanne)
 * @Date 		March 2024
 * @group 		Study Pathway
 * @Description Study pathway wizard
 * @changehistory
 * ISS-001917 26-03-2024 Sueanne - new component
 * ISS-002124 10-07-2024 Sueanne - added showModalHeader
 * ISS-002187 12-12-2024 XW - Remove the default value if the field is empty
 * ISS-002191 12-12-2024 XW - Pass hrefTarget into studyPathwayUnit
 * ISS-002189 13-12-2024 XW - open selected term in study pathway & search by study unit & preselect minor spo
 * ISS-002331 12-03-2025 Lean - Show proper message when there is no study pathway found
 * ISS-002330 19-03-2025 XW - display translated spl name (major/minor) if found
 * ISS-002654 03-10-2025 Lean - Column number shared util
 */
import { LightningElement, api, wire, track } from 'lwc';
import { promptError } from 'c/toasterUtil';
import { getErrorMessage, logInfo } from 'c/loggingUtil';
import { customLabels } from 'c/labelLoader';
import { getColumnSize } from 'c/lwcUtil';

import { refreshApex } from '@salesforce/apex';
import { RefreshEvent, registerRefreshContainer, unregisterRefreshContainer } from 'lightning/refresh';

import SUN_OBJECT from '@salesforce/schema/Study_Unit__c';
import SPW_OBJECT from '@salesforce/schema/Study_Pathway__c';

//Apex methods
import ctrlGetStudyPathway from '@salesforce/apex/REDU_StudyPathway_LCTRL.getStudyPathway';
import ctrlGetStudyPlanOptions from '@salesforce/apex/REDU_StudyPathway_LCTRL.getStudyPlanOptions';
import ctrlGetStudyPathwayTermIds from '@salesforce/apex/REDU_StudyPathway_LCTRL.getStudyPathwayTermIds';
import ctrlGetTranslationFieldForNameByObjPrefix from '@salesforce/apex/REDU_Translation_LCTRL.getTranslationFieldForNameByObjPrefix';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';

import NO_STUDY_PATHWAY_FOUND_LABEL from '@salesforce/label/c.No_Default_Active_Study_Pathway_Found';

const OBJ_TRANSLATION = [
    "SPL"
];

export default class PathwayVisualiser extends LightningElement {
	
	//configurable attributes
    @api recordId; //study pathway or study plan id
    
    @api modalTitle;
    @api modalIconName;
    @api studyPathwayInfoFields;
    @api studyPathwayTermTitlePrefix;
    @api studyPathwayTermInfoFields;
    @api studyPathwayUnitTitleField;
    @api studyPathwayUnitInfoFields;
    @api studyPathwayUnitIcon;
    @api studyPathwayGroupTitleField;
    @api studyPathwayGroupInfoFields;
    @api studyPathwayGroupIcon;
    @api showStudyPlanOptions = false;
    @api accordionBackgroundColor;
    @api accordionTextColor;
    @api comboboxLabel;
    @api currentTermNumber; //ISS-002189
    @api showStudyUnitQuickSearch; //ISS-002189

    @api set preselectedSpo(value){ //ISS-002189
        if(value) {
            this._preselectedSpo = JSON.parse(JSON.stringify(value));
            this.addPreselectedSpo();
        }
    } 
	get preselectedSpo(){
        return this._preselectedSpo;
    }

    @api hrefTargetType;
    @api enableDebugMode = false;
	
	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false;
	loadedLists = 0;
    showFilterPanel = false;
    studyUnitSearchString; //ISS-002189
    draftStudyUnitSearchString; //ISS-002189
    _preselectedSpo; //ISS-002189
    
    //wire attribute
    studyPathwayResult;
    studyPathwayRecord;

    studyPlanOptionResult;
    studyPlanOptionRecord;

    studyPathwayTermIdsResult;
    studyPathwayTermIdsRecord;

    @track objectTranslatedNameResult;
    @track objectTranslatedNameResponse;

    //other attributes
    @track selectedSpo = []; //selected study plan option
    @track draftSelectedSpo = []; //ISS-002189

	//labels
	label = customLabels; // ISS-002189
	
	//js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'jquery'
    modules = ['stringutil'];

    //refresh Container
    refreshContainerID;
	

    //ISS-002189 wired sun object
    @wire(getObjectInfo, {objectApiName: SUN_OBJECT})
    sunObjInfo;

    @wire(getObjectInfo, {objectApiName: SPW_OBJECT})
    spwObjInfo;

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
    connectedCallback(){
        this.refreshContainerID = registerRefreshContainer(this, this.refreshData);
	}
	
    /**
     * @descripton disconnected callback
     */
	disconnectedCallback() {
		unregisterRefreshContainer(this.refreshContainerID);
	}

    /**
     * @description Refreh data
     */
    refreshData() {
        this.consoleLog('refreshData');

        refreshApex(this.studyPathwayResult);
        refreshApex(this.studyPlanOptionResult);
        refreshApex(this.studyPathwayTermIdsResult);

        return new Promise((resolve) => {
            resolve(true);
        });

    }

    /**
     * @description Return true to show modal title and icon
     */
    get showModalHeader(){
        if(this.modalTitle){
            return true;
        }
        return false;
    }

    /**
     * @description Return default study pathway id
     */
    get studyPathwayId() {
        if (this.studyPathwayRecord) {
            return this.studyPathwayRecord.Id;
        }
        return null;
    }

    /**
     * @description Return study pathway label
     */
    get studyPathwayLabel() {
        return this.spwObjInfo?.data?.label;
    }

    /**
     * @description Return no default pathway found message
     */
    get noPathwayFoundLabel() {
        return NO_STUDY_PATHWAY_FOUND_LABEL.format([this.studyPathwayLabel]);
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
        logInfo('PathwayVisualiser', anything, this.enableDebugMode, isJson);
    }

    /**
     * @description get the current study pathway in record page
     */
    @wire(ctrlGetStudyPathway, {recordId: '$recordId'})
    wiredStudyPathway(result) {

        this.studyPathwayResult = result;
        this.studyPathwayRecord = null;
        
        if (result.data) {
            this.studyPathwayRecord = JSON.parse(result.data.responseData);
            this.consoleLog(this.studyPathwayRecord, true);
        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
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
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    get studyPlanId(){
        return this.studyPathwayRecord?.reduivy__Study_Plan__c;
    }


    /**
     * @description Return a list of study pathway fields
     */
    get spwInfoFields() {
        if (this.studyPathwayInfoFields) {
            return this.studyPathwayInfoFields.split(';');
        }
        return [];
    }

    /**
     * @description Return the layout item size (study pathway)
     */
    get spwInfoFieldSize() {
        return getColumnSize(this.spwInfoFields?.length, 4);
    }

    /**
     * @description Return the layout item size (accordion)
     */
    get accordionSize() {
        if (!this.showStudyPlanOptions) {
            return 12;
        }
        return 9;
    }

    /**
     * @description get the study plan options based on studyPlanId
     */
    @wire(ctrlGetStudyPlanOptions, {studyPlanId: '$studyPlanId'})
    wiredStudyPlanOptions(result) {

        this.studyPlanOptionResult = result;
        this.studyPlanOptionRecord = null;

        if (result.data) {
            this.studyPlanOptionRecord = JSON.parse(result.data.responseData);
            this.consoleLog(this.studyPlanOptionRecord, true);
        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }

    }

    /**
     * @description return study plan option for combobox options
     */
    get studyPlanOptions(){
        let options = [];

        if(this.studyPlanOptionRecord){
            for(let spo of this.studyPlanOptionRecord){
                let spLabel = spo.reduivy__Child_Study_Plan__r?.[this.splNameTranslationField];
                if(!spLabel) {
                    spLabel = spo.reduivy__Child_Study_Plan__r?.Name;
                }
                options.push({
                    id: spo.Id,
                    label: spLabel,
                    studyPlanId: spo.reduivy__Child_Study_Plan__r.Id,
                    value: spo.Id
                })
            }
        }
        return options;
    }

    /**
     * @description return the study plan translation field for name
     */
    get splNameTranslationField() {
        return this.objectTranslatedNameResponse?.SPL;
    }

    /**
     * @description to handle study plan option combobox change
     */
    handleSpoChange(event){
        this.toggleSpinner(1);

        try{
            let selectedSpoIdx = this.studyPlanOptions.findIndex(item => item.id === event.detail.value);
            if(selectedSpoIdx !== -1 && !this.draftSelectedSpo.find(item => item.id === event.detail.value)){
                this.draftSelectedSpo.push(this.studyPlanOptions[selectedSpoIdx]);
            }

            this.template.querySelector('lightning-combobox[data-name="spocombobox"]').value = null;
            
            this.toggleSpinner(-1);
        }catch(error){
            this.toggleSpinner(-1);
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
        }
    }

    /**
     * @description to handle remove study plan option 
     */
    handleRemoveSelectedSpo(event){
        this.toggleSpinner(1);

        try{
            let indexToRemove = event.detail.index;
            this.draftSelectedSpo.splice(indexToRemove, 1);

            this.toggleSpinner(-1);
        }catch(error){
            this.toggleSpinner(-1);
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
        }
    }

    /**
     * @description Return the selected study plan option(label, id) from combobox
     */
    get selectedSpoPills() {
        
        let spoPills = [];
        for (let spo of this.draftSelectedSpo) {
            spoPills.push(
                {
                    label: spo.label,
                    name: spo.id,
                }
            );
        }

        return spoPills;
    }

    /**
     * @description get a list of study pathway term ids from current study pathway
     */
    @wire(ctrlGetStudyPathwayTermIds, {studyPwId : '$studyPathwayId'})
	wiredStudyPathwayTermIds(result) {

        this.studyPathwayTermIdsResult = result;
        this.studyPathwayTermIdsRecord = null;

        if (result.data) {
            this.studyPathwayTermIdsRecord = JSON.parse(result.data.responseData);
            this.consoleLog(this.studyPathwayTermIdsRecord, true);
        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    /** ISS-002189
     * @description get the classes for the filter panel
     */
    get panelClasses(){
        let baseClasses = 'pathway-visualiser-panel slds-panel slds-size_medium slds-panel_docked slds-panel_docked-right slds-panel_drawer';

        if(this.showFilterPanel){
            return baseClasses + ' slds-is-open';
        }

        return baseClasses;
    }

    /** ISS-002189
     * @description get the label for the study unit search bar
     */
    get showStudyUnitQuickSearchLabel(){
        return this.label.SEARCHPLACEHOLDER_LABEL.format([this.sunObjInfo?.data?.label]);
    }

    /** ISS-002189
     * @description show filter button if show study unit quick search or preview major/minor is enable
     */
    get showFilterButton(){
        return this.showStudyUnitQuickSearch || this.showStudyPlanOptions;
    }

    /** ISS-002189
     * @description get the classes for the filter panel
     */
    handleToggleFilterPanel(){
        this.showFilterPanel = !this.showFilterPanel;
    }

    /**
     * ISS-002189
     * @description handle study unit search string
     */
    handleShowStudyUnitQuickSearch(event){ 
        this.draftStudyUnitSearchString = event.detail.value;
    }

    /** ISS-002189
     * @description label of clear button
     */
    get clearButtonLabel(){
        return this.label.CLEAR_LABEL;
    }

    /** ISS-002189
     * @description label of apply button
     */
    get applyButtonLabel(){
        return this.label.APPLY_LABEL;
    }

    /** ISS-002189
     * @description handle clear click
     */
    handleClearClick(){
        this.draftSelectedSpo = [];
        this.draftStudyUnitSearchString = "";
    }

    /** ISS-002189
     * @description handle apply click
     */
    handleApplyClick(){
        this.studyUnitSearchString = this.draftStudyUnitSearchString;
        this.selectedSpo = JSON.parse(JSON.stringify(this.draftSelectedSpo));
        this.dispatchEvent(new RefreshEvent());
    }

    /** ISS-002189
     * @description add preselected spo into draft and selected spo
     */
    addPreselectedSpo(){
        if(this.preselectedSpo.length > 0){
            for(let preSpo of this.preselectedSpo){
                let insertedDraftSpoIndex = this.draftSelectedSpo.findIndex(spo => spo.id === preSpo.id);
                if(insertedDraftSpoIndex < 0){
                    this.draftSelectedSpo.push(preSpo);
                }

                let insertedSpoIndex = this.selectedSpo.findIndex(spo => spo.id === preSpo.id);
                if(insertedSpoIndex < 0){
                    this.selectedSpo.push(preSpo);
                }
            }
        }
    }
}