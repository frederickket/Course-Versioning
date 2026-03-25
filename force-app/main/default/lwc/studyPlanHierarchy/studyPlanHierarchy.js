/**
 * @Author 		WDCi (Lean)
 * @Date 		Nov 2023
 * @group 		Study Plan
 * @Description Study plan hierarchy wizard
 * @changehistory
 * ISS-001617 10-11-2023 Lean - new component
 * ISS-002152 29-10-2024 Jordan - Study Plan Wizard to support modification
 * ISS-002230 05-02-2025 XW - added spsGroupTitleField 
 * ISS-002330 24-03-2025 XW - display sps translation name in delete confirmation if found
 * ISS-002654 03-10-2025 Lean - Column number shared util
 * ISS-002650 10-11-2025 XW - replace refreshHandler to refreshContainer
 * ISS-002736 25-11-2025 XiRouh - Added tableTextDisplayMode configurable attribute
 */
import { LightningElement, api, wire } from 'lwc';
import { promptError, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo } from 'c/loggingUtil';
import { studyPlanHierarchyConstants } from 'c/studyPlanHierarchyHelper';
import { customLabels } from 'c/labelLoader';
import { getColumnSize } from 'c/lwcUtil';

//refresh module
import { refreshApex } from '@salesforce/apex';
import { RefreshEvent, registerRefreshContainer, unregisterRefreshContainer } from 'lightning/refresh';

//Apex methods
import getTopLevelGroups from '@salesforce/apex/REDU_StudyPlanHierarchy_LCTRL.getTopLevelGroups';
import getSpsRecordTypeInfo from '@salesforce/apex/REDU_StudyPlanHierarchy_LCTRL.getSpsRecordTypeInfo';
import getGroupFieldSet from '@salesforce/apex/REDU_StudyPlanHierarchy_LCTRL.getGroupFieldSet';
import getUnitFieldSet from '@salesforce/apex/REDU_StudyPlanHierarchy_LCTRL.getUnitFieldSet';
import getCommunityInfo from '@salesforce/apex/REDU_StudyPlanHierarchy_LCTRL.getCommunityInfo';
import deleteStudyPlanStructure from '@salesforce/apex/REDU_StudyPlanHierarchy_LCTRL.deleteStudyPlanStructure';

import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import SPS_OBJECT from '@salesforce/schema/Study_Plan_Structure__c';

import studyPlanHierarchyModal from "c/studyPlanHierarchyModal";
import genericConfirmationModal from 'c/genericConfirmationModal';

export default class StudyPlanHierarchy extends LightningElement {
	
	//configurable attributes
    @api recordId; // study plan recordId

    @api modalTitle;
    @api modalIconName;
    @api showSplInfo = false;
    @api splInfoFields; // Semi-colon separated list of field API names for study plan group highlights
    @api splInfoColumnNo;
    @api showSpsGroupInfo = false;
    @api spsGroupTitleField;
    @api spsGroupInfoFields; // Semi-colon separated list of field API names for study plan structure group highlights
    @api spsGroupInfoColumnNo;
    @api accordionBackgroundColor;
    @api accordionTextColor;
    @api spsUnitTableFields; // Semi-colon separated list of fields for sps unit table
    @api enableClickableRefField = false;
    @api hrefTargetType;
    @api mode;
    @api groupFieldSetName;
    @api unitFieldSetName;

    @api tableTextDisplayMode;
    
	@api enableDebugMode = false;
	
    //obsolete
    @api forCommunity = false;

	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false;
	loadedLists = 0;
    nextLevel = 1; //this is to indicates the current level of group
	
    //refresh Container
    refreshContainerID;

    //wire attribute
    topGroupsWireResult;
    topGroupsResponse;
    spsRecordTypeInfoWireResult;
    spsRecordTypeInfoResponse;
    groupFieldSetWireResult;
    groupFieldSetResponse;
    unitFieldSetWireResult;
    unitFieldSetResponse;
    communityInfoWireResult;
    communityInfoResponse;

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

        refreshApex(this.topGroupsWireResult);

        return new Promise((resolve) => {
            resolve(true);
        });

    }

    @wire(getCommunityInfo, {})
    wiredCommunityInfo(result) {
        this.communityInfoWireResult = result;

        if (result.data) {
            this.communityInfoResponse = JSON.parse(result.data.responseData);
            this.consoleLog(this.communityInfoResponse, true);

        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    /**
     * @description Return true if current context is community
     */
    get isCommunity() {
        return this.communityInfoResponse?.isCommunity;
    }

    /**
     * @description Sample wire method that invoke apex controller to retrieve data
     */
    @wire(getTopLevelGroups, {
        splId: "$recordId"
    })
    wireTopLevelGroups(result) {
        
        this.topGroupsWireResult = result;
        this.topGroupsResponse = null;

        if (result.data) {
            this.topGroupsResponse = JSON.parse(result.data.responseData);
            this.consoleLog(this.topGroupsResponse, true);
        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }

    }

    /**
     * @description Get SPS record type info
     */
    @wire(getSpsRecordTypeInfo)
    wireSpsRecordTypeInfo(result) {
        
        this.spsRecordTypeInfoWireResult = result;
        this.spsRecordTypeInfoResponse = null;

        if (result.data) {
            this.spsRecordTypeInfoResponse = JSON.parse(result.data.responseData);
            this.consoleLog(this.spsRecordTypeInfoResponse, true);
        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }

    }

    /**
     * @description Get group field set
     */
    @wire(getGroupFieldSet, {
        groupFieldSetName: "$groupFieldSetName"
    })
    wireGroupFieldSet(result) {
        
        this.groupFieldSetWireResult = result;
        this.groupFieldSetResponse = null;

        if (result.data) {
            this.groupFieldSetResponse = JSON.parse(result.data.responseData);
            this.consoleLog(this.groupFieldSetResponse, true);
        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }

    }

    /**
     * @description Get unit field set
     */
    @wire(getUnitFieldSet, {
        unitFieldSetName: "$unitFieldSetName"
    })
    wireUnitFieldSet(result) {
        
        this.unitFieldSetWireResult = result;
        this.unitFieldSetResponse = null;

        if (result.data) {
            this.unitFieldSetResponse = JSON.parse(result.data.responseData);
            this.consoleLog(this.unitFieldSetResponse, true);
        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }

    }

    /**
     * @description Get object info
     */
    @wire(getObjectInfo, { objectApiName: SPS_OBJECT })
    spsObjInfo;

    /**
     * @description Return true if view only
     */
    get isModeView() {
        if (this.mode === 'Edit') {
            return false;
        }

        return true;
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
     * @description Return top level groups
     */
    get topGroups() {
        if (this.topGroupsResponse) {
            return this.topGroupsResponse;
        }

        return null;
    }

    /**
     * @description Return a list of individual pathway fields
     */
    get infoFields() {
        if (this.splInfoFields) {
            return this.splInfoFields.split(';');
        }

        return [];
    }

    /**
     * @description Return the layout item size
     */
    get infoFieldSize() {
        return getColumnSize(this.splInfoColumnNo, 4);
    }

    /**
     * @description ISS-002152 Return new group label
     */
    get newGroupLabel(){
        return this.label.NEW_RECORD_LABEL.format([this.spsGroupRecordTypeLabel]);
    }

    /**
     * @description Return sps unit fields
     */
    get unitFields() {
        if (this.unitFieldSetResponse?.unitFields) {
            return this.unitFieldSetResponse?.unitFields;
        }

        return [];
    }

    /**
     * @description Return sps group fields
     */
    get groupFields() {
        if (this.groupFieldSetResponse?.groupFields) {
            return this.groupFieldSetResponse?.groupFields;
        }

        return [];
    }

    /**
     * @description Return SPS Group record type id
     */
    get spsGroupRecordTypeId() {
        return this.spsRecordTypeInfoResponse?.spsGroupRecordTypeId;
    }

    /**
     * @description Return SPS Group record type label
     */
    get spsGroupRecordTypeLabel() {
        return this.spsRecordTypeInfoResponse?.spsGroupRecordTypeLabel;
    }

    /**
     * @description Return SPS Unit record type id
     */
    get spsUnitRecordTypeId() {
        return this.spsRecordTypeInfoResponse?.spsUnitRecordTypeId;
    }

    /**
     * @description Return SPS Unit record type label
     */
    get spsUnitRecordTypeLabel() {
        return this.spsRecordTypeInfoResponse?.spsUnitRecordTypeLabel;
    }

    /**
     * @description Return SPS object label
     */
    get spsObjectLabel() {
        return this.spsObjInfo?.data?.label;
    }

    /**
     * @description Return true when ready to render child components, this is to avoid null data pass to the child components and causing invocation issue in wire methods
     */
    get isDataReady() {
        return this.unitFieldSetResponse?.unitFields &&
            this.groupFieldSetResponse?.groupFields &&
            this.spsRecordTypeInfoResponse && 
            this.topGroups
    }

    /**
     * @description Sample handle refresh button
     */
    handleRefreshOnclick(event) {
        this.dispatchEvent(new RefreshEvent());
    }

    /**
     * @description Handle new top group button click
     */
    handleNewTopGroupButtonClick(event) {
        let headerName = this.label.NEW_RECORD_LABEL.format([this.spsGroupRecordTypeLabel + " " + this.spsObjectLabel]);
        let columnSet = this.groupFields;

        this.openSpsEditModal(null, null, null, this.spsGroupRecordTypeId, headerName, columnSet, studyPlanHierarchyConstants.NEW_GROUP_ACTION);
    }

    /**
     * @description ISS-002152 This funtion is called when user clicks on button menu item
     */
    handleButtonEvent(event) {
        let actionType = event.detail.actionType;

        let spsId = event.detail.spsId;
        let spsName = event.detail.spsName;
        let spsTranslationName = event.detail.spsTranslationName;
        let spsParentId = event.detail.spsParentId;
        let spsType = event.detail.spsType;

        let headerName;
        let columnSet;

        let objectLabel = this.spsObjectLabel;

        if (actionType === studyPlanHierarchyConstants.DELETE_ACTION) {
            headerName = this.label.DELETE_RECORD_LABEL.format([objectLabel]);
            let deleteConfirmationMsg;

            if (spsType === this.spsGroupRecordTypeId) {
                deleteConfirmationMsg = this.label.DELETE_RECORD_WITH_CHILD_CONFIRMATION_LABEL.format([this.spsGroupRecordTypeLabel, spsTranslationName ? spsTranslationName : spsName ]);
            } else if (spsType === this.spsUnitRecordTypeId) {
                deleteConfirmationMsg = this.label.DELETE_RECORD_WITH_CHILD_CONFIRMATION_LABEL.format([this.spsUnitRecordTypeLabel, spsTranslationName ? spsTranslationName : spsName ]);
            }
            
            let data = {
                spsId: spsId,
                spsName: spsName,
                spsType: spsType
            };

            this.openDeleteConfirmationModal(headerName, deleteConfirmationMsg, data);

        } else {

            if (actionType === studyPlanHierarchyConstants.NEW_GROUP_ACTION) {
                headerName = this.label.NEW_RECORD_LABEL.format([this.spsGroupRecordTypeLabel + " " + objectLabel]);
                columnSet = this.groupFields;
    
            } else if (actionType === studyPlanHierarchyConstants.NEW_UNIT_ACTION) {
                headerName = this.label.NEW_RECORD_LABEL.format([this.spsUnitRecordTypeLabel + " " + objectLabel]);
                columnSet = this.unitFields;
    
            } else if (actionType === studyPlanHierarchyConstants.EDIT_ACTION) {
                if (spsType === this.spsGroupRecordTypeId) {
                    headerName = this.label.EDIT_RECORD_LABEL.format([this.spsGroupRecordTypeLabel + " " + objectLabel]);
                    columnSet = this.groupFields;
    
                } else if (spsType === this.spsUnitRecordTypeId) {
                    headerName = this.label.EDIT_RECORD_LABEL.format([this.spsUnitRecordTypeLabel + " " + objectLabel]);
                    columnSet = this.unitFields;
                }
    
            }
    
            this.openSpsEditModal(spsId, spsName, spsParentId, spsType, headerName, columnSet, actionType);
        }
    }

    /**
     * @description Open sps edit modal
     */
    openSpsEditModal(spsId, spsName, spsParentId, spsType, headerName, columnSet, actionType) {
        
        studyPlanHierarchyModal.open({
            size: 'small',
            modalTitle: headerName,
            actionType: actionType,
            studyPlanId: this.recordId,
            spsId: spsId,
            spsParentId: spsParentId,
            spsType: spsType,
            recordFormColumns: columnSet,
            enableDebugMode: this.enableDebugMode
        }).then((result) => {
            
            if (result && result.operation !== 'cancel') {
                this.dispatchEvent(new RefreshEvent());
            }
        });
    }

    /**
     * @description Open delete confirmation modal
     */
    openDeleteConfirmationModal(modalTitle, confirmationMsg, data) {
        //call genericConfirmationModal
        genericConfirmationModal.open({
            size: 'small',
            modalTitle: modalTitle,
            confirmationText1: confirmationMsg,
            eventSource: 'studyPlanHierarchy',
            eventData: data,
            showSubmitButton: true,
            submitButtonLabel: this.label.DELETE_LABEL,
            showCancelButton: true,
            cancelButtonLabel: this.label.CANCEL_LABEL,
            enableDebugMode: this.enableDebugMode
        })
        .then((result) => {
            if(result){

                const {operation, eventSource, eventData} = result;
                if(operation === 'submit'){
                    this.deleteSpsRecord(eventData);
                }
            }
        });
    }

    deleteSpsRecord(eventData) {
        this.toggleSpinner(1);
                
        deleteStudyPlanStructure({ 
            spsId: eventData?.spsId,
            spsType: eventData?.spsType
        }).then(result => {
            this.toggleSpinner(-1);

            promptSuccess(this.label.SUCCESS_LABEL, this.spsDeletedMessage);
            
            this.dispatchEvent(new RefreshEvent());

        }).catch((error) => {
            this.toggleSpinner(-1);
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
        })
    }

    /**
     * @description Return sps deleted message
     */
    get spsDeletedMessage() {
        if (this.spsObjectLabel) {
            return this.label.RECORD_DELETED_LABEL.format([this.spsObjectLabel]);
        }

        return null;
    }
	
    /**
     * @descripton Spinner loading status
     */
	get isLoading(){
        return this.loadedLists === 0 && this.topGroupsResponse ? false : true;
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
        logInfo('studyPlanHierarchy', anything, this.enableDebugMode, isJson);
    }
	
}