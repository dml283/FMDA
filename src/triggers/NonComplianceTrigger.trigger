/* Description:
* When update Non_Compliance_Issue__c.Section__c & Non_Compliance_Issue__c.Possible_Offence__c,
* then also update Task.Section__c & Task.Possible_Offence__c (make data consistency)
*/
trigger NonComplianceTrigger on Non_Compliance__c (after update) {
    try{
        List<Task> taskUpsertList = new List<Task>();
        
        Set<String> nonComplianceIds = new Set<String>();
        Map<String, List<Task>> mapTask = new Map<String, List<Task>>();
        for(Non_Compliance__c item :Trigger.New){            
            nonComplianceIds.add(item.Id);
			mapTask.put(item.Id, new List<Task>()); 
        }
        
        List<Task> taskList = [SELECT Id, Legislative_Reference__c, Compliance_Issue__c, Non_Compliance_Id__c 
                               FROM Task WHERE Non_Compliance_Id__c IN :nonComplianceIds];                
        for(Task item : taskList){
            mapTask.get(item.Non_Compliance_Id__c).add(item);
        }
        
        for(Non_Compliance__c item :Trigger.New){   
            if(mapTask.get(item.Id).size() > 0){
                List<Task> newTaskList = mapTask.get(item.Id);
                for(Task task : newTaskList){
                    task.Legislative_Reference__c = item.Legislative_Reference__c;
                    task.Compliance_Issue__c = item.Compliance_Issue__c;
                    taskUpsertList.Add(task);
                }
            }
        }
        upsert taskUpsertList;
    }catch(Exception e){
        ApexPages.AddMessages(e);
    }
}