/**
 * @Author 		WDCi (Lean)
 * @Date 		Oct 2023
 * @group 		Enrollment Wizard
 * @Description Student enrollment wizard
 * @changehistory
 * ISS-001752 05-10-2022 Lean - new component
 * ISS-002009 16-07-2024 Sueanne - update sofId getter
 */
import { LightningElement, api, wire, track } from 'lwc';
import LightningModal from 'lightning/modal';
import { promptInfo, promptError, promptWarning, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';

import CLOSE_LABEL from '@salesforce/label/c.Close';
import LOADING_LABEL from '@salesforce/label/c.Loading';

export default class UnitInfoModal extends LightningModal {
	
	//configurable attributes
    @api modalTitle;
    @api ipsRecord;
    @api studyUnitFields;
    @api studyOfferingFields;
    @api studyPlanStructureUnitFields;
	@api enableDebugMode = false;
	
	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false;
	loadedLists = 0;
		
	//js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'tooltips'
    modules = [];
	
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
		this.consoleLog(this.studyUnitFields);
        this.consoleLog(this.studyOfferingFields);
        this.consoleLog(this.studyPlanStructureUnitFields);
	}
	
    /**
     * @descripton disconnected callback
     */
	disconnectedCallback() {
		
	}

    /**
     * @description Return modal title
     */
    get headerLabel() {
        return this.modalTitle;
    }

    /**
     * @description Return loading label
     */
    get loadingLabel() {
        return LOADING_LABEL;
    }

    /**
     * @description Return close label
     */
    get closeButtonLabel() {
        return CLOSE_LABEL;
    }

    /**
     * @description Return true if sunId and sunFields are not blank
     */
    get showStudyUnitInfo() {
        if (this.sunId && this.sunFields) {
            return true;
        }

        return false;
    }

    /**
     * @description Return true if sofId and sofFields are not blank
     */
    get showStudyOfferingInfo() {
        if (this.sofId && this.sofFields) {
            return true;
        }

        return false;
    }

    /**
     * @description Return true if spsUnitId and spsUnitFields are not blank
     */
    get showStudyPlanStructureUnitInfo() {
        if (this.spsUnitId && this.spsUnitFields) {
            return true;
        }

        return false;
    }

    /**
     * @description Return study unit id
     */
    get sunId() {
        if (this.ipsRecord && this.ipsRecord.sun) {
            return this.ipsRecord.sun.Id;
        }

        return null;
    }

    /**
     * @description Return study offering id
     */
    get sofId() {
        let recordId;
        if (this.ipsRecord && this.ipsRecord?.sof) {
            recordId = this.ipsRecord.sof.Id;
        }else if(this.ipsRecord?.ips?.reduivy__Individual_Enrollment__r?.reduivy__Study_Offering__c){
            recordId = this.ipsRecord.ips.reduivy__Individual_Enrollment__r.reduivy__Study_Offering__c;
        }

        return recordId;
    }

    /**
     * @description Return study plan structure unit id
     */
    get spsUnitId() {
        if (this.ipsRecord && this.ipsRecord.sps) {
            return this.ipsRecord.sps.Id;
        }

        return null;
    }

    /**
     * @description Return study unit fields
     */
    get sunFields() {
        if (this.studyUnitFields) {
            return this.studyUnitFields.split(';');
        }

        return null;
    }

    /**
     * @description Return study offering fields
     */
    get sofFields() {
        if (this.studyOfferingFields) {
            return this.studyOfferingFields.split(';');
        }

        return null;
    }

    /**
     * @description Return study plan structure unit fields
     */
    get spsUnitFields() {
        if (this.studyPlanStructureUnitFields) {
            return this.studyPlanStructureUnitFields.split(';');
        }

        return null;
    }

    /**
     * @description Handle close click
     */
    handleCloseClick() {
        this.close({operation: 'close'});
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
        logInfo('unitInfoModal', anything, this.enableDebugMode, isJson);
    }
	
}