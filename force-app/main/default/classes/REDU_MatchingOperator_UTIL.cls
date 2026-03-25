/**
 * @author      WDCi (XW)
 * @date        Dec 2024
 * @group       Utility
 * @description Utility class to compare two values using a specified operator
 * @changehistory
 * ISS-002155 19-12-2024 XW - new class
 */

@NamespaceAccessible
public inherited sharing class REDU_MatchingOperator_UTIL {
    public static final String MATCHINGOP_EQUALS = SUR_Helper.FIELDMATCHINGOP_EQUALS;
    public static final String MATCHINGOP_DOESNOTEQUAL = SUR_Helper.FIELDMATCHINGOP_DOESNOTEQUAL;
    public static final String MATCHINGOP_GREATER = SUR_Helper.FIELDMATCHINGOP_GREATER;
    public static final String MATCHINGOP_LESS = SUR_Helper.FIELDMATCHINGOP_LESS;
    public static final String MATCHINGOP_GREATEROREQUAL = SUR_Helper.FIELDMATCHINGOP_GREATEROREQUAL;
    public static final String MATCHINGOP_LESSOREQUAL = SUR_Helper.FIELDMATCHINGOP_LESSOREQUAL;
    public static final String MATCHINGOP_ISBLANK = SUR_Helper.FIELDMATCHINGOP_ISBLANK;
    
    private static final String TYPE_BOOLEAN = 'Boolean';
    private static final String TYPE_STRING = 'String';
    private static final String TYPE_NUMBER = 'Number';

    private static final List<Schema.DisplayType> DISPLAY_TYPE_STRING = new List<Schema.DisplayType>{
        Schema.DisplayType.REFERENCE,
        Schema.DisplayType.TEXTAREA,
        Schema.DisplayType.STRING,
        Schema.DisplayType.EMAIL,
        Schema.DisplayType.PHONE,
        Schema.DisplayType.PICKLIST,
        Schema.DisplayType.MULTIPICKLIST,
        Schema.DisplayType.URL,
        Schema.DisplayType.ID
    };
    
    private static final List<Schema.DisplayType> DISPLAY_TYPE_NUMBER = new List<Schema.DisplayType>{
        Schema.DisplayType.LONG,
        Schema.DisplayType.INTEGER,
        Schema.DisplayType.DOUBLE,
        Schema.DisplayType.CURRENCY,
        Schema.DisplayType.PERCENT
    };

    private static final List<String> VALID_OPERATOR_BOOLEAN = new List<String>{
        MATCHINGOP_EQUALS,
        MATCHINGOP_DOESNOTEQUAL
    };

    private static final List<String> VALID_OPERATOR_STRING = new List<String>{
        MATCHINGOP_EQUALS,
        MATCHINGOP_DOESNOTEQUAL,
        MATCHINGOP_ISBLANK
    };

    private static final List<String> VALID_OPERATOR_NUMBER = new List<String>{
        MATCHINGOP_EQUALS,
        MATCHINGOP_DOESNOTEQUAL,
        MATCHINGOP_GREATER,
        MATCHINGOP_LESS,
        MATCHINGOP_GREATEROREQUAL,
        MATCHINGOP_LESSOREQUAL,
        MATCHINGOP_ISBLANK
    };

    
    public static final String INVALID_VALUE_BOOLEAN = 'INVALID_VALUE_BOOLEAN';
    public static final String INVALID_VALUE_NUMBER = 'INVALID_VALUE_NUMBER';
    public static final String INVALID_OPERATOR_BOOLEAN = 'INVALID_OPERATOR_BOOLEAN';
    public static final String INVALID_OPERATOR_STRING = 'INVALID_OPERATOR_STRING';
    public static final String INVALID_FIELD = 'INVALID_FIELD';
    
    
    /**
    * @description calculate the result of the comparison
     * @param  fieldType     Schema.DisplayType
     * @param  actualValue   The actual value
     * @param  operator      The operator to be compared
     * @param  expectedValue The expected value
     * @return               True if statement is correct
     */
    @NamespaceAccessible
    public static Boolean calculate(Schema.DisplayType fieldType, Object actualValue, String operator, String expectedValue) {
        String normalizedType = getNormalizedType(fieldType);
        validateOperator(normalizedType, operator);

        if(expectedValueCanBeEmpty(operator)) {
            expectedValue = '0';
        }
        validateValueType(normalizedType, operator, expectedValue);
        if(normalizedType == TYPE_BOOLEAN) {
            return calculateBoolean(actualValue, operator, expectedValue);
        } else if(normalizedType == TYPE_STRING) {
            return calculateString(actualValue, operator, expectedValue);
        } else if(normalizedType == TYPE_NUMBER) {
            return calculateNumber(fieldType, actualValue, operator, expectedValue);
        }
        return false;
        
    }
    /**
     * @description get either boolean, number or string from the display type
     * @param  fieldType Schema.DisplayType of the field
     * @return           either boolean, number or string
     */
    private static String getNormalizedType(Schema.DisplayType fieldType){
        String result;
        if(fieldType == Schema.DisplayType.BOOLEAN) {
            result = TYPE_BOOLEAN;
        } else if(DISPLAY_TYPE_NUMBER.contains(fieldType)) {
            result = TYPE_NUMBER;
        } else if (DISPLAY_TYPE_STRING.contains(fieldType)) {
            result = TYPE_STRING;
        } else {
            throw new REDU_ApplicationException(INVALID_FIELD);
        }

        return result;
    }

    /**
     * @description validate if the operator is allowed to use for this type
     * @param  normalizedType normalizedType
     * @param  operator         the operator
     */ 
    private static void validateOperator(String normalizedType, String operator) {

        if(normalizedType == TYPE_BOOLEAN) {
            if(!VALID_OPERATOR_BOOLEAN.contains(operator)) {
                throw new REDU_ApplicationException(INVALID_OPERATOR_BOOLEAN);
            }
        } else if (normalizedType == TYPE_STRING) {
            if(!VALID_OPERATOR_STRING.contains(operator)) {
                throw new REDU_ApplicationException(INVALID_OPERATOR_STRING);
            }
        } else if (normalizedType != TYPE_NUMBER) {
            throw new REDU_ApplicationException(INVALID_FIELD);
        }
    }  

    /**
     * @description validateValueType description
     * @param  normalizedType normalizedType description
     * @param  operator       operator description
     * @param  expectedValue  expectedValue description
     */
    private static void validateValueType(String normalizedType, String operator, String expectedValue) {

        if(normalizedType == TYPE_BOOLEAN) {
            if(!expectedValue.equalsIgnoreCase('true') && !expectedValue.equalsIgnoreCase('false') && !expectedValueCanBeEmpty(operator)) {
                throw new REDU_ApplicationException(INVALID_VALUE_BOOLEAN);
            }
        } else if(normalizedType == TYPE_NUMBER) {
            if(!isNumericOrDecimal(expectedValue) && !expectedValueCanBeEmpty(operator)) {
                String errorMsg = String.format(Label.Invalid_Requirement_Matching_Value_Number, new List<String>{''});
                throw new REDU_ApplicationException(INVALID_VALUE_NUMBER);
            }
        }
    }



    /**
     * @description calculate boolean value
     * @param  actualValue   value in Ipe
     * @param  operator      operator selected in field matching operator
     * @param  expectedValue value expected
     * @return               true if condition is met
     */
    private static Boolean calculateBoolean(Object actualValue, String operator, String expectedValue) {

        if(operator == MATCHINGOP_EQUALS) {
            return Boolean.valueOf(actualValue) == Boolean.valueOf(expectedValue.toLowerCase());
        }
        else if(operator == MATCHINGOP_DOESNOTEQUAL) {
            return Boolean.valueOf(actualValue) != Boolean.valueOf(expectedValue.toLowerCase());
        }
        
        return false;
    }

    /**
     * @description calculate string value
     * @param  actualValue   value in Ipe
     * @param  operator      operator selected in field matching operator
     * @param  expectedValue value expected
     * @return               true if condition is met
     */
    private static Boolean calculateString(Object actualValue, String operator, String expectedValue) {
        if(operator == MATCHINGOP_EQUALS) {
            return String.valueOf(actualValue) == expectedValue;
        }
        else if (operator == MATCHINGOP_DOESNOTEQUAL) {
            return String.valueOf(actualValue) != expectedValue;
        }
        else if (operator == MATCHINGOP_ISBLANK) {
            return String.isBlank(String.valueOf(actualValue));
        }
        return false;
    }

    /**
     * @description calculate number value
     * @param  actualValue   value in Ipe
     * @param  operator      operator selected in field matching operator
     * @param  expectedValue value expected
     * @return               true if condition is met
     */
    private static Boolean calculateNumber(Schema.DisplayType fieldType, Object actualValue, String operator, String expectedValue) {
        
        if(fieldType == Schema.DisplayType.LONG) {
            Long actualValueLong = (Long)actualValue;
            Long expectedValueLong = Long.valueOf(expectedValue);
    
            if(operator == MATCHINGOP_EQUALS) {
                return actualValueLong == expectedValueLong;
            }
            else if (operator == MATCHINGOP_DOESNOTEQUAL) {
                return actualValueLong != expectedValueLong;
            }
            else if (operator == MATCHINGOP_GREATER) {
                return actualValueLong > expectedValueLong;
            }
            else if (operator == MATCHINGOP_LESS) {
                return actualValueLong < expectedValueLong;
            }
            else if (operator == MATCHINGOP_GREATEROREQUAL) {
                return actualValueLong >= expectedValueLong;
            }
            else if (operator == MATCHINGOP_LESSOREQUAL) {
                return actualValueLong <= expectedValueLong;
            }
            else if (operator == MATCHINGOP_ISBLANK) {
                return actualValueLong == null;
            }
        }
        else if(fieldType == Schema.DisplayType.DOUBLE) {
            Double actualValueDouble = (Double)actualValue;
            Double expectedValueDouble = Double.valueOf(expectedValue);
    
            if(operator == MATCHINGOP_EQUALS) {
                return actualValueDouble == expectedValueDouble;
            }
            else if (operator == MATCHINGOP_DOESNOTEQUAL) {
                return actualValueDouble != expectedValueDouble;
            }
            else if (operator == MATCHINGOP_GREATER) {
                return actualValueDouble > expectedValueDouble;
            }
            else if (operator == MATCHINGOP_LESS) {
                return actualValueDouble < expectedValueDouble;
            }
            else if (operator == MATCHINGOP_GREATEROREQUAL) {
                return actualValueDouble >= expectedValueDouble;
            }
            else if (operator == MATCHINGOP_LESSOREQUAL) {
                return actualValueDouble <= expectedValueDouble;
            }
            else if (operator == MATCHINGOP_ISBLANK) {
                return actualValueDouble == null;
            }
        }
        else if(fieldType == Schema.DisplayType.CURRENCY || fieldType == Schema.DisplayType.PERCENT) {
            Decimal actualValueDecimal = (Decimal)actualValue;
            Decimal expectedValueDecimal = Decimal.valueOf(expectedValue);
    
            if(operator == MATCHINGOP_EQUALS) {
                return actualValueDecimal == expectedValueDecimal;
            }
            else if (operator == MATCHINGOP_DOESNOTEQUAL) {
                return actualValueDecimal != expectedValueDecimal;
            }
            else if (operator == MATCHINGOP_GREATER) {
                return actualValueDecimal > expectedValueDecimal;
            }
            else if (operator == MATCHINGOP_LESS) {
                return actualValueDecimal < expectedValueDecimal;
            }
            else if (operator == MATCHINGOP_GREATEROREQUAL) {
                return actualValueDecimal >= expectedValueDecimal;
            }
            else if (operator == MATCHINGOP_LESSOREQUAL) {
                return actualValueDecimal <= expectedValueDecimal;
            }
            else if (operator == MATCHINGOP_ISBLANK) {
                return actualValueDecimal == null;
            }
        }
        else if(fieldType == Schema.DisplayType.INTEGER) {
            Integer actualValueInteger = (Integer)actualValue;
            Integer expectedValueInteger = Integer.valueOf(expectedValue);
    
            if(operator == MATCHINGOP_EQUALS) {
                return actualValueInteger == expectedValueInteger;
            }
            else if (operator == MATCHINGOP_DOESNOTEQUAL) {
                return actualValueInteger != expectedValueInteger;
            }
            else if (operator == MATCHINGOP_GREATER) {
                return actualValueInteger > expectedValueInteger;
            }
            else if (operator == MATCHINGOP_LESS) {
                return actualValueInteger < expectedValueInteger;
            }
            else if (operator == MATCHINGOP_GREATEROREQUAL) {
                return actualValueInteger >= expectedValueInteger;
            }
            else if (operator == MATCHINGOP_LESSOREQUAL) {
                return actualValueInteger <= expectedValueInteger;
            }
            else if (operator == MATCHINGOP_ISBLANK) {
                return actualValueInteger == null;
            }
        }
        return false;
        
    }

    /**
     * @description return true if the operator will allow an empty string as expected value (is blank)
     * @param  operator operator selected
     * @return          return true if is blank
     */
    private static Boolean expectedValueCanBeEmpty(String operator) {
        return operator == MATCHINGOP_ISBLANK;
    }


    /**
     * @description return true if the string is a number or a decimal
     * @param  s The numeric string 
     * @return   return true if the string is a number or a decimal
     */
    private static Boolean isNumericOrDecimal(String s){
        // Check if the string is null or empty
        if (String.isEmpty(s)) {
            return false;
        }
        
        String regex = '^-?\\d*\\.?\\d+$';
        // Regular expression to match a valid decimal number
        Boolean isMatch = Pattern.matches(regex, s);
        
        // Check if the string matches the regular expression
        if (isMatch) {
            try {
                // Try to parse the string as a Decimal
                Decimal d = Decimal.valueOf(s);
                return true;
            } catch (Exception e) {
                // Catch any exception that may arise from invalid decimal conversion
                return false;
            }
        } else {
            return false;
        }
    }

    /**
     * @description handle the error message
     * @param  errorType             Message thrown by calculate(), get it from exp.getMessage()
     * @param  errorOperator         the field operator
     * @param  requirementObjApiName The object api name of the requirement, SUR/SPR/IUR
     * @param  customFieldApiName    the custom field api name in reduivy__Field_Name__c
     * @return                       return description
     */
    public static String getErrorMessage(String errorType, String errorOperator, String requirementObjApiName, String customFieldApiName){
        Map<String, String> picklistValueToLabelMap = new Map<String,String>();
        List<Schema.PicklistEntry> operatorList = SUR_Helper.getFieldMatchingOperator();
        for(Schema.PicklistEntry operatorItem : operatorList) {
            picklistValueToLabelMap.put(operatorItem.getValue(), operatorItem.getLabel());
        }
        
        String errorMsg = errorType;
        if(errorType == INVALID_VALUE_BOOLEAN) {
            Schema.DescribeFieldResult fieldNameDescribe = REDU_Metadata_UTIL.describeSObjectField(requirementObjApiName, 'reduivy__Field_Matching_Value__c');
            errorMsg = String.format(Label.Invalid_Requirement_Matching_Value_Boolean, new List<String>{fieldNameDescribe.getLabel()});
        } else if(errorType == INVALID_VALUE_NUMBER) {
            Schema.DescribeFieldResult fieldNameDescribe = REDU_Metadata_UTIL.describeSObjectField(requirementObjApiName, 'reduivy__Field_Matching_Value__c');
            errorMsg = String.format(Label.Invalid_Requirement_Matching_Value_Number, new List<String>{fieldNameDescribe.getLabel()});
        } else if(errorType == INVALID_OPERATOR_BOOLEAN) {
            errorMsg = String.format(Label.Invalid_Requirement_Matching_Operator_Boolean, 
                new List<String>{
                    picklistValueToLabelMap.get(errorOperator), picklistValueToLabelMap.get(MATCHINGOP_EQUALS), 
                    picklistValueToLabelMap.get(MATCHINGOP_DOESNOTEQUAL)
                }
            );
        } else if (errorType == INVALID_OPERATOR_STRING) {
            errorMsg = String.format(Label.Invalid_Requirement_Matching_Operator_String, 
                new List<String>{
                    picklistValueToLabelMap.get(errorOperator), picklistValueToLabelMap.get(MATCHINGOP_EQUALS), 
                    picklistValueToLabelMap.get(MATCHINGOP_DOESNOTEQUAL), picklistValueToLabelMap.get(MATCHINGOP_ISBLANK)
                }
            );
        } else if (errorType == INVALID_FIELD) {
            Schema.DescribeFieldResult customFieldNameDescribe = REDU_Metadata_UTIL.describeSObjectField(IPE_Helper.getApiName(), customFieldApiName);
            errorMsg = String.format(Label.Invalid_Requirement_Field_Type, 
                new List<String>{
                    customFieldNameDescribe.getLabel()
                }
            );
        }
        return errorMsg;
        
    }
}

