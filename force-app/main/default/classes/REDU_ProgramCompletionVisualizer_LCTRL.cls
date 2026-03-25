/**
 * @author      WDCi (XW)
 * @date        May 2024
 * @group
 * @description Component of showing Result for Program Completion Visualizer
 * @changehistory
 * ISS-001916 20-05-2024 name - Program Completion Visualizer
 */
public with sharing class REDU_ProgramCompletionVisualizer_LCTRL{
    /**
     * @description create a preview ipe with progress calculated, return the ipe created
     * @param  contactId      the contact id of the ipe user
     * @param  studyProgramId id of the study program selected
     * @param  studyPlanId    id of the study program selected
     * @return REDU_LightningResponse
     */
    @AuraEnabled(cacheable = false)
    public static REDU_LightningResponse createPreviewIpe(Id contactId, Id studyProgramId, Id studyPlanId){
        try{
            Id recordTypeId = IPE_Helper.getMasterEnrollmentRecordTypeId();
            List<String> previewStatuses = IPE_Helper.getPreviewStatuses();

            reduivy__Individual_Program_Enrollment__c ipe = new reduivy__Individual_Program_Enrollment__c(
                reduivy__Contact__c = contactId, 
                reduivy__Study_Program__c = studyProgramId, 
                reduivy__Study_Plan__c = studyPlanId, 
                RecordTypeId = recordTypeId, 
                reduivy__Enrollment_Status__c = previewStatuses[0]
            );
            
            List<reduivy__Individual_Program_Enrollment__c> ipeList = new List<reduivy__Individual_Program_Enrollment__c>{ ipe };
            REDU_Database_UTIL.doInsert(ipeList);

            return new REDU_LightningResponse(true, 'success', JSON.serialize(ipe));

        } catch (QueryException qex){
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp){
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    /**
     * @description delete the preview ipe created just now
     * @param  ipeId the ipe that will be deleted in json format
     * @return         REDU_LightningResponse
     */
    @AuraEnabled(cacheable = false)
    public static REDU_LightningResponse deletePreviewIpe(Id ipeId){
        try{
            List<reduivy__Individual_Program_Enrollment__c> ipeList = [SELECT Id, Name
                FROM reduivy__Individual_Program_Enrollment__c
                WHERE Id = :ipeId
                WITH USER_MODE
            ];

            if (!ipeList.isEmpty()){
                //User needs to be able to delete regardless of ownership
                REDU_SystemMode_UTIL.doDelete(ipeList);
            }

            return new REDU_LightningResponse(true, 'success', ipeId);

        } catch (QueryException qex){

            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp){
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    /**
     * @description delete the existing ipe if any when creating a new one (the old ipe may be created in different page).
     * @param  contactId the contact Id
     * @return           REDU_LightningResponse
     */
    @AuraEnabled
    public static REDU_LightningResponse deleteExisitingPreviewIpe(Id contactId){
        try{

            List<String> previewStatuses = IPE_Helper.getPreviewStatuses();
            List<reduivy__Individual_Program_Enrollment__c> ipeList = [SELECT Id
                FROM reduivy__Individual_Program_Enrollment__c
                WHERE reduivy__Contact__r.Id = :contactId AND reduivy__Enrollment_Status__c in :previewStatuses
                WITH SYSTEM_MODE
            ];

            if (!ipeList.isEmpty()){
                //User needs to be able to delete regardless of ownership
                REDU_SystemMode_UTIL.doDelete(ipeList);
            }

            REDU_LightningResponse response = new REDU_LightningResponse(true, 'success', JSON.serialize(ipeList));
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