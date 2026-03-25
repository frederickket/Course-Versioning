/**
 * @Author 		WDCi (XW)
 * @Date 		May 2024
 * @group 		
 * @Description The main chatbot container
 * @changehistory
 * ISS-001916 20-05-2024 XW - Chatbot
 * ISS-001991 01-07-2024 XW - Removed eval
 * ISS-002125 16-10-2024 XW - Modified the condition of isCommunityPage getter
 * ISS-002191 12-12-2024 XW - Pass hrefTarget into studyPathwayUnit
 * ISS-002189 16-12-2024 XW - added show study unit quick search
 * ISS-002375 02-05-2025 xW - add logging
 */
import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { promptError } from 'c/toasterUtil';
import { getErrorMessage, logInfo } from 'c/loggingUtil';
import { customLabels } from 'c/labelLoader';
import { programCompletionVisualizerModule } from 'c/chatbotProgramCompletionVisualizer';
import { pathwayVisualizerModule } from 'c/chatbotPathwayVisualizer';
import { CurrentPageReference } from 'lightning/navigation';
import USER_ID from "@salesforce/user/Id";

import { chatbotCustomLabel } from 'c/chatbotLabelLoader';

const DISPLAY_TYPE = {
    LIST: 'list',
    COMBOBOX: 'combobox',
    COMBOBOX_PILL: 'comboboxPill',
    RECORD_PICKER: 'recordPicker'
}

const MODULE_PROGRAM_COMPLETION = 'programCompletionVisualizer';
const MODULE_PATHWAY_VISUALIZER = 'pathwayVisualizer';


const menuLevelData = {
    previousLevel: null,
    levelId: 0,
    question: chatbotCustomLabel.MENU_LABEL,
    answers: [
        {
            label: chatbotCustomLabel.ENTER_PROGRAM_COMPLETION_LABEL,
            value: MODULE_PROGRAM_COMPLETION,
            nextLevel: MODULE_PROGRAM_COMPLETION
        },
        {
            label: chatbotCustomLabel.ENTER_PATHWAY_LABEL,
            value: MODULE_PATHWAY_VISUALIZER,
            nextLevel: MODULE_PATHWAY_VISUALIZER
        }
    ],
    promptingModal: false,
    displayType: DISPLAY_TYPE.LIST,
    attributes: {},
}



export default class Chatbot extends LightningElement {

    //configurable attributes
    @api enableDebugMode = false;
    @api accordionBackgroundColor;
    @api accordionTextColor;
    @api isCommunity = false;
    @api recordId;
    @api objectApiName;

    //program completion
    //ISS-002187
    @api programCompletionVisualizerModalTitle;
    @api programCompletionVisualizerModalIconName;
    @api showIpsGroupInfo = false;
    @api ipsGroupTitleField;
    @api ipsGroupTitleFormat;
    @api ipeInfoFields;
    @api ipeInfoColumnNo;
    @api ipsInfoFields;
    @api ipsInfoFieldsUnit;
    @api ipsInfoColumnNo;
    @api ipsUnitFields;
    @api idvEnrollmentFields;
    @api enableClickableRefField = false;
    @api enableSetPrimaryIps = false;
    @api enableViewEnrollmentHistory = false;
    @api hrefTargetType;
    @api summaryInfoField;
    @api progressRingColor;
    @api progressRingPercentageField;
    
    //pathway visualizer modal
    //ISS-002187
    @api pathwayVisualizerModalTitle;
    @api pathwayVisualizerModalIconName;
    @api studyPathwayInfoFields;
    @api studyPathwayTermTitlePrefix;
    @api studyPathwayTermInfoFields;
    @api studyPathwayUnitTitleField;
    @api studyPathwayUnitInfoFields;
    @api studyPathwayUnitIcon;
    @api studyPathwayGroupTitleField;
    @api studyPathwayGroupInfoFields;
    @api studyPathwayGroupIcon;
    @api showStudyUnitQuickSearch = false; //ISS-002189
    @api showStudyPlanOptions = false;
    @api comboboxLabel;



    //internal attributes
    isScriptLoaded = false;
    isInitSuccess = false;
    loadedLists = 0;
    htmlIsInitialized = false;

    //labels
    label = customLabels;

    /**ISS-002125
     * @description This getter is used to get the record Id of the current viewing page.
                    The method to get the record Id is different in community and internal pages.
     */
    get targetRecordId() {
        if (this.isCommunityPage) {
            return this.pageRef.attributes.recordId;
        } 
        return this.recordId;
    }

    /**ISS-002125
     * @description This getter is used to get the object api name of the current viewing page.
                    The method to get the object api name is different in community and internal pages.
     */
    get targetObjectApiName() {
        if (this.isCommunityPage) {
            return this.objectApiNameInCommunity;
        } 
        return this.objectApiName;
    }


    // return attributes used in pathway visualizer
    get apiPathwayVisualizer() {
        return {
            'pathwayVisualizerModalTitle': this.pathwayVisualizerModalTitle,
            'pathwayVisualizerModalIconName': this.pathwayVisualizerModalIconName,
            'studyPathwayInfoFields': this.studyPathwayInfoFields,
            'studyPathwayTermTitlePrefix': this.studyPathwayTermTitlePrefix,
            'studyPathwayTermInfoFields': this.studyPathwayTermInfoFields,
            'studyPathwayUnitTitleField': this.studyPathwayUnitTitleField,
            'studyPathwayUnitInfoFields': this.studyPathwayUnitInfoFields,
            'studyPathwayUnitIcon': this.studyPathwayUnitIcon,
            'studyPathwayGroupTitleField': this.studyPathwayGroupTitleField,
            'studyPathwayGroupInfoFields': this.studyPathwayGroupInfoFields,
            'studyPathwayGroupIcon': this.studyPathwayGroupIcon,
            'showStudyPlanOptions': this.showStudyPlanOptions,
            'accordionBackgroundColor': this.accordionBackgroundColor,
            'accordionTextColor': this.accordionTextColor,
            'comboboxLabel': this.comboboxLabel,
            'enableDebugMode': this.enableDebugMode,
            'isCommunity': this.isCommunity,
            'hrefTargetType': this.hrefTargetType, //ISS-002191,
            'showStudyUnitQuickSearch': this.showStudyUnitQuickSearch //ISS-002189
        };
    }

    // return attributes used in program completion visualizer
    get apiProgramCompletionVisualizer() {
        return {
            'programCompletionVisualizerModalTitle': this.programCompletionVisualizerModalTitle,
            'programCompletionVisualizerModalIconName': this.programCompletionVisualizerModalIconName,
            'showIpsGroupInfo': this.showIpsGroupInfo,
            'ipsGroupTitleField': this.ipsGroupTitleField,
            'ipsGroupTitleFormat': this.ipsGroupTitleFormat,
            'ipeInfoFields': this.ipeInfoFields,
            'ipsInfoFieldsUnit': this.ipsInfoFieldsUnit,
            'ipeInfoColumnNo': this.ipeInfoColumnNo,
            'ipsInfoFields': this.ipsInfoFields,
            'ipsInfoColumnNo': this.ipsInfoColumnNo,
            'ipsUnitFields': this.ipsUnitFields,
            'idvEnrollmentFields': this.idvEnrollmentFields,
            'accordionBackgroundColor': this.accordionBackgroundColor,
            'accordionTextColor': this.accordionTextColor,
            'enableClickableRefField': this.enableClickableRefField,
            'enableSetPrimaryIps': this.enableSetPrimaryIps,
            'enableViewEnrollmentHistory': this.enableViewEnrollmentHistory,
            'hrefTargetType': this.hrefTargetType,
            'summaryInfoField': this.summaryInfoField,
            'progressRingColor': this.progressRingColor,
            'progressRingPercentageField': this.progressRingPercentageField,
            'enableDebugMode': this.enableDebugMode,
            'isCommunity': this.isCommunity,

        };
    }

    //stores the question sets that are in the chat bot
    @track questionSets = [];
    questionAfterModal;
    @track previousLength = 1
    get currentQna() {
        return this.questionSets[this.questionSets.length - 1];
    }

    currentModule = {};

    //get the object that contains data of current module
    get currentModuleObject() {
        if(this.currentModule.name === MODULE_PROGRAM_COMPLETION){
            return programCompletionVisualizerModule;
        }else if(this.currentModule.name === MODULE_PATHWAY_VISUALIZER){
            return pathwayVisualizerModule;
        }
        return null;
    }

    /**
     * @returns return True if current page is a record page (Internal page or Digital Experience), False for vice versa
    */
    get isRecordPage() {
        return this.pageRef?.type === 'standard__recordPage';
    }
    
    //ISS-002125
    /**
     * @returns return True if current page is a record page (Internal page or Digital Experience),
        and its object api name is valid as defined in module, False for vice versa
    */
    get isValidRecordPage() {
        return this.isRecordPage && this.currentModuleObject?.validObjects?.includes(this.targetObjectApiName); //ISS-002125
    }

    /**
     * @returns return True if current page is a community page(Digital Experience), False for vice versa
    */
    get isCommunityPage() {
        return this.pageRef?.type === 'comm__namedPage' || this.isCommunity; // ISS-002125
    }

    @wire(CurrentPageReference)
    pageRef;

    //ISS-002125 get and replace the object api name if the chatbot is in digital experience
    objectApiNameInCommunity;
    @wire(getRecord, { recordId: "$targetRecordId", layoutTypes: ["Full"], modes: ["View"] })
    wiredGetApiName(result) {
        if(result?.data && this.isCommunityPage){
            this.objectApiNameInCommunity = result?.data?.apiName;
            this.consoleLog("wiredGetApiName :: " + this.objectApiNameInCommunity);
        }
    }


    /**Pack the relavent data of opening page into an object and return it
     */
    get pageData() {
        let data = {};
        data.isRecordPage = this.isRecordPage;
        data.isValidRecordPage = this.isValidRecordPage; // ISS-002125
        data.isCommunityPage = this.isCommunityPage;
        data.pageRef = this.pageRef;
        data.objectApiName = this.targetObjectApiName //ISS-002125
        data.recordId = this.targetRecordId; //ISS-002125
        if (this.isCommunityPage) {
            data.userId = USER_ID;
        }
        return data;
    }

    /**
     * @description Return True if input is available, critiria:
     * @description Current level is menu OR the opening page is valid
     * @description If no valid page, always true
     */
    get inputIsEnabled() {
        let event = {
            page: this.pageData
        }
        let result = null;
        if (this.currentQna.level === 'menu') {
            result = true;
        }
        else {
            try {
                result = this.currentModuleObject.isValidPage(event);
            }
            catch {
                result = true;
            }
        }

        return result;

    }

    /**
     * 
     * @param {string} level 
     * @returns The Level Data based on the given level name
     */
    getLevelData(level) {
        return { ...this.currentModuleObject.levelData[level] };
    }



    //return to menu attributes
    get returnToMenuSet() {
        return {
            question: chatbotCustomLabel.RECORD_PAGE_CHANGED_GO_BACK_LABEL,
            displayType: 'list',
            level: this.currentQna.level,
            answers: [
                {
                    label: chatbotCustomLabel.RETURN_TO_MENU_LABEL,
                    value: 'menu',
                    nextLevel: 'menu'
                }
            ],
            levelId: this.currentQna.levelId,
            promptingModal: false,

        }
    }





    /**
     * @descripton library loader
     */
    handleLibLoadSuccess() {
        this.isScriptLoaded = true;
        this.isInitSuccess = true;

    }


    /**
     * @descripton library loader
     */
    handleLibLoadFail() {
        this.isScriptLoaded = true;
        this.isInitSuccess = false;
    }

    /**
     * @descripton rendered callback
     */
    renderedCallback() {
        //To prevent error when the chatbpt is first added into the community
        if(this.htmlIsInitialized){
            this.refs.bottomdiv.scrollIntoView(false);
        } else {
            this.htmlIsInitialized = true;
        }
        
        if (this.currentModule.recordId !== this.targetRecordId && this.currentQna.level !== 'menu') {
            this.currentQna.pageChangedText = chatbotCustomLabel.RECORD_PAGE_CHANGED_GO_BACK_LABEL;
        } else {
            this.currentQna.pageChangedText = "";
        }




    }

    /**
     * @descripton connected callback
     */
    connectedCallback() {
        this.initializeQuestionSets();
    }



    /**
     * 
     * @param {object} event 
     * @description Handle the response from chatbot-qna and add a new Qna via addIntoQuestionSets
     * @returns 
     */
    handleAddNewQna(event) {
        this.consoleLog("handleAddNewQna - raw event :: " + JSON.stringify(event));
        this.template.querySelector(`c-chatbot-qna[data-id=${this.currentQna.key}]`).toggleSpinner(1);
        
        //init the current module object
        if (Object.keys(this.currentModule).length === 0) {
            this.currentModule.name = event.detail.value;
            this.currentModule.recordId = this.targetRecordId;              //ISS-002125
            this.currentModule.objectApiName = this.targetObjectApiName;    //ISS-002125
            this.currentModule.fromIndex = this.questionSets.length - 1;
            if(this.currentModule.name === MODULE_PATHWAY_VISUALIZER){
                this.currentModuleApi = this.apiPathwayVisualizer;
            }else if(this.currentModule.name === MODULE_PROGRAM_COMPLETION){
                this.currentModuleApi = this.apiProgramCompletionVisualizer;
            }

            this.consoleLog("handleAddNewQna - init module :: " + JSON.stringify(this.currentModule));
            this.consoleLog("handleAddNewQna - init module - this.currentModuleApi :: " + this.currentModuleApi);
            
        }

        event.page = this.pageData;
        event.page.api = this.currentModuleApi;

        try {

            let isValidPage = this.currentModuleObject.isValidPage(event);

            if (event.detail.nextLevel === "menu" || !isValidPage) {
                let newMenuQna = { ...menuLevelData };
                if (!isValidPage) {

                    newMenuQna.topText = chatbotCustomLabel.PROCEED_TO_VALID_RECORD_PAGE_LABEL;
                }
                this.addIntoQuestionSets(newMenuQna);
                return;
            }

            let newQna = this.getLevelData(event.detail.nextLevel);
            newQna.level = event.detail.nextLevel;
            newQna.levelId = event.detail.levelId + 1;
            newQna.attributes = event.detail.attributes;
            newQna.moduleHasFinished = false;
            if (!newQna.answers) {
                newQna.answers = [];
            }
            if (!newQna.displayType) {
                newQna.displayType = 'list';
            }

            this.consoleLog("handleAddNewQna - this.currentQna :: " + JSON.stringify(this.currentQna));
            this.consoleLog("handleAddNewQna - newQna :: " + JSON.stringify(newQna));
            this.consoleLog("handleAddNewQna - event :: " + JSON.stringify(event));

            this.currentModuleObject.handle(this.currentQna, newQna, event).then(result => {
                this.addIntoQuestionSets(result);
            }).catch(error => {
                this.addIntoQuestionSets({ ...menuLevelData });
                promptError(this.label.ERROR_LABEL, getErrorMessage(error));
            });
        } catch (error) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
        }


    }

    /**
     * @description initialize the first qna into the sets
     */
    initializeQuestionSets() {
        menuLevelData.key = 'menu-0';
        menuLevelData.level = 'menu';
        menuLevelData.moduleHasFinished = false;
        let menu = { ...menuLevelData };

        this.addIntoQuestionSets(menu);
    }

    /**
     * 
     * @param {object} newQna 
     * @description Ensure that there is a "Go back to menu" option into the answer and add the new Qna into the list
     */
    addIntoQuestionSets(newQna) { 
        this.consoleLog("addIntoQuestionSets - raw newQna :: " + JSON.stringify(newQna));

        if (newQna.level === 'menu') {
            this.currentModule = {};
            //filter the answer to be selected if shownInCommunity or shownInRecord is false
            for (let i = newQna.answers.length - 1; i >= 0; i--) {
                if (newQna.answers[i] !== undefined && newQna.answers[i].shownInCommunity === false &&
                    this.isCommunityPage) {
                    newQna.answers.splice(i, 1);
                }
                else if (newQna.answers[i] !== undefined && newQna.answers[i].shownInRecord === false &&
                    this.isRecordPage) {
                    newQna.answers.splice(i, 1);
                }
            }

        } else {
            this.refs.bottomdiv.scrollIntoView(false);
            if(!Array.isArray(newQna.answers)){ //ISS-002191
                newQna.answers = [];
            }
            //make sure that there is one and only one answer to navigate to menu 
            let nextLevelMenuAnswersList = newQna.answers.filter(item => item.nextLevel === "menu")
            if (nextLevelMenuAnswersList.length === 0) {
                newQna.answers.push({ label: chatbotCustomLabel.RETURN_TO_MENU_LABEL, value: "menu", nextLevel: "menu" })
            } else {
                for (let i = nextLevelMenuAnswersList.length; i >= 2; i--) {
                    newQna.answers.pop();
                }
            }
        }

        //ISS-002125
        if(this.questionSets.length > 0){
            this.template.querySelector(`c-chatbot-qna[data-id=${this.currentQna.key}]`)?.toggleSpinner(-1);
        }

        if (newQna.skipToNextLevel) {
            let event = {};
            event.detail = {};
            event.detail.nextLevel = newQna.nextLevel;
            event.detail.level = newQna.level;
            event.detail.value = null;
            event.detail.levelId = newQna.levelId;
            event.detail.attributes = newQna.attributes;
            this.consoleLog('addIntoQuestionSets - skipToNextLevel - next question event :: ' + JSON.stringify(event));
            this.handleAddNewQna(event);
            return;
        }



        newQna.key = newQna.level + '-' + this.questionSets.length;
        this.consoleLog('addIntoQuestionSets - final newQna :: ' + JSON.stringify(newQna))
        this.questionSets.push(newQna);

    }

    /**
     * 
     * @param {object} event 
     * @description When the inputIsEnabled is false and the user clicked on the go back to menu button, this will be invoked.
     * Add the menu level into the list.
     */
    handleReturnToMenu() {

        let returnToMenuQna = this.returnToMenuSet;
        returnToMenuQna.key = returnToMenuQna.level + this.questionSets.length;
        this.addIntoQuestionSets(returnToMenuQna);

        for (let i = this.currentModule.fromIndex; i < this.questionSets.length; i++) {
            this.questionSets[i].moduleHasFinished = true;
        }
        let newQna = { ...menuLevelData };
        this.addIntoQuestionSets(newQna);

    }


    /**
     * @descripton Console log for debugging
     */
    consoleLog(anything, isJson) {
        logInfo('Chatbot', anything, this.enableDebugMode, isJson);
    }

}


