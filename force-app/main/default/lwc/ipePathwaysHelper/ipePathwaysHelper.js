/**
 * @Author 		WDCi (Lean)
 * @Date 		Oct 2023
 * @group 		Enrollment Wizard
 * @Description Enrollment wizard constants
 * @changehistory
 * ISS-001752 24-10-2023 Lean - new component
 * ISS-002050 18-09-2024 Sueanne - add statuses for session enrollment
 * ISS-002188 14-01-2025 XW - Renamed Unit Listing mode value to 'All Study Units' and 'Recommended Pathwaty'
 * ISS-002231 25-03-2025 Lean - Added deferred status
 * ISS-002486 10-06-2025 XiRouh - Added IEN_STATUS_TYPE_COMPLETED_FAIL
 */
import { LightningElement } from 'lwc';

const IPW_STATUS_COMPLETED = 'Completed';
const IPW_STATUS_CURRENT = 'Current';
const IPW_STATUS_FUTURE = 'Future';

const UNIT_LISTING_MODE_ALL = 'All Study Units';
const UNIT_LISTING_MODE_PATHWAY = 'Recommended Pathway';

const ENROLLMENT_ACTION_ENROLL = 'Enroll';
const ENROLLMENT_ACTION_ENROLLREQUESTED = 'EnrollRequested';
const ENROLLMENT_ACTION_WITHDRAWENROLLREQUESTED = 'WithdrawEnrollRequested';
const ENROLLMENT_ACTION_UNENROLL = 'Unenroll';
const ENROLLMENT_ACTION_UNENROLLREQUESTED = 'UnenrollRequested';
const ENROLLMENT_ACTION_JOINWAITLIST = 'JoinWaitList';
const ENROLLMENT_ACTION_WITHDRAWWAITLIST = 'WithdrawWaitList';

const IPS_STATUS_TYPE_NOTSTARTED = 'Not_Started';
const IPS_STATUS_TYPE_INPROGRESS = 'In_Progress';
const IPS_STATUS_TYPE_COMPLETED = 'Completed';
const IPS_STATUS_TYPE_FAILED = 'Failed';
const IPS_STATUS_TYPE_WITHDRAWN = 'Withdrawn';
const IPS_STATUS_TYPE_DROPPED = 'Dropped';
const IPS_STATUS_TYPE_NONENROLLABLE = 'Non_Enrollable';
const IPS_STATUS_TYPE_DEFERRED = 'Deferred';

const IEN_STATUS_TYPE_OPEN = 'Open';
const IEN_STATUS_TYPE_ENROLLMENT_REQUESTED = 'Enrollment_Requested';
const IEN_STATUS_TYPE_INPROGRESS = 'In_Progress';
const IEN_STATUS_TYPE_COMPLETED = 'Completed';
const IEN_STATUS_TYPE_COMPLETED_FAIL = 'Completed_Fail';
const IEN_STATUS_TYPE_WAITLISTED = 'Waitlisted';
const IEN_STATUS_TYPE_DROPPED = 'Dropped';
const IEN_STATUS_TYPE_WITHDRAWN_REQUESTED = 'Withdrawal_Requested';
const IEN_STATUS_TYPE_WITHDRAWN = 'Withdrawn';
const IEN_STATUS_TYPE_WITHDRAWN_FAIL = 'Withdrawn_Fail';
const IEN_STATUS_TYPE_NONENROLLABLE = 'Non_Enrollable';
const IEN_STATUS_TYPE_DEFERRED = 'Deferred';

const SOF_STATUS_TYPE_NOTSTARTED = 'Not_Started';
const SOF_STATUS_TYPE_PREENROLLMENT_OPENED = 'Pre_enrollment_Opened';
const SOF_STATUS_TYPE_ENROLLMENT_OPENED = 'Enrollment_Opened';
const SOF_STATUS_TYPE_ENROLLMENT_CLOSED = 'Enrollment_Closed';
const SOF_STATUS_TYPE_RUNNING_ENROLLMENT_OPENED = 'Running_Enrollment_Opened';
const SOF_STATUS_TYPE_RUNNING = 'Running';

const SSE_STATUS_TYPE_NOTSTARTED = 'Not_Started';
const SSE_STATUS_TYPE_PREENROLLMENT_OPENED = 'Pre_enrollment_Opened';
const SSE_STATUS_TYPE_ENROLLMENT_OPENED = 'Enrollment_Opened';
const SSE_STATUS_TYPE_ENROLLMENT_CLOSED = 'Enrollment_Closed';
const SSE_STATUS_TYPE_RUNNING_ENROLLMENT_OPENED = 'Running_Enrollment_Opened';
const SSE_STATUS_TYPE_RUNNING = 'Running';

const ISN_STATUS_TYPE_COMPLETED = 'Completed';
const ISN_STATUS_TYPE_DROPPED = 'Dropped';
const ISN_STATUS_TYPE_OPEN = 'Open';
const ISN_STATUS_TYPE_ENROLLMENT_REQUESTED = 'Enrollment_Requested';
const ISN_STATUS_TYPE_INPROGRESS = 'In_Progress';
const ISN_STATUS_TYPE_WAITLISTED = 'Waitlisted';
const ISN_STATUS_TYPE_WITHDRAWN = 'Withdrawn';

/**
 * @description Pathway constants
 */
const ipePathwayConstants = {
    IPW_STATUS_COMPLETED,
    IPW_STATUS_CURRENT,
    IPW_STATUS_FUTURE,
    UNIT_LISTING_MODE_ALL,
    UNIT_LISTING_MODE_PATHWAY,
    ENROLLMENT_ACTION_ENROLL,
    ENROLLMENT_ACTION_ENROLLREQUESTED,
    ENROLLMENT_ACTION_WITHDRAWENROLLREQUESTED,
    ENROLLMENT_ACTION_UNENROLL,
    ENROLLMENT_ACTION_UNENROLLREQUESTED,
    ENROLLMENT_ACTION_JOINWAITLIST,
    ENROLLMENT_ACTION_WITHDRAWWAITLIST
}

/**
 * @description Individual plan structure unit status types
 */
const ipsUnitStatusTypes = {
    IPS_STATUS_TYPE_NOTSTARTED,
    IPS_STATUS_TYPE_INPROGRESS,
    IPS_STATUS_TYPE_COMPLETED,
    IPS_STATUS_TYPE_FAILED,
    IPS_STATUS_TYPE_WITHDRAWN,
    IPS_STATUS_TYPE_DROPPED,
    IPS_STATUS_TYPE_NONENROLLABLE,
    IPS_STATUS_TYPE_DEFERRED
}

/**
 * @description Individual enrollment enrollment status types
 */
const ienEnrollmentStatusTypes = {
    IEN_STATUS_TYPE_OPEN,
    IEN_STATUS_TYPE_COMPLETED,
    IEN_STATUS_TYPE_COMPLETED_FAIL,
    IEN_STATUS_TYPE_DROPPED,
    IEN_STATUS_TYPE_ENROLLMENT_REQUESTED,
    IEN_STATUS_TYPE_INPROGRESS,
    IEN_STATUS_TYPE_WAITLISTED,
    IEN_STATUS_TYPE_WITHDRAWN,
    IEN_STATUS_TYPE_WITHDRAWN_FAIL,
    IEN_STATUS_TYPE_WITHDRAWN_REQUESTED,
    IEN_STATUS_TYPE_NONENROLLABLE,
    IEN_STATUS_TYPE_DEFERRED
}

/**
 * @description Study offering status types
 */
const sofStatusTypes = {
    SOF_STATUS_TYPE_NOTSTARTED,
    SOF_STATUS_TYPE_PREENROLLMENT_OPENED,
    SOF_STATUS_TYPE_ENROLLMENT_OPENED,
    SOF_STATUS_TYPE_ENROLLMENT_CLOSED,
    SOF_STATUS_TYPE_RUNNING_ENROLLMENT_OPENED,
    SOF_STATUS_TYPE_RUNNING
}

/**
 * @description Study session status types
 */
const sseStatusTypes = {
    SSE_STATUS_TYPE_NOTSTARTED,
    SSE_STATUS_TYPE_PREENROLLMENT_OPENED,
    SSE_STATUS_TYPE_ENROLLMENT_OPENED,
    SSE_STATUS_TYPE_ENROLLMENT_CLOSED,
    SSE_STATUS_TYPE_RUNNING_ENROLLMENT_OPENED,
    SSE_STATUS_TYPE_RUNNING
}

/**
 * @description Individual session enrollment enrollment status types
 */
const isnEnrollmentStatusTypes = {
    ISN_STATUS_TYPE_COMPLETED,
    ISN_STATUS_TYPE_DROPPED,
    ISN_STATUS_TYPE_OPEN,
    ISN_STATUS_TYPE_ENROLLMENT_REQUESTED,
    ISN_STATUS_TYPE_INPROGRESS,
    ISN_STATUS_TYPE_WAITLISTED,
    ISN_STATUS_TYPE_WITHDRAWN
}

export { ipePathwayConstants, ipsUnitStatusTypes, ienEnrollmentStatusTypes, sofStatusTypes, sseStatusTypes, isnEnrollmentStatusTypes };

export default class IpePathwaysHelper extends LightningElement {}