/**
 * @Author 		WDCi (Lean)
 * @Date 		June 2025
 * @group 		Enrollment Wizard
 * @Description The enrollment finalization modal
 * @changehistory
 * ISS-002493 10-06-2025 Lean - new modal
 */
import { api } from 'lwc';
import LightningModal from 'lightning/modal';

import { logInfo } from 'c/loggingUtil';
import { customLabels } from 'c/labelLoader';

export default class IpePathwayEnrollmentFinalizeModal extends LightningModal {
	
	//configurable attributes
    @api modalTitle;
    @api flowName;
    
    @api individualAcademicProgressId;
    @api individualPathwayId;
    @api masterIpeId;
    @api individualEnrollmentIds;
    
	@api enableDebugMode = false;
	
	//internal attributes
    flowFinishBehavior = 'NONE';
    showCloseButton = false;

	isScriptLoaded = false;
	isInitSuccess = false
	loadedLists = 0;

	//js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'jquery', 'tooltips'
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

        this.consoleLog('individualAcademicProgressId ' + this.individualAcademicProgressId);
        this.consoleLog('individualPathwayId ' + this.individualPathwayId);
        this.consoleLog('masterIpeId ' + this.masterIpeId);
        this.consoleLog('individualEnrollmentIds ' + this.individualEnrollmentIds);
	}
	
    /**
     * @descripton disconnected callback
     */
	disconnectedCallback() {
		
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
     * @description Close button
     */
    get closeButtonLabel() {
        return customLabels.CLOSE_LABEL;
    }

    /**
     * @description Flow variables
     */
    get inputVariables() {
        let vars = [
            {
                name: 'individualAcademicProgressId',
                type: 'String',
                value: this.individualAcademicProgressId
            },
            {
                name: 'individualPathwayId',
                type: 'String',
                value: this.individualPathwayId
            },
            {
                name: 'masterIpeId',
                type: 'String',
                value: this.masterIpeId
            },
            {
                name: 'individualEnrollmentIds',
                type: 'String',
                value: this.individualEnrollmentIds
            }
        ];

        return vars;
    }

    /**
     * @description Indicates that the wire method is returned
     */
    get canRenderFlow() {

        if (this.flowName) {
            return true;
        }

        return false;
    }

    /**
     * @description Hanlde flow status change
     * @param {@} event 
     */
    handleStatusChange(event) {
        
        if (event.detail.status === 'FINISHED' || event.detail.status === 'FINISHED_SCREEN') {
            if (this.flowFinishBehavior === 'NONE') {
                this.close('finish');
            }
        }
    }

    /**
     * @description handle close
     */
    handleClose() {
        this.close('close');
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
        logInfo('IpePathwayEnrollmentFinalizeModal', anything, this.enableDebugMode, isJson);
    }
	
}