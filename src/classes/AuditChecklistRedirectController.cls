public class AuditChecklistRedirectController{
    public Audit_Checklist__c Entity{get;set;}
    
    public AuditChecklistRedirectController(ApexPages.StandardController controller) {
        this.Entity = (Audit_Checklist__c)controller.getRecord();
    }
    
    public PageReference Redirect(){
        PageReference pageRef = new PageReference('/apex/' + (this.Entity.IsTemplate__c == true ? 'auditchecklistbuilder?auditId=' : 'auditchecklistform?id=') + this.Entity.Id);
        pageRef.setRedirect(true);
        
        return pageRef;
    }
}