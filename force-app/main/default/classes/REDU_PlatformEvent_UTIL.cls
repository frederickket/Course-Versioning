/**
 * @author      WDCi (Jordan)
 * @date        Nov 2024
 * @group       Util
 * @description Platform event util
 * @changehistory
 * ISS-002153 19-11-2024 Jordan - new class
 */
global inherited sharing class REDU_PlatformEvent_UTIL {
    
    /**
     * @description Initialise platform event
     * @param opType Operation type
     * @param status Status
     * @param message Message
     * @param resourceId Resource ID
     * @return Platform event
     */
    global static SObject initPlatformEvent(String opType, String status, String message, String resourceId){
        String platformEventChannel = 'reduivy__Operation_Channel__e';

        if(String.isNotBlank(platformEventChannel)){
            SObject pfEvt = (SObject)Type.forName(platformEventChannel).newInstance();
            pfEvt.put('reduivy__Status__c', status);
            pfEvt.put('reduivy__Operation_Type__c', opType);
            pfEvt.put('reduivy__Message__c', message);
            pfEvt.put('reduivy__Resource_ID__c', resourceId);

            return pfEvt;

        }

        return null;
    }

    /**
     * @description Publish platform event
     * @param pfEvt Platform event to publish
     * @return Database.SaveResult
     */
    global static Database.SaveResult publishEvent(SObject pfEvt){
        if(pfEvt != null){
            return Eventbus.publish(pfEvt);
        }

        return null;
    }
}