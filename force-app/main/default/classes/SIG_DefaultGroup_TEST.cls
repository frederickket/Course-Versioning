/**
 * @author      WDCi (XW)
 * @date        Sept 202
 * @group       Test
 * @description Test class for SIG_DefaultGroup_EXE
 * @changehistory
 * ISS-002526 11-7-2025 XW - new class
 */
@IsTest
public inherited sharing class SIG_DefaultGroup_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static final String SRC_NEW_SIG = 'NEW_SIG';
    static final String SRC_SIT = 'SYDNEY_BACBIS_CYINTAKE';
    static final String SRC_SIT2 = 'SYDNEY_BACBIS_NYINTAKE';
    static final String SRC_SIG_STANDARD = SRC_SIT + '_Standard';
    static final String SRC_SIG_DISABLED = SRC_SIT + '_Disabled';
    static final String SRC_SIG2_STANDARD = SRC_SIT2 + '_Standard';
    static final String SRC_SIG2_DISABLED = SRC_SIT2 + '_Disabled';

    static reduivy__Study_Intake__c sit;
    static reduivy__Study_Intake_Group__c sigStandard;
    static reduivy__Study_Intake_Group__c sigDisabled;
    static reduivy__Study_Intake__c sit2;
    static reduivy__Study_Intake_Group__c sig2Standard;
    static reduivy__Study_Intake_Group__c sig2Disabled;

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
            setEnableSigSetting(true);
        	
            testFactory.initSampleData(SPL_Helper.getApiName(), SIG_Helper.getApiName(), USR_Helper.getApiName(), IPA_Helper.getApiName(), true, true);
            
            Test.stopTest();
		}

    }
	
    /**
     * @description Test as admin for creating sig with default
     */
    @IsTest
    static void testForCreate_Default_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        setSig();
        System.Assert.areEqual(false, sigDisabled.reduivy__Default__c, 'default should be set to false!');
        System.Assert.areEqual(true, sigStandard.reduivy__Default__c, 'default should be set to true!');


        setSit();
        reduivy__Study_Intake_Group__c sigToInsert = createSig(1, SIG_Helper.STUDENT_GROUP_TYPE_STANDARD, true);
        
		System.runAs(ADMIN_USER){
            insert sigToInsert;    
		}

        reduivy__Study_Intake_Group__c actualSig = querySig(1)[0];

        setSig();

        System.Assert.areEqual(false, sigDisabled.reduivy__Default__c, 'default should be always false!');
        System.Assert.areEqual(false, sigStandard.reduivy__Default__c, 'default should be set to false!');
        System.Assert.areEqual(true, actualSig.reduivy__Default__c, 'default should be set to true!');

        

        Test.stopTest();
		
		
    }

    /**
     * @description Test as admin for creating sig without default
     */
    @IsTest
    static void testForCreate_WithoutDefault_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        setSig();
        System.Assert.areEqual(false, sigDisabled.reduivy__Default__c, 'default should be set to false!');
        System.Assert.areEqual(true, sigStandard.reduivy__Default__c, 'default should be set to true!');

        setSit();
        reduivy__Study_Intake_Group__c sigToInsert = createSig(1, SIG_Helper.STUDENT_GROUP_TYPE_STANDARD, false);
        
		System.runAs(ADMIN_USER){
            insert sigToInsert;    
		}

        reduivy__Study_Intake_Group__c actualSig = querySig(1)[0];

        setSig();

        System.Assert.areEqual(false, sigDisabled.reduivy__Default__c, 'default should be always false!');
        System.Assert.areEqual(true, sigStandard.reduivy__Default__c, 'default should be remain as true!');
        System.Assert.areEqual(false, actualSig.reduivy__Default__c, 'default should not be set to true!');

        
        Test.stopTest();
		
    }

	
    /**
     * @description Test as admin for creating sig with default
     */
    @IsTest
    static void testForCreate10_Default_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        setSig();
        System.Assert.areEqual(false, sigDisabled.reduivy__Default__c, 'default should be set to false!');
        System.Assert.areEqual(true, sigStandard.reduivy__Default__c, 'default should be set to true!');


        setSit();
        List<reduivy__Study_Intake_Group__c> sigToInsertList = new List<reduivy__Study_Intake_Group__c>();
        for(Integer i = 1; i <= 10; i++) {
            reduivy__Study_Intake_Group__c sigToInsert = createSig(i, SIG_Helper.STUDENT_GROUP_TYPE_STANDARD, true);
            sigToInsertList.add(sigToInsert);
        }
        
		System.runAs(ADMIN_USER){
            insert sigToInsertList;    
		}

        List<reduivy__Study_Intake_Group__c> actualSigList = querySig(10);

        setSig();

        System.Assert.areEqual(10, actualSigList.size(), 'Wrong inserted isg list!');
        System.Assert.areEqual(false, sigDisabled.reduivy__Default__c, 'default should be always false!');
        System.Assert.areEqual(false, sigStandard.reduivy__Default__c, 'default should be set to false!');
        System.Assert.areEqual(true, actualSigList[0].reduivy__Default__c, 'default should be set to true!');
        for(Integer i = 1; i < 10; i++) {
            System.Assert.areEqual(false, actualSigList[i].reduivy__Default__c, 'default should be set to false!');
        }
    }
	
    /**
     * @description Test as admin for creating sig with default
     */
    @IsTest
    static void testForCreate100_Default_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        setSig();
        System.Assert.areEqual(false, sigDisabled.reduivy__Default__c, 'default should be set to false!');
        System.Assert.areEqual(true, sigStandard.reduivy__Default__c, 'default should be set to true!');


        setSit();
        List<reduivy__Study_Intake_Group__c> sigToInsertList = new List<reduivy__Study_Intake_Group__c>();
        for(Integer i = 1; i <= 100; i++) {
            reduivy__Study_Intake_Group__c sigToInsert = createSig(i, SIG_Helper.STUDENT_GROUP_TYPE_STANDARD, true);
            sigToInsertList.add(sigToInsert);
        }
        
		System.runAs(ADMIN_USER){
            insert sigToInsertList;    
		}

        List<reduivy__Study_Intake_Group__c> actualSigList = querySig(100);

        setSig();

        System.Assert.areEqual(100, actualSigList.size(), 'Wrong inserted isg list!');
        System.Assert.areEqual(false, sigDisabled.reduivy__Default__c, 'default should be always false!');
        System.Assert.areEqual(false, sigStandard.reduivy__Default__c, 'default should be set to false!');
        System.Assert.areEqual(true, actualSigList[0].reduivy__Default__c, 'default should be set to true!');
        for(Integer i = 1; i < 100; i++) {
            System.Assert.areEqual(false, actualSigList[i].reduivy__Default__c, 'default should be set to false!');
        }
    }
	
    /**
     * @description Test as admin for creating sig with default
     */
    @IsTest
    static void testForCreate10_DiffSit_Default_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        setSig();
        System.Assert.areEqual(false, sigDisabled.reduivy__Default__c, 'default should be set to false!');
        System.Assert.areEqual(true, sigStandard.reduivy__Default__c, 'default should be set to true!');


        setSit();
        List<reduivy__Study_Intake_Group__c> sigToInsertList = new List<reduivy__Study_Intake_Group__c>();
        for(Integer i = 1; i <= 10; i++) {
            reduivy__Study_Intake_Group__c sigToInsert = createSig(i, SIG_Helper.STUDENT_GROUP_TYPE_STANDARD, true);
            sigToInsertList.add(sigToInsert);

            if(i >= 6) {
                sigToInsert.reduivy__Study_Intake__c = sit2.Id;
            } 
        }
        
		System.runAs(ADMIN_USER){
            insert sigToInsertList;    
		}

        List<reduivy__Study_Intake_Group__c> actualSigList = querySig(10);

        setSig();

        System.Assert.areEqual(10, actualSigList.size(), 'Wrong inserted isg list!');
        System.Assert.areEqual(false, sigDisabled.reduivy__Default__c, 'default should be always false!');
        System.Assert.areEqual(false, sigStandard.reduivy__Default__c, 'default should be set to false!');

        System.Assert.areEqual(true, actualSigList[0].reduivy__Default__c, 'default should be set to true!');
        for(Integer i = 1; i <= 4; i++) {
            System.Assert.areEqual(false, actualSigList[i].reduivy__Default__c, 'default should be set to false!');
            System.Assert.areEqual(sit.Id, actualSigList[i].reduivy__Study_Intake__c, 'Wrong sit!');
        }
        
        System.Assert.areEqual(true, actualSigList[5].reduivy__Default__c, 'default should be set to true!');
        for(Integer i = 6; i <= 9; i++) {
            System.Assert.areEqual(false, actualSigList[i].reduivy__Default__c, 'default should be set to false!');
            System.Assert.areEqual(sit2.Id, actualSigList[i].reduivy__Study_Intake__c, 'Wrong sit!');
        }
    }

    @IsTest
    static void testForUpdate_ChangeDefault_AsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        setSig();
        System.Assert.areEqual(false, sigDisabled.reduivy__Default__c, 'default should be set to false!');
        System.Assert.areEqual(true, sigStandard.reduivy__Default__c, 'default should be set to true!');
        System.Assert.areEqual(false, sig2Disabled.reduivy__Default__c, 'default should be set to false!');
        System.Assert.areEqual(true, sig2Standard.reduivy__Default__c, 'default should be set to true!');

        //change sit of sig disabled to 
        setSit();
        sig2Disabled.reduivy__Default__c = true;
        sigDisabled.reduivy__Default__c = true;
        
        System.runAs(ADMIN_USER) {
            update new List<reduivy__Study_Intake_Group__c> {sig2Disabled, sigDisabled};
        }

        setSig();

        System.Assert.areEqual(true, sigDisabled.reduivy__Default__c, 'default should be updated to true!');
        System.Assert.areEqual(false, sigStandard.reduivy__Default__c, 'default should be updated to false!');
        System.Assert.areEqual(true, sig2Disabled.reduivy__Default__c, 'default should be updated to true!');
        System.Assert.areEqual(false, sig2Standard.reduivy__Default__c, 'default should be updated to false!');
        System.Assert.areEqual(sit2.Id, sig2Disabled.reduivy__Study_Intake__c, 'study intake should not be updated!');
        System.Assert.areEqual(sit.Id, sigDisabled.reduivy__Study_Intake__c, 'study intake should not be updated!');
        
        Test.stopTest();
    }

    @IsTest
    static void testForUpdate_ChangeSit_AsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        setSig();
        System.Assert.areEqual(false, sigDisabled.reduivy__Default__c, 'default should be set to false!');
        System.Assert.areEqual(true, sigStandard.reduivy__Default__c, 'default should be set to true!');
        System.Assert.areEqual(false, sig2Disabled.reduivy__Default__c, 'default should be set to false!');
        System.Assert.areEqual(true, sig2Standard.reduivy__Default__c, 'default should be set to true!');

        //change sit of sig disabled to 
        setSit();
        sig2Standard.reduivy__Study_Intake__c = sit.Id;
        
        System.runAs(ADMIN_USER) {
            update sig2Standard;
        }

        setSig();

        System.Assert.areEqual(false, sigDisabled.reduivy__Default__c, 'default should be remain as false!');
        System.Assert.areEqual(false, sigStandard.reduivy__Default__c, 'default should be updated to false!');
        System.Assert.areEqual(false, sig2Disabled.reduivy__Default__c, 'default should be remain as false!');
        System.Assert.areEqual(true, sig2Standard.reduivy__Default__c, 'default should be set to true!');
        System.Assert.areEqual(sit.Id, sig2Standard.reduivy__Study_Intake__c, 'sig2 standard study intake should be changed!');
        

        Test.stopTest();
    }

    
    /**
     * @description Test as admin for updating sig with default
     */
    @IsTest
    static void testForUpdate100_Default_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        setSig();
        System.Assert.areEqual(false, sigDisabled.reduivy__Default__c, 'default should be set to false!');
        System.Assert.areEqual(true, sigStandard.reduivy__Default__c, 'default should be set to true!');


        setSit();
        List<reduivy__Study_Intake_Group__c> sigToInsertList = new List<reduivy__Study_Intake_Group__c>();
        for(Integer i = 1; i <= 100; i++) {
            reduivy__Study_Intake_Group__c sigToInsert = createSig(i, SIG_Helper.STUDENT_GROUP_TYPE_STANDARD, false);
            sigToInsertList.add(sigToInsert);
        }
        
		System.runAs(ADMIN_USER){
            insert sigToInsertList;    
		}

        List<reduivy__Study_Intake_Group__c> actualSigList = querySig(100);

        setSig();

        System.Assert.areEqual(100, actualSigList.size(), 'Wrong inserted isg list!');
        System.Assert.areEqual(false, sigDisabled.reduivy__Default__c, 'default should be always false!');
        System.Assert.areEqual(true, sigStandard.reduivy__Default__c, 'default should not be set to false yet!');
        System.Assert.areEqual(false, actualSigList[0].reduivy__Default__c, 'default should be set to false!');
        for(Integer i = 1; i < 100; i++) {
            System.Assert.areEqual(false, actualSigList[i].reduivy__Default__c, 'default should be set to false!');
        }


        //update default to true
        for(reduivy__Study_Intake_Group__c sig : sigToInsertList) {
            sig.reduivy__Default__c = true;
        }

        System.runAs(ADMIN_USER) {
            update sigToInsertList;
        }

        List<reduivy__Study_Intake_Group__c> actualSigListAfterUpdate = querySig(100);
        setSig();

        System.Assert.areEqual(100, actualSigListAfterUpdate.size(), 'Wrong inserted isg list!');
        System.Assert.areEqual(false, sigDisabled.reduivy__Default__c, 'default should be always false!');
        System.Assert.areEqual(false, sigStandard.reduivy__Default__c, 'default should be set to false!');
        System.Assert.areEqual(true, actualSigListAfterUpdate[0].reduivy__Default__c, 'default should be set to true!');
        for(Integer i = 1; i < 100; i++) {
            System.Assert.areEqual(false, actualSigListAfterUpdate[i].reduivy__Default__c, 'default should be set to false!');
        }
        
    }
	

    /**
     * @description set the record value translation setting to the value given
     */
    private static void setEnableSigSetting(Boolean value) {
        if(REDU_AppSetting_UTIL.isUsingStudyIntakeGroup() != value) {
            reduivy__RIO_Education_Ivy_Settings__c setting = REDU_AppSetting_UTIL.getOrgDefaultSetting();
            setting.reduivy__Use_Study_Intake_Group__c = value;
            update setting;
        }
    }

    static reduivy__Study_Intake_Group__c createSig(Integer id, String type, Boolean isDefault) {
        return REDU_TestData_UTIL.newStudyIntakeGroup(SRC_NEW_SIG + id, SRC_NEW_SIG, type, sit.Id, 10, isDefault);
    }
    
    static List<reduivy__Study_Intake_Group__c> querySig(Integer numberOfCount) {
        Set<String> srcSet = new Set<String>();

        for(Integer i = 1; i <= numberOfCount; i++) {
            srcSet.add(SRC_NEW_SIG + i);
        }
        
        return [
            SELECT Id, Name, reduivy__Default__c, reduivy__Study_Intake__c
            FROM reduivy__Study_Intake_Group__c WHERE reduivy__Sample_Record_Code__c IN :srcSet
        ];
    }

    static void setSit() {
        for(reduivy__Study_Intake__c si : [
            SELECT Id, Name, reduivy__Sample_Record_Code__c
            FROM reduivy__Study_Intake__c WHERE reduivy__Sample_Record_Code__c IN (:SRC_SIT, :SRC_SIT2)
        ]) {
            if(si.reduivy__Sample_Record_Code__c == SRC_SIT) {
                sit = si;
            } else if(si.reduivy__Sample_Record_Code__c == SRC_SIT2) {
                sit2 = si;
            }
        }
    }

    static void setSig() {
        for(reduivy__Study_Intake_Group__c sig : [
            SELECT Id, Name, reduivy__Default__c, reduivy__Sample_Record_Code__c , reduivy__Study_Intake__c
            FROM reduivy__Study_Intake_Group__c 
            WHERE reduivy__Sample_Record_Code__c 
            IN (:SRC_SIG_STANDARD, :SRC_SIG_DISABLED, :SRC_SIG2_STANDARD, :SRC_SIG2_DISABLED)
        ]) {
            if(sig.reduivy__Sample_Record_Code__c == SRC_SIG_STANDARD) {
                sigStandard = sig;
            } else if(sig.reduivy__Sample_Record_Code__c == SRC_SIG_DISABLED) {
                sigDisabled = sig;
            } else if(sig.reduivy__Sample_Record_Code__c == SRC_SIG2_STANDARD) {
                sig2Standard = sig;
            } else if (sig.reduivy__Sample_Record_Code__c == SRC_SIG2_DISABLED) {
                sig2Disabled = sig;
            }
        }
    }
	
}