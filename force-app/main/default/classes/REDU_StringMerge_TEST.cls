/**
 * @author      WDCi (Lean)
 * @date        Sept 2023
 * @group       Test
 * @description Test class for REDU_StringMerge_UTIL
 * @changehistory
 * 
 */
@isTest
public inherited sharing class REDU_StringMerge_TEST {

    private final static String TEST_RAW_STRING = '{param1} and {param2}';

    /**
     * @description Test extract merge fields
     */
	@IsTest
    static void testExtractFieldNames(){
        
        Test.startTest();
        
        Map<String, String> mergeFields = REDU_StringMerge_UTIL.extractFieldNames(null, TEST_RAW_STRING);

        System.Assert.areEqual(2, mergeFields.size());
        System.Assert.areEqual('param1', mergeFields.get('{param1}'));
        System.Assert.areEqual('param2', mergeFields.get('{param2}'));

        Test.stopTest();
        
    }

    /**
     * @description Test merge values
     */
    @IsTest
    static void testMergeValues(){
        
        Test.startTest();
        
        Map<String, String> mergeFields = new Map<String, String>();
        mergeFields.put('param1', 'value1');
        mergeFields.put('param2', 'value2');
        
        System.Assert.areEqual('value1 and value2', REDU_StringMerge_UTIL.mergeValues(mergeFields, TEST_RAW_STRING));

        Test.stopTest();
        
    }

    /**
     * @description Test merge value with sobject fields and max length
     */
    @IsTest
    static void testSobjectMergeValuesWithMaxLength(){
        
        Test.startTest();
        
        String mergeStringPattern = 'Hallo, my name is {FirstName} {LastName}, I am from RIO Education';
        String expectedResult = 'Hallo, my name is TestFirstName TestLastName';

        Contact contact = new Contact(
            FirstName = 'TestFirstName',
            LastName = 'TestLastName'
        );
        
        System.Assert.areEqual(expectedResult, REDU_StringMerge_UTIL.mergeValues(contact, null, mergeStringPattern, 44));

        Test.stopTest();
        
    }

    /**
     * @description Test merge value with sobject fields
     */
    @IsTest
    static void testSobjectMergeValuesWithoutMaxLength(){
        
        Test.startTest();
        
        String mergeStringPattern = 'Hallo, my name is {FirstName} {LastName}, I am from RIO Education';
        String expectedResult = 'Hallo, my name is TestFirstName TestLastName, I am from RIO Education';

        Contact contact = new Contact(
            FirstName = 'TestFirstName',
            LastName = 'TestLastName'
        );
        
        System.Assert.areEqual(expectedResult, REDU_StringMerge_UTIL.mergeValues(contact, null, mergeStringPattern, null));

        Test.stopTest();
        
    }

    /**
     * @description Test merge value performance without merge field map
     */
    @IsTest
    static void testSobjectMergeValuesPerformanceTestWithoutMergeFieldMap(){
        
        Test.startTest();
        
        String mergeStringPattern = 'Hallo, my name is {FirstName} {LastName}, I am from RIO Education';
        String expectedResult = 'Hallo, my name is TestFirstName TestLastName';

        Contact contact = new Contact(
            FirstName = 'TestFirstName',
            LastName = 'TestLastName'
        );
        
        Integer startCpu = Limits.getCpuTime();
        for (Integer i = 0; i < 1000; i ++) {
            System.Assert.areEqual(expectedResult, REDU_StringMerge_UTIL.mergeValues(contact, null, mergeStringPattern, 44));
        }

        Integer endCpu = Limits.getCpuTime();
        Integer cpuUsage = endCpu - startCpu;
        System.Assert.isTrue(cpuUsage < 1000, 'The Apex CPU time consumed is too much: ' + cpuUsage);

        Test.stopTest();
        
    }

    /**
     * @description Test merge value performance with merge field map
     */
    @IsTest
    static void testSobjectMergeValuesPerformanceTestWithMergeFieldMap(){
        
        Test.startTest();
        
        String mergeStringPattern = 'Hallo, my name is {FirstName} {LastName}, I am from RIO Education';
        String expectedResult = 'Hallo, my name is TestFirstName TestLastName';

        Map<String, String> mergeFields = new Map<String, String>();
        mergeFields.put('{FirstName}', 'FirstName');
        mergeFields.put('{LastName}', 'LastName');

        Contact contact = new Contact(
            FirstName = 'TestFirstName',
            LastName = 'TestLastName'
        );
        
        Integer startCpu = Limits.getCpuTime();
        for (Integer i = 0; i < 1000; i ++) {
            System.Assert.areEqual(expectedResult, REDU_StringMerge_UTIL.mergeValues(contact, mergeFields, mergeStringPattern, 44));
        }

        Integer endCpu = Limits.getCpuTime();
        Integer cpuUsage = endCpu - startCpu;
        System.Assert.isTrue(cpuUsage < 500, 'The Apex CPU time consumed is too much: ' + cpuUsage);

        Test.stopTest();
        
    }
}