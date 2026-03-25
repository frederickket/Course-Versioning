/**
 * @author      WDCi (Lean)
 * @date        Dec 2023
 * @group       Test
 * @description Test class for REDU_OrganizationInfo_UTIL
 * @changehistory
 * ISS-001816 20-12-2023 Lean - new class
 */
@IsTest
public inherited sharing class REDU_OrganizationInfo_TEST extends REDU_TriggerExecutable {
    
    /**
     * @description Test running in sandbox
     */
    @IsTest
    static void testRunningInASandbox(){

        Test.startTest();

        System.Domain domain = System.DomainParser.parse(URL.getOrgDomainUrl());
        Boolean runningInASandbox = domain.getSandboxName() == null ? false : true;

        Boolean sandboxCheck = REDU_OrganizationInfo_UTIL.isSandbox();

        System.Assert.areEqual(runningInASandbox, sandboxCheck);

        Test.stopTest();
        
    }

    /**
     * @description Test the get domain url
     */
    @IsTest
    static void testDomainUrl(){
        
        Test.startTest();
        
        System.Assert.areEqual(URL.getOrgDomainUrl().toExternalForm() + '/', REDU_OrganizationInfo_UTIL.getDomainUrl());

        Test.stopTest();
        
    }
	
}