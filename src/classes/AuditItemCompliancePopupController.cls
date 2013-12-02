public class AuditItemCompliancePopupController{
    public List<SelectOption> numberItemPerPageOptions{get;set;}
    public List<NonComplianceWrapper> WrapperList{get;set;}
    public String checklistItemId{get;set;}
    public String sectionId{get;set;}
    private Integer RecordCounter;
    public Map<string, Schema.FieldSet> GetAllComFieldSet(){
        return Schema.SObjectType.Non_Compliance__c.fieldSets.getMap();
    } 
    public AuditItemCompliancePopupController() {
        try {
            checklistItemId = ApexPages.CurrentPage().GetParameters().Get('checklistItemId');
            sectionId = ApexPages.CurrentPage().GetParameters().Get('sectionId');
            
            numberItemPerPageOptions = new List<SelectOption>();
            numberItemPerPageOptions.add(new SelectOption('5', '5'));
            numberItemPerPageOptions.add(new SelectOption('10', '10'));
            numberItemPerPageOptions.add(new SelectOption('20', '20'));
            numberItemPerPageOptions.add(new SelectOption('50', '50'));
            numberItemPerPageOptions.add(new SelectOption('100', '100'));
            
            RecordCounter = 0;
            WrapperList = new List<NonComplianceWrapper>();
        	String query = CompSelectField();
            query += ' FROM Audit_Checklist_Item_Non_Compliance_Join__c WHERE Audit_Checklist_Item__c=\'' 
                	+ checklistItemId + '\'';
            for (Audit_Checklist_Item_Non_Compliance_Join__c item : Database.query(query)) {
                NonComplianceWrapper temp = new NonComplianceWrapper(RecordCounter++,item);
                WrapperList.add(temp);
            }
        } catch (Exception e){
            ApexPages.addMessages(e);
        }
    }
    
    public void SaveItem() {
        try {
            Integer ItemId = Integer.valueOf(ApexPages.CurrentPage().GetParameters().Get('itemId'));
            String NonComplianceId = ApexPages.CurrentPage().GetParameters().Get('NonComplianceId');
            for (NonComplianceWrapper temp : WrapperList) {
                if (temp.Id == ItemId) {
                    temp.Item.Non_Compliance__c = NonComplianceId;
                    upsert temp.Item;
                    temp.Item = getChecklistItemById(temp.Item.Id);
                    break;
                }
            }
        } catch (Exception e) {
            ApexPages.addMessages(e);
        }
    }
    public void btnAdd_OnClick() {
        Audit_Checklist_Item_Non_Compliance_Join__c item = new Audit_Checklist_Item_Non_Compliance_Join__c(Audit_Checklist_Item__c=checklistItemId);
        NonComplianceWrapper temp = new NonComplianceWrapper(RecordCounter++,item);
        if (WrapperList.size() == 0) {
            WrapperList.add(temp); 
        } else {
            WrapperList.add(temp); 
        }
    }
    
    public void btnDelete_OnClick() {
        try {
            List <Audit_Checklist_Item_Non_Compliance_Join__c> delList = new List<Audit_Checklist_Item_Non_Compliance_Join__c>();
            for (NonComplianceWrapper temp : WrapperList) {
                if (temp.isInclude) {
                    delList.add(temp.item);
                }
            }
            delete delList;
            for (Integer i = WrapperList.size() - 1; i >= 0; i--) {
                NonComplianceWrapper temp = WrapperList.get(i);
                if (temp.isInclude) {
                    WrapperList.remove(i);
                }
            }
        } catch (Exception e) {
            ApexPages.addMessages(e);
        }
    }
    private Audit_Checklist_Item_Non_Compliance_Join__c getChecklistItemById(String itemId) {
        String query = CompSelectField();
        query += ' FROM Audit_Checklist_Item_Non_Compliance_Join__c WHERE Id=\'' 
            + itemId + '\' Limit 1';
        return Database.query(query);
    }
    private String CompSelectField () {
        String query = 'SELECT ';
        Schema.FieldSet CompFieldSet = Schema.SObjectType.Non_Compliance__c.fieldSets.Non_Compliance;
        for(Schema.FieldSetMember f : CompFieldSet.getFields()) {
            query += 'Non_Compliance__r.' + f.getFieldPath() + ', ';
        }
        query += 'Id, Non_Compliance__c, Audit_Checklist_Item__c ';
        return query;
    }
    
    public class NonComplianceWrapper {
        public Audit_Checklist_Item_Non_Compliance_Join__c Item{get;set;}
        public Integer Id{get;set;}
        public boolean isInclude{get;set;}
        public NonComplianceWrapper(Integer RecordId, Audit_Checklist_Item_Non_Compliance_Join__c Item) {
            this.Id = RecordId;
            this.Item = Item;
            isInclude = false;
        }
    }
}