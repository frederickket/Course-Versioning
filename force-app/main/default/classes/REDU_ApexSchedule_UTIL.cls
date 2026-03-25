/**
 * @author      WDCi (Lean)
 * @date        Aug 2023
 * @group       Utility
 * @description Apex scheduler utility
 * @changehistory
 * 
 */
@NamespaceAccessible
public inherited sharing class REDU_ApexSchedule_UTIL {
    
    /**
     * @description Schedule a schedulable job
     * @param jobName Unique job name
     * @param frequency Salesforce CRON expression e.g., 0 0 0 ? * * *
     * @param className Schedulable Apex class name
     * @param reschedule Abort the current job and reshedule a new instance
     * @param silent Silent the error if exception occurs when scheduling the job
     * @return String Job id
     */
    @NamespaceAccessible
	public static String scheduleJob(String jobName, String frequency, String className, Boolean reschedule, Boolean silent) {

        try {
            //Check if the job is already scheduled - CronJobDetail is the parent and CronTrigger is the child
            //Type '7' is for scheduled Apex
            List<CronTrigger> scheduledJobs = [SELECT Id, CronJobDetail.Id FROM CronTrigger
                WHERE CronJobDetail.Name = :jobName AND CronJobDetail.JobType = '7'
                WITH USER_MODE
            ];

            if (reschedule && !scheduledJobs.isEmpty()) {
                for (CronTrigger ct : scheduledJobs) {
                    System.abortJob(ct.Id);
                }
            }
            
            Type classType = Type.forName(className);

            if (classType != null) {
                Object instance = classType.newInstance();
                if (instance instanceof Schedulable) {
                    return System.schedule(jobName, frequency, (Schedulable)instance);
                }
            }
            
        } catch (Exception exp) {
            if (silent) {
                //failed silently but log a message to prevent the sched job from dying
                REDU_Logging_UTIL.debug(exp);
            } else {
                throw exp;
            }
        }

        return null;
    }
	
}