/* used for searching Stakeholder (Political Party) records.
*/
public class PoliticalSearchController{
    public string Keyword{get;set;}
    public List<Account> Accounts{get;set;}
    public Account Account{get;set;}
    public List<AccountWrapper> AccountWrappers{get;set;}
    public PagingInfo AccountPagingInfo{get;set;}
    public string comeFrom{get;set;}
    public string QueryString{get{
        string temp = '?isdtp=vw';
        for(string key :new string[]{'fid','currentid'}){
        	if(ApexPages.CurrentPage().GetParameters().ContainsKey(key)){
        		temp += '&' + key + '=' + ApexPages.CurrentPage().GetParameters().Get(key);
        	}
        }
        return temp;
    }}
    
    public PoliticalSearchController(){
        this.Accounts = new List<Account>();
       
       this.comeFrom = ApexPages.CurrentPage().GetParameters().Get('fromLIForm');
        this.InitAccount();
        this.Search();
        //this.AccountWrappers = buildAccountWrapper(this.Accounts);
        
    }
    
    public void InitAccount(){
        //init account record
        if(ApexPages.CurrentPage().GetParameters().ContainsKey('currentid')){
            this.Account = [
                SELECT isPersonAccount, Id, Name, Phone, ABN_ACN_Other__c, Fax, BillingStreet, BillingCity, BillingState, BillingPostalCode,
                PersonMailingStreet,PersonMailingCity,PersonMailingState
                FROM Account
                WHERE Id = :ApexPages.CurrentPage().GetParameters().Get('currentid')
                LIMIT 1
            ];
        }
        else{
            RecordType accountType = [SELECT Id FROM RecordType WHERE Name = 'Political Party' AND SobjectType='Account' LIMIT 1];
            this.Account = new Account(RecordTypeId = accountType.Id);
        }
    }
    
    public void Sort(){
        try{
            this.Accounts = this.AccountPagingInfo.GetRecords();
        }
        catch(Exception ex){
            ApexPages.AddMessages(ex);
        }
    }
    
    public void Search(){ 
        try{
            //init account paging info
            
            string filter = ' FROM Account WHERE RecordType.Name = \'Political Party\'';
            
            for(string key: new string[]{'Name'}){
                if(string.IsNotEmpty((string)this.Account.Get(key))){
                    filter += ' AND '+key+' LIKE \'%'+String.escapeSingleQuotes((string)this.Account.Get(key))+'%\' ';
                }
            }
            List<string> fields = new List<string>();
            for(Schema.FieldSetMember field :Schema.SObjectType.Account.fieldSets.Political_Party.Fields){
                fields.Add(field.FieldPath);
            }
            
            //US5309
            //string query = ' SELECT ' + string.Join(fields, ',') + filter;
            string query = ' SELECT ' + string.Join(fields, ',') + ', PersonMailingStreet,PersonMailingCity,PersonMailingState ' + filter;
            
            string countQuery = 'SELECT count() ' + filter;
            
            //this.AccountPagingInfo = new PagingInfo('AccountPagingInfo', query, countQuery);
            this.AccountPagingInfo = new PagingInfo('AccountPagingInfo', query, countQuery, 'Name', 'ASC');
            this.Accounts = this.AccountPagingInfo.GetRecords();
            
            this.AccountWrappers = buildAccountWrapper(this.Accounts);
        }
        catch(Exception ex){
            ApexPages.AddMessages(ex);
        }
    }
    private List<AccountWrapper> buildAccountWrapper (List<Account> accounts) {
    	List<AccountWrapper> temp = new List<AccountWrapper>();
    	for(Account acc : accounts){
    		string PersonMailingStreet = '';
    		if(acc.PersonMailingStreet == null) {
    			PersonMailingStreet = acc.PersonMailingStreet + ' ';
    		}
        	string PersonMailingCity = '';
        	if(acc.PersonMailingCity == null) {
        		PersonMailingCity = acc.PersonMailingCity + ' ';
        	}
        	string PersonMailingState = '';
        	if(acc.PersonMailingState == null) {
        		PersonMailingState = acc.PersonMailingState;
        	}
        	string strAddress = PersonMailingStreet + PersonMailingCity + PersonMailingState;
        	AccountWrapper obj = new AccountWrapper(acc,strAddress);
        	temp.Add(obj);
    	}
    	return temp;
    }
    public class AccountWrapper{        
        public Account Item{get;set;}
        public string strAddress{get;set;}
        
        public AccountWrapper(Account acc, string strAdd){
            this.Item = acc;
            this.strAddress = strAdd;
        }
    }
}