@istest
public class TestReviewVouchingStatus{
    static Map<string, sObject> Entities;
	static testMethod void myTest() {
        InitialData();
    	PageReference pageRef = Page.ReviewVouchingStatus;
        Test.setCurrentPage(pageRef);
        ReviewVouchingStatusController controller = new ReviewVouchingStatusController(new ApexPages.StandardController(Entities.Get('Line_Item__c')));
        controller.GetMapLineItemFieldSets();
        controller.UnrelatedVouchList.Refresh();
        pageRef.getParameters().put('sortByColumn','Name');   
        pageRef.getParameters().put('sortDirection','DESC');   
        controller.UnrelatedVouchList.Sort();
        controller.UnrelatedVouchList.Entities[0].IsSelected = true;
        controller.btnAddVouching_OnClick();
        
        controller.RelatedVouchList.Entities[0].IsSelected = true;
        controller.btnRemoveVouching_OnClick();
        
        controller.btnNoVouching_OnClick();
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
        
        Line_Item_Category__c lic1 = new Line_Item_Category__c(Add_Row__c=true,Reference_Number__c='1011',Aggregated_Category__c ='Electoral Expenditure');
		upsert lic1; Entities.Put('Line_Item_Category__c', lic1);
		
		Line_Item_Type__c lit1 = new Line_Item_Type__c(Line_Item_Category__c=lic1.Id,Disclosure_Claim_for_Payment__c=dcp.Id);
		upsert lit1; Entities.Put('Line_Item_Type__c', lit1);
        
        Line_Item__c li = new Line_Item__c(Line_Item_Type__c = lit1.Id);
        upsert li; Entities.Put('Line_Item__c', li);
        
        fuseit_s2t__Trim__c trimserver1 = new fuseit_s2t__Trim__c(Name='NSWEC TRIM DEV',
                                                                  fuseit_s2t__Trim_IP_Address__c='http://svrapps7.seodom.local/trimdevSecure/retrievedoc.aspx?recordno=',
                                                                  fuseit_s2t__Trim_Light_IP_Address__c ='https://s2t-testing.elections.nsw.gov.au/trimws/trim.asmx',
                                                                  fuseit_s2t__Trim_Default_Location_ID__c = '98504'
                                                                 );
        upsert trimserver1;
        
        Attachment attach=new Attachment();   	
    	attach.Name='Unit Test Attachment';
    	Blob bodyBlob=Blob.valueOf('Unit Test Attachment Body');
    	attach.body=bodyBlob;
        attach.parentId=dcp.id;
        upsert attach;
        
        fuseit_s2t__Trim_Record__c trimrecord = new fuseit_s2t__Trim_Record__c(
            Name='Test',
            fuseit_s2t__Attachment_ID__c = attach.Id,
            fuseit_s2t__Attachment_Name__c = 'Test',
            fuseit_s2t__Parent_ID__c = dcp.Id,
            fuseit_s2t__Trim_ID__c = trimserver1.Id,
            Vouching_Item__c = true
        );
        upsert trimrecord; Entities.Put('fuseit_s2t__Trim_Record__c', trimrecord);
        
    }
}