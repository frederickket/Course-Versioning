/**
 * @author      WDCi (Lean)
 * @date        Sept 2023
 * @group       Object Helper
 * @description Contact object helper class that contains the picklist option constants and object related methods
 * @changehistory
 * ISS-001618 02-10-2023 dblack - added constants and methods required for CON_CreateAccount_EXE.cls
 * ISS-002050 13-09-2024 Sueanne - added method getContactEvents() to get contact events
 * ISS-002380 09-04-2025 XW - consider faculty isn enrollment status in getContactEvents
 * ISS-002421 30-04-2025 XW - Change getContactEvents recordId type to String to avoid Invalid Id error
 * ISS-002675 14-01-2026 XiRouh - Added canRunEvaluationTestForRequirementIndicatorInContact()
 */
global inherited sharing class CON_Helper implements SObject_Helper{
    /**
     * @description Contact type - Applicant
     */
    global static final String CONTACT_TYPE_APPLICANT = 'Applicant';
    /**
     * @description Contact type - Student
     */
    global static final String CONTACT_TYPE_STUDENT = 'Student';
    /**
     * @description Contact type - Alumni
     */
    global static final String CONTACT_TYPE_ALUMNI = 'Alumni';
    /**
     * @description Contact type - Faculty
     */
    global static final String CONTACT_TYPE_FACULTY = 'Faculty';
    /**
     * @description Class constants
     */
    private static final Id ADMIN_ACCOUNT_RECORD_TYPE_ID = ACC_Helper.getAdministrativeRecordTypeId();
    private static final String ADMIN_ACCOUNT_NAME_FORMAT = REDU_AppSetting_UTIL.getAdministrativeAccountNameFormat();
    
    /**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel(){
        return SObjectType.Contact.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel(){
        return SObjectType.Contact.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName(){
        return SObjectType.Contact.getName();
    }

    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.Contact);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }

    /**
     * @description Create a new account for each contact with the account name formatted as specified in the custom setting
     * @param conList List<Contact>
     * @return accMap Map<Integer, Account>
     */
    public static Map<Integer, Account> getNewAccountMap(List<Contact> conList){

        Map<Integer, Account> accMap = new Map<Integer, Account>();
        Map<String, String> mergeFields = REDU_StringMerge_UTIL.extractFieldNames(null, ADMIN_ACCOUNT_NAME_FORMAT);

        Integer accNameFieldLength = Schema.SObjectType.Account.fields.Name.getLength();

        for (Contact con : conList){

            // Create the account name according to the format specified in the custom setting
            String accName = REDU_StringMerge_UTIL.mergeValues(con, mergeFields, ADMIN_ACCOUNT_NAME_FORMAT, accNameFieldLength);

            // Populate the map
            accMap.put(conList.indexOf(con), new Account(
                Name = accName, 
                RecordTypeId = ADMIN_ACCOUNT_RECORD_TYPE_ID
            ));
        }

        // Insert the accounts
        Map<Id, Contact> conMap = new Map<Id, Contact>();
        for (Contact con : conList){
            conMap.put(con.AccountId, con);
        }
        REDU_Database_UTIL.doInsert(accMap.values(), conMap, 'Id', false);

        return accMap;
    }

    /**
     * @description Get current logged-in user contact record
     * @return Contact
     */
    public static Contact getCurrentLoggedInUserContact(){
        User currentUser = USR_HELPER.getCurrentUserInfo(UserInfo.getUserId());
        return getCurrentLoggedInUserContact(currentUser);
    }

    /**
     * @description Get contact record based on user record
     * @return Contact
     */
    public static Contact getCurrentLoggedInUserContact(User userRecord){

        Contact userContact;

        if(String.isNotBlank(userRecord.ContactId)){
            userContact = [SELECT Id, AccountId, reduivy__Corporate_Purchaser__c, reduivy__User__c FROM Contact WHERE Id =: userRecord.ContactId WITH USER_MODE LIMIT 1];
        } else {
            for(Contact contact : [SELECT Id, AccountId, reduivy__Corporate_Purchaser__c, reduivy__User__c FROM Contact WHERE reduivy__User__c =: userRecord.Id WITH USER_MODE LIMIT 1]){
                userContact = contact;
            }
        }

        return userContact;
    }
    

    /**
     * @description Get a list of booked event for contact (student and faculty events)
     * @param recordId Id of contact
     * @return List<reduivy__Study_Event__c>
     */
    public static List<reduivy__Study_Event__c> getContactEvents(String recordId, Datetime fromDate, Datetime toDate, List<String> enrollmentStatuses){

        Id contactId;
        if (String.isNotBlank(recordId)) {
            Id tempId = Id.valueOf(recordId);
            
            if(tempId.getSobjectType() == Schema.Contact.getSobjectType()) {
                contactId = tempId;
            }
        }

        if(String.isBlank(contactId)){
            User currentUser = USR_Helper.getCurrentUserInfo(UserInfo.getUserId());
            if (currentUser != null && String.isNotBlank(currentUser.ContactId)) {
                contactId = currentUser.ContactId;
            } else {
                throw new REDU_ApplicationException(Label.Failed_To_Identify_The_Contact_For_Current_User);
            }
        }

        //get faculty study events from Study Event Relation, this includes both faculty allocation (with isn) and appointments (without isn)
        Set<String> serFields = new Set<String>{
            'Id',
            'Name',
            'reduivy__Contact__c',
            'reduivy__Study_Event__c',
            'reduivy__Event_Start_Datetime__c',
            'reduivy__Event_End_Datetime__c'
        };

        String serSoql = 'SELECT ' + String.join(serFields, ', ') +
            ' FROM reduivy__Study_Event_Relation__c ' +
            ' WHERE reduivy__Contact__c = :contactId ' +
            ' AND reduivy__Event_Start_Datetime__c >=: fromDate AND reduivy__Event_Start_Datetime__c <=: toDate ' +
            ' AND reduivy__Study_Event__r.reduivy__Status__c IN: sevStatus ' + 
            ' AND reduivy__Response_Status__c IN: responseStatus ' +
            ' AND (reduivy__Individual_Session_Enrollment__c = null OR (reduivy__Individual_Session_Enrollment__r.RecordTypeId =: isnFacultyRtId AND reduivy__Individual_Session_Enrollment__r.reduivy__Enrollment_Status__c IN :enrollmentStatuses))';

        Set<String> sevStatus = new Set<String>{SEV_Helper.STATUS_CONFIRMED};
        Set<String> responseStatus = new Set<String>{SER_Helper.RESPONSE_STATUS_ACCEPTED, SER_Helper.RESPONSE_STATUS_NEW, SER_Helper.RESPONSE_STATUS_REJECTED};

        Map<String, Object> serBindParams = new Map<String, Object>();
        serBindParams.put('contactId', contactId);
        serBindParams.put('fromDate', fromDate);
        serBindParams.put('toDate', toDate);
        serBindParams.put('sevStatus', sevStatus);
        serBindParams.put('responseStatus', responseStatus);
        serBindParams.put('enrollmentStatuses', enrollmentStatuses);
        serBindParams.put('isnFacultyRtId', ISN_Helper.getFacultyRecordTypeId());

        //gather the study event Id from study event relation
        Set<Id> sevIds = new Set<Id>();
        for (reduivy__Study_Event_Relation__c ser : (List<reduivy__Study_Event_Relation__c>) Database.queryWithBinds(serSoql, serBindParams, AccessLevel.USER_MODE)) {
            if (String.isNotBlank(ser.reduivy__Study_Event__c)) {
                sevIds.add(ser.reduivy__Study_Event__c);
            }
        }

        //get student study events from Individual Session Enrollment, this should also cover the faculty as a student too
        Set<String> isnFields = new Set<String>{
            'Id',
            'Name',
            'reduivy__Contact_Id__c',
            'reduivy__Enrollment_Status__c',
            'reduivy__Individual_Enrollment__c',
            'RecordTypeId',
            'reduivy__Start_Date__c',
            'reduivy__End_Date__c',
            'reduivy__Study_Session__c',
            'reduivy__Study_Session__r.reduivy__End_Date_Calculated__c',
            'reduivy__Study_Session__r.reduivy__Start_Date_Calculated__c'
        };

        String isnSoql = 'SELECT ' + String.join(isnFields, ', ') +
        ' FROM reduivy__Individual_Session_Enrollment__c ' +
        ' WHERE reduivy__Contact_Id__c =: contactId ' +
        ' AND reduivy__Enrollment_Status__c IN: enrollmentStatuses ' + 
        ' AND RecordTypeId =: isnStudentRtId';

        Map<String, Object> isnBindParams = new Map<String, Object>();
        isnBindParams.put('contactId', contactId);
        isnBindParams.put('enrollmentStatuses', enrollmentStatuses);
        isnBindParams.put('isnStudentRtId', ISN_Helper.getStudentRecordTypeId());

        //gather the study session Id from individual session enrollment
        Set<Id> sseIds = new Set<Id>();
        Map<Id, List<reduivy__Individual_Session_Enrollment__c>> isnListBySession = new Map<Id, List<reduivy__Individual_Session_Enrollment__c>>();
        for (reduivy__Individual_Session_Enrollment__c isn : (List<reduivy__Individual_Session_Enrollment__c>) Database.queryWithBinds(isnSoql, isnBindParams, AccessLevel.USER_MODE)) {
            if (String.isNotBlank(isn.reduivy__Study_Session__c)) {
                sseIds.add(isn.reduivy__Study_Session__c);

                if (isnListBySession.containsKey(isn.reduivy__Study_Session__c)) {
                    isnListBySession.get(isn.reduivy__Study_Session__c).add(isn);
                } else {
                    isnListBySession.put(isn.reduivy__Study_Session__c, new List<reduivy__Individual_Session_Enrollment__c>{isn});
                }
            }
        }

        //Query the study events related to the enrolled sessions
        Set<String> isnSevFields = new Set<String>{
            'Id',
            'reduivy__Study_Session_Time__c',
            'reduivy__Start_Date_Non_TZ__c',
            'reduivy__End_Date_Non_TZ__c',
            'reduivy__Study_Session_Time__r.reduivy__Study_Session__c'
        };

        String sevByIsnSoql = 'SELECT ' + String.join(isnSevFields, ', ') + 
            ' FROM reduivy__Study_Event__c ' +
            ' WHERE reduivy__Study_Session_Time__r.reduivy__Study_Session__c IN: sseIds ';
            
        Map<String, Object> sevByIsnBindParams = new Map<String, Object>();
        sevByIsnBindParams.put('sseIds', sseIds);

        Map<String, Set<String>> sevObjectFieldsForFls1 = new Map<String, Set<String>>();
        sevObjectFieldsForFls1.put(SEV_Helper.getApiName(), isnSevFields);
        sevObjectFieldsForFls1.put(SST_Helper.getApiName(), new Set<String>{'reduivy__Study_Session__c'});

        //query the study event object which is protected by restriction rules using system mode
        for (reduivy__Study_Event__c sev : (List<reduivy__Study_Event__c>) REDU_SystemMode_UTIL.doQuery(sevByIsnSoql, sevByIsnBindParams, sevObjectFieldsForFls1)) {
            if (String.isNotBlank(sev.reduivy__Study_Session_Time__r.reduivy__Study_Session__c)) {
                Boolean qualifiedSev = false;
                
                for (reduivy__Individual_Session_Enrollment__c isn : isnListBySession.get(sev.reduivy__Study_Session_Time__r.reduivy__Study_Session__c)) {
                    Date startDate = (isn.reduivy__Start_Date__c != null ? isn.reduivy__Start_Date__c : isn.reduivy__Study_Session__r.reduivy__Start_Date_Calculated__c);
                    Date endDate = (isn.reduivy__End_Date__c != null ? isn.reduivy__End_Date__c : isn.reduivy__Study_Session__r.reduivy__End_Date_Calculated__c);

                    if (sev.reduivy__Start_Date_Non_TZ__c >= startDate && sev.reduivy__Start_Date_Non_TZ__c <= endDate) {
                        qualifiedSev = true;
                        break;
                    }
                }

                if (qualifiedSev) {
                    sevIds.add(sev.Id);
                }
            }
        }

        String sevTranslationFieldName = SEV_Helper.getTranslationFieldNameForName();

        //find the study events by sevIds
        Set<String> sevFields = new Set<String>{
            'Id',
            'Name',
            sevTranslationFieldName,
            'reduivy__Start__c',
            'reduivy__End__c',
            'reduivy__Start_Date_Non_TZ__c',
            'reduivy__Start_Time_Non_TZ__c',
            'reduivy__End_Date_Non_TZ__c',
            'reduivy__End_Time_Non_TZ__c',
            'reduivy__Type__c',
            'reduivy__Status__c',
            'reduivy__Study_Session_Time__c',
            'reduivy__Study_Session_Time__r.reduivy__Study_Session__c',
            'reduivy__Study_Session_Time__r.reduivy__Study_Session__r.reduivy__Background_Colour__c',
            'reduivy__Study_Session_Time__r.reduivy__Study_Session__r.reduivy__Text_Colour__c',
            'reduivy__Study_Session_Time__r.reduivy__Study_Session__r.reduivy__Required_Facility_Type__c',
            'reduivy__Study_Session_Time__r.reduivy__Study_Session__r.reduivy__Study_Offering__r.reduivy__Study_Unit__c',
            'reduivy__Study_Session_Time__r.reduivy__Study_Session__r.reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Background_Colour__c',
            'reduivy__Study_Session_Time__r.reduivy__Study_Session__r.reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Text_Colour__c',
            'reduivy__Study_Session_Time__r.reduivy__Study_Session__r.reduivy__Study_Offering__r.reduivy__Campus__c'
        };

        String facTranslationFieldName = FAC_Helper.getTranslationFieldNameForName();

        Set<String> childSerFields = new Set<String>{
            'Id',
            'reduivy__Response_Status__c',
            'reduivy__Relation_Type__c',
            'reduivy__Facility__c',
            'reduivy__Facility__r.Name',
            'reduivy__Contact__c',
            'reduivy__Contact__r.Name',
            'reduivy__Facility__r.' + facTranslationFieldName
        };

        String sevSoql = 'SELECT ' + String.join(sevFields, ', ') + ', ' +
            ' (' +
                ' SELECT ' + String.join(childSerFields, ', ') +
                ' FROM reduivy__Study_Event_Relations__r ' +
            ' ) ' +
            ' FROM reduivy__Study_Event__c' +
            ' WHERE Id IN: sevIds ';

        Map<String, Object> sevBindParams = new Map<String, Object>();
        sevBindParams.put('sevIds', sevIds);

        Map<String, Set<String>> sevObjectFieldsForFls2 = new Map<String, Set<String>>();
        sevObjectFieldsForFls2.put(SEV_Helper.getApiName(), sevFields);
        sevObjectFieldsForFls2.put(SER_Helper.getApiName(), childSerFields);

        sevObjectFieldsForFls2.put(SST_Helper.getApiName(), new Set<String>{
            'reduivy__Study_Session__c'
        });

        sevObjectFieldsForFls2.put(SSE_Helper.getApiName(), new Set<String>{
            'reduivy__Background_Colour__c', 
            'reduivy__Text_Colour__c',
            'reduivy__Required_Facility_Type__c'
        });

        sevObjectFieldsForFls2.put(SOF_Helper.getApiName(), new Set<String>{
            'reduivy__Study_Unit__c', 
            'reduivy__Campus__c'
        });

        sevObjectFieldsForFls2.put(SUN_Helper.getApiName(), new Set<String>{
            'reduivy__Background_Colour__c', 
            'reduivy__Text_Colour__c'
        });

        //query the study event object which is protected by restriction rules using system mode
        List<reduivy__Study_Event__c> studyEvents = new List<reduivy__Study_Event__c>();
        for (reduivy__Study_Event__c sev : (List<reduivy__Study_Event__c>) REDU_SystemMode_UTIL.doQuery(sevSoql, sevBindParams, sevObjectFieldsForFls2)) {
            studyEvents.add(sev);
        }

        return studyEvents;
    }

    /**
     * @description Return true if reduivy__Test_Requirements_Complete_Admin__c, reduivy__Test_Requirements_Complete_Faculty__c, and reduivy__Test_Requirements_Complete_Student__c is available in object for testing
     * @return Boolean
     */
    public static Boolean canRunEvaluationTestForRequirementIndicatorInContact() {

        Map<String, Schema.SObjectField> contactFields = SObjectType.Contact.fields.getMap();

        //patch org doesn't allow us to add fields to the object, hence we will only proceed the test if the field exist e.g., major release test
        return (contactFields.containsKey('reduivy__Test_Requirements_Complete_Admin__c') || contactFields.containsKey('Test_Requirements_Complete_Admin__c')) &&
        (contactFields.containsKey('reduivy__Test_Requirements_Complete_Faculty__c') || contactFields.containsKey('Test_Requirements_Complete_Faculty__c')) &&
        (contactFields.containsKey('reduivy__Test_Requirements_Complete_Student__c') || contactFields.containsKey('Test_Requirements_Complete_Student__c'));
    }
}