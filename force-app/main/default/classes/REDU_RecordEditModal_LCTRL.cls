/**
 * @author      WDCi (XW)
 * @date        Nov 2024
 * @group       Record Edit Modal
 * @description 
 * @changehistory
 * ISS-002104 11-11-2024 XW - create new class
 */
public inherited sharing class REDU_RecordEditModal_LCTRL{
    
    /**
     * @description get field set member in semicolon string
     * @param  objName      object api name
     * @param  fieldSetName field set api name
     * @return              return semicolon separated field api string
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getFieldSetMembers(String objName, String fieldSetName){
        try {
            List<REDU_DynamicFieldValue_OBJ> result = REDU_Metadata_UTIL.getFieldSetMembers(objName, fieldSetName);
            return new REDU_LightningResponse(true, 'success', JSON.serialize(result));
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}