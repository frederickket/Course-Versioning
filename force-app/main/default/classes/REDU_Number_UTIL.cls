/**
 * @author      WDCi (Lean)
 * @date        Mar 2025
 * @group       Utility
 * @description Number util
 * @changehistory
 * ISS-002323 03-05-2025 Lean - new class
 */
@NamespaceAccessible
public inherited sharing class REDU_Number_UTIL {

    /**
     * @description Set the number of decimal places for a decimal value
     * @param decimalValue
     * @param scale
     * @return Decimal
     */
    public static Decimal setScale(Decimal decimalValue, Integer scale) {

        if (decimalValue != null) {
            return decimalValue.setScale(scale);
        }

        return decimalValue;
    }
}