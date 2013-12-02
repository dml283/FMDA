@IsTest
public class TestClaimForm{
 static Map<string, SObject> Entities{get;set;}
    
    static TestMethod void Test(){
        Init();
        ApexPages.StandardController sc = new ApexPages.StandardController(new Disclosure_Claim_For_Payment__c());  
        Test.SetCurrentPage(Page.ClaimForm);
        
        ApexPages.CurrentPage().GetParameters().Put('ecpid', Entities.Get('Ecp').Id);
        ClaimFormController controller = new ClaimFormController(sc);
        
        //controller.btnSelectRecordType_Click();
        controller.GetRecordTypes();
        controller.SaveAndNew();
    }
     
    static void Init(){
        Entities = new Map<string, Sobject>();
        Map<String, String> listRecordType = new Map<String,String>();
        for (RecordType r : [SELECT Id, Name FROM RecordType]) {
            listRecordType.put (r.Name, r.Id);
        }
        Account accountPerson = new Account(LastName = 'Test', FirstName='Name',RecordTypeId=listRecordType.get('Person') );upsert accountPerson;
        Account accountParty = new Account(Name = 'Test Political Party',Party_Agent__c=accountPerson.Id, Registered_Officer__c=accountPerson.Id,RecordTypeId=listRecordType.get('Political Party') );upsert accountParty;
        Election_Event__c localCamp = new Election_Event__c(RecordTypeId=listRecordType.get('Local Government Election Event'), Name='Test Campaign', By_Election__c=true, Date_of_Election__c = Date.parse('30/05/2014'));upsert localCamp;        
        Registration__c reg1 = new Registration__c(RecordTypeId=listRecordType.get('Elected Member'), Election_Event1__c = localCamp.Id, Stakeholder__c = accountPerson.Id);upsert reg1;
        Eligible_Claim_for_Payment__c ecp = new  Eligible_Claim_for_Payment__c(Registration__c = reg1.Id, Stakeholder__c = accountPerson.Id); upsert ecp; Entities.Put('Ecp', ecp);
    }
}