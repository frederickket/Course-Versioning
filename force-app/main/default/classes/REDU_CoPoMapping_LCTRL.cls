/**
 * @author      RIO Education
 * @date        2026
 * @description Apex controller for the CO-PO Mapping LWC component.
 *              Provides methods to retrieve Course Outcomes, Program Outcomes,
 *              existing Course_Outcome_Program_Outcome__c weight mappings, and to save/update mappings.
 */
public with sharing class REDU_CoPoMapping_LCTRL {

    /**
     * @description Returns all Course Outcomes, optionally filtered by a Study Unit Version.
     * @param       studyUnitVersionId  Id of the Study_Unit_Version__c record (nullable).
     * @return      List of Course_Outcome__c records ordered by Course Outcome Code.
     */
    @AuraEnabled(cacheable=true)
    public static List<Course_Outcome__c> getCourseOutcomes(String studyUnitVersionId) {
        try {
            Id suvId = String.isNotBlank(studyUnitVersionId) ? (Id) studyUnitVersionId : null;
            if (suvId != null) {
                return [
                    SELECT Id, Name, Course_Outcome_Code__c, Blooms_Taxonomy_Level__c
                    FROM   Course_Outcome__c
                    WHERE  Study_Unit_Version__c = :suvId
                    ORDER BY Course_Outcome_Code__c ASC NULLS LAST
                ];
            }
            return [
                SELECT Id, Name, Course_Outcome_Code__c, Blooms_Taxonomy_Level__c
                FROM   Course_Outcome__c
                ORDER BY Course_Outcome_Code__c ASC NULLS LAST
            ];
        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    /**
     * @description Returns all Program Outcomes, optionally filtered by a Study Program Version.
     * @param       studyProgramVersionId  Id of the Study_Program_Version__c record (nullable).
     * @return      List of Program_Outcome__c records ordered by Program Outcome Code.
     */
    @AuraEnabled(cacheable=true)
    public static List<Program_Outcome__c> getProgramOutcomes(String studyProgramVersionId) {
        try {
            Id spvId = String.isNotBlank(studyProgramVersionId) ? (Id) studyProgramVersionId : null;
            if (spvId != null) {
                return [
                    SELECT Id, Name, Program_Outcome_Code__c
                    FROM   Program_Outcome__c
                    WHERE  Study_Program_Version__c = :spvId
                    ORDER BY Program_Outcome_Code__c ASC NULLS LAST
                ];
            }
            return [
                SELECT Id, Name, Program_Outcome_Code__c
                FROM   Program_Outcome__c
                ORDER BY Program_Outcome_Code__c ASC NULLS LAST
            ];
        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    /**
     * @description Returns existing Course_Outcome_Program_Outcome__c records for the given sets of Course and Program Outcomes.
     * @param       courseOutcomeIds   List of Course_Outcome__c Ids.
     * @param       programOutcomeIds  List of Program_Outcome__c Ids.
     * @return      List of Course_Outcome_Program_Outcome__c records with Weight values.
     */
    @AuraEnabled(cacheable=true)
    public static List<Course_Outcome_Program_Outcome__c> getMappings(List<Id> courseOutcomeIds, List<Id> programOutcomeIds) {
        try {
            if (courseOutcomeIds == null || courseOutcomeIds.isEmpty()
                    || programOutcomeIds == null || programOutcomeIds.isEmpty()) {
                return new List<Course_Outcome_Program_Outcome__c>();
            }
            return [
                SELECT Id, Course_Outcome__c, Program_Outcome__c, Weight__c
                FROM   Course_Outcome_Program_Outcome__c
                WHERE  Course_Outcome__c IN :courseOutcomeIds
                AND    Program_Outcome__c IN :programOutcomeIds
            ];
        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    /**
     * @description Creates or updates a Course_Outcome_Program_Outcome__c record with the given weight.
     *              If a record for the CO+PO pair already exists, its Weight is updated.
     *              If not, a new record is inserted.
     * @param       courseOutcomeId   Id of the Course_Outcome__c record.
     * @param       programOutcomeId  Id of the Program_Outcome__c record.
     * @param       weight            Weight value (0–5).
     * @return      Id of the saved Course_Outcome_Program_Outcome__c record.
     */
    @AuraEnabled
    public static Id saveMappingWeight(Id courseOutcomeId, Id programOutcomeId, Decimal weight) {
        try {
            if (weight == null || weight < 0 || weight > 5) {
                throw new AuraHandledException('Weight must be a number between 0 and 5.');
            }

            List<Course_Outcome_Program_Outcome__c> existing = [
                SELECT Id
                FROM   Course_Outcome_Program_Outcome__c
                WHERE  Course_Outcome__c  = :courseOutcomeId
                AND    Program_Outcome__c = :programOutcomeId
                LIMIT  1
            ];

            Course_Outcome_Program_Outcome__c mapping;
            if (!existing.isEmpty()) {
                mapping           = existing[0];
                mapping.Weight__c = weight;
                update mapping;
            } else {
                mapping = new Course_Outcome_Program_Outcome__c(
                    Course_Outcome__c  = courseOutcomeId,
                    Program_Outcome__c = programOutcomeId,
                    Weight__c          = weight
                );
                insert mapping;
            }

            return mapping.Id;
        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }
}
