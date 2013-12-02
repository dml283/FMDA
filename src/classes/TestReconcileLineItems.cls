@isTest(SeeAllData=true)
public with sharing class TestReconcileLineItems{
    static Map<String,String> Entity;
    static testMethod void newTest() {
        Disclosure_Claim_For_Payment__c dcp = InitialData();
        PageReference pageRef = Page.ReconcileLineItems;
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardController stdController = new ApexPages.StandardController(dcp);
        
        ReconcileLineItems controller = new ReconcileLineItems(stdController);
        controller.GetMapLineItemFieldSets();
        controller.btnSearch_Click();
        
        controller.FilterKey = 'Reconciled';
        controller.btnFilter_Click();
        controller.FilterKey = 'Not Reconciled';
        controller.btnFilter_Click();
        controller.FilterKey = 'A';
        controller.btnFilter_Click();
        controller.FilterKey = 'All';
        controller.btnFilter_Click();
        
        pageRef.getParameters().put('sortDirection','ASC');
        pageRef.getParameters().put('sortBy','Name');
        pageRef.getParameters().put('blockType','Donations Received');
        if (controller.Results.size() > 0) {
            pageRef.getParameters().put('stakeholderId',controller.Results[0].Stakeholder.Id);
            pageRef.getParameters().put('blockType','Donations Received');
            pageRef.getParameters().put('lineItemId',controller.Results[0].DonationReceivedItems[0].Id + '');
            pageRef.getParameters().put('command','edit');
        }
        controller.btnReconcile_Click();
        controller.btnSort_Click();
        pageRef.getParameters().put('sortBy','Stakeholder__c');
        controller.btnSort_Click();
        pageRef.getParameters().put('sortBy','Amount_or_Value_of_Donation__c');
        controller.btnSort_Click();
        pageRef.getParameters().put('sortBy','Date_Donation_was_made__c');
        controller.btnSort_Click();
        controller.listLineItem_Command();
        pageRef.getParameters().put('command','save');
        controller.listLineItem_Command();
        controller.listLineItem_Added();
            
        pageRef.getParameters().put('lineItemId',controller.Results[0].DonationReceivedItems[0].Id+ '');
        pageRef.getParameters().put('command','add');
        controller.listLineItem_Command();
        pageRef.getParameters().put('command','delete');
        controller.listLineItem_Command();
    }
    
    static Disclosure_Claim_For_Payment__c InitialData()
    {
        Entity = new Map<String,String>();
        
        List<RecordType> recordTypes = [SELECT Id, Name FROM RecordType];
        
        // Map Namae, Id of RecordType
        Map<String, String> listRecordType = new Map<String,String>();
        for (RecordType r : recordTypes) {
            listRecordType.put (r.Name, r.Id);
        }
        
        fuseit_s2t__Trim__c trimser = new fuseit_s2t__Trim__c(Name='NSWEC TRIM',
                                                              fuseit_s2t__Trim_Light_IP_Address__c ='https://s2t-testing.elections.nsw.gov.au/trimws/trim.asmx',
                                                                fuseit_s2t__Trim_Default_Location_ID__c='98504');
        upsert trimser;
        String recordTypeId=recordTypes[0].Id;
        
        // Create Account
        Account accountPerson = new Account(LastName = 'Test', FirstName='Name',RecordTypeId=listRecordType.get('Person') );
        upsert accountPerson;
        Account accountPerson2 = new Account(LastName = 'Test2', FirstName='Name2',RecordTypeId=listRecordType.get('Person') );
        upsert accountPerson;
        upsert accountPerson2;
        Entity.put('AccountId',accountPerson.Id);
        Entity.put('AccountId2',accountPerson2.Id);
        
        // Create Reporting Period
		Reporting_Period__c reportP = new Reporting_Period__c(RecordTypeId=listRecordType.get('Reporting Period'), Name='Sample Period', Type__c='Financial Year');        
		reportP.Date_From__c = Date.parse('03/05/2014');
		reportP.Date_To__c = Date.parse('03/05/2015');
		upsert reportP;
        Disclosure_Obligation__c disOb = new Disclosure_Obligation__c(Stakeholder__c = accountPerson2.Id,Reporting_Period__c=reportP.Id); 
        upsert disOb;
        
        Disclosure_Claim_for_Payment__c dcp = new Disclosure_Claim_for_Payment__c(Stakeholder__c=accountPerson.Id,isTemplate__c=true,RecordTypeId=listRecordType.get('Disclosure (Major Political Donor)'),
                                                                                 Active__c = true,Disclosure_Obligation__c=disOb.Id);
        upsert dcp;
        //Disclosure_Claim_for_Payment__c dcp1 = new Disclosure_Claim_for_Payment__c(Stakeholder__c=accountPerson2.Id,isTemplate__c=true,RecordTypeId=listRecordType.get('Disclosure (Major Political Donor)'));
        //upsert dcp1;
        Entity.put('DisclosureId',dcp.Id);
        Line_Item_Category__c lic1 = new Line_Item_Category__c(Add_Row__c=true,Reference_Number__c='1999',Reconcile_Type__c='Donations Received',Line_Item_Category__c='Category 1');
        upsert lic1;
        Line_Item_Category__c lic2 = new Line_Item_Category__c(Add_Row__c=true,Reference_Number__c='2999',Reconcile_Type__c='Donations Made',Line_Item_Category__c='Category 2');
        upsert lic2;
        Line_Item_Type__c lit1 = new Line_Item_Type__c(Line_Item_Category__c=lic1.Id,Disclosure_Claim_for_Payment__c=dcp.Id);
        upsert lit1;
        Line_Item_Type__c lit2 = new Line_Item_Type__c(Line_Item_Category__c=lic2.Id,Disclosure_Claim_for_Payment__c=dcp.Id);
        upsert lit2;
        //Line_Item_Type__c lit3 = new Line_Item_Type__c(Line_Item_Category__c=lic2.Id,Disclosure_Claim_for_Payment__c=dcp1.Id);
        //upsert lit3;
        List<Line_Item__c> liList = new List<Line_Item__c>();
        
        Line_Item__c li = new Line_Item__c(Active__c = true, Line_Item_Type__c = lit1.Id,Stakeholder__c=accountPerson.Id,RecordTypeId=listRecordType.get('Audit Line Item'));
        Line_Item__c li1 = new Line_Item__c(Active__c = true, Line_Item_Type__c = lit1.Id,Stakeholder__c=accountPerson.Id,RecordTypeId=listRecordType.get('Audit Line Item'));
        Line_Item__c li2 = new Line_Item__c(Active__c = true, Line_Item_Type__c = lit2.Id,Stakeholder__c=accountPerson2.Id,RecordTypeId=listRecordType.get('Audit Line Item'));
        Line_Item__c li3 = new Line_Item__c(Active__c = true, Line_Item_Type__c = lit2.Id,Stakeholder__c=accountPerson2.Id,RecordTypeId=listRecordType.get('Audit Line Item'));
        Line_Item__c li4 = new Line_Item__c(Active__c = true, Line_Item_Type__c = lit2.Id,Stakeholder__c=accountPerson.Id,RecordTypeId=listRecordType.get('Audit Line Item'));
        Line_Item__c li5 = new Line_Item__c(Active__c = true, Line_Item_Type__c = lit1.Id,Stakeholder__c=accountPerson2.Id,RecordTypeId=listRecordType.get('Audit Line Item'));
        //Line_Item__c li6 = new Line_Item__c(Active__c = true, Line_Item_Type__c = lit3.Id,Stakeholder__c=accountPerson.Id,RecordTypeId=listRecordType.get('Audit Line Item'));
        liList.add(li);
        liList.add(li1);
        liList.add(li2);
        liList.add(li3);
        liList.add(li4);
        liList.add(li5);
        upsert liList;
        Non_Compliance__c nci = new Non_Compliance__c(Name='test', Legislative_Reference__c='test',Compliance_Issue__c='test');
        upsert nci;
        
        Entity.put('NCI',nci.Id);
        return dcp;
    }
}