import { LightningElement } from 'lwc';

const NEW_GROUP_ACTION = 'new_group';
const NEW_UNIT_ACTION = 'new_unit';
const EDIT_ACTION = 'edit';
const DELETE_ACTION = 'delete';

/**
 * @description Pathway constants
 */
const studyPlanHierarchyConstants = {
    NEW_GROUP_ACTION,
    NEW_UNIT_ACTION,
    EDIT_ACTION,
    DELETE_ACTION
}

export { 
    studyPlanHierarchyConstants
};

export default class StudyPlanHierarchyHelper extends LightningElement {}