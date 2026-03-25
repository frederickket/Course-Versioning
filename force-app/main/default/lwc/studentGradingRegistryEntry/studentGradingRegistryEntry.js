/**
 * @Author 		WDCi (CM)
 * @Date 		Sept 2024
 * @group 		Grade Management
 * @Description Student Grading Wizard - Study Session or Study Offering record page
 * @changehistory
 * ISS-001918 04-09-2024 Lean - placeholder for student grading enhancement
 */
import { LightningElement, api } from 'lwc';
import { logInfo } from 'c/loggingUtil';
import { customLabels } from 'c/labelLoader';

export default class StudentGradingRegistryEntry extends LightningElement {
	
    //configurable attributes
    @api userMode;
    
    @api contactTileInfoFields;
    @api contactImageFileName;
    @api contactImageUrlFieldName;
    @api contactTileClickAction;
    @api infoModalFieldsForContact;
    @api infoModalSectionNameForContact;
	
    @api lockedIgdStatus;
    @api individualGradeItemNotesFieldSetName;
    
    @api enableDebugMode = false;

    //api attributes that requires from parent
    @api sw;
    @api gradingConfigDataWrapper;
    
    @api set studentSearchKey(value){
        this._studentSearchKey = value;
        this.updateRowDisplayMode();
    }

    get studentSearchKey() {
        return this._studentSearchKey;
    }    
	
	//internal attributes
    _studentSearchKey;
    loadedLists = 0;

    IGI_TYPE = "reduivy__Individual_Grade_Item__c";
    IGD_TYPE = "reduivy__Individual_Enrollment_Grade__c";
    LOCKING_MODE_LOCKED = 'Locked'; //ISS-002257

	//labels
	label = customLabels;

    /**
     * @descripton rendered callback
     */
	renderedCallback(){

    }

    /**
     * @descripton connected callback
     */
    connectedCallback(){
		
	}
	
    /**
     * @descripton disconnected callback
     */
	disconnectedCallback() {
		
	}
	
    /**
     * @description Prevent grades from being updated if we're outside the Study Grade Period Setting dates
     */
    get isSgpLocked(){
        if (this.gradingConfigDataWrapper){
            return (this.gradingConfigDataWrapper.sgp.reduivy__Locking_Mode__c === this.LOCKING_MODE_LOCKED); //ISS-002257
        }
        return true;
    }

    /**
     * @description Return true if matches the search key
     */
    updateRowDisplayMode() {
        let isMatched = true;
        if (this.studentSearchKey){
            //Show student if name partially matches studentSearchKey
            isMatched = this.sw?.ien?.reduivy__Contact__r?.Name?.toLowerCase()?.indexOf(this.studentSearchKey) >= 0;
        }

        let css = this.template.host.style;
        css.setProperty('--entry-row-display', (isMatched ? 'table-row' : 'none'));
    }

    /**
     * @description Return SGI wrapper list with unique key to handle sorting without the rerendering the whole component
     */
    get sgiWrapperList() {

        let sgiWrappers = [];
        if (this.sw && this.gradingConfigDataWrapper.tableColumnSgiList) {
            for (let sgiWrapper of this.gradingConfigDataWrapper.tableColumnSgiList) {
                let tempWrapper = JSON.parse(JSON.stringify(sgiWrapper));
                tempWrapper.key = this.sw?.ien?.Id + '_' + sgiWrapper?.sgi?.Id;

                sgiWrappers.push(tempWrapper);
            }
        }

        return sgiWrappers;
    }

    /**
     * @description Return IGD custom field wrapper list with unique key to handle sorting without the rerendering the whole component
     */
    get igdCustomFieldList() {

        let igiCustomFieldWrappers = [];
        if (this.sw && this.gradingConfigDataWrapper.igdCustomFields) {
            for (let igdCustomField of this.gradingConfigDataWrapper.igdCustomFields) {
                let tempWrapper = JSON.parse(JSON.stringify(igdCustomField));
                tempWrapper.key = this.sw?.ien?.Id + '_' + igdCustomField?.fieldName;

                igiCustomFieldWrappers.push(tempWrapper);
            }
        }

        return igiCustomFieldWrappers;
    }

    /**
     * @description Handle the registry entry cell update event and pass the info to parent
     */
    handleGradeEntryCellUpdate(event) {
        const {gradeEntryInfo} = event.detail;
        
        this.dispatchEvent(new CustomEvent("gradeentryupdate", {
            detail: {
                gradeEntryInfo: gradeEntryInfo
            }
        }));
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
        logInfo('StudentGradingRegistryEntry', anything, this.enableDebugMode, isJson);
    }
	
}