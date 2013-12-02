@IsTest(SeeAllData = true)
private class TestAccountTrigger{
    public static Map<string, sObject> Entities{get;set;}
    
    static TestMethod void Test_Account_AfterUpdate_UpdateOaa(){
        Init();
        Account acc = (Account)Entities.Get('AccountPerson');
        acc.Online_Training_Result_Outcome__c = '123';
        update acc;
        acc.Online_Training_Result_Outcome__c = 'Passed';
        update acc;
    }
    
    static void Init(){
        Entities = new Map<string, sObject>();
        List<RecordType> recordTypes = [SELECT Id, Name FROM RecordType];
        
        // Map Namae, Id of RecordType
        Map<String, String> listRecordType = new Map<String,String>();
        for (RecordType r : recordTypes) {
            listRecordType.put (r.Name, r.Id);
        }
        // Create New Campaigns
        Election_Event__c camp = new Election_Event__c(Name='Test Campaign', RecordTypeId=listRecordType.get('State Election Event'), 
                                     By_Election__c=true, Date_of_Election__c = Date.parse('30/05/2014'));
        upsert camp;
        
        // Create Account
        Account accountPerson = new Account(LastName = 'Test', FirstName='Name',RecordTypeId=listRecordType.get('Person') );
        upsert accountPerson;
        // Create Account Political Party
        Account accountParty = new Account(Name = 'Test Political Party',Party_Agent__c=accountPerson.Id, Registered_Officer__c=accountPerson.Id,
                                    RecordTypeId=listRecordType.get('Political Party') );
        upsert accountParty;
        
        Registration__c Registration = new Registration__c();
        Registration.Election_Event1__c = camp.Id;
        Registration.Stakeholder__c = accountPerson.Id;
        Registration.Official_Agent__c = accountPerson.Id;
        upsert Registration;
        
        Official_Agent_Appointment__c oaa1 = new Official_Agent_Appointment__c(Registration__c = Registration.Id, Official_Agent__c = accountPerson.Id, Status__c = 'Pending Agent Training', Date_Received__c = Date.Today());
        upsert oaa1;
        Official_Agent_Appointment__c oaa2 = new Official_Agent_Appointment__c(Registration__c = Registration.Id, Official_Agent__c = accountPerson.Id, Status__c = 'Active', Date_Received__c = Date.Today(), Date_From__c = Date.Today());
        upsert oaa2;
        Official_Agent_Appointment__c oaa3 = new Official_Agent_Appointment__c(Registration__c = Registration.Id, Official_Agent__c = accountPerson.Id, Status__c = 'Pending Agent Training');
        upsert oaa3;
        
        Entities.Put('AccountPerson', accountPerson);
        Entities.Put('AccountParty', accountParty);
        Entities.Put('Registration', Registration);
        Entities.Put('Oaa1', oaa1);
        Entities.Put('Oaa2', oaa2);
        Entities.Put('Oaa3', oaa3);
    }
}