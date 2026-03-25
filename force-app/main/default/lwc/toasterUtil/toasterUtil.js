/**
 * @Author 		WDCi (Lean)
 * @Date 		March 2023
 * @group 		Uti
 * @Description Platform show toast event utility for LWC
 * @changehistory
 * ISS-001864 07-03-2024 Lean - Changed to use Toast as platformShowToastEvent is not supported in LWR site
 */
import { LightningElement } from 'lwc';

import Toast from 'lightning/toast';
import LightningAlert from 'lightning/alert';
import { getErrorMessage } from 'c/loggingUtil';

import ctrlGetToasterConfigs from '@salesforce/apex/REDU_Toaster_LCTRL.getToasterConfigs';

let infoVariant = 'info';
let warningVariant = 'warning';
let errorVariant = 'error';
let successVariant = 'success';

let infoNotificationType;
let warningNotificationType;
let errorNotificationType;
let successNotificationType;

/**
 * @description Load toaster settings
 */
ctrlGetToasterConfigs({})
.then(data => {
    if (data) {

        let responseData = JSON.parse(data.responseData);

        if (responseData?.info) {
            if (responseData?.info?.reduivy__Notification_Type__c) {
                infoNotificationType = responseData?.info?.reduivy__Notification_Type__c;
            }

            if (responseData?.info?.reduivy__Variant_or_Theme__c) {
                infoVariant = responseData?.info?.reduivy__Variant_or_Theme__c;
            }
        }

        if (responseData?.warning) {
            if (responseData?.warning?.reduivy__Notification_Type__c) {
                warningNotificationType = responseData?.warning?.reduivy__Notification_Type__c;
            }

            if (responseData?.warning?.reduivy__Variant_or_Theme__c) {
                warningVariant = responseData?.warning?.reduivy__Variant_or_Theme__c;
            }
        }

        if (responseData?.error) {
            if (responseData?.error?.reduivy__Notification_Type__c) {
                errorNotificationType = responseData?.error?.reduivy__Notification_Type__c;
            }

            if (responseData?.error?.reduivy__Variant_or_Theme__c) {
                errorVariant = responseData?.error?.reduivy__Variant_or_Theme__c;
            }
        }

        if (responseData?.success) {
            if (responseData?.success?.reduivy__Notification_Type__c) {
                successNotificationType = responseData?.success?.reduivy__Notification_Type__c;
            }

            if (responseData?.success?.reduivy__Variant_or_Theme__c) {
                successVariant = responseData?.success?.reduivy__Variant_or_Theme__c;
            }
        }
    }
})
.catch(error => {
    console.error('Error fetching toast configs:', getErrorMessage(error));
});

/**
 * @description To replace the indexed placeholders with the corresponding links e.g., "my {0} is {1}" with links = [{label: "My Link", url: "https://www.google.com"}, {label: "My Link 2", url: "https://www.google.com"}]
 * @param {*} text 
 * @param {*} links 
 * @returns 
 */
const replaceIndexedPlaceholders = (text, links) => {
    if (text && links) {
        return text.replace(/{(\d+)}/g, (_, index) => {
            const link = links[index];
            return link ? `${link?.label} [${link?.url}]` : `{${index}}`;
        });
    }

    return text;
}

/**
 * @description To replace the named placeholders with the corresponding links e.g., "my {name} is {age}" with [{name: {url: 'xxx', label: 'xxx'}, age: {a: 'xxx', label: 'xxx'}}]
 * @param {*} text 
 * @param {*} links 
 * @returns 
 */
const replaceNamedPlaceholders = (text, links) => {
    if (text && links) {
        return text.replace(/{(.*?)}/g, (_, key) => {
            const link = links[key];
            return link ? `${link?.label} [${link?.url}]` : `{${key}}`;
        });
    }

    return text;
}

/**
 * @description Format and return the text with links
 * @param {*} text 
 * @param {*} links 
 * @returns 
 */
const formatText = (text, links) => {

    if (text && links) {
        text = replaceIndexedPlaceholders(text, links);
        text = replaceNamedPlaceholders(text, links);
    }

    return text;
}

/**
 * @description Prompt info with the given label, message, labelLinks and messageLinks
 * @param {*} label 
 * @param {*} message 
 * @param {*} labelLinks 
 * @param {*} messageLinks 
 */
const promptInfo = (label, message, labelLinks, messageLinks) =>{

    if (infoNotificationType === "Alert") {

        let formattedMsg = formatText(message, messageLinks);
        let formattedLabel = formatText(label, labelLinks);

        LightningAlert.open({
            message: formattedMsg || formattedLabel,
            theme: infoVariant,
            label: formattedLabel
        });
        
    } else {
        Toast.show({
            label: label,
            labelLinks: labelLinks,
            messageLinks : messageLinks,
            message: message,        
            variant: infoVariant
        }, this);
    }
}

/**
 * @description Prompt error with the given label, message, labelLinks and messageLinks
 * @param {*} label 
 * @param {*} message 
 * @param {*} labelLinks 
 * @param {*} messageLinks 
 */
const promptError = (label, message, labelLinks, messageLinks) => {

    if (errorNotificationType === "Alert") {

        let formattedMsg = formatText(message, messageLinks);
        let formattedLabel = formatText(label, labelLinks);

        LightningAlert.open({
            message: formattedMsg || formattedLabel,
            theme: errorVariant,
            label: formattedLabel
        });
        
    } else {
        Toast.show({
            label: label,
            labelLinks: labelLinks,
            messageLinks : messageLinks,
            message: message,        
            variant: errorVariant,
            mode: "sticky"
        }, this);
    }
}

/**
 * @description Prompt warning with the given label, message, labelLinks and messageLinks
 * @param {*} label 
 * @param {*} message 
 * @param {*} labelLinks 
 * @param {*} messageLinks 
 */
const promptWarning = (label, message, labelLinks, messageLinks) => {

    if (warningNotificationType === "Alert") {

        let formattedMsg = formatText(message, messageLinks);
        let formattedLabel = formatText(label, labelLinks);

        LightningAlert.open({
            message: formattedMsg || formattedLabel,
            theme: warningVariant,
            label: formattedLabel
        });
        
    } else {
        Toast.show({
            label: label,
            labelLinks: labelLinks,
            messageLinks : messageLinks,
            message: message,        
            variant: warningVariant,
            mode: "sticky"
        }, this);
    }
}

/**
 * @description Prompt success with the given label, message, labelLinks and messageLinks
 * @param {*} label 
 * @param {*} message 
 * @param {*} labelLinks 
 * @param {*} messageLinks 
 */
const promptSuccess = (label, message, labelLinks, messageLinks) => {

    if (successNotificationType === "Alert") {

        let formattedMsg = formatText(message, messageLinks);
        let formattedLabel = formatText(label, labelLinks);

        LightningAlert.open({
            message: formattedMsg || formattedLabel,
            theme: successVariant,
            label: formattedLabel
        });

    } else {
        Toast.show({
            label: label,
            labelLinks: labelLinks,
            messageLinks : messageLinks,
            message: message,        
            variant: successVariant
        }, this);
    }
}

export { promptInfo, promptWarning, promptSuccess, promptError };

export default class ToasterUtil extends LightningElement {}