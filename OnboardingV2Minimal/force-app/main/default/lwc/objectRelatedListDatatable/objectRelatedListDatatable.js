import LightningDatatable from 'lightning/datatable';
import picklistInlineTemplate from './picklistInlineTemplate.html';
import picklistInlineEditTemplate from './picklistInlineEditTemplate.html';

export default class ObjectRelatedListDatatable extends LightningDatatable {
    static customTypes = {
        picklistInline: {
            template: picklistInlineTemplate,
            editTemplate: picklistInlineEditTemplate,
            standardCellLayout: true,
            typeAttributes: ['options', 'placeholder']
        }
    };
}
