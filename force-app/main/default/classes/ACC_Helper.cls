/**
 * @author      WDCi (Lean)
 * @date        July 2023
 * @group       Object Helper
 * @description Account object helper class that contains the picklist option constants and object related methods
 * @changehistory
 * 
 */
global inherited sharing class ACC_Helper implements SObject_Helper {
    
    /**
     * @description Status - Active
     */
    public static final String STATUS_ACTIVE = 'Active';

    /**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel() {
        return SObjectType.Account.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel() {
        return SObjectType.Account.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName() {
        return SObjectType.Account.getName();
    }

    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.Account);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }

    /**
     * @description RecordTypeInfo map
     */
    private static Map<String, Schema.RecordTypeInfo> rtMap;

    /**
     * @description Return record type map by developername
     * @return Map<String, Schema.RecordTypeInfo>
     */
    global static Map<String, Schema.RecordTypeInfo> getRecordTypes() {
        if (rtMap == null) {
            rtMap = Schema.SObjectType.Account.getRecordtypeInfosByDeveloperName();
        }

        return rtMap;
    }

    /**
     * @description Return administrative record type id
     * @return Id
     */
    global static Id getAdministrativeRecordTypeId() {
        return getRecordTypes().get('Administrative').getRecordTypeId();
    }

    /**
     * @description Return administrative record type UI label
     * @return String
     */
    global static String getAdministrativeRecordTypeLabel() {
        return getRecordTypes().get('Administrative').getName();
    }

    /**
     * @description Return campus record type id
     * @return Id
     */
    global static Id getCampusRecordTypeId() {
        return getRecordTypes().get('Campus').getRecordTypeId();
    }

    /**
     * @description Return Campus record type UI label
     * @return String
     */
    global static String getCampusRecordTypeLabel() {
        return getRecordTypes().get('Campus').getName();
    }

    /**
     * @description Return department record type id
     * @return Id
     */
    global static Id getDepartmentRecordTypeId() {
        return getRecordTypes().get('Department').getRecordTypeId();
    }

    /**
     * @description Return Department record type UI label
     * @return String
     */
    global static String getDepartmentRecordTypeLabel() {
        return getRecordTypes().get('Department').getName();
    }

    /**
     * @description Return educational institution record type id
     * @return Id
     */
    global static Id getEducationalInstitutionRecordTypeId() {
        return getRecordTypes().get('Educational_Institution').getRecordTypeId();
    }

    /**
     * @description Return Educational Institution record type UI label
     * @return String
     */
    global static String getEducationalInstitutionRecordTypeLabel() {
        return getRecordTypes().get('Educational_Institution').getName();
    }

    /**
     * @description Return external educational institution record type id
     * @return Id
     */
    global static Id getExternalEducationalInstitutionRecordTypeId() {
        return getRecordTypes().get('External_Educational_Institution').getRecordTypeId();
    }

    /**
     * @description Return External Educational Institution record type UI label
     * @return String
     */
    global static String getExternalEducationalInstitutionRecordTypeLabel() {
        return getRecordTypes().get('External_Educational_Institution').getName();
    }

    /**
     * @description Return organization record type id
     * @return Id
     */
    global static Id getOrganizationRecordTypeId() {
        return getRecordTypes().get('Organization').getRecordTypeId();
    }

    /**
     * @description Return Organization record type UI label
     * @return String
     */
    global static String getOrganizationRecordTypeLabel() {
        return getRecordTypes().get('Organization').getName();
    }
}