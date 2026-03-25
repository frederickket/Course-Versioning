/**
 * @author      WDCi (Lean)
 * @date        Aug 2024
 * @group       Object Helper
 * @description Organization object helper class that contains the picklist option constants and object related methods
 * @changehistory
 * 
 */
global inherited sharing class ORG_Helper implements SObject_Helper {
    
    /**
     * @description salesforce org domain url param - domainUrl
     */
    public static final String DOMAIN_URL_PARAM = 'domainUrl';

    /**
     * @description current request url param - currentRequestUrl
     */
    public static final String CURRENT_REQUEST_URL_PARAM = 'currentRequestUrl';

    /**
     * @description site path prefix  param - sitePathPrefix
     */
    public static final String SITE_PATH_PREFIX_PARAM = 'sitePathPrefix';

    /**
     * @description site path param - sitePath
     */
    public static final String SITE_PATH_PARAM = 'sitePath';

    /**
     * @description site id param - siteId
     */
    public static final String SITE_ID_PARAM = 'siteId';

    /**
     * @description site base url param - siteBaseUrl
     */
    public static final String SITE_BASE_URL_PARAM = 'siteBaseUrl';

    /**
     * @description network id param - networkId
     */
    public static final String NETWORK_ID_PARAM = 'networkId';

    /**
     * @description site login url param - loginUrl
     */
    public static final String LOGIN_URL_PARAM = 'loginUrl';

    /**
     * @description is community param - isCommunity
     */
    public static final String IS_COMMUNITY_PARAM = 'isCommunity';

    /**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel() {
        return SObjectType.Organization.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel() {
        return SObjectType.Organization.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName() {
        return SObjectType.Organization.getName();
    }

    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.Organization);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }

    /**
     * @description Checks if this component is running in a community, this changes which image is displayed
     * @return Boolean
     */
    public static Boolean isCommunity(){
        
        Id nwId = Network.getNetworkId(); // take a look at the apex class Site
        if (nwId != null) {
            return true;
        }
        return false;
    }

    /**
     * @description ISS-001147 Get community site path url e.g, /portal/s > /portal
     * @return String
     */
    public static String getCurrentCommunitySitePath(){
        
        return Site.getPathPrefix().removeEndIgnoreCase('/s');
    }

    /**
     * @description Get community info
     * @return Map<String, Object>
     */
    public static Map<String, Object> getCommunityInfo() {

        // sample for internal
        // {
        //     "isCommunity": false,
        //     "loginUrl": null,
        //     "networkId": null,
        //     "siteBaseUrl": "",
        //     "siteId": null,
        //     "sitePath": "",
        //     "sitePathPrefix": "",
        //     "currentRequestUrl": "https://efficiency-computing-1300-dev-ed.scratch.my.salesforce.com/aura?r=78&aura.ApexAction.execute=1",
        //     "domainUrl": "https://efficiency-computing-1300-dev-ed.scratch.my.salesforce.com"
        // }

        // sample for digital experience
        // {
        //     "isCommunity": true,
        //     "loginUrl": "https://efficiency-computing-1300-dev-ed.scratch.my.site.com/portal/s/login",
        //     "networkId": "0DBxxx",
        //     "siteBaseUrl": "https://efficiency-computing-1300-dev-ed.scratch.my.site.com/portal",
        //     "siteId": "0DMxxx",
        //     "sitePath": "/portal",
        //     "sitePathPrefix": "/portal/s",
        //     "currentRequestUrl": "https://efficiency-computing-1300-dev-ed.scratch.my.site.com/portal/sfsites/aura?r=31&aura.ApexAction.execute=1",
        //     "domainUrl": "https://efficiency-computing-1300-dev-ed.scratch.my.salesforce.com"
        // }

        Map<String, Object> communityInfo = new Map<String, Object>();
        communityInfo.put(DOMAIN_URL_PARAM, URL.getOrgDomainUrl().toExternalForm());
        communityInfo.put(CURRENT_REQUEST_URL_PARAM, URL.getCurrentRequestUrl().toExternalForm());
        communityInfo.put(SITE_PATH_PREFIX_PARAM, Site.getPathPrefix());
        communityInfo.put(SITE_PATH_PARAM, ORG_Helper.getCurrentCommunitySitePath());
        communityInfo.put(SITE_ID_PARAM, Site.getSiteId());
        communityInfo.put(SITE_BASE_URL_PARAM, Site.getBaseUrl());
        communityInfo.put(NETWORK_ID_PARAM, Network.getNetworkId());
        communityInfo.put(LOGIN_URL_PARAM, Network.getLoginUrl(Network.getNetworkId()));
        communityInfo.put(IS_COMMUNITY_PARAM, ORG_Helper.isCommunity());

        REDU_Logging_UTIL.debugJsonString('ORG_Helper.getCommunityInfo', communityInfo);
        return communityInfo;
    }

    /**
     * @description Test mode only. This is to simulate the multi currencies enablement for test class assertion purposes only.
     */
    @TestVisible
    public static Boolean testSimulateMultiCurrencies = false;

    /**
     * @description Return true if multi currencies is enabled
     */
    public static Boolean isMultiCurrenciesOrg() {

        if (testSimulateMultiCurrencies) {
            return true;
        }

        return UserInfo.isMultiCurrencyOrganization();
    }
}