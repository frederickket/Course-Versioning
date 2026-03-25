/**
 * @Author 		WDCi (XiRouh)
 * @Date 		Jan 2025
 * @group 		
 * @Description 
 * @changehistory
 * ISS-002229 27-02-2025 XiRouh - initial version
 * ISS-002547 10-07-2025 Lean - support job queue group
 * ISS-002736 25-11-2025 XiRouh - Added tableTextDisplayMode configurable attribute
 */
import { LightningElement, api, wire, track } from 'lwc';
import { promptError, promptSuccess, promptWarning } from 'c/toasterUtil';
import { getErrorMessage, logInfo } from 'c/loggingUtil';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';

import JQH_OBJECT from '@salesforce/schema/Job_Queue__c';

import newJobModal from 'c/termStudentEnrollmentModal';
import enrollmentHelpModal from 'c/termStudentEnrollmentHelpModal';
import cancelJobConfirmationModal from 'c/jqhCancelJobConfirmationModal';
import retryJobConfirmationModal from 'c/jqhRetryJobConfirmationModal';
import clearAllJobsConfirmationModal from 'c/jqhClearJobsConfirmationModal';

//Labels
import { customLabels } from 'c/labelLoader';
import TERM_STUDENT_ENROLLMENT_WIZARD_NAME from '@salesforce/label/c.Auto_Student_Enrollment';
import TERM_STUDENT_ENROLLMENT_WIZARD_TEXT1 from '@salesforce/label/c.Term_Student_Enrollment_Wizard_Text_1';
import TERM_STUDENT_ENROLLMENT_WIZARD_TEXT2 from '@salesforce/label/c.Term_Student_Enrollment_Wizard_Text_2';
import TERM_STUDENT_ENROLLMENT_WIZARD_TEXT3 from '@salesforce/label/c.Term_Student_Enrollment_Wizard_Text_3';
import SHOW_MENU_LABEL from '@salesforce/label/c.Show_Menu';
import CANCEL_JOB_LABEL from '@salesforce/label/c.Job_Cancel_Confirmation';
import RETRY_JOB_LABEL from '@salesforce/label/c.Job_Retry_Confirmation';
import NO_JOBS_SELECTED_LABEL from '@salesforce/label/c.No_Jobs_Selected';
import NO_RECORD_TO_DISPLAY_LABEL from '@salesforce/label/c.No_Records_To_Display';
import CLEAR_ALL_JOBS_LABEL from '@salesforce/label/c.Clear_All_Jobs_Confirmation';

import ctrlGetJobQueueData from '@salesforce/apex/REDU_TermStudentEnrollment_LCTRL.getJobQueueData';

export default class TermStudentEnrollment extends LightningElement {
	
	//configurable attributes
    @api recordId;
    @api modalTitle = '';
    @api modalIconName = 'standard:sales_path';
    @api jobQueueTableMaxHeight;

    @api studyIntakeSelectionTableFields;
    @api eligibleStudentCountTableStudyIntakeField;
    @api existingIndividualEnrollmentStatuses;
    @api jobQueueFields;
    @api jobQueueStatuses;
    @api jobOperation;

    @api tableTextDisplayMode;
    
	@api enableDebugMode;

	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false
	loadedLists = 0;

	//label
	label = {
        TERM_STUDENT_ENROLLMENT_WIZARD_NAME,
        TERM_STUDENT_ENROLLMENT_WIZARD_TEXT1,
        TERM_STUDENT_ENROLLMENT_WIZARD_TEXT2,
        TERM_STUDENT_ENROLLMENT_WIZARD_TEXT3,
        SHOW_MENU_LABEL,
        CANCEL_JOB_LABEL,
        RETRY_JOB_LABEL,
        NO_JOBS_SELECTED_LABEL,
        NO_RECORD_TO_DISPLAY_LABEL,
        CLEAR_ALL_JOBS_LABEL,
        ...customLabels
    };
       
    modules = ['stringutil'];

    DROP_DOWN_EVENT_CANCEL_JOB = "canceljob";
    DROP_DOWN_EVENT_RETRY_JOB = "retryjob";
    DROP_DOWN_EVENT_REFRESH = "refresh";
    DROP_DOWN_EVENT_HELP = "help";
    DROP_DOWN_EVENT_CLEAR_ALL_JOBS = "clearAllJobs"

    selectedJobQueueIds = [];
    jobQueueGroupRecords = [];
    
	/**
     * @descripton library loader
     */
    handleLibLoadSuccess(event) {
        this.isScriptLoaded = true;
        this.isInitSuccess = true;

        if (this.recordId){
            this.getJobData();
        }
    }

    /**
     * @descripton library loader
     */
    handleLibLoadFail(event) {
        this.isScriptLoaded = true;
        this.isInitSuccess = false;
    }

    //wired object
    @wire(getObjectInfo, {objectApiName: JQH_OBJECT})
    jqhObjInfo;

    /**
     * @descripton Find all relevant jobs to the current term
     */
    getJobData(){

        //Call Apex
        this.toggleSpinner(1);

        ctrlGetJobQueueData({
            jobOperation: this.jobOperation,
            termId: this.recordId,
            jobQueueGroupFields: this.jobQueueFields,
            jobQueueGroupStatuses: this.jobQueueStatuses
        })
        .then(result => {          
            this.selectedJobQueueIds = [];

            if (result.responseData) {
                const returnedResult = JSON.parse(result.responseData);

                this.jobQueueGroupRecords = returnedResult?.jobQueueGroupRecords;
    
            } else if (result.error) {
                promptError(this.label.ERROR_LABEL, getErrorMessage(result.error));
            }

            this.toggleSpinner(-1);
        })
        .catch(error => {
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
            this.toggleSpinner(-1);
        });
    }


    /**
     * @description Handler for dropdown menu
     * @param {@} event 
     */
    handleMenuSelect(event){

        let selectedMenu = event.detail.value;

        switch (selectedMenu) {
            case this.DROP_DOWN_EVENT_CANCEL_JOB:
                this.handleCancelClick();
                break;

            case this.DROP_DOWN_EVENT_RETRY_JOB:
                this.handleRetryClick();
                break;

            case this.DROP_DOWN_EVENT_REFRESH:
                this.handleRefreshClick();
                break;

            case this.DROP_DOWN_EVENT_CLEAR_ALL_JOBS:
                this.handleClearAllJobsClick()
                break;

            case this.DROP_DOWN_EVENT_HELP:
                this.handleHelpClick();
                break;

            default:
                break;
        }
    }

    /**
     * @description Open window to start new job
     */
    handleNewClick() {
        newJobModal.open({
            size: 'small',
            recordId: this.recordId,
            jobOperation: this.jobOperation,
            modalTitle: this.modalTitle,
            modalIconName: this.modalIconName,
            studyIntakeSelectionTableFields: this.studyIntakeSelectionTableFields,
            eligibleStudentCountTableStudyIntakeField: this.eligibleStudentCountTableStudyIntakeField,
            existingIndividualEnrollmentStatuses: this.existingIndividualEnrollmentStatuses,
            tableTextDisplayMode: this.tableTextDisplayMode,
            enableDebugMode: this.enableDebugMode
        }).then(result=>{
            if(result !== 'cancel') {
                this.getJobData();
            }
        })
        .catch(error => {
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
        });
    }

    /**
     * @descripton Handle cancel job click
     */
    handleCancelClick() {
        if (this.selectedJobQueueIds.length === 0){
            promptWarning(this.label.NO_JOBS_SELECTED_LABEL);
        } else {
            cancelJobConfirmationModal.open({
                size: 'small',
                jobQueueIds: this.selectedJobQueueIds,
                enableDebugMode: this.enableDebugMode
            }).then(result=>{
                if(result !== 'cancel') {
                    this.getJobData();
                }
            })
            .catch(error => {
                promptError(this.label.ERROR_LABEL, getErrorMessage(error));
            });
        }
    }

    /**
     * @description Handle retry job click
     */
    handleRetryClick() {
        if (this.selectedJobQueueIds.length === 0){
            promptWarning(this.label.NO_JOBS_SELECTED_LABEL);
        } else {
            retryJobConfirmationModal.open({
                size: 'small',
                jobQueueIds: this.selectedJobQueueIds,
                enableDebugMode: this.enableDebugMode
            }).then(result=>{
                if(result !== 'cancel') {
                    this.getJobData();
                }
            })
            .catch(error => {
                promptError(this.label.ERROR_LABEL, getErrorMessage(error));
            });
        }
    }

    handleClearAllJobsClick() {
        clearAllJobsConfirmationModal.open({
            size: 'small',
            jobOperation: this.jobOperation,
            recordId: this.recordId,
            enableDebugMode: this.enableDebugMode
        }).then(result=>{
            if(result !== 'cancel') {
                this.getJobData();
            }
        })
        .catch(error => {
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
        });
    }

    /**
     * @description Refresh list of records in the table
     */
    handleRefreshClick(){
        this.getJobData();
    }

    /**
     * @description Launch help modal
     */
    handleHelpClick(){
        enrollmentHelpModal.open({
            enableDebugMode: this.enableDebugMode
        }).then(result=>{
            
        });
    }

    /**
     * @description handle job queue row select
     */
    handleJobQueueRowSelect(event){
        const selectedRows = event.detail.selectedRows;

        this.selectedJobQueueIds = selectedRows.map(row => row.Id);
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
     * @description Return sObject Label
     */
    get jqhObjectLabel() {
        return this.jqhObjInfo?.data?.labelPlural;
    }

    /**
     * @description Return noRecordToDisplay label
     */
    get noRecordToDisplayLabel() {
        return this.label.NO_RECORD_TO_DISPLAY_LABEL;
    }

    /**
     * @description Return termStudentEnrollmentWizardText1 label
     */
    get termStudentEnrollmentWizardText1() {
        return this.label.TERM_STUDENT_ENROLLMENT_WIZARD_TEXT1.format([this.label.TERM_STUDENT_ENROLLMENT_WIZARD_NAME]);
    }

    /**
     * @description Return termStudentEnrollmentWizardText2 label
     */
    get termStudentEnrollmentWizardText2() {
        return this.label.TERM_STUDENT_ENROLLMENT_WIZARD_TEXT2;
    }

    /**
     * @description Return termStudentEnrollmentWizardText3 label
     */
    get termStudentEnrollmentWizardText3() {
        return this.label.TERM_STUDENT_ENROLLMENT_WIZARD_TEXT3.format([this.label.TERM_STUDENT_ENROLLMENT_WIZARD_NAME]);
    }

    /**
     * @description Return new label
     */
    get newLabel() {
        return this.label.NEW_LABEL;
    }

    /**
     * @description Return show menu label
     */
    get showMenuLabel() {
        return this.label.SHOW_MENU_LABEL;
    }

    /**
     * @description Return cancel job label
     */
    get cancelJobLabel() {
        return this.label.CANCEL_JOB_LABEL;
    }

    /**
     * @description Return retry job label
     */
    get retryJobLabel() {
        return this.label.RETRY_JOB_LABEL;
    }

    /**
     * @description Return refresh label
     */
    get refreshLabel() {
        return this.label.REFRESH_LABEL;
    }

    /**
     * @description Return help label
     */
    get helpLabel() {
        return this.label.HELP_LABEL;
    }

    get clearAllJobsLabel() {
        return this.label.CLEAR_ALL_JOBS_LABEL;
    }

    /**
     * @description Return loading label
     */
    get loadingLabel() {
        return this.label.LOADING_LABEL;
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
        logInfo('TermStudentEnrollment', anything, this.enableDebugMode, isJson);
    }
	
}