@isTest (SeeAllData = true)
public with sharing class TestLineItemFormController{
	static String recordTypeId;
    static Line_Item_Type__c lit1;
    static Line_Item_Type__c lit2;
    static Line_Item_Type__c lit3;
    static Line_Item_Type__c lit4;
    static Line_Item_Type__c lit5;
    static Line_Item_Type__c lit6;
	static testMethod void TestLineItemForm() {
		InitialData();
    	//Disclosure_Claim_for_Payment__c disclosureClaim = new Disclosure_Claim_for_Payment__c();
		
    	PageReference pageRef = Page.LineItemForm;
        Test.setCurrentPage(pageRef);
        //pageRef.getParameters().put('RecordType',recordTypeId);
        ApexPages.StandardController stdController = new ApexPages.StandardController(lit3);
    	LineItemFormController controller = new LineItemFormController(stdController);     
        
        pageRef.getParameters().put('lineitemid','0');                               
        controller.btnEdit_Click(); 
        controller.btnCancel_Click();         
        controller.btnEdit_Click(); 
        controller.btnAddRow_Click();
        controller.btnSaveRow_Click();
        pageRef.getParameters().put('lineitemid','1');
		controller.btnEditRow_Click();         
        controller.btnSaveRow_Click();
        controller.btnDelRow_Click();
        //controller.btnSave_Click();
        controller.btnSaveClose_Click();
        pageRef.getParameters().put('lineitemid','2');
		controller.btnEditRow_Click();
        controller.btnQuickSave_Click(); 
       
    }
    static testMethod void TestLineItemForm1() {
		InitialData();
    	//Disclosure_Claim_for_Payment__c disclosureClaim = new Disclosure_Claim_for_Payment__c();
		
    	PageReference pageRef = Page.LineItemForm;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController stdController1 = new ApexPages.StandardController(lit4);
    	LineItemFormController controller1 = new LineItemFormController(stdController1);       
        
        pageRef.getParameters().put('lineitemid','0');
        controller1.btnEditRow_Click(); 
        controller1.btnCancelRow_Click();
        controller1.btnEdit_Click();  
        controller1.btnQuickSaveJS_Click();
        controller1.btnSave_Click();                                          
    }
    static testMethod void TestLineItemForm2() {
		InitialData();
    	//Disclosure_Claim_for_Payment__c disclosureClaim = new Disclosure_Claim_for_Payment__c();
		
    	PageReference pageRef = Page.LineItemForm;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController stdController2 = new ApexPages.StandardController(lit5);
    	LineItemFormController controller2 = new LineItemFormController(stdController2);      
        
        pageRef.getParameters().put('lineitemid','0');
        
        controller2.btnEditRow_Click(); 
        controller2.btnCancelRow_Click();
        controller2.btnEdit_Click(); 
        controller2.LineItemType.Nil_Disclosure_Claim_for_Payment__c = false;
        controller2.QueryLineItemTypes();
        controller2.btnSave_Click();
        
        controller2.LineItemType.Nil_Disclosure_Claim_for_Payment__c =true;
        controller2.Nil_Checked();
        controller2.QueryLineItemTypes();                             
    }
    static void InitialData()
    {
		
		List<RecordType> recordTypes = [SELECT Id, Name FROM RecordType Where Name='Disclosure (Major Political Donor)' Limit 1];		
		recordTypeId=recordTypes[0].Id;
        
        List<RecordType> recordTypes1 = [SELECT Id, Name FROM RecordType];		
		// Map Namae, Id of RecordType
		Map<String, String> listRecordType = new Map<String,String>();
		for (RecordType r : recordTypes1) {
			listRecordType.put (r.Name, r.Id);
		}
        Account acc = new Account(FirstName='Test',LastName='Acc',RecordTypeId=listRecordType.get('Person'));
		upsert acc;
        Account acc1 = new Account(FirstName='Test1',LastName='Acc1',RecordTypeId=listRecordType.get('Person'));
		upsert acc1;
        // Create Reporting Period
		Reporting_Period__c reportP = new Reporting_Period__c(RecordTypeId=listRecordType.get('Reporting Period'), Name='Sample Period', Type__c='Financial Year');
        //reportP.Lodgement_Due_Date__c = Date.parse('03/05/2015');
		reportP.Date_From__c = Date.parse('03/05/2014');
		reportP.Date_To__c = Date.parse('03/05/2015');
		upsert reportP;
        
        Disclosure_Obligation__c doc = new Disclosure_Obligation__c();
        doc.Reporting_Period__c = reportP.Id;
        doc.Stakeholder__c = acc1.Id;
        upsert doc;
		Disclosure_Claim_for_Payment__c dcp = new Disclosure_Claim_for_Payment__c(Disclosure_Obligation__c = doc.Id, isTemplate__c=false,RecordTypeId=recordTypeId);
        upsert dcp;       
		
        //Disclosure_Claim_for_Payment__c dcp = new Disclosure_Claim_for_Payment__c(isTemplate__c=false,RecordTypeId=recordTypeId);
		//upsert dcp;
        //LIC
        List<Line_Item_Category__c> listLIC = new List<Line_Item_Category__c>();
        List<Line_Item_Category__c> listlic1 = [SELECT Id, Add_Row__c, Reference_Number__c FROM Line_Item_Category__c WHERE Reference_Number__c = '1009'];
        Line_Item_Category__c lic1;
        if(listlic1.size() > 0){
		 	lic1 = listlic1[0];
			listLIC.add(lic1);
        }else{
        	lic1 = new Line_Item_Category__c(Add_Row__c=true,Reference_Number__c='1009');
			listLIC.add(lic1);		
        }
        List<Line_Item_Category__c> listlic2 = [SELECT Id, Add_Row__c, Reference_Number__c FROM Line_Item_Category__c WHERE Reference_Number__c = '1010'];
        Line_Item_Category__c lic2;
        if(listlic2.size() > 0){
		 	lic2 = listlic2[0];
			listLIC.add(lic2);
        }else{
        	lic2 = new Line_Item_Category__c(Add_Row__c=true,Reference_Number__c='1010');
			listLIC.add(lic2);		
        }
        
        List<Line_Item_Category__c> listlic3 = [SELECT Id, Add_Row__c, Reference_Number__c FROM Line_Item_Category__c WHERE Reference_Number__c = '1005'];
        Line_Item_Category__c lic3;
        if(listlic3.size() > 0){
		 	lic3 = listlic3[0];
		 	lic3.Aggregated_Category__c = 'Reportable Donations Received';
			listLIC.add(lic3);
        }else{
        	lic3 = new Line_Item_Category__c(Add_Row__c=true,Reference_Number__c='1005', Aggregated_Category__c = 'Reportable Donations Received');
			listLIC.add(lic3);		
        }
        
		List<Line_Item_Category__c> listlic4 = [SELECT Id, Add_Row__c, Reference_Number__c FROM Line_Item_Category__c WHERE Reference_Number__c = '1000'];
        Line_Item_Category__c lic4;
        if(listlic4.size() > 0){
		 	lic4 = listlic4[0];
			listLIC.add(lic4);
        }else{
        	lic4 = new Line_Item_Category__c(Add_Row__c=true,Reference_Number__c='1000');
			listLIC.add(lic2);		
        }
         
     	List<Line_Item_Category__c> listlic5 = [SELECT Id, Add_Row__c, Reference_Number__c FROM Line_Item_Category__c WHERE Reference_Number__c = '1007'];
        Line_Item_Category__c lic5;
        if(listlic5.size() > 0){
		 	lic5 = listlic5[0];
		 	lic5.Aggregated_Category__c = 'Reportable Donations Received';
			listLIC.add(lic5);
        }else{
        	lic5 = new Line_Item_Category__c(Add_Row__c=true,Reference_Number__c='1007', Aggregated_Category__c = 'Reportable Donations Received');
			listLIC.add(lic5);		
        }     
        
        upsert listLIC;
        
        //LIT
        List<Line_Item_Type__c> listLIT = new List<Line_Item_Type__c>();
		lit1 = new Line_Item_Type__c(Line_Item_Category__c=lic1.Id,Disclosure_Claim_for_Payment__c=dcp.Id);
		listLIT.add(lit1);
		lit2 = new Line_Item_Type__c(Line_Item_Category__c=lic2.Id,Disclosure_Claim_for_Payment__c=dcp.Id);
		listLIT.add(lit2);
        lit3 = new Line_Item_Type__c(Line_Item_Category__c=lic3.Id,Disclosure_Claim_for_Payment__c=dcp.Id);
		listLIT.add(lit3);
        lit4 = new Line_Item_Type__c(Line_Item_Category__c=lic4.Id,Disclosure_Claim_for_Payment__c=dcp.Id);
		listLIT.add(lit4);
        lit5 = new Line_Item_Type__c(Line_Item_Category__c=lic5.Id,Disclosure_Claim_for_Payment__c=dcp.Id, Nil_Disclosure_Claim_for_Payment__c = true);
		listLIT.add(lit5);
        lit6 = new Line_Item_Type__c(Line_Item_Category__c=lic3.Id,Disclosure_Claim_for_Payment__c=dcp.Id, Nil_Disclosure_Claim_for_Payment__c = false);
		listLIT.add(lit6);
        upsert listLIT;
        
        //LI
        List<Line_Item__c> upsertList = new List<Line_Item__c>();        
        Line_Item__c li = new Line_Item__c(Line_Item_Type__c = lit1.Id);
        upsertList.add(li);
        Line_Item__c li1 = new Line_Item__c(Line_Item_Type__c = lit3.Id, Stakeholder__c=acc.Id);
        upsertList.add(li1);
        Line_Item__c li2 = new Line_Item__c(Line_Item_Type__c = lit3.Id, Stakeholder__c=acc.Id);
        upsertList.add(li2);
        Line_Item__c li3 = new Line_Item__c(Line_Item_Type__c = lit3.Id, Stakeholder__c=acc.Id);
        upsertList.add(li3);
        Line_Item__c li7 = new Line_Item__c(Line_Item_Type__c = lit4.Id, Stakeholder__c=acc.Id);
        upsertList.add(li7);
        Line_Item__c li8 = new Line_Item__c(Line_Item_Type__c = lit6.Id, Stakeholder__c=acc.Id);
        upsertList.add(li8);
        Line_Item__c li4 = new Line_Item__c(Line_Item_Type__c = lit4.Id);
        upsertList.add(li4);
        Line_Item__c li5 = new Line_Item__c(Line_Item_Type__c = lit4.Id);
        upsertList.add(li5);
        Line_Item__c li6 = new Line_Item__c(Line_Item_Type__c = lit4.Id);
        upsertList.add(li6);
        upsert upsertList;
    }
}