/**
 * @Author 		WDCi (XW)
 * @Date 		May 2024
 * @group 		
 * @Description Chatbot to be used in digital experience 
 * @changehistory
 * ISS-001916 20-05-2024 XW - Chatbot to be used in digital experience
 * ISS-002150 25-10-2024 Lean - Removed the position:fixed css property
 * ISS-002187 05-12-2024 XW - Removed default value if propetry is not set.
 * ISS-002189 16-12-2024 XW - added show study unit quick search
 * ISS-002463 13-05-2025 XiRouh - Added configurable attributes
 */
import { LightningElement, api, track } from 'lwc';
import { logInfo } from 'c/loggingUtil';

export default class DigitalExperienceChatbot extends LightningElement {

    //configurable attributes
    @api modalTitle;
    @api modalIconName;
    
    @api recordId;
    @api objectApiName;
    @api accordionBackgroundColor;
    @api accordionTextColor;
    @api forCommunity = false; //obsolete

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
    @api studyPathwayUnitInfoFields;
    @api studyPathwayUnitTitleField;
    @api studyPathwayUnitIcon;
    @api studyPathwayGroupTitleField;
    @api studyPathwayGroupInfoFields;
    @api studyPathwayGroupIcon;
    @api showStudyPlanOptions;
    @api comboboxLabel;

    @api chatbotIconName;
    @api chatbotIconSize;
    @api chatbotIconColour;
    @api chatbotIconBackgroundColour;
    @api showStudyUnitQuickSearch

    @api enableDebugMode = false;

    //internal attributes
    @track isChatWindowOpened = false;

    connectedCallback() {
        this.updateCssVars();
    }

    /**
     * @description Update css var
     */
    updateCssVars() {

        let css = this.template.host.style;
        css.setProperty('--chatbot-icon-background-color', this.chatbotIconBackgroundColour);
        css.setProperty('--chatbot-icon-color', this.chatbotIconColour);
    }

    /**
     * @description toggle the chat window
     */
    get chatWindowClasses() {
        if (this.isChatWindowOpened) {
            return 'floating-window-visible';
        }

        return 'floating-window-hidden';
    }
    
    /**
     * @description toggle the chatbot
     */
    toggleWindow() {
        this.isChatWindowOpened = !this.isChatWindowOpened;
    }

    /**
     * @description close the chatbot
     */
    closeWindow() {
        this.isChatWindowOpened = false;
    }

    /**
     * @descripton Console log for debugging
     */
    consoleLog(anything, isJson) {
        logInfo('DigitalExperienceChatbot', anything, this.enableDebugMode, isJson);
    }

}