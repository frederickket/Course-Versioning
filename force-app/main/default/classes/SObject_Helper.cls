/**
 * @author      WDCi (Lean)
 * @date        July 2023
 * @group       Object Helper
 * @description Interface for object helper class
 * @changehistory
 * 
 */
public interface SObject_Helper {
    
    String getObjectLabel();

    String getObjectPluralLabel();

    String getApiName();

    String getTranslationFieldNameForName();
}