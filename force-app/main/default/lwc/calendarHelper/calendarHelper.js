/**
 * @author      WDCi (Lean)
 * @date        Apr 2024
 * @group       Session Management
 * @description Study session scheduler
 * @changehistory
 * ISS-001920 23-04-2024 Lean - new class
 */
import { LightningElement } from 'lwc';

import TWO_WEEKS_BUTTON_LABEL from '@salesforce/label/c.Calendar_2_Weeks_button';
import DAY_BUTTON_LABEL from '@salesforce/label/c.Calendar_Day_button';
import LIST_WEEK_BUTTON_LABEL from '@salesforce/label/c.Calendar_List_Week_Button';
import MONTH_BUTTON_LABEL from '@salesforce/label/c.Calendar_Month_button';
import VIEW_BUTTON_LABEL from '@salesforce/label/c.Calendar_View';
import WEEK_BUTTON_LABEL from '@salesforce/label/c.Calendar_Week_button';
import JUMP_TO_BUTTON_LABEL from '@salesforce/label/c.Calendar_Jump_To_Button';
import TODAY_BUTTON_LABEL from '@salesforce/label/c.Calendar_Today_button';
import MY_CALENDAR_LABEL from '@salesforce/label/c.My_Calendar';

// import _LABEL from '@salesforce/label/c.';
// import _LABEL from '@salesforce/label/c.';

const calendarLabels = {
    TWO_WEEKS_BUTTON_LABEL,
    DAY_BUTTON_LABEL,
    LIST_WEEK_BUTTON_LABEL,
    MONTH_BUTTON_LABEL,
    VIEW_BUTTON_LABEL,
    WEEK_BUTTON_LABEL,
    JUMP_TO_BUTTON_LABEL,
    TODAY_BUTTON_LABEL,
    MY_CALENDAR_LABEL
}

export { calendarLabels };

export default class CalendarHelper extends LightningElement { }