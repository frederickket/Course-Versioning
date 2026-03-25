/**
 * @author      WDCi (Lean)
 * @date        Sept 2023
 * @group       Test
 * @description Test class for REDU_Datatable_UTIL
 * @changehistory
 * ISS-002104 03-12-2024 XW - added new editable field (inline editing)
 * ISS-002736 25-11-2025 XiRouh - added enableWrapText param
 */
@IsTest
public inherited sharing class REDU_Datatable_TEST {

    @IsTest
    static void testGenerateTableMetadata(){
        
        Test.startTest();

        JSONGenerator gen = JSON.createGenerator(true);
        REDU_Datatable_UTIL.generateTableColMetadata(gen, Contact.getSObjectType(), 'FirstName;LastName;Email;MobilePhone;PhotoUrl', false, null, false, null, false, true);

        String datatableMeta = gen.getAsString();

        String expectedResult = '[ {\n' +
        '  "label" : "First Name",\n' +
        '  "fieldName" : "FirstName",\n' +
        '  "type" : "text",\n' +
        '  "sortable" : true,\n' +
        '  "editable" : false,\n' +
        '  "wrapText" : true\n' +
        '}, {\n' +
        '  "label" : "Last Name",\n' +
        '  "fieldName" : "LastName",\n' +
        '  "type" : "text",\n' +
        '  "sortable" : true,\n' +
        '  "editable" : false,\n' +
        '  "wrapText" : true\n' +
        '}, {\n' +
        '  "label" : "Email",\n' +
        '  "fieldName" : "Email",\n' +
        '  "type" : "email",\n' +
        '  "sortable" : true,\n' +
        '  "editable" : false,\n' +
        '  "wrapText" : true\n' +
        '}, {\n' +
        '  "label" : "Mobile Phone",\n' +
        '  "fieldName" : "MobilePhone",\n' +
        '  "type" : "phone",\n' +
        '  "sortable" : true,\n' +
        '  "editable" : false,\n' +
        '  "wrapText" : true\n' +
        '}, {\n' +
        '  "label" : "Photo URL",\n' +
        '  "fieldName" : "PhotoUrl",\n' +
        '  "type" : "url",\n' +
        '  "typeAttributes" : {\n' +
        '    "target" : "_self"\n' +
        '  },\n' +
        '  "sortable" : true,\n' +
        '  "editable" : false,\n' +
        '  "wrapText" : true\n' +
        '} ]';

        System.Assert.areEqual(expectedResult, datatableMeta);

        Test.stopTest();
        
    }

    @IsTest
    static void testGenerateTableMetadataWithHelpColumn(){
        
        Test.startTest();

        JSONGenerator gen = JSON.createGenerator(true);
        REDU_Datatable_UTIL.generateTableColMetadata(gen, Contact.getSObjectType(), 'FirstName;LastName;Email;MobilePhone;PhotoUrl', true, null, false, null, false, true);

        String datatableMeta = gen.getAsString();

        String expectedResult = '[ {\n' +
        '  "label" : "",\n' +
        '  "initialWidth" : 20,\n' +
        '  "hideDefaultActions" : "true",\n' +
        '  "hideLabel" : "true",\n' +
        '  "type" : "customHelpTextCol",\n' +
        '  "typeAttributes" : {\n' +
        '    "content" : {\n' +
        '      "fieldName" : "helpTextColContent"\n' +
        '    },\n' +
        '    "iconName" : {\n' +
        '      "fieldName" : "helpTextColIconName"\n' +
        '    },\n' +
        '    "iconVariant" : {\n' +
        '      "fieldName" : "helpTextColIconVariant"\n' +
        '    },\n' +
        '    "visible" : {\n' +
        '      "fieldName" : "helpTextColIconVisible"\n' +
        '    }\n' +
        '  }\n' +
        '}, {\n' +
        '  "label" : "First Name",\n' +
        '  "fieldName" : "FirstName",\n' +
        '  "type" : "text",\n' +
        '  "sortable" : true,\n' +
        '  "editable" : false,\n' +
        '  "wrapText" : true\n' +
        '}, {\n' +
        '  "label" : "Last Name",\n' +
        '  "fieldName" : "LastName",\n' +
        '  "type" : "text",\n' +
        '  "sortable" : true,\n' +
        '  "editable" : false,\n' +
        '  "wrapText" : true\n' +
        '}, {\n' +
        '  "label" : "Email",\n' +
        '  "fieldName" : "Email",\n' +
        '  "type" : "email",\n' +
        '  "sortable" : true,\n' +
        '  "editable" : false,\n' +
        '  "wrapText" : true\n' +
        '}, {\n' +
        '  "label" : "Mobile Phone",\n' +
        '  "fieldName" : "MobilePhone",\n' +
        '  "type" : "phone",\n' +
        '  "sortable" : true,\n' +
        '  "editable" : false,\n' +
        '  "wrapText" : true\n' +
        '}, {\n' +
        '  "label" : "Photo URL",\n' +
        '  "fieldName" : "PhotoUrl",\n' +
        '  "type" : "url",\n' +
        '  "typeAttributes" : {\n' +
        '    "target" : "_self"\n' +
        '  },\n' +
        '  "sortable" : true,\n' +
        '  "editable" : false,\n' +
        '  "wrapText" : true\n' +
        '} ]';

        System.Assert.areEqual(expectedResult, datatableMeta);

        Test.stopTest();
        
    }

    @IsTest
    static void testGenerateTableMetadataWithHelpColumnAndEditAction(){
        
        //Generate column metadata for datatable
        List<REDU_Datatable_UTIL.TableActionWrapper> tableActionList = new List<REDU_Datatable_UTIL.TableActionWrapper>();
        tableActionList.add(new REDU_Datatable_UTIL.TableActionWrapper('Edit', 'Edit'));

        Test.startTest();

        JSONGenerator gen = JSON.createGenerator(true);
        REDU_Datatable_UTIL.generateTableColMetadata(gen, Contact.getSObjectType(), 'FirstName;LastName;Email;MobilePhone;PhotoUrl', true, tableActionList, false, null, false, true);

        String datatableMeta = gen.getAsString();

        String expectedResult = '[ {\n' + 
        '  "label" : "",\n' + 
        '  "initialWidth" : 20,\n' + 
        '  "hideDefaultActions" : "true",\n' + 
        '  "hideLabel" : "true",\n' + 
        '  "type" : "customHelpTextCol",\n' + 
        '  "typeAttributes" : {\n' + 
        '    "content" : {\n' + 
        '      "fieldName" : "helpTextColContent"\n' + 
        '    },\n' + 
        '    "iconName" : {\n' + 
        '      "fieldName" : "helpTextColIconName"\n' + 
        '    },\n' + 
        '    "iconVariant" : {\n' + 
        '      "fieldName" : "helpTextColIconVariant"\n' + 
        '    },\n' + 
        '    "visible" : {\n' + 
        '      "fieldName" : "helpTextColIconVisible"\n' + 
        '    }\n' + 
        '  }\n' + 
        '}, {\n' + 
        '  "label" : "First Name",\n' + 
        '  "fieldName" : "FirstName",\n' + 
        '  "type" : "text",\n' + 
        '  "sortable" : true,\n' +
        '  "editable" : false,\n' +
        '  "wrapText" : true\n' +
        '}, {\n' + 
        '  "label" : "Last Name",\n' + 
        '  "fieldName" : "LastName",\n' + 
        '  "type" : "text",\n' + 
        '  "sortable" : true,\n' +
        '  "editable" : false,\n' +
        '  "wrapText" : true\n' +
        '}, {\n' + 
        '  "label" : "Email",\n' + 
        '  "fieldName" : "Email",\n' + 
        '  "type" : "email",\n' + 
        '  "sortable" : true,\n' +
        '  "editable" : false,\n' +
        '  "wrapText" : true\n' +
        '}, {\n' + 
        '  "label" : "Mobile Phone",\n' + 
        '  "fieldName" : "MobilePhone",\n' + 
        '  "type" : "phone",\n' + 
        '  "sortable" : true,\n' +
        '  "editable" : false,\n' + 
        '  "wrapText" : true\n' +
        '}, {\n' + 
        '  "label" : "Photo URL",\n' + 
        '  "fieldName" : "PhotoUrl",\n' + 
        '  "type" : "url",\n' + 
        '  "typeAttributes" : {\n' + 
        '    "target" : "_self"\n' + 
        '  },\n' + 
        '  "sortable" : true,\n' +
        '  "editable" : false,\n' +
        '  "wrapText" : true\n' +
        '}, {\n' + 
        '  "type" : "action",\n' + 
        '  "typeAttributes" : {\n' + 
        '    "rowActions" : [ {\n' + 
        '      "label" : "Edit",\n' + 
        '      "name" : "Edit"\n' + 
        '    } ]\n' + 
        '  }\n' + 
        '} ]';

        System.Assert.areEqual(expectedResult, datatableMeta);

        Test.stopTest();
        
    }

    @IsTest
    static void testGenerateTableWithClickableRefFieldMetadata(){
        
        Test.startTest();

        JSONGenerator gen = JSON.createGenerator(true);
        REDU_Datatable_UTIL.generateTableColMetadata(gen, Contact.getSObjectType(), 'AccountId;FirstName;LastName;Email;MobilePhone;PhotoUrl', false, null, true, '_blank', false, true);

        String datatableMeta = gen.getAsString();

        String expectedResult = '[ {\n' + 
        '  "label" : "Account ID",\n' + 
        '  "fieldName" : "linkAccountId",\n' + 
        '  "type" : "url",\n' + 
        '  "typeAttributes" : {\n' + 
        '    "tooltip" : {\n' + 
        '      "fieldName" : "Account.Name"\n' + 
        '    },\n' + 
        '    "label" : {\n' + 
        '      "fieldName" : "Account.Name"\n' + 
        '    },\n' + 
        '    "target" : "_blank"\n' + 
        '  },\n' + 
        '  "sortable" : true,\n' +
        '  "wrapText" : true\n' +
        '}, {\n' + 
        '  "label" : "First Name",\n' + 
        '  "fieldName" : "FirstName",\n' + 
        '  "type" : "text",\n' + 
        '  "sortable" : true,\n' +
        '  "editable" : false,\n' +
        '  "wrapText" : true\n' +
        '}, {\n' + 
        '  "label" : "Last Name",\n' + 
        '  "fieldName" : "LastName",\n' + 
        '  "type" : "text",\n' + 
        '  "sortable" : true,\n' +
        '  "editable" : false,\n' + 
        '  "wrapText" : true\n' +
        '}, {\n' + 
        '  "label" : "Email",\n' + 
        '  "fieldName" : "Email",\n' + 
        '  "type" : "email",\n' + 
        '  "sortable" : true,\n' +
        '  "editable" : false,\n' +
        '  "wrapText" : true\n' +
        '}, {\n' + 
        '  "label" : "Mobile Phone",\n' + 
        '  "fieldName" : "MobilePhone",\n' + 
        '  "type" : "phone",\n' + 
        '  "sortable" : true,\n' +
        '  "editable" : false,\n' +
        '  "wrapText" : true\n' +
        '}, {\n' + 
        '  "label" : "Photo URL",\n' + 
        '  "fieldName" : "PhotoUrl",\n' + 
        '  "type" : "url",\n' + 
        '  "typeAttributes" : {\n' + 
        '    "target" : "_blank"\n' + 
        '  },\n' + 
        '  "sortable" : true,\n' +
        '  "editable" : false,\n' +
        '  "wrapText" : true\n' +
        '} ]';

        System.Assert.areEqual(expectedResult, datatableMeta);

        Test.stopTest();
        
    }

    @IsTest
    static void testGenerateTableWithNonClickableRefFieldMetadata(){
        
        Test.startTest();

        JSONGenerator gen = JSON.createGenerator(true);
        REDU_Datatable_UTIL.generateTableColMetadata(gen, reduivy__Individual_Program_Enrollment__c.getSObjectType(), 'reduivy__Contact__c;reduivy__Contact__r.FirstName', false, null, false, '_blank', false, true);

        String datatableMeta = gen.getAsString();

        String expectedResult = '[ {\n' + 
        '  "label" : "Contact",\n' + 
        '  "fieldName" : "reduivy__Contact__r.Name",\n' + 
        '  "type" : "text",\n' + 
        '  "sortable" : true,\n' +
        '  "wrapText" : true\n' +
        '}, {\n' + 
        '  "label" : "First Name",\n' + 
        '  "fieldName" : "reduivy__Contact__r.FirstName",\n' + 
        '  "type" : "text",\n' + 
        '  "sortable" : true,\n' +
        '  "editable" : false,\n' +
        '  "wrapText" : true\n' +
        '} ]';

        System.Assert.areEqual(expectedResult, datatableMeta);

        Test.stopTest();
        
    }

    //ISS-2104
    @IsTest
    static void testGenerateTableWithInlineEditingMetadata(){
        
        Test.startTest();

        JSONGenerator gen = JSON.createGenerator(true);
        REDU_Datatable_UTIL.generateTableColMetadata(gen, Contact.getSObjectType(), 'FirstName;LastName', false, null, false, '_blank', true, true);

        String datatableMeta = gen.getAsString();

        String expectedResult = '[ {\n' + 
        '  "label" : "First Name",\n' + 
        '  "fieldName" : "FirstName",\n' + 
        '  "type" : "text",\n' + 
        '  "sortable" : true,\n' + 
        '  "editable" : true,\n' +
        '  "wrapText" : true\n' +
        '}, {\n' + 
        '  "label" : "Last Name",\n' + 
        '  "fieldName" : "LastName",\n' + 
        '  "type" : "text",\n' + 
        '  "sortable" : true,\n' +
        '  "editable" : true,\n' +
        '  "wrapText" : true\n' +
        '} ]';

        System.Assert.areEqual(expectedResult, datatableMeta);

        Test.stopTest();
        
    }

    /**
     * @description Test without multi currency
     */
    @IsTest
    static void testWithoutMultiCurrencies(){
        
        Test.startTest();

        if (ORG_Helper.isMultiCurrenciesOrg()) {
            //we won't run this test in multi currencies org as it will fail
            return;
        }

        JSONGenerator gen = JSON.createGenerator(true);
        REDU_Datatable_UTIL.generateTableColMetadata(gen, reduivy__Transaction_Line_Item__c.getSObjectType(), 'Name;reduivy__Subtotal__c', false, null, false, '_blank', true, true);

        String datatableMeta = gen.getAsString();

        String expectedResult = '[ {\n' + 
        '  "label" : "Transaction Line Item #",\n' + 
        '  "fieldName" : "Name",\n' + 
        '  "type" : "text",\n' + 
        '  "sortable" : true,\n' + 
        '  "wrapText" : true\n' +
        '}, {\n' + 
        '  "label" : "Subtotal",\n' + 
        '  "fieldName" : "reduivy__Subtotal__c",\n' + 
        '  "type" : "currency",\n' + 
        '  "sortable" : true,\n' +
        '  "cellAttributes" : {\n' +
        '    "alignment" : "left"\n' +
        '  },\n' +
        '  "typeAttributes" : { },\n' +
        '  "editable" : true,\n' +
        '  "wrapText" : true\n' +
        '} ]';

        System.Assert.areEqual(expectedResult, datatableMeta);

        Test.stopTest();
        
    }

    /**
     * @description Test with multi currency
     */
    @IsTest
    static void testWithMultiCurrencies(){
        
        Test.startTest();
        ORG_Helper.testSimulateMultiCurrencies = true;

        JSONGenerator gen = JSON.createGenerator(true);
        REDU_Datatable_UTIL.generateTableColMetadata(gen, reduivy__Transaction_Line_Item__c.getSObjectType(), 'Name;reduivy__Subtotal__c', false, null, false, '_blank', true, true);

        String datatableMeta = gen.getAsString();

        String expectedResult = '[ {\n' + 
        '  "label" : "Transaction Line Item #",\n' + 
        '  "fieldName" : "Name",\n' + 
        '  "type" : "text",\n' + 
        '  "sortable" : true,\n' + 
        '  "wrapText" : true\n' +
        '}, {\n' + 
        '  "label" : "Subtotal",\n' + 
        '  "fieldName" : "reduivy__Subtotal__c",\n' + 
        '  "type" : "currency",\n' + 
        '  "sortable" : true,\n' +
        '  "cellAttributes" : {\n' +
        '    "alignment" : "left"\n' +
        '  },\n' +
        '  "typeAttributes" : {\n' +
        '    "currencyCode" : {\n' +
        '      "fieldName" : "CurrencyIsoCode"\n' +
        '    }\n' +
        '  },\n' +
        '  "editable" : true,\n' +
        '  "wrapText" : true\n' +
        '} ]';

        System.Assert.areEqual(expectedResult, datatableMeta);

        ORG_Helper.testSimulateMultiCurrencies = false;
        Test.stopTest();
        
    }
	
}