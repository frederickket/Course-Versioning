/**
 * @Author 		WDCi (Jordan)
 * @Date 		Dec 2024
 * @group 		Contact
 * @Description Contact profile picture wizard
 * @changehistory
 * ISS-002196 04-12-2024 Jordan - new component
 * ISS-002727 17-11-2025 Lean - Fixed label
 * ISS-002594 17-11-2025 Lean - Moved the upload profile text to bottom
 */
import { LightningElement, api, wire } from 'lwc';
import { promptError, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo } from 'c/loggingUtil';
import { initCacheIdx } from 'c/lwcUtil';
import { customLabels } from 'c/labelLoader';

//refresh module
import { refreshApex } from '@salesforce/apex';

//Apex methods
import getProfilePicture from '@salesforce/apex/REDU_ContactProfilePanel_LCTRL.getProfilePicture';
import updateProfilePicture from '@salesforce/apex/REDU_ContactProfilePanel_LCTRL.updateProfilePicture';
import deleteProfilePicture from '@salesforce/apex/REDU_ContactProfilePanel_LCTRL.deleteProfilePicture';

import PROFILE_PICTURE_UPLOADED_LABEL from '@salesforce/label/c.The_Profile_Picture_Was_Uploaded';
import PROFILE_PICTURE_DELETED_LABEL from '@salesforce/label/c.The_Profile_Picture_Was_Deleted';
import CLICK_TO_UPLOAD_NEW_LABEL from '@salesforce/label/c.Click_To_Upload_New_Profile_Picture';

export default class ContactProfilePanel extends LightningElement {
	
    @api recordId;

	//configurable attributes
    @api fileCategory;
    @api allowedFileTypes;
    @api noImageMessage;
	@api enableDebugMode = false;
	
	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false
	loadedLists = 0;
    showButtons = false;
    imageUrl;
	
    //local cache idx to force rerendering
    _cacheIdx;

    //wire attribute
    profilePictureWireResult;
    profilePictureResponse;

	//labels
	label = {
        PROFILE_PICTURE_UPLOADED_LABEL,
        PROFILE_PICTURE_DELETED_LABEL,
        ...customLabels
    };
	
	//js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'jquery'
    modules = [];
	
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
     * @descripton rendered callback
     */
	renderedCallback(){

    }

    /**
     * @descripton connected callback
     */
    connectedCallback(){
        this._cacheIdx = initCacheIdx();
	}
	
    /**
     * @descripton disconnected callback
     */
	disconnectedCallback() {

	}

    /**
     * @description Refresh data
     */
    refreshData() {
        this.consoleLog('refreshData');

        this._cacheIdx = initCacheIdx();

        refreshApex(this.profilePictureWireResult);

        return new Promise((resolve) => {
            resolve(true);
        });

    }

    /**
     * @description Get profile picture wrapper
     */
    @wire(getProfilePicture, {
        cacheIdx: "$_cacheIdx",
        recordId: "$recordId",
        fileCategory: "$fileCategory"
    })
    wireProfilePicture(result) {
        
        this.profilePictureWireResult = result;
        this.profilePictureResponse = null;

        if (result.data) {
            this.profilePictureResponse = JSON.parse(result.data.responseData);
            this.imageUrl = this.profilePictureResponse.imageUrl;
            this.consoleLog(this.profilePictureResponse, true);
        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }

    }

    /**
     * @description Return click to upload new profile message
     */
    get clickToUploadNewProfileMsg() {
        return CLICK_TO_UPLOAD_NEW_LABEL;
    }

    /**
     * @description Show uploader
     */
    showHideButtons() {
        this.showButtons = !this.showButtons;
    }

    /**
     * @description Handle upload finished
     */
    handleUploadFinished(event) {
        const files = event.detail.files;

        if (files.length > 0) {
            let fileDocumentId = files[0].documentId;

            this.toggleSpinner(1);

            try {
                updateProfilePicture({
                    documentId: fileDocumentId,
                    fileCategory: this.fileCategory
                })
                .then(() => {
                    this.toggleSpinner(-1);
                    this.showButtons = false;
                    promptSuccess(this.label.SUCCESS_LABEL, this.label.PROFILE_PICTURE_UPLOADED_LABEL);

                    this.refreshData();
                })
                .catch(error => {
                    promptError(this.label.ERROR_LABEL, getErrorMessage(error));
                    this.toggleSpinner(-1);
                });

            } catch (error) {
                this.toggleSpinner(-1);
                promptError(this.label.ERROR_LABEL, getErrorMessage(error));
            }
        }
    }

    /**
     * @description Handle button menu action
     */
    handleButtonMenuAction(event) {
        let selectedMenu = event.detail.value;

        if (selectedMenu === "remove") {
            this.doRemoveFile();
        } else if (selectedMenu === "close") {
            this.showHideButtons();
        }
    }

    /**
     * @description Handle remove file
     */
    doRemoveFile() {
        this.toggleSpinner(1);

        try {
            deleteProfilePicture({
                recordId: this.recordId,
                fileCategory: this.fileCategory
            })
            .then(() => {
                this.toggleSpinner(-1);
                promptSuccess(this.label.SUCCESS_LABEL, this.label.PROFILE_PICTURE_DELETED_LABEL);

                this.refreshData();
            })
            .catch(error => {
                promptError(this.label.ERROR_LABEL, getErrorMessage(error));
                this.toggleSpinner(-1);
            });

        } catch (error) {
            this.toggleSpinner(-1);
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
        }
    }
	
    /**
     * @descripton Spinner loading status
     */
	get isLoading(){
        return this.loadedLists === 0 ? false : true;
    }

    /**
     * @description Is file uploader visible
     */
    get buttonsVisible(){
        return this.showButtons || !this.imageUrl;
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
        logInfo('ContactProfilePanel', anything, this.enableDebugMode, isJson);
    }
	
}