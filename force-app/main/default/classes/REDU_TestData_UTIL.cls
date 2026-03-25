/**
 * @author      WDCi (Lean)
 * @date        March 2023
 * @group       Test
 * @description Test data factory with the @isTest annotation. This can also be used to generate sample data for manual testing/demo.
 * @changehistory
 * ISS-001591 30-03-2023 Lean - new class
 * ISS-001992 29/7/2024 XiRouh - added new object (Contact Availability, Qualified Faculty, Contact Association, Study Voucher, Holiday, Facility Availability, and other Study Fee management objects)
 * ISS-002155 31-12-2024 XW - added newCustomStudyUnitRequirement
 * ISS-002743 15-12-2025 XiRouh - Updated newStudentIndividualEnrollment to include the new parameter idvAcademicProfileId
 */
@NamespaceAccessible
public inherited sharing class REDU_TestData_UTIL {
    
    /**
     * @description Init new user record
     * @param firstName
     * @param lastName
     * @param contactId require for community license user
     * @param profileName
     * @return User
     */
    @NamespaceAccessible
    public static User newUser(String firstName, String lastName, String profileName){
        // Create an Admin User to update the Crud/Fls permissions for testing:
        
        Profile userProfile = [SELECT Id FROM Profile 
            WHERE Name =: profileName 
            WITH SYSTEM_MODE
            LIMIT 1
        ];
        
        return newUser(firstName, lastName, null, userProfile.Id, (firstName + '.' + lastName + '@redu.example').deleteWhitespace());
    }

    /**
     * @description Init new user record
     * @param firstName
     * @param lastName
     * @param contactId require for community license user
     * @param profileId
     * @return User
     */
    @NamespaceAccessible
    public static User newUser(String firstName, String lastName, Id contactId, Id profileId, String email){

        String emailAddress = email;

        User testUser = new User();
        testUser.FirstName = firstName;
        testUser.Lastname = lastName;
        testUser.Username = generateRandomString(5) + emailAddress;
        testUser.Email = emailAddress;
        testUser.ProfileId = profileId;
        testUser.TimeZoneSidKey = UserInfo.getTimeZone().getID();
        testUser.LocaleSidKey = 'en_AU';
        testUser.EmailEncodingKey = 'UTF-8';
        testUser.LanguageLocaleKey = 'en_US';
        testUser.Alias = testUser.Firstname.deleteWhitespace().left(2) + 
                    testUser.Lastname.deleteWhitespace().right(2) + 
                    testUser.Firstname.right(1);
        testUser.CommunityNickname = testUser.Username.substringBefore('@').left(40);
        testUser.isActive = true;

        if (String.isNotBlank(contactId)) {
            testUser.ContactId = contactId;
        }

        return testUser;
    }

    /**
     * @description Init new permission set assignment based on permission set name
     * @param assigneeId
     * @param permissionSetNames
     * @return List<PermissionSetAssignment>
     */
    @NamespaceAccessible
    public static List<PermissionSetAssignment> newPermissionSetAssignment(Id assigneeId, Set<String> permissionSetNames) {
        
        List<PermissionSetAssignment> psaList = new List<PermissionSetAssignment>();
        for (PermissionSet ps : [SELECT Id 
            FROM PermissionSet
            WHERE Name IN: permissionSetNames
            WITH SYSTEM_MODE
        ]) {
            PermissionSetAssignment psa = new PermissionSetAssignment(
                AssigneeId = assigneeId,
                PermissionSetId = ps.Id
            );

            psaList.add(psa);
        }

        return psaList;
    }

    /**
     * @description Init new permission set assignment based on permission set id
     * @param assigneeId
     * @param permissionSetIds
     * @return List<PermissionSetAssignment>
     */
    @NamespaceAccessible
    public static List<PermissionSetAssignment> newPermissionSetAssignment(Id assigneeId, List<Id> permissionSetIds) {
        
        List<PermissionSetAssignment> psaList = new List<PermissionSetAssignment>();
        for (Id permSetId : permissionSetIds) {
            PermissionSetAssignment psa = new PermissionSetAssignment(
                AssigneeId = assigneeId,
                PermissionSetId = permSetId
            );

            psaList.add(psa);
        }

        return psaList;
    }

    /**
     * @description Generate random string
     * @return String
     */
    @NamespaceAccessible
    public static String generateRandomString(Integer len) {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        String randStr = '';

        while (randStr.length() < len) {
           Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
           randStr += chars.substring(idx, idx+1);
        }

        return randStr; 
    }

    /**
     * @description Init a new educational institution
     * @param sampleRecordCode
     * @param name
     * @return Account
     */
    @NamespaceAccessible
    public static Account newEducationalInstitution(String sampleRecordCode, String name, String code) {

        Account acc = new Account(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            RecordTypeId = ACC_Helper.getEducationalInstitutionRecordTypeId(),    
            Name = name,
            reduivy__Code__c = code,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return acc;
    }

    /**
     * @description Init a new department
     * @param sampleRecordCode
     * @param educationalInstitutionId
     * @param name
     * @return Account
     */
    @NamespaceAccessible
    public static Account newDepartment(String sampleRecordCode, Id educationalInstitutionId, String name, String code) {

        Account acc = new Account(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            RecordTypeId = ACC_Helper.getDepartmentRecordTypeId(),
            ParentId = educationalInstitutionId,
            Name = name,
            reduivy__Code__c = code,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return acc;
    }

    /**
     * @description Init a new campus
     * @param sampleRecordCode
     * @param educationalInstitutionId
     * @param name
     * @return Account
     */
    @NamespaceAccessible
    public static Account newCampus(String sampleRecordCode, Id educationalInstitutionId, String name, String code, String timezone) {

        Account acc = new Account(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            RecordTypeId = ACC_Helper.getCampusRecordTypeId(),
            ParentId = educationalInstitutionId,
            Name = name,
            reduivy__Timezone__c = timezone,
            reduivy__Code__c = code,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return acc;
    }

    /**
     * @description Init a study voucher
     * @param sampleRecordCode
     * @param name
     * @param code
     * @param vouncherType
     * @param voucherValue
     * @param educationalInstitutionId
     * @param status
     * @param validFrom
     * @param validUntil
     * @param sequence
     * @param applicableItemTypes
     * @return reduivy__Study_Voucher__c
     */
    @NamespaceAccessible
    public static reduivy__Study_Voucher__c newStudyVoucher(String sampleRecordCode, String name, String code, String vouncherType, Integer voucherValue, Id educationalInstitutionId, String status, Date validFrom, Date validUntil, Integer sequence, String applicableItemTypes, Integer usageLimit) {

        reduivy__Study_Voucher__c studyVoucher = new reduivy__Study_Voucher__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            Name = name,
            reduivy__Code__c = code,
            reduivy__Voucher_Type__c = vouncherType,
            reduivy__Voucher_Value__c = voucherValue,
            reduivy__Account__c = educationalInstitutionId,
            reduivy__Status__c = status,
            reduivy__Valid_From__c = validFrom,
            reduivy__Valid_Until__c = validUntil,
            reduivy__Sequence__c = sequence,
            reduivy__Applicable_Item_Type__c = applicableItemTypes,
            reduivy__Usage_Limit__c = usageLimit,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return studyVoucher;
    }

    /**
     * @description Init a study voucher transaction
     * @param sampleRecordCode
     * @param name
     * @param code
     * @param vouncherType
     * @return reduivy__Study_Voucher_Transaction__c
     */
    @NamespaceAccessible
    public static reduivy__Study_Voucher_Transaction__c newStudyVoucherTransaction(String sampleRecordCode, Id studyVoucherId, Id transactionOrderId, String status) {

        reduivy__Study_Voucher_Transaction__c studyVoucherTransaction = new reduivy__Study_Voucher_Transaction__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            reduivy__Study_Voucher__c = studyVoucherId,
            reduivy__Transaction_Order__c = transactionOrderId,
            reduivy__Status__c = status,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return studyVoucherTransaction;
    }

    /**
     * @description Init a study fee
     * @param sampleRecordCode
     * @param name
     * @param educationalInstitutionId
     * @param itemType
     * @param refundable
     * @return reduivy__Study_Fee__c
     */
    @NamespaceAccessible
    public static reduivy__Study_Fee__c newStudyFee(String sampleRecordCode, String name, Id educationalInstitutionId, String itemType, Boolean refundable) {

        reduivy__Study_Fee__c studyFee = new reduivy__Study_Fee__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            Name = name,
            reduivy__Educational_Institution__c = educationalInstitutionId,
            reduivy__Item_Type__c = itemType,
            reduivy__Refundable__c = refundable,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return studyFee;
    }

    /**
     * @description Init a study fee config
     * @param sampleRecordCode
     * @param name
     * @param educationalInstitutionId
     * @param type
     * @param status
     * @return reduivy__Study_Fee_Config__c
     */
    @NamespaceAccessible
    public static reduivy__Study_Fee_Config__c newStudyFeeConfig(String sampleRecordCode, String name, Id educationalInstitutionId, String type, String status) {

        reduivy__Study_Fee_Config__c studyFeeConfig = new reduivy__Study_Fee_Config__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            Name = name,
            reduivy__Educational_Institution__c = educationalInstitutionId,
            reduivy__Type__c = type,
            reduivy__Status__c = status,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return studyFeeConfig;
    }

    /**
     * @description Init a study fee matrix
     * @param sampleRecordCode
     * @param name
     * @param studyFeeConfigId
     * @param applicableStudentFeeTypes
     * @param fromDate
     * @param toDate
     * @param status
     * @return reduivy__Study_Fee_Matrix__c
     */
    @NamespaceAccessible
    public static reduivy__Study_Fee_Matrix__c newStudyFeeMatrix(String sampleRecordCode, String name, Id studyFeeConfigId, String applicableStudentFeeTypes, Date fromDate, Date toDate, String status) {

        reduivy__Study_Fee_Matrix__c studyFeeMatrix = new reduivy__Study_Fee_Matrix__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            Name = name,
            reduivy__Study_Fee_Config__c = studyFeeConfigId,
            reduivy__Applicable_Student_Fee_Types__c = applicableStudentFeeTypes,
            reduivy__From_Date__c = fromDate,
            reduivy__To_Date__c = toDate,
            reduivy__Status__c = status,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return studyFeeMatrix;
    }

    /**
     * @description Init a study fee matrix item
     * @param sampleRecordCode
     * @param studyFeeMatrixId
     * @param studyFeeId
     * @param type
     * @param amount
     * @param applicableforAttemptNumber
     * @param applicableForStudyUnit
     * @param applicableForTerm
     * @return reduivy__Study_Fee_Matrix_Item__c
     */
    @NamespaceAccessible
    public static reduivy__Study_Fee_Matrix_Item__c newStudyFeeMatrixItem(String sampleRecordCode, Id studyFeeMatrixId, Id studyFeeId, String type, Integer amount, String applicableforAttemptNumber, Id applicableForStudyUnit, String applicableForTerm) {

        reduivy__Study_Fee_Matrix_Item__c studyFeeMatrixItem = new reduivy__Study_Fee_Matrix_Item__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            reduivy__Study_Fee_Matrix__c = studyFeeMatrixId,
            reduivy__Study_Fee__c = studyFeeId,
            reduivy__Type__c = type,
            reduivy__Amount__c = amount,
            reduivy__Applicable_for_Attempt_Number__c = applicableforAttemptNumber,
            reduivy__Applicable_For_Study_Unit__c = applicableForStudyUnit,
            reduivy__Applicable_For_Term__c = applicableForTerm,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return studyFeeMatrixItem;
    }

    /**
     * @description Init a new external educational institution
     * @param sampleRecordCode
     * @param name
     * @return Account
     */
    @NamespaceAccessible
    public static Account newExternalEducationalInstitution(String sampleRecordCode, String name, String code) {

        Account acc = new Account(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            RecordTypeId = ACC_Helper.getExternalEducationalInstitutionRecordTypeId(),
            Name = name,
            reduivy__Code__c = code,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return acc;
    }

    /**
     * @description Init a new organization
     * @param sampleRecordCode
     * @param name
     * @return Account
     */
    @NamespaceAccessible
    public static Account newOrganization(String sampleRecordCode, String name) {

        Account acc = new Account(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            RecordTypeId = ACC_Helper.getOrganizationRecordTypeId(),
            Name = name,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return acc;
    }

    /**
     * @description Init a new administrative account
     * @param sampleRecordCode
     * @param name
     * @return Account
     */
    @NamespaceAccessible
    public static Account newAdministrativeAccount(String sampleRecordCode, String name) {

        Account acc = new Account(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            RecordTypeId = ACC_Helper.getAdministrativeRecordTypeId(),
            Name = name,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return acc;
    }

    /**
     * @description Init a new applicant contact
     * @param sampleRecordCode
     * @param accountId
     * @param firstName
     * @param lastName
     * @param email
     * @return Contact
     */
    @NamespaceAccessible
    public static Contact newApplicantContact(String sampleRecordCode, Id accountId, String firstName, String lastName, String email) {

        Contact contact = new Contact(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            AccountId = accountId, 
            FirstName = firstName, 
            LastName = lastName, 
            Email = email,
            reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_APPLICANT,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return contact;
    }

    /**
     * @description Init a new student contact
     * @param sampleRecordCode
     * @param accountId
     * @param firstName
     * @param lastName
     * @param email
     * @return Contact
     */
    @NamespaceAccessible
    public static Contact newStudentContact(String sampleRecordCode, Id accountId, String firstName, String lastName, String email, String studentId) {

        Contact contact = new Contact(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            AccountId = accountId, 
            FirstName = firstName, 
            LastName = lastName, 
            Email = email,
            reduivy__Student_Id__c = studentId,
            reduivy__Generate_Student_Id__c = String.isNotBlank(studentId),
            reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_STUDENT,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return contact;
    }

    /**
     * @description Init a new faculty contact
     * @param sampleRecordCode
     * @param accountId
     * @param firstName
     * @param lastName
     * @param email
     * @return Contact
     */
    @NamespaceAccessible
    public static Contact newFacultyContact(String sampleRecordCode, Id accountId, String firstName, String lastName, String email) {

        Contact contact = new Contact(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            AccountId = accountId, 
            FirstName = firstName, 
            LastName = lastName, 
            Email = email,
            reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_FACULTY,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return contact;
    }

    /**
     * @description Init a new Qualified Faculty
     * @param sampleRecordCode
     * @param contactId
     * @param status
     * @param studyUnitId
     * @return reduivy__Qualified_Faculty__c
     */
    @NamespaceAccessible
    public static reduivy__Qualified_Faculty__c newQualifiedFaculty(String sampleRecordCode, Id contactId, String status, Id studyUnitId) {

        reduivy__Qualified_Faculty__c qualifiedFaculty = new reduivy__Qualified_Faculty__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            reduivy__Contact__c = contactId,
            reduivy__Status__c = status,
            reduivy__Study_Unit__c = studyUnitId,
            reduivy__Faculty_Role__c = 'Lecturer;Lab Assistant;Tutor;Assistant;Trainer',
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return qualifiedFaculty;
    }

    /**
     * @description Init a new Contact Availability
     * @param sampleRecordCode
     * @param contactId
     * @param campusId
     * @param fromDate
     * @param toDate
     * @param status
     * @param mondayFrom
     * @param mondayTo
     * @param tuesdayFrom
     * @param tuesdayTo
     * @param wednesdayFrom
     * @param wednesdayTo
     * @param thursdayFrom
     * @param thursdayTo
     * @param fridayFrom
     * @param fridayTo
     * @param saturdayFrom
     * @param saturdayTo
     * @param sundayFrom
     * @param sundayTo
     * @return reduivy__Contact_Availability__c
     */
    @NamespaceAccessible
    public static reduivy__Contact_Availability__c newContactAvailability(String sampleRecordCode, Id contactId, Id campusId, Date fromDate, Date toDate, String status, Time mondayFrom, Time mondayTo, Time tuesdayFrom, Time tuesdayTo, Time wednesdayFrom, Time wednesdayTo, Time thursdayFrom, Time thursdayTo, Time fridayFrom, Time fridayTo, Time saturdayFrom, Time saturdayTo, Time sundayFrom, Time sundayTo) {

        reduivy__Contact_Availability__c contactAvailability = new reduivy__Contact_Availability__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            reduivy__Contact__c = contactId,
            reduivy__Campus__c = campusId,
            reduivy__From_Date__c = fromDate,
            reduivy__To_Date__c = toDate, 
            reduivy__Status__c = status,
            reduivy__Monday_From__c = mondayFrom,
            reduivy__Monday_To__c = mondayTo,
            reduivy__Tuesday_From__c = tuesdayFrom,
            reduivy__Tuesday_To__c = tuesdayTo,
            reduivy__Wednesday_From__c = wednesdayFrom,
            reduivy__Wednesday_To__c = wednesdayTo,
            reduivy__Thursday_From__c = thursdayFrom,
            reduivy__Thursday_To__c = thursdayTo,
            reduivy__Friday_From__c = fridayFrom,
            reduivy__Friday_To__c = fridayTo,
            reduivy__Saturday_From__c = saturdayFrom,
            reduivy__Saturday_To__c = saturdayTo,
            reduivy__Sunday_From__c = sundayFrom,
            reduivy__Sunday_To__c = sundayTo,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return contactAvailability;
    }

    /**
     * @description Init a new Contact Association 
     * @param sampleRecordCode
     * @param contactId
     * @param educationalInstitutionId
     * @param role
     * @param status
     * @return reduivy__Contact_Association__c
     */
    @NamespaceAccessible
    public static reduivy__Contact_Association__c newContactAssociation (String sampleRecordCode, Id contactId, Id educationalInstitutionId, String role, String status) {

        reduivy__Contact_Association__c contactAssociation = new reduivy__Contact_Association__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            reduivy__Contact__c = contactId,
            reduivy__Account__c = educationalInstitutionId,
            reduivy__Role__c = role,
            reduivy__Status__c = status,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return contactAssociation;
    }

    /**
     * @description Init a new agreement
     * @param sampleRecordCode
     * @param educationalInstitutionId
     * @param name
     * @param startDate
     * @param endDate
     * @param status
     * @param type
     * @return reduivy__Agreement__c
     */
    @NamespaceAccessible
    public static reduivy__Agreement__c newAgreement(String sampleRecordCode, Id educationalInstitutionId, Id externalEducationalInstitutionId, String name, Date startDate, Date endDate, String status, String type) {

        reduivy__Agreement__c agreement = new reduivy__Agreement__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            Name = name,
            reduivy__Educational_Institution__c = educationalInstitutionId,
            reduivy__External_Educational_Institution__c = externalEducationalInstitutionId,
            reduivy__Start_Date__c = startDate,
            reduivy__End_Date__c = endDate,
            reduivy__Status__c = status,
            reduivy__Type__c = type,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return agreement;
    }

    /**
     * @description Init a new agreement unit equivalent
     * @param sampleRecordCode
     * @param agreementId
     * @param originUnitName
     * @param originUnitCodes
     * @param targetUnitCodes
     * @param status
     * @param type
     * @return reduivy__Agreement_Unit_Equivalent__c
     */
    @NamespaceAccessible
    public static reduivy__Agreement_Unit_Equivalent__c newAgreementUnitEquivalent(String sampleRecordCode, Id agreementId, String originUnitName, Set<String> originUnitCodes, Set<String> targetUnitCodes, String status, String type) {
        reduivy__Agreement_Unit_Equivalent__c agreementUnEv = new reduivy__Agreement_Unit_Equivalent__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            reduivy__Agreement__c = agreementId,
            Name = originUnitName,
            reduivy__Origin_Unit_Codes__c = String.join(originUnitCodes, ';'),
            reduivy__Target_Unit_Codes__c = String.join(targetUnitCodes, ';'),
            reduivy__Status__c = status,
            reduivy__Type__c = type,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return agreementUnEv;
    }

        /**
     * @description Init a new credit transfer application
     * @param sampleRecordCode
     * @param contactId
     * @param agreementUnitEqId
     * @param ipeId
     * @param ipsUnit
     * @param letterGrade
     * @param numericalGrade
     * @param status
     * @param type
     * @return reduivy__Credit_Transfer_Application__c
     */
    @NamespaceAccessible
    public static reduivy__Credit_Transfer_Application__c newCreditTransferApplication(String sampleRecordCode, Id contactId, Id agreementUnitEqId, Id ipeId, Id ipsUnit, String letterGrade, Decimal numericalGrade, Decimal creditAttempted, Decimal creditEarned, Date requestDate, String status, String approvedLetterGrade, Set<String> approvedUnitCodes, String type) {
        reduivy__Credit_Transfer_Application__c ctApplication= new reduivy__Credit_Transfer_Application__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            reduivy__Contact__c = contactId,
            reduivy__Agreement_Unit_Equivalent__c = agreementUnitEqId,
            reduivy__Individual_Program_Enrollment__c = ipeId,
            reduivy__Individual_Plan_Structure__c = ipsUnit,
            reduivy__Letter_Grade__c = letterGrade,
            reduivy__Numerical_Grade__c = numericalGrade,
            reduivy__Credits_Attempted__c = creditAttempted,
            reduivy__Credits_Earned__c = creditEarned,
            reduivy__Request_Date__c = requestDate,
            reduivy__Status__c = status,
            reduivy__Approved_Letter_Grade__c = approvedLetterGrade,
            reduivy__Approved_Unit_Codes__c = String.join(approvedUnitCodes, ';'),
            reduivy__Type__c = type,
            reduivy__Start_Date__c = System.today().addDays(-90),
            reduivy__Completed_Date__c = System.today().addDays(-10),
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return ctApplication;
    }

    /**
     * @description Init a new facility
     * @param sampleRecordCode
     * @param campusId
     * @param parentFacilityId
     * @param name
     * @param capacity
     * @param type
     * @param isActive
     * @return reduivy__Facility__c
     */
    @NamespaceAccessible
    public static reduivy__Facility__c newFacility(String sampleRecordCode, Id campusId, Id parentFacilityId, String name, Decimal capacity, String type, Boolean isActive) {
        reduivy__Facility__c facility = new reduivy__Facility__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            Name = name,
            reduivy__Campus__c = campusId,
            reduivy__Capacity__c = capacity,
            reduivy__Facility_Type__c = type,
            reduivy__Parent_Facility__c = parentFacilityId,
            reduivy__Active__c = isActive,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return facility;
    }

    /**
     * @description Init a new facility availability
     * @param sampleRecordCode
     * @param facilityId
     * @param fromDate
     * @param toDate
     * @param status
     * @param mondayFrom
     * @param mondayTo
     * @param tuesdayFrom
     * @param tuesdayTo
     * @param wednesdayFrom
     * @param wednesdayTo
     * @param thursdayFrom
     * @param thursdayTo
     * @param fridayFrom
     * @param fridayTo
     * @param saturdayFrom
     * @param saturdayTo
     * @param sundayFrom
     * @param sundayTo
     * @return reduivy__Facility_Availability__c
     */
    @NamespaceAccessible
    public static reduivy__Facility_Availability__c newFacilityAvailability(String sampleRecordCode, Id facilityId, Date fromDate, Date toDate, String status, Time mondayFrom, Time mondayTo, Time tuesdayFrom, Time tuesdayTo, Time wednesdayFrom, Time wednesdayTo, Time thursdayFrom, Time thursdayTo, Time fridayFrom, Time fridayTo, Time saturdayFrom, Time saturdayTo, Time sundayFrom, Time sundayTo) {
        reduivy__Facility_Availability__c facilityAvailability = new reduivy__Facility_Availability__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            reduivy__Facility__c = facilityId,
            reduivy__From_Date__c = fromDate,
            reduivy__To_Date__c = toDate, 
            reduivy__Status__c = status,
            reduivy__Monday_From__c = mondayFrom,
            reduivy__Monday_To__c = mondayTo,
            reduivy__Tuesday_From__c = tuesdayFrom,
            reduivy__Tuesday_To__c = tuesdayTo,
            reduivy__Wednesday_From__c = wednesdayFrom,
            reduivy__Wednesday_To__c = wednesdayTo,
            reduivy__Thursday_From__c = thursdayFrom,
            reduivy__Thursday_To__c = thursdayTo,
            reduivy__Friday_From__c = fridayFrom,
            reduivy__Friday_To__c = fridayTo,
            reduivy__Saturday_From__c = saturdayFrom,
            reduivy__Saturday_To__c = saturdayTo,
            reduivy__Sunday_From__c = sundayFrom,
            reduivy__Sunday_To__c = sundayTo,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return facilityAvailability;
    }

    /**
     * @description Init a study unit
     * @param sampleRecordCode
     * @param educationalInstitutionId
     * @param name
     * @param code
     * @param credits
     * @param fieldOfStudy
     * @param unitLevel
     * @param eftsl
     * @param reqLogic
     * @return reduivy__Study_Unit__c
     */
    @NamespaceAccessible
    public static reduivy__Study_Unit__c newStudyUnit(String sampleRecordCode, Id educationalInstitutionId, Id studyGradeSettingId, String name, String code, Decimal credits, String fieldOfStudy, String unitLevel, Decimal eftsl, String reqLogic) {

        reduivy__Study_Unit__c studyUnit = new reduivy__Study_Unit__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            reduivy__Educational_Institution__c = educationalInstitutionId,
            reduivy__Study_Grade_Setting__c = studyGradeSettingId,
            Name = name,
            reduivy__Unit_Code__c = code,
            reduivy__Credits__c = credits,
            reduivy__Default_EFTSL__c = eftsl,
            reduivy__Field_of_Study__c = fieldOfStudy,
            reduivy__Unit_Level__c = unitLevel,
            reduivy__Requirement_Logic__c = reqLogic,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return studyUnit;
    }
    
    /**
     * @description Init a credit study unit requirement
     * @param sampleRecordCode
     * @param studyUnitId
     * @param name
     * @param reqID
     * @param credits
     * @return reduivy__Study_Unit_Requirement__c
     */
    @NamespaceAccessible
    public static reduivy__Study_Unit_Requirement__c newCreditsStudyUnitRequirement(String sampleRecordCode, Id studyUnitId, String name, String reqID, Decimal credits) {

        reduivy__Study_Unit_Requirement__c sur = new reduivy__Study_Unit_Requirement__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            Name = name,
            reduivy__Study_Unit__c = studyUnitId,
            reduivy__Requirement_ID__c = reqID,
            reduivy__Requirement_Type__c = SUR_Helper.REQTYPE_CREDITS,
            reduivy__Credits__c = credits,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return sur;
    }

    /**
     * @description Init a study unit requirement
     * @param sampleRecordCode
     * @param studyUnitId
     * @param reqStudyUnitId
     * @param name
     * @param reqID
     * @param reqType
     * @return reduivy__Study_Unit_Requirement__c
     */
    @NamespaceAccessible
    public static reduivy__Study_Unit_Requirement__c newUnitStudyUnitRequirement(String sampleRecordCode, Id studyUnitId, Id reqStudyUnitId, String name, String reqID, String reqType) {

        reduivy__Study_Unit_Requirement__c sur = new reduivy__Study_Unit_Requirement__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            Name = name,
            reduivy__Study_Unit__c = studyUnitId,
            reduivy__Requirement_ID__c = reqID,
            reduivy__Requirement_Type__c = reqType,
            reduivy__Required_Study_Unit__c = reqStudyUnitId,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return sur;
    }

    /**
     * @description Init an other study unit requirement
     * @param sampleRecordCode
     * @param studyUnitId
     * @param name
     * @param reqID
     * @return reduivy__Study_Unit_Requirement__c
     */
    @NamespaceAccessible
    public static reduivy__Study_Unit_Requirement__c newOtherStudyUnitRequirement(String sampleRecordCode, Id studyUnitId, String name, String reqID) {

        reduivy__Study_Unit_Requirement__c sur = new reduivy__Study_Unit_Requirement__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            Name = name,
            reduivy__Study_Unit__c = studyUnitId,
            reduivy__Requirement_ID__c = reqID,
            reduivy__Requirement_Type__c = SUR_Helper.REQTYPE_OTHER,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return sur;
    }

    /** ISS-002155
     * @description Init an custom study unit requirement
     * @param sampleRecordCode
     * @param studyUnitId
     * @param name
     * @param reqID
     * @param fieldName
     * @param matchingOperator
     * @param matchingValue
     * @return reduivy__Study_Unit_Requirement__c
     */
    @NamespaceAccessible
    public static reduivy__Study_Unit_Requirement__c newCustomStudyUnitRequirement(String sampleRecordCode, Id studyUnitId, String name, String reqID, String fieldName, String matchingOperator, String matchingValue) {

        reduivy__Study_Unit_Requirement__c sur = new reduivy__Study_Unit_Requirement__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            Name = name,
            reduivy__Study_Unit__c = studyUnitId,
            reduivy__Requirement_ID__c = reqID,
            reduivy__Requirement_Type__c = SUR_Helper.REQTYPE_CUSTOM,
            reduivy__Field_Name__c = fieldName,
            reduivy__Field_Matching_Operator__c = matchingOperator, 
            reduivy__Field_Matching_Value__c = matchingValue,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return sur;
    }

    /**
     * @description Init a new study program
     * @param sampleRecordCode
     * @param educationalInstitutionId
     * @param name
     * @param academicLevel
     * @param programCode
     * @return reduivy__Study_Program__c
     */
    @NamespaceAccessible
    public static reduivy__Study_Program__c newStudyProgram(String sampleRecordCode, Id educationalInstitutionId, String name, String academicLevel, String programCode) {

        reduivy__Study_Program__c studyProgram = new reduivy__Study_Program__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            reduivy__Educational_Institution__c = educationalInstitutionId,
            Name = name,
            reduivy__Academic_Level__c = academicLevel,
            reduivy__Program_Code__c = programCode,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return studyProgram;
    }

    /**
     * @description Init a new study plan
     * @param sampleRecordCode
     * @param studyProgramId
     * @param name
     * @param payUpfront
     * @param status
     * @param isDefault
     * @param totalCredits
     * @return reduivy__Study_Plan__c
     */
    @NamespaceAccessible
    public static reduivy__Study_Plan__c newStudyPlan(String sampleRecordCode, Id studyProgramId, Id studyFeeConfigId, String name, String payUpfront, String status, Boolean isDefault, Decimal totalCredits) {

        reduivy__Study_Plan__c studyPlan = new reduivy__Study_Plan__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            reduivy__Study_Program__c = studyProgramId,
            Name = name,
            reduivy__Pay_Upfront__c = payUpfront,
            reduivy__Status__c = status,
            reduivy__Default__c = isDefault,
            reduivy__Total_Required_Credits__c = totalCredits,
            reduivy__Study_Fee_Config__c = studyFeeConfigId,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return studyPlan;
    }

    /**
     * @description Init a new group study plan structure
     * @param sampleRecordCode
     * @param studyPlanId
     * @param parentGroupId
     * @param name
     * @param category
     * @param credits
     * @param maxCredits
     * @param unitsRequired
     * @param creditsPerUnit
     * @return reduivy__Study_Plan_Structure__c
     */
    @NamespaceAccessible
    public static reduivy__Study_Plan_Structure__c newGroupStudyPlanStructure(String sampleRecordCode, Id studyPlanId, Id parentGroupId, String name, String category, Decimal credits, Decimal maxCredits, Decimal unitsRequired, Decimal creditsPerUnit) {

        reduivy__Study_Plan_Structure__c groupSps = new reduivy__Study_Plan_Structure__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            RecordTypeId = SPS_Helper.getGroupRecordTypeId(),
            Name = name,
            reduivy__Study_Plan__c = studyPlanId,
            reduivy__Parent_Study_Plan_Structure__c = parentGroupId,
            reduivy__Category__c = category,
            reduivy__Credits__c = credits,
            reduivy__Max_Credits__c = maxCredits,
            reduivy__Units_Required__c = unitsRequired,
            reduivy__Credits_equivalent_per_Unit__c = creditsPerUnit,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return groupSps;
    }

    /**
     * @description Init a new group study plan structure
     * @param sampleRecordCode
     * @param studyPlanId
     * @param parentGroupId
     * @param studyUnitId
     * @param name
     * @param category
     * @param credits
     * @param allowPreEnroll
     * @param reqLogic
     * @return reduivy__Study_Plan_Structure__c
     */
    @NamespaceAccessible
    public static reduivy__Study_Plan_Structure__c newUnitStudyPlanStructure(String sampleRecordCode, Id studyPlanId, Id parentGroupId, Id studyUnitId, String name, String category, Decimal credits, Boolean allowPreEnroll, String reqLogic) {

        reduivy__Study_Plan_Structure__c unitSps = new reduivy__Study_Plan_Structure__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            RecordTypeId = SPS_Helper.getUnitRecordTypeId(),
            Name = name,
            reduivy__Study_Plan__c = studyPlanId,
            reduivy__Parent_Study_Plan_Structure__c = parentGroupId,
            reduivy__Study_Unit__c = studyUnitId,
            reduivy__Category__c = category,
            reduivy__Credits__c = credits,
            reduivy__Allow_Pre_Enrollment__c = allowPreEnroll,
            reduivy__Requirement_Logic__c = reqLogic,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return unitSps;
    }

    /**
     * @description Init a credit study plan unit requirement
     * @param sampleRecordCode
     * @param studyPlanUnitId
     * @param reqID
     * @param credits
     * @return reduivy__Study_Plan_Unit_Requirement__c
     */
    @NamespaceAccessible
    public static reduivy__Study_Plan_Unit_Requirement__c newCreditsStudyPlanUnitRequirement(String sampleRecordCode, Id studyPlanUnitId, String reqID, Decimal credits) {

        reduivy__Study_Plan_Unit_Requirement__c spur = new reduivy__Study_Plan_Unit_Requirement__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            Name = studyPlanUnitId + '_Credits',
            reduivy__Study_Plan_Unit__c = studyPlanUnitId,
            reduivy__Requirement_ID__c = reqID,
            reduivy__Requirement_Type__c = SUR_Helper.REQTYPE_CREDITS,
            reduivy__Credits__c = credits,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return spur;
    }

    /**
     * @description Init a study plan unit requirement
     * @param sampleRecordCode
     * @param studyPlanUnitId
     * @param reqStudyUnitId
     * @param reqID
     * @param reqType
     * @return reduivy__Study_Plan_Unit_Requirement__c
     */
    @NamespaceAccessible
    public static reduivy__Study_Plan_Unit_Requirement__c newUnitStudyPlanUnitRequirement(String sampleRecordCode, Id studyPlanUnitId, Id reqStudyUnitId, String reqID, String reqType) {

        reduivy__Study_Plan_Unit_Requirement__c spur = new reduivy__Study_Plan_Unit_Requirement__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            Name = studyPlanUnitId + '_' + reqID + '_' + reqType,
            reduivy__Study_Plan_Unit__c = studyPlanUnitId,
            reduivy__Requirement_ID__c = reqID,
            reduivy__Requirement_Type__c = reqType,
            reduivy__Required_Study_Unit__c = reqStudyUnitId,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return spur;
    }

    /**
     * @description Init an other study plan unit requirement
     * @param sampleRecordCode
     * @param studyPlanUnitId
     * @param reqID
     * @return reduivy__Study_Plan_Unit_Requirement__c
     */
    @NamespaceAccessible
    public static reduivy__Study_Plan_Unit_Requirement__c newOtherStudyPlanUnitRequirement(String sampleRecordCode, Id studyPlanUnitId, String reqID) {

        reduivy__Study_Plan_Unit_Requirement__c spur = new reduivy__Study_Plan_Unit_Requirement__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            Name = studyPlanUnitId + '_' + reqID + '_Other',
            reduivy__Study_Plan_Unit__c = studyPlanUnitId,
            reduivy__Requirement_ID__c = reqID,
            reduivy__Requirement_Type__c = SUR_Helper.REQTYPE_OTHER,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return spur;
    }

    /**
     * @description Init a study pathway
     * @param sampleRecordCode
     * @param studyPlanId
     * @param name
     * @param status
     * @param isDefault
     * @return reduivy__Study_Pathway__c
     */
    @NamespaceAccessible
    public static reduivy__Study_Pathway__c newStudyPathway(String sampleRecordCode, Id studyPlanId, String name, String status, Boolean isDefault) {

        reduivy__Study_Pathway__c studyPathway = new reduivy__Study_Pathway__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            Name = name,
            reduivy__Study_Plan__c = studyPlanId,
            reduivy__Default__c = isDefault,
            reduivy__Status__c = status,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return studyPathway;
    }

    /**
     * @description Init a study pathway term
     * @param sampleRecordCode
     * @param studyPathwayId
     * @param termNumber
     * @param enrollmentMethod
     * @param recommendedCredits
     * @param maxCredits
     * @return reduivy__Study_Pathway_Term__c
     */
    @NamespaceAccessible
    public static reduivy__Study_Pathway_Term__c newStudyPathwayTerm(String sampleRecordCode, Id studyPathwayId, Decimal termNumber, String enrollmentMethod, Decimal recommendedCredits, Decimal maxCredits) {

        reduivy__Study_Pathway_Term__c studyPathwayTerm = new reduivy__Study_Pathway_Term__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            reduivy__Study_Pathway__c = studyPathwayId,
            reduivy__Term_Number__c = termNumber,
            reduivy__Enrollment_Method__c = enrollmentMethod,
            reduivy__Recommended_Credits__c = recommendedCredits,
            reduivy__Max_Credits__c = maxCredits,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return studyPathwayTerm;
    }

    /**
     * @description Init a unit study pathway unit
     * @param sampleRecordCode
     * @param studyPathwayTermId
     * @param studyUnitId
     * @param term
     * @return reduivy__Study_Pathway_Unit__c
     */
    @NamespaceAccessible
    public static reduivy__Study_Pathway_Unit__c newUnitStudyPathwayUnit(String sampleRecordCode, Id studyPathwayTermId, Id studyUnitId, Id applicableStudyPlanId) {

        reduivy__Study_Pathway_Unit__c spu = new reduivy__Study_Pathway_Unit__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            reduivy__Study_Pathway_Term__c = studyPathwayTermId,
            reduivy__Study_Unit__c = studyUnitId,
            reduivy__Applicable_Study_Plan__c = applicableStudyPlanId,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return spu;
    }

    /**
     * @description Init a group study pathway unit
     * @param sampleRecordCode
     * @param studyPathwayTermId
     * @param studyPlanGroupId
     * @param numOfUnits
     * @param term
     * @return reduivy__Study_Pathway_Unit__c
     */
    @NamespaceAccessible
    public static reduivy__Study_Pathway_Unit__c newGroupStudyPathwayUnit(String sampleRecordCode, Id studyPathwayTermId, Id studyPlanGroupId, Decimal numOfUnits, Id applicableStudyPlanId) {

        reduivy__Study_Pathway_Unit__c spu = new reduivy__Study_Pathway_Unit__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            reduivy__Study_Pathway_Term__c = studyPathwayTermId,
            reduivy__Study_Plan_Group__c = studyPlanGroupId,
            reduivy__Number_of_Units_from_Group__c = numOfUnits,
            reduivy__Applicable_Study_Plan__c = applicableStudyPlanId,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return spu;
    }

    /**
     * @description Init an academic year study term
     * @param sampleRecordCode
     * @param educationalInstitutionId
     * @param name
     * @param alternateName
     * @param type
     * @param startDate
     * @param endDate
     * @return reduivy__Study_Term__c
     */
    @NamespaceAccessible
    public static reduivy__Study_Term__c newAcademicYearStudyTerm(String sampleRecordCode, Id educationalInstitutionId, String name, String alternateName, String type, Date startDate, Date endDate) {
        
        reduivy__Study_Term__c academicYear = new reduivy__Study_Term__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            RecordTypeId = STM_Helper.getAcademicYearRecordTypeId(),
            reduivy__Educational_Institution__c = educationalInstitutionId,
            Name = name,
            reduivy__Alternate_Name__c = alternateName,
            reduivy__Type__c = type,
            reduivy__Start_Date__c = startDate,
            reduivy__End_Date__c = endDate,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return academicYear;
    }

    /**
     * @description Init an academic term study term
     * @param sampleRecordCode
     * @param academicYearId
     * @param name
     * @param alternateName
     * @param type
     * @param startDate
     * @param endDate
     * @param censusDate
     * @param preEnrollmentDate
     * @param enrollmentOpenDate
     * @param enrollmentCloseDate
     * @param termLabel
     * @param internalOnly
     * @return reduivy__Study_Term__c
     */
    @NamespaceAccessible
    public static reduivy__Study_Term__c newAcademicTermStudyTerm(String sampleRecordCode, Id academicYearId, String name, String alternateName, String type, Date startDate, Date endDate, Date censusDate, Datetime preEnrollmentDate, Datetime enrollmentOpenDate, Datetime enrollmentCloseDate, Boolean internalOnly) {
        
        reduivy__Study_Term__c academicTerm = new reduivy__Study_Term__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            RecordTypeId = STM_Helper.getAcademicTermRecordTypeId(),
            reduivy__Academic_Year__c = academicYearId,
            Name = name,
            reduivy__Alternate_Name__c = alternateName,
            reduivy__Type__c = type,
            reduivy__Start_Date__c = startDate,
            reduivy__End_Date__c = endDate,
            reduivy__Census_Date__c = censusDate,
            reduivy__Fee_Due_Date__c = censusDate,
            reduivy__Pre_enrollment_Open_Date__c = preEnrollmentDate,
            reduivy__Enrollment_Open_Date__c = enrollmentOpenDate,
            reduivy__Enrollment_Close_Date__c = enrollmentCloseDate,
            reduivy__For_Internal_Only__c = internalOnly,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return academicTerm;
    }
    
    /**
     * @description Init a study intake
     * @param sampleRecordCode
     * @param campusId
     * @param studyProgramId
     * @param defaultStudyPlanId
     * @param academicTermId
     * @param registrationOpenDate
     * @param registrationCloseDate
     * return reduivy__Study_Intake__c
     */
    @NamespaceAccessible
    public static reduivy__Study_Intake__c newStudyIntake(String sampleRecordCode, Id campusId, Id studyProgramId, Id defaultStudyPlanId, Id defaultStudyPathwayId, Id academicTermId, String name, Date registrationOpenDate, Date registrationCloseDate, String status) {

        reduivy__Study_Intake__c studyIntake = new reduivy__Study_Intake__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            Name = name,
            reduivy__Campus__c = campusId,
            reduivy__Study_Program__c = studyProgramId,
            reduivy__Default_Study_Plan__c = defaultStudyPlanId,
            reduivy__Default_Study_Pathway__c = defaultStudyPathwayId,
            reduivy__Academic_Term__c = academicTermId,
            reduivy__Registration_Open_Date__c = registrationOpenDate,
            reduivy__Registration_Close_Date__c = registrationCloseDate,
            reduivy__Status__c = status,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return studyIntake;
    }

    /**
     * @description Init a study offering
     * @param sampleRecordCode
     * @param studyUnitId
     * @param academicTermId
     * @param campusId
     * @param capacity
     * @param startDate
     * @param endDate
     * return reduivy__Study_Offering__c
     */
    @NamespaceAccessible
    public static reduivy__Study_Offering__c newStudyOffering(String sampleRecordCode, Id studyUnitId, Id academicTermId, Id campusId, String name, Decimal capacity, Date startDate, Date endDate) {

        reduivy__Study_Offering__c studyOffering = new reduivy__Study_Offering__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            Name = name,
            reduivy__Study_Unit__c = studyUnitId,
            reduivy__Academic_Term__c = academicTermId,
            reduivy__Campus__c = campusId,
            reduivy__Capacity__c = capacity,
            reduivy__Start_Date__c = startDate,
            reduivy__End_Date__c = endDate,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return studyOffering;
    }

    /**
     * @description Init a study grade setting
     * @param sampleRecordCode
     * @param educationalInstitutionId
     * @param type
     * @return reduivy__Study_Grade_Setting__c
     */
    @NamespaceAccessible
    public static reduivy__Study_Grade_Setting__c newStudyGradeSetting(String sampleRecordCode, Id educationalInstitutionId, String name, String gradeSettingType) {
        
        reduivy__Study_Grade_Setting__c sgs = new reduivy__Study_Grade_Setting__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            Name = name,
            reduivy__Educational_Institution__c = educationalInstitutionId,
            reduivy__Grade_Setting_Type__c = gradeSettingType,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return sgs;
    }

    /**
     * @description Init a study grading scheme
     * @param sampleRecordCode
     * @param studyGradeSettingId
     * @param type
     * @param lowerRange
     * @param higherRange
     * @param letterGrade
     * @param gradePoints
     * @param gradeResult
     * @param letterGradeScoringRange
     * @param excludeCreditsEarned
     * @param excludeGpa
     * @param enrollmentStatus
     * @param sequence
     * @return reduivy__Study_Grading_Scheme__c
     */
    @NamespaceAccessible
    public static reduivy__Study_Grading_Scheme__c newStudyGradingScheme(String sampleRecordCode, Id studyGradeSettingId, String name, Decimal lowerRange, Decimal higherRange, String letterGrade, Decimal gradePoints, String gradeResult, String letterGradeScoringRange, String excludeCreditsEarned, String excludeGpa, String enrollmentStatus, Decimal sequence) {
        
        reduivy__Study_Grading_Scheme__c sgc = new reduivy__Study_Grading_Scheme__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            Name = name,
            reduivy__Study_Grade_Setting__c = studyGradeSettingId,
            reduivy__Numerical_Grade_Lower_Range__c = lowerRange,
            reduivy__Numerical_Grade_Higher_Range__c = higherRange,
            reduivy__Letter_Grade__c = letterGrade,
            reduivy__Grade_Points__c = gradePoints,
            reduivy__Grade_Result__c = gradeResult,
            reduivy__Letter_Grade_Scoring_Range__c = letterGradeScoringRange,
            reduivy__Exclude_Credits_Earned__c = excludeCreditsEarned,
            reduivy__Exclude_GPA_Calculation__c = excludeGpa,
            reduivy__Enrollment_Status__c = enrollmentStatus,
            reduivy__Sequence__c = sequence,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return sgc;
    }

    /**
     * @description Init a study cohort enrollment
     * @param sampleRecordCode
     * @param academicTermId
     * @param cohortID
     * @param classStanding
     * @param classYear
     * @param preEnrollmentOpenDate
     * @param enrollmentOpenDate
     * @param enrollmentCloseDate
     * @return reduivy__Study_Cohort_Enrollment__c
     */
    @NamespaceAccessible
    public static reduivy__Study_Cohort_Enrollment__c newStudyCohortEnrollment(String sampleRecordCode, Id academicTermId, String name, String cohortID, String classStanding, String classYear, Datetime preEnrollmentOpenDate, Datetime enrollmentOpenDate, Datetime enrollmentCloseDate) {
        
        reduivy__Study_Cohort_Enrollment__c sce = new reduivy__Study_Cohort_Enrollment__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            Name = name,
            reduivy__Academic_Term__c = academicTermId,
            reduivy__Cohort_ID__c = cohortID,
            reduivy__Class_Standing__c = classStanding,
            reduivy__Class_Year__c = classYear,
            reduivy__Pre_enrollment_Open_Date__c = preEnrollmentOpenDate,
            reduivy__Enrollment_Open_Date__c = enrollmentOpenDate,
            reduivy__Enrollment_Close_Date__c = enrollmentCloseDate,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return sce;
    }

    /**
     * @description Init a study plan option
     * @param sampleRecordCode
     * @param masterStudyPlanId
     * @param childStudyPlanId
     * @param type
     * @param status
     * @return reduivy__Study_Plan_Option__c
     */
    @NamespaceAccessible
    public static reduivy__Study_Plan_Option__c newStudyPlanOption(String sampleRecordCode, Id masterStudyPlanId, Id childStudyPlanId, String completionRequirement, String status) {

        reduivy__Study_Plan_Option__c spo = new reduivy__Study_Plan_Option__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            reduivy__Master_Study_Plan__c = masterStudyPlanId,
            reduivy__Child_Study_Plan__c = childStudyPlanId,
            reduivy__Completion_Requirement__c = completionRequirement,
            reduivy__Status__c = status,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return spo;
    }

    /**
     * @description Init an individual achievement
     * @param sampleRecordCode
     * @param contactId
     * @param name
     * @param educationalInstitutionName
     * @param completionStatus
     * @param completionDate
     * @param verificationStatus
     * @param verificationDate
     * @return reduivy__Individual_Achievement__c
     */
    @NamespaceAccessible
    public static reduivy__Individual_Achievement__c newIndividualAchievement(String sampleRecordCode, Id contactId, String name, String educationalInstitutionName, String academicLevel, String completionStatus, Date completionDate, String verificationStatus, Date verificationDate) {

        reduivy__Individual_Achievement__c iac = new reduivy__Individual_Achievement__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            reduivy__Contact__c = contactId,
            Name = name,
            reduivy__Educational_Institution_Name__c = educationalInstitutionName,
            reduivy__Academic_Level__c = academicLevel,
            reduivy__Completion_Status__c = completionStatus,
            reduivy__Graduation_Completion_Date__c = completionDate,
            reduivy__Verification_Status__c = verificationStatus,
            reduivy__Verification_Date__c = verificationDate,
            reduivy__UUID__c = System.UUID.randomUUID().toString(),
            reduivy__Type__c = IAC_Helper.TYPE_ACADEMIC
        );

        return iac;
    }

    /**
     * @description Init a master individual program enrollment
     * @param sampleRecordCode
     * @param contactId
     * @param studyProgramId
     * @param studyPlanId
     * @param studyIntakeId
     * @param startingTermId
     * @param studyPathwayId
     * @param defaultCampusId
     * @param classYear
     * @param classStanding
     * @param eligibleToEnroll
     * @param enrollmentStatus
     * @param idvAcademicProfileId
     * @return reduivy__Individual_Program_Enrollment__c
     */
    @NamespaceAccessible
    public static reduivy__Individual_Program_Enrollment__c newMasterIndividualProgramEnrollment(String sampleRecordCode, Id contactId, Id studyProgramId, Id studyPlanId, Id studyIntakeId, Id startingTermId, Id studyPathwayId, Id defaultCampusId, String classYear, String classStanding, Boolean eligibleToEnroll, String enrollmentStatus, Id idvAcademicProfileId) {

        reduivy__Individual_Program_Enrollment__c ipe = new reduivy__Individual_Program_Enrollment__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            RecordTypeId = IPE_Helper.getMasterEnrollmentRecordTypeId(),
            reduivy__Contact__c = contactId,
            reduivy__Study_Program__c = studyProgramId,
            reduivy__Study_Plan__c = studyPlanId,
            reduivy__Study_Intake__c = studyIntakeId,
            reduivy__Starting_Term__c = startingTermId,
            reduivy__Study_Pathway__c = studyPathwayId,
            reduivy__Default_Campus__c = defaultCampusId,
            reduivy__Class_Year__c = classYear,
            reduivy__Class_Standing__c = classStanding,
            reduivy__Eligible_To_Enroll__c = eligibleToEnroll,
            reduivy__Enrollment_Status__c = enrollmentStatus,
            reduivy__Individual_Academic_Profile__c = idvAcademicProfileId,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return ipe;
    }

    /**
     * @description Init a child individual program enrollment
     * @param sampleRecordCode
     * @param contactId
     * @param studyProgramId
     * @param studyPlanId
     * @param masterIndividualProgramEnrollmentId
     * @param eligibleToEnroll
     * @param enrollmentStatus
     * @return reduivy__Individual_Program_Enrollment__c
     */
    @NamespaceAccessible
    public static reduivy__Individual_Program_Enrollment__c newChildIndividualProgramEnrollment(String sampleRecordCode, Id contactId, Id studyProgramId, Id studyPlanId, Id masterIndividualProgramEnrollmentId, String completionRequirement, Boolean eligibleToEnroll, String enrollmentStatus) {

        reduivy__Individual_Program_Enrollment__c ipe = new reduivy__Individual_Program_Enrollment__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            RecordTypeId = IPE_Helper.getChildEnrollmentRecordTypeId(),
            reduivy__Contact__c = contactId,
            reduivy__Study_Program__c = studyProgramId,
            reduivy__Study_Plan__c = studyPlanId,
            reduivy__Master_Enrollment__c = masterIndividualProgramEnrollmentId,
            reduivy__Completion_Requirement__c = completionRequirement,
            reduivy__Eligible_To_Enroll__c = eligibleToEnroll,
            reduivy__Enrollment_Status__c = enrollmentStatus,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return ipe;
    }

    /**
     * @description Init a unit individual plan structure
     * @param sampleRecordCode
     * @param individualProgramEnrollmentId
     * @param parentPlanStructureId
     * @param unitStudyPlanStructureId
     * @param individualPathwayId
     * @param category
     * @param credits
     * @param isPrimary
     * @param status
     * @param reduivy__Individual_Plan_Structure__c
     */
    @NamespaceAccessible
    public static reduivy__Individual_Plan_Structure__c newIndividualUnitPlanStructure(String sampleRecordCode, Id individualProgramEnrollmentId, Id parentPlanStructureId, Id unitStudyPlanStructureId, String category, Decimal credits, Boolean isPrimary, String status) {

        reduivy__Individual_Plan_Structure__c ips = new reduivy__Individual_Plan_Structure__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            RecordTypeId = IPS_Helper.getUnitRecordTypeId(),
            reduivy__Individual_Program_Enrollment__c = individualProgramEnrollmentId,
            reduivy__Parent_Plan_Structure__c = parentPlanStructureId,
            reduivy__Study_Plan_Structure__c = unitStudyPlanStructureId,
            reduivy__Category__c = category,
            reduivy__Credits__c = credits,
            reduivy__Primary__c = isPrimary,
            reduivy__Status__c = status,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return ips;
    }

    /**
     * @description Init a group individual plan structure
     * @param sampleRecordCode
     * @param individualProgramEnrollmentId
     * @param parentPlanStructureId
     * @param groupStudyPlanStructureId
     * @param category
     * @param credits
     * @param maxCredits
     * @param unitsRequired
     * @param creditsPerUnit
     * @param status
     * @return reduivy__Individual_Plan_Structure__c
     */
    @NamespaceAccessible
    public static reduivy__Individual_Plan_Structure__c newIndividualGroupPlanStructure(String sampleRecordCode, Id individualProgramEnrollmentId, Id parentPlanStructureId, Id groupStudyPlanStructureId, String category, Decimal credits, Decimal maxCredits, Decimal unitsRequired, Decimal creditsPerUnit, String status) {

        reduivy__Individual_Plan_Structure__c ips = new reduivy__Individual_Plan_Structure__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            RecordTypeId = IPS_Helper.getGroupRecordTypeId(),
            reduivy__Individual_Program_Enrollment__c = individualProgramEnrollmentId,
            reduivy__Parent_Plan_Structure__c = parentPlanStructureId,
            reduivy__Study_Plan_Structure__c = groupStudyPlanStructureId,
            reduivy__Category__c = category,
            reduivy__Credits__c = credits,
            reduivy__Max_Credits__c = maxCredits,
            reduivy__Units_Required__c = unitsRequired,
            reduivy__Credits_equivalent_per_Unit__c = creditsPerUnit,
            reduivy__Status__c = status,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return ips;
    }

    /**
     * @description Init a credit individual plan unit requirement
     * @param sampleRecordCode
     * @param studyPlanUnitId
     * @param reqID
     * @param credits
     * @return reduivy__Individual_Plan_Unit_Requirement__c
     */
    @NamespaceAccessible
    public static reduivy__Individual_Plan_Unit_Requirement__c newCreditsIndividualPlanUnitRequirement(String sampleRecordCode, Id individualPlanUnitId, String reqID, Decimal credits) {

        reduivy__Individual_Plan_Unit_Requirement__c iur = new reduivy__Individual_Plan_Unit_Requirement__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            Name = individualPlanUnitId + '_Credits',
            reduivy__Individual_Plan_Unit__c = individualPlanUnitId,
            reduivy__Requirement_ID__c = reqID,
            reduivy__Requirement_Type__c = SUR_Helper.REQTYPE_CREDITS,
            reduivy__Credits__c = credits,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return iur;
    }

    /**
     * @description Init a unit individual plan unit requirement
     * @param sampleRecordCode
     * @param studyPlanUnitId
     * @param reqStudyUnitId
     * @param reqID
     * @param reqType
     * @return reduivy__Individual_Plan_Unit_Requirement__c
     */
    @NamespaceAccessible
    public static reduivy__Individual_Plan_Unit_Requirement__c newUnitIndividualPlanUnitRequirement(String sampleRecordCode, Id individualPlanUnitId, Id reqStudyUnitId, String reqID, String reqType) {

        reduivy__Individual_Plan_Unit_Requirement__c iur = new reduivy__Individual_Plan_Unit_Requirement__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            Name = individualPlanUnitId + '_' + reqID + '_' + reqType,
            reduivy__Individual_Plan_Unit__c = individualPlanUnitId,
            reduivy__Requirement_ID__c = reqID,
            reduivy__Requirement_Type__c = reqType,
            reduivy__Required_Study_Unit__c = reqStudyUnitId,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return iur;
    }

    /**
     * @description Init an other individual plan unit requirement
     * @param sampleRecordCode
     * @param studyPlanUnitId
     * @param reqID
     * @return reduivy__Individual_Plan_Unit_Requirement__c
     */
    @NamespaceAccessible
    public static reduivy__Individual_Plan_Unit_Requirement__c newOtherIndividualPlanUnitRequirement(String sampleRecordCode, Id individualPlanUnitId, String reqID) {

        reduivy__Individual_Plan_Unit_Requirement__c iur = new reduivy__Individual_Plan_Unit_Requirement__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            Name = individualPlanUnitId + '_' + reqID + '_Other',
            reduivy__Individual_Plan_Unit__c = individualPlanUnitId,
            reduivy__Requirement_ID__c = reqID,
            reduivy__Requirement_Type__c = SUR_Helper.REQTYPE_OTHER,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return iur;
    }

    /**
     * @description Init an individual pathway
     * @param sampleRecordCode
     * @param individualProgramEnrollmentId
     * @param academicTermId
     * @param termNumber
     * @param recommendedCredits
     * @param maxCredits
     * @param enrollmentMethod
     * @return reduivy__Individual_Pathway__c
     */
    @NamespaceAccessible
    public static reduivy__Individual_Pathway__c newIndividualPathway(String sampleRecordCode, Id individualProgramEnrollmentId, Id academicTermId, Decimal termNumber, Decimal recommendedCredits, Decimal maxCredits, String enrollmentMethod) {

        reduivy__Individual_Pathway__c ipw = new reduivy__Individual_Pathway__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            reduivy__Individual_Program_Enrollment__c = individualProgramEnrollmentId, 
            reduivy__Academic_Term__c = academicTermId,
            reduivy__Term_Number__c = termNumber,
            reduivy__Recommended_Credits__c = recommendedCredits,
            reduivy__Max_Credits__c = maxCredits,
            reduivy__Enrollment_Method__c = enrollmentMethod,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return ipw;
    }

    /**
     * @description Init a student individual enrollment
     * @param sampleRecordCode
     * @param contactId
     * @param studyOfferingId
     * @param enrollmentStatus
     * @param attemptNumber
     * @param enrollmentDate
     * @param startDate
     * @param endDate
     * @param censusDate
     * @param creditsOffered
     * @param idvAcademicProgressId
     * @return reduivy__Individual_Enrollment__c
     */
    @NamespaceAccessible
    public static reduivy__Individual_Enrollment__c newStudentIndividualEnrollment(String sampleRecordCode, Id contactId, Id studyOfferingId, String enrollmentStatus, Decimal attemptNumber, Date enrollmentDate, Date startDate, Date endDate, Date censusDate, Decimal creditsOffered, Id idvAcademicProgressId, Id idvAcademicProfileId, Boolean byPassReq) {

        reduivy__Individual_Enrollment__c ien = new reduivy__Individual_Enrollment__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            RecordTypeId = IEN_Helper.getStudentRecordTypeId(),
            reduivy__Contact__c = contactId,
            reduivy__Study_Offering__c = studyOfferingId,
            reduivy__Enrollment_Status__c = enrollmentStatus,
            reduivy__Attempt_Number__c = attemptNumber,
            reduivy__Enrollment_Date__c = enrollmentDate,
            reduivy__Start_Date__c = startDate,
            reduivy__End_Date__c = endDate,
            reduivy__Census_Date__c = censusDate,
            reduivy__Credits_Offered__c = creditsOffered,
            reduivy__Enrollment_Type__c = IEN_Helper.ENROLLMENT_TYPE_PROGRAM,
            reduivy__Individual_Academic_Progress__c = idvAcademicProgressId,
            reduivy__Individual_Academic_Profile__c = idvAcademicProfileId,
            reduivy__Bypass_Requirement_Met__c = byPassReq,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return ien;
    }

    /**
     * @description Init a faculty individual enrollment
     * @param sampleRecordCode
     * @param contactId
     * @param studyOfferingId
     * @param enrollmentStatus
     * @return reduivy__Individual_Enrollment__c
     */
    @NamespaceAccessible
    public static reduivy__Individual_Enrollment__c newFacultyIndividualEnrollment(String sampleRecordCode, Id contactId, Id studyOfferingId, String enrollmentStatus) {

        reduivy__Individual_Enrollment__c ien = new reduivy__Individual_Enrollment__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            RecordTypeId = IEN_Helper.getFacultyRecordTypeId(),
            reduivy__Contact__c = contactId,
            reduivy__Study_Offering__c = studyOfferingId,
            reduivy__Enrollment_Status__c = enrollmentStatus,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return ien;
    }

    /**
     * @description Init an individual academic profile
     * @param sampleRecordCode
     * @param contactId
     * @param status
     * @param isPrimary
     * @return reduivy__Individual_Academic_Profile__c
     */
    @NamespaceAccessible
    public static reduivy__Individual_Academic_Profile__c newIndividualAcademicProfile(String sampleRecordCode, Id contactId, String name, String status, Boolean isPrimary) {

        reduivy__Individual_Academic_Profile__c ipf = new reduivy__Individual_Academic_Profile__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            Name = name,
            reduivy__Contact__c = contactId,
            reduivy__Status__c = status,
            reduivy__Primary__c = isPrimary,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return ipf;
    }

    /**
     * @description Init an individual academic progress
     * @param sampleRecordCode
     * @param contactId
     * @param academicTermId
     * @param individualAcademicProfileId
     * @return reduivy__Individual_Academic_Progress__c
     */
    @NamespaceAccessible
    public static reduivy__Individual_Academic_Progress__c newIndividualAcademicProgress(String sampleRecordCode, Id contactId, Id academicTermId, Id individualAcademicProfileId) {

        reduivy__Individual_Academic_Progress__c ipr = new reduivy__Individual_Academic_Progress__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            reduivy__Contact__c = contactId,
            reduivy__Academic_Term__c = academicTermId,
            reduivy__Individual_Academic_Profile__c = individualAcademicProfileId,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return ipr;
    }

    /**
     * @description Init an Transaction Order
     * @param sampleRecordCode
     * @param contactId
     * @param academicProgressId
     * @param transactionDate
     * @param status
     * @return reduivy__Transaction_Order__c
     */
    @NamespaceAccessible
    public static reduivy__Transaction_Order__c newTransactionOrder(String sampleRecordCode, Id contactId, Id academicProgressId, Date transactionDate, String status, Decimal totalAmount, Decimal outstandingAmount, Decimal paidAmount) {

        reduivy__Transaction_Order__c transactionOrder = new reduivy__Transaction_Order__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            reduivy__Contact__c = contactId,
            reduivy__Individual_Academic_Progress__c = academicProgressId,
            reduivy__Transaction_Date__c = transactionDate,
            reduivy__Status__c = status,
            reduivy__Total_Amount__c = totalAmount, 
            reduivy__Total_Outstanding_Amount__c = outstandingAmount,
            reduivy__Total_Paid_Amount__c = paidAmount,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return transactionOrder;
    }

    /**
     * @description Init an Transaction Line Item for Order Line transaction type
     * @param sampleRecordCode
     * @param transactionOrderId
     * @param itemName
     * @param itemType
     * @param unitPrice
     * @return reduivy__Transaction_Line_Item__c
     */
    @NamespaceAccessible
    public static reduivy__Transaction_Line_Item__c newTransactionOrderLine(String sampleRecordCode, Id transactionOrderId, Id studyFeeMatrixItemId, String itemName, String itemType, Decimal unitPrice, Decimal offsetAmount, Decimal outstandingAmount) {

        reduivy__Transaction_Line_Item__c transactionLineItem = new reduivy__Transaction_Line_Item__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            reduivy__Transaction_Order__c = transactionOrderId,
            reduivy__Item_Name__c = itemName,
            reduivy__Item_Type__c = itemType,
            reduivy__Quantity__c = 1,
            reduivy__Unit_Price__c = unitPrice,
            reduivy__Offset_Amount__c = offsetAmount,
            reduivy__Outstanding_Amount__c = outstandingAmount,
            reduivy__Study_Fee_Matrix_Item__c = studyFeeMatrixItemId,
            reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_DEBIT,
            reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_ORDERLINE,
            reduivy__Subtotal__c = 1 * unitPrice,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return transactionLineItem;
    }

    /**
     * @description Init an Transaction Line Item for Monetary Entry transaction type
     * @param sampleRecordCode
     * @param transactionOrderId
     * @param transactionPaymentId
     * @param itemName
     * @param itemType
     * @param paymentAmount
     * @return reduivy__Transaction_Line_Item__c
     */
    @NamespaceAccessible
    public static reduivy__Transaction_Line_Item__c newTransactionMonetaryEntry(String sampleRecordCode, Id transactionOrderId, Id transactionPaymentId, Id offsetLineItemId, Id idvFundingAllocationId, String itemName, String itemType, Decimal paymentAmount, Decimal offsetAmount, Decimal outstandingAmount) {

        reduivy__Transaction_Line_Item__c transactionLineItem = new reduivy__Transaction_Line_Item__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            reduivy__Transaction_Order__c = transactionOrderId,
            reduivy__Transaction_Payment__c = transactionPaymentId,
            reduivy__Offset_Line_Item__c = offsetLineItemId,
            reduivy__Individual_Funding_Allocation__c = idvFundingAllocationId,
            reduivy__Item_Name__c = itemName,
            reduivy__Item_Type__c = itemType,
            reduivy__Quantity__c = 1,
            reduivy__Unit_Price__c = paymentAmount,
            reduivy__Offset_Amount__c = offsetAmount,
            reduivy__Outstanding_Amount__c = outstandingAmount,
            reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_CREDIT,
            reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_MONETARYENTRY,
            reduivy__Subtotal__c = 1 * paymentAmount,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return transactionLineItem;
    }

    /**
     * @description Init an Transaction Line Item for Discount Entry transaction type
     * @param sampleRecordCode
     * @param transactionOrderId
     * @param itemName
     * @param itemType
     * @param discountAmount
     * @param idvFundingAllocationId
     * @param studyVoucherTransactionId
     * @param studyFeeMatrixItemId
     * @param individualEnrollmentId
     * @return reduivy__Transaction_Line_Item__c
     */
    @NamespaceAccessible
    public static reduivy__Transaction_Line_Item__c newTransactionDiscountEntry(String sampleRecordCode, Id transactionOrderId, String itemName, String itemType, Decimal discountAmount, Id idvFundingAllocationId, Id studyVoucherTransactionId, Id studyFeeMatrixItemId, Id individualEnrollmentId) {

        reduivy__Transaction_Line_Item__c transactionLineItem = new reduivy__Transaction_Line_Item__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            reduivy__Transaction_Order__c = transactionOrderId,
            reduivy__Item_Name__c = itemName,
            reduivy__Item_Type__c = itemType,
            reduivy__Quantity__c = 1,
            reduivy__Unit_Price__c = discountAmount,
            reduivy__Individual_Funding_Allocation__c = idvFundingAllocationId,
            reduivy__Study_Voucher_Transaction__c = studyVoucherTransactionId,
            reduivy__Study_Fee_Matrix_Item__c = studyFeeMatrixItemId,
            reduivy__Individual_Enrollment__c = individualEnrollmentId,
            reduivy__Entry_Type__c = TRL_Helper.ENTRY_TYPE_DEBIT,
            reduivy__Transaction_Type__c = TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY,
            reduivy__Subtotal__c = 1 * discountAmount,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return transactionLineItem;
    }

    /**
     * @description Init an Transaction Payment
     * @param sampleRecordCode
     * @param contactId
     * @param transactionOrderId
     * @param transactionType
     * @param idvFundingAllocationId
     * @param amount
     * @param applicableItemType
     * @return reduivy__Transaction_Payment__c
     */
    @NamespaceAccessible
    public static reduivy__Transaction_Payment__c newTransactionPayment(String sampleRecordCode, Id contactId, Id transactionOrderId, String transactionType, Id idvFundingAllocationId, Decimal amount, Decimal appliedAamount, String applicableItemType) {

        reduivy__Transaction_Payment__c transactionPayment = new reduivy__Transaction_Payment__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            reduivy__Contact__c = contactId,
            reduivy__Transaction_Order__c = transactionOrderId,
            reduivy__Transaction_Type__c = transactionType,
            reduivy__Individual_Funding_Allocation__c = idvFundingAllocationId,
            reduivy__Amount__c = amount,
            reduivy__Applied_Amount__c = appliedAamount,
            reduivy__Status__c = TRP_Helper.STATUS_ACTIVE,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        if(String.isNotBlank(applicableItemType)){
            transactionPayment.reduivy__Applicable_to_Specific_Types__c = TRP_Helper.APPLICABLE_TO_TYPES_YES;
            transactionPayment.reduivy__Applicable_Item_Type__c = applicableItemType;
        }else{
            transactionPayment.reduivy__Applicable_to_Specific_Types__c = TRP_Helper.APPLICABLE_TO_TYPES_NO;
        }

        return transactionPayment;
    }

    /**
     * @description Init an Study Funding
     * @param sampleRecordCode
     * @param type
     * @param amount
     * @param sequence
     * @param status
     * @return reduivy__Study_Funding__c
     */
    @NamespaceAccessible
    public static reduivy__Study_Funding__c newStudyFunding(String sampleRecordCode, String name, String type, Decimal amount, Decimal sequence, Decimal disbursedAmount, Decimal allocatedAmount, String status) {

        reduivy__Study_Funding__c transactionPayment = new reduivy__Study_Funding__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            Name = name,
            reduivy__Type__c = type,
            reduivy__Amount__c = amount,
            reduivy__Sequence__c = sequence,
            reduivy__Disbursed_Amount__c = disbursedAmount,
            reduivy__Status__c = status,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return transactionPayment;
    }

    /**
     * @description Init an Individual Funding Allocation
     * @param sampleRecordCode
     * @param contactId
     * @param studyFundingId
     * @param amount
     * @param status
     * @return reduivy__Individual_Funding_Allocation__c
     */
    @NamespaceAccessible
    public static reduivy__Individual_Funding_Allocation__c newIdvFundingAllocation(String sampleRecordCode, Id contactId, Id studyFundingId, Decimal amount, Date startDate, Date endDate, Decimal disbursedAmount, String status) {

        reduivy__Individual_Funding_Allocation__c idvFundingAlloc = new reduivy__Individual_Funding_Allocation__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            reduivy__Contact__c = contactId,
            reduivy__Study_Funding__c = studyFundingId,
            reduivy__Amount__c = amount,
            reduivy__Start_Date__c = startDate,
            reduivy__End_Date__c = endDate,
            reduivy__Disbursed_Amount__c = disbursedAmount,
            reduivy__Status__c = status,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return idvFundingAlloc;
    }

    ///////////////////////// new objects
    /**
     * @description Init a Study Session
     * @param sampleRecordCode
     * @param studyOfferingId
     * @param priFacultyContactId
     * @param name
     * @param capacity
     * @param bookedPlaces
     * @param reqAttendPercent
     * @param type
     * @param startDate
     * @param endDate
     * @return reduivy__Study_Session__c
     */
    @NamespaceAccessible
    public static reduivy__Study_Session__c newStudySession(String sampleRecordCode, Id studyOfferingId, Id priFacultyContactId, String name, Decimal capacity, Decimal bookedPlaces, Decimal reqAttendPercent, String type, Date startDate, Date endDate) {

        reduivy__Study_Session__c studySession = new reduivy__Study_Session__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            reduivy__Study_Offering__c = studyOfferingId,
            reduivy__Primary_Faculty__c = priFacultyContactId,
            Name = name,
            reduivy__Capacity__c = capacity,
            reduivy__Booked_Places__c = bookedPlaces,
            reduivy__Required_Attendance_Percentage__c = reqAttendPercent,
            reduivy__Type__c = type,
            reduivy__Start_Date__c = startDate,
            reduivy__End_Date__c = endDate,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return studySession;
    }

    /**
     * @description Init a Study Session Time
     * @param sampleRecordCode
     * @param studySessionId
     * @param defFacilityId
     * @param name
     * @param changeDate
     * @param dayOfWeek
     * @param recurrence
     * @param startDate
     * @param endDate
     * @param startTime
     * @param endTime
     * @return reduivy__Study_Session_Time__c
     */
    @NamespaceAccessible
    public static reduivy__Study_Session_Time__c newStudySessionTime(String sampleRecordCode, Id studySessionId, Id defFacilityId, String name, Date changeDate, String dayOfWeek, String recurrence, Date startDate, Date endDate, Time startTime, Time endTime) {

        reduivy__Study_Session_Time__c studySessionTime = new reduivy__Study_Session_Time__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            reduivy__Study_Session__c = studySessionId,
            reduivy__Default_Facility__c = defFacilityId,
            Name = name,
            reduivy__Change_Date__c = changeDate,
            reduivy__Day_of_Week__c = dayOfWeek,
            reduivy__Recurrence__c = recurrence,
            reduivy__Start_Date__c = startDate,
            reduivy__End_Date__c = endDate,
            reduivy__Start_Time__c = startTime,
            reduivy__End_Time__c = endTime,
            reduivy__Update_Settings__c = SST_Helper.UPDATE_SETTING_ALL,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return studySessionTime;
    }

    /**
     * @description Init a Study Event
     * @param sampleRecordCode
     * @param studySessionTimeId
     * @param name
     * @param location
     * @param status
     * @param startDate
     * @param endDate
     * @param startDtNtz start date non timezone
     * @param startTmNtz start time non timezone
     * @param endDtNtz end date non timezone
     * @param endTmNtz end time non timezone
     * @return reduivy__Study_Event__c
     */
    @NamespaceAccessible
    public static reduivy__Study_Event__c newSessionStudyEvent(String sampleRecordCode, Id studySessionTimeId, String name, String location, String status, Datetime startDt, Datetime endDt) {

        	reduivy__Study_Event__c studyEvent = new reduivy__Study_Event__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            reduivy__Study_Session_Time__c = studySessionTimeId,
            Name = name,
            reduivy__Type__c = 'Study Session',
            reduivy__Location__c = location,
            reduivy__Status__c = status,
            reduivy__Start__c = startDt,
            reduivy__End__c = endDt,
            reduivy__Start_Date_Non_TZ__c = startDt.date(),
            reduivy__Start_Time_Non_TZ__c = startDt.time(),
            reduivy__End_Date_Non_TZ__c = endDt.date(),
            reduivy__End_Time_Non_TZ__c = endDt.time(),
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return studyEvent;
    }

    /**
     * @description Init a student Individual Session Enrollment
     * @param sampleRecordCode
     * @param contactId
     * @param studySessionId
     * @param idvEnrollId individual enrollment id
     * @param enrollDate
     * @param enrollStatus
     * @return reduivy__Individual_Session_Enrollment__c
     */
    @NamespaceAccessible
    public static reduivy__Individual_Session_Enrollment__c newStudentIndividualSessionEnrollment(String sampleRecordCode, Id studySessionId, Id idvEnrollId, Date enrollDate, String enrollStatus) {

        	reduivy__Individual_Session_Enrollment__c idvSessionEnroll = new reduivy__Individual_Session_Enrollment__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            RecordTypeId = ISN_Helper.getStudentRecordTypeId(),
            reduivy__Study_Session__c = studySessionId,
            reduivy__Individual_Enrollment__c = idvEnrollId,
            reduivy__Enrollment_Date__c = enrollDate,
            reduivy__Enrollment_Status__c = enrollStatus,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return idvSessionEnroll;
    }

    /**
     * @description Init a faculty Individual Session Enrollment
     * @param sampleRecordCode
     * @param contactId
     * @param studySessionId
     * @param idvEnrollId individual enrollment id
     * @param enrollDate
     * @param enrollStatus
     * @return reduivy__Individual_Session_Enrollment__c
     */
    @NamespaceAccessible
    public static reduivy__Individual_Session_Enrollment__c newFacultyIndividualSessionEnrollment(String sampleRecordCode, Id studySessionId, Id idvEnrollId, String facultyRole, Date enrollDate, String enrollStatus) {

        	reduivy__Individual_Session_Enrollment__c idvSessionEnroll = new reduivy__Individual_Session_Enrollment__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            RecordTypeId = ISN_Helper.getFacultyRecordTypeId(),
            reduivy__Study_Session__c = studySessionId,
            reduivy__Individual_Enrollment__c = idvEnrollId,
            reduivy__Faculty_Role__c = facultyRole,
            reduivy__Enrollment_Date__c = enrollDate,
            reduivy__Enrollment_Status__c = enrollStatus,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return idvSessionEnroll;
    }

    /**
     * @description Init a Student Study Event Relation
     * @param sampleRecordCode
     * @param contactId
     * @param studyEventId
     * @param idvSessEnrollId individual session enrollment id
     * @param checkInTime
     * @param checkOutTime
     * @param attendStatus
     * @return 	reduivy__Study_Event_Relation__c
     */
    @NamespaceAccessible
    public static reduivy__Study_Event_Relation__c newStudentStudyEventRelation(String sampleRecordCode, Id contactId, Id studyEventId, Id idvSessEnrollId, Time checkInTime, Time checkOutTime, String attendStatus) {

        	reduivy__Study_Event_Relation__c studyEventRelation = new reduivy__Study_Event_Relation__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            reduivy__Contact__c = contactId,
            reduivy__Study_Event__c = studyEventId,
            reduivy__Individual_Session_Enrollment__c = idvSessEnrollId,
            reduivy__Check_In__c = checkInTime,
            reduivy__Check_Out__c = checkOutTime,
            reduivy__Attendance_Status__c = attendStatus,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return studyEventRelation;
    }

    /**
     * @description Init a Faculty Study Event Relation
     * @param sampleRecordCode
     * @param contactId
     * @param studyEventId
     * @param idvSessEnrollId individual session enrollment id
     * @return 	reduivy__Study_Event_Relation__c
     */
    @NamespaceAccessible
    public static reduivy__Study_Event_Relation__c newFacultyStudyEventRelation(String sampleRecordCode, Id contactId, Id studyEventId, Id idvSessEnrollId) {

        	reduivy__Study_Event_Relation__c studyEventRelation = new reduivy__Study_Event_Relation__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            reduivy__Contact__c = contactId,
            reduivy__Study_Event__c = studyEventId,
            reduivy__Individual_Session_Enrollment__c = idvSessEnrollId,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return studyEventRelation;
    }

    /**
     * @description Init a Facility Study Event Relation
     * @param sampleRecordCode
     * @param facilityId
     * @param studyEventId
     * @return 	reduivy__Study_Event_Relation__c
     */
    @NamespaceAccessible
    public static reduivy__Study_Event_Relation__c newFacilityStudyEventRelation(String sampleRecordCode, Id facilityId, Id studyEventId) {

        	reduivy__Study_Event_Relation__c studyEventRelation = new reduivy__Study_Event_Relation__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            reduivy__Facility__c = facilityId,
            reduivy__Study_Event__c = studyEventId,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return studyEventRelation;
    }

    /**
     * @description Init an Announcement
     * @param sampleRecordCode
     * @param status
     * @param notifTargetValue
     * @param notifTargetType 
     * @param notifReceiverId
     * @param notifSenderId
     * @param publishDatetime
     * @return 	reduivy__Announcement__c
     */
    @NamespaceAccessible
    public static reduivy__Announcement__c newAnnouncement(String sampleRecordCode, String details, String status, String notifTargetValue, String notifTargetType, String channelType, String notifReceiverId, String notifSenderId, Datetime publishDatetime) {

        	reduivy__Announcement__c announcement = new reduivy__Announcement__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            reduivy__Details__c = details,
            reduivy__Status__c = status,
            reduivy__Notification_Target_Value__c = notifTargetValue,
            reduivy__Notification_Target_Type__c = notifTargetType,
            reduivy__Channel_Type__c = channelType,
            reduivy__Notification_Receivers_Id__c = notifReceiverId,
            reduivy__Notification_Sender_Id__c = notifSenderId,
            reduivy__Published_Datetime__c = publishDatetime,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return announcement;
    }

    /**
     * @description Init a Holiday
     * @param sampleRecordCode
     * @param name
     * @param campusId
     * @param startDate 
     * @param endDate
     * @return 	reduivy__Holiday__c
     */
    @NamespaceAccessible
    public static reduivy__Holiday__c newHoliday(String sampleRecordCode, String name, Id campusId, Date startDate, Date endDate) {

        	reduivy__Holiday__c holiday = new reduivy__Holiday__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            Name = name,
            reduivy__Educational_Institution_Campus__c = campusId,
            reduivy__Start_Date__c = startDate,
            reduivy__End_Date__c = endDate,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return holiday;
    }

    /**
     * @description Init an Individual Enrollment Grade
     * @param sampleRecordCode
     * @param contactId
     * @param idvEnroll
     * @param academicTermId 
     * @param sgPeriodSetId study grade period setting id
     * @param studyOfferId
     * @param numGrade
     * @param letterGrade
     * @param status
     * @param gradingDate
     * @param submittedDate
     * @return 	reduivy__Individual_Enrollment_Grade__c
     */
    @NamespaceAccessible
    public static reduivy__Individual_Enrollment_Grade__c newIndividualEnrollmentGrade(String sampleRecordCode, Id contactId, Id idvEnroll, Id academicTermId, Id sgPeriodSetId, Id studyOfferId, Decimal numGrade, Decimal numGradeAdj, String letterGrade, String status, Date gradingDate, Date submittedDate) {

        	reduivy__Individual_Enrollment_Grade__c idvEnrollGrade = new reduivy__Individual_Enrollment_Grade__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            reduivy__Contact__c = contactId,
            reduivy__Individual_Enrollment__c = idvEnroll,
            reduivy__Academic_Term__c = academicTermId,
            reduivy__Study_Grade_Period_Setting__c = sgPeriodSetId,
            reduivy__Study_Offering__c = studyOfferId,
            reduivy__Numerical_Grade__c = numGrade,
            reduivy__Numerical_Grade_Adjustment__c = numGradeAdj,
            reduivy__Letter_Grade__c = letterGrade,
            reduivy__Status__c = status,
            reduivy__Grading_Date__c = gradingDate,
            reduivy__Submitted_Date__c = submittedDate,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return idvEnrollGrade;
    } //1 for each student enrollment = completed
    
    /**
     * @description Init an Individual Grade Item
     * @param sampleRecordCode
     * @param parentIdvGradeItmId
     * @param idvEnrollGradeId
     * @param name
     * @param status 
     * @param weight
     * @param numGradeAdj
     * @param numGrade
     * @param letterGrade
     * @return 	reduivy__Individual_Grade_Item__c
     */
    @NamespaceAccessible
    public static reduivy__Individual_Grade_Item__c newIndividualGradeItem(String sampleRecordCode, Id parentIdvGradeItmId, Id idvEnrollGradeId, String name, String status, Decimal weight, Decimal numGradeAdj, Decimal numGrade, String letterGrade) {

        	reduivy__Individual_Grade_Item__c idvGradeItm = new reduivy__Individual_Grade_Item__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            reduivy__Parent_Grade_Item__c = parentIdvGradeItmId,
            reduivy__Individual_Enrollment_Grade__c = idvEnrollGradeId,
            Name = name,
            reduivy__Status__c = status,
            reduivy__Weight__c = weight,
            reduivy__Numerical_Grade_Adjustment__c = numGradeAdj,
            reduivy__Numerical_Grade__c = numGrade,
            reduivy__Letter_Grade__c = letterGrade,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return idvGradeItm;
    }

    /**
     * @description Init a Study Grade Item
     * @param sampleRecordCode
     * @param parentIdvGradeItmId
     * @param studyUnitId
     * @param name
     * @param displayType 
     * @param sequence
     * @param weight
     * @return 	reduivy__Study_Grade_Item__c
     */
    @NamespaceAccessible
    public static reduivy__Study_Grade_Item__c newStudyGradeItem(String sampleRecordCode, Id parentIdvGradeItmId, Id studyUnitId, String name, String displayType, Decimal sequence, Decimal weight) {

        	reduivy__Study_Grade_Item__c studyGradeItm = new reduivy__Study_Grade_Item__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            reduivy__Parent_Grade_Item__c = parentIdvGradeItmId,
            reduivy__Study_Unit__c = studyUnitId,  
            Name = name,
            reduivy__Display_Type__c = displayType,
            reduivy__Sequence__c = sequence,
            reduivy__Weight__c = weight,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return studyGradeItm;
    }

    /**
     * @description Init a Study Grade Period Setting
     * @param sampleRecordCode
     * @param academicTermId
     * @param name
     * @param startDate 
     * @param endDate
     * @param type
     * @param weight
     * @return 	reduivy__Study_Grade_Period_Setting__c
     */
    @NamespaceAccessible
    public static reduivy__Study_Grade_Period_Setting__c newStudyGradePeriodSetting(String sampleRecordCode, Id academicTermId, String name, Date startDate, Date endDate, String type, Decimal weight) {

        	reduivy__Study_Grade_Period_Setting__c studyGradePeriodSet = new reduivy__Study_Grade_Period_Setting__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            reduivy__Academic_Term__c = academicTermId,
            Name = name,
            reduivy__Start_Date__c = startDate,
            reduivy__End_Date__c = endDate,
            reduivy__Type__c = type,
            reduivy__Weight__c = weight,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return studyGradePeriodSet;
    }

    /**
     * @description Init a job queue group
     * @param sampleRecordCode
     * @param jobOperationContext
     */
    @NamespaceAccessible
    public static reduivy__Job_Queue_Group__c newJobQueueGroup(String sampleRecordCode, String jobOperationContext) {
        reduivy__Job_Queue_Group__c jqg = new reduivy__Job_Queue_Group__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            reduivy__Job_Operation_Context__c = jobOperationContext,
            reduivy__Status__c = JQG_Helper.STATUS_DRAFT
        );

        return jqg;
    }
    
    /**
     * @description Init a Job Queue
     * @param sampleRecordCode
     * @param jobQueueGroupId
     * @param jobOperationContext
     * @param jobOperation
     * @param className
     * @param paramsString 
     * @param recordIdsString
     * @param startDatetime
     * @param endDatetime
     * @param sourceRecordId
     * @param sourceRecordName
     * @param status
     * @return 	reduivy__Job_Queue__c
     */
    @NamespaceAccessible
    public static reduivy__Job_Queue__c newJobQueue(String sampleRecordCode, Id jobQueueGroupId, String jobOperationContext, String jobOperation, String className, String paramsString, String recordIdsString, Datetime startDatetime, Datetime endDatetime, String sourceRecordId, String sourceRecordName, String status) {

        reduivy__Job_Queue__c jobQueue = new reduivy__Job_Queue__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            reduivy__Job_Queue_Group__c = jobQueueGroupId,
            reduivy__Job_Operation_Context__c = jobOperationContext,
            reduivy__Job_Operation__c = jobOperation,
            reduivy__Job_Handler_Class_Name__c = className,
            reduivy__Job_Handler_Params__c = paramsString,
            reduivy__Job_Handler_Record_Ids__c = recordIdsString,
            reduivy__Start_Datetime__c = startDatetime,
            reduivy__End_Datetime__c = endDatetime,
            reduivy__Source_Record_Id__c = sourceRecordId,
            reduivy__Source_Record_Name__c = sourceRecordName,
            reduivy__Status__c = status,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        return jobQueue;
    }

    /**
     * @description Init a System Variable
     * @param  sampleRecordCode 
     * @param  name             
     * @param  format           
     * @param  number           
     * @return reduivy__System_Variable__c
     */
    @NamespaceAccessible
    public static reduivy__System_Variable__c newSystemVariable(String sampleRecordCode, String name, String format, Integer startingNumber) {
        reduivy__System_Variable__c systemVariable = new reduivy__System_Variable__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            Name = name,
            reduivy__Format__c = format,
            reduivy__Number__c = startingNumber
        );

        return systemVariable;
    }

    /**
     * @description Init a study enrollment setting
     * @param sampleRecordCode
     * @param type
     * @param educationalInstitutionId
     * @param studyProgramId
     * @param studyUnitId
     * @param individualProgramEnrollmentId
     * @param numberValue
     * @param action
     */
    @NamespaceAccessible
    public static reduivy__Study_Enrollment_Setting__c newStudyEnrollmentSetting(String sampleRecordCode, String type, Id educationalInstitutionId, Id studyProgramId, Id studyUnitId, Id individualProgramEnrollmentId, Decimal numberValue, String action) {
        reduivy__Study_Enrollment_Setting__c ses = new reduivy__Study_Enrollment_Setting__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            reduivy__Type__c = type,
            reduivy__Educational_Institution__c = educationalInstitutionId,
            reduivy__Study_Program__c = studyProgramId,
            reduivy__Study_Unit__c = studyUnitId,
            reduivy__Individual_Program_Enrollment__c = individualProgramEnrollmentId,
            reduivy__Number__c = numberValue,
            reduivy__Action__c = action,
            reduivy__Status__c = SES_Helper.STATUS_ACTIVE
        );

        return ses;
    }

    /**
     * @description newIndividualProgramApplication description
     * @param  sampleRecordCode     sampleRecordCode description
     * @param  contactId            contactId description
     * @param  studyProgramId       studyProgramId description
     * @param  masterStudyPlanId    masterStudyPlanId description
     * @param  secondaryStudyPlanId secondaryStudyPlanId description
     * @param  studyIntakeId        studyIntakeId description
     * @return                      return description
     */
    public static reduivy__Individual_Program_Application__c newIndividualProgramApplication(String sampleRecordCode, Id contactId, Id studyProgramId, Id masterStudyPlanId, Id secondaryStudyPlanId, Id studyIntakeId) {
        reduivy__Individual_Program_Application__c ipa = new reduivy__Individual_Program_Application__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            reduivy__Contact__c = contactId,
            reduivy__Study_Program__c = studyProgramId,
            reduivy__Master_Study_Plan__c = masterStudyPlanId,
            reduivy__Secondary_Study_Plan__c = secondaryStudyPlanId,
            reduivy__Study_Intake__c = studyIntakeId,

            reduivy__Application_Date__c = System.today()
        );

        return ipa;
    }
    
    /*
    /**
     * @description newStudyIntakeGroup description
     * @param  sampleRecordCode sampleRecordCode description
     * @param  name             name description
     * @param  studentGroupType studentGroupType description
     * @param  studyIntakeId    studyIntakeId description
     * @param  capacity         capacity description
     * @param  isDefault        isDefault description
     * @return                  return description
     */ 
    public static reduivy__Study_Intake_Group__c newStudyIntakeGroup(String sampleRecordCode, String name, String studentGroupType, Id studyIntakeId, Integer capacity, Boolean isDefault) {
        reduivy__Study_Intake_Group__c sig = new reduivy__Study_Intake_Group__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            Name = name,
            reduivy__Student_Group_Type__c = studentGroupType,
            reduivy__Study_Intake__c = studyIntakeId,
            reduivy__Capacity__c = capacity,
            reduivy__Default__c = isDefault,

            reduivy__Status__c = SIG_Helper.STATUS_ACTIVE
        );

        return sig;
    }

    /**
     * @description newStudyRequirementSet description
     * @param  sampleRecordCode sampleRecordCode description
     * @param  name             name description
     * @param  code             code description
     * @param  objectName       objectName description
     * @param  contactField     contactField description
     * @param  criteria         criteria description
     * @param  description      description description
     * @return                  return description
     */
    @NamespaceAccessible
    public static reduivy__Study_Requirement_Set__c newStudyRequirementSet(String sampleRecordCode, String name, String code, String objectName, String contactField, String criteria, String description, String requirementGenerationMode) {
        reduivy__Study_Requirement_Set__c srs = new reduivy__Study_Requirement_Set__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            Name = name,
            reduivy__Code__c = code,
            reduivy__Object__c = objectName,
            reduivy__Contact_Field__c = contactField,
            reduivy__Criteria__c = criteria,
            reduivy__Description__c = description,
            reduivy__Requirement_Generation_Mode__c = requirementGenerationMode,
            
            reduivy__Status__c = SRQ_Helper.STATUS_ACTIVE
        );

        return srs;
    }

    /**
     * @description newFileUploadStudyRequirement description
     * @param  sampleRecordCode      sampleRecordCode description
     * @param  name                  name description
     * @param  code                  code description
     * @param  fileCategory          fileCategory description
     * @param  fileCount             fileCount description
     * @param  sequence              sequence description
     * @param  srsId                 srsId description
     * @param  requirementDetails    requirementDetails description
     * @param  requirementVisibility requirementVisibility description
     * @return                       return description
     */
    @NamespaceAccessible
    public static reduivy__Study_Requirement__c newFileUploadStudyRequirement(String sampleRecordCode, String name, String code, Integer sequence, Id srsId, String requirementDetails, String requirementVisibility, Integer dueDays, String fileCategory, Integer fileCount, String linkToIac){

        reduivy__Study_Requirement__c srq = new reduivy__Study_Requirement__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            Name = name,
            reduivy__Code__c = code,
            reduivy__Sequence__c = sequence,
            reduivy__Study_Requirement_Set__c = srsId,
            reduivy__Requirement_Details__c = requirementDetails,
            reduivy__Requirement_Visibility__c = requirementVisibility,
            reduivy__Due_Days__c = dueDays,
            reduivy__File_Category__c = fileCategory,
            reduivy__File_Count__c = fileCount,
            reduivy__Link_To_Individual_Achievement__c = linkToIac,

            reduivy__Requirement_Type__c = SRQ_Helper.REQUIREMENT_TYPE_FILE_UPLOAD,
            reduivy__Create_Salesforce_Task__c = false,
            reduivy__Status__c = SRQ_Helper.STATUS_ACTIVE
        );

        return srq;
    }

    /**
     * @description newActionStudyRequirement description
     * @param  sampleRecordCode      sampleRecordCode description
     * @param  name                  name description
     * @param  code                  code description
     * @param  sequence              sequence description
     * @param  srsId                 srsId description
     * @param  requirementDetails    requirementDetails description
     * @param  requirementVisibility requirementVisibility description
     * @param  dueDays               dueDays description
     * @return                       return description
     */
    @NamespaceAccessible
    public static reduivy__Study_Requirement__c newActionStudyRequirement(String sampleRecordCode, String name, String code, Integer sequence, Id srsId, String requirementDetails, String requirementVisibility, Integer dueDays) {
        
        reduivy__Study_Requirement__c srq = new reduivy__Study_Requirement__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            Name = name,
            reduivy__Code__c = code,
            reduivy__Sequence__c = sequence,
            reduivy__Study_Requirement_Set__c = srsId,
            reduivy__Requirement_Details__c = requirementDetails,
            reduivy__Requirement_Visibility__c = requirementVisibility,
            reduivy__Due_Days__c = dueDays,
            reduivy__Requirement_Type__c = SRQ_Helper.REQUIREMENT_TYPE_ACTION,
            reduivy__Create_Salesforce_Task__c = false,
            reduivy__Status__c = SRQ_Helper.STATUS_ACTIVE
        );

        return srq;
    }

    /**
     * @description newActionStudyRequirement description
     * @param  sampleRecordCode      sampleRecordCode description
     * @param  name                  name description
     * @param  code                  code description
     * @param  sequence              sequence description
     * @param  srsId                 srsId description
     * @param  requirementDetails    requirementDetails description
     * @param  requirementVisibility requirementVisibility description
     * @param  dueDays               dueDays description
     * @return                       return description
     */
    @NamespaceAccessible
    public static reduivy__Study_Requirement__c newFieldUpdateStudyRequirement(String sampleRecordCode, String name, String code, Integer sequence, Id srsId, String requirementDetails, String requirementVisibility, Integer dueDays, String objectFields, String objectRelationField) {
        
        reduivy__Study_Requirement__c srq = new reduivy__Study_Requirement__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            Name = name,
            reduivy__Code__c = code,
            reduivy__Sequence__c = sequence,
            reduivy__Study_Requirement_Set__c = srsId,
            reduivy__Requirement_Details__c = requirementDetails,
            reduivy__Requirement_Visibility__c = requirementVisibility,
            reduivy__Due_Days__c = dueDays,
            reduivy__Object_Fields__c = objectFields,
            reduivy__Object_Relation_Field__c = objectRelationField,

            reduivy__Requirement_Type__c = SRQ_Helper.REQUIREMENT_TYPE_FIELD_UPDATE,
            reduivy__Create_Salesforce_Task__c = false,
            reduivy__Status__c = SRQ_Helper.STATUS_ACTIVE
        );

        return srq;
    }

    /**
     * @description Init a log
     * @param sampleRecordCode
     * @param jobQueueGroupId
     * @param jobQueueId
     * @param name
     * @param reference
     * @param type
     */
    @NamespaceAccessible
    public static reduivy__Log__c newLog(String sampleRecordCode, Id jobQueueGroupId, Id jobQueueId, String name, String reference, String type) {
        reduivy__Log__c log = new reduivy__Log__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            reduivy__Job_Queue_Group__c = jobQueueGroupId,
            reduivy__Job_Queue__c = jobQueueId,
            Name = name,
            reduivy__Reference__c = reference,
            reduivy__Type__c = type
        );

        return log;
    }

    /**
     * @description Init a new individual success plan
     * @param sampleRecordCode
     * @param contactId
     * @param individualAcademicProfileId
     * @param name
     * @param status
     * @param startDate
     * @param endDate
     * @param summary
     */
    @NamespaceAccessible
    public static reduivy__Individual_Success_Plan__c newIndividualSuccessPlan(String sampleRecordCode, Id contactId, Id individualAcademicProfileId, String name, String status, Date startDate, Date endDate, String summary) {
        reduivy__Individual_Success_Plan__c isp = new reduivy__Individual_Success_Plan__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            reduivy__Contact__c = contactId,
            reduivy__Individual_Academic_Profile__c = individualAcademicProfileId,
            Name = name,
            reduivy__Status__c = status,
            reduivy__Start_Date__c = startDate,
            reduivy__End_Date__c = endDate,
            reduivy__Plan_Summary__c = summary
        );

        return isp;
    }

    /**
     * @description Init a new individual success plan
     * @param sampleRecordCode
     * @param contactId
     * @param individualAcademicProfileId
     * @param individualSuccessPlanId
     * @param name
     * @param category
     * @param noteDate
     * @param privacyLevel
     * @param content
     */
    @NamespaceAccessible
    public static reduivy__Individual_Support_Note__c newIndividualSupportNote(String sampleRecordCode, Id contactId, Id individualAcademicProfileId, Id individualSuccessPlanId, String name, String category, Date noteDate, String privacyLevel, String content) {
        reduivy__Individual_Support_Note__c isp = new reduivy__Individual_Support_Note__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            reduivy__Contact__c = contactId,
            reduivy__Individual_Academic_Profile__c = individualAcademicProfileId,
            reduivy__Individual_Success_Plan__c = individualSuccessPlanId,
            Name = name,
            reduivy__Note_Category__c = category,
            reduivy__Note_Date__c = noteDate,
            reduivy__Privacy_Level__c = privacyLevel,
            reduivy__Note_Content__c = content
        );

        return isp;
    }

    /**
     * @description Init a new study scoring config
     * @param sampleRecordCode
     * @param name
     * @param code
     * @param sobjectType
     * @param contactField
     * @param criteria
     */
    @NamespaceAccessible
    public static reduivy__Study_Scoring_Config__c newStudyScoringConfig(String sampleRecordCode, String name, String code, String sobjectType, String contactField, String criteria) {
        return new reduivy__Study_Scoring_Config__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            Name = name,
            reduivy__Code__c = code,
            reduivy__SObject_Type__c = sobjectType,
            reduivy__Contact_Field__c = contactField,
            reduivy__Criteria__c = criteria,
            reduivy__Status__c = SCF_Helper.STATUS_ACTIVE
        );
    }

    /**
     * @description Init a new study scoring criteria
     * @param sampleRecordCode
     * @param name
     * @param code
     * @param studyScoringConfigId
     * @param studyRequirementId
     * @param parentCriteriaId
     * @param sequence
     * @param scoreLogic
     * @param weight
     * @param maxScore
     */
    @NamespaceAccessible
    public static reduivy__Study_Scoring_Criteria__c newStudyScoringCriteria(String sampleRecordCode, String name, String code, Id studyScoringConfigId, Id studyRequirementId, Id parentCriteriaId, Integer sequence, String scoreLogic, Decimal weight, Decimal maxScore) {
        return new reduivy__Study_Scoring_Criteria__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            Name = name,
            reduivy__Code__c = code,
            reduivy__Study_Scoring_Config__c = studyScoringConfigId,
            reduivy__Study_Requirement__c = studyRequirementId,
            reduivy__Parent_Criteria__c = parentCriteriaId,
            reduivy__Sequence__c = sequence,
            reduivy__Score_Logic__c = scoreLogic,
            reduivy__Weight__c = weight,
            reduivy__Max_Score__c = maxScore,

            reduivy__Status__c = SCR_Helper.STATUS_ACTIVE
        );
    }

    /**
     * @description Init a new individual score
     * @param sampleRecordCode
     * @param name
     * @param studyScoringConfigId
     * @param ipaId
     */
    @NamespaceAccessible
    public static reduivy__Individual_Score__c newIndividualScore(String sampleRecordCode, String name, Id studyScoringConfigId, Id ipaId, Id contactId) {
        return new reduivy__Individual_Score__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            Name = name,
            reduivy__Study_Scoring_Config__c = studyScoringConfigId,
            reduivy__Individual_Program_Application__c = ipaId,
            reduivy__Contact__c = contactId,
            reduivy__Status__c = ISC_Helper.STATUS_ACTIVE
            
        );
    }

    /**
     * @description Init a new individual score detail
     * @param sampleRecordCode
     * @param name
     * @param individualScoreId
     * @param parentIndividualScoreDetailId
     * @param studyScoringCriteriaId
     * @param studyRequirementId
     * @param sequence
     * @param scoreLogic
     * @param weight
     * @param maxScore
     */
    @NamespaceAccessible
    public static reduivy__Individual_Score_Detail__c newIndividualScoreDetail(String sampleRecordCode, String name, Id individualScoreId, Id parentIndividualScoreDetailId, Id studyScoringCriteriaId, Id studyRequirementId, Integer sequence, String scoreLogic, Decimal weight, Decimal maxScore) {
        return new reduivy__Individual_Score_Detail__c(
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            Name = name,
            reduivy__Individual_Score__c = individualScoreId,
            reduivy__Parent_Score_Detail__c = parentIndividualScoreDetailId,
            reduivy__Study_Scoring_Criteria__c = studyScoringCriteriaId,
            reduivy__Study_Requirement__c = studyRequirementId,
            reduivy__Sequence__c = sequence,
            reduivy__Score_Logic__c = scoreLogic,
            reduivy__Weight__c = weight,
            reduivy__Max_Score__c = maxScore,
            reduivy__Status__c = ISD_Helper.STATUS_ACTIVE
        );
    }

    /**
     * @description Init a new admission path
     * @param sampleRecordCode
     * @param name
     * @param type
     * @param priority
     * @param studyRequirementSetCode
     */
    @NamespaceAccessible
    public static reduivy__Admission_Path__c newAdmissionPath(String sampleRecordCode, String name, String type, Integer priority, String studyRequirementSetCode) {

        return new reduivy__Admission_Path__c (
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            Name = name,
            reduivy__Type__c = type,
            reduivy__Priority__c = priority,
            reduivy__Study_Requirement_Set_Code__c = studyRequirementSetCode,
            reduivy__Status__c = ADP_Helper.STATUS_ACTIVE
        );
    }

    /**
     * @description Init a new admission path option
     * @param sampleRecordCode
     * @param name
     * @param admissionPathId
     * @param agreementRecognitionId
     */
    @NamespaceAccessible
    public static reduivy__Admission_Path_Option__c newAdmissionPathOption(String sampleRecordCode, String name, Id admissionPathId, Id agreementRecognitionId) {

        return new reduivy__Admission_Path_Option__c (
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            Name = name,
            reduivy__Admission_Path__c = admissionPathId,
            reduivy__Agreement_Recognition__c = agreementRecognitionId,
            reduivy__Status__c = ADO_Helper.STATUS_ACTIVE
        );
    }

    /**
     * @description Init a new study program admission path
     * @param sampleRecordCode
     * @param name
     * @param admissionPathId
     * @param agreementRecognitionId
     */
    @NamespaceAccessible
    public static reduivy__Study_Program_Admission_Path__c newStudyProgramAdmissionPath(String sampleRecordCode, String name, Id studyProgramId, Id admissionPathId, Id secondaryStudyPlanId) {

        return new reduivy__Study_Program_Admission_Path__c (
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            Name = name,
            reduivy__Study_Program__c = studyProgramId,
            reduivy__Admission_Path__c = admissionPathId,
            reduivy__Secondary_Study_Plan__c = secondaryStudyPlanId,
            reduivy__Status__c = SAP_Helper.STATUS_ACTIVE
        );
    }

    /**
     * @description Init a new agreement recognition
     * @param sampleRecordCode
     * @param name
     * @param agreementId
     * @param departmentId
     * @param code
     * @param fromDate
     * @param toDate
     * @param fieldOfStudy
     * @param type
     */
    @NamespaceAccessible
    public static reduivy__Agreement_Recognition__c newAgreementRecognition(String sampleRecordCode, String name, Id agreementId, Id departmentId, String code, Date fromDate, Date toDate, String fieldOfStudy, String type) {

        return new reduivy__Agreement_Recognition__c (
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            Name = name,
            reduivy__Agreement__c = agreementId,
            reduivy__Department__c = departmentId,
            reduivy__Code__c = code,
            reduivy__From_Date__c = fromDate,
            reduivy__To_Date__c = toDate,
            reduivy__Field_of_Study__c = fieldOfStudy,
            reduivy__Type__c = type,
            reduivy__Status__c = ARC_Helper.STATUS_ACTIVE,
            reduivy__Verification_Status__c = ARC_Helper.VERIFICATION_STATUS_VERIFIED
        );
    }

    @NamespaceAccessible
    public static reduivy__Agreement_Recognition_Unit__c newAgreementRecognitionUnit(String sampleRecordCode, String name, String unitCode, Id agreementRecognitionId) {
        return new reduivy__Agreement_Recognition_Unit__c(
            
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            Name = name,
            reduivy__Unit_Code__c = unitCode,
            reduivy__Agreement_Recognition__c = agreementRecognitionId,
            reduivy__Status__c = ARC_Helper.STATUS_ACTIVE,
            reduivy__Verification_Status__c = ARC_Helper.VERIFICATION_STATUS_VERIFIED,
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );
    }

    /**
     * @description Init a new individual achievement unit
     * @param sampleRecordCode
     * @param name
     * @param agreementId
     * @param departmentId
     * @param code
     * @param fromDate
     * @param toDate
     * @param fieldOfStudy
     * @param type
     */
    @NamespaceAccessible
    public static reduivy__Individual_Achievement_Unit__c newIndividualAchievementUnit(String sampleRecordCode, Id agreementRecognitionUnitId, Id individualAchievementId, String letterGrade, Decimal numericalGrade, String verificationStatus) {

        return new reduivy__Individual_Achievement_Unit__c (
            reduivy__Sample_Record_Code__c = sampleRecordCode,
            reduivy__Agreement_Recognition_Unit__c = agreementRecognitionUnitId,
            reduivy__Individual_Achievement__c = individualAchievementId,
            //reduivy__Letter_Grade__c = letterGrade,
            reduivy__Numerical_Grade__c = numericalGrade,
            reduivy__Verification_Status__c = verificationStatus,
            reduivy__Verification_Date__c = System.today(),
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );
    }


}