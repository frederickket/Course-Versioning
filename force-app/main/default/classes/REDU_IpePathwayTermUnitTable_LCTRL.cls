/**
 * @author      WDCi (Lean)
 * @date        Oct 2023
 * @group       Enrollment wizard
 * @description Controller to handle child groups and child units for a parent group individual plan structure
 * @changehistory
 * ISS-001752 09-10-2023 Lean - new class
 * ISS-001911 27-03-2024 VTan - Update retry statuses for enrollment wizard
 * ISS-001979 19-07-2024 Sueanne - to open pre-enrollment for study unit when its pre-requisite that going to complete
 * ISS-002066 04-09-2024 Sueanne - update to retain the ien if the pathway status is completed
 * ISS-002120 30-09-2024 Lean - List the enrolled IEN for user mode = student
 * ISS-002155 30-12-2024 XW - consider fields for custom reqtype
 * ISS-002230 22-01-2025 XW - get picklist value label if field type is picklist & allow configurable requirement desc field
 * ISS-002330 20-03-2025 XW - show study offering translation name if found
 * ISS-002345 21-03-2025 XiRouh - updated getIndividualPlanStructureUnits's paramter to receive master ipe id and updated soql to query reduivy__Individual_Plan_Structure__c based on reduivy__Master_Individual_Program_Enrollment_Id__c field
 * ISS-002231 25-03-2025 Lean - Added deferred status
 * ISS-002336 24-03-2024 Lean - Added missed/failed unit
 * ISS-002365 27-03-2025 Lean - Track historical ien
 * ISS-002381 11-04-2025 XiRouh - update sofNameWithTranslation to use the translated field only if it is not null; otherwise, use the original record name
 * ISS-002373 14-04-2025 XiRouh - Added getFinalGradeReleasedStatuses()
 * ISS-002410 14-04-2025 XiRouh - Replaced isSet with != null
 * ISS-002374 14-04-2025 XiRouh - Added getInternalGradeReleasedStatuses()
 * ISS-002400 30-04-2025 XiRouh - Updated unitStudyOfferings to also query IEN related study offerings, even if the study offering is not active. Updated the logic to assign ipsWrapper.sof, applying different logic for completed and ongoing IPW
 * ISS-002445 06-05-2025 XiRouh - Updated the method for determining whether the study unit is isEnrolledInOtherTerm, updated to use academicTermIen to decide whether to allow reenrollment in the unit, updated the condition for including the study unit in the list.
 * ISS-002442 07-05-2025 XiRouh - Added reduivy__Academic_Term__r.reduivy__Display_Name__c field for query
 * ISS-002483 20-05-2025 XiRouh - Updated to handle the completed but failed re-enrollment issue; refer to the issue number in the code for details
 * ISS-002486 10-06-2025 XiRouh - Introduce New IEN Status: Completed – Failed; refer to the issue number in the code for details
 * ISS-002514 10-06-2025 XW - Updated upsertEnrollment to accept enrollment status to change to
 * ISS-002541 14-07-2025 XiRouh - Updated upsertEnrollment() to check for an existing placeholder individual enrollment before creating a new one
 * ISS-002495 29-09-2025 XW - Support record value translation from Translation Mapping mdt
 * ISS-002743 09-12-2025 XiRouh - Updated getIndividualPlanStructureUnits to receive the master IPF ID as a parameter and to only check the IEN associated with the passed master IPF ID. Updated upsertEnrollment() so that the newly created enrollment identifies and references the appropriate Individual Academic Profile based on the one from the master Individual Program Enrollment
 */
public with sharing class REDU_IpePathwayTermUnitTable_LCTRL {
    
    /**
     * @description response param - childUnitsIps
     */
    public static final String CHILDUNITSIPS_PARAM = 'childUnitsIps';

    /**
     * @description response param - unitTableColumns
     */
    public static final String UNITTABLECOLUMNS_PARAM = 'unitTableColumns';

    /**
     * @description response param - ipe
     */
    public static final String IPE_PARAM = 'ipe';

    /**
     * @description response param - masterIpe
     */
    public static final String MASTERIPE_PARAM = 'masterIpe';

    /**
     * @description response param - sce
     */
    public static final String SCE_PARAM = 'sce';

    /**
     * @description response param - ipw
     */
    public static final String IPW_PARAM = 'ipw';

    public static final String SUN_TRANSLATION_INFO_PARAM = 'sunTranslationInfo';
    public static final String SOF_TRANSLATION_INFO_PARAM = 'sofTranslationInfo';
    public static final String SPS_TRANSLATION_INFO_PARAM = 'spsTranslationInfo';

    /**
     * @description IEN Open statuses
     */
    public static final List<String> IEN_OPEN_STATUSES = IEN_Helper.getOpenStatuses();

    /**
     * @description Find the related child unit records for the current group individual plan structure and study term
     * @param individualPeId
     * @param individualPlanStructureGroupId
     * @param individualPathwayId
     * @param titleField
     * @param tableFields A list of field API name for the enrollment wizard table e.g., reduivy__Study_Unit__c.Name;reduivy__Study_Unit__c.reduivy__Unit_Code__c
     * @return REDU_LightningResponse
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getIndividualPlanStructureUnits(Id masterIndividualPeId, Id individualPeId, Id individualPlanStructureGroupId, Id individualPathwayId, Id campusId, String tableFields, List<Id> restrictedToUnits, String userMode, String unitListingMode, String customFilters, String missedFailedUnitListingOption, String language, String cacheIdx){

        try {

            Map<String, Object> responseData = new Map<String, Object>();

            Id ipsUnitRtId = IPS_Helper.getUnitRecordTypeId();
            Id ipsGroupRtId = IPS_Helper.getGroupRecordTypeId();

            Id spsUnitRtId = SPS_Helper.getUnitRecordTypeId();
            Id spsGroupRtId = SPS_Helper.getGroupRecordTypeId();

            //query individual pathway
            reduivy__Individual_Pathway__c ipw = [SELECT Id,
                reduivy__Status__c,
                reduivy__Term_Number__c,
                reduivy__Academic_Term__c,
                reduivy__Academic_Term__r.reduivy__Enable_Cohort_Enrollment__c,
                reduivy__Academic_Term__r.reduivy__Unit_Enrollment_Setting__c,
                reduivy__Individual_Program_Enrollment__c,
                reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c,
                reduivy__Individual_Academic_Progress__c,
                reduivy__Individual_Academic_Progress__r.reduivy__Individual_Academic_Profile__c
                FROM reduivy__Individual_Pathway__c
                WHERE Id =: individualPathwayId
                WITH USER_MODE
            ];

            Id masterIndividualAcademicProfileId = ipw?.reduivy__Individual_Academic_Progress__r?.reduivy__Individual_Academic_Profile__c;

            if (String.isBlank(masterIndividualAcademicProfileId)) {
                String ipfFieldLabel = SObjectType.reduivy__Individual_Academic_Progress__c.fields.reduivy__Individual_Academic_Profile__c.getLabel();
                String recordUrl = REDU_OrganizationInfo_UTIL.getDomainUrl() + ipw?.reduivy__Individual_Academic_Progress__c;
                String errorMsg = String.format(Label.Missing_Info_For_Record, new List<String>{ipfFieldLabel, IPR_Helper.getObjectLabel(), recordUrl});
                
                throw new REDU_ApplicationException(errorMsg);
            }
            
            List<reduivy__Individual_Plan_Structure__c> childIpsUnits = new List<reduivy__Individual_Plan_Structure__c>();
            Map<Id, List<reduivy__Individual_Plan_Structure__c>> childIpsUnitsBySpsId = new Map<Id, List<reduivy__Individual_Plan_Structure__c>>();
            
            reduivy__Individual_Plan_Structure__c currentGroupIps;
            Map<Id, List<reduivy__Individual_Plan_Structure__c>> unitIpsBySun = new Map<Id, List<reduivy__Individual_Plan_Structure__c>>();

            String stmTranslationFieldForName = STM_Helper.getTranslationFieldNameForName();

            //query all the existing individual plan structures
            Set<String> ipsFields = new Set<String>{
                'Id',
                'Name',
                'RecordTypeId',
                'reduivy__Allow_Pre_Enrollment__c',
                'reduivy__Credits__c',
                'reduivy__Sequence__c',
                'reduivy__Category__c',
                REDU_Metadata_UTIL.getPicklistFieldLabelQuery('reduivy__Category__c'),
                'reduivy__Hidden__c',
                'reduivy__Requirement_Met__c',
                'reduivy__Status__c',
                REDU_Metadata_UTIL.getPicklistFieldLabelQuery('reduivy__Status__c'),
                'reduivy__Target_Unit_Id__c',
                'reduivy__Alternate_Study_Unit__c',
                'reduivy__Alternate_Study_Unit__r.reduivy__Requirement_Logic__c',
                'reduivy__Alternate_Study_Unit__r.reduivy__Requirement_Description__c',
                'reduivy__Individual_Enrollment__c',
                'reduivy__Individual_Enrollment__r.reduivy__Academic_Term_Id__c',
                'reduivy__Individual_Enrollment__r.reduivy__Attempt_Number__c',
                'reduivy__Individual_Enrollment__r.reduivy__Census_Date__c',
                'reduivy__Individual_Enrollment__r.reduivy__Enrollment_Status__c',
                REDU_Metadata_UTIL.getPicklistFieldLabelQuery('reduivy__Individual_Enrollment__r.reduivy__Enrollment_Status__c'),
                'reduivy__Individual_Enrollment__r.reduivy__Study_Offering__c',
                'reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Academic_Term__r.Name',
                'reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Academic_Term__r.reduivy__Display_Name__c', //ISS-002442
                'reduivy__Individual_Enrollment__r.reduivy__Grade_Result__c',
                'reduivy__Individual_Enrollment__r.reduivy__Target_Unit_Id__c',
                'reduivy__Study_Plan_Structure__c',
                'reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c',
                'reduivy__Study_Plan_Structure__r.reduivy__Requirement_Logic__c',
                'reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__r.reduivy__Requirement_Logic__c',
                'reduivy__Parent_Plan_Structure__c',
                'reduivy__Parent_Plan_Structure__r.reduivy__Study_Plan_Structure__c',
                'reduivy__Individual_Program_Enrollment__c',
                'reduivy__Master_Individual_Program_Enrollment_Id__c', //ISS-002345
                'reduivy__Individual_Enrollment__r.reduivy__Grade_Release_Status__c', //ISS-002402
                'reduivy__Individual_Enrollment__r.reduivy__Credit_Transfer_Received__c' //ISS-002400 - To check if the ien is from credit transfer
            };

            Set<String> ienFields = new Set<String>{
                'reduivy__Academic_Term_Id__c',
                'reduivy__Attempt_Number__c',
                'reduivy__Census_Date__c',
                'reduivy__Enrollment_Status__c',
                REDU_Metadata_UTIL.getPicklistFieldLabelQuery('reduivy__Enrollment_Status__c'),
                'reduivy__Study_Offering__c',
                'reduivy__Study_Offering__r.reduivy__Academic_Term__r.Name',
                'reduivy__Study_Offering__r.reduivy__Academic_Term__r.reduivy__Display_Name__c', //ISS-002442
                'reduivy__Grade_Result__c',
                'reduivy__Target_Unit_Id__c',
                'reduivy__Grade_Release_Status__c'
            };

            if (String.isNotBlank(stmTranslationFieldForName)) {
                ipsFields.add('reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Academic_Term__r.' + stmTranslationFieldForName);
                ienFields.add('reduivy__Study_Offering__r.reduivy__Academic_Term__r.' + stmTranslationFieldForName);
            }

            Map<String, Object> ipsBindParams = new Map<String, Object>{
                'masterIndividualPeId' => masterIndividualPeId //ISS-002345
            };

            String ipsSoql = 'SELECT ' + String.join(ipsFields, ', ') + 
            ' FROM reduivy__Individual_Plan_Structure__c ' +
            ' WHERE reduivy__Master_Individual_Program_Enrollment_Id__c =: masterIndividualPeId ' + //ISS-002345
            ' ORDER BY reduivy__Sequence_Key__c NULLS LAST ';

            for (reduivy__Individual_Plan_Structure__c ips : (List<reduivy__Individual_Plan_Structure__c>) Database.queryWithBinds(ipsSoql, ipsBindParams, AccessLevel.USER_MODE)) {
                if(ips.reduivy__Individual_Program_Enrollment__c == individualPeId) { //ISS-002345
                    if (ips.RecordTypeId == ipsGroupRtId && ips.Id == individualPlanStructureGroupId) {
                    
                        //get current group info
                        currentGroupIps = ips;
    
                    } else if (ips.RecordTypeId == ipsUnitRtId) {
    
                        if (ips.reduivy__Parent_Plan_Structure__c == individualPlanStructureGroupId) {
                            //get the unit individual plan structure records
                            if (String.isNotBlank(ips.reduivy__Study_Plan_Structure__c)) {
                                if (childIpsUnitsBySpsId.containsKey(ips.reduivy__Study_Plan_Structure__c)) {
                                    childIpsUnitsBySpsId.get(ips.reduivy__Study_Plan_Structure__c).add(ips);
                                } else {
                                    childIpsUnitsBySpsId.put(ips.reduivy__Study_Plan_Structure__c, new List<reduivy__Individual_Plan_Structure__c>{ips});
                                }
                            }
    
                            childIpsUnits.add(ips);
                        }
    
                        Id sunId = IPS_Helper.getTargetUnitId(ips, ips.reduivy__Study_Plan_Structure__r);
    
                        if (unitIpsBySun.containsKey(sunId)) {
                            unitIpsBySun.get(sunId).add(ips);
                        } else {
                            unitIpsBySun.put(sunId, new List<reduivy__Individual_Plan_Structure__c>{ips});
                        }
                    }
                } else if (ips.reduivy__Individual_Program_Enrollment__c != individualPeId && ips.RecordTypeId == ipsUnitRtId) {
                    //we need to collect all unit IPS that belongs from the same parents so that we can use them for requirement met check
                    Id sunId = IPS_Helper.getTargetUnitId(ips, ips.reduivy__Study_Plan_Structure__r);
    
                    if (unitIpsBySun.containsKey(sunId)) {
                        unitIpsBySun.get(sunId).add(ips);
                    } else {
                        unitIpsBySun.put(sunId, new List<reduivy__Individual_Plan_Structure__c>{ips});
                    }
                }
            }

            //query historical individual enrollments so that we can report it correctly based on the term
            Map<String, reduivy__Individual_Enrollment__c> latestIenByUnitTerm = new Map<String, reduivy__Individual_Enrollment__c>();
            List<String> activeStatuses = new List<String>();
            activeStatuses.addAll(IEN_Helper.getNonEnrollableStatuses());
            activeStatuses.addAll(IEN_Helper.getWaitlistedStatuses());
            activeStatuses.addAll(IEN_Helper.getEnrollmentRequestedStatuses());
            activeStatuses.addAll(IEN_Helper.getCompletedFailStatuses()); //ISS-002486 - We also need to query the completed fail IEN, as it should appear in the completed term and the term in which it was failed

            Map<String, Object> ienBindParams = new Map<String, Object>();
            ienBindParams.put('sunIds', unitIpsBySun.keySet());
            ienBindParams.put('contactId', ipw.reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c);
            ienBindParams.put('ienStudentRtId', IEN_Helper.getStudentRecordTypeId());
            ienBindParams.put('ienEnrollmentType', IEN_Helper.ENROLLMENT_TYPE_PROGRAM);
            ienBindParams.put('activeStatuses', activeStatuses);
            ienBindParams.put('ipfId', masterIndividualAcademicProfileId);

            String ienSoql = 'SELECT ' + String.join(ienFields, ', ') +
                ' FROM reduivy__Individual_Enrollment__c ' +
                ' WHERE reduivy__Target_Unit_Id__c IN: sunIds ' + 
                ' AND reduivy__Contact__c =: contactId ' +
                ' AND RecordTypeId =: ienStudentRtId ' +
                ' AND reduivy__Enrollment_Status__c IN: activeStatuses ' +
                ' AND reduivy__Enrollment_Type__c =: ienEnrollmentType ' +
                ' AND reduivy__Individual_Academic_Profile__c =: ipfId ' +
                ' ORDER BY reduivy__Attempt_Number__c DESC NULLS LAST, reduivy__Start_Date__c DESC NULLS LAST, CreatedDate DESC ';
            
            Set<Id> ienStudyOfferingIds = new Set<Id>(); //ISS-002400 - To get the study offerings id that the enrolled or completed ien related to
            for (reduivy__Individual_Enrollment__c ien : (List<reduivy__Individual_Enrollment__c>) Database.queryWithBinds(ienSoql, ienBindParams, AccessLevel.USER_MODE)) {
                String ienByTermKey = ien.reduivy__Target_Unit_Id__c + '_' + ien.reduivy__Academic_Term_Id__c;
                if (!latestIenByUnitTerm.containsKey(ienByTermKey)) {
                    latestIenByUnitTerm.put(ienByTermKey, ien);
                }

                if(!String.isBlank(ien.reduivy__Study_Offering__c)) {
                    ienStudyOfferingIds.add(ien.reduivy__Study_Offering__c);
                }
            }

            //prepare unit enrollment table column metadata
            List<REDU_DynamicFieldValue_OBJ> tableColumnMetadata = new List<REDU_DynamicFieldValue_OBJ>();

            Set<String> sunFields = new Set<String>();
            Set<String> spsFields = new Set<String>();
            Set<String> sofFields = new Set<String>();

            Map<String, Set<String>> objectFieldsSet = new Map<String, Set<String>>{
                'reduivy__Study_Unit__c' => sunFields,
                'reduivy__Study_Plan_Structure__c' => spsFields,
                'reduivy__Study_Offering__c' => sofFields
            };

            Map<String, Map<String, Schema.SObjectField>> objectFieldsMap = new Map<String, Map<String, Schema.SObjectField>>{
                'reduivy__Study_Unit__c' => Schema.SObjectType.reduivy__Study_Unit__c.fields.getMap(),
                'reduivy__Study_Plan_Structure__c' => Schema.SObjectType.reduivy__Study_Plan_Structure__c.fields.getMap(),
                'reduivy__Study_Offering__c' => Schema.SObjectType.reduivy__Study_Offering__c.fields.getMap()
            };

            //we only check for 1 object here, normally the sps and sof should have the CurrencyIsoCode field too
            if (REDU_SObject_UTIL.hasCurrencyIsoCode(Schema.reduivy__Study_Unit__c.getSObjectType())) {
                objectFieldsSet.get('reduivy__Study_Unit__c').add(REDU_SObject_UTIL.CURRENCYISOCODE_FIELD);
                objectFieldsSet.get('reduivy__Study_Plan_Structure__c').add(REDU_SObject_UTIL.CURRENCYISOCODE_FIELD);
                objectFieldsSet.get('reduivy__Study_Offering__c').add(REDU_SObject_UTIL.CURRENCYISOCODE_FIELD);
            }

            if (String.isNotBlank(tableFields)) {

                for (String tf : tableFields.split(';')) {
                    if (String.isNotBlank(tf) && tf.contains('.')) {
                        List<String> tfInfo = tf.split('\\.');
                        REDU_Logging_UTIL.debugJsonString('tfInfo', tfInfo);

                        String objectName = tfInfo.get(0);
                        String fieldName = tfInfo.get(1);
                        String fieldNameLowerCase = fieldName.toLowerCase();
                        String label;
                        String fieldType;

                        if (objectFieldsSet.containsKey(objectName) && objectFieldsMap.containsKey(objectName)) {
                            if (objectFieldsMap.get(objectName).containsKey(fieldNameLowerCase)) {

                                objectFieldsSet.get(objectName).add(fieldName);

                                DescribeFieldResult dfr = objectFieldsMap.get(objectName).get(fieldNameLowerCase).getDescribe();
                                label = dfr.getLabel();
                                fieldType = dfr.getType().name();

                                REDU_DynamicFieldValue_OBJ dfv = new REDU_DynamicFieldValue_OBJ(objectName, fieldName, label, null, fieldType, null, dfr.isCreateable(), dfr.isUpdateable());
                                tableColumnMetadata.add(dfv);
                            }
                        }
                        
                    }
                }
            }

            //If it doesn't have child group, we assume that we need to display the related unit individual plan structure or unit study plan structure
            //To list the unit, we need to join the list from both individual program enrollment and study plan
            List<REDU_IndividualPlanStructure_OBJ> eligibleUnitsIps = new List<REDU_IndividualPlanStructure_OBJ>();

            //sps fields
            Set<String> spsQueryFields = new Set<String>{
                'Id',
                'Name',
                'RecordTypeId',
                'reduivy__Allow_Pre_Enrollment__c',
                'reduivy__Category__c',
                'reduivy__Credits__c',
                'reduivy__Description__c',
                'reduivy__Hide_in_Enrollment__c',
                'reduivy__Sequence__c',
                'reduivy__Study_Unit__c',
                'reduivy__Requirement_Logic__c',
                'reduivy__Requirement_Description__c'
            };

            spsQueryFields.addAll(objectFieldsSet.get('reduivy__Study_Plan_Structure__c'));

            if (String.isNotBlank(currentGroupIps.reduivy__Study_Plan_Structure__c)) {

                //sps params
                Map<String, Object> spsBindParams = new Map<String, Object>{
                    'parentSpsId' => currentGroupIps.reduivy__Study_Plan_Structure__c,
                    'parentSpsRtId' => spsGroupRtId,
                    'spsRtId' => spsUnitRtId
                };

                //sps query
                String spsQuery = 'SELECT ' + String.join(spsQueryFields, ', ') + 
                    ' FROM reduivy__Study_Plan_Structure__c ' +
                    ' WHERE reduivy__Parent_Study_Plan_Structure__c =: parentSpsId ' +
                    ' AND reduivy__Parent_Study_Plan_Structure__r.RecordTypeId =: parentSpsRtId ' +
                    ' AND RecordTypeId =: spsRtId ' +
                    ' ORDER BY reduivy__Sequence_Key__c ASC NULLS LAST ';

                List<String> ienRetryStatuses = IEN_Helper.getRetryStatuses();
                List<String> ienWithdrawnStatuses = IEN_Helper.getWithdrawnStatuses();
                List<String> ienNonEnrollableStatuses = IEN_Helper.getNonEnrollableStatuses();
                List<String> ienCompletedFailStatuses = IEN_Helper.getCompletedFailStatuses();

                //if the group has a study plan structure defined, we will list the units from the study plan + current individual plan structure for the group
                for (reduivy__Study_Plan_Structure__c unitSps : (List<reduivy__Study_Plan_Structure__c>) Database.queryWithBinds(spsQuery, spsBindParams, AccessLevel.USER_MODE)) {
                    if (childIpsUnitsBySpsId.containsKey(unitSps.Id)) {
                        //use the existing unit ips if found
                        for (reduivy__Individual_Plan_Structure__c existingIps : childIpsUnitsBySpsId.get(unitSps.Id)) {
                            Id sunId = IPS_Helper.getTargetUnitId(existingIps, unitSps);
                            
                            if (restrictedToUnits != null && 
                                !restrictedToUnits.isEmpty() && 
                                !restrictedToUnits.contains(sunId) && 
                                !restrictedToUnits.contains(existingIps.Id)
                            ) {
                                continue;
                            }

                            //try to find the ien that matches the term so that we can display the right one in the enrollment wizard
                            //this is because we can't rely on the ien that link to ips because that is the latest one which could be different from the term specific ien
                            String ienByTermKey = sunId + '_' + ipw.reduivy__Academic_Term__c;
                            reduivy__Individual_Enrollment__c academicTermIen = latestIenByUnitTerm.containsKey(ienByTermKey) ? latestIenByUnitTerm.get(ienByTermKey) : null;

                            REDU_IndividualPlanStructure_OBJ ipsWrapper = new REDU_IndividualPlanStructure_OBJ();
                            ipsWrapper.ips = existingIps;
                            ipsWrapper.sps = unitSps;
                            ipsWrapper.academicTermIen = academicTermIen;
                            ipsWrapper.ipsCurrentIen = existingIps?.reduivy__Individual_Enrollment__r;

                            if (ipsWrapper.ipsCurrentIen != null) {
                                //we unset the data to reduce the payload back to lwc since we have stored it in the ipsCurrentIen
                                existingIps.reduivy__Individual_Enrollment__r = null;
                                existingIps.reduivy__Individual_Enrollment__c = null;
                            }

                            if (
                                (String.isNotBlank(ipsWrapper?.academicTermIen?.reduivy__Academic_Term_Id__c) && ipsWrapper?.academicTermIen?.reduivy__Academic_Term_Id__c != ipw.reduivy__Academic_Term__c) || 
                                (//String.isBlank(ipsWrapper?.academicTermIen?.reduivy__Academic_Term_Id__c) && //ISS-002445 - Commented out this line because there could be a scenario where academicTermIen is not blank, but ipsCurrentIen is already in a non-enrollable status, and both IENs are different
                                String.isNotBlank(ipsWrapper.ipsCurrentIen?.reduivy__Academic_Term_Id__c) 
                                && ipsWrapper.ipsCurrentIen?.reduivy__Academic_Term_Id__c != ipw.reduivy__Academic_Term__c 
                                && ienNonEnrollableStatuses.contains(ipsWrapper.ipsCurrentIen?.reduivy__Enrollment_Status__c)) //ISS-002445 - Added a check to determine if the ipsCurrentIen enrollment status is in non enrollable statuses, because if ipsCurrentIen is in a status like 'Withdrawn', it is not considered enrolled in another term, and the user should be allowed to enroll in the study unit for the viewing term
                            ) {
                                ipsWrapper.isEnrolledInOtherTerm = true;
                            }

                            //we to allow them to enroll to the unit again
                            if (ipw.reduivy__Status__c != IPW_Helper.STATUS_COMPLETED) {

                                //ISS-002445 - Ori code is causing an error where, when the existingIps is in an ipsRetryStatuses status (but not failed, such as withdrawn), the academicTermIen is being removed, causing the wizard to be unable to find the academicTermIen if it is not the same as the linked ips IEN
                                if (
                                    ipsWrapper?.academicTermIen == null && (
                                        (
                                            ienRetryStatuses.contains(ipsWrapper?.ipsCurrentIen?.reduivy__Enrollment_Status__c)
                                        ) ||
                                        (
                                            ienCompletedFailStatuses.contains(ipsWrapper?.ipsCurrentIen?.reduivy__Enrollment_Status__c) && ipsWrapper.isEnrolledInOtherTerm
                                        ) //ISS-002483 - If academicTermIen is null, we use ipsCurrentIen to determine whether re-enrollment should be allowed
                                        //ISS-002486 - If the ipsCurrentIen is in a completed fail status, we will remove it from ipsCurrentIen and isEnrolledInOtherTerm so that the student can re-enroll in the course
                                    )
                                ) {
                                    ipsWrapper.ipsCurrentIen = null;
                                    ipsWrapper.isEnrolledInOtherTerm = false;

                                } else if (ienWithdrawnStatuses.contains(ipsWrapper?.academicTermIen?.reduivy__Enrollment_Status__c)) { 
                                    //ISS-002483 - If academicTermIen is not null and has a status of 'withdrawn', reenrollment is allowed.
                                    //if the status is 'failed', 'in progress', or any other status, no removal is performed, as reenrollment in the viewing term should not be allowed when academicTermIen exists and is not 'withdrawn'
                                    ipsWrapper.academicTermIen = null;
                                }
                            }

                            eligibleUnitsIps.add(ipsWrapper);
                        }
                    } else {
                        //skip the unit sps if we are restricting the unit listing in pathway mode
                        if (restrictedToUnits != null && 
                            !restrictedToUnits.isEmpty() && 
                            !restrictedToUnits.contains(unitSps.reduivy__Study_Unit__c)
                        ) {
                            continue;
                        }
                        
                        //create new unit ips if it doesn't exist
                        REDU_IndividualPlanStructure_OBJ ipsWrapper = new REDU_IndividualPlanStructure_OBJ();
                        ipsWrapper.ips = IPS_Helper.initUnitPlanStructure(individualPeId, individualPlanStructureGroupId, null, unitSps);
                        ipsWrapper.sps = unitSps;

                        eligibleUnitsIps.add(ipsWrapper);
                    }
                }

                for (reduivy__Individual_Plan_Structure__c existingIps : childIpsUnits) {
                    if (String.isBlank(existingIps.reduivy__Study_Plan_Structure__c)) {
                        //if the exisitng ips doesn't have study plan structure linked, we will append it to the end of the list
                        REDU_IndividualPlanStructure_OBJ ipsWrapper = new REDU_IndividualPlanStructure_OBJ();
                        ipsWrapper.ips = existingIps;

                        eligibleUnitsIps.add(ipsWrapper);
                    }
                }
            } else {
                //if the group doesn't have study plan structure defined, we just list the existing unit individual plan structure as it is
                //sps params
                Map<String, Object> spsBindParams = new Map<String, Object>{
                    'spsIds' => childIpsUnitsBySpsId.keySet(),
                    'spsRtId' => spsUnitRtId
                };

                //sps query
                String spsQuery = 'SELECT ' + String.join(spsQueryFields, ', ') + 
                    ' FROM reduivy__Study_Plan_Structure__c ' +
                    ' WHERE Id IN: spsIds ' +
                    ' AND RecordTypeId =: spsRtId ' +
                    ' ORDER BY reduivy__Sequence_Key__c ASC NULLS LAST ';

                //query the sps so that we can get the same data as above
                Map<Id, reduivy__Study_Plan_Structure__c> unitSpsMap = new Map<Id, reduivy__Study_Plan_Structure__c>((List<reduivy__Study_Plan_Structure__c>)Database.queryWithBinds(spsQuery, spsBindParams, AccessLevel.USER_MODE));
                
                for (reduivy__Individual_Plan_Structure__c existingIpsWithoutParentSps : childIpsUnits) {

                    REDU_IndividualPlanStructure_OBJ ipsWrapper = new REDU_IndividualPlanStructure_OBJ();
                    ipsWrapper.ips = existingIpsWithoutParentSps;

                    if (String.isNotBlank(existingIpsWithoutParentSps.reduivy__Study_Plan_Structure__c) && unitSpsMap.containsKey(existingIpsWithoutParentSps.reduivy__Study_Plan_Structure__c)) {
                        ipsWrapper.sps = unitSpsMap.get(existingIpsWithoutParentSps.reduivy__Study_Plan_Structure__c);
                    }

                    eligibleUnitsIps.add(ipsWrapper);
                }
            }

            //get study unit id for querying study unit and study offerings
            Set<Id> studyUnitIds = new Set<Id>();
            Map<Id, reduivy__Study_Plan_Structure__c> spsMap = new Map<Id, reduivy__Study_Plan_Structure__c>();
            List<reduivy__Individual_Plan_Structure__c> ipsList = new List<reduivy__Individual_Plan_Structure__c>();

            for (REDU_IndividualPlanStructure_OBJ ipsWrapper : eligibleUnitsIps) {
                Id sunId = IPS_Helper.getTargetUnitId(ipsWrapper.ips, ipsWrapper.sps);

                if (String.isNotBlank(sunId)) {
                    studyUnitIds.add(sunId);
                }

                if (ipsWrapper.sps != null) {
                    spsMap.put(ipsWrapper.sps.Id, ipsWrapper.sps);
                }

                if (ipsWrapper.ips != null) {
                    ipsList.add(ipsWrapper.ips);
                }
            }
            
            //get sps translation info
            Map<String, Object> spsTranslationInfo = REDU_TranslationManager.getTranslationInfo(SPS_Helper.getApiName(), spsMap.keySet(), spsQueryFields, language);

            //get the study plan unit requirement and individual plan structure unit requirement
            Map<Id, List<reduivy__Study_Plan_Unit_Requirement__c>> spursBySps = REDU_StudyUnitRequirement_UTIL.getUnitSpsRequirements(spsMap.values()); 
            Map<Id, List<reduivy__Individual_Plan_Unit_Requirement__c>> ipursByIps = REDU_StudyUnitRequirement_UTIL.getUnitIpsRequirements(ipsList);

            //ISS-002155 moved to here so that we can get spurs 
            //query individual program enrollment to identify the master enrollment
            Set<String> ipeFieldsToQuery = new Set<String> {
                'Id',
                'reduivy__Credits_Earned__c',
                'reduivy__Contact__c',
                'reduivy__Cohort_ID__c',
                'reduivy__Class_Standing__c',
                'reduivy__Class_Year__c',
                'reduivy__Eligible_To_Enroll__c',
                'reduivy__Individual_Academic_Profile__c',
                'reduivy__Study_Plan__c',
                'reduivy__Study_Pathway__c',
                'reduivy__Master_Enrollment__c',
                'reduivy__Master_Enrollment__r.reduivy__Credits_Earned__c',
                'reduivy__Master_Enrollment__r.reduivy__Contact__c',
                'reduivy__Master_Enrollment__r.reduivy__Cohort_ID__c',
                'reduivy__Master_Enrollment__r.reduivy__Class_Standing__c',
                'reduivy__Master_Enrollment__r.reduivy__Class_Year__c',
                'reduivy__Master_Enrollment__r.reduivy__Individual_Academic_Profile__c',
                'reduivy__Master_Enrollment__r.reduivy__Eligible_To_Enroll__c',
                'reduivy__Master_Enrollment__r.reduivy__Study_Plan__c',
                'reduivy__Master_Enrollment__r.reduivy__Study_Pathway__c'
            };

            for(Id spsId : spursBySps.keySet()) {
                for(reduivy__Study_Plan_Unit_Requirement__c spur : spursBySps.get(spsId)) {
                    if(String.isNotBlank(spur.reduivy__Field_Name__c) && spur.reduivy__Requirement_Type__c == SPR_Helper.REQTYPE_CUSTOM) {
                        ipeFieldsToQuery.add(spur.reduivy__Field_Name__c);
                        ipeFieldsToQuery.add('reduivy__Master_Enrollment__r.' + spur.reduivy__Field_Name__c);
                    }
                }
            }

            for(Id ipsId : ipursByIps.keySet()) {
                for(reduivy__Individual_Plan_Unit_Requirement__c ipur : ipursByIps.get(ipsId)) {
                    if(String.isNotBlank(ipur.reduivy__Field_Name__c) && ipur.reduivy__Requirement_Type__c == IUR_Helper.REQTYPE_CUSTOM) {
                        ipeFieldsToQuery.add(ipur.reduivy__Field_Name__c);
                    }
                }
            }

            REDU_Logging_UTIL.debug('ipeFieldsToQuery', String.join(ipeFieldsToQuery, ','));
            String ipeQuery = 'SELECT ' + String.join(ipeFieldsToQuery, ',') + 
                        ' FROM reduivy__Individual_Program_Enrollment__c ' +
                        ' WHERE Id = :individualPeId ';
            Map<String, Object> ipeBindMap = new Map<String, Object> {'individualPeId' => individualPeId};
            reduivy__Individual_Program_Enrollment__c ipe = Database.queryWithBinds(ipeQuery, ipeBindMap, AccessLevel.USER_MODE);

            reduivy__Individual_Program_Enrollment__c masterIpe;

            if (String.isNotBlank(ipe.reduivy__Master_Enrollment__c)) {
                masterIpe = ipe.reduivy__Master_Enrollment__r;
            } else {
                masterIpe = ipe;
            }

            //get enrollmentSetting value from academic term
            String enrollmentSetting;
            if(String.isNotBlank(ipw.reduivy__Academic_Term__r.reduivy__Unit_Enrollment_Setting__c)){
                enrollmentSetting = ipw.reduivy__Academic_Term__r.reduivy__Unit_Enrollment_Setting__c;
            }

            reduivy__Study_Cohort_Enrollment__c sce;
            //get the study cohort enrollment if the setting is enabled
            if (String.isNotBlank(ipw.reduivy__Academic_Term__c) 
                && ipw.reduivy__Academic_Term__r.reduivy__Enable_Cohort_Enrollment__c
                && masterIpe != null
            ) {
                sce = SCE_Helper.getStudyCohortEnrollment(ipw.reduivy__Academic_Term__c, masterIpe.reduivy__Cohort_ID__c, masterIpe.reduivy__Class_Standing__c, masterIpe.reduivy__Class_Year__c);

                //overwrite the wnrollmentSetting if having value in sce
                if(sce != null && String.isNotBlank(sce.reduivy__Unit_Enrollment_Setting__c)){
                    enrollmentSetting = sce.reduivy__Unit_Enrollment_Setting__c;
                }
            }

            //sun fields
            Set<String> sunQueryFields = new Set<String>{
                'Id',
                'Name',
                'reduivy__Unit_Code__c',
                'reduivy__Requirement_Logic__c',
                'reduivy__Requirement_Description__c',
                SUN_Helper.getTranslationFieldNameForName()
            };

            sunQueryFields.addAll(objectFieldsSet.get('reduivy__Study_Unit__c'));
            
            Map<String, Object> sunTranslationInfo;
            Map<Id, reduivy__Study_Unit__c> studyUnitsMap;
            if(REDU_AppSetting_UTIL.isRecordValueTranslationEnabled()) {
                sunTranslationInfo = REDU_TranslationManager.getTranslationInfo(SUN_Helper.getApiName(), studyUnitIds, sunQueryFields, language);
                studyUnitsMap = new Map<Id, reduivy__Study_Unit__c> (
                    (List<reduivy__Study_Unit__c>) sunTranslationInfo.get(REDU_TranslationManager.RECORDS_PARAM)
                );
            } else {
                sunTranslationInfo = new Map<String, Object>();

                Map<String, Object> sunBindParams = new Map<String, Object>{
                    'sunIds' => studyUnitIds
                };

                //sun query
                String sunQuery = 'SELECT ' + String.join(sunQueryFields, ', ') +
                    ' FROM reduivy__Study_Unit__c ' +
                    ' WHERE Id IN: sunIds ';

                studyUnitsMap = new Map<Id, reduivy__Study_Unit__c>(
                    (List<reduivy__Study_Unit__c>) Database.queryWithBinds(sunQuery, sunBindParams, AccessLevel.USER_MODE)
                );
            }
            
            String sofTranslationFieldName = SOF_Helper.getTranslationFieldNameForName();
            
            //sof fields
            Set<String> sofQueryFields = new Set<String>{
                'Id',
                'Name',
                'reduivy__Study_Unit__c',
                'reduivy__Available_Places__c',
                'reduivy__Enable_Self_Enrollment__c',
                'reduivy__Enable_Waitlist__c',
                'reduivy__Census_Date_Calculated__c',
                'reduivy__Enrollment_Close_Date_Calculated__c',
                'reduivy__Enrollment_Open_Date_Calculated__c',
                'reduivy__Pre_enrollment_Open_Date_Calculated__c',
                'reduivy__Status__c',
                'reduivy__Unlimited_Places__c'
            };

            sofQueryFields.addAll(objectFieldsSet.get('reduivy__Study_Offering__c'));
            sofQueryFields.add(sofTranslationFieldName);

            List<String> sofPositiveStatuses = SOF_Helper.getPositiveStatuses();

            //sof params
            Map<String, Object> sofBindParams = new Map<String, Object>{
                'sunIds' => studyUnitIds,
                'academicTermId' => ipw.reduivy__Academic_Term__c,
                'statuses' => sofPositiveStatuses,
                'ienStudyOfferingIds' => ienStudyOfferingIds
            };

            //sof query
            String sofQuery = 'SELECT ' + String.join(sofQueryFields, ', ') + 
                ' FROM reduivy__Study_Offering__c ' + 
                ' WHERE reduivy__Study_Unit__c IN: sunIds ' + 
                ' AND reduivy__Academic_Term__c =: academicTermId '+
                ' AND (reduivy__Status__c IN: statuses OR Id IN: ienStudyOfferingIds) '; //ISS-002400 - Added ienStudyOfferingIds as we need to query study offerings that are not active but are enrolled or completed in the IPW term

            if (String.isNotBlank(campusId)) {
                sofBindParams.put('campusId', campusId);
                
                sofQuery += ' AND reduivy__Campus__c =: campusId ';
            }

            //sof params (ISS-002400-for ien related study offerings - to be used in completed ipw)
            Map<String, Object> sofBindParamsForIenSof = new Map<String, Object>{
                'sofIds' => ienStudyOfferingIds
            };

            //sof query (ISS-002400-for ien related study offerings - to be used in completed ipw)
            String sofQueryForIenSof = 'SELECT ' + String.join(sofQueryFields, ', ') + 
                ' FROM reduivy__Study_Offering__c ' + 
                ' WHERE Id IN: sofIds ';

            if (String.isNotBlank(customFilters)) {
                List<REDU_CustomFilter_OBJ> customFilterConfigs = (List<REDU_CustomFilter_OBJ>) JSON.deserialize(customFilters, List<REDU_CustomFilter_OBJ>.class);
                for (REDU_CustomFilter_OBJ cf : customFilterConfigs) {
                    if (cf.isValid()) {
                        sofBindParams.putAll(cf.getBindParams());
                        sofQuery += ' AND ' + cf.getQueryBinder();
                    }
                }
            }

            REDU_Logging_UTIL.debug('sofBindParams', sofBindParams);
            REDU_Logging_UTIL.debug('sofBindParamsForIenSof', sofBindParamsForIenSof);

            Map<Id, List<reduivy__Study_Offering__c>> unitStudyOfferings = new Map<Id, List<reduivy__Study_Offering__c>>();
            Set<Id> allSofIds = new Set<Id>();

            for (reduivy__Study_Offering__c sof : (List<reduivy__Study_Offering__c>) Database.queryWithBinds(sofQuery, sofBindParams, AccessLevel.USER_MODE)) {
                if (unitStudyOfferings.containsKey(sof.reduivy__Study_Unit__c)) {
                    unitStudyOfferings.get(sof.reduivy__Study_Unit__c).add(sof);
                } else {
                    unitStudyOfferings.put(sof.reduivy__Study_Unit__c, new List<reduivy__Study_Offering__c>{sof});
                }
                allSofIds.add(sof.Id);
            }

            //ISS-002400-for ien related study offerings - to be used in completed ipw
            List<reduivy__Study_Offering__c> ienStudyOfferings = new List<reduivy__Study_Offering__c>();

            for(reduivy__Study_Offering__c ienSof : (List<reduivy__Study_Offering__c>) Database.queryWithBinds(sofQueryForIenSof, sofBindParamsForIenSof, AccessLevel.USER_MODE)) {
                ienStudyOfferings.add(ienSof);
                allSofIds.add(ienSof.Id);
            }

            //get translation info for study offering
            Map<String, Object> sofTranslationInfo = REDU_TranslationManager.getTranslationInfo(SOF_Helper.getApiName(), allSofIds, sofQueryFields, language);

            //ISS-002336
            Set<Id> missedFailedStudyUnits = new Set<Id>();
            if (String.isNotBlank(missedFailedUnitListingOption) && ipw.reduivy__Status__c != IPW_Helper.STATUS_COMPLETED) {
                missedFailedStudyUnits = REDU_IpePathways_LCTRL.getMissedFailedStudyUnits(ipe.Id, ipe.reduivy__Study_Plan__c, masterIpe.reduivy__Study_Pathway__c, userMode, ipw.reduivy__Term_Number__c, missedFailedUnitListingOption);
            }

            List<REDU_IndividualPlanStructure_OBJ> unitIpsWrapperList = new List<REDU_IndividualPlanStructure_OBJ>();
            Integer counter = 0;

            List<String> ipsPositiveStatuses = new List<String>();
            ipsPositiveStatuses.addAll(IPS_Helper.getUnitFailedStatuses());
            ipsPositiveStatuses.addAll(IPS_Helper.getUnitNonEnrollableStatuses());

            for (REDU_IndividualPlanStructure_OBJ ipsWrapper : eligibleUnitsIps) {

                if (String.isBlank(userMode) || userMode != USR_Helper.USER_MODE_ADMIN) {
                    if (ipsWrapper.ips != null && 
                        ((String.isNotBlank(ipsWrapper.ips.Id) && ipsWrapper.ips.reduivy__Hidden__c) || //for existing ips, we check against the formula field
                        (String.isBlank(ipsWrapper.ips.Id) && ipsWrapper.ips.reduivy__Hide_in_Enrollment__c)) //for new ips, we check against the checkbox as formula field is not available yet
                    ) {
                        continue;
                    }
                }

                Id sunId = IPS_Helper.getTargetUnitId(ipsWrapper.ips, ipsWrapper.sps);

                if (studyUnitsMap.containsKey(sunId)) {
                    if ((
                            (ipw.reduivy__Status__c == IPW_Helper.STATUS_CURRENT || ipw.reduivy__Status__c == IPW_Helper.STATUS_FUTURE) 
                            && (!unitStudyOfferings.containsKey(sunId) && ipsWrapper.ipsCurrentIen.reduivy__Credit_Transfer_Received__c == false)
                        ) ||
                        (
                            ipw.reduivy__Status__c == IPW_Helper.STATUS_COMPLETED && 
                            (!ipsPositiveStatuses.contains(ipsWrapper.ips.reduivy__Status__c) || String.isBlank(ipsWrapper.ips.reduivy__Status__c)) //ISS-002445 - Added the check for ipsPositiveStatuses, if the viewing IPW is completed, it should only show the units that are failed, completed, or in progress
                        )
                    ) {
                        continue;
                    }

                    //ISS-002336 missed failed unit indicator
                    ipsWrapper.isMissedFailed = missedFailedStudyUnits.contains(sunId);

                    reduivy__Study_Unit__c studyUnit = studyUnitsMap.get(sunId);

                    //set the additional info for the wrapper
                    ipsWrapper.seq = counter;
                    ipsWrapper.sun = studyUnit;

                    Map<String, String> requirementInfo = IPS_Helper.getRequirementInfo(ipsWrapper.sps, ipsWrapper.sun, ipsWrapper.ips.reduivy__Alternate_Study_Unit__r);
                    ipsWrapper.requirementLogic = requirementInfo.get(IPS_Helper.REQINFO_LOGIC);
                    ipsWrapper.requirementDescription = requirementInfo.get(IPS_Helper.REQINFO_DESC);

                    if (String.isBlank(ipsWrapper.ips.Id)) {
                        //for newly initiated unit ips, we use sps to get spur
                        List<reduivy__Study_Plan_Unit_Requirement__c> spurs = ipsWrapper.sps != null && spursBySps.containsKey(ipsWrapper.sps.Id) ? spursBySps.get(ipsWrapper.sps.Id) : new List<reduivy__Study_Plan_Unit_Requirement__c>();
                        if(!ipsWrapper.ips.reduivy__Allow_Pre_Enrollment__c){

                            // if (!ipsWrapper.ips.reduivy__Requirement_Met__c) {
                                ipsWrapper.ips.reduivy__Requirement_Met__c = REDU_StudyUnitRequirement_UTIL.isRequirementMet(ipsWrapper.requirementLogic, masterIpe, spurs, unitIpsBySun, null, ipw.reduivy__Academic_Term__c);
                            // } 
                            
                            if (!ipsWrapper.ips.reduivy__Requirement_Met__c && enrollmentSetting == STM_Helper.UNIT_ENROLLMENT_ALLOW_PREREQUISITE) {
                                ipsWrapper.byPassReqMet = REDU_StudyUnitRequirement_UTIL.isRequirementMet(ipsWrapper.requirementLogic, masterIpe, spurs, unitIpsBySun, enrollmentSetting, ipw.reduivy__Academic_Term__c);
                            }
                        }

                    } else {
                        //for existing unit ips, we use ips to get ipur
                        List<reduivy__Individual_Plan_Unit_Requirement__c> ipurs = ipursByIps.containsKey(ipsWrapper.ips.Id) ? ipursByIps.get(ipsWrapper.ips.Id) : new List<reduivy__Individual_Plan_Unit_Requirement__c>();

                        //construct spur by ipur
                        List<reduivy__Study_Plan_Unit_Requirement__c> spurList = new List<reduivy__Study_Plan_Unit_Requirement__c>();
                        for(reduivy__Individual_Plan_Unit_Requirement__c ipur : ipurs){
                            reduivy__Study_Plan_Unit_Requirement__c spur = IUR_Helper.convertIurToSpr(ipur.reduivy__Individual_Plan_Unit__c, ipur.reduivy__Required_Study_Unit__c, ipur.reduivy__Requirement_ID__c, ipur.reduivy__Requirement_Type__c, ipur.reduivy__Field_Name__c, ipur.reduivy__Field_Matching_Operator__c, ipur.reduivy__Field_Matching_Value__c, ipur.reduivy__Credits__c);
                            spurList.add(spur);
                        }

                        if(!ipsWrapper.ips.reduivy__Allow_Pre_Enrollment__c){
                            List<reduivy__Study_Plan_Unit_Requirement__c> spurs = ipsWrapper.sps != null && spursBySps.containsKey(ipsWrapper.sps.Id) ? spursBySps.get(ipsWrapper.sps.Id) : new List<reduivy__Study_Plan_Unit_Requirement__c>();

                            // if (!ipsWrapper.ips.reduivy__Requirement_Met__c) {
                                ipsWrapper.ips.reduivy__Requirement_Met__c = REDU_StudyUnitRequirement_UTIL.isRequirementMet(ipsWrapper.requirementLogic, masterIpe, spurList, unitIpsBySun, null, ipw.reduivy__Academic_Term__c);
                            // } 
                            
                            if (!ipsWrapper.ips.reduivy__Requirement_Met__c && enrollmentSetting == STM_Helper.UNIT_ENROLLMENT_ALLOW_PREREQUISITE) {
                                ipsWrapper.byPassReqMet = REDU_StudyUnitRequirement_UTIL.isRequirementMet(ipsWrapper.requirementLogic, masterIpe, spurs, unitIpsBySun, enrollmentSetting, ipw.reduivy__Academic_Term__c);
                            }
                        }
                        
                    }

                    counter ++;

                    List<reduivy__Study_Offering__c> availableSofs = unitStudyOfferings.containsKey(sunId) ? unitStudyOfferings.get(sunId) : new List<reduivy__Study_Offering__c>();

                    //skip the ips listing if no available sof
                    if(ipw.reduivy__Status__c == IPW_Helper.STATUS_COMPLETED && !ienStudyOfferings.isEmpty()) { //ISS-002400 - If the IPW is in a completed status, we will only loop through the study offerings that have an IEN and display them if the study offering matches the study offering linked with the academicTermIen
                        for (reduivy__Study_Offering__c sof : ienStudyOfferings) {
                            if(ipsWrapper?.academicTermIen != null && sof.Id == ipsWrapper?.academicTermIen?.reduivy__Study_Offering__c) {
                                ipsWrapper.sof = sof;
                            } else if (ipsWrapper?.academicTermIen == null && ipsWrapper?.ipsCurrentIen != null && sof.Id == ipsWrapper?.ipsCurrentIen?.reduivy__Study_Offering__c) {
                                ipsWrapper.sof = sof;
                            }
                        }
                        
                        unitIpsWrapperList.add(ipsWrapper);
                    } else if (ipw.reduivy__Status__c != IPW_Helper.STATUS_COMPLETED && !availableSofs.isEmpty()) {
                        List<reduivy__Study_Offering__c> enrollableSofs = new List<reduivy__Study_Offering__c>();

                        if (userMode == USR_Helper.USER_MODE_ADMIN ) {
                            //for admin mode, list all sof
                            enrollableSofs = availableSofs;
                        } else {
                            //for non-admin mode, list the self enrollment enabled or the one that is already enrolled (by admin)
                            for (reduivy__Study_Offering__c availSof : availableSofs) {
                                if (availSof.reduivy__Enable_Self_Enrollment__c || 
                                    (IPS_Helper.getUnitInProgressStatuses().contains(ipsWrapper?.ips?.reduivy__Status__c) && availSof.Id == ipsWrapper?.academicTermIen?.reduivy__Study_Offering__c)
                                ) {
                                    enrollableSofs.add(availSof);
                                }
                            }
                        }

                        //ISS-002400 - We have also updated this issue to query the IEN-related study offerings. This part has been updated to check if the study offering is in a positive status; if not, it must match the academicTermIen study offering in order to be displayed in the list
                        if (enrollableSofs.size() == 1) {
                            if(sofPositiveStatuses.contains(enrollableSofs.get(0).reduivy__Status__c) || 
                                (
                                    !sofPositiveStatuses.contains(enrollableSofs.get(0).reduivy__Status__c) 
                                    && ipsWrapper?.academicTermIen != null 
                                    && ipsWrapper?.academicTermIen?.reduivy__Study_Offering__c == enrollableSofs.get(0).Id
                                )
                            ) {
                                ipsWrapper.sof = enrollableSofs.get(0);
                            }
                        } else {
                            for (reduivy__Study_Offering__c sof : enrollableSofs) {
                                if(sofPositiveStatuses.contains(sof.reduivy__Status__c) || 
                                    (
                                        !sofPositiveStatuses.contains(sof.reduivy__Status__c) 
                                        && ipsWrapper?.academicTermIen != null 
                                        && ipsWrapper?.academicTermIen?.reduivy__Study_Offering__c == sof.Id
                                    )
                                ) {
                                    //initiate new option wrapper for the ips wrapper based on study offering
                                    REDU_IndividualPlanStructure_OBJ optionIpsWrapper = new REDU_IndividualPlanStructure_OBJ();
                                    optionIpsWrapper.seq = counter;
                                    optionIpsWrapper.sun = ipsWrapper.sun;
                                    optionIpsWrapper.ips = ipsWrapper.ips;
                                    optionIpsWrapper.sps = ipsWrapper.sps;
                                    optionIpsWrapper.sof = sof;
                                    optionIpsWrapper.academicTermIen = ipsWrapper.academicTermIen;
                                    optionIpsWrapper.ipsCurrentIen = ipsWrapper.ipsCurrentIen;
                                    optionIpsWrapper.isEnrolledInOtherTerm = ipsWrapper.isEnrolledInOtherTerm;
                                    optionIpsWrapper.isMissedFailed = ipsWrapper.isMissedFailed;
                                    optionIpsWrapper.byPassReqMet = ipsWrapper.byPassReqMet;
                                    
                                    counter ++;
                                    ipsWrapper.options.add(optionIpsWrapper);
                                } 
                            }
                        }

                        unitIpsWrapperList.add(ipsWrapper);
                    } else {
                        unitIpsWrapperList.add(ipsWrapper);
                    }
                }
            }

            Map<String, Object> translationInfo = new Map<String, Object> {
                SUN_Helper.getApiName() => sunTranslationInfo,
                SPS_Helper.getApiName() => spsTranslationInfo,
                SOF_Helper.getApiName() => sofTranslationInfo
            };

            responseData.put(IPE_PARAM, ipe);
            responseData.put(MASTERIPE_PARAM, masterIpe);
            responseData.put(SCE_PARAM, sce);
            responseData.put(CHILDUNITSIPS_PARAM, unitIpsWrapperList);
            responseData.put(UNITTABLECOLUMNS_PARAM, tableColumnMetadata);
            responseData.put(IPW_PARAM, ipw);
            responseData.put(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM, translationInfo);

            return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(responseData, true));

        } catch (QueryException qex) {
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    /**
     * @description Return study offering status map by type
     * @return REDU_LightningResponse
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getStudyOfferingStatuses(){

        try {
            Map<String, List<String>> sofStatusMap = new Map<String, List<String>>{
                SOF_Helper.STATUS_TYPE_NOTSTARTED => SOF_Helper.getNotStartedStatuses(),
                SOF_Helper.STATUS_TYPE_PREENROLLMENT_OPENED => SOF_Helper.getPreEnrollmentOpenedStatuses(),
                SOF_Helper.STATUS_TYPE_ENROLLMENT_OPENED => SOF_Helper.getEnrollmentOpenedStatuses(),
                SOF_Helper.STATUS_TYPE_ENROLLMENT_CLOSED => SOF_Helper.getEnrollmentClosedStatuses(),
                SOF_Helper.STATUS_TYPE_RUNNING => SOF_Helper.getRunningStatuses()
            };

            for (String key : sofStatusMap.keySet()) {
                if (sofStatusMap.get(key).isEmpty()) {
                    String errorMsg = String.format(Label.Missing_Object_Record, new List<String>{SObjectType.reduivy__Study_Offering_Status_Config__mdt.getLabel() + '.' + key});
                    throw new REDU_ApplicationException(errorMsg);
                }
            }

            return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(sofStatusMap));

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    /**
     * @description Return individual plan structure status map by type
     * @return REDU_LightningResponse
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getIndividualPlanStructureUnitStatuses(){

        try {
            Map<String, List<String>> ipsStatusMap = new Map<String, List<String>>{
                IPS_Helper.STATUS_TYPE_NOTSTARTED => IPS_Helper.getUnitNotStartedStatuses(),
                IPS_Helper.STATUS_TYPE_INPROGRESS => IPS_Helper.getUnitInProgressStatuses(),
                IPS_Helper.STATUS_TYPE_COMPLETED => IPS_Helper.getUnitCompletedStatuses(),
                IPS_Helper.STATUS_TYPE_FAILED => IPS_Helper.getUnitFailedStatuses(),
                IPS_Helper.STATUS_TYPE_WITHDRAWN => IPS_Helper.getUnitWithdrawnStatuses(),
                IPS_Helper.STATUS_TYPE_DROPPED => IPS_Helper.getUnitDroppedStatuses(),
                IPS_Helper.STATUS_TYPE_NONENROLLABLE => IPS_Helper.getUnitNonEnrollableStatuses(),
                IPS_Helper.STATUS_TYPE_DEFERRED => IPS_Helper.getUnitDeferredStatuses()
            };

            for (String key : ipsStatusMap.keySet()) {
                if (ipsStatusMap.get(key).isEmpty()) {
                    String errorMsg = String.format(Label.Missing_Object_Record, new List<String>{SObjectType.reduivy__IdvPs_Status_Config__mdt.getLabel() + '.' + key});
                    throw new REDU_ApplicationException(errorMsg);
                }
            }

            return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(ipsStatusMap));
            
        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    /**
     * @description Return individual enrollment's enrollment status map by type
     * @return REDU_LightningResponse
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getIndividualEnrollmentStatuses(){

        try {
            Map<String, List<String>> ienStatusMap = new Map<String, List<String>>{
                IEN_Helper.STATUS_TYPE_OPEN => IEN_Helper.getOpenStatuses(),
                IEN_Helper.STATUS_TYPE_ENROLLMENT_REQUESTED => IEN_Helper.getEnrollmentRequestedStatuses(),
                IEN_Helper.STATUS_TYPE_INPROGRESS => IEN_Helper.getInProgressStatuses(),
                IEN_Helper.STATUS_TYPE_COMPLETED => IEN_Helper.getCompletedStatuses(),
                IEN_Helper.STATUS_TYPE_COMPLETED_FAIL => IEN_Helper.getCompletedFailStatuses(), //ISS-002486 - New Status
                IEN_Helper.STATUS_TYPE_WAITLISTED => IEN_Helper.getWaitlistedStatuses(),
                IEN_Helper.STATUS_TYPE_DROPPED => IEN_Helper.getDroppedStatuses(),
                IEN_Helper.STATUS_TYPE_WITHDRAWN_REQUESTED => IEN_Helper.getWithdrawalRequestedStatuses(),
                IEN_Helper.STATUS_TYPE_WITHDRAWN => IEN_Helper.getWithdrawnStatuses(),
                IEN_Helper.STATUS_TYPE_WITHDRAWN_FAIL => IEN_Helper.getWithdrawnFailStatuses(),
                IEN_Helper.STATUS_TYPE_NONENROLLABLE => IEN_Helper.getNonEnrollableStatuses(),
                IEN_Helper.STATUS_TYPE_DEFERRED => IEN_Helper.getDeferredStatuses()
            };

            for (String key : ienStatusMap.keySet()) {
                if (ienStatusMap.get(key).isEmpty()) {
                    String errorMsg = String.format(Label.Missing_Object_Record, new List<String>{SObjectType.reduivy__IdvEn_Enrollment_Status_Config__mdt.getLabel() + '.' + key});
                    throw new REDU_ApplicationException(errorMsg);
                }
            }

            return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(ienStatusMap));
            
        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    /**
     * @description Return internal grade released statuses 
     * @return REDU_LightningResponse
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getInternalGradeReleasedStatuses(){

        try {
            List<String> internalGradeReleasedStatuses = IEN_Helper.getInternalGradeReleasedStatuses();

            return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(internalGradeReleasedStatuses));
            
        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    /**
     * @description Return final grade released statuses 
     * @return REDU_LightningResponse
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getFinalGradeReleasedStatuses(){

        try {
            List<String> finalGradeReleasedStatuses = IEN_Helper.getFinalGradeReleasedStatuses();

            return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(finalGradeReleasedStatuses));
            
        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    /**
     * @description Insert or update the individual plan structure unit and individual enrollment record based on the enrollment action.
     * @param ipsRecord REDU_IndividualPlanStructure_OBJ record
     * @param enrollmentAction IPS_Helper ENROLLMENT_ACTION
     * @return REDU_LightningResponse
     */
    @AuraEnabled
    public static REDU_LightningResponse upsertEnrollment(Id individualPathwayId, String requestIpsRecord, String enrollmentAction, String enrollmentStatus){

        Savepoint sp = Database.setSavePoint();
        REDU_Logging_UTIL.debug('requestIpsRecord', requestIpsRecord);

        try {
            REDU_IndividualPlanStructure_OBJ ipsRecord = (REDU_IndividualPlanStructure_OBJ) JSON.deserialize(requestIpsRecord, REDU_IndividualPlanStructure_OBJ.class);

            if (String.isBlank(individualPathwayId) || 
                String.isBlank(enrollmentAction) || 
                ipsRecord.ips == null || 
                ipsRecord.sof == null
            ) {
                throw new REDU_ApplicationException(Label.Error_Contact_Admin);
            }

            // Query the ipw to get the academic term to find the ipr
            List<reduivy__Individual_Pathway__c> ipwList = [SELECT Id, 
                Name,
                reduivy__Academic_Term__c,
                reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c
                FROM reduivy__Individual_Pathway__c
                WHERE Id =: individualPathwayId
                WITH USER_MODE
            ];

            if (ipwList.isEmpty() || String.isBlank(ipwList.get(0).reduivy__Academic_Term__c)) {
                String academicTermFieldLabel = SObjectType.reduivy__Individual_Pathway__c.fields.reduivy__Academic_Term__c.getLabel();
                String recordUrl = REDU_OrganizationInfo_UTIL.getDomainUrl() + individualPathwayId;
                String errorMsg = String.format(Label.Missing_Info_For_Record, new List<String>{academicTermFieldLabel, IPW_Helper.getObjectLabel(), recordUrl});
                
                throw new REDU_ApplicationException(errorMsg);
            }

            // Query the ipe to get ipf to find the ipr
            List<reduivy__Individual_Program_Enrollment__c> ipeList = [SELECT Id,
                Name,
                reduivy__Contact__c,
                reduivy__Individual_Academic_Profile__c,
                reduivy__Master_Enrollment__r.reduivy__Individual_Academic_Profile__c
                FROM reduivy__Individual_Program_Enrollment__c
                WHERE Id =: ipsRecord.ips.reduivy__Individual_Program_Enrollment__c
                WITH USER_MODE
            ];

            Id academicProfileId;
            Id contactId;
            if (!ipeList.isEmpty()) {
                academicProfileId = IPE_Helper.getIpfId(ipeList.get(0));
                            
                if(String.isBlank(contactId)) {
                    contactId = ipeList.get(0).reduivy__Contact__c;
                }
            }

            if (String.isBlank(academicProfileId)) {
                String ipfFieldLabel = SObjectType.reduivy__Individual_Program_Enrollment__c.fields.reduivy__Individual_Academic_Profile__c.getLabel();
                String recordUrl = REDU_OrganizationInfo_UTIL.getDomainUrl() + ipsRecord.ips.reduivy__Individual_Program_Enrollment__c;
                String errorMsg = String.format(Label.Missing_Info_For_Record, new List<String>{ipfFieldLabel, IPE_Helper.getObjectLabel(), recordUrl});
                
                throw new REDU_ApplicationException(errorMsg);
            }

            List<reduivy__Individual_Academic_Progress__c> iprList = [SELECT Id,
                Name,
                reduivy__Academic_Term__c
                FROM reduivy__Individual_Academic_Progress__c
                WHERE reduivy__Individual_Academic_Profile__c =: academicProfileId
                AND reduivy__Academic_Term__c =: ipwList.get(0).reduivy__Academic_Term__c
                WITH USER_MODE
                ORDER BY CreatedDate
                LIMIT 1
            ];

            if (iprList.isEmpty()) {
                String recordUrl = REDU_OrganizationInfo_UTIL.getDomainUrl() + academicProfileId;
                String errorMsg = String.format(Label.Missing_Info_For_Record, new List<String>{IPR_Helper.getObjectLabel(), IPF_Helper.getObjectLabel(), recordUrl});
                
                throw new REDU_ApplicationException(errorMsg);
            }

            reduivy__Individual_Plan_Structure__c unitIps = new reduivy__Individual_Plan_Structure__c(
                Id = ipsRecord.ips.Id,
                RecordTypeId = ipsRecord.ips.RecordTypeId,
                reduivy__Individual_Program_Enrollment__c = ipsRecord.ips.reduivy__Individual_Program_Enrollment__c,
                reduivy__Study_Plan_Structure__c = ipsRecord.ips.reduivy__Study_Plan_Structure__c,
                reduivy__Parent_Plan_Structure__c = ipsRecord.ips.reduivy__Parent_Plan_Structure__c,
                reduivy__Allow_Pre_Enrollment__c = ipsRecord.ips.reduivy__Allow_Pre_Enrollment__c,
                reduivy__Category__c = ipsRecord.ips.reduivy__Category__c,
                reduivy__Credits__c = ipsRecord.ips.reduivy__Credits__c,
                reduivy__Hide_in_Enrollment__c = ipsRecord.ips.reduivy__Hide_in_Enrollment__c,
                reduivy__Sequence__c = ipsRecord.ips.reduivy__Sequence__c
            );

            reduivy__Individual_Enrollment__c existingOpenIenForContactWithStudyUnit;
            
            //ISS-002541 - We only need to find the placeholder IEN if academicTermIen does not exist. If academicTermIen exists (e.g., for pre-enrolled or waitlisted cases), we will use it.
            if (String.isNotBlank(contactId) && String.isNotBlank(ipsRecord.ips.reduivy__Target_Unit_Id__c) && String.isBlank(ipsRecord?.academicTermIen?.Id)) {
                for(reduivy__Individual_Enrollment__c ien : [SELECT Id,
                    reduivy__Study_Offering__c,
                    reduivy__Individual_Academic_Progress__c,
                    reduivy__Credit_Transfer_Application__c
                    FROM reduivy__Individual_Enrollment__c 
                    WHERE reduivy__Contact__c = :contactId 
                    AND reduivy__Target_Unit_Id__c = :ipsRecord.ips.reduivy__Target_Unit_Id__c
                    AND reduivy__Enrollment_Status__c IN :IEN_OPEN_STATUSES
                    AND reduivy__Enrollment_Type__c =: IEN_Helper.ENROLLMENT_TYPE_PROGRAM
                    AND reduivy__Individual_Academic_Profile__c =: academicProfileId
                    WITH USER_MODE
                    ORDER BY CreatedDate ASC
                ]) {
                    //ISS-002541 - Only need the oldest not-started IEN that has no assigned study offering and does not belong to any individual academic progress and not credti transfer application
                    if(existingOpenIenForContactWithStudyUnit == null && String.isBlank(ien.reduivy__Study_Offering__c) && String.isBlank(ien.reduivy__Individual_Academic_Progress__c) && String.isBlank(ien.reduivy__Credit_Transfer_Application__c)) {
                        existingOpenIenForContactWithStudyUnit = ien;
                        break;
                    }
                }
            }
            
            reduivy__Individual_Enrollment__c ien = new reduivy__Individual_Enrollment__c();
            if (String.isNotBlank(ipsRecord?.academicTermIen?.Id)) {
                ien.Id = ipsRecord.academicTermIen.Id;
                ien.reduivy__Enrollment_Status__c = ipsRecord.academicTermIen.reduivy__Enrollment_Status__c;
            } else if (existingOpenIenForContactWithStudyUnit != null && String.isNotBlank(existingOpenIenForContactWithStudyUnit.Id)) { //ISS-002541
                ien.Id = existingOpenIenForContactWithStudyUnit.Id;
            }

            ien.RecordTypeId = IEN_Helper.getStudentRecordTypeId();
            ien.reduivy__Enrollment_Type__c = IEN_Helper.ENROLLMENT_TYPE_PROGRAM;
            ien.reduivy__Contact__c = ipeList.get(0).reduivy__Contact__c;
            ien.reduivy__Individual_Academic_Progress__c = iprList.get(0).Id;
            ien.reduivy__Bypass_Requirement_Met__c = ipsRecord.byPassReqMet;
            ien.reduivy__Individual_Academic_Profile__c = academicProfileId;
            
            String responseMessage;

            String translatedNameFieldApiName = SOF_Helper.getTranslationFieldNameForName();
            String sofNameWithTranslation = (String) (ipsRecord.sof.get(translatedNameFieldApiName) != null ? ipsRecord.sof.get(translatedNameFieldApiName) : ipsRecord.sof.Name);

            if (enrollmentAction == IEN_Helper.ENROLLMENT_ACTION_ENROLLREQUESTED) {
                //pre-enrollment = Enrollment Requested

                ien.reduivy__Enrollment_Status__c = String.isNotBlank(enrollmentStatus) ? enrollmentStatus : IEN_Helper.getEnrollmentRequestedStatuses()[0];
                ien.reduivy__Study_Offering__c = ipsRecord.sof.Id;

                responseMessage = String.format(Label.Pre_Enrollment_Success, new List<String>{sofNameWithTranslation});

            } else if (enrollmentAction == IEN_Helper.ENROLLMENT_ACTION_ENROLL) {
                //enroll = Enrolled

                ien.reduivy__Enrollment_Status__c = String.isNotBlank(enrollmentStatus) ? enrollmentStatus :  IEN_Helper.getInProgressStatuses()[0];
                ien.reduivy__Study_Offering__c = ipsRecord.sof.Id;

                unitIps.reduivy__Primary__c = true;

                responseMessage = String.format(Label.Enrollment_Success, new List<String>{sofNameWithTranslation});

            } else if (enrollmentAction == IEN_Helper.ENROLLMENT_ACTION_JOINWAITLIST) {
                //join waitlist = Waitlisted

                ien.reduivy__Enrollment_Status__c = String.isNotBlank(enrollmentStatus) ? enrollmentStatus :  IEN_Helper.getWaitlistedStatuses()[0];
                ien.reduivy__Study_Offering__c = ipsRecord.sof.Id;

                responseMessage = String.format(Label.Join_Waitlist_Success, new List<String>{sofNameWithTranslation});

            } else if (enrollmentAction == IEN_Helper.ENROLLMENT_ACTION_WITHDRAWENROLLREQUESTED) {
                //withdraw from pre-enrollment = null

                ien.reduivy__Enrollment_Status__c = String.isNotBlank(enrollmentStatus) ? enrollmentStatus :  IEN_Helper.getOpenStatuses()[0];
                ien.reduivy__Study_Offering__c = null;

                unitIps.reduivy__Primary__c = false;

                responseMessage = String.format(Label.Withdraw_Pre_Enrollment_Success, new List<String>{sofNameWithTranslation});

            } else if (enrollmentAction == IEN_Helper.ENROLLMENT_ACTION_WITHDRAWWAITLIST) {
                //withdraw from waitlist = null

                ien.reduivy__Enrollment_Status__c = String.isNotBlank(enrollmentStatus) ? enrollmentStatus :  IEN_Helper.getOpenStatuses()[0];
                ien.reduivy__Study_Offering__c = null;

                unitIps.reduivy__Primary__c = false;
                
                responseMessage = String.format(Label.Withdraw_Waitlist_Success, new List<String>{sofNameWithTranslation});

            } else if(enrollmentAction == IEN_Helper.ENROLLMENT_ACTION_UNENROLLREQUESTED) {
                //request for unenroll = Withdrawl Requested

                ien.reduivy__Enrollment_Status__c = String.isNotBlank(enrollmentStatus) ? enrollmentStatus :  IEN_Helper.getWithdrawalRequestedStatuses()[0];

                responseMessage = String.format(Label.Request_Unenrollment_Success, new List<String>{sofNameWithTranslation});

            } else if (enrollmentAction == IEN_Helper.ENROLLMENT_ACTION_UNENROLL) {
                //unenroll = Withdrawn

                if (String.isNotBlank(ien.Id) && String.isNotBlank(ien.reduivy__Enrollment_Status__c)) {

                    if (IEN_Helper.getInProgressStatuses().contains(ien.reduivy__Enrollment_Status__c)) {
                        ien.reduivy__Enrollment_Status__c = String.isNotBlank(enrollmentStatus) ? enrollmentStatus :  IEN_Helper.getWithdrawnStatuses()[0];

                        unitIps.reduivy__Primary__c = false;

                        responseMessage = String.format(Label.Unenrollment_Success, new List<String>{sofNameWithTranslation});
                    }
                }
            }

            REDU_Database_UTIL.doUpsert(new List<reduivy__Individual_Plan_Structure__c>{unitIps});
            REDU_Database_UTIL.doUpsert(new List<reduivy__Individual_Enrollment__c>{ien});

            return new REDU_LightningResponse(true, responseMessage, JSON.serialize(new Set<Id>{unitIps.Id, ien.Id}));

        } catch (QueryException qex) {
            Database.rollback(sp);

            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {
            Database.rollback(sp);

            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }
}