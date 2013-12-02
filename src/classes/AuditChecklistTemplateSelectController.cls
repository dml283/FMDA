public class AuditChecklistTemplateSelectController{
    public String doID{get;set;}
    public List<Audit_Checklist__c> ListTemplate{get{
        // Vinh removed 'AND Disclosure_Claim_For_Payment__c = :entity.Disclosure_Claim_for_Payment__c'
        // to get all templates
    	return [
            SELECT Id, Name, Template_Description__c, Template_Name__c
            FROM Audit_Checklist__c 
            WHERE IsTemplate__c = true
        ];
    }}
    public Audit_Checklist__c Entity{get;set;}
    
    public AuditChecklistTemplateSelectController(ApexPages.StandardController controller){
        this.Entity = (Audit_Checklist__c)controller.GetRecord();
        doID = ApexPages.currentPage().getParameters().get('retURL');
        if (doID.contains('/')) doID = doID.remove('/');
    }
    
    public void fieldParentId_OnChange(){
        
    }
}