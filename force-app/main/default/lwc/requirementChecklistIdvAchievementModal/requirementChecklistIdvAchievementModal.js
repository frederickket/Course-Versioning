/**
 * @Author 		WDCi (XW)
 * @Date 		Jan 2024
 * @group 		
 * @Description 
 * @changehistory
 * ISS-002128 30-06-2025 XW - new cmp
 */
import { LightningElement, api, wire, track } from 'lwc';
import { promptInfo, promptError, promptWarning, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';
import { initCacheIdx, flattenObj, commonConstants } from 'c/lwcUtil';
import { customLabels } from 'c/labelLoader';
import LightningModal from 'lightning/modal';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import IAC_OBJ from '@salesforce/schema/Individual_Achievement__c'

//refresh module
import { refreshApex } from '@salesforce/apex';
import { registerRefreshHandler, unregisterRefreshHandler } from 'lightning/refresh';

//Apex methods
import ctrlGetDocumentsAndIACs from '@salesforce/apex/REDU_RequirementChecklistIdvAc_LCTRL.getDocumentsAndIACs';
import ctrlInsertAndDeleteCdl from '@salesforce/apex/REDU_RequirementChecklistIdvAc_LCTRL.insertAndDeleteCdl';

import SELECT_IAC_TO_LINK_LABEL from '@salesforce/label/c.Requirement_Checklist_Select_Iac_To_Link';
import NO_DOCUMENTS_FOUND_LABEL from '@salesforce/label/c.Requirement_Checklist_No_Documents_Found';
import NO_OBJECT_FOUND_LABEL from '@salesforce/label/c.No_Object_found';

import recordEditModal from 'c/recordEditModal';

const RESPONSE_CDC_LIST = 'RESPONSE_CDC_LIST';
const RESPONSE_IAC_LIST = 'RESPONSE_IAC_LIST';
const RESPONSE_CDC_IAC_MAP = 'RESPONSE_CDC_IAC_MAP';
const RESPONSE_CDCIAC_CDLID_MAP = 'RESPONSE_CDCIAC_CDLID_MAP';

export default class RequirementChecklistIdvAchievement extends LightningModal {
	
	//configurable attributes
    @api headerLabel;
    @api irqId;
    @api conId;
    @api achievementDetailsFields;
    @api createAchievementDetailsFieldSet;
	@api enableDebugMode = false;
	
	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false
	loadedLists = 0;
	
    //refresh handler
    refreshHandlerID;

    //local cache idx to force rerendering
    _cacheIdx;

    //wire attribute
    documentsAndIACsResult;
    documentsAndIACsResponse;

	//js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'jquery', 'tooltips'
    modules = ['stringutil'];
	

    @wire(getObjectInfo, { objectApiName: IAC_OBJ })
    iacObj;

    get iacObjectApiName() {
        return this.iacObj?.data?.apiName;
    }

    get iacObjectLabel() {
        return this.iacObj?.data?.label;
    }
    
    get iacPluralObjectLabel() {
        return this.iacObj?.data?.labelPlural;
    }

    /**
     * @description get the related documents and individual achievements
     */
    @wire(ctrlGetDocumentsAndIACs, {
        irqId: "$irqId",
        conId: "$conId",
        achievementDetailsFields: "$achievementDetailsFieldsList",
        cacheIdx: '$_cacheIdx'
    })
    wireGetDocumentsAndIACs(result) {
        this.consoleLog('wireGetDocumentsAndIACs');
        this.documentsAndIACsResult = result;
        this.documentsAndIACsResponse = null;

        if (result.data) {
            this.documentsAndIACsResponse = JSON.parse(result.data.responseData);
            this.consoleLog(this.documentsAndIACsResponse, true);
        } else if (result.error) {
            promptError(customLabels.ERROR_LABEL, getErrorMessage(result.error));
        }

    }

    /**
     * @description list of content document
     */
    get cdcList() {
        return this.documentsAndIACsResponse ? this.documentsAndIACsResponse[RESPONSE_CDC_LIST] : [];
    }

    /**
     * @description list of individual achievement
     */
    get iacList() {
        return this.documentsAndIACsResponse ? this.documentsAndIACsResponse[RESPONSE_IAC_LIST] : [];
    }
    
    /**
    * @description map of content document d to list of individual achievement id
    */
    get cdcToIacMap() {
        return this.documentsAndIACsResponse ? this.documentsAndIACsResponse[RESPONSE_CDC_IAC_MAP] : {};
    }
    
    get cdcIacToCdlIdMap() {
        return this.documentsAndIACsResponse ? this.documentsAndIACsResponse[RESPONSE_CDCIAC_CDLID_MAP] : {};
    }

    /**
     * @description if document and individual achievement is found, message is not shown. else it will display the relavant error message
     */
    get noObjectFoundMessage() {
        if(!this.documentsAndIACsResponse) {
            return customLabels.LOADING_LABEL;
        }
        if(this.cdcList.length === 0) {
            return NO_DOCUMENTS_FOUND_LABEL;
        } else if (this.iacList.length === 0) {
            return NO_OBJECT_FOUND_LABEL.format([this.iacPluralObjectLabel]);
        }
        return '';
    }

    /**
     * @description the wrapper list that is used in the component html
     */
    get cdcWrapperList() {
        let result = [];
        for(let cdc of this.cdcList) {
            
            let iacWrapperList = [];
            
            for(let iac of this.iacList) {
                let iacWrapper = {};
                iacWrapper.iac = iac;
                iacWrapper.checked = this.cdcToIacMap?.[cdc.Id]?.includes(iac.Id);
                iacWrapper.cdcIacKey = cdc.Id + '_' + iac.Id;

                let flattenIac = flattenObj(iac);
                let iacDetailWrapper = [];
                for(let iacField of this.achievementDetailsFieldsList) {
                    iacDetailWrapper.push({
                        label: this.iacObj?.data?.fields?.[iacField]?.label,
                        value: Object.hasOwn(flattenIac, iacField + commonConstants.PICKLIST_LABEL) ? flattenIac[iacField + commonConstants.PICKLIST_LABEL] : flattenIac[iacField],
                        apiName: iacField
                    });
                }
                iacWrapper.iacDetailWrapper = iacDetailWrapper;

                iacWrapperList.push(iacWrapper);
            }

            let cdcName = cdc.Title + '.' + cdc.FileExtension;
            
            result.push({
                id: cdc.Id,
                name: cdcName,
                iacSectionLabel: SELECT_IAC_TO_LINK_LABEL.format([this.iacPluralObjectLabel, cdcName]),
                iacWrapperList: iacWrapperList
            });
        }

        return result;
    }

    /**
     * @description new individual achievement button label 
     */
    get newIndividualAchievementLabel() {
        return customLabels.NEW_RECORD_LABEL.format([this.iacObjectLabel]);
    }

    /**
     * @description create the individual achievement when the button is clicked
     */
    async handleCreateIndividualAchievement() {
        this.consoleLog('handleCreateIndividualAchievement');
        try {
            this.toggleSpinner(1);
            let result = await recordEditModal.open({
                size: "small",
                headerLabel: customLabels.NEW_RECORD_LABEL.format([this.iacObjectLabel]),
                enableDebugMode: this.enableDebugMode,
                objectApiName: this.iacObjectApiName,
                fieldSetName: this.createAchievementDetailsFieldSet,
                editFormColumnNo: 2
            });

            if(result) {
                const {operation, eventResult, eventData} = result;
                if(operation === 'submit' && eventResult === 'success') {
                    this.consoleLog('eventData');
                    this.consoleLog(eventData, true);
                    promptSuccess(customLabels.SUCCESS_LABEL, customLabels.RECORD_CREATED_LABEL.format([this.iacObjectLabel]));
                }
            }

            this.consoleLog('handleCreateIndividualAchievement.close');
            this.refreshData();
            
            this.toggleSpinner(-1);
        } catch(error) {
            promptError(customLabels.ERROR_LABEL, getErrorMessage(error));
        }
    }

    /**
     * @description edit the individual achievement when the button is clicked
     */
    async handleEditIndividualAchievement(event) {
        this.consoleLog('handleEditIndividualAchievement');
        try {
            this.toggleSpinner(1);
            let result = await recordEditModal.open({
                size: "small",
                headerLabel: customLabels.EDIT_RECORD_LABEL.format([this.iacObjectLabel]),
                enableDebugMode: this.enableDebugMode,
                objectApiName: this.iacObjectApiName,
                fieldSetName: this.createAchievementDetailsFieldSet,
                editFormColumnNo: 2,
                recordId: event.currentTarget.dataset.id
            });

            if(result) {
                const {operation, eventResult, eventData} = result;
                if(operation === 'submit' && eventResult === 'success') {
                    this.consoleLog('eventData');
                    this.consoleLog(eventData, true);
                    promptSuccess(customLabels.SUCCESS_LABEL, customLabels.RECORD_SAVED_LABEL);
                }
            }

            this.consoleLog('handleEditIndividualAchievement.close');
            this.refreshData();
            
            this.toggleSpinner(-1);
        } catch(error) {
            promptError(customLabels.ERROR_LABEL, getErrorMessage(error));
        }
    }

    /**
     * @description the additional individual achievement field to be displayed on the screen in list form
     */
    get achievementDetailsFieldsList() {
        if(this.achievementDetailsFields) {
            return this.achievementDetailsFields.split(';');
        }
        return [];
    }
    
    /**
     * @description cancel label
     */
    get cancelLabel() {
        return customLabels.CLOSE_LABEL;
    }
    
    /**
     * @description save label
     */
    get saveLabel(){
        return customLabels.SAVE_LABEL;
    }
    
    /**
     * @description handle cancel click
     */
    handleCancelClick() {
        this.close({operation: "cancel"});
    }
    
    /**
     * @description save the result of inserting/deleting the content document link
     */
    async handleSaveClick() {
        //get all of the checkbox
        let elements = this.template.querySelectorAll('.requirementchecklistidvacmodal-iaccheckbox');
        this.consoleLog(elements, true);

        let cdlListToDelete = [];
        let cdlListToInsert = {};
        for(let element of elements) {
            let [cdcId, iacId] = element.name.split('_');
            
            if(this.cdcToIacMap[cdcId].find(id => id === iacId) && element.checked === false) {
                let cdlId = this.cdcIacToCdlIdMap[element.name];
                cdlListToDelete.push(cdlId);
            } else if(element.checked === true && !this.cdcToIacMap[cdcId].find(id => id === iacId)) {
                if(Object.keys(cdlListToInsert).includes(cdcId)) {
                    cdlListToInsert[cdcId].push(iacId);
                } else {
                    cdlListToInsert[cdcId] = [iacId];
                }
            }
        }

        this.consoleLog(cdlListToDelete, true);
        this.consoleLog(cdlListToInsert, true);

        try {
            let result = await ctrlInsertAndDeleteCdl({cdlIdToDelete: cdlListToDelete, cdcToLinkToIac: JSON.stringify(cdlListToInsert)});
            
            let recordIdList = [];
            if(result.responseData) {
                let responseData = JSON.parse(result.responseData);
                this.consoleLog(responseData);
                if(responseData.length > 0) {
                    for(let id of responseData) {
                        recordIdList.push({recordId: id});
                    }
                }
                
                this.close({operation: 'close', eventSource: 'submit', eventData: recordIdList});
            }

        } catch (error) {
            promptError(customLabels.ERROR_LABEL, getErrorMessage(error));
        }
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
		this.refreshHandlerID = registerRefreshHandler(this, this.refreshData);
        this._cacheIdx = initCacheIdx();
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
        
        //update the cacheIdx if you need to force the wire method to get new data from apex
        this._cacheIdx = initCacheIdx();

        refreshApex(this.documentsAndIACsResult);

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
        logInfo('RequirementChecklistIdvAchievement', anything, this.enableDebugMode, isJson);
    }
	
}