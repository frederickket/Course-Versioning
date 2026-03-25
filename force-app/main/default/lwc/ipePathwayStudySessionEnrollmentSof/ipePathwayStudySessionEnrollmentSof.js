/**
 * @Author 		WDCi (XW)
 * @Date 		Mar 2025
 * @group 		
 * @Description 
 * @changehistory
 * ISS-002330 21-03-2025 XW - new class
 * ISS-002401 22-04-2025 Lean - Respect the allow enrollment config from enrollment action status
 */
import { LightningElement, api, track } from 'lwc';
import { logInfo } from 'c/loggingUtil';
import { customLabels } from 'c/labelLoader';
import { extractFieldValue } from 'c/lwcUtil';

export default class IpePathwayStudySessionEnrollmentSof extends LightningElement {
	
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

	@api enableDebugMode = false;
	
	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false
	loadedLists = 0;
	
    //internal attributes
    @api set sofObj(val) {
        this._sofObj = JSON.parse(JSON.stringify(val));
    }

    get sofObj() {
        return this._sofObj;
    }
    
    @api masterIpeId;
    @api individualPathwayId;
    @api individualEnrollmentId;
    @api contactId;
    
    @track _sofObj;

    //local cache idx to force rerendering
    _cacheIdx;

	//labels
	label = customLabels;
	
	//js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'jquery', 'tooltips'
    modules = ['lodash', 'stringutil'];
	
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
     * @description Update css var
     */
    updateCssVars() {
        let css = this.template.host.style;
        css.setProperty('--accordion-background-color', this.studyOfferingAccordionBackgroundColor);
        css.setProperty('--accordion-text-color', this.studyOfferingAccordionTextColor);
    }

    /**
     * @description Return a list of study offering fields
     */
    get infoFields() {
        if(this.studyOfferingInfoFields){
            return this.studyOfferingInfoFields.split(';');
        }
        return [];
    }

    /**
     * @description Return study offering title value
     */
    get sofTitle() {
        if (this.studyOfferingTitleField) {
            return extractFieldValue(this.sofObj, this.studyOfferingTitleField);
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
	
    /**
     * @descripton Console log for debugging
     */
	consoleLog(anything, isJson){
        logInfo('IpePathwayStudySessionEnrollmentSof', anything, this.enableDebugMode, isJson);
    }
	
}