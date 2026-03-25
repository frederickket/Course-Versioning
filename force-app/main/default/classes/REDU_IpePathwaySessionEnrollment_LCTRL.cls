/**
 * @author      WDCi (Sueanne)
 * @date        Sept 2024
 * @group       Enrollment wizard
 * @description Controller to handle study session enrollment needed data
 * @changehistory
 * ISS-002050 13-09-2024 Sueanne - new class
 */
public with sharing class REDU_IpePathwaySessionEnrollment_LCTRL {
    
    public static List<String> IEN_INPROGRESS_STATUSES = IEN_Helper.getInProgressStatuses();
    public static List<String> IEN_COMPLETED_STATUSES = IEN_Helper.getCompletedStatuses();

    /**
     * @description Find the related study offerings
     * @param masterIpeId
     * @param individualPathwayId
     * @return REDU_LightningResponse
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getStudyOfferings(Id masterIpeId, Id individualPathwayId, String studyOfferingTitleField){

        try{

            if(String.isBlank(masterIpeId) || String.isBlank(individualPathwayId)){
                throw new REDU_ApplicationException(Label.Error_Contact_Admin);
            }

            //get contactId from ipe
            List<reduivy__Individual_Program_Enrollment__c> ipeList = [
                SELECT Id, reduivy__Contact__c
                FROM reduivy__Individual_Program_Enrollment__c
                WHERE Id = :masterIpeId
                WITH USER_MODE
            ];
            reduivy__Individual_Program_Enrollment__c ipe;

            if(!ipeList.isEmpty()){
                ipe = ipeList[0];
            } else {
                throw new REDU_ApplicationException(String.format(Label.Invalid_Record_Id_For_Object_Type, new List<String>{masterIpeId, IPE_Helper.getObjectLabel()}));
            }

            //get termId from ipw
            List<reduivy__Individual_Pathway__c> ipwList = [
                SELECT Id, reduivy__Academic_Term__c
                FROM reduivy__Individual_Pathway__c
                WHERE Id = :individualPathwayId
                WITH USER_MODE
            ];
            reduivy__Individual_Pathway__c ipw;

            if(!ipwList.isEmpty()){
                ipw = ipwList[0];
            } else {
                throw new REDU_ApplicationException(String.format(Label.Invalid_Record_Id_For_Object_Type, new List<String>{individualPathwayId, IPW_Helper.getObjectLabel()}));
            }

            Set<String> ienStatuses = new Set<String>();
            ienStatuses.addAll(IEN_INPROGRESS_STATUSES);
            ienStatuses.addAll(IEN_COMPLETED_STATUSES);

            //get study offering Ids from individual enrollments
            Map<Id, Id> ienIdBySofId = new Map<Id, Id>();
            for(reduivy__Individual_Enrollment__c ien : [
                SELECT Id, reduivy__Study_Offering__c
                FROM reduivy__Individual_Enrollment__c
                WHERE reduivy__Enrollment_Status__c IN :ienStatuses
                AND reduivy__Contact__c = :ipe.reduivy__Contact__c
                AND reduivy__Academic_Term_Id__c = :ipw.reduivy__Academic_Term__c
                WITH USER_MODE
                ORDER BY reduivy__Enrollment_Date__c NULLS FIRST
            ]){
                ienIdBySofId.put(ien.reduivy__Study_Offering__c, ien.Id);
            }

            //get study offering
            String sofTranslationFieldName = SOF_Helper.getTranslationFieldNameForName();

            Set<String> sofFields = new Set<String>{
                'Id',
                'Name',
                'reduivy__Start_Date_Calculated__c',
                sofTranslationFieldName
            };

            if (String.isNotBlank(studyOfferingTitleField)) {
                sofFields.add(studyOfferingTitleField);
            }

            Map<String, Object> sofBindParams = new Map<String, Object>();
            sofBindParams.put('sofIds', ienIdBySofId.keySet());

            String sofSoql = 'SELECT ' + String.join(sofFields, ', ') +
                ' FROM reduivy__Study_Offering__c ' +
                ' WHERE Id IN: sofIds ';

            Map<Id, reduivy__Study_Offering__c> sofByIenId = new Map<Id, reduivy__Study_Offering__c>();
            for(reduivy__Study_Offering__c sof : (List<reduivy__Study_Offering__c>) Database.queryWithBinds(sofSoql, sofBindParams, AccessLevel.USER_MODE) ){
                sofByIenId.put(ienIdBySofId.get(sof.Id), sof);
            }

            return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(sofByIenId));

        } catch (QueryException qex) {
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }
}