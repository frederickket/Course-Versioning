/**
 * @author      WDCi (Lean)
 * @date        Aug 2023
 * @group       License
 * @description Schedule job to invoke the license usage calculation batch job.
 * @changehistory
 * ISS-002574 04-08-2025 Lean - Decommission the applicant license type count
 */
public inherited sharing class REDU_License_SCHED implements Schedulable {

    /**
     * @description Schedulable execute method runs REDU_License_BATCH.
     */
    public void execute(SchedulableContext context) {

        try {
            //call the batch job
            REDU_License_BATCH adminLicenseJob = new REDU_License_BATCH(REDU_LicenseManagement_UTIL.ADMIN);
            Database.executeBatch(adminLicenseJob, 2000);

            REDU_License_BATCH studentLicenseJob = new REDU_License_BATCH(REDU_LicenseManagement_UTIL.STUDENT);
            Database.executeBatch(studentLicenseJob, 2000);

            REDU_License_BATCH facultyLicenseJob = new REDU_License_BATCH(REDU_LicenseManagement_UTIL.FACULTY);
            Database.executeBatch(facultyLicenseJob, 2000);
            
        } catch (Exception exp) {
            //failed silently but log a message to prevent the sched job from dying
            REDU_Logging_UTIL.logError('REDU_License_SCHED', 'REDU_License_SCHED', null, null, 'Problem initiating REDU_License_BATCH job.', exp);
        }
    }
}