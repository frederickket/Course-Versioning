/**
 * @author      WDCi (VTan)
 * @date        Jul 2024
 * @group       
 * @description 
 * @changehistory
 * ISS-001922 01-07-2024 VTan - new class
 */
@IsTest
public inherited sharing class REDU_Date_TEST {

    @IsTest
    static void testGetISOWeekNumberAndYear(){
        
        Test.startTest();
        
        for (Integer i = 0; i < 1000; i ++) {
            List<Integer> test2015 = REDU_Date_UTIL.getISOWeekNumberAndYear(Date.newInstance(2015, 12, 28));
            System.Assert.areEqual(53, test2015.get(0));
            System.Assert.areEqual(2015, test2015.get(1));
        }
        
        Test.stopTest();
        
    }

    @IsTest
    static void testGet50YearsOfISOWeekNumberAndYear1(){
        
        Test.startTest();
        
        Date dateCounter = Date.newInstance(1999, 1, 1);

        List<reduivy__Study_Event__c> studyEvents = new List<reduivy__Study_Event__c>();
        for (integer i = 0; i < 18627; i ++) {
            reduivy__Study_Event__c sev = new reduivy__Study_Event__c();
            sev.reduivy__Start_Date_Non_TZ__c = dateCounter.addDays(i);
            
            studyEvents.add(sev);
        }

        Integer s1 = Limits.getCpuTime();
        List<System.FormulaRecalcResult> formulaResults = System.Formula.recalculateFormulas(studyEvents);
        for (System.FormulaRecalcResult fr : formulaResults) {
            if (!fr.isSuccess()) {
                
            }
        }
        Integer s2 = Limits.getCpuTime();

        Test.stopTest();

        Integer s3 = Limits.getCpuTime();
        for (integer i = 0; i < 18627; i ++) {
            Date currentDate = dateCounter.addDays(i);
            List<Integer> sevIsoInfo = REDU_Date_UTIL.getISOWeekNumberAndYear(currentDate);
            
            reduivy__Study_Event__c sev = studyEvents.get(i);
            Integer iweek = sev.reduivy__ISO_Week__c.intValue();
            Integer iyear = sev.reduivy__ISO_Year__c.intValue();
            
            System.Assert.areEqual(iweek, sevIsoInfo.get(0), 'ISO Week should match with the salesforce formula for date ::' + currentDate);
            System.Assert.areEqual(iyear, sevIsoInfo.get(1), 'ISO Year should match with the salesforce formula for date ::' + currentDate);
        }
        Integer s4 = Limits.getCpuTime();

        Integer a = s2 - s1;
        Integer b = s4 - s3;
        REDU_Logging_UTIL.debug('ISO Week/Year formula recalculation time', s2 - s1);
        REDU_Logging_UTIL.debug('ISO Week/Year UTIL recalculation time', s4 - s2);
    }

    @IsTest
    static void testGet50YearsOfISOWeekNumberAndYear2(){
        
        Test.startTest();
        
        Date dateCounter = Date.newInstance(2050, 1, 1);

        List<reduivy__Study_Event__c> studyEvents = new List<reduivy__Study_Event__c>();
        for (integer i = 0; i < 18261; i ++) {
            reduivy__Study_Event__c sev = new reduivy__Study_Event__c();
            sev.reduivy__Start_Date_Non_TZ__c = dateCounter.addDays(i);
            
            studyEvents.add(sev);
        }

        Integer s1 = Limits.getCpuTime();
        List<System.FormulaRecalcResult> formulaResults = System.Formula.recalculateFormulas(studyEvents);
        for (System.FormulaRecalcResult fr : formulaResults) {
            if (!fr.isSuccess()) {
                
            }
        }
        Integer s2 = Limits.getCpuTime();

        Test.stopTest();

        Integer s3 = Limits.getCpuTime();
        for (integer i = 0; i < 18261; i ++) {
            Date currentDate = dateCounter.addDays(i);
            List<Integer> sevIsoInfo = REDU_Date_UTIL.getISOWeekNumberAndYear(currentDate);
            
            reduivy__Study_Event__c sev = studyEvents.get(i);
            Integer iweek = sev.reduivy__ISO_Week__c.intValue();
            Integer iyear = sev.reduivy__ISO_Year__c.intValue();
            
            if (sevIsoInfo.get(0) != iweek && sevIsoInfo.get(1) != iyear) {
                REDU_Logging_UTIL.debug('ISO Week/Year Not Matched', currentDate);
            } 
            System.Assert.areEqual(iweek, sevIsoInfo.get(0), 'ISO Week should match with the salesforce formula');
            System.Assert.areEqual(iyear, sevIsoInfo.get(1), 'ISO Year should match with the salesforce formula');
        }
        Integer s4 = Limits.getCpuTime();

        REDU_Logging_UTIL.debug('ISO Week/Year formula recalculation time', s2 - s1);
        REDU_Logging_UTIL.debug('ISO Week/Year UTIL recalculation time', s4 - s2);
    }

    @IsTest
    static void testGet50YearsOfISOWeekNumberAndYear3(){
        
        Test.startTest();
        
        Date dateCounter = Date.newInstance(2100, 1, 1);

        List<reduivy__Study_Event__c> studyEvents = new List<reduivy__Study_Event__c>();
        for (integer i = 0; i < 18261; i ++) {
            reduivy__Study_Event__c sev = new reduivy__Study_Event__c();
            sev.reduivy__Start_Date_Non_TZ__c = dateCounter.addDays(i);
            
            studyEvents.add(sev);
        }

        Integer s1 = Limits.getCpuTime();
        List<System.FormulaRecalcResult> formulaResults = System.Formula.recalculateFormulas(studyEvents);
        for (System.FormulaRecalcResult fr : formulaResults) {
            if (!fr.isSuccess()) {
                
            }
        }
        Integer s2 = Limits.getCpuTime();

        Test.stopTest();

        Integer s3 = Limits.getCpuTime();
        for (integer i = 0; i < 18261; i ++) {
            Date currentDate = dateCounter.addDays(i);
            List<Integer> sevIsoInfo = REDU_Date_UTIL.getISOWeekNumberAndYear(currentDate);
            
            reduivy__Study_Event__c sev = studyEvents.get(i);
            Integer iweek = sev.reduivy__ISO_Week__c.intValue();
            Integer iyear = sev.reduivy__ISO_Year__c.intValue();
            
            if (sevIsoInfo.get(0) != iweek && sevIsoInfo.get(1) != iyear) {
                REDU_Logging_UTIL.debug('ISO Week/Year Not Matched', currentDate);
            } 
            System.Assert.areEqual(iweek, sevIsoInfo.get(0), 'ISO Week should match with the salesforce formula');
            System.Assert.areEqual(iyear, sevIsoInfo.get(1), 'ISO Year should match with the salesforce formula');
        }
        Integer s4 = Limits.getCpuTime();

        REDU_Logging_UTIL.debug('ISO Week/Year formula recalculation time', s2 - s1);
        REDU_Logging_UTIL.debug('ISO Week/Year UTIL recalculation time', s4 - s2);
    }
}