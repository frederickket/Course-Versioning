/**
 * @author      WDCi (VTan)
 * @date        Aug 2024
 * @group       Transaction Order
 * @description This is to set the default values for Apply Non-Repayable FA, Apply Repayable FA, Apply Payment based on the value at the study term.
 * ISS-002026 20-08-2024 VTan - New class
 */
public inherited sharing class TRO_DefaultValues_EXE extends REDU_TriggerExecutable {
    
	/**
     * @description This is to ensure that the current trigger list doesn't contain duplicate default study plan
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeBeforeInsert(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {
        
        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {

            Map<Id, reduivy__Individual_Academic_Progress__c> iprMap = new Map<Id, reduivy__Individual_Academic_Progress__c>();
            List<reduivy__Transaction_Order__c> qualifiedTroList = new List<reduivy__Transaction_Order__c>();
            for (reduivy__Transaction_Order__c tro : (List<reduivy__Transaction_Order__c>) newList) {
                if (String.isNotBlank(tro.reduivy__Individual_Academic_Progress__c)) {
                    iprMap.put(tro.reduivy__Individual_Academic_Progress__c, null);
                    qualifiedTroList.add(tro);
                }
            }

            if(!iprMap.isEmpty()){

                String iprQuery = 'SELECT Id, reduivy__Academic_Term__c, reduivy__Academic_Term__r.reduivy__Apply_Non_Repayable_FA__c, reduivy__Academic_Term__r.reduivy__Apply_Repayable_FA__c, reduivy__Academic_Term__r.reduivy__Apply_Payment__c' +
                ' FROM reduivy__Individual_Academic_Progress__c' +
                ' WHERE Id IN : iprIds';

                Map<String, Object> iprBindParams = new Map<String, Object>{
                    'iprIds' => iprMap.keySet()
                };

                for(reduivy__Individual_Academic_Progress__c ipr : (List<reduivy__Individual_Academic_Progress__c>) Database.queryWithBinds(iprQuery, iprBindParams, AccessLevel.USER_MODE)){
                    iprMap.put(ipr.Id, ipr);
                }

                for(reduivy__Transaction_Order__c tro : qualifiedTroList) {

                    if(iprMap.containsKey(tro.reduivy__Individual_Academic_Progress__c)){

                        if(!tro.reduivy__Apply_Repayable_FA__c && iprMap.get(tro.reduivy__Individual_Academic_Progress__c).reduivy__Academic_Term__r.reduivy__Apply_Repayable_FA__c){
                            tro.reduivy__Apply_Repayable_FA__c = true;
                        }

                        if(!tro.reduivy__Apply_Payment__c && iprMap.get(tro.reduivy__Individual_Academic_Progress__c).reduivy__Academic_Term__r.reduivy__Apply_Payment__c){
                            tro.reduivy__Apply_Payment__c = true;
                        }

                        if(!tro.reduivy__Apply_Non_Repayable_FA__c && iprMap.get(tro.reduivy__Individual_Academic_Progress__c).reduivy__Academic_Term__r.reduivy__Apply_Non_Repayable_FA__c){
                            tro.reduivy__Apply_Non_Repayable_FA__c = true;
                        }
                    }
                }
            }
        }
    }
}