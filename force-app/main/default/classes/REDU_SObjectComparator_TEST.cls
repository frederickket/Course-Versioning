/**
 * @author      WDCi (Lean)
 * @date        Dec 2023
 * @group       Test
 * @description Test class for REDU_SObjectComparator
 * @changehistory
 * ISS-001591 22-12-2023 Lean - generic comparator for sobject
 * ISS-002395 26-05-2025 Lean - enhanced to support sorting of multiple fields
 * ISS-002733 28-01-2026 Lean - enhanced to support string field name sorting
 */
@IsTest
public inherited sharing class REDU_SObjectComparator_TEST {

    /**
     * @description Test string asc nulls first
     */
    @IsTest
    static void testStringSortingAscNullsFirst(){
        
        Test.startTest();
        
        List<reduivy__Study_Offering__c> toSort = new List<reduivy__Study_Offering__c>();
        toSort.add(new reduivy__Study_Offering__c(Name = 'Test1'));
        toSort.add(null);
        toSort.add(new reduivy__Study_Offering__c(Name = 'Test3'));
        toSort.add(new reduivy__Study_Offering__c(Name = null));
        toSort.add(new reduivy__Study_Offering__c(Name = 'Test2'));

        List<REDU_SObjectComparator.SortCriterion> criteria = new List<REDU_SObjectComparator.SortCriterion>{
            new REDU_SObjectComparator.SortCriterion(reduivy__Study_Offering__c.Name, REDU_SObjectComparator.SortOrder.Ascend, REDU_SObjectComparator.NullOrder.NullsFirst)
        };
        
        toSort.sort(new REDU_SObjectComparator(criteria));

        System.debug(JSON.serialize(toSort));
        // System.Assert.areEqual('expected', JSOn.serialize(toSort));

        System.Assert.isNull(toSort.get(0));
        System.Assert.areEqual(null, toSort.get(1).Name);
        System.Assert.areEqual('Test1', toSort.get(2).Name);
        System.Assert.areEqual('Test2', toSort.get(3).Name);
        System.Assert.areEqual('Test3', toSort.get(4).Name);
        
        

        Test.stopTest();
        
    }

    /**
     * @description Test string asc nulls last
     */
    @IsTest
    static void testStringSortingAscNullsLast(){
        
        Test.startTest();
        
        List<reduivy__Study_Offering__c> toSort = new List<reduivy__Study_Offering__c>();
        toSort.add(new reduivy__Study_Offering__c(Name = 'Test1'));
        toSort.add(null);
        toSort.add(new reduivy__Study_Offering__c(Name = 'Test3'));
        toSort.add(new reduivy__Study_Offering__c(Name = null));
        toSort.add(new reduivy__Study_Offering__c(Name = 'Test2'));

        List<REDU_SObjectComparator.SortCriterion> criteria = new List<REDU_SObjectComparator.SortCriterion>{
            new REDU_SObjectComparator.SortCriterion(reduivy__Study_Offering__c.Name, REDU_SObjectComparator.SortOrder.Ascend, REDU_SObjectComparator.NullOrder.NullsLast)
        };
        
        toSort.sort(new REDU_SObjectComparator(criteria));

        System.debug(JSON.serialize(toSort));
        // System.Assert.areEqual('expected', JSOn.serialize(toSort));

        System.Assert.areEqual('Test1', toSort.get(0).Name);
        System.Assert.areEqual('Test2', toSort.get(1).Name);
        System.Assert.areEqual('Test3', toSort.get(2).Name);
        System.Assert.areEqual(null, toSort.get(3).Name);
        System.Assert.isNull(toSort.get(4));

        Test.stopTest();
        
    }

    /**
     * @description Test string desc nulls first
     */
    @IsTest
    static void testStringSortingDescNullsFirst(){
        
        Test.startTest();
        
        List<reduivy__Study_Offering__c> toSort = new List<reduivy__Study_Offering__c>();
        toSort.add(new reduivy__Study_Offering__c(Name = 'Test1'));
        toSort.add(null);
        toSort.add(new reduivy__Study_Offering__c(Name = 'Test3'));
        toSort.add(new reduivy__Study_Offering__c(Name = null));
        toSort.add(new reduivy__Study_Offering__c(Name = 'Test2'));

        List<REDU_SObjectComparator.SortCriterion> criteria = new List<REDU_SObjectComparator.SortCriterion>{
            new REDU_SObjectComparator.SortCriterion(reduivy__Study_Offering__c.Name, REDU_SObjectComparator.SortOrder.Descend, REDU_SObjectComparator.NullOrder.NullsFirst)
        };
        
        toSort.sort(new REDU_SObjectComparator(criteria));

        System.debug(JSON.serialize(toSort));
        // System.Assert.areEqual('expected', JSOn.serialize(toSort));

        System.Assert.isNull(toSort.get(0));
        System.Assert.areEqual(null, toSort.get(1).Name);
        System.Assert.areEqual('Test3', toSort.get(2).Name);
        System.Assert.areEqual('Test2', toSort.get(3).Name);
        System.Assert.areEqual('Test1', toSort.get(4).Name);
        
        

        Test.stopTest();
        
    }

    /**
     * @description Test string desc nulls last
     */
    @IsTest
    static void testStringSortingDescNullsLast(){
        
        Test.startTest();
        
        List<reduivy__Study_Offering__c> toSort = new List<reduivy__Study_Offering__c>();
        toSort.add(new reduivy__Study_Offering__c(Name = 'Test1'));
        toSort.add(null);
        toSort.add(new reduivy__Study_Offering__c(Name = 'Test3'));
        toSort.add(new reduivy__Study_Offering__c(Name = null));
        toSort.add(new reduivy__Study_Offering__c(Name = 'Test2'));

        List<REDU_SObjectComparator.SortCriterion> criteria = new List<REDU_SObjectComparator.SortCriterion>{
            new REDU_SObjectComparator.SortCriterion(reduivy__Study_Offering__c.Name, REDU_SObjectComparator.SortOrder.Descend, REDU_SObjectComparator.NullOrder.NullsLast)
        };
        
        toSort.sort(new REDU_SObjectComparator(criteria));

        System.debug(JSON.serialize(toSort));
        // System.Assert.areEqual('expected', JSOn.serialize(toSort));

        System.Assert.areEqual('Test3', toSort.get(0).Name);
        System.Assert.areEqual('Test2', toSort.get(1).Name);
        System.Assert.areEqual('Test1', toSort.get(2).Name);
        System.Assert.areEqual(null, toSort.get(3).Name);
        System.Assert.isNull(toSort.get(4));

        Test.stopTest();
        
    }

    /**
     * @description Test two fields asc nulls first
     */
    @IsTest
    static void testTwoFieldsSortingAscNullsFirst(){
        
        Test.startTest();
        
        List<reduivy__Study_Offering__c> toSort = new List<reduivy__Study_Offering__c>();
        toSort.add(new reduivy__Study_Offering__c(Name = 'Test1', reduivy__Description__c = 'Test1_1'));
        toSort.add(null);
        toSort.add(new reduivy__Study_Offering__c(Name = 'Test3', reduivy__Description__c = 'Test3_1'));
        toSort.add(new reduivy__Study_Offering__c(Name = null, reduivy__Description__c = 'null_2'));
        toSort.add(new reduivy__Study_Offering__c(Name = null, reduivy__Description__c = 'null_1'));
        toSort.add(new reduivy__Study_Offering__c(Name = null, reduivy__Description__c = null));
        toSort.add(new reduivy__Study_Offering__c(Name = 'Test2', reduivy__Description__c = 'Test2_2'));
        toSort.add(new reduivy__Study_Offering__c(Name = 'Test2', reduivy__Description__c = 'Test2_1'));
        toSort.add(new reduivy__Study_Offering__c(Name = 'Test2', reduivy__Description__c = null));
        toSort.add(new reduivy__Study_Offering__c(Name = 'Test1', reduivy__Description__c = 'Test1_2'));
        toSort.add(new reduivy__Study_Offering__c(Name = 'Test1', reduivy__Description__c = 'Test1_3'));
        toSort.add(new reduivy__Study_Offering__c(Name = 'Test1', reduivy__Description__c = null));

        List<REDU_SObjectComparator.SortCriterion> criteria = new List<REDU_SObjectComparator.SortCriterion>{
            new REDU_SObjectComparator.SortCriterion(reduivy__Study_Offering__c.Name, REDU_SObjectComparator.SortOrder.Ascend, REDU_SObjectComparator.NullOrder.NullsFirst),
            new REDU_SObjectComparator.SortCriterion(reduivy__Study_Offering__c.reduivy__Description__c, REDU_SObjectComparator.SortOrder.Ascend, REDU_SObjectComparator.NullOrder.NullsFirst)
        };
        
        toSort.sort(new REDU_SObjectComparator(criteria));

        System.debug(JSON.serialize(toSort));
        // System.Assert.areEqual('expected', JSOn.serialize(toSort));
        
        System.Assert.isNull(toSort.get(0));

        System.Assert.areEqual(null, toSort.get(1).Name);
        System.Assert.areEqual(null, toSort.get(1).reduivy__Description__c);

        System.Assert.areEqual(null, toSort.get(2).Name);
        System.Assert.areEqual('null_1', toSort.get(2).reduivy__Description__c);

        System.Assert.areEqual(null, toSort.get(3).Name);
        System.Assert.areEqual('null_2', toSort.get(3).reduivy__Description__c);

        System.Assert.areEqual('Test1', toSort.get(4).Name);
        System.Assert.areEqual(null, toSort.get(4).reduivy__Description__c);

        System.Assert.areEqual('Test1', toSort.get(5).Name);
        System.Assert.areEqual('Test1_1', toSort.get(5).reduivy__Description__c);

        System.Assert.areEqual('Test1', toSort.get(6).Name);
        System.Assert.areEqual('Test1_2', toSort.get(6).reduivy__Description__c);

        System.Assert.areEqual('Test1', toSort.get(7).Name);
        System.Assert.areEqual('Test1_3', toSort.get(7).reduivy__Description__c);

        System.Assert.areEqual('Test2', toSort.get(8).Name);
        System.Assert.areEqual(null, toSort.get(8).reduivy__Description__c);

        System.Assert.areEqual('Test2', toSort.get(9).Name);
        System.Assert.areEqual('Test2_1', toSort.get(9).reduivy__Description__c);

        System.Assert.areEqual('Test2', toSort.get(10).Name);
        System.Assert.areEqual('Test2_2', toSort.get(10).reduivy__Description__c);

        System.Assert.areEqual('Test3', toSort.get(11).Name);
        System.Assert.areEqual('Test3_1', toSort.get(11).reduivy__Description__c);

        Test.stopTest();
        
    }

    /**
     * @description Test two fields asc nulls last
     */
    @IsTest
    static void testTwoFieldsSortingAscNullsLast(){
        
        Test.startTest();
        
        List<reduivy__Study_Offering__c> toSort = new List<reduivy__Study_Offering__c>();
        toSort.add(new reduivy__Study_Offering__c(Name = 'Test1', reduivy__Description__c = 'Test1_1'));
        toSort.add(null);
        toSort.add(new reduivy__Study_Offering__c(Name = 'Test3', reduivy__Description__c = 'Test3_1'));
        toSort.add(new reduivy__Study_Offering__c(Name = null, reduivy__Description__c = 'null_2'));
        toSort.add(new reduivy__Study_Offering__c(Name = null, reduivy__Description__c = 'null_1'));
        toSort.add(new reduivy__Study_Offering__c(Name = null, reduivy__Description__c = null));
        toSort.add(new reduivy__Study_Offering__c(Name = 'Test2', reduivy__Description__c = 'Test2_2'));
        toSort.add(new reduivy__Study_Offering__c(Name = 'Test2', reduivy__Description__c = 'Test2_1'));
        toSort.add(new reduivy__Study_Offering__c(Name = 'Test2', reduivy__Description__c = null));
        toSort.add(new reduivy__Study_Offering__c(Name = 'Test1', reduivy__Description__c = 'Test1_2'));
        toSort.add(new reduivy__Study_Offering__c(Name = 'Test1', reduivy__Description__c = 'Test1_3'));
        toSort.add(new reduivy__Study_Offering__c(Name = 'Test1', reduivy__Description__c = null));

        List<REDU_SObjectComparator.SortCriterion> criteria = new List<REDU_SObjectComparator.SortCriterion>{
            new REDU_SObjectComparator.SortCriterion(reduivy__Study_Offering__c.Name, REDU_SObjectComparator.SortOrder.Ascend, REDU_SObjectComparator.NullOrder.NullsLast),
            new REDU_SObjectComparator.SortCriterion(reduivy__Study_Offering__c.reduivy__Description__c, REDU_SObjectComparator.SortOrder.Ascend, REDU_SObjectComparator.NullOrder.NullsLast)
        };
        
        toSort.sort(new REDU_SObjectComparator(criteria));

        System.debug(JSON.serialize(toSort));
        // System.Assert.areEqual('expected', JSOn.serialize(toSort));

        System.Assert.areEqual('Test1', toSort.get(0).Name);
        System.Assert.areEqual('Test1_1', toSort.get(0).reduivy__Description__c);

        System.Assert.areEqual('Test1', toSort.get(1).Name);
        System.Assert.areEqual('Test1_2', toSort.get(1).reduivy__Description__c);

        System.Assert.areEqual('Test1', toSort.get(2).Name);
        System.Assert.areEqual('Test1_3', toSort.get(2).reduivy__Description__c);

        System.Assert.areEqual('Test1', toSort.get(3).Name);
        System.Assert.areEqual(null, toSort.get(3).reduivy__Description__c);

        System.Assert.areEqual('Test2', toSort.get(4).Name);
        System.Assert.areEqual('Test2_1', toSort.get(4).reduivy__Description__c);

        System.Assert.areEqual('Test2', toSort.get(5).Name);
        System.Assert.areEqual('Test2_2', toSort.get(5).reduivy__Description__c);

        System.Assert.areEqual('Test2', toSort.get(6).Name);
        System.Assert.areEqual(null, toSort.get(6).reduivy__Description__c);

        System.Assert.areEqual('Test3', toSort.get(7).Name);
        System.Assert.areEqual('Test3_1', toSort.get(7).reduivy__Description__c);

        System.Assert.areEqual(null, toSort.get(8).Name);
        System.Assert.areEqual('null_1', toSort.get(8).reduivy__Description__c);

        System.Assert.areEqual(null, toSort.get(9).Name);
        System.Assert.areEqual('null_2', toSort.get(9).reduivy__Description__c);

        System.Assert.areEqual(null, toSort.get(10).Name);
        System.Assert.areEqual(null, toSort.get(10).reduivy__Description__c);

        System.Assert.isNull(toSort.get(11));

        Test.stopTest();
        
    }

    /**
     * @description Test two fields desc nulls first
     */
    @IsTest
    static void testTwoFieldsSortingDescNullsFirst(){
        
        Test.startTest();
        
        List<reduivy__Study_Offering__c> toSort = new List<reduivy__Study_Offering__c>();
        toSort.add(new reduivy__Study_Offering__c(Name = 'Test1', reduivy__Description__c = 'Test1_1'));
        toSort.add(null);
        toSort.add(new reduivy__Study_Offering__c(Name = 'Test3', reduivy__Description__c = 'Test3_1'));
        toSort.add(new reduivy__Study_Offering__c(Name = null, reduivy__Description__c = 'null_2'));
        toSort.add(new reduivy__Study_Offering__c(Name = null, reduivy__Description__c = 'null_1'));
        toSort.add(new reduivy__Study_Offering__c(Name = null, reduivy__Description__c = null));
        toSort.add(new reduivy__Study_Offering__c(Name = 'Test2', reduivy__Description__c = 'Test2_2'));
        toSort.add(new reduivy__Study_Offering__c(Name = 'Test2', reduivy__Description__c = 'Test2_1'));
        toSort.add(new reduivy__Study_Offering__c(Name = 'Test2', reduivy__Description__c = null));
        toSort.add(new reduivy__Study_Offering__c(Name = 'Test1', reduivy__Description__c = 'Test1_2'));
        toSort.add(new reduivy__Study_Offering__c(Name = 'Test1', reduivy__Description__c = 'Test1_3'));
        toSort.add(new reduivy__Study_Offering__c(Name = 'Test1', reduivy__Description__c = null));

        List<REDU_SObjectComparator.SortCriterion> criteria = new List<REDU_SObjectComparator.SortCriterion>{
            new REDU_SObjectComparator.SortCriterion(reduivy__Study_Offering__c.Name, REDU_SObjectComparator.SortOrder.Descend, REDU_SObjectComparator.NullOrder.NullsFirst),
            new REDU_SObjectComparator.SortCriterion(reduivy__Study_Offering__c.reduivy__Description__c, REDU_SObjectComparator.SortOrder.Descend, REDU_SObjectComparator.NullOrder.NullsFirst)
        };
        
        toSort.sort(new REDU_SObjectComparator(criteria));

        System.debug(JSON.serialize(toSort));
        // System.Assert.areEqual('expected', JSOn.serialize(toSort));
        
        System.Assert.isNull(toSort.get(0));

        System.Assert.areEqual(null, toSort.get(1).Name);
        System.Assert.areEqual(null, toSort.get(1).reduivy__Description__c);

        System.Assert.areEqual(null, toSort.get(2).Name);
        System.Assert.areEqual('null_2', toSort.get(2).reduivy__Description__c);

        System.Assert.areEqual(null, toSort.get(3).Name);
        System.Assert.areEqual('null_1', toSort.get(3).reduivy__Description__c);
        
        System.Assert.areEqual('Test3', toSort.get(4).Name);
        System.Assert.areEqual('Test3_1', toSort.get(4).reduivy__Description__c);
        
        System.Assert.areEqual('Test2', toSort.get(5).Name);
        System.Assert.areEqual(null, toSort.get(5).reduivy__Description__c);
        
        System.Assert.areEqual('Test2', toSort.get(6).Name);
        System.Assert.areEqual('Test2_2', toSort.get(6).reduivy__Description__c);

        System.Assert.areEqual('Test2', toSort.get(7).Name);
        System.Assert.areEqual('Test2_1', toSort.get(7).reduivy__Description__c);

        System.Assert.areEqual('Test1', toSort.get(8).Name);
        System.Assert.areEqual(null, toSort.get(8).reduivy__Description__c);
        
        System.Assert.areEqual('Test1', toSort.get(9).Name);
        System.Assert.areEqual('Test1_3', toSort.get(9).reduivy__Description__c);
        
        System.Assert.areEqual('Test1', toSort.get(10).Name);
        System.Assert.areEqual('Test1_2', toSort.get(10).reduivy__Description__c);
        
        System.Assert.areEqual('Test1', toSort.get(11).Name);
        System.Assert.areEqual('Test1_1', toSort.get(11).reduivy__Description__c);

        Test.stopTest();
        
    }

    /**
     * @description Test two fields desc nulls last
     */
    @IsTest
    static void testTwoFieldsSortingDescNullsLast(){
        
        Test.startTest();
        
        List<reduivy__Study_Offering__c> toSort = new List<reduivy__Study_Offering__c>();
        toSort.add(new reduivy__Study_Offering__c(Name = 'Test1', reduivy__Description__c = 'Test1_1'));
        toSort.add(null);
        toSort.add(new reduivy__Study_Offering__c(Name = 'Test3', reduivy__Description__c = 'Test3_1'));
        toSort.add(new reduivy__Study_Offering__c(Name = null, reduivy__Description__c = 'null_2'));
        toSort.add(new reduivy__Study_Offering__c(Name = null, reduivy__Description__c = 'null_1'));
        toSort.add(new reduivy__Study_Offering__c(Name = null, reduivy__Description__c = null));
        toSort.add(new reduivy__Study_Offering__c(Name = 'Test2', reduivy__Description__c = 'Test2_2'));
        toSort.add(new reduivy__Study_Offering__c(Name = 'Test2', reduivy__Description__c = 'Test2_1'));
        toSort.add(new reduivy__Study_Offering__c(Name = 'Test2', reduivy__Description__c = null));
        toSort.add(new reduivy__Study_Offering__c(Name = 'Test1', reduivy__Description__c = 'Test1_2'));
        toSort.add(new reduivy__Study_Offering__c(Name = 'Test1', reduivy__Description__c = 'Test1_3'));
        toSort.add(new reduivy__Study_Offering__c(Name = 'Test1', reduivy__Description__c = null));

        List<REDU_SObjectComparator.SortCriterion> criteria = new List<REDU_SObjectComparator.SortCriterion>{
            new REDU_SObjectComparator.SortCriterion(reduivy__Study_Offering__c.Name, REDU_SObjectComparator.SortOrder.Descend, REDU_SObjectComparator.NullOrder.NullsLast),
            new REDU_SObjectComparator.SortCriterion(reduivy__Study_Offering__c.reduivy__Description__c, REDU_SObjectComparator.SortOrder.Descend, REDU_SObjectComparator.NullOrder.NullsLast)
        };
        
        toSort.sort(new REDU_SObjectComparator(criteria));

        System.debug(JSON.serialize(toSort));
        // System.Assert.areEqual('expected', JSOn.serialize(toSort));
        
        System.Assert.areEqual('Test3', toSort.get(0).Name);
        System.Assert.areEqual('Test3_1', toSort.get(0).reduivy__Description__c);
        
        System.Assert.areEqual('Test2', toSort.get(1).Name);
        System.Assert.areEqual('Test2_2', toSort.get(1).reduivy__Description__c);
        
        System.Assert.areEqual('Test2', toSort.get(2).Name);
        System.Assert.areEqual('Test2_1', toSort.get(2).reduivy__Description__c);

        System.Assert.areEqual('Test2', toSort.get(3).Name);
        System.Assert.areEqual(null, toSort.get(3).reduivy__Description__c);
        
        System.Assert.areEqual('Test1', toSort.get(4).Name);
        System.Assert.areEqual('Test1_3', toSort.get(4).reduivy__Description__c);
        
        System.Assert.areEqual('Test1', toSort.get(5).Name);
        System.Assert.areEqual('Test1_2', toSort.get(5).reduivy__Description__c);

        System.Assert.areEqual('Test1', toSort.get(6).Name);
        System.Assert.areEqual('Test1_1', toSort.get(6).reduivy__Description__c);

        System.Assert.areEqual('Test1', toSort.get(7).Name);
        System.Assert.areEqual(null, toSort.get(7).reduivy__Description__c);
        
        System.Assert.areEqual(null, toSort.get(8).Name);
        System.Assert.areEqual('null_2', toSort.get(8).reduivy__Description__c);

        System.Assert.areEqual(null, toSort.get(9).Name);
        System.Assert.areEqual('null_1', toSort.get(9).reduivy__Description__c);

        System.Assert.areEqual(null, toSort.get(10).Name);
        System.Assert.areEqual(null, toSort.get(10).reduivy__Description__c);

        System.Assert.isNull(toSort.get(11));

        Test.stopTest();
        
    }

    /**
     * @description Test ascii string asc nulls first
     */
    @IsTest
    static void testAsciiStringSortingAscNullsLast(){
        
        Test.startTest();
        
        List<reduivy__Study_Offering__c> toSort = new List<reduivy__Study_Offering__c>();
        toSort.add(new reduivy__Study_Offering__c(Name = 'test1'));
        toSort.add(null);
        toSort.add(new reduivy__Study_Offering__c(Name = 'test2'));
        toSort.add(new reduivy__Study_Offering__c(Name = null));
        toSort.add(new reduivy__Study_Offering__c(Name = 'Test2'));

        List<REDU_SObjectComparator.SortCriterion> criteria = new List<REDU_SObjectComparator.SortCriterion>{
            new REDU_SObjectComparator.SortCriterion(reduivy__Study_Offering__c.Name, REDU_SObjectComparator.SortOrder.Ascend, REDU_SObjectComparator.NullOrder.NullsLast)
        };
        
        toSort.sort(new REDU_SObjectComparator(criteria));

        System.debug(JSON.serialize(toSort));
        // System.Assert.areEqual('expected', JSOn.serialize(toSort));

        System.Assert.areEqual('test1', toSort.get(0).Name);
        System.Assert.areEqual('test2', toSort.get(1).Name);
        System.Assert.areEqual('Test2', toSort.get(2).Name);
        System.Assert.areEqual(null, toSort.get(3).Name);
        System.Assert.isNull(toSort.get(4));

        Test.stopTest();
        
    }

    /**
     * @description Test ascii string asc nulls last
     */
    @IsTest
    static void testAsciiStringSortingDescNullsLast(){
        
        Test.startTest();
        
        List<reduivy__Study_Offering__c> toSort = new List<reduivy__Study_Offering__c>();
        toSort.add(new reduivy__Study_Offering__c(Name = 'test1'));
        toSort.add(null);
        toSort.add(new reduivy__Study_Offering__c(Name = 'test2'));
        toSort.add(new reduivy__Study_Offering__c(Name = null));
        toSort.add(new reduivy__Study_Offering__c(Name = 'Test2'));

        List<REDU_SObjectComparator.SortCriterion> criteria = new List<REDU_SObjectComparator.SortCriterion>{
            new REDU_SObjectComparator.SortCriterion(reduivy__Study_Offering__c.Name, REDU_SObjectComparator.SortOrder.Descend, REDU_SObjectComparator.NullOrder.NullsLast)
        };
        
        toSort.sort(new REDU_SObjectComparator(criteria));

        System.debug(JSON.serialize(toSort));
        // System.Assert.areEqual('expected', JSOn.serialize(toSort));

        System.Assert.areEqual('test2', toSort.get(0).Name);
        System.Assert.areEqual('Test2', toSort.get(1).Name);
        System.Assert.areEqual('test1', toSort.get(2).Name);
        System.Assert.areEqual(null, toSort.get(3).Name);
        System.Assert.isNull(toSort.get(4));

        Test.stopTest();
        
    }

    /**
     * @description Test rich text area asc nulls first
     */
    @IsTest
    static void testRichTextAreaSortingAscNullsFirst(){
        
        Test.startTest();
        
        List<reduivy__Study_Offering__c> toSort = new List<reduivy__Study_Offering__c>();
        toSort.add(new reduivy__Study_Offering__c(reduivy__About__c = 'Test1'));
        toSort.add(null);
        toSort.add(new reduivy__Study_Offering__c(reduivy__About__c = 'Test3'));
        toSort.add(new reduivy__Study_Offering__c(reduivy__About__c = null));
        toSort.add(new reduivy__Study_Offering__c(reduivy__About__c = 'Test2'));

        List<REDU_SObjectComparator.SortCriterion> criteria = new List<REDU_SObjectComparator.SortCriterion>{
            new REDU_SObjectComparator.SortCriterion(reduivy__Study_Offering__c.reduivy__About__c, REDU_SObjectComparator.SortOrder.Ascend, REDU_SObjectComparator.NullOrder.NullsFirst)
        };
        
        toSort.sort(new REDU_SObjectComparator(criteria));

        System.debug(JSON.serialize(toSort));
        // System.Assert.areEqual('expected', JSOn.serialize(toSort));

        System.Assert.isNull(toSort.get(0));
        System.Assert.areEqual(null, toSort.get(1).reduivy__About__c);
        System.Assert.areEqual('Test1', toSort.get(2).reduivy__About__c);
        System.Assert.areEqual('Test2', toSort.get(3).reduivy__About__c);
        System.Assert.areEqual('Test3', toSort.get(4).reduivy__About__c);

        Test.stopTest();
        
    }

    /**
     * @description Test rich text area asc nulls last
     */
    @IsTest
    static void testRichTextAreaSortingAscNullsLast(){
        
        Test.startTest();
        
        List<reduivy__Study_Offering__c> toSort = new List<reduivy__Study_Offering__c>();
        toSort.add(new reduivy__Study_Offering__c(reduivy__About__c = 'Test1'));
        toSort.add(null);
        toSort.add(new reduivy__Study_Offering__c(reduivy__About__c = 'Test3'));
        toSort.add(new reduivy__Study_Offering__c(reduivy__About__c = null));
        toSort.add(new reduivy__Study_Offering__c(reduivy__About__c = 'Test2'));

        List<REDU_SObjectComparator.SortCriterion> criteria = new List<REDU_SObjectComparator.SortCriterion>{
            new REDU_SObjectComparator.SortCriterion(reduivy__Study_Offering__c.reduivy__About__c, REDU_SObjectComparator.SortOrder.Ascend, REDU_SObjectComparator.NullOrder.NullsLast)
        };
        
        toSort.sort(new REDU_SObjectComparator(criteria));

        System.debug(JSON.serialize(toSort));
        // System.Assert.areEqual('expected', JSOn.serialize(toSort));

        System.Assert.areEqual('Test1', toSort.get(0).reduivy__About__c);
        System.Assert.areEqual('Test2', toSort.get(1).reduivy__About__c);
        System.Assert.areEqual('Test3', toSort.get(2).reduivy__About__c);
        System.Assert.areEqual(null, toSort.get(3).reduivy__About__c);
        System.Assert.isNull(toSort.get(4));

        Test.stopTest();
        
    }

    /**
     * @description Test rich text area desc nulls first
     */
    @IsTest
    static void testRichTextAreaSortingDescNullsFirst(){
        
        Test.startTest();
        
        List<reduivy__Study_Offering__c> toSort = new List<reduivy__Study_Offering__c>();
        toSort.add(new reduivy__Study_Offering__c(reduivy__About__c = 'Test1'));
        toSort.add(null);
        toSort.add(new reduivy__Study_Offering__c(reduivy__About__c = 'Test3'));
        toSort.add(new reduivy__Study_Offering__c(reduivy__About__c = null));
        toSort.add(new reduivy__Study_Offering__c(reduivy__About__c = 'Test2'));

        List<REDU_SObjectComparator.SortCriterion> criteria = new List<REDU_SObjectComparator.SortCriterion>{
            new REDU_SObjectComparator.SortCriterion(reduivy__Study_Offering__c.reduivy__About__c, REDU_SObjectComparator.SortOrder.Descend, REDU_SObjectComparator.NullOrder.NullsFirst)
        };
        
        toSort.sort(new REDU_SObjectComparator(criteria));

        System.debug(JSON.serialize(toSort));
        // System.Assert.areEqual('expected', JSOn.serialize(toSort));

        System.Assert.isNull(toSort.get(0));
        System.Assert.areEqual(null, toSort.get(1).reduivy__About__c);
        System.Assert.areEqual('Test3', toSort.get(2).reduivy__About__c);
        System.Assert.areEqual('Test2', toSort.get(3).reduivy__About__c);
        System.Assert.areEqual('Test1', toSort.get(4).reduivy__About__c);

        Test.stopTest();
        
    }

    /**
     * @description Test rich text area desc nulls last
     */
    @IsTest
    static void testRichTextAreaSortingDescNullsLast(){
        
        Test.startTest();
        
        List<reduivy__Study_Offering__c> toSort = new List<reduivy__Study_Offering__c>();
        toSort.add(new reduivy__Study_Offering__c(reduivy__About__c = 'Test1'));
        toSort.add(null);
        toSort.add(new reduivy__Study_Offering__c(reduivy__About__c = 'Test3'));
        toSort.add(new reduivy__Study_Offering__c(reduivy__About__c = null));
        toSort.add(new reduivy__Study_Offering__c(reduivy__About__c = 'Test2'));

        List<REDU_SObjectComparator.SortCriterion> criteria = new List<REDU_SObjectComparator.SortCriterion>{
            new REDU_SObjectComparator.SortCriterion(reduivy__Study_Offering__c.reduivy__About__c, REDU_SObjectComparator.SortOrder.Descend, REDU_SObjectComparator.NullOrder.NullsLast)
        };
        
        toSort.sort(new REDU_SObjectComparator(criteria));

        System.debug(JSON.serialize(toSort));
        // System.Assert.areEqual('expected', JSOn.serialize(toSort));

        System.Assert.areEqual('Test3', toSort.get(0).reduivy__About__c);
        System.Assert.areEqual('Test2', toSort.get(1).reduivy__About__c);
        System.Assert.areEqual('Test1', toSort.get(2).reduivy__About__c);
        System.Assert.areEqual(null, toSort.get(3).reduivy__About__c);
        System.Assert.isNull(toSort.get(4));

        Test.stopTest();
        
    }

    /**
     * @description Test long text area asc nulls first
     */
    @IsTest
    static void testLongTextAreaSortingAscNullsFirst(){
        
        Test.startTest();
        
        List<reduivy__Study_Offering__c> toSort = new List<reduivy__Study_Offering__c>();
        toSort.add(new reduivy__Study_Offering__c(reduivy__Banner_Image_URL__c = 'Test1'));
        toSort.add(null);
        toSort.add(new reduivy__Study_Offering__c(reduivy__Banner_Image_URL__c = 'Test3'));
        toSort.add(new reduivy__Study_Offering__c(reduivy__Banner_Image_URL__c = null));
        toSort.add(new reduivy__Study_Offering__c(reduivy__Banner_Image_URL__c = 'Test2'));

        List<REDU_SObjectComparator.SortCriterion> criteria = new List<REDU_SObjectComparator.SortCriterion>{
            new REDU_SObjectComparator.SortCriterion(reduivy__Study_Offering__c.reduivy__Banner_Image_URL__c, REDU_SObjectComparator.SortOrder.Ascend, REDU_SObjectComparator.NullOrder.NullsFirst)
        };
        
        toSort.sort(new REDU_SObjectComparator(criteria));

        System.debug(JSON.serialize(toSort));
        // System.Assert.areEqual('expected', JSOn.serialize(toSort));

        System.Assert.isNull(toSort.get(0));
        System.Assert.areEqual(null, toSort.get(1).reduivy__Banner_Image_URL__c);
        System.Assert.areEqual('Test1', toSort.get(2).reduivy__Banner_Image_URL__c);
        System.Assert.areEqual('Test2', toSort.get(3).reduivy__Banner_Image_URL__c);
        System.Assert.areEqual('Test3', toSort.get(4).reduivy__Banner_Image_URL__c);

        Test.stopTest();
        
    }

    /**
     * @description Test long text area asc nulls last
     */
    @IsTest
    static void testLongTextAreaSortingAscNullsLast(){
        
        Test.startTest();
        
        List<reduivy__Study_Offering__c> toSort = new List<reduivy__Study_Offering__c>();
        toSort.add(new reduivy__Study_Offering__c(reduivy__Banner_Image_URL__c = 'Test1'));
        toSort.add(null);
        toSort.add(new reduivy__Study_Offering__c(reduivy__Banner_Image_URL__c = 'Test3'));
        toSort.add(new reduivy__Study_Offering__c(reduivy__Banner_Image_URL__c = null));
        toSort.add(new reduivy__Study_Offering__c(reduivy__Banner_Image_URL__c = 'Test2'));

        List<REDU_SObjectComparator.SortCriterion> criteria = new List<REDU_SObjectComparator.SortCriterion>{
            new REDU_SObjectComparator.SortCriterion(reduivy__Study_Offering__c.reduivy__Banner_Image_URL__c, REDU_SObjectComparator.SortOrder.Ascend, REDU_SObjectComparator.NullOrder.NullsLast)
        };
        
        toSort.sort(new REDU_SObjectComparator(criteria));

        System.debug(JSON.serialize(toSort));
        // System.Assert.areEqual('expected', JSOn.serialize(toSort));

        System.Assert.areEqual('Test1', toSort.get(0).reduivy__Banner_Image_URL__c);
        System.Assert.areEqual('Test2', toSort.get(1).reduivy__Banner_Image_URL__c);
        System.Assert.areEqual('Test3', toSort.get(2).reduivy__Banner_Image_URL__c);
        System.Assert.areEqual(null, toSort.get(3).reduivy__Banner_Image_URL__c);
        System.Assert.isNull(toSort.get(4));

        Test.stopTest();
        
    }

    /**
     * @description Test long text area desc nulls first
     */
    @IsTest
    static void testLongTextAreaSortingDescNullsFirst(){
        
        Test.startTest();
        
        List<reduivy__Study_Offering__c> toSort = new List<reduivy__Study_Offering__c>();
        toSort.add(new reduivy__Study_Offering__c(reduivy__Banner_Image_URL__c = 'Test1'));
        toSort.add(null);
        toSort.add(new reduivy__Study_Offering__c(reduivy__Banner_Image_URL__c = 'Test3'));
        toSort.add(new reduivy__Study_Offering__c(reduivy__Banner_Image_URL__c = null));
        toSort.add(new reduivy__Study_Offering__c(reduivy__Banner_Image_URL__c = 'Test2'));

        List<REDU_SObjectComparator.SortCriterion> criteria = new List<REDU_SObjectComparator.SortCriterion>{
            new REDU_SObjectComparator.SortCriterion(reduivy__Study_Offering__c.reduivy__Banner_Image_URL__c, REDU_SObjectComparator.SortOrder.Descend, REDU_SObjectComparator.NullOrder.NullsFirst)
        };
        
        toSort.sort(new REDU_SObjectComparator(criteria));

        System.debug(JSON.serialize(toSort));
        // System.Assert.areEqual('expected', JSOn.serialize(toSort));

        System.Assert.isNull(toSort.get(0));
        System.Assert.areEqual(null, toSort.get(1).reduivy__Banner_Image_URL__c);
        System.Assert.areEqual('Test3', toSort.get(2).reduivy__Banner_Image_URL__c);
        System.Assert.areEqual('Test2', toSort.get(3).reduivy__Banner_Image_URL__c);
        System.Assert.areEqual('Test1', toSort.get(4).reduivy__Banner_Image_URL__c);

        Test.stopTest();
        
    }

    /**
     * @description Test long text area desc nulls last
     */
    @IsTest
    static void testLongTextAreaSortingDescNullsLast(){
        
        Test.startTest();
        
        List<reduivy__Study_Offering__c> toSort = new List<reduivy__Study_Offering__c>();
        toSort.add(new reduivy__Study_Offering__c(reduivy__Banner_Image_URL__c = 'Test1'));
        toSort.add(null);
        toSort.add(new reduivy__Study_Offering__c(reduivy__Banner_Image_URL__c = 'Test3'));
        toSort.add(new reduivy__Study_Offering__c(reduivy__Banner_Image_URL__c = null));
        toSort.add(new reduivy__Study_Offering__c(reduivy__Banner_Image_URL__c = 'Test2'));

        List<REDU_SObjectComparator.SortCriterion> criteria = new List<REDU_SObjectComparator.SortCriterion>{
            new REDU_SObjectComparator.SortCriterion(reduivy__Study_Offering__c.reduivy__Banner_Image_URL__c, REDU_SObjectComparator.SortOrder.Descend, REDU_SObjectComparator.NullOrder.NullsLast)
        };
        
        toSort.sort(new REDU_SObjectComparator(criteria));

        System.debug(JSON.serialize(toSort));
        // System.Assert.areEqual('expected', JSOn.serialize(toSort));

        System.Assert.areEqual('Test3', toSort.get(0).reduivy__Banner_Image_URL__c);
        System.Assert.areEqual('Test2', toSort.get(1).reduivy__Banner_Image_URL__c);
        System.Assert.areEqual('Test1', toSort.get(2).reduivy__Banner_Image_URL__c);
        System.Assert.areEqual(null, toSort.get(3).reduivy__Banner_Image_URL__c);
        System.Assert.isNull(toSort.get(4));

        Test.stopTest();
        
    }

    /**
     * @description Test decimal asc nulls first
     */
    @IsTest
    static void testDecimalSortingAscNullsFirst(){
        
        Test.startTest();
        
        List<reduivy__Study_Offering__c> toSort = new List<reduivy__Study_Offering__c>();
        toSort.add(new reduivy__Study_Offering__c(reduivy__Capacity__c = 1));
        toSort.add(null);
        toSort.add(new reduivy__Study_Offering__c(reduivy__Capacity__c = 3));
        toSort.add(new reduivy__Study_Offering__c(reduivy__Capacity__c = null));
        toSort.add(new reduivy__Study_Offering__c(reduivy__Capacity__c = 2));

        List<REDU_SObjectComparator.SortCriterion> criteria = new List<REDU_SObjectComparator.SortCriterion>{
            new REDU_SObjectComparator.SortCriterion(reduivy__Study_Offering__c.reduivy__Capacity__c, REDU_SObjectComparator.SortOrder.Ascend, REDU_SObjectComparator.NullOrder.NullsFirst)
        };

        toSort.sort(new REDU_SObjectComparator(criteria));
        // System.Assert.areEqual('expected', JSOn.serialize(toSort));
        
        System.Assert.isNull(toSort.get(0));
        System.Assert.areEqual(null, toSort.get(1).reduivy__Capacity__c);
        System.Assert.areEqual(1, toSort.get(2).reduivy__Capacity__c);
        System.Assert.areEqual(2, toSort.get(3).reduivy__Capacity__c);
        System.Assert.areEqual(3, toSort.get(4).reduivy__Capacity__c);

        Test.stopTest();
        
    }

    /**
     * @description Test decimal asc nulls last
     */
    @IsTest
    static void testDecimalSortingAscNullsLast(){
        
        Test.startTest();
        
        List<reduivy__Study_Offering__c> toSort = new List<reduivy__Study_Offering__c>();
        toSort.add(new reduivy__Study_Offering__c(reduivy__Capacity__c = 1));
        toSort.add(null);
        toSort.add(new reduivy__Study_Offering__c(reduivy__Capacity__c = 3));
        toSort.add(new reduivy__Study_Offering__c(reduivy__Capacity__c = null));
        toSort.add(new reduivy__Study_Offering__c(reduivy__Capacity__c = 2));

        List<REDU_SObjectComparator.SortCriterion> criteria = new List<REDU_SObjectComparator.SortCriterion>{
            new REDU_SObjectComparator.SortCriterion(reduivy__Study_Offering__c.reduivy__Capacity__c, REDU_SObjectComparator.SortOrder.Ascend, REDU_SObjectComparator.NullOrder.NullsLast)
        };

        toSort.sort(new REDU_SObjectComparator(criteria));
        // System.Assert.areEqual('expected', JSOn.serialize(toSort));
        
        System.Assert.areEqual(1, toSort.get(0).reduivy__Capacity__c);
        System.Assert.areEqual(2, toSort.get(1).reduivy__Capacity__c);
        System.Assert.areEqual(3, toSort.get(2).reduivy__Capacity__c);
        System.Assert.areEqual(null, toSort.get(3).reduivy__Capacity__c);
        System.Assert.isNull(toSort.get(4));

        Test.stopTest();
        
    }

    /**
     * @description Test decimal desc nulls first
     */
    @IsTest
    static void testDecimalSortingDescNullsFirst(){
        
        Test.startTest();
        
        List<reduivy__Study_Offering__c> toSort = new List<reduivy__Study_Offering__c>();
        toSort.add(new reduivy__Study_Offering__c(reduivy__Capacity__c = 1));
        toSort.add(null);
        toSort.add(new reduivy__Study_Offering__c(reduivy__Capacity__c = 3));
        toSort.add(new reduivy__Study_Offering__c(reduivy__Capacity__c = null));
        toSort.add(new reduivy__Study_Offering__c(reduivy__Capacity__c = 2));

        List<REDU_SObjectComparator.SortCriterion> criteria = new List<REDU_SObjectComparator.SortCriterion>{
            new REDU_SObjectComparator.SortCriterion(reduivy__Study_Offering__c.reduivy__Capacity__c, REDU_SObjectComparator.SortOrder.Descend, REDU_SObjectComparator.NullOrder.NullsFirst)
        };

        toSort.sort(new REDU_SObjectComparator(criteria));
        // System.Assert.areEqual('expected', JSOn.serialize(toSort));
        
        System.Assert.isNull(toSort.get(0));
        System.Assert.areEqual(null, toSort.get(1).reduivy__Capacity__c);
        System.Assert.areEqual(3, toSort.get(2).reduivy__Capacity__c);
        System.Assert.areEqual(2, toSort.get(3).reduivy__Capacity__c);
        System.Assert.areEqual(1, toSort.get(4).reduivy__Capacity__c);

        Test.stopTest();
        
    }

    /**
     * @description Test decimal desc nulls last
     */
    @IsTest
    static void testDecimalSortingDescNullsLast(){
        
        Test.startTest();
        
        List<reduivy__Study_Offering__c> toSort = new List<reduivy__Study_Offering__c>();
        toSort.add(new reduivy__Study_Offering__c(reduivy__Capacity__c = 1));
        toSort.add(null);
        toSort.add(new reduivy__Study_Offering__c(reduivy__Capacity__c = 3));
        toSort.add(new reduivy__Study_Offering__c(reduivy__Capacity__c = null));
        toSort.add(new reduivy__Study_Offering__c(reduivy__Capacity__c = 2));

        List<REDU_SObjectComparator.SortCriterion> criteria = new List<REDU_SObjectComparator.SortCriterion>{
            new REDU_SObjectComparator.SortCriterion(reduivy__Study_Offering__c.reduivy__Capacity__c, REDU_SObjectComparator.SortOrder.Descend, REDU_SObjectComparator.NullOrder.NullsLast)
        };

        toSort.sort(new REDU_SObjectComparator(criteria));
        // System.Assert.areEqual('expected', JSOn.serialize(toSort));
        
        System.Assert.areEqual(3, toSort.get(0).reduivy__Capacity__c);
        System.Assert.areEqual(2, toSort.get(1).reduivy__Capacity__c);
        System.Assert.areEqual(1, toSort.get(2).reduivy__Capacity__c);
        System.Assert.areEqual(null, toSort.get(3).reduivy__Capacity__c);
        System.Assert.isNull(toSort.get(4));

        Test.stopTest();
        
    }

    /**
     * @description Test currency asc nulls first
     */
    @IsTest
    static void testCurrencySortingAscNullsFirst(){
        
        Test.startTest();
        
        List<reduivy__Study_Offering__c> toSort = new List<reduivy__Study_Offering__c>();
        toSort.add(new reduivy__Study_Offering__c(reduivy__Fee_Amount__c = 1));
        toSort.add(null);
        toSort.add(new reduivy__Study_Offering__c(reduivy__Fee_Amount__c = 3));
        toSort.add(new reduivy__Study_Offering__c(reduivy__Fee_Amount__c = null));
        toSort.add(new reduivy__Study_Offering__c(reduivy__Fee_Amount__c = 2));

        List<REDU_SObjectComparator.SortCriterion> criteria = new List<REDU_SObjectComparator.SortCriterion>{
            new REDU_SObjectComparator.SortCriterion(reduivy__Study_Offering__c.reduivy__Fee_Amount__c, REDU_SObjectComparator.SortOrder.Ascend, REDU_SObjectComparator.NullOrder.NullsFirst)
        };

        toSort.sort(new REDU_SObjectComparator(criteria));
        // System.Assert.areEqual('expected', JSOn.serialize(toSort));
        
        System.Assert.isNull(toSort.get(0));
        System.Assert.areEqual(null, toSort.get(1).reduivy__Fee_Amount__c);
        System.Assert.areEqual(1, toSort.get(2).reduivy__Fee_Amount__c);
        System.Assert.areEqual(2, toSort.get(3).reduivy__Fee_Amount__c);
        System.Assert.areEqual(3, toSort.get(4).reduivy__Fee_Amount__c);

        Test.stopTest();
        
    }

    /**
     * @description Test currency asc nulls last
     */
    @IsTest
    static void testCurrencySortingAscNullsLast(){
        
        Test.startTest();
        
        List<reduivy__Study_Offering__c> toSort = new List<reduivy__Study_Offering__c>();
        toSort.add(new reduivy__Study_Offering__c(reduivy__Fee_Amount__c = 1));
        toSort.add(null);
        toSort.add(new reduivy__Study_Offering__c(reduivy__Fee_Amount__c = 3));
        toSort.add(new reduivy__Study_Offering__c(reduivy__Fee_Amount__c = null));
        toSort.add(new reduivy__Study_Offering__c(reduivy__Fee_Amount__c = 2));

        List<REDU_SObjectComparator.SortCriterion> criteria = new List<REDU_SObjectComparator.SortCriterion>{
            new REDU_SObjectComparator.SortCriterion(reduivy__Study_Offering__c.reduivy__Fee_Amount__c, REDU_SObjectComparator.SortOrder.Ascend, REDU_SObjectComparator.NullOrder.NullsLast)
        };

        toSort.sort(new REDU_SObjectComparator(criteria));
        // System.Assert.areEqual('expected', JSOn.serialize(toSort));
        
        System.Assert.areEqual(1, toSort.get(0).reduivy__Fee_Amount__c);
        System.Assert.areEqual(2, toSort.get(1).reduivy__Fee_Amount__c);
        System.Assert.areEqual(3, toSort.get(2).reduivy__Fee_Amount__c);
        System.Assert.areEqual(null, toSort.get(3).reduivy__Fee_Amount__c);
        System.Assert.isNull(toSort.get(4));

        Test.stopTest();
        
    }

    /**
     * @description Test currency desc nulls first
     */
    @IsTest
    static void testCurrencySortingDescNullsFirst(){
        
        Test.startTest();
        
        List<reduivy__Study_Offering__c> toSort = new List<reduivy__Study_Offering__c>();
        toSort.add(new reduivy__Study_Offering__c(reduivy__Fee_Amount__c = 1));
        toSort.add(null);
        toSort.add(new reduivy__Study_Offering__c(reduivy__Fee_Amount__c = 3));
        toSort.add(new reduivy__Study_Offering__c(reduivy__Fee_Amount__c = null));
        toSort.add(new reduivy__Study_Offering__c(reduivy__Fee_Amount__c = 2));

        List<REDU_SObjectComparator.SortCriterion> criteria = new List<REDU_SObjectComparator.SortCriterion>{
            new REDU_SObjectComparator.SortCriterion(reduivy__Study_Offering__c.reduivy__Fee_Amount__c, REDU_SObjectComparator.SortOrder.Descend, REDU_SObjectComparator.NullOrder.NullsFirst)
        };

        toSort.sort(new REDU_SObjectComparator(criteria));
        // System.Assert.areEqual('expected', JSOn.serialize(toSort));
        
        System.Assert.isNull(toSort.get(0));
        System.Assert.areEqual(null, toSort.get(1).reduivy__Fee_Amount__c);
        System.Assert.areEqual(3, toSort.get(2).reduivy__Fee_Amount__c);
        System.Assert.areEqual(2, toSort.get(3).reduivy__Fee_Amount__c);
        System.Assert.areEqual(1, toSort.get(4).reduivy__Fee_Amount__c);

        Test.stopTest();
        
    }

    /**
     * @description Test currency desc nulls last
     */
    @IsTest
    static void testCurrencySortingDescNullsLast(){
        
        Test.startTest();
        
        List<reduivy__Study_Offering__c> toSort = new List<reduivy__Study_Offering__c>();
        toSort.add(new reduivy__Study_Offering__c(reduivy__Fee_Amount__c = 1));
        toSort.add(null);
        toSort.add(new reduivy__Study_Offering__c(reduivy__Fee_Amount__c = 3));
        toSort.add(new reduivy__Study_Offering__c(reduivy__Fee_Amount__c = null));
        toSort.add(new reduivy__Study_Offering__c(reduivy__Fee_Amount__c = 2));

        List<REDU_SObjectComparator.SortCriterion> criteria = new List<REDU_SObjectComparator.SortCriterion>{
            new REDU_SObjectComparator.SortCriterion(reduivy__Study_Offering__c.reduivy__Fee_Amount__c, REDU_SObjectComparator.SortOrder.Descend, REDU_SObjectComparator.NullOrder.NullsLast)
        };

        toSort.sort(new REDU_SObjectComparator(criteria));
        // System.Assert.areEqual('expected', JSOn.serialize(toSort));
        
        System.Assert.areEqual(3, toSort.get(0).reduivy__Fee_Amount__c);
        System.Assert.areEqual(2, toSort.get(1).reduivy__Fee_Amount__c);
        System.Assert.areEqual(1, toSort.get(2).reduivy__Fee_Amount__c);
        System.Assert.areEqual(null, toSort.get(3).reduivy__Fee_Amount__c);
        System.Assert.isNull(toSort.get(4));

        Test.stopTest();
        
    }

    /**
     * @description Test date asc nulls last
     */
    @IsTest
    static void testDateSortingAscNullsFirst(){
        
        Test.startTest();
        
        Date testDate = System.today();

        List<reduivy__Study_Offering__c> toSort = new List<reduivy__Study_Offering__c>();
        toSort.add(new reduivy__Study_Offering__c(reduivy__Start_Date__c = testDate.addDays(1)));
        toSort.add(null);
        toSort.add(new reduivy__Study_Offering__c(reduivy__Start_Date__c = testDate.addDays(3)));
        toSort.add(new reduivy__Study_Offering__c(reduivy__Start_Date__c = null));
        toSort.add(new reduivy__Study_Offering__c(reduivy__Start_Date__c = testDate.addDays(2)));

        List<REDU_SObjectComparator.SortCriterion> criteria = new List<REDU_SObjectComparator.SortCriterion>{
            new REDU_SObjectComparator.SortCriterion(reduivy__Study_Offering__c.reduivy__Start_Date__c, REDU_SObjectComparator.SortOrder.Ascend, REDU_SObjectComparator.NullOrder.NullsFirst)
        };

        toSort.sort(new REDU_SObjectComparator(criteria));
        // System.Assert.areEqual('expected', JSOn.serialize(toSort));

        System.Assert.isNull(toSort.get(0));
        System.Assert.areEqual(null, toSort.get(1).reduivy__Start_Date__c);
        System.Assert.areEqual(testDate.addDays(1), toSort.get(2).reduivy__Start_Date__c);
        System.Assert.areEqual(testDate.addDays(2), toSort.get(3).reduivy__Start_Date__c);
        System.Assert.areEqual(testDate.addDays(3), toSort.get(4).reduivy__Start_Date__c);

        Test.stopTest();
        
    }

    /**
     * @description Test date asc nulls last
     */
    @IsTest
    static void testDateSortingAscNullsLast(){
        
        Test.startTest();
        
        Date testDate = System.today();

        List<reduivy__Study_Offering__c> toSort = new List<reduivy__Study_Offering__c>();
        toSort.add(new reduivy__Study_Offering__c(reduivy__Start_Date__c = testDate.addDays(1)));
        toSort.add(null);
        toSort.add(new reduivy__Study_Offering__c(reduivy__Start_Date__c = testDate.addDays(3)));
        toSort.add(new reduivy__Study_Offering__c(reduivy__Start_Date__c = null));
        toSort.add(new reduivy__Study_Offering__c(reduivy__Start_Date__c = testDate.addDays(2)));

        List<REDU_SObjectComparator.SortCriterion> criteria = new List<REDU_SObjectComparator.SortCriterion>{
            new REDU_SObjectComparator.SortCriterion(reduivy__Study_Offering__c.reduivy__Start_Date__c, REDU_SObjectComparator.SortOrder.Ascend, REDU_SObjectComparator.NullOrder.NullsLast)
        };

        toSort.sort(new REDU_SObjectComparator(criteria));
        // System.Assert.areEqual('expected', JSOn.serialize(toSort));

        System.Assert.areEqual(testDate.addDays(1), toSort.get(0).reduivy__Start_Date__c);
        System.Assert.areEqual(testDate.addDays(2), toSort.get(1).reduivy__Start_Date__c);
        System.Assert.areEqual(testDate.addDays(3), toSort.get(2).reduivy__Start_Date__c);
        System.Assert.areEqual(null, toSort.get(3).reduivy__Start_Date__c);
        System.Assert.isNull(toSort.get(4));

        Test.stopTest();
        
    }

    /**
     * @description Test date desc nulls last
     */
    @IsTest
    static void testDateSortingDescNullsFirst(){
        
        Test.startTest();
        
        Date testDate = System.today();

        List<reduivy__Study_Offering__c> toSort = new List<reduivy__Study_Offering__c>();
        toSort.add(new reduivy__Study_Offering__c(reduivy__Start_Date__c = testDate.addDays(1)));
        toSort.add(null);
        toSort.add(new reduivy__Study_Offering__c(reduivy__Start_Date__c = testDate.addDays(3)));
        toSort.add(new reduivy__Study_Offering__c(reduivy__Start_Date__c = null));
        toSort.add(new reduivy__Study_Offering__c(reduivy__Start_Date__c = testDate.addDays(2)));

        List<REDU_SObjectComparator.SortCriterion> criteria = new List<REDU_SObjectComparator.SortCriterion>{
            new REDU_SObjectComparator.SortCriterion(reduivy__Study_Offering__c.reduivy__Start_Date__c, REDU_SObjectComparator.SortOrder.Descend, REDU_SObjectComparator.NullOrder.NullsFirst)
        };

        toSort.sort(new REDU_SObjectComparator(criteria));
        // System.Assert.areEqual('expected', JSOn.serialize(toSort));

        System.Assert.isNull(toSort.get(0));
        System.Assert.areEqual(null, toSort.get(1).reduivy__Start_Date__c);
        System.Assert.areEqual(testDate.addDays(3), toSort.get(2).reduivy__Start_Date__c);
        System.Assert.areEqual(testDate.addDays(2), toSort.get(3).reduivy__Start_Date__c);
        System.Assert.areEqual(testDate.addDays(1), toSort.get(4).reduivy__Start_Date__c);

        Test.stopTest();
        
    }

    /**
     * @description Test date desc nulls last
     */
    @IsTest
    static void testDateSortingDescNullsLast(){
        
        Test.startTest();
        
        Date testDate = System.today();

        List<reduivy__Study_Offering__c> toSort = new List<reduivy__Study_Offering__c>();
        toSort.add(new reduivy__Study_Offering__c(reduivy__Start_Date__c = testDate.addDays(1)));
        toSort.add(null);
        toSort.add(new reduivy__Study_Offering__c(reduivy__Start_Date__c = testDate.addDays(3)));
        toSort.add(new reduivy__Study_Offering__c(reduivy__Start_Date__c = null));
        toSort.add(new reduivy__Study_Offering__c(reduivy__Start_Date__c = testDate.addDays(2)));

        List<REDU_SObjectComparator.SortCriterion> criteria = new List<REDU_SObjectComparator.SortCriterion>{
            new REDU_SObjectComparator.SortCriterion(reduivy__Study_Offering__c.reduivy__Start_Date__c, REDU_SObjectComparator.SortOrder.Descend, REDU_SObjectComparator.NullOrder.NullsLast)
        };

        toSort.sort(new REDU_SObjectComparator(criteria));
        // System.Assert.areEqual('expected', JSOn.serialize(toSort));

        System.Assert.areEqual(testDate.addDays(3), toSort.get(0).reduivy__Start_Date__c);
        System.Assert.areEqual(testDate.addDays(2), toSort.get(1).reduivy__Start_Date__c);
        System.Assert.areEqual(testDate.addDays(1), toSort.get(2).reduivy__Start_Date__c);
        System.Assert.areEqual(null, toSort.get(3).reduivy__Start_Date__c);
        System.Assert.isNull(toSort.get(4));

        Test.stopTest();
        
    }

    /**
     * @description Test datetime asc nulls first
     */
    @IsTest
    static void testDatetimeSortingAscNullsFirst(){
        
        Test.startTest();
        
        Datetime testDate = System.now();

        List<reduivy__Study_Offering__c> toSort = new List<reduivy__Study_Offering__c>();
        toSort.add(new reduivy__Study_Offering__c(reduivy__Pre_enrollment_Open_Date__c = testDate.addDays(1)));
        toSort.add(null);
        toSort.add(new reduivy__Study_Offering__c(reduivy__Pre_enrollment_Open_Date__c = testDate.addDays(3)));
        toSort.add(new reduivy__Study_Offering__c(reduivy__Pre_enrollment_Open_Date__c = null));
        toSort.add(new reduivy__Study_Offering__c(reduivy__Pre_enrollment_Open_Date__c = testDate.addDays(2)));

        List<REDU_SObjectComparator.SortCriterion> criteria = new List<REDU_SObjectComparator.SortCriterion>{
            new REDU_SObjectComparator.SortCriterion(reduivy__Study_Offering__c.reduivy__Pre_enrollment_Open_Date__c, REDU_SObjectComparator.SortOrder.Ascend, REDU_SObjectComparator.NullOrder.NullsFirst)
        };

        toSort.sort(new REDU_SObjectComparator(criteria));
        // System.Assert.areEqual('expected', JSOn.serialize(toSort));

        System.Assert.isNull(toSort.get(0));
        System.Assert.areEqual(null, toSort.get(1).reduivy__Pre_enrollment_Open_Date__c);
        System.Assert.areEqual(testDate.addDays(1), toSort.get(2).reduivy__Pre_enrollment_Open_Date__c);
        System.Assert.areEqual(testDate.addDays(2), toSort.get(3).reduivy__Pre_enrollment_Open_Date__c);
        System.Assert.areEqual(testDate.addDays(3), toSort.get(4).reduivy__Pre_enrollment_Open_Date__c);

        Test.stopTest();
        
    }

    /**
     * @description Test datetime asc nulls last
     */
    @IsTest
    static void testDatetimeSortingAscNullsLast(){
        
        Test.startTest();
        
        Datetime testDate = System.now();

        List<reduivy__Study_Offering__c> toSort = new List<reduivy__Study_Offering__c>();
        toSort.add(new reduivy__Study_Offering__c(reduivy__Pre_enrollment_Open_Date__c = testDate.addDays(1)));
        toSort.add(null);
        toSort.add(new reduivy__Study_Offering__c(reduivy__Pre_enrollment_Open_Date__c = testDate.addDays(3)));
        toSort.add(new reduivy__Study_Offering__c(reduivy__Pre_enrollment_Open_Date__c = null));
        toSort.add(new reduivy__Study_Offering__c(reduivy__Pre_enrollment_Open_Date__c = testDate.addDays(2)));

        List<REDU_SObjectComparator.SortCriterion> criteria = new List<REDU_SObjectComparator.SortCriterion>{
            new REDU_SObjectComparator.SortCriterion(reduivy__Study_Offering__c.reduivy__Pre_enrollment_Open_Date__c, REDU_SObjectComparator.SortOrder.Ascend, REDU_SObjectComparator.NullOrder.NullsLast)
        };

        toSort.sort(new REDU_SObjectComparator(criteria));
        // System.Assert.areEqual('expected', JSOn.serialize(toSort));

        System.Assert.areEqual(testDate.addDays(1), toSort.get(0).reduivy__Pre_enrollment_Open_Date__c);
        System.Assert.areEqual(testDate.addDays(2), toSort.get(1).reduivy__Pre_enrollment_Open_Date__c);
        System.Assert.areEqual(testDate.addDays(3), toSort.get(2).reduivy__Pre_enrollment_Open_Date__c);
        System.Assert.areEqual(null, toSort.get(3).reduivy__Pre_enrollment_Open_Date__c);
        System.Assert.isNull(toSort.get(4));

        Test.stopTest();
        
    }

    /**
     * @description Test datetime desc nulls first
     */
    @IsTest
    static void testDatetimeSortingDescNullsFirst(){
        
        Test.startTest();
        
        Datetime testDate = System.now();

        List<reduivy__Study_Offering__c> toSort = new List<reduivy__Study_Offering__c>();
        toSort.add(new reduivy__Study_Offering__c(reduivy__Pre_enrollment_Open_Date__c = testDate.addDays(1)));
        toSort.add(null);
        toSort.add(new reduivy__Study_Offering__c(reduivy__Pre_enrollment_Open_Date__c = testDate.addDays(3)));
        toSort.add(new reduivy__Study_Offering__c(reduivy__Pre_enrollment_Open_Date__c = null));
        toSort.add(new reduivy__Study_Offering__c(reduivy__Pre_enrollment_Open_Date__c = testDate.addDays(2)));

        List<REDU_SObjectComparator.SortCriterion> criteria = new List<REDU_SObjectComparator.SortCriterion>{
            new REDU_SObjectComparator.SortCriterion(reduivy__Study_Offering__c.reduivy__Pre_enrollment_Open_Date__c, REDU_SObjectComparator.SortOrder.Descend, REDU_SObjectComparator.NullOrder.NullsFirst)
        };

        toSort.sort(new REDU_SObjectComparator(criteria));
        // System.Assert.areEqual('expected', JSOn.serialize(toSort));

        System.Assert.isNull(toSort.get(0));
        System.Assert.areEqual(null, toSort.get(1).reduivy__Pre_enrollment_Open_Date__c);
        System.Assert.areEqual(testDate.addDays(3), toSort.get(2).reduivy__Pre_enrollment_Open_Date__c);
        System.Assert.areEqual(testDate.addDays(2), toSort.get(3).reduivy__Pre_enrollment_Open_Date__c);
        System.Assert.areEqual(testDate.addDays(1), toSort.get(4).reduivy__Pre_enrollment_Open_Date__c);

        Test.stopTest();
        
    }

    /**
     * @description Test datetime desc nulls last
     */
    @IsTest
    static void testDatetimeSortingDescNullsLast(){
        
        Test.startTest();
        
        Datetime testDate = System.now();

        List<reduivy__Study_Offering__c> toSort = new List<reduivy__Study_Offering__c>();
        toSort.add(new reduivy__Study_Offering__c(reduivy__Pre_enrollment_Open_Date__c = testDate.addDays(1)));
        toSort.add(null);
        toSort.add(new reduivy__Study_Offering__c(reduivy__Pre_enrollment_Open_Date__c = testDate.addDays(3)));
        toSort.add(new reduivy__Study_Offering__c(reduivy__Pre_enrollment_Open_Date__c = null));
        toSort.add(new reduivy__Study_Offering__c(reduivy__Pre_enrollment_Open_Date__c = testDate.addDays(2)));

        List<REDU_SObjectComparator.SortCriterion> criteria = new List<REDU_SObjectComparator.SortCriterion>{
            new REDU_SObjectComparator.SortCriterion(reduivy__Study_Offering__c.reduivy__Pre_enrollment_Open_Date__c, REDU_SObjectComparator.SortOrder.Descend, REDU_SObjectComparator.NullOrder.NullsLast)
        };

        toSort.sort(new REDU_SObjectComparator(criteria));
        // System.Assert.areEqual('expected', JSOn.serialize(toSort));

        System.Assert.areEqual(testDate.addDays(3), toSort.get(0).reduivy__Pre_enrollment_Open_Date__c);
        System.Assert.areEqual(testDate.addDays(2), toSort.get(1).reduivy__Pre_enrollment_Open_Date__c);
        System.Assert.areEqual(testDate.addDays(1), toSort.get(2).reduivy__Pre_enrollment_Open_Date__c);
        System.Assert.areEqual(null, toSort.get(3).reduivy__Pre_enrollment_Open_Date__c);
        System.Assert.isNull(toSort.get(4));

        Test.stopTest();
        
    }

    /**
     * @description Test time asc nulls first
     */
    @IsTest
    static void testTimeSortingAscNullsFirst(){
        
        Test.startTest();
        
        List<reduivy__Study_Session_Time__c> toSort = new List<reduivy__Study_Session_Time__c>();
        toSort.add(new reduivy__Study_Session_Time__c(reduivy__Start_Time__c = Time.newInstance(1, 0, 0, 0)));
        toSort.add(null);
        toSort.add(new reduivy__Study_Session_Time__c(reduivy__Start_Time__c = Time.newInstance(2, 0, 0, 0)));
        toSort.add(new reduivy__Study_Session_Time__c(reduivy__Start_Time__c = null));
        toSort.add(new reduivy__Study_Session_Time__c(reduivy__Start_Time__c = Time.newInstance(3, 0, 0, 0)));

        List<REDU_SObjectComparator.SortCriterion> criteria = new List<REDU_SObjectComparator.SortCriterion>{
            new REDU_SObjectComparator.SortCriterion(reduivy__Study_Session_Time__c.reduivy__Start_Time__c, REDU_SObjectComparator.SortOrder.Ascend, REDU_SObjectComparator.NullOrder.NullsFirst)
        };

        toSort.sort(new REDU_SObjectComparator(criteria));
        // System.Assert.areEqual('expected', JSOn.serialize(toSort));

        System.Assert.isNull(toSort.get(0));
        System.Assert.areEqual(null, toSort.get(1).reduivy__Start_Time__c);
        System.Assert.areEqual(Time.newInstance(1, 0, 0, 0), toSort.get(2).reduivy__Start_Time__c);
        System.Assert.areEqual(Time.newInstance(2, 0, 0, 0), toSort.get(3).reduivy__Start_Time__c);
        System.Assert.areEqual(Time.newInstance(3, 0, 0, 0), toSort.get(4).reduivy__Start_Time__c);

        Test.stopTest();
        
    }

    /**
     * @description Test time asc nulls last
     */
    @IsTest
    static void testTimeSortingAscNullsLast(){
        
        Test.startTest();
        
        List<reduivy__Study_Session_Time__c> toSort = new List<reduivy__Study_Session_Time__c>();
        toSort.add(new reduivy__Study_Session_Time__c(reduivy__Start_Time__c = Time.newInstance(1, 0, 0, 0)));
        toSort.add(null);
        toSort.add(new reduivy__Study_Session_Time__c(reduivy__Start_Time__c = Time.newInstance(2, 0, 0, 0)));
        toSort.add(new reduivy__Study_Session_Time__c(reduivy__Start_Time__c = null));
        toSort.add(new reduivy__Study_Session_Time__c(reduivy__Start_Time__c = Time.newInstance(3, 0, 0, 0)));

        List<REDU_SObjectComparator.SortCriterion> criteria = new List<REDU_SObjectComparator.SortCriterion>{
            new REDU_SObjectComparator.SortCriterion(reduivy__Study_Session_Time__c.reduivy__Start_Time__c, REDU_SObjectComparator.SortOrder.Ascend, REDU_SObjectComparator.NullOrder.NullsLast)
        };

        toSort.sort(new REDU_SObjectComparator(criteria));
        // System.Assert.areEqual('expected', JSOn.serialize(toSort));

        System.Assert.areEqual(Time.newInstance(1, 0, 0, 0), toSort.get(0).reduivy__Start_Time__c);
        System.Assert.areEqual(Time.newInstance(2, 0, 0, 0), toSort.get(1).reduivy__Start_Time__c);
        System.Assert.areEqual(Time.newInstance(3, 0, 0, 0), toSort.get(2).reduivy__Start_Time__c);
        System.Assert.areEqual(null, toSort.get(3).reduivy__Start_Time__c);
        System.Assert.isNull(toSort.get(4));

        Test.stopTest();
        
    }

    /**
     * @description Test time desc nulls first
     */
    @IsTest
    static void testTimeSortingDescNullsFirst(){
        
        Test.startTest();
        
        List<reduivy__Study_Session_Time__c> toSort = new List<reduivy__Study_Session_Time__c>();
        toSort.add(new reduivy__Study_Session_Time__c(reduivy__Start_Time__c = Time.newInstance(1, 0, 0, 0)));
        toSort.add(null);
        toSort.add(new reduivy__Study_Session_Time__c(reduivy__Start_Time__c = Time.newInstance(2, 0, 0, 0)));
        toSort.add(new reduivy__Study_Session_Time__c(reduivy__Start_Time__c = null));
        toSort.add(new reduivy__Study_Session_Time__c(reduivy__Start_Time__c = Time.newInstance(3, 0, 0, 0)));

        List<REDU_SObjectComparator.SortCriterion> criteria = new List<REDU_SObjectComparator.SortCriterion>{
            new REDU_SObjectComparator.SortCriterion(reduivy__Study_Session_Time__c.reduivy__Start_Time__c, REDU_SObjectComparator.SortOrder.Descend, REDU_SObjectComparator.NullOrder.NullsFirst)
        };

        toSort.sort(new REDU_SObjectComparator(criteria));
        // System.Assert.areEqual('expected', JSOn.serialize(toSort));

        System.Assert.isNull(toSort.get(0));
        System.Assert.areEqual(null, toSort.get(1).reduivy__Start_Time__c);
        System.Assert.areEqual(Time.newInstance(3, 0, 0, 0), toSort.get(2).reduivy__Start_Time__c);
        System.Assert.areEqual(Time.newInstance(2, 0, 0, 0), toSort.get(3).reduivy__Start_Time__c);
        System.Assert.areEqual(Time.newInstance(1, 0, 0, 0), toSort.get(4).reduivy__Start_Time__c);

        Test.stopTest();
        
    }

    /**
     * @description Test time desc nulls last
     */
    @IsTest
    static void testTimeSortingDescNullsLast(){
        
        Test.startTest();
        
        List<reduivy__Study_Session_Time__c> toSort = new List<reduivy__Study_Session_Time__c>();
        toSort.add(new reduivy__Study_Session_Time__c(reduivy__Start_Time__c = Time.newInstance(1, 0, 0, 0)));
        toSort.add(null);
        toSort.add(new reduivy__Study_Session_Time__c(reduivy__Start_Time__c = Time.newInstance(2, 0, 0, 0)));
        toSort.add(new reduivy__Study_Session_Time__c(reduivy__Start_Time__c = null));
        toSort.add(new reduivy__Study_Session_Time__c(reduivy__Start_Time__c = Time.newInstance(3, 0, 0, 0)));

        List<REDU_SObjectComparator.SortCriterion> criteria = new List<REDU_SObjectComparator.SortCriterion>{
            new REDU_SObjectComparator.SortCriterion(reduivy__Study_Session_Time__c.reduivy__Start_Time__c, REDU_SObjectComparator.SortOrder.Descend, REDU_SObjectComparator.NullOrder.NullsLast)
        };

        toSort.sort(new REDU_SObjectComparator(criteria));
        // System.Assert.areEqual('expected', JSOn.serialize(toSort));

        System.Assert.areEqual(Time.newInstance(3, 0, 0, 0), toSort.get(0).reduivy__Start_Time__c);
        System.Assert.areEqual(Time.newInstance(2, 0, 0, 0), toSort.get(1).reduivy__Start_Time__c);
        System.Assert.areEqual(Time.newInstance(1, 0, 0, 0), toSort.get(2).reduivy__Start_Time__c);
        System.Assert.areEqual(null, toSort.get(3).reduivy__Start_Time__c);
        System.Assert.isNull(toSort.get(4));

        Test.stopTest();
        
    }

    /**
     * @description Test string asc nulls first with string field name
     */
    @IsTest
    static void testStringSortingAscNullsFirstWithStringFieldName(){
        
        Test.startTest();
        
        List<reduivy__Study_Offering__c> toSort = new List<reduivy__Study_Offering__c>();
        toSort.add(new reduivy__Study_Offering__c(Name = 'Test1'));
        toSort.add(null);
        toSort.add(new reduivy__Study_Offering__c(Name = 'Test3'));
        toSort.add(new reduivy__Study_Offering__c(Name = null));
        toSort.add(new reduivy__Study_Offering__c(Name = 'Test2'));

        List<REDU_SObjectComparator.SortCriterion> criteria = new List<REDU_SObjectComparator.SortCriterion>{
            new REDU_SObjectComparator.SortCriterion('reduivy__Study_Offering__c.Name', REDU_SObjectComparator.SortOrder.Ascend, REDU_SObjectComparator.NullOrder.NullsFirst)
        };
        
        toSort.sort(new REDU_SObjectComparator(criteria));

        System.debug(JSON.serialize(toSort));
        // System.Assert.areEqual('expected', JSOn.serialize(toSort));

        System.Assert.isNull(toSort.get(0));
        System.Assert.areEqual(null, toSort.get(1).Name);
        System.Assert.areEqual('Test1', toSort.get(2).Name);
        System.Assert.areEqual('Test2', toSort.get(3).Name);
        System.Assert.areEqual('Test3', toSort.get(4).Name);
        
        

        Test.stopTest();
        
    }

    /**
     * @description Test string asc nulls last with string field name
     */
    @IsTest
    static void testStringSortingAscNullsLastWithStringFieldName(){
        
        Test.startTest();
        
        List<reduivy__Study_Offering__c> toSort = new List<reduivy__Study_Offering__c>();
        toSort.add(new reduivy__Study_Offering__c(Name = 'Test1'));
        toSort.add(null);
        toSort.add(new reduivy__Study_Offering__c(Name = 'Test3'));
        toSort.add(new reduivy__Study_Offering__c(Name = null));
        toSort.add(new reduivy__Study_Offering__c(Name = 'Test2'));

        List<REDU_SObjectComparator.SortCriterion> criteria = new List<REDU_SObjectComparator.SortCriterion>{
            new REDU_SObjectComparator.SortCriterion('reduivy__Study_Offering__c.Name', REDU_SObjectComparator.SortOrder.Ascend, REDU_SObjectComparator.NullOrder.NullsLast)
        };
        
        toSort.sort(new REDU_SObjectComparator(criteria));

        System.debug(JSON.serialize(toSort));
        // System.Assert.areEqual('expected', JSOn.serialize(toSort));

        System.Assert.areEqual('Test1', toSort.get(0).Name);
        System.Assert.areEqual('Test2', toSort.get(1).Name);
        System.Assert.areEqual('Test3', toSort.get(2).Name);
        System.Assert.areEqual(null, toSort.get(3).Name);
        System.Assert.isNull(toSort.get(4));

        Test.stopTest();
        
    }

}