/**
 * @author      WDCi (Lean)
 * @date        Dec 2023
 * @group       Trigger Executable
 * @description This is to link a newly create individual enrollment to a new or existing individual academic progress.
 * @changehistory
 * ISS-001816 Lean 20-12-2023 - New class
 * ISS-002743 XiRouh 20-11-2025 - Updated to link IAP based on Individual Academic Profile instead of primary profile
 */
public inherited sharing class IEN_AcademicProgress_EXE extends REDU_TriggerExecutable {
    
    /**
     * TODO: we may need to enhance this to handle continuing education ien in the future
     */

    /**
     * @description Individual program enrollment object label
     */
    private static final String CON_OBJECT_LABEL = CON_Helper.getObjectLabel();
    
    /**
     * @description Individual academic program object label
     */
    private static final String IPF_OBJECT_LABEL = IPF_Helper.getObjectLabel();

    /**
     * @description Individual enrollment student record type
     */
    private static final Id IEN_STUDENT_RTID = IEN_Helper.getStudentRecordTypeId();

    /**
     * @description Individual enrollment type
     */
    private static final String IEN_ENROLLMENTTYPE_PROGRAM = IEN_Helper.ENROLLMENT_TYPE_PROGRAM;
    
	/**
     * @description BeforeInsert
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeBeforeInsert(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {
        
        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {
            
            List<reduivy__Individual_Enrollment__c> workingIenList = new List<reduivy__Individual_Enrollment__c>();

            for (reduivy__Individual_Enrollment__c ien : (List<reduivy__Individual_Enrollment__c>) newList) {
                if (ien.RecordTypeId == IEN_STUDENT_RTID &&
                    ien.reduivy__Enrollment_Type__c == IEN_ENROLLMENTTYPE_PROGRAM &&
                    String.isNotBlank(ien.reduivy__Contact__c) &&
                    String.isNotBlank(ien.reduivy__Academic_Term_Id__c) &&
                    String.isNotBlank(ien.reduivy__Individual_Academic_Profile__c) &&
                    String.isBlank(ien.reduivy__Individual_Academic_Progress__c)
                ) {
                    workingIenList.add(ien);
                }
            }

            if (!workingIenList.isEmpty()) {
                setAcademicProgress(workingIenList);
            }
        }
    }

    /**
     * @description BeforeUpdate
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeBeforeUpdate(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {
        
        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {
            
            List<reduivy__Individual_Enrollment__c> workingIenList = new List<reduivy__Individual_Enrollment__c>();

            for (reduivy__Individual_Enrollment__c ien : (List<reduivy__Individual_Enrollment__c>) newList) {
                reduivy__Individual_Enrollment__c oldIen = (reduivy__Individual_Enrollment__c) oldMap.get(ien.Id);

                if (ien.RecordTypeId == IEN_STUDENT_RTID &&
                    ien.reduivy__Enrollment_Type__c == IEN_ENROLLMENTTYPE_PROGRAM &&
                    String.isNotBlank(ien.reduivy__Contact__c) &&
                    String.isNotBlank(ien.reduivy__Individual_Academic_Profile__c) &&
                    (
                        (String.isNotBlank(ien.reduivy__Academic_Term_Id__c) && ien.reduivy__Academic_Term_Id__c != oldIen.reduivy__Academic_Term_Id__c) ||
                        (String.isBlank(ien.reduivy__Individual_Academic_Progress__c) && ien.reduivy__Individual_Academic_Progress__c != oldien.reduivy__Individual_Academic_Progress__c) ||
                        (ien.reduivy__Individual_Academic_Profile__c != oldIen.reduivy__Individual_Academic_Profile__c)
                    )
                ) {
                    workingIenList.add(ien);
                }
            }

            if (!workingIenList.isEmpty()) {
                setAcademicProgress(workingIenList);
            }
        }
    }

    /**
     * @description Set the individual enrollment with individual academic progress
     * @param ienList list of individual enrollment
     * @return void
     */
    private void setAcademicProgress(List<reduivy__Individual_Enrollment__c> ienList) {

        Set<Id> stmIds = new Set<Id>();
        Set<Id> ipfIds = new Set<Id>();

        Map<String, List<reduivy__Individual_Enrollment__c>> ienByIpfTermMap = new Map<String, List<reduivy__Individual_Enrollment__c>>();
        for (reduivy__Individual_Enrollment__c ien : ienList) {
            if (String.isNotBlank(ien.reduivy__Academic_Term_Id__c) && 
                String.isNotBlank(ien.reduivy__Individual_Academic_Profile__c)) {
                
                stmIds.add(ien.reduivy__Academic_Term_Id__c);
                ipfIds.add(ien.reduivy__Individual_Academic_Profile__c);

                String ipfStmKey = getIpfStmKey(ien.reduivy__Individual_Academic_Profile__c, ien.reduivy__Academic_Term_Id__c);

                if (ienByIpfTermMap.containsKey(ipfStmKey)) {
                    ienByIpfTermMap.get(ipfStmKey).add(ien);
                } else {
                    ienByIpfTermMap.put(ipfStmKey, new List<reduivy__Individual_Enrollment__c>{ien});
                }
            }
        }

        // Get the existing individual academic progress for the IPF and academic term
        Map<String, reduivy__Individual_Academic_Progress__c> iprByIpfTermMap = new Map<String, reduivy__Individual_Academic_Progress__c>();
        for (reduivy__Individual_Academic_Progress__c ipr : [SELECT Id,
            reduivy__Contact__c,
            reduivy__Academic_Term__c,
            reduivy__Individual_Academic_Profile__c
            FROM reduivy__Individual_Academic_Progress__c
            WHERE reduivy__Individual_Academic_Profile__c IN: ipfIds
            AND reduivy__Academic_Term__c IN: stmIds
            WITH USER_MODE
            ORDER BY CreatedDate DESC
        ]) {
            String ipfStmKey = getIpfStmKey(ipr.reduivy__Individual_Academic_Profile__c, ipr.reduivy__Academic_Term__c);

            if (!iprByIpfTermMap.containsKey(ipfStmKey)) {
                iprByIpfTermMap.put(ipfStmKey, ipr);
            }
        }

        Map<String, reduivy__Individual_Academic_Progress__c> newIprMap = new Map<String, reduivy__Individual_Academic_Progress__c>();

        for (String ipfStmKey : ienByIpfTermMap.keySet()) {
            for (reduivy__Individual_Enrollment__c ien : ienByIpfTermMap.get(ipfStmKey)) {

                if (!iprByIpfTermMap.containsKey(ipfStmKey)) {
                    // Create a new individual academic progress record for this IPF + Term combination
                    //TODO: we won't be able to map the recommended credits and max credits here as we don't have the info
                    reduivy__Individual_Academic_Progress__c newIpr = new reduivy__Individual_Academic_Progress__c(
                        reduivy__Contact__c = ien.reduivy__Contact__c,
                        reduivy__Individual_Academic_Profile__c = ien.reduivy__Individual_Academic_Profile__c,
                        reduivy__Academic_Term__c = ien.reduivy__Academic_Term_Id__c
                    );

                    iprByIpfTermMap.put(ipfStmKey, newIpr);
                    newIprMap.put(ipfStmKey, newIpr);
                }
            }
        }

        // Create new individual academic progress record
        REDU_Database_UTIL.doInsert(newIprMap, ienByIpfTermMap, false);

        // Associate the ien to ipr
        for (String ipfStmKey : ienByIpfTermMap.keySet()) {
            if (iprByIpfTermMap.containsKey(ipfStmKey)) {
                for (reduivy__Individual_Enrollment__c ien : ienByIpfTermMap.get(ipfStmKey)) {
                    ien.reduivy__Individual_Academic_Progress__c = iprByIpfTermMap.get(ipfStmKey).Id;
                }
            }
        }
    }

    /**
     * @description Return Individual Academic Profile + academic term id key
     * @param ipfId Individual Academic Profile Id
     * @param academicTermId Academic Term Id
     * @return String
     */
    private String getIpfStmKey(Id ipfId, Id academicTermId) {
        return ipfId + '_' + academicTermId;
    }
	
}