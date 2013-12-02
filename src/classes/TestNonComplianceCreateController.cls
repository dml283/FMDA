@isTest
public with sharing class TestNonComplianceCreateController{
    static Disclosure_Claim_for_Payment__c dcp;
    static Non_Compliance__c nci;
    static testMethod void newTest() {
        InitialData();
        Test.SetCurrentPage(Page.NonComplianceCreate);
        
        List<RecordType> recordTypes = [SELECT Id, Name FROM RecordType Where Name='Non-Compliance' Limit 1];       
        String recordTypeId=recordTypes[0].Id;
        ApexPages.CurrentPage().GetParameters().Put('retURL', '/' + dcp.Id);
        ApexPages.CurrentPage().GetParameters().Put('what_id', dcp.Id);
              
        //System.Debug('aaa ' + str);
        //ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.INFO, '/' + dcp.Id));
        
        ApexPages.StandardController sc = new ApexPages.StandardController(new Task());          
        NonComplianceCreateController controller = new NonComplianceCreateController(sc);
        controller.GetAllTaskFieldSet();
        controller.Entity.Non_Compliance_Id__c = nci.Id;
        controller.Save();
        
        //For Exception => not set retURL
        Test.SetCurrentPage(Page.NonComplianceCreate);
        ApexPages.CurrentPage().GetParameters().Put('RecordType', recordTypeId);
        ApexPages.StandardController sc1 = new ApexPages.StandardController(new Task());          
        NonComplianceCreateController controller1 = new NonComplianceCreateController(sc1);
        controller1.Entity.Non_Compliance_Id__c = nci.Id;
        controller1.Save();
        
        //For Test NonComplianceTrigger
        nci.Name='Updated Test';
        upsert nci;
    }
    static void InitialData()
    {
        Map<String, String> listRecordType = new Map<String,String>();
        for (RecordType r : [SELECT Id, Name FROM RecordType]) {
            listRecordType.put (r.Name, r.Id);
        }
        Account accountPerson = new Account(LastName = 'Test', FirstName='Name',RecordTypeId=listRecordType.get('Person') );
        upsert accountPerson;
        
        dcp = new Disclosure_Claim_for_Payment__c(isTemplate__c=false,RecordTypeId=listRecordType.get('Disclosure (Major Political Donor)'), Stakeholder__c = accountPerson.Id);
        upsert dcp;
        Line_Item_Category__c lic1 = new Line_Item_Category__c(Add_Row__c=true,Reference_Number__c='1009');
        upsert lic1;
        Line_Item_Category__c lic2 = new Line_Item_Category__c(Add_Row__c=true,Reference_Number__c='1010');
        upsert lic2;
        Line_Item_Type__c lit1 = new Line_Item_Type__c(Line_Item_Category__c=lic1.Id,Disclosure_Claim_for_Payment__c=dcp.Id);
        upsert lit1;
        Line_Item_Type__c lit2 = new Line_Item_Type__c(Line_Item_Category__c=lic2.Id,Disclosure_Claim_for_Payment__c=dcp.Id);
        upsert lit2;
        Line_Item__c li = new Line_Item__c(Line_Item_Type__c = lit1.Id);
        upsert li;
        nci = new Non_Compliance__c(Name='test',Legislative_Reference__c='test',Compliance_Issue__c='test',
                                    RecordTypeId=listRecordType.get('Disclosure Non-Compliance'));
        upsert nci;
    }
}