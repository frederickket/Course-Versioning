/**
 * @Author 		WDCi (XW)
 * @Date 		May 2024
 * @group 		Enrollment Wizard
 * @Description To withdraw the student from the term
 * @changehistory
 * ISS-002436 05-05-2025 XW - create new class
 */
import { api, wire } from 'lwc';
import LightningModal from 'lightning/modal'
import { promptError, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo } from 'c/loggingUtil';
import { customLabels } from 'c/labelLoader';
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { initCacheIdx } from 'c/lwcUtil';

import IEN_ENROLLMENT_STATUS from '@salesforce/schema/Individual_Enrollment__c.Enrollment_Status__c';
import IEN_OBJ from '@salesforce/schema/Individual_Enrollment__c';
import STM_OBJ from '@salesforce/schema/Study_Term__c';

//Apex methods
import ctrlGetTranslationFieldForNameByObjPrefix from '@salesforce/apex/REDU_Translation_LCTRL.getTranslationFieldForNameByObjPrefix';
import ctrlGetIndividualEnrollments from '@salesforce/apex/REDU_IpePathwayWithdrawFromTerm_LCTRL.getIndividualEnrollments';
import ctrlGetDefaultWithdrawnStatus from '@salesforce/apex/REDU_IpePathwayWithdrawFromTerm_LCTRL.getDefaultWithdrawnStatus';
import ctrlUpdateEnrollmentStatus from '@salesforce/apex/REDU_IpePathwayWithdrawFromTerm_LCTRL.updateEnrollmentStatus';

//custom labels
import WITHDRAW_FROM_TERM_CONFIRMATION_LABEL from '@salesforce/label/c.Withdraw_From_Term_Confirmation';
import NO_IEN_FOUND_LABEL from '@salesforce/label/c.No_Individual_Enrollment_Found_For_Academic_Term';
import WITHDRAWN_IEN_FORMAT_LABEL from '@salesforce/label/c.Withdraw_Individual_Enrollment_List_Format';

const OBJ_TRANSLATION = [
    "SPL"
];

const IEN_RECORD_TYPE_STUDENT = 'Student';

export default class IpePathwayWithdrawFromTermModal extends LightningModal {
	
	//configurable attributes
    @api iprId;
    @api statusesForWithdrawal;

	@api enableDebugMode = false;
	
	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false
	loadedLists = 0;
    selectedEnrollmentStatus;

    //cache
    _cacheIdx;
	
    //wire attribute
    ienResult;
    ienResponse;
    ienObjResult;
    ienObjResponse;
    stmObjResult;
    stmObjResponse;
    objectTranslatedNameResult;
    objectTranslatedNameResponse;
    defaultWithdrawnStatusResult;
    defaultWithdrawnStatusResponse;
    enrollmentStatusPicklistResult;
    enrollmentStatusPicklistResponse;
	
	//js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'jquery', 'tooltips'
    modules = ['stringutil'];

    connectedCallback() {
        this._cacheIdx = initCacheIdx();
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
     * @description confirmation message in the body
     */
    get withdrawFromTermConfirmation() {
        return WITHDRAW_FROM_TERM_CONFIRMATION_LABEL;
    }

    /**
     * @description confirmation title in the header
     */
    get confirmationTitle(){
        return customLabels.CONFIRMATION_LABEL;
    }

    /**
     * @description cancel label for button
     */
    get cancelLabel(){
        return customLabels.CANCEL_LABEL;
    }

    /**
     * @description confirm label for button
     */
    get confirmLabel(){
        return customLabels.CONFIRM_LABEL;
    }

    /**
     * @description get ien object info
     */
    @wire(getObjectInfo, { objectApiName: IEN_OBJ })
    wireGetIenObjectInfo(result) {
        this.ienObjResult = result;
        this.ienObjResponse = null;

        if(result.data) {
            this.consoleLog(this.ienObjResponse, true);
            this.ienObjResponse = result.data;
        } else if (result.error) {
            promptError(customLabels.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    /**
     * @description get stm object info
     */
    @wire(getObjectInfo, { objectApiName: STM_OBJ })
    wireGetStmObjectInfo(result) {
        this.stmObjResult = result;
        this.stmObjResponse = null;

        if(result.data) {
            this.consoleLog(this.stmObjResponse, true);
            this.stmObjResponse = result.data;
        } else if (result.error) {
            promptError(customLabels.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    /**
     * @description get related ien from the given ipr id
     */
    @wire(ctrlGetIndividualEnrollments, { iprId: '$iprId', statusesForWithdrawal: '$statusesForWithdrawal',  cacheIdx:'$_cacheIdx' })
    wireGetIndividualEnrollments(result) {
        
        this.ienResult = result;
        this.ienResponse = null;
        
        if (result.data) {
            this.ienResponse = JSON.parse(result.data.responseData);
            this.consoleLog(this.ienResponse, true);
        } else if (result.error) {
            promptError(customLabels.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    /**
     * @description Get Study Unit Translation
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
            promptError(customLabels.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    /**
     * @description get default withdraw status to set as default in combobox
     */
    @wire(ctrlGetDefaultWithdrawnStatus)
    wireGetDefaultWithdrawnStatus(result) {
        this.defaultWithdrawnStatusResult = result;
        this.defaultWithdrawnStatusResponse = null;

        if(result.data) {
            this.defaultWithdrawnStatusResponse = result.data.responseData;
            this.consoleLog(this.defaultWithdrawnStatusResponse);
            if(!this.selectedEnrollmentStatus) {
                this.selectedEnrollmentStatus = this.defaultWithdrawnStatusResponse;
            }
        } else if (result.error) {
            promptError(customLabels.ERROR_LABEL, getErrorMessage(result.error));
        }
    }
    
    /**
     * @description get enrollment status picklist for the student record type
     */
    @wire(getPicklistValues, { recordTypeId: '$ienStudentRecordTypeId', fieldApiName: IEN_ENROLLMENT_STATUS })
    wireEnrollmentStatusPicklist(result) {
        this.enrollmentStatusPicklistResult = result;
        this.enrollmentStatusPicklistResponse = null;
        
        if(result.data) {
            this.enrollmentStatusPicklistResponse = result.data;
            this.consoleLog(this.enrollmentStatusPicklistResponse, true);
        } else if (result.error) {
            promptError(customLabels.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    /**
     * @description the ien study record type id
     */
    get ienStudentRecordTypeId(){
        if(this.ienObjResponse) {
            return Object.values(this.ienObjResponse.recordTypeInfos).find(recordType => recordType.name === IEN_RECORD_TYPE_STUDENT).recordTypeId;
        }

        return '';
    }

    /**
     * @description list of ien to be displayed on the modal as strings
     */
    get ienList(){
        if(this.isIenDataReady && this.ienRecordsAreFound) {
            let result = [];
            for(let ien of this.ienResponse) {
                let splNameList = [];
                let ienString = '';

                //display study plan name if found
                if(ien.reduivy__Individual_Plan_Units__r?.records) {
                    for(let ips of ien.reduivy__Individual_Plan_Units__r.records){
                        splNameList.push(
                            ips?.reduivy__Study_Plan_Structure__r?.reduivy__Study_Plan__r?.[this.objectTranslatedNameResponse?.SPL] || ips.reduivy__Study_Plan_Structure__r?.reduivy__Study_Plan__r?.Name
                        )
                    }
                    ienString = WITHDRAWN_IEN_FORMAT_LABEL.format([
                        ien?.reduivy__Study_Offering__r?.reduivy__Study_Unit__r?.reduivy__Unit_Code__c,
                        splNameList.join(', ')
                    ]);
                } else {
                    ienString = ien?.reduivy__Study_Offering__r?.reduivy__Study_Unit__r?.reduivy__Unit_Code__c;
                }

                result.push(ienString);
            }
            return result;
        }

        return [];
    }

    /**
     * @description get list of ien id to be updated
     */
    get ienIdList() {
        if(this.isIenDataReady && this.ienRecordsAreFound) {
            return this.ienResponse.map(ien=> ien.Id);
        }

        return [];
    }

    /**
     * @description get enrollement status field label 
     */
    get enrollmentStatusLabel() {
        if(this.ienObjResponse) {
            return this.ienObjResponse.fields.reduivy__Enrollment_Status__c.label;
        }

        return '';
    }

    /**
     * @description get enrollement status options
     */
    get enrollmentStatusOptions() {
        if(this.enrollmentStatusPicklistResponse?.values) {
            return this.enrollmentStatusPicklistResponse.values;
        }

        return [];
    }

    /**
     * @description get enrollement status field label 
     */
    get studyTermLabel() {
        if(this.stmObjResponse) {
            return this.stmObjResponse.label;
        }

        return '';
    }

    /**
     * @description get individual enrollment plural label
     */
    get individualEnrollmentPluralLabel(){
        if(this.ienObjResponse) {
            return this.ienObjResponse.labelPlural;
        }
        return '';
    }

    /**
     * @description return true if ien records are found
     */
    get ienRecordsAreFound() {
        return this.ienResponse?.length > 0;
    }

    /**
     * @description return true if individual enrollment data is ready
     */
    get isIenDataReady(){
        return this.iprId && this.ienResponse;
    }
	
    /**
     * @description show the records found section
     */
    get showRecordsFound(){
        return this.isIenDataReady && this.ienRecordsAreFound;
    }

    /**
     * @description show the records not found section
     */
    get showRecordsNotFound(){
        return this.isIenDataReady && !this.ienRecordsAreFound;
    }

    /**
     * @description label for no ien records found
     */
    get noIenFoundLabel() {
        return NO_IEN_FOUND_LABEL.format([this.individualEnrollmentPluralLabel, this.studyTermLabel]);
    }
    
    /**
     * @description show the records found section
     */
    handleEnrollmentStatusChange(event){
        this.consoleLog('handleEnrollmentStatusChange');
        this.selectedEnrollmentStatus = event.detail.value;
    }

    /**
     * @description cancel button click
     */
    handleCancelClick() {
        this.consoleLog('handleCancelClick');
        this.close({
            operation: 'cancel'
        });
    }

    /**
     * @description confirm button click
     */
    async handleConfirmClick() {
        this.consoleLog('handleConfirmClick');

        this.toggleSpinner(1);
        try {
            let updatedRecordIdsResult = await ctrlUpdateEnrollmentStatus({
                iprId: this.iprId,
                ienIdList: this.ienIdList,
                enrollmentStatus: this.selectedEnrollmentStatus
            });

            let updatedRecordIds = JSON.parse(updatedRecordIdsResult.responseData);
            this.consoleLog(updatedRecordIds, true);
            let notifyList = [];
            for(let id of updatedRecordIds) {
                notifyList.push({recordId: id});
            }
            notifyRecordUpdateAvailable(notifyList);
            
            promptSuccess(customLabels.SUCCESS_LABEL, customLabels.YOUR_CHANGES_ARE_SAVED_LABEL);
            this.toggleSpinner(-1);

            this.close({
                operation: 'saved',
            });

        } catch (error) {
            promptError(customLabels.ERROR_LABEL, getErrorMessage(error));
            this.toggleSpinner(-1);
        }
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
        logInfo('IpePathwayWithdrawFromTermModal', anything, this.enableDebugMode, isJson);
    }
	
}