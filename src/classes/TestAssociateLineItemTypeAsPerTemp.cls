@isTest
public class TestAssociateLineItemTypeAsPerTemp{
	static String recordTypeId;
	static testMethod void newTestAssociateLineItemTypeAsPerTemp() {
		List<RecordType> recordTypes = [SELECT Id, Name FROM RecordType Where Name='Disclosure (Major Political Donor)' Limit 1];
		
		recordTypeId=recordTypes[0].Id;
        
        Disclosure_Obligation__c doc = new Disclosure_Obligation__c(Stakeholder__c='001N0000005Wh6VIAS');
        upsert doc;
        Disclosure_Claim_for_Payment__c tmpdcp = new Disclosure_Claim_for_Payment__c(/*Name='Tempt1',*/ isTemplate__c=true,RecordTypeId=recordTypeId, Disclosure_Obligation__c=doc.Id);
		upsert tmpdcp;
        ///*
		Line_Item_Category__c lic1 = new Line_Item_Category__c(Add_Row__c=true,Reference_Number__c='1009');
		upsert lic1;
		Line_Item_Category__c lic2 = new Line_Item_Category__c(Add_Row__c=true,Reference_Number__c='1010');
		upsert lic2;
		//*/
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
        
        
		Disclosure_Claim_for_Payment__c dcp = new Disclosure_Claim_for_Payment__c(/*Name='TestTrigger',*/ isTemplate__c=false,RecordTypeId=recordTypeId);
		upsert dcp;
    }
}