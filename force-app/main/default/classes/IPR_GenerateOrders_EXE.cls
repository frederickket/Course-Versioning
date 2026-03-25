/**
 * @author      WDCi (VTan)
 * @date        Feb 2024
 * @group       Finance
 * @description Trigger to generate transaction order based on the matching study fee config.
 * @changehistory
 * ISS-002026 05-08-2024 VTan - New class
 * ISS-002504 04-06-2025 XW - fixed when specifying multipicklist condition
 * ISS-002536 18-07-2025 XiRouh - Added a check for the transaction type in the logic that verifies whether the term fee or annual fee has been charged to avoid duplicate charges
 * ISS-002510 30-07-2025 Lean - Changed the sequence of updating order due to the new validation rules to prevent confirmed order from being modified
 * ISS-002580 07-08-2025 XiRouh - Updated to create TRL only for IENs with statuses configured as 'Include In Fee' by adding a status filter to the IEN query
 */
public inherited sharing class IPR_GenerateOrders_EXE extends REDU_TriggerExecutable {

    /**
     * @description IEN statuses for which TRL should be generated
     */
    static final List<String> IEN_INCLUDE_IN_FEE_STATUSES = IEN_Helper.getIncludeInFeeStatuses();

    /**
     * @description AfterUpdate
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeAfterUpdate(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {
            
            Map<Id, reduivy__Individual_Academic_Progress__c> qualifiedIprMap = new Map<Id, reduivy__Individual_Academic_Progress__c>();
            for (reduivy__Individual_Academic_Progress__c newIpr : (List<reduivy__Individual_Academic_Progress__c>) newList) {
                reduivy__Individual_Academic_Progress__c oldIpr = (reduivy__Individual_Academic_Progress__c) oldMap.get(newIpr.Id);

                if (newIpr.reduivy__Generate_Transaction_Orders__c && newIpr.reduivy__Generate_Transaction_Orders__c != oldIpr.reduivy__Generate_Transaction_Orders__c && String.isNotBlank(newIpr.reduivy__Academic_Term__c)) {
                    
                    qualifiedIprMap.put(newIpr.Id, newIpr);
                }
            }

            if(!qualifiedIprMap.isEmpty()){
                processTrnOrders(qualifiedIprMap);
            }
        }
    }

    /**
     * @description Create transaction orders / order lines
     * @param iprMap Qualified individual academic progress map for which to create transaction order / order line
     * @return void
     */
    private void processTrnOrders(Map<Id, reduivy__Individual_Academic_Progress__c> iprMap){

        //Get existing transaction orders
        String troQuery = 'SELECT Id, ' +
            ' reduivy__Primary__c, ' +
            ' reduivy__Contact__c, ' +
            ' reduivy__Individual_Academic_Progress__c, ' +
            ' reduivy__Status__c' +
            ' FROM reduivy__Transaction_Order__c' +
            ' WHERE reduivy__Individual_Academic_Progress__c IN: iprIds ' +
            ' AND reduivy__Primary__c = true ' +
            ' AND reduivy__Status__c NOT IN : troVoidStatuses' +
            ' ORDER BY reduivy__Transaction_Date__c ASC';

        Map<String, Object> troBindParams = new Map<String, Object>{
            'iprIds' => iprMap.keySet(),
            'troVoidStatuses' => TRO_Helper.getVoidStatuses()
        };

        Map<Id, reduivy__Transaction_Order__c> iprTrnOrderMap = new Map<Id, reduivy__Transaction_Order__c>();
        for(reduivy__Transaction_Order__c trnOrder : (List<reduivy__Transaction_Order__c>) Database.queryWithBinds(troQuery, troBindParams, AccessLevel.USER_MODE)){
            
            iprTrnOrderMap.put(trnOrder.reduivy__Individual_Academic_Progress__c, trnOrder);
        }

        //Get study term details for transaction order creation
        Map<Id, reduivy__Study_Term__c> studyTermMap = new Map<Id, reduivy__Study_Term__c>();
        for(reduivy__Individual_Academic_Progress__c ipr : iprMap.values()){

            studyTermMap.put(ipr.reduivy__Academic_Term__c, null);
        }
        
        String studyTermQuery = 'SELECT Id, ' +
            ' Name, ' + 
            ' reduivy__Fee_Due_Date__c, ' +
            ' reduivy__Apply_Payment__c, ' +
            ' reduivy__Apply_Non_Repayable_FA__c, ' +
            ' reduivy__Apply_Repayable_FA__c, ' +
            ' reduivy__Academic_Year__c' +
            ' FROM reduivy__Study_Term__c' +
            ' WHERE Id IN: studyTermIds';

        Map<String, Object> studyTermBindParams = new Map<String, Object>{
            'studyTermIds' => studyTermMap.keySet()
        };

        for(reduivy__Study_Term__c studyTerm : (List<reduivy__Study_Term__c>) Database.queryWithBinds(studyTermQuery, studyTermBindParams, AccessLevel.USER_MODE)){

            studyTermMap.put(studyTerm.Id, studyTerm);
        }
        
        //Process transaction order for each of the individual academic progress
        List<reduivy__Transaction_Order__c> trnOrderList = new List<reduivy__Transaction_Order__c>();
        Map<Id, reduivy__Individual_Academic_Progress__c> trnOrderIdIprMap = new Map<Id, reduivy__Individual_Academic_Progress__c>();
        Map<Id, reduivy__Individual_Academic_Progress__c> qualifiedIprToUpdateMap = new Map<Id, reduivy__Individual_Academic_Progress__c>();
        
        for(reduivy__Individual_Academic_Progress__c ipr : iprMap.values()){

            //Skip if the academic term doesn't have a fee due date
            if(studyTermMap.get(ipr.reduivy__Academic_Term__c).reduivy__Fee_Due_Date__c == null){
                ipr.addError(String.format(Label.Error_Generate_New_Transaction_Order_Invalid_Due_Date, new List<String>{STM_Helper.getObjectLabel(), ipr.Name}));
                continue;
            }

            //Skip if the student fee type is empty
            if(String.isBlank(ipr.reduivy__Student_Fee_Type__c)){
                ipr.addError(String.format(Label.Error_Generate_New_Transaction_Order_Missing_Student_Fee_Type, new List<String>{ipr.Name}));
                continue;
            }

            if(ipr.reduivy__Order_Generation_Action__c == IPR_Helper.ORDER_GENERATION_ACTION_NEW_ONLY){

                if(iprTrnOrderMap.containsKey(ipr.Id)){

                    //return error if primary transaction order existed
                    ipr.addError(String.format(Label.Error_Generate_New_Transaction_Order, new List<String>{TRO_Helper.getObjectLabel(), ipr.Name}));
                }else{
                    trnOrderList.add(IPR_Helper.createPrimaryTrnOrder(ipr, studyTermMap.get(ipr.reduivy__Academic_Term__c)));
                    qualifiedIprToUpdateMap.put(ipr.Id, ipr);
                }

            }else if(ipr.reduivy__Order_Generation_Action__c == IPR_Helper.ORDER_GENERATION_ACTION_REGENERATION){

                if(iprTrnOrderMap.containsKey(ipr.Id)){

                    if(TRO_Helper.getDraftStatuses().contains(iprTrnOrderMap.get(ipr.Id).reduivy__Status__c) || 
                    TRO_Helper.getSubmittedStatuses().contains(iprTrnOrderMap.get(ipr.Id).reduivy__Status__c) ||
                    TRO_Helper.getConfirmedStatuses().contains(iprTrnOrderMap.get(ipr.Id).reduivy__Status__c)){

                        reduivy__Transaction_Order__c trnOrderExisting = iprTrnOrderMap.get(ipr.Id);
                        trnOrderExisting.reduivy__Status__c = TRO_Helper.getDraftStatuses().get(0);
                        trnOrderList.add(trnOrderExisting);
                        
                        //Save the transaction order Ids so we can delete the related transaction line item/ map for error handling
                        trnOrderIdIprMap.put(iprTrnOrderMap.get(ipr.Id).Id, ipr);
                        qualifiedIprToUpdateMap.put(ipr.Id, ipr);
                    }else{

                        ipr.addError(String.format(Label.Error_Regenerate_Transaction_Order, new List<String>{TRO_Helper.getObjectLabel(), ipr.Name}));
                    }
                    
                }else{
                    trnOrderList.add(IPR_Helper.createPrimaryTrnOrder(ipr, studyTermMap.get(ipr.reduivy__Academic_Term__c)));
                    qualifiedIprToUpdateMap.put(ipr.Id, ipr);
                }
            }
        }

        //create or update the transaction order with status = draft first
        if(!trnOrderList.isEmpty()){
            REDU_Database_UTIL.doUpsert(trnOrderList, iprMap, 'reduivy__Individual_Academic_Progress__c', false);
        }

        //Delete transaction line item for the existing transaction order
        if(!trnOrderIdIprMap.isEmpty()){

            String trnLineItemQuery = 'SELECT Id, ' + 
                ' reduivy__Transaction_Order__r.reduivy__Individual_Academic_Progress__c ' +
                ' FROM reduivy__Transaction_Line_Item__c' +
                ' WHERE reduivy__Transaction_Order__c IN: trnOrderIds';

            Map<String, Object> trnLineItemBindParams = new Map<String, Object>{
                'trnOrderIds' => trnOrderIdIprMap.keySet()
            };

            List<reduivy__Transaction_Line_Item__c> deleteTrnLineItem = new List<reduivy__Transaction_Line_Item__c>();
            for(reduivy__Transaction_Line_Item__c tli : (List<reduivy__Transaction_Line_Item__c>) Database.queryWithBinds(trnLineItemQuery, trnLineItemBindParams, AccessLevel.USER_MODE)){
                deleteTrnLineItem.add(tli);
            }

            if(!deleteTrnLineItem.isEmpty()){
                //Delete records regardless of ownership using system mode
                REDU_SystemMode_UTIL.doDelete(deleteTrnLineItem, trnOrderIdIprMap, 'reduivy__Transaction_Order__c', false);
            }
        }

        //recreate transaction line items
        if(!trnOrderList.isEmpty()){
            createTrnLineItems(qualifiedIprToUpdateMap, trnOrderList, studyTermMap);

            //Update the transaction order status from draft to confirm
            String troConfirmedStatus = TRO_Helper.getConfirmedStatuses().get(0);
            List<reduivy__Transaction_Order__c> trnOrderUpdateList = new List<reduivy__Transaction_Order__c>();
            for (reduivy__Transaction_Order__c trnOrder : trnOrderList) {
                reduivy__Transaction_Order__c troUpdate = new reduivy__Transaction_Order__c(
                    Id = trnOrder.Id,
                    reduivy__Status__c = troConfirmedStatus
                );

                trnOrderUpdateList.add(troUpdate);
            }

            if(!trnOrderUpdateList.isEmpty()){
                REDU_Database_UTIL.doUpsert(trnOrderUpdateList, iprMap, 'reduivy__Individual_Academic_Progress__c', false);
            }
        }
    }

    /**
     * @description Creates a Fee Line for a given Student Fee
     * @param iprMap Qualified individual academic progress map for which to create transaction order / order line
     * @return void
     */
    private void createTrnLineItems(Map<Id, reduivy__Individual_Academic_Progress__c> iprMap, List<reduivy__Transaction_Order__c> trnOrderList, Map<Id, reduivy__Study_Term__c> studyTermMap){
        
        //Get individual pathway, study fee config, study fee matrix, and study fee matrix item information
        Map<Id, List<reduivy__Individual_Pathway__c>> iprIdvPathwayMap = new Map<Id, List<reduivy__Individual_Pathway__c>>();
        Map<Id, List<reduivy__Study_Fee_Matrix__c>> feeConfigMatrixMap = new Map<Id, List<reduivy__Study_Fee_Matrix__c>>();
        Map<Id, List<reduivy__Study_Fee_Matrix_Item__c>> feeMatrixItemMap = new Map<Id, List<reduivy__Study_Fee_Matrix_Item__c>>();
        Set<Id> academicYearIds = new Set<Id>();
        Set<Id> annualFeeIds = new Set<Id>();
        Set<Id> termFeeIds = new Set<Id>();
        String idvPathwayQuery = 'SELECT Id, ' + 
            ' reduivy__Individual_Academic_Progress__c, ' +
            ' reduivy__Individual_Program_Enrollment__c, ' +
            ' reduivy__Academic_Term__c, ' +
            ' reduivy__Term_Number__c, ' +
            ' reduivy__Academic_Term__r.reduivy__Academic_Year__c, ' +
            ' reduivy__Academic_Term__r.reduivy__Fee_Due_Date__c, ' + 
            ' reduivy__Individual_Program_Enrollment__r.reduivy__Study_Plan__r.reduivy__Study_Fee_Config__c, ' +
            ' reduivy__Individual_Academic_Progress__r.reduivy__Student_Fee_Type__c ' +
            ' FROM reduivy__Individual_Pathway__c' +
            ' WHERE reduivy__Individual_Academic_Progress__c IN: iprIds' + 
            ' AND reduivy__Individual_Program_Enrollment__r.RecordTypeId =: masterRTId' + 
            ' AND reduivy__Individual_Program_Enrollment__r.reduivy__Enrollment_Status__c IN: inProgressStatuses';

        Map<String, Object> idvPathwayBindParams = new Map<String, Object>{
            'iprIds' => iprMap.keySet(),
            'masterRTId' => IPE_Helper.getMasterEnrollmentRecordTypeId(),
            'inProgressStatuses' => IPE_Helper.getInProgressStatuses()
        };

        Set<String> qualifiedStudentTypes = new Set<String>();
        Date earliestDueDate;
        Date latestDueDate;
        for(reduivy__Individual_Pathway__c idvPathway : (List<reduivy__Individual_Pathway__c>) Database.queryWithBinds(idvPathwayQuery, idvPathwayBindParams, AccessLevel.USER_MODE)){
            
            if(iprIdvPathwayMap.containsKey(idvPathway.reduivy__Individual_Academic_Progress__c)){
                iprIdvPathwayMap.get(idvPathway.reduivy__Individual_Academic_Progress__c).add(idvPathway);
            }else{
                iprIdvPathwayMap.put(idvPathway.reduivy__Individual_Academic_Progress__c, new List<reduivy__Individual_Pathway__c>{idvPathway});
            }

            if(String.isNotBlank(idvPathway.reduivy__Individual_Program_Enrollment__r.reduivy__Study_Plan__r.reduivy__Study_Fee_Config__c)){
                feeConfigMatrixMap.put(idvPathway.reduivy__Individual_Program_Enrollment__r.reduivy__Study_Plan__r.reduivy__Study_Fee_Config__c, null);
            }

            if(String.isNotBlank(idvPathway.reduivy__Individual_Academic_Progress__r.reduivy__Student_Fee_Type__c)){
                qualifiedStudentTypes.add(idvPathway.reduivy__Individual_Academic_Progress__r.reduivy__Student_Fee_Type__c);
            }

            if(earliestDueDate == null){
                earliestDueDate = idvPathway.reduivy__Academic_Term__r.reduivy__Fee_Due_Date__c;
            }else if(idvPathway.reduivy__Academic_Term__r.reduivy__Fee_Due_Date__c < earliestDueDate){
                earliestDueDate = idvPathway.reduivy__Academic_Term__r.reduivy__Fee_Due_Date__c;
            }

            if(latestDueDate == null){
                latestDueDate = idvPathway.reduivy__Academic_Term__r.reduivy__Fee_Due_Date__c;
            }else if(idvPathway.reduivy__Academic_Term__r.reduivy__Fee_Due_Date__c > latestDueDate){
                latestDueDate = idvPathway.reduivy__Academic_Term__r.reduivy__Fee_Due_Date__c;
            }
        }

        Map<String, Object> studyFeeMatrixBindParams = new Map<String, Object>{
            'studyFeeConfigIds' => feeConfigMatrixMap.keySet(),
            'statusActive' => SMX_Helper.STATUS_ACTIVE,
            'earliestDueDate' => earliestDueDate,
            'latestDueDate' => latestDueDate
        };

        Map<String, Object> qualifiedStudentTypesBindMap = REDU_Database_UTIL.getMultiPicklistBindMap('studentFeeType', new List<String>(qualifiedStudentTypes));
        studyFeeMatrixBindParams.putAll(qualifiedStudentTypesBindMap);
        Set<String> qualifiedStudentTypePlaceholders = REDU_Database_UTIL.getMultiPicklistPlaceholders(qualifiedStudentTypesBindMap.keySet());
        
        String studyFeeMatrixQuery = 'SELECT Id, ' +
            ' reduivy__Study_Fee_Config__c, ' +
            ' reduivy__Applicable_Student_Fee_Types__c, ' +
            ' reduivy__Status__c, reduivy__From_Date__c, ' + 
            ' reduivy__To_Date__c' +
            ' FROM reduivy__Study_Fee_Matrix__c' +
            ' WHERE reduivy__Study_Fee_Config__c IN: studyFeeConfigIds' + 
            ' AND reduivy__Status__c =: statusActive' +
            ' AND reduivy__Applicable_Student_Fee_Types__c INCLUDES ( ' + String.join(qualifiedStudentTypePlaceholders, ', ') + ' )' +
            ' AND (reduivy__To_Date__c >= :earliestDueDate OR reduivy__To_Date__c = null)' +
            ' AND (reduivy__From_Date__c <= :latestDueDate)';

        for(reduivy__Study_Fee_Matrix__c studyFeeMatrix : (List<reduivy__Study_Fee_Matrix__c>) Database.queryWithBinds(studyFeeMatrixQuery, studyFeeMatrixBindParams, AccessLevel.USER_MODE)){

            if(feeConfigMatrixMap.get(studyFeeMatrix.reduivy__Study_Fee_Config__c) != null){
                feeConfigMatrixMap.get(studyFeeMatrix.reduivy__Study_Fee_Config__c).add(studyFeeMatrix);
            }else{
                feeConfigMatrixMap.put(studyFeeMatrix.reduivy__Study_Fee_Config__c, new List<reduivy__Study_Fee_Matrix__c>{studyFeeMatrix});
            }

            feeMatrixItemMap.put(studyFeeMatrix.Id, null);
        }

        String studyFeeMatrixItemQuery = 'SELECT Id, ' +
            ' reduivy__Type__c, ' +
            ' reduivy__Study_Fee_Matrix__c, ' +
            ' reduivy__Study_Fee_Matrix__r.reduivy__Study_Fee_Config__c, ' +
            ' reduivy__Amount__c, ' +
            ' reduivy__Applicable_for_Attempt_Number__c,' +
            ' reduivy__Applicable_For_Study_Unit__c, ' +
            ' reduivy__Applicable_For_Term__c, ' +
            ' reduivy__Study_Fee__c, reduivy__Study_Fee__r.Name, ' +
            ' reduivy__Study_Fee__r.reduivy__Item_Type__c, ' +
            ' reduivy__Study_Fee__r.reduivy__Description_for_Transactions__c' +
            ' FROM reduivy__Study_Fee_Matrix_Item__c' +
            ' WHERE reduivy__Study_Fee_Matrix__c IN: studyFeeMatrixIds';

        Map<String, Object> studyFeeMatrixItemBindParams = new Map<String, Object>{
            'studyFeeMatrixIds' => feeMatrixItemMap.keySet()
        };

        for(reduivy__Study_Fee_Matrix_Item__c studyFeeMatrixItem : (List<reduivy__Study_Fee_Matrix_Item__c>) Database.queryWithBinds(studyFeeMatrixItemQuery, studyFeeMatrixItemBindParams, AccessLevel.USER_MODE)){
            
            if(feeMatrixItemMap.get(studyFeeMatrixItem.reduivy__Study_Fee_Matrix__c) != null){
                feeMatrixItemMap.get(studyFeeMatrixItem.reduivy__Study_Fee_Matrix__c).add(studyFeeMatrixItem);
            }else{
                feeMatrixItemMap.put(studyFeeMatrixItem.reduivy__Study_Fee_Matrix__c, new List<reduivy__Study_Fee_Matrix_Item__c>{studyFeeMatrixItem});
            }

            if(studyFeeMatrixItem.reduivy__Type__c == SMI_Helper.TYPE_PER_ACADEMIC_TERM){
                termFeeIds.add(studyFeeMatrixItem.reduivy__Study_Fee__c);
            }else if(studyFeeMatrixItem.reduivy__Type__c == SMI_Helper.TYPE_PER_ACADEMIC_YEAR){
                annualFeeIds.add(studyFeeMatrixItem.reduivy__Study_Fee__c);
            }
        }

        //Query individual enrollment related to the individual academic progress
        Map<Id, List<reduivy__Individual_Enrollment__c>> iprIenMap = new Map<Id, List<reduivy__Individual_Enrollment__c>>();
        String ienQuery = 'SELECT Id, ' +
            ' reduivy__Credits_Offered__c, ' +
            ' reduivy__Attempt_Number__c, ' +
            ' reduivy__Individual_Academic_Progress__c, ' +
            ' reduivy__Target_Unit_Id__c, ' +
            ' reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Unit_Code__c, ' +
            ' (SELECT Id, ' +
                ' reduivy__Master_Individual_Program_Enrollment_Id__c, ' +
                ' reduivy__Individual_Program_Enrollment__r.reduivy__Study_Plan__r.reduivy__Study_Fee_Config__c ' +
                ' FROM reduivy__Individual_Plan_Units__r)' +
            ' FROM reduivy__Individual_Enrollment__c' +
            ' WHERE reduivy__Individual_Academic_Progress__c IN: iprIds ' + 
            ' AND reduivy__Enrollment_Status__c IN: includeInFeeStatuses '; //ISS-002580

        Map<String, Object> ienBindParams = new Map<String, Object>{
            'iprIds' => iprMap.keySet(),
            'includeInFeeStatuses' => IEN_INCLUDE_IN_FEE_STATUSES //ISS-002580
        };

        for(reduivy__Individual_Enrollment__c ien : (List<reduivy__Individual_Enrollment__c>) Database.queryWithBinds(ienQuery, ienBindParams, AccessLevel.USER_MODE)){
            if(iprIenMap.containsKey(ien.reduivy__Individual_Academic_Progress__c)){
                iprIenMap.get(ien.reduivy__Individual_Academic_Progress__c).add(ien);
            }else{
                iprIenMap.put(ien.reduivy__Individual_Academic_Progress__c, new List<reduivy__Individual_Enrollment__c>{ien});
            }
        }

        //Query transaction fee lines for previous current terms or current academic years
        for(reduivy__Study_Term__c studyTerm : studyTermMap.values()){

            if(String.isNotBlank(studyTerm.reduivy__Academic_Year__c)){
                academicYearIds.add(studyTerm.reduivy__Academic_Year__c);
            }
        }

        Set<Id> qualifiedContactId = new Set<Id>();
        for(reduivy__Transaction_Order__c tro : trnOrderList){
            qualifiedContactId.add(tro.reduivy__Contact__c);
        }

        Map<String, Set<Id>> termKeyStudyFeesMap = new Map<String, Set<Id>>();
        String trlAnnualTermFeeQuery = 'SELECT Id, ' +
            ' reduivy__Transaction_Type__c, ' +
            ' reduivy__Study_Fee_Matrix_Item__r.reduivy__Study_Fee__c, ' +
            ' reduivy__Transaction_Order__r.reduivy__Contact__c, ' +
            ' reduivy__Transaction_Order__r.reduivy__Individual_Academic_Progress__r.reduivy__Academic_Term__c, ' +
            ' reduivy__Transaction_Order__r.reduivy__Individual_Academic_Progress__r.reduivy__Academic_Term__r.reduivy__Academic_Year__c ' +
            ' FROM reduivy__Transaction_Line_Item__c ' +
            ' WHERE reduivy__Transaction_Type__c = :orderLineTransactionType ' + //ISS-002536 - The check for whether the term fee or annual fee has been charged should be based only on the order line
            ' AND reduivy__Transaction_Order__r.reduivy__Contact__c IN: qualifiedContactId AND ' + 
            ' ((reduivy__Transaction_Order__r.reduivy__Individual_Academic_Progress__r.reduivy__Academic_Term__c IN: studyTermIds AND reduivy__Study_Fee_Matrix_Item__r.reduivy__Study_Fee__c IN :termFeeIds) OR' + 
            ' (reduivy__Transaction_Order__r.reduivy__Individual_Academic_Progress__r.reduivy__Academic_Term__r.reduivy__Academic_Year__c IN: academicYearIds AND reduivy__Study_Fee_Matrix_Item__r.reduivy__Study_Fee__c IN: annualFeeIds))';

        Map<String, Object> trlAnnualTermFeeBindParams = new Map<String, Object>{
            'qualifiedContactId' => qualifiedContactId,
            'studyTermIds' => studyTermMap.keySet(),
            'termFeeIds' => termFeeIds,
            'academicYearIds' => academicYearIds,
            'annualFeeIds' => annualFeeIds,
            'orderLineTransactionType' => TRL_Helper.TRANSACTION_TYPE_ORDERLINE
        };

        for(reduivy__Transaction_Line_Item__c trl : (List<reduivy__Transaction_Line_Item__c>) Database.queryWithBinds(trlAnnualTermFeeQuery, trlAnnualTermFeeBindParams, AccessLevel.USER_MODE)){

            //Assign term fee per contact
            String termkey = trl.reduivy__Transaction_Order__r.reduivy__Contact__c + '|' + trl.reduivy__Transaction_Order__r.reduivy__Individual_Academic_Progress__r.reduivy__Academic_Term__c;
            if(!termKeyStudyFeesMap.containsKey(termkey)){
                termKeyStudyFeesMap.put(termkey, new Set<Id>{trl.reduivy__Study_Fee_Matrix_Item__r.reduivy__Study_Fee__c});
            }else{
                termKeyStudyFeesMap.get(termkey).add(trl.reduivy__Study_Fee_Matrix_Item__r.reduivy__Study_Fee__c);
            }

            //Assign academic year fee per contact
            String academicYearkey = trl.reduivy__Transaction_Order__r.reduivy__Contact__c + '|' + trl.reduivy__Transaction_Order__r.reduivy__Individual_Academic_Progress__r.reduivy__Academic_Term__r.reduivy__Academic_Year__c;
            if(!termKeyStudyFeesMap.containsKey(academicYearkey)){
                termKeyStudyFeesMap.put(academicYearkey, new Set<Id>{trl.reduivy__Study_Fee_Matrix_Item__r.reduivy__Study_Fee__c});
            }else{
                termKeyStudyFeesMap.get(academicYearkey).add(trl.reduivy__Study_Fee_Matrix_Item__r.reduivy__Study_Fee__c);
            }
        }

        //Check for matching study fee matrix
        Map<Id, Id> idvPathwayIdFeeMatrixIdMap = new Map<Id, Id>();
        for(reduivy__Individual_Academic_Progress__c ipr : iprMap.values()){

            if(iprIdvPathwayMap.containsKey(ipr.Id)){

                for(reduivy__Individual_Pathway__c idvPathway : iprIdvPathwayMap.get(ipr.Id)){

                    if(String.isNotBlank(idvPathway.reduivy__Individual_Program_Enrollment__r.reduivy__Study_Plan__r.reduivy__Study_Fee_Config__c) && 
                    feeConfigMatrixMap.containsKey(idvPathway.reduivy__Individual_Program_Enrollment__r.reduivy__Study_Plan__r.reduivy__Study_Fee_Config__c) &&
                    feeConfigMatrixMap .get(idvPathway.reduivy__Individual_Program_Enrollment__r.reduivy__Study_Plan__r.reduivy__Study_Fee_Config__c) != null){

                        for(reduivy__Study_Fee_Matrix__c studyFeeMatrix : feeConfigMatrixMap.get(idvPathway.reduivy__Individual_Program_Enrollment__r.reduivy__Study_Plan__r.reduivy__Study_Fee_Config__c)){

                            Date feeDueDate = studyTermMap.get(iprMap.get(ipr.Id).reduivy__Academic_Term__c).reduivy__Fee_Due_Date__c;
                            List<String> studFeeTypeSelections = studyFeeMatrix.reduivy__Applicable_Student_Fee_Types__c.split(';');

                            if(feeDueDate >= studyFeeMatrix.reduivy__From_Date__c && 
                                (studyFeeMatrix.reduivy__To_Date__c == null || feeDueDate <= studyFeeMatrix.reduivy__To_Date__c) &&
                                String.isNotBlank(ipr.reduivy__Student_Fee_Type__c) && 
                                studFeeTypeSelections.contains(ipr.reduivy__Student_Fee_Type__c)
                            ){

                                if(idvPathwayIdFeeMatrixIdMap.containsKey(idvPathway.Id)){

                                    //Return error if multiple study fee matrix found
                                    ipr.addError(String.format(Label.Error_Multiple_Study_Fee_Matrix_Found, new List<String>{TRO_Helper.getObjectLabel(), SMX_Helper.getObjectLabel(), ipr.Name}));
                                }else{

                                    idvPathwayIdFeeMatrixIdMap.put(idvPathway.Id, studyFeeMatrix.id);
                                }
                            }
                        }
                    }//Else no study fee matrix found for individual pathway
                }
            }
        }

        //Start creating transaction line item
        Map<Id, reduivy__Individual_Academic_Progress__c> trnOrderIdIprMap = new Map<Id, reduivy__Individual_Academic_Progress__c>(); //For error handling
        if(!idvPathwayIdFeeMatrixIdMap.isEmpty()){

            List<reduivy__Transaction_Line_Item__c> trnLineItemList = new List<reduivy__Transaction_Line_Item__c>();
            for(reduivy__Transaction_Order__c tro : trnOrderList){
                
                if(iprIdvPathwayMap.containsKey(tro.reduivy__Individual_Academic_Progress__c)){
                    for(reduivy__Individual_Pathway__c idvPathway : iprIdvPathwayMap.get(tro.reduivy__Individual_Academic_Progress__c)){

                        if(feeMatrixItemMap.containsKey(idvPathwayIdFeeMatrixIdMap.get(idvPathway.Id))){
                            for(reduivy__Study_Fee_Matrix_Item__c studyFeeMatrixItem : feeMatrixItemMap.get(idvPathwayIdFeeMatrixIdMap.get(idvPathway.Id))){

                                if(studyFeeMatrixItem.reduivy__Type__c == SMI_Helper.TYPE_PER_CREDIT){

                                    if(iprIenMap.containsKey(tro.reduivy__Individual_Academic_Progress__c)) {
                                        trnLineItemList.addAll(IPR_Helper.createPerCreditLineItems(studyFeeMatrixItem, tro, iprIenMap.get(tro.reduivy__Individual_Academic_Progress__c), idvPathway));
                                    }
                                    
                                }else if(studyFeeMatrixItem.reduivy__Type__c == SMI_Helper.TYPE_PER_STUDY_UNIT){

                                    if(iprIenMap.containsKey(tro.reduivy__Individual_Academic_Progress__c)) { 
                                        trnLineItemList.addAll(IPR_Helper.createPerStudyUnitLineItems(studyFeeMatrixItem, tro, iprIenMap.get(tro.reduivy__Individual_Academic_Progress__c), idvPathway));
                                    }
                                    
                                }else if(studyFeeMatrixItem.reduivy__Type__c == SMI_Helper.TYPE_PER_ACADEMIC_TERM){

                                    trnLineItemList.addAll(IPR_Helper.createPerTermLineItems(studyFeeMatrixItem, tro, termKeyStudyFeesMap, idvPathway));
                                }else if(studyFeeMatrixItem.reduivy__Type__c == SMI_Helper.TYPE_PER_ACADEMIC_YEAR){

                                    trnLineItemList.addAll(IPR_Helper.createPerAnnualLineItems(studyFeeMatrixItem, tro, termKeyStudyFeesMap, idvPathway));
                                }
                            }
                        }
                    }
                }

                if(!trnOrderIdIprMap.containsKey(tro.Id)){
                    trnOrderIdIprMap.put(tro.Id, iprMap.get(tro.reduivy__Individual_Academic_Progress__c));
                }
            }

            if(!trnLineItemList.isEmpty()){
                REDU_Database_UTIL.doInsert(trnLineItemList, trnOrderIdIprMap, 'reduivy__Transaction_Order__c', false);
            }
        }
    }
}