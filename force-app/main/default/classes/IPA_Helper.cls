/**
 * @author      WDCi (Lean)
 * @date        Jan 2025
 * @group       Object Helper
 * @description Individual Program Application object helper class that contains the picklist option constants and object related methods
 * @changehistory
 * ISS-002165 07-01-2025 Lean - new class
 * ISS-002415 23-05-2025 XW - added negative test mock metadata, and method to get rollup field grouped by field or status
 * ISS-002487 30-06-2025 XiRouh - Added getCreateIpeStatusWithIpeEnrollmentStatus()
 * ISS-002508 08-07-2025 XiRouh - Added getActiveStatuses()
 * ISS-002675 14-01-2026 XiRouh - Added canRunEvaluationTestForRequirementIndicatorInIPA()
 */
global inherited sharing class IPA_Helper implements SObject_Helper {

    /**
     * @description Application Status - Draft
     */
    global static final String APPLICATION_STATUS_DRAFT = 'Draft';
    
    /**
     * @description Application Status - Submitted
     */
    global static final String APPLICATION_STATUS_SUBMITTED = 'Submitted';
    
    /**
     * @description Application Status - Reviewing
     */
    global static final String APPLICATION_STATUS_REVIEWING = 'Reviewing';
    
    /**
     * @description Application Status - Approved
     */
    global static final String APPLICATION_STATUS_APPROVED = 'Approved';
    
    /**
     * @description Application Status - Offer
     */
    global static final String APPLICATION_STATUS_OFFER = 'Offer';
    
    /**
     * @description Application Status - Offer Accepted
     */
    global static final String APPLICATION_STATUS_OFFER_ACCEPTED = 'Offer Accepted';
    
    /**
     * @description Application Status - Offer Declined
     */
    global static final String APPLICATION_STATUS_OFFER_DECLINED = 'Offer Declined';
    
    /**
     * @description Application Status - Rejected
     */
    global static final String APPLICATION_STATUS_REJECTED = 'Rejected';
    
    /**
     * @description Application Status - Cancelled
     */
    global static final String APPLICATION_STATUS_CANCELLED = 'Cancelled';

    /**
     * @description Application Status - Waitlisted
     */
    global static final String APPLICATION_STATUS_WAITLISTED = 'Waitlisted';

    /**
     * @description Student Group Type - Standard
     */
    global static final String STUDENT_GROUP_TYPE_STANDARD = 'Standard';

    /**
     * @description Student Group Type - Disabled
     */
    global static final String STUDENT_GROUP_TYPE_DISABLED = 'Disabled';

    /**
     * @description Study Intake Group Assignment - Auto
     */
    global static final String STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO = 'Auto';

    /**
     * @description Study Intake Group Assignment - Manual
     */
    global static final String STUDY_INTAKE_GROUP_ASSIGNMENT_MANUAL = 'Manual';

    @TestVisible
    private static Boolean isNegativeTests = false;

    /**
     * @description List of reduivy__IdvPa_Application_Status_Config__mdt that is used for negative tests
     */
    private static List<reduivy__IdvPa_Application_Status_Config__mdt> getApplicationStatusConfigsforTest(){


            Map<String, String> testMetadataMap = new Map<String, String> {
                APPLICATION_STATUS_DRAFT => 'InvalidRollup',
                APPLICATION_STATUS_SUBMITTED => 'reduivy__Registration_Open_Date__c',
                APPLICATION_STATUS_APPROVED => 'reduivy__Available_Places__c'
            };
            
            List<reduivy__IdvPa_Application_Status_Config__mdt> applicationStatusConfigsforTest = new List<reduivy__IdvPa_Application_Status_Config__mdt>();

            for(String status : testMetadataMap.keySet()) {
                applicationStatusConfigsforTest.add(new reduivy__IdvPa_Application_Status_Config__mdt(
                    MasterLabel = status,
                    DeveloperName = status,
                    reduivy__Application_Status__c = status,
                    reduivy__Type__c = status,
                    reduivy__Active__c = true,
                    reduivy__Include_In_Rollup__c = true,
                    reduivy__Rollup_Field_API_Name__c = testMetadataMap.get(status)
                ));
            }
        
            return applicationStatusConfigsforTest;
    }


    

    /**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel() {
        return SObjectType.reduivy__Individual_Program_Application__c.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel() {
        return SObjectType.reduivy__Individual_Program_Application__c.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName() {
        return SObjectType.reduivy__Individual_Program_Application__c.getName();
    }

    /**
     * @description List of reduivy__IdvPa_Application_Status_Config__mdt
     */
    private static List<reduivy__IdvPa_Application_Status_Config__mdt> applicationStatusConfigs;
    /**
     * @description Enrollment status configs metadata sorted according to Enrollment Status field
     * @return List<reduivy__IdvPa_Application_Status_Config__mdt>
     */
    public static List<reduivy__IdvPa_Application_Status_Config__mdt> getApplicationStatusConfig(){

        //return mock data if is testing and is negative test
        if(Test.isRunningTest() && isNegativeTests) {
            return getApplicationStatusConfigsforTest();
        }

        if (applicationStatusConfigs == null){
            Schema.DescribeFieldResult dfr = Schema.SObjectType.reduivy__Individual_Program_Application__c.fields.reduivy__Application_Status__c;
            List<Schema.PicklistEntry> pleList = dfr.getPicklistValues();

            List<reduivy__IdvPa_Application_Status_Config__mdt> configs = reduivy__IdvPa_Application_Status_Config__mdt.getAll().values();
            List<reduivy__IdvPa_Application_Status_Config__mdt> sortedConfigs = new List<reduivy__IdvPa_Application_Status_Config__mdt>();

            for (Schema.PicklistEntry ple : pleList){
                if (ple.isActive()){
                    for (reduivy__IdvPa_Application_Status_Config__mdt config : configs){
                        if (config.reduivy__Active__c && ple.getValue() == config.reduivy__Application_Status__c){
                            sortedConfigs.add(config);
                        }
                    }
                }
            }

            applicationStatusConfigs = sortedConfigs;
        }

        return applicationStatusConfigs;
    }

    /**
     * @description Draft statuses
     */
    private static List<String> draftStatuses;

    /**
     * @description Return a list of draft application status
     * @return  List<String>
     */
    global static List<String> getDraftStatuses(){
        if (draftStatuses == null){
            draftStatuses = new List<String>();

            for (reduivy__IdvPa_Application_Status_Config__mdt config : getApplicationStatusConfig()){
                if (config.reduivy__Type__c == APPLICATION_STATUS_DRAFT){
                    draftStatuses.add(config.reduivy__Application_Status__c);
                }
            }
        }

        return draftStatuses;
    }
	
    
    /**
     * @description Submitted statuses
     */
    private static List<String> submittedStatuses;
    
    /**
     * @description Return a list of submitted application status
     * @return  List<String>
     */
    global static List<String> getSubmittedStatuses(){
        if (submittedStatuses == null){
            submittedStatuses = new List<String>();

            for (reduivy__IdvPa_Application_Status_Config__mdt config : getApplicationStatusConfig()){
                if (config.reduivy__Type__c == APPLICATION_STATUS_SUBMITTED){
                    submittedStatuses.add(config.reduivy__Application_Status__c);
                }
            }
        }

        return submittedStatuses;
    }   

    /**
     * @description Reviewing statuses
     */
    private static List<String> reviewingStatuses;
    
    /**
     * @description Return a list of reviewing application status
     * @return  List<String>
     */
    global static List<String> getReviewingStatuses(){
        if (reviewingStatuses == null){
            reviewingStatuses = new List<String>();

            for (reduivy__IdvPa_Application_Status_Config__mdt config : getApplicationStatusConfig()){
                if (config.reduivy__Type__c == APPLICATION_STATUS_REVIEWING){
                    reviewingStatuses.add(config.reduivy__Application_Status__c);
                }
            }
        }

        return reviewingStatuses;
    }

    /**
     * @description Approved statuses
     */
    private static List<String> approvedStatuses;
    
    /**
     * @description Return a list of Approved application status
     * @return  List<String>
     */
    global static List<String> getApprovedStatuses(){
        if (approvedStatuses == null){
            approvedStatuses = new List<String>();

            for (reduivy__IdvPa_Application_Status_Config__mdt config : getApplicationStatusConfig()){
                if (config.reduivy__Type__c == APPLICATION_STATUS_APPROVED){
                    approvedStatuses.add(config.reduivy__Application_Status__c);
                }
            }
        }

        return approvedStatuses;
    }

    /**
     * @description Approved statuses
     */
    private static List<String> offerStatuses;
    
    /**
     * @description Return a list of Offer application status
     * @return  List<String>
     */
    global static List<String> getOfferStatuses(){
        if (offerStatuses == null){
            offerStatuses = new List<String>();

            for (reduivy__IdvPa_Application_Status_Config__mdt config : getApplicationStatusConfig()){
                if (config.reduivy__Type__c == APPLICATION_STATUS_OFFER){
                    offerStatuses.add(config.reduivy__Application_Status__c);
                }
            }
        }

        return offerStatuses;
    }

    /**
     * @description Offer Accepted statuses
     */
    private static List<String> offerAcceptedStatuses;
    
    /**
     * @description Return a list of Offer Accepted application status
     * @return  List<String>
     */
    global static List<String> getOfferAcceptedStatuses(){
        if (offerAcceptedStatuses == null){
            offerAcceptedStatuses = new List<String>();

            for (reduivy__IdvPa_Application_Status_Config__mdt config : getApplicationStatusConfig()){
                if (config.reduivy__Type__c == APPLICATION_STATUS_OFFER_ACCEPTED){
                    offerAcceptedStatuses.add(config.reduivy__Application_Status__c);
                }
            }
        }

        return offerAcceptedStatuses;
    }

    /**
     * @description Offer Declined statuses
     */
    private static List<String> offerDeclinedStatuses;
    
    /**
     * @description Return a list of Offer Declined application status
     * @return  List<String>
     */
    global static List<String> getOfferDeclinedStatuses(){
        if (offerDeclinedStatuses == null){
            offerDeclinedStatuses = new List<String>();

            for (reduivy__IdvPa_Application_Status_Config__mdt config : getApplicationStatusConfig()){
                if (config.reduivy__Type__c == APPLICATION_STATUS_OFFER_DECLINED){
                    offerDeclinedStatuses.add(config.reduivy__Application_Status__c);
                }
            }
        }

        return offerDeclinedStatuses;
    }

    /**
     * @description Rejected statuses
     */
    private static List<String> rejectedStatuses;
    
    /**
     * @description Return a list of Rejected application status
     * @return  List<String>
     */
    global static List<String> getRejectedStatuses(){
        if (rejectedStatuses == null){
            rejectedStatuses = new List<String>();

            for (reduivy__IdvPa_Application_Status_Config__mdt config : getApplicationStatusConfig()){
                if (config.reduivy__Type__c == APPLICATION_STATUS_REJECTED){
                    rejectedStatuses.add(config.reduivy__Application_Status__c);
                }
            }
        }

        return rejectedStatuses;
    }

    /**
     * @description Cancelled statuses
     */
    private static List<String> cancelledStatuses;
    
    /**
     * @description Return a list of Cancelled application status
     * @return  List<String>
     */
    global static List<String> getCancelledStatuses(){
        if (cancelledStatuses == null){
            cancelledStatuses = new List<String>();

            for (reduivy__IdvPa_Application_Status_Config__mdt config : getApplicationStatusConfig()){
                if (config.reduivy__Type__c == APPLICATION_STATUS_CANCELLED){
                    cancelledStatuses.add(config.reduivy__Application_Status__c);
                }
            }
        }

        return cancelledStatuses;
    }
    
    /**
     * @description Waitlisted statuses
     */
    private static List<String> waitlistedStatuses;
    
    /**
     * @description Return a list of submitted application status
     * @return  List<String>
     */
    global static List<String> getWaitlistedStatuses(){
        if (waitlistedStatuses == null){
            waitlistedStatuses = new List<String>();

            for (reduivy__IdvPa_Application_Status_Config__mdt config : getApplicationStatusConfig()){
                if (config.reduivy__Type__c == APPLICATION_STATUS_WAITLISTED){
                    waitlistedStatuses.add(config.reduivy__Application_Status__c);
                }
            }
        }

        return waitlistedStatuses;
    }   

    /**
     * @description C IPE status with IPE enrollment status
     */
    private static Map<String, String> createIpeStatusWithIpeEnrollmentStatus;
    
    /**
     * @description Return a list of create IPE application status with the IPE status
     * @return  Map<String, String>
     */
    global static Map<String, String> getCreateIpeStatusWithIpeEnrollmentStatus(){
        if (createIpeStatusWithIpeEnrollmentStatus == null){
            createIpeStatusWithIpeEnrollmentStatus = new Map<String, String>();

            for (reduivy__IdvPa_Application_Status_Config__mdt config : getApplicationStatusConfig()){
                if (config.reduivy__Create_IPE__c){
                    //Only return the first status if duplicate application statuses are found
                    if(!createIpeStatusWithIpeEnrollmentStatus.containsKey(config.reduivy__Application_Status__c)) {
                        createIpeStatusWithIpeEnrollmentStatus.put(config.reduivy__Application_Status__c, config.reduivy__IPE_Enrollment_Status__c);
                    }
                }
            }
        }

        return createIpeStatusWithIpeEnrollmentStatus;
    }

    /**
     * @description Return a list of active statuses
     * @return List<String>
     */
    public static List<String> getActiveStatuses() {
        
        List<String> statuses = new List<String>();

        statuses.addAll(getDraftStatuses());
        statuses.addAll(getSubmittedStatuses());
        statuses.addAll(getReviewingStatuses());
        statuses.addAll(getApprovedStatuses());
        statuses.addAll(getOfferStatuses());
        statuses.addAll(getOfferAcceptedStatuses());

        return statuses;
    }

    /**
     * @description Include In Rollup statuses
     */
    private static Map<String, Set<String>> rollupStatusesByField;

    /**
     * @description 
     * @return   Map<Rollup_Field_API_Name, Set<IPA_statuses>>
     */
    global static Map<String, Set<String>> getRollupStatusesByField(){
        if(rollupStatusesByField == null){
            rollupStatusesByField = new Map<String, Set<String>>();

            for(reduivy__IdvPa_Application_Status_Config__mdt config : getApplicationStatusConfig()) {
                if(config.reduivy__Include_In_Rollup__c && String.isNotBlank(config.reduivy__Rollup_Field_API_Name__c)) {
                    List<String> rollupFieldList = config.reduivy__Rollup_Field_API_Name__c.split(REDU_List_UTIL.DELIMITER);
                    for(String field : rollupFieldList){
                        if(!rollupStatusesByField.containsKey(field)) {
                            rollupStatusesByField.put(field, new Set<String>());
                        }
                        rollupStatusesByField.get(field).add(config.reduivy__Application_Status__c);
                    }
                }
            }
        }

        return rollupStatusesByField;
    }

    /**
     * @description Include In Rollup statuses
     */
    private static Map<String, Set<String>> rollupFieldsApiNameByStatus;

    /**
     * @description 
     * @return   Map<IPA_statuses, Set<Rollup_Field_API_Name>>
     */
    global static Map<String, Set<String>> getRollupFieldsApiNameByStatus(){
        if(rollupFieldsApiNameByStatus == null){
            rollupFieldsApiNameByStatus = new Map<String, Set<String>>();

            for(reduivy__IdvPa_Application_Status_Config__mdt config : getApplicationStatusConfig()) {
                if(config.reduivy__Include_In_Rollup__c && String.isNotBlank(config.reduivy__Rollup_Field_API_Name__c)) {
                    List<String> rollupFieldList = config.reduivy__Rollup_Field_API_Name__c.split(REDU_List_UTIL.DELIMITER);
                    rollupFieldsApiNameByStatus.put(config.reduivy__Application_Status__c, new Set<String>(rollupFieldList));
                }
            }
        }

        return rollupFieldsApiNameByStatus;
    }

    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.reduivy__Individual_Program_Application__c);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }
    
    /**
     * @description Return true if reduivy__Test_Teaching_Period__c is available in object for testing
     * @return Boolean
     */
    public static Boolean canRunEvaluationTest() {

        Map<String, Schema.SObjectField> ipaFields = SObjectType.reduivy__Individual_Program_Application__c.fields.getMap();

        //patch org doesn't allow us to add fields to the object, hence we will only proceed the test if the field exist e.g., major release test
        return ipaFields.containsKey('reduivy__Test_Teaching_Period__c') || ipaFields.containsKey('Test_Teaching_Period__c');
    }

    /**
     * @description Return true if reduivy__Test_Requirements_Complete_Admin__c, reduivy__Test_Requirements_Complete_Faculty__c, and reduivy__Test_Requirements_Complete_Student__c is available in object for testing
     * @return Boolean
     */
    public static Boolean canRunEvaluationTestForRequirementIndicatorInIPA() {

        Map<String, Schema.SObjectField> ipaFields = SObjectType.reduivy__Individual_Program_Application__c.fields.getMap();

        //patch org doesn't allow us to add fields to the object, hence we will only proceed the test if the field exist e.g., major release test
        return (ipaFields.containsKey('reduivy__Test_Requirements_Complete_Admin__c') || ipaFields.containsKey('Test_Requirements_Complete_Admin__c')) &&
        (ipaFields.containsKey('reduivy__Test_Requirements_Complete_Faculty__c') || ipaFields.containsKey('Test_Requirements_Complete_Faculty__c')) &&
        (ipaFields.containsKey('reduivy__Test_Requirements_Complete_Student__c') || ipaFields.containsKey('Test_Requirements_Complete_Student__c'));
    }
}