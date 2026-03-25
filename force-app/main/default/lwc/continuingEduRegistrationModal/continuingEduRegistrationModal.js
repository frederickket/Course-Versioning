/**
 * @Author 		WDCi (Jordan)
 * @Date 		Feb 2024
 * @group 		Continuing Education
 * @Description Registration modal
 * @changehistory
 * ISS-001846 21-02-2024 Jordan - new lwc
 */
import { LightningElement, api, wire, track } from 'lwc';
import LightningModal from 'lightning/modal';
import { promptInfo, promptError, promptWarning, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';

import LOADING_LABEL from '@salesforce/label/c.Loading';

export default class ContinuingEduRegistrationModal extends LightningModal {
	
	//configurable attributes
    @api guestRegistrationText;
    @api nonGuestRegistrationText;
    @api guestRegistrationButtonLabel;
    @api nonGuestRegistrationButtonLabel;
    @api allowGuestRegistrations;
    @api recordName;

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
     * @description Return modal title
     */
    get headerLabel() {
        return this.recordName;
    }

    /**
     * @description Return loading label
     */
    get loadingLabel() {
        return LOADING_LABEL;
    }

    closeModal() {
        this.close({
            operation: 'cancel'
        });
    }
    
    handleLogin() {
        this.close({
            operation: 'loginAsUser'
        });
    }

    handleRegisterEvent() {
        this.close({
            operation: 'continueAsGuest'
        });
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
        logInfo('continuingEduRegistrationModal', anything, this.enableDebugMode, isJson);
    }
	
}