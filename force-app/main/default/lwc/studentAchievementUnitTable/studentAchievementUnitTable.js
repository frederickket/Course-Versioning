/**
 * @Author 		WDCi (XW)
 * @Date 		Dec 2025
 * @group 		StudentAchievement
 * @Description StudentAchievement unit table
 * @changehistory
 * ISS-002633 12-12-2025 XW - new class
 */
import { LightningElement, api, wire, track } from 'lwc';
import { promptInfo, promptError, promptWarning, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';
import { initCacheIdx, commonConstants, getMergeKeys, mergeValues, getFileDownloadUrl } from 'c/lwcUtil';
import { notifyRecordUpdateAvailable, updateRecord } from 'lightning/uiRecordApi';
import { shadeHexColorCode } from 'c/cssUtil';
import { customLabels } from 'c/labelLoader';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import LANG from "@salesforce/i18n/lang";
import genericConfirmationModal from 'c/genericConfirmationModal';
import studentAchievementUnitAdminModal from 'c/studentAchievementUnitAdminModal'
import studentAchievementUnitStudentModal from 'c/studentAchievementUnitStudentModal'
import { NavigationMixin } from "lightning/navigation";

//objects and fields
import IAU_OBJ from "@salesforce/schema/Individual_Achievement_Unit__c";
import IAC_OBJ from '@salesforce/schema/Individual_Achievement__c'
import IAC_VERIFICATION_STATUS_FIELD from "@salesforce/schema/Individual_Achievement_Unit__c.Verification_Status__c";

const LOCKING_MODE_LOCKED = 'Locked';
const LOCKING_MODE_UNLOCKED = 'Unlocked';

//refresh module
import { refreshApex } from '@salesforce/apex';
import { RefreshEvent, registerRefreshContainer, unregisterRefreshContainer } from 'lightning/refresh';

//Apex methods
import ctrlGetIndividualAchievementUnits from '@salesforce/apex/REDU_StudentAchievementUnitTable_LCTRL.getIndividualAchievementUnits';
import ctrlGetIdvAcWizardMetadata from '@salesforce/apex/REDU_StudentAchievement_LCTRL.getIdvAcWizardMetadata';
import ctrlGetIndividualAchievementRecord from '@salesforce/apex/REDU_StudentAchievementDetails_LCTRL.getIndividualAchievementRecord'
import ctrlGetIndividualAchievementVerificationStatusesInfo from '@salesforce/apex/REDU_StudentAchievement_LCTRL.getIndividualAchievementVerificationStatusesInfo';
import ctrlGetIndividualAchievementUnitVerificationStatusesInfo from '@salesforce/apex/REDU_StudentAchievementUnitTable_LCTRL.getIndividualAchievementUnitVerificationStatusesInfo';

//custom labels
import UNIT_IS_NOT_REQUIRED_LABEL from '@salesforce/label/c.Student_Achievement_Unit_Is_Not_Required';
import UNIT_IS_REQUIRED_LABEL from '@salesforce/label/c.Student_Achievement_Unit_Is_Required';
import COMPLETE_ALL_REQUIREMENTS_LABEL from '@salesforce/label/c.Student_Achievement_Complete_All_Requirements';
import PREVIEW_LABEL from '@salesforce/label/c.Requirement_Checklist_Preview';
import DOWNLOAD_LABEL from '@salesforce/label/c.Download';
import THE_RECORD_IS_LOCKED_LABEL from '@salesforce/label/c.The_Record_Is_Locked';
import UNIT_NAME_LABEL from '@salesforce/label/c.Student_Achievement_Unit_Name';
import UNIT_CODE_LABEL from '@salesforce/label/c.Student_Achievement_Unit_Code';
import SHOW_UPLOADED_FILES_LABEL from '@salesforce/label/c.Student_Achievement_Show_Uploaded_Files';
import HIDE_UPLOADED_FILES_LABEL from '@salesforce/label/c.Student_Achievement_Hide_Uploaded_Files';
import NO_MATCHED_OR_DEFAULT_WIZARD_CONFIG_RECORD_LABEL from '@salesforce/label/c.Student_Achievement_No_Matched_Or_Default_Wizard_Config';

//message
import { subscribe, unsubscribe, MessageContext, publish} from "lightning/messageService";
import MESSAGE_CHANNEL from "@salesforce/messageChannel/c__privateLwcMessageChannel__c"

const VERIFICATION_STATUS_TYPE_OPEN = 'Open';

export default class StudentAchievementUnitTable extends NavigationMixin(LightningElement) {
	
	//configurable attributes
    @api userMode;
    @api modalTitle;
    @api modalIconName;
    @api recordId; // individualAchievement id
    @api showNewButton = false;
    @api individualAchievementFormConfigurationName;
    @api verificationDetailsFieldSetName;
    @api agreementRecognitionUnitCreationFieldSetName;
    
    @api downloadUrl;
    
	@api enableDebugMode = false;

	
	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false
	loadedLists = 0
    @track individualAchievementUnitToAgreementRecognitionUnitValue = {};
    subscription = null;
    @track individualAchievementUnitShowFilesValue = {};
	
    //refresh Container
    refreshContainerID;

    //local cache idx to force rerendering
    _cacheIdx;

    //wire attribute
    @track individualAchievementUnitsResult;
    @track individualAchievementUnitsResponse;
    @track idvAcWizardMetadataResult;
    @track idvAcWizardMetadataResponse;
    @track individualAchievementRecordResult;
    @track individualAchievementRecordResponse;
    @track individualAchievementVerificationStatusesInfoResult;
    @track individualAchievementVerificationStatusesInfoResponse;
    @track individualAchievementUnitVerificationStatusesInfoResult;
    @track individualAchievementUnitVerificationStatusesInfoResponse;

	//labels
	label = {
        PREVIEW_LABEL,
        DOWNLOAD_LABEL,
        ...customLabels
    };
	
	//js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'jquery', 'tooltips'
    modules = ['stringutil'];

    //-----------------------------------------base--------------------------
    
    
    @wire(ctrlGetIndividualAchievementVerificationStatusesInfo) 
    wiredGetIndividualAchievementVerificationStatusesInfo(result) {
        
        this.individualAchievementVerificationStatusesInfoResult = result;
        this.individualAchievementVerificationStatusesInfoResponse = null;

        if (result.data) {
            this.individualAchievementVerificationStatusesInfoResponse = JSON.parse(result.data.responseData);
            this.consoleLog(this.individualAchievementVerificationStatusesInfoResponse, true);
        } else if (result.error) {
            promptError(customLabels.ERROR_LABEL, getErrorMessage(result.error));
        }
    }


    get individualAchievementLockedVerificationStatuses() {
        return this.individualAchievementVerificationStatusesInfoResponse?.lockingMode?.[LOCKING_MODE_LOCKED] ?? [];
    }

    get individualAchievementUnlockedVerificationStatuses() {
        return this.individualAchievementVerificationStatusesInfoResponse?.lockingMode?.[LOCKING_MODE_UNLOCKED] ?? [];
    }

    get individualAchievementVerificationStatusType() {
        return this.individualAchievementVerificationStatusesInfoResponse?.verificationStatusType ?? {};
    }

    @wire(ctrlGetIndividualAchievementUnitVerificationStatusesInfo) 
    wiredGetIndividualAchievementUnitVerificationStatusesInfo(result) {
        
        this.individualAchievementUnitVerificationStatusesInfoResult = result;
        this.individualAchievementUnitVerificationStatusesInfoResponse = null;

        if (result.data) {
            this.individualAchievementUnitVerificationStatusesInfoResponse = JSON.parse(result.data.responseData);
            this.consoleLog(this.individualAchievementUnitVerificationStatusesInfoResponse, true);
        } else if (result.error) {
            promptError(customLabels.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    //-----------------------------------------------header--------------------------------

    get showComponentHeader() {
        return this.modalTitle || this.modalIconName || this.showAddIndividualAchievementUnitButton;
    }

    get showAddIndividualAchievementUnitButton() {
        return this.showNewButton && this.showUnitTable && !this.preventEditingIndividualAchievement;
    }

    get newLabel() {
        return this.label.NEW_LABEL;
    }


    @wire(MessageContext)
    messageContext;

    get isAdminMode() {
        return this.userMode === commonConstants.USER_MODE_ADMIN;
    }

    get preventEditingIndividualAchievement() {
        return this.individualAchievementIsLocked && !this.isAdminMode;
    }

    get showUploadedFilesLabel() {
        return SHOW_UPLOADED_FILES_LABEL;
    }

    get hideUploadedFilesLabel() {
        return HIDE_UPLOADED_FILES_LABEL;
    }

    async handleAddIndividualAchievementUnit(){
        if(this.preventEditingIndividualAchievement) {
            let recordIsLockedMsg = THE_RECORD_IS_LOCKED_LABEL.format([this.individualAchievementObjectLabel, this.individualAchievementRecord?.Name]);
            promptError(recordIsLockedMsg);
            return;
        }
        this.consoleLog(`openAddIndividualAchievementUnitModal: individualAchievementId:${this.recordId}`)
        let newRecordLabel = this.label.NEW_RECORD_LABEL.format([this.individualAchievementUnitObjLabel]);
        try {
            let result;

            if(this.isAdminMode) {
                result = await studentAchievementUnitAdminModal.open({
                    
                    size: 'small',
                    modalTitle: newRecordLabel,
                    additionalUnitFieldSetName: this.additionalUnitFieldSetName,
                    unitCodeFallbackField: this.unitCodeFallbackField,
                    unitNameFallbackField: this.unitNameFallbackField,
                    verificationDetailsFieldSetName: this.verificationDetailsFieldSetName,
                    individualAchievementId: this.recordId,
                    enableDebugMode: this.enableDebugMode,
                    agreementRecognitionUnitCreationFieldSetName: this.agreementRecognitionUnitCreationFieldSetName,
                    unitRequired: this.unitRequired,
                    onfilepreview: (previewEvent) => {
                        this[NavigationMixin.Navigate]({
                            type: 'standard__namedPage',
                            attributes:{ 
                                pageName:'filePreview'
                            },
                            state: {
                                selectedRecordId: previewEvent.detail.documentId
                            }
                        })
                    }

                })

            } else {
                result = await studentAchievementUnitStudentModal.open({
                    modalTitle: newRecordLabel,

                    fieldSetName: this.additionalUnitFieldSetName,
                    editFormColumnNo: 2,
                    size: 'small',
                    enableDebugMode: this.enableDebugMode,
                    enableNewParentCreation: false,
                    unitNameFallbackField : this.unitNameFallbackField,
                    unitCodeFallbackField : this.unitCodeFallbackField,
                    unitRequired: this.unitRequired,
                    individualAchievementId: this.recordId
                });
            }
            
            
            if(result) {
                const { operation, eventResult, eventData } = result;
                if(operation === 'submit' && eventResult === 'success') {
                    let recordId = eventData.Id;
                    this.consoleLog('studentAchievementUnitStudentModal.close.recordId = ' + recordId);

                    promptSuccess(customLabels.SUCCESS_LABEL, this.label.RECORD_SAVED_LABEL);

                    notifyRecordUpdateAvailable([{recordId: recordId}]);

                    this.dispatchEvent(new RefreshEvent());
                    this.publishRefresh();
                }
            }
        } catch(err) {
            promptError(customLabels.ERROR_LABEL, getErrorMessage(err));
        }

    }

    get individualAchievementUnitTableFields() {
        return this.individualAchievementUnitsResponse?.unitTableFields ?? null;
    }

    //-----------------------------------base-------------------------------------

    get unitNameLabel() {
        return UNIT_NAME_LABEL;
    }

    get unitCodeLabel() {
        return UNIT_CODE_LABEL;
    }

    @wire(getObjectInfo, { objectApiName: IAU_OBJ })
    individualAchievementUnitObj;

    get individualAchievementUnitObjLabel() {
        return this.individualAchievementUnitObj?.data?.label ?? IAU_OBJ.objectApiName;
    }

    @wire(getObjectInfo, { objectApiName: IAC_OBJ })
    individualAchievementObjectInfo;
    
    get individualAchievementObjectLabel() {
        return this.individualAchievementObjectInfo?.data?.label ?? IAC_OBJ.objectApiName;
    }
    
    @wire(ctrlGetIndividualAchievementRecord, {individualAchievementId: '$recordId', language: "$language"})
    wiredGetIndividualAchievementRecord(result) {
        
        this.individualAchievementRecordResult = result;
        this.individualAchievementRecordResponse = null;

        if (result.data) {
            this.individualAchievementRecordResponse = JSON.parse(result.data.responseData);
            this.consoleLog(this.individualAchievementRecordResponse, true);
        } else if (result.error) {
            promptError(customLabels.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    get individualAchievementRecord() {
        return this.individualAchievementRecordResponse?.individualAchievementRecord ?? null;
    }

    get individualAchievementIsLocked() {
        return this.individualAchievementLockedVerificationStatuses.includes(this.individualAchievementRecord?.[IAC_VERIFICATION_STATUS_FIELD.fieldApiName]);
    }

    //-----------------------custom metadata--------------------------
    
    @wire(ctrlGetIdvAcWizardMetadata, {
        parentWizardConfigName: "$individualAchievementFormConfigurationName"
    })
    wiredGetIdvAcWizardMetadata(result) {
        this.idvAcWizardMetadataResult = result;
        this.idvAcWizardMetadataResponse = null;

        if (result.data) {
            this.idvAcWizardMetadataResponse = JSON.parse(result.data.responseData);
            this.consoleLog(this.idvAcWizardMetadataResponse, true);
        } else if (result.error) {
            promptError(customLabels.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    get idvAcWizardFormGroupList() {
        return this.idvAcWizardMetadataResponse?.idvAcWizardFormGroupList ?? [];
    }


    get matchedWizardFormConfig() {
        if(this.idvAcWizardFormGroupList && this.idvAcWizardFormGroupList.length > 0 && this.individualAchievementRecord) {
            let defaultConfig;
            for(let config of this.idvAcWizardFormGroupList) {
                let compositeKeyFormat = config.compositeKey;
                let compositeKeyMergeKey = getMergeKeys(compositeKeyFormat);
                let formattedCompositeKey = mergeValues(compositeKeyFormat, compositeKeyMergeKey, this.individualAchievementRecord, false);
                if(formattedCompositeKey === config.compositeKeyValue) {
                    return config;
                }
                if(!defaultConfig && config.isDefault) {
                    defaultConfig = config;
                }
            }

            if(defaultConfig) {
                return defaultConfig;
            }
            promptError(this.label.ERROR_LABEL, NO_MATCHED_OR_DEFAULT_WIZARD_CONFIG_RECORD_LABEL);
        }

        return null;
    }

    get showUnitTable() {
        return this.matchedWizardFormConfig?.showUnitTable ?? false;
    }

    get unitRequired() {
        return this.matchedWizardFormConfig?.unitRequired ?? false;
    }

    get additionalUnitFieldSetName() {
        return this.matchedWizardFormConfig?.unitAdditionalInfoFieldSet ?? '';
    }

    get unitCodeFallbackField() {
        return this.matchedWizardFormConfig?.unitCode?.fallbackField ?? '';
    }

    get unitNameFallbackField() {
        return this.matchedWizardFormConfig?.unitName?.fallbackField ?? '';
    }

    get showUnitCodeField() {
        return this.matchedWizardFormConfig?.unitCode?.showSubgroup;
    }

    get showUnitNameField() {
        return this.matchedWizardFormConfig?.unitName?.showSubgroup;
    }

    get unitTableDisplayFields() {
        return this.matchedWizardFormConfig?.unitTableFields;
    }
    
    //---------------------------------------------------------------

    @wire(ctrlGetIndividualAchievementUnits, {
        individualAchievementId: '$recordId', 
        unitTableFields: "$unitTableDisplayFields",
        language: '$language'
    })
    wiredGetIndividualAchievementUnits(result) {
        this.individualAchievementUnitsResult = result;
        this.individualAchievementUnitsResponse = null;

        if (result.data) {
            this.individualAchievementUnitsResponse = JSON.parse(result.data.responseData);
            this.consoleLog('individualAchievementUnitsResponse');
            this.consoleLog(this.individualAchievementUnitsResponse, true);
            this.toggleSpinner(-1);
        } else if (result.error) {
            promptError(customLabels.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    get isCommunity() {
        return this.individualAchievementUnitsResponse?.isCommunity;
    }

    get sitePath() {
        return this.individualAchievementUnitsResponse?.sitePath;
    }

    get individualAchievementUnitIdList() {
        return this.individualAchievementUnitsResponse?.individualAchievementUnitIdList ?? [];
    }

    //--------------------------------------------items-------------------------

    get hasIndividualAchievementUnit() {
        return this.individualAchievementUnitsResponse?.individualAchievementUnitIdList?.length > 0;
    }

    get actionLabel() {
        return this.label.ACTION_LABEL;
    }

    get unitIsNotRequiredLabel() {
        return UNIT_IS_NOT_REQUIRED_LABEL;
    }

    get unitIsRequiredLabel() {
        return UNIT_IS_REQUIRED_LABEL;
    }

    get completeAllRequirementsLabel() {
        return COMPLETE_ALL_REQUIREMENTS_LABEL;
    }

    /**
     * @description Return language
     */
    get language() {
        return LANG;
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

    handlePublishRefresh() {
        this.publishRefresh();
    }

    publishRefresh(){
        let message = {
            eventSource: StudentAchievementUnitTable.name,
            recordId: this.recordId,
            operation: 'refresh'
        }
        publish(this.messageContext, MESSAGE_CHANNEL, message);
    }

    subscribeToMessageChannel() {
        if (!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                MESSAGE_CHANNEL,
                (message) => this.handleMessage(message)
            );
        }
    }

    unsubscribeToMessageChannel() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }

    /**
     * @description refresh when message received. this is to refresh the field value after submitting for verification, or when an individual requirement is updated to Submitted.
     */
    handleMessage(message) {
        if(
            message.eventSource !== StudentAchievementUnitTable.name && 
            message.operation === 'refresh' && 
            message.recordId === this.recordId
        ) {
            this.dispatchEvent(new RefreshEvent());
        }
    }

    /**
     * @descripton connected callback
     */
    connectedCallback(){
		this.refreshContainerID = registerRefreshContainer(this, this.refreshData);
        this._cacheIdx = initCacheIdx();
        this.subscribeToMessageChannel();
        this.toggleSpinner(1);
	}
	
    /**
     * @descripton disconnected callback
     */
	disconnectedCallback() {
		unregisterRefreshContainer(this.refreshContainerID);
        this.unsubscribeToMessageChannel();
	}

    /**
     * @description Refresh data
     */
    refreshData() {
        this.consoleLog('refreshData');
        
        //update the cacheIdx if you need to force the wire method to get new data from apex
        this._cacheIdx = initCacheIdx();

        refreshApex(this.individualAchievementUnitsResult);
        refreshApex(this.idvAcWizardMetadataResult);
        refreshApex(this.individualAchievementRecordResult);

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
        logInfo('StudentAchievementUnitTable', anything, this.enableDebugMode, isJson);
    }
	
}