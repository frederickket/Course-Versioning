/**
 * @author      WDCi (Sueanne)
 * @date        March 2024
 * @group       Study Pathway
 * @description Study pathway wizard
 * @changehistory
 * ISS-001917 26-03-2024 Sueanne - new class
 * ISS-002331 12-03-2025 Lean - Fixed query to get active study pathways
 * ISS-002330 19-03-2025 XW - get translated child study plan name if found
 */
public with sharing class REDU_StudyPathway_LCTRL {

    /**
     * @description get study pathway with: studyPlanId, default = true
     * @param studyPlanId
     * @return REDU_LightningResponse
     */
    @AuraEnabled(cacheable = true)
    public static REDU_LightningResponse getStudyPathway(Id recordId){
        try{
            reduivy__Study_Pathway__c pathway = null;

            if (String.isNotBlank(recordId) && 
                (recordId.getSobjectType() == Schema.reduivy__Study_Plan__c.getSobjectType()) 
                || (recordId.getSobjectType() == Schema.reduivy__Study_Pathway__c.getSobjectType()) 
            ) {
                if (recordId.getSObjectType() == Schema.reduivy__Study_Plan__c.getSobjectType()){
                    for (reduivy__Study_Pathway__c spw : [SELECT Id, 
                        Name, 
                        reduivy__Study_Mode__c, 
                        reduivy__Study_Plan__c
                        FROM reduivy__Study_Pathway__c
                        WHERE reduivy__Study_Plan__c =: recordId 
                        AND reduivy__Default__c = true
                        AND reduivy__Status__c =: SPW_Helper.STATUS_ACTIVE
                        WITH USER_MODE
                        LIMIT 1
                    ]) {
                        pathway = spw;
                    }

                } else if (recordId.getSObjectType() == Schema.reduivy__Study_Pathway__c.getSobjectType()){

                    for (reduivy__Study_Pathway__c spw : [SELECT Id, 
                        Name, 
                        reduivy__Study_Mode__c, 
                        reduivy__Study_Plan__c
                        FROM reduivy__Study_Pathway__c
                        WHERE Id =: recordId
                        WITH USER_MODE
                        LIMIT 1
                    ]) {
                        pathway = spw;
                    }
                }
            } else {
                String objectNames = String.join(new List<String>{SPL_Helper.getObjectLabel(), SPW_Helper.getObjectLabel()}, ', ');
                throw new REDU_ApplicationException(String.format(Label.Invalid_Record_Id_For_Object_Type, new List<String>{recordId, objectNames}));
            }

            REDU_LightningResponse response = new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(pathway));
            return response;

        } catch (QueryException qex){
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp){
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    /**
     * @description get study plan option with: studyPlanId, status = 'Active'
     * @param studyPlanId
     * @return REDU_LightningResponse
     */
    @AuraEnabled(cacheable = true)
    public static REDU_LightningResponse getStudyPlanOptions(Id studyPlanId){
        try{

            Set<String> fieldsToQuery = new Set<String>{
                'Id', 
                'reduivy__Status__c',
                'reduivy__Child_Study_Plan__r.Name',
                'reduivy__Child_Study_Plan__r.Id'
            };

            //query the individual pathway
            List<reduivy__Study_Plan_Option__c> studyPlanOptionList = new List<reduivy__Study_Plan_Option__c>();

            String splTranslatedNameFieldApiName = SPL_Helper.getTranslationFieldNameForName();
            
            splTranslatedNameFieldApiName = 'reduivy__Child_Study_Plan__r.' + splTranslatedNameFieldApiName;
            fieldsToQuery.add(splTranslatedNameFieldApiName);
            
            String spoSoql = 'SELECT ' + String.join(fieldsToQuery, ', ') + 
                ' FROM reduivy__Study_Plan_Option__c ' +
                ' WHERE reduivy__Master_Study_Plan__c =: studyPlanId ' +
                ' AND reduivy__Status__c =: status ' +
                ' ORDER BY ' + splTranslatedNameFieldApiName;

            Map<String, Object> spoBindParams = new Map<String, Object>();
            spoBindParams.put('studyPlanId', studyPlanId);
            spoBindParams.put('status', SPO_Helper.STATUS_ACTIVE);

            for (reduivy__Study_Plan_Option__c spo : (List<reduivy__Study_Plan_Option__c>) Database.queryWithBinds(spoSoql, spoBindParams, AccessLevel.USER_MODE)) {
                //loop to get all records
                studyPlanOptionList.add(spo);
            }

            REDU_LightningResponse response = new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(studyPlanOptionList));
            return response;

        } catch (QueryException qex){
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp){
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    /**
     * @description get study pathway term id list
     * @param studyPwId study pathway id
     * @return REDU_LightningResponse
     */
    @AuraEnabled(cacheable = true)
    public static REDU_LightningResponse getStudyPathwayTermIds(Id studyPwId){
        try{
            //get study pathway term (get recommended credits and term number)
            List<reduivy__Study_Pathway_Term__c> studyPwTermIdsList = new List<reduivy__Study_Pathway_Term__c>();

            String sptSoql = 'SELECT Id ' +
                ' FROM reduivy__Study_Pathway_Term__c ' +
                ' WHERE reduivy__Study_Pathway__c = :studyPwId ' +
                ' ORDER BY reduivy__Term_Number__c ';

            Map<String, Object> sptBindParams = new Map<String, Object>();
            sptBindParams.put('studyPwId', studyPwId);

            for (reduivy__Study_Pathway_Term__c spt : (List<reduivy__Study_Pathway_Term__c>) Database.queryWithBinds(sptSoql, sptBindParams, AccessLevel.USER_MODE)){
                //loop to get all records
                studyPwTermIdsList.add(spt);
            }

            REDU_LightningResponse response = new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(studyPwTermIdsList));
            return response;

        } catch (QueryException qex){
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp){
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

}