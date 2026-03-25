/**
 * @Author 		WDCi (Sueanne)
 * @Date 		April 2024
 * @group 		Study Pathway
 * @Description Study pathway wizard
 * @changehistory
 * ISS-001917 01-04-2024 Sueanne - new component
 * ISS-002191 12-12-2024 XW - Pass hrefTarget into studyPathwayUnit
 * ISS-002189 13-12-2024 XW - open selected term in study pathway
 * ISS-002189 16-12-2024 XW - added show study unit quick search
 * ISS-002230 22-01-2025 XW - replace hardcoded label to custom label
 * ISS-002654 03-10-2025 Lean - Column number shared util
 */
import { LightningElement, api, wire } from 'lwc';
import { promptError } from 'c/toasterUtil';
import { getErrorMessage, logInfo } from 'c/loggingUtil';
import { customLabels } from 'c/labelLoader';
import { getColumnSize } from 'c/lwcUtil';

//refresh module
import { refreshApex } from '@salesforce/apex';
import { registerRefreshHandler, unregisterRefreshHandler } from 'lightning/refresh';

//Apex methods
import ctrlGetStudyPathwayTerm from '@salesforce/apex/REDU_StudyPathwayTerm_LCTRL.getStudyPathwayTerm';
import ctrlGetStudyPathwayUnits from '@salesforce/apex/REDU_StudyPathwayTerm_LCTRL.getStudyPathwayUnits';

import TERM_TITLE_LABEL from '@salesforce/label/c.Pathway_Visualizer_Term_Title';

export default class StudyPathwayTerm extends LightningElement {
	
	//configurable attributes
    @api enableDebugMode;
    @api studyPathwayTermId;
    @api selectedSpo;
    @api studyPathwayId; //contains default study plan only
    @api studyPathwayTermTitlePrefix;
    @api studyPathwayTermInfoFields;
    @api studyPathwayUnitTitleField;
    @api studyPathwayUnitInfoFields;
    @api studyPathwayUnitIcon;
    @api studyPathwayGroupTitleField;
    @api studyPathwayGroupInfoFields;
    @api studyPathwayGroupIcon;
    @api studyPlanId;
    @api accordionBackgroundColor;
    @api accordionTextColor;
    @api hrefTargetType
    @api currentTermNumber; //ISS-002189
    @api studyUnitSearchString; //ISS-002189
	
	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false;
	loadedLists = 0;
	
    //refresh handler
    refreshHandlerID;

    //wire attribute
    studyPathwayTermResult;
    studyPathwayTermRecord;

    studyPathwayUnitResult;
    studyPathwayUnitRecord;

    selectedSptIdsResult;
    selectedSptIdsRecord;

	//labels
	label = customLabels;
	
	//js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'jquery'
    modules = ['stringutil'];
	
    /**
     * @description Update css var
     */
    updateCssVars() {
        let css = this.template.host.style;
        css.setProperty('--accordion-background-color', this.accordionBackgroundColor);
        css.setProperty('--accordion-text-color', this.accordionTextColor);
    }

	/**
     * @descripton library loader
     */
    handleLibLoadSuccess() {
        this.isScriptLoaded = true;
        this.isInitSuccess = true;
        
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

        refreshApex(this.studyPathwayTermResult);
        refreshApex(this.studyPathwayUnitRecord);

        return new Promise((resolve) => {
            resolve(true);
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
        logInfo('StudyPathwayTerm', anything, this.enableDebugMode, isJson);
    }

    /**
     * @description To get each terms contents
     */
    @wire(ctrlGetStudyPathwayTerm, {
        studyPathwayTermId: '$studyPathwayTermId'
    })
    wireStudyPathwayTerm(result) {
        this.studyPathwayTermResult = result;
        this.studyPathwayTermRecord = null;

        if (result.data) {
            this.studyPathwayTermRecord = JSON.parse(result.data.responseData);
            this.consoleLog(this.studyPathwayTermRecord, true);
        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    /**
     * @descripton gather study plan id from selected study plan option
     */
    get selectedSpoIds(){
        if(this.selectedSpo.length > 0){
            return this.selectedSpo.map(item => item.studyPlanId);
        }
        return null; 
    }

    /**
     * @description To get a study pathway unit id list from the current study pathway term
     */
    @wire(ctrlGetStudyPathwayUnits, {
        studyPathwayTermId: '$studyPathwayTermId',
        selectedSpoIds: '$selectedSpoIds'
    })
    wireStudyPathwayTermId(result) {
        this.studyPathwayUnitResult = result;
        this.studyPathwayUnitRecord = null;

        if (result.data) {
            this.studyPathwayUnitRecord = JSON.parse(result.data.responseData);
            this.consoleLog(this.studyPathwayUnitRecord, true);
        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    /**
     * @description return accordion label
     */
    get accordionLabel(){
        if(this.studyPathwayTermRecord){
            return TERM_TITLE_LABEL.format([this.studyPathwayTermTitlePrefix, this.studyPathwayTermRecord.reduivy__Term_Number__c]);
        }
        return null;
    }

    get activeSectionName(){
        if(this.currentTermNumber){
            return TERM_TITLE_LABEL.format([this.studyPathwayTermTitlePrefix, this.currentTermNumber]);
        }
        return null;
    }

    /**
     * @description Return a list of study pathway term fields
     */
    get spwtInfoFields() {
        if (this.studyPathwayTermInfoFields) {
            return this.studyPathwayTermInfoFields.split(';');
        }

        return [];
    }

    /**
     * @description Return the layout item size (study pathway)
     */
    get spwtInfoFieldSize() {
        return getColumnSize(this.spwtInfoFields?.length, 2);
    }

}