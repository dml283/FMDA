/* used for searching, creating / updating Stakeholder (Person) records.
*/
public class PersonSearchController{
    public string Keyword{get;set;}
    public boolean IsPostBack{get;set;}
    public boolean IsFadmsSkip{get;set;}
    public boolean NoMatches{get{ return this.Accounts.IsEmpty(); }}
    public List<Account> Accounts{get;set;}
    public Account Account{get;set;}
    public Account AccountElectoral{get;set;}
    //public Address__c Address{get;set;}
    public PagingInfo AccountPagingInfo{get;set;}
    public Contact PersonContact{get;set;}
    public Contact PersonContactElectoral{get;set;}
    public transient string StartUpScript{get;set;}
    public string messageOnPersonCreateUpdate{get;set;}
    public Map<String, Boolean> CriteriaSelection{get;set;}
    //public Map<String, Boolean> AddressCriteriaSelection{get;set;}
    public Map<String, String> SortExpressions{get;set;}
    
    private boolean isStakeFoundOnFADMS;
    private final String STAKE_EXIST_FADMS = 'Stakeholder already exists in FADMS, when you click \'Save\' the Stakeholder will be updated';
    private final String STAKE_NOT_EXIST_FADMS = 'Stakeholder does not currently exist in FADMS, when you click \'Save\' the Stakeholder will be created';
    public string electoralWebServiceURL {get{
    		return Webservice_URL__c.getValues('Electoral Roll').URL__c;
    	}
    }
    public string QueryString{get{
        string temp = '?isdtp=vw';
        for(string key :new string[]{'fid','currentid'}){
        	if(ApexPages.CurrentPage().GetParameters().ContainsKey(key)){
        		temp += '&' + key + '=' + ApexPages.CurrentPage().GetParameters().Get(key);
        	}
        }
        return temp;
    }}
    public boolean isFADMS{get;set;}
    public List<Selectoption> ElectoralTypeOptions{get;set;}
    public String ElectoralType{get;set;}
    public string FieldId{get;set;}
    public string JsonElectoralRoll{get;set;}
    public ElectoralRollWrapper ElectoralRoll{get{return (ElectoralRollWrapper)Json.Deserialize(this.JsonElectoralRoll, ElectoralRollWrapper.Class );}} 
    
    public string EventId{get;set;}
    public string fId{get;set;}
    
    public class ElectoralRollWrapper{
        public string FadmsElectorId{get;set;}
        public string ElectorSalutation{get;set;}
        public string ElectorGivenNames{get;set;}
        public string ElectorFamilyName{get;set;}
        public string ElectorDob{get;set;}
        public string ElectorOccupation{get;set;}
        public string ElectorSilent{get;set;}
        public string EnrolledAddress{get;set;}
        public string EnrolledLocality{get;set;}
        public string EnrolledPostcode{get;set;}
    }
    
    public PersonSearchController(){
        if(this.IsPostBack == null){
            this.StartUpScript = null;
            this.Accounts = new List<Account>();
            this.Keyword = ApexPages.CurrentPage().GetParameters().Get('key');
            
            this.Keyword = ApexPages.CurrentPage().GetParameters().Get('key');
            
            this.isFADMS = true;
            this.isStakeFoundOnFADMS = false;
            this.JsonElectoralRoll = '{}';
            this.messageOnPersonCreateUpdate = '';
            ElectoralTypeOptions = new List<Selectoption>();
            ElectoralTypeOptions.add(new SelectOption('NSW', 'NSW'));
            ElectoralTypeOptions.add(new SelectOption('AU', 'AU'));
            ElectoralType = 'NSW';
            if(ApexPages.CurrentPage().GetParameters().ContainsKey('currentid')){
            	this.Account = [
            		SELECT PersonContactId , Id,FADMS_Elector_ID__c,PersonBirthdate, PersonMailingStreet, PersonMailingCity, PersonMailingPostalCode
            		FROM Account
            		WHERE Id = :ApexPages.CurrentPage().GetParameters().Get('currentid')
            		LIMIT 1
            	];
            	this.PersonContact = [
            		SELECT Salutation, FirstName, LastName
            		FROM Contact
            		WHERE Id = :this.Account.PersonContactId
            		LIMIT 1
            	];
            }
            else{
	            RecordType accountType = [SELECT Id FROM RecordType WHERE Name = 'Person' AND SobjectType='Account' LIMIT 1];
	            this.Account = new Account(RecordTypeId = accountType.Id);
            	this.PersonContact = new Contact();
            }
            this.FieldId = ApexPages.CurrentPage().GetParameters().Get('fid');
            if (FieldId != null) {
               FieldId  = FieldId.Replace(':','\\:');
            }
            
            this.EventId = ApexPages.CurrentPage().GetParameters().Get('eid');
            this.fId = ApexPages.CurrentPage().GetParameters().Get('fid');
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Event: ' + this.EventId));
            
            this.InitCriteriaSelection();
            this.InitSortExpressions();
            // For US4813
            if (ApexPages.CurrentPage().GetParameters().ContainsKey('skipFADMS')) {
                //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, 'Firts'));
                IsFadmsSkip = true;
                ApexPages.CurrentPage().GetParameters().Put('accountIdToFill',ApexPages.CurrentPage().GetParameters().Get('currentid') );
                this.FillElectoralSearchParam();
                //this.Account = Acc.Clone(false,true);
            	//this.PersonContact = PersonCon.Clone(false,true);
            } else {
                IsFadmsSkip = false;
                this.SearchFADMS();
            }
            
            // End US4813
            this.IsPostBack = true;
        }
    }
    
    public void InitCriteriaSelection(){
        this.CriteriaSelection = new Map<String, Boolean>();
        this.CriteriaSelection.Put('Salutation', false);
        this.CriteriaSelection.Put('FirstName', false);
        this.CriteriaSelection.Put('LastName', false);
        this.CriteriaSelection.Put('PersonBirthdate', false);
        this.CriteriaSelection.Put('FADMS_Elector_ID__c', false);
        
        this.CriteriaSelection.Put('PersonMailingStreet', false);
        this.CriteriaSelection.Put('PersonMailingCity', false);
        this.CriteriaSelection.Put('PersonMailingPostalCode', false);/*
        this.AddressCriteriaSelection = new Map<String, Boolean>();
        this.AddressCriteriaSelection.Put('Address_Line_1__c', false);
        this.AddressCriteriaSelection.Put('Address_Line_2__c', false);
        this.AddressCriteriaSelection.Put('State__c', false);
        this.AddressCriteriaSelection.Put('Postcode__c', false);
*/
    }
    
    public void InitSortExpressions(){
        this.SortExpressions = new Map<String, String>();
        for(Schema.FieldSetMember field :Schema.SObjectType.Account.fieldSets.Person.Fields){
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
                if (isFADMS) {
                	this.SearchFADMS();
                }
            }
        }
        catch(Exception ex){
            ApexPages.AddMessages(ex);
        }
    }
    
    private void setFilterValue() {
        for(string key: this.CriteriaSelection.KeySet()){
            //if (key.equalsIgnoreCase('PersonBirthdate')) {
              //  String str = String.Value
            //} else {
                String str = String.ValueOf(this.Account.Get(key));
            //}
            if(str!=null && String.isNotEmpty(str) && (str).Trim().length()>0) {
                this.CriteriaSelection.put(key, true);
           	}else{
                this.CriteriaSelection.put(key, false);
            }
        }
    }
    
    public void SearchFADMS(){
        this.Acc = null;
        this.PersonCon = null;
        this.Account.Salutation = this.PersonContact.Salutation;
        this.Account.FirstName = this.PersonContact.FirstName;
        this.Account.LastName = this.PersonContact.LastName;
        string filter = ' FROM Account WHERE IsPersonAccount = true';
        string sorter = ' ORDER BY IsPersonAccount';
        this.setFilterValue();
        
        for(string key: this.SortExpressions.KeySet()){
            if(this.SortExpressions.Get(key) != 'null'){
                sorter += ', ' + key + ' ' + this.SortExpressions.Get(key);
            }
        }
        
        for(string key: this.CriteriaSelection.KeySet()){
            if(this.CriteriaSelection.Get(key)){
            	String str = String.ValueOf(this.Account.Get(key));
                if (key.equalsIgnoreCase('PersonBirthdate')) {
                    //str = str.mid(6,4) + '-' + str.mid(3,2) + '-' + str.mid(0,2);
                    filter += ' AND '+key+' = '+str.left(10)+' ';
                }
                else{
                	filter += ' AND '+key+' LIKE \'%'+String.escapeSingleQuotes(str)+'%\' ';
                }
            }
        }
        
        if(this.EventId != NULL){
            Set<Id> accountIds = new Map<Id, AggregateResult>([SELECT Stakeholder__c Id FROM Registration__c 
                                                               WHERE Election_Event1__c =: this.EventId
                                                               GROUP BY Stakeholder__c]).keyset();
            filter += ' AND Id IN (\'' + String.Join(new List<Id>(accountIds), '\',\'') + '\') ';
        }
        //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Filter: ' + filter));
        
        List<string> fields = new List<string>();
        for(Schema.FieldSetMember field :Schema.SObjectType.Account.fieldSets.Person.Fields){
            fields.Add(field.FieldPath);
        }
        string query = ' SELECT ' + string.Join(fields, ',') + filter + sorter;
        string countQuery = 'SELECT count() ' + filter;
        //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'query: ' + query));
        try{
            this.AccountPagingInfo = new PagingInfo('AccountPagingInfo', query, countQuery);
            this.Accounts = this.AccountPagingInfo.GetRecords();
        }
        catch(Exception ex){
            ApexPages.AddMessages(ex);
        }
    }
    
    public void Clear() {
        RecordType accountType = [SELECT Id FROM RecordType WHERE Name = 'Person' AND SobjectType='Account' LIMIT 1];
        if (this.isFADMS) {
            this.Account = new Account(RecordTypeId = accountType.Id);
            this.PersonContact = new Contact();
            this.InitCriteriaSelection();
            this.InitSortExpressions();
            this.SearchFADMS();
        } else {
            this.AccountElectoral = new Account(RecordTypeId = accountType.Id);
            this.PersonContactElectoral = new Contact();
        }
    }
    
    public void SwitchSearchType() {
        if (this.isFADMS) {
            // Initialize Account and PersonContact of Electoral
            // RecordType accountType = [SELECT Id FROM RecordType WHERE Name = 'Person' AND SobjectType='Account' LIMIT 1];
            this.AccountElectoral = Account.Clone(false,true);
            this.PersonContactElectoral = PersonContact.Clone(false,true);
            this.Acc = Account.Clone(false,true);
            this.PersonCon = PersonContact.Clone(false,true);
        }
        //this.messageOnPersonCreateUpdate = 'Stakeholder does not currently exist in FADMS, when you click \'Save\' the Stakeholder will be created';
        this.isFADMS = !this.isFADMS;
        this.isStakeFoundOnFADMS = false;
    }
    
    public void FillElectoralSearchParam() {
        Id accountIdToFill = ApexPages.CurrentPage().GetParameters().Get('accountIdToFill');
        this.Acc = [
            SELECT PersonContactId , Id,FADMS_Elector_ID__c,PersonBirthdate, Salutation,FirstName,LastName,
            		Phone, PersonMobilePhone, Description,Occupation__c,Fax,PersonEmail,Electoral_Roll_Name__c,
            		PersonMailingCity ,PersonMailingCountry, PersonMailingPostalCode, PersonMailingState, PersonMailingStreet,
					PersonOtherCity, PersonOtherCountry, PersonOtherPostalCode, PersonOtherState, PersonOtherStreet,
					ShippingCity, ShippingCountry, ShippingPostalCode, ShippingState, ShippingStreet
            FROM Account 
            WHERE Id = :accountIdToFill
        ];
        //this.messageOnPersonCreateUpdate = 'Stakeholder already exists in FADMS, when you click \'Save\' the Stakeholder will be updated';
        this.PersonCon = new Contact(FirstName = this.Acc.FirstName, LastName = this.Acc.LastName, Salutation = this.Acc.Salutation);
        this.AccountElectoral = this.Acc.Clone(false,true);
        this.PersonContactElectoral = new Contact(Salutation = this.AccountElectoral.Salutation, FirstName = this.AccountElectoral.FirstName, LastName = this.AccountElectoral.LastName);
        this.isFADMS = false;
		this.isStakeFoundOnFADMS = true;
        // Search for Electoral Roll        
    }
    
    public PageReference SelectElectoralRoll(){
        //this.Account.FADMS_Elector_ID__c = this.ElectoralRoll.Id;
        // When found on Electoral but not found on FADMS, Select stakeholders with FadmsElectorId match
        if (!this.isStakeFoundOnFADMS) {
            List<Account> AccList = [
                SELECT PersonContactId , Id,FADMS_Elector_ID__c,PersonBirthdate, Salutation,FirstName,LastName,
                        Phone, PersonMobilePhone, Description,Occupation__c,Fax,PersonEmail,Electoral_Roll_Name__c,
                        PersonMailingCity ,PersonMailingCountry, PersonMailingPostalCode, PersonMailingState, PersonMailingStreet,
                        PersonOtherCity, PersonOtherCountry, PersonOtherPostalCode, PersonOtherState, PersonOtherStreet,
                        ShippingCity, ShippingCountry, ShippingPostalCode, ShippingState, ShippingStreet
                FROM Account 
                WHERE FADMS_Elector_ID__c = :this.ElectoralRoll.FadmsElectorId
            ];
            if(AccList.size() == 0){
            	// Not found on FADMS and found on Electoral but there's no user on FADMS have FadmsElectorId match with found record
                this.Acc = AccountElectoral.Clone(false,true);
                this.PersonCon = PersonContactElectoral.Clone(false,true);
                this.Acc.FADMS_Elector_ID__c = this.ElectoralRoll.FadmsElectorId;
                this.messageOnPersonCreateUpdate = this.STAKE_NOT_EXIST_FADMS ;
            } else {
            	//Not found on FADMS and found on Electoral, load user on FADMS have FadmsElectorId match with found record
            	this.Acc = AccList.get(0);
                this.PersonCon = new Contact(FirstName = this.Acc.FirstName, LastName = this.Acc.LastName, Salutation = this.Acc.Salutation);
                this.messageOnPersonCreateUpdate = this.STAKE_EXIST_FADMS;
            }
        } else {
            // Found on FADMS and found on Electoral
            if (this.Acc.FADMS_Elector_ID__c == null) {
            	this.Acc.FADMS_Elector_ID__c = this.ElectoralRoll.FadmsElectorId;
            } else if(this.Acc.FADMS_Elector_ID__c != this.ElectoralRoll.FadmsElectorId) {
            	this.StartUpScript = 'alert(\'The Stakeholders selected in the FADMS and Electoral Roll searches have different FADMS Elector ID\\\'s. Please select matching records to update\')';
                return null;
            }
            this.messageOnPersonCreateUpdate = this.STAKE_EXIST_FADMS;
        }
        return Page.PersonCreateUpdate;
    }
    
    public PageReference NotOnElectoralRoll(){
        if(this.Acc == null){
            this.Acc = AccountElectoral.Clone(false,true);
            this.PersonCon = PersonContactElectoral.Clone(false,true);
        }
        JsonElectoralRoll = '{}';
        this.messageOnPersonCreateUpdate = (this.isStakeFoundOnFADMS ? this.STAKE_EXIST_FADMS : this.STAKE_NOT_EXIST_FADMS);
        
        return Page.PersonCreateUpdate;
    } 
    
    public void CopyErToStakeholder(){
        ElectoralRollWrapper temp = this.ElectoralRoll;
        this.PersonCon.Salutation = temp.ElectorSalutation;
        this.PersonCon.FirstName = temp.ElectorGivenNames;
        this.PersonCon.LastName = temp.ElectorFamilyName;
        if(string.IsNotEmpty(temp.ElectorDob)){
            this.Acc.PersonBirthdate = Date.NewInstance(integer.ValueOf(temp.ElectorDob.Left(4)),integer.ValueOf(temp.ElectorDob.Mid(4,2)) ,integer.ValueOf(temp.ElectorDob.Right(2)) );
        }
        this.Acc.Occupation__c = temp.ElectorOccupation;
        this.Acc.PersonMailingStreet = temp.EnrolledAddress;
        this.Acc.PersonMailingCity = temp.EnrolledLocality;
        this.Acc.PersonMailingPostalCode = temp.EnrolledPostcode;
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
    public Contact PersonCon{get;set;}
    /*
    public PageReference CreateStakeHolder(){
        this.Acc = this.Account.Clone(false, true);
        this.PersonCon = this.PersonContact.Clone(false, true);
        this.Acc.FADMS_Elector_ID__c = this.ElectoralRoll.Id;
        
        return Page.PersonCreateUpdate;
    }
    
    public PageReference UpdateStakeHolder(){
        Id accountToUpdate = ApexPages.CurrentPage().GetParameters().Get('accountIdToUpdate');
        this.Acc = [
            SELECT Id, Salutation,FirstName,LastName, Phone,PersonBirthdate,PersonMobilePhone,Description,PersonTitle,Fax,PersonEmail,Last_Queried_Date_Time__c,SPID__c,FADMS_Elector_ID__c, //Electoral_Roll_ID__c,
            		PersonMailingCity ,PersonMailingCountry, PersonMailingPostalCode, PersonMailingState, PersonMailingStreet,
					PersonOtherCity, PersonOtherCountry, PersonOtherPostalCode, PersonOtherState, PersonOtherStreet,
					ShippingCity, ShippingCountry, ShippingPostalCode, ShippingState, ShippingStreet
            FROM Account 
            WHERE Id = :accountToUpdate
        ];
        this.PersonCon = new Contact(Salutation = this.Acc.Salutation, FirstName = this.Acc.FirstName, LastName = this.Acc.LastName);
        return Page.PersonCreateUpdate;
    }
    */
    public void SaveAccountAndClose(){
        if(this.SaveAccount()){
            this.StartUpScript += 'top.window.close()';
        }
    }
    
    public void QuickSaveAccount(){
        this.SaveAccount();
    }
    
    public boolean SaveAccount(){
        this.Acc.Salutation = this.PersonCon.Salutation;
        this.Acc.FirstName = this.PersonCon.FirstName;
        this.Acc.LastName = this.PersonCon.LastName;
        // Create save Point
        Savepoint sp = Database.setSavepoint();
        try {
        	upsert this.Acc;
			string name = [Select Id,Name From Account Where Id =:Acc.Id LIMIT 1].Name;
            // For US4813
            if (isFadmsSkip) {
                this.StartUpScript = '';
                //this.StartUpScript = 'top.window.opener.location.reload();';
                //this.StartUpScript += 'top.window.opener.location.href = top.window.opener.location.href;';
                //this.StartUpScript += 'top.window.close();';
            } else {
				this.StartUpScript = 'top.window.opener.pickCustomLookup("'+ApexPages.CurrentPage().GetParameters().Get('fid')+'","'+this.Acc.Id+'","'+String.escapeSingleQuotes(name)+'"); ';
				string comeFrom = ApexPages.CurrentPage().GetParameters().Get('fromLIForm');
				if(comeFrom == 'true'){
                    //Account obj = [Select Id,PersonMailingStreet,PersonMailingCity,PersonMailingState
                    //               From Account Where Id =:Acc.Id LIMIT 1];
					//string strAddress = this.Acc.PersonMailingStreet == null ? '' : this.Acc.PersonMailingStreet + ', ' +
	            	//				this.Acc.PersonMailingCity == null ? '' : this.Acc.PersonMailingCity + ', ' +
	            	//				this.Acc.PersonMailingState == null ? '' : this.Acc.PersonMailingState;
	            					string strAddress = '';
	            					if(this.Acc.PersonMailingStreet != null)
	            						 strAddress += this.Acc.PersonMailingStreet + ' ';
            						 if(this.Acc.PersonMailingCity != null)
	            						 strAddress += this.Acc.PersonMailingCity + ' ';
            						 if(this.Acc.PersonMailingState != null)
	            						 strAddress += this.Acc.PersonMailingState;	            					
		            this.StartUpScript += 'top.window.opener.FillAddress("'+this.FieldId+'","'+ strAddress + '");';
						//this.StartUpScript += 'top.window.opener.FillAddress("'+ApexPages.CurrentPage().GetParameters().Get('fid')+'","'+ this.Acc.PersonMailingStreet + ', '
		             	//+ this.Acc.PersonMailingCity + ', ' + this.Acc.PersonMailingState +'");';
				}
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
        return Page.PersonSearch;
    }
}