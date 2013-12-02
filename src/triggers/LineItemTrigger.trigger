/* - Set default 0 for some fields of some Line_Item_Type__c to make formula field (Line_Item__c.Count) work correctly.
* - After Insert / Update Triggers are required on the Line_Item__c Object to create/update a mirrored Line_Item__c 
* record with a record type of 'Audit Line Item' and is related to the original Line Item record
*/
trigger LineItemTrigger on Line_Item__c (after insert, after update) {
    // If isClone from a Disclosure, not create new Audit Line Item, don't call trigger
    if (!LineItemFormController.inFutureContext && !CloneDisclosureClaimForPaymentController.isCloning) {
        System.debug('vinhvinh: should not come here when cloning');
        LineItemFormController.inFutureContext = true;
        
        String auditRecordType = [SELECT Id FROM RecordType WHERE Name='Audit Line Item' LIMIT 1].Id;
        String lineItemRecordType = [SELECT Id FROM RecordType WHERE Name='Line Item' LIMIT 1].Id;
        //For Calculated Count
        Set<String> newlineItemIds = new Set<String>();
        List<Line_Item__c> listUpsertLI = new List<Line_Item__c>();
        if (Trigger.isInsert) {
            for(Line_Item__c item :Trigger.New){
                if (item.RecordTypeId == lineItemRecordType) {
                    newlineItemIds.add(item.Id);
                }
            }
        }
        List<Line_Item__c> listLI = [SELECT Id, Line_Item_Type__r.Line_Item_Category__r.Reference_Number__c, 
                                            Amount__c, Total_Number_of_Small_Donations_Made__c,
                                            Total_Number_of_Small_Donations_Received__c   
                                     FROM Line_Item__c 
                                     WHERE Line_Item_Type__r.Line_Item_Category__r.Reference_Number__c IN ('1000', '0999','1007','1016') 
                                           AND Id IN :newlineItemIds];        
        for(Line_Item__c item : listLI){
            System.Debug('Test1: '+item.Line_Item_Type__r.Line_Item_Category__r.Reference_Number__c);
            if(item.Line_Item_Type__r.Line_Item_Category__r.Reference_Number__c == '1000' 
               || item.Line_Item_Type__r.Line_Item_Category__r.Reference_Number__c == '0999'){
                if(item.Total_Number_of_Small_Donations_Received__c == NULL){
                    item.Total_Number_of_Small_Donations_Received__c = 0;
                }
            }else if(item.Line_Item_Type__r.Line_Item_Category__r.Reference_Number__c == '1007'){
                if(item.Total_Number_of_Small_Donations_Made__c == NULL){
                    item.Total_Number_of_Small_Donations_Made__c = 0;
                }
            }else if(item.Line_Item_Type__r.Line_Item_Category__r.Reference_Number__c == '1016'){
                if(item.Amount__c == NULL){
                    item.Amount__c = 0;
                }
            }
            listUpsertLI.Add(item);
        }
        upsert listUpsertLI;
        //End Calculated Count
    
        
        //For US4626
        //List<Line_Item__c> newLineItems = new List<Line_Item__c>();
        List<Line_Item__c> newAuditLineItems = new List<Line_Item__c>();
        Set<String> lineItemIds = new Set<String>();
        // Map: <String: Id of LineItem, List<>: List of audit Line Item>
        Map<String, List<Line_Item__c>> lineItemMaps = new Map<String, List<Line_Item__c>>();
        for(Line_Item__c item :Trigger.New){
            if ((item.Cloned_Line_Item__c == null) && (item.RecordTypeId == lineItemRecordType)) {
                lineItemIds.add(item.Id);
                if (lineItemMaps.get(item.Id) == null) {
                    lineItemMaps.put(item.Id, new List<Line_Item__c>());
                }
            }
        }
        // Select all audit line items
        List<Line_Item__c> oldAuditLineItems = [SELECT Id,Line_Item__c, Active__c, Line_Item_Status__c
                                                FROM Line_Item__c
                                                WHERE RecordTypeId =:auditRecordType
                                                AND Active__c = true
                                                //US5105
                                                AND Line_Item_Status__c != 'Audited'
                                                AND Line_Item__c IN :lineItemIds
                                               ];
        for (Line_Item__c auditItem : oldAuditLineItems) {
            lineItemMaps.get(auditItem.Line_Item__c).add(auditItem);
        }
        
        if (Trigger.isInsert) {
            System.Debug('vinhvinh: Come to Insert Audit trigger');
            for(Line_Item__c item :Trigger.New){
                if ((item.Cloned_Line_Item__c == null) && (item.RecordTypeId == lineItemRecordType)) {
                    if (lineItemMaps.get(item.Id).size() == 0 ) {
                        Line_Item__c temp = item.Clone(false,true);
                        temp.Line_Item__c = item.Id;
                        temp.Line_Item_Type__c = item.Line_Item_Type__c;
                        temp.RecordTypeId = auditRecordType;
                        temp.Active__c = true;
                        temp.Line_Item_Status__c = 'Not Audited';
                        newAuditLineItems.add(temp);
                    }
                }
            }
        } else if (Trigger.isUpdate) {
            System.Debug('vinhvinh: Come to Update Audit trigger');
            for(Line_Item__c item :Trigger.New){
                if ((item.Cloned_Line_Item__c == null) && (item.RecordTypeId == lineItemRecordType)) {
                    // Create new Audit Line Item
                    /*
Line_Item__c temp = item.Clone(false,true);
temp.Line_Item__c = item.Id;
temp.Line_Item_Type__c = item.Line_Item_Type__c;
temp.RecordTypeId = auditRecordType;
temp.Active__c = true;
temp.Line_Item_Status__c = 'Not Audited';
*/
                    if (lineItemMaps.get(item.Id).size() > 0) {
                        
                        // Comment--> Not change active to false, just add new audit with active__c false
                        
                        // Change active status to false;                        
                        
                        Line_Item__c temp = lineItemMaps.get(item.Id).get(0);
                        String tempId = temp.Line_Item__c;                                                
                        String tempStatus = temp.Line_Item_Status__c;
                        Map<String, Schema.SObjectField> fldObjMap = schema.SObjectType.Line_Item__c.fields.getMap();
                        List<Schema.SObjectField> fldObjMapValues = fldObjMap.values();
                        //Set<String> excludeFields = {'Id', 'CreatedBy', ''}
                        
                        for(Schema.SObjectField s : fldObjMapValues)
                        {
                            if(s.getDescribe().isCustom() && s.getDescribe().isUpdateable()){ 
                                temp.put(s.getDescribe().getName(),item.get(s.getDescribe().getName()));
                            }
                        }
                        temp.Line_Item__c = tempId;
                        temp.RecordTypeId = auditRecordType;
                        temp.Active__c = true;
                        temp.Line_Item_Status__c = tempStatus;
                        /*
temp = item.Clone(false,true);
temp.Line_Item__c = item.Id;
temp.Line_Item_Type__c = item.Line_Item_Type__c;
temp.RecordTypeId = auditRecordType;
temp.Line_Item_Status__c = 'Not Audited';
temp.Active__c = false;
*/
                        // newAuditLineItems.add(lineItemMaps.get(item.Id).get(0));
                        //temp.Active__c = false;
                        newAuditLineItems.add(temp);
                    }
                    
                }
            }
        }
        upsert newAuditLineItems;
        LineItemFormController.inFutureContext = false;
    }
}