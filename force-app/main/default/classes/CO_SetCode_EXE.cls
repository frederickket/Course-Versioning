/**
 * @author      RIO Education
 * @date        2026
 * @group       Trigger Executable
 * @description Assigns and renumbers Course_Outcome_Code__c (CO-001, CO-002, …)
 *              scoped per Study_Unit_Version__c.
 *              On insert : assigns the next sequential code within the same study unit.
 *              On delete : renumbers all remaining COs for the affected study units.
 */
public with sharing class CO_SetCode_EXE {

    private static final String  PREFIX = 'CO-';
    private static final Integer DIGITS = 3;

    // ─── Before Insert ────────────────────────────────────────────────────────

    public static void onBeforeInsert(List<Course_Outcome__c> newCOs) {
        Set<Id>  parentIds     = new Set<Id>();
        Boolean  hasNullParent = false;
        for (Course_Outcome__c co : newCOs) {
            if (co.Study_Unit_Version__c != null) {
                parentIds.add(co.Study_Unit_Version__c);
            } else {
                hasNullParent = true;
            }
        }

        Map<Id, Integer> maxByParent     = queryMaxByParent(parentIds, hasNullParent);
        Map<Id, Integer> counterByParent = new Map<Id, Integer>();

        for (Course_Outcome__c co : newCOs) {
            Id parentId = co.Study_Unit_Version__c;
            if (!counterByParent.containsKey(parentId)) {
                counterByParent.put(parentId, maxByParent.containsKey(parentId) ? maxByParent.get(parentId) : 0);
            }
            Integer next = counterByParent.get(parentId) + 1;
            counterByParent.put(parentId, next);
            co.Course_Outcome_Code__c = formatCode(next);
        }
    }

    // ─── After Delete ─────────────────────────────────────────────────────────

    public static void onAfterDelete(List<Course_Outcome__c> deletedCOs) {
        Set<Id>  parentIds     = new Set<Id>();
        Boolean  hasNullParent = false;
        for (Course_Outcome__c co : deletedCOs) {
            if (co.Study_Unit_Version__c != null) {
                parentIds.add(co.Study_Unit_Version__c);
            } else {
                hasNullParent = true;
            }
        }

        List<Course_Outcome__c> remaining = queryRemaining(parentIds, hasNullParent);

        // Group by parent (null is a valid Map key in Apex)
        Map<Id, List<Course_Outcome__c>> byParent = new Map<Id, List<Course_Outcome__c>>();
        for (Course_Outcome__c co : remaining) {
            Id key = co.Study_Unit_Version__c;
            if (!byParent.containsKey(key)) byParent.put(key, new List<Course_Outcome__c>());
            byParent.get(key).add(co);
        }

        // Renumber each group 1..N in their current sorted order
        List<Course_Outcome__c> toUpdate = new List<Course_Outcome__c>();
        for (Id parentId : byParent.keySet()) {
            List<Course_Outcome__c> coGroup = byParent.get(parentId);
            for (Integer i = 0; i < coGroup.size(); i++) {
                String expected = formatCode(i + 1);
                if (coGroup[i].Course_Outcome_Code__c != expected) {
                    coGroup[i].Course_Outcome_Code__c = expected;
                    toUpdate.add(coGroup[i]);
                }
            }
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    // ─── Private helpers ──────────────────────────────────────────────────────

    private static Map<Id, Integer> queryMaxByParent(Set<Id> parentIds, Boolean hasNullParent) {
        Map<Id, Integer>        result   = new Map<Id, Integer>();
        List<Course_Outcome__c> existing = new List<Course_Outcome__c>();

        if (!parentIds.isEmpty() && hasNullParent) {
            existing = [SELECT Course_Outcome_Code__c, Study_Unit_Version__c FROM Course_Outcome__c
                        WHERE  Study_Unit_Version__c IN :parentIds OR Study_Unit_Version__c = null];
        } else if (!parentIds.isEmpty()) {
            existing = [SELECT Course_Outcome_Code__c, Study_Unit_Version__c FROM Course_Outcome__c
                        WHERE  Study_Unit_Version__c IN :parentIds];
        } else if (hasNullParent) {
            existing = [SELECT Course_Outcome_Code__c, Study_Unit_Version__c FROM Course_Outcome__c
                        WHERE  Study_Unit_Version__c = null];
        }

        for (Course_Outcome__c co : existing) {
            Id      key = co.Study_Unit_Version__c;
            Integer num = parseCode(co.Course_Outcome_Code__c);
            if (!result.containsKey(key) || num > result.get(key)) {
                result.put(key, num);
            }
        }
        return result;
    }

    private static List<Course_Outcome__c> queryRemaining(Set<Id> parentIds, Boolean hasNullParent) {
        if (!parentIds.isEmpty() && hasNullParent) {
            return [SELECT Id, Course_Outcome_Code__c, Study_Unit_Version__c FROM Course_Outcome__c
                    WHERE  Study_Unit_Version__c IN :parentIds OR Study_Unit_Version__c = null
                    ORDER BY Course_Outcome_Code__c ASC NULLS LAST];
        } else if (!parentIds.isEmpty()) {
            return [SELECT Id, Course_Outcome_Code__c, Study_Unit_Version__c FROM Course_Outcome__c
                    WHERE  Study_Unit_Version__c IN :parentIds
                    ORDER BY Course_Outcome_Code__c ASC NULLS LAST];
        } else if (hasNullParent) {
            return [SELECT Id, Course_Outcome_Code__c, Study_Unit_Version__c FROM Course_Outcome__c
                    WHERE  Study_Unit_Version__c = null
                    ORDER BY Course_Outcome_Code__c ASC NULLS LAST];
        }
        return new List<Course_Outcome__c>();
    }

    private static Integer parseCode(String code) {
        if (String.isBlank(code) || !code.startsWith(PREFIX)) return 0;
        try {
            return Integer.valueOf(code.substring(PREFIX.length()));
        } catch (Exception e) {
            return 0;
        }
    }

    private static String formatCode(Integer seq) {
        String n = String.valueOf(seq);
        while (n.length() < DIGITS) n = '0' + n;
        return PREFIX + n;
    }
}
