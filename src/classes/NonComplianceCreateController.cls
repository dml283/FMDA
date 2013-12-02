/* Used for creating new 'Non-Compliance'.
** - The Task Object is being used as a means of capturing areas on Non-Compliance in relation 
** to the different data that is being captured for a Disclosure.
*/
public class NonComplianceCreateController{
    public ApexPages.StandardController Controller{get;set;}
    public Task Entity{get;set;}
    public String retURL{get;set;}
    public String recordTypeName{get;set;}
    public Boolean hasDueDate{get;set;}
    public String offender{get;set;}
    public transient Map<string, Schema.FieldSet> AllTaskFieldSet;
    public Map<string, Schema.FieldSet> GetAllTaskFieldSet(){
        return Schema.SObjectType.Task.fieldSets.getMap();
    }
    
    public NonComplianceCreateController(ApexPages.StandardController sc){
        try {
            this.Controller = sc;
            this.Entity = (Task)this.Controller.GetRecord();
            //ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'v: ' + this.Entity.Id));
            this.Entity.RecordTypeId = ApexPages.CurrentPage().GetParameters().Get('RecordType');
            retURL = ApexPages.CurrentPage().GetParameters().Get('retURL');
            
            this.Entity.WhatId = ApexPages.CurrentPage().GetParameters().Get('what_id');
            this.recordTypeName = getRecordTypeNameFromWhatId(this.Entity.WhatId);
            //ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.INFO, recordTypeName));
            this.Entity.WhoId = null;
            String whoId = ApexPages.CurrentPage().GetParameters().Get('who_id');
            if(whoId == null && retURL != null && retURL.length() > 0){
                String dcpId = retURL.SubString(1, retURL.length()); 
                //ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'dcpId: ' + dcpId));
                List<Disclosure_Claim_for_Payment__c> DCP = [SELECT Id, name, OwnerId, Stakeholder__c
                                                      FROM Disclosure_Claim_for_Payment__c
                                                      WHERE Id =:dcpId];
                if(DCP != null && DCP.size() > 0){
                    whoId = DCP[0].Stakeholder__c;
                }
                
            }
            //If come from Disclosure_Obligation__c
            if(retURL != null && retURL.length() > 0){
                String doId = retURL.SubString(1, retURL.length()); 
                List<Disclosure_Obligation__c> DOb = [SELECT Id, name, Lodgement_Due_Date__c
                                                      FROM Disclosure_Obligation__c
                                                      WHERE Id =:doId];
                if(DOb != null && DOb.size() > 0){
                    this.Entity.ActivityDate = DOb[0].Lodgement_Due_Date__c; 
                    hasDueDate = true;
                }
            }
            
            List<Contact> contactList = [SELECT Id, name, Account.Name FROM Contact WHERE Account.Id =: whoId];
            
            if(contactList.size() > 0){
                this.Entity.WhoId = contactList[0].Id;
            }
            this.Entity.OwnerId = UserInfo.GetUserId();
        } catch (Exception e) {
            ApexPages.addMessages(e);
        }
    }
    
    public PageReference Save(){
        try{
            this.Entity.Offender__c = this.offender;
            System.debug('abc: ' + this.offender);
            upsert this.Entity;
            PageReference newPage = new PageReference(retURL);
            newPage.setRedirect(true);
            return newPage;
        }catch(Exception ex){
            ApexPages.AddMessages(ex);
            return null;
        }
    }
    private String getRecordTypeNameFromObjectName(String objectName, String whatId) {
        String recordTypeName = '';
        if (objectName == 'Line_Item__c') {
            recordTypeName = 'Line Item Non-Compliance';
        } else if (objectName == 'Official_Agent_Appointment__c') {
            recordTypeName = 'Official Agent Appointment Non-Compliance';
        } else if (objectName == 'Party_Agent_Appointment__c') {
            recordTypeName = 'Party Agent Appointment Non-Compliance';
        } else if (objectName == 'Registration__c') {
            recordTypeName = 'Registration Non-Compliance';
        }
        //US5169
        else if (objectName == 'Disclosure_Obligation__c') {
            //recordTypeName = 'Disclosure Obligation Non-Compliance';
            recordTypeName = 'Disclosure Non-Compliance';
        }
        //End US5169
        else if (objectName == 'Disclosure_Claim_for_payment__c') {
            String tempRecordName = [Select RecordType.Name from Disclosure_Claim_for_payment__c where id=:whatId][0].RecordType.Name;
            if (tempRecordname.startsWith('Disclosure')) {
                recordTypeName = 'Disclosure Non-Compliance';
            } else {
                recordTypeName = 'Claim for Payment Non-Compliance';
            }
        }
        return recordTypeName;
    }
    private String getRecordTypeNameFromWhatId(String whatId) {
        String tPrefix = whatId.subString(0,3);
        String objectName = '';
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe(); 
        Set<String> keyPrefixSet = gd.keySet();
        for(String sObj : keyPrefixSet){
           Schema.DescribeSObjectResult r =  gd.get(sObj).getDescribe();
            if (r.getKeyPrefix() != null) {
                if (r.getKeyPrefix().compareTo(tPrefix) == 0) {
                    objectName =  r.getName();
                    break;
                }
            }
        }
        return getRecordTypeNameFromObjectName(objectName, whatId);
    }
}