/**
 * @author      WDCi (XW)
 * @date        Aug 2024
 * @group       Application Scoring
 * @description Link Individual requirement to the 
 * @changehistory
 * ISS-002506 22-08-2025 XW - new class
 */

public inherited sharing class ISD_LinkRequirement_EXE extends REDU_TriggerExecutable {
    
    Map<String, List<SObject>> sourceObjMapForInsert;
	/**
     * @description BeforeInsert
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeBeforeInsert(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {
        
        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {

            List<reduivy__Individual_Score_Detail__c> workingList = new List<reduivy__Individual_Score_Detail__c>();
            for (reduivy__Individual_Score_Detail__c objNew : (List<reduivy__Individual_Score_Detail__c>) newList) {
                if(
                    String.isNotBlank(objNew.reduivy__Study_Requirement__c) && 
                    String.isBlank(objNew.reduivy__Individual_Requirement__c)
                ) {
                    workingList.add(objNew);
                }
            }

            if(!workingList.isEmpty()) {
                linkRequirements(workingList);
            }
        }
    }
    

	/**
     * @description BeforeUpdate
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeBeforeUpdate(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {
        
        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {

            List<reduivy__Individual_Score_Detail__c> workingList = new List<reduivy__Individual_Score_Detail__c>();
            for (reduivy__Individual_Score_Detail__c objNew : (List<reduivy__Individual_Score_Detail__c>) newList) {
                reduivy__Individual_Score_Detail__c objOld = (reduivy__Individual_Score_Detail__c) oldMap.get(objNew.Id);
                if(
                    objOld.reduivy__Study_Requirement__c != objNew.reduivy__Study_Requirement__c &&
                    String.isNotBlank(objNew.reduivy__Study_Requirement__c) &&
                    String.isBlank(objNew.reduivy__Individual_Requirement__c)
                ) {
                    workingList.add(objNew);
                }
            }

            if(!workingList.isEmpty()) {
                linkRequirements(workingList);
            }
        }
    }
    


    /**
     * @description links requirements to the inserted/updated individual score details
     * 1 - find any individual requirement created before to avoid creating isq twice
     * 2 - insert irs if the irs is not inserted for the sobject yet
     * 3 - insert irq for the newly created irs, or the created irs if the irq is not found
     * 4 - link isq to isd
     * @param
     * @return void
     */
    private void linkRequirements(List<reduivy__Individual_Score_Detail__c> isdList) {
        Map<String, String> sobjectRelationFieldFromIscMap = new Map<String, String>();
        Map<String, String> sobjectRelationFieldFromIrsMap = new Map<String, String>();

        Map<Id, reduivy__Individual_Score__c> iscMap = getIscMap(isdList);
        Map<Id, reduivy__Individual_Requirement_Set__c> irsMap = new Map<Id, reduivy__Individual_Requirement_Set__c>();
        
        //contrust map of sobject name => name lookup field to sobject from irs
        for(reduivy__Individual_Score__c isc : iscMap.values()) {
            String objectName = isc.reduivy__Study_Scoring_Config__r.reduivy__SObject_Type__c;
            if(!sobjectRelationFieldFromIscMap.containsKey(objectName)) {
                String lookupFieldName = REDU_Metadata_UTIL.getObjectLookupField(ISC_Helper.getApiName(), objectName);
                sobjectRelationFieldFromIscMap.put(objectName, lookupFieldName);
            }
        }
        
        
        //1 - find any individual requirement created before to avoid creating isq twice
        Set<String> irqFields = new Set<String>{
            'Id',
            'Name',
            'reduivy__Study_Requirement__c',
            'reduivy__Study_Requirement__r.reduivy__Study_Requirement_Set__c',
            'reduivy__Study_Requirement__r.reduivy__Study_Requirement_Set__r.reduivy__Object__c',
            'reduivy__Study_Requirement__r.reduivy__Study_Requirement_Set__r.reduivy__Contact_Field__c',
            'reduivy__Individual_Requirement_Set__c'
        };

        Set<String> irsLookupFields = REDU_Metadata_UTIL.getLookupFieldsFromObject(IRS_Helper.getApiName());
        for(String field : irsLookupFields) {
            irqFields.add('reduivy__Individual_Requirement_Set__r.' + field);
        }

        String irqQuery = 'SELECT ' + String.join(irqFields, ', ') +
            ' FROM ' + IRQ_Helper.getApiName() +
            ' WHERE reduivy__Status__c = :irqActive' +
            ' AND reduivy__Study_Requirement__r.reduivy__Status__c = :srqActive';

        Map<String, Object> irqBindMap = new Map<String, Object>{
            'irqActive' => IRQ_Helper.STATUS_ACTIVE,
            'srqActive' => SRQ_Helper.STATUS_ACTIVE
        };

        //These two maps are to store the inserted individual requirement sets and individual requirements. 
        Map<String, Id> sobjIdSrsIdToInsertedIrsIdMap = new Map<String, Id>();
        Map<String, Id> sobjIdSrqIdToInsertedIrqIdMap = new Map<String, Id>();

        for(reduivy__Individual_Requirement__c irq : (List<reduivy__Individual_Requirement__c>) Database.queryWithBinds(irqQuery, irqBindMap, AccessLevel.USER_MODE)) {

            //1.1 - preparing data to create irq or irs
            String objectName = irq.reduivy__Study_Requirement__r.reduivy__Study_Requirement_Set__r.reduivy__Object__c;
            String lookupField;

            if(!sobjectRelationFieldFromIrsMap.containsKey(objectName)) {
                lookupField = REDU_Metadata_UTIL.getObjectLookupField(IRS_Helper.getApiName(), objectName);
                sobjectRelationFieldFromIrsMap.put(objectName, lookupField);
            } else {
                lookupField = sobjectRelationFieldFromIrsMap.get(objectName);
            }
            
            Id sobjId = (Id) (irq.reduivy__Individual_Requirement_Set__r.get(lookupField));
            String irqKey = sobjId + '_' + irq.reduivy__Study_Requirement__c;
            String irsKey = sobjId + '_' + irq.reduivy__Study_Requirement__r.reduivy__Study_Requirement_Set__c;
            sobjIdSrqIdToInsertedIrqIdMap.put(irqKey, irq.Id);
            sobjIdSrsIdToInsertedIrsIdMap.put(irsKey, irq.reduivy__Individual_Requirement_Set__c);
            irsMap.put(irq.reduivy__Individual_Requirement_Set__c, irq.reduivy__Individual_Requirement_Set__r);
        }

        Map<Id, List<reduivy__Individual_Score_Detail__c>> srqUsedToIsdMap = new Map<Id, List<reduivy__Individual_Score_Detail__c>>();
        //1.2 get the study requirement id used by the sobject (to create individual requirement)
        Map<Id, Set<Id>> sobjIdToSrqIdUsedMap = new Map<Id, Set<Id>>();
        for(reduivy__Individual_Score_Detail__c isd : isdList) {

            if(!iscMap.containsKey(isd.reduivy__Individual_Score__c)) {
                continue;
            }
            reduivy__Individual_Score__c isc = iscMap.get(isd.reduivy__Individual_Score__c);

            String objectName = isc.reduivy__Study_Scoring_Config__r.reduivy__SObject_Type__c;
            if(!sobjectRelationFieldFromIscMap.containsKey(objectName)) {
                String errorMsg = String.format(Label.Missing_Object_Record, new List<String>{objectName});
                isd.addError(errorMsg);
                return;
            }

            Id sobjId = (Id) isc.get(sobjectRelationFieldFromIscMap.get(objectName));

            if(String.isBlank(sobjId)) {
                //we cant create individual requirement without sobjid
                continue;
            }

            if(!sobjIdToSrqIdUsedMap.containsKey(sobjId)) {
                sobjIdToSrqIdUsedMap.put(sobjId, new Set<Id>());
            }

            sobjIdToSrqIdUsedMap.get(sobjId).add((Id)isd.reduivy__Study_Requirement__c);

            if(!srqUsedToIsdMap.containsKey((Id)isd.reduivy__Study_Requirement__c)) {
                srqUsedToIsdMap.put((Id)isd.reduivy__Study_Requirement__c, new List<reduivy__Individual_Score_Detail__c>());
            }
            
            srqUsedToIsdMap.get((Id)isd.reduivy__Study_Requirement__c).add(isd);

        }

        //2 - insert irs if the irs is not inserted
        //2.1 - get all of the study requirement and study requirement set that are used by the isd
        List<reduivy__Study_Requirement__c> srqList = getSrq(srqUsedToIsdMap);
        Map<Id, reduivy__Study_Requirement__c> srqMap  = new Map<Id, reduivy__Study_Requirement__c>();
        Map<Id, reduivy__Study_Requirement_Set__c> srsMap  = new Map<Id, reduivy__Study_Requirement_Set__c>();

        for(reduivy__Study_Requirement__c srq : srqList) {

            srqMap.put(srq.Id, srq);
            srsMap.put(srq.reduivy__Study_Requirement_Set__c, (reduivy__Study_Requirement_Set__c) srq.getSObject('reduivy__Study_Requirement_Set__r'));
        }

        //2.2 - get the study requirement set id used by the sobject (to create individual requirement set)
        Map<Id, Set<Id>> sobjIdToSrsIdUsedMap = new Map<Id, Set<Id>>();
        Set<Id> srsIdUsed = new Set<Id>();
        for(Id sobjId : sobjIdToSrqIdUsedMap.keySet()) {
            sobjIdToSrsIdUsedMap.put(sobjId, new Set<Id>());

            for(Id srqId : sobjIdToSrqIdUsedMap.get(sobjId)) {
                Id srsId = srqMap.get(srqId).reduivy__Study_Requirement_Set__c;
                sobjIdToSrsIdUsedMap.get(sobjId).add(srsId);
                srsIdUsed.add(srsId);
            }
        }

        //2.3 construct a map of sobjId => set of srs id that will be used to create new irs.
        Map<Id, Set<Id>> sobjIdToSrsIdToCreateIrsMap = new Map<Id, Set<Id>>();
        for(Id sobjId : sobjIdToSrsIdUsedMap.keySet()) {
            
            for(Id srsId : sobjIdToSrsIdUsedMap.get(sobjId)) {
                String key = sobjId + '_' + srsId;
                if(!sobjIdSrsIdToInsertedIrsIdMap.containsKey(key)){

                    if(!sobjIdToSrsIdToCreateIrsMap.containsKey(sobjId)) {
                            
                        sobjIdToSrsIdToCreateIrsMap.put(sobjId, new Set<Id>());
                    }

                    sobjIdToSrsIdToCreateIrsMap.get(sobjId).add(srsId);
                }
            }
        }
        
        Map<String, reduivy__Individual_Requirement_Set__c> irsToBeInserted = new Map<String, reduivy__Individual_Requirement_Set__c>();
        //2.4 query the id, ownerid, contact of the parent sobjects from individual score to create new irs.
        //we can only do this after the contact fields is queried.
        if(!sobjIdToSrsIdToCreateIrsMap.isEmpty()) {

            Map<Id, SObject> sobjMap = new Map<Id, SObject>();
            
            //sobjFieldsMap is to store the fields to be queried for each sobject
            Map<String, Set<String>> sobjFieldsMap = new Map<String, Set<String>>();
            Set<String> sobjFieldsFromIscSet = new Set<String>{
                'reduivy__Study_Scoring_Config__r.reduivy__SObject_Type__c'
            };
            for(Id sobjId : sobjIdToSrsIdToCreateIrsMap.keySet()) {

                String objectName = sobjId.getSobjectType().getDescribe(Schema.SObjectDescribeOptions.DEFERRED).getName();
                if(!sobjFieldsMap.containsKey(objectName)) {
                    sobjFieldsMap.put(objectName, new Set<String>{'OwnerId', 'Id'});
                }
                
                for(Id srsId : sobjIdToSrsIdToCreateIrsMap.get(sobjId)) {
                    reduivy__Study_Requirement_Set__c srs = srsMap.get(srsId);
                    sobjFieldsMap.get(objectName).add(srs.reduivy__Contact_Field__c);
                }
                
            }
            
            Set<String> sobjConditions = new Set<String>();
            for(String sobjName : sobjFieldsMap.keySet()) {
                String sobjLookupField = sobjectRelationFieldFromIscMap.get(sobjName);

                sobjConditions.add(sobjLookupField + ' IN :sobjIdSet');

                for(String sobjField : sobjFieldsMap.get(sobjName)) {
                    //get the sobject fields from individual score. eg: reduivy__Individual_Program_Application__r.OwnerId
                    sobjFieldsFromIscSet.add(sobjLookupField.removeEnd('__c') + '__r' + '.' + sobjField);
                }
            }

            String sobjQuery = 'SELECT ' + String.join(sobjFieldsFromIscSet, ',') + 
                              ' FROM ' + ISC_Helper.getApiName() +
                              ' WHERE ' + String.join(sobjConditions, ' OR ');

            Map<String, Object> sobjBindMap = new Map<String, Object> {
                'sobjIdSet' => sobjIdToSrsIdToCreateIrsMap.keySet()
            };

            //2.5 construct the sobj map to be used when creating individual requirement set
            for(reduivy__Individual_Score__c iscWithSobj : (List<reduivy__Individual_Score__c>) Database.queryWithBinds(sobjQuery, sobjBindMap, AccessLevel.USER_MODE)) {
                String sobjName = iscWithSobj.reduivy__Study_Scoring_Config__r.reduivy__SObject_Type__c;
                String sobjLookupField = sobjectRelationFieldFromIscMap.get(sobjName);
                sobjMap.put((Id) iscWithSobj.get(sobjLookupField), (SObject) iscWithSobj.getSObject(sobjLookupField.removeEnd('__c') + '__r'));
            }
            
            //2.6 create list of individual requirement set to be inserted
            Map<String, List<SObject>> sobjIdToInsertIrsMap = new Map<String, List<SObject>>();
            for(Id sobjId : sobjIdToSrsIdToCreateIrsMap.keySet()) {
                Boolean isMdRelationship = REDU_Metadata_UTIL.hasMasterDetailRelationship(sobjId.getSobjectType().getDescribe(Schema.SObjectDescribeOptions.DEFERRED).getName());
                SObject sobj = sobjMap.get(sobjId);

                //2.7 create individual requirement set from each study requirement set
                for(Id srsId : sobjIdToSrsIdToCreateIrsMap.get(sobjId)) {
                    String key = sobjId + '_' + srsId;
                    Id ownerId = isMdRelationship ? UserInfo.getUserId() : (Id) sobj.get('OwnerId');

                    reduivy__Study_Requirement_Set__c srs = srsMap.get(srsId);

                    reduivy__Individual_Requirement_Set__c newIrs = IRS_Helper.createIrs(srs, sobj, ownerId);
                    
                    irsToBeInserted.put(key, newIrs);
                    if(!sobjIdToInsertIrsMap.containsKey(sobjId)) {
                        sobjIdToInsertIrsMap.put(sobjId, new List<SObject>());
                    }
                    sobjIdToInsertIrsMap.get(sobjId).add(newIrs);
                }
            }

            if(!irsToBeInserted.isEmpty()) {
                Map<String, List<SObject>> sourceObjMap = constructSourceObjMapForInsert(isdList, iscMap, sobjectRelationFieldFromIscMap);
                REDU_Database_UTIL.doInsert(sobjIdToInsertIrsMap, sourceObjMap, true);
            }

            //2.8 after inserting the irs, put them into irsMap
            for(String key : irsToBeInserted.keySet()) {
                reduivy__Individual_Requirement_Set__c irs = irsToBeInserted.get(key);
                sobjIdSrsIdToInsertedIrsIdMap.put(key, irs.Id);
                irsMap.put(irs.Id, irs);
            }
        }
        
        //need to cater for irs created, but irq not created
        //we will need to create seperate irq for it and then link to the irs
        
        Map<Id, Set<Id>> sobjIdToSrqIdToCreateIrqMap = new Map<Id, Set<Id>>();
        
        //3 - loop through sobjIdToSrqIdUsedMap to find which irq to create
        for(Id sobjId : sobjIdToSrqIdUsedMap.keySet()) {
            for(Id srqIdUsed : sobjIdToSrqIdUsedMap.get(sobjId)) {

                //3.1 mark as to-be-created if the irq is not inserted before
                if(!sobjIdSrqIdToInsertedIrqIdMap.containsKey(sobjId + '_' + srqIdUsed)) {
                    if(!sobjIdToSrqIdToCreateIrqMap.containsKey(sobjId)) {
                        sobjIdToSrqIdToCreateIrqMap.put(sobjId, new Set<Id>());
                    }
                    
                    sobjIdToSrqIdToCreateIrqMap.get(sobjId).add(srqIdUsed);
                }
            }
        }
        Map<String, reduivy__Individual_Requirement__c> irqToBeInserted = new Map<String, reduivy__Individual_Requirement__c>();
        if(!sobjIdToSrqIdToCreateIrqMap.isEmpty()){
            
            Map<String, List<SObject>> sobjIdToInsertIrqMap = new Map<String, List<SObject>>();
            for(Id sobjId : sobjIdToSrqIdToCreateIrqMap.keySet()) {
                String parentSobjectName = sobjId.getSobjectType().getDescribe(schema.SObjectDescribeOptions.DEFERRED).getName();
                for(Id srqIdUsed : sobjIdToSrqIdToCreateIrqMap.get(sobjId)) {
                    //3.2 create irq for each srq used

                    reduivy__Study_Requirement__c srq = srqMap.get(srqIdUsed);
                    
                    //get the srs
                    Id srsId = srq.reduivy__Study_Requirement_Set__c;

                    //get the irs
                    Id irsId = sobjIdSrsIdToInsertedIrsIdMap.get(sobjId + '_' + srsId);

                    Id ownerId = IRQ_Helper.getIrqOwnerId(parentSobjectName, srq, irsMap.get(irsId));

                    reduivy__Individual_Requirement__c newIrq = IRQ_Helper.createIrq(srq, irsId, ownerId);
                    irqToBeInserted.put(sobjId + '_' + srqIdUsed, newIrq);
                    
                    if(!sobjIdToInsertIrqMap.containsKey(sobjId)) {
                        sobjIdToInsertIrqMap.put(sobjId, new List<SObject>());
                    }

                    sobjIdToInsertIrqMap.get(sobjId).add(newIrq);
                }
            }

            if(!irqToBeInserted.isEmpty()) {
                Map<String, List<SObject>> sourceObjMap = constructSourceObjMapForInsert(isdList, iscMap, sobjectRelationFieldFromIscMap);
                REDU_Database_UTIL.doInsert(sobjIdToInsertIrqMap, sourceObjMap, false);

                for(String key : irqToBeInserted.keySet()) {
                    reduivy__Individual_Requirement__c irq = irqToBeInserted.get(key);
                    //3.3 after irq is inserted, add them into sobjIdSrqIdToInsertedIrqIdMap to link to isd later
                    sobjIdSrqIdToInsertedIrqIdMap.put(key,irq.Id);
                }

            }
        }

        //4 - link isq to isd
        for(reduivy__Individual_Score_Detail__c isd : isdList) {

            //get irq id
            Id iscId = isd.reduivy__Individual_Score__c;
            if(String.isBlank(iscId) || !iscMap.containsKey(iscId)) {
                String errorMsg = String.format(Label.Missing_Info_For_Record, new List<String> {ISC_Helper.getApiName(), ISD_Helper.getApiName(), isd.Name});
                isd.addError(errorMsg);
                return;
            }
            String objectName = iscMap.get(iscId).reduivy__Study_Scoring_Config__r.reduivy__SObject_Type__c;
            Id sobjId = (Id) iscMap.get(iscId).get(sobjectRelationFieldFromIscMap.get(objectName));
            if(String.isBlank(sobjId)) {
                String errorMsg = String.format(Label.Missing_Info_For_Record, new List<String> {objectName, ISC_Helper.getApiName(), iscMap.get(iscId).Name});
                isd.addError(errorMsg);
                return;
            }
            
            Id srqId = isd.reduivy__Study_Requirement__c;
            Id newIsqId = sobjIdSrqIdToInsertedIrqIdMap.get(sobjId + '_' + srqId);
            isd.reduivy__Individual_Requirement__c = newIsqId;
        }
    }

    /**
     * @description get map of isc id to isc
     * @param  isdList isdList description
     * @return         return description
     */
    private Map<Id, reduivy__Individual_Score__c> getIscMap(List<reduivy__Individual_Score_Detail__c> isdList){

        Set<Id> iscSet = new Set<Id>();
        for(reduivy__Individual_Score_Detail__c isd : isdList) {
            iscSet.add(isd.reduivy__Individual_Score__c);
        }
        Set<String> iscFields = new Set<String> {
            'Id',
            'Name',
            'reduivy__Study_Scoring_Config__r.reduivy__SObject_Type__c'
        };
        Set<String> isdLookupFields = REDU_Metadata_UTIL.getLookupFieldsFromObject(ISC_Helper.getApiName());
        iscFields.addAll(isdLookupFields);

        String isdQuery = 'SELECT ' + String.join(iscFields, ', ') + 
                         ' FROM ' + ISC_Helper.getApiName() +
                         ' WHERE Id IN :iscSet' ;

        Map<String, Object> bindMap = new Map<String, Object>{
            'iscSet' => iscSet
        };
        
        Map<Id, reduivy__Individual_Score__c> iscMap = new Map<Id, reduivy__Individual_Score__c>();
        for(reduivy__Individual_Score__c isc : (List<reduivy__Individual_Score__c>) Database.queryWithBinds(isdQuery, bindMap, AccessLevel.USER_MODE)) {
            iscMap.put(isc.Id, isc);
        }

        return iscMap;
    }

    private List<reduivy__Study_Requirement__c> getSrq(Map<Id, List<reduivy__Individual_Score_Detail__c>> srqUsedToIsdMap) {
        
        //get the study requirement set id of the study requirement and get the map of sobject id => study requirement id used
        List<reduivy__Study_Requirement__c> srqList = new List<reduivy__Study_Requirement__c>();

        Set<String> srsFields = new Set<String>{
            'reduivy__Contact_Field__c',
            'reduivy__Object__c',
            'Name',
            'Id',
            'reduivy__Status__c'
        };
        srsFields.addAll(IRS_Helper.getSrsIrsCommonFields());
        Set<String> srsFieldsFromSrq = new Set<String>();
        for(String field : srsFields) {
            srsFieldsFromSrq.add('reduivy__Study_Requirement_Set__r.' + field);
        }

        Set<String> srqFields = new Set<String> {
            'Id',
            'Name',
            'reduivy__Study_Requirement_Set__c',
            'reduivy__Due_Days__c',
            'reduivy__Task_Owner_Id__c',
            'reduivy__Status__c'
        };
        srqFields.addAll(IRQ_Helper.getSrqIrqCommonFields());

        String srqQuery = 'SELECT ' + String.join(srqFields, ', ') + ', ' + String.join(srsFieldsFromSrq, ', ')
                       + ' FROM ' + SRQ_Helper.getApiName()
                       + ' WHERE Id IN :srqUsedSet';
        Map<String, Object> srqBindMap = new Map<String, Object> {
            'srqUsedSet' => srqUsedToIsdMap.keySet()
        };

        for(reduivy__Study_Requirement__c srq : (List<reduivy__Study_Requirement__c>) Database.queryWithBinds(srqQuery, srqBindMap, AccessLevel.USER_MODE)){
            if(srq.reduivy__Status__c != SRQ_Helper.STATUS_ACTIVE) { //if the study requirement is not active, throw an error
                for(reduivy__Individual_Score_Detail__c isd : srqUsedToIsdMap.get(srq.Id)) {
                    String errMsg = String.format(Label.Study_Requirement_Used_Is_Inactive, new List<String> {
                        SRQ_Helper.getObjectLabel(),
                        SCR_Helper.getObjectLabel(),
                        srq.Name
                    });

                    isd.addError(errMsg);
                }
            }
            if(srq.reduivy__Study_Requirement_Set__r.reduivy__Status__c != SRS_Helper.STATUS_ACTIVE) {
                
                for(reduivy__Individual_Score_Detail__c isd : srqUsedToIsdMap.get(srq.Id)) {
                    String errMsg = String.format(Label.Study_Requirement_Set_Used_Is_Inactive, new List<String> {
                        SRS_Helper.getObjectLabel(),
                        SCR_Helper.getObjectLabel(),
                        srq.reduivy__Study_Requirement_Set__r.Name
                    });

                    isd.addError(errMsg);
                }
            }


            srqList.add(srq);
        }

        return srqList;
    }

    private Map<String, List<SObject>> constructSourceObjMapForInsert(List<reduivy__Individual_Score_Detail__c> sourceIsdList, Map<Id, reduivy__Individual_Score__c> iscMap, Map<String, String> sobjectRelationFieldFromIscMap) {
        //sobjId => list of isd
        if(sourceObjMapForInsert == null) {
            sourceObjMapForInsert = new Map<String, List<SObject>>();

            for(reduivy__Individual_Score_Detail__c isd : sourceIsdList) {
                reduivy__Individual_Score__c isc = iscMap.get(isd.reduivy__Individual_Score__c);

                String sobjectName = isc.reduivy__Study_Scoring_Config__r.reduivy__SObject_Type__c;
                String lookupFieldName = sobjectRelationFieldFromIscMap.get(sobjectName);
                Id parentSobjectId = (Id) isc.get(lookupFieldName);

                if(!sourceObjMapForInsert.containsKey(parentSobjectId)) {
                    sourceObjMapForInsert.put(parentSobjectId, new List<SObject>());
                }

                sourceObjMapForInsert.get(parentSobjectId).add(isd);

            }
        }
        return sourceObjMapForInsert;
    }
}