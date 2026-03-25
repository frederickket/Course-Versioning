/**
 * @author      WDCi (VTan)
 * @date        Feb 2024
 * @group       Finance
 * @description Queable job to trigger funding payment application for related transaction order when Apply Repayable/Non Repayable FA is checked (Academic Term).
 * @changehistory
 * ISS-001848 20-02-2024 VTan - New class
 */
public inherited sharing class STM_ApplyFundings_QUEUE implements Queueable {

    public Set<Id> transactionOrderIds;
    public List<List<Id>> transactionOrderIdsList;
	
    /**
     * @description
     * @param transactionOrderIdsList
     */
    public STM_ApplyFundings_QUEUE(List<List<Id>> transactionOrderIdsList) {
        
        if (transactionOrderIdsList == null || transactionOrderIdsList.isEmpty()) {
            this.transactionOrderIds = new Set<Id>();
        } else {
            this.transactionOrderIds = new Set<Id>(transactionOrderIdsList.get(0));

            transactionOrderIdsList.remove(0);
            this.transactionOrderIdsList = transactionOrderIdsList;
        }

        REDU_Logging_UTIL.debug('STM_ApplyFundings_QUEUE', transactionOrderIdsList);
    }

    public void execute(QueueableContext queueableContext) {

        Map<Id, reduivy__Transaction_Order__c> transactionOrderMap = new Map<Id, reduivy__Transaction_Order__c>();
        
        // Log start job
        REDU_Logging_UTIL.logInfo('Async Job Started', 'STM_ApplyFundings_QUEUE', STM_Helper.getApiName(), queueableContext.getJobId(), 'Processing ' + transactionOrderIds.size() + ' record(s) with Job Id ' + queueableContext.getJobId());

        SavePoint sp = Database.setSavePoint();

        try {

            Map<String, Object> troBindParams = new Map<String, Object>{
                'transactionOrderIds' => transactionOrderIds
            };
    
            String troQuery = 'SELECT Id, reduivy__Apply_Non_Repayable_FA__c, reduivy__Apply_Repayable_FA__c,' +
                ' reduivy__Individual_Academic_Progress__r.reduivy__Academic_Term__r.reduivy__Apply_Non_Repayable_FA__c, reduivy__Individual_Academic_Progress__r.reduivy__Academic_Term__r.reduivy__Apply_Repayable_FA__c' +
                ' FROM reduivy__Transaction_Order__c ' +
                ' WHERE Id IN: transactionOrderIds';
    
            updateTransactionOrder((List<reduivy__Transaction_Order__c>)Database.queryWithBinds(troQuery, troBindParams, AccessLevel.USER_MODE));

        } catch (Exception exp) {
            
            Database.rollback(sp);
            REDU_Logging_UTIL.debug(exp);
            REDU_Logging_UTIL.logError('Academic Term Update Transaction Order', 'STM_ApplyFundings_QUEUE', 'reduivy__Transaction_Order__c', null, JSON.serialize(transactionOrderMap.keySet(), true), exp);

        } finally {

            //Log job finished
            REDU_Logging_UTIL.logInfo('Async Job Ended', 'STM_ApplyFundings_QUEUE', STM_Helper.getApiName(), queueableContext.getJobId(), 'Processed ' + transactionOrderIds.size() + ' record(s) with Job Id ' + queueableContext.getJobId());
            
            if (!Test.isRunningTest() && this.transactionOrderIdsList != null && !this.transactionOrderIdsList.isEmpty()) {
                STM_ApplyFundings_QUEUE queueJob = new STM_ApplyFundings_QUEUE(this.transactionOrderIdsList);
                System.enqueueJob(queueJob);
            }
        }
    }

    /**
     * @description Update Transaction Order with Disburse Non Repayable FA and/or Disburse Repayable FA to true.
     * @param trnOrderToUpdate List<reduivy__Transaction_Order__c>
     */
    public void updateTransactionOrder(List<reduivy__Transaction_Order__c> trnOrderToUpdate){

        Map<Id, reduivy__Transaction_Order__c> transactionOrderMap = new Map<Id, reduivy__Transaction_Order__c>();
        for (reduivy__Transaction_Order__c trnOrder : trnOrderToUpdate){

            reduivy__Transaction_Order__c curTransactionOrder = new reduivy__Transaction_Order__c();
                curTransactionOrder.Id = trnOrder.Id;

                if(trnOrder.reduivy__Individual_Academic_Progress__r.reduivy__Academic_Term__r.reduivy__Apply_Non_Repayable_FA__c && !trnOrder.reduivy__Apply_Non_Repayable_FA__c){
    
                    curTransactionOrder.reduivy__Apply_Non_Repayable_FA__c = true;
                    transactionOrderMap.put(curTransactionOrder.Id, curTransactionOrder);
                }
    
                if(trnOrder.reduivy__Individual_Academic_Progress__r.reduivy__Academic_Term__r.reduivy__Apply_Repayable_FA__c && !trnOrder.reduivy__Apply_Repayable_FA__c){
    
                    curTransactionOrder.reduivy__Apply_Repayable_FA__c = true;
                    transactionOrderMap.put(curTransactionOrder.Id, curTransactionOrder);
                }
        }
        
        REDU_Logging_UTIL.debug('STM_ApplyFundings_QUEUE', transactionOrderMap);

        if(!transactionOrderMap.isEmpty()){
            REDU_Database_UTIL.doUpdate(transactionOrderMap.values());
        }
    }
}