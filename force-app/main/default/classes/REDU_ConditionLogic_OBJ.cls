/**
 * @author      WDCi (Lean)
 * @date        Oct 2023
 * @group       Utility
 * @description Condition logic utility that validates requirement provided
 * @changehistory
 * ISS-001725 25-10-2023 Lean - new class
 */
public inherited sharing class REDU_ConditionLogic_OBJ {
    
    
	/**
     * @description Logic String
     */
    String ls;
    
    /**
     * @description Boolean Value
     */
    Boolean bv;
    
    /**
     * @description Constructor
     * @param logicString String of criteria logic e.g, 1 OR 2 AND (3 AND 4)
     */
    public REDU_ConditionLogic_OBJ (String logicString) {

        ls = logicString;
        bv = false;

        formatLogic();
    }
    
    /**
     * @description Replace logic word with proper logic syntax, e.g, & = &&, AND = &&.
     * @return void
     */
    private void formatLogic() {

        ls = ls.toUpperCase();
        ls = ls.deleteWhitespace();
        ls = ls.replace('&', '&&');
        ls = ls.replace('AND', '&&');
        ls = ls.replace('|', '||');
        ls = ls.replace('OR', '||');
        ls = ls.replace('NOT', '!');
    }
    
    /**
     * @description Substitute requirement with true/false flag of requirementValue from REDU_ConditionLogic_OBJ.Requirement and validate the final outcome.
     * @param reqList list of REDU_ConditionLogic_OBJ.Requirement
     * @return Boolean
     */
    public Boolean valueOf(List<Requirement> reqList) {

        for (Requirement req : reqList) {
            if (req.requirementID != null) {
                ls = ls.replace(req.requirementID.toUpperCase(), String.valueOf(req.requirementValue));
            }
        }

        bv = evaluateLogic(ls);
        return bv;
    }
    
    /**
     * @description Evaluate the outcome of a logic string, e.g, false && true = false.
     * @param x String of criteria logic
     * @return Boolean
     */
    private Boolean evaluateLogic(String x) {

        x = simplifyLogic(x);
        if (!isSimpleExpressionLogic(x)) {
            if (x.contains('&&'))
                return logicAND(x.substringBefore('&&'), x.substringAfter('&&'));
            if (x.contains('||'))
                return logicOR(x.substringBefore('||'), x.substringAfter('||'));
            if (x.startsWith('!')) 
                return !evaluateLogic(x.substring(1));
            return false;
        }
        return Boolean.valueOf(x);
    }
    
    /**
     * @description Split or chunk complex logic into simple logic. E.g, (true && false) || (true && true) = 1. true && false, 2. true && true.
     * @String x String of criteria logic
     * @return String
     */
    private String simplifyLogic(String x) {

        x = x.trim();
        while (x.contains('(')) {
            String subLogic = x.substringAfterLast('(').substringBefore(')');
            x = x.replace('(' + subLogic + ')', String.valueOf(evaluateLogic(subLogic)));
        }

        return x;
    }
    
    /**
     * @description Validate if string of logic is only true/false.
     * @param x String of logic
     * @return Boolean
     */
    private Boolean isSimpleExpressionLogic(String x) {

        if ((x == 'true') || (x == 'false'))
            return true;
        else
            return false;
    }
    
    /**
     * @description Evaluate outcome between x and y using AND condition.
     * @param x simple string of logic
     * @param y simple string of logic
     * @return Boolean
     */
    private Boolean logicAND(String x, String y) {

        return evaluateLogic(x) && evaluateLogic(y);
    }
    
    /**
     * @description Evaluate outcome between x and y using OR condition.
     * @param x simple string of logic
     * @param y simple string of logic
     * @return Boolean
     */
    private Boolean logicOR(String x, String y) {

        return evaluateLogic(x) || evaluateLogic(y);
    }

    public class Requirement {

        public String requirementID {set; get;}
        public Boolean requirementValue {set; get;}

        public Requirement(String requirementID, Boolean requirementValue) {
            this.requirementID = requirementID;
            this.requirementValue = requirementValue;
        }
    }
}