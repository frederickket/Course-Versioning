//Create Contact
List<Contact> contactsToBeCreated = new List<Contact>();
for(Integer i = 0; i < 31; i ++) {
    contactsToBeCreated.add(new Contact(
        FirstName = 'Test Term Enrollment Student',
        LastName = i.toString()
    ));
}

insert contactsToBeCreated;

List<reduivy__Individual_Program_Enrollment__c> existingIPE = [SELECT Id, reduivy__Default_Campus__c, reduivy__Study_Program__c, reduivy__Study_Plan__c, reduivy__Starting_Term__c, reduivy__Study_Pathway__c FROM reduivy__Individual_Program_Enrollment__c LIMIT 1];
List<reduivy__Individual_Program_Enrollment__c> ipeToBeCreated = new List<reduivy__Individual_Program_Enrollment__c>();

List<reduivy__Study_Intake__c> sitToBeCreated = new List<reduivy__Study_Intake__c>();
sitToBeCreated.add(new reduivy__Study_Intake__c(
    Name = 'Test Term Enrollment Study Intake',
    reduivy__Study_Program__c = existingIPE[0].reduivy__Study_Program__c,
    reduivy__Campus__c = existingIPE[0].reduivy__Default_Campus__c,
    reduivy__Academic_Term__c = existingIPE[0].reduivy__Starting_Term__c,
    reduivy__Default_Study_Plan__c = existingIPE[0].reduivy__Study_Plan__c,
    reduivy__Default_Study_Pathway__c = existingIPE[0].reduivy__Study_Pathway__c
));

insert sitToBeCreated;

List<reduivy__Study_Term__c> randomTerm = [SELECT Id FROM reduivy__Study_Term__c WHERE RecordTypeId = :STM_Helper.getAcademicTermRecordTypeId()];
List<reduivy__Study_Term__c> academicYear = [SELECT Id FROM reduivy__Study_Term__c WHERE RecordTypeId = :STM_Helper.getAcademicYearRecordTypeId()];

List<reduivy__Study_Term__c> toBeEnrolledTerm = new List<reduivy__Study_Term__c>();
toBeEnrolledTerm.add(new reduivy__Study_Term__c(
    Name = 'Test Term Enrollment To Be Enrolled Study Term',
    reduivy__Academic_Year__c = academicYear[0].Id,
    RecordTypeId = STM_Helper.getAcademicTermRecordTypeId(),
    reduivy__Start_Date__c = System.today(),
    reduivy__End_Date__c = System.today().addMonths(6),
    reduivy__Census_Date__c = System.today().addMonths(1)
));

List<reduivy__Study_Term__c> prevTerm = new List<reduivy__Study_Term__c>();
prevTerm.add(new reduivy__Study_Term__c(
    Name = 'Test Term Enrollment Previous Study Term',
    reduivy__Academic_Year__c = academicYear[0].Id,
    RecordTypeId = STM_Helper.getAcademicTermRecordTypeId(),
    reduivy__Start_Date__c = System.today().addMonths(-6),
    reduivy__End_Date__c = System.today().addMonths(-2),
    reduivy__Census_Date__c = System.today().addMonths(-5)
));

insert prevTerm;
insert toBeEnrolledTerm;

for(Integer i = 0; i < contactsToBeCreated.size(); i++) {
    ipeToBeCreated.add(new reduivy__Individual_Program_Enrollment__c(
        reduivy__Contact__c = contactsToBeCreated[i].Id,
        reduivy__Default_Campus__c = existingIPE[0].reduivy__Default_Campus__c,
        reduivy__Study_Program__c = existingIPE[0].reduivy__Study_Program__c,
        reduivy__Study_Plan__c = existingIPE[0].reduivy__Study_Plan__c,
        reduivy__Study_Intake__c = sitToBeCreated[0].Id,
        reduivy__Starting_Term__c = prevTerm[0].Id,
        reduivy__Enrollment_Status__c = IPE_Helper.getInProgressStatuses()[0],
        reduivy__Eligible_To_Enroll__c = true,
        reduivy__Study_Mode__c = 'Full-Time',
        reduivy__Study_Pathway_Mode__c = 'Default',
        reduivy__Study_Pathway__c = existingIPE[0].reduivy__Study_Pathway__c,
        RecordTypeId = IPE_Helper.getMasterEnrollmentRecordTypeId()
    ));
}

insert ipeToBeCreated;

List<reduivy__Individual_Program_Enrollment__c> ipes = [
    SELECT Id, Name, reduivy__Contact__c,
        (SELECT Id, reduivy__Term_Number__c, reduivy__Academic_Term__c, reduivy__Individual_Academic_Progress__c 
         FROM reduivy__Individual_Pathways__r
         ORDER BY reduivy__Term_Number__c)
    FROM reduivy__Individual_Program_Enrollment__c 
    WHERE reduivy__Contact_Name__c LIKE '%Test Term Enrollment%' 
    ORDER BY Name
];

List<reduivy__Study_Unit__c> studyUnits = [SELECT Id, Name FROM reduivy__Study_Unit__c];
List<reduivy__Study_Offering__c> studyOfferingsToBeCreated = new List<reduivy__Study_Offering__c>();

for(reduivy__Study_Unit__c su : studyUnits) {
    Decimal capacity = su.Name == 'MGT301' || su.Name == 'MGT302' ? 1 : 20;

    studyOfferingsToBeCreated.add(new reduivy__Study_Offering__c(
        reduivy__Capacity__c = capacity,
        reduivy__Study_Unit__c = su.Id,
        reduivy__Academic_Term__c = toBeEnrolledTerm[0].Id,
        reduivy__Campus__c = existingIPE[0].reduivy__Default_Campus__c,
        reduivy__Start_Date__c = toBeEnrolledTerm[0].reduivy__Start_Date__c,
        reduivy__End_Date__c = toBeEnrolledTerm[0].reduivy__End_Date__c
    ));    
}

insert studyOfferingsToBeCreated;

List<reduivy__Study_Pathway_Unit__c> spuWithApplicableStudyPlan = [SELECT Id, reduivy__Applicable_Study_Plan__c FROM reduivy__Study_Pathway_Unit__c WHERE reduivy__Study_Pathway_Term__r.reduivy__Study_Pathway__c = :existingIPE[0].reduivy__Study_Pathway__c AND (reduivy__Study_Unit__r.Name IN ('BUS101', 'BUS102', 'BUS103', 'COM101'))];

spuWithApplicableStudyPlan[0].reduivy__Applicable_Study_Plan__c = existingIPE[0].reduivy__Study_Plan__c;
spuWithApplicableStudyPlan[1].reduivy__Applicable_Study_Plan__c = existingIPE[0].reduivy__Study_Plan__c;
spuWithApplicableStudyPlan[2].reduivy__Applicable_Study_Plan__c = existingIPE[0].reduivy__Study_Plan__c;
spuWithApplicableStudyPlan[3].reduivy__Applicable_Study_Plan__c = existingIPE[0].reduivy__Study_Plan__c;
update spuWithApplicableStudyPlan;

List<reduivy__Individual_Program_Enrollment__c> ipesToBeUpdated = new List<reduivy__Individual_Program_Enrollment__c>();
List<reduivy__Individual_Program_Enrollment__c> ipesToBeCreated = new List<reduivy__Individual_Program_Enrollment__c>();
List<reduivy__Individual_Pathway__c> ipwsToBeUpdated = new List<reduivy__Individual_Pathway__c>();
List<reduivy__Individual_Pathway__c> ipwsToBeDeleted = new List<reduivy__Individual_Pathway__c>();
List<reduivy__Individual_Pathway__c> ipwsToBeCreated = new List<reduivy__Individual_Pathway__c>();
List<reduivy__Individual_Enrollment__c> ienToBeCreated = new List<reduivy__Individual_Enrollment__c>();
List<reduivy__Study_Offering__c> toBeEnrolledSof = [SELECT Id FROM reduivy__Study_Offering__c WHERE reduivy__Study_Unit__r.Name IN ('BUS101', 'BUS102', 'BUS103', 'COM101')];

for(Integer i = 0; i < 30; i ++) {
    reduivy__Individual_Program_Enrollment__c ipe = ipes[i];
    
    for (reduivy__Individual_Pathway__c pathway : ipe.reduivy__Individual_Pathways__r) {
        if(i == 0) {
            ipwsToBeDeleted.add(pathway);
        }
        
        if(i == 1) {
            if(pathway.reduivy__Term_Number__c == 1) {
            	ipwsToBeDeleted.add(pathway);
            }
        }
        
        if(i == 2) {
            if(pathway.reduivy__Term_Number__c == 1) {
                ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(
                	Id = pathway.Id,
                    reduivy__Individual_Academic_Progress__c = null,
                    reduivy__Academic_Term__c = toBeEnrolledTerm[0].Id
                ));
            }
        }
        
        if(i == 3) {
            if(pathway.reduivy__Term_Number__c == 1) {
                ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(
                	Id = pathway.Id,
                    reduivy__Individual_Academic_Progress__c = null,
                    reduivy__Academic_Term__c = randomTerm[0].Id
                ));
            }
            
            if(pathway.reduivy__Term_Number__c == 3) {
                ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(
                	Id = pathway.Id,
                    reduivy__Academic_Term__c = toBeEnrolledTerm[0].Id
                ));
            }
        }
        
        if(i == 4) {
            if(pathway.reduivy__Term_Number__c == 1) {
                ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(
                	Id = pathway.Id,
                    reduivy__Individual_Academic_Progress__c = null,
                    reduivy__Academic_Term__c = null
                ));
            }
        }
        
        if(i == 5) {
            if(pathway.reduivy__Term_Number__c == 1) {
                ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(
                	Id = pathway.Id,
                    reduivy__Individual_Academic_Progress__c = null,
                    reduivy__Academic_Term__c = randomTerm[0].Id
                ));
            }
        }
        
        if(i == 6) {
            if(pathway.reduivy__Term_Number__c == 2) {
                ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(
                	Id = pathway.Id,
                    reduivy__Academic_Term__c = toBeEnrolledTerm[0].Id
                ));
            }
        }
        
        if(i == 7) {
            if(pathway.reduivy__Term_Number__c == 3) {
                ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(
                	Id = pathway.Id,
                    reduivy__Academic_Term__c = toBeEnrolledTerm[0].Id
                ));
            }
        }
        
        if(i == 8) {
            break;
        }
        
        if(i == 9) {
            if(pathway.reduivy__Term_Number__c == 2) {
                ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(
                	Id = pathway.Id,
                    reduivy__Academic_Term__c = randomTerm[0].Id
                ));
            }
        }
        
        if(i == 10) {
            if(pathway.reduivy__Term_Number__c == 1) {
                ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(
                	Id = pathway.Id,
                    reduivy__Individual_Academic_Progress__c = null,
                    reduivy__Academic_Term__c = randomTerm[0].Id
                ));
            }
            
            if(pathway.reduivy__Term_Number__c == 2) {
                ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(
                	Id = pathway.Id,
                    reduivy__Academic_Term__c = randomTerm[1].Id
                ));
            }
            
            if(pathway.reduivy__Term_Number__c == 3) {
                ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(
                	Id = pathway.Id,
                    reduivy__Academic_Term__c = randomTerm[2].Id
                ));
            }
            
            if(pathway.reduivy__Term_Number__c == 4) {
                ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(
                	Id = pathway.Id,
                    reduivy__Academic_Term__c = prevTerm[0].Id
                ));
            }
        }
        
        if(i == 11) {
            if(pathway.reduivy__Term_Number__c == 1) {
                ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(
                	Id = pathway.Id,
                    reduivy__Individual_Academic_Progress__c = null,
                    reduivy__Academic_Term__c = null
                ));
            }
            
            if(pathway.reduivy__Term_Number__c == 3) {
                ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(
                	Id = pathway.Id,
                    reduivy__Academic_Term__c = randomTerm[0].Id
                ));
            }
        }
        
        if(i == 12) {
            if(pathway.reduivy__Term_Number__c == 1) {
                ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(
                	Id = pathway.Id,
                    reduivy__Individual_Academic_Progress__c = null,
                    reduivy__Academic_Term__c = null
                ));
            }
            
            if(pathway.reduivy__Term_Number__c == 4) {
                ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(
                	Id = pathway.Id,
                    reduivy__Academic_Term__c = randomTerm[0].Id
                ));
            }
        }
        
        if(i == 13) {
            if(pathway.reduivy__Term_Number__c == 1) {
                ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(
                	Id = pathway.Id,
                    reduivy__Individual_Academic_Progress__c = null,
                    reduivy__Academic_Term__c = null
                ));
            }
            
            if(pathway.reduivy__Term_Number__c == 3) {
                ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(
                	Id = pathway.Id,
                    reduivy__Academic_Term__c = toBeEnrolledTerm[0].Id
                ));
            }
        }
        
        if(i == 14) {    
            if(pathway.reduivy__Term_Number__c == 2) {
                ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(
                	Id = pathway.Id,
                    reduivy__Academic_Term__c = randomTerm[0].Id
                ));
            }
            
            if(pathway.reduivy__Term_Number__c == 3) {
                ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(
                	Id = pathway.Id,
                    reduivy__Academic_Term__c = toBeEnrolledTerm[0].Id
                ));
            }
        }
        
        if(i == 15) {
            if(pathway.reduivy__Term_Number__c == 1) {
                ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(
                	Id = pathway.Id,
                    reduivy__Individual_Academic_Progress__c = null,
                    reduivy__Academic_Term__c = null
                ));
            }
            
            if(pathway.reduivy__Term_Number__c == 4) {
                ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(
                	Id = pathway.Id,
                    reduivy__Academic_Term__c = prevTerm[0].Id
                ));
            }
        }
        
        if(i == 16) {
            if(pathway.reduivy__Term_Number__c == 1) {
                ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(
                	Id = pathway.Id,
                    reduivy__Individual_Academic_Progress__c = null,
                    reduivy__Academic_Term__c = null
                ));
            }
            
            if(pathway.reduivy__Term_Number__c == 4) {
                ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(
                	Id = pathway.Id,
                    reduivy__Academic_Term__c = toBeEnrolledTerm[0].Id
                ));
            }
        }
        
        if(i == 17) {
            if(pathway.reduivy__Term_Number__c == 1) {
                ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(
                	Id = pathway.Id,
                    reduivy__Individual_Academic_Progress__c = null,
                    reduivy__Academic_Term__c = null
                ));
            }
            
            if(pathway.reduivy__Term_Number__c == 2) {
                ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(
                	Id = pathway.Id,
                    reduivy__Academic_Term__c = prevTerm[0].Id
                ));
            }
            
            if(pathway.reduivy__Term_Number__c == 3) {
                ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(
                	Id = pathway.Id,
                    reduivy__Academic_Term__c = randomTerm[0].Id
                ));
            }
            
            if(pathway.reduivy__Term_Number__c == 4) {
                ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(
                	Id = pathway.Id,
                    reduivy__Academic_Term__c = toBeEnrolledTerm[0].Id
                ));
            }
        }
        
        if(i == 18) {
            if(pathway.reduivy__Term_Number__c == 1) {
                ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(
                	Id = pathway.Id,
                    reduivy__Individual_Academic_Progress__c = null,
                    reduivy__Academic_Term__c = null
                ));
            }
            
            if(pathway.reduivy__Term_Number__c == 2) {
                ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(
                	Id = pathway.Id,
                    reduivy__Academic_Term__c = prevTerm[0].Id
                ));
            }
            
            if(pathway.reduivy__Term_Number__c == 4) {
                ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(
                	Id = pathway.Id,
                    reduivy__Academic_Term__c = toBeEnrolledTerm[0].Id
                ));
            }
        }
        
        if(i == 19) {
            if(pathway.reduivy__Term_Number__c == 1) {
                ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(
                	Id = pathway.Id,
                    reduivy__Individual_Academic_Progress__c = null,
                    reduivy__Academic_Term__c = null
                ));
            }
            
            if(pathway.reduivy__Term_Number__c == 2) {
                ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(
                	Id = pathway.Id,
                    reduivy__Academic_Term__c = prevTerm[0].Id
                ));
            }
            
            if(pathway.reduivy__Term_Number__c == 3) {
                ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(
                	Id = pathway.Id,
                    reduivy__Academic_Term__c = randomTerm[0].Id
                ));
            }
        }
        
        if(i == 20) {
            if(pathway.reduivy__Term_Number__c == 1) {
                ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(
                	Id = pathway.Id,
                    reduivy__Individual_Academic_Progress__c = null,
                    reduivy__Academic_Term__c = null
                ));
            }
            
            if(pathway.reduivy__Term_Number__c == 3) {
                ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(
                	Id = pathway.Id,
                    reduivy__Academic_Term__c = prevTerm[0].Id
                ));
            }
            
            if(pathway.reduivy__Term_Number__c == 4) {
                ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(
                	Id = pathway.Id,
                    reduivy__Academic_Term__c = randomTerm[0].Id
                ));
            }
        }
        
        if(i == 21) {
            if(pathway.reduivy__Term_Number__c == 1) {
                ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(
                	Id = pathway.Id,
                    reduivy__Individual_Academic_Progress__c = null,
                    reduivy__Academic_Term__c = null
                ));
            }
            
            if(pathway.reduivy__Term_Number__c == 2) {
                ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(
                	Id = pathway.Id,
                    reduivy__Academic_Term__c = prevTerm[0].Id
                ));
            }
            
            if(pathway.reduivy__Term_Number__c == 3) {
                ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(
                	Id = pathway.Id,
                    reduivy__Academic_Term__c = prevTerm[0].Id
                ));
            }
        }
        
        if(i == 22) {
            if(pathway.reduivy__Term_Number__c == 1) {
                ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(
                	Id = pathway.Id,
                    reduivy__Individual_Academic_Progress__c = null,
                    reduivy__Academic_Term__c = null
                ));
            }
            
            if(pathway.reduivy__Term_Number__c == 2) {
                ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(
                	Id = pathway.Id,
                    reduivy__Academic_Term__c = toBeEnrolledTerm[0].Id
                ));
            }
            
            if(pathway.reduivy__Term_Number__c == 3) {
                ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(
                	Id = pathway.Id,
                    reduivy__Academic_Term__c = toBeEnrolledTerm[0].Id
                ));
            }
        }
        
        if(i == 23) {
            if(pathway.reduivy__Term_Number__c == 1) {
                ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(
                	Id = pathway.Id,
                    reduivy__Individual_Academic_Progress__c = null,
                    reduivy__Academic_Term__c = null
                ));
            }
            
            if(pathway.reduivy__Term_Number__c == 2) {
                ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(
                	Id = pathway.Id,
                    reduivy__Academic_Term__c = prevTerm[0].Id
                ));
            }
        }
        
        if(i == 24) {
            if(pathway.reduivy__Term_Number__c == 1) {
                ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(
                	Id = pathway.Id,
                    reduivy__Individual_Academic_Progress__c = null,
                    reduivy__Academic_Term__c = randomTerm[0].Id
                ));
            }
            
            if(pathway.reduivy__Term_Number__c == 2) {
                ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(
                	Id = pathway.Id,
                    reduivy__Academic_Term__c = prevTerm[0].Id
                ));
            }
        }
        
        if(i == 25) {
            if(pathway.reduivy__Term_Number__c == 1) {
                ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(
                	Id = pathway.Id,
                    reduivy__Individual_Academic_Progress__c = null,
                    reduivy__Academic_Term__c = null
                ));

                ienToBeCreated.add(new reduivy__Individual_Enrollment__c(
                    reduivy__Contact__c = ipe.reduivy__Contact__c,
                    reduivy__Study_Offering__c = toBeEnrolledSof[0].Id,
                    RecordTypeId = IEN_Helper.getStudentRecordTypeId(),
                    reduivy__Enrollment_Status__c = IEN_Helper.getInProgressStatuses()[0],
                    reduivy__Bypass_Requirement_Met__c = true
                ));

                ienToBeCreated.add(new reduivy__Individual_Enrollment__c(
                    reduivy__Contact__c = ipe.reduivy__Contact__c,
                    reduivy__Study_Offering__c = toBeEnrolledSof[1].Id,
                    RecordTypeId = IEN_Helper.getStudentRecordTypeId(),
                    reduivy__Enrollment_Status__c = IEN_Helper.getInProgressStatuses()[0],
                    reduivy__Bypass_Requirement_Met__c = true
                ));

                ienToBeCreated.add(new reduivy__Individual_Enrollment__c(
                    reduivy__Contact__c = ipe.reduivy__Contact__c,
                    reduivy__Study_Offering__c = toBeEnrolledSof[2].Id,
                    RecordTypeId = IEN_Helper.getStudentRecordTypeId(),
                    reduivy__Enrollment_Status__c = IEN_Helper.getInProgressStatuses()[0],
                    reduivy__Bypass_Requirement_Met__c = true
                ));

                ienToBeCreated.add(new reduivy__Individual_Enrollment__c(
                    reduivy__Contact__c = ipe.reduivy__Contact__c,
                    reduivy__Study_Offering__c = toBeEnrolledSof[3].Id,
                    RecordTypeId = IEN_Helper.getStudentRecordTypeId(),
                    reduivy__Enrollment_Status__c = IEN_Helper.getInProgressStatuses()[0],
                    reduivy__Bypass_Requirement_Met__c = true
                ));
            }
        }
        
        if(i == 26) {
            if(pathway.reduivy__Term_Number__c == 1) {
                ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(
                	Id = pathway.Id,
                    reduivy__Individual_Academic_Progress__c = null,
                    reduivy__Academic_Term__c = randomTerm[0].Id
                ));
            }
            
            if(pathway.reduivy__Term_Number__c == 2) {
                ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(
                	Id = pathway.Id,
                    reduivy__Academic_Term__c = prevTerm[0].Id
                ));
            }
        }
        
        if(i == 27) {
            if(pathway.reduivy__Term_Number__c == 1) {
                ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(
                	Id = pathway.Id,
                    reduivy__Individual_Academic_Progress__c = null,
                    reduivy__Academic_Term__c = null
                ));

                ipesToBeUpdated.add(new reduivy__Individual_Program_Enrollment__c(
                	Id = ipe.Id,
                    reduivy__Study_Plan__c = null
                ));

                ipesToBeCreated.add(new reduivy__Individual_Program_Enrollment__c(
                    RecordTypeId = IPE_Helper.getChildEnrollmentRecordTypeId(),
                    reduivy__Study_Plan__c = existingIPE[0].reduivy__Study_Plan__c,
                    reduivy__Study_Program__c = existingIPE[0].reduivy__Study_Program__c,
                    reduivy__Contact__c = ipe.reduivy__Contact__c,
                    reduivy__Master_Enrollment__c = ipe.Id
                ));
            }
        }
        
        if(i == 28) {
            if(pathway.reduivy__Term_Number__c == 1) {
                ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(
                	Id = pathway.Id,
                    reduivy__Individual_Academic_Progress__c = null,
                    reduivy__Academic_Term__c = null
                ));

                ipesToBeUpdated.add(new reduivy__Individual_Program_Enrollment__c(
                	Id = ipe.Id,
                    reduivy__Study_Plan__c = null
                ));
            }
        } 

        if(i == 29) {
            if(pathway.reduivy__Term_Number__c == 1) {
                ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(
                	Id = pathway.Id,
                    reduivy__Individual_Academic_Progress__c = null,
                    reduivy__Academic_Term__c = null
                ));
            }

            if(pathway.reduivy__Term_Number__c == 4) {
                ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(
                	Id = pathway.Id,
                    reduivy__Academic_Term__c = prevTerm[0].Id
                ));

                ipwsToBeCreated.add(new reduivy__Individual_Pathway__c(
                    reduivy__Individual_Program_Enrollment__c = ipe.Id,
                    reduivy__Term_Number__c = 5,
                    reduivy__Recommended_Credits__c = 40
                ));
            }
        }
    }   
}

update ipesToBeUpdated;
delete ipwsToBeDeleted;
insert ienToBeCreated;
update ipwsToBeUpdated;
insert ipwsToBeCreated;
insert ipesToBeCreated;
