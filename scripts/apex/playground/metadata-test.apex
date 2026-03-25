Integer startCpu = Limits.getCpuTime();

for (Integer i = 0; i < 100; i ++) {
    String objectName = 'reduivy__Individual_Program_Enrollment__c'.toLowerCase();
    Schema.SObjectType objType = ((SObject) Type.forName(objectName).newInstance()).getSObjectType();
    Schema.DescribeSObjectResult dsr = objType.getDescribe(SObjectDescribeOptions.DEFERRED);
}

Integer finishCpu = Limits.getCpuTime();

System.debug('type 1 :: ' + (finishCpu - startCpu));

Integer startCpu2 = Limits.getCpuTime();

for (Integer i = 0; i < 100; i ++) {
    String objectName = 'reduivy__Individual_Program_Enrollment__c'.toLowerCase();
    List<Schema.DescribeSObjectResult> sObjects = Schema.describeSObjects(new List<String>{objectName}, SObjectDescribeOptions.DEFERRED);
    Schema.DescribeSObjectResult dsr = sObjects.get(0);
    Schema.SObjectType sobjType  = dsr.getSObjectType();
}

Integer finishCpu2 = Limits.getCpuTime();

System.debug('type 2 :: ' + (finishCpu2 - startCpu2));

Integer startCpu3 = Limits.getCpuTime();

for (Integer i = 0; i < 100; i ++) {
    String objectName = 'reduivy__Individual_Program_Enrollment__c'.toLowerCase();
    Schema.SObjectType sobjType  = Schema.getGlobalDescribe().get(objectName);
    Schema.DescribeSObjectResult dsr = sobjType.getDescribe(SObjectDescribeOptions.DEFERRED);
}

Integer finishCpu3 = Limits.getCpuTime();

System.debug('type 3 :: ' + (finishCpu3 - startCpu3));