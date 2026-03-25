/**
 * @Author 		WDCi (Lean)
 * @Date 		Sept 2023
 * @group 		Util
 * @Description Javascript library and CSS loader
 * @changehistory
 * ISS-001920 23-04-2024 Lean - added tooltips library, removed jquery
 */
import { LightningElement, api } from 'lwc';
import { promptInfo, promptError, promptWarning, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';
import { customLabels } from 'c/labelLoader';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';

import REDU_RES from '@salesforce/resourceUrl/redu_resource';
import CE_RES from '@salesforce/resourceUrl/continuing_edu_resource';

export default class JsLibraryLoader extends LightningElement {
	
	//configurable attributes
	@api reloadOnError = false;
    @api modules = [];
    @api enableDebugMode = false;
	
	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false;
	loadedLists = 0;
	
	//labels
	label = customLabels;

    //'lodash', 'stringutil', 'noheadercss', 'continuingeducss', 'moment', 'fullcalendar', 'fcmoment', 'tooltips', 'jquery'
    _LODASH = 'lodash';
    _STRUTIL = 'stringutil';
    _NOHEADER = 'noheadercss';
    _MOMENT = 'moment';
    _FC = 'fullcalendar';
    _FCMOMENT = 'fcmoment';
    _CONTINUINGEDU = 'continuingeducss';
    _TOOLTIPS = 'tooltips';
    _JQUERY = 'jquery';
	
	renderedCallback() {
        //ISS-000410
        if(!this.isScriptLoaded){
            this.loadLibraries();
        }
    }

    /**
     * @description lodash library
     */
    async loadLodashLib() {
        //we only load the script if it is not there, otherwise the salesforce will fail it silently
        if (this.modules && this.modules.includes(this._LODASH)) {
            if(typeof _ != "undefined"){
                this.consoleLog('renderedCallback - lodash found. skip loading.');
            } else {
                this.consoleLog('renderedCallback - lodash not found. loading');

                await Promise.all([
                    loadScript(this, REDU_RES + '/lodash/lodash.js')
                ]);

                this.consoleLog('renderedCallback - loaded lodash.');
            }
        }
    }

    /**
     * @description String merge library
     */
    async loadStringUtilLib() {
        if (this.modules && this.modules.includes(this._STRUTIL)) {
            //we only load the script if it is not there, otherwise the salesforce will fail it silently
            if(typeof String.prototype.format != "undefined"){
                this.consoleLog('renderedCallback - stringutil found. skip loading.');
            } else {
                this.consoleLog('renderedCallback - stringutil not found. loading');

                await Promise.all([
                    loadScript(this, REDU_RES + '/utils/stringutil.js')
                ]);

                this.consoleLog('renderedCallback - loaded stringutil.');
            }
        }
    }

    /**
     * @description No header app css
     */
    async loadNoHeaderCss() {
        if (this.modules && this.modules.includes(this._NOHEADER)) {
            this.consoleLog('renderedCallback - noheader css. loading');

            await Promise.all([
                loadStyle(this, REDU_RES + '/css/noheader.css')
            ]);

            this.consoleLog('renderedCallback - loaded noheader css.');
        }
    }

    /**
     * @description Continuing edu css
     */
    async loadContinuingEduCss() {
        if (this.modules && this.modules.includes(this._CONTINUINGEDU)) {
            this.consoleLog('renderedCallback - continuing edu css. loading');

            await Promise.all([
                loadStyle(this, CE_RES + '/css/continuing_edu.css')
            ]);

            this.consoleLog('renderedCallback - loaded continuing edu css.');
        }
    }

    /**
     * @description moment library
     */
    async loadMomentLib() {
        if (this.modules && this.modules.includes(this._MOMENT)) {
            //we only load the script if it is not there, otherwise the salesforce will fail it silently
            if(typeof moment != "undefined"){
                this.consoleLog('renderedCallback - moment found. skip loading.');
            } else {
                this.consoleLog('renderedCallback - moment not found. loading');

                await Promise.all([
                    loadScript(this, REDU_RES + '/moment/moment-with-locales.min.js')
                ]);

                await Promise.all([
                    loadScript(this, REDU_RES + '/moment/moment-timezone-with-data.js')
                ]);

                this.consoleLog('renderedCallback - loaded moment.');
            }
        }
    }

    /**
     * @description fullcalendar library
     */
    async loadFullCalendarLib() {
        if (this.modules && this.modules.includes(this._FC)) {
            //we only load the script if it is not there, otherwise the salesforce will fail it silently
            if(typeof FullCalendar5 != "undefined"){
                this.consoleLog('renderedCallback - fullcalendar5 found. skip loading.');
            } else {
                this.consoleLog('renderedCallback - fullcalendar5 not found. loading');

                await Promise.all([
                    loadScript(this, REDU_RES + '/fullcalendar-v5/lib/main.min.js'),
                    loadStyle(this, REDU_RES + '/fullcalendar-v5/lib/main.min.css')
                ]);

                await Promise.all([
                    loadScript(this, REDU_RES + '/fullcalendar-v5/lib/locales-all.min.js')
                ])

                this.consoleLog('renderedCallback - loaded fullcalendar5.');
            }
        }
    }

    /**
     * @description fullcalendar-moment connector
     */
    async loadFcMomentConnectorLib() {
        if (this.modules && this.modules.includes(this._FCMOMENT)) {
            //we only load the script if it is not there, otherwise the salesforce will fail it silently
            if(typeof FullCalendarMoment != "undefined"){
                this.consoleLog('renderedCallback - fcmoment connector found. skip loading.');
            } else {
                this.consoleLog('renderedCallback - fcmoment connector not found. loading');

                await Promise.all([
                    loadScript(this, REDU_RES + '/fullcalendar-v5/lib/moment/main.global.min.js')
                ]);

                this.consoleLog('renderedCallback - loaded fcmoment connector.');
            }
        }
    }

    /**
     * @description Tooltips library
     */
    async loadTooltipsLib() {
        if (this.modules && this.modules.includes(this._TOOLTIPS)) {
            //we only load the script if it is not there, otherwise the salesforce will fail it silently
            if(typeof tippy != "undefined"){
                this.consoleLog('renderedCallback - tippy found. skip loading.');
            } else {
                this.consoleLog('renderedCallback - tippy not found. loading');

                await Promise.all([
                    loadScript(this, REDU_RES + '/tooltips/popper.min.js'),
                    loadScript(this, REDU_RES + '/tooltips/tippy-bundle.umd.min.js')
                ]);

                this.consoleLog('renderedCallback - loaded tippy.');
            }
        }
    }

    async loadJqueryLib() {
        if (this.modules && this.modules.includes(this._JQUERY)) {
            //we only load the script if it is not there, otherwise the salesforce will fail it silently
            if(typeof jQuery != "undefined"){
                this.consoleLog('renderedCallback - jquery found. skip loading.');
            } else {
                this.consoleLog('renderedCallback - jquery not found. loading');

                await Promise.all([
                    loadScript(this, REDU_RES + '/jquery/jquery.js')
                ]);

                this.consoleLog('renderedCallback - loaded jquery.');
            }
        }
    }

    async loadLibraries() {

        try {
            if (this.modules) {
                this.consoleLog('renderedCallback - attempting to load ' + JSON.stringify(this.modules));

                // we have to load the libraries according to the sequence below to avoid failure
                // 'lodash', 'stringutil', 'noheadercss', 'continuingeducss', 'moment', 'fullcalendar', 'fcmoment', 'tooltips', 'jquery'

                if (this.modules.includes(this._LODASH)) {
                    await this.loadLodashLib();
                }
                
                if (this.modules.includes(this._STRUTIL)) {
                    await this.loadStringUtilLib();
                }

                if (this.modules.includes(this._NOHEADER)) {
                    await this.loadNoHeaderCss();
                }

                if (this.modules.includes(this._CONTINUINGEDU)) {
                    await this.loadContinuingEduCss();
                }

                if (this.modules.includes(this._MOMENT)) {
                    await this.loadMomentLib();
                }
                
                if (this.modules.includes(this._FC)) {
                    await this.loadFullCalendarLib();
                }
                
                if (this.modules.includes(this._FCMOMENT)) {
                    await this.loadFcMomentConnectorLib();
                }
                
                if (this.modules.includes(this._TOOLTIPS)) {
                    await this.loadTooltipsLib();
                }
                
                if (this.modules.includes(this._JQUERY)) {
                    await this.loadJqueryLib();
                }
                
                this.consoleLog('renderedCallback - all libraries loaded.');
            }

            this.isScriptLoaded = true;
            this.isInitSuccess = true;

            this.dispatchEvent(new CustomEvent("success", {}));

        } catch(error) {

            if (this.reloadOnError) {
                document.location.reload();
            } else {
                promptError(this.label.ERROR_LABEL, getErrorMessage(error));
            }

            this.isScriptLoaded = true;
            this.isInitSuccess = false;

            this.dispatchEvent(new CustomEvent("fail", {}));
        }
    }
		
	consoleLog(anything, isJson){
        logInfo('jsLibraryLoader', anything, this.enableDebugMode, isJson);
    }
	
}