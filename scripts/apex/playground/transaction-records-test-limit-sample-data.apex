Contact testContact = new Contact(
    LastName = 'Test Transaction Records Limit 1'
);

insert testContact;

System.debug('Initial Limit :: ' + Limits.getQueries());
Integer initialLimit = Limits.getQueries();

reduivy__Transaction_Order__c troToBeInsert = REDU_TestData_UTIL.newTransactionOrder(
    testContact.Id + '_Test_Transaction_Order', 
    testContact.Id, 
    null, 
    System.today(), 
    TRO_Helper.getDraftStatuses().get(0), 
    0, 
    0, 
    0
);

insert troToBeInsert;

System.debug('After Transaction Order :: ' + (Limits.getQueries() - initialLimit));

reduivy__Transaction_Line_Item__c orderTrlToBeInsert = REDU_TestData_UTIL.newTransactionOrderLine(
    troToBeInsert.reduivy__Sample_Record_Code__c + '_Test_Order_Line', 
    troToBeInsert.Id, 
    null, 
    'Test Order Line', 
    TRL_Helper.ITEM_TYPE_TUITION, 
    2500, 
    0, 
    0
);

insert orderTrlToBeInsert;

System.debug('After Transaction Order Line Item :: ' + (Limits.getQueries() - initialLimit));

reduivy__Transaction_Line_Item__c discountTrlToBeInsert = REDU_TestData_UTIL.newTransactionDiscountEntry(
    troToBeInsert.reduivy__Sample_Record_Code__c + '_Test_Discount_Line', 
    troToBeInsert.Id, 
    'Test Discount Line', 
    TRL_Helper.ITEM_TYPE_TUITION, 
    1000, 
    null, 
    null,
    null,
    null
);

discountTrlToBeInsert.reduivy__Offset_Line_Item__c = orderTrlToBeInsert.Id;

insert discountTrlToBeInsert;

System.debug('After Transaction Discount Line Item :: ' + (Limits.getQueries() - initialLimit));

reduivy__Transaction_Order__c insertedTro = [SELECT Id, reduivy__Apply_Payment__c, reduivy__Status__c FROM reduivy__Transaction_Order__c WHERE Id = :troToBeInsert.Id LIMIT 1];
insertedTro.reduivy__Apply_Payment__c = true;
insertedTro.reduivy__Status__c = TRO_Helper.getConfirmedStatuses().get(0);

update insertedTro;

reduivy__Transaction_Payment__c trpToBeInsert = REDU_TestData_UTIL.newTransactionPayment(
    troToBeInsert.reduivy__Sample_Record_Code__c + '_Test_Transaction_Payment', 
    testContact.Id, 
    null, 
    TRP_Helper.TRANSACTION_TYPE_PAYMENT, 
    null, 
    1000, 
    0, 
    null
);

insert trpToBeInsert;

System.debug('After Apply Payment :: ' + (Limits.getQueries() - initialLimit));