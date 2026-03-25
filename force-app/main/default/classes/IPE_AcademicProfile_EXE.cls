/**
 * @author      WDCi (Lean)
 * @date        Dec 2023
 * @group       Trigger Executable
 * @description This is to link a newly create master individual program enrollment to a new or existing individual academic profile
 * @changehistory
 * ISS-001816 Lean 15-12-2023 - New class
 * ISS-001928 VTan 24-05-2024 - Prevent creation of Individual Academic Profile if IPE status is preview.
 */
public inherited sharing class IPE_AcademicProfile_EXE extends REDU_TriggerExecutable {
    
    /**
     * @description Academic profile name format
     */
    private static final String ACADEMIC_PROFILE_NAME_FORMAT = REDU_AppSetting_UTIL.getIndividualAcademicProfileNameFormat();

    /**
     * @description Academic profile generation type
     */
    private static final String ACADEMIC_PROFILE_GEN_TYPE = REDU_AppSetting_UTIL.getIndividualAcademicProfileGenerationType();

    /**
     * @description Individual program enrollment master record type id
     */
    private static final Id IPE_MASTER_RTID = IPE_Helper.getMasterEnrollmentRecordTypeId();

    private static final Integer NAME_FIELD_LENGTH = Schema.SObjectType.reduivy__Individual_Academic_Profile__c.fields.Name.getLength();

	/**
     * @description This is to link a newly create individual program enrollment to a new or existing individual academic profile
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeBeforeInsert(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {
        
        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.ADMIN)) {
            
            List<String> ipePreviewStatusList = IPE_Helper.getPreviewStatuses();
            List<reduivy__Individual_Program_Enrollment__c> workingIpes = new List<reduivy__Individual_Program_Enrollment__c>();

            for (reduivy__Individual_Program_Enrollment__c ipe : (List<reduivy__Individual_Program_Enrollment__c>) newList) {
                if (ipe.RecordTypeId == IPE_MASTER_RTID &&
                    String.isNotBlank(ipe.reduivy__Contact__c) &&
                    String.isBlank(ipe.reduivy__Individual_Academic_Profile__c) &&
                    !ipePreviewStatusList.contains(ipe.reduivy__Enrollment_Status__c)
                ) {
                    workingIpes.add(ipe);
                }
            }

            setAcademicProfile(workingIpes);
        }
    }

    /**
     * @description This is to link an updated individual program enrollment to a new or existing individual academic profile when the individual academic profile field is unset
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeBeforeUpdate(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {
        
        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.ADMIN)) {
            
            List<reduivy__Individual_Program_Enrollment__c> workingIpes = new List<reduivy__Individual_Program_Enrollment__c>();
            List<reduivy__Individual_Program_Enrollment__c> oldIpeList = (List<reduivy__Individual_Program_Enrollment__c>) oldList;
            List<String> ipePreviewStatusList = IPE_Helper.getPreviewStatuses();

            for (reduivy__Individual_Program_Enrollment__c ipe : (List<reduivy__Individual_Program_Enrollment__c>) newList) {
                reduivy__Individual_Program_Enrollment__c oldIpe = (reduivy__Individual_Program_Enrollment__c) oldMap.get(ipe.Id);
                if (ipe.RecordTypeId == IPE_MASTER_RTID &&
                    String.isNotBlank(ipe.reduivy__Contact__c) && 
                    String.isBlank(ipe.reduivy__Individual_Academic_Profile__c) &&
                    (ipe.reduivy__Individual_Academic_Profile__c != oldIpe.reduivy__Individual_Academic_Profile__c ||
                    (!ipePreviewStatusList.contains(ipe.reduivy__Enrollment_Status__c) &&
                    ipePreviewStatusList.contains(oldIpe.reduivy__Enrollment_Status__c)))
                ) {
                    workingIpes.add(ipe);
                }
            }

            setAcademicProfile(workingIpes);
        }
    }

    /**
     * @description Set the individual program enrollment with individual academic profile
     * @param ipeList List of individual program enrollment
     * @return void
     */
    private void setAcademicProfile(List<reduivy__Individual_Program_Enrollment__c> ipeList) {

        if (!ipeList.isEmpty()) {
            Set<Id> contactIds = new Set<Id>();
            for (reduivy__Individual_Program_Enrollment__c ipe : ipeList) {
                if (String.isNotBlank(ipe.reduivy__Contact__c)) {
                    contactIds.add(ipe.reduivy__Contact__c);
                }
            }
            
            //get the merge fields for record name
            Map<String, String> mergeFields = REDU_StringMerge_UTIL.extractFieldNames(null, ACADEMIC_PROFILE_NAME_FORMAT);

            if (ACADEMIC_PROFILE_GEN_TYPE == IPF_Helper.PROFILE_GEN_TYPE_BYIPE) {
                // for IPE type, we will always create a new profile
                List<reduivy__Individual_Academic_Profile__c> newAcadmicProfiles = new List<reduivy__Individual_Academic_Profile__c>();
                for (reduivy__Individual_Program_Enrollment__c ipe : ipeList) {

                    reduivy__Individual_Academic_Profile__c newIpf = initNewProfile(ipe, mergeFields, null, null);

                    newAcadmicProfiles.add(newIpf);
                }

                REDU_Database_UTIL.doInsert(newAcadmicProfiles, ipeList, false);
                
                // gen type by ipe, we will set according to the sequence of the records in the list
                Integer counter = 0;

                for (reduivy__Individual_Program_Enrollment__c ipe : ipeList) {
                    ipe.reduivy__Individual_Academic_Profile__c = newAcadmicProfiles.get(counter).Id;

                    counter ++;
                }

            } else {
                // for identifier type, we need the identifier mapping
                Map<String, String> identifierMapping = REDU_AppSetting_UTIL.getIndividualAcademicProfileIdentifierMapping();
                Map<String, Schema.DescribeFieldResult> ipfDfrsMap = REDU_Metadata_UTIL.describeSObjectFields('reduivy__Individual_Academic_Profile__c', identifierMapping.values());

                if (identifierMapping.isEmpty()) {
                    throw new REDU_ApplicationException(Label.Missing_Academic_Profile_Identifier_Mapping);
                }

                // get the existing individual academic profile for the students
                Set<String> ipfFields = new Set<String>{'Id', 'reduivy__Contact__c'};
                ipfFields.addAll(identifierMapping.values());

                Map<String, Object> ipfBindParams = new Map<String, Object>();
                ipfBindParams.put('contactIds', contactIds);
                ipfBindParams.put('status', IPF_Helper.STATUS_ACTIVE);

                String ipfQuery = 'SELECT ' + String.join(ipfFields, ', ') +
                    ' FROM reduivy__Individual_Academic_Profile__c ' +
                    ' WHERE reduivy__Contact__c IN: contactIds ' +
                    ' AND reduivy__Status__c =: status ' + 
                    ' ORDER BY CreatedDate ';

                Map<String, reduivy__Individual_Academic_Profile__c> ipfsByIdentifier = new Map<String, reduivy__Individual_Academic_Profile__c>();
                for (reduivy__Individual_Academic_Profile__c existingIpf : (List<reduivy__Individual_Academic_Profile__c>) Database.queryWithBinds(ipfQuery, ipfBindParams, AccessLevel.USER_MODE)) {
                    
                    String identifierKey = getIdentifierKey(existingIpf, identifierMapping, false);
                    ipfsByIdentifier.put(identifierKey, existingIpf);
                }

                Map<String, List<reduivy__Individual_Program_Enrollment__c>> ipesByIdentifier = new Map<String, List<reduivy__Individual_Program_Enrollment__c>>();
                Map<String, reduivy__Individual_Academic_Profile__c> newAcadmicProfilesMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
                for (reduivy__Individual_Program_Enrollment__c ipe : ipeList) {

                    String identifierKey = getIdentifierKey(ipe, identifierMapping, true);
                    
                    // try to match the individual academic profile based on the mapping
                    if (!ipfsByIdentifier.containsKey(identifierKey)) {
                        
                        // create a new individual academic profile if couldn't find one
                        reduivy__Individual_Academic_Profile__c newIpf = initNewProfile(ipe, mergeFields, identifierMapping, ipfDfrsMap);

                        ipfsByIdentifier.put(identifierKey, newIpf);

                        newAcadmicProfilesMap.put(identifierKey, newIpf);
                    }

                    if (ipesByIdentifier.containsKey(identifierKey)) {
                        ipesByIdentifier.get(identifierKey).add(ipe);
                    } else {
                        ipesByIdentifier.put(identifierKey, new List<reduivy__Individual_Program_Enrollment__c>{ipe});
                    }
                }

                // create the new individual academic profile
                REDU_Database_UTIL.doInsert(newAcadmicProfilesMap, ipesByIdentifier, false);

                // Associate the ipe to ipf
                for (String identifierKey : ipesByIdentifier.keySet()) {
                    if (ipfsByIdentifier.containsKey(identifierKey)) {
                        for (reduivy__Individual_Program_Enrollment__c ipe : ipesByIdentifier.get(identifierKey)) {
                            ipe.reduivy__Individual_Academic_Profile__c = ipfsByIdentifier.get(identifierKey).Id;
                        }
                    }
                }
            }
        }
    }

    /**
     * @description Return the identifier key
     * @param record SObject to be used to generate the key
     * @param identifierMapping Identifier mapping
     * @param useSourceField Use field name from map key or map value to genereate the key
     */
    private String getIdentifierKey(SObject record, Map<String, String> identifierMapping, Boolean useSourceField) {

        // compile a list of identifier mapping field value and make them as a key, the key is used to identify an individual academic profile record
        List<Object> identifierValues = new List<Object>{record.get('reduivy__Contact__c')};

        for (String identifierSourceField : identifierMapping.keySet()) {
            if (useSourceField) {
                identifierValues.add(record.get(identifierSourceField));
            } else {
                identifierValues.add(record.get(identifierMapping.get(identifierSourceField)));
            }
        }
        
        return String.join(identifierValues, '_');
    }

    /**
     * @description Return new individual academic profile
     * @param ipe Individual program enrollment
     * @param nameMergeFields Merge field map for record name
     * @param identifierMapping Individual academic profile identifier mapping
     * @param ipfDfrsMap Individual academic profile identifier fields describe
     */
    private reduivy__Individual_Academic_Profile__c initNewProfile(reduivy__Individual_Program_Enrollment__c ipe, Map<String, String> nameMergeFields, Map<String, String> identifierMapping, Map<String, Schema.DescribeFieldResult> ipfDfrsMap) {

        reduivy__Individual_Academic_Profile__c newIpf = new reduivy__Individual_Academic_Profile__c();
        newIpf.Name = REDU_StringMerge_UTIL.mergeValues(ipe, nameMergeFields, ACADEMIC_PROFILE_NAME_FORMAT, NAME_FIELD_LENGTH);
        newIpf.reduivy__Contact__c = ipe.reduivy__Contact__c;
        newIpf.reduivy__Status__c = IPF_Helper.STATUS_ACTIVE;

        // The master IPE will always be the latest primary by default
        newIpf.reduivy__Primary__c = true;
        
        if (identifierMapping != null && ipfDfrsMap != null) {
            // set the additional fields based on the identifier mapping
            for (String identifierSourceField : identifierMapping.keySet()) {
                String identifierTargetField = identifierMapping.get(identifierSourceField);

                if (ipfDfrsMap.get(identifierTargetField).isCreateable()) {
                    newIpf.put(identifierTargetField, ipe.get(identifierSourceField));
                }
            }
        }

        return newIpf;
    }
}