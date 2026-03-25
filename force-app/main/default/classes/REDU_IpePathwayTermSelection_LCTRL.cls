/**
 * @author      WDCi (Lean)
 * @date        Sept 2023
 * @group       Enrollment Wizard
 * @description Term selection for enrollment wizard
 * @changehistory
 * ISS-001752 06-10-2023 Lean - New class
 * ISS-002330 20-03-2025 XW - get study term translation name
 * ISS-002367 11-04-2025 XW - Academic Term that has earlier start date than the previous term shouldnt be queried
 */
public with sharing class REDU_IpePathwayTermSelection_LCTRL {
    
    /**
     * @description Return a list of eligible academic term based on individual pathway
     * @param individualPeId
     * @return REDU_LightningResponse
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getAcademicTerms(Id individualPeId){

        try {
            Id eduInstId;
            Set<Id> selectedAcademicTermIds = new Set<Id>();
            Date greatestSelectedTermStartDate = null;

            //find the academic term that have been set on individual pathway so that we can skip them
            for (reduivy__Individual_Pathway__c ipw : [SELECT Id,
                reduivy__Academic_Term__c,
                reduivy__Academic_Term__r.reduivy__Start_Date__c,
                reduivy__Individual_Program_Enrollment__c,
                reduivy__Individual_Program_Enrollment__r.reduivy__Study_Program__c,
                reduivy__Individual_Program_Enrollment__r.reduivy__Study_Program__r.reduivy__Educational_Institution__c
                FROM reduivy__Individual_Pathway__c
                WHERE reduivy__Individual_Program_Enrollment__c =: individualPeId
                WITH USER_MODE
                ORDER BY reduivy__Academic_Term__r.reduivy__Start_Date__c DESC NULLS LAST
            ]) {

                eduInstId = ipw.reduivy__Individual_Program_Enrollment__r.reduivy__Study_Program__r.reduivy__Educational_Institution__c;
                if (String.isNotBlank(ipw.reduivy__Academic_Term__c)) {
                    selectedAcademicTermIds.add(ipw.reduivy__Academic_Term__c);
                }

                if(greatestSelectedTermStartDate == null && ipw.reduivy__Academic_Term__r.reduivy__Start_Date__c != null) {
                    greatestSelectedTermStartDate = ipw.reduivy__Academic_Term__r.reduivy__Start_Date__c;
                }
            }

            if (String.isNotBlank(eduInstId)) {
                String stmTranslationName = STM_Helper.getTranslationFieldNameForName();
                Set<String> fieldsToQuery = new Set<String> {
                    'Id',
                    'reduivy__Start_Date__c',
                    'reduivy__End_Date__c',
                    'reduivy__For_Internal_Only__c',
                    'reduivy__Display_Name__c',
                    stmTranslationName
                };

                Map<String, Object> bindMap = new Map<String, Object>();
                String soqlQuery = 'SELECT ' + String.join(fieldsToQuery, ', ')
                                + ' FROM reduivy__Study_Term__c'
                                + ' WHERE reduivy__Academic_Year__r.reduivy__Educational_Institution__c =: eduInstId'
                                + ' AND RecordTypeId =: termRecordTypeId'
                                + ' AND reduivy__End_Date__c >= TODAY'
                                + ' AND reduivy__Status__c =: statusActive';
                if(greatestSelectedTermStartDate != null) {
                    soqlQuery += ' AND reduivy__Start_Date__c > :greatestSelectedTermStartDate';
                    bindmap.put('greatestSelectedTermStartDate', greatestSelectedTermStartDate);
                }
                soqlQuery += (' ORDER BY reduivy__Start_Date__c, ' + stmTranslationName);

                bindmap.put('eduInstId', eduInstId);
                bindmap.put('termRecordTypeId', STM_Helper.getAcademicTermRecordTypeId());
                bindmap.put('statusActive', STM_Helper.STATUS_ACTIVE);

                List<reduivy__Study_Term__c> availableTerms = new List<reduivy__Study_Term__c>();
                for (reduivy__Study_Term__c term : (List<reduivy__Study_Term__c>) Database.queryWithBinds(soqlQuery, bindMap, AccessLevel.USER_MODE)) {
                    if (!selectedAcademicTermIds.contains(term.Id)) {
                        availableTerms.add(term);
                    }
                }

                return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(availableTerms));

            } else {
                return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, null);
            }

        } catch (QueryException qex) {
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }
	
}