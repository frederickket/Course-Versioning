/**
 * @Author 		WDCi (Lean)
 * @Date 		Sept 2023
 * @group 		Enrollment Wizard
 * @Description Student enrollment wizard
 * @changehistory
 * ISS-001752 03-10-2022 Lean - new component
 * ISS-001924 21-05-2024 Sueanne - Major/Minor Enrollment
 * ISS-002036 26-07-2024 Sueanne - updated fields default value
 * ISS-002050 13-09-2024 Sueanne - added study session enrollment
 * ISS-002124 04-10-2024 Sueanne - added study pathway
 * ISS-002188 12-12-2024 XW - moved filter component to filter panel
 * ISS-002189 13-12-2024 XW - open selected term in study pathway & show study unit quick search
 * ISS-002336 24-03-2024 Lean - Added missed/failed unit
 * ISS-002330 20-03-2025 XW - Show Campus translation name if found
 * ISS-002401 21-04-2025 Lean - Added enrollment action status button and logic
 * ISS-002416 23-04-2025 XiRouh - Moved the individual pathway term buttons into child component
 * ISS-002421 30-04-2025 XW - Replace RefreshHandler with RefreshContainer
 * ISS-002436 05-05-2025 XW - added "withdraw from term" feature
 * ISS-002459 13-05-2025 Lean - Disable enrollment when IPE is not In Progress
 * ISS-002509 09-07-2025 XiRouh - Added individualAcademicProgressInfoFields and individualAcademicProgressInfoColumnNo
 * ISS-002739 21-11-2025 Lean - Fixed pathway visualizer to dipslay the correct IPE pathway
 * ISS-002740 15-01-2025 Lean - Allow users to change pathway
 */
import { LightningElement, api, wire, track } from 'lwc';
import { promptInfo, promptError, promptWarning, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';
import { customLabels } from 'c/labelLoader';
import { calendarLabels } from 'c/calendarHelper';
import { ipePathwayConstants } from 'c/ipePathwaysHelper';

import { getRecord, getFieldValue } from "lightning/uiRecordApi";

import { refreshApex } from '@salesforce/apex';
import { RefreshEvent, registerRefreshContainer, unregisterRefreshContainer } from 'lightning/refresh';

import genericConfirmationModal from 'c/genericConfirmationModal';
import ipePathwayHelpModal from 'c/ipePathwayHelpModal';
import ipePathwayChildEnrollmentModal from 'c/ipePathwayChildEnrollmentModal';
import ipePathwayStudyPathwayModal from 'c/ipePathwayStudyPathwayModal';
import ipePathwayLockingModal from 'c/ipePathwayLockingModal';
import ipePathwayWithdrawFromTermModal from 'c/ipePathwayWithdrawFromTermModal';
import ipePathwayEnrollmentFinalizeModal from 'c/ipePathwayEnrollmentFinalizeModal';

import ADD_NEW_PATHWAY_LABEL from '@salesforce/label/c.Add_New_Pathway';
import ADD_NEW_PATHWAY_CONFIRMATION_LABEL from '@salesforce/label/c.Add_New_Pathway_Confirmation';
import UNIT_LISTING_ALL_LABEL from '@salesforce/label/c.Unit_Listing_All';
import UNIT_LISTING_PATHWAY_LABEL from '@salesforce/label/c.Unit_Listing_Pathway';
import LISTING_MODE_LABEL from '@salesforce/label/c.Listing_Mode';
import PLEASE_ADD_PATHWAY_TO_START_LABEL from '@salesforce/label/c.Please_add_Pathway_To_Start';
import ENROLLMENT_CONFIRMATION_LABEL from '@salesforce/label/c.Child_IPE_Enrollment_Confirmation';
import UNENROLL_FROM_LABEL from '@salesforce/label/c.Child_IPE_Enrollment_Unenroll_From';
import ENROLL_TO_LABEL from '@salesforce/label/c.Child_IPE_Enrollment_Enroll_To';
import MAJOR_MINOR_ENROLLMENT_LABEL from '@salesforce/label/c.Child_IPE_Enrollment';
import CHILD_IPE_ENROLL_SUCCESS from '@salesforce/label/c.Child_IPE_Enrollment_Success';
import CHILD_IPE_UNENROLL_SUCCESS from '@salesforce/label/c.Child_IPE_Unenrollment_Success';
import STUDY_PATHWAY_LABEL from '@salesforce/label/c.Study_Pathway';
import ALL_CAMPUS_LABEL from '@salesforce/label/c.Campus_All';
import QUICK_SEARCH_HELPTEXT_LABEL from '@salesforce/label/c.Enrollment_Wizard_Quick_Search_Helptext';
import LOCK_TERM_LABEL from '@salesforce/label/c.Lock_The_Term';
import UNLOCK_TERM_LABEL from '@salesforce/label/c.Unlock_The_Term';
import WITHDRAW_FROM_TERM_LABEL from '@salesforce/label/c.Withdraw_From_Term';
import NO_STUDY_PATHWAY_FOUND_LABEL from '@salesforce/label/c.No_Study_Pathway_Found'; //ISS-002739

//Apex methods
import ctrlGetIndividualPathways from '@salesforce/apex/REDU_IpePathways_LCTRL.getIndividualPathways';
import ctrlCreateIndividualPathway from '@salesforce/apex/REDU_IpePathways_LCTRL.createIndividualPathway';
import ctrlGetCampuses from '@salesforce/apex/REDU_IpePathways_LCTRL.getCampuses';
import ctrlGetSpoStudentEnrollment from '@salesforce/apex/REDU_IpePathways_LCTRL.getSpoStudentEnrollment';
import ctrlManageChildIpeEnrollment from '@salesforce/apex/REDU_IpePathways_LCTRL.manageChildIpeEnrollment';
import ctrlGetEnrollmentActionStatusConfigs from '@salesforce/apex/REDU_IpePathways_LCTRL.getEnrollmentActionStatusConfigs';
import ctrlGetIpeStatusConfigs from '@salesforce/apex/REDU_IpePathways_LCTRL.getIpeStatusConfigs';
import ctrlGetTranslationFieldForNameByObjPrefix from '@salesforce/apex/REDU_Translation_LCTRL.getTranslationFieldForNameByObjPrefix';
import ctrlGetIndividualEnrollments from '@salesforce/apex/REDU_IpePathwayEnrollmentFinalize_LCTRL.getIndividualEnrollments';

//wire attributes for querying individual pathway using getRecord
const IPE_FIELDS = [
    "reduivy__Individual_Program_Enrollment__c.Id",
    "reduivy__Individual_Program_Enrollment__c.Name",
    "reduivy__Individual_Program_Enrollment__c.reduivy__Contact__c",
    "reduivy__Individual_Program_Enrollment__c.reduivy__Default_Campus__c",
    "reduivy__Individual_Program_Enrollment__c.reduivy__Study_Plan__c",
    "reduivy__Individual_Program_Enrollment__c.reduivy__Enrollment_Status__c",
    "reduivy__Individual_Program_Enrollment__c.reduivy__Study_Pathway__c", //ISS-002739
    "reduivy__Individual_Program_Enrollment__c.reduivy__Master_Enrollment__c",
    "reduivy__Individual_Program_Enrollment__c.reduivy__Master_Enrollment__r.Id",
    "reduivy__Individual_Program_Enrollment__c.reduivy__Master_Enrollment__r.Name",
    "reduivy__Individual_Program_Enrollment__c.reduivy__Master_Enrollment__r.reduivy__Contact__c",
    "reduivy__Individual_Program_Enrollment__c.reduivy__Master_Enrollment__r.reduivy__Default_Campus__c",
    "reduivy__Individual_Program_Enrollment__c.reduivy__Master_Enrollment__r.reduivy__Study_Plan__c", //ISS-002189
    "reduivy__Individual_Program_Enrollment__c.reduivy__Master_Enrollment__r.reduivy__Enrollment_Status__c", //ISS-002459
    "reduivy__Individual_Program_Enrollment__c.reduivy__Master_Enrollment__r.reduivy__Study_Pathway__c" //ISS-002739
    
];

const OBJ_TRANSLATION = [
    "ACC"
];

export default class IpePathways extends LightningElement {
	
	//configurable attributes
    @api recordId;
    @api modalTitle = '';
    @api modalIconName = 'standard:sales_path';
    @api individualPathwayInfoFields;
    @api individualPathwayInfoColumnNo;
    @api individualAcademicProgressInfoFields;
    @api individualAcademicProgressInfoColumnNo;
    @api userMode; //supported options: Admin, Student
    @api ipwButtonLabelPrefix;
    @api individualEnrollmentTabLabel;
    @api sessionEnrollmentTabLabel;

    //configurable attributes - ipe, ips group title, unit table fields, and accordion color
    @api ipeTitleField;
    @api ipsGroupTitleField;
    @api showIpsGroupInfo = false;
    @api ipsGroupInfoFields;
    @api ipsGroupInfoColumnNo;   
    @api ipsUnitTableFields;
    @api accordionBackgroundColor;
    @api accordionTextColor;

    //configurable attributes - view info fields
    @api studyUnitInfoFields;
    @api studyOfferingInfoFields;
    @api studyPlanStructureUnitInfoFields;

    //configurable attributes - enrollment button icon, label and enrollment status for ien
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

    //configurable attributes - other buttons
    @api showStudyUnitQuickSearch = false; //ISS-002188
    @api showUnitListingOption = false;
    @api defaultUnitListingMode; //supported options: Pathway, All
    @api showCampusOptions = false;
    
    @api showNewPathwayButton = false;
    @api addPathwayButtonIconName;

    @api showChildIpeEnrollmentButton = false;
    @api childIpeEnrollmentButtonIconName;

    @api showMyCalendarButton = false;
    @api myCalendarButtonIconName;

    @api showStudyPathwayButton = false;
    @api studyPathwayButtonIconName;
    
    //configurable attributes - custom filter
    @api customFilter1Active = false;
    @api customFilter1Visible = false;
    @api customFilter1Label;
    @api customFilter1Mapping;

    @api customFilter2Active = false;
    @api customFilter2Visible = false;
    @api customFilter2Label;
    @api customFilter2Mapping;

    @api customFilter3Active = false;
    @api customFilter3Visible = false;
    @api customFilter3Label;
    @api customFilter3Mapping;
 
    //configurable attributes - study session enrollment
    @api sessionEnrollmentSofAccordionBackgroundColor;
    @api sessionEnrollmentSofAccordionTextColor;
    @api sessionEnrollmentSofTitleField;
    @api sessionEnrollmentSofInfoFields;
    @api sessionEnrollmentSseTitleField;
    @api sessionEnrollmentSseInfoFields; 
    @api sessionEnrollmentSseIcon;
    @api sessionEnrollmentSstTitleField;
    @api sessionEnrollmentSstInfoFields;
    @api sessionEnrollmentSstIcon;
    @api sessionEnrollmentShowSstFieldLabel = false;

    //configurable attributes - my calendar
    @api myCalendarModalTitle;
    @api myCalendarModalIconName;
    @api myCalendarTimelineMinTime;
    @api myCalendarTimelineMaxTime;
    @api myCalendarView; //'listWeek', 'timeGridDay', 'timeGridWeek', 'dayGridMonth'
    @api myCalendarEnrollmentStatuses; //Individual Session Enrollment status
    @api myCalendarHeaderButtonLeft;
    @api myCalendarHeaderButtonCenter;
    @api myCalendarHeaderButtonRight;
    @api myCalendarStudySessionInfoFields;
    @api myCalendarStudySessionTimeInfoFields;
    @api myCalendarStudyEventInfoFields;
    @api myCalendarUseIsoWeek = false;

    //configurable attributes - study pathway modal
    @api studyPathwayInfoFields;
    @api studyPathwayTermTitlePrefix;
    @api studyPathwayTermInfoFields;
    @api studyPathwayUnitTitleField;
    @api studyPathwayUnitInfoFields; 
    @api studyPathwayUnitIcon;
    @api studyPathwayGroupTitleField;
    @api studyPathwayGroupInfoFields; 
    @api studyPathwayGroupIcon;
    @api studyPathwayShowStudyPlanOptions = false;
    @api studyPathwayAccordionBackgroundColor;
    @api studyPathwayAccordionTextColor;
    @api studyPathwayComboboxLabel;
    @api studyPathwayShowStudyUnitQuickSearch; //ISS-002189
    @api showChangeStudyPathwayButton = false; //ISS-002740

    //ISS-002401 enrollment action status config
    @api showLockingButton = false;
    @api showWithdrawFromTermButton = false;

    //configurable attributes - Withdraw from term
    @api withdrawFromTermIenStatusesForWithdrawal

    //configurable attributes - request reattempt settings
    @api requestAttemptMax = 3;
    @api requestAttemptWaitingTime = 5; //in seconds
    
    @api individualEnrollmentHelptext;
    @api sessionEnrollmentHelptext;

    @api missedFailedUnitListingOption;

    @api showEnrollmentFinalizationButton = false;
    @api enrollmentFinalizationMode;
    @api enrollmentFinalizationFlowName;

    //configurable attributes - debugging
	@api enableDebugMode = false;
	
    //obsolete
    @api showEnrollmentButton;
    @api requirementDescriptionField;

	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false;
	loadedLists = 0;
	
    selectedIpwId;
    showMyCalendar = false;
    isMyCalendarBtnClicked = false;
    showFilterPanel = false; //ISS-002188
    
    //filter panel
    studyUnitQuickSearchValue;
    selectedUnitListingMode;
    selectedCampusId;
    draftStudyUnitQuickSearchValue;
    draftSelectedUnitListingMode;
    draftSelectedCampusId;

    
    //wire attributes
    @track ipeRecord;
    @track ipeWireResult;

    @track ipwListWireResult;
    @track ipwListResponse;

    @track campusListWireResult;
    @track campusListResponse;

    @track spoEnrollWireResult;
    @track spoEnrollResponse;

    @track objectTranslatedNameResult;
    @track objectTranslatedNameResponse;

    //ISS-002401
    @track ipwEnrollmentActionStatusConfigsResult;
    @track ipwEnrollmentActionStatusConfigsResponse;

    //ISS-002459
    @track ipeStatusConfigsResult;
    @track ipeStatusConfigsResponse;

    //custom filters
    customFilters  = '';
    draftCustomFilters = '';

    //refresh container for parent component
    refreshContainerID;

	//labels
	@track label = {
        ADD_NEW_PATHWAY_LABEL,
        LISTING_MODE_LABEL,
        PLEASE_ADD_PATHWAY_TO_START_LABEL,
        ENROLLMENT_CONFIRMATION_LABEL,
        UNENROLL_FROM_LABEL,
        ENROLL_TO_LABEL,
        MAJOR_MINOR_ENROLLMENT_LABEL,
        CHILD_IPE_ENROLL_SUCCESS,
        CHILD_IPE_UNENROLL_SUCCESS,
        STUDY_PATHWAY_LABEL,
        LOCK_TERM_LABEL,
        UNLOCK_TERM_LABEL,
        WITHDRAW_FROM_TERM_LABEL,
        ...customLabels,
        ...calendarLabels
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

    }

    /**
     * @descripton connected callback
     */
    connectedCallback(){
		this.refreshContainerID = registerRefreshContainer(this, this.refreshData);

        this.selectedUnitListingMode = this.defaultUnitListingMode;
        this.draftSelectedUnitListingMode = this.selectedUnitListingMode;

        this.consoleLog('campus' + this.selectedCampusId);

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
        
        refreshApex(this.ipeWireResult);
        refreshApex(this.ipwListWireResult);
        refreshApex(this.campusListWireResult);
        refreshApex(this.spoEnrollWireResult);

        return new Promise((resolve) => {
            resolve(true);
        });

    }

    /**
     * @description Get individual program enrollment record
     */
    @wire(getRecord, { recordId: "$recordId", fields: IPE_FIELDS })
    wiredRecord(result) {
        
        this.ipeWireResult = result;
        this.ipeRecord = null;

        if (result.data) {
            this.ipeRecord = result.data;
            this.consoleLog(this.ipeRecord, true);

            //set the selected campus id if there is none selected yet
            if (this.selectedCampusId === undefined) {
                if (getFieldValue(this.ipeRecord, 'reduivy__Individual_Program_Enrollment__c.reduivy__Master_Enrollment__c')) {
                    //return the master ipe campus if it has master ipe
                    this.selectedCampusId = getFieldValue(this.ipeRecord, 'reduivy__Individual_Program_Enrollment__c.reduivy__Master_Enrollment__r.reduivy__Default_Campus__c');
                        
                } else {
                    this.selectedCampusId = getFieldValue(this.ipeRecord, 'reduivy__Individual_Program_Enrollment__c.reduivy__Default_Campus__c');
                }
                this.draftSelectedCampusId = this.selectedCampusId;
            }
            
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

    /**
     * @description ISS-002401 Get enrollment action status configs metadata
     */
    @wire(ctrlGetEnrollmentActionStatusConfigs, {})
    wiredEnrollmentActionStatusConfigsResult(result) {
        
        this.ipwEnrollmentActionStatusConfigsResult = result;
        this.ipwEnrollmentActionStatusConfigsResponse = null;

        if (result.data) {
            let response = result.data;
            if (response.responseData) {
                this.ipwEnrollmentActionStatusConfigsResponse = JSON.parse(response.responseData);
            }
            this.consoleLog(this.ipwEnrollmentActionStatusConfigsResponse, true);
            
        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    /**
     * @description ISS-002459 Get IPE statuses
     */
    @wire(ctrlGetIpeStatusConfigs, {})
    wiredGetIpeStatusesResult(result) {
        
        this.ipeStatusConfigsResult = result;
        this.ipeStatusConfigsResponse = null;

        if (result.data) {
            let response = result.data;
            if (response.responseData) {
                this.ipeStatusConfigsResponse = JSON.parse(response.responseData);
            }
            this.consoleLog(this.ipeStatusConfigsResponse, true);
            
        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    /**
     * @description Return master ipe record, this is to standardize the access of master enrollment fields
     */
    get masterIpeRecord() {

        let targetIpe = this.ipeRecord;

        if (getFieldValue(this.ipeRecord, 'reduivy__Individual_Program_Enrollment__c.reduivy__Master_Enrollment__c')) {
            targetIpe = getFieldValue(this.ipeRecord, 'reduivy__Individual_Program_Enrollment__c.reduivy__Master_Enrollment__r');
        }

        this.consoleLog('masterIpeRecord :: ');
        this.consoleLog(targetIpe, true);

        return targetIpe;
    }

    /**
     * @description Return contact id
     */
    get contactId(){
        if(this.masterIpeRecord){
            return getFieldValue(this.masterIpeRecord, 'reduivy__Individual_Program_Enrollment__c.reduivy__Contact__c');
        }

        return null;
    }

    /** ISS-002189 get master ipe studyplan id if this is a child ipe
     * @description Return master ipe study plan id
     */
    get masterIpeStudyPlanId(){
        if(this.masterIpeRecord){
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
     * @description Return master individual program enrolment id
     */
    get masterIpeId() {
        if (this.masterIpeRecord) {
            return getFieldValue(this.masterIpeRecord, 'reduivy__Individual_Program_Enrollment__c.Id');
        }

        return null;
    }

    /**
     * @description Return master individual program enrolment default campus id
     */
    get masterIpeDefaultCampusId() {
        if (this.masterIpeRecord) {
            return getFieldValue(this.masterIpeRecord, 'reduivy__Individual_Program_Enrollment__c.reduivy__Default_Campus__c');
        }

        return null;
    }

    /**
     * @description ISS-002459 Return true if master individual program enrolment's enrollment status is In Progress
     */
    get masterIpeIsAllowEnrollment() {

        if (this.masterIpeRecord && this.ipeStatusConfigsResponse) {
            let currentIpeStatus = getFieldValue(this.masterIpeRecord, 'reduivy__Individual_Program_Enrollment__c.reduivy__Enrollment_Status__c');

            if (Object.hasOwn(this.ipeStatusConfigsResponse, currentIpeStatus)) {
                return this.ipeStatusConfigsResponse[currentIpeStatus]?.reduivy__Allow_Enrollment__c;
            }
        }
        
        return false;
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
     * @description Get individual pathway records by masterIpeId
     */
    @wire(ctrlGetIndividualPathways, { 
        masterIpeId: "$masterIpeId"
    })
    wiredIndividualPathways(result) {
        
        this.ipwListWireResult = result;
        this.ipwListResponse = null;

        if (result.data) {
            this.ipwListResponse = JSON.parse(result.data.responseData);
            this.consoleLog(this.ipwListResponse, true);
        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }

    }

    /**
     * @description Return individual pathway list
     */
    get ipwList() {
        if (this.ipwListResponse) {
            return this.ipwListResponse;
        }

        return null;
    }

    /**
     * @description Get individual pathway records by masterIpeId
     */
    @wire(ctrlGetCampuses, { 
        masterIpeId: "$masterIpeId"
    })
    wiredCampuses(result) {
        this.campusListWireResult = result;
        this.campusListResponse = null;

        if (result.data) {
            this.campusListResponse = JSON.parse(result.data.responseData);
            this.consoleLog(this.campusListResponse, true);
        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }

    }

    /**
     * @description Get spo student enrollment by masterIpeId
     */
    @wire(ctrlGetSpoStudentEnrollment, {
        masterIpeId: "$masterIpeId"
    })
    wiredSpoStudentEnrollment(result) {
        this.spoEnrollWireResult = result;
        this.spoEnrollResponse = null;

        if (result.data) {
            this.spoEnrollResponse = JSON.parse(result.data.responseData);
            this.consoleLog(this.spoEnrollResponse, true);
        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    /**
     * @description Return campus combobox options
     */
    get campusOptions() {
        let options = [{
            id: ALL_CAMPUS_LABEL,
            label: ALL_CAMPUS_LABEL,
            value: null
        }];

        if (this.campusListResponse) {
            
            for (let campus of this.campusListResponse) {
                let campusName = campus?.[this.accNameTranslationField];
                if(!campusName) {
                    campusName = campus.Name;
                }
                options.push({
                    id: campus.Id,
                    label: campusName,
                    value: campus.Id
                })
            }
        }

        return options;
    }
 
    /**
     * @description return the account translation field for name
     */
    get accNameTranslationField() {
        return this.objectTranslatedNameResponse?.ACC;
    }

    /**
     * @description Return true to show filter section
     */
    get showFilters() {
        return this.hasPathway && (this.showUnitListingOption || this.showCampusOptions || this.showCustomFilters);

    }

    /**
     * @description Unit listing mode options
     */
    get unitListingModeOptions() {
        let options = [
            {
                id: ipePathwayConstants.UNIT_LISTING_MODE_ALL,
                label: UNIT_LISTING_ALL_LABEL,
                value: ipePathwayConstants.UNIT_LISTING_MODE_ALL
            },
            {
                id: ipePathwayConstants.UNIT_LISTING_MODE_PATHWAY,
                label: UNIT_LISTING_PATHWAY_LABEL,
                value: ipePathwayConstants.UNIT_LISTING_MODE_PATHWAY
            }
            
        ];

        return options;
    }

    /**
     * @description panel classes to create the panel
     */
    get panelClasses(){
        let baseClasses = 'ipepathway-individualenrollment-filterpanel slds-panel slds-size_medium slds-panel_docked slds-panel_docked-right slds-panel_drawer'
        if(this.showFilterPanel) {
            return baseClasses + ' slds-is-open';
        }

        return baseClasses;
    }

    /** ISS-002188
     * @description Toggle filter panel
     */
    handleToggleFilterPanel(){
        this.showFilterPanel = !this.showFilterPanel;

    }

    /** ISS-002188
     * @description Close filter panel
     */
    handleFilterPanelClose(){
        this.showFilterPanel = false;
    }
    
    /** ISS-002188
     * @description handle study unit quick search change
     */
    handleStudyUnitQuickSearchChange(event) {
        this.draftStudyUnitQuickSearchValue = event.target.value;
    }

    /**
     * @description Handle unit listing mode change
     */
    handleUnitListingModeChange(event) {
        this.draftSelectedUnitListingMode = event.detail.value;
        this.dispatchEvent(new RefreshEvent());
    }

    /**
     * @description Handle campus change
     */
    handleCampusChange(event) {
        this.draftSelectedCampusId = event.detail.value;
        this.dispatchEvent(new RefreshEvent());
    }

    /**
     * @description Handle menu item click
     */
    handleMenuSelect(event) {
        let selectedMenu = event.detail.value;

        if (selectedMenu === 'refresh') {
            this.handleRefreshClick(event);
        } else if (selectedMenu === 'help') {
            this.handleHelpClick(event);
        } else if(selectedMenu === 'updatelock') {
            this.handleUpdateLockClick(event);
        } else if(selectedMenu === 'withdrawfromterm') {
            this.handleWithdrawFromTermClick();
        }
    }

    /**
     * @description Handle the refresh
     */
    handleRefreshClick(event) {
        this.dispatchEvent(new RefreshEvent());
    }

    /**
     * @description Handle add pathway
     */
    handleAddPathwayClick(event) {
        this.launchConfirmationModal(this.label.CONFIRMATION_LABEL, ADD_NEW_PATHWAY_CONFIRMATION_LABEL, null, null, true, this.label.CONFIRM_LABEL, true, this.label.CANCEL_LABEL, 'addpathway', null);
    }

    /**
     * @description Handle enrollment click
     */
    handleEnrollmentClick(event) {
        this.launchEnrollmentModal(this.label.MAJOR_MINOR_ENROLLMENT_LABEL, true, this.label.APPLY_LABEL, true, this.label.CANCEL_LABEL, 'enrollment', this.spoEnrollResponse);
    }

    /**
     * @description Handle study pathway button click
     */
    handleStudyPathwayClick(event) {

        if (this.masterIpeStudyPathwayId) {
            //ISS-002739 we will use the study pathway id if available
            this.launchStudyPathwayModal(this.label.STUDY_PATHWAY_LABEL, 'studypathway');
        } else {
            promptWarning(this.label.WARNING_LABEL, NO_STUDY_PATHWAY_FOUND_LABEL);
        }
    }

    /**
     * @description Handle help menu
     */
    handleHelpClick(event) {
        this.launchHelpModal();
    }

    /**
     * @description Handle enrollment action status button click to lock or unlock a term
     */
    handleUpdateLockClick(event) {
        this.launchLockingModal();
    }

    /**
     * @description Handle Withdraw from term to withdraw all the individual enrollment from the selected term
     */
    handleWithdrawFromTermClick(){
        this.launchWithdrawFromTermModal();
    }

    /**
     * @description Launch the confirmation modal
     * @param title 
     * @param text1 
     * @param text2 
     * @param text3 
     * @param showSubmit 
     * @param submitLabel 
     * @param showCancel 
     * @param cancelLabel 
     * @param lEventSource 
     * @param lEventData 
     */
    launchConfirmationModal(title, text1, text2, text3, showSubmit, submitLabel, showCancel, cancelLabel, lEventSource, lEventData) {
        genericConfirmationModal.open({
            size: 'small',
            modalTitle: title,
            confirmationText1: text1,
            confirmationText2: text2,
            confirmationText3: text3,
            showSubmitButton: showSubmit,
            submitButtonLabel: submitLabel,
            showCancelButton: showCancel,
            cancelButtonLabel: cancelLabel,
            eventSource: lEventSource,
            eventData: lEventData,
            enableDebugMode: this.enableDebugMode            
        }).then((result) => {
            
            if (result) {
                this.consoleLog('launchConfirmationModal.close');
                this.consoleLog(result, true);

                const {operation, eventSource, eventData} = result;

                if (operation === 'submit' && eventSource === 'addpathway') {
                    this.createPathway();
                } else if (operation === 'submit' && eventSource === 'enrollment'){
                    this.manageChildIpe(eventData);
                }
            }
        });
    }

    /**
     * @description Launch the enrollment modal
     * @param title 
     * @param showApply 
     * @param applyLabel 
     * @param showCancel 
     * @param cancelLabel 
     * @param lEventSource 
     * @param lEventData 
     */
    launchEnrollmentModal(title, showApply, applyLabel, showCancel, cancelLabel, lEventSource, lEventData) {
        ipePathwayChildEnrollmentModal.open({
            size: 'small',
            modalTitle: title,
            showApplyButton: showApply,
            applyButtonLabel: applyLabel,
            showCancelButton: showCancel,
            cancelButtonLabel: cancelLabel,
            eventSource: lEventSource,
            eventData: lEventData,
            enableDebugMode: this.enableDebugMode
        }).then((result) => {
            if (result) {
                this.consoleLog('launchEnrollmentModal.close');
                this.consoleLog(result, true);

                const {operation, eventSource, eventData} = result;

                if (operation === 'apply' && eventSource === 'enrollment') {
                    this.showConfirmEnrollModal(eventData);
                }
            }
        });
    }

    /**
     * @description Launch the help modal
     */
    launchHelpModal() {
        ipePathwayHelpModal.open({
            size: 'small',
            preEnrollButtonIconName: this.preEnrollButtonIconName,
            preEnrollButtonLabel: this.preEnrollButtonLabel,
            withdrawPreEnrollButtonIconName: this.withdrawPreEnrollButtonIconName,
            withdrawPreEnrollButtonLabel: this.withdrawPreEnrollButtonLabel,
            enrollButtonIconName: this.enrollButtonIconName,
            enrollButtonLabel: this.enrollButtonLabel,
            unenrollButtonIconName: this.unenrollButtonIconName,
            unenrollButtonLabel: this.unenrollButtonLabel,
            unenrollRequestButtonIconName: this.unenrollRequestButtonIconName,
            unenrollRequestButtonLabel: this.unenrollRequestButtonLabel,
            waitlistButtonIconName: this.waitlistButtonIconName,
            waitlistButtonLabel: this.waitlistButtonLabel,
            withdrawWaitlistButtonIconName: this.withdrawWaitlistButtonIconName,
            withdrawWaitlistButtonLabel: this.withdrawWaitlistButtonLabel,
            enableDebugMode: this.enableDebugMode
        }).then((result) => {
            
        });
    }

    /**
     * @description Launch the study pathway modal
     * @param title 
     * @param eventSource 
     */
    launchStudyPathwayModal(title, eventSource) {
        ipePathwayStudyPathwayModal.open({
            size: 'small',
            modalTitle: title,
            eventSource: eventSource,
            studyPathwayInfoFields: this.studyPathwayInfoFields,
            studyPathwayTermTitlePrefix: this.studyPathwayTermTitlePrefix,
            studyPathwayTermInfoFields: this.studyPathwayTermInfoFields,
            studyPathwayUnitTitleField: this.studyPathwayUnitTitleField,
            studyPathwayUnitInfoFields: this.studyPathwayUnitInfoFields,
            studyPathwayUnitIcon: this.studyPathwayUnitIcon,
            studyPathwayGroupTitleField: this.studyPathwayGroupTitleField,
            studyPathwayGroupInfoFields: this.studyPathwayGroupInfoFields,
            studyPathwayGroupIcon: this.studyPathwayGroupIcon,
            studyPathwayShowStudyUnitQuickSearch: this.studyPathwayShowStudyUnitQuickSearch, //ISS-002189
            studyPathwayShowStudyPlanOptions: this.studyPathwayShowStudyPlanOptions,
            studyPathwayAccordionBackgroundColor: this.studyPathwayAccordionBackgroundColor,
            studyPathwayAccordionTextColor: this.studyPathwayAccordionTextColor,
            studyPathwayComboboxLabel: this.studyPathwayComboboxLabel,
            currentTermNumber: this.currentTermNumber, //ISS-002189
            masterIpeId: this.masterIpeId, //ISS-002189
            showChangeStudyPathwayButton: this.showChangeStudyPathwayButton, //ISS-002740
            enableDebugMode: this.enableDebugMode
        }).then((result) => {
            if (result) {
                this.consoleLog('launchStudyPathwayModal.close');
                this.consoleLog(result, true);

                const {operation} = result;

                if (operation === 'closedwithrefresh') {
                    this.dispatchEvent(new RefreshEvent());
                }
            }
        });
    }

    /**
     * @description ISS-002401 Launch the locking/unlocking modal for admin to update the enrollment action status
     */
    launchLockingModal() {

        let lockingModalTitle = this.isCurrentPathwayAllowEnrollment ? this.label.LOCK_TERM_LABEL : this.label.UNLOCK_TERM_LABEL;
        let lockingActionLabel = this.isCurrentPathwayAllowEnrollment ? this.label.LOCK_TERM_LABEL : this.label.UNLOCK_TERM_LABEL;

        ipePathwayLockingModal.open({
            size: 'small',
            modalTitle: lockingModalTitle,
            lockingActionLabel: lockingActionLabel,
            individualPathwayId: this.currentIpwId,
            individualAcademicProgressId: this.iprFromCurrentIpwRecord,
            enableDebugMode: this.enableDebugMode
        }).then((result) => {
            this.consoleLog('ipePathwayLockingModal.close');

            if (result) {
                this.consoleLog(result, true);

                const {operation } = result;
                if (operation === 'confirmed') {
                    this.dispatchEvent(new RefreshEvent());
                }
            }
        });
    }

    /**
     * @description ISS-002436 Launch the withdraw from term modal for admin to withdraw all the ien of the selected ipw
     */
    launchWithdrawFromTermModal() {
        ipePathwayWithdrawFromTermModal.open({
            size: 'small',
            iprId: this.iprFromCurrentIpwRecord,
            statusesForWithdrawal: this.withdrawFromTermIenStatusesForWithdrawal,
            enableDebugMode: this.enableDebugMode
        }).then(result=>{
            this.consoleLog('withdrawFromTermModal.close');
            
            if(result) {
                this.consoleLog(result, true);

                const { operation } = result;
                if(operation === 'saved') {
                    this.dispatchEvent(new RefreshEvent());
                }
            }
        });
    }

    /**
     * @description Handle the change of individual pathway
     */
    handleSelectPathwayEvent(event) {
        this.selectedIpwId = event.detail.selectedIpwId;
    }

    /**
     * @description Create a new pathway
     */
    createPathway() {
        
        this.toggleSpinner(1);

        try {
            this.consoleLog('createPathway');

            ctrlCreateIndividualPathway({
                masterIpeId: this.masterIpeId
            })
            .then(saveResult => {
                this.toggleSpinner(-1);
                promptSuccess(this.label.SUCCESS_LABEL, saveResult.message);

                this.dispatchEvent(new RefreshEvent());
            })
            .catch(error => {
                promptError(this.label.ERROR_LABEL, getErrorMessage(error));
                this.toggleSpinner(-1);
                
            });

        } catch (error) {
            this.toggleSpinner(-1);
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
        }
    }

    /**
     * @description manage Individual Program Enrollment (create Ipe for enrollment, change Ipe status for unenrollment)
     */
    manageChildIpe(eventData) {
        
        this.toggleSpinner(1);

        try {
            this.consoleLog('manageChildIpe');

            ctrlManageChildIpeEnrollment({
                masterIpeId: this.masterIpeId,
                toEnrollUnenroll: JSON.stringify(eventData)
            })
            .then(saveResult => {
                let response = saveResult ? JSON.parse(saveResult.responseData) : null;

                let successTxt = '', enrollText = '';
                if(response && response.enroll){
                    enrollText += response.enroll.map(sp => sp.Name).join(', ');
                    successTxt = this.label.CHILD_IPE_ENROLL_SUCCESS.format([enrollText]);
                }
                
                let unenrollText = '';
                if(response && response.unenroll){
                    unenrollText += response.unenroll.map(sp => sp.Name).join(', ');
                    successTxt = successTxt === '' ? this.label.CHILD_IPE_UNENROLL_SUCCESS.format([unenrollText]) : successTxt + ' ' + this.label.CHILD_IPE_UNENROLL_SUCCESS.format([unenrollText]);
                }

                this.dispatchEvent(new RefreshEvent());
                this.toggleSpinner(-1);
                promptSuccess(this.label.SUCCESS_LABEL, successTxt);

                this.dispatchEvent(new RefreshEvent());
            })
            .catch(error => {
                promptError(this.label.ERROR_LABEL, getErrorMessage(error));
                this.toggleSpinner(-1);
                
            });

            this.dispatchEvent(new RefreshEvent());

        } catch (error) {
            this.toggleSpinner(-1);
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
        }
    }

    /**
     * @description return a map which study plan that going to enroll or unenroll from eventData
     */
    showConfirmEnrollModal(eventData) {
        
        this.toggleSpinner(1);

        try {
            this.consoleLog('showConfirmEnrollModal');

            this.toggleSpinner(-1);

            let response = this.getEnrollUnenrollMap(eventData, this.spoEnrollResponse);
            
            let enroll = null, enrollText = '';
            if(response && response.enroll){
                enrollText += response.enroll.map(sp => sp.Name).join(', ');
                enroll = this.label.ENROLL_TO_LABEL.format([enrollText]);
            }
            
            let unenroll = null, unenrollText = '';
            if(response && response.unenroll){
                unenrollText += response.unenroll.map(sp => sp.Name).join(', ');
                unenroll = this.label.UNENROLL_FROM_LABEL.format([unenrollText]);
            }

            if(enroll != null || unenroll != null){
                this.launchConfirmationModal(this.label.CONFIRMATION_LABEL, this.label.ENROLLMENT_CONFIRMATION_LABEL, enroll, unenroll, true, this.label.CONFIRM_LABEL, true, this.label.CANCEL_LABEL, 'enrollment', response);
            }

        } catch (error) {
            this.toggleSpinner(-1);
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
        }
    }

    /**
     * @description to return the map that indicate which study plan name that going to enroll or unenroll from eventData
     */
    getEnrollUnenrollMap(newEnrollmentData, oldEnrollmentData) {
        try {
            //convert newEnrollmentData into Map<study plan, enrollStatus>
            const newEnrollMap = new Map();
            newEnrollmentData.forEach(wrapper => {
                newEnrollMap.set(wrapper.studyPlan.Id, wrapper.isEnrolled);
            });
            
            //find updated enrollment status
            const spEnrollMap = {};
            oldEnrollmentData.forEach(oldWrap => {
                const sp = oldWrap.studyPlan;

                if (oldWrap.isEnrolled !== newEnrollMap.get(sp.Id)) {
                    if (!oldWrap.isEnrolled) {
                        if (!spEnrollMap.enroll) {
                            spEnrollMap.enroll = [];
                        }
                        spEnrollMap.enroll.push(sp);
                    } else {
                        if (!spEnrollMap.unenroll) {
                            spEnrollMap.unenroll = [];
                        }
                        spEnrollMap.unenroll.push(sp);
                    }
                }
            });

            return spEnrollMap;

        } catch (error) {
            this.toggleSpinner(-1);
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
        }

        return null
    }

    /**
     * @description Return the selected individual pathway id, if none selected, the first one will be the default
     */
    get currentIpwId() {
        if (this.ipwList && this.ipwList.length > 0) {
            if (!this.selectedIpwId) {
                //find the current term ipw
                for (let ipw of this.ipwList) {
                    if (ipw.reduivy__Status__c === ipePathwayConstants.IPW_STATUS_CURRENT) {
                        this.selectedIpwId = ipw.Id;
                        break;
                    }
                }

                //if no current, get the first ipw
                if (!this.selectedIpwId) {
                    this.selectedIpwId = this.ipwList[0].Id;
                }
            }

            return this.selectedIpwId;
        }

        return null;
    }

    /**
     * @description Return true if the pathways list is not empty
     */
    get hasPathway() {
        return this.ipwList && this.ipwList.length > 0 ? true : false;
    }

    /**
     * @description ISS-002401 get the current individual pathway record based on the currentIpwId
     */
    get currentIpwRecord(){
        if(this.currentIpwId){
            let currentIpw = this.ipwList.find((ipw) => ipw.Id === this.currentIpwId);
            return currentIpw;
        }

        return null;
    }

    /**
     * @description ISS-002401 Return true if there is no config or the config allows enrollment
     */
    get isCurrentPathwayAllowEnrollment() {
        if (this.currentIpwRecord && this.ipwEnrollmentActionStatusConfigsResponse) {
            let ipwEnrollmentActionStatus = this.currentIpwRecord?.reduivy__Individual_Academic_Progress__r?.reduivy__Enrollment_Action_Status__c;
            if (Object.hasOwn(this.ipwEnrollmentActionStatusConfigsResponse, ipwEnrollmentActionStatus)) {
                return this.ipwEnrollmentActionStatusConfigsResponse[ipwEnrollmentActionStatus]?.reduivy__Allow_Enrollment__c;
            }
        }

        return true;
    }

    /**
     * @description Return true if enrollment is allowed
     */
    get canPerformEnrollment() {
        return this.showEnrollmentButtons && this.isCurrentPathwayAllowEnrollment && this.masterIpeIsAllowEnrollment; //ISS-002459 added new criteria to check for status
    }

    get pleaseAddPathwayText() {
        return PLEASE_ADD_PATHWAY_TO_START_LABEL.format([this.label.PATHWAY_LABEL.toLowerCase(), this.label.ADD_NEW_PATHWAY_LABEL]);
    }

    /**
     * @description Has active custom filters
     */
    get hasActiveCustomFilters() {
        return (
            (this.customFilter1Active) || 
            (this.customFilter2Active) || 
            (this.customFilter3Active)
        );
    }

    /**
     * @description Show custom filter section
     */
    get showCustomFilters() {
        return this.hasActiveCustomFilters && (
            (this.customFilter1Visible) || 
            (this.customFilter2Visible) || 
            (this.customFilter3Visible)
        );
    }

    /**
     * @description Return custom filters config
     */
    get customFilterConfigs() {
        if (this.hasActiveCustomFilters) {

            let configs = [];

            if (this.customFilter1Active) {
                configs.push({
                    seq: 1,
                    showFilter: this.customFilter1Visible,
                    label: this.customFilter1Label,
                    mapping: this.customFilter1Mapping
                });
            }

            if (this.customFilter2Active) {
                configs.push({
                    seq: 2,
                    showFilter: this.customFilter2Visible,
                    label: this.customFilter2Label,
                    mapping: this.customFilter2Mapping
                });
            }

            if (this.customFilter3Active) {
                configs.push({
                    seq: 3,
                    showFilter: this.customFilter3Visible,
                    label: this.customFilter3Label,
                    mapping: this.customFilter3Mapping
                });
            }

            return JSON.stringify(configs);
        }

        return null;

    }

    /**
     * @description This method is used to handle the message/data coming from other component.
     */
    handleFiltersUpdate(event) {

        this.consoleLog('handleFiltersUpdate');

        if (event.detail) {
            this.consoleLog(event.detail.customFilters, true);

            this.draftCustomFilters = JSON.stringify(event.detail.customFilters);
            if(!this.customFilters) {
                this.customFilters = JSON.stringify(event.detail.customFilters);
            }

            this.dispatchEvent(new RefreshEvent());
        }
    }

    /**
     * @description Returns My Calendar button variant
     */
    get myCalendarBtnVariant(){
        return this.isMyCalendarBtnClicked ? "brand" : "brand-outline";
    }

    /**
     * @description Handle My Sessions button click
     */
    handleMyCalendarBtnClick(event) {
        this.isMyCalendarBtnClicked = !this.isMyCalendarBtnClicked;
        this.showMyCalendar = !this.showMyCalendar;
    }

    /** ISS-002188
     * @description Handle Apply button click in filter panel
     */
    handleApplyClick() {
        this.selectedUnitListingMode = this.draftSelectedUnitListingMode;
        this.studyUnitQuickSearchValue = this.draftStudyUnitQuickSearchValue;
        this.selectedCampusId = this.draftSelectedCampusId;
        this.customFilters = this.draftCustomFilters;
        this.dispatchEvent(new RefreshEvent());
    }

    /** ISS-002188
     * @description Handle Clear button click in filter panel
     */
    handleClearClick() {
        this.draftSelectedUnitListingMode = this.defaultUnitListingMode;
        this.draftStudyUnitQuickSearchValue = null;
        this.draftSelectedCampusId = this.masterIpeDefaultCampusId;
        this.template.querySelector('c-custom-filters').resetToDefault();
    }

    /** ISS-002188
     * @description Quick Search Help Text Label
     */
    get quickSearchHelpTextLabel() {
        return QUICK_SEARCH_HELPTEXT_LABEL
    }


    /** ISS-002189
     * @description get the term number of selected term
     */
    get currentTermNumber(){
        return this.currentIpwRecord?.reduivy__Term_Number__c;
    }

    /**
     * @description get the ipr id from the current selected ipw record
     */
    get iprFromCurrentIpwRecord(){
        return this.currentIpwRecord?.reduivy__Individual_Academic_Progress__c;
    }

    /**
     * @description handle finalization event
     */
    async handleFinalizeEnrollment(event) {
        const {individualPathwayId, masterIpeId, individualAcademicProgressId} = event.detail;

        if (this.enrollmentFinalizationMode) {
            this.toggleSpinner(1);

            try {
                let ienListResponse = await ctrlGetIndividualEnrollments({
                    individualAcademicProgressId: individualAcademicProgressId
                });

                let ienList = JSON.parse(ienListResponse.responseData);
                let ienIds = ienList.map(item => item.Id);
                
                if (this.enrollmentFinalizationMode === 'Launch Flow') {

                    ipePathwayEnrollmentFinalizeModal.open({
                        size: 'small',
                        modalTitle: this.label.CONFIRMATION_LABEL,
                        flowName: this.enrollmentFinalizationFlowName,
                        individualAcademicProgressId: individualAcademicProgressId,
                        individualPathwayId: individualPathwayId,
                        masterIpeId: masterIpeId,
                        individualEnrollmentIds: ienIds,
                        enableDebugMode: this.enableDebugMode
                    }).then(result=>{
                        this.consoleLog('ipePathwayEnrollmentFinalizeModal.close');
                        
                        if(result) {
                            this.consoleLog(result, true);
                        }

                        this.dispatchEvent(new RefreshEvent());
                    });

                    this.consoleLog('launched finalize flow');

                } else if (this.enrollmentFinalizationMode === 'Dispatch LWC Event') {

                    this.dispatchEvent(new CustomEvent("finalize", {
                        detail: {
                            individualPathwayId: individualPathwayId,
                            masterIpeId: masterIpeId,
                            individualAcademicProgressId: individualAcademicProgressId,
                            individualEnrollmentIds: ienIds
                        }
                    }));

                    this.consoleLog('dispatched finalize event :: ' + individualPathwayId + ' - ' + individualAcademicProgressId + ' - ' + masterIpeId + ' - ' + JSON.stringify(ienIds));
                }

                this.toggleSpinner(-1);

            } catch (error) {
                this.toggleSpinner(-1);

                promptError(this.label.ERROR_LABEL, getErrorMessage(error));
            }
        }
    }
	
    /**
     * @descripton Spinner loading status
     */
	get isLoading(){
        return this.loadedLists === 0 && this.ipeRecord ? false : true;
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
        logInfo('ipePathways', anything, this.enableDebugMode, isJson);
    }
	
}