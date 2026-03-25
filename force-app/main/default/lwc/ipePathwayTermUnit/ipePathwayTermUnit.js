/**
 * @Author 		WDCi (Lean)
 * @Date 		Oct 2023
 * @group 		Enrollment Wizard
 * @Description Student enrollment wizard
 * @changehistory
 * ISS-001752 05-10-2022 Lean - new component
 * ISS-001878 14-06-2024 Sueanne - update isPastCensusDate to match with date only
 * ISS-001979 19-07-2024 Sueanne - to open pre-enrollment for study unit when its pre-requisite that going to complete
 * ISS-002066 04-09-2024 Sueanne - update ipsEnrollmentStatusText
 * ISS-002119 30-09-2024 Lean - Make enrollment buttons visible to admin when sof self enrollment is disabled
 * ISS-002230 04-02-2025 XW - all picklist value now display in label
 * ISS-002336 24-03-2024 Lean - Added missed/failed unit
 * ISS-002231 25-03-2025 Lean - Added deferred status
 * ISS-002365 27-03-2025 Lean - Track and display based on ien that matches the term
 * ISS-002373 14-04-2025 XiRouh - Added finalGradeReleasedStatuses variable and updated ipsEnrollmentStatusText to hide the result if the grade release status is not final released status, moved ienGradeResultPicklistValues to ipePathwayTermUnitTable
 * ISS-002374 14-04-2025 XiRouh - Updated to hide the action button if the grade release status is one of the internal release statuses
 * ISS-002400 25-04-2025 XiRouh - Added isIpsCurrentIenCreditTransfer so hide the action button if the ips current ien is credit transfer
 * ISS-002445 06-05-2025 XiRouh - Added the isActiveIen and showIpsEnrollmentStatusText getters, the ipsEnrollmentStatusText will only be displayed if the IEN is in a positive status, so that when the IEN is withdrawn, dropped, or deferred, the text (e.g., 'Withdrawn - T1 2024') will not be shown, moved the !isEnrolledInOtherTerm logic from the showActionButton getter to each button's individual getter, so that the withdrawn-type button will only be shown if the study unit is already enrolled in viewing term
 * ISS-002442 07-05-2025 XiRouh - updated the translatedStudyTermName getter to use the translated field when it returns a value, otherwise, display name field
 * ISS-002483 20-05-2025 XiRouh - Updated to handle the completed but failed re-enrollment issue; refer to the issue number in the code for details
 * ISS-002486 10-06-2025 XiRouh - Introduce New IEN Status: Completed – Failed; refer to the issue number in the code for details
 * ISS-002514 10-06-2025 XW - Updated upsertEnrollment to accept enrollment status to change to
 * ISS-002495 29-09-2025 XW - support translation for long text field
 */
import { LightningElement, api, track, wire } from 'lwc';
import { promptInfo, promptError, promptWarning, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';
import { customLabels } from 'c/labelLoader';
import { formatDateTime, commonConstants, extractFieldValue } from 'c/lwcUtil';
import { ipePathwayConstants, ipsUnitStatusTypes, ienEnrollmentStatusTypes, sofStatusTypes } from 'c/ipePathwaysHelper';

//internationalization
import LOCALE from "@salesforce/i18n/locale";
import TIME_ZONE from '@salesforce/i18n/timeZone';

//overlay modal
import unitInfoModal from 'c/unitInfoModal';
import confirmationModal from 'c/genericConfirmationModal';

//additional labels
import ENROLLMENT_STATUS_COL_LABEL from '@salesforce/label/c.Enrollment_Status_Column';
import OFFERING_STATUS_COL_LABEL from '@salesforce/label/c.Offering_Status_Column';
import STATUS_COL_LABEL from '@salesforce/label/c.Status_Column';
import MULTIPLE_OFFERINGS_LABEL from '@salesforce/label/c.Multiple_Offerings';
import REQUIREMENT_NOT_MET_LABEL from '@salesforce/label/c.Requirement_Not_Met';

import NOT_STARTED_WITH_PREENROLLDATE_LABEL from '@salesforce/label/c.Offering_Not_Started_With_Pre_Enrollment_Open_Date_Status';
import NOT_STARTED_WITH_ENROLLDATE_LABEL from '@salesforce/label/c.Offering_Not_Started_Enrollment_Open_Date_Status';
import STARTED_PREENROLL_OPENED_LABEL from '@salesforce/label/c.Offering_Started_Pre_Enrollment_Opened_Status';
import STARTED_ENROLL_OPENED_LABEL from '@salesforce/label/c.Offering_Started_Enrollment_Opened_Status';
import STARTED_ENROLL_CLOSED_LABEL from '@salesforce/label/c.Offering_Started_Enrollment_Closed_Status';
import OFFERING_RUNNING_LABEL from '@salesforce/label/c.Offering_Running';

import PREENROLL_CONFIRMATION_LABEL from '@salesforce/label/c.Pre_Enrollment_Confirmation';
import WITHDRAW_PREENROLL_CONFIRMATION_LABEL from '@salesforce/label/c.Withdraw_Pre_Enrollment_Confirmation';
import ENROLL_CONFIRMATION_LABEL from '@salesforce/label/c.Enrollment_Confirmation';
import ENROLL_ADDITIONAL_INFO_LABEL from '@salesforce/label/c.Enrollment_Confirmation_Additional_Info';
import UNENROLL_CONFIRMATION_LABEL from '@salesforce/label/c.Unenrollment_Confirmation';
import REQUEST_UNENROLL_CONFIRMATION_LABEL from '@salesforce/label/c.Request_Unenrollment_Confirmation';
import JOIN_WAITLIST_CONFIRMATION_LABEL from '@salesforce/label/c.Join_Waitlist_Confirmation';
import WITHDRAW_WAITLIST_CONFIRMATION_LABEL from '@salesforce/label/c.Withdraw_Waitlist_Confirmation';

import IPS_STATUS_LABEL from '@salesforce/label/c.Enrollment_Wizard_IPS_Status';
import MISSED_FAILED_UNIT_LABEL from '@salesforce/label/c.Missed_Failed_Study_Unit_Warning';

export default class IpePathwayTermUnit extends LightningElement {
	
	//configurable attributes
    @api individualPathwayId;
    @api ipsRecord;
    @api unitTableColumns;
    @api sofStatuses;
    @api internalGradeReleasedStatuses;
    @api finalGradeReleasedStatuses;
    @api ienGradeResultPicklistValues;
    @api ipsUnitStatuses;
    @api ienEnrollmentStatuses;
    @api isOption = false;
    @api userMode;
    @api isEligibleToEnroll = false;
    @api sceSetting;
    @api sofNameTranslationField;
    @api stmNameTranslationField;
    @api sunNameTranslationField;
    @api translationInfo;

    //configurable attributes - view info fields
    @api studyUnitInfoFields;
    @api studyOfferingInfoFields;
    @api studyPlanStructureUnitInfoFields;

    //configurable attributes - enrollment button icon and label
    @api showEnrollmentButtons = false;
    @api preEnrollButtonIconName;
    @api preEnrollButtonLabel;
    @api preEnrollEnrollmentStatus;
    @api withdrawPreEnrollButtonIconName;
    @api withdrawPreEnrollButtonLabel;
    @api withdrawPreEnrollEnrollmentStatus;
    @api enrollButtonIconName;
    @api enrollButtonLabel;
    @api enrollEnrollmentStatus;
    @api unenrollButtonIconName;
    @api unenrollButtonLabel;
    @api unenrollEnrollmentStatus;
    @api unenrollRequestButtonIconName;
    @api unenrollRequestButtonLabel;
    @api unenrollRequestEnrollmentStatus;
    @api waitlistButtonIconName;
    @api waitlistButtonLabel;
    @api waitlistEnrollmentStatus;
    @api withdrawWaitlistButtonIconName;
    @api withdrawWaitlistButtonLabel;
    @api withdrawWaitlistEnrollmentStatus;

    @api ipwRecord;

    @api showActionColumn = false;
    @api showIndicatorColumn = false;

    //configurable attributes - debugging
	@api enableDebugMode = false;
	
	//internal attributes
    @api lwcReactor; //for reactive rerender only
	loadedLists = 0;

    @track nowTime = new Date();

	//labels
	label = {
        ENROLLMENT_STATUS_COL_LABEL, 
        OFFERING_STATUS_COL_LABEL,
        STATUS_COL_LABEL,
        MULTIPLE_OFFERINGS_LABEL,
        REQUIREMENT_NOT_MET_LABEL,
        NOT_STARTED_WITH_PREENROLLDATE_LABEL,
        NOT_STARTED_WITH_ENROLLDATE_LABEL,
        STARTED_PREENROLL_OPENED_LABEL,
        STARTED_ENROLL_OPENED_LABEL,
        STARTED_ENROLL_CLOSED_LABEL,
        OFFERING_RUNNING_LABEL,
        PREENROLL_CONFIRMATION_LABEL,
        WITHDRAW_PREENROLL_CONFIRMATION_LABEL,
        ENROLL_CONFIRMATION_LABEL,
        ENROLL_ADDITIONAL_INFO_LABEL,
        UNENROLL_CONFIRMATION_LABEL,
        REQUEST_UNENROLL_CONFIRMATION_LABEL,
        JOIN_WAITLIST_CONFIRMATION_LABEL,
        WITHDRAW_WAITLIST_CONFIRMATION_LABEL,
        ...customLabels
    };

    /**
     * @descripton connected callback
     */
    connectedCallback(){
        this.consoleLog('nowTime :: ' + this.nowTime?.toISOString());
	}
	
    /**
     * @descripton disconnected callback
     */
	disconnectedCallback() {
		
	}

    /**
     * @description Return translated study offering name value
     */
    get translatedStudyOfferingName() {

        if (this.localIpsRecord.sof && Object.hasOwn(this.localIpsRecord.sof, this.sofNameTranslationField)) {
            return this.localIpsRecord.sof[this.sofNameTranslationField];
        } else if (this.localIpsRecord.sof) {
            return this.localIpsRecord?.sof?.Name;
        }

        return null;
    }

    /**
     * @description Return translated study session name value
     */
    get translatedStudyTermName() {
        let ienTerm = this.ienToBeReferredInCurrentTerm?.reduivy__Study_Offering__r?.reduivy__Academic_Term__r

        let ienTermName;
        
        if(this.stmNameTranslationField) {
            ienTermName = extractFieldValue(ienTerm, this.stmNameTranslationField);
        } 

        if(!ienTermName) {
            ienTermName = extractFieldValue(ienTerm, 'reduivy__Display_Name__c');
        }

        return ienTermName;
    }

    /**
     * @description Return enrollment table columns metadata
     */
    get columnsMetadata() {
        if (this.unitTableColumns && this.unitTableColumns.length > 0) {
            return this.unitTableColumns;
        }

        return null;
    }

    /**
     * @description Return true if the current ips record has multiple sof options
     */
    get hasOptions() {
        if (this.localIpsRecord.options && this.localIpsRecord.options.length > 0) {
            return true;
        }

        return false;
    }

    /**
     * @description Return chevron icon name
     */
    get chevronIconName() {
        if (this.hasOptions && this.isOptionsExpanded) {
            return 'utility:chevrondown';
        }

        return 'utility:chevronright';
    }

    /**
     * @description Return true if the sof options is expanded
     */
    get isOptionsExpanded() {
        if (this.hasOptions && this.localIpsRecord.isOptionsExpanded) {
            return true;
        }

        return false;
    }

    /**
     * @description Reative method to return the current ips record
     */
    get localIpsRecord() {
        //this is to force the component to rerender when the lwcReactor value is changed
        let lwcReactor = this.lwcReactor;

        return this.ipsRecord;
    }

    /**
     * @description Return ips unit not started type status
     */
    get ipsUnitNotStartedStatuses() {
        if (this.ipsUnitStatuses && Object.hasOwn(this.ipsUnitStatuses, ipsUnitStatusTypes.IPS_STATUS_TYPE_NOTSTARTED)) {
            return this.ipsUnitStatuses[ipsUnitStatusTypes.IPS_STATUS_TYPE_NOTSTARTED];
        }

        return [];
    }

    /**
     * @description Return ien open/not started type status
     */
    get ienOpenStatuses() {
        if (this.ienEnrollmentStatuses && Object.hasOwn(this.ienEnrollmentStatuses, ienEnrollmentStatusTypes.IEN_STATUS_TYPE_OPEN)) {
            return this.ienEnrollmentStatuses[ienEnrollmentStatusTypes.IEN_STATUS_TYPE_OPEN];
        }

        return [];
    }

    /**
     * @description Return ien enrollment requested type status
     */
    get ienEnrollmentRequestedStatuses() {
        if (this.ienEnrollmentStatuses && Object.hasOwn(this.ienEnrollmentStatuses, ienEnrollmentStatusTypes.IEN_STATUS_TYPE_ENROLLMENT_REQUESTED)) {
            return this.ienEnrollmentStatuses[ienEnrollmentStatusTypes.IEN_STATUS_TYPE_ENROLLMENT_REQUESTED];
        }

        return [];
    }

    /**
     * @description Return ien enrollment requested type status
     */
    get ienWaitlistedStatuses() {
        if (this.ienEnrollmentStatuses && Object.hasOwn(this.ienEnrollmentStatuses, ienEnrollmentStatusTypes.IEN_STATUS_TYPE_WAITLISTED)) {
            return this.ienEnrollmentStatuses[ienEnrollmentStatusTypes.IEN_STATUS_TYPE_WAITLISTED];
        }

        return [];
    }

    /**
     * @description Return ien withdrawal requested type status
     */
    get ienWithdrawalRequestedStatuses() {
        if (this.ienEnrollmentStatuses && Object.hasOwn(this.ienEnrollmentStatuses, ienEnrollmentStatusTypes.IEN_STATUS_TYPE_WITHDRAWN_REQUESTED)) {
            return this.ienEnrollmentStatuses[ienEnrollmentStatusTypes.IEN_STATUS_TYPE_WITHDRAWN_REQUESTED];
        }

        return [];
    }

    /**
     * @description Return ien completed enrollment type status
     */
    get ienCompletedStatuses() {
        if (this.ienEnrollmentStatuses && Object.hasOwn(this.ienEnrollmentStatuses, ienEnrollmentStatusTypes.IEN_STATUS_TYPE_COMPLETED)) {
            return this.ienEnrollmentStatuses[ienEnrollmentStatusTypes.IEN_STATUS_TYPE_COMPLETED];
        }

        return [];
    }

    /**
     * @description Return ien completed fail enrollment type status (ISS-002486 - New Status)
     */
    get ienCompletedFailStatuses() {
        if (this.ienEnrollmentStatuses && Object.hasOwn(this.ienEnrollmentStatuses, ienEnrollmentStatusTypes.IEN_STATUS_TYPE_COMPLETED_FAIL)) {
            return this.ienEnrollmentStatuses[ienEnrollmentStatusTypes.IEN_STATUS_TYPE_COMPLETED_FAIL];
        }

        return [];
    }

    /**
     * @description Return ien non enrollable enrollment type status
     */
    get ienNonEnrollableStatuses() {
        if (this.ienEnrollmentStatuses && Object.hasOwn(this.ienEnrollmentStatuses, ienEnrollmentStatusTypes.IEN_STATUS_TYPE_NONENROLLABLE)) {
            return this.ienEnrollmentStatuses[ienEnrollmentStatusTypes.IEN_STATUS_TYPE_NONENROLLABLE];
        }

        return [];
    }

    /**
     * @description Return ips unit non enrollable type status
     */
    get ipsUnitNonEnrollableStatuses() {
        if (this.ipsUnitStatuses && Object.hasOwn(this.ipsUnitStatuses, ipsUnitStatusTypes.IPS_STATUS_TYPE_NONENROLLABLE)) {
            return this.ipsUnitStatuses[ipsUnitStatusTypes.IPS_STATUS_TYPE_NONENROLLABLE];
        }

        return [];
    }

    /**
     * @description ISS-002231 Return ien deferred enrollment type status
     */
    get ienDeferredStatuses() {
        if (this.ienEnrollmentStatuses && Object.hasOwn(this.ienEnrollmentStatuses, ienEnrollmentStatusTypes.IEN_STATUS_TYPE_DEFERRED)) {
            return this.ienEnrollmentStatuses[ienEnrollmentStatusTypes.IEN_STATUS_TYPE_DEFERRED];
        }

        return [];
    }

    /**
     * @description ISS-002231 Return ips unit deferred type status
     */
    get ipsUnitDeferredStatuses() {
        if (this.ipsUnitStatuses && Object.hasOwn(this.ipsUnitStatuses, ipsUnitStatusTypes.IPS_STATUS_TYPE_DEFERRED)) {
            return this.ipsUnitStatuses[ipsUnitStatusTypes.IPS_STATUS_TYPE_DEFERRED];
        }

        return [];
    }

    /**
     * @description Return sof not started type status
     */
    get sofNotStartedStatuses() {
        if (this.sofStatuses && Object.hasOwn(this.sofStatuses, sofStatusTypes.SOF_STATUS_TYPE_NOTSTARTED)) {
            return this.sofStatuses[sofStatusTypes.SOF_STATUS_TYPE_NOTSTARTED];
        }

        return [];
    }

    /**
     * @description Return sof pre enrollment opened type status
     */
    get sofPreEnrollmentOpenedStatuses() {
        if (this.sofStatuses && Object.hasOwn(this.sofStatuses, sofStatusTypes.SOF_STATUS_TYPE_PREENROLLMENT_OPENED)) {
            return this.sofStatuses[sofStatusTypes.SOF_STATUS_TYPE_PREENROLLMENT_OPENED];
        }

        return [];
    }

    /**
     * @description Return sof enrollment opened type status
     */
    get sofEnrollmentOpenedStatuses() {
        if (this.sofStatuses && Object.hasOwn(this.sofStatuses, sofStatusTypes.SOF_STATUS_TYPE_ENROLLMENT_OPENED)) {
            return this.sofStatuses[sofStatusTypes.SOF_STATUS_TYPE_ENROLLMENT_OPENED];
        }

        return [];
    }

    /**
     * @description Return sof enrollment closed type status
     */
    get sofEnrollmentClosedStatuses() {
        if (this.sofStatuses && Object.hasOwn(this.sofStatuses, sofStatusTypes.SOF_STATUS_TYPE_ENROLLMENT_CLOSED)) {
            return this.sofStatuses[sofStatusTypes.SOF_STATUS_TYPE_ENROLLMENT_CLOSED];
        }

        return [];
    }

    /**
     * @description Return sof running type status
     */
    get sofRunningStatuses() {
        if (this.sofStatuses && Object.hasOwn(this.sofStatuses, sofStatusTypes.SOF_STATUS_TYPE_RUNNING)) {
            return this.sofStatuses[sofStatusTypes.SOF_STATUS_TYPE_RUNNING];
        }

        return [];
    }

    /**
     * @description Return true if the current ips is enrollable
     */
    get ipsEnrollable() {

        if (this.localIpsRecord.ips) {
            if (this.hasIndividualEnrollment) {
                let currentStatus = this.academicTermIenEnrollmentStatus ? this.academicTermIenEnrollmentStatus : null;

                if ((this.ienNonEnrollableStatuses.includes(currentStatus) || this.ienCompletedFailStatuses.includes(currentStatus)) || //ISS-002486 - If the IEN is failed in the viewing term, the student should not be allowed to enroll in the same term
                    //disallow enrollment is status is deferred and belongs to the same term
                    (this.ienDeferredStatuses.includes(currentStatus) && !this.isEnrolledInOtherTerm)
                ) {
                    return false;
                }
            } else {
                //for ips without ien, if the status is deferred, we will always show the button as we won't know which term it is to block the student
                let currentStatus = this.ipsStatus ? this.ipsStatus : null;
                
                if (this.ipsUnitNonEnrollableStatuses.includes(currentStatus)) {
                    return false;
                }
            }
        }

        return true;
    }

    /**
     * @description Return enrollment status cell value
     */
    get ipsOfferingStatusText() {

        let statusText;

        if (!this.isTermCompleted) { //we will show only if the term is still open/future
            if (this.ipsRequirementMet) {
                statusText = this.sofEnrollmentStatusText;
            } else {
                statusText = this.label.REQUIREMENT_NOT_MET_LABEL.format([this.ipsRequirementDescription]);
            }
        }

        return statusText;
    }

    /**
     * @description Return the individual enrollment to be referenced in the current viewing term, using either the academicTermIen or ipsCurrentIen
     */
    get ienToBeReferredInCurrentTerm() {
        return this.localIpsRecord?.academicTermIen ? this.localIpsRecord?.academicTermIen : this.localIpsRecord?.ipsCurrentIen;
    }

    /**
     * @description Return if the ienToBeReferredInCurrentTerm is an active ien
     */
    get isActiveIen() {
        return this.ienNonEnrollableStatuses.includes(this.ienToBeReferredInCurrentTerm?.reduivy__Enrollment_Status__c) || 
        this.ienWaitlistedStatuses.includes(this.ienToBeReferredInCurrentTerm?.reduivy__Enrollment_Status__c) ||
        this.ienEnrollmentRequestedStatuses.includes(this.ienToBeReferredInCurrentTerm?.reduivy__Enrollment_Status__c) ||
        this.ienCompletedFailStatuses.includes(this.ienToBeReferredInCurrentTerm?.reduivy__Enrollment_Status__c); //ISS-002486 - Completed Fail also need to display a status label if it is failed in the viewing term or in a completed term
    }

    /**
     * @description Return if the unit should show the ipsEnrollmentStatusText
     */
    get showIpsEnrollmentStatusText() {
        // ISS-002486 - Show status text when:
        // - The IEN is active (i.e., not in a status like withdrawn, dropped, etc.)
        // - It is not enrollable (either because the IPS is in a non-enrollable status or it failed in the viewing term;
        //   this flag helps prevent displaying 'Completed - Fail' just because the course failed elsewhere—
        //   if it failed in a different term but the viewing term allows enrollment, we should not show the 'Completed - Fail' text)
        // - The term is completed
        // - And we are able to construct the status text
        return this.isActiveIen && (!this.ipsEnrollable || this.isTermCompleted) && this.ipsEnrollmentStatusText; 
    }

    /**
     * @description Return enrollment status with related grade reult or study term name
     */
    get ipsEnrollmentStatusText() {
        // let ienStatusLabel = (this.enrolledOfferingId && !this.isOption) || (this.academicTermIenEnrollmentStatus && !this.isEnrolledOfferingNotMatched) ? this.academicTermIenEnrollmentStatusLabel : null;
        let enrollmentStatus = this.academicTermIenEnrollmentStatusLabel || this.ipsCurrentIenEnrollmentStatusLabel

        let ienStatusLabel = (this.enrolledOfferingId && !this.isOption) || (enrollmentStatus) ? enrollmentStatus : null;

        let gradeResult = this.ienToBeReferredInCurrentTerm?.reduivy__Grade_Result__c;

        let termName = this.translatedStudyTermName || this.label.UNKNOWN_LABEL;

        let gradeResultLabel = gradeResult;
        if(gradeResult && this.ienGradeResultPicklistValues?.data && this.isFinalGradeReleaseStatus) {
            let resultLabel = this.ienGradeResultPicklistValues?.data?.values?.find(picklist => picklist.value === gradeResult).label;
            if(resultLabel) {
                gradeResultLabel = resultLabel;
            }
        }

        if(gradeResultLabel && ienStatusLabel && this.isFinalGradeReleaseStatus){
            //if grade result exist, we will combine it with the status (e.g. Completed - Pass)
            return IPS_STATUS_LABEL.format([ienStatusLabel, gradeResultLabel]);

        } else if (ienStatusLabel && termName && !(this.isIpsCurrentIenCreditTransfer && !this.hasIndividualEnrollment)) {
            //if study term found, we will combine it with the status (e.g. Enrolled - T1 2023)
            return IPS_STATUS_LABEL.format([ienStatusLabel, termName]);
        } else if (ienStatusLabel) { //In case it is a credit transfer but somehow not yet in final release status (e.g., internal release)
            return ienStatusLabel;
        }

        return '';
    }

    /**
     * @description Return isFinalGradeReleaseStatus
     */
    get isFinalGradeReleaseStatus() {
        return this.finalGradeReleasedStatuses?.includes(this.gradeReleaseStatus);
    }

    /**
     * @description Return current academic term's ien's grade release status
     */
    get gradeReleaseStatus() {
        return this.ienToBeReferredInCurrentTerm?.reduivy__Grade_Release_Status__c;
    }

    /**
     * @description Return individual plan structure status
     */
    get ipsStatus() {
        if (this.localIpsRecord.ips && !this.ipsUnitNotStartedStatuses.includes(this.localIpsRecord.ips.reduivy__Status__c)) {
            return this.localIpsRecord.ips.reduivy__Status__c;
        }

        return null;
    }

    /**
     * @description Return individual plan structure's individual pathway
     */
    get isEnrolledInOtherTerm() {
        if (this.localIpsRecord && this.localIpsRecord?.isEnrolledInOtherTerm) {
            return this.localIpsRecord?.isEnrolledInOtherTerm;
        }

        return false;
    }

    /**
     * @description Return term individual enrollment's enrollment status
     */
    get academicTermIenEnrollmentStatus() {
        if (this.localIpsRecord.ips && this.localIpsRecord?.academicTermIen && !this.ienOpenStatuses.includes(this.localIpsRecord?.academicTermIen?.reduivy__Enrollment_Status__c)) {
            return this.localIpsRecord?.academicTermIen?.reduivy__Enrollment_Status__c;
        }

        return null;
    }

    /**
     * @description Return term individual enrollment's enrollment status label
     */
    get academicTermIenEnrollmentStatusLabel() {
        if(this.academicTermIenEnrollmentStatus) {
            return this.localIpsRecord?.academicTermIen?.reduivy__Enrollment_Status__c_PicklistLabel;
        }

        return null;
    }

    /**
     * @description Return current individual enrollment's enrollment status
     */
    get ipsCurrentIenEnrollmentStatus() {
        if (this.localIpsRecord.ips && this.localIpsRecord?.ipsCurrentIen && !this.ienOpenStatuses.includes(this.localIpsRecord?.ipsCurrentIen?.reduivy__Enrollment_Status__c)) {
            return this.localIpsRecord?.ipsCurrentIen?.reduivy__Enrollment_Status__c;
        }

        return null;
    }

    /**
     * @description Return current individual enrollment's enrollment status label
     */
    get ipsCurrentIenEnrollmentStatusLabel() {
        if(this.ipsCurrentIenEnrollmentStatus) {
            return this.localIpsRecord?.ipsCurrentIen?.reduivy__Enrollment_Status__c_PicklistLabel;
        }

        return null;
    }

    /**
     * @description Return true if the individual plan structure has an individual enrollment linked
     */
    get hasIndividualEnrollment() {
        if (this.localIpsRecord.ips && this.localIpsRecord?.academicTermIen) {
            return true;
        }

        return false;
    }

    /**
     * @description Return enrolled study offering id
     */
    get enrolledOfferingId() {
        if (this.localIpsRecord.ips && 
            this.localIpsRecord?.academicTermIen &&
            this.localIpsRecord?.academicTermIen?.reduivy__Study_Offering__c
        ) {
            return this.localIpsRecord?.academicTermIen?.reduivy__Study_Offering__c;
        }

        return null;
    }

    /**
     * @description Return true if the individual enrollment's study offering is the same as the current listed study offering option
     */
    get isEnrolledOfferingNotMatched() {
        if (this.enrolledOfferingId && this.enrolledOfferingId !== this.sofId
        ) {
            return true;
        }

        return false;
    }

    /**
     * @description Return requirement met
     */
    get ipsRequirementMet() {

        if (this.localIpsRecord.ips) {
            if (this.localIpsRecord.ips.reduivy__Allow_Pre_Enrollment__c || this.localIpsRecord.ips.reduivy__Requirement_Met__c || this.localIpsRecord.byPassReqMet) {
                return true;
            }
        }

        return false;
    }

    /**
     * @description Return requirement description
     */
    get ipsRequirementDescription() {

        if (this.localIpsRecord.ips) {
            if (this.localIpsRecord.requirementDescription) {
                return this.localIpsRecord.requirementDescription;
            }
        }

        return '';
    }

    /**
     * @description Return individual enrollment census date
     */
    get ipsCensusDate() {
        let targetDate;
        if (this.localIpsRecord?.academicTermIen && this.localIpsRecord?.academicTermIen?.reduivy__Census_Date__c) {
            targetDate = moment.tz(this.localIpsRecord?.academicTermIen?.reduivy__Census_Date__c + 'T23:59:59.999', TIME_ZONE).toDate();

        }

        this.consoleLog('ipsCensusDate ' + targetDate?.toISOString());
        return targetDate;
    }

    /**
     * @description Return study cohort enrollment's study offering status
     */
    get sceSofStatus() {
        if (this.sceSetting && this.sceSetting.reduivy__Study_Offering_Status__c) {
            return this.sceSetting.reduivy__Study_Offering_Status__c;
        }

        return null;
    }

    /**
     * @description Return study offering status type
     */
    get sofStatusType() {

        let statusType;

        if (this.localIpsRecord.sof) {
            let currentStatus = this.sofStatus ? this.sofStatus : null;
            
            if (this.sceSofStatus) {
                //if there is study cohort enrollment found, we will override the sof status

                if (this.sofNotStartedStatuses.includes(this.sceSofStatus)
                    || this.sofPreEnrollmentOpenedStatuses.includes(this.sceSofStatus)
                    || this.sofEnrollmentOpenedStatuses.includes(this.sceSofStatus)
                    || this.sofEnrollmentClosedStatuses.includes(this.sceSofStatus)
                ) {
                    currentStatus = this.sceSofStatus;
                }
            }

            if (this.sofNotStartedStatuses.includes(currentStatus)) {
                statusType = sofStatusTypes.SOF_STATUS_TYPE_NOTSTARTED;

            } else if (this.sofPreEnrollmentOpenedStatuses.includes(currentStatus)) {
                statusType = sofStatusTypes.SOF_STATUS_TYPE_PREENROLLMENT_OPENED;

            } else if (this.sofEnrollmentOpenedStatuses.includes(currentStatus)) {
                statusType = sofStatusTypes.SOF_STATUS_TYPE_ENROLLMENT_OPENED;

            } else if (this.sofEnrollmentClosedStatuses.includes(currentStatus)) {
                statusType = sofStatusTypes.SOF_STATUS_TYPE_ENROLLMENT_CLOSED;

            } else if (this.sofRunningStatuses.includes(currentStatus)) {
                statusType = sofStatusTypes.SOF_STATUS_TYPE_RUNNING;

            }
        }

        return statusType;
    }

    /**
     * @description Return study offering status
     */
    get sofStatus() {
        if (this.localIpsRecord.sof) {
            return this.localIpsRecord.sof.reduivy__Status__c;
        }

        return null;
    }

    /**
     * @description Return study offering status for enrollment status cell
     */
    get sofEnrollmentStatusText() {
        let statusText;

        if (this.sofStatusType === sofStatusTypes.SOF_STATUS_TYPE_NOTSTARTED) {
            if (this.sofPreEnrollmentOpenedDate && this.sofPreEnrollmentOpenedDate > this.nowTime) {
                statusText = this.label.NOT_STARTED_WITH_PREENROLLDATE_LABEL.format([this.sofPreEnrollmentOpenDateStr]);
            } else if (this.sofEnrollmentOpenedDate && this.sofEnrollmentOpenedDate > this.nowTime) {
                statusText = this.label.NOT_STARTED_WITH_ENROLLDATE_LABEL.format([this.sofEnrollmentOpenDateStr]);
            }

        } else if (this.sofStatusType === sofStatusTypes.SOF_STATUS_TYPE_PREENROLLMENT_OPENED) {
            statusText = this.label.STARTED_PREENROLL_OPENED_LABEL;

        } else if (this.sofStatusType === sofStatusTypes.SOF_STATUS_TYPE_ENROLLMENT_OPENED) {
            let param0 = (this.sofEnrollmentClosedDate ? this.sofEnrollmentCloseDateStr : this.label.UNKNOWN_LABEL);
            let param1 = this.remainingPlaces;
            
            statusText = this.label.STARTED_ENROLL_OPENED_LABEL.format([param0, param1]);

        } else if (this.sofStatusType === sofStatusTypes.SOF_STATUS_TYPE_ENROLLMENT_CLOSED) {
            statusText = this.label.STARTED_ENROLL_CLOSED_LABEL;

        } else if (this.sofStatusType === sofStatusTypes.SOF_STATUS_TYPE_RUNNING) {
            statusText = this.label.OFFERING_RUNNING_LABEL;

        }

        return statusText;
    }

    /**
     * @description Return study offering census date
     */
    get sofId() {
        if (this.localIpsRecord.sof && this.localIpsRecord.sof.Id) {
            return this.localIpsRecord.sof.Id;
        }

        return null;
    }

    /**
     * @description Return study offering pre-enrollment open date
     */
    get sofPreEnrollmentOpenedDate() {

        let targetDate;
        if (this.sceSetting) {
            //if there is study cohort enrollment, the date will be used
            if (this.sceSetting.reduivy__Pre_enrollment_Open_Date__c) {
                targetDate = new Date(this.sceSetting.reduivy__Pre_enrollment_Open_Date__c);
            }
        } else if (this.localIpsRecord.sof && this.localIpsRecord.sof.reduivy__Pre_enrollment_Open_Date_Calculated__c) {
            targetDate = new Date(this.localIpsRecord.sof.reduivy__Pre_enrollment_Open_Date_Calculated__c);
        }

        this.consoleLog('sofPreEnrollmentOpenedDate ' + targetDate?.toISOString());
        return targetDate;
    }

    /**
     * @description Return study offering enrollment open date
     */
    get sofEnrollmentOpenedDate() {

        let targetDate;
        if (this.sceSetting) {
            //if there is study cohort enrollment, the date will be used
            if (this.sceSetting.reduivy__Enrollment_Open_Date__c) {
                targetDate = new Date(this.sceSetting.reduivy__Enrollment_Open_Date__c);
            }
        } else if (this.localIpsRecord.sof && this.localIpsRecord.sof.reduivy__Enrollment_Open_Date_Calculated__c) {
            targetDate = new Date(this.localIpsRecord.sof.reduivy__Enrollment_Open_Date_Calculated__c);
        }

        this.consoleLog('sofEnrollmentOpenedDate ' + targetDate?.toISOString());
        return targetDate;
    }

    /**
     * @description Return study offering enrollment close date
     */
    get sofEnrollmentClosedDate() {

        let targetDate;
        if (this.sceSetting) {
            //if there is study cohort enrollment, the date will be used
            if (this.sceSetting.reduivy__Enrollment_Close_Date__c) {
                targetDate = new Date(this.sceSetting.reduivy__Enrollment_Close_Date__c);
            }
        } else if (this.localIpsRecord.sof && this.localIpsRecord.sof.reduivy__Enrollment_Close_Date_Calculated__c) {
            targetDate = new Date(this.localIpsRecord.sof.reduivy__Enrollment_Close_Date_Calculated__c);
        }

        this.consoleLog('sofEnrollmentClosedDate ' + targetDate?.toISOString());
        return targetDate;
    }

    /**
     * @description Return study offering census date
     */
    get sofCensusDate() {
        let targetDate;
        if (this.localIpsRecord.sof && this.localIpsRecord.sof.reduivy__Census_Date_Calculated__c) {
            targetDate = moment.tz(this.localIpsRecord.sof.reduivy__Census_Date_Calculated__c + 'T23:59:59.999', TIME_ZONE).toDate();
        }

        this.consoleLog('sofCensusDate ' + targetDate?.toISOString());
        return targetDate;
    }

    /**
     * @description Return study offering pre-enrollment open date formatted date
     */
    get sofPreEnrollmentOpenDateStr() {
        if (this.sofPreEnrollmentOpenedDate) {
            return formatDateTime(this.sofPreEnrollmentOpenedDate, LOCALE, TIME_ZONE);
        }

        return null;
    }

    /**
     * @description Return study offering enrollment open date formatted date
     */
    get sofEnrollmentOpenDateStr() {
        if (this.sofEnrollmentOpenedDate) {
            return formatDateTime(this.sofEnrollmentOpenedDate, LOCALE, TIME_ZONE);
        }

        return null;
    }

    /**
     * @description Return study offering enrollment close date formatted date
     */
    get sofEnrollmentCloseDateStr() {
        if (this.sofEnrollmentClosedDate) {
            return formatDateTime(this.sofEnrollmentClosedDate, LOCALE, TIME_ZONE);
        }

        return null;
    }

    /**
     * @description Return study offering enable self enrollment
     */
    get sofSelfEnrollmentEnabled() {
        //ISS-002119 make the buttons visible to admin
        if (this.localIpsRecord?.sof?.reduivy__Enable_Self_Enrollment__c || this.userMode === commonConstants.USER_MODE_ADMIN) {
            return true;
        }

        return false;
    }

    /**
     * @description Return available places
     */
    get availablePlaces() {
        if(this.localIpsRecord.sof && this.localIpsRecord.sof.reduivy__Available_Places__c) {
            return this.localIpsRecord.sof.reduivy__Available_Places__c;
        }

        return 0;
    }

    /**
     * @description Return number of waitlisted student
     */
    get waitlistPlaces() {
        if(this.localIpsRecord.sof && this.localIpsRecord.sof.reduivy__Waitlist_Places__c) {
            return this.localIpsRecord.sof.reduivy__Waitlist_Places__c;
        }

        return 0;
    }

    /**
     * @description Return remaining places
     */
    get remainingPlaces() {
        let remaining = this.availablePlaces - this.waitlistPlaces;
        
        return (remaining > 0 ? remaining : 0);
    }

    /**
     * @description Return true if the study offering still has sufficient places
     */
    get hasRemainingPlaces() {
        if (this.localIpsRecord.sof) {
            if (this.localIpsRecord.sof.reduivy__Unlimited_Places__c || this.remainingPlaces > 0) {
                return true;
            }
        }

        return false;
    }

    /**
     * @description Return true if it has past the census date
     */
    get isPastCensusDate() {

        if (this.ipsCensusDate) {
            if (this.ipsCensusDate < this.nowTime) {
                return true;
            }

        } else if (this.sofCensusDate) {
            if (this.sofCensusDate < this.nowTime) {
                return true;
            }
        }

        return false;
    }

    /**
     * @description Return true if the individual pathway status is Completed
     */
    get isTermCompleted() {
        if (this.ipwRecord && this.ipwRecord.reduivy__Status__c === ipePathwayConstants.IPW_STATUS_COMPLETED) {
            return true;
        }

        return false;
    }

    /**
     * @description Show join waiting list button
     */
    get showWaitlistButton() {
        if (this.ipsRequirementMet && 
            !(this.academicTermIenEnrollmentStatus && this.ienWaitlistedStatuses.includes(this.academicTermIenEnrollmentStatus)) &&
            this.remainingPlaces <= 0 && 
            this.sofStatusType === sofStatusTypes.SOF_STATUS_TYPE_ENROLLMENT_OPENED && 
            this.localIpsRecord.sof && this.localIpsRecord.sof.reduivy__Enable_Waitlist__c && 
            this.ipsEnrollable &&
            !this.isEnrolledInOtherTerm //ISS-002445 - button should not be shown if already enrolled in another term
        ) {
            return true;
        }

        return false;
    }

    /**
     * @description Show withdraw from waiting list button
     */
    get showWithdrawWaitlistButton() {
        if (this.academicTermIenEnrollmentStatus && this.ienWaitlistedStatuses.includes(this.academicTermIenEnrollmentStatus) && this.hasIndividualEnrollment) {
            return true;
        }

        return false;
    }

    /**
     * @description Show pre-enrollment button
     */
    get showPreEnrollButton() {
        if (this.ipsRequirementMet && 
            !(this.academicTermIenEnrollmentStatus && this.ienEnrollmentRequestedStatuses.includes(this.academicTermIenEnrollmentStatus)) &&
            this.sofStatusType === sofStatusTypes.SOF_STATUS_TYPE_PREENROLLMENT_OPENED &&
            this.ipsEnrollable &&
            !this.isEnrolledInOtherTerm //ISS-002445 - button should not be shown if already enrolled in another term
        ) {
            return true;
        }

        return false;
    }

    /**
     * @description Show withdraw from pre-enrollment button
     */
    get showWithdrawPreEnrollButton() {
        if (this.academicTermIenEnrollmentStatus && this.ienEnrollmentRequestedStatuses.includes(this.academicTermIenEnrollmentStatus) && this.hasIndividualEnrollment) {
            return true;
        }

        return false;
    }

    /**
     * @description Show enroll button
     */
    get showEnrollButton() {
        if (this.ipsRequirementMet && 
            this.remainingPlaces > 0 &&
            this.sofStatusType === sofStatusTypes.SOF_STATUS_TYPE_ENROLLMENT_OPENED &&
            this.ipsEnrollable &&
            !this.isEnrolledInOtherTerm //ISS-002445 - button should not be shown if already enrolled in another term
        ) {
            return true;
        }

        return false;
    }

    /**
     * @description Show unenroll request button
     */
    get showUnenrollRequestButton() {
        if ( !(this.academicTermIenEnrollmentStatus && this.ienWithdrawalRequestedStatuses.includes(this.academicTermIenEnrollmentStatus)) &&
            !(this.academicTermIenEnrollmentStatus && this.ienCompletedStatuses.includes(this.academicTermIenEnrollmentStatus)) &&
            //disallow unenroll request if status is deferred
            !(this.academicTermIenEnrollmentStatus && this.ienDeferredStatuses.includes(this.academicTermIenEnrollmentStatus)) &&
            this.isPastCensusDate && 
            !this.ipsEnrollable &&
            this.hasIndividualEnrollment //ISS-002445 - button should show only if academicTermIen found
        ) {
            return true;
        }

        return false;
    }

    /**
     * @description Show unenroll button
     */
    get showUnenrollButton() {
        if (!(this.academicTermIenEnrollmentStatus && this.ienCompletedStatuses.includes(this.academicTermIenEnrollmentStatus)) &&
            !this.isPastCensusDate && 
            !this.ipsEnrollable &&
            this.hasIndividualEnrollment //ISS-002445 - button should show only if academicTermIen found
        ) {
            return true;
        }

        return false;
    }

    /**
     * @description return whether the academic term ien is internal grade release status
     */
    get isInternalGradeReleaseStatus() {
        return this.internalGradeReleasedStatuses?.includes(this.gradeReleaseStatus);
    }

    /**
     * @description return whether the ips current ien is credit transfer
     */
    get isIpsCurrentIenCreditTransfer() {
        return this.localIpsRecord?.ipsCurrentIen ?this.localIpsRecord?.ipsCurrentIen?.reduivy__Credit_Transfer_Received__c :false;
    }

    /**
     * @description Show action buttons
     */
    get showActionButtons() {
        return this.showEnrollmentButtons && //logic is defined by ipePathwayTerm.canPerformEnrollmentActions(), optional here but for fail-safe purpose
            this.isEligibleToEnroll && //logic is defined by ipePathwayTermUnitTable.isEligibleToEnroll(), optional here but for fail-safe purpose
            !this.isTermCompleted && //the same logic is also defined in ipePathwayTerm.isTermCompleted(), optional here but for fail-safe purpose 
            this.sofSelfEnrollmentEnabled && 
            !this.isEnrolledOfferingNotMatched &&
            //ISS-002483 - grade release status is internal or final, ips = in progress => hide button
            //ISS-002483 - grade release status is internal or final, ips = completed => hide button
            //ISS-002483 - grade release status is internal or final, ips != in progress/completed => show button
            //ISS-002483 - grade release status is not released, ips = in progress => show button
            //ISS-002483 - grade release status is not released, ips = completed => hide button
            (!(this.isInternalGradeReleaseStatus || this.isFinalGradeReleaseStatus) || this.ipsEnrollable) &&
            (!(this.isIpsCurrentIenCreditTransfer && !this.hasIndividualEnrollment)) //To hide the action button if the ips current ien is credit transfer and academicTermIen not existed
        ;
    }

    /**
     * @description Return isMissedFailed flag
     */
    get isMissedFailed() {
        return this.localIpsRecord?.isMissedFailed;
    }

    /**
     * @description Missed failed units label
     */
    get missedFailedUnitWarning() {
        return MISSED_FAILED_UNIT_LABEL;
    }

    /**
     * @description Handle ips record option button click
     */
    handleOptionsOnclick(event) {
        this.dispatchEvent(new CustomEvent("optionclick", {
            detail: {
                ipsRecord: this.localIpsRecord
            }
        }));
    }

    /**
     * @desription Handle ips record cell click
     */
    handleUnitcellClick(event){
        let eventRecord = event.detail.ipsRecord;
        let eventFieldName = event.detail.fieldName;
        let eventObjectName = event.detail.objectName;

        if (eventRecord && eventFieldName && eventObjectName) {
            if (eventObjectName === 'reduivy__Study_Unit__c' && (eventFieldName === 'Name' || eventFieldName === 'reduivy__Unit_Code__c' || eventFieldName === this.sunNameTranslationField)) {
                this.launchUnitInfoModal(eventRecord);
            }
        }
    }

    /**
     * @description Launch unit info model
     */
    launchUnitInfoModal(targetIpsRecord){

        unitInfoModal.open({
            size: 'small',
            modalTitle: this.label.INFO_LABEL,
            ipsRecord: targetIpsRecord,
            studyUnitFields: this.studyUnitInfoFields,
            studyOfferingFields: this.studyOfferingInfoFields,
            studyPlanStructureUnitFields: this.studyPlanStructureUnitInfoFields,
            enableDebugMode: this.enableDebugMode
        }).then((result) => {
            if (result) {
                this.consoleLog('launchUnitInfoModal.close');
                this.consoleLog(result, true);
            }
        });
    }

    /**
     * @description Handle pre enrollment click
     */
    handlePreEnrollClick(event) {
        let confirmationMsg1 = this.label.PREENROLL_CONFIRMATION_LABEL.format([this.translatedStudyOfferingName]);
        let confirmationMsg2;
        if (this.ipsRequirementDescription) {
            confirmationMsg2 = this.label.ENROLL_ADDITIONAL_INFO_LABEL.format([this.ipsRequirementDescription]);
        }

        this.launchConfirmationModal(this.label.CONFIRMATION_LABEL, confirmationMsg1, confirmationMsg2, null, true, this.label.CONFIRM_LABEL, true, this.label.CANCEL_LABEL, this.preEnrollEventSource, this.localIpsRecord);
    }
    
    /**
     * @description The pre-enroll request event source to dispatch to the parent
     */
    get preEnrollEventSource() {
        return {
            'enrollmentAction': ipePathwayConstants.ENROLLMENT_ACTION_ENROLLREQUESTED,
            'enrollmentStatus': this.preEnrollEnrollmentStatus
        }
    }

    /**
     * @description Handle withdraw from pre enrollment click
     */
    handleWithdrawPreEnrollClick(event) {
        let confirmationMsg1 = this.label.WITHDRAW_PREENROLL_CONFIRMATION_LABEL.format([this.translatedStudyOfferingName]);
        this.launchConfirmationModal(this.label.CONFIRMATION_LABEL, confirmationMsg1, null, null, true, this.label.CONFIRM_LABEL, true, this.label.CANCEL_LABEL, this.withdrawPreEnrollEventSource, this.localIpsRecord);
    }

    /**
     * @description The withdraw pre-enroll event source to dispatch to the parent
     */
    get withdrawPreEnrollEventSource() {
        return {
            'enrollmentAction': ipePathwayConstants.ENROLLMENT_ACTION_WITHDRAWENROLLREQUESTED,
            'enrollmentStatus': this.withdrawPreEnrollEnrollmentStatus
        }
    }

    /**
     * @description Handle enroll click
     */
    handleEnrollClick(event) {
        let confirmationMsg1 = this.label.ENROLL_CONFIRMATION_LABEL.format([this.translatedStudyOfferingName]);
        let confirmationMsg2;
        if (this.ipsRequirementDescription) {
            confirmationMsg2 = this.label.ENROLL_ADDITIONAL_INFO_LABEL.format([this.ipsRequirementDescription]);
        }

        this.launchConfirmationModal(this.label.CONFIRMATION_LABEL, confirmationMsg1, confirmationMsg2, null, true, this.label.CONFIRM_LABEL, true, this.label.CANCEL_LABEL, this.enrollEventSource, this.localIpsRecord);
    }

    /**
     * @description The enroll request event source to dispatch to the parent
     */
    get enrollEventSource() {
        return {
            'enrollmentAction': ipePathwayConstants.ENROLLMENT_ACTION_ENROLL,
            'enrollmentStatus': this.enrollEnrollmentStatus
        }
    }

    /**
     * @description Handle unenroll click
     */
    handleUnenrollClick(event) {
        let confirmationMsg1 = this.label.UNENROLL_CONFIRMATION_LABEL.format([this.translatedStudyOfferingName]);
        this.launchConfirmationModal(this.label.CONFIRMATION_LABEL, confirmationMsg1, null, null, true, this.label.CONFIRM_LABEL, true, this.label.CANCEL_LABEL, this.unenrollEventSource, this.localIpsRecord);
    }

    /**
     * @description The unenroll request event source to dispatch to the parent
     */
    get unenrollEventSource() {
        return {
            'enrollmentAction': ipePathwayConstants.ENROLLMENT_ACTION_UNENROLL,
            'enrollmentStatus': this.unenrollEnrollmentStatus
        }
    }

    /**
     * @description Handle request to unenroll click e.g., after census date
     */
    handleUnenrollRequestClick(event) {
        let confirmationMsg1 = this.label.REQUEST_UNENROLL_CONFIRMATION_LABEL.format([this.translatedStudyOfferingName]);
        this.launchConfirmationModal(this.label.CONFIRMATION_LABEL, confirmationMsg1, null, null, true, this.label.CONFIRM_LABEL, true, this.label.CANCEL_LABEL, this.unenrollRequestEventSource, this.localIpsRecord);
    }

    /**
     * @description The unenroll request event source to dispatch to the parent
     */
    get unenrollRequestEventSource() {
        return {
            'enrollmentAction': ipePathwayConstants.ENROLLMENT_ACTION_UNENROLLREQUESTED,
            'enrollmentStatus': this.unenrollRequestEnrollmentStatus
        }
    }

    /**
     * @description Handle Handle join waitlist click
     */
    handleJoinWaitListClick(event) {
        let confirmationMsg1 = this.label.JOIN_WAITLIST_CONFIRMATION_LABEL.format([this.translatedStudyOfferingName]);
        this.launchConfirmationModal(this.label.CONFIRMATION_LABEL, confirmationMsg1, null, null, true, this.label.CONFIRM_LABEL, true, this.label.CANCEL_LABEL, this.waitListEnrollmentEventSource, this.localIpsRecord);
    }

    /**
     * @description The waitlist enrollment event source to dispatch to the parent
     */
    get waitListEnrollmentEventSource() {
        return {
            'enrollmentAction': ipePathwayConstants.ENROLLMENT_ACTION_JOINWAITLIST,
            'enrollmentStatus': this.waitlistEnrollmentStatus
        }
    }

    /**
     * @description Handle withdraw from waitlist click
     */
    handleWithdrawWaitListClick(event) {
        let confirmationMsg1 = this.label.WITHDRAW_WAITLIST_CONFIRMATION_LABEL.format([this.translatedStudyOfferingName]);
        this.launchConfirmationModal(this.label.CONFIRMATION_LABEL, confirmationMsg1, null, null, true, this.label.CONFIRM_LABEL, true, this.label.CANCEL_LABEL, this.withdrawWaitListEventSource, this.localIpsRecord);
    }

    /**
     * @description The withdraw waitlist event source to dispatch to the parent
     */
    get withdrawWaitListEventSource() {
        return {
            'enrollmentAction': ipePathwayConstants.ENROLLMENT_ACTION_WITHDRAWWAITLIST,
            'enrollmentStatus': this.withdrawWaitlistEnrollmentStatus
        }
    }

    /**
     * @description Launch the confirmation modal
     * @param title 
     * @param text1 
     * @param text2 
     * @param text3 
     * @param showSubmit 
     * @param submitLabel 
     * @param showCancel 
     * @param cancelLabel 
     * @param lEventSource 
     * @param lEventData 
     */
    launchConfirmationModal(title, text1, text2, text3, showSubmit, submitLabel, showCancel, cancelLabel, lEventSource, lEventData) {

        confirmationModal.open({
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

                const {operation, eventSource, eventData} = result;

                if (operation === 'submit') {
                    const {enrollmentAction, enrollmentStatus} = eventSource;
                    this.fireUpsertEnrollmentEvent(enrollmentAction, enrollmentStatus);
                }
            }
        });
    }

    fireUpsertEnrollmentEvent(enrollmentAction, enrollmentStatus) {
        this.dispatchEvent(new CustomEvent("enrollmentaction", {
            detail: {
                ipsRecord: this.localIpsRecord,
                enrollmentAction: enrollmentAction,
                enrollmentStatus: enrollmentStatus
            }
        }));
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
        logInfo('ipePathwayTermUnit', anything, this.enableDebugMode, isJson);
    }
	
}