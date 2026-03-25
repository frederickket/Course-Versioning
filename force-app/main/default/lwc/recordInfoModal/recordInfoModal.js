/**
 * @Author 		WDCi (Lean)
 * @Date 		Aug 2024
 * @group 		Utility
 * @Description Record info tile
 * @changehistory
 * ISS-001919 08-08-2024 Lean - new tile
 */
import { api } from 'lwc';
import LightningModal from 'lightning/modal';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';
import { customLabels } from 'c/labelLoader';

export default class RecordInfoModal extends LightningModal {
	
	//configurable attributes
    @api modalTitle;
    @api recordInfoModalRecord1Id;
    @api recordInfoModalRecord1ObjectName;
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

    @api recordImageUrl;

	@api enableDebugMode = false;
	
	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false
	loadedLists = 0;
	
	//js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'tooltips'
    modules = [];
	
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
     * @description Return loading label
     */
    get loadingLabel() {
        return customLabels.LOADING_LABEL;
    }

    /**
     * @description Return modal title
     */
    get headerLabel() {
        return this.modalTitle;
    }

    /**
     * @description Return close label
     */
    get closeButtonLabel() {
        return customLabels.CLOSE_LABEL;
    }

    /**
     * @description Show record 1 info
     */
    get showRecord1Info() {
        if (this.recordInfoModalRecord1Id && this.recordInfoModalRecord1InfoFields && this.recordInfoModalRecord1ObjectName) {
            return true;
        }

        return false;
    }

    /**
     * @description Show record 2 info
     */
    get showRecord2Info() {
        if (this.recordInfoModalRecord2Id && this.recordInfoModalRecord2InfoFields && this.recordInfoModalRecord2ObjectName) {
            return true;
        }

        return false;
    }

    /**
     * @description Show record 3 info
     */
    get showRecord3Info() {
        if (this.recordInfoModalRecord3Id && this.recordInfoModalRecord3InfoFields && this.recordInfoModalRecord3ObjectName) {
            return true;
        }

        return false;
    }

    /**
     * @description Return record 1 fields
     */
    get record1InfoFields() {
        if (this.recordInfoModalRecord1InfoFields) {
            return this.recordInfoModalRecord1InfoFields.split(';');
        }

        return null;
    }

    /**
     * @description Return record 2 fields
     */
    get record2InfoFields() {
        if (this.recordInfoModalRecord2InfoFields) {
            return this.recordInfoModalRecord2InfoFields.split(';');
        }

        return null;
    }

    /**
     * @description Return record 3 fields
     */
    get record3InfoFields() {
        if (this.recordInfoModalRecord3InfoFields) {
            return this.recordInfoModalRecord3InfoFields.split(';');
        }

        return null;
    }

    /**
     * @description Active accordions
     */
    get activeAccordions() {
        let accordions = [];

        if (this.showRecord1Info) {
            accordions.push('section1');
        }

        if (this.showRecord2Info) {
            accordions.push('section2');
        }

        if (this.showRecord3Info) {
            accordions.push('section3');
        }

        return accordions;
    }

    /**
     * @description Handle close click
     */
    handleCloseClick() {
        this.close({operation: 'close'});
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
        logInfo('RecordInfoModal', anything, this.enableDebugMode, isJson);
    }
	
}