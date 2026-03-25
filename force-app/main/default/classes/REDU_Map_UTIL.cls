/**
 * @author      WDCi (Lean)
 * @date        Sept 2023
 * @group       Util
 * @description Utility for map
 * @changehistory
 * ISS-002410 14-04-2025 XiRouh - Replaced isSet with != null
 */
@NamespaceAccessible
public inherited sharing class REDU_Map_UTIL {
    
    /**
     * @description Generate a parent and child map based on the parent field
     * @param sobjList List of sobject
     * @param parentFieldName The parent field
     * @return Map<String, List<SObject>>
     */
    @NamespaceAccessible
	public static Map<Id, List<SObject>> generateParentChilMap(List<SObject> sobjList, String parentFieldName){

        Map<Id, List<SObject>> parentChildMap = new Map<Id, List<SObject>>();

        for (SObject child : sobjList) {
            if(child.get(parentFieldName) != null){
                Id parentVal = Id.valueOf(String.valueOf(child.get(parentFieldName)));
                
                if(parentChildMap.containsKey(parentVal)){
                    parentChildMap.get(parentVal).add(child);
                } else {
                    parentChildMap.put(parentVal, new List<SObject>{child});
                }
            }
        }

        return parentChildMap;
    }
	
}