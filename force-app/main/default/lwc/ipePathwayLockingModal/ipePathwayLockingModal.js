/**
 * @Author 		WDCi (Lean)
 * @Date 		Apr 2025
 * @group 		Enrollment wizard
 * @Description Modal for locking or unlocking an individual pathway
 * @changehistory
 * ISS-002401 22-04-2025 Lean - new component
 */
import { api, wire } from 'lwc';
import LightningModal from 'lightning/modal';

import { promptError, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo } from 'c/loggingUtil';
import { notifyRecordUpdateAvailable, updateRecord } from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { customLabels } from 'c/labelLoader';

import IPR_OBJ from '@salesforce/schema/Individual_Academic_Progress__c';

import LOCK_UNLOCK_CONFIRMATION_LABEL from '@salesforce/label/c.Lock_Unlock_Confirmation';

export default class IpePathwayLockingModal extends LightningModal {
	
	//configurable attributes
    @api modalTitle;
    @api lockingActionLabel;
    @api individualPathwayId;
    @api individualAcademicProgressId;
	@api enableDebugMode = false;
	
	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false
	loadedLists = 0;
	
    fieldsValue = {};

	//js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'jquery', 'tooltips'
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
        //set the record id so that it is ready for update
		this.fieldsValue.Id = this.individualAcademicProgressId;
	}
	
    /**
     * @descripton disconnected callback
     */
	disconnectedCallback() {
		
	}

    /**
     * @descripton Get the object info
     */
    @wire(getObjectInfo, {objectApiName: IPR_OBJ})
    iprInfo;
    
    /**
     * @description Return enrollment action status field label
     */
    get enrollmentActionStatusFieldLabel() {

        return this.iprInfo?.data?.fields?.reduivy__Enrollment_Action_Status__c?.label;
    }

    /**
     * @description Modal header label
     */
    get headerLabel() {
        return this.modalTitle;
    }

    /**
     * @description loading label
     */
    get loadingLabel() {
        return customLabels.LOADING_LABEL;
    }

    /**
     * @description cancel label
     */
    get closeButtonLabel() {
        return customLabels.CANCEL_LABEL;
    }

    /**
     * @description save label
     */
    get confirmButtonLabel() {
        return customLabels.CONFIRM_LABEL;
    }

    /**
     * @description Return confirmation text
     */
    get confirmationText() {
        return LOCK_UNLOCK_CONFIRMATION_LABEL.format([this.enrollmentActionStatusFieldLabel, this.lockingActionLabel?.toLowerCase()]);
    }

    /**
     * @description Handle close button click
     */
    handleCloseClick(event) {
        this.close({
            operation: 'cancel',
            individualPathwayId: this.individualPathwayId,
            individualAcademicProgressId: this.individualAcademicProgressId
        });
    }

    handleConfirmClick(event) {
        this.consoleLog(this.fieldsValue, true);

        let recordObj = {
            fields: this.fieldsValue
        };

        try {
            this.toggleSpinner(1);

            updateRecord(recordObj)
            .then(() => {
                promptSuccess(customLabels.SUCCESS_LABEL, customLabels.RECORD_SAVED_LABEL);
                
                //notify lightning data service
                notifyRecordUpdateAvailable([{recordId: this.individualAcademicProgressId}]);

                this.close({
                    operation: 'confirmed',
                    individualPathwayId: this.individualPathwayId,
                    individualAcademicProgressId: this.individualAcademicProgressId
                });

                this.toggleSpinner(-1);
            })
            .catch((error) => {
                this.toggleSpinner(-1);

                this.consoleLog(error);
                promptError(customLabels.ERROR_LABEL, getErrorMessage(error));
            });
        } catch (error) {
            this.toggleSpinner(-1);
            promptError(customLabels.ERROR_LABEL, getErrorMessage(error));
        }
    }

    /**
     * @descripton Spinner loading status
     */
	get isLoading(){
        return this.loadedLists === 0 ? false : true;
    }

    /**
     * @description Handle field change
     */
    handleFieldChange(event) {
        this.fieldsValue[event.target.fieldName] = event.detail.value;
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
        logInfo('IpePathwayLockingModal', anything, this.enableDebugMode, isJson);
    }
	
}