@isTest
public class TestAttachmentTrigger{
	static testMethod void newTest() {
        List<RecordType> recordTypes = [SELECT Id, Name FROM RecordType Where Name='Disclosure (Major Political Donor)' Limit 1];
		String recordTypeId=recordTypes[0].Id;
        
        fuseit_s2t__Trim__c trimserver1 = new fuseit_s2t__Trim__c(Name='NSWEC TRIM DEV',
                                                                  fuseit_s2t__Trim_IP_Address__c='http://svrapps7.seodom.local/trimdevSecure/retrievedoc.aspx?recordno=',
                                                                  fuseit_s2t__Trim_Light_IP_Address__c ='https://s2t-testing.elections.nsw.gov.au/trimws/trim.asmx',
                                                                  fuseit_s2t__Trim_Default_Location_ID__c = '98504'
                                                                 );

        upsert trimserver1;
		fuseit_s2t__Trim__c trimserver2 = new fuseit_s2t__Trim__c(Name='NSWEC TRIM',
                                                                  fuseit_s2t__Trim_IP_Address__c='http://svrapps7.seodom.local/trimdevSecure/retrievedoc.aspx?recordno=',
                                                                  fuseit_s2t__Trim_Light_IP_Address__c ='https://s2t-testing.elections.nsw.gov.au/trimws/trim.asmx',
                                                                  fuseit_s2t__Trim_Default_Location_ID__c = '98504'
                                                                 );

        upsert trimserver2;
		Disclosure_Claim_for_Payment__c dcp = new Disclosure_Claim_for_Payment__c(RecordTypeId=recordTypeId);
		upsert dcp;

        Attachment attach=new Attachment();   	
    	attach.Name='Unit Test Attachment';
    	Blob bodyBlob=Blob.valueOf('Unit Test Attachment Body');
    	attach.body=bodyBlob;
        attach.parentId=dcp.id;
        upsert attach;
    }
    
}