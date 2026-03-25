/**
 * @Author 		WDCi (XW)
 * @Date 		Dec 2025
 * @group 		Student Achievement
 * @Description Show the details of Individual Achievement
 * @changehistory
 * ISS-2633 16-12-2025 XW - new class
 */
import { LightningElement, api, wire, track } from 'lwc';
import { promptInfo, promptError, promptWarning, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';
import { notifyRecordUpdateAvailable, createRecord, getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { shadeHexColorCode } from 'c/cssUtil';
import { initCacheIdx, getMergeKeys, mergeValues, commonConstants, extractFieldValue, getFormDataFieldOnChangeValue } from 'c/lwcUtil';
import { customLabels } from 'c/labelLoader';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import LANG from '@salesforce/i18n/lang';
import recordEditModal from 'c/recordEditModal';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import genericConfirmationModal from 'c/genericConfirmationModal';

//refresh module
import { refreshApex } from '@salesforce/apex';
import { RefreshEvent, registerRefreshContainer, unregisterRefreshContainer } from 'lightning/refresh';

//Objects and fields;
import ACC_OBJ from '@salesforce/schema/Account'
import AGR_EX_EDU_INST_FIELD from "@salesforce/schema/Agreement__c.External_Educational_Institution__c"
import ACC_PARENT_ACC_FIELD from "@salesforce/schema/Account.ParentId";
import AGR_OBJ from '@salesforce/schema/Agreement__c'
import ARC_OBJ from '@salesforce/schema/Agreement_Recognition__c'
import IAC_OBJ from '@salesforce/schema/Individual_Achievement__c'
import IAC_VERIFICATION_STATUS_FIELD from '@salesforce/schema/Individual_Achievement__c.Verification_Status__c'
import IAC_TYPE from '@salesforce/schema/Individual_Achievement__c.Type__c'

//custom label
import DETAILS_LABEL from '@salesforce/label/c.Student_Achievement_Details';
import FALLBACK_FIELD_PLACEHOLDER_LABEL from '@salesforce/label/c.Student_Achievement_Fallback_Field_Placeholder';
import WARNING_EDIT_VERIFIED_RECORD from '@salesforce/label/c.Student_Achievement_Warning_Edit_Verified_Record';
import NO_MATCHED_OR_DEFAULT_WIZARD_CONFIG_RECORD_LABEL from '@salesforce/label/c.Student_Achievement_No_Matched_Or_Default_Wizard_Config';

import STUDENT_ACHIEVEMENT_LINKED_SUCCESSFULLY_LABEL from '@salesforce/label/c.Student_Achievement_Linked_Successfully';
import STUDENT_ACHIEVEMENT_LINK_LABEL from '@salesforce/label/c.Student_Achievement_Link';
import STUDENT_ACHIEVEMENT_LINKED_LABEL from '@salesforce/label/c.Student_Achievement_Linked';
import OPTIONS_LABEL from '@salesforce/label/c.Options';
import VERIFICATION_DETAILS_LABEL from '@salesforce/label/c.Student_Achievement_Verification_Details';

//Apex methods
import ctrlGetIdvAcWizardMetadata from '@salesforce/apex/REDU_StudentAchievement_LCTRL.getIdvAcWizardMetadata';
import ctrlGetIndividualAchievementRecord from '@salesforce/apex/REDU_StudentAchievementDetails_LCTRL.getIndividualAchievementRecord'
import ctrlGetFieldSet from '@salesforce/apex/REDU_StudentAchievement_LCTRL.getFieldSet';
import ctrlGetTranslationFieldForName from '@salesforce/apex/REDU_Translation_LCTRL.getTranslationFieldForNameByObjPrefix';
import ctrlGetIndividualAchievementVerificationStatusesInfo from '@salesforce/apex/REDU_StudentAchievement_LCTRL.getIndividualAchievementVerificationStatusesInfo';

//message
import { publish, MessageContext, subscribe, unsubscribe } from "lightning/messageService";
import MESSAGE_CHANNEL from "@salesforce/messageChannel/c__privateLwcMessageChannel__c"

const SYSTEM_AGREEMENT = 'agreement';
const SYSTEM_DEPARTMENT = 'department';
const SYSTEM_AGREEMENT_RECOGNITION = 'agreementRecognition';

const STATUS_ACTIVE = 'Active';

const DISPLAY_MODE_EDIT = 'edit';
const DISPLAY_MODE_VIEW = 'view';
const MASTER_RECORD_TYPE_ID = '012000000000000AAA';

const OBJ_TRANSLATION = [
    "ACC", "ARC", "AGR"
];

const LOCKING_MODE_LOCKED = 'Locked';
const LOCKING_MODE_UNLOCKED = 'Unlocked';

const VERIFICATION_STATUS_TYPE_OPEN = 'Open';
const VERIFICATION_STATUS_TYPE_VERIFIED = 'Verified';

export default class StudentAchievementDetails extends NavigationMixin(LightningElement) {
	
	//configurable attributes
    @api recordId; //individual achievement id
    @api individualAchievementFormConfigurationName;
    @api userMode;
    @api agreementCustomFilter;
    @api departmentCustomFilter;
    @api agreementRecognitionCustomFilter;

    @api agreementCreationFieldSetName;
    @api departmentCreationFieldSetName;
    @api agreementRecognitionCreationFieldSetName;
    @api verificationDetailsFieldSetName;

	@api enableDebugMode = false;
	
	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false
	loadedLists = 0;
    @track displayMode = DISPLAY_MODE_VIEW;
    @track individualAchievementFieldValue = {}
    @track draftIndividualAchievementFieldValue = {};
	
    //refresh Container
    refreshContainerID;

    //local cache idx to force rerendering
    _cacheIdx;

    //wire attribute
	@track idvAcWizardMetadataResult;
	@track idvAcWizardMetadataResponse;
    @track individualAchievementRecordResult;
    @track individualAchievementRecordResponse;
    @track objectTranslatedNameResult;
    @track objectTranslatedNameResponse;
    @track verificationDetailsFieldsResult;
    @track verificationDetailsFieldsResponse;
    @track additionalInfoFieldSetResult;
    @track additionalInfoFieldSetResponse;
    
    @track arcRecordResult;
    @track arcRecordResponse;
    @track agrRecordResult;
    @track agrRecordResponse;
    @track departmentAccRecordResult;
    @track departmentAccRecordResponse;
    @track individualAchievementVerificationStatusesInfoResult;
    @track individualAchievementVerificationStatusesInfoResponse;
    

    @track pageRef;

	//labels
	label = customLabels;
	
	//js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'jquery', 'tooltips'
    modules = ['stringutil'];

    get systemSectionInfos() {
        return {
            [SYSTEM_AGREEMENT]: {
                systemSection: [SYSTEM_AGREEMENT],
                fieldName: 'reduivy__Agreement__c',
                prefix: "AGR",
                recordTitle: '{Name}', 
                displayAsReadonly: 'reduivy__Agreement__c',
                recordSubtitle: '', 
                searchFields: 'reduivy__External_Educational_Institution__r.Name;Name', 
                lookupFilterGeneral: "(reduivy__External_Educational_Institution__r.RecordTypeId = :externalEducationalInstitutionRecordTypeId)",
                referenceObject: 'reduivy__Agreement__c',
                referenceObjectLabel: this.agrObjectLabel ?? null,
                referenceObjectFieldSet: this.agreementCreationFieldSetName,
                customFilter: this.agreementCustomFilter,
            },
            [SYSTEM_DEPARTMENT]: {
                systemSection: [SYSTEM_DEPARTMENT],
                fieldName: 'reduivy__Department__c',
                prefix: "ACC",
                recordTitle: '{Name}', 
                displayAsReadonly: 'reduivy__Department__c',
                recordSubtitle: '', 
                searchFields: 'Name',
                lookupFilterGeneral: "(RecordTypeId = :departmentRecordTypeId AND Parent.RecordTypeId = :externalEducationalInstitutionRecordTypeId)",
                lookupFilterAgreementFound: "(ParentId = :exEduInstIdFromSelectedAgreement)",
                referenceObject: 'Account',
                referenceObjectLabel: this.accObjectLabel ?? null,
                referenceObjectFieldSet: this.departmentCreationFieldSetName,
                customFilter: this.departmentCustomFilter,
            },
            [SYSTEM_AGREEMENT_RECOGNITION]: {
                systemSection: [SYSTEM_AGREEMENT_RECOGNITION],
                fieldName: 'reduivy__Agreement_Recognition__c',
                prefix: "ARC",
                recordTitle: '{Name}',
                displayAsReadonly: 'reduivy__Agreement_Recognition__c',
                recordSubtitle: '',
                searchFields: 'reduivy__Agreement__r.Name;Name',
                lookupFilterGeneral: "(reduivy__Type__c = :individualAchievementType)",
                lookupFilterAgreementFound: "(reduivy__Agreement__c = :selectedAgreementId)",
                lookupFilterDepartmentFound: "(reduivy__Department__c = :selectedDepartmentId)",
                referenceObject: 'reduivy__Agreement_Recognition__c',
                referenceObjectLabel: this.arcObjectLabel ?? null,
                referenceObjectFieldSet: this.agreementRecognitionCreationFieldSetName,
                customFilter: this.agreementRecognitionCustomFilter,
            }
        }
    }
    
    @wire(MessageContext)
    messageContext;

    @wire(CurrentPageReference, {cacheIdx: "$_cacheIdx"})
    wiredPageRef(pageRef) {
        this.pageRef = pageRef;
        const displayModeFromUrl = pageRef.state.reduivy__displayMode;
        const wizardConfigNameFromUrl = pageRef.state.reduivy__wizardConfigName;

        if(displayModeFromUrl) {
            this.displayMode = displayModeFromUrl;
        }

        if(!wizardConfigNameFromUrl || wizardConfigNameFromUrl !== this.individualAchievementFormConfigurationName) {
            this.replacePageRef(this.displayMode);
        }
    }

    

    //--------------------------base----------------------

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

    get individualAchievementType() {
        return this.individualAchievementRecord?.[IAC_TYPE.fieldApiName] ?? null;
    }

    get individualAchievementTranslationInfo() {
        return this.individualAchievementRecordResponse?.translationInfo ?? {};
    }

    get individualAchievementRecordTypeId() {
        return this.individualAchievementRecord?.RecordTypeId ?? MASTER_RECORD_TYPE_ID;
    }

    get externalEducationalInstitutionRecordTypeId() {
        return this.individualAchievementRecordResponse?.externalEducationalInstitutionRecordTypeId ?? '';
    }

    get departmentRecordTypeId() {
        return this.individualAchievementRecordResponse?.departmentRecordTypeId ?? '';
    }

    
    get isAdminMode() {
        return this.userMode === commonConstants.USER_MODE_ADMIN;
    }

    @wire(getObjectInfo, { objectApiName: IAC_OBJ })
    individualAchievementObjectInfo;
    
    get individualAchievementObjectLabel() {
        return this.individualAchievementObjectInfo?.data?.label ?? IAC_OBJ.objectApiName;
    }

    @wire(ctrlGetIndividualAchievementVerificationStatusesInfo) 
    wiredGetIdvAcLockingModeStatuses(result) {
        
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

    //----------------------------------------------Agreement Recognition--------------------

    @wire(getObjectInfo, { objectApiName: ARC_OBJ })
    arcObj;

    get arcObjectLabel() {
        return this.arcObj?.data?.label
    }

    //----------------------------------------------Agreement (EduInst) Parent lookup Id--------------------

    get selectedAgreementId() {
        let agreementField = this.systemSectionInfos.agreement.fieldName;
        return this.draftIndividualAchievementFieldValue?.[agreementField] ?? undefined;
    }
    
    get agrFields() {
        return [AGR_EX_EDU_INST_FIELD];
    }

    @wire(getRecord, {recordId: "$selectedAgreementId", fields: '$agrFields', cacheIdx: "$_cacheIdx" })
    wiredAgrRecord(result) {
        this.agrRecordResult = result;
        this.agrRecordResponse = null;

        if (result.data) {
            this.agrRecordResponse = result.data;
            this.consoleLog(this.agrRecordResponse, true);
        } else if (result.error) {
            promptError(customLabels.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    get exEduInstIdFromSelectedAgreement() {
        return getFieldValue(this.agrRecordResponse, AGR_EX_EDU_INST_FIELD);
    }

	
    @wire(getObjectInfo, { objectApiName: AGR_OBJ })
    agrObj;

    get agrObjectLabel() {
        return this.agrObj?.data?.label;
    }

    //----------------------------------------------Department (Account) Parent lookup Id--------------------

    @wire(getObjectInfo, { objectApiName: ACC_OBJ })
    accObj;

    get selectedDepartmentId() {
        let departmentField = this.systemSectionInfos.department.fieldName;
        return this.draftIndividualAchievementFieldValue?.[departmentField] ?? undefined;
    }

    get departmentFields() {
        return [ACC_PARENT_ACC_FIELD];
    }

    get accObjectLabel() {
        return this.accObj?.data?.label;
    }

    @wire(getRecord, {recordId: "$selectedDepartmentId", fields: '$departmentFields'})
    wiredDepartmentAccRecord(result) {
        this.departmentAccRecordResult = result;
        this.departmentAccRecordResponse = null;

        if (result.data) {
            this.departmentAccRecordResponse = result.data;
            this.consoleLog(this.departmentAccRecordResponse, true);
        } else if (result.error) {
            promptError(customLabels.ERROR_LABEL, getErrorMessage(result.error));
        }

    }

    get exEduInstIdFromDepartment() {
        return getFieldValue(this.departmentAccRecordResponse, ACC_PARENT_ACC_FIELD);
    }

    //---------------------------------------translation-----------------------------------
    
    /**
    * @description Get Study Unit Translation Name
    */
    @wire(ctrlGetTranslationFieldForName, { objectPrefixes: OBJ_TRANSLATION})
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
            promptError(customLabels.ERROR_LABEL, getErrorMessage(result.error));
        }
    }
    

    //-----------------------------------------custom metadata--------------------------

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

    get idvAcWizardFormLabels() {
        return this.idvAcWizardMetadataResponse?.labels ?? {};
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

    get agreementSectionisShown() {
        return this.matchedWizardFormConfig?.[SYSTEM_AGREEMENT]?.showSubgroup;
    }

    get departmentSectionisShown() {
        return this.matchedWizardFormConfig?.[SYSTEM_DEPARTMENT]?.showSubgroup;
    }

    get agreementRecognitionSectionisShown() {
        return this.matchedWizardFormConfig?.[SYSTEM_AGREEMENT_RECOGNITION]?.showSubgroup;
    }

    get additionalInfoFieldSetName() {
        if(this.matchedWizardFormConfig) {
            return this.matchedWizardFormConfig.additionalInfoFieldSet;
        }

        return undefined;
    }

    get additionalInfoCOutputFieldVarient() {
        return this.preventEditing ? "recordDetailsReadonly" : "recordDetailsEdit"
    }

    @wire(ctrlGetFieldSet, {fieldSetName: "$additionalInfoFieldSetName", objectApiName: 'reduivy__Individual_Achievement__c'}) 
    wiredAdditionalInfoFieldSet(result) {
        this.additionalInfoFieldSetResult = result;
        this.additionalInfoFieldSetResponse = null;

        if (result.data) {
            this.additionalInfoFieldSetResponse = JSON.parse(result.data.responseData);
            this.consoleLog(this.additionalInfoFieldSetResponse, true);
        } else if (result.error) {
            promptError(customLabels.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    get additionalInfoFieldList() {
        let result = [];
        if(this.additionalInfoFieldSetResponse) {
            for(let field of this.additionalInfoFieldSetResponse) {
                result.push(field.fieldName);
            }
        }

        return result;
    }

    get hasAdditionalInfo(){
        return this.additionalInfoFieldSetResponse?.length > 0;
    }

    get additionalInfoFieldSetWrapperList() {
        let result = [];
        if(this.additionalInfoFieldSetResponse) {
            for(let field of this.additionalInfoFieldSetResponse) {
                
                let isPicklist = field.displayType === 'PICKLIST' || field.displayType === 'MULTIPICKLIST';
                let isRichText = field.displayType === 'TEXTAREA';
                let value = this.displayModeIsViewing ? this.individualAchievementFieldValue[field.fieldName] : this.draftIndividualAchievementFieldValue[field.fieldName];
                let displayValue = isPicklist ? (field.picklistOptions.find(opt => opt.value === value)?.label ?? value) : value;
                result.push({
                    ...field,
                    value: value,
                    displayValue: displayValue,
                    isReference: field.displayType === 'REFERENCE',
                    isPicklist: isPicklist,
                    isRichText: isRichText,
                    isViewingPicklistOrRichText: this.displayModeIsViewing && (isPicklist || isRichText)
                })
            }
        }

        return result;
    }
    
    get verificationDetailsFields() {
        let result = [];
        if(this.verificationDetailsFieldsResponse) {
            for(let field of this.verificationDetailsFieldsResponse) {
                let isPicklist = field.displayType === 'PICKLIST' || field.displayType === 'MULTIPICKLIST';
                let isRichText = field.displayType === 'TEXTAREA';
                let value = this.displayModeIsViewing ? this.individualAchievementFieldValue[field.fieldName] : this.draftIndividualAchievementFieldValue[field.fieldName];
                let displayValue = isPicklist ? (field.picklistOptions.find(opt => opt.value === value)?.label ?? value) : value;
                result.push({
                    ...field,
                    value: value,
                    displayValue: displayValue,
                    isReference: field.displayType === 'REFERENCE',
                    isPicklist: isPicklist,
                    isRichText: isRichText,
                    isViewingPicklistOrRichText: this.displayModeIsViewing && (isPicklist || isRichText)
                }
                );
            }
        }

        return result;
    }

    /**
     * @description the list that is used to display the system section in the accordion.
     */
    get systemSectionWrapperList() {
        if(this.matchedWizardFormConfig) {
            let result = [];
            let agreementField = this.systemSectionInfos.agreement.fieldName;
            let departmentField = this.systemSectionInfos.department.fieldName;

            for(let systemSectionName of Object.keys(this.systemSectionInfos)) {

                const systemSectionInfo = this.systemSectionInfos[systemSectionName];
                if(this.matchedWizardFormConfig?.[systemSectionName]?.showSubgroup) {
                    let systemSectionConfig = {...this.matchedWizardFormConfig?.[systemSectionName]}

                    systemSectionConfig.label = this.idvAcWizardFormLabels[systemSectionConfig.label] ?? systemSectionConfig.label;         //the inputbox label
                    systemSectionConfig.lookupFieldName = systemSectionInfo.fieldName                                                       //the system field
                    systemSectionConfig.systemSection = systemSectionName;                                                                  //system section name
                    systemSectionConfig.fallbackFieldPlaceholder = FALLBACK_FIELD_PLACEHOLDER_LABEL.format([systemSectionConfig.label]);    //placeholder of the fallback text field
                    systemSectionConfig.required = systemSectionConfig.isRequired;                                                          //the value of the fallback field
                    systemSectionConfig.recordTitle = systemSectionInfo.recordTitle;                                                        //the title of the selectable option
                    systemSectionConfig.recordSubtitle =  systemSectionInfo.recordSubtitle;                                                 //the subtitle of the selectable option
                    systemSectionConfig.searchFields = systemSectionInfo.searchFields                                                       //the search fields
                    systemSectionConfig.lookupFieldData = {
                        systemSection: systemSectionName,
                        fallbackFieldName: systemSectionConfig.fallbackField
                    }
                    systemSectionConfig.studentCustomLookupFieldSize = systemSectionConfig.fallbackField && this.displayModeIsEditing ? 12 : 6;
                    systemSectionConfig.isLinked = !!this.draftIndividualAchievementFieldValue?.[systemSectionConfig.lookupFieldName];
                    systemSectionConfig.linkButtonLabel = systemSectionConfig.isLinked ? this.linkedLabel : this.linkLabel;

                    let lookupFieldNameRelation;
                    let systemDisplayField = systemSectionInfo.displayAsReadonly;
                    if(systemDisplayField.endsWith('__c')) {
                        lookupFieldNameRelation = systemDisplayField.slice(0, -3) + '__r';
                    } else if(systemDisplayField.endsWith('Id')) {
                        lookupFieldNameRelation = systemDisplayField.slice(0, -2);
                    } else {
                        lookupFieldNameRelation = systemDisplayField;
                    }
                    let nameField = this.objectTranslatedNameResponse?.[systemSectionInfo.prefix];
                    let nameFromTranslationInfo = extractFieldValue(this.individualAchievementRecord, lookupFieldNameRelation + '.' + nameField, this.individualAchievementTranslationInfo, this.language);
                    if(!nameFromTranslationInfo) {
                        nameFromTranslationInfo = extractFieldValue(this.individualAchievementRecord, lookupFieldNameRelation + '.Name', this.individualAchievementTranslationInfo, this.language);
                    }
                    systemSectionConfig.fallbackValue = nameFromTranslationInfo ?? this.individualAchievementRecord?.[systemSectionConfig.fallbackField];
                    systemSectionConfig.isNotListed = !nameFromTranslationInfo && this.individualAchievementRecord?.[systemSectionConfig.fallbackField];
                    systemSectionConfig.fieldReferenceObject = systemSectionInfo.referenceObject;
                    
                    //search filter
                    //this is the must-have filter
                    let searchFilterList = [];
                    if(systemSectionInfo.lookupFilterGeneral) {
                        searchFilterList.push(systemSectionInfo.lookupFilterGeneral);
                    }
                    systemSectionConfig.searchFilterBindMap = {
                        'externalEducationalInstitutionRecordTypeId': this.externalEducationalInstitutionRecordTypeId,
                        'departmentRecordTypeId': this.departmentRecordTypeId,
                        'active': STATUS_ACTIVE,
                        'exEduInstIdFromSelectedAgreement': this.exEduInstIdFromSelectedAgreement,
                        'selectedDepartmentId': this.selectedDepartmentId,
                        'selectedAgreementId': this.selectedAgreementId,
                        'individualAchievementType': this.individualAchievementType
                    }

                    //custom filter by user
                    if(systemSectionInfo.customFilter) {
                        searchFilterList.push('(' + systemSectionInfo.customFilter + ')');
                    }
                    //filter if parent system section is found
                    if(systemSectionInfo.lookupFilterParentSystemSectionFound) {
                        searchFilterList.push(systemSectionInfo.lookupFilterParentSystemSectionFound);
                    }
                    
                    const hasValue = (field) => !!this.draftIndividualAchievementFieldValue?.[field];
                    // Default to disabled for safety, then enable based on specific conditions
                    systemSectionConfig.disableRecordSelection = true;

                    switch (systemSectionName) {
                        case SYSTEM_AGREEMENT:
                            // Always enabled if the section exists
                            systemSectionConfig.disableRecordSelection = false;
                            break;

                        case SYSTEM_DEPARTMENT: {
                            // Enable if Agreement is hidden OR if Agreement is shown and has a value
                            const agreementFilled = hasValue(agreementField);
                            if(agreementFilled) {
                                searchFilterList.push(systemSectionInfo.lookupFilterAgreementFound);
                            }
                            if (!this.agreementSectionisShown || agreementFilled) {
                                systemSectionConfig.disableRecordSelection = false;
                            }
                            break;
                        }

                        case SYSTEM_AGREEMENT_RECOGNITION: {
                            const deptFilled = hasValue(departmentField);
                            const agrFilled = hasValue(agreementField);

                            if(deptFilled) {
                                searchFilterList.push(systemSectionInfo.lookupFilterDepartmentFound);
                            }
                            if(agrFilled) {
                                searchFilterList.push(systemSectionInfo.lookupFilterAgreementFound);
                            }
                            const deptCondition = !this.departmentSectionisShown || deptFilled;
                            const agrCondition = !this.agreementSectionisShown || agrFilled;

                            // Enable only if both preceding dependencies are satisfied (either hidden or filled)
                            if (deptCondition && agrCondition) {
                                systemSectionConfig.disableRecordSelection = false;
                            }
                            break;
                        }
                        default: break;
                    }

                    systemSectionConfig.searchFilter = searchFilterList.join(' AND ');
                    systemSectionConfig.buttonDisabled = systemSectionConfig.isLinked || this.displayModeIsViewing || systemSectionConfig.disableRecordSelection;


                    result.push(systemSectionConfig);
                }
            }
            return result;
        }

        return [];
    }

    //--------------------------admin system fields -------------------------------------

    get optionsLabel() {
        return OPTIONS_LABEL;
    }
    
    handleLinkButton(event){
        let customLookupFieldName = event.target.dataset.name;
        let fallbackValue = event.target.dataset.fallbackValue;
        this.consoleLog(`handleLinkButton: customLookupFieldName:${customLookupFieldName} - fallbackValue:${fallbackValue}`);

        let element = this.template.querySelector(`c-custom-lookup-field[data-name="${customLookupFieldName}"]`);
        element.setSearchKeyword(fallbackValue, true, true);
    }


    async handleSystemSectionNewButton(event) {
        let systemSection = event.target.dataset.systemSection;
        let referenceObjectName = this.systemSectionInfos[systemSection]?.referenceObject;
        let referenceObjectLabel = this.systemSectionInfos[systemSection]?.referenceObjectLabel;
        let referenceObjectFieldSet = this.systemSectionInfos[systemSection]?.referenceObjectFieldSet;

        this.consoleLog(`handleLookupChange: referenceObjectName:${referenceObjectName} - referenceObjectLabel:${referenceObjectLabel} - systemSection:${systemSection}`)

        if(referenceObjectName) {
            try {
                
                let result = await recordEditModal.open({
                    
                    size: "small",
                    headerLabel: customLabels.NEW_RECORD_LABEL.format([referenceObjectLabel]),
                    enableDebugMode: this.enableDebugMode,
                    objectApiName: referenceObjectName,
                    fieldSetName: referenceObjectFieldSet,
                    editFormColumnNo: 2,
                    enableNewParentCreation: this.userMode === commonConstants.USER_MODE_ADMIN,
                    defaultValue: { Name: event.target.dataset.fallbackValue }
                });
                this.consoleLog('recordEditModal.close');
                this.consoleLog(result, true);

                if(result) {
                    const { operation, eventResult, eventData } = result;
                    if(operation === 'submit' && eventResult === 'success') {
                        let recordId = eventData.Id;
                        this.consoleLog('recordEditModal.close.recordId = ' + recordId);

                        promptSuccess(customLabels.SUCCESS_LABEL, STUDENT_ACHIEVEMENT_LINKED_SUCCESSFULLY_LABEL.format([referenceObjectLabel]));
                        notifyRecordUpdateAvailable([{recordId: recordId}]);
                        
                        let element = this.template.querySelector(`c-custom-lookup-field[data-name="${systemSection}"]`);
                        await element.setSelectedRecord(recordId);
                    }

                }
            } catch(error) {
                promptError(customLabels.ERROR_LABEL, getErrorMessage(error));
            }
        }
    }

    get adminSystemSectionsClass() {
        if(this.displayModeIsViewing) {
            return 'slds-hide';
        }
        return 'slds-show';
    }
    
    //-----------------------student system fields -------------------------

    get linkedLabel() {
        return STUDENT_ACHIEVEMENT_LINKED_LABEL;
    }

    get linkLabel() {
        return STUDENT_ACHIEVEMENT_LINK_LABEL;
    }

    get newLabel() {
        return this.label.NEW_LABEL;
    }

    get studentSystemSectionsViewClass() {
        return this.displayModeIsViewing ? 'slds-show' : 'slds-hide';
    }

    get studentSystemSectionsEditClass() {
        return this.displayModeIsEditing ? 'slds-show' : 'slds-hide';
    }

    //----------------------------------------accordion----------------------
    

    get activeAccordionList() {
        if(!this.additionalInfoFieldSetName) {
            return [...Object.keys(this.systemSectionInfos)];
        }
        if(this.displayModeIsEditing) {
            return [...Object.keys(this.systemSectionInfos), 'detailsedit', 'verificationedit'];
        }
        return [...Object.keys(this.systemSectionInfos), 'detailsview', 'verificationview'];

    }

    //------------------------------------------display mode---------------------------

    get displayModeIsEditing() {
        return this.displayMode === DISPLAY_MODE_EDIT;
    }

    get displayModeIsViewing() {
        return this.displayMode === DISPLAY_MODE_VIEW;
    }

    //---------------------------------------------------additional details---------------------

    get detailsLabel() {
        return DETAILS_LABEL;
    }

    get recordFormFields() {
        let systemFieldsNameList = Object.values(this.systemSectionInfos).map(config => config.fieldName);
        return [...this.verificationDetailsFieldList, ...this.additionalInfoFieldList, ...systemFieldsNameList];
    }

    get recordViewFormClass() {
        return this.displayModeIsEditing ? 'slds-hide' : 'slds-show';
    }
    
    get recordEditFormClass() {
        return this.displayModeIsViewing ? 'slds-hide' : 'slds-show';
    }

    //-----------------------------------verification details-------------------------------------
    
    get hasVerificationDetails() {
        return Array.isArray(this.verificationDetailsFieldsResponse) && this.verificationDetailsFieldsResponse.length > 0;
    }

    @wire(ctrlGetFieldSet, {fieldSetName:"$verificationDetailsFieldSetName", objectApiName: 'reduivy__Individual_Achievement__c'})
    wiredGetVerificationDetailsFields(result) {
        this.verificationDetailsFieldsResult = result;
        this.verificationDetailsFieldsResponse = null;
        
        if (result.data) {
            this.verificationDetailsFieldsResponse = JSON.parse(result.data.responseData);
            this.consoleLog(this.verificationDetailsFieldsResponse, true);
        } else if (result.error) {
            promptError(customLabels.ERROR_LABEL, getErrorMessage(result.error));
        }

    }

    get verificationDetailsLabel() {
        return VERIFICATION_DETAILS_LABEL;
    }

    get verificationDetailsFieldList() {
        let result = [];
        if(this.verificationDetailsFieldsResponse) {
            for(let field of this.verificationDetailsFieldsResponse) {
                result.push(field.fieldName);
            }
        }

        return result;
    }
    //-----------------------------------------

    handleCancelClick() {
        this.displayMode = DISPLAY_MODE_VIEW;
        this.replacePageRef();

        let allCustomLookup = [...this.template.querySelectorAll('c-custom-lookup-field')];
        for(let cmp of allCustomLookup) {
            let lookupFieldName = cmp.lookupFieldName;
            cmp.setCustomValidity('');
            cmp.reportValidity();
            let lookupFieldValue = this.individualAchievementFieldValue?.[lookupFieldName];
            if(lookupFieldValue)  {
                cmp.setSelectedRecord(lookupFieldValue);
            } else {
                cmp.clear();
            }
        }

        let allInputField = [...this.template.querySelectorAll('lightning-input-field')];
        for(let cmp of allInputField) {
            let fieldName = cmp.dataset.fieldName;
            cmp.value = this.individualAchievementFieldValue[fieldName];
            cmp.currentTarget?.reportValidity();
            if(!this.individualAchievementFieldValue[fieldName] && this.draftIndividualAchievementFieldValue[fieldName]) {
                cmp.reset();
            }
        }

        this.draftIndividualAchievementFieldValue = {};
    }
    
    handleEditClick() {
        if(this.displayModeIsEditing) {
            return;
        }
        if(this.preventEditing) {
            return;
        }
        this.displayMode = DISPLAY_MODE_EDIT;
        this.replacePageRef();
        this.draftIndividualAchievementFieldValue = {...this.individualAchievementFieldValue};

    }

    get individualAchievementIsLocking() {
        let status = this.individualAchievementRecord?.[IAC_VERIFICATION_STATUS_FIELD.fieldApiName];
        return this.individualAchievementLockedVerificationStatuses.includes(status);
    }

    get preventEditing() {
        return !this.isAdminMode && this.individualAchievementIsLocking;
    }

    handleFormFieldChange(event){
        
        let dataFieldName = event.target.fieldName;
        let dataDisplayType = event.target.dataset.displaytype;

        let dataFieldValue = getFormDataFieldOnChangeValue(dataDisplayType, event.detail);

        this.draftIndividualAchievementFieldValue[dataFieldName] = dataFieldValue;
    }

    handleSystemSectionLookupChange(event) {
        this.consoleLog('handleSystemSectionLookupChange');
        this.consoleLog(event, true);
        
        let isFallback = event.detail.isFallback;
        
        if(isFallback) {
            let fallbackFieldName = event.detail.lookupFieldData.fallbackFieldName;
            let fallbackValue = event.detail.fallbackValue;
            this.draftIndividualAchievementFieldValue[fallbackFieldName] = fallbackValue;
            let additionalInfoCmp = Object.values(this.template.querySelectorAll(`lightning-input-field:not([data-type="systemSection"])`)).find(cmp => cmp.fieldName === fallbackFieldName);
            if(additionalInfoCmp){
                additionalInfoCmp.value = fallbackValue;
            }
        } else {
            let lookupFieldName = event.detail.lookupFieldName;
            let lookupRecordId = event.detail.value;
            this.draftIndividualAchievementFieldValue[lookupFieldName] = lookupRecordId;
            let additionalInfoCmp = Object.values(this.template.querySelectorAll(`c-custom-lookup-field:not([data-type="systemSection"])`)).find(cmp => cmp.lookupFieldName === lookupFieldName);            
            if(additionalInfoCmp){
                if(lookupRecordId) {
                    additionalInfoCmp.setSelectedRecord(lookupRecordId);
                } else {
                    additionalInfoCmp.clear();
                }
            }

            //clear children system field custom lookup field if parent is cleared
            if(!lookupRecordId) {
                this.clearChildSystemSection(lookupFieldName);
            }
        }

    }

    async handleAdditionalDetailsLookupChange(event) {
        this.consoleLog('handleAdditionalDetailsLookupChange');
        this.consoleLog(event, true);

        let isFallback = event.detail.isFallback;
        let lookupFieldName = event.detail.lookupFieldName;

        let systemSection = Object.values(this.systemSectionInfos).find(config => config.fieldName === lookupFieldName)?.systemSection;

        if(isFallback) {

            let fallbackFieldName = event.detail.lookupFieldData.fallbackFieldName;
            let fallbackValue = event.detail.fallbackValue;
            this.draftIndividualAchievementFieldValue[fallbackFieldName] = fallbackValue;
            let cmp = this.template.querySelector(`c-custom-lookup-field[data-name="${systemSection}"]`);
            

            if(cmp){
                await cmp.setIsNotListed(true);
                await cmp.setSearchKeyword(fallbackValue);
            }

        } else {
            
            let lookupRecordId = event.detail.value;
            this.draftIndividualAchievementFieldValue[lookupFieldName] = lookupRecordId;
            if(systemSection) {
                let cmp = this.template.querySelector(`c-custom-lookup-field[data-name="${systemSection}"]`);
                if(cmp) {
                    if(lookupRecordId) {
                        cmp.setSelectedRecord(lookupRecordId);
                    } else {
                        cmp.clear();
                    }
                }
            }

            //clear children system field custom lookup field if parent is cleared
            if(!lookupRecordId) {
                this.clearChildSystemSection(lookupFieldName);
            }
        }
    }

    clearChildSystemSection(lookupFieldName) {

        let childrenCmps = [];
        if(lookupFieldName === this.systemSectionInfos.agreement.fieldName || lookupFieldName === this.systemSectionInfos.department.fieldName) {
            childrenCmps = childrenCmps.concat(Object.values(this.template.querySelectorAll(`c-custom-lookup-field`)).filter(cmp => cmp.lookupFieldName === this.systemSectionInfos.agreementRecognition.fieldName));
        }
        if(lookupFieldName === this.systemSectionInfos.agreement.fieldName) {
            childrenCmps = childrenCmps.concat(Object.values(this.template.querySelectorAll(`c-custom-lookup-field`)).filter(cmp => cmp.lookupFieldName === this.systemSectionInfos.department.fieldName));
        }

        for(let cmp of childrenCmps) {
            cmp.clear();
        }
    }



    handleRecordEditFormLoad(event) {

        
        this.individualAchievementFieldValue = {};

        if(event.detail?.records?.[this.recordId]) {

            for(let fieldName of Object.keys(event.detail.records[this.recordId].fields)) {
                let value = event.detail.records[this.recordId].fields[fieldName].value;
                if(typeof value !== 'object' && value) {
                    this.individualAchievementFieldValue[fieldName] = value;
                }
            }
        }

        let customLookupFieldElements = Object.values(this.template.querySelectorAll('c-custom-lookup-field'));
        for(let systemSectionName of Object.keys(this.systemSectionInfos)) {
            let systemField = this.systemSectionInfos[systemSectionName].fieldName;
            let elementList = customLookupFieldElements.filter(ele => ele.lookupFieldName === systemField);
            if(elementList) {
                elementList.forEach(element => {
                    let fieldValue = this.individualAchievementFieldValue[systemField];
                    element.setSelectedRecord(fieldValue);
                })
            }
            
        }

        for(let additionalField of this.additionalInfoFieldSetWrapperList) {
            if(this.individualAchievementFieldValue[additionalField.fieldName]) {
                
                additionalField.value = this.individualAchievementFieldValue[additionalField.fieldName];
                if(additionalField.isReference) {
                    
                    let targetFieldName = additionalField.fieldName.endsWith('__r') ? additionalField.fieldName.slice(0, -1) + 'c' : additionalField.fieldName;
                    let fieldValue = this.individualAchievementFieldValue[targetFieldName]
                    let elementList = customLookupFieldElements.filter(ele => ele.lookupFieldName === targetFieldName);
                    if(elementList && elementList.length > 0) {
                        elementList.forEach(ele => ele.setSelectedRecord(fieldValue));
                    }
                }
            }
        }
    }

    async handleSaveClick() {
        this.consoleLog('handleSaveClick');
        if(this.preventEditing) {
            this.displayMode = DISPLAY_MODE_VIEW;
            this.replacePageRef();
            return;
        }

        this.refs.editFormButton.click();
        
    }

    async handleSaveRecordEditForm(event) {
        event.preventDefault();

        let element = [...this.template.querySelectorAll('[data-required="true"]')];
        let requiredFieldsValid = element.reduce((validSoFar, inputCmp) => {

            this.consoleLog('validateRequiredDataFields :: ' + inputCmp.name + ' - ' + inputCmp.value);
            let reportValidity = inputCmp?.reportValidity();
            if(!reportValidity) {
                inputCmp.scrollIntoView(false);
            }
            return validSoFar && reportValidity

        }, true);

        if(!requiredFieldsValid){
            return;
        }

        //add all custom lookup field value
        const fields = event.detail.fields;
        for(const [key, value] of Object.entries(this.draftIndividualAchievementFieldValue)) {
            fields[key] = value;
        }
        
        //prompt confirmation if is student, and verification status is verified, and individualAchievement is not locked
        let verificationStatus = this.individualAchievementRecord?.[IAC_VERIFICATION_STATUS_FIELD.fieldApiName];
        let allowSaving = true;
        if(
            !this.isAdminMode &&
            this.individualAchievementVerificationStatusType?.[VERIFICATION_STATUS_TYPE_VERIFIED]?.includes(verificationStatus) &&
            !this.individualAchievementIsLocking
        ) {

            allowSaving = await this.promptSaveConfirmation();
            if(!allowSaving) {
                return;
            }

            //set the verification status to not verified
            fields[IAC_VERIFICATION_STATUS_FIELD.fieldApiName] = this.individualAchievementVerificationStatusType?.[VERIFICATION_STATUS_TYPE_OPEN]?.[0];
        }

        this.toggleSpinner(1);
        this.refs.recordEditForm.submit(fields);
    }

    handleRecordEditFormSuccess(event) {
        notifyRecordUpdateAvailable([{recordId: this.recordId}]);
        this.draftIndividualAchievementFieldValue = {};
        
        promptSuccess(this.label.SUCCESS_LABEL, this.label.YOUR_CHANGES_ARE_SAVED_LABEL);
        this.displayMode = DISPLAY_MODE_VIEW;
        this.replacePageRef();
        this.toggleSpinner(-1);
        this.publishRefresh();
        this.refs.recordViewForm.refreshData();
        this.dispatchEvent(new RefreshEvent());
    }

    async promptSaveConfirmation() {

        let allowSaving = false;
            
        let confirmationText = WARNING_EDIT_VERIFIED_RECORD.format([this.individualAchievementObjectLabel, this.individualAchievementRecord?.Name]);
        let result = await genericConfirmationModal.open({
            size: "small",
            modalTitle: this.label.CONFIRMATION_LABEL,
            confirmationText1: confirmationText,
            showSubmitButton: true,
            submitButtonLabel: this.label.CONFIRM_LABEL,
            showCancelButton: true,
            cancelButtonLabel: this.label.CANCEL_LABEL,
            eventSource: "saveIndividualAchievement",
            enableDebugMode: this.enableDebugMode
        });

        if (result){
            const { operation, eventSource, eventData } = result; 
            if(operation === 'submit' && eventSource === 'saveIndividualAchievement') {
                allowSaving = true;
            }
        }
        
        return allowSaving;

    }

    
    publishRefresh(){
        let message = {
            eventSource: StudentAchievementDetails.name,
            recordId: this.recordId,
            operation: 'refresh'
        }
        publish(this.messageContext, MESSAGE_CHANNEL, message);
    }


    handleRecordEditFormFail(event) {
        promptError(this.label.ERROR_LABEL, getErrorMessage(event.detail));
        this.toggleSpinner(-1);
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
     * @description refresh when message received. this is to refresh the field value after submitting for verification, or a new individual achievement unit is created.
     */
    handleMessage(message) {
        if(
            message.eventSource !== StudentAchievementDetails.name && 
            message.operation === 'refresh' && 
            message.recordId === this.recordId
        ) {
            this.dispatchEvent(new RefreshEvent());
        }
    }

    replacePageRef(displayMode) {

        if(
            (
                !this.pageRef.state.reduivy__displayMode && this.pageRef.state.reduivy__wizardConfigName && 
                this.pageRef.state.reduivy__wizardConfigName === this.individualAchievementFormConfigurationName
            ) ||
            this.pageRef.attributes.actionName === 'edit'
        ) {
            return;
        }

        let newPageRef = Object.assign({}, this.pageRef, {
            state: Object.assign({}, this.pageRef.state, {
                reduivy__displayMode: displayMode === DISPLAY_MODE_VIEW ? undefined : displayMode,
                reduivy__wizardConfigName: this.individualAchievementFormConfigurationName
            })
        })

        this[NavigationMixin.Navigate](newPageRef, true);
    }

    /**
     * @descripton connected callback
     */
    connectedCallback(){
		this.refreshContainerID = registerRefreshContainer(this, this.refreshData);
        this._cacheIdx = initCacheIdx();
        this.subscribeToMessageChannel();
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

    	refreshApex(this.idvAcWizardMetadataResult);
        refreshApex(this.individualAchievementRecordResult);
        refreshApex(this.objectTranslatedNameResult);
        refreshApex(this.verificationDetailsFieldsResult);
        refreshApex(this.additionalInfoFieldSetResult);
        refreshApex(this.arcRecordResult);
        refreshApex(this.agrRecordResult);
        refreshApex(this.departmentAccRecordResult);
        refreshApex(this.individualAchievementVerificationStatusesInfoResult);
        refreshApex(this.pageRef);

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
     * @description the user language
     */
    get language() {
        return LANG;
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
        logInfo('StudentAchievementDetails', anything, this.enableDebugMode, isJson);
    }


	
}