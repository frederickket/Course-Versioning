/**
 * @author      WDCi (Lean)
 * @date        Oct 2023
 * @group       Utility
 * @description Wrapper object for individual plan structure
 * @changehistory
 * ISS-001752 10-10-2023 Lean - new class
 * ISS-001979 19-07-2024 Sueanne - added field: byPassReqMet
 * ISS-002336 24-03-2025 Lean - Added missed/failed unit
 * ISS-002365 27-03-2025 Lean - Track historical ien
 */
public inherited sharing class REDU_IndividualPlanStructure_OBJ {
    
    /**
     * @description Sequence of the object in a list, this is an alternative to a new record that doesn't have id yet
     */
    @AuraEnabled
    public Decimal seq {set; get;}

    /**
     * @description This can be record id or any unique id that represents a record for the wrapper
     */
    @AuraEnabled
    public String id {set; get;}

    /**
     * @description Description
     */
    @AuraEnabled
    public String description {set; get;}

    /**
     * @description reduivy__Individual_Plan_Structure__c
     */
    @AuraEnabled
    public reduivy__Individual_Plan_Structure__c ips {set; get;}

    /**
     * @description reduivy__Individual_Enrollment__c for an academic term
     */
    @AuraEnabled
    public reduivy__Individual_Enrollment__c academicTermIen {set; get;}

    /**
     * @description reduivy__Individual_Enrollment__c for an academic term
     */
    @AuraEnabled
    public reduivy__Individual_Enrollment__c ipsCurrentIen {set; get;}

    /**
     * @description reduivy__Study_Plan_Structure__c
     */
    @AuraEnabled
    public reduivy__Study_Plan_Structure__c sps {set; get;}

    /**
     * @description reduivy__Study_Unit__c
     */
    @AuraEnabled
    public reduivy__Study_Unit__c sun {set; get;}

    /**
     * @description reduivy__Study_Offering__c
     */
    @AuraEnabled
    public reduivy__Study_Offering__c sof {set; get;}

    /**
     * @description Represents the list of ips wrapper when there are multiple study offerings
     */
    @AuraEnabled
    public List<REDU_IndividualPlanStructure_OBJ> options {set; get;}

    /**
     * @description Indicates that the parent section is expanded to display the child options
     */
    @AuraEnabled
    public Boolean isOptionsExpanded {set; get;}

    /**
     * @description LWC reactive attribute to force the rerendering
     */
    @AuraEnabled
    public String lwcReactor {set; get;}

    /**
     * @description To retrict the study unit listing to the id specified only
     */
    @AuraEnabled
    public List<Id> restrictedToUnits {set; get;}

    /**
     * @description Requirement logic string
     */
    @AuraEnabled
    public String requirementLogic {set; get;}

    /**
     * @description Requirement description
     */
    @AuraEnabled
    public String requirementDescription {set; get;}

    /**
     * @description Requirement description
     */
    @AuraEnabled
    public Boolean isEnrolledInOtherTerm {set; get;}

    /**
     * @description Indicate whether allow pre-enroll
     */
    @AuraEnabled
    public Boolean byPassReqMet {set; get;}

    /**
     * @description Indicate whether allow pre-enroll
     */
    @AuraEnabled
    public Boolean isMissedFailed {set; get;}

    /**
     * @description Default constructor
     */
    public REDU_IndividualPlanStructure_OBJ() {

        this.options = new List<REDU_IndividualPlanStructure_OBJ>();
        this.isOptionsExpanded = false;
        this.lwcReactor = '';
        this.restrictedToUnits = new List<Id>();
        this.isEnrolledInOtherTerm = false;
        this.byPassReqMet = false;
        this.isMissedFailed = false;
    }
}