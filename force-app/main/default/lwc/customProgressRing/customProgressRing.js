/**
 * @Author 		WDCi (XW)
 * @Date 		Jan 2025
 * @group 		Custom Progress Ring
 * @Description Configurable Progress Ring 
 * @changehistory
 * ISS-002186 07-01-2025 XW - create new class
 */
import { LightningElement, api } from 'lwc';
import { logInfo } from 'c/loggingUtil';

export default class CustomProgressRing extends LightningElement {
	
	//configurable attributes
    get progress() {
        return this._progress;
    }

    //between 0 and 100
	@api set progress(value) {
        if(value < 0) {
            value = 0;
        } else if(value > 100) {
            value = 100;
        }
        this._progress = value;
    }


    get width() {
        return this._width;
    }

	@api set width(value) {
        this._width = value;
        this.template.host.style.setProperty('--customprogressring-width', value);
    }

    get height() {
        return this._height;
    }

    @api set height(value) {
        this._height = value;
        this.template.host.style.setProperty('--customprogressring-height', value);
    }

    get pathColor() {
        return this._pathColor;
    }

    @api set pathColor(value) {
        this._pathColor = value;
        this.template.host.style.setProperty('--customprogressring-pathColor', value);
    }

    get pathThickness(){
        return this._pathThickness;
    }

    @api set pathThickness(value) {
        this._pathThickness = value;
        this.template.host.style.setProperty('--customprogressring-pathThickness', value);
    }
    @api drawInClockwise = false;
    @api enableDebugMode = false;

	//internal attributes
	loadedLists = 0;
    _progress;
    _width;
    _height;
    _pathThickness;
    _pathColor;

	//js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'jquery', 'tooltips'
    modules = [];

    /**
     * @description calculate the path of the progress ring
     */
    get pathD() {
        let isLong = this.progress > 50 ? 1 : 0;
        let clockwiseFlag = this.drawInClockwise ? 0 : 1;
        let arcX = Math.cos(2 * Math.PI * (this.progress / 100.0));
        let arcY = Math.sin(2 * Math.PI * (this.progress / 100.0));
        if(this.drawInClockwise) {
            arcY *= -1;
        }
        let d = `M 1 0 A 1 1 0 ${isLong} ${clockwiseFlag} ${arcX} ${arcY} L 0 0`
        this.consoleLog(d);
        return d;
    }

    /**
     * @description Update css var
     */
    updateCssVars() {
        let css = this.template.host.style;
        css.setProperty('--customprogressring-width', this.width);
        css.setProperty('--customprogressring-height', this.height);
        css.setProperty('--customprogressring-pathColor', this.pathColor);
        css.setProperty('--customprogressring-pathThickness', this.pathThickness);
    }
	
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
        logInfo('CustomProgressRing', anything, this.enableDebugMode, isJson);
    }
	
}