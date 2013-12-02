@isTest (SeeAllData = true)
public with sharing class TestTaskNonComplianceTrigger{
    static Disclosure_Claim_for_Payment__c dcp;
    static Non_Compliance__c nci;
    static Line_Item__c li;
    static Account accountPerson;
    static testMethod void newTest() {
        InitialData();
        
        Task task = new Task(OwnerId= UserInfo.GetUserId(),Subject=nci.Non_Compliance_Number__c,Priority='Normal',
                             Status='Potential Non-Compliance Flagged');
        insert task;
    }
    static void InitialData()
    {
        Map<String, String> listRecordType = new Map<String,String>();
        for (RecordType r : [SELECT Id, Name FROM RecordType]) {
            listRecordType.put (r.Name, r.Id);
        }
        accountPerson = new Account(LastName = 'Test', FirstName='Name',RecordTypeId=listRecordType.get('Person') );
        upsert accountPerson;
        
        dcp = new Disclosure_Claim_for_Payment__c(isTemplate__c=false,RecordTypeId=listRecordType.get('Disclosure (Major Political Donor)'), Stakeholder__c = accountPerson.Id);
        upsert dcp;
        Line_Item_Category__c lic1 = new Line_Item_Category__c(Add_Row__c=true/*,Reference_Number__c='1009'*/);
        upsert lic1;
        Line_Item_Category__c lic2 = new Line_Item_Category__c(Add_Row__c=true/*,Reference_Number__c='1010'*/);
        upsert lic2;
        Line_Item_Type__c lit1 = new Line_Item_Type__c(Line_Item_Category__c=lic1.Id,Disclosure_Claim_for_Payment__c=dcp.Id);
        upsert lit1;
        Line_Item_Type__c lit2 = new Line_Item_Type__c(Line_Item_Category__c=lic2.Id,Disclosure_Claim_for_Payment__c=dcp.Id);
        upsert lit2;
        li = new Line_Item__c(Line_Item_Type__c = lit1.Id);
        upsert li;
        string num1 = string.valueOf(Math.round(Math.random()*10)).subString(0,1);
        string num2 = string.valueOf(Math.round(Math.random()*10)).subString(0,1);
        string num3 = string.valueOf(Math.round(Math.random()*10)).subString(0,1);
        string num4 = string.valueOf(Math.round(Math.random()*10)).subString(0,1);
        string strNum = '' + num1 + num2 + num3 + num4;
        nci = new Non_Compliance__c(Non_Compliance_Number__c = strNum,Name='test',Legislative_Reference__c='test',
                                    Compliance_Issue__c='test', Line_Item_Category__c = lic1.Id,
                                    RecordTypeId=listRecordType.get('Line Item Non-Compliance'));
        upsert nci;
    }
}