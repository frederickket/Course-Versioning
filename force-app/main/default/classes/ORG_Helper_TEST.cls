/**
 * @author      WDCi (Lean)
 * @date        Aug 2024
 * @group       Test
 * @description Test class for QFA_Helper
 * @changehistory
 */
@IsTest
public inherited sharing class ORG_Helper_TEST {
    
    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
    
    @TestSetup
    static void makeData(){
        
    }

    /**
     * @description Test object helper method
     */
    @IsTest
    static void testObjectHelper(){
        
        Test.startTest();
        
        System.Assert.areEqual(SObjectType.Organization.getLabel(), ORG_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.Organization.getLabelPlural(), ORG_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.Organization.getName(), ORG_Helper.getApiName());

        System.Assert.isFalse(ORG_Helper.isCommunity(), 'This should be null as we are not running in community context.');
        System.Assert.isTrue(String.isBlank(ORG_Helper.getCurrentCommunitySitePath()), 'This should be null as we are not running in community context.');
        
        Map<String, Object> communityInfo = ORG_Helper.getCommunityInfo();
        System.Assert.areEqual(URL.getOrgDomainUrl().toExternalForm(), communityInfo.get(ORG_Helper.DOMAIN_URL_PARAM));
        System.Assert.areEqual(URL.getCurrentRequestUrl().toExternalForm(), communityInfo.get(ORG_Helper.CURRENT_REQUEST_URL_PARAM));
        System.Assert.areEqual(Site.getPathPrefix(), communityInfo.get(ORG_Helper.SITE_PATH_PREFIX_PARAM));
        System.Assert.areEqual(ORG_Helper.getCurrentCommunitySitePath(), communityInfo.get(ORG_Helper.SITE_PATH_PARAM));
        System.Assert.areEqual(Site.getSiteId(), communityInfo.get(ORG_Helper.SITE_ID_PARAM));
        System.Assert.areEqual(Site.getBaseUrl(), communityInfo.get(ORG_Helper.SITE_BASE_URL_PARAM));
        System.Assert.areEqual(Network.getNetworkId(), communityInfo.get(ORG_Helper.NETWORK_ID_PARAM));
        System.Assert.areEqual(Network.getLoginUrl(Network.getNetworkId()), communityInfo.get(ORG_Helper.LOGIN_URL_PARAM));
        System.Assert.areEqual(ORG_Helper.isCommunity(), communityInfo.get(ORG_Helper.IS_COMMUNITY_PARAM));

        Test.stopTest();
        
    }

}