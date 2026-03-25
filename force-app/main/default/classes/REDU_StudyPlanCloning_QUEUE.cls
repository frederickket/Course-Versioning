/**
 * @author      WDCi (Jordan)
 * @date        Nov 2024
 * @group       Study Plan Cloning
 * @description Handle large child study plan cloning
 * @changehistory
 * ISS-002153 18-11-2024 Jordan - New class
 */
public inherited sharing class REDU_StudyPlanCloning_QUEUE implements Queueable {

    /**
     * @description ISS-002153 Study plan cloning platform event name
     */
    public static final String STUDY_PLAN_CLONING_PLATFORM_EVENT_NAME = 'StudyPlanCloning';

    public String studyPlanId;
    public String studyPlanData;
    public List<Id> studyPathwayArray;
    public List<Id> studyPlanOptionArray;
    public Boolean includeExistingStudyPlanUnitRequirements;
    public Boolean cloneChildStudyPlans;
    public reduivy__Study_Plan__c clonedMasterStudyPlan;
	
    /**
     * @description REDU_StudyPlanCloning_QUEUE constructor
     * @param studyPlanId Id of Study Plan to clone
     * @param studyPlanData Cloned Study Plan data
     * @param studyPathwayArray Study Pathways to clone
     * @param studyPlanOptionArray Study Plan Options to clone
     * @param includeExistingStudyPlanUnitRequirements Clone Existing Study Plan Unit Requirements?
     * @param cloneChildStudyPlans Clone Child Study Plans when cloning Study Plan Options?
     **/
    public REDU_StudyPlanCloning_QUEUE(String studyPlanId, String studyPlanData, List<Id> studyPathwayArray, List<Id> studyPlanOptionArray, Boolean includeExistingStudyPlanUnitRequirements, Boolean cloneChildStudyPlans) {
        this.studyPlanId = studyPlanId;
        this.studyPlanData = studyPlanData;
        this.studyPathwayArray = studyPathwayArray;
        this.studyPlanOptionArray = studyPlanOptionArray;
        this.includeExistingStudyPlanUnitRequirements = includeExistingStudyPlanUnitRequirements;
        this.cloneChildStudyPlans = cloneChildStudyPlans;

        REDU_Logging_UTIL.debug('REDU_StudyPlanCloning_QUEUE', studyPlanId);
    }

    /**
     * @description Execute
     * @param queueableContext Queueable Context
     **/
    public void execute(QueueableContext queueableContext) {

        // Log start job
        REDU_Logging_UTIL.logInfo('Async Job Started', 'REDU_StudyPlanCloning_QUEUE', SPL_Helper.getApiName(), queueableContext.getJobId(), 'Cloning Study Plan ' + this.studyPlanId + ' with Job Id ' + queueableContext.getJobId());

        SavePoint sp = Database.setSavePoint();

        try {

            cloneStudyPlan();

        } catch (Exception exp) {
            
            Database.rollback(sp);
            REDU_Logging_UTIL.debug(exp);
            REDU_Logging_UTIL.logError('Clone Study Plan', 'REDU_StudyPlanCloning_QUEUE', 'reduivy__Study_Plan__c', null, this.studyPlanId, exp);

            SObject pfEvt = REDU_PlatformEvent_UTIL.initPlatformEvent(STUDY_PLAN_CLONING_PLATFORM_EVENT_NAME, 'Failed', exp.getMessage(), this.studyPlanId);
            REDU_PlatformEvent_UTIL.publishEvent(pfEvt);

        } finally {

            //Log job finished
            REDU_Logging_UTIL.logInfo('Async Job Ended', 'REDU_StudyPlanCloning_QUEUE', SPL_Helper.getApiName(), queueableContext.getJobId(), 'Cloned Study Plan ' + this.studyPlanId + ' with Job Id ' + queueableContext.getJobId());
            
            SObject pfEvt = REDU_PlatformEvent_UTIL.initPlatformEvent(STUDY_PLAN_CLONING_PLATFORM_EVENT_NAME, 'Completed', JSON.serialize(this.clonedMasterStudyPlan), this.studyPlanId);
            REDU_PlatformEvent_UTIL.publishEvent(pfEvt);
        }
    }

    /**
     * @description Clone Study Plan and related records.
     */
    public void cloneStudyPlan() {
        reduivy__Study_Plan__c clonedStudyPlan = (reduivy__Study_Plan__c) JSON.deserialize(this.studyPlanData, reduivy__Study_Plan__c.Class);
            
        //Clone study plan
        clonedStudyPlan.reduivy__Clone_From_Id__c = this.studyPlanId;
        REDU_Database_UTIL.doInsert(new List<reduivy__Study_Plan__c>{clonedStudyPlan});

        this.clonedMasterStudyPlan = clonedStudyPlan;
        
        //Clone study plan structures
        Set<String> spsFields = REDU_Metadata_UTIL.getObjectFieldsForCloning('reduivy__Study_Plan_Structure__c', AccessType.CREATABLE);

        Map<String, Object> studyPlanStructureBindParams = new Map<String, Object>{
            'studyPlanId' => studyPlanId
        };

        String studyPlanStructureQuery = 'SELECT ' + String.join(spsFields, ',') +
            ' FROM reduivy__Study_Plan_Structure__c ' +
            ' WHERE reduivy__Study_Plan__c =: studyPlanId ';

        List<reduivy__Study_Plan_Structure__c> existingStudyPlanStructureData = (List<reduivy__Study_Plan_Structure__c>) Database.queryWithBinds(studyPlanStructureQuery, studyPlanStructureBindParams, AccessLevel.USER_MODE);

        //Using map of old study plan structures for easier future reference
        Map<Id, reduivy__Study_Plan_Structure__c> existingStudyPlanStructureMap = new Map<Id, reduivy__Study_Plan_Structure__c>(existingStudyPlanStructureData);
        Map<Id, reduivy__Study_Plan_Structure__c> spsExistingToNewMap = new Map<Id,reduivy__Study_Plan_Structure__c>();

        if(!existingStudyPlanStructureData.isEmpty()) {
            for(reduivy__Study_Plan_Structure__c sps : existingStudyPlanStructureData) {
                reduivy__Study_Plan_Structure__c newSps = sps.clone();
                newSps.reduivy__Clone_From_Id__c = sps.Id;
                
                //Create cloned Study Plan Structures directly on the cloned Study Plan
                newSps.reduivy__Study_Plan__c = clonedStudyPlan.Id;
                newSps.reduivy__Parent_Study_Plan_Structure__c = null; //Reset study plan structure lookup so we can insert on cloned program plan

                //Clear requirement fields
                if (this.includeExistingStudyPlanUnitRequirements == null || !this.includeExistingStudyPlanUnitRequirements) {
                    newSps.reduivy__Requirement_Logic__c = null;
                    newSps.reduivy__Requirement_Description__c = null;
                }

                spsExistingToNewMap.put(sps.Id, newSps);
            }
        }

        List<reduivy__Study_Plan_Structure__c> newSpsData = new List<reduivy__Study_Plan_Structure__c>();
        List<reduivy__Study_Plan_Structure__c> newSpsToBeClonedData = spsExistingToNewMap.values();
        REDU_Database_UTIL.doInsert(newSpsToBeClonedData);
        
        if(!newSpsToBeClonedData.isEmpty()) {
            //Clone the existing Study Plan Unit Requirements configured in the Study Plan Structures
            if (this.includeExistingStudyPlanUnitRequirements != null && this.includeExistingStudyPlanUnitRequirements) {
                List<reduivy__Study_Plan_Unit_Requirement__c> listSPURsToInsert = getStudyPlanUnitReqsFromSps(newSpsToBeClonedData);
                REDU_Database_UTIL.doInsert(listSPURsToInsert);
            }

            for(reduivy__Study_Plan_Structure__c newSps : newSpsToBeClonedData) {
                //Find cloned version of the original study plan structure lookup
                if (existingStudyPlanStructureMap.get(newSps.reduivy__Clone_From_Id__c).reduivy__Parent_Study_Plan_Structure__c != null){
                    if (spsExistingToNewMap.containsKey(existingStudyPlanStructureMap.get(newSps.reduivy__Clone_From_Id__c).reduivy__Parent_Study_Plan_Structure__c)){
                        newSps.reduivy__Parent_Study_Plan_Structure__c = spsExistingToNewMap.get(existingStudyPlanStructureMap.get(newSps.reduivy__Clone_From_Id__c).reduivy__Parent_Study_Plan_Structure__c).Id;
                        newSpsData.add(newSps);
                    }
                }
                
            }
        }

        if(!newSpsData.isEmpty()) {
            REDU_Database_UTIL.doUpdate(newSpsData);
        }

        //Clone study plan options
        Map<Id, reduivy__Study_Plan__c> clonedChildStudyPlans = new Map<Id, reduivy__Study_Plan__c>();

        if(this.studyPlanOptionArray != null && !this.studyPlanOptionArray.isEmpty()) {
            Set<String> studyPlanOptionFields = REDU_Metadata_UTIL.getObjectFieldsForCloning('reduivy__Study_Plan_Option__c', AccessType.CREATABLE);

            Map<String, Object> studyPlanOptionParams = new Map<String, Object>{
                'studyPlanOptionArray' => this.studyPlanOptionArray
            };

            String studyPlanOptionQuery = 'SELECT Id, ' + String.join(studyPlanOptionFields, ',') +
                ' FROM reduivy__Study_Plan_Option__c ' +
                ' WHERE Id IN: studyPlanOptionArray ';

            List<reduivy__Study_Plan_Option__c> studyPlanOptionsToBeCloned = (List<reduivy__Study_Plan_Option__c>) Database.queryWithBinds(studyPlanOptionQuery, studyPlanOptionParams, AccessLevel.USER_MODE);

            if (this.cloneChildStudyPlans != null && this.cloneChildStudyPlans) {
                Set<Id> childStudyPlansToBeClonedIds = new Set<Id>();

                for (reduivy__Study_Plan_Option__c studyPlanOption : studyPlanOptionsToBeCloned) {
                    childStudyPlansToBeClonedIds.add(studyPlanOption.reduivy__Child_Study_Plan__c);
                }
                
                Set<String> childStudyPlanFields = REDU_Metadata_UTIL.getObjectFieldsForCloning('reduivy__Study_Plan__c', AccessType.CREATABLE);

                Map<String, Object> childStudyPlanParams = new Map<String, Object>{
                    'childStudyPlansToBeClonedIds' => childStudyPlansToBeClonedIds
                };

                String childStudyPlanQuery = 'SELECT ' + String.join(childStudyPlanFields, ',') +
                    ' FROM reduivy__Study_Plan__c ' +
                    ' WHERE Id IN: childStudyPlansToBeClonedIds ';
                
                List<reduivy__Study_Plan__c> childStudyPlansToClone = (List<reduivy__Study_Plan__c>) Database.queryWithBinds(childStudyPlanQuery, childStudyPlanParams, AccessLevel.USER_MODE);

                cloneChildStudyPlans(childStudyPlansToClone, clonedChildStudyPlans, spsExistingToNewMap);
            } else {
                Map<Id, reduivy__Study_Plan_Option__c> clonedStudyPlanOptions = new Map<Id, reduivy__Study_Plan_Option__c>();

                if(!studyPlanOptionsToBeCloned.isEmpty()) {
                    for(reduivy__Study_Plan_Option__c studyPlanOption : studyPlanOptionsToBeCloned) {
                        reduivy__Study_Plan_Option__c newStudyPlanOption = studyPlanOption.clone();
                        newStudyPlanOption.reduivy__Clone_From_Id__c = studyPlanOption.Id;
                        newStudyPlanOption.reduivy__Master_Study_Plan__c = clonedStudyPlan.Id;
                        clonedStudyPlanOptions.put(studyPlanOption.Id, newStudyPlanOption);
                    }
                }

                REDU_Database_UTIL.doInsert(clonedStudyPlanOptions.values());
            }
        }
        
        //Clone study pathways and related records
        if(this.studyPathwayArray != null && !this.studyPathwayArray.isEmpty()) {
            //Study Pathways
            Set<String> studyPathwayFields = REDU_Metadata_UTIL.getObjectFieldsForCloning('reduivy__Study_Pathway__c', AccessType.CREATABLE);

            Map<String, Object> studyPathwayBindParams = new Map<String, Object>{
                'studyPathwayArray' => this.studyPathwayArray
            };

            String studyPathwayQuery = 'SELECT ' + String.join(studyPathwayFields, ',') +
                ' FROM reduivy__Study_Pathway__c ' +
                ' WHERE Id IN: studyPathwayArray ';

            List<reduivy__Study_Pathway__c> studyPathwaysToBeCloned = (List<reduivy__Study_Pathway__c>) Database.queryWithBinds(studyPathwayQuery, studyPathwayBindParams, AccessLevel.USER_MODE);

            Map<Id, reduivy__Study_Pathway__c> clonedStudyPathways = new Map<Id, reduivy__Study_Pathway__c>();
            
            if(!studyPathwaysToBeCloned.isEmpty()) {
                for(reduivy__Study_Pathway__c studyPathway : studyPathwaysToBeCloned) {
                    reduivy__Study_Pathway__c newStudyPathway = studyPathway.clone();
                    newStudyPathway.reduivy__Clone_From_Id__c = studyPathway.Id;
                    newStudyPathway.reduivy__Study_Plan__c = clonedStudyPlan.Id;
                    clonedStudyPathways.put(studyPathway.Id, newStudyPathway);
                }
            }
            
            REDU_Database_UTIL.doInsert(clonedStudyPathways.values());

            //Study Pathway Terms
            Set<String> studyPathwayTermFields = REDU_Metadata_UTIL.getObjectFieldsForCloning('reduivy__Study_Pathway_Term__c', AccessType.CREATABLE);

            Map<String, Object> studyPathwayTermBindParams = new Map<String, Object>{
                'studyPathwaySet' => clonedStudyPathways.keySet()
            };

            String studyPathwayTermQuery = 'SELECT ' + String.join(studyPathwayTermFields, ',') +
                ' FROM reduivy__Study_Pathway_Term__c ' +
                ' WHERE reduivy__Study_Pathway__c IN: studyPathwaySet ';

            List<reduivy__Study_Pathway_Term__c> studyPathwayTermsToBeCloned = (List<reduivy__Study_Pathway_Term__c>) Database.queryWithBinds(studyPathwayTermQuery, studyPathwayTermBindParams, AccessLevel.USER_MODE);

            Map<Id, reduivy__Study_Pathway_Term__c> clonedStudyPathwayTerms = new Map<Id, reduivy__Study_Pathway_Term__c>();

            if(!studyPathwayTermsToBeCloned.isEmpty()) {
                for(reduivy__Study_Pathway_Term__c studyPathwayTerm : studyPathwayTermsToBeCloned) {
                    reduivy__Study_Pathway_Term__c newStudyPathwayTerm = studyPathwayTerm.clone();
                    newStudyPathwayTerm.reduivy__Clone_From_Id__c = studyPathwayTerm.Id;
                    newStudyPathwayTerm.reduivy__Study_Pathway__c = clonedStudyPathways.get(studyPathwayTerm.reduivy__Study_Pathway__c).Id;
                    clonedStudyPathwayTerms.put(studyPathwayTerm.Id, newStudyPathwayTerm);
                }
            }

            REDU_Database_UTIL.doInsert(clonedStudyPathwayTerms.values());

            //Study Pathway Units
            Set<String> relatedPathwayUnitFields = REDU_Metadata_UTIL.getObjectFieldsForCloning('reduivy__Study_Pathway_Unit__c', AccessType.CREATABLE);
            
            Map<String, Object> studyPathwayUnitBindParams = new Map<String, Object>{
                'studyPathwayTermSet' => clonedStudyPathwayTerms.keySet()
            };

            String studyPathwayUnitQuery = 'SELECT ' + String.join(relatedPathwayUnitFields, ',') +
                ' FROM reduivy__Study_Pathway_Unit__c ' +
                ' WHERE reduivy__Study_Pathway_Term__c IN: studyPathwayTermSet ';

            List<reduivy__Study_Pathway_Unit__c> studyPathwayUnitsToBeCloned = (List<reduivy__Study_Pathway_Unit__c>) Database.queryWithBinds(studyPathwayUnitQuery, studyPathwayUnitBindParams, AccessLevel.USER_MODE);
            
            List<reduivy__Study_Pathway_Unit__c> clonedStudyPathwayUnits = new List<reduivy__Study_Pathway_Unit__c>();

            if(!studyPathwayUnitsToBeCloned.isEmpty()) {
                for(reduivy__Study_Pathway_Unit__c studyPathwayUnit : studyPathwayUnitsToBeCloned) {
                    reduivy__Study_Pathway_Unit__c newStudyPathwayUnit = studyPathwayUnit.clone();
                    newStudyPathwayUnit.reduivy__Clone_From_Id__c = studyPathwayUnit.Id;
                    newStudyPathwayUnit.reduivy__Study_Pathway_Term__c = clonedStudyPathwayTerms.get(studyPathwayUnit.reduivy__Study_Pathway_Term__c).Id;

                    //Applicable Study Plan
                    if(studyPathwayUnit.reduivy__Applicable_Study_Plan__c != null && studyPathwayUnit.reduivy__Applicable_Study_Plan__c == clonedStudyPlan.reduivy__Clone_From_Id__c) {
                        newStudyPathwayUnit.reduivy__Applicable_Study_Plan__c = clonedStudyPlan.Id;
                    } else if(studyPathwayUnit.reduivy__Applicable_Study_Plan__c != null && clonedChildStudyPlans.containsKey(studyPathwayUnit.reduivy__Applicable_Study_Plan__c)) {
                        newStudyPathwayUnit.reduivy__Applicable_Study_Plan__c = clonedChildStudyPlans.get(studyPathwayUnit.reduivy__Applicable_Study_Plan__c).Id;
                    } else {
                        newStudyPathwayUnit.reduivy__Applicable_Study_Plan__c = studyPathwayUnit.reduivy__Applicable_Study_Plan__c;
                    }

                    //Study Plan Group
                    if(studyPathwayUnit.reduivy__Study_Plan_Group__c != null && spsExistingToNewMap.containsKey(studyPathwayUnit.reduivy__Study_Plan_Group__c)) {
                        newStudyPathwayUnit.reduivy__Study_Plan_Group__c = spsExistingToNewMap.get(studyPathwayUnit.reduivy__Study_Plan_Group__c).Id;
                    } else {
                        newStudyPathwayUnit.reduivy__Study_Plan_Group__c = studyPathwayUnit.reduivy__Study_Plan_Group__c;
                    }

                    clonedStudyPathwayUnits.add(newStudyPathwayUnit);
                }
            }

            REDU_Database_UTIL.doInsert(clonedStudyPathwayUnits);
        }
    }

    /**
    * @description Get Cloned Study Plan Unit Requirements from Study Plan Structure
    * @param workingSpsList Study Plan Structure list
    * @return List<reduivy__Study_Plan_Unit_Requirement__c> 
    **/
    public static List<reduivy__Study_Plan_Unit_Requirement__c> getStudyPlanUnitReqsFromSps(List<reduivy__Study_Plan_Structure__c> workingSpsList){
        List<reduivy__Study_Plan_Unit_Requirement__c> listSPURCloned = new List<reduivy__Study_Plan_Unit_Requirement__c>();

        Set<Id> spsClonedFromIdSet = new Set<Id>();

        for(reduivy__Study_Plan_Structure__c sps : workingSpsList){
            spsClonedFromIdSet.add(sps.reduivy__Clone_From_Id__c);
        }

        Set<String> setFldSelect = REDU_Metadata_UTIL.getObjectFieldsForCloning('reduivy__Study_Plan_Unit_Requirement__c', AccessType.READABLE);
        Set<String> setFldCreate = REDU_Metadata_UTIL.getObjectFieldsForCloning('reduivy__Study_Plan_Unit_Requirement__c', AccessType.CREATABLE);
        setFldSelect.remove('ownerid');
        setFldCreate.remove('reduivy__study_plan_unit__c');

        List<String> listFldSelect = new List<String>(setFldSelect);

        Map<String, Object> studyPlanUnitRequirementParams = new Map<String, Object>{
            'spsClonedFromIdSet' => spsClonedFromIdSet
        };

        String studyPlanUnitRequirementQuery = 'SELECT ' + String.join(listFldSelect, ',') +
            ' FROM reduivy__Study_Plan_Unit_Requirement__c ' +
            ' WHERE reduivy__Study_Plan_Unit__c IN: spsClonedFromIdSet ';

        //Get Study Plan Unit Requirements
        List<reduivy__Study_Plan_Unit_Requirement__c> listSPURsToClone = (List<reduivy__Study_Plan_Unit_Requirement__c>) Database.queryWithBinds(studyPlanUnitRequirementQuery, studyPlanUnitRequirementParams, AccessLevel.USER_MODE);
        Map<Id, List<reduivy__Study_Plan_Unit_Requirement__c>> spsToSpurMap = new Map<Id, List<reduivy__Study_Plan_Unit_Requirement__c>>();

        for (reduivy__Study_Plan_Unit_Requirement__c spur : listSPURsToClone) {
            List<reduivy__Study_Plan_Unit_Requirement__c> spurTempList = spsToSpurMap.get(spur.reduivy__Study_Plan_Unit__c);
            if (spurTempList == null) {
                spurTempList = new List<reduivy__Study_Plan_Unit_Requirement__c>{spur};
            }
            else {
                spurTempList.add(spur);
            }

            spsToSpurMap.put(spur.reduivy__Study_Plan_Unit__c, spurTempList);
        }

        //Clone records to create
        for (reduivy__Study_Plan_Structure__c sps : workingSpsList) {
            List<reduivy__Study_Plan_Unit_Requirement__c> listSPUR = spsToSpurMap.get(sps.reduivy__Clone_From_Id__c);

            if (listSPUR != null && listSPUR.size() > 0){

                for (reduivy__Study_Plan_Unit_Requirement__c spur : listSPUR) {
                    reduivy__Study_Plan_Unit_Requirement__c spurCloned = new reduivy__Study_Plan_Unit_Requirement__c();

                    for (String fld : setFldSelect) {
                        if (setFldCreate.contains(fld)){
                            spurCloned.put(fld, spur.get(fld));
                        }
                    }
                    spurCloned.reduivy__Study_Plan_Unit__c = sps.Id;
                    
                    listSPURCloned.add(spurCloned);
                }
            } 
        }

        return listSPURCloned;
    }

    /**
     * @description Clone child Study Plans and related records.
     * @param childStudyPlansToClone Child Study Plans to clone
     * @param clonedChildStudyPlans Map to store cloned child Study Plans
     * @param spsExistingToNewMap Map to store cloned Study Plan Structures of cloned child Study Plans
     */
    public void cloneChildStudyPlans(List<reduivy__Study_Plan__c> childStudyPlansToClone, Map<Id, reduivy__Study_Plan__c> clonedChildStudyPlans, Map<Id, reduivy__Study_Plan_Structure__c> spsExistingToNewMap){

        if(!childStudyPlansToClone.isEmpty()) {
            for(reduivy__Study_Plan__c childStudyPlan : childStudyPlansToClone) {
                reduivy__Study_Plan__c newChildStudyPlan = childStudyPlan.clone();
                newChildStudyPlan.reduivy__Clone_From_Id__c = childStudyPlan.Id;
                clonedChildStudyPlans.put(childStudyPlan.Id, newChildStudyPlan);
            }
        }
        
        REDU_Database_UTIL.doInsert(clonedChildStudyPlans.values());

        //Clone study plan structures
        Set<String> spsFields = REDU_Metadata_UTIL.getObjectFieldsForCloning('reduivy__Study_Plan_Structure__c', AccessType.CREATABLE);

        Map<String, Object> studyPlanStructureBindParams = new Map<String, Object>{
            'studyPlanIds' => clonedChildStudyPlans.keySet()
        };

        String studyPlanStructureQuery = 'SELECT ' + String.join(spsFields, ',') +
            ' FROM reduivy__Study_Plan_Structure__c ' +
            ' WHERE reduivy__Study_Plan__c IN: studyPlanIds ';

        List<reduivy__Study_Plan_Structure__c> existingStudyPlanStructureData = (List<reduivy__Study_Plan_Structure__c>) Database.queryWithBinds(studyPlanStructureQuery, studyPlanStructureBindParams, AccessLevel.USER_MODE);

        //Using map of old study plan structures for easier future reference
        Map<Id, reduivy__Study_Plan_Structure__c> existingStudyPlanStructureMap = new Map<Id, reduivy__Study_Plan_Structure__c>(existingStudyPlanStructureData);
        List<reduivy__Study_Plan_Structure__c> newSpsToBeClonedData = new List<reduivy__Study_Plan_Structure__c>();

        if(!existingStudyPlanStructureData.isEmpty()) {
            for(reduivy__Study_Plan_Structure__c sps : existingStudyPlanStructureData) {
                reduivy__Study_Plan_Structure__c newSps = sps.clone();
                newSps.reduivy__Clone_From_Id__c = sps.Id;
                
                //Create cloned Study Plan Structures directly on the cloned Study Plan
                newSps.reduivy__Study_Plan__c = clonedChildStudyPlans.get(sps.reduivy__Study_Plan__c).Id;
                newSps.reduivy__Parent_Study_Plan_Structure__c = null; //Reset study plan structure lookup so we can insert on cloned program plan

                //Clear requirement fields
                if (this.includeExistingStudyPlanUnitRequirements == null || !this.includeExistingStudyPlanUnitRequirements) {
                    newSps.reduivy__Requirement_Logic__c = null;
                    newSps.reduivy__Requirement_Description__c = null;
                }

                spsExistingToNewMap.put(sps.Id, newSps);
                newSpsToBeClonedData.add(newSps);
            }
        }

        List<reduivy__Study_Plan_Structure__c> newSpsData = new List<reduivy__Study_Plan_Structure__c>();
        REDU_Database_UTIL.doInsert(newSpsToBeClonedData);
        
        if(!newSpsToBeClonedData.isEmpty()) {
            //Clone the existing Study Plan Unit Requirements configured in the Study Plan Structures
            if (this.includeExistingStudyPlanUnitRequirements != null && this.includeExistingStudyPlanUnitRequirements) {
                List<reduivy__Study_Plan_Unit_Requirement__c> listSPURsToInsert = getStudyPlanUnitReqsFromSps(newSpsToBeClonedData);
                REDU_Database_UTIL.doInsert(listSPURsToInsert);
            }

            for(reduivy__Study_Plan_Structure__c newSps : newSpsToBeClonedData) {
                //Find cloned version of the original study plan structure lookup
                if (existingStudyPlanStructureMap.get(newSps.reduivy__Clone_From_Id__c).reduivy__Parent_Study_Plan_Structure__c != null){
                    if (spsExistingToNewMap.containsKey(existingStudyPlanStructureMap.get(newSps.reduivy__Clone_From_Id__c).reduivy__Parent_Study_Plan_Structure__c)){
                        newSps.reduivy__Parent_Study_Plan_Structure__c = spsExistingToNewMap.get(existingStudyPlanStructureMap.get(newSps.reduivy__Clone_From_Id__c).reduivy__Parent_Study_Plan_Structure__c).Id;
                        newSpsData.add(newSps);
                    }
                }
                
            }
        }

        if(!newSpsData.isEmpty()) {
            REDU_Database_UTIL.doUpdate(newSpsData);
        }

        //Study plan options (for master study plan)
        Set<String> studyPlanOptionFields = REDU_Metadata_UTIL.getObjectFieldsForCloning('reduivy__Study_Plan_Option__c', AccessType.CREATABLE);

        Map<String, Object> studyPlanOptionParams = new Map<String, Object>{
            'studyPlanOptionArray' => this.studyPlanOptionArray
        };

        String studyPlanOptionQuery = 'SELECT Id, ' + String.join(studyPlanOptionFields, ',') +
            ' FROM reduivy__Study_Plan_Option__c ' +
            ' WHERE Id IN: studyPlanOptionArray ';

        List<reduivy__Study_Plan_Option__c> studyPlanOptionsToBeCloned = (List<reduivy__Study_Plan_Option__c>) Database.queryWithBinds(studyPlanOptionQuery, studyPlanOptionParams, AccessLevel.USER_MODE);

        Map<Id, reduivy__Study_Plan_Option__c> clonedStudyPlanOptions = new Map<Id, reduivy__Study_Plan_Option__c>();

        if(!studyPlanOptionsToBeCloned.isEmpty()) {
            for(reduivy__Study_Plan_Option__c studyPlanOption : studyPlanOptionsToBeCloned) {
                if (clonedChildStudyPlans.containsKey(studyPlanOption.reduivy__Child_Study_Plan__c)) {
                    reduivy__Study_Plan_Option__c newStudyPlanOption = studyPlanOption.clone();
                    newStudyPlanOption.reduivy__Clone_From_Id__c = studyPlanOption.Id;
                    newStudyPlanOption.reduivy__Master_Study_Plan__c = this.clonedMasterStudyPlan.Id;
                    newStudyPlanOption.reduivy__Child_Study_Plan__c = clonedChildStudyPlans.get(studyPlanOption.reduivy__Child_Study_Plan__c).Id;
                    clonedStudyPlanOptions.put(studyPlanOption.Id, newStudyPlanOption);
                }
            }
        }

        REDU_Database_UTIL.doInsert(clonedStudyPlanOptions.values());
    }
}