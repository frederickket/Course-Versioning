/**
 * @author      WDCi (XW)
 * @date        Mar 2025
 * @group       Test
 * @description Test class for SYV_Helper
 * @changehistory
 * ISS-002089 04-03-2025 new class
 */
@IsTest
public inherited sharing class SYV_Helper_TEST {

    static final String SEQUENCE_NUMBER_KEY_PREFIX = 'SN-';
    static final String NO_CURLY_KEY = 'No curly';
    static final String EXTRA_CURLY_KEY = 'Extra curly';
    static final String DIFFERENT_PAD_CURLY_KEY1 = 'Different Pad curly1';
    static final String DIFFERENT_PAD_CURLY_KEY2 = 'Different Pad curly2';
    static final Integer MAX_ZERO_SEQUENCE_NUMBER = 2;

    @TestSetup
    static void makeData() {
        List<reduivy__System_Variable__c> syvList = new List<reduivy__System_Variable__c>();
        
        for(Integer i = 0; i <= MAX_ZERO_SEQUENCE_NUMBER; i++) {

            reduivy__System_Variable__c syv = new reduivy__System_Variable__c();
            
            syv.Name = getSystemVariableKey(i);
            syv.reduivy__Format__c = SEQUENCE_NUMBER_KEY_PREFIX + REDU_StringMerge_UTIL.format(''.leftPad(i, '0'));
            syv.reduivy__Number__c = 0;
            syv.reduivy__Sample_Record_Code__c = getSystemVariableKey(i);

            syvList.add(syv);
        }
        reduivy__System_Variable__c noCurlyBracketSyv = new reduivy__System_Variable__c();
        noCurlyBracketSyv.Name = NO_CURLY_KEY;
        noCurlyBracketSyv.reduivy__Format__c = SEQUENCE_NUMBER_KEY_PREFIX;
        noCurlyBracketSyv.reduivy__Number__c = 0;
        noCurlyBracketSyv.reduivy__Sample_Record_Code__c = NO_CURLY_KEY;
        syvList.add(noCurlyBracketSyv);
        
        reduivy__System_Variable__c extraCurlyBracketSyv = new reduivy__System_Variable__c();
        extraCurlyBracketSyv.Name = EXTRA_CURLY_KEY;
        extraCurlyBracketSyv.reduivy__Format__c = SEQUENCE_NUMBER_KEY_PREFIX + REDU_StringMerge_UTIL.format('0000') + '-' + REDU_StringMerge_UTIL.format('0000');
        extraCurlyBracketSyv.reduivy__Number__c = 0;
        extraCurlyBracketSyv.reduivy__Sample_Record_Code__c = EXTRA_CURLY_KEY;
        syvList.add(extraCurlyBracketSyv);

        reduivy__System_Variable__c diffPadCurlyBracketSyv1 = new reduivy__System_Variable__c();
        diffPadCurlyBracketSyv1.Name = DIFFERENT_PAD_CURLY_KEY1;
        diffPadCurlyBracketSyv1.reduivy__Format__c = SEQUENCE_NUMBER_KEY_PREFIX + REDU_StringMerge_UTIL.format('AAAA');
        diffPadCurlyBracketSyv1.reduivy__Number__c = 0;
        diffPadCurlyBracketSyv1.reduivy__Sample_Record_Code__c = DIFFERENT_PAD_CURLY_KEY1;
        syvList.add(diffPadCurlyBracketSyv1);

        reduivy__System_Variable__c diffPadCurlyBracketSyv2 = new reduivy__System_Variable__c();
        diffPadCurlyBracketSyv2.Name = DIFFERENT_PAD_CURLY_KEY2;
        diffPadCurlyBracketSyv2.reduivy__Format__c = SEQUENCE_NUMBER_KEY_PREFIX + REDU_StringMerge_UTIL.format('A0AA');
        diffPadCurlyBracketSyv2.reduivy__Number__c = 0;
        diffPadCurlyBracketSyv2.reduivy__Sample_Record_Code__c = DIFFERENT_PAD_CURLY_KEY2;
        syvList.add(diffPadCurlyBracketSyv2);


        insert syvList;

    }


    /**
     * @description Test object helper method
     */
    @IsTest
    static void testObjectHelper(){
        
        Test.startTest();
        
        System.Assert.areEqual(SObjectType.reduivy__System_Variable__c.getLabel(), SYV_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__System_Variable__c.getLabelPlural(), SYV_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__System_Variable__c.getName(), SYV_Helper.getApiName());

        Test.stopTest();
        
    }

    /**
     * @description test for valid format (SN-{0000})
     */
    @IsTest
    static void testGenerateIdsValid() {
        
        Test.startTest();

        Integer numberOfRecords = 5;

        //assert before generate ids
        List<reduivy__System_Variable__c> syvBeforeList = [
            SELECT Id, Name, reduivy__Format__c, reduivy__Number__c
            FROM reduivy__System_Variable__c
            WHERE reduivy__Sample_Record_Code__c NOT IN (:NO_CURLY_KEY, :EXTRA_CURLY_KEY, :DIFFERENT_PAD_CURLY_KEY1, :DIFFERENT_PAD_CURLY_KEY2)
            ORDER BY reduivy__Sample_Record_Code__c ASC
        ];

        for(Integer i = 1; i <= MAX_ZERO_SEQUENCE_NUMBER; i++) {
            System.Assert.areEqual(0, syvBeforeList[i].reduivy__Number__c, 'Number should be 0!');
            System.Assert.areEqual(SEQUENCE_NUMBER_KEY_PREFIX + REDU_StringMerge_UTIL.format(''.leftPad(i, '0')),
                syvBeforeList[i].reduivy__Format__c, 'Format should be 0!');
            System.Assert.areEqual(getSystemVariableKey(i), syvBeforeList[i].Name, 'Number should be 0!');
        }

        List<List<String>> syvGeneratedIds = new List<List<String>>();
        for(Integer i = 1; i <= MAX_ZERO_SEQUENCE_NUMBER; i++){
            syvGeneratedIds.add(SYV_Helper.generateSequenceNumber(numberOfRecords, getSystemVariableKey(i)));
        }

        List<reduivy__System_Variable__c> syvAfterList = [
            SELECT Id, Name, reduivy__Format__c, reduivy__Number__c
            FROM reduivy__System_Variable__c
            WHERE Id IN :syvBeforeList
            ORDER BY reduivy__Sample_Record_Code__c ASC
        ];
        

        for(Integer lengthOfZero = 1; lengthOfZero <= MAX_ZERO_SEQUENCE_NUMBER; lengthOfZero++) {

            System.Assert.areEqual(
                SEQUENCE_NUMBER_KEY_PREFIX + REDU_StringMerge_UTIL.format(''.leftPad(lengthOfZero, '0')),
                syvAfterList[lengthOfZero].reduivy__Format__c, 'Format should be 0!'
            );
            System.Assert.areEqual(getSystemVariableKey(lengthOfZero), syvAfterList[lengthOfZero].Name, 'Number should be 0!');
            System.Assert.areEqual(numberOfRecords, syvAfterList[lengthOfZero].reduivy__Number__c, 'Number should be ' + numberOfRecords + '!');

            for(Integer idIndex = 1; idIndex <= numberOfRecords; idIndex++) {
                System.Assert.areEqual(
                    SEQUENCE_NUMBER_KEY_PREFIX + String.valueOf(idIndex).leftPad(lengthOfZero, '0'), 
                    syvGeneratedIds[lengthOfZero - 1][idIndex - 1], 'Id generation error! lengthOfZero: ' + String.valueOf(lengthOfZero) + ', ' + 'idIndex: ' + String.valueOf(idIndex) + '.'
                );
            }
        }
        
        Test.stopTest();
    }
    
    /**
     * @description test for invalid syv (no syv is found)
     */
    @IsTest
    static void testGenerateIdsInvalidSyv() {
        
        Test.startTest();

        Integer numberOfRecords = 5;

        List<List<String>> syvGeneratedIds = new List<List<String>>();
        for(Integer i = 1; i <= MAX_ZERO_SEQUENCE_NUMBER; i++){
            try{
                syvGeneratedIds.add(SYV_Helper.generateSequenceNumber(numberOfRecords, 'Invalid Syv name'));
                System.Assert.fail('An error should be prompted for invalid syv name!');
            } catch(Exception exp) {
                String expectedError = String.format(Label.System_Variable_Not_Found, new List<String>{'Invalid Syv name'});
                System.Assert.areEqual(expectedError, exp.getMessage(), 'Wrong exception message!');
            }
        }

        System.Assert.areEqual(0, syvGeneratedIds.size(), 'No id should be generated!');
        
        
        Test.stopTest();
    }    

    /**
     * @description test for no records or no syv key
     */
    @IsTest
    static void testGenerateIdsEmptyParam() {
        
        Test.startTest();

        Integer numberOfRecords = 5;

        List<String> emptyRecordsGeneratedIds = new List<String>();
        List<String> emptyKeyGeneratedIds = new List<String>();

        emptyRecordsGeneratedIds = SYV_Helper.generateSequenceNumber(0, getSystemVariableKey(1));
        emptyKeyGeneratedIds = SYV_Helper.generateSequenceNumber(numberOfRecords, '');
        
        System.Assert.areEqual(0, emptyRecordsGeneratedIds.size(), 'No id should be generated for emptyRecordsGeneratedIds!');
        System.Assert.areEqual(0, emptyKeyGeneratedIds.size(), 'No id should be generated for emptyKeyGeneratedIds!');
        
        Test.stopTest();
    }

    /**
     * @description test for invalid format (SN-)
     */
    @IsTest
    static void testGenerateIdsNoCurlyBracket() {
        
        Test.startTest();

        Integer numberOfRecords = 5;

        List<String> generatedIds = new List<String>();

        try {
            generatedIds = SYV_Helper.generateSequenceNumber(numberOfRecords, NO_CURLY_KEY);
            System.Assert.fail('Ids should not be generated! Generated Ids: ' + JSON.serialize(generatedIds));
        } catch (Exception exp) {
            String expectedError = String.format(Label.System_Variable_Invalid_Formatted_String, new List<String> {SEQUENCE_NUMBER_KEY_PREFIX});
            System.Assert.areEqual(expectedError, exp.getMessage(), 'Wrong exception!');   
        }
        Test.stopTest();
    }
    
    /**
     * @description test for valid format (SN-{0000}-{0000})
     */
    @IsTest
    static void testGenerateIdsExtraCurlyBracket() {
        
        Test.startTest();

        Integer numberOfRecords = 5;

        //assert before generate ids
        reduivy__System_Variable__c syvBefore = [
            SELECT Id, Name, reduivy__Format__c, reduivy__Number__c
            FROM reduivy__System_Variable__c
            WHERE reduivy__Sample_Record_Code__c = :EXTRA_CURLY_KEY
            LIMIT 1
        ];

        System.Assert.areEqual(0, syvBefore.reduivy__Number__c, 'Number should be 0!');
        System.Assert.areEqual(
            SEQUENCE_NUMBER_KEY_PREFIX + REDU_StringMerge_UTIL.format(''.leftPad(4, '0')) + '-' + REDU_StringMerge_UTIL.format(''.leftPad(4, '0')),
            syvBefore.reduivy__Format__c, 'Format should be 0!');
        

        List<String> syvGeneratedIds = new List<String>();
        syvGeneratedIds = SYV_Helper.generateSequenceNumber(numberOfRecords, EXTRA_CURLY_KEY);
        

        reduivy__System_Variable__c syvAfter = [
            SELECT Id, Name, reduivy__Format__c, reduivy__Number__c
            FROM reduivy__System_Variable__c
            WHERE reduivy__Sample_Record_Code__c = :EXTRA_CURLY_KEY
            LIMIT 1
        ];
        

        for(Integer idIndex = 1; idIndex <= numberOfRecords; idIndex++) {
            System.Assert.areEqual(
                SEQUENCE_NUMBER_KEY_PREFIX + String.valueOf(idIndex).leftPad(4, '0') + '-' + String.valueOf(idIndex).leftPad(4, '0'), 
                syvGeneratedIds[idIndex - 1], 'Id generation error! idIndex: ' + String.valueOf(idIndex) + '.'
            );
        }
        
        
        Test.stopTest();

    }

    /**
     * @description test for valid format (SN-{AAAA})
     */
    @IsTest
    static void testGenerateIdsDifferentPad1(){
         
        Test.startTest();

        Integer numberOfRecords = 5;

        //assert before generate ids
        reduivy__System_Variable__c diffPad1Syv = [
            SELECT Id, Name, reduivy__Format__c, reduivy__Number__c
            FROM reduivy__System_Variable__c
            WHERE reduivy__Sample_Record_Code__c = :DIFFERENT_PAD_CURLY_KEY1
            LIMIT 1
        ];

        
        System.Assert.areEqual(0, diffPad1Syv.reduivy__Number__c, 'Number should be 0!');
        System.Assert.areEqual(SEQUENCE_NUMBER_KEY_PREFIX + REDU_StringMerge_UTIL.format('AAAA'),
            diffPad1Syv.reduivy__Format__c, 'Wrong format!');

        List<String> syvGeneratedIds = new List<String>();
        syvGeneratedIds = SYV_Helper.generateSequenceNumber(numberOfRecords, DIFFERENT_PAD_CURLY_KEY1);
        

        reduivy__System_Variable__c syvAfter = [
            SELECT Id, Name, reduivy__Format__c, reduivy__Number__c
            FROM reduivy__System_Variable__c
            WHERE reduivy__Sample_Record_Code__c = :DIFFERENT_PAD_CURLY_KEY1
            LIMIT 1
        ];
        

        for(Integer idIndex = 1; idIndex <= numberOfRecords; idIndex++) {
            System.Assert.areEqual(
                SEQUENCE_NUMBER_KEY_PREFIX + String.valueOf(idIndex).leftPad(4, 'A'), 
                syvGeneratedIds[idIndex - 1], 'Id generation error! idIndex: ' + String.valueOf(idIndex) + '.'
            );
        }
        
        Test.stopTest();
    }

    /**
     * @description test for valid format (SN-{A0AA})
     */
    @IsTest
    static void testGenerateIdsDifferentPad2(){
         
        Test.startTest();

        Integer numberOfRecords = 5;

        //assert before generate ids
        reduivy__System_Variable__c diffPad1Syv = [
            SELECT Id, Name, reduivy__Format__c, reduivy__Number__c
            FROM reduivy__System_Variable__c
            WHERE reduivy__Sample_Record_Code__c = :DIFFERENT_PAD_CURLY_KEY2
            LIMIT 1
        ];
        
        System.Assert.areEqual(0, diffPad1Syv.reduivy__Number__c, 'Number should be 0!');
        System.Assert.areEqual(SEQUENCE_NUMBER_KEY_PREFIX + REDU_StringMerge_UTIL.format('A0AA'),
            diffPad1Syv.reduivy__Format__c, 'Wrong format!');

        List<String> syvGeneratedIds = new List<String>();
        syvGeneratedIds = SYV_Helper.generateSequenceNumber(numberOfRecords, DIFFERENT_PAD_CURLY_KEY2);
        

        reduivy__System_Variable__c syvAfter = [
            SELECT Id, Name, reduivy__Format__c, reduivy__Number__c
            FROM reduivy__System_Variable__c
            WHERE reduivy__Sample_Record_Code__c = :DIFFERENT_PAD_CURLY_KEY2
            LIMIT 1
        ];
        

        for(Integer idIndex = 1; idIndex <= numberOfRecords; idIndex++) {
            System.Assert.areEqual(
                SEQUENCE_NUMBER_KEY_PREFIX + String.valueOf(idIndex).leftPad(4, 'A'), 
                syvGeneratedIds[idIndex - 1], 'Id generation error! idIndex: ' + String.valueOf(idIndex) + '.'
            );
        }
        
        Test.stopTest();
    }
    
    
    static String getSystemVariableKey(Integer i) {
        return SEQUENCE_NUMBER_KEY_PREFIX + String.valueOf(i);
    }

    
	
}