@isTest
public with sharing class TestViewCreateEditLineItemsController {	
	static String recordTypeId;
	static testMethod void newTest() {
		InitialData();
    	Disclosure_Claim_for_Payment__c disclosureClaim = new Disclosure_Claim_for_Payment__c();
		
    	PageReference pageRef = Page.ViewCreateEditLineItems;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('RecordType',recordTypeId);
        ApexPages.StandardController stdController = new ApexPages.StandardController(disclosureClaim);
    	ViewCreateEditLineItemsController controller = new ViewCreateEditLineItemsController(stdController);
        controller.GetMapLineItemFieldSets();
        controller.btnSave_Click();
        
        disclosureClaim = controller.Entity;
        ApexPages.StandardController stdController2 = new ApexPages.StandardController(disclosureClaim);
    	ViewCreateEditLineItemsController controller2 = new ViewCreateEditLineItemsController(stdController2);
        String lineitemtypeno = controller2.ListTabs.get(0).Line_Item_Category__r.Reference_Number__c;
        String lineitemId = String.valueOf(controller2.MapTabLineItems.get(lineitemtypeno).get(0).Id);
        String lineitemtypeid = controller2.ListTabs.get(0).Id;
        pageRef.getParameters().put('lineitemid',lineitemId);
        pageRef.getParameters().put('lineitemtypeno',lineitemtypeno);
        pageRef.getParameters().put('lineitemtypeid',lineitemtypeid);
        controller2.btnDelRow_Click();
        controller2.btnAddRow_Click();
        lineitemId = String.valueOf(controller2.MapTabLineItems.get(lineitemtypeno).get(0).Id);
        pageRef.getParameters().put('lineitemid',lineitemId);
        controller2.btnEditRow_Click();
        controller2.btnSaveRow_Click();
        controller2.btnEditRow_Click();
        controller2.btnCancelRow_Click();
        controller2.btnEdit_Click();
        controller2.btnCancel_Click();
        controller2.btnEdit_Click();
        pageRef.getParameters().put('inline','1');
        controller2.btnCancel_Click();
        controller2.btnSave_Click();
        controller2.btnSaveClose_Click();
    }
    
	static testMethod void testViewLineItem() {
        InitialData();
        Line_Item__c entity = [SELECT Id FROM Line_Item__c LIMIT 1];
        Test.SetCurrentPage(Page.ViewLineItem);
        ApexPages.StandardController sc = new ApexPages.StandardController(entity);
    	ViewLineItemController con = new ViewLineItemController(sc);
        
    }
    static void InitialData()
    {
		
		List<RecordType> recordTypes = [SELECT Id, Name FROM RecordType Where Name='Disclosure (Major Political Donor)' Limit 1];
		
		recordTypeId=recordTypes[0].Id;
		Disclosure_Claim_for_Payment__c dcp = new Disclosure_Claim_for_Payment__c(Name='Template', isTemplate__c=true,RecordTypeId=recordTypeId);
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
    }
}