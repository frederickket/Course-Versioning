/**
 * @author      WDCi (Lean)
 * @date        Apr 2024
 * @group       Session Management
 * @description Study session scheduler
 * @changehistory
 * ISS-001920 26-04-2024 Lean - new class
 */
import { LightningElement } from 'lwc';
import { customLabels } from 'c/labelLoader';

import FACULTY_LABEL from '@salesforce/label/c.Faculty';
import FACILITY_LABEL from '@salesforce/label/c.Facility';
import WORKPAD_LABEL from '@salesforce/label/c.Workpad';
import ADD_TO_WORKPAD_LABEL from '@salesforce/label/c.Add_To_Workpad';
import REMOVE_FROM_WORKPAD_LABEL from '@salesforce/label/c.Remove_From_Workpad';
import CURRENT_INFO_LABEL from '@salesforce/label/c.Current_Info';
import NEW_INFO_LABEL from '@salesforce/label/c.New_Info';
import EVENT_CHANGE_OPTION_THISEVENT_LABEL from '@salesforce/label/c.Event_Change_Option_This_Event_Only';
import EVENT_CHANGE_OPTION_ALLTHISDAY_LABEL from '@salesforce/label/c.Event_Change_Option_All_This_Day';
import EVENT_CHANGE_OPTION_THISWEEK_LABEL from '@salesforce/label/c.Event_Change_Option_This_Week';
import EVENT_CHANGE_OPTION_THISANDNEXTWEEK_LABEL from '@salesforce/label/c.Event_Change_Option_This_and_Next_Week';
import EVENT_CHANGE_OPTION_THISANDNEXT3WEEKS_LABEL from '@salesforce/label/c.Event_Change_Option_This_and_Next_3_Weeks';
import EVENT_CHANGE_OPTION_THISANDFUTURE_LABEL from '@salesforce/label/c.Event_Change_Option_Future';
import APPLY_THIS_FOR_LABEL from '@salesforce/label/c.Apply_This_For';
import EVENT_TIME_CHANGE_CONFIRMATION_LABEL from '@salesforce/label/c.Event_Time_Change_Confirmation';
import EVENT_ALLOCATION_CONFIRMATION_LABEL from '@salesforce/label/c.Event_Allocation_Confirmation';
import EVENT_UNALLOCATION_CONFIRMATION_LABEL from '@salesforce/label/c.Event_Unallocation_Confirmation';
import UNQUALIFIED_RESOURCE_LABEL from '@salesforce/label/c.Unqualified_Resource';
import UNALLOCATE_LABEL from '@salesforce/label/c.Unallocate'
import STUDY_EVENT_INFO_LABEL from '@salesforce/label/c.Study_Event_Info'

import PREVIEW_LABEL from '@salesforce/label/c.Study_Session_Scheduler_Preview';
import ASSIGN_FACILITY_LABEL from '@salesforce/label/c.Study_Session_Scheduler_Assign_Facility';
import ASSIGN_FACULTY_LABEL from '@salesforce/label/c.Study_Session_Scheduler_Assign_Faculty';
import SEND_ANNOUNCEMENT_LABEL from '@salesforce/label/c.Study_Session_Scheduler_Send_Announcement';

import SAVE_AND_UPDATE_LABEL from '@salesforce/label/c.Save_and_Update_Schedules';
import MISSING_INFO_ERROR_LABEL from '@salesforce/label/c.Missing_Required_Fields_And_Study_Session_Times';

import SELECT_STUDY_EVENT_TO_UPDATE_LABEL from '@salesforce/label/c.Select_Study_Event_To_Update';
import UPDATE_UNALLOCATED_STUDY_EVENTS_LABEL from '@salesforce/label/c.Update_Unallocated_Study_Events';
import ADD_INTO_ALL_STUDY_EVENTS_LABEL from '@salesforce/label/c.Add_into_All_Study_Events';
import REPLACE_ALL_STUDY_EVENTS_LABEL from '@salesforce/label/c.Replace_All_Study_Events';

import PREVIEW_ALL_LABEL from '@salesforce/label/c.Preview_All';
import PREVIEW_UNALLOCATED_ONLY_LABEL from '@salesforce/label/c.Preview_Unallocated_Only';
import FROM_A_DATE_LABEL from '@salesforce/label/c.From_A_date';
import FROM_TODAY_LABEL from '@salesforce/label/c.From_Today';

import SST_EVENT_CHANGE_TITLE_LABEL from '@salesforce/label/c.Study_Session_Time_Event_Change_Title';
import SST_TIME_EDIT_DAY_LABEL from '@salesforce/label/c.SST_Time_Edit_Accordion_Day';
import SST_TIME_EDIT_TIME_LABEL from '@salesforce/label/c.SST_Time_Edit_Accordion_Time';
import SST_TIME_EDIT_TITLE_LABEL from '@salesforce/label/c.SST_Time_Edit_Accordion_Title';
import SEV_TIMELINE_TOOLTIP_LABEL from '@salesforce/label/c.SEV_Timeline_Tooltip';
import SEV_TIMELINE_PREVIEW_TOOLTIP_LABEL from '@salesforce/label/c.SEV_Timeline_Preview_Tooltip';


// import _LABEL from '@salesforce/label/c.';

const sessionSchedulerLabels = {
    FACILITY_LABEL,
    FACULTY_LABEL,
    WORKPAD_LABEL,
    ADD_TO_WORKPAD_LABEL,
    REMOVE_FROM_WORKPAD_LABEL,
    CURRENT_INFO_LABEL,
    NEW_INFO_LABEL,
    EVENT_CHANGE_OPTION_THISEVENT_LABEL,
    EVENT_CHANGE_OPTION_ALLTHISDAY_LABEL,
    EVENT_CHANGE_OPTION_THISWEEK_LABEL,
    EVENT_CHANGE_OPTION_THISANDNEXTWEEK_LABEL,
    EVENT_CHANGE_OPTION_THISANDNEXT3WEEKS_LABEL,
    EVENT_CHANGE_OPTION_THISANDFUTURE_LABEL,
    APPLY_THIS_FOR_LABEL,
    EVENT_TIME_CHANGE_CONFIRMATION_LABEL,
    EVENT_ALLOCATION_CONFIRMATION_LABEL,
    EVENT_UNALLOCATION_CONFIRMATION_LABEL,
    UNQUALIFIED_RESOURCE_LABEL,
    PREVIEW_LABEL,
    ASSIGN_FACILITY_LABEL,
    ASSIGN_FACULTY_LABEL,
    SEND_ANNOUNCEMENT_LABEL,
    SAVE_AND_UPDATE_LABEL,
    MISSING_INFO_ERROR_LABEL,
    UNALLOCATE_LABEL,
    STUDY_EVENT_INFO_LABEL,
    SELECT_STUDY_EVENT_TO_UPDATE_LABEL,
    UPDATE_UNALLOCATED_STUDY_EVENTS_LABEL,
    ADD_INTO_ALL_STUDY_EVENTS_LABEL,
    REPLACE_ALL_STUDY_EVENTS_LABEL,
    PREVIEW_ALL_LABEL,
    PREVIEW_UNALLOCATED_ONLY_LABEL,
    FROM_A_DATE_LABEL,
    FROM_TODAY_LABEL,
    SST_EVENT_CHANGE_TITLE_LABEL,
    SST_TIME_EDIT_DAY_LABEL,
    SST_TIME_EDIT_TIME_LABEL,
    SST_TIME_EDIT_TITLE_LABEL,
    SEV_TIMELINE_TOOLTIP_LABEL,
    SEV_TIMELINE_PREVIEW_TOOLTIP_LABEL,
    ...customLabels
}

const STUDENT = 'Student';
const FACULTY = 'Faculty';
const FACILITY = 'Facility';

const STUDYSESSION_TYPE_SESSION = 'Study Session';
const STUDYSESSION_TYPE_APPOINTMENT = 'Appointment';

const EVENTCHANGE_SINGLE = 'single';
const EVENTCHANGE_ALLTHISDAY = 'allthisday';
const EVENTCHANGE_THISWEEK = 'thisweek';
const EVENTCHANGE_TWOWEEKS = 'twoweeks';
const EVENTCHANGE_FOURWEEKS = 'fourweeks';
const EVENTCHANGE_FUTURE = 'future';

const EVENTACTION_ALLOCATE = 'allocate';
const EVENTACTION_UNALLOCATE = 'unallocate';
const EVENTACTION_CHANGETIME_DROP = 'changetimeviadrop';
const EVENTACTION_CHANGETIME_RESIZE = 'changetimeviaresize';

const sessionSchedulerConstants = {
    STUDYSESSION_TYPE_SESSION,
    STUDYSESSION_TYPE_APPOINTMENT,
    STUDENT,
    FACULTY,
    FACILITY,
    EVENTCHANGE_SINGLE,
    EVENTCHANGE_ALLTHISDAY,
    EVENTCHANGE_THISWEEK,
    EVENTCHANGE_TWOWEEKS,    
    EVENTCHANGE_FOURWEEKS,
    EVENTCHANGE_FUTURE,
    EVENTACTION_ALLOCATE,
    EVENTACTION_UNALLOCATE,
    EVENTACTION_CHANGETIME_DROP,
    EVENTACTION_CHANGETIME_RESIZE
}

const getSchedulingTypeLabel = (schedulingType) => {
    if (schedulingType === FACILITY) {
        return FACILITY_LABEL;
    } else if (schedulingType === FACULTY) {
        return FACULTY_LABEL;
    }

    return '';
}

export { sessionSchedulerLabels, sessionSchedulerConstants, getSchedulingTypeLabel };

export default class StudySessionSchedulerHelper extends LightningElement { }