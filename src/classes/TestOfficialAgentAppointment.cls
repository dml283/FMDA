@isTest
private class TestOfficialAgentAppointment {
    static Map<string, sObject> Entities{get;set;}
    static Official_Agent_Appointment__c oaa;
    static testMethod void myUnitTest() {
        InitData();
        Test.SetCurrentPage(Page.OfficialAgentAppointment);
        ApexPages.CurrentPage().GetParameters().Put('regid', Entities.Get('Registration').Id);
        ApexPages.CurrentPage().GetParameters().Put('oapid', Entities.Get('OfficialAgentAppointment').Id);
        ApexPages.CurrentPage().GetParameters().Put('hdnIsByPassing1ActiveAgent', 'true');
        /*
        ApexPages.StandardController sc1 = new ApexPages.StandardController(oaa);
        OfficialAgentAppointmentController controller1 = new OfficialAgentAppointmentController(sc1);
        controller1.btnSave_Click();
                
        ApexPages.StandardController sc = new ApexPages.StandardController(new Official_Agent_Appointment__c());
        OfficialAgentAppointmentController controller = new OfficialAgentAppointmentController(sc);
        */
        ApexPages.StandardController sc1 = new ApexPages.StandardController(oaa);
        OfficialAgentAppointmentController controller = new OfficialAgentAppointmentController(sc1);
        ApexPages.CurrentPage().GetParameters().Put('retURL', '');
        controller.btnSave_Click();
        
        controller.updateOfficialAgent();
        controller.lkpOfficialAgent_Change();
        controller.OfficialAgent_Validated();
        ApexPages.CurrentPage().GetParameters().Put('ListEntitySortColumn', 'Name');
        controller.btnSortOap_Click();
        controller.btnCreateOap_Click();
        controller.btnInlineEditOap_Click();
        controller.btnSaveInlineEditOap_Click();
        controller.btnCancelInlineEditOap_Click();
        controller.btnInlineEditOap_Click();
        controller.btnEditOap_Click();
        controller.btnDelOap_Click();
        controller.btnSave_Click();
        controller.btnQuickSave_Click();
        
        
    }
    
    static Registration__c InitData()
    {
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
        
        // Create Reporting Period
        Reporting_Period__c reportP = new Reporting_Period__c(Name='Sample Period', Type__c='Financial Year');
        reportP.Date_From__c = Date.parse('30/05/2014');
        reportP.Date_To__c = Date.parse('30/05/2015');
        upsert reportP;
        
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
    
        Table_Settings__c tablesetting = new Table_Settings__c(Name='DisclosureObligation');
        tablesetting.Column1_Name__c = 'Reporting Period';
        tablesetting.Column2_Name__c = 'Status';
        tablesetting.Column3_Name__c = 'Donations (Received) Cap';
        tablesetting.Column4_Name__c = 'Expenditure Cap';
        tablesetting.Column5_Name__c = 'Donations (Given) Cap';
        upsert tablesetting;
        
        Table_Settings__c tablesettingGroup = new Table_Settings__c(Name='GroupCandiate');
        tablesettingGroup.Column1_Name__c = 'Candidate Name';
        tablesettingGroup.Column2_Name__c = 'Political Party';
        tablesettingGroup.Column3_Name__c = 'Head Candidate';
        tablesettingGroup.Column4_Name__c = 'Confirm Signed by Candidate';
        upsert tablesettingGroup;
        
        Registration__c Registration = new Registration__c();
        Registration.Election_Event1__c = camp.Id;
        Registration.Stakeholder__c = accountPerson.Id;
        Registration.Official_Agent__c = accountPerson.Id;
        upsert Registration;
        Entities.Put('Registration', Registration);
        
        oaa = new Official_Agent_Appointment__c(Registration__c = Registration.Id, Official_Agent__c = accountPerson.Id);
        upsert oaa;
        Entities.Put('OfficialAgentAppointment', oaa);
        
        return Registration;
    }
}