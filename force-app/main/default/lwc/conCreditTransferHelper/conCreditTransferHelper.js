/**
 * @Author 		WDCi (VTan)
 * @Date 		Jan 2024
 * @group 		Credit Transfer Wizard
 * @Description Credit Transfer Wizard const
 * @changehistory
 * ISS-001659 17-01-2024 VTan - Inital Built.
 */
import { LightningElement } from 'lwc';

const EDIT_ACTION = 'Edit';
const APPROVE_ACTION = 'Approve';
const REJECT_ACTION = 'Reject';
const VIEW_ACTION = 'View';
const SUBMIT_ACTION = 'Submit';
const CTAMODAL_NEW = 'New';
const CTAMODAL_EDIT = 'Edit';
const CTAMODAL_APPROVAL = 'Approval';
const AUE_TYPE_MANUAL = 'Manual Assignment';

const conCreditTransferConstants = {
    EDIT_ACTION,
    APPROVE_ACTION,
    REJECT_ACTION,
    VIEW_ACTION,
    SUBMIT_ACTION,
    CTAMODAL_NEW,
    CTAMODAL_EDIT,
    CTAMODAL_APPROVAL,
    AUE_TYPE_MANUAL
}

export {conCreditTransferConstants};

export default class conCreditTransferHelper extends LightningElement {}