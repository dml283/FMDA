public class EndorsedStakeholdersController{
    public Eligible_Claim_for_Payment__c Entity{get;set;}
    public List<string> FilterKeys{get{return new List<string>{'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','X','Y','Z', 'All'};}}
    public ListEndorsedRegWrapper RelatedEndorsedList{get;set;}
    public ListEndorsedRegWrapper UnRelatedEndorsedList{get;set;}
    public boolean isNotRequire{get;set;}
    public List<Schema.FieldSetMember> GetFieldSets() {
        if (this.Entity.Public_Fund__c == 'Administration Fund') {
            return SObjectType.Registration__c.FieldSets.Endorsed_Stakeholders_Admin_Fund.getFields();
        } else {
            return SObjectType.Registration__c.FieldSets.Endorsed_Stakeholders_Policy_Dev_Fund.getFields();
        }
    }
    public EndorsedStakeholdersController(ApexPages.StandardController controller){
        try {
            this.Entity = (Eligible_Claim_for_Payment__c)controller.GetRecord();
            this.Entity = this.GetEntityById(this.Entity.Id);
            isNotRequire = false;
            if (this.Entity.Public_Fund__c != 'Administration Fund' && this.Entity.Public_Fund__c != 'Policy Development Fund' ) {
                ApexPages.addMessage(new ApexPages.Message (ApexPages.Severity.INFO,'Endorsed Stakeholders are not required for Claims for Payment from the Elections Campaign Fund'));
                isNotRequire = true;
                return;
            }
            this.InitEndorsedList();
        } catch (Exception e) {
            ApexPages.addMessages(e);
        }
    }
    
    public void InitEndorsedList(){
        this.RelatedEndorsedList = new ListEndorsedRegWrapper(this.Entity, true);	// true -> related
        this.UnRelatedEndorsedList = new ListEndorsedRegWrapper(this.Entity, false);	// false -> unrelated
        this.RelatedEndorsedList.Query();
        this.UnRelatedEndorsedList.Query();
    }
    
    public Eligible_Claim_for_Payment__c GetEntityById(string entityId){
        return [SELECT Id, Name, Public_Fund__c, Election_Event__c,Stakeholder__c
                FROM Eligible_Claim_for_Payment__c
                WHERE Id = :entityId LIMIT 1];
    }
    
    public void btnRemoveEndorsed_OnClick() {
        RelatedEndorsedList.AddRemoveEndorsed();
        UnRelatedEndorsedList.Refresh();
    }
    
    public void btnAddEndorsed_OnClick() {
        UnRelatedEndorsedList.AddRemoveEndorsed();
        RelatedEndorsedList.Refresh();
    }
    
    public class ListEndorsedRegWrapper{
        public boolean IsRelated{get;set;}
        public string FilterKey{get;set;}
        public Eligible_Claim_for_Payment__c ecp{get;set;}
        public PagingInfo Pager{get;set;}
        public List<EndorsedRegWrapper> Entities{get;set;}
        public Set<id> ListSelectedEndorsedRegIds{get;set;}
        public String ColumnSearchIn{get;set;}
        public ListEndorsedRegWrapper(Eligible_Claim_for_Payment__c ecp, boolean isRelated){
            this.ecp = ecp;
            this.IsRelated = isRelated;
            this.FilterKey = 'All';
            this.ListSelectedEndorsedRegIds = new Set<id>();
            this.Entities = new List<EndorsedRegWrapper>();
            
            List<string> fields = new List<string>();
            Schema.FieldSet endorsedFieldSets;
            if (this.ecp.Public_Fund__c == 'Administration Fund') {
                endorsedFieldSets = SObjectType.Registration__c.FieldSets.Endorsed_Stakeholders_Admin_Fund;
            } else {
                endorsedFieldSets = SObjectType.Registration__c.FieldSets.Endorsed_Stakeholders_Policy_Dev_Fund;
            }
            for(Schema.FieldSetMember f : endorsedFieldSets.getFields()){
                if (f.FieldPath == 'Stakeholder__c') {
                    ColumnSearchIn = f.FieldPath;
                }
                fields.Add(f.FieldPath);
            }
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,String.valueof(fields) ));
            if (ColumnSearchIn == null) {
                ColumnSearchIn = fields.get(0);
            }
            this.Pager = new PagingInfo('ListEndorsedRegWrapper')
                .QSelect(fields)
                .QFrom('Registration__c')
                .QOrderByAsc(ColumnSearchIn);
            //this.Pager.PageSize = 2;
        }
        
        public void Refresh(){
            this.ListSelectedEndorsedRegIds = new Set<id>();
            this.Entities = new List<EndorsedRegWrapper>();
            //this.Pager.QOrderByAsc('Name', true);
            this.Query();
        }
        
        public void Query(){
            try{
                this.SaveSelection();
                this.Entities = new List<EndorsedRegWrapper>();
                
                if(this.IsRelated == true){
                    String queryRelated = 'SELECT Id,Registration__c,Confirmed_Endorsement__c FROM Endorsed_Stakeholder__c ' +
                        				+ ' WHERE Eligible_Claim_for_Payment__c = \'' + this.ecp.Id + '\' '
                        				+ qualifySearchColumn(this.ColumnSearchIn,true);
                    
                    // ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, queryRelated));
                    List<Endorsed_Stakeholder__c> tempEliList = Database.query(queryRelated);
                    Set<String> relatedReg = new Set<String>();
                    for (Endorsed_Stakeholder__c elg : tempEliList) {
                        relatedReg.add(elg.Registration__c);
                    }
                    String filter =	'Id IN (\''+ string.Join(new List<String>(relatedReg), '\',\'') +'\')';
                    this.Pager.QWhere(filter);
                }
                else{
                    // Select all Registrations that releated to Eligible claim for payment record
                    Set<String> relatedRegList = new Map<String,AggregateResult>([
                        SELECT Registration__c Id
                        FROM Endorsed_Stakeholder__c
                        WHERE Eligible_Claim_for_Payment__c = :this.ecp.Id
                        GROUP BY Registration__c
                    ]).Keyset();
                    
                    String filter = ' Election_Event1__r.Parent_Election_Event__c = \'' + this.ecp.Election_Event__c + '\' '
                        			+' AND Political_Party__c = \'' + this.ecp.Stakeholder__c + '\' ';
                    if (this.ecp.Public_Fund__c == 'Administration Fund') {
						filter += ' AND RecordType.Name = \'Elected Member\'';
                    } else {
                        filter += ' AND RecordType.Name = \'Candidate\' ';
                    }
                    filter += qualifySearchColumn(this.ColumnSearchIn,false);
                    /*
                    filter += ' AND ' + qualifySearchColumn(this.ColumnSearchIn) + ' LIKE \'' 
                        	 + (this.FilterKey == 'All' ? '%' : this.FilterKey) + '%\' ';*/
                    filter += ' AND Id NOT IN (\''+ string.Join(new List<String>(relatedRegList), '\',\'') +'\') ';
                    this.Pager.QWhere(filter);
                }
                Set<String> RegIdList = new Set<String>();
                for(sObject item :this.Pager.ToList()){
                    EndorsedRegWrapper temp = new EndorsedRegWrapper((Registration__c)item);
                    RegIdList.add(temp.Item.Id);
                    if(this.ListSelectedEndorsedRegIds.Contains(temp.Item.Id)){
                        temp.IsSelected = true;
                    }
                    this.Entities.Add(temp);
                }
                // Render the Confirmed_Endorsement__c column on Related
                if (isRelated) {
                    Set<String> confirmList = new Map<String,AggregateResult>([
                        SELECT Registration__c Id
                        FROM Endorsed_Stakeholder__c
                        WHERE Eligible_Claim_for_Payment__c = :this.ecp.Id
                        AND Registration__c IN :RegIdList
                        AND Confirmed_Endorsement__c = true
                        GROUP BY Registration__c
                    ]).Keyset();
                    for (EndorsedRegWrapper tempW : this.Entities) {
                        if (confirmList.contains(tempW.Item.Id)) {
                            tempW.Confirmed_Endorsement = true;
                        }
                    }
                }
            }
            catch(Exception ex){
                ApexPages.AddMessages(ex);
            }
        }
        
        public void Sort(){
            string orderBy = ApexPages.CurrentPage().GetParameters().Get('sortByColumn');
            string orderDirection = ApexPages.CurrentPage().GetParameters().Get('sortDirection');
            this.ColumnSearchIn = orderBy;
            this.Pager.QOrderBy(orderBy, orderDirection, true);
            this.Query();
        }
        
        public void AddRemoveEndorsed(){
            this.SaveSelection();
            if(this.IsRelated){//remove
                delete [SELECT Id FROM Endorsed_Stakeholder__c WHERE Eligible_Claim_for_Payment__c = :this.ecp.Id AND Registration__c IN :this.ListSelectedEndorsedRegIds];
            }
            else{
                List<Endorsed_Stakeholder__c> insertList = new List<Endorsed_Stakeholder__c>();
                for(string regId :this.ListSelectedEndorsedRegIds){
                    insertList.Add(new Endorsed_Stakeholder__c(Eligible_Claim_for_Payment__c = this.ecp.Id, Registration__c = regId)) ;
                }
                insert insertList;
            }
            this.Refresh();
        }
        
        public void SaveSelection(){
            for(EndorsedRegWrapper item :this.Entities){
                if(item.IsSelected){
                    this.ListSelectedEndorsedRegIds.Add(item.Item.Id);
                }
                else{
                    this.ListSelectedEndorsedRegIds.Remove(item.Item.Id);
                }
            }
        }
        
        public void btnConfirmEndorsed_OnClick() {
            if (this.isRelated) {
            	List<Endorsed_Stakeholder__c> tempList = getEndorsedListByRegIds();
                for (Endorsed_Stakeholder__c temp : tempList) {
                    temp.Confirmed_Endorsement__c = true;
                }
                upsert tempList;
                this.Refresh();
            }
        }
        
        public void btnUnconfirmEndorsed_OnClick() {
            if (this.isRelated) {
            	List<Endorsed_Stakeholder__c> tempList = getEndorsedListByRegIds();
                for (Endorsed_Stakeholder__c temp : tempList) {
                    temp.Confirmed_Endorsement__c = false;
                }
                upsert tempList;
                this.Refresh();
            }
        }
        
        private List<Endorsed_Stakeholder__c> getEndorsedListByRegIds () {
            this.SaveSelection();
            return [SELECT Id, Confirmed_Endorsement__c
                    FROM Endorsed_Stakeholder__c
                    WHERE Eligible_Claim_for_Payment__c = :this.ecp.Id
                    AND Registration__c IN :this.ListSelectedEndorsedRegIds
                    ];
        }
        
        private String qualifySearchColumn(String inField, boolean isRelation) {
            DescribeSObjectResult objDef = Schema.getGlobalDescribe().get('Registration__c').getDescribe();
            Map<String, SObjectField> fields = objDef.fields.getMap();
            DescribeFieldResult field = fields.get(inField).getDescribe();
            String fieldType = String.valueOf(field.getType());
            String retQuery = '';
            String fieldOnQuery = '';
            if (fieldType.equalsIgnoreCase('STRING') || fieldType.equalsIgnoreCase('PICKLIST')
               || fieldType.equalsIgnoreCase('EMAIL') || fieldType.equalsIgnoreCase('MULTIPICKLIST')) {
                fieldOnQuery = inField;
            } else if (fieldType.equalsIgnoreCase('REFERENCE')){
                fieldOnQuery = inField.replace('__c', '__r.Name');
            }
            
            if (!String.isEmpty(fieldOnQuery)) {
                if (isRelation) {
                    fieldOnQuery = ' Registration__r.' + fieldOnQuery;
                }
                retQuery += fieldOnQuery + ' LIKE \'' + (this.FilterKey == 'All' ? '%' : this.FilterKey) + '%\' ';
               
                if (this.FilterKey == 'All') {
                    retQuery += ' OR ' + fieldOnQuery + ' = null ';
                }
                retQuery = ' AND (' + retQuery + ')';
            }
            return retQuery;
        }
    }
    
    public class EndorsedRegWrapper{
        public Registration__c Item{get;set;}
        public boolean IsSelected{get;set;}
        public boolean Confirmed_Endorsement{get;set;}
        public EndorsedRegWrapper(Registration__c entity){
            this.Item = entity;
            this.IsSelected = false;
            this.Confirmed_Endorsement = false;
        }
    }
}