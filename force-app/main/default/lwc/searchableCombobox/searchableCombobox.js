/**
 * @author      WDCi (Lean)
 * @date        Apr 2024
 * @group       Util
 * @description Searchable combobox
 * @changehistory
 * ISS-001920 23-04-2024 Lean - new component
 * ISS-002188 17-12-2024 XW - added resetToDefault api method
 * ISS-002719 07-11-2025 XW - Filter out the option if isSelectable == false
 */
import {LightningElement, api, track} from "lwc";
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';

import { customLabels } from 'c/labelLoader';

export default class SearchableCombobox extends LightningElement {
	
	//configurable attributes
	@api fieldLabel;
	@api fieldName;
	@api iconName;
	@api required = false;
	@api defaultValue;
	@api messageWhenValueMissing;
	@api helpText;
	@api enableDebugMode = false;

	@track _options;
	@api
	get options() {
		return this._options;
	}

	set options(val) {
		this._options = JSON.parse(JSON.stringify(val));
		this.initPicklistOptions();
	}

	//internal attributes
	showOptions = false;
	highlightedOptionCounter = null;
	hasFirstClicked = false;
	picklistOptions = [];
	selectedValue = "";
	searchValue = "";

	_inputHasFocus = false;
	_cancelBlur = false;

	//labels
	label = customLabels;

	/**
     * @descripton connected callback
     */
	connectedCallback() {
		this.selectedValue = this.defaultValue;
		// this.initPicklistOptions();
	}

	/**
     * @descripton rendered callback
     */
	renderedCallback() {
		this.template.querySelector("[data-focused='true']")?.scrollIntoView();

		//focus the input field when the flag is true
		if (this._inputHasFocus) {
			this.template.querySelector("[name='searchinput']")?.focus();
		}
	}

	/** ISS-002188
	 * @description Reset the selected value to the value given
	 */
	@api changeValue(value){
		this.selectedValue = value;
		this.searchValue = '';
		this.fireChange();
	}

	/**
	 * @description Init the picklist option meta info and add none option if it is required
	 */
	initPicklistOptions() {
		let tempOptions = JSON.parse(JSON.stringify(this._options));

		for (let opt of tempOptions) {
			if (opt.metaInfo) {
				opt.metaInfoStr = opt.metaInfo.join(" • ");
			}
		}

		this.picklistOptions = tempOptions;

		this.consoleLog('initPicklistOptions');
		this.consoleLog(this.picklistOptions, true);
		
	}

	/**
	 * @description Return the label for the selected option
	 */
	get selectedValueLabel() {
		
		return this.selectedOption?.label;
	}

	/**
	 * @description Return the icon for the selected option
	 */
	get selectedValueIconName() {
		
		return (this.selectedOption?.iconName ? this.selectedOption?.iconName : this.iconName);
	}

	/**
	 * @description Return the css class for selected record icon
	 */
	get selectedValueIconCss() {
		
		let cssClass = 'slds-combobox__form-element slds-input-has-icon ';

		if (this.selectedValueIconName) {
			cssClass += ' slds-input-has-icon_left-right';
		} else {
			cssClass += ' slds-input-has-icon_right';
		}

		return cssClass;
	}
	
	/**
	 * @description Return the filtered picklist option
	 */
	get filteredOptions() {
		let options = this.picklistOptions.filter(opt => !Object.hasOwn(opt, 'isSelectable') || (opt.isSelectable === undefined || opt.isSelectable === true));
		if (this.searchValue) {
			options = options.filter((op) => op.label.toLowerCase().includes(this.searchValue.toLowerCase()));
		}
		return this.setOptionsCss(options);
	}

	/**
	 * @description Return true if the required field is not filled
	 */
	get isInvalid() {
		return this.required && this.hasFirstClicked && !this.selectedValue;
	}

	/**
	 * @description Return the css for the main component
	 */
	get searchableComboboxClasses() {
		let css = "searchablecombobox slds-form-element";

		if (this.isInvalid) {
			css += " slds-has-error";
		}

		return css;
	}

	/**
	 * @description Return the combobox container css
	 */
	get comboContainerClasses() {
		let css = "searchablecombobox-container slds-combobox_container";

		if (this.selectedValue) {
			css += " slds-has-selection";
		}

		return css;
	}

	/**
	 * @description Return the combobox inner div css
	 */
	get comboDivClasses() {
		let css = "slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click";

		if (this.showOptions) {
			return css + " slds-is-open";
		}

		return css;
	}

	/**
	 * @description Return the input field css
	 */
	get searchInputClasses() {
		let css = "searchablecombobox-searchinput slds-input slds-combobox__input";

		if (this.showOptions) {
			return css + " slds-has-focus";
		}
		
		return css;
	}

	/**
	 * @description Return the selected option object
	 */
	get selectedOption() {
		let selectedOpt = this.picklistOptions.find(opt => {
			return opt.value === this.selectedValue
		});

		return selectedOpt;
	}

	/**
	 * @description Set the style for combobox dropdown so that the options appear at the correct position and not blocked by modal footer
	 */
	setComboDropdownStyle() {
		let comboDiv = this.refs.combobodydiv;
		let dropdownDiv = this.refs.combodropdowndiv;

		if (comboDiv && dropdownDiv) {
			let rect = comboDiv.getBoundingClientRect();
			let divTop = rect.top + 30;
			let divWidth = rect.width;

			this.consoleLog(divTop);
			this.consoleLog(divWidth);

			dropdownDiv.style.left = 'auto';
			dropdownDiv.style.right = 'auto';
			dropdownDiv.style.top = `${divTop}px`;
			dropdownDiv.style.width = `${divWidth}px`;
			dropdownDiv.style.position = 'fixed';
		}
	}

	/**
	 * @description Handle clear button click
	 */
	handleClearInput() {
		this.selectedValue = "";
		this.searchValue = "";
		
		this.handleFocus();
		this.fireChange();
	}

	/**
	 * @description Handle input field change
	 */
	handleChange(event) {
		this.searchValue = event.target.value;
		this.selectedValue = "";
	}

	/**
	 * @description Handle input field onclick
	 */
	handleInput(event) {
		this.showOptions = true;
	}

	/**
	 * @description Fire onchange event to parent component
	 */
	fireChange() {

		this.dispatchEvent(new CustomEvent("change", {
			detail: {
				selectedOpt: this.selectedOption,
				fieldName: this.fieldName,
				fieldLabel: this.fieldLabel
			}
		}));
	}

	/**
	 * @description Set blur
	 */
	allowBlur() {
		this._cancelBlur = false;
	}

	/**
	 * @description Unset blur
	 */
	cancelBlur() {
		this._cancelBlur = true;
	}

	/**
	 * @description Handle mouse click
	 */
	handleDropdownMouseDown(event) {
		const mainButton = 0;
		if (event.button === mainButton) {
			this.cancelBlur();
		}
	}

	/**
	 * @description Handle mouse click
	 */
	handleDropdownMouseUp() {
		this.allowBlur();
	}

	/**
	 * @description Handle mouse click
	 */
	handleDropdownMouseLeave() {
		if (!this._inputHasFocus) {
			this.showList = false;
		}
	}

	/**
	 * @description Handle input field on blur
	 */
	handleBlur() {
		this._inputHasFocus = false;
		if (this._cancelBlur) {
			return;
		}
		this.showOptions = false;

		this.highlightedOptionCounter = null;
		this.dispatchEvent(new CustomEvent("blur"));
	}

	/**
	 * @description Handle input field on focus
	 */
	handleFocus() {
		this.hasFirstClicked = true;
		this._inputHasFocus = true;
		this.showOptions = true;
		this.highlightedOptionCounter = null;
		this.setComboDropdownStyle();
		this.dispatchEvent(new CustomEvent("focus"));
	}

	/**
	 * @description Handle input field on key press
	 */
	handleKeyDown(event) {
		if (event.key === "Escape") {
			this.showOptions = !this.showOptions;
			this.highlightedOptionCounter = null;

		} else if (event.key === "Enter" && this.showOptions) {
			if (this.highlightedOptionCounter !== null) {
				this.showOptions = false;
				this.allowBlur();
				this.selectedValue = this.filteredOptions[this.highlightedOptionCounter].value;
				this.fireChange();
			}
		} else if (event.key === "Enter") {
			this.handleFocus();
		}

		if (event.key === "ArrowDown" || event.key === "PageDown") {
			this._inputHasFocus = true;
			this.showOptions = true;
			this.highlightedOptionCounter = this.highlightedOptionCounter === null ? 0 : this.highlightedOptionCounter + 1;
		} else if (event.key === "ArrowUp" || event.key === "PageUp") {
			this._inputHasFocus = true;
			this.showOptions = true;
			this.highlightedOptionCounter = this.highlightedOptionCounter === null || this.highlightedOptionCounter === 0 ? this.filteredOptions.length - 1 : this.highlightedOptionCounter - 1;
		}

		if (event.key === "ArrowDown" || event.key === "ArrowUp") {
			this.highlightedOptionCounter = Math.abs(this.highlightedOptionCounter) % this.filteredOptions.length;
		}

		if (event.key === "Home") {
			this.highlightedOptionCounter = 0;
		} else if (event.key === "End") {
			this.highlightedOptionCounter = this.filteredOptions.length - 1;
		}
	}

	/**
	 * @description Handle picklist option on select
	 */
	handleSelect(event) {
		this.showOptions = false;
		this.allowBlur();
		this.selectedValue = event.currentTarget.dataset.value;
		this.fireChange();
	}

	setOptionsCss(options) {
		let classes = "slds-media slds-listbox__option slds-media_center slds-media_small";

		return options.map((option, index) => {
			let cs = classes;
			let focused = "";

			if (option.iconName) {
				cs += " slds-listbox__option_entity slds-listbox__option_has-meta";
			} else {
				cs += " slds-listbox__option_plain ";
			}

			if (index === this.highlightedOptionCounter) {
				cs += " slds-has-focus";
				focused = "true";
			}

			return {classes: cs, focused, ...option};
		});
	}

	/**
     * @descripton Console log for debugging
     */
	consoleLog(anything, isJson){
        logInfo('SearchableCombobox', anything, this.enableDebugMode, isJson);
    }
}