/**
 * @author      WDCi (Lean)
 * @date        Aug 2023
 * @group       License
 * @description RIO Education V4 license management utility
 * @changehistory
 * ISS-001858 19-03-2024 VTan - Introduce new feature parameter and get set method.
 * ISS-001978 24-06-2024  Xirouh - add guest permission
 * ISS-002574 04-08-2025 Lean - Decommission the applicant license type count
 */
public without sharing class REDU_LicenseManagement_UTIL {

    /**
     * @description A placeholder figure for number of licenses. This will be used if the organisation type is 'Developer Edition'
     */
    private final static Integer NO_OF_LICENSE_PLACEHOLDER = -1;
    
    /**
     * @description Custom Permission - REDU_Admin
     */
	public final static String ADMIN = 'REDU_Admin';

    /**
     * @description Custom Permission - REDU_Student
     */
    public final static String STUDENT = 'REDU_Student';

    /**
     * @description Custom Permission - REDU_Faculty
     */
    public final static String FACULTY = 'REDU_Faculty';

    /**
     * @description Custom Permission - REDU_Guest
     */
    public final static String GUEST = 'REDU_Guest';

    /**
     * @description Obsolete - Feature Parameter - REDU_Applicant_Used_Licenses
     */
    public final static String FEATURE_PARAM_APPLICANTTOTALUSED = 'REDU_Applicant_Used_Licenses';

    /**
     * @description Obsolete - Feature Parameter - REDU_Applicant_Total_Licenses
     */
    public final static String FEATURE_PARAM_APPLICANTTOTALLICENSE = 'REDU_Applicant_Total_Licenses';
    
    /**
     * @description Feature Parameter - REDU_Student_Total_Licenses
     */
    public final static String FEATURE_PARAM_STUDENTTOTALLICENSE = 'REDU_Student_Total_Licenses';

    /**
     * @description Feature Parameter - REDU_Student_Used_Licenses
     */
    public final static String FEATURE_PARAM_STUDENTTOTALUSED = 'REDU_Student_Used_Licenses';

    /**
     * @description Feature Parameter - REDU_Admin_Total_Licenses
     */
    public final static String FEATURE_PARAM_ADMINTOTALLICENSE = 'REDU_Admin_Total_Licenses';

    /**
     * @description Feature Parameter - REDU_Admin_Used_Licenses
     */
    public final static String FEATURE_PARAM_ADMINTOTALUSED = 'REDU_Admin_Used_Licenses';
    
    /**
     * @description Feature Parameter - REDU_Faculty_Total_Licenses
     */
    public final static String FEATURE_PARAM_FACULTYTOTALLICENSE = 'REDU_Faculty_Total_Licenses'; 
    
    /**
     * @description Feature Parameter - REDU_Faculty_Used_Licenses
     */
    public final static String FEATURE_PARAM_FACULTYTOTALUSED = 'REDU_Faculty_Used_Licenses';

    /**
     * @description Feature Parameter - Continuing_Ed_Feature_Enabled
     */
    public final static String FEATURE_PARAM_CONTINUINGEDFEATUREENABLED = 'CE_Feature';

    /**
     * @description Feature Parameter - Full_Suite_Feature
     */
    public final static String FEATURE_PARAM_FULLSUITEENABLED = 'Full_Suite_Feature';

    /**
     * @description Return the number of student licenses subscribed from LMO
     * @return Integer
     */
    public static Integer getReduStudentLicensesSubscribed() {

        return FeatureManagement.checkPackageIntegerValue(FEATURE_PARAM_STUDENTTOTALLICENSE);
    }

    /**
     * @description Return the number of faculty licenses subscribed from LMO
     * @return Integer
     */
    public static Integer getReduFacultyLicensesSubscribed() {
        
        return FeatureManagement.checkPackageIntegerValue(FEATURE_PARAM_FACULTYTOTALLICENSE);
    }

    /**
     * @description Return the number of admin licenses subscribed from LMO
     * @return Integer
     */
    public static Integer getReduAdminLicensesSubscribed() {
        
        return FeatureManagement.checkPackageIntegerValue(FEATURE_PARAM_ADMINTOTALLICENSE);
    }

    /**
     * @description Set the number of student licenses used
     * @param usersCount
     * @return void
     */
    public static void setStudentUsedLicense(Integer usersCount) {
        
        FeatureManagement.setPackageIntegerValue(FEATURE_PARAM_STUDENTTOTALUSED, usersCount);
    }

    /**
     * @description Set the number of faculty licenses used
     * @param usersCount
     * @return void
     */
    public static void setFacultyUsedLicense(Integer usersCount) {

        FeatureManagement.setPackageIntegerValue(FEATURE_PARAM_FACULTYTOTALUSED, usersCount);
    }

    /**
     * @description Set the number of admin licenses used
     * @param usersCount
     * @return void
     */
    public static void setAdminUsedLicense(Integer usersCount) {

        FeatureManagement.setPackageIntegerValue(FEATURE_PARAM_ADMINTOTALUSED, usersCount);
    }

    /**
     * @description Return the number of student licenses used
     * @return Integer
     */
    public static Integer getReduStudentLicensesUsed() {

        return FeatureManagement.checkPackageIntegerValue(FEATURE_PARAM_STUDENTTOTALUSED);
    }

    /**
     * @description Return the number of faculty licenses used
     * @return Integer
     */
    public static Integer getReduFacultyLicensesUsed() {

        return FeatureManagement.checkPackageIntegerValue(FEATURE_PARAM_FACULTYTOTALUSED);
    }

    /**
     * @description Return the number of admin licenses used
     * @return Integer
     */
    public static Integer getReduAdminLicensesUsed() {

        return FeatureManagement.checkPackageIntegerValue(FEATURE_PARAM_ADMINTOTALUSED);
    }

    /**
     * @description Schedule the license checking job to run on every 12AM every sunday
     * @param reschedule True to delete the existing schedule and reschedule a new one
     * @param silent True to ignore exception/error
     * @return void
     */
    public static void initLicenseCheckJob(Boolean reschedule, Boolean silent) {

        String scheduleJobFrequency = REDU_AppSetting_UTIL.getLicenseScheduleJobFrequency();
        REDU_ApexSchedule_UTIL.scheduleJob('REDU_License_SCHED', scheduleJobFrequency, 'reduivy.REDU_License_SCHED', reschedule, silent);
    }

    /**
     * @description Return true if the continuing education feature is enabled in LMO
     * @return Boolean
     */
    public static boolean isContinuingEdFeatureEnabled() {

        return FeatureManagement.checkPackageBooleanValue(FEATURE_PARAM_CONTINUINGEDFEATUREENABLED);
    }

    /**
     * @description Validate if the continuing education feature is enabled in LMO
     * @return Boolean
     */
    public static void validateContinuingEdFeatureLicense() {

        if (!isContinuingEdFeatureEnabled() && getOrgInfo().OrganizationType != 'Developer Edition') {
            throw new REDU_ApplicationException(Label.Continuing_Education_Feature_License_Required);
        }
    }

    /**
     * @description Return true if the RIO Ed full suite feature is enabled in LMO
     * @return Boolean
     */
    public static boolean isFullSuiteFeatureEnabled() {

        return FeatureManagement.checkPackageBooleanValue(FEATURE_PARAM_FULLSUITEENABLED);
    }

    /**
     * @description Validate if the RIO Ed full suite feature is enabled in LMO
     * @return Boolean
     */
    public static void validateFullSuiteFeatureLicense() {

        if (!isFullSuiteFeatureEnabled() && getOrgInfo().OrganizationType != 'Developer Edition') {
            throw new REDU_ApplicationException(Label.Full_Suite_Feature_License_Required);
        }
    }

    /**
     * @description Salesforce organization
     */
    public static Organization orgInfo;

    /**
     * @description Return current salesforce organization info such as Id and OrganizationType
     * @return Organization
     */
    public static Organization getOrgInfo() {
        if(orgInfo == null) {
            orgInfo = [SELECT Id, OrganizationType FROM Organization WHERE Id =: UserInfo.getOrganizationId() WITH SYSTEM_MODE];
        }

        return orgInfo;
    }
}