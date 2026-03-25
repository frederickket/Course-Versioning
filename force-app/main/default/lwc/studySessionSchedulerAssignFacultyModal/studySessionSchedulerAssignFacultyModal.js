/**
 * @Author 		WDCi (XW)
 * @Date 		Jan 2024
 * @group 		Study Session Scheduler
 * @Description 
 * @changehistory
 * ISS-001920 05-08-2024 XW - create new class
 */

import LightningModal from 'lightning/modal';
import { api } from 'lwc';
import { logInfo } from 'c/loggingUtil';
import { sessionSchedulerLabels } from 'c/studySessionSchedulerHelper';

export default class StudySessionSchedulerAssignFacultyModal extends LightningModal {
	
	//configurable attributes
    @api modalTitle;
    @api modalIconName;
	@api enableDebugMode = false;

    @api sseObj;
    showHeader = false;

    //internal attributes
	loadedLists = 0;

    /**
     * @description Title
     */
    get headerLabel() {
        return this.modalTitle;
    }

    /**
     * @descrpition Save button
     */
    get saveButtonLabel() {
        return sessionSchedulerLabels.SAVE_LABEL;
    }

    /**
     * @description Close button
     */
    get closeButtonLabel() {
        return sessionSchedulerLabels.CLOSE_LABEL;
    }

    /**
     * @description Handle save
     */
    handleSave(){
        this.template.querySelector('c-study-session-scheduler-faculty-assignment').handleSave();
    }

    /**
     * @description Handle close
     */
    handleClose(){
        this.close({operation:'cancel'});
    }
	
    /**
     * @description Handle after faculty assignment 
     */
    handleFacultyAssigned(event){
        this.close({operation: 'submit', eventData: event.detail.recordIds});
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
        logInfo('StudySessionSchedulerAssignFacultyModal', anything, this.enableDebugMode, isJson);
    }
	
}