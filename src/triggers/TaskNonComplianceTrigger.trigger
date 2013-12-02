/* An After Insert Trigger is required on the Task object that will update the record 
** with the correct Non-Compliance details.
*/
trigger TaskNonComplianceTrigger on Task (after insert) {
    try{
        List<Task> taskUpsertList = new List<Task>();
        List<String> taskIdUpsertList = new List<String>();
        
        Set<String> taskIds = new Set<String>();
        Map<String, List<Non_Compliance__c>> mapNonCompliance = new Map<String, List<Non_Compliance__c>>();
        for(Task item :Trigger.New){
            if(item.Status == 'Potential Non-Compliance Flagged'){            
                taskIds.add(item.Subject.substring(0,4));
                mapNonCompliance.put(item.Subject.substring(0,4), new List<Non_Compliance__c>()); 
                taskIdUpsertList.add(item.Id);
            }
        }
        List<Non_Compliance__c> nonComplianceList = [SELECT Id, Name, Legislative_Reference__c, Compliance_Issue__c, 
                                                     Offence_Reference__c, Offender__c, Offence_Penalty__c,
                                                     Penalty_Notice_Penalty__c, Outcome__c, RecordType.Name, 
                                                     Comments__c, Line_Item_Category__r.Id, Non_Compliance_Number__c
                                                     FROM Non_Compliance__c 
                                                     WHERE Non_Compliance_Number__c IN :taskIds];                
        for(Non_Compliance__c item : nonComplianceList){
            mapNonCompliance.get(item.Non_Compliance_Number__c).add(item);
        }
        
        taskUpsertList = [SELECT id, Subject, Legislative_Reference__c, Compliance_Issue__c, Offence_Reference__c,
                          Offender__c, Offence_Penalty__c, Penalty_Notice_Penalty__c, Outcome__c, Type, Description,
                          Line_Item_Category_Id__c, Non_Compliance_Id__c, Non_Compliance_Number__c
                         FROM Task
                         WHERE Id in :taskIdUpsertList];
        
        List<RecordType> recordTypes = [SELECT Id, Name FROM RecordType Where Name='Non-Compliance' Limit 1];
		String recordTypeId=recordTypes[0].Id;
        
        for(Task item : taskUpsertList){
            List<Non_Compliance__c> newNonComplianceList = mapNonCompliance.get(item.Subject.substring(0,4));
                for(Non_Compliance__c nc : newNonComplianceList){
                    item.Subject = nc.Name;
                    item.Legislative_Reference__c = nc.Legislative_Reference__c;
                    item.Compliance_Issue__c = nc.Compliance_Issue__c;
                    item.Offence_Reference__c = nc.Offence_Reference__c;
                    item.Offender__c = nc.Offender__c;
                    item.Offence_Penalty__c = nc.Offence_Penalty__c;
                    item.Penalty_Notice_Penalty__c = nc.Penalty_Notice_Penalty__c;
                    item.Outcome__c = nc.Outcome__c;
                    item.Type = nc.RecordType.Name;
                    item.Description = nc.Comments__c;
                    if(nc.RecordType.Name == 'Line Item Non-Compliance'){
                        item.Line_Item_Category_Id__c  = nc.Line_Item_Category__r.Id;
                    }
                    item.Non_Compliance_Id__c = nc.Id;
                    item.Non_Compliance_Number__c = nc.Non_Compliance_Number__c;
                    item.RecordTypeId = recordTypeId;
                }
        }
        System.Debug('Go here!');
        upsert taskUpsertList;
    }catch(Exception e){
        ApexPages.AddMessages(e);
    }
}