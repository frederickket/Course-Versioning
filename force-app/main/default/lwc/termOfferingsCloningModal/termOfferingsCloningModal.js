/**
 * @Author 		WDCi (XiRouh)
 * @Date 		March 2025
 * @group 		Term Offerings Cloning
 * @Description 
 * @changehistory
 * ISS-002200 11-03-2025 XiRouh - New Class
 * ISS-002364 22-04-2025 xiRouh - Added combobox for option to retain study offering and study session name, updated summary screen details
 * ISS-002736 25-11-2025 XiRouh - Added tableTextDisplayMode configurable attribute
 */
import { api, wire, track } from 'lwc';
import LightningModal from 'lightning/modal';
import { promptInfo, promptError, promptWarning, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';
import { setupPicklistOptionsFromRecords } from 'c/lwcUtil';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';

import STUDY_UNIT_OBJECT from '@salesforce/schema/Study_Unit__c';
import STUDY_OFFERING_OBJECT from '@salesforce/schema/Study_Offering__c';
import STUDY_SESSION_OBJECT from '@salesforce/schema/Study_Session__c';
import STUDY_EVENT_OBJECT from '@salesforce/schema/Study_Event__c';

//labels
import { customLabels } from 'c/labelLoader';
import MODAL_SUB_TITLE from '@salesforce/label/c.Term_Offerings_Cloning_Sub_Title';
import NO_RECORD_TO_DISPLAY_LABEL from '@salesforce/label/c.No_Records_To_Display';
import QUEUE_JOB_SUBMITTED_MSG from '@salesforce/label/c.Queue_Job_Submitted_Message';
import SELECTION_SCREEN_DESCRIPTION from '@salesforce/label/c.Term_Offerings_Cloning_Selection_Screen_Description';
import TERM_COMBOBOX_LABEL from '@salesforce/label/c.Term_Offerings_Cloning_Term_Combobox_Label';
import TERM_COMBOBOX_HELPTEXT from '@salesforce/label/c.Term_Offerings_Cloning_Term_Combobox_Helptext';
import CAMPUS_COMBOBOX_LABEL from '@salesforce/label/c.Term_Offerings_Cloning_Campus_Combobox_Label';
import CAMPUS_COMBOBOX_HELPTEXT from '@salesforce/label/c.Term_Offerings_Cloning_Campus_Combobox_Helptext';
import MESSAGE_WHEN_COMBOBOX_NOT_SELECTED from '@salesforce/label/c.Complete_This_Field';
import SELECTION_TYPE_COMBOBOX_LABEL from '@salesforce/label/c.Term_Offerings_Cloning_Selection_Type_Combobox_Label'
import SELECTION_TYPE_HELP_TEXT from '@salesforce/label/c.Term_Offerings_Cloning_Selection_Type_Help_Text'
import MANUAL_SELECTION_LABEL from '@salesforce/label/c.Term_Offerings_Cloning_Manual_Selection'
import RECORD_COUNT_DETAIL from '@salesforce/label/c.Term_Offerings_Cloning_Summary_Record_Count_Detail'
import SUMMARY_DETAILS from '@salesforce/label/c.Term_Offerings_Cloning_Summary'
import NOT_TO_CLONE_STUDY_SESSION from '@salesforce/label/c.Term_Offerings_Cloning_Summary_Detail_Not_To_Clone_Study_Session'
import FINAL_CONFIRMATION from '@salesforce/label/c.Term_Offerings_Cloning_Final_Confirmation'
import FINAL_CONFIRMATION_STUDY_OFFERING from '@salesforce/label/c.Term_Offerings_Cloning_Final_Confirmation_Study_Offering'
import FINAL_CONFIRMATION_STUDY_SESSION from '@salesforce/label/c.Term_Offerings_Cloning_Final_Confirmation_Clone_Study_Session'
import FINAL_CONFIRMATION_RETAIN_RECORD_NAME from '@salesforce/label/c.Term_Offerings_Cloning_Final_Confirmation_Retain_Record_Name'
import ACADEMIC_TERM_COMMON_TERM from '@salesforce/label/c.Academic_Term'
import CAMPUS_COMMON_TERM from '@salesforce/label/c.Campus'
import DATATABLE_MESSAGE_FOR_ALL_SELECTION_TYPE from '@salesforce/label/c.Term_Offerings_Cloning_Datatable_Message_For_All_Selection_Type'
import DATATABLE_MESSAGE_WHEN_EXCEED_MAXIMUM_ROW_NUMBER from '@salesforce/label/c.Term_Offerings_Cloning_Datatable_Message_When_Exceed_Maximum_Row_Number'
import PROGRESS_INDICATOR_STEP_ONE_LABEL from '@salesforce/label/c.Term_Offerings_Cloning_Progress_Indicator_Step_One_Label';
import PROGRESS_INDICATOR_STEP_TWO_LABEL from '@salesforce/label/c.Term_Offerings_Cloning_Progress_Indicator_Step_Two_Label';
import PROGRESS_INDICATOR_STEP_THREE_LABEL from '@salesforce/label/c.Term_Offerings_Cloning_Progress_Indicator_Step_Three_Label';
import PROGRESS_INDICATOR_STEP_FOUR_LABEL from '@salesforce/label/c.Term_Offerings_Cloning_Progress_Indicator_Step_Four_Label';
import CLONE_STUDY_SESSION_COMBOBOX_LABEL from '@salesforce/label/c.Term_Offerings_Cloning_Clone_Study_Session_Combobox_Label';
import RETAIN_RECORD_NAME_OPTION_LABEL from '@salesforce/label/c.Term_Offerings_Cloning_Retain_Record_Name_Combobox_Label';
import RETAIN_RECORD_NAME_OPTION_HELPTEXT from '@salesforce/label/c.Term_Offerings_Cloning_Retain_Record_Name_Combobox_Helptext';
import RETAIN_RECORD_NAME_RETAIN_OPTION from '@salesforce/label/c.Term_Offerings_Cloning_Retain_Record_Name_Combobox_Retain_Option';
import RETAIN_RECORD_NAME_RANAME_OPTION from '@salesforce/label/c.Term_Offerings_Cloning_Retain_Record_Name_Combobox_Rename_Option';

//Apex methods
import ctrlGetComboboxesOptions from '@salesforce/apex/REDU_TermOfferingsCloningModal_LCTRL.getComboboxesOptions';
import ctrlGetStudyTermDetails from '@salesforce/apex/REDU_TermOfferingsCloningModal_LCTRL.getStudyTermDetails';
import ctrlGetStudyUnitData from '@salesforce/apex/REDU_TermOfferingsCloningModal_LCTRL.getStudyUnitData';
import ctrlGetStudyOfferingData from '@salesforce/apex/REDU_TermOfferingsCloningModal_LCTRL.getStudyOfferingData';
import ctrlInitQueueJob from '@salesforce/apex/REDU_TermOfferingsCloningModal_LCTRL.initQueueJob';

export default class TermOfferingsCloningModal extends LightningModal {
	
	//configurable attributes
    @api recordId;
    @api modalTitle;

	@api jobOperation;

    @api studyUnitFields;
    @api studyUnitTableMaxHeight;

    @api studyOfferingFields;
    @api studyOfferingStatuses;
    @api studyOfferingTableMaxHeight;
    @api studyOfferingTableMaximumRowNumber;

    //ISS-002736
    @api tableTextDisplayMode;

    @api enableDebugMode;
	
	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false
	loadedLists = 0;
	
	//js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'jquery', 'tooltips'
    modules = ['stringutil', 'moment'];

    //screen control
    isStudyUnitSelectionScreen = true;
    isStudyOfferingSelectionScreen = false;
    isAdditionalOptionScreen = false;
    isConfirmationScreen = false;

    //Wired responses
    //Study term details
    termWiredResult;

    //term and campus combobox
    wiredComboboxResponseData;

    //academic term combobox
    selectedTermId;
    selectedTermLabel;
    TERM_COMBOBOX_FIELD_NAME = 'termId';

    //campus combobox
    selectedCampusId;
    selectedCampusLabel;
    CAMPUS_COMBOBOX_FIELD_NAME = 'campusId';

    //Selection Type Combobox
    ALL_SELECTION = customLabels.ALL_LABEL;
    MANUAL_SELECTION = MANUAL_SELECTION_LABEL;

    selectionTypeOptions = [
        {label: customLabels.ALL_LABEL, value: this.ALL_SELECTION},
        {label: MANUAL_SELECTION_LABEL, value: this.MANUAL_SELECTION}
    ];

    selectedStudyUnitSelectionType = this.ALL_SELECTION;
    selectedStudyOfferingSelectionType = this.ALL_SELECTION;

    cloneStudySessionComboboxOptions = [
        { label: customLabels.YES_LABEL, value: "true", },
        { label: customLabels.NO_LABEL, value: "false" }
    ];

    selectedCloneStudySessionOption;
    proceedToCloneStudySession = false;

    retainStudyOfferingNameOptions = [
        { label: RETAIN_RECORD_NAME_RETAIN_OPTION, value: "true", },
        { label: RETAIN_RECORD_NAME_RANAME_OPTION, value: "false" }
    ];

    selectedRetainStudyOfferingNameOption;

    retainStudySessionNameOptions = [
        { label: RETAIN_RECORD_NAME_RETAIN_OPTION, value: "true", },
        { label: RETAIN_RECORD_NAME_RANAME_OPTION, value: "false" }
    ];

    selectedRetainStudySessionNameOption;

    //Study unit datatable
    @track studyUnitRecords;
    isStudyUnitListReady = false;

    manualSelectedStudyUnitIds = [];
    manualSelectedStudyUnitLabels = [];

    //Study offering wired result
    @track studyOfferingWiredResult;

    manualSelectedStudyOfferingIds = [];
    
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
     * @description Handle cancel button onclick
     */
    handleCancelOnClick() {
        this.close('cancel');
    }

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
     * @descripton To get study offering object info
     */
    @wire(getObjectInfo, {objectApiName: STUDY_SESSION_OBJECT})
    studySessionObjInfo;

    /**
     * @descripton To get study event object info
     */
    @wire(getObjectInfo, {objectApiName: STUDY_EVENT_OBJECT})
    studyEventObjInfo;
    
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
    * @description Wire method to get academic term and campus options
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
        selectedTermId: "$selectedTermId",
        selectedCampusId: "$selectedCampusId",
        studyUnitFields: "$studyUnitFields",
        studyOfferingStatuses: "$studyOfferingStatuses"
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
            selectedTermId: this.selectedTermId,
            selectedCampusId: this.selectedCampusId,
            selectedStudyUnitIds: this.studyUnitIdsToBeProcessed,
            studyOfferingTableMaximumRowNumber: this.studyOfferingTableMaximumRowNumber,
            studyOfferingFields: this.studyOfferingFields,
            studyOfferingStatuses: this.studyOfferingStatuses
        })
        .then(result => {     
            if (result.isSuccess) {
                if (result.responseData) {    
                    this.studyOfferingWiredResult = JSON.parse(result.responseData);

                    this.consoleLog(this.studyOfferingWiredResult, true);
                }
            } else {
                if (result.message) {
                    promptError(customLabels.ERROR_LABEL, result.message);
                } else {
                    promptError(customLabels.ERROR_LABEL, customLabels.UNKNOWN_EXCEPTIONS_LABEL);
                }
            }
            
            this.toggleSpinner(-1);
        })
        .catch(error => {
            promptError(customLabels.ERROR_LABEL, getErrorMessage(error));
            this.toggleSpinner(-1);
        });
    }

    /**
    * @description To init queue job
    */
    initQueueJob() {
        //Call Apex
        this.toggleSpinner(1);

        if((!this.selectedStudyOfferingManualSelectionType && (this.studyUnitIdsToBeProcessed && this.studyUnitIdsToBeProcessed.length > 0)) || (this.selectedStudyOfferingManualSelectionType && (this.manualSelectedStudyOfferingIds && this.manualSelectedStudyOfferingIds.length > 0)) ) {            
            ctrlInitQueueJob({
                jobOperation: this.jobOperation,
                idsToBeProcessed: this.idsToBeProcessed,
                currentTermId: this.recordId,
                selectedTermId: this.selectedTermId,
                selectedCampusId: this.selectedCampusId,
                sofSelectionType: this.selectedStudyOfferingSelectionType,
                studyOfferingStatuses: this.studyOfferingStatuses,
                cloneStudySessionOption: this.selectedCloneStudySessionOption,
                selectedRetainStudyOfferingNameOption: this.selectedRetainStudyOfferingNameOption,
                selectedRetainStudySessionNameOption: this.selectedRetainStudySessionNameOption
            })
            .then(result => {        
                if(result.isSuccess) {
                    promptSuccess(QUEUE_JOB_SUBMITTED_MSG);

                    this.toggleSpinner(-1);
                    this.close('submitted');
                } else {
                    if (result.message) {
                        promptError(customLabels.ERROR_LABEL, result.message);
                    } else {
                        promptError(customLabels.ERROR_LABEL, customLabels.UNKNOWN_EXCEPTIONS_LABEL);
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
        } else {
            this.toggleSpinner(-1);
            this.close('failed');
        }
    }

    /**
     * @description Handle selection screen next button on click 
     */
    handleStudyUnitSelectionScreenNextOnClick() {
        this.isStudyUnitSelectionScreen = false;
        this.isStudyOfferingSelectionScreen = true;
        this.isAdditionalOptionScreen = false;
        this.isConfirmationScreen = false;

        //Reset selected study offerings variable
        this.selectedStudyOfferingSelectionType = this.ALL_SELECTION;
        this.manualSelectedStudyOfferingIds = [];
        
        this.getStudyOfferingData();
    }

    /**
     * @description Handle study offering screen previous button on click 
     */
    handleStudyOfferingSelectionScreenPreviousOnClick() {
        this.isStudyUnitSelectionScreen = true;
        this.isStudyOfferingSelectionScreen = false;
        this.isAdditionalOptionScreen = false;
        this.isConfirmationScreen = false;
    }

    /**
     * @description Handle study offering screen next button on click 
     */
    handleStudyOfferingSelectionScreenNextOnClick() {
        this.isStudyUnitSelectionScreen = false;
        this.isStudyOfferingSelectionScreen = false;
        this.isAdditionalOptionScreen = true;
        this.isConfirmationScreen = false;
    }

    /**
     * @description Handle study offering screen previous button on click 
     */
    handleAdditionalOptionScreenPreviousOnClick() {
        this.isStudyUnitSelectionScreen = false;
        this.isStudyOfferingSelectionScreen = true;
        this.isAdditionalOptionScreen = false;
        this.isConfirmationScreen = false;
    }

    /**
     * @description Handle study offering screen next button on click 
     */
    handleAdditionalOptionScreenNextOnClick() {
        this.isStudyUnitSelectionScreen = false;
        this.isStudyOfferingSelectionScreen = false;
        this.isAdditionalOptionScreen = false;
        this.isConfirmationScreen = true;
    }

    /**
     * @description Handle confirmation screen previous button on click 
     */
    handleConfirmationScreenPreviousOnClick() {
        this.isStudyUnitSelectionScreen = false;
        this.isStudyOfferingSelectionScreen = false;
        this.isAdditionalOptionScreen = true;
        this.isConfirmationScreen = false;
    }

    /**
     * @description Handle confirmation screen add job button on click 
     */
    handleConfirmationScreenAddJobOnClick() {
        this.initQueueJob();
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
                    this.selectedStudyUnitSelectionType = this.ALL_SELECTION;
                }
            } else if (fieldName === this.TERM_COMBOBOX_FIELD_NAME) {
                //Set as undefined so that the wire method does not re-run if selectedTermId is removed after being selected
                this.selectedTermId = selectedOpt?.value || undefined;
                this.selectedTermLabel = selectedOpt?.label || '';
                
                if (!this.selectedTermId) {
                    //Remove the queried study units and hide the datatable when the term combobox is cleared
                    this.studyUnitRecords = [];
                    this.isStudyUnitListReady = false;

                    //Remvome the selected study units Ids in the datatable
                    this.manualSelectedStudyUnitIds = [];
                    this.manualSelectedStudyUnitLabels = [];
                    //Change back to all selection type
                    this.selectedStudyUnitSelectionType = this.ALL_SELECTION;
                }
            }
        }
    }

    /**
    * @descripton Handle study unit selection type combobox change
    */
    handleStudyUnitSelectionTypeChange(event) {
        this.selectedStudyUnitSelectionType = event.detail.value;
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
    * @descripton Handle study offering selection type combobox change
    */
    handleStudyOfferingSelectionTypeChange(event) {
        this.selectedStudyOfferingSelectionType = event.detail.value;
    }

    /**
    * @descripton Handle study offering table row select
    */
    handleStudyOfferingRowSelect(event){
        const selectedRows = event.detail.selectedRows;
        
        this.manualSelectedStudyOfferingIds = selectedRows.map(row => row.Id);
    }

    /**
     * @description Handle clone study session combobox change
     */
    handleCloneStudySessionOptionChange(event) {
        this.proceedToCloneStudySession = event.detail.value === "true";
        this.selectedCloneStudySessionOption = event.detail.value;
    }

    /**
     * @description Handle retain study offering name option combobox change
     */
    handleRetainStudyOfferingNameOptionsChange(event) {
        this.selectedRetainStudyOfferingNameOption = event.detail.value;
    }

    /**
     * @description Handle retain study session name option combobox change
     */
    handleRetainStudySessionNameOptionsChange(event) {
        this.selectedRetainStudySessionNameOption = event.detail.value;
    }

    /**
     * @description Return current step for progress indicator
     */
    get currentStep() {
        if(this.isStudyUnitSelectionScreen) {
            return '1';
        } else if (this.isStudyOfferingSelectionScreen) {
            return '2';
        } else if (this.isAdditionalOptionScreen) {
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
    * @description Return progressIndicatorStep3 label
    */
    get progressIndicatorStep4Label() {
        return PROGRESS_INDICATOR_STEP_FOUR_LABEL;
    }

    /**
     * @description Return selectionScreenDescription
     */
    get selectionScreenDescription() {
        return SELECTION_SCREEN_DESCRIPTION.format([this.studyOfferingLabel, ACADEMIC_TERM_COMMON_TERM, this.termRecordName]);
    }

    /**
     * @description Return termComboboxLabel
     */
    get termComboboxLabel() {
        return TERM_COMBOBOX_LABEL.format([ACADEMIC_TERM_COMMON_TERM]);
    }

    /**
     * @description Return termComboboxHelptext
     */
    get termComboboxHelptext() {
        return TERM_COMBOBOX_HELPTEXT.format([ACADEMIC_TERM_COMMON_TERM, this.studyOfferingLabel]);
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
    * @description Return academic term combobox options
    */
    get academicTermsComboboxOptions() {
        if(this.wiredComboboxResponseData?.academicTerms) {
            return setupPicklistOptionsFromRecords(this.wiredComboboxResponseData?.academicTerms, '');
        }

        return [];
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
     * @description Return selectedStudyUnitManualSelectionType (To control the visibility of the datatable's checkbox column and datatable)
     */
    get selectedStudyUnitManualSelectionType() {
        return this.selectedStudyUnitSelectionType === this.MANUAL_SELECTION;
    } 

    /**
     * @description Return selectedStudyOfferingManualSelectionType (To control the visibility of the datatable's checkbox column and datatable)
     */
    get selectedStudyOfferingManualSelectionType() {
        return this.selectedStudyOfferingSelectionType === this.MANUAL_SELECTION;
    } 

    /**
     * @description Return studyUnitSelectionTypeHelpText
     */
    get studyUnitSelectionTypeHelpText() {
        return SELECTION_TYPE_HELP_TEXT.format([this.studyUnitLabel]);
    }

    /**
     * @description Return studyOfferingSelectionTypeHelpText
     */
    get studyOfferingSelectionTypeHelpText() {
        return SELECTION_TYPE_HELP_TEXT.format([this.studyOfferingLabel]);
    }

    /**
     * @description Return studyUnitSelectionTypeComboboxLabel
     */
    get studyUnitSelectionTypeComboboxLabel() {
        return SELECTION_TYPE_COMBOBOX_LABEL.format([this.studyUnitLabel]);
    }

    /**
     * @description Return studyOfferingSelectionTypeComboboxLabel
     */
    get studyOfferingSelectionTypeComboboxLabel() {
        return SELECTION_TYPE_COMBOBOX_LABEL.format([this.studyOfferingLabel]);
    }

    /**
    * @description Return available study offering record count (full records count without limit)
    */
    get availableStudyOfferingCount() {
        return this.studyOfferingWiredResult?.totalRecordCount || 0;
    }

    /**
    * @description Return study offering records that should show in datatable based on the maximum row number
    */
    get studyOfferingRecordsToShowInDatatable() {
        return this.studyOfferingWiredResult?.studyOfferingRecordsWithLimitSet || [];
    }

    /**
    * @description Return study offering datatable message that will show above the study offering datatable
    */
    get studyOfferingDatatableMessage() {
        if (this.selectedStudyOfferingSelectionType === this.ALL_SELECTION) {
            return DATATABLE_MESSAGE_FOR_ALL_SELECTION_TYPE.format([customLabels.ALL_LABEL, this.studyOfferingLabel, this.availableStudyOfferingCount]);
        } else if (this.selectedStudyOfferingSelectionType === this.MANUAL_SELECTION && this.availableStudyOfferingCount > this.studyOfferingTableMaximumRowNumber) {
            return DATATABLE_MESSAGE_WHEN_EXCEED_MAXIMUM_ROW_NUMBER.format([this.studyOfferingLabel, this.studyOfferingTableMaximumRowNumber]);
        }

        return null;
    }

    /**
    * @description Return study unit labels To Be Processed
    */
    get studyUnitLabelsToBeProcessed() {
        //If selection type is All, return all label
        if (this.selectedStudyUnitSelectionType === this.ALL_SELECTION) {
            return customLabels.ALL_LABEL;
        }

        let labelString = this.manualSelectedStudyUnitLabels.join(', ');

        //Truncate if > 150 characters
        return labelString.length > 150 ? labelString.substring(0, 150) + '...' : labelString;
    }

    /**
    * @description Return study unit Ids To Be Processed
    */
    get studyUnitIdsToBeProcessed() {
        //If selection type is All, return all study unit Ids
        //Else return selected study unit Ids
        if (this.selectedStudyUnitSelectionType === this.ALL_SELECTION) {
            if (this.studyUnitRecords && this.studyUnitRecords.length > 0) {
                return this.studyUnitRecords.map(studyUnit => studyUnit.Id);
            }
        }

        return this.manualSelectedStudyUnitIds;
    }

    /**
     * @description To set the disabled status for the selection screen next button
     */
    get isStudyUnitSelectionScreenNextDisabled() {
        return !this.selectedTermId || !this.selectedCampusId || !this.studyUnitIdsToBeProcessed || this.studyUnitIdsToBeProcessed.length === 0;
    }

    /**
     * @description To set the disabled status for the study offering screen next button
     */
    get isStudyOfferingSelectionScreenNextDisabled() {
        return !(this.selectedStudyOfferingSelectionType === this.ALL_SELECTION || (this.selectedStudyOfferingManualSelectionType && this.manualSelectedStudyOfferingIds?.length > 0));
    }

    /**
    * @description To set the disabled status for the additional option screen next button
    */
    get isAdditionalOptionScreenNextDisabled() {
        return !(this.selectedRetainStudyOfferingNameOption && this.selectedCloneStudySessionOption && (!this.proceedToCloneStudySession || this.selectedRetainStudySessionNameOption));
    }    

    /**
    * @description Return the number of selected study offering 
    */
    get selectedSofRecordCount() {
        if (this.selectedStudyOfferingSelectionType === this.ALL_SELECTION) {
            return this.availableStudyOfferingCount;
        } else if (this.selectedStudyOfferingSelectionType === this.MANUAL_SELECTION) {
            return this.manualSelectedStudyOfferingIds?.length;
        }

        return 0;
    }

    /**
    * @description Return recordCountDetails
    */
    get recordCountDetails() {
        if (this.selectedSofRecordCount) {
            return RECORD_COUNT_DETAIL.format([this.selectedSofRecordCount, this.studyOfferingLabel]);
        }

        return '';
    }

    /**
     * @description Return the selected clone study session option label
     */
    get selectedCloneStudySessionOptionLabel() {
        return this.selectedCloneStudySessionOption && this.selectedCloneStudySessionOption === "true" ? customLabels.YES_LABEL : customLabels.NO_LABEL;
    }

    /**
     * @description Return the selected retain study offering name option label
     */
    get selectedRetainStudyOfferingNameOptionLabel() {
        return this.selectedRetainStudyOfferingNameOption && this.selectedRetainStudyOfferingNameOption === "true" ? RETAIN_RECORD_NAME_RETAIN_OPTION : RETAIN_RECORD_NAME_RANAME_OPTION;
    }

    /**
    * @description Return the selected retain study session name option label
    */
    get selectedRetainStudySessionNameOptionLabel() {
        if (this.selectedCloneStudySessionOption === "false") {
            return NOT_TO_CLONE_STUDY_SESSION.format([this.studySessionsLabel]);
        }

        return this.selectedRetainStudySessionNameOption && this.selectedRetainStudySessionNameOption === "true"
            ? RETAIN_RECORD_NAME_RETAIN_OPTION
            : RETAIN_RECORD_NAME_RANAME_OPTION;
    }

    /**
    * @description Return summaryDetails
    */
    get summaryDetails() {
        return SUMMARY_DETAILS.format([
            ACADEMIC_TERM_COMMON_TERM, 
            CAMPUS_COMMON_TERM, 
            this.selectedTermLabel, 
            this.termRecordName, 
            this.selectedCampusLabel, 
            this.studyUnitLabel, 
            this.studyUnitLabelsToBeProcessed, 
            this.recordCountDetails,
            this.studySessionsLabel,
            this.selectedCloneStudySessionOptionLabel,
            this.studyOfferingLabel,
            this.selectedRetainStudyOfferingNameOptionLabel,
            this.selectedRetainStudySessionNameOptionLabel
        ]);
    }

    /**
    * @description Return finalConfirmation for study offering
    */
    get finalConfirmationStudyOfferingSummary() {
        return FINAL_CONFIRMATION_STUDY_OFFERING.format([
            this.studyOfferingLabel, 
            this.currentAcademicTermStartDate, 
            this.currentAcademicTermEndDate, 
            ACADEMIC_TERM_COMMON_TERM, 
            this.termRecordName
        ]);
    }

    /**
    * @description Return finalConfirmation for study offering
    */
    get finalConfirmationStudySessionSummary() {

        if (this.selectedCloneStudySessionOption === "true") {
            return FINAL_CONFIRMATION_STUDY_SESSION.format([
                this.studySessionsLabel,
                this.studyEventsLabel,
                this.studyEventGenerationStatusFieldLabel,
                this.studySessionLabel
            ]);
        }

        return null;
    }

    /**
    * @description Return finalConfirmation for retain record name
    */
    get finalRetainRecordSummary() {
        return FINAL_CONFIRMATION_RETAIN_RECORD_NAME.format([
            this.studyOfferingLabel,
            this.studySessionsLabel,
            ACADEMIC_TERM_COMMON_TERM,
            this.selectedTermLabel,
            this.termRecordName
        ]);
    }

    /**
     * @description Return final confirmation
     */
    get finalConfirmation() {
        return FINAL_CONFIRMATION;
    }

    /**
    * @description Return idsToBeProcessed based on the selection type
    */
    get idsToBeProcessed() {
        if (this.selectedStudyOfferingSelectionType === this.ALL_SELECTION) {
            return this.studyUnitIdsToBeProcessed;
        }

        return this.manualSelectedStudyOfferingIds;
    }

    /**
    * @description Return current academic term start date
    */
    get currentAcademicTermStartDate() {
        return this.termWiredResult?.studyTermStartDate;
    }

    /**
    * @description Return current academic term end date
    */
    get currentAcademicTermEndDate() {
        return this.termWiredResult?.studyTermEndDate;
    }

    /**
     * @description Return current term record name
     */
    get termRecordName() {
        return this.termWiredResult?.studyTermName;
    }

    /**
     * @description Return current term record name
     */
    get educationalInstitutionId() {
        return this.termWiredResult?.educationalInstitutionId;
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
     * @description Return study session object plural label
     */
    get studySessionsLabel() {
        return this.studySessionObjInfo?.data?.labelPlural;
    }

    /**
     * @description Return study session object label
     */
    get studySessionLabel() {
        return this.studySessionObjInfo?.data?.label;
    }

    /**
     * @description Return study event generation status field label
     */
    get studyEventGenerationStatusFieldLabel() {
        return this.studySessionObjInfo?.data?.fields.reduivy__Study_Event_Generation_Status__c?.label;
    }

    /**
     * @description Return study event object label
     */
    get studyEventsLabel() {
        return this.studyEventObjInfo?.data?.labelPlural;
    }

    /**
     * @description Return the label for clone study session option combobox
     */
    get cloneStudySesssionComboboxLabel() {
        return CLONE_STUDY_SESSION_COMBOBOX_LABEL.format([this.studySessionsLabel]);
    }

    /**
     * @description Return the label for retain study offering option combobox
     */
    get retainStudyOfferingNameComboboxLabel() {
        return RETAIN_RECORD_NAME_OPTION_LABEL.format([this.studyOfferingLabel]);
    }

    /**
     * @description Return the helptext for retain study offering option combobox
     */
    get retainStudyOfferingNameComboboxHelptext() {
        return RETAIN_RECORD_NAME_OPTION_HELPTEXT.format([RETAIN_RECORD_NAME_RANAME_OPTION, this.studyOfferingLabel, ACADEMIC_TERM_COMMON_TERM]);
    }

    /**
     * @description Return the label for retain study session option combobox
     */
    get retainStudySessionNameComboboxLabel() {
        return RETAIN_RECORD_NAME_OPTION_LABEL.format([this.studySessionsLabel]);
    }

    /**
     * @description Return the helptext for retain study session option combobox
     */
    get retainStudySessionNameComboboxHelptext() {
        return RETAIN_RECORD_NAME_OPTION_HELPTEXT.format([RETAIN_RECORD_NAME_RANAME_OPTION, this.studySessionLabel, ACADEMIC_TERM_COMMON_TERM]);
    }

    /**
     * @description Return messageWhenComboboxNotSelected label
     */
    get messageWhenComboboxNotSelected() {
        return MESSAGE_WHEN_COMBOBOX_NOT_SELECTED;
    }

    /**
     * @description Return noRecordToDisplay label
     */
    get noRecordToDisplayLabel() {
        return NO_RECORD_TO_DISPLAY_LABEL;
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
        logInfo('TermOfferingsCloningModal', anything, this.enableDebugMode, isJson);
    }
}