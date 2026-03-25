/**
 * @author      WDCi (Lean)
 * @date        Oct 2023
 * @group       Requirement Met
 * @description Utility to validate the requirement met status
 * @changehistory
 * ISS-001752 25-10-2023 Lean - new utility
 * ISS-001979 19-07-2024 Sueanne - added getUnitIpsRequirements() 
 * ISS-002044 29-07-2024 Sueanne - added logic for "Conflict" requirement type
 * ISS-002137 14-10-2024 Sueanne - added if statement check for unitIpsBySun for requirement type = Conflict
 * ISS-002144 18-12-2024 XW - do not allow pre-enrollment if enrollmentSetting == UNIT_ENROLLMENT_ALLOW_PREREQUISITE and spur requirement type is REQTYPE_PREREQ (not bypass)
 * ISS-002155 26-12-2024 XW - allow req type == custom
 * ISS-002226 06-01-2025 XW - renamed Conflict type to 'Enrolled or Completed'
 */
public inherited sharing class REDU_StudyUnitRequirement_UTIL {
    
    /**
     * @description Validate an sps requirement met status
     * @param requirementLogic Requirement logic string
     * @param ipeTotalCreditsEarned Individual Program Enrollment's total credits earned
     * @param unitRequirements List of student plan unit requirements to be evaluated
     * @param unitIpsBySun List of individual plan structure unit to be used as evaluation
     * @return Boolean
     */
    public static boolean isRequirementMet(String requirementLogic, reduivy__Individual_Program_Enrollment__c ipe, List<reduivy__Study_Plan_Unit_Requirement__c> unitRequirements, Map<Id, List<reduivy__Individual_Plan_Structure__c>> unitIpsBySun, String enrollmentSetting, Id academicTermId) {

        if (String.isBlank(requirementLogic) || unitRequirements == null || unitRequirements.isEmpty()) {
            return true;
        }

        Decimal ipeTotalCreditsEarned = ipe.reduivy__Credits_Earned__c != null ? ipe.reduivy__Credits_Earned__c : 0;
        unitIpsBySun = unitIpsBySun != null ? unitIpsBySun : new Map<Id, List<reduivy__Individual_Plan_Structure__c>>();

        List<REDU_ConditionLogic_OBJ.Requirement> reqList = new List<REDU_ConditionLogic_OBJ.Requirement>();

        Schema.DescribeSObjectResult ipeDescribeSObjectResult = REDU_Metadata_UTIL.describeSObject(IPE_Helper.getApiName());
        Map<String, Schema.SObjectField> ipeFieldMap = ipeDescribeSObjectResult.fields.getMap();
        for (reduivy__Study_Plan_Unit_Requirement__c spur : unitRequirements) {
            REDU_ConditionLogic_OBJ.Requirement req = new REDU_ConditionLogic_OBJ.Requirement(spur.reduivy__Requirement_ID__c, false);

            //Check if individual requirement is met
            //ISS-002144 prereq with/without bypass have the same behaviour, except for "bypass allowed" can be bypassed if enrollmentSetting is "allow prerequisite"
            if (spur.reduivy__Requirement_Type__c == SPR_Helper.REQTYPE_PREREQ || spur.reduivy__Requirement_Type__c == SPR_Helper.REQTYPE_PREREQ_BYPASS) { 

                //Look for Completed unit
                if (unitIpsBySun.containsKey(spur.reduivy__Required_Study_Unit__c)) {

                    for (reduivy__Individual_Plan_Structure__c unitIps : unitIpsBySun.get(spur.reduivy__Required_Study_Unit__c)) {
                        if (IPS_Helper.getUnitCompletedStatuses().contains(unitIps.reduivy__Status__c)
                            && unitIps.reduivy__Individual_Enrollment__r.reduivy__Academic_Term_Id__c != academicTermId
                        ) {
                            req.requirementValue = true;
                            break;
                        }
                    }

                    if(!req.requirementValue){
                        if(spur.reduivy__Requirement_Type__c == SPR_Helper.REQTYPE_PREREQ_BYPASS && enrollmentSetting == STM_Helper.UNIT_ENROLLMENT_ALLOW_PREREQUISITE) { //ISS-002144
                            for (reduivy__Individual_Plan_Structure__c unitIps : unitIpsBySun.get(spur.reduivy__Required_Study_Unit__c)){
                                
                                if (IPS_Helper.getUnitInProgressStatuses().contains(unitIps.reduivy__Status__c) 
                                    && unitIps.reduivy__Individual_Enrollment__r.reduivy__Academic_Term_Id__c != academicTermId
                                ){
                                    req.requirementValue = true;
                                    break;
                                }
                            }
                        }
                    }
                }

            } else if (spur.reduivy__Requirement_Type__c == SPR_Helper.REQTYPE_COREQ) {
                //Treat all coreqs as met
                req.requirementValue = true;

            } else if (spur.reduivy__Requirement_Type__c == SPR_Helper.REQTYPE_ENROLLED_COMPLETED) {
                
                if (!unitIpsBySun.containsKey(spur.reduivy__Required_Study_Unit__c)){
                    req.requirementValue = false;
                    
                } else {

                    for (reduivy__Individual_Plan_Structure__c unitIps : unitIpsBySun.get(spur.reduivy__Required_Study_Unit__c)){
                        if (IPS_Helper.getUnitCompletedStatuses().contains(unitIps.reduivy__Status__c) || IPS_Helper.getUnitInProgressStatuses().contains(unitIps.reduivy__Status__c)){
                            req.requirementValue = true;
                            break;
                        }
                    }
                }
                
            } else if (spur.reduivy__Requirement_Type__c == SPR_Helper.REQTYPE_CREDITS) {
                //Check Credits
                req.requirementValue = ipeTotalCreditsEarned >= spur.reduivy__Credits__c;

            } else if (spur.reduivy__Requirement_Type__c == SPR_Helper.REQTYPE_CUSTOM) { //ISS-002155

                if(String.isBlank(spur.reduivy__Field_Name__c) || String.isBlank(spur.reduivy__Field_Matching_Operator__c)) {
                    continue;
                }

                ipeFieldMap.get(spur.reduivy__Field_Name__c);
                Schema.DescribeFieldResult fieldResult = ipeFieldMap.get(spur.reduivy__Field_Name__c).getDescribe();
                Object actualValue = ipe.get(spur.reduivy__Field_Name__c);
                String operator = spur.reduivy__Field_Matching_Operator__c;
                String expectedValue = spur.reduivy__Field_Matching_Value__c;

                try {
                    req.requirementValue = REDU_MatchingOperator_UTIL.calculate(fieldResult.getType(), actualValue, operator, expectedValue);
                } catch(Exception exp) {
                    String errorMessage = REDU_MatchingOperator_UTIL.getErrorMessage(exp.getMessage(), operator, IUR_Helper.getApiName(), spur.reduivy__Field_Name__c);
                    throw REDU_Exception_UTIL.auraException(errorMessage);
                }
            }

            reqList.add(req);
        }

        REDU_ConditionLogic_OBJ conditionLogic = new REDU_ConditionLogic_OBJ(requirementLogic);

        return conditionLogic.valueOf(reqList);

    }

    /**
     * @description Return the study plan unit requirement for study plan structure unit
     * @param unitSpsList List of study plan structure unit
     * @return Map<Id, List<reduivy__Study_Plan_Unit_Requirement__c>>
     */
    public static Map<Id, List<reduivy__Study_Plan_Unit_Requirement__c>> getUnitSpsRequirements(List<reduivy__Study_Plan_Structure__c> unitSpsList) {

        Map<Id, List<reduivy__Study_Plan_Unit_Requirement__c>> spursBySps = new Map<Id, List<reduivy__Study_Plan_Unit_Requirement__c>>();
        Map<Id, List<reduivy__Study_Unit_Requirement__c>> sursBySun = new Map<Id, List<reduivy__Study_Unit_Requirement__c>>();
        
        //look for spur if there is any
        for (reduivy__Study_Plan_Unit_Requirement__c spur : [SELECT Id,
            Name, 
            reduivy__Requirement_ID__c,
            reduivy__Requirement_Type__c,
            reduivy__Required_Study_Unit__c,
            reduivy__Credits__c,
            reduivy__Other__c,
            reduivy__Field_Name__c,                 //ISS-002155
            reduivy__Field_Matching_Operator__c,    //ISS-002155
            reduivy__Field_Matching_Value__c,       //ISS-002155
            reduivy__Study_Plan_Unit__c,
            reduivy__Study_Plan_Unit__r.reduivy__Study_Unit__c
            FROM reduivy__Study_Plan_Unit_Requirement__c
            WHERE reduivy__Study_Plan_Unit__c IN: unitSpsList
            WITH USER_MODE
        ]) {
            if (spursBySps.containsKey(spur.reduivy__Study_Plan_Unit__c)) {
                spursBySps.get(spur.reduivy__Study_Plan_Unit__c).add(spur);
            } else {
                spursBySps.put(spur.reduivy__Study_Plan_Unit__c, new List<reduivy__Study_Plan_Unit_Requirement__c>{spur});
            }
        }

        // look for the default sur if the sps doesn't have requirement logic defined and doesn't have any spur
        // if the sps has requirement logic defined, we should use spur instead. this is the same in IPS_CreateRequirement_EXE
        Set<Id> unitIdsForSpsWithoutSpur = new Set<Id>();
        List<reduivy__Study_Plan_Structure__c> spsWithoutSpurList = new List<reduivy__Study_Plan_Structure__c>();

        for (reduivy__Study_Plan_Structure__c sps : unitSpsList) {
            if (String.isNotBlank(sps.reduivy__Study_Unit__c) && String.isBlank(sps.reduivy__Requirement_Logic__c)) {
                unitIdsForSpsWithoutSpur.add(sps.reduivy__Study_Unit__c);

                spsWithoutSpurList.add(sps);
            }
        }

        for (reduivy__Study_Unit_Requirement__c sur : [SELECT Id,
            Name, 
            reduivy__Requirement_ID__c,
            reduivy__Requirement_Type__c,
            reduivy__Required_Study_Unit__c,
            reduivy__Credits__c,
            reduivy__Other__c,
            reduivy__Field_Name__c,                 //ISS-002155
            reduivy__Field_Matching_Operator__c,    //ISS-002155
            reduivy__Field_Matching_Value__c,       //ISS-002155
            reduivy__Study_Unit__c
            FROM reduivy__Study_Unit_Requirement__c
            WHERE reduivy__Study_Unit__c IN: unitIdsForSpsWithoutSpur
            WITH USER_MODE
        ]) {
            if (sursBySun.containsKey(sur.reduivy__Study_Unit__c)) {
                sursBySun.get(sur.reduivy__Study_Unit__c).add(sur);
            } else {
                sursBySun.put(sur.reduivy__Study_Unit__c, new List<reduivy__Study_Unit_Requirement__c>{sur});
            }
        }

        for (reduivy__Study_Plan_Structure__c sps : spsWithoutSpurList) {
            if (sursBySun.containsKey(sps.reduivy__Study_Unit__c)) {

                List<reduivy__Study_Plan_Unit_Requirement__c> spsSpurs = new List<reduivy__Study_Plan_Unit_Requirement__c>();

                for (reduivy__Study_Unit_Requirement__c sur : sursBySun.get(sps.reduivy__Study_Unit__c)){
                    reduivy__Study_Plan_Unit_Requirement__c spur = new reduivy__Study_Plan_Unit_Requirement__c(
                        Name = sur.Name,
                        reduivy__Requirement_ID__c = sur.reduivy__Requirement_ID__c,
                        reduivy__Requirement_Type__c = sur.reduivy__Requirement_Type__c,
                        reduivy__Required_Study_Unit__c = sur.reduivy__Required_Study_Unit__c,
                        reduivy__Credits__c = sur.reduivy__Credits__c,
                        reduivy__Other__c = sur.reduivy__Other__c,
                        reduivy__Field_Name__c = sur.reduivy__Field_Name__c,                            //ISS-002155
                        reduivy__Field_Matching_Operator__c = sur.reduivy__Field_Matching_Operator__c,  //ISS-002155
                        reduivy__Field_Matching_Value__c = sur.reduivy__Field_Matching_Value__c,        //ISS-002155
                        reduivy__Study_Plan_Unit__c = sps.Id
                    );

                    spsSpurs.add(spur);
                }

                spursBySps.put(sps.Id, spsSpurs);
            }
        }

        return spursBySps;
    }

    /**
     * @description Return the individual plan unit requirement for individual plan structure unit
     * @param unitIpsList List of individual plan structure unit
     * @return Map<Id, List<reduivy__Individual_Plan_Unit_Requirement__c>>
     */
    public static Map<Id, List<reduivy__Individual_Plan_Unit_Requirement__c>> getUnitIpsRequirements(List<reduivy__Individual_Plan_Structure__c> unitIpsList) {

        Map<Id, List<reduivy__Individual_Plan_Unit_Requirement__c>> ipursByIps = new Map<Id, List<reduivy__Individual_Plan_Unit_Requirement__c>>();
        
        //look for ipur if there is any
        for (reduivy__Individual_Plan_Unit_Requirement__c ipur : [SELECT Id,
            Name, 
            reduivy__Requirement_ID__c,
            reduivy__Requirement_Type__c,
            reduivy__Required_Study_Unit__c,
            reduivy__Credits__c,
            reduivy__Other__c,
            reduivy__Field_Name__c,                 //ISS-002155
            reduivy__Field_Matching_Operator__c,    //ISS-002155
            reduivy__Field_Matching_Value__c,       //ISS-002155
            reduivy__Individual_Plan_Unit__c,
            reduivy__Individual_Plan_Unit__r.reduivy__Study_Plan_Structure__c
            FROM reduivy__Individual_Plan_Unit_Requirement__c
            WHERE reduivy__Individual_Plan_Unit__c IN: unitIpsList
            WITH USER_MODE
        ]) {
            if (ipursByIps.containsKey(ipur.reduivy__Individual_Plan_Unit__c)) {
                ipursByIps.get(ipur.reduivy__Individual_Plan_Unit__c).add(ipur);
            } else {
                ipursByIps.put(ipur.reduivy__Individual_Plan_Unit__c, new List<reduivy__Individual_Plan_Unit_Requirement__c>{ipur});
            }
        }

        return ipursByIps;
    }
}