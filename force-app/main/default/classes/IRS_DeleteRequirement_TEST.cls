
/**
 * @author      WDCi (XW)
 * @date        Sept 2025
 * @group       Test
 * @description Test class for IRS_DeleteRequirement_EXE
 * @changehistory
 * ISS-002506 12-09-2025 XW - new class
 */
@IsTest
public inherited sharing class IRS_DeleteRequirement_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static final String CON_STUDENT = 'sandydoe@redu.example';

    /**
     * @description Default method to setup required data for automated test
     */
	@TestSetup
    static void makeData(){
        
        // Create settings
        testFactory.setupDefaultSettings();

        // Create test data
        User ADMIN_USER = testFactory.getReduAdminUser();
		System.runAs(ADMIN_USER) {
            Test.startTest();
        	
            testFactory.initMasterData(SRQ_Helper.getApiName());
            testFactory.initOfferingData(SIT_Helper.getApiName());
            testFactory.initFacultyData(USR_Helper.getApiName(), true);
            testFactory.initStudentData(IRQ_Helper.getApiName(), true);

            Test.stopTest();
		}

    }
	
    /**
     * @description Test as admin for deleting irs
     */
    @IsTest
    static void testForDeleteAsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        List<reduivy__Individual_Requirement__c> irqListBeforeDelete = queryIrqList();
        List<reduivy__Individual_Requirement_Set__c> irsListBeforeDelete = queryIrsList();
        
        System.Assert.isTrue(!irqListBeforeDelete.isEmpty(), 'List of Individual Requirement should not be empty! Size: ' + irqListBeforeDelete.size());
        System.Assert.isTrue(!irsListBeforeDelete.isEmpty(), 'List of Individual Requirement Set should not be empty! Size: ' + irsListBeforeDelete.size());
        
		System.runAs(ADMIN_USER){
            delete irsListBeforeDelete;
		}
        
        List<reduivy__Individual_Requirement__c> irqListAfterDelete = queryIrqList();
        List<reduivy__Individual_Requirement_Set__c> irsListAfterDelete = queryIrsList();

        System.Assert.isTrue(irqListAfterDelete.isEmpty(), 'List of Individual Requirement should be empty after deleted! Size: ' + irqListAfterDelete.size());
        System.Assert.isTrue(irsListAfterDelete.isEmpty(), 'List of Individual Requirement Set should be empty after deleted! Size: ' + irsListAfterDelete.size());

        Test.stopTest();
		
    }

    
	
    /**
     * @description Test as faculty for deleting irs
     */
    @IsTest
    static void testForDeleteAsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();

        List<reduivy__Individual_Requirement__c> irqListBeforeDelete = queryIrqList();
        List<reduivy__Individual_Requirement_Set__c> irsListBeforeDelete = queryIrsList();
        
        System.Assert.isTrue(!irqListBeforeDelete.isEmpty(), 'List of Individual Requirement should not be empty! Size: ' + irqListBeforeDelete.size());
        System.Assert.isTrue(!irsListBeforeDelete.isEmpty(), 'List of Individual Requirement Set should not be empty! Size: ' + irsListBeforeDelete.size());
        
		System.runAs(FACULTY_USER){

            try{
                delete irsListBeforeDelete;
                System.Assert.fail('Should be failed as faculty do not have permission to delete individual requirement set!');
            } catch(Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains('INSUFFICIENT_ACCESS_OR_READONLY'), 'Faculty do not have permission to delete individual requirement set! Actual: ' + exp.getMessage());
            }
		}
        
        List<reduivy__Individual_Requirement__c> irqListAfterDelete = queryIrqList();
        List<reduivy__Individual_Requirement_Set__c> irsListAfterDelete = queryIrsList();

        System.Assert.isTrue(!irqListAfterDelete.isEmpty(), 'List of Individual Requirement should not be empty after deleted! Size: ' + irqListAfterDelete.size());
        System.Assert.isTrue(!irsListAfterDelete.isEmpty(), 'List of Individual Requirement Set should not be empty after deleted! Size: ' + irsListAfterDelete.size());


        Test.stopTest();
		
    }

    /**
     * @description Test as student for deleting irs
     */
    @IsTest
    static void testForDeleteAsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();

        List<reduivy__Individual_Requirement__c> irqListBeforeDelete = queryIrqList();
        List<reduivy__Individual_Requirement_Set__c> irsListBeforeDelete = queryIrsList();
        
        System.Assert.isTrue(!irqListBeforeDelete.isEmpty(), 'List of Individual Requirement should not be empty! Size: ' + irqListBeforeDelete.size());
        System.Assert.isTrue(!irsListBeforeDelete.isEmpty(), 'List of Individual Requirement Set should not be empty! Size: ' + irsListBeforeDelete.size());
        
		System.runAs(studentUser){

            try{
                delete irsListBeforeDelete;
                System.Assert.fail('Should be failed as student do not have permission to delete individual requirement set!');
            } catch(Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains('INSUFFICIENT_ACCESS_OR_READONLY'), 'Student do not have permission to delete individual requirement set! Actual: ' + exp.getMessage());
            }
		}
        
        List<reduivy__Individual_Requirement__c> irqListAfterDelete = queryIrqList();
        List<reduivy__Individual_Requirement_Set__c> irsListAfterDelete = queryIrsList();

        System.Assert.isTrue(!irqListAfterDelete.isEmpty(), 'List of Individual Requirement should not be empty after deleted! Size: ' + irqListAfterDelete.size());
        System.Assert.isTrue(!irsListAfterDelete.isEmpty(), 'List of Individual Requirement Set should not be empty after deleted! Size: ' + irsListAfterDelete.size());

        Test.stopTest();
		
    }
	
    static List<reduivy__Individual_Requirement_Set__c> queryIrsList(){
        return [
            SELECT Id
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Contact__r.reduivy__Sample_Record_Code__c = :CON_STUDENT
        ];
    }

    static List<reduivy__Individual_Requirement__c> queryIrqList(){
        return [
            SELECT Id
            FROM reduivy__Individual_Requirement__c
            WHERE reduivy__Individual_Requirement_Set__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c = :CON_STUDENT
        ];
    }
	
}