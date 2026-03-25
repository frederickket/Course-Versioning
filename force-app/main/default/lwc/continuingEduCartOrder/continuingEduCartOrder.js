/**
 * @Author 		WDCi (XW)
 * @Date 		Apr 2025
 * @group 		Continuing Education
 * @Description Lwc for continuing education cart (transaction order)
 * @changehistory
 * ISS-002393 10-04-2025 XW - moved from continuingEduCart lwc as a child component
 * ISS-002451 26-05-2025 XW - added t&c checkbox and tnc custom flow modal
 * ISS-002510 28-07-2025 XW - discount field now consider order level discount
 * ISS-002495 22-09-2025 XW - support translation for long text field
 * ISS-002682 14-10-2025 Lean - Added fail-safe navigation
 * ISS-002736 25-11-2025 XiRouh - Added tableTextDisplayMode configurable attribute
 * ISS-002746 27-11-2025 Lean - Removed currencyDisplayAs to use sf default setting
 * ISS-002747 28-11-2025 Lean - Fixed JS decimal issue
 * ISS-002779 21-01-2026 Lean - Make table header to respect tableTextDisplayMode
 * ISS-002793 10-02-2026 Lean - Show fully discounted draft order for checkout, hide order without order line, support custom criteria
 * ISS-002797 13-02-2025 Lean - Standardize language code format to POSIX
 */
import { LightningElement, api, wire, track } from 'lwc';
import genericConfirmationModal from 'c/genericConfirmationModal';
import { RefreshEvent, registerRefreshHandler, unregisterRefreshHandler } from 'lightning/refresh';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';
import { promptError, promptSuccess } from 'c/toasterUtil';
import { customLabels } from 'c/labelLoader';
import { updateDatatableConfig, isWrapTextEnabled, getTableHeaderDisplayMode, roundFloat, formatLanguageCodeToPosix } from 'c/lwcUtil';

import { refreshApex } from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { updateRecord, notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';

import TRO_OBJ from "@salesforce/schema/Transaction_Order__c";

import IS_GUEST from '@salesforce/user/isGuest';
import LANG from '@salesforce/i18n/lang';

import ctrlDeleteTransactionLine from '@salesforce/apex/REDU_ContinuingEduCartOrder_LCTRL.deleteTransactionLine';
import ctrlFetchTransactionLines from '@salesforce/apex/REDU_ContinuingEduCartOrder_LCTRL.fetchTransactionLines';
import ctrlUpdateTransactionFeeLine from '@salesforce/apex/REDU_ContinuingEduCartOrder_LCTRL.updateTransactionFeeLine';
import ctrlGetTransactionOrderStatuses from '@salesforce/apex/REDU_ContinuingEduCartOrder_LCTRL.getTransactionOrderStatuses';
import ctrlDistributeOrderDiscount from '@salesforce/apex/REDU_ContinuingEduCartOrder_LCTRL.distributeOrderDiscount';
import getTransactionOrder from '@salesforce/apex/REDU_ContinuingEduCartOrder_LCTRL.getTransactionOrder';

import continuingEduCartTncModal from 'c/continuingEduCartTncModal';

import AGREED_TO_TERMS_AND_CONDITIONS_LABEL from '@salesforce/label/c.Agreed_To_Terms_And_Conditions';

const RESPONSE_DEFAULT_CURRENCY = 'defaultCurrency';
const RESPONSE_COLUMNS = 'columns';
const RESPONSE_IS_MUTLICURRENCY_ORG = 'isMultiCurrencyOrg';
const RESPONSE_TRL_ORDERLINE_RECORDS = 'records';
const RESPONSE_TRL_DISCOUNTENTRY_RECORDS = 'discountEntryRecords';

const TRL_QUANTITY_FIELD_NAME = 'reduivy__Quantity__c';
const TRL_SUBTOTAL_FIELD_NAME = 'reduivy__Subtotal__c';

const TRO_STATUSES_DRAFT = 'Draft';
const TRO_STATUSES_CONFIRMED = 'Confirmed';
const TRO_STATUSES_SUBMITTED = 'Submitted';

const TYPE_CURRENCY = 'CURRENCY';

const TNC_MODE_CHECKBOX = 'Checkbox with Url';
const TNC_MODE_FLOW = 'Custom Screen Flow Mode';
const TNC_MODE_NONE = 'None';

const SVO_APPLYAS_ORDERLINEDISCOUNT = 'Order Line Discount';
const SVO_APPLYAS_ORDERDISCOUNT = 'Order Discount';

export default class ContinuingEduCartOrder extends NavigationMixin(LightningElement) {

    //transaction order record
    @api troRecord;
    
    //header & footer properties
    @api headerLabel;
    @api checkOutButtonLabel;
    @api clearAllButtonLabel;
    
    //table properties
    @api transactionLineFields;
    @api deleteIconName;
    @api isQuantityColumnEditable;
    @api quantityErrorMessage;

    //delete modal properties
    @api confirmationBoxBody;
    @api confirmationHeader;
    @api confirmationYesButtonLabel;
    @api confirmationNoButtonLabel;

    @api clearAllTransactionLineToastMessage;
    @api removeTransactionLineToastMessage

    //pricing summary properties
    @api subTotalPriceLabel;
    @api discountPriceLabel;
    @api totalPriceLabel;
    @api additionalOrderFields;

    //redirection properties
    @api paymentScreenSitePageName;

    //tnc
    @api termsAndConditionsMode;
    @api termsAndConditionsUrlFlowName;

    //debug properties
    @api enableDebugMode;
    @api isCommunity;

    //wire attributes
    @track transactionLinesResult;
    @track transactionLinesResponse;
    @track transactionOrderStatusesResult;
    @track transactionOrderStatusesResponse;

    //ISS-002736
    @api tableTextDisplayMode;

    //labels
    label = customLabels;

    //refresh handler
    refreshHandlerID;

    loadedLists = 0;
    isScriptLoaded = false;
    isInitSuccess = false;
    
    @track agreedToTermsAndConditions;

    //identifier to decide toggle or not in lwc
    @track invalidQuantity = false;

    //js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'tooltips'
    modules = [];

    /**
     * @descripton connected callback
     */
    connectedCallback(){
        this.refreshHandlerID = registerRefreshHandler(this, this.refreshData);
        
        this.consoleLog('this.refreshHandlerID: ' + this.refreshHandlerID);
	}
    
    /**
     * @descripton disconnected callback
     */
	disconnectedCallback() {
		unregisterRefreshHandler(this.refreshHandlerID);
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

        this.toggleSpinner(1);
        refreshApex(this.transactionLinesResult);

        this.toggleSpinner(-1);
        return new Promise((resolve) => {
            resolve(true);
        });

    }

    
    @wire(getObjectInfo, { objectApiName: TRO_OBJ })
    wiredTroObjectInfo;

    /**
     * @description get all the children transaction line items of the transaction order
     */
    @wire(ctrlFetchTransactionLines, { troId: "$troRecord.Id", transactionLinesFields: "$transactionLineFields", language: '$language', enableWrapText: '$enableWrapText' })
    wiredTransactionLines(result) {
        this.consoleLog('wiredTransactionLines')
        this.transactionLinesResult = result;
        this.transactionLinesResponse = null;

        if (result.data) {
            this.transactionLinesResponse = JSON.parse(result.data.responseData);
            this.consoleLog(this.transactionLinesResponse, true);

            updateDatatableConfig(this.transactionLinesResponse, this.isCommunity, this.language);

        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }
    }
    
    /**
     * @description get tro statuses defined in custom metadata
     */
    @wire(ctrlGetTransactionOrderStatuses)
    wiredGetTransactionOrderStatuses(result) {
        this.consoleLog('wiredGetTransactionOrderStatuses');
        this.transactionOrderStatusesResult = result;
        this.transactionOrderStatusesResponse = null;
        
        if(result.data) {
            this.transactionOrderStatusesResponse = JSON.parse(result.data.responseData);
            this.consoleLog(this.transactionOrderStatusesResponse, true);
        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    /**
     * @description the user language
     */
    get language() {
        return formatLanguageCodeToPosix(LANG);
    }

    /**
     * @description Return order title
     */
    get headerLabelText() {
        return (this.headerLabel ?? '' ) + ' ' + this.troRecord?.Name;
    }

    /**
     * @description get tro draft statuses
     */
    get troDraftStatuses(){
        if(this.transactionOrderStatusesResponse && this.transactionOrderStatusesResponse[TRO_STATUSES_DRAFT]) {
            return this.transactionOrderStatusesResponse[TRO_STATUSES_DRAFT];
        }

        return [];
    }

    /**
     * @description get tro confirmed statuses
     */
    get troConfirmedStatuses(){
        if(this.transactionOrderStatusesResponse && this.transactionOrderStatusesResponse[TRO_STATUSES_CONFIRMED]) {
            return this.transactionOrderStatusesResponse[TRO_STATUSES_CONFIRMED];
        }

        return [];
    }

    /**
     * @description get tro submitted statuses
     */
    get troSubmittedStatuses(){
        if(this.transactionOrderStatusesResponse && this.transactionOrderStatusesResponse[TRO_STATUSES_SUBMITTED]) {
            return this.transactionOrderStatusesResponse[TRO_STATUSES_SUBMITTED];
        }

        return [];
    }

    /**
     * @description Return true if order is draft
     */
    get isEditAllowed() {
        return this.troDraftStatuses.includes(this.troRecord?.reduivy__Status__c);
    }

    /**
     * @description Return true if order can accept payment
     */
    get isCheckoutAllowed() {
        return this.troDraftStatuses.includes(this.troRecord?.reduivy__Status__c) ||
            this.troSubmittedStatuses.includes(this.troRecord?.reduivy__Status__c) ||
            this.troConfirmedStatuses.includes(this.troRecord?.reduivy__Status__c);
    }

    /**
     * @description the children study voucher transaction for order level discount
     */
    get svtList() {
        return this.troRecord?.reduivy__Study_Voucher_Transactions__r?.records ?? [];
    }

    /**
     * @description the total order discount amount from study voucher transaction
     */
    get totalOrderDiscountAmount() {
        //calculate the order line discount from study voucher transaction amount
        //where study voucher transaction.apply as = order level discount
        let amount = 0;
        for(let svt of this.svtList) {
            if (svt?.reduivy__Study_Voucher__r) {
                amount += svt?.reduivy__Study_Voucher__r?.reduivy__Apply_As__c === SVO_APPLYAS_ORDERDISCOUNT ? (svt?.reduivy__Amount__c ?? 0) : 0;
            }
        }
        
        return amount;
    }

    //the default currency of the org
    get defaultCurrency(){
        return this.transactionLinesResponse && this.transactionLinesResponse?.[RESPONSE_DEFAULT_CURRENCY];
    }
    
    //list of transaction line items order line
    get orderLineRecords(){
        return this.transactionLinesResponse && this.transactionLinesResponse?.[RESPONSE_TRL_ORDERLINE_RECORDS]
    }

    //list of transaction line items discount entry
    get discountEntryRecords(){
        return this.transactionLinesResponse && this.transactionLinesResponse?.[RESPONSE_TRL_DISCOUNTENTRY_RECORDS]
    }

    //columns to be used in datatable
    get transactionLineColumns(){
        let columns = this.transactionLinesResponse && this.transactionLinesResponse?.[RESPONSE_COLUMNS];
        
        for(let column of columns) {
            if(column.fieldName === TRL_QUANTITY_FIELD_NAME) {
                column.editable = this.isLoggedInUser && this.isEditAllowed ? this.isQuantityColumnEditable : false;
            }
            if(column.type === 'currency') {
                column.typeAttributes = {};
                column.typeAttributes.currencyCode = this.currencyToDisplay;
            }
        }
        
        //add the delete column into the table
        if (this.isLoggedInUser && this.deleteIconName && this.isEditAllowed) {
            columns = [...columns, ...[{
                type: "button", 
                fixedWidth: 32,
                typeAttributes: {
                    iconName: this.deleteIconName,
                    variant: 'base'
                }
            }]];
        }

        this.consoleLog(columns, true);
        return columns;
    }

    //return true if the org is multicurrency enabled
    get isMultiCurrencyOrg() {
        return this.transactionLinesResponse && this.transactionLinesResponse?.[RESPONSE_IS_MUTLICURRENCY_ORG];
    }

    //the currency of this transaction order used. same as defaultCurrency if isMultiCurrencyOrg is not enabled
    get currencyToDisplay() {
        if(this.isMultiCurrencyOrg && this.troRecord?.CurrencyIsoCode){
            return this.troRecord?.CurrencyIsoCode;
        } 
        return this.defaultCurrency;
    }

    //the sum of all the transaction line items subtotal
    get subTotalPrice(){
        let result = 0.0;
        if(this.orderLineRecords) {
            for(let trl of this.orderLineRecords) {
                result += trl[TRL_SUBTOTAL_FIELD_NAME] || 0;
            }
        }

        return result;
    }

    //the sum of all the transaction line items discount
    get discountPrice(){
        let result = 0.0;
        if(this.discountEntryRecords?.length > 0) {
            for(let trl of this.discountEntryRecords) {
                
                //calculate the order line discount from discount entry trl total amount 
                //where study voucher transaction = null or study voucher transaction.apply as = order level discount
                if(
                    !trl?.reduivy__Study_Voucher_Transaction__c || 
                    (trl?.reduivy__Study_Voucher_Transaction__c && trl?.reduivy__Study_Voucher_Transaction__r?.reduivy__Study_Voucher__r?.reduivy__Apply_As__c === SVO_APPLYAS_ORDERLINEDISCOUNT)
                ) {
                    result += trl?.reduivy__Total_Amount__c ?? 0;
                }

            }
        }

        result += this.totalOrderDiscountAmount;
        return result;
    }

    //the total amount value in transaction order, subtotal - discount
    get totalPrice(){
        let result = this.subTotalPrice - this.discountPrice;
        return result;
    }

    //list of summary fields data to be displayed under the trl table
    get summaryFieldsData(){
        let result = [];

        let parentContextData = {CurrencyIsoCode: this.currencyToDisplay};

        //subtotal
        if(this.subTotalPriceLabel) {
            let obj = {};
            let subtotal = roundFloat(this.subTotalPrice, 2); //ISS-002747 fixed to 2 decimal
            obj.key = 'subtotal_' + subtotal;
            obj.value = subtotal;
            obj.fieldDisplayValue = subtotal;
            obj.label = this.subTotalPriceLabel;
            obj.displayType = TYPE_CURRENCY;
            obj.parentContextData = JSON.stringify(parentContextData);
            result.push(obj);
        }

        //discount
        if(this.discountPriceLabel) {
            let obj = {};
            let discount = roundFloat(this.discountPrice, 2);
            obj.key = 'discount_' + discount;
            obj.value = discount;
            obj.fieldDisplayValue = discount;
            obj.label = this.discountPriceLabel;
            obj.displayType = TYPE_CURRENCY;
            obj.parentContextData = JSON.stringify(parentContextData);
            result.push(obj);
        }

        //total price
        if(this.totalPriceLabel) {
            let obj = {};
            let totalprice = roundFloat(this.totalPrice, 2);
            obj.key = 'totalprice_' + totalprice;
            obj.value = totalprice;
            obj.fieldDisplayValue = totalprice;
            obj.label = this.totalPriceLabel;
            obj.displayType = TYPE_CURRENCY;
            obj.parentContextData = JSON.stringify(parentContextData);
            result.push(obj);
        }

        //additional fields, we will display using outputField.js
        if(this.additionalOrderFields){
            let fieldList = this.additionalOrderFields.split(';');

            for(let fieldName of fieldList){
                if(Object.hasOwn(this.troRecord, fieldName)){
                    let obj = {};
                    let label = fieldName;
                    let value = this.troRecord[fieldName];
                    if(this.wiredTroObjectInfo?.data?.fields[fieldName]){
                        label = this.wiredTroObjectInfo?.data?.fields[fieldName]?.label;
                        obj.displayType = this.wiredTroObjectInfo?.data?.fields[fieldName]?.dataType?.toUpperCase();

                        if (obj.displayType === TYPE_CURRENCY) {
                            //ISS-002747 fix to decimal based on the field setting
                            value = roundFloat(value, this.wiredTroObjectInfo?.data?.fields[fieldName]?.scale);
                        }
                    }

                    obj.key = `${fieldName}_${value}`;
                    obj.value = value;
                    obj.fieldDisplayValue = value;
                    obj.label = label;
                    obj.parentContextData = JSON.stringify(parentContextData);

                    result.push(obj);
                    
                }
            }
        }

        this.consoleLog(result, true);
        return result;
    }

    /**
     * @description Return true for non guest user
     */
    get isLoggedInUser() {
        return !IS_GUEST;
    }

    /**
     * @description Return true to display clear all button
     */
    get showClearAllButton() {
        return this.isLoggedInUser && this.clearAllButtonLabel && this.isEditAllowed;
    }

    /**
     * @description Return true to display checkout button
     */
    get showCheckoutButton() {
        return (this.isLoggedInUser && this.checkOutButtonLabel && this.isCheckoutAllowed);
    }

    /**
     * @description The Agreed To Tnc Label
     */
    get agreedToTermsAndConditionsLabel() {
        return AGREED_TO_TERMS_AND_CONDITIONS_LABEL.format([this.termsAndConditionsUrlFlowName]);
    }

    /**
     * @description disable checkout button
     */
    get checkoutDisabled() {
        return !!(this.invalidQuantity || (this.showTncCheckbox && !this.agreedToTermsAndConditions));
    }

    /**
     * @description terms and conditions feature is enabled
     */
    get showTncCheckbox(){
        return this.termsAndConditionsUrlFlowName && this.termsAndConditionsMode === TNC_MODE_CHECKBOX && this.isCheckoutAllowed;
    }

    /** 
    * @description This method will get the id of transaction line record which is to be deleted.
    */
    handleRowAction(event) {
        const row = event.detail.row;
        let orderLineIdToBeDeleted = row.Id;
        this.launchConfirmationModal(this.confirmationHeader, this.confirmationBoxBody, null, null, true, this.confirmationYesButtonLabel, true, this.confirmationNoButtonLabel, 'deleteTransactionLine', orderLineIdToBeDeleted);
    }

    /** 
    * @description This method will delete all transaction lines record against the particular order.
    */
    handleClearAll(event) {
        let orderIdToBeCleared = event.target.value;
        this.launchConfirmationModal(this.confirmationHeader, this.confirmationBoxBody, null, null, true, this.confirmationYesButtonLabel, true, this.confirmationNoButtonLabel, 'deleteAllTransactionLines', orderIdToBeCleared);
    }

    /**
     * @description checkout to the payment screen
     */
    async handleCheckout(){
        this.consoleLog('handleCheckout');
        if(this.showTncCheckbox && !this.agreedToTermsAndConditions) {
            return;
        }

        try{
            this.toggleSpinner(1);

            if(this.termsAndConditionsUrlFlowName) {
                if(this.termsAndConditionsMode === TNC_MODE_CHECKBOX) {
                    this.consoleLog('handleCheckout :: TNC_MODE_CHECKBOX');
                    await this.updateAgreedToTnc();

                } else if(this.termsAndConditionsMode === TNC_MODE_FLOW) {
                    this.consoleLog('handleCheckout :: TNC_MODE_FLOW');

                    await continuingEduCartTncModal.open({
                        transactionOrderId: this.troRecord?.Id,
                        flowName: this.termsAndConditionsUrlFlowName,
                        enableDebugMode: this.enableDebugMode,
                        size: 'small'
                    });

                    this.consoleLog('continuingEduCartTncModal.close');

                    //get the latest tnc status
                    let updatedTroResult = await getTransactionOrder({troId: this.troRecord?.Id});
                    let updatedTroResponse = JSON.parse(updatedTroResult.responseData);
                    
                    this.consoleLog('updatedTroResponse = ' + updatedTroResponse.reduivy__Agreed_To_Terms_And_Conditions__c);
                    if(!updatedTroResponse.reduivy__Agreed_To_Terms_And_Conditions__c) {
                        this.toggleSpinner(-1);
                        return;
                    }
                    
                }
            }

            this.consoleLog('ctrlDistributeOrderDiscount');
            await ctrlDistributeOrderDiscount({troId: this.troRecord?.Id});
            notifyRecordUpdateAvailable([{recordId: this.troRecord?.Id}]);
            
            this.toggleSpinner(-1);

            this.navigateToSitePage(this.troRecord.Id, this.paymentScreenSitePageName);

        } catch(error) {
            this.toggleSpinner(-1);
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
        }
    }

    /**
     * @description update the Agreed To Tnc field to true
     */
    async updateAgreedToTnc(){
        let fields = {};
        fields.Id = this.troRecord.Id
        fields.reduivy__Agreed_To_Terms_And_Conditions__c = this.showTncCheckbox && this.agreedToTermsAndConditions;
        let record = {fields};

        this.consoleLog('updateAgreedToTnc');
        this.consoleLog(record, true);

        await updateRecord(record);
        notifyRecordUpdateAvailable([{recordId: this.troRecord.Id}]);

    }
    
    /**
     * @description Navigate to the page given
     * @param {String} orderId
     * @param {String} sitePageName 
     */
    navigateToSitePage(orderId, sitePageName) {

        let navigationUrl;
        let pageReference = {};
        let pageRefAttr = {};

        if (sitePageName) {
            sitePageName = sitePageName.replace('{orderId}', orderId);

            if (sitePageName.startsWith('http://') || sitePageName.startsWith('https://')) {
                navigationUrl = sitePageName;
                pageReference.type = 'standard__webPage'
                pageRefAttr = { url: navigationUrl };
            } else {
                if (this.isCommunity) {
                    //for community
                    pageReference.type = 'comm__namedPage';
                    pageRefAttr = { name: sitePageName};
                    pageReference.state = {'orderId' : orderId};

                } else {
                    //for internal, we expect the lightning page to have a tab in order to navigate to the page successfully
                    //the query string will also have namespace or use c__orderId, otherwise it will fail
                    pageReference.type = 'standard__navItemPage';
                    pageRefAttr = { apiName: sitePageName};
                    pageReference.state = {'reduivy__orderId' : orderId};
                }                
            }
        } else {
            pageReference.type = 'standard__recordPage';
            pageRefAttr = {
                recordId: orderId,
                objectApiName: 'reduivy__Transaction_Order__c',
                actionName: 'view'
            };
        }

        pageReference.attributes = pageRefAttr;

        if (pageReference) {
            this.consoleLog('navigateToSitePage');
            this.consoleLog(pageReference, true);
            
            // Navigate to a URL
            this[NavigationMixin.Navigate](pageReference, true);
        }
    }

    /**
     * @description Launch the confirmation modal to confirm delete
     * @param {String} title 
     * @param {String} text1 
     * @param {String} text2 
     * @param {String} text3 
     * @param {String} showSubmit 
     * @param {String} submitLabel 
     * @param {String} showCancel 
     * @param {String} cancelLabel 
     * @param {String} lEventSource 
     * @param {String} lEventData 
     */
    launchConfirmationModal(title, text1, text2, text3, showSubmit, submitLabel, showCancel, cancelLabel, lEventSource, lEventData) {
        genericConfirmationModal.open({
            size: 'small',
            modalTitle: title,
            confirmationText1: text1,
            confirmationText2: text2,
            confirmationText3: text3,
            showSubmitButton: showSubmit,
            submitButtonLabel: submitLabel,
            showCancelButton: showCancel,
            cancelButtonLabel: cancelLabel,
            eventSource: lEventSource,
            eventData: lEventData,
            enableDebugMode: this.enableDebugMode
        }).then((result) => {

            if (result) {
                this.consoleLog('launchConfirmationModal.close');
                this.consoleLog(result, true);

                const { operation, eventSource, eventData } = result;

                if (operation === 'submit' && eventSource === 'deleteAllTransactionLines') {
                    this.handleDeleteTransactionLines(eventData, true);
                } else if (operation === 'submit' && eventSource === 'deleteTransactionLine') {
                    this.handleDeleteTransactionLines(eventData, false);
                }
            }
        });
    }


    /** 
    * @description This method will delete transaction line, either clear all or single transaction line
    */
    handleDeleteTransactionLines(idTobeDelete, isDeleteAll) {

        let trlIds = [];
        let toastMessage = '';
        if (isDeleteAll) {
            
            toastMessage = this.clearAllTransactionLineToastMessage;

        } else {
            trlIds.push(idTobeDelete);
            toastMessage = this.removeTransactionLineToastMessage;
        }

        if (isDeleteAll || (!isDeleteAll && trlIds.length > 0)) {
            this.deleteTransactionLines(trlIds, toastMessage);
        }

    }
    
    /** 
    * @description This is the generic method used to delete transaction lines records.
    */
    deleteTransactionLines(trlIds, toastMessage){

        this.toggleSpinner(1);

        let affectedOrderId = this.troRecord.Id;

        ctrlDeleteTransactionLine({
            orderId: affectedOrderId,
            transactionLineIds: trlIds
        })
        .then(result => {
            this.toggleSpinner(-1);
            this.dispatchEvent(new RefreshEvent());

            promptSuccess(this.label.SUCCESS_LABEL, toastMessage);

            this.dispatchEvent(new CustomEvent('trlupdated'));
            

        }).catch(error => {
            this.toggleSpinner(-1);

            promptError(this.label.ERROR_LABEL, getErrorMessage(error));

        });
    }

    /**
     * =@description update the transaction line item when quantity is changed
     */
    handleQuantityChange(event){
        let eventValue = event.detail.draftValues[0];
        eventValue[TRL_QUANTITY_FIELD_NAME] = parseFloat(eventValue[TRL_QUANTITY_FIELD_NAME]);

        if (eventValue[TRL_QUANTITY_FIELD_NAME] >= 1 && eventValue[TRL_QUANTITY_FIELD_NAME] % 1 === 0) {
            this.invalidQuantity = false;

            let targetTrlRecord = this.orderLineRecords?.find(trl => trl.Id === eventValue.Id);
            if(targetTrlRecord){
                targetTrlRecord[TRL_QUANTITY_FIELD_NAME] = eventValue[TRL_QUANTITY_FIELD_NAME];
                this.handleUpdateTransactionFeeLine(targetTrlRecord);
            }


        } else {
            this.invalidQuantity = true;
            promptError(this.label.ERROR_LABEL, this.quantityErrorMessage);
        }
    }

    /** 
    * @description This method will update quantity at the backend.
    */
    handleUpdateTransactionFeeLine(data) {
        this.toggleSpinner(1);

        ctrlUpdateTransactionFeeLine({ 
            transactionOrderId: this.troRecord.Id, 
            transactionLineItemJsonStr: JSON.stringify(data)
        })
        .then(result => {
            this.toggleSpinner(-1);
            this.dispatchEvent(new RefreshEvent());

        }).catch(error => {
            this.toggleSpinner(1);
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
        })

    }

    /**
     * @description toggle terms and conditions value
     */
    handleToggleTermsAndConditions() {
        this.agreedToTermsAndConditions = !this.agreedToTermsAndConditions;
    }

    /**
     * @descripton Spinner loading status
     */
    get isLoading() { 
        return this.loadedLists === 0 ? false : true;
    }

    /**
     * @descripton return Table display mode - enable wrap text
     */
    get enableWrapText() {
        return isWrapTextEnabled(this.tableTextDisplayMode);
    }

    /**
     * @description ISS-002779 return Table header display mode - enable wrap text
     */
    get tableHeaderDisplayMode() {
        return getTableHeaderDisplayMode(this.tableTextDisplayMode);
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
        logInfo('ContinuingEduCartOrder', anything, this.enableDebugMode, isJson);
    }


}