@isTest
public with sharing class TestStakeholderController {	
	static testMethod void TestPersonController() {
    	InitialData();
    	PageReference pageRef = Page.PersonSearch;
        Test.setCurrentPage(pageRef);
		pageRef.getParameters().put('fid','testid');
    	PersonSearchController controller = new PersonSearchController(); 
		
		controller.PersonContact.Salutation = 'Mr.';
		controller.PersonContact.FirstName = 'Name';
		controller.PersonContact.LastName = 'Test';
		
		controller.SearchFADMS();
		controller.Cancel();
		pageRef.getParameters().put('AccountSortingInfo','FirstName');
		controller.Sort();
        controller.Sort();
        controller.Sort();
        controller.SwitchSearchType();
        controller.Clear();
        controller.SwitchSearchType();
        controller.Clear();
        //controller.PersonContact.Salutation = 'Mr.';
		controller.PersonContact.FirstName = 'Name';
		controller.PersonContact.LastName = 'Test';
        controller.SearchFADMS();
        pageRef.getParameters().put('accountIdToFill',controller.Accounts[0].Id);
        controller.FillElectoralSearchParam();
        controller.QuickSaveAccount();
        controller.SaveAccountAndClose();
        controller.NotOnElectoralRoll();
        //controller.JsonElectoralRoll  = '{"FirstName":"fa","LastName":"fa","Dob":"fa","Occupation":"fa","SilentElector":"fa","Street":"fa","City":"fa","PostCode":"fa"}';
        controller.SelectElectoralRoll();
        //PersonSearchController.ElectoralRollWrapper c = controller.ElectoralRoll;
        String a = controller.QueryString;
        controller.CopyErToStakeholder();
    }
	
	static testMethod void TestEntityController() {
    	
    	PageReference pageRef = Page.EntitySearch;
        Test.setCurrentPage(pageRef);
		pageRef.getParameters().put('fid','testid');
    	EntitySearchController controller = new EntitySearchController(); 
		System.assertNotEquals(null, controller.CreateStakeHolder());
		controller.Acc.Name = 'Test Entity';
		
		controller.QuickSaveAccount();
		controller.Cancel();
		pageRef.getParameters().put('AccountSortingInfo','Name');
		controller.Sort();
        controller.Sort();
        controller.Sort();
		pageRef.getParameters().put('accountIdToUpdate',controller.Acc.Id);
		controller.UpdateStakeHolder();
		
		controller.SaveAccountAndClose();
    }
    
	
	static testMethod void TestPoliticalPartySearchController() {
    	
    	PageReference pageRef = Page.PoliticalPartySearch;
        Test.setCurrentPage(pageRef);
		pageRef.getParameters().put('fid','testid');
    	PoliticalSearchController controller = new PoliticalSearchController(); 
        controller.Sort();
    }
    
    static void InitialData() {
        List<RecordType> recordTypes = [SELECT Id, Name FROM RecordType];
		
		// Map Namae, Id of RecordType
		Map<String, String> listRecordType = new Map<String,String>();
		for (RecordType r : recordTypes) {
			listRecordType.put (r.Name, r.Id);
		}
        Account accountPerson = new Account(FirstName='Name', LastName='Test',FADMS_Elector_ID__c='zzzzzzz1',RecordTypeId=listRecordType.get('Person') );
		upsert accountPerson;
    }
}