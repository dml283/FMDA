public class AcSectionNcPopupController{
    public Audit_Checklist_Section__c Entity{get;set;}
    public PagingInfo ListNcPager{get;set;}
    public List<Non_Compliance__c> ListNc{get{return this.ListNcPager.ToList();}}
    
    public AcSectionNcPopupController(ApexPages.StandardController controller){
        this.Entity = (Audit_Checklist_Section__c)controller.getRecord();
        
        Map<Id, AggregateResult> temp = new Map<Id, AggregateResult>([
            SELECT Non_Compliance__c Id
            FROM Audit_Checklist_Item_Non_Compliance_Join__c
            WHERE Audit_Checklist_Item__r.Audit_Checklist_Section__c = :this.Entity.Id
            	AND Non_Compliance__c != null
            GROUP BY Non_Compliance__c
        ]);
        
        List<string> listNcField = new List<string>();
        for(Schema.FieldSetMember f :Schema.SObjectType.Non_Compliance__c.fieldSets.Non_Compliance.GetFields()){
            listNcField.Add(f.FieldPath);
        }
        this.ListNcPager = new PagingInfo('ListNc')
            .QSelect(listNcField)
            .QFrom('Non_Compliance__c')
            .QWhere('Id IN (\'' + string.join(new List<id>(temp.keySet()), '\',\'') + '\')')
            .QOrderByAsc('Non_Compliance_Number__c');
        
    }
    
    public void voidAction(){
    }
    
    public void btnSort_Click(){
        string sortby = ApexPages.currentPage().getParameters().get('sortby');
        string sortdirection = ApexPages.currentPage().getParameters().get('sortdirection');
        
        if(schema.SObjectType.Non_Compliance__c.fields.getMap().get(sortby).getDescribe().sortable == true){
            this.ListNcPager.QOrderBy(sortby, sortdirection, true);
        }
        else{
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.Info, 'The field is not sortable'));
        }
    }
}