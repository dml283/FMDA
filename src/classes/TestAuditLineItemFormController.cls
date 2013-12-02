@isTest
public with sharing class TestAuditLineItemFormController { 
    static Map<String,String> Entity;
    static testMethod void newTest() {
        InitialData();
        
        // Test for AuditLineItemForm
        PageReference pageRef = Page.AuditLineItemForm;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('do',Entity.get('DisclosureId'));
        AuditLineItemFormController controller = new AuditLineItemFormController();
        controller.GetMapLineItemFieldSets();
        controller.ChangeLineItemType();
        controller.btnAdd_Click();
        pageRef.getParameters().put('LineItemId',controller.LineItemWrapperList[0].Id+'');
        controller.btnSaveRow_Click();
        controller.reloadId = controller.LineItemWrapperList[0].Item.Id;
        controller.ReloadLineItem();
        controller.CollapseAll();
        controller.ExpandAll();
        pageRef.getParameters().put('LineItemId',controller.LineItemWrapperList[1].Id+'');
        controller.btnCollapseRow_Click();
        controller.btnExpandRow_Click();
        controller.buildPagingInfo();
        controller.btnEditRow_Click();
        controller.btnSaveRow_Click();
        controller.btnEditRow_Click();
        controller.btnCancelRow_Click();
        //controller.btnAddRow_Click();
        //pageRef.getParameters().put('LineItemId',controller.LineItemWrapperList[2].Id+'');
        //controller.btnSaveRow_Click();
        //For US5062
        pageRef.getParameters().put('LineItemId',controller.LineItemWrapperList[2].Id+'');
        pageRef.getParameters().put('IsAddFromExistALI', 'True');
        controller.btnAddRow_Click();
        pageRef.getParameters().put('LineItemId',controller.LineItemWrapperList[3].Id+'');
        controller.btnSaveRow_Click();
        //End US5062
        pageRef.getParameters().put('LineItemId',controller.LineItemWrapperList[2].Id+'');
        controller.btnDelRow_Click();
        //controller.btnQuickSave_Click();
        //controller.btnSaveClose_Click();
        
        // Test For Non-Compliance Controller
        pageRef = Page.NonComplianceForm;
        pageRef.getParameters().put('whatId',controller.LineItemWrapperList[0].Item.Id);
        Test.setCurrentPage(pageRef);
        NonComplianceFormController ComplianceController = new NonComplianceFormController();
        ComplianceController.GetAllTaskFieldSet();
        ComplianceController.btnAddRow_Click();
        ComplianceController.btnAddRow_Click();
        ComplianceController.ItemWrapperList[0].item.Non_Compliance_Id__c = Entity.get('NCI');
        ComplianceController.ItemWrapperList[1].item.Non_Compliance_Id__c = Entity.get('NCI');
        pageRef.getParameters().put('editId',ComplianceController.ItemWrapperList[0].Id + '');
        ComplianceController.btnSaveRow_Click();
        pageRef.getParameters().put('editId',ComplianceController.ItemWrapperList[1].Id + '');
        ComplianceController.btnSaveRow_Click();
        ComplianceController.btnEditRow_Click();
        ComplianceController.btnCancelRow_Click();
        ComplianceController.btnDelRow_Click();
        ComplianceController.btnAddRow_Click();
        pageRef.getParameters().put('editId',ComplianceController.ItemWrapperList[0].Id + '');
        ComplianceController.btnSaveRow_Click();
        ComplianceController.btnCancelRow_Click();
        ComplianceController.Sort();
        
        // For Non Compliance Search Controller
        pageRef = Page.NonComplianceSearch;
        pageRef.getParameters().put('keyword','');
        pageRef.getParameters().put('recordTypeName','Disclosure Non-Compliance');
        pageRef.getParameters().put('itemIdParam','10');
        Test.setCurrentPage(pageRef);
        NonComplianceSearchController SearchController = new NonComplianceSearchController();
        SearchController.GetAllComFieldSet();
        pageRef.getParameters().put('itemId',SearchController.Items[0].Id + '');
        SearchController.Sort();
        SearchController.PickItem();
    }
    
    static void InitialData()
    {
        Entity = new Map<String,String>();
        
        Map<String, String> listRecordType = new Map<String,String>();
        for (RecordType r : [SELECT Id, Name FROM RecordType]) {
            listRecordType.put (r.Name, r.Id);
        }
        
        Disclosure_Claim_for_Payment__c dcp = new Disclosure_Claim_for_Payment__c(isTemplate__c=true,RecordTypeId=listRecordType.get('Disclosure (Major Political Donor)'));
        upsert dcp;
        Entity.put('DisclosureId',dcp.Id);
        
        Line_Item_Category__c lic1 = new Line_Item_Category__c(Add_Row__c=true,Reference_Number__c='1009',Line_Item_Category__c='ab',Reconcile_Type__c = 'Donations Received');
        upsert lic1;
        
        Line_Item_Category__c lic2 = new Line_Item_Category__c(Add_Row__c=true,Reference_Number__c='1010',Line_Item_Category__c='cd',Reconcile_Type__c = 'Donations Made');
        upsert lic2;
        
        Line_Item_Type__c lit1 = new Line_Item_Type__c(Line_Item_Category__c=lic1.Id,Disclosure_Claim_for_Payment__c=dcp.Id);
        upsert lit1;
        Entity.put('lit1',lit1.Id);
        
        Line_Item_Type__c lit2 = new Line_Item_Type__c(Line_Item_Category__c=lic2.Id,Disclosure_Claim_for_Payment__c=dcp.Id);     
        upsert lit2;
        Entity.put('lit2',lit2.Id);
        
        Line_Item__c li = new Line_Item__c(Line_Item_Type__c = lit1.Id);
        upsert li;
        Entity.put('li',li.Id);
        
        Non_Compliance__c nci = new Non_Compliance__c(Name='test',Legislative_Reference__c='test',Compliance_Issue__c='test',
                                                     RecordTypeId=listRecordType.get('Disclosure Non-Compliance'));
        upsert nci;
        Entity.put('NCI',nci.Id);
        
        //Reconciled_Line_Item__c rli1 = new Reconciled_Line_Item__c(Line_Item_Donation_Received__c=li.Id);
		//upsert rli1;
    }
}