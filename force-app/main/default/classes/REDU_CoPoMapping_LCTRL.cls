/**
 * @author      WDCi ()
 * @date        Jan 2024
 * @group       
 * @description 
 * @changehistory
 * ISS-XXXXXX dd-mm-yyyy name - description
 */

/**
 * COPOMappingController
 * Apex controller for the CO-PO Mapping LWC component.
 *
 * Key decisions:
 *  - Course Outcomes are ordered by reduivy__Course_Outcome_Code__c (CO1, CO2 …)
 *  - Program Outcomes are ordered by reduivy__Program_Outcome_Code__c (PO1, PO2 …)
 *  - No separate Sequence field is needed; the code itself acts as the sequence.
 *  - studyProgramVersionId is returned in the DTO so the LWC can call addProgramOutcome.
 */
public with sharing class COPOMappingController {

    // ─────────────────────────────────────────────────────────────────────────
    // DTOs
    // ─────────────────────────────────────────────────────────────────────────

    public class COPOMappingData {
        @AuraEnabled public List<CourseOutcomeRow>  courseOutcomes;
        @AuraEnabled public List<ProgramOutcomeCol> programOutcomes;
        @AuraEnabled public Map<String, Integer>    weightMap;           // 'coId__poId' → weight
        @AuraEnabled public Decimal                 completeness;        // 0–100
        @AuraEnabled public String                  studyProgramVersionId;
    }

    public class CourseOutcomeRow {
        @AuraEnabled public String id;
        @AuraEnabled public String code;         // e.g. CO1
        @AuraEnabled public String description;
        @AuraEnabled public String btLevel;
    }

    public class ProgramOutcomeCol {
        @AuraEnabled public String id;
        @AuraEnabled public String code;         // e.g. PO1
        @AuraEnabled public String description;
    }

    public class MappingEntry {
        @AuraEnabled public String  courseOutcomeId;
        @AuraEnabled public String  programOutcomeId;
        @AuraEnabled public Integer weight;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // getMappingData
    // ─────────────────────────────────────────────────────────────────────────

    @AuraEnabled(cacheable=true)
    public static COPOMappingData getMappingData(String studyUnitVersionId) {
        try {
            COPOMappingData result = new COPOMappingData();

            // 1. Course Outcomes — sorted by code (CO1, CO2 … CO10 …)
            List<reduivy__Course_Outcome__c> coList = [
                SELECT  Id,
                        Name,
                        reduivy__Course_Outcome_Code__c,
                        reduivy__Description__c,
                        reduivy__Blooms_Taxonomy_Level__c
                FROM    reduivy__Course_Outcome__c
                WHERE   reduivy__Study_Unit_Version__c = :studyUnitVersionId
                ORDER BY reduivy__Course_Outcome_Code__c ASC
            ];

            result.courseOutcomes = new List<CourseOutcomeRow>();
            for (reduivy__Course_Outcome__c co : coList) {
                CourseOutcomeRow row = new CourseOutcomeRow();
                row.id          = co.Id;
                row.code        = co.reduivy__Course_Outcome_Code__c;
                row.description = co.reduivy__Description__c;
                row.btLevel     = co.reduivy__Blooms_Taxonomy_Level__c;
                result.courseOutcomes.add(row);
            }

            // 2. Resolve Study Program Version from Study Unit Version
            reduivy__Study_Unit_Version__c suv = [
                SELECT Id, reduivy__Study_Program_Version__c
                FROM   reduivy__Study_Unit_Version__c
                WHERE  Id = :studyUnitVersionId
                LIMIT  1
            ];
            result.studyProgramVersionId = suv.reduivy__Study_Program_Version__c;

            // 3. Program Outcomes — sorted by code (PO1, PO2 … PO10 …)
            List<reduivy__Program_Outcome__c> poList = new List<reduivy__Program_Outcome__c>();
            if (suv.reduivy__Study_Program_Version__c != null) {
                poList = [
                    SELECT  Id,
                            Name,
                            reduivy__Program_Outcome_Code__c,
                            reduivy__Description__c
                    FROM    reduivy__Program_Outcome__c
                    WHERE   reduivy__Study_Program_Version__c = :suv.reduivy__Study_Program_Version__c
                    AND     reduivy__Is_Active__c = true
                    ORDER BY reduivy__Program_Outcome_Code__c ASC
                ];
            }

            result.programOutcomes = new List<ProgramOutcomeCol>();
            for (reduivy__Program_Outcome__c po : poList) {
                ProgramOutcomeCol col = new ProgramOutcomeCol();
                col.id          = po.Id;
                col.code        = po.reduivy__Program_Outcome_Code__c;
                col.description = po.reduivy__Description__c;
                result.programOutcomes.add(col);
            }

            // 4. Existing CO-PO weight records
            Set<Id> coIds = new Set<Id>();
            for (reduivy__Course_Outcome__c co : coList) coIds.add(co.Id);

            Set<Id> poIds = new Set<Id>();
            for (reduivy__Program_Outcome__c po : poList) poIds.add(po.Id);

            result.weightMap = new Map<String, Integer>();
            if (!coIds.isEmpty() && !poIds.isEmpty()) {
                for (reduivy__Course_Outcome_Program_Outcome__c m : [
                    SELECT  reduivy__Course_Outcome__c,
                            reduivy__Program_Outcome__c,
                            reduivy__Weight__c
                    FROM    reduivy__Course_Outcome_Program_Outcome__c
                    WHERE   reduivy__Course_Outcome__c  IN :coIds
                    AND     reduivy__Program_Outcome__c IN :poIds
                ]) {
                    String key = m.reduivy__Course_Outcome__c + '__' + m.reduivy__Program_Outcome__c;
                    result.weightMap.put(
                        key,
                        m.reduivy__Weight__c != null ? Integer.valueOf(m.reduivy__Weight__c) : 0
                    );
                }
            }

            // 5. Completeness
            result.completeness = computeCompleteness(
                result.weightMap, coList.size(), poList.size()
            );

            return result;

        } catch (Exception e) {
            throw new AuraHandledException('Error fetching mapping data: ' + e.getMessage());
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // saveMappingWeights
    // ─────────────────────────────────────────────────────────────────────────

    @AuraEnabled
    public static Decimal saveMappingWeights(String studyUnitVersionId, String entriesJson) {
        try {
            List<MappingEntry> entries = (List<MappingEntry>) JSON.deserialize(
                entriesJson, List<MappingEntry>.class
            );

            Set<Id> coIds = new Set<Id>();
            Set<Id> poIds = new Set<Id>();
            for (MappingEntry e : entries) {
                if (String.isNotBlank(e.courseOutcomeId))  coIds.add((Id) e.courseOutcomeId);
                if (String.isNotBlank(e.programOutcomeId)) poIds.add((Id) e.programOutcomeId);
            }

            // Load existing records
            Map<String, reduivy__Course_Outcome_Program_Outcome__c> existingMap =
                new Map<String, reduivy__Course_Outcome_Program_Outcome__c>();

            for (reduivy__Course_Outcome_Program_Outcome__c m : [
                SELECT  Id,
                        reduivy__Course_Outcome__c,
                        reduivy__Program_Outcome__c,
                        reduivy__Weight__c
                FROM    reduivy__Course_Outcome_Program_Outcome__c
                WHERE   reduivy__Course_Outcome__c  IN :coIds
                AND     reduivy__Program_Outcome__c IN :poIds
            ]) {
                existingMap.put(
                    m.reduivy__Course_Outcome__c + '__' + m.reduivy__Program_Outcome__c, m
                );
            }

            List<reduivy__Course_Outcome_Program_Outcome__c> toUpsert =
                new List<reduivy__Course_Outcome_Program_Outcome__c>();
            Map<String, Integer> weightMap = new Map<String, Integer>();

            for (MappingEntry entry : entries) {
                String key = entry.courseOutcomeId + '__' + entry.programOutcomeId;
                reduivy__Course_Outcome_Program_Outcome__c record =
                    existingMap.containsKey(key)
                        ? existingMap.get(key)
                        : new reduivy__Course_Outcome_Program_Outcome__c(
                            reduivy__Course_Outcome__c  = entry.courseOutcomeId,
                            reduivy__Program_Outcome__c = entry.programOutcomeId
                          );
                record.reduivy__Weight__c = entry.weight;
                toUpsert.add(record);
                weightMap.put(key, entry.weight);
            }

            upsert toUpsert;

            return computeCompleteness(weightMap, coIds.size(), poIds.size());

        } catch (Exception e) {
            throw new AuraHandledException('Error saving mapping: ' + e.getMessage());
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // addProgramOutcome
    // ─────────────────────────────────────────────────────────────────────────

    @AuraEnabled
    public static reduivy__Program_Outcome__c addProgramOutcome(
        String studyProgramVersionId,
        String name,
        String code,
        String description
    ) {
        try {
            reduivy__Program_Outcome__c po = new reduivy__Program_Outcome__c(
                Name                              = name,
                reduivy__Program_Outcome_Code__c  = code,
                reduivy__Description__c           = description,
                reduivy__Study_Program_Version__c = studyProgramVersionId,
                reduivy__Is_Active__c             = true
            );
            insert po;
            return po;
        } catch (Exception e) {
            throw new AuraHandledException('Error adding Program Outcome: ' + e.getMessage());
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // removeProgramOutcome
    // ─────────────────────────────────────────────────────────────────────────

    @AuraEnabled
    public static void removeProgramOutcome(String programOutcomeId) {
        try {
            List<reduivy__Course_Outcome_Program_Outcome__c> relatedMaps = [
                SELECT Id FROM reduivy__Course_Outcome_Program_Outcome__c
                WHERE  reduivy__Program_Outcome__c = :programOutcomeId
            ];
            if (!relatedMaps.isEmpty()) delete relatedMaps;

            update new reduivy__Program_Outcome__c(
                Id                    = programOutcomeId,
                reduivy__Is_Active__c = false
            );
        } catch (Exception e) {
            throw new AuraHandledException('Error removing Program Outcome: ' + e.getMessage());
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Helpers
    // ─────────────────────────────────────────────────────────────────────────

    private static Decimal computeCompleteness(
        Map<String, Integer> weightMap,
        Integer coCount,
        Integer poCount
    ) {
        if (coCount == 0 || poCount == 0) return 0;
        Integer total  = coCount * poCount;
        Integer filled = 0;
        for (Integer w : weightMap.values()) {
            if (w != null && w > 0) filled++;
        }
        return (Decimal.valueOf(filled) / Decimal.valueOf(total) * 100).setScale(1);
    }
}