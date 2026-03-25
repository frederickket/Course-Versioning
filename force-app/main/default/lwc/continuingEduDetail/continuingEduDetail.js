/**
 * @Author 		WDCi (Jordan)
 * @Date 		Feb 2024
 * @group 		Continuing Education
 * @Description Lwc for continuing education detail
 * @changehistory
 * ISS-001846 21-02-2024 Jordan - new lwc
 */

import { LightningElement, api, track } from 'lwc';
import { promptInfo, promptError, promptWarning, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';
import { customLabels } from 'c/labelLoader';

import getObjectFields from '@salesforce/apex/REDU_ContinuingEduDetail_LCTRL.getObjectFields';

export default class ContinuingEduDetail extends LightningElement {
    //Target Configs property
    @api objectApiName;
    @api recordId;
    @api showTitle = false;
    @api title;
    @api showIcon = false;
    @api iconName;
    @api fieldNames;
    @api showFieldLabel = false;
    @api showBackgroundBorder = false;
    @api enableDebugMode = false;

    //internal attributes
	isScriptLoaded = false;
	isInitSuccess = false;
	loadedLists = 0;

    @track fieldsArray;
    @track label = {
        ...customLabels
    };

    //js library module 'lodash', 'stringutil', 'noheadercss', 'continuingeducss', 'moment', 'fullcalendar', 'fcmoment', 'tooltips'
    modules = ['continuingeducss'];
	
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

    //This method is used to captured values(field label and field api name) coming from backend.
    connectedCallback() {
        this.consoleLog(this.objectApiName);
        this.consoleLog(this.recordId);
        
        this.doInit();
    }

    renderedCallback() {
        
    }

    doInit() {
        this.consoleLog('doInit');
        
        this.toggleSpinner(1);

        getObjectFields({
            sObjectName: this.objectApiName, recordId: this.recordId, fieldNames: this.fieldNames
        }).then(result => {
            this.toggleSpinner(-1);

            if (result.isSuccess && result.responseData) {
                
                this.fieldsArray = JSON.parse(result.responseData);
                
                this.consoleLog(this.fieldsArray, true);
                
            } else if (!result.isSuccess) {
                promptError(this.label.ERROR_LABEL, result.message);
            }
            
        }).catch(error => {
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
            this.toggleSpinner(-1);
            
        });
    }

    get divBlockCss() {
        if (this.showBackgroundBorder) {
            return 'slds-grid slds-box';
        }

        return 'slds-grid slds-gutters';
    }

    /**
     * @description return fields for view from
     */
    get infoFields(){
        if(this.fieldsArray){
            return this.fieldsArray.map(field => field.fieldName);
        }
        return null;
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

    consoleLog(anything, isJson) {
        logInfo('continuingEduDetails', anything, this.enableDebugMode, isJson);
    }
}