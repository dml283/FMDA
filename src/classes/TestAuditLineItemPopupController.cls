@isTest
public class TestAuditLineItemPopupController{
    static Map<String, String> EntityMap = new Map<String,String>();
	static testMethod void TestLineItemForm() {
		InitialData();
        PageReference pageRef = Page.AuditLineItemPopup;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('disclosureId',EntityMap.get('do'));
        pageRef.getParameters().put('reconciletype','Donations Received');
        pageRef.getParameters().put('stakeholderId',EntityMap.get('stakeholder'));
        AuditLineItemPopupController controller = new AuditLineItemPopupController();
        controller.GetLineItemTypes();
        controller.btnSelectLineItemType_Click();
        controller.record.Line_Item_Type__c = EntityMap.get('lineItemType1');
        controller.GetLineItemFieldSets();
        controller.Save();
        controller.Cancel();
        pageRef.getParameters().put('lineitemId',EntityMap.get('lineItem1'));
        controller = new AuditLineItemPopupController();
       // pageRef.getParameters().put('lineItemTypeId',EntityMap.get('lineItemType'));
        //pageRef.getParameters().put('stakeholderId',EntityMap.get('stakeholder'));
        
    }
    static void InitialData() {
        List<RecordType> recordTypes = [SELECT Id, Name FROM RecordType];
		
		// Map Namae, Id of RecordType
		Map<String, String> listRecordType = new Map<String,String>();
		for (RecordType r : recordTypes) {
			listRecordType.put (r.Name, r.Id);
		}
		// Create Account
		Account accountPerson = new Account(LastName = 'Test', FirstName='Name',RecordTypeId=listRecordType.get('Person') );
		upsert accountPerson;
        Account accountPerson2 = new Account(LastName = 'Test2', FirstName='Name2',RecordTypeId=listRecordType.get('Person') );
		upsert accountPerson2;
		
		String recordTypeId=listRecordType.get('Disclosure (Major Political Donor)');
		Disclosure_Claim_for_Payment__c dcp = new Disclosure_Claim_for_Payment__c(isTemplate__c=false,RecordTypeId=recordTypeId);
		upsert dcp;
		Line_Item_Category__c lic1 = new Line_Item_Category__c(Add_Row__c=true,Reference_Number__c='1005',Reconcile_Type__c='Donations Received',Line_Item_Category__c='abc');
		upsert lic1;
		Line_Item_Category__c lic2 = new Line_Item_Category__c(Add_Row__c=true,Reference_Number__c='1006',Reconcile_Type__c='Donations Made',Line_Item_Category__c='ef');
		upsert lic2;
		
		Line_Item_Type__c lit1 = new Line_Item_Type__c(Line_Item_Category__c=lic1.Id,Disclosure_Claim_for_Payment__c=dcp.Id);
		upsert lit1;
		Line_Item_Type__c lit2 = new Line_Item_Type__c(Line_Item_Category__c=lic2.Id,Disclosure_Claim_for_Payment__c=dcp.Id);
		upsert lit2;
        List<Line_Item__c> liList = new List<Line_Item__c>();
        Line_Item__c li1 = new Line_Item__c(Line_Item_Type__c = lit1.Id,Stakeholder__c=accountPerson.Id);
        Line_Item__c li2 = new Line_Item__c(Line_Item_Type__c = lit2.Id,Stakeholder__c=accountPerson2.Id);
        liList.add(li1);
        liList.add(li2);
        upsert liList;
        EntityMap.put('do',dcp.Id);
        EntityMap.put('lineItem1',li1.Id);
        EntityMap.put('lineItem2',li2.Id);
		EntityMap.put('stakeholder',accountPerson.Id);
        EntityMap.put('stakeholder2',accountPerson2.Id);
        EntityMap.put('lineItemType1',lit1.Id);
        EntityMap.put('lineItemType2',lit2.Id);
        
    }
}