/**
 * @author      WDCi (XW)
 * @date        Nov 2025
 * @group       Label util
 * @description Label
 * @changehistory
 * ISS-002633 20-11-2025 XW - new class
 */

@NamespaceAccessible
public inherited sharing class REDU_Label_UTIL {
    
    @NamespaceAccessible
    public static String getLabelValue(String label) {
        
        if(isLabelFormatted(label)) {
            String labelNameRaw = label.removeStart('{!$Label.').removeEnd('}');
        
            try{
                if(labelNameRaw.contains('__')) {
                    List<String> splitedLabelList = labelNameRaw.split('__');
                    return System.Label.get(splitedLabelList[0], splitedLabelList[1]);
                } else {
                    return System.Label.get('', labelNameRaw);
                }
            } catch (System.InvalidParameterValueException exp) {
                //no label found
                String errorMessage = String.format(System.Label.Invalid_Label, new List<String>{
                    labelNameRaw
                });
                throw new REDU_ApplicationException(errorMessage);
            }
        }
        

        return label;
    }

    @NamespaceAccessible
    public static Boolean isLabelFormatted(String label) {
        return String.isNotBlank(label) && label.trim().startsWith('{!$Label.') && label.trim().endsWith('}');
    }
}
