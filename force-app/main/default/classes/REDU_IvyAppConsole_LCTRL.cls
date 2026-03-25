/**
 * @author      WDCi (Lean)
 * @date        Mar 2024
 * @group       Administration
 * @description Admin console for RIO Education Ivy
 * @changehistory
 * ISS-001858 22-03-2024 Lean - new class
 * ISS-002574 04-08-2025 Lean - Decommission the applicant license type count
 */
public with sharing class REDU_IvyAppConsole_LCTRL {
    
    /**
     * @description Init license schedule job
     * @return REDU_LightningResponse
     */
    @AuraEnabled
    public static REDU_LightningResponse initLicenseJob(){

        try {
            REDU_LicenseManagement_UTIL.initLicenseCheckJob(true, false);
            return new REDU_LightningResponse(true, 'success', null);

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    /**
     * @description Get license info by license type
     * @param licenseType
     * @return REDU_LightningResponse
     */
    @AuraEnabled
    public static REDU_LightningResponse getLicensesInfo(String licenseType){
        try {
            Map<String, Object> responseData = new Map<String, Object>();

            Integer totalLicenses;
            Integer usedLicenses;

            if (licenseType == REDU_LicenseManagement_UTIL.ADMIN) {
                totalLicenses = REDU_LicenseManagement_UTIL.getReduAdminLicensesSubscribed();
                usedLicenses = REDU_LicenseManagement_UTIL.getReduAdminLicensesUsed();

            } else if (licenseType == REDU_LicenseManagement_UTIL.STUDENT) {
                totalLicenses = REDU_LicenseManagement_UTIL.getReduStudentLicensesSubscribed();
                usedLicenses = REDU_LicenseManagement_UTIL.getReduStudentLicensesUsed();

            } else if (licenseType == REDU_LicenseManagement_UTIL.FACULTY) {
                totalLicenses = REDU_LicenseManagement_UTIL.getReduFacultyLicensesSubscribed();
                usedLicenses = REDU_LicenseManagement_UTIL.getReduFacultyLicensesUsed();

            }

            responseData.put('totalLicenses', totalLicenses);
            responseData.put('usedLicenses', usedLicenses);

            return new REDU_LightningResponse(true, 'success', JSON.serialize(responseData));

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }
}