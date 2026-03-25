/**
 * @author      WDCi (XW)
 * @date        Dec 2024
 * @group       Test
 * @description Test class for REDU_MatchingOperator_UTIL
 * @changehistory
 * ISS-002155 20-12-2024 XW - create new test class
 */
@IsTest
public inherited sharing class REDU_MatchingOperator_TEST {

    public static final String MATCHINGOP_EQUALS = REDU_MatchingOperator_UTIL.MATCHINGOP_EQUALS;
    public static final String MATCHINGOP_DOESNOTEQUAL = REDU_MatchingOperator_UTIL.MATCHINGOP_DOESNOTEQUAL;
    public static final String MATCHINGOP_GREATER = REDU_MatchingOperator_UTIL.MATCHINGOP_GREATER;
    public static final String MATCHINGOP_LESS = REDU_MatchingOperator_UTIL.MATCHINGOP_LESS;
    public static final String MATCHINGOP_GREATEROREQUAL = REDU_MatchingOperator_UTIL.MATCHINGOP_GREATEROREQUAL;
    public static final String MATCHINGOP_LESSOREQUAL = REDU_MatchingOperator_UTIL.MATCHINGOP_LESSOREQUAL;
    public static final String MATCHINGOP_ISBLANK = REDU_MatchingOperator_UTIL.MATCHINGOP_ISBLANK;
 
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    /**
     * @description Test for display type = boolean (valid)
     */
    @IsTest
    static void testForValidBoolean() {

        Boolean resultTrueEqTrue = REDU_MatchingOperator_UTIL.calculate(Schema.DisplayType.BOOLEAN, true, MATCHINGOP_EQUALS, 'true');
        System.Assert.isTrue(resultTrueEqTrue, 'Wrong result for true = true, Expected: true, Actual: ' + resultTrueEqTrue);
        Boolean resultTrueEqFalse = REDU_MatchingOperator_UTIL.calculate(Schema.DisplayType.BOOLEAN, true, MATCHINGOP_EQUALS, 'false');
        System.Assert.isFalse(resultTrueEqFalse, 'Wrong result for true = FALSE, Expected: false, Actual: ' + resultTrueEqFalse);

        Boolean resultTrueNeqTrue = REDU_MatchingOperator_UTIL.calculate(Schema.DisplayType.BOOLEAN, true, MATCHINGOP_DOESNOTEQUAL, 'TRUE');
        System.Assert.isFalse(resultTrueNeqTrue, 'Wrong result for true != true, Expected: false, Actual: ' + resultTrueNeqTrue);
        Boolean resultTrueNeqFalse = REDU_MatchingOperator_UTIL.calculate(Schema.DisplayType.BOOLEAN, true, MATCHINGOP_DOESNOTEQUAL, 'FALSE');
        System.Assert.isTrue(resultTrueNeqFalse, 'Wrong result for true != FALSE, Expected: true, Actual: ' + resultTrueNeqFalse);

        Boolean resultFalseEqTrue = REDU_MatchingOperator_UTIL.calculate(Schema.DisplayType.BOOLEAN, false, MATCHINGOP_EQUALS, 'true');
        System.Assert.isFalse(resultFalseEqTrue, 'Wrong result for false = true, Expected: false, Actual: ' + resultFalseEqTrue);
        Boolean resultFalseEqFalse = REDU_MatchingOperator_UTIL.calculate(Schema.DisplayType.BOOLEAN, false, MATCHINGOP_EQUALS, 'false');
        System.Assert.isTrue(resultFalseEqFalse, 'Wrong result for false = FALSE, Expected: true, Actual: ' + resultFalseEqFalse);

        Boolean resultFalseNeqTrue = REDU_MatchingOperator_UTIL.calculate(Schema.DisplayType.BOOLEAN, false, MATCHINGOP_DOESNOTEQUAL, 'TRUE');
        System.Assert.isTrue(resultFalseNeqTrue, 'Wrong result for false != true, Expected: true, Actual: ' + resultFalseNeqTrue);
        Boolean resultFalseNeqFalse = REDU_MatchingOperator_UTIL.calculate(Schema.DisplayType.BOOLEAN, false, MATCHINGOP_DOESNOTEQUAL, 'FALSE');
        System.Assert.isFalse(resultFalseNeqFalse, 'Wrong result for false != FALSE, Expected: false, Actual: ' + resultFalseNeqFalse);
    }

    /**
     * @description Test for display type = long (valid)
     */
    @IsTest
    static void testForValidNumberLong() {

        Schema.DisplayType targetDisplayType = Schema.DisplayType.LONG;
        Long value100 = 100;
        Long valueBlank = null;

        //Equals =
        Boolean result100Eq100 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_EQUALS, '100');
        System.Assert.isTrue(result100Eq100, 'Wrong result for 100 = 100, Expected: true, Actual: ' + result100Eq100);
        Boolean result100Eq101 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_EQUALS, '101');
        System.Assert.isFalse(result100Eq101, 'Wrong result for 100 != 100, Expected: false, Actual: ' + result100Eq101);

        //Not equals !=
        Boolean result100Neq101 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_DOESNOTEQUAL, '101');
        System.Assert.isTrue(result100Neq101, 'Wrong result for 100 != 101, Expected: true, Actual: ' + result100Neq101);
        Boolean result100Neq100 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_DOESNOTEQUAL, '100');
        System.Assert.isFalse(result100Neq100, 'Wrong result for 100 = 101, Expected: false, Actual: ' + result100Neq100);

        //Greater >
        Boolean result100Gt99 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_GREATER, '99');
        System.Assert.isTrue(result100Gt99, 'Wrong result for 100 > 99, Expected: true, Actual: ' + result100Gt99);
        Boolean result100Gt100 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_GREATER, '100');
        System.Assert.isFalse(result100Gt100, 'Wrong result for 100 > 100, Expected: false, Actual: ' + result100Gt100);
        Boolean result100Gt101 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_GREATER, '101');
        System.Assert.isFalse(result100Gt101, 'Wrong result for 100 > 101, Expected: false, Actual: ' + result100Gt101);

        //Less <
        Boolean result100Lt99 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_LESS, '99');
        System.Assert.isFalse(result100Lt99, 'Wrong result for 100 < 99, Expected: false, Actual: ' + result100Lt99);
        Boolean result100Lt100 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_LESS, '100');
        System.Assert.isFalse(result100Lt100, 'Wrong result for 100 < 100, Expected: false, Actual: ' + result100Lt100);
        Boolean result100Lt101 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_LESS, '101');
        System.Assert.isTrue(result100Lt101, 'Wrong result for 100 < 101, Expected: true, Actual: ' + result100Lt101);
        
        //Greater or equal >=
        Boolean result100Gteq99 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_GREATEROREQUAL, '99');
        System.Assert.isTrue(result100Gteq99, 'Wrong result for 100 >= 99, Expected: true, Actual: ' + result100Gteq99);
        Boolean result100Gteq100 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_GREATEROREQUAL, '100');
        System.Assert.isTrue(result100Gteq100, 'Wrong result for 100 >= 100, Expected: true, Actual: ' + result100Gteq100);
        Boolean result100Gteq101 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_GREATEROREQUAL, '101');
        System.Assert.isFalse(result100Gteq101, 'Wrong result for 100 >= 101, Expected: false, Actual: ' + result100Gteq101);

        //Less or equal <=
        Boolean result100Lteq99 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_LESSOREQUAL, '99');
        System.Assert.isFalse(result100Lteq99, 'Wrong result for 100 <= 99, Expected: false, Actual: ' + result100Lteq99);
        Boolean result100Lteq100 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_LESSOREQUAL, '100');
        System.Assert.isTrue(result100Lteq100, 'Wrong result for 100 <= 100, Expected: true, Actual: ' + result100Lteq100);
        Boolean result100Lteq101 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_LESSOREQUAL, '101');
        System.Assert.isTrue(result100Lteq101, 'Wrong result for 100 <= 101, Expected: true, Actual: ' + result100Lteq101);

        //Is blank
        Boolean resultBlankisBlank = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, valueBlank, MATCHINGOP_ISBLANK, '');
        System.Assert.isTrue(resultBlankisBlank, 'Wrong result for blank is blank, Expected: true, Actual: ' + resultBlankisBlank);
        Boolean result100isBlank = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_ISBLANK, '');
        System.Assert.isFalse(result100isBlank, 'Wrong result for 100 is blank, Expected: false, Actual: ' + result100isBlank);
    }

    
    /**
     * @description Test for display type = integer (valid)
     */
    @IsTest
    static void testForValidNumberInteger() {

        Schema.DisplayType targetDisplayType = Schema.DisplayType.INTEGER;
        Integer value100 = 100;
        Integer valueBlank = null;

        //Equals =
        Boolean result100Eq100 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_EQUALS, '100');
        System.Assert.isTrue(result100Eq100, 'Wrong result for 100 = 100, Expected: true, Actual: ' + result100Eq100);
        Boolean result100Eq101 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_EQUALS, '101');
        System.Assert.isFalse(result100Eq101, 'Wrong result for 100 != 100, Expected: false, Actual: ' + result100Eq101);

        //Not equals !=
        Boolean result100Neq101 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_DOESNOTEQUAL, '101');
        System.Assert.isTrue(result100Neq101, 'Wrong result for 100 != 101, Expected: true, Actual: ' + result100Neq101);
        Boolean result100Neq100 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_DOESNOTEQUAL, '100');
        System.Assert.isFalse(result100Neq100, 'Wrong result for 100 = 101, Expected: false, Actual: ' + result100Neq100);

        //Greater >
        Boolean result100Gt99 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_GREATER, '99');
        System.Assert.isTrue(result100Gt99, 'Wrong result for 100 > 99, Expected: true, Actual: ' + result100Gt99);
        Boolean result100Gt100 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_GREATER, '100');
        System.Assert.isFalse(result100Gt100, 'Wrong result for 100 > 100, Expected: false, Actual: ' + result100Gt100);
        Boolean result100Gt101 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_GREATER, '101');
        System.Assert.isFalse(result100Gt101, 'Wrong result for 100 > 101, Expected: false, Actual: ' + result100Gt101);

        //Less <
        Boolean result100Lt99 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_LESS, '99');
        System.Assert.isFalse(result100Lt99, 'Wrong result for 100 < 99, Expected: false, Actual: ' + result100Lt99);
        Boolean result100Lt100 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_LESS, '100');
        System.Assert.isFalse(result100Lt100, 'Wrong result for 100 < 100, Expected: false, Actual: ' + result100Lt100);
        Boolean result100Lt101 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_LESS, '101');
        System.Assert.isTrue(result100Lt101, 'Wrong result for 100 < 101, Expected: true, Actual: ' + result100Lt101);
        
        //Greater or equal >=
        Boolean result100Gteq99 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_GREATEROREQUAL, '99');
        System.Assert.isTrue(result100Gteq99, 'Wrong result for 100 >= 99, Expected: true, Actual: ' + result100Gteq99);
        Boolean result100Gteq100 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_GREATEROREQUAL, '100');
        System.Assert.isTrue(result100Gteq100, 'Wrong result for 100 >= 100, Expected: true, Actual: ' + result100Gteq100);
        Boolean result100Gteq101 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_GREATEROREQUAL, '101');
        System.Assert.isFalse(result100Gteq101, 'Wrong result for 100 >= 101, Expected: false, Actual: ' + result100Gteq101);

        //Less or equal <=
        Boolean result100Lteq99 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_LESSOREQUAL, '99');
        System.Assert.isFalse(result100Lteq99, 'Wrong result for 100 <= 99, Expected: false, Actual: ' + result100Lteq99);
        Boolean result100Lteq100 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_LESSOREQUAL, '100');
        System.Assert.isTrue(result100Lteq100, 'Wrong result for 100 <= 100, Expected: true, Actual: ' + result100Lteq100);
        Boolean result100Lteq101 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_LESSOREQUAL, '101');
        System.Assert.isTrue(result100Lteq101, 'Wrong result for 100 <= 101, Expected: true, Actual: ' + result100Lteq101);

        //Is blank
        Boolean resultBlankisBlank = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, valueBlank, MATCHINGOP_ISBLANK, '');
        System.Assert.isTrue(resultBlankisBlank, 'Wrong result for blank is blank, Expected: true, Actual: ' + resultBlankisBlank);
        Boolean result100isBlank = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_ISBLANK, '');
        System.Assert.isFalse(result100isBlank, 'Wrong result for 100 is blank, Expected: false, Actual: ' + result100isBlank);
    }
    
    /**
     * @description Test for display type = double (valid)
     */
    @IsTest
    static void testForValidNumberDouble() {

        Schema.DisplayType targetDisplayType = Schema.DisplayType.DOUBLE;
        Double value100 = 100;
        Double value100_1 = 100.1;
        Double valueBlank = null;

        //Equals =
        Boolean result100Eq100 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_EQUALS, '100');
        System.Assert.isTrue(result100Eq100, 'Wrong result for 100 = 100, Expected: true, Actual: ' + result100Eq100);
        Boolean result100Eq101 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_EQUALS, '101');
        System.Assert.isFalse(result100Eq101, 'Wrong result for 100 != 100, Expected: false, Actual: ' + result100Eq101);
        Boolean result100_1Eq100_1 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100_1, MATCHINGOP_EQUALS, '100.1');
        System.Assert.isTrue(result100_1Eq100_1, 'Wrong result for 100.1 = 100.1, Expected: true, Actual: ' + result100_1Eq100_1);
        Boolean result100_1Eq101_1 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100_1, MATCHINGOP_EQUALS, '101.1');
        System.Assert.isFalse(result100_1Eq101_1, 'Wrong result for 100.1 != 100.1, Expected: false, Actual: ' + result100_1Eq101_1);

        //Not equals !=
        Boolean result100Neq101 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_DOESNOTEQUAL, '101');
        System.Assert.isTrue(result100Neq101, 'Wrong result for 100 != 101, Expected: true, Actual: ' + result100Neq101);
        Boolean result100Neq100 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_DOESNOTEQUAL, '100');
        System.Assert.isFalse(result100Neq100, 'Wrong result for 100 = 101, Expected: false, Actual: ' + result100Neq100);
        Boolean result100_1Neq101_1 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100_1, MATCHINGOP_DOESNOTEQUAL, '101.1');
        System.Assert.isTrue(result100_1Neq101_1, 'Wrong result for 100.1 = 100.1, Expected: true, Actual: ' + result100_1Neq101_1);
        Boolean result100_1Neq100_1 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100_1, MATCHINGOP_DOESNOTEQUAL, '100.1');
        System.Assert.isFalse(result100_1Neq100_1, 'Wrong result for 100.1 != 100.1, Expected: false, Actual: ' + result100_1Neq100_1);

        //Greater >
        Boolean result100Gt99 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_GREATER, '99');
        System.Assert.isTrue(result100Gt99, 'Wrong result for 100 > 99, Expected: true, Actual: ' + result100Gt99);
        Boolean result100Gt100 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_GREATER, '100');
        System.Assert.isFalse(result100Gt100, 'Wrong result for 100 > 100, Expected: false, Actual: ' + result100Gt100);
        Boolean result100Gt101 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_GREATER, '101');
        System.Assert.isFalse(result100Gt101, 'Wrong result for 100 > 101, Expected: false, Actual: ' + result100Gt101);
        Boolean result100_1Gt99_1 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100_1, MATCHINGOP_GREATER, '99.1');
        System.Assert.isTrue(result100_1Gt99_1, 'Wrong result for 100.1 > 99.1, Expected: true, Actual: ' + result100Gt99);
        Boolean result100_1Gt100_1 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100_1, MATCHINGOP_GREATER, '100.1');
        System.Assert.isFalse(result100_1Gt100_1, 'Wrong result for 100.1 > 100.1, Expected: false, Actual: ' + result100_1Gt100_1);
        Boolean result100_1Gt101_1 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100_1, MATCHINGOP_GREATER, '101.1');
        System.Assert.isFalse(result100_1Gt101_1, 'Wrong result for 100.1 > 101.1, Expected: false, Actual: ' + result100_1Gt101_1);

        //Less <
        Boolean result100Lt99 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_LESS, '99');
        System.Assert.isFalse(result100Lt99, 'Wrong result for 100 < 99, Expected: false, Actual: ' + result100Lt99);
        Boolean result100Lt100 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_LESS, '100');
        System.Assert.isFalse(result100Lt100, 'Wrong result for 100 < 100, Expected: false, Actual: ' + result100Lt100);
        Boolean result100Lt101 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_LESS, '101');
        System.Assert.isTrue(result100Lt101, 'Wrong result for 100 < 101, Expected: true, Actual: ' + result100Lt101);
        Boolean result100_1Lt99_1 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100_1, MATCHINGOP_LESS, '99.1');
        System.Assert.isFalse(result100_1Lt99_1, 'Wrong result for 100.1 < 99.1, Expected: false, Actual: ' + result100_1Lt99_1);
        Boolean result100_1Lt100_1 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100_1, MATCHINGOP_LESS, '100.1');
        System.Assert.isFalse(result100_1Lt100_1, 'Wrong result for 100.1 < 100.1, Expected: false, Actual: ' + result100_1Lt100_1);
        Boolean result100_1Lt101_1 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100_1, MATCHINGOP_LESS, '101.1');
        System.Assert.isTrue(result100_1Lt101_1, 'Wrong result for 100.1 < 101.1, Expected: true, Actual: ' + result100_1Lt101_1);
        
        //Greater or equal >=
        Boolean result100Gteq99 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_GREATEROREQUAL, '99');
        System.Assert.isTrue(result100Gteq99, 'Wrong result for 100 >= 99, Expected: true, Actual: ' + result100Gteq99);
        Boolean result100Gteq100 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_GREATEROREQUAL, '100');
        System.Assert.isTrue(result100Gteq100, 'Wrong result for 100 >= 100, Expected: true, Actual: ' + result100Gteq100);
        Boolean result100Gteq101 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_GREATEROREQUAL, '101');
        System.Assert.isFalse(result100Gteq101, 'Wrong result for 100 >= 101, Expected: false, Actual: ' + result100Gteq101);
        Boolean result100_1Gteq99_1 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100_1, MATCHINGOP_GREATEROREQUAL, '99.1');
        System.Assert.isTrue(result100_1Gteq99_1, 'Wrong result for 100.1 >= 99.1, Expected: true, Actual: ' + result100_1Gteq99_1);
        Boolean result100_1Gteq100_1 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100_1, MATCHINGOP_GREATEROREQUAL, '100.1');
        System.Assert.isTrue(result100_1Gteq100_1, 'Wrong result for 100.1 >= 100.1, Expected: true, Actual: ' + result100_1Gteq100_1);
        Boolean result100_1Gteq101_1 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100_1, MATCHINGOP_GREATEROREQUAL, '101.1');
        System.Assert.isFalse(result100_1Gteq101_1, 'Wrong result for 100.1 >= 101.1, Expected: false, Actual: ' + result100_1Gteq101_1);

        //Less or equal <=
        Boolean result100Lteq99 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_LESSOREQUAL, '99');
        System.Assert.isFalse(result100Lteq99, 'Wrong result for 100 <= 99, Expected: false, Actual: ' + result100Lteq99);
        Boolean result100Lteq100 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_LESSOREQUAL, '100');
        System.Assert.isTrue(result100Lteq100, 'Wrong result for 100 <= 100, Expected: true, Actual: ' + result100Lteq100);
        Boolean result100Lteq101 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_LESSOREQUAL, '101');
        System.Assert.isTrue(result100Lteq101, 'Wrong result for 100 <= 101, Expected: true, Actual: ' + result100Lteq101);
        Boolean result100_1Lteq99_1 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100_1, MATCHINGOP_LESSOREQUAL, '99.1');
        System.Assert.isFalse(result100_1Lteq99_1, 'Wrong result for 100.1 <= 99.1, Expected: false, Actual: ' + result100_1Lteq99_1);
        Boolean result100_1Lteq100_1 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100_1, MATCHINGOP_LESSOREQUAL, '100.1');
        System.Assert.isTrue(result100_1Lteq100_1, 'Wrong result for 100.1 <= 100.1, Expected: true, Actual: ' + result100_1Lteq100_1);
        Boolean result100_1Lteq101_1 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100_1, MATCHINGOP_LESSOREQUAL, '101.1');
        System.Assert.isTrue(result100_1Lteq101_1, 'Wrong result for 100.1 <= 101.1, Expected: true, Actual: ' + result100_1Lteq101_1);

        //Is blank
        Boolean resultBlankisBlank = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, valueBlank, MATCHINGOP_ISBLANK, '');
        System.Assert.isTrue(resultBlankisBlank, 'Wrong result for blank is blank, Expected: true, Actual: ' + resultBlankisBlank);
        Boolean result100isBlank = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_ISBLANK, '');
        System.Assert.isFalse(result100isBlank, 'Wrong result for 100 is blank, Expected: false, Actual: ' + result100isBlank);
    }    

    /**
     * @description Test for display type = Currency (valid)
     */
    @IsTest
    static void testForValidNumberCurrency() {

        Schema.DisplayType targetDisplayType = Schema.DisplayType.CURRENCY;
        Double value100 = 100;
        Double valueBlank = null;

        //Equals =
        Boolean result100Eq100 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_EQUALS, '100');
        System.Assert.isTrue(result100Eq100, 'Wrong result for 100 = 100, Expected: true, Actual: ' + result100Eq100);
        Boolean result100Eq101 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_EQUALS, '101');
        System.Assert.isFalse(result100Eq101, 'Wrong result for 100 != 100, Expected: false, Actual: ' + result100Eq101);

        //Not equals !=
        Boolean result100Neq101 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_DOESNOTEQUAL, '101');
        System.Assert.isTrue(result100Neq101, 'Wrong result for 100 != 101, Expected: true, Actual: ' + result100Neq101);
        Boolean result100Neq100 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_DOESNOTEQUAL, '100');
        System.Assert.isFalse(result100Neq100, 'Wrong result for 100 = 101, Expected: false, Actual: ' + result100Neq100);

        //Greater >
        Boolean result100Gt99 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_GREATER, '99');
        System.Assert.isTrue(result100Gt99, 'Wrong result for 100 > 99, Expected: true, Actual: ' + result100Gt99);
        Boolean result100Gt100 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_GREATER, '100');
        System.Assert.isFalse(result100Gt100, 'Wrong result for 100 > 100, Expected: false, Actual: ' + result100Gt100);
        Boolean result100Gt101 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_GREATER, '101');
        System.Assert.isFalse(result100Gt101, 'Wrong result for 100 > 101, Expected: false, Actual: ' + result100Gt101);

        //Less <
        Boolean result100Lt99 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_LESS, '99');
        System.Assert.isFalse(result100Lt99, 'Wrong result for 100 < 99, Expected: false, Actual: ' + result100Lt99);
        Boolean result100Lt100 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_LESS, '100');
        System.Assert.isFalse(result100Lt100, 'Wrong result for 100 < 100, Expected: false, Actual: ' + result100Lt100);
        Boolean result100Lt101 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_LESS, '101');
        System.Assert.isTrue(result100Lt101, 'Wrong result for 100 < 101, Expected: true, Actual: ' + result100Lt101);
        
        //Greater or equal >=
        Boolean result100Gteq99 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_GREATEROREQUAL, '99');
        System.Assert.isTrue(result100Gteq99, 'Wrong result for 100 >= 99, Expected: true, Actual: ' + result100Gteq99);
        Boolean result100Gteq100 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_GREATEROREQUAL, '100');
        System.Assert.isTrue(result100Gteq100, 'Wrong result for 100 >= 100, Expected: true, Actual: ' + result100Gteq100);
        Boolean result100Gteq101 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_GREATEROREQUAL, '101');
        System.Assert.isFalse(result100Gteq101, 'Wrong result for 100 >= 101, Expected: false, Actual: ' + result100Gteq101);

        //Less or equal <=
        Boolean result100Lteq99 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_LESSOREQUAL, '99');
        System.Assert.isFalse(result100Lteq99, 'Wrong result for 100 <= 99, Expected: false, Actual: ' + result100Lteq99);
        Boolean result100Lteq100 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_LESSOREQUAL, '100');
        System.Assert.isTrue(result100Lteq100, 'Wrong result for 100 <= 100, Expected: true, Actual: ' + result100Lteq100);
        Boolean result100Lteq101 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_LESSOREQUAL, '101');
        System.Assert.isTrue(result100Lteq101, 'Wrong result for 100 <= 101, Expected: true, Actual: ' + result100Lteq101);

        //Is blank
        Boolean resultBlankisBlank = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, valueBlank, MATCHINGOP_ISBLANK, '');
        System.Assert.isTrue(resultBlankisBlank, 'Wrong result for blank is blank, Expected: true, Actual: ' + resultBlankisBlank);
        Boolean result100isBlank = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_ISBLANK, '');
        System.Assert.isFalse(result100isBlank, 'Wrong result for 100 is blank, Expected: false, Actual: ' + result100isBlank);
    }

    
    /**
     * @description Test for display type = Percent (valid)
     */
    @IsTest
    static void testForValidNumberPercent() {

        Schema.DisplayType targetDisplayType = Schema.DisplayType.PERCENT;
        Double value100 = 100;
        Double valueBlank = null;

        //Equals =
        Boolean result100Eq100 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_EQUALS, '100');
        System.Assert.isTrue(result100Eq100, 'Wrong result for 100 = 100, Expected: true, Actual: ' + result100Eq100);
        Boolean result100Eq101 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_EQUALS, '101');
        System.Assert.isFalse(result100Eq101, 'Wrong result for 100 != 100, Expected: false, Actual: ' + result100Eq101);

        //Not equals !=
        Boolean result100Neq101 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_DOESNOTEQUAL, '101');
        System.Assert.isTrue(result100Neq101, 'Wrong result for 100 != 101, Expected: true, Actual: ' + result100Neq101);
        Boolean result100Neq100 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_DOESNOTEQUAL, '100');
        System.Assert.isFalse(result100Neq100, 'Wrong result for 100 = 101, Expected: false, Actual: ' + result100Neq100);

        //Greater >
        Boolean result100Gt99 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_GREATER, '99');
        System.Assert.isTrue(result100Gt99, 'Wrong result for 100 > 99, Expected: true, Actual: ' + result100Gt99);
        Boolean result100Gt100 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_GREATER, '100');
        System.Assert.isFalse(result100Gt100, 'Wrong result for 100 > 100, Expected: false, Actual: ' + result100Gt100);
        Boolean result100Gt101 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_GREATER, '101');
        System.Assert.isFalse(result100Gt101, 'Wrong result for 100 > 101, Expected: false, Actual: ' + result100Gt101);

        //Less <
        Boolean result100Lt99 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_LESS, '99');
        System.Assert.isFalse(result100Lt99, 'Wrong result for 100 < 99, Expected: false, Actual: ' + result100Lt99);
        Boolean result100Lt100 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_LESS, '100');
        System.Assert.isFalse(result100Lt100, 'Wrong result for 100 < 100, Expected: false, Actual: ' + result100Lt100);
        Boolean result100Lt101 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_LESS, '101');
        System.Assert.isTrue(result100Lt101, 'Wrong result for 100 < 101, Expected: true, Actual: ' + result100Lt101);
        
        //Greater or equal >=
        Boolean result100Gteq99 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_GREATEROREQUAL, '99');
        System.Assert.isTrue(result100Gteq99, 'Wrong result for 100 >= 99, Expected: true, Actual: ' + result100Gteq99);
        Boolean result100Gteq100 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_GREATEROREQUAL, '100');
        System.Assert.isTrue(result100Gteq100, 'Wrong result for 100 >= 100, Expected: true, Actual: ' + result100Gteq100);
        Boolean result100Gteq101 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_GREATEROREQUAL, '101');
        System.Assert.isFalse(result100Gteq101, 'Wrong result for 100 >= 101, Expected: false, Actual: ' + result100Gteq101);

        //Less or equal <=
        Boolean result100Lteq99 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_LESSOREQUAL, '99');
        System.Assert.isFalse(result100Lteq99, 'Wrong result for 100 <= 99, Expected: false, Actual: ' + result100Lteq99);
        Boolean result100Lteq100 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_LESSOREQUAL, '100');
        System.Assert.isTrue(result100Lteq100, 'Wrong result for 100 <= 100, Expected: true, Actual: ' + result100Lteq100);
        Boolean result100Lteq101 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_LESSOREQUAL, '101');
        System.Assert.isTrue(result100Lteq101, 'Wrong result for 100 <= 101, Expected: true, Actual: ' + result100Lteq101);

        //Is blank
        Boolean resultBlankisBlank = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, valueBlank, MATCHINGOP_ISBLANK, '');
        System.Assert.isTrue(resultBlankisBlank, 'Wrong result for blank is blank, Expected: true, Actual: ' + resultBlankisBlank);
        Boolean result100isBlank = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, value100, MATCHINGOP_ISBLANK, '');
        System.Assert.isFalse(result100isBlank, 'Wrong result for 100 is blank, Expected: false, Actual: ' + result100isBlank);
    }

      
    /**
     * @description Test for display type = reference (valid)
     */  
    @IsTest
    static void testForValidStringReference() {
        Test.startTest();

        Account edu1 = new Account(RecordTypeId = ACC_Helper.getEducationalInstitutionRecordTypeId(), Name = 'EduInst 1');
        Account eduA = new Account(RecordTypeId = ACC_Helper.getEducationalInstitutionRecordTypeId(), Name = 'EduInst A');
        List<Account> eduList = new List<Account>{edu1, eduA};
        insert eduList;

        Account campus1 = REDU_TestData_UTIL.newCampus('Campus 1', edu1.Id, 'Campus 1', 'Campus 1', 'Australia/Sydney');
        Account campus2 = REDU_TestData_UTIL.newCampus('Campus 2', edu1.Id, 'Campus 2', 'Campus 2', 'Australia/Sydney');
        Account campusA = REDU_TestData_UTIL.newCampus('Campus A', eduA.Id, 'Campus A', 'Campus A', 'Australia/Sydney');
        Account campusB = REDU_TestData_UTIL.newCampus('Campus B', eduA.Id, 'Campus B', 'Campus B', 'Australia/Sydney');
        Account campus = REDU_TestData_UTIL.newCampus('Campus', null, 'Campus', 'Campus', 'Australia/Sydney');

        List<Account> campusList = new List<Account>{campus1, campus2, campusA, campusB, campus};
        insert campusList;

        //Equals =
        Boolean resultCampus1parentEqEdu1 = REDU_MatchingOperator_UTIL.calculate(Schema.DisplayType.REFERENCE, campus1.ParentId, MATCHINGOP_EQUALS, edu1.Id);
        System.Assert.isTrue(resultCampus1parentEqEdu1, 'Wrong result for campus1parent is edu1, Expected: true, Actual: ' + resultCampus1parentEqEdu1);
        Boolean resultCampusAparentEqEdu1 = REDU_MatchingOperator_UTIL.calculate(Schema.DisplayType.REFERENCE, campusA.ParentId, MATCHINGOP_EQUALS, edu1.Id);
        System.Assert.isFalse(resultCampusAparentEqEdu1, 'Wrong result for campus2parent is edu1, Expected: false, Actual: ' + resultCampusAparentEqEdu1);
        
        //Not Equals
        Boolean resultCampusAparentNeqEdu1 = REDU_MatchingOperator_UTIL.calculate(Schema.DisplayType.REFERENCE, campusA.ParentId, MATCHINGOP_DOESNOTEQUAL, edu1.Id);
        System.Assert.isTrue(resultCampusAparentNeqEdu1, 'Wrong result for campus2parent is edu1, Expected: true, Actual: ' + resultCampusAparentNeqEdu1);
        Boolean resultCampus1parentNeqEdu1 = REDU_MatchingOperator_UTIL.calculate(Schema.DisplayType.REFERENCE, campus1.ParentId, MATCHINGOP_DOESNOTEQUAL, edu1.Id);
        System.Assert.isFalse(resultCampus1parentNeqEdu1, 'Wrong result for campus1parent is edu1, Expected: false, Actual: ' + resultCampus1parentNeqEdu1);
        
        //is Blank
        Boolean resultCampusparentIsblank = REDU_MatchingOperator_UTIL.calculate(Schema.DisplayType.REFERENCE, campus.ParentId, MATCHINGOP_ISBLANK, '');
        System.Assert.isTrue(resultCampusparentIsblank, 'Wrong result for campus2parent is blank, Expected: true, Actual: ' + resultCampusparentIsblank);
        Boolean resultCampus1parentIsblank = REDU_MatchingOperator_UTIL.calculate(Schema.DisplayType.REFERENCE, campus1.ParentId, MATCHINGOP_ISBLANK, '');
        System.Assert.isFalse(resultCampus1parentIsblank, 'Wrong result for campus2parent is blank, Expected: false, Actual: ' + resultCampus1parentIsblank);
        
        Test.stopTest();
    }

    /**
     * @description Test for display type = textarea (valid)
     */  
    @IsTest
    static void testForValidStringTextarea() {
        String string1 = 'This is a very long sentence designed to simulate the type of string you might encounter in a textarea.';
        String string2 = 'This is another very long sentence designed to simulate the type of string you might encounter in a textarea.';
        String stringBlank = '';
        String stringNull = null;
        Schema.DisplayType targetDisplayType = Schema.DisplayType.TEXTAREA;

        //Equals =
        Boolean result1Eq1 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, string1, MATCHINGOP_EQUALS, string1);
        System.Assert.isTrue(result1Eq1, 'Wrong result for string1 = string1, Expected: true, Actual: ' + result1Eq1);
        Boolean result1Eq2 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, string1, MATCHINGOP_EQUALS, string2);
        System.Assert.isFalse(result1Eq2, 'Wrong result for string1 = string2, Expected: false, Actual: ' + result1Eq2);
        
        //Not Equals !=
        Boolean result1Neq2 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, string1, MATCHINGOP_DOESNOTEQUAL, string2);
        System.Assert.isTrue(result1Neq2, 'Wrong result for string1 != string2, Expected: true, Actual: ' + result1Neq2);
        Boolean result1Neq1 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, string1, MATCHINGOP_DOESNOTEQUAL, string1);
        System.Assert.isFalse(result1Neq1, 'Wrong result for string1 = string1, Expected: false, Actual: ' + result1Neq1);
        
        //is Blank
        Boolean result1Isblank = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, string1, MATCHINGOP_ISBLANK, '');
        System.Assert.isFalse(result1Isblank, 'Wrong result for string1 is blank, Expected: false, Actual: ' + result1Isblank);
        Boolean resultblankIsblank = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, stringBlank, MATCHINGOP_ISBLANK, '');
        System.Assert.isTrue(resultblankIsblank, 'Wrong result for blank is blank, Expected: true, Actual: ' + resultblankIsblank);
        Boolean resultNullIsblank = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, stringNull, MATCHINGOP_ISBLANK, '');
        System.Assert.isTrue(resultNullIsblank, 'Wrong result for null is blank, Expected: true, Actual: ' + resultNullIsblank);
        
    }

    /**
     * @description Test for display type = string (valid)
     */  
    @IsTest
    static void testForValidStringString() {
        String string1 = 'string1';
        String string2 = 'string2';
        String stringBlank = '';
        String stringNull = null;
        Schema.DisplayType targetDisplayType = Schema.DisplayType.STRING;

        //Equals =
        Boolean result1Eq1 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, string1, MATCHINGOP_EQUALS, string1);
        System.Assert.isTrue(result1Eq1, 'Wrong result for string1 = string1, Expected: true, Actual: ' + result1Eq1);
        Boolean result1Eq2 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, string1, MATCHINGOP_EQUALS, string2);
        System.Assert.isFalse(result1Eq2, 'Wrong result for string1 = string2, Expected: false, Actual: ' + result1Eq2);
        
        //Not Equals !=
        Boolean result1Neq2 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, string1, MATCHINGOP_DOESNOTEQUAL, string2);
        System.Assert.isTrue(result1Neq2, 'Wrong result for string1 != string2, Expected: true, Actual: ' + result1Neq2);
        Boolean result1Neq1 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, string1, MATCHINGOP_DOESNOTEQUAL, string1);
        System.Assert.isFalse(result1Neq1, 'Wrong result for string1 = string1, Expected: false, Actual: ' + result1Neq1);
        
        //is Blank
        Boolean result1Isblank = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, string1, MATCHINGOP_ISBLANK, '');
        System.Assert.isFalse(result1Isblank, 'Wrong result for string1 is blank, Expected: false, Actual: ' + result1Isblank);
        Boolean resultblankIsblank = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, stringBlank, MATCHINGOP_ISBLANK, '');
        System.Assert.isTrue(resultblankIsblank, 'Wrong result for blank is blank, Expected: true, Actual: ' + resultblankIsblank);
        Boolean resultNullIsblank = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, stringNull, MATCHINGOP_ISBLANK, '');
        System.Assert.isTrue(resultNullIsblank, 'Wrong result for null is blank, Expected: true, Actual: ' + resultNullIsblank);
        
    }

    /**
     * @description Test for display type = email (valid)
     */  
    @IsTest
    static void testForValidStringEmail() {
        String string1 = 'person1@example.com';
        String string2 = 'person2@example.com';
        String stringBlank = '';
        String stringNull = null;
        Schema.DisplayType targetDisplayType = Schema.DisplayType.EMAIL;

        //Equals =
        Boolean result1Eq1 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, string1, MATCHINGOP_EQUALS, string1);
        System.Assert.isTrue(result1Eq1, 'Wrong result for string1 = string1, Expected: true, Actual: ' + result1Eq1);
        Boolean result1Eq2 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, string1, MATCHINGOP_EQUALS, string2);
        System.Assert.isFalse(result1Eq2, 'Wrong result for string1 = string2, Expected: false, Actual: ' + result1Eq2);
        
        //Not Equals !=
        Boolean result1Neq2 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, string1, MATCHINGOP_DOESNOTEQUAL, string2);
        System.Assert.isTrue(result1Neq2, 'Wrong result for string1 != string2, Expected: true, Actual: ' + result1Neq2);
        Boolean result1Neq1 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, string1, MATCHINGOP_DOESNOTEQUAL, string1);
        System.Assert.isFalse(result1Neq1, 'Wrong result for string1 = string1, Expected: false, Actual: ' + result1Neq1);
        
        //is Blank
        Boolean result1Isblank = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, string1, MATCHINGOP_ISBLANK, '');
        System.Assert.isFalse(result1Isblank, 'Wrong result for string1 is blank, Expected: false, Actual: ' + result1Isblank);
        Boolean resultblankIsblank = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, stringBlank, MATCHINGOP_ISBLANK, '');
        System.Assert.isTrue(resultblankIsblank, 'Wrong result for blank is blank, Expected: true, Actual: ' + resultblankIsblank);
        Boolean resultNullIsblank = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, stringNull, MATCHINGOP_ISBLANK, '');
        System.Assert.isTrue(resultNullIsblank, 'Wrong result for null is blank, Expected: true, Actual: ' + resultNullIsblank);
        
    }

    /**
     * @description Test for display type = phone (valid)
     */  
    @IsTest
    static void testForValidStringPhone() {
        String string1 = '0123456789';
        String string2 = '0123456000';
        String stringBlank = '';
        String stringNull = null;
        Schema.DisplayType targetDisplayType = Schema.DisplayType.PHONE;

        //Equals =
        Boolean result1Eq1 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, string1, MATCHINGOP_EQUALS, string1);
        System.Assert.isTrue(result1Eq1, 'Wrong result for string1 = string1, Expected: true, Actual: ' + result1Eq1);
        Boolean result1Eq2 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, string1, MATCHINGOP_EQUALS, string2);
        System.Assert.isFalse(result1Eq2, 'Wrong result for string1 = string2, Expected: false, Actual: ' + result1Eq2);
        
        //Not Equals !=
        Boolean result1Neq2 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, string1, MATCHINGOP_DOESNOTEQUAL, string2);
        System.Assert.isTrue(result1Neq2, 'Wrong result for string1 != string2, Expected: true, Actual: ' + result1Neq2);
        Boolean result1Neq1 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, string1, MATCHINGOP_DOESNOTEQUAL, string1);
        System.Assert.isFalse(result1Neq1, 'Wrong result for string1 = string1, Expected: false, Actual: ' + result1Neq1);
        
        //is Blank
        Boolean result1Isblank = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, string1, MATCHINGOP_ISBLANK, '');
        System.Assert.isFalse(result1Isblank, 'Wrong result for string1 is blank, Expected: false, Actual: ' + result1Isblank);
        Boolean resultblankIsblank = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, stringBlank, MATCHINGOP_ISBLANK, '');
        System.Assert.isTrue(resultblankIsblank, 'Wrong result for blank is blank, Expected: true, Actual: ' + resultblankIsblank);
        Boolean resultNullIsblank = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, stringNull, MATCHINGOP_ISBLANK, '');
        System.Assert.isTrue(resultNullIsblank, 'Wrong result for null is blank, Expected: true, Actual: ' + resultNullIsblank);
    }

    /**
     * @description Test for display type = picklist (valid)
     */  
    @IsTest
    static void testForValidStringPicklist() {
        String string1 = 'Item1';
        String string2 = 'Item2';
        String stringBlank = '';
        String stringNull = null;
        Schema.DisplayType targetDisplayType = Schema.DisplayType.PICKLIST;

        //Equals =
        Boolean result1Eq1 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, string1, MATCHINGOP_EQUALS, string1);
        System.Assert.isTrue(result1Eq1, 'Wrong result for string1 = string1, Expected: true, Actual: ' + result1Eq1);
        Boolean result1Eq2 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, string1, MATCHINGOP_EQUALS, string2);
        System.Assert.isFalse(result1Eq2, 'Wrong result for string1 = string2, Expected: false, Actual: ' + result1Eq2);
        
        //Not Equals !=
        Boolean result1Neq2 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, string1, MATCHINGOP_DOESNOTEQUAL, string2);
        System.Assert.isTrue(result1Neq2, 'Wrong result for string1 != string2, Expected: true, Actual: ' + result1Neq2);
        Boolean result1Neq1 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, string1, MATCHINGOP_DOESNOTEQUAL, string1);
        System.Assert.isFalse(result1Neq1, 'Wrong result for string1 = string1, Expected: false, Actual: ' + result1Neq1);
        
        //is Blank
        Boolean result1Isblank = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, string1, MATCHINGOP_ISBLANK, '');
        System.Assert.isFalse(result1Isblank, 'Wrong result for string1 is blank, Expected: false, Actual: ' + result1Isblank);
        Boolean resultblankIsblank = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, stringBlank, MATCHINGOP_ISBLANK, '');
        System.Assert.isTrue(resultblankIsblank, 'Wrong result for blank is blank, Expected: true, Actual: ' + resultblankIsblank);
        Boolean resultNullIsblank = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, stringNull, MATCHINGOP_ISBLANK, '');
        System.Assert.isTrue(resultNullIsblank, 'Wrong result for null is blank, Expected: true, Actual: ' + resultNullIsblank);

    }  
    
    /**
     * @description Test for display type = multipicklist (valid)
     */  
    @IsTest
    static void testForValidStringMultiPicklist() {
        String string1 = 'Item1';
        String string2 = 'Item1;Item2';
        String stringBlank = '';
        String stringNull = null;
        Schema.DisplayType targetDisplayType = Schema.DisplayType.MULTIPICKLIST;

        //Equals =
        Boolean result1Eq1 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, string1, MATCHINGOP_EQUALS, string1);
        System.Assert.isTrue(result1Eq1, 'Wrong result for string1 = string1, Expected: true, Actual: ' + result1Eq1);
        Boolean result1Eq2 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, string1, MATCHINGOP_EQUALS, string2);
        System.Assert.isFalse(result1Eq2, 'Wrong result for string1 = string2, Expected: false, Actual: ' + result1Eq2);
        
        //Not Equals !=
        Boolean result1Neq2 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, string1, MATCHINGOP_DOESNOTEQUAL, string2);
        System.Assert.isTrue(result1Neq2, 'Wrong result for string1 != string2, Expected: true, Actual: ' + result1Neq2);
        Boolean result1Neq1 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, string1, MATCHINGOP_DOESNOTEQUAL, string1);
        System.Assert.isFalse(result1Neq1, 'Wrong result for string1 = string1, Expected: false, Actual: ' + result1Neq1);
        
        //is Blank
        Boolean result1Isblank = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, string1, MATCHINGOP_ISBLANK, '');
        System.Assert.isFalse(result1Isblank, 'Wrong result for string1 is blank, Expected: false, Actual: ' + result1Isblank);
        Boolean resultblankIsblank = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, stringBlank, MATCHINGOP_ISBLANK, '');
        System.Assert.isTrue(resultblankIsblank, 'Wrong result for blank is blank, Expected: true, Actual: ' + resultblankIsblank);
        Boolean resultNullIsblank = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, stringNull, MATCHINGOP_ISBLANK, '');
        System.Assert.isTrue(resultNullIsblank, 'Wrong result for null is blank, Expected: true, Actual: ' + resultNullIsblank);
        
    }    
    
    /**
     * @description Test for display type = url (valid)
     */  
    @IsTest
    static void testForValidStringUrl() {
        String string1 = 'https://www.google.com';
        String string2 = 'https://www.example.com';
        String stringBlank = '';
        String stringNull = null;
        Schema.DisplayType targetDisplayType = Schema.DisplayType.URL;

        //Equals =
        Boolean result1Eq1 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, string1, MATCHINGOP_EQUALS, string1);
        System.Assert.isTrue(result1Eq1, 'Wrong result for string1 = string1, Expected: true, Actual: ' + result1Eq1);
        Boolean result1Eq2 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, string1, MATCHINGOP_EQUALS, string2);
        System.Assert.isFalse(result1Eq2, 'Wrong result for string1 = string2, Expected: false, Actual: ' + result1Eq2);
        
        //Not Equals !=
        Boolean result1Neq2 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, string1, MATCHINGOP_DOESNOTEQUAL, string2);
        System.Assert.isTrue(result1Neq2, 'Wrong result for string1 != string2, Expected: true, Actual: ' + result1Neq2);
        Boolean result1Neq1 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, string1, MATCHINGOP_DOESNOTEQUAL, string1);
        System.Assert.isFalse(result1Neq1, 'Wrong result for string1 = string1, Expected: false, Actual: ' + result1Neq1);
        
        //is Blank
        Boolean result1Isblank = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, string1, MATCHINGOP_ISBLANK, '');
        System.Assert.isFalse(result1Isblank, 'Wrong result for string1 is blank, Expected: false, Actual: ' + result1Isblank);
        Boolean resultblankIsblank = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, stringBlank, MATCHINGOP_ISBLANK, '');
        System.Assert.isTrue(resultblankIsblank, 'Wrong result for blank is blank, Expected: true, Actual: ' + resultblankIsblank);
        Boolean resultNullIsblank = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, stringNull, MATCHINGOP_ISBLANK, '');
        System.Assert.isTrue(resultNullIsblank, 'Wrong result for null is blank, Expected: true, Actual: ' + resultNullIsblank);
        
    }    

    /**
     * @description test for invalid string
     */ 
    @IsTest
    static void testForValidStringId() {

        Test.startTest();

        Account edu1 = new Account(RecordTypeId = ACC_Helper.getEducationalInstitutionRecordTypeId(), Name = 'EduInst 1');
        Account edu2 = new Account(RecordTypeId = ACC_Helper.getEducationalInstitutionRecordTypeId(), Name = 'EduInst 2');
        Account eduNotInserted = new Account(RecordTypeId = ACC_Helper.getEducationalInstitutionRecordTypeId(), Name = 'EduInst Empty');
        List<Account> eduList = new List<Account>{edu1, edu2};
        insert eduList;

        Schema.DisplayType targetDisplayType = Schema.DisplayType.ID;

        //Equals =
        Boolean result1Eq1 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, edu1.Id, MATCHINGOP_EQUALS, edu1.Id);
        System.Assert.isTrue(result1Eq1, 'Wrong result for edu1 = edu1, Expected: true, Actual: ' + result1Eq1);
        Boolean result1Eq2 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, edu1.Id, MATCHINGOP_EQUALS, edu2.Id);
        System.Assert.isFalse(result1Eq2, 'Wrong result for edu1 = edu2, Expected: false, Actual: ' + result1Eq2);
        
        //Not Equals !=
        Boolean result1Neq2 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, edu1.Id, MATCHINGOP_DOESNOTEQUAL, edu2.Id);
        System.Assert.isTrue(result1Neq2, 'Wrong result for edu1 != edu2, Expected: true, Actual: ' + result1Neq2);
        Boolean result1Neq1 = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, edu1.Id, MATCHINGOP_DOESNOTEQUAL, edu1.Id);
        System.Assert.isFalse(result1Neq1, 'Wrong result for edu1 = edu1, Expected: false, Actual: ' + result1Neq1);
        
        //is Blank
        Boolean result1Isblank = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, edu1.Id, MATCHINGOP_ISBLANK, '');
        System.Assert.isFalse(result1Isblank, 'Wrong result for edu1.Id is blank, Expected: false, Actual: ' + result1Isblank);
        Boolean resultblankIsblank = REDU_MatchingOperator_UTIL.calculate(targetDisplayType, eduNotInserted.Id, MATCHINGOP_ISBLANK, '');
        System.Assert.isTrue(resultblankIsblank, 'Wrong result for blank is blank, Expected: true, Actual: ' + resultblankIsblank);
        
        Test.stopTest();
    }

    /**
     * @description test for invalid boolean value
     */ 
    @IsTest
    static void testForInvalidBoolean(){
        Map<String, String> picklistValueToLabelMap = new Map<String,String>();
        List<Schema.PicklistEntry> operatorList = SUR_Helper.getFieldMatchingOperator();
        for(Schema.PicklistEntry operatorItem : operatorList) {
            picklistValueToLabelMap.put(operatorItem.getValue(), operatorItem.getLabel());
        }

        try {
            REDU_MatchingOperator_UTIL.calculate(Schema.DisplayType.BOOLEAN, true, MATCHINGOP_GREATER, 'true');
            System.Assert.fail('Should not be able to use greater operator.');
        } catch (Exception exp) {
            System.Assert.areEqual(REDU_MatchingOperator_UTIL.INVALID_OPERATOR_BOOLEAN, exp.getMessage(), 'Wrong exception message.');
            String actualMsg = REDU_MatchingOperator_UTIL.getErrorMessage(exp.getMessage(), MATCHINGOP_GREATER, IUR_Helper.getApiName(), 'Boolean Custom Field');
            String expectedMsg = String.format(Label.Invalid_Requirement_Matching_Operator_Boolean, 
                new List<String>{
                    picklistValueToLabelMap.get(MATCHINGOP_GREATER), picklistValueToLabelMap.get(MATCHINGOP_EQUALS), 
                    picklistValueToLabelMap.get(MATCHINGOP_DOESNOTEQUAL)
                }
            );
            System.Assert.areEqual(expectedMsg, actualMsg, 'Wrong exception message. ');
        }

        try {
            REDU_MatchingOperator_UTIL.calculate(Schema.DisplayType.BOOLEAN, true, MATCHINGOP_LESS, 'true');
            System.Assert.fail('Should not be able to use less operator.');
        } catch (Exception exp) {
            System.Assert.areEqual(REDU_MatchingOperator_UTIL.INVALID_OPERATOR_BOOLEAN, exp.getMessage(), 'Wrong exception message.');
            String actualMsg = REDU_MatchingOperator_UTIL.getErrorMessage(exp.getMessage(), MATCHINGOP_LESS, IUR_Helper.getApiName(), 'Boolean Custom Field');
            String expectedMsg = String.format(Label.Invalid_Requirement_Matching_Operator_Boolean, 
                new List<String>{
                    picklistValueToLabelMap.get(MATCHINGOP_LESS), picklistValueToLabelMap.get(MATCHINGOP_EQUALS), 
                    picklistValueToLabelMap.get(MATCHINGOP_DOESNOTEQUAL)
                }
            );
            System.Assert.areEqual(expectedMsg, actualMsg, 'Wrong exception message. ');
        }

        try {
            REDU_MatchingOperator_UTIL.calculate(Schema.DisplayType.BOOLEAN, true, MATCHINGOP_GREATEROREQUAL, 'true');
            System.Assert.fail('Should not be able to use greater than or equal operator.');
        } catch (Exception exp) {
            System.Assert.areEqual(REDU_MatchingOperator_UTIL.INVALID_OPERATOR_BOOLEAN, exp.getMessage(), 'Wrong exception message.');
            String actualMsg = REDU_MatchingOperator_UTIL.getErrorMessage(exp.getMessage(), MATCHINGOP_LESS, IUR_Helper.getApiName(), 'Boolean Custom Field');
            String expectedMsg = String.format(Label.Invalid_Requirement_Matching_Operator_Boolean, 
                new List<String>{
                    picklistValueToLabelMap.get(MATCHINGOP_LESS), picklistValueToLabelMap.get(MATCHINGOP_EQUALS), 
                    picklistValueToLabelMap.get(MATCHINGOP_DOESNOTEQUAL)
                }
            );
            System.Assert.areEqual(expectedMsg, actualMsg, 'Wrong exception message. ');
        }

        try {
            REDU_MatchingOperator_UTIL.calculate(Schema.DisplayType.BOOLEAN, true, MATCHINGOP_LESSOREQUAL, 'true');
            System.Assert.fail('Should not be able to use less than or equal operator.');
        } catch (Exception exp) {
            System.Assert.areEqual(REDU_MatchingOperator_UTIL.INVALID_OPERATOR_BOOLEAN, exp.getMessage(), 'Wrong exception message.');
            String actualMsg = REDU_MatchingOperator_UTIL.getErrorMessage(exp.getMessage(), MATCHINGOP_LESSOREQUAL, IUR_Helper.getApiName(), 'Boolean Custom Field');
            String expectedMsg = String.format(Label.Invalid_Requirement_Matching_Operator_Boolean, 
                new List<String>{
                    picklistValueToLabelMap.get(MATCHINGOP_LESSOREQUAL), picklistValueToLabelMap.get(MATCHINGOP_EQUALS), 
                    picklistValueToLabelMap.get(MATCHINGOP_DOESNOTEQUAL)
                }
            );
            System.Assert.areEqual(expectedMsg, actualMsg, 'Wrong exception message. ');
        }

        try {
            REDU_MatchingOperator_UTIL.calculate(Schema.DisplayType.BOOLEAN, true, MATCHINGOP_ISBLANK, 'true');
            System.Assert.fail('Should not be able to use is blank operator.');
        } catch (Exception exp) {
            System.Assert.areEqual(REDU_MatchingOperator_UTIL.INVALID_OPERATOR_BOOLEAN, exp.getMessage(), 'Wrong exception message.');
            String actualMsg = REDU_MatchingOperator_UTIL.getErrorMessage(exp.getMessage(), MATCHINGOP_ISBLANK, IUR_Helper.getApiName(), 'Boolean Custom Field');
            String expectedMsg = String.format(Label.Invalid_Requirement_Matching_Operator_Boolean, 
                new List<String>{
                    picklistValueToLabelMap.get(MATCHINGOP_ISBLANK), picklistValueToLabelMap.get(MATCHINGOP_EQUALS), 
                    picklistValueToLabelMap.get(MATCHINGOP_DOESNOTEQUAL)
                }
            );
            System.Assert.areEqual(expectedMsg, actualMsg, 'Wrong exception message. ');
        }

        try {
            REDU_MatchingOperator_UTIL.calculate(Schema.DisplayType.BOOLEAN, true, MATCHINGOP_ISBLANK, 'true');
            System.Assert.fail('Should not be able to use is blank operator.');
        } catch (Exception exp) {
            System.Assert.areEqual(REDU_MatchingOperator_UTIL.INVALID_OPERATOR_BOOLEAN, exp.getMessage(), 'Wrong exception message.');
            String actualMsg = REDU_MatchingOperator_UTIL.getErrorMessage(exp.getMessage(), MATCHINGOP_ISBLANK, IUR_Helper.getApiName(), 'Boolean Custom Field');
            String expectedMsg = String.format(Label.Invalid_Requirement_Matching_Operator_Boolean, 
                new List<String>{
                    picklistValueToLabelMap.get(MATCHINGOP_ISBLANK), picklistValueToLabelMap.get(MATCHINGOP_EQUALS), 
                    picklistValueToLabelMap.get(MATCHINGOP_DOESNOTEQUAL)
                }
            );
            System.Assert.areEqual(expectedMsg, actualMsg, 'Wrong exception message. ');
        }

        try {
            REDU_MatchingOperator_UTIL.calculate(Schema.DisplayType.BOOLEAN, true, MATCHINGOP_EQUALS, '');
            System.Assert.fail('The value should not be empty');
        } catch (Exception exp) {
            System.Assert.areEqual(REDU_MatchingOperator_UTIL.INVALID_VALUE_BOOLEAN, exp.getMessage(), 'Wrong exception message.');
            String actualMsg = REDU_MatchingOperator_UTIL.getErrorMessage(exp.getMessage(), MATCHINGOP_EQUALS, IUR_Helper.getApiName(), 'Field Name');
            Schema.DescribeFieldResult fieldNameDescribe = REDU_Metadata_UTIL.describeSObjectField(IUR_Helper.getApiName(), 'reduivy__Field_Matching_Value__c');
            String expectedMsg = String.format(Label.Invalid_Requirement_Matching_Value_Boolean, new List<String>{fieldNameDescribe.getLabel()});
            System.Assert.areEqual(expectedMsg, actualMsg, 'Wrong exception message.');
        }

        try {
            REDU_MatchingOperator_UTIL.calculate(Schema.DisplayType.BOOLEAN, true, MATCHINGOP_DOESNOTEQUAL, '');
            System.Assert.fail('The value should not be empty');
        } catch (Exception exp) {
            System.Assert.areEqual(REDU_MatchingOperator_UTIL.INVALID_VALUE_BOOLEAN, exp.getMessage(), 'Wrong exception message.');
            String actualMsg = REDU_MatchingOperator_UTIL.getErrorMessage(exp.getMessage(), MATCHINGOP_DOESNOTEQUAL, IUR_Helper.getApiName(), 'Field Name');
            Schema.DescribeFieldResult fieldNameDescribe = REDU_Metadata_UTIL.describeSObjectField(IUR_Helper.getApiName(), 'reduivy__Field_Matching_Value__c');
            String expectedMsg = String.format(Label.Invalid_Requirement_Matching_Value_Boolean, new List<String>{fieldNameDescribe.getLabel()});
            System.Assert.areEqual(expectedMsg, actualMsg, 'Wrong exception message.');
        }

        try {
            REDU_MatchingOperator_UTIL.calculate(Schema.DisplayType.BOOLEAN, true, MATCHINGOP_EQUALS, 'test');
            System.Assert.fail('The value can only be either true or false');
        } catch (Exception exp) {
            System.Assert.areEqual(REDU_MatchingOperator_UTIL.INVALID_VALUE_BOOLEAN, exp.getMessage(), 'Wrong exception message.');
            String actualMsg = REDU_MatchingOperator_UTIL.getErrorMessage(exp.getMessage(), MATCHINGOP_EQUALS, IUR_Helper.getApiName(), 'Boolean Custom Field');
            Schema.DescribeFieldResult fieldNameDescribe = REDU_Metadata_UTIL.describeSObjectField(IUR_Helper.getApiName(), 'reduivy__Field_Matching_Value__c');
            String expectedMsg = String.format(Label.Invalid_Requirement_Matching_Value_Boolean, new List<String>{fieldNameDescribe.getLabel()});
            System.Assert.areEqual(expectedMsg, actualMsg, 'Wrong exception message.');
        }

        try {
            REDU_MatchingOperator_UTIL.calculate(Schema.DisplayType.BOOLEAN, true, MATCHINGOP_DOESNOTEQUAL, 'not false');
            System.Assert.fail('The value can only be either true or false');
        } catch (Exception exp) {
            System.Assert.areEqual(REDU_MatchingOperator_UTIL.INVALID_VALUE_BOOLEAN, exp.getMessage(), 'Wrong exception message.');
            String actualMsg = REDU_MatchingOperator_UTIL.getErrorMessage(exp.getMessage(), MATCHINGOP_DOESNOTEQUAL, IUR_Helper.getApiName(), 'Boolean Custom Field');
            Schema.DescribeFieldResult fieldNameDescribe = REDU_Metadata_UTIL.describeSObjectField(IUR_Helper.getApiName(), 'reduivy__Field_Matching_Value__c');
            String expectedMsg = String.format(Label.Invalid_Requirement_Matching_Value_Boolean, new List<String>{fieldNameDescribe.getLabel()});
            System.Assert.areEqual(expectedMsg, actualMsg, 'Wrong exception message.');
        }
    }

    /**
     * @description test for invalid number value
     */ 
    @IsTest
    static void testForInvalidNumber() {
        Map<String, String> picklistValueToLabelMap = new Map<String,String>();
        List<Schema.PicklistEntry> operatorList = SUR_Helper.getFieldMatchingOperator();
        for(Schema.PicklistEntry operatorItem : operatorList) {
            picklistValueToLabelMap.put(operatorItem.getValue(), operatorItem.getLabel());
        }

        Long valueLong = 12;
        Integer valueInteger = 12;
        Double valueDouble = 12.1;
        Decimal valueDecimal = 12.41;
        String nonNumerical = 'abcd123';

        try {
            REDU_MatchingOperator_UTIL.calculate(Schema.DisplayType.LONG, valueLong, MATCHINGOP_EQUALS, nonNumerical);
            System.Assert.fail('Value type is invalid.');
        } catch (Exception exp) {
            System.Assert.areEqual(REDU_MatchingOperator_UTIL.INVALID_VALUE_NUMBER, exp.getMessage(), 'Wrong exception message.');
            String actualMsg = REDU_MatchingOperator_UTIL.getErrorMessage(exp.getMessage(), MATCHINGOP_EQUALS, IUR_Helper.getApiName(), 'Number');
            Schema.DescribeFieldResult fieldNameDescribe = REDU_Metadata_UTIL.describeSObjectField(IUR_Helper.getApiName(), 'reduivy__Field_Matching_Value__c');
            String expectedMsg = String.format(Label.Invalid_Requirement_Matching_Value_Number, new List<String>{fieldNameDescribe.getLabel()});
            System.Assert.areEqual(expectedMsg, actualMsg, 'Wrong exception message.');
        }

        try {
            REDU_MatchingOperator_UTIL.calculate(Schema.DisplayType.INTEGER, valueInteger, MATCHINGOP_EQUALS, nonNumerical);
            System.Assert.fail('Value type is invalid.');
        } catch (Exception exp) {
            System.Assert.areEqual(REDU_MatchingOperator_UTIL.INVALID_VALUE_NUMBER, exp.getMessage(), 'Wrong exception message.');
            String actualMsg = REDU_MatchingOperator_UTIL.getErrorMessage(exp.getMessage(), MATCHINGOP_EQUALS, IUR_Helper.getApiName(), 'Number');
            Schema.DescribeFieldResult fieldNameDescribe = REDU_Metadata_UTIL.describeSObjectField(IUR_Helper.getApiName(), 'reduivy__Field_Matching_Value__c');
            String expectedMsg = String.format(Label.Invalid_Requirement_Matching_Value_Number, new List<String>{fieldNameDescribe.getLabel()});
            System.Assert.areEqual(expectedMsg, actualMsg, 'Wrong exception message.');
        }

        try {
            REDU_MatchingOperator_UTIL.calculate(Schema.DisplayType.DOUBLE, valueDouble, MATCHINGOP_EQUALS, nonNumerical);
            System.Assert.fail('Value type is invalid.');
        } catch (Exception exp) {
            System.Assert.areEqual(REDU_MatchingOperator_UTIL.INVALID_VALUE_NUMBER, exp.getMessage(), 'Wrong exception message.');
            String actualMsg = REDU_MatchingOperator_UTIL.getErrorMessage(exp.getMessage(), MATCHINGOP_EQUALS, IUR_Helper.getApiName(), 'Number');
            Schema.DescribeFieldResult fieldNameDescribe = REDU_Metadata_UTIL.describeSObjectField(IUR_Helper.getApiName(), 'reduivy__Field_Matching_Value__c');
            String expectedMsg = String.format(Label.Invalid_Requirement_Matching_Value_Number, new List<String>{fieldNameDescribe.getLabel()});
            System.Assert.areEqual(expectedMsg, actualMsg, 'Wrong exception message.');
        }

        try {
            REDU_MatchingOperator_UTIL.calculate(Schema.DisplayType.CURRENCY, valueDecimal, MATCHINGOP_EQUALS, nonNumerical);
            System.Assert.fail('Value type is invalid.');
        } catch (Exception exp) {
            System.Assert.areEqual(REDU_MatchingOperator_UTIL.INVALID_VALUE_NUMBER, exp.getMessage(), 'Wrong exception message.');
            String actualMsg = REDU_MatchingOperator_UTIL.getErrorMessage(exp.getMessage(), MATCHINGOP_EQUALS, IUR_Helper.getApiName(), 'Number');
            Schema.DescribeFieldResult fieldNameDescribe = REDU_Metadata_UTIL.describeSObjectField(IUR_Helper.getApiName(), 'reduivy__Field_Matching_Value__c');
            String expectedMsg = String.format(Label.Invalid_Requirement_Matching_Value_Number, new List<String>{fieldNameDescribe.getLabel()});
            System.Assert.areEqual(expectedMsg, actualMsg, 'Wrong exception message.');
        }

        try {
            REDU_MatchingOperator_UTIL.calculate(Schema.DisplayType.PERCENT, valueDecimal, MATCHINGOP_EQUALS, nonNumerical);
            System.Assert.fail('Value type is invalid.');
        } catch (Exception exp) {
            System.Assert.areEqual(REDU_MatchingOperator_UTIL.INVALID_VALUE_NUMBER, exp.getMessage(), 'Wrong exception message.');
            String actualMsg = REDU_MatchingOperator_UTIL.getErrorMessage(exp.getMessage(), MATCHINGOP_EQUALS, IUR_Helper.getApiName(), 'Number');
            Schema.DescribeFieldResult fieldNameDescribe = REDU_Metadata_UTIL.describeSObjectField(IUR_Helper.getApiName(), 'reduivy__Field_Matching_Value__c');
            String expectedMsg = String.format(Label.Invalid_Requirement_Matching_Value_Number, new List<String>{fieldNameDescribe.getLabel()});
            System.Assert.areEqual(expectedMsg, actualMsg, 'Wrong exception message.');
        }
    }

    /**
     * @description test for invalid string value
     */ 
    @IsTest
    static void testForInvalidString(){
        Map<String, String> picklistValueToLabelMap = new Map<String,String>();
        List<Schema.PicklistEntry> operatorList = SUR_Helper.getFieldMatchingOperator();
        for(Schema.PicklistEntry operatorItem : operatorList) {
            picklistValueToLabelMap.put(operatorItem.getValue(), operatorItem.getLabel());
        }
        String string1 = 'string1';
        String string2 = 'string2';
        
        try {
            REDU_MatchingOperator_UTIL.calculate(Schema.DisplayType.STRING, string1, MATCHINGOP_GREATER, string2);
            System.Assert.fail('Should not be able to use greater operator.');
        } catch (Exception exp) {
            System.Assert.areEqual(REDU_MatchingOperator_UTIL.INVALID_OPERATOR_STRING, exp.getMessage(), 'Wrong exception message.');
            String actualMsg = REDU_MatchingOperator_UTIL.getErrorMessage(exp.getMessage(), MATCHINGOP_GREATER, IUR_Helper.getApiName(), 'String');
            String expectedMsg = String.format(Label.Invalid_Requirement_Matching_Operator_String, 
                new List<String>{
                    picklistValueToLabelMap.get(MATCHINGOP_GREATER), picklistValueToLabelMap.get(MATCHINGOP_EQUALS), 
                    picklistValueToLabelMap.get(MATCHINGOP_DOESNOTEQUAL), picklistValueToLabelMap.get(MATCHINGOP_ISBLANK)
                }
            );
            System.Assert.areEqual(expectedMsg, actualMsg, 'Wrong exception message.');
        }

        try {
            REDU_MatchingOperator_UTIL.calculate(Schema.DisplayType.STRING, string1, MATCHINGOP_LESS, string2);
            System.Assert.fail('Should not be able to use less operator.');
        } catch (Exception exp) {
            System.Assert.areEqual(REDU_MatchingOperator_UTIL.INVALID_OPERATOR_STRING, exp.getMessage(), 'Wrong exception message.');
            String actualMsg = REDU_MatchingOperator_UTIL.getErrorMessage(exp.getMessage(), MATCHINGOP_GREATER, IUR_Helper.getApiName(), 'String');
            String expectedMsg = String.format(Label.Invalid_Requirement_Matching_Operator_String, 
                new List<String>{
                    picklistValueToLabelMap.get(MATCHINGOP_GREATER), picklistValueToLabelMap.get(MATCHINGOP_EQUALS), 
                    picklistValueToLabelMap.get(MATCHINGOP_DOESNOTEQUAL), picklistValueToLabelMap.get(MATCHINGOP_ISBLANK)
                }
            );
            System.Assert.areEqual(expectedMsg, actualMsg, 'Wrong exception message.');
        }

        try {
            REDU_MatchingOperator_UTIL.calculate(Schema.DisplayType.STRING, string1, MATCHINGOP_GREATEROREQUAL, string2);
            System.Assert.fail('Should not be able to use greater than or equal operator.');
        } catch (Exception exp) {
            System.Assert.areEqual(REDU_MatchingOperator_UTIL.INVALID_OPERATOR_STRING, exp.getMessage(), 'Wrong exception message.');
            String actualMsg = REDU_MatchingOperator_UTIL.getErrorMessage(exp.getMessage(), MATCHINGOP_GREATER, IUR_Helper.getApiName(), 'String');
            String expectedMsg = String.format(Label.Invalid_Requirement_Matching_Operator_String, 
                new List<String>{
                    picklistValueToLabelMap.get(MATCHINGOP_GREATER), picklistValueToLabelMap.get(MATCHINGOP_EQUALS), 
                    picklistValueToLabelMap.get(MATCHINGOP_DOESNOTEQUAL), picklistValueToLabelMap.get(MATCHINGOP_ISBLANK)
                }
            );
            System.Assert.areEqual(expectedMsg, actualMsg, 'Wrong exception message.');
        }

        try {
            REDU_MatchingOperator_UTIL.calculate(Schema.DisplayType.STRING, string1, MATCHINGOP_LESSOREQUAL, string2);
            System.Assert.fail('Should not be able to use less than or equal operator.');
        } catch (Exception exp) {
            System.Assert.areEqual(REDU_MatchingOperator_UTIL.INVALID_OPERATOR_STRING, exp.getMessage(), 'Wrong exception message.');
            String actualMsg = REDU_MatchingOperator_UTIL.getErrorMessage(exp.getMessage(), MATCHINGOP_GREATER, IUR_Helper.getApiName(), 'String');
            String expectedMsg = String.format(Label.Invalid_Requirement_Matching_Operator_String, 
                new List<String>{
                    picklistValueToLabelMap.get(MATCHINGOP_GREATER), picklistValueToLabelMap.get(MATCHINGOP_EQUALS), 
                    picklistValueToLabelMap.get(MATCHINGOP_DOESNOTEQUAL), picklistValueToLabelMap.get(MATCHINGOP_ISBLANK)
                }
            );
            System.Assert.areEqual(expectedMsg, actualMsg, 'Wrong exception message.');
        }
    }

    /**
     * @description Test for invalid field
     */
    @IsTest
    static void testForInvalidField(){
        try {
            REDU_MatchingOperator_UTIL.calculate(Schema.DisplayType.Date, System.today(), MATCHINGOP_EQUALS, System.today().toString());
            System.Assert.fail('Date is not supported');
        } catch (Exception exp) {
            System.Assert.areEqual(REDU_MatchingOperator_UTIL.INVALID_FIELD, exp.getMessage(), 'Wrong exception message.');
            String actual = REDU_MatchingOperator_UTIL.getErrorMessage(exp.getMessage(), MATCHINGOP_EQUALS, IUR_Helper.getApiName(), 'reduivy__Start_Date__c');
            Schema.DescribeFieldResult customFieldNameDescribe = REDU_Metadata_UTIL.describeSObjectField(IPE_Helper.getApiName(), 'reduivy__Start_Date__c');
            String expected = String.format(Label.Invalid_Requirement_Field_Type, 
                new List<String>{
                    customFieldNameDescribe.getLabel()
                }
            );
            System.Assert.areEqual(expected, actual, 'Wrong exception message.');
        }
        
        try {
            REDU_MatchingOperator_UTIL.calculate(Schema.DisplayType.DATETIME, System.now(), MATCHINGOP_EQUALS, System.now().toString());
            System.Assert.fail('Datetime is not supported');
        } catch (Exception exp) {
            System.Assert.areEqual(REDU_MatchingOperator_UTIL.INVALID_FIELD, exp.getMessage(), 'Wrong exception message.');
            
        }
    }

}