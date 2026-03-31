/**
 * @author      RIO Education
 * @date        2026
 * @group       CO-PO Mapping
 * @description CO-PO Mapping matrix component.
 *              Displays Course Outcomes as rows and Program Outcomes as columns
 *              with editable weight values persisted to Course_Outcome_Program_Outcome__c.
 *              Supports add/remove PO columns, add CO rows, orange warning for unconfigured
 *              weight cells, and hover detail cards for CO/PO records.
 * @changehistory
 */
import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';
import { promptSuccess, promptError } from 'c/toasterUtil';
import { getErrorMessage, logInfo } from 'c/loggingUtil';
import { customLabels } from 'c/labelLoader';

import ctrlGetCourseOutcomes   from '@salesforce/apex/REDU_CoPoMapping_LCTRL.getCourseOutcomes';
import ctrlGetProgramOutcomes  from '@salesforce/apex/REDU_CoPoMapping_LCTRL.getProgramOutcomes';
import ctrlGetMappings         from '@salesforce/apex/REDU_CoPoMapping_LCTRL.getMappings';
import ctrlSaveMappingWeight   from '@salesforce/apex/REDU_CoPoMapping_LCTRL.saveMappingWeight';
import ctrlDeleteCourseOutcome from '@salesforce/apex/REDU_CoPoMapping_LCTRL.deleteCourseOutcome';

export default class CoPoMapping extends NavigationMixin(LightningElement) {

    /**
     * Automatically provided by the framework when placed on a record page.
     * Used as studyUnitVersionId when the page object is Study_Unit_Version__c.
     */
    @api recordId;
    @api objectApiName;

    /** Optional override: explicit Study Unit Version Id (App Page / Home Page use) */
    @api studyUnitVersionId;

    /** Optional: filter Program Outcomes by Study Plan. Leave blank to show all. */
    @api studyPlanId;

    @api enableDebugMode = false;

    // internal attributes
    courseOutcomes = [];
    programOutcomes = [];
    mappingMap = {};        // key = 'coId_poId', value = { mapId, weight }
    errorMessage;

    _coLoaded = false;
    _poLoaded = false;

    // spinner counter — loadedLists > 0 means loading
    loadedLists = 1;

    // hover detail popover state
    hoveredRecord = null;   // { type: 'co'|'po', record, x, y }

    // wire result holders
    _coWireResult;
    _poWireResult;

    // labels
    label = customLabels;

    // ─── Lifecycle ────────────────────────────────────────────────────────────

    /**
     * @description connected callback — auto-detect Study Unit Version from record page context.
     *              objectApiName is 'Study_Unit_Version__c' in scratch orgs and
     *              'reduivy__Study_Unit_Version__c' in packaged orgs; endsWith handles both.
     */
    connectedCallback() {
        if (!this.studyUnitVersionId && this.recordId
                && this.objectApiName && this.objectApiName.endsWith('Study_Unit_Version__c')) {
            this.studyUnitVersionId = this.recordId;
        }
    }

    /**
     * @description rendered callback — positions the hover detail tooltip via direct DOM style
     *              to avoid VS Code CSS linter errors from dynamic style bindings in HTML.
     */
    renderedCallback() {
        const tooltip = this.template.querySelector('.record-tooltip');
        if (!tooltip) return;
        if (this.hoveredRecord) {
            const { x, y } = this.hoveredRecord;
            tooltip.style.cssText =
                `position:fixed;top:${y}px;left:${x}px;z-index:9999;max-width:18rem;display:block;`;
        } else {
            tooltip.style.cssText = 'display:none;';
        }
    }

    /**
     * @description disconnected callback
     */
    disconnectedCallback() {}

    // ─── Wire: Course Outcomes ────────────────────────────────────────────────

    @wire(ctrlGetCourseOutcomes, { studyUnitVersionId: '$studyUnitVersionId' })
    wiredCourseOutcomes(result) {
        this._coWireResult = result;
        if (result.data) {
            this.courseOutcomes = result.data;
            this._coLoaded = true;
            this._tryLoadMappings();
            this.consoleLog(result.data, true);
        } else if (result.error) {
            this.errorMessage = getErrorMessage(result.error);
            this.loadedLists = 0;
        }
    }

    // ─── Wire: Program Outcomes ───────────────────────────────────────────────

    @wire(ctrlGetProgramOutcomes, { studyPlanId: '$studyPlanId' })
    wiredProgramOutcomes(result) {
        this._poWireResult = result;
        if (result.data) {
            this.programOutcomes = result.data;
            this._poLoaded = true;
            this._tryLoadMappings();
            this.consoleLog(result.data, true);
        } else if (result.error) {
            this.errorMessage = getErrorMessage(result.error);
            this.loadedLists = 0;
        }
    }

    // ─── Load Mappings (imperative, runs after both wire calls complete) ──────

    _tryLoadMappings() {
        if (!this._coLoaded || !this._poLoaded) return;

        if (this.courseOutcomes.length === 0 || this.programOutcomes.length === 0) {
            this.toggleSpinner(-1);
            return;
        }

        const coIds = this.courseOutcomes.map(co => co.Id);
        const poIds = this.programOutcomes.map(po => po.Id);

        ctrlGetMappings({ courseOutcomeIds: coIds, programOutcomeIds: poIds })
            .then(mappings => {
                const map = {};
                mappings.forEach(m => {
                    // Field names are namespace-prefixed in namespaced orgs — try both
                    const coId     = m.Course_Outcome__c  || m['reduivy__Course_Outcome__c'];
                    const poId     = m.Program_Outcome__c || m['reduivy__Program_Outcome__c'];
                    const weightVal = (m.Weight__c != null) ? m.Weight__c : m['reduivy__Weight__c'];
                    const key = `${coId}_${poId}`;
                    map[key] = { mapId: m.Id, weight: weightVal };
                });
                this.mappingMap = map;
                this.consoleLog(mappings, true);
            })
            .catch(error => {
                this.errorMessage = getErrorMessage(error);
            })
            .finally(() => {
                this.toggleSpinner(-1);
            });
    }

    // ─── Computed: Matrix rows (COs sorted numerically by code) ──────────────

    get matrixRows() {
        const sortedCos = [...this.courseOutcomes].sort((a, b) =>
            this._codeNum(this._coCode(a)) - this._codeNum(this._coCode(b))
        );
        const sortedPos = [...this.programOutcomes].sort((a, b) =>
            this._codeNum(this._poCode(a)) - this._codeNum(this._poCode(b))
        );
        return sortedCos.map(co => {
            const cells = sortedPos.map(po => {
                const key = `${co.Id}_${po.Id}`;
                const existing = this.mappingMap[key];
                const isUnconfigured = !existing;
                return {
                    key,
                    coId     : co.Id,
                    poId     : po.Id,
                    weight   : (existing && existing.weight != null) ? existing.weight : '',
                    cellClass: isUnconfigured
                        ? 'slds-text-align_center slds-p-around_xx-small weight-cell-warning'
                        : 'slds-text-align_center slds-p-around_xx-small'
                };
            });
            return {
                id   : co.Id,
                name : co.Name,
                label: this._coCode(co) || co.Name,
                cells
            };
        });
    }

    // ─── Computed: PO headers sorted numerically by code ─────────────────────

    get poHeaders() {
        return [...this.programOutcomes]
            .sort((a, b) =>
                this._codeNum(this._poCode(a)) - this._codeNum(this._poCode(b))
            )
            .map(po => ({
                id   : po.Id,
                name : po.Name,
                label: this._poCode(po) || po.Name
            }));
    }

    // ─── Computed: Template conditionals ─────────────────────────────────────

    /**
     * @description Spinner loading status
     */
    get isLoading() {
        return this.loadedLists > 0;
    }

    get hasData() {
        return !this.isLoading
            && !this.errorMessage
            && this.courseOutcomes.length > 0
            && this.programOutcomes.length > 0;
    }

    get hasNoData() {
        return !this.isLoading
            && !this.errorMessage
            && (this.courseOutcomes.length === 0 || this.programOutcomes.length === 0);
    }

    get hasError() {
        return !!this.errorMessage;
    }

    // ─── Computed: Hover popover ──────────────────────────────────────────────

    get hoveredIsCo() {
        return this.hoveredRecord && this.hoveredRecord.type === 'co';
    }

    get hoveredName() {
        return this.hoveredRecord ? this.hoveredRecord.record.Name : '';
    }

    get hoveredCode() {
        if (!this.hoveredRecord) return '';
        const rec = this.hoveredRecord.record;
        return this.hoveredRecord.type === 'co'
            ? this._coCode(rec)
            : this._poCode(rec);
    }

    get hoveredBtLevel() {
        if (!this.hoveredRecord || this.hoveredRecord.type !== 'co') return '';
        const rec = this.hoveredRecord.record;
        return rec.Blooms_Taxonomy_Level__c || rec['reduivy__Blooms_Taxonomy_Level__c'] || '—';
    }

    // ─── Computed: Namespace prefix (for NavigationMixin object names) ────────

    /**
     * @description Derives the object namespace prefix from objectApiName.
     *              e.g. 'reduivy__Study_Unit_Version__c' → 'reduivy__', '' in scratch orgs.
     */
    get _ns() {
        if (this.objectApiName) {
            const parts = this.objectApiName.split('__');
            if (parts.length >= 3) return `${parts[0]}__`;
        }
        return '';
    }

    // ─── Event handlers ───────────────────────────────────────────────────────

    /**
     * @description Handle weight cell change — lightning-input fires event.detail.value
     */
    handleWeightChange(event) {
        const rawVal = event.detail.value;
        const weight = (rawVal === '' || rawVal === null) ? null : parseFloat(rawVal);

        // lightning-input min/max shows the validation error automatically
        if (rawVal === '' || rawVal === null || isNaN(weight) || weight < 0 || weight > 5) return;

        const target = event.target;
        this._saveWeight(target.dataset.coid, target.dataset.poid, target.dataset.key, weight);
    }

    /**
     * @description Navigate to the CO record edit page.
     */
    handleEditCo(event) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId  : event.currentTarget.dataset.id,
                actionName: 'edit'
            }
        });
    }

    /**
     * @description Delete a Course Outcome record and remove it from the local matrix view.
     */
    handleDeleteCo(event) {
        const coId = event.currentTarget.dataset.id;
        ctrlDeleteCourseOutcome({ courseOutcomeId: coId })
            .then(() => {
                this.courseOutcomes = this.courseOutcomes.filter(co => co.Id !== coId);
                promptSuccess(this.label.SUCCESS_LABEL, 'Course Outcome deleted successfully.');
                return refreshApex(this._coWireResult);
            })
            .catch(error => {
                promptError(this.label.ERROR_LABEL, getErrorMessage(error));
            });
    }

    /**
     * @description Remove a PO column from the matrix view (local only, no DB delete)
     */
    handleRemovePo(event) {
        const poId = event.target.dataset.poid;
        this.programOutcomes = this.programOutcomes.filter(po => po.Id !== poId);
    }

    /**
     * @description Navigate to the standard new Program Outcome creation page/modal,
     *              pre-populating Study Plan when available.
     */
    handleAddPo() {
        const state = this.studyPlanId
            ? { defaultFieldValues: `${this._ns}Study_Plan__c=${this.studyPlanId}` }
            : {};
        this[NavigationMixin.Navigate]({
            type      : 'standard__objectPage',
            attributes: {
                objectApiName: `${this._ns}Program_Outcome__c`,
                actionName   : 'new'
            },
            state
        });
    }

    /**
     * @description Navigate to the standard new Course Outcome creation page/modal,
     *              pre-populating Study Unit Version when available.
     */
    handleAddCo() {
        const state = this.studyUnitVersionId
            ? { defaultFieldValues: `${this._ns}Study_Unit_Version__c=${this.studyUnitVersionId}` }
            : {};
        this[NavigationMixin.Navigate]({
            type      : 'standard__objectPage',
            attributes: {
                objectApiName: `${this._ns}Course_Outcome__c`,
                actionName   : 'new'
            },
            state
        });
    }

    /**
     * @description Navigate to a CO or PO record page.
     *              Used by both the CO row label and PO column header links.
     */
    handleRecordNavigate(event) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId  : event.currentTarget.dataset.id,
                actionName: 'view'
            }
        });
    }

    /**
     * @description Show a detail popover when hovering over a CO or PO link.
     */
    handleRecordMouseenter(event) {
        const type = event.currentTarget.dataset.type;
        const id   = event.currentTarget.dataset.id;
        const rect = event.currentTarget.getBoundingClientRect();

        const record = type === 'co'
            ? this.courseOutcomes.find(co => co.Id === id)
            : this.programOutcomes.find(po => po.Id === id);

        if (record) {
            this.hoveredRecord = { type, record, x: rect.left, y: rect.bottom + 6 };
        }
    }

    /**
     * @description Hide the detail popover when the mouse leaves a CO or PO link.
     */
    handleRecordMouseleave() {
        this.hoveredRecord = null;
    }

    // ─── Private: Apex save ───────────────────────────────────────────────────

    /**
     * @description Save or update a single CO-PO weight mapping.
     *              Optimistically updates local state before the server responds.
     *              Clears the isUnconfigured flag on success so the orange warning disappears.
     */
    _saveWeight(coId, poId, key, weight) {
        const updatedMap = Object.assign({}, this.mappingMap);
        updatedMap[key] = Object.assign({}, updatedMap[key] || {}, { weight });
        this.mappingMap = updatedMap;

        ctrlSaveMappingWeight({ courseOutcomeId: coId, programOutcomeId: poId, weight })
            .then(mapId => {
                const finalMap = Object.assign({}, this.mappingMap);
                finalMap[key] = { mapId, weight };
                this.mappingMap = finalMap;
                promptSuccess(this.label.SUCCESS_LABEL, 'Mapping weight updated successfully.');
                this.consoleLog({ key, mapId, weight }, true);
            })
            .catch(error => {
                promptError(this.label.ERROR_LABEL, getErrorMessage(error));
            });
    }

    // ─── Private: helpers ─────────────────────────────────────────────────────

    /**
     * @description Returns Course Outcome code, handling both namespaced and non-namespaced orgs.
     *              In a scratch org with namespace 'reduivy', Apex serialises custom fields with
     *              the 'reduivy__' prefix; this tries both to work in all deployment contexts.
     */
    _coCode(co) {
        return co.Course_Outcome_Code__c || co['reduivy__Course_Outcome_Code__c'] || '';
    }

    /**
     * @description Returns Program Outcome code, handling both namespaced and non-namespaced orgs.
     */
    _poCode(po) {
        return po.Program_Outcome_Code__c || po['reduivy__Program_Outcome_Code__c'] || '';
    }

    /**
     * @description Extracts the first integer from a code string for numeric sorting.
     *              e.g. 'CO10' → 10, 'PO2' → 2, null → 0
     */
    _codeNum(code) {
        if (!code) return 0;
        const match = code.match(/\d+/);
        return match ? parseInt(match[0], 10) : 0;
    }

    /**
     * @description Spinner toggler
     */
    toggleSpinner(loadCount) {
        this.loadedLists += loadCount;
        if (this.loadedLists <= 0) {
            this.loadedLists = 0;
        }
    }

    /**
     * @description Console log for debugging
     */
    consoleLog(anything, isJson) {
        logInfo('CoPoMapping', anything, this.enableDebugMode, isJson);
    }
}
