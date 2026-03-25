BEGIN TRANSACTION;
CREATE TABLE "Account" (
	id INTEGER NOT NULL, 
	"AccountNumber" VARCHAR(255), 
	"AccountSource" VARCHAR(255), 
	"BillingCity" VARCHAR(255), 
	"BillingCountry" VARCHAR(255), 
	"BillingGeocodeAccuracy" VARCHAR(255), 
	"BillingLatitude" VARCHAR(255), 
	"BillingLongitude" VARCHAR(255), 
	"BillingPostalCode" VARCHAR(255), 
	"BillingState" VARCHAR(255), 
	"BillingStreet" VARCHAR(255), 
	"Description" VARCHAR(255), 
	"Fax" VARCHAR(255), 
	"Industry" VARCHAR(255), 
	"Name" VARCHAR(255), 
	"NumberOfEmployees" VARCHAR(255), 
	"Ownership" VARCHAR(255), 
	"Phone" VARCHAR(255), 
	"ShippingCity" VARCHAR(255), 
	"ShippingCountry" VARCHAR(255), 
	"ShippingGeocodeAccuracy" VARCHAR(255), 
	"ShippingLatitude" VARCHAR(255), 
	"ShippingLongitude" VARCHAR(255), 
	"ShippingPostalCode" VARCHAR(255), 
	"ShippingState" VARCHAR(255), 
	"ShippingStreet" VARCHAR(255), 
	"Type" VARCHAR(255), 
	"Website" VARCHAR(255), 
	"reduivy__Code__c" VARCHAR(255), 
	"reduivy__External_Id__c" VARCHAR(255), 
	"reduivy__Sample_Record_Code__c" VARCHAR(255), 
	"reduivy__Timezone__c" VARCHAR(255), 
	"ParentId" VARCHAR(255), 
	"RecordTypeId" VARCHAR(255), 
	PRIMARY KEY (id)
);
INSERT INTO "Account" VALUES(1,'','','','','','','','','','','','','','Sydney Campus','','','','','','','','','','','','','','SYDNEY','','SYDNEY','','2','0127X000001sv6eQAA');
INSERT INTO "Account" VALUES(2,'','','','','','','','','','','','','','RIO University','','','','','','','','','','','','','','RIOUNI','','RIOUNI','','','0127X000001sv6gQAA');
INSERT INTO "Account" VALUES(3,'','','','','','','','','','','','','','Business Faculty','','','','','','','','','','','','','','BUS','','BUS','','2','0127X000001sv6fQAA');
INSERT INTO "Account" VALUES(4,'','','','','','','','','','','','','','Computer Science Faculty','','','','','','','','','','','','','','COM','','COM','','2','0127X000001sv6fQAA');
INSERT INTO "Account" VALUES(5,'','','','','','','','','','','','','','Brisbane Campus','','','','','','','','','','','','','','BRISBANE','','BRISBANE','','2','0127X000001sv6eQAA');
INSERT INTO "Account" VALUES(6,'','','','','','','','','','','','','','Partner University','','','','','','','','','','','','','','EXTUNIT','','EXTUNIT','','','0127X000001sv6hQAA');
INSERT INTO "Account" VALUES(7,'','','','','','','','','','','','','','Acme Company','','','','','','','','','','','','','','','','ACME','','','0127X000001sv6iQAA');
INSERT INTO "Account" VALUES(8,'','','','','','','','','','','','','','John Doe Administrative Account','','','','','','','','','','','','','','','','','','','0127X000001sv6dQAA');
CREATE TABLE "Account_rt_mapping" (
	record_type_id VARCHAR(18) NOT NULL, 
	developer_name VARCHAR(255), 
	PRIMARY KEY (record_type_id)
);
INSERT INTO "Account_rt_mapping" VALUES('0127X000001sv6dQAA','Administrative');
INSERT INTO "Account_rt_mapping" VALUES('0127X000001sv6eQAA','Campus');
INSERT INTO "Account_rt_mapping" VALUES('0127X000001sv6fQAA','Department');
INSERT INTO "Account_rt_mapping" VALUES('0127X000001sv6gQAA','Educational_Institution');
INSERT INTO "Account_rt_mapping" VALUES('0127X000001sv6hQAA','External_Educational_Institution');
INSERT INTO "Account_rt_mapping" VALUES('0127X000001sv6iQAA','Organization');
CREATE TABLE "Contact" (
	id INTEGER NOT NULL, 
	"AssistantName" VARCHAR(255), 
	"AssistantPhone" VARCHAR(255), 
	"Birthdate" VARCHAR(255), 
	"Department" VARCHAR(255), 
	"Description" VARCHAR(255), 
	"Email" VARCHAR(255), 
	"EmailBouncedDate" VARCHAR(255), 
	"EmailBouncedReason" VARCHAR(255), 
	"Fax" VARCHAR(255), 
	"FirstName" VARCHAR(255), 
	"HomePhone" VARCHAR(255), 
	"LastName" VARCHAR(255), 
	"LeadSource" VARCHAR(255), 
	"MailingCity" VARCHAR(255), 
	"MailingCountry" VARCHAR(255), 
	"MailingGeocodeAccuracy" VARCHAR(255), 
	"MailingLatitude" VARCHAR(255), 
	"MailingLongitude" VARCHAR(255), 
	"MailingPostalCode" VARCHAR(255), 
	"MailingState" VARCHAR(255), 
	"MailingStreet" VARCHAR(255), 
	"MobilePhone" VARCHAR(255), 
	"OtherCity" VARCHAR(255), 
	"OtherCountry" VARCHAR(255), 
	"OtherGeocodeAccuracy" VARCHAR(255), 
	"OtherLatitude" VARCHAR(255), 
	"OtherLongitude" VARCHAR(255), 
	"OtherPhone" VARCHAR(255), 
	"OtherPostalCode" VARCHAR(255), 
	"OtherState" VARCHAR(255), 
	"OtherStreet" VARCHAR(255), 
	"Phone" VARCHAR(255), 
	"Salutation" VARCHAR(255), 
	"Title" VARCHAR(255), 
	"reduivy__Active__c" VARCHAR(255), 
	"reduivy__External_Id__c" VARCHAR(255), 
	"reduivy__Sample_Record_Code__c" VARCHAR(255), 
	"reduivy__Student_ID__c" VARCHAR(255), 
	"AccountId" VARCHAR(255), 
	"IndividualId" VARCHAR(255), 
	"ReportsToId" VARCHAR(255), 
	PRIMARY KEY (id)
);
INSERT INTO "Contact" VALUES(1,'','','','','','john.doe@redu.com.example','','','','John','','Doe','','','','','','','','','','','','','','','','','','','','','Mr.','','True','','','','8','','');
CREATE TABLE "ContentAsset" (
	id INTEGER NOT NULL, 
	"DeveloperName" VARCHAR(255), 
	"MasterLabel" VARCHAR(255), 
	PRIMARY KEY (id)
);
CREATE TABLE "reduivy__Facility__c" (
	id INTEGER NOT NULL, 
	"Name" VARCHAR(255), 
	"reduivy__Active__c" VARCHAR(255), 
	"reduivy__Capacity__c" VARCHAR(255), 
	"reduivy__Description__c" VARCHAR(255), 
	"reduivy__External_Id__c" VARCHAR(255), 
	"reduivy__Facility_Type__c" VARCHAR(255), 
	"reduivy__Sample_Record_Code__c" VARCHAR(255), 
	"reduivy__Campus__c" VARCHAR(255), 
	"reduivy__Parent_Facility__c" VARCHAR(255), 
	PRIMARY KEY (id)
);
INSERT INTO "reduivy__Facility__c" VALUES(1,'Sydney Campus - Block A','True','','','','Building','SYD_BLOCKA','1','');
INSERT INTO "reduivy__Facility__c" VALUES(2,'Sydney Campus - Block B','True','','','','Building','SYD_BLOCKB','1','');
INSERT INTO "reduivy__Facility__c" VALUES(3,'Brisbane Campus - Block A','True','','','','Building','BRI_BLOCKA','5','');
INSERT INTO "reduivy__Facility__c" VALUES(4,'Brisbane Campus - Block B','True','','','','Building','BRI_BLOCKB','5','');
INSERT INTO "reduivy__Facility__c" VALUES(5,'Sydney Campus - Block A - Room A1','True','20.0','','','Classroom','SYD_BLOCKA_RA1','1','1');
INSERT INTO "reduivy__Facility__c" VALUES(6,'Sydney Campus - Block A - Room A2','True','20.0','','','Classroom','SYD_BLOCKA_RA2','1','1');
INSERT INTO "reduivy__Facility__c" VALUES(7,'Sydney Campus - Block A - Hall A3','True','200.0','','','Lecture Hall','SYD_BLOCKA_HA3','1','1');
INSERT INTO "reduivy__Facility__c" VALUES(8,'Sydney Campus - Block B - Room B1','True','20.0','','','Classroom','SYD_BLOCKB_RB1','1','2');
INSERT INTO "reduivy__Facility__c" VALUES(9,'Sydney Campus - Block B - Room B2','True','20.0','','','Classroom','SYD_BLOCKB_RB2','1','2');
INSERT INTO "reduivy__Facility__c" VALUES(10,'Sydney Campus - Block B - Hall B3','True','200.0','','','Lecture Hall','SYD_BLOCKB_HB3','1','2');
INSERT INTO "reduivy__Facility__c" VALUES(11,'Brisbane Campus - Block A - Room A1','True','20.0','','','Classroom','BRI_BLOCKA_RA1','5','3');
INSERT INTO "reduivy__Facility__c" VALUES(12,'Brisbane Campus - Block A - Room A2','True','20.0','','','Classroom','BRI_BLOCKA_RA2','5','3');
INSERT INTO "reduivy__Facility__c" VALUES(13,'Brisbane Campus - Block A - Hall A3','True','200.0','','','Lecture Hall','BRI_BLOCKA_HA3','5','3');
INSERT INTO "reduivy__Facility__c" VALUES(14,'Brisbane Campus - Block B - Room B1','True','20.0','','','Classroom','BRI_BLOCKB_RB1','5','4');
INSERT INTO "reduivy__Facility__c" VALUES(15,'Brisbane Campus - Block B - Room B2','True','20.0','','','Classroom','BRI_BLOCKB_RB2','5','4');
INSERT INTO "reduivy__Facility__c" VALUES(16,'Brisbane Campus - Block B - Hall B3','True','200.0','','','Lecture Hall','BRI_BLOCKB_HB3','5','4');
CREATE TABLE "reduivy__Individual_Enrollment__c" (
	id INTEGER NOT NULL, 
	"reduivy__Attempt_Number__c" VARCHAR(255), 
	"reduivy__Census_Date__c" VARCHAR(255), 
	"reduivy__Credit_Transfer_Notes__c" VARCHAR(255), 
	"reduivy__Credit_Transfer_Received__c" VARCHAR(255), 
	"reduivy__Credits_Attempted__c" VARCHAR(255), 
	"reduivy__Credits_Earned__c" VARCHAR(255), 
	"reduivy__Credits_Offered__c" VARCHAR(255), 
	"reduivy__Due_Date__c" VARCHAR(255), 
	"reduivy__EFTSL__c" VARCHAR(255), 
	"reduivy__End_Date__c" VARCHAR(255), 
	"reduivy__Enrollment_Date__c" VARCHAR(255), 
	"reduivy__Enrollment_Status__c" VARCHAR(255), 
	"reduivy__Exclude_Credits_Earned__c" VARCHAR(255), 
	"reduivy__Exclude_GPA_Calculation__c" VARCHAR(255), 
	"reduivy__External_Id__c" VARCHAR(255), 
	"reduivy__Grade_Points__c" VARCHAR(255), 
	"reduivy__Grade_Release_Status__c" VARCHAR(255), 
	"reduivy__Grade_Result__c" VARCHAR(255), 
	"reduivy__Grade_Setting_Type__c" VARCHAR(255), 
	"reduivy__Historical_Term__c" VARCHAR(255), 
	"reduivy__Historical_Unit_Code__c" VARCHAR(255), 
	"reduivy__Historical_Unit_Name__c" VARCHAR(255), 
	"reduivy__Letter_Grade__c" VARCHAR(255), 
	"reduivy__Notes__c" VARCHAR(255), 
	"reduivy__Numerical_Grade__c" VARCHAR(255), 
	"reduivy__Sample_Record_Code__c" VARCHAR(255), 
	"reduivy__Start_Date__c" VARCHAR(255), 
	"reduivy__Waitlist_Date__c" VARCHAR(255), 
	"reduivy__Withdrawal_Date__c" VARCHAR(255), 
	"RecordTypeId" VARCHAR(255), 
	"reduivy__Contact__c" VARCHAR(255), 
	"reduivy__Study_Offering__c" VARCHAR(255), 
	PRIMARY KEY (id)
);
INSERT INTO "reduivy__Individual_Enrollment__c" VALUES(1,'1.0','','','False','','','','','','','','Enrolled','False','False','','','','','','','','','','','','','','','','0127X000001sv6kQAA','1','257');
INSERT INTO "reduivy__Individual_Enrollment__c" VALUES(2,'1.0','','','False','','','','','','','','Enrollment Requested','False','False','','','','','','','','','','','','','','','','0127X000001sv6kQAA','1','24');
INSERT INTO "reduivy__Individual_Enrollment__c" VALUES(3,'1.0','','','False','','','','','','','','Enrolled','False','False','','','','','','','','','','','','','','','','0127X000001sv6kQAA','1','75');
INSERT INTO "reduivy__Individual_Enrollment__c" VALUES(4,'1.0','','','False','','','','','','','','Not Started','False','False','','','','','','','','','','','','','','','','0127X000001sv6kQAA','1','');
INSERT INTO "reduivy__Individual_Enrollment__c" VALUES(5,'1.0','','','False','','','','','','','','Not Started','False','False','','','','','','','','','','','','','','','','0127X000001sv6kQAA','1','');
INSERT INTO "reduivy__Individual_Enrollment__c" VALUES(6,'1.0','','','False','','','','','','','','Not Started','False','False','','','','','','','','','','','','','','','','0127X000001sv6kQAA','1','');
INSERT INTO "reduivy__Individual_Enrollment__c" VALUES(7,'1.0','','','False','','','','','','','','Not Started','False','False','','','','','','','','','','','','','','','','0127X000001sv6kQAA','1','');
INSERT INTO "reduivy__Individual_Enrollment__c" VALUES(8,'1.0','','','False','','','','','','','','Not Started','False','False','','','','','','','','','','','','','','','','0127X000001sv6kQAA','1','');
INSERT INTO "reduivy__Individual_Enrollment__c" VALUES(9,'1.0','','','False','','','','','','','','','False','False','','','','','','','','','','','','','','','','0127X000001sv6kQAA','1','');
INSERT INTO "reduivy__Individual_Enrollment__c" VALUES(10,'1.0','','','False','','','','','','','','','False','False','','','','','','','','','','','','','','','','0127X000001sv6kQAA','1','');
INSERT INTO "reduivy__Individual_Enrollment__c" VALUES(11,'1.0','','','False','','','','','','','','Completed','False','False','','','','','','','','','','','','','','','','0127X000001sv6kQAA','1','279');
INSERT INTO "reduivy__Individual_Enrollment__c" VALUES(12,'1.0','','','False','','','','','','','','Not Started','False','False','','','','','','','','','','','','','','','','0127X000001sv6kQAA','1','');
INSERT INTO "reduivy__Individual_Enrollment__c" VALUES(13,'1.0','','','False','','','','','','','','','False','False','','','','','','','','','','','','','','','','0127X000001sv6kQAA','1','');
CREATE TABLE "reduivy__Individual_Enrollment__c_rt_mapping" (
	record_type_id VARCHAR(18) NOT NULL, 
	developer_name VARCHAR(255), 
	PRIMARY KEY (record_type_id)
);
INSERT INTO "reduivy__Individual_Enrollment__c_rt_mapping" VALUES('0127X000001sv6jQAA','Faculty');
INSERT INTO "reduivy__Individual_Enrollment__c_rt_mapping" VALUES('0127X000001sv6kQAA','Student');
CREATE TABLE "reduivy__Individual_Pathway__c" (
	id INTEGER NOT NULL, 
	"reduivy__All_Units_Completed__c" VARCHAR(255), 
	"reduivy__All_Units_Passed__c" VARCHAR(255), 
	"reduivy__Completed_Units__c" VARCHAR(255), 
	"reduivy__Credits_Attempted__c" VARCHAR(255), 
	"reduivy__Credits_Earned__c" VARCHAR(255), 
	"reduivy__Credits_Enrolled__c" VARCHAR(255), 
	"reduivy__Description__c" VARCHAR(255), 
	"reduivy__Enrolled_Units__c" VARCHAR(255), 
	"reduivy__Enrollment_Method__c" VARCHAR(255), 
	"reduivy__External_Id__c" VARCHAR(255), 
	"reduivy__GPA__c" VARCHAR(255), 
	"reduivy__Grade_Points__c" VARCHAR(255), 
	"reduivy__Max_Credits__c" VARCHAR(255), 
	"reduivy__Recommended_Credits__c" VARCHAR(255), 
	"reduivy__Sample_Record_Code__c" VARCHAR(255), 
	"reduivy__Term_Number__c" VARCHAR(255), 
	"reduivy__Academic_Term__c" VARCHAR(255), 
	"reduivy__Individual_Program_Enrollment__c" VARCHAR(255), 
	PRIMARY KEY (id)
);
INSERT INTO "reduivy__Individual_Pathway__c" VALUES(1,'False','False','','','','','','','Manual','','','','','','','7.0','','2');
INSERT INTO "reduivy__Individual_Pathway__c" VALUES(2,'False','False','','','','','','','Manual','','','','','50.0','','6.0','','2');
INSERT INTO "reduivy__Individual_Pathway__c" VALUES(3,'False','False','','','','','','','Manual','','','','','50.0','','2.0','7','2');
INSERT INTO "reduivy__Individual_Pathway__c" VALUES(4,'False','False','','','','','','','Manual','','','','','50.0','','3.0','8','2');
INSERT INTO "reduivy__Individual_Pathway__c" VALUES(5,'False','False','','','','','','','Manual','','','','','50.0','','5.0','','2');
INSERT INTO "reduivy__Individual_Pathway__c" VALUES(6,'False','False','','','','50.0','<strong>Lorem Ipsum</strong> is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry&#39;s standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.','','Manual','','','','','50.0','','1.0','6','2');
INSERT INTO "reduivy__Individual_Pathway__c" VALUES(7,'False','False','','','','','','','Manual','','','','','50.0','','4.0','','2');
CREATE TABLE "reduivy__Individual_Plan_Structure__c" (
	id INTEGER NOT NULL, 
	"reduivy__Allow_Pre_Enrollment__c" VARCHAR(255), 
	"reduivy__Category__c" VARCHAR(255), 
	"reduivy__Completion_Percentage__c" VARCHAR(255), 
	"reduivy__Credits_Attempted__c" VARCHAR(255), 
	"reduivy__Credits_Earned__c" VARCHAR(255), 
	"reduivy__Credits__c" VARCHAR(255), 
	"reduivy__Credits_equivalent_per_Unit__c" VARCHAR(255), 
	"reduivy__Description__c" VARCHAR(255), 
	"reduivy__External_Id__c" VARCHAR(255), 
	"reduivy__Grade_Points__c" VARCHAR(255), 
	"reduivy__Hide_in_Enrollment__c" VARCHAR(255), 
	"reduivy__Max_Credits__c" VARCHAR(255), 
	"reduivy__Primary__c" VARCHAR(255), 
	"reduivy__Requirement_Met__c" VARCHAR(255), 
	"reduivy__Revalidate_Completion__c" VARCHAR(255), 
	"reduivy__Sample_Record_Code__c" VARCHAR(255), 
	"reduivy__Sequence__c" VARCHAR(255), 
	"reduivy__Status__c" VARCHAR(255), 
	"reduivy__Units_Passed__c" VARCHAR(255), 
	"reduivy__Units_Required__c" VARCHAR(255), 
	"RecordTypeId" VARCHAR(255), 
	"reduivy__Alternate_Study_Unit__c" VARCHAR(255), 
	"reduivy__Individual_Enrollment__c" VARCHAR(255), 
	"reduivy__Individual_Pathway__c" VARCHAR(255), 
	"reduivy__Individual_Program_Enrollment__c" VARCHAR(255), 
	"reduivy__Parent_Plan_Structure__c" VARCHAR(255), 
	"reduivy__Study_Plan_Structure__c" VARCHAR(255), 
	PRIMARY KEY (id)
);
INSERT INTO "reduivy__Individual_Plan_Structure__c" VALUES(1,'False','Required','','','','','','','','','False','','False','False','False','','','Not Started','','','0127X000001sv6lQAA','','','','2','15','6');
INSERT INTO "reduivy__Individual_Plan_Structure__c" VALUES(2,'False','Required','','','','','','','','','False','','False','False','False','','','Not Started','','','0127X000001sv6lQAA','','','','2','11','7');
INSERT INTO "reduivy__Individual_Plan_Structure__c" VALUES(3,'False','Optional','','','','10.0','','','','','False','','True','True','False','','','Not Started','','','0127X000001sv6mQAA','','3','3','2','1','20');
INSERT INTO "reduivy__Individual_Plan_Structure__c" VALUES(4,'False','Optional','','','','10.0','','','','','False','','False','True','False','','','Not Started','','','0127X000001sv6mQAA','','4','','2','2','23');
INSERT INTO "reduivy__Individual_Plan_Structure__c" VALUES(5,'False','Required','','','','10.0','','','','','False','','False','True','False','','','Completed','','','0127X000001sv6mQAA','','11','6','2','18','15');
INSERT INTO "reduivy__Individual_Plan_Structure__c" VALUES(6,'False','Optional','','','','10.0','','','','','False','','False','True','False','','','Not Started','','','0127X000001sv6mQAA','','5','','2','1','22');
INSERT INTO "reduivy__Individual_Plan_Structure__c" VALUES(7,'False','Required','','','','10.0','','','','','False','','False','True','False','','','Not Started','','','0127X000001sv6mQAA','','6','','2','1','19');
INSERT INTO "reduivy__Individual_Plan_Structure__c" VALUES(8,'False','Optional','','','','10.0','','','','','False','','False','True','False','','','Not Started','','','0127X000001sv6mQAA','','12','','2','2','25');
INSERT INTO "reduivy__Individual_Plan_Structure__c" VALUES(9,'False','Optional','','','','10.0','','','','','False','','False','True','False','','','Not Started','','','0127X000001sv6mQAA','','7','','2','18','16');
INSERT INTO "reduivy__Individual_Plan_Structure__c" VALUES(10,'False','Optional','','','','10.0','','','','','False','','False','True','False','','','Not Started','','','0127X000001sv6mQAA','','8','','2','2','24');
INSERT INTO "reduivy__Individual_Plan_Structure__c" VALUES(11,'False','Required','','','','','','','','','False','','False','False','False','','','Not Started','','','0127X000001sv6lQAA','','','','2','19','3');
INSERT INTO "reduivy__Individual_Plan_Structure__c" VALUES(12,'False','Required','','','','','','','','','False','','False','False','False','','','Not Started','','','0127X000001sv6lQAA','','','','2','','12');
INSERT INTO "reduivy__Individual_Plan_Structure__c" VALUES(13,'False','Required','','','','','','','','','False','','False','False','False','','','Not Started','','','0127X000001sv6lQAA','','','','2','16','11');
INSERT INTO "reduivy__Individual_Plan_Structure__c" VALUES(14,'False','Required','','','','','','','','','False','','False','False','False','','','Not Started','','','0127X000001sv6lQAA','','','','2','11','4');
INSERT INTO "reduivy__Individual_Plan_Structure__c" VALUES(15,'False','Required','','','','','','','','','False','','False','False','False','','','Not Started','','','0127X000001sv6lQAA','','','','2','19','2');
INSERT INTO "reduivy__Individual_Plan_Structure__c" VALUES(16,'False','Required','','','','','','','','','False','','False','False','False','','','Not Started','','','0127X000001sv6lQAA','','','','2','','8');
INSERT INTO "reduivy__Individual_Plan_Structure__c" VALUES(17,'False','Required','','','','','','','','','False','','False','False','False','','','Not Started','','','0127X000001sv6lQAA','','','','2','16','10');
INSERT INTO "reduivy__Individual_Plan_Structure__c" VALUES(18,'False','Required','','','','','','','','','False','','False','False','False','','','Not Started','','','0127X000001sv6lQAA','','','','2','15','5');
INSERT INTO "reduivy__Individual_Plan_Structure__c" VALUES(19,'False','Required','','','','','','','','','False','','False','False','False','','','Not Started','','','0127X000001sv6lQAA','','','','2','','1');
INSERT INTO "reduivy__Individual_Plan_Structure__c" VALUES(20,'False','Required','','','','','','','','','False','','False','False','False','','','Not Started','','','0127X000001sv6lQAA','','','','2','16','9');
INSERT INTO "reduivy__Individual_Plan_Structure__c" VALUES(21,'False','Required','','','','','','','','','False','','False','False','False','','','Not Started','','','0127X000001sv6lQAA','','','','1','','12');
CREATE TABLE "reduivy__Individual_Plan_Structure__c_rt_mapping" (
	record_type_id VARCHAR(18) NOT NULL, 
	developer_name VARCHAR(255), 
	PRIMARY KEY (record_type_id)
);
INSERT INTO "reduivy__Individual_Plan_Structure__c_rt_mapping" VALUES('0127X000001sv6lQAA','Group');
INSERT INTO "reduivy__Individual_Plan_Structure__c_rt_mapping" VALUES('0127X000001sv6mQAA','Unit');
CREATE TABLE "reduivy__Individual_Plan_Unit_Requirement__c" (
	id INTEGER NOT NULL, 
	"Name" VARCHAR(255), 
	"reduivy__Credits__c" VARCHAR(255), 
	"reduivy__External_Id__c" VARCHAR(255), 
	"reduivy__Other__c" VARCHAR(255), 
	"reduivy__Requirement_ID__c" VARCHAR(255), 
	"reduivy__Requirement_Met__c" VARCHAR(255), 
	"reduivy__Requirement_Type__c" VARCHAR(255), 
	"reduivy__Sample_Record_Code__c" VARCHAR(255), 
	"reduivy__Individual_Plan_Unit__c" VARCHAR(255), 
	"reduivy__Required_Study_Unit__c" VARCHAR(255), 
	PRIMARY KEY (id)
);
INSERT INTO "reduivy__Individual_Plan_Unit_Requirement__c" VALUES(1,'BUS202_BUS101','','','','BUS101','False','Pre-Requisite','','3','1');
INSERT INTO "reduivy__Individual_Plan_Unit_Requirement__c" VALUES(2,'BUS202_BUS102','','','','BUS102','False','Pre-Requisite','','3','2');
INSERT INTO "reduivy__Individual_Plan_Unit_Requirement__c" VALUES(3,'BUS201_BUS101','','','','BUS101','False','Pre-Requisite','','7','1');
CREATE TABLE "reduivy__Individual_Program_Enrollment__c" (
	id INTEGER NOT NULL, 
	"reduivy__Admission_Date__c" VARCHAR(255), 
	"reduivy__Class_Standing__c" VARCHAR(255), 
	"reduivy__Class_Year__c" VARCHAR(255), 
	"reduivy__Cohort_ID__c" VARCHAR(255), 
	"reduivy__Completion_Percentage__c" VARCHAR(255), 
	"reduivy__Credits_Attempted__c" VARCHAR(255), 
	"reduivy__Credits_Earned__c" VARCHAR(255), 
	"reduivy__Eligible_To_Enroll__c" VARCHAR(255), 
	"reduivy__End_Date__c" VARCHAR(255), 
	"reduivy__Enrollment_Status__c" VARCHAR(255), 
	"reduivy__External_Id__c" VARCHAR(255), 
	"reduivy__Fee_Method__c" VARCHAR(255), 
	"reduivy__GPA__c" VARCHAR(255), 
	"reduivy__Grade_Points__c" VARCHAR(255), 
	"reduivy__Last_Payment_Date__c" VARCHAR(255), 
	"reduivy__Outstanding_Amount__c" VARCHAR(255), 
	"reduivy__Paid_Amount__c" VARCHAR(255), 
	"reduivy__Parchment_No__c" VARCHAR(255), 
	"reduivy__Pay_Upfront__c" VARCHAR(255), 
	"reduivy__Qualification_Issue_Date__c" VARCHAR(255), 
	"reduivy__Sample_Record_Code__c" VARCHAR(255), 
	"reduivy__Start_Date__c" VARCHAR(255), 
	"reduivy__Study_Mode__c" VARCHAR(255), 
	"reduivy__Study_Pathway_Mode__c" VARCHAR(255), 
	"reduivy__Study_Plan_Option_Type__c" VARCHAR(255), 
	"reduivy__Withdrawal_Date__c" VARCHAR(255), 
	"reduivy__Withdrawal_Reason__c" VARCHAR(255), 
	"RecordTypeId" VARCHAR(255), 
	"reduivy__Contact__c" VARCHAR(255), 
	"reduivy__Default_Campus__c" VARCHAR(255), 
	"reduivy__Master_Enrollment__c" VARCHAR(255), 
	"reduivy__Starting_Term__c" VARCHAR(255), 
	"reduivy__Study_Intake__c" VARCHAR(255), 
	"reduivy__Study_Pathway__c" VARCHAR(255), 
	"reduivy__Study_Plan__c" VARCHAR(255), 
	"reduivy__Study_Program__c" VARCHAR(255), 
	PRIMARY KEY (id)
);
INSERT INTO "reduivy__Individual_Program_Enrollment__c" VALUES(1,'','','','','','','','False','','In Progress','','Term','','','','','','','No','','','','Full-time','Default','','','','0127X000001sv6nQAA','1','','2','','','','1','1');
INSERT INTO "reduivy__Individual_Program_Enrollment__c" VALUES(2,'','','','A','','','','True','','In Progress','','Term','','','','','','','No','','','','Full-time','Default','','','','0127X000001sv6oQAA','1','1','','7','','1','1','1');
CREATE TABLE "reduivy__Study_Cohort_Enrollment__c" (
	id INTEGER NOT NULL, 
	"Name" VARCHAR(255), 
	"reduivy__Class_Standing__c" VARCHAR(255), 
	"reduivy__Class_Year__c" VARCHAR(255), 
	"reduivy__Cohort_ID__c" VARCHAR(255), 
	"reduivy__Enrollment_Close_Date__c" VARCHAR(255), 
	"reduivy__Enrollment_Open_Date__c" VARCHAR(255), 
	"reduivy__External_Id__c" VARCHAR(255), 
	"reduivy__Pre_enrollment_Open_Date__c" VARCHAR(255), 
	"reduivy__Sample_Record_Code__c" VARCHAR(255), 
	"reduivy__Academic_Term__c" VARCHAR(255), 
	PRIMARY KEY (id)
);
CREATE TABLE "reduivy__Individual_Program_Enrollment__c_rt_mapping" (
	record_type_id VARCHAR(18) NOT NULL, 
	developer_name VARCHAR(255), 
	PRIMARY KEY (record_type_id)
);
INSERT INTO "reduivy__Individual_Program_Enrollment__c_rt_mapping" VALUES('0127X000001sv6nQAA','Child_Enrollment');
INSERT INTO "reduivy__Individual_Program_Enrollment__c_rt_mapping" VALUES('0127X000001sv6oQAA','Master_Enrollment');
INSERT INTO "reduivy__Study_Cohort_Enrollment__c" VALUES(1,'A','','','A','2023-11-14T01:23:00.000+0000','2023-10-27T02:03:00.000+0000','','2023-10-24T02:00:00.000+0000','','7');
CREATE TABLE "reduivy__Study_Intake__c" (
	id INTEGER NOT NULL, 
	PRIMARY KEY (id)
);
CREATE TABLE "reduivy__Study_Offering__c" (
	id INTEGER NOT NULL, 
	"Name" VARCHAR(255), 
	"reduivy__About__c" VARCHAR(255), 
	"reduivy__Banner_Image_URL__c" VARCHAR(255), 
	"reduivy__Booked_Places__c" VARCHAR(255), 
	"reduivy__Capacity__c" VARCHAR(255), 
	"reduivy__Census_Date__c" VARCHAR(255), 
	"reduivy__Code__c" VARCHAR(255), 
	"reduivy__Credit_Expiry_Dates__c" VARCHAR(255), 
	"reduivy__Delivery_Method__c" VARCHAR(255), 
	"reduivy__Description__c" VARCHAR(255), 
	"reduivy__Discountable__c" VARCHAR(255), 
	"reduivy__Enable_Guest_Registrations__c" VARCHAR(255), 
	"reduivy__Enable_Self_Enrollment__c" VARCHAR(255), 
	"reduivy__Enable_Waitlist__c" VARCHAR(255), 
	"reduivy__End_Date__c" VARCHAR(255), 
	"reduivy__Enrollment_Close_Date__c" VARCHAR(255), 
	"reduivy__Enrollment_Open_Date__c" VARCHAR(255), 
	"reduivy__Entry_Requirements__c" VARCHAR(255), 
	"reduivy__External_Id__c" VARCHAR(255), 
	"reduivy__Fee_Amount__c" VARCHAR(255), 
	"reduivy__Field_of_Study__c" VARCHAR(255), 
	"reduivy__Listing_Image_URL__c" VARCHAR(255), 
	"reduivy__Listing_Status__c" VARCHAR(255), 
	"reduivy__Number_of_Credits__c" VARCHAR(255), 
	"reduivy__Offering_Type__c" VARCHAR(255), 
	"reduivy__Pre_enrollment_Open_Date__c" VARCHAR(255), 
	"reduivy__Sample_Record_Code__c" VARCHAR(255), 
	"reduivy__Scheduled_Duration_Unit__c" VARCHAR(255), 
	"reduivy__Scheduled_Duration__c" VARCHAR(255), 
	"reduivy__Start_Date__c" VARCHAR(255), 
	"reduivy__Status_Override__c" VARCHAR(255), 
	"reduivy__Unlimited_Places__c" VARCHAR(255), 
	"reduivy__Waitlist_Places__c" VARCHAR(255), 
	"reduivy__Academic_Term__c" VARCHAR(255), 
	"reduivy__Campus__c" VARCHAR(255), 
	"reduivy__Primary_Faculty__c" VARCHAR(255), 
	"reduivy__Study_Unit__c" VARCHAR(255), 
	PRIMARY KEY (id)
);
INSERT INTO "reduivy__Study_Offering__c" VALUES(1,'BUS102_CYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2023-06-30','','','','','','','','Draft','','Unit','','BUS102_CYT1_SYDNEY','Hour','','2023-02-06','','False','','6','1','','2');
INSERT INTO "reduivy__Study_Offering__c" VALUES(2,'BUS102_CYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2023-06-30','','','','','','','','Draft','','Unit','','BUS102_CYT1_BRISBANE','Hour','','2023-02-06','','False','','6','5','','2');
INSERT INTO "reduivy__Study_Offering__c" VALUES(3,'BUS102_CYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2023-12-08','','','','','','','','Draft','','Unit','','BUS102_CYT2_SYDNEY','Hour','','2023-07-31','','False','','7','1','','2');
INSERT INTO "reduivy__Study_Offering__c" VALUES(4,'BUS102_CYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2023-12-08','','','','','','','','Draft','','Unit','','BUS102_CYT2_BRISBANE','Hour','','2023-07-31','','False','','7','5','','2');
INSERT INTO "reduivy__Study_Offering__c" VALUES(5,'BUS102_NYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2024-02-05','','','','','','','','Draft','','Unit','','BUS102_NYT1_SYDNEY','Hour','','2024-02-05','','False','','8','1','','2');
INSERT INTO "reduivy__Study_Offering__c" VALUES(6,'BUS102_NYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2024-02-05','','','','','','','','Draft','','Unit','','BUS102_NYT1_BRISBANE','Hour','','2024-02-05','','False','','8','5','','2');
INSERT INTO "reduivy__Study_Offering__c" VALUES(7,'BUS102_NYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2024-12-06','','','','','','','','Draft','','Unit','','BUS102_NYT2_SYDNEY','Hour','','2024-07-29','','False','','9','1','','2');
INSERT INTO "reduivy__Study_Offering__c" VALUES(8,'BUS102_NYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2024-12-06','','','','','','','','Draft','','Unit','','BUS102_NYT2_BRISBANE','Hour','','2024-07-29','','False','','9','5','','2');
INSERT INTO "reduivy__Study_Offering__c" VALUES(9,'BUS103_PYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2022-07-01','','','','','','','','Draft','','Unit','','BUS103_PYT1_SYDNEY','Hour','','2022-02-07','','False','','4','1','','3');
INSERT INTO "reduivy__Study_Offering__c" VALUES(10,'BUS103_PYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2022-07-01','','','','','','','','Draft','','Unit','','BUS103_PYT1_BRISBANE','Hour','','2022-02-07','','False','','4','5','','3');
INSERT INTO "reduivy__Study_Offering__c" VALUES(11,'BUS103_PYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2022-12-09','','','','','','','','Draft','','Unit','','BUS103_PYT2_SYDNEY','Hour','','2022-08-01','','False','','5','1','','3');
INSERT INTO "reduivy__Study_Offering__c" VALUES(12,'BUS103_PYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2022-12-09','','','','','','','','Draft','','Unit','','BUS103_PYT2_BRISBANE','Hour','','2022-08-01','','False','','5','5','','3');
INSERT INTO "reduivy__Study_Offering__c" VALUES(13,'BUS103_CYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2023-06-30','','','','','','','','Draft','','Unit','','BUS103_CYT1_SYDNEY','Hour','','2023-02-06','','False','','6','1','','3');
INSERT INTO "reduivy__Study_Offering__c" VALUES(14,'BUS103_CYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2023-06-30','','','','','','','','Draft','','Unit','','BUS103_CYT1_BRISBANE','Hour','','2023-02-06','','False','','6','5','','3');
INSERT INTO "reduivy__Study_Offering__c" VALUES(15,'BUS103_CYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2023-12-08','','','','','','','','Draft','','Unit','','BUS103_CYT2_SYDNEY','Hour','','2023-07-31','','False','','7','1','','3');
INSERT INTO "reduivy__Study_Offering__c" VALUES(16,'BUS103_CYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2023-12-08','','','','','','','','Draft','','Unit','','BUS103_CYT2_BRISBANE','Hour','','2023-07-31','','False','','7','5','','3');
INSERT INTO "reduivy__Study_Offering__c" VALUES(17,'BUS103_NYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2024-02-05','','','','','','','','Draft','','Unit','','BUS103_NYT1_SYDNEY','Hour','','2024-02-05','','False','','8','1','','3');
INSERT INTO "reduivy__Study_Offering__c" VALUES(18,'BUS103_NYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2024-02-05','','','','','','','','Draft','','Unit','','BUS103_NYT1_BRISBANE','Hour','','2024-02-05','','False','','8','5','','3');
INSERT INTO "reduivy__Study_Offering__c" VALUES(19,'BUS103_NYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2024-12-06','','','','','','','','Draft','','Unit','','BUS103_NYT2_SYDNEY','Hour','','2024-07-29','','False','','9','1','','3');
INSERT INTO "reduivy__Study_Offering__c" VALUES(20,'BUS103_NYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2024-12-06','','','','','','','','Draft','','Unit','','BUS103_NYT2_BRISBANE','Hour','','2024-07-29','','False','','9','5','','3');
INSERT INTO "reduivy__Study_Offering__c" VALUES(21,'MKT101_PYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2022-07-01','','','','','','','','Draft','','Unit','','MKT101_PYT1_SYDNEY','Hour','','2022-02-07','','False','','4','1','','4');
INSERT INTO "reduivy__Study_Offering__c" VALUES(22,'MKT101_PYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2022-07-01','','','','','','','','Draft','','Unit','','MKT101_PYT1_BRISBANE','Hour','','2022-02-07','','False','','4','5','','4');
INSERT INTO "reduivy__Study_Offering__c" VALUES(23,'MKT101_PYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2022-12-09','','','','','','','','Draft','','Unit','','MKT101_PYT2_SYDNEY','Hour','','2022-08-01','','False','','5','1','','4');
INSERT INTO "reduivy__Study_Offering__c" VALUES(24,'MKT101_CYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2023-12-08','','','','','','','','Draft','','Unit','','MKT101_CYT2_SYDNEY','Hour','','2023-07-31','','False','','7','1','','4');
INSERT INTO "reduivy__Study_Offering__c" VALUES(25,'MKT101_PYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2022-12-09','','','','','','','','Draft','','Unit','','MKT101_PYT2_BRISBANE','Hour','','2022-08-01','','False','','5','5','','4');
INSERT INTO "reduivy__Study_Offering__c" VALUES(26,'MKT101_CYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2023-06-30','','','','','','','','Draft','','Unit','','MKT101_CYT1_SYDNEY','Hour','','2023-02-06','','False','','6','1','','4');
INSERT INTO "reduivy__Study_Offering__c" VALUES(27,'MKT101_CYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2023-06-30','','','','','','','','Draft','','Unit','','MKT101_CYT1_BRISBANE','Hour','','2023-02-06','','False','','6','5','','4');
INSERT INTO "reduivy__Study_Offering__c" VALUES(28,'MKT101_CYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2023-12-08','','','','','','','','Draft','','Unit','','MKT101_CYT2_BRISBANE','Hour','','2023-07-31','','False','','7','5','','4');
INSERT INTO "reduivy__Study_Offering__c" VALUES(29,'MKT101_NYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2024-02-05','','','','','','','','Draft','','Unit','','MKT101_NYT1_SYDNEY','Hour','','2024-02-05','','False','','8','1','','4');
INSERT INTO "reduivy__Study_Offering__c" VALUES(30,'MKT101_NYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2024-02-05','','','','','','','','Draft','','Unit','','MKT101_NYT1_BRISBANE','Hour','','2024-02-05','','False','','8','5','','4');
INSERT INTO "reduivy__Study_Offering__c" VALUES(31,'MKT101_NYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2024-12-06','','','','','','','','Draft','','Unit','','MKT101_NYT2_SYDNEY','Hour','','2024-07-29','','False','','9','1','','4');
INSERT INTO "reduivy__Study_Offering__c" VALUES(32,'MKT101_NYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2024-12-06','','','','','','','','Draft','','Unit','','MKT101_NYT2_BRISBANE','Hour','','2024-07-29','','False','','9','5','','4');
INSERT INTO "reduivy__Study_Offering__c" VALUES(33,'MKT102_PYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2022-07-01','','','','','','','','Draft','','Unit','','MKT102_PYT1_SYDNEY','Hour','','2022-02-07','','False','','4','1','','5');
INSERT INTO "reduivy__Study_Offering__c" VALUES(34,'MKT102_PYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2022-07-01','','','','','','','','Draft','','Unit','','MKT102_PYT1_BRISBANE','Hour','','2022-02-07','','False','','4','5','','5');
INSERT INTO "reduivy__Study_Offering__c" VALUES(35,'MKT102_PYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2022-12-09','','','','','','','','Draft','','Unit','','MKT102_PYT2_SYDNEY','Hour','','2022-08-01','','False','','5','1','','5');
INSERT INTO "reduivy__Study_Offering__c" VALUES(36,'MKT102_PYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2022-12-09','','','','','','','','Draft','','Unit','','MKT102_PYT2_BRISBANE','Hour','','2022-08-01','','False','','5','5','','5');
INSERT INTO "reduivy__Study_Offering__c" VALUES(37,'MKT102_CYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2023-06-30','','','','','','','','Draft','','Unit','','MKT102_CYT1_SYDNEY','Hour','','2023-02-06','','False','','6','1','','5');
INSERT INTO "reduivy__Study_Offering__c" VALUES(38,'MKT102_CYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2023-06-30','','','','','','','','Draft','','Unit','','MKT102_CYT1_BRISBANE','Hour','','2023-02-06','','False','','6','5','','5');
INSERT INTO "reduivy__Study_Offering__c" VALUES(39,'MKT102_CYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2023-12-08','','','','','','','','Draft','','Unit','','MKT102_CYT2_SYDNEY','Hour','','2023-07-31','','False','','7','1','','5');
INSERT INTO "reduivy__Study_Offering__c" VALUES(40,'MKT102_CYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2023-12-08','','','','','','','','Draft','','Unit','','MKT102_CYT2_BRISBANE','Hour','','2023-07-31','','False','','7','5','','5');
INSERT INTO "reduivy__Study_Offering__c" VALUES(41,'MKT102_NYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2024-02-05','','','','','','','','Draft','','Unit','','MKT102_NYT1_SYDNEY','Hour','','2024-02-05','','False','','8','1','','5');
INSERT INTO "reduivy__Study_Offering__c" VALUES(42,'MKT102_NYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2024-02-05','','','','','','','','Draft','','Unit','','MKT102_NYT1_BRISBANE','Hour','','2024-02-05','','False','','8','5','','5');
INSERT INTO "reduivy__Study_Offering__c" VALUES(43,'MKT102_NYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2024-12-06','','','','','','','','Draft','','Unit','','MKT102_NYT2_SYDNEY','Hour','','2024-07-29','','False','','9','1','','5');
INSERT INTO "reduivy__Study_Offering__c" VALUES(44,'MKT102_NYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2024-12-06','','','','','','','','Draft','','Unit','','MKT102_NYT2_BRISBANE','Hour','','2024-07-29','','False','','9','5','','5');
INSERT INTO "reduivy__Study_Offering__c" VALUES(45,'MKT103_PYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2022-07-01','','','','','','','','Draft','','Unit','','MKT103_PYT1_SYDNEY','Hour','','2022-02-07','','False','','4','1','','6');
INSERT INTO "reduivy__Study_Offering__c" VALUES(46,'MKT103_PYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2022-07-01','','','','','','','','Draft','','Unit','','MKT103_PYT1_BRISBANE','Hour','','2022-02-07','','False','','4','5','','6');
INSERT INTO "reduivy__Study_Offering__c" VALUES(47,'MKT103_CYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2023-06-30','','','','','','','','Draft','','Unit','','MKT103_CYT1_BRISBANE','Hour','','2023-02-06','','False','','6','5','','6');
INSERT INTO "reduivy__Study_Offering__c" VALUES(48,'MKT103_PYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2022-12-09','','','','','','','','Draft','','Unit','','MKT103_PYT2_SYDNEY','Hour','','2022-08-01','','False','','5','1','','6');
INSERT INTO "reduivy__Study_Offering__c" VALUES(49,'MKT103_PYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2022-12-09','','','','','','','','Draft','','Unit','','MKT103_PYT2_BRISBANE','Hour','','2022-08-01','','False','','5','5','','6');
INSERT INTO "reduivy__Study_Offering__c" VALUES(50,'MKT103_CYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2023-06-30','','','','','','','','Draft','','Unit','','MKT103_CYT1_SYDNEY','Hour','','2023-02-06','','False','','6','1','','6');
INSERT INTO "reduivy__Study_Offering__c" VALUES(51,'MKT103_CYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2023-12-08','','','','','','','','Draft','','Unit','','MKT103_CYT2_SYDNEY','Hour','','2023-07-31','','False','','7','1','','6');
INSERT INTO "reduivy__Study_Offering__c" VALUES(52,'MKT103_CYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2023-12-08','','','','','','','','Draft','','Unit','','MKT103_CYT2_BRISBANE','Hour','','2023-07-31','','False','','7','5','','6');
INSERT INTO "reduivy__Study_Offering__c" VALUES(53,'MKT103_NYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2024-02-05','','','','','','','','Draft','','Unit','','MKT103_NYT1_SYDNEY','Hour','','2024-02-05','','False','','8','1','','6');
INSERT INTO "reduivy__Study_Offering__c" VALUES(54,'MKT103_NYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2024-02-05','','','','','','','','Draft','','Unit','','MKT103_NYT1_BRISBANE','Hour','','2024-02-05','','False','','8','5','','6');
INSERT INTO "reduivy__Study_Offering__c" VALUES(55,'MKT103_NYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2024-12-06','','','','','','','','Draft','','Unit','','MKT103_NYT2_SYDNEY','Hour','','2024-07-29','','False','','9','1','','6');
INSERT INTO "reduivy__Study_Offering__c" VALUES(56,'MKT103_NYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2024-12-06','','','','','','','','Draft','','Unit','','MKT103_NYT2_BRISBANE','Hour','','2024-07-29','','False','','9','5','','6');
INSERT INTO "reduivy__Study_Offering__c" VALUES(57,'BUS201_PYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2022-07-01','','','','','','','','Draft','','Unit','','BUS201_PYT1_SYDNEY','Hour','','2022-02-07','','False','','4','1','','7');
INSERT INTO "reduivy__Study_Offering__c" VALUES(58,'BUS201_PYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2022-07-01','','','','','','','','Draft','','Unit','','BUS201_PYT1_BRISBANE','Hour','','2022-02-07','','False','','4','5','','7');
INSERT INTO "reduivy__Study_Offering__c" VALUES(59,'BUS201_PYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2022-12-09','','','','','','','','Draft','','Unit','','BUS201_PYT2_SYDNEY','Hour','','2022-08-01','','False','','5','1','','7');
INSERT INTO "reduivy__Study_Offering__c" VALUES(60,'BUS201_PYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2022-12-09','','','','','','','','Draft','','Unit','','BUS201_PYT2_BRISBANE','Hour','','2022-08-01','','False','','5','5','','7');
INSERT INTO "reduivy__Study_Offering__c" VALUES(61,'BUS201_CYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2023-06-30','','','','','','','','Draft','','Unit','','BUS201_CYT1_SYDNEY','Hour','','2023-02-06','','False','','6','1','','7');
INSERT INTO "reduivy__Study_Offering__c" VALUES(62,'BUS201_CYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2023-06-30','','','','','','','','Draft','','Unit','','BUS201_CYT1_BRISBANE','Hour','','2023-02-06','','False','','6','5','','7');
INSERT INTO "reduivy__Study_Offering__c" VALUES(63,'BUS201_CYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2023-12-08','','','','','','','','Draft','','Unit','','BUS201_CYT2_SYDNEY','Hour','','2023-07-31','','False','','7','1','','7');
INSERT INTO "reduivy__Study_Offering__c" VALUES(64,'BUS201_CYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2023-12-08','','','','','','','','Draft','','Unit','','BUS201_CYT2_BRISBANE','Hour','','2023-07-31','','False','','7','5','','7');
INSERT INTO "reduivy__Study_Offering__c" VALUES(65,'BUS201_NYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2024-02-05','','','','','','','','Draft','','Unit','','BUS201_NYT1_SYDNEY','Hour','','2024-02-05','','False','','8','1','','7');
INSERT INTO "reduivy__Study_Offering__c" VALUES(66,'BUS201_NYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2024-02-05','','','','','','','','Draft','','Unit','','BUS201_NYT1_BRISBANE','Hour','','2024-02-05','','False','','8','5','','7');
INSERT INTO "reduivy__Study_Offering__c" VALUES(67,'BUS201_NYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2024-12-06','','','','','','','','Draft','','Unit','','BUS201_NYT2_SYDNEY','Hour','','2024-07-29','','False','','9','1','','7');
INSERT INTO "reduivy__Study_Offering__c" VALUES(68,'BUS201_NYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2024-12-06','','','','','','','','Draft','','Unit','','BUS201_NYT2_BRISBANE','Hour','','2024-07-29','','False','','9','5','','7');
INSERT INTO "reduivy__Study_Offering__c" VALUES(69,'BUS202_PYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2022-07-01','','','','','','','','Draft','','Unit','','BUS202_PYT1_SYDNEY','Hour','','2022-02-07','','False','','4','1','','8');
INSERT INTO "reduivy__Study_Offering__c" VALUES(70,'BUS202_CYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2023-06-30','','','','','','','','Draft','','Unit','','BUS202_CYT1_SYDNEY','Hour','','2023-02-06','','False','','6','1','','8');
INSERT INTO "reduivy__Study_Offering__c" VALUES(71,'BUS202_PYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2022-07-01','','','','','','','','Draft','','Unit','','BUS202_PYT1_BRISBANE','Hour','','2022-02-07','','False','','4','5','','8');
INSERT INTO "reduivy__Study_Offering__c" VALUES(72,'BUS202_PYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2022-12-09','','','','','','','','Draft','','Unit','','BUS202_PYT2_SYDNEY','Hour','','2022-08-01','','False','','5','1','','8');
INSERT INTO "reduivy__Study_Offering__c" VALUES(73,'BUS202_PYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2022-12-09','','','','','','','','Draft','','Unit','','BUS202_PYT2_BRISBANE','Hour','','2022-08-01','','False','','5','5','','8');
INSERT INTO "reduivy__Study_Offering__c" VALUES(74,'BUS202_CYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2023-06-30','','','','','','','','Draft','','Unit','','BUS202_CYT1_BRISBANE','Hour','','2023-02-06','','False','','6','5','','8');
INSERT INTO "reduivy__Study_Offering__c" VALUES(75,'BUS202_CYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2023-12-08','','','','','','','','Draft','','Unit','','BUS202_CYT2_SYDNEY','Hour','','2023-07-31','','False','','7','1','','8');
INSERT INTO "reduivy__Study_Offering__c" VALUES(76,'BUS202_CYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2023-12-08','','','','','','','','Draft','','Unit','','BUS202_CYT2_BRISBANE','Hour','','2023-07-31','','False','','7','5','','8');
INSERT INTO "reduivy__Study_Offering__c" VALUES(77,'BUS202_NYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2024-02-05','','','','','','','','Draft','','Unit','','BUS202_NYT1_SYDNEY','Hour','','2024-02-05','','False','','8','1','','8');
INSERT INTO "reduivy__Study_Offering__c" VALUES(78,'BUS202_NYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2024-02-05','','','','','','','','Draft','','Unit','','BUS202_NYT1_BRISBANE','Hour','','2024-02-05','','False','','8','5','','8');
INSERT INTO "reduivy__Study_Offering__c" VALUES(79,'BUS202_NYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2024-12-06','','','','','','','','Draft','','Unit','','BUS202_NYT2_SYDNEY','Hour','','2024-07-29','','False','','9','1','','8');
INSERT INTO "reduivy__Study_Offering__c" VALUES(80,'BUS202_NYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2024-12-06','','','','','','','','Draft','','Unit','','BUS202_NYT2_BRISBANE','Hour','','2024-07-29','','False','','9','5','','8');
INSERT INTO "reduivy__Study_Offering__c" VALUES(81,'BUS203_PYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2022-07-01','','','','','','','','Draft','','Unit','','BUS203_PYT1_SYDNEY','Hour','','2022-02-07','','False','','4','1','','9');
INSERT INTO "reduivy__Study_Offering__c" VALUES(82,'BUS203_PYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2022-07-01','','','','','','','','Draft','','Unit','','BUS203_PYT1_BRISBANE','Hour','','2022-02-07','','False','','4','5','','9');
INSERT INTO "reduivy__Study_Offering__c" VALUES(83,'BUS203_PYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2022-12-09','','','','','','','','Draft','','Unit','','BUS203_PYT2_SYDNEY','Hour','','2022-08-01','','False','','5','1','','9');
INSERT INTO "reduivy__Study_Offering__c" VALUES(84,'BUS203_PYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2022-12-09','','','','','','','','Draft','','Unit','','BUS203_PYT2_BRISBANE','Hour','','2022-08-01','','False','','5','5','','9');
INSERT INTO "reduivy__Study_Offering__c" VALUES(85,'BUS203_CYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2023-06-30','','','','','','','','Draft','','Unit','','BUS203_CYT1_SYDNEY','Hour','','2023-02-06','','False','','6','1','','9');
INSERT INTO "reduivy__Study_Offering__c" VALUES(86,'BUS203_CYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2023-06-30','','','','','','','','Draft','','Unit','','BUS203_CYT1_BRISBANE','Hour','','2023-02-06','','False','','6','5','','9');
INSERT INTO "reduivy__Study_Offering__c" VALUES(87,'BUS203_CYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2023-12-08','','','','','','','','Draft','','Unit','','BUS203_CYT2_SYDNEY','Hour','','2023-07-31','','False','','7','1','','9');
INSERT INTO "reduivy__Study_Offering__c" VALUES(88,'BUS203_CYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2023-12-08','','','','','','','','Draft','','Unit','','BUS203_CYT2_BRISBANE','Hour','','2023-07-31','','False','','7','5','','9');
INSERT INTO "reduivy__Study_Offering__c" VALUES(89,'BUS203_NYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2024-02-05','','','','','','','','Draft','','Unit','','BUS203_NYT1_SYDNEY','Hour','','2024-02-05','','False','','8','1','','9');
INSERT INTO "reduivy__Study_Offering__c" VALUES(90,'BUS203_NYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2024-02-05','','','','','','','','Draft','','Unit','','BUS203_NYT1_BRISBANE','Hour','','2024-02-05','','False','','8','5','','9');
INSERT INTO "reduivy__Study_Offering__c" VALUES(91,'BUS203_NYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2024-12-06','','','','','','','','Draft','','Unit','','BUS203_NYT2_SYDNEY','Hour','','2024-07-29','','False','','9','1','','9');
INSERT INTO "reduivy__Study_Offering__c" VALUES(92,'BUS203_NYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2024-12-06','','','','','','','','Draft','','Unit','','BUS203_NYT2_BRISBANE','Hour','','2024-07-29','','False','','9','5','','9');
INSERT INTO "reduivy__Study_Offering__c" VALUES(93,'MGT301_PYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2022-12-09','','','','','','','','Draft','','Unit','','MGT301_PYT2_BRISBANE','Hour','','2022-08-01','','False','','5','5','','10');
INSERT INTO "reduivy__Study_Offering__c" VALUES(94,'MGT301_PYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2022-07-01','','','','','','','','Draft','','Unit','','MGT301_PYT1_SYDNEY','Hour','','2022-02-07','','False','','4','1','','10');
INSERT INTO "reduivy__Study_Offering__c" VALUES(95,'MGT301_PYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2022-07-01','','','','','','','','Draft','','Unit','','MGT301_PYT1_BRISBANE','Hour','','2022-02-07','','False','','4','5','','10');
INSERT INTO "reduivy__Study_Offering__c" VALUES(96,'MGT301_PYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2022-12-09','','','','','','','','Draft','','Unit','','MGT301_PYT2_SYDNEY','Hour','','2022-08-01','','False','','5','1','','10');
INSERT INTO "reduivy__Study_Offering__c" VALUES(97,'MGT301_CYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2023-06-30','','','','','','','','Draft','','Unit','','MGT301_CYT1_SYDNEY','Hour','','2023-02-06','','False','','6','1','','10');
INSERT INTO "reduivy__Study_Offering__c" VALUES(98,'MGT301_CYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2023-06-30','','','','','','','','Draft','','Unit','','MGT301_CYT1_BRISBANE','Hour','','2023-02-06','','False','','6','5','','10');
INSERT INTO "reduivy__Study_Offering__c" VALUES(99,'MGT301_CYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2023-12-08','','','','','','','','Draft','','Unit','','MGT301_CYT2_SYDNEY','Hour','','2023-07-31','','False','','7','1','','10');
INSERT INTO "reduivy__Study_Offering__c" VALUES(100,'MGT301_CYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2023-12-08','','','','','','','','Draft','','Unit','','MGT301_CYT2_BRISBANE','Hour','','2023-07-31','','False','','7','5','','10');
INSERT INTO "reduivy__Study_Offering__c" VALUES(101,'MGT301_NYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2024-02-05','','','','','','','','Draft','','Unit','','MGT301_NYT1_SYDNEY','Hour','','2024-02-05','','False','','8','1','','10');
INSERT INTO "reduivy__Study_Offering__c" VALUES(102,'MGT301_NYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2024-02-05','','','','','','','','Draft','','Unit','','MGT301_NYT1_BRISBANE','Hour','','2024-02-05','','False','','8','5','','10');
INSERT INTO "reduivy__Study_Offering__c" VALUES(103,'MGT301_NYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2024-12-06','','','','','','','','Draft','','Unit','','MGT301_NYT2_SYDNEY','Hour','','2024-07-29','','False','','9','1','','10');
INSERT INTO "reduivy__Study_Offering__c" VALUES(104,'MGT301_NYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2024-12-06','','','','','','','','Draft','','Unit','','MGT301_NYT2_BRISBANE','Hour','','2024-07-29','','False','','9','5','','10');
INSERT INTO "reduivy__Study_Offering__c" VALUES(105,'MGT302_PYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2022-07-01','','','','','','','','Draft','','Unit','','MGT302_PYT1_SYDNEY','Hour','','2022-02-07','','False','','4','1','','11');
INSERT INTO "reduivy__Study_Offering__c" VALUES(106,'MGT302_PYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2022-07-01','','','','','','','','Draft','','Unit','','MGT302_PYT1_BRISBANE','Hour','','2022-02-07','','False','','4','5','','11');
INSERT INTO "reduivy__Study_Offering__c" VALUES(107,'MGT302_PYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2022-12-09','','','','','','','','Draft','','Unit','','MGT302_PYT2_SYDNEY','Hour','','2022-08-01','','False','','5','1','','11');
INSERT INTO "reduivy__Study_Offering__c" VALUES(108,'MGT302_PYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2022-12-09','','','','','','','','Draft','','Unit','','MGT302_PYT2_BRISBANE','Hour','','2022-08-01','','False','','5','5','','11');
INSERT INTO "reduivy__Study_Offering__c" VALUES(109,'MGT302_CYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2023-06-30','','','','','','','','Draft','','Unit','','MGT302_CYT1_SYDNEY','Hour','','2023-02-06','','False','','6','1','','11');
INSERT INTO "reduivy__Study_Offering__c" VALUES(110,'MGT302_CYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2023-06-30','','','','','','','','Draft','','Unit','','MGT302_CYT1_BRISBANE','Hour','','2023-02-06','','False','','6','5','','11');
INSERT INTO "reduivy__Study_Offering__c" VALUES(111,'MGT302_CYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2023-12-08','','','','','','','','Draft','','Unit','','MGT302_CYT2_SYDNEY','Hour','','2023-07-31','','False','','7','1','','11');
INSERT INTO "reduivy__Study_Offering__c" VALUES(112,'MGT302_CYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2023-12-08','','','','','','','','Draft','','Unit','','MGT302_CYT2_BRISBANE','Hour','','2023-07-31','','False','','7','5','','11');
INSERT INTO "reduivy__Study_Offering__c" VALUES(113,'MGT302_NYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2024-02-05','','','','','','','','Draft','','Unit','','MGT302_NYT1_SYDNEY','Hour','','2024-02-05','','False','','8','1','','11');
INSERT INTO "reduivy__Study_Offering__c" VALUES(114,'MGT302_NYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2024-02-05','','','','','','','','Draft','','Unit','','MGT302_NYT1_BRISBANE','Hour','','2024-02-05','','False','','8','5','','11');
INSERT INTO "reduivy__Study_Offering__c" VALUES(115,'MGT302_NYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2024-12-06','','','','','','','','Draft','','Unit','','MGT302_NYT2_SYDNEY','Hour','','2024-07-29','','False','','9','1','','11');
INSERT INTO "reduivy__Study_Offering__c" VALUES(116,'MGT303_PYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2022-12-09','','','','','','','','Draft','','Unit','','MGT303_PYT2_SYDNEY','Hour','','2022-08-01','','False','','5','1','','12');
INSERT INTO "reduivy__Study_Offering__c" VALUES(117,'MGT302_NYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2024-12-06','','','','','','','','Draft','','Unit','','MGT302_NYT2_BRISBANE','Hour','','2024-07-29','','False','','9','5','','11');
INSERT INTO "reduivy__Study_Offering__c" VALUES(118,'MGT303_PYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2022-07-01','','','','','','','','Draft','','Unit','','MGT303_PYT1_SYDNEY','Hour','','2022-02-07','','False','','4','1','','12');
INSERT INTO "reduivy__Study_Offering__c" VALUES(119,'MGT303_PYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2022-07-01','','','','','','','','Draft','','Unit','','MGT303_PYT1_BRISBANE','Hour','','2022-02-07','','False','','4','5','','12');
INSERT INTO "reduivy__Study_Offering__c" VALUES(120,'MGT303_PYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2022-12-09','','','','','','','','Draft','','Unit','','MGT303_PYT2_BRISBANE','Hour','','2022-08-01','','False','','5','5','','12');
INSERT INTO "reduivy__Study_Offering__c" VALUES(121,'MGT303_CYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2023-06-30','','','','','','','','Draft','','Unit','','MGT303_CYT1_SYDNEY','Hour','','2023-02-06','','False','','6','1','','12');
INSERT INTO "reduivy__Study_Offering__c" VALUES(122,'MGT303_CYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2023-06-30','','','','','','','','Draft','','Unit','','MGT303_CYT1_BRISBANE','Hour','','2023-02-06','','False','','6','5','','12');
INSERT INTO "reduivy__Study_Offering__c" VALUES(123,'MGT303_CYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2023-12-08','','','','','','','','Draft','','Unit','','MGT303_CYT2_SYDNEY','Hour','','2023-07-31','','False','','7','1','','12');
INSERT INTO "reduivy__Study_Offering__c" VALUES(124,'MGT303_CYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2023-12-08','','','','','','','','Draft','','Unit','','MGT303_CYT2_BRISBANE','Hour','','2023-07-31','','False','','7','5','','12');
INSERT INTO "reduivy__Study_Offering__c" VALUES(125,'MGT303_NYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2024-02-05','','','','','','','','Draft','','Unit','','MGT303_NYT1_SYDNEY','Hour','','2024-02-05','','False','','8','1','','12');
INSERT INTO "reduivy__Study_Offering__c" VALUES(126,'MGT303_NYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2024-02-05','','','','','','','','Draft','','Unit','','MGT303_NYT1_BRISBANE','Hour','','2024-02-05','','False','','8','5','','12');
INSERT INTO "reduivy__Study_Offering__c" VALUES(127,'MGT303_NYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2024-12-06','','','','','','','','Draft','','Unit','','MGT303_NYT2_SYDNEY','Hour','','2024-07-29','','False','','9','1','','12');
INSERT INTO "reduivy__Study_Offering__c" VALUES(128,'MGT303_NYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2024-12-06','','','','','','','','Draft','','Unit','','MGT303_NYT2_BRISBANE','Hour','','2024-07-29','','False','','9','5','','12');
INSERT INTO "reduivy__Study_Offering__c" VALUES(129,'COM101_PYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2022-07-01','','','','','','','','Draft','','Unit','','COM101_PYT1_SYDNEY','Hour','','2022-02-07','','False','','4','1','','13');
INSERT INTO "reduivy__Study_Offering__c" VALUES(130,'COM101_PYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2022-07-01','','','','','','','','Draft','','Unit','','COM101_PYT1_BRISBANE','Hour','','2022-02-07','','False','','4','5','','13');
INSERT INTO "reduivy__Study_Offering__c" VALUES(131,'COM101_PYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2022-12-09','','','','','','','','Draft','','Unit','','COM101_PYT2_SYDNEY','Hour','','2022-08-01','','False','','5','1','','13');
INSERT INTO "reduivy__Study_Offering__c" VALUES(132,'COM101_PYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2022-12-09','','','','','','','','Draft','','Unit','','COM101_PYT2_BRISBANE','Hour','','2022-08-01','','False','','5','5','','13');
INSERT INTO "reduivy__Study_Offering__c" VALUES(133,'COM101_CYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2023-06-30','','','','','','','','Draft','','Unit','','COM101_CYT1_SYDNEY','Hour','','2023-02-06','','False','','6','1','','13');
INSERT INTO "reduivy__Study_Offering__c" VALUES(134,'COM101_CYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2023-06-30','','','','','','','','Draft','','Unit','','COM101_CYT1_BRISBANE','Hour','','2023-02-06','','False','','6','5','','13');
INSERT INTO "reduivy__Study_Offering__c" VALUES(135,'COM101_CYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2023-12-08','','','','','','','','Draft','','Unit','','COM101_CYT2_SYDNEY','Hour','','2023-07-31','','False','','7','1','','13');
INSERT INTO "reduivy__Study_Offering__c" VALUES(136,'COM101_CYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2023-12-08','','','','','','','','Draft','','Unit','','COM101_CYT2_BRISBANE','Hour','','2023-07-31','','False','','7','5','','13');
INSERT INTO "reduivy__Study_Offering__c" VALUES(137,'COM101_NYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2024-02-05','','','','','','','','Draft','','Unit','','COM101_NYT1_SYDNEY','Hour','','2024-02-05','','False','','8','1','','13');
INSERT INTO "reduivy__Study_Offering__c" VALUES(138,'COM101_NYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2024-02-05','','','','','','','','Draft','','Unit','','COM101_NYT1_BRISBANE','Hour','','2024-02-05','','False','','8','5','','13');
INSERT INTO "reduivy__Study_Offering__c" VALUES(139,'COM102_PYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2022-07-01','','','','','','','','Draft','','Unit','','COM102_PYT1_BRISBANE','Hour','','2022-02-07','','False','','4','5','','14');
INSERT INTO "reduivy__Study_Offering__c" VALUES(140,'COM101_NYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2024-12-06','','','','','','','','Draft','','Unit','','COM101_NYT2_SYDNEY','Hour','','2024-07-29','','False','','9','1','','13');
INSERT INTO "reduivy__Study_Offering__c" VALUES(141,'COM101_NYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2024-12-06','','','','','','','','Draft','','Unit','','COM101_NYT2_BRISBANE','Hour','','2024-07-29','','False','','9','5','','13');
INSERT INTO "reduivy__Study_Offering__c" VALUES(142,'COM102_PYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2022-07-01','','','','','','','','Draft','','Unit','','COM102_PYT1_SYDNEY','Hour','','2022-02-07','','False','','4','1','','14');
INSERT INTO "reduivy__Study_Offering__c" VALUES(143,'COM102_PYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2022-12-09','','','','','','','','Draft','','Unit','','COM102_PYT2_SYDNEY','Hour','','2022-08-01','','False','','5','1','','14');
INSERT INTO "reduivy__Study_Offering__c" VALUES(144,'COM102_PYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2022-12-09','','','','','','','','Draft','','Unit','','COM102_PYT2_BRISBANE','Hour','','2022-08-01','','False','','5','5','','14');
INSERT INTO "reduivy__Study_Offering__c" VALUES(145,'COM102_CYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2023-06-30','','','','','','','','Draft','','Unit','','COM102_CYT1_SYDNEY','Hour','','2023-02-06','','False','','6','1','','14');
INSERT INTO "reduivy__Study_Offering__c" VALUES(146,'COM102_CYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2023-06-30','','','','','','','','Draft','','Unit','','COM102_CYT1_BRISBANE','Hour','','2023-02-06','','False','','6','5','','14');
INSERT INTO "reduivy__Study_Offering__c" VALUES(147,'COM102_CYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2023-12-08','','','','','','','','Draft','','Unit','','COM102_CYT2_SYDNEY','Hour','','2023-07-31','','False','','7','1','','14');
INSERT INTO "reduivy__Study_Offering__c" VALUES(148,'COM102_CYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2023-12-08','','','','','','','','Draft','','Unit','','COM102_CYT2_BRISBANE','Hour','','2023-07-31','','False','','7','5','','14');
INSERT INTO "reduivy__Study_Offering__c" VALUES(149,'COM102_NYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2024-02-05','','','','','','','','Draft','','Unit','','COM102_NYT1_SYDNEY','Hour','','2024-02-05','','False','','8','1','','14');
INSERT INTO "reduivy__Study_Offering__c" VALUES(150,'COM102_NYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2024-02-05','','','','','','','','Draft','','Unit','','COM102_NYT1_BRISBANE','Hour','','2024-02-05','','False','','8','5','','14');
INSERT INTO "reduivy__Study_Offering__c" VALUES(151,'COM102_NYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2024-12-06','','','','','','','','Draft','','Unit','','COM102_NYT2_SYDNEY','Hour','','2024-07-29','','False','','9','1','','14');
INSERT INTO "reduivy__Study_Offering__c" VALUES(152,'COM102_NYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2024-12-06','','','','','','','','Draft','','Unit','','COM102_NYT2_BRISBANE','Hour','','2024-07-29','','False','','9','5','','14');
INSERT INTO "reduivy__Study_Offering__c" VALUES(153,'COM103_PYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2022-07-01','','','','','','','','Draft','','Unit','','COM103_PYT1_SYDNEY','Hour','','2022-02-07','','False','','4','1','','15');
INSERT INTO "reduivy__Study_Offering__c" VALUES(154,'COM103_PYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2022-07-01','','','','','','','','Draft','','Unit','','COM103_PYT1_BRISBANE','Hour','','2022-02-07','','False','','4','5','','15');
INSERT INTO "reduivy__Study_Offering__c" VALUES(155,'COM103_PYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2022-12-09','','','','','','','','Draft','','Unit','','COM103_PYT2_SYDNEY','Hour','','2022-08-01','','False','','5','1','','15');
INSERT INTO "reduivy__Study_Offering__c" VALUES(156,'COM103_PYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2022-12-09','','','','','','','','Draft','','Unit','','COM103_PYT2_BRISBANE','Hour','','2022-08-01','','False','','5','5','','15');
INSERT INTO "reduivy__Study_Offering__c" VALUES(157,'COM103_CYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2023-06-30','','','','','','','','Draft','','Unit','','COM103_CYT1_SYDNEY','Hour','','2023-02-06','','False','','6','1','','15');
INSERT INTO "reduivy__Study_Offering__c" VALUES(158,'COM103_CYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2023-06-30','','','','','','','','Draft','','Unit','','COM103_CYT1_BRISBANE','Hour','','2023-02-06','','False','','6','5','','15');
INSERT INTO "reduivy__Study_Offering__c" VALUES(159,'COM103_CYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2023-12-08','','','','','','','','Draft','','Unit','','COM103_CYT2_SYDNEY','Hour','','2023-07-31','','False','','7','1','','15');
INSERT INTO "reduivy__Study_Offering__c" VALUES(160,'COM103_CYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2023-12-08','','','','','','','','Draft','','Unit','','COM103_CYT2_BRISBANE','Hour','','2023-07-31','','False','','7','5','','15');
INSERT INTO "reduivy__Study_Offering__c" VALUES(161,'COM103_NYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2024-02-05','','','','','','','','Draft','','Unit','','COM103_NYT1_SYDNEY','Hour','','2024-02-05','','False','','8','1','','15');
INSERT INTO "reduivy__Study_Offering__c" VALUES(162,'ICT101_PYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2022-07-01','','','','','','','','Draft','','Unit','','ICT101_PYT1_SYDNEY','Hour','','2022-02-07','','False','','4','1','','16');
INSERT INTO "reduivy__Study_Offering__c" VALUES(163,'COM103_NYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2024-02-05','','','','','','','','Draft','','Unit','','COM103_NYT1_BRISBANE','Hour','','2024-02-05','','False','','8','5','','15');
INSERT INTO "reduivy__Study_Offering__c" VALUES(164,'COM103_NYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2024-12-06','','','','','','','','Draft','','Unit','','COM103_NYT2_SYDNEY','Hour','','2024-07-29','','False','','9','1','','15');
INSERT INTO "reduivy__Study_Offering__c" VALUES(165,'COM103_NYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2024-12-06','','','','','','','','Draft','','Unit','','COM103_NYT2_BRISBANE','Hour','','2024-07-29','','False','','9','5','','15');
INSERT INTO "reduivy__Study_Offering__c" VALUES(166,'ICT101_PYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2022-07-01','','','','','','','','Draft','','Unit','','ICT101_PYT1_BRISBANE','Hour','','2022-02-07','','False','','4','5','','16');
INSERT INTO "reduivy__Study_Offering__c" VALUES(167,'ICT101_PYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2022-12-09','','','','','','','','Draft','','Unit','','ICT101_PYT2_SYDNEY','Hour','','2022-08-01','','False','','5','1','','16');
INSERT INTO "reduivy__Study_Offering__c" VALUES(168,'ICT101_PYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2022-12-09','','','','','','','','Draft','','Unit','','ICT101_PYT2_BRISBANE','Hour','','2022-08-01','','False','','5','5','','16');
INSERT INTO "reduivy__Study_Offering__c" VALUES(169,'ICT101_CYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2023-06-30','','','','','','','','Draft','','Unit','','ICT101_CYT1_SYDNEY','Hour','','2023-02-06','','False','','6','1','','16');
INSERT INTO "reduivy__Study_Offering__c" VALUES(170,'ICT101_CYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2023-06-30','','','','','','','','Draft','','Unit','','ICT101_CYT1_BRISBANE','Hour','','2023-02-06','','False','','6','5','','16');
INSERT INTO "reduivy__Study_Offering__c" VALUES(171,'ICT101_CYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2023-12-08','','','','','','','','Draft','','Unit','','ICT101_CYT2_SYDNEY','Hour','','2023-07-31','','False','','7','1','','16');
INSERT INTO "reduivy__Study_Offering__c" VALUES(172,'ICT101_CYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2023-12-08','','','','','','','','Draft','','Unit','','ICT101_CYT2_BRISBANE','Hour','','2023-07-31','','False','','7','5','','16');
INSERT INTO "reduivy__Study_Offering__c" VALUES(173,'ICT101_NYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2024-02-05','','','','','','','','Draft','','Unit','','ICT101_NYT1_SYDNEY','Hour','','2024-02-05','','False','','8','1','','16');
INSERT INTO "reduivy__Study_Offering__c" VALUES(174,'ICT101_NYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2024-02-05','','','','','','','','Draft','','Unit','','ICT101_NYT1_BRISBANE','Hour','','2024-02-05','','False','','8','5','','16');
INSERT INTO "reduivy__Study_Offering__c" VALUES(175,'ICT101_NYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2024-12-06','','','','','','','','Draft','','Unit','','ICT101_NYT2_SYDNEY','Hour','','2024-07-29','','False','','9','1','','16');
INSERT INTO "reduivy__Study_Offering__c" VALUES(176,'ICT101_NYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2024-12-06','','','','','','','','Draft','','Unit','','ICT101_NYT2_BRISBANE','Hour','','2024-07-29','','False','','9','5','','16');
INSERT INTO "reduivy__Study_Offering__c" VALUES(177,'ICT102_PYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2022-07-01','','','','','','','','Draft','','Unit','','ICT102_PYT1_SYDNEY','Hour','','2022-02-07','','False','','4','1','','17');
INSERT INTO "reduivy__Study_Offering__c" VALUES(178,'ICT102_PYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2022-07-01','','','','','','','','Draft','','Unit','','ICT102_PYT1_BRISBANE','Hour','','2022-02-07','','False','','4','5','','17');
INSERT INTO "reduivy__Study_Offering__c" VALUES(179,'ICT102_PYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2022-12-09','','','','','','','','Draft','','Unit','','ICT102_PYT2_SYDNEY','Hour','','2022-08-01','','False','','5','1','','17');
INSERT INTO "reduivy__Study_Offering__c" VALUES(180,'ICT102_PYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2022-12-09','','','','','','','','Draft','','Unit','','ICT102_PYT2_BRISBANE','Hour','','2022-08-01','','False','','5','5','','17');
INSERT INTO "reduivy__Study_Offering__c" VALUES(181,'ICT102_CYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2023-06-30','','','','','','','','Draft','','Unit','','ICT102_CYT1_SYDNEY','Hour','','2023-02-06','','False','','6','1','','17');
INSERT INTO "reduivy__Study_Offering__c" VALUES(182,'ICT102_CYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2023-06-30','','','','','','','','Draft','','Unit','','ICT102_CYT1_BRISBANE','Hour','','2023-02-06','','False','','6','5','','17');
INSERT INTO "reduivy__Study_Offering__c" VALUES(183,'ICT102_CYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2023-12-08','','','','','','','','Draft','','Unit','','ICT102_CYT2_SYDNEY','Hour','','2023-07-31','','False','','7','1','','17');
INSERT INTO "reduivy__Study_Offering__c" VALUES(184,'ICT102_CYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2023-12-08','','','','','','','','Draft','','Unit','','ICT102_CYT2_BRISBANE','Hour','','2023-07-31','','False','','7','5','','17');
INSERT INTO "reduivy__Study_Offering__c" VALUES(185,'ICT102_NYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2024-12-06','','','','','','','','Draft','','Unit','','ICT102_NYT2_BRISBANE','Hour','','2024-07-29','','False','','9','5','','17');
INSERT INTO "reduivy__Study_Offering__c" VALUES(186,'ICT102_NYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2024-02-05','','','','','','','','Draft','','Unit','','ICT102_NYT1_SYDNEY','Hour','','2024-02-05','','False','','8','1','','17');
INSERT INTO "reduivy__Study_Offering__c" VALUES(187,'ICT102_NYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2024-02-05','','','','','','','','Draft','','Unit','','ICT102_NYT1_BRISBANE','Hour','','2024-02-05','','False','','8','5','','17');
INSERT INTO "reduivy__Study_Offering__c" VALUES(188,'ICT102_NYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2024-12-06','','','','','','','','Draft','','Unit','','ICT102_NYT2_SYDNEY','Hour','','2024-07-29','','False','','9','1','','17');
INSERT INTO "reduivy__Study_Offering__c" VALUES(189,'ICT103_PYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2022-07-01','','','','','','','','Draft','','Unit','','ICT103_PYT1_SYDNEY','Hour','','2022-02-07','','False','','4','1','','18');
INSERT INTO "reduivy__Study_Offering__c" VALUES(190,'ICT103_PYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2022-07-01','','','','','','','','Draft','','Unit','','ICT103_PYT1_BRISBANE','Hour','','2022-02-07','','False','','4','5','','18');
INSERT INTO "reduivy__Study_Offering__c" VALUES(191,'ICT103_PYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2022-12-09','','','','','','','','Draft','','Unit','','ICT103_PYT2_SYDNEY','Hour','','2022-08-01','','False','','5','1','','18');
INSERT INTO "reduivy__Study_Offering__c" VALUES(192,'ICT103_PYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2022-12-09','','','','','','','','Draft','','Unit','','ICT103_PYT2_BRISBANE','Hour','','2022-08-01','','False','','5','5','','18');
INSERT INTO "reduivy__Study_Offering__c" VALUES(193,'ICT103_CYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2023-06-30','','','','','','','','Draft','','Unit','','ICT103_CYT1_SYDNEY','Hour','','2023-02-06','','False','','6','1','','18');
INSERT INTO "reduivy__Study_Offering__c" VALUES(194,'ICT103_CYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2023-06-30','','','','','','','','Draft','','Unit','','ICT103_CYT1_BRISBANE','Hour','','2023-02-06','','False','','6','5','','18');
INSERT INTO "reduivy__Study_Offering__c" VALUES(195,'ICT103_CYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2023-12-08','','','','','','','','Draft','','Unit','','ICT103_CYT2_SYDNEY','Hour','','2023-07-31','','False','','7','1','','18');
INSERT INTO "reduivy__Study_Offering__c" VALUES(196,'ICT103_CYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2023-12-08','','','','','','','','Draft','','Unit','','ICT103_CYT2_BRISBANE','Hour','','2023-07-31','','False','','7','5','','18');
INSERT INTO "reduivy__Study_Offering__c" VALUES(197,'ICT103_NYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2024-02-05','','','','','','','','Draft','','Unit','','ICT103_NYT1_SYDNEY','Hour','','2024-02-05','','False','','8','1','','18');
INSERT INTO "reduivy__Study_Offering__c" VALUES(198,'ICT103_NYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2024-02-05','','','','','','','','Draft','','Unit','','ICT103_NYT1_BRISBANE','Hour','','2024-02-05','','False','','8','5','','18');
INSERT INTO "reduivy__Study_Offering__c" VALUES(199,'ICT103_NYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2024-12-06','','','','','','','','Draft','','Unit','','ICT103_NYT2_SYDNEY','Hour','','2024-07-29','','False','','9','1','','18');
INSERT INTO "reduivy__Study_Offering__c" VALUES(200,'ICT103_NYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2024-12-06','','','','','','','','Draft','','Unit','','ICT103_NYT2_BRISBANE','Hour','','2024-07-29','','False','','9','5','','18');
INSERT INTO "reduivy__Study_Offering__c" VALUES(201,'MAT201_PYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2022-07-01','','','','','','','','Draft','','Unit','','MAT201_PYT1_SYDNEY','Hour','','2022-02-07','','False','','4','1','','19');
INSERT INTO "reduivy__Study_Offering__c" VALUES(202,'MAT201_PYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2022-07-01','','','','','','','','Draft','','Unit','','MAT201_PYT1_BRISBANE','Hour','','2022-02-07','','False','','4','5','','19');
INSERT INTO "reduivy__Study_Offering__c" VALUES(203,'MAT201_PYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2022-12-09','','','','','','','','Draft','','Unit','','MAT201_PYT2_SYDNEY','Hour','','2022-08-01','','False','','5','1','','19');
INSERT INTO "reduivy__Study_Offering__c" VALUES(204,'MAT201_PYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2022-12-09','','','','','','','','Draft','','Unit','','MAT201_PYT2_BRISBANE','Hour','','2022-08-01','','False','','5','5','','19');
INSERT INTO "reduivy__Study_Offering__c" VALUES(205,'MAT201_CYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2023-06-30','','','','','','','','Draft','','Unit','','MAT201_CYT1_SYDNEY','Hour','','2023-02-06','','False','','6','1','','19');
INSERT INTO "reduivy__Study_Offering__c" VALUES(206,'MAT201_CYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2023-06-30','','','','','','','','Draft','','Unit','','MAT201_CYT1_BRISBANE','Hour','','2023-02-06','','False','','6','5','','19');
INSERT INTO "reduivy__Study_Offering__c" VALUES(207,'MAT201_CYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2023-12-08','','','','','','','','Draft','','Unit','','MAT201_CYT2_SYDNEY','Hour','','2023-07-31','','False','','7','1','','19');
INSERT INTO "reduivy__Study_Offering__c" VALUES(208,'MAT201_NYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2024-12-06','','','','','','','','Draft','','Unit','','MAT201_NYT2_SYDNEY','Hour','','2024-07-29','','False','','9','1','','19');
INSERT INTO "reduivy__Study_Offering__c" VALUES(209,'MAT201_CYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2023-12-08','','','','','','','','Draft','','Unit','','MAT201_CYT2_BRISBANE','Hour','','2023-07-31','','False','','7','5','','19');
INSERT INTO "reduivy__Study_Offering__c" VALUES(210,'MAT201_NYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2024-02-05','','','','','','','','Draft','','Unit','','MAT201_NYT1_SYDNEY','Hour','','2024-02-05','','False','','8','1','','19');
INSERT INTO "reduivy__Study_Offering__c" VALUES(211,'MAT201_NYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2024-02-05','','','','','','','','Draft','','Unit','','MAT201_NYT1_BRISBANE','Hour','','2024-02-05','','False','','8','5','','19');
INSERT INTO "reduivy__Study_Offering__c" VALUES(212,'MAT201_NYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2024-12-06','','','','','','','','Draft','','Unit','','MAT201_NYT2_BRISBANE','Hour','','2024-07-29','','False','','9','5','','19');
INSERT INTO "reduivy__Study_Offering__c" VALUES(213,'MAT202_PYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2022-07-01','','','','','','','','Draft','','Unit','','MAT202_PYT1_SYDNEY','Hour','','2022-02-07','','False','','4','1','','20');
INSERT INTO "reduivy__Study_Offering__c" VALUES(214,'MAT202_PYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2022-07-01','','','','','','','','Draft','','Unit','','MAT202_PYT1_BRISBANE','Hour','','2022-02-07','','False','','4','5','','20');
INSERT INTO "reduivy__Study_Offering__c" VALUES(215,'MAT202_PYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2022-12-09','','','','','','','','Draft','','Unit','','MAT202_PYT2_SYDNEY','Hour','','2022-08-01','','False','','5','1','','20');
INSERT INTO "reduivy__Study_Offering__c" VALUES(216,'MAT202_PYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2022-12-09','','','','','','','','Draft','','Unit','','MAT202_PYT2_BRISBANE','Hour','','2022-08-01','','False','','5','5','','20');
INSERT INTO "reduivy__Study_Offering__c" VALUES(217,'MAT202_CYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2023-06-30','','','','','','','','Draft','','Unit','','MAT202_CYT1_SYDNEY','Hour','','2023-02-06','','False','','6','1','','20');
INSERT INTO "reduivy__Study_Offering__c" VALUES(218,'MAT202_CYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2023-06-30','','','','','','','','Draft','','Unit','','MAT202_CYT1_BRISBANE','Hour','','2023-02-06','','False','','6','5','','20');
INSERT INTO "reduivy__Study_Offering__c" VALUES(219,'MAT202_CYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2023-12-08','','','','','','','','Draft','','Unit','','MAT202_CYT2_SYDNEY','Hour','','2023-07-31','','False','','7','1','','20');
INSERT INTO "reduivy__Study_Offering__c" VALUES(220,'MAT202_CYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2023-12-08','','','','','','','','Draft','','Unit','','MAT202_CYT2_BRISBANE','Hour','','2023-07-31','','False','','7','5','','20');
INSERT INTO "reduivy__Study_Offering__c" VALUES(221,'MAT202_NYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2024-02-05','','','','','','','','Draft','','Unit','','MAT202_NYT1_SYDNEY','Hour','','2024-02-05','','False','','8','1','','20');
INSERT INTO "reduivy__Study_Offering__c" VALUES(222,'MAT202_NYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2024-02-05','','','','','','','','Draft','','Unit','','MAT202_NYT1_BRISBANE','Hour','','2024-02-05','','False','','8','5','','20');
INSERT INTO "reduivy__Study_Offering__c" VALUES(223,'MAT202_NYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2024-12-06','','','','','','','','Draft','','Unit','','MAT202_NYT2_SYDNEY','Hour','','2024-07-29','','False','','9','1','','20');
INSERT INTO "reduivy__Study_Offering__c" VALUES(224,'MAT202_NYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2024-12-06','','','','','','','','Draft','','Unit','','MAT202_NYT2_BRISBANE','Hour','','2024-07-29','','False','','9','5','','20');
INSERT INTO "reduivy__Study_Offering__c" VALUES(225,'MAT203_PYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2022-07-01','','','','','','','','Draft','','Unit','','MAT203_PYT1_SYDNEY','Hour','','2022-02-07','','False','','4','1','','21');
INSERT INTO "reduivy__Study_Offering__c" VALUES(226,'MAT203_PYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2022-07-01','','','','','','','','Draft','','Unit','','MAT203_PYT1_BRISBANE','Hour','','2022-02-07','','False','','4','5','','21');
INSERT INTO "reduivy__Study_Offering__c" VALUES(227,'MAT203_PYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2022-12-09','','','','','','','','Draft','','Unit','','MAT203_PYT2_SYDNEY','Hour','','2022-08-01','','False','','5','1','','21');
INSERT INTO "reduivy__Study_Offering__c" VALUES(228,'MAT203_PYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2022-12-09','','','','','','','','Draft','','Unit','','MAT203_PYT2_BRISBANE','Hour','','2022-08-01','','False','','5','5','','21');
INSERT INTO "reduivy__Study_Offering__c" VALUES(229,'MAT203_CYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2023-06-30','','','','','','','','Draft','','Unit','','MAT203_CYT1_SYDNEY','Hour','','2023-02-06','','False','','6','1','','21');
INSERT INTO "reduivy__Study_Offering__c" VALUES(230,'MAT203_CYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2023-06-30','','','','','','','','Draft','','Unit','','MAT203_CYT1_BRISBANE','Hour','','2023-02-06','','False','','6','5','','21');
INSERT INTO "reduivy__Study_Offering__c" VALUES(231,'MAT203_NYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2024-02-05','','','','','','','','Draft','','Unit','','MAT203_NYT1_BRISBANE','Hour','','2024-02-05','','False','','8','5','','21');
INSERT INTO "reduivy__Study_Offering__c" VALUES(232,'MAT203_CYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2023-12-08','','','','','','','','Draft','','Unit','','MAT203_CYT2_SYDNEY','Hour','','2023-07-31','','False','','7','1','','21');
INSERT INTO "reduivy__Study_Offering__c" VALUES(233,'MAT203_CYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2023-12-08','','','','','','','','Draft','','Unit','','MAT203_CYT2_BRISBANE','Hour','','2023-07-31','','False','','7','5','','21');
INSERT INTO "reduivy__Study_Offering__c" VALUES(234,'MAT203_NYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2024-02-05','','','','','','','','Draft','','Unit','','MAT203_NYT1_SYDNEY','Hour','','2024-02-05','','False','','8','1','','21');
INSERT INTO "reduivy__Study_Offering__c" VALUES(235,'MAT203_NYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2024-12-06','','','','','','','','Draft','','Unit','','MAT203_NYT2_SYDNEY','Hour','','2024-07-29','','False','','9','1','','21');
INSERT INTO "reduivy__Study_Offering__c" VALUES(236,'MAT203_NYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2024-12-06','','','','','','','','Draft','','Unit','','MAT203_NYT2_BRISBANE','Hour','','2024-07-29','','False','','9','5','','21');
INSERT INTO "reduivy__Study_Offering__c" VALUES(237,'SEC301_PYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2022-07-01','','','','','','','','Draft','','Unit','','SEC301_PYT1_SYDNEY','Hour','','2022-02-07','','False','','4','1','','22');
INSERT INTO "reduivy__Study_Offering__c" VALUES(238,'SEC301_PYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2022-07-01','','','','','','','','Draft','','Unit','','SEC301_PYT1_BRISBANE','Hour','','2022-02-07','','False','','4','5','','22');
INSERT INTO "reduivy__Study_Offering__c" VALUES(239,'SEC301_PYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2022-12-09','','','','','','','','Draft','','Unit','','SEC301_PYT2_SYDNEY','Hour','','2022-08-01','','False','','5','1','','22');
INSERT INTO "reduivy__Study_Offering__c" VALUES(240,'SEC301_PYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2022-12-09','','','','','','','','Draft','','Unit','','SEC301_PYT2_BRISBANE','Hour','','2022-08-01','','False','','5','5','','22');
INSERT INTO "reduivy__Study_Offering__c" VALUES(241,'SEC301_CYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2023-06-30','','','','','','','','Draft','','Unit','','SEC301_CYT1_SYDNEY','Hour','','2023-02-06','','False','','6','1','','22');
INSERT INTO "reduivy__Study_Offering__c" VALUES(242,'SEC301_CYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2023-06-30','','','','','','','','Draft','','Unit','','SEC301_CYT1_BRISBANE','Hour','','2023-02-06','','False','','6','5','','22');
INSERT INTO "reduivy__Study_Offering__c" VALUES(243,'SEC301_CYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2023-12-08','','','','','','','','Draft','','Unit','','SEC301_CYT2_SYDNEY','Hour','','2023-07-31','','False','','7','1','','22');
INSERT INTO "reduivy__Study_Offering__c" VALUES(244,'SEC301_CYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2023-12-08','','','','','','','','Draft','','Unit','','SEC301_CYT2_BRISBANE','Hour','','2023-07-31','','False','','7','5','','22');
INSERT INTO "reduivy__Study_Offering__c" VALUES(245,'SEC301_NYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2024-02-05','','','','','','','','Draft','','Unit','','SEC301_NYT1_SYDNEY','Hour','','2024-02-05','','False','','8','1','','22');
INSERT INTO "reduivy__Study_Offering__c" VALUES(246,'SEC301_NYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2024-02-05','','','','','','','','Draft','','Unit','','SEC301_NYT1_BRISBANE','Hour','','2024-02-05','','False','','8','5','','22');
INSERT INTO "reduivy__Study_Offering__c" VALUES(247,'SEC301_NYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2024-12-06','','','','','','','','Draft','','Unit','','SEC301_NYT2_SYDNEY','Hour','','2024-07-29','','False','','9','1','','22');
INSERT INTO "reduivy__Study_Offering__c" VALUES(248,'SEC301_NYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2024-12-06','','','','','','','','Draft','','Unit','','SEC301_NYT2_BRISBANE','Hour','','2024-07-29','','False','','9','5','','22');
INSERT INTO "reduivy__Study_Offering__c" VALUES(249,'SEC302_PYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2022-07-01','','','','','','','','Draft','','Unit','','SEC302_PYT1_SYDNEY','Hour','','2022-02-07','','False','','4','1','','23');
INSERT INTO "reduivy__Study_Offering__c" VALUES(250,'SEC302_PYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2022-07-01','','','','','','','','Draft','','Unit','','SEC302_PYT1_BRISBANE','Hour','','2022-02-07','','False','','4','5','','23');
INSERT INTO "reduivy__Study_Offering__c" VALUES(251,'SEC302_PYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2022-12-09','','','','','','','','Draft','','Unit','','SEC302_PYT2_SYDNEY','Hour','','2022-08-01','','False','','5','1','','23');
INSERT INTO "reduivy__Study_Offering__c" VALUES(252,'SEC302_PYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2022-12-09','','','','','','','','Draft','','Unit','','SEC302_PYT2_BRISBANE','Hour','','2022-08-01','','False','','5','5','','23');
INSERT INTO "reduivy__Study_Offering__c" VALUES(253,'SEC302_CYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2023-06-30','','','','','','','','Draft','','Unit','','SEC302_CYT1_SYDNEY','Hour','','2023-02-06','','False','','6','1','','23');
INSERT INTO "reduivy__Study_Offering__c" VALUES(254,'SEC302_NYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2024-02-05','','','','','','','','Draft','','Unit','','SEC302_NYT1_SYDNEY','Hour','','2024-02-05','','False','','8','1','','23');
INSERT INTO "reduivy__Study_Offering__c" VALUES(255,'SEC302_CYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2023-06-30','','','','','','','','Draft','','Unit','','SEC302_CYT1_BRISBANE','Hour','','2023-02-06','','False','','6','5','','23');
INSERT INTO "reduivy__Study_Offering__c" VALUES(256,'SEC302_CYT2_SYDNEY','','','','20.0','','','','','','False','False','True','True','2023-12-08','','','','','','','','Draft','','Unit','','SEC302_CYT2_SYDNEY','Hour','','2023-07-31','Not Started','False','','7','1','','23');
INSERT INTO "reduivy__Study_Offering__c" VALUES(257,'SEC302_CYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2023-12-08','','','','','','','','Draft','','Unit','','SEC302_CYT2_BRISBANE','Hour','','2023-07-31','Enrollment Opened','False','','7','5','','23');
INSERT INTO "reduivy__Study_Offering__c" VALUES(258,'SEC302_NYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2024-02-05','','','','','','','','Draft','','Unit','','SEC302_NYT1_BRISBANE','Hour','','2024-02-05','','False','','8','5','','23');
INSERT INTO "reduivy__Study_Offering__c" VALUES(259,'SEC302_NYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2024-12-06','','','','','','','','Draft','','Unit','','SEC302_NYT2_SYDNEY','Hour','','2024-07-29','','False','','9','1','','23');
INSERT INTO "reduivy__Study_Offering__c" VALUES(260,'SEC302_NYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2024-12-06','','','','','','','','Draft','','Unit','','SEC302_NYT2_BRISBANE','Hour','','2024-07-29','','False','','9','5','','23');
INSERT INTO "reduivy__Study_Offering__c" VALUES(261,'SEC303_PYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2022-07-01','','','','','','','','Draft','','Unit','','SEC303_PYT1_SYDNEY','Hour','','2022-02-07','','False','','4','1','','24');
INSERT INTO "reduivy__Study_Offering__c" VALUES(262,'SEC303_PYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2022-07-01','','','','','','','','Draft','','Unit','','SEC303_PYT1_BRISBANE','Hour','','2022-02-07','','False','','4','5','','24');
INSERT INTO "reduivy__Study_Offering__c" VALUES(263,'SEC303_PYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2022-12-09','','','','','','','','Draft','','Unit','','SEC303_PYT2_SYDNEY','Hour','','2022-08-01','','False','','5','1','','24');
INSERT INTO "reduivy__Study_Offering__c" VALUES(264,'SEC303_PYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2022-12-09','','','','','','','','Draft','','Unit','','SEC303_PYT2_BRISBANE','Hour','','2022-08-01','','False','','5','5','','24');
INSERT INTO "reduivy__Study_Offering__c" VALUES(265,'SEC303_CYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2023-06-30','','','','','','','','Draft','','Unit','','SEC303_CYT1_SYDNEY','Hour','','2023-02-06','','False','','6','1','','24');
INSERT INTO "reduivy__Study_Offering__c" VALUES(266,'SEC303_CYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2023-06-30','','','','','','','','Draft','','Unit','','SEC303_CYT1_BRISBANE','Hour','','2023-02-06','','False','','6','5','','24');
INSERT INTO "reduivy__Study_Offering__c" VALUES(267,'SEC303_CYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2023-12-08','','','','','','','','Draft','','Unit','','SEC303_CYT2_SYDNEY','Hour','','2023-07-31','','False','','7','1','','24');
INSERT INTO "reduivy__Study_Offering__c" VALUES(268,'SEC303_CYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2023-12-08','','','','','','','','Draft','','Unit','','SEC303_CYT2_BRISBANE','Hour','','2023-07-31','','False','','7','5','','24');
INSERT INTO "reduivy__Study_Offering__c" VALUES(269,'SEC303_NYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2024-02-05','','','','','','','','Draft','','Unit','','SEC303_NYT1_SYDNEY','Hour','','2024-02-05','','False','','8','1','','24');
INSERT INTO "reduivy__Study_Offering__c" VALUES(270,'SEC303_NYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2024-02-05','','','','','','','','Draft','','Unit','','SEC303_NYT1_BRISBANE','Hour','','2024-02-05','','False','','8','5','','24');
INSERT INTO "reduivy__Study_Offering__c" VALUES(271,'SEC303_NYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2024-12-06','','','','','','','','Draft','','Unit','','SEC303_NYT2_SYDNEY','Hour','','2024-07-29','','False','','9','1','','24');
INSERT INTO "reduivy__Study_Offering__c" VALUES(272,'SEC303_NYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2024-12-06','','','','','','','','Draft','','Unit','','SEC303_NYT2_BRISBANE','Hour','','2024-07-29','','False','','9','5','','24');
INSERT INTO "reduivy__Study_Offering__c" VALUES(273,'BUS101_PYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2022-12-09','','','','','','','','Draft','','Unit','','BUS101_PYT2_BRISBANE','Hour','','2022-08-01','','False','','5','5','','1');
INSERT INTO "reduivy__Study_Offering__c" VALUES(274,'BUS101_PYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2022-07-01','','','','','','','','Draft','','Unit','','BUS101_PYT1_SYDNEY','Hour','','2022-02-07','','False','','4','1','','1');
INSERT INTO "reduivy__Study_Offering__c" VALUES(275,'BUS101_PYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2022-07-01','','','','','','','','Draft','','Unit','','BUS101_PYT1_BRISBANE','Hour','','2022-02-07','','False','','4','5','','1');
INSERT INTO "reduivy__Study_Offering__c" VALUES(276,'BUS101_PYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2022-12-09','','','','','','','','Draft','','Unit','','BUS101_PYT2_SYDNEY','Hour','','2022-08-01','','False','','5','1','','1');
INSERT INTO "reduivy__Study_Offering__c" VALUES(277,'BUS101_CYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2023-06-30','','','','','','','','Draft','','Unit','','BUS101_CYT1_SYDNEY','Hour','','2023-02-06','','False','','6','1','','1');
INSERT INTO "reduivy__Study_Offering__c" VALUES(278,'BUS101_CYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2023-06-30','','','','','','','','Draft','','Unit','','BUS101_CYT1_BRISBANE','Hour','','2023-02-06','','False','','6','5','','1');
INSERT INTO "reduivy__Study_Offering__c" VALUES(279,'BUS101_CYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2023-12-08','','','','','','','','Draft','','Unit','','BUS101_CYT2_SYDNEY','Hour','','2023-07-31','Running (Enrollment Opened)','False','','7','1','','1');
INSERT INTO "reduivy__Study_Offering__c" VALUES(280,'BUS101_CYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2023-12-08','','','','','','','','Draft','','Unit','','BUS101_CYT2_BRISBANE','Hour','','2023-07-31','Running (Enrollment Opened)','False','','7','5','','1');
INSERT INTO "reduivy__Study_Offering__c" VALUES(281,'BUS101_NYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2024-02-05','','','','','','','','Draft','','Unit','','BUS101_NYT1_SYDNEY','Hour','','2024-02-05','','False','','8','1','','1');
INSERT INTO "reduivy__Study_Offering__c" VALUES(282,'BUS101_NYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2024-02-05','','','','','','','','Draft','','Unit','','BUS101_NYT1_BRISBANE','Hour','','2024-02-05','','False','','8','5','','1');
INSERT INTO "reduivy__Study_Offering__c" VALUES(283,'BUS101_NYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2024-12-06','','','','','','','','Draft','','Unit','','BUS101_NYT2_SYDNEY','Hour','','2024-07-29','','False','','9','1','','1');
INSERT INTO "reduivy__Study_Offering__c" VALUES(284,'BUS101_NYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2024-12-06','','','','','','','','Draft','','Unit','','BUS101_NYT2_BRISBANE','Hour','','2024-07-29','','False','','9','5','','1');
INSERT INTO "reduivy__Study_Offering__c" VALUES(285,'BUS102_PYT1_SYDNEY','','','','20.0','','','','','','False','False','False','False','2022-07-01','','','','','','','','Draft','','Unit','','BUS102_PYT1_SYDNEY','Hour','','2022-02-07','','False','','4','1','','2');
INSERT INTO "reduivy__Study_Offering__c" VALUES(286,'BUS102_PYT1_BRISBANE','','','','20.0','','','','','','False','False','False','False','2022-07-01','','','','','','','','Draft','','Unit','','BUS102_PYT1_BRISBANE','Hour','','2022-02-07','','False','','4','5','','2');
INSERT INTO "reduivy__Study_Offering__c" VALUES(287,'BUS102_PYT2_SYDNEY','','','','20.0','','','','','','False','False','False','False','2022-12-09','','','','','','','','Draft','','Unit','','BUS102_PYT2_SYDNEY','Hour','','2022-08-01','','False','','5','1','','2');
INSERT INTO "reduivy__Study_Offering__c" VALUES(288,'BUS102_PYT2_BRISBANE','','','','20.0','','','','','','False','False','False','False','2022-12-09','','','','','','','','Draft','','Unit','','BUS102_PYT2_BRISBANE','Hour','','2022-08-01','','False','','5','5','','2');
CREATE TABLE "reduivy__Study_Pathway_Term__c" (
	id INTEGER NOT NULL, 
	"reduivy__Clone_From_Id__c" VARCHAR(255), 
	"reduivy__Description__c" VARCHAR(255), 
	"reduivy__Enrollment_Method__c" VARCHAR(255), 
	"reduivy__External_Id__c" VARCHAR(255), 
	"reduivy__Max_Credits__c" VARCHAR(255), 
	"reduivy__Recommended_Credits__c" VARCHAR(255), 
	"reduivy__Sample_Record_Code__c" VARCHAR(255), 
	"reduivy__Term_Number__c" VARCHAR(255), 
	"reduivy__Study_Pathway__c" VARCHAR(255), 
	PRIMARY KEY (id)
);
INSERT INTO "reduivy__Study_Pathway_Term__c" VALUES(1,'','','Manual','','40.0','40.0','BACBIS_DEFAULT_T1','1.0','1');
INSERT INTO "reduivy__Study_Pathway_Term__c" VALUES(2,'','','Manual','','40.0','40.0','BACBIS_DEFAULT_T2','2.0','1');
INSERT INTO "reduivy__Study_Pathway_Term__c" VALUES(3,'','','Manual','','40.0','40.0','BACBIS_DEFAULT_T3','3.0','1');
INSERT INTO "reduivy__Study_Pathway_Term__c" VALUES(4,'','','Manual','','40.0','40.0','BACBIS_DEFAULT_T4','4.0','1');
INSERT INTO "reduivy__Study_Pathway_Term__c" VALUES(5,'','','Manual','','40.0','40.0','BACCOM_DEFAULT_T1','1.0','2');
INSERT INTO "reduivy__Study_Pathway_Term__c" VALUES(6,'','','Manual','','40.0','40.0','BACCOM_DEFAULT_T2','2.0','2');
INSERT INTO "reduivy__Study_Pathway_Term__c" VALUES(7,'','','Manual','','40.0','40.0','BACCOM_DEFAULT_T3','3.0','2');
INSERT INTO "reduivy__Study_Pathway_Term__c" VALUES(8,'','','Manual','','40.0','40.0','BACCOM_DEFAULT_T4','4.0','2');
CREATE TABLE "reduivy__Study_Pathway_Unit__c" (
	id INTEGER NOT NULL, 
	"reduivy__Clone_From_Id__c" VARCHAR(255), 
	"reduivy__External_Id__c" VARCHAR(255), 
	"reduivy__Number_of_Units_from_Group__c" VARCHAR(255), 
	"reduivy__Sample_Record_Code__c" VARCHAR(255), 
	"reduivy__Applicable_Study_Plan__c" VARCHAR(255), 
	"reduivy__Study_Pathway_Term__c" VARCHAR(255), 
	"reduivy__Study_Plan_Group__c" VARCHAR(255), 
	"reduivy__Study_Unit__c" VARCHAR(255), 
	PRIMARY KEY (id)
);
INSERT INTO "reduivy__Study_Pathway_Unit__c" VALUES(1,'','','2.0','','1','2','12','');
INSERT INTO "reduivy__Study_Pathway_Unit__c" VALUES(2,'','','','BACBIS_DEFAULT_T1_BUS101','','1','','1');
INSERT INTO "reduivy__Study_Pathway_Unit__c" VALUES(3,'','','','BACBIS_DEFAULT_T1_BUS102','','1','','2');
INSERT INTO "reduivy__Study_Pathway_Unit__c" VALUES(4,'','','','BACBIS_DEFAULT_T1_BUS103','','1','','3');
INSERT INTO "reduivy__Study_Pathway_Unit__c" VALUES(5,'','','','BACBIS_DEFAULT_T1_COM101','','1','','13');
INSERT INTO "reduivy__Study_Pathway_Unit__c" VALUES(6,'','','','BACBIS_DEFAULT_T2_BUS201','','2','','7');
INSERT INTO "reduivy__Study_Pathway_Unit__c" VALUES(7,'','','','BACBIS_DEFAULT_T2_BUS202','','2','','8');
INSERT INTO "reduivy__Study_Pathway_Unit__c" VALUES(8,'','','2.0','BACBIS_DEFAULT_T2_BISGROUPA_2_1','','2','7','');
INSERT INTO "reduivy__Study_Pathway_Unit__c" VALUES(9,'','','','BACBIS_DEFAULT_T3_MGT301','','3','','10');
INSERT INTO "reduivy__Study_Pathway_Unit__c" VALUES(10,'','','','BACBIS_DEFAULT_T3_MGT302','','3','','11');
INSERT INTO "reduivy__Study_Pathway_Unit__c" VALUES(11,'','','2.0','BACBIS_DEFAULT_T3_BISGROUPA_2_2','','3','4','');
INSERT INTO "reduivy__Study_Pathway_Unit__c" VALUES(12,'','','2.0','BACBIS_DEFAULT_T4_BISGROUPB_2','','4','10','');
INSERT INTO "reduivy__Study_Pathway_Unit__c" VALUES(13,'','','2.0','BACBIS_DEFAULT_T4_BISGROUPB_3','','4','11','');
INSERT INTO "reduivy__Study_Pathway_Unit__c" VALUES(14,'','','','BACCOM_DEFAULT_T1_BUS101','','5','','1');
INSERT INTO "reduivy__Study_Pathway_Unit__c" VALUES(15,'','','','BACCOM_DEFAULT_T1_BUS102','','5','','2');
INSERT INTO "reduivy__Study_Pathway_Unit__c" VALUES(16,'','','2.0','BACCOM_DEFAULT_T1_COMGROUPA','','5','13','');
INSERT INTO "reduivy__Study_Pathway_Unit__c" VALUES(17,'','','','BACCOM_DEFAULT_T2_BUS201','','6','','7');
INSERT INTO "reduivy__Study_Pathway_Unit__c" VALUES(18,'','','','BACCOM_DEFAULT_T2_BUS202','','6','','8');
INSERT INTO "reduivy__Study_Pathway_Unit__c" VALUES(19,'','','2.0','BACCOM_DEFAULT_T2_COMGROUPA','','6','13','');
INSERT INTO "reduivy__Study_Pathway_Unit__c" VALUES(20,'','','','BACCOM_DEFAULT_T3_MGT301','','7','','10');
INSERT INTO "reduivy__Study_Pathway_Unit__c" VALUES(21,'','','','BACCOM_DEFAULT_T3_MGT302','','7','','11');
INSERT INTO "reduivy__Study_Pathway_Unit__c" VALUES(22,'','','2.0','BACCOM_DEFAULT_T3_COMGROUPA','','7','13','');
INSERT INTO "reduivy__Study_Pathway_Unit__c" VALUES(23,'','','4.0','BACCOM_DEFAULT_T4_COMGROUPB','','8','14','');
CREATE TABLE "reduivy__Study_Pathway__c" (
	id INTEGER NOT NULL, 
	"Name" VARCHAR(255), 
	"reduivy__Clone_From_Id__c" VARCHAR(255), 
	"reduivy__Default__c" VARCHAR(255), 
	"reduivy__External_Id__c" VARCHAR(255), 
	"reduivy__Sample_Record_Code__c" VARCHAR(255), 
	"reduivy__Status__c" VARCHAR(255), 
	"reduivy__Study_Mode__c" VARCHAR(255), 
	"reduivy__Study_Plan__c" VARCHAR(255), 
	PRIMARY KEY (id)
);
INSERT INTO "reduivy__Study_Pathway__c" VALUES(1,'Bachelor of Business Default Pathway','','True','','BACBIS_DEFAULT','','Full-time','1');
INSERT INTO "reduivy__Study_Pathway__c" VALUES(2,'Bachelor of Comp Science Default Pathway','','True','','BACCOM_DEFAULT','','Full-time','2');
CREATE TABLE "reduivy__Study_Plan_Structure__c" (
	id INTEGER NOT NULL, 
	"Name" VARCHAR(255), 
	"reduivy__Allow_Pre_Enrollment__c" VARCHAR(255), 
	"reduivy__Category__c" VARCHAR(255), 
	"reduivy__Clone_From_Id__c" VARCHAR(255), 
	"reduivy__Credits__c" VARCHAR(255), 
	"reduivy__Credits_equivalent_per_Unit__c" VARCHAR(255), 
	"reduivy__Description__c" VARCHAR(255), 
	"reduivy__EFTSL_Override__c" VARCHAR(255), 
	"reduivy__External_Id__c" VARCHAR(255), 
	"reduivy__Hide_in_Enrollment__c" VARCHAR(255), 
	"reduivy__Max_Credits__c" VARCHAR(255), 
	"reduivy__Requirement_Description__c" VARCHAR(255), 
	"reduivy__Requirement_Logic__c" VARCHAR(255), 
	"reduivy__Sample_Record_Code__c" VARCHAR(255), 
	"reduivy__Sequence__c" VARCHAR(255), 
	"reduivy__Units_Required__c" VARCHAR(255), 
	"RecordTypeId" VARCHAR(255), 
	"reduivy__Parent_Study_Plan_Structure__c" VARCHAR(255), 
	"reduivy__Study_Plan__c" VARCHAR(255), 
	"reduivy__Study_Unit__c" VARCHAR(255), 
	PRIMARY KEY (id)
);
INSERT INTO "reduivy__Study_Plan_Structure__c" VALUES(1,'BISGROUPA','False','Required','','100.0','','','','','False','100.0','','','BISGROUPA','','','0127X000001sv6pQAA','','1','');
INSERT INTO "reduivy__Study_Plan_Structure__c" VALUES(2,'BISGROUPA_1','False','Required','','60.0','','','','','False','60.0','','','BISGROUPA_1','','','0127X000001sv6pQAA','1','1','');
INSERT INTO "reduivy__Study_Plan_Structure__c" VALUES(3,'BISGROUPA_2','False','Required','','40.0','','','','','False','40.0','','','BISGROUPA_2','','','0127X000001sv6pQAA','1','1','');
INSERT INTO "reduivy__Study_Plan_Structure__c" VALUES(4,'BISGROUPA_2_2','False','Required','','20.0','10.0','','','','False','20.0','','','BISGROUPA_2_2','','2.0','0127X000001sv6pQAA','3','1','');
INSERT INTO "reduivy__Study_Plan_Structure__c" VALUES(5,'BISGROUPA_1_1','False','Optional','','20.0','','','','','False','40.0','','','BISGROUPA_1_1','','','0127X000001sv6pQAA','2','1','');
INSERT INTO "reduivy__Study_Plan_Structure__c" VALUES(6,'BISGROUPA_1_2','False','Optional','','20.0','','','','','False','40.0','','','BISGROUPA_1_2','','','0127X000001sv6pQAA','2','1','');
INSERT INTO "reduivy__Study_Plan_Structure__c" VALUES(7,'BISGROUPA_2_1','False','Required','','20.0','10.0','','','','False','20.0','','','BISGROUPA_2_1','','2.0','0127X000001sv6pQAA','3','1','');
INSERT INTO "reduivy__Study_Plan_Structure__c" VALUES(8,'BISGROUPB','False','Required','','60.0','','','','','False','60.0','','','BISGROUPB','','','0127X000001sv6pQAA','','1','');
INSERT INTO "reduivy__Study_Plan_Structure__c" VALUES(9,'BISGROUPB_1','False','Required','','20.0','10.0','','','','False','20.0','','','BISGROUPB_1','','2.0','0127X000001sv6pQAA','8','1','');
INSERT INTO "reduivy__Study_Plan_Structure__c" VALUES(10,'BISGROUPB_2','False','Optional','','10.0','','','','','False','40.0','','','BISGROUPB_2','','','0127X000001sv6pQAA','8','1','');
INSERT INTO "reduivy__Study_Plan_Structure__c" VALUES(11,'BISGROUPB_3','False','Optional','','10.0','','','','','False','40.0','','','BISGROUPB_3','','','0127X000001sv6pQAA','8','1','');
INSERT INTO "reduivy__Study_Plan_Structure__c" VALUES(12,'BISGROUPC','False','Optional','','20.0','','','','','False','20.0','','','BISGROUPC','','','0127X000001sv6pQAA','','1','');
INSERT INTO "reduivy__Study_Plan_Structure__c" VALUES(13,'COMGROUPA','False','Required','','100.0','','','','','False','100.0','','','COMGROUPA','','','0127X000001sv6pQAA','','2','');
INSERT INTO "reduivy__Study_Plan_Structure__c" VALUES(14,'COMGROUPB','False','Required','','60.0','','','','','False','60.0','','','COMGROUPB','','','0127X000001sv6pQAA','','2','');
INSERT INTO "reduivy__Study_Plan_Structure__c" VALUES(15,'BACBIS_V1_BUS101','False','Required','','10.0','','','','','False','','','','BACBIS_V1_BUS101','','','0127X000001sv6qQAA','5','1','1');
INSERT INTO "reduivy__Study_Plan_Structure__c" VALUES(16,'BACBIS_V1_BUS102','False','Optional','','10.0','','','','','False','','','','BACBIS_V1_BUS102','','','0127X000001sv6qQAA','5','1','2');
INSERT INTO "reduivy__Study_Plan_Structure__c" VALUES(17,'BACBIS_V1_BUS103','False','Optional','','10.0','','','','','False','','','','BACBIS_V1_BUS103','','','0127X000001sv6qQAA','5','1','3');
INSERT INTO "reduivy__Study_Plan_Structure__c" VALUES(18,'BACBIS_V1_COM101','False','Optional','','10.0','','','','','False','','','NOT(COM102) OR MANUAL','BACBIS_V1_COM101','','','0127X000001sv6qQAA','5','1','13');
INSERT INTO "reduivy__Study_Plan_Structure__c" VALUES(19,'BACBIS_V1_BUS201','False','Required','','10.0','','','','','False','','','BUS101','BACBIS_V1_BUS201','','','0127X000001sv6qQAA','6','1','7');
INSERT INTO "reduivy__Study_Plan_Structure__c" VALUES(20,'BACBIS_V1_BUS202','False','Optional','','10.0','','','','','False','','','BUS101 OR BUS102','BACBIS_V1_BUS202','','','0127X000001sv6qQAA','6','1','8');
INSERT INTO "reduivy__Study_Plan_Structure__c" VALUES(21,'BACBIS_V1_BUS203','False','Optional','','10.0','','','','','False','','','BUS101 OR BUS103','BACBIS_V1_BUS203','','','0127X000001sv6qQAA','6','1','9');
INSERT INTO "reduivy__Study_Plan_Structure__c" VALUES(22,'BACBIS_V1_MAT201','False','Optional','','10.0','','','','','False','','','','BACBIS_V1_MAT201','','','0127X000001sv6qQAA','6','1','19');
INSERT INTO "reduivy__Study_Plan_Structure__c" VALUES(23,'BACBIS_V1_MKT101','False','Optional','','10.0','','','','','False','','','','BACBIS_V1_MKT101','','','0127X000001sv6qQAA','7','1','4');
INSERT INTO "reduivy__Study_Plan_Structure__c" VALUES(24,'BACBIS_V1_MKT102','False','Optional','','10.0','','','','','False','','','','BACBIS_V1_MKT102','','','0127X000001sv6qQAA','7','1','5');
INSERT INTO "reduivy__Study_Plan_Structure__c" VALUES(25,'BACBIS_V1_MKT103','False','Optional','','10.0','','','','','False','','','','BACBIS_V1_MKT103','','','0127X000001sv6qQAA','7','1','6');
INSERT INTO "reduivy__Study_Plan_Structure__c" VALUES(26,'BACBIS_V1_ICT101','False','Optional','','10.0','','','','','False','','','','BACBIS_V1_ICT101','','','0127X000001sv6qQAA','4','1','16');
INSERT INTO "reduivy__Study_Plan_Structure__c" VALUES(27,'BACBIS_V1_ICT102','False','Optional','','10.0','','','','','False','','','','BACBIS_V1_ICT102','','','0127X000001sv6qQAA','4','1','17');
INSERT INTO "reduivy__Study_Plan_Structure__c" VALUES(28,'BACBIS_V1_ICT103','False','Optional','','10.0','','','','','False','','','','BACBIS_V1_ICT103','','','0127X000001sv6qQAA','4','1','18');
INSERT INTO "reduivy__Study_Plan_Structure__c" VALUES(29,'BACBIS_V1_MGT301','False','Required','','10.0','','','','','False','','','BUS201 AND CREDIT10','BACBIS_V1_MGT301','','','0127X000001sv6qQAA','9','1','10');
INSERT INTO "reduivy__Study_Plan_Structure__c" VALUES(30,'BACBIS_V1_MGT302','False','Required','','10.0','','','','','False','','','BUS201 AND NOT(BUS203)','BACBIS_V1_MGT302','','','0127X000001sv6qQAA','9','1','11');
INSERT INTO "reduivy__Study_Plan_Structure__c" VALUES(31,'BACBIS_V1_MGT303','False','Optional','','10.0','','','','','False','','','BUS201 AND NOT(BUS202)','BACBIS_V1_MGT303','','','0127X000001sv6qQAA','10','1','12');
INSERT INTO "reduivy__Study_Plan_Structure__c" VALUES(32,'BACBIS_V1_COM102','False','Optional','','10.0','','','','','False','','','NOT(COM101) OR MANUAL','BACBIS_V1_COM102','','','0127X000001sv6qQAA','10','1','14');
INSERT INTO "reduivy__Study_Plan_Structure__c" VALUES(33,'BACBIS_V1_COM103','False','Optional','','10.0','','','','','False','','','','BACBIS_V1_COM103','','','0127X000001sv6qQAA','10','1','15');
INSERT INTO "reduivy__Study_Plan_Structure__c" VALUES(34,'BACBIS_V1_SEC302','False','Optional','','10.0','','','','','False','','','(COM101 OR COM102) AND BUS201 AND CREDIT20','BACBIS_V1_SEC302','','','0127X000001sv6qQAA','12','1','23');
INSERT INTO "reduivy__Study_Plan_Structure__c" VALUES(35,'BACBIS_V1_MAT202','False','Optional','','10.0','','','','','False','','','','BACBIS_V1_MAT202','','','0127X000001sv6qQAA','11','1','20');
INSERT INTO "reduivy__Study_Plan_Structure__c" VALUES(36,'BACBIS_V1_MAT203','False','Optional','','10.0','','','','','False','','','','BACBIS_V1_MAT203','','','0127X000001sv6qQAA','11','1','21');
INSERT INTO "reduivy__Study_Plan_Structure__c" VALUES(37,'BACBIS_V1_SEC301','False','Optional','','10.0','','','','','False','','','COM101 AND (BUS101 OR BUS102)','BACBIS_V1_SEC301','','','0127X000001sv6qQAA','11','1','22');
INSERT INTO "reduivy__Study_Plan_Structure__c" VALUES(38,'BACBIS_V1_SEC303','False','Optional','','10.0','','','','','False','','','(COM101 OR COM102) AND (MAT201 OR MAT202)','BACBIS_V1_SEC303','','','0127X000001sv6qQAA','12','1','24');
INSERT INTO "reduivy__Study_Plan_Structure__c" VALUES(39,'BACCOM_V1_BUS101','False','Required','','10.0','','','','','False','','','','BACCOM_V1_BUS101','','','0127X000001sv6qQAA','13','2','1');
INSERT INTO "reduivy__Study_Plan_Structure__c" VALUES(40,'BACCOM_V1_BUS102','False','Optional','','10.0','','','','','False','','','','BACCOM_V1_BUS102','','','0127X000001sv6qQAA','13','2','2');
INSERT INTO "reduivy__Study_Plan_Structure__c" VALUES(41,'BACCOM_V1_BUS103','False','Optional','','10.0','','','','','False','','','','BACCOM_V1_BUS103','','','0127X000001sv6qQAA','13','2','3');
INSERT INTO "reduivy__Study_Plan_Structure__c" VALUES(42,'BACCOM_V1_COM101','False','Optional','','10.0','','','','','False','','','NOT(COM102) OR MANUAL','BACCOM_V1_COM101','','','0127X000001sv6qQAA','13','2','13');
INSERT INTO "reduivy__Study_Plan_Structure__c" VALUES(43,'BACCOM_V1_BUS201','False','Required','','10.0','','','','','False','','','BUS101','BACCOM_V1_BUS201','','','0127X000001sv6qQAA','13','2','7');
INSERT INTO "reduivy__Study_Plan_Structure__c" VALUES(44,'BACCOM_V1_BUS202','False','Optional','','10.0','','','','','False','','','BUS101 OR BUS102','BACCOM_V1_BUS202','','','0127X000001sv6qQAA','13','2','8');
INSERT INTO "reduivy__Study_Plan_Structure__c" VALUES(45,'BACCOM_V1_BUS203','False','Optional','','10.0','','','','','False','','','BUS101 OR BUS103','BACCOM_V1_BUS203','','','0127X000001sv6qQAA','13','2','9');
INSERT INTO "reduivy__Study_Plan_Structure__c" VALUES(46,'BACCOM_V1_MAT201','False','Optional','','10.0','','','','','False','','','','BACCOM_V1_MAT201','','','0127X000001sv6qQAA','13','2','19');
INSERT INTO "reduivy__Study_Plan_Structure__c" VALUES(47,'BACCOM_V1_MKT101','False','Optional','','10.0','','','','','False','','','','BACCOM_V1_MKT101','','','0127X000001sv6qQAA','13','2','4');
INSERT INTO "reduivy__Study_Plan_Structure__c" VALUES(48,'BACCOM_V1_MKT102','False','Optional','','10.0','','','','','False','','','','BACCOM_V1_MKT102','','','0127X000001sv6qQAA','13','2','5');
INSERT INTO "reduivy__Study_Plan_Structure__c" VALUES(49,'BACCOM_V1_MKT103','False','Optional','','10.0','','','','','False','','','','BACCOM_V1_MKT103','','','0127X000001sv6qQAA','13','2','6');
INSERT INTO "reduivy__Study_Plan_Structure__c" VALUES(50,'BACCOM_V1_ICT101','False','Optional','','10.0','','','','','False','','','','BACCOM_V1_ICT101','','','0127X000001sv6qQAA','13','2','16');
INSERT INTO "reduivy__Study_Plan_Structure__c" VALUES(51,'BACCOM_V1_ICT102','False','Optional','','10.0','','','','','False','','','','BACCOM_V1_ICT102','','','0127X000001sv6qQAA','13','2','17');
INSERT INTO "reduivy__Study_Plan_Structure__c" VALUES(52,'BACCOM_V1_ICT103','False','Optional','','10.0','','','','','False','','','','BACCOM_V1_ICT103','','','0127X000001sv6qQAA','13','2','18');
INSERT INTO "reduivy__Study_Plan_Structure__c" VALUES(53,'BACCOM_V1_MGT301','False','Required','','10.0','','','','','False','','','BUS201 AND CREDIT10','BACCOM_V1_MGT301','','','0127X000001sv6qQAA','14','2','10');
INSERT INTO "reduivy__Study_Plan_Structure__c" VALUES(54,'BACCOM_V1_MGT302','False','Required','','10.0','','','','','False','','','BUS201 AND NOT(BUS203)','BACCOM_V1_MGT302','','','0127X000001sv6qQAA','14','2','11');
INSERT INTO "reduivy__Study_Plan_Structure__c" VALUES(55,'BACCOM_V1_MGT303','False','Optional','','10.0','','','','','False','','','BUS201 AND NOT(BUS202)','BACCOM_V1_MGT303','','','0127X000001sv6qQAA','14','2','12');
INSERT INTO "reduivy__Study_Plan_Structure__c" VALUES(56,'BACCOM_V1_COM102','False','Optional','','10.0','','','','','False','','','NOT(COM101) OR MANUAL','BACCOM_V1_COM102','','','0127X000001sv6qQAA','14','2','14');
INSERT INTO "reduivy__Study_Plan_Structure__c" VALUES(57,'BACCOM_V1_COM103','False','Optional','','10.0','','','','','False','','','','BACCOM_V1_COM103','','','0127X000001sv6qQAA','14','2','15');
INSERT INTO "reduivy__Study_Plan_Structure__c" VALUES(58,'BACCOM_V1_MAT202','False','Optional','','10.0','','','','','False','','','','BACCOM_V1_MAT202','','','0127X000001sv6qQAA','14','2','20');
INSERT INTO "reduivy__Study_Plan_Structure__c" VALUES(59,'BACCOM_V1_MAT203','False','Optional','','10.0','','','','','False','','','','BACCOM_V1_MAT203','','','0127X000001sv6qQAA','14','2','21');
INSERT INTO "reduivy__Study_Plan_Structure__c" VALUES(60,'BACCOM_V1_SEC301','False','Optional','','10.0','','','','','False','','','COM101 AND (BUS101 OR BUS102)','BACCOM_V1_SEC301','','','0127X000001sv6qQAA','14','2','22');
INSERT INTO "reduivy__Study_Plan_Structure__c" VALUES(61,'BACCOM_V1_SEC302','False','Optional','','10.0','','','','','False','','','(COM101 OR COM102) AND BUS201 AND CREDIT20','BACCOM_V1_SEC302','','','0127X000001sv6qQAA','14','2','23');
INSERT INTO "reduivy__Study_Plan_Structure__c" VALUES(62,'BACCOM_V1_SEC303','False','Optional','','10.0','','','','','False','','','(COM101 OR COM102) AND (MAT201 OR MAT202)','BACCOM_V1_SEC303','','','0127X000001sv6qQAA','14','2','24');
CREATE TABLE "reduivy__Study_Plan_Structure__c_rt_mapping" (
	record_type_id VARCHAR(18) NOT NULL, 
	developer_name VARCHAR(255), 
	PRIMARY KEY (record_type_id)
);
INSERT INTO "reduivy__Study_Plan_Structure__c_rt_mapping" VALUES('0127X000001sv6pQAA','Group');
INSERT INTO "reduivy__Study_Plan_Structure__c_rt_mapping" VALUES('0127X000001sv6qQAA','Unit');
CREATE TABLE "reduivy__Study_Plan__c" (
	id INTEGER NOT NULL, 
	"Name" VARCHAR(255), 
	"reduivy__Clone_From_Id__c" VARCHAR(255), 
	"reduivy__Default__c" VARCHAR(255), 
	"reduivy__Description__c" VARCHAR(255), 
	"reduivy__External_Id__c" VARCHAR(255), 
	"reduivy__Fee_Method__c" VARCHAR(255), 
	"reduivy__Pay_Upfront__c" VARCHAR(255), 
	"reduivy__Sample_Record_Code__c" VARCHAR(255), 
	"reduivy__Status__c" VARCHAR(255), 
	"reduivy__Total_Required_Credits__c" VARCHAR(255), 
	"reduivy__Type__c" VARCHAR(255), 
	"reduivy__Valid_From__c" VARCHAR(255), 
	"reduivy__Valid_To__c" VARCHAR(255), 
	"reduivy__Version__c" VARCHAR(255), 
	"reduivy__Study_Program__c" VARCHAR(255), 
	PRIMARY KEY (id)
);
INSERT INTO "reduivy__Study_Plan__c" VALUES(1,'Bachelor of Business Management V1','','True','','','Term','No','BACBIS_V1','Active','160.0','','','','','1');
INSERT INTO "reduivy__Study_Plan__c" VALUES(2,'Bachelor of Computer Science V1','','True','','','Term','No','BACCOM_V1','Active','160.0','','','','','2');
CREATE TABLE "reduivy__Study_Program__c" (
	id INTEGER NOT NULL, 
	"Name" VARCHAR(255), 
	"reduivy__Academic_Level__c" VARCHAR(255), 
	"reduivy__External_Id__c" VARCHAR(255), 
	"reduivy__Program_Code__c" VARCHAR(255), 
	"reduivy__Program_Entry_Criteria__c" VARCHAR(255), 
	"reduivy__Sample_Record_Code__c" VARCHAR(255), 
	"reduivy__Educational_Institution__c" VARCHAR(255), 
	PRIMARY KEY (id)
);
INSERT INTO "reduivy__Study_Program__c" VALUES(1,'Bachelor of Business Management','Bachelors Honours','','BACBIS','','BACBIS','2');
INSERT INTO "reduivy__Study_Program__c" VALUES(2,'Bachelor of Computer Science','Bachelors Honours','','BACCOM','','BACCOM','2');
CREATE TABLE "reduivy__Study_Term__c" (
	id INTEGER NOT NULL, 
	"Name" VARCHAR(255), 
	"reduivy__Alternate_Name__c" VARCHAR(255), 
	"reduivy__Census_Date__c" VARCHAR(255), 
	"reduivy__Enable_Cohort_Enrollment__c" VARCHAR(255), 
	"reduivy__End_Date__c" VARCHAR(255), 
	"reduivy__Enrollment_Close_Date__c" VARCHAR(255), 
	"reduivy__Enrollment_Open_Date__c" VARCHAR(255), 
	"reduivy__External_Id__c" VARCHAR(255), 
	"reduivy__For_Internal_Only__c" VARCHAR(255), 
	"reduivy__Pre_enrollment_Open_Date__c" VARCHAR(255), 
	"reduivy__Sample_Record_Code__c" VARCHAR(255), 
	"reduivy__Start_Date__c" VARCHAR(255), 
	"reduivy__Type__c" VARCHAR(255), 
	"RecordTypeId" VARCHAR(255), 
	"reduivy__Academic_Year__c" VARCHAR(255), 
	"reduivy__Educational_Institution__c" VARCHAR(255), 
	PRIMARY KEY (id)
);
INSERT INTO "reduivy__Study_Term__c" VALUES(1,'Year 2022','Academic Year 2022','','False','2022-12-09','','','','False','','PY','2022-02-07','School Year','0127X000001sv6sQAA','','2');
INSERT INTO "reduivy__Study_Term__c" VALUES(2,'Year 2023','Academic Year 2023','','False','2023-12-08','','','','False','','CY','2023-02-06','School Year','0127X000001sv6sQAA','','2');
INSERT INTO "reduivy__Study_Term__c" VALUES(3,'Year 2024','Academic Year 2024','','False','2024-12-06','','','','False','','NY','2024-02-05','School Year','0127X000001sv6sQAA','','2');
INSERT INTO "reduivy__Study_Term__c" VALUES(4,'T1 2022','Academic Term 1 2022','2022-02-21','False','2022-07-01','2022-02-07T08:00:00.000+0000','2022-01-24T08:00:00.000+0000','','False','2022-01-17T08:00:00.000+0000','PYT1','2022-02-07','Semester','0127X000001sv6rQAA','1','');
INSERT INTO "reduivy__Study_Term__c" VALUES(5,'T2 2022','Academic Term 2 2022','2022-08-15','False','2022-12-09','2022-08-01T07:00:00.000+0000','2022-07-18T07:00:00.000+0000','','False','2022-07-11T07:00:00.000+0000','PYT2','2022-08-01','Semester','0127X000001sv6rQAA','1','');
INSERT INTO "reduivy__Study_Term__c" VALUES(6,'T1 2023','Academic Term 1 2023','2023-02-20','False','2023-06-30','2023-02-06T08:00:00.000+0000','2023-01-23T08:00:00.000+0000','','False','2023-01-16T08:00:00.000+0000','CYT1','2023-02-06','Semester','0127X000001sv6rQAA','2','');
INSERT INTO "reduivy__Study_Term__c" VALUES(7,'T2 2023','Academic Term 2 2023','2023-08-14','True','2023-12-08','2023-07-31T07:00:00.000+0000','2023-07-17T07:00:00.000+0000','','False','2023-11-10T08:00:00.000+0000','CYT2','2023-07-31','Semester','0127X000001sv6rQAA','2','');
INSERT INTO "reduivy__Study_Term__c" VALUES(8,'T1 2024','Academic Term 1 2024','2024-02-19','False','2024-02-05','2024-02-05T08:00:00.000+0000','2024-01-22T08:00:00.000+0000','','False','2024-01-15T08:00:00.000+0000','NYT1','2024-02-05','Semester','0127X000001sv6rQAA','3','');
INSERT INTO "reduivy__Study_Term__c" VALUES(9,'T2 2024','Academic Term 2 2024','2024-08-12','False','2024-12-06','2024-07-29T07:00:00.000+0000','2024-07-15T07:00:00.000+0000','','False','2024-07-08T07:00:00.000+0000','NYT2','2024-07-29','Semester','0127X000001sv6rQAA','3','');
CREATE TABLE "reduivy__Study_Term__c_rt_mapping" (
	record_type_id VARCHAR(18) NOT NULL, 
	developer_name VARCHAR(255), 
	PRIMARY KEY (record_type_id)
);
INSERT INTO "reduivy__Study_Term__c_rt_mapping" VALUES('0127X000001sv6rQAA','Academic_Term');
INSERT INTO "reduivy__Study_Term__c_rt_mapping" VALUES('0127X000001sv6sQAA','Academic_Year');
CREATE TABLE "reduivy__Study_Unit_Requirement__c" (
	id INTEGER NOT NULL, 
	"Name" VARCHAR(255), 
	"reduivy__Credits__c" VARCHAR(255), 
	"reduivy__External_Id__c" VARCHAR(255), 
	"reduivy__Other__c" VARCHAR(255), 
	"reduivy__Requirement_ID__c" VARCHAR(255), 
	"reduivy__Requirement_Type__c" VARCHAR(255), 
	"reduivy__Sample_Record_Code__c" VARCHAR(255), 
	"reduivy__Required_Study_Unit__c" VARCHAR(255), 
	"reduivy__Study_Unit__c" VARCHAR(255), 
	PRIMARY KEY (id)
);
INSERT INTO "reduivy__Study_Unit_Requirement__c" VALUES(1,'BUS201_BUS101','','','','BUS101','Pre-Requisite','BUS201_BUS101','1','7');
INSERT INTO "reduivy__Study_Unit_Requirement__c" VALUES(2,'BUS202_BUS101','','','','BUS101','Pre-Requisite','BUS202_BUS101','1','8');
INSERT INTO "reduivy__Study_Unit_Requirement__c" VALUES(3,'BUS202_BUS102','','','','BUS102','Pre-Requisite','BUS202_BUS102','2','8');
INSERT INTO "reduivy__Study_Unit_Requirement__c" VALUES(4,'BUS203_BUS101','','','','BUS101','Pre-Requisite','BUS203_BUS101','1','9');
INSERT INTO "reduivy__Study_Unit_Requirement__c" VALUES(5,'BUS203_BUS103','','','','BUS103','Pre-Requisite','BUS203_BUS103','3','9');
INSERT INTO "reduivy__Study_Unit_Requirement__c" VALUES(6,'MGT301_BUS201','','','','BUS201','Pre-Requisite','MGT301_BUS201','7','10');
INSERT INTO "reduivy__Study_Unit_Requirement__c" VALUES(7,'MGT301_CREDIT10','10.0','','','CREDIT10','Credits','MGT301_CREDIT10','','10');
INSERT INTO "reduivy__Study_Unit_Requirement__c" VALUES(8,'MGT302_BUS201','','','','BUS201','Pre-Requisite','MGT302_BUS201','7','11');
INSERT INTO "reduivy__Study_Unit_Requirement__c" VALUES(9,'MGT302_BUS203','','','','BUS203','Pre-Requisite (Enrolled or Completed)','MGT302_BUS203','9','11');
INSERT INTO "reduivy__Study_Unit_Requirement__c" VALUES(10,'MGT303_BUS201','','','','BUS201','Pre-Requisite','MGT303_BUS201','7','12');
INSERT INTO "reduivy__Study_Unit_Requirement__c" VALUES(11,'MGT303_BUS202','','','','BUS202','Pre-Requisite (Enrolled or Completed)','MGT303_BUS202','8','12');
INSERT INTO "reduivy__Study_Unit_Requirement__c" VALUES(12,'COM101_COM102','','','','COM102','Pre-Requisite (Enrolled or Completed)','COM101_COM102','14','13');
INSERT INTO "reduivy__Study_Unit_Requirement__c" VALUES(13,'COM101_MANUAL','','','','MANUAL','Other','COM101_MANUAL','','13');
INSERT INTO "reduivy__Study_Unit_Requirement__c" VALUES(14,'COM102_COM101','','','','COM101','Pre-Requisite (Enrolled or Completed)','COM102_COM101','13','14');
INSERT INTO "reduivy__Study_Unit_Requirement__c" VALUES(15,'COM102_MANUAL','','','','MANUAL','Other','COM102_MANUAL','','14');
INSERT INTO "reduivy__Study_Unit_Requirement__c" VALUES(16,'SEC301_COM101','','','','COM101','Pre-Requisite','SEC301_COM101','13','22');
INSERT INTO "reduivy__Study_Unit_Requirement__c" VALUES(17,'SEC301_BUS101','','','','BUS101','Pre-Requisite','SEC301_BUS101','1','22');
INSERT INTO "reduivy__Study_Unit_Requirement__c" VALUES(18,'SEC301_BUS102','','','','BUS102','Pre-Requisite','SEC301_BUS102','2','22');
INSERT INTO "reduivy__Study_Unit_Requirement__c" VALUES(19,'SEC302_COM101','','','','COM101','Pre-Requisite','SEC302_COM101','13','23');
INSERT INTO "reduivy__Study_Unit_Requirement__c" VALUES(20,'SEC302_COM102','','','','COM102','Pre-Requisite','SEC302_COM102','14','23');
INSERT INTO "reduivy__Study_Unit_Requirement__c" VALUES(21,'SEC302_BUS201','','','','BUS201','Pre-Requisite','SEC302_BUS201','7','23');
INSERT INTO "reduivy__Study_Unit_Requirement__c" VALUES(22,'SEC302_CREDIT20','20.0','','','CREDIT20','Credits','SEC302_CREDIT20','','23');
INSERT INTO "reduivy__Study_Unit_Requirement__c" VALUES(23,'SEC303_COM101','','','','COM101','Pre-Requisite','SEC303_COM101','13','24');
INSERT INTO "reduivy__Study_Unit_Requirement__c" VALUES(24,'SEC303_COM102','','','','COM102','Pre-Requisite','SEC303_COM102','14','24');
INSERT INTO "reduivy__Study_Unit_Requirement__c" VALUES(25,'SEC303_MAT201','','','','MAT201','Pre-Requisite','SEC303_MAT201','19','24');
INSERT INTO "reduivy__Study_Unit_Requirement__c" VALUES(26,'SEC303_MAT202','','','','MAT202','Pre-Requisite','SEC303_MAT202','20','24');
CREATE TABLE "reduivy__Study_Unit__c" (
	id INTEGER NOT NULL, 
	"Name" VARCHAR(255), 
	"reduivy__Credits__c" VARCHAR(255), 
	"reduivy__Default_EFTSL__c" VARCHAR(255), 
	"reduivy__Description__c" VARCHAR(255), 
	"reduivy__External_Id__c" VARCHAR(255), 
	"reduivy__Field_of_Study__c" VARCHAR(255), 
	"reduivy__Requirement_Description__c" VARCHAR(255), 
	"reduivy__Requirement_Logic__c" VARCHAR(255), 
	"reduivy__Sample_Record_Code__c" VARCHAR(255), 
	"reduivy__Unit_Code__c" VARCHAR(255), 
	"reduivy__Unit_Level__c" VARCHAR(255), 
	"reduivy__Educational_Institution__c" VARCHAR(255), 
	PRIMARY KEY (id)
);
INSERT INTO "reduivy__Study_Unit__c" VALUES(1,'BUS101','5.0','0.125','','','Business, Management, and Marketing','','','BUS101','BUS101','100','2');
INSERT INTO "reduivy__Study_Unit__c" VALUES(2,'BUS102','5.0','0.125','','','Business, Management, and Marketing','','','BUS102','BUS102','100','2');
INSERT INTO "reduivy__Study_Unit__c" VALUES(3,'BUS103','5.0','0.125','','','Business, Management, and Marketing','','','BUS103','BUS103','100','2');
INSERT INTO "reduivy__Study_Unit__c" VALUES(4,'MKT101','5.0','0.125','','','Business, Management, and Marketing','','','MKT101','MKT101','100','2');
INSERT INTO "reduivy__Study_Unit__c" VALUES(5,'MKT102','5.0','0.125','','','Business, Management, and Marketing','','','MKT102','MKT102','100','2');
INSERT INTO "reduivy__Study_Unit__c" VALUES(6,'MKT103','5.0','0.125','','','Business, Management, and Marketing','','','MKT103','MKT103','100','2');
INSERT INTO "reduivy__Study_Unit__c" VALUES(7,'BUS201','5.0','0.125','','','Business, Management, and Marketing','','BUS101','BUS201','BUS201','200','2');
INSERT INTO "reduivy__Study_Unit__c" VALUES(8,'BUS202','5.0','0.125','','','Business, Management, and Marketing','','BUS101 OR BUS102','BUS202','BUS202','200','2');
INSERT INTO "reduivy__Study_Unit__c" VALUES(9,'BUS203','5.0','0.125','','','Business, Management, and Marketing','','BUS101 OR BUS103','BUS203','BUS203','200','2');
INSERT INTO "reduivy__Study_Unit__c" VALUES(10,'MGT301','5.0','0.125','','','Business, Management, and Marketing','','BUS201 AND CREDIT10','MGT301','MGT301','300','2');
INSERT INTO "reduivy__Study_Unit__c" VALUES(11,'MGT302','5.0','0.125','','','Business, Management, and Marketing','','BUS201 AND NOT(BUS203)','MGT302','MGT302','300','2');
INSERT INTO "reduivy__Study_Unit__c" VALUES(12,'MGT303','5.0','0.125','','','Business, Management, and Marketing','','BUS201 AND NOT(BUS202)','MGT303','MGT303','300','2');
INSERT INTO "reduivy__Study_Unit__c" VALUES(13,'COM101','5.0','0.125','','','Computer and Information Sciences','','NOT(COM102) OR MANUAL','COM101','COM101','100','2');
INSERT INTO "reduivy__Study_Unit__c" VALUES(14,'COM102','5.0','0.125','','','Computer and Information Sciences','','NOT(COM101) OR MANUAL','COM102','COM102','100','2');
INSERT INTO "reduivy__Study_Unit__c" VALUES(15,'COM103','5.0','0.125','','','Computer and Information Sciences','','','COM103','COM103','100','2');
INSERT INTO "reduivy__Study_Unit__c" VALUES(16,'ICT101','5.0','0.125','','','Computer and Information Sciences','','','ICT101','ICT101','100','2');
INSERT INTO "reduivy__Study_Unit__c" VALUES(17,'ICT102','5.0','0.125','','','Computer and Information Sciences','','','ICT102','ICT102','100','2');
INSERT INTO "reduivy__Study_Unit__c" VALUES(18,'ICT103','5.0','0.125','','','Computer and Information Sciences','','','ICT103','ICT103','100','2');
INSERT INTO "reduivy__Study_Unit__c" VALUES(19,'MAT201','5.0','0.125','','','Computer and Information Sciences','','','MAT201','MAT201','200','2');
INSERT INTO "reduivy__Study_Unit__c" VALUES(20,'MAT202','5.0','0.125','','','Computer and Information Sciences','','','MAT202','MAT202','200','2');
INSERT INTO "reduivy__Study_Unit__c" VALUES(21,'MAT203','5.0','0.125','','','Computer and Information Sciences','','','MAT203','MAT203','200','2');
INSERT INTO "reduivy__Study_Unit__c" VALUES(22,'SEC301','5.0','0.125','','','Computer and Information Sciences','','COM101 AND (BUS101 OR BUS102)','SEC301','SEC301','300','2');
INSERT INTO "reduivy__Study_Unit__c" VALUES(23,'SEC302','5.0','0.125','','','Computer and Information Sciences','<strong>Requirement desc</strong>','(COM101 OR COM102) AND BUS201 AND CREDIT20','SEC302','SEC302','300','2');
INSERT INTO "reduivy__Study_Unit__c" VALUES(24,'SEC303','5.0','0.125','','','Computer and Information Sciences','','(COM101 OR COM102) AND (MAT201 OR MAT202)','SEC303','SEC303','300','2');
COMMIT;
