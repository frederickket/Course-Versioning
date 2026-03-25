/**
 * @author      WDCi (Lean)
 * @date        Aug 2023
 * @group       Utility
 * @description Exception utility
 * @changehistory
 * 
 */
@NamespaceAccessible
public inherited sharing class REDU_Exception_UTIL {
    
    /**
     * @param message Error message
     * @return AuraHandledException
     */
    @NamespaceAccessible
    public static AuraHandledException auraException(String message){

        String errorMsg = contructErrorMessage(message, null, null);

        AuraHandledException ahe = new AuraHandledException(errorMsg);
        ahe.setMessage(errorMsg);

        return ahe;
    }

    /**
     * @param exp Exception
     * @return AuraHandledException
     */
    @NamespaceAccessible
    public static AuraHandledException auraException(Exception exp){

        String errorMsg = contructErrorMessage(exp.getMessage(), exp.getLineNumber(), exp.getStackTraceString());

        AuraHandledException ahe = new AuraHandledException(errorMsg);
        ahe.setMessage(errorMsg);

        return ahe;
    }

    /**
     * @param message Error message
     * @param lineNumber Line number
     * @param stackTrace Strack trace
     * @return AuraHandledException
     */
    @NamespaceAccessible
    public static AuraHandledException auraException(String message, Integer lineNumber, String stackTrace){

        String errorMsg = contructErrorMessage(message, lineNumber, stackTrace);

        AuraHandledException ahe = new AuraHandledException(errorMsg);
        ahe.setMessage(errorMsg);

        return ahe;
    }

    /**
     * @param message Error message
     * @param lineNumber Line number
     * @param stackTrace Strack trace
     * @return String
     */
    private static String contructErrorMessage(String message, Integer lineNumber, String stackTrace){

        message = REDU_Database_UTIL.cleanseErrorMessage(message);

        String errorMsg = '';
        if(String.isNotBlank(message)){
            errorMsg += message;
        }

        if(lineNumber != null){
            errorMsg += ': ' + lineNumber;
        }

        if(String.isNotBlank(stackTrace)){
            errorMsg += ' - ' + stackTrace;
        }

        return errorMsg;
    }

    /**
     * @param exp Exception
     * @return String string of error JSON object
     */
    @NamespaceAccessible
    public static String initExceptionError(Exception exp) {
        //ISS-000977
        Map<String, Object> errorMap = new Map<String, Object>();
        errorMap.put('lineNumber', exp.getLineNumber());
        errorMap.put('message', exp.getMessage());
        errorMap.put('stackTraceString', exp.getStackTraceString());

        return JSON.serialize(errorMap);
    }
}