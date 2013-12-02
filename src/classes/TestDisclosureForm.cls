@isTest (SeeAllData = true)
public class TestDisclosureForm{
    static Map<string, SObject> Entities{get;set;}
    static Disclosure_Claim_for_Payment__c dcp;
    
    static TestMethod void TestNormalCases(){

        Init();
        Map<Id, RecordType> mapRecordType = new Map<Id, RecordType>([SELECT Id, Name FROM RecordType WHERE sObjectType = 'Disclosure_Claim_For_Payment__c']);
        
        Map<string,string> MapRecordType1 = new Map<string, string>();
        for(RecordType item: [SELECT Id, Name FROM RecordType WHERE sObjectType = 'Disclosure_Claim_For_Payment__c']){
            mapRecordType1.Put(item.Name, item.Id);
        }
        
        ApexPages.StandardController sc = new ApexPages.StandardController(new Disclosure_Claim_For_Payment__c());  
        Test.SetCurrentPage(Page.DisclosureForm);
        
        ApexPages.CurrentPage().GetParameters().Put('doid', Entities.Get('Do1').Id);        
        DisclosureFormController controller = new DisclosureFormController(sc);
        //System.Debug('bbbb '+ MapRecordType1.Get('Disclosure (Major Political Donor)'));
        //System.Debug('aa111 ' + abc[0].Registration__r.RecordType.Name  + ', ' +abc[0].Registration__r.Election_Event1__r.RecordType.Name + ', ' + controller.Entity.RecordTypeId);
        System.AssertEquals('Disclosure (Elected Member - Local Government Councillor)', mapRecordType.Get(controller.Entity.RecordTypeId).Name);
           
        ApexPages.CurrentPage().GetParameters().Put('doid', Entities.Get('Do2').Id);
        controller = new DisclosureFormController(sc);
        System.AssertEquals('Disclosure (Elected Member - Member of Parliament)', mapRecordType.Get(controller.Entity.RecordTypeId).Name);
         
        //ApexPages.CurrentPage().GetParameters().Put('doid', Entities.Get('Do3').Id);
        //controller = new DisclosureFormController(sc);
        //System.AssertEquals('Disclosure (Elected Member - Member of Parliament)', mapRecordType.Get(controller.Entity.RecordTypeId).Name);
         
        ApexPages.CurrentPage().GetParameters().Put('doid', Entities.Get('Do4').Id);
        controller = new DisclosureFormController(sc);
        System.AssertEquals('Disclosure (Group of Local Government Candidates)', mapRecordType.Get(controller.Entity.RecordTypeId).Name);
        /*
        ApexPages.CurrentPage().GetParameters().Put('doid', Entities.Get('Do5').Id);
        controller = new DisclosureFormController(sc);
        System.AssertEquals('Disclosure (Group of State Candidates)', mapRecordType.Get(controller.Entity.RecordTypeId).Name);
        
        ApexPages.CurrentPage().GetParameters().Put('doid', Entities.Get('Do6').Id);
        controller = new DisclosureFormController(sc);
        System.AssertEquals('Disclosure (Local Government Candidate)', mapRecordType.Get(controller.Entity.RecordTypeId).Name);
         
        ApexPages.CurrentPage().GetParameters().Put('doid', Entities.Get('Do7').Id);
        controller = new DisclosureFormController(sc);
        System.AssertEquals('Disclosure (Major Political Donor)', mapRecordType.Get(controller.Entity.RecordTypeId).Name);
        System.AssertEquals(true, controller.IsMajorPoliticalDonor) ;
        
        ApexPages.CurrentPage().GetParameters().Put('doid', Entities.Get('Do8').Id);
        controller = new DisclosureFormController(sc);
        System.AssertEquals('Disclosure (Political Party)', mapRecordType.Get(controller.Entity.RecordTypeId).Name);
        System.AssertEquals(((Account)Entities.Get('AccountParty')).Party_Agent__c, controller.Entity.Official_Agent__c) ;
        
        ApexPages.CurrentPage().GetParameters().Put('doid', Entities.Get('Do9').Id);
        controller = new DisclosureFormController(sc);
        System.AssertEquals('Disclosure (State Candidate)', mapRecordType.Get(controller.Entity.RecordTypeId).Name);
		*/
        //ApexPages.CurrentPage().GetParameters().Put('dcid', Entities.Get('Do10').Id);
        //controller = new DisclosureFormController(sc);
        //System.AssertEquals('Disclosure (State Candidate)', mapRecordType.Get(controller.Entity.RecordTypeId).Name);
        /* 
        ApexPages.CurrentPage().GetParameters().Put('doid', Entities.Get('Do11').Id);
        controller = new DisclosureFormController(sc);
        System.AssertEquals('Disclosure (Third-Party Campaigner)', mapRecordType.Get(controller.Entity.RecordTypeId).Name);
    	*/
    	controller.SaveAndNew();
        
        ApexPages.StandardController sc1 = new ApexPages.StandardController(dcp);    
        DisclosureFormController controller1 = new DisclosureFormController(sc1);
    }

    static void Init(){
        Entities = new Map<string, Sobject>();
		Map<String, String> listRecordType = new Map<String,String>();
		for (RecordType r : [SELECT Id, Name FROM RecordType]) {
			listRecordType.put (r.Name, r.Id);
		}
        List<RecordType> recordTypes = [SELECT Id, Name FROM RecordType Where Name='Disclosure (Major Political Donor)' Limit 1];
		String recordTypeId=recordTypes[0].Id;
        dcp = new Disclosure_Claim_for_Payment__c(RecordTypeId=recordTypeId);
		upsert dcp;
        Entities.put('dcp',dcp);
        
        Account accountPerson = new Account(LastName = 'Test', FirstName='Name',RecordTypeId=listRecordType.get('Person') );upsert accountPerson; Entities.Put('AccountPerson', accountPerson);
        Account accountParty = new Account(Name = 'Test Political Party',Party_Agent__c=accountPerson.Id, RecordTypeId=listRecordType.get('Political Party') );upsert accountParty; Entities.Put('AccountParty', accountParty);
        Entities.put('accountPerson',accountPerson);
        Entities.put('accountParty',accountParty);
        
        Election_Event__c localCamp = new Election_Event__c(RecordTypeId=listRecordType.get('Local Government Election Event'), Name='Test Campaign', By_Election__c=true, Date_of_Election__c = Date.parse('30/05/2014'));upsert localCamp;
        Election_Event__c groupCamp = new Election_Event__c(RecordTypeId=listRecordType.get('State Election Group'), Name='Test Campaign', By_Election__c=true, Date_of_Election__c = Date.parse('30/05/2014'));upsert groupCamp;
        Election_Event__c eventCamp = new Election_Event__c(RecordTypeId=listRecordType.get('State Election Event'), Name='Test Campaign', By_Election__c=true, Date_of_Election__c = Date.parse('30/05/2014'));upsert eventCamp;
        Entities.put('localCamp',localCamp);
        Entities.put('groupCamp',groupCamp);
        Entities.put('eventCamp',eventCamp);
        
        Registration__c reg1 = new Registration__c(RecordTypeId=listRecordType.get('Elected Member'), Election_Event1__c = localCamp.Id, Stakeholder__c = accountPerson.Id);upsert reg1;
        Registration__c reg2 = new Registration__c(RecordTypeId=listRecordType.get('Elected Member'), Election_Event1__c = eventCamp.Id, Stakeholder__c = accountPerson.Id);upsert reg2;
        //Registration__c reg3 = new Registration__c(RecordTypeId=listRecordType.get('Elected Member'), Election_Event__c = groupCamp.Id, Stakeholder__c = accountPerson.Id);upsert reg3;
        Registration__c reg4 = new Registration__c(RecordTypeId=listRecordType.get('Group of Candidates'), Election_Event1__c = localCamp.Id, Stakeholder__c = accountPerson.Id);upsert reg4;
        /*
        Registration__c reg5 = new Registration__c(RecordTypeId=listRecordType.get('Group of Candidates'), Election_Event1__c = eventCamp.Id, Stakeholder__c = accountPerson.Id);upsert reg5;
        Registration__c reg6 = new Registration__c(RecordTypeId=listRecordType.get('Candidate'), Election_Event1__c = localCamp.Id, Stakeholder__c = accountPerson.Id);upsert reg6;
        Registration__c reg7 = new Registration__c(RecordTypeId=listRecordType.get('Candidate'), Election_Event1__c = eventCamp.Id, Stakeholder__c = accountPerson.Id);upsert reg7;
        //Registration__c reg8 = new Registration__c(RecordTypeId=listRecordType.get('Candidate'), Election_Event__c = groupCamp.Id, Stakeholder__c = accountPerson.Id);upsert reg8;
        Registration__c reg9 = new Registration__c(RecordTypeId=listRecordType.get('Third-Party Campaigner'), Election_Event1__c = groupCamp.Id, Stakeholder__c = accountPerson.Id);upsert reg9;
        */
        Disclosure_Obligation__c do1 = new Disclosure_Obligation__c(Registration__c = reg1.Id, Stakeholder__c = accountPerson.Id); upsert do1; Entities.Put('Do1', do1);
        Disclosure_Obligation__c do2 = new Disclosure_Obligation__c(Registration__c = reg2.Id, Stakeholder__c = accountPerson.Id); upsert do2; Entities.Put('Do2', do2);
        //Disclosure_Obligation__c do3 = new Disclosure_Obligation__c(Registration__c = reg3.Id); upsert do3; Entities.Put('Do3', do3);
        Disclosure_Obligation__c do4 = new Disclosure_Obligation__c(Registration__c = reg4.Id, Stakeholder__c = accountPerson.Id); upsert do4; Entities.Put('Do4', do4);
        //Disclosure_Obligation__c do5 = new Disclosure_Obligation__c(Registration__c = reg5.Id, Stakeholder__c = accountPerson.Id); upsert do5; Entities.Put('Do5', do5);
        //Disclosure_Obligation__c do6 = new Disclosure_Obligation__c(Registration__c = reg6.Id, Stakeholder__c = accountPerson.Id); upsert do6; Entities.Put('Do6', do6);
        //Disclosure_Obligation__c do7 = new Disclosure_Obligation__c(Stakeholder__c = accountPerson.Id); upsert do7; Entities.Put('Do7', do7);
        //Disclosure_Obligation__c do8 = new Disclosure_Obligation__c(Stakeholder__c = accountParty.Id); upsert do8; Entities.Put('Do8', do8);
        //Disclosure_Obligation__c do9 = new Disclosure_Obligation__c(Registration__c = reg7.Id, Stakeholder__c = accountPerson.Id); upsert do9; Entities.Put('Do9', do9);
        //Disclosure_Obligation__c do10 = new Disclosure_Obligation__c(Registration__c = reg8.Id); upsert do10; Entities.Put('Do10', do10);
        //Disclosure_Obligation__c do11 = new Disclosure_Obligation__c(Registration__c = reg9.Id, Stakeholder__c = accountPerson.Id); upsert do11; Entities.Put('Do11', do11);
    }
    
    static TestMethod void TestAbnormalCases(){
        InitAbnormalCases();
        
        Map<Id, RecordType> mapRecordType = new Map<Id, RecordType>([SELECT Id, Name FROM RecordType WHERE sObjectType = 'Disclosure_Claim_For_Payment__c']);
        
        Map<string,string> MapRecordType1 = new Map<string, string>();
        for(RecordType item: [SELECT Id, Name FROM RecordType WHERE sObjectType = 'Disclosure_Claim_For_Payment__c']){
            mapRecordType1.Put(item.Name, item.Id);
        }
        
        ApexPages.StandardController sc = new ApexPages.StandardController(new Disclosure_Claim_For_Payment__c());  
        Test.SetCurrentPage(Page.DisclosureForm);

        ApexPages.CurrentPage().GetParameters().Put('doid', Entities.Get('Do5').Id);
        DisclosureFormController controller = new DisclosureFormController(sc);
        System.AssertEquals('Disclosure (Group of State Candidates)', mapRecordType.Get(controller.Entity.RecordTypeId).Name);
        
        ApexPages.CurrentPage().GetParameters().Put('doid', Entities.Get('Do6').Id);
        controller = new DisclosureFormController(sc);
        System.AssertEquals('Disclosure (Local Government Candidate)', mapRecordType.Get(controller.Entity.RecordTypeId).Name);
         
        ApexPages.CurrentPage().GetParameters().Put('doid', Entities.Get('Do7').Id);
        controller = new DisclosureFormController(sc);
        System.AssertEquals('Disclosure (Major Political Donor)', mapRecordType.Get(controller.Entity.RecordTypeId).Name);
        System.AssertEquals(true, controller.IsMajorPoliticalDonor) ;
        
        ApexPages.CurrentPage().GetParameters().Put('doid', Entities.Get('Do8').Id);
        controller = new DisclosureFormController(sc);
        System.AssertEquals('Disclosure (Political Party)', mapRecordType.Get(controller.Entity.RecordTypeId).Name);
        System.AssertEquals(((Account)Entities.Get('AccountParty')).Party_Agent__c, controller.Entity.Official_Agent__c) ;
        
        ApexPages.CurrentPage().GetParameters().Put('doid', Entities.Get('Do9').Id);
        controller = new DisclosureFormController(sc);
        System.AssertEquals('Disclosure (State Candidate)', mapRecordType.Get(controller.Entity.RecordTypeId).Name);
     
        ApexPages.CurrentPage().GetParameters().Put('doid', Entities.Get('Do11').Id);
        controller = new DisclosureFormController(sc);
        System.AssertEquals('Disclosure (Third-Party Campaigner)', mapRecordType.Get(controller.Entity.RecordTypeId).Name);
    }
    
    static void InitAbnormalCases(){
        Entities = new Map<string, Sobject>();
        Map<String, String> listRecordType = new Map<String,String>();
		for (RecordType r : [SELECT Id, Name FROM RecordType]) {
			listRecordType.put (r.Name, r.Id);
		}        
        Account accountPerson = new Account(LastName = 'Test', FirstName='Name',RecordTypeId=listRecordType.get('Person') );
        upsert accountPerson;       
        Entities.Put('accountPerson', accountPerson);
        Account accountParty = new Account(Name = 'Test Political Party',Party_Agent__c=accountPerson.Id, RecordTypeId=listRecordType.get('Political Party') );
        upsert accountParty; 
        Entities.Put('AccountParty', accountParty);
      
        Election_Event__c localCamp = new Election_Event__c(RecordTypeId=listRecordType.get('Local Government Election Event'), Name='Test Campaign', By_Election__c=true, Date_of_Election__c = Date.parse('30/05/2014'));upsert localCamp;
        Election_Event__c groupCamp = new Election_Event__c(RecordTypeId=listRecordType.get('State Election Group'), Name='Test Campaign', By_Election__c=true, Date_of_Election__c = Date.parse('30/05/2014'));upsert groupCamp;
        Election_Event__c eventCamp = new Election_Event__c(RecordTypeId=listRecordType.get('State Election Event'), Name='Test Campaign', By_Election__c=true, Date_of_Election__c = Date.parse('30/05/2014'));upsert eventCamp;
        
		Registration__c reg5 = new Registration__c(RecordTypeId=listRecordType.get('Group of Candidates'), Election_Event1__c = eventCamp.Id, Stakeholder__c = accountPerson.Id);upsert reg5;        
        Registration__c reg6 = new Registration__c(RecordTypeId=listRecordType.get('Candidate'), Election_Event1__c = localCamp.Id, Stakeholder__c = accountPerson.Id);upsert reg6;
        Registration__c reg7 = new Registration__c(RecordTypeId=listRecordType.get('Candidate'), Election_Event1__c = eventCamp.Id, Stakeholder__c = accountPerson.Id);upsert reg7;
        //Registration__c reg8 = new Registration__c(RecordTypeId=listRecordType.get('Candidate'), Election_Event__c = groupCamp.Id, Stakeholder__c = accountPerson.Id);upsert reg8;
        Registration__c reg9 = new Registration__c(RecordTypeId=listRecordType.get('Third-Party Campaigner'), Election_Event1__c = groupCamp.Id, Stakeholder__c = accountPerson.Id);upsert reg9;
        Disclosure_Obligation__c do5 = new Disclosure_Obligation__c(Registration__c = reg5.Id, Stakeholder__c = accountPerson.Id); upsert do5; Entities.Put('Do5', do5);
        Disclosure_Obligation__c do6 = new Disclosure_Obligation__c(Registration__c = reg6.Id, Stakeholder__c = accountPerson.Id); upsert do6; Entities.Put('Do6', do6);
        Disclosure_Obligation__c do7 = new Disclosure_Obligation__c(Stakeholder__c = accountPerson.Id); upsert do7; Entities.Put('Do7', do7);
        Disclosure_Obligation__c do8 = new Disclosure_Obligation__c(Stakeholder__c = accountParty.Id); upsert do8; Entities.Put('Do8', do8);
        Disclosure_Obligation__c do9 = new Disclosure_Obligation__c(Registration__c = reg7.Id, Stakeholder__c = accountPerson.Id); upsert do9; Entities.Put('Do9', do9);
        //Disclosure_Obligation__c do10 = new Disclosure_Obligation__c(Registration__c = reg8.Id); upsert do10; Entities.Put('Do10', do10);
        Disclosure_Obligation__c do11 = new Disclosure_Obligation__c(Registration__c = reg9.Id, Stakeholder__c = accountPerson.Id); upsert do11; Entities.Put('Do11', do11);
    }
}