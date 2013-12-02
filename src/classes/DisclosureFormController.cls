/* [US4419] used for creating a Disclosure from a Disclosure Obligation
*/
public class DisclosureFormController{
    public ApexPages.StandardController Controller{get;set;}
    public Disclosure_Claim_For_Payment__c Entity{get;set;}
    public Map<String, Static_Label__c> Labels{get;set;}
    public Map<string, string> MapRecordType{get;set;}
    public boolean IsMajorPoliticalDonor{get{return this.Entity.RecordTypeId == this.MapRecordType.Get('Disclosure (Major Political Donor)');}}
    public boolean isEdit{get;set;}
    
    public DisclosureFormController(ApexPages.StandardController sc){
        this.isEdit = false;
        this.Controller = sc;
        this.Labels = Static_Label__c.GetAll();
        this.MapRecordType = new Map<string, string>();
            for(RecordType item: [SELECT Id, Name FROM RecordType WHERE sObjectType = 'Disclosure_Claim_For_Payment__c']){
                mapRecordType.Put(item.Name, item.Id);
            }
        this.Entity = (Disclosure_Claim_For_Payment__c)this.Controller.GetRecord();
        if(this.Entity.Id != null){
            this.isEdit = true;
            this.Entity = GetEntityById(this.Entity.Id);
        }else{        
            
            
            try{
                //this.Entity.Disclosure_Obligation__c = ApexPages.CurrentPage().GetParameters().Get('dcid');
                this.Entity.Disclosure_Obligation__c = ApexPages.CurrentPage().GetParameters().Get('doid');
                this.Entity.Disclosure_Obligation__r = [
                    SELECT Id, Stakeholder__c, Official_Agent_ID__c,Stakeholder__r.Party_Agent__c, Stakeholder__r.RecordType.Name, Registration__r.RecordType.Name, Registration__r.Election_Event1__r.RecordType.Name,
                            Disclosure_Period_Ends__c, Disclosure_Period_Commences__c, Registration__c
                    FROM Disclosure_Obligation__c
                    WHERE Id = :this.Entity.Disclosure_Obligation__c
                    LIMIT 1
                ];
                //Set default Period End Date
                this.Entity.Disclosure_Period_Ends__c = this.Entity.Disclosure_Obligation__r.Disclosure_Period_Ends__c;
                //Set default Disclosure Period Commences date
                //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, String.valueof(this.Entity.Disclosure_Obligation__r.Disclosure_Period_Commences__c)));
                this.Entity.Disclosure_Period_Commences__c = this.Entity.Disclosure_Obligation__r.Disclosure_Period_Commences__c;
                if(this.Entity.Disclosure_Obligation__r.Registration__c == null){
                    if(this.Entity.Disclosure_Obligation__r.Stakeholder__r.RecordType.Name == 'Person'){
                        this.Entity.RecordTypeId = mapRecordType.Get('Disclosure (Major Political Donor)');
                    }
                    else if(this.Entity.Disclosure_Obligation__r.Stakeholder__r.RecordType.Name == 'Political Party'){
                        this.Entity.RecordTypeId = mapRecordType.Get('Disclosure (Political Party)');
                    }
                }
                else{
                    string regType = this.Entity.Disclosure_Obligation__r.Registration__r.RecordType.Name;
                    string campType = this.Entity.Disclosure_Obligation__r.Registration__r.Election_Event1__r.RecordType.Name;
                    if(regType == 'Elected Member'){
                        if(campType == 'Local Government Election Event'){
                            this.Entity.RecordTypeId = mapRecordType.Get('Disclosure (Elected Member - Local Government Councillor)');
                        }
                        else if(campType == 'State Election Event' || campType == 'State Election Group'){
                            this.Entity.RecordTypeId = mapRecordType.Get('Disclosure (Elected Member - Member of Parliament)');
                        }
                    }
                    else if(regType == 'Candidate'){
                        if(campType == 'Local Government Election Event'){
                            this.Entity.RecordTypeId = mapRecordType.Get('Disclosure (Local Government Candidate)');
                        }
                        else if(campType == 'State Election Event' || campType == 'State Election Group'){
                            this.Entity.RecordTypeId = mapRecordType.Get('Disclosure (State Candidate)');
                        }
                    }
                    else if(regType == 'Group of Candidates'){
                        if(campType == 'Local Government Election Event'){
                            this.Entity.RecordTypeId = mapRecordType.Get('Disclosure (Group of Local Government Candidates)');
                        }
                        else if(campType == 'State Election Event'){
                            this.Entity.RecordTypeId = mapRecordType.Get('Disclosure (Group of State Candidates)');
                        }
                    }
                    else if(regType == 'Third-Party Campaigner'){
                        this.Entity.RecordTypeId = mapRecordType.Get('Disclosure (Third-Party Campaigner)');
                    }
                }
                this.Entity.Stakeholder__c = this.Entity.Disclosure_Obligation__r.Stakeholder__c;
                this.Entity.Official_Agent__c = this.Entity.Disclosure_Obligation__r.Official_Agent_ID__c;
                this.Entity.OwnerId = UserInfo.GetUserId();
                
                if(this.Entity.RecordTypeId == this.MapRecordType.Get('Disclosure (Political Party)')){
                    this.Entity.Official_Agent__c = this.Entity.Disclosure_Obligation__r.Stakeholder__r.Party_Agent__c;
                }
            }
            catch(Exception ex){
                ApexPages.addMessages(ex);
            }
    	}
    }
    
    private Disclosure_Claim_For_Payment__c GetEntityById(String id){
        return [SELECT Id, Name, OwnerId, Stakeholder__c, RecordTypeId, Disclosure_Obligation__c, Status__c,
                Cloned_Disclosure_Claim_for_Payment__c, Active__c, Version_Number__c,
                Disclosure_Period_Commences__c, Disclosure_Period_Ends__c, Official_Agent__c, 
                Signed_By_Official_Agent__c, Signed_By_Official_Agent_Date__c, Auditor_Name__c, Signed_by_Auditor__c, 
                Auditor_Registration_Number__c, Signed_by_Auditor_Date__c, Date_Received__c, Date_Checked__c, 
                Received_By__c, Checked_By__c,Signed_by_Political_Donor__c, Signed_by_Political_Donor_Date__c 
                FROM Disclosure_Claim_For_Payment__c
                WHERE Id =:id
                LIMIT 1];
    }
    
    public Pagereference SaveAndNew()
  	{
        try
        {
    		upsert this.Entity;
            Pagereference pageRef = new PageReference('/apex/disclosureform?doid=' + this.Entity.Disclosure_Obligation__c);
            pageRef.SetRedirect(true);
    		return pageRef;
        }
        catch(Exception ex)
        {
            ApexPages.addMessages(ex);
            return null;
        }        
   	}
}