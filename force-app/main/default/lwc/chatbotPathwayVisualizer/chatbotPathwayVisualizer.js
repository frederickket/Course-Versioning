/**
 * @Author 		WDCi (XW)
 * @Date 		Jan 2024
 * @group 		
 * @Description Pathway Visualizer in Chatbot
 * @changehistory
 * ISS-001917 20-05-2024 XW - Pathway Visualizer in Chatbot
 * ISS-001991 01-07-2024 XW - Changed the structure of data to not using evals
 * ISS-002125 16-10-2024 XW - Added one more criteria to skip the ipe selection
 * ISS-002191 12-12-2024 XW - Pass hrefTarget into studyPathwayUnit
 * ISS-002189 16-12-2024 XW - added show study unit quick search
 * ISS-002375 02-05-2025 xW - add logging
 */
import { LightningElement } from 'lwc';
import { logInfo } from 'c/loggingUtil';

import getDefaultStudyPlan from '@salesforce/apex/REDU_ChatbotPathwayVisualizer_LCTRL.getDefaultStudyPlan';
import getPathwayIdAndProgramName from '@salesforce/apex/REDU_ChatbotPathwayVisualizer_LCTRL.getPathwayIdAndProgramName';

import getIpeRecord from '@salesforce/apex/REDU_ChatbotProgComVisualizer_LCTRL.getIpeRecord';
import getContactIdByUserId from '@salesforce/apex/REDU_ChatbotProgComVisualizer_LCTRL.getContactIdByUserId';
import getAllProgram from '@salesforce/apex/REDU_ChatbotProgComVisualizer_LCTRL.getAllProgram';

import ChatbotPathwayVisualizerModal from 'c/chatbotPathwayVisualizerModal';

import { chatbotCustomLabel } from 'c/chatbotLabelLoader';

var ipeStudyPathwayMap = [];
var enableDebugMode = null;


const pathwayVisualizerModule = {

    //ISS-002125
    validObjects : ['Contact','reduivy__Individual_Program_Enrollment__c'],

    isValidPage: (event) => {
        //ISS-002125
        return (event.page.isRecordPage && pathwayVisualizerModule.validObjects.includes(event.page.objectApiName)) ||
            event.page.isCommunityPage;
    },

    handle: (currentQna, newQna, event) => {
        if(enableDebugMode == null) {
            enableDebugMode = event.page.api.enableDebugMode;
        }

        switch (newQna.level) {
            case 'pathwayVisualizer': {
                //get contactId
                if (event.page.isCommunityPage && !event.page.isValidRecordPage) { // ISS-002125
                    return getContactIdByUserId({ userId: event.page.userId }).then(result => {
                        newQna.attributes.contactId = JSON.parse(result.responseData).ContactId;
                        consoleLog('pathwayVisualizer - contact id :: ' + newQna.attributes.contactId);
                        return toPromise(newQna);
                    });
                }
                else if (event.page.objectApiName === 'Contact') {
                    newQna.attributes = { contactId: event.page.recordId };
                    consoleLog('pathwayVisualizer - Contact - newQna.attributes :: ' + JSON.stringify(newQna.attributes));
                    return toPromise(newQna);
                }
                
                return getIpeRecord({ ipeId: event.page.recordId }).then(result => {
                    let jsonResult = JSON.parse(result.responseData);
                    newQna.attributes.contactId = jsonResult.reduivy__Contact__c;
                    newQna.attributes.studyProgramIdOfOpeningIpe = jsonResult.reduivy__Study_Program__c;
                    consoleLog('pathwayVisualizer - else - newQna.attributes :: ' + JSON.stringify(newQna.attributes));
                    return toPromise(newQna);
                    
                })
            }
            case 'program': {
                return getAllProgram().then(result => {
                    newQna.comboboxOptions = JSON.parse(result.responseData);
                    consoleLog('program - getAllProgram - newQna.comboboxOptions :: ' + JSON.stringify(newQna.comboboxOptions));
                    return toPromise(newQna);
                })
            }
            case 'plan': {
                newQna.attributes.programId = event.detail.value;
                
                return getDefaultStudyPlan({ studyProgramId: newQna.attributes.programId }).then(result => {
                    try {
                        let responseDataJson = JSON.parse(result.responseData);
                        newQna.attributes.recordId = responseDataJson.Id;
                        newQna.attributes.studyPlanName = responseDataJson.Name;
                        consoleLog('plan - getDefaultStudyPlan - default found :: ' + JSON.stringify(newQna.attributes));
                    } catch (error) {
                        newQna = { ...currentQna };
                        newQna.bottomText = chatbotCustomLabel.NO_DEFAULT_STUDY_PLAN_FOUND_LABEL;
                    }
                    return toPromise(newQna);
                });
                
            }
            case 'ipe': {
                return getPathwayIdAndProgramName({ contactId: newQna.attributes.contactId }).then(result => {
                    newQna.comboboxOptions = JSON.parse(result.responseData);
                    consoleLog('ipe - getPathwayIdAndProgramName - comboboxOptions :: ' + JSON.stringify(newQna.comboboxOptions));
                    
                    //ISS-002191
                    if(newQna.comboboxOptions.length === 0) {
                        newQna = pathwayVisualizerModule.levelData.noIpeFound;
                        consoleLog('ipe - getPathwayIdAndProgramName - no ipe found');
                        return toPromise(newQna);
                    } 
                    ipeStudyPathwayMap = newQna.comboboxOptions;
                    if(newQna.comboboxOptions.length === 1 && 
                        event.page.objectApiName === 'reduivy__Individual_Program_Enrollment__c' && 
                        event.page.recordId){ // ISS-002125 added one more criteria to skip the ipe selection
                            
                            newQna.skipToNextLevel = true;
                            
                        return getDefaultStudyPlan({studyProgramId: newQna.attributes.studyProgramIdOfOpeningIpe}).then(defaultPlanResult => {
                            let defaultPlanResponse = JSON.parse(defaultPlanResult.responseData);
                            consoleLog('ipe - getDefaultStudyPlan - defaultPlanResult :: ' + JSON.stringify(defaultPlanResponse));
                            newQna.attributes.recordId = defaultPlanResponse.Id;
                            newQna.attributes.studyPlanName = defaultPlanResponse.Name;
                            return toPromise(newQna);
                        });
                    }
                    
                    return toPromise(newQna);
                });
            }
            case 'selectMajorMinor': {
                if (currentQna.level === 'ipe') {
                    if(!newQna.attributes.recordId){
                        
                        if (!event.detail.value) {
                            newQna = { ...currentQna };
                            newQna.bottomText = chatbotCustomLabel.NO_STUDY_PATHWAY_FOUND_LABEL;
                            consoleLog('selectMajorMinor - NO_STUDY_PATHWAY_FOUND_LABEL :: ' + JSON.stringify(newQna));
                            return toPromise(newQna);
                        }   
                        newQna.attributes.recordId = event.detail.value;
                    }
                    
                    let studyPlanName = ipeStudyPathwayMap.filter(sp => sp.value === newQna.attributes.recordId)[0].studyPlanName;
                    newQna.topText = chatbotCustomLabel.STUDY_PLAN_SELECTED_LABEL.replace('{0}', studyPlanName);
                    
                    consoleLog('selectMajorMinor - studyPlanName :: ' + studyPlanName);
                }
                else {
                    newQna.topText = chatbotCustomLabel.STUDY_PLAN_SELECTED_LABEL.replace('{0}', newQna.attributes.studyPlanName);
                    consoleLog('selectMajorMinor - studyPlanName :: ' + newQna.attributes.studyPlanName);
                }

                return toPromise(newQna);

            } case "pathwayModal": {
                return handleModal(newQna, event);

            } default: {
                return toPromise(newQna);
            }

        }

    },

    /**
     * @description data of pathwayVisualizer
     * @description loading stringutil library is not possible, the global variable will be accessed first before importing library
     */
    levelData: {
        pathwayVisualizer: {
            question: chatbotCustomLabel.PATHWAY_QUESTION_LABEL,
            displayType: "list",
            answers: [
                { label: chatbotCustomLabel.IPE_LABEL, value: "ipe", nextLevel: "ipe" },
                { label: chatbotCustomLabel.PROGRAM_LABEL, value: "program", nextLevel: "program" }
            ],
            previousLevel: "menu"


        },
        program: {
        question: chatbotCustomLabel.SELECT_YOUR_TARGET_LABEL.replace("{0}", chatbotCustomLabel.PROGRAM_LABEL),
            previousLevel: "pathwayVisualizer",
            nextLevel: "plan",
            promptingModal: false,
            displayType: "combobox",

        },
        plan: {
            question: chatbotCustomLabel.SELECT_YOUR_TARGET_LABEL.replace("{0}", chatbotCustomLabel.PLAN_LABEL),
            previousLevel: "program",
            nextLevel: "selectMajorMinor",
            promptingModal: false,
            displayType: "combobox",
            skipToNextLevel: true
        },
        ipe: {
            question: chatbotCustomLabel.SELECT_YOUR_LABEL.replace("{0}", chatbotCustomLabel.IPE_LABEL),
            previousLevel: "pathwayVisualizer",
            nextLevel: "selectMajorMinor",
            promptingModal: false,
            displayType: "combobox"


        },
        selectMajorMinor: {
            question: chatbotCustomLabel.VIEW_PATHWAY_CONFIRMATION_LABEL,
            previousLevel: 'pathwayVisualizer',
            nextLevel: "pathwayModal",
            displayType: "list",
            answers: [
                {
                    label: chatbotCustomLabel.CONFIRM_LABEL,
                    value: 'confirm',
                    nextLevel: 'pathwayModal'
                }
            ]

        },
        pathwayModal: {
            question: "",
            previousLevel: 'selectMajorMinor',
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


function handleModal(newQna, event) {
    return ChatbotPathwayVisualizerModal.open({
        size: 'large',
        recordId: newQna.attributes.recordId,

        label: event.page.api.pathwayVisualizerModalTitle,
        enableDebugMode: event.page.api.enableDebugMode,
        modalTitle: event.page.api.pathwayVisualizerModalTitle,
        modalIconName: event.page.api.pathwayVisualizerModalIconName,
        studyPathwayInfoFields: event.page.api.studyPathwayInfoFields,
        studyPathwayTermTitlePrefix: event.page.api.studyPathwayTermTitlePrefix,
        studyPathwayTermInfoFields: event.page.api.studyPathwayTermInfoFields,
        studyPathwayUnitTitleField: event.page.api.studyPathwayUnitTitleField,
        studyPathwayUnitInfoFields: event.page.api.studyPathwayUnitInfoFields,
        studyPathwayUnitIcon: event.page.api.studyPathwayUnitIcon,
        studyPathwayGroupTitleField: event.page.api.studyPathwayGroupTitleField,
        studyPathwayGroupInfoFields: event.page.api.studyPathwayGroupInfoFields,
        studyPathwayGroupIcon: event.page.api.studyPathwayGroupIcon,
        showStudyUnitQuickSearch: event.page.api.showStudyUnitQuickSearch, //ISS-002189
        showStudyPlanOptions: event.page.api.showStudyPlanOptions,
        accordionBackgroundColor: event.page.api.accordionBackgroundColor,
        accordionTextColor: event.page.api.accordionTextColor,
        comboboxLabel: event.page.api.comboboxLabel,
        hrefTargetType: event.page.api.hrefTargetType,

    }).then(() => {
        return newQna;
    });
}

/**
 * @descripton Console log for debugging
 */
function consoleLog(anything, isJson) {
    logInfo('ChatbotPathwayVisualizer', anything, enableDebugMode, isJson);
}

export { pathwayVisualizerModule }

export default class ChatbotPathwayVisualizer extends LightningElement { }