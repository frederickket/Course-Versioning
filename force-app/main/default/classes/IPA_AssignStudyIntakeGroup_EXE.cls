/**
 * @author      WDCi (XW)
 * @date        July 2025
 * @group       Study Intake Group
 * @description link IPA to Study Intake group
 * @changehistory
 * ISS-002526 11-07-2025 XW - new class
 */

public inherited sharing class IPA_AssignStudyIntakeGroup_EXE extends REDU_TriggerExecutable {
    
	/**
     * @description BeforeInsert
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeBeforeInsert(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {
        
        if (REDU_AppSetting_UTIL.isUsingStudyIntakeGroup() && REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {

            List<reduivy__Individual_Program_Application__c> workingList = new List<reduivy__Individual_Program_Application__c>();
            List<reduivy__Individual_Program_Application__c> errorList = new List<reduivy__Individual_Program_Application__c>();

            for (reduivy__Individual_Program_Application__c ipaNew : (List<reduivy__Individual_Program_Application__c>) newList) {
                Boolean isValid = isValid(ipaNew);

                if(isValid == true) {
                    workingList.add(ipaNew);
                } else if (isValid == false) {
                    errorList.add(ipaNew);
                }
            }

            if(!errorList.isEmpty()) {
                setError(errorList);
                return;
            }

            if(!workingList.isEmpty()) {
                assignStudyIntakeGroups(workingList);
            }
        }
    }

    /**
     * @description BeforeUpdate
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeBeforeUpdate(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        if (REDU_AppSetting_UTIL.isUsingStudyIntakeGroup() && REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {

            List<reduivy__Individual_Program_Application__c> workingList = new List<reduivy__Individual_Program_Application__c>();
            List<reduivy__Individual_Program_Application__c> errorList = new List<reduivy__Individual_Program_Application__c>();

            for (reduivy__Individual_Program_Application__c ipaNew : (List<reduivy__Individual_Program_Application__c>) newList) {
                reduivy__Individual_Program_Application__c ipaOld = (reduivy__Individual_Program_Application__c) oldMap.get(ipaNew.Id);

                if (
                    ipaNew.reduivy__Study_Intake_Group_Assignment__c != ipaOld.reduivy__Study_Intake_Group_Assignment__c || 
                    ipaNew.reduivy__Student_Group_Type__c != ipaOld.reduivy__Student_Group_Type__c
                ) {
                    Boolean isValid = isValid(ipaNew);

                    if(isValid == true) {
                        workingList.add(ipaNew);
                    } else if (isValid == false) {
                        errorList.add(ipaNew);
                    }
                }
            }

            if(!errorList.isEmpty()) {
                setError(errorList);
                return;
            }

            if(!workingList.isEmpty()) {
                assignStudyIntakeGroups(workingList);
            }
        }
    }
	
    /**
     * @description assign the study intake group to the valid ipa
     * @param ipaList
     * @return void
     */
    private void assignStudyIntakeGroups(List<reduivy__Individual_Program_Application__c> ipaList) {

        Set<Id> studyIntakeIdSet = new Set<Id>();
        Set<String> studentGroupTypeSet = new Set<String>();
        for(reduivy__Individual_Program_Application__c ipa : ipaList) {
            if(String.isNotBlank(ipa.reduivy__Study_Intake__c)) {
                studyIntakeIdSet.add(ipa.reduivy__Study_Intake__c);
            }
            
            if(String.isNotBlank(ipa.reduivy__Student_Group_Type__c)) {
                studentGroupTypeSet.add(ipa.reduivy__Student_Group_Type__c);
            }
        }

        //find the study intake group
        Map<String, reduivy__Study_Intake_Group__c> sitIdTypeTosigMap = new Map<String, reduivy__Study_Intake_Group__c>();
        Map<Id, reduivy__Study_Intake_Group__c> defaultSigMap = new Map<Id, reduivy__Study_Intake_Group__c>();
        for(reduivy__Study_Intake_Group__c sig : [
            SELECT Id,
            Name,
            reduivy__Study_Intake__c,
            reduivy__Default__c,
            reduivy__Student_Group_Type__c
            FROM reduivy__Study_Intake_Group__c
            WHERE reduivy__Study_Intake__c IN :studyIntakeIdSet
            AND reduivy__Status__c = :SIG_Helper.STATUS_ACTIVE
            AND (
                reduivy__Student_Group_Type__c IN :studentGroupTypeSet OR
                reduivy__Default__c = true
            )
            WITH USER_MODE
        ]) {
            String identifier = getSigIdentifier(sig.reduivy__Study_Intake__c, sig.reduivy__Student_Group_Type__c);
            if(!sitIdTypeTosigMap.containsKey(identifier)) {
                sitIdTypeTosigMap.put(identifier, sig);
            }

            if(sig.reduivy__Default__c) {
                defaultSigMap.put(sig.reduivy__Study_Intake__c, sig);
            }
        }

        //set the group based on reduivy__Student_Group_Type__c and reduivy__Study_Intake_Group_Assignment__c
        for(reduivy__Individual_Program_Application__c ipa : ipaList) {

            //directly set sig field if reduivy__Student_Group_Type__c is set
            if(String.isNotBlank(ipa.reduivy__Student_Group_Type__c)) {
                String sigIdentifier = getSigIdentifier(ipa.reduivy__Study_Intake__c, ipa.reduivy__Student_Group_Type__c);

                if(sitIdTypeTosigMap.containsKey(sigIdentifier)){
                    reduivy__Study_Intake_Group__c sigToLink = sitIdTypeTosigMap.get(sigIdentifier);
                        
                    //set the study intake group when either met:
                    if(
                        (
                            //if assignment is auto and study intake group field is different from the study intake group to be linked
                            ipa.reduivy__Study_Intake_Group_Assignment__c == IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO &&
                            ipa.reduivy__Study_Intake_Group__c != sigToLink.Id
                        ) ||
                        (
                            //if assignment is manual and the study intake group field is empty
                            ipa.reduivy__Study_Intake_Group_Assignment__c == IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_MANUAL &&
                            String.isBlank(ipa.reduivy__Study_Intake_Group__c)
                        )
                    ) {
                        ipa.reduivy__Study_Intake_Group__c = sigToLink.Id;
                    }
                } else {
                    //set to default if type is not found and is auto
                    if(defaultSigMap.containsKey(ipa.reduivy__Study_Intake__c) && ipa.reduivy__Study_Intake_Group_Assignment__c == IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO) {
                        reduivy__Study_Intake_Group__c sigToLink = defaultSigMap.get(ipa.reduivy__Study_Intake__c);
                        ipa.reduivy__Study_Intake_Group__c = sigToLink.Id;
                    } else  {   
                        //throw error if no matching sig is found and no default sig is found
                        String errorMsg = String.format(Label.Error_No_Matching_SIG, new List<String>{
                            SIG_Helper.getObjectLabel(), 
                            SObjectType.reduivy__Study_Intake_Group__c.fields.reduivy__Student_Group_Type__c.getLabel()
                        });
                        
                        ipa.addError(errorMsg);
                    }
                }
            }
            //find the default if reduivy__Student_Group_Type__c is not set and is auto
            else if(String.isBlank(ipa.reduivy__Student_Group_Type__c) && ipa.reduivy__Study_Intake_Group_Assignment__c == IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO) {
                if(defaultSigMap.containsKey(ipa.reduivy__Study_Intake__c)) {
                    reduivy__Study_Intake_Group__c sigToLink = defaultSigMap.get(ipa.reduivy__Study_Intake__c);
                    ipa.reduivy__Study_Intake_Group__c = sigToLink.Id;
                    ipa.reduivy__Student_Group_Type__c = sigToLink.reduivy__Student_Group_Type__c;
                } else {
                    //throw error if no default sig is found
                    String errorMsg = String.format(Label.Error_No_Default_SIG, new List<String> {
                        SIG_Helper.getObjectLabel()
                    });

                    ipa.addError(errorMsg);
                    
                }
            }

            //booked places check is performed in rollup class
        }

        
    }

    /**
     * @description return validity of the ipa to be assigned for a study intake group
     */
    private Boolean isValid(reduivy__Individual_Program_Application__c ipaNew) {
        //return false if group type is not set and group assignment is manual (add error)
        if(
            String.isBlank(ipaNew.reduivy__Student_Group_Type__c) && 
            ipaNew.reduivy__Study_Intake_Group_Assignment__c == IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_MANUAL
        ) {
            //error is added if the ipa study group type is not specified, and the assignnent is Manual
            return false;
        }
        //return true if study intake is set and either assignment is auto, or group type is set
        else if(
            String.isNotBlank(ipaNew.reduivy__Study_Intake__c) && (
                String.isNotBlank(ipaNew.reduivy__Student_Group_Type__c) || 
                ipaNew.reduivy__Study_Intake_Group_Assignment__c == IPA_Helper.STUDY_INTAKE_GROUP_ASSIGNMENT_AUTO
            )
        ) {
            //sig is linked if the study intake field is populated, and either the student group type is specified, or the assignment is auto
            return true;
        }

        //we skip the assignment to the study intake group for the rest of the ipa
        return null;
    }


    /**
     * @description set error to the invalid ipa
     */
    private void setError(List<reduivy__Individual_Program_Application__c> errorRecords) {
        String errorMsg = String.format(Label.Error_No_Matching_SIG, new List<String>{
            SIG_Helper.getObjectLabel(), 
            SObjectType.reduivy__Study_Intake_Group__c.fields.reduivy__Student_Group_Type__c.getLabel()
        });
        
        for(reduivy__Individual_Program_Application__c ipa : errorRecords) {
            ipa.addError(errorMsg);
        }
    }

    
    /**
     * @description get the sig identifier from its sit id and group type
     */
    private String getSigIdentifier(Id sitId, String studentGroupType) {
        return sitId + '_' + studentGroupType;
    }
}