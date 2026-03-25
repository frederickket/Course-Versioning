/**
 * @Author 		WDCi (Lean)
 * @Date 		June 2024
 * @group 		Study Session Scheduler
 * @Description Study session scheduler custom action modal
 * @changehistory
 * ISS-001920 10-06-2024 Lean - new modal
 */
import { api, } from 'lwc';
import LightningModal from 'lightning/modal';
import { logInfo } from 'c/loggingUtil';
import { customLabels } from 'c/labelLoader';

export default class StudySessionSchedulerCustomActionModal extends LightningModal {
	
	//configurable attributes
    @api modalTitle;
    @api flowName = '';
    @api flowFinishBehavior = 'NONE';
    @api showCloseButton = false;
    @api studySessionId;
    @api schedulerStartDate;
    @api schedulerEndDate;

	@api enableDebugMode = false;
	
	//internal attributes
	loadedLists = 0;
		
    /**
     * @descripton rendered callback
     */
	renderedCallback(){

    }

    /**
     * @descripton connected callback
     */
    connectedCallback(){

	}
	
    /**
     * @descripton disconnected callback
     */
	disconnectedCallback() {

	}
    
    /**
     * @description Close button
     */
    get closeButtonLabel() {
        return customLabels.CLOSE_LABEL;
    }

    /**
     * @description Title
     */
    get headerLabel() {
        return this.modalTitle;
    }

    /**
     * @description Flow variables
     */
    get inputVariables() {
        let vars = [
            {
                name: 'studySessionId',
                type: 'String',
                value: this.studySessionId
            },
            {
                name: 'schedulerStartDate',
                type: 'DateTime',
                value: this.schedulerStartDate
            },
            {
                name: 'schedulerEndDate',
                type: 'DateTime',
                value: this.schedulerEndDate
            },
        ];

        return vars;
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
        logInfo('StudySessionSchedulerCustomActionModal', anything, this.enableDebugMode, isJson);
    }
	
}