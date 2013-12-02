@isTest (SeeAllData = true)
public with sharing class TestLineItemNoteController{
    static String lineItemId;
	static testMethod void TestLineItemForm() {
        InitialData();
		
    	PageReference pageRef = Page.LineItemNote;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('lineItemId',lineItemId);
    	LineItemNoteController controller = new LineItemNoteController();
        
        controller.btnAddRow_Click();
        controller.NoteWrapperList[0].note.Title = 'abc';
        pageRef.getParameters().put('saveId',String.valueOf(controller.NoteWrapperList[0].Id));
        controller.btnSaveRow_Click();
        controller.btnAddRow_Click();
        controller.NoteWrapperList[1].note.Title = 'def';
        pageRef.getParameters().put('saveId',String.valueOf(controller.NoteWrapperList[1].Id));
        controller.btnSaveRow_Click();
        pageRef.getParameters().put('editId',String.valueOf(controller.NoteWrapperList[0].Id));
        controller.btnEditRow_Click();
        pageRef.getParameters().put('cancelId',String.valueOf(controller.NoteWrapperList[0].Id));
        controller.btnCancelRow_Click();
        controller.btnAddRow_Click();
        pageRef.getParameters().put('cancelId',String.valueOf(controller.NoteWrapperList[1].Id));
        controller.btnCancelRow_Click();
        pageRef.getParameters().put('delId',String.valueOf(controller.NoteWrapperList[1].Id));
        controller.btnDelRow_Click();
        pageRef.getParameters().put('orderDirection','ASC');
        pageRef.getParameters().put('orderBy','Title');
        controller.Sort();
        pageRef.getParameters().put('orderDirection','DESC');
        controller.Sort();
    }
    static void InitialData()
    {
        List<RecordType> recordTypes = [SELECT Id, Name FROM RecordType Where Name='Disclosure (Major Political Donor)' Limit 1];
		
		String recordTypeId=recordTypes[0].Id;
		Disclosure_Claim_for_Payment__c dcp = new Disclosure_Claim_for_Payment__c(isTemplate__c=false,RecordTypeId=recordTypeId);
		upsert dcp;
		Line_Item_Category__c lic = new Line_Item_Category__c(Add_Row__c=true/*,Reference_Number__c='1009'*/);
		upsert lic;
		Line_Item_Type__c lit = new Line_Item_Type__c(Line_Item_Category__c=lic.Id,Disclosure_Claim_for_Payment__c=dcp.Id);
		upsert lit;
        Line_Item__c li = new Line_Item__c(Line_Item_Type__c = lit.Id);
        upsert li;
        lineItemId = li.Id;
    }
}