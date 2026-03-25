/**
 * @Author 		WDCi (XW)
 * @Date 		May 2024
 * @group 		
 * @Description Program Completion Visualizer Modal for Chatbot
 * @changehistory
 * ISS-001916 20-05-2024 name - Program Completion Visualizer Modal for Chatbot
 * ISS-001984 27-06-2024 XW - Fixed a bug that the delete Preview IPE method will be called twice
 * ISS-002375 02-05-2025 xW - add logging
 */
import { LightningElement, api, wire, track } from 'lwc';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';
import LightningModal from 'lightning/modal';


export default class ChatbotProgramCompletionVisualizerModal extends LightningModal {

    //configurable attributes ISS-002187
    @api modalTitle;
    @api modalIconName;
    @api enableDebugMode = false;


    @api contactId;
    @api studyProgramId;
    @api studyPlanId;
    @api ipeIdsBefore;

    @api showIpsGroupInfo = false;
    @api ipsGroupTitleField;
    @api ipsGroupTitleFormat;
    @api ipeInfoFields;
    @api ipeInfoColumnNo;
    @api ipsInfoFields;
    @api ipsInfoFieldsUnit; 
    @api ipsInfoColumnNo;
    @api ipsUnitFields;
    @api idvEnrollmentFields;
    @api accordionBackgroundColor;
    @api accordionTextColor;
    @api enableClickableRefField = false;
    @api enableSetPrimaryIps = false;
    @api enableViewEnrollmentHistory = false;
    @api hrefTargetType;
    @api isCommunity = false;

    @api progressRingColor;
    @api progressRingPercentageField;

    @api summaryInfoField;

    //ISS-002187
    get summaryInfoFieldList() {
        if(!this.summaryInfoField){
            return [];
        }
        return this.summaryInfoField.split(";");
    }

    //ISS-002187
    get showCompareIpe() {
        return this.summaryInfoFieldList.length;
    }

    //ISS-002187
    get ipeLargeSize() {
        return this.showIpeToCompare ? 3 : 5;
    }

    //ISS-002187
    get showModalHeader(){
        if(this.modalTitle){
            return true;
        }
        return false;
    }

    ipeIdSelectedToCompare;

    get ipeIdBefore() {
        return this.ipeIdSelectedToCompare;
    }

    ipeIdAfter;

    get ipeAfterIsLoading() {
        return !this.ipeIdAfter;
    }

    handleClose(event) {
        this.consoleLog('close');
        this.close({ operation: 'close' });
        //ISS-001984
    }
    
    get showIpeToCompare(){
        return this.ipeIdsBefore.length > 1;
    }
    
    connectedCallback() {
        this.consoleLog('connectedCallback');
        this.ipeIdSelectedToCompare = this.ipeIdsBefore[0].value;
    }
    
    handleIpeToCompare(event){
        if(event.detail.selectedOpt){
            this.ipeIdSelectedToCompare = event.detail.selectedOpt.value;
            this.consoleLog('handleIpeToCompare - ' + event.detail.selectedOpt.value);
        }
    }
    
    handleIpeAfter(event) {
        this.ipeIdAfter = event.detail.previewIpeId;
        this.consoleLog('handleIpeAfter - ' + event.detail.previewIpeId);
    }


    /**
     * @descripton Console log for debugging
     */
    consoleLog(anything, isJson) {
        logInfo('ChatbotProgramCompletionVisualizerModal', anything, this.enableDebugMode, isJson);
    }

}