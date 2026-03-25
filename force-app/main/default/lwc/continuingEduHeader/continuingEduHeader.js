/**
 * @Author 		WDCi (Jordan)
 * @Date 		Feb 2024
 * @group 		Continuing Education
 * @Description Lwc for continuing education header
 * @changehistory
 * ISS-001846 21-02-2024 Jordan - new lwc
 */

import { LightningElement, api, wire, track } from 'lwc';
import { promptInfo, promptError, promptWarning, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';
import { NavigationMixin } from 'lightning/navigation';
import { customLabels } from 'c/labelLoader';
import isGuest from '@salesforce/user/isGuest';

//Apex methods
import getRecordInfo from '@salesforce/apex/REDU_ContinuingEduHeader_LCTRL.getRecordInfo';
import getCommunityInfo from '@salesforce/apex/REDU_ContinuingEduCartPayment_LCTRL.getCommunityInfo';

import continuingEduRegistrationModal from 'c/continuingEduRegistrationModal';

export default class ContinuingEduHeader extends NavigationMixin(LightningElement) {
    //configurable attributes
    @api objectApiName;
    @api recordId;
    
    @api titleFieldApiName;
    @api imageFieldApiName;

    @api detailShowIcon;
    @api detailIconName;
    @api detailShowTitle;
    @api detailTitle;
    @api detailFieldNames;
    @api detailShowFieldLabel;

    @api backButtonLabel;
    @api backButtonSitePageName;

    @api registrationUrl;
    @api guestRegistrationText;
    @api nonGuestRegistrationText;
    @api guestRegistrationButtonLabel;
    @api nonGuestRegistrationButtonLabel;
    @api allowGuestRegistrationFieldApiName;
    
    @api registerButtonLabel;
    @api registerButtonConditionFieldApiName;

    @api enableDebugMode = false;

    //internal attributes
	isScriptLoaded = false;
	isInitSuccess = false;
	loadedLists = 0;

    @track mainData;

    //wire attribute
    communityInfoWireResult;
    communityInfoResponse;

    //labels
	label = {
        ...customLabels
    };
	
	//js library module 'lodash', 'stringutil', 'noheadercss', 'continuingeducss', 'moment', 'fullcalendar', 'fcmoment', 'tooltips'
    modules = ['continuingeducss'];

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
        this.consoleLog(this.objectApiName);
        this.consoleLog(this.recordId);

        this.loadRecordInfo();
	}
	
    /**
     * @descripton disconnected callback
     */
	disconnectedCallback() {
        
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

    /**
     * @description Return domain url
     */
    get sitePathPrefix() {
        return this.communityInfoResponse?.sitePathPrefix;
    }

    /**
     * @description Return login url
     */
    get loginUrl() {
        return this.communityInfoResponse?.loginUrl;
    }

    /**
     * @description Return true if current context is community
     */
    get isCommunity() {
        return this.communityInfoResponse?.isCommunity;
    }

    /**
     * @description Return registration url for login's startUrl
     */
    get registerFlowUrl() {
        this.consoleLog('get registerFlowUrl');
        
        let flowUrl;
        if (this.registrationUrl) {
            if ((this.registrationUrl.startsWith('http://') || this.registrationUrl.startsWith('https://'))) {
                flowUrl = this.registrationUrl;
            } else {
                flowUrl = this.sitePathPrefix + '/' + this.registrationUrl;
            }

            if (flowUrl.includes('{!recordId}')) {
                flowUrl = flowUrl.replace('{!recordId}', this.recordId);
            } else if (!flowUrl.includes(this.recordId)) {
                if (flowUrl.includes('?')) {
                    flowUrl = flowUrl + '&studyOfferingId=' + this.recordId;
                } else {
                    flowUrl = flowUrl + '?studyOfferingId=' + this.recordId;
                }
            }
        }

        this.consoleLog(flowUrl);

        return flowUrl;
    }

    /**
     * @description Handle back button click
     */
    handleBackButtonClick() {
        this.navigateToSitePage(this.backButtonSitePageName);
    }

    loadRecordInfo() {
        this.consoleLog('loadRecordInfo');

        try {
            this.toggleSpinner(1);

            getRecordInfo({ 
                sObjectName: this.objectApiName, 
                recordId: this.recordId, 
                titleFieldApiName: this.titleFieldApiName, 
                imageFieldApiName: this.imageFieldApiName, 
                allowGuestRegistrationFieldApiName: this.allowGuestRegistrationFieldApiName, 
                registerButtonConditionFieldApiName: this.registerButtonConditionFieldApiName 
            }).then(result => {
                this.toggleSpinner(-1);

                if (result.isSuccess && result.responseData) {

                    let responseData = JSON.parse(result.responseData);
                    let data = responseData.records[0];

                    this.mainData = data;

                    this.consoleLog(this.mainData, true);

                } else if (!result.isSuccess) {
                    promptError(this.label.ERROR_LABEL, result.message);
                }

            }).catch((error) => {
                this.toggleSpinner(-1);
                promptError(this.label.ERROR_LABEL, getErrorMessage(error));
            })
        } catch (error) {
            this.toggleSpinner(-1);
        }
    }

    get ceRecordId() {

        if (this.mainData && this.mainData.Id) {
            return this.mainData.Id;
        }

        return null;
    }

    get ceRecordTitle() {

        if (this.titleFieldApiName && this.mainData && this.mainData[this.titleFieldApiName]) {
            return this.mainData[this.titleFieldApiName];
        }

        return null;
    }

    get ceRecordImageUrl() {

        if (this.imageFieldApiName && this.mainData && this.mainData[this.imageFieldApiName]) {
            return this.mainData[this.imageFieldApiName];
        }

        return null;
    }

    get ceRecordAllowGuestRegistrations() {

        if (this.allowGuestRegistrationFieldApiName && this.mainData && this.mainData[this.allowGuestRegistrationFieldApiName]) {
            return this.mainData[this.allowGuestRegistrationFieldApiName];
        }

        return null;
    }

    get ceRecordDisableRegisterButton() {

        if (this.registerButtonConditionFieldApiName && this.mainData && this.mainData[this.registerButtonConditionFieldApiName]) {
            return this.mainData[this.registerButtonConditionFieldApiName];
        }

        return null;
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
        logInfo('ContinuingEduListing', anything, this.enableDebugMode, isJson);
    }

    handleRegister() {
        if (isGuest) {
            continuingEduRegistrationModal.open({
                size: 'small',
                guestRegistrationText: this.guestRegistrationText,
                nonGuestRegistrationText: this.nonGuestRegistrationText,
                guestRegistrationButtonLabel: this.guestRegistrationButtonLabel,
                nonGuestRegistrationButtonLabel: this.nonGuestRegistrationButtonLabel,
                allowGuestRegistrations: this.ceRecordAllowGuestRegistrations,
                recordName: this.ceRecordTitle,
                enableDebugMode: this.enableDebugMode
            }).then((result) => {

                if (result) {
                    this.consoleLog('continuingEduRegistrationModal.close');
                    this.consoleLog(result, true);
    
                    const {operation} = result;
    
                    if (operation === 'loginAsUser') {
                        let siteLoginUrl = this.loginUrl + '?startURL=' + encodeURIComponent(this.registerFlowUrl);
                        
                        this.consoleLog(siteLoginUrl);

                        //use window.open to retain the query parameter as the navigation.mixin will remove it
                        window.open(siteLoginUrl, '_self');
                        
                    } else if (operation === 'continueAsGuest') {
                        this.navigateToSitePage(this.registrationUrl);
                    }
                }
            });
        } else {
            this.navigateToSitePage(this.registrationUrl);
        }
    }
    
    /*navigateToWebPage(URL) {
        // Navigate to a URL
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: URL
            }
        },
            true
        );
    }*/

    /**
     * @description Navigate to the page given
     * @param {String} sitePageName 
     */
    navigateToSitePage(sitePageName) {

        let navigationUrl;
        let pageReference = {};
        let pageRefAttr = {};

        if (sitePageName) {
            sitePageName = sitePageName.replace('{!recordId}', this.recordId);

            if (sitePageName.startsWith('http://') || sitePageName.startsWith('https://')) {
                navigationUrl = sitePageName;
                pageReference.type = 'standard__webPage'
                pageRefAttr = { url: navigationUrl };
            } else {
                if (this.isCommunity) {
                    //for community
                    pageReference.type = 'comm__namedPage';
                    pageRefAttr = { pageName: sitePageName};
                    pageReference.state = {'studyOfferingId' : this.recordId};

                } else {
                    //for internal, we expect the lightning page to have a tab in order to navigate to the page successfully
                    //the query string will also have namespace or use c__orderId, otherwise it will fail
                    pageReference.type = 'standard__navItemPage';
                    pageRefAttr = { apiName: sitePageName};
                    pageReference.state = {'reduivy__studyOfferingId' : this.recordId};
                }                
            }
        } else {
            pageReference.type = 'standard__recordPage';
            pageRefAttr = {
                recordId: this.recordId,
                objectApiName: 'reduivy__Study_Offering__c',
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
}