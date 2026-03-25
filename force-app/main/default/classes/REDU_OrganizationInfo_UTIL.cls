/**
 * @author      WDCi (Lean)
 * @date        Dec 2023
 * @group       Utility
 * @description Salesforce organization/instance utility
 * @changehistory
 * ISS-001816 20-12-2023 Lean - new utility
 */
@NamespaceAccessible
public inherited sharing class REDU_OrganizationInfo_UTIL {
    
	/**
     * @description Organization info
     */
    private static Organization orgInfo;

    /**
     * @description Query the organization info like OrganizationType
     * @return Organization
     */
    @NamespaceAccessible
    public static Organization getOrgInfo() {
        if(orgInfo == null) {
            orgInfo = [SELECT Id, OrganizationType FROM Organization WHERE Id =: UserInfo.getOrganizationId() WITH SYSTEM_MODE];
        }

        return orgInfo;
    }

    /**
     * @description Sandbox indicator
     */
    private static Boolean runningInASandbox;

    /**
     * @description To identify if the current instance is a sandbox or production org
     * @return Boolean
     */
    @NamespaceAccessible
    public static Boolean isSandbox() {

        if (runningInASandbox == null) {
            System.Domain domain = System.DomainParser.parse(URL.getOrgDomainUrl());
            runningInASandbox = domain.getSandboxName() == null ? false : true;
        }

        return runningInASandbox;
    }

    /**
     * @description Instance base url
     */
    private static String domainUrl;

    /**
     * @description Return the domain url
     * @return String
     */
    @NamespaceAccessible
    public static String getDomainUrl() {

        if (String.isBlank(domainUrl)) {
            domainUrl = URL.getOrgDomainUrl().toExternalForm() + '/';
        }

        return domainUrl;
    }

}