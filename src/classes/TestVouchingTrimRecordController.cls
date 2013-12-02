@isTest (SeeAllData = true)
public class TestVouchingTrimRecordController{
    static Map<String,sObject> Entity;
	static testMethod void newTest() {
        InitializeData();
        
        PageReference pageRef = Page.VouchingTRIMRecord;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('do',Entity.get('do').Id);
        VouchingTRIMRecordController controller = new VouchingTRIMRecordController();
        controller.GetMapTRIMRecordFieldSets();
        controller.btnAddRowClick();
        fuseit_s2t__Trim_record__c  temp = controller.TRIMWrapperList.get(0).Item;
        Attachment att1 = (Attachment)Entity.get('att1');
        temp.fuseit_s2t__Attachment_ID__c = att1.Id;
        temp.fuseit_s2t__Attachment_Name__c = att1.name;
        pageRef.getParameters().put('recordID',controller.TRIMWrapperList.get(0).Id+'');
        controller.btnSaveRowClick();
        controller.btnEditRowClick();
        controller.btnCancelRowClick();
        controller.TRIMWrapperList.get(0).isInclude = true;
        controller.btnSyncClick();
        controller.btnRefreshClick();
        
        controller.QueryTRIMRecords();
        controller.btnDelRowClick();
        controller.btnAddRowClick();
        pageRef.getParameters().put('recordID',controller.TRIMWrapperList.get(0).Id+'');
        controller.btnCancelRowClick();
        controller.btnBackClick();
        // Test Attachment Popup
        controller.btnAddRowClick();
        fuseit_s2t__Trim_record__c  temp2 = controller.TRIMWrapperList.get(0).Item;
        Attachment att2 = (Attachment)Entity.get('att2');
        temp2.fuseit_s2t__Attachment_ID__c = att2.Id;
        temp2.fuseit_s2t__Attachment_Name__c = att2.name;
        pageRef.getParameters().put('recordID',controller.TRIMWrapperList.get(0).Id+'');
        controller.btnSaveRowClick();
        PageReference pageRef2 = Page.AttachmentPopup;
        Test.setCurrentPage(pageRef2);
        pageRef2.getParameters().put('do',Entity.get('do').Id);
        pageRef2.getParameters().put('trimRecId',controller.TRIMWrapperList.get(0).Item.id);
        AttachmentPopupController contr2 = new AttachmentPopupController();
        contr2.getAttachmentItems();
        contr2.fileName = 'abc.txt';
        contr2.fileDescription = 'ab';
        contr2.fileBody = Blob.valueOf('Unit Test Attachment Body');
        contr2.upload();
        contr2.attachmentId = att2.Id;
        contr2.upload();
        AttachmentPopupController contr3 = new AttachmentPopupController();
        contr3.getAttachmentItems();
        contr3.upload();
        
        controller.btnSyncClick();
    }
    
    static void InitializeData() {
        Entity = new Map<String,sObject>();
        List<RecordType> recordTypes = [SELECT Id, Name FROM RecordType Where Name='Disclosure (Major Political Donor)' Limit 1];
		String recordTypeId=recordTypes[0].Id;
        
        /*fuseit_s2t__Trim__c trimserver1 = new fuseit_s2t__Trim__c(Name='NSWEC TRIM DEV',
                                                                  fuseit_s2t__Trim_IP_Address__c='http://svrapps7.seodom.local/trimdevSecure/retrievedoc.aspx?recordno=',
                                                                  fuseit_s2t__Trim_Light_IP_Address__c ='https://s2t-testing.elections.nsw.gov.au/trimws/trim.asmx',
                                                                  fuseit_s2t__Trim_Default_Location_ID__c = '98504',
                                                                  fuseit_s2t__Key__c = '12345678'
                                                                 );

        upsert trimserver1;
		fuseit_s2t__Trim__c trimserver2 = new fuseit_s2t__Trim__c(Name='NSWEC TRIM',
                                                                  fuseit_s2t__Trim_IP_Address__c='http://svrapps7.seodom.local/trimdevSecure/retrievedoc.aspx?recordno=',
                                                                  fuseit_s2t__Trim_Light_IP_Address__c ='https://s2t-testing.elections.nsw.gov.au/trimws/trim.asmx',
                                                                  fuseit_s2t__Trim_Default_Location_ID__c = '98504',
                                                                  fuseit_s2t__Key__c = '12345678'
                                                                 );

        upsert trimserver2;*/
		Disclosure_Claim_for_Payment__c dcp = new Disclosure_Claim_for_Payment__c(RecordTypeId=recordTypeId);
		upsert dcp;
		Entity.put('do',dcp);
        
        Line_Item_Category__c lic1 = new Line_Item_Category__c(Add_Row__c=true,Reference_Number__c='1999',Line_Item_Category__c='Test');
		upsert lic1;
        Line_Item_Type__c lit1 = new Line_Item_Type__c(Line_Item_Category__c=lic1.Id,Disclosure_Claim_for_Payment__c=dcp.Id);
		upsert lit1;
        
        Attachment attach=new Attachment();   	
    	attach.Name='Unit Test Attachment';
    	Blob bodyBlob=Blob.valueOf('Unit Test Attachment Body');
    	attach.body=bodyBlob;
        attach.parentId=dcp.id;
        upsert attach;
        
        Attachment attach2=new Attachment();   	
    	attach2.Name='Unit Test Attachment 2';
    	Blob bodyBlob2=Blob.valueOf('Unit Test Attachment Body 2');
    	attach2.body=bodyBlob;
        attach2.parentId=dcp.id;
        upsert attach2;
        Entity.put('att1',attach);
        Entity.put('att2',attach2);
        
        
    }
}