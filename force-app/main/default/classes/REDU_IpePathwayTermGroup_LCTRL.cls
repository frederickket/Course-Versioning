/**
 * @author      WDCi (Lean)
 * @date        Oct 2023
 * @group       Enrollment wizard
 * @description Controller to handle child groups and child units for a parent group individual plan structure
 * @changehistory
 * ISS-001752 09-10-2023 Lean - new class
 */
public with sharing class REDU_IpePathwayTermGroup_LCTRL {
    
    /**
     * @description response param - title
     */
    public static final String TITLE_PARAM = 'title';

    /**
     * @description response param - ips
     */
    public static final String IPS_PARAM = 'ips';

    /**
     * @description response param - childGroupsIps
     */
    public static final String CHILDGROUPSIPS_PARAM = 'childGroupsIps';

    /**
     * @description Find the related child group records for the current group individual plan structure
     * @param individualPeId
     * @param individualPlanStructureGroupId
     * @param titleField
     * @param tableFields A list of field API name for the enrollment wizard table e.g., reduivy__Study_Unit__c.Name;reduivy__Study_Unit__c.reduivy__Unit_Code__c
     * @return REDU_LightningResponse
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getIndividualPlanStructureGroup(Id individualPeId, Id individualPlanStructureGroupId, String userMode, String titleField, String tableFields){

        try {
            Id ipsGroupRtId = IPS_Helper.getGroupRecordTypeId();
            Id ipsUnitRtId = IPS_Helper.getUnitRecordTypeId();

            Id spsUnitRtId = SPS_Helper.getUnitRecordTypeId();
            Id spsGroupRtId = SPS_Helper.getGroupRecordTypeId();

            //ips fields
            Set<String> ipsQueryFields = new Set<String>{
                'Id',
                'Name',
                'reduivy__Category__c',
                'reduivy__Hidden__c',
                'reduivy__Status__c',
                'reduivy__Individual_Program_Enrollment__c'
            };

            if (String.isBlank(titleField)) {
                titleField = 'reduivy__Study_Plan_Structure__r.Name';
            }

            ipsQueryFields.add(titleField);

            //ips params
            Map<String, Object> ipsBindParams = new Map<String, Object>{
                'id' => individualPlanStructureGroupId,
                'ipeId' => individualPeId,
                'groupRtId' => ipsGroupRtId
            };

            //ips query
            String ipsSubGroupSoql = ' (SELECT Id, Name, RecordTypeId, reduivy__Hidden__c ' + 
            '   FROM reduivy__Individual_Plan_Structures__r ' + 
            '   WHERE RecordTypeId =: groupRtId ';
            
            if (String.isBlank(userMode) || userMode != USR_Helper.USER_MODE_ADMIN) {
                ipsBindParams.put('hidden', false);

                ipsSubGroupSoql += ' AND reduivy__Hidden__c =: hidden ';
            }

            ipsSubGroupSoql += ' ORDER BY reduivy__Sequence_Key__c NULLS LAST) ';

            String ipsSoql = 'SELECT ' + String.join(ipsQueryFields, ', ') + ', ' + 
            ipsSubGroupSoql +
            ' FROM reduivy__Individual_Plan_Structure__c ' +
            ' WHERE Id =: id ' +
            ' AND reduivy__Individual_Program_Enrollment__c =: ipeId ';
            
            Map<String, Object> responseData = new Map<String, Object>();

            List<reduivy__Individual_Plan_Structure__c> childGroupsIps = new List<reduivy__Individual_Plan_Structure__c>();
            reduivy__Individual_Plan_Structure__c currentGroupIps;

            //get the group individual plan structure and related child group records
            for (reduivy__Individual_Plan_Structure__c ips : (List<reduivy__Individual_Plan_Structure__c>) Database.queryWithBinds(ipsSoql, ipsBindParams, AccessLevel.USER_MODE)) {
                currentGroupIps = ips;
                
                for (reduivy__Individual_Plan_Structure__c childIps : ips.reduivy__Individual_Plan_Structures__r) {
                    childGroupsIps.add(childIps);
                }
            }

            if (currentGroupIps != null) {
                String title = String.valueOf(REDU_SObject_UTIL.extractFieldValue(currentGroupIps, titleField));
                    
                responseData.put(TITLE_PARAM, title);
                responseData.put(IPS_PARAM, currentGroupIps);

                if (!childGroupsIps.isEmpty()) {
                    //If it has more child groups, return the child group only
                    responseData.put(CHILDGROUPSIPS_PARAM, childGroupsIps);
                }
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
	
}