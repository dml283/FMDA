/* Used for adding a new ‘Non-Compliance’ Task records.
*/
public class NonComplianceFormController{
    public boolean IsPostBack{get;set;}
    public List<ItemWrapper> ItemWrapperList{get;set;}
    public String whatId{get;set;}
    public String whoId{get;set;}
    public String DOId{get;set;}
    public Date dueDate{get;set;}
    public String offender{get;set;}
    public String aggregatedCategories{get;set;}
    public String recordTypeName{get;set;}
    public String fromPage{get;set;}
    public Integer RecordCounter{get;set;}
    public string NonComplianceRecordTypeId{get;set;}
    private String queryTaskAllField;
    public List<SelectOption> numberItemPerPageOptions{get;set;}
    public PagingInfo ItemPagingInfo{get;set;}
    public transient Map<string, Schema.FieldSet> AllTaskFieldSet;
    public Map<string, Schema.FieldSet> GetAllTaskFieldSet(){
        return Schema.SObjectType.Task.fieldSets.getMap();
    }
    public string LineItemType{get;set;}
    public NonComplianceFormController() {
        if(this.IsPostBack == null){
            try {
                String tempStakeholderId = '';
                whatId = ApexPages.CurrentPage().GetParameters().Get('whatId');
                this.LineItemType = ApexPages.CurrentPage().GetParameters().Get('litId');
                if (whatId.length() < 18) {
                    whatId = (Id)whatId;
                }
                recordTypeName = ApexPages.CurrentPage().GetParameters().Get('recordTypeName');
                fromPage = ApexPages.CurrentPage().GetParameters().Get('fromPage');
                whoId = '';
                // Check if it is a disclosure Id
                List<Disclosure_Claim_For_Payment__c> dcpList = [SELECT Id, Stakeholder__c, Disclosure_Obligation__c
                                                                 FROM Disclosure_Claim_For_Payment__c
                                                                 WHERE Id=:whatId];
                queryTaskAllField = TaskSelectField();
                if (dcpList.size() > 0) {
                    // It is a Disclosure_Claim_For_Payment__c
                    tempStakeholderId = dcpList.get(0).Stakeholder__c;
                    //US5089
                    DOId = dcpList.get(0).Disclosure_Obligation__c;
                    
                } else {
                    List<Line_Item__c> liList = [SELECT Id, Line_Item_Type__r.Disclosure_Claim_For_Payment__r.Stakeholder__c
                                                 FROM Line_Item__c WHERE Id=:whatId];
                    if (liList.size() > 0) {
                        tempStakeholderId = liList.get(0).Line_Item_Type__r.Disclosure_Claim_For_Payment__r.Stakeholder__c;
                    }
                }
                List<Contact> contactList = [SELECT Id, name FROM Contact WHERE Account.Id =:tempStakeholderId];
                //List<Lead> leadList = [SELECT Id, name FROM Lead WHERE Id =: whoId];
                if(contactList.size() > 0){
                    whoId = contactList[0].Id;
                }
                
                
                numberItemPerPageOptions = new List<SelectOption>();
                numberItemPerPageOptions.add(new SelectOption('5', '5'));
                numberItemPerPageOptions.add(new SelectOption('10', '10'));
                numberItemPerPageOptions.add(new SelectOption('20', '20'));
                numberItemPerPageOptions.add(new SelectOption('50', '50'));
                numberItemPerPageOptions.add(new SelectOption('100', '100'));
                
        		this.NonComplianceRecordTypeId = [SELECT Id FROM RecordType WHERE sObjectType='Task' AND Name='Non-Compliance' LIMIT 1].Id;
                buildItemWrapper();
                this.IsPostBack = false;
            } catch (Exception e){
                ApexPages.addMessages(e);
            }
        }
    }
    
    public void buildItemWrapper () {
        this.RecordCounter = 0;
        
        List<Task> temp = GetListItem();
        ItemWrapperList = new List<ItemWrapper>();
        
        for(Task item: temp){
            //item.ActivityDate = this.dueDate;
            ItemWrapperList.Add(new ItemWrapper(recordCounter++, item, true, false));
        }
    }
    
    private String TaskSelectField () {
        String query = '';
        Schema.FieldSet TaskFieldSet = Schema.SObjectType.Task.fieldSets.Non_Compliance;
        for(Schema.FieldSetMember f : TaskFieldSet.getFields()) {
            query += f.getFieldPath() + ', ';
        }
        query += 'Id, Non_Compliance_Id__c, Line_Item_Category_Id__c , WhoId, WhatId ';
        System.debug('query: ' + query);
        return query;
    }
    
    private List<Task> GetListItem() {
        if(this.ItemPagingInfo == null){
            this.ItemPagingInfo = 
                new PagingInfo('ItemPagingInfo')
                .QFrom('Task')
                .QWhere(' WhatId=\'' + whatId + '\' AND RecordType.Name = \'Non-Compliance\' ')
                .QOrderByAsc('Subject');
            
        	this.ItemPagingInfo.soqlSelect = this.queryTaskAllField;
        }
        return this.ItemPagingInfo.ToList();
    }
    private Task GetItem(String Id) {
        String query = 'SELECT ' + this.queryTaskAllField;
        query += ' FROM Task  WHERE Id=\'' + Id + '\'';
        return Database.query(query);
    }
    
    public void Sort(){
        ItemPagingInfo.soqlOrder = ItemPagingInfo.OrderBy + ' ' + ItemPagingInfo.OrderDirection;
        buildItemWrapper();
    }
    
    public void btnAddRow_Click(){
        try {
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info,'whatId: '+ WhatId + '  WhoId:' + whoId + '  bll'));
            Task item = new Task(WhatId=whatId, RecordTypeId = this.NonComplianceRecordTypeId);
            //US5089
            List<Disclosure_Obligation__c> DOb = [SELECT Id, name, Lodgement_Due_Date__c
                                                  FROM Disclosure_Obligation__c
                                                  WHERE Id =:DOId];
            
            if (!String.IsEmpty(whoId)) {
                item.WhoId = whoId;
            }
            if (ItemWrapperList.size() > 0) {
                if(DOb != null && DOb.size() > 0){
                    item.ActivityDate = DOb[0].Lodgement_Due_Date__c; 
                    ItemWrapperList.Add(0,new ItemWrapper(recordCounter++, item, false,true, true));
                }else{
                	ItemWrapperList.Add(0,new ItemWrapper(recordCounter++, item, false,true));
                }
            } else {
                if(DOb != null && DOb.size() > 0){
                    item.ActivityDate = DOb[0].Lodgement_Due_Date__c; 
                    ItemWrapperList.Add(new ItemWrapper(recordCounter++, item, false,true, true));
                }else{
                	ItemWrapperList.Add(new ItemWrapper(recordCounter++, item, false,true));
                }
            }
        } catch (Exception ex) {
            ApexPages.addMessages(ex);
        }
    }
    
    public void btnEditRow_Click(){
        Integer editId = Integer.valueOf(ApexPages.CurrentPage().GetParameters().Get('editId'));
        for (ItemWrapper item : ItemWrapperList) {
            if (item.Id == editId) {
                //US5089
                if(item.item.ActivityDate == NULL){
                    List<Disclosure_Obligation__c> DOb = [SELECT Id, name, Lodgement_Due_Date__c
                                                          FROM Disclosure_Obligation__c
                                                          WHERE Id =:DOId];
                    if(DOb != null && DOb.size() > 0){
                        item.item.ActivityDate = DOb[0].Lodgement_Due_Date__c; 
                        item.hasDueDate = true;
                    }
                }else{
                    item.hasDueDate = true;
                }
                item.isEdit = true;
                break;
            }
        }
    }
    
    public void btnDelRow_Click(){
        Integer delId = Integer.valueOf(ApexPages.CurrentPage().GetParameters().Get('editId'));
        for (Integer i = 0; i < ItemWrapperList.size(); i++) {
            ItemWrapper item = ItemWrapperList.get(i);
            if (item.Id == delId) {
                try {
                    delete item.item;
                } catch (Exception e){
                    ApexPages.addMessages(e);
                    return;
                }
                ItemWrapperList.remove(i);
                break;
            }
        }
    }
    
    public void btnSaveRow_Click(){
        Integer saveId = Integer.valueOf(ApexPages.CurrentPage().GetParameters().Get('editId'));
        for (ItemWrapper item: ItemWrapperList) {
            if (item.Id == saveId) {
                try {
                    if (item.item.Non_Compliance_Id__c == null) {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,'You must select one Non-Compliance Issue!'));
                        return;
                    }
                    item.item.Offender__c = offender;
                    item.item.Line_Item_Aggregated_Categories__c = aggregatedCategories;                    
                    upsert item.item;
                    item.item = GetItem(item.item.Id);
                    item.IsExist = true;
                    item.IsEdit = false;
                    break;
                } catch (Exception e){
                    ApexPages.addMessages(e);
                    return;
                }
            }
        }
    }
    public void btnCancelRow_Click(){
        Integer cancelId = Integer.valueOf(ApexPages.CurrentPage().GetParameters().Get('editId'));
        for (Integer i = ItemWrapperList.size() - 1; i >= 0; i--) {
            ItemWrapper item = ItemWrapperList.get(i);
            if (item.Id == cancelId) {
                if (item.IsExist) {
                    item.item = GetItem(item.item.Id);
                    item.isEdit = false;
                } else {
                    ItemWrapperList.remove(i);
                }
                break;
            }
        }
    }
    public class ItemWrapper {
        public Integer Id {get;set;}
        public Task item{get;set;}
        public boolean IsExist{get;set;}
        public boolean IsEdit{get;set;}
        public Boolean hasdueDate{get;set;}
        public ItemWrapper(integer idCounter, Task item, boolean isExist, boolean isEdit, boolean HasDueDate){
            this.Id = idCounter;
            this.item = item;
            this.IsExist = isExist;
            this.IsEdit = isEdit;
            this.hasdueDate = HasDueDate;
        }
        public ItemWrapper(integer idCounter, Task item, boolean isExist, boolean isEdit){
            this.Id = idCounter;
            this.item = item;
            this.IsExist = isExist;
            this.IsEdit = isEdit;
        }
    }
    
}