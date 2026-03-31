/**
 * @author      RIO Education
 * @date        2026
 * @group       Trigger Executable
 * @description Assigns and renumbers Program_Outcome_Code__c (PO-001, PO-002, …)
 *              scoped per Study_Plan__c.
 *              On insert : assigns the next sequential code within the same study plan.
 *              On delete : renumbers all remaining POs for the affected study plans.
 */
public with sharing class PO_SetCode_EXE {

    private static final String  PREFIX = 'PO-';
    private static final Integer DIGITS = 3;

    // ─── Before Insert ────────────────────────────────────────────────────────

    public static void onBeforeInsert(List<Program_Outcome__c> newPOs) {
        Set<Id>  parentIds     = new Set<Id>();
        Boolean  hasNullParent = false;
        for (Program_Outcome__c po : newPOs) {
            if (po.Study_Plan__c != null) {
                parentIds.add(po.Study_Plan__c);
            } else {
                hasNullParent = true;
            }
        }

        Map<Id, Integer> maxByParent     = queryMaxByParent(parentIds, hasNullParent);
        Map<Id, Integer> counterByParent = new Map<Id, Integer>();

        for (Program_Outcome__c po : newPOs) {
            Id parentId = po.Study_Plan__c;
            if (!counterByParent.containsKey(parentId)) {
                counterByParent.put(parentId, maxByParent.containsKey(parentId) ? maxByParent.get(parentId) : 0);
            }
            Integer next = counterByParent.get(parentId) + 1;
            counterByParent.put(parentId, next);
            po.Program_Outcome_Code__c = formatCode(next);
        }
    }

    // ─── After Delete ─────────────────────────────────────────────────────────

    public static void onAfterDelete(List<Program_Outcome__c> deletedPOs) {
        Set<Id>  parentIds     = new Set<Id>();
        Boolean  hasNullParent = false;
        for (Program_Outcome__c po : deletedPOs) {
            if (po.Study_Plan__c != null) {
                parentIds.add(po.Study_Plan__c);
            } else {
                hasNullParent = true;
            }
        }

        List<Program_Outcome__c> remaining = queryRemaining(parentIds, hasNullParent);

        // Group by parent (null is a valid Map key in Apex)
        Map<Id, List<Program_Outcome__c>> byParent = new Map<Id, List<Program_Outcome__c>>();
        for (Program_Outcome__c po : remaining) {
            Id key = po.Study_Plan__c;
            if (!byParent.containsKey(key)) byParent.put(key, new List<Program_Outcome__c>());
            byParent.get(key).add(po);
        }

        // Renumber each group 1..N in their current sorted order
        List<Program_Outcome__c> toUpdate = new List<Program_Outcome__c>();
        for (Id parentId : byParent.keySet()) {
            List<Program_Outcome__c> poGroup = byParent.get(parentId);
            for (Integer i = 0; i < poGroup.size(); i++) {
                String expected = formatCode(i + 1);
                if (poGroup[i].Program_Outcome_Code__c != expected) {
                    poGroup[i].Program_Outcome_Code__c = expected;
                    toUpdate.add(poGroup[i]);
                }
            }
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    // ─── Private helpers ──────────────────────────────────────────────────────

    private static Map<Id, Integer> queryMaxByParent(Set<Id> parentIds, Boolean hasNullParent) {
        Map<Id, Integer>         result   = new Map<Id, Integer>();
        List<Program_Outcome__c> existing = new List<Program_Outcome__c>();

        if (!parentIds.isEmpty() && hasNullParent) {
            existing = [SELECT Program_Outcome_Code__c, Study_Plan__c FROM Program_Outcome__c
                        WHERE  Study_Plan__c IN :parentIds OR Study_Plan__c = null];
        } else if (!parentIds.isEmpty()) {
            existing = [SELECT Program_Outcome_Code__c, Study_Plan__c FROM Program_Outcome__c
                        WHERE  Study_Plan__c IN :parentIds];
        } else if (hasNullParent) {
            existing = [SELECT Program_Outcome_Code__c, Study_Plan__c FROM Program_Outcome__c
                        WHERE  Study_Plan__c = null];
        }

        for (Program_Outcome__c po : existing) {
            Id      key = po.Study_Plan__c;
            Integer num = parseCode(po.Program_Outcome_Code__c);
            if (!result.containsKey(key) || num > result.get(key)) {
                result.put(key, num);
            }
        }
        return result;
    }

    private static List<Program_Outcome__c> queryRemaining(Set<Id> parentIds, Boolean hasNullParent) {
        if (!parentIds.isEmpty() && hasNullParent) {
            return [SELECT Id, Program_Outcome_Code__c, Study_Plan__c FROM Program_Outcome__c
                    WHERE  Study_Plan__c IN :parentIds OR Study_Plan__c = null
                    ORDER BY Program_Outcome_Code__c ASC NULLS LAST];
        } else if (!parentIds.isEmpty()) {
            return [SELECT Id, Program_Outcome_Code__c, Study_Plan__c FROM Program_Outcome__c
                    WHERE  Study_Plan__c IN :parentIds
                    ORDER BY Program_Outcome_Code__c ASC NULLS LAST];
        } else if (hasNullParent) {
            return [SELECT Id, Program_Outcome_Code__c, Study_Plan__c FROM Program_Outcome__c
                    WHERE  Study_Plan__c = null
                    ORDER BY Program_Outcome_Code__c ASC NULLS LAST];
        }
        return new List<Program_Outcome__c>();
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
