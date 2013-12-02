public class ReviewVouchingStatusController{
    public Line_Item__c Entity{get;set;}
    public String doID{get;set;}
    public String lineItemTypeId{get;set;}
    public Boolean isLineItemTableEdit{get;set;}
    public List<string> FilterKeys{get{return new List<string>{'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','X','Y','Z', 'All', 'Vouching', 'Advertising Material'};}}
    public ListVouchWrapper RelatedVouchList{get;set;}
    public ListVouchWrapper UnrelatedVouchList{get;set;}
    
    private Set<String> allDisclosureId{get;set;}
    public Map<string, Schema.FieldSet> GetMapLineItemFieldSets(){
        return Schema.SObjectType.Line_Item__c.fieldSets.getMap();
    }
    
    public ReviewVouchingStatusController(ApexPages.StandardController controller){
        this.Entity = (Line_Item__c)controller.GetRecord();
        this.Entity = this.GetEntityById(this.Entity.Id);
        this.doId = Entity.Line_Item_Type__r.Disclosure_Claim_For_Payment__c;
        this.lineItemTypeId = Entity.Line_Item_Type__c;
        List<Disclosure_Claim_for_payment__c> doList = [SELECT TRIM_Container_URI__c,Cloned_Disclosure_Claim_for_Payment__c,
                                                            		Disclosure_Obligation__c
                                                            FROM Disclosure_Claim_for_payment__c
                                                            WHERE Id=:doID LIMIT 1];
        allDisclosureId = new Set<String>();
        allDisclosureId.add(doID);
        if (doList.size() > 0) {
            String disObId = doList.get(0).Disclosure_Obligation__c;
            this.allDisclosureId = new Map<String, Disclosure_Claim_for_payment__c>([
                            SELECT Id from Disclosure_Claim_for_payment__c where Disclosure_Obligation__c = :disObId
                        ]).keySet();
        }
        this.InitVouching();
        isLineItemTableEdit = false;
    }
    
    public void InitVouching(){
        this.RelatedVouchList = new ListVouchWrapper(this.Entity, true, this.allDisclosureId);	// true -> related
        this.UnrelatedVouchList = new ListVouchWrapper(this.Entity, false, this.allDisclosureId);	// false -> unrelated
        this.RelatedVouchList.Query();
        this.UnrelatedVouchList.Query();
    }
    
    public Line_Item__c GetEntityById(string entityId){
        String theQuery = 'SELECT ';
        for(Schema.SObjectField s : schema.SObjectType.Line_Item__c.fields.getMap().values())
        {
            String theName = s.getDescribe().getName();
            theQuery += theName + ', ';
        }
        if (!theQuery.contains('No_Vouching_Provided__c')) {
            theQuery += ' No_Vouching_Provided__c, No_Advertising_Material_Provided__c, ';
        }
        if (!theQuery.contains(' Name,')) {
            theQuery += 'Name, ';
        }
        theQuery += ' Line_Item_Type__r.Line_Item_Category_Text__c,Line_Item_Type__r.Line_Item_Category__r.Reference_Number__c, Line_Item_Type__r.Disclosure_Claim_For_Payment__c, Line_Item_Type__r.Disclosure_Claim_For_Payment__r.Cloned_Disclosure_Claim_for_Payment__c FROM Line_Item__c WHERE Id = \''+entityId+'\' LIMIT 1';
       
        return Database.Query(theQuery);
    }
    
    public void btnRemoveVouching_OnClick() {
        RelatedVouchList.AddRemoveVouching();
        UnrelatedVouchList.Refresh();
    }
    
    public void btnAddVouching_OnClick() {
        UnrelatedVouchList.AddRemoveVouching();
        RelatedVouchList.Refresh();
    }
    public void btnEdit_Onclick() {
        isLineItemTableEdit = true;
    }
    public void btnCancel_Onclick() {
    	this.Entity = this.GetEntityById(this.Entity.Id);
        isLineItemTableEdit = false;
    }
    public void btnSave_Onclick(){
        try {
            upsert this.Entity;
            isLineItemTableEdit = false;
        } catch(Exception ex){
            ApexPages.AddMessages(ex);
        }
    }
    public class ListVouchWrapper{
        private Set<String> allDisclosureId;
        public boolean IsRelated{get;set;}
        public string FilterKey{get;set;}
        public Line_Item__c LineItem{get;set;}
        public PagingInfo Pager{get;set;}
        public List<VouchWrapper> Entities{get;set;}
        public Set<id> ListSelectedVouchIds{get;set;}
        
        public ListVouchWrapper(Line_Item__c li, boolean isRelated, Set<String> allDisclosureId){
            this.LineItem = li;
            this.IsRelated = isRelated;
            this.allDisclosureId = allDisclosureId;
            this.FilterKey = 'All';
            this.ListSelectedVouchIds = new Set<id>();
            this.Entities = new List<VouchWrapper>();
            
            List<string> fields = new List<string>();
            boolean hasVouchingType = false;
            for(Schema.FieldSetMember f :SObjectType.fuseit_s2t__Trim_Record__c.FieldSets.VouchingTRIMRecords.getFields()){
                if (f.FieldPath == 'Vouching_Type__c') hasVouchingType = true;
                fields.Add(f.FieldPath);
            }
            if (!hasVouchingType) fields.Add('Vouching_Type__c');
            this.Pager = new PagingInfo('ListVouchWrapper')
                .QSelect(fields)
                .QFrom('fuseit_s2t__Trim_Record__c')
                .QOrderByAsc('Name');
            //this.Pager.PageSize = 2;
        }
        
        public void Refresh(){
            this.ListSelectedVouchIds = new Set<id>();
            this.Entities = new List<VouchWrapper>();
            this.Pager.QOrderByAsc('Name', true);
            this.Query();
        }
        
        public void Query(){
            try{
                this.SaveSelection();
                this.Entities = new List<VouchWrapper>();
                
                if(this.IsRelated == true){
                    Set<Id> vouchIds = new Map<id, AggregateResult>([
                        SELECT Trim_Record__c Id 
                        FROM Vouched_Line_Item__c 
                        WHERE Trim_Record__c != null 
                            AND Line_Item__c = :this.lineItem.Id
                            AND Trim_Record__r.Name LIKE :(this.FilterKey.length() > 2 ? '%' : this.FilterKey + '%') 
                        GROUP BY Trim_Record__c
                	]).KeySet();
                    String filter =	'Id IN (\''+ string.Join(new List<Id>(vouchIds), '\',\'') +'\')';
                    if (this.FilterKey == 'Vouching') {
                        filter += ' AND Vouching_Type__c != \'Advertising Material\'';
                    } else if (this.FilterKey == 'Advertising Material') {
                        filter += ' AND Vouching_Type__c = \'Advertising Material\'';
                    }
                    this.Pager.QWhere(filter);
                }
                else{
                    Set<Id> vouchIds = new Map<id, AggregateResult>([
                        SELECT Trim_Record__c Id 
                        FROM Vouched_Line_Item__c 
                        WHERE Trim_Record__c != null 
                            AND Line_Item__c = :this.lineItem.Id
                        GROUP BY Trim_Record__c
                	]).KeySet();
                    String filter = ' Vouching_Item__c = true' +
                        ' AND fuseit_s2t__Parent_ID__c IN (';
                    for (String Id : this.allDisclosureId) {
                        filter += '\'' + Id + '\', ';
                    }
                    filter = filter.subString(0,filter.Length()-2) + ') ';
                    filter += ' AND Name LIKE \'%' + (this.FilterKey.length() > 2 ? '%' : this.FilterKey) + '%\' ' +
                        		' AND Id NOT IN (\''+ string.Join(new List<Id>(vouchIds), '\',\'') +'\') ';
                    if (this.FilterKey == 'Vouching') {
                        filter += ' AND Vouching_Type__c != \'Advertising Material\'';
                    } else if (this.FilterKey == 'Advertising Material') {
                        filter += ' AND Vouching_Type__c = \'Advertising Material\'';
                    }
                    this.Pager.QWhere(filter);
                }
                for(sObject item :this.Pager.ToList()){
                    VouchWrapper temp = new VouchWrapper((fuseit_s2t__Trim_Record__c)item);
                    if(this.ListSelectedVouchIds.Contains(temp.Item.Id)){
                        temp.IsSelected = true;
                    }
                    this.Entities.Add(temp);
                }
            }
            catch(Exception ex){
                ApexPages.AddMessages(ex);
            }
        }
        
        public void Sort(){
            string orderBy = ApexPages.CurrentPage().GetParameters().Get('sortByColumn');
            string orderDirection = ApexPages.CurrentPage().GetParameters().Get('sortDirection');
            this.Pager.QOrderBy(orderBy, orderDirection, true);
            this.Query();
        }
        
        public void AddRemoveVouching(){
            this.SaveSelection();
            if(this.IsRelated){//remove
                delete [SELECT Id FROM Vouched_Line_Item__c WHERE Line_Item__c = :this.LineItem.Id AND Trim_Record__c IN :this.ListSelectedVouchIds];
            }
            else{
                List<Vouched_Line_Item__c> insertList = new List<Vouched_Line_Item__c>();
                for(string vouchId :this.ListSelectedVouchIds){
                    insertList.Add(new Vouched_Line_Item__c(Line_Item__c = this.lineItem.Id, Trim_Record__c = vouchId)) ;
                }
                insert insertList;
            }
            this.Refresh();
        }
        
        public void SaveSelection(){
            for(VouchWrapper item :this.Entities){
                if(item.IsSelected){
                    this.ListSelectedVouchIds.Add(item.Item.Id);
                }
                else{
                    this.ListSelectedVouchIds.Remove(item.Item.Id);
                }
            }
        }
    }
    
    public class VouchWrapper{
        public fuseit_s2t__Trim_Record__c Item{get;set;}
        public boolean IsSelected{get;set;}
        public VouchWrapper(fuseit_s2t__Trim_Record__c entity){
            this.Item = entity;
            this.IsSelected = false;
        }
    }
}