@IsTest(SeeAllData=true)
public with sharing class TestReviewExpenditureCapController{
    static String doId;
    static Map<string, sObject> Entities;
	static testMethod void TestReviewExpenditureCap() {
        InitialData();
		
    	PageReference pageRef = Page.ReviewExpenditureCap;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('do',doId);
        ReviewExpenditureCapController controller = new ReviewExpenditureCapController();
        controller.GetMapLineItemFieldSets();
        String a = controller.ExpenditureCap;
        a = controller.Amount;
        a = controller.TotalExpenditure;
        a = controller.Difference;
        a = controller.TotalECE;
        a = controller.DifferenceECE;
        controller.reloadLitId = controller.lineItemTypeWrap.get(0).lit.Id;
        controller.ReloadLitTable();
        pageRef.getParameters().put('sortByColumn','CreatedDate');
        pageRef.getParameters().put('sortDirection','ASC');
        controller.lineItemTypeWrap.get(0).Sort();
        controller.Back();
    }
    static testMethod void TestReviewDonationCap() {
        InitialData();
		
    	PageReference pageRef = Page.ReviewDonationCap;
        Test.setCurrentPage(pageRef);
        ReviewDonationCapController controller = new ReviewDonationCapController(new ApexPages.StandardController(Entities.Get('Disclosure_Claim_for_Payment__c')));
        controller.lnkSearch_OnClick();
        controller.GetMapLineItemFieldSets();
        controller.ReloadLitTable();
        
        pageRef.getParameters().put('sortByColumn','CreatedDate');
        pageRef.getParameters().put('sortDirection','ASC');
        //controller.Results[0].LineItemTypes[0].Sort();
        /*
        String a = controller.ExpenditureCap;
        a = controller.Amount;
        a = controller.TotalExpenditure;
        a = controller.Difference;
        controller.reloadLitId = controller.lineItemTypeWrap.get(0).lit.Id;
        controller.ReloadLitTable();
        pageRef.getParameters().put('sortByColumn','CreatedDate');
        pageRef.getParameters().put('sortDirection','ASC');
        controller.lineItemTypeWrap.get(0).Sort();
        controller.Back();
*/
    }
    static void InitialData()
    {
        Entities = new Map<string, sObject>();
		List<RecordType> recordTypes = [SELECT Id, Name FROM RecordType Where Name='Disclosure (Group of Local Government Candidates)' Limit 1];		
		String recordTypeId=recordTypes[0].Id;
        
        List<RecordType> recordTypes1 = [SELECT Id, Name FROM RecordType];		
		// Map Namae, Id of RecordType
		Map<String, String> listRecordType = new Map<String,String>();
		for (RecordType r : recordTypes1) {
			listRecordType.put (r.Name, r.Id);
		}
        
		Account acc = new Account(FirstName='Test',LastName='Acc',RecordTypeId=listRecordType.get('Person'));
		upsert acc;
        Disclosure_Claim_for_Payment__c dcp = new Disclosure_Claim_for_Payment__c(isTemplate__c=false,RecordTypeId=recordTypeId);
		upsert dcp; Entities.Put('Disclosure_Claim_for_Payment__c', dcp);
        doId = dcp.Id;
		Line_Item_Category__c lic1 = new Line_Item_Category__c(Add_Row__c=true,Reference_Number__c='1999',Aggregated_Category__c ='Electoral Expenditure');
		upsert lic1;
		Line_Item_Category__c lic2 = new Line_Item_Category__c(Add_Row__c=true,Reference_Number__c='2999',Aggregated_Category__c ='Reportable Donations Received');
		upsert lic2;
        
		Line_Item_Type__c lit1 = new Line_Item_Type__c(Line_Item_Category__c=lic1.Id,Disclosure_Claim_for_Payment__c=dcp.Id);
		upsert lit1;
		Line_Item_Type__c lit2 = new Line_Item_Type__c(Line_Item_Category__c=lic2.Id,Disclosure_Claim_for_Payment__c=dcp.Id);
		upsert lit2;
        
        List<Line_Item__c> upsertList = new List<Line_Item__c>();
        
        Line_Item__c li = new Line_Item__c(Line_Item_Type__c = lit1.Id, Active__c = true, Line_Item_Status__c='Audited',
                                          RecordTypeId=listRecordType.get('Audit Line Item'));
        upsertList.add(li);
        Line_Item__c li1 = new Line_Item__c(Line_Item_Type__c = lit2.Id, Stakeholder__c=acc.Id,Active__c = true, 
                                            Line_Item_Status__c='Audited', RecordTypeId=listRecordType.get('Audit Line Item'));
        upsertList.add(li1);
        
        upsert upsertList;
    }
}