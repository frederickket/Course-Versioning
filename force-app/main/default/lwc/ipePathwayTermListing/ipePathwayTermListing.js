/**
 * @Author 		WDCi (Lean)
 * @Date 		Oct 2023
 * @group 		Enrollment Wizard
 * @Description Student enrollment wizard
 * @changehistory
 * ISS-001752 05-10-2022 Lean - new component
 * ISS-002328 10-03-2025 XW - fixed bug where study offering might not be shown if same ips group appears on different term
 * ISS-002345 21-03-2025 XiRouh - Added masterIndividualPeId param and pass to c-ipe-pathway-term-group
 * ISS-002336 24-03-2024 Lean - Added missed/failed unit
 */
import { LightningElement, api, wire, track } from 'lwc';
import { promptInfo, promptError, promptWarning, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';
import { customLabels } from 'c/labelLoader';
import { ipePathwayConstants } from 'c/ipePathwaysHelper';
import { initCacheIdx } from 'c/lwcUtil';

import { refreshApex } from '@salesforce/apex';
import { registerRefreshHandler, unregisterRefreshHandler } from 'lightning/refresh';

//Apex methods
 import ctrlGetIpe from '@salesforce/apex/REDU_IpePathwayTermListing_LCTRL.getIndividualProgramEnrollment';

export default class IpePathwayTermListing extends LightningElement {
	
	//configurable attributes
    @api masterIndividualPeId; //ISS-002345
    @api individualPeId;
    @api individualPathwayId;
    @api ipwAcademicTermId;

    @api userMode;
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
    @api preEnrollEnrollmentStatus;
    @api withdrawPreEnrollButtonIconName;
    @api withdrawPreEnrollButtonLabel;
    @api withdrawPreEnrollEnrollmentStatus;
    @api enrollButtonIconName;
    @api enrollButtonLabel;
    @api enrollEnrollmentStatus;
    @api unenrollButtonIconName;
    @api unenrollButtonLabel;
    @api unenrollEnrollmentStatus;
    @api unenrollRequestButtonIconName;
    @api unenrollRequestButtonLabel;
    @api unenrollRequestEnrollmentStatus;
    @api waitlistButtonIconName;
    @api waitlistButtonLabel;
    @api waitlistEnrollmentStatus;
    @api withdrawWaitlistButtonIconName;
    @api withdrawWaitlistButtonLabel;
    @api withdrawWaitlistEnrollmentStatus;

    //configurable attributes - request reattempt settings
    @api requestAttemptMax = 3;
    @api requestAttemptWaitingTime = 5; //in seconds
    
    //custom filters
    @api customFilters;

    @api missedFailedUnitListingOption;

    //configurable attributes - debugging
	@api enableDebugMode = false;
	
	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false;
	loadedLists = 0;
	
    @track ipeWireResult;
    @track ipeResponse;

    //refresh module
    refreshHandlerID;
    _cacheIdx;

	//labels
	label = customLabels;
	
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
     * @descripton rendered callback
     */
	renderedCallback(){

    }

    /**
     * @descripton connected callback
     */
    connectedCallback(){
		this.refreshHandlerID = registerRefreshHandler(this, this.refreshData);
        // this._cacheIdx = initCacheIdx();
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
        // this._cacheIdx = initCacheIdx();

        refreshApex(this.ipeWireResult);

        return new Promise((resolve) => {
            resolve(true);
        });
    }

    /**
     * @description Get individual program enrollment record
     */
    @wire(ctrlGetIpe, { 
        individualPeId: "$individualPeId", 
        individualPathwayId: "$individualPathwayId", 
        titleField: "$ipeTitleField", 
        unitListingMode : "$unitListingMode",
        missedFailedUnitListingOption: "$missedFailedUnitListingOption",
        userMode: "$userMode",
        ipwAcademicTermId: "$ipwAcademicTermId"
        // cacheIdx: "$_cacheIdx"
    })
    wiredRecord(result) {
        
        this.ipeWireResult = result;
        this.ipeResponse = null;

        if (result.data) {
            this.ipeResponse = JSON.parse(result.data.responseData);
            this.consoleLog(this.ipeResponse, true);
        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }

    }

    /**
     * @description Return title
     */
    get title() {
        if (this.isIpeRecordReady && this.ipeResponse.title) {
            return this.ipeResponse.title;
        }

        return '';
    }

    /**
     * @description Return individual program enrollment record
     */
    get ipeRecord() {
        if (this.isIpeRecordReady && this.ipeResponse.ipe) {
            return this.ipeResponse.ipe;
        }

        return null;
    }

    /**
     * @description Return list of top level group individual plan structure
     */
    get groupIpsList() {
        if (this.isIpeRecordReady && this.ipeResponse.topGroupIps) {
            for(let top of this.ipeResponse.topGroupIps) {
                //update the index to trigger rerender
                top.newIndex = top.ips.Id + '_' + this.ipwAcademicTermId + '_' + top.ips.restrictedToUnits;
            }
            return this.ipeResponse.topGroupIps;
        }

        return [];
    }

    /**
     * @description Return true if the ipeResponse is fetched by the wire method
     */
    get isIpeRecordReady() {
        
        if (this.individualPeId && this.ipeResponse) {
            return true;
        }

        return false;
    }

    /**
     * @description Return ipe accordion section name
     */
    get accordionSectionName() {
        return this.individualPeId;
    }

    /**
     * @description Return ipe according default active sections
     */
    get activeSectionName() {
        return [this.individualPeId];
    }

    get ipeResponseForDebugging() {
        return this.enableDebugMode ? JSON.stringify(this.ipeResponse) : null;
    }
	
    /**
     * @descripton Spinner loading status
     */
	get isLoading(){
        return this.loadedLists === 0 && this.isIpeRecordReady ? false : true;
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
        logInfo('ipePathwayTermListing', anything, this.enableDebugMode, isJson);
    }
	
}