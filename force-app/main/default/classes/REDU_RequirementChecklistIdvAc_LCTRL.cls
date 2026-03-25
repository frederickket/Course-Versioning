/**
 * @author      WDCi (XW)
 * @date        Jan 2024
 * @group       Requirement Checklist 
 * @description Requirement Checklist Individual Achievement Modal Controller
 * @changehistory
 * ISS-002128 30-06-2025 XW - new class
 */

public with sharing class REDU_RequirementChecklistIdvAc_LCTRL {
    
    static final String RESPONSE_CDC_LIST = 'RESPONSE_CDC_LIST';
    static final String RESPONSE_IAC_LIST = 'RESPONSE_IAC_LIST';
    static final String RESPONSE_CDC_IAC_MAP = 'RESPONSE_CDC_IAC_MAP';
    static final String RESPONSE_CDCIAC_CDLID_MAP = 'RESPONSE_CDCIAC_CDLID_MAP';
    
    /**
     * @description get the related documents and individual achievements
     * @param  irqId                    irqId the individual requirement id
     * @param  conId                    conId the contact id 
     * @param  achievementDetailsFields additional Individual Achievement fields to be displayed on the screen
     * @return                          return REDU_LightningResponse
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getDocumentsAndIACs(String irqId, String conId, List<String> achievementDetailsFields){
        
        Map<String, Object> responseData = new Map<String, Object>();
        
        try {
            List<ContentDocument> cdcList = new List<ContentDocument>();
            List<reduivy__Individual_Achievement__c> iacList = new List<reduivy__Individual_Achievement__c>();
            Map<Id, Set<Id>> cdcToIacMap = new Map<Id, Set<Id>>();
            Map<String, Id> cdcIacToCdlMap = new Map<String, Id>();
            
            if(String.isNotBlank(irqId) && String.isNotBlank(conId)) {
                Set<Id> linkedEntityIds = new Set<Id>{ irqId };
                
                Set<String> iacFields = new Set<String>{'Id'};
                iacFields.addAll(achievementDetailsFields);

                Map<String, Schema.DescribeFieldResult> fieldsDescribe = REDU_Metadata_UTIL.describeSObjectFields(IAC_Helper.getApiName(), achievementDetailsFields);
                for(String fieldName : fieldsDescribe.keySet()) {
                    Schema.DescribeFieldResult fieldDescribe = fieldsDescribe.get(fieldName);
                    if(fieldDescribe.getType() == Schema.DisplayType.PICKLIST || fieldDescribe.getType() == Schema.DisplayType.MULTIPICKLIST) {
                        iacFields.add(REDU_Metadata_UTIL.getPicklistFieldLabelQuery(fieldName));
                    }
                }

                String iacQuery = 'SELECT ' + String.join(iacFields, ', ') +
                                ' FROM ' + IAC_Helper.getApiName() +
                                ' WHERE reduivy__Contact__c = :conId' +
                                ' ORDER BY CreatedDate ASC';
                Map<String, Object> iacBindMap = new Map<String, Object> {
                    'conId' => conId
                };

                //get the individual achievement of the contact
                for(reduivy__Individual_Achievement__c iac : (List<reduivy__Individual_Achievement__c>) Database.queryWithBinds(iacQuery, iacBindMap, AccessLevel.USER_MODE)) {
                    iacList.add(iac);
                    linkedEntityIds.add(iac.Id);
                }

                Set<Id> irqDocumentIdSet = new Set<Id>();
                List<ContentDocumentLink> allCdlLinkedToIac = new List<ContentDocumentLink>();
                for (ContentDocumentLink cdl : [
                    SELECT Id, 
                    LinkedEntityId,
                    ContentDocumentId,
                    ContentDocument.Title, 
                    ContentDocument.Id,
                    ContentDocument.FileExtension
                    FROM ContentDocumentLink
                    WHERE LinkedEntityId =: linkedEntityIds
                    WITH USER_MODE
                    ORDER BY ContentDocument.CreatedDate ASC
                ]) {
                    if (String.isBlank(cdl.ContentDocumentId)) {
                        continue;
                    }

                    //find only the content document that has linked to indiviudual requirement
                    if(cdl.LinkedEntityId == irqId) {
                        cdcToIacMap.put(cdl.ContentDocumentId, new Set<Id>());
                        irqDocumentIdSet.add(cdl.ContentDocumentId);
                        cdcList.add(cdl.ContentDocument);
                    } else {
                        allCdlLinkedToIac.add(cdl);
                    }
                    
                    cdcIacToCdlMap.put(cdl.ContentDocumentId + '_' + cdl.LinkedEntityId, cdl.Id);
                }

                //based on the content document that has linked to indiviudual requirement, we find the content document link that has linkage for both idv achievement and idv requirement
                //this is to make sure that there are documents uploaded/linked to the idv achievement
                for(Id documentId : irqDocumentIdSet) {
                    for(ContentDocumentLink cdl : allCdlLinkedToIac) {
                        if(cdl.ContentDocumentId == documentId) {
                            cdcToIacMap.get(cdl.ContentDocumentId).add(cdl.LinkedEntityId);
                        }
                    }
                }
            }

            responseData.put(RESPONSE_CDC_LIST, cdcList);
            responseData.put(RESPONSE_IAC_LIST, iacList);
            responseData.put(RESPONSE_CDC_IAC_MAP, cdcToIacMap);
            responseData.put(RESPONSE_CDCIAC_CDLID_MAP, cdcIacToCdlMap);

            return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(responseData));

        } catch (QueryException qex) {
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    /**
     * @description insert or delete the content document link based on the selection in requirement checklist
     * @param  cdlIdToDelete  list of content document link id to be deleted
     * @param  cdcToLinkToIac serialized map to show the new content document link relationship (Map<ContentDocumentId, Set<Individual Achievement Id>>) 
     * @return               REDU_LightningResponse
     */
    @AuraEnabled
    public static REDU_LightningResponse insertAndDeleteCdl(List<String> cdlIdToDelete, String cdcToLinkToIac){

        Savepoint sp = Database.setSavePoint();

        try {
            Set<Id> responseData = new Set<Id>();

            //insert new content document link
            List<ContentDocumentLink> cdlToInsert = new List<ContentDocumentLink>();
            if(String.isNotBlank(cdcToLinkToIac)) {

                Map<String, List<String>> cdcToLinkToIacMap = (Map<String, List<String>>) JSON.deserialize(cdcToLinkToIac, Map<String, List<String>>.class);
                if(!cdcToLinkToIacMap.isEmpty()) {
                    for(String cdcId : cdcToLinkToIacMap.keySet()) {
                        for(String iacId : cdcToLinkToIacMap.get(cdcId)) {
                            cdlToInsert.add(
                                new ContentDocumentLink(ContentDocumentId = cdcId, LinkedEntityId = iacId)
                            );
                        }
                    }
                }
                
                if(!cdlToInsert.isEmpty()) {
                    REDU_Database_UTIL.doInsert(cdlToInsert);
                }
            }

            //delete existing content document link
            List<ContentDocumentLink> cdlToDelete = new List<ContentDocumentLink>();
            if(cdlIdToDelete != null && !cdlIdToDelete.isEmpty()){
                for(String cdlId : cdlIdToDelete) {
                    cdlToDelete.add(
                        new ContentDocumentLink(Id = cdlId)
                    );
                }
            }

            if(!cdlToDelete.isEmpty()){
                REDU_Database_UTIL.doDelete(cdlToDelete);
            }

            for(ContentDocumentLink cdl : cdlToInsert) {
                responseData.add(cdl.Id);
            }

            for(ContentDocumentLink cdl : cdlToDelete) {
                responseData.add(cdl.Id);
            }

            return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(responseData));

        } catch (QueryException qex) {
            Database.rollback(sp);

            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {
            Database.rollback(sp);

            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }
}