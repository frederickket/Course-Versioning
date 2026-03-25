/**
 * @author      WDCi (Lean)
 * @date        Jun 2024
 * @group       Announcement
 * @description This is to send salesforce custom notification to users. For other channel types, it would require customization.
 * @changehistory
 * ISS-001920 11-06-2024 Lean - new class
 */
public inherited sharing class ANM_SendNotification_EXE extends REDU_TriggerExecutable {
    
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

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.ADMIN) || REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.FACULTY)) {

            sendNotifications((List<reduivy__Announcement__c>) newList, null);
        }
    }

    /**
     * @description AfterUpdate
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeAfterUpdate(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.ADMIN) || REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.FACULTY)) {

            sendNotifications((List<reduivy__Announcement__c>) newList, (List<reduivy__Announcement__c>) oldList);
        }
    }
	
    /**
     * @description Create and send the notifications
     * @param newList list of new Announcements (reduivy__Announcement__c)
     * @param oldList list of old Announcements (reduivy__Announcement__c)
     * @return void
     */
    private void sendNotifications(List<reduivy__Announcement__c> newList, List<reduivy__Announcement__c> oldList) {
        
        Map<Id, reduivy__Announcement__c> oldMap = new Map<Id, reduivy__Announcement__c>();
        if (oldList != null) {
            oldMap = new Map<Id, reduivy__Announcement__c>((List<reduivy__Announcement__c>) oldList);
        }

        List<reduivy__Announcement__c> annList = new List<reduivy__Announcement__c>();
        for (reduivy__Announcement__c annNew : newList) {

            if (
                String.isNotBlank(annNew.reduivy__Channel_Type__c) &&
                annNew.reduivy__Channel_Type__c?.contains(ANM_Helper.NCT_NOTIFICATION) && 
                annNew.reduivy__Status__c == ANM_Helper.STATUS_SEND &&
                String.isNotBlank(annNew.reduivy__Notification_Receivers_Id__c) &&
                String.isNotBlank(annNew.reduivy__Details__c)
            ) {
                if (oldMap.containsKey(annNew.Id) && annNew.reduivy__Status__c == oldMap.get(annNew.Id).reduivy__Status__c) {
                    //don't send if Status hasn't changed
                    continue;
                } else {
                    annList.add(annNew);
                }
            }
        }

        if (!annList.isEmpty()) {
            List<reduivy__Announcement__c> updateAnns = new List<reduivy__Announcement__c>();
            Id notificationTypeId = REDU_AppSetting_UTIL.getNotificationTypeId();

            Integer annNameFieldLength = Schema.SObjectType.reduivy__Announcement__c.fields.Name.getLength();
            Integer annDetailsFieldLength = Schema.SObjectType.reduivy__Announcement__c.fields.reduivy__Details__c.getLength();

            //Create and send a new notification for each Announcement
            for (reduivy__Announcement__c ann : annList) {

                //Get the receivers' IDs
                Set<String> receiverIdsSet = new Set<String>();
                receiverIdsSet.addAll(ann.reduivy__Notification_Receivers_Id__c.split(';')); //required

                List<Set<String>> receiverIdsIterable = REDU_List_UTIL.getPageIterable(receiverIdsSet, 500);

                for (Set<String> receiverIds : receiverIdsIterable) {
                    //Create a new custom notification
                    Messaging.CustomNotification notification = new Messaging.CustomNotification();
                    notification.setNotificationTypeId(notificationTypeId);

                    //Set the contents for the notification
                    notification.setTitle(ann.Name.left(annNameFieldLength)); //required
                    notification.setBody(ann.reduivy__Details__c.stripHtmlTags().left(annDetailsFieldLength)); //required

                    //Set the sender ID
                    if (String.isNotBlank(ann.reduivy__Notification_Sender_Id__c)) {
                        notification.setSenderId(ann.reduivy__Notification_Sender_Id__c);
                    } else {
                        notification.setSenderId(UserInfo.getUserId());
                    }

                    //Set the target
                    if (String.isNotBlank(ann.reduivy__Notification_Target_Value__c) && String.isNotBlank(ann.reduivy__Notification_Target_Type__c)) {
                        if (ann.reduivy__Notification_Target_Type__c == ANM_Helper.NTT_NAMED_PAGE_EXPERIENCE_CLOUD) {
                            String experiencePageRef = 
                            '{' +
                            '       type: \'comm__namedPage\',' +
                            '       attributes: {' +
                            '           name: \'' + ann.reduivy__Notification_Target_Value__c + '\',' +
                            '       }' +
                            '}';
                            notification.setTargetPageRef(experiencePageRef);
                        } else if (ann.reduivy__Notification_Target_Type__c == ANM_Helper.NTT_NAMED_PAGE_STANDARD) {
                            String standardPageRef = 
                            '{' +
                            '       type: \'standard__namedPage\',' +
                            '       attributes: {' +
                            '           pageName: \'' + ann.reduivy__Notification_Target_Value__c + '\',' +
                            '       }' +
                            '}';
                            notification.setTargetPageRef(standardPageRef);
                        } else if (ann.reduivy__Notification_Target_Type__c == ANM_Helper.NTT_NAVIGATION_ITEM_PAGE) {
                            String navItemPageRef = 
                            '{' +
                            '       type: \'standard__navItemPage\',' +
                            '       attributes: {' +
                            '           apiName: \'' + ann.reduivy__Notification_Target_Value__c + '\',' +
                            '       }' +
                            '}';
                            notification.setTargetPageRef(navItemPageRef);
                        } else if (ann.reduivy__Notification_Target_Type__c == ANM_Helper.NTT_WEB_PAGE) {
                            String webPageRef = 
                            '{' +
                            '       type: \'standard__webPage\',' +
                            '       attributes: {' +
                            '           url: \'' + ann.reduivy__Notification_Target_Value__c + '\',' +
                            '       }' +
                            '}';
                            notification.setTargetPageRef(webPageRef);
                        } else {
                            notification.setTargetId(ann.reduivy__Notification_Target_Value__c);
                        }
                    } else {
                        notification.setTargetId(ann.Id);
                    }

                    //Send the notification
                    try {
                        notification.send(receiverIds);
                        reduivy__Announcement__c updateAnn = new reduivy__Announcement__c(Id = ann.Id);
                        updateAnn.reduivy__Status__c = ANM_Helper.STATUS_PUBLISHED;
                        updateAnn.reduivy__Published_Datetime__c = System.now();
                        updateAnns.add(updateAnn);
                    }
                    catch (Exception exp) {
                        String errorMsg = String.format(Label.Problem_Sending_Notification, new List<String>{exp.getMessage()});
                        ann.addError(errorMsg);
                    }
                }
            }

            //Update Announcement system fields after all notifications have been sent using system mode
            REDU_SystemMode_UTIL.doUpdate(updateAnns);
        }
    }
}