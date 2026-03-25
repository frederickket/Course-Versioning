/**
 * @author      WDCi (Lean)
 * @date        Oct 2023
 * @group       Enrollment wizard
 * @description Controller to handle group individual plan structure for an individual program enrollment
 * @changehistory
 * ISS-001752 09-10-2023 Lean - new class
 * ISS-002230 26-02-2025 XW - display picklist label instead of value
 * ISS-002336 24-03-2024 Lean - Added missed/failed unit
 * ISS-002369 15-04-2025 XiRouh - Added condition to check IEN enrollment status in soql
 * ISS-002486 10-05-2025 XiRouh - Updated the SOQL query to include completed fail IEN
 */
public with sharing class REDU_IpePathwayTermListing_LCTRL {
    
    /**
     * @description response param - title
     */
    public static final String TITLE_PARAM = 'title';

    /**
     * @description response param - ipe
     */
    public static final String IPE_PARAM = 'ipe';

    /**
     * @description response param - topGroupIps
     */
    public static final String TOPGROUPSIPS_PARAM = 'topGroupIps';

    /**
     * @description Get individual program enrollment and top level groups
     * @param individualPeId
     * @param titleField
     * @return REDU_LightningResponse
     */
	@AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getIndividualProgramEnrollment(Id individualPeId, Id individualPathwayId, String userMode, String unitListingMode, String titleField, String missedFailedUnitListingOption){

        try {
            Id ipsGroupRtId = IPS_Helper.getGroupRecordTypeId();
            Id spsGroupRtId = SPS_Helper.getGroupRecordTypeId();
            Id spsUnitRtId = SPS_Helper.getUnitRecordTypeId();

            String sunPluralLabel = SUN_Helper.getObjectPluralLabel();

            Set<String> ipeFields = new Set<String>{
                'Id',
                'Name',
                'reduivy__Contact__c',
                'reduivy__Individual_Academic_Profile__c',
                'reduivy__Study_Pathway__c',
                'reduivy__Study_Plan__c',
                'reduivy__Master_Enrollment__c',
                'reduivy__Master_Enrollment__r.reduivy__Study_Pathway__c',
                'reduivy__Master_Enrollment__r.reduivy__Individual_Academic_Profile__c'
            };

            if (String.isBlank(titleField)) {
                titleField = 'reduivy__Study_Plan__r.Name';
            }

            ipeFields.add(titleField);

            Schema.SObjectType rootSobjectType = reduivy__Individual_Program_Enrollment__c.sObjectType;
            Set<String> ipeAdditionalFields = new Set<String>();

            for(String field : ipeFields) {
                Schema.DescribeFieldResult fieldDescribe = REDU_Datatable_UTIL.getFieldDescribe(field, rootSobjectType);
                String purifiedField;

                if(fieldDescribe.getType() == Schema.DisplayType.REFERENCE) {
                    purifiedField = REDU_Metadata_UTIL.getReferenceFieldForQuery(field, true);
                    ipeAdditionalFields.add(purifiedField);
                    
                } else if(fieldDescribe.getType() == Schema.DisplayType.PICKLIST || fieldDescribe.getType() == Schema.DisplayType.MULTIPICKLIST) {
                    purifiedField = REDU_Metadata_UTIL.getPicklistLabelFieldName(field);
                    ipeAdditionalFields.add(REDU_Metadata_UTIL.getPicklistFieldLabelQuery(field));
                }

                if(String.isNotBlank(purifiedField) && field == titleField) {
                    titleField = purifiedField;
                }
            }

            ipeFields.addAll(ipeAdditionalFields);

            String ipeSoql = 'SELECT ' + String.join(ipeFields, ', ') + 
            ' FROM reduivy__Individual_Program_Enrollment__c ' +
            ' WHERE Id =: individualPeId ';

            Map<String, Object> ipeBindParams = new Map<String, Object>{
                'individualPeId' => individualPeId
            };
            
            Map<String, Object> responseData = new Map<String, Object>();

            reduivy__Individual_Program_Enrollment__c ipeRecord;
            for (reduivy__Individual_Program_Enrollment__c ipe : (List<reduivy__Individual_Program_Enrollment__c>)Database.queryWithBinds(ipeSoql, ipeBindParams, AccessLevel.USER_MODE)) {
                ipeRecord = ipe;
            }

            if (ipeRecord != null) {
                //we only consider the study pathway and academic profile from the master enrollment
                Id studyPathwayId = String.isNotBlank(ipeRecord.reduivy__Master_Enrollment__c) ? ipeRecord.reduivy__Master_Enrollment__r.reduivy__Study_Pathway__c : ipeRecord.reduivy__Study_Pathway__c;
                Id academicProfileId = IPE_Helper.getIpfId(ipeRecord);

                String title = String.valueOf(REDU_SObject_UTIL.extractFieldValue(ipeRecord, titleField));
                responseData.put(TITLE_PARAM, title);
                responseData.put(IPE_PARAM, ipeRecord);

                //find the group by listing mode
                List<REDU_IndividualPlanStructure_OBJ> groupIpsWrapper = new List<REDU_IndividualPlanStructure_OBJ>();

                if (unitListingMode == IPW_Helper.UNIT_LISTING_MODE_PATHWAY) {
                    //pathway listing mode
                    //look for the study program, skip if Study Plan and Study Program is not defined or individualPathwayId is blank
                    if (String.isNotBlank(ipeRecord.reduivy__Study_Plan__c) && String.isNotBlank(studyPathwayId) && String.isNotBlank(individualPathwayId) && String.isNotBlank(academicProfileId)) {

                        List<reduivy__Individual_Pathway__c> ipwList = [SELECT Id, 
                            reduivy__Academic_Term__c,
                            reduivy__Term_Number__c,
                            reduivy__Status__c
                            FROM reduivy__Individual_Pathway__c
                            WHERE Id =: individualPathwayId
                            WITH USER_MODE
                        ];

                        if (!ipwList.isEmpty()) {
                            reduivy__Individual_Pathway__c ipwRecord = ipwList.get(0);

                            //ensure that we have term number for matching
                            if (ipwRecord.reduivy__Term_Number__c != null &&
                                String.isNotBlank(ipwRecord.reduivy__Academic_Term__c)
                            ) {
                                //get the existing ien that enrolled on the same academic term from ipr
                                Set<Id> ienSunIds = new Set<Id>();
                                Map<Id, reduivy__Individual_Enrollment__c> ienMap = new Map<Id, reduivy__Individual_Enrollment__c>([
                                    SELECT Id,
                                    reduivy__Contact__c,
                                    reduivy__Enrollment_Status__c,
                                    reduivy__Target_Unit_Id__c
                                    FROM reduivy__Individual_Enrollment__c
                                    WHERE reduivy__Contact__c =: ipeRecord.reduivy__Contact__c
                                    AND reduivy__Individual_Academic_Progress__r.reduivy__Academic_Term__c =: ipwRecord.reduivy__Academic_Term__c
                                    AND reduivy__Individual_Academic_Progress__r.reduivy__Individual_Academic_Profile__c =: academicProfileId
                                    AND reduivy__Individual_Academic_Progress__r.reduivy__Individual_Academic_Profile__r.reduivy__Status__c =: IPF_Helper.STATUS_ACTIVE
                                    AND reduivy__Enrollment_Type__c =: IEN_Helper.ENROLLMENT_TYPE_PROGRAM
                                    AND (reduivy__Enrollment_Status__c IN: IEN_Helper.getNonEnrollableStatuses() OR reduivy__Enrollment_Status__c IN: IEN_Helper.getCompletedFailStatuses()) //ISS-002369, ISS-002486
                                    WITH USER_MODE
                                ]);

                                for (reduivy__Individual_Enrollment__c ien : ienMap.values()) {
                                    if (!IEN_Helper.getOpenStatuses().contains(ien.reduivy__Enrollment_Status__c) && 
                                        String.isNotBlank(ien.reduivy__Target_Unit_Id__c)
                                    ) {
                                        ienSunIds.add(ien.reduivy__Target_Unit_Id__c);
                                    }
                                }

                                List<reduivy__Study_Pathway_Unit__c> groupSpuList = new List<reduivy__Study_Pathway_Unit__c>();
                                List<reduivy__Study_Pathway_Unit__c> unitSpuList = new List<reduivy__Study_Pathway_Unit__c>();
                                
                                Map<Id, reduivy__Study_Pathway_Unit__c> unitSptMap = new Map<Id, reduivy__Study_Pathway_Unit__c>();
                                Map<Id, reduivy__Study_Pathway_Unit__c> groupSptMap = new Map<Id, reduivy__Study_Pathway_Unit__c>();

                                Map<Id, Set<Id>> sunIdsByGroupSps = new Map<Id, Set<Id>>();

                                for (reduivy__Study_Pathway_Unit__c spt : [SELECT Id,
                                    reduivy__Applicable_Study_Plan__c,
                                    reduivy__Number_of_Units_from_Group__c,
                                    reduivy__Study_Plan_Group__c,
                                    reduivy__Study_Unit__c
                                    FROM reduivy__Study_Pathway_Unit__c
                                    WHERE reduivy__Study_Pathway_Term__r.reduivy__Study_Pathway__c =: studyPathwayId
                                    AND reduivy__Study_Pathway_Term__r.reduivy__Term_Number__c =: ipwRecord.reduivy__Term_Number__c
                                    WITH USER_MODE
                                ]) {
                                    //match the study pathway unit
                                    if (String.isBlank(spt.reduivy__Applicable_Study_Plan__c)
                                        || (String.isNotBlank(spt.reduivy__Applicable_Study_Plan__c) && spt.reduivy__Applicable_Study_Plan__c == ipeRecord.reduivy__Study_Plan__c)
                                    ) {
                                        if (String.isNotBlank(spt.reduivy__Study_Unit__c)) {
                                            unitSptMap.put(spt.reduivy__Study_Unit__c, spt);
                                        } else if (String.isNotBlank(spt.reduivy__Study_Plan_Group__c)) {
                                            groupSptMap.put(spt.reduivy__Study_Plan_Group__c, spt);
                                        }
                                    }
                                }

                                Set<Id> studyUnitsToInclude = new Set<Id>();
                                studyUnitsToInclude.addAll(unitSptMap.keySet());

                                //ISS-002336
                                if (String.isNotBlank(missedFailedUnitListingOption) && ipwRecord.reduivy__Status__c != IPW_Helper.STATUS_COMPLETED) {
                                    Set<Id> missedFailedStudyUnits = REDU_IpePathways_LCTRL.getMissedFailedStudyUnits(ipeRecord.Id, ipeRecord.reduivy__Study_Plan__c, studyPathwayId, userMode, ipwRecord.reduivy__Term_Number__c, missedFailedUnitListingOption);
                                    studyUnitsToInclude.addAll(missedFailedStudyUnits);
                                }

                                //find the sps defined in the study pathway unit
                                for (reduivy__Study_Plan_Structure__c unitSps : [SELECT Id,
                                    Name,
                                    reduivy__Study_Unit__c,
                                    reduivy__Parent_Study_Plan_Structure__c
                                    FROM reduivy__Study_Plan_Structure__c
                                    WHERE RecordTypeId =: spsUnitRtId
                                    AND reduivy__Study_Unit__c IN: studyUnitsToInclude
                                    AND reduivy__Study_Plan__c =: ipeRecord.reduivy__Study_Plan__c
                                    WITH USER_MODE
                                ]) {
                                    if (String.isNotBlank(unitSps.reduivy__Parent_Study_Plan_Structure__c) && String.isNotBlank(unitSps.reduivy__Study_Unit__c)) {
                                        if (sunIdsByGroupSps.containsKey(unitSps.reduivy__Parent_Study_Plan_Structure__c)) {
                                            sunIdsByGroupSps.get(unitSps.reduivy__Parent_Study_Plan_Structure__c).add(unitSps.reduivy__Study_Unit__c);
                                        } else {
                                            sunIdsByGroupSps.put(unitSps.reduivy__Parent_Study_Plan_Structure__c, new Set<Id>{unitSps.reduivy__Study_Unit__c});
                                        }
                                    }
                                }

                                //find the existing unit ips that linked to the individual pathway as we need to show them in pathway view too
                                Set<String> existingUnitIpsFields = new Set<String>{
                                    'Id',
                                    'reduivy__Target_Unit_Id__c',
                                    'reduivy__Parent_Plan_Structure__c',
                                    'reduivy__Parent_Plan_Structure__r.Name',
                                    'reduivy__Parent_Plan_Structure__r.reduivy__Study_Plan_Structure__c',
                                    'reduivy__Hidden__c'
                                };

                                String existingUnitIpsSoql = 'SELECT ' + String.join(existingUnitIpsFields, ', ') +
                                    ' FROM reduivy__Individual_Plan_Structure__c ' +
                                    ' WHERE reduivy__Individual_Program_Enrollment__c =: ipeRecordId ' +
                                    ' AND reduivy__Target_Unit_Id__c IN: ienSunIds ' +
                                    ' AND RecordTypeId =: unitRtId ';

                                Map<String, Object> existingUnitIpsBindParams = new Map<String, Object>{
                                    'ipeRecordId' => ipeRecord.Id,
                                    'ienSunIds' => ienSunIds,
                                    'unitRtId' => IPS_Helper.getUnitRecordTypeId()
                                };

                                if (String.isBlank(userMode) || userMode != USR_Helper.USER_MODE_ADMIN) {
                                    existingUnitIpsBindParams.put('hidden', false);
                    
                                    existingUnitIpsSoql += ' AND reduivy__Hidden__c =: hidden ';
                                }

                                for (reduivy__Individual_Plan_Structure__c existingUnitIps : (List<reduivy__Individual_Plan_Structure__c>) Database.queryWithBinds(existingUnitIpsSoql, existingUnitIpsBindParams, AccessLevel.USER_MODE)) {
                                    if (String.isNotBlank(existingUnitIps.reduivy__Parent_Plan_Structure__c)) {

                                        //we store the study unit id. if study unit id is blank, we store the unit ips id
                                        Id targetId = getIdForRestrictedUnit(existingUnitIps);

                                        if (String.isNotBlank(existingUnitIps.reduivy__Parent_Plan_Structure__r.reduivy__Study_Plan_Structure__c)) {
                                            Id spsId = existingUnitIps.reduivy__Parent_Plan_Structure__r.reduivy__Study_Plan_Structure__c;

                                            //if the group sps is defined in the study pathway unit, we will not list it individually
                                            if (!groupSptMap.containsKey(spsId)) {
                                                if (sunIdsByGroupSps.containsKey(spsId)) {
                                                    sunIdsByGroupSps.get(spsId).add(targetId);
                                                } else {
                                                    sunIdsByGroupSps.put(spsId, new Set<Id>{targetId});
                                                }
                                            }
                                        } else {
                                            //we store the group ips id as the key instead of the parent's sps to cater for group without study plan structure
                                            Id ipsId = existingUnitIps.reduivy__Parent_Plan_Structure__c;

                                            if (sunIdsByGroupSps.containsKey(ipsId)) {
                                                sunIdsByGroupSps.get(ipsId).add(targetId);
                                            } else {
                                                sunIdsByGroupSps.put(ipsId, new Set<Id>{targetId});
                                            }
                                        }
                                    }
                                }

                                Set<Id> groupSpsIds = new Set<Id>();
                                groupSpsIds.addAll(groupSptMap.keySet());
                                groupSpsIds.addAll(sunIdsByGroupSps.keySet());

                                REDU_Logging_UTIL.debug('groupSpsIds', groupSpsIds);
                                
                                Set<String> groupIpsFields = new Set<String>{
                                    'Id',
                                    'Name',
                                    'reduivy__Study_Plan_Structure__c',
                                    'reduivy__Hidden__c'
                                };

                                String groupIpsSoql = 'SELECT ' + String.join(groupIpsFields, ', ') +
                                    ' FROM reduivy__Individual_Plan_Structure__c ' +
                                    ' WHERE (reduivy__Study_Plan_Structure__c IN: groupSpsIds OR Id IN: groupSpsIds ) ' +
                                    ' AND reduivy__Individual_Program_Enrollment__c =: ipeRecordId ' +
                                    ' AND RecordTypeId =: ipsGroupRtId ';

                                Map<String, Object> groupIpsBindParams = new Map<String, Object>{
                                    'ipeRecordId' => ipeRecord.Id,
                                    'groupSpsIds' => groupSpsIds,
                                    'ipsGroupRtId' => ipsGroupRtId
                                };

                                if (String.isBlank(userMode) || userMode != USR_Helper.USER_MODE_ADMIN) {
                                    groupIpsBindParams.put('hidden', false);
                    
                                    groupIpsSoql += ' AND reduivy__Hidden__c =: hidden ';
                                }

                                groupIpsSoql += ' ORDER BY reduivy__Sequence_Key__c NULLS LAST ';

                                for (reduivy__Individual_Plan_Structure__c ips : (List<reduivy__Individual_Plan_Structure__c>) Database.queryWithBinds(groupIpsSoql, groupIpsBindParams, AccessLevel.USER_MODE)) {
                                    if (groupSptMap.containsKey(ips.reduivy__Study_Plan_Structure__c)) {
                                        //prepare the group for the sps group defined in study pathway unit
                                        Decimal numOfUnits = groupSptMap.get(ips.reduivy__Study_Plan_Structure__c).reduivy__Number_of_Units_from_Group__c;
                                        String numOfUnitsStr = numOfUnits != null ? String.valueOf(numOfUnits) : Label.Unknown.toLowerCase();

                                        REDU_IndividualPlanStructure_OBJ groupIps = new REDU_IndividualPlanStructure_OBJ();
                                        groupIps.id = ips.Id;
                                        groupIps.ips = ips;
                                        groupIps.description = String.format(Label.Pick_x_Study_Units_From_Below, new List<String>{numOfUnitsStr, sunPluralLabel.toLowerCase()});
                                        
                                        groupIpsWrapper.add(groupIps);

                                    }
                                    
                                    if (sunIdsByGroupSps.containsKey(ips.reduivy__Study_Plan_Structure__c)) {
                                        //prepare the group for the sps unit defined in the study pathway unit
                                        REDU_IndividualPlanStructure_OBJ groupIps = new REDU_IndividualPlanStructure_OBJ();
                                        groupIps.id = ips.Id;
                                        groupIps.ips = ips;
                                        groupIps.restrictedToUnits.addAll(sunIdsByGroupSps.get(ips.reduivy__Study_Plan_Structure__c));
                                        
                                        groupIpsWrapper.add(groupIps);
                                    } else if (sunIdsByGroupSps.containsKey(ips.Id)) {
                                        //prepare the group  for ips group that has units linked to the individual pathway
                                        REDU_IndividualPlanStructure_OBJ groupIps = new REDU_IndividualPlanStructure_OBJ();
                                        groupIps.id = ips.Id;
                                        groupIps.ips = ips;
                                        groupIps.restrictedToUnits.addAll(sunIdsByGroupSps.get(ips.Id));
                                        
                                        groupIpsWrapper.add(groupIps);
                                    }
                                }
                            }
                        } else {
                            throw new REDU_ApplicationException(String.format(Label.Invalid_Record_Id, new List<String>{individualPathwayId}));
                        }
                        
                    }                 

                } else {
                    //all listing mode, just list everything available in the study program plan

                    String groupIpsSoql = 'SELECT Id, Name, reduivy__Hidden__c ' +
                        ' FROM reduivy__Individual_Plan_Structure__c ' + 
                        ' WHERE RecordTypeId =: ipsGroupRtId ' +
                        ' AND reduivy__Parent_Plan_Structure__c = NULL ' + 
                        ' AND reduivy__Individual_Program_Enrollment__c =: individualPeId ';

                    Map<String, Object> ipsBindParams = new Map<String, Object>{
                        'ipsGroupRtId' => ipsGroupRtId,
                        'individualPeId' => individualPeId
                    };

                    if (String.isBlank(userMode) || userMode != USR_Helper.USER_MODE_ADMIN) {
                        ipsBindParams.put('hidden', false);
        
                        groupIpsSoql += ' AND reduivy__Hidden__c =: hidden ';
                    }

                    groupIpsSoql += ' ORDER BY reduivy__Sequence_Key__c NULLS LAST ';

                    for (reduivy__Individual_Plan_Structure__c ips : (List<reduivy__Individual_Plan_Structure__c>)Database.queryWithBinds(groupIpsSoql, ipsBindParams, AccessLevel.USER_MODE)) {
                        REDU_IndividualPlanStructure_OBJ groupIps = new REDU_IndividualPlanStructure_OBJ();
                        groupIps.id = ips.Id;
                        groupIps.ips = ips;

                        groupIpsWrapper.add(groupIps);
                    }
                }

                responseData.put(TOPGROUPSIPS_PARAM, groupIpsWrapper);

            } else {
                throw new REDU_ApplicationException(String.format(Label.Invalid_Record_Id, new List<String>{individualPeId}));
            }

            return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(responseData));

        } catch (QueryException qex) {
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    /**
     * @description Return the study unit id or unit ips id
     * @param unitIps
     * @return Id
     */
    private static Id getIdForRestrictedUnit(reduivy__Individual_Plan_Structure__c unitIps) {

        if (String.isNotBlank(unitIps.reduivy__Target_Unit_Id__c)) {
            return Id.valueOf(unitIps.reduivy__Target_Unit_Id__c);
        }
        
        return unitIps.Id;
    }

}