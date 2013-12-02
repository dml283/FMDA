@isTest
public with sharing class TestPartyAgentAppointmentController {
    static Account accountPerson;
    static Account accountParty;
    static Party_Agent_Appointment__c paa;
	static testMethod void test() {
		InitialData();
    	Party_Agent_Appointment__c partyAgentApp = new Party_Agent_Appointment__c();
		// First Test Candidate Registration
    	PageReference pageRef = Page.CandidateRegistration;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('AccountId',accountParty.Id);
        ApexPages.StandardController stdController = new ApexPages.StandardController(partyAgentApp);
    	PartyAgentAppointmentController controller = new PartyAgentAppointmentController(stdController);
        controller.partyAgentApp.Party_Agent__c = accountPerson.Id;
        controller.partyAgentApp.Date_From__c = Date.Today();
        //controller.partyAgentApp.Political_Party__c = accountParty.Id;
        System.Debug('asd: ' + controller.partyAgentApp);
        controller.QuickSave();
        controller.CreateNew();
        controller.partyAgentApp.Party_Agent__c = accountPerson.Id;
        controller.QuickSave();
        controller.updatePoliticalParty();
        controller.updatePartyAgent();
        controller.updateOnlineTrainingDetails();
        controller.updateTrainingStatus();
        System.Debug('abc ' + controller.PartyAgentWrapper.size());
        //pageRef.getParameters().put('editid',controller.PartyAgentWrapper.get(1).Id);
        pageRef.getParameters().put('editid',controller.PartyAgentWrapper.get(0).Id);
        controller.editRow();
        controller.saveRow();
        controller.editRow();
        controller.cancelRow();
        pageRef.getParameters().put('delid',controller.PartyAgentWrapper.get(1).Id);
        controller.delRow();
        pageRef.getParameters().put('editid',controller.PartyAgentWrapper.get(0).Id);
        //controller.editPartyAgent();
        controller.sortByColumn = 'Party Agent Appointment Number';
        System.assertEquals(null, controller.sortData());
        System.assertEquals(null, controller.sortData());
        controller.sortByColumn = 'Party Agent';
        System.assertEquals(null, controller.sortData());
        controller.sortByColumn = 'Status';
        System.assertEquals(null, controller.sortData());
        controller.sortByColumn = 'Training Status';
        System.assertEquals(null, controller.sortData());
        controller.sortByColumn = 'Date From';
        System.assertEquals(null, controller.sortData());
        controller.sortByColumn = 'Date To';
        System.assertEquals(null, controller.sortData());
        controller.sortByColumn = 'Nothing';
        System.assertEquals(null, controller.sortData());
        controller.Save();
        controller.Cancel();
        
        //Create Party_Agent_Appointment__c for edit
        paa = new Party_Agent_Appointment__c(Party_Agent__c = accountPerson.Id, Political_Party__c = accountParty.Id); 
        upsert paa;
		ApexPages.StandardController stdController1 = new ApexPages.StandardController(paa);
    	PartyAgentAppointmentController controller1 = new PartyAgentAppointmentController(stdController1);
        
        
        /*
		System.assertEquals(null, controller.addDO());
		controller.DOWrapper.get(0).include = true;
		System.assertEquals(null, controller.deleteDO());
        System.assertEquals(null, controller.updateElectionDetail());
        controller.selectedID = controller.DOWrapper.get(0).Id;
        System.assertEquals(null, controller.updateDonationExpenditure());
        
        controller.sortByColumn = 'Reporting Period';
        System.assertEquals(null, controller.sortData());
        System.assertEquals(null, controller.sortData());
        controller.sortByColumn = 'Status';
        System.assertEquals(null, controller.sortData());
        controller.sortByColumn = 'Donations (Received) Cap';
        System.assertEquals(null, controller.sortData());
        controller.sortByColumn = 'Expenditure Cap';
        System.assertEquals(null, controller.sortData());
        controller.sortByColumn = 'Donations (Given) Cap';
        System.assertEquals(null, controller.sortData());
        controller.sortByColumn = 'Nothing';
        System.assertEquals(null, controller.sortData());
        
        System.assertNotEquals(null, controller.save());
		*/
    }
   
    static void InitialData()
    {
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
		accountPerson = new Account(LastName = 'Test', FirstName='Name',RecordTypeId=listRecordType.get('Person'), CPA_Membership_Number__c='8' );
		upsert accountPerson;
		// Create Account Political Party
		accountParty = new Account(Name = 'Test Political Party',Party_Agent__c=accountPerson.Id, Registered_Officer__c=accountPerson.Id,
									RecordTypeId=listRecordType.get('Political Party') );
		
		upsert accountParty;
		
        Table_Settings__c tablesetting = new Table_Settings__c(Name='PartyAgentAppointments');
        tablesetting.Column1_Name__c = 'Party Agent Appointment Number';
        tablesetting.Column2_Name__c = 'Party Agent';
        tablesetting.Column3_Name__c = 'Status';
        tablesetting.Column4_Name__c = 'Training Status';
        tablesetting.Column5_Name__c = 'Date From';
        tablesetting.Column6_Name__c = 'Date To';
        upsert tablesetting;
        
        Static_Label__c errorMessage = new Static_Label__c(Name='PartyAgentApp.Msg.2ActiveAgent', Content__c='abcd');
        upsert errorMessage;
        
        
    }
    
}