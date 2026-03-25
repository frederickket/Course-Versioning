/**
 * @author      WDCi (Lean)
 * @date        Jul 2025
 * @group       Job Queue Framework
 * @description The job queue group helper
 * @changehistory
 * ISS-002547 09-07-2025 Lean - new class
 */
global inherited sharing class JQG_Helper implements SObject_Helper {
    
    /**
     * @description Status - Draft
     */
    global static final String STATUS_DRAFT = 'Draft';

    /**
     * @description Status - Pending
     */
    global static final String STATUS_PENDING = 'Pending';

    /**
     * @description Status - Processing
     */
    global static final String STATUS_PROCESSING = 'Processing';

    /**
     * @description Status - Completed
     */
    global static final String STATUS_COMPLETED = 'Completed';

    /**
     * @description Status - Failed
     */
    global static final String STATUS_FAILED = 'Failed';

    /**
     * @description Status - Cancelled
     */
    global static final String STATUS_CANCELLED = 'Cancelled';

    /**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel() {
        return SObjectType.reduivy__Job_Queue_Group__c.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel() {
        return SObjectType.reduivy__Job_Queue_Group__c.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName() {
        return SObjectType.reduivy__Job_Queue_Group__c.getName();
    }

    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.reduivy__Job_Queue_Group__c);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }

}