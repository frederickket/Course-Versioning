/**
 * @Author 		WDCi (XW)
 * @Date 		June 2025
 * @group 		Requirement Checklist
 * @Description Requirement Checklist component
 * @changehistory
 * ISS-002128 06-06-2025 XW - new class
 * ISS-002616 09-09-2025 XW - file is linked to the actual record instead of contact if checklist is in contact record page
 * ISS-002604 12-09-2025 Lean - fixed download url
 * ISS-002665 10-11-2025 XiRouh - Updated the RequirementWrapper to include the submission status type and updated the submission status type to be determined by custom metadata
 * ISS-002706 14-01-2026 XiRouh - Updated to calculate totalSubmitted, totalReviewed, and totalRequirements directly from the roll-up fields in IRS
 * ISS-002771 08-01-2026 XW - support showing requirement sets and requirement from child object,
 */

public with sharing class REDU_RequirementChecklist_LCTRL {

    static final String REQUEST_USERMODE_ADMIN = 'Admin';
    static final String REQUEST_USERMODE_FACULTY = 'Faculty';
    static final String REQUEST_USERMODE_STUDENT = 'Student';

    static final String RESPONSE_TOTAL_REQUIREMENTS_PARAM = 'totalRequirements';
    static final String RESPONSE_TOTAL_REVIEWED_PARAM = 'totalReviewed';
    static final String RESPONSE_TOTAL_SUBMITTED_PARAM = 'totalSubmitted';
    static final String RESPONSE_PARENT_IRS_DATA_PARAM = 'irsParentData';
    static final String RESPONSE_CHILD_IRS_DATA_PARAM = 'irsChildData';
    static final String RESPONSE_CHILD_LABEL_PARAM = 'irsChildRelationshipLabel';
    //ISS-002665 - To set the submission status based on the custom metadata configuration when the buttons are clicked in the requirement checklist wizard
    static final String RESPONSE_DEFAULT_SUBMITTED_STATUS_PARAM = 'defaultSubmittedStatus';

    static final Map<String, String> reviewStatusTypeMap = IRQ_Helper.getReviewStatusTypeMap();
    static final List<String> reviewedStatuses = IRQ_Helper.getReviewedStatuses();

    static final Map<String, String> submissionStatusTypeMap = IRQ_Helper.getSubmissionStatusTypeMap();
    static List<String> submittedStatuses = IRQ_Helper.getSubmissionSubmittedStatuses();

    static final Set<String> irsFields = new Set<String> {
        'Id',
        'Name',
        'reduivy__Study_Requirement_Set__r.reduivy__Object__c',
        'reduivy__Total_Requirement__c',
        'reduivy__Total_Reviewed__c',
        'reduivy__Total_Submitted__c',
        'reduivy__Total_Requirement_Faculty__c', //ISS-002706
        'reduivy__Total_Reviewed_Faculty__c', //ISS-002706
        'reduivy__Total_Submitted_Faculty__c', //ISS-002706
        'reduivy__Total_Requirement_Student__c', //ISS-002706
        'reduivy__Total_Reviewed_Student__c', //ISS-002706
        'reduivy__Total_Submitted_Student__c' //ISS-002706
    };

    static final Set<String> irqFields = new Set<String> {
        'Id',
        'reduivy__Review_Status__c',
        'reduivy__Submission_Status__c',
        'reduivy__File_Count__c',
        'reduivy__File_Category__c',
        'reduivy__File_Share_Type__c',
        'reduivy__File_Visibility__c',
        'reduivy__File_Format__c',
        'reduivy__Requirement_Type__c',
        'reduivy__Object_Fields__c',
        'reduivy__Object_Relation_Field__c',
        'reduivy__Individual_Requirement_Set__r.reduivy__Contact__c',
        'reduivy__Link_To_Individual_Achievement__c'
    };

    /**
     * @description get the related individual requirements of the parent record
     * @param  userMode                        The user mode of the requirement checklist comp. Admin, Faculty or Student
     * @param  requirementSetReferencedFields the individual requirement set title field api name to be displayed on the accordion
     * @param  requirementTitleField    the individual requirement title field api name to be displayed on the details
     * @param  recordId                        parent record id
     * @return                                 REDU_LightningResponse
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getIndividualRequirements(String userMode, List<String> requirementSetReferencedFields, String requirementTitleField, String recordId, String childrenRelationshipName, String language){

        try {
            //get all irs and related irq
            Map<String, Object> responseData = new Map<String, Object>();
            Map<String, Object> irsData = new Map<String, Object>();
            Set<String> irsVisibility = new Set<String>();
            List<RequirementSetWrapper> parentIrsWrapperList = new List<RequirementSetWrapper>();
            Map<Id, ChildRequirementSetWrapper> childrenWrapperMap = new Map<Id, ChildRequirementSetWrapper>();
            Decimal totalSubmitted = 0, totalReviewed = 0, totalRequirements = 0;
            String childrenRelationshipLabel;
            Set<Id> irqIdSet = new Set<Id>();
            if(String.isBlank(language)) {
                language = UserInfo.getLanguage();
            }

            if(String.isNotBlank(recordId) && String.isNotBlank(userMode)) {
                if(requirementSetReferencedFields != null && !requirementSetReferencedFields.isEmpty()) {
                    irsFields.addAll(requirementSetReferencedFields);
                }
                if(String.isNotBlank(requirementTitleField)) {
                    irqFields.add(requirementTitleField);
                }

                Set<String> allLookupFields = REDU_Metadata_UTIL.getLookupFieldsFromObject(IRS_Helper.getApiName());
                irsFields.addAll(allLookupFields);
                for(String lookupField : allLookupFields) {
                    irsFields.add(REDU_Metadata_UTIL.getReferenceFieldForQuery(lookupField, true));
                }

                Map<String, Schema.SObjectField> irsFieldsMap = SObjectType.reduivy__Individual_Requirement_Set__c.fields.getMap();

                Schema.SObjectType rootRecordObjectType = ((Id)recordId).getSobjectType();
                Schema.ChildRelationship childRelationship = getChildrenRelationshipInfo(childrenRelationshipName, rootRecordObjectType);

                List<String> relationshipFieldNameList = new List<String>();
                String parentField;

                for(String irsField : irsFieldsMap.keySet()) {
                    Schema.DescribeFieldResult dfr = irsFieldsMap.get(irsField).getDescribe();
                    List<Schema.SObjectType> getReferenceToList = dfr.getReferenceTo();
                    if(!getReferenceToList.isEmpty() && getReferenceToList[0] == rootRecordObjectType) {
                        parentField = dfr.getName();
                        relationshipFieldNameList.add(parentField);
                        break;
                    }
                }

                if(childRelationship != null) {
                    childrenRelationshipLabel = childRelationship.getChildSObject().getDescribe(Schema.SObjectDescribeOptions.DEFERRED).getLabelPlural();

                    for(String irsField : irsFieldsMap.keySet()) {
                        Schema.DescribeFieldResult dfr = irsFieldsMap.get(irsField).getDescribe();
                        List<Schema.SObjectType> getReferenceToList = dfr.getReferenceTo();
                        if(!getReferenceToList.isEmpty() && getReferenceToList[0] == childRelationship.getChildSObject()) {
                            relationshipFieldNameList.add(dfr.getRelationshipName() + '.' + childRelationship.getField().getDescribe().getName());
                        }
                    }
                }

                if(!relationshipFieldNameList.isEmpty()) {
                
                    List<String> relationshipFieldNameQueryList = new List<String>();
                                    
                    for(String relationshipFieldName : relationshipFieldNameList) {
                        relationshipFieldNameQueryList.add(relationshipFieldName + ' = :recordId');
                    }

                    String irsQuery = 'SELECT ' + String.join(irsFields, ', ') + ', ' + 
                                    ' ( ' +
                                    ' SELECT ' + String.join(irqFields, ', ') + 
                                    ' FROM reduivy__Individual_Requirements__r ' +
                                    ' WHERE reduivy__Status__c = :irqStatusActive ' + 
                                    ' AND reduivy__Requirement_Visibility__c IN :irsVisibility' + 
                                    ' ORDER BY reduivy__Sequence__c ASC NULLS LAST' +
                                    ' ) ' +
                                    ' FROM ' + IRS_Helper.getApiName() +
                                    ' WHERE reduivy__Status__c = :irsStatusActive' +
                                    ' AND (';
                    irsQuery += String.join(relationshipFieldNameQueryList, ' OR ');
                    irsQuery += ')';

                    Map<String, Object> irsBindMap = new Map<String, Object> {
                        'recordId' => recordId,
                        'irsVisibility' => irsVisibility,
                        'irsStatusActive' => IRS_Helper.STATUS_ACTIVE,
                        'irqStatusActive' => IRQ_Helper.STATUS_ACTIVE
                    };

                    //user mode
                    if(userMode == REQUEST_USERMODE_STUDENT) {
                        Contact studentContact = CON_Helper.getCurrentLoggedInUserContact();
                        if(studentContact != null) {
                            irsQuery += (' AND reduivy__Contact__c = :studentContact');
                            irsBindMap.put('studentContact', studentContact.Id);
                        }
                        irsVisibility.add(IRQ_Helper.REQUIREMENT_VISIBILITY_STUDENT);

                    } else if(userMode == REQUEST_USERMODE_FACULTY) {
                        
                        irsVisibility.add(IRQ_Helper.REQUIREMENT_VISIBILITY_FACULTY);
                        irsVisibility.add(IRQ_Helper.REQUIREMENT_VISIBILITY_STUDENT);

                    } else if(userMode == REQUEST_USERMODE_ADMIN) {

                        irsVisibility.add(IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN);
                        irsVisibility.add(IRQ_Helper.REQUIREMENT_VISIBILITY_FACULTY);
                        irsVisibility.add(IRQ_Helper.REQUIREMENT_VISIBILITY_STUDENT);

                    }
                    
                    List<reduivy__Individual_Requirement_Set__c> parentRequirementSets = new List<reduivy__Individual_Requirement_Set__c>();
                    List<reduivy__Individual_Requirement_Set__c> childRequirementSets = new List<reduivy__Individual_Requirement_Set__c>();
                    REDU_Logging_UTIL.debug('irsQuery', String.escapeSingleQuotes(irsQuery));
                    for(reduivy__Individual_Requirement_Set__c irs : (List<reduivy__Individual_Requirement_Set__c>) Database.queryWithBinds(String.escapeSingleQuotes(irsQuery), irsBindMap, AccessLevel.USER_MODE)) {

                        List<REDU_RequirementChecklist_LCTRL.RequirementWrapper> irqWrapperList = new List<REDU_RequirementChecklist_LCTRL.RequirementWrapper>();

                        // ISS-002706
                        if (userMode == REQUEST_USERMODE_STUDENT) {
                            totalSubmitted += (irs.reduivy__Total_Submitted_Student__c != null ? irs.reduivy__Total_Submitted_Student__c : 0);
                            totalReviewed += (irs.reduivy__Total_Reviewed_Student__c != null ? irs.reduivy__Total_Reviewed_Student__c : 0);
                            totalRequirements += (irs.reduivy__Total_Requirement_Student__c != null ? irs.reduivy__Total_Requirement_Student__c : 0);

                        } else if (userMode == REQUEST_USERMODE_FACULTY) {
                            totalSubmitted += (irs.reduivy__Total_Submitted_Faculty__c != null ? irs.reduivy__Total_Submitted_Faculty__c : 0);
                            totalReviewed += (irs.reduivy__Total_Reviewed_Faculty__c != null ? irs.reduivy__Total_Reviewed_Faculty__c : 0);
                            totalRequirements += (irs.reduivy__Total_Requirement_Faculty__c != null ? irs.reduivy__Total_Requirement_Faculty__c : 0);

                        } else if (userMode == REQUEST_USERMODE_ADMIN) {
                            totalSubmitted += (irs.reduivy__Total_Submitted__c != null ? irs.reduivy__Total_Submitted__c : 0);
                            totalReviewed += (irs.reduivy__Total_Reviewed__c != null ? irs.reduivy__Total_Reviewed__c : 0);
                            totalRequirements += (irs.reduivy__Total_Requirement__c != null ? irs.reduivy__Total_Requirement__c : 0);
                        }

                        for(reduivy__Individual_Requirement__c irq : irs.reduivy__Individual_Requirements__r) {
                            irqIdSet.add(irq.Id);

                            Map<String, Object> requirementInfo = getRequirementInfo(irq);
                            
                            String reviewStatusType = String.valueOf(requirementInfo.get('reviewStatusType'));
                            String submissionStatusType = String.valueOf(requirementInfo.get('submissionStatusType'));

                            REDU_RequirementChecklist_LCTRL.RequirementWrapper newIrqWrapper = new REDU_RequirementChecklist_LCTRL.RequirementWrapper(irq, reviewStatusType, submissionStatusType);
                            irqWrapperList.add(newIrqWrapper);
                        }

                        String lookupFieldName = REDU_Metadata_UTIL.getObjectLookupField(IRS_Helper.getApiName(), irs.reduivy__Study_Requirement_Set__r.reduivy__Object__c);

                        if (String.isNotBlank(lookupFieldName)) {
                            Id parentId = (Id) irs.get(lookupFieldName);
                            RequirementSetWrapper newIrsWrapper = new RequirementSetWrapper(irs, irqWrapperList, parentId);

                            if(parentId == recordId) {
                                parentIrsWrapperList.add(newIrsWrapper);
                            } else {
                                if(!childrenWrapperMap.containsKey(parentId)) {

                                    String lookupRelationName = lookupFieldName.endsWith('__c') ? lookupFieldName.removeEnd('__c') + '__r' : lookupFieldName.removeEnd('Id');
                                    SObject childRecord = irs.getSObject(lookupRelationName);

                                    childrenWrapperMap.put(parentId, new ChildRequirementSetWrapper(new List<RequirementSetWrapper>(), childRecord));
                                }
                                childrenWrapperMap.get(parentId).irsWrapperList.add(newIrsWrapper);
                            }
                            
                        } else {
                            String errMsg = String.format(Label.Invalid_Relationship_Field_Error, new List<String>{IRS_Helper.getObjectLabel(), irs.reduivy__Study_Requirement_Set__r.reduivy__Object__c});
                            throw new REDU_ApplicationException(errMsg);
                        }
                    }
                }
            }
            responseData.put(RESPONSE_PARENT_IRS_DATA_PARAM, parentIrsWrapperList);
            responseData.put(RESPONSE_CHILD_IRS_DATA_PARAM, childrenWrapperMap.values());
            responseData.put(RESPONSE_CHILD_LABEL_PARAM, childrenRelationshipLabel);
            responseData.put(RESPONSE_TOTAL_SUBMITTED_PARAM, totalSubmitted ?? 0);
            responseData.put(RESPONSE_TOTAL_REVIEWED_PARAM, totalReviewed ?? 0);
            responseData.put(RESPONSE_TOTAL_REQUIREMENTS_PARAM, totalRequirements ?? 0);
            responseData.put(RESPONSE_DEFAULT_SUBMITTED_STATUS_PARAM, submittedStatuses?.get(0));
            responseData.put(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM, getTranslationInfo(irqIdSet, irsFields, irqFields, language));

            return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(responseData));

        } catch (QueryException qex) {
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    private static Schema.ChildRelationship getChildrenRelationshipInfo(String childrenRelationshipName, Schema.SObjectType rootObjectType){

        if(String.isNotBlank(childrenRelationshipName) && rootObjectType != null) {
            List<String> childrenRelationshipNameList = childrenRelationshipName.split(REDU_List_UTIL.DELIMITER);
            List<Schema.ChildRelationship> childrenRelationshipList = rootObjectType.getDescribe(Schema.SObjectDescribeOptions.DEFERRED).getChildRelationships();
            
            for(Schema.ChildRelationship childRelationship : childrenRelationshipList) {
                if(childRelationship.getRelationshipName() == childrenRelationshipName) {
                    return childRelationship;
                }
            }
            
        }
        return null;
            
            
    }

    //get the info needed for the requirement
    public static Map<String, Object> getRequirementInfo(reduivy__Individual_Requirement__c irq) {
        String reviewStatusType = getIrsStatusType(irq.reduivy__Review_Status__c);
        String finalReviewStatusType; 

        String submissionStatusType = getIrsSubmissionStatusType(irq.reduivy__Submission_Status__c);

        //calculate reviewed and submitted
        if (reviewStatusType == IRQ_Helper.REVIEW_STATUS_TYPE_CANCELLED) {
            //we do not count cancelled requirement
            finalReviewStatusType = reviewStatusType;

        } else {

            if (reviewStatusType == IRQ_Helper.REVIEW_STATUS_TYPE_REJECTED ||
                reviewStatusType == IRQ_Helper.REVIEW_STATUS_TYPE_ACCEPTED ||
                reviewStatusType == IRQ_Helper.REVIEW_STATUS_TYPE_REVIEWING
            ) {
                finalReviewStatusType = reviewStatusType;
            } else {
                if (submittedStatuses.contains(irq.reduivy__Submission_Status__c)) {
                    finalReviewStatusType = IRQ_Helper.REVIEW_STATUS_TYPE_SUBMITTED;
                } else {
                    finalReviewStatusType = IRQ_Helper.REVIEW_STATUS_TYPE_OPEN;
                }
            }
        }
        

        Map<String, Object> requirementInfo = new Map<String, Object>{
            'reviewStatusType' => finalReviewStatusType,
            'submissionStatusType' => submissionStatusType
        };

        return requirementInfo;
    }

    /**
     * @description Return community info
     */
    @AuraEnabled(cacheable = true)
    public static REDU_LightningResponse getCommunityInfo(){
        try {
            
            REDU_LightningResponse response = new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(ORG_Helper.getCommunityInfo()));

            return response;

        } catch (QueryException qex){
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp){
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    /**
     * @description get the review status type used in requirement checklist
     * @param  reviewStatus the review status of the individual requirement
     * @return              review status type
     */
    static String getIrsStatusType(String reviewStatus) {
        return reviewStatusTypeMap.containsKey(reviewStatus) ? reviewStatusTypeMap.get(reviewStatus) : IRQ_Helper.REVIEW_STATUS_TYPE_OPEN;
    }

    /**
     * @description get the submission status type used in requirement checklist
     * @param  submissionStatus the submission status of the individual requirement
     * @return              submission status type
     */
    static String getIrsSubmissionStatusType(String submissionStatus) {
        return submissionStatusTypeMap.containsKey(submissionStatus) ? submissionStatusTypeMap.get(submissionStatus) : '';
    }

    static Map<String, Object> getTranslationInfo(Set<Id> irqIdSet, Set<String> irsFields, Set<String> irqFields, String language){

        Set<String> fields = new Set<String>(irqFields);
        for(String irsField : irsFields) {
            fields.add('reduivy__Individual_Requirement_Set__r.' + irsField);
        }

        return REDU_TranslationManager.getTranslationInfo(
            IRQ_Helper.getApiName(),
            irqIdSet,
            fields,
            language
        );
    }

    public class ChildRequirementSetWrapper {
        public List<RequirementSetWrapper> irsWrapperList;
        public SObject childRecord;

        public ChildRequirementSetWrapper(List<RequirementSetWrapper> irsWrapperList, SObject childRecord) {
            this.irsWrapperList = irsWrapperList;
            this.childRecord = childRecord;
        }

    }

    /**
     * @description Wrapper of the individual requirement set
     */
    public class RequirementSetWrapper {

        /**
         * @param  irs            Raw data of the individual requirement set
         */
        public reduivy__Individual_Requirement_Set__c irs;
        
        /**
         * @param  irqWrapperList List of wrapper of the children individual requirement 
         */
        public List<RequirementWrapper> irqWrapperList;
        
        /**
         * @param  parentId       The parent id of the Individual requirement set
         */
        public Id parentId;

        public RequirementSetWrapper(reduivy__Individual_Requirement_Set__c irs, List<RequirementWrapper> irqWrapperList, Id parentId) {
            this.irs = irs;
            this.irqWrapperList = irqWrapperList;
            this.parentId = parentId;
        }
    }

    /**
     * @description Wrapper of the individual requirement
     */
    public class RequirementWrapper {
        
        /**
         * @param  irq  Raw data of the individual requirement
         */
        public reduivy__Individual_Requirement__c irq;

        /**
         * @param  reviewStatusType review type of review status
         */
        public String reviewStatusType;

        /**
         * @param  submissionStatusType type of submmission status
         */
        public String submissionStatusType;
        
        public RequirementWrapper(reduivy__Individual_Requirement__c irq, String reviewStatusType, String submissionStatusType) {
            this.irq = irq;
            this.reviewStatusType = reviewStatusType;
            this.submissionStatusType = submissionStatusType;
        }
    }

}