/**
 * @author      WDCi (Lean)
 * @date        Oct 2023
 * @group       Utility
 * @description Wrapper object for custom filter
 * @changehistory
 * ISS-001752 28-10-2023 Lean - new class
 * ISS-002410 14-04-2025 XiRouh - Replaced isSet with != null
 * ISS-002505 03-06-2025 XW - moved QueryBinder generation to here from LCTRL class
 */
public inherited sharing class REDU_CustomFilter_OBJ {
    
    /**
     * @description Sequence of the object in a list, this is an alternative to a new record that doesn't have id yet
     */
    @AuraEnabled
    public Decimal seq {set; get;}

    /**
     * @description Show or hide the filter field
     */
    @AuraEnabled
    public Boolean showFilter {set; get;}

    /**
     * @description Label for the filter field. If left blank, it will be set based on the field's label
     */
    @AuraEnabled
    public String label {set; get;}

    /**
     * @description The source object and target object mapping e.g., reduivy__Source__c=reduivy__Target__c
     */
    @AuraEnabled
    public String mapping {set; get;}

    /**
     * @description The source field api name extracted from mapping
     */
    @AuraEnabled
    public String sourceFieldName {set; get;}

    /**
     * @description The source field Schema.DisplayType name
     */
    @AuraEnabled
    public String targetFieldType {set; get;}

    /**
     * @description The source field Schema.SoapType name
     */
    @AuraEnabled
    public String targetSoapFieldType {set; get;}

    /**
     * @description The source sobject record
     */
    @AuraEnabled
    public SObject sourceSobj {set; get;}

    /**
     * @description The source object api name
     */
    @AuraEnabled
    public String targetObjectType {set; get;}
    
    /**
     * @description The target field api name extracted from mapping
     */
    @AuraEnabled
    public String targetFieldName {set; get;}

    /**
     * @description Options for picklist
     */
    @AuraEnabled
    public List<REDU_PicklistOption_OBJ> picklistOptions {set; get;}

    /**
     * @description LWC reactive attribute to force the rerendering
     */
    @AuraEnabled
    public String lwcReactor {set; get;}

    public REDU_CustomFilter_OBJ() {

    }

    private static List<String> equalsTypeList = new List<String> {
        Schema.DisplayType.DATE.name(),
        Schema.DisplayType.DATETIME.name(), 
        Schema.DisplayType.BOOLEAN.name(), 
        Schema.DisplayType.DOUBLE.name(),
        Schema.DisplayType.INTEGER.name(),
        Schema.DisplayType.PERCENT.name(), 
        Schema.DisplayType.CURRENCY.name(),
        Schema.DisplayType.REFERENCE.name(),
        Schema.DisplayType.ID.name()
    };

    public Boolean isValid() {
        if (this.sourceSobj != null && 
            String.isNotBlank(this.sourceFieldName) && 
            this.sourceSobj.get(this.sourceFieldName) != null
        ) {
            return true;
        }

        return false;
    }

    private Object getValue() {

        if (isValid()) {

            if (this.targetFieldType == Schema.DisplayType.MULTIPICKLIST.name() || this.targetFieldType == Schema.DisplayType.PICKLIST.name()) {
                //for picklist, we will split the value as a set of string
                Set<String> value = new Set<String>(((String) this.sourceSobj.get(this.sourceFieldName)).split(';'));
                return value;

            } else if (getQueryBinder().contains('LIKE:')) {
                //for LIKE operator, we will append the % to search for string start with
                return ((String) this.sourceSobj.get(this.sourceFieldName)) + '%';
            }

            return this.sourceSobj.get(this.sourceFieldName);
        }

        return null;
    }

    public Map<String, Object> getBindParams() {
        if(this.targetFieldType == Schema.DisplayType.MULTIPICKLIST.name()) {
            return REDU_Database_UTIL.getMultiPicklistBindMap(this.sourceFieldName, new List<String>((Set<String>)getValue()));
        } else {
            return new Map<String, Object>{this.sourceFieldName => getValue()};
        }
    }

    public String getQueryBinder() {
        String targetFieldBinder = '';
        if(equalsTypeList.contains( this.targetFieldType )){
            targetFieldBinder = this.targetFieldName + ' =: ' + this.sourceFieldName;
        } 
        else if (this.targetFieldType == Schema.DisplayType.PICKLIST.name()) {
            targetFieldBinder = this.targetFieldName + ' IN: ' + this.sourceFieldName;
        }
        else if (this.targetFieldType == Schema.DisplayType.MULTIPICKLIST.name()) {
            //for multipicklist, have to use includes

            Map<String, Object> bindMap = REDU_Database_UTIL.getMultiPicklistBindMap(this.sourceFieldName,  new List<String>((Set<String>)getValue()));
            Set<String> placeholderSet = REDU_Database_UTIL.getMultiPicklistPlaceholders(bindMap.keySet());

            targetFieldBinder = this.targetFieldName + ' INCLUDES ( ' + String.join(placeholderSet, ', ') + ' )';
        }
        else if (this.targetFieldType == Schema.DisplayType.STRING.name() || this.targetFieldType == Schema.DisplayType.URL.name() || this.targetFieldType == Schema.DisplayType.EMAIL.name()) {
            targetFieldBinder = this.targetFieldName + ' LIKE: ' + this.sourceFieldName;
        }
        
        
        return targetFieldBinder;
    }

	
}