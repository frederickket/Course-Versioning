/**
 * @author      WDCi (Lean)
 * @date        Sept 2023
 * @group       Object Helper
 * @description Individual Pathway object helper class that contains the picklist option constants and object related methods
 * @changehistory
 * ISS-001662 12-10-2023 dblack - added methods: createPathway(), getIpwMap()
 * ISS-002188 14-01-2025 XW - Renamed UNIT_LISTING value to 'All Study Units' and 'Recommended Pathway'
 * ISS-002401 21-04-2025 Lean - Added enrollment action status config
 */
global inherited sharing class IPW_Helper implements SObject_Helper {
    
    /**
     * @description Status - Current
     */
    public static final String STATUS_CURRENT = 'Current';

    /**
     * @description Status - Completed
     */
    public static final String STATUS_COMPLETED = 'Completed';

    /**
     * @description Status - Current
     */
    public static final String STATUS_FUTURE = 'Future';

    /**
     * @description Enrollment Method - Manual
     */
    public static final String ENROLLMENTMETHOD_MANUAL = 'Manual';

    /**
     * @description Unit listing mode - All
     */
    public static final String UNIT_LISTING_MODE_ALL = 'All Study Units';

    /**
     * @description Unit listing mode - Pathway
     */
    public static final String UNIT_LISTING_MODE_PATHWAY = 'Recommended Pathway';

    /**
     * @description Enrollment Action Status Type - Open
     */
    public static final String ENROLLMENT_ACTION_STATUS_TYPE_OPEN = 'Open';

    /**
     * @description Enrollment Action Status Type - Locked
     */
    public static final String ENROLLMENT_ACTION_STATUS_TYPE_LOCKED = 'Locked';

	/**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel() {
        return SObjectType.reduivy__Individual_Pathway__c.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel() {
        return SObjectType.reduivy__Individual_Pathway__c.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName() {
        return SObjectType.reduivy__Individual_Pathway__c.getName();
    }

    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.reduivy__Individual_Pathway__c);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }

    /**
     * @description Create individual pathway records
     * @param ipeMap Map<Id, reduivy__Individual_Program_Enrollment__c>
     */
    public static void createPathway(Map<Id, reduivy__Individual_Program_Enrollment__c> ipeMap) {

        // Get the study pathway term records
        Map<Id, List<reduivy__Study_Pathway_Term__c>> sptMap = SPT_Helper.getPathwayTermMap(ipeMap.values());

        if (!sptMap.isEmpty()) {

            // Get the existing individual pathway records
            Map<Id, Map<Decimal, reduivy__Individual_Pathway__c>> ipwMap = getIpwMap(ipeMap.keySet());

            // Create and/or update the individual pathway records
            List<reduivy__Individual_Pathway__c> ipwList = new List<reduivy__Individual_Pathway__c>();
            for (reduivy__Individual_Program_Enrollment__c ipe : ipeMap.values()) {
                if (sptMap.containsKey(ipe.reduivy__Study_Pathway__c)) {
                    for (reduivy__Study_Pathway_Term__c spt : sptMap.get(ipe.reduivy__Study_Pathway__c)) {
                        if (spt.reduivy__Term_Number__c != null) {

                            Decimal termNumber = spt.reduivy__Term_Number__c;
                            reduivy__Individual_Pathway__c ipw = new reduivy__Individual_Pathway__c();
                            reduivy__Individual_Pathway__c existingIpw;

                            if ((ipwMap.containsKey(ipe.Id)) && (ipwMap.get(ipe.Id).containsKey(termNumber))) {
                                existingIpw = ipwMap.get(ipe.Id).get(termNumber);
                                ipw.Id = existingIpw.Id;

                                if (existingIpw.reduivy__Status__c == STATUS_COMPLETED) {
                                    //skip updating the completed pathway
                                    continue;
                                }
                            }

                            //default the first term to the starting term if not set
                            if (termNumber == 1 && (existingIpw == null || String.isBlank(existingIpw.reduivy__Academic_Term__c))) {
                                ipw.reduivy__Academic_Term__c = ipe.reduivy__Starting_Term__c;
                            }

                            ipw.reduivy__Description__c = spt.reduivy__Description__c;
                            ipw.reduivy__Enrollment_Method__c = spt.reduivy__Enrollment_Method__c;
                            ipw.reduivy__Individual_Program_Enrollment__c = ipe.Id;
                            ipw.reduivy__Max_Credits__c = spt.reduivy__Max_Credits__c;
                            ipw.reduivy__Recommended_Credits__c = spt.reduivy__Recommended_Credits__c;
                            ipw.reduivy__Term_Number__c = spt.reduivy__Term_Number__c;

                            ipwList.add(ipw);
                        }
                    }
                }
            }
            if (!ipwList.isEmpty()) {
                REDU_Database_UTIL.doUpsert(ipwList, ipeMap, 'reduivy__Individual_Program_Enrollment__c', false);
            }
        }
    }

    /**
     * @description Get map of individual pathway records
     * @param ipeIdSet Set<Id>
     * @return ipwMap Map<Id, Map<Decimal, reduivy__Individual_Pathway__c>> (mapKey1: ipe Id; mapKey2: term number)
     */
    private static Map<Id, Map<Decimal, reduivy__Individual_Pathway__c>> getIpwMap(Set<Id> ipeIdSet) {

        Map<Id, Map<Decimal, reduivy__Individual_Pathway__c>> ipwMap = new Map<Id, Map<Decimal, reduivy__Individual_Pathway__c>>();

        for (reduivy__Individual_Pathway__c ipw : [
            SELECT  Id, 
                reduivy__Academic_Term__c, 
                reduivy__Description__c, 
                reduivy__Enrollment_Method__c,
                reduivy__Individual_Program_Enrollment__c, 
                reduivy__Max_Credits__c,
                reduivy__Recommended_Credits__c, 
                reduivy__Term_Number__c,
                reduivy__Status__c,
                reduivy__Individual_Academic_Progress__c,
                reduivy__Individual_Academic_Progress__r.reduivy__Individual_Academic_Profile__c
            FROM reduivy__Individual_Pathway__c
            WHERE reduivy__Individual_Program_Enrollment__c IN :ipeIdSet
            WITH USER_MODE
        ]) {
            if (!ipwMap.containsKey(ipw.reduivy__Individual_Program_Enrollment__c)) {
                ipwMap.put(ipw.reduivy__Individual_Program_Enrollment__c, new Map<Decimal, reduivy__Individual_Pathway__c>());
            }

            ipwMap.get(ipw.reduivy__Individual_Program_Enrollment__c).put(ipw.reduivy__Term_Number__c, ipw);
        }

        return ipwMap;
    }

    /**
     * @description List of reduivy__IdvPw_Enrollment_Action_Status_Config__mdt
     */
    private static List<reduivy__IdvPw_Enrollment_Action_Status_Config__mdt> enrollmentActionStatusConfigs;

    /**
     * @description Enrollment action status configs metadata sorted according to Enrollment Action Status field
     * @return List<reduivy__IdvPw_Enrollment_Action_Status_Config__mdt>
     */
    public static List<reduivy__IdvPw_Enrollment_Action_Status_Config__mdt> getEnrollmentActionStatusConfigs(){

        if (enrollmentActionStatusConfigs == null){
            Schema.DescribeFieldResult dfr = Schema.SObjectType.reduivy__Individual_Academic_Progress__c.fields.reduivy__Enrollment_Action_Status__c;
            List<Schema.PicklistEntry> pleList = dfr.getPicklistValues();

            List<reduivy__IdvPw_Enrollment_Action_Status_Config__mdt> configs = reduivy__IdvPw_Enrollment_Action_Status_Config__mdt.getAll().values();
            List<reduivy__IdvPw_Enrollment_Action_Status_Config__mdt> sortedConfigs = new List<reduivy__IdvPw_Enrollment_Action_Status_Config__mdt>();

            for (Schema.PicklistEntry ple : pleList){
                if (ple.isActive()){
                    for (reduivy__IdvPw_Enrollment_Action_Status_Config__mdt config : configs){
                        if (config.reduivy__Active__c && ple.getValue() == config.reduivy__Enrollment_Action_Status__c){
                            sortedConfigs.add(config);
                        }
                    }
                }
            }

            enrollmentActionStatusConfigs = sortedConfigs;
        }

        return enrollmentActionStatusConfigs;
    }
}