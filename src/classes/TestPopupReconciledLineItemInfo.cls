@IsTest(SeeAllData=true)
public class TestPopupReconciledLineItemInfo{
    static Line_Item__c li1;
    static Line_Item__c li2;
	static TestMethod void Test(){
        Init();
		
    	PageReference pageRef = Page.PopupReconciledLineItemInfo;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController stdController = new ApexPages.StandardController(li1);
    	PopupReconciledLineItemInfoController controller = new PopupReconciledLineItemInfoController(stdController);
        ApexPages.StandardController stdController2 = new ApexPages.StandardController(li2);
    	PopupReconciledLineItemInfoController controller2 = new PopupReconciledLineItemInfoController(stdController2);
    }
    static void Init(){
        List<RecordType> recordTypes = [SELECT Id, Name FROM RecordType Where Name='Disclosure (Elected Member - Local Government Councillor)' Limit 1];		
		String recordTypeId=recordTypes[0].Id;		
        Disclosure_Claim_for_Payment__c dcp = new Disclosure_Claim_for_Payment__c(isTemplate__c=false,RecordTypeId=recordTypeId, Stakeholder__c='001N0000005Wh6VIAS');
		upsert dcp;
        
        String lic1Id;
        String lic2Id;
        List<Line_Item_Category__c> listTemp = [Select Id,Reference_Number__c From Line_Item_Category__c where Reference_Number__c='1005'];
        if (listTemp.size() > 0) {
            lic1Id = listTemp[0].Id;
        } else {
            Line_Item_Category__c lic1 = new Line_Item_Category__c(Add_Row__c=true, Reference_Number__c='1005', Reconcile_Type__c='Donations Received');
			upsert lic1;
            lic1Id = lic1.Id;
        }
        listTemp = [Select Id,Reference_Number__c From Line_Item_Category__c where Reference_Number__c='1009'];
        if (listTemp.size() > 0) {
            lic2Id = listTemp[0].Id;
        } else {
            Line_Item_Category__c lic2 = new Line_Item_Category__c(Add_Row__c=true, Reference_Number__c='1009', Reconcile_Type__c='Donations Made');
            upsert lic2;
            lic2Id = listTemp[0].Id;
        }
        
		Line_Item_Type__c lit1 = new Line_Item_Type__c(Line_Item_Category__c=lic1Id,Disclosure_Claim_for_Payment__c=dcp.Id);
		upsert lit1;
        Line_Item_Type__c lit2 = new Line_Item_Type__c(Line_Item_Category__c=lic2Id,Disclosure_Claim_for_Payment__c=dcp.Id);
		upsert lit2;
        li1 = new Line_Item__c(Line_Item_Type__c = lit1.Id);
        upsert li1;
        li2 = new Line_Item__c(Line_Item_Type__c = lit2.Id);
        upsert li2;
        
        Reconciled_Line_Item__c rli1 = new Reconciled_Line_Item__c(Line_Item_Donation_Received__c = li1.Id, Line_Item_Donation_Made__c = li2.Id);
		upsert rli1;
        Reconciled_Line_Item__c rli2 = new Reconciled_Line_Item__c(Line_Item_Donation_Received__c = li2.Id);
		upsert rli2;
    }
}