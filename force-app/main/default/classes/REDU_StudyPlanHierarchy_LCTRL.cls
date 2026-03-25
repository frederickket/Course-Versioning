/**
 * @Author 		WDCi (Lean)
 * @Date 		Nov 2023
 * @group 		Study Plan
 * @Description Study plan hierarchy wizard
 * @changehistory
 * ISS-001617 10-11-2023 Lean - new component
 * ISS-002152 29-10-2024 Jordan - Study Plan Wizard to support modification
 */
public with sharing class REDU_StudyPlanHierarchy_LCTRL {
    
    public static final String NEW_GROUP_ACTION_TYPE = 'new_group';

    public static final String NEW_UNIT_ACTION_TYPE = 'new_unit';

    public static final String EDIT_ACTION_TYPE = 'edit';

    public static final String DELETE_ACTION_TYPE = 'delete';

    /**
     * @description Get top level group study plan structures
     * @param spsId Parent study plan structure id 
     * @return REDU_LightningResponse
     */
	@AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getTopLevelGroups(Id splId){
        
        try {
            List<reduivy__Study_Plan_Structure__c> topGroups = new List<reduivy__Study_Plan_Structure__c>();

            Map<String, Object> spsBindParams = new Map<String, Object>{
                'spsGroupRtId' => SPS_Helper.getGroupRecordTypeId(),
                'splId' => splId
            };

            String spsQuery = 'SELECT Id, Name ' +
            ' FROM reduivy__Study_Plan_Structure__c ' +
            ' WHERE reduivy__Study_Plan__c =: splId ' +
            ' AND RecordTypeId =: spsGroupRtId ' +
            ' AND reduivy__Parent_Study_Plan_Structure__c = NULL ' +
            ' ORDER BY reduivy__Sequence_Key__c ASC NULLS LAST, Name ASC ';

            for (reduivy__Study_Plan_Structure__c sps : (List<reduivy__Study_Plan_Structure__c>) Database.queryWithBinds(spsQuery, spsBindParams, AccessLevel.USER_MODE)) {
                topGroups.add(sps);
            }

            REDU_LightningResponse response = new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(topGroups));
            return response;

        } catch (QueryException qex) {
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    /**
     * @description ISS-002152 Get SPS record type info
     * @param groupFieldSetName
     * @return REDU_LightningResponse
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getSpsRecordTypeInfo(){
        
        try {
            Map<String, Object> responseJSON = new Map<String, Object>();
            responseJSON.put('spsGroupRecordTypeId', SPS_Helper.getGroupRecordTypeId());
            responseJSON.put('spsGroupRecordTypeLabel', SPS_Helper.getGroupRecordTypeLabel());
            responseJSON.put('spsUnitRecordTypeId', SPS_Helper.getUnitRecordTypeId());
            responseJSON.put('spsUnitRecordTypeLabel', SPS_Helper.getUnitRecordTypeLabel());

            REDU_LightningResponse response = new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(responseJSON));
            return response;

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    /**
     * @description ISS-002152 Get group field set
     * @param groupFieldSetName
     * @return REDU_LightningResponse
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getGroupFieldSet(String groupFieldSetName){
        
        try {
            List<REDU_DynamicFieldValue_OBJ> groupFsmList = REDU_Metadata_UTIL.getFieldSetMembers(
                'reduivy__Study_Plan_Structure__c',
                groupFieldSetName
            );

            Map<String, Object> responseJSON = new Map<String, Object>();
            responseJSON.put('groupFields', groupFsmList);
            REDU_Logging_UTIL.debug('groupFields :: ', groupFsmList);

            REDU_LightningResponse response = new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(responseJSON));
            return response;

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    /**
     * @description ISS-002152 Get unit field set
     * @param unitFieldSetName
     * @return REDU_LightningResponse
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getUnitFieldSet(String unitFieldSetName){
        
        try {
            List<REDU_DynamicFieldValue_OBJ> unitFsmList = REDU_Metadata_UTIL.getFieldSetMembers(
                'reduivy__Study_Plan_Structure__c',
                unitFieldSetName
            );

            Map<String, Object> responseJSON = new Map<String, Object>();
            responseJSON.put('unitFields', unitFsmList);
            REDU_Logging_UTIL.debug('unitFields :: ', unitFsmList);

            REDU_LightningResponse response = new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(responseJSON));
            return response;

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    /**
     * ISS-002152
     * @description getCommunityInfo description
     * @return   return description
     */ 
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getCommunityInfo(){
        try {
            return new REDU_LightningResponse(true, 'success', JSON.serialize(ORG_Helper.getCommunityInfo()));
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description ISS-002152 Method for handling insert and edit logic of record edit form
     * @param spsId Id of Study Plan Structure to create or edit
     * @param actionType NewGroup, NewUnit, Edit
     * @param studyPlanId Study plan id
     * @param spsRecord Field data of Study Plan Structure to create or edit
     * @return REDU_LightningResponse
     */
    @AuraEnabled
    public static REDU_LightningResponse upsertStudyPlanStructure(String spsId, String studyPlanId, String spsParentId, String actionType, reduivy__Study_Plan_Structure__c spsRecord){
        SavePoint sp = Database.setSavepoint();

        try{
            if (actionType == REDU_StudyPlanHierarchy_LCTRL.NEW_GROUP_ACTION_TYPE) {
                spsRecord.RecordTypeId = SPS_Helper.getGroupRecordTypeId();
                spsRecord.reduivy__Study_Plan__c = studyPlanId;
                spsRecord.reduivy__Parent_Study_Plan_Structure__c = spsParentId;

                REDU_Database_UTIL.doInsert(new List<reduivy__Study_Plan_Structure__c>{spsRecord});

            } else if (actionType == REDU_StudyPlanHierarchy_LCTRL.NEW_UNIT_ACTION_TYPE) {
                spsRecord.RecordTypeId = SPS_Helper.getUnitRecordTypeId();
                spsRecord.reduivy__Study_Plan__c = studyPlanId;
                spsRecord.reduivy__Parent_Study_Plan_Structure__c = spsParentId;

                REDU_Database_UTIL.doInsert(new List<reduivy__Study_Plan_Structure__c>{spsRecord});

            } else if (actionType == REDU_StudyPlanHierarchy_LCTRL.EDIT_ACTION_TYPE) {
                spsRecord.Id = spsId;

                REDU_Database_UTIL.doUpdate(new List<reduivy__Study_Plan_Structure__c>{spsRecord});
            }
            
            Map<String, Object> responseJSON = new Map<String, Object>();
            responseJSON.put('Id', spsRecord.Id);
            REDU_LightningResponse response = new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(responseJSON));
            return response;
        } catch (Exception exp) {
            Database.rollback(sp);
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    /**
     * @description ISS-002152 Method to delete sps group and its related child
     * @param spsId Study Plan Structure to delete
     * @param spsType Type of study plan structure to delete
     * @return REDU_LightningResponse
     */
    @AuraEnabled
    public static REDU_LightningResponse deleteStudyPlanStructure(String spsId, Id spsType){
        try{
            List<reduivy__Study_Plan_Structure__c> spsDeleteList = new List<reduivy__Study_Plan_Structure__c>();

            if (spsType == SPS_Helper.getGroupRecordTypeId()) {
                Map<String, Object> spsDeleteBindParams = new Map<String, Object>{
                    'spsId' => spsId
                };
        
                String spsDeleteQuery = 'SELECT Id ' +
                ' FROM reduivy__Study_Plan_Structure__c ' +
                ' WHERE reduivy__Parent_Study_Plan_Structure__c =: spsId ' +
                ' OR reduivy__Parent_Study_Plan_Structure__r.reduivy__Parent_Study_Plan_Structure__c =: spsId ' +
                ' OR reduivy__Parent_Study_Plan_Structure__r.reduivy__Parent_Study_Plan_Structure__r.reduivy__Parent_Study_Plan_Structure__c =: spsId ' +
                ' ORDER BY reduivy__Sequence_Key__c ASC NULLS LAST, Name ASC ';

                spsDeleteList = (List<reduivy__Study_Plan_Structure__c>) Database.queryWithBinds(spsDeleteQuery, spsDeleteBindParams, AccessLevel.USER_MODE);
            }

            spsDeleteList.add(new reduivy__Study_Plan_Structure__c(Id = spsId));
            REDU_SystemMode_UTIL.doDelete(spsDeleteList);

            REDU_LightningResponse response = new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, REDU_LightningResponse.SUCCESS);
            return response;
        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }
}