/**
 * @author      WDCi (Lean)
 * @date        May 2024
 * @group       Study Session Scheduler
 * @description The study session scheduler filter controller
 * @changehistory
 * ISS-001920 14-05-2024 Lean - new class
 */
public inherited sharing class REDU_SessionFilterValue_OBJ {
    
    public String schedulingType;
    public Id educationalInstitutionId;
    public Id studyUnitId;
    public Id academicTermId;
    public Id studyOfferingId;
    public Id campusId;

    List<REDU_CustomFilter_OBJ> sessionFilter;
    List<REDU_CustomFilter_OBJ> facilityFilter;
    List<REDU_CustomFilter_OBJ> contactFilter;

    /**
     * @description Default constructor
     */
    REDU_SessionFilterValue_OBJ() {

    }

    /**
     * @description Return the bind params based on session filters
     * @return Map<String, Object>
     */
    public Map<String, Object> getSessionBindParams() {
        return generateBindParams(this.sessionFilter);
    }

    /**
     * @description Return the query binder based on session filters
     * @return List<String>
     */
    public List<String> getSessionQueryBinders() {
        return generateQueryBinders(this.sessionFilter);
    }

    /**
     * @description Return the bind params based on contact filters
     * @return Map<String, Object>
     */
    public Map<String, Object> getContactBindParams() {
        return generateBindParams(this.contactFilter);
    }

    /**
     * @description Return the query binder based on contact filters
     * @return List<String>
     */
    public List<String> getContactQueryBinders() {
        return generateQueryBinders(this.contactFilter);
    }

    /**
     * @description Return the bind params based on facility filters
     * @return Map<String, Object>
     */
    public Map<String, Object> getFacilityBindParams() {
        return generateBindParams(this.facilityFilter);
    }

    /**
     * @description Return the query binder based on facility filters
     * @return List<String>
     */
    public List<String> getFacilityQueryBinders() {
        return generateQueryBinders(this.facilityFilter);
    }

    /**
     * @description Generate bind params
     * @param customFilterConfigs
     * @return Map<String, Object>
     */
    public Map<String, Object> generateBindParams(List<REDU_CustomFilter_OBJ> customFilterConfigs) {
        Map<String, Object> bindParams = new Map<String, Object>();

        if (customFilterConfigs != null && !customFilterConfigs.isEmpty()) {
            for (REDU_CustomFilter_OBJ cf : customFilterConfigs) {
                if (cf.isValid()) {
                    bindParams.putAll(cf.getBindParams());
                }
            }
        }

        return bindParams;
    }

    /**
     * @description Generate query binders
     * @param customFilterConfigs
     * @return List<String>
     */
    public List<String> generateQueryBinders(List<REDU_CustomFilter_OBJ> customFilterConfigs) {

        List<String> binders = new List<String>();

        if (customFilterConfigs != null && !customFilterConfigs.isEmpty()) {
            for (REDU_CustomFilter_OBJ cf : customFilterConfigs) {
                if (cf.isValid()) {
                    binders.add(cf.getQueryBinder());
                }
            }
        }

        return binders;

    }

}