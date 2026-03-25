/**
 * @Author 		WDCi (XW)
 * @Date 		Nov 2025
 * @group 		Student Achievement
 * @Description The root LWC of Student Achievement
 * @changehistory
 * ISS-002633 14-11-2025 XW - new component
 */
import { LightningElement, api, wire, track } from 'lwc';
import { promptInfo, promptError, promptWarning, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';
import { initCacheIdx, getMergeKeys, mergeValues, commonConstants, extractFieldValue } from 'c/lwcUtil';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { customLabels } from 'c/labelLoader';
import LANG from "@salesforce/i18n/lang";
import { NavigationMixin } from 'lightning/navigation';

import IAC_OBJ from '@salesforce/schema/Individual_Achievement__c';

//refresh module
import { refreshApex } from '@salesforce/apex';
import { RefreshEvent, registerRefreshContainer, unregisterRefreshContainer } from 'lightning/refresh';

import ctrlGetIndividualAchievements from '@salesforce/apex/REDU_StudentAchievement_LCTRL.getIndividualAchievements';
import RECORD_SAVED_REVIEW_DOCUMENTS_LABEL from "@salesforce/label/c.Student_Achievement_Record_Saved_Review_Documents";

import recordEditModal from 'c/recordEditModal';

export default class StudentAchievement extends NavigationMixin(LightningElement) {
	
	//configurable attributes
    @api recordId;
    @api userMode;
    @api targetContactField;
    @api modalTitle;
    @api modalIconName;
	@api showQuickSearch = false;
    @api quickSearchKeyFields;
    @api individualAchievementGroupByField = '';
    @api individualAchievementTitleFormat = '';
    @api individualAchievementSubtitleFormat = '';
    @api individualAchievementInfoFields1 = '';
    @api individualAchievementInfoFields2 = '';

    @api showVerificationIndicator;
    @api showViewButton;
    @api showNewButton;
    @api showDeleteButton;

    @api individualAchievementPrecreationFieldSet;
    
	@api enableDebugMode = false;

	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false
	loadedLists = 0;
    quickSearchValue;
	
    //refresh Container
    refreshContainerID;

    //local cache idx to force rerendering
    _cacheIdx;

    //wire attribute
    @track rawIndividualAchievementsResult;
    @track rawIndividualAchievementsResponse;

	//labels
	label = customLabels;
	
	//js library module 'lodash',, 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'jquery', 'tooltips'
    modules = ['stringutil'];

    @wire(getObjectInfo, { objectApiName: IAC_OBJ })
    individualAchievementObjectInfo;

    get individualAchievementObjectLabel() {
        return this.individualAchievementObjectInfo?.data?.label;
    }

    get individualAchievementObjectApiName() {
        return this.individualAchievementObjectInfo?.data?.apiName ?? IAC_OBJ.objectApiName;
    }

    get individualAchievementTitleFields() {
        return getMergeKeys(this.individualAchievementTitleFormat, true);
    }

    get individualAchievementSubtitleFields() {
        return getMergeKeys(this.individualAchievementSubtitleFormat, true);
    }

    /**
     * @description get the list of individual achievement
     * @param {*} result 
     */
	@wire(ctrlGetIndividualAchievements, {
        recordId: "$recordId",
        contactField: "$targetContactField",
        additionalFields: "$individualAchievementAdditionalFields",
        language: "$language",
        cacheIdx: "$_cacheIdx"
    })
    wiredGetIndividualAchievements(result) {
        this.rawIndividualAchievementsResult = result;
        this.rawIndividualAchievementsResponse = null;

        if (result.data) {
            this.rawIndividualAchievementsResponse = JSON.parse(result.data.responseData);
            this.consoleLog(this.rawIndividualAchievementsResponse, true);
        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    get individualAchievementAdditionalFields() {
        let fields = [];
        if(this.individualAchievementGroupByField) {
            fields = fields.concat(this.individualAchievementGroupByField);
        }
        if(Array.isArray(this.individualAchievementTitleFields) && this.individualAchievementTitleFields.length > 0) {
            fields = fields.concat(this.individualAchievementTitleFields);
        }
        if(Array.isArray(this.individualAchievementSubtitleFields) && this.individualAchievementSubtitleFields.length > 0) {
            fields = fields.concat(this.individualAchievementSubtitleFields);
        }
        if(this.individualAchievementInfoFields1) {
            fields = fields.concat(this.individualAchievementInfoFields1.split(";"));
        }
        if(this.individualAchievementInfoFields2) {
            fields = fields.concat(this.individualAchievementInfoFields2.split(";"));
        }


        return fields;
    }

    get translationInfo() {
        return this.rawIndividualAchievementsResponse?.translationInfo ?? {}
    }

    /**
     * @description Return language
     */
    get language() {
        return LANG;
    }

    /**
     * @description list of individual achievement
     */
    get individualAchievementList() {
        return this.rawIndividualAchievementsResponse?.individualAchievementList ?? [];
    }

    /**
     * @description the mapping of the submission status type and its submission status
     */
    get fieldToDisplayTypeMap() {
        return this.rawIndividualAchievementsResponse?.fieldToDisplayTypeMap ?? [];
    }

    /**
     * @description the target contact id to display
     */
    get targetContactId() {
        return this.rawIndividualAchievementsResponse?.targetContactId ?? null;
    }

    /**
     * @description group individualAchievement together based on the user preference and display it in student achievement item
     */
    get groupedIndividualAchievementList() {
        if (this.individualAchievementList && this.individualAchievementList.length > 0) {
            let result = [];
            for(let individualAchievement of this.individualAchievementList) {

                individualAchievement.stringifyIndividualAchievement = JSON.stringify(individualAchievement);
                let quickSearchFieldMergeKey = getMergeKeys(this.quickSearchKeyFields);
                let searchKey = mergeValues(this.quickSearchKeyFields, quickSearchFieldMergeKey, individualAchievement, true, this.translationInfo, this.language);

                if(!this.quickSearchValue || searchKey.toLowerCase().includes(this.quickSearchValue.toLowerCase())) {

                    let individualAchievementGroupByFieldPicklist = this.individualAchievementGroupByField + commonConstants.PICKLIST_LABEL;
                    
                    let accordionTitle;
                    if(Object.hasOwn(individualAchievement, individualAchievementGroupByFieldPicklist)){
                        accordionTitle = extractFieldValue(individualAchievement, individualAchievementGroupByFieldPicklist, this.translationInfo, this.language);
                    } else {
                        accordionTitle = extractFieldValue(individualAchievement, this.individualAchievementGroupByField, this.translationInfo, this.language);
                    } 
                    if (!Object.prototype.hasOwnProperty.call(result, accordionTitle)) {
                        result[accordionTitle] = {
                            label: accordionTitle,
                            individualAchievementList: []
                        };
                    }
                    result[accordionTitle].individualAchievementList.push(individualAchievement);
                }
            }

            return Object.values(result);
        }

        return [];
    }

    get recordSavedReviewDocumentsLabel() {
        return RECORD_SAVED_REVIEW_DOCUMENTS_LABEL;
    }
    
    /**
     * @description create new achievement by opening create modal 
     */
    async handleNewAchievement(){
        try {
            let modalHeader = customLabels.NEW_RECORD_LABEL.format([this.individualAchievementObjectLabel]);
            let result = await recordEditModal.open({
                
                headerLabel: modalHeader,

                objectApiName: this.individualAchievementObjectApiName,
                fieldSetName: this.individualAchievementPrecreationFieldSet,
                editFormColumnNo: 2,
                size: 'small',
                enableDebugMode: this.enableDebugMode,
                enableNewParentCreation: this.userMode === commonConstants.USER_MODE_ADMIN,
                defaultValue: {reduivy__Contact__c: this.targetContactId}
            })

            if(result){
                const { operation, eventResult, eventData } = result;
                if(operation === 'submit' && eventResult === 'success') {
                    let individualAchievementId = eventData.Id;
                    this.consoleLog('recordEditModal.close.individualAchievementId = ' + individualAchievementId);
                    
                    promptSuccess(this.recordSavedReviewDocumentsLabel);

                    this.dispatchEvent(new RefreshEvent());
                    notifyRecordUpdateAvailable([{recordId: individualAchievementId}]);
                    
                    const individualAchievementPageRef = {
                        type: 'standard__recordPage',
                        attributes: {
                            recordId: individualAchievementId,
                            actionName: 'view'
                        },
                        state: {
                            reduivy__displayMode: 'edit'
                        }
                    }

                    this[NavigationMixin.Navigate] (individualAchievementPageRef);

                }
            }

        } catch(err) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(err));
        }
    }

    /**
     * @description quick search input change
     */
    handleQuickSearchChange(event) {
        this.quickSearchValue = event.detail.value;
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
     * @descripton connected callback
     */
    connectedCallback(){
		this.refreshContainerID = registerRefreshContainer(this, this.refreshData);
        this._cacheIdx = initCacheIdx();
	}
	
    /**
     * @descripton disconnected callback
     */
	disconnectedCallback() {
		unregisterRefreshContainer(this.refreshContainerID);
	}

    /**
     * @description Refresh data
     */
    refreshData() {
        this.consoleLog('refreshData');
        
        //update the cacheIdx if you need to force the wire method to get new data from apex
        this._cacheIdx = initCacheIdx();

        refreshApex(this.rawIndividualAchievementsResult);

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
        logInfo('StudentAchievement', anything, this.enableDebugMode, isJson);
    }
	
}