/**
 * @author      WDCi (Lean)
 * @date        March 2023
 * @group       Test
 * @description Test data factory with the @isTest annotation. This can also be used to generate sample data for manual testing/demo.
 * @changehistory
 * ISS-001591 30-03-2023 Lean - new class
 * ISS-001992 29-07-2024 XiRouh - added new object (Contact Availability, Qualified Faculty, Contact Association, Study Voucher, Holiday, Facility Availability, and other Study Fee management objects)
 * ISS-002155 31-12-2024 XW - made COM103 requirement: unit enrolled >= 2
 * ISS-002089 12-03-2025 XW - assign student id and create student id system variable
 * ISS-002486 10-06-2025 XiRouh - Updated the studyGradingScheme  to use getCompletedPassStatuses() and getCompletedFailStatuses() accordingly
 * ISS-002486 11-06-2025 XiRouh - Updated to create individual grades based on the number of study grade period settings
 * ISS-002587 18-08-2025 XiRouh - Added muteTriggers when creating transaction related records
 * ISS-002743 15-12-2025 XiRouh - Updated to create the Master IPE first, and then create the child IPE. This fixes the issue where the child IPE did not have an IPF during creation, which caused the IPS Unit not to be created
 * ISS-002784 28-01-2026 Lean - Make exclude gpa enabled by default
 * ISS-002633 03-02-2026 XW - added new study requirement set and requirement for individual achievement and achievement units
 */
global inherited sharing class REDU_TestData_FACTORY {
    
    /**
     * @description Admin user with REDU_Admin permission set for testing as admin
     */
    private User reduAdminUser;

    /**
     * @description Faculty user with REDU_Faculty permission set for testing as faculty
     */
    private User reduFacultyUser;

    /**
     * @description Setup user for creating "setup" object as salesforce doesn't allow dml on non-setup object (perm set) after performing dml on setup object (custom setting)
     */
    private User setupUser;

    public Account eduInst {set; get;}
    public Map<String, Account> departments {set; get;}
    public Map<String, Account> campuses {set; get;}
    public Map<String, Account> extEduInsts {set; get;}
    public Map<String, Account> bizOrgs {set; get;}

    public Map<String, reduivy__Holiday__c> holidays {set; get;}

    public Map<String, reduivy__Study_Voucher__c> studyVouchers {set; get;}

    public Map<String, reduivy__Study_Funding__c> studyFundings {set; get;}

    public Map<String, reduivy__Study_Fee__c> studyFees {set; get;}
    public Map<String, reduivy__Study_Fee_Config__c> studyFeeConfigs {set; get;}
    public Map<String, reduivy__Study_Fee_Matrix__c> studyFeeMatrix {set; get;}

    public Map<String, reduivy__System_Variable__c> systemVariables {set; get;}

    public Map<String, Account> studentAdminstratives {set; get;}
    public Map<String, Contact> students {set; get;}
    public Map<String, User> studentUsers {set; get;}

    public Map<String, reduivy__Individual_Funding_Allocation__c> idvFundingAllocation {set; get;}

    public Map<String, Account> facultyAdminstratives {set; get;}
    public Map<String, Contact> faculties {set; get;}
    public List<Contact> facultiesSequenceList {set; get;}
    public Map<String, User> facultyUsers {set; get;}

    public Map<String, reduivy__Qualified_Faculty__c> qualifiedFaculty {set; get;}
    public Map<String, reduivy__Contact_Availability__c> contactAvailability {set; get;}
    public Map<String, reduivy__Contact_Association__c> contactAssociation {set; get;}

    public Map<String, reduivy__Agreement__c> agreements {set; get;}
    public Map<String, reduivy__Agreement_Recognition_Unit__c> agreementRecognitionUnits {set; get;}
    public Map<String, reduivy__Agreement_Unit_Equivalent__c> agreementUnitEquavalents {set; get;}
    public Map<String, reduivy__Agreement_Recognition__c> agreementRecognitions {set; get;}

    public Map<String, reduivy__Facility__c> facilities {set; get;}
    public Map<String, reduivy__Facility__c> subFacilities {set; get;}

    public Map<String, reduivy__Facility_Availability__c> facilityAvailability {set; get;}

    public Map<String, reduivy__Study_Grade_Setting__c> studyGradeSettings {set; get;}
    public Map<String, reduivy__Study_Grading_Scheme__c> studyGradingScheme {set; get;}

    public Map<String, reduivy__Study_Unit__c> studyUnits {set; get;}
    public Map<String, reduivy__Study_Fee_Matrix_Item__c> studyFeeMatrixItems {set; get;}
    public Map<String, reduivy__Study_Unit_Requirement__c> studyUnitReqs {set; get;}
    public Map<String, reduivy__Study_Program__c> studyPrograms {set; get;}
    public Map<String, reduivy__Study_Plan__c> studyPlans {set; get;}
    public Map<String, reduivy__Study_Plan_Structure__c> groupStudyPlanStructures {set; get;}
    public Map<String, reduivy__Study_Plan_Structure__c> unitStudyPlanStructures {set; get;}
    public Map<String, reduivy__Study_Plan_Unit_Requirement__c> studyPlanUnitReqs {set; get;}
    public Map<String, reduivy__Study_Pathway__c> studyPathways {set; get;}
    public Map<String, reduivy__Study_Pathway_Term__c> studyPathwayTerms {set; get;}
    public Map<String, reduivy__Study_Pathway_Unit__c> studyPathwayUnits {set; get;}
    public Map<String, reduivy__Study_Plan_Option__c> studyPlanOptions {set; get;}
    public Map<String, reduivy__Study_Requirement_Set__c> studyRequirementSets {set; get;}
    public Map<String, reduivy__Study_Requirement__c> studyRequirements {set; get;}
    public Map<String, reduivy__Study_Scoring_Config__c> studyScoringConfigs {set; get;}
    public Map<String, reduivy__Study_Scoring_Criteria__c> studyScoringCriteria {set; get;}
    
    public Map<String, reduivy__Admission_Path__c> admissionPaths {set; get;}
    public Map<String, reduivy__Admission_Path_Option__c> admissionPathOptions {set; get;}
    public Map<String, reduivy__Study_Program_Admission_Path__c> studyProgramAdmissionPaths {set; get;}

    public Map<String, reduivy__Study_Term__c> academicYears {set; get;}
    public Map<String, reduivy__Study_Term__c> academicTerms {set; get;}
    public Map<String, reduivy__Study_Cohort_Enrollment__c> studyCohortEnrollments {set; get;}
    public Map<String, reduivy__Study_Intake__c> studyIntakes {set; get;}
    public Map<String, reduivy__Study_Intake_Group__c> studyIntakeGroups {set; get;}
    public Map<String, reduivy__Study_Offering__c> studyOfferings {set; get;}
    
    public Map<String, reduivy__Individual_Achievement__c> idvAchievement {set; get;}
    public Map<String, reduivy__Individual_Achievement_Unit__c> idvAchievementUnit {set; get;}
    public Map<String, reduivy__Individual_Program_Enrollment__c> masterProgramEnrollments {set; get;}
    public Map<String, reduivy__Individual_Program_Enrollment__c> childProgramEnrollments {set; get;}
    public Map<String, reduivy__Individual_Requirement_Set__c> individualRequirementSets {set; get;}
    public Map<String, reduivy__Individual_Requirement__c> individualRequirements {set; get;}
    public Map<String, reduivy__Individual_Score__c> individualScores {set; get;}
    public Map<String, reduivy__Individual_Score_Detail__c> individualScoreDetails {set; get;}

    public Map<String, reduivy__Individual_Program_Application__c> individualProgramApplicaitions {set; get;}

    public Map<String, reduivy__Credit_Transfer_Application__c> creditTransferApplications {set; get;}

    public Map<String, reduivy__Individual_Plan_Structure__c> ipsGroups {set; get;}
    public Map<String, reduivy__Individual_Plan_Structure__c> ipsUnits {set; get;}

    public Map<String, reduivy__Individual_Plan_Unit_Requirement__c> individualPlanUnitRequirements {set; get;}
    public Map<String, reduivy__Individual_Pathway__c> individualPathways {set; get;}
    public Map<String, reduivy__Individual_Enrollment__c> studentIndividualEnrollments {set; get;}
    public Map<String, reduivy__Individual_Enrollment__c> facultyIndividualEnrollments {set; get;}

    public Map<String, reduivy__Study_Session__c> studySessions {set; get;}
    public Map<String, reduivy__Study_Session_Time__c> studySessionTimes {set; get;}
    public Map<String, reduivy__Study_Event__c> studyEvents {set; get;}
    public Map<String, reduivy__Individual_Session_Enrollment__c> studentIndividualSessionEnrollments {set; get;}
    public Map<String, reduivy__Individual_Session_Enrollment__c> facultyIndividualSessionEnrollments {set; get;}
    public Map<String, reduivy__Study_Event_Relation__c> studentStudyEventRelations {set; get;}
    public Map<String, reduivy__Study_Event_Relation__c> facultyStudyEventRelations {set; get;}
    public Map<String, reduivy__Study_Event_Relation__c> facilityStudyEventRelations {set; get;}

    public Map<String, reduivy__Individual_Enrollment_Grade__c> individualEnrollmentGrades {set; get;}
    public Map<String, reduivy__Individual_Grade_Item__c> individualGradeItems {set; get;}
    public Map<String, reduivy__Study_Grade_Item__c> studyGradeItems {set; get;}
    public Map<String, reduivy__Study_Grade_Period_Setting__c> studyGradePeriodSettings {set; get;}

    public Map<String, reduivy__Individual_Academic_Profile__c> individualAcademicProfiles {set; get;}
    public Map<String, reduivy__Individual_Academic_Progress__c> individualAcademicProgress {set; get;}
    public Map<String, reduivy__Transaction_Order__c> transactionOrders {set; get;}
    public Map<String, reduivy__Transaction_Line_Item__c> transactionOrderLines {set; get;}
    public Map<String, reduivy__Study_Voucher_Transaction__c> studyVoucherTransaction {set; get;}
    public Map<String, reduivy__Transaction_Payment__c> transactionPayment {set; get;}
    public Map<String, reduivy__Transaction_Line_Item__c> transactionLineItemPaymentLine {set; get;}

    /**
     * @description Term dates
     */
    public Date mondayDate = Date.newInstance(2022, 2, 7); //mon

    public Date lastYearTerm1StartDate;
    public Date lastYearTerm1EndDate;

    public Date lastYearTerm2StartDate;
    public Date lastYearTerm2EndDate;

    public Date currentYearTerm1StartDate = System.today();
    public Date currentYearTerm1EndDate;

    public Date currentYearTerm2StartDate;
    public Date currentYearTerm2EndDate;

    public Date nextYearTerm1StartDate;
    public Date nextYearTerm1EndDate;

    public Date nextYearTerm2StartDate;
    public Date nextYearTerm2EndDate;

    public String CYTKey = 'CYT1'; //default to current year term 1 

    //individual enrollment for current term (link to the academic progress)
    public List<String> term1SunList = new List<String>{'BUS101', 'BUS102', 'BUS103', 'COM101'}; //for student completed year 1 and new student starting term 1
    public List<String> term2SunList = new List<String>{'BUS201', 'BUS202', 'MKT101', 'MKT102'}; //for student completed year 1
    public List<String> term3SunList = new List<String>{'MGT301', 'MGT302', 'ICT101', 'ICT102'}; //for student starting year 2

    public Map<Integer, List<String>> sunListByTermNo = new Map<Integer, List<String>>{
        1 => term1SunList,
        2 => term2SunList,
        3 => term3SunList
    };

    //study unit offered in current term and past term
    public Map<String, List<String>> termSunList;

    global Boolean FULLDATA = false;
    global static String FACILITY_SER = 'FACILITY_SER';
    global static String FACULTY_SER = 'FACULTY_SER';

    global REDU_TestData_FACTORY() {
        departments = new Map<String, Account>();
        campuses = new Map<String, Account>();
        extEduInsts = new Map<String, Account>();
        bizOrgs = new Map<String, Account>();

        holidays = new Map<String, reduivy__Holiday__c>();

        studyVouchers = new Map<String, reduivy__Study_Voucher__c>();

        studyFundings = new Map<String, reduivy__Study_Funding__c>();

        studyFees = new Map<String, reduivy__Study_Fee__c>();
        studyFeeConfigs = new Map<String, reduivy__Study_Fee_Config__c>();
        studyFeeMatrix = new Map<String, reduivy__Study_Fee_Matrix__c>();
        systemVariables = new Map<String, reduivy__System_Variable__c>();

        studentAdminstratives = new Map<String, Account>();
        students = new Map<String, Contact>();
        studentUsers = new Map<String, User>();

        idvFundingAllocation = new Map<String, reduivy__Individual_Funding_Allocation__c>();

        facultyAdminstratives = new Map<String, Account>();
        faculties = new Map<String, Contact>();
        facultiesSequenceList = new List<Contact>();
        facultyUsers = new Map<String, User>();

        qualifiedFaculty = new Map<String, reduivy__Qualified_Faculty__c>();
        contactAvailability = new Map<String, reduivy__Contact_Availability__c>(); 
        contactAssociation = new Map<String, reduivy__Contact_Association__c>();

        agreements = new Map<String, reduivy__Agreement__c>();
        agreementRecognitionUnits = new Map<String, reduivy__Agreement_Recognition_Unit__c>();
        agreementUnitEquavalents = new Map<String, reduivy__Agreement_Unit_Equivalent__c>();
        agreementRecognitions = new Map<String, reduivy__Agreement_Recognition__c>();

        facilities = new Map<String, reduivy__Facility__c>();
        subFacilities = new Map<String, reduivy__Facility__c>();
        facilityAvailability = new Map<String, reduivy__Facility_Availability__c>();

        studyGradeSettings = new Map<String, reduivy__Study_Grade_Setting__c>();
        studyGradingScheme = new Map<String, reduivy__Study_Grading_Scheme__c>();

        studyUnits = new Map<String, reduivy__Study_Unit__c>();
        studyUnitReqs = new Map<String, reduivy__Study_Unit_Requirement__c>();
        studyPrograms = new Map<String, reduivy__Study_Program__c>();

        studyFeeMatrixItems = new Map<String, reduivy__Study_Fee_Matrix_Item__c>();

        studyPlans = new Map<String, reduivy__Study_Plan__c>();
        groupStudyPlanStructures = new Map<String, reduivy__Study_Plan_Structure__c>();
        unitStudyPlanStructures = new Map<String, reduivy__Study_Plan_Structure__c>();
        studyPlanUnitReqs = new Map<String, reduivy__Study_Plan_Unit_Requirement__c>();
        studyPathways = new Map<String, reduivy__Study_Pathway__c>();
        studyPathwayTerms = new Map<String, reduivy__Study_Pathway_Term__c>();
        studyPathwayUnits = new Map<String, reduivy__Study_Pathway_Unit__c>();
        studyPlanOptions = new Map<String, reduivy__Study_Plan_Option__c>();
        studyRequirementSets = new Map<String, reduivy__Study_Requirement_Set__c>();
        studyRequirements = new Map<String, reduivy__Study_Requirement__c>();
        studyScoringConfigs = new Map<String, reduivy__Study_Scoring_Config__c>();
        studyScoringCriteria = new Map<String, reduivy__Study_Scoring_Criteria__c>();
        
        admissionPaths = new Map<String, reduivy__Admission_Path__c>();
        admissionPathOptions = new Map<String, reduivy__Admission_Path_Option__c>();
        studyProgramAdmissionPaths = new Map<String, reduivy__Study_Program_Admission_Path__c>();

        academicYears = new Map<String, reduivy__Study_Term__c>();
        academicTerms = new Map<String, reduivy__Study_Term__c>();
        studyCohortEnrollments = new Map<String, reduivy__Study_Cohort_Enrollment__c>();
        studyIntakes = new Map<String, reduivy__Study_Intake__c>();
        studyIntakeGroups = new Map<String, reduivy__Study_Intake_Group__c>();
        studyOfferings = new Map<String, reduivy__Study_Offering__c>();
        
        masterProgramEnrollments = new Map<String, reduivy__Individual_Program_Enrollment__c>();
        childProgramEnrollments = new Map<String, reduivy__Individual_Program_Enrollment__c>();
        idvAchievement = new Map<String, reduivy__Individual_Achievement__c>(); 
        idvAchievementUnit = new Map<String, reduivy__Individual_Achievement_Unit__c>(); 
        individualProgramApplicaitions = new Map<String, reduivy__Individual_Program_Application__c>();
        individualRequirementSets = new Map<String, reduivy__Individual_Requirement_Set__c>();
        individualRequirements = new Map<String, reduivy__Individual_Requirement__c>();
        individualScores = new Map<String, reduivy__Individual_Score__c>();
        individualScoreDetails = new Map<String, reduivy__Individual_Score_Detail__c>();

        creditTransferApplications = new Map<String, reduivy__Credit_Transfer_Application__c>();

        ipsGroups = new Map<String, reduivy__Individual_Plan_Structure__c>();
        ipsUnits = new Map<String, reduivy__Individual_Plan_Structure__c>();
        
        individualPlanUnitRequirements = new Map<String, reduivy__Individual_Plan_Unit_Requirement__c>();
        individualPathways = new Map<String, reduivy__Individual_Pathway__c>();
        studentIndividualEnrollments = new Map<String, reduivy__Individual_Enrollment__c>();
        facultyIndividualEnrollments = new Map<String, reduivy__Individual_Enrollment__c>();

        studySessions = new Map<String, reduivy__Study_Session__c>();
        studySessionTimes = new Map<String, reduivy__Study_Session_Time__c>();
        studyEvents = new Map<String, reduivy__Study_Event__c>();
        studentIndividualSessionEnrollments = new Map<String, reduivy__Individual_Session_Enrollment__c>();
        facultyIndividualSessionEnrollments = new Map<String, reduivy__Individual_Session_Enrollment__c>();
        studentStudyEventRelations = new Map<String, reduivy__Study_Event_Relation__c>();
        facultyStudyEventRelations = new Map<String, reduivy__Study_Event_Relation__c>();
        facilityStudyEventRelations = new Map<String, reduivy__Study_Event_Relation__c>();
        
        individualEnrollmentGrades = new Map<String, reduivy__Individual_Enrollment_Grade__c>();
        individualGradeItems = new Map<String, reduivy__Individual_Grade_Item__c>();
        studyGradeItems = new Map<String, reduivy__Study_Grade_Item__c>();
        studyGradePeriodSettings = new Map<String, reduivy__Study_Grade_Period_Setting__c>();
        
        individualAcademicProfiles = new Map<String, reduivy__Individual_Academic_Profile__c>();
        individualAcademicProgress = new Map<String, reduivy__Individual_Academic_Progress__c>();
        transactionOrders = new Map<String, reduivy__Transaction_Order__c>();
        transactionOrderLines = new Map<String, reduivy__Transaction_Line_Item__c>();
        studyVoucherTransaction = new Map<String, reduivy__Study_Voucher_Transaction__c>();
        transactionPayment = new Map<String, reduivy__Transaction_Payment__c>();
        transactionLineItemPaymentLine = new Map<String, reduivy__Transaction_Line_Item__c>();

        //We always start with current week monday, to make it as current year term 1
        Integer daysBetween = mondayDate.daysBetween(currentYearTerm1StartDate);
        Integer todayDateDayOfWeek = Math.mod(daysBetween, 7);

        if(todayDateDayOfWeek != 0) {
            currentYearTerm1StartDate = currentYearTerm1StartDate.addDays(-todayDateDayOfWeek);
        }
            
        currentYearTerm1EndDate = currentYearTerm1StartDate.addDays(137);
        currentYearTerm2StartDate = currentYearTerm1EndDate.addDays(31);
        currentYearTerm2EndDate = currentYearTerm2StartDate.addDays(137);
        
        lastYearTerm2EndDate = currentYearTerm1StartDate.addDays(-31);
        lastYearTerm2StartDate = lastYearTerm2EndDate.addDays(-137);
        
        lastYearTerm1EndDate = lastYearTerm2StartDate.addDays(-31);
        lastYearTerm1StartDate = lastYearTerm1EndDate.addDays(-137);
        
        nextYearTerm1StartDate = currentYearTerm2EndDate.addDays(31);
        nextYearTerm1EndDate = nextYearTerm1StartDate.addDays(137);
        nextYearTerm2StartDate = nextYearTerm1EndDate.addDays(31);
        nextYearTerm2EndDate = nextYearTerm2StartDate.addDays(137);

        termSunList = new Map<String, List<String>>();

        //this is to generate the sof for student starting y1t1 and y2t1
        List<String> combined = new List<String>();
        combined.addAll(term1SunList);
        combined.addAll(term3SunList);

        termSunList.put('PYT1', term1SunList);
        termSunList.put('PYT2', term2SunList);
        termSunList.put('CYT1', combined);

        // if (Test.isRunningTest()) {
        //     setupUser = getSetupUser();

        //     System.runAs(setupUser) {
        //         reduAdminUser = getReduAdminUser();
        //         reduFacultyUser = getReduFacultyUser();
        //     }
        // }
    }

    /**
     * @description Setup the default settings required
     */
    global void setupDefaultSettings() {
        muteTriggers();
        Id systemUserId = UserInfo.getUserId();

        if (Test.isRunningTest()) {
            initCustomSettings(systemUserId);
            User runningUser = getSetupUser();

            System.runAs(runningUser) {
                setupUserRole(systemUserId);
                
            }

        } else {
            setupUserRole(systemUserId);
            setupUserPermission(systemUserId);
            initCustomSettingsFuture(systemUserId);
        }

        unmuteTriggers();
    }

    /**
     * @description Setup current user role
     */
    public void setupUserRole(Id userId) {

        UserRole ur = new UserRole(Name = 'Unit Testing');

        REDU_SystemMode_UTIL.doInsert(new List<UserRole>{ur});
        REDU_SystemMode_UTIL.doUpdate(new List<User>{new User(Id = userId, UserRoleId = ur.Id)});
        
    }

    /**
     * @description Setup the current user with redu admin permission
     */
    public void setupUserPermission(Id userId) {
        REDU_SystemMode_UTIL.doInsert(REDU_TestData_UTIL.newPermissionSetAssignment(userId, new Set<String>{'REDU_Admin', 'REDU_Admin_Tabs', 'REDU_Admin_Unmanaged', 'REDU_Unit_Test'}));
    }

    /**
     * @description Initiate custom settings
     */
    global void initCustomSettings(Id defaultOwnerId) {

        createCustomSettings(defaultOwnerId);
    }

    /**
     * @description Initiate custom settings in async mode
     */
    @future
    global static void initCustomSettingsFuture(Id defaultOwnerId) {

        createCustomSettings(defaultOwnerId);
    }

    /**
     * @description Upsert RIO Education Ivy settings
     */
    public static void createCustomSettings(Id defaultOwnerId) {
        REDU_PostInstallation pi = new REDU_PostInstallation();
        reduivy__RIO_Education_Ivy_Settings__c settings = pi.initAppSetting(null);
        settings.SetupOwnerId = UserInfo.getOrganizationId();
        settings.reduivy__Debug_Mode__c = true;
        settings.reduivy__Default_Owner_Id__c = defaultOwnerId;
        settings.reduivy__Academic_Profile_Generation_Type__c = IPF_Helper.PROFILE_GEN_TYPE_BYIPE;
        settings.Exclude_GPA_For_Repeated_Unit__c = true; //ISS-002784
        
        REDU_SystemMode_UTIL.doUpsert(new List<reduivy__RIO_Education_Ivy_Settings__c>{settings});
    }

    /**
     * @description Return setup user without REDU permission set. A new user will be created if not found.
     * @return User
     */
    public User getSetupUser() {
        
        if (setupUser == null) {
            List<User> users = [SELECT Id, FirstName, LastName, ProfileId, Email, Username 
                FROM User 
                WHERE Email = 'rioed.ivysetup@redu.example'
                WITH SYSTEM_MODE
            ];

            if (users.isEmpty()) {
                setupUser = REDU_TestData_UTIL.newUser('RIO Ed', 'Ivy Setup', 'System Administrator Custom');
                REDU_SystemMode_UTIL.doInsert(new List<User>{setupUser});

            } else {
                setupUser = users.get(0);
            }
        }

        return setupUser;
    }

    /**
     * @description Default REDU Admin user with REDU permission set for testing. A new user will be created if not found.
     * @return User
     */
    public User getReduAdminUser() {

        if (reduAdminUser == null) {
            List<User> users = [SELECT Id, FirstName, LastName, ProfileId, Email, Username 
                FROM User 
                WHERE Email = 'rioed.ivyadmin@redu.example'
                WITH SYSTEM_MODE
            ];

            if (users.isEmpty()) {
                System.runAs(getSetupUser()) {
                    reduAdminUser = REDU_TestData_UTIL.newUser('RIO Ed', 'Ivy Admin', 'Standard User');

                    // UserRole needed because ReduAdminUser creates student/community users (Portal account owner must have a role)
                    UserRole reduAdminRole = new UserRole(Name = 'Redu Admin Role');
                    REDU_SystemMode_UTIL.doInsert(new List<UserRole>{reduAdminRole});

                    reduAdminUser.UserRoleId = reduAdminRole.Id;

                    REDU_SystemMode_UTIL.doInsert(new List<User>{reduAdminUser});

                    REDU_SystemMode_UTIL.doInsert(REDU_TestData_UTIL.newPermissionSetAssignment(reduAdminUser.Id, new Set<String>{'REDU_Admin', 'REDU_Admin_Tabs', 'REDU_Admin_Unmanaged', 'REDU_Unit_Test'}));
                }
            } else {
                reduAdminUser = users.get(0);
            }
        }

        return reduAdminUser;
    }

    /**
     * @description Default REDU Faculty user with REDU permission set for testing. A new user will be created if not found. This user doesn't have any session allocation. Use getAllocatedFacultyUser() if the one with allocation.
     * @return User
     */
    public User getReduFacultyUser() {

        if (reduFacultyUser == null) {
            List<User> users = [SELECT Id, FirstName, LastName, ProfileId, Email, Username, ContactId 
                FROM User 
                WHERE Email = 'rioed.ivyfaculty@redu.example'
                WITH SYSTEM_MODE
            ];

            if (users.isEmpty()) {
                System.runAs(getSetupUser()) {
                    reduFacultyUser = REDU_TestData_UTIL.newUser('RIO Ed', 'Ivy Faculty', 'REDU - Faculty');
                    REDU_SystemMode_UTIL.doInsert(new List<User>{reduFacultyUser});

                    REDU_SystemMode_UTIL.doInsert(REDU_TestData_UTIL.newPermissionSetAssignment(reduFacultyUser.Id, new Set<String>{'REDU_Faculty', 'REDU_Faculty_Unmanaged', 'REDU_Unit_Test'}));
                }
            } else {
                reduFacultyUser = users.get(0);
            }
        }

        return reduFacultyUser;
    }

    /**
     * @description Return faculty user with session allocation for testing
     * @return User
     */
    public User getAllocatedFacultyUser() {
        List<Contact> facultyContacts = [SELECT Id,
            reduivy__User__c,
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_FACULTY
            AND reduivy__Sample_Record_Code__c = 'kleeford@redu.example'
            AND reduivy__User__c != null
            WITH SYSTEM_MODE
            LIMIT 1
        ];

        User facultyUser = new User(Id = facultyContacts.get(0).reduivy__User__c, ContactId = facultyContacts.get(0).Id);

        return facultyUser;
    }

    /**
     * @description Return student for testing
     * @return User
     */
    public User getStudentUser() {
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c = 'sandydoe@redu.example'
            WITH SYSTEM_MODE
            LIMIT 1
        ];

        Contact student = studentContacts.get(0);

        User studentUser = [SELECT Id, ContactId, FirstName, LastName, Email
            FROM User 
            WHERE ContactId =: student.Id 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
            WITH SYSTEM_MODE
        ];

        return studentUser;
    }

    /**
     * @description Default method to initate full sample data for test classes
     */
    global void initSampleData() {
        initMasterData(null);
        initFacultyData(null, false);
        initOfferingData(null);
        initStudentData(null, false);
    }

    /**
     * @description Default method to initate full sample data for test classes
     * @param masterDataSkipAfter Object to skip after for master data
     * @param facultyDataSkipAfter Object to skip after for faculty data
     * @param offeringDataSkipAfter Object to skip after for offering data
     * @param studentDataSkipAfter Object to skip after for student data
     * @param enableFacultyUser Enable community user for faculty contact
     * @param enableStudentUser Enable community user for student contact
     */
    global void initSampleData(String masterDataSkipAfter, String facultyDataSkipAfter, String offeringDataSkipAfter, String studentDataSkipAfter, Boolean enableFacultyUser, Boolean enableStudentUser) {
        initMasterData(masterDataSkipAfter);
        initFacultyData(facultyDataSkipAfter, enableFacultyUser);
        initOfferingData(offeringDataSkipAfter);
        initStudentData(studentDataSkipAfter, enableStudentUser);
    }

    /**
     * @description Default method to initiate master data
     * @param skipAfterObject Object to skip
     */
    global void initMasterData(String skipAfterObject) {

        muteTriggers();

        //account hierarchy
        eduInst = REDU_TestData_UTIL.newEducationalInstitution('RIOUNI', 'RIO University', 'RIOUNI');
        REDU_SystemMode_UTIL.doInsert(new List<Account>{eduInst});

        departments.put('BUS', REDU_TestData_UTIL.newDepartment('BUS', eduInst.Id, 'Business Faculty', 'BUS'));
        departments.put('COM', REDU_TestData_UTIL.newDepartment('COM', eduInst.Id, 'Computer Science Faculty', 'COM'));

        campuses.put('SYDNEY', REDU_TestData_UTIL.newCampus('SYDNEY', eduInst.Id, 'Sydney Campus', 'SYDNEY', 'Australia/Sydney'));

        if (FULLDATA) {
            campuses.put('BRISBANE', REDU_TestData_UTIL.newCampus('BRISBANE', eduInst.Id, 'Brisbane Campus', 'BRISBANE', 'Australia/Brisbane'));
        }

        extEduInsts.put('EXTUNIT', REDU_TestData_UTIL.newExternalEducationalInstitution('EXTUNIT', 'Partner University', 'EXTUNIT'));

        bizOrgs.put('ACME', REDU_TestData_UTIL.newOrganization('ACME', 'Acme Company'));

        List<Account> masterAccounts = new List<Account>();
        masterAccounts.addAll(departments.values());
        masterAccounts.addAll(campuses.values());
        masterAccounts.addAll(extEduInsts.values());
        masterAccounts.addAll(bizOrgs.values());

        REDU_SystemMode_UTIL.doInsert(masterAccounts);

        if (validateCheckpoint(ACC_Helper.getApiName(), skipAfterObject)) {
            unmuteTriggers();
            unmuteRollup();
            return;
        }

        //Holiday
        Integer pastYear = lastYearTerm1StartDate.year();
        Integer currentYear = lastYearTerm1StartDate.year() + 1;
        Integer nextYear = lastYearTerm1StartDate.year() + 2;

        String pastYearStr = String.valueOf(pastYear);
        String currentYearStr = String.valueOf(currentYear);
        String nextYearStr = String.valueOf(nextYear);

        holidays.put('NEW_YEARS_DAY_' + pastYearStr, REDU_TestData_UTIL.newHoliday('NEW_YEARS_DAY_' + pastYearStr, 'NEW_YEARS_DAY_' + pastYearStr, eduInst.Id, Date.newInstance(pastYear, 01, 01), Date.newInstance(pastYear, 01, 01)));
        holidays.put('AUSTRALIA_DAY_' + pastYearStr, REDU_TestData_UTIL.newHoliday('AUSTRALIA_DAY_' + pastYearStr, 'AUSTRALIA_DAY_' + pastYearStr, eduInst.Id, Date.newInstance(pastYear, 01, 26), Date.newInstance(pastYear, 01, 26)));
        holidays.put('GOOD_FRIDAY_' + pastYearStr, REDU_TestData_UTIL.newHoliday('GOOD_FRIDAY_' + pastYearStr, 'GOOD_FRIDAY_' + pastYearStr, eduInst.Id, Date.newInstance(pastYear, 04, 02), Date.newInstance(pastYear, 04, 02)));
        holidays.put('ANZAC_DAY_' + pastYearStr, REDU_TestData_UTIL.newHoliday('ANZAC_DAY_' + pastYearStr, 'ANZAC_DAY_' + pastYearStr, eduInst.Id, Date.newInstance(pastYear, 04, 26), Date.newInstance(pastYear, 04, 26)));
        holidays.put('EASTER_MONDAY_' + pastYearStr, REDU_TestData_UTIL.newHoliday('EASTER_MONDAY_' + pastYearStr, 'EASTER_MONDAY_' + pastYearStr, eduInst.Id, Date.newInstance(pastYear, 04, 05), Date.newInstance(pastYear, 04, 05)));
        holidays.put('QUEENS_BIRTHDAY_' + pastYearStr, REDU_TestData_UTIL.newHoliday('QUEENS_BIRTHDAY_' + pastYearStr, 'QUEENS_BIRTHDAY_' + pastYearStr, eduInst.Id, Date.newInstance(pastYear, 06, 14), Date.newInstance(pastYear, 06, 14)));

        holidays.put('NEW_YEARS_DAY_' + currentYearStr, REDU_TestData_UTIL.newHoliday('NEW_YEARS_DAY_' + currentYearStr, 'NEW_YEARS_DAY_' + currentYearStr, eduInst.Id, Date.newInstance(currentYear, 01, 01), Date.newInstance(currentYear, 01, 01)));
        holidays.put('AUSTRALIA_DAY_' + currentYearStr, REDU_TestData_UTIL.newHoliday('AUSTRALIA_DAY_' + currentYearStr, 'AUSTRALIA_DAY_' + currentYearStr, eduInst.Id, Date.newInstance(currentYear, 01, 26), Date.newInstance(currentYear, 01, 26)));
        holidays.put('GOOD_FRIDAY_' + currentYearStr, REDU_TestData_UTIL.newHoliday('GOOD_FRIDAY_' + currentYearStr, 'GOOD_FRIDAY_' + currentYearStr, eduInst.Id, Date.newInstance(currentYear, 04, 02), Date.newInstance(currentYear, 04, 02)));
        holidays.put('ANZAC_DAY_' + currentYearStr, REDU_TestData_UTIL.newHoliday('ANZAC_DAY_' + currentYearStr, 'ANZAC_DAY_' + currentYearStr, eduInst.Id, Date.newInstance(currentYear, 04, 26), Date.newInstance(currentYear, 04, 26)));
        holidays.put('EASTER_MONDAY_' + currentYearStr, REDU_TestData_UTIL.newHoliday('EASTER_MONDAY_' + currentYearStr, 'EASTER_MONDAY_' + currentYearStr, eduInst.Id, Date.newInstance(currentYear, 04, 05), Date.newInstance(currentYear, 04, 05)));
        holidays.put('QUEENS_BIRTHDAY_' + currentYearStr, REDU_TestData_UTIL.newHoliday('QUEENS_BIRTHDAY_' + currentYearStr, 'QUEENS_BIRTHDAY_' + currentYearStr, eduInst.Id, Date.newInstance(currentYear, 06, 14), Date.newInstance(currentYear, 06, 14)));

        holidays.put('NEW_YEARS_DAY_' + nextYearStr, REDU_TestData_UTIL.newHoliday('NEW_YEARS_DAY_' + nextYearStr, 'NEW_YEARS_DAY_' + nextYearStr, eduInst.Id, Date.newInstance(nextYear, 01, 01), Date.newInstance(nextYear, 01, 01)));
        holidays.put('AUSTRALIA_DAY_' + nextYearStr, REDU_TestData_UTIL.newHoliday('AUSTRALIA_DAY_' + nextYearStr, 'AUSTRALIA_DAY_' + nextYearStr, eduInst.Id, Date.newInstance(nextYear, 01, 26), Date.newInstance(nextYear, 01, 26)));
        holidays.put('GOOD_FRIDAY_' + nextYearStr, REDU_TestData_UTIL.newHoliday('GOOD_FRIDAY_' + nextYearStr, 'GOOD_FRIDAY_' + nextYearStr, eduInst.Id, Date.newInstance(nextYear, 04, 02), Date.newInstance(nextYear, 04, 02)));
        holidays.put('ANZAC_DAY_' + nextYearStr, REDU_TestData_UTIL.newHoliday('ANZAC_DAY_' + nextYearStr, 'ANZAC_DAY_' + nextYearStr, eduInst.Id, Date.newInstance(nextYear, 04, 26), Date.newInstance(nextYear, 04, 26)));
        holidays.put('EASTER_MONDAY_' + nextYearStr, REDU_TestData_UTIL.newHoliday('EASTER_MONDAY_' + nextYearStr, 'EASTER_MONDAY_' + nextYearStr, eduInst.Id, Date.newInstance(nextYear, 04, 05), Date.newInstance(nextYear, 04, 05)));
        holidays.put('QUEENS_BIRTHDAY_' + nextYearStr, REDU_TestData_UTIL.newHoliday('QUEENS_BIRTHDAY_' + nextYearStr, 'QUEENS_BIRTHDAY_' + nextYearStr, eduInst.Id, Date.newInstance(nextYear, 06, 14), Date.newInstance(nextYear, 06, 14)));

        if (FULLDATA) {
            holidays.put('ROYAL_QUEENSLAND_SHOW_PUBLIC_HOLIDAY_' + pastYearStr, REDU_TestData_UTIL.newHoliday('ROYAL_QUEENSLAND_SHOW_PUBLIC_HOLIDAY_' + pastYearStr, 'ROYAL_QUEENSLAND_SHOW_PUBLIC_HOLIDAY_' + pastYearStr, campuses.get('BRISBANE').Id, Date.newInstance(pastYear, 08, 09), Date.newInstance(pastYear, 08, 09)));
            holidays.put('ROYAL_QUEENSLAND_SHOW_PUBLIC_HOLIDAY_' + currentYearStr, REDU_TestData_UTIL.newHoliday('ROYAL_QUEENSLAND_SHOW_PUBLIC_HOLIDAY_' + currentYearStr, 'ROYAL_QUEENSLAND_SHOW_PUBLIC_HOLIDAY_' + currentYearStr, campuses.get('BRISBANE').Id, Date.newInstance(currentYear, 08, 14), Date.newInstance(currentYear, 08, 14)));
            holidays.put('ROYAL_QUEENSLAND_SHOW_PUBLIC_HOLIDAY_' + nextYearStr, REDU_TestData_UTIL.newHoliday('ROYAL_QUEENSLAND_SHOW_PUBLIC_HOLIDAY_' + nextYearStr, 'ROYAL_QUEENSLAND_SHOW_PUBLIC_HOLIDAY_' + nextYearStr, campuses.get('BRISBANE').Id, Date.newInstance(nextYear, 08, 13), Date.newInstance(nextYear, 08, 13)));
        }

        holidays.put('BANK_HOLIDAY_' + pastYearStr, REDU_TestData_UTIL.newHoliday('BANK_HOLIDAY_' + pastYearStr, 'BANK_HOLIDAY_' + pastYearStr, campuses.get('SYDNEY').Id, Date.newInstance(pastYear, 08, 07), Date.newInstance(pastYear, 08, 07)));
        holidays.put('BANK_HOLIDAY_' + currentYearStr, REDU_TestData_UTIL.newHoliday('BANK_HOLIDAY_' + currentYearStr, 'BANK_HOLIDAY_' + currentYearStr, campuses.get('SYDNEY').Id, Date.newInstance(currentYear, 08, 05), Date.newInstance(currentYear, 08, 05)));
        holidays.put('BANK_HOLIDAY_' + nextYearStr, REDU_TestData_UTIL.newHoliday('BANK_HOLIDAY_' + nextYearStr, 'BANK_HOLIDAY_' + nextYearStr, campuses.get('SYDNEY').Id, Date.newInstance(nextYear, 08, 04), Date.newInstance(nextYear, 08, 04)));

        REDU_SystemMode_UTIL.doInsert(holidays.values());

        if (validateCheckpoint(HOL_Helper.getApiName(), skipAfterObject)) {
            unmuteTriggers();
            unmuteRollup();
            return;
        }
        
        //Study Funding
        studyFundings.put('RIO_University_Hardship_Award', REDU_TestData_UTIL.newStudyFunding('RIO_University_Hardship_Award', 'RIO University Hardship Award', SFD_Helper.TYPE_SCHOLARSHIP, 50000, 1, 3000, 3000, SFD_Helper.STATUS_ACTIVE));
        studyFundings.put('RIO_University_Tuition_Scholarship', REDU_TestData_UTIL.newStudyFunding('RIO_University_Tuition_Scholarship', 'RIO University Tuition Scholarship', SFD_Helper.TYPE_SCHOLARSHIP, 50000, 1, 0, 0, SFD_Helper.STATUS_ACTIVE));

        REDU_SystemMode_UTIL.doInsert(studyFundings.values());

        if (validateCheckpoint(SFD_Helper.getApiName(), skipAfterObject)) {
            unmuteTriggers();
            unmuteRollup();
            return; 
        }

        //campus facilities
        facilities.put('SYD_BLOCKA', REDU_TestData_UTIL.newFacility('SYD_BLOCKA', campuses.get('SYDNEY').Id, null, 'Sydney Campus - Block A', null, FAC_Helper.FACTYPE_BUILDING, true));
        facilities.put('SYD_BLOCKB', REDU_TestData_UTIL.newFacility('SYD_BLOCKB', campuses.get('SYDNEY').Id, null, 'Sydney Campus - Block B', null, FAC_Helper.FACTYPE_BUILDING, true));
        
        if (FULLDATA) {
            facilities.put('BRI_BLOCKA', REDU_TestData_UTIL.newFacility('BRI_BLOCKA', campuses.get('BRISBANE').Id, null, 'Brisbane Campus - Block A', null, FAC_Helper.FACTYPE_BUILDING, true));
            facilities.put('BRI_BLOCKB', REDU_TestData_UTIL.newFacility('BRI_BLOCKB', campuses.get('BRISBANE').Id, null, 'Brisbane Campus - Block B', null, FAC_Helper.FACTYPE_BUILDING, true));
        }

        REDU_SystemMode_UTIL.doInsert(facilities.values());

        subFacilities.put('SYD_BLOCKA_RA1', REDU_TestData_UTIL.newFacility('SYD_BLOCKA_RA1', campuses.get('SYDNEY').Id, facilities.get('SYD_BLOCKA').Id, 'Sydney Campus - Block A - Room A1', 20, FAC_Helper.FACTYPE_CLASSROOM, true));
        subFacilities.put('SYD_BLOCKA_RA2', REDU_TestData_UTIL.newFacility('SYD_BLOCKA_RA2', campuses.get('SYDNEY').Id, facilities.get('SYD_BLOCKA').Id, 'Sydney Campus - Block A - Room A2', 20, FAC_Helper.FACTYPE_CLASSROOM, true));
        subFacilities.put('SYD_BLOCKA_HA3', REDU_TestData_UTIL.newFacility('SYD_BLOCKA_HA3', campuses.get('SYDNEY').Id, facilities.get('SYD_BLOCKA').Id, 'Sydney Campus - Block A - Hall A3', 200, FAC_Helper.FACTYPE_LECHALL, true));
        subFacilities.put('SYD_BLOCKB_RB1', REDU_TestData_UTIL.newFacility('SYD_BLOCKB_RB1', campuses.get('SYDNEY').Id, facilities.get('SYD_BLOCKB').Id, 'Sydney Campus - Block B - Room B1', 20, FAC_Helper.FACTYPE_CLASSROOM, true));
        subFacilities.put('SYD_BLOCKB_RB2', REDU_TestData_UTIL.newFacility('SYD_BLOCKB_RB2', campuses.get('SYDNEY').Id, facilities.get('SYD_BLOCKB').Id, 'Sydney Campus - Block B - Room B2', 20, FAC_Helper.FACTYPE_CLASSROOM, true));
        subFacilities.put('SYD_BLOCKB_HB3', REDU_TestData_UTIL.newFacility('SYD_BLOCKB_HB3', campuses.get('SYDNEY').Id, facilities.get('SYD_BLOCKB').Id, 'Sydney Campus - Block B - Hall B3', 200, FAC_Helper.FACTYPE_LECHALL, true));
        
        if (FULLDATA) {
            subFacilities.put('BRI_BLOCKA_RA1', REDU_TestData_UTIL.newFacility('BRI_BLOCKA_RA1', campuses.get('BRISBANE').Id, facilities.get('BRI_BLOCKA').Id, 'Brisbane Campus - Block A - Room A1', 20, FAC_Helper.FACTYPE_CLASSROOM, true));
            subFacilities.put('BRI_BLOCKA_RA2', REDU_TestData_UTIL.newFacility('BRI_BLOCKA_RA2', campuses.get('BRISBANE').Id, facilities.get('BRI_BLOCKA').Id, 'Brisbane Campus - Block A - Room A2', 20, FAC_Helper.FACTYPE_CLASSROOM, true));
            subFacilities.put('BRI_BLOCKA_HA3', REDU_TestData_UTIL.newFacility('BRI_BLOCKA_HA3', campuses.get('BRISBANE').Id, facilities.get('BRI_BLOCKA').Id, 'Brisbane Campus - Block A - Hall A3', 200, FAC_Helper.FACTYPE_LECHALL, true));
            subFacilities.put('BRI_BLOCKB_RB1', REDU_TestData_UTIL.newFacility('BRI_BLOCKB_RB1', campuses.get('BRISBANE').Id, facilities.get('BRI_BLOCKB').Id, 'Brisbane Campus - Block B - Room B1', 20, FAC_Helper.FACTYPE_CLASSROOM, true));
            subFacilities.put('BRI_BLOCKB_RB2', REDU_TestData_UTIL.newFacility('BRI_BLOCKB_RB2', campuses.get('BRISBANE').Id, facilities.get('BRI_BLOCKB').Id, 'Brisbane Campus - Block B - Room B2', 20, FAC_Helper.FACTYPE_CLASSROOM, true));
            subFacilities.put('BRI_BLOCKB_HB3', REDU_TestData_UTIL.newFacility('BRI_BLOCKB_HB3', campuses.get('BRISBANE').Id, facilities.get('BRI_BLOCKB').Id, 'Brisbane Campus - Block B - Hall B3', 200, FAC_Helper.FACTYPE_LECHALL, true));
        }

        REDU_SystemMode_UTIL.doInsert(subFacilities.values());

        if (validateCheckpoint(FAC_Helper.getApiName(), skipAfterObject)) {
            unmuteTriggers();
            unmuteRollup();
            return;
        }

        //Facility Availability
        if(!subFacilities.isEmpty()) {
            for(reduivy__Facility__c subFac : subFacilities.values()) {
                facilityAvailability.put('FAV_' + subFac.reduivy__Sample_Record_Code__c, REDU_TestData_UTIL.newFacilityAvailability('FAV_' + subFac.reduivy__Sample_Record_Code__c, subFac.Id, Date.newInstance(2023, 01, 01), Date.newInstance(2026, 12, 31), 'Active', Time.newInstance(08, 0, 0, 0), Time.newInstance(16, 0, 0, 0), Time.newInstance(08, 0, 0, 0), Time.newInstance(16, 0, 0, 0), Time.newInstance(08, 0, 0, 0), Time.newInstance(16, 0, 0, 0), Time.newInstance(08, 0, 0, 0), Time.newInstance(16, 0, 0, 0), Time.newInstance(08, 0, 0, 0), Time.newInstance(16, 0, 0, 0), Time.newInstance(08, 0, 0, 0), Time.newInstance(12, 0, 0, 0), null, null));
            }
    
            REDU_SystemMode_UTIL.doInsert(facilityAvailability.values());
        }

        if (validateCheckpoint(FAV_Helper.getApiName(), skipAfterObject)) {
            unmuteTriggers();
            unmuteRollup();
            return;
        }

        //Study Grade Setting
        studyGradeSettings.put('PERCENTAGE_SCORE', REDU_TestData_UTIL.newStudyGradeSetting('PERCENTAGE_SCORE', eduInst.Id, 'Percentage/Score', SGS_Helper.GRADING_SETTING_TYPE_PERCENTAGE_LETTER));
        studyGradeSettings.put('PASS_FAIL', REDU_TestData_UTIL.newStudyGradeSetting('PASS_FAIL', eduInst.Id, 'Pass/Fail', SGS_Helper.GRADING_SETTING_TYPE_PASSFAIL));

        REDU_SystemMode_UTIL.doInsert(studyGradeSettings.values());

        if (validateCheckpoint(SGS_Helper.getApiName(), skipAfterObject)) {
            unmuteTriggers();
            unmuteRollup();
            return;
        }

        String ienCompletedPassStatus = IEN_Helper.getCompletedPassStatuses().get(0);
        String ienCompletedFailStatus = IEN_Helper.getCompletedFailStatuses().get(0);

        studyGradingScheme.put('PERCENTAGE_SCORE_A', REDU_TestData_UTIL.newStudyGradingScheme('PERCENTAGE_SCORE_A', studyGradeSettings.get('PERCENTAGE_SCORE').Id, 'PERCENTAGE_SCORE_A', 71, 100, 'A', 4, 'Pass', SGD_Helper.SCORINGRANGE_HIGHERRANGE, SGD_Helper.EXCLUDE_CREDITSEARNED_NO, SGD_Helper.EXCLUDE_GPA_No, ienCompletedPassStatus, 1));
        studyGradingScheme.put('PERCENTAGE_SCORE_B', REDU_TestData_UTIL.newStudyGradingScheme('PERCENTAGE_SCORE_B', studyGradeSettings.get('PERCENTAGE_SCORE').Id, 'PERCENTAGE_SCORE_B', 61, 70.9, 'B', 3, 'Pass', SGD_Helper.SCORINGRANGE_HIGHERRANGE, SGD_Helper.EXCLUDE_CREDITSEARNED_NO, SGD_Helper.EXCLUDE_GPA_No, ienCompletedPassStatus, 2));
        studyGradingScheme.put('PERCENTAGE_SCORE_C', REDU_TestData_UTIL.newStudyGradingScheme('PERCENTAGE_SCORE_C', studyGradeSettings.get('PERCENTAGE_SCORE').Id, 'PERCENTAGE_SCORE_C', 51, 60.9, 'C', 2, 'Pass', SGD_Helper.SCORINGRANGE_HIGHERRANGE, SGD_Helper.EXCLUDE_CREDITSEARNED_NO, SGD_Helper.EXCLUDE_GPA_No, ienCompletedPassStatus, 3));
        studyGradingScheme.put('PERCENTAGE_SCORE_D', REDU_TestData_UTIL.newStudyGradingScheme('PERCENTAGE_SCORE_D', studyGradeSettings.get('PERCENTAGE_SCORE').Id, 'PERCENTAGE_SCORE_D', 41, 50.9, 'D', 1, 'Pass', SGD_Helper.SCORINGRANGE_HIGHERRANGE, SGD_Helper.EXCLUDE_CREDITSEARNED_NO, SGD_Helper.EXCLUDE_GPA_No, ienCompletedPassStatus, 4));
        studyGradingScheme.put('PERCENTAGE_SCORE_F', REDU_TestData_UTIL.newStudyGradingScheme('PERCENTAGE_SCORE_F', studyGradeSettings.get('PERCENTAGE_SCORE').Id, 'PERCENTAGE_SCORE_F', 0, 40.9, 'F', 0, 'Fail', SGD_Helper.SCORINGRANGE_HIGHERRANGE, SGD_Helper.EXCLUDE_CREDITSEARNED_NO, SGD_Helper.EXCLUDE_GPA_No, ienCompletedFailStatus, 5));
        studyGradingScheme.put('PERCENTAGE_SCORE_WF', REDU_TestData_UTIL.newStudyGradingScheme('PERCENTAGE_SCORE_WF', studyGradeSettings.get('PERCENTAGE_SCORE').Id, 'PERCENTAGE_SCORE_WF', null, null, 'WF', 0, 'Fail', SGD_Helper.SCORINGRANGE_HIGHERRANGE, SGD_Helper.EXCLUDE_CREDITSEARNED_NO, SGD_Helper.EXCLUDE_GPA_No, ienCompletedFailStatus, 6));
        
        reduivy__Study_Grading_Scheme__c faScheme = REDU_TestData_UTIL.newStudyGradingScheme('PERCENTAGE_SCORE_FA', studyGradeSettings.get('PERCENTAGE_SCORE').Id, 'PERCENTAGE_SCORE_FA', null, null, 'FA', 0, 'Fail', SGD_Helper.SCORINGRANGE_HIGHERRANGE, SGD_Helper.EXCLUDE_CREDITSEARNED_NO, SGD_Helper.EXCLUDE_GPA_No, ienCompletedFailStatus, 7);
        faScheme.reduivy__For_Fail_Absent__c = true;
        
        studyGradingScheme.put('PERCENTAGE_SCORE_FA', faScheme);
        
        //for credit transfer applicaiton
        studyGradingScheme.put('PERCENTAGE_SCORE_CT', REDU_TestData_UTIL.newStudyGradingScheme('PERCENTAGE_SCORE_CT', studyGradeSettings.get('PERCENTAGE_SCORE').Id, 'PERCENTAGE_SCORE_CT', null, null, 'CT', 0, 'Credit Transfer', SGD_Helper.SCORINGRANGE_HIGHERRANGE, SGD_Helper.EXCLUDE_CREDITSEARNED_YES, SGD_Helper.EXCLUDE_GPA_YES, ienCompletedPassStatus, 8));
        studyGradingScheme.put('PERCENTAGE_SCORE_RPL', REDU_TestData_UTIL.newStudyGradingScheme('PERCENTAGE_SCORE_RPL', studyGradeSettings.get('PERCENTAGE_SCORE').Id, 'PERCENTAGE_SCORE_RPL', null, null, 'RPL', 0, 'RPL', SGD_Helper.SCORINGRANGE_HIGHERRANGE, SGD_Helper.EXCLUDE_CREDITSEARNED_YES, SGD_Helper.EXCLUDE_GPA_YES, ienCompletedPassStatus, 9));
        studyGradingScheme.put('PERCENTAGE_SCORE_WAIVE', REDU_TestData_UTIL.newStudyGradingScheme('PERCENTAGE_SCORE_WAIVE', studyGradeSettings.get('PERCENTAGE_SCORE').Id, 'PERCENTAGE_SCORE_WAIVE', null, null, 'Waive', 0, 'Waive', SGD_Helper.SCORINGRANGE_HIGHERRANGE, SGD_Helper.EXCLUDE_CREDITSEARNED_YES, SGD_Helper.EXCLUDE_GPA_YES, ienCompletedPassStatus, 10));

        studyGradingScheme.put('PASS_FAIL_PASSED', REDU_TestData_UTIL.newStudyGradingScheme('PASS_FAIL_PASSED', studyGradeSettings.get('PASS_FAIL').Id, 'PASS_FAIL_PASSED', 51, 100, 'A', 4, 'Pass', SGD_Helper.SCORINGRANGE_HIGHERRANGE, SGD_Helper.EXCLUDE_CREDITSEARNED_NO, SGD_Helper.EXCLUDE_GPA_No, ienCompletedPassStatus, 1));
        studyGradingScheme.put('PASS_FAIL_FAILED', REDU_TestData_UTIL.newStudyGradingScheme('PASS_FAIL_FAILED', studyGradeSettings.get('PASS_FAIL').Id, 'PASS_FAIL_FAILED', 0, 50.9, 'F', 0, 'Fail', SGD_Helper.SCORINGRANGE_HIGHERRANGE, SGD_Helper.EXCLUDE_CREDITSEARNED_NO, SGD_Helper.EXCLUDE_GPA_No, ienCompletedFailStatus, 2));
        
        REDU_SystemMode_UTIL.doInsert(studyGradingScheme.values());

        if (validateCheckpoint(SGD_Helper.getApiName(), skipAfterObject)) {
            unmuteTriggers();
            unmuteRollup();
            return;
        }
        
        //study unit
        studyUnits.put('BUS101', REDU_TestData_UTIL.newStudyUnit('BUS101', eduInst.Id, studyGradeSettings.get('PERCENTAGE_SCORE').Id, 'BUS101', 'BUS101', 10, 'Business, Management, and Marketing', '100', 0.125, null));
        studyUnits.put('BUS102', REDU_TestData_UTIL.newStudyUnit('BUS102', eduInst.Id, studyGradeSettings.get('PERCENTAGE_SCORE').Id, 'BUS102', 'BUS102', 10, 'Business, Management, and Marketing', '100', 0.125, null));
        studyUnits.put('BUS103', REDU_TestData_UTIL.newStudyUnit('BUS103', eduInst.Id, studyGradeSettings.get('PERCENTAGE_SCORE').Id, 'BUS103', 'BUS103', 10, 'Business, Management, and Marketing', '100', 0.125, null));
        studyUnits.put('MKT101', REDU_TestData_UTIL.newStudyUnit('MKT101', eduInst.Id, studyGradeSettings.get('PERCENTAGE_SCORE').Id, 'MKT101', 'MKT101', 10, 'Business, Management, and Marketing', '100', 0.125, null));
        studyUnits.put('MKT102', REDU_TestData_UTIL.newStudyUnit('MKT102', eduInst.Id, studyGradeSettings.get('PERCENTAGE_SCORE').Id, 'MKT102', 'MKT102', 10, 'Business, Management, and Marketing', '100', 0.125, null));
        studyUnits.put('MKT103', REDU_TestData_UTIL.newStudyUnit('MKT103', eduInst.Id, studyGradeSettings.get('PERCENTAGE_SCORE').Id, 'MKT103', 'MKT103', 10, 'Business, Management, and Marketing', '100', 0.125, null));    
        studyUnits.put('BUS201', REDU_TestData_UTIL.newStudyUnit('BUS201', eduInst.Id, studyGradeSettings.get('PERCENTAGE_SCORE').Id, 'BUS201', 'BUS201', 10, 'Business, Management, and Marketing', '200', 0.125, 'BUS101'));
        studyUnits.put('BUS202', REDU_TestData_UTIL.newStudyUnit('BUS202', eduInst.Id, studyGradeSettings.get('PERCENTAGE_SCORE').Id, 'BUS202', 'BUS202', 10, 'Business, Management, and Marketing', '200', 0.125, 'BUS101 OR BUS102'));
        studyUnits.put('BUS203', REDU_TestData_UTIL.newStudyUnit('BUS203', eduInst.Id, studyGradeSettings.get('PERCENTAGE_SCORE').Id, 'BUS203', 'BUS203', 10, 'Business, Management, and Marketing', '200', 0.125, 'BUS101 OR BUS103'));
        studyUnits.put('MGT301', REDU_TestData_UTIL.newStudyUnit('MGT301', eduInst.Id, studyGradeSettings.get('PERCENTAGE_SCORE').Id, 'MGT301', 'MGT301', 10, 'Business, Management, and Marketing', '300', 0.125, 'BUS201 AND CREDIT10'));
        studyUnits.put('MGT302', REDU_TestData_UTIL.newStudyUnit('MGT302', eduInst.Id, studyGradeSettings.get('PERCENTAGE_SCORE').Id, 'MGT302', 'MGT302', 10, 'Business, Management, and Marketing', '300', 0.125, 'BUS201 AND NOT(BUS203)'));
        studyUnits.put('MGT303', REDU_TestData_UTIL.newStudyUnit('MGT303', eduInst.Id, studyGradeSettings.get('PERCENTAGE_SCORE').Id, 'MGT303', 'MGT303', 10, 'Business, Management, and Marketing', '300', 0.125, 'BUS201 AND NOT(BUS202)'));

        studyUnits.put('COM101', REDU_TestData_UTIL.newStudyUnit('COM101', eduInst.Id, studyGradeSettings.get('PERCENTAGE_SCORE').Id, 'COM101', 'COM101', 10, 'Computer and Information Sciences', '100', 0.125, 'NOT(COM102) OR MANUAL'));
        studyUnits.put('COM102', REDU_TestData_UTIL.newStudyUnit('COM102', eduInst.Id, studyGradeSettings.get('PERCENTAGE_SCORE').Id, 'COM102', 'COM102', 10, 'Computer and Information Sciences', '100', 0.125, 'NOT(COM101) OR MANUAL'));
        studyUnits.put('COM103', REDU_TestData_UTIL.newStudyUnit('COM103', eduInst.Id, studyGradeSettings.get('PERCENTAGE_SCORE').Id, 'COM103', 'COM103', 10, 'Computer and Information Sciences', '100', 0.125, 'UNITS2'));
        studyUnits.put('ICT101', REDU_TestData_UTIL.newStudyUnit('ICT101', eduInst.Id, studyGradeSettings.get('PERCENTAGE_SCORE').Id, 'ICT101', 'ICT101', 10, 'Computer and Information Sciences', '100', 0.125, null));
        studyUnits.put('ICT102', REDU_TestData_UTIL.newStudyUnit('ICT102', eduInst.Id, studyGradeSettings.get('PERCENTAGE_SCORE').Id, 'ICT102', 'ICT102', 10, 'Computer and Information Sciences', '100', 0.125, null));
        studyUnits.put('ICT103', REDU_TestData_UTIL.newStudyUnit('ICT103', eduInst.Id, studyGradeSettings.get('PERCENTAGE_SCORE').Id, 'ICT103', 'ICT103', 10, 'Computer and Information Sciences', '100', 0.125, null));
        studyUnits.put('MAT201', REDU_TestData_UTIL.newStudyUnit('MAT201', eduInst.Id, studyGradeSettings.get('PERCENTAGE_SCORE').Id, 'MAT201', 'MAT201', 10, 'Computer and Information Sciences', '200', 0.125, null));
        studyUnits.put('MAT202', REDU_TestData_UTIL.newStudyUnit('MAT202', eduInst.Id, studyGradeSettings.get('PERCENTAGE_SCORE').Id, 'MAT202', 'MAT202', 10, 'Computer and Information Sciences', '200', 0.125, null));
        studyUnits.put('MAT203', REDU_TestData_UTIL.newStudyUnit('MAT203', eduInst.Id, studyGradeSettings.get('PERCENTAGE_SCORE').Id, 'MAT203', 'MAT203', 10, 'Computer and Information Sciences', '200', 0.125, null));
        studyUnits.put('SEC301', REDU_TestData_UTIL.newStudyUnit('SEC301', eduInst.Id, studyGradeSettings.get('PERCENTAGE_SCORE').Id, 'SEC301', 'SEC301', 10, 'Computer and Information Sciences', '300', 0.125, 'COM101 AND (BUS101 OR BUS102)'));
        studyUnits.put('SEC302', REDU_TestData_UTIL.newStudyUnit('SEC302', eduInst.Id, studyGradeSettings.get('PERCENTAGE_SCORE').Id, 'SEC302', 'SEC302', 10, 'Computer and Information Sciences', '300', 0.125, '(COM101 OR COM102) AND BUS201 AND CREDIT20'));
        studyUnits.put('SEC303', REDU_TestData_UTIL.newStudyUnit('SEC303', eduInst.Id, studyGradeSettings.get('PERCENTAGE_SCORE').Id, 'SEC303', 'SEC303', 10, 'Computer and Information Sciences', '300', 0.125, '(COM101 OR COM102) AND (MAT201 OR MAT202)'));

        REDU_SystemMode_UTIL.doInsert(studyUnits.values());

        if (validateCheckpoint(SUN_Helper.getApiName(), skipAfterObject)) {
            unmuteTriggers();
            unmuteRollup();
            return;
        }

        //create the newStudyGradeItem for each study units
        for(reduivy__Study_Unit__c su : studyUnits.values()){
            studyGradeItems.put('Assignment_' + su.Name, REDU_TestData_UTIL.newStudyGradeItem('Assignment_' + su.Name, null, su.Id, 'Assignment - ' + su.Name, 'Numerical Grade', 1, 50));
            studyGradeItems.put('Exam_' + su.Name, REDU_TestData_UTIL.newStudyGradeItem('Exam_' + su.Name, null, su.Id, 'Exam - ' + su.Name, 'Numerical Grade', 2, 50));
        }

        REDU_SystemMode_UTIL.doInsert(studyGradeItems.values());

        if (validateCheckpoint(SGI_Helper.getApiName(), skipAfterObject)) {
            unmuteTriggers();
            unmuteRollup();
            return;
        }

        //study units requirement
        studyUnitReqs.put('BUS201_BUS101', REDU_TestData_UTIL.newUnitStudyUnitRequirement('BUS201_BUS101', studyUnits.get('BUS201').Id, studyUnits.get('BUS101').Id, 'BUS201_BUS101', 'BUS101', SUR_Helper.REQTYPE_PREREQ_BYPASS));
        studyUnitReqs.put('BUS202_BUS101', REDU_TestData_UTIL.newUnitStudyUnitRequirement('BUS202_BUS101', studyUnits.get('BUS202').Id, studyUnits.get('BUS101').Id, 'BUS202_BUS101', 'BUS101', SUR_Helper.REQTYPE_PREREQ_BYPASS));
        studyUnitReqs.put('BUS202_BUS102', REDU_TestData_UTIL.newUnitStudyUnitRequirement('BUS202_BUS102', studyUnits.get('BUS202').Id, studyUnits.get('BUS102').Id, 'BUS202_BUS102', 'BUS102', SUR_Helper.REQTYPE_PREREQ_BYPASS));
        studyUnitReqs.put('BUS203_BUS101', REDU_TestData_UTIL.newUnitStudyUnitRequirement('BUS203_BUS101', studyUnits.get('BUS203').Id, studyUnits.get('BUS101').Id, 'BUS203_BUS101', 'BUS101', SUR_Helper.REQTYPE_PREREQ));
        studyUnitReqs.put('BUS203_BUS103', REDU_TestData_UTIL.newUnitStudyUnitRequirement('BUS203_BUS103', studyUnits.get('BUS203').Id, studyUnits.get('BUS103').Id, 'BUS203_BUS103', 'BUS103', SUR_Helper.REQTYPE_PREREQ));
        studyUnitReqs.put('MGT301_BUS201', REDU_TestData_UTIL.newUnitStudyUnitRequirement('MGT301_BUS201', studyUnits.get('MGT301').Id, studyUnits.get('BUS201').Id, 'MGT301_BUS201', 'BUS201', SUR_Helper.REQTYPE_PREREQ_BYPASS));
        studyUnitReqs.put('MGT301_CREDIT10', REDU_TestData_UTIL.newCreditsStudyUnitRequirement('MGT301_CREDIT10', studyUnits.get('MGT301').Id, 'MGT301_CREDIT10', 'CREDIT10', 10));
        studyUnitReqs.put('MGT302_BUS201', REDU_TestData_UTIL.newUnitStudyUnitRequirement('MGT302_BUS201', studyUnits.get('MGT302').Id, studyUnits.get('BUS201').Id, 'MGT302_BUS201', 'BUS201', SUR_Helper.REQTYPE_PREREQ_BYPASS));
        studyUnitReqs.put('MGT302_BUS203', REDU_TestData_UTIL.newUnitStudyUnitRequirement('MGT302_BUS203', studyUnits.get('MGT302').Id, studyUnits.get('BUS203').Id, 'MGT302_BUS203', 'BUS203', SUR_Helper.REQTYPE_PREREQ_BYPASS));
        studyUnitReqs.put('MGT303_BUS201', REDU_TestData_UTIL.newUnitStudyUnitRequirement('MGT303_BUS201', studyUnits.get('MGT303').Id, studyUnits.get('BUS201').Id, 'MGT303_BUS201', 'BUS201', SUR_Helper.REQTYPE_PREREQ_BYPASS));
        studyUnitReqs.put('MGT303_BUS202', REDU_TestData_UTIL.newUnitStudyUnitRequirement('MGT303_BUS202', studyUnits.get('MGT303').Id, studyUnits.get('BUS202').Id, 'MGT303_BUS202', 'BUS202', SUR_Helper.REQTYPE_PREREQ_BYPASS));

        studyUnitReqs.put('COM101_COM102', REDU_TestData_UTIL.newUnitStudyUnitRequirement('COM101_COM102', studyUnits.get('COM101').Id, studyUnits.get('COM102').Id, 'COM101_COM102', 'COM102', SUR_Helper.REQTYPE_PREREQ_BYPASS));
        studyUnitReqs.put('COM101_MANUAL', REDU_TestData_UTIL.newOtherStudyUnitRequirement('COM101_MANUAL', studyUnits.get('COM101').Id, 'COM101_MANUAL', 'MANUAL'));
        studyUnitReqs.put('COM102_COM101', REDU_TestData_UTIL.newUnitStudyUnitRequirement('COM102_COM101', studyUnits.get('COM102').Id, studyUnits.get('COM101').Id, 'COM102_COM101', 'COM101', SUR_Helper.REQTYPE_PREREQ_BYPASS));
        studyUnitReqs.put('COM102_MANUAL', REDU_TestData_UTIL.newOtherStudyUnitRequirement('COM102_MANUAL', studyUnits.get('COM102').Id, 'COM102_MANUAL', 'MANUAL'));

        studyUnitReqs.put('COM103_UNITS2', REDU_TestData_UTIL.newCustomStudyUnitRequirement('COM103_UNITS2', studyUnits.get('COM103').Id, 'COM103_UNITS2', 'UNITS2', 'reduivy__Units_Enrolled__c', SUR_Helper.FIELDMATCHINGOP_GREATEROREQUAL, '2'));

        studyUnitReqs.put('SEC301_COM101', REDU_TestData_UTIL.newUnitStudyUnitRequirement('SEC301_COM101', studyUnits.get('SEC301').Id, studyUnits.get('COM101').Id, 'SEC301_COM101', 'COM101', SUR_Helper.REQTYPE_PREREQ_BYPASS));
        studyUnitReqs.put('SEC301_BUS101', REDU_TestData_UTIL.newUnitStudyUnitRequirement('SEC301_BUS101', studyUnits.get('SEC301').Id, studyUnits.get('BUS101').Id, 'SEC301_BUS101', 'BUS101', SUR_Helper.REQTYPE_PREREQ_BYPASS));
        studyUnitReqs.put('SEC301_BUS102', REDU_TestData_UTIL.newUnitStudyUnitRequirement('SEC301_BUS102', studyUnits.get('SEC301').Id, studyUnits.get('BUS102').Id, 'SEC301_BUS102', 'BUS102', SUR_Helper.REQTYPE_PREREQ_BYPASS));

        studyUnitReqs.put('SEC302_COM101', REDU_TestData_UTIL.newUnitStudyUnitRequirement('SEC302_COM101', studyUnits.get('SEC302').Id, studyUnits.get('COM101').Id, 'SEC302_COM101', 'COM101', SUR_Helper.REQTYPE_PREREQ_BYPASS));
        studyUnitReqs.put('SEC302_COM102', REDU_TestData_UTIL.newUnitStudyUnitRequirement('SEC302_COM102', studyUnits.get('SEC302').Id, studyUnits.get('COM102').Id, 'SEC302_COM102', 'COM102', SUR_Helper.REQTYPE_PREREQ_BYPASS));
        studyUnitReqs.put('SEC302_BUS201', REDU_TestData_UTIL.newUnitStudyUnitRequirement('SEC302_BUS201', studyUnits.get('SEC302').Id, studyUnits.get('BUS201').Id, 'SEC302_BUS201', 'BUS201', SUR_Helper.REQTYPE_PREREQ_BYPASS));
        studyUnitReqs.put('SEC302_CREDIT20', REDU_TestData_UTIL.newCreditsStudyUnitRequirement('SEC302_CREDIT20', studyUnits.get('SEC302').Id, 'SEC302_CREDIT20', 'CREDIT20', 20));

        studyUnitReqs.put('SEC303_COM101', REDU_TestData_UTIL.newUnitStudyUnitRequirement('SEC303_COM101', studyUnits.get('SEC303').Id, studyUnits.get('COM101').Id, 'SEC303_COM101', 'COM101', SUR_Helper.REQTYPE_PREREQ_BYPASS));
        studyUnitReqs.put('SEC303_COM102', REDU_TestData_UTIL.newUnitStudyUnitRequirement('SEC303_COM102', studyUnits.get('SEC303').Id, studyUnits.get('COM102').Id, 'SEC303_COM102', 'COM102', SUR_Helper.REQTYPE_PREREQ_BYPASS));
        studyUnitReqs.put('SEC303_MAT201', REDU_TestData_UTIL.newUnitStudyUnitRequirement('SEC303_MAT201', studyUnits.get('SEC303').Id, studyUnits.get('MAT201').Id, 'SEC303_MAT201', 'MAT201', SUR_Helper.REQTYPE_PREREQ_BYPASS));
        studyUnitReqs.put('SEC303_MAT202', REDU_TestData_UTIL.newUnitStudyUnitRequirement('SEC303_MAT202', studyUnits.get('SEC303').Id, studyUnits.get('MAT202').Id, 'SEC303_MAT202', 'MAT202', SUR_Helper.REQTYPE_PREREQ_BYPASS));

        REDU_SystemMode_UTIL.doInsert(studyUnitReqs.values());

        if (validateCheckpoint(SUR_Helper.getApiName(), skipAfterObject)) {
            unmuteTriggers();
            unmuteRollup();
            return;
        }

        //Agreement
        agreements.put('Transfer_Credit_Agreement_with_Partner_University', REDU_TestData_UTIL.newAgreement('Transfer_Credit_Agreement_with_Partner_University', eduInst.Id, extEduInsts.get('EXTUNIT').Id, 'Transfer Credit Agreement with Partner University', Date.newInstance(2023, 01, 01), Date.newInstance(2026, 12, 31), AGR_Helper.STATUS_ACTIVE, AGR_Helper.TYPE_EXTERNAL));

        REDU_SystemMode_UTIL.doInsert(agreements.values());

        if (validateCheckpoint(AGR_Helper.getApiName(), skipAfterObject)) {
            unmuteTriggers();
            unmuteRollup();
            return;
        }

        //Agreement Unit Equivalent
        agreementUnitEquavalents.put('AUE_Introduction_to_Business_Studies', REDU_TestData_UTIL.newAgreementUnitEquivalent('AUE_Introduction_to_Business_Studies', agreements.get('Transfer_Credit_Agreement_with_Partner_University').Id, 'Introduction to Business Studies', new Set<String>{'BSN1000'}, new Set<String>{'BUS101'}, AUE_Helper.STATUS_ACTIVE, AUE_Helper.TYPE_ONETOONE));
        agreementUnitEquavalents.put('AUE_Introduction_to_IT', REDU_TestData_UTIL.newAgreementUnitEquivalent('AUE_Introduction_to_IT', agreements.get('Transfer_Credit_Agreement_with_Partner_University').Id, 'Introduction to IT', new Set<String>{'ITS1000'}, new Set<String>{'ICT101'}, AUE_Helper.STATUS_ACTIVE, AUE_Helper.TYPE_ONETOONE));
        agreementUnitEquavalents.put('AUE_Advanced_Marketing_Studies', REDU_TestData_UTIL.newAgreementUnitEquivalent('AUE_Advanced_Marketing_Studies', agreements.get('Transfer_Credit_Agreement_with_Partner_University').Id, 'Advanced Marketing Studies', new Set<String>{'MRT2000'}, new Set<String>{'MKT101', 'MKT102', 'MKT103'}, AUE_Helper.STATUS_ACTIVE, AUE_Helper.TYPE_ONETOMANY));
        agreementUnitEquavalents.put('AUE_Intro_to_MathsI_Intro_to_MathsII', REDU_TestData_UTIL.newAgreementUnitEquivalent('AUE_Intro_to_MathsI_Intro_to_MathsII', agreements.get('Transfer_Credit_Agreement_with_Partner_University').Id, 'Intro to Maths - I;Intro to Maths - II', new Set<String>{'MTS1001', 'MTS1002'}, new Set<String>{'MAT201'}, AUE_Helper.STATUS_ACTIVE, AUE_Helper.TYPE_MANYTOONE));
        agreementUnitEquavalents.put('AUE_Leadership_Skills', REDU_TestData_UTIL.newAgreementUnitEquivalent('AUE_Leadership_Skills', agreements.get('Transfer_Credit_Agreement_with_Partner_University').Id, 'Leadership Skills', new Set<String>{'LDR1000'}, new Set<String>{}, AUE_Helper.STATUS_ACTIVE, AUE_Helper.TYPE_MANUALASSIGNMENT));

        REDU_SystemMode_UTIL.doInsert(agreementUnitEquavalents.values());

        if (validateCheckpoint(AUE_Helper.getApiName(), skipAfterObject)) {
            unmuteTriggers();
            unmuteRollup();
            return;
        }

        //Agreement Recognition
        agreementRecognitions.put('PARTNER_PROGRAM_A', REDU_TestData_UTIL.newAgreementRecognition('PARTNER_PROGRAM_A', 'PARTNER_PROGRAM_A', agreements.get('Transfer_Credit_Agreement_with_Partner_University').Id, null, 'PARTNER_PROGRAM_A', null, null, null, null));

        REDU_SystemMode_UTIL.doInsert(agreementRecognitions.values());

        if (validateCheckpoint(ARC_Helper.getApiName(), skipAfterObject)) {
            unmuteTriggers();
            unmuteRollup();
            return;
        }

        //agreement Recognition unit
        agreementRecognitionUnits.put('ARU_Introduction_to_Business_Studies', REDU_TestData_UTIL.newAgreementRecognitionUnit('ARU_Introduction_to_Business_Studies', 'Introduction to Business Studies', 'BSN1000', agreementRecognitions.get('PARTNER_PROGRAM_A').Id));
        agreementRecognitionUnits.put('ARU_Introduction_to_IT', REDU_TestData_UTIL.newAgreementRecognitionUnit('ARU_Introduction_to_IT', 'Introduction to IT', 'ITS1000', agreementRecognitions.get('PARTNER_PROGRAM_A').Id));
        agreementRecognitionUnits.put('ARU_Advanced_Marketing_Studies', REDU_TestData_UTIL.newAgreementRecognitionUnit('ARU_Advanced_Marketing_Studies', 'Advanced Marketing Studies', 'MRT2000', agreementRecognitions.get('PARTNER_PROGRAM_A').Id));
        agreementRecognitionUnits.put('ARU_Intro_to_MathsII', REDU_TestData_UTIL.newAgreementRecognitionUnit('ARU_Intro_to_MathsII', 'Intro to MathsI', 'MTS1001', agreementRecognitions.get('PARTNER_PROGRAM_A').Id));
        agreementRecognitionUnits.put('ARU_Intro_to_MathsII', REDU_TestData_UTIL.newAgreementRecognitionUnit('ARU_Intro_to_MathsII', 'Intro to MathsII', 'MTS1002', agreementRecognitions.get('PARTNER_PROGRAM_A').Id));
        agreementRecognitionUnits.put('ARU_Leadership_Skills', REDU_TestData_UTIL.newAgreementRecognitionUnit('ARU_Leadership_Skills', 'Leadership Skills', 'LDR1000', agreementRecognitions.get('PARTNER_PROGRAM_A').Id));

        
        REDU_SystemMode_UTIL.doInsert(agreementRecognitionUnits.values());

        if (validateCheckpoint(ARU_Helper.getApiName(), skipAfterObject)) {
            unmuteTriggers();
            unmuteRollup();
            return;
        }

        //Study Fee
        studyFees.put('UNIT_TUITION_FEE', REDU_TestData_UTIL.newStudyFee('UNIT_TUITION_FEE', 'Unit Tuition Fee', eduInst.Id, SFE_Helper.ITEM_TYPE_TUITION, true));
        studyFees.put('INSURANCE_FEE', REDU_TestData_UTIL.newStudyFee('INSURANCE_FEE', 'Insurance Fee', eduInst.Id, SFE_Helper.ITEM_TYPE_MISCELLANEOUS, false));
        studyFees.put('LABORATORY_FEE', REDU_TestData_UTIL.newStudyFee('LABORATORY_FEE', 'Laboratory Fee', eduInst.Id, SFE_Helper.ITEM_TYPE_MISCELLANEOUS, true));
        studyFees.put('MATERIAL_FEE', REDU_TestData_UTIL.newStudyFee('MATERIAL_FEE', 'Material Fee', eduInst.Id, SFE_Helper.ITEM_TYPE_MISCELLANEOUS, false));

        studyFees.put('TUITION_FEE_NORMAL_TERM', REDU_TestData_UTIL.newStudyFee('TUITION_FEE_NORMAL_TERM', 'Tuition Fee (Normal Term)', eduInst.Id, SFE_Helper.ITEM_TYPE_TUITION, true));
        studyFees.put('TUITION_FEE_SHORT_TERM', REDU_TestData_UTIL.newStudyFee('TUITION_FEE_SHORT_TERM', 'Tuition Fee (Short Term)', eduInst.Id, SFE_Helper.ITEM_TYPE_TUITION, true));

        REDU_SystemMode_UTIL.doInsert(studyFees.values());

        if (validateCheckpoint(SFE_Helper.getApiName(), skipAfterObject)) {
            unmuteTriggers();
            unmuteRollup();
            return; 
        }

        //Study Fee Configs
        studyFeeConfigs.put('UNDERGRADUATE_FEE_CONFIG', REDU_TestData_UTIL.newStudyFeeConfig('UNDERGRADUATE_FEE_CONFIG', 'Undergraduate Fee Config', eduInst.Id, SFC_Helper.TYPE_ACADEMIC_PROGRAM, SFC_Helper.STATUS_ACTIVE));

        REDU_SystemMode_UTIL.doInsert(studyFeeConfigs.values());

        if (validateCheckpoint(SFC_Helper.getApiName(), skipAfterObject)) {
            unmuteTriggers();
            unmuteRollup();
            return;
        }

        //Study Fee Matrix
        studyFeeMatrix.put('FEE_MATRIX_FOR_DOMESTIC_STUDENTS', REDU_TestData_UTIL.newStudyFeeMatrix('FEE_MATRIX_FOR_DOMESTIC_STUDENTS', 'Fee Matrix for Domestic Students', studyFeeConfigs.get('UNDERGRADUATE_FEE_CONFIG').Id, IPR_Helper.STUDENT_FEE_TYPE_DOMESTIC, Date.newInstance(lastYearTerm1StartDate.year(), 01, 01), Date.newInstance(nextYearTerm2EndDate.year(), 12, 31), SMX_Helper.STATUS_ACTIVE));
        studyFeeMatrix.put('FEE_MATRIX_FOR_INTERNATIONAL_STUDENTS', REDU_TestData_UTIL.newStudyFeeMatrix('FEE_MATRIX_FOR_INTERNATIONAL_STUDENTS', 'Fee Matrix for International Students', studyFeeConfigs.get('UNDERGRADUATE_FEE_CONFIG').Id, IPR_Helper.STUDENT_FEE_TYPE_INTERNATIONAL, Date.newInstance(lastYearTerm1StartDate.year(), 01, 01), Date.newInstance(nextYearTerm2EndDate.year(), 12, 31), SMX_Helper.STATUS_ACTIVE));

        REDU_SystemMode_UTIL.doInsert(studyFeeMatrix.values());

        if (validateCheckpoint(SMX_Helper.getApiName(), skipAfterObject)) {
            unmuteTriggers();
            unmuteRollup();
            return; 
        }
        
        //Study Fee Matrix Item
        studyFeeMatrixItems.put('UNIT_TUITION_FEE_FOR_DOMESTIC', REDU_TestData_UTIL.newStudyFeeMatrixItem('UNIT_TUITION_FEE_FOR_DOMESTIC', studyFeeMatrix.get('FEE_MATRIX_FOR_DOMESTIC_STUDENTS').Id, studyFees.get('UNIT_TUITION_FEE').Id, SMI_Helper.TYPE_PER_CREDIT, 700, null, null, null));
        studyFeeMatrixItems.put('INSURANCE_FEE_FOR_DOMESTIC', REDU_TestData_UTIL.newStudyFeeMatrixItem('INSURANCE_FEE_FOR_DOMESTIC', studyFeeMatrix.get('FEE_MATRIX_FOR_DOMESTIC_STUDENTS').Id, studyFees.get('INSURANCE_FEE').Id, SMI_Helper.TYPE_PER_ACADEMIC_YEAR, 50, null, null, '1;4;7;10'));
        studyFeeMatrixItems.put('LABORATORY_FEE_FOR_DOMESTIC', REDU_TestData_UTIL.newStudyFeeMatrixItem('LABORATORY_FEE_FOR_DOMESTIC', studyFeeMatrix.get('FEE_MATRIX_FOR_DOMESTIC_STUDENTS').Id, studyFees.get('LABORATORY_FEE').Id, SMI_Helper.TYPE_PER_ACADEMIC_TERM, 50, null, null, null));
        studyFeeMatrixItems.put('MATERIAL_FEE_FOR_DOMESTIC', REDU_TestData_UTIL.newStudyFeeMatrixItem('MATERIAL_FEE_FOR_DOMESTIC', studyFeeMatrix.get('FEE_MATRIX_FOR_DOMESTIC_STUDENTS').Id, studyFees.get('MATERIAL_FEE').Id, SMI_Helper.TYPE_PER_STUDY_UNIT, 50, '1', studyUnits.get('ICT101').Id, null));

        studyFeeMatrixItems.put('TUITION_FEE_NORMAL_TERM_FOR_INTERNATIONAL', REDU_TestData_UTIL.newStudyFeeMatrixItem('TUITION_FEE_NORMAL_TERM_FOR_INTERNATIONAL', studyFeeMatrix.get('FEE_MATRIX_FOR_INTERNATIONAL_STUDENTS').Id, studyFees.get('TUITION_FEE_NORMAL_TERM').Id, SMI_Helper.TYPE_PER_ACADEMIC_TERM, 2500, null, null, '1;2;4;5;7;8;10;11'));
        studyFeeMatrixItems.put('TUITION_FEE_SHORT_TERM_FOR_INTERNATIONAL', REDU_TestData_UTIL.newStudyFeeMatrixItem('TUITION_FEE_SHORT_TERM_FOR_INTERNATIONAL', studyFeeMatrix.get('FEE_MATRIX_FOR_INTERNATIONAL_STUDENTS').Id, studyFees.get('TUITION_FEE_SHORT_TERM').Id, SMI_Helper.TYPE_PER_ACADEMIC_TERM, 1500, null, null, '3;6;9;12'));
        studyFeeMatrixItems.put('INSURANCE_FEE_FOR_INTERNATIONAL', REDU_TestData_UTIL.newStudyFeeMatrixItem('INSURANCE_FEE_FOR_INTERNATIONAL', studyFeeMatrix.get('FEE_MATRIX_FOR_INTERNATIONAL_STUDENTS').Id, studyFees.get('INSURANCE_FEE').Id, SMI_Helper.TYPE_PER_ACADEMIC_YEAR, 50, null, null, '1;4;7;10'));
        studyFeeMatrixItems.put('LABORATORY_FEE_FOR_INTERNATIONAL', REDU_TestData_UTIL.newStudyFeeMatrixItem('LABORATORY_FEE_FOR_INTERNATIONAL', studyFeeMatrix.get('FEE_MATRIX_FOR_INTERNATIONAL_STUDENTS').Id, studyFees.get('LABORATORY_FEE').Id, SMI_Helper.TYPE_PER_ACADEMIC_TERM, 50, null, null, null));
        studyFeeMatrixItems.put('MATERIAL_FEE_FOR_INTERNATIONAL', REDU_TestData_UTIL.newStudyFeeMatrixItem('MATERIAL_FEE_FOR_INTERNATIONAL', studyFeeMatrix.get('FEE_MATRIX_FOR_INTERNATIONAL_STUDENTS').Id, studyFees.get('MATERIAL_FEE').Id, SMI_Helper.TYPE_PER_STUDY_UNIT, 50, '1', studyUnits.get('ICT101').Id, null));

        REDU_SystemMode_UTIL.doInsert(studyFeeMatrixItems.values());

        if (validateCheckpoint(SMI_Helper.getApiName(), skipAfterObject)) {
            unmuteTriggers();
            unmuteRollup();
            return; 
        }

        //study program
        studyPrograms.put('BACBIS', REDU_TestData_UTIL.newStudyProgram('BACBIS', eduInst.Id, 'Bachelor of Business Management', 'Bachelors Honours', 'BACBIS'));
        studyPrograms.put('BACCOM', REDU_TestData_UTIL.newStudyProgram('BACCOM', eduInst.Id, 'Bachelor of Computer Science', 'Bachelors Honours', 'BACCOM'));

        REDU_SystemMode_UTIL.doInsert(studyPrograms.values());

        if (validateCheckpoint(SPG_Helper.getApiName(), skipAfterObject)) {
            unmuteTriggers();
            unmuteRollup();
            return;
        }

        //study plan
        studyPlans.put('BACBIS_MajorA', REDU_TestData_UTIL.newStudyPlan('BACBIS_MajorA', studyPrograms.get('BACBIS').Id, studyFeeConfigs.get('UNDERGRADUATE_FEE_CONFIG').Id, 'BACBIS - Major A', SPL_Helper.PAYUPFRONT_No, SPL_Helper.STATUS_ACTIVE, true, 160));
        studyPlans.put('BACBIS_MinorA', REDU_TestData_UTIL.newStudyPlan('BACBIS_MinorA', studyPrograms.get('BACBIS').Id, studyFeeConfigs.get('UNDERGRADUATE_FEE_CONFIG').Id, 'BACBIS - Minor A', SPL_Helper.PAYUPFRONT_No, SPL_Helper.STATUS_ACTIVE, false, 80));
        studyPlans.put('BACBIS_MinorB', REDU_TestData_UTIL.newStudyPlan('BACBIS_MinorB', studyPrograms.get('BACBIS').Id, studyFeeConfigs.get('UNDERGRADUATE_FEE_CONFIG').Id, 'BACBIS - Minor B', SPL_Helper.PAYUPFRONT_No, SPL_Helper.STATUS_ACTIVE, false, 80));
        studyPlans.put('BACCOM_MajorA', REDU_TestData_UTIL.newStudyPlan('BACCOM_MajorA', studyPrograms.get('BACCOM').Id, studyFeeConfigs.get('UNDERGRADUATE_FEE_CONFIG').Id, 'BACCOM - Major A', SPL_Helper.PAYUPFRONT_No, SPL_Helper.STATUS_ACTIVE, true, 160));

        REDU_SystemMode_UTIL.doInsert(studyPlans.values());

        if (validateCheckpoint(SPL_Helper.getApiName(), skipAfterObject)) {
            unmuteTriggers();
            unmuteRollup();
            return;
        }

        //study plan structure - for Study Plan BACBIS - Major A
        /*
            Group A (Required, 100)
                Group A-1 (Required, 60)
                    Group A-1-1 (Optional, 20-40)
                        BUS101 Required
                        BUS102 Optional
                        BUS103 Optional
                        COM101 Optional
                    Group A-1-2 (Optional, 20-40)
                        BUS201 Required
                        BUS202 Optional
                        BUS203 Optional
                        MAT201 Optional
                Group A-2 (Required, 40)
                    Group A-2-1 (Required, 20)
                        MKT101 Optional
                        MKT102 Optional
                        MKT103 Optional
                    Group A-2-2 (Required, 20)
                        ICT101 Required //ISS-002155
                        ICT102 Optional
                        ICT103 Optional
            Group B (Required, 60)
                Group B-1 (Required, 20)
                    MGT301 Required
                    MGT302 Required
                Group B-2 (Optional, 10-40)
                    MGT303 Optional
                    COM102 Optional
                    COM103 Optional
                Group B-3 (Optional, 10-40)
                    MAT202 Optional
                    MAT203 Optional
                    SEC301 Optional
            Group C (Optional, 20)
                SEC302 Optional
                SEC303 Optional

         */

        //study plan structure - for Study Plan BACBIS - Minor A
        /*
            Group A (Required, 50)
                MAT201 Required
                SEC301 Required
                BUS102 Optional
                BUS103 Optional
                COM101 Optional
                COM102 Optional
            Group B (Required, 30)
                MAT202 Required
                MGT301 Optional
                BUS202 Optional
                BUS203 Optional
                SEC302 Optional
         */

         //study plan structure - for Study Plan BACBIS - Minor B
        /*
            Group A (Required, 50)
                MKT101 Required
                COM101 Optional
                COM102 Optional
                MKT102 Optional
                MKT103 Optional
                SEC301 Optional
            Group B (Required, 30)
                ICT101 Required
                MGT302 Optional
                MGT303 Optional
                SEC302 Optional
                SEC303 Optional
         */

        //BACBIS v1: major A group
        groupStudyPlanStructures.put('BACBIS_MajorA_GROUPA', REDU_TestData_UTIL.newGroupStudyPlanStructure('BACBIS_MajorA_GROUPA', studyPlans.get('BACBIS_MajorA').Id, null, 'BACBIS_MajorA_GROUPA', SPS_Helper.CATEGORY_REQUIRED, 100, 100, null, null));
        groupStudyPlanStructures.put('BACBIS_MajorA_GROUPA_1', REDU_TestData_UTIL.newGroupStudyPlanStructure('BACBIS_MajorA_GROUPA_1', studyPlans.get('BACBIS_MajorA').Id, null, 'BACBIS_MajorA_GROUPA_1', SPS_Helper.CATEGORY_REQUIRED, 60, 60, null, null));
        groupStudyPlanStructures.put('BACBIS_MajorA_GROUPA_2', REDU_TestData_UTIL.newGroupStudyPlanStructure('BACBIS_MajorA_GROUPA_2', studyPlans.get('BACBIS_MajorA').Id, null, 'BACBIS_MajorA_GROUPA_2', SPS_Helper.CATEGORY_REQUIRED, 40, 40, null, null));
        groupStudyPlanStructures.put('BACBIS_MajorA_GROUPA_1_1', REDU_TestData_UTIL.newGroupStudyPlanStructure('BACBIS_MajorA_GROUPA_1_1', studyPlans.get('BACBIS_MajorA').Id, null, 'BACBIS_MajorA_GROUPA_1_1', SPS_Helper.CATEGORY_OPTIONAL, 20, 40, null, null));
        groupStudyPlanStructures.put('BACBIS_MajorA_GROUPA_1_2', REDU_TestData_UTIL.newGroupStudyPlanStructure('BACBIS_MajorA_GROUPA_1_2', studyPlans.get('BACBIS_MajorA').Id, null, 'BACBIS_MajorA_GROUPA_1_2', SPS_Helper.CATEGORY_OPTIONAL, 20, 40, null, null));
        groupStudyPlanStructures.put('BACBIS_MajorA_GROUPA_2_1', REDU_TestData_UTIL.newGroupStudyPlanStructure('BACBIS_MajorA_GROUPA_2_1', studyPlans.get('BACBIS_MajorA').Id, null, 'BACBIS_MajorA_GROUPA_2_1', SPS_Helper.CATEGORY_REQUIRED, 20, 20, 2, 10));
        groupStudyPlanStructures.put('BACBIS_MajorA_GROUPA_2_2', REDU_TestData_UTIL.newGroupStudyPlanStructure('BACBIS_MajorA_GROUPA_2_2', studyPlans.get('BACBIS_MajorA').Id, null, 'BACBIS_MajorA_GROUPA_2_2', SPS_Helper.CATEGORY_REQUIRED, 20, 20, 2, 10));
        groupStudyPlanStructures.put('BACBIS_MajorA_GROUPB', REDU_TestData_UTIL.newGroupStudyPlanStructure('BACBIS_MajorA_GROUPB', studyPlans.get('BACBIS_MajorA').Id, null, 'BACBIS_MajorA_GROUPB', SPS_Helper.CATEGORY_REQUIRED, 60, 60, null, null));
        groupStudyPlanStructures.put('BACBIS_MajorA_GROUPB_1', REDU_TestData_UTIL.newGroupStudyPlanStructure('BACBIS_MajorA_GROUPB_1', studyPlans.get('BACBIS_MajorA').Id, null, 'BACBIS_MajorA_GROUPB_1', SPS_Helper.CATEGORY_REQUIRED, 20, 20, 2, 10));
        groupStudyPlanStructures.put('BACBIS_MajorA_GROUPB_2', REDU_TestData_UTIL.newGroupStudyPlanStructure('BACBIS_MajorA_GROUPB_2', studyPlans.get('BACBIS_MajorA').Id, null, 'BACBIS_MajorA_GROUPB_2', SPS_Helper.CATEGORY_OPTIONAL, 10, 40, null, null));
        groupStudyPlanStructures.put('BACBIS_MajorA_GROUPB_3', REDU_TestData_UTIL.newGroupStudyPlanStructure('BACBIS_MajorA_GROUPB_3', studyPlans.get('BACBIS_MajorA').Id, null, 'BACBIS_MajorA_GROUPB_3', SPS_Helper.CATEGORY_OPTIONAL, 10, 40, null, null));
        groupStudyPlanStructures.put('BACBIS_MajorA_GROUPC', REDU_TestData_UTIL.newGroupStudyPlanStructure('BACBIS_MajorA_GROUPC', studyPlans.get('BACBIS_MajorA').Id, null, 'BACBIS_MajorA_GROUPC', SPS_Helper.CATEGORY_OPTIONAL, 20, 20, null, null));

        //BACBIS - minor A group
        groupStudyPlanStructures.put('BACBIS_MinorA_GROUPA', REDU_TestData_UTIL.newGroupStudyPlanStructure('BACBIS_MinorA_GROUPA', studyPlans.get('BACBIS_MinorA').Id, null, 'BACBIS_MinorA_GROUPA', SPS_Helper.CATEGORY_REQUIRED, 50, 50, null, null));
        groupStudyPlanStructures.put('BACBIS_MinorA_GROUPB', REDU_TestData_UTIL.newGroupStudyPlanStructure('BACBIS_MinorA_GROUPB', studyPlans.get('BACBIS_MinorA').Id, null, 'BACBIS_MinorA_GROUPB', SPS_Helper.CATEGORY_REQUIRED, 30, 30, null, null));

        //BACBIS - minor B group
        groupStudyPlanStructures.put('BACBIS_MinorB_GROUPA', REDU_TestData_UTIL.newGroupStudyPlanStructure('BACBIS_MinorB_GROUPA', studyPlans.get('BACBIS_MinorB').Id, null, 'BACBIS_MinorB_GROUPA', SPS_Helper.CATEGORY_REQUIRED, 50, 50, null, null));
        groupStudyPlanStructures.put('BACBIS_MinorB_GROUPB', REDU_TestData_UTIL.newGroupStudyPlanStructure('BACBIS_MinorB_GROUPB', studyPlans.get('BACBIS_MinorB').Id, null, 'BACBIS_MinorB_GROUPB', SPS_Helper.CATEGORY_REQUIRED, 30, 30, null, null));

        REDU_SystemMode_UTIL.doInsert(groupStudyPlanStructures.values());

        //BACBIS - major A group hierarchy update
        groupStudyPlanStructures.get('BACBIS_MajorA_GROUPA_1').reduivy__Parent_Study_Plan_Structure__c = groupStudyPlanStructures.get('BACBIS_MajorA_GROUPA').Id;
        groupStudyPlanStructures.get('BACBIS_MajorA_GROUPA_2').reduivy__Parent_Study_Plan_Structure__c = groupStudyPlanStructures.get('BACBIS_MajorA_GROUPA').Id;
        groupStudyPlanStructures.get('BACBIS_MajorA_GROUPA_1_1').reduivy__Parent_Study_Plan_Structure__c = groupStudyPlanStructures.get('BACBIS_MajorA_GROUPA_1').Id;
        groupStudyPlanStructures.get('BACBIS_MajorA_GROUPA_1_2').reduivy__Parent_Study_Plan_Structure__c = groupStudyPlanStructures.get('BACBIS_MajorA_GROUPA_1').Id;
        groupStudyPlanStructures.get('BACBIS_MajorA_GROUPA_2_1').reduivy__Parent_Study_Plan_Structure__c = groupStudyPlanStructures.get('BACBIS_MajorA_GROUPA_2').Id;
        groupStudyPlanStructures.get('BACBIS_MajorA_GROUPA_2_2').reduivy__Parent_Study_Plan_Structure__c = groupStudyPlanStructures.get('BACBIS_MajorA_GROUPA_2').Id;

        groupStudyPlanStructures.get('BACBIS_MajorA_GROUPB_1').reduivy__Parent_Study_Plan_Structure__c = groupStudyPlanStructures.get('BACBIS_MajorA_GROUPB').Id;
        groupStudyPlanStructures.get('BACBIS_MajorA_GROUPB_2').reduivy__Parent_Study_Plan_Structure__c = groupStudyPlanStructures.get('BACBIS_MajorA_GROUPB').Id;
        groupStudyPlanStructures.get('BACBIS_MajorA_GROUPB_3').reduivy__Parent_Study_Plan_Structure__c = groupStudyPlanStructures.get('BACBIS_MajorA_GROUPB').Id;

        REDU_SystemMode_UTIL.doUpdate(groupStudyPlanStructures.values());

        //BACBIS major A units
        //Group A_1_1
        unitStudyPlanStructures.put('BACBIS_MajorA_BUS101', REDU_TestData_UTIL.newUnitStudyPlanStructure('BACBIS_MajorA_BUS101', studyPlans.get('BACBIS_MajorA').Id, groupStudyPlanStructures.get('BACBIS_MajorA_GROUPA_1_1').Id, studyUnits.get('BUS101').Id, 'BACBIS_MajorA_BUS101', SPS_Helper.CATEGORY_REQUIRED, 10, false, null));
        unitStudyPlanStructures.put('BACBIS_MajorA_BUS102', REDU_TestData_UTIL.newUnitStudyPlanStructure('BACBIS_MajorA_BUS102', studyPlans.get('BACBIS_MajorA').Id, groupStudyPlanStructures.get('BACBIS_MajorA_GROUPA_1_1').Id, studyUnits.get('BUS102').Id, 'BACBIS_MajorA_BUS102', SPS_Helper.CATEGORY_OPTIONAL, 10, false, null));
        unitStudyPlanStructures.put('BACBIS_MajorA_BUS103', REDU_TestData_UTIL.newUnitStudyPlanStructure('BACBIS_MajorA_BUS103', studyPlans.get('BACBIS_MajorA').Id, groupStudyPlanStructures.get('BACBIS_MajorA_GROUPA_1_1').Id, studyUnits.get('BUS103').Id, 'BACBIS_MajorA_BUS103', SPS_Helper.CATEGORY_OPTIONAL, 10, false, null));
        unitStudyPlanStructures.put('BACBIS_MajorA_COM101', REDU_TestData_UTIL.newUnitStudyPlanStructure('BACBIS_MajorA_COM101', studyPlans.get('BACBIS_MajorA').Id, groupStudyPlanStructures.get('BACBIS_MajorA_GROUPA_1_1').Id, studyUnits.get('COM101').Id, 'BACBIS_MajorA_COM101', SPS_Helper.CATEGORY_OPTIONAL, 10, false, null));

        //Group A_1_2
        unitStudyPlanStructures.put('BACBIS_MajorA_BUS201', REDU_TestData_UTIL.newUnitStudyPlanStructure('BACBIS_MajorA_BUS201', studyPlans.get('BACBIS_MajorA').Id, groupStudyPlanStructures.get('BACBIS_MajorA_GROUPA_1_2').Id, studyUnits.get('BUS201').Id, 'BACBIS_MajorA_BUS201', SPS_Helper.CATEGORY_REQUIRED, 10, false, null));
        unitStudyPlanStructures.put('BACBIS_MajorA_BUS202', REDU_TestData_UTIL.newUnitStudyPlanStructure('BACBIS_MajorA_BUS202', studyPlans.get('BACBIS_MajorA').Id, groupStudyPlanStructures.get('BACBIS_MajorA_GROUPA_1_2').Id, studyUnits.get('BUS202').Id, 'BACBIS_MajorA_BUS202', SPS_Helper.CATEGORY_OPTIONAL, 10, false, null));
        unitStudyPlanStructures.put('BACBIS_MajorA_BUS203', REDU_TestData_UTIL.newUnitStudyPlanStructure('BACBIS_MajorA_BUS203', studyPlans.get('BACBIS_MajorA').Id, groupStudyPlanStructures.get('BACBIS_MajorA_GROUPA_1_2').Id, studyUnits.get('BUS203').Id, 'BACBIS_MajorA_BUS203', SPS_Helper.CATEGORY_OPTIONAL, 10, false, null));
        unitStudyPlanStructures.put('BACBIS_MajorA_MAT201', REDU_TestData_UTIL.newUnitStudyPlanStructure('BACBIS_MajorA_MAT201', studyPlans.get('BACBIS_MajorA').Id, groupStudyPlanStructures.get('BACBIS_MajorA_GROUPA_1_2').Id, studyUnits.get('MAT201').Id, 'BACBIS_MajorA_MAT201', SPS_Helper.CATEGORY_OPTIONAL, 10, false, null));
        
        //Group A_2_1
        unitStudyPlanStructures.put('BACBIS_MajorA_MKT101', REDU_TestData_UTIL.newUnitStudyPlanStructure('BACBIS_MajorA_MKT101', studyPlans.get('BACBIS_MajorA').Id, groupStudyPlanStructures.get('BACBIS_MajorA_GROUPA_2_1').Id, studyUnits.get('MKT101').Id, 'BACBIS_MajorA_MKT101', SPS_Helper.CATEGORY_OPTIONAL, 10, false, null));
        unitStudyPlanStructures.put('BACBIS_MajorA_MKT102', REDU_TestData_UTIL.newUnitStudyPlanStructure('BACBIS_MajorA_MKT102', studyPlans.get('BACBIS_MajorA').Id, groupStudyPlanStructures.get('BACBIS_MajorA_GROUPA_2_1').Id, studyUnits.get('MKT102').Id, 'BACBIS_MajorA_MKT102', SPS_Helper.CATEGORY_OPTIONAL, 10, false, null));
        unitStudyPlanStructures.put('BACBIS_MajorA_MKT103', REDU_TestData_UTIL.newUnitStudyPlanStructure('BACBIS_MajorA_MKT103', studyPlans.get('BACBIS_MajorA').Id, groupStudyPlanStructures.get('BACBIS_MajorA_GROUPA_2_1').Id, studyUnits.get('MKT103').Id, 'BACBIS_MajorA_MKT103', SPS_Helper.CATEGORY_OPTIONAL, 10, false, null));
        
        //Group A_2_2
        unitStudyPlanStructures.put('BACBIS_MajorA_ICT101', REDU_TestData_UTIL.newUnitStudyPlanStructure('BACBIS_MajorA_ICT101', studyPlans.get('BACBIS_MajorA').Id, groupStudyPlanStructures.get('BACBIS_MajorA_GROUPA_2_2').Id, studyUnits.get('ICT101').Id, 'BACBIS_MajorA_ICT101', SPS_Helper.CATEGORY_REQUIRED, 10, false, null));
        unitStudyPlanStructures.put('BACBIS_MajorA_ICT102', REDU_TestData_UTIL.newUnitStudyPlanStructure('BACBIS_MajorA_ICT102', studyPlans.get('BACBIS_MajorA').Id, groupStudyPlanStructures.get('BACBIS_MajorA_GROUPA_2_2').Id, studyUnits.get('ICT102').Id, 'BACBIS_MajorA_ICT102', SPS_Helper.CATEGORY_OPTIONAL, 10, false, null));
        unitStudyPlanStructures.put('BACBIS_MajorA_ICT103', REDU_TestData_UTIL.newUnitStudyPlanStructure('BACBIS_MajorA_ICT103', studyPlans.get('BACBIS_MajorA').Id, groupStudyPlanStructures.get('BACBIS_MajorA_GROUPA_2_2').Id, studyUnits.get('ICT103').Id, 'BACBIS_MajorA_ICT103', SPS_Helper.CATEGORY_OPTIONAL, 10, false, null));

        //Group B_1
        unitStudyPlanStructures.put('BACBIS_MajorA_MGT301', REDU_TestData_UTIL.newUnitStudyPlanStructure('BACBIS_MajorA_MGT301', studyPlans.get('BACBIS_MajorA').Id, groupStudyPlanStructures.get('BACBIS_MajorA_GROUPB_1').Id, studyUnits.get('MGT301').Id, 'BACBIS_MajorA_MGT301', SPS_Helper.CATEGORY_REQUIRED, 10, false, null));
        unitStudyPlanStructures.put('BACBIS_MajorA_MGT302', REDU_TestData_UTIL.newUnitStudyPlanStructure('BACBIS_MajorA_MGT302', studyPlans.get('BACBIS_MajorA').Id, groupStudyPlanStructures.get('BACBIS_MajorA_GROUPB_1').Id, studyUnits.get('MGT302').Id, 'BACBIS_MajorA_MGT302', SPS_Helper.CATEGORY_REQUIRED, 10, false, null));
        
        //Group B_2
        unitStudyPlanStructures.put('BACBIS_MajorA_MGT303', REDU_TestData_UTIL.newUnitStudyPlanStructure('BACBIS_MajorA_MGT303', studyPlans.get('BACBIS_MajorA').Id, groupStudyPlanStructures.get('BACBIS_MajorA_GROUPB_2').Id, studyUnits.get('MGT303').Id, 'BACBIS_MajorA_MGT303', SPS_Helper.CATEGORY_OPTIONAL, 10, false, null));
        unitStudyPlanStructures.put('BACBIS_MajorA_COM102', REDU_TestData_UTIL.newUnitStudyPlanStructure('BACBIS_MajorA_COM102', studyPlans.get('BACBIS_MajorA').Id, groupStudyPlanStructures.get('BACBIS_MajorA_GROUPB_2').Id, studyUnits.get('COM102').Id, 'BACBIS_MajorA_COM102', SPS_Helper.CATEGORY_OPTIONAL, 10, false, null));
        unitStudyPlanStructures.put('BACBIS_MajorA_COM103', REDU_TestData_UTIL.newUnitStudyPlanStructure('BACBIS_MajorA_COM103', studyPlans.get('BACBIS_MajorA').Id, groupStudyPlanStructures.get('BACBIS_MajorA_GROUPB_2').Id, studyUnits.get('COM103').Id, 'BACBIS_MajorA_COM103', SPS_Helper.CATEGORY_OPTIONAL, 10, false, null));
        
        //Group B_3
        unitStudyPlanStructures.put('BACBIS_MajorA_MAT202', REDU_TestData_UTIL.newUnitStudyPlanStructure('BACBIS_MajorA_MAT202', studyPlans.get('BACBIS_MajorA').Id, groupStudyPlanStructures.get('BACBIS_MajorA_GROUPB_3').Id, studyUnits.get('MAT202').Id, 'BACBIS_MajorA_MAT202', SPS_Helper.CATEGORY_OPTIONAL, 10, false, null));
        unitStudyPlanStructures.put('BACBIS_MajorA_MAT203', REDU_TestData_UTIL.newUnitStudyPlanStructure('BACBIS_MajorA_MAT203', studyPlans.get('BACBIS_MajorA').Id, groupStudyPlanStructures.get('BACBIS_MajorA_GROUPB_3').Id, studyUnits.get('MAT203').Id, 'BACBIS_MajorA_MAT203', SPS_Helper.CATEGORY_OPTIONAL, 10, false, null));
        unitStudyPlanStructures.put('BACBIS_MajorA_SEC301', REDU_TestData_UTIL.newUnitStudyPlanStructure('BACBIS_MajorA_SEC301', studyPlans.get('BACBIS_MajorA').Id, groupStudyPlanStructures.get('BACBIS_MajorA_GROUPB_3').Id, studyUnits.get('SEC301').Id, 'BACBIS_MajorA_SEC301', SPS_Helper.CATEGORY_OPTIONAL, 10, false, null));

        //Group C
        unitStudyPlanStructures.put('BACBIS_MajorA_SEC302', REDU_TestData_UTIL.newUnitStudyPlanStructure('BACBIS_MajorA_SEC302', studyPlans.get('BACBIS_MajorA').Id, groupStudyPlanStructures.get('BACBIS_MajorA_GROUPC').Id, studyUnits.get('SEC302').Id, 'BACBIS_MajorA_SEC302', SPS_Helper.CATEGORY_OPTIONAL, 10, false, null));
        unitStudyPlanStructures.put('BACBIS_MajorA_SEC303', REDU_TestData_UTIL.newUnitStudyPlanStructure('BACBIS_MajorA_SEC303', studyPlans.get('BACBIS_MajorA').Id, groupStudyPlanStructures.get('BACBIS_MajorA_GROUPC').Id, studyUnits.get('SEC303').Id, 'BACBIS_MajorA_SEC303', SPS_Helper.CATEGORY_OPTIONAL, 10, false, null));

        //BACBIS minor A units
        //Group A
        unitStudyPlanStructures.put('BACBIS_MinorA_MAT201', REDU_TestData_UTIL.newUnitStudyPlanStructure('BACBIS_MinorA_MAT201', studyPlans.get('BACBIS_MinorA').Id, groupStudyPlanStructures.get('BACBIS_MinorA_GROUPA').Id, studyUnits.get('MAT201').Id, 'BACBIS_MinorA_MAT201', SPS_Helper.CATEGORY_REQUIRED, 10, false, null));
        unitStudyPlanStructures.put('BACBIS_MinorA_SEC301', REDU_TestData_UTIL.newUnitStudyPlanStructure('BACBIS_MinorA_SEC301', studyPlans.get('BACBIS_MinorA').Id, groupStudyPlanStructures.get('BACBIS_MinorA_GROUPA').Id, studyUnits.get('SEC301').Id, 'BACBIS_MinorA_SEC301', SPS_Helper.CATEGORY_REQUIRED, 10, false, null));
        unitStudyPlanStructures.put('BACBIS_MinorA_BUS102', REDU_TestData_UTIL.newUnitStudyPlanStructure('BACBIS_MinorA_BUS102', studyPlans.get('BACBIS_MinorA').Id, groupStudyPlanStructures.get('BACBIS_MinorA_GROUPA').Id, studyUnits.get('BUS102').Id, 'BACBIS_MinorA_BUS102', SPS_Helper.CATEGORY_OPTIONAL, 10, false, null));
        unitStudyPlanStructures.put('BACBIS_MinorA_BUS103', REDU_TestData_UTIL.newUnitStudyPlanStructure('BACBIS_MinorA_BUS103', studyPlans.get('BACBIS_MinorA').Id, groupStudyPlanStructures.get('BACBIS_MinorA_GROUPA').Id, studyUnits.get('BUS103').Id, 'BACBIS_MinorA_BUS103', SPS_Helper.CATEGORY_OPTIONAL, 10, false, null));
        unitStudyPlanStructures.put('BACBIS_MinorA_COM101', REDU_TestData_UTIL.newUnitStudyPlanStructure('BACBIS_MinorA_COM101', studyPlans.get('BACBIS_MinorA').Id, groupStudyPlanStructures.get('BACBIS_MinorA_GROUPA').Id, studyUnits.get('COM101').Id, 'BACBIS_MinorA_COM101', SPS_Helper.CATEGORY_OPTIONAL, 10, false, null));
        unitStudyPlanStructures.put('BACBIS_MinorA_COM102', REDU_TestData_UTIL.newUnitStudyPlanStructure('BACBIS_MinorA_COM102', studyPlans.get('BACBIS_MinorA').Id, groupStudyPlanStructures.get('BACBIS_MinorA_GROUPA').Id, studyUnits.get('COM102').Id, 'BACBIS_MinorA_COM102', SPS_Helper.CATEGORY_OPTIONAL, 10, false, null));
        
        //Group B
        unitStudyPlanStructures.put('BACBIS_MinorA_MAT202', REDU_TestData_UTIL.newUnitStudyPlanStructure('BACBIS_MinorA_MAT202', studyPlans.get('BACBIS_MinorA').Id, groupStudyPlanStructures.get('BACBIS_MinorA_GROUPB').Id, studyUnits.get('MAT202').Id, 'BACBIS_MinorA_MAT202', SPS_Helper.CATEGORY_REQUIRED, 10, false, null));
        unitStudyPlanStructures.put('BACBIS_MinorA_MGT301', REDU_TestData_UTIL.newUnitStudyPlanStructure('BACBIS_MinorA_MGT301', studyPlans.get('BACBIS_MinorA').Id, groupStudyPlanStructures.get('BACBIS_MinorA_GROUPB').Id, studyUnits.get('MGT301').Id, 'BACBIS_MinorA_MGT301', SPS_Helper.CATEGORY_OPTIONAL, 10, false, null));
        unitStudyPlanStructures.put('BACBIS_MinorA_BUS202', REDU_TestData_UTIL.newUnitStudyPlanStructure('BACBIS_MinorA_BUS202', studyPlans.get('BACBIS_MinorA').Id, groupStudyPlanStructures.get('BACBIS_MinorA_GROUPB').Id, studyUnits.get('BUS202').Id, 'BACBIS_MinorA_BUS202', SPS_Helper.CATEGORY_OPTIONAL, 10, false, null));
        unitStudyPlanStructures.put('BACBIS_MinorA_BUS203', REDU_TestData_UTIL.newUnitStudyPlanStructure('BACBIS_MinorA_BUS203', studyPlans.get('BACBIS_MinorA').Id, groupStudyPlanStructures.get('BACBIS_MinorA_GROUPB').Id, studyUnits.get('BUS203').Id, 'BACBIS_MinorA_BUS203', SPS_Helper.CATEGORY_OPTIONAL, 10, false, null));
        unitStudyPlanStructures.put('BACBIS_MinorA_SEC302', REDU_TestData_UTIL.newUnitStudyPlanStructure('BACBIS_MinorA_SEC302', studyPlans.get('BACBIS_MinorA').Id, groupStudyPlanStructures.get('BACBIS_MinorA_GROUPB').Id, studyUnits.get('SEC302').Id, 'BACBIS_MinorA_SEC302', SPS_Helper.CATEGORY_OPTIONAL, 10, false, null));
        
        //BACBIS minor B units

        //Group A
        unitStudyPlanStructures.put('BACBIS_MinorB_MKT101', REDU_TestData_UTIL.newUnitStudyPlanStructure('BACBIS_MinorB_MKT101', studyPlans.get('BACBIS_MinorB').Id, groupStudyPlanStructures.get('BACBIS_MinorB_GROUPA').Id, studyUnits.get('MKT101').Id, 'BACBIS_MinorB_MKT101', SPS_Helper.CATEGORY_REQUIRED, 10, false, null));
        unitStudyPlanStructures.put('BACBIS_MinorB_COM101', REDU_TestData_UTIL.newUnitStudyPlanStructure('BACBIS_MinorB_COM101', studyPlans.get('BACBIS_MinorB').Id, groupStudyPlanStructures.get('BACBIS_MinorB_GROUPA').Id, studyUnits.get('COM101').Id, 'BACBIS_MinorB_COM101', SPS_Helper.CATEGORY_OPTIONAL, 10, false, null));
        unitStudyPlanStructures.put('BACBIS_MinorB_COM102', REDU_TestData_UTIL.newUnitStudyPlanStructure('BACBIS_MinorB_COM102', studyPlans.get('BACBIS_MinorB').Id, groupStudyPlanStructures.get('BACBIS_MinorB_GROUPA').Id, studyUnits.get('COM102').Id, 'BACBIS_MinorB_COM102', SPS_Helper.CATEGORY_OPTIONAL, 10, false, null));
        unitStudyPlanStructures.put('BACBIS_MinorB_MKT102', REDU_TestData_UTIL.newUnitStudyPlanStructure('BACBIS_MinorB_MKT102', studyPlans.get('BACBIS_MinorB').Id, groupStudyPlanStructures.get('BACBIS_MinorB_GROUPA').Id, studyUnits.get('MKT102').Id, 'BACBIS_MinorB_MKT102', SPS_Helper.CATEGORY_OPTIONAL, 10, false, null));
        unitStudyPlanStructures.put('BACBIS_MinorB_MKT103', REDU_TestData_UTIL.newUnitStudyPlanStructure('BACBIS_MinorB_MKT103', studyPlans.get('BACBIS_MinorB').Id, groupStudyPlanStructures.get('BACBIS_MinorB_GROUPA').Id, studyUnits.get('MKT103').Id, 'BACBIS_MinorB_MKT103', SPS_Helper.CATEGORY_OPTIONAL, 10, false, null));
        unitStudyPlanStructures.put('BACBIS_MinorB_SEC301', REDU_TestData_UTIL.newUnitStudyPlanStructure('BACBIS_MinorB_SEC301', studyPlans.get('BACBIS_MinorB').Id, groupStudyPlanStructures.get('BACBIS_MinorB_GROUPA').Id, studyUnits.get('SEC301').Id, 'BACBIS_MinorB_SEC301', SPS_Helper.CATEGORY_OPTIONAL, 10, false, null));
        
        //Group B
        unitStudyPlanStructures.put('BACBIS_MinorB_ICT101', REDU_TestData_UTIL.newUnitStudyPlanStructure('BACBIS_MinorB_ICT101', studyPlans.get('BACBIS_MinorB').Id, groupStudyPlanStructures.get('BACBIS_MinorB_GROUPB').Id, studyUnits.get('ICT101').Id, 'BACBIS_MinorB_ICT101', SPS_Helper.CATEGORY_REQUIRED, 10, false, null));
        unitStudyPlanStructures.put('BACBIS_MinorB_MGT302', REDU_TestData_UTIL.newUnitStudyPlanStructure('BACBIS_MinorB_MGT302', studyPlans.get('BACBIS_MinorB').Id, groupStudyPlanStructures.get('BACBIS_MinorB_GROUPB').Id, studyUnits.get('MGT302').Id, 'BACBIS_MinorB_MGT302', SPS_Helper.CATEGORY_OPTIONAL, 10, false, null));
        unitStudyPlanStructures.put('BACBIS_MinorB_MGT303', REDU_TestData_UTIL.newUnitStudyPlanStructure('BACBIS_MinorB_MGT303', studyPlans.get('BACBIS_MinorB').Id, groupStudyPlanStructures.get('BACBIS_MinorB_GROUPB').Id, studyUnits.get('MGT303').Id, 'BACBIS_MinorB_MGT303', SPS_Helper.CATEGORY_OPTIONAL, 10, false, null));
        unitStudyPlanStructures.put('BACBIS_MinorB_SEC302', REDU_TestData_UTIL.newUnitStudyPlanStructure('BACBIS_MinorB_SEC302', studyPlans.get('BACBIS_MinorB').Id, groupStudyPlanStructures.get('BACBIS_MinorB_GROUPB').Id, studyUnits.get('SEC302').Id, 'BACBIS_MinorB_SEC302', SPS_Helper.CATEGORY_OPTIONAL, 10, false, null));
        unitStudyPlanStructures.put('BACBIS_MinorB_SEC303', REDU_TestData_UTIL.newUnitStudyPlanStructure('BACBIS_MinorB_SEC303', studyPlans.get('BACBIS_MinorB').Id, groupStudyPlanStructures.get('BACBIS_MinorB_GROUPB').Id, studyUnits.get('SEC303').Id, 'BACBIS_MinorB_SEC303', SPS_Helper.CATEGORY_OPTIONAL, 10, false, null));
        
        REDU_SystemMode_UTIL.doInsert(unitStudyPlanStructures.values());

        if (validateCheckpoint(SPS_Helper.getApiName(), skipAfterObject)) {
            unmuteTriggers();
            unmuteRollup();
            return;
        }

        // //copy the study unit requirements to study plan unit requirements - no longer require this
        // for (reduivy__Study_Plan_Structure__c unitSps : unitStudyPlanStructures.values()) {
        //     for (reduivy__Study_Unit_Requirement__c sur : studyUnitReqs.values()) {
        //         if (unitSps.reduivy__Study_Unit__c == sur.reduivy__Study_Unit__c) {
        //             String mapKey = unitSps.reduivy__Study_Plan__c + '_' + unitSps.Name + '_' + sur.Name;
        //             reduivy__Study_Plan_Unit_Requirement__c spur;

        //             if (sur.reduivy__Requirement_Type__c == SUR_Helper.REQTYPE_CREDITS) {
        //                 spur = REDU_TestData_UTIL.newCreditsStudyPlanUnitRequirement(mapKey, unitSps.Id, sur.reduivy__Requirement_ID__c, sur.reduivy__Credits__c);
        //             } else if (sur.reduivy__Requirement_Type__c == SUR_Helper.REQTYPE_OTHER) {
        //                 spur = REDU_TestData_UTIL.newOtherStudyPlanUnitRequirement(mapKey, unitSps.Id, sur.reduivy__Requirement_ID__c);
        //             } else {
        //                 spur = REDU_TestData_UTIL.newUnitStudyPlanUnitRequirement(mapKey, unitSps.Id, sur.reduivy__Required_Study_Unit__c, sur.reduivy__Requirement_ID__c, sur.reduivy__Requirement_Type__c);
        //             }

        //             studyPlanUnitReqs.put(mapKey, spur);
        //         }
        //     }
        // }

        // insert studyPlanUnitReqs.values();

        // if (validateCheckpoint(SPR_Helper.getApiName(), skipAfterObject)) {
        //     return;
        // }

        //study plan option for Major/Minor
        studyPlanOptions.put('BACBIS_MajorA_MinorA', REDU_TestData_UTIL.newStudyPlanOption('BACBIS_MajorA_MinorA', studyPlans.get('BACBIS_MajorA').Id, studyPlans.get('BACBIS_MinorA').Id, SPO_Helper.COMPLETION_REQUIREMENT_MANDATORY, SPO_Helper.STATUS_ACTIVE));
        studyPlanOptions.put('BACBIS_MajorA_MinorB', REDU_TestData_UTIL.newStudyPlanOption('BACBIS_MajorA_MinorB', studyPlans.get('BACBIS_MajorA').Id, studyPlans.get('BACBIS_MinorB').Id, SPO_Helper.COMPLETION_REQUIREMENT_OPTIONAL, SPO_Helper.STATUS_ACTIVE));

        REDU_SystemMode_UTIL.doInsert(studyPlanOptions.values());

        if (validateCheckpoint(SPO_Helper.getApiName(), skipAfterObject)) {
            unmuteTriggers();
            unmuteRollup();
            return;
        }

        //study pathway, study pathway term and pathway unit
        String spwActiveStatus = SPW_Helper.STATUS_ACTIVE;
        studyPathways.put('BACBIS_MajorA_DEFAULT', REDU_TestData_UTIL.newStudyPathway('BACBIS_MajorA_DEFAULT', studyPlans.get('BACBIS_MajorA').Id, 'Bachelor of Business - Major A Default Pathway', spwActiveStatus, true));
        studyPathways.put('BACBIS_MinorA_DEFAULT', REDU_TestData_UTIL.newStudyPathway('BACBIS_MinorA_DEFAULT', studyPlans.get('BACBIS_MinorA').Id, 'Bachelor of Business - Minor A Default Pathway', spwActiveStatus, true));
        studyPathways.put('BACBIS_MinorB_DEFAULT', REDU_TestData_UTIL.newStudyPathway('BACBIS_MinorB_DEFAULT', studyPlans.get('BACBIS_MinorB').Id, 'Bachelor of Business - Minor B Default Pathway', spwActiveStatus, true));

        REDU_SystemMode_UTIL.doInsert(studyPathways.values());

        if (validateCheckpoint(SPW_Helper.getApiName(), skipAfterObject)) {
            unmuteTriggers();
            unmuteRollup();
            return;
        }

        studyPathwayTerms.put('BACBIS_MajorA_DEFAULT_T1', REDU_TestData_UTIL.newStudyPathwayTerm('BACBIS_MajorA_DEFAULT_T1', studyPathways.get('BACBIS_MajorA_DEFAULT').Id, 1, SPT_Helper.ENROLLMENTMETHOD_MANUAL, 40, 40));
        studyPathwayTerms.put('BACBIS_MajorA_DEFAULT_T2', REDU_TestData_UTIL.newStudyPathwayTerm('BACBIS_MajorA_DEFAULT_T2', studyPathways.get('BACBIS_MajorA_DEFAULT').Id, 2, SPT_Helper.ENROLLMENTMETHOD_MANUAL, 40, 40));
        studyPathwayTerms.put('BACBIS_MajorA_DEFAULT_T3', REDU_TestData_UTIL.newStudyPathwayTerm('BACBIS_MajorA_DEFAULT_T3', studyPathways.get('BACBIS_MajorA_DEFAULT').Id, 3, SPT_Helper.ENROLLMENTMETHOD_MANUAL, 40, 40));
        studyPathwayTerms.put('BACBIS_MajorA_DEFAULT_T4', REDU_TestData_UTIL.newStudyPathwayTerm('BACBIS_MajorA_DEFAULT_T4', studyPathways.get('BACBIS_MajorA_DEFAULT').Id, 4, SPT_Helper.ENROLLMENTMETHOD_MANUAL, 40, 40));

        studyPathwayTerms.put('BACBIS_MinorA_DEFAULT_T1', REDU_TestData_UTIL.newStudyPathwayTerm('BACBIS_MinorA_DEFAULT_T1', studyPathways.get('BACBIS_MinorA_DEFAULT').Id, 1, SPT_Helper.ENROLLMENTMETHOD_MANUAL, 20, 20));
        studyPathwayTerms.put('BACBIS_MinorA_DEFAULT_T2', REDU_TestData_UTIL.newStudyPathwayTerm('BACBIS_MinorA_DEFAULT_T2', studyPathways.get('BACBIS_MinorA_DEFAULT').Id, 2, SPT_Helper.ENROLLMENTMETHOD_MANUAL, 20, 20));
        studyPathwayTerms.put('BACBIS_MinorA_DEFAULT_T3', REDU_TestData_UTIL.newStudyPathwayTerm('BACBIS_MinorA_DEFAULT_T3', studyPathways.get('BACBIS_MinorA_DEFAULT').Id, 3, SPT_Helper.ENROLLMENTMETHOD_MANUAL, 20, 20));
        studyPathwayTerms.put('BACBIS_MinorA_DEFAULT_T4', REDU_TestData_UTIL.newStudyPathwayTerm('BACBIS_MinorA_DEFAULT_T4', studyPathways.get('BACBIS_MinorA_DEFAULT').Id, 4, SPT_Helper.ENROLLMENTMETHOD_MANUAL, 20, 20));

        studyPathwayTerms.put('BACBIS_MinorB_DEFAULT_T1', REDU_TestData_UTIL.newStudyPathwayTerm('BACBIS_MinorB_DEFAULT_T1', studyPathways.get('BACBIS_MinorB_DEFAULT').Id, 1, SPT_Helper.ENROLLMENTMETHOD_MANUAL, 20, 20));
        studyPathwayTerms.put('BACBIS_MinorB_DEFAULT_T2', REDU_TestData_UTIL.newStudyPathwayTerm('BACBIS_MinorB_DEFAULT_T2', studyPathways.get('BACBIS_MinorB_DEFAULT').Id, 2, SPT_Helper.ENROLLMENTMETHOD_MANUAL, 20, 20));
        studyPathwayTerms.put('BACBIS_MinorB_DEFAULT_T3', REDU_TestData_UTIL.newStudyPathwayTerm('BACBIS_MinorB_DEFAULT_T3', studyPathways.get('BACBIS_MinorB_DEFAULT').Id, 3, SPT_Helper.ENROLLMENTMETHOD_MANUAL, 20, 20));
        studyPathwayTerms.put('BACBIS_MinorB_DEFAULT_T4', REDU_TestData_UTIL.newStudyPathwayTerm('BACBIS_MinorB_DEFAULT_T4', studyPathways.get('BACBIS_MinorB_DEFAULT').Id, 4, SPT_Helper.ENROLLMENTMETHOD_MANUAL, 20, 20));

        REDU_SystemMode_UTIL.doInsert(studyPathwayTerms.values());

        if (validateCheckpoint(SPT_Helper.getApiName(), skipAfterObject)) {
            unmuteTriggers();
            unmuteRollup();
            return;
        }

        //BACBIS_MajorA_DEFAULT study pathway unit
        /*
            Term 1
                BUS101
                BUS102
                BUS103
                COM101
            Term 2
                BUS201
                BUS202
                2 units from Group A-2-1
            Term 3
                MGT301
                MGT302
                2 units from Group A-2-2
            Term 4
                2 units from Group B-2
                2 units from Group B-3
         */
        studyPathwayUnits.put('BACBIS_MajorA_DEFAULT_T1_BUS101', REDU_TestData_UTIL.newUnitStudyPathwayUnit('BACBIS_MajorA_DEFAULT_T1_BUS101', studyPathwayTerms.get('BACBIS_MajorA_DEFAULT_T1').Id, studyUnits.get('BUS101').Id, null));
        studyPathwayUnits.put('BACBIS_MajorA_DEFAULT_T1_BUS102', REDU_TestData_UTIL.newUnitStudyPathwayUnit('BACBIS_MajorA_DEFAULT_T1_BUS102', studyPathwayTerms.get('BACBIS_MajorA_DEFAULT_T1').Id, studyUnits.get('BUS102').Id, null));
        studyPathwayUnits.put('BACBIS_MajorA_DEFAULT_T1_BUS103', REDU_TestData_UTIL.newUnitStudyPathwayUnit('BACBIS_MajorA_DEFAULT_T1_BUS103', studyPathwayTerms.get('BACBIS_MajorA_DEFAULT_T1').Id, studyUnits.get('BUS103').Id, null));
        studyPathwayUnits.put('BACBIS_MajorA_DEFAULT_T1_COM101', REDU_TestData_UTIL.newUnitStudyPathwayUnit('BACBIS_MajorA_DEFAULT_T1_COM101', studyPathwayTerms.get('BACBIS_MajorA_DEFAULT_T1').Id, studyUnits.get('COM101').Id, null));

        studyPathwayUnits.put('BACBIS_MajorA_DEFAULT_T2_BUS201', REDU_TestData_UTIL.newUnitStudyPathwayUnit('BACBIS_MajorA_DEFAULT_T2_BUS201', studyPathwayTerms.get('BACBIS_MajorA_DEFAULT_T2').Id, studyUnits.get('BUS201').Id, null));
        studyPathwayUnits.put('BACBIS_MajorA_DEFAULT_T2_BUS202', REDU_TestData_UTIL.newUnitStudyPathwayUnit('BACBIS_MajorA_DEFAULT_T2_BUS202', studyPathwayTerms.get('BACBIS_MajorA_DEFAULT_T2').Id, studyUnits.get('BUS202').Id, null));
        studyPathwayUnits.put('BACBIS_MajorA_DEFAULT_T2_GROUPA_2_1', REDU_TestData_UTIL.newGroupStudyPathwayUnit('BACBIS_MajorA_DEFAULT_T2_GROUPA_2_1', studyPathwayTerms.get('BACBIS_MajorA_DEFAULT_T2').Id, groupStudyPlanStructures.get('BACBIS_MajorA_GROUPA_2_1').Id, 2, null));

        studyPathwayUnits.put('BACBIS_MajorA_DEFAULT_T3_MGT301', REDU_TestData_UTIL.newUnitStudyPathwayUnit('BACBIS_MajorA_DEFAULT_T3_MGT301', studyPathwayTerms.get('BACBIS_MajorA_DEFAULT_T3').Id, studyUnits.get('MGT301').Id, null));
        studyPathwayUnits.put('BACBIS_MajorA_DEFAULT_T3_MGT302', REDU_TestData_UTIL.newUnitStudyPathwayUnit('BACBIS_MajorA_DEFAULT_T3_MGT302', studyPathwayTerms.get('BACBIS_MajorA_DEFAULT_T3').Id, studyUnits.get('MGT302').Id, null));
        studyPathwayUnits.put('BACBIS_MajorA_DEFAULT_T3_GROUPA_2_2', REDU_TestData_UTIL.newGroupStudyPathwayUnit('BACBIS_MajorA_DEFAULT_T3_GROUPA_2_2', studyPathwayTerms.get('BACBIS_MajorA_DEFAULT_T3').Id, groupStudyPlanStructures.get('BACBIS_MajorA_GROUPA_2_2').Id, 2, null));

        studyPathwayUnits.put('BACBIS_MajorA_DEFAULT_T4_GROUPB_2', REDU_TestData_UTIL.newGroupStudyPathwayUnit('BACBIS_MajorA_DEFAULT_T4_GROUPB_2', studyPathwayTerms.get('BACBIS_MajorA_DEFAULT_T4').Id, groupStudyPlanStructures.get('BACBIS_MajorA_GROUPB_2').Id, 2, null));
        studyPathwayUnits.put('BACBIS_MajorA_DEFAULT_T4_GROUPB_3', REDU_TestData_UTIL.newGroupStudyPathwayUnit('BACBIS_MajorA_DEFAULT_T4_GROUPB_3', studyPathwayTerms.get('BACBIS_MajorA_DEFAULT_T4').Id, groupStudyPlanStructures.get('BACBIS_MajorA_GROUPB_3').Id, 2, null));

        //BACBIS_MinorA_DEFAULT study pathway unit
        /*
            Term 1
                MAT201
                1 units from Group A
            Term 2
                MAT202
                1 units from Group A
            Term 3
                1 units from Group A
				1 units from Group B
            Term 4
                2 units from Group B
         */	
        studyPathwayUnits.put('BACBIS_MinorA_DEFAULT_T1_MAT201', REDU_TestData_UTIL.newUnitStudyPathwayUnit('BACBIS_MinorA_DEFAULT_T1_MAT201', studyPathwayTerms.get('BACBIS_MinorA_DEFAULT_T1').Id, studyUnits.get('MAT201').Id, null));
        studyPathwayUnits.put('BACBIS_MinorA_DEFAULT_T1_COMGROUPA', REDU_TestData_UTIL.newGroupStudyPathwayUnit('BACBIS_MinorA_DEFAULT_T1_COMGROUPA', studyPathwayTerms.get('BACBIS_MinorA_DEFAULT_T1').Id, groupStudyPlanStructures.get('BACBIS_MinorA_GROUPA').Id, 1, null));

        studyPathwayUnits.put('BACBIS_MinorA_DEFAULT_T2_MAT202', REDU_TestData_UTIL.newUnitStudyPathwayUnit('BACBIS_MinorA_DEFAULT_T2_MAT202', studyPathwayTerms.get('BACBIS_MinorA_DEFAULT_T2').Id, studyUnits.get('MAT202').Id, null));
        studyPathwayUnits.put('BACBIS_MinorA_DEFAULT_T2_COMGROUPA', REDU_TestData_UTIL.newGroupStudyPathwayUnit('BACBIS_MinorA_DEFAULT_T2_COMGROUPA', studyPathwayTerms.get('BACBIS_MinorA_DEFAULT_T2').Id, groupStudyPlanStructures.get('BACBIS_MinorA_GROUPA').Id, 1, null));

        studyPathwayUnits.put('BACBIS_MinorA_DEFAULT_T3_COMGROUPA', REDU_TestData_UTIL.newGroupStudyPathwayUnit('BACBIS_MinorA_DEFAULT_T3_COMGROUPA', studyPathwayTerms.get('BACBIS_MinorA_DEFAULT_T3').Id, groupStudyPlanStructures.get('BACBIS_MinorA_GROUPA').Id, 1, null));
        studyPathwayUnits.put('BACBIS_MinorA_DEFAULT_T3_COMGROUPB', REDU_TestData_UTIL.newGroupStudyPathwayUnit('BACBIS_MinorA_DEFAULT_T3_COMGROUPB', studyPathwayTerms.get('BACBIS_MinorA_DEFAULT_T3').Id, groupStudyPlanStructures.get('BACBIS_MinorA_GROUPB').Id, 1, null));
        
        studyPathwayUnits.put('BACBIS_MinorA_DEFAULT_T4_COMGROUPB', REDU_TestData_UTIL.newGroupStudyPathwayUnit('BACBIS_MinorA_DEFAULT_T4_COMGROUPB', studyPathwayTerms.get('BACBIS_MinorA_DEFAULT_T4').Id, groupStudyPlanStructures.get('BACBIS_MinorA_GROUPB').Id, 2, null));

        //BACBIS_MinorB_DEFAULT study pathway unit
        /*
            Term 1
                MKT101
                1 units from Group A
            Term 2
                ICT101
                1 units from Group A
            Term 3
                1 units from Group A
				1 units from Group B
            Term 4
                2 units from Group B
         */	
        studyPathwayUnits.put('BACBIS_MinorB_DEFAULT_T1_MAT201', REDU_TestData_UTIL.newUnitStudyPathwayUnit('BACBIS_MinorB_DEFAULT_T1_MAT201', studyPathwayTerms.get('BACBIS_MinorB_DEFAULT_T1').Id, studyUnits.get('MAT201').Id, null));
        studyPathwayUnits.put('BACBIS_MinorB_DEFAULT_T1_COMGROUPA', REDU_TestData_UTIL.newGroupStudyPathwayUnit('BACBIS_MinorB_DEFAULT_T1_COMGROUPA', studyPathwayTerms.get('BACBIS_MinorB_DEFAULT_T1').Id, groupStudyPlanStructures.get('BACBIS_MinorB_GROUPA').Id, 1, null));

        studyPathwayUnits.put('BACBIS_MinorB_DEFAULT_T2_MAT202', REDU_TestData_UTIL.newUnitStudyPathwayUnit('BACBIS_MinorB_DEFAULT_T2_MAT202', studyPathwayTerms.get('BACBIS_MinorB_DEFAULT_T2').Id, studyUnits.get('MAT202').Id, null));
        studyPathwayUnits.put('BACBIS_MinorB_DEFAULT_T2_COMGROUPA', REDU_TestData_UTIL.newGroupStudyPathwayUnit('BACBIS_MinorB_DEFAULT_T2_COMGROUPA', studyPathwayTerms.get('BACBIS_MinorB_DEFAULT_T2').Id, groupStudyPlanStructures.get('BACBIS_MinorB_GROUPA').Id, 1, null));

        studyPathwayUnits.put('BACBIS_MinorB_DEFAULT_T3_COMGROUPA', REDU_TestData_UTIL.newGroupStudyPathwayUnit('BACBIS_MinorB_DEFAULT_T3_COMGROUPA', studyPathwayTerms.get('BACBIS_MinorB_DEFAULT_T3').Id, groupStudyPlanStructures.get('BACBIS_MinorB_GROUPA').Id, 1, null));
        studyPathwayUnits.put('BACBIS_MinorB_DEFAULT_T3_COMGROUPB', REDU_TestData_UTIL.newGroupStudyPathwayUnit('BACBIS_MinorB_DEFAULT_T3_COMGROUPB', studyPathwayTerms.get('BACBIS_MinorB_DEFAULT_T3').Id, groupStudyPlanStructures.get('BACBIS_MinorB_GROUPB').Id, 1, null));
        
        studyPathwayUnits.put('BACBIS_MinorB_DEFAULT_T4_COMGROUPB', REDU_TestData_UTIL.newGroupStudyPathwayUnit('BACBIS_MinorB_DEFAULT_T4_COMGROUPB', studyPathwayTerms.get('BACBIS_MinorB_DEFAULT_T4').Id, groupStudyPlanStructures.get('BACBIS_MinorB_GROUPB').Id, 2, null));
    
        REDU_SystemMode_UTIL.doInsert(studyPathwayUnits.values());

        if (validateCheckpoint(SPU_Helper.getApiName(), skipAfterObject)) {
            unmuteTriggers();
            unmuteRollup();
            return;
        }

        //Admission Path
        admissionPaths.put('DIRECT_ADMISSION_PATH', REDU_TestData_UTIL.newAdmissionPath('DIRECT_ADMISSION_PATH', 'Direct Admission Path', 'Direct Admission', 1, null));

        REDU_SystemMode_UTIL.doInsert(admissionPaths.values());

        if (validateCheckpoint(ADP_Helper.getApiName(), skipAfterObject)) {
            unmuteTriggers();
            unmuteRollup();
            return;
        }

        //Admission Path Option
        admissionPathOptions.put('DIRECT_ADMISSION_PATH_PARTNER_PROGRAM_A', REDU_TestData_UTIL.newAdmissionPathOption('DIRECT_ADMISSION_PATH_PARTNER_PROGRAM_A', 'Direct Admission Path - Ext Program', admissionPaths.get('DIRECT_ADMISSION_PATH').Id, agreementRecognitions.get('PARTNER_PROGRAM_A').Id));

        REDU_SystemMode_UTIL.doInsert(admissionPathOptions.values());

        if (validateCheckpoint(ADO_Helper.getApiName(), skipAfterObject)) {
            unmuteTriggers();
            unmuteRollup();
            return;
        }

        //Study Program Admission Path
        studyProgramAdmissionPaths.put('BACBIS_DIRECT_ADMISSION_PATH_PARTNER_PROGRAM_A', REDU_TestData_UTIL.newStudyProgramAdmissionPath('BACBIS_DIRECT_ADMISSION_PATH_PARTNER_PROGRAM_A', 'Direct Admission Path - Ext Program for Bachelor of Business', studyPrograms.get('BACBIS').Id, admissionPaths.get('DIRECT_ADMISSION_PATH').Id, null));

        REDU_SystemMode_UTIL.doInsert(studyProgramAdmissionPaths.values());

        if (validateCheckpoint(SAP_Helper.getApiName(), skipAfterObject)) {
            unmuteTriggers();
            unmuteRollup();
            return;
        }

        //Study Voucher
        studyVouchers.put('DEPOSIT_10%_DISCOUNT', REDU_TestData_UTIL.newStudyVoucher('DEPOSIT_10%_DISCOUNT', 'DEPOSIT 10% DISCOUNT', 'DEPOSIT_10%_DISCOUNT', SVO_Helper.VOUCHER_TYPE_PERCENTAGE, 10, eduInst.Id, SVO_Helper.STATUS_ACTIVE, Date.newInstance(2023, 01, 01), Date.newInstance(2026, 12, 31), 1, SVO_Helper.APPLICABLE_ITEM_TYPES_DEPOSIT, 50));
        studyVouchers.put('APPLICATION_10%_DISCOUNT', REDU_TestData_UTIL.newStudyVoucher('APPLICATION_10%_DISCOUNT', 'APPLICATION 10% DISCOUNT', 'APPLICATION_10%_DISCOUNT', SVO_Helper.VOUCHER_TYPE_PERCENTAGE, 10, eduInst.Id, SVO_Helper.STATUS_ACTIVE, Date.newInstance(2023, 01, 01), Date.newInstance(2026, 12, 31), 1, SVO_Helper.APPLICABLE_ITEM_TYPES_APPLICATION, 50));
        studyVouchers.put('TUITION_10%_DISCOUNT', REDU_TestData_UTIL.newStudyVoucher('TUITION_10%_DISCOUNT', 'TUITION 10% DISCOUNT', 'TUITION_10%_DISCOUNT', SVO_Helper.VOUCHER_TYPE_PERCENTAGE, 10, eduInst.Id, SVO_Helper.STATUS_ACTIVE, Date.newInstance(2023, 01, 01), Date.newInstance(2026, 12, 31), 1, SVO_Helper.APPLICABLE_ITEM_TYPES_TUITION, 50));
        studyVouchers.put('RESIDENTIAL_10%_DISCOUNT', REDU_TestData_UTIL.newStudyVoucher('RESIDENTIAL_10%_DISCOUNT', 'RESIDENTIAL 10% DISCOUNT', 'RESIDENTIAL_10%_DISCOUNT', SVO_Helper.VOUCHER_TYPE_PERCENTAGE, 10, eduInst.Id, SVO_Helper.STATUS_ACTIVE, Date.newInstance(2023, 01, 01), Date.newInstance(2026, 12, 31), 1, SVO_Helper.APPLICABLE_ITEM_TYPES_RESIDENTIAL, 50));
        studyVouchers.put('MISCELLANEOUS_10%_DISCOUNT', REDU_TestData_UTIL.newStudyVoucher('MISCELLANEOUS_10%_DISCOUNT', 'MISCELLANEOUS 10% DISCOUNT', 'MISCELLANEOUS_10%_DISCOUNT', SVO_Helper.VOUCHER_TYPE_PERCENTAGE, 10, eduInst.Id, SVO_Helper.STATUS_ACTIVE, Date.newInstance(2023, 01, 01), Date.newInstance(2026, 12, 31), 1, SVO_Helper.APPLICABLE_ITEM_TYPES_MISCELLANEOUS, 50));

        REDU_SystemMode_UTIL.doInsert(studyVouchers.values());

        if (validateCheckpoint(SVO_Helper.getApiName(), skipAfterObject)) {
            unmuteTriggers();
            unmuteRollup();
            return; 
        }

        //System Variable
        String studentIdSyvKey = CON_GenerateStudentID_EXE.KEY_STUDENT_ID;
        Integer studentCount = FULLDATA ? 20 : 3; //full data will create 20 students, otherwise 3 students only
        systemVariables.put(studentIdSyvKey, REDU_TestData_UTIL.newSystemVariable(studentIdSyvKey, studentIdSyvKey, 'STUD-{0000}', studentCount));

        REDU_SystemMode_UTIL.doInsert(systemVariables.values());

        if (validateCheckpoint(SYV_Helper.getApiName(), skipAfterObject)) {
            unmuteTriggers();
            unmuteRollup();
            return; 
        }
        
        //Study Requirement Set
        studyRequirementSets.put('SRS_General', REDU_TestData_UTIL.newStudyRequirementSet('SRS_General', 'Study Requirement Set General', 'SRS_General', IPA_Helper.getApiName(), 'reduivy__Contact__c', 'AND(TEXT(reduivy__Application_Status__c) = "Submitted", NOT(ISBLANK(reduivy__Contact__c)))', 'Study Requirement Set General', SRS_Helper.REQUIREMENT_GENERATION_MODE_AUTO));
        studyRequirementSets.put('SRS_Local', REDU_TestData_UTIL.newStudyRequirementSet('SRS_Local', 'Study Requirement Set Local', 'SRS_Local', IPA_Helper.getApiName(), 'reduivy__Contact__c', 'AND(TEXT(reduivy__Application_Status__c) = "Submitted", NOT(ISBLANK(reduivy__Contact__c)))', 'Study Requirement Set Local', SRS_Helper.REQUIREMENT_GENERATION_MODE_AUTO));

        studyRequirementSets.put('SRS_Achievement_Evidence', REDU_TestData_UTIL.newStudyRequirementSet('SRS_Achievement_Evidence', 'Upload Evidence', 'SRS_Achievement_Evidence', IAC_Helper.getApiName(), 'reduivy__Contact__c', 'AND(NOT(ISBLANK(reduivy__Contact__c)), TEXT(reduivy__Type__c) = "Academic")', 'Upload Evidence', SRS_Helper.REQUIREMENT_GENERATION_MODE_AUTO));
        studyRequirementSets.put('SRS_Achievement_Unit_Syllabi', REDU_TestData_UTIL.newStudyRequirementSet('SRS_Achievement_Unit_Syllabi', 'Upload Syllabi', 'SRS_Achievement_Unit_Syllabi', IAU_Helper.getApiName(), 'reduivy__Individual_Achievement__r.reduivy__Contact__c', 'AND(NOT(ISBLANK(reduivy__Individual_Achievement__c)), TEXT(reduivy__Individual_Achievement__r.reduivy__Type__c) = "Academic")', 'Upload Syllabi', SRS_Helper.REQUIREMENT_GENERATION_MODE_AUTO));

        if(IPA_Helper.canRunEvaluationTest()) {
            //Study Requirement Set for Application Scoring
            studyRequirementSets.put('SRS_Application', REDU_TestData_UTIL.newStudyRequirementSet('SRS_Application', 'Application Scoring', 'SRS_Application', IPA_Helper.getApiName(), 'reduivy__Contact__c', 'AND(TEXT(reduivy__Application_Status__c) = "Submitted", NOT(ISBLANK(reduivy__Contact__c)))', 'Study Requirement Set Application', SRS_Helper.REQUIREMENT_GENERATION_MODE_MANUAL));
        }
        REDU_SystemMode_UTIL.doInsert(studyRequirementSets.values());
        
        if (validateCheckpoint(SRS_Helper.getApiName(), skipAfterObject)) {
            unmuteTriggers();
            unmuteRollup();
            return; 
        }

        //Study Requirement
        studyRequirements.put('SRS_General_UploadTranscript', REDU_TestData_UTIL.newFileUploadStudyRequirement('SRS_General_UploadTranscript', 'Upload Transcript', 'SRS_General_UploadTranscript', 1, studyRequirementSets.get('SRS_General').Id, 'Upload transcript', IRQ_Helper.REQUIREMENT_VISIBILITY_STUDENT, 7, 'Transcript', 1, SRQ_Helper.LINK_TO_INDIVIDUAL_ACHIEVEMENT_YES));
        studyRequirements.put('SRS_General_ValidateTranscript', REDU_TestData_UTIL.newActionStudyRequirement('SRS_General_ValidateTranscript', 'Admin Validate Transcript', 'SRS_General_ValidateTranscript', 2, studyRequirementSets.get('SRS_General').Id, 'Admin Validate Transcript', IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN, 14));
        
        studyRequirements.put('SRS_Local_UploadID', REDU_TestData_UTIL.newFileUploadStudyRequirement('SRS_Local_UploadID', 'Upload ID', 'SRS_Local_UploadID', 1, studyRequirementSets.get('SRS_Local').Id, 'Upload ID', IRQ_Helper.REQUIREMENT_VISIBILITY_STUDENT, 7, 'Transcript', 1, SRQ_Helper.LINK_TO_INDIVIDUAL_ACHIEVEMENT_YES));
        studyRequirements.put('SRS_Local_ValidateID', REDU_TestData_UTIL.newActionStudyRequirement('SRS_Local_ValidateID', 'Admin Validate ID', 'SRS_Local_ValidateID', 2, studyRequirementSets.get('SRS_Local').Id, 'Admin Validate ID', IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN, 14));
        
        studyRequirements.put('SRS_Achievement_Evidence_UploadEvidence', REDU_TestData_UTIL.newFileUploadStudyRequirement('SRS_Achievement_Evidence_UploadEvidence', 'Upload Evidence', 'SRS_Achievement_Evidence_UploadEvidence', 1, studyRequirementSets.get('SRS_Achievement_Evidence').Id, 'Upload Evidence', IRQ_Helper.REQUIREMENT_VISIBILITY_STUDENT, 7, 'Transcript', 1, SRQ_Helper.LINK_TO_INDIVIDUAL_ACHIEVEMENT_YES));
        studyRequirements.put('SRS_Achievement_Evidence_ValidateEvidence', REDU_TestData_UTIL.newActionStudyRequirement('SRS_Achievement_Evidence_ValidateEvidence', 'Admin Validate Evidence', 'SRS_Achievement_Evidence_ValidateEvidence', 2, studyRequirementSets.get('SRS_Achievement_Evidence').Id, 'Admin Validate Evidence', IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN, 14));

        studyRequirements.put('SRS_Achievement_Unit_Syllabi_UploadSyllabi', REDU_TestData_UTIL.newFileUploadStudyRequirement('SRS_Achievement_Unit_Syllabi_UploadSyllabi', 'Upload Syllabi', 'SRS_Achievement_Unit_Syllabi_UploadSyllabi', 1, studyRequirementSets.get('SRS_Achievement_Unit_Syllabi').Id, 'Upload Syllabi', IRQ_Helper.REQUIREMENT_VISIBILITY_STUDENT, 7, 'Transcript', 1, SRQ_Helper.LINK_TO_INDIVIDUAL_ACHIEVEMENT_NO));
        studyRequirements.put('SRS_Achievement_Unit_Syllabi_ValidateSyllabi', REDU_TestData_UTIL.newActionStudyRequirement('SRS_Achievement_Unit_Syllabi_ValidateSyllabi', 'Admin Validate Syllabi', 'SRS_Achievement_Unit_Syllabi_ValidateSyllabi', 2, studyRequirementSets.get('SRS_Achievement_Unit_Syllabi').Id, 'Admin Validate Syllabi', IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN, 14));
        
        if(IPA_Helper.canRunEvaluationTest()) {
            //Study Requirement for Application
            studyRequirements.put('SRS_Application_CGPA', REDU_TestData_UTIL.newFieldUpdateStudyRequirement('SRS_Application_CGPA', 'CGPA', 'SRS_Application_CGPA', 1, studyRequirementSets.get('SRS_Application').Id, 'CGPA', IRQ_Helper.REQUIREMENT_VISIBILITY_STUDENT, 7, 'reduivy__Test_Previous_CGPA__c', 'reduivy__Individual_Program_Application__c'));
            studyRequirements.put('SRS_Application_Official university master\'s degree', REDU_TestData_UTIL.newFileUploadStudyRequirement('SRS_Application_Official university master\'s degree', 'Official university master\'s degree', 'SRS_Application_Official university master\'s degree', 2, studyRequirementSets.get('SRS_Application').Id, 'SRS_Application_Official university master\'s degree', IRQ_Helper.REQUIREMENT_VISIBILITY_STUDENT, 7, 'Transcript', 1, SRQ_Helper.LINK_TO_INDIVIDUAL_ACHIEVEMENT_NO));
            studyRequirements.put('SRS_Application_Validate Official university master\'s degree', REDU_TestData_UTIL.newFieldUpdateStudyRequirement('SRS_Application_Validate Official university master\'s degree', 'Validate Official university master\'s degree', 'SRS_Application_Validate Official university master\'s degree', 3, studyRequirementSets.get('SRS_Application').Id, 'Validate SRS_Application_Validate Official university master\'s degree', IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN, 7, 'reduivy__Test_Official_university_master_s_degree__c', 'reduivy__Individual_Program_Application__c'));

            studyRequirements.put('SRS_Application_Other continuing education master\'s degree (from 60 to 120 ECTS)', REDU_TestData_UTIL.newFileUploadStudyRequirement('SRS_Application_Other continuing education master\'s degree (from 60 to 120 ECTS)', 'Other continuing education master\'s degree (from 60 to 120 ECTS)', 'SRS_Application_Other continuing education master\'s degree (from 60 to 120 ECTS)', 4, studyRequirementSets.get('SRS_Application').Id, 'Other continuing education master\'s degree (from 60 to 120 ECTS)', IRQ_Helper.REQUIREMENT_VISIBILITY_STUDENT, 7, 'Transcript', 1, SRQ_Helper.LINK_TO_INDIVIDUAL_ACHIEVEMENT_NO));
            studyRequirements.put('SRS_Application_Validate Other continuing education master\'s degree (from 60 to 120 ECTS)', REDU_TestData_UTIL.newFieldUpdateStudyRequirement('SRS_Application_Validate Other continuing education master\'s degree (from 60 to 120 ECTS)', 'Validate Other continuing education master\'s degree (from 60 to 120 ECTS)', 'SRS_Application_Validate Other continuing education master\'s degree (from 60 to 120 ECTS)', 5, studyRequirementSets.get('SRS_Application').Id, 'Validate Other continuing education master\'s degree (from 60 to 120 ECTS)', IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN, 7, 'reduivy__Test_Official_university_master_s_degree__c', 'reduivy__Individual_Program_Application__c'));

            studyRequirements.put('SRS_Application_Doctoral degree (PhD)', REDU_TestData_UTIL.newFileUploadStudyRequirement('SRS_Application_Doctoral degree (PhD)', 'Doctoral degree (PhD)', 'Doctoral degree (PhD)', 6, studyRequirementSets.get('SRS_Application').Id, 'SRS_Application_Doctoral degree (PhD)', IRQ_Helper.REQUIREMENT_VISIBILITY_STUDENT, 7, 'Transcript', 1, SRQ_Helper.LINK_TO_INDIVIDUAL_ACHIEVEMENT_NO));
            studyRequirements.put('SRS_Application_Validate Doctoral degree (PhD)', REDU_TestData_UTIL.newFieldUpdateStudyRequirement('SRS_Application_Validate Doctoral degree (PhD)', 'Validate Doctoral degree (PhD)', 'Validate Doctoral degree (PhD)', 7, studyRequirementSets.get('SRS_Application').Id, 'SRS_Application_Validate Doctoral degree (PhD)', IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN, 7, 'reduivy__Test_Official_university_master_s_degree__c', 'reduivy__Individual_Program_Application__c'));

            studyRequirements.put('SRS_Application_Diploma of Advanced Studies (Spanish DEA) / 32 ECTS in research', REDU_TestData_UTIL.newFileUploadStudyRequirement('SRS_Application_Diploma of Advanced Studies (Spanish DEA) / 32 ECTS in research', 'Diploma of Advanced Studies (Spanish DEA) / 32 ECTS in research', 'SRS_Application_Diploma of Advanced Studies (Spanish DEA) / 32 ECTS in research', 8, studyRequirementSets.get('SRS_Application').Id, 'Diploma of Advanced Studies (Spanish DEA) / 32 ECTS in research', IRQ_Helper.REQUIREMENT_VISIBILITY_STUDENT, 7, 'Transcript', 1, SRQ_Helper.LINK_TO_INDIVIDUAL_ACHIEVEMENT_NO));
            studyRequirements.put('SRS_Application_Validate Diploma of Advanced Studies (Spanish DEA) / 32 ECTS in research', REDU_TestData_UTIL.newFieldUpdateStudyRequirement('SRS_Application_Validate Diploma of Advanced Studies (Spanish DEA) / 32 ECTS in research', 'Validate Diploma of Advanced Studies (Spanish DEA) / 32 ECTS in research', 'Validate SRS_Application_Diploma of Advanced Studies (Spanish DEA) / 32 ECTS in research', 9, studyRequirementSets.get('SRS_Application').Id, 'Validate Diploma of Advanced Studies (Spanish DEA) / 32 ECTS in research', IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN, 7, 'reduivy__Test_Official_university_master_s_degree__c', 'reduivy__Individual_Program_Application__c'));

            studyRequirements.put('SRS_Application_Teaching period', REDU_TestData_UTIL.newFieldUpdateStudyRequirement('SRS_Application_Teaching period', 'Teaching period', 'SRS_Application_Teaching period', 10, studyRequirementSets.get('SRS_Application').Id, 'Teaching period', IRQ_Helper.REQUIREMENT_VISIBILITY_STUDENT, 7, 'reduivy__Test_Teaching_Period__c', 'reduivy__Individual_Program_Application__c'));
            studyRequirements.put('SRS_Application_English Proficiency', REDU_TestData_UTIL.newFieldUpdateStudyRequirement('SRS_Application_English Proficiency', 'English Proficiency', 'SRS_Application_English Proficiency', 11, studyRequirementSets.get('SRS_Application').Id, 'English Proficiency', IRQ_Helper.REQUIREMENT_VISIBILITY_STUDENT, 7, 'reduivy__Test_English_Proficiency__c', 'reduivy__Individual_Program_Application__c'));
        }

        REDU_SystemMode_UTIL.doInsert(studyRequirements.values());

        if (validateCheckpoint(SRQ_Helper.getApiName(), skipAfterObject)) {
            unmuteTriggers();
            unmuteRollup();
            return; 
        }

        
        if(IPA_Helper.canRunEvaluationTest()) {
            //Study Scoring Config
            studyScoringConfigs.put('SCF_Application', REDU_TestData_UTIL.newStudyScoringConfig('SCF_Application', 'Application Score', 'Application Score', IPA_Helper.getApiName(), 'reduivy__Contact__c', 'AND(TEXT(reduivy__Application_Status__c) = "Reviewing", NOT(ISBLANK(reduivy__Contact__c)))'));
            
            REDU_SystemMode_UTIL.doInsert(studyScoringConfigs.values());

            if (validateCheckpoint(SCF_Helper.getApiName(), skipAfterObject)) {
                unmuteTriggers();
                unmuteRollup();
                return; 
            }

            //Study Scoring Criteria
            /**                                                                             Max
                CGPA                                                                        60
                Additional Academic Background                                              30
                    Official university master's degree                                     -10
                    Other continuing education master\'s degree (from 60 to 120 ECTS)       -5
                    Doctoral studies related to clinical and health psychology              -15
                        Doctoral degree (PhD)                                               --10
                        Diploma of Advanced Studies (Spanish DEA) / 32 ECTS in research     --5
                        Teaching period                                                     --2
                English Proficiency                                                         10
            */

            List<String> scrNameList = new List<String>{
                'CGPA', 
                'Additional Academic Background', 
                'Official university master\'s degree',
                'Other continuing education master\'s degree (from 60 to 120 ECTS)',
                'Doctoral studies related to clinical and health psychology',
                'Doctoral degree (PhD)',
                'Diploma of Advanced Studies (Spanish DEA) / 32 ECTS in research',
                'Teaching period',
                'English Proficiency'
            };
            
            Map<String, Decimal> scrNameToMaxScore = new Map<String, Decimal>{
                'CGPA' => 60,
                'Additional Academic Background' => 30,
                'Official university master\'s degree' => 10,
                'Other continuing education master\'s degree (from 60 to 120 ECTS)' => 5,
                'Doctoral studies related to clinical and health psychology' => 15,
                'Doctoral degree (PhD)' => 9,
                'Diploma of Advanced Studies (Spanish DEA) / 32 ECTS in research' => 3,
                'Teaching period' => 3,
                'English Proficiency' => 10
            };

            Map<String, Decimal> scrNameToWeight = new Map<String, Decimal>{
                'CGPA' => 60,
                'Additional Academic Background' => 30,
                'Official university master\'s degree' => 33.33,
                'Other continuing education master\'s degree (from 60 to 120 ECTS)' => 16.67,
                'Doctoral studies related to clinical and health psychology' => 50,
                'Doctoral degree (PhD)' => 60,
                'Diploma of Advanced Studies (Spanish DEA) / 32 ECTS in research' => 20,
                'Teaching period' => 20,
                'English Proficiency' => 10
            };

            Map<String, String> scrNameToScoreLogic = new Map<String, String>{
                'CGPA' => 'reduivy__Test_Previous_CGPA__c * 10',
                'Additional Academic Background' => null,
                'Official university master\'s degree' => 'IF(reduivy__Test_Official_university_master_s_degree__c, 100, 0)',
                'Other continuing education master\'s degree (from 60 to 120 ECTS)' => 'IF(reduivy__Test_continuing_education_master_degree__c, 100, 0)',
                'Doctoral studies related to clinical and health psychology' => null,
                'Doctoral degree (PhD)' => 'IF(reduivy__Test_Doctoral_degree_PhD__c, 100, 0)',
                'Diploma of Advanced Studies (Spanish DEA) / 32 ECTS in research' => 'IF(reduivy__Test_Diploma_of_Advanced_Studies__c, 100, 0)',
                'Teaching period' => 'IF(reduivy__Test_Teaching_Period__c, 100, 0)',
                'English Proficiency' => 'CASE(TEXT(reduivy__Test_English_Proficiency__c), "B1", 40, "B2", 80, "C1", 90, "C2", 100, 0)'
            };
            
            Map<String, String> childScrToParentScrNameMap = new Map<String, String>{
                'Official university master\'s degree' => 'Additional Academic Background',
                'Other continuing education master\'s degree (from 60 to 120 ECTS)' => 'Additional Academic Background',
                'Doctoral studies related to clinical and health psychology' => 'Additional Academic Background',
                'Doctoral degree (PhD)' => 'Doctoral studies related to clinical and health psychology',
                'Diploma of Advanced Studies (Spanish DEA) / 32 ECTS in research' => 'Doctoral studies related to clinical and health psychology',
                'Teaching period' => 'Doctoral studies related to clinical and health psychology'
            };

            for(String scrName : scrNameList) {
                Id srqId = studyRequirements.containsKey('SRS_Application_' + scrName) ? studyRequirements.get('SRS_Application_' + scrName).Id : null;
                String scoreLogic = scrNameToScoreLogic.get(scrName);
                Decimal weight = scrNameToWeight.get(scrName);
                Decimal maxScore = scrNameToMaxScore.get(scrName);
                studyScoringCriteria.put('SCR_' + scrName, REDU_TestData_UTIL.newStudyScoringCriteria('SCR_' + scrName, scrName, scrName, studyScoringConfigs.get('SCF_Application').Id, srqId, null, scrNameList.indexOf(scrName) + 1, scoreLogic, weight, maxScore));
            }

            REDU_SystemMode_UTIL.doInsert(studyScoringCriteria.values());

            for(reduivy__Study_Scoring_Criteria__c scr : studyScoringCriteria.values()) {
                if(childScrToParentScrNameMap.containsKey(scr.Name)) {
                    scr.reduivy__Parent_Criteria__c = studyScoringCriteria.get('SCR_' + childScrToParentScrNameMap.get(scr.Name)).Id;
                }
            }
            
            REDU_SystemMode_UTIL.doUpdate(studyScoringCriteria.values());
        
            if (validateCheckpoint(SCR_Helper.getApiName(), skipAfterObject)) {
                unmuteTriggers();
                unmuteRollup();
                return; 
            }
        }
        
        unmuteTriggers();
    }

    /**
     * @description Default method to initiate offering data
     * @param skipAfterObject Object to skip
     */
    global void initOfferingData(String skipAfterObject) {
        muteTriggers();

        if (eduInst == null) {
            for (Account acc : [SELECT Id, Name, reduivy__Code__c, RecordTypeId, reduivy__Sample_Record_Code__c 
                FROM Account 
                WHERE reduivy__Sample_Record_Code__c != null
                AND RecordTypeId = : ACC_Helper.getEducationalInstitutionRecordTypeId()
                WITH SYSTEM_MODE
                LIMIT 1
            ]) {
                eduInst = acc;
            }
        }

        if (studyPrograms.isEmpty()) {
            for (reduivy__Study_Program__c sProg : [SELECT Id, reduivy__Educational_Institution__c, Name, reduivy__Academic_Level__c, reduivy__Program_Code__c, reduivy__Sample_Record_Code__c
                FROM reduivy__Study_Program__c
                WHERE reduivy__Sample_Record_Code__c != null
                WITH SYSTEM_MODE
            ]) {
                studyPrograms.put(sProg.reduivy__Sample_Record_Code__c, sProg);
            }
        }

        if (studyUnits.isEmpty()) {
            for (reduivy__Study_Unit__c sUnit : [SELECT Id, reduivy__Educational_Institution__c, Name, reduivy__Unit_Code__c, reduivy__Credits__c, reduivy__Default_EFTSL__c, reduivy__Field_of_Study__c, reduivy__Unit_Level__c, reduivy__Requirement_Logic__c, reduivy__Sample_Record_Code__c
                FROM reduivy__Study_Unit__c
                WHERE reduivy__Sample_Record_Code__c != null
                WITH SYSTEM_MODE
            ]) {
                studyUnits.put(sUnit.reduivy__Sample_Record_Code__c, sUnit);
            }
        }

		if(campuses.isEmpty()){
            for (Account campus : [SELECT Id, Name, reduivy__Sample_Record_Code__c, ParentId 
                FROM Account
                WHERE reduivy__Sample_Record_Code__c != null AND RecordTypeId =: ACC_Helper.getCampusRecordTypeId()
                WITH SYSTEM_MODE
            ]) {
                campuses.put(campus.reduivy__Sample_Record_Code__c, campus);
            }
        }
        
        if(studyPlans.isEmpty()){
			for(reduivy__Study_Plan__c studyPlan : [SELECT Id, Name, reduivy__Study_Program__c, reduivy__Sample_Record_Code__c
				FROM reduivy__Study_Plan__c
				WHERE reduivy__Sample_Record_Code__c != null
                WITH SYSTEM_MODE
			]){
				studyPlans.put(studyPlan.reduivy__Sample_Record_Code__c, studyPlan);
			}
		}

        if(studyPathways.isEmpty()){
			for(reduivy__Study_Pathway__c studyPathway : [SELECT Id, Name, reduivy__Study_Plan__c, reduivy__Default__c, reduivy__Sample_Record_Code__c
				FROM reduivy__Study_Pathway__c
				WHERE reduivy__Sample_Record_Code__c != null
                WITH SYSTEM_MODE
			]){
				studyPathways.put(studyPathway.reduivy__Sample_Record_Code__c, studyPathway);
			}
		}

        if(subfacilities.isEmpty()){
            for(reduivy__Facility__c subfacility : [SELECT Id, Name, reduivy__Campus__c, reduivy__Parent_Facility__c, reduivy__Capacity__c, reduivy__Facility_Type__c, reduivy__Active__c, reduivy__Sample_Record_Code__c
				FROM reduivy__Facility__c
				WHERE reduivy__Sample_Record_Code__c != null
                AND reduivy__Parent_Facility__c != null
                WITH SYSTEM_MODE
			]){
				subfacilities.put(subfacility.reduivy__Sample_Record_Code__c, subfacility);
			}
        }

        if (eduInst == null) {
            throw new REDU_ApplicationException('Not able to find educational institution. Please execute initMasterData() to generate master data.');
        }

        //academic year
        academicYears.put('PY', REDU_TestData_UTIL.newAcademicYearStudyTerm('PY', eduInst.Id, 'Year ' + lastYearTerm1StartDate.year(), 'Academic Year ' + lastYearTerm1StartDate.year(), STM_Helper.TYPE_SCHOOLYEAR, lastYearTerm1StartDate, lastYearTerm2EndDate));
        academicYears.put('CY', REDU_TestData_UTIL.newAcademicYearStudyTerm('CY', eduInst.Id, 'Year ' + currentYearTerm1StartDate.year(), 'Academic Year ' + currentYearTerm1StartDate.year(), STM_Helper.TYPE_SCHOOLYEAR, currentYearTerm1StartDate, currentYearTerm2EndDate));
        academicYears.put('NY', REDU_TestData_UTIL.newAcademicYearStudyTerm('NY', eduInst.Id, 'Year ' + nextYearTerm1StartDate.year(), 'Academic Year ' + nextYearTerm1StartDate.year(), STM_Helper.TYPE_SCHOOLYEAR, nextYearTerm1StartDate, nextYearTerm2EndDate));

        REDU_SystemMode_UTIL.doInsert(academicYears.values());

        //academic terms
        academicTerms.put('PYT1', REDU_TestData_UTIL.newAcademicTermStudyTerm('PYT1', academicYears.get('PY').Id, 'T1 ' + lastYearTerm1StartDate.year(), 'Academic Term 1 ' + lastYearTerm1StartDate.year(), STM_Helper.TYPE_SEMESTER, lastYearTerm1StartDate, lastYearTerm1EndDate, lastYearTerm1StartDate.addDays(14), Datetime.newInstance(lastYearTerm1StartDate.addDays(-21), Time.newInstance(0, 0, 0, 0)) , Datetime.newInstance(lastYearTerm1StartDate.addDays(-14), Time.newInstance(0, 0, 0, 0)), Datetime.newInstance(lastYearTerm1StartDate, Time.newInstance(0, 0, 0, 0)), false));
        academicTerms.put('PYT2', REDU_TestData_UTIL.newAcademicTermStudyTerm('PYT2', academicYears.get('PY').Id, 'T2 ' + lastYearTerm1StartDate.year(), 'Academic Term 2 ' + lastYearTerm2StartDate.year(), STM_Helper.TYPE_SEMESTER, lastYearTerm2StartDate, lastYearTerm2EndDate, lastYearTerm2StartDate.addDays(14), Datetime.newInstance(lastYearTerm2StartDate.addDays(-21), Time.newInstance(0, 0, 0, 0)) , Datetime.newInstance(lastYearTerm2StartDate.addDays(-14), Time.newInstance(0, 0, 0, 0)), Datetime.newInstance(lastYearTerm2StartDate, Time.newInstance(0, 0, 0, 0)), false));
        
        academicTerms.put('CYT1', REDU_TestData_UTIL.newAcademicTermStudyTerm('CYT1', academicYears.get('CY').Id, 'T1 ' + currentYearTerm1StartDate.year(), 'Academic Term 1 ' + currentYearTerm1StartDate.year(), STM_Helper.TYPE_SEMESTER, currentYearTerm1StartDate, currentYearTerm1EndDate, currentYearTerm1StartDate.addDays(14), Datetime.newInstance(currentYearTerm1StartDate.addDays(-21), Time.newInstance(0, 0, 0, 0)) , Datetime.newInstance(currentYearTerm1StartDate.addDays(-14), Time.newInstance(0, 0, 0, 0)), Datetime.newInstance(currentYearTerm1StartDate, Time.newInstance(0, 0, 0, 0)), false));
        academicTerms.put('CYT2', REDU_TestData_UTIL.newAcademicTermStudyTerm('CYT2', academicYears.get('CY').Id, 'T2 ' + currentYearTerm1StartDate.year(), 'Academic Term 2 ' + currentYearTerm2StartDate.year(), STM_Helper.TYPE_SEMESTER, currentYearTerm2StartDate, currentYearTerm2EndDate, currentYearTerm2StartDate.addDays(14), Datetime.newInstance(currentYearTerm2StartDate.addDays(-21), Time.newInstance(0, 0, 0, 0)) , Datetime.newInstance(currentYearTerm2StartDate.addDays(-14), Time.newInstance(0, 0, 0, 0)), Datetime.newInstance(currentYearTerm2StartDate, Time.newInstance(0, 0, 0, 0)), false));
        
        academicTerms.put('NYT1', REDU_TestData_UTIL.newAcademicTermStudyTerm('NYT1', academicYears.get('NY').Id, 'T1 ' + nextYearTerm1StartDate.year(), 'Academic Term 1 ' + nextYearTerm1StartDate.year(), STM_Helper.TYPE_SEMESTER, nextYearTerm1StartDate, nextYearTerm1EndDate, nextYearTerm1StartDate.addDays(14), Datetime.newInstance(nextYearTerm1StartDate.addDays(-21), Time.newInstance(0, 0, 0, 0)) , Datetime.newInstance(nextYearTerm1StartDate.addDays(-14), Time.newInstance(0, 0, 0, 0)), Datetime.newInstance(nextYearTerm1StartDate, Time.newInstance(0, 0, 0, 0)), false));
        academicTerms.put('NYT2', REDU_TestData_UTIL.newAcademicTermStudyTerm('NYT2', academicYears.get('NY').Id, 'T2 ' + nextYearTerm1StartDate.year(), 'Academic Term 2 ' + nextYearTerm2StartDate.year(), STM_Helper.TYPE_SEMESTER, nextYearTerm2StartDate, nextYearTerm2EndDate, nextYearTerm2StartDate.addDays(14), Datetime.newInstance(nextYearTerm2StartDate.addDays(-21), Time.newInstance(0, 0, 0, 0)) , Datetime.newInstance(nextYearTerm2StartDate.addDays(-14), Time.newInstance(0, 0, 0, 0)), Datetime.newInstance(nextYearTerm2StartDate, Time.newInstance(0, 0, 0, 0)), false));
        
        REDU_SystemMode_UTIL.doInsert(academicTerms.values());

        if (validateCheckpoint(STM_Helper.getApiName(), skipAfterObject)) {
            unmuteTriggers();
            unmuteRollup();
            return;
        }

        //study cohort enrollments
        studyCohortEnrollments.put('CYT1_CustomCohort', REDU_TestData_UTIL.newStudyCohortEnrollment('CYT1_CustomCohort', academicTerms.get('CYT1').Id, 'CYT1_CustomCohort', 'Cohort 1', 'Freshman', String.valueOf(currentYearTerm1StartDate.year()), currentYearTerm1StartDate, currentYearTerm1StartDate, currentYearTerm1EndDate));

        REDU_SystemMode_UTIL.doInsert(studyCohortEnrollments.values());

        if (validateCheckpoint(SCE_Helper.getApiName(), skipAfterObject)) {
            unmuteTriggers();
            unmuteRollup();
            return;
        }

        if (studyUnits.isEmpty() || campuses.isEmpty()) {
            throw new REDU_ApplicationException('Not able to find study programs, study units, campuses, and study plan. Please execute initMasterData() to generate master data.');
        }

        //study offering
        for (String stKey : termSunList.keySet()) {
            reduivy__Study_Term__c st = academicTerms.get(stKey);

            for (String campusKey : campuses.keySet()) {
                Account campus = campuses.get(campusKey);

                for (String suKey : termSunList.get(stKey)) {
                    reduivy__Study_Unit__c su = studyUnits.get(suKey);

                    String soffKey = suKey + '_' + stKey + '_' + campusKey;
                    studyOfferings.put(soffKey, REDU_TestData_UTIL.newStudyOffering(soffKey, su.Id, st.Id, campus.Id, soffKey, 20, null, null));
                }
            }
        }

        REDU_SystemMode_UTIL.doInsert(studyOfferings.values());

        if (validateCheckpoint(SOF_Helper.getApiName(), skipAfterObject)) {
            unmuteTriggers();
            unmuteRollup();
            return;
        }

        if (!studyPrograms.isEmpty() && !studyPlans.isEmpty()) {

            //study intakes
            studyIntakes.put('SYDNEY_BACBIS_PYINTAKE', REDU_TestData_UTIL.newStudyIntake('SYDNEY_BACBIS_PYINTAKE', campuses.get('SYDNEY').Id, studyPrograms.get('BACBIS').Id, studyPlans.get('BACBIS_MajorA').Id, studyPathways.get('BACBIS_MajorA_DEFAULT')?.Id, academicTerms.get('PYT1').Id, 'SYDNEY_BACBIS_PYINTAKE', lastYearTerm1StartDate.addDays(-50), lastYearTerm1StartDate.addDays(-20), SIT_Helper.STATUS_ACTIVE));
            studyIntakes.put('SYDNEY_BACBIS_CYINTAKE', REDU_TestData_UTIL.newStudyIntake('SYDNEY_BACBIS_CYINTAKE', campuses.get('SYDNEY').Id, studyPrograms.get('BACBIS').Id, studyPlans.get('BACBIS_MajorA').Id, studyPathways.get('BACBIS_MajorA_DEFAULT')?.Id, academicTerms.get('CYT1').Id, 'SYDNEY_BACBIS_CYINTAKE', currentYearTerm1StartDate.addDays(-50), currentYearTerm1StartDate.addDays(-20), SIT_Helper.STATUS_ACTIVE));
            studyIntakes.put('SYDNEY_BACBIS_NYINTAKE', REDU_TestData_UTIL.newStudyIntake('SYDNEY_BACBIS_NYINTAKE', campuses.get('SYDNEY').Id, studyPrograms.get('BACBIS').Id, studyPlans.get('BACBIS_MajorA').Id, studyPathways.get('BACBIS_MajorA_DEFAULT')?.Id, academicTerms.get('NYT1').Id, 'SYDNEY_BACBIS_NYINTAKE', nextYearTerm1StartDate.addDays(-50), nextYearTerm1StartDate.addDays(-20), SIT_Helper.STATUS_ACTIVE));
            
            studyIntakes.put('SYDNEY_BACCOM_CYINTAKE', REDU_TestData_UTIL.newStudyIntake('SYDNEY_BACCOM_CYINTAKE', campuses.get('SYDNEY').Id, studyPrograms.get('BACCOM').Id, studyPlans.get('BACBIS_MinorA').Id, studyPathways.get('BACBIS_MinorA_DEFAULT')?.Id, academicTerms.get('CYT1').Id, 'SYDNEY_BACCOM_CYINTAKE', currentYearTerm1StartDate.addDays(-50), currentYearTerm1StartDate.addDays(-20), SIT_Helper.STATUS_ACTIVE));
            studyIntakes.put('SYDNEY_BACCOM_NYINTAKE', REDU_TestData_UTIL.newStudyIntake('SYDNEY_BACCOM_NYINTAKE', campuses.get('SYDNEY').Id, studyPrograms.get('BACCOM').Id, studyPlans.get('BACBIS_MinorA').Id, studyPathways.get('BACBIS_MinorA_DEFAULT')?.Id, academicTerms.get('NYT1').Id, 'SYDNEY_BACCOM_NYINTAKE', nextYearTerm1StartDate.addDays(-50), nextYearTerm1StartDate.addDays(-20), SIT_Helper.STATUS_ACTIVE));
            
            if (FULLDATA) {
                studyIntakes.put('BRISBANE_BACBIS_CYINTAKE', REDU_TestData_UTIL.newStudyIntake('BRISBANE_BACBIS_CYINTAKE', campuses.get('BRISBANE').Id, studyPrograms.get('BACBIS').Id, studyPlans.get('BACBIS_MajorA').Id, studyPathways.get('BACBIS_MajorA_DEFAULT')?.Id, academicTerms.get('CYT1').Id, 'BRISBANE_BACBIS_CYINTAKE', currentYearTerm1StartDate.addDays(-50), currentYearTerm1StartDate.addDays(-20), SIT_Helper.STATUS_ACTIVE));
                studyIntakes.put('BRISBANE_BACBIS_NYINTAKE', REDU_TestData_UTIL.newStudyIntake('BRISBANE_BACBIS_NYINTAKE', campuses.get('BRISBANE').Id, studyPrograms.get('BACBIS').Id, studyPlans.get('BACBIS_MajorA').Id, studyPathways.get('BACBIS_MajorA_DEFAULT')?.Id, academicTerms.get('NYT1').Id, 'BRISBANE_BACBIS_NYINTAKE',  nextYearTerm1StartDate.addDays(-50), nextYearTerm1StartDate.addDays(-20), SIT_Helper.STATUS_ACTIVE));

                studyIntakes.put('BRISBANE_BACCOM_CYINTAKE', REDU_TestData_UTIL.newStudyIntake('BRISBANE_BACCOM_CYINTAKE', campuses.get('BRISBANE').Id, studyPrograms.get('BACCOM').Id, studyPlans.get('BACBIS_MinorA').Id, studyPathways.get('BACBIS_MinorA_DEFAULT')?.Id, academicTerms.get('CYT1').Id, 'BRISBANE_BACCOM_CYINTAKE', currentYearTerm1StartDate.addDays(-50), currentYearTerm1StartDate.addDays(-20), SIT_Helper.STATUS_ACTIVE));
                studyIntakes.put('BRISBANE_BACCOM_NYINTAKE', REDU_TestData_UTIL.newStudyIntake('BRISBANE_BACCOM_NYINTAKE', campuses.get('BRISBANE').Id, studyPrograms.get('BACCOM').Id, studyPlans.get('BACBIS_MinorA').Id, studyPathways.get('BACBIS_MinorA_DEFAULT')?.Id, academicTerms.get('NYT1').Id, 'BRISBANE_BACCOM_NYINTAKE', nextYearTerm1StartDate.addDays(-50), nextYearTerm1StartDate.addDays(-20), SIT_Helper.STATUS_ACTIVE));
            }

            REDU_SystemMode_UTIL.doInsert(studyIntakes.values());
        }

        if (validateCheckpoint(SIT_Helper.getApiName(), skipAfterObject)) {
            unmuteTriggers();
            unmuteRollup();
            return;
        }

        if(REDU_AppSetting_UTIL.isUsingStudyIntakeGroup()) {

            Map<String, Integer> sigType = new Map<String, Integer> {'Standard' => 85, 'Disabled' => 15};
            
            for(reduivy__Study_Intake__c sit : studyIntakes.values()) {
                for(String type : sigType.keySet()) {
                    Integer capacity = sigType.get(type);
                    String sigKey = sit.reduivy__Sample_Record_Code__c + '_' + type;
                    studyIntakeGroups.put(sigKey, REDU_TestData_UTIL.newStudyIntakeGroup(sigKey, sigKey, type, sit.Id, capacity, type == 'Standard'));
                }
            }
            
            REDU_SystemMode_UTIL.doInsert(studyIntakeGroups.values());
        }

        if (validateCheckpoint(SIG_Helper.getApiName(), skipAfterObject)) {
            unmuteTriggers();
            unmuteRollup();
            return;
        }

        unmuteTriggers();

        //study grade period setting for current terms
        reduivy__Study_Term__c CYTerm1 = academicTerms.get('CYT1');
        reduivy__Study_Term__c CYTerm2 = academicTerms.get('CYT2');

        //study grade period setting for past terms
        reduivy__Study_Term__c PYTerm1 = academicTerms.get('PYT1');
        reduivy__Study_Term__c PYTerm2 = academicTerms.get('PYT2');
        
        studyGradePeriodSettings.put('MidTermGrade_' + CYTerm1.reduivy__Sample_Record_Code__c, REDU_TestData_UTIL.newStudyGradePeriodSetting('MidTermGrade_' + CYTerm1.reduivy__Sample_Record_Code__c, CYTerm1.Id, 'Mid Term Grade - CYT1', CYTerm1.reduivy__Start_Date__c, CYTerm1.reduivy__End_Date__c, 'Mid-term Grade', 50));
        studyGradePeriodSettings.put('MidTermGrade_' + CYTerm2.reduivy__Sample_Record_Code__c, REDU_TestData_UTIL.newStudyGradePeriodSetting('MidTermGrade_' + CYTerm2.reduivy__Sample_Record_Code__c, CYTerm2.Id, 'Mid Term Grade - CYT2', CYTerm2.reduivy__Start_Date__c, CYTerm2.reduivy__End_Date__c, 'Mid-term Grade', 50));
        studyGradePeriodSettings.put('MidTermGrade_' + PYTerm1.reduivy__Sample_Record_Code__c, REDU_TestData_UTIL.newStudyGradePeriodSetting('MidTermGrade_' + PYTerm1.reduivy__Sample_Record_Code__c, PYTerm1.Id, 'Mid Term Grade - PYT1', PYTerm1.reduivy__Start_Date__c, PYTerm1.reduivy__End_Date__c, 'Mid-term Grade', 50));
        studyGradePeriodSettings.put('MidTermGrade_' + PYTerm2.reduivy__Sample_Record_Code__c, REDU_TestData_UTIL.newStudyGradePeriodSetting('MidTermGrade_' + PYTerm2.reduivy__Sample_Record_Code__c, PYTerm2.Id, 'Mid Term Grade - PYT2', PYTerm2.reduivy__Start_Date__c, PYTerm2.reduivy__End_Date__c, 'Mid-term Grade', 50));

        studyGradePeriodSettings.put('FinalTermGrade_' + CYTerm1.reduivy__Sample_Record_Code__c, REDU_TestData_UTIL.newStudyGradePeriodSetting('FinalGrade_' + CYTerm1.reduivy__Sample_Record_Code__c, CYTerm1.Id, 'Final Term Grade - CYT1', CYTerm1.reduivy__Start_Date__c, CYTerm1.reduivy__End_Date__c, 'Final Grade', 50));
        studyGradePeriodSettings.put('FinalTermGrade_' + CYTerm2.reduivy__Sample_Record_Code__c, REDU_TestData_UTIL.newStudyGradePeriodSetting('FinalGrade_' + CYTerm2.reduivy__Sample_Record_Code__c, CYTerm2.Id, 'Final Term Grade - CYT2', CYTerm2.reduivy__Start_Date__c, CYTerm2.reduivy__End_Date__c, 'Final Grade', 50));
        studyGradePeriodSettings.put('FinalTermGrade_' + PYTerm1.reduivy__Sample_Record_Code__c, REDU_TestData_UTIL.newStudyGradePeriodSetting('FinalGrade_' + PYTerm1.reduivy__Sample_Record_Code__c, PYTerm1.Id, 'Final Term Grade - PYT1', PYTerm1.reduivy__Start_Date__c, PYTerm1.reduivy__End_Date__c, 'Final Grade', 50));
        studyGradePeriodSettings.put('FinalTermGrade_' + PYTerm2.reduivy__Sample_Record_Code__c, REDU_TestData_UTIL.newStudyGradePeriodSetting('FinalGrade_' + PYTerm2.reduivy__Sample_Record_Code__c, PYTerm2.Id, 'Final Term Grade - PYT2', PYTerm2.reduivy__Start_Date__c, PYTerm2.reduivy__End_Date__c, 'Final Grade', 50));

        REDU_SystemMode_UTIL.doInsert(studyGradePeriodSettings.values());

        if (validateCheckpoint(SGP_Helper.getApiName(), skipAfterObject)) {
            unmuteTriggers();
            unmuteRollup();
            return;
        }

        //get current academic term (campus = SYDNEY, today is between term's start & end)
        reduivy__Study_Term__c currentAcaTerm;
        for (String atKey : academicTerms.keySet()) {
            if(atKey == CYTKey){
                currentAcaTerm = academicTerms.get(CYTKey);
            }
        }

        //For each study offering, create 4 Study Sessions = Lecture, Tutorial, Workshop, Exam
        Integer idx = 0;

        for(String suName: termSunList.get('CYT1')){
            reduivy__Study_Offering__c so = studyOfferings.get(suName + '_' + CYTKey + '_SYDNEY');
            studySessions.put('Lecture_' + so.reduivy__Sample_Record_Code__c, REDU_TestData_UTIL.newStudySession('Lecture_' + so.reduivy__Sample_Record_Code__c, so.Id, (facultiesSequenceList.isEmpty() ? null : facultiesSequenceList[idx].Id), suName + ' Lecture - ' + CYTKey, 100, 0, 90, 'Lecture', so.reduivy__Start_Date__c, so.reduivy__End_Date__c));
            
            if (FULLDATA) {
                studySessions.put('Tutorial_' + so.reduivy__Sample_Record_Code__c, REDU_TestData_UTIL.newStudySession('Tutorial_' + so.reduivy__Sample_Record_Code__c, so.Id, (facultiesSequenceList.isEmpty() ? null : facultiesSequenceList[idx].Id), suName + ' Tutorial - ' + CYTKey, 100, 0, 90, 'Tutorial', so.reduivy__Start_Date__c, so.reduivy__End_Date__c));
                studySessions.put('Workshop_' + so.reduivy__Sample_Record_Code__c, REDU_TestData_UTIL.newStudySession('Workshop_' + so.reduivy__Sample_Record_Code__c, so.Id, (facultiesSequenceList.isEmpty() ? null : facultiesSequenceList[idx].Id), suName + ' Workshop - ' + CYTKey, 100, 0, 90, 'Workshop', so.reduivy__Start_Date__c, so.reduivy__End_Date__c));
                studySessions.put('Exam_' + so.reduivy__Sample_Record_Code__c, REDU_TestData_UTIL.newStudySession('Exam_' + so.reduivy__Sample_Record_Code__c, so.Id, (facultiesSequenceList.isEmpty() ? null : facultiesSequenceList[idx].Id), suName + ' Exam - ' + CYTKey, 100, 0, 90, 'Exam', so.reduivy__Start_Date__c, so.reduivy__End_Date__c));
            }
            
            idx++;
        }
        
        REDU_SystemMode_UTIL.doInsert(studySessions.values());

        if (validateCheckpoint(SSE_Helper.getApiName(), skipAfterObject)) {
            unmuteTriggers();
            unmuteRollup();
            return;
        }

        //Study Session Time
        //Lecture = 1 session time on weekly monday 9am - 11am
        //Tutorial = 2 session time on weekly tuesday 10am - 11am and wednesday 3pm - 4pm
        //Workshop = 1 session time on bi-weekly friday 12pm - 3pm
        //Exam  = 1 session time on last day of the semester (one off) 9am - 11am
        if(currentAcaTerm != null){
            //find SYDNEY subfacilities
            List<Id> subfacilityIds = new List<Id>();

            if (!campuses.isEmpty()) {
                for(reduivy__Facility__c f : subfacilities.values()){
                    if(f.reduivy__Campus__c == campuses.get('SYDNEY').Id){
                        subfacilityIds.add(f.Id);
                    }
                }
            }

            Integer lec = 0, tut = 0, wok = 0, exm = 0;
            for(reduivy__Study_Session__c ss: studySessions.values()){
                Id suId;
                for(reduivy__Study_Offering__c so : studyOfferings.values()){
                    if(so.Id == ss.reduivy__Study_Offering__c){
                        suId = so.reduivy__Study_Unit__c;
                    }
                }

                String suName;
                for(reduivy__Study_Unit__c su : studyUnits.values()){
                    if(su.Id == suId){
                        suName = su.Name;
                    }
                }

                if(suName != null){
                    if(ss.reduivy__Type__c == 'Lecture'){
                        studySessionTimes.put('Mon(9-11)_' + ss.reduivy__Sample_Record_Code__c, REDU_TestData_UTIL.newStudySessionTime('Mon(9-11)_' + ss.reduivy__Sample_Record_Code__c, ss.Id, (subfacilityIds.isEmpty() ? null : subfacilityIds[lec]), suName + ' Lecture - Monday', null, 'Monday', 'Weekly', currentAcaTerm.reduivy__Start_Date__c, currentAcaTerm.reduivy__End_Date__c, Time.newInstance(9, 0, 0, 0), Time.newInstance(11, 0, 0, 0)));
                        lec = lec >= subfacilityIds.size()-1 ? 0 : ++lec;
                    }else if(ss.reduivy__Type__c == 'Tutorial'){
                        studySessionTimes.put('Tue(10-11)_' + ss.reduivy__Sample_Record_Code__c, REDU_TestData_UTIL.newStudySessionTime('Tue(10-11)_' + ss.reduivy__Sample_Record_Code__c, ss.Id, (subfacilityIds.isEmpty() ? null : subfacilityIds[tut]), suName + ' Tutorial - Tuesday', null, 'Tuesday', 'Weekly', currentAcaTerm.reduivy__Start_Date__c, currentAcaTerm.reduivy__End_Date__c, Time.newInstance(10, 0, 0, 0), Time.newInstance(11, 0, 0, 0)));
                        studySessionTimes.put('Wed(15-16)_' + ss.reduivy__Sample_Record_Code__c, REDU_TestData_UTIL.newStudySessionTime('Wed(15-16)_' + ss.reduivy__Sample_Record_Code__c, ss.Id, (subfacilityIds.isEmpty() ? null : subfacilityIds[tut]), suName + ' Tutorial - Wednesday', null, 'Wednesday', 'Weekly', currentAcaTerm.reduivy__Start_Date__c, currentAcaTerm.reduivy__End_Date__c, Time.newInstance(15, 0, 0, 0), Time.newInstance(16, 0, 0, 0)));
                        tut = tut >= subfacilityIds.size()-1 ? 0 : ++tut;
                    }else if(ss.reduivy__Type__c == 'Workshop'){
                        studySessionTimes.put('Fri_biWeek(12-15)_' + ss.reduivy__Sample_Record_Code__c, REDU_TestData_UTIL.newStudySessionTime('Fri_biWeek(12-15)_' + ss.reduivy__Sample_Record_Code__c, ss.Id, (subfacilityIds.isEmpty() ? null : subfacilityIds[wok]), suName + ' Workshop - Friday', null, 'Friday', 'Bi-Weekly', currentAcaTerm.reduivy__Start_Date__c, currentAcaTerm.reduivy__End_Date__c, Time.newInstance(12, 0, 0, 0), Time.newInstance(15, 0, 0, 0)));
                        wok = wok >= subfacilityIds.size()-1 ? 0 : ++wok;
                    }else if(ss.reduivy__Type__c == 'Exam'){
                        studySessionTimes.put('One-off(9-11)_' + ss.reduivy__Sample_Record_Code__c, REDU_TestData_UTIL.newStudySessionTime('One-off(9-11)_' + ss.reduivy__Sample_Record_Code__c, ss.Id, (subfacilityIds.isEmpty() ? null : subfacilityIds[exm]), suName + ' Exam', null, null, 'One-off', currentAcaTerm.reduivy__End_Date__c, currentAcaTerm.reduivy__End_Date__c, Time.newInstance(9, 0, 0, 0), Time.newInstance(11, 0, 0, 0)));
                        exm = exm >= subfacilityIds.size()-1 ? 0 : ++exm;
                    }
                }
            }
            REDU_SystemMode_UTIL.doInsert(studySessionTimes.values());

            if (validateCheckpoint(SST_Helper.getApiName(), skipAfterObject)) {
                unmuteTriggers();
                unmuteRollup();
                return;
            }
        }

        //Create the study event for each session time between the start date and end date based on the recurrence: weekly + 7, bi + 14
        Map<String, Integer> dayOfWeek = new Map<String, Integer>{'Monday' => 0, 'Tuesday' => 1, 'Wednesday' => 2, 'Thursday' => 3, 'Friday' => 4, 'Saturday' => 5, 'Sunday' => 6};

        for(reduivy__Study_Session_Time__c sst: studySessionTimes.values()){
            
            if(sst.reduivy__Recurrence__c == 'Weekly' || sst.reduivy__Recurrence__c == 'Bi-Weekly'){
                Integer daysToAdd = dayOfWeek.get(sst.reduivy__Day_of_Week__c);

                //assign 14 for 'Bi-Weekly' and 7 for 'Weekly'
                Integer recurrenceDays = sst.reduivy__Recurrence__c == 'Weekly' ? 7 : sst.reduivy__Recurrence__c == 'Bi-Weekly' ? 14 : -1;
                
                for(Date currentDate = sst.reduivy__Start_Date__c.addDays(daysToAdd); currentDate <= sst.reduivy__End_Date__c; currentDate = currentDate.addDays(recurrenceDays)){
                    Datetime startDt = Datetime.newInstance(currentDate, sst.reduivy__Start_Time__c);
                    Datetime endDt = Datetime.newInstance(currentDate, sst.reduivy__End_Time__c);
                    studyEvents.put(currentDate.format() + '_' + sst.reduivy__Sample_Record_Code__c, 
                    REDU_TestData_UTIL.newSessionStudyEvent(currentDate.format() + '_' + sst.reduivy__Sample_Record_Code__c, sst.Id, sst.Name + ' (' + startDt.format() + ')', null, 'Confirmed', startDt, endDt));
                }
            }else if(sst.reduivy__Recurrence__c == 'One-off'){
                Datetime startDt = Datetime.newInstance(sst.reduivy__Start_Date__c, sst.reduivy__Start_Time__c);
                Datetime endDt = Datetime.newInstance(sst.reduivy__End_Date__c, sst.reduivy__End_Time__c);
                studyEvents.put(sst.reduivy__Start_Date__c.format() + '_' + sst.reduivy__Sample_Record_Code__c, 
                REDU_TestData_UTIL.newSessionStudyEvent(sst.reduivy__Start_Date__c.format() + '_' + sst.reduivy__Sample_Record_Code__c, sst.Id, sst.Name + ' (' + startDt.format() + ')', null, 'Confirmed', startDt, endDt));
            }
        }

        Set<String> sevTriggers = new Set<String>{
            'SEV_CreateFacilityEventRelations_EXE'
        };
        REDU_TriggerController.muteTriggers(sevTriggers);
        REDU_SystemMode_UTIL.doInsert(studyEvents.values());
        REDU_TriggerController.unmuteTriggers(sevTriggers);

        if (validateCheckpoint(SEV_Helper.getApiName(), skipAfterObject)) {
            unmuteTriggers();
            unmuteRollup();
            return;
        }
        
        //create the study event relation for facilities
        Map<Id, reduivy__Study_Session_Time__c> sstIdMap = new Map<Id, reduivy__Study_Session_Time__c>(studySessionTimes.values());
        Map<Id, reduivy__Facility__c> subFacilitiesIdMap = new Map<Id, reduivy__Facility__c>(subfacilities.values());

        for(reduivy__Study_Event__c se : studyEvents.values()){
            reduivy__Study_Session_Time__c sst = sstIdMap.get(se.reduivy__Study_Session_Time__c);
            reduivy__Facility__c subfacility = subFacilitiesIdMap.get(sst.reduivy__Default_Facility__c);

            String facilitySrc = subfacility.reduivy__Sample_Record_Code__c;
            facilityStudyEventRelations.put(facilitySrc + '_' + se.reduivy__Sample_Record_Code__c, REDU_TestData_UTIL.newFacilityStudyEventRelation(facilitySrc + '_' + se.reduivy__Sample_Record_Code__c, subfacility.Id, se.Id));
        }

        REDU_SystemMode_UTIL.doInsert(facilityStudyEventRelations.values());

        if (validateCheckpoint(FACILITY_SER, skipAfterObject)) {
            unmuteTriggers();
            unmuteRollup();
            return;
        }
        
        //create map to get all study offering Id and its primary faculty having study session
        if(!faculties.isEmpty()){
            Map<Id, Id> soIdfacultyId = new Map<Id, Id>();
            for(reduivy__Study_Session__c ss : studySessions.values()){
                soIdfacultyId.put(ss.reduivy__Study_Offering__c, ss.reduivy__Primary_Faculty__c);
            }
    
            //create individual enrollment to assign the faculty to the study offering that has study session
            Map<Id, Contact> facultyIdMap = new Map<Id, Contact>(faculties.values());
            for(reduivy__Study_Offering__c so : studyOfferings.values()){
                if(soIdfacultyId.containsKey(so.Id)){
                    
                    Contact faculty = facultyIdMap.get(soIdfacultyId.get(so.Id));
                    String sampleRecord = faculty.reduivy__Sample_Record_Code__c + '_' + so.reduivy__Sample_Record_Code__c;
    
                    if(faculty != null){
                        facultyIndividualEnrollments.put(sampleRecord, REDU_TestData_UTIL.newFacultyIndividualEnrollment(sampleRecord, faculty.Id, so.Id, IEN_Helper.getInProgressStatuses()[0]));
                    }
                    
                }
            }

            REDU_SystemMode_UTIL.doInsert(facultyIndividualEnrollments.values());
            if (validateCheckpoint(IEN_Helper.getApiName(), skipAfterObject)) {
                unmuteTriggers();
                unmuteRollup();
                return;
            }
    
            Map<Id, reduivy__Individual_Enrollment__c> facIdIdvEnroll = new Map<Id, reduivy__Individual_Enrollment__c>();
            for(reduivy__Individual_Enrollment__c ie : facultyIndividualEnrollments.values()){
                facIdIdvEnroll.put(ie.reduivy__Contact__c, ie);
            }
    
            //create individual session enrollment for faculty
            for(reduivy__Study_Session__c ss : studySessions.values()){
    
                if(facIdIdvEnroll.containsKey(ss.reduivy__Primary_Faculty__c)){
                    reduivy__Individual_Enrollment__c ie = facIdIdvEnroll.get(ss.reduivy__Primary_Faculty__c);
                    String role = (ss.reduivy__Type__c == 'Lecture') ? 'Lecturer' :
                        (ss.reduivy__Type__c == 'Tutorial') ? 'Tutor' :
                        (ss.reduivy__Type__c == 'Workshop') ? 'Assistant' :
                        (ss.reduivy__Type__c == 'Exam') ? 'Assistant' : null;
                    
                    if(role != null){
                        String sampleRecord = role + '_' + ie.reduivy__Sample_Record_Code__c;
                        facultyIndividualSessionEnrollments.put(sampleRecord, REDU_TestData_UTIL.newFacultyIndividualSessionEnrollment(sampleRecord, ss.Id, ie.Id, role, ss.reduivy__Start_Date__c, ISN_Helper.getInProgressStatuses().get(0)));
                    }
                }
    
            }
            
            REDU_SystemMode_UTIL.doInsert(facultyIndividualSessionEnrollments.values());
     
            if (validateCheckpoint(ISN_Helper.getApiName(), skipAfterObject)) {
                unmuteTriggers();
                unmuteRollup();
                return;
            }
    
            //Map studySessionId + IndividualSessionEnrollment (Map 1) --- match studySessionId
            Map<Id, reduivy__Individual_Session_Enrollment__c> ssIdWithIse = new Map<Id, reduivy__Individual_Session_Enrollment__c>();
            for(reduivy__Individual_Session_Enrollment__c ise : facultyIndividualSessionEnrollments.values()){
                if(ise.RecordTypeId == ISN_Helper.getFacultyRecordTypeId()){
                    ssIdWithIse.put(ise.reduivy__Study_Session__c, ise);
                }
            }
    
    
            //Map studySessionTimeId + studySessionId -> Map studySessionId + StudyEvent (Map 2)
            Map<Id, Id> sstIdWithSsId = new Map<Id, Id>();
            for(reduivy__Study_Session_Time__c sst : studySessionTimes.values()){
                sstIdWithSsId.put(sst.Id, sst.reduivy__Study_Session__c);
            }
            Map<Id, List<reduivy__Study_Event__c>> ssIdWithSe = new Map<Id, List<reduivy__Study_Event__c>>();
            for(reduivy__Study_Event__c se : studyEvents.values()){
                Id ssId = sstIdWithSsId.get(se.reduivy__Study_Session_Time__c);
                if(ssId != null){
                    if(!ssIdWithSe.containsKey(ssId)){
                        ssIdWithSe.put(ssId, new List<reduivy__Study_Event__c>());
                    }
                    ssIdWithSe.get(ssId).add(se);
                }
            }
    
            //match studySessionId Map 1 and Map 2 (for create study event relations)
            Map<Id, reduivy__Individual_Enrollment__c> iensMapById = new Map<Id, reduivy__Individual_Enrollment__c>(facultyIndividualEnrollments.values());

            for(Id ssId : ssIdWithIse.keySet()){
                if(ssIdWithSe.containsKey(ssId)){
                    List<reduivy__Study_Event__c> seList = ssIdWithSe.get(ssId);
                    reduivy__Individual_Session_Enrollment__c ise = ssIdWithIse.get(ssId);
                    for(reduivy__Study_Event__c se : seList){
                        String sampleRecord = ise.reduivy__Sample_Record_Code__c + '_' + se.reduivy__Sample_Record_Code__c;
                        facultyStudyEventRelations.put(sampleRecord, REDU_TestData_UTIL.newFacultyStudyEventRelation(sampleRecord, iensMapById.get(ise.reduivy__Individual_Enrollment__c).reduivy__Contact__c, se.Id, ise.Id));
                    }
                }
            }
            
            REDU_SystemMode_UTIL.doInsert(facultyStudyEventRelations.values());
    
            if (validateCheckpoint(FACULTY_SER, skipAfterObject)) {
                unmuteTriggers();
                unmuteRollup();
                return;
            }
        }
    
    }

    /**
     * @description Default method to initiate faculty account and contact data
     * @param skipAfterObject Object to skip
     * @param enableFacultyUser Enable community user for faculty contact
     */
    global void initFacultyData(String skipAfterObject, Boolean enableFacultyUser){
        muteTriggers();

        Id facultyProfileId = REDU_AppSetting_UTIL.getFacultyProfileId();
        List<Id> facultyPermissionSetIds = REDU_AppSetting_UTIL.getFacultyPermissionSetIds();

        //faculty administrative account
        facultyAdminstratives.put('albedoford@redu.example', REDU_TestData_UTIL.newAdministrativeAccount('albedoford@redu.example', 'albedoford@redu.example'));
        facultyAdminstratives.put('dilucford@redu.example', REDU_TestData_UTIL.newAdministrativeAccount('dilucford@redu.example', 'dilucford@redu.example'));
        facultyAdminstratives.put('ventiford@redu.example', REDU_TestData_UTIL.newAdministrativeAccount('ventiford@redu.example', 'ventiford@redu.example'));
        facultyAdminstratives.put('jeanford@redu.example', REDU_TestData_UTIL.newAdministrativeAccount('jeanford@redu.example', 'jeanford@redu.example'));
        facultyAdminstratives.put('kleeford@redu.example', REDU_TestData_UTIL.newAdministrativeAccount('kleeford@redu.example', 'kleeford@redu.example'));
        facultyAdminstratives.put('lisaford@redu.example', REDU_TestData_UTIL.newAdministrativeAccount('lisaford@redu.example', 'lisaford@redu.example'));
        facultyAdminstratives.put('amberford@redu.example', REDU_TestData_UTIL.newAdministrativeAccount('amberford@redu.example', 'amberford@redu.example'));
        facultyAdminstratives.put('eulaford@redu.example', REDU_TestData_UTIL.newAdministrativeAccount('eulaford@redu.example', 'eulaford@redu.example'));

        REDU_SystemMode_UTIL.doInsert(facultyAdminstratives.values());

        //faculty contact
        facultiesSequenceList.add(REDU_TestData_UTIL.newFacultyContact('albedoford@redu.example', facultyAdminstratives.get('albedoford@redu.example').Id, 'Albedo', 'Ford', 'albedoford@redu.example'));
        facultiesSequenceList.add(REDU_TestData_UTIL.newFacultyContact('dilucford@redu.example', facultyAdminstratives.get('dilucford@redu.example').Id, 'Diluc', 'Ford', 'dilucford@redu.example'));
        facultiesSequenceList.add(REDU_TestData_UTIL.newFacultyContact('ventiford@redu.example', facultyAdminstratives.get('ventiford@redu.example').Id, 'Venti', 'Ford', 'ventiford@redu.example'));
        facultiesSequenceList.add(REDU_TestData_UTIL.newFacultyContact('jeanford@redu.example', facultyAdminstratives.get('jeanford@redu.example').Id, 'Jean', 'Ford', 'jeanford@redu.example'));
        facultiesSequenceList.add(REDU_TestData_UTIL.newFacultyContact('kleeford@redu.example', facultyAdminstratives.get('kleeford@redu.example').Id, 'Klee', 'Ford', 'kleeford@redu.example'));
        facultiesSequenceList.add(REDU_TestData_UTIL.newFacultyContact('lisaford@redu.example', facultyAdminstratives.get('lisaford@redu.example').Id, 'Lisa', 'Ford', 'lisaford@redu.example'));
        facultiesSequenceList.add(REDU_TestData_UTIL.newFacultyContact('amberford@redu.example', facultyAdminstratives.get('amberford@redu.example').Id, 'Amber', 'Ford', 'amberford@redu.example'));
        facultiesSequenceList.add(REDU_TestData_UTIL.newFacultyContact('eulaford@redu.example', facultyAdminstratives.get('eulaford@redu.example').Id, 'Eula', 'Ford', 'eulaford@redu.example'));

        for (Contact faculty : facultiesSequenceList) {
            faculties.put(faculty.reduivy__Sample_Record_Code__c, faculty);
        }

        // faculties.put('albedoford@redu.example', REDU_TestData_UTIL.newFacultyContact('albedoford@redu.example', facultyAdminstratives.get('albedoford@redu.example').Id, 'Albedo', 'Ford', 'albedoford@redu.example'));
        // faculties.put('dilucford@redu.example', REDU_TestData_UTIL.newFacultyContact('dilucford@redu.example', facultyAdminstratives.get('dilucford@redu.example').Id, 'Diluc', 'Ford', 'dilucford@redu.example'));
        // faculties.put('ventiford@redu.example', REDU_TestData_UTIL.newFacultyContact('ventiford@redu.example', facultyAdminstratives.get('ventiford@redu.example').Id, 'Venti', 'Ford', 'ventiford@redu.example'));
        // faculties.put('jeanford@redu.example', REDU_TestData_UTIL.newFacultyContact('jeanford@redu.example', facultyAdminstratives.get('jeanford@redu.example').Id, 'Jean', 'Ford', 'jeanford@redu.example'));
        // faculties.put('kleeford@redu.example', REDU_TestData_UTIL.newFacultyContact('kleeford@redu.example', facultyAdminstratives.get('kleeford@redu.example').Id, 'Klee', 'Ford', 'kleeford@redu.example'));
        // faculties.put('lisaford@redu.example', REDU_TestData_UTIL.newFacultyContact('lisaford@redu.example', facultyAdminstratives.get('lisaford@redu.example').Id, 'Lisa', 'Ford', 'lisaford@redu.example'));
        // faculties.put('amberford@redu.example', REDU_TestData_UTIL.newFacultyContact('amberford@redu.example', facultyAdminstratives.get('amberford@redu.example').Id, 'Amber', 'Ford', 'amberford@redu.example'));
        // faculties.put('eulaford@redu.example', REDU_TestData_UTIL.newFacultyContact('eulaford@redu.example', facultyAdminstratives.get('eulaford@redu.example').Id, 'Eula', 'Ford', 'eulaford@redu.example'));

        REDU_SystemMode_UTIL.doInsert(facultiesSequenceList);

        if (validateCheckpoint(CON_Helper.getApiName(), skipAfterObject)) {
            unmuteTriggers();
            unmuteRollup();
            return;
        }

        //provision the faculty contact as digital experience user
        if (enableFacultyUser) {
            //create user
            for (Contact faculty : faculties.values()) {
                facultyUsers.put(faculty.Email, REDU_TestData_UTIL.newUser(faculty.FirstName, faculty.LastName, null, facultyProfileId, faculty.Email));
            }

            REDU_SystemMode_UTIL.doInsert(facultyUsers.values());

            List<Id> userIds = new List<Id>();
            for (User facultyUsr : facultyUsers.values()) {
                userIds.add(facultyUsr.Id);

                faculties.get(facultyUsr.Email).reduivy__User__c = facultyUsr.Id;
            }

            REDU_SystemMode_UTIL.doUpdate(faculties.values());

            //assign permission set
            if (Test.isRunningTest()) {
                User runningUser = getSetupUser();

                System.runAs(runningUser) {
                    assignPermissionSet(userIds, facultyPermissionSetIds);
                }
            } else {
                assignPermissionSetFuture(userIds, facultyPermissionSetIds);
            }
        }

        if (validateCheckpoint(USR_Helper.getApiName(), skipAfterObject)) {
            unmuteTriggers();
            unmuteRollup();
            return;
        }

        //Qualified Faculty (Each faculty will have an equal number of Qualified Faculty objects created, depending on the number of study units)
        Integer numOfStudyUnits = studyUnits.size();
        Integer currentStudyUnits = 0;
        List<reduivy__Study_Unit__c> listOfStudyUnits = studyUnits.values();

        if(!faculties.isEmpty()) {
            for(Contact facultyContacts : faculties.values()) {
                for (Integer numOfQualifiedStudyUnit = 0; numOfQualifiedStudyUnit < numOfStudyUnits/faculties.size(); numOfQualifiedStudyUnit++) {
    
                    if (currentStudyUnits < numOfStudyUnits) {
    
                        qualifiedFaculty.put(listOfStudyUnits[currentStudyUnits].Name + facultyContacts.LastName, REDU_TestData_UTIL.newQualifiedFaculty(listOfStudyUnits[currentStudyUnits].Name + facultyContacts.LastName, facultyContacts.Id, 'Active', listOfStudyUnits[currentStudyUnits].Id));
    
                        currentStudyUnits++;
                    } else {
                        break; 
                    }
                }
            }
    
            REDU_SystemMode_UTIL.doInsert(qualifiedFaculty.values());

            if (validateCheckpoint(QFA_Helper.getApiName(), skipAfterObject)) {
                unmuteTriggers();
                unmuteRollup();
                return;
            }
        }

        //Contact Availability
        contactAvailability.put('CAV_Albedo_SYDNEY', REDU_TestData_UTIL.newContactAvailability('Albedo_SYDNEY', faculties.get('albedoford@redu.example').Id, campuses.get('SYDNEY').Id, Date.newInstance(2023, 01, 01), Date.newInstance(2026, 12, 31), CAV_Helper.STATUS_ACTIVE, Time.newInstance(08, 0, 0, 0), Time.newInstance(16, 0, 0, 0), Time.newInstance(08, 0, 0, 0), Time.newInstance(16, 0, 0, 0), Time.newInstance(08, 0, 0, 0), Time.newInstance(16, 0, 0, 0), Time.newInstance(08, 0, 0, 0), Time.newInstance(16, 0, 0, 0), Time.newInstance(08, 0, 0, 0), Time.newInstance(16, 0, 0, 0), null, null, null, null));
        contactAvailability.put('CAV_Diluc_SYDNEY', REDU_TestData_UTIL.newContactAvailability('Diluc_SYDNEY', faculties.get('dilucford@redu.example').Id, campuses.get('SYDNEY').Id, Date.newInstance(2023, 01, 01), Date.newInstance(2026, 12, 31), CAV_Helper.STATUS_ACTIVE, Time.newInstance(08, 0, 0, 0), Time.newInstance(17, 0, 0, 0), Time.newInstance(08, 0, 0, 0), Time.newInstance(16, 0, 0, 0), Time.newInstance(09, 0, 0, 0), Time.newInstance(16, 0, 0, 0), Time.newInstance(08, 0, 0, 0), Time.newInstance(16, 0, 0, 0), Time.newInstance(08, 0, 0, 0), Time.newInstance(16, 0, 0, 0), null, null, null, null));
        contactAvailability.put('CAV_Venti_SYDNEY', REDU_TestData_UTIL.newContactAvailability('Venti_SYDNEY', faculties.get('ventiford@redu.example').Id, campuses.get('SYDNEY').Id, Date.newInstance(2023, 01, 01), Date.newInstance(2026, 12, 31), CAV_Helper.STATUS_ACTIVE, Time.newInstance(08, 0, 0, 0), Time.newInstance(14, 0, 0, 0), Time.newInstance(08, 0, 0, 0), Time.newInstance(16, 0, 0, 0), Time.newInstance(09, 0, 0, 0), Time.newInstance(16, 0, 0, 0), Time.newInstance(08, 0, 0, 0), Time.newInstance(16, 0, 0, 0), Time.newInstance(08, 0, 0, 0), Time.newInstance(16, 0, 0, 0), null, null, null, null));
        contactAvailability.put('CAV_Jean_SYDNEY', REDU_TestData_UTIL.newContactAvailability('Jean_SYDNEY', faculties.get('jeanford@redu.example').Id, campuses.get('SYDNEY').Id, Date.newInstance(2023, 01, 01), Date.newInstance(2026, 12, 31), CAV_Helper.STATUS_ACTIVE, Time.newInstance(08, 0, 0, 0), Time.newInstance(16, 0, 0, 0), Time.newInstance(08, 0, 0, 0), Time.newInstance(16, 0, 0, 0), Time.newInstance(08, 0, 0, 0), Time.newInstance(16, 0, 0, 0), Time.newInstance(09, 0, 0, 0), Time.newInstance(16, 0, 0, 0), Time.newInstance(08, 0, 0, 0), Time.newInstance(16, 0, 0, 0), null, null, null, null));
        
        if (FULLDATA) {
            contactAvailability.put('CAV_Klee_BRISBANE', REDU_TestData_UTIL.newContactAvailability('Klee_BRISBANE', faculties.get('kleeford@redu.example').Id, campuses.get('BRISBANE').Id, Date.newInstance(2023, 01, 01), Date.newInstance(2026, 12, 31), CAV_Helper.STATUS_ACTIVE, Time.newInstance(08, 0, 0, 0), Time.newInstance(16, 0, 0, 0), Time.newInstance(08, 0, 0, 0), Time.newInstance(16, 0, 0, 0), Time.newInstance(11, 0, 0, 0), Time.newInstance(16, 0, 0, 0), Time.newInstance(08, 0, 0, 0), Time.newInstance(16, 0, 0, 0), Time.newInstance(08, 0, 0, 0), Time.newInstance(13, 0, 0, 0), null, null, null, null));
            contactAvailability.put('CAV_Lisa_BRISBANE', REDU_TestData_UTIL.newContactAvailability('Lisa_BRISBANE', faculties.get('lisaford@redu.example').Id, campuses.get('BRISBANE').Id, Date.newInstance(2023, 01, 01), Date.newInstance(2026, 12, 31), CAV_Helper.STATUS_ACTIVE, Time.newInstance(08, 0, 0, 0), Time.newInstance(17, 0, 0, 0), Time.newInstance(08, 0, 0, 0), Time.newInstance(16, 0, 0, 0), Time.newInstance(07, 0, 0, 0), Time.newInstance(16, 0, 0, 0), Time.newInstance(09, 0, 0, 0), Time.newInstance(16, 0, 0, 0), Time.newInstance(08, 0, 0, 0), Time.newInstance(16, 0, 0, 0), null, null, null, null));
            contactAvailability.put('CAV_Amber_BRISBANE', REDU_TestData_UTIL.newContactAvailability('Amber_BRISBANE', faculties.get('amberford@redu.example').Id, campuses.get('BRISBANE').Id, Date.newInstance(2023, 01, 01), Date.newInstance(2026, 12, 31), CAV_Helper.STATUS_ACTIVE, Time.newInstance(08, 0, 0, 0), Time.newInstance(16, 0, 0, 0), Time.newInstance(08, 0, 0, 0), Time.newInstance(16, 0, 0, 0), Time.newInstance(08, 0, 0, 0), Time.newInstance(16, 0, 0, 0), Time.newInstance(08, 0, 0, 0), Time.newInstance(16, 0, 0, 0), Time.newInstance(08, 0, 0, 0), Time.newInstance(17, 0, 0, 0), null, null, null, null));
            contactAvailability.put('CAV_Eula_BRISBANE', REDU_TestData_UTIL.newContactAvailability('Eula_BRISBANE', faculties.get('eulaford@redu.example').Id, campuses.get('BRISBANE').Id, Date.newInstance(2023, 01, 01), Date.newInstance(2026, 12, 31), CAV_Helper.STATUS_ACTIVE, Time.newInstance(08, 0, 0, 0), Time.newInstance(17, 0, 0, 0), Time.newInstance(08, 0, 0, 0), Time.newInstance(16, 0, 0, 0), Time.newInstance(08, 0, 0, 0), Time.newInstance(16, 0, 0, 0), Time.newInstance(08, 0, 0, 0), Time.newInstance(16, 0, 0, 0), Time.newInstance(08, 0, 0, 0), Time.newInstance(16, 0, 0, 0), null, null, null, null));
        }

        REDU_SystemMode_UTIL.doInsert(contactAvailability.values());
    
        if (validateCheckpoint(CAV_Helper.getApiName(), skipAfterObject)) {
            unmuteTriggers();
            unmuteRollup();
            return;
        }

        //Contact Association
        if(!faculties.isEmpty()) {
            for(Contact facultyContacts : faculties.values()) {
                contactAssociation.put('CAS_' + facultyContacts.FirstName, REDU_TestData_UTIL.newContactAssociation('CAS_' + facultyContacts.FirstName, facultyContacts.Id, eduInst.Id, CAS_Helper.ROLE_FACULTY, CAS_Helper.STATUS_ACTIVE));
            }

            REDU_SystemMode_UTIL.doInsert(contactAssociation.values());

            if (validateCheckpoint(CAS_Helper.getApiName(), skipAfterObject)) {
                unmuteTriggers();
                unmuteRollup();
                return;
            }    
        }
    
        unmuteTriggers();
    }

    /**
     * @description Default method to initiate student account and contact data
     * @param skipAfterObject Object to skip
     * @param enableStudentUser Enable community user for student contact
     */
    global void initStudentData(String skipAfterObject, Boolean enableStudentUser) {

		if(campuses.isEmpty()){
            for (Account campus : [SELECT Id, Name, reduivy__Sample_Record_Code__c, ParentId 
                FROM Account
                WHERE reduivy__Sample_Record_Code__c != null AND RecordTypeId =: ACC_Helper.getCampusRecordTypeId()
                WITH SYSTEM_MODE
            ]) {
                campuses.put(campus.reduivy__Sample_Record_Code__c, campus);
            }
        }

        if(academicTerms.isEmpty()) {
            for (reduivy__Study_Term__c academicTerm : [SELECT Id, Name, reduivy__Start_Date__c, reduivy__End_Date__c, reduivy__Census_Date__c, reduivy__Fee_Due_Date__c, reduivy__Pre_enrollment_Open_Date__c, reduivy__Enrollment_Open_Date__c, reduivy__Enrollment_Close_Date__c, RecordTypeId, reduivy__Academic_Year__c, reduivy__Alternate_Name__c, reduivy__Type__c, reduivy__For_Internal_Only__c, reduivy__Sample_Record_Code__c 
                FROM reduivy__Study_Term__c
                WHERE reduivy__Sample_Record_Code__c != null AND RecordTypeId = : STM_Helper.getAcademicTermRecordTypeId()
                WITH SYSTEM_MODE
            ]) {
                academicTerms.put(academicTerm.reduivy__Sample_Record_Code__c, academicTerm);
            }
        }

        if (studyFundings.isEmpty()) {
            for (reduivy__Study_Funding__c studyFunding : [SELECT Id, Name, reduivy__Type__c, reduivy__Amount__c, reduivy__Sequence__c, reduivy__Status__c, reduivy__Sample_Record_Code__c
                FROM reduivy__Study_Funding__c
                WHERE reduivy__Sample_Record_Code__c != null
                WITH SYSTEM_MODE
            ]) {
                studyFundings.put(studyFunding.reduivy__Sample_Record_Code__c, studyFunding);
            }
        }
        
        if(studyPlans.isEmpty()){
			for(reduivy__Study_Plan__c studyPlan : [SELECT Id, Name, reduivy__Study_Program__c, reduivy__Sample_Record_Code__c
				FROM reduivy__Study_Plan__c
				WHERE reduivy__Sample_Record_Code__c != null
                WITH SYSTEM_MODE
			]){
				studyPlans.put(studyPlan.reduivy__Sample_Record_Code__c, studyPlan);
			}
		}

        if(studyIntakes.isEmpty()){
			for(reduivy__Study_Intake__c studyIntake : [SELECT Id, Name, reduivy__Academic_Term__c, reduivy__Default_Study_Pathway__c, reduivy__Sample_Record_Code__c
				FROM reduivy__Study_Intake__c
				WHERE reduivy__Sample_Record_Code__c != null
                WITH SYSTEM_MODE
			]){
				studyIntakes.put(studyIntake.reduivy__Sample_Record_Code__c, studyIntake);
			}
		}

        if(studyOfferings.isEmpty()){
			for(reduivy__Study_Offering__c studyOffering : [SELECT Id, Name, reduivy__Study_Unit__c, reduivy__Academic_Term__c, reduivy__Campus__c, reduivy__Capacity__c, reduivy__Start_Date__c, reduivy__End_Date__c, reduivy__Sample_Record_Code__c
				FROM reduivy__Study_Offering__c
				WHERE reduivy__Sample_Record_Code__c != null
                WITH SYSTEM_MODE
			]){
				studyOfferings.put(studyOffering.reduivy__Sample_Record_Code__c, studyOffering);
			}
		}

        if(studySessions.isEmpty()){
            for(reduivy__Study_Session__c studySession : [SELECT Id, Name, reduivy__Study_Offering__c, reduivy__Primary_Faculty__c, reduivy__Capacity__c, reduivy__Booked_Places__c, reduivy__Required_Attendance_Percentage__c, reduivy__Type__c, reduivy__Start_Date__c, reduivy__End_Date__c, reduivy__Sample_Record_Code__c
				FROM reduivy__Study_Session__c
				WHERE reduivy__Sample_Record_Code__c != null
                WITH SYSTEM_MODE
			]){
				studySessions.put(studySession.reduivy__Sample_Record_Code__c, studySession);
			}
        }

        if(studySessionTimes.isEmpty()){
            for(reduivy__Study_Session_Time__c studySessionTime : [SELECT Id, Name, reduivy__Study_Session__c, reduivy__Default_Facility__c, reduivy__Change_Date__c, reduivy__Day_of_Week__c, reduivy__Recurrence__c, reduivy__Start_Date__c, reduivy__End_Date__c, reduivy__Start_Time__c, reduivy__End_Time__c, reduivy__Sample_Record_Code__c
				FROM reduivy__Study_Session_Time__c
				WHERE reduivy__Sample_Record_Code__c != null
                WITH SYSTEM_MODE
			]){
				studySessionTimes.put(studySessionTime.reduivy__Sample_Record_Code__c, studySessionTime);
			}
        }

        if(studyEvents.isEmpty()){
            for(reduivy__Study_Event__c studyEvent : [SELECT Id, Name, reduivy__Study_Session_Time__c, reduivy__Type__c, reduivy__Location__c, reduivy__Status__c, reduivy__Start__c, reduivy__End__c, reduivy__Start_Date_Non_TZ__c, reduivy__Start_Time_Non_TZ__c, reduivy__End_Date_Non_TZ__c, reduivy__End_Time_Non_TZ__c, reduivy__Sample_Record_Code__c
				FROM reduivy__Study_Event__c
				WHERE reduivy__Sample_Record_Code__c != null
                WITH SYSTEM_MODE
			]){
				studyEvents.put(studyEvent.reduivy__Sample_Record_Code__c, studyEvent);
			}
        }

        if (agreementRecognitionUnits.isEmpty()) {
            for (reduivy__Agreement_Recognition_Unit__c aru : [SELECT Id, Name, reduivy__Sample_Record_Code__c
                FROM reduivy__Agreement_Recognition_Unit__c
                WHERE reduivy__Sample_Record_Code__c != null
                WITH SYSTEM_MODE
            ]) {
                agreementRecognitionUnits.put(aru.reduivy__Sample_Record_Code__c, aru);
            }
        }


        if (agreementUnitEquavalents.isEmpty()) {
            for (reduivy__Agreement_Unit_Equivalent__c aue : [SELECT Id, Name, reduivy__Sample_Record_Code__c, reduivy__Agreement__c, reduivy__Origin_Unit_Codes__c, reduivy__Target_Unit_Codes__c, reduivy__Status__c, reduivy__Type__c
                FROM reduivy__Agreement_Unit_Equivalent__c
                WHERE reduivy__Sample_Record_Code__c != null
                WITH SYSTEM_MODE
            ]) {
                agreementUnitEquavalents.put(aue.reduivy__Sample_Record_Code__c, aue);
            }
        }

        if (studyFeeMatrixItems.isEmpty()) {
            for (reduivy__Study_Fee_Matrix_Item__c smi : [SELECT Id, Name, reduivy__Sample_Record_Code__c, reduivy__Study_Fee_Matrix__c, reduivy__Study_Fee__c, reduivy__Type__c, reduivy__Amount__c, reduivy__Applicable_for_Attempt_Number__c, reduivy__Applicable_For_Study_Unit__c, reduivy__Applicable_For_Term__c
                FROM reduivy__Study_Fee_Matrix_Item__c
                WHERE reduivy__Sample_Record_Code__c != null
                WITH SYSTEM_MODE
            ]) {
                studyFeeMatrixItems.put(smi.reduivy__Sample_Record_Code__c, smi);
            }
        }

        if (studyVouchers.isEmpty()) {
            for (reduivy__Study_Voucher__c svc : [SELECT Id, Name, reduivy__Sample_Record_Code__c, reduivy__Code__c, reduivy__Voucher_Type__c, reduivy__Voucher_Value__c, reduivy__Account__c, reduivy__Status__c, reduivy__Valid_From__c, reduivy__Valid_Until__c, reduivy__Sequence__c, reduivy__Applicable_Item_Type__c, reduivy__Usage_Limit__c
                FROM reduivy__Study_Voucher__c
                WHERE reduivy__Sample_Record_Code__c != null
                WITH SYSTEM_MODE
            ]) {
                studyVouchers.put(svc.reduivy__Sample_Record_Code__c, svc);
            }
        }
        
        if (studyPrograms.isEmpty()) {
            for (reduivy__Study_Program__c spg : [SELECT Id, Name, reduivy__Sample_Record_Code__c, reduivy__Educational_Institution__c, reduivy__Academic_Level__c, reduivy__Program_Code__c
                FROM reduivy__Study_Program__c
                WHERE reduivy__Sample_Record_Code__c != null
                WITH SYSTEM_MODE
            ]) {
                studyPrograms.put(spg.reduivy__Sample_Record_Code__c, spg);
            }
        }

        muteTriggers();

        Id studentProfileId = REDU_AppSetting_UTIL.getStudentProfileId();
        List<Id> studentPermissionSetIds = REDU_AppSetting_UTIL.getStudentPermissionSetIds();

        //student administrative account
        studentAdminstratives.put('johndoe@redu.example', REDU_TestData_UTIL.newAdministrativeAccount('johndoe@redu.example', 'johndoe@redu.example'));
        studentAdminstratives.put('amydoe@redu.example', REDU_TestData_UTIL.newAdministrativeAccount('amydoe@redu.example', 'amydoe@redu.example'));
        studentAdminstratives.put('sandydoe@redu.example', REDU_TestData_UTIL.newAdministrativeAccount('sandydoe@redu.example', 'sandydoe@redu.example'));
        
        if (FULLDATA) {
            studentAdminstratives.put('tommydoe@redu.example', REDU_TestData_UTIL.newAdministrativeAccount('tommydoe@redu.example', 'tommydoe@redu.example'));
            studentAdminstratives.put('fionnadoe@redu.example', REDU_TestData_UTIL.newAdministrativeAccount('fionnadoe@redu.example', 'fionnadoe@redu.example'));
            studentAdminstratives.put('codydoe@redu.example', REDU_TestData_UTIL.newAdministrativeAccount('codydoe@redu.example', 'codydoe@redu.example'));
            studentAdminstratives.put('farisdoe@redu.example', REDU_TestData_UTIL.newAdministrativeAccount('farisdoe@redu.example', 'farisdoe@redu.example'));
            studentAdminstratives.put('pauladoe@redu.example', REDU_TestData_UTIL.newAdministrativeAccount('pauladoe@redu.example', 'pauladoe@redu.example'));
            studentAdminstratives.put('herbiedoe@redu.example', REDU_TestData_UTIL.newAdministrativeAccount('herbiedoe@redu.example', 'herbiedoe@redu.example'));
            studentAdminstratives.put('coraldoe@redu.example', REDU_TestData_UTIL.newAdministrativeAccount('coraldoe@redu.example', 'coraldoe@redu.example'));
            studentAdminstratives.put('lochlandoe@redu.example', REDU_TestData_UTIL.newAdministrativeAccount('lochlandoe@redu.example', 'lochlandoe@redu.example'));
            studentAdminstratives.put('katydoe@redu.example', REDU_TestData_UTIL.newAdministrativeAccount('katydoe@redu.example', 'katydoe@redu.example'));
            studentAdminstratives.put('jeffreydoe@redu.example', REDU_TestData_UTIL.newAdministrativeAccount('jeffreydoe@redu.example', 'jeffreydoe@redu.example'));
            studentAdminstratives.put('patrickdoe@redu.example', REDU_TestData_UTIL.newAdministrativeAccount('patrickdoe@redu.example', 'patrickdoe@redu.example'));
            studentAdminstratives.put('nikodemdoe@redu.example', REDU_TestData_UTIL.newAdministrativeAccount('nikodemdoe@redu.example', 'nikodemdoe@redu.example'));
            studentAdminstratives.put('jonathandoe@redu.example', REDU_TestData_UTIL.newAdministrativeAccount('jonathandoe@redu.example', 'jonathandoe@redu.example'));
            studentAdminstratives.put('dorothydoe@redu.example', REDU_TestData_UTIL.newAdministrativeAccount('dorothydoe@redu.example', 'dorothydoe@redu.example'));
            studentAdminstratives.put('miyadoe@redu.example', REDU_TestData_UTIL.newAdministrativeAccount('miyadoe@redu.example', 'miyadoe@redu.example'));
            studentAdminstratives.put('monicadoe@redu.example', REDU_TestData_UTIL.newAdministrativeAccount('monicadoe@redu.example', 'monicadoe@redu.example'));
            studentAdminstratives.put('stevendoe@redu.example', REDU_TestData_UTIL.newAdministrativeAccount('stevendoe@redu.example', 'stevendoe@redu.example'));
        }

        REDU_SystemMode_UTIL.doInsert(studentAdminstratives.values());

        //student contact
        students.put('johndoe@redu.example', REDU_TestData_UTIL.newStudentContact('johndoe@redu.example', studentAdminstratives.get('johndoe@redu.example').Id, 'John', 'Doe', 'johndoe@redu.example', 'STUD-0001'));
        students.put('amydoe@redu.example', REDU_TestData_UTIL.newStudentContact('amydoe@redu.example', studentAdminstratives.get('amydoe@redu.example').Id, 'Amy', 'Doe', 'amydoe@redu.example', 'STUD-0002'));
        students.put('sandydoe@redu.example', REDU_TestData_UTIL.newStudentContact('sandydoe@redu.example', studentAdminstratives.get('sandydoe@redu.example').Id, 'Sandy', 'Doe', 'sandydoe@redu.example', 'STUD-0003'));
        
        if (FULLDATA) {
            students.put('tommydoe@redu.example', REDU_TestData_UTIL.newStudentContact('tommydoe@redu.example', studentAdminstratives.get('tommydoe@redu.example').Id, 'Tommy', 'Doe', 'tommydoe@redu.example', 'STUD-0004'));
            students.put('fionnadoe@redu.example', REDU_TestData_UTIL.newStudentContact('fionnadoe@redu.example', studentAdminstratives.get('fionnadoe@redu.example').Id, 'Fionna', 'Doe', 'fionnadoe@redu.example', 'STUD-0005'));
            students.put('codydoe@redu.example', REDU_TestData_UTIL.newStudentContact('codydoe@redu.example', studentAdminstratives.get('codydoe@redu.example').Id, 'Cody', 'Doe', 'codydoe@redu.example', 'STUD-0006'));
            students.put('farisdoe@redu.example', REDU_TestData_UTIL.newStudentContact('farisdoe@redu.example', studentAdminstratives.get('farisdoe@redu.example').Id, 'Faris', 'Doe', 'farisdoe@redu.example', 'STUD-0007'));
            students.put('pauladoe@redu.example', REDU_TestData_UTIL.newStudentContact('pauladoe@redu.example', studentAdminstratives.get('pauladoe@redu.example').Id, 'Paula', 'Doe', 'pauladoe@redu.example', 'STUD-0008'));
            students.put('herbiedoe@redu.example', REDU_TestData_UTIL.newStudentContact('herbiedoe@redu.example', studentAdminstratives.get('herbiedoe@redu.example').Id, 'Herbie', 'Doe', 'herbiedoe@redu.example', 'STUD-0009'));
            students.put('coraldoe@redu.example', REDU_TestData_UTIL.newStudentContact('coraldoe@redu.example', studentAdminstratives.get('coraldoe@redu.example').Id, 'Coral', 'Doe', 'coraldoe@redu.example', 'STUD-0010'));
            students.put('lochlandoe@redu.example', REDU_TestData_UTIL.newStudentContact('lochlandoe@redu.example', studentAdminstratives.get('lochlandoe@redu.example').Id, 'Lochlan', 'Doe', 'lochlandoe@redu.example', 'STUD-0011'));
            students.put('katydoe@redu.example', REDU_TestData_UTIL.newStudentContact('katydoe@redu.example', studentAdminstratives.get('katydoe@redu.example').Id, 'Katy', 'Doe', 'katydoe@redu.example', 'STUD-0012'));
            students.put('jeffreydoe@redu.example', REDU_TestData_UTIL.newStudentContact('jeffreydoe@redu.example', studentAdminstratives.get('jeffreydoe@redu.example').Id, 'Jeffrey', 'Doe', 'jeffreydoe@redu.example', 'STUD-0013'));
            students.put('patrickdoe@redu.example', REDU_TestData_UTIL.newStudentContact('patrickdoe@redu.example', studentAdminstratives.get('patrickdoe@redu.example').Id, 'Patrick', 'Doe', 'patrickdoe@redu.example', 'STUD-0014'));
            students.put('nikodemdoe@redu.example', REDU_TestData_UTIL.newStudentContact('nikodemdoe@redu.example', studentAdminstratives.get('nikodemdoe@redu.example').Id, 'Nikodem', 'Doe', 'nikodemdoe@redu.example', 'STUD-0015'));
            students.put('jonathandoe@redu.example', REDU_TestData_UTIL.newStudentContact('jonathandoe@redu.example', studentAdminstratives.get('jonathandoe@redu.example').Id, 'Jonathan', 'Doe', 'jonathandoe@redu.example', 'STUD-0016'));
            students.put('dorothydoe@redu.example', REDU_TestData_UTIL.newStudentContact('dorothydoe@redu.example', studentAdminstratives.get('dorothydoe@redu.example').Id, 'Dorothy', 'Doe', 'dorothydoe@redu.example', 'STUD-0017'));
            students.put('miyadoe@redu.example', REDU_TestData_UTIL.newStudentContact('miyadoe@redu.example', studentAdminstratives.get('miyadoe@redu.example').Id, 'Miya', 'Doe', 'miyadoe@redu.example', 'STUD-0018'));
            students.put('monicadoe@redu.example', REDU_TestData_UTIL.newStudentContact('monicadoe@redu.example', studentAdminstratives.get('monicadoe@redu.example').Id, 'Monica', 'Doe', 'monicadoe@redu.example', 'STUD-0019'));
            students.put('stevendoe@redu.example', REDU_TestData_UTIL.newStudentContact('stevendoe@redu.example', studentAdminstratives.get('stevendoe@redu.example').Id, 'Steven', 'Doe', 'stevendoe@redu.example', 'STUD-0020'));
        }

        REDU_SystemMode_UTIL.doInsert(students.values());

        if (validateCheckpoint(CON_Helper.getApiName(), skipAfterObject)) {
            unmuteTriggers();
            unmuteRollup();
            return;
        }

        //provision the student contact as digital experience user
        if (enableStudentUser) {
            //create user
            for (Contact student : students.values()) {
                studentUsers.put(student.Email, REDU_TestData_UTIL.newUser(student.FirstName, student.LastName, student.Id, studentProfileId, student.Email));
            }

            REDU_SystemMode_UTIL.doInsert(studentUsers.values());

            List<Id> userIds = new List<Id>();
            for (User studentUsr : studentUsers.values()) {
                userIds.add(studentUsr.Id);
            }

            //assign permission set
            if (Test.isRunningTest()) {
                User runningUser = getSetupUser();

                System.runAs(runningUser) {
                    assignPermissionSet(userIds, studentPermissionSetIds);
                }
            } else {
                assignPermissionSetFuture(userIds, studentPermissionSetIds);
            }
        }

        if (validateCheckpoint(USR_Helper.getApiName(), skipAfterObject)) {
            unmuteTriggers();
            unmuteRollup();
            return;
        }

        //individual achievement
        for (Contact student : students.values()) {
            idvAchievement.put(student.reduivy__Sample_Record_Code__c + 'Individual_Achievement', REDU_TestData_UTIL.newIndividualAchievement(student.reduivy__Sample_Record_Code__c + 'Individual_Achievement', student.Id, 'Diploma in Business Management - ' + student.FirstName + student.LastName, 'University of Golders Green', IAC_Helper.ACADEMIC_LEVEL_DIPLOMA, IAC_Helper.COMPLETION_STATUS_AWARDED, Date.newInstance(2023, 01, 01), IAC_Helper.VERIFICATION_STATUS_REVIEWING, null));
        }

        REDU_SystemMode_UTIL.doInsert(idvAchievement.values());

        if (validateCheckpoint(IAC_Helper.getApiName(), skipAfterObject)) {
            unmuteTriggers();
            unmuteRollup();
            return;
        }

        //individual achievement units
        reduivy__Agreement_Recognition_Unit__c aruForIau = agreementRecognitionUnits.get('ARU_Introduction_to_Business_Studies');
        if(aruForIau != null) {
            
            for(reduivy__Individual_Achievement__c iac : idvAchievement.values()) {
                String iauSrc = iac.reduivy__Sample_Record_Code__c + '_' + aruForIau.reduivy__Sample_Record_Code__c;
                idvAchievementUnit.put(iauSrc, REDU_Testdata_UTIL.newIndividualAchievementUnit(iauSrc, aruForIau.Id, iac.Id, 'A', 80, IAU_Helper.getReviewVerificationStatuses().get(0)));
            }
            
            REDU_SystemMode_UTIL.doInsert(idvAchievementUnit.values());
        }
        if (validateCheckpoint(IAU_Helper.getApiName(), skipAfterObject)) {
            unmuteTriggers();
            unmuteRollup();
            return;
        }

        //Create academic profile
        for(Contact student : students.values()){
            individualAcademicProfiles.put(student.reduivy__Sample_Record_Code__c, REDU_TestData_UTIL.newIndividualAcademicProfile(student.reduivy__Sample_Record_Code__c, student.Id, 'Academic Profile - ' + student.FirstName + ' ' + student.LastName + ' (Bachelors Honours)', IPF_Helper.STATUS_ACTIVE, true));
        }
        
        REDU_SystemMode_UTIL.doInsert(individualAcademicProfiles.values());

        if (validateCheckpoint(IPF_Helper.getApiName(), skipAfterObject)) {
            unmuteTriggers();
            unmuteRollup();
            return;
        }

        Map<Id, List<String>> studentWithStudyTerm = new Map<Id, List<String>>();

        //students started last year
        studentWithStudyTerm.put(students.get('johndoe@redu.example').Id, 
            new List<String> { 
                'PYT1', 
                'PYT2', 
                'CYT1' 
            }
        );

        studentWithStudyTerm.put(students.get('amydoe@redu.example').Id, 
            new List<String> { 
                'PYT1', 
                'PYT2', 
                'CYT1' 
            }
        );

        //student started this term
        for (Contact student : students.values()) {
            if (!studentWithStudyTerm.containsKey(student.Id)) {
                studentWithStudyTerm.put(student.Id, 
                    new List<String> { 
                        'CYT1'
                    }
                );
            }
        }

        //Create academic progress for each academic profile
        for(reduivy__Individual_Academic_Profile__c ipf : individualAcademicProfiles.values()){
            for (String termKey : studentWithStudyTerm.get(ipf.reduivy__Contact__c)) {
                individualAcademicProgress.put(ipf.reduivy__Sample_Record_Code__c + '_' + termKey, REDU_TestData_UTIL.newIndividualAcademicProgress(ipf.reduivy__Sample_Record_Code__c + '_' + termKey, ipf.reduivy__Contact__c, academicTerms.get(termKey)?.Id, ipf.Id));
            }
        }

        REDU_SystemMode_UTIL.doInsert(individualAcademicProgress.values());

        if (validateCheckpoint(IPR_Helper.getApiName(), skipAfterObject)) {
            unmuteTriggers();
            unmuteRollup();
            return;
        }

        unmuteTriggers();

        //individual funding allocation
        idvFundingAllocation.put('AmyDoe_RIO_University_Hardship_Award', REDU_TestData_UTIL.newIdvFundingAllocation('AmyDoe_RIO_University_Hardship_Award', students.get('amydoe@redu.example').Id, studyFundings.get('RIO_University_Hardship_Award').Id, 3000, Date.newInstance(2022, 01, 01), Date.newInstance(2028, 12, 31), 3000, IFA_Helper.STATUS_ACTIVE));

        REDU_SystemMode_UTIL.doInsert(idvFundingAllocation.values());

        if (validateCheckpoint(IFA_Helper.getApiName(), skipAfterObject)) {
            unmuteTriggers();
            unmuteRollup();
            return;
        }

        if (academicTerms.isEmpty() || studyOfferings.isEmpty()) {
            throw new REDU_ApplicationException('Not able to find academic term, and study offering. Please execute initMasterData() and initOfferingDate() to generate master data.');
        }

        //individual enrollment
        String ienCompletedStatus = IEN_Helper.getCompletedPassStatuses().get(0);
        String ienInProgressStatus = IEN_Helper.getInProgressStatuses().get(0);
        
        //individual enrollment for current term (link to the academic progress)
        for (Contact student : students.values()) {
            Integer termNo = 1;
            for (String termKey : studentWithStudyTerm.get(student.Id)) {
                List<String> sunListForTerm = sunListByTermNo.get(termNo);
                String ienEnrollmentStatus;

                if (termKey.startsWith('PY')) {
                    ienEnrollmentStatus = ienCompletedStatus;
                } else {
                    ienEnrollmentStatus = ienInProgressStatus;
                }

                for (String sunCode : sunListForTerm) {
                    String sampleRecordIenKey = String.join(new List<String>{student.reduivy__Sample_Record_Code__c, sunCode, termKey, 'SYDNEY'}, '_');
                    reduivy__Individual_Academic_Profile__c studentIpf = individualAcademicProfiles.get(student.reduivy__Sample_Record_Code__c);
                    reduivy__Individual_Academic_Progress__c studentIprForTerm = individualAcademicProgress.get(studentIpf.reduivy__Sample_Record_Code__c + '_' + termKey);
                    Date startDate = academicTerms.get(termKey).reduivy__Start_Date__c;
                    Date endDate = academicTerms.get(termKey).reduivy__End_Date__c;

                    reduivy__Individual_Enrollment__c studIen = REDU_TestData_UTIL.newStudentIndividualEnrollment(sampleRecordIenKey, student.Id, studyOfferings.get(sunCode + '_' + termKey + '_SYDNEY').Id, ienEnrollmentStatus, 1, startDate, startDate, endDate, null, 10, studentIprForTerm.Id, studentIpf.Id, true);
                    
                    studentIndividualEnrollments.put(sampleRecordIenKey, studIen);
                }

                termNo ++;
            }
        }

        Set<String> ienTriggers = new Set<String>{
            'IEN_BestAttempt_EXE',
            'IEN_CompletionEngine_EXE',
            'IEN_IncrementAttemptNumber_EXE',
            'IEN_PopulateDate_EXE',
            'IEN_SetCreditsAttempted_EXE',
            'IEN_SetCreditsEarned_EXE',
            'IEN_SetCreditsOffered_EXE',
            'IEN_SetGradeSetting_EXE',
            'IEN_WaitlistDate_EXE',
            'IEN_PopulateEftsl_EXE',
            'IEN_CloneRecognizedUnit_EXE'
        };
        REDU_TriggerController.muteTriggers(ienTriggers);
        REDU_SystemMode_UTIL.doInsert(studentIndividualEnrollments.values());
        REDU_TriggerController.unmuteTriggers(ienTriggers);

        if (validateCheckpoint(IEN_Helper.getApiName(), skipAfterObject)) {
            unmuteTriggers();
            unmuteRollup();
            return;
        }

        //get student idv enrollments which status == 'Completed'
        List<reduivy__Individual_Enrollment__c> idvEnrollCompleted = new List<reduivy__Individual_Enrollment__c>();
        for(reduivy__Individual_Enrollment__c idvEnroll : studentIndividualEnrollments.values()){
            if(idvEnroll.reduivy__Enrollment_Status__c == ienCompletedStatus && idvEnroll.RecordTypeId == IEN_Helper.getStudentRecordTypeId()){
                idvEnrollCompleted.add(idvEnroll);
            }
        }

        //get term Id by: studyOfferingId + studyTermId Map
        Map<Id, Id> soIdWithStId = new Map<Id, Id>();
        for(reduivy__Study_Offering__c so : studyOfferings.values()){
            soIdWithStId.put(so.Id, so.reduivy__Academic_Term__c);
        }

        //get study grade period setting by term
        Map<Id, Set<Id>> termWithStudyGradePeriodSetting = new Map<Id, Set<Id>>();
        for(reduivy__Study_Grade_Period_Setting__c sgps : studyGradePeriodSettings.values()) {

            if(!termWithStudyGradePeriodSetting.containsKey(sgps.reduivy__Academic_Term__c)) {
                termWithStudyGradePeriodSetting.put(sgps.reduivy__Academic_Term__c, new Set<Id>());
            }

            termWithStudyGradePeriodSetting.get(sgps.reduivy__Academic_Term__c).add(sgps.Id);
        }

        //assign individualEnrollmentGrades for each student from idvEnrollCompleted
        for(reduivy__Individual_Enrollment__c ie : idvEnrollCompleted){
            Date gradingDate = ie.reduivy__End_Date__c;
            Date submittedDate = ie.reduivy__End_Date__c;
            Id stId = soIdWithStId.get(ie.reduivy__Study_Offering__c);
            
            Set<Id> sgpIds = termWithStudyGradePeriodSetting.get(stId);

            if (sgpIds != null) {
                for (Id sgpId : sgpIds) {
                    String igdSampleRecordCode = ie.reduivy__Sample_Record_Code__c + '_' + sgpId;

                    individualEnrollmentGrades.put(igdSampleRecordCode, REDU_TestData_UTIL.newIndividualEnrollmentGrade(igdSampleRecordCode, ie.reduivy__Contact__c, ie.Id, stId, sgpId, ie.reduivy__Study_Offering__c, null, null, null, 'Submitted', gradingDate, submittedDate));
                }
            } else {
                String igdSampleRecordCode = ie.reduivy__Sample_Record_Code__c;

                individualEnrollmentGrades.put(igdSampleRecordCode, REDU_TestData_UTIL.newIndividualEnrollmentGrade(igdSampleRecordCode, ie.reduivy__Contact__c, ie.Id, stId, null, ie.reduivy__Study_Offering__c, null, null, null, 'Submitted', gradingDate, submittedDate));
            }
        }

        REDU_SystemMode_UTIL.doInsert(individualEnrollmentGrades.values());

        if (validateCheckpoint(IGD_Helper.getApiName(), skipAfterObject)) {
            unmuteTriggers();
            unmuteRollup();
            return;
        }

        //create 2 individualGradeItm for each individualEnrollmentGrades
        for(reduivy__Individual_Enrollment_Grade__c idvEG : individualEnrollmentGrades.values()){
            Integer asmNumGrade = (Integer)(Math.random() * 51) + 50; //random 50 to 100
            Integer exmNumGrade = (Integer)(Math.random() * 51) + 50;

            Id studId;
            Id soId;
            for(reduivy__Individual_Enrollment__c ien : studentIndividualEnrollments.values()){
                if(idvEg.reduivy__Individual_Enrollment__c == ien.Id){
                    studId = ien.reduivy__Contact__c;
                    soId = ien.reduivy__Study_Offering__c;
                }
            }

            if(studId != null && soId != null){
                String studentName;
                for(Contact s : students.values()){
                    if(s.Id == studId){
                        studentName = s.FirstName + ' ' + s.LastName;
                    }
                }
                String soSrc; //studyOffering sample record code
                for(reduivy__Study_Offering__c so : studyOfferings.values()){
                    if(so.Id == soId){
                        soSrc = so.reduivy__Sample_Record_Code__c;
                    }
                }
                
                if(studentName != null && soSrc != null){
                    individualGradeItems.put('Assignment_' + idvEG.reduivy__Sample_Record_Code__c, REDU_TestData_UTIL.newIndividualGradeItem('Assignment_' + idvEG.reduivy__Sample_Record_Code__c, null, idvEG.Id, 'Assignment (' + soSrc + ') - ' + studentName, null, 50, null, asmNumGrade, null));
                    individualGradeItems.put('Exam_' + idvEG.reduivy__Sample_Record_Code__c, REDU_TestData_UTIL.newIndividualGradeItem('Exam_' + idvEG.reduivy__Sample_Record_Code__c, null, idvEG.Id, ' Exam (' + soSrc + ') - ' + studentName, null, 50, null, exmNumGrade, null));
                }
            }
        }
        
        REDU_SystemMode_UTIL.doInsert(individualGradeItems.values());

        //update the individualEnrollment's GradeReleaseStatus = 'Released' 
        for(reduivy__Individual_Enrollment__c ie : idvEnrollCompleted){
            ie.reduivy__Grade_Release_Status__c = 'Released';
        }

        REDU_TriggerController.muteTriggers(new Set<String>{'IEN_CloneRecognizedUnit_EXE'});
        REDU_SystemMode_UTIL.doUpdate(idvEnrollCompleted);
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IEN_CloneRecognizedUnit_EXE'});

        if (validateCheckpoint(IGI_Helper.getApiName(), skipAfterObject)) {
            unmuteTriggers();
            unmuteRollup();
            return;
        }

        System.debug('before ipe ' + Limits.getQueries());

        if (campuses.isEmpty() || academicTerms.isEmpty() || studyPlans.isEmpty()) {
            throw new REDU_ApplicationException('Not able to find campuses, academic term, study plan, and study intake (optional). Please execute initMasterData() and initOfferingDate() to generate master data.');
        }

        //individual program enrollment
        String ipeEnrollmentStatus = IPE_Helper.getInProgressStatuses().get(0);
        String splMajorKey = 'BACBIS_MajorA';
        String splMinorKey = 'BACBIS_MinorA';

        for (Contact student : students.values()) {
            String masterIpekey = student.reduivy__Sample_Record_Code__c + '_' + splMajorKey;
            String childIpekey = student.reduivy__Sample_Record_Code__c + '_' + splMinorKey;
            String startingTermKey = studentWithStudyTerm.get(student.Id).get(0);
            String studyIntakeKey;
            
            if (startingTermKey.startsWith('PY')) {
                studyIntakeKey = 'SYDNEY_BACBIS_PYINTAKE';
            } else {
                studyIntakeKey = 'SYDNEY_BACBIS_CYINTAKE';
            }
            
            reduivy__Study_Term__c startingTerm = academicTerms.get(startingTermKey);
            
            masterProgramEnrollments.put(masterIpekey, REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(masterIpekey, student.Id, studyPlans.get(splMajorKey).reduivy__Study_Program__c, studyPlans.get(splMajorKey).Id, studyIntakes.get(studyIntakeKey)?.Id, startingTerm.Id, studyIntakes.get(studyIntakeKey)?.reduivy__Default_Study_Pathway__c, campuses.get('SYDNEY').Id, String.valueOf(startingTerm.reduivy__Start_Date__c.year()), 'Freshman', true, ipeEnrollmentStatus, individualAcademicProfiles.get(student.reduivy__Sample_Record_Code__c).Id));
            childProgramEnrollments.put(childIpekey, REDU_TestData_UTIL.newChildIndividualProgramEnrollment(childIpekey, student.Id, studyPlans.get(splMinorKey).reduivy__Study_Program__c, studyPlans.get(splMinorKey).Id,masterProgramEnrollments.get(masterIpekey).Id, IPE_Helper.COMPLETION_REQUIREMENT_MANDATORY, true, ipeEnrollmentStatus));
        }

        Set<String> ipeTriggers = new Set<String>{
            'IPE_AcademicProfile_EXE',
            'IPE_DefaultValues_EXE',
            'IPE_DeleteEnrollment_EXE',
            'IPE_RequirementMet_EXE',
            'IPE_UpdateContactType_EXE'
        };

        REDU_TriggerController.muteTriggers(ipeTriggers);

        List<reduivy__Individual_Program_Enrollment__c> allProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
        allProgramEnrollments.addAll(masterProgramEnrollments.values());
        allProgramEnrollments.addAll(childProgramEnrollments.values());

        REDU_SystemMode_UTIL.doInsert(allProgramEnrollments);

        List<reduivy__Individual_Program_Enrollment__c> childProgramEnrollmentsToUpdate = new List<reduivy__Individual_Program_Enrollment__c>();
        for (Contact student : students.values()) {
            String masterIpekey = student.reduivy__Sample_Record_Code__c + '_' + splMajorKey;
            String childIpekey = student.reduivy__Sample_Record_Code__c + '_' + splMinorKey;

            childProgramEnrollmentsToUpdate.add(
                new reduivy__Individual_Program_Enrollment__c(
                    Id = childProgramEnrollments.get(childIpekey).Id,
                    reduivy__Master_Enrollment__c = masterProgramEnrollments.get(masterIpekey).Id
                )
            );
            
        }

        REDU_SystemMode_UTIL.doUpdate(childProgramEnrollmentsToUpdate);

        REDU_TriggerController.unmuteTriggers(ipeTriggers);

        muteTriggers();

        //Update academic term for individual pathways
        List<reduivy__Individual_Pathway__c> individualPathwaysToUpdate = new List<reduivy__Individual_Pathway__c>();
        for(reduivy__Individual_Pathway__c idvp : [SELECT Id, 
            reduivy__Term_Number__c, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Individual_Academic_Profile__r.reduivy__Sample_Record_Code__c 
            FROM reduivy__Individual_Pathway__c 
            WHERE reduivy__Individual_Program_Enrollment__c IN: masterProgramEnrollments.values() 
            AND reduivy__Term_Number__c > 0
            WITH SYSTEM_MODE]
        ) {
            
            Integer termNoSeq = idvp.reduivy__Term_Number__c.intValue() - 1;

            if (studentWithStudyTerm.get(idvp.reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c).size() > termNoSeq ) {
                String termKey = studentWithStudyTerm.get(idvp.reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c).get(termNoSeq);
                reduivy__Individual_Academic_Progress__c studentIprForTerm = individualAcademicProgress.get(idvp.reduivy__Individual_Program_Enrollment__r.reduivy__Individual_Academic_Profile__r.reduivy__Sample_Record_Code__c + '_' + termKey);

                individualPathwaysToUpdate.add(new reduivy__Individual_Pathway__c(
                    Id = idvp.Id,
                    reduivy__Academic_Term__c = academicTerms.get(termKey).Id,
                    reduivy__Individual_Academic_Progress__c = studentIprForTerm.Id
                ));
            }
        }

        REDU_SystemMode_UTIL.doUpdate(individualPathwaysToUpdate);

        if (validateCheckpoint(IPE_Helper.getApiName(), skipAfterObject)) {
            unmuteTriggers();
            unmuteRollup();
            return;
        }

        //Credit Transfer Application
        if (!agreementUnitEquavalents.isEmpty()) {
            creditTransferApplications.put('CTA_Introduction_to_Business_Studies', REDU_TestData_UTIL.newCreditTransferApplication('CTA_Introduction_to_Business_Studies', students.get('sandydoe@redu.example').Id, agreementUnitEquavalents.get('AUE_Introduction_to_Business_Studies').Id, masterProgramEnrollments.get('sandydoe@redu.example_BACBIS_MajorA').Id, null, 'B', 66, 5, 5, System.today(), CTA_Helper.STATUS_TYPE_SUBMITTED, 'CT', new Set<String>{}, CTA_Helper.TYPE_INCOMING));
            creditTransferApplications.put('CTA_Advanced_Marketing_Studies', REDU_TestData_UTIL.newCreditTransferApplication('CTA_Advanced_Marketing_Studies', students.get('sandydoe@redu.example').Id, agreementUnitEquavalents.get('AUE_Advanced_Marketing_Studies').Id, masterProgramEnrollments.get('sandydoe@redu.example_BACBIS_MajorA').Id, null, 'A', 75, 5, 5, System.today(), CTA_Helper.STATUS_TYPE_APPROVED, 'CT', new Set<String>{'MKT101', 'MKT102', 'MKT103'}, CTA_Helper.TYPE_INCOMING));

            if (FULLDATA) {
                creditTransferApplications.put('CTA_Intro_to_MathsI_Intro_to_MathsII', REDU_TestData_UTIL.newCreditTransferApplication('CTA_Intro_to_MathsI_Intro_to_MathsII', students.get('fionnadoe@redu.example').Id, agreementUnitEquavalents.get('AUE_Intro_to_MathsI_Intro_to_MathsII').Id, masterProgramEnrollments.get('fionnadoe@redu.example_BACBIS_MajorA').Id, null, 'A', 75, 4, 4, System.today(), CTA_Helper.STATUS_TYPE_APPROVED, 'CT', new Set<String>{'MAT201'}, CTA_Helper.TYPE_INCOMING));
                creditTransferApplications.put('CTA_Leadership_Skills', REDU_TestData_UTIL.newCreditTransferApplication('CTA_Leadership_Skills', students.get('fionnadoe@redu.example').Id, agreementUnitEquavalents.get('AUE_Leadership_Skills').Id, masterProgramEnrollments.get('fionnadoe@redu.example_BACBIS_MajorA').Id, null, 'B', 66, 4, 4, System.today(), CTA_Helper.STATUS_TYPE_SUBMITTED, 'CT', new Set<String>{}, CTA_Helper.TYPE_INCOMING));
            }

            REDU_SystemMode_UTIL.doInsert(creditTransferApplications.values());
        }

        if (validateCheckpoint(CTA_Helper.getApiName(), skipAfterObject)) {
            unmuteTriggers();
            unmuteRollup();
            return;
        }

        unmuteTriggers();

        if (studyIntakes.isEmpty()) {
            throw new REDU_ApplicationException('Not able to find study intakes. Please execute initMasterData() and initOfferingData() to generate master data.');
        }

        Set<String> createRequirementTriggers = new Set<String> {
            'SOBJ_CreateIndividualRequirementSet_EXE',
            'IRS_CreateIndividualRequirement_EXE',
            'SOBJ_IndividualScoreGeneration_EXE',
            'SOBJ_IndividualScoreEvaluation_EXE',
            'IRS_UpdateParentCompletionIndicator_EXE'
        };
        REDU_TriggerController.muteTriggers(createRequirementTriggers);
        //Individual Program Application
        for(Contact student : students.values()) {
            String sampleRecordString = student.reduivy__Sample_Record_Code__c;
            String startingTermKey = studentWithStudyTerm.get(student.Id).get(0);
            String studyIntakeKey;
            if (startingTermKey.startsWith('PY')) {
                studyIntakeKey = 'SYDNEY_BACBIS_PYINTAKE';
            } else {
                studyIntakeKey = 'SYDNEY_BACBIS_CYINTAKE';
            }

            reduivy__Individual_Program_Application__c newIpa = REDU_TestData_UTIL.newIndividualProgramApplication(sampleRecordString, student.Id, studyPrograms.get('BACBIS').Id, studyPlans.get(splMajorKey).Id, studyPlans.get(splMinorKey).Id, studyIntakes.get(studyIntakeKey).Id);
            newIpa.reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_SUBMITTED;
            individualProgramApplicaitions.put(sampleRecordString, newIpa);
        }

        REDU_SystemMode_UTIL.doInsert(individualProgramApplicaitions.values());

        
        if (validateCheckpoint(IPA_Helper.getApiName(), skipAfterObject)) {
            unmuteTriggers();
            unmuteRollup();
            return;
        }

        //Individual Requirement Set
        if(!studyRequirementSets.isEmpty()) {
            for(reduivy__Study_Requirement_Set__c srs : studyRequirementSets.values()) {

                List<SObject> parentSObjList;
                Boolean isIau = false;
                if(srs.reduivy__Object__c == IAU_Helper.getApiName()) {
                    parentSObjList = idvAchievementUnit.values();
                    isIau = true;
                } else if(srs.reduivy__Object__c == IAC_Helper.getApiName()) {
                    parentSObjList = idvAchievement.values();
                } else if(srs.reduivy__Object__c == IPA_Helper.getApiName()) {
                    parentSObjList = individualProgramApplicaitions.values();
                }
                if(parentSObjList != null || !parentSObjList.isEmpty()) {
                    for(SObject sobj : parentSObjList) {
                        
                        String irsKey = (String) sobj.get('reduivy__Sample_Record_Code__c') + '_' + srs.reduivy__Sample_Record_Code__c;
                        if(isIau) { 
                            List<String> sobjSrcSplit = ((String) sobj.get('reduivy__Sample_Record_Code__c')).split('_');
                            String iacSrc = sobjSrcSplit[0] + '_' + sobjSrcSplit[1];
                            system.debug(JSON.serialize(sobjSrcSplit));
                            system.debug(iacSrc);
                            reduivy__Individual_Achievement__c iac = idvAchievement.get(iacSrc);
                            sobj.putSObject('reduivy__Individual_Achievement__r', iac);
                        }
                        reduivy__Individual_Requirement_Set__c irs = IRS_Helper.createIrs(srs, sobj, UserInfo.getUserId());
                        irs.reduivy__Sample_Record_Code__c = irsKey;
                        individualRequirementSets.put(irsKey, irs);
                    }
                }

                


            }
            
            REDU_SystemMode_UTIL.doInsert(individualRequirementSets.values());
        }
        
        if (validateCheckpoint(IRS_Helper.getApiName(), skipAfterObject)) {
            unmuteTriggers();
            unmuteRollup();
            return;
        }

        //Individual Requirement
        if(!individualRequirementSets.isEmpty()) {
            for(reduivy__Individual_Requirement_Set__c irs : individualRequirementSets.values()) {
                for(reduivy__Study_Requirement__c srq : studyRequirements.values()) {
                    if(srq.reduivy__Study_Requirement_Set__c == irs.reduivy__Study_Requirement_Set__c) {

                        String irqKey = irs.reduivy__Sample_Record_Code__c + '_' + srq.reduivy__Sample_Record_Code__c;
                        reduivy__Individual_Requirement__c irq = IRQ_Helper.createIrq(srq, irs.Id, UserInfo.getUserId());
                        irq.reduivy__Sample_Record_Code__c = irqKey;
                        individualRequirements.put(irqKey, irq);
                        
                    }
                }
            }

            REDU_SystemMode_UTIL.doInsert(individualRequirements.values());
        }

        if (validateCheckpoint(IRQ_Helper.getApiName(), skipAfterObject)) {
            unmuteTriggers();
            unmuteRollup();
            return;
        }

        if(IPA_Helper.canRunEvaluationTest()) {
            //Individual Score
            for(String ipaSrc : individualProgramApplicaitions.keySet()) {
                reduivy__Individual_Program_Application__c ipa = individualProgramApplicaitions.get(ipaSrc);
                for(String configSrc : studyScoringConfigs.keySet()){
                    reduivy__Study_Scoring_Config__c config = studyScoringConfigs.get(configSrc);
                    String iscSrc = ipaSrc + '_' + configSrc;
                    individualScores.put(iscSrc, REDU_Testdata_UTIL.newIndividualScore(iscSrc, config.Name, config.Id, ipa.Id, ipa.reduivy__Contact__c));
                }
            }

            REDU_SystemMode_UTIL.doInsert(individualScores.values());

            if (validateCheckpoint(ISC_Helper.getApiName(), skipAfterObject)) {
                unmuteTriggers();
                unmuteRollup();
                return;
            }

            Set<Id> scfIdSet = (new Map<Id, reduivy__Study_Scoring_Config__c>(studyScoringConfigs.values())).keySet();
            Map<Id, reduivy__Individual_Requirement_Set__c> irsMap = new Map<Id, reduivy__Individual_Requirement_Set__c>(individualRequirementSets.values());
            Map<String, Id> sobjIdSrqIdToIrqIdMap = new Map<String, Id>();
            for(String irqSrc : individualRequirements.keySet()) {
                reduivy__Individual_Requirement__c irq = individualRequirements.get(irqSrc);

                Id srqId = irq.reduivy__Study_Requirement__c;
                Id irsId = irq.reduivy__Individual_Requirement_Set__c;
                Id sobjId = (Id)irsMap.get(irsId).get('reduivy__Individual_Program_Application__c');
                
                sobjIdSrqIdToIrqIdMap.put(sobjId + '_' + srqId, irq.Id);
                
            }
            //Individual Score Detail
            Map<Id, Map<Id, List<reduivy__Study_Scoring_Criteria__c>>> scrGroupMap = SCR_Helper.getGroupMap(scfIdSet);
            Map<String, List<reduivy__Individual_Score_Detail__c>> parentIsdToIsdMap = new Map<String, List<reduivy__Individual_Score_Detail__c>>();

            for(String individualScoreSrc : individualScores.keySet()) {
                reduivy__Individual_Score__c isc = individualScores.get(individualScoreSrc);

                Id targetScfId = isc.reduivy__Study_Scoring_Config__c;
                Map<Id, List<reduivy__Study_Scoring_Criteria__c>> parentScrToScrMap = scrGroupMap.get(targetScfId);

                for(Id parentScrId : parentScrToScrMap.keySet()) {
                    for(reduivy__Study_Scoring_Criteria__c scr : parentScrToScrMap.get(parentScrId)) {
                        reduivy__Individual_Score_Detail__c isd = ISD_Helper.createIsd(scr, isc.Id);
                        isd.reduivy__Sample_Record_Code__c = individualScoreSrc + '_' + scr.reduivy__Sample_Record_Code__c;
                        
                        String parentKey = isc.Id + '_' + parentScrId;
                        if(!parentIsdToIsdMap.containsKey(parentKey)){
                            parentIsdToIsdMap.put(parentKey, new List<reduivy__Individual_Score_Detail__c>());
                        }
                        
                        parentIsdToIsdMap.get(parentKey).add(isd);

                    }
                }
            }

            if(!parentIsdToIsdMap.isEmpty()) {
                List<reduivy__Individual_Score_Detail__c> isdListToInsert = new List<reduivy__Individual_Score_Detail__c>();
                Map<Id, reduivy__Individual_Score__c> iscMap = new Map<Id, reduivy__Individual_Score__c>(individualScores.values());

                // Insert the records
                for(List<reduivy__Individual_Score_Detail__c> isdList : parentIsdToIsdMap.values()) {
                    isdListToInsert.addAll(isdList);
                }

                REDU_SystemMode_UTIL.doInsert(isdListToInsert);

                Map<Id, reduivy__Individual_Score_Detail__c> isdMapToUpdate = new Map<Id, reduivy__Individual_Score_Detail__c>();
                
                // Update the child records with their parent Ids
                for(reduivy__Individual_Score_Detail__c isd : isdListToInsert) {
                    String parentKey = isd.reduivy__Individual_Score__c + '_' + isd.reduivy__Study_Scoring_Criteria__c;

                    if(parentIsdToIsdMap.containsKey(parentKey)) {
                        for(reduivy__Individual_Score_Detail__c childIsd : parentIsdToIsdMap.get(parentKey)) {
                            isdMapToUpdate.put(childIsd.Id, new reduivy__Individual_Score_Detail__c(
                                Id = childIsd.Id, 
                                reduivy__Parent_Score_Detail__c = isd.Id,
                                reduivy__Individual_Score__c = childIsd.reduivy__Individual_Score__c
                            ));
                        }
                    }
                }

                //create map of irq id => sobject id
                String sobjLookupFieldFromIrs = REDU_Metadata_UTIL.getObjectLookupField(IRS_Helper.getApiName(), IPA_Helper.getApiName());
                for(reduivy__Individual_Score_Detail__c isd : isdListToInsert) {
                    reduivy__Individual_Score__c parentIsc = iscMap.get((Id) isd.get('reduivy__Individual_Score__c'));
                    Id sobjId = (Id) parentIsc.get(sobjLookupFieldFromIrs);
                    Id irqId = sobjIdSrqIdToIrqIdMap.get(sobjId + '_' + isd.reduivy__Study_Requirement__c);
                    if(irqId != null) {
                        if(isdMapToUpdate.containsKey(isd.Id)) {
                            isdMapToUpdate.get(isd.Id).reduivy__Individual_Requirement__c = irqId;
                        } else {
                            isdMapToUpdate.put(isd.Id, new reduivy__Individual_Score_Detail__c(
                                Id = isd.Id,
                                reduivy__Individual_Requirement__c = irqId
                            ));
                        }
                    }   
                }

                if(!isdMapToUpdate.isEmpty()) {
                    REDU_SystemMode_UTIL.doUpdate(isdMapToUpdate.values());
                }
            }
            
            REDU_TriggerController.unmuteTriggers(createRequirementTriggers);
        }

        if (validateCheckpoint(ISD_Helper.getApiName(), skipAfterObject)) {
            unmuteTriggers();
            unmuteRollup();
            return;
        }

        //find student idv enrollment status = enrolled, select first studyOfferingId for each student
        Map<reduivy__Individual_Enrollment__c, reduivy__Study_Offering__c> idvEnrollWithStudyOffer = new Map<reduivy__Individual_Enrollment__c, reduivy__Study_Offering__c>();
        Set<Id> studentIds = new Set<Id>();

        for(reduivy__Individual_Enrollment__c idvEnroll : studentIndividualEnrollments.values()){
            if(idvEnroll.reduivy__Enrollment_Status__c == ienInProgressStatus && idvEnroll.RecordTypeId == IEN_Helper.getStudentRecordTypeId() && !studentIds.contains(idvEnroll.reduivy__Contact__c)){
                
                for(reduivy__Study_Offering__c so : studyOfferings.values()){
                    if(so.Id == idvEnroll.reduivy__Study_Offering__c){
                        idvEnrollWithStudyOffer.put(idvEnroll, so);
                        studentIds.add(idvEnroll.reduivy__Contact__c);
                    }
                }

            }
        }

        if (studySessions.isEmpty() || studySessionTimes.isEmpty()) {
            throw new REDU_ApplicationException('Not able to find study session, study session time and study event (optional). Please execute initMasterData() and initOfferingDate() to generate master data.');
        }

        //enroll students into Lecture study session (create student session enrollment)
        for(reduivy__Individual_Enrollment__c idvEnroll : idvEnrollWithStudyOffer.keySet()){
            for(reduivy__Study_Session__c ss : studySessions.values()){
                if(ss.reduivy__Study_Offering__c == idvEnrollWithStudyOffer.get(idvEnroll).Id && ss.reduivy__Type__c == 'Lecture'){
                    String isnSampleRecord = ss.Name + '_' + idvEnroll.reduivy__Sample_Record_Code__c;
                    studentIndividualSessionEnrollments.put(isnSampleRecord, REDU_TestData_UTIL.newStudentIndividualSessionEnrollment(isnSampleRecord, ss.Id, idvEnroll.Id, ss.reduivy__Start_Date__c, ISN_Helper.getInProgressStatuses().get(0)));
                }
            }
        }
        
        muteTriggers();

        REDU_SystemMode_UTIL.doInsert(studentIndividualSessionEnrollments.values());
 
        if (validateCheckpoint(ISN_Helper.getApiName(), skipAfterObject)) {
            unmuteTriggers();
            unmuteRollup();
            return;
        }


        if (!studyEvents.isEmpty()) {
            //create study event relation for student
            //Map studySessionId + IndividualSessionEnrollment (Map 1) --- match studySessionId
            Map<Id, List<reduivy__Individual_Session_Enrollment__c>> ssIdWithIsnList = new Map<Id, List<reduivy__Individual_Session_Enrollment__c>>();
            for(reduivy__Individual_Session_Enrollment__c isn : studentIndividualSessionEnrollments.values()){
                if(isn.RecordTypeId == ISN_Helper.getStudentRecordTypeId()){
                    if (ssIdWithIsnList.containsKey(isn.reduivy__Study_Session__c)) {
                        ssIdWithIsnList.get(isn.reduivy__Study_Session__c).add(isn);
                    } else {
                        ssIdWithIsnList.put(isn.reduivy__Study_Session__c, new List<reduivy__Individual_Session_Enrollment__c>{isn});
                    }
                }
            }

            //Map studySessionTimeId + studySessionId -> Map studySessionId + StudyEvent (Map 2)
            Map<Id, Id> sstIdWithSsId = new Map<Id, Id>();
            for(reduivy__Study_Session_Time__c sst : studySessionTimes.values()){
                sstIdWithSsId.put(sst.Id, sst.reduivy__Study_Session__c);
            }

            Map<Id, List<reduivy__Study_Event__c>> ssIdWithSe = new Map<Id, List<reduivy__Study_Event__c>>();
            for(reduivy__Study_Event__c se : studyEvents.values()){
                Id ssId = sstIdWithSsId.get(se.reduivy__Study_Session_Time__c);
                if(ssId != null){
                    if(!ssIdWithSe.containsKey(ssId)){
                        ssIdWithSe.put(ssId, new List<reduivy__Study_Event__c>());
                    }
                    ssIdWithSe.get(ssId).add(se);
                }
            }

            //match studySessionId Map 1 and Map 2 (for create study event relations)
            Map<Id, reduivy__Individual_Enrollment__c> iensMapById = new Map<Id, reduivy__Individual_Enrollment__c>(studentIndividualEnrollments.values());

            for(Id ssId : ssIdWithIsnList.keySet()){
                if(ssIdWithSe.containsKey(ssId)){
                    List<reduivy__Study_Event__c> seList = ssIdWithSe.get(ssId);
                    List<reduivy__Individual_Session_Enrollment__c> isnList = ssIdWithIsnList.get(ssId);
                    for (reduivy__Individual_Session_Enrollment__c isn : isnList) {
                        for(reduivy__Study_Event__c se : seList){
                            DateTime startDt = se.reduivy__Start__c;
                            DateTime endDt = se.reduivy__End__c;
                            
                            if(endDt.date() <= System.today()){
                                Time checkInTime = startDt.time();
                                Time checkOutTime = endDt.time();
                                String attendStatus = 'Attended';
                                String serSampleRecord = isn.reduivy__Sample_Record_Code__c + '_' + se.reduivy__Sample_Record_Code__c;
                                studentStudyEventRelations.put(serSampleRecord, REDU_TestData_UTIL.newStudentStudyEventRelation(serSampleRecord, iensMapById.get(isn.reduivy__Individual_Enrollment__c).reduivy__Contact__c, se.Id, isn.Id, checkInTime, checkOutTime, attendStatus));
                            }
                        }
                    }
                }
            }

            REDU_SystemMode_UTIL.doInsert(studentStudyEventRelations.values());
        }

        if (validateCheckpoint(SER_Helper.getApiName(), skipAfterObject)) {
            unmuteTriggers();
            unmuteRollup();
            return;
        }

        if (!studyFeeMatrixItems.isEmpty()) {
            Map<Id, Decimal> academicProgressWithTerm = new Map<Id, Decimal>();

            for (reduivy__Individual_Pathway__c idvp : [SELECT Id, reduivy__Individual_Academic_Progress__c, reduivy__Term_Number__c FROM reduivy__Individual_Pathway__c WHERE reduivy__Individual_Academic_Progress__c IN :individualAcademicProgress.values() WITH SYSTEM_MODE]) {
                academicProgressWithTerm.put(idvp.reduivy__Individual_Academic_Progress__c, idvp.reduivy__Term_Number__c);
            }

            //Create Transaction Order for each individual academic progress
            for(reduivy__Individual_Academic_Progress__c ipr : individualAcademicProgress.values()){
                if (ipr.reduivy__Contact__c == students.get('johndoe@redu.example').Id) {
                    if(academicProgressWithTerm.get(ipr.Id) == 1) {
                        transactionOrders.put(ipr.reduivy__Contact__c + '_' + ipr.reduivy__Academic_Term__c + '_Transaction Order', REDU_TestData_UTIL.newTransactionOrder(ipr.reduivy__Contact__c + '_' + ipr.reduivy__Academic_Term__c + '_Transaction Order', ipr.reduivy__Contact__c, ipr.Id, Date.newInstance(2024, 01, 01), TRO_Helper.getConfirmedStatuses().get(0), 2600, 100, 2500));

                    } else if (academicProgressWithTerm.get(ipr.Id) == 2) {
                        transactionOrders.put(ipr.reduivy__Contact__c + '_' + ipr.reduivy__Academic_Term__c + '_Transaction Order', REDU_TestData_UTIL.newTransactionOrder(ipr.reduivy__Contact__c + '_' + ipr.reduivy__Academic_Term__c + '_Transaction Order', ipr.reduivy__Contact__c, ipr.Id, Date.newInstance(2024, 01, 01), TRO_Helper.getConfirmedStatuses().get(0), 2550, 50, 2500));

                    } else if (academicProgressWithTerm.get(ipr.Id) == 3) {
                        transactionOrders.put(ipr.reduivy__Contact__c + '_' + ipr.reduivy__Academic_Term__c + '_Transaction Order', REDU_TestData_UTIL.newTransactionOrder(ipr.reduivy__Contact__c + '_' + ipr.reduivy__Academic_Term__c + '_Transaction Order', ipr.reduivy__Contact__c, ipr.Id, Date.newInstance(2024, 01, 01), TRO_Helper.getConfirmedStatuses().get(0), 1600, 100, 1500));

                    }
                } else if (ipr.reduivy__Contact__c == students.get('amydoe@redu.example').Id) {
                    if(academicProgressWithTerm.get(ipr.Id) == 1) {
                        transactionOrders.put(ipr.reduivy__Contact__c + '_' + ipr.reduivy__Academic_Term__c + '_Transaction Order', REDU_TestData_UTIL.newTransactionOrder(ipr.reduivy__Contact__c + '_' + ipr.reduivy__Academic_Term__c + '_Transaction Order', ipr.reduivy__Contact__c, ipr.Id, Date.newInstance(2024, 01, 01), TRO_Helper.getConfirmedStatuses().get(0), 2350, 1350, 1000));

                    } else if (academicProgressWithTerm.get(ipr.Id) == 2) {
                        transactionOrders.put(ipr.reduivy__Contact__c + '_' + ipr.reduivy__Academic_Term__c + '_Transaction Order', REDU_TestData_UTIL.newTransactionOrder(ipr.reduivy__Contact__c + '_' + ipr.reduivy__Academic_Term__c + '_Transaction Order', ipr.reduivy__Contact__c, ipr.Id, Date.newInstance(2024, 01, 01), TRO_Helper.getConfirmedStatuses().get(0), 2550, 1550, 1000));

                    } else if (academicProgressWithTerm.get(ipr.Id) == 3) {
                        transactionOrders.put(ipr.reduivy__Contact__c + '_' + ipr.reduivy__Academic_Term__c + '_Transaction Order', REDU_TestData_UTIL.newTransactionOrder(ipr.reduivy__Contact__c + '_' + ipr.reduivy__Academic_Term__c + '_Transaction Order', ipr.reduivy__Contact__c, ipr.Id, Date.newInstance(2024, 01, 01), TRO_Helper.getConfirmedStatuses().get(0), 1600, 600, 1000));

                    }

                } else if (ipr.reduivy__Contact__c == students.get('sandydoe@redu.example').Id || 
                    (FULLDATA && (ipr.reduivy__Contact__c == students.get('fionnadoe@redu.example').Id || ipr.reduivy__Contact__c == students.get('tommydoe@redu.example').Id))
                ) {
                    transactionOrders.put(ipr.reduivy__Contact__c + '_' + ipr.reduivy__Academic_Term__c + '_Transaction Order', REDU_TestData_UTIL.newTransactionOrder(ipr.reduivy__Contact__c + '_' + ipr.reduivy__Academic_Term__c + '_Transaction Order', ipr.reduivy__Contact__c, ipr.Id, Date.newInstance(2024, 01, 01), TRO_Helper.getConfirmedStatuses().get(0), 2600, 0, 2600));
                }
            }

            REDU_SystemMode_UTIL.doInsert(transactionOrders.values());

            if (validateCheckpoint(TRO_Helper.getApiName(), skipAfterObject)) {
                unmuteTriggers();
                unmuteRollup();
                return;
            }

            //Generate transaction order line fee (Currently all individual pathway with individual academic progress is in term 1, so we will only generate fee that applicable for term 1)
            for (reduivy__Transaction_Order__c tro : transactionOrders.values()) {
                if (academicProgressWithTerm.get(tro.reduivy__Individual_Academic_Progress__c) == 1){
                    if (tro.reduivy__Contact__c == students.get('johndoe@redu.example').Id ) {
                        transactionOrderLines.put(tro.reduivy__Sample_Record_Code__c + '_Tuition Fee (Normal Term)', REDU_TestData_UTIL.newTransactionOrderLine(tro.reduivy__Sample_Record_Code__c + '_Tuition Fee (Normal Term)', tro.Id, studyFeeMatrixItems.get('TUITION_FEE_NORMAL_TERM_FOR_INTERNATIONAL').Id, 'Tuition Fee (Normal Term)', TRL_Helper.ITEM_TYPE_TUITION, 2500, 2500, 0));
                        transactionOrderLines.put(tro.reduivy__Sample_Record_Code__c + '_Insurance Fee', REDU_TestData_UTIL.newTransactionOrderLine(tro.reduivy__Sample_Record_Code__c + '_Insurance Fee', tro.Id, studyFeeMatrixItems.get('INSURANCE_FEE_FOR_INTERNATIONAL').Id, 'Insurance Fee', TRL_Helper.ITEM_TYPE_MISCELLANEOUS, 50, 0, 50));
                        transactionOrderLines.put(tro.reduivy__Sample_Record_Code__c + '_Laboratory Fee', REDU_TestData_UTIL.newTransactionOrderLine(tro.reduivy__Sample_Record_Code__c + '_Laboratory Fee', tro.Id, studyFeeMatrixItems.get('LABORATORY_FEE_FOR_INTERNATIONAL').Id, 'Laboratory Fee', TRL_Helper.ITEM_TYPE_MISCELLANEOUS, 50, 0, 50));    
                    
                    } else if (tro.reduivy__Contact__c == students.get('amydoe@redu.example').Id) {
                        //offset amount will set to 0 to avoid hit into validation rules error when update discount field later
                        transactionOrderLines.put(tro.reduivy__Sample_Record_Code__c + '_Tuition Fee (Normal Term)', REDU_TestData_UTIL.newTransactionOrderLine(tro.reduivy__Sample_Record_Code__c + '_Tuition Fee (Normal Term)', tro.Id, studyFeeMatrixItems.get('TUITION_FEE_NORMAL_TERM_FOR_INTERNATIONAL').Id, 'Tuition Fee (Normal Term)', TRL_Helper.ITEM_TYPE_TUITION, 2500, 0, 1250));
                        transactionOrderLines.put(tro.reduivy__Sample_Record_Code__c + '_Insurance Fee', REDU_TestData_UTIL.newTransactionOrderLine(tro.reduivy__Sample_Record_Code__c + '_Insurance Fee', tro.Id, studyFeeMatrixItems.get('INSURANCE_FEE_FOR_INTERNATIONAL').Id, 'Insurance Fee', TRL_Helper.ITEM_TYPE_MISCELLANEOUS, 50, 0, 50));
                        transactionOrderLines.put(tro.reduivy__Sample_Record_Code__c + '_Laboratory Fee', REDU_TestData_UTIL.newTransactionOrderLine(tro.reduivy__Sample_Record_Code__c + '_Laboratory Fee', tro.Id, studyFeeMatrixItems.get('LABORATORY_FEE_FOR_INTERNATIONAL').Id, 'Laboratory Fee', TRL_Helper.ITEM_TYPE_MISCELLANEOUS, 50, 0, 50));    
                    
                    } else {
                        transactionOrderLines.put(tro.reduivy__Sample_Record_Code__c + '_Tuition Fee (Normal Term)', REDU_TestData_UTIL.newTransactionOrderLine(tro.reduivy__Sample_Record_Code__c + '_Tuition Fee (Normal Term)', tro.Id, studyFeeMatrixItems.get('TUITION_FEE_NORMAL_TERM_FOR_INTERNATIONAL').Id, 'Tuition Fee (Normal Term)', TRL_Helper.ITEM_TYPE_TUITION, 2500, 2500, 0));
                        transactionOrderLines.put(tro.reduivy__Sample_Record_Code__c + '_Insurance Fee', REDU_TestData_UTIL.newTransactionOrderLine(tro.reduivy__Sample_Record_Code__c + '_Insurance Fee', tro.Id, studyFeeMatrixItems.get('INSURANCE_FEE_FOR_INTERNATIONAL').Id, 'Insurance Fee', TRL_Helper.ITEM_TYPE_MISCELLANEOUS, 50, 50, 0));
                        transactionOrderLines.put(tro.reduivy__Sample_Record_Code__c + '_Laboratory Fee', REDU_TestData_UTIL.newTransactionOrderLine(tro.reduivy__Sample_Record_Code__c + '_Laboratory Fee', tro.Id, studyFeeMatrixItems.get('LABORATORY_FEE_FOR_INTERNATIONAL').Id, 'Laboratory Fee', TRL_Helper.ITEM_TYPE_MISCELLANEOUS, 50, 50, 0));    
                    }
                } else if (academicProgressWithTerm.get(tro.reduivy__Individual_Academic_Progress__c) == 2) {
                    if (tro.reduivy__Contact__c == students.get('johndoe@redu.example').Id ) {
                        transactionOrderLines.put(tro.reduivy__Sample_Record_Code__c + '_Tuition Fee (Normal Term)', REDU_TestData_UTIL.newTransactionOrderLine(tro.reduivy__Sample_Record_Code__c + '_Tuition Fee (Normal Term)', tro.Id, studyFeeMatrixItems.get('TUITION_FEE_NORMAL_TERM_FOR_INTERNATIONAL').Id, 'Tuition Fee (Normal Term)', TRL_Helper.ITEM_TYPE_TUITION, 2500, 2500, 0));
                        transactionOrderLines.put(tro.reduivy__Sample_Record_Code__c + '_Laboratory Fee', REDU_TestData_UTIL.newTransactionOrderLine(tro.reduivy__Sample_Record_Code__c + '_Laboratory Fee', tro.Id, studyFeeMatrixItems.get('LABORATORY_FEE_FOR_INTERNATIONAL').Id, 'Laboratory Fee', TRL_Helper.ITEM_TYPE_MISCELLANEOUS, 50, 0, 50));
                    
                    } else if (tro.reduivy__Contact__c == students.get('amydoe@redu.example').Id) {
                        transactionOrderLines.put(tro.reduivy__Sample_Record_Code__c + '_Tuition Fee (Normal Term)', REDU_TestData_UTIL.newTransactionOrderLine(tro.reduivy__Sample_Record_Code__c + '_Tuition Fee (Normal Term)', tro.Id, studyFeeMatrixItems.get('TUITION_FEE_NORMAL_TERM_FOR_INTERNATIONAL').Id, 'Tuition Fee (Normal Term)', TRL_Helper.ITEM_TYPE_TUITION, 2500, 1000, 1500));
                        transactionOrderLines.put(tro.reduivy__Sample_Record_Code__c + '_Laboratory Fee', REDU_TestData_UTIL.newTransactionOrderLine(tro.reduivy__Sample_Record_Code__c + '_Laboratory Fee', tro.Id, studyFeeMatrixItems.get('LABORATORY_FEE_FOR_INTERNATIONAL').Id, 'Laboratory Fee', TRL_Helper.ITEM_TYPE_MISCELLANEOUS, 50, 0, 50));
                    
                    } else {
                        transactionOrderLines.put(tro.reduivy__Sample_Record_Code__c + '_Tuition Fee (Normal Term)', REDU_TestData_UTIL.newTransactionOrderLine(tro.reduivy__Sample_Record_Code__c + '_Tuition Fee (Normal Term)', tro.Id, studyFeeMatrixItems.get('TUITION_FEE_NORMAL_TERM_FOR_INTERNATIONAL').Id, 'Tuition Fee (Normal Term)', TRL_Helper.ITEM_TYPE_TUITION, 2500, 2500, 0));
                        transactionOrderLines.put(tro.reduivy__Sample_Record_Code__c + '_Laboratory Fee', REDU_TestData_UTIL.newTransactionOrderLine(tro.reduivy__Sample_Record_Code__c + '_Laboratory Fee', tro.Id, studyFeeMatrixItems.get('LABORATORY_FEE_FOR_INTERNATIONAL').Id, 'Laboratory Fee', TRL_Helper.ITEM_TYPE_MISCELLANEOUS, 50, 50, 0));
                    }
                } else if (academicProgressWithTerm.get(tro.reduivy__Individual_Academic_Progress__c) == 3) {
                    if (tro.reduivy__Contact__c == students.get('johndoe@redu.example').Id ) {
                        transactionOrderLines.put(tro.reduivy__Sample_Record_Code__c + '_Tuition Fee (Short Term)', REDU_TestData_UTIL.newTransactionOrderLine(tro.reduivy__Sample_Record_Code__c + '_Tuition Fee (Short Term)', tro.Id, studyFeeMatrixItems.get('TUITION_FEE_SHORT_TERM_FOR_INTERNATIONAL').Id, 'Tuition Fee (Short Term)', TRL_Helper.ITEM_TYPE_TUITION, 1500, 1500, 0));
                        transactionOrderLines.put(tro.reduivy__Sample_Record_Code__c + '_Laboratory Fee', REDU_TestData_UTIL.newTransactionOrderLine(tro.reduivy__Sample_Record_Code__c + '_Laboratory Fee', tro.Id, studyFeeMatrixItems.get('LABORATORY_FEE_FOR_INTERNATIONAL').Id, 'Laboratory Fee', TRL_Helper.ITEM_TYPE_MISCELLANEOUS, 50, 0, 50));    
                        transactionOrderLines.put(tro.reduivy__Sample_Record_Code__c + '_Material Fee_ICT101', REDU_TestData_UTIL.newTransactionOrderLine(tro.reduivy__Sample_Record_Code__c + '__Material Fee_ICT101', tro.Id, studyFeeMatrixItems.get('MATERIAL_FEE_FOR_INTERNATIONAL').Id, 'Material Fee For ICT101', TRL_Helper.ITEM_TYPE_MISCELLANEOUS, 50,0, 50));

                    } else if (tro.reduivy__Contact__c == students.get('amydoe@redu.example').Id) {
                        transactionOrderLines.put(tro.reduivy__Sample_Record_Code__c + '_Tuition Fee (Short Term)', REDU_TestData_UTIL.newTransactionOrderLine(tro.reduivy__Sample_Record_Code__c + '_Tuition Fee (Short Term)', tro.Id, studyFeeMatrixItems.get('TUITION_FEE_SHORT_TERM_FOR_INTERNATIONAL').Id, 'Tuition Fee (Short Term)', TRL_Helper.ITEM_TYPE_TUITION, 1500, 1000, 500));
                        transactionOrderLines.put(tro.reduivy__Sample_Record_Code__c + '_Laboratory Fee', REDU_TestData_UTIL.newTransactionOrderLine(tro.reduivy__Sample_Record_Code__c + '_Laboratory Fee', tro.Id, studyFeeMatrixItems.get('LABORATORY_FEE_FOR_INTERNATIONAL').Id, 'Laboratory Fee', TRL_Helper.ITEM_TYPE_MISCELLANEOUS, 50, 0, 50));    
                        transactionOrderLines.put(tro.reduivy__Sample_Record_Code__c + '_Material Fee_ICT101', REDU_TestData_UTIL.newTransactionOrderLine(tro.reduivy__Sample_Record_Code__c + '__Material Fee_ICT101', tro.Id, studyFeeMatrixItems.get('MATERIAL_FEE_FOR_INTERNATIONAL').Id, 'Material Fee For ICT101', TRL_Helper.ITEM_TYPE_MISCELLANEOUS, 50, 0, 50));

                    } else {
                        transactionOrderLines.put(tro.reduivy__Sample_Record_Code__c + '_Tuition Fee (Short Term)', REDU_TestData_UTIL.newTransactionOrderLine(tro.reduivy__Sample_Record_Code__c + '_Tuition Fee (Short Term)', tro.Id, studyFeeMatrixItems.get('TUITION_FEE_SHORT_TERM_FOR_INTERNATIONAL').Id, 'Tuition Fee (Short Term)', TRL_Helper.ITEM_TYPE_TUITION, 1500, 1500, 0));
                        transactionOrderLines.put(tro.reduivy__Sample_Record_Code__c + '_Laboratory Fee', REDU_TestData_UTIL.newTransactionOrderLine(tro.reduivy__Sample_Record_Code__c + '_Laboratory Fee', tro.Id, studyFeeMatrixItems.get('LABORATORY_FEE_FOR_INTERNATIONAL').Id, 'Laboratory Fee', TRL_Helper.ITEM_TYPE_MISCELLANEOUS, 50, 50, 0));    
                    }
                }
            }

            REDU_SystemMode_UTIL.doInsert(transactionOrderLines.values());

            //Create study voucher transaction
            if (!studyVouchers.isEmpty()) {
                for (reduivy__Transaction_Order__c tro : transactionOrders.values()) {
                    if (tro.reduivy__Contact__c == students.get('amydoe@redu.example').Id && academicProgressWithTerm.get(tro.reduivy__Individual_Academic_Progress__c) == 1) {
                        studyVoucherTransaction.put(tro.reduivy__Sample_Record_Code__c + 'Study Voucher Transaction', REDU_TestData_UTIL.newStudyVoucherTransaction(tro.reduivy__Sample_Record_Code__c + 'Study Voucher Transaction', studyVouchers.get('TUITION_10%_DISCOUNT').Id, tro.Id, SVT_Helper.STATUS_CONFIRMED));
                    }
                }

                REDU_SystemMode_UTIL.doInsert(studyVoucherTransaction.values());
            }
            
            //Update discount field for the line item
            reduivy__Transaction_Line_Item__c trl = new reduivy__Transaction_Line_Item__c(
                Id = transactionOrderLines.get(students.get('amydoe@redu.example').Id + '_' + academicTerms.get('PYT1').Id + '_Transaction Order_Tuition Fee (Normal Term)').Id,
                reduivy__Discount__c = 250
            );

            REDU_SystemMode_UTIL.doUpdate(new List<reduivy__Transaction_Line_Item__c>{trl});

            if (validateCheckpoint(TRL_Helper.TRANSACTION_TYPE_ORDERLINE, skipAfterObject)) {
                unmuteTriggers();
                unmuteRollup();
                return;
            }
            
            //Discount amount updated, update offset amount
            reduivy__Transaction_Line_Item__c trlOffset = new reduivy__Transaction_Line_Item__c(
                Id = transactionOrderLines.get(students.get('amydoe@redu.example').Id + '_' + academicTerms.get('PYT1').Id + '_Transaction Order_Tuition Fee (Normal Term)').Id,
                reduivy__Offset_Amount__c = 1000,
                reduivy__Outstanding_Amount__c = 1250
            );

            REDU_SystemMode_UTIL.doUpdate(new List<reduivy__Transaction_Line_Item__c>{trlOffset});

            if (validateCheckpoint(TRL_Helper.TRANSACTION_TYPE_ORDERLINE, skipAfterObject)) {
                unmuteTriggers();
                unmuteRollup();
                return;
            }

            //Create Transaction Payment 
            for (reduivy__Transaction_Order__c tro : transactionOrders.values()) {
                if (tro.reduivy__Contact__c == students.get('sandydoe@redu.example').Id || 
                    (FULLDATA && (tro.reduivy__Contact__c == students.get('tommydoe@redu.example').Id || tro.reduivy__Contact__c == students.get('fionnadoe@redu.example').Id))
                ) { //For Fully Paid with normal payment
                    
                    transactionPayment.put(tro.reduivy__Sample_Record_Code__c + 'Transaction Payment(Payment)', REDU_TestData_UTIL.newTransactionPayment(tro.reduivy__Sample_Record_Code__c + 'Transaction Payment(Payment)', tro.reduivy__Contact__c, null, TRP_Helper.TRANSACTION_TYPE_PAYMENT, null, 2600, 2600, null));
                
                } else if (tro.reduivy__Contact__c == students.get('amydoe@redu.example').Id) { //For Partial Paid with study vouncher (For first term only) + study funding
                    
                    transactionPayment.put(tro.reduivy__Sample_Record_Code__c + 'Transaction Payment(Financial Aid Disbursement)', REDU_TestData_UTIL.newTransactionPayment(tro.reduivy__Sample_Record_Code__c + 'Transaction Payment(Financial Aid Disbursement)', tro.reduivy__Contact__c, null, TRP_Helper.TRANSACTION_TYPE_NON_REPAYABLE_FINANCIAL_AID_DISBURSEMENT, idvFundingAllocation.get('AmyDoe_RIO_University_Hardship_Award').Id, 1000, 1000, null));

                } else if (tro.reduivy__Contact__c == students.get('johndoe@redu.example').Id) { //For Partial Paid with normal payment with Applicable to Specific Types configured
                    
                    if(academicProgressWithTerm.get(tro.reduivy__Individual_Academic_Progress__c) == 3) {
                        transactionPayment.put(tro.reduivy__Sample_Record_Code__c + 'Transaction Payment(Payment)', REDU_TestData_UTIL.newTransactionPayment(tro.reduivy__Sample_Record_Code__c + 'Transaction Payment(Payment)', tro.reduivy__Contact__c, null, TRP_Helper.TRANSACTION_TYPE_PAYMENT, null, 1600, 1500, TRP_Helper.APPLICABLE_ITEM_TYPE_TUITION));
                    } else {
                        transactionPayment.put(tro.reduivy__Sample_Record_Code__c + 'Transaction Payment(Payment)', REDU_TestData_UTIL.newTransactionPayment(tro.reduivy__Sample_Record_Code__c + 'Transaction Payment(Payment)', tro.reduivy__Contact__c, null, TRP_Helper.TRANSACTION_TYPE_PAYMENT, null, 2600, 2500, TRP_Helper.APPLICABLE_ITEM_TYPE_TUITION));
                    }
                
                }
            }

            REDU_SystemMode_UTIL.doInsert(transactionPayment.values());

            if (validateCheckpoint(TRP_Helper.getApiName(), skipAfterObject)) {
                unmuteTriggers();
                unmuteRollup();
                return;
            }

            //Create transaction order line item for payment        
            for (reduivy__Transaction_Order__c tro : transactionOrders.values()) {
                if (tro.reduivy__Contact__c == students.get('sandydoe@redu.example').Id) {
                    transactionLineItemPaymentLine.put(tro.reduivy__Sample_Record_Code__c + 'Payment_Line_Tuition' + tro.reduivy__Contact__c, REDU_TestData_UTIL.newTransactionMonetaryEntry(tro.reduivy__Sample_Record_Code__c + 'Payment_Line_Tuition' + tro.reduivy__Contact__c, tro.Id, transactionPayment.get(tro.reduivy__Sample_Record_Code__c + 'Transaction Payment(Payment)').Id, transactionOrderLines.get(students.get('sandydoe@redu.example').Id + '_' + academicTerms.get('CYT1').Id + '_Transaction Order_Tuition Fee (Normal Term)').Id, null, 'Payment For Tuition Fee', TRL_Helper.ITEM_TYPE_TUITION, 2500, 2500, 0));
                    transactionLineItemPaymentLine.put(tro.reduivy__Sample_Record_Code__c + 'Payment_Line_Insurance' + tro.reduivy__Contact__c, REDU_TestData_UTIL.newTransactionMonetaryEntry(tro.reduivy__Sample_Record_Code__c + 'Payment_Line_Insurance' + tro.reduivy__Contact__c, tro.Id, transactionPayment.get(tro.reduivy__Sample_Record_Code__c + 'Transaction Payment(Payment)').Id, transactionOrderLines.get(students.get('sandydoe@redu.example').Id + '_' + academicTerms.get('CYT1').Id + '_Transaction Order_Insurance Fee').Id, null, 'Payment For Insurance Fee', TRL_Helper.ITEM_TYPE_MISCELLANEOUS, 50, 50, 0));
                    transactionLineItemPaymentLine.put(tro.reduivy__Sample_Record_Code__c + 'Payment_Line_Laboratory' + tro.reduivy__Contact__c, REDU_TestData_UTIL.newTransactionMonetaryEntry(tro.reduivy__Sample_Record_Code__c + 'Payment_Line_Laboratory' + tro.reduivy__Contact__c, tro.Id, transactionPayment.get(tro.reduivy__Sample_Record_Code__c + 'Transaction Payment(Payment)').Id, transactionOrderLines.get(students.get('sandydoe@redu.example').Id + '_' + academicTerms.get('CYT1').Id + '_Transaction Order_Laboratory Fee').Id, null, 'Payment For Laboratory Fee', TRL_Helper.ITEM_TYPE_MISCELLANEOUS, 50, 50, 0));
                
                } else if (FULLDATA && tro.reduivy__Contact__c == students.get('tommydoe@redu.example').Id) {
                    transactionLineItemPaymentLine.put(tro.reduivy__Sample_Record_Code__c + 'Payment_Line_Tuition' + tro.reduivy__Contact__c, REDU_TestData_UTIL.newTransactionMonetaryEntry(tro.reduivy__Sample_Record_Code__c + 'Payment_Line_Tuition' + tro.reduivy__Contact__c, tro.Id, transactionPayment.get(tro.reduivy__Sample_Record_Code__c + 'Transaction Payment(Payment)').Id, transactionOrderLines.get(students.get('tommydoe@redu.example').Id + '_' + academicTerms.get('CYT1').Id + '_Transaction Order_Tuition Fee (Normal Term)').Id, null, 'Payment For Tuition Fee', TRL_Helper.ITEM_TYPE_TUITION, 2500, 2500, 0));
                    transactionLineItemPaymentLine.put(tro.reduivy__Sample_Record_Code__c + 'Payment_Line_Insurance' + tro.reduivy__Contact__c, REDU_TestData_UTIL.newTransactionMonetaryEntry(tro.reduivy__Sample_Record_Code__c + 'Payment_Line_Insurance' + tro.reduivy__Contact__c, tro.Id, transactionPayment.get(tro.reduivy__Sample_Record_Code__c + 'Transaction Payment(Payment)').Id, transactionOrderLines.get(students.get('tommydoe@redu.example').Id + '_' + academicTerms.get('CYT1').Id + '_Transaction Order_Insurance Fee').Id, null, 'Payment For Insurance Fee', TRL_Helper.ITEM_TYPE_MISCELLANEOUS, 50, 50, 0));
                    transactionLineItemPaymentLine.put(tro.reduivy__Sample_Record_Code__c + 'Payment_Line_Laboratory' + tro.reduivy__Contact__c, REDU_TestData_UTIL.newTransactionMonetaryEntry(tro.reduivy__Sample_Record_Code__c + 'Payment_Line_Laboratory' + tro.reduivy__Contact__c, tro.Id, transactionPayment.get(tro.reduivy__Sample_Record_Code__c + 'Transaction Payment(Payment)').Id, transactionOrderLines.get(students.get('tommydoe@redu.example').Id + '_' + academicTerms.get('CYT1').Id + '_Transaction Order_Laboratory Fee').Id, null, 'Payment For Laboratory Fee', TRL_Helper.ITEM_TYPE_MISCELLANEOUS, 50, 50, 0));
                
                } else if (FULLDATA && tro.reduivy__Contact__c == students.get('fionnadoe@redu.example').Id) {
                    transactionLineItemPaymentLine.put(tro.reduivy__Sample_Record_Code__c + 'Payment_Line_Tuition' + tro.reduivy__Contact__c, REDU_TestData_UTIL.newTransactionMonetaryEntry(tro.reduivy__Sample_Record_Code__c + 'Payment_Line_Tuition' + tro.reduivy__Contact__c, tro.Id, transactionPayment.get(tro.reduivy__Sample_Record_Code__c + 'Transaction Payment(Payment)').Id, transactionOrderLines.get(students.get('fionnadoe@redu.example').Id + '_' + academicTerms.get('CYT1').Id + '_Transaction Order_Tuition Fee (Normal Term)').Id, null, 'Payment For Tuition Fee', TRL_Helper.ITEM_TYPE_TUITION, 2500, 2500, 0));
                    transactionLineItemPaymentLine.put(tro.reduivy__Sample_Record_Code__c + 'Payment_Line_Insurance' + tro.reduivy__Contact__c, REDU_TestData_UTIL.newTransactionMonetaryEntry(tro.reduivy__Sample_Record_Code__c + 'Payment_Line_Insurance' + tro.reduivy__Contact__c, tro.Id, transactionPayment.get(tro.reduivy__Sample_Record_Code__c + 'Transaction Payment(Payment)').Id, transactionOrderLines.get(students.get('fionnadoe@redu.example').Id + '_' + academicTerms.get('CYT1').Id + '_Transaction Order_Insurance Fee').Id, null, 'Payment For Insurance Fee', TRL_Helper.ITEM_TYPE_MISCELLANEOUS, 50, 50, 0));
                    transactionLineItemPaymentLine.put(tro.reduivy__Sample_Record_Code__c + 'Payment_Line_Laboratory' + tro.reduivy__Contact__c, REDU_TestData_UTIL.newTransactionMonetaryEntry(tro.reduivy__Sample_Record_Code__c + 'Payment_Line_Laboratory' + tro.reduivy__Contact__c, tro.Id, transactionPayment.get(tro.reduivy__Sample_Record_Code__c + 'Transaction Payment(Payment)').Id, transactionOrderLines.get(students.get('fionnadoe@redu.example').Id + '_' + academicTerms.get('CYT1').Id + '_Transaction Order_Laboratory Fee').Id, null, 'Payment For Laboratory Fee', TRL_Helper.ITEM_TYPE_MISCELLANEOUS, 50, 50, 0));
                
                } else if (tro.reduivy__Contact__c == students.get('amydoe@redu.example').Id) {
                    //To get the transaction order lines id to populate the offset field
                    if(academicProgressWithTerm.get(tro.reduivy__Individual_Academic_Progress__c) == 1) {
                        
                        transactionLineItemPaymentLine.put(tro.reduivy__Sample_Record_Code__c + 'Payment _Line_Financial_Aid_Disbursement', REDU_TestData_UTIL.newTransactionMonetaryEntry(tro.reduivy__Sample_Record_Code__c + 'Payment_Line_FinancialAid', tro.Id, transactionPayment.get(tro.reduivy__Sample_Record_Code__c + 'Transaction Payment(Financial Aid Disbursement)').Id, transactionOrderLines.get(students.get('amydoe@redu.example').Id + '_' + academicTerms.get('PYT1').Id + '_Transaction Order_Tuition Fee (Normal Term)').Id, idvFundingAllocation.get('AmyDoe_RIO_University_Hardship_Award').Id, 'AmyDoe_RIO_University_Hardship_Award', TRL_Helper.ITEM_TYPE_TUITION, 1000, 1000, 0));
                    
                    } else if (academicProgressWithTerm.get(tro.reduivy__Individual_Academic_Progress__c) == 2) {
                        
                        transactionLineItemPaymentLine.put(tro.reduivy__Sample_Record_Code__c + 'Payment _Line_Financial_Aid_Disbursement', REDU_TestData_UTIL.newTransactionMonetaryEntry(tro.reduivy__Sample_Record_Code__c + 'Payment_Line_FinancialAid', tro.Id, transactionPayment.get(tro.reduivy__Sample_Record_Code__c + 'Transaction Payment(Financial Aid Disbursement)').Id, transactionOrderLines.get(students.get('amydoe@redu.example').Id + '_' + academicTerms.get('PYT2').Id + '_Transaction Order_Tuition Fee (Normal Term)').Id, idvFundingAllocation.get('AmyDoe_RIO_University_Hardship_Award').Id, 'AmyDoe_RIO_University_Hardship_Award', TRL_Helper.ITEM_TYPE_TUITION, 1000, 1000, 0));
                    
                    } else if (academicProgressWithTerm.get(tro.reduivy__Individual_Academic_Progress__c) == 3) {
                        
                        transactionLineItemPaymentLine.put(tro.reduivy__Sample_Record_Code__c + 'Payment _Line_Financial_Aid_Disbursement', REDU_TestData_UTIL.newTransactionMonetaryEntry(tro.reduivy__Sample_Record_Code__c + 'Payment_Line_FinancialAid', tro.Id, transactionPayment.get(tro.reduivy__Sample_Record_Code__c + 'Transaction Payment(Financial Aid Disbursement)').Id, transactionOrderLines.get(students.get('amydoe@redu.example').Id + '_' + academicTerms.get('CYT1').Id + '_Transaction Order_Tuition Fee (Short Term)').Id, idvFundingAllocation.get('AmyDoe_RIO_University_Hardship_Award').Id, 'AmyDoe_RIO_University_Hardship_Award', TRL_Helper.ITEM_TYPE_TUITION, 1000, 1000, 0));
                    }
                } else if (tro.reduivy__Contact__c == students.get('johndoe@redu.example').Id) {
                    //To get the transaction order lines id to populate the offset field
                    if(academicProgressWithTerm.get(tro.reduivy__Individual_Academic_Progress__c) == 1) {
                        
                        transactionLineItemPaymentLine.put(tro.reduivy__Sample_Record_Code__c + 'Payment_Line_Tuition' + tro.reduivy__Contact__c, REDU_TestData_UTIL.newTransactionMonetaryEntry(tro.reduivy__Sample_Record_Code__c + 'Payment_Line_Tuition' + tro.reduivy__Contact__c, tro.Id, transactionPayment.get(tro.reduivy__Sample_Record_Code__c + 'Transaction Payment(Payment)').Id, transactionOrderLines.get(students.get('johndoe@redu.example').Id + '_' + academicTerms.get('PYT1').Id + '_Transaction Order_Tuition Fee (Normal Term)').Id, null, 'Payment For Tuition Fee', TRL_Helper.ITEM_TYPE_TUITION, 2500, 2500, 0));

                    } else if (academicProgressWithTerm.get(tro.reduivy__Individual_Academic_Progress__c) == 2) {
                        
                        transactionLineItemPaymentLine.put(tro.reduivy__Sample_Record_Code__c + 'Payment_Line_Tuition' + tro.reduivy__Contact__c, REDU_TestData_UTIL.newTransactionMonetaryEntry(tro.reduivy__Sample_Record_Code__c + 'Payment_Line_Tuition' + tro.reduivy__Contact__c, tro.Id, transactionPayment.get(tro.reduivy__Sample_Record_Code__c + 'Transaction Payment(Payment)').Id, transactionOrderLines.get(students.get('johndoe@redu.example').Id + '_' + academicTerms.get('PYT2').Id + '_Transaction Order_Tuition Fee (Normal Term)').Id, null, 'Payment For Tuition Fee', TRL_Helper.ITEM_TYPE_TUITION, 2500, 2500, 0));

                    } else if (academicProgressWithTerm.get(tro.reduivy__Individual_Academic_Progress__c) == 3) {
                        
                        transactionLineItemPaymentLine.put(tro.reduivy__Sample_Record_Code__c + 'Payment_Line_Tuition' + tro.reduivy__Contact__c, REDU_TestData_UTIL.newTransactionMonetaryEntry(tro.reduivy__Sample_Record_Code__c + 'Payment_Line_Tuition' + tro.reduivy__Contact__c, tro.Id, transactionPayment.get(tro.reduivy__Sample_Record_Code__c + 'Transaction Payment(Payment)').Id, transactionOrderLines.get(students.get('johndoe@redu.example').Id + '_' + academicTerms.get('CYT1').Id + '_Transaction Order_Tuition Fee (Short Term)').Id, null, 'Payment For Tuition Fee', TRL_Helper.ITEM_TYPE_TUITION, 1500, 1500, 0));

                    }
                }
            }

            REDU_SystemMode_UTIL.doInsert(transactionLineItemPaymentLine.values());

            unmuteRollup();
            unmuteTriggers();
        }
    }

    /**
     * @description Deactivate community users
     */
    public void deactivateCommunityUsers() {
        muteTriggers();

        List<Contact> contacts = new List<Contact>();
        for (Contact contact : [SELECT Id 
            FROM Contact 
            WHERE reduivy__Sample_Record_Code__c != null
            WITH SYSTEM_MODE
        ]) {
            contacts.add(contact);
        }

        List<User> communityUsers = [SELECT IsActive, IsPortalEnabled FROM User WHERE ContactId in :contacts WITH SYSTEM_MODE];
        for (User user : communityUsers) {
            user.IsActive = false;
            user.isPortalEnabled = false;
        }

        REDU_SystemMode_UTIL.doUpdate(communityUsers);

        unmuteTriggers();
        
    }

    /**
     * @description Delete sample data
     */
    global void deleteSampleData() {
        
        muteTriggers();

        List<reduivy__Individual_Program_Enrollment__c> idvProgramEnrollments = [SELECT Id FROM reduivy__Individual_Program_Enrollment__c WHERE reduivy__Sample_Record_Code__c != null WITH SYSTEM_MODE];
        List<reduivy__Individual_Plan_Structure__c> idvPlanStructures = [SELECT Id FROM reduivy__Individual_Plan_Structure__c WHERE reduivy__Individual_Program_Enrollment__c IN: idvProgramEnrollments WITH SYSTEM_MODE];
        List<reduivy__Individual_Plan_Unit_Requirement__c> idvPlanUnitReq = [SELECT Id FROM reduivy__Individual_Plan_Unit_Requirement__c WHERE 	reduivy__Individual_Plan_Unit__c IN:idvPlanStructures WITH SYSTEM_MODE];
        List<reduivy__Individual_Pathway__c> idvPathway = [SELECT Id FROM reduivy__Individual_Pathway__c WHERE reduivy__Individual_Program_Enrollment__c IN: idvProgramEnrollments WITH SYSTEM_MODE];

        REDU_SystemMode_UTIL.doDelete(idvPlanUnitReq);
        REDU_SystemMode_UTIL.doDelete(idvPlanStructures);
        REDU_SystemMode_UTIL.doDelete(idvPathway);
        REDU_SystemMode_UTIL.doDelete(idvProgramEnrollments);
        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Individual_Enrollment__c WHERE reduivy__Sample_Record_Code__c != null WITH SYSTEM_MODE]);
        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Individual_Achievement__c WHERE reduivy__Sample_Record_Code__c != null WITH SYSTEM_MODE]);

        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Credit_Transfer_Application__c WHERE reduivy__Sample_Record_Code__c != null WITH SYSTEM_MODE]);
        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Agreement_Unit_Equivalent__c WHERE reduivy__Sample_Record_Code__c != null WITH SYSTEM_MODE]);
        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Agreement__c WHERE reduivy__Sample_Record_Code__c != null WITH SYSTEM_MODE]);

        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Study_Cohort_Enrollment__c WHERE reduivy__Sample_Record_Code__c != null WITH SYSTEM_MODE]);
        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Study_Offering__c WHERE reduivy__Sample_Record_Code__c != null WITH SYSTEM_MODE]);
        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Study_Intake__c WHERE reduivy__Sample_Record_Code__c != null WITH SYSTEM_MODE]);
        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Study_Term__c WHERE reduivy__Sample_Record_Code__c != null WITH SYSTEM_MODE]);

        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Study_Fee_Matrix_Item__c WHERE reduivy__Sample_Record_Code__c != null WITH SYSTEM_MODE]);
        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Study_Fee_Matrix__c WHERE reduivy__Sample_Record_Code__c != null WITH SYSTEM_MODE]);
        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Study_Fee_Config__c WHERE reduivy__Sample_Record_Code__c != null WITH SYSTEM_MODE]);

        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Study_Grade_Setting__c WHERE reduivy__Sample_Record_Code__c != null WITH SYSTEM_MODE]);
        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Study_Pathway_Unit__c WHERE reduivy__Sample_Record_Code__c != null WITH SYSTEM_MODE]);
        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Study_Pathway_Term__c WHERE reduivy__Sample_Record_Code__c != null WITH SYSTEM_MODE]);
        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Study_Pathway__c WHERE reduivy__Sample_Record_Code__c != null WITH SYSTEM_MODE]);
        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Study_Plan_Option__c WHERE reduivy__Sample_Record_Code__c != null WITH SYSTEM_MODE]);
        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Study_Plan_Unit_Requirement__c WHERE reduivy__Sample_Record_Code__c != null WITH SYSTEM_MODE]);
        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Study_Plan_Structure__c WHERE reduivy__Sample_Record_Code__c != null WITH SYSTEM_MODE]);
        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Study_Plan__c WHERE reduivy__Sample_Record_Code__c != null WITH SYSTEM_MODE]);

        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Facility_Availability__c  WHERE reduivy__Sample_Record_Code__c != null WITH SYSTEM_MODE]);
        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Qualified_Faculty__c  WHERE reduivy__Sample_Record_Code__c != null WITH SYSTEM_MODE]);

        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Study_Program__c WHERE reduivy__Sample_Record_Code__c != null WITH SYSTEM_MODE]);
        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Study_Unit_Requirement__c WHERE reduivy__Sample_Record_Code__c != null WITH SYSTEM_MODE]);
        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Study_Unit__c WHERE reduivy__Sample_Record_Code__c != null WITH SYSTEM_MODE]);
        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Facility__c WHERE reduivy__Sample_Record_Code__c != null WITH SYSTEM_MODE]);
        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Log__c WHERE reduivy__Sample_Record_Code__c != null WITH SYSTEM_MODE]);

        List<reduivy__Study_Event__c> studyEvents = [SELECT Id FROM reduivy__Study_Event__c WHERE reduivy__Sample_Record_Code__c != null WITH SYSTEM_MODE];

        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Study_Event_Relation__c WHERE reduivy__Study_Event__c IN: studyEvents WITH SYSTEM_MODE]);
        REDU_SystemMode_UTIL.doDelete(studyEvents);
        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Individual_Session_Enrollment__c WHERE reduivy__Sample_Record_Code__c != null WITH SYSTEM_MODE]);
        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Study_Session_Time__c WHERE reduivy__Sample_Record_Code__c != null WITH SYSTEM_MODE]);
        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Study_Session__c WHERE reduivy__Sample_Record_Code__c != null WITH SYSTEM_MODE]);
        
        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Individual_Grade_Item__c WHERE reduivy__Sample_Record_Code__c != null WITH SYSTEM_MODE]);
        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Individual_Enrollment_Grade__c WHERE reduivy__Sample_Record_Code__c != null WITH SYSTEM_MODE]);
        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Study_Grade_Item__c WHERE reduivy__Sample_Record_Code__c != null WITH SYSTEM_MODE]);
        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Study_Grade_Period_Setting__c WHERE reduivy__Sample_Record_Code__c != null WITH SYSTEM_MODE]);

        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Contact_Availability__c WHERE reduivy__Sample_Record_Code__c != null WITH SYSTEM_MODE]);
        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Contact_Association__c WHERE reduivy__Sample_Record_Code__c != null WITH SYSTEM_MODE]);

        List<reduivy__Study_Voucher__c> studyVouchers = [SELECT Id FROM reduivy__Study_Voucher__c WHERE reduivy__Sample_Record_Code__c != null WITH SYSTEM_MODE];

        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Study_Voucher_Transaction__c WHERE reduivy__Study_Voucher__c IN: studyVouchers WITH SYSTEM_MODE]);
        REDU_SystemMode_UTIL.doDelete(studyVouchers);
        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Holiday__c  WHERE reduivy__Sample_Record_Code__c != null WITH SYSTEM_MODE]);
        
        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Individual_Funding_Allocation__c  WHERE reduivy__Sample_Record_Code__c != null WITH SYSTEM_MODE]);
        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Study_Funding__c  WHERE reduivy__Sample_Record_Code__c != null WITH SYSTEM_MODE]);

        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Study_Fee__c  WHERE reduivy__Sample_Record_Code__c != null WITH SYSTEM_MODE]);

        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Individual_Achievement__c  WHERE reduivy__Sample_Record_Code__c != null WITH SYSTEM_MODE]);

        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Agreement_Unit_Equivalent__c  WHERE reduivy__Sample_Record_Code__c != null WITH SYSTEM_MODE]);
        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Agreement__c  WHERE reduivy__Sample_Record_Code__c != null WITH SYSTEM_MODE]);

        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM Contact WHERE reduivy__Sample_Record_Code__c != null WITH SYSTEM_MODE]);
        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM Account WHERE reduivy__Sample_Record_Code__c != null WITH SYSTEM_MODE]);

        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Transaction_Payment__c WHERE reduivy__Sample_Record_Code__c != null WITH SYSTEM_MODE]);
        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Transaction_Line_Item__c WHERE reduivy__Sample_Record_Code__c != null WITH SYSTEM_MODE]);
        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Transaction_Order__c WHERE reduivy__Sample_Record_Code__c != null WITH SYSTEM_MODE]);

        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Sample_Record_Code__c != null WITH SYSTEM_MODE]);
        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Individual_Academic_Progress__c WHERE reduivy__Sample_Record_Code__c != null WITH SYSTEM_MODE]);

        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Announcement__c WHERE reduivy__Sample_Record_Code__c != null WITH SYSTEM_MODE]);
        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Log__c WHERE reduivy__Sample_Record_Code__c != null WITH SYSTEM_MODE]);

        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Individual_Program_Application__c WHERE reduivy__Sample_Record_Code__c != null WITH SYSTEM_MODE]);
        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Study_Requirement_Set__c WHERE reduivy__Sample_Record_Code__c != null WITH SYSTEM_MODE]);
        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Study_Requirement__c WHERE reduivy__Sample_Record_Code__c != null WITH SYSTEM_MODE]);
        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Individual_Requirement_Set__c WHERE reduivy__Sample_Record_Code__c != null WITH SYSTEM_MODE]);
        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Individual_Requirement__c WHERE reduivy__Sample_Record_Code__c != null WITH SYSTEM_MODE]);

        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__System_Variable__c WHERE reduivy__Sample_Record_Code__c != null WITH SYSTEM_MODE]);
        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Study_Scoring_Config__c WHERE reduivy__Sample_Record_Code__c != null WITH SYSTEM_MODE]);
        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Study_Scoring_Criteria__c WHERE reduivy__Sample_Record_Code__c != null WITH SYSTEM_MODE]);
        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Individual_Score__c WHERE reduivy__Sample_Record_Code__c != null WITH SYSTEM_MODE]);
        REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Individual_Score_Detail__c WHERE reduivy__Sample_Record_Code__c != null WITH SYSTEM_MODE]);

        unmuteTriggers();
    }

    /**
     * @description Mute all triggers
     */
    public void muteTriggers() {
        REDU_TriggerController.muteAllTriggers();
    }

    /**
     * @description Unmute all triggers
     */
    public void unmuteTriggers() {
        REDU_TriggerController.unmuteAllTriggers();
    }

    /**
     * @description Mute rollup
     */
    public void muteRollup() {
        REDU_CustomRollupController.muteAllRollups();
    }

    /**
     * @description Unmute rollup
     */
    public void unmuteRollup() {
        REDU_CustomRollupController.unmuteAllRollups();
    }
    
    /**
     * @description Assign Permission Set Assignment
     * @param userIds List of user id
     * @param permissionSetIds List of permission set id
     */
    public void assignPermissionSet(List<Id> userIds, List<Id> permissionSetIds) {

        createPermissionSetAssignment(userIds, permissionSetIds);
    }

    /**
     * @description Assign Permission Set Assignment in async mode
     * @param userIds List of user id
     * @param permissionSetIds List of permission set id
     */
    @future
    public static void assignPermissionSetFuture(List<Id> userIds, List<Id> permissionSetIds) {

        createPermissionSetAssignment(userIds, permissionSetIds);
    }

    /**
     * @description Insert permission set assignment
     * @param userIds List of user id
     * @param permissionSetIds List of permission set id
     */
    public static void createPermissionSetAssignment(List<Id> userIds, List<Id> permissionSetIds) {

        List<PermissionSetAssignment> psaList = new List<PermissionSetAssignment>();

        for (Id usrId : userIds) {
            psaList.addAll(REDU_TestData_UTIL.newPermissionSetAssignment(usrId, permissionSetIds));
        }

        REDU_SystemMode_UTIL.doInsert(psaList);
    }

    /**
     * @description Sample account for trigger controller test
     * @return List<Account>
     */
    public List<Account> initSampleAccount(Integer num) {
        List<Account> accounts = new List<Account>();
        for (Integer i = 1; i <= num; i ++) {
            Account acc = REDU_TestData_UTIL.newEducationalInstitution(null, 'Sample Test', 'Sample_' + i);
            accounts.add(acc);
        }

        return accounts;
    }

    /**
     * @description Data controller checkpoint
     * @param skipAfterObject
     * @return void
     */
    public Boolean validateCheckpoint(String currentObject, String skipAfterObject) {

        if (String.isNotBlank(skipAfterObject)) {
            if (currentObject.equalsIgnoreCase(skipAfterObject)) {
                return true;
            }
        }

        return false;
    }

    /**
     * @description Sample record creation for object triggers that haven't got any automation built yet, we need to cover the class test coverage
     * @return void
     */
    public void testSampleRecordCreation() {

        reduivy__Individual_Achievement__c idvAchiement = new reduivy__Individual_Achievement__c(Name = 'Individual Achievement');
        REDU_SystemMode_UTIL.doInsert(new List<reduivy__Individual_Achievement__c>{idvAchiement});
        
        reduivy__Study_Voucher__c studyVoucher = new reduivy__Study_Voucher__c(Name = 'Study Voucher');
        REDU_SystemMode_UTIL.doInsert(new List<reduivy__Study_Voucher__c>{studyVoucher});

        reduivy__Study_Voucher_Transaction__c studyVoucherTransaction = new reduivy__Study_Voucher_Transaction__c(reduivy__Study_Voucher__c = studyVoucher.Id);
        REDU_SystemMode_UTIL.doInsert(new List<reduivy__Study_Voucher_Transaction__c>{studyVoucherTransaction}); 
    }
}