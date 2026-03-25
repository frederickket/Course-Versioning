/**
 * @author      WDCi (XW)
 * @date        Dec 2024
 * @group       Test
 * @description Test class for REDU_RecordEditModal_LCTRL
 * @changehistory
 * ISS-002104 03-12-2024 XW - create new class
 */
@IsTest
public inherited sharing class REDU_RecordEditModal_TEST {

    /**
     * @description Test as admin for getFieldSetMembers
     */
    @IsTest
    static void testForGetFieldSetMembers() {

        Test.startTest();
        
        String objName = 'Contact';
        String fieldSetName = 'reduivy__UnitTesting';

        List<REDU_DynamicFieldValue_OBJ> expectedFields = REDU_Metadata_UTIL.getFieldSetMembers(objName, fieldSetName);
        String actualFields = REDU_RecordEditModal_LCTRL.getFieldSetMembers(objName, fieldSetName).responseData;

        System.Assert.areEqual(false, expectedFields.isEmpty(), 'There should be fields in the field set.');
        System.Assert.areEqual(5, expectedFields.size(), 'There should be AccountId, FirstName, LastName, Birthdate and Email in the field set.');
        System.Assert.areEqual(JSON.serialize(expectedFields), actualFields, 'The fields are different.');

        Test.stopTest();
		
    }

}