/**
 * @Author 		WDCi (XW)
 * @Date 		May 2024
 * @group 		
 * @Description Result of Program Completion Visualizer Modal in Chatbot
 * @changehistory
 * ISS-001916 20-05-2024 XW - Result of Program Completion Visualizer Modal in Chatbot
 * ISS-002191 12-12-2024 XW - remove default value if field is empty
 * ISS-002375 02-05-2025 xW - add logging
 */
import { LightningElement, api } from 'lwc';
import { promptError } from 'c/toasterUtil';
import { getErrorMessage, logInfo } from 'c/loggingUtil';
import { customLabels } from 'c/labelLoader';

//refresh module
import { refreshApex } from '@salesforce/apex';
import { registerRefreshContainer, unregisterRefreshContainer } from 'lightning/refresh';

//Apex methods
import createPreviewIpe from '@salesforce/apex/REDU_ProgramCompletionVisualizer_LCTRL.createPreviewIpe';
import deletePreviewIpe from '@salesforce/apex/REDU_ProgramCompletionVisualizer_LCTRL.deletePreviewIpe';
import deleteExisitingPreviewIpe from '@salesforce/apex/REDU_ProgramCompletionVisualizer_LCTRL.deleteExisitingPreviewIpe';

export default class ProgramCompletionVisualizer extends LightningElement {

    //configurable attributes
    @api modalTitle;
    @api modalIconName;
    @api enableDebugMode = false;

    //internal attributes
    isScriptLoaded = false;
    isInitSuccess = false;
    loadedLists = 0;

    //refresh Container
    refreshContainerID;

    //labels
    label = customLabels;


    //attribute to check is the user previewing
    @api isPreviewing

    //ids to create preview ipe
    @api contactId;
    @api studyProgramId;
    @api studyPlanId;
    @api previewIpeId;

    //attribute to display ipe
    @api ipsGroupTitleField;
    @api ipsGroupTitleFormat;
    @api ipeInfoFields;
    @api ipeInfoColumnNo; //ISS-002187;
    @api ipsInfoFields; //ISS-002187
    @api ipsInfoFieldsUnit; 
    @api ipsInfoColumnNo;
    @api ipsUnitFields;
    @api idvEnrollmentFields;
    @api showIpsGroupInfo = false;
    
    @api progressRingColor;
    @api progressRingPercentageField;

    @api accordionBackgroundColor;
    @api accordionTextColor;

    @api enableClickableRefField; //ISS-002191
    @api enableSetPrimaryIps; //ISS-002191
    @api enableViewEnrollmentHistory; //ISS-002191
    @api hrefTargetType;
    @api isCommunity = false;


    /**
     * @descripton connected callback and create preview ipe
     */
    connectedCallback() {
        this.refreshContainerID = registerRefreshContainer(this, this.refreshData);
        if (!this.isPreviewing) {
            
            try {


                this.toggleSpinner(1);
      
                //if there are existing ipe, delete the old preview ipe
                deleteExisitingPreviewIpe({
                    contactId: this.contactId
                }).then(() => {

                }).catch(error => {
                    promptError(this.label.ERROR_LABEL, getErrorMessage(error));
                });


                //create the preview ipe and let automation to calculate the progress
                createPreviewIpe({
                    contactId: this.contactId,
                    studyProgramId: this.studyProgramId,
                    studyPlanId: this.studyPlanId
                }).then(result => {
                    let ipeJsonResult = JSON.parse(result.responseData);
                    
                    this.consoleLog('createPreviewIpe - ' + JSON.stringify(ipeJsonResult));
                    this.previewIpeId = ipeJsonResult.Id;
                    this.toggleSpinner(-1);
                    this.dispatchOnIpeGenerated(ipeJsonResult.Id);
                }).catch(error => {
                    promptError(this.label.ERROR_LABEL, getErrorMessage(error));
                    this.toggleSpinner(-1);
                })
            } catch (error) {
                promptError(this.label.ERROR_LABEL, getErrorMessage(error));
                this.toggleSpinner(-1);
            }
        }
    }

    dispatchOnIpeGenerated(previewIpeId){
        this.consoleLog('dispatchOnIpeGenerated - ' + previewIpeId);
        this.dispatchEvent(new CustomEvent("ipegenerated",{
            detail: {
                previewIpeId: previewIpeId
            }
        }));
    }


    /**
     * @descripton disconnected callback and delete the preview ipe
     */
    disconnectedCallback() {
        unregisterRefreshContainer(this.refreshContainerID);
        this. deleteCurrentPreviewIpe();
    }

    /**
     * @description delete the preview ipe displayed in the model
     */
    deleteCurrentPreviewIpe(){
        
        this.toggleSpinner(1);
        this.consoleLog("deleteCurrentPreviewIpe - " + this.previewIpeId);

        //delete the preview ipe
        try {
            deletePreviewIpe({
                ipeId: this.previewIpeId
            }).then(() => {
                this.toggleSpinner(-1);
            }).catch(error => {
                promptError(this.label.ERROR_LABEL, getErrorMessage(error));
                this.toggleSpinner(-1);
            })
        } catch (error) {
            this.toggleSpinner(-1);
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
        }
    }

 


    /**
     * @descripton library loader
     */
    handleLibLoadSuccess() {
        this.isScriptLoaded = true;
        this.isInitSuccess = true;

    }

    /**
     * @descripton library loader
     */
    handleLibLoadFail() {
        this.isScriptLoaded = true;
        this.isInitSuccess = false;
    }


    /**
     * @description Refresh data
     */
    refreshData() {
        this.consoleLog('refreshData');

        refreshApex(this.sampleWireResult);

        return new Promise((resolve) => {
            resolve(true);
        });

    }

    /**
     * @descripton Spinner loading status
     */
    get isLoading() {
        return this.loadedLists === 0 ? false : true;
    }

    /**
     * @descripton Spinner toggler
     */
    toggleSpinner(loadCount) {
        this.loadedLists += loadCount;

        if (this.loadedLists <= 0) {
            this.loadedLists = 0;
        }
    }

    /**
     * @descripton Console log for debugging
     */
    consoleLog(anything, isJson) {
        logInfo('ProgramCompletionVisualizer', anything, this.enableDebugMode, isJson);
    }

}