/**
 * @author      WDCi (Lean)
 * @date        Aug 2023
 * @group       Misc
 * @description Trigger to validate and prevent the deletion of a parent record if it has child records. Please note that we only check the one for normal lookup relationship.
 * @changehistory
 * 
 */
public without sharing class SOBJ_DeleteValidation_EXE extends REDU_TriggerExecutable {
    
	/**
     * @description BeforeDelete
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeBeforeDelete(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        if (!oldList.isEmpty()) {
            doBeforeDeleteValidation(sobjResult, oldList);
        }
    }

    private void doBeforeDeleteValidation(Schema.DescribeSObjectResult objResult, List<SObject> oldList) {

        Map<Id, SObject> oldSObjectMap = new Map<Id, SObject>(oldList);

        List<Schema.ChildRelationship> childRelationships = objResult.getChildRelationships();
        List<Schema.ChildRelationship> qualifiedRelationships = new List<Schema.ChildRelationship>();
        Map<String, String> objectLabelMap = new Map<String, String>();
        Map<String, String> fieldLabelMap = new Map<String, String>();

        List<String> childObjSoqls = new List<String>();
        String childSoqlFormat = ' (SELECT Id FROM {0} {1} LIMIT 1) ';

        for (Schema.ChildRelationship cr : childRelationships) {
            if (cr.getRelationshipName() != null && !cr.isRestrictedDelete() && cr.getRelationshipName().endsWith('__r')) {

                REDU_Logging_UTIL.debug('cr.getRelationshipName', cr.getRelationshipName());
                
                Schema.DescribeSObjectResult childObjResult = cr.getChildSObject().getDescribe(SObjectDescribeOptions.DEFERRED);
                String childObjectName = childObjResult.getName();
                String childObjectLabel = childObjResult.getLabelPlural();
                String childRefFieldLabel = cr.getField().getDescribe().getLabel();

                objectLabelMap.put(cr.getRelationshipName(), childObjectLabel);
                fieldLabelMap.put(cr.getRelationshipName(), childRefFieldLabel);

                //we should exclude the records from validation if the child and parent are the same object
                String excludeDeletedRecordsClause = '';
                if (objResult.getName() == childObjectName) {
                    excludeDeletedRecordsClause = 'WHERE Id NOT IN: recordIds';
                }
                
                String childSoql = String.format(childSoqlFormat, new List<String>{cr.getRelationshipName(), excludeDeletedRecordsClause});
                childObjSoqls.add(childSoql);

                qualifiedRelationships.add(cr);
            }
        }

        if (!qualifiedRelationships.isEmpty()) {

            Map<String, Object> objectBindParams = new Map<String, Object>{
                'recordIds' => oldList
            };

            String objectSoqlTemplate = 'SELECT Id, {0} FROM {1} WHERE Id IN: recordIds';
            String objectSoql = String.format(objectSoqlTemplate, new List<String>{String.join(childObjSoqls, ', '), objResult.getName()});
            
            REDU_Logging_UTIL.debug('objectSoql', objectSoql);

            //Doing local system mode query here as the user may or may not have permission to read the child object.
            for (SObject recToDelete : Database.queryWithBinds(objectSoql, objectBindParams, AccessLevel.SYSTEM_MODE)) {
                Map<String, Object> populatedFieldsMap = recToDelete.getPopulatedFieldsAsMap();
                List<String> relatedChildWithRecords = new List<String>();

                for (Schema.ChildRelationship cr : qualifiedRelationships) {
                    String relName = cr.getRelationshipName();

                    if (populatedFieldsMap.containsKey(relName)) {
                        List<SObject> childRecords = recToDelete.getSObjects(relName);

                        if (!childRecords.isEmpty()) {
                            String objRefInfo = objectLabelMap.get(relName) + ' [' + fieldLabelMap.get(relName) + ']'; 
                            relatedChildWithRecords.add(objRefInfo);
                        }
                    } 

                }

                if (!relatedChildWithRecords.isEmpty()) {
                    oldSObjectMap.get(recToDelete.Id).addError(String.format(Label.Cannot_Delete_Child_Error, new List<String>{ String.join(relatedChildWithRecords, ', ') }));
                }
            }
        }
    }
	
}