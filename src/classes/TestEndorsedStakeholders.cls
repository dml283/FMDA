@IsTest(SeeAllData=true)
public class TestEndorsedStakeholders{
 	static Map<string, SObject> Entities{get;set;}
    
    static TestMethod void Test(){
        Init();
        PageReference pageRef = Page.EndorsedStakeholders;
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardController stdController = new ApexPages.StandardController(Entities.get('ecpAdmin'));
        EndorsedStakeholdersController ctl = new EndorsedStakeholdersController(stdController);
        ctl.GetFieldSets();
        
        ctl.UnRelatedEndorsedList.Entities.get(0).IsSelected = true;
        ctl.btnAddEndorsed_OnClick();
        ctl.RelatedEndorsedList.Entities.get(0).IsSelected = true;
        ctl.RelatedEndorsedList.btnConfirmEndorsed_OnClick();
        ctl.RelatedEndorsedList.btnUnconfirmEndorsed_OnClick();
        ctl.btnRemoveEndorsed_OnClick();
        
        pageRef.getParameters().put('sortByColumn','Name');
        pageRef.getParameters().put('sortDirection','ASC');
        
        ctl.UnRelatedEndorsedList.Sort();
    }
     
    static void Init(){
        Entities = new Map<string, Sobject>();
        List<sObject> uplist = new List<sObject>();
        Map<String, String> listRecordType = new Map<String,String>();
		for (RecordType r : [SELECT Id, Name FROM RecordType]) {
			listRecordType.put (r.Name, r.Id);
		}
        
        Account accountPerson = new Account(LastName = 'Test', FirstName='Name',RecordTypeId=listRecordType.get('Person') );
        insert accountPerson;
        // Create Account Political Party
		Account accountParty = new Account(Name = 'Test Political Party',Party_Agent__c=accountPerson.Id, Registered_Officer__c=accountPerson.Id,
									RecordTypeId=listRecordType.get('Political Party') );
        insert accountParty;
        Election_Event__c parentCamp = new Election_Event__c(RecordTypeId=listRecordType.get('Local Government Election Group'), Name='Test Campaign', By_Election__c=true, Date_of_Election__c = Date.parse('30/05/2014'));
        insert parentCamp;
        Election_Event__c localCamp = new Election_Event__c(Parent_Election_Event__c=parentCamp.Id, RecordTypeId=listRecordType.get('Local Government Election Event'), 
                                                            Name='Test Campaign', By_Election__c=false, Date_of_Election__c = Date.parse('30/05/2014'));
        insert localCamp;
        Registration__c reg1 = new Registration__c(RecordTypeId=listRecordType.get('Elected Member'), Political_Party__c=accountParty.Id,
                                                   Election_Event1__c = localCamp.Id, Stakeholder__c = accountPerson.Id);
        Registration__c reg2 = new Registration__c(RecordTypeId=listRecordType.get('Elected Member'), Political_Party__c=accountParty.Id,
                                                   Election_Event1__c = localCamp.Id, Stakeholder__c = accountPerson.Id);
        Registration__c reg3 = new Registration__c(RecordTypeId=listRecordType.get('Candidate'), Political_Party__c=accountParty.Id,
                                                   Election_Event1__c = localCamp.Id, Stakeholder__c = accountPerson.Id);
        uplist.add(reg1);
        uplist.add(reg2);
        uplist.add(reg3);
        insert uplist;
        
        Eligible_Claim_for_Payment__c ecpAdmin = new  Eligible_Claim_for_Payment__c(Stakeholder__c = accountParty.Id,
                                                                               Public_Fund__c = 'Administration Fund',Election_Event__c=parentCamp.Id);
        insert ecpAdmin;
		
        Eligible_Claim_for_Payment__c ecpPol = new  Eligible_Claim_for_Payment__c( Stakeholder__c = accountParty.Id,
                                                                               Public_Fund__c = 'Policy Development Fund',Election_Event__c=parentCamp.Id);
        insert ecpPol;
        Entities.put('ecpAdmin',ecpAdmin);
        Entities.put('ecpPol',ecpPol);
    }
}