/**
 * @author      WDCi (Lean)
 * @date        Jun 2024
 * @group       Study Session Scheduler
 * @description Study session scheduler preview modal
 * @changehistory
 * ISS-001920 11-06-2024 Lean - new class
 */
import { api, } from 'lwc';
import LightningModal from 'lightning/modal';
import { logInfo } from 'c/loggingUtil';
import { sessionSchedulerLabels } from 'c/studySessionSchedulerHelper';

export default class StudySessionSchedulerSessionPreviewModal extends LightningModal {
    PREVIEW_FROM_TODAY_VALUE = "today";
    PREVIEW_FROM_DATE_VALUE = "date";
    ALLOCATED_STATUS_UNALLOCATED = "unallocated";
    ALLOCATED_STATUS_ALL = "all";
	
	//configurable attributes
    @api modalTitle;
    @api modalIconName;
	@api enableDebugMode = false;
    @api sseObjId;

	//attributes value
    previewFromValue = this.PREVIEW_FROM_TODAY_VALUE;
    allocatedStatusValue = this.ALLOCATED_STATUS_UNALLOCATED;
    datePreviewFromValue;

	//internal attributes
	loadedLists = 0;

    /**
     * @description Return header label
     */
    get headerLabel() {
        return this.modalTitle;
    }

    /**
     * @description Cancel button
     */
    get cancelButtonLabel() {
        return sessionSchedulerLabels.CANCEL_LABEL;
    }

    /**
     * @description confirm button
     */
    get confirmButtonLabel() {
        return sessionSchedulerLabels.CONFIRM_LABEL;
    }

    /**
     * @description Preview options
     */
    get previewFromOptions(){
        return [
            {label: sessionSchedulerLabels.FROM_TODAY_LABEL, value: this.PREVIEW_FROM_TODAY_VALUE},
            {label: sessionSchedulerLabels.FROM_A_DATE_LABEL, value: this.PREVIEW_FROM_DATE_VALUE}
        ];
    }

    /**
     * @description allocation options
     */
    get allocatedStatusOptions(){
        return [
            {label: sessionSchedulerLabels.PREVIEW_UNALLOCATED_ONLY_LABEL, value: this.ALLOCATED_STATUS_UNALLOCATED},
            {label: sessionSchedulerLabels.PREVIEW_ALL_LABEL, value: this.ALLOCATED_STATUS_ALL}
        ];
    }

    /**
     * @description Is preview from a date
     */
    get isPreviewFromDate(){
        return this.previewFromValue === this.PREVIEW_FROM_DATE_VALUE;
    }

    /**
     * @description Handle preview from date option
     */
    handlePreviewFrom(event) {
        this.previewFromValue = event.detail.value;
    }

    /**
     * @description Handle allocation selection
     */
    handleAllocatedStatus(event) {
        this.allocatedStatusValue = event.detail.value;
    }

    /**
     * @description Handle preview from date selection
     */
    handleDatePreviewFrom(event) {
        this.datePreviewFromValue = event.target.value;
    }

    /**
     * @description Handle cancel
     */
    handleCancelClick(){
        this.close({operation:'cancel'});
    }

    /**
     * @description Handle confirm
     */
    handleConfirmClick(){
        if(!this.validateRequiredDataFields()){
            return;
        }
        let detail = {};
        if(this.previewFromValue === this.PREVIEW_FROM_TODAY_VALUE){
            let gmtDate = new Date();
            let currentDate = new Date(gmtDate.getTime() - (gmtDate.getTimezoneOffset() * 60000));
            detail.date = currentDate.toISOString().slice(0,10);
        }else{
            detail.date = this.datePreviewFromValue;
        }

        
        detail.unallocatedOnly = this.allocatedStatusValue === this.ALLOCATED_STATUS_UNALLOCATED;

        this.close({operation:'submit',eventData:{detail}});
    }
	
    /**
     * @description Validate required fields
     */
    validateRequiredDataFields() {
        let element = [...this.template.querySelectorAll('[data-save-required="true"]')];
        let requiredFieldsValid = element.reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                this.consoleLog('validateRequiredDataFields :: ' + inputCmp.name + ' - ' + inputCmp.value);
                return validSoFar && inputCmp.value;
            }, true);

        return requiredFieldsValid;

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
        logInfo('StudySessionSchedulerSessionPreviewModal', anything, this.enableDebugMode, isJson);
    }
	
}