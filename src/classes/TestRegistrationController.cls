@isTest(SeeAllData=true)
public with sharing class TestRegistrationController {
    static Election_Event__c camp1;
    
	static testMethod void TestCandidateRegistration() {
		Registration__c Registration =	InitialData();
    	
		// First Test Candidate Registration
    	PageReference pageRef = Page.CandidateRegistration;
        Test.setCurrentPage(pageRef);
        //pageRef.getParameters().put('RecordType',);
        ApexPages.StandardController stdController = new ApexPages.StandardController(Registration);
    	CandidateRegistrationController controller = new CandidateRegistrationController(stdController); 
		
		//System.assertEquals(null, controller.addDO());
		//controller.DOWrapper.get(0).include = true;
		//System.assertEquals(null, controller.deleteDO());
        System.assertEquals(null, controller.updateElectionDetail());
        //controller.selectedID = controller.DOWrapper.get(0).Id;
        //System.assertEquals(null, controller.updateDonationExpenditure());
        
        //controller.sortByColumn = 'Reporting Period';
        //System.assertEquals(null, controller.sortData());
        //System.assertEquals(null, controller.sortData());
        //controller.sortByColumn = 'Status';
        //System.assertEquals(null, controller.sortData());
        ////controller.sortByColumn = 'Donations (Received) Cap';
        //controller.sortByColumn = 'Donation Cap';
        //System.assertEquals(null, controller.sortData());
        //controller.sortByColumn = 'Expenditure Cap';
        //System.assertEquals(null, controller.sortData());
        ////controller.sortByColumn = 'Donations (Given) Cap';
        ////System.assertEquals(null, controller.sortData());
        //controller.sortByColumn = 'Nothing';
        //System.assertEquals(null, controller.sortData());
        System.debug('vinhvinh: bf save');
       	controller.save();
        System.debug('vinhvinh: af save');
        Registration.Election_Event1__c = camp1.Id;
        System.assertEquals(null, controller.updateElectionDetail());
        controller.save();
        //System.assertNotEquals(null, controller.save());
        controller.QuickSave();
        controller.Cancel();
    }
    /*
    static testMethod void TestGroupCandidateRegistration() {
		Registration__c Registration =	InitialData();
    	
		// First Test Candidate Registration
    	PageReference pageRef = Page.GroupCandidateRegistration;
        Test.setCurrentPage(pageRef);
        //pageRef.getParameters().put('RecordType',);
        ApexPages.StandardController stdController = new ApexPages.StandardController(Registration);
    	GroupCandidateRegistrationController controller = new GroupCandidateRegistrationController(stdController); 
		
        controller.QuickSave();
		//System.assertEquals(null, controller.addDO());
		//controller.DOWrapper.get(0).include = true;
		//System.assertEquals(null, controller.deleteDO());
        System.assertEquals(null, controller.updateElectionDetail());
        //controller.selectedID = controller.DOWrapper.get(0).Id;
        //System.assertEquals(null, controller.updateDonationExpenditure());
        
        //controller.sortByColumn = 'Reporting Period';
        //System.assertEquals(null, controller.sortData());
        //System.assertEquals(null, controller.sortData());
        //controller.sortByColumn = 'Status';
        //System.assertEquals(null, controller.sortData());
        ////controller.sortByColumn = 'Donations (Received) Cap';
        //controller.sortByColumn = 'Donation Cap';
        //System.assertEquals(null, controller.sortData());
        //controller.sortByColumn = 'Expenditure Cap';
        //System.assertEquals(null, controller.sortData());
        ////controller.sortByColumn = 'Donations (Given) Cap';
        ////System.assertEquals(null, controller.sortData());
        //controller.sortByColumn = 'Nothing';
        //System.assertEquals(null, controller.sortData());
        
        System.assertEquals(null, controller.addGM());
		controller.GMWrapper.get(1).include = true;
		System.assertEquals(null, controller.deleteGM());
        controller.headCandidate.Political_Party__c = null;
        controller.updateHeadCandidateInTable();
        System.assertEquals(null, controller.updateHeadCandidate());
        
        controller.sortByColumnGroup = 'Candidate Name';
        System.assertEquals(null, controller.sortDataGroup());
        System.assertEquals(null, controller.sortDataGroup());
        controller.sortByColumnGroup = 'Political Party';
        System.assertEquals(null, controller.sortDataGroup());
        controller.sortByColumnGroup = 'Head Candidate';
        System.assertEquals(null, controller.sortDataGroup());
        controller.sortByColumnGroup = 'Confirm Signed by Candidate';
        System.assertEquals(null, controller.sortDataGroup());
        controller.sortByColumnGroup = 'Nothing';
        System.assertEquals(null, controller.sortDataGroup());
        
        controller.save();
        Registration.Election_Event1__c = camp1.Id;
        System.assertEquals(null, controller.updateElectionDetail());
        controller.save();
        //System.assertNotEquals(null, controller.save());
        //QuickSave
        //controller.QuickSave();
        
    }
    
    static testMethod void TestCampaignerRegistration() {
		Registration__c Registration =	InitialData();
    	
		// First Test Candidate Registration
    	PageReference pageRef = Page.CampaignerReg;
        Test.setCurrentPage(pageRef);
        //pageRef.getParameters().put('RecordType',);
        ApexPages.StandardController stdController = new ApexPages.StandardController(Registration);
    	CampaignerRegController controller = new CampaignerRegController(stdController); 
		
		//System.assertEquals(null, controller.addDO());
		//controller.DOWrapper.get(0).include = true;
		//System.assertEquals(null, controller.deleteDO());
        //System.assertEquals(null, controller.updateElectionDetail());
        //controller.selectedID = controller.DOWrapper.get(0).Id;
        //System.assertEquals(null, controller.updateDonationExpenditure());
        
        //controller.sortByColumn = 'Reporting Period';
        //System.assertEquals(null, controller.sortData());
        //System.assertEquals(null, controller.sortData());
        //controller.sortByColumn = 'Status';
        //System.assertEquals(null, controller.sortData());
        ////controller.sortByColumn = 'Donations (Received) Cap';
        //controller.sortByColumn = 'Donation Cap';
        //System.assertEquals(null, controller.sortData());
        //controller.sortByColumn = 'Expenditure Cap';
        //System.assertEquals(null, controller.sortData());
        ////controller.sortByColumn = 'Donations (Given) Cap';
        ////System.assertEquals(null, controller.sortData());
        //controller.sortByColumn = 'Nothing';
        //System.assertEquals(null, controller.sortData());
        
        controller.getElectionDetail();
        controller.save();
        Registration.Election_Event1__c = camp1.Id;
        controller.getElectionDetail();
        controller.save();
        //System.assertNotEquals(null, controller.save());
        controller.QuickSave();
        controller.Cancel();
    }
    
    static testMethod void TestElectedMemberRegistration() {
		Registration__c Registration =	InitialData();
    	
		// First Test Candidate Registration
    	PageReference pageRef = Page.ElectedMemReg;
        Test.setCurrentPage(pageRef);
        //pageRef.getParameters().put('RecordType',);
        ApexPages.StandardController stdController = new ApexPages.StandardController(Registration);
    	ElectedMemRegController controller = new ElectedMemRegController(stdController); 
		
		//System.assertEquals(null, controller.addDO());
		//controller.DOWrapper.get(0).include = true;
		//System.assertEquals(null, controller.deleteDO());
        //System.assertEquals(null, controller.updateElectionDetail());
        //controller.selectedID = controller.DOWrapper.get(0).Id;
        //System.assertEquals(null, controller.updateDonationExpenditure());
        
        //controller.sortByColumn = 'Reporting Period';
        //System.assertEquals(null, controller.sortData());
        //System.assertEquals(null, controller.sortData());
        //controller.sortByColumn = 'Status';
        //System.assertEquals(null, controller.sortData());
        ////controller.sortByColumn = 'Donations (Received) Cap';
        //controller.sortByColumn = 'Donation Cap';
        //System.assertEquals(null, controller.sortData());
        //controller.sortByColumn = 'Expenditure Cap';
        //System.assertEquals(null, controller.sortData());
        ////controller.sortByColumn = 'Donations (Given) Cap';
        ////System.assertEquals(null, controller.sortData());
        //controller.sortByColumn = 'Nothing';
        //System.assertEquals(null, controller.sortData());
        controller.setDefaultTermDate();
        controller.save();
        Registration.Election_Event1__c = camp1.Id;
        controller.setDefaultTermDate();
        controller.save();
        //System.assertNotEquals(null, controller.save());
        controller.QuickSave();
        controller.Cancel();
    }
    static testMethod void TestGroupCandidateEdit() {
		Registration__c Registration =	InitialData();
    	upsert Registration;
		// First Test Candidate Registration
    	PageReference pageRef = Page.GroupCandidateEdit;
        Test.setCurrentPage(pageRef);
        //pageRef.getParameters().put('RecordType',);
        ApexPages.StandardController stdController = new ApexPages.StandardController(Registration);
    	GroupCandidateEditController controller = new GroupCandidateEditController(stdController); 
        
        //controller.Cancel();
		controller.QuickSave();
        //controller.addDO();
		//System.assertEquals(null, controller.addDO());
		//controller.DOWrapper.get(0).include = true;
		//System.assertEquals(null, controller.deleteDO());
        System.assertEquals(null, controller.updateElectionDetail());
        //controller.selectedID = controller.DOWrapper.get(0).Id;
        //System.assertEquals(null, controller.updateDonationExpenditure());
        
        //controller.sortByColumn = 'Reporting Period';
        //System.assertEquals(null, controller.sortData());
        //System.assertEquals(null, controller.sortData());
        //controller.sortByColumn = 'Status';
        //System.assertEquals(null, controller.sortData());
        ////controller.sortByColumn = 'Donations (Received) Cap';
        //controller.sortByColumn = 'Donation Cap';
        //System.assertEquals(null, controller.sortData());
        //controller.sortByColumn = 'Expenditure Cap';
        //System.assertEquals(null, controller.sortData());
        ////controller.sortByColumn = 'Donations (Given) Cap';
        ////System.assertEquals(null, controller.sortData());
        //controller.sortByColumn = 'Nothing';
        //System.assertEquals(null, controller.sortData());
        
        System.assertEquals(null, controller.addGM());
		controller.GMWrapper.get(1).include = true;
		System.assertEquals(null, controller.deleteGM());
        System.assertEquals(null, controller.updateHeadCandidate());
        
        controller.sortByColumnGroup = 'Candidate Name';
        System.assertEquals(null, controller.sortDataGroup());
        System.assertEquals(null, controller.sortDataGroup());
        controller.sortByColumnGroup = 'Political Party';
        System.assertEquals(null, controller.sortDataGroup());
        controller.sortByColumnGroup = 'Head Candidate';
        System.assertEquals(null, controller.sortDataGroup());
        controller.sortByColumnGroup = 'Confirm Signed by Candidate';
        System.assertEquals(null, controller.sortDataGroup());
        controller.sortByColumnGroup = 'Nothing';
        System.assertEquals(null, controller.sortDataGroup());
        
        controller.save();
        Registration.Election_Event1__c = camp1.Id;
        System.assertEquals(null, controller.updateElectionDetail());
        controller.save();
        //controller.QuickSave();
        controller.QuickSave();
        //controller.addDO();
        //controller.deleteDO();
        controller.quickSaveAndLookupOaa();
        ApexPages.CurrentPage().GetParameters().Put('deleteoncancel','1');        
        controller.Cancel();
    }*/
    static Registration__c InitialData()
    {
		List<RecordType> recordTypes = [SELECT Id, Name FROM RecordType];
		
		// Map Namae, Id of RecordType
		Map<String, String> listRecordType = new Map<String,String>();
		for (RecordType r : recordTypes) {
			listRecordType.put (r.Name, r.Id);
		}
		// Create New Campaigns
        /*
        Campaign camp = new Campaign(Name='Test Campaign', RecordTypeId=listRecordType.get('State Election Group'), 
                                     By_Election__c=true, Close_of_Nominations__c = Date.parse('30/05/2014'),
                                     EndDate = Date.parse('30/05/2014'), Term_End_Date_for_Legislative_Council__c = Date.parse('30/05/2014'),
                                     StartDate = Date.parse('30/05/2014'), Date_of_Election__c = Date.parse('30/05/2014'));
		upsert camp;
		*/
        /*
        Campaign camp1 = new Campaign(Name='Test aa', RecordTypeId='012N00000008YK2IAM', 
                                     By_Election__c=true, Date_of_Election__c = Date.parse('30/05/2014'));
		upsert camp1;
		*/
		Election_Event__c camp = new Election_Event__c(Name='Test Campaign1', 
                                                       RecordTypeId=listRecordType.get('State Election Event'),
                                     By_Election__c=true, Date_of_Election__c = Date.parse('30/05/2018'),
                                                      Term_End_Date__c = Date.parse('30/05/2018'));
		upsert camp;
        camp1 = new Election_Event__c(Name='Test Campaign1', 
                                                       RecordTypeId=listRecordType.get('State Election Event'),
                                     By_Election__c=true, Date_of_Election__c = Date.parse('30/08/2018'),
                                                      Term_End_Date__c = Date.parse('30/08/2018'));
		upsert camp1;
        
		
		// Create Account
		Account accountPerson = new Account(LastName = 'Test', FirstName='Name',RecordTypeId=listRecordType.get('Person') );
		upsert accountPerson;
		// Create Account Political Party
		Account accountParty = new Account(Name = 'Test Political Party',Party_Agent__c=accountPerson.Id, Registered_Officer__c=accountPerson.Id,
									RecordTypeId=listRecordType.get('Political Party') );
		
		upsert accountParty;
		
		// Create Reporting Period
		Reporting_Period__c reportP = new Reporting_Period__c(RecordTypeId=listRecordType.get('Reporting Period'), Name='Sample Period', Type__c='Financial Year');        
		reportP.Date_From__c = Date.parse('03/05/2014');
		reportP.Date_To__c = Date.parse('03/05/2015');
		upsert reportP;
		
        ///*
		// Create Disclosure Obligation
		List<Donation_Expenditure_Cap__c> doExList = new List<Donation_Expenditure_Cap__c>();
		List<String> StakeHolderList = new List<String>();
		StakeHolderList.add('Candidate');
		StakeHolderList.add('Group of Candidates');
		StakeHolderList.add('Elected Member');
		StakeHolderList.add('Third-Party Campaigner');
		for (String st : StakeHolderList) {
			//Donation_Expenditure_Cap__c d1 = new Donation_Expenditure_Cap__c(Reporting_Period__c=reportP.Id,Stakeholder_Type__c=st,Active__c=true);
			//Donation_Expenditure_Cap__c d2 = new Donation_Expenditure_Cap__c(Reporting_Period__c=reportP.Id,Stakeholder_Type__c=st,Active__c=true);
			Donation_Expenditure_Cap__c d3 = new Donation_Expenditure_Cap__c(Reporting_Period__c=reportP.Id,Stakeholder_Type__c=st,Active__c=true);
			Donation_Expenditure_Cap__c d4 = new Donation_Expenditure_Cap__c(Reporting_Period__c=reportP.Id,Stakeholder_Type__c=st,Active__c=true);
			Donation_Expenditure_Cap__c d5 = new Donation_Expenditure_Cap__c(Reporting_Period__c=reportP.Id,Stakeholder_Type__c=st,Active__c=true);
			Donation_Expenditure_Cap__c d6 = new Donation_Expenditure_Cap__c(Reporting_Period__c=reportP.Id,Stakeholder_Type__c=st,Active__c=true);
			//d1.RecordTypeId = listRecordType.get('Donations (Given) Cap');
			//d2.RecordTypeId = listRecordType.get('Donations (Given) Cap');
			//d3.RecordTypeId = listRecordType.get('Donations (Received) Cap');
			//d4.RecordTypeId = listRecordType.get('Donations (Received) Cap');
            d3.RecordTypeId = listRecordType.get('Donation Cap');
			d4.RecordTypeId = listRecordType.get('Donation Cap');
			d5.RecordTypeId = listRecordType.get('Expenditure Cap');
			d6.RecordTypeId = listRecordType.get('Expenditure Cap');
			//d1.Amount__c = (Integer)(Math.random()*100)*1000 + 100000;
			//d2.Amount__c = (Integer)(Math.random()*100)*1000 + 100000;
			d3.Amount__c = (Integer)(Math.random()*100)*1000 + 100000;
			d4.Amount__c = (Integer)(Math.random()*100)*1000 + 100000;
			d5.Amount__c = (Integer)(Math.random()*100)*1000 + 100000;
			d6.Amount__c = (Integer)(Math.random()*100)*1000 + 100000;
			//doExList.add(d1);
			//doExList.add(d2);
			doExList.add(d3);
			doExList.add(d4);
			doExList.add(d5);
			doExList.add(d6);
		}
		upsert doExList;
		//*/
		/*
        Table_Settings__c tablesetting = new Table_Settings__c(Name='DisclosureObligation');
        tablesetting.Column1_Name__c = 'Reporting Period';
        tablesetting.Column2_Name__c = 'Status';
        tablesetting.Column3_Name__c = 'Donation Cap';
        //tablesetting.Column3_Name__c = 'Donations (Received) Cap';
        tablesetting.Column4_Name__c = 'Expenditure Cap';
        //tablesetting.Column5_Name__c = 'Donations (Given) Cap';
        upsert tablesetting;
		Table_Settings__c tablesettingGroup = new Table_Settings__c(Name='GroupCandiate');
        tablesettingGroup.Column1_Name__c = 'Candidate Name';
        tablesettingGroup.Column2_Name__c = 'Political Party';
        tablesettingGroup.Column3_Name__c = 'Head Candidate';
        tablesettingGroup.Column4_Name__c = 'Confirm Signed by Candidate';
        upsert tablesettingGroup;
		*/
		Registration__c Registration = new Registration__c();
        //Registration.Election_Event__c = camp1.Id;
		Registration.Election_Event1__c = camp.Id;
		Registration.Stakeholder__c = accountPerson.Id;
		Registration.Official_Agent__c = accountPerson.Id;
        return Registration;
    }
    
}