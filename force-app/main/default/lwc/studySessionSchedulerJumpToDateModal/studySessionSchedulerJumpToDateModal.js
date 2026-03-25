/**
 * @Author 		WDCi (XW)
 * @Date 		June 2025
 * @group 		Study Session Scheduler
 * @Description Accept jump to date
 * @changehistory
 * ISS-002530 23-06-2025 XW - create new component
 */
import { LightningElement, api, wire, track } from 'lwc';
import LightningModal from 'lightning/modal';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';
import { sessionSchedulerLabels } from 'c/studySessionSchedulerHelper';
import { calendarLabels } from 'c/calendarHelper';


export default class StudySessionSchedulerJumpToDateModal extends LightningModal {
	
	//configurable attributes
	@api enableDebugMode = false;
	
	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false
	loadedLists = 0;
    jumpToDate;
	
	//js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'jquery', 'tooltips'
    modules = [];
    
    /**
     * @description cancel button label
     */
    get cancelButtonLabel(){
        return sessionSchedulerLabels.CANCEL_LABEL;
    }

    /**
     * @description confirm button label
     */
    get confirmButtonLabel() {
        return sessionSchedulerLabels.CONFIRM_LABEL;
    }

    get jumpToDateLabel() {
        return calendarLabels.JUMP_TO_BUTTON_LABEL;
    }

    get loadingLabel() {
        return sessionSchedulerLabels.LOADING_LABEL;
    }

    get headerLabel() {
        return calendarLabels.JUMP_TO_BUTTON_LABEL;
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
     * @description handle jump to date
     */
    handleJumpToDate(event) {
        this.jumpToDate = event.target.value;
        this.consoleLog('jump to date: ' + this.jumpToDate);
    }
	
    /**
     * @description Handle cancel
     */
    handleCancelClick(){
        this.close({operation:'cancel'});
    }

    /**
     * @description handle confirm
     */
    handleConfirmClick() {
        this.close({
            operation: 'submit', 
            eventData: this.jumpToDate
        })
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
        logInfo('StudySessionSchedulerJumpToDateModal', anything, this.enableDebugMode, isJson);
    }
	
}