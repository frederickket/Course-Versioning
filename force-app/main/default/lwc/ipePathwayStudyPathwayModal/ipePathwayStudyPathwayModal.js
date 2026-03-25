/**
 * @Author 		WDCi (Sueanne)
 * @Date 		Sept 2024
 * @group 		Enrollment Wizard
 * @Description Study Pathway modal for enrollment wizard
 * @changehistory
 * ISS-002124 04-10-2024 Sueanne - new component
 * ISS-002189 13-12-2024 XW - open selected term and preselect minor in study pathway
 * ISS-002330 19-03-2025 XW - display translated spl name (major/minor) if there are any
 */
import {api, wire, track } from 'lwc';
import LightningModal from 'lightning/modal';

import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import { getErrorMessage, logInfo } from 'c/loggingUtil';
import { promptError} from 'c/toasterUtil';
import { customLabels } from 'c/labelLoader';

import { refreshApex } from '@salesforce/apex';
import { RefreshEvent, registerRefreshHandler, unregisterRefreshHandler } from 'lightning/refresh';

import ipePathwayStudyPathwayChangeModal from 'c/ipePathwayStudyPathwayChangeModal';

import CHANGE_PATHWAY_LABEL from '@salesforce/label/c.Change_Pathway';

import ctrlGetIpeList from '@salesforce/apex/REDU_IpePathwayTerm_LCTRL.getIndividualProgramEnrollments';
import ctrlGetTranslationFieldForNameByObjPrefix from '@salesforce/apex/REDU_Translation_LCTRL.getTranslationFieldForNameByObjPrefix';

const STUDY_PLAN_OPTION_FIELDS = [
    'reduivy__Study_Plan_Option__c.Name',
    'reduivy__Study_Plan_Option__c.Id', 
    'reduivy__Study_Plan_Option__c.reduivy__Child_Study_Plan__r.Name',
    'reduivy__Study_Plan_Option__c.reduivy__Child_Study_Plan__r.Id'
];

//wire attributes for querying individual program enrollment
const IPE_FIELDS = [
    "reduivy__Individual_Program_Enrollment__c.Id",
    "reduivy__Individual_Program_Enrollment__c.reduivy__Study_Plan__c",
    "reduivy__Individual_Program_Enrollment__c.reduivy__Study_Pathway__c"
];

const OBJ_TRANSLATION = [
    "SPL"
];

export default class IpePathwayStudyPathwayModal extends LightningModal {

    //configurable attributes
    @api studyPathwayInfoFields;
    @api studyPathwayTermTitlePrefix;
    @api studyPathwayTermInfoFields;
    @api studyPathwayUnitTitleField;
    @api studyPathwayUnitInfoFields; 
    @api studyPathwayUnitIcon;
    @api studyPathwayGroupTitleField;
    @api studyPathwayGroupInfoFields; 
    @api studyPathwayGroupIcon;
    @api studyPathwayShowStudyUnitQuickSearch; //ISS-002189
    @api studyPathwayShowStudyPlanOptions = false;
    @api studyPathwayAccordionBackgroundColor;
    @api studyPathwayAccordionTextColor;
    @api studyPathwayComboboxLabel;
    @api currentTermNumber; //ISS-002189
    @api masterIpeId; //ISS-002189

    @api showChangeStudyPathwayButton = false;

    @api enableDebugMode = false;

    //internal attributes
    @api modalTitle;

	isScriptLoaded = false;
	isInitSuccess = false
	loadedLists = 0;    

    @track hasPathwayChanged = false;

    //wire attribute
    @track objectTranslatedNameResult;
    @track objectTranslatedNameResponse;

    @track ipeListResult;
    @track ipeListResponse;

    @track childStudyPlanOptionsResult;
    @track childStudyPlanOptionsResponse;

    @track masterIpeWireResult;
    @track masterIpeRecord;

    refreshHandlerID;

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
     * @descripton connected callback
     */
    connectedCallback(){
        this.consoleLog('connectedCallback :: ' + this.masterIpeId);
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

        refreshApex(this.masterIpeWireResult);

        return new Promise((resolve) => {
            resolve(true);
        });
    }

    /** ISS-002189
     * @description get master ipe
     */
    @wire(ctrlGetIpeList, {masterIpeId: '$masterIpeId'})
    wiredIpeListResult(result) {
        this.ipeListResult = result;
        if(result.data){
            this.ipeListResponse = JSON.parse(result.data.responseData);
        } else if (result.error) {
            promptError(customLabels.ERROR_LABEL, getErrorMessage(result.error));
        }
    }



    /** ISS-002189
     * @description get child study plan options
     */
    @wire(getRelatedListRecords, {
        parentRecordId: '$masterIpeStudyPlanId',
        relatedListId: 'reduivy__Child_Study_Plan_Options__r',
        fields: '$studyPlanOptionFieldsWithTranslationName',
        where: '$childStudyPlanOptionsFilter'
    })
    wiredChildStudyPlanOptions(result) {
        this.childStudyPlanOptionsResult = result;
        if(result.data){
            this.childStudyPlanOptionsResponse = result.data;
        } else if (result.error){
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
     * @description get study plan option fields to query, and the child study plan translation name
     */
    get studyPlanOptionFieldsWithTranslationName(){
        let fields = STUDY_PLAN_OPTION_FIELDS;
        if(this.splNameTranslationField) {
            fields.push('reduivy__Study_Plan_Option__c.reduivy__Child_Study_Plan__r.' + this.splNameTranslationField);
        }
        return fields;
    }


    /** ISS-002189
     * @description get child study plan options filter
     */
    get childStudyPlanOptionsFilter(){
        let filter = {};
        if(this.ipeListResponse){
            let childStudyPlanIds = [];
            let masterStudyPlanIds = [];

            for(let ipe of this.ipeListResponse){
                if(ipe.reduivy__Master_Enrollment__c) {
                    childStudyPlanIds.push(ipe.reduivy__Study_Plan__c);
                } else {
                    masterStudyPlanIds.push(ipe.reduivy__Study_Plan__c);
                }
            }

            filter.and = [];
            filter.and.push({'reduivy__Master_Study_Plan__c':{in: masterStudyPlanIds}});
            filter.and.push({'reduivy__Child_Study_Plan__c':{in: childStudyPlanIds}});
        }
        
        this.consoleLog('childStudyPlanOptionsFilter');
        this.consoleLog(filter, true);

        return JSON.stringify(filter);
    }

    /** ISS-002189
     * @description preselected spo based on child study plan options
     */
    get preselectedSpo(){
        let result = [];
        if(this.childStudyPlanOptionsResponse){
            for(let spo of this.childStudyPlanOptionsResponse.records) {
                
                let spLabel;
                if(this.splNameTranslationField){
                    spLabel = getFieldValue(spo, spo.apiName + '.reduivy__Child_Study_Plan__r.' + this.splNameTranslationField);
                } 
                if(!spLabel) {
                    spLabel = getFieldValue(spo, spo.apiName + '.reduivy__Child_Study_Plan__r.Name');
                }

                result.push({
                    label: spLabel,
                    id: spo.fields.Id.value,
                    studyPlanId: spo.fields.reduivy__Child_Study_Plan__r.value.fields.Id.value,
                    value: spo.fields.Id.value
                });
            }
        }

        this.consoleLog('preselectedSpo');
        this.consoleLog(result, true);

        return result;
    }
    
    /**
     * @description return the study plan translation field for name
     */
    get splNameTranslationField() {
        return this.objectTranslatedNameResponse?.SPL;
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

    /** ISS-002379 get master ipe study pathway id if this is a child ipe
     * @description Return master ipe study pathway id
     */
    get masterIpeStudyPathwayId(){
        if(this.masterIpeRecord){
            return getFieldValue(this.masterIpeRecord, 'reduivy__Individual_Program_Enrollment__c.reduivy__Study_Pathway__c');
        }

        return null;
    }

    /**
     * @description Return modal title
     */
    get headerLabel() {
        return this.modalTitle;
    }

    /**
     * @description Return loading label
     */
    get loadingLabel() {
        return customLabels.LOADING_LABEL;
    }

    /**
     * @description Close button
     */
    get closeButtonLabel() {
        return customLabels.CLOSE_LABEL;
    }

    /**
     * @description Change pathway button label
     */
    get changePathwayButtonLabel() {
        return CHANGE_PATHWAY_LABEL;
    }

    /**
     * @description Close button css class
     */
    get closeButtonCssClass() {
        return this.showChangeStudyPathwayButton ? 'slds-p-right_xx-small' : '';
    }

    /**
     * @description handle close
     */
    handleCloseClick() {
        
        let closeOpt = this.hasPathwayChanged ? 'closedwithrefresh' : 'closed';
        this.close({
            operation: closeOpt
        });
    }

    /**
     * @description handle change pathway button click
     */
    handleChangePathwayClick() {
        ipePathwayStudyPathwayChangeModal.open({
            size: 'small',
            masterIpeId: this.masterIpeId,
            studyPathwayInfoFields: this.studyPathwayInfoFields,
            enableDebugMode: this.enableDebugMode      
        }).then((result) => {
            
            if (result) {
                this.consoleLog('ipePathwayStudyPathwayChangeModal.close');
                this.consoleLog(result, true);

                const {operation} = result;

                if (operation === 'confirmed') {
                    this.hasPathwayChanged = true;

                    this.dispatchEvent(new RefreshEvent());
                }
            }
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
        logInfo('ipePathwayStudyPathwayModal', anything, this.enableDebugMode, isJson);
    }

}