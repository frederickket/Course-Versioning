/**
 * @Author 		WDCi (Lean)
 * @Date 		Aug 2024
 * @group 		Utility
 * @Description Record info tile
 * @changehistory
 * ISS-001919 08-08-2024 Lean - new tile
 * ISS-002050 17-09-2024 Sueanne - update to support show field label, added icon size
 */
import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { promptInfo, promptError, promptWarning, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';
import { getColumnSize } from 'c/lwcUtil';
import { customLabels } from 'c/labelLoader';

import { getRecord, getFieldValue } from "lightning/uiRecordApi";

import recordInfoModal from 'c/recordInfoModal';

//refresh module
import { refreshApex } from '@salesforce/apex';
import { RefreshEvent, registerRefreshHandler, unregisterRefreshHandler } from 'lightning/refresh';

import ctrlGetRecordAvatarFileUrl from '@salesforce/apex/REDU_RecordInfoTile_LCTRL.getRecordAvatarFileUrl';

export default class RecordInfoTile extends NavigationMixin(LightningElement) {
	
	//configurable attributes
    @api recordId;
    @api recordTitleFieldName;
    @api recordInfoFields;
    @api recordColor;
    @api objectApiName;
    @api recordIconName;
    @api recordImageFileName;
    @api recordImageUrlFieldName;
    @api recordImageUrl;
    @api showFieldLabel;
    @api recordIconSize = 'medium';
    @api recordTitleHeadingSize;
    @api recordInfoColumnNo;

    @api recordInfoModalRecord1InfoFields;
    @api recordInfoModalSection1Name;

    @api recordInfoModalRecord2Id;
    @api recordInfoModalRecord2ObjectName;
    @api recordInfoModalRecord2InfoFields;
    @api recordInfoModalSection2Name;

    @api recordInfoModalRecord3Id;
    @api recordInfoModalRecord3ObjectName;
    @api recordInfoModalRecord3InfoFields;
    @api recordInfoModalSection3Name;

    @api recordTitleClickAction; //support View Info and View Record

	@api enableDebugMode = false;
	
	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false
	loadedLists = 0;
	
    //refresh handler
    refreshHandlerID;

    //wire attribute
    recordWireResult;
    recordResponse;
    recordAvatarFileUrlWireResult;
    recordAvatarFileUrlResponse;

	//labels
	label = customLabels;
	
	//js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'tooltips'
    modules = [];
	
	/**
     * @descripton library loader
     */
    handleLibLoadSuccess(event) {
        this.isScriptLoaded = true;
        this.isInitSuccess = true;

        this.updateCssVars();
        
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
		this.refreshHandlerID = registerRefreshHandler(this, this.refreshData);

        this.consoleLog('recordId :: ' + this.recordId);
        this.consoleLog('objectApiName :: ' + this.objectApiName);
	}
	
    /**
     * @descripton disconnected callback
     */
	disconnectedCallback() {
		unregisterRefreshHandler(this.refreshHandlerID);
	}

    /**
     * @description Refresh data
     */
    refreshData() {
        this.consoleLog('refreshData');

        refreshApex(this.recordWireResult);
        refreshApex(this.recordAvatarFileUrlWireResult);

        return new Promise((resolve) => {
            resolve(true);
        });

    }

    /**
     * @description Update css var
     */
    updateCssVars() {
        let css = this.template.host.style;
        css.setProperty('--tile-bar-color', this.recordColor);
    }

    /**
     * @description Return fields for query
     */
    get fieldsForQuery() {
        if (this.objectApiName && this.recordTitleFieldName) {
            let fields = [this.objectApiName + '.Id'];
            fields.push(this.objectApiName + '.' + this.recordTitleFieldName);

            //file url field is defined, we may want to query the profile url field too if provided
            if (this.recordImageUrlFieldName) {
                fields.push(this.objectApiName + '.' + this.recordImageUrlFieldName);
            }

            return fields;
        }

        return [];
    }

    /**
     * @description Record info fields array
     */
    get tileInfoFields() {
        if (this.recordInfoFields) {
            return this.recordInfoFields.split(';');
        }

        return [];
    }

    /**
     * @description Return true if the title has action set
     */
    get isTitleClickable() {

        if (!this.recordTitleClickAction || this.recordTitleClickAction === 'None') {
            return false;
        }

        return true;
    }
    /**
     * @description Title button css class
     */
    get tileTitleButtonCssClass() {
        if (this.isTitleClickable) {
            return 'truncate-button clickable-title slds-button';
        }

        return 'truncate-button non-clickable-title slds-button';
    }

    /**
     * @description Title heading css class
     */
    get tiileTitleHeadingCssClass() {
        let titleCss = 'slds-truncate ';

        if (this.recordTitleHeadingSize) {
            if (this.recordTitleHeadingSize.toLowerCase() === 'large') {
                titleCss += 'slds-text-heading_large';
            } else if (this.recordTitleHeadingSize.toLowerCase() === 'medium') {
                titleCss += 'slds-text-heading_medium';
            } else if (this.recordTitleHeadingSize.toLowerCase() === 'small') {
                titleCss += 'slds-text-heading_small';
            }
        }
        
        return titleCss;
    }

    /**
     * @description Return true if to show object avatar
     */
    get showRecordAvatar() {
        if (this.recordImageFileName || this.recordImageUrlFieldName || this.recordImageUrl) {
            return true;
        }

        return false;
    }

    /**
     * @description Return the object avatar source url
     */
    get recordAvatarSrc() {
        if (this.recordImageUrl) {
            return this.recordImageUrl;
            
        } else if(this.recordImageUrlFieldName) {
            if (this.recordResponse) {
                return this.recordResponse?.fields[this.recordImageUrlFieldName]?.value;
            }
        } else if (this.recordImageFileName) {
            return this.recordAvatarFileUrlResponse;
        }

        return null;
    }

    /**
     * @description Get record tile title value
     */
    get tileTitle() {
        if (this.recordTitleFieldName && this.recordResponse) {
            return getFieldValue(this.recordResponse, this.objectApiName + '.' + this.recordTitleFieldName);
        }

        return '';
    }

    /**
     * @description Return the layout item size for record info
     */
    get recordInfoFieldSize() {
        return getColumnSize(this.recordInfoColumnNo, 6);
    }

    /**
     * @description Get current individual plan structure Group record
     */
    @wire(getRecord, { recordId: "$recordId", fields: "$fieldsForQuery" })
    wiredRecord(result) {
        
        this.recordWireResult = result;

        if (result.data) {
            this.recordResponse = result.data;
            this.consoleLog(this.recordResponse, true);
            
        } else if (result.error) {
            this.recordResponse = null;
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }

    }

    /**
     * @description Get fields from field set
     */
    @wire(ctrlGetRecordAvatarFileUrl, {
        recordId: '$recordId',
        recordImageFileName: '$recordImageFileName'
    })
    wiredSerFields(result) {
        this.recordAvatarFileUrlWireResult = result;
        this.recordAvatarFileUrlResponse = null;

        if (result.data) {
            this.recordAvatarFileUrlResponse = result.data.responseData; //this is string, no JSON parse is required

            this.consoleLog(this.recordAvatarFileUrlResponse, true);

        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    handleRecordTitleClick(){
        if (this.recordTitleClickAction === 'View Info') {

            recordInfoModal.open({
                size: 'small',
                modalTitle: this.label.INFO_LABEL,
                recordInfoModalRecord1Id: this.recordId,
                recordInfoModalRecord1ObjectName: this.objectApiName,
                recordInfoModalRecord1InfoFields: this.recordInfoModalRecord1InfoFields,
                recordInfoModalSection1Name: this.recordInfoModalSection1Name,
                recordInfoModalRecord2Id: this.recordInfoModalRecord2Id,
                recordInfoModalRecord2ObjectName: this.recordInfoModalRecord2ObjectName,
                recordInfoModalRecord2InfoFields: this.recordInfoModalRecord2InfoFields,
                recordInfoModalSection2Name: this.recordInfoModalSection2Name,
                recordInfoModalRecord3Id: this.recordInfoModalRecord3Id,
                recordInfoModalRecord3ObjectName: this.recordInfoModalRecord3ObjectName,
                recordInfoModalRecord3InfoFields: this.recordInfoModalRecord3InfoFields,
                recordInfoModalSection3Name: this.recordInfoModalSection3Name,
                recordImageUrl: this.recordAvatarSrc,
                enableDebugMode: this.enableDebugMode
            }).then((result) => {
                if (result) {
                    this.consoleLog('recordInfoModal.close');
                    this.consoleLog(result, true);
                }
            });

        } else if (this.recordTitleClickAction === 'View Record') {

            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    objectApiName: this.objectApiName,
                    recordId: this.recordId,
                    actionName: 'view'
                },
            });
        }
    }
	
    /**
     * @descripton Spinner loading status
     */
	get isLoading(){
        return this.loadedLists === 0 && this.recordResponse ? false : true;
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
        logInfo('RecordInfoTile', anything, this.enableDebugMode, isJson);
    }
	
}