/**
 * @author      WDCi (XW)
 * @date        Feb 2025
 * @group       Object Helper
 * @description System Variable object helper class that contains the System variable key
 * @changehistory
 * ISS-002089 12-02-2025 XW - new class
 */
global inherited sharing class SYV_Helper implements SObject_Helper{
    
    /**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel() {
        return SObjectType.reduivy__System_Variable__c.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel() {
        return SObjectType.reduivy__System_Variable__c.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName() {
        return SObjectType.reduivy__System_Variable__c.getName();
    }
    
    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.reduivy__System_Variable__c);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }

    /**
     * @description Generic method to generate IDs, and update the number after generated the Ids
     * @param  numberOfRecords Number of records that are applying for ids
     * @param  syvKey          syvKey System Variable Key (eg: KEY_STUDENT_ID)
     * @return                 List of generated Ids
     */
    @NamespaceAccessible
    public static List<String> generateSequenceNumber(Integer numberOfRecords, String syvKey){

        if(numberOfRecords == 0 || String.isBlank(syvKey)){
            return new List<String>();
        }

        List<String> generatedIdsList = new List<String>();

        Set<String> syvFields = new Set<String>{
            'Id',
            'Name',
            'reduivy__Format__c',
            'reduivy__Number__c'
        };

        Map<String, Object> syvParams = new Map<String, Object>{
            'syvKey' => syvKey
        };

        String syvSoql = 'SELECT ' + String.join(syvFields, ', ') + ' FROM reduivy__System_Variable__c WHERE Name = :syvKey LIMIT 1 FOR UPDATE';
        
        Map<String, Set<String>> objectFields = new Map<String, Set<String>>();
        objectFields.put(SYV_Helper.getApiName(), syvFields);

        reduivy__System_Variable__c syv;
        for(reduivy__System_Variable__c soqlSyv : (List<reduivy__System_Variable__c>) REDU_SystemMode_UTIL.doQuery(syvSoql, syvParams, objectFields)) {
            syv = soqlSyv;
        }
        
        if(syv == null) {
            String error = String.format(Label.System_Variable_Not_Found, new List<String>{syvKey});
            throw new REDU_ApplicationException(error);
        }

        //extract strings enclosed with {}
        Map<String, String> extractedResult = REDU_StringMerge_UTIL.extractFieldNames(null, syv.reduivy__Format__c);
        if(extractedResult.isEmpty()){
            String error = String.format(Label.System_Variable_Invalid_Formatted_String, new List<String>{syv.reduivy__Format__c});
            throw new REDU_ApplicationException(error);
        }
        
        //pad the first character within the {}
        String sequenceNumberKey = extractedResult.values()[0];
        String charToPad = sequenceNumberKey.substring(0,1);

        //format the id with sequence number
        for(Integer i = 0; i < numberOfRecords; i++) {   
            syv.reduivy__Number__c++;
            String currentFormattedSegment = String.valueOf(syv.reduivy__Number__c).leftPad(sequenceNumberKey.length(), charToPad);
            extractedResult.put(sequenceNumberKey, currentFormattedSegment);
            String newId = REDU_StringMerge_UTIL.mergeValues(extractedResult, syv.reduivy__Format__c);
            generatedIdsList.add(newId);
        }

        REDU_SystemMode_UTIL.doUpdate(new List<reduivy__System_Variable__c> {syv});
        
        return generatedIdsList;

    }
}