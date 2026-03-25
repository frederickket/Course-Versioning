/**
 * @author      WDCi (Lean)
 * @date        Aug 2023
 * @group       License
 * @description To validate the user type and custom permission for RIO Education Ivy classes.
 * @changehistory
 * ISS-001978 24-06-2024  Xirouh - add guest permission
 */
@NamespaceAccessible
public inherited sharing class REDU_Permission_UTIL {
    
    /**
     * @description UserPermission enum: ADMIN, FACULTY, STUDENT, GUEST, REDUUSER
     */
    @NamespaceAccessible
    public enum UserPermission {ADMIN, FACULTY, STUDENT, GUEST, REDUUSER}

    /**
     * @description check user permission (e.g, admin, student, faculty and guest)
     * @return boolean
     */
    @NamespaceAccessible
    public static boolean hasPermission(REDU_Permission_UTIL.UserPermission usrPerm){
        
        switch on usrPerm {
           when ADMIN {
               return FeatureManagement.checkPermission(REDU_LicenseManagement_UTIL.ADMIN);
           }
           when FACULTY {
               return FeatureManagement.checkPermission(REDU_LicenseManagement_UTIL.FACULTY);
           }
           when STUDENT {
               return FeatureManagement.checkPermission(REDU_LicenseManagement_UTIL.STUDENT);
           }
           when REDUUSER {
               if(FeatureManagement.checkPermission(REDU_LicenseManagement_UTIL.ADMIN) || FeatureManagement.checkPermission(REDU_LicenseManagement_UTIL.FACULTY) || FeatureManagement.checkPermission(REDU_LicenseManagement_UTIL.STUDENT)){
                   return true;
               } else {
                   return false;
               }
           }
           when GUEST {
               if(UserInfo.getUserType() == 'Guest' || FeatureManagement.checkPermission(REDU_LicenseManagement_UTIL.GUEST)){
                   return true;
               }
           }
           
           when else {
               return false;
           }
        }

        return false;
    }
	
}