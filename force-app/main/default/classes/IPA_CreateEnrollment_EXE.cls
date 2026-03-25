/**
 * @author      WDCi (XiRouh)
 * @date        June 2025
 * @group       
 * @description Create Individual Program Enrollments when the Individual Program Application is updated to a status that triggers enrollment creation, as defined in custom metadata
 * @changehistory
 * ISS-002487 13-06-2025 XiRouh - new class
 */
public inherited sharing class IPA_CreateEnrollment_EXE extends REDU_TriggerExecutable {

    /**
     * @description Individual Program Application Create IPE Statuses with IPE Status
     */
    private static final Map<String, String> IPA_CREATE_IPE_STATUSES_WITH_IPE_STATUS = IPA_Helper.getCreateIpeStatusWithIpeEnrollmentStatus();

    /**
    * @description Individual program enrollment in-progress statuses
    */
    private static final List<String> IPE_INPROGRESS_STATUSES = IPE_Helper.getInProgressStatuses();

    /**
    * @description Individual program enrollment child record type id
    */
    private static final String IPE_CHILD_RECORD_TYPE_ID = IPE_Helper.getChildEnrollmentRecordTypeId();

    /**
    * @description Individual program enrollment master record type id
    */
    private static final String IPE_MASTER_RECORD_TYPE_ID = IPE_Helper.getMasterEnrollmentRecordTypeId();

    /**
     * @description AfterInsert
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeAfterInsert(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.ADMIN)) {

            Map<Id, reduivy__Individual_Program_Application__c> workingMap = new Map<Id, reduivy__Individual_Program_Application__c>();

            Set<String> applicableIpaStatuses = IPA_CREATE_IPE_STATUSES_WITH_IPE_STATUS.keySet();

            for (reduivy__Individual_Program_Application__c objNew : (List<reduivy__Individual_Program_Application__c>) newList) {
                if(String.isNotBlank(objNew.reduivy__Application_Status__c) && applicableIpaStatuses.contains(objNew.reduivy__Application_Status__c)) {
                    workingMap.put(objNew.Id, objNew);                  
                }
            }

            if(!workingMap.isEmpty()) {
                createEnrollment(workingMap);
            }
        }
    }

    /**
     * @description AfterUpdate
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeAfterUpdate(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.ADMIN)) {

            Map<Id, reduivy__Individual_Program_Application__c> workingMap = new Map<Id, reduivy__Individual_Program_Application__c>();

            Set<String> applicableIpaStatuses = IPA_CREATE_IPE_STATUSES_WITH_IPE_STATUS.keySet();

            for (reduivy__Individual_Program_Application__c objNew : (List<reduivy__Individual_Program_Application__c>) newList) {
                reduivy__Individual_Program_Application__c objOld = (reduivy__Individual_Program_Application__c) oldMap.get(objNew.Id);

                if (String.isNotBlank(objNew.reduivy__Application_Status__c) && applicableIpaStatuses.contains(objNew.reduivy__Application_Status__c) && !applicableIpaStatuses.contains(objOld.reduivy__Application_Status__c)) {
                    workingMap.put(objNew.Id, objNew);
                }
            }

            if(!workingMap.isEmpty()) {
                createEnrollment(workingMap);
            }
        }
    }

    /**
     * @description To create an individual program enrollment based on the values from the individual program application
     * @param Map<Id, reduivy__Individual_Program_Application__c> ipaMap
     * @return void
     */
    private void createEnrollment (Map<Id, reduivy__Individual_Program_Application__c> ipaMap) {

        Set<Id> invalidIpaIds = new Set<Id>();

        //Check whether the IPA has any existing IPEs linked to it
        for(reduivy__Individual_Program_Enrollment__c ipe : [
            SELECT Id, 
                reduivy__Individual_Program_Application__c,
                reduivy__Individual_Program_Application__r.Name
            FROM reduivy__Individual_Program_Enrollment__c 
            WHERE reduivy__Individual_Program_Application__c IN :ipaMap.keySet()
            WITH USER_MODE
        ]) {
            reduivy__Individual_Program_Application__c ipa = ipaMap.get(ipe.reduivy__Individual_Program_Application__c);

            String errorMsg = String.format(Label.Existing_IPE_Found, 
                            new List<String>{IPA_Helper.getObjectPluralLabel(), ipa.Name, IPE_Helper.getObjectPluralLabel()});

            ipa.addError(errorMsg);

            invalidIpaIds.add(ipe.reduivy__Individual_Program_Application__c);
        }

        if (!invalidIpaIds.isEmpty()) {
            for (Id invalidId : invalidIpaIds) {
                ipaMap.remove(invalidId);
            }
        }

        if(!ipaMap.isEmpty()) {
            Set<Id> masterPlanIds = new Set<Id>();
            Set<Id> studyProgramIds = new Set<Id>();
            Set<Id> childPlanIds = new Set<Id>();

            //Re-querying IPA as we need fields related to the Study Intake. 
            //not querying Study Intakes directly because we also need to collecy the Study Program and Master Plan IDs.
            //Re-querying IPA allows us to do this in one go, instead of using two separate loops.
            Map<Id, reduivy__Individual_Program_Application__c> newIpaMap = new Map<Id, reduivy__Individual_Program_Application__c>();

            for(reduivy__Individual_Program_Application__c ipa : [
                SELECT Id,
                    Name,
                    reduivy__Application_Status__c,
                    reduivy__Contact__c,
                    reduivy__Study_Program__c,
                    reduivy__Master_Study_Plan__c,
                    reduivy__Master_Study_Plan__r.reduivy__Type__c,
                    reduivy__Study_Intake__c,
                    reduivy__Study_Intake__r.reduivy__Class_Year__c,
                    reduivy__Study_Intake__r.reduivy__Cohort_ID__c,
                    reduivy__Study_Intake__r.reduivy__Campus__c,
                    reduivy__Study_Intake__r.reduivy__Default_Study_Plan__c,
                    reduivy__Study_Intake__r.reduivy__Default_Study_Plan__r.reduivy__Type__c,
                    reduivy__Study_Intake__r.reduivy__Default_Study_Pathway__c,
                    reduivy__Study_Mode__c,
                    reduivy__Default_Campus__c,
                    reduivy__Study_Pathway__c,
                    reduivy__Secondary_Study_Plan__c
                FROM reduivy__Individual_Program_Application__c
                WHERE Id IN :ipaMap.keySet()
                WITH USER_MODE
            ]) {
                newIpaMap.put(ipa.Id, ipa);

                //We will use the default study plan and study pathway from the study program only if both the master study plan and study intake are blank
                if(String.isNotBlank(ipa.reduivy__Study_Program__c)) {
                    if(String.isBlank(ipa.reduivy__Master_Study_Plan__c) && 
                        String.isBlank(ipa.reduivy__Study_Intake__c)
                    ) {
                        studyProgramIds.add(ipa.reduivy__Study_Program__c);
                    }
                }

                if(String.isNotBlank(ipa.reduivy__Master_Study_Plan__c)) {
                    masterPlanIds.add(ipa.reduivy__Master_Study_Plan__c);
                }
                
                if(String.isNotBlank(ipa.reduivy__Study_Intake__c) && String.isNotBlank(ipa.reduivy__Study_Intake__r.reduivy__Default_Study_Plan__c)) {
                    masterPlanIds.add(ipa.reduivy__Study_Intake__r.reduivy__Default_Study_Plan__c);
                }

                if(String.isNotBlank(ipa.reduivy__Secondary_Study_Plan__c)) {
                    childPlanIds.add(ipa.reduivy__Secondary_Study_Plan__c);
                }
            }

            //Study program Id, Related Default Study Plan Record
            Map<Id, reduivy__Study_Plan__c> defaultStudyPlanByStudyProgram = new Map<Id, reduivy__Study_Plan__c>();
            //Study Plan Id, Study Plan Record
            Map<Id, reduivy__Study_Plan__c> studyPlanByStudyPlanId = new Map<Id, reduivy__Study_Plan__c>();
            //Master Study Plan Id|Child Study Plan Id, Completion Requirement
            Map<String, String> completionRequirementMap = new Map<String, String>();

            for (reduivy__Study_Plan__c spl : [
                SELECT Id, reduivy__Type__c, reduivy__Study_Program__c,
                    (
                        SELECT Id
                        FROM reduivy__Study_Pathways__r
                        WHERE reduivy__Status__c = :SPW_Helper.STATUS_ACTIVE
                        AND reduivy__Default__c = true
                        LIMIT 1
                    ),
                    (
                        SELECT Id,
                            reduivy__Master_Study_Plan__c,
                            reduivy__Child_Study_Plan__c,
                            reduivy__Completion_Requirement__c
                        FROM reduivy__Child_Study_Plan_Options__r
                        WHERE reduivy__Status__c = :SPO_Helper.STATUS_ACTIVE
                        AND reduivy__Child_Study_Plan__c IN :childPlanIds
                    )
                FROM reduivy__Study_Plan__c
                WHERE Id IN :masterPlanIds
                OR (
                    reduivy__Study_Program__c IN :studyProgramIds
                    AND reduivy__Default__c = true
                    AND reduivy__Status__c = :SPL_Helper.STATUS_ACTIVE
                )
                WITH USER_MODE
            ]) {
                if(!masterPlanIds.contains(spl.Id) && String.isNotBlank(spl.reduivy__Study_Program__c)) {
                    defaultStudyPlanByStudyProgram.put(spl.reduivy__Study_Program__c, spl);
                }

                if(masterPlanIds.contains(spl.Id)) {
                    studyPlanByStudyPlanId.put(spl.Id, spl);
                }

                for(reduivy__Study_Plan_Option__c spo : spl.reduivy__Child_Study_Plan_Options__r) {
                    if(String.isNotBlank(spo.reduivy__Child_Study_Plan__c)) {
                        String tempMasterStudyPlan = String.isNotBlank(spo.reduivy__Master_Study_Plan__c) ? spo.reduivy__Master_Study_Plan__c :'-';
                        String tempChildStudyPlan = spo.reduivy__Child_Study_Plan__c;

                        String key = tempMasterStudyPlan + '|' + tempChildStudyPlan;                        

                        completionRequirementMap.put(key, spo.reduivy__Completion_Requirement__c);
                    }   
                }
            }

            //IPA Id, reduivy__Individual_Program_Enrollment__c
            //Stores the Master IPE for the IPA so the Child IPE can reference it later.
            Map<Id, reduivy__Individual_Program_Enrollment__c> masterIpeToBeCreated = new Map<Id, reduivy__Individual_Program_Enrollment__c>();

            for(reduivy__Individual_Program_Application__c ipa : newIpaMap.values()) {
                reduivy__Individual_Program_Enrollment__c tempMasterIpe = new reduivy__Individual_Program_Enrollment__c();

                //Set the enrollment status to null if the custom metadata does not specify any enrollment status for the application status
                String enrollmentStatus = IPA_CREATE_IPE_STATUSES_WITH_IPE_STATUS.containsKey(ipa.reduivy__Application_Status__c) ? IPA_CREATE_IPE_STATUSES_WITH_IPE_STATUS.get(ipa.reduivy__Application_Status__c) : null;

                tempMasterIpe.reduivy__Contact__c = ipa?.reduivy__Contact__c;
                tempMasterIpe.reduivy__Study_Program__c = ipa?.reduivy__Study_Program__c;
                tempMasterIpe.reduivy__Admission_Date__c = IPE_INPROGRESS_STATUSES.contains(enrollmentStatus) ? System.today() : null;
                tempMasterIpe.reduivy__Study_Mode__c = ipa?.reduivy__Study_Mode__c;
                tempMasterIpe.reduivy__Individual_Program_Application__c = ipa.Id;
                tempMasterIpe.reduivy__Eligible_To_Enroll__c = IPE_INPROGRESS_STATUSES.contains(enrollmentStatus) ? true : false;
                tempMasterIpe.RecordTypeId = IPE_MASTER_RECORD_TYPE_ID;

                // If the Study Intake is populated, we can populate these fields; otherwise, blank
                tempMasterIpe.reduivy__Study_Intake__c = ipa?.reduivy__Study_Intake__c;
                tempMasterIpe.reduivy__Class_Year__c = ipa?.reduivy__Study_Intake__r?.reduivy__Class_Year__c;
                tempMasterIpe.reduivy__Cohort_ID__c = ipa?.reduivy__Study_Intake__r?.reduivy__Cohort_ID__c;
            
                // How to determine the Study Plan, Campus, Pathway, and Study Plan Option Type:
                // - The values set on the IPA (Study Plan, Campus, and Pathway) take precedence.
                // - If not defined on the IPA:
                //     - Use values from the Master Study Plan > Study Intake > Study Program.
                // Note: Campus can only be set based on the IPA value or the Study Intake campus, if available.
                String studyPlan = ipa?.reduivy__Master_Study_Plan__c;
                String studyPlanOptionType = ipa?.reduivy__Master_Study_Plan__r?.reduivy__Type__c;

                String defaultCampus = String.isNotBlank(ipa.reduivy__Default_Campus__c) 
                    ?ipa.reduivy__Default_Campus__c 
                    :ipa?.reduivy__Study_Intake__r?.reduivy__Campus__c;

                String studyPathway = ipa?.reduivy__Study_Pathway__c;

                // If the Study Plan is still blank, it means the Master Study Plan isn't populated, so we need to retrieve it from either the Study Intake or the Study Program default.
                if(String.isBlank(studyPlan)) {
                    // If the Study Intake is populated, set the Study Plan and type using the Study Intake's default values.
                    if(String.isNotBlank(ipa.reduivy__Study_Intake__c)) {
                        studyPlan = ipa.reduivy__Study_Intake__r?.reduivy__Default_Study_Plan__c;
                        studyPlanOptionType = ipa.reduivy__Study_Intake__r?.reduivy__Default_Study_Plan__r?.reduivy__Type__c;
                    } else {  // Otherwise, try to get the default Study Plan from the Study Program; if none is found, leave it blank.
                        studyPlan = defaultStudyPlanByStudyProgram.containsKey(ipa.reduivy__Study_Program__c) ?defaultStudyPlanByStudyProgram.get(ipa.reduivy__Study_Program__c).Id :null;
                        studyPlanOptionType = defaultStudyPlanByStudyProgram.containsKey(ipa.reduivy__Study_Program__c) ?defaultStudyPlanByStudyProgram.get(ipa.reduivy__Study_Program__c)?.reduivy__Type__c :null;
                    }
                }

                // If the Study Pathway is still null, determine which field the Study Plan was set from, and use that to decide how to retrieve the pathway.
                if(String.isBlank(studyPathway)) {
                    if(String.isNotBlank(ipa.reduivy__Master_Study_Plan__c)) {
                        // If it's from the Master Study Plan, retrieve its default Study Pathway; if none is found, leave it blank.
                        reduivy__Study_Plan__c spl = studyPlanByStudyPlanId.containsKey(ipa.reduivy__Master_Study_Plan__c) ? studyPlanByStudyPlanId.get(ipa.reduivy__Master_Study_Plan__c) :null; 
                        
                        if (spl != null && spl.reduivy__Study_Pathways__r != null && !spl.reduivy__Study_Pathways__r.isEmpty()) {
                            studyPathway = spl.reduivy__Study_Pathways__r[0].Id;
                        } else {
                            studyPathway = null;
                        }

                    } else if (String.isNotBlank(ipa.reduivy__Study_Intake__c)) {
                        studyPathway = ipa.reduivy__Study_Intake__r?.reduivy__Default_Study_Pathway__c;

                    } else {
                        reduivy__Study_Plan__c spl = defaultStudyPlanByStudyProgram.containsKey(ipa.reduivy__Study_Program__c) ?defaultStudyPlanByStudyProgram.get(ipa.reduivy__Study_Program__c) :null;
                        
                        if (spl != null && spl.reduivy__Study_Pathways__r != null && !spl.reduivy__Study_Pathways__r.isEmpty()) {
                            studyPathway = spl.reduivy__Study_Pathways__r[0].Id;
                        } else {
                            studyPathway = null;
                        }
                    }
                }

                tempMasterIpe.reduivy__Study_Plan__c = studyPlan;
                tempMasterIpe.reduivy__Study_Plan_Option_Type__c = studyPlanOptionType;
                tempMasterIpe.reduivy__Default_Campus__c = defaultCampus;
                tempMasterIpe.reduivy__Study_Pathway__c = studyPathway;
                tempMasterIpe.reduivy__Enrollment_Status__c = enrollmentStatus;

                if(String.isBlank(studyPlan) && IPE_INPROGRESS_STATUSES.contains(tempMasterIpe.reduivy__Enrollment_Status__c)) {
                    String errorMsg = String.format(Label.IPA_No_Default_Study_Plan_Found, 
                                new List<String>{SPL_Helper.getObjectPluralLabel(), ipa.Name, SIT_Helper.getObjectPluralLabel(), SPG_Helper.getObjectPluralLabel(), IPE_Helper.getObjectPluralLabel()});

                    ipaMap.get(ipa.Id).addError(errorMsg);

                    newIpaMap.remove(ipa.Id);

                    continue;
                }

                masterIpeToBeCreated.put(ipa.Id, tempMasterIpe);
            }

            if(!masterIpeToBeCreated.isEmpty()) {
                REDU_Database_UTIL.doInsert(masterIpeToBeCreated.values(), ipaMap, 'reduivy__Individual_Program_Application__c', false);

                List<reduivy__Individual_Program_Enrollment__c> childIpeToBeCreated = new List<reduivy__Individual_Program_Enrollment__c>();

                for(reduivy__Individual_Program_Application__c ipa : newIpaMap.values()) {
                    if(String.isNotBlank(ipa.reduivy__Secondary_Study_Plan__c)) { //If the Secondary Study Plan is populated, create a child IPE
                        reduivy__Individual_Program_Enrollment__c relatedMasterIpe = masterIpeToBeCreated.get(ipa.Id);

                        if(String.isNotBlank(relatedMasterIpe?.Id)) { //If the Master IPE that the Child IPE should link to for this IPA cannot be found, skip processing.
                            
                            reduivy__Individual_Program_Enrollment__c tempChildIpe = new reduivy__Individual_Program_Enrollment__c();

                            String masterIpeId = relatedMasterIpe.Id;
                            String masterIpeContact = relatedMasterIpe.reduivy__Contact__c;
                            String masterEnrollmentStatus = relatedMasterIpe.reduivy__Enrollment_Status__c;
                            String masterStudyProgram = relatedMasterIpe.reduivy__Study_Program__c;
                            Date masterAdmissionDate = relatedMasterIpe.reduivy__Admission_Date__c;

                            String tempMasterStudyPlan = String.isNotBlank(relatedMasterIpe.reduivy__Study_Plan__c) ? relatedMasterIpe.reduivy__Study_Plan__c :'-';
                            String tempChildStudyPlan = ipa.reduivy__Secondary_Study_Plan__c;

                            String tempKey = tempMasterStudyPlan + '|' + tempChildStudyPlan;  

                            //Best effort, if a study plan option is found where the master study plan and secondary study plan match, then use it, otherwise default it to 'Mandatory'
                            String completionRequirement = completionRequirementMap.containsKey(tempKey) ?completionRequirementMap.get(tempKey) :SPO_Helper.COMPLETION_REQUIREMENT_MANDATORY;
                            
                            tempChildIpe.reduivy__Contact__c = masterIpeContact;
                            tempChildIpe.reduivy__Study_Program__c = masterStudyProgram;
                            tempChildIpe.reduivy__Completion_Requirement__c = completionRequirement;
                            tempChildIpe.reduivy__Study_Plan__c = ipa.reduivy__Secondary_Study_Plan__c;
                            tempChildIpe.RecordTypeId = IPE_CHILD_RECORD_TYPE_ID;
                            tempChildIpe.reduivy__Master_Enrollment__c = masterIpeId;
                            tempChildIpe.reduivy__Enrollment_Status__c = masterEnrollmentStatus;
                            tempChildIpe.reduivy__Admission_Date__c = masterAdmissionDate;
                            tempChildIpe.reduivy__Individual_Program_Application__c = ipa.Id;

                            childIpeToBeCreated.add(tempChildIpe);
                        }
                    } 
                }

                if(!childIpeToBeCreated.isEmpty()) {
                    REDU_Database_UTIL.doInsert(childIpeToBeCreated, ipaMap, 'reduivy__Individual_Program_Application__c', false);
                }
            }
        }
    }
}