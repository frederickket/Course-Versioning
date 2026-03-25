/**
 * @Author 		WDCi (Sueanne)
 * @Date 		April 2024
 * @group 		Study Pathway
 * @Description Study pathway wizard
 * @changehistory
 * ISS-001917 02-04-2024 Sueanne - new component
 * ISS-002191 26-11-2024 XW - Hardcoded url link if link is not generated and allow hreftarget
 * ISS-002189 16-12-2024 XW - show study unit quick search
 * ISS-002230 22-01-2025 XW - replace hardcoded label to custom label
 * ISS-002230 05-02-2025 XW - added studyPathwayUnitTitleField and studyPathwayGroupTitleField
 * ISS-002330 19-03-2025 XW - display translated name in requiredSP, optionalSP and applicableSP if found
 */
import { LightningElement, api, wire, track } from 'lwc';
import { promptError } from 'c/toasterUtil';
import { getErrorMessage, logInfo } from 'c/loggingUtil';
import { customLabels } from 'c/labelLoader';
import { NavigationMixin } from 'lightning/navigation';

import NUMBER_SELECT_FROM_GROUP_LABEL from '@salesforce/label/c.Number_Select_From_Group';
import REQUIRED_FOR_LABEL from '@salesforce/label/c.Required_For';
import OPTIONAL_FOR_LABEL from '@salesforce/label/c.Optional_For';
import APPLICABLE_STUDY_PLAN_LABEL from '@salesforce/label/c.Applicable_Study_Plan';

//refresh module
import { refreshApex } from '@salesforce/apex';
import { registerRefreshHandler, unregisterRefreshHandler } from 'lightning/refresh';

//Apex methods
import ctrlGetStudyPathwayUnit from '@salesforce/apex/REDU_StudyPathwayUnit_LCTRL.getStudyPathwayUnit';
import ctrlGetStudyPlanStructureList from '@salesforce/apex/REDU_StudyPathwayUnit_LCTRL.getStudyPlanStructureList';
import ctrlGetRelatedSpuList from '@salesforce/apex/REDU_StudyPathwayUnit_LCTRL.getRelatedSpuList';
import ctrlGetCommunityInfo from '@salesforce/apex/REDU_StudyPathwayUnit_LCTRL.getCommunityInfo'
import ctrlGetTranslationFieldForNameByObjPrefix from '@salesforce/apex/REDU_Translation_LCTRL.getTranslationFieldForNameByObjPrefix';
 
const OBJ_TRANSLATION = [
    "SPL"
];

export default class StudyPathwayUnit extends NavigationMixin(LightningElement) {
	
	//configurable attributes
	@api enableDebugMode;
    @api selectedSpo;
    @api studyPlanId; //default study plan id
    @api studyPathwayTermId;
    @api studyPathwayUnitTitleField;
    @api studyPathwayUnitId;
    @api studyPathwayUnitInfoFields;
    @api studyPathwayUnitIcon;
    @api studyPathwayGroupTitleField;
    @api studyPathwayGroupInfoFields;
    @api studyPathwayGroupIcon;
    @api hrefTargetType
    @api studyUnitSearchString; //ISS-002189

	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false;
	loadedLists = 0;
    isCommunity = false;
    sitePathPrefix;

    //other attributes
    getUrl;
	
    //refresh handler
    refreshHandlerID;

    //wire attribute
    studyPathwayUnitResult;
    studyPathwayUnitRecord;

    structureListResult;
    structureListRecord;

    relatedSpuListResult;
    relatedSpuListRecord;

    @track objectTranslatedNameResult;
    @track objectTranslatedNameResponse;

	//labels
	label = {
        NUMBER_SELECT_FROM_GROUP_LABEL,
        REQUIRED_FOR_LABEL,
        OPTIONAL_FOR_LABEL,
        APPLICABLE_STUDY_PLAN_LABEL,
        ...customLabels
    };
	
	//js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'jquery'
    modules = ['stringutil'];
	
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

        refreshApex(this.studyPathwayUnitResult);
        refreshApex(this.structureListResult);

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
        logInfo('StudyPathwayUnit', anything, this.enableDebugMode, isJson);
    }
	

    /**
     * @description get study pathway unit record
     */
    @wire(ctrlGetStudyPathwayUnit, {
        studyPathwayUnitId: "$studyPathwayUnitId",
        additionalFields: '$additionalFields'
    })
    wireStudyPathwayUnitRecord(result) {
        
        this.studyPathwayUnitResult = result;
        this.studyPathwayUnitRecord = null;

        if (result.data) {
            this.studyPathwayUnitRecord = JSON.parse(result.data.responseData);
            this.consoleLog(this.studyPathwayUnitRecord, true);
        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }

    }

    get additionalFields() {
        let result = [];
        if(this.studyPathwayUnitTitleField) {
            result.push('reduivy__Study_Unit__r.' + this.studyPathwayUnitTitleField);
        }
        if(this.studyPathwayGroupTitleField) {
            result.push('reduivy__Study_Plan_Group__r.' + this.studyPathwayGroupTitleField);
        }
        
        return result;
    }
    
    /**
     * @description get community info
     */
    @wire(ctrlGetCommunityInfo)
    wireGetCommunityInfo(result) {
        if(result.data){
            let responseData = JSON.parse(result.data.responseData);
            this.isCommunity = responseData?.isCommunity;
            this.sitePathPrefix = responseData?.sitePathPrefix;
        }
    }

    /**
     * @description get study unit Id from study pathway unit
     */
    get studyUnitId(){
        if(this.studyPathwayUnitRecord && !this.isGroup){
            return this.studyPathwayUnitRecord.reduivy__Study_Unit__c;
        }
        return null;
    }

    /**
     * @description get study plan group Id from study pathway unit
     */
    get studyPlanGroupId(){
        if(this.studyPathwayUnitRecord && this.isGroup){
            return this.studyPathwayUnitRecord.reduivy__Study_Plan_Group__c;
        }
        return null;
    }

    /**
     * @description use for html to check the availability of records
     */
    get showUnitContent(){
        // ISS-002189 consider studyUnitSearchString
        let recordFound = this.studyPathwayUnitRecord && this.studyPathwayUnitId;
        if(!recordFound) {
            return false;
        }
        if(!this.studyUnitSearchString) {
            return true;
        }
        let name;

        if(!this.isGroup){
            name = this.studyPathwayUnitRecord.reduivy__Study_Unit__r?.[this.splNameTranslationField]?.toUpperCase();
            if(!name) {
                name = this.studyPathwayUnitRecord.reduivy__Study_Unit__r?.Name?.toUpperCase();
            }
        } else {
            name = this.studyPathwayUnitRecord.reduivy__Study_Plan_Group__r?.[this.splNameTranslationField]?.toUpperCase();
            if(!name) {
                name = this.studyPathwayUnitRecord.reduivy__Study_Plan_Group__r?.Name?.toUpperCase();
            }
        }
        let searchStringList = this.studyUnitSearchString.toUpperCase().split(' ');
        
        for(let word of searchStringList) {
            if(name.includes(word)) {
                return true;
            }
        }
        return false;
    }

    /**
     * @description return study unit name based on current study pathway unit group or unit
     */
    get tileName() {
        if (this.studyPathwayUnitRecord && !this.isGroup) {
            return this.studyPathwayUnitRecord?.reduivy__Study_Unit__r?.[this.studyPathwayUnitTitleField];
        }
        return this.studyPathwayUnitRecord?.reduivy__Study_Plan_Group__r?.[this.studyPathwayGroupTitleField];
    }

    /**
     * @description return study unit icon based on current study pathway unit group or unit
     */
    get tileIcon(){
        if (this.studyPathwayUnitRecord && !this.isGroup) {
            return this.studyPathwayUnitIcon;
        }
        return this.studyPathwayGroupIcon;
    }

    /**
     * @description generate url for study plan unit or group
     */
    async getGenerateUrl(recId, objApi){
        // this[NavigationMixin.GenerateUrl]({
        //     type: 'standard__recordPage',
        //     attributes: {
        //         recordId: recId, 
        //         objectApiName: objApi, 
        //         actionName: 'view'
        //     }
        // }).then(url => {
        //     return url;
        // });

        this.getUrl = await this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recId, 
                objectApiName: objApi, 
                actionName: 'view'
            }
        });
    }

    /**
     * @description get the generated the study unit url
     */
    get studyUnitOrGrpUrl() {
        if(this.isGroup){
            this.getGenerateUrl(this.studyPlanGroupId, 'reduivy__Study_Plan_Structure__c');
        }else if(!this.isGroup){
            this.getGenerateUrl(this.studyUnitId, 'reduivy__Study_Unit__c');
        }

        //ISS-002191 GenerateUrl will always generate 'javascript:void(0);' for us in modal, so we need to check if the url contains 'javascript'. 
        //return hardcoded url link if url is not valid.
        if(this.getUrl && !this.getUrl.includes('javascript')){
            return this.getUrl;
        }
        //ISS-002187
        if(this.isCommunity){
            let path;
            if(this.sitePathPrefix.endsWith("/")){
                path = this.sitePathPrefix + 'detail';
            } else {
                path = this.sitePathPrefix + '/detail';
            }
            return `${path}/${this.isGroup ? this.studyPlanGroupId : this.studyUnitId}`;
        }
        //NavigationMixin generate url is not usable in modal and flow, so we hardcode the url 
        return `/lightning/r/${this.isGroup ? this.studyPlanGroupId : this.studyUnitId}/view`;
        
    }
    
    /**
     * @description use for html to check if study pathway unit is group
     */
    get isGroup(){
        if(this.studyPathwayUnitRecord){
            let spu = this.studyPathwayUnitRecord;
            if(spu.reduivy__Number_of_Units_from_Group__c && spu.reduivy__Study_Plan_Group__c){
                return true;
            }
        }
        return false;
    }

    /**
     * @description to construct the label for study pathway group
     */
    get numOfGroupLabel(){
        if(this.isGroup === true && this.studyPathwayUnitRecord && this.isLoading === false){ //ISS-002189
            return this.label.NUMBER_SELECT_FROM_GROUP_LABEL.format([this.studyPathwayUnitRecord.reduivy__Number_of_Units_from_Group__c]);
        }
        return null;
    }

    /**
     * @description store the study plan id that will show the data (selected in combobox + default study plan)
     */
    get studyPlanIdArray(){
        if(this.selectedSpo.length > 0 && this.studyPlanId){
            let studyPlanIds = this.selectedSpo.map(item => item.studyPlanId);
            studyPlanIds.push(this.studyPlanId);
            return studyPlanIds;
        }
        return [this.studyPlanId];
    }

    /**
     * @description gather the study pathway units that have same studyUnitId in same studyPathTermId
     */
    @wire(ctrlGetRelatedSpuList, {
        studyUnitId: '$studyUnitId',
        studyPathTermId: '$studyPathwayTermId',
        selectedDefaultSpList: '$studyPlanIdArray'
    })
    wireRelatedSpuList(result){
        this.relatedSpuListResult = result;
        this.relatedSpuListRecord = null;

        if (result.data) {
            this.relatedSpuListRecord = JSON.parse(result.data.responseData);
            this.consoleLog(this.relatedSpuListRecord, true);
        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    /**
     * @description return study plan id list from relatedSpuListRecord wire where: 
     * the study plan id(selected + default study plan id) available in relatedSpuListRecord(a study pathway unit list, which may contains duplicate study unit)
     */
    get availableStudyPlanIdList(){
        let relatedSpuIdList = [];
        if(this.relatedSpuListRecord){
            for(let relatedSpu of this.relatedSpuListRecord){
                if(relatedSpu.reduivy__Applicable_Study_Plan__c == null){
                    relatedSpuIdList.push(this.studyPlanId);
                }else{
                    relatedSpuIdList.push(relatedSpu.reduivy__Applicable_Study_Plan__c);
                }
            }
        }
        return relatedSpuIdList;
    }

    /**
     * @description get study plan structure list by study plan id list and study unit
     */
    @wire(ctrlGetStudyPlanStructureList, {
        studyPlanIdList: '$availableStudyPlanIdList',
        studyUnitId: '$studyUnitId'
    })
    wireStudyPlanStructureList(result){
        this.structureListResult = result;
        this.structureListRecord = null;

        if (result.data) {
            this.structureListRecord = JSON.parse(result.data.responseData);
            this.consoleLog(this.structureListRecord, true);
        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    /**
     * @description Get Study Plan Translation
     */
    @wire(ctrlGetTranslationFieldForNameByObjPrefix, { objectPrefixes: OBJ_TRANSLATION })
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
     * @description return the formatted required study plan array from wireStudyPlanStructureList
     */
    get requiredSP(){
        if(this.structureListRecord && this.structureListRecord.required){
            return this.structureListRecord.required.join(', ');
        }
        return '';
    }

    /**
     * @description return the formatted optional study plan array from wireStudyPlanStructureList
     */
    get optionalSP(){
        if(this.structureListRecord && this.structureListRecord.optional){
            return this.structureListRecord.optional.join(', ');
        }
        return '';
    }
    
    /**
     * @description return the formatted applicable study plan array from relatedSpuListRecord
     */
    get applicableSP(){
        let applicableSpuList = [];
        if(this.relatedSpuListRecord){
            for(let relatedSpu of this.relatedSpuListRecord){
                if(relatedSpu.reduivy__Applicable_Study_Plan__c != null){
                    let name = relatedSpu.reduivy__Applicable_Study_Plan__r?.[this.splNameTranslationField];
                    if(!name) {
                        name = relatedSpu.reduivy__Applicable_Study_Plan__r?.Name;
                    }
                    applicableSpuList.push(name);
                }
            }
            return applicableSpuList.join(', ');
        }
        return applicableSpuList;
    }

    /**
     * @description Return a list of study pathway fields
     */
    get infoFields() {
        if (!this.isGroup && this.studyPathwayUnitInfoFields) {
            return this.studyPathwayUnitInfoFields.split(';');
        }else if(this.isGroup && this.studyPathwayGroupInfoFields){
            return this.studyPathwayGroupInfoFields.split(';');
        }
        return [];
    }

    /**
     * @description return the study plan translation field for name
     */
    get splNameTranslationField() {
        return this.objectTranslatedNameResponse?.SPL;
    }


}