/**
 * @author      WDCi (Lean)
 * @date        Sept 2023
 * @group       Object Helper
 * @description User object helper class that contains the picklist option constants and object related methods
 * @changehistory
 * ISS-001813 13-12-2023 dblack - added properties and methods for user types: Guest, CspLitePortal, NonSharing
 */
global inherited sharing class USR_Helper implements SObject_Helper {
    
    /**
     * @description user mode setting for lwc attribute - Admin
     */
    public final static String USER_MODE_ADMIN = 'Admin';
    
    /**
     * @description user mode setting for lwc attribute - Student
     */
    public final static String USER_MODE_STUDENT = 'Student';
    
    /**
     * @description user mode setting for lwc attribute - Faculty
     */
    public final static String USER_MODE_FACULTY = 'Faculty';

    /**
     * @description Guest user type
     */
    public final static String USER_TYPE_GUEST = 'Guest';

    /**
     * @description CspLitePortal user type (e.g. customer community user / customer community login user)
     */
    public final static String USER_TYPE_CSPLITEPORTAL = 'CspLitePortal';

    /**
     * @description User types that doesn't support sharing
     */
    public final static Set<String> NON_SHARING_USERTYPES = new Set<String>{
        getUserTypeGuest(),
        getUserTypeCspLitePortal()
    };

    /**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel() {
        return SObjectType.User.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel() {
        return SObjectType.User.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName() {
        return SObjectType.User.getName();
    }

    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.User);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }
    
    /**
     * @description Return Guest user type
     * @return String
     */
    public static String getUserTypeGuest() {
        return USER_TYPE_GUEST;
    }

    /**
     * @description Return CspLitePortal user type
     * @return String
     */
    public static String getUserTypeCspLitePortal() {
        return USER_TYPE_CSPLITEPORTAL;
    }

    /**
     * @description Return Non-sharing user types
     * @return Set<String>
     */
    public static Set<String> getNonSharingUserTypes() {
        return NON_SHARING_USERTYPES;
    }


    /**
     * @description Return current user
     * @return User
     */
    public static User getCurrentUserInfo(Id userId) {

        if (String.isBlank(userId)) {
            userId = UserInfo.getUserId();
        }

        List<User> userList = [SELECT FirstName, LastName, ContactId
            FROM User
            WHERE Id = :userId
            WITH USER_MODE
            LIMIT 1
        ];

        User user = userList[0];

        if (String.isBlank(user.ContactId)){
            
            List<Contact> contactList = [SELECT Id, AccountId
                FROM Contact
                WHERE reduivy__User__c =: userId
                WITH USER_MODE
                LIMIT 1
            ];

            if (!contactList.isEmpty()) {
                user.ContactId = contactList.get(0).Id;
            }
        }

        return user;
    }
}