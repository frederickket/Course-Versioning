/**
 * @Author 		WDCi (XW)
 * @Date 		June 2025
 * @group 		Requirement Checklist
 * @Description Requirement Checklist File Uploader component
 * @changehistory
 * ISS-002128 12-06-2025 XW - new class
 */
import { LightningElement, api, wire, track } from 'lwc';
import { promptInfo, promptError, promptWarning, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';
import { initCacheIdx } from 'c/lwcUtil';
import { customLabels } from 'c/labelLoader';
import LightningModal from 'lightning/modal';

//refresh module
import { refreshApex } from '@salesforce/apex';

//Apex methods
import ctrlGetExistingUploadedFiles from '@salesforce/apex/REDU_RequirementChecklistFile_LCTRL.getExistingUploadedFiles';
import ctrlUpdateUploadedFiles from '@salesforce/apex/REDU_RequirementChecklistFile_LCTRL.updateUploadedFiles';
import ctrlShareUploadedFiles from '@salesforce/apex/REDU_RequirementChecklistFile_LCTRL.shareUploadedFiles';
import ctrlLinkUploadedFiles from '@salesforce/apex/REDU_RequirementChecklistFile_LCTRL.linkUploadedFiles';


import SAVE_AND_MARK_AS_DONE_LABEL from '@salesforce/label/c.Save_And_Mark_As_Done';
import NUMBER_OF_FILES_LABEL from '@salesforce/label/c.Requirement_Checklist_Number_of_Files_Required';
import UPLOADED_FILES_LABEL from '@salesforce/label/c.Requirement_Checklist_Uploaded_Files';


export default class RequirementChecklistFileModal extends LightningModal {
	
	//configurable attributes
    @api headerLabel;
    @api parentId;
    @api set irq(value) {
        this._irq = JSON.parse(JSON.stringify(value));
        if(!this._irq?.reduivy__File_Count__c) {
            this._irq.reduivy__File_Count__c = 1;
        }
    }

    get irq(){
        return this._irq;
    }

	@api enableDebugMode = false;
	
	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false;
	loadedLists = 0;
    _irq;
    uploadedFiles;

    //wire attribute
    existingUploadedFilesResult;
    existingUploadedFilesResponse;
	
	//js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'jquery', 'tooltips'
    modules = ['stringutil'];
	
    /**
     * @description loading label
     */
    get loadingLabel() {
        return customLabels.LOADING_LABEL;
    }
	
    /**
     * @description save and mark as done label on button
     */
    get saveAndMarkAsDoneLabel() {
        return SAVE_AND_MARK_AS_DONE_LABEL;
    }

    /**
     * @description save label on button
     */
    get saveLabel() {
        return customLabels.SAVE_LABEL;
    }

    /**
    * @description close label
    */
    get closeLabel() {
        return customLabels.CLOSE_LABEL;
    }

    /**
     * @description return true if the files uploaded have sufficient
     */
    get hasSufficientFiles() {
        if(this.irq?.reduivy__File_Count__c && this.existingUploadedFiles) {
            return this.existingUploadedFiles.length >= this.irq?.reduivy__File_Count__c;
        }
        return false;
    }

    /**
     * @description return true if mark as done should be disabled
     */
    get disableMarkAsDone() {
        return !this.hasSufficientFiles;
    }

    /**
     * @description The ids of the uploaded content documents
     */
    get uploadedDocumentIds() {
        if (this.uploadedFiles) {
            let cdIds = [];

            for (let uf of this.uploadedFiles) {
                cdIds.push(uf.documentId);
            }

            return cdIds;
        }

        return [];
    }

    /**
     * @description get uploaded files
     * @param cacheIdx This is to force the wire method to get new data from apex, you don't need to have the variable declare in the apex. Please remove if you don't need it.
     */
    @wire(ctrlGetExistingUploadedFiles, {
        recordId: "$irq.Id",
        cacheIdx: '$_cacheIdx'
    })
    wireGetExistingUploadedFiles(result) {
        
        this.existingUploadedFilesResult = result;
        this.existingUploadedFilesResponse = null;

        if (result.data) {
            this.existingUploadedFilesResponse = JSON.parse(result.data.responseData);
            this.consoleLog(this.existingUploadedFilesResponse, true);
        } else if (result.error) {
            promptError(customLabels.ERROR_LABEL, getErrorMessage(result.error));
        }

    }

    /**
     * @description the existing uploaded files of the individual requirement record
     */
    get existingUploadedFiles() {
        if(this.existingUploadedFilesResponse) {
            return this.existingUploadedFilesResponse;
        }
        return [];
    }

    /**
     * @description handle when files are uploaded. Update the file category, sharetype & visible, and create linkage to the parent record
     */
    async handleUploadFinished(event) {
        this.uploadedFiles = event.detail.files;
        this.consoleLog('handleUploadFinished');
        this.consoleLog(this.uploadedFiles, true);
        await this.updateUploadedFiles();
        await this.shareUploadedFiles();
        await this.linkUploadedFiles();

        refreshApex(this.existingUploadedFilesResult);
    }

    /**
     * @description update the file catagory of the uploaded documents
     */
    async updateUploadedFiles() {
        let documentIds = this.uploadedDocumentIds;
        
        if (documentIds) {
            this.toggleSpinner(1);
            try{
                await ctrlUpdateUploadedFiles({fileCategory: this.irq.reduivy__File_Category__c, contentDocumentIds: documentIds});
                this.toggleSpinner(-1);
            } catch(error) {
                this.toggleSpinner(-1);
                promptError(customLabels.ERROR_LABEL, getErrorMessage(error));
            }
        }
    }

    /**
     * @description update the sharetype and visibility of the uploaded documents
     */
    async shareUploadedFiles() {
        let documentIds = this.uploadedDocumentIds;
        
        if (documentIds) {
            this.toggleSpinner(1);
            try{
                await ctrlShareUploadedFiles({
                    requirementId: this.irq.Id,
                    fileShareType: this.irq.reduivy__File_Share_Type__c,
                    fileVisibility:this.irq.reduivy__File_Visibility__c,
                    contentDocumentIds: documentIds
                });
                this.toggleSpinner(-1);
            } catch(error) {
                this.toggleSpinner(-1);
                promptError(customLabels.ERROR_LABEL, getErrorMessage(error));
            }
        }
    }

    /**
     * @description create linkage to the parent record
     */
    async linkUploadedFiles() {
        let documentIds = this.uploadedDocumentIds;
        
        if (documentIds) {
            this.toggleSpinner(1);
            try{
                await ctrlLinkUploadedFiles({
                    parentId: this.parentId,
                    fileShareType: this.irq.reduivy__File_Share_Type__c,
                    fileVisibility:this.irq.reduivy__File_Visibility__c,
                    contentDocumentIds: documentIds
                });
                this.toggleSpinner(-1);
            } catch(error) {
                this.toggleSpinner(-1);
                promptError(customLabels.ERROR_LABEL, getErrorMessage(error));
            }
        }
    }

    /**
     * @description number of files text displayed on the modal
     */
    get numberOfFilesLabel() {
        return NUMBER_OF_FILES_LABEL.format([this.irq.reduivy__File_Count__c ? this.irq.reduivy__File_Count__c : 0]);
    }

    /**
     * @description uploaded files name displayed on the modal
     */
    get uploadedFilesLabel() {
        if(this.existingUploadedFiles && this.existingUploadedFiles.length > 0) {
            
            let uploadedFilesNameList = [];
            for(let file of this.existingUploadedFiles) {
                uploadedFilesNameList.push(file.Title + '.' + file.FileExtension);
            }

            return UPLOADED_FILES_LABEL.format([uploadedFilesNameList.join(', ')]);
        }
        return '';
    }

    /**
     * @description close the modal
     */
    handleSaveClick() {
        this.close({
            operation: 'save',
            eventSource: 'cancel',
            eventData: this.irq
        });
    }

    /**
     * @description close and modal and updated the submitted field after closing it
     */
    handleSaveAndDoneClick() {
        this.close({
            operation: 'save',
            eventSource: 'submit',
            eventData: this.irq
        });
    }

    /**
     * @description handle close click
     */
    handleCloseClick() {
        this.close({
            operation: 'cancel'
        });
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
     * @descripton connected callback
     */
    connectedCallback(){
        this._cacheIdx = initCacheIdx();
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
        logInfo('RequirementChecklistFileModal', anything, this.enableDebugMode, isJson);
    }
	
}