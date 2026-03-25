/**
 * @Author 		WDCi (XW)
 * @Date 		May 2024
 * @group 		Continuing Education
 * @Description Lwc for continuing education cart payment
 * @changehistory
 * ISS-001660 31-05-2024 XW - Created new shopping cart payment
 */
import { LightningElement, api, wire, track } from 'lwc';
import { promptInfo, promptError, promptWarning, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';
import { customLabels } from 'c/labelLoader';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';

import checkCompanyOrder from '@salesforce/apex/REDU_ContinuingEduCartPayment_LCTRL.checkCompanyOrder';
import updateCompanyOrder from '@salesforce/apex/REDU_ContinuingEduCartPayment_LCTRL.updateCompanyOrder';
import getCommunityInfo from '@salesforce/apex/REDU_ContinuingEduCartPayment_LCTRL.getCommunityInfo';

export default class ContinuingEduCartPayment extends NavigationMixin(LightningElement) {

    //configurable attributes
    @api titleLabel;
    
    @api modalIconName;
    @api iconSize;

    @api recordId;
    @api paramOrderId;    
    
    @api descriptionText;
    @api creditCardLabel;
    @api creditCardDescription;
    @api companyLabel;
    @api companyDescription;
    
    @api payButtonLabel;
    @api cancelButtonLabel;
    @api creditCardPaymentRedirectionPage;
    @api companyOrderPaymentRedirectionPage;
    @api cancelRedirectionPageName;
    
    @api rioOrderUpdatedSuccessMessage;
    @api paymentErrorMessage;
    @api orderSubmittedStatus = 'Submitted';

    @api enableDebugMode = false;

    //obsolete attribute - do not use
    @api domainName;
    @api modalTitle;
    @api headerBackgroundColour;
    @api footerBackgroundColour;
    @api headerCssClass;
    @api cardCssClass;

    creditselect = false;
    creditCompany = false;
    isCorporatePurchaser;
    targetOrderId;

    //internal attributes
    isScriptLoaded = false;
    isInitSuccess = false;
    loadedLists = 0;

    //wire attribute
    communityInfoWireResult;
    communityInfoResponse;

    pageRef;

    //labels
    label = customLabels;

    //js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'tooltips'
    modules = [];

    /**
     * @descripton connected callback
     */
    connectedCallback() {
        
    }

    /**
    * @descripton library loader
    */
    handleLibLoadSuccess(event) {
        this.isScriptLoaded = true;
        this.isInitSuccess = true;

        if (this.paramOrderId) {
            this.targetOrderId = this.paramOrderId;
        } else if (this.pageRef?.attributes?.orderId) {
            this.targetOrderId = this.pageRef.attributes.orderId;
        } else if (this.recordId) {
            this.targetOrderId = this.recordId;
        } else {
            this.targetOrderId = null;
        }

        this.checkOrder();

    }

    /**
     * @descripton library loader
    */
    handleLibLoadFail(event) {
        this.isScriptLoaded = true;
        this.isInitSuccess = false;
    }

    @wire(getCommunityInfo, {})
    wiredCommunityInfo(result) {
        this.communityInfoWireResult = result;

        if (result.data) {
            this.communityInfoResponse = JSON.parse(result.data.responseData);
            this.consoleLog(this.communityInfoResponse, true);

        } else if (result.error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    @wire(CurrentPageReference)
    wiredPageRef(result) {
        this.pageRef = result;

        this.consoleLog(this.pageRef, true);
    }
    
    /**
     * @description Return true to show modal title and icon
     */
    get showModalHeader(){
        if(this.titleLabel){
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
     * @description This method is used to check wheter it is a company order or not
     */
    checkOrder() {
        this.toggleSpinner(1);

        checkCompanyOrder({ contactId: null })
            .then(result => {
                if (result.isSuccess) {
                    this.toggleSpinner(-1);
                    this.isCorporatePurchaser = result.message === 'true' ? true : false;
                } else {
                    if (result.message) {
                        promptError(this.label.ERROR_LABEL, result.message);
                    } else {
                        promptError(this.label.ERROR_LABEL, this.label.UNKNOWN_EXCEPTIONS_LABEL);
                    }
                }
            }).catch(error => {
                promptError(this.label.ERROR_LABEL, getErrorMessage(error));
            })
    }

    /**
     * @description This method is used to handle the payment type selection
     */
    handlePaymentType(event) {
        if (event.target.value === 'type-credit') {
            this.creditselect = true;
            this.creditCompany = false;
        } else {

            this.creditCompany = true;
            this.creditselect = false;
        }
    }



    /**
    * @description This method is used to handle cancel button.
    */
    handleCancelHandler() {
        let sitePageName = this.cancelRedirectionPageName !== null ? this.cancelRedirectionPageName : '';
        this.navigateToSitePage(sitePageName);
    }

    /**
    * @description This method is used to handle pay button.
    */
    handlePayHandler() {
        if (this.creditCompany) {
            this.toggleSpinner(1);
            updateCompanyOrder({ currentOrderId: this.targetOrderId, orderSubmittedStatus: this.orderSubmittedStatus })
                .then(result => {
                    if (result.isSuccess) {
                        this.toggleSpinner(-1);
                        promptSuccess(this.label.SUCCESS_LABEL, this.rioOrderUpdatedSuccessMessage);
                        let sitePageName = this.companyOrderPaymentRedirectionPage !== null ? this.companyOrderPaymentRedirectionPage : '';
                        this.navigateToSitePage(sitePageName);
                    } else {
                        if (result.message) {
                            promptError(this.label.ERROR_LABEL, result.message);
                        } else {
                            promptError(this.label.ERROR_TITLE, this.label.UNKNOWN_EXCEPTIONS_LABEL);
                        }

                    }
                }).catch(error => {
                    if (error) {
                        this.toggleSpinner(1);
                        promptError(this.label.ERROR_LABEL, getErrorMessage(error));

                    }
                })
        } else if (this.creditselect) {
            let sitePageName = this.creditCardPaymentRedirectionPage !== null ? this.creditCardPaymentRedirectionPage : '';
            this.navigateToSitePage(sitePageName);
        } else {
            promptError(this.label.ERROR_LABEL, this.paymentErrorMessage);
        }
    }

    /**
     * @description Navigate to the page given
     * @param {String} sitePageName 
     */
    navigateToSitePage(sitePageName) {

        let navigationUrl;
        let pageReference = {};
        let pageRefAttr = {};

        if (sitePageName) {
            sitePageName = sitePageName.replace('{orderId}', this.targetOrderId);

            if (sitePageName.startsWith('http://') || sitePageName.startsWith('https://')) {
                navigationUrl = sitePageName;
                pageReference.type = 'standard__webPage'
                pageRefAttr = { url: navigationUrl };
            } else {
                if (this.isCommunity) {
                    //for community
                    pageReference.type = 'comm__namedPage';
                    pageRefAttr = { pageName: sitePageName};
                    pageReference.state = {'orderId' : this.targetOrderId};

                } else {
                    //for internal, we expect the lightning page to have a tab in order to navigate to the page successfully
                    //the query string will also have namespace or use c__orderId, otherwise it will fail
                    pageReference.type = 'standard__navItemPage';
                    pageRefAttr = { apiName: sitePageName};
                    pageReference.state = {'reduivy__orderId' : this.targetOrderId};
                }                
            }
        } else {
            pageReference.type = 'standard__recordPage';
            pageRefAttr = {
                recordId: this.targetOrderId,
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
        logInfo('ContinuingEduCartPayment', anything, this.enableDebugMode, isJson);
    }

}