/* [US4420] used for creating a Claim for Payment from a Disclosure Obligation.
*/
public class ClaimFormController{
    public ApexPages.StandardController Controller{get;set;}
    public Disclosure_Claim_For_Payment__c Entity{get;set;}
    public Map<String, Static_Label__c> Labels{get;set;}
    //show form or show record type selection screen
    //public boolean ShowForm{get;set;}
    
    public ClaimFormController(ApexPages.StandardController sc){
        this.Controller = sc;
        this.Entity = (Disclosure_Claim_For_Payment__c)this.Controller.GetRecord();
        this.Labels = Static_Label__c.GetAll();
        //this.ShowForm = false;
        
        try{
            this.Entity.Eligible_Claim_for_Payment__c = ApexPages.CurrentPage().GetParameters().Get('ecpid');
            this.Entity.Eligible_Claim_for_Payment__r = [
                SELECT Id, Stakeholder__c, Stakeholder__r.Party_Agent__c,Claim_for_Payment_Record_Type__c, Registration__r.Official_Agent__c, Public_Fund__c
                FROM Eligible_Claim_for_Payment__c
                WHERE Id = :this.Entity.Eligible_Claim_for_Payment__c
                LIMIT 1
            ];
            this.Entity.Stakeholder__c = this.Entity.Eligible_Claim_for_Payment__r.Stakeholder__c;
            this.Entity.Official_Agent__c = this.Entity.Eligible_Claim_for_Payment__r.Registration__r.Official_Agent__c;
            if(this.Entity.Official_Agent__c == null){
            	this.Entity.Official_Agent__c = this.Entity.Eligible_Claim_for_Payment__r.Stakeholder__r.Party_Agent__c;
            }
            this.Entity.OwnerId = UserInfo.GetUserId();
            //HanhLuu:US5253
            this.Entity.RecordTypeId = GetRecordTypeId(this.Entity.Eligible_Claim_for_Payment__r.Public_Fund__c);            
        }
        catch(Exception ex){
            ApexPages.addMessages(ex);
        }
    }   
    
   
    public List<SelectOption> GetRecordTypes(){
        List<SelectOption> temp = new List<SelectOption>();
        Map<string, string> mapRecordType = new Map<string, string>();
        for(RecordType item: [SELECT Id, Name FROM RecordType WHERE sObjectType = 'Disclosure_Claim_For_Payment__c' AND Name LIKE 'Claim for Payment%']){
            mapRecordType.Put(item.Name, item.Id);
        }
        for(string rType : new string[]{
            	'Claim for Payment (Elections Campaign Fund)',
                'Claim for Payment (Administration Fund)',
                'Claim for Payment (Policy Development Fund)'}){
                    if(mapRecordType.ContainsKey(rType)){
                        temp.Add(new SelectOption(mapRecordType.Get(rType), rType));
                        mapRecordType.Remove(rType);
                    }
                }
        
        for(string key :mapRecordType.KeySet()){
            temp.Add(new SelectOption(mapRecordType.Get(key), key));
        }        
        return temp;
    }

    public Pagereference SaveAndNew()
    {
        try
        {
            upsert this.Entity;
            Pagereference pageRef = new PageReference('/apex/claimform?ecpid=' + this.Entity.Eligible_Claim_for_Payment__c);
            pageRef.SetRedirect(true);
            return pageRef;
        }
        catch(Exception ex)
        {
            ApexPages.addMessages(ex);
            return null;
        }        
    }
    
    //HanhLuu:US5253:Start
    public id GetRecordTypeId(String parentValue){
        String search_Pattern = '%' + parentValue + '%';
    	RecordType recordTypes = [SELECT Id, Name, DeveloperName 
                                  FROM RecordType 
                                  WHERE sObjectType = 'Disclosure_Claim_For_Payment__c' AND Name LIKE :search_Pattern
                                  LIMIT 1];
        return recordTypes.Id;
    }
    //HanhLuu:US5253:End
}