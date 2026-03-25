/**
 * @Author 		WDCi (Lean)
 * @Date 		Sept 2023
 * @group 		Util
 * @Description Custom label loader
 * @changehistory
 */
import { LightningElement } from 'lwc';

import ADD_JOB_LABEL from '@salesforce/label/c.Add_Job';
import ALL_LABEL from '@salesforce/label/c.All';
import ACTION_LABEL from '@salesforce/label/c.Action';
import APPLY_LABEL from '@salesforce/label/c.Apply';
import ADD_NOTES_LABEL from '@salesforce/label/c.Add_Notes';
import APPROVE_LABEL from '@salesforce/label/c.Approve';
import CANCEL_LABEL from '@salesforce/label/c.Cancel';
import CLEAR_LABEL from '@salesforce/label/c.Clear';
import CLONE_LABEL from '@salesforce/label/c.Clone';
import CLOSE_LABEL from '@salesforce/label/c.Close';
import CONFIRM_LABEL from '@salesforce/label/c.Confirm';
import CONFIRMATION_LABEL from '@salesforce/label/c.Confirmation';
import DELETE_LABEL from '@salesforce/label/c.Delete';
import DELETE_RECORD_LABEL from '@salesforce/label/c.Delete_Record';
import DELETE_RECORD_CONFIRMATION_LABEL from '@salesforce/label/c.Delete_Record_Confirmation';
import DELETE_RECORD_WITH_CHILD_CONFIRMATION_LABEL from '@salesforce/label/c.Delete_Record_With_Child_Confirmation';
import DONE_LABEL from '@salesforce/label/c.Done';
import EDIT_LABEL from '@salesforce/label/c.Edit';
import EDIT_RECORD_LABEL from '@salesforce/label/c.Edit_Record';
import ERROR_LABEL from '@salesforce/label/c.Error';
import FILTER_LABEL from '@salesforce/label/c.Filter';
import GROUPBY_LABEL from '@salesforce/label/c.Group_By';
import GROUPBY_FIELD_1_LABEL from '@salesforce/label/c.Group_By_Field_1';
import GROUPBY_FIELD_2_LABEL from '@salesforce/label/c.Group_By_Field_2';
import GROUPBY_FIELD_3_LABEL from '@salesforce/label/c.Group_By_Field_3';
import HELP_LABEL from '@salesforce/label/c.Help';
import INDICATOR_LABEL from '@salesforce/label/c.Indicator';
import INFO_LABEL from '@salesforce/label/c.Info';
import INSERT_LABEL from '@salesforce/label/c.Insert';
import LOADING_LABEL from '@salesforce/label/c.Loading';
import LOCKED_LABEL from '@salesforce/label/c.Locked';
import MISSING_REQUIRED_FIELDS_LABEL from '@salesforce/label/c.Missing_Required_Fields';
import NEW_RECORD_LABEL from '@salesforce/label/c.New_Record';
import NEW_LABEL from '@salesforce/label/c.New';
import NEXT_LABEL from '@salesforce/label/c.Next';
import NO_LABEL from '@salesforce/label/c.No';
import NUMBER_OF_SESSION_LABEL from '@salesforce/label/c.Number_Of_Session';
import NOT_SAVED_LABEL from '@salesforce/label/c.Not_Saved';
import PICKLIST_OPTION_ALL_LABEL from '@salesforce/label/c.Picklist_Option_All';
import PICKLIST_OPTION_NONE_LABEL from '@salesforce/label/c.Picklist_Option_None';
import PREVIOUS_LABEL from '@salesforce/label/c.Previous';
import PROCESSING_LABEL from '@salesforce/label/c.Processing';
import QUICK_SEARCH_LABEL from '@salesforce/label/c.Quick_Search';
import RECORD_CREATED_LABEL from '@salesforce/label/c.The_Record_Was_Created';
import RECORD_DELETED_LABEL from '@salesforce/label/c.The_Record_Was_Deleted';
import RECORD_SAVED_LABEL from '@salesforce/label/c.The_Record_Was_Saved';
import REFRESH_LABEL from '@salesforce/label/c.Refresh';
import REJECT_LABEL from '@salesforce/label/c.Reject';
import REMOVE_LABEL from '@salesforce/label/c.Remove';
import REQUIRED_LABEL from '@salesforce/label/c.Required';
import SAVE_LABEL from '@salesforce/label/c.Save';
import SEARCH_LABEL from '@salesforce/label/c.Search';
import SEARCHPLACEHOLDER_LABEL from '@salesforce/label/c.Search_Placeholder';
import STUDENT_LABEL from '@salesforce/label/c.Student';
import SEND_LABEL from '@salesforce/label/c.Send';
import SUBMIT_LABEL from '@salesforce/label/c.Submit';
import SUCCESS_LABEL from '@salesforce/label/c.Success';
import UNDO_LABEL from '@salesforce/label/c.Undo';
import UNKNOWN_EXCEPTIONS_LABEL from '@salesforce/label/c.Unknown_Error';
import UNKNOWN_LABEL from '@salesforce/label/c.Unknown';
import UPDATE_LABEL from '@salesforce/label/c.Update';
import UPSERT_LABEL from '@salesforce/label/c.Upsert';
import VIEW_LABEL from '@salesforce/label/c.View';
import VIEW_ALL_LABEL from '@salesforce/label/c.View_All';
import WARNING_LABEL from '@salesforce/label/c.Warning';
import YES_LABEL from '@salesforce/label/c.Yes';
import SELECT_LABEL from '@salesforce/label/c.Select'
import UNSELECT_LABEL from '@salesforce/label/c.Unselect'
import UNLOCKED_LABEL from '@salesforce/label/c.Unlocked'

import CONTINUING_ED_FEATURE_LABEL from '@salesforce/label/c.Continuing_Education_Feature';
import FULLSUITE_FEATURE_LABEL from '@salesforce/label/c.Full_Suite_Feature';

import CONTINUING_ED_LICENSE_REQUIRED_LABEL from '@salesforce/label/c.Continuing_Education_Feature_License_Required';
import FULLSUITE_LICENSE_REQUIRED_LABEL from '@salesforce/label/c.Full_Suite_Feature_License_Required';

import ACADEMICTERM_LABEL from '@salesforce/label/c.Academic_Term';
import CAMPUS_LABEL from '@salesforce/label/c.Campus';
import CREDITS_LABEL from '@salesforce/label/c.Credits';
import EDUCATIONAL_INSTITUTION_LABEL from '@salesforce/label/c.Educational_Institution';
import PATHWAY_LABEL from '@salesforce/label/c.Pathway';
import PATHWAYS_LABEL from '@salesforce/label/c.Pathways';
import FILE_LABEL from '@salesforce/label/c.File';

import ERROR_CONTACT_ADMIN_LABEL from '@salesforce/label/c.Error_Contact_Admin';
import LONG_PROCESSING_WARNING_LABEL from '@salesforce/label/c.Long_Processing_Warning';
import SERVER_TOO_BUSY_LABEL from '@salesforce/label/c.Server_Too_Busy';
import UNSUPPORTED_FIELD_TYPE_LABEL from '@salesforce/label/c.Unsupported_Field_Type';
import UNSUPPORTED_ACTION_LABEL from '@salesforce/label/c.Unsupported_Action';
import YOUR_CHANGES_ARE_SAVED_LABEL from '@salesforce/label/c.Your_Changes_Are_Saved';

import UNSAVED_CHANGES_WARNING_TITLE_LABEL from '@salesforce/label/c.Unsaved_Changes_Warning_Title';
import UNSAVED_CHANGES_WARNING_TEXT_LABEL from '@salesforce/label/c.Unsaved_Changes_Warning_Text';
import UNSAVED_CHANGES_STAY_BUTTON_LABEL from '@salesforce/label/c.Stay_On_This_Page';
import UNSAVED_CHANGES_LEAVE_BUTTON_LABEL from '@salesforce/label/c.Discard_Changes_And_Leave_This_Page';

const customLabels = {
    ACTION_LABEL,
    ADD_JOB_LABEL,
    ADD_NOTES_LABEL,
    APPROVE_LABEL,
    CANCEL_LABEL,
    CLEAR_LABEL,
    CLONE_LABEL,
    CLOSE_LABEL,
    CONFIRM_LABEL,
    CONFIRMATION_LABEL,
    DELETE_LABEL,
    DELETE_RECORD_LABEL,
    DELETE_RECORD_CONFIRMATION_LABEL,
    DELETE_RECORD_WITH_CHILD_CONFIRMATION_LABEL,
    DONE_LABEL,
    EDIT_LABEL,
    EDIT_RECORD_LABEL,
    ERROR_LABEL,
    FILTER_LABEL,
    GROUPBY_LABEL,
    GROUPBY_FIELD_1_LABEL,
    GROUPBY_FIELD_2_LABEL,
    GROUPBY_FIELD_3_LABEL,
    HELP_LABEL,
    INDICATOR_LABEL,
    INFO_LABEL,
    INSERT_LABEL,
    LOADING_LABEL,
    LOCKED_LABEL,
    NEW_LABEL,
    MISSING_REQUIRED_FIELDS_LABEL,
    NEW_RECORD_LABEL,
    NEXT_LABEL,
    NO_LABEL,
    NUMBER_OF_SESSION_LABEL,
    NOT_SAVED_LABEL,
    PICKLIST_OPTION_ALL_LABEL,
    PICKLIST_OPTION_NONE_LABEL,
    PREVIOUS_LABEL,
    PROCESSING_LABEL,
    QUICK_SEARCH_LABEL,
    REFRESH_LABEL,
    REJECT_LABEL,
    REQUIRED_LABEL,
    SAVE_LABEL,
    SEARCH_LABEL,
    SEND_LABEL,
    SEARCHPLACEHOLDER_LABEL,
    STUDENT_LABEL,
    SUBMIT_LABEL,
    SUCCESS_LABEL,
    UNLOCKED_LABEL,
    UNDO_LABEL,
    UNKNOWN_EXCEPTIONS_LABEL,
    UNKNOWN_LABEL,
    UPDATE_LABEL,
    UPSERT_LABEL,
    VIEW_LABEL,
    VIEW_ALL_LABEL,
    YES_LABEL,
    CONTINUING_ED_FEATURE_LABEL,
    FULLSUITE_FEATURE_LABEL,
    CONTINUING_ED_LICENSE_REQUIRED_LABEL,
    FULLSUITE_LICENSE_REQUIRED_LABEL,
    ACADEMICTERM_LABEL,
    CAMPUS_LABEL,
    CREDITS_LABEL,
    EDUCATIONAL_INSTITUTION_LABEL,
    PATHWAY_LABEL,
    PATHWAYS_LABEL,
    FILE_LABEL,
    RECORD_CREATED_LABEL,
    RECORD_DELETED_LABEL,
    RECORD_SAVED_LABEL,
    ERROR_CONTACT_ADMIN_LABEL,
    SERVER_TOO_BUSY_LABEL,
    LONG_PROCESSING_WARNING_LABEL,
    UNSUPPORTED_FIELD_TYPE_LABEL,
    UNSUPPORTED_ACTION_LABEL,
    YOUR_CHANGES_ARE_SAVED_LABEL,
    UNSAVED_CHANGES_WARNING_TITLE_LABEL,
    UNSAVED_CHANGES_WARNING_TEXT_LABEL,
    UNSAVED_CHANGES_STAY_BUTTON_LABEL,
    UNSAVED_CHANGES_LEAVE_BUTTON_LABEL,
    APPLY_LABEL,
    SELECT_LABEL,
    UNSELECT_LABEL,
    WARNING_LABEL,
    ALL_LABEL,
    REMOVE_LABEL,
};

export {customLabels};

export default class LabelLoader extends LightningElement { }