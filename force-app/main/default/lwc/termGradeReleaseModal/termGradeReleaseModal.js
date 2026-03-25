/**
 * @Author 		WDCi (XiRouh)
 * @Date 		March 2025
 * @group 		Term Grade Release
 * @Description 
 * @changehistory
 * ISS-002311 04-03-2025 XiRouh - initial version
 * ISS-002736 25-11-2025 XiRouh - Added tableTextDisplayMode configurable attribute
 */
import { api, wire, track } from 'lwc';
import LightningModal from 'lightning/modal';

import { promptError, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo } from 'c/loggingUtil';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import { setupPicklistOptionsFromRecords } from 'c/lwcUtil';

import STUDY_UNIT_OBJECT from '@salesforce/schema/Study_Unit__c';
import STUDY_OFFERING_OBJECT from '@salesforce/schema/Study_Offering__c';
import INDIVIDUAL_ENROLLMENT_OBJECT from '@salesforce/schema/Individual_Enrollment__c';
import IEN_GRADE_RELEASE_STATUS_FIELD from '@salesforce/schema/Individual_Enrollment__c.Grade_Release_Status__c'

//Labels
import { customLabels } from 'c/labelLoader';
import MODAL_SUB_TITLE from '@salesforce/label/c.Term_Grade_Release_Sub_Title';
import STUDY_UNIT_SELECTION_SCREEN_DESCRIPTION from '@salesforce/label/c.Term_Grade_Release_Selection_Screen_Description';
import CAMPUS_COMBOBOX_LABEL from '@salesforce/label/c.Term_Grade_Release_Campus_Combobox_Label';
import CAMPUS_COMBOBOX_HELPTEXT from '@salesforce/label/c.Term_Grade_Release_Campus_Combobox_Helptext';
import MESSAGE_WHEN_COMBOBOX_NOT_SELECTED from '@salesforce/label/c.Complete_This_Field';
import CAMPUS_COMMON_TERM from '@salesforce/label/c.Campus'
import SELECTION_TYPE_HELP_TEXT from '@salesforce/label/c.Term_Grade_Release_Selection_Type_Help_Text'
import SELECTION_TYPE_COMBOBOX_LABEL from '@salesforce/label/c.Term_Grade_Release_Selection_Type_Combobox_Label'
import MANUAL_SELECTION_LABEL from '@salesforce/label/c.Term_Grade_Release_Manual_Selection'
import NO_RECORD_TO_DISPLAY_LABEL from '@salesforce/label/c.No_Records_To_Display';
import GRADE_RELEASE_STATUSES_SELECTION_COMBOBOX_LABEL from '@salesforce/label/c.Term_Grade_Release_Grade_Release_Statuses_Combobox_Label';
import QUEUE_JOB_SUBMITTED_MSG from '@salesforce/label/c.Queue_Job_Submitted_Message';
import GRADE_RELEASE_STATUSES_SELECTION_COMBOBOX_HELPTEXT from '@salesforce/label/c.Term_Grade_Release_Grade_Release_Statuses_Combobox_Helptext';
import ACADEMIC_TERM_COMMON_TERM from '@salesforce/label/c.Academic_Term'

import RECORD_COUNT_DETAIL from '@salesforce/label/c.Term_Grade_Release_Summary_Record_Count_Detail'
import SUMMARY_DETAILS from '@salesforce/label/c.Term_Grade_Release_Summary'
import FINAL_CONFIRMATION from '@salesforce/label/c.Term_Grade_Release_Final_Confirmation'

import PROGRESS_INDICATOR_STEP_ONE_LABEL from '@salesforce/label/c.Term_Grade_Release_Progress_Indicator_Step_One_Label';
import PROGRESS_INDICATOR_STEP_TWO_LABEL from '@salesforce/label/c.Term_Grade_Release_Progress_Indicator_Step_Two_Label';
import PROGRESS_INDICATOR_STEP_THREE_LABEL from '@salesforce/label/c.Term_Grade_Release_Progress_Indicator_Step_Three_Label';
import PROGRESS_INDICATOR_STEP_FOUR_LABEL from '@salesforce/label/c.Term_Grade_Release_Progress_Indicator_Step_Four_Label';

import ctrlGetStudyTermDetails from '@salesforce/apex/REDU_TermGradeReleaseModal_LCTRL.getStudyTermDetails';
import ctrlGetComboboxesOptions from '@salesforce/apex/REDU_TermGradeReleaseModal_LCTRL.getComboboxesOptions';
import ctrlGetStudyUnitData from '@salesforce/apex/REDU_TermGradeReleaseModal_LCTRL.getStudyUnitData';
import ctrlGetStudyOfferingData from '@salesforce/apex/REDU_TermGradeReleaseModal_LCTRL.getStudyOfferingData';
import ctrlInitQueueJob from '@salesforce/apex/REDU_TermGradeReleaseModal_LCTRL.initQueueJob';

export default class TermGradeReleaseModal extends LightningModal {
    //Configurable attributes
    @api recordId;
    @api modalTitle;

    @api studyUnitFields;
    @api studyUnitTableMaxHeight;

    @api studyOfferingStatuses;
    @api studyOfferingFields;
    @api studyOfferingTableMaxHeight;

    @api jobOperation;

    //ISS-002736
    @api tableTextDisplayMode;
    
    @api enableDebugMode;

    //internal attributes
    isScriptLoaded = false;
    isInitSuccess = false
    loadedLists = 0;
        
    modules = ['stringutil'];

    //To control screen
    isStudyUnitScreen = true;
    isStudyOfferingScreen = false;
    isGradeReleaseStatusesSelectionScreen = false;

    //Wired responses
    //Study term details
    termWiredResult;

    //campus combobox
    wiredComboboxResponseData;
    selectedCampusId;
    selectedCampusLabel;
    CAMPUS_COMBOBOX_FIELD_NAME = 'campusId';

    //Datatable
    studyUnitRecords;
    studyOfferingRecords;

    manualSelectedStudyUnitIds = [];
    manualSelectedStudyUnitLabels = [];

    manualSelectedStudyOfferingIds = [];

    //Grade Release Status Combobox
    @track selectedGradeReleaseStatus;

    //Selection Type Combobox
    ALL_SELECTION = "all";
    MANUAL_SELECTION = "manual";

    selectionTypeOptions = [
        {label: customLabels.ALL_LABEL, value: this.ALL_SELECTION},
        {label: MANUAL_SELECTION_LABEL, value: this.MANUAL_SELECTION}
    ];

    studyUnitSelectedSelectionType = this.ALL_SELECTION;
    studyOfferingSelectedSelectionType = this.ALL_SELECTION;

    /**
    * @descripton To get study unit object info
    */
    @wire(getObjectInfo, {objectApiName: STUDY_UNIT_OBJECT})
    studyUnitObjInfo;

    /**
    * @descripton To get study offering object info
    */
    @wire(getObjectInfo, {objectApiName: STUDY_OFFERING_OBJECT})
    studyOfferingObjInfo;

    /**
     * @description get the object info for the Study Offering
     */
    @wire(getObjectInfo, {objectApiName: INDIVIDUAL_ENROLLMENT_OBJECT})
    ienObjectInfo;

    /**
    * @description To get the picklist options for the grade release status combobox
    */
    @wire(getPicklistValues, { recordTypeId: '$ienDefaultRecordTypeId', fieldApiName: IEN_GRADE_RELEASE_STATUS_FIELD })
    returnedGradeReleaseStatusesPicklistOptions;

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
    * @description Get term record details
    */
    @wire(ctrlGetStudyTermDetails, {
        studyTermRecordId: '$recordId'
    })
    ctrlStudyTermDetails(result) {
        this.termWiredResult = null;

        if (result.data) {
            this.termWiredResult = JSON.parse(result.data.responseData);

            this.consoleLog(this.termWiredResult, true);

        } else if (result.error) {
            promptError(customLabels.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    /**
    * @description Wire method to get campus options
    */
    @wire(ctrlGetComboboxesOptions,{
        termId: "$recordId",
        educationalInstitutionId: "$educationalInstitutionId"
    })
    wireComboboxesOptions(result){
        this.wiredComboboxResponseData = null;

        if(result.data){
            if(result.data.responseData) {
                this.wiredComboboxResponseData = JSON.parse(result.data.responseData);

                this.consoleLog(this.wiredComboboxResponseData, true);
            }
        } else if (result.error){
            promptError(customLabels.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    /**
    * @description To get study unit data for datatable
    */
    @wire(ctrlGetStudyUnitData, {
        termId: "$recordId",
        studyUnitFields: "$studyUnitFields",
        studyOfferingStatuses: "$studyOfferingStatuses",
        selectedCampusId: "$selectedCampusId",
    })
    wiredStudyUnits(result) {
        if (result.data) {
            if(result.data.responseData) {
                const returnedResult = JSON.parse(result.data.responseData);

                this.studyUnitRecords = returnedResult?.studyUnitRecords || [];

                this.isStudyUnitListReady = true;

                this.consoleLog(this.studyUnitRecords, true);
            }
        } else if (result.error) {
            promptError(customLabels.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    /**
    * @descripton To get study offering data for datatable
    */
    getStudyOfferingData() {
        //Call Apex
        this.toggleSpinner(1);

        ctrlGetStudyOfferingData({
            termId: this.recordId,
            selectedCampusId: this.selectedCampusId,
            studyUnitIds: this.studyUnitIdsToBeProcessed,
            studyOfferingFields: this.studyOfferingFields,
            studyOfferingStatuses: this.studyOfferingStatuses
        })
        .then(result => {            
            if (result.responseData) {
                const returnedResult = JSON.parse(result.responseData);

                this.studyOfferingRecords = returnedResult?.studyOfferingRecords;
    
            } else if (result.error) {
                promptError(customLabels.ERROR_LABEL, getErrorMessage(result.error));
            }

            this.toggleSpinner(-1);
        })
        .catch(error => {
            promptError(customLabels.ERROR_LABEL, getErrorMessage(error));
            this.toggleSpinner(-1);
        });
    }

    /**
     * @description Handle study unit screen next button onclick
     */
    handleStudyUnitScreenNextOnClick() {
        this.isStudyUnitScreen = false;
        this.isGradeReleaseStatusesSelectionScreen = false;
        this.isConfirmationScreen = false; 

        this.isStudyOfferingScreen = true;

        //Reset selected study offerings variable
        this.studyOfferingSelectedSelectionType = this.ALL_SELECTION;
        this.manualSelectedStudyOfferingIds = [];

        this.getStudyOfferingData();
    }

    /**
     * @description Handle study offering screen previous button onclick
     */
    handleStudyOfferingScreenPreviousOnClick() {
        this.manualSelectedStudyOfferingIds = [];

        this.isStudyOfferingScreen = false;
        this.isGradeReleaseStatusesSelectionScreen = false; 
        this.isConfirmationScreen = false; 

        this.isStudyUnitScreen = true;
    }

    /**
     * @description Handle study offering screen next button onclick
     */
    handleStudyOfferingScreenNextOnClick() {
        this.isStudyUnitScreen = false;
        this.isStudyOfferingScreen = false;
        this.isConfirmationScreen = false; 

        this.isGradeReleaseStatusesSelectionScreen = true; 
    }

    /**
     * @description Handle grade release statuses selection screen previous button on click
     */
    handleGradeReleaseStatusesSelectionScreenPreviousOnClick() {
        this.isGradeReleaseStatusesSelectionScreen = false; 
        this.isStudyUnitScreen = false;
        this.isConfirmationScreen = false; 

        this.isStudyOfferingScreen = true;
    }

    /**
     * @description Handle grade release statuses selection screen next button onclick
     */
    handleGradeReleaseStatusesSelectionScreenNextOnClick() {
        this.isGradeReleaseStatusesSelectionScreen = false; 
        this.isStudyUnitScreen = false;
        this.isStudyOfferingScreen = false;

        this.isConfirmationScreen = true; 
    }

    /**
     * @description Handle confirmation screen previous button onclick
     */
    handleConfirmationScreenPreviousOnClick() {
        this.isStudyUnitScreen = false;
        this.isStudyOfferingScreen = false;
        this.isConfirmationScreen = false; 

        this.isGradeReleaseStatusesSelectionScreen = true; 
    }

    /**
     * @description Handle confirmation screen add job button onclick
     */
    handleConfirmationScreenAddJobOnClick() {
        this.toggleSpinner(1);

        if(this.studyOfferingIdsToBeProcessed || this.studyOfferingIdsToBeProcessed.length > 0) {
            ctrlInitQueueJob({
                termId: this.recordId,
                jobOperation: this.jobOperation,
                toBeProcessedStudyOfferingIds: this.studyOfferingIdsToBeProcessed,
                selectedGradeReleaseStatus: this.selectedGradeReleaseStatus,
            })
            .then(result => {        
                if(result.isSuccess) {
                    promptSuccess(QUEUE_JOB_SUBMITTED_MSG);
                    this.toggleSpinner(-1);
                    this.close('submitted');
                } else {
                    if(result.error) {
                        promptError(customLabels.ERROR_LABEL, getErrorMessage(result.error));
                    }

                    this.toggleSpinner(-1);
                    this.close('failed');
                }
            })
            .catch(error => {
                promptError(customLabels.ERROR_LABEL, getErrorMessage(error));
                this.toggleSpinner(-1);
                this.close('failed');
            });
        }

        this.toggleSpinner(-1);
        this.close('failed');
    }

    /**
     * @description Handle cancel button onclick
     */
    handleCancelOnClick() {
        this.close('cancel');
    }

     /**
     * @description Handle campus combobox on change
     */
     handleComboboxChange(event) {
        const { fieldName, selectedOpt } = event.detail;

        if (fieldName) {
            if (fieldName === this.CAMPUS_COMBOBOX_FIELD_NAME) {
                //Set as undefined so that the wire method does not re-run if selectedCampusId is removed after being selected
                this.selectedCampusId = selectedOpt?.value || undefined;
                this.selectedCampusLabel = selectedOpt?.label || '';

                if (!this.selectedCampusId) {
                    //Remove the queried study units and hide the datatable when the campus combobox is cleared
                    this.studyUnitRecords = [];
                    this.isStudyUnitListReady = false;

                    //Remvome the selected study units Ids in the datatable
                    this.manualSelectedStudyUnitIds = [];
                    this.manualSelectedStudyUnitLabels = [];
                    //Change back to all selection type
                    this.studyUnitSelectedSelectionType = this.ALL_SELECTION;
                }
            }
        }
    }

    /**
    * @descripton Handle study unit table row select
    */
    handleStudyUnitRowSelect(event){
        const selectedRows = event.detail.selectedRows;
        
        this.manualSelectedStudyUnitIds = selectedRows.map(row => row.Id);
        this.manualSelectedStudyUnitLabels = selectedRows.map(row => row.Name);
    }

    /**
    * @descripton Handle study offering table row select
    */
    handleStudyOfferingRowSelect(event) {
        const selectedRows = event.detail.selectedRows;
        
        this.manualSelectedStudyOfferingIds = selectedRows.map(row => row.Id);
    }

    /**
    * @descripton Handle study unit selection type combobox change
    */
    handleStudyUnitSelectionTypeChange(event) {
        this.studyUnitSelectedSelectionType = event.detail.value;
    }

    /**
    * @descripton Handle study offering selection type combobox change
    */
    handleStudyOfferingSelectionTypeChange(event) {
        this.studyOfferingSelectedSelectionType = event.detail.value;
    }

    /**
    * @descripton Handle grade release status combobox change
    */
    handleGradeReleaseStatusesChange(event) {
        this.selectedGradeReleaseStatus = event.detail.value;
    }   
    
    /**
     * @description Return current step for progress indicator
     */
    get currentStep() {
        if(this.isStudyUnitScreen) {
            return '1';
        } else if (this.isStudyOfferingScreen) {
            return '2';
        } else if (this.isGradeReleaseStatusesSelectionScreen) {
            return '3';
        } else if (this.isConfirmationScreen) {
            return '4';
        }

        return null;
    }

    /**
    * @description Return progressIndicatorStep1 label
    */
    get progressIndicatorStep1Label() {
        return PROGRESS_INDICATOR_STEP_ONE_LABEL.format([this.studyUnitLabel]);
    }

    /**
    * @description Return progressIndicatorStep2 label
    */
    get progressIndicatorStep2Label() {
        return PROGRESS_INDICATOR_STEP_TWO_LABEL.format([this.studyOfferingLabel]);
    }

    /**
    * @description Return progressIndicatorStep3 label
    */
    get progressIndicatorStep3Label() {
        return PROGRESS_INDICATOR_STEP_THREE_LABEL;
    }

    /**
    * @description Return progressIndicatorStep4 label
    */
    get progressIndicatorStep4Label() {
        return PROGRESS_INDICATOR_STEP_FOUR_LABEL;
    }

    /**
     * @description Return current term record name
     */
    get educationalInstitutionId() {
        return this.termWiredResult?.educationalInstitutionId;
    }

    /**
     * @description Return current term record name
     */
    get termRecordName() {
        return this.termWiredResult?.studyTermName;
    }

    /**
     * @description Return campus combobox options
     */
    get campusComboboxOptions() {
        if(this.wiredComboboxResponseData?.campuses) {
            return setupPicklistOptionsFromRecords(this.wiredComboboxResponseData?.campuses, '');
        }

        return [];
    }

    /**
     * @description Return campusComboboxLabel
     */
    get campusComboboxLabel() {
        return CAMPUS_COMBOBOX_LABEL.format([CAMPUS_COMMON_TERM]);
    }

    /**
     * @description Return campusComboboxHelptext
     */
    get campusComboboxHelptext() {
        return CAMPUS_COMBOBOX_HELPTEXT.format([this.studyUnitLabel, CAMPUS_COMMON_TERM]);
    }

    /**
     * @description Return messageWhenComboboxNotSelected label
     */
    get messageWhenComboboxNotSelected() {
        return MESSAGE_WHEN_COMBOBOX_NOT_SELECTED;
    }

    /**
    * @description Return study unit Ids To Be Processed
    */
    get studyUnitIdsToBeProcessed() {
        //If selection type is All, return all study unit Ids
        //Else return selected study unit Ids
        if (this.studyUnitSelectedSelectionType === this.ALL_SELECTION) {
            if (this.studyUnitRecords && this.studyUnitRecords.length > 0) {
                return this.studyUnitRecords.map(studyUnit => studyUnit.Id);
            }
        }

        return this.manualSelectedStudyUnitIds;
    }

    /**
    * @description Return study Offering Ids To Be Processed
    */
    get studyOfferingIdsToBeProcessed() {
        //If selection type is All, return all study offering Ids
        //Else return selected study offering Ids
        if (this.studyOfferingSelectedSelectionType === this.ALL_SELECTION) {
            if (this.studyOfferingRecords && this.studyOfferingRecords.length > 0) {
                return this.studyOfferingRecords.map(studyOffering => studyOffering.Id);
            }
        }

        return this.manualSelectedStudyOfferingIds;
    }

    /**
     * @description Return selectedStudyUnitAutoSelectionType (To control the visibility of the datatable's checkbox column)
     */
    get selectedStudyUnitAutoSelectionType() {
        return this.studyUnitSelectedSelectionType !== this.ALL_SELECTION;
    }    

    /**
     * @description Return selectedStudyOfferingAutoSelectionType (To control the visibility of the datatable's checkbox column)
     */
    get selectedStudyOfferingAutoSelectionType() {
        return this.studyOfferingSelectedSelectionType !== this.ALL_SELECTION;
    } 

    /**
     * @description Return noRecordToDisplay label
     */
    get noRecordToDisplayLabel() {
        return NO_RECORD_TO_DISPLAY_LABEL;
    }

    /**
    * @description Return study unit labels To Be Processed
    */
    get studyUnitLabelsToBeProcessed() {
        //If selection type is All, return all label
        if (this.studyUnitSelectedSelectionType === this.ALL_SELECTION) {
            return customLabels.ALL_LABEL;
        }

        let labelString = this.manualSelectedStudyUnitLabels.join(', ');

        //Truncate if > 150 characters
        return labelString.length > 150 ? labelString.substring(0, 150) + '...' : labelString;
    }

    /**
    * @description Return recordCountDetails
    */
    get recordCountDetails() {
        if (this.studyOfferingIdsToBeProcessed) {
            return RECORD_COUNT_DETAIL.format([this.studyOfferingIdsToBeProcessed.length, this.studyOfferingLabel]);
        }

        return '';
    }

    /**
    * @description Return summaryDetails
    */
    get summaryDetails() {
        return SUMMARY_DETAILS.format([ACADEMIC_TERM_COMMON_TERM, this.termRecordName, CAMPUS_COMMON_TERM, this.selectedCampusLabel, this.studyUnitLabel, this.studyUnitLabelsToBeProcessed, this.recordCountDetails]);
    }

    /**
    * @description Return finalConfirmation
    */
    get finalConfirmation() {
        return FINAL_CONFIRMATION.format([this.individualEnrollmentLabel, this.studyOfferingLabel, this.termRecordName, this.selectedGradeReleaseStatus]);
    }

    /**
     * @description Return termGradeReleaseStep1BriefDescription
     */
    get studyUnitSelectionScreenDescription(){
        return STUDY_UNIT_SELECTION_SCREEN_DESCRIPTION.format([this.individualEnrollmentLabel, this.studyOfferingLabel, ACADEMIC_TERM_COMMON_TERM, this.termRecordName]);
    }

    /**
     * @description Return cancel button label
     */
    get cancelButtonLabel() {
        return customLabels.CANCEL_LABEL;
    }

    /**
     * @description Return next button label
     */
    get nextScreenButtonLabel() {
        return customLabels.NEXT_LABEL;
    }

    /**
     * @description Return previous button label
     */
    get previousScreenButtonLabel() {
        return customLabels.PREVIOUS_LABEL;
    }

    /**
     * @description Return start button label
     */
    get addJobButtonLabel() {
        return customLabels.ADD_JOB_LABEL;
    }

    /**
    * @description return grade release statuses options for combobox
    */
    get gradeReleaseStatusesOptions() {
        if (this.returnedGradeReleaseStatusesPicklistOptions?.data?.values) {
            return this.returnedGradeReleaseStatusesPicklistOptions.data.values;
        }
        
        return [];
    }    

    /**
     * @description Return studyUnitSelectionTypeComboboxLabel
     */
    get studyUnitSelectionTypeComboboxLabel() {
        return SELECTION_TYPE_COMBOBOX_LABEL.format([this.studyUnitLabel]);
    }

    /**
     * @description Return studyUnitScreenSelectionTypeHelpText
     */
    get studyUnitScreenSelectionTypeHelpText() {
        return SELECTION_TYPE_HELP_TEXT.format([this.studyUnitLabel]);
    }

    /**
     * @description Return studyOfferingSelectionTypeComboboxLabel
     */
    get studyOfferingSelectionTypeComboboxLabel() {
        return SELECTION_TYPE_COMBOBOX_LABEL.format([this.studyOfferingLabel]);
    }

    /**
    * @description Return studyOfferingScreenSelectionTypeHelpText
    */
    get studyOfferingScreenSelectionTypeHelpText() {
        return SELECTION_TYPE_HELP_TEXT.format([this.studyOfferingLabel]);
    }
    
    /**
    * @description Return grade Release Statuses Selection Combobox label
    */
    get gradeReleaseStatusesSelectionComboboxLabel() {
        return GRADE_RELEASE_STATUSES_SELECTION_COMBOBOX_LABEL;
    }

    /**
    * @description Return grade Release Statuses Selection Combobox help text
    */
    get gradeReleaseStatusesSelectionComboboxHelptext() {
        return GRADE_RELEASE_STATUSES_SELECTION_COMBOBOX_HELPTEXT;
    }

    /**
     * @description Return study unit object label
     */
    get studyUnitLabel() {
        return this.studyUnitObjInfo?.data?.labelPlural;
    }

    /**
     * @description Return study offering object label
     */
    get studyOfferingLabel() {
        return this.studyOfferingObjInfo?.data?.labelPlural;
    }

    /**
     * @description Return individual enrollment object label
     */
    get individualEnrollmentLabel() {
        return this.ienObjectInfo?.data?.labelPlural;
    }

    /**
     * @description get the default record type id of the Study Session to get picklist value
     */
    get ienDefaultRecordTypeId(){
        return this.ienObjectInfo?.data?.defaultRecordTypeId;
    }

    /**
     * @description Return isStudyUnitScreenNextDisabled
     */
    get isStudyUnitScreenNextDisabled() {
        return !this.studyUnitIdsToBeProcessed || this.studyUnitIdsToBeProcessed.length === 0;
    }

    /**
     * @description Return isStudyOfferingScreenAddJobDisabled
     */
    get isStudyOfferingScreenNextDisabled() {
        return !this.studyOfferingIdsToBeProcessed || this.studyOfferingIdsToBeProcessed.length === 0;
    }

    /**
     * @description Return isGradeReleaseStatusesSelectionScreenAddJobDisabled (To control whether the Add Job button is disabled)
     */
    get isGradeReleaseStatusesSelectionScreenAddJobDisabled() {
        return !this.selectedGradeReleaseStatus || this.isLoading;
    }

    /**
     * @description Return sub title
     */
    get modalSubTitle() {
        return MODAL_SUB_TITLE.format([this.termRecordName]);
    }

    /**
    * @description Return loading label
    */
    get loadingLabel() {
        return customLabels.LOADING_LABEL;
    }

    /**
     * @descripton Spinner loading status
     */
    get isLoading(){
        return this.loadedLists === 0 && this.termWiredResult?.educationalInstitutionId ? false : true;
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
        logInfo('TermGradeReleaseModal', anything, this.enableDebugMode, isJson);
    }
}