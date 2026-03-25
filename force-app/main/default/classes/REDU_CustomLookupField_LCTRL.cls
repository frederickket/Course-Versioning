/**
 * @author      WDCi (XW)
 * @date        Nov 2025
 * @group       Custom Lookup Field
 * @description 
 * @changehistory
 * ISS-002633 12-11-2025 XW - description
 */

public with sharing class REDU_CustomLookupField_LCTRL {

    /**
     * @description get the first 5 possible records
     * @param  lookupObjectName    the object reference name of the lookup field
     * @param  fields              fields to query and use in lwc
     * @param  searchFields        fields to search
     * @param  searchKeyword       keyword to search
     * @param  customFilter        custom filter when querying possible records
     * @param  customFilterBindMap custom filter bind map
     * @param  language            language
     * @return                     List of sobj, object icon name and the translation info
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getRecords(String lookupObjectName, List<String> fields, String searchFields, String searchKeyword, String customFilter, Map<String, Object> customFilterBindMap, String language){

        try {
            Map<String, Object> responseData = new Map<String, Object>();
            
            if(String.isNotBlank(lookupObjectName)) {
                if(String.isBlank(language)) {
                    language = UserInfo.getLanguage();
                }
                
                Map<String, Object> bindMap = new Map<String, Object>();
                if(customFilterBindMap != null && !customFilterBindMap.isEmpty()) {
                    REDU_Logging_UTIL.debugJsonString('customFilterBindMap', customFilterBindMap);
                    bindMap.putAll(customFilterBindMap);
                }

                Set<String> searchKeywordSet = new Set<String>();
                if(String.isNotBlank(searchKeyword)) {
                    Set<String> searchFieldsSet = new Set<String>(searchFields.split(';'));
                    
                    Schema.SObjectType rootSobjType = REDU_Metadata_UTIL.getSObjectType(lookupObjectName);
                    
                    for(String searchField : searchFieldsSet) {
                        Schema.DescribeFieldResult dfr = REDU_Datatable_UTIL.getFieldDescribe(searchField, rootSobjType);
                        Schema.SObjectType sobjType = dfr.getSObjectType();
                        String sobjectName = sobjType.getDescribe(Schema.SObjectDescribeOptions.DEFERRED).getName();
                        Map<String, REDU_TranslationManager.TranslationMapping> translationMappingMap = REDU_TranslationManager.getTranslationMappingConfigByObject(sobjectName);

                    
                        if(dfr?.getType() == Schema.DisplayType.STRING) {
                            String translatedSearchField = searchField;
                            if(translationMappingMap.containsKey(dfr.getName())) {
                                REDU_TranslationManager.TranslationMapping translationWrapper = translationMappingMap.get(dfr.getName());
                                String referencedLanguageField = translationWrapper.getReferencedLanguageField(language);
                                translatedSearchField = translationWrapper.translationField.removeEnd('__c') + '__r.' + referencedLanguageField;

                            } else if(dfr.getName() == 'Name') {
                                String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(sobjType.getDescribe(Schema.SObjectDescribeOptions.DEFERRED));
                                translatedSearchField = String.isBlank(formulaFieldName) ? ( lookupObjectName == STM_Helper.getApiName() ? 'reduivy__Display_Name__c' : 'Name') : formulaFieldName;
                            }

                            
                            //it is possible that the search field is from parent object, so we need to construct the path to the parent field.
                            if(dfr.getType() !== Schema.DisplayType.REFERENCE && searchField.contains('.')) {
                                String relationPath = searchField.substringBeforeLast('.');
                                if(String.isNotBlank(relationPath)) {
                                    translatedSearchField = relationPath + '.' + translatedSearchField;
                                }
                            }
                            searchKeywordSet.add(translatedSearchField + ' LIKE :searchKeyword');


                            //we also need to include the field with original value (in case the translation map or translation record is empty)
                            if(translatedSearchField != searchField) {
                                searchKeywordSet.add(searchField + ' LIKE :searchKeyword');
                            }
                            
                        }
                    }
                    bindMap.put('searchKeyword', '%' + searchKeyword + '%');
                }

                String soqlQuery = 'SELECT ' + String.join(new Set<String>(fields), ', ')
                                + ' FROM ' + lookupObjectName;
                
                if(!searchKeywordSet.isEmpty() || String.isNotBlank(customFilter)) {
                    soqlQuery += ' WHERE ';
                    if(!searchKeywordSet.isEmpty()) {
                        soqlQuery += ('(' + String.join(searchKeywordSet, ' OR ') + ')');
                        soqlQuery += String.isNotBlank(customFilter) ? ' AND ' : '';
                    }
                    if (String.isNotBlank(customFilter)) {
                        soqlQuery += customFilter;
                    }
                }

                Schema.DescribeSObjectResult describeSobject = REDU_Metadata_UTIL.describeSObject(lookupObjectName);
                if(String.isBlank(customFilter) || !customFilter.containsIgnoreCase('ORDER BY')) {
                    if(describeSobject.fields.getMap().containsKey('LastViewedDate')) {
                        soqlQuery += ' ORDER BY LastViewedDate DESC';
                    } else {
                        soqlQuery += ' ORDER BY Name ASC';
                    }
                }

                soqlQuery += (String.isNotBlank(customFilter) && customFilter.containsIgnoreCase('LIMIT ') ? '' : ' LIMIT 5');
                

                List<SObject> sobjList = new List<SObject>();
                REDU_Logging_UTIL.debug('soqlQuery', soqlQuery);
                for(SObject sobj : Database.queryWithBinds(soqlQuery, bindMap, AccessLevel.USER_MODE)){
                    sobjList.add(sobj);
                }
                
                REDU_Logging_UTIL.debugJsonString('responseData', responseData);

                responseData.put('sobjList', sobjList);
                responseData.put('objectIconName', REDU_Metadata_UTIL.getObjectIcon(lookupObjectName));
                responseData.put(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM, REDU_TranslationManager.getTranslationInfo(lookupObjectName, sobjList, fields, language));
            }

            return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(responseData));

        } catch (QueryException qex) {
            REDU_Logging_UTIL.debug(qex);

            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, false);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);

            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    /**
     * @description get the info of the selected record based on id
     * @param  lookupObjectName the object reference name of the lookup field
     * @param  fields           fields to query and use in lwc
     * @param  selectedRecordId the selected record id
     * @param  language         language
     * @return                  List of sobj, object icon name and the translation info
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getSelectedRecord(String lookupObjectName, List<String> fields, String selectedRecordId, String language) {
        
        try {
            Map<String, Object> responseData = new Map<String, Object>();
            List<SObject> sobjList = new List<SObject>();
            
            if(String.isNotBlank(lookupObjectName)) {

                Set<String> fieldSet = new Set<String>(fields);
                String soqlQuery = 'SELECT ' + String.join(fieldSet, ', ')
                                + ' FROM ' + lookupObjectName
                                + ' WHERE Id = :selectedRecordId '
                                + ' LIMIT 1';
                Map<String, Object> bindMap = new Map<String, Object> {
                    'selectedRecordId' => selectedRecordId
                };
                
                REDU_Logging_UTIL.debug('soqlQuery', soqlQuery);
                for(SObject sobj : Database.queryWithBinds(soqlQuery, bindMap, AccessLevel.USER_MODE)) {
                    sobjList.add(sobj);
                }
            }

            responseData.put('sobjList', sobjList);
            responseData.put('objectIconName', REDU_Metadata_UTIL.getObjectIcon(lookupObjectName));
            responseData.put(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM, REDU_TranslationManager.getTranslationInfo(lookupObjectName, sobjList, fields, language));

            REDU_Logging_UTIL.debugJsonString('responseData', responseData);
            return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(responseData));
        } catch (QueryException qex) {
            REDU_Logging_UTIL.debug(qex);

            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, false);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);

            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    /**
     * @description get the lookup field info (lookup field reference object and the label)
     * @param  rootObjectName  the root object name of the field
     * @param  lookupFieldName the lookup field name
     * @return                 fieldLabel and fieldReferenceObjectName
     */
    @AuraEnabled
    public static REDU_LightningResponse getLookupFieldInfo(String rootObjectName, String lookupFieldName) {
        
        try {
            Map<String, Object> responseData = new Map<String, Object>();
            Schema.DescribeFieldResult dfr = REDU_Metadata_UTIL.describeSObjectField(rootObjectName, lookupFieldName);

            responseData.put('fieldLabel', dfr.getLabel());
            responseData.put('fieldReferenceObjectName', dfr.getReferenceTo()[0].getDescribe(Schema.SObjectDescribeOptions.DEFERRED).getName());

            REDU_Logging_UTIL.debugJsonString('responseData', responseData);
            return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(responseData));
        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);

            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    /**
     * @description update the last viewed so that it can be the first record in the selectable record list
     * @param  recordId record id to update
     */
    @AuraEnabled
    public static void updateRecordLastViewed(String recordId) {
        
        try {
            Schema.DescribeSObjectResult describeSobject = Id.valueOf(recordId).getSobjectType().getDescribe(Schema.SObjectDescribeOptions.DEFERRED);
            //We cant use FOR VIEW/REFERENCE if the object doesnt have a tab
            if(!describeSobject.fields.getMap().containsKey('LastViewedDate')) { 
                return;
            }

            if (String.isNotBlank(recordId)) {
                Id targetRecord = Id.valueOf(recordId);
                String objectType = targetRecord.getSobjectType().getDescribe().getName();

                String soqlQuery = 'SELECT Id, Name FROM ' + objectType + ' WHERE Id =: recordId LIMIT 1 FOR VIEW';
                Map<String, Object> bindMap = new Map<String, Object>{
                    'recordId' => recordId
                };
                List<SObject> records = Database.queryWithBinds(soqlQuery, bindMap, AccessLevel.USER_MODE);
            }
        } catch (QueryException qex) {
            REDU_Logging_UTIL.debug(qex);

            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, false);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);

            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

}
