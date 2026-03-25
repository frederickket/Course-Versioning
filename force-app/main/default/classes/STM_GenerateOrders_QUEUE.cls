/**
 * @author      WDCi (VTan)
 * @date        Aug 2024
 * @group       Finance
 * @description Queable job to trigger update all related individual academic progress to generate transaction order.
 * @changehistory
 * ISS-002025 16-08-2024 VTan - New class
 */
public inherited sharing class STM_GenerateOrders_QUEUE implements Queueable {

    public Set<Id> iprIds;
    public List<List<Id>> iprIdsList;
	
    /**
     * @description
     * @param iprIdsList
     */
    public STM_GenerateOrders_QUEUE(List<List<Id>> iprIdsList) {
        if (iprIdsList == null || iprIdsList.isEmpty()) {
            this.iprIds = new Set<Id>();
        } else {
            this.iprIds = new Set<Id>(iprIdsList.get(0));

            iprIdsList.remove(0);
            this.iprIdsList = iprIdsList;
        }

        REDU_Logging_UTIL.debug('STM_GenerateOrders_QUEUE', iprIdsList);
    }

    public void execute(QueueableContext queueableContext) {

        Map<Id, reduivy__Individual_Academic_Progress__c> iprMap = new Map<Id, reduivy__Individual_Academic_Progress__c>();
        // Log start job
        REDU_Logging_UTIL.logInfo('Async Job Started', 'STM_GenerateOrders_QUEUE', STM_Helper.getObjectLabel(), queueableContext.getJobId(), 'Processing ' + iprIds.size() + ' record(s) with Job Id ' + queueableContext.getJobId());

        SavePoint sp = Database.setSavePoint();

        try {

            Map<String, Object> iprBindParams = new Map<String, Object>{
                'iprIds' => iprIds
            };
    
            String iprQuery = 'SELECT Id, reduivy__Generate_Transaction_Orders__c ' +
                ' FROM reduivy__Individual_Academic_Progress__c ' +
                ' WHERE Id IN: iprIds';
    
            updateIdvAcademicProgress((List<reduivy__Individual_Academic_Progress__c>)Database.queryWithBinds(iprQuery, iprBindParams, AccessLevel.USER_MODE));

        } catch (Exception exp) {
            
            Database.rollback(sp);
            REDU_Logging_UTIL.debug(exp);
            REDU_Logging_UTIL.logError('Academic Term Update Individual Academic Progress', 'STM_GenerateOrders_QUEUE', 'reduivy__Individual_Academic_Progress__c', null, JSON.serialize(iprMap.keySet(), true), exp);

        } finally {

            //Log job finished
            REDU_Logging_UTIL.logInfo('Async Job Ended', 'STM_GenerateOrders_QUEUE', STM_Helper.getObjectLabel(), queueableContext.getJobId(), 'Processed ' + iprIds.size() + ' record(s) with Job Id ' + queueableContext.getJobId());

            if (!Test.isRunningTest() && this.iprIdsList != null && !this.iprIdsList.isEmpty()) {
                STM_GenerateOrders_QUEUE queueJob = new STM_GenerateOrders_QUEUE(this.iprIdsList);
                System.enqueueJob(queueJob);
            }
        }

    }

    /**
     * @description Update Individual Academic Progress with Generate Transaction Orders equal to true.
     * @param iprToUpdate List<reduivy__Individual_Academic_Progress__c>
     */
    public void updateIdvAcademicProgress(List<reduivy__Individual_Academic_Progress__c> iprToUpdate){

        Map<Id, reduivy__Individual_Academic_Progress__c> iprMap = new Map<Id, reduivy__Individual_Academic_Progress__c>();
        for (reduivy__Individual_Academic_Progress__c ipr : iprToUpdate){

            reduivy__Individual_Academic_Progress__c curIpr = new reduivy__Individual_Academic_Progress__c();
                curIpr.Id = ipr.Id;

                if(!ipr.reduivy__Generate_Transaction_Orders__c){
    
                    curIpr.reduivy__Generate_Transaction_Orders__c = true;
                    iprMap.put(curIpr.Id, curIpr);
                }
        }
        
        REDU_Logging_UTIL.debug('STM_GenerateOrders_QUEUE', iprMap);

        if(!iprMap.isEmpty()){
            REDU_Database_UTIL.doUpdate(iprMap.values());
        }
    }
}