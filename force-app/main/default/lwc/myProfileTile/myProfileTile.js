/**
 * @Author 		WDCi (vtan)
 * @Date 		Oct 2024
 * @group 		Utility
 * @Description My profile tile
 * @changehistory
 * ISS-002151 25-10-2024 vtan - new tile
 */

import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

import { promptError } from 'c/toasterUtil';
import { getErrorMessage, logInfo } from 'c/loggingUtil';

import { customLabels } from 'c/labelLoader';

import ctrlGetUser from '@salesforce/apex/REDU_MyProfile_LCTRL.getUser';

export default class myProfileTile extends NavigationMixin(LightningElement) {

    @api iconName; // Icon name, e.g., utility:home
    @api iconSize; // Icon size (e.g., small, medium, large)
    @api tileName; // The title of the tile
    @api description; // Description text for the tile
    @api autoRedirection = false; // auto redirecting user to the target page
    @api objectType; // URL to navigate to when the tile is clicked

    @api enableDebugMode = false;

    //internal attribute
    contactUserWireResult;
    contactUserResponse;

    //labels
	label = customLabels;

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

    @wire(ctrlGetUser)
    wiredGetUser(result) {
        this.contactUserWireResult = result;
        this.contactUserResponse = null;

        if (result.data) {
            this.contactUserResponse = JSON.parse(result.data.responseData);
            this.consoleLog(this.contactUserResponse, true);

            if (this.autoRedirection) {
                this.navigateToRecordPage();
            }

        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    handleClick() {
        this.navigateToRecordPage();
    }

    /**
     * @description navigate to record page
     */
    navigateToRecordPage() {

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                objectApiName: this.objectType,
                recordId: this.targetRecordId,
                actionName: 'view'
            },
        });
    }

    get targetRecordId(){
        if(this.objectType === 'Contact') {
            return this.contactUserResponse?.ContactId;
        }

        return this.contactUserResponse?.Id;
    }

    /**
     * @descripton Console log for debugging
     */
	consoleLog(anything, isJson){
        logInfo('myProfileTile', anything, this.enableDebugMode, isJson);
    }
}