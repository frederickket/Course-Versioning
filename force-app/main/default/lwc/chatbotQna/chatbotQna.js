/**
 * @Author 		WDCi (XW)
 * @Date 		May 2024
 * @group 		
 * @Description Chatbot Qna that handle 1 set of qna (question and answer)
 * @changehistory
 * ISS-001916 20-05-2024 name - Chatbot Qna
 */
import { LightningElement, api, wire, track } from 'lwc';
import { promptInfo, promptError, promptWarning, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';
import { customLabels } from 'c/labelLoader';

//refresh module
import { RefreshEvent } from 'lightning/refresh';

export default class ChatbotQna extends LightningElement {

    //configurable attributes
    @api modalTitle;
    @api modalIconName;
    @api enableDebugMode = false;


    loadedLists = 0;
    
    //labels
    label = customLabels;

    /**
     * @description Return true if selecting an answer is not allowed
     */
    get answerIsDisabled() {
        return (this.isAnswered ? (true) : (!this.inputIsEnabled)) || this.questionSet.moduleHasFinished;
    }

    /**
     * @description Return true if question is showing in the chatbot
     */
    get showQuestion() {
        return this.questionSet.question;
    }

    /**
     * @description Return true if answer is showing in the chatbot
     */
    get isAnswered() {
        return this.selectedAnswer;
    }

    question;
    answersOptions = [];
    selectedAnswer;
    @api questionSet;
    @api inputIsEnabled;
    @track hideAnswer = false;


    //record picker attribute
    recordPickerValue
    get isRecordPicker() {
        return this.questionSet.displayType.localeCompare("recordPicker", undefined, { sensitivity: 'base' }) === 0;
    }
    get recordPickerObjectApiName() {
        return this.questionSet.objectApiName;
    }

    get recordPickerFilter() {
        if (!this.questionSet.recordPickerAttributes) return null;
        return this.questionSet.recordPickerAttributes.filter ? JSON.parse(JSON.stringify(this.questionSet.recordPickerAttributes.filter)) : null;
    }

    get recordPickerDisplayInfo() {
        if (!this.questionSet.recordPickerAttributes) return null;
        return this.questionSet.recordPickerAttributes.displayInfo ? JSON.parse(JSON.stringify(this.questionSet.recordPickerAttributes.displayInfo)) : null;
    }

    get recordPickerMatchingInfo() {
        if (!this.questionSet.recordPickerAttributes) return null;
        return this.questionSet.recordPickerAttributes.matchingInfo ? JSON.parse(JSON.stringify(this.questionSet.recordPickerAttributes.matchingInfo)) : null;
    }

    //list attributes
    get isList() {
        return this.answersOptions.length > 0;
    }

    get getQuestion() {
        return this.question ? this.question : ""
    }

    //combobox attributes
    get isCombobox() {
        return this.questionSet.displayType.localeCompare("combobox", undefined, { sensitivity: 'base' })=== 0;
    }

    get comboboxOptions() {
        return this.questionSet.comboboxOptions;
    }
    comboboxValue

    //text attributes

    get topText() {
        return this.questionSet.topText;
    }

    get bottomText() {
        return this.questionSet.bottomText;
    }

    get pageChangedText() {
        return this.questionSet.pageChangedText;
    }

    //combobox pill attributes
    get isComboboxPill() {
        return this.questionSet.displayType.localeCompare("comboboxPill", undefined, { sensitivity: 'base' })=== 0;
    }
    @track pills = [];

    comboboxPillValue
    get comboboxPillOptions() {
        return this.questionSet.comboboxPillOptions;
    }

    //to determine the size of the bubble (display is inline block or not)
    get isFitContent(){
        let defaultClass = 'chatbot-qna-question-section slds-p-around_x-small slds-m-around_x-small';
        if(this.isCombobox || this.isComboboxPill || this.isRecordPicker){
            return defaultClass;
        } 
        return defaultClass + " fit-content"
    }

    /**
     * @descripton connected callback
    */
    connectedCallback() {
        this.question = this.questionSet.question;
        this.answersOptions = this.questionSet.answers;
    }

    renderedCallback() {
        if(this.isAnswered) { 
            this.refs.bottomdiv.scrollIntoView(false);
        }
    }

    /**
     * 
     * @param {object} level 
     * @param {object} nextLevel 
     * @param {object} value 
     * @param {object} levelId 
     * @param {object} attributes
     * @description Dispatch the response event to the parent with details 
     */
    dispatchResponseEvent(level, nextLevel, value, levelId, attributes) {
        
        this.dispatchEvent(
            new CustomEvent("response", {
                detail: {
                    level: level,
                    nextLevel: nextLevel,
                    value: value,
                    levelId: levelId,
                    attributes: attributes
                }

            })
        )
    }

    /**
     * 
     * @param {object} event 
     * @returns Handle the answer by the user
     */
    handleAnswer(event) {
        if (this.isAnswered) return;
        let nextLevelAttributes = (this.questionSet.attributes ? JSON.parse(JSON.stringify(this.questionSet.attributes)) : {});
        let value = null;
        let nextLevel = null;
        if (this.isRecordPicker || this.isCombobox || this.isComboboxPill) {
            this.hideAnswer = true;

            this.selectedAnswer = "Answered";
            if (this.isComboboxPill) {
                value = this.pills;
            } else {
                value = event.detail.value;
            }


        }

        //list
        else {
            this.selectedAnswer = event.target.label;
            value = event.target.value;
        }
        nextLevel = (event.target.nextlevel ? event.target.nextlevel : this.questionSet.nextLevel);


        this.dispatchResponseEvent(this.questionSet.level,
            nextLevel, value,
            this.questionSet.levelId,
            nextLevelAttributes);
    }

    handleAddPill(event) {
        let selectedSpoIdx = this.comboboxPillOptions.findIndex(item => item.value === event.detail.value);
        let foundPill = this.pills.find(item => item.value === event.detail.value);
        if (selectedSpoIdx !== -1 && !foundPill) {
            this.pills.push(JSON.parse(JSON.stringify(this.comboboxPillOptions[selectedSpoIdx])));
        }

        this.template.querySelector('lightning-combobox[data-name="comboboxPill"]').value = null;
        this.dispatchEvent(new RefreshEvent());

    }

    handleRemovePill(event) {
        if (!this.answerIsDisabled) {
            try {
                let indexToRemove = event.detail.index;
                this.pills.splice(indexToRemove, 1);
                this.dispatchEvent(new RefreshEvent());
            } catch (error) {
                promptError(this.label.ERROR_LABEL, getErrorMessage(error));
            }
        }
    }



    /**
     * @descripton Spinner toggler
     */
	@api toggleSpinner(loadCount){
        this.loadedLists += loadCount;

        if(this.loadedLists <= 0){
            this.loadedLists = 0;
        }
    }

    /**
     * @descripton Spinner loading status
     */
	get isLoading(){
        return this.loadedLists === 0 ? false : true;
    }


   

    /**
     * @descripton Console log for debugging
     */
    consoleLog(anything, isJson) {
        logInfo('ChatbotQna', anything, this.enableDebugMode, isJson);
    }




}