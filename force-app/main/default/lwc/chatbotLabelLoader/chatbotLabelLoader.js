/**
 * @Author 		WDCi (XW)
 * @Date 		May 2024
 * @group 		
 * @Description 
 * @changehistory
 * ISS-001916 20-05-2024 name - Chatbot Label Loader
 */
import { LightningElement } from 'lwc';
import MENU_LABEL from '@salesforce/label/c.Menu_Question';
import ENTER_PROGRAM_COMPLETION_LABEL from '@salesforce/label/c.Enter_Program_Completion_Visualizer';
import ENTER_PATHWAY_LABEL from '@salesforce/label/c.Enter_Pathway_Visualizer';
import CHANGING_PROGRAM_LABEL from '@salesforce/label/c.Changing_Study_Program_Confirmation';
import IPE_LABEL from '@salesforce/label/c.IPE';
import PROGRAM_LABEL from '@salesforce/label/c.Study_Program';
import PLAN_LABEL from '@salesforce/label/c.Study_Plan';
import SELECT_YOUR_LABEL from '@salesforce/label/c.Select_your';
import SELECT_YOUR_TARGET_LABEL from '@salesforce/label/c.Select_your_target';
import YES_LABEL from '@salesforce/label/c.Yes';
import NO_LABEL from '@salesforce/label/c.No';
import RECORD_PAGE_CHANGED_GO_BACK_LABEL from '@salesforce/label/c.Record_Page_Changed_Back_to_Record';
import RETURN_TO_MENU_LABEL from '@salesforce/label/c.Return_To_Menu';
import NO_IPE_FOUND_LABEL from '@salesforce/label/c.No_Individual_Program_Enrollment_Found'
import PROCEED_TO_VALID_RECORD_PAGE_LABEL from '@salesforce/label/c.Proceed_to_valid_record_page'


import PATHWAY_QUESTION_LABEL from '@salesforce/label/c.Viewing_Pathway_Visualizer_for';
import VIEW_PATHWAY_CONFIRMATION_LABEL from '@salesforce/label/c.View_Pathway_Confirmation';
import CONFIRM_LABEL from '@salesforce/label/c.Confirm';
import NO_STUDY_PLAN_FOUND_LABEL from '@salesforce/label/c.No_Study_Plan_Found';
import NO_DEFAULT_STUDY_PLAN_FOUND_LABEL from '@salesforce/label/c.No_Default_Study_Plan_Found';
import NO_STUDY_PATHWAY_FOUND_LABEL from '@salesforce/label/c.No_Study_Pathway_Found';
import STUDY_PLAN_SELECTED_LABEL from '@salesforce/label/c.Study_Plan_Selected';
import PATHWAY_VISUALIZER_LABEL from '@salesforce/label/c.Pathway_Visualizer';



const chatbotCustomLabel = {
    MENU_LABEL,
    ENTER_PROGRAM_COMPLETION_LABEL,
    ENTER_PATHWAY_LABEL,
    CHANGING_PROGRAM_LABEL,
    SELECT_YOUR_LABEL,
    SELECT_YOUR_TARGET_LABEL,
    IPE_LABEL,
    PROGRAM_LABEL,
    PLAN_LABEL,
    YES_LABEL,
    NO_LABEL,

    PATHWAY_QUESTION_LABEL,
    VIEW_PATHWAY_CONFIRMATION_LABEL,
    CONFIRM_LABEL,
    NO_IPE_FOUND_LABEL,
    PROCEED_TO_VALID_RECORD_PAGE_LABEL,

    RECORD_PAGE_CHANGED_GO_BACK_LABEL,
    RETURN_TO_MENU_LABEL,
    NO_STUDY_PLAN_FOUND_LABEL,
    NO_DEFAULT_STUDY_PLAN_FOUND_LABEL,
    NO_STUDY_PATHWAY_FOUND_LABEL,
    STUDY_PLAN_SELECTED_LABEL,
    PATHWAY_VISUALIZER_LABEL,

}

export { chatbotCustomLabel }
export default class ChatbotLabelLoader extends LightningElement { }