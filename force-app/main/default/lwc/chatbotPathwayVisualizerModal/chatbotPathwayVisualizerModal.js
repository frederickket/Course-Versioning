/**
 * @Author 		WDCi (XW)
 * @Date 		May 2024
 * @group 		
 * @Description Pathway Visualizer Modal for Chatbot
 * @changehistory
 * ISS-001917 20-05-2024 name - Pathway Visualizer Modal for Chatbot
 * ISS-002191 12-12-2024 XW - Pass hrefTarget into studyPathwayUnit
 * ISS-002189 16-12-2024 XW - added show study unit quick search
 * ISS-002375 02-05-2025 xW - add logging
 */
import { api } from 'lwc';
import { logInfo } from 'c/loggingUtil';
import { customLabels } from 'c/labelLoader';
import LightningModal from 'lightning/modal';



export default class ChatbotPathwayVisualizerModal extends LightningModal {
	
	//configurable attributes
    @api modalTitle;
    @api modalIconName;
    @api studyPathwayInfoFields;
    @api studyPathwayTermTitlePrefix;
    @api studyPathwayTermInfoFields;
    @api studyPathwayUnitTitleField;
    @api studyPathwayUnitInfoFields;
    @api studyPathwayUnitIcon;
    @api studyPathwayGroupTitleField;
    @api studyPathwayGroupInfoFields;
    @api studyPathwayGroupIcon;
    @api recordId;
    @api showStudyPlanOptions = false;
    @api enableDebugMode = false;
    @api accordionBackgroundColor;
    @api accordionTextColor;
    @api comboboxLabel;
    @api hrefTargetType;
    @api showStudyUnitQuickSearch; //ISS-002189
    
	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false;
	loadedLists = 0;
	
	//labels
	label = customLabels;
	
	//js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'tooltips'
    modules = [];
	
	/**
     * @descripton library loader
     */
    handleLibLoadSuccess() {
        this.isScriptLoaded = true;
        this.isInitSuccess = true;
        
    }

    handleClose(){
        this.close({operation:'close'});
        this.consoleLog('handleClose');
    }
    
    /**
    * @descripton library loader
    */
    handleLibLoadFail() {
        this.isScriptLoaded = true;
        this.isInitSuccess = false;
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
        logInfo('ChatbotPathwayVisualizerModal', anything, this.enableDebugMode, isJson);
    }
	
}