/**
 * @author      WDCi (Lean)
 * @date        Aug 2023
 * @group       Utility
 * @description Error/Debug logging utility
 * @changehistory
 * 
 */
@NamespaceAccessible
public inherited sharing class REDU_Logging_UTIL {
    
    /**
     * @description Debug mode flag
     */
    final static boolean isDebugMode = REDU_AppSetting_UTIL.isDebugMode();

    /**
     * @description Print the system debug in logs for object
     * @param prefix Log prefix
     * @param anything Object to be serialized
     * @return void
     */
    @NamespaceAccessible
    public static void debugJsonString(String prefix, Object anything){
        if(isDebugMode){
            System.debug(prefix + ' ::');
            System.debug(JSON.serialize(anything));
        }
    }

    /**
     * @description Print the system debug in logs for object
     * @param prefix Log prefix
     * @param anything Object
     * @return void
     */
    @NamespaceAccessible
    public static void debug(String prefix, Object anything){
        if(isDebugMode){
            System.debug(prefix + ' ::');
            System.debug(anything);
        }
    }

    /**
     * @description Print the exception
     * @param exp Exception
     * @return void
     */
    @NamespaceAccessible
    public static void debug(Exception exp){
        if(isDebugMode){
            System.debug(exp.getMessage() + ' - ' + exp.getLineNumber() + ' - ' + exp.getStackTraceString());
        }
    }

    /**
     * @description Generate info log
     * @param logTitle Title
     * @param reference Reference
     * @param objectName Object name
     * @param recordId Record id
     * @param message Any message
     * @return void
     */
    @NamespaceAccessible
    public static void logInfo(String logTitle, String reference, String objectName, String recordId, String message){
        reduivy__Log__c newLog = initInfo(logTitle, reference, objectName, recordId, message);

        REDU_SystemMode_UTIL.doInsert(new List<reduivy__Log__c>{newLog});
    }

    /**
     * @description Init info log
     * @param logTitle Title
     * @param reference Reference
     * @param objectName Object name
     * @param recordId Record id
     * @param message Any message
     * @return reduivy__Log__c
     */
    @NamespaceAccessible
    public static reduivy__Log__c initInfo(String logTitle, String reference, String objectName, String recordId, String message){
        return initLog(logTitle, reference, objectName, recordId, LOG_Helper.TYPE_INFO, message, null);
    }

    /**
     * @description Generate warning log
     * @param logTitle Title
     * @param reference Reference
     * @param objectName Object name
     * @param recordId Record id
     * @param message Any message
     * @return void
     */
    @NamespaceAccessible
    public static void logWarning(String logTitle, String reference, String objectName, String recordId, String message){
        reduivy__Log__c newLog = initWarning(logTitle, reference, objectName, recordId, message);

        REDU_SystemMode_UTIL.doInsert(new List<reduivy__Log__c>{newLog});
    }

    /**
     * @description Init warning log
     * @param logTitle Title
     * @param reference Reference
     * @param objectName Object name
     * @param recordId Record id
     * @param message Any message
     * @return reduivy__Log__c
     */
    @NamespaceAccessible
    public static reduivy__Log__c initWarning(String logTitle, String reference, String objectName, String recordId, String message){
        return initLog(logTitle, reference, objectName, recordId, LOG_Helper.TYPE_WARNING, message, null);
    }

    /**
     * @description Generate error log
     * @param logTitle Title
     * @param reference Reference
     * @param objectName Object name
     * @param recordId Record id
     * @param message Any message
     * @param exp Exception
     * @return void
     */
    @NamespaceAccessible
    public static void logError(String logTitle, String reference, String objectName, String recordId, String message, Exception exp){
        reduivy__Log__c newLog = initError(logTitle, reference, objectName, recordId, message, exp);

        REDU_SystemMode_UTIL.doInsert(new List<reduivy__Log__c>{newLog});
    }

    /**
     * @description Init error log
     * @param logTitle Title
     * @param reference Reference
     * @param objectName Object name
     * @param recordId Record id
     * @param message Any message
     * @param exp Exception
     * @return reduivy__Log__c
     */
    @NamespaceAccessible
    public static reduivy__Log__c initError(String logTitle, String reference, String objectName, String recordId, String message, Exception exp){
        return initLog(logTitle, reference, objectName, recordId, LOG_Helper.TYPE_ERROR, message, exp);
    }

    /**
     * @description Generate log
     * @param logTitle Title
     * @param reference Reference
     * @param objectName Object name
     * @param recordId Record id
     * @param type Log type
     * @param message Any message
     * @param exp Exception
     * @return void
     */
    @NamespaceAccessible
    public static void createLog(String logTitle, String reference, String objectName, String recordId, String type, String message, Exception exp){

        reduivy__Log__c error = initLog(logTitle, reference, objectName, recordId, type, message, exp);

        REDU_SystemMode_UTIL.doInsert(new List<reduivy__Log__c>{error});
    }

    /**
     * @description Init log without inserting the record
     * @param logTitle Title
     * @param reference Reference
     * @param objectName Object name
     * @param recordId Record id
     * @param type Log type
     * @param message Any message
     * @param exp Exception
     * @return reduivy__Log__c
     */
    @NamespaceAccessible
    public static reduivy__Log__c initLog(String logTitle, String reference, String objectName, String recordId, String type, String message, Exception exp){

        Integer logShortDescFieldLength = Schema.SObjectType.reduivy__Log__c.fields.reduivy__Short_Description__c.getLength();
        Integer logDetailsFieldLength = Schema.SObjectType.reduivy__Log__c.fields.reduivy__Details__c.getLength();

        String shortDesc = '';
        String details = '';

        if (String.isNotBlank(message)) {
            shortDesc += message;
        }

        if (exp != null) {
            shortDesc += '\n\n' + exp.getMessage();
            details += exp.getStackTraceString();
        }

        reduivy__Log__c error = new reduivy__Log__c();
        error.Name = logTitle;
        error.reduivy__Reference__c = reference;
        error.reduivy__Object_Type__c = objectName;
        error.reduivy__Record_Id__c = recordId;
        error.reduivy__Type__c = type;
        error.reduivy__Short_Description__c = shortDesc.left(logShortDescFieldLength);
        error.reduivy__Details__c = details.left(logDetailsFieldLength);

        return error;

    }
	
    /**
     * @description Init async job started info log
     * @param jobOperation Title
     * @param reference Reference
     * @param classObj The class instance
     * @return reduivy__Log__c
     */
    @NamespaceAccessible
    public static reduivy__Log__c initAsyncJobStartedLog(String jobOperation, String reference, Object classObj){
        String title = String.format(Label.Job_Started_Log, new List<String>{jobOperation});
        String msg = String.format(Label.Processing_Records_Log_Details, new List<String>{String.valueOf(classObj)});

        return initLog(title, reference, null, null, LOG_Helper.TYPE_INFO, msg, null);
    }

    /**
     * @description Init async job completed info log
     * @param jobOperation Title
     * @param reference Reference
     * @param classObj The class instance
     * @return reduivy__Log__c
     */
    @NamespaceAccessible
    public static reduivy__Log__c initAsyncJobCompletedLog(String jobOperation, String reference, Object classObj){
        String title = String.format(Label.Job_Completed_Log_Title, new List<String>{jobOperation});
        String msg = String.format(Label.Processed_Records_Log_Details, new List<String>{String.valueOf(classObj)});

        return initLog(title, reference, null, null, LOG_Helper.TYPE_INFO, msg, null);
    }

    /**
     * @description Init async job completed with error log
     * @param jobOperation Title
     * @param reference Reference
     * @param classObj The class instance
     * @return reduivy__Log__c
     */
    @NamespaceAccessible
    public static reduivy__Log__c initAsyncJobCompletedWithErrorLog(String jobOperation, String reference, Object classObj){
        String title = String.format(Label.Job_Completed_With_Error_Log_Title, new List<String>{jobOperation});
        String msg = String.format(Label.Processed_Records_Log_Details, new List<String>{String.valueOf(classObj)});

        return initLog(title, reference, null, null, LOG_Helper.TYPE_ERROR, msg, null);
    }

    /**
     * @description Init async job failed with error log
     * @param jobOperation Title
     * @param reference Reference
     * @param classObj The class instance
     * @return reduivy__Log__c
     */
    @NamespaceAccessible
    public static reduivy__Log__c initAsyncJobFailedLog(String jobOperation, String reference, String message, Exception exp, Object classObj){
        String title = String.format(Label.Job_Failed_Log_Title, new List<String>{jobOperation});
        
        return initError(title, reference, null, null, Label.Error_Contact_Admin + ' ' + message + ' ' + String.valueOf(classObj), exp);
    }
}