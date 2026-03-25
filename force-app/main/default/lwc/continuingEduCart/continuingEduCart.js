/**
 * @Author 		WDCi (XW)
 * @Date 		May 2024
 * @group 		Continuing Education
 * @Description Lwc for continuing education cart
 * @changehistory
 * ISS-001660 28-05-2024 XW - Created new shopping cart
 * ISS-001660 28-10-2024 Lean - Make cart view-only for guest user
 * ISS-002393 17-04-2025 XW - get additional tro fields value
 * ISS-002683 14-10-2025 Lean - Avoid unnecessary wire method invocation
 * ISS-002736 25-11-2025 XiRouh - Added tableTextDisplayMode configurable attribute
 * ISS-002793 10-02-2026 Lean - Show fully discounted draft order for checkout, hide order without order line, support custom criteria
 */
import { LightningElement, api, wire, track } from 'lwc';
import { promptInfo, promptError, promptWarning, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';
import { customLabels } from 'c/labelLoader';
import { RefreshEvent, registerRefreshContainer, unregisterRefreshContainer } from 'lightning/refresh';
import { refreshApex } from '@salesforce/apex';

import IS_GUEST from '@salesforce/user/isGuest';

import ctrlGetTransactionOrders from '@salesforce/apex/REDU_ContinuingEduCart_LCTRL.getTransactionOrders';
import ctrlGetCommunityInfo from '@salesforce/apex/REDU_ContinuingEduCart_LCTRL.getCommunityInfo';

export default class ContinuingEduCart extends LightningElement {

    //configurable attributes
    @api modalTitle;
    //icon properties
    @api modalIconName;
    @api iconSize;

    //record id properties
    @api paramOrderId;
    @api recordId

    //header & footer properties
    @api headerLabel;    
    @api checkOutButtonLabel;
    @api saveErrorMessage;
    @api clearAllButtonLabel;
    
    //table properties
    @api transactionLineFields;
    @api deleteIconName;
    @api isQuantityColumnEditable;
    @api quantityErrorMessage;

    @api tableTextDisplayMode;

    //no order line div properties
    @api noTransactionOrderErrorMessage;

    //delete modal properties
    @api confirmationHeader;
    @api confirmationBoxBody;
    @api confirmationYesButtonLabel;
    @api confirmationNoButtonLabel;

    @api clearAllTransactionLineToastMessage;
    @api removeTransactionLineToastMessage;

    //pricing summary properties
    @api subTotalPriceLabel;
    @api discountPriceLabel;
    @api totalPriceLabel;
    @api additionalOrderFields = '';

    //redirection properties
    @api paymentScreenSitePageName;

    //tnc
    @api termsAndConditionsMode;
    @api termsAndConditionsUrlFlowName;

    //ISS-002793
    @api orderCustomCriteria;

    //debug properties
    @api enableDebugMode;

    //obsolete attribute - do not use
    @api basePath;
    @api headerLabelCss;
    @api totalContainerStyling;
    @api headerContainerStyling;
    @api footerContainerStyling;
    @api transactionLineTableLastColumnHeading;

    //the refer orderId
    targetOrderId;

    //internal attributes
    loadedLists = 0;
    isScriptLoaded = false;
    isInitSuccess = false;

    //wire attribute
    communityInfoWireResult;
    communityInfoResponse;
    transactionOrdersWireResult;
    transactionOrdersResponse;

    pageRef;

    //refresh handler
    refreshContainerID;

    //labels
    label = customLabels;

    //js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'tooltips'
    modules = ['continuingeducss', 'stringutil'];

    /**
     * @descripton connected callback
     */
    connectedCallback() {
        
        this.refreshContainerID = registerRefreshContainer(this, this.refreshData);
    }

    /**
     * @descripton disconnected callback
     */
	disconnectedCallback() {
		unregisterRefreshContainer(this.refreshContainerID);
	}

    /**
    * @descripton library loader
    */
    handleLibLoadSuccess() {
        this.isScriptLoaded = true;
        this.isInitSuccess = true;

        //ISS-002683 ensure that the targetOrderId is ready before wire method invocation
        if (this.paramOrderId) {
            this.targetOrderId = this.paramOrderId;
        } else if (this.recordId) {
            this.targetOrderId = this.recordId;
        } else {
            this.targetOrderId = null;
        }
    }

    /**
     * @descripton library loader
    */
    handleLibLoadFail() {
        this.isScriptLoaded = true;
        this.isInitSuccess = false;
    }

    /**
     * @description Refreh data
     */
    refreshData() {
        this.consoleLog('refreshData');
        
        this.toggleSpinner(1);

        refreshApex(this.transactionOrdersWireResult);
        
        this.toggleSpinner(-1);
        return new Promise((resolve) => {
            resolve(true);
        });

    }

    /**
     * @description Handle the refresh
     */
    handleRefreshOnclick() {
        this.dispatchEvent(new RefreshEvent());
    }

    /**
     * @description Get community info
     * @param {*} result 
     */
    @wire(ctrlGetCommunityInfo, {})
    wiredCommunityInfo(result) {
        this.consoleLog('wiredCommunityInfo');
        this.communityInfoWireResult = result;
        this.communityInfoResponse = null;

        if (result.data) {
            this.communityInfoResponse = JSON.parse(result.data.responseData);
            this.consoleLog(this.communityInfoResponse, true);

        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    /**
     * @description Return order id array for wire method
     */
    get orderIdsForWireMethod() {
        if (this.targetOrderId) {
            return this.targetOrderId.split(';');
        }

        return null;
    }

    /**
     * @description Return non null orderCustomCriteria if it is not set
     */
    get orderCustomCriteriaForWireMethod() {
        return this.orderCustomCriteria ?? '';
    }

    /**
     * @description Get transaction orders
     * @param {*} result 
     */
    @wire(ctrlGetTransactionOrders, {
        orderIds: '$orderIdsForWireMethod',
        additionalFields: '$additionalOrderFields',
        orderCustomCriteria: '$orderCustomCriteriaForWireMethod'
    })
    wiredTransactionOrders(result) {
        this.consoleLog('wiredTransactionOrders');
        this.transactionOrdersWireResult = result;
        this.transactionOrdersResponse = null;

        if (result.data) {
            this.transactionOrdersResponse = JSON.parse(result.data.responseData);
            this.consoleLog(this.transactionOrdersResponse, true);

        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    /**
     * @description Return true to show modal title and icon
     */
    get showModalHeader(){
        if(this.modalTitle){
            return true;
        }
        return false;
    }

    /**
     * @description Return true if current context is community
     */
    get isCommunity() {
        return this.communityInfoResponse?.isCommunity;
    }

    /**
     * @description Return true for non guest user
     */
    get isLoggedInUser() {
        return !IS_GUEST;
    }

    /**
     * @description Return true if there is transaction order
     */
    get hasTransactionOrders() {
        return this.transactionOrdersResponse && this.transactionOrdersResponse.length > 0;
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
        logInfo('ContinuingEduCart', anything, this.enableDebugMode, isJson);
    }

}