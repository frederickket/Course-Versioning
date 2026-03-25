/**
 * @author      WDCi (Lean)
 * @date        Oct 2023
 * @group       Utility
 * @description Wrapper object for picklist option
 * @changehistory
 * ISS-001752 28-10-2023 Lean - new class
 */
 public inherited sharing class REDU_PicklistOption_OBJ {
    
    /**
     * @description Picklist label
     */
    @AuraEnabled
    public String label {set; get;}
    
    /**
     * @description Picklist unique id
     */
    @AuraEnabled
    public String id {set; get;}

    /**
     * @description Picklist value
     */
    @AuraEnabled
    public String value {set; get;}
    
    /**
     * @description True if selected
     */
    @AuraEnabled
    public boolean selected {set; get;}

    /**
     * @description Child picklist options to simulate dependent picklist
     */
    @AuraEnabled
    public List<REDU_PicklistOption_OBJ> childOptions {set; get;}

    public REDU_PicklistOption_OBJ(String label, String id, boolean selected){
        this.label = label;
        this.id = id;
        this.value = id;
        this.selected = selected;

        childOptions = new List<REDU_PicklistOption_OBJ>();
    }

}