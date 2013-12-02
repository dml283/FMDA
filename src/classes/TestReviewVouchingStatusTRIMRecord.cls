@isTest
public class TestReviewVouchingStatusTRIMRecord{
	static String doId;
    static Map<string, sObject> Entities;
    static fuseit_s2t__Trim_Record__c trimrecord;
    static testMethod void Test() {
        InitialData();
		
    	PageReference pageRef = Page.ReviewVouchingStatusTRIMRecord;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('trc',trimrecord.Id);        
        ReviewVouchingStatusTRIMRecordController controller = new ReviewVouchingStatusTRIMRecordController(new ApexPages.StandardController(new Vouched_Line_Item__c()));
        if(controller.LineItemTypeWrap.size()>0){
            controller.LineItemTypeWrap[0].QueryLineItemTypes();
            controller.LineItemTypeWrap[0].Sort();
        }            
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
		Line_Item_Category__c lic1 = new Line_Item_Category__c(Add_Row__c=true,Aggregated_Category__c ='Electoral Expenditure');
		upsert lic1;
		Line_Item_Category__c lic2 = new Line_Item_Category__c(Add_Row__c=true,Aggregated_Category__c ='Electoral Expenditure');
		upsert lic2;
        
		Line_Item_Type__c lit1 = new Line_Item_Type__c(Line_Item_Category__c=lic1.Id,Disclosure_Claim_for_Payment__c=dcp.Id);
		upsert lit1;
		Line_Item_Type__c lit2 = new Line_Item_Type__c(Line_Item_Category__c=lic2.Id,Disclosure_Claim_for_Payment__c=dcp.Id);
		upsert lit2;
        
        List<Line_Item__c> upsertList = new List<Line_Item__c>();
        Line_Item__c li = new Line_Item__c(Line_Item_Type__c = lit1.Id, RecordTypeId=listRecordType.get('Line Item'));
        upsertList.add(li);
        Line_Item__c li1 = new Line_Item__c(Line_Item_Type__c = lit2.Id, RecordTypeId=listRecordType.get('Line Item'), Stakeholder__c=acc.Id);
        upsertList.add(li1);
        
        upsert upsertList;
        
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
        trimrecord = new fuseit_s2t__Trim_Record__c(Name='Test',
                                                    fuseit_s2t__Attachment_ID__c = attach.Id,
                                                    fuseit_s2t__Attachment_Name__c = 'tests',
                                                    fuseit_s2t__Parent_ID__c = dcp.Id,
                                                    fuseit_s2t__Trim_ID__c = trimserver1.Id
        );
        upsert trimrecord;
        Vouched_Line_Item__c vli = new Vouched_Line_Item__c(Line_Item__c = li.Id, Trim_Record__c = trimrecord.Id);
        upsert vli;
        Vouched_Line_Item__c vli1 = new Vouched_Line_Item__c(Line_Item__c = li1.Id, Trim_Record__c = trimrecord.Id);
        upsert vli;
    }
}