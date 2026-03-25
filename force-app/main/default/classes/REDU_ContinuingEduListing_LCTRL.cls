/**
 * @author      WDCi (Jordan)
 * @date        Mar 2024
 * @group       Continuing Education
 * @description Controller for continuingEduListing
 * @changehistory
 * ISS-001844 12-03-2024 Jordan - new class
 * ISS-002495 10-10-2025 XW - support translation for long text
 */
public with sharing class REDU_ContinuingEduListing_LCTRL {
    
	//This method is used to fetch the records according to predefined filters applied by admin.
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse fetchingObjectRecords(String objectName, List<String> fieldApiNames, String sortByField1ApiName, String sortByField2ApiName, String predefinedFilters, String searchFieldApiName, String searchValue, String customFilterConfigs, String language) {
        try {

            if(String.isBlank(language)) {
                language = UserInfo.getLanguage();
            }
            
            if(String.isNotBlank(sortByField1ApiName) && !fieldApiNames.contains(sortByField1ApiName)) {
                fieldApiNames.add(sortByField1ApiName);
            }
            
            if(String.isNotBlank(sortByField2ApiName) && !fieldApiNames.contains(sortByField2ApiName)) {
                fieldApiNames.add(sortByField2ApiName);
            }

            Map<String, Object> objBindParams = new Map<String, Object>();
            String queryString = 'SELECT ' + String.join(new List<String>(fieldApiNames), ',');
            queryString += ' FROM ' + objectName + ' ';
            
            if (String.isNotBlank(predefinedFilters)) {
                queryString += ' WHERE ';
                queryString += predefinedFilters;
            }

            if (String.isNotBlank(searchValue)) {
                if (String.isBlank(predefinedFilters)) {
                    queryString += ' WHERE ';
                } else {
                    queryString += ' AND ';
                }

                objBindParams.put(searchFieldApiName, '%' + searchValue + '%');
                queryString += searchFieldApiName + ' LIKE :' + searchFieldApiName;
            }

            if (String.isNotBlank(customFilterConfigs)) {
                List<String> targetFieldBinders = new List<String>();
                List<REDU_CustomFilter_OBJ> customFilters = (List<REDU_CustomFilter_OBJ>) JSON.deserialize(customFilterConfigs, List<REDU_CustomFilter_OBJ>.class);
                for (REDU_CustomFilter_OBJ cf : customFilters) {
                    if (cf.isValid()) {
                        objBindParams.putAll(cf.getBindParams());
                        targetFieldBinders.add(cf.getQueryBinder());
                    }
                }

                if (!targetFieldBinders.isEmpty()) {
                    if (String.isBlank(predefinedFilters) && String.isBlank(searchValue)) {
                        queryString += ' WHERE ';
                    } else {
                        queryString += ' AND ';
                    }

                    queryString += String.join(targetFieldBinders, ' AND ');
                }
            }

            REDU_Logging_UTIL.debug('queryString  ::', queryString);

            List<sObject> objectRecords = new List<sObject>();
            for(sObject obj : Database.queryWithBinds(queryString, objBindParams, AccessLevel.USER_MODE)){
                objectRecords.add(obj);
            }

            Map<String, Object> translationInfo = REDU_TranslationManager.getTranslationInfo(objectName, objectRecords, fieldApiNames, language);

            Map<String, Object> responseData = new Map<String, Object>{
                'rawData' => objectRecords,
                REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM => translationInfo
            };
            
            if(!objectRecords.isEmpty()) {
                return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(responseData));
            } else {
                return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, null);
            }
        } catch (QueryException qex) {
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);
        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }
}