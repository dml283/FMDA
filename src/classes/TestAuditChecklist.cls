@isTest
public class TestAuditChecklist{
    static String doId;
    static String NonComId;
    static Map<string, sObject> Entities{get;set;}
    
    static testMethod void TestAuditChecklistRedirect(){
        Test.setCurrentPage(Page.AuditChecklistRedirect);   
        AuditChecklistRedirectController controller = new AuditChecklistRedirectController(new ApexPages.StandardController(new Audit_Checklist__c()));
        
        controller.redirect();
    }
    
    static testMethod void TestAuditChecklistTemplateSelect(){
        Test.setCurrentPage(Page.AuditChecklistTemplateSelect);   
        AuditChecklistTemplateSelectController controller = new AuditChecklistTemplateSelectController(new ApexPages.StandardController(new Audit_Checklist__c()));
        
        System.assert(controller.ListTemplate != null);
        
        controller.fieldParentId_OnChange();
    }
    
    static testMethod void TestAcSectionNcPopup(){
        Test.setCurrentPage(Page.AcSectionNcPopup);   
        AcSectionNcPopupController controller = new AcSectionNcPopupController(new ApexPages.StandardController(new Audit_Checklist_Section__c()));
        
        System.assert(controller.ListNcPager != null);
        
        controller.voidAction();
        
        ApexPages.currentPage().getParameters().put('sortby', 'Name');
        ApexPages.currentPage().getParameters().put('sortdirection', 'ASC');
        controller.btnSort_Click();
        
        ApexPages.currentPage().getParameters().put('sortby', 'Comments__c');
        ApexPages.currentPage().getParameters().put('sortdirection', 'ASC');
        controller.btnSort_Click();
    }
    
    static testMethod void TestAuditChecklistForm(){
        InitialData1();
        
        Test.setCurrentPage(Page.AuditChecklistForm);   
        AuditChecklistFormController controller = new AuditChecklistFormController(new ApexPages.StandardController(new Audit_Checklist__c()));
        controller = new AuditChecklistFormController(new ApexPages.StandardController(Entities.Get('Audit_Checklist__c')));
        
        ApexPages.currentPage().getParameters().put('sortby', 'Non_Compliance_Number__c');
        ApexPages.currentPage().getParameters().put('sortdirection', 'ASC');
        //controller.MapSectionTask.Values()[0].Values()[0].btnSort_Click();
        
        controller.GetMapLineItemFieldSets();
        controller.btnNavigate_Click();
        controller.btnQuickSave_Click();
        controller.btnSaveAndClose_Click();
        controller.btnSaveAndPDF_Click();
        controller.btnQuickSave_Click();
        controller.btnQuickSave_Click();
        controller.btnQuickSave_Click();
        controller.btnQuickSave_Click();
    }
    
    static testMethod void newTest() {
        InitialData();
        
        PageReference pageRef = Page.AuditChecklistBuilder;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('doID',doId);
        AuditChecklistBuilderController controller = new AuditChecklistBuilderController();
        controller.GetMapItemFieldSets();
        controller.GetMapSectionFieldSets();
        controller.auditChecklist.Template_Name__c = 'New Checklist';
        controller.btnSaveAuditCheckList_OnClick();
        controller.SectionWrapperList.get(0).Section.Name = 'New Section';
        pageRef.getParameters().put('sectionId',controller.SectionWrapperList.get(0).Id + '');
        controller.btnQuickSaveSection_OnClick();
        controller.btnSaveSection_OnClick();
        controller.btnSaveSection_OnClick();
        controller.btnEditSection_OnClick();
        controller.btnAddChecklistItem_OnClick();
        pageRef.getParameters().put('itemId',controller.SectionWrapperList.get(0).Items.get(0).Id + '');
        controller.btnSaveRow_onClick();
        controller.btnEditRow_OnClick();
        controller.btnCancelRow_OnClick();
        controller.btnDeleteRow_OnClick();
        controller.btnAddChecklistItem_OnClick();
        pageRef.getParameters().put('itemId',controller.SectionWrapperList.get(0).Items.get(0).Id + '');
        controller.btnSaveRow_onClick();
        //controller.reloadItem();
        pageRef.getParameters().put('auditID',controller.auditChecklist.Id);
        
        PageReference pageRef2 = Page.AuditItemCompliancePopup;
        Test.setCurrentPage(pageRef2);
        pageRef2.getParameters().put('checklistItemId',controller.SectionWrapperList.get(0).Items.get(0).Item.Id);
        pageRef2.getParameters().put('sectionId',controller.SectionWrapperList.get(0).Id + '');
        AuditItemCompliancePopupController controller2= new AuditItemCompliancePopupController();
        controller2.GetAllComFieldSet();
        controller2.btnAdd_OnClick();
        pageRef2.getParameters().put('itemId',controller2.WrapperList.get(0).Id + '');
        pageRef2.getParameters().put('NonComplianceId',NonComId);
        controller2.SaveItem();
        controller2.btnAdd_OnClick();
        pageRef2.getParameters().put('itemId',controller2.WrapperList.get(0).Id + '');
        controller2.WrapperList.get(0).isInclude = true;
        controller2.btnDelete_OnClick();
        
        Test.setCurrentPage(pageRef);
        controller = new AuditChecklistBuilderController();
        controller.btnQuickSave_OnClick();
        controller.btnEditAuditCheckList_OnClick();
        pageRef.getParameters().put('sectionId',controller.SectionWrapperList.get(0).Id + '');
        pageRef.getParameters().put('itemId',controller.SectionWrapperList.get(0).Items.get(0).Item.Id);
        controller.btnEditSection_OnClick();
        controller.reloadItem();
        controller.btnSave_OnClick();
        controller.btnDeleteSection_OnClick();
    }
    
    static void InitialData() {
        List<RecordType> recordTypes = [SELECT Id, Name FROM RecordType];       
        // Map Namae, Id of RecordType
        Map<String, String> listRecordType = new Map<String,String>();
        for (RecordType r : recordTypes) {
            listRecordType.put (r.Name, r.Id);
        }
        Disclosure_Claim_for_Payment__c dcp = new Disclosure_Claim_for_Payment__c(isTemplate__c=false,RecordTypeId=listRecordType.get('Disclosure (Group of Local Government Candidates)'));
        upsert dcp;
        doId = dcp.Id;
        
        Non_Compliance__c NonCompliance = new Non_Compliance__c(
            RecordTypeId=listRecordType.get('Disclosure Non-Compliance'),
            Name='Test', Active__c = true, Compliance_Issue__c ='Test'
        );
        upsert NonCompliance;
        NonComId = NonCompliance.Id;
    }
    
    static void InitialData1() {
        Entities = new Map<string,sObject>();
        
        List<RecordType> recordTypes = [SELECT Id, Name FROM RecordType];       
        // Map Namae, Id of RecordType
        Map<String, String> listRecordType = new Map<String,String>();
        for (RecordType r : recordTypes) {
            listRecordType.put (r.Name, r.Id);
        }
        Disclosure_Claim_for_Payment__c dcp = new Disclosure_Claim_for_Payment__c(isTemplate__c=false,RecordTypeId=listRecordType.get('Disclosure (Group of Local Government Candidates)'));
        upsert dcp; Entities.Put('Disclosure_Claim_for_Payment__c', dcp);
        
        Non_Compliance__c NonCompliance = new Non_Compliance__c(
            RecordTypeId=listRecordType.get('Disclosure Non-Compliance'),
            Name='Test', Active__c = true, Compliance_Issue__c ='Test'
        );
        upsert NonCompliance; 
        Entities.Put('Non_Compliance__c', NonCompliance);
        
        Audit_Checklist__c ac = new Audit_Checklist__c(IsTemplate__c = true, Disclosure_Claim_for_Payment__c = dcp.Id);
        upsert ac; 
        Entities.Put('Audit_Checklist__c', ac);
        
        Audit_Checklist_Section__c acs = new Audit_Checklist_Section__c(Audit_Checklist__c = ac.Id);
        upsert acs; 
        Entities.Put('Audit_Checklist_Section__c', acs);
        
        Audit_Checklist_Item__c acsi1 = new Audit_Checklist_Item__c(
            Audit_Checklist_Section__c = acs.Id
            , Response_Field__c = 'Editable'
            , Response_Field_Type__c = 'Multi-Select Picklist' 
            , Response_Field_Type_Picklist__c = 'Yes;No'
        );
        upsert acsi1; 
        Entities.Put('acsi1', acsi1);
        
        Audit_Checklist_Item__c acsi2 = new Audit_Checklist_Item__c(
            Audit_Checklist_Section__c = acs.Id
            , Response_Field__c = 'Formula'
            , Response_Field_Type_Formula__c = 'Disclosure_Claim_For_Payment__r.Name'
        );
        upsert acsi2; 
        Entities.Put('acsi2', acsi2);
        
        Audit_Checklist_Item__c acsi3 = new Audit_Checklist_Item__c(Audit_Checklist_Section__c = acs.Id);
        upsert acsi3; 
        Entities.Put('acsi3', acsi3);
        
        Audit_Checklist_Item_Non_Compliance_Join__c acinc = new Audit_Checklist_Item_Non_Compliance_Join__c(Audit_Checklist_Item__c = acsi1.Id, Non_Compliance__c = NonCompliance.Id);
        upsert acinc; 
        Entities.Put('acinc', acinc);
    }
}