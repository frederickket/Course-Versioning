/**
 * @author      WDCi (Lean)
 * @date        Dec 2023
 * @group       Utility
 * @description SObject comparator
 * @changehistory
 * ISS-001591 22-12-2023 Lean - generic comparator for sobject
 * ISS-002395 26-05-2025 Lean - enhanced to support sorting of multiple fields
 * ISS-002733 28-01-2026 Lean - enhanced to support parent field sorting
 */
public inherited sharing class REDU_SObjectComparator implements Comparator<SObject> {
    
    /**
     * @description Sorting order enum: Ascend, Descend
     */
    public enum SortOrder { Ascend, Descend}

    /**
     * @description Null order enum: NullsFirst, NullsLast
     */
    public enum NullOrder { NullsFirst, NullsLast }

    public class SortCriterion {

        /**
         * @description SObjectField for the field to be sorted
         */
        public Schema.SObjectField field;

        /**
         * @description ISS-002733 Field api name for the field to be sorted if the which can be used to support parent field e.g., reduivy__Academic_Term__r.reduivy__Start_Date__c
         */
        public String fieldName;

        /**
         * @description Sorting order
         */
        public SortOrder order;

        /**
         * Description Null order
         */
        public NullOrder nullOrder;

        /**
         * @description DescribeFieldResult for the field to be sorted
         */
        public DescribeFieldResult describeResult;

        /**
         * @description Init sorting criterion by SObjectField
         */
        public SortCriterion(Schema.SObjectField field, SortOrder order, NullOrder nullOrder) {
            this.field = field;
            this.order = order;
            this.nullOrder = nullOrder;
            this.describeResult = field.getDescribe();
        }

        /**
         * @description ISS-002733 Init sorting criterion by object + field api name to support parent field e.g., reduivy__Individual_Enrollment__c.reduivy__Academic_Term__r.reduivy__Start_Date__c
         */
        public SortCriterion(String objectFieldName, SortOrder order, NullOrder nullOrder) {
            this.order = order;
            this.nullOrder = nullOrder;

            //get the object name
            String objName = objectFieldName.substringBefore('.');

            //get the field name
            this.fieldName = objectFieldName.substringAfter('.');

            if (String.isBlank(objName) || String.isBlank(this.fieldName)) {
                String errorMsg = String.format(Label.Invalid_Object_Field_Error, new List<String>{objName, this.fieldName});
                throw new REDU_ApplicationException(errorMsg);
            }

            this.describeResult = REDU_Datatable_UTIL.getFieldDescribe(this.fieldName, REDU_Metadata_UTIL.getSObjectType(objName));
        }
    }
    
    /**
     * @description List of sorting criteria
     */
    private List<SortCriterion> sortCriteria;

    /**
     * @description Comparator constructur
     * @param compareField Schema.sObjectField for the field to be sorted
     * @param sortingOrder Sorting order
     * @return REDU_SObjectComparator
     */
    public REDU_SObjectComparator(List<SortCriterion> criteria) {
        if (criteria == null || criteria.isEmpty()) {
            throw new REDU_ApplicationException(Label.Sort_Criterion_Is_Required);
        }

        this.sortCriteria = criteria;
    }
    
    /**
     * @description Comparing the sobj and field with nulls last
     * @param s1 SObject
     * @param s2 SObject
     * @return Integer
     */
    public Integer compare(SObject s1, SObject s2) {
        
        for (SortCriterion criterion : sortCriteria) {
                        
            // Handle null objects before null field values
            if(s1 == null && s2 == null) {
                return 0;
            } else if (s1 == null) {
                return (criterion.nullOrder == NullOrder.NullsFirst) ? -1 : 1;
            } else if (s2 == null) {
                return (criterion.nullOrder == NullOrder.NullsFirst) ? 1 : -1;
            } 
            
            //ISS-002733
            object s1FieldValue = (criterion.field != null ? s1?.get(criterion.field) : REDU_SObject_UTIL.extractFieldValue(s1, criterion.fieldName));
            object s2FieldValue = (criterion.field != null ? s2?.get(criterion.field) : REDU_SObject_UTIL.extractFieldValue(s2, criterion.fieldName));

            // Handle null field values then actual value compares
            if(s1FieldValue == null && s2FieldValue == null) {
                // Equal, move to next criterion
                continue;
            } else if (s1FieldValue == null) {
                return (criterion.nullOrder == NullOrder.NullsFirst) ? -1 : 1;
            } else if (s2FieldValue == null) {
                return (criterion.nullOrder == NullOrder.NullsFirst) ? 1 : -1;
            } else {
                Integer compareResult = compareFieldValues(s1FieldValue, s2FieldValue, criterion.describeResult);

                if (compareResult != 0) {
                    return (criterion.order == SortOrder.Descend) ? -compareResult : compareResult;
                } 
            }
        }

        return 0;
    }
    
    /**
     * @description Compare the value by field type
     * @param s1FieldValue
     * @param s2FieldValue
     * @param describeResult
     * @return Integer
     */
    private Integer compareFieldValues(Object s1FieldValue, Object s2FieldValue, DescribeFieldResult describeResult) {
        switch on (describeResult.getSoapType()) {
            when String {
                //convert to lowercase to mimic the similar behavior as SOQL so that we can compare using case-insensitive
                String s1 = ((String)s1FieldValue).toLowerCase();
                String s2 = ((String)s2FieldValue).toLowerCase();

                Integer strCompareResult = s1.compareTo(s2);
                if (strCompareResult < 0) {
                    return -1;
                } else if (strCompareResult > 0) {
                    return 1;
                }

                return 0;

            } when DateTime {
                DateTime s1 = (DateTime)s1FieldValue;
                DateTime s2 = (DateTime)s2FieldValue;
            	return (s1 < s2) ? -1 : (s1 > s2) ? 1 : 0;

            } when Date {
                Date s1 = (Date)s1FieldValue;
                Date s2 = (Date)s2FieldValue;
            	return (s1 < s2) ? -1 : (s1 > s2) ? 1 : 0;

            } when Time {
                Time s1 = (Time)s1FieldValue;
                Time s2 = (Time)s2FieldValue;
            	return (s1 < s2) ? -1 : (s1 > s2) ? 1 : 0;

            } when Integer {
                Integer s1 = (Integer)s1FieldValue;
                Integer s2 = (Integer)s2FieldValue;
            	return (s1 < s2) ? -1 : (s1 > s2) ? 1 : 0;

            } when Double {
                Double s1 = (Double)s1FieldValue;
                Double s2 = (Double)s2FieldValue;
            	return (s1 < s2) ? -1 : (s1 > s2) ? 1 : 0;

            } when Id {
                Id s1 = (Id)s1FieldValue;
                Id s2 = (Id)s2FieldValue;
            	return (s1 < s2) ? -1 : (s1 > s2) ? 1 : 0;

            } when else {
                String error = String.format(Label.Unsupported_Field_Type_For_Sorting, new List<String>{describeResult.getName(), describeResult.getType().name()});
                throw new REDU_ApplicationException(error);
            }
        }
    }
    
    
}