/**
 * @author      WDCi (Lean)
 * @date        Sept 2023
 * @group       Util
 * @description List utility
 * @changehistory
 * 
 */
@NamespaceAccessible
public inherited sharing class REDU_List_UTIL {
    
    /**
     * @description Delimiter = semi-colon (;)
     */
    @NamespaceAccessible
    public static final String DELIMITER = ';';

    /**
     * @description Default iterator page size 200
     */
	public static final integer DEFAULT_ITERABLE_PAGE_SIZE = 200;
    
    /**
     * @description Paginate a list of id
     * @param sobjIdList
     * @param pageSize
     * @return List<List<Id>>
     */
    @NamespaceAccessible
    public static List<List<Id>> getPageIterable(List<Id> sobjIdList, integer pageSize){
         
        List<List<Id>> iterableList = new List<List<Id>>();
        
        if(sobjIdList != null){
            integer size = (pageSize == null ? DEFAULT_ITERABLE_PAGE_SIZE : pageSize);
             
            integer counter = 1;
            integer listCounter = 0;
            List<Id> pageList = new List<Id>();
             
            for(Id sobjId : sobjIdList){
                 
                pageList.add(sobjId);
                 
                if(counter == size || listCounter == (sobjIdList.size() - 1)){
                    iterableList.add(pageList.clone());
                    pageList = new List<Id>();
                    counter = 1;
                     
                } else {
                    counter ++;
                }
                 
                listCounter ++;
                 
            }
        }
         
        return iterableList;
         
    }

    /**
     * @description Paginate a set of string
     * @param stringSet
     * @param pageSize
     * @return List<Set<String>>
     */
    @NamespaceAccessible
    public static List<Set<String>> getPageIterable(Set<String> stringSet, integer pageSize){
         
        List<Set<String>> iterableList = new List<Set<String>>();
        
        if(stringSet != null){
            integer size = (pageSize == null ? DEFAULT_ITERABLE_PAGE_SIZE : pageSize);
             
            integer counter = 1;
            integer listCounter = 0;
            Set<String> pageSet = new Set<String>();
             
            for(String stringToAdd : stringSet){
                 
                pageSet.add(stringToAdd);
                 
                if(counter == size || listCounter == (stringSet.size() - 1)){
                    iterableList.add(pageSet.clone());
                    pageSet = new Set<String>();
                    counter = 1;
                     
                } else {
                    counter ++;
                }
                 
                listCounter ++;
                 
            }
        }
         
        return iterableList;
         
    }
	
}