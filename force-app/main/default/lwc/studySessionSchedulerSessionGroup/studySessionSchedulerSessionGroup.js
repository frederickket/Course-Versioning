/**
 * @author      WDCi (Lean)
 * @date        Jun 2024
 * @group       Study Session Scheduler
 * @description Study session scheduler session group component
 * @changehistory
 * ISS-001920 11-06-2024 Lean - new class
 * ISS-002213 06-12-2024 XW - get the calendar start date and end date from studySessionScheduler
 */
import { LightningElement, api, track } from 'lwc';
import { promptError } from 'c/toasterUtil';
import { getErrorMessage, logInfo } from 'c/loggingUtil';
import { sessionSchedulerLabels } from 'c/studySessionSchedulerHelper';

export default class StudySessionSchedulerSessionGroup extends LightningElement {
	
	//configurable attributes
    @api allowEditSession = false;
    @api allowDeleteSession = false;
    @api allowFacilityAssignment = false;
    @api allowFacultyContactAssignment = false;
    @api allowPreviewSession = false;
    @api allowSendAnnouncement = false;
    @api allowCustomAction = false;
    @api neutralizedCurrentCalendarStartDate; //ISS-002213
    @api neutralizedCurrentCalendarEndDate; //ISS-002213
    
    @api customActionLabel;
    @api customActionFlowName;
    @api customActionFlowFinishBehavior;
    @api customActionShowCloseButton;

    //session edit form
    @api editFormStudySessionFieldSetName;
    @api editFormStudySessionTimeFieldSetName;
    @api editFormSseColumnNo;
    @api editFormSstColumnNo;
    @api accordionBackgroundColor;
    @api accordionTextColor;
    @api accordionButtonVariant;

    @api facilityDefaultCriteria;
    @api allowCrossCampusFacilityAllocation = false;

    @api studySessionNameFormat;

    @api timelineMinTime;
    @api timelineMaxTime;
    
    /**
     * @description To make the object reactive to changes from parent
     */
    @api
    set groupObj(val) {
        this._groupObj = val;
    }

    get groupObj() {
        return this._groupObj;
    }
    
    /**
     * @description strigified json data
     */
    @api 
    set hiddenGroupsAndStudySessions(val) {
        this.consoleLog('hiddenGroupsAndStudySessions');
        this.consoleLog(val, true);

        this._hiddenGroupsAndStudySessions = JSON.parse(val);
    }

    get hiddenGroupsAndStudySessions() {
        return this._hiddenGroupsAndStudySessions;
    }

    @api parentIds; //stringified array
	@api enableDebugMode = false;
	
	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false;
	loadedLists = 0;

    //for expansion button
    isCollapsed = false;

    @track _groupObj;
    @track _hiddenGroupsAndStudySessions;
    @track _parentIds = [];

	//labels
	label = sessionSchedulerLabels;
	
	//js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'tooltips'
    modules = [];
	
	/**
     * @descripton library loader
     */
    handleLibLoadSuccess() {
        this.isScriptLoaded = true;
        this.isInitSuccess = true;
        
        this.updateCssVars();
    }

    /**
     * @descripton library loader
     */
    handleLibLoadFail() {
        this.isScriptLoaded = true;
        this.isInitSuccess = false;
    }

    /**
     * @descripton connected callback
     */
    connectedCallback(){

        //we store the parent hierarchy here
        if (this.parentIds) {
            this._parentIds = JSON.parse(this.parentIds);
        }

        if (this._parentIds) {
            this._parentIds.push(this.groupObj.uniquename);
        } else {
            this._parentIds = [this.groupObj.uniquename];
        }
	}

    /**
     * @description Return expansion icon
     */
    get expansionIconName() {
        return this.isCollapsed ? 'utility:chevronright' : 'utility:chevrondown';
    }

    /**
     * @description Return css class to hide/show child groups/classes
     */
    get expansionChildDivCss() {
        return 'studysessionschedulersessiongroup-childdiv' + (this.isCollapsed ? ' slds-hide' : '');
    }

    /**
     * @description Return true if the group has child groups
     */
    get hasChildGroups() {
        return this.groupObj && this.groupObj.groups;
    }

    /**
     * @description Return group's uniquename
     */
    get groupUniqueName() {
        return this.groupObj.uniquename;
    }

    /**
     * @description Return group's name
     */
    get groupLabel() {
        return this.groupObj.name;
    }

    /**
     * @description Return child groups
     */
    get childGroups() {
        return this.groupObj?.groups;
    }

    /**
     * @description Return child study sessions of the group
     */
    get childStudySessions() {
        return this.groupObj?.studySessions;
    }

    /**
     * @description Return the value for the visibility checkbox
     */
    get isVisible() {
        if (this._hiddenGroupsAndStudySessions && this._hiddenGroupsAndStudySessions.includes(this.groupObj.uniquename)) {
            return false;
        }
        //the group checkbox will not be checked if any of its study sessions are hidden
        if (this.groupObj?.studySessions) {
            for(let newGroupSession of this.groupObj.studySessions){
                if(this._hiddenGroupsAndStudySessions.includes(newGroupSession.Id)){
                    return false;
                }
            }
        }

        return true;
    }

    /**
     * @description Return stringified _hiddenGroupsAndStudySessions
     */
    get stringifiedHiddenGroupsAndStudySessions() {
        return JSON.stringify(this._hiddenGroupsAndStudySessions);
    }

    /**
     * @description Return stringified _parentIds
     */
    get stringifiedParentIds() {
        return JSON.stringify(this._parentIds);
    }

    /**
     * @description Return padding left
     */
    get groupPaddingLeftSize() {

        return (this._parentIds ? (this._parentIds.length - 1) * 3 : 0) + 'px';
    }

    /**
     * @description Return padding left
     */
    get sessionsPaddingLeftSize() {

        return (this._parentIds ? (this._parentIds.length * 3) + 16 : 0) + 'px';
    }

    /**
     * @description Update css var
     */
    updateCssVars() {
        let css = this.template.host.style;

        css.setProperty('--group-div-padding-left', this.groupPaddingLeftSize);
        css.setProperty('--childsessions-div-padding-left', this.sessionsPaddingLeftSize);
    }

    /**
     * @description Handle expansion button icon click
     */
    handleExpansionButtonClick() {
        this.isCollapsed = !this.isCollapsed;
    }

    /**
     * @description Handle visibility checkbox onchange
     * @param {*} event 
     */
    handleVisibilityCheckboxChange(event) {
        this.consoleLog('handleVisibilityCheckboxChange');

        try {
            let checked = event.target.checked;

            let updatedObjects = [{id: this.groupObj.uniquename, visible: checked}];
            updatedObjects = updatedObjects.concat(this.extractClasses(this.groupObj, checked));
            
            this.consoleLog(updatedObjects, true);

            let tempHolderSet =  this.stringifiedHiddenGroupsAndStudySessions ? new Set(JSON.parse(this.stringifiedHiddenGroupsAndStudySessions)) : new Set();
            let tempHolder = Array.from(tempHolderSet)
            for (let obj of updatedObjects) {

                if (obj.visible) {
                    let idx = tempHolder.indexOf(obj.id);
                    if (idx > -1) {
                        tempHolder.splice(idx, 1);
                    }
                } else {
                    tempHolder.push(obj.id);
                }
            }

            this.consoleLog(tempHolder, true);

            this.dispatchEvent(
                new CustomEvent("visibilityupdated", {
                    detail: {
                        groupOrStudySessions: tempHolder,
                        isVisible: checked
                    }
                })
            );
        } catch (err) {
            promptError(this.label.ERROR_LABEL, getErrorMessage(err));
        }
    }

    /**
     * @description get the child element (child group or child class)
     */
    extractClasses(groupObj, checkedValue){
        let updatedObjects = [];

        if(groupObj.groups){
            updatedObjects = updatedObjects.concat(this.extractChildGroups(groupObj, checkedValue));
        } else if(groupObj.studySessions){
            updatedObjects = updatedObjects.concat(this.extracChildClasses(groupObj, checkedValue));
        }

        return updatedObjects;
    }

    /**
    * @description get the child study session 
    */
    extracChildClasses(groupObj, checkedValue){
        let updatedObjects = [];

        for(let sseObj of groupObj.studySessions){
            updatedObjects.push({id: sseObj.Id, visible: checkedValue});
        }

        return updatedObjects;
    }

    /**
    * @description get the child group
    */
    extractChildGroups(groupObj, checkedValue){
        let updatedObjects = [];

        for(let childGroup of groupObj.groups){
            updatedObjects.push({id: childGroup.uniquename, visible: checkedValue});

            updatedObjects = updatedObjects.concat(this.extractClasses(childGroup, checkedValue));
        }

        return updatedObjects;
    }

    /**
     * @description handle group checkbox or study session checkbox (event dispatched from study session)
     */
    handleVisibilityUpdated(event) {
        this.consoleLog('handleVisibilityUpdated');

        const {groupOrStudySessions, isVisible} = event.detail;

        this._hiddenGroupsAndStudySessions = groupOrStudySessions;
        
        this.consoleLog(this._hiddenGroupsAndStudySessions, true);

        this.dispatchEvent(
            new CustomEvent("visibilityupdated", {
                detail: {
                    groupOrStudySessions: this._hiddenGroupsAndStudySessions,
                    isVisible: isVisible
                }
            })
        );
    }

    /**
     * @description Handle study session deleted event from child components
     * @param {*} event 
     */
    handleStudySessionDeleted(event) {
        const { studySessionId } = event.detail;

        //notify the parent component about the deletion
        this.dispatchEvent(
            new CustomEvent("studysessiondeleted", {
                detail: {
                    studySessionId: studySessionId
                }
            })
        );
    }

	/**
     * @description Handle study session preview from child components
     * @param {*} event 
     */
    handlePreviewClicked(event) {
        const detail = JSON.parse(JSON.stringify(event.detail));

        //notify the parent component about the preview
        this.dispatchEvent(
            new CustomEvent("previewclicked", {
                detail: detail
            })
        );
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
        logInfo('StudySessionSchedulerSessionGroup', anything, this.enableDebugMode, isJson);
    }
	
}