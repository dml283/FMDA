global class TrimRecordSynBatchController implements Database.Batchable<SObject>, Database.AllowsCallouts {
	private final Set<String> trimRecordIds;
	private boolean m_isTestMode = false;
    
	public TrimRecordSynBatchController(Set<String> ids) {
		trimRecordIds = ids;	
        if (Test_Mode__c.getValues('TestMode') != null) {
            m_isTestMode = Test_Mode__c.getValues('TestMode').isTestMode__c;
        }
	}
	
	global Database.QueryLocator start(Database.BatchableContext ctx) {
        String query = TRIMRecordAllFields();
        query += ' FROM fuseit_s2t__Trim_record__c WHERE Id IN :trimRecordIds';
		return Database.getQueryLocator(query);
	}
    
    global void execute(Database.BatchableContext ctx, List<SObject> records) {
        fuseit_s2t__Trim__c trimServer = getTrimServer();
    	Set<String> attIds = new Set<String>();
    	for (SObject rec : records) {
            fuseit_s2t__Trim_record__c temp = (fuseit_s2t__Trim_record__c) rec;
    		attIds.add(temp.fuseit_s2t__Attachment_ID__c);
    	}
    	Map<Id, Attachment> attachmentsMap = new Map<Id,Attachment>(
    		[Select Id, ParentId, Name, Body, CreatedDate
    			FROM Attachment WHERE Id IN :attIds]
    	);
        //Integer i = 1;
        List<fuseit_s2t__Trim_record__c> upsertList = new List<fuseit_s2t__Trim_record__c>();
        for (SObject rec : records) {
        	//System.debug('vinhvinh: Callout time: ' + (i++));
            fuseit_s2t__Trim_record__c temp = (fuseit_s2t__Trim_record__c) rec;
            temp = fuseit_s2t.TrimConnector.synchronizeRecord(trimServer, temp, UserInfo.getUserId(), null,
                                                             attachmentsMap.get(temp.fuseit_s2t__Attachment_ID__c).Body, 
                                                             attachmentsMap.get(temp.fuseit_s2t__Attachment_ID__c).CreatedDate,
                                                             m_isTestMode);
			upsertList.add(temp);
        }
        upsert upsertList;
    }
    
    global void finish(Database.BatchableContext ctx) {
   	}
    
    private static string TRIMRecordAllFields(){
        Map<String, Schema.SObjectField> fldObjMap = schema.SObjectType.fuseit_s2t__Trim_record__c.fields.getMap();
		List<Schema.SObjectField> fldObjMapValues = fldObjMap.values();
        
        String theQuery = 'SELECT ';
        for(Schema.SObjectField s : fldObjMapValues)
        {
           if (s.getDescribe().isAccessible()) {
           		String theName = s.getDescribe().getName();
           		theQuery += theName + ',';
            }
        }
        theQuery += ' Line_Item_Type__r.Line_Item_Category__r.Line_Item_Category__c, Line_Item_Type__r.Disclosure_Claim_for_Payment__c ';
        // Trim last comma
        // theQuery = theQuery.subString(0, theQuery.length() - 1);
        theQuery = theQuery.replaceAll('LastReferencedDate,','');
        // Remove LastReferencedDate;
        
        return theQuery;
    }
    
    private static fuseit_s2t__Trim__c getTrimServer() {
    	fuseit_s2t__Trim__c trimServerTemp;
        String trimServerName = 'NSWEC TRIM';
        try
        {
        trimServerTemp = [SELECT ID,Name,fuseit_s2t__Trim_Light_IP_Address__c,fuseit_s2t__Trim_IP_Address__c,
        				fuseit_s2t__Trim_Default_Location_ID__c,fuseit_s2t__Key__c,fuseit_s2t__ClientCertificateName__c
                       FROM fuseit_s2t__Trim__c
                       WHERE Name = :trimServerName LIMIT 1];
            
        }      
        catch (Exception e)
        {
            System.debug('Error Occurred:' + '[' + e.getMessage() +' ]');            
            throw new FADMSException(e.getMessage());
        }
        return trimServerTemp;
    }
}