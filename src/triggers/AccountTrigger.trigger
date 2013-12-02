/* Description:
* Name: AccountTrigger
* Called when: after an account record is Updated
* Job: updates applicable Official Agent Appointment records when a Stakeholder successfully passes their online training
*/
trigger AccountTrigger on Account (after update) {
    if(Trigger.IsAfter && Trigger.IsUpdate){
        Set<string> accountIds = new Set<string>();
        List<SObject> records = new List<SObject>();
        List<Official_Agent_Appointment__c> oaas;
        Map<Id, SObject> registrations = new Map<Id, SObject>();
        Map<Id, Date> mapDate = new Map<Id, Date>();
        Map<Id, List<Official_Agent_Appointment__c>> mapRegistrations = new Map<Id, List<Official_Agent_Appointment__c>>();
        
        for(Account item :Trigger.New){
            Account oldAccount = Trigger.OldMap.Get(item.Id);
            if((oldAccount.Training_Status__c == null || oldAccount.Training_Status__c == 'Training Required') && (item.Training_Status__c == 'Online Training Complete' || item.Training_Status__c == 'Training Not Required')){
            	accountIds.Add(item.Id);
            }
        }
        
        oaas = [
            SELECT Id, Status__c, Date_To__c, Date_From__c, Date_Received__c, Registration__c,
            		Registration__r.Official_Agent__c, Official_Agent__c
            FROM Official_Agent_Appointment__c 
            WHERE Official_Agent__c IN :accountIds
            	AND Status__c = 'Pending Agent Training'
            	AND Date_Received__c != null
        ];
        
        for(Official_Agent_Appointment__c item :oaas){
            item.Status__c = 'Active';
            item.Date_From__c = item.Date_Received__c;
            item.Registration__r.Official_Agent__c = item.Official_Agent__c;
            registrations.Put(item.Registration__c, item.Registration__r);
            mapDate.Put(item.Registration__c, item.Date_Received__c);
            mapRegistrations.Put(item.Registration__c, new List<Official_Agent_Appointment__c>());
            
            records.Add(item);
        }
        
        oaas = [
            SELECT Id, Status__c, Date_To__c, Date_Received__c, Registration__c
            FROM Official_Agent_Appointment__c 
            WHERE Registration__c IN :registrations.KeySet()
            	AND Status__c = 'Active'
        ];
        
        for(Official_Agent_Appointment__c item :oaas){
            mapRegistrations.get(item.Registration__c).add(item);
        }
        for(Id item :mapRegistrations.Keyset()){
            for(Official_Agent_Appointment__c obj :mapRegistrations.get(item)){
                obj.Status__c = 'Inactive';
                //obj.Date_To__c = mapDate.get(item);	
                //For US4922
                obj.Date_To__c = mapDate.get(item).addDays(-1);	
                
                records.Add(obj);
            }
            /*
            item.Status__c = 'Inactive';
            item.Date_To__c = item.Date_Received__c;			
            
            records.Add(item);
			*/
        }
        
        oaas = [
            SELECT Id,Status__c
            FROM Official_Agent_Appointment__c 
            WHERE Official_Agent__c IN :accountIds
            	AND Status__c = 'Pending Agent Training'
            	AND Date_Received__c = null
        ];
        
        for(Official_Agent_Appointment__c item :oaas){
            item.Status__c = 'Pending Notice of Appointment Form';
            
            records.Add(item);
        }
        
        records.AddAll(registrations.Values());
        
        update records;
    }
}