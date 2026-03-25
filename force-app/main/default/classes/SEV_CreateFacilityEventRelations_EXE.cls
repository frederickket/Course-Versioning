/**
 * @author      WDCi (XW)
 * @date        June 2024
 * @group       Trigger Executable
 * @description Create a new Facility Event Relation if there is default facility. if reduivy__Respect_Resource_Availability__c == true, check for facility availability
 * @changehistory
 * ISS-001922 14-06-2024 XW - create new class
 */
public inherited sharing class SEV_CreateFacilityEventRelations_EXE extends REDU_TriggerExecutable {
    /**
     * @description AfterInsert
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeAfterInsert(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {

            List<reduivy__Study_Event__c> studyEventList = new List<reduivy__Study_Event__c>();
            for (reduivy__Study_Event__c newStudyEvent: (List<reduivy__Study_Event__c>)newList) {
                if (newStudyEvent.reduivy__Type__c == SEV_Helper.TYPE_STUDY_SESSION) {
                    studyEventList.add(newStudyEvent);
                }
            }

            if (!studyEventList.isEmpty()) {
                Map<Id, reduivy__Study_Session_Time__c> studyEventSstMap = new Map<Id, reduivy__Study_Session_Time__c>();
                Map<Id, reduivy__Study_Session__c> studyEventSseMap = new Map<Id, reduivy__Study_Session__c>();
                Set<Id> facilityIdSet = new Set<Id>();

                List<reduivy__Study_Event_Relation__c> serToInsert = new List<reduivy__Study_Event_Relation__c>();


                //get additional info
                List<reduivy__Study_Event__c> detailStudyEventList = new List<reduivy__Study_Event__c>();
                for(reduivy__Study_Event__c studyEvent : [SELECT Id, 
                    Name, 
                    reduivy__Start_Date_Non_TZ__c, 
                    reduivy__End_Date_Non_TZ__c, 
                    reduivy__Start_Time_Non_TZ__c, 
                    reduivy__End_Time_Non_TZ__c, 
                    reduivy__Day_of_Week__c,
                    reduivy__Study_Session_Time__r.Id, 
                    reduivy__Study_Session_Time__r.reduivy__Default_Facility__r.Id, 
                    reduivy__Study_Session_Time__r.reduivy__Start_Time__c, 
                    reduivy__Study_Session_Time__r.reduivy__End_Time__c,
                    reduivy__Study_Session_Time__r.reduivy__Study_Session__r.Id, 
                    reduivy__Study_Session_Time__r.reduivy__Study_Session__r.reduivy__Respect_Resource_Availability__c
                    FROM reduivy__Study_Event__c
                    WHERE Id IN:studyEventList
                    WITH USER_MODE
                ]){
                    detailStudyEventList.add(studyEvent);
                }

                for (reduivy__Study_Event__c studyEvent : detailStudyEventList) {
                    studyEventSstMap.put(studyEvent.Id, studyEvent.reduivy__Study_Session_Time__r);
                    studyEventSseMap.put(studyEvent.Id, studyEvent.reduivy__Study_Session_Time__r.reduivy__Study_Session__r);

                    if (String.isNotBlank(studyEvent.reduivy__Study_Session_Time__r.reduivy__Default_Facility__c)) {
                        facilityIdSet.add(studyEvent.reduivy__Study_Session_Time__r.reduivy__Default_Facility__c);
                    }
                }

                //Add into Facility Availability Map
                Map<Id, List<reduivy__Facility_Availability__c>> facilityAvailabilityMap = new Map<Id, List<reduivy__Facility_Availability__c>>();
                for (reduivy__Facility_Availability__c facilityAvailability : [SELECT Id, 
                    reduivy__Facility__c, 
                    reduivy__From_Date__c, 
                    reduivy__To_Date__c, 
                    reduivy__Monday_From__c, 
                    reduivy__Monday_To__c, 
                    reduivy__Tuesday_From__c, 
                    reduivy__Tuesday_To__c, 
                    reduivy__Wednesday_From__c, 
                    reduivy__Wednesday_To__c, 
                    reduivy__Thursday_From__c, 
                    reduivy__Thursday_To__c, 
                    reduivy__Friday_From__c, 
                    reduivy__Friday_To__c, 
                    reduivy__Saturday_From__c, 
                    reduivy__Saturday_To__c, 
                    reduivy__Sunday_From__c, 
                    reduivy__Sunday_To__c
                    FROM reduivy__Facility_Availability__c
                    WHERE reduivy__Facility__c IN: facilityIdSet AND reduivy__Status__c =: FAV_Helper.STATUS_ACTIVE
                    WITH USER_MODE
                ]) {
                    if (facilityAvailabilityMap.containsKey(facilityAvailability.reduivy__Facility__c)) {
                        facilityAvailabilityMap.get(facilityAvailability.reduivy__Facility__c).add(facilityAvailability);
                    } else{
                        facilityAvailabilityMap.put(facilityAvailability.reduivy__Facility__c, new List<reduivy__Facility_Availability__c>{ facilityAvailability });
                    }
                }


                for (reduivy__Study_Event__c event : detailStudyEventList) {
                    if (!studyEventSseMap.containsKey(event.Id) || !studyEventSstMap.containsKey(event.Id) || String.isBlank(studyEventSstMap.get(event.Id).reduivy__Default_Facility__c)) {
                        continue;
                    }

                    reduivy__Study_Session_Time__c currentSst = studyEventSstMap.get(event.Id);
                    reduivy__Study_Event_Relation__c newRelation;

                    if (studyEventSseMap.get(event.Id).reduivy__Respect_Resource_Availability__c) {
                        Id facilityId = currentSst.reduivy__Default_Facility__c;

                        for (reduivy__Facility_Availability__c availability : facilityAvailabilityMap.get(facilityId)) {

                            if (facilityIsAvailable(event, availability)) {
                                newRelation = new reduivy__Study_Event_Relation__c(
                                    reduivy__Study_Event__c = event.Id, 
                                    reduivy__Facility__c = currentSst.reduivy__Default_Facility__c,
                                    reduivy__Response_Status__c = SER_Helper.RESPONSE_STATUS_ACCEPTED
                                );

                                serToInsert.add(newRelation);
                                break;
                            }
                        }
                            
                    } else{
                        newRelation = new reduivy__Study_Event_Relation__c(
                            reduivy__Study_Event__c = event.Id, 
                            reduivy__Facility__c = currentSst.reduivy__Default_Facility__c,
                            reduivy__Response_Status__c = SER_Helper.RESPONSE_STATUS_ACCEPTED
                        );

                        serToInsert.add(newRelation);
                    }
                }

                REDU_Database_UTIL.doInsert(serToInsert);
            }
        }
    }

    /**
     * @description Return true if the default facility is available for the event
     * @param  event        Study event
     * @param  sst          Study Session Time
     * @param  availability Facility Availability
     * @return              Boolean
     */ 
    private Boolean facilityIsAvailable(reduivy__Study_Event__c event, reduivy__Facility_Availability__c availability) {

        if(availability.reduivy__From_Date__c != null && availability.reduivy__From_Date__c > event.reduivy__Start_Date_Non_TZ__c) {
            return false;
        }

        if (availability.reduivy__To_Date__c != null && availability.reduivy__To_Date__c < event.reduivy__End_Date_Non_TZ__c) {
            return false;
        }

        Time facilityFrom;
        Time facilityTo;
        Time sevFrom = event.reduivy__Start_Time_Non_TZ__c;
        Time sevTo = event.reduivy__End_Time_Non_TZ__c;

        if (event.reduivy__Day_of_Week__c == SST_Helper.DAY_OF_WEEK_SUNDAY) {
            facilityFrom = availability.reduivy__Sunday_From__c;
            facilityTo = availability.reduivy__Sunday_To__c;

        } else if (event.reduivy__Day_of_Week__c == SST_Helper.DAY_OF_WEEK_MONDAY) {
            facilityFrom = availability.reduivy__Monday_From__c;
            facilityTo = availability.reduivy__Monday_To__c;

        } else if (event.reduivy__Day_of_Week__c == SST_Helper.DAY_OF_WEEK_TUESDAY) {
            facilityFrom = availability.reduivy__Tuesday_From__c;
            facilityTo = availability.reduivy__Tuesday_To__c;

        } else if (event.reduivy__Day_of_Week__c == SST_Helper.DAY_OF_WEEK_WEDNESDAY) {
            facilityFrom = availability.reduivy__Wednesday_From__c;
            facilityTo = availability.reduivy__Wednesday_To__c;

        } else if (event.reduivy__Day_of_Week__c == SST_Helper.DAY_OF_WEEK_THURSDAY) {
            facilityFrom = availability.reduivy__Thursday_From__c;
            facilityTo = availability.reduivy__Thursday_To__c;

        } else if (event.reduivy__Day_of_Week__c == SST_Helper.DAY_OF_WEEK_FRIDAY) {
            facilityFrom = availability.reduivy__Friday_From__c;
            facilityTo = availability.reduivy__Friday_To__c;

        } else if (event.reduivy__Day_of_Week__c == SST_Helper.DAY_OF_WEEK_SATURDAY) {
            facilityFrom = availability.reduivy__Saturday_From__c;
            facilityTo = availability.reduivy__Saturday_To__c;

        } else {
            return false;
        }

        if (facilityFrom == null || facilityTo == null){
            return false;
        } else{
            return isInRange(sevFrom, sevTo, facilityFrom, facilityTo);
        }
    }

    /**
     * @description Return true if study sesstion time is within the facility availability time
     * @param  sevFrom      The study event start time
     * @param  sevTo        The study event end time
     * @param  facilityFrom The facility availability's from time
     * @param  facilityTo   The facility availability's to time
     * @return              Boolean
     */
    private Boolean isInRange(Time sevFrom, Time sevTo, Time facilityFrom, Time facilityTo) {

        REDU_Logging_UTIL.debug('sevFrom >= facilityFrom && sevTo <= facilityTo', sevFrom >= facilityFrom && sevTo <= facilityTo);
        return sevFrom >= facilityFrom && sevTo <= facilityTo;
    }

}