trigger AttachmentTrigger on Attachment (after insert) {
    List<String> listParentId = new List<String>();
    Set<String> setParentId = new Set<String>();
    Map<String,Attachment> mapAtt = new Map<String,Attachment>();
    Map<String,String> mapURL = new Map<String,String>();
    Set<String> AttachmentIDs = new Set<String>();
    List<fuseit_s2t__Trim_Record__c> listToUpsert = new List<fuseit_s2t__Trim_Record__c>();
    
    for(Attachment attachment : Trigger.NEW){
        AttachmentIDs.add(attachment.Id);
    }
    Map<Id, AggregateResult> attCountMap = new Map<Id, AggregateResult>(
                            [SELECT fuseit_s2t__Attachment_ID__c Id, COUNT(Id) Cnt FROM fuseit_s2t__Trim_Record__c 
                             WHERE fuseit_s2t__Attachment_ID__c IN :AttachmentIDs 
                             GROUP BY fuseit_s2t__Attachment_ID__c]);
    
    
    for(Attachment attachment : Trigger.NEW){
        /*Integer counter = [SELECT count() FROM fuseit_s2t__Trim_Record__c WHERE fuseit_s2t__Attachment_ID__c =: attachment.Id];
        if(counter == 0){
            listParentId.Add(attachment.ParentId);
            mapAtt.put(attachment.ParentId, attachment);    
        }*/
        if (!attCountMap.containsKey(attachment.Id)) {
            listParentId.Add(attachment.ParentId);
            mapAtt.put(attachment.ParentId, attachment);
        }
    }
    
    
    
    /*
    for(Registration__c obj : [SELECT Id, TRIM_Container_URI__c FROM Registration__c WHERE Id IN :listParentId]){
        setParentId.add(obj.Id);
        mapURL.put(obj.Id,obj.TRIM_Container_URI__c);
    }*/
    for(Disclosure_Claim_for_Payment__c obj : [SELECT Id, TRIM_Container_URI__c FROM Disclosure_Claim_for_Payment__c WHERE Id IN :listParentId]){
        setParentId.add(obj.Id);
        mapURL.put(obj.Id,obj.TRIM_Container_URI__c);
    }
    /*
    for(Disclosure_Obligation__c obj : [SELECT Id, TRIM_Container_URI__c FROM Disclosure_Obligation__c WHERE Id IN :listParentId]){
        setParentId.add(obj.Id);
        mapURL.put(obj.Id,obj.TRIM_Container_URI__c);
    }*/
    // Check whether Sandbox or production
    String trimServerName = 'NSWEC TRIM';
    String trimServerId;
    // Sandbox and production use same trim server name, comment these code
        // String s  =  System.URL.getSalesforceBaseUrl().getHost();
        // Sandbox
        // if (Pattern.matches('(.*\\.)?cs[0-9]*(-api)?\\..*force.com',s)) {
        //     trimServerName = 'NSWEC TRIM DEV';
        // } else {    //Production
        //     trimServerName = 'NSWEC TRIM';
        // }
    try
    {
        fuseit_s2t__Trim__c trimRec = [SELECT ID                                      
                                       FROM fuseit_s2t__Trim__c
                                       WHERE Name = :trimServerName LIMIT 1];
        
        trimServerId = trimRec.ID;   
    }      
    catch (Exception e)
    {
        System.debug('Error Occurred:' + '[' + e.getMessage() +' ]');            
        throw new FADMSException(e.getMessage());
    }   

    for(String strId : setParentId){
        Attachment att = mapAtt.get(strId);
        String location = mapURL.get(strId);
        String extension = '';
        if (att.Name.contains('.')) {
            extension = att.Name.subString(att.Name.lastIndexOf('.') + 1);
        }
        fuseit_s2t__Trim_Record__c TR = new fuseit_s2t__Trim_Record__c();
        TR.Name = att.Name;
        TR.fuseit_s2t__File_Extension__c = extension;
        TR.fuseit_s2t__Parent_ID__c = att.ParentId;
        TR.fuseit_s2t__Attachment_Type__c = 'Attachment';
        TR.fuseit_s2t__Attachment_ID__c = att.Id;
        TR.fuseit_s2t__Attachment_Name__c = att.Name;
        TR.fuseit_s2t__Trim_ID__c = trimServerId;
        TR.fuseit_s2t__Trim_Location_ID__c = location;
        TR.fuseit_s2t__Trim_Record_Type__c = 'Document';
        TR.fuseit_s2t__Trim_Status__c = 'Scheduled';
        TR.fuseit_s2t__isPreserve__c = TRUE;
        
        listToUpsert.add(TR);
    }
    upsert listToUpsert;
}