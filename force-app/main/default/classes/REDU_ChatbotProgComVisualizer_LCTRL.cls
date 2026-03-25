/**
 * @author      WDCi (XW)
 * @date        May 2024
 * @group       
 * @description The controller class of the Program Completion Visualizer.
 * @changehistory
 * ISS-001916 20-05-2024 XW - Program Completion Visualizer
 * ISS-002187 26-11-2024 XW - add study plan id 
 */
public with sharing class REDU_ChatbotProgComVisualizer_LCTRL {
    public static final String MASTER_IPE = 'masterIpeRtId';
    public static final String CHILD_IPE = 'childIpeRtId';

	  /**
     * @description Get the Ipe with contact id based on the Ipe Id
     * @param  ipeId Id Ipe Id
     * @return       return REDU_LightningResponse that contains Contact
     */
    @AuraEnabled
    public static REDU_LightningResponse getIpeRecord(Id ipeId){
        try{

            Set<String> ipeFields = new Set<String>{
                'Id',
                'reduivy__Contact__c',
                'reduivy__Contact__r.Id',
                'reduivy__Study_Program__c'
            };

            Map<String, Object> ipeBindParams = new Map<String, Object>();
            ipeBindParams.put('ipeId', ipeId);

            String ipeSoql = 'SELECT ' + String.join(ipeFields, ', ') +
                ' FROM reduivy__Individual_Program_Enrollment__c ' +
                ' WHERE Id = :ipeId ';

            List<reduivy__Individual_Program_Enrollment__c> ipeList = new List<reduivy__Individual_Program_Enrollment__c>();
            for(reduivy__Individual_Program_Enrollment__c ipe : (List<reduivy__Individual_Program_Enrollment__c>) Database.queryWithBinds(ipeSoql, ipeBindParams, AccessLevel.USER_MODE)){
                ipeList.add(ipe);
            }

            REDU_LightningResponse response = new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, '');
            if (!ipeList.isEmpty()){
                response.responseData = JSON.serialize(ipeList[0]);
            }

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
     * @description getContactIdByUserId Get the contact by user id
     * @param  userId userId User Id
     * @return        return REDU_LightningResponse
     */ 
    @AuraEnabled
    public static REDU_LightningResponse getContactIdByUserId(Id userId){
        try{

            User user = USR_HELPER.getCurrentUserInfo(userId);
            return new REDU_LightningResponse(true, 'success', JSON.serialize(user));			

        } catch (QueryException qex){
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);
        } catch (Exception exp){
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    /**
     * @description getAllProgram Get all the program that is active
     * @return   return REDU_LightningResponse
     */ 
    @AuraEnabled
    public static REDU_LightningResponse getAllProgram(){
        try{
            Set<String> spgFields = new Set<String>{
                'Id',
                'Name'
            };

            Map<String, Object> spgBindParams = new Map<String, Object>();
            spgBindParams.put('status', SPG_HELPER.SPG_STATUS_ACTIVE);

            String spgSoql = 'SELECT ' + String.join(spgFields, ', ') + 
                ' FROM reduivy__Study_Program__c ' +
                ' WHERE reduivy__Status__c =: status ';

            List<reduivy__Study_Program__c> programList = new List<reduivy__Study_Program__c>();
            for(reduivy__Study_Program__c studyProgram : (List<reduivy__Study_Program__c>) Database.queryWithBinds(spgSoql, spgBindParams, AccessLevel.USER_MODE)){
                programList.add(studyProgram);
            }

            REDU_LightningResponse response = new REDU_LightningResponse(true, 'success', '');
            if (programList.isEmpty()){
                return response;
            }
            
            List<Map<String, String>> options = new List<Map<String, String>>();
            for(reduivy__Study_Program__c program: programList){
                Map<String, String> tempMap = new Map<String, String>();
                tempMap.put('value', program.Id);
                tempMap.put('label', program.Name);
                options.add(tempMap);
            }

            response.responseData = JSON.serialize(options);
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
     * @description getContactIdByUserId Get the enrolled ipe by a contact
     * @param  contactId contactId Contact Id
     * @return        return REDU_LightningResponse
     */ 
    @AuraEnabled
    public static REDU_LightningResponse getIpeProgramByContactId(Id contactId){
        try{

            List<String> inProgressStatuses = IPE_HELPER.getInProgressStatuses();

            Set<String> ipeFields = new Set<String>{
                'Id',
                'Name',
                'reduivy__Study_Program__r.Name',
                'reduivy__Study_Program__r.reduivy__Program_Code__c',
                'reduivy__Study_Program__r.Id',
                'reduivy__Study_Plan__r.reduivy__Type__c',
                'RecordTypeId'
            };

            Map<String, Object> ipeBindParams = new Map<String, Object>();
            ipeBindParams.put('contactId', contactId);
            ipeBindParams.put('inProgressStatuses', inProgressStatuses);

            String ipeSoql = 'SELECT ' + String.join(ipeFields, ', ') +
                ' FROM reduivy__Individual_Program_Enrollment__c ' +
                ' WHERE reduivy__Contact__c =: contactId ' +
                ' AND reduivy__Enrollment_Status__c =: inProgressStatuses ';

            List<Map<String, String>> options = new List<Map<String, String>>();

            for(reduivy__Individual_Program_Enrollment__c ipe : (List<reduivy__Individual_Program_Enrollment__c>) Database.queryWithBinds(ipeSoql, ipeBindParams, AccessLevel.USER_MODE)){
                Map<String, String> tempMap = new Map<String, String>();
                tempMap.put('label', ipe.Name + ' - ' + ipe.reduivy__Study_Program__r.Name);
                tempMap.put('value',  ipe.reduivy__Study_Program__r.Id);
                tempMap.put('ipeId', ipe.Id);
                tempMap.put('recordTypeId',  ipe.RecordTypeId);
                tempMap.put('type', ipe.reduivy__Study_Plan__r.reduivy__Type__c);
                tempMap.put('studyPlanId', ipe.reduivy__Study_Plan__c); //ISS-002187
                options.add(tempMap);
            }

            JSONGenerator gen = JSON.createGenerator(true);
            gen.writeStartObject();
            gen.writeObjectField('comboboxOptions', options);
            gen.writeStringField(MASTER_IPE, IPE_Helper.getMasterEnrollmentRecordTypeId());
            gen.writeStringField(CHILD_IPE, IPE_Helper.getChildEnrollmentRecordTypeId());
            gen.writeEndObject();

            REDU_LightningResponse response = new REDU_LightningResponse(true, 'success', gen.getAsString());

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
     * @description get the study plans of the given program id and return them in combobox options format
     * @param  programId programId program id
     * @return           return combobox options format string
     */ 
    @AuraEnabled
    public static REDU_LightningResponse getStudyPlansByProgramId(Id programId){
        try{
            Set<String> splFields = new Set<String>{
                'Id',
                'Name',
                'reduivy__Type__c'
            };

            Map<String, Object> splBindParams = new Map<String, Object>();
            splBindParams.put('programId', programId);
            splBindParams.put('status', SPL_HELPER.STATUS_ACTIVE);

            String splSoql = 'SELECT ' + String.join(splFields, ', ') + 
                ' FROM reduivy__Study_Plan__c ' +
                ' WHERE reduivy__Study_Program__r.Id =: programId  ' +
                ' AND reduivy__Status__c =: status';

            List<reduivy__Study_Plan__c> planList = new List<reduivy__Study_Plan__c>();
            for(reduivy__Study_Plan__c studyPlan : (List<reduivy__Study_Plan__c>) Database.queryWithBinds(splSoql, splBindParams, AccessLevel.USER_MODE)){
                planList.add(studyPlan);
            }

            REDU_LightningResponse response = new REDU_LightningResponse(true, 'success', '');
            if (!planList.isEmpty()){

                List<Map<String, String>> options = new List<Map<String, String>>();

                for (reduivy__Study_Plan__c spl : planList){
                    Map<String, String> tempMap = new Map<String, String>();
                    tempMap.put('value', spl.Id);
                    tempMap.put('label', spl.Name);
                    tempMap.put('type', spl.reduivy__Type__c);
                    options.add(tempMap);
                }

                response.responseData = JSON.serialize(options);
            }

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