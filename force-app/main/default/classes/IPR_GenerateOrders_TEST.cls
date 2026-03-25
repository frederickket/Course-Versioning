/**
 * @author      WDCi (VTan)
 * @date        Aug 2024
 * @group       Test
 * @description Test class for IPR_GenerateOrders_EXE
 * @changehistory
 * ISS-002026 12-08-2023 VTan - new class
 * ISS-002510 30-07-2025 Lean - Changed the sequence of updating order due to the new validation rules to prevent confirmed order from being modified
 * ISS-002580 07-08-2025 XiRouh - Added testGenerateTrnOrderWithDiffIenStatuses()
 */
@IsTest
public inherited sharing class IPR_GenerateOrders_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static String TRO_CONFIRMED_STATUS = TRO_Helper.getConfirmedStatuses().get(0);
    static String TRO_DRAFT_STATUS = TRO_Helper.getDraftStatuses().get(0);

    /**
     * @description Default method to setup required data for automated test
     */
	@TestSetup
    static void makeData(){
        
        testFactory.setupDefaultSettings();

        Test.startTest();

        User ADMIN_USER = testFactory.getReduAdminUser();
		System.runAs(ADMIN_USER) {

        	testFactory.initMasterData(SPT_Helper.getApiName());
			testFactory.initOfferingData(SIT_Helper.getApiName());
			testFactory.initStudentData(IPE_Helper.getApiName(), true);
		}
        Test.stopTest();
    }

    /**
     * @description Test generate Order with per credit, study unit, term and academic year fees. Order Generation Action = New Order Only
     */
    @IsTest
    static void testGenerateTrnOrder() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<Id, reduivy__Individual_Academic_Progress__c> iprMap = new Map<Id, reduivy__Individual_Academic_Progress__c>();
        for(reduivy__Individual_Pathway__c idvPathway : [SELECT Id, reduivy__Individual_Academic_Progress__c 
                                                        FROM reduivy__Individual_Pathway__c 
                                                        WHERE reduivy__Term_Number__c = 1]){

            iprMap.put(idvPathway.reduivy__Individual_Academic_Progress__c, null);
        }

        for(reduivy__Individual_Academic_Progress__c ipr : [SELECT Id, reduivy__Student_Fee_Type__c, reduivy__Generate_Transaction_Orders__c, reduivy__Order_Generation_Action__c,
                                                    (SELECT Id, reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Unit_Code__c FROM reduivy__Individual_Enrollments__r)
                                                    FROM reduivy__Individual_Academic_Progress__c 
                                                    WHERE Id IN: iprMap.keySet()]){

            iprMap.put(ipr.Id, ipr);
        }
        System.Assert.areEqual(false, iprMap.isEmpty(), 'Individual Academic Progress should not be empty.');

        Map<Id, reduivy__Transaction_Order__c> trnOrderMap = new Map<Id, reduivy__Transaction_Order__c>(
                                                        [SELECT Id, reduivy__Primary__c, reduivy__Individual_Academic_Progress__c 
                                                        FROM reduivy__Transaction_Order__c 
                                                        WHERE reduivy__Individual_Academic_Progress__c = :iprMap.keySet()]);
        System.Assert.areEqual(true, trnOrderMap.isEmpty(), 'Transaction Order should not be generated yet.');
        
        for(reduivy__Individual_Academic_Progress__c ipr : iprMap.values()){
            ipr.reduivy__Student_Fee_Type__c = IPR_Helper.STUDENT_FEE_TYPE_DOMESTIC;
            ipr.reduivy__Generate_Transaction_Orders__c = true;
            ipr.reduivy__Order_Generation_Action__c = IPR_Helper.ORDER_GENERATION_ACTION_NEW_ONLY;
        }

        System.runAs(ADMIN_USER) {
            
            Test.startTest();
            update iprMap.values();
            Test.stopTest();
        }

        //Check Transaction Order
        Map<Id, Id> iprIdTranOrderIdMap = new Map<Id, Id>();
        trnOrderMap = new Map<Id, reduivy__Transaction_Order__c>([SELECT Id, 
            reduivy__Primary__c, 
            reduivy__Individual_Academic_Progress__c,
            reduivy__Status__c
            FROM reduivy__Transaction_Order__c 
            WHERE reduivy__Individual_Academic_Progress__c = :iprMap.keySet()
        ]);

        for(reduivy__Transaction_Order__c trnOrder : trnOrderMap.values()){
            System.assertEquals(TRO_CONFIRMED_STATUS, trnOrder.reduivy__Status__c, 'Transaction order should be marked as confirmed.');
            System.Assert.areEqual(true, trnOrder.reduivy__Primary__c, 'Transaction order should be marked as primary.');
            iprIdTranOrderIdMap.put(trnOrder.reduivy__Individual_Academic_Progress__c, trnOrder.Id);
        }
        
        System.Assert.areEqual(iprMap.size(), iprIdTranOrderIdMap.size(), 'Number of generated Transaction Order should matches the number of Individual Academic Progress.');

        //Check Transaction Line Item
        Map<Id, List<reduivy__Transaction_Line_Item__c>> trnOrderIdLineItemMap = new Map<Id, List<reduivy__Transaction_Line_Item__c>>();
        for(reduivy__Transaction_Line_Item__c trl : [SELECT Id, reduivy__Transaction_Order__c, reduivy__Individual_Enrollment__c, reduivy__Transaction_Order__r.reduivy__Individual_Academic_Progress__c, reduivy__Study_Fee_Matrix_Item__r.reduivy__Type__c
                                                FROM reduivy__Transaction_Line_Item__c 
                                                WHERE reduivy__Transaction_Order__c IN :trnOrderMap.keySet()]){
            if(trnOrderIdLineItemMap.containsKey(trl.reduivy__Transaction_Order__c)){
                trnOrderIdLineItemMap.get(trl.reduivy__Transaction_Order__c).add(trl);
            }else{
                trnOrderIdLineItemMap.put(trl.reduivy__Transaction_Order__c, new List<reduivy__Transaction_Line_Item__c>{trl});
            }
        }

        for(Id tranOrderId : trnOrderIdLineItemMap.keySet()){

            Integer perCreditFeeCount = 0;
            Integer perUnitStudyFeeCount = 0;
            Integer perTermFeeCount = 0;
            Integer perAnnualFeeCount = 0;
            for(reduivy__Transaction_Line_Item__c trl : trnOrderIdLineItemMap.get(tranOrderId)){

                if(String.isNotBlank(trl.reduivy__Individual_Enrollment__c ) && trl.reduivy__Study_Fee_Matrix_Item__r.reduivy__Type__c == SMI_Helper.TYPE_PER_CREDIT){
                    perCreditFeeCount++;
                }else if(String.isNotBlank(trl.reduivy__Individual_Enrollment__c ) && trl.reduivy__Study_Fee_Matrix_Item__r.reduivy__Type__c == SMI_Helper.TYPE_PER_STUDY_UNIT){
                    perUnitStudyFeeCount++;
                }else if(String.isBlank(trl.reduivy__Individual_Enrollment__c ) && trl.reduivy__Study_Fee_Matrix_Item__r.reduivy__Type__c == SMI_Helper.TYPE_PER_ACADEMIC_TERM){
                    perTermFeeCount++;
                }else if(String.isBlank(trl.reduivy__Individual_Enrollment__c ) && trl.reduivy__Study_Fee_Matrix_Item__r.reduivy__Type__c == SMI_Helper.TYPE_PER_ACADEMIC_YEAR){
                    perAnnualFeeCount++;
                }
            }

            Map<String, reduivy__Individual_Enrollment__c> unitCodeIenMap = new Map<String, reduivy__Individual_Enrollment__c>();
            for(reduivy__Individual_Enrollment__c ien : iprMap.get(trnOrderMap.get(tranOrderId).reduivy__Individual_Academic_Progress__c).reduivy__Individual_Enrollments__r){
                unitCodeIenMap.put(ien.reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Unit_Code__c, ien);
            }

            System.Assert.areEqual(iprMap.get(trnOrderMap.get(tranOrderId).reduivy__Individual_Academic_Progress__c).reduivy__Individual_Enrollments__r.size(), perCreditFeeCount, 'Number of per Credit transaction line item should match with the number of invidual enrollment.');
            System.Assert.areEqual(false, unitCodeIenMap.containsKey('ICT101') && perUnitStudyFeeCount != 1, 'Number of per Study Unit transaction line item should 1 for student enrolled to ICT101.');
            System.Assert.areEqual(1, perTermFeeCount, 'Number of per Study Term transaction line item should 1.');
            System.Assert.areEqual(1, perAnnualFeeCount, 'Number of per Academic Year transaction line item should 1.');
        }
    }

    /**
     * @description Test generate Order with per credit, study unit, term and academic year fees. Order Generation Action = New Order Only, with different student fee type
     */
    @IsTest
    static void testGenerateTrnOrderWithDiffFeeType() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<Id, reduivy__Individual_Academic_Progress__c> iprMap = new Map<Id, reduivy__Individual_Academic_Progress__c>();
        for(reduivy__Individual_Pathway__c idvPathway : [SELECT Id, reduivy__Individual_Academic_Progress__c 
                                                        FROM reduivy__Individual_Pathway__c 
                                                        WHERE reduivy__Term_Number__c = 1]){

            iprMap.put(idvPathway.reduivy__Individual_Academic_Progress__c, null);
        }

        for(reduivy__Individual_Academic_Progress__c ipr : [SELECT Id, reduivy__Student_Fee_Type__c, reduivy__Generate_Transaction_Orders__c, reduivy__Order_Generation_Action__c,
                                                    (SELECT Id, reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Unit_Code__c FROM reduivy__Individual_Enrollments__r)
                                                    FROM reduivy__Individual_Academic_Progress__c 
                                                    WHERE Id IN: iprMap.keySet()]){

            iprMap.put(ipr.Id, ipr);
        }
        System.Assert.areEqual(false, iprMap.isEmpty(), 'Individual Academic Progress should not be empty.');

        Map<Id, reduivy__Transaction_Order__c> trnOrderMap = new Map<Id, reduivy__Transaction_Order__c>(
                                                        [SELECT Id, reduivy__Primary__c, reduivy__Individual_Academic_Progress__c 
                                                        FROM reduivy__Transaction_Order__c 
                                                        WHERE reduivy__Individual_Academic_Progress__c = :iprMap.keySet()]);
        System.Assert.areEqual(true, trnOrderMap.isEmpty(), 'Transaction Order should not be generated yet.');
        
        Integer counter = 0;
        for(reduivy__Individual_Academic_Progress__c ipr : iprMap.values()){
            if(Math.mod(counter, 2) == 0) {
                ipr.reduivy__Student_Fee_Type__c = IPR_Helper.STUDENT_FEE_TYPE_DOMESTIC;
            } else {
                ipr.reduivy__Student_Fee_Type__c = IPR_Helper.STUDENT_FEE_TYPE_INTERNATIONAL;
            }
            ipr.reduivy__Generate_Transaction_Orders__c = true;
            ipr.reduivy__Order_Generation_Action__c = IPR_Helper.ORDER_GENERATION_ACTION_NEW_ONLY;
        }

        System.runAs(ADMIN_USER) {
            
            Test.startTest();
            update iprMap.values();
            Test.stopTest();
        }

        //Check Transaction Order
        Map<Id, Id> iprIdTranOrderIdMap = new Map<Id, Id>();
        trnOrderMap = new Map<Id, reduivy__Transaction_Order__c>([SELECT Id, 
            reduivy__Primary__c, 
            reduivy__Individual_Academic_Progress__c,
            reduivy__Status__c
            FROM reduivy__Transaction_Order__c 
            WHERE reduivy__Individual_Academic_Progress__c = :iprMap.keySet()
        ]);

        for(reduivy__Transaction_Order__c trnOrder : trnOrderMap.values()){
            System.assertEquals(TRO_CONFIRMED_STATUS, trnOrder.reduivy__Status__c, 'Transaction order should be marked as confirmed.');
            System.Assert.areEqual(true, trnOrder.reduivy__Primary__c, 'Transaction order should be marked as primary.');
            iprIdTranOrderIdMap.put(trnOrder.reduivy__Individual_Academic_Progress__c, trnOrder.Id);
        }
        
        System.Assert.areEqual(iprMap.size(), iprIdTranOrderIdMap.size(), 'Number of generated Transaction Order should matches the number of Individual Academic Progress.');

        //Check Transaction Line Item
        Map<Id, List<reduivy__Transaction_Line_Item__c>> trnOrderIdLineItemMap = new Map<Id, List<reduivy__Transaction_Line_Item__c>>();
        for(reduivy__Transaction_Line_Item__c trl : [SELECT Id, reduivy__Transaction_Order__c, reduivy__Individual_Enrollment__c, reduivy__Transaction_Order__r.reduivy__Individual_Academic_Progress__c, reduivy__Study_Fee_Matrix_Item__r.reduivy__Type__c
                                                FROM reduivy__Transaction_Line_Item__c 
                                                WHERE reduivy__Transaction_Order__c IN :trnOrderMap.keySet()]){
            if(trnOrderIdLineItemMap.containsKey(trl.reduivy__Transaction_Order__c)){
                trnOrderIdLineItemMap.get(trl.reduivy__Transaction_Order__c).add(trl);
            }else{
                trnOrderIdLineItemMap.put(trl.reduivy__Transaction_Order__c, new List<reduivy__Transaction_Line_Item__c>{trl});
            }
        }
        System.Assert.isFalse(trnOrderIdLineItemMap.isEmpty(), 'TRL should not be empty!');

        for(Id tranOrderId : trnOrderIdLineItemMap.keySet()){

            Integer perCreditFeeCount = 0;
            Integer perUnitStudyFeeCount = 0;
            Integer perTermFeeCount = 0;
            Integer perAnnualFeeCount = 0;
            for(reduivy__Transaction_Line_Item__c trl : trnOrderIdLineItemMap.get(tranOrderId)){

                if(String.isNotBlank(trl.reduivy__Individual_Enrollment__c ) && trl.reduivy__Study_Fee_Matrix_Item__r.reduivy__Type__c == SMI_Helper.TYPE_PER_CREDIT){
                    perCreditFeeCount++;
                }else if(String.isNotBlank(trl.reduivy__Individual_Enrollment__c ) && trl.reduivy__Study_Fee_Matrix_Item__r.reduivy__Type__c == SMI_Helper.TYPE_PER_STUDY_UNIT){
                    perUnitStudyFeeCount++;
                }else if(String.isBlank(trl.reduivy__Individual_Enrollment__c ) && trl.reduivy__Study_Fee_Matrix_Item__r.reduivy__Type__c == SMI_Helper.TYPE_PER_ACADEMIC_TERM){
                    perTermFeeCount++;
                }else if(String.isBlank(trl.reduivy__Individual_Enrollment__c ) && trl.reduivy__Study_Fee_Matrix_Item__r.reduivy__Type__c == SMI_Helper.TYPE_PER_ACADEMIC_YEAR){
                    perAnnualFeeCount++;
                }
            }

            Map<String, reduivy__Individual_Enrollment__c> unitCodeIenMap = new Map<String, reduivy__Individual_Enrollment__c>();
            for(reduivy__Individual_Enrollment__c ien : iprMap.get(trnOrderMap.get(tranOrderId).reduivy__Individual_Academic_Progress__c).reduivy__Individual_Enrollments__r){
                unitCodeIenMap.put(ien.reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Unit_Code__c, ien);
            }

            System.Assert.areEqual(iprMap.get(trnOrderMap.get(tranOrderId).reduivy__Individual_Academic_Progress__c).reduivy__Individual_Enrollments__r.size(), perCreditFeeCount, 'Number of per Credit transaction line item should match with the number of invidual enrollment.');
            System.Assert.areEqual(false, unitCodeIenMap.containsKey('ICT101') && perUnitStudyFeeCount != 1, 'Number of per Study Unit transaction line item should 1 for student enrolled to ICT101.');
            System.Assert.areEqual(1, perTermFeeCount, 'Number of per Study Term transaction line item should 1.');
            System.Assert.areEqual(1, perAnnualFeeCount, 'Number of per Academic Year transaction line item should 1.');
        }
    }

    /**
     * @description Test regeneration with Order Generation Action	= New Order Only (expect error)
     */
    @IsTest
    static void testRegenerateTransactionOrderError() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<Id, reduivy__Individual_Academic_Progress__c> iprMap = new Map<Id, reduivy__Individual_Academic_Progress__c>();
        for(reduivy__Individual_Pathway__c idvPathway : [SELECT Id, reduivy__Individual_Academic_Progress__c 
                                                        FROM reduivy__Individual_Pathway__c 
                                                        WHERE reduivy__Term_Number__c = 1]){

            iprMap.put(idvPathway.reduivy__Individual_Academic_Progress__c, null);
        }

        for(reduivy__Individual_Academic_Progress__c ipr : [SELECT Id, reduivy__Student_Fee_Type__c, reduivy__Generate_Transaction_Orders__c, reduivy__Order_Generation_Action__c,
                                                    (SELECT Id, reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Unit_Code__c FROM reduivy__Individual_Enrollments__r)
                                                    FROM reduivy__Individual_Academic_Progress__c 
                                                    WHERE Id IN: iprMap.keySet()]){

            iprMap.put(ipr.Id, ipr);
        }
        System.Assert.areEqual(false, iprMap.isEmpty(), 'Individual Academic Progress should not be empty.');
        
        //Generate Transaction Order first
        for(reduivy__Individual_Academic_Progress__c ipr : iprMap.values()){
            ipr.reduivy__Student_Fee_Type__c = IPR_Helper.STUDENT_FEE_TYPE_DOMESTIC;
            ipr.reduivy__Generate_Transaction_Orders__c = true;
            ipr.reduivy__Order_Generation_Action__c = IPR_Helper.ORDER_GENERATION_ACTION_NEW_ONLY;
        }
        update iprMap.values();

        //Preparation for Regeneration
        for(reduivy__Individual_Academic_Progress__c ipr : iprMap.values()){
            ipr.reduivy__Generate_Transaction_Orders__c = false;
        }
        update iprMap.values();

        Map<Id, reduivy__Transaction_Order__c> trnOrderMap = new Map<Id, reduivy__Transaction_Order__c>(
            [SELECT Id, reduivy__Primary__c, reduivy__Individual_Academic_Progress__c 
            FROM reduivy__Transaction_Order__c 
            WHERE reduivy__Individual_Academic_Progress__c = :iprMap.keySet()]);
        System.Assert.areEqual(false, trnOrderMap.isEmpty(), 'Transaction Order should be generated.');

        for(reduivy__Individual_Academic_Progress__c ipr : iprMap.values()){
            ipr.reduivy__Generate_Transaction_Orders__c = true;
        }

        System.runAs(ADMIN_USER) {
            Test.startTest();
            try{
                update iprMap.values();
                System.Assert.fail('Transaction order regeneration should be failed');
            }catch(Exception exp){
                System.Assert.areEqual(true, exp.getMessage().contains('a Primary Transaction Order already exists'), 'The expected error should match');
            }
            Test.stopTest();
        }
    }

    /**
     * @description Test regeneration with Order Generation Action = Regeneration
     */
    @IsTest
    static void testRegenerateTransactionOrder() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<Id, reduivy__Individual_Academic_Progress__c> iprMap = new Map<Id, reduivy__Individual_Academic_Progress__c>();
        for(reduivy__Individual_Pathway__c idvPathway : [SELECT Id, reduivy__Individual_Academic_Progress__c 
                                                        FROM reduivy__Individual_Pathway__c 
                                                        WHERE reduivy__Term_Number__c = 1]){

            iprMap.put(idvPathway.reduivy__Individual_Academic_Progress__c, null);
        }

        for(reduivy__Individual_Academic_Progress__c ipr : [SELECT Id, reduivy__Student_Fee_Type__c, reduivy__Generate_Transaction_Orders__c, reduivy__Order_Generation_Action__c,
                                                    (SELECT Id, reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Unit_Code__c FROM reduivy__Individual_Enrollments__r)
                                                    FROM reduivy__Individual_Academic_Progress__c 
                                                    WHERE Id IN: iprMap.keySet()]){

            iprMap.put(ipr.Id, ipr);
        }
        System.Assert.areEqual(false, iprMap.isEmpty(), 'Individual Academic Progress should not be empty.');
        
        //Generate Transaction Order first
        for(reduivy__Individual_Academic_Progress__c ipr : iprMap.values()){
            ipr.reduivy__Student_Fee_Type__c = IPR_Helper.STUDENT_FEE_TYPE_DOMESTIC;
            ipr.reduivy__Generate_Transaction_Orders__c = true;
            ipr.reduivy__Order_Generation_Action__c = IPR_Helper.ORDER_GENERATION_ACTION_NEW_ONLY;
        }
        update iprMap.values();

        //Preparation for Regeneration
        for(reduivy__Individual_Academic_Progress__c ipr : iprMap.values()){
            ipr.reduivy__Generate_Transaction_Orders__c = false;
        }
        update iprMap.values();

        Map<Id, reduivy__Transaction_Order__c> oldTrnOrderMap = new Map<Id, reduivy__Transaction_Order__c>(
            [SELECT Id, reduivy__Primary__c, reduivy__Individual_Academic_Progress__c 
            FROM reduivy__Transaction_Order__c 
            WHERE reduivy__Individual_Academic_Progress__c = :iprMap.keySet()]);
        System.Assert.areEqual(false, oldTrnOrderMap.isEmpty(), 'Transaction Order should be generated.');

        Map<Id, reduivy__Transaction_Line_Item__c> oldTrlMap = new Map<Id, reduivy__Transaction_Line_Item__c>([
                                                            SELECT Id 
                                                            FROM reduivy__Transaction_Line_Item__c WHERE reduivy__Transaction_Order__c IN :oldTrnOrderMap.keySet()]);

        for(reduivy__Individual_Academic_Progress__c ipr : iprMap.values()){
            ipr.reduivy__Generate_Transaction_Orders__c = true;
            ipr.reduivy__Order_Generation_Action__c = IPR_Helper.ORDER_GENERATION_ACTION_REGENERATION;
        }

        System.runAs(ADMIN_USER) {
            Test.startTest();
            update iprMap.values();
            Test.stopTest();
        }

        //Check Transaction Order
        Map<Id, Id> iprIdTranOrderIdMap = new Map<Id, Id>();
        Map<Id, reduivy__Transaction_Order__c> newTrnOrderMap = new Map<Id, reduivy__Transaction_Order__c>([SELECT Id, 
            reduivy__Primary__c, 
            reduivy__Individual_Academic_Progress__c,
            reduivy__Status__c
            FROM reduivy__Transaction_Order__c 
            WHERE reduivy__Individual_Academic_Progress__c = :iprMap.keySet()]
        );

        for(reduivy__Transaction_Order__c trnOrder : newTrnOrderMap.values()){
            System.assertEquals(TRO_CONFIRMED_STATUS, trnOrder.reduivy__Status__c, 'Transaction order should be marked as confirmed.');
            System.Assert.areEqual(true, trnOrder.reduivy__Primary__c, 'Transaction order should be marked as primary.');
            iprIdTranOrderIdMap.put(trnOrder.reduivy__Individual_Academic_Progress__c, trnOrder.Id);
        }

        System.Assert.areEqual(iprMap.size(), iprIdTranOrderIdMap.size(), 'Number of generated Transaction Order should matches the number of Individual Academic Progress.');

        //Check Transaction Line Item
        Map<Id, List<reduivy__Transaction_Line_Item__c>> trnOrderIdLineItemMap = new Map<Id, List<reduivy__Transaction_Line_Item__c>>();
        for(reduivy__Transaction_Line_Item__c trl : [SELECT Id, reduivy__Transaction_Order__c, reduivy__Individual_Enrollment__c, reduivy__Transaction_Order__r.reduivy__Individual_Academic_Progress__c, reduivy__Study_Fee_Matrix_Item__r.reduivy__Type__c
                                                FROM reduivy__Transaction_Line_Item__c 
                                                WHERE reduivy__Transaction_Order__c IN :newTrnOrderMap.keySet()]){
            if(trnOrderIdLineItemMap.containsKey(trl.reduivy__Transaction_Order__c)){
                trnOrderIdLineItemMap.get(trl.reduivy__Transaction_Order__c).add(trl);
            }else{
                trnOrderIdLineItemMap.put(trl.reduivy__Transaction_Order__c, new List<reduivy__Transaction_Line_Item__c>{trl});
            }
            System.Assert.areEqual(false, oldTrlMap.containsKey(trl.Id), 'All transaction line item should be re-created.');
        }

        for(Id tranOrderId : trnOrderIdLineItemMap.keySet()){

            Integer perCreditFeeCount = 0;
            Integer perUnitStudyFeeCount = 0;
            Integer perTermFeeCount = 0;
            Integer perAnnualFeeCount = 0;
            for(reduivy__Transaction_Line_Item__c trl : trnOrderIdLineItemMap.get(tranOrderId)){

                if(String.isNotBlank(trl.reduivy__Individual_Enrollment__c ) && trl.reduivy__Study_Fee_Matrix_Item__r.reduivy__Type__c == SMI_Helper.TYPE_PER_CREDIT){
                    perCreditFeeCount++;
                }else if(String.isNotBlank(trl.reduivy__Individual_Enrollment__c ) && trl.reduivy__Study_Fee_Matrix_Item__r.reduivy__Type__c == SMI_Helper.TYPE_PER_STUDY_UNIT){
                    perUnitStudyFeeCount++;
                }else if(String.isBlank(trl.reduivy__Individual_Enrollment__c ) && trl.reduivy__Study_Fee_Matrix_Item__r.reduivy__Type__c == SMI_Helper.TYPE_PER_ACADEMIC_TERM){
                    perTermFeeCount++;
                }else if(String.isBlank(trl.reduivy__Individual_Enrollment__c ) && trl.reduivy__Study_Fee_Matrix_Item__r.reduivy__Type__c == SMI_Helper.TYPE_PER_ACADEMIC_YEAR){
                    perAnnualFeeCount++;
                }
            }

            Map<String, reduivy__Individual_Enrollment__c> unitCodeIenMap = new Map<String, reduivy__Individual_Enrollment__c>();
            for(reduivy__Individual_Enrollment__c ien : iprMap.get(newTrnOrderMap.get(tranOrderId).reduivy__Individual_Academic_Progress__c).reduivy__Individual_Enrollments__r){
                unitCodeIenMap.put(ien.reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Unit_Code__c, ien);
            }

            System.Assert.areEqual(iprMap.get(newTrnOrderMap.get(tranOrderId).reduivy__Individual_Academic_Progress__c).reduivy__Individual_Enrollments__r.size(), perCreditFeeCount, 'Number of per Credit transaction line item should match with the number of invidual enrollment.');
            System.Assert.areEqual(false, unitCodeIenMap.containsKey('ICT101') && perUnitStudyFeeCount != 1, 'Number of per Study Unit transaction line item should 1 for student enrolled to ICT101.');
            System.Assert.areEqual(1, perTermFeeCount, 'Number of per Study Term transaction line item should 1.');
            System.Assert.areEqual(1, perAnnualFeeCount, 'Number of per Academic Year transaction line item should 1.');
        }
    }

    /**
     * @description Test generate Order with per term fee, and the term fee is charged for current term.
     */
    @IsTest
    static void testGenerateTrnOrderWithTermFee() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<Id, reduivy__Individual_Academic_Progress__c> iprMap = new Map<Id, reduivy__Individual_Academic_Progress__c>(
                                                                [SELECT Id, reduivy__Contact__c, reduivy__Student_Fee_Type__c, reduivy__Generate_Transaction_Orders__c, reduivy__Order_Generation_Action__c,
                                                                (SELECT Id, reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Unit_Code__c FROM reduivy__Individual_Enrollments__r)
                                                                FROM reduivy__Individual_Academic_Progress__c 
                                                                WHERE reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c =:testFactory.CYTKey]);
        System.Assert.areEqual(false, iprMap.isEmpty(), 'Individual Academic Progress should not be empty.');

        Map<Id, reduivy__Transaction_Order__c> trnOrderMap = new Map<Id, reduivy__Transaction_Order__c>(
                                                        [SELECT Id, reduivy__Primary__c, reduivy__Individual_Academic_Progress__c 
                                                        FROM reduivy__Transaction_Order__c 
                                                        WHERE reduivy__Individual_Academic_Progress__c = :iprMap.keySet()]);
        System.Assert.areEqual(true, trnOrderMap.isEmpty(), 'Transaction Order should not be generated yet.');

        //Create transaction order with term fee first
        Map<Id, reduivy__Study_Fee_Matrix_Item__c> termFeeMatrixItemMap = new Map<Id, reduivy__Study_Fee_Matrix_Item__c>([SELECT Id, Name, reduivy__Study_Fee__r.Name, reduivy__Amount__c
                                                                        FROM reduivy__Study_Fee_Matrix_Item__c
                                                                        WHERE reduivy__Type__c = :SMI_Helper.TYPE_PER_ACADEMIC_TERM AND reduivy__Study_Fee_Matrix__r.reduivy__Applicable_Student_Fee_Types__c = :IPR_Helper.STUDENT_FEE_TYPE_DOMESTIC]);

        for(Id iprId : iprMap.keySet()){

            trnOrderMap.put(iprId, REDU_TestData_UTIL.newTransactionOrder(iprId + '|TermFee', iprMap.get(iprId).reduivy__Contact__c, iprId, System.today(), TRO_DRAFT_STATUS, 0, 0, 0));
        }
        insert trnOrderMap.values();

        List<reduivy__Transaction_Line_Item__c> trnLineItemList = new List<reduivy__Transaction_Line_Item__c>();
        for(Id iprId : trnOrderMap.keySet()){
            for(Id termFeeMatrixItemId : termFeeMatrixItemMap.keySet()){
                trnLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(trnOrderMap.get(iprId).Id + '|' + termFeeMatrixItemMap.get(termFeeMatrixItemId).reduivy__Study_Fee__r.Name, trnOrderMap.get(iprId).Id, termFeeMatrixItemMap.get(termFeeMatrixItemId).Id, termFeeMatrixItemMap.get(termFeeMatrixItemId).reduivy__Study_Fee__r.Name, SFE_Helper.ITEM_TYPE_MISCELLANEOUS, termFeeMatrixItemMap.get(termFeeMatrixItemId).reduivy__Amount__c, null, null));
            }
        }
        insert trnLineItemList;

        List<reduivy__Transaction_Order__c> orderStatusUpdateList = new List<reduivy__Transaction_Order__c>();
        for (reduivy__Transaction_Order__c tro : trnOrderMap.values()) {
            reduivy__Transaction_Order__c troUpdate = new reduivy__Transaction_Order__c();
            troUpdate.Id = tro.Id;
            troUpdate.reduivy__Status__c = TRO_CONFIRMED_STATUS;
            orderStatusUpdateList.add(tro);
        }

        update orderStatusUpdateList;

        for(reduivy__Individual_Academic_Progress__c ipr : iprMap.values()){
            ipr.reduivy__Student_Fee_Type__c = IPR_Helper.STUDENT_FEE_TYPE_DOMESTIC;
            ipr.reduivy__Generate_Transaction_Orders__c = true;
            ipr.reduivy__Order_Generation_Action__c = IPR_Helper.ORDER_GENERATION_ACTION_NEW_ONLY;
        }

        System.runAs(ADMIN_USER) {
            
            Test.startTest();
            update iprMap.values();
            Test.stopTest();
        }

        //Check Transaction Order
        Map<Id, Id> iprIdTranOrderIdMap = new Map<Id, Id>();
        Map<Id, reduivy__Transaction_Order__c> primaryTrnOrderMap = new Map<Id, reduivy__Transaction_Order__c>([SELECT Id, reduivy__Primary__c, reduivy__Individual_Academic_Progress__c, reduivy__Contact__r.reduivy__Sample_Record_Code__c
                    FROM reduivy__Transaction_Order__c 
                    WHERE reduivy__Individual_Academic_Progress__c = :iprMap.keySet() AND reduivy__Primary__c = true]);

        for(reduivy__Transaction_Order__c trnOrder : primaryTrnOrderMap.values()){

            System.Assert.areEqual(true, trnOrder.reduivy__Primary__c, 'Transaction order should be marked as primary.');
            iprIdTranOrderIdMap.put(trnOrder.reduivy__Individual_Academic_Progress__c, trnOrder.Id);
        }
        System.Assert.areEqual(iprMap.size(), iprIdTranOrderIdMap.size(), 'Number of generated Transaction Order should matches the number of Individual Academic Progress.');

        //Check Transaction Line Item
        Map<Id, List<reduivy__Transaction_Line_Item__c>> trnOrderIdLineItemMap = new Map<Id, List<reduivy__Transaction_Line_Item__c>>();
        for(reduivy__Transaction_Line_Item__c trl : [SELECT Id, reduivy__Transaction_Order__c, reduivy__Individual_Enrollment__c, reduivy__Transaction_Order__r.reduivy__Individual_Academic_Progress__c, reduivy__Study_Fee_Matrix_Item__r.reduivy__Type__c
                                                FROM reduivy__Transaction_Line_Item__c 
                                                WHERE reduivy__Transaction_Order__c IN :primaryTrnOrderMap.keySet()]){
            if(trnOrderIdLineItemMap.containsKey(trl.reduivy__Transaction_Order__c)){
                trnOrderIdLineItemMap.get(trl.reduivy__Transaction_Order__c).add(trl);
            }else{
                trnOrderIdLineItemMap.put(trl.reduivy__Transaction_Order__c, new List<reduivy__Transaction_Line_Item__c>{trl});
            }
        }

        for(Id tranOrderId : trnOrderIdLineItemMap.keySet()){

            Integer perCreditFeeCount = 0;
            Integer perUnitStudyFeeCount = 0;
            Integer perTermFeeCount = 0;
            Integer perAnnualFeeCount = 0;
            for(reduivy__Transaction_Line_Item__c trl : trnOrderIdLineItemMap.get(tranOrderId)){

                if(String.isNotBlank(trl.reduivy__Individual_Enrollment__c ) && trl.reduivy__Study_Fee_Matrix_Item__r.reduivy__Type__c == SMI_Helper.TYPE_PER_CREDIT){
                    perCreditFeeCount++;
                }else if(String.isNotBlank(trl.reduivy__Individual_Enrollment__c ) && trl.reduivy__Study_Fee_Matrix_Item__r.reduivy__Type__c == SMI_Helper.TYPE_PER_STUDY_UNIT){
                    perUnitStudyFeeCount++;
                }else if(String.isBlank(trl.reduivy__Individual_Enrollment__c ) && trl.reduivy__Study_Fee_Matrix_Item__r.reduivy__Type__c == SMI_Helper.TYPE_PER_ACADEMIC_TERM){
                    perTermFeeCount++;
                }else if(String.isBlank(trl.reduivy__Individual_Enrollment__c ) && trl.reduivy__Study_Fee_Matrix_Item__r.reduivy__Type__c == SMI_Helper.TYPE_PER_ACADEMIC_YEAR){
                    perAnnualFeeCount++;
                }
            }

            Map<String, reduivy__Individual_Enrollment__c> unitCodeIenMap = new Map<String, reduivy__Individual_Enrollment__c>();
            for(reduivy__Individual_Enrollment__c ien : iprMap.get(primaryTrnOrderMap.get(tranOrderId).reduivy__Individual_Academic_Progress__c).reduivy__Individual_Enrollments__r){
                unitCodeIenMap.put(ien.reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Unit_Code__c, ien);
            }

            System.Assert.areEqual(iprMap.get(primaryTrnOrderMap.get(tranOrderId).reduivy__Individual_Academic_Progress__c).reduivy__Individual_Enrollments__r.size(), perCreditFeeCount, 'Number of per Credit transaction line item should match with the number of invidual enrollment.');
            System.Assert.areEqual(false, unitCodeIenMap.containsKey('ICT101') && perUnitStudyFeeCount != 1, 'Number of per Study Unit transaction line item should 1 for student enrolled to ICT101.');
            System.Assert.areEqual(0, perTermFeeCount, 'Number of per Study Term transaction line item should 0 as it was generated in another transaction order.');
            
            //only sandydoe is charged as this is the first term for him
            if(primaryTrnOrderMap.get(tranOrderId).reduivy__Contact__r.reduivy__Sample_Record_Code__c == 'sandydoe@redu.example') { 
                System.Assert.areEqual(1, perAnnualFeeCount, 'Number of per Academic Year transaction line item should 1.');
            } else {
                System.Assert.areEqual(0, perAnnualFeeCount, 'Number of per Academic Year transaction line item should 0.');
            }
        }
    }

    /**
     * @description Test generate Order with per academic year fee, and the academic year fee is charged for current year.
     */
    @IsTest
    static void testGenerateTrnOrderWithAnnualFee() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<Id, reduivy__Individual_Academic_Progress__c> iprMap = new Map<Id, reduivy__Individual_Academic_Progress__c>(
                                                                [SELECT Id, reduivy__Contact__c, reduivy__Student_Fee_Type__c, reduivy__Generate_Transaction_Orders__c, reduivy__Order_Generation_Action__c,
                                                                (SELECT Id, reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Unit_Code__c FROM reduivy__Individual_Enrollments__r)
                                                                FROM reduivy__Individual_Academic_Progress__c 
                                                                WHERE reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c =:testFactory.CYTKey]);
        System.Assert.areEqual(false, iprMap.isEmpty(), 'Individual Academic Progress should not be empty.');

        Map<Id, reduivy__Transaction_Order__c> trnOrderMap = new Map<Id, reduivy__Transaction_Order__c>(
                                                        [SELECT Id, reduivy__Primary__c, reduivy__Individual_Academic_Progress__c 
                                                        FROM reduivy__Transaction_Order__c 
                                                        WHERE reduivy__Individual_Academic_Progress__c = :iprMap.keySet()]);
        System.Assert.areEqual(true, trnOrderMap.isEmpty(), 'Transaction Order should not be generated yet.');

        //Create transaction order with term fee first
        Map<Id, reduivy__Study_Fee_Matrix_Item__c> termFeeMatrixItemMap = new Map<Id, reduivy__Study_Fee_Matrix_Item__c>([SELECT Id, Name, reduivy__Study_Fee__r.Name, reduivy__Amount__c
                                                                        FROM reduivy__Study_Fee_Matrix_Item__c
                                                                        WHERE reduivy__Type__c = :SMI_Helper.TYPE_PER_ACADEMIC_YEAR AND reduivy__Study_Fee_Matrix__r.reduivy__Applicable_Student_Fee_Types__c = :IPR_Helper.STUDENT_FEE_TYPE_DOMESTIC]);

        for(Id iprId : iprMap.keySet()){

            trnOrderMap.put(iprId, REDU_TestData_UTIL.newTransactionOrder(iprId + '|TermFee', iprMap.get(iprId).reduivy__Contact__c, iprId, System.today(), TRO_DRAFT_STATUS, 0, 0, 0));
        }

        insert trnOrderMap.values();

        List<reduivy__Transaction_Line_Item__c> trnLineItemList = new List<reduivy__Transaction_Line_Item__c>();
        for(Id iprId : trnOrderMap.keySet()){
            for(Id termFeeMatrixItemId : termFeeMatrixItemMap.keySet()){
                trnLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(trnOrderMap.get(iprId).Id + '|' + termFeeMatrixItemMap.get(termFeeMatrixItemId).reduivy__Study_Fee__r.Name, trnOrderMap.get(iprId).Id, termFeeMatrixItemMap.get(termFeeMatrixItemId).Id, termFeeMatrixItemMap.get(termFeeMatrixItemId).reduivy__Study_Fee__r.Name, SFE_Helper.ITEM_TYPE_MISCELLANEOUS, termFeeMatrixItemMap.get(termFeeMatrixItemId).reduivy__Amount__c, null, null));
            }
        }

        insert trnLineItemList;

        List<reduivy__Transaction_Order__c> orderStatusUpdateList = new List<reduivy__Transaction_Order__c>();
        for (reduivy__Transaction_Order__c tro : trnOrderMap.values()) {
            reduivy__Transaction_Order__c troUpdate = new reduivy__Transaction_Order__c();
            troUpdate.Id = tro.Id;
            troUpdate.reduivy__Status__c = TRO_CONFIRMED_STATUS;
            orderStatusUpdateList.add(tro);
        }

        update orderStatusUpdateList;

        for(reduivy__Individual_Academic_Progress__c ipr : iprMap.values()){
            ipr.reduivy__Student_Fee_Type__c = IPR_Helper.STUDENT_FEE_TYPE_DOMESTIC;
            ipr.reduivy__Generate_Transaction_Orders__c = true;
            ipr.reduivy__Order_Generation_Action__c = IPR_Helper.ORDER_GENERATION_ACTION_NEW_ONLY;
        }

        System.runAs(ADMIN_USER) {
            
            Test.startTest();
            update iprMap.values();
            Test.stopTest();
        }

        //Check Transaction Order
        Map<Id, Id> iprIdTranOrderIdMap = new Map<Id, Id>();
        Map<Id, reduivy__Transaction_Order__c> primaryTrnOrderMap = new Map<Id, reduivy__Transaction_Order__c>([SELECT Id, reduivy__Primary__c, reduivy__Individual_Academic_Progress__c 
                    FROM reduivy__Transaction_Order__c 
                    WHERE reduivy__Individual_Academic_Progress__c = :iprMap.keySet() AND reduivy__Primary__c = true]);

        for(reduivy__Transaction_Order__c trnOrder : primaryTrnOrderMap.values()){

            System.Assert.areEqual(true, trnOrder.reduivy__Primary__c, 'Transaction order should be marked as primary.');
            iprIdTranOrderIdMap.put(trnOrder.reduivy__Individual_Academic_Progress__c, trnOrder.Id);
        }
        System.Assert.areEqual(iprMap.size(), iprIdTranOrderIdMap.size(), 'Number of generated Transaction Order should matches the number of Individual Academic Progress.');

        //Check Transaction Line Item
        Map<Id, List<reduivy__Transaction_Line_Item__c>> trnOrderIdLineItemMap = new Map<Id, List<reduivy__Transaction_Line_Item__c>>();
        for(reduivy__Transaction_Line_Item__c trl : [SELECT Id, reduivy__Transaction_Order__c, reduivy__Individual_Enrollment__c, reduivy__Transaction_Order__r.reduivy__Individual_Academic_Progress__c, reduivy__Study_Fee_Matrix_Item__r.reduivy__Type__c
                                                FROM reduivy__Transaction_Line_Item__c 
                                                WHERE reduivy__Transaction_Order__c IN :primaryTrnOrderMap.keySet()]){
            if(trnOrderIdLineItemMap.containsKey(trl.reduivy__Transaction_Order__c)){
                trnOrderIdLineItemMap.get(trl.reduivy__Transaction_Order__c).add(trl);
            }else{
                trnOrderIdLineItemMap.put(trl.reduivy__Transaction_Order__c, new List<reduivy__Transaction_Line_Item__c>{trl});
            }
        }

        for(Id tranOrderId : trnOrderIdLineItemMap.keySet()){

            Integer perCreditFeeCount = 0;
            Integer perUnitStudyFeeCount = 0;
            Integer perTermFeeCount = 0;
            Integer perAnnualFeeCount = 0;
            for(reduivy__Transaction_Line_Item__c trl : trnOrderIdLineItemMap.get(tranOrderId)){

                if(String.isNotBlank(trl.reduivy__Individual_Enrollment__c ) && trl.reduivy__Study_Fee_Matrix_Item__r.reduivy__Type__c == SMI_Helper.TYPE_PER_CREDIT){
                    perCreditFeeCount++;
                }else if(String.isNotBlank(trl.reduivy__Individual_Enrollment__c ) && trl.reduivy__Study_Fee_Matrix_Item__r.reduivy__Type__c == SMI_Helper.TYPE_PER_STUDY_UNIT){
                    perUnitStudyFeeCount++;
                }else if(String.isBlank(trl.reduivy__Individual_Enrollment__c ) && trl.reduivy__Study_Fee_Matrix_Item__r.reduivy__Type__c == SMI_Helper.TYPE_PER_ACADEMIC_TERM){
                    perTermFeeCount++;
                }else if(String.isBlank(trl.reduivy__Individual_Enrollment__c ) && trl.reduivy__Study_Fee_Matrix_Item__r.reduivy__Type__c == SMI_Helper.TYPE_PER_ACADEMIC_YEAR){
                    perAnnualFeeCount++;
                }
            }

            Map<String, reduivy__Individual_Enrollment__c> unitCodeIenMap = new Map<String, reduivy__Individual_Enrollment__c>();
            for(reduivy__Individual_Enrollment__c ien : iprMap.get(primaryTrnOrderMap.get(tranOrderId).reduivy__Individual_Academic_Progress__c).reduivy__Individual_Enrollments__r){
                unitCodeIenMap.put(ien.reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Unit_Code__c, ien);
            }

            System.Assert.areEqual(iprMap.get(primaryTrnOrderMap.get(tranOrderId).reduivy__Individual_Academic_Progress__c).reduivy__Individual_Enrollments__r.size(), perCreditFeeCount, 'Number of per Credit transaction line item should match with the number of invidual enrollment.');
            System.Assert.areEqual(false, unitCodeIenMap.containsKey('ICT101') && perUnitStudyFeeCount != 1, 'Number of per Study Unit transaction line item should 1 for student enrolled to ICT101.');
            System.Assert.areEqual(1, perTermFeeCount, 'Number of per Study Term transaction line item should be 1.');
            System.Assert.areEqual(0, perAnnualFeeCount, 'Number of per Academic Year transaction line item should be 0 as it was generated in another transaction order.');
        }
    }

    /**
     * @description Test generate Order with per credit - Applicable for Attempt Number
     */
    @IsTest
    static void testGenerateTrnOrderWithAttemptNo() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        //Test Dosmestic, set per credit, attempt #1, #2, #3
        Map<Integer, reduivy__Study_Fee_Matrix_Item__c> newSmxAttemptMap = new Map<Integer, reduivy__Study_Fee_Matrix_Item__c>();
        reduivy__Study_Fee_Matrix_Item__c smxAttemptOne = [SELECT Id, reduivy__Study_Fee__c, reduivy__Type__c, reduivy__Applicable_for_Attempt_Number__c, reduivy__Amount__c, reduivy__Study_Fee_Matrix__c 
                                                    FROM reduivy__Study_Fee_Matrix_Item__c 
                                                    WHERE reduivy__Sample_Record_Code__c = 'UNIT_TUITION_FEE_FOR_DOMESTIC' LIMIT 1];

        smxAttemptOne.reduivy__Applicable_for_Attempt_Number__c = '1';
        update smxAttemptOne;

        newSmxAttemptMap.put(2, REDU_TestData_UTIL.newStudyFeeMatrixItem('UNIT_TUITION_FEE_FOR_DOMESTIC_2', smxAttemptOne.reduivy__Study_Fee_Matrix__c, smxAttemptOne.reduivy__Study_Fee__c, SMI_Helper.TYPE_PER_CREDIT, 702, '2', null, null));
        newSmxAttemptMap.put(3, REDU_TestData_UTIL.newStudyFeeMatrixItem('UNIT_TUITION_FEE_FOR_DOMESTIC_3', smxAttemptOne.reduivy__Study_Fee_Matrix__c, smxAttemptOne.reduivy__Study_Fee__c, SMI_Helper.TYPE_PER_CREDIT, 703, '3', null, null));
        insert newSmxAttemptMap.values();

        newSmxAttemptMap.put(1, smxAttemptOne);

        Map<Id, reduivy__Individual_Academic_Progress__c> iprMap = new Map<Id, reduivy__Individual_Academic_Progress__c>(
                                                                [SELECT Id, reduivy__Contact__c, reduivy__Student_Fee_Type__c, reduivy__Generate_Transaction_Orders__c, reduivy__Order_Generation_Action__c,
                                                                (SELECT Id, reduivy__Attempt_Number__c, reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Unit_Code__c FROM reduivy__Individual_Enrollments__r)
                                                                FROM reduivy__Individual_Academic_Progress__c 
                                                                WHERE reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c =:testFactory.CYTKey LIMIT 3]);

        List<reduivy__Individual_Enrollment__c> updateIenAttemptNoList = new List<reduivy__Individual_Enrollment__c>();
        Integer i=1;
        for(reduivy__Individual_Academic_Progress__c ipr : iprMap.values()){
            ipr.reduivy__Student_Fee_Type__c = IPR_Helper.STUDENT_FEE_TYPE_DOMESTIC;
            ipr.reduivy__Generate_Transaction_Orders__c = true;
            ipr.reduivy__Order_Generation_Action__c = IPR_Helper.ORDER_GENERATION_ACTION_NEW_ONLY;

            //IPS 1 - All attempt 1
            //IPS 2 - 2 attempt #1, 2 attempt #2
            //IPS 3 - 1 attempt #1, 1 attempt #2, 2 attempt #3

            Integer ienCount = 1;
            for(reduivy__Individual_Enrollment__c  ien : ipr.reduivy__Individual_Enrollments__r){

                if(i == 1){
                    ien.reduivy__Attempt_Number__c = 1;
                }else if(i == 2){
                    if(ienCount <= 2){
                        ien.reduivy__Attempt_Number__c = 1;
                    }else{
                        ien.reduivy__Attempt_Number__c = 2;
                    }
                }else{
                    if(ienCount == 1){
                        ien.reduivy__Attempt_Number__c = 1;
                    }else if(ienCount == 2){
                        ien.reduivy__Attempt_Number__c = 2;
                    }else{
                        ien.reduivy__Attempt_Number__c = 3;
                    }
                }
                
                updateIenAttemptNoList.add(ien);
                ienCount ++;
            }
            i ++;
        }

        update updateIenAttemptNoList;

        System.runAs(ADMIN_USER) {
            
            Test.startTest();
            update iprMap.values();
            Test.stopTest();
        }

        //Check Transaction Order
        Map<Id, Id> iprIdTranOrderIdMap = new Map<Id, Id>();
        Map<Id, reduivy__Transaction_Order__c> trnOrderMap = new Map<Id, reduivy__Transaction_Order__c>([SELECT Id, reduivy__Primary__c, reduivy__Individual_Academic_Progress__c 
                    FROM reduivy__Transaction_Order__c 
                    WHERE reduivy__Individual_Academic_Progress__c = :iprMap.keySet()]);

        for(reduivy__Transaction_Order__c trnOrder : trnOrderMap.values()){

            System.Assert.areEqual(true, trnOrder.reduivy__Primary__c, 'Transaction order should be marked as primary.');
            iprIdTranOrderIdMap.put(trnOrder.reduivy__Individual_Academic_Progress__c, trnOrder.Id);
        }
        System.Assert.areEqual(iprMap.size(), iprIdTranOrderIdMap.size(), 'Number of generated Transaction Order should matches the number of Individual Academic Progress.');

        //Check Transaction Line Item
        Map<Id, List<reduivy__Transaction_Line_Item__c>> trnOrderIdLineItemMap = new Map<Id, List<reduivy__Transaction_Line_Item__c>>();
        for(reduivy__Transaction_Line_Item__c trl : [SELECT Id, reduivy__Transaction_Order__c, reduivy__Individual_Enrollment__c, reduivy__Transaction_Order__r.reduivy__Individual_Academic_Progress__c, reduivy__Study_Fee_Matrix_Item__r.reduivy__Type__c,
                                                reduivy__Total_Amount__c, reduivy__Study_Fee_Matrix_Item__c, reduivy__Individual_Enrollment__r.reduivy__Attempt_Number__c, reduivy__Individual_Enrollment__r.reduivy__Credits_Offered__c
                                                FROM reduivy__Transaction_Line_Item__c 
                                                WHERE reduivy__Transaction_Order__c IN :trnOrderMap.keySet()]){
            
            if(String.isNotBlank(String.Valueof(trl.reduivy__Individual_Enrollment__r.reduivy__Attempt_Number__c)) && newSmxAttemptMap.containsKey(Integer.ValueOf(trl.reduivy__Individual_Enrollment__r.reduivy__Attempt_Number__c)) && trl.reduivy__Study_Fee_Matrix_Item__r.reduivy__Type__c == SMI_Helper.TYPE_PER_CREDIT){

                REDU_Logging_UTIL.debug('Amount', trl.reduivy__Total_Amount__c + ' || Formula :: '+ newSmxAttemptMap.get(Integer.ValueOf(trl.reduivy__Individual_Enrollment__r.reduivy__Attempt_Number__c)).reduivy__Amount__c + ' * '+ trl.reduivy__Individual_Enrollment__r.reduivy__Credits_Offered__c);
                System.Assert.areEqual(trl.reduivy__Study_Fee_Matrix_Item__c, newSmxAttemptMap.get(Integer.ValueOf(trl.reduivy__Individual_Enrollment__r.reduivy__Attempt_Number__c)).Id, 'The study fee matrix item is not correct according to the IEN\'s attempt number');
                System.Assert.areEqual(trl.reduivy__Total_Amount__c, newSmxAttemptMap.get(Integer.ValueOf(trl.reduivy__Individual_Enrollment__r.reduivy__Attempt_Number__c)).reduivy__Amount__c * trl.reduivy__Individual_Enrollment__r.reduivy__Credits_Offered__c, 'The amount charged is not correct according to the IEN\'s attempt number');
            }
        }
    }

    /**
     * @description Generate Order with per credit, study unit, term and academic year fees - Applicable For Term #
     */
    @IsTest
    static void testGenerateTrnOrderWithApplForTerm() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Study_Fee_Matrix_Item__c smiInsurance = [SELECT Id, reduivy__Study_Fee__c, reduivy__Type__c, reduivy__Applicable_For_Term__c, reduivy__Amount__c, reduivy__Study_Fee_Matrix__c 
                                                    FROM reduivy__Study_Fee_Matrix_Item__c 
                                                    WHERE reduivy__Sample_Record_Code__c = 'INSURANCE_FEE_FOR_INTERNATIONAL' LIMIT 1];
        
        Map<Id, reduivy__Individual_Academic_Progress__c> iprMap = new Map<Id, reduivy__Individual_Academic_Progress__c>(
                                                    [SELECT Id, reduivy__Contact__c, reduivy__Student_Fee_Type__c, reduivy__Generate_Transaction_Orders__c, reduivy__Order_Generation_Action__c,
                                                    (SELECT Id, reduivy__Academic_Term__c, reduivy__Individual_Academic_Progress__c, reduivy__Individual_Program_Enrollment__c, reduivy__Term_Number__c FROM reduivy__Individual_Pathways__r)
                                                    FROM reduivy__Individual_Academic_Progress__c 
                                                    WHERE reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c =:testFactory.CYTKey LIMIT 6]);

        List<reduivy__Individual_Pathway__c> updateIdvPathwayList = new List<reduivy__Individual_Pathway__c>();
        Integer i=1;
        Map<Id, Boolean> term1IprInsuranceMap = new Map<Id, Boolean>();
        Map<Id, Boolean> term2IprInsuranceMap = new Map<Id, Boolean>();
        for(reduivy__Individual_Academic_Progress__c ipr : iprMap.values()){
            ipr.reduivy__Student_Fee_Type__c = IPR_Helper.STUDENT_FEE_TYPE_INTERNATIONAL;
            ipr.reduivy__Generate_Transaction_Orders__c = true;
            ipr.reduivy__Order_Generation_Action__c = IPR_Helper.ORDER_GENERATION_ACTION_NEW_ONLY;

            for(reduivy__Individual_Pathway__c  idvPathway : ipr.reduivy__Individual_Pathways__r){

                if(i <= 3){
                    term1IprInsuranceMap.put(ipr.Id, false);
                    idvPathway.reduivy__Term_Number__c = 1;
                }else{
                    term2IprInsuranceMap.put(ipr.Id, false);
                    idvPathway.reduivy__Term_Number__c = 2;
                }
                
                updateIdvPathwayList.add(idvPathway);
            }
            i ++;
        }

        update updateIdvPathwayList;

        System.runAs(ADMIN_USER) {
            
            Test.startTest();
            update iprMap.values();
            Test.stopTest();
        }

        //Check Transaction Order
        Map<Id, Id> iprIdTranOrderIdMap = new Map<Id, Id>();
        Map<Id, reduivy__Transaction_Order__c> trnOrderMap = new Map<Id, reduivy__Transaction_Order__c>([SELECT Id, reduivy__Primary__c, reduivy__Individual_Academic_Progress__c 
                    FROM reduivy__Transaction_Order__c 
                    WHERE reduivy__Individual_Academic_Progress__c = :iprMap.keySet()]);

        for(reduivy__Transaction_Order__c trnOrder : trnOrderMap.values()){

            System.Assert.areEqual(true, trnOrder.reduivy__Primary__c, 'Transaction order should be marked as primary.');
            iprIdTranOrderIdMap.put(trnOrder.reduivy__Individual_Academic_Progress__c, trnOrder.Id);
        }
        System.Assert.areEqual(iprMap.size(), iprIdTranOrderIdMap.size(), 'Number of generated Transaction Order should matches the number of Individual Academic Progress.');

        //Check Transaction Line Item
        Map<Id, List<reduivy__Transaction_Line_Item__c>> trnOrderIdLineItemMap = new Map<Id, List<reduivy__Transaction_Line_Item__c>>();
        for(reduivy__Transaction_Line_Item__c trl : [SELECT Id, reduivy__Transaction_Order__c, reduivy__Individual_Enrollment__c, reduivy__Transaction_Order__r.reduivy__Individual_Academic_Progress__c, reduivy__Study_Fee_Matrix_Item__r.reduivy__Type__c,
                                                reduivy__Total_Amount__c, reduivy__Study_Fee_Matrix_Item__c, reduivy__Individual_Enrollment__r.reduivy__Attempt_Number__c, reduivy__Individual_Enrollment__r.reduivy__Credits_Offered__c
                                                FROM reduivy__Transaction_Line_Item__c 
                                                WHERE reduivy__Transaction_Order__c IN :trnOrderMap.keySet()]){
            
            if(term1IprInsuranceMap.containsKey(trl.reduivy__Transaction_Order__r.reduivy__Individual_Academic_Progress__c) && trl.reduivy__Study_Fee_Matrix_Item__c == smiInsurance.Id){
                term1IprInsuranceMap.put(trl.reduivy__Transaction_Order__r.reduivy__Individual_Academic_Progress__c, true);
            }

            if(term2IprInsuranceMap.containsKey(trl.reduivy__Transaction_Order__r.reduivy__Individual_Academic_Progress__c) && trl.reduivy__Study_Fee_Matrix_Item__c == smiInsurance.Id){
                term2IprInsuranceMap.put(trl.reduivy__Transaction_Order__r.reduivy__Individual_Academic_Progress__c, true);
            }
        }

        for(Id iprId : term1IprInsuranceMap.keyset()){
            System.Assert.areEqual(true, term1IprInsuranceMap.get(iprId), 'Insurance fee should be generated for term 1.');
        }

        for(Id iprId : term2IprInsuranceMap.keyset()){
            System.Assert.areEqual(false, term2IprInsuranceMap.get(iprId), 'Insurance fee should not be generated for term 2.');
        }
    }

    /**
     * @description Test generate Order with per credit, study unit fees. Order Generation Action = New Order Only, with different IEN statuses
     */
    @IsTest
    static void testGenerateTrnOrderWithDiffIenStatuses() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        delete [SELECT Id FROM reduivy__Individual_Enrollment_Grade__c];
        delete [SELECT Id FROM reduivy__Individual_Enrollment__c];

        REDU_TriggerController.muteTriggers(new Set<String>{'IEN_AcademicProgress_EXE', 'IEN_AcademicProgressRollup_EXE', 'IEN_BestAttempt_EXE', 'IEN_CompletionEngine_EXE', 'IEN_IncrementAttemptNumber_EXE', 'IEN_ReassignIpsu_EXE', 'IEN_StudyOfferingRollup_EXE', 'IPS_RequirementMet_EXE'});

        Account sydneyCampus = [SELECT Id FROM Account WHERE reduivy__Sample_Record_Code__c = 'SYDNEY' LIMIT 1];

        Map<Id, reduivy__Individual_Academic_Progress__c> iprMap = new Map<Id, reduivy__Individual_Academic_Progress__c>();
        for(reduivy__Individual_Pathway__c idvPathway : [SELECT Id, reduivy__Individual_Academic_Progress__c 
                                                        FROM reduivy__Individual_Pathway__c 
                                                        WHERE reduivy__Term_Number__c = 1]){

            iprMap.put(idvPathway.reduivy__Individual_Academic_Progress__c, null);
        }

        Set<Id> academicTermId = new Set<Id>();
        for(reduivy__Individual_Academic_Progress__c ipr : [SELECT Id, reduivy__Student_Fee_Type__c, reduivy__Generate_Transaction_Orders__c, reduivy__Order_Generation_Action__c, reduivy__Academic_Term__c, reduivy__Contact__c
                                                    FROM reduivy__Individual_Academic_Progress__c 
                                                    WHERE Id IN: iprMap.keySet()]){

            iprMap.put(ipr.Id, ipr);
            academicTermId.add(ipr.reduivy__Academic_Term__c);
        }
        System.Assert.areEqual(false, iprMap.isEmpty(), 'Individual Academic Progress should not be empty.');

        Map<Id, reduivy__Transaction_Order__c> trnOrderMap = new Map<Id, reduivy__Transaction_Order__c>(
                                                        [SELECT Id, reduivy__Primary__c, reduivy__Individual_Academic_Progress__c 
                                                        FROM reduivy__Transaction_Order__c 
                                                        WHERE reduivy__Individual_Academic_Progress__c = :iprMap.keySet()]);
        System.Assert.areEqual(true, trnOrderMap.isEmpty(), 'Transaction Order should not be generated yet.');

        List<reduivy__Study_Offering__c> sofToBeCreated = new List<reduivy__Study_Offering__c>();
        
        for(reduivy__Study_Unit__c su : [SELECT Id FROM reduivy__Study_Unit__c WHERE reduivy__Unit_Code__c != 'ICT101' LIMIT 6]){
            for(Id acTermId : academicTermId){
                sofToBeCreated.add(new reduivy__Study_Offering__c(
                    reduivy__Academic_Term__c = acTermId,
                    reduivy__Study_Unit__c = su.Id,
                    reduivy__Status_Override__c = SOF_Helper.getEnrollmentOpenedStatuses().get(0),
                    reduivy__Capacity__c = 100, 
                    reduivy__Campus__c = sydneyCampus.Id
                ));
            }
        }

        insert sofToBeCreated;

        List<reduivy__Individual_Enrollment__c> ienToBeCreated = new List<reduivy__Individual_Enrollment__c>();

        for(Integer i = 0; i < 6; i++) {
            reduivy__Study_Offering__c sof = sofToBeCreated[i];
            
            if(i == 0) {
                for(reduivy__Individual_Academic_Progress__c ipr : iprMap.values()) {
                    ienToBeCreated.add(new reduivy__Individual_Enrollment__c(
                        reduivy__Individual_Academic_Progress__c = ipr.Id,
                        reduivy__Study_Offering__c = sof.Id, 
                        reduivy__Contact__c = ipr.reduivy__Contact__c, 
                        reduivy__Enrollment_Status__c = IEN_Helper.getCompletedPassStatuses().get(0)
                    ));
                }
            }

            if(i == 1) {
                for(reduivy__Individual_Academic_Progress__c ipr : iprMap.values()) {
                    ienToBeCreated.add(new reduivy__Individual_Enrollment__c(
                        reduivy__Individual_Academic_Progress__c = ipr.Id,
                        reduivy__Study_Offering__c = sof.Id, 
                        reduivy__Contact__c = ipr.reduivy__Contact__c, 
                        reduivy__Enrollment_Status__c = IEN_Helper.getCompletedFailStatuses().get(0)
                    ));
                }
            }

            if(i == 2) {
                for(reduivy__Individual_Academic_Progress__c ipr : iprMap.values()) {
                    ienToBeCreated.add(new reduivy__Individual_Enrollment__c(
                        reduivy__Individual_Academic_Progress__c = ipr.Id,
                        reduivy__Study_Offering__c = sof.Id, 
                        reduivy__Contact__c = ipr.reduivy__Contact__c, 
                        reduivy__Enrollment_Status__c = IEN_Helper.getWaitlistedStatuses().get(0)
                    ));
                }
            }

            if(i == 3) {
                for(reduivy__Individual_Academic_Progress__c ipr : iprMap.values()) {
                    ienToBeCreated.add(new reduivy__Individual_Enrollment__c(
                        reduivy__Individual_Academic_Progress__c = ipr.Id,
                        reduivy__Study_Offering__c = sof.Id, 
                        reduivy__Contact__c = ipr.reduivy__Contact__c, 
                        reduivy__Enrollment_Status__c = IEN_Helper.getWithdrawnStatuses().get(0)
                    ));
                }
            }

            if(i == 4) {
                for(reduivy__Individual_Academic_Progress__c ipr : iprMap.values()) {
                    ienToBeCreated.add(new reduivy__Individual_Enrollment__c(
                        reduivy__Individual_Academic_Progress__c = ipr.Id,
                        reduivy__Study_Offering__c = sof.Id, 
                        reduivy__Contact__c = ipr.reduivy__Contact__c, 
                        reduivy__Enrollment_Status__c = IEN_Helper.getInProgressStatuses().get(0)
                    ));
                }
            }

            if(i == 5) {
                for(reduivy__Individual_Academic_Progress__c ipr : iprMap.values()) {
                    ienToBeCreated.add(new reduivy__Individual_Enrollment__c(
                        reduivy__Individual_Academic_Progress__c = ipr.Id,
                        reduivy__Study_Offering__c = sof.Id, 
                        reduivy__Contact__c = ipr.reduivy__Contact__c, 
                        reduivy__Enrollment_Status__c = IEN_Helper.getWithdrawalRequestedStatuses().get(0)
                    ));
                }
            }
        }

        insert ienToBeCreated;

        for(reduivy__Individual_Academic_Progress__c ipr : iprMap.values()){
            ipr.reduivy__Student_Fee_Type__c = IPR_Helper.STUDENT_FEE_TYPE_DOMESTIC;
            ipr.reduivy__Generate_Transaction_Orders__c = true;
            ipr.reduivy__Order_Generation_Action__c = IPR_Helper.ORDER_GENERATION_ACTION_NEW_ONLY;
        }

        System.runAs(ADMIN_USER) {
            
            Test.startTest();
            update iprMap.values();
        }

        //Check Transaction Order
        Map<Id, Id> iprIdTranOrderIdMap = new Map<Id, Id>();
        trnOrderMap = new Map<Id, reduivy__Transaction_Order__c>([SELECT Id, 
            reduivy__Primary__c, 
            reduivy__Individual_Academic_Progress__c,
            reduivy__Status__c
            FROM reduivy__Transaction_Order__c 
            WHERE reduivy__Individual_Academic_Progress__c = :iprMap.keySet()
        ]);

        for(reduivy__Transaction_Order__c trnOrder : trnOrderMap.values()){
            System.assertEquals(TRO_CONFIRMED_STATUS, trnOrder.reduivy__Status__c, 'Transaction order should be marked as confirmed.');
            System.Assert.areEqual(true, trnOrder.reduivy__Primary__c, 'Transaction order should be marked as primary.');
            iprIdTranOrderIdMap.put(trnOrder.reduivy__Individual_Academic_Progress__c, trnOrder.Id);
        }
        
        System.Assert.areEqual(iprMap.size(), iprIdTranOrderIdMap.size(), 'Number of generated Transaction Order should matches the number of Individual Academic Progress.');

        //Check Transaction Line Item
        Map<Id, List<reduivy__Transaction_Line_Item__c>> trnOrderIdLineItemMap = new Map<Id, List<reduivy__Transaction_Line_Item__c>>();
        for(reduivy__Transaction_Line_Item__c trl : [SELECT Id, reduivy__Transaction_Order__c, reduivy__Individual_Enrollment__c, reduivy__Transaction_Order__r.reduivy__Individual_Academic_Progress__c, reduivy__Study_Fee_Matrix_Item__r.reduivy__Type__c
                                                FROM reduivy__Transaction_Line_Item__c 
                                                WHERE reduivy__Transaction_Order__c IN :trnOrderMap.keySet()]){
            if(trnOrderIdLineItemMap.containsKey(trl.reduivy__Transaction_Order__c)){
                trnOrderIdLineItemMap.get(trl.reduivy__Transaction_Order__c).add(trl);
            }else{
                trnOrderIdLineItemMap.put(trl.reduivy__Transaction_Order__c, new List<reduivy__Transaction_Line_Item__c>{trl});
            }
        }
        System.Assert.isFalse(trnOrderIdLineItemMap.isEmpty(), 'TRL should not be empty!');

        for(Id tranOrderId : trnOrderIdLineItemMap.keySet()){

            Integer perCreditFeeCount = 0;
            Integer perUnitStudyFeeCount = 0;
            Integer perTermFeeCount = 0;
            Integer perAnnualFeeCount = 0;
            for(reduivy__Transaction_Line_Item__c trl : trnOrderIdLineItemMap.get(tranOrderId)){

                if(String.isNotBlank(trl.reduivy__Individual_Enrollment__c ) && trl.reduivy__Study_Fee_Matrix_Item__r.reduivy__Type__c == SMI_Helper.TYPE_PER_CREDIT){
                    perCreditFeeCount++;
                }else if(String.isNotBlank(trl.reduivy__Individual_Enrollment__c ) && trl.reduivy__Study_Fee_Matrix_Item__r.reduivy__Type__c == SMI_Helper.TYPE_PER_STUDY_UNIT){
                    perUnitStudyFeeCount++;
                }else if(String.isBlank(trl.reduivy__Individual_Enrollment__c ) && trl.reduivy__Study_Fee_Matrix_Item__r.reduivy__Type__c == SMI_Helper.TYPE_PER_ACADEMIC_TERM){
                    perTermFeeCount++;
                }else if(String.isBlank(trl.reduivy__Individual_Enrollment__c ) && trl.reduivy__Study_Fee_Matrix_Item__r.reduivy__Type__c == SMI_Helper.TYPE_PER_ACADEMIC_YEAR){
                    perAnnualFeeCount++;
                }
            }

            Map<String, reduivy__Individual_Enrollment__c> unitCodeIenMap = new Map<String, reduivy__Individual_Enrollment__c>();
            for(reduivy__Individual_Enrollment__c ien : iprMap.get(trnOrderMap.get(tranOrderId).reduivy__Individual_Academic_Progress__c).reduivy__Individual_Enrollments__r){
                unitCodeIenMap.put(ien.reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Unit_Code__c, ien);
            }

            //Complted, Completed Fail, Withdrawn, Waitlisted
            System.Assert.areEqual(4, perCreditFeeCount, 'Number of per Credit transaction line item should match with the number of invidual enrollment.');
            System.Assert.areEqual(1, perTermFeeCount, 'Number of per Study Term transaction line item should 1.');
            System.Assert.areEqual(1, perAnnualFeeCount, 'Number of per Academic Year transaction line item should 1.');
        }

        List<String> activeStatuses = new List<String>();
        activeStatuses.addAll(IEN_Helper.getCompletedStatuses());
        activeStatuses.addAll(IEN_Helper.getInProgressStatuses());
        activeStatuses.addAll(IEN_Helper.getWithdrawalRequestedStatuses());
        
        List<reduivy__Individual_Enrollment__c> ienToBeUpdated = new List<reduivy__Individual_Enrollment__c>();
        for(reduivy__Individual_Enrollment__c ien : [SELECT Id, reduivy__Enrollment_Status__c FROM reduivy__Individual_Enrollment__c]) {
            if(activeStatuses.contains(ien.reduivy__Enrollment_Status__c)) {
                ien.reduivy__Enrollment_Status__c = IEN_Helper.getWithdrawnStatuses().get(0);
            } else {
                ien.reduivy__Enrollment_Status__c = IEN_Helper.getInProgressStatuses().get(0);
            }

            ienToBeUpdated.add(ien);
        }

        update ienToBeUpdated;

        for(reduivy__Individual_Academic_Progress__c ipr : iprMap.values()){
            ipr.reduivy__Generate_Transaction_Orders__c = false;
            ipr.reduivy__Order_Generation_Action__c = IPR_Helper.ORDER_GENERATION_ACTION_REGENERATION;
        }

        update iprMap.values();

        for(reduivy__Individual_Academic_Progress__c ipr : iprMap.values()){
            ipr.reduivy__Generate_Transaction_Orders__c = true;
            ipr.reduivy__Order_Generation_Action__c = IPR_Helper.ORDER_GENERATION_ACTION_REGENERATION;
        }

        System.runAs(ADMIN_USER) {
            
            update iprMap.values();
            Test.stopTest();
        }

        //Check Transaction Order
        iprIdTranOrderIdMap.clear();

        trnOrderMap = new Map<Id, reduivy__Transaction_Order__c>([SELECT Id, 
            reduivy__Primary__c, 
            reduivy__Individual_Academic_Progress__c,
            reduivy__Status__c
            FROM reduivy__Transaction_Order__c 
            WHERE reduivy__Individual_Academic_Progress__c = :iprMap.keySet()
        ]);

        for(reduivy__Transaction_Order__c trnOrder : trnOrderMap.values()){
            System.assertEquals(TRO_CONFIRMED_STATUS, trnOrder.reduivy__Status__c, 'Transaction order should be marked as confirmed.');
            System.Assert.areEqual(true, trnOrder.reduivy__Primary__c, 'Transaction order should be marked as primary.');
            iprIdTranOrderIdMap.put(trnOrder.reduivy__Individual_Academic_Progress__c, trnOrder.Id);
        }
        
        System.Assert.areEqual(iprMap.size(), iprIdTranOrderIdMap.size(), 'Number of generated Transaction Order should matches the number of Individual Academic Progress.');

        //Check Transaction Line Item
        trnOrderIdLineItemMap.clear();
        for(reduivy__Transaction_Line_Item__c trl : [SELECT Id, reduivy__Transaction_Order__c, reduivy__Individual_Enrollment__c, reduivy__Transaction_Order__r.reduivy__Individual_Academic_Progress__c, reduivy__Study_Fee_Matrix_Item__r.reduivy__Type__c
                                                FROM reduivy__Transaction_Line_Item__c 
                                                WHERE reduivy__Transaction_Order__c IN :trnOrderMap.keySet()]){
            if(trnOrderIdLineItemMap.containsKey(trl.reduivy__Transaction_Order__c)){
                trnOrderIdLineItemMap.get(trl.reduivy__Transaction_Order__c).add(trl);
            }else{
                trnOrderIdLineItemMap.put(trl.reduivy__Transaction_Order__c, new List<reduivy__Transaction_Line_Item__c>{trl});
            }
        }
        System.Assert.isFalse(trnOrderIdLineItemMap.isEmpty(), 'TRL should not be empty!');

        for(Id tranOrderId : trnOrderIdLineItemMap.keySet()){

            Integer perCreditFeeCount = 0;
            Integer perUnitStudyFeeCount = 0;
            Integer perTermFeeCount = 0;
            Integer perAnnualFeeCount = 0;
            for(reduivy__Transaction_Line_Item__c trl : trnOrderIdLineItemMap.get(tranOrderId)){

                if(String.isNotBlank(trl.reduivy__Individual_Enrollment__c ) && trl.reduivy__Study_Fee_Matrix_Item__r.reduivy__Type__c == SMI_Helper.TYPE_PER_CREDIT){
                    perCreditFeeCount++;
                }else if(String.isNotBlank(trl.reduivy__Individual_Enrollment__c ) && trl.reduivy__Study_Fee_Matrix_Item__r.reduivy__Type__c == SMI_Helper.TYPE_PER_STUDY_UNIT){
                    perUnitStudyFeeCount++;
                }else if(String.isBlank(trl.reduivy__Individual_Enrollment__c ) && trl.reduivy__Study_Fee_Matrix_Item__r.reduivy__Type__c == SMI_Helper.TYPE_PER_ACADEMIC_TERM){
                    perTermFeeCount++;
                }else if(String.isBlank(trl.reduivy__Individual_Enrollment__c ) && trl.reduivy__Study_Fee_Matrix_Item__r.reduivy__Type__c == SMI_Helper.TYPE_PER_ACADEMIC_YEAR){
                    perAnnualFeeCount++;
                }
            }

            Map<String, reduivy__Individual_Enrollment__c> unitCodeIenMap = new Map<String, reduivy__Individual_Enrollment__c>();
            for(reduivy__Individual_Enrollment__c ien : iprMap.get(trnOrderMap.get(tranOrderId).reduivy__Individual_Academic_Progress__c).reduivy__Individual_Enrollments__r){
                unitCodeIenMap.put(ien.reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Unit_Code__c, ien);
            }

            System.Assert.areEqual(2, perCreditFeeCount, 'Number of per Credit transaction line item should match with the number of invidual enrollment.');
            System.Assert.areEqual(1, perTermFeeCount, 'Number of per Study Term transaction line item should 1.');
            System.Assert.areEqual(1, perAnnualFeeCount, 'Number of per Academic Year transaction line item should 1.');
        }
    }
}