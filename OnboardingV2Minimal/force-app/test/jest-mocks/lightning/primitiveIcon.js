import { LightningElement, api } from 'lwc';

export default class PrimitiveIcon extends LightningElement {
    @api iconName;
    @api size;
    @api variant;
    @api src;
    @api svgClass;
}
