/**
 * @Author 		WDCi (Lean)
 * @Date 		July 2025
 * @group 		Continuing Education
 * @Description Term and Conditions Modal for continuing education cart
 * @changehistory
 * ISS-002451 31-07-2025 XW - new modal
 */
import { api, } from 'lwc';
import LightningModal from 'lightning/modal';
import { logInfo } from 'c/loggingUtil';

export default class ContinuingEduCartTncModal extends LightningModal {
	
	//configurable attributes
    @api flowName = '';
    @api transactionOrderId;
    
	@api enableDebugMode = false;
	
	//internal attributes
    flowFinishBehavior = 'NONE';
	loadedLists = 0;

    /**
     * @description Flow variables
     */
    get inputVariables() {
        let vars = [
            {
                name: 'transactionOrderId',
                type: 'String',
                value: this.transactionOrderId
            }
        ];

        return vars;
    }

    /**
     * @description Hanlde flow status change
     * @param {@} event 
     */
    handleStatusChange(event) {
        this.consoleLog('handleStatusChange');
        
        if (event.detail.status === 'FINISHED' || event.detail.status === 'FINISHED_SCREEN') {
            if (this.flowFinishBehavior === 'NONE') {
                this.close('finish');
            }
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
        logInfo('ContinuingEduCartTncModal', anything, this.enableDebugMode, isJson);
    }
	
}