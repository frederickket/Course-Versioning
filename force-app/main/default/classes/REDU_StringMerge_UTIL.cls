/**
 * @author      WDCi (Lean)
 * @date        Sept 2023
 * @group       Util
 * @description String merge utility
 * @changehistory
 * 
 */
@NamespaceAccessible
public inherited sharing class REDU_StringMerge_UTIL {
    
    /**
     * @description Regex syntax to identify merge field using curly bracket e.g., {}
     */
    @NamespaceAccessible
	public static final String MERGEFIELD_SYNTAX_REGEX = '(\\{[^}]*\\})';

    /**
     * @description Regex for open curly bracket
     */
    @NamespaceAccessible
    public static final String MERGEFIELD_PREFIX_REGEX = '\\{';

    /**
     * @description Regex for close curly bracket
     */
    @NamespaceAccessible
    public static final String MERGEFIELD_POSTFIX_REGEX = '\\}';

    /**
     * @description Open curly bracket
     */
    @NamespaceAccessible
    public static final String MERGEFIELD_PREFIX = '{';

    /**
     * @description Close curly bracket
     */
    @NamespaceAccessible
    public static final String MERGEFIELD_POSTFIX = '}';

    /**
     * @description Extract merge fields from the raw string
     * @param fieldPattern System.Pattern
     * @param rawString Raw string
     * @return Map<String, String>
     */
    @NamespaceAccessible
    public static Map<String, String> extractFieldNames(Pattern fieldPattern, String rawString){

        if (fieldPattern == null) {
            fieldPattern = Pattern.compile(MERGEFIELD_SYNTAX_REGEX);
        }

        Map<String, String> fields = new Map<String, String>();
        if(String.isNotBlank(rawString)){
            Matcher matcher = fieldPattern.matcher(rawString);

            while(matcher.find()) {
                
                String mergeFieldSyntax = matcher.group(1);
                String mergeFieldName = mergeFieldSyntax.substringAfterLast(MERGEFIELD_PREFIX).substringBefore(MERGEFIELD_POSTFIX);

                fields.put(mergeFieldSyntax, mergeFieldName);
            }
        }

        return fields;
    }

    /**
     * @description Fill the merge fields defined in the raw string with the actual value
     * @param mergeFieldValues Map of key value pair
     * @param rawString Raw String
     * @return String
     */
    @NamespaceAccessible
    public static String mergeValues(Map<String, String> mergeFieldValues, String rawString){

        if(rawString.contains(MERGEFIELD_PREFIX)){
            
            for(String key : mergeFieldValues.keySet()){

                if(contains(rawString, key)){
                    String mergeValue = mergeFieldValues.get(key);
                    rawString = replaceAll(rawString, key, (String.isNotBlank(mergeValue) ? mergeValue : ''));
                }
            }
        }
        
        return rawString;
    }

    /**
     * @description Format the field with open and close curly bracket in regex syntax
     * @param field fieldA
     * @return String \{fieldA\}
     */
    @NamespaceAccessible
    public static String formatRegex(String field){
        return MERGEFIELD_PREFIX_REGEX + field + MERGEFIELD_POSTFIX_REGEX;
    }

    /**
     * @description Format the field with open and close curly bracket
     * param field fieldA
     * @return String {fieldA}
     */
    @NamespaceAccessible
    public static String format(String field){
        return MERGEFIELD_PREFIX + field + MERGEFIELD_POSTFIX;
    }

    /**
     * @description Check if the rawString contains the mergeField
     * @param rawString
     * @param mergeField
     * @return Boolean
     */
    @NamespaceAccessible
    public static boolean contains(String rawString, String mergeField){
        return rawString.contains( format(mergeField) );
    }

    /**
     * @description Replace the merge field in a rawString with the actual value
     * @param rawString
     * @param mergeField
     * @param mergeValue
     * @return String
     */
    @NamespaceAccessible
    public static String replaceAll(String rawString, String mergeField, String mergeValue){
        return rawString.replaceAll( formatRegex(mergeField), mergeValue);
    }
	
    /**
     * @description Fill the merge fields defined in the raw string with the actual value
     * @param mergeFieldValues Map of key value pair
     * @param rawString Raw String
     * @return String
     */
    @NamespaceAccessible
    public static String mergeValues(SObject sobj, Map<String, String> mergeFields, String rawString, Integer maxLength){

        String mergedString = rawString;

        if(mergedString.contains(MERGEFIELD_PREFIX)){
            
            if (mergeFields == null) {
                Pattern fieldPattern = Pattern.compile(MERGEFIELD_SYNTAX_REGEX);
                mergeFields = extractFieldNames(fieldPattern, rawString);
            }

            for (String mfKey : mergeFields.keySet()){
                String mergeField = mergeFields.get(mfKey);
                String mergeValue = sobj.get(mergeField) == null ? '' : String.valueOf(sobj.get(mergeField));
                mergedString = mergedString.replace(mfKey, mergeValue);
            }

            if (String.isNotBlank(mergedString) && maxLength != null) {
                mergedString = mergedString.left(maxLength);
            }
        }
        
        return mergedString;
    }
}