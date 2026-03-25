/**
 * @Author 		WDCi (Lean)
 * @Date 		Sept 2023
 * @group 		Util
 * @Description Custom datatable
 * @changehistory
 */
import LightningDatatable from 'lightning/datatable';
import customHelpTextColTemplate from './customHelpTextCol.html';
import customIconColTemplate from './customIconCol.html';
import customRichTextColTemplate from './customRichTextCol.html';

export default class CustomTypeDatatable extends LightningDatatable {

    static customTypes = {
        customHelpTextCol: {
            template: customHelpTextColTemplate,
            standardCellLayout: true,
            typeAttributes: [
                'content',
                'iconName',
                'iconVariant',
                'visible'
            ]
        },
        customIconCol: {
            template: customIconColTemplate,
            standardCellLayout: false,
            typeAttributes: [
                'iconName',
                'size',
                'variant',
                'visible'
            ]
        },
        customRichTextCol: {
            template: customRichTextColTemplate,
            standardCellLayout: true,
            typeAttributes: [
                'value'
            ]
        }
        // Other types here
    }

}