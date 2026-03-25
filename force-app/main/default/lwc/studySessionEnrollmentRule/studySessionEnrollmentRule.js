/**
 * @Author 		WDCi (XW)
 * @Date 		Nov 2024
 * @group 		Study Session Enrollment Rules
 * @Description Study Session Enrollment Rules Wizard
 * @changehistory
 * ISS-002070 01-11-2024 XW - create new class
 */
import { LightningElement, api, track, wire } from 'lwc';
import { promptError, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo } from 'c/loggingUtil';
import { customLabels } from 'c/labelLoader';
import { getRecord } from 'lightning/uiRecordApi';
import { updateRecord } from "lightning/uiRecordApi";
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';

import SOF_RULE_FIELD from '@salesforce/schema/Study_Offering__c.Study_Session_Enrollment_Rule__c'
import ADD_RULE_FIELD from '@salesforce/label/c.Add_Rule'
import SSE_TYPE_FIELD from '@salesforce/schema/Study_Session__c.Type__c';
import SSE_OBJ from '@salesforce/schema/Study_Session__c';
import SOF_OBJ from '@salesforce/schema/Study_Offering__c';
import SOF_ID_FIELD from '@salesforce/schema/Study_Offering__c.Id'

import INVALID_RULE_LABEL from '@salesforce/label/c.Invalid_Study_Session_Enrollment_Rule';
import INVALID_NUMBER_OF_SESSION_LABEL from '@salesforce/label/c.Invalid_Number_Of_Session';
import SELECT_STUDY_SESSION_TYPE_LABEL from '@salesforce/label/c.Select_Study_Session_Type';
import DUPLICATED_TYPE_FOUND_LABEL from '@salesforce/label/c.Duplicated_Type_Found';

export default class StudySessionEnrollmentRule extends LightningElement {
	
	//configurable attributes
    @api modalTitle;
    @api modalIconName;
	@api enableDebugMode = false;

    @api objectApiName;
    @api recordId;

    //internal attributes
	isScriptLoaded = false;
	isInitSuccess = false
	loadedLists = 0;
    
    sessionRulesInRecordData;
    sessionRulesInRecordError;

    @track sessionTypeValueList = [];
    @track sessionNumberValueList = [];
    numberOfRules = 0;
    
    //labels
	label = customLabels;

    fields = [SOF_RULE_FIELD]

    //js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'jquery', 'tooltips'
    modules = ['stringutil'];

    /**
     * @descripton library loader
     */
    handleLibLoadSuccess() {
        this.isScriptLoaded = true;
        this.isInitSuccess = true;
        this.mapExisitingRuleToWizard();
    }

    /**
     * @descripton library loader
     */
    handleLibLoadFail() {
        this.isScriptLoaded = true;
        this.isInitSuccess = false;
    }

    /**
     * get the session enrollment rules from the record page
     */
    @wire(getRecord, {recordId:"$recordId", fields: "$fields"})
    sessionRulesInRecord({data, error}){
        if(data){
            this.sessionRulesInRecordData = data;
            this.mapExisitingRuleToWizard();
        } else if (error){
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
        }
    }

    /**
     * @description get the object info for the Study Session 
     */
    @wire(getObjectInfo, {objectApiName: SSE_OBJ})
    sseObjectInfo;

    get sseObjectLabel() {
        return this.sseObjectInfo?.data?.label;
    }

    /**
     * @description get the object info for the Study Offering
     */
    @wire(getObjectInfo, {objectApiName: SOF_OBJ})
    sofObjectInfo;

    //get the default record type id of the Study Session to get picklist value
    get sseDefaultRecordTypeId(){
        return this.sseObjectInfo?.data?.defaultRecordTypeId;
    }
    
    
    /**
     * @description get the picklist value of the Session Type
     */
    @wire(getPicklistValues, { recordTypeId: '$sseDefaultRecordTypeId', fieldApiName: SSE_TYPE_FIELD })
    ssePicklistValues;
	
    //object that is displayed on the wizard
    get sessionRulesInWizard() {
        let rules = [];
        for(let i = 0; i < this.numberOfRules; i++) {
            rules.push({
                typeValue: this.sessionTypeValueList[i],
                numberValue: this.sessionNumberValueList[i],
                dataId: i
            })
        }

        this.consoleLog(rules);

        return rules;
    }

    //the session rules in record, will be updated automatically if the rules is updated
    get sessionRulesInRecordValue(){
        return this.sessionRulesInRecordData?.fields?.reduivy__Study_Session_Enrollment_Rule__c?.value;
    }

    //type label for table header
    get typeLabel(){
        return this.sseObjectInfo?.data?.fields?.reduivy__Type__c?.label;
    }

    //number label for table header
    get numberLabel() {
        return this.label.NUMBER_OF_SESSION_LABEL.format([this.sseObjectLabel]);
    }

    //show warning icon if changes have been made
    get warningIcon(){
        return this.hasUnsavedChanges ? "utility:warning" : "";
    }

    //save label for button
    get saveLabel(){
        return this.label.SAVE_LABEL;
    }

    //cancel label for button
    get cancelLabel(){
        return this.label.CANCEL_LABEL;
    }

    //add rule label for button
    get addRuleLabel(){
        return ADD_RULE_FIELD;
    }
    
    //add remove label for button
    get deleteLabel(){
        return this.label.DELETE_LABEL;
    }

    //session type option for combobox
    get sessionTypeOptions(){
        let result = this.ssePicklistValues?.data?.values.map(option => {
            return {label: option.label, value: option.value}
        });

        return result ? result : [];
    }

    //map session value to label
    get sessionTypeValueToLabelMap(){
        let map = {};
        for(let sessionTypeOptions of this.sessionTypeOptions){
            map[sessionTypeOptions.value] = sessionTypeOptions.label;
        }
        return map;
    }

    
    get hasUnsavedChanges(){
        let result = [];
        this.sessionRulesInWizard.forEach(rule=>{
            result.push(rule.typeValue + '=' + rule.numberValue);
        })

        this.consoleLog('hasUnsavedChanges');
        this.consoleLog(result);
        this.consoleLog(this.sessionRulesInRecordValue);

        if (result.length === 0 && !this.sessionRulesInRecordValue) {
            return false;
        }

        return result.join(';') !== this.sessionRulesInRecordValue;
    }

    get noUnsavedChanges(){
        return !this.hasUnsavedChanges;
    }
    
    get selectTypeErrorMessage(){
        return SELECT_STUDY_SESSION_TYPE_LABEL.format([this.typeLabel]);
    }

    
    /**
     * @description map the exisiting rule to the wizard
     */
    mapExisitingRuleToWizard(){

        this.sessionTypeValueList = [];
        this.sessionNumberValueList = [];
        this.numberOfRules = 0;

        if(this.sessionRulesInRecordValue){
            try{
                let sessionRuleList = this.sessionRulesInRecordValue.split(';');
                for (let sessionRule of sessionRuleList){
                    if(sessionRule && sessionRule.includes('=')){
                        sessionRule = sessionRule.trim();
                        let sessionRuleValue = sessionRule.split('=');
                        if(sessionRuleValue.length === 2){
                            this.numberOfRules++;
                            if(
                                !isNaN(sessionRuleValue[1])
                            ) {
                                this.sessionTypeValueList.push(sessionRuleValue[0]);
                                this.sessionNumberValueList.push(parseInt(sessionRuleValue[1], 10));
                            } else {
                                throw new Error();
                            }
                        } else {
                            throw new Error();
                        }
                    } else {
                        throw new Error();
                    }
                }

            } catch(error) {
                if(!this.isInitSuccess) return;
                let sessionRuleLabel = this.sofObjectInfo.data?.fields?.reduivy__Study_Session_Enrollment_Rule__c?.label;
                let objectLabel = this.sofObjectInfo.data?.label;
                    
                let invalidMessage = INVALID_RULE_LABEL.format([sessionRuleLabel, objectLabel]);
                promptError(this.label.ERROR_LABEL, invalidMessage);
            }
        }
    }


    /**
     * @description add rule button click handler
     */
    handleButtonAddRule(){
        this.numberOfRules++;
        this.sessionTypeValueList.push(null);
        this.sessionNumberValueList.push(null);
    }

    /**
     * 
     * @param {*} event handle session type changed
     */
    handleComboboxTypeChange(event) {
        let index = parseInt(event.target.dataset.id, 10);

        this.consoleLog('handleComboboxTypeChange :: ' + index);

        this.sessionTypeValueList[index] = event.target.value;
    }
    
    /**
    * 
    * @param {*} event handle number of session changed
    */
    handleInputNumberChange(event){
        let index = parseInt(event.target.dataset.id, 10);

        this.consoleLog('handleInputNumberChange :: ' + index);

        this.sessionNumberValueList[index] = event.detail.value;
    }

    /**
     * 
     * @param {*} event handle remove button clicked
     */
    handleButtonRemoveRule(event){
        let index = parseInt(event.target.dataset.id, 10);

        this.consoleLog('handleButtonRemoveRule :: ' + index);

        this.sessionTypeValueList.splice(index, 1);
        this.sessionNumberValueList.splice(index, 1);
        this.numberOfRules--;
    }

    /**
     * @description cancel button click handler
     */
    handleButtonCancel() {
        this.mapExisitingRuleToWizard();
    }

    /**
     * @description save button click handler
     */
    handleButtonSave(){
        let resultList = [];
        let selectedType = [];
        let isValid = true;
        for(let i = 0; i < this.numberOfRules; i++){

            //validate type combobox
            let typeCmp = this.template.querySelector(`lightning-combobox[data-id="${i}"]`);
            if(this.sessionTypeValueList[i]){

                //validate duplicated type selected
                if(selectedType.includes(this.sessionTypeValueList[i])){
                    let label = this.sessionTypeValueToLabelMap[this.sessionTypeValueList[i]];
                    typeCmp.setCustomValidity(DUPLICATED_TYPE_FOUND_LABEL.format([label]));
                    isValid = false;
                } else {
                    selectedType.push(this.sessionTypeValueList[i]);
                    typeCmp.setCustomValidity('');
                }
            }
            typeCmp.reportValidity();
            
            //validate number input
            let numberCmp = this.template.querySelector(`lightning-input[data-id="${i}"]`);
            if(isNaN(parseInt(this.sessionNumberValueList[i], 10)) || parseInt(this.sessionNumberValueList[i], 10) <= 0){
                numberCmp.setCustomValidity(INVALID_NUMBER_OF_SESSION_LABEL.format([this.sseObjectLabel]));
                isValid = false;
            } else {
                numberCmp.setCustomValidity('');
            }
            numberCmp.reportValidity();



            resultList.push(this.sessionTypeValueList[i] + '=' + this.sessionNumberValueList[i]);
        }
        if(!isValid) return;
        let result = resultList.join(';');
        if(result === this.sessionRulesInRecordValue){
            return;
        }

        let fields = {};

        fields[SOF_RULE_FIELD.fieldApiName] = result;
        fields[SOF_ID_FIELD.fieldApiName] = this.recordId;
        

        let recordInput = {fields};

        this.consoleLog('handleButtonSave');
        this.consoleLog(recordInput, true);

        try{
            this.toggleSpinner(1);
            updateRecord(recordInput).then(()=>{
                promptSuccess(this.label.SUCCESS_LABEL, this.label.RECORD_SAVED_LABEL);
                this.toggleSpinner(-1);
            }).catch(error=>{
                promptError(this.label.ERROR_LABEL, getErrorMessage(error));
                this.toggleSpinner(-1);
            })
        }catch(error){  
            this.toggleSpinner(-1);
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
        }
    }	

    /**
     * @descripton Spinner loading status
     */
	get isLoading(){
        return this.loadedLists === 0 ? false : true;
    }

    /**
     * @descripton Spinner toggler
     */
	toggleSpinner(loadCount){
        this.loadedLists += loadCount;

        if(this.loadedLists <= 0){
            this.loadedLists = 0;
        }
    }
	
    /**
     * @descripton Console log for debugging
     */
	consoleLog(anything, isJson){
        logInfo('StudySessionEnrollmentRule', anything, this.enableDebugMode, isJson);
    }
	
}