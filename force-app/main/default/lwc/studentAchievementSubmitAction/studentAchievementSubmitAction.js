/**
 * @Author 		WDCi (XW)
 * @Date 		Dec 2025
 * @group 		Student Achievement
 * @Description Student Achievement quick action to submit the individual achievement
 * @changehistory
 * ISS-002633 29-01-2026 XW - new class
 */
import { LightningElement, api, wire, track } from 'lwc';
import { promptInfo, promptError, promptWarning, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';
import { initCacheIdx, commonConstants, getMergeKeys, mergeValues } from 'c/lwcUtil';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { shadeHexColorCode } from 'c/cssUtil';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { customLabels } from 'c/labelLoader';
import LANG from '@salesforce/i18n/lang';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { CloseActionScreenEvent } from 'lightning/actions';

import IAC_OBJ from '@salesforce/schema/Individual_Achievement__c';
import IAC_NAME_FIELD from '@salesforce/schema/Individual_Achievement__c.Name';
import IAC_ID_FIELD from "@salesforce/schema/Individual_Achievement__c.Id";
import IAC_VERIFICATION_STATUS_FIELD from "@salesforce/schema/Individual_Achievement__c.Verification_Status__c";
import IAC_SUBMISSION_DATE_FIELD from "@salesforce/schema/Individual_Achievement__c.Submission_Date__c";
import IAC_AGREEMENT_FIELD from "@salesforce/schema/Individual_Achievement__c.Agreement__c";
import IAC_DEPARTMENT_FIELD from "@salesforce/schema/Individual_Achievement__c.Department__c";
import IAC_AGREEMENT_RECOGNITION_FIELD from "@salesforce/schema/Individual_Achievement__c.Agreement_Recognition__c";
import IAU_AGREEMENT_RECOGNITION_UNIT_FIELD from "@salesforce/schema/Individual_Achievement_Unit__c.Agreement_Recognition_Unit__c";
import IRS_TOTAL_REQUIREMENT_STUDENT_FIELD from '@salesforce/schema/Individual_Requirement_Set__c.Total_Requirement_Student__c';
import IRS_TOTAL_REVIEWED_STUDENT_FIELD from '@salesforce/schema/Individual_Requirement_Set__c.Total_Reviewed_Student__c';
import IRS_TOTAL_SUBMITTED_STUDENT_FIELD from '@salesforce/schema/Individual_Requirement_Set__c.Total_Submitted_Student__c';
import IRQ_OBJ from '@salesforce/schema/Individual_Requirement__c';

//message
import MESSAGE_CHANNEL from "@salesforce/messageChannel/c__privateLwcMessageChannel__c"
import { publish, MessageContext } from "lightning/messageService";

import SUBMIT_FOR_VERIFICATION_CONFIRMATION_LABEL from '@salesforce/label/c.Student_Achievement_Submit_For_Verification_Confirmation'
import COMPLETE_REQUIREMENTS_BEFORE_SUBMIT_LABEL from '@salesforce/label/c.Student_Achievement_Complete_Requirements_Before_Submit'
import SUBMIT_FOR_VERIFICATION_LABEL from '@salesforce/label/c.Student_Achievement_Submit_For_Verification'
import SUBMITTED_FOR_VERIFICATION_LABEL from '@salesforce/label/c.Student_Achievement_Submitted_For_Verification'
import ALREADY_SUBMITTED_FOR_VERIFICATION_LABEL from '@salesforce/label/c.Student_Achievement_Already_Submitted_For_Verification'
import SYSTEM_FIELD_IS_REQUIRED_LABEL from '@salesforce/label/c.Student_Achievement_System_Field_Is_Required'
import INDIVIDUAL_ACHIEVEMENT_UNIT_AGREEMENT_RECOGNITION_UNIT_LABEL from '@salesforce/label/c.Student_Achievement_Individual_Achievement_Unit_Agreement_Recognition_Unit'
import INDIVIDUAL_REQUIREMENT_MUST_BE_SUBMITTED_LABEL from '@salesforce/label/c.Student_Achievement_Individual_Requirement_Must_Be_Submitted'
import NO_MATCHED_OR_DEFAULT_WIZARD_CONFIG_RECORD_LABEL from '@salesforce/label/c.Student_Achievement_No_Matched_Or_Default_Wizard_Config';
import NO_MATCHED_WIZARD_CONFIG_RECORD_LABEL from '@salesforce/label/c.Student_Achievement_No_Matched_Wizard_Config';

//Apex methods
import ctrlGetIdvAcWizardMetadata from '@salesforce/apex/REDU_StudentAchievement_LCTRL.getIdvAcWizardMetadata';
import ctrlGetIndividualAchievementVerificationStatusesInfo from '@salesforce/apex/REDU_StudentAchievement_LCTRL.getIndividualAchievementVerificationStatusesInfo'
import ctrlGetIndividualRequirementSets from '@salesforce/apex/REDU_StudentAchievementItem_LCTRL.getIndividualRequirementSets'
import ctrlUpdateIndividualAchievementIndividualAchievementUnitToSubmitted from '@salesforce/apex/REDU_StudentAchievementSubmit_LCTRL.updateIndividualAchievementIndividualAchievementUnitToSubmitted'
import ctrlGetIndividualAchievementRecord from '@salesforce/apex/REDU_StudentAchievementDetails_LCTRL.getIndividualAchievementRecord';
import ctrlGetIndividualAchievementUnits from '@salesforce/apex/REDU_StudentAchievementSubmit_LCTRL.getIndividualAchievementUnits';

const IAC_FIELDS = [
    IAC_SUBMISSION_DATE_FIELD, 
    IAC_VERIFICATION_STATUS_FIELD, 
    IAC_NAME_FIELD, 
    IAC_ID_FIELD,
    IAC_AGREEMENT_FIELD, 
    IAC_DEPARTMENT_FIELD, 
    IAC_AGREEMENT_RECOGNITION_FIELD
];

const VERIFICATION_STATUS_TYPE_SUBMITTED = 'Submitted';

const SYSTEM_AGREEMENT = 'agreement';
const SYSTEM_DEPARTMENT = 'department';
const SYSTEM_AGREEEMENT_RECOGNITION = 'agreementRecognition';


export default class StudentAchievementSubmitAction extends LightningElement {
	
	//configurable attributes
    modalTitle = SUBMIT_FOR_VERIFICATION_LABEL;
    @api recordId;
	enableDebugMode = false;
	
	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false
	loadedLists = 0;

    //local cache idx to force rerendering
    _cacheIdx;
    @track individualRequirementsResult;
    @track individualRequirementsResponse;
    @track individualAchievementRecordResult;
    @track individualAchievementRecordResponse;
    @track lockingModeResult;
    @track lockingModeResponse;
    @track individualAchievementVerificationStatusesInfoResult;
    @track individualAchievementVerificationStatusesInfoResponse;
    @track individualRequirementSetsResult;
    @track individualRequirementSetsResponse;
    @track idvAcWizardMetadataResult;
    @track idvAcWizardMetadataResponse;
    @track individualAchievementUnitsResult;
    @track individualAchievementUnitsResponse;
    @track pageRef;
	//labels
	label = customLabels;
	
	//js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'jquery', 'tooltips'
    modules = ['stringutil'];

    @wire(MessageContext)
    messageContext;
    
    /**
    * @description the user language
    */
    get language() {
        return LANG;
    }
    
    @wire(CurrentPageReference)
    wiredPageRef(pageRef) {
        this.pageRef = pageRef;
    }

    /**
     * @description get the idvac config id from pageref
     */
    get wizardConfigName() {
        let name = this.pageRef?.state?.reduivy__wizardConfigName;
        if(!name) {
            //if the component is in the internal page, pageref will not get the custom param from url.
            //we will need to get it using URLSearchParams
            let urlParams = new URLSearchParams(window.location.search);
            name = urlParams.get('reduivy__wizardConfigName');
        }
        return name;
    }

    /**
     * @description get all the individual achievement wizard mdt based on the wizard config id
     */
    @wire(ctrlGetIdvAcWizardMetadata, {
        parentWizardConfigName: "$wizardConfigName"
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
    
    /*
     * @description list of individual achievement wizard mdt
    */
    get idvAcWizardFormGroupList() {
        return this.idvAcWizardMetadataResponse?.idvAcWizardFormGroupList ?? [];
    }

    /**
     * @description map of label used in the student achievement wizards
     */
    get idvAcWizardFormLabels() {
        return this.idvAcWizardMetadataResponse?.labels ?? {};
    }

    /**
     * @description individual achievement wizard mdt that matched the composite key
     */

    get matchedWizardFormConfig() {
        if(this.idvAcWizardFormGroupList && this.idvAcWizardFormGroupList.length > 0 && this.individualAchievementRecord) {
            let defaultConfig = null;
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

    /**
     * @description get external education institution config from matchedWizardFormConfig
     */
    get externalEducationalInstitutionConfig() {
        return this.matchedWizardFormConfig?.[SYSTEM_AGREEMENT];
    }

    /**
     * @description return true if external education institution is required
     */
    get externalEducationalInstitutionIsRequired() {
        return this.externalEducationalInstitutionConfig?.isRequired;
    }

    /**
     * @description external education institution fallback field
     */
    get externalEducationalInstitutionFallbackField() {
        return this.externalEducationalInstitutionConfig?.fallbackField;
    }

    /**
     * @description get department config from matchedWizardFormConfig
     */
    get departmentConfig() {
        return this.matchedWizardFormConfig?.[SYSTEM_DEPARTMENT]
    }

    /**
     * @description return true if department is required
     */
    get departmentIsRequired() {
        return this.departmentConfig?.isRequired;
    }

    /**
     * @description department fallback field
     */
    get departmentFallbackField() {
        return this.departmentConfig?.fallbackField;
    }

    /**
     * @description get agreement recognition config from matchedWizardFormConfig
     */
    get programConfig() {
        return this.matchedWizardFormConfig?.[SYSTEM_AGREEEMENT_RECOGNITION]
    }

    /**
     * @description return true if agreement recognition is required
     */
    get programIsRequired() {
        return this.programConfig?.isRequired;
    }

    /**
     * @description agreement recognition fallback field
     */
    get programFallbackField() {
        return this.programConfig?.fallbackField;
    }

    get unitIsRequired() {
        return this.matchedWizardFormConfig?.unitRequired ?? false;
    }

    get unitCodeFallbackField() {
        return this.matchedWizardFormConfig?.unitCode?.fallbackField;
    }

    get unitNameFallbackField() {
        return this.matchedWizardFormConfig?.unitName?.fallbackField;
    }

    //-----------------------------------------

    get showNoWizardConfigNameFound() {
        return !this.wizardConfigName;
    }

    get showConfirmationScreen() {
        return !this.showPreventSubmitScreen && !this.showSubmittedScreen && this.individualAchievementUnitsResponse && !this.showNoWizardConfigNameFound;
    }

    get showPreventSubmitScreen() {
        return (this.requirementsNotCompleted || this.requiredSystemFieldsNotPopulated || this.requiredUnitNotPopulated) && !this.showNoWizardConfigNameFound;
    }

    get showSubmittedScreen() {
        return this.verificationStatusTypeMapping &&
            this.verificationStatusTypeMapping?.[VERIFICATION_STATUS_TYPE_SUBMITTED].length > 0 && 
            this.verificationStatusTypeMapping?.[VERIFICATION_STATUS_TYPE_SUBMITTED].includes(this.individualAchievementRecord?.reduivy__Verification_Status__c);
    }

    get individualAchievementIsSubmittedLabel() {
        return SUBMITTED_FOR_VERIFICATION_LABEL.format([this.individualAchievementObjectLabel, this.individualAchievementRecord?.Name]);
    }

    get individualAchievementIsAlreadySubmittedLabel() {
        return ALREADY_SUBMITTED_FOR_VERIFICATION_LABEL.format([this.individualAchievementObjectLabel, this.individualAchievementRecord?.Name]);
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

    @wire(getObjectInfo, { objectApiName: IAC_OBJ })
    individualAchievementObjectInfo;

    get individualAchievementObjectLabel() {
        return this.individualAchievementObjectInfo?.data?.label;
    }


    //-----------------------------------no wizard config name found---------------------------
    get noWizardConfigNameFoundLabel() {
        return NO_MATCHED_WIZARD_CONFIG_RECORD_LABEL;
    }

    //-------------------------------------check requirements----------------------------------

    @wire(ctrlGetIndividualAchievementVerificationStatusesInfo) 
    wiredGetIndividualAchievementVerificationStatusesInfo(result) {
        this.individualAchievementVerificationStatusesInfoResult = result;
        this.individualAchievementVerificationStatusesInfoResponse = null;
        if(result.data) {
            this.individualAchievementVerificationStatusesInfoResponse = JSON.parse(result.data.responseData);
            this.consoleLog('wiredGetIndividualAchievementVerificationStatusesInfo');
            this.consoleLog(this.individualAchievementVerificationStatusesInfoResponse, true);
        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    get verificationStatusTypeMapping() {
        return this.individualAchievementVerificationStatusesInfoResponse?.verificationStatusType;
    }

    @wire(ctrlGetIndividualRequirementSets, {
        individualAchievementId: '$recordId',
        cacheIdx: '$_cacheIdx'
    }) 
    wiredGetIndividualRequirementSets(result) {
        this.individualRequirementSetsResult = result;
        this.individualRequirementSetsResponse = null;
        if(result.data) {
            this.individualRequirementSetsResponse = JSON.parse(result.data.responseData);
            this.consoleLog('wiredGetIndividualRequirementSets');
            this.consoleLog(this.individualRequirementSetsResponse, true);
            this.toggleSpinner(-1);
        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    /**
     * @description total count of requirements 
     */
    get totalRequirements() {
        let total = 0;
        if(this.individualRequirementSetsResponse) {
            for(let irs of this.individualRequirementSetsResponse) {
                total += irs?.[IRS_TOTAL_REQUIREMENT_STUDENT_FIELD.fieldApiName] ?? 0;
            }
        }
        return total;
    }

    /**
     * @description total reviewed requirements count
     */
    get totalReviewed() {
        let total = 0;
        if(this.individualRequirementSetsResponse) {
            for(let irs of this.individualRequirementSetsResponse) {
                total += irs?.[IRS_TOTAL_REVIEWED_STUDENT_FIELD.fieldApiName] ?? 0;
            }
        }
        return total;
    }

    /**
     * @description total submitted requirements count
     */
    get totalSubmitted() {
        
        let total = 0;
        if(this.individualRequirementSetsResponse) {
            for(let irs of this.individualRequirementSetsResponse) {
                total += irs?.[IRS_TOTAL_SUBMITTED_STUDENT_FIELD.fieldApiName] ?? 0;
            }
        }
        return total;
    }

    //------------------------------confirmation screen-------------------------

    get submitForVerificationConfirmationLabel() {
        return SUBMIT_FOR_VERIFICATION_CONFIRMATION_LABEL;
    }

    //-------------------complete requirements screen--------------------------

    /**
     * @description return true if the total submitted requirements count is not the same as total requirements count
     */
    get requirementsNotCompleted() {
        return this.totalRequirements > this.totalSubmitted; 
    }

    get completeRequirementsBeforeSubmitLabel() {
        return COMPLETE_REQUIREMENTS_BEFORE_SUBMIT_LABEL;
    }

    @wire(getObjectInfo, { objectApiName: IRQ_OBJ })
    irqObjInfo;

    get irqObjLabel() {
        return this.irqObjInfo?.data?.label ?? IRQ_OBJ.objectApiName;
    }

    get individualRequirementMustBeSubmittedLabel() {
        return INDIVIDUAL_REQUIREMENT_MUST_BE_SUBMITTED_LABEL.format([this.irqObjLabel]);
    }

    get submittedStatuses() {
        return this.verificationStatusTypeMapping?.[VERIFICATION_STATUS_TYPE_SUBMITTED] ?? []
    }

    //---------------------------------required system fields not populated------------------------

    get exEduInstLabel() {
        return this.idvAcWizardFormLabels[this.externalEducationalInstitutionConfig?.label] ?? this.externalEducationalInstitutionConfig?.label;
    }

    get departmentLabel() {
        return this.idvAcWizardFormLabels[this.departmentConfig?.label] ?? this.departmentConfig?.label;
    }

    get programLabel() {
        return this.idvAcWizardFormLabels[this.programConfig?.label] ?? this.programConfig?.label;
    }

    get requiredSystemFieldsNotPopulated() {
        return this.requiredSystemFieldsLabels.length > 0;
    }

    /**
     * @description list of "system field is required" label if the system field is required but not populated
     */
    get requiredSystemFieldsLabels() {
        const result = [];

        // Define the checks in a configuration array
        const checks = [
            {
                required: this.externalEducationalInstitutionIsRequired,
                lookupField: IAC_AGREEMENT_FIELD.fieldApiName,
                fallback: this.externalEducationalInstitutionFallbackField,
                label: this.exEduInstLabel
            },
            {
                required: this.departmentIsRequired,
                lookupField: IAC_DEPARTMENT_FIELD.fieldApiName,
                fallback: this.departmentFallbackField,
                label: this.departmentLabel
            },
            {
                required: this.programIsRequired,
                lookupField: IAC_AGREEMENT_RECOGNITION_FIELD.fieldApiName,
                fallback: this.programFallbackField,
                label: this.programLabel
            }
        ];

        checks.forEach(item => {
            if (item.required && !this.hasValue(this.individualAchievementRecord, item.lookupField, [item.fallback])) {
                result.push(SYSTEM_FIELD_IS_REQUIRED_LABEL.format([item.label]));
            }
        });

        return result;
    }

    /**
     * @description return true if the lookup field is set in record, or the fallback value is set
     */
    hasValue(record, lookupField, fallbackFields) {
        const lookupValue = record?.[lookupField];
        
        if (lookupValue) {
            return true;
        }

        if (Array.isArray(fallbackFields) && fallbackFields.length > 0) {
            return fallbackFields.every(fieldName => {
                const value = record?.[fieldName];
                
                // Returns true only if the value is not null/undefined/empty string
                return value !== undefined && value !== null && value !== '';
            });
        }
        return false;
    }

    //------------------------------------requiredUnitNotPopulated-----------------------

    /**
     * @description the unit code fallback field and the unit name fallback field if set
     */
    get individualAchievementUnitAdditionalFields() {
        let result = [];
        if(this.unitCodeFallbackField) {
            result.push(this.unitCodeFallbackField);
        }
        if(this.unitNameFallbackField) {
            result.push(this.unitNameFallbackField);
        }
        return result;
    }

    /**
     * @description the unit is required label
     */
    get unitIsRequiredLabel() {
        return SYSTEM_FIELD_IS_REQUIRED_LABEL.format([INDIVIDUAL_ACHIEVEMENT_UNIT_AGREEMENT_RECOGNITION_UNIT_LABEL]);
    }

    /**
     * @description get the individual achievement 
     */
    @wire(ctrlGetIndividualAchievementUnits, {individualAchievementId: '$recordId', additionalFields:'$individualAchievementUnitAdditionalFields', cacheIdx:"$_cacheIdx"})
    wiredGetIndividualAchievementUnits(result) {
        this.individualAchievementUnitsResult = result;
        this.individualAchievementUnitsResponse = null;
        
        if (result.data) {
            this.individualAchievementUnitsResponse = JSON.parse(result.data.responseData);
            this.consoleLog('wiredGetIndividualAchievementUnits');
            this.consoleLog(this.individualAchievementUnitsResponse, true);
        } else if (result.error) {
            promptError(customLabels.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    /**
     * @description return true if the agreement Recognition unit in individual achievement unit is required, 
                    but the agreement Recognition unit is not populated, or the fallback field is not populated if fallback field it set
     */
    get requiredUnitNotPopulated() {
        if(!this.unitIsRequired) {
            return false;
        }

        if(this.individualAchievementUnitsResponse) {
            for(let individualAchievementUnit of this.individualAchievementUnitsResponse) {
                
                if (!this.hasValue(individualAchievementUnit, IAU_AGREEMENT_RECOGNITION_UNIT_FIELD.fieldApiName, this.individualAchievementUnitAdditionalFields)) {
                    return true;
                }
            }
        }

        return false;
    }

    //----------------------------buttons--------------------------

    handleCloseClick() {
        this.closeQuickAction();
    }

    handleCancelClick() {
        this.closeQuickAction();
    }
    
    async handleConfirmClick() {
        this.toggleSpinner(1);
        try{

            if(!this.submittedStatuses.includes(this.individualAchievementRecord.reduivy__Verification_Status__c)) {
                //update to submitted
                let result = await ctrlUpdateIndividualAchievementIndividualAchievementUnitToSubmitted({individualAchievementId : this.recordId});
                if(result) {
                    let responseData = JSON.parse(result.responseData);
                    let recordIdsToNotify = responseData.map(recordId => ({'recordId': recordId}));
                    promptSuccess(this.label.SUCCESS_LABEL, this.individualAchievementIsSubmittedLabel);   
                    notifyRecordUpdateAvailable(recordIdsToNotify);
                    this.publishRefresh();
                }
            }
            this.closeQuickAction();
        } catch(err) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(err));
        }
    }

    /**
     * @description publish refresh message to student achievements component
     */
    publishRefresh(){
        let message = {
            eventSource: StudentAchievementSubmitAction.name,
            recordId: this.recordId,
            operation: 'refresh'
        }
        publish(this.messageContext, MESSAGE_CHANNEL, message);
    }

    /**
     * @description Close quick action
     */
    closeQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
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
        this._cacheIdx = initCacheIdx();
        this.toggleSpinner(1);
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
        logInfo('StudentAchievementSubmitAction', anything, this.enableDebugMode, isJson);
    }
	
}