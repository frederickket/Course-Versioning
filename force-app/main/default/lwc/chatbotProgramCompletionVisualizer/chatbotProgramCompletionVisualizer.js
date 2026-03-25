/**
 * @Author 		WDCi (XW)
 * @Date 		May 2024
 * @group 		
 * @Description Program Completion Visualizer for Chatbot
 * @changehistory
 * ISS-001916 20-05-2024 XW - Program Completion Visualizer for Chatbot
 * ISS-001991 01-07-2024 XW - Changed the structure of data to not using eval
 * ISS-002187 26-11-2024 XW - Remove enrolled Study Plan from target study plan combobox
 * ISS-002191 05-12-2024 XW - Force to go back to menu if ipe is not found
 * ISS-002375 02-05-2025 xW - add logging
 */
import { LightningElement } from 'lwc';
import { logInfo } from 'c/loggingUtil';
import getIpeRecord from '@salesforce/apex/REDU_ChatbotProgComVisualizer_LCTRL.getIpeRecord';
import getContactIdByUserId from '@salesforce/apex/REDU_ChatbotProgComVisualizer_LCTRL.getContactIdByUserId';
import getAllProgram from '@salesforce/apex/REDU_ChatbotProgComVisualizer_LCTRL.getAllProgram';
import getIpeProgramByContactId from '@salesforce/apex/REDU_ChatbotProgComVisualizer_LCTRL.getIpeProgramByContactId';
import getStudyPlansByProgramId from '@salesforce/apex/REDU_ChatbotProgComVisualizer_LCTRL.getStudyPlansByProgramId';
import ChatbotProgramCompletionVisualizerModal from 'c/chatbotProgramCompletionVisualizerModal';

import { chatbotCustomLabel } from 'c/chatbotLabelLoader';

const MASTER_IPE = 'masterIpeRtId';
var enableDebugMode = null;

/**
 * 
 * @param newQna 
 * @returns Promise that handle Ipe model
 */
function handleIpe(newQna, event) {

    
    return ChatbotProgramCompletionVisualizerModal.open({
        size: "large",
        label: "header",
        description: "Program Completion Visualizer",
        
        contactId: newQna.attributes.contactId,
        studyProgramId: newQna.attributes.programId,
        studyPlanId: newQna.attributes.planId,

        ipeIdsBefore: newQna.attributes.ipeIdsBefore,

        modalTitle: event.page.api.programCompletionVisualizerModalTitle,
        modalIconName: event.page.api.programCompletionVisualizerModalIconName,
        ipsGroupTitleField: event.page.api.ipsGroupTitleField,
        ipsGroupTitleFormat: event.page.api.ipsGroupTitleFormat,
        showIpsGroupInfo: event.page.api.showIpsGroupInfo,
        ipeInfoFields: event.page.api.ipeInfoFields,
        ipeInfoColumnNo: event.page.api.ipeInfoColumnNo,
        ipsInfoFields: event.page.api.ipsInfoFields,
        ipsInfoFieldsUnit: event.page.api.ipsInfoFieldsUnit,
        ipsInfoColumnNo: event.page.api.ipsInfoColumnNo,
        ipsUnitFields: event.page.api.ipsUnitFields,
        idvEnrollmentFields: event.page.api.idvEnrollmentFields,
        accordionBackgroundColor: event.page.api.accordionBackgroundColor,
        accordionTextColor: event.page.api.accordionTextColor,
        enableClickableRefField: event.page.api.enableClickableRefField,
        enableSetPrimaryIps: event.page.api.enableSetPrimaryIps,
        enableViewEnrollmentHistory: event.page.api.enableViewEnrollmentHistory,
        hrefTargetType: event.page.api.hrefTargetType,
        summaryInfoField: event.page.api.summaryInfoField,
        isCommunity: event.page.api.isCommunity,
        progressRingColor: event.page.api.progressRingColor,
        progressRingPercentageField: event.page.api.progressRingPercentageField,
        enableDebugMode: event.page.api.enableDebugMode
    }).then(() => {
        newQna.attributes = {};
        return newQna;
    });


}

const programCompletionVisualizerModule = {
    /**
     * ISS-002125
     * @description An array of object API name that this module can handle
     */
    validObjects: ['reduivy__Individual_Program_Enrollment__c', 'Contact'],


    /**
     * 
     * @param {object} event
     * @returns True if current page is a valid record page, False for vice versa
     */
    isValidPage: (event) => {
        //ISS-002125
        return (event.page.isRecordPage && programCompletionVisualizerModule.validObjects.includes(event.page.objectApiName)) ||
            event.page.isCommunityPage;
    },



    /**
     * 
     * @param {object} currentQna 
     * @param {object} newQna 
     * @param {object} event 
     * @returns A promise with new Qna included
     */
    handle : async (currentQna, newQna, event) => {
        if(enableDebugMode == null) {
            enableDebugMode = event.page.api.enableDebugMode;
        }

        //ISS-002187
        if (newQna.level === 'programCompletionVisualizer') {

            //get contactId from logged in user id
            if (event.page.isCommunityPage && !event.page.isValidRecordPage) { // ISS-002125
                let result = await getContactIdByUserId({ userId: event.page.userId });
                newQna.attributes.contactId = JSON.parse(result.responseData).ContactId;
                consoleLog('programCompletionVisualizer - contact id :: ' + newQna.attributes.contactId);
            }
            else if (event.page.objectApiName === 'Contact') {
                newQna.attributes = { contactId: event.page.recordId };
                consoleLog('programCompletionVisualizer - record id :: ' + event.page.recordId);
            } else {
                let result = await getIpeRecord({ ipeId: event.page.recordId });
                let jsonResult = JSON.parse(result.responseData);
                newQna.attributes.contactId = jsonResult.reduivy__Contact__c;
                consoleLog('programCompletionVisualizer - else contact id :: ' + newQna.attributes.contactId);
            }
            
            let result = await getIpeProgramByContactId({ contactId: newQna.attributes.contactId });
            
            let ipeResult = JSON.parse(result.responseData);
            consoleLog('programCompletionVisualizer - ipeResult :: ' + JSON.stringify(ipeResult));
            //ISS-002191
            if(ipeResult.comboboxOptions.length === 0){
                newQna = programCompletionVisualizerModule.levelData.noIpeFound;
            } else {
                newQna.attributes.ipeResult = ipeResult;
            }
            return toPromise(newQna);
            
        }
        //ISS-002187
        else if (newQna.level === 'ipe') {
            let ipeResult = newQna.attributes.ipeResult;
            newQna.comboboxOptions = ipeResult.comboboxOptions.filter(ipe => ipe.recordTypeId === ipeResult[MASTER_IPE]);
            consoleLog('ipe - comboboxOptions :: ' + JSON.stringify(newQna.comboboxOptions));
            if(newQna.comboboxOptions.length === 1 && event.page.objectApiName === 'reduivy__Individual_Program_Enrollment__c'){
                
                newQna.attributes.programId = newQna.comboboxOptions[0].value;
                consoleLog('ipe - programId :: ' + newQna.comboboxOptions[0].value);
                newQna.skipToNextLevel = true;
            }
            newQna.attributes.selectByIpe = true;
            return toPromise(newQna);
            
        }
        else if (newQna.level === 'program') {
            return getAllProgram().then(result => {
                newQna.comboboxOptions = JSON.parse(result.responseData);
                consoleLog('program - getAllProgram - newQna.comboboxOptions :: ' + JSON.stringify(newQna.comboboxOptions));
                newQna.attributes.selectByProgram = true;
                
                return toPromise(newQna);
            })
            
        } else if (newQna.level === 'plan') {
            if(!newQna.attributes.programId){
                newQna.attributes.programId = event.detail.value;
            }
            return getStudyPlansByProgramId({ programId: newQna.attributes.programId }).then(result => {
                try {
                    let responseData = JSON.parse(result.responseData);
                    //ISS-002187
                    consoleLog('plan - getStudyPlansByProgramId - responseData :: ' + JSON.stringify(responseData));
                    let enrolledStudyPlan = newQna.attributes.ipeResult.comboboxOptions.map(plan => plan.studyPlanId);
                    newQna.comboboxOptions = responseData.filter(plan => !enrolledStudyPlan.includes(plan.value));
                    newQna.attributes.planComboboxOptions = newQna.comboboxOptions;
                } catch (error) {
                    newQna = { ...currentQna };
                    newQna.bottomText = chatbotCustomLabel.NO_STUDY_PLAN_FOUND_LABEL;
                }
                return toPromise(newQna);
            })
        }
        else if (newQna.level === 'ipeModal') {
            newQna.attributes.planId = event.detail.value;
            let selectedPlanType = newQna.attributes.planComboboxOptions.filter(plan => plan.value === newQna.attributes.planId)[0].type;
            consoleLog('ipeModal - selectedPlanType :: ' + selectedPlanType);
            if(newQna.attributes.selectByIpe){
                consoleLog('ipeModal - selectByIpe');
                let ipeIdsBefore = newQna.attributes.ipeResult.comboboxOptions.filter(ipe => ipe.type === selectedPlanType);
                consoleLog('ipeModal - ipeIdsBefore1 :: ' + JSON.stringify(ipeIdsBefore));
                
                //ISS-002191
                if(ipeIdsBefore.length === 0){
                    ipeIdsBefore = newQna.attributes.ipeResult.comboboxOptions;
                    consoleLog('ipeModal - ipeIdsBefore2 :: ' + JSON.stringify(ipeIdsBefore));
                }
                
                newQna.attributes.ipeIdsBefore = ipeIdsBefore.map(item => {
                    return { label: item.label, value: item.ipeId }
                });
                consoleLog('ipeModal - ipeIdsBefore3 :: ' + JSON.stringify(newQna.attributes.ipeIdsBefore));
                return handleIpe(newQna,event);
            }
            
            return getIpeProgramByContactId({contactId: newQna.attributes.contactId}).then(result=>{
                let ipeResult = JSON.parse(result.responseData);
                consoleLog('ipeModal - ipeResult :: ' + JSON.stringify(ipeResult));
                
                let ipeIdsBefore = ipeResult.comboboxOptions.filter(ipe => ipe.type === selectedPlanType);
                consoleLog('ipeModal - ipeIdsBefore :: ' + JSON.stringify(ipeIdsBefore));
                
                //ISS-002191
                if(ipeIdsBefore.length === 0){
                    ipeIdsBefore = ipeResult.comboboxOptions;
                }
                
                newQna.attributes.ipeIdsBefore = ipeIdsBefore.map(item => {
                    return { label: item.label, value: item.ipeId }
                });
                consoleLog('ipeModal - ipeIdsBefore3 :: ' + JSON.stringify(newQna.attributes.ipeIdsBefore));
                return handleIpe(newQna,event);
            })
        }

        return toPromise(newQna);
    },



    /**
     * @description data of programCompletionVisualizer
     * @description loading stringutil library is not possible, the global variable will be accessed first before importing library
     */
    levelData: {
        programCompletionVisualizer: {
            previousLevel: "menu",
            promptingModal: false,
            question: chatbotCustomLabel.CHANGING_PROGRAM_LABEL.replace("{0}", chatbotCustomLabel.PROGRAM_LABEL),
            displayType: "list",
            answers: [
                {
                    label: chatbotCustomLabel.YES_LABEL,
                    value: "yes",
                    nextLevel: "program"
                },
                {
                    label: chatbotCustomLabel.NO_LABEL,
                    value: "no",
                    nextLevel: "ipe"
                }
            ]


        },
        ipe: {
            question: chatbotCustomLabel.SELECT_YOUR_LABEL.replace("{0}", chatbotCustomLabel.IPE_LABEL),
            previousLevel: "programCompletionVisualizer",
            nextLevel: "plan",
            promptingModal: false,
            displayType: "combobox"


        },
        program: {
        question: chatbotCustomLabel.SELECT_YOUR_TARGET_LABEL.replace("{0}", chatbotCustomLabel.PROGRAM_LABEL),
            previousLevel: "programCompletionVisualizer",
            nextLevel: "plan",
            promptingModal: false,
            displayType: "combobox",

        },
        plan: {
        question: chatbotCustomLabel.SELECT_YOUR_TARGET_LABEL.replace("{0}", chatbotCustomLabel.PLAN_LABEL),
            previousLevel: "program",
            nextLevel: "ipeModal",
            promptingModal: false,
            displayType: "combobox",

        },
        ipeModal: {
            question: "",
            previousLevel: "plan",
            promptingModal: true,
            nextLevel: "menu",
            displayType: "list",
            skipToNextLevel: true

        },
        noIpeFound:{ //ISS-002191
            question: chatbotCustomLabel.NO_IPE_FOUND_LABEL.replace('{0}', chatbotCustomLabel.IPE_LABEL),
            nextLevel: "menu",
            promptingModal: false,
            displayType: 'list'
        }
    }
}
/**
 * 
 * @param {object} data 
 * @returns Convert any data to Promise
 */
function toPromise(data) {
    return new Promise((resolve) => resolve(data));
}

/**
 * @descripton Console log for debugging
 */
function consoleLog(anything, isJson) {
    logInfo('ChatbotProgramCompletionVisualizer', anything, enableDebugMode, isJson);
}

export { programCompletionVisualizerModule };


export default class ChatbotProgramCompletionVisualizer extends LightningElement { }