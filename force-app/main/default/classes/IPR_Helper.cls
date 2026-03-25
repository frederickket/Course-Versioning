/**
 * @author      WDCi (Lean)
 * @date        Dec 2023
 * @group       Object Helper
 * @description Individual Academic Progress object helper class that contains the picklist option constants and object related methods
 * @changehistory
 * ISS-002026 25-10-2024 Lean - Removed the need of individual plan structure when generating transaction line for per credit and per study unit
 * ISS-002436 13-05-2025 XW - moved getIndividualEnrollments and unenrollIpr to helper class
 * ISS-002632 11-06-2025 XW - isMatrixItemApplicable always has the top priority when creating annual or term line item
 */
global inherited sharing class IPR_Helper implements SObject_Helper {

    /**
     * @description Individual Academic Progress's Order Generation Action picklist constants
     */
    public static final String ORDER_GENERATION_ACTION_NEW_ONLY = 'New Order Only';

    /**
     * @description Individual Academic Progress's Order Generation Action picklist constants
     */
    public static final String ORDER_GENERATION_ACTION_REGENERATION = 'Regeneration';
    
    /**
     * @description Student Fee Type - Domestic
     */
    public static final String STUDENT_FEE_TYPE_DOMESTIC = 'Domestic';

    /**
     * @description Student Fee Type - International
     */
    public static final String STUDENT_FEE_TYPE_INTERNATIONAL = 'International';

	/**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel() {
        return SObjectType.reduivy__Individual_Academic_Progress__c.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel() {
        return SObjectType.reduivy__Individual_Academic_Progress__c.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName() {
        return SObjectType.reduivy__Individual_Academic_Progress__c.getName();
    }

    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.reduivy__Individual_Academic_Progress__c);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }

    /**
     * @description Check if the study fee matrix item is applicable for the transaction fee line generation
     * @param studyFeeMatrixItem Study fee matrix item for which to generate the transaction line item
     * @param ien Individual enrollment to be applied to the transaction line item
     * @param ipwTermNo Term number of the processing individual pathway
     * @return Boolean
     */
    global static Boolean isMatrixItemApplicable(reduivy__Study_Fee_Matrix_Item__c studyFeeMatrixItem, reduivy__Individual_Enrollment__c ien, Decimal ipwTermNo){

        if(
            String.isBlank(studyFeeMatrixItem.reduivy__Applicable_for_Attempt_Number__c) || 
            (
                String.isNotBlank(studyFeeMatrixItem.reduivy__Applicable_for_Attempt_Number__c) &&
                ien?.reduivy__Attempt_Number__c != null &&
                studyFeeMatrixItem.reduivy__Applicable_for_Attempt_Number__c.split(';').contains(String.valueOf(ien?.reduivy__Attempt_Number__c))
            )
        ){

            if(
                String.isBlank(studyFeeMatrixItem.reduivy__Applicable_For_Study_Unit__c) ||
                (
                    String.isNotBlank(studyFeeMatrixItem.reduivy__Applicable_For_Study_Unit__c) &&
                    String.isNotBlank(ien?.reduivy__Target_Unit_Id__c) &&
                    studyFeeMatrixItem.reduivy__Applicable_For_Study_Unit__c == ien?.reduivy__Target_Unit_Id__c
                )
            ){
            
                if(
                    String.isBlank(studyFeeMatrixItem.reduivy__Applicable_For_Term__c) ||
                    (
                        String.isNotBlank(studyFeeMatrixItem.reduivy__Applicable_For_Term__c) &&
                        ipwTermNo != null &&
                        studyFeeMatrixItem.reduivy__Applicable_For_Term__c.split(';').contains(String.valueOf(ipwTermNo))
                    )
                ){
                
                    return true;
                }
            }
        }
    
        return false;
    }

    /**
     * @description Create primary transaction order for the IPR based on the study term and provided individual progress record
     * @param parentIpr Qualified individual academic progress to be processed
     * @param studyTerm Study term to be used for transaction order generation
     * @return reduivy__Transaction_Order__c
     */
    global static reduivy__Transaction_Order__c createPrimaryTrnOrder(reduivy__Individual_Academic_Progress__c parentIpr, reduivy__Study_Term__c studyTerm) {

        reduivy__Transaction_Order__c primaryTrnOrder = new reduivy__Transaction_Order__c();
        primaryTrnOrder.reduivy__Contact__c = parentIpr.reduivy__Contact__c;
        primaryTrnOrder.reduivy__Individual_Academic_Progress__c = parentIpr.Id;
        primaryTrnOrder.reduivy__Primary__c = true;
        primaryTrnOrder.reduivy__Status__c = TRO_Helper.getDraftStatuses().get(0);
        primaryTrnOrder.reduivy__Due_Date__c = studyTerm.reduivy__Fee_Due_Date__c;
        primaryTrnOrder.reduivy__Transaction_Date__c = System.today();
        primaryTrnOrder.reduivy__Apply_Payment__c = studyTerm.reduivy__Apply_Payment__c;
        primaryTrnOrder.reduivy__Apply_Non_Repayable_FA__c = studyTerm.reduivy__Apply_Non_Repayable_FA__c;
        primaryTrnOrder.reduivy__Apply_Repayable_FA__c = studyTerm.reduivy__Apply_Repayable_FA__c;
        primaryTrnOrder.reduivy__Description__c = String.format(Label.Primary_Transaction_Order_Description, new List<String>{Label.Academic_Term, studyTerm.Name});

        return primaryTrnOrder;
    }

    /**
     * @description Create transaction line item for the primary transaction order
     * @param trnOrderId Transaction order Id
     * @param unitPrice Unit price of the transaction line item
     * @param description Description of the transaction line item
     * @param ienId Related individual enrollment of the transaction line item (optional)
     * @param studyFeeMatrixItemId Study fee matrix item of the transaction line item
     * @param itemType Item type of the transaction line item
     * @param itemName Item name of the transaction line item
     * @return reduivy__Transaction_Line_Item__c
     */
    global static reduivy__Transaction_Line_Item__c createTrnLineItem(Id trnOrderId, Decimal unitPrice, String description, Id ienId, Id studyFeeMatrixItemId, String itemType, String itemName) {

        reduivy__Transaction_Line_Item__c newTrnLineItem = new reduivy__Transaction_Line_Item__c();
        newTrnLineItem.reduivy__Transaction_Order__c = trnOrderId;
        newTrnLineItem.reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_DEBIT;
        newTrnLineItem.reduivy__Quantity__c = 1;
        newTrnLineItem.reduivy__Unit_Price__c = unitPrice;
        newTrnLineItem.reduivy__Description__c = description;
        newTrnLineItem.reduivy__Individual_Enrollment__c = ienId;
        newTrnLineItem.reduivy__Item_Name__c = itemName;
        newTrnLineItem.reduivy__Item_Type__c = itemType;
        newTrnLineItem.reduivy__Study_Fee_Matrix_Item__c = studyFeeMatrixItemId;
        newTrnLineItem.reduivy__Transaction_Type__c= TRL_Helper.TRANSACTION_TYPE_ORDERLINE;

        return newTrnLineItem;
    }

    /**
     * @description Generate transaction line item for fee type of "Per Credit"
     * @param studyFeeMatrixItem Study fee matrix item for which to generate the transaction line item
     * @param primaryTrnOrder Primary transaction order
     * @param ienList List of related individual enrollment to be applied to the transaction line item
     * @param idvPathway Individual Pathway related to the transaction line item
     * @return List<reduivy__Transaction_Line_Item__c>
     */
    global static List<reduivy__Transaction_Line_Item__c> createPerCreditLineItems(reduivy__Study_Fee_Matrix_Item__c studyFeeMatrixItem, reduivy__Transaction_Order__c primaryTrnOrder, List<reduivy__Individual_Enrollment__c> ienList, reduivy__Individual_Pathway__c idvPathway) {
        
        List<reduivy__Transaction_Line_Item__c> newTrnLineItemList = new List<reduivy__Transaction_Line_Item__c>();
        for(reduivy__Individual_Enrollment__c ien : ienList){

            if(IPR_Helper.isMatrixItemApplicable(studyFeeMatrixItem, ien, idvPathway.reduivy__Term_Number__c)){
        
                Decimal unitPrice = ien.reduivy__Credits_Offered__c * studyFeeMatrixItem.reduivy__Amount__c;
                String itemName = studyFeeMatrixItem.reduivy__Study_Fee__r.Name + ' - ' + ien.reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Unit_Code__c;
                newTrnLineItemList.add(createTrnLineItem(primaryTrnOrder.Id, 
                    unitPrice, 
                    studyFeeMatrixItem.reduivy__Study_Fee__r.reduivy__Description_for_Transactions__c, 
                    ien.Id, 
                    studyFeeMatrixItem.Id, 
                    studyFeeMatrixItem.reduivy__Study_Fee__r.reduivy__Item_Type__c, 
                    itemName)
                );
            }
        }

        return newTrnLineItemList;
    }

    /**
     * @description Generate transaction line item for fee type of "Per Study Unit"
     * @param studyFeeMatrixItem Study fee matrix item for which to generate the transaction line item
     * @param primaryTrnOrder Primary transaction order
     * @param ienList List of related individual enrollment to be applied to the transaction line item
     * @param idvPathway Individual Pathway related to the transaction line item
     * @return List<reduivy__Transaction_Line_Item__c>
     */
    global static List<reduivy__Transaction_Line_Item__c> createPerStudyUnitLineItems(reduivy__Study_Fee_Matrix_Item__c studyFeeMatrixItem, reduivy__Transaction_Order__c primaryTrnOrder, List<reduivy__Individual_Enrollment__c> ienList, reduivy__Individual_Pathway__c idvPathway) {
        
        List<reduivy__Transaction_Line_Item__c> newTrnLineItemList = new List<reduivy__Transaction_Line_Item__c>();
        for(reduivy__Individual_Enrollment__c ien : ienList){

            if(IPR_Helper.isMatrixItemApplicable(studyFeeMatrixItem, ien, idvPathway.reduivy__Term_Number__c)){
        
                Decimal unitPrice = studyFeeMatrixItem.reduivy__Amount__c;
                String itemName = studyFeeMatrixItem.reduivy__Study_Fee__r.Name + ' - ' + ien.reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Unit_Code__c;
                newTrnLineItemList.add(createTrnLineItem(primaryTrnOrder.Id, 
                    unitPrice, 
                    studyFeeMatrixItem.reduivy__Study_Fee__r.reduivy__Description_for_Transactions__c, 
                    ien.Id, 
                    studyFeeMatrixItem.Id, 
                    studyFeeMatrixItem.reduivy__Study_Fee__r.reduivy__Item_Type__c, 
                    itemName)
                );
            }
        }

        return newTrnLineItemList;
    }

    /**
     * @description Generate transaction line item for fee type of "Per Term"
     * @param studyFeeMatrixItem Study fee matrix item for which to generate the transaction line item
     * @param primaryTrnOrder Primary transaction order
     * @param termIdStudyFeesMap Map of term id + contact id and related study fees. To be used to check if study fee is charged prviously.
     * @param idvPathway Individual Pathway related to the transaction line item
     * @return List<reduivy__Transaction_Line_Item__c>
     */
    global static List<reduivy__Transaction_Line_Item__c> createPerTermLineItems(reduivy__Study_Fee_Matrix_Item__c studyFeeMatrixItem, reduivy__Transaction_Order__c primaryTrnOrder, Map<String, Set<Id>> termIdStudyFeesMap, reduivy__Individual_Pathway__c idvPathway) {
        
        List<reduivy__Transaction_Line_Item__c> newTrnLineItemList = new List<reduivy__Transaction_Line_Item__c>();

        String termkey = primaryTrnOrder.reduivy__Contact__c + '|' + idvPathway.reduivy__Academic_Term__c;
        if(IPR_Helper.isMatrixItemApplicable(studyFeeMatrixItem, null, idvPathway.reduivy__Term_Number__c) && (!termIdStudyFeesMap.containsKey(termkey) || 
            (termIdStudyFeesMap.containsKey(termkey) && !termIdStudyFeesMap.get(termkey).contains(studyFeeMatrixItem.reduivy__Study_Fee__c)))){

            Decimal unitPrice = studyFeeMatrixItem.reduivy__Amount__c;
            String itemName = studyFeeMatrixItem.reduivy__Study_Fee__r.Name;
            newTrnLineItemList.add(createTrnLineItem(primaryTrnOrder.Id, 
                unitPrice, 
                studyFeeMatrixItem.reduivy__Study_Fee__r.reduivy__Description_for_Transactions__c, 
                null, 
                studyFeeMatrixItem.Id, 
                studyFeeMatrixItem.reduivy__Study_Fee__r.reduivy__Item_Type__c, 
                itemName)
            );

            //Make sure the map has the latest fee
            if(!termIdStudyFeesMap.containsKey(termkey)){
                termIdStudyFeesMap.put(termkey, new Set<Id>{studyFeeMatrixItem.reduivy__Study_Fee__c});
            }else{
                termIdStudyFeesMap.get(termkey).add(studyFeeMatrixItem.reduivy__Study_Fee__c);
            }
        }

        return newTrnLineItemList;
    }

    /**
     * @description Generate transaction line item for fee type of "Per Academic Year"
     * @param studyFeeMatrixItem Study fee matrix item for which to generate the transaction line item
     * @param primaryTrnOrder Primary transaction order
     * @param termIdStudyFeesMap Map of term id + contact id and related study fees. To be used to check if study fee is charged prviously.
     * @param idvPathway Individual Pathway related to the transaction line item
     * @return List<reduivy__Transaction_Line_Item__c>
     */
    global static List<reduivy__Transaction_Line_Item__c> createPerAnnualLineItems(reduivy__Study_Fee_Matrix_Item__c studyFeeMatrixItem, reduivy__Transaction_Order__c primaryTrnOrder, Map<String, Set<Id>> termIdStudyFeesMap, reduivy__Individual_Pathway__c idvPathway) {
        
        List<reduivy__Transaction_Line_Item__c> newTrnLineItemList = new List<reduivy__Transaction_Line_Item__c>();

        String academicYearkey = primaryTrnOrder.reduivy__Contact__c + '|' + idvPathway.reduivy__Academic_Term__r.reduivy__Academic_Year__c;
        if(IPR_Helper.isMatrixItemApplicable(studyFeeMatrixItem, null, idvPathway.reduivy__Term_Number__c) && (!termIdStudyFeesMap.containsKey(academicYearkey) || 
            (termIdStudyFeesMap.containsKey(academicYearkey) && !termIdStudyFeesMap.get(academicYearkey).contains(studyFeeMatrixItem.reduivy__Study_Fee__c)))){

            Decimal unitPrice = studyFeeMatrixItem.reduivy__Amount__c;
            String itemName = studyFeeMatrixItem.reduivy__Study_Fee__r.Name;
            newTrnLineItemList.add(createTrnLineItem(primaryTrnOrder.Id, 
                unitPrice, 
                studyFeeMatrixItem.reduivy__Study_Fee__r.reduivy__Description_for_Transactions__c, 
                null, 
                studyFeeMatrixItem.Id, 
                studyFeeMatrixItem.reduivy__Study_Fee__r.reduivy__Item_Type__c, 
                itemName)
            );
                                
            //Make sure the map has the latest fee
            if(!termIdStudyFeesMap.containsKey(academicYearkey)){
                termIdStudyFeesMap.put(academicYearkey, new Set<Id>{studyFeeMatrixItem.reduivy__Study_Fee__c});
            }else{
                termIdStudyFeesMap.get(academicYearkey).add(studyFeeMatrixItem.reduivy__Study_Fee__c);
            }
        }

        return newTrnLineItemList;
    }

    /**
     * @description get individual enrollments with statuses of given ipr ids
     * @param  iprEnrollmentStatusesMap semi-colon separated enrollment statuses for different ipr id
     * @return                          map of ien record list by iprid
     */
    global static Map<Id, List<reduivy__Individual_Enrollment__c>> getIndividualEnrollments(Map<Id, String> iprEnrollmentStatusesMap){

        Set<Id> iprIds = new Set<Id>();
        Map<Id, Set<String>> iprEnrollmentStatusesMapSplitted = new Map<Id, Set<String>>();
        Set<String> enrollmentStatusesForQuery = new Set<String>();
        
        Map<Id, List<reduivy__Individual_Enrollment__c>> ienMap = new Map<Id, List<reduivy__Individual_Enrollment__c>>();

        for(String iprId: iprEnrollmentStatusesMap.keySet()) {

            String statusesStr = iprEnrollmentStatusesMap.get(iprId);
            List<String> statuses = String.isNotBlank(statusesStr) ? statusesStr.split(REDU_List_UTIL.DELIMITER) : new List<String>();

            iprIds.add(iprId);
            enrollmentStatusesForQuery.addAll(statuses);
            iprEnrollmentStatusesMapSplitted.put(iprId, new Set<String>(statuses));

            ienMap.put(iprId, new List<reduivy__Individual_Enrollment__c>());
        }

        if(iprIds != null && !iprIds.isEmpty()) {

            Set<String> ienFields = new Set<String>{
                'Id',
                'Name',
                'reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Unit_Code__c',
                'reduivy__Enrollment_Status__c',
                'reduivy__Individual_Academic_Progress__c'
            };

            Set<String> ipsFields = new Set<String> {
                'Id',
                'Name',
                'reduivy__Study_Plan_Structure__r.reduivy__Study_Plan__r.Name',
                'reduivy__Study_Plan_Structure__r.reduivy__Study_Plan__r.' + SPL_Helper.getTranslationFieldNameForName()
            };

            Map<String, Object> ienBindMap = new Map<String, Object>{
                'iprIds' => iprIds
            };

            String ienSoql =  'SELECT ' + String.join(ienFields, ', ') + ', '
                + ' ( SELECT ' + String.join(ipsFields, ', ')
                + ' FROM reduivy__Individual_Plan_Units__r ) ' +  
                + ' FROM reduivy__Individual_Enrollment__c ' +
                + ' WHERE reduivy__Individual_Academic_Progress__c IN :iprIds ';
            
            if (!enrollmentStatusesForQuery.isEmpty()) {
                ienBindMap.put('statuses', enrollmentStatusesForQuery);
                ienSoql += ' AND reduivy__Enrollment_Status__c IN :statuses ';
            }

            for(reduivy__Individual_Enrollment__c ien : (List<reduivy__Individual_Enrollment__c>) Database.queryWithBinds(ienSoql, ienBindMap, AccessLevel.USER_MODE)) {
                
                Set<String> qualifiedEnrollmentStatuses = iprEnrollmentStatusesMapSplitted.get(ien.reduivy__Individual_Academic_Progress__c);
                
                //the ien will be included if the enrollment statuses is not defined or matches the defined one
                if(qualifiedEnrollmentStatuses.isEmpty() || qualifiedEnrollmentStatuses.contains(ien.reduivy__Enrollment_Status__c)) {
                    
                    if(!ienMap.containsKey(ien.reduivy__Individual_Academic_Progress__c)) {
                        ienMap.put(ien.reduivy__Individual_Academic_Progress__c, new List<reduivy__Individual_Enrollment__c>());
                    }

                    ienMap.get(ien.reduivy__Individual_Academic_Progress__c).add(ien);
                }
            }
        }

        return ienMap;

    }

    /**
     * @description unenroll ien in map values to the given enrollment status
     * @param  ienIdListByIprIdMap map of ienlist by ipr id 
     * @param  enrollmentStatusMap map of enrollment status by ipr id
     * @return                     ienIdListByIprIdMap
     */
    global static Map<String, List<String>> unenrollIpr(Map<String, List<String>> ienIdListByIprIdMap, Map<String, String> enrollmentStatusMap) {

        List<reduivy__Individual_Enrollment__c> ienListToUpdate = new List<reduivy__Individual_Enrollment__c>();

        if(ienIdListByIprIdMap != null && !ienIdListByIprIdMap.isEmpty()) {
            for(String iprId : ienIdListByIprIdMap.keySet()) {
                List<String> ienIdList = ienIdListByIprIdMap.get(iprId);

                for(String ienId : ienIdList) {
                    reduivy__Individual_Enrollment__c ienToUpdate = new reduivy__Individual_Enrollment__c(
                        Id = ienId,
                        reduivy__Enrollment_Status__c = enrollmentStatusMap.get(iprId)
                    );
                    ienListToUpdate.add(ienToUpdate);
                }
            }
            
            if(!ienListToUpdate.isEmpty()) {
                REDU_Database_UTIL.doUpdate(ienListToUpdate);
            }
        }

        return ienIdListByIprIdMap;
    }

}