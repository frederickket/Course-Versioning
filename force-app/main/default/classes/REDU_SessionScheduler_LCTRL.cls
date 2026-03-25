/**
 * @author      WDCi (Lean)
 * @date        Apr 2024
 * @group       Session Management
 * @description Study session scheduler shared methods
 * @changehistory
 * ISS-001920 23-04-2024 Lean - new class
 * ISS-002230 22-01-2025 XW - get picklist value label if field type is picklist
 * ISS-002269 24-02-2025 XW - allow get study session to only return specified data
 * ISS-002719 07-11-2025 XW - query the selected facility in timeedit modal if the facility doesnt meet the default criteria
 */
public with sharing class REDU_SessionScheduler_LCTRL {
    
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getEducationalInstitutions(){
        try {
            
            List<Account> eduInstList = new List<Account>();
            for (Account eduInst : [SELECT Id, 
                Name, 
                reduivy__Code__c
                FROM Account
                WHERE RecordTypeId =: ACC_Helper.getEducationalInstitutionRecordTypeId()
                AND reduivy__Status__c =: ACC_Helper.STATUS_ACTIVE
                WITH USER_MODE
                ORDER BY Name
            ]) {
                eduInstList.add(eduInst);
            }

            REDU_LightningResponse response = new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(eduInstList));

            return response;
            
        } catch (QueryException qex) {
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getCampuses(String educationalInstitutionId){
        try{

            List<Account> campusList = new List<Account>();

            if(String.isNotBlank(educationalInstitutionId)){
                for(Account campus : [SELECT Id,
                    Name,
                    reduivy__Code__c
                    FROM Account
                    WHERE ParentId =: educationalInstitutionId
                    AND RecordTypeId =: ACC_Helper.getCampusRecordTypeId()
                    AND reduivy__Status__c =: ACC_Helper.STATUS_ACTIVE
                    WITH USER_MODE
                    ORDER BY Name
                ]) {
                    campusList.add(campus);
                }
            }

            REDU_LightningResponse response = new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(campusList));

            return response;

        } catch (QueryException qex) {
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }
   
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getStudyUnits(String educationalInstitutionId){
        try {
            
            List<reduivy__Study_Unit__c> sunList = new List<reduivy__Study_Unit__c>();

            if (String.isNotBlank(educationalInstitutionId)) {
                for (reduivy__Study_Unit__c sun : [SELECT Id, 
                    Name,
                    reduivy__Unit_Code__c
                    FROM reduivy__Study_Unit__c
                    WHERE reduivy__Educational_Institution__c =: educationalInstitutionId
                    WITH USER_MODE
                    ORDER BY Name
                ]) {
                    sunList.add(sun);
                }
            }

            REDU_LightningResponse response = new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(sunList));

            return response;
            
        } catch (QueryException qex) {
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getAcademicTerms(String educationalInstitutionId){
        try {
            
            List<reduivy__Study_Term__c> stmList = new List<reduivy__Study_Term__c>();

            if (String.isNotBlank(educationalInstitutionId)) {
                for (reduivy__Study_Term__c stm : [SELECT Id, 
                    Name, 
                    reduivy__Academic_Year__r.Name
                    FROM reduivy__Study_Term__c
                    WHERE reduivy__Academic_Year__r.reduivy__Educational_Institution__c =: educationalInstitutionId
                    AND RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId()
                    AND (reduivy__End_Date__c >= TODAY OR reduivy__End_Date__c = NULL)
                    AND reduivy__Status__c =: STM_Helper.STATUS_ACTIVE
                    WITH USER_MODE
                    ORDER BY reduivy__Start_Date__c NULLS LAST, Name
                ]) {
                    stmList.add(stm);
                }
            }

            REDU_LightningResponse response = new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(stmList));

            return response;
            
        } catch (QueryException qex) {
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getStudyOfferings(String campusId, String academicTermId, String studyUnitId){
        try {
            
            List<reduivy__Study_Offering__c> sofList = new List<reduivy__Study_Offering__c>();

            if (String.isNotBlank(campusId) || String.isNotBlank(academicTermId) || String.isNotBlank(studyUnitId)) {

                Map<String, Object> sofBindParams = new Map<String, Object>();
                List<String> sofCriteria = new List<String>();

                if(String.isNotBlank(campusId)) {
                    sofBindParams.put('campusId', campusId);
                    sofCriteria.add('reduivy__Campus__c =: campusId');
                }

                if (String.isNotBlank(academicTermId)) {
                    sofBindParams.put('academicTermId', academicTermId);
                    sofCriteria.add('reduivy__Academic_Term__c =: academicTermId');
                }

                if (String.isNotBlank(studyUnitId)) {
                    sofBindParams.put('studyUnitId', studyUnitId);
                    sofCriteria.add('reduivy__Study_Unit__c =: studyUnitId');
                }

                Set<String> sofFields = new Set<String>{
                    'Id',
                    'Name',
                    'reduivy__Code__c'
                };

                String sofSoql = 'SELECT ' + String.join(sofFields, ', ') +
                    ' FROM reduivy__Study_Offering__c ' +
                    ' WHERE ' + String.join(sofCriteria, ' AND ') + 
                    ' ORDER BY reduivy__Start_Date__c NULLS LAST, Name';

                for (reduivy__Study_Offering__c sof : (List<reduivy__Study_Offering__c>) Database.queryWithBinds(sofSoql, sofBindParams, AccessLevel.USER_MODE)) {
                    sofList.add(sof);
                }
            }

            REDU_LightningResponse response = new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(sofList));

            return response;

        } catch (QueryException qex) {
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getStudySessions(String nameFormat, String defaultCriteria, Datetime fromDate, Datetime toDate, String filterValueStr, String studySessionGroupByFields){
        
        try {
            REDU_Logging_UTIL.debug('filterValueStr', filterValueStr);

            REDU_SessionFilterValue_OBJ filterValue = (REDU_SessionFilterValue_OBJ) JSON.deserialize(filterValueStr, REDU_SessionFilterValue_OBJ.class);

            Map<String, Object> responseData = new Map<String, Object>();
            List<reduivy__Study_Session__c> sessions = new List<reduivy__Study_Session__c>();
            Map<Id, List<reduivy__Study_Event__c>> sessionStudyEvents = new Map<Id, List<reduivy__Study_Event__c>>();
            Map<Id, List<reduivy__Study_Session_Time__c>> sessionTimes = new Map<Id, List<reduivy__Study_Session_Time__c>>();

            Map<String, String> nameFields = REDU_StringMerge_UTIL.extractFieldNames(null, nameFormat);

            List<String> groupByFieldsList = new List<String>();
            if (String.isNotBlank(studySessionGroupByFields)) {
                groupByFieldsList.addAll(studySessionGroupByFields.split(REDU_List_UTIL.DELIMITER));
            }

            for (reduivy__Study_Session__c session : REDU_SessionScheduler_UTIL.getStudySessionsByFilter(fromDate, toDate, filterValue, defaultCriteria, nameFields.values(), groupByFieldsList)) {
                sessions.add(session);
                sessionTimes.put(session.Id, new List<reduivy__Study_Session_Time__c>());
                sessionStudyEvents.put(session.Id, new List<reduivy__Study_Event__c>());
            }
            
            if (!sessions.isEmpty()) {
                for(reduivy__Study_Session_Time__c sst: [SELECT Id,
                    Name,
                    reduivy__Day_of_Week__c,
                    reduivy__Recurrence__c,
                    reduivy__Default_Facility__c,
                    reduivy__Start_Date__c,
                    reduivy__End_Date__c,
                    reduivy__Start_Time__c,
                    reduivy__End_Time__c,
                    reduivy__Study_Session__c
                    FROM reduivy__Study_Session_Time__c
                    WHERE reduivy__Study_Session__c IN :sessions
                    WITH USER_MODE
                ]) {
                    sessionTimes.get(sst.reduivy__Study_Session__c).add(sst);
                }

                for (reduivy__Study_Event__c sev : [SELECT Id,
                    Name,
                    reduivy__Study_Session_Time__r.reduivy__Study_Session__c,
                    (
                        SELECT Id, 
                        Name,
                        reduivy__Study_Event__c,
                        reduivy__Relation_Type__c,
                        reduivy__Relation_Name__c,
                        reduivy__Response_Status__c,
                        reduivy__Allow_Conflict__c
                        FROM reduivy__Study_Event_Relations__r

                    )
                    FROM reduivy__Study_Event__c
                    WHERE reduivy__Study_Session_Time__r.reduivy__Study_Session__c IN: sessions
                    AND reduivy__Start__c >=: fromDate
                    AND reduivy__Start__c <=: toDate
                    WITH USER_MODE
                ]) {
                    sessionStudyEvents.get(sev.reduivy__Study_Session_Time__r.reduivy__Study_Session__c).add(sev);
                }
            }

            responseData.put('sessions', sessions);
            responseData.put('sessionTimes', sessionTimes);
            responseData.put('sessionStudyEvents', sessionStudyEvents);

            REDU_LightningResponse response = new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(responseData));

            return response;

        } catch (QueryException qex) {
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getFacultyContacts(String nameFormat, String defaultCriteria, String filterValueStr, String facultyAssociationRoles){

        try {
            REDU_Logging_UTIL.debug('nameFormat', nameFormat);
            REDU_Logging_UTIL.debug('defaultCriteria', defaultCriteria);
            REDU_Logging_UTIL.debug('filterValueStr', filterValueStr);
            REDU_Logging_UTIL.debug('facultyAssociationRoles', facultyAssociationRoles);

            REDU_SessionFilterValue_OBJ filterValue = (REDU_SessionFilterValue_OBJ) JSON.deserialize(filterValueStr, REDU_SessionFilterValue_OBJ.class);

            Id educationalInstitutionId = filterValue.educationalInstitutionId;
            Id campusId = filterValue.campusId;
            Id studyUnitId = filterValue.studyUnitId;
            
            Map<String, String> nameFields = REDU_StringMerge_UTIL.extractFieldNames(null, nameFormat);

            //look for contact association first if educationalInstitutionId is provided
            List<String> casRoles = String.isNotBlank(facultyAssociationRoles) ? facultyAssociationRoles.split(REDU_List_UTIL.DELIMITER) : new List<String>{CAS_Helper.ROLE_FACULTY};

            Set<Id> associatedContactIds = new Set<Id>();
            if (String.isNotBlank(educationalInstitutionId)) {
                for(reduivy__Contact_Association__c cas : [SELECT Id, reduivy__Contact__c 
                    FROM reduivy__Contact_Association__c 
                    WHERE reduivy__Account__c =: educationalInstitutionId 
                    AND reduivy__Role__c IN: casRoles
                    AND reduivy__Status__c =: CAS_Helper.STATUS_ACTIVE
                    WITH USER_MODE
                ]){
                    if (String.isNotBlank(cas.reduivy__Contact__c)) {
                        associatedContactIds.add(cas.reduivy__Contact__c);
                    }
                }
            }

            //Contact fields
            Set<String> contactFields = new Set<String>{
                'Id',
                'Name',
                'AccountId',
                'Account.Name'
            };

            if (!nameFields.isEmpty()) {
                contactFields.addAll(nameFields.values());
            }

            Schema.SObjectType rootSobjectType = Contact.sObjectType;
            Set<String> contactAdditionalFields = new Set<String>();

            for(String field : contactFields) {
                Schema.DescribeFieldResult fieldDescribe = REDU_Datatable_UTIL.getFieldDescribe(field, rootSobjectType);
                if(fieldDescribe.getType() == Schema.DisplayType.REFERENCE) {
                    contactAdditionalFields.add(REDU_Metadata_UTIL.getReferenceFieldForQuery(field, true));
                } else if(fieldDescribe.getType() == Schema.DisplayType.PICKLIST || fieldDescribe.getType() == Schema.DisplayType.MULTIPICKLIST) {
                    contactAdditionalFields.add(REDU_Metadata_UTIL.getPicklistFieldLabelQuery(field));
                }
            }

            contactFields.addAll(contactAdditionalFields);

            //contact availability fields
            Set<String> cavFields = new Set<String>{
                'Id',
                'Name',
                'reduivy__Campus__c',
                'reduivy__Contact__c',
                'reduivy__From_Date__c',
                'reduivy__To_Date__c',
                'reduivy__Monday_From__c',
                'reduivy__Monday_To__c',
                'reduivy__Tuesday_From__c',
                'reduivy__Tuesday_To__c',
                'reduivy__Wednesday_From__c',
                'reduivy__Wednesday_To__c',
                'reduivy__Thursday_From__c',
                'reduivy__Thursday_To__c',
                'reduivy__Friday_From__c',
                'reduivy__Friday_To__c',
                'reduivy__Saturday_From__c',
                'reduivy__Saturday_To__c',
                'reduivy__Sunday_From__c',
                'reduivy__Sunday_To__c'
            };

            //qualified faculty fields
            Set<String> qfaFields = new Set<String>{
                'Id',
                'reduivy__Study_Unit__c', 
                'reduivy__Contact__c'
            };

            Map<String, Object> contactBindParams = filterValue.getContactBindParams();
            List<String> contactQueryBinders = filterValue.getContactQueryBinders();

            Set<String> qfaCriteria = new Set<String>();
            Set<String> cavCriteria = new Set<String>();

            if (!associatedContactIds.isEmpty()) {
                contactBindParams.put('contactIds', associatedContactIds);
                contactQueryBinders.add('Id IN: contactIds');
            }

            //we add the additional bind params for non contact one here so avoid the query preparation above messing up
            //for availability
            contactBindParams.put('cavStatus', CAV_Helper.STATUS_ACTIVE);
            cavCriteria.add('reduivy__Status__c =: cavStatus');

            if (String.isNotBlank(campusId)) {
                contactBindParams.put('campusId', campusId);
                cavCriteria.add('reduivy__Campus__c =: campusId');
            }

            //for qualified faculty
            contactBindParams.put('qfaStatus', QFA_Helper.STATUS_ACTIVE);
            qfaCriteria.add('reduivy__Status__c =: qfaStatus');
            
            if (String.isNotBlank(studyUnitId)) {
                contactBindParams.put('studyUnitId', studyUnitId);
                qfaCriteria.add('reduivy__Study_Unit__c =: studyUnitId');
            }

            String facultySoql = 'SELECT ' + String.join(contactFields, ', ') + ', ' +
                ' (SELECT ' + String.join(qfaFields, ', ') + ' FROM reduivy__Qualified_Faculties__r ' + (!qfaCriteria.isEmpty() ? ' WHERE ' + String.join(qfaCriteria, ' AND ') : '') + ' ), ' +
                ' (SELECT ' + String.join(cavFields, ', ') + ' FROM reduivy__Contact_Availabilities__r ' + (!cavCriteria.isEmpty() ? 'WHERE ' + String.join(cavCriteria, ' AND ') : '') + ' ) ' +
                ' FROM Contact ';

            if (String.isNotBlank(defaultCriteria) || !contactQueryBinders.isEmpty()) {
                facultySoql += ' WHERE ';

                if (String.isNotBlank(defaultCriteria)) {
                    contactQueryBinders.add(defaultCriteria);
                }

                if (!contactQueryBinders.isEmpty()) {
                    facultySoql += String.join(contactQueryBinders, ' AND ');
                }
            }
            
            facultySoql += ' ORDER BY Account.Name, Name ';

            REDU_Logging_UTIL.debug('contactBindParams', contactBindParams);
            REDU_Logging_UTIL.debug('facultySoql', facultySoql);

            List<Contact> contacts = new List<Contact>();
            for (Contact contact : (List<Contact>) Database.queryWithBinds(facultySoql, contactBindParams, AccessLevel.USER_MODE)) {
                contacts.add(contact);
            }

            REDU_LightningResponse response = new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(contacts));

            return response;
            
        } catch (QueryException qex) {
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getFacilities(String nameFormat, String defaultCriteria, String filterValueStr, String selectedFacilityId){

        try {
            REDU_Logging_UTIL.debug('nameFormat', nameFormat);
            REDU_Logging_UTIL.debug('defaultCriteria', defaultCriteria);
            REDU_Logging_UTIL.debug('filterValueStr', filterValueStr);

            REDU_SessionFilterValue_OBJ filterValue = (REDU_SessionFilterValue_OBJ) JSON.deserialize(filterValueStr, REDU_SessionFilterValue_OBJ.class);

            Id educationalInstitutionId = filterValue.educationalInstitutionId;
            Id campusId = filterValue.campusId;

            Map<String, String> nameFields = REDU_StringMerge_UTIL.extractFieldNames(null, nameFormat);

            Set<String> facilityFields = new Set<String>{
                'Id',
                'Name',
                'reduivy__Capacity__c',
                'reduivy__Facility_Type__c',
                'reduivy__Campus__c',
                'reduivy__Campus__r.Name',
                'reduivy__Campus__r.ParentId',
                'reduivy__Campus__r.Parent.Name',
                'reduivy__Parent_Facility__c',
                'reduivy__Parent_Facility__r.Name',
                'reduivy__Parent_Facility__r.reduivy__Parent_Facility__c',
                'reduivy__Parent_Facility__r.reduivy__Parent_Facility__r.Name'
            };

            if (!nameFields.isEmpty()) {
                facilityFields.addAll(nameFields.values());
            }

            Schema.SObjectType rootSobjectType = reduivy__Facility__c.sObjectType;
            Set<String> facilityAdditionalFields = new Set<String>();

            for(String field : facilityFields) {
                Schema.DescribeFieldResult fieldDescribe = REDU_Datatable_UTIL.getFieldDescribe(field, rootSobjectType);
                if(fieldDescribe.getType() == Schema.DisplayType.PICKLIST || fieldDescribe.getType() == Schema.DisplayType.MULTIPICKLIST) {
                    facilityAdditionalFields.add(REDU_Metadata_UTIL.getPicklistFieldLabelQuery(field));
                }
            }

            facilityFields.addAll(facilityAdditionalFields);

            //get facility availability
            Set<String> favFields = new Set<String>{
                'Id',
                'Name',
                'reduivy__Facility__c',
                'reduivy__From_Date__c',
                'reduivy__To_Date__c',
                'reduivy__Monday_From__c',
                'reduivy__Monday_To__c',
                'reduivy__Tuesday_From__c',
                'reduivy__Tuesday_To__c',
                'reduivy__Wednesday_From__c',
                'reduivy__Wednesday_To__c',
                'reduivy__Thursday_From__c',
                'reduivy__Thursday_To__c',
                'reduivy__Friday_From__c',
                'reduivy__Friday_To__c',
                'reduivy__Saturday_From__c',
                'reduivy__Saturday_To__c',
                'reduivy__Sunday_From__c',
                'reduivy__Sunday_To__c'
            };
            
            Map<String, Object> facilityBindParams = filterValue.getFacilityBindParams();
            List<String> facilityQueryBinders = filterValue.getFacilityQueryBinders();
            Set<String> favCriteria = new Set<String>();

            if (String.isNotBlank(educationalInstitutionId)) {
                facilityBindParams.put('educationalInstitutionId', educationalInstitutionId);
                facilityQueryBinders.add('reduivy__Campus__r.ParentId =: educationalInstitutionId');
            }

            if (String.isNotBlank(campusId)) {
                facilityBindParams.put('campusId', campusId);
                facilityQueryBinders.add('reduivy__Campus__c =: campusId');
            }

            //we add the additional bind params for non contact one here so avoid the query preparation above messing up
            //for facility availabilities
            facilityBindParams.put('favStatus', FAV_Helper.STATUS_ACTIVE);
            favCriteria.add('reduivy__Status__c =: favStatus');

            String facilitySoqlBase = 'SELECT ' + String.join(facilityFields, ', ') + ', ' +
                ' (SELECT ' + String.join(favFields, ', ') + ' FROM reduivy__Facility_Availabilities__r ' + (!favCriteria.isEmpty() ? 'WHERE ' + String.join(favCriteria, ' AND ') : '') + ' ) ' +
                ' FROM reduivy__Facility__c ';
            String facilitySoql = facilitySoqlBase;

            if (String.isNotBlank(defaultCriteria) || !facilityQueryBinders.isEmpty()) {
                facilitySoql += ' WHERE ';

                if (String.isNotBlank(defaultCriteria)) {
                    facilityQueryBinders.add(defaultCriteria);
                }

                if (!facilityQueryBinders.isEmpty()) {
                    facilitySoql += String.join(facilityQueryBinders, ' AND ');
                }
            }
            
            facilitySoql += ' ORDER BY reduivy__Campus__r.Name, reduivy__Parent_Facility__r.reduivy__Parent_Facility__r.Name, reduivy__Parent_Facility__r.Name, Name ';

            REDU_Logging_UTIL.debug('facilityBindParams', facilityBindParams);
            REDU_Logging_UTIL.debug('facilitySoql', facilitySoql);

            Boolean querySelectedFacility = String.isNotBlank(selectedFacilityId);
            List<reduivy__Facility__c> facilities = new List<reduivy__Facility__c>();
            for (reduivy__Facility__c facility : (List<reduivy__Facility__c>) Database.queryWithBinds(facilitySoql, facilityBindParams, AccessLevel.USER_MODE)) {
                facilities.add(facility);
                if(String.isNotBlank(selectedFacilityId) && facility.Id == selectedFacilityId) {
                    querySelectedFacility = false;
                }
            }

            //if the selected facility does not match the defaultCriteria, we query the selected facility
            if(querySelectedFacility) {
                String facilitySoqlSelected = facilitySoqlBase + ' WHERE Id = :selectedFacilityId LIMIT 1';
                facilityBindParams.put('selectedFacilityId', selectedFacilityId);
                
                for (reduivy__Facility__c facility : (List<reduivy__Facility__c>) Database.queryWithBinds(facilitySoqlSelected, facilityBindParams, AccessLevel.USER_MODE)) {
                    facilities.add(facility);
                }
            }

            Map<String, Object> responseJson = new Map<String, Object>{
                'facilities' => facilities,
                'selectedFacilityMetDefaultCriteria' => !querySelectedFacility
            };

            REDU_LightningResponse response = new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(responseJson));

            return response;
            
        } catch (QueryException qex) {
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    /**
     * @description Get study session times by study session id
     * @param studySessionId
     * @return REDU_LightningResponse
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getStudySessionTimes(String studySessionId){
        
        try {
            List<reduivy__Study_Session_Time__c> sessionTimes = new List<reduivy__Study_Session_Time__c>();

            if(String.isNotBlank(studySessionId)) {

                Set<String> sstFields = new Set<String>{
                    'Id', 
                    'Name',
                    'reduivy__Day_of_Week__c',
                    REDU_Metadata_UTIL.getPicklistFieldLabelQuery('reduivy__Day_of_Week__c'),
                    'reduivy__Recurrence__c',
                    REDU_Metadata_UTIL.getPicklistFieldLabelQuery('reduivy__Recurrence__c'),
                    'reduivy__Start_Date_Calculated__c',
                    'reduivy__End_Date_Calculated__c',
                    'reduivy__Start_Time__c',
                    'reduivy__End_Time__c'
                };
                
                String sstSoql = 'SELECT ' + String.join(sstFields, ', ') +
                ' FROM reduivy__Study_Session_Time__c ' +
                ' WHERE reduivy__Study_Session__c =: studySessionId ';
                
                Map<String, Object> sstBindParams = new Map<String, Object>();
                sstBindParams.put('studySessionId', studySessionId);
                
                for (reduivy__Study_Session_Time__c ipw : (List<reduivy__Study_Session_Time__c>) Database.queryWithBinds(sstSoql, sstBindParams, AccessLevel.USER_MODE)) {
                    sessionTimes.add(ipw);
                }
                
                SessionTimeSorter sstSorter = new SessionTimeSorter();
                sessionTimes.sort(sstSorter);
            }
            
            REDU_LightningResponse response = new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(sessionTimes));
            return response;
                
        } catch (QueryException qex) {
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }

    }

    
    /**
     * @description Session time sorter, sort by Day of Week + Start Date + Start Time
     */
    public with sharing class SessionTimeSorter implements Comparator<reduivy__Study_Session_Time__c> {

        /**
         * @description Session time sorter, sort by Day of Week + Start Date + Start Time
         * @param sst1 Study session time
         * @param sst2 Study session time
         * @return Integer
         */
        public Integer compare(reduivy__Study_Session_Time__c sst1, reduivy__Study_Session_Time__c sst2) {

            String sst1Key = getDayOfWeek(sst1?.reduivy__Day_of_Week__c) + '_' + sst1?.reduivy__Start_Time__c;
            String sst2Key = getDayOfWeek(sst2?.reduivy__Day_of_Week__c) + '_' + sst2?.reduivy__Start_Time__c;

            return sst1Key.compareTo(sst2Key);
        }

        public Integer getDayOfWeek(String dayOfWeek) {
            if (dayOfWeek.equalsIgnoreCase(SST_Helper.DAY_OF_WEEK_MONDAY)) {
                return 1;
            } else if (dayOfWeek.equalsIgnoreCase(SST_Helper.DAY_OF_WEEK_TUESDAY)) {
                return 2;
            } else if (dayOfWeek.equalsIgnoreCase(SST_Helper.DAY_OF_WEEK_WEDNESDAY)) {
                return 3;
            } else if (dayOfWeek.equalsIgnoreCase(SST_Helper.DAY_OF_WEEK_THURSDAY)) {
                return 4;
            } else if (dayOfWeek.equalsIgnoreCase(SST_Helper.DAY_OF_WEEK_FRIDAY)) {
                return 5;
            } else if (dayOfWeek.equalsIgnoreCase(SST_Helper.DAY_OF_WEEK_SATURDAY)) {
                return 6;
            } else if (dayOfWeek.equalsIgnoreCase(SST_Helper.DAY_OF_WEEK_SUNDAY)){
                return 7;
            }

            return 99;
        }
    }


}