/**
 * @Author 		WDCi (Lean)
 * @Date 		Oct 2023
 * @group 		Enrollment Wizard
 * @Description Student enrollment wizard
 * @changehistory
 * ISS-001752 05-10-2022 Lean - new component
 * ISS-002230 22-01-2025 XW - replace hardcoded label to custom label
 * ISS-002345 21-03-2025 XiRouh - Added masterIndividualPeId param and pass to c-ipe-pathway-term-group and c-ipe-pathway-term-unit-table 
 * ISS-002336 24-03-2024 Lean - Added missed/failed unit
 * ISS-002654 03-10-2025 Lean - Column number shared util
 */
import { LightningElement, api, wire, track } from 'lwc';
import { promptInfo, promptError, promptWarning, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';
import { shadeHexColorCode } from 'c/cssUtil';
import { customLabels } from 'c/labelLoader';
import { getColumnSize } from 'c/lwcUtil';

import { refreshApex } from '@salesforce/apex';
import { registerRefreshHandler, unregisterRefreshHandler } from 'lightning/refresh';

//Apex methods
import ctrlGetIpsGroup from '@salesforce/apex/REDU_IpePathwayTermGroup_LCTRL.getIndividualPlanStructureGroup';

import IPS_GROUP_TITLE_WITH_DESC_LABEL  from '@salesforce/label/c.IPE_Pathway_IPS_Group_Title_With_Desc'

export default class IpePathwayTermGroup extends LightningElement {
	
	//configurable attributes
    @api masterIndividualPeId; //ISS-002345
    @api individualPeId;
    @api individualPlanStructureGroupId;
    @api individualPathwayId;
    @api ipwAcademicTermId;

    @api userMode;
    @api studyUnitQuickSearchValue; //ISS-002188
    @api unitListingMode;
    @api campusId;
    @api restrictedToUnits; //Restrict the listing to the specified usits when viewing in pathway mode
    @api accordionBackgroundColor;
    @api accordionTextColor;
    @api description;

    //configurable attributes - ipe, ips group title and unit table fields
    @api ipsGroupTitleField;
    @api showIpsGroupInfo = false;
    @api ipsGroupInfoFields;
    @api ipsGroupInfoColumnNo = 4;    
    @api ipsUnitTableFields;

    //configurable attributes - view info fields
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

    //configurable attributes - debugging
	@api enableDebugMode = false;
	
	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false;
	loadedLists = 0;
	
    ipsGroupWireResult;
    ipsGroupResponse;

    refreshHandlerID;
    _cacheIdx;

	//labels
	label = customLabels;
	
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

        refreshApex(this.ipsGroupWireResult);

        return new Promise((resolve) => {
            resolve(true);
        });
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
     * @description Get individual plan structure group record
     */
    @wire(ctrlGetIpsGroup, {
        individualPeId: "$individualPeId", 
        individualPlanStructureGroupId: "$individualPlanStructureGroupId", 
        userMode: "$userMode",
        titleField: "$ipsGroupTitleField",
        tableFields: "$ipsUnitTableFields",
        ipwAcademicTermId: "$ipwAcademicTermId"
        // cacheIdx: "$_cacheIdx"
    })
    wiredRecord(result) {
        
        this.ipsGroupWireResult = result;
        this.ipsGroupResponse = null;

        if (result.data) {
            this.ipsGroupResponse = JSON.parse(result.data.responseData);
            this.consoleLog(this.ipsGroupResponse, true);
        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }

    }

    /**
     * @description Return a list of individual pathway fields
     */
    get infoFields() {
        if (this.ipsGroupInfoFields) {
            return this.ipsGroupInfoFields.split(';');
        }

        return [];
    }

    /**
     * @description Return the layout item size
     */
    get infoFieldSize() {
        return getColumnSize(this.ipsGroupInfoColumnNo, 4);
    }

    /**
     * @description Return true if has restricted units
     */
    get hasRestrictedUnits() {
        if (this.restrictedToUnits && this.restrictedToUnits.length > 0) {
            return true;
        }

        return false;
    }

    /**
     * @description Return list of child individual plan structure groups
     */
    get childGroups() {
        if (this.isIpsGroupRecordReady && this.ipsGroupResponse.childGroupsIps) {
            return this.ipsGroupResponse.childGroupsIps;
        }

        return null;
    }

    /**
     * @description Return true if the current individual plan structure group has more child groups
     */
    get hasChildGroups() {
        if (this.isIpsGroupRecordReady && this.ipsGroupResponse.childGroupsIps) {
            return true;
        }

        return false;
    }

    /**
     * @description Return individual plan structure group record
     */
    get ipsRecord() {
        if (this.isIpsGroupRecordReady && this.ipsGroupResponse.ips) {            
            return this.ipsGroupResponse.ips;
        }

        return null;
    }

    /**
     * @description Return title
     */
    get title() {
        if (this.isIpsGroupRecordReady && this.ipsGroupResponse.title) {
            let addDesc = this.description;
            if(addDesc) {
                return IPS_GROUP_TITLE_WITH_DESC_LABEL.format([this.ipsGroupResponse.title, addDesc]);
            }
            return this.ipsGroupResponse.title;
        }

        return '';
    }

    /**
     * @description Return true if the ipsGroupResponse is fetched by the wire method
     */
    get isIpsGroupRecordReady() {
        
        if (this.individualPlanStructureGroupId && this.ipsGroupResponse) {
            return true;
        }

        return false;
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
        return this.individualPlanStructureGroupId;
    }

    /**
     * @description Return ipe according default active sections
     */
    get activeSectionName() {
        return [this.individualPlanStructureGroupId];
    }
	
    /**
     * @descripton Spinner loading status
     */
	get isLoading(){
        return this.loadedLists === 0 && this.isIpsGroupRecordReady ? false : true;
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
        logInfo('ipePathwayTermGroup', anything, this.enableDebugMode, isJson);
    }
	
}