import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getCourseOutcomes from '@salesforce/apex/REDU_CoPoMapping_LCTRL.getCourseOutcomes';
import getProgramOutcomes from '@salesforce/apex/REDU_CoPoMapping_LCTRL.getProgramOutcomes';
import getMappings from '@salesforce/apex/REDU_CoPoMapping_LCTRL.getMappings';
import saveMappingWeight from '@salesforce/apex/REDU_CoPoMapping_LCTRL.saveMappingWeight';

export default class CoPoMapping extends LightningElement {

    /**
     * Automatically provided by the framework when placed on a record page.
     * Used as studyUnitVersionId when the record page object is Study_Unit_Version__c.
     */
    @api recordId;
    @api objectApiName;

    /** Optional override: explicit Study Unit Version Id (App Page / Home Page use) */
    @api studyUnitVersionId;

    /** Optional: filter Program Outcomes by Study Program Version. Leave blank to show all. */
    @api studyProgramVersionId;

    @track courseOutcomes = [];
    @track programOutcomes = [];
    @track mappingMap = {};       // key = 'coId_poId', value = { mapId, weight }
    @track isLoading = true;
    @track errorMessage;

    _coLoaded = false;
    _poLoaded = false;
    _pendingSave = {};            // tracks in-flight saves per cell key

    // ─── Lifecycle: auto-detect Study Unit Version from record page context ───

    connectedCallback() {
        // objectApiName is 'Study_Unit_Version__c' in scratch orgs (no namespace)
        // and 'reduivy__Study_Unit_Version__c' in packaged orgs — endsWith handles both
        if (!this.studyUnitVersionId && this.recordId
                && this.objectApiName && this.objectApiName.endsWith('Study_Unit_Version__c')) {
            this.studyUnitVersionId = this.recordId;
        }
    }

    // ─── Wire: Course Outcomes ───────────────────────────────────────────────

    @wire(getCourseOutcomes, { studyUnitVersionId: '$studyUnitVersionId' })
    wiredCourseOutcomes({ data, error }) {
        if (data) {
            this.courseOutcomes = data;
            this._coLoaded = true;
            this._tryLoadMappings();
        } else if (error) {
            this.errorMessage = this._extractError(error);
            this.isLoading = false;
        }
    }

    // ─── Wire: Program Outcomes ──────────────────────────────────────────────

    @wire(getProgramOutcomes, { studyProgramVersionId: '$studyProgramVersionId' })
    wiredProgramOutcomes({ data, error }) {
        if (data) {
            this.programOutcomes = data;
            this._poLoaded = true;
            this._tryLoadMappings();
        } else if (error) {
            this.errorMessage = this._extractError(error);
            this.isLoading = false;
        }
    }

    // ─── Load Mappings (imperative, runs after both lists are ready) ─────────

    _tryLoadMappings() {
        if (!this._coLoaded || !this._poLoaded) return;

        if (this.courseOutcomes.length === 0 || this.programOutcomes.length === 0) {
            this.isLoading = false;
            return;
        }

        const coIds = this.courseOutcomes.map(co => co.Id);
        const poIds = this.programOutcomes.map(po => po.Id);

        getMappings({ courseOutcomeIds: coIds, programOutcomeIds: poIds })
            .then(mappings => {
                const map = {};
                mappings.forEach(m => {
                    const key = `${m.Course_Outcome__c}_${m.Program_Outcome__c}`;
                    map[key] = { mapId: m.Id, weight: m.Weight__c };
                });
                this.mappingMap = map;
                this.isLoading = false;
            })
            .catch(error => {
                this.errorMessage = this._extractError(error);
                this.isLoading = false;
            });
    }

    // ─── Computed: Matrix rows (COs sorted numerically by code) ─────────────

    get matrixRows() {
        const sortedCos = [...this.courseOutcomes].sort((a, b) =>
            this._codeNum(a.Course_Outcome_Code__c) - this._codeNum(b.Course_Outcome_Code__c)
        );
        const sortedPos = [...this.programOutcomes].sort((a, b) =>
            this._codeNum(a.Program_Outcome_Code__c) - this._codeNum(b.Program_Outcome_Code__c)
        );
        return sortedCos.map(co => {
            const cells = sortedPos.map(po => {
                const key = `${co.Id}_${po.Id}`;
                const existing = this.mappingMap[key];
                return {
                    key,
                    coId: co.Id,
                    poId: po.Id,
                    weight: (existing && existing.weight != null) ? existing.weight : '',
                    mapId: existing ? existing.mapId : null,
                    isSaving: !!this._pendingSave[key]
                };
            });
            return {
                id: co.Id,
                name: co.Name,
                label: co.Course_Outcome_Code__c || co.Name,
                btLevel: co.Blooms_Taxonomy_Level__c || '—',
                cells
            };
        });
    }

    // ─── Computed: PO headers sorted numerically by code ─────────────────────

    get poHeaders() {
        return [...this.programOutcomes]
            .sort((a, b) =>
                this._codeNum(a.Program_Outcome_Code__c) - this._codeNum(b.Program_Outcome_Code__c)
            )
            .map(po => ({
                id: po.Id,
                name: po.Name,
                label: po.Program_Outcome_Code__c || po.Name
            }));
    }

    // ─── Computed: Template conditionals ─────────────────────────────────────

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

    // ─── Event: cell value changed (lightning-input fires event.detail.value) ──

    handleWeightChange(event) {
        const rawVal = event.detail.value;
        const weight = (rawVal === '' || rawVal === null) ? null : parseFloat(rawVal);

        // Skip empty or out-of-range — lightning-input min/max shows the error automatically
        if (rawVal === '' || rawVal === null || isNaN(weight) || weight < 0 || weight > 5) return;

        const target = event.target;
        this._saveWeight(target.dataset.coid, target.dataset.poid, target.dataset.key, weight);
    }

    // ─── Event: remove a PO column from the matrix view ──────────────────────

    handleRemovePo(event) {
        const poId = event.target.dataset.poid;
        this.programOutcomes = this.programOutcomes.filter(po => po.Id !== poId);
    }

    // ─── Event: add a PO — fires a custom event for the parent to handle ─────

    handleAddPo() {
        this.dispatchEvent(new CustomEvent('addprogramoutcome'));
    }

    // ─── Private: call Apex save ──────────────────────────────────────────────

    _saveWeight(coId, poId, key, weight) {
        // Optimistically update local state
        const updatedMap = Object.assign({}, this.mappingMap);
        const existing = updatedMap[key] || {};
        updatedMap[key] = Object.assign({}, existing, { weight });
        this.mappingMap = updatedMap;

        // Mark as in-flight
        this._pendingSave = Object.assign({}, this._pendingSave, { [key]: true });

        saveMappingWeight({ courseOutcomeId: coId, programOutcomeId: poId, weight })
            .then(mapId => {
                const finalMap = Object.assign({}, this.mappingMap);
                finalMap[key] = { mapId, weight };
                this.mappingMap = finalMap;

                this._dispatchToast('success', 'Saved', 'Mapping weight updated successfully.');
            })
            .catch(error => {
                this._dispatchToast('error', 'Save Failed', this._extractError(error));
            })
            .finally(() => {
                const pending = Object.assign({}, this._pendingSave);
                delete pending[key];
                this._pendingSave = pending;
            });
    }

    // ─── Private: helpers ─────────────────────────────────────────────────────

    /**
     * Extracts the first integer found in a code string for numeric sorting.
     * e.g. 'CO10' → 10, 'PO2' → 2, 'BSCO3' → 3, null → 0
     */
    _codeNum(code) {
        if (!code) return 0;
        const match = code.match(/\d+/);
        return match ? parseInt(match[0], 10) : 0;
    }

    _extractError(error) {
        if (!error) return 'An unknown error occurred.';
        if (typeof error === 'string') return error;
        if (error.body) {
            if (error.body.message) return error.body.message;
            if (Array.isArray(error.body) && error.body[0]) return error.body[0].message;
        }
        return error.message || 'An unknown error occurred.';
    }

    _dispatchToast(variant, title, message) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
