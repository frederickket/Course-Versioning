/**
 * @Author 		WDCi (Sueanne)
 * @Date 		Sept 2024
 * @group 		Enrollment Wizard
 * @Description to render study sessions in session enrollment wizard
 * @changehistory
 * ISS-002050 13-09-2024 Sueanne - new component
 * ISS-002330 20-03-2025 XW - Show Study Session translation name if found
 * ISS-002401 22-04-2025 Lean - Respect the allow enrollment config from enrollment action status
 */
import { LightningElement, api, wire, track } from 'lwc';
import { promptInfo, promptError, promptWarning, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';
import { customLabels } from 'c/labelLoader';

import { refreshApex } from '@salesforce/apex';
import { registerRefreshHandler, unregisterRefreshHandler } from 'lightning/refresh';

//Apex methods
import ctrlGetStudySessions from '@salesforce/apex/REDU_IpePathwayStudySessions_LCTRL.getStudySessions';
import ctrlGetTranslationFieldForNameByObjPrefix from '@salesforce/apex/REDU_Translation_LCTRL.getTranslationFieldForNameByObjPrefix';

const OBJ_TRANSLATION = [
    "SSE"
];

export default class IpePathwayStudySessions extends LightningElement {
    
    //configurable attributes
    @api userMode;
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
    modules = ['lodash'];

    //internal attributes
    @api masterIpeId;
    @api individualPathwayId;
    @api studyOfferingId;
    @api individualEnrollmentId;
    @api contactId;
    
    isScriptLoaded = false;
	isInitSuccess = false;
	loadedLists = 0;
    refreshHandlerID;

    sseWireResult;
    sseWireRecord;

    @track objectTranslatedNameResult;
    @track objectTranslatedNameResponse;

    //labels
	label = customLabels;

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
     * @description Refresh data
     */
    refreshData() {
        this.consoleLog('refreshData');

        refreshApex(this.sseWireResult);

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
        logInfo('ipePathwayStudySessions', anything, this.enableDebugMode, isJson);
    }

    @wire(ctrlGetStudySessions, {studyOfferingId: "$studyOfferingId"})
    wiredStudySessionRecord(result){
        
        this.sseWireResult = result;
        this.sseWireRecord = null;

        if (result.data) {
            this.sseWireRecord = JSON.parse(result.data.responseData);
            this.consoleLog(this.sseWireRecord, true);
            
        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    /**
     * @description Get Study Session Translation
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
     * @description return the study plan translation field for name
     */
    get sseNameTranslationField() {
        return this.objectTranslatedNameResponse?.SSE;
    }

    /**
     * @description Return sorted session list
     */
    get sortedSseList() {
        let orderByName = this.sseNameTranslationField ? this.sseNameTranslationField : 'Name'
        this.sseWireRecord = _.orderBy(this.sseWireRecord, [orderByName, 'reduivy__Start_Date_Calculated__c'], ['asc', 'asc']);

        return this.sseWireRecord;
    }
}