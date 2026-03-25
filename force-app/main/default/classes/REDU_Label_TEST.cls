/**
 * @author      WDCi ()
 * @date        Dec 2025
 * @group       Test
 * @description Test class for 
 * @changehistory
 * ISS-XXXXXX dd-mm-yyyy name - description
 */
@IsTest
public inherited sharing class REDU_Label_TEST {

    @IsTest
    static void testGetLabel() {
        
        Test.startTest();
        
        String withNamespace = REDU_Label_UTIL.getLabelValue('{!$Label.reduivy__Academic_Term}');
        System.Assert.areEqual(System.Label.get('reduivy', 'Academic_Term'), withNamespace, 'Wrong label!');
        
        String withoutNamespace = REDU_Label_UTIL.getLabelValue('{!$Label.Academic_Term}');
        System.Assert.areEqual(System.Label.get('', 'Academic_Term'), withoutNamespace, 'Wrong label!');

        String invalidFormat = REDU_Label_UTIL.getLabelValue('reduivy__Academic_Term');
        System.Assert.areEqual('reduivy__Academic_Term', invalidFormat, 'Wrong result!');

        try {
            
            REDU_Label_UTIL.getLabelValue('{!$Label.reduivy__Some_random_invalid_label_name}');
            System.Assert.fail('Should failed with REDU_ApplicationException!');
        } catch (REDU_ApplicationException exp) {
            //no label found
            String errorMessage = String.format(System.Label.Invalid_Label, new List<String>{
                'reduivy__Some_random_invalid_label_name'
            });
            System.Assert.isTrue(exp.getMessage().contains(errorMessage), 'Wrong exception message! Actual: ' + exp.getMessage());

        } catch(Exception exp) {
            
            System.Assert.fail('Should failed with REDU_ApplicationException!');
        }
        
        Test.stopTest();
    }

    @IsTest
    static void testIsLabelFormatted() {
        
        Test.startTest();
        
        System.Assert.isTrue(REDU_Label_UTIL.isLabelFormatted('{!$Label.reduivy__Academic_Term}'), '{!$Label.reduivy__Academic_Term} should be label formatted!');
        System.Assert.isTrue(REDU_Label_UTIL.isLabelFormatted('{!$Label.Academic_Term}'), '{!$Label.Academic_Term} should be label formatted!');
        System.Assert.isTrue(REDU_Label_UTIL.isLabelFormatted('{!$Label.reduivy__Some_random_invalid_label_name}'), '{!$Label.reduivy__Some_random_invalid_label_name} should be label formatted!');
        System.Assert.isFalse(REDU_Label_UTIL.isLabelFormatted('{!$Label.Academic_Term'), '{!$Label.Academic_Term should not be label formatted!');
        System.Assert.isFalse(REDU_Label_UTIL.isLabelFormatted('Academic_Term}'), 'Academic_Term} should not be label formatted!');
        System.Assert.isFalse(REDU_Label_UTIL.isLabelFormatted('reduivy__Academic_Term'), 'reduivy__Academic_Term should not be label formatted!');
        
        Test.stopTest();
    }
	
}