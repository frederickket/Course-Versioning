/**
 * @author      WDCi (Jordan)
 * @date        Nov 2024
 * @group       Test
 * @description Test class for CVS_FileCategorySharing_EXE
 * @changehistory
 * ISS-002103 08-11-2024 Jordan - new class
 */
@IsTest
public inherited sharing class CVS_FileCategorySharing_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    /**
     * @description Create settings and test data
     */
	@TestSetup
    static void makeData() {
		
        // Create settings
		testFactory.setupDefaultSettings();
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        System.runAs(ADMIN_USER) {
            Test.startTest();
            testFactory.initMasterData(ACC_Helper.getApiName());
            testFactory.initOfferingData(STM_Helper.getApiName());
			testFactory.initStudentData(IPR_Helper.getApiName(), true);
            Test.stopTest();
        }
    }

    /**
     * @description Test file category sharing after insert as admin user
     */
    @IsTest
    static void testFileCategorySharingAfterInsertAsAdminUser() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        //Create file
        Blob body = Blob.valueOf('data:image/gif;base64,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');
        
        ContentVersion cvs1 = new ContentVersion();
        cvs1.Title = 'TestFileCategorySharing1.png';
        cvs1.VersionData = body;
        cvs1.PathOnClient = '/' + cvs1.Title;
        cvs1.reduivy__File_Category__c = 'Profile Picture';

        ContentVersion cvs2 = new ContentVersion();
        cvs2.Title = 'TestFileCategorySharing2.png';
        cvs2.VersionData = body;
        cvs2.PathOnClient = '/' + cvs2.Title;
        cvs2.reduivy__File_Category__c = 'Transcript';
        
        List<ContentVersion> files = new List<ContentVersion>{cvs1, cvs2};

        Test.startTest();

        System.runAs(ADMIN_USER) {
            //Create test record
            Account testAccount = new Account();
            testAccount.Name = 'Test Account';
            insert testAccount;
            
            cvs1.FirstPublishLocationId  = testAccount.Id;
            cvs2.FirstPublishLocationId  = testAccount.Id;

            REDU_Database_UTIL.doInsert(files);

        }

        //Assert
        Map<Id, ContentVersion> cdToCvMap = new Map<Id, ContentVersion>();
        for (ContentVersion cv : [SELECT ContentDocumentId, reduivy__File_Category__c FROM ContentVersion WHERE Id IN: files]) {
            cdToCvMap.put(cv.ContentDocumentId, cv);
        }

        Map<String, reduivy__File_Sharing_Config__mdt> fileSharingXref = CVS_Helper.getFileSharingXref();

        List<ContentDocumentLink> cdlCheckList = [SELECT Visibility, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE ContentDocumentId IN: cdToCvMap.keySet()];
        System.Assert.isTrue(!cdlCheckList.isEmpty(), 'There should be records for assertion.');

        for (ContentDocumentLink cdlCheck : cdlCheckList) {
            ContentVersion cv = cdToCvMap.get(cdlCheck.ContentDocumentId);
            reduivy__File_Sharing_Config__mdt fsc = fileSharingXref.get(cv.reduivy__File_Category__c);

            System.Assert.areEqual(fsc.reduivy__Visibility__c, cdlCheck.Visibility);
        }

        Test.stopTest();
	}

    /**
     * @description Test file category sharing after update as admin user
     */
    @IsTest
    static void testFileCategorySharingAfterUpdateAsAdminUser() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        //Create file
        Blob body = Blob.valueOf('data:image/gif;base64,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');
        
        ContentVersion cvs1 = new ContentVersion();
        cvs1.Title = 'TestFileCategorySharing1.png';
        cvs1.VersionData = body;
        cvs1.PathOnClient = '/' + cvs1.Title;

        ContentVersion cvs2 = new ContentVersion();
        cvs2.Title = 'TestFileCategorySharing2.png';
        cvs2.VersionData = body;
        cvs2.PathOnClient = '/' + cvs2.Title;
        
        List<ContentVersion> files = new List<ContentVersion>{cvs1, cvs2};
        
        Test.startTest();

        System.runAs(ADMIN_USER) {
            //Create test record
            Account testAccount = new Account();
            testAccount.Name = 'Test Account';
            insert testAccount;
            
            cvs1.FirstPublishLocationId  = testAccount.Id;
            cvs2.FirstPublishLocationId  = testAccount.Id;

            REDU_Database_UTIL.doInsert(files);
        }

        //Assert
        Map<Id, ContentVersion> cdToCvMapPre = new Map<Id, ContentVersion>();
        for (ContentVersion cv : [SELECT ContentDocumentId, reduivy__File_Category__c FROM ContentVersion WHERE Id IN: files]) {
            cdToCvMapPre.put(cv.ContentDocumentId, cv);
        }

        List<ContentDocumentLink> cdlCheckListPre = [SELECT Visibility, LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId IN: cdToCvMapPre.keySet()];
        for (ContentDocumentLink cdlCheck : cdlCheckListPre) {
            if (cdlCheck.LinkedEntityId == ADMIN_USER.Id) {
                //salesforce default the owner cdl to AllUsers
                System.Assert.areEqual('AllUsers', cdlCheck.Visibility);
            } else {
                System.Assert.areEqual('InternalUsers', cdlCheck.Visibility);
            }
        }

        ContentVersion cvs1Update = new ContentVersion();
        cvs1Update.Id = cvs1.Id;
        cvs1Update.reduivy__File_Category__c = 'Profile Picture';
        
        ContentVersion cvs2Update = new ContentVersion();
        cvs2Update.Id = cvs2.Id;
        cvs2Update.reduivy__File_Category__c = 'Transcript';

        List<ContentVersion> files2 = new List<ContentVersion>{cvs1Update, cvs2Update};

        System.runAs(ADMIN_USER) {
            REDU_Database_UTIL.doUpdate(files2);
        }

        //Assert
        Map<Id, ContentVersion> cdToCvMap = new Map<Id, ContentVersion>();
        for (ContentVersion cv : [SELECT ContentDocumentId, reduivy__File_Category__c FROM ContentVersion WHERE Id IN: files2]) {
            cdToCvMap.put(cv.ContentDocumentId, cv);
        }

        Map<String, reduivy__File_Sharing_Config__mdt> fileSharingXref = CVS_Helper.getFileSharingXref();

        List<ContentDocumentLink> cdlCheckList = [SELECT Visibility, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE ContentDocumentId IN: cdToCvMap.keySet()];
        System.Assert.isTrue(!cdlCheckList.isEmpty(), 'There should be records for assertion.');

        for (ContentDocumentLink cdlCheck : cdlCheckList) {
            ContentVersion cv = cdToCvMap.get(cdlCheck.ContentDocumentId);
            reduivy__File_Sharing_Config__mdt fsc = fileSharingXref.get(cv.reduivy__File_Category__c);

            System.Assert.areEqual(fsc.reduivy__Visibility__c, cdlCheck.Visibility);
        }

        Test.stopTest();
	}

    /**
     * @description Test file category sharing after insert as admin user
     */
    @IsTest
    static void testFileCategorySharingAfterInsertAsFacultyUser() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        //Create file
        Blob body = Blob.valueOf('data:image/gif;base64,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');
        
        ContentVersion cvs1 = new ContentVersion();
        cvs1.Title = 'TestFileCategorySharing1.png';
        cvs1.VersionData = body;
        cvs1.PathOnClient = '/' + cvs1.Title;
        cvs1.reduivy__File_Category__c = 'Profile Picture';

        ContentVersion cvs2 = new ContentVersion();
        cvs2.Title = 'TestFileCategorySharing2.png';
        cvs2.VersionData = body;
        cvs2.PathOnClient = '/' + cvs2.Title;
        cvs2.reduivy__File_Category__c = 'Transcript';
        
        List<ContentVersion> files = new List<ContentVersion>{cvs1, cvs2};

        Test.startTest();

        System.runAs(FACULTY_USER) {
            //Create test record
            Account testAccount = new Account();
            testAccount.Name = 'Test Account';
            insert testAccount;
            
            cvs1.FirstPublishLocationId  = testAccount.Id;
            cvs2.FirstPublishLocationId  = testAccount.Id;

            REDU_Database_UTIL.doInsert(files);

        }

        //Assert
        Map<Id, ContentVersion> cdToCvMap = new Map<Id, ContentVersion>();
        for (ContentVersion cv : [SELECT ContentDocumentId, reduivy__File_Category__c FROM ContentVersion WHERE Id IN: files]) {
            cdToCvMap.put(cv.ContentDocumentId, cv);
        }

        Map<String, reduivy__File_Sharing_Config__mdt> fileSharingXref = CVS_Helper.getFileSharingXref();

        List<ContentDocumentLink> cdlCheckList = [SELECT Visibility, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE ContentDocumentId IN: cdToCvMap.keySet()];
        System.Assert.isTrue(!cdlCheckList.isEmpty(), 'There should be records for assertion.');

        for (ContentDocumentLink cdlCheck : cdlCheckList) {
            ContentVersion cv = cdToCvMap.get(cdlCheck.ContentDocumentId);
            reduivy__File_Sharing_Config__mdt fsc = fileSharingXref.get(cv.reduivy__File_Category__c);

            System.Assert.areEqual(fsc.reduivy__Visibility__c, cdlCheck.Visibility);
        }

        Test.stopTest();
	}

    /**
     * @description Test file category sharing after update as admin user
     */
    @IsTest
    static void testFileCategorySharingAfterUpdateAsFacultyUser() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        //Create file
        Blob body = Blob.valueOf('data:image/gif;base64,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');
        
        ContentVersion cvs1 = new ContentVersion();
        cvs1.Title = 'TestFileCategorySharing1.png';
        cvs1.VersionData = body;
        cvs1.PathOnClient = '/' + cvs1.Title;

        ContentVersion cvs2 = new ContentVersion();
        cvs2.Title = 'TestFileCategorySharing2.png';
        cvs2.VersionData = body;
        cvs2.PathOnClient = '/' + cvs2.Title;
        
        List<ContentVersion> files = new List<ContentVersion>{cvs1, cvs2};
        
        Test.startTest();

        System.runAs(FACULTY_USER) {
            //Create test record
            Account testAccount = new Account();
            testAccount.Name = 'Test Account';
            insert testAccount;
            
            cvs1.FirstPublishLocationId  = testAccount.Id;
            cvs2.FirstPublishLocationId  = testAccount.Id;

            REDU_Database_UTIL.doInsert(files);
        }

        //Assert
        Map<Id, ContentVersion> cdToCvMapPre = new Map<Id, ContentVersion>();
        for (ContentVersion cv : [SELECT ContentDocumentId, reduivy__File_Category__c FROM ContentVersion WHERE Id IN: files]) {
            cdToCvMapPre.put(cv.ContentDocumentId, cv);
        }

        List<ContentDocumentLink> cdlCheckListPre = [SELECT Visibility, LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId IN: cdToCvMapPre.keySet()];
        for (ContentDocumentLink cdlCheck : cdlCheckListPre) {
            if (cdlCheck.LinkedEntityId == FACULTY_USER.Id) {
                //salesforce default the owner cdl to AllUsers
                System.Assert.areEqual('AllUsers', cdlCheck.Visibility);
            } else {
                System.Assert.areEqual('InternalUsers', cdlCheck.Visibility);
            }
        }

        ContentVersion cvs1Update = new ContentVersion();
        cvs1Update.Id = cvs1.Id;
        cvs1Update.reduivy__File_Category__c = 'Profile Picture';
        
        ContentVersion cvs2Update = new ContentVersion();
        cvs2Update.Id = cvs2.Id;
        cvs2Update.reduivy__File_Category__c = 'Transcript';

        List<ContentVersion> files2 = new List<ContentVersion>{cvs1Update, cvs2Update};

        System.runAs(FACULTY_USER) {
            REDU_Database_UTIL.doUpdate(files2);
        }

        //Assert
        Map<Id, ContentVersion> cdToCvMap = new Map<Id, ContentVersion>();
        for (ContentVersion cv : [SELECT ContentDocumentId, reduivy__File_Category__c FROM ContentVersion WHERE Id IN: files2]) {
            cdToCvMap.put(cv.ContentDocumentId, cv);
        }

        Map<String, reduivy__File_Sharing_Config__mdt> fileSharingXref = CVS_Helper.getFileSharingXref();

        List<ContentDocumentLink> cdlCheckList = [SELECT Visibility, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE ContentDocumentId IN: cdToCvMap.keySet()];
        System.Assert.isTrue(!cdlCheckList.isEmpty(), 'There should be records for assertion.');

        for (ContentDocumentLink cdlCheck : cdlCheckList) {
            ContentVersion cv = cdToCvMap.get(cdlCheck.ContentDocumentId);
            reduivy__File_Sharing_Config__mdt fsc = fileSharingXref.get(cv.reduivy__File_Category__c);

            System.Assert.areEqual(fsc.reduivy__Visibility__c, cdlCheck.Visibility);
        }

        Test.stopTest();
	}

    /**
     * @description Test file category sharing after insert as student user
     */
    // @IsTest
    // static void testFileCategorySharingAfterInsertAsStudentUser() {
    //     // Following error returned when trying to create content version as a community user. NetworkId is required but community may not be available yet.
    //     // INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY, You do not have the level of access necessary to perform the operation you requested. Please contact the owner of the record or your administrator if access is necessary.: [NetworkId]
    // }

    /**
     * @description Test file category sharing after update as student user
     */
    // @IsTest
    // static void testFileCategorySharingAfterUpdateAsStudentUser() {
    //     // Following error returned when trying to create content version as a community user. NetworkId is required but community may not be available yet.
    //     // INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY, You do not have the level of access necessary to perform the operation you requested. Please contact the owner of the record or your administrator if access is necessary.: [NetworkId]
    // }
}