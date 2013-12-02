@isTest
public with sharing class TestDisclosureClaimForPmtController{
	static String recordTypeId;
    static Disclosure_Claim_for_Payment__c dcp;
    static Disclosure_Claim_for_Payment__c tmpDCP;
    static Line_Item_Category__c lic1;
    static Line_Item_Category__c lic2;
	static testMethod void newTest() {
		InitialData();
    	Disclosure_Claim_for_Payment__c disclosureClaim = new Disclosure_Claim_for_Payment__c();
		Disclosure_Claim_for_Payment__c curDCP = [select Id, name FROM Disclosure_Claim_for_Payment__c LIMIT 1];
    	PageReference pageRef = Page.CloneDisclosureClaimForPayment;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('RecordType',recordTypeId);
        //pageRef.getParameters().put('Id',curDCP.Id);
        pageRef.getParameters().put('Id',dcp.Id);
        ApexPages.StandardController stdController = new ApexPages.StandardController(disclosureClaim);
    	CloneDisclosureClaimForPaymentController controller = new CloneDisclosureClaimForPaymentController(stdController);
        CloneDisclosureClaimForPaymentController controller2 = new CloneDisclosureClaimForPaymentController();
        
        controller2.deepClone();
        
        //For Clone Template
        InitialDataForTmpt();
        CloneDisclosureClaimForPaymentController controller3 = new CloneDisclosureClaimForPaymentController(tmpDCP.Id, dcp.Id);
        controller3.CloneTempt();

    }
    
    static void InitialData()
    {
		
		List<RecordType> recordTypes = [SELECT Id, Name FROM RecordType Where Name='Disclosure (Major Political Donor)' Limit 1];
		recordTypeId=recordTypes[0].Id;
        
		dcp = new Disclosure_Claim_for_Payment__c(RecordTypeId=recordTypeId);
		upsert dcp;
		lic1 = new Line_Item_Category__c(Add_Row__c=true,Reference_Number__c='1009');
		upsert lic1;
		lic2 = new Line_Item_Category__c(Add_Row__c=true,Reference_Number__c='1010');
		upsert lic2;
		Line_Item_Type__c lit1 = new Line_Item_Type__c(Line_Item_Category__c=lic1.Id,Disclosure_Claim_for_Payment__c=dcp.Id);
		upsert lit1;
		Line_Item_Type__c lit2 = new Line_Item_Type__c(Line_Item_Category__c=lic2.Id,Disclosure_Claim_for_Payment__c=dcp.Id);
		upsert lit2;
        
        Line_Item__c li1 = new Line_Item__c(Line_Item_Type__c=lit1.Id);
		upsert li1;
		Line_Item__c li2 = new Line_Item__c(Line_Item_Type__c=lit2.Id);
		upsert li2;
        /*
        Account acc = [SELECT Id, Name FROM Account WHERE Name = 'Jordan Hobbs' LIMIT 1];
        Registration__c reg = [SELECT Id, Name FROM Registration__c WHERE Name = 'Reg1' LIMIT 1];
        Line_Item__c li1 = new Line_Item__c(Line_Item_Type__c=lit1.Id, Stakeholder__c=acc.Id, Stakeholder_Registration__c=reg.Id);
		upsert li1;
		Line_Item__c li2 = new Line_Item__c(Line_Item_Type__c=lit2.Id, Stakeholder__c=acc.Id, Stakeholder_Registration__c=reg.Id);
		upsert li2;
        */
        Reconciled_Line_Item__c rli1 = new Reconciled_Line_Item__c(Line_Item_Donation_Received__c=li1.Id);
		upsert rli1;
		Reconciled_Line_Item__c rli2 = new Reconciled_Line_Item__c(Line_Item_Donation_Received__c=li2.Id, Line_Item_Donation_Made__c=li2.Id);
		upsert rli2;
        Reconciled_Line_Item__c rli3 = new Reconciled_Line_Item__c(Line_Item_Donation_Made__c=li1.Id);
		upsert rli3;
/*
		//Need Vouching__c
        Vouched_Line_Item__c vli1 = new Vouched_Line_Item__c(Line_Item__c=li1.Id);
		upsert vli1;
		Vouched_Line_Item__c vli2 = new Vouched_Line_Item__c(Line_Item__c=li2.Id);
		upsert vli2;
*/
    }
    
    static void InitialDataForTmpt()
    {
		List<RecordType> recordTypes = [SELECT Id, Name FROM RecordType Where Name='Disclosure (Major Political Donor)' Limit 1];
		
		recordTypeId=recordTypes[0].Id;
		tmpDCP = new Disclosure_Claim_for_Payment__c(isTemplate__c=true,RecordTypeId=recordTypeId);
		upsert tmpDCP;
		/*
		Line_Item_Category__c lic1 = new Line_Item_Category__c(Add_Row__c=true,Reference_Number__c='1009');
		upsert lic1;
		Line_Item_Category__c lic2 = new Line_Item_Category__c(Add_Row__c=true,Reference_Number__c='1010');
		upsert lic2;
		*/
        Line_Item_Category__c lic3 = new Line_Item_Category__c(Add_Row__c=true,Reference_Number__c='1005');
		upsert lic3;
		///*
		Line_Item_Type__c lit1 = new Line_Item_Type__c(Line_Item_Category__c=lic1.Id,Disclosure_Claim_for_Payment__c=tmpDCP.Id);
		upsert lit1;
		Line_Item_Type__c lit2 = new Line_Item_Type__c(Line_Item_Category__c=lic2.Id,Disclosure_Claim_for_Payment__c=tmpDCP.Id);
		upsert lit2;
        Line_Item_Type__c lit3 = new Line_Item_Type__c(Line_Item_Category__c=lic3.Id,Disclosure_Claim_for_Payment__c=tmpDCP.Id);
		upsert lit3;
		///*
        Line_Item__c li = new Line_Item__c(Line_Item_Type__c = lit1.Id);
        upsert li;
		//*/
        // Account.id = '001N0000005Wh6VIAS' => Name ='Jordan Hobbs'
        Line_Item__c li1 = new Line_Item__c(Line_Item_Type__c = lit3.Id, Stakeholder__c='001N0000005Wh6VIAS');
        upsert li1;
    }
}