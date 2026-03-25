/**
 * @Author 		WDCi (Sueanne)
 * @Date 		Sept 2024
 * @group 		Enrollment Wizard
 * @Description session enrollment wizard
 * @changehistory
 * ISS-002050 13-09-2024 Sueanne - new component
 * ISS-002330 20-03-2025 XW - move study offering accordion to ipePathwayStudySessionEnrollmentSof
 * ISS-002401 22-04-2025 Lean - Respect the allow enrollment config from enrollment action status
 */
import { LightningElement, api, wire, track } from 'lwc';
import { promptInfo, promptError, promptWarning, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';
import { customLabels } from 'c/labelLoader';
import { getRecord } from "lightning/uiRecordApi";

import { refreshApex } from '@salesforce/apex';
import { registerRefreshHandler, unregisterRefreshHandler } from 'lightning/refresh';

//Apex methods
import ctrlGetStudyOfferings from '@salesforce/apex/REDU_IpePathwaySessionEnrollment_LCTRL.getStudyOfferings';
import ctrlGetTranslationFieldForNameByObjPrefix from '@salesforce/apex/REDU_Translation_LCTRL.getTranslationFieldForNameByObjPrefix';

//wire attributes for querying individual pathway using getRecord
const IPE_FIELDS = [
    "reduivy__Individual_Program_Enrollment__c.reduivy__Contact__c"
];

const OBJ_TRANSLATION = [
    "SOF"
];


export default class IpePathwayStudySessionEnrollment extends LightningElement {

    //configurable attributes
    @api userMode;
    @api studyOfferingAccordionBackgroundColor;
    @api studyOfferingAccordionTextColor;
    @api studyOfferingTitleField;
    @api studyOfferingInfoFields;
    @api studySessionTitleField;
    @api studySessionInfoFields;
    @api studySessionIcon;
    @api studySessionTimeTitleField;
    @api studySessionTimeInfoFields;
    @api studySessionTimeIcon;
    @api showStudySessionTimeFieldLabel;

    //configurable attributes - enrollment button icon and label
    @api showEnrollmentButtons = false; //ISS-002401
    @api preEnrollButtonIconName;
    @api preEnrollButtonLabel;
    @api withdrawPreEnrollButtonIconName;
    @api withdrawPreEnrollButtonLabel;
    @api enrollButtonIconName;
    @api enrollButtonLabel;
    @api unenrollButtonIconName;
    @api unenrollButtonLabel;
    @api waitlistButtonIconName;
    @api waitlistButtonLabel;
    @api withdrawWaitlistButtonIconName;
    @api withdrawWaitlistButtonLabel;

    //configurable attributes - request reattempt settings
    @api requestAttemptMax = 3;
    @api requestAttemptWaitingTime = 5; //in seconds

    //configurable attributes - debugging
	@api enableDebugMode = false;

    //js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'tooltips'
    modules = ['lodash', 'stringutil'];

    //internal attributes
    @api masterIpeId;
    @api individualPathwayId;
    isScriptLoaded = false;
	isInitSuccess = false;
	loadedLists = 0;
    refreshHandlerID;

    sofWireResult;
    sofWireRecord;
    ipeWireResult;
    ipeWireRecord;
    @track objectTranslatedNameResult;
    @track objectTranslatedNameResponse;

    //labels
	label = customLabels;

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

        refreshApex(this.sofWireResult);

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
        logInfo('ipePathwayStudySessionEnrollment', anything, this.enableDebugMode, isJson);
    }

    /**
     * @description Get individual program enrollment record
     */
    @wire(getRecord, { recordId: "$masterIpeId", fields: IPE_FIELDS })
    wiredRecord(result) {
        
        this.ipeWireResult = result;
        this.ipeWireRecord = null;

        if (result.data) {
            this.ipeWireRecord = result.data;
            this.consoleLog(this.ipeWireRecord, true);
            
        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }

    }

    
    /**
     * @description Get Study Offering Translation
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
     * @description Return contact id
     */
    get contactId(){
        if(this.ipeWireRecord && this.ipeWireRecord.fields.reduivy__Contact__c){
            return this.ipeWireRecord.fields.reduivy__Contact__c.value;
        }

        return null;
    }

    /**
     * @description Get study offerings record
     */
    @wire(ctrlGetStudyOfferings, { masterIpeId: "$masterIpeId", individualPathwayId: "$individualPathwayId", studyOfferingTitleField: "$studyOfferingTitleField" })
    wiredStudyOfferingRecord(result) {
        
        this.sofWireResult = result;
        this.sofWireRecord = null;

        if (result.data) {
            this.sofWireRecord = JSON.parse(result.data.responseData);
            this.consoleLog(this.sofWireRecord, true);
            
        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }

    }

    get ienIdSofList(){
        let ienIdSofArray = [];
    
        if (this.sofWireRecord) {
            for(let [key, value] of Object.entries(this.sofWireRecord)){
                ienIdSofArray.push({ ienId: key, sof: value });
            }
        }

        let orderByName = this.sofNameTranslationField ? 'sof.' + this.sofNameTranslationField : 'sof.Name';

        ienIdSofArray = _.orderBy(ienIdSofArray, [orderByName, 'sof.reduivy__Start_Date_Calculated__c'], ['asc', 'asc']);
        
        return ienIdSofArray;
    }

    /**
     * @description return the study offering translation field for name
     */
    get sofNameTranslationField() {
        return this.objectTranslatedNameResponse?.SOF;
    }
    
}