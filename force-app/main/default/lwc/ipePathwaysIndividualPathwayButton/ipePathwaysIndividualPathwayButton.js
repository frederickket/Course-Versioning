/**
 * @Author 		WDCi (XiRouh)
 * @Date 		April 2025
 * @group 		
 * @Description 
 * @changehistory
 * ISS-002416 23-04-2025 XiRouh - new class
 */
import { LightningElement, api } from 'lwc';

export default class IpePathwaysIndividualPathwayButton extends LightningElement {
	
	@api enableDebugMode = false;
	
    @api ipwRecord;
    @api currentIpwId;
    @api ipwButtonLabelPrefix;

	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false
	loadedLists = 0;
	
    //js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'tooltips'
    modules = ['stringutil'];

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
     * @descripton handle button on click event
     */
    handleSelectPathway(event) {
        let selectedIpwId = event.target.value;
    
        const selectEvent = new CustomEvent('pathwayselect', {
            detail: {
                selectedIpwId: selectedIpwId
            }
        });
        
        this.dispatchEvent(selectEvent);
    }

    /**
     * @descripton return button variant
     */
    get buttonVariant() {
        return this.isSelected ? 'brand' : 'neutral';
    }

    /**
     * @descripton to check if current ipw is selected
     */
    get isSelected() {
        return this.currentIpwId === this.ipwRecord?.Id;
    }
	
    /**
     * @descripton get id of the ipwRecord
     */
    get ipwId() {
        return this.ipwRecord?.Id;
    }

    /**
     * @descripton get the term number of the ipwRecord
     */
    get ipwTermNumber() {
        return this.ipwRecord?.reduivy__Term_Number__c;
    }

    /**
     * @descripton get the ipw button label
     */
    get ipwButtonLabel(){
        if (this.ipwButtonLabelPrefix) {
            return this.ipwButtonLabelPrefix.format([this.ipwTermNumber]);
        }

        return this.ipwTermNumber;
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
        logInfo('IpePathwaysIndividualPathwayButton', anything, this.enableDebugMode, isJson);
    }
}