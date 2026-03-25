/**
 * @Author 		WDCi (VTan)
 * @Date 		March 2023
 * @group 		Program Completion Wizard
 * @Description Program Completion Wizard const
 * @changehistory
 * ISS-001753 23-10-2023 VTan - New Component
 */
import { LightningElement } from 'lwc';

const IPE_REF_FIELD_LABEL_NAME = 'Name';
const SET_PRIMARY_ROW_ACTION_LABEL = 'Set_as_Primary';
const VIEW_HISTORY_ROW_ACTION_LABEL = 'View_Individual_Enrollment_History';

const ipeAuditConstants = {
    IPE_REF_FIELD_LABEL_NAME,
    SET_PRIMARY_ROW_ACTION_LABEL,
    VIEW_HISTORY_ROW_ACTION_LABEL
}

export {ipeAuditConstants};

export default class IpeAuditHelper extends LightningElement {}