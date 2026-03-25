/**
 * @author      WDCi (Lean)
 * @date        March 2023
 * @group       Util
 * @description SObject utility
 * @changehistory
 * ISS-001591 31-03-2023 Lean - new class
 * ISS-002230 26-02-2025 XW - modify the logic to get field value so that we can get picklist label
 * ISS-002746 27-11-2025 Lean - Standardize the CurrencyIsoCode detection
 * ISS-002633 07-01-2026 XW - added setFieldValue method
 */
@NamespaceAccessible
public inherited sharing class REDU_SObject_UTIL {
    
    /**
     * @description Number field type - N
     */
    @NamespaceAccessible
    public static final String FIELDTYPE_NUMBER = 'N';

    /**
     * @description Date field type - D
     */
    @NamespaceAccessible
    public static final String FIELDTYPE_DATE = 'D';

    /**
     * @description Datetime field type - T
     */
    @NamespaceAccessible
    public static final String FIELDTYPE_DATETIME = 'T';

    /**
     * @description Text field type - A
     */
    @NamespaceAccessible
    public static final String FIELDTYPE_TEXT = 'A';

    /**
     * @description Boolean field type - B
     */
    @NamespaceAccessible
    public static final String FIELDTYPE_BOOLEAN = 'B';

    /**
     * @description CurrencyIsoCode field
     */
    @NamespaceAccessible
    public static final String CURRENCYISOCODE_FIELD = 'CurrencyIsoCode';

    /**
     * @description         To extract a field value from a sobject as an object
     * @param sobj          Salesforce object
     * @param fieldName     API name for a field
     * @return Object
     */
    @NamespaceAccessible
    public static Object extractFieldValue(SObject sobj, String fieldName){

        SObject sobjHolder = sobj;
        
        if(fieldName != null && fieldName.contains('.')){
            
            integer counter = 0;
            String [] splittedNames = fieldName.split('\\.');
            for(String splittedName : splittedNames){
                if(counter != (splittedNames.size() - 1) && sobjHolder != null){
                    sobjHolder = sobjHolder.getSObject(splittedName);
                } else {
                    return (sobjHolder != null ? sobjHolder.get(splittedName) : null);
                }
                
                counter ++;
            }
            
            return null;
            
        } else {
            
            return (sobj != null && fieldName != null ? sobj.get(fieldName) : null);
        }
        
    }

    /**
     * @description         To set the field value (can be sobject or any object)
     * @param sobj          Salesforce object to be modified
     * @param fieldName     API name for a field. can be more than one level
     * @param value         the value to be inserted in the sobj
     * @return Object
     */
    @NamespaceAccessible
    public static void setFieldValue(SObject sobj, String fieldName, Object value){

        if(value == null || sobj == null) {
            return;
        }

        SObject sobjHolder = sobj;
        SObject previousSobjHolder = null;

        List<Schema.DescribeFieldResult> describeFieldPathList = REDU_Metadata_UTIL.getDescribePathFields(sobj.getSObjectType().getDescribe(Schema.SObjectDescribeOptions.DEFERRED).getName(), fieldName);

        if(fieldName != null && fieldName.contains('.')){
            Integer counter = 0;
            String [] splittedNames = fieldName.split('\\.');
            Integer splittedNameSize = splittedNames.size();
            for(String splittedName : splittedNames){
                previousSobjHolder = sobjHolder;
                
                if(counter != (splittedNameSize - 1)){
                    sobjHolder = sobjHolder.getSObject(splittedName);
                    if(sobjHolder == null) {
                        Schema.DescribeFieldResult currentFieldDescribe = describeFieldPathList.get(counter);
                        SObject newParentSObject = currentFieldDescribe.getReferenceTo()[0].newSObject();
                        previousSobjHolder.putSObject(splittedName, newParentSObject);
                        sobjHolder = newParentSObject; 
                    }
                } else {
                    if(value instanceof SObject) {
                        sobjHolder.putSObject(splittedName, (SObject)value);
                    } else {
                        sobjHolder.put(splittedName, value);
                    }
                }
                counter ++;
            }
            
        } else if(String.isNotBlank(fieldName)) {
            
            if(value instanceof SObject) {
                sobj.putSObject(fieldName, (SObject)value);
            } else {
                sobj.put(fieldName, value);
            }
        }
        
    }

    /**
     * @description To get standard field type: N = Number, D = Date, T = DateTime, A = AlphaNumeric, B = Boolean
     * @param soapDisplayType Schema.SoapType enum name
     * @return String
     */
    @NamespaceAccessible
    public static String getFieldType(String soapDisplayType){

        if (String.isNotBlank(soapDisplayType)) {
            //ISS-000077
            Schema.SoapType fieldSoapType = Schema.SoapType.valueOf(soapDisplayType);

            switch on fieldSoapType {
                when DATE {
                    return FIELDTYPE_DATE;
                }
                when DATETIME {
                    return FIELDTYPE_DATETIME;
                }
                when INTEGER, DOUBLE {
                    return FIELDTYPE_NUMBER;
                }
                when BOOLEAN {
                    return FIELDTYPE_BOOLEAN;
                }
                when else {
                    return FIELDTYPE_TEXT;
                }
            }
        }

        return null;
    }

    /**
     * @description Return true if the object has CurrencyIsoCode field
     * @return Boolean
     */
    public static Boolean hasCurrencyIsoCode(SObjectType sobjType) {

        if (ORG_Helper.isMultiCurrenciesOrg()) {
            Map<String, Schema.SObjectField> childObjectFields = sobjType.getDescribe(SObjectDescribeOptions.DEFERRED).fields.getMap();
            if (ORG_Helper.testSimulateMultiCurrencies || childObjectFields.containsKey(CURRENCYISOCODE_FIELD.toLowerCase())) {
                return true;
            }
        }

        return false;
    }
}