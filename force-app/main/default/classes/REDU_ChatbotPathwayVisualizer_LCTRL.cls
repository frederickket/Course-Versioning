/**
 * @author      WDCi (XW)
 * @date        May 2024
 * @group       Pathway visualizer
 * @description 
 * @changehistory
 * ISS-001917 20-05-2024 XW - Pathway Visualizer
 * ISS-002191 05-12-2024 XW - return empty list if default plan not found
 */
public with sharing class REDU_ChatbotPathwayVisualizer_LCTRL{
    

    /**
     * @description Get the Study Program Name and the Study Pathway Id. Group them into a map
     * @param  contactId contactId The Id of the contact
     * @return           return REDU_LightningResponse
     */
    @AuraEnabled
    public static REDU_LightningResponse getPathwayIdAndProgramName(Id contactId){
        try{

            List<String> inProgressStatuses = IPE_HELPER.getInProgressStatuses();

            Set<String> ipeFields = new Set<String>{
                'Id',
                'Name',
                'reduivy__Study_Pathway__c',
                'reduivy__Study_Program__r.Name',
                'reduivy__Study_Program__r.reduivy__Program_Code__c',
                'reduivy__Study_Plan__r.Name'
            };

            Map<String, Object> ipeBindParams = new Map<String, Object>();
            ipeBindParams.put('contactId', contactId);
            ipeBindParams.put('inProgressStatuses', inProgressStatuses);
            ipeBindParams.put('ipeMasterRtId', IPE_Helper.getMasterEnrollmentRecordTypeId());

            String ipeSoql = 'SELECT ' + String.join(ipeFields, ', ') +
                ' FROM reduivy__Individual_Program_Enrollment__c ' +
                ' WHERE reduivy__Contact__c = :contactId ' +
                ' AND reduivy__Enrollment_Status__c IN: inProgressStatuses ' +
                ' AND RecordTypeId =: ipeMasterRtId';

            List<reduivy__Individual_Program_Enrollment__c> ipeList = new List<reduivy__Individual_Program_Enrollment__c>();
            for(reduivy__Individual_Program_Enrollment__c ipe : (List<reduivy__Individual_Program_Enrollment__c>) Database.queryWithBinds(ipeSoql, ipeBindParams, AccessLevel.USER_MODE)){
                ipeList.add(ipe);
            }

            //ISS-002191
            List<Map<String, String>> options = new List<Map<String, String>>();
            
            if (!ipeList.isEmpty()){
                
                for (reduivy__Individual_Program_Enrollment__c ipe : ipeList){
                    Map<String, String> tempMap = new Map<String, String>();
                    tempMap.put('label', ipe.Name + ' - ' + ipe.reduivy__Study_Program__r.Name);
                    tempMap.put('value', ipe.reduivy__Study_Pathway__c);
                    tempMap.put('studyPlanName', ipe.reduivy__Study_Plan__r.Name);
                    options.add(tempMap);
                }
            }
            
            REDU_LightningResponse response = new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(options)); 
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
     * @description getDefaultStudyPlan Get the default Study Plan of a given Study Program
     * @param  studyProgramId studyProgramId The given Study Program    
     * @return                return REDU_LightningResponse
     */
    @AuraEnabled
    public static REDU_LightningResponse getDefaultStudyPlan(Id studyProgramId){
        try{

            Set<String> splFields = new Set<String>{
                'Id',
                'Name'
            };

            Map<String, Object> splBindParams = new Map<String, Object>();
            splBindParams.put('studyProgramId', studyProgramId);
            splBindParams.put('default', true);

            String splSoql = 'SELECT ' + String.join(splFields, ', ') + 
                ' FROM reduivy__Study_Plan__c ' +
                ' WHERE reduivy__Study_Program__c =: studyProgramId ' +
                ' AND reduivy__Default__c =: default';
            
            //ISS-002191
            List<reduivy__Study_Plan__c> defaultStudyPlanList = new List<reduivy__Study_Plan__c>();
            for(reduivy__Study_Plan__c studyPlan : (List<reduivy__Study_Plan__c>) Database.queryWithBinds(splSoql, splBindParams, AccessLevel.USER_MODE)){
                defaultStudyPlanList.add(studyPlan);
            }

            reduivy__Study_Plan__c defaultStudyPlan;
            if (defaultStudyPlanList.isEmpty()){
                defaultStudyPlan = new reduivy__Study_Plan__c();
            } else {
                defaultStudyPlan = defaultStudyPlanList[0];
            }
            
            return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(defaultStudyPlan));
            

        } catch (QueryException qex){
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);
        } catch (Exception exp){
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

}