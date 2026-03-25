/**
 * @Author 		WDCi (Lean)
 * @Date 		Oct 2023
 * @group 		Enrollment Wizard
 * @Description Student enrollment wizard
 * @changehistory
 * ISS-001752 05-10-2022 Lean - new component
 * ISS-002336 24-03-2024 Lean - Added missed/failed unit
 * ISS-002330 20-03-2025 XW - Show Study Term translation name if found
 * ISS-002424 30-04-2025 XiRouh - Added reduivy__Academic_Term__r.reduivy__Display_Name__c to IPW_FIELDS, updated the pathwayTitle getter to use the translated field when it returns a value, otherwise, display name field
 * ISS-002509 09-07-2025 XiRouh - Added individualAcademicProgressInfoFields and individualAcademicProgressInfoColumnNo
 * ISS-002654 03-10-2025 Lean - Column number shared util
 */
import { LightningElement, api, wire, track } from 'lwc';
import { promptInfo, promptError, promptWarning, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';
import { customLabels } from 'c/labelLoader';
import { ipePathwayConstants } from 'c/ipePathwaysHelper';
import { getColumnSize } from 'c/lwcUtil';

import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import { refreshApex } from '@salesforce/apex';
import { RefreshEvent, registerRefreshHandler, unregisterRefreshHandler } from 'lightning/refresh';

import ctrlGetIpeList from '@salesforce/apex/REDU_IpePathwayTerm_LCTRL.getIndividualProgramEnrollments';
import ctrlGetTranslationFieldForNameByObjPrefix from '@salesforce/apex/REDU_Translation_LCTRL.getTranslationFieldForNameByObjPrefix';

//additional labels
import VIEWTERM_LABEL from '@salesforce/label/c.View_Term';
import SELECTERM_LABEL from '@salesforce/label/c.Select_Term';
import VIEWRESULT_LABEL from '@salesforce/label/c.View_Result';
import SELECTTERM_DESC_LABEL from '@salesforce/label/c.Select_An_Academic_Term_to_Start';
import CONFIRM_ENROLLMENT_LABEL from '@salesforce/label/c.Confirm_Enrollment';

//term selection modal
import ipePathwayTermSelection from 'c/ipePathwayTermSelection';

//wire attributes for querying individual pathway using getRecord
const IPW_FIELDS = [
    "reduivy__Individual_Pathway__c.Id",
    "reduivy__Individual_Pathway__c.Name", 
    "reduivy__Individual_Pathway__c.reduivy__Individual_Academic_Progress__c", 
    "reduivy__Individual_Pathway__c.reduivy__Individual_Program_Enrollment__c", 
    "reduivy__Individual_Pathway__c.reduivy__Status__c", 
    "reduivy__Individual_Pathway__c.reduivy__Academic_Term__c",
    "reduivy__Individual_Pathway__c.reduivy__Academic_Term__r.reduivy__Display_Name__c"
];

const OBJ_TRANSLATION = [
    "STM"
];

export default class IpePathwayTerm extends LightningElement {
	
	//configurable attributes
    @api masterIpeId;
    @api individualPathwayId;
    @api individualPathwayInfoFields;
    @api individualPathwayInfoColumnNo = 4;
    @api individualAcademicProgressInfoFields;
    @api individualAcademicProgressInfoColumnNo = 4;
    @api userMode; //supported options: Admin, Student
    @api unitListingMode;
    @api campusId;
    @api accordionBackgroundColor;
    @api accordionTextColor;

    //configurable attributes - ipe, ips group title and unit table fields
    @api ipeTitleField;
    @api ipsGroupTitleField;
    @api showIpsGroupInfo = false;
    @api ipsGroupInfoFields;
    @api ipsGroupInfoColumnNo = 4;   
    @api ipsUnitTableFields;

    //configurable attributes - view info fields
    @api studyUnitQuickSearchValue; //ISS-002188
    @api studyUnitInfoFields;
    @api studyOfferingInfoFields;
    @api studyPlanStructureUnitInfoFields;

    //configurable attributes - enrollment button icon and label
    @api showEnrollmentButtons = false;
    @api preEnrollButtonIconName;
    @api preEnrollButtonLabel;
    @api preEnrollEnrollmentStatus
    @api withdrawPreEnrollButtonIconName;
    @api withdrawPreEnrollButtonLabel;
    @api withdrawPreEnrollEnrollmentStatus
    @api enrollButtonIconName;
    @api enrollButtonLabel;
    @api enrollEnrollmentStatus
    @api unenrollButtonIconName;
    @api unenrollButtonLabel;
    @api unenrollEnrollmentStatus
    @api unenrollRequestButtonIconName;
    @api unenrollRequestButtonLabel;
    @api unenrollRequestEnrollmentStatus
    @api waitlistButtonIconName;
    @api waitlistButtonLabel;
    @api waitlistEnrollmentStatus
    @api withdrawWaitlistButtonIconName;
    @api withdrawWaitlistButtonLabel;
    @api withdrawWaitlistEnrollmentStatus

    //configurable attributes - request reattempt settings
    @api requestAttemptMax = 3;
    @api requestAttemptWaitingTime = 5; //in seconds
    
    //custom filters
    @api customFilters;

    @api missedFailedUnitListingOption;

    @api showEnrollmentFinalizationButton = false;

    //configurable attributes - debugging
	@api enableDebugMode = false;
	
	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false;
	loadedLists = 0;
	
    @track ipwWireResult = [];
    @track ipwRecord = null;

    @track ipeListWireResult = [];
    @track ipeList = [];

    @track objectTranslatedNameResult;
    @track objectTranslatedNameResponse;

    refreshHandlerID;

	//labels
	label = {
        ...customLabels, 
        VIEWRESULT_LABEL, 
        VIEWTERM_LABEL, 
        SELECTERM_LABEL,
        SELECTTERM_DESC_LABEL
    };
    
	
	//js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'tooltips'
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
        this.consoleLog('renderedCallback :: ' + this.individualPathwayId);
    }

    /**
     * @descripton connected callback
     */
    connectedCallback(){
        this.consoleLog('connectedCallback :: ' + this.individualPathwayId);
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

        refreshApex(this.ipwWireResult);
        refreshApex(this.ipeListWireResult);

        return new Promise((resolve) => {
            resolve(true);
        });
    }

    /**
     * @description Get individual pathway record
     */
    @wire(getRecord, { recordId: "$individualPathwayId", fields: "$ipePathwayQueryFields"})
    wiredRecord(result) {
        
        this.ipwWireResult = result;
        this.ipwRecord = null;

        if (result.data) {
            this.ipwRecord = result.data;

            this.consoleLog(this.ipwRecord, true);
            
        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    /**
     * @description Return ipe pathway fields for query
     */
    get ipePathwayQueryFields() {
        
        let fields;
        if (this.stmNameTranslationField) {
            fields = IPW_FIELDS;
            fields.push('reduivy__Individual_Pathway__c.reduivy__Academic_Term__r.' + this.stmNameTranslationField);
        }

        return fields;
    }

    /**
     * @description Get object translation record
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
     * @description Return a list of individual pathway fields
     */
    get ipwInfoFields() {
        if (this.individualPathwayInfoFields) {
            return this.individualPathwayInfoFields.split(';');
        }

        return [];
    }

    /**
     * @description Return if the individual pathway info fields are set
     */
    get hasIpwInfoFields() {
        return this.ipwInfoFields && this.ipwInfoFields.length > 0;
    }

    /**
     * @description Return the individual pathway info field layout item size
     */
    get ipwInfoFieldSize() {
        return getColumnSize(this.individualPathwayInfoColumnNo, 4);
    }

    /**
     * @description Return a list of individual academic progress fields
     */
    get iprInfoFields() {
        if (this.individualAcademicProgressInfoFields) {
            return this.individualAcademicProgressInfoFields.split(';');
        }

        return [];
    }

    /**
     * @description Return if the individual academic progress info fields are set
     */
    get hasIprInfoFields() {
        return this.iprInfoFields && this.iprInfoFields.length > 0;
    }

    /**
     * @description Return the individual academic progress field layout item size
     */
    get iprInfoFieldSize() {
        return getColumnSize(this.individualAcademicProgressInfoColumnNo, 4);
    }

    /**
     * @description Return true if the individual pathway status is Completed
     */
    get isTermCompleted() {
        if (this.isIpwRecordReady && getFieldValue(this.ipwRecord, 'reduivy__Individual_Pathway__c.reduivy__Status__c') === ipePathwayConstants.IPW_STATUS_COMPLETED) {
            return true;
        }

        return false;
    }

    /**
     * @description Return true if the individual pathway status is Current
     */
    get isTermInProgress() {
        if (this.isIpwRecordReady && getFieldValue(this.ipwRecord, 'reduivy__Individual_Pathway__c.reduivy__Status__c') === ipePathwayConstants.IPW_STATUS_CURRENT) {
            return true;
        }
        
        return false;
    }

    /**
     * @description Return true if the individual pathway status is Future
     */
    get isTermFuture() {
        if (this.isIpwRecordReady && getFieldValue(this.ipwRecord, 'reduivy__Individual_Pathway__c.reduivy__Status__c') === ipePathwayConstants.IPW_STATUS_FUTURE) {
            return true;
        }
        
        return false;
    }

    /**
     * @description Return true if the individual pathway's academic term is selected
     */
    get hasTermSelected() {
        let academicTermId = this.ipwAcademicTermId;

        if (this.isIpwRecordReady && academicTermId &&
            // ISS-002743 this check is to ensure that the listing component is not rendered when the term tile is changed 
            // and the ipwRecord is still not refresh by the wire method
            this.individualPathwayId === this.ipwId 
        ) {
            return true;
        }
        
        return false;
    }

    /**
     * @description Return individual pathway id
     */
    get ipwId() {
        return getFieldValue(this.ipwRecord, 'reduivy__Individual_Pathway__c.Id');
    }

    /**
     * @description Return selected term id for the current pathway
     */
    get ipwAcademicTermId() {
        return getFieldValue(this.ipwRecord, 'reduivy__Individual_Pathway__c.reduivy__Academic_Term__c');
    }

    /**
     * @description Return individual academic progress id for the current pathway
     */
    get ipwIndividualAcademicProgressId() {
        return getFieldValue(this.ipwRecord, 'reduivy__Individual_Pathway__c.reduivy__Individual_Academic_Progress__c');
    }

    /**
     * @description Confirm enrollment button label
     */
    get finalizeEnrollmentButtonLabel() {
        return CONFIRM_ENROLLMENT_LABEL;
    }

    /**
     * @description Return component title
     */
    get pathwayTitle() {
        if (this.isScriptLoaded) {
            this.consoleLog('pathwayTitle');

            if (this.isIpwRecordReady ) {
                let termName;

                if(this.stmNameTranslationField) {
                    termName = getFieldValue(this.ipwRecord, 'reduivy__Individual_Pathway__c.reduivy__Academic_Term__r.' + this.stmNameTranslationField);
                } 

                if(!termName) {
                    termName = getFieldValue(this.ipwRecord, 'reduivy__Individual_Pathway__c.reduivy__Academic_Term__r.reduivy__Display_Name__c');
                }

                this.consoleLog(termName);
                return termName;
            }

            return this.label.SELECTTERM_DESC_LABEL.format([this.label.ACADEMICTERM_LABEL]);

        }

        return '';
    }

    /**
     * @description Return individual program enrollment id
     */
    get individualPeId() {
        let ipeId = getFieldValue(this.ipwRecord, 'reduivy__Individual_Pathway__c.reduivy__Individual_Program_Enrollment__c');
        if (this.isIpwRecordReady && ipeId) {
            return ipeId;
        }

        return null;
    }

    /**
     * @description Return the translation field for name
     */
    get stmNameTranslationField() {
        return this.objectTranslatedNameResponse?.STM;
    }

    /**
     * @description Return true if the ipwRecord is fetched by the wire method
     */
    get isIpwRecordReady() {
        if (this.individualPathwayId && this.ipwRecord && this.ipwRecord.fields) {
            return true;
        }

        return false;
    }

    /**
     * @description Return calculated show enrollment action buttons
     */
    get canPerformEnrollmentActions() {
        return this.showEnrollmentButtons && !this.isTermCompleted;
    }

    /**
     * @description Handle select term button click
     */
    handleSelectTermOnclick(event) {

        ipePathwayTermSelection.open({
            size: 'small',
            individualPathwayId: this.individualPathwayId,
            individualPeId: this.individualPeId,
            userMode: this.userMode,
            enableDebugMode: this.enableDebugMode
        }).then((result) => {
            if (result && result.operation === 'confirm') {
                this.consoleLog('handleSelectTermOnclick.close');
                this.consoleLog(result, true);
                
                this.dispatchEvent(new RefreshEvent());

            }
        });

    }

    /**
     * @description Return a list of master and child individual program enrollment based on master individual program enrollment id
     */
    @wire(ctrlGetIpeList, {masterIpeId: '$masterIpeId', ipwAcademicTermId: "$ipwAcademicTermId"})
    wireIpeList( result ) {
        this.ipeListWireResult = result;
        this.ipeList = [];

        if (result.data) {
            let response = result.data;
            if (response.responseData) {
                this.ipeList = JSON.parse(response.responseData);
            }
            this.consoleLog(this.ipeList, true);
            
        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    /**
     * @description Handle finalize enrollment onclick
     */
    handleFinalizeEnrollmentOnClick(event) {
        this.dispatchEvent(new CustomEvent("finalize", {
            detail: {
                individualPathwayId: this.individualPathwayId,
                masterIpeId: this.masterIpeId,
                individualAcademicProgressId: this.ipwIndividualAcademicProgressId
            }
        }));
    }

    /**
     * @descripton Spinner loading status
     */
	get isLoading(){
        return this.loadedLists === 0 && this.ipwRecord ? false : true;
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
        logInfo('ipePathwayTerm', anything, this.enableDebugMode, isJson);
    }
	
}