/**
 * @author      WDCi (Lean)
 * @date        Sept 2023
 * @group       Object Helper
 * @description Individual Plan Unit Requirement object helper class that contains the picklist option constants and object related methods
 * @changehistory
 * ISS-001662 12-10-2023 dblack - added method, getIurMap()
 * ISS-001762 23-10-2023 dblack - added method, isRequirementMet()
 * ISS-001927 29-03-2024 VTan - Enhance logic to consider requirement met for child IPE
 * ISS-001979 15-07-2024 Sueanne - added method, convertIurToSpr()
 * ISS-002044 29-07-2024 Sueanne - added requirement type "Conflict"
 * ISS-002144 18-12-2024 XW - added requiremen type Pre-Requisite (Allow Bypass)
 * ISS-002155 27-12-2024 XW - getIurMap now accepts list of req type
 * ISS-002226 06-01-2025 XW - removed Conflict and added 'enrolled completed' type
 */
global inherited sharing class IUR_Helper implements SObject_Helper {
    
    /**
     * @description Requirement Type - Pre-Requisite
     */
    public static final String REQTYPE_PREREQ = 'Pre-Requisite';

    /**
     * @description Requirement Type - Pre-Requisite (Allow Bypass)
     */
    public static final String REQTYPE_PREREQ_BYPASS = 'Pre-Requisite (Allow Bypass)';
    
    /**
     * @description Requirement Type - Enrolled or Completed
     */
    public static final String REQTYPE_ENROLLED_COMPLETED = 'Enrolled or Completed';

    /**
     * @description Requirement Type - Co-Requisite
     */
    public static final String REQTYPE_COREQ = 'Co-Requisite';
    
    
    /**
     * @description Requirement Type - Credits
     */
    public static final String REQTYPE_CREDITS = 'Credits';
    
    /**
     * @description Requirement Type - Custom
     */
    public static final String REQTYPE_CUSTOM = 'Custom';

    /**
     * @description Requirement Type - Other
     */
    public static final String REQTYPE_OTHER = 'Other';
    
    /**
     * @description Field Matching Operator - Equals
     */
    public static final String FIELDMATCHINGOP_EQUALS = 'Equals';

    /**
     * @description Field Matching Operator - Does Not Equal
     */
    public static final String FIELDMATCHINGOP_DOESNOTEQUAL = 'Does Not Equal';
    
    /**
     * @description Field Matching Operator - Greater than
     */
    public static final String FIELDMATCHINGOP_GREATER = 'Greater than';
    
    /**
     * @description Field Matching Operator - Less Than
     */
    public static final String FIELDMATCHINGOP_LESS = 'Less Than';
    
    /**
     * @description Field Matching Operator - Greater Than or Equal
     */
    public static final String FIELDMATCHINGOP_GREATEROREQUAL = 'Greater Than or Equal';
    
    /**
     * @description Field Matching Operator - Less Than or Equal
     */
    public static final String FIELDMATCHINGOP_LESSOREQUAL = 'Less Than or Equal';
    
    /**
     * @description Field Matching Operator - Is Blank
     */
    public static final String FIELDMATCHINGOP_ISBLANK = 'Is Blank';
    

	/**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel() {
        return SObjectType.reduivy__Individual_Plan_Unit_Requirement__c.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel() {
        return SObjectType.reduivy__Individual_Plan_Unit_Requirement__c.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName() {
        return SObjectType.reduivy__Individual_Plan_Unit_Requirement__c.getName();
    }

    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.reduivy__Individual_Plan_Unit_Requirement__c);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }

    /**
     * @description Get map: Individual Program Enrollment Id => List of Individual Plan Unit Requirement
     * @param ipeIdSet Set<Id> (reduivy__Individual_Program_Enrollment__c)
     * @param reqType String (REQTYPE_PREREQ | REQTYPE_COREQ | REQTYPE_CREDITS | REQTYPE_OTHER)
     * @return iurMap Map<Id, List<reduivy__Individual_Plan_Unit_Requirement__c>>
     */
    public static Map<Id, List<reduivy__Individual_Plan_Unit_Requirement__c>> getIurMap(Set<Id> ipeIdSet, Set<String> reqType) {

        Map<Id, List<reduivy__Individual_Plan_Unit_Requirement__c>> iurMap = new Map<Id, List<reduivy__Individual_Plan_Unit_Requirement__c>>();

        for (reduivy__Individual_Plan_Unit_Requirement__c iur : [
            SELECT  reduivy__Individual_Plan_Unit__c, reduivy__Individual_Plan_Unit__r.reduivy__Individual_Program_Enrollment__c, 
            reduivy__Master_Individual_Program_Enrollment_Id__c,
            reduivy__Credits__c, reduivy__Requirement_Met__c,
            reduivy__Requirement_Type__c, reduivy__Field_Name__c, reduivy__Field_Matching_Operator__c, reduivy__Field_Matching_Value__c //ISS-002155
            FROM reduivy__Individual_Plan_Unit_Requirement__c
            WHERE reduivy__Master_Individual_Program_Enrollment_Id__c IN :ipeIdSet
            AND reduivy__Requirement_Type__c IN :reqType //ISS-002155
            WITH USER_MODE
        ]) {
            if (iurMap.containsKey(iur.reduivy__Master_Individual_Program_Enrollment_Id__c)) {
                iurMap.get(iur.reduivy__Master_Individual_Program_Enrollment_Id__c).add(iur);
            } else {
                iurMap.put(iur.reduivy__Master_Individual_Program_Enrollment_Id__c, new List<reduivy__Individual_Plan_Unit_Requirement__c>{iur});
            }
        }

        return iurMap;
    }

    /**
     * @description Set the requirement met field for each of the individual plan unit requirement records
     * @param iurList List<reduivy__Individual_Plan_Unit_Requirement__c>
     */
    public static void isRequirementMet(List<reduivy__Individual_Plan_Unit_Requirement__c> iurList) {
                
        // Initialise the field values and populate the relevant lists
        List<reduivy__Individual_Plan_Unit_Requirement__c> iurPreRequisiteList = new List<reduivy__Individual_Plan_Unit_Requirement__c>();
        List<reduivy__Individual_Plan_Unit_Requirement__c> iurEnrolledCompletedList = new List<reduivy__Individual_Plan_Unit_Requirement__c>();
        List<reduivy__Individual_Plan_Unit_Requirement__c> iurCreditList = new List<reduivy__Individual_Plan_Unit_Requirement__c>();
        List<reduivy__Individual_Plan_Unit_Requirement__c> iurCustomList = new List<reduivy__Individual_Plan_Unit_Requirement__c>();
        Set<String> customFieldNameSet = new Set<String>();
        

        Set<Id> ipeIds = new Set<Id>();

        for (reduivy__Individual_Plan_Unit_Requirement__c iur : iurList) {
            if (String.isNotBlank(iur.reduivy__Master_Individual_Program_Enrollment_Id__c)) {
                if (iur.reduivy__Requirement_Type__c == REQTYPE_PREREQ || iur.reduivy__Requirement_Type__c == REQTYPE_PREREQ_BYPASS) { //ISS-002144
                    iur.reduivy__Credits__c = null;
                    iur.reduivy__Other__c = null;
                    iur.reduivy__Field_Name__c = null;
                    iur.reduivy__Field_Matching_Operator__c = null;
                    iur.reduivy__Field_Matching_Value__c = null;
                    iurPreRequisiteList.add(iur);

                } else if (iur.reduivy__Requirement_Type__c == REQTYPE_COREQ) {
                    iur.reduivy__Credits__c = null;
                    iur.reduivy__Other__c = null;
                    iur.reduivy__Field_Name__c = null;
                    iur.reduivy__Field_Matching_Operator__c = null;
                    iur.reduivy__Field_Matching_Value__c = null;
                    iur.reduivy__Requirement_Met__c = true;

                } else if (iur.reduivy__Requirement_Type__c == REQTYPE_ENROLLED_COMPLETED) {
                    iur.reduivy__Credits__c = null;
                    iur.reduivy__Other__c = null;
                    iur.reduivy__Field_Name__c = null;
                    iur.reduivy__Field_Matching_Operator__c = null;
                    iur.reduivy__Field_Matching_Value__c = null;
                    iurEnrolledCompletedList.add(iur);

                } else if (iur.reduivy__Requirement_Type__c == REQTYPE_CREDITS) {
                    iur.reduivy__Required_Study_Unit__c = null;
                    iur.reduivy__Other__c = null;
                    iur.reduivy__Field_Name__c = null;
                    iur.reduivy__Field_Matching_Operator__c = null;
                    iur.reduivy__Field_Matching_Value__c = null;
                    iurCreditList.add(iur);

                } else if (iur.reduivy__Requirement_Type__c == REQTYPE_OTHER) {
                    iur.reduivy__Required_Study_Unit__c = null;
                    iur.reduivy__Credits__c = null;
                    iur.reduivy__Field_Name__c = null;
                    iur.reduivy__Field_Matching_Operator__c = null;
                    iur.reduivy__Field_Matching_Value__c = null;

                } else if (iur.reduivy__Requirement_Type__c == REQTYPE_CUSTOM) { //ISS-002155
                    iur.reduivy__Required_Study_Unit__c = null;
                    iur.reduivy__Credits__c = null;
                    iur.reduivy__Other__c = null;
                    if(String.isNotBlank(iur.reduivy__Field_Name__c) && String.isNotBlank(iur.reduivy__Field_Matching_Operator__c)) {
                        iurCustomList.add(iur);
                        customFieldNameSet.add(iur.reduivy__Field_Name__c);
                    }

                }

                ipeIds.add(iur.reduivy__Master_Individual_Program_Enrollment_Id__c);

            }
        }

        // Pre-Requisities and/or Co-Requisities and/or "Enrolled or complete" and/or Credits and/or Custom (ISS-002155)
        if ((!iurPreRequisiteList.isEmpty()) || (!iurEnrolledCompletedList.isEmpty()) || (!iurCreditList.isEmpty()) || (!iurCustomList.isEmpty())) {
            
            if (!ipeIds.isEmpty()) {

                // Individual enrollment and grade result statuses
                List<String> ipsuStatusCompleted = IPS_Helper.getUnitCompletedStatuses();
                List<String> ipsuStatusInProgress = IPS_Helper.getUnitInProgressStatuses();

                Set<String> ipsuStatuses = new Set<String>();
                ipsuStatuses.addAll(ipsuStatusCompleted);
                ipsuStatuses.addAll(ipsuStatusInProgress);

                Map<String, reduivy__Individual_Plan_Structure__c> inProgressIpsuByIpeSunMap = new Map<String, reduivy__Individual_Plan_Structure__c>();
                Map<String, reduivy__Individual_Plan_Structure__c> completedIpsuByIpeSunMap = new Map<String, reduivy__Individual_Plan_Structure__c>();
                Map<Id, Decimal> ipeCreditsMap = new Map<Id, Decimal>();
                

                for (reduivy__Individual_Plan_Structure__c ipsu : [SELECT  Id, reduivy__Status__c,
                    reduivy__Target_Unit_Id__c,
                    reduivy__Individual_Program_Enrollment__c,
                    reduivy__Individual_Program_Enrollment__r.reduivy__Master_Enrollment__c,
                    reduivy__Individual_Program_Enrollment__r.reduivy__Credits_Earned__c
                    FROM reduivy__Individual_Plan_Structure__c
                    WHERE (reduivy__Individual_Program_Enrollment__c IN :ipeIds
                    OR reduivy__Individual_Program_Enrollment__r.reduivy__Master_Enrollment__c IN :ipeIds)
                    AND RecordTypeId =: IPS_Helper.getUnitRecordTypeId()
                    WITH USER_MODE
                ]) {
                    String ipeSunKey;
                    if(ipsu.reduivy__Individual_Program_Enrollment__c != null && ipsu.reduivy__Individual_Program_Enrollment__r.reduivy__Master_Enrollment__c != null){
                        ipeSunKey = ipsu.reduivy__Individual_Program_Enrollment__r.reduivy__Master_Enrollment__c + '_' + ipsu.reduivy__Target_Unit_Id__c;
                    }else{
                        ipeSunKey = ipsu.reduivy__Individual_Program_Enrollment__c + '_' + ipsu.reduivy__Target_Unit_Id__c;
                    }

                    if (ipsuStatusInProgress.contains(ipsu.reduivy__Status__c) && !inProgressIpsuByIpeSunMap.containsKey(ipeSunKey)) {
                        inProgressIpsuByIpeSunMap.put(ipeSunKey, ipsu);

                    } else if (ipsuStatusCompleted.contains(ipsu.reduivy__Status__c) && !completedIpsuByIpeSunMap.containsKey(ipeSunKey)) {
                        completedIpsuByIpeSunMap.put(ipeSunKey, ipsu);

                    }

                    if (!ipeCreditsMap.containsKey(ipsu.reduivy__Individual_Program_Enrollment__c)) {
                        ipeCreditsMap.put(ipsu.reduivy__Individual_Program_Enrollment__c, (ipsu.reduivy__Individual_Program_Enrollment__r.reduivy__Credits_Earned__c == null ? 0 : ipsu.reduivy__Individual_Program_Enrollment__r.reduivy__Credits_Earned__c));
                    }
                }                

                // Pre-Requisities
                if (!iurPreRequisiteList.isEmpty()) {
                    for (reduivy__Individual_Plan_Unit_Requirement__c iur : iurPreRequisiteList) {
                        
                        String ipeSunKey = iur.reduivy__Master_Individual_Program_Enrollment_Id__c + '_' + iur.reduivy__Required_Study_Unit__c;
                        if (completedIpsuByIpeSunMap.containsKey(ipeSunKey)) {
                            iur.reduivy__Requirement_Met__c = true;
                        } else {
                            iur.reduivy__Requirement_Met__c = false;
                        }
                    }
                }

                // Pre-Requisities (Enrolled / Completed) ISS-002226
                if (!iurEnrolledCompletedList.isEmpty()){
                    
                    for (reduivy__Individual_Plan_Unit_Requirement__c iur : iurEnrolledCompletedList) {

                        String ipeSunKey = iur.reduivy__Master_Individual_Program_Enrollment_Id__c + '_' + iur.reduivy__Required_Study_Unit__c;
                        if(completedIpsuByIpeSunMap.containsKey(ipeSunKey) || inProgressIpsuByIpeSunMap.containsKey(ipeSunKey)){
                            iur.reduivy__Requirement_Met__c = true;
                        } else {
                            iur.reduivy__Requirement_Met__c = false;
                        }
                    }
                }

                // Credits
                if (!iurCreditList.isEmpty()) {
                    for (reduivy__Individual_Plan_Unit_Requirement__c iur : iurCreditList) {
                        if (ipeCreditsMap.containsKey(iur.reduivy__Master_Individual_Program_Enrollment_Id__c) && ipeCreditsMap.get(iur.reduivy__Master_Individual_Program_Enrollment_Id__c) >= iur.reduivy__Credits__c) {
                            iur.reduivy__Requirement_Met__c = true;
                        } else {
                            iur.reduivy__Requirement_Met__c = false;
                        }
                    }
                }

                // ISS-002155 Custom
                if(!iurCustomList.isEmpty()) {
                    Map<Id, reduivy__Individual_Program_Enrollment__c> ipeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>();
                    
                    String query = 'SELECT ' + String.join(customFieldNameSet, ',') + ' FROM reduivy__Individual_Program_Enrollment__c WHERE Id IN :ipeIds';
                    Map<String, Object> bindMap = new Map<String, Object>{'ipeIds' => ipeIds};
                    for(reduivy__Individual_Program_Enrollment__c ipe : 
                    (List<reduivy__Individual_Program_Enrollment__c>) Database.queryWithBinds(query, bindMap, AccessLevel.USER_MODE)){
                        ipeMap.put(ipe.Id, ipe);
                    }
                    
                    Schema.DescribeSObjectResult ipeDescribeSObjectResult = REDU_Metadata_UTIL.describeSObject(IPE_Helper.getApiName());
                    Map<String, Schema.SObjectField> ipeFieldMap = ipeDescribeSObjectResult.fields.getMap();
                    for(reduivy__Individual_Plan_Unit_Requirement__c iur : iurCustomList) {
                        if(ipeMap.containsKey(iur.reduivy__Master_Individual_Program_Enrollment_Id__c)) {
                            reduivy__Individual_Program_Enrollment__c ipe = ipeMap.get(iur.reduivy__Master_Individual_Program_Enrollment_Id__c);
                            
                            Schema.DescribeFieldResult fieldResult = ipeFieldMap.get(iur.reduivy__Field_Name__c).getDescribe();
                            
                            Object actualValue = ipe.get(iur.reduivy__Field_Name__c);
                            String operator = iur.reduivy__Field_Matching_Operator__c;
                            String expectedValue = iur.reduivy__Field_Matching_Value__c;
                            
                            try{
                                Boolean result = REDU_MatchingOperator_UTIL.calculate(fieldResult.getType(), actualValue, operator, expectedValue);
                                iur.reduivy__Requirement_Met__c = result;
                            } catch(Exception exp) {
                                String errorMessage = REDU_MatchingOperator_UTIL.getErrorMessage(exp.getMessage(), operator, IUR_Helper.getApiName(), iur.reduivy__Field_Name__c);
                                throw new REDU_ApplicationException(errorMessage);
                            }
                        }
                    }
                }
            }
        }
    }

    /**
     * @description Init a study plan unit requirement
     * @param studyPlanUnitId
     * @param reqStudyUnitId
     * @param reqID
     * @param reqType
     * @param customFieldName
     * @param matchingOperator
     * @param matchingValue
     * @return reduivy__Study_Plan_Unit_Requirement__c
     */
    @NamespaceAccessible
    public static reduivy__Study_Plan_Unit_Requirement__c convertIurToSpr(Id studyPlanUnitId, Id reqStudyUnitId, String reqID, String reqType, String customFieldName, String matchingOperator, String matchingValue, Decimal credits) { //ISS-002155

        reduivy__Study_Plan_Unit_Requirement__c spur = new reduivy__Study_Plan_Unit_Requirement__c(
            Name = studyPlanUnitId + '_' + reqID + '_' + reqType,
            reduivy__Study_Plan_Unit__c = studyPlanUnitId,
            reduivy__Requirement_ID__c = reqID,
            reduivy__Requirement_Type__c = reqType,
            reduivy__Required_Study_Unit__c = reqStudyUnitId,
            reduivy__Field_Name__c = customFieldName,
            reduivy__Field_Matching_Operator__c = matchingOperator,
            reduivy__Field_Matching_Value__c = matchingValue,
            reduivy__Credits__c = credits
        );

        return spur;
    }
}