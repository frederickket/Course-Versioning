/**
 * @Author 		WDCi (Lean)
 * @Date 		Oct 2023
 * @group 		Utility
 * @Description Utility for lwc
 * @changehistory
 * ISS-001752 05-10-2022 Lean - new component
 * ISS-002230 05-02-2025 XW - get picklist value label if field type is picklist
 * ISS-002329 12-03-2025 Lean - handle null value when preparing datatable records
 * ISS-002604 12-09-2025 Lean - Added fallback url for file download
 * ISS-002495 19-09-2025 XW - support translation for long text field
 * ISS-002654 03-10-2025 Lean - Added method to calculate column size
 * ISS-002719 07-11-2025 XW - allow option to be non-selectable if isSelectable is false (setupPicklistOptionsFromRecords)
 * ISS-002736 26-11-2025 XiRouh - Added isWrapTextEnabled
 * ISS-002747 28-11-2025 Lean - Fixed JS decimal issue
 * ISS-002779 21-01-2026 Lean - Make table header to respect tableTextDisplayMode
 */
import { LightningElement } from 'lwc';

const USER_MODE_ADMIN = 'Admin';
const USER_MODE_STUDENT = 'Student';
const USER_MODE_FACULTY = 'Faculty';

const TABLE_TEXT_DISPLAY_MODE_WRAP_TEXT = 'Wrap Text';
const TABLE_TEXT_DISPLAY_MODE_CLIP_TEXT = 'Clip Text';

const PICKLIST_LABEL = '_PicklistLabel';
const FILE_DOWNLOAD_FALLBACK_URL = '/sfc/servlet.shepherd/version/download/{0}?operationContext=S1';

/**
 * @description Pathway constants
 */
const commonConstants = {
    USER_MODE_ADMIN,
    USER_MODE_STUDENT,
    USER_MODE_FACULTY,
    PICKLIST_LABEL,
    TABLE_TEXT_DISPLAY_MODE_WRAP_TEXT,
    TABLE_TEXT_DISPLAY_MODE_CLIP_TEXT
}

/**
 * @description Generate a new epoch time to act as cache index
 * @returns Date
 */
const initCacheIdx = () => {
    return new Date().getTime();
}

/**
 * @description Return the object with new lwcReactor value to force the rerendering
 * @param obj
 * @return obj
 */
const updatedObjReactor = (obj) => {
    obj.lwcReactor = Math.floor((Math.random() * 100) + 1) + ' reactor updated';

    return obj;
}

/**
 * @descripton Format date to string based on user local and timezone
 * @param {*} dateValue 
 * @param {*} locale 
 * @param {*} timezone 
 * @returns 
 */
const formatDate = (dateValue, locale, timezone) => {
    let options = {
        dateStyle: "medium",
        timeZone: timezone,
    };

    return new Intl.DateTimeFormat(locale, options).format(dateValue);
}

/**
 * @descripton Format datetime to string based on user local and timezone
 * @param {*} dateValue 
 * @param {*} locale 
 * @param {*} timezone 
 * @returns 
 */
const formatDateTime = (dateValue, locale, timezone) => {
    let options = {
        year: 'numeric',
        month: 'numeric',
        day: 'numeric',
        hour: 'numeric',
        minute: '2-digit',
        timeZone: timezone,
    };

    return new Intl.DateTimeFormat(locale, options).format(dateValue);
}

/**
 * @description Format language code from web to POSIX/java format en-US to en_US
 * @param {*} language
 * @returns String
 */
const formatLanguageCodeToPosix = (language) => {
    // ISS-002797 new method
    if (language) {
        return language.replace("-", "_");
    }

    return null;
}

/**
 * @description Extract field value from sobj based on the field name
 * @param {*} targetObj 
 * @param {*} fieldName 
 * @param {*} translationInfo the translationInfo object from translation util class. can be undefined
 * @param {*} language the user language. can be undefined
 * @returns Obj
 */
const extractFieldValue = (targetObj, fieldName, translationInfo, language) => {

    let val;
    let sobjHolder = targetObj;

    language = formatLanguageCodeToPosix(language);

    if (sobjHolder && fieldName) {
        let counter = 0;
        let splittedNames = fieldName.split('.');
        for(let splittedName of splittedNames){
            if(counter !== (splittedNames.length - 1) && sobjHolder !== null){
                sobjHolder = sobjHolder?.[splittedName] ?? null;
            } else {
                val = (sobjHolder != null && Object.hasOwn(sobjHolder, splittedName) ? sobjHolder[splittedName] : null);
                if(translationInfo && language) {
                    let translationData = translationInfo.translations?.find(t => t.languageCode === language)?.data;

                    let translatedVal = translationData?.[sobjHolder?.Id]?.[splittedName];
                    if(translatedVal) {
                        val = translatedVal;
                    }
                }
            }
            
            counter ++;
        }

    }

    return val;
}

/**
 * @description To update the datatableConfig to flatten the parent object fields to the root and make name fields clickable
 * @param {*} datatableConfig 
 * @param {*} isCommunity 
 * @param {*} language the user language. can be undefined
 * @returns datatableConfig
 */
const updateDatatableConfig = (datatableConfig, isCommunity, language) => {

    if(Array.isArray(datatableConfig.records) && datatableConfig.records.length){
        
        language = formatLanguageCodeToPosix(language);

        let refLinks = datatableConfig.refLinks;
        //translation, to replace default
        //if found translations that matches user language, perform translation
        let translation;
        if(datatableConfig.translationInfo && language) {
            translation = datatableConfig.translationInfo?.translations?.find(curTranslation => curTranslation.languageCode === language);
        }
        
        datatableConfig.records.forEach(function(record){
            
            //Prepare url link (e.i. community or salesforce internal)
            //TODO The "detail" won't work for LWR as it no longer has a generic object page like Aura site
            let path = '';
            if(isCommunity){
                let urlString = datatableConfig.sitePathPrefix;
                if (urlString.endsWith("/")) {
                    path = urlString + 'detail';
                } else {
                    path = urlString + '/detail';
                }
            }

            for(let i = 0; i < refLinks.length; i ++){
                
                let refLink = refLinks[i];

                let refObjFields = refLink.linkFieldValue.split('.');
                let refVal = refObjFields.reduce((rof, key) => rof && rof[key], record);
                let refRecordIdFields = refLink.linkFieldReferenceId.split('.');
                let recordId = refRecordIdFields.reduce((rof, key) => rof && rof[key], record);

                if (refVal || translation) {
                    //if refVal is empty (the source field is not populated), there might be a chance that the value is in the translation record
                    let refObjLabels = refLink.linkFieldLabel.split('.');
                    
                    let translatedField = refObjLabels[refObjLabels.length - 1];
                    let translatedValue;
                    if(translation?.data?.[recordId]?.[translatedField]) {
                        translatedValue = translation?.data?.[recordId]?.[translatedField];
                        record[refLink.linkFieldLabel] = translatedValue
                    } else {
                        record[refLink.linkFieldLabel] = refObjLabels.reduce((rol, key) => rol && rol[key], record);
                    }

                    if(record[refLink.linkFieldLabel]) {
                        if (refLink.linkFieldType === 'url') {
                            record[refLink.linkFieldName] = path + '/' + recordId;
                        } else {
                            record[refLink.linkFieldName] = translatedValue ?? refVal;
                        }
                    }
                        
                }
                
            }
        });
    }

    return datatableConfig;
}

/**
 * @description Extract merge field keys from the string based on the curly braces
 * @param {*} stringFormat 
 * @returns String array
 */
const getMergeKeys = (stringFormat, removeCurlyBraces) => {

    if (stringFormat) {
        const regExp = /{([^}]*)}/g;
        let keyList = stringFormat.match(regExp);
        if(removeCurlyBraces && Array.isArray(keyList) && keyList.length) {
            for(let [idx, key] of keyList.entries()) {
                keyList[idx] = key.replace('{', '').replace('}', '');
            }
        }
        return keyList;
    }

    return [];
}
 
/**
 * @description Check if the record has the field even if the field has more than 1 level
 * @param {*} record The record to check
 * @param {*} field The field name to check. eg: 'Account.Name'
 * @returns 
 */
const hasOwnNestedProperty = (record, field) => {
    if(!record) {
        return false;
    }
    if(Object.prototype.hasOwnProperty.call(record, field)) {
        return true;
    }

    return field.split('.').reduce((acc, key) => 
        (acc && Object.prototype.hasOwnProperty.call(acc, key) ? acc[key] : undefined), record
    ) !== undefined;
}

/**
 * @description Format the merge fields of a string with the actual value
 * @param {*} stringFormat 
 * @param {*} mergeKeys 
 * @param {*} objects
 * @returns String
 */
const mergeValues = (stringFormat, mergeKeys, obj, usePicklistLabel = true, translationInfo, language) => {

    if (stringFormat && mergeKeys && obj) {
        let formattedString = stringFormat;

        for (let mergeKey of mergeKeys) {
            let cleansedKey = mergeKey.replace("{", "").replace("}", "");
            let labelfiedCleansedKey = cleansedKey + PICKLIST_LABEL;
            if(hasOwnNestedProperty(obj, labelfiedCleansedKey) && usePicklistLabel){
                cleansedKey = labelfiedCleansedKey
            }

            let val = extractFieldValue(obj, cleansedKey, translationInfo, language);
            if(val === null)  {
                return null;
            }
            formattedString = formattedString.replace(mergeKey, val);
            
            
        }

        return formattedString;
    }

    return "";
}

/**
 * @description To init the picklist options with label and subinfo
 * @param {*} data 
 * @param {*} infoField 
 * @param {*} metaInfoFields 
 * @returns Array
 */
const setupPicklistOptionsFromRecords = (data, infoField, metaInfoFields) => {

    let options = [];

    if (data) {
        for (let rec of data) {
            let optLabel = rec.Name;
            let optValue = rec.Id;
            let metaInfo = [];

            if (infoField) {
                let infoVal = extractFieldValue(rec, infoField);
                if (infoVal) {
                    optLabel += ' - ' + infoVal;
                }
            }

            if (metaInfoFields) {
                for (let mif of metaInfoFields) {
                    let metaInfoVal = extractFieldValue(rec, mif.field);
                    if (metaInfoVal) {
                        metaInfo.push(mif.label + ': ' + metaInfoVal);
                    }
                }
            }

            let option = {
                label: optLabel,
                value: optValue,
                metaInfo: metaInfo,
            }

            if(Object.hasOwn(rec, 'isSelectable')) {
                option.isSelectable = rec.isSelectable;
            }
            

            options.push(option);
        }
    }

    return options;
}

/**
 * @description Return data field value based on the data type
 * @param {*} dataFieldType 
 * @param {*} dataFieldValue 
 */
const getFormDataFieldOnChangeValue = (dataDisplayType, dataDetail) => {

    let dataFieldValue;

    if (dataDisplayType === 'BOOLEAN') {
        dataFieldValue = dataDetail?.checked;

    } else if (dataDisplayType === 'TIME') {
        if (dataDetail?.value) {
            dataFieldValue = dataDetail.value + 'Z';
        } else {
            dataFieldValue = null;
        }

    } else if (Array.isArray(dataDetail?.value) && dataDetail?.value.length === 1) {
        //reference type is returned as array, we need to change to string otherwise the saving will fail
        dataFieldValue = dataDetail?.value[0];

    } else {
        dataFieldValue = dataDetail?.value;
    }

    return dataFieldValue;

}

/**
 * @description Return the object without the attributes that ends with "_Label"
 * @param {*} obj Object to cleanse
 */
const removeLabelAttributes = (obj) => {

    for (let key in obj) {
        if (Object.hasOwn(obj, key)) {
            // If the value is an object, recurse into it
            if (typeof obj[key] === 'object' && obj[key] !== null) {
                removeLabelAttributes(obj[key]);
            }

            // If the key ends with '_PicklistLabel', delete it
            if (key.endsWith(PICKLIST_LABEL)) {
                delete obj[key];
            }
        }
    }

    return obj;
}

/**
 * @description flatten the object from multiple layer to only a layer
 * @param {*} ob Object to flatten
 * @returns flatten object with only a layer
 */
const flattenObj = (ob) => {

    let result = {};

    for (const i in ob) {

        if ((typeof ob[i]) === 'object' && !Array.isArray(ob[i])) {
            const temp = flattenObj(ob[i]);
            for (const j in temp) {
                result[i + '.' + j] = temp[j];
            }
        }
        else {
            result[i] = ob[i];
        }
    }
    return result;
};

/**
 * @description Construct file download url
 * @param {*} sitePath digital experience site path
 * @param {*} downloadUrl download sub path
 * @param {*} cvId content version id
 * @returns 
 */
const getFileDownloadUrl = (sitePath, downloadUrl, cvId) => {

    let targetSitePath = sitePath ? sitePath : '';
    let targetDownloadUrl;

    if (downloadUrl) {
        if (downloadUrl.startsWith('https://') || downloadUrl.startsWith('http://')) {
            targetDownloadUrl = downloadUrl;
        }

        targetDownloadUrl = targetSitePath + downloadUrl;
    } else {
        targetDownloadUrl = targetSitePath + FILE_DOWNLOAD_FALLBACK_URL;
    }

    return targetDownloadUrl?.format([cvId]);

}

/**
 * @description ISS-002654 Return column number for layout item based on grid of 12
 * @param {*} colNo Column number
 * @param {*} defaultColNo Default fallback Column number
 * @returns
 */
const getColumnSize = (colNo, defaultColNo) => {

    if (!colNo) {
        colNo = defaultColNo;
    }

    if (colNo) {
        return 12 / colNo;
    }

    //return 6 which results in 2 column per row as default
    return 6;
}

/**
 * @description Check if table text display mode is set to wrap text
 * @param {*} tableTextDisplayMode The table text display mode
 * @returns Boolean
 */
const isWrapTextEnabled = (tableTextDisplayMode) => {
    return tableTextDisplayMode === TABLE_TEXT_DISPLAY_MODE_WRAP_TEXT;
}

/**
 * @description Return the table header text display mode based on the setting
 * @param {*} tableTextDisplayMode The table text display mode
 * @returns String
 */
const getTableHeaderDisplayMode = (tableTextDisplayMode) => {
    //ISS-002779 lightning-datatable wrap-table-header supported options: all = wrap, none = clip
    return tableTextDisplayMode === TABLE_TEXT_DISPLAY_MODE_WRAP_TEXT ? 'all' : 'none';
}

/**
 * @description Round javascript float to 2 decimal points as a workaround for JS float issue (https://medium.com/tapro-labs/dealing-with-floating-point-numbers-in-javascript-lessons-learned-8e940cc7f1e0)
 * @param {*} val 
 * @param {*} decimalPoint 
 * @returns Float
 */
const roundFloat = (val, decimalPoint) => {
    //ISS-002747 new method
    
    if (val !== null && val !== undefined && !isNaN(val) && decimalPoint >= 0) {
        // Multiply by 10^decimalPoint, round to nearest integer, then divide by 10^decimalPoint
        const factor = Math.pow(10, decimalPoint);
        return Math.round(val * factor) / factor;
    }

    return val; // Return the value unchanged if it's not a valid number or decimalPoint is invalid
};

export { 
    updatedObjReactor, 
    formatDate, 
    formatDateTime, 
    extractFieldValue, 
    updateDatatableConfig, 
    getMergeKeys, 
    mergeValues, 
    initCacheIdx,
    setupPicklistOptionsFromRecords,
    getFormDataFieldOnChangeValue,
    hasOwnNestedProperty,
    removeLabelAttributes,
    flattenObj,
    getFileDownloadUrl,
    getColumnSize,
    isWrapTextEnabled,
    getTableHeaderDisplayMode,
    roundFloat,
    formatLanguageCodeToPosix,
    commonConstants
};

export default class LwcUtil extends LightningElement {}