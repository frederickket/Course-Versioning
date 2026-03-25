/**
 * @author      WDCi (Lean)
 * @date        Mar 2024
 * @group       Administration
 * @description Admin console for RIO Education V4
 * @changehistory
 * ISS-001858 22-03-2024 Lean - new class
 * ISS-002574 04-08-2025 Lean - Decommission the applicant license type count
 */
import { LightningElement, api, wire, track } from 'lwc';
import { promptInfo, promptError, promptWarning, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';
import { customLabels } from 'c/labelLoader';

import LICENSE_FIELD_NAME_LABEL from '@salesforce/label/c.License_Name';
import LICENSE_FIELD_TOTAL_LABEL from '@salesforce/label/c.License_Total';
import LICENSE_FIELD_USED_LABEL from '@salesforce/label/c.License_Used';
import LICENSE_FIELD_REMAINING_LABEL from '@salesforce/label/c.License_Remaining';
import LICENSE_TYPE_ADMIN_LABEL from '@salesforce/label/c.License_Type_Admin';
import LICENSE_TYPE_FACULTY_LABEL from '@salesforce/label/c.License_Type_Faculty';
import LICENSE_TYPE_STUDENT_LABEL from '@salesforce/label/c.License_Type_Student';
import USER_LICENSES_LABEL from '@salesforce/label/c.User_Licenses';

//refresh module
import { RefreshEvent, registerRefreshHandler, unregisterRefreshHandler } from 'lightning/refresh';

//Apex methods
import ctrlGetLicensesInfo from '@salesforce/apex/REDU_IvyAppConsole_LCTRL.getLicensesInfo';
import ctrlInitLicenseJob from '@salesforce/apex/REDU_IvyAppConsole_LCTRL.initLicenseJob';

export default class IvyAppConsole extends LightningElement {
	
	//configurable attributes
    @api modalTitle = 'RIO - App Settings';
    @api modalIconName = 'standard:work_contract';
	@api enableDebugMode = false;
	
	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false;
	loadedLists = 0;
	
    adminLicenseInfo;
    studentLicenseInfo;
    facultyLicenseInfo;

    //refresh handler
    refreshHandlerID;

	//labels
	label = {
        ...customLabels,
        LICENSE_FIELD_NAME_LABEL,
        LICENSE_FIELD_REMAINING_LABEL,
        LICENSE_FIELD_TOTAL_LABEL,
        LICENSE_FIELD_USED_LABEL,
        LICENSE_TYPE_ADMIN_LABEL,
        LICENSE_TYPE_FACULTY_LABEL,
        LICENSE_TYPE_STUDENT_LABEL,
        USER_LICENSES_LABEL
    };
	
	//js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'tooltips'
    modules = ['noheadercss'];
	
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
		this.refreshHandlerID = registerRefreshHandler(this, this.getLicenseUsageInfo);

        this.initSchedJob();
        this.getLicenseUsageInfo();
	}
	
    /**
     * @descripton disconnected callback
     */
	disconnectedCallback() {
		unregisterRefreshHandler(this.refreshHandlerID);
	}

    /**
     * @description Get user license usage
     */
    getLicenseUsageInfo() {
        this.consoleLog('getLicenseUsageInfo');

        this.getAdminLicenseUsage();
        this.getFacultyLicenseUsage();
        this.getStudentLicenseUsage();
    }

    /**
     * @description Get admin license usage
     */
    getAdminLicenseUsage() {

        this.toggleSpinner(1);

        ctrlGetLicensesInfo({
            licenseType: 'REDU_Admin'
        })
        .then(result => {
            let licenseInfoObj = JSON.parse(result.responseData);
            this.adminLicenseInfo = licenseInfoObj;

            this.toggleSpinner(-1);
        })
        .catch(error => {
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
            this.toggleSpinner(-1);
        });

    }

    /**
     * @description Get student license usage
     */
    getStudentLicenseUsage() {

        this.toggleSpinner(1);

        ctrlGetLicensesInfo({
            licenseType: 'REDU_Student'
        })
        .then(result => {
            let licenseInfoObj = JSON.parse(result.responseData);
            this.studentLicenseInfo = licenseInfoObj;
            
            this.toggleSpinner(-1);
        })
        .catch(error => {
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
            this.toggleSpinner(-1);
        });

    }

    /**
     * @description Get faculty license usage
     */
    getFacultyLicenseUsage() {

        this.toggleSpinner(1);

        ctrlGetLicensesInfo({
            licenseType: 'REDU_Faculty'
        })
        .then(result => {
            let licenseInfoObj = JSON.parse(result.responseData);
            this.facultyLicenseInfo = licenseInfoObj;
            
            this.toggleSpinner(-1);
        })
        .catch(error => {
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
            this.toggleSpinner(-1);
        });

    }

    /**
     * @descripton Init license schedule job
     */
    initSchedJob() {
        this.toggleSpinner(1);

        try {
            
            ctrlInitLicenseJob({})
            .then(result => {
                this.toggleSpinner(-1);
            })
            .catch(error => {
                promptError(this.label.ERROR_LABEL, getErrorMessage(error));
                this.toggleSpinner(-1);
                
            })            

        } catch (error) {
            this.toggleSpinner(-1);
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
        }
    }

    /**
     * @description Handle refresh button
     */
    handleRefreshOnclick(event) {
        this.getLicenseUsageInfo();
    }

    /**
     * @description Return total licenses that the customer has subscribed for admin user
     */
    get adminTotalLicenses() {

        if (this.adminLicenseInfo && this.adminLicenseInfo.totalLicenses != null) {
            return this.adminLicenseInfo.totalLicenses;
        }

        return 0;
    }

    /**
     * @description Return total licenses that the customer has used for admin user
     */
    get adminUsedLicenses() {
        if (this.adminLicenseInfo && this.adminLicenseInfo.usedLicenses != null) {
            return this.adminLicenseInfo.usedLicenses;
        }

        return 0;
    }

    /**
     * @description Return the remaining licenses for admin user
     */
    get adminRemainingLicenses() {
        return this.calculateRemaining(this.adminTotalLicenses, this.adminUsedLicenses);
    }

    /**
     * @description Return total licenses that the customer has subscribed for student user
     */
    get studentTotalLicenses() {
        if (this.studentLicenseInfo && this.studentLicenseInfo.totalLicenses != null) {
            return this.studentLicenseInfo.totalLicenses;
        }

        return 0;
    }

    /**
     * @description Return total licenses that the customer has used for student user
     */
    get studentUsedLicenses() {
        if (this.studentLicenseInfo && this.studentLicenseInfo.usedLicenses != null) {
            return this.studentLicenseInfo.usedLicenses;
        }

        return 0;
    }

    /**
     * @description Return the remaining licenses for student user
     */
    get studentRemainingLicenses() {
        return this.calculateRemaining(this.studentTotalLicenses, this.studentUsedLicenses);
    }

    /**
     * @description Return total licenses that the customer has subscribed for faculty user
     */
    get facultyTotalLicenses() {
        if (this.facultyLicenseInfo && this.facultyLicenseInfo.totalLicenses != null) {
            return this.facultyLicenseInfo.totalLicenses;
        }

        return 0;
    }

    /**
     * @description Return total licenses that the customer has used for faculty user
     */
    get facultyUsedLicenses() {
        if (this.facultyLicenseInfo && this.facultyLicenseInfo.usedLicenses != null) {
            return this.facultyLicenseInfo.usedLicenses;
        }

        return 0;
    }

    /**
     * @description Return the remaining licenses for faculty user
     */
    get facultyRemainingLicenses() {
        return this.calculateRemaining(this.facultyTotalLicenses, this.facultyUsedLicenses);
    }

    calculateRemaining(licenseTotal, licenseUsed) {
        if (licenseTotal && licenseTotal >= 0) {
            return licenseTotal - licenseUsed;
        }

        return 0 - licenseUsed;
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
        logInfo('IvyAppConsole', anything, this.enableDebugMode, isJson);
    }
	
}