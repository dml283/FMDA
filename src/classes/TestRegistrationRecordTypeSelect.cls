@IsTest(SeeAllData = true)
public class TestRegistrationRecordTypeSelect{
    static TestMethod void TestNewRedirect(){
        ApexPages.StandardController sc = new ApexPages.StandardController(new Registration__c());
        RegistrationRecordTypeSelectController controller = new RegistrationRecordTypeSelectController(sc);
        Test.SetCurrentPage(Page.RegistrationRecordTypeSelect);
        controller.Redirect();
        
        List<RecordType> recordTypes = [
            SELECT ID, Name 
            FROM RecordType 
            WHERE SObjectType = 'Registration__c' AND IsActive = true
        ];
        for(RecordType item: recordTypes){
        	ApexPages.currentPage().getParameters().put('RecordType', item.Id);
            controller.Redirect();
        }
    }
    
    static TestMethod void TestEditRedirect(){
    	
		List<RecordType> recordTypes = [SELECT Id, Name FROM RecordType];
		
		// Map Namae, Id of RecordType
		Map<String, String> listRecordType = new Map<String,String>();
		for (RecordType r : recordTypes) {
			listRecordType.put (r.Name, r.Id);
		}
		// Create New Campaigns
		Election_Event__c camp = new Election_Event__c(Name='Test Campaign', RecordTypeId=listRecordType.get('Local Government Election Event'), 
                                     By_Election__c=true, Date_of_Election__c = Date.parse('30/05/2014'));
		upsert camp;
		
		// Create Account
		Account accountPerson = new Account(LastName = 'Test', FirstName='Name',RecordTypeId=listRecordType.get('Person') );
		upsert accountPerson;
    	
    	Registration__c entity = new Registration__c(Stakeholder__c = accountPerson.Id, Election_Event1__c = camp.Id);
    	insert entity;
    	
        ApexPages.StandardController sc = new ApexPages.StandardController(entity);
        RegistrationEditRedirectController controller = new RegistrationEditRedirectController(sc);
        Test.SetCurrentPage(Page.RegistrationEditRedirect);
        controller.Redirect();
        
        RecordType regType = [SELECT Id FROM RecordType WHERE Name = 'Group of Candidates'];
        entity.RecordTypeId = regType.Id;
        upsert entity;

        controller.Redirect();
    }
}