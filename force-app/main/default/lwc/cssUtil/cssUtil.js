/**
 * @Author 		WDCi (Lean)
 * @Date 		Oct 2023
 * @group 		Util
 * @Description Css utility for lightning web component
 * @changehistory
 * ISS-001752 24-10-2023 Lean - new utility
 * ISS-002014 18-07-2024 Sueanne - check colorHex to ensure it is not empty
 */
import { LightningElement } from 'lwc';

/**
 * @description Shade the hex colour code
 * @param colorHex HTML hex colour code
 * @param percent Percentage for shading
 * @return String
 */
const shadeHexColorCode = (colorHex, percent) => {
    if(colorHex){
        let f=parseInt(colorHex.slice(1),16),t=percent<0?0:255,p=percent<0?percent*-1:percent,R=f>>16,G=f>>8&0x00FF,B=f&0x0000FF;
        return "#"+(0x1000000+(Math.round((t-R)*p)+R)*0x10000+(Math.round((t-G)*p)+G)*0x100+(Math.round((t-B)*p)+B)).toString(16).slice(1);
    }
    return '';
}

export { shadeHexColorCode };

export default class CssUtil extends LightningElement {}