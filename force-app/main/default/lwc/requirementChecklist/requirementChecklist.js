/**
 * @Author 		WDCi (XW)
 * @Date 		June 2025
 * @group 		Requirement Checklist
 * @Description Requirement Checklist component
 * @changehistory
 * ISS-002128 06-06-2025 XW - new class
 * ISS-002616 09-09-2025 XW - file is linked to the actual record instead of contact if checklist is in contact record page
 * ISS-002604 12-09-2025 Lean - fixed download url
 * ISS-002771 08-01-2026 XW - support showing requirement sets and requirement from child object, formatting title of requirement set
 */
import { LightningElement, api, wire, track } from 'lwc';
import { promptInfo, promptError, promptWarning, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';
import { initCacheIdx, extractFieldValue, getMergeKeys, mergeValues } from 'c/lwcUtil';
import { customLabels } from 'c/labelLoader';
import LANG from '@salesforce/i18n/lang';

//refresh module
import { RefreshEvent, registerRefreshContainer, unregisterRefreshContainer } from 'lightning/refresh';

//Apex methods
import ctrlGetIndividualRequirements from '@salesforce/apex/REDU_RequirementChecklist_LCTRL.getIndividualRequirements'
import ctrlGetCommunityInfo from '@salesforce/apex/REDU_RequirementChecklist_LCTRL.getCommunityInfo'

//labels
import REVIEWED_LABEL from '@salesforce/label/c.Requirement_Checklist_Reviewed';
import SUBMITTED_LABEL from '@salesforce/label/c.Requirement_Checklist_Submitted';

//message
import { subscribe, unsubscribe, MessageContext, publish } from "lightning/messageService";
import MESSAGE_CHANNEL from "@salesforce/messageChannel/c__privateLwcMessageChannel__c"

const RESPONSE_TOTAL_REQUIREMENTS_PARAM = 'totalRequirements';
const RESPONSE_TOTAL_REVIEWED_PARAM = 'totalReviewed';
const RESPONSE_TOTAL_SUBMITTED_PARAM = 'totalSubmitted';
const RESPONSE_PARENT_IRS_DATA_PARAM = 'irsParentData';
const RESPONSE_CHILD_IRS_DATA_PARAM = 'irsChildData';
const RESPONSE_DEFAULT_SUBMITTED_STATUS_PARAM = 'defaultSubmittedStatus';
const RESPONSE_CHILD_LABEL_PARAM = 'irsChildRelationshipLabel';
const RESPONSE_TRANSLATION_INFO_PARAM = 'translationInfo';

const THEME_SUCCESS = 'slds-theme_success';
const THEME_WARNING = 'slds-theme_warning';

export default class RequirementChecklist extends LightningElement {
	
	//configurable attributes
    @api recordId;
    @api objectApiName;
    @api modalTitle;
    @api modalIconName;
    
    @api userMode;
    @api childrenRelationshipName = '';
    
    @api openIcon;
    @api submittedIcon;
    @api reviewingIcon;
    @api acceptedIcon;
    @api rejectedIcon;
    @api cancelledIcon;
    @api resubmissionRequestedIcon;
    @api requirementSetTitleField; 

    /**
     * @description to support backwards compatibility of requirement set
     */
    get parentRequirementSetTitleFormat() {
        let value = this.requirementSetTitleField;
        if(!value) {
            return value;
        } 
        if(!value.includes('{') && !value.includes('}')) {
            value = '{' + value + '}';
        }

        return value;
            
    }
    @api childrenRequirementSetTitleFormat;

    @api requirementTitleField;
    @api requirementDetailsFields;

    @api showRequirementRowDetailsButton;
    @api showRequirementUserActionButton;
    @api showRequirementApprovalActionButton;

    @api showSubmittedCount;
    @api showReviewedCount;

    @api achievementDetailsFields;
    @api createAchievementDetailsFieldSet;

    //ISS-002604
    @api downloadUrl;

    //ISS-002666
    @api promptRemarksAfterReviewStatusUpdate;
    @api showRemarksAction;
    @api remarksFieldSetName;

    // ISS-002665 - To set the submission status based on the configured status in the wizard or the custom metadata configuration when the buttons are clicked in the requirement checklist wizard.
    @api submissionStatus;

	@api enableDebugMode = false;
	
	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false
	loadedLists = 0;
    @track subscription;
	
    //refresh handler
    refreshHandlerID;

    //local cache idx to force rerendering
    _cacheIdx;

    //wire attribute
    individualRequirementsResult;
    individualRequirementsResponse;
    communityInfoResult;
    communityInfoResponse;

	//labels
	label = customLabels;
	
	//js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'jquery', 'tooltips'
    modules = ['stringutil'];

    /**
     * @description individual requirement set of parent record wrapper data
     */
    get parentIrsData(){
        if(this.irsDataAreReady) {
            let parentIrsData = this.individualRequirementsResponse?.[RESPONSE_PARENT_IRS_DATA_PARAM];
            for(let parentIrsWrapper of parentIrsData) {
                let parentMergeKeys = getMergeKeys(this.parentRequirementSetTitleFormat);
                parentIrsWrapper.title = mergeValues(this.parentRequirementSetTitleFormat, parentMergeKeys, parentIrsWrapper.irs, true, this.translationInfo, this.language);
            }
            return parentIrsData;
        }
        return [];
    }   

    /**
     * @description individual requirement set of children records wrapper data
     */
    get childIrsData(){
        let result = [];
        if(this.irsDataAreReady) {
            let childIrsData = this.individualRequirementsResponse?.[RESPONSE_CHILD_IRS_DATA_PARAM];
            for(let childRecordWrapper of childIrsData) {
                for(let childIrsWrapper of childRecordWrapper.irsWrapperList) {
                    let childMergeKeys = getMergeKeys(this.childrenRequirementSetTitleFormat);
                    childIrsWrapper.title = mergeValues(this.childrenRequirementSetTitleFormat, childMergeKeys, childIrsWrapper.irs, true, this.translationInfo, this.language);
           
                    result.push(childIrsWrapper);
                }
            }
        }
        return result;
    }

    get hasChildIrsData() {
        return this.childIrsData.length > 0
    }
    
    /**
     * @description individual requirement set of children records wrapper data
     */
    get childrenRelationshipLabel(){
        if(this.irsDataAreReady) {
            return this.individualRequirementsResponse?.[RESPONSE_CHILD_LABEL_PARAM];
        }
        return [];
    }

    /**
     * @description return true if irsdata are ready
     */
    get irsDataAreReady(){
        return this.individualRequirementsResponse;
    }

    /**
     * @description total required individual requirements count
     */
    get totalRequirements() {
        if(this.irsDataAreReady) {
            return this.individualRequirementsResponse?.[RESPONSE_TOTAL_REQUIREMENTS_PARAM]
        }

        return 0;
    }

    /**
     * @description total submitted individual requirements
     */
    get totalSubmitted() {
        if(this.irsDataAreReady) {
            return this.individualRequirementsResponse?.[RESPONSE_TOTAL_SUBMITTED_PARAM]
        }

        return 0;
    }

    /**
     * @description total reviewed individual requirements
     */
    get totalReviewed() {
        if(this.irsDataAreReady) {
            return this.individualRequirementsResponse?.[RESPONSE_TOTAL_REVIEWED_PARAM]
        }

        return 0;
    }

    /**
     * @description submitted submission statuses
     */
    get defaultSubmittedStatus() {
        if(this.irsDataAreReady) {
            return this.individualRequirementsResponse?.[RESPONSE_DEFAULT_SUBMITTED_STATUS_PARAM]
        }

        return '';
    }

    get translationInfo() {
        if(this.irsDataAreReady) {
            return this.individualRequirementsResponse?.[RESPONSE_TRANSLATION_INFO_PARAM]
        }

        return {};
        
    }

    /**
     * @description the text displayed on reviewed badge
     */
    get reviewedBadgeLabel() {
        return REVIEWED_LABEL.format([this.totalReviewed, this.totalRequirements])
    }

    /**
     * @description the text displayed on submitted badge
     */
    get submittedBadgeLabel() {
        return SUBMITTED_LABEL.format([this.totalSubmitted, this.totalRequirements])
    }

    /**
     * @description the class (colour) for the reviewed badge
     */
    get reviewedBadgeClassVariant() {
        if(this.totalReviewed >= this.totalRequirements) {
            return THEME_SUCCESS;
        }

        return THEME_WARNING;
    }

    /**
     * @description the class (colour) for the submitted badge
     */
    get submittedBadgeClassVariant() {
        if(this.totalSubmitted >= this.totalRequirements) {
            return THEME_SUCCESS;
        }

        return THEME_WARNING;
    }

    /**
     * @description the name of all of the individual requirement set (to open all of the accordion by default)
     */
    get activeSections() {
        let result = [];
        if(this.irsDataAreReady) {
            result = this.parentIrsData.map(irsWrapper => irsWrapper.irs.Id);
            if(this.hasChildIrsData) {
                result = result.concat(this.childIrsData.map(irsWrapper => irsWrapper.irs.Id));
            }
        }
        return result;
    }
	
    /**
        * @description the user language
        */
    get language() {
        return LANG;
    }
	/**
     * @descripton library loader
     */
    handleLibLoadSuccess() {
        this.isScriptLoaded = true;
        this.isInitSuccess = true;
        
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
        this.refreshHandlerID = registerRefreshContainer(this, this.refreshData);
        this._cacheIdx = initCacheIdx();
        this.subscribeToMessageChannel();
	}
	
    /**
     * @descripton disconnected callback
     */
	disconnectedCallback() {
        unregisterRefreshContainer(this.refreshHandlerID);
        this.unsubscribeToMessageChannel();
	}

    /**
     * @description Refresh data
     */
    refreshData() {
        this.consoleLog('refreshData');
        
        this.toggleSpinner(1);
        this._cacheIdx = initCacheIdx();
        
        this.toggleSpinner(-1);
        return new Promise((resolve) => {
            resolve(true);
        });

    }

    get requirementSetReferencedFields() {
        return [...(getMergeKeys(this.parentRequirementSetTitleFormat, true) ?? []), ...(getMergeKeys(this.childrenRequirementSetTitleFormat, true) ?? [])]
    }

    /**
     * @description get the individual requirements set and individual requirements
     * @param  userMode                        The user mode of the requirement checklist comp. Admin, Faculty or Student
     * @param  requirementSetReferencedFields  the individual requirement set title field api name to be displayed on the accordion
     * @param  requirementTitleField           the individual requirement title field api name to be displayed on the details
     * @param  recordId                        parent record id
     */
    @wire(ctrlGetIndividualRequirements, {
        userMode: "$userMode",
        requirementSetReferencedFields: "$requirementSetReferencedFields",
        requirementTitleField: "$requirementTitleField",
        recordId: "$recordId",
        childrenRelationshipName: '$childrenRelationshipName',
        language: '$language',
        cacheIdx: '$_cacheIdx'
    })
    wireGetIndividualRequirements(result) {
        
        this.consoleLog('wireGetIndividualRequirements');
        this.individualRequirementsResult = result;
        this.individualRequirementsResponse = null;

        if (result.data) {
            this.individualRequirementsResponse = JSON.parse(result.data.responseData);
            this.consoleLog(this.individualRequirementsResponse, true);
        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }

    }

    /**
     * @description get the is community attribute
     */
    @wire(ctrlGetCommunityInfo)
    wireGetCommunityInfo(result){
        this.consoleLog('wireGetCommunityInfo');
        this.communityInfoResult = result;
        this.communityInfoResponse = null;

        if (result.data) {
            this.communityInfoResponse = JSON.parse(result.data.responseData);
            this.consoleLog(this.communityInfoResponse, true);
        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    @wire(MessageContext)
    messageContext;

    /**
     * @description subscribe to message channel to refresh the component
     */
    subscribeToMessageChannel() {
        if (!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                MESSAGE_CHANNEL,
                (message) => this.handleMessage(message)
            );
        }
    }

    /**
     * @description unsubscribe to message channel
     */
    unsubscribeToMessageChannel() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }
    
    /**
     * @description refresh when message received. this is to refresh the available requirements records when an individual achievement unit is created and related requirements are created.
     */
    handleMessage(message) {
        if(
            message.eventSource !== RequirementChecklist.name && 
            message.operation === 'refresh' && 
            message.recordId === this.recordId
        ) {
            this.dispatchEvent(new RefreshEvent());
        }
    }

    handlePublishRefresh() {
        this.publishRefresh();
    }
    
    publishRefresh(){
        let message = {
            eventSource: RequirementChecklist.name,
            recordId: this.recordId,
            operation: 'refresh'
        }
        publish(this.messageContext, MESSAGE_CHANNEL, message);
    }
    
    
    /**
     * @description return true if component is in community
     */
    get isCommunity() {
        return this.communityInfoResponse?.isCommunity;
    }

    /**
     * @description return site path
     */
    get sitePath() {
        return this.communityInfoResponse?.sitePath;
    }

    /**
     * @description Handle refresh button
     */
    handleRefreshOnclick() {
        
        this.consoleLog('handleRefreshOnclick');
        this.dispatchEvent(new RefreshEvent());
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
        logInfo('RequirementChecklist', anything, this.enableDebugMode, isJson);
    }
	
}