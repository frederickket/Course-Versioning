/**
 * @author      WDCi (dblack)
 * @date        Oct 2023
 * @group       Trigger executable
 * @description Individual program enrollment generation: Set the default values
 * @changehistory
 * ISS-001662 04-10-2023 dblack - new class
 * ISS-002487 30-06-2025 XiRouh - added condition to only process 'Master Enrollment' record and populate class year, cohort id, study plan option type if it is blank
 */
public inherited sharing class IPE_DefaultValues_EXE extends REDU_TriggerExecutable {

    /**
     * @description Individual Program Enrollment Master Record Type Id
     */
    private static final Id IPE_MASTER_RECORDTYPE_ID = IPE_Helper.getMasterEnrollmentRecordTypeId();

	/**
     * @description BeforeInsert: Set the default values on individual program enrollment upon insert
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeBeforeInsert(
        System.TriggerOperation operationType, 
        List<SObject> newList, Map<Id, SObject> newMap, 
        List<SObject> oldList, Map<Id, SObject> oldMap, 
        Schema.DescribeSObjectResult sobjResult) {

        if ((operationType == TriggerOperation.BEFORE_INSERT) && 
            REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)
        ) {

            List<reduivy__Individual_Program_Enrollment__c> ipeList = new List<reduivy__Individual_Program_Enrollment__c>();    
            for (reduivy__Individual_Program_Enrollment__c ipe : (List<reduivy__Individual_Program_Enrollment__c>) newList) {
                if (ipe.RecordTypeId == IPE_MASTER_RECORDTYPE_ID && 
                    (String.isNotBlank(ipe.reduivy__Study_Program__c)) && 
                    (
                        (String.isBlank(ipe.reduivy__Study_Plan__c)) || 
                        (String.isBlank(ipe.reduivy__Default_Campus__c)) || 
                        (String.isBlank(ipe.reduivy__Study_Pathway__c)) || 
                        (String.isBlank(ipe.reduivy__Starting_Term__c)) ||
                        (String.isBlank(ipe.reduivy__Study_Plan_Option_Type__c)) ||
                        (
                            String.isNotBlank(ipe.reduivy__Study_Intake__c) && 
                            ((String.isBlank(ipe.reduivy__Cohort_ID__c)) || (String.isBlank(ipe.reduivy__Class_Year__c)))
                        )
                    )
                ) {
                    ipeList.add(ipe);
                }
            }
            if (!ipeList.isEmpty()) {

                Map<Id, reduivy__Study_Intake__c> sitMap = new Map<Id, reduivy__Study_Intake__c>();
                Map<Id, reduivy__Study_Plan__c> splMap = new Map<Id, reduivy__Study_Plan__c>();
                Map<Id, reduivy__Study_Plan__c> spgDefaultSplMap = new Map<Id, reduivy__Study_Plan__c>();

                // Assign the source of the default field values: study intake or study plan or study program
                for (reduivy__Individual_Program_Enrollment__c ipe : ipeList) {
                    if (String.isNotBlank(ipe.reduivy__Study_Intake__c)) {
                        sitMap.put(ipe.reduivy__Study_Intake__c, null);
                    } else if (String.isNotBlank(ipe.reduivy__Study_Plan__c)) {
                        splMap.put(ipe.reduivy__Study_Plan__c, null);
                    } else {
                        spgDefaultSplMap.put(ipe.reduivy__Study_Program__c, null);
                    }
                }
                // Get the study intake records
                if (!sitMap.isEmpty()) {
                    sitMap = new Map<Id, reduivy__Study_Intake__c>([
                        SELECT  Id, reduivy__Default_Study_Plan__c, reduivy__Default_Study_Pathway__c, reduivy__Class_Year__c, reduivy__Cohort_ID__c,
                                reduivy__Academic_Term__c, reduivy__Campus__c, reduivy__Default_Study_Plan__r.reduivy__Type__c
                        FROM reduivy__Study_Intake__c
                        WHERE Id IN :sitMap.keySet()
                        WITH USER_MODE
                    ]);
                }
                // Get the study plan records
                if ((!splMap.isEmpty()) || (!spgDefaultSplMap.isEmpty())) {
                    splMap = new Map<Id, reduivy__Study_Plan__c>([
                        SELECT  Id, reduivy__Study_Program__c, reduivy__Default__c, reduivy__Type__c,
                                (SELECT Id FROM reduivy__Study_Pathways__r WHERE reduivy__Default__c = true AND reduivy__Status__c =: SPW_Helper.STATUS_ACTIVE)
                        FROM reduivy__Study_Plan__c
                        WHERE Id IN :splMap.keySet()
                        OR (reduivy__Default__c = true AND reduivy__Study_Program__c IN: spgDefaultSplMap.keySet())
                        WITH USER_MODE
                    ]);
                    for (reduivy__Study_Plan__c spl : splMap.values()) {
                        if ((spl.reduivy__Default__c) && (spgDefaultSplMap.containsKey(spl.reduivy__Study_Program__c))) {
                            spgDefaultSplMap.put(spl.reduivy__Study_Program__c, spl);
                        }
                    }
                }

                // Populate the individual program enrollment records with the default values
                for (reduivy__Individual_Program_Enrollment__c ipe : ipeList) {
                    if (sitMap.containsKey(ipe.reduivy__Study_Intake__c)) {

                        // Populate default values from the related study intake record
                        reduivy__Study_Intake__c sit = sitMap.get(ipe.reduivy__Study_Intake__c);
                        if (String.isBlank(ipe.reduivy__Study_Plan__c)) {
                            ipe.reduivy__Study_Plan__c = sit.reduivy__Default_Study_Plan__c;
                        }
                        if (String.isBlank(ipe.reduivy__Study_Pathway__c)) {
                            ipe.reduivy__Study_Pathway__c = sit.reduivy__Default_Study_Pathway__c;
                        }
                        if (String.isBlank(ipe.reduivy__Starting_Term__c)) {
                            ipe.reduivy__Starting_Term__c = sit.reduivy__Academic_Term__c;
                        }
                        if (String.isBlank(ipe.reduivy__Default_Campus__c)) {
                            ipe.reduivy__Default_Campus__c = sit.reduivy__Campus__c;
                        }
                        if (String.isBlank(ipe.reduivy__Class_Year__c)) {
                            ipe.reduivy__Class_Year__c = sit.reduivy__Class_Year__c;
                        }
                        if (String.isBlank(ipe.reduivy__Cohort_ID__c)) {
                            ipe.reduivy__Cohort_ID__c = sit.reduivy__Cohort_ID__c;
                        }
                        if (String.isBlank(ipe.reduivy__Study_Plan_Option_Type__c)) {
                            ipe.reduivy__Study_Plan_Option_Type__c = sit.reduivy__Default_Study_Plan__r.reduivy__Type__c;
                        }
                    } else {
                        // Populate default values from the related study plan record
                        reduivy__Study_Plan__c spl;
                        if (splMap.containsKey(ipe.reduivy__Study_Plan__c)) {
                            spl = splMap.get(ipe.reduivy__Study_Plan__c);
                        } else if (spgDefaultSplMap.containsKey(ipe.reduivy__Study_Program__c)) {
                            spl = spgDefaultSplMap.get(ipe.reduivy__Study_Program__c);
                        }
                        if (spl != null) {
                            if (String.isBlank(ipe.reduivy__Study_Plan__c)) {
                                ipe.reduivy__Study_Plan__c = spl.Id;                                
                            }
                            if ((String.isBlank(ipe.reduivy__Study_Pathway__c)) && 
                                (!spl.reduivy__Study_Pathways__r.isEmpty())) {
                                ipe.reduivy__Study_Pathway__c = spl.reduivy__Study_Pathways__r.get(0).Id;
                            }
                            if (String.isBlank(ipe.reduivy__Study_Plan_Option_Type__c)) {
                                ipe.reduivy__Study_Plan_Option_Type__c = spl.reduivy__Type__c;
                            }
                        }
                    }
                }
            }
        }
    }
}