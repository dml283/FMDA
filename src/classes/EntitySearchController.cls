/* used for searching, creating/updating Stakeholder (Entity) records
*/
public class EntitySearchController{
    public string Keyword{get;set;}
    public boolean IsPostBack{get;set;}
    public boolean NoMatches{get{ return this.Accounts.IsEmpty(); }}
    public List<Account> Accounts{get;set;}
    public Account Account{get;set;}
    //public Address__c Address{get;set;}
    public PagingInfo AccountPagingInfo{get;set;}
    //public Contact PersonContact{get;set;}
    public string StartUpScript{get;set;}
    public Map<String, Boolean> CriteriaSelection{get;set;}
    //public Map<String, Boolean> AddressCriteriaSelection{get;set;}
    public Map<String, String> SortExpressions{get;set;}
    public string QueryString{get{
        string temp = '?isdtp=vw';
        for(string key :new string[]{'fid','currentid'}){
            if(ApexPages.CurrentPage().GetParameters().ContainsKey(key)){
                temp += '&' + key + '=' + ApexPages.CurrentPage().GetParameters().Get(key);
            }
        }
        return temp;
    }}
    
    public string FieldId{get;set;}
    
    public EntitySearchController(){
        if(this.IsPostBack == null){
            this.StartUpScript = null;
            this.Accounts = new List<Account>();
            this.Keyword = ApexPages.CurrentPage().GetParameters().Get('key');
            if(ApexPages.CurrentPage().GetParameters().ContainsKey('currentid')){
                this.Account = [
                    SELECT isPersonAccount,Email__c, Id, Name, Phone, ABN_ACN_Other__c, Fax
                    , BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry
                    , ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry
                    FROM Account
                    WHERE Id = :ApexPages.CurrentPage().GetParameters().Get('currentid')
                    LIMIT 1
                ];
            }
            else{
                RecordType accountType = [SELECT Id FROM RecordType WHERE Name = 'Entity' AND SobjectType='Account' LIMIT 1];
                this.Account = new Account(RecordTypeId = accountType.Id);
            }
            this.FieldId = ApexPages.CurrentPage().GetParameters().Get('fid').Replace(':','\\:');
            this.InitCriteriaSelection();
            this.InitSortExpressions();
            this.Search();
            
            this.IsPostBack = true;
        }
    }
    
    public void InitCriteriaSelection(){ 
        this.CriteriaSelection = new Map<String, Boolean>();
        this.CriteriaSelection.Put('Name', false);
        this.CriteriaSelection.Put('ABN_ACN_Other__c', false);
        this.CriteriaSelection.Put('Phone', false);
        this.CriteriaSelection.Put('Fax', false);
        this.CriteriaSelection.Put('BillingStreet', false);
        this.CriteriaSelection.Put('BillingCity', false);
        this.CriteriaSelection.Put('BillingState', false);
        this.CriteriaSelection.Put('BillingPostalCode', false);
        this.CriteriaSelection.Put('BillingCountry', false);
        this.CriteriaSelection.Put('ShippingStreet', false);
        this.CriteriaSelection.Put('ShippingCity', false);
        this.CriteriaSelection.Put('ShippingState', false);
        this.CriteriaSelection.Put('ShippingPostalCode', false);
        this.CriteriaSelection.Put('ShippingCountry', false);
    }
    
    public void InitSortExpressions(){
        this.SortExpressions = new Map<String, String>();
        for(Schema.FieldSetMember field :Schema.SObjectType.Account.fieldSets.Entity.Fields){
            this.SortExpressions.Put(field.FieldPath, 'null');
        }
    }
    
    public void Sort(){
        try{
            string sortField = ApexPages.CurrentPage().GetParameters().Get('AccountSortingInfo');
            
            if(this.SortExpressions.ContainsKey(sortField)){
                //reset sort field
                for(string key: this.SortExpressions.KeySet()){
                    if(key != sortField){
                        this.SortExpressions.Put(key, 'null');
                    }
                }
                //set sort field
                string sortDirection = this.SortExpressions.Get(sortField);
                if(sortDirection == 'null'){
                    this.SortExpressions.Put(sortField, 'ASC');
                }
                else if(sortDirection == 'ASC'){
                    this.SortExpressions.Put(sortField, 'DESC');
                }
                else if(sortDirection == 'DESC'){
                    this.SortExpressions.Put(sortField, 'null');
                }
                this.Search();
            }
        }
        catch(Exception ex){
            ApexPages.AddMessages(ex);
        }
    }
    
    private void setFilterValue() {
        for(string key: this.CriteriaSelection.KeySet()){
            String str = (string)this.Account.Get(key);
            if(str!=null && String.isNotEmpty(str) && (str).Trim().length()>0) {
                this.CriteriaSelection.put(key, true);
            }else{
                this.CriteriaSelection.put(key, false);
            }
        }
    }
    
    public void Search(){
        
        /*this.Account.Salutation = this.PersonContact.Salutation;
        this.Account.FirstName = this.PersonContact.FirstName;
        this.Account.LastName = this.PersonContact.LastName;*/
        string filter = ' FROM Account WHERE RecordType.Name = \'Entity\'';
        string sorter = ' ORDER BY RecordTypeId';
        this.setFilterValue();
        
        for(string key: this.SortExpressions.KeySet()){
            if(this.SortExpressions.Get(key) != 'null'){
                sorter += ', ' + key + ' ' + this.SortExpressions.Get(key);
            }
        }
        
        for(string key: this.CriteriaSelection.KeySet()){
            if(this.CriteriaSelection.Get(key)){
                filter += ' AND '+key+' LIKE \'%'+ String.escapeSingleQuotes((string)this.Account.Get(key))+'%\' ';
            }
        }
        //Set<Id> accountIds = this.SearchAccFromAdd();
        //filter += ' AND Id IN :accountIds ';
        
        List<string> fields = new List<string>();
        for(Schema.FieldSetMember field :Schema.SObjectType.Account.fieldSets.Entity.Fields){
            fields.Add(field.FieldPath);
        }
        string query = ' SELECT ' + string.Join(fields, ',') + filter + sorter;
        string countQuery = 'SELECT count() ' + filter;
        //ApexPages.AddMessage(new ApexPages.Message(ApexPages.SEVERITY.INFO, query));
        try{
            this.AccountPagingInfo = new PagingInfo('AccountPagingInfo', query, countQuery);
            this.Accounts = this.AccountPagingInfo.GetRecords();
        }
        catch(Exception ex){
            ApexPages.AddMessages(ex);
        }
    }
    
    public void CopyFromOfficialAddress(){
        this.Account.ShippingStreet = this.Account.BillingStreet;
        this.Account.ShippingCity = this.Account.BillingCity;
        this.Account.ShippingState = this.Account.BillingState;
        this.Account.ShippingPostalCode = this.Account.BillingPostalCode;
        this.Account.ShippingCountry = this.Account.BillingCountry;
    }
    
    public void CopyFromOfficialAddress1(){
        this.Acc.ShippingStreet = this.Acc.BillingStreet;
        this.Acc.ShippingCity = this.Acc.BillingCity;
        this.Acc.ShippingState = this.Acc.BillingState;
        this.Acc.ShippingPostalCode = this.Acc.BillingPostalCode;
        this.Acc.ShippingCountry = this.Acc.BillingCountry;
    }
    
    /*
    public Set<Id> SearchAccFromAdd(){
        string addressFilter = 'FROM Address__c WHERE Address_Type__c = \'Electoral Roll Address\' ';
            
        for(string key: this.AddressCriteriaSelection.KeySet()){
            if(this.AddressCriteriaSelection.Get(key)){
                addressFilter += ' AND '+key+' = \''+(string)this.Address.Get(key)+'\' ';
            }
        }
        
        addressFilter += 'GROUP BY Stakeholder__c';
        
        Map<Id, sObject> accountIds = new Map<Id, sObject>(Database.Query('SELECT Stakeholder__c Id ' + addressFilter));

        return accountIds.KeySet();
    }
*/
    // Initialize Address Detail
    public Account Acc{get;set;}
    
    public PageReference CreateStakeHolder(){
        this.Acc = this.Account.Clone(false, true);
        return Page.EntityCreateUpdate;
    }
    
    public PageReference UpdateStakeHolder(){
        Id accountToUpdate = ApexPages.CurrentPage().GetParameters().Get('accountIdToUpdate');
        this.Acc = [
            SELECT Id, Name, Phone,ABN_ACN_Other__c,Fax,Description, isPersonAccount,Email__c,
                        BillingCity, BillingCountry, BillingPostalCode, BillingState, BillingStreet,
                        ShippingCity, ShippingCountry, ShippingPostalCode, ShippingState, ShippingStreet,
                        PersonMailingStreet,PersonMailingCity,PersonMailingState
            FROM Account 
            WHERE Id = :accountToUpdate
        ];
        return Page.EntityCreateUpdate;
    }
    
    public void SaveAccountAndClose(){
        if(this.SaveAccount()){
            this.StartUpScript += 'top.window.close()';
        }
    }
    
    public void QuickSaveAccount(){
        this.SaveAccount();
    }
    
    public boolean SaveAccount(){
        // Create save Point
        Savepoint sp = Database.setSavepoint();
        try {
            upsert this.Acc;
            string name = [Select Id,Name From Account Where Id =:Acc.Id LIMIT 1].Name;
            this.StartUpScript = 'top.window.opener.pickCustomLookup("'+this.FieldId+'","'+this.Acc.Id+'","'+name+'"); ';
            string comeFrom = ApexPages.CurrentPage().GetParameters().Get('fromLIForm');
			if(comeFrom == 'true'){
	            //string strAddress = this.Acc.PersonMailingStreet == null ? '' : this.Acc.PersonMailingStreet + ', ' +
	            //					this.Acc.PersonMailingCity == null ? '' : this.Acc.PersonMailingCity + ', ' +
	            //					this.Acc.PersonMailingState == null ? '' : this.Acc.PersonMailingState;
				string strAddress = '';
	            					if(this.Acc.PersonMailingStreet != null)
	            						 strAddress += this.Acc.PersonMailingStreet + ' ';
            						 if(this.Acc.PersonMailingCity != null)
	            						 strAddress += this.Acc.PersonMailingCity + ' ';
            						 if(this.Acc.PersonMailingState != null)
	            						 strAddress += this.Acc.PersonMailingState;	   
					            					
				System.debug('address: ' + strAddress);	            					
	            this.StartUpScript += 'top.window.opener.FillAddress("'+this.FieldId+'","'+ strAddress + '");';
			}
        } catch (Exception e) {
            Database.rollback(sp);
            ApexPages.addMessages(e);
            return false;
        }
        return true;
    }    
    
    public PageReference Cancel(){
        this.StartUpScript=null;
        return Page.EntitySearch;
    }
}