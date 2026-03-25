/**
 * @Author 		WDCi (XiRouh)
 * @Date 		Jan 2025
 * @group 		
 * @Description 
 * @changehistory
 * ISS-002229 16-01-2025 XiRouh - initial version
 * ISS-002495 22-09-2025 XW - support translation for long text field
 * ISS-002736 25-11-2025 XiRouh - Added tableTextDisplayMode configurable attribute
 * ISS-002779 21-01-2026 Lean - Make table header to respect tableTextDisplayMode
 * ISS-002797 13-02-2025 Lean - Standardize language code format to POSIX
 */
import { api, wire, track } from 'lwc';
import LightningModal from 'lightning/modal';

import { promptError, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo } from 'c/loggingUtil';
import { setupPicklistOptionsFromRecords, isWrapTextEnabled, updateDatatableConfig, getTableHeaderDisplayMode, formatLanguageCodeToPosix } from 'c/lwcUtil';
import LANG from '@salesforce/i18n/lang';

//Labels
import { customLabels } from 'c/labelLoader';

import MODAL_SUB_TITLE from '@salesforce/label/c.Term_Student_Enrollment_Sub_Title';
import STUDY_INTAKES_DATATABLE_LABEL from '@salesforce/label/c.Study_Intakes_Datatable_Label';
import SELECT_PAST_ACADEMIC_TERM_COMBOBOX_LABEL from '@salesforce/label/c.Select_Past_Academic_Term_Combobox_Label';
import CAMPUS_COMBOBOX_LABEL from '@salesforce/label/c.Select_Campus_Combobox_Label';
import STUDY_PROGRAM_COMBOBOX_LABEL from '@salesforce/label/c.Select_Study_Program_Combobox_Label';
import STUDY_INTAKE_NOT_SELECTED from '@salesforce/label/c.Study_Intake_Not_Selected';
import NO_AVAILABLE_STUDY_INTAKE_FOUND from '@salesforce/label/c.No_Available_Study_Intake_Found';
import ENROLL_MANDATORY_STUDY_UNITS_COMBOBOX_LABEL from '@salesforce/label/c.Enroll_Mandatory_Study_Units_Combobox_Label';
import BYPASS_REQUIREMENT_RULES_COMBOBOX_LABEL from '@salesforce/label/c.Bypass_Requirement_Rules_Combobox_Label';
import TERM_STUDENT_ENROLLMENT_NO_PROGRAM_ENROLLMENT_FOUND from '@salesforce/label/c.Term_Student_Enrollment_No_Program_Enrollment_Found';
import ELIGIBLE_FOR_TERM_ENROLLMENT_COUNT_LABEL from '@salesforce/label/c.Eligible_For_Term_Enrollment_Count_Label';
import ELIGIBLE_FOR_UNIT_ENROLLMENT_COUNT_LABEL from '@salesforce/label/c.Eligible_For_Unit_Enrollment_Count_Label';
import SKIP_UNIT_ENROLLMENT_MESSAGE from '@salesforce/label/c.Skip_Unit_Enrollment_Message';
import TERM_STUDENT_ENROLLMENT_STEP1_BRIEF_DESCRIPTION from '@salesforce/label/c.Term_Student_Enrollment_Step1_Brief_Description';
import TERM_STUDENT_ENROLLMENT_STEP3_BRIEF_DESCRIPTION from '@salesforce/label/c.Term_Student_Enrollment_Step3_Brief_Description';
import TERM_STUDENT_ENROLLMENT_STEP2_BRIEF_DESCRIPTION from '@salesforce/label/c.Term_Student_Enrollment_Step2_Brief_Description';
import TERM_STUDENT_ENROLLMENT_STEP4_BRIEF_DESCRIPTION from '@salesforce/label/c.Term_Student_Enrollment_Step4_Brief_Description';
import QUEUE_JOB_SUBMITTED_MSG from '@salesforce/label/c.Queue_Job_Submitted_Message';
import PROGRESS_INDICATOR_STEP_ONE_LABEL from '@salesforce/label/c.Progress_Indicator_Step_One_Label';
import PROGRESS_INDICATOR_STEP_TWO_LABEL from '@salesforce/label/c.Progress_Indicator_Step_Two_Label';
import PROGRESS_INDICATOR_STEP_THREE_LABEL from '@salesforce/label/c.Progress_Indicator_Step_Three_Label';
import PROGRESS_INDICATOR_STEP_FOUR_LABEL from '@salesforce/label/c.Progress_Indicator_Step_Four_Label';
import MESSAGE_WHEN_COMBOBOX_NOT_SELECTED from '@salesforce/label/c.Complete_This_Field';

//Apex methods
import ctrlGetStudyTermDetails from '@salesforce/apex/REDU_TermStudentEnrollmentModal_LCTRL.getStudyTermDetails';
import ctrlGetComboboxOptions from '@salesforce/apex/REDU_TermStudentEnrollmentModal_LCTRL.getComboboxOptions';
import ctrlGetStudyIntakes from '@salesforce/apex/REDU_TermStudentEnrollmentModal_LCTRL.getStudyIntakes';
import ctrlGetTermEnrollmentRecords from '@salesforce/apex/REDU_TermStudentEnrollmentModal_LCTRL.getTermEnrollmentRecords';
import ctrlInitQueueJob from '@salesforce/apex/REDU_TermStudentEnrollmentModal_LCTRL.initQueueJob';

export default class TermStudentEnrollmentModal extends LightningModal {
    //configurable attributes
    @api modalTitle;
    @api jobOperation;
    @api studyIntakeSelectionTableFields;
    @api eligibleStudentCountTableStudyIntakeField;
    @api existingIndividualEnrollmentStatuses;
    //ISS-002736
    @api tableTextDisplayMode;
    @api enableDebugMode;

    @api recordId;
    
    //internal attributes
    isScriptLoaded = false;
    isInitSuccess = false
    loadedLists = 0;
        
    modules = ['stringutil'];

    //screen control
    @track isTermEnrollmentSelectionScreen = true;
    @track isTermEnrollmentCountScreen = false;
    @track isUnitEnrollmentSelectionScreen = false;
    @track isFinalScreen = false;
    
    //Combobox
    PAST_ACADEMIC_TERM_COMBOBOX_FIELD_NAME = 'pastAcademicTermId';
    CAMPUS_COMBOBOX_FIELD_NAME = 'campusId';
    STUDY_PROGRAM_COMBOBOX_FIELD_NAME = 'studyProgramId';

    @track comboboxOptionsResponse;

    unitEnrollmentComboboxOptions = [
        { value: "true", label: customLabels.YES_LABEL },
        { value: "false", label: customLabels.NO_LABEL }
    ];

    //Datatable
    @track studyIntakesData;
    @track studyIntakesColumn;

    @track termEnrollmentData;

    @track termEnrollmentRecordCountData;
    @track termEnrollmentRecordCountColumn;

    @track finalRecordCountData;
    @track finalRecordCountColumn;

    //Selected values
    @track selectedTermId;
    @track selectedCampusId;
    @track selectedStudyProgramId;
    @track selectedStudyIntakeIds = [];
    
    @track studyIntakeReady = false;
    @track studyIntakeSelected = true;
    @track availableStudyIntakeFound = false;

    @track proceedForUnitEnrollment = false;
    @track bypassRequirementMetRules = false;
    @track selectedUnitEnrollmentResult;
    @track selectedBypassRequirementMetRules;

    //records
    @track ipwIds;
    @track toBeProcessedRecordsExists = true;

    //wired method vars
    @track studyTermDetailsResponse;

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
     * @descripton connected callback
     */
    connectedCallback() {

    }

    /**
     * @description To get the study term name and educational institution id
     */
    @wire(ctrlGetStudyTermDetails, {
        studyTermRecordId: '$recordId'
    })
    ctrlStudyTermDetails(result) {
        this.studyTermDetailsResponse = null;

        if (result.data) {
            this.studyTermDetailsResponse = JSON.parse(result.data.responseData);

            this.consoleLog(this.studyTermDetailsResponse, true);

        } else if (result.error) {
            promptError(customLabels.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    /**
     * @description Get term and campus combobox options
     */
    @wire(ctrlGetComboboxOptions, {
        eduInstitutionId: '$eduInstitutionId',
        currentTermId: '$recordId'
    })
    wiredComboboxOptions(result) {
        this.comboboxOptionsResponse = null;

        if (result.data) {
            this.comboboxOptionsResponse = JSON.parse(result.data.responseData);

            this.consoleLog(this.comboboxOptionsResponse, true);

        } else if (result.error) {
            promptError(customLabels.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    /**
     * @description Get available study intakes
     */
    @wire(ctrlGetStudyIntakes, {
        selectedStudyProgramId: "$selectedStudyProgramId",
        selectedCampusId: "$selectedCampusId",
        studyIntakeSelectionTableFields: "$studyIntakeSelectionTableFields",
        language: '$language',
        enableWrapText: '$enableWrapText'
    })
    wiredStudyIntakes(result) {
        if (result.data) {
            let datatableConfig = JSON.parse(result.data.responseData);
            
            this.consoleLog(datatableConfig, true);

            datatableConfig = updateDatatableConfig(datatableConfig, false, this.language);

            this.studyIntakesData = datatableConfig.records || [];
            this.studyIntakesColumn = datatableConfig.columns || [];

            this.studyIntakeReady = true;
            this.availableStudyIntakeFound = this.studyIntakesData.length > 0;

        } else if (result.error) {
            promptError(customLabels.ERROR_LABEL, getErrorMessage(result.error));
        }
    }

    /**
     * @description the user language
     */
    get language() {
        return formatLanguageCodeToPosix(LANG);
    }

    /**
     * @description Get term enrollment records count
     */
    getTermEnrollmentRecords() {
    
        this.toggleSpinner(1);

        try {
            ctrlGetTermEnrollmentRecords ({
                selectedStudyIntakeIds: this.selectedStudyIntakeIds,
                selectedCampusId: this.selectedCampusId,
                selectedAcademicTermId: this.selectedTermId,
                academicTermToBeEnroll: this.recordId,
                eligibleStudentCountTableStudyIntakeField: this.eligibleStudentCountTableStudyIntakeField,
                enableWrapText: this.enableWrapText
            })
            .then(response => {
                
                this.consoleLog(response, true);

                this.termEnrollmentRecordCountData = [];
                this.termEnrollmentRecordCountColumn = [];
                this.ipwIds = [];
        
                if(response.responseData) {
                    const responseData = JSON.parse(response.responseData);
                    this.termEnrollmentData = responseData;
        
                    if (responseData.columns) {
                        responseData.columns.forEach(column => {
                            let columnDef = {
                                label: column.label,
                                fieldName: column.fieldName,
                                wrapText: this.enableWrapText
                            };
        
                            //Special handling for exclusion column
                            if(column.fieldName === 'detailsOfRecordsToBeExcluded') {
                                columnDef = {
                                    ...columnDef,
                                    type: 'customRichTextCol',
                                    typeAttributes: {
                                        value: { fieldName: column.fieldName }
                                    },
                                    initialWidth: 350
                                };
                            }

                            if(column.fieldName === 'detailsOfRecordsToBeProcessed') {
                                columnDef = {
                                    ...columnDef,
                                    initialWidth: 200
                                };
                            }
        
                            this.termEnrollmentRecordCountColumn.push(columnDef);
                        });
                    }
        
                    if (responseData.records) {
                        responseData.records.forEach(data => {
                            let rowData = {};
                            
                            Object.keys(data).forEach(key => {
                                rowData[key] = data[key];
                            });
        
                            this.termEnrollmentRecordCountData.push(rowData);
                        });
                    }
        
                    //Process IPW IDs from term enrollment
                    if (responseData.studyIntakesWithIPWToBeProcessedInTermEnrollment) {
                        Object.values(responseData.studyIntakesWithIPWToBeProcessedInTermEnrollment)
                            .forEach(records => {
                                records.forEach(record => {
                                    this.ipwIds.push(...Object.values(record));
                                });
                            });
                    }
        
                    //Process IPW IDs from unit enrollment
                    if (responseData.studyIntakesWithIPWToBeProcessedInOnlyUnitEnrollment) {
                        Object.values(responseData.studyIntakesWithIPWToBeProcessedInOnlyUnitEnrollment)
                            .forEach(records => {
                                records.forEach(record => {
                                    this.ipwIds.push(...Object.values(record));
                                });
                            });
                    }
        
                    this.toBeProcessedRecordsExists = this.ipwIds.length > 0;

                    this.toggleSpinner(-1);
                }
            })
            .catch(error => {
                promptError(customLabels.ERROR_LABEL, getErrorMessage(error));
                this.toggleSpinner(-1);
            });
        } catch (error) {
            this.toggleSpinner(-1);
            promptError(customLabels.ERROR_LABEL, getErrorMessage(error));
        }
    }

    /**
     * @description Get final enrollment records count
     */
    getFinalRecordCount() {
        this.toggleSpinner(1);

        this.finalRecordCountColumn = [];
        this.finalRecordCountData = [];

        if (this.termEnrollmentData) {
            const { 
                columns,
                studyIntakesIdWithName, 
                studyIntakesWithIPWToBeProcessedInOnlyUnitEnrollment, 
                studyIntakesWithIPWToBeProcessedInTermEnrollment 
            } = this.termEnrollmentData;

            if (columns) {
                columns.forEach(column => {
                    if(column.fieldName !== 'detailsOfRecordsToBeProcessed' && column.fieldName !== 'detailsOfRecordsToBeExcluded') {
                        this.finalRecordCountColumn.push({
                            label: column.label,
                            fieldName: column.fieldName,
                            wrapText: this.enableWrapText
                        });
                    }
                });
            }

            //Add fixed enrollment count columns
            this.finalRecordCountColumn.push({
                label: ELIGIBLE_FOR_TERM_ENROLLMENT_COUNT_LABEL,
                fieldName: 'numberOfRecordsToBeProcessedForTermEnrollment',
            });
            
            this.finalRecordCountColumn.push({
                label: ELIGIBLE_FOR_UNIT_ENROLLMENT_COUNT_LABEL,
                fieldName: 'numberOfRecordsToBeProcessedForUnitEnrollment',
            });

            Object.keys(studyIntakesIdWithName).forEach(studyIntakeId => {
                const termEnrollmentRecords = studyIntakesWithIPWToBeProcessedInTermEnrollment[studyIntakeId] || [];
                const unitEnrollmentRecords = studyIntakesWithIPWToBeProcessedInOnlyUnitEnrollment[studyIntakeId] || [];
                
                //Calculate enrollment counts
                const numberOfRecordsToBeProcessedForTermEnrollment = termEnrollmentRecords.length;
                let numberOfRecordsToBeProcessedForUnitEnrollment = unitEnrollmentRecords.length + termEnrollmentRecords.length;
                
                if (this.proceedForUnitEnrollment === false) {
                    numberOfRecordsToBeProcessedForUnitEnrollment = SKIP_UNIT_ENROLLMENT_MESSAGE;
                }

                let rowData = {};

                if (this.termEnrollmentData.records) {
                    const matchingData = this.termEnrollmentData.records.find(data => data.Id === studyIntakeId);

                    if (matchingData) {
                        Object.keys(matchingData).forEach(key => {
                            rowData[key] = matchingData[key];
                        });
                    }
                }

                //Add fixed enrollment count fields
                rowData = {
                    ...rowData,
                    numberOfRecordsToBeProcessedForTermEnrollment,
                    numberOfRecordsToBeProcessedForUnitEnrollment
                };

                this.finalRecordCountData.push(rowData);
            });
        }

        this.consoleLog(this.finalRecordCountData, true);

        this.toggleSpinner(-1);
    }

    /**
     * @description Validate the input fields on the quick action to ensure that all required fields are filled.
     * @returns boolean
     */
    validateComboboxInputFields() {
        const comboboxValid = [...this.template.querySelectorAll('lightning-combobox')]
            .reduce((validSoFar, inputField) => {
                inputField.reportValidity();
                return validSoFar && inputField.checkValidity();
            }, true);
    
        return comboboxValid;
    }

    /**
     * @description Handle Term Enrollment Selection Screen Next On Click
     */
    handleTermEnrollmentSelectionScreenNextOnClick(){
        const datatableValid = this.selectedStudyIntakeIds && this.selectedStudyIntakeIds.length > 0;
        this.studyIntakeSelected  = datatableValid;

        if(this.validateComboboxInputFields() && this.studyIntakeSelected) {

            this.isTermEnrollmentSelectionScreen = false;
            this.isTermEnrollmentCountScreen = true;

            this.getTermEnrollmentRecords();
        }
    }

    /**
     * @description Handle Term Enrollment Selection Screen Previous On Click
     */
    handleTermEnrollmentCountScreenPreviousOnClick(){
        this.isTermEnrollmentCountScreen = false;
        this.isTermEnrollmentSelectionScreen = true;
    }

    /**
     * @description Handle Term Enrollment Count Screen Next On Click
     */
    handleTermEnrollmentCountScreenNextOnClick(){
        if(this.ipwIds.length > 0) {
            this.isTermEnrollmentCountScreen = false;
            this.isUnitEnrollmentSelectionScreen = true;
        }
    }

    /**
     * @description Handle Unit Enrollment Count Screen Previous On Click
     */
    handleUnitEnrollmentSelectionScreenPreviousOnClick(){
        this.isUnitEnrollmentSelectionScreen = false;
        this.isTermEnrollmentCountScreen = true;
    }

    /**
     * @description Handle Unit Enrollment Count Screen Next On Click
     */
    handleUnitEnrollmentSelectionScreenNextOnClick(){
        if(this.validateComboboxInputFields()) {

            this.getFinalRecordCount();

            this.isUnitEnrollmentSelectionScreen = false;
            this.isFinalScreen = true;
        }
    }

    /**
     * @description Handle Final Screen Previous On Click
     */
    handleFinalScreenPreviousOnClick(){
        this.isFinalScreen = false;
        this.isUnitEnrollmentSelectionScreen = true;
    }

    /**
     * @description Handle Final Screen Start On Click
     */
    handleFinalScreenStartOnClick(){
        this.toggleSpinner(1);

        if(this.ipwIds || this.ipwIds.length > 0) {
            ctrlInitQueueJob({
                jobOperation: this.jobOperation,
                toBeProcessedIpwIds: this.ipwIds,
                toBeEnrolledTermId: this.recordId,
                proceedForUnitEnrollment: this.proceedForUnitEnrollment,
                bypassRequirementRules: this.bypassRequirementMetRules,
                existingIndividualEnrollmentStatuses: this.existingIndividualEnrollmentStatuses
            })
            .then(saveResult => {
                promptSuccess(QUEUE_JOB_SUBMITTED_MSG);
                this.toggleSpinner(-1);
                this.close('submitted');
            })
            .catch(error => {
                promptError(customLabels.ERROR_LABEL, getErrorMessage(error));
                this.toggleSpinner(-1);
                this.close('failed');
            })
        }
    }

    handleCancelOnClick() {
        this.close('cancel');
    }

     /**
     * @description Handle campus combobox on change
     */
     handleComboboxChange(event) {
        const { fieldName, selectedOpt } = event.detail;

        if (fieldName) {
            if (fieldName === this.PAST_ACADEMIC_TERM_COMBOBOX_FIELD_NAME) {
                this.selectedTermId = selectedOpt?.value || '';
            } else if (fieldName === this.CAMPUS_COMBOBOX_FIELD_NAME) {
                this.selectedCampusId = selectedOpt?.value || undefined;

                if (!this.selectedCampusId) {
                    //Remove the queried study intakes and hide the datatable when the campus combobox is cleared
                    this.studyIntakesData = [];
                    this.studyIntakeReady = false;

                    this.selectedStudyIntakeIds = [];
                }
            } else if (fieldName === this.STUDY_PROGRAM_COMBOBOX_FIELD_NAME) {
                this.selectedStudyProgramId = selectedOpt?.value || undefined;

                if (!this.selectedStudyProgramId) {
                    //Remove the queried study intakes and hide the datatable when the study program combobox is cleared
                    this.studyIntakesData = [];
                    this.studyIntakeReady = false;

                    this.selectedStudyIntakeIds = [];
                }
            }
        }
    }

    /**
     * @description assign value when the campus combobox chaneged
     */
    handleCampusComboboxChange(event) {
        this.selectedCampusId = event.detail.value;
        this.selectedStudyIntakeIds = [];
        this.studyIntakeSelected = true; 
    }

    /**
     * @description assign value when the study progam combobox chaneged
     */
    handleStudyProgramComboboxChange(event) {
        this.selectedStudyProgramId = event.detail.value;
        this.selectedStudyIntakeIds = [];
        this.studyIntakeSelected = true; 
    }

    /**
     * @description Get selected Study Intakes for datatable
     */
    getSelectedStudyIntakes(event) {
        const selectedRows = event.detail.selectedRows;
        this.selectedStudyIntakeIds = selectedRows.map(row => row.Id);
        this.studyIntakeSelected = this.selectedStudyIntakeIds.length > 0;
    }

    /**
     * @description assign value when the unit enrollment combobox chaneged
     */
    handleUnitEnrollmentComboboxChange(event) {
        this.proceedForUnitEnrollment = event.detail.value === "true";
        this.selectedUnitEnrollmentResult = event.detail.value;
    }

    /**
     * @description assign value when the unit enrollment checkbox chaneged
     */
    handleUnitEnrollmentBypassComboboxChange(event) {
        this.bypassRequirementMetRules = event.detail.value === "true";
        this.selectedBypassRequirementMetRules = event.detail.value;
    }

    /**
     * @description Return academicYearName
     */
    get academicYearName() {
        return this.studyTermDetailsResponse?.academicYearName;
    }

    /**
     * @description Return termName
     */
    get termName() {
        return this.studyTermDetailsResponse?.studyTermName;
    }

    /**
     * @description Return eduInstitutionId
     */
    get eduInstitutionId() {
        return this.studyTermDetailsResponse?.eduInstitutionId;
    }

    /**
     * @description Return campusComboboxOptions
     */
    get campusComboboxOptions() {
        if(this.comboboxOptionsResponse?.campus) {
            return setupPicklistOptionsFromRecords(this.comboboxOptionsResponse?.campus, '');
        }

        return [];
    }

    /**
     * @description Return termComboboxOptions
     */
    get termComboboxOptions() {
        if(this.comboboxOptionsResponse?.term) {
            return setupPicklistOptionsFromRecords(this.comboboxOptionsResponse?.term, '');
        }

        return [];
    }

    /**
     * @description Return studyProgramComboboxOptions
     */
    get studyProgramComboboxOptions() {
        if(this.comboboxOptionsResponse?.studyProgram) {
            return setupPicklistOptionsFromRecords(this.comboboxOptionsResponse?.studyProgram, '');
        }

        return [];
    }

    /**
     * @description Return messageWhenComboboxNotSelected label
     */
    get messageWhenComboboxNotSelected() {
        return MESSAGE_WHEN_COMBOBOX_NOT_SELECTED;
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
     * @description Return studyTermName
     */
    get studyTermName () {
        return this.termName || '';
    }

    /**
     * @description Return sub title
     */
    get modalSubTitle() {
        return MODAL_SUB_TITLE.format([this.studyTermName]);
    }

    /**
     * @description Return term combobox label
     */
    get selectPastAcademicTermComboboxLabel() {
        return SELECT_PAST_ACADEMIC_TERM_COMBOBOX_LABEL;
    }

    /**
     * @description Return campus combobox label
     */
    get campusComboboxLabel() {
        return CAMPUS_COMBOBOX_LABEL;

    }

    /**
     * @description Return study program combobox label
     */
    get studyProgramComboboxLabel() {
        return STUDY_PROGRAM_COMBOBOX_LABEL;

    }

    /**
     * @description Return study intakes datatable label
     */
    get studyIntakesDatatableLabel() {
        return STUDY_INTAKES_DATATABLE_LABEL;

    }

    /**
     * @description Return study intake not selected error msg
     */
    get studyIntakeNotSelectedErrorMsg() {
        return STUDY_INTAKE_NOT_SELECTED;
    }

    /**
     * @description Return no study intake found error msg
     */
    get noAvailableStudyIntakeFoundErrorMsg() {
        return NO_AVAILABLE_STUDY_INTAKE_FOUND;
    }

    /**
     * @description Return unit enrollment combobox label
     */
    get enrollMandatoryStudyUnitsComboboxLabel() {
        return ENROLL_MANDATORY_STUDY_UNITS_COMBOBOX_LABEL;
    }

    /**
     * @description Return unit enrollment checkbox label
     */
    get bypassRequirementMetRulesComboboxLabel() {
        return BYPASS_REQUIREMENT_RULES_COMBOBOX_LABEL;
    } 

    /**
     * @description Return to be processed records not exists error msg
     */
    get termStudentEnrollmentNoProgramEnrollmentFound() {
        return TERM_STUDENT_ENROLLMENT_NO_PROGRAM_ENROLLMENT_FOUND;
    }

    /**
     * @description Return term enrollment screen breif description
     */
    get termStudentEnrollmentStep1BriefDescription() {
        return TERM_STUDENT_ENROLLMENT_STEP1_BRIEF_DESCRIPTION;
    }

    /**
     * @description Return term enrollment count screen breif description
     */
    get termStudentEnrollmentStep2BriefDescription() {
        return TERM_STUDENT_ENROLLMENT_STEP2_BRIEF_DESCRIPTION;
    }

    /**
     * @description Return unit enrollment screen breif description
     */
    get termStudentEnrollmentStep3BriefDescription() {
        return TERM_STUDENT_ENROLLMENT_STEP3_BRIEF_DESCRIPTION;
    }

    /**
     * @description Return final screen breif description
     */
    get termStudentEnrollmentStep4BriefDescription() {
        return TERM_STUDENT_ENROLLMENT_STEP4_BRIEF_DESCRIPTION;
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
     * @description Return current step for progress indicator
     */
    get currentStep() {
        if(this.isTermEnrollmentSelectionScreen) {
            return '1';
        } else if (this.isTermEnrollmentCountScreen) {
            return '2';
        } else if (this.isUnitEnrollmentSelectionScreen) {
            return '3';
        } else if (this.isFinalScreen) {
            return '4';
        }

        return null;
    }

    /**
    * @description Return progressIndicatorStep1 label
    */
    get progressIndicatorStep1Label() {
        return PROGRESS_INDICATOR_STEP_ONE_LABEL;
    }

    /**
    * @description Return progressIndicatorStep2 label
    */
    get progressIndicatorStep2Label() {
        return PROGRESS_INDICATOR_STEP_TWO_LABEL;
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
    * @description Return isTermEnrollmentSelectionScreenNextDisabled
    */
    get isTermEnrollmentSelectionScreenNextDisabled() {
        return !this.selectedTermId || !this.selectedCampusId || !this.selectedStudyProgramId || this.selectedStudyIntakeIds.length === 0;
    }
    
    /**
    * @description Return isTermEnrollmentCountScreenNextDisabled
    */
    get isTermEnrollmentCountScreenNextDisabled() {
        return !this.ipwIds || this.ipwIds.length === 0;
    }
    
    /**
    * @description Return isUnitEnrollmentSelectionScreenNextDisabled
    */
    get isUnitEnrollmentSelectionScreenNextDisabled() {
        return !this.selectedUnitEnrollmentResult || (this.proceedForUnitEnrollment && !this.selectedBypassRequirementMetRules);
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
        return this.loadedLists === 0 && this.studyTermDetailsResponse?.eduInstitutionId ? false : true;
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
        logInfo('TermStudentEnrollmentModal', anything, this.enableDebugMode, isJson);
    }
}
