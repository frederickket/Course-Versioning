/**
 * @author      WDCi (XW)
 * @date        June 2025
 * @group       Object Helper
 * @description Individual Requirement object helper class that contains the picklist option constants and object related methods
 * @changehistory
 * ISS-002128 05-06-2025 XW - new class
 * ISS-002665 10-11-2025 XiRouh - Added getSubmissionStatusConfig() and getSubmissionStatusTypeMap()
 */

global inherited sharing class IRQ_Helper implements SObject_Helper{

    
    /**
     * @description Review Status - Accepted
     */
    global static final String REVIEW_STATUS_ACCEPTED = 'Accepted';
    
    /**
     * @description Review Status - Conditionally_Accepted
     */
    global static final String REVIEW_STATUS_CONDITIONALLY_ACCEPTED = 'Conditionally Accepted';
    
    /**
     * @description Review Status - Not_Accepted
     */
    global static final String REVIEW_STATUS_NOT_ACCEPTED = 'Not Accepted';
    
    /**
     * @description Review Status - Not_Required
     */
    global static final String REVIEW_STATUS_NOT_REQUIRED = 'Not Required';
    
    /**
     * @description Review Status - Open
     */
    global static final String REVIEW_STATUS_OPEN = 'Open';
    
    /**
     * @description Review Status - Under_Review
     */
    global static final String REVIEW_STATUS_UNDER_REVIEW = 'Under Review';

    /**
     * @description Review Status Type in Requirement Checklist - Accepted
     */
    global static final String REVIEW_STATUS_TYPE_ACCEPTED = 'Accepted';
    
    /**
     * @description Review Status Type in Requirement Checklist - Rejected
     */
    global static final String REVIEW_STATUS_TYPE_REJECTED = 'Rejected';
    
    /**
     * @description Review Status Type in Requirement Checklist - Cancelled
     */
    global static final String REVIEW_STATUS_TYPE_CANCELLED = 'Cancelled';
    
    /**
     * @description Review Status Type in Requirement Checklist - Open
     */
    global static final String REVIEW_STATUS_TYPE_OPEN = 'Open';
    
    /**
     * @description Review Status Type in Requirement Checklist - Reviewing
     */
    global static final String REVIEW_STATUS_TYPE_REVIEWING = 'Reviewing';

    /**
     * @description Review Status Type in Requirement Checklist - Submitted
     */
    global static final String REVIEW_STATUS_TYPE_SUBMITTED = 'Submitted';

    /**
     * @description Requirement Visibility - Admin
     */
    global static final String REQUIREMENT_VISIBILITY_ADMIN = 'Admin';
    
    /**
     * @description Requirement Visibility - Faculty
     */
    global static final String REQUIREMENT_VISIBILITY_FACULTY = 'Faculty';
    
    /**
     * @description Requirement Visibility - Student
     */
    global static final String REQUIREMENT_VISIBILITY_STUDENT = 'Student';

    /**
     * @description Individual Requirement Status - Draft
     */
    global static final String STATUS_DRAFT = 'Draft';
    
    /**
     * @description Individual Requirement Status - Active
     */
    global static final String STATUS_ACTIVE = 'Active';

    /**
     * @description Individual Requirement Status - Archived
     */
    global static final String STATUS_ARCHIVED = 'Archived';

    /**
     * @description Individual Requirement Submission Status - Open
     */
    global static final String SUBMISSION_STATUS_OPEN = 'Open';

    /**
     * @description Individual Requirement Submission Status - Submitted
     */
    global static final String SUBMISSION_STATUS_SUBMITTED = 'Submitted';

    /**
     * @description Individual Requirement Submission Status - Cancelled
     */
    global static final String SUBMISSION_STATUS_CANCELLED = 'Cancelled';

    /**
     * @description Individual Requirement Submission Status - Resubmission Requested
     */
    global static final String SUBMISSION_STATUS_RESUBMISSION_REQUESTED = 'Resubmission Requested';

    /**
     * @description Individual Requirement Submission Status Type - Open
     */
    global static final String SUBMISSION_STATUS_TYPE_OPEN = 'Open';

    /**
     * @description Individual Requirement Submission Status Type - Submitted
     */
    global static final String SUBMISSION_STATUS_TYPE_SUBMITTED = 'Submitted';

    /**
     * @description Individual Requirement Submission Status Type - Cancelled
     */
    global static final String SUBMISSION_STATUS_TYPE_CANCELLED = 'Cancelled';

    /**
     * @description Individual Requirement Submission Status Type - Resubmission Requested
     */
    global static final String SUBMISSION_STATUS_TYPE_RESUBMISSION_REQUESTED = 'Resubmission_Requested';

    /**
     * @description Link To Individual Achievement - Yes
     */
    global static final String LINK_TO_INDIVIDUAL_ACHIEVEMENT_YES = 'Yes';
    
    /**
     * @description Link To Individual Achievement - No
     */
    global static final String LINK_TO_INDIVIDUAL_ACHIEVEMENT_NO = 'No';
    
    /**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel() {
        return SObjectType.reduivy__Individual_Requirement__c.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel() {
        return SObjectType.reduivy__Individual_Requirement__c.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName() {
        return SObjectType.reduivy__Individual_Requirement__c.getName();
    }

    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.reduivy__Individual_Requirement__c);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }

    
    /**
     * @description List of reduivy__IdvRq_Review_Status_Config__mdt
     */
    private static List<reduivy__IdvRq_Review_Status_Config__mdt> reviewStatusConfigs;

    /**
     * @description Review status configs metadata sorted according to Review Status field
     * @return List<reduivy__IdvRq_Review_Status_Config__mdt>
     */
    public static List<reduivy__IdvRq_Review_Status_Config__mdt> getReviewStatusConfig(){

        if (reviewStatusConfigs == null) {
            Schema.DescribeFieldResult dfr = Schema.SObjectType.reduivy__Individual_Requirement__c.fields.reduivy__Review_Status__c;
            List<Schema.PicklistEntry> pleList = dfr.getPicklistValues();

            List<reduivy__IdvRq_Review_Status_Config__mdt> configs = reduivy__IdvRq_Review_Status_Config__mdt.getAll().values();
            List<reduivy__IdvRq_Review_Status_Config__mdt> sortedConfigs = new List<reduivy__IdvRq_Review_Status_Config__mdt>();

            for (Schema.PicklistEntry ple : pleList) {
                if(ple.isActive()) {
                    for (reduivy__IdvRq_Review_Status_Config__mdt config : configs) {
                        if (config.reduivy__Active__c && ple.getValue() == config.reduivy__Review_Status__c) {
                            sortedConfigs.add(config);
                        }
                    }
                }
            }

            reviewStatusConfigs = sortedConfigs;
        }

        return reviewStatusConfigs;
    }

    /**
     * @description List of reduivy__IdvRq_Submission_Status_Config__mdt
     */
    private static List<reduivy__IdvRq_Submission_Status_Config__mdt> submissionStatusConfigs;

    /**
     * @description Submission status configs metadata sorted according to Submission Status field
     * @return List<reduivy__IdvRq_Submission_Status_Config__mdt>
     */
    public static List<reduivy__IdvRq_Submission_Status_Config__mdt> getSubmissionStatusConfig(){

        if (submissionStatusConfigs == null) {
            Schema.DescribeFieldResult dfr = Schema.SObjectType.reduivy__Individual_Requirement__c.fields.reduivy__Submission_Status__c;
            List<Schema.PicklistEntry> pleList = dfr.getPicklistValues();

            List<reduivy__IdvRq_Submission_Status_Config__mdt> configs = reduivy__IdvRq_Submission_Status_Config__mdt.getAll().values();
            List<reduivy__IdvRq_Submission_Status_Config__mdt> sortedConfigs = new List<reduivy__IdvRq_Submission_Status_Config__mdt>();

            for (Schema.PicklistEntry ple : pleList) {
                if(ple.isActive()) {
                    for (reduivy__IdvRq_Submission_Status_Config__mdt config : configs) {
                        if (config.reduivy__Active__c && ple.getValue() == config.reduivy__Submission_Status__c) {
                            sortedConfigs.add(config);
                        }
                    }
                }
            }

            submissionStatusConfigs = sortedConfigs;
        }

        return submissionStatusConfigs;
    }

    /**
     * @description Reviewed statuses
     */
    public static List<String> reviewedStatuses;

    /**
     * @description get all the review statuses that has the reviewed checkbox checked in the custom metadata
     * @return   List of reviewed statuses
     */
    public static List<String> getReviewedStatuses(){
        if(reviewedStatuses == null) {
            reviewedStatuses = new List<String>();
            
            for(reduivy__IdvRq_Review_Status_Config__mdt config : getReviewStatusConfig()){
                if(config.reduivy__Reviewed__c) {
                    reviewedStatuses.add(config.reduivy__Review_Status__c);
                }
            }
        }

        return reviewedStatuses;
    }

    /**
     * @description Submission Open statuses
     */
    public static List<String> submissionOpenStatuses;

    /**
     * @description Get all submission statuses that have the 'Open' type in the custom metadata
     * @return   List of submission open statuses
     */
    public static List<String> getSubmissionOpenStatuses(){
        if(submissionOpenStatuses == null) {
            submissionOpenStatuses = new List<String>();
            
            for(reduivy__IdvRq_Submission_Status_Config__mdt config : getSubmissionStatusConfig()){
                if(config.reduivy__Type__c == SUBMISSION_STATUS_TYPE_OPEN) {
                    submissionOpenStatuses.add(config.reduivy__Submission_Status__c);
                }
            }
        }

        return submissionOpenStatuses;
    }

    /**
     * @description Submission Submitted statuses
     */
    public static List<String> submissionSubmittedStatuses;

    /**
     * @description Get all submission statuses that have the 'Submitted' type in the custom metadata
     * @return   List of submission submitted statuses
     */
    public static List<String> getSubmissionSubmittedStatuses(){
        if(submissionSubmittedStatuses == null) {
            submissionSubmittedStatuses = new List<String>();
            
            for(reduivy__IdvRq_Submission_Status_Config__mdt config : getSubmissionStatusConfig()){
                if(config.reduivy__Type__c == SUBMISSION_STATUS_TYPE_SUBMITTED) {
                    submissionSubmittedStatuses.add(config.reduivy__Submission_Status__c);
                }
            }
        }

        return submissionSubmittedStatuses;
    }

    /**
     * @description Submission Cancelled statuses
     */
    public static List<String> submissionCancelledStatuses;

    /**
     * @description Get all submission statuses that have the 'Cancelled' type in the custom metadata
     * @return   List of submission cancelled statuses
     */
    public static List<String> getSubmissionCancelledStatuses(){
        if(submissionCancelledStatuses == null) {
            submissionCancelledStatuses = new List<String>();
            
            for(reduivy__IdvRq_Submission_Status_Config__mdt config : getSubmissionStatusConfig()){
                if(config.reduivy__Type__c == SUBMISSION_STATUS_TYPE_CANCELLED) {
                    submissionCancelledStatuses.add(config.reduivy__Submission_Status__c);
                }
            }
        }

        return submissionCancelledStatuses;
    }

    /**
     * @description Submission Resubmission Requested statuses
     */
    public static List<String> submissionResubmissionRequestedStatuses;

    /**
     * @description Get all submission statuses that have the 'Resubmission_Requested' type in the custom metadata
     * @return   List of submission resubmission required statuses
     */
    public static List<String> getSubmissionResubmissionRequestedStatuses(){
        if(submissionResubmissionRequestedStatuses == null) {
            submissionResubmissionRequestedStatuses = new List<String>();
            
            for(reduivy__IdvRq_Submission_Status_Config__mdt config : getSubmissionStatusConfig()){
                if(config.reduivy__Type__c == SUBMISSION_STATUS_TYPE_RESUBMISSION_REQUESTED) {
                    submissionResubmissionRequestedStatuses.add(config.reduivy__Submission_Status__c);
                }
            }
        }

        return submissionResubmissionRequestedStatuses;
    }
    
    /**
     * @description Map from review status to its type in Requirement
     */
    public static Map<String, String> reviewStatusTypeMap;

    /**
     * @description get the map of the review status type, review status in irq => review status type in requirement checklist
     * @return   Map of review status in irq => review status type in requirement checklist
     */
    public static Map<String, String> getReviewStatusTypeMap() {
        if(reviewStatusTypeMap == null) {
            reviewStatusTypeMap = new Map<String, String>();

            for(reduivy__IdvRq_Review_Status_Config__mdt config : getReviewStatusConfig()){
                reviewStatusTypeMap.put(config.reduivy__Review_Status__c, config.reduivy__Type__c);
            }
        }

        return reviewStatusTypeMap;
    }

    /**
     * @description Map from submission status to its type in Requirement
     */
    public static Map<String, String> submissionStatusTypeMap;

    /**
     * @description get the map of the submission status type, submission status in irq => submission status type in requirement checklist
     * @return   Map of submission status in irq => submission status type in requirement checklist
     */
    public static Map<String, String> getSubmissionStatusTypeMap() {
        if(submissionStatusTypeMap == null) {
            submissionStatusTypeMap = new Map<String, String>();

            for(reduivy__IdvRq_Submission_Status_Config__mdt config : getSubmissionStatusConfig()){
                submissionStatusTypeMap.put(config.reduivy__Submission_Status__c, config.reduivy__Type__c);
            }
        }

        return submissionStatusTypeMap;
    }

    /**
     * @description Unreviewed statuses
     */
    public static List<String> unreviewedStatuses;

    /**
     * @description get all the review statuses that has the reviewed checkbox unchecked in the custom metadata
     * @return   List of unreviewed statuses
     */
    public static List<String> getUnreviewedStatuses(){
        if(unreviewedStatuses == null) {
            unreviewedStatuses = new List<String>();
            
            for(reduivy__IdvRq_Review_Status_Config__mdt config : getReviewStatusConfig()){
                if(!config.reduivy__Reviewed__c) {
                    unreviewedStatuses.add(config.reduivy__Review_Status__c);
                }
            }
        }

        return unreviewedStatuses;
    }

    static List<String> acceptedReviewStatuses; 

    public static List<String> getAcceptedReviewStatuses() {
        if(acceptedReviewStatuses == null) {
            acceptedReviewStatuses = new List<String>();
            
            for(reduivy__IdvRq_Review_Status_Config__mdt config : getReviewStatusConfig()){
                if(config.reduivy__Type__c == REVIEW_STATUS_TYPE_ACCEPTED) {
                    acceptedReviewStatuses.add(config.reduivy__Review_Status__c);
                }
            }
        }

        return acceptedReviewStatuses;
    }

    /**
     * @description map of review status => submission status 
     */
    public static Map<String, String> submissionStatusMap;

    /**
     * @description get the map of review status => submission status 
     * @return   Map<String, String>
     */
    public static Map<String, String> getSubmissionStatusMap(){
        if(Test.isRunningTest()) {
            return getTestSubmissionStatusMap();
        }


        if(submissionStatusMap == null) {
            submissionStatusMap = new Map<String, String>();
            
            for(reduivy__IdvRq_Review_Status_Config__mdt config : getReviewStatusConfig()){
                if(String.isNotBlank(config.reduivy__Submission_Status__c)) {
                    submissionStatusMap.put(config.reduivy__Review_Status__c, config.reduivy__Submission_Status__c);
                }
            }
        }
        return submissionStatusMap;
    }

    
    /**
     * @description map of review status => submission status to be used in test class
     */
    static Map<String, String> testSubmissionStatusMap;

    /**
     * @description get map of review status => submission status to be used in test class
     * @return   Map<String, String>
     */
    static Map<String, String> getTestSubmissionStatusMap() {
        if(testSubmissionStatusMap == null) {
            testSubmissionStatusMap = new Map<String, String>{
                'Accepted' => 'Submitted',
                'Conditionally Accepted' => 'Submitted',
                'Not Accepted' => 'Submitted',
                'Not Required' => null,
                'Open' => 'Open',
                'Under Review' => 'Submitted'
            };
        }
        return testSubmissionStatusMap;
    }

    /**
     * @description create an individual requirement from a study requirement
     * @param  srq   the study requirement record
     * @param  irsId parent individual requirement set id
     * @return       individual requirement
     */
    public static reduivy__Individual_Requirement__c createIrq(reduivy__Study_Requirement__c srq, Id irsId, Id ownerId){
        reduivy__Individual_Requirement__c irq = new reduivy__Individual_Requirement__c();
        if(srq != null) {
            //non common fields
            if(srq.reduivy__Due_Days__c != null) {
                irq.reduivy__Due_Date__c = System.today().addDays(srq.reduivy__Due_Days__c.intValue());
            }
            if(String.isNotBlank(irsId)) {
                irq.reduivy__Individual_Requirement_Set__c = irsId;
            }
            irq.reduivy__Study_Requirement__c = srq.Id;
            irq.OwnerId = ownerId;

            //common fields
            Set<String> commonFields = getSrqIrqCommonFields();
            for(String commonField : commonFields) {
                irq.put(commonField, srq.get(commonField));
            }
        }

        return irq;
    }

    /**
     * @description list of fields that has the same name in study requirement and individual requirement
     * @return   Set<String>
     */
    private static Set<String> srqIrqCommonFields;

    /**
     * @description get list of fields that has the same name in study requirement and individual requirement
     * @return   Set<String>
     */
    public static Set<String> getSrqIrqCommonFields(){
        if(srqIrqCommonFields == null) {
            srqIrqCommonFields = new Set<String>();
            Set<String> irqCloningFields = REDU_Metadata_UTIL.getObjectFieldsForCloning(getApiName(), AccessType.CREATABLE);

            Map<String, Schema.SObjectField> srqFieldsMap = Schema.SObjectType.reduivy__Study_Requirement__c.fields.getMap();
            Map<String, Schema.SObjectField> irqFieldsMap = Schema.SObjectType.reduivy__Individual_Requirement__c.fields.getMap();

            for(Schema.SObjectField srqField : srqFieldsMap.values()) {
                Schema.DescribeFieldResult srqFieldResult = srqField.getDescribe();
                String srqFieldName = srqFieldResult.getName();

                if(irqCloningFields.contains(srqFieldName)) {
                    srqIrqCommonFields.add(srqFieldName);
                }
            }
        }

        return srqIrqCommonFields;
      
    }

    /**
     * @description find the owner id of new irq based on certain criteria
     * @param  sobjectName name of the sobject of the parent irs
     * @param  srq         parent Study Requirement
     * @param  parentIrs   parent Individual Requirement Set
     * @return             return owner id
     */
    public static Id getIrqOwnerId(String sobjectName, reduivy__Study_Requirement__c srq, reduivy__Individual_Requirement_Set__c parentIrs) {
        Id ownerId;
        Boolean hasMasterDetailRelationship = REDU_Metadata_UTIL.hasMasterDetailRelationship(sobjectName);
        if(String.isNotBlank(srq.reduivy__Task_Owner_Id__c)) {
            ownerId = srq.reduivy__Task_Owner_Id__c;
        } else if (hasMasterDetailRelationship == false) {
            ownerId = parentIrs.OwnerId;
        } else {
            ownerId = UserInfo.getUserId();
        }

        return ownerId;
    }

}