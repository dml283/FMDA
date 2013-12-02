/* used for creating and updating Official Agent Appointment records against a Registration
*/
public with sharing class OfficialAgentAppointmentController {
    public Map<String, Static_Label__c> Labels{get;set;}
	public Official_Agent_Appointment__c Entity{get;set;}
    public Registration__c Registration{get;set;}
    public Account OfficialAgent{get;set;}
    
	public List<Official_Agent_Appointment__c> ListEntity{get;set;}
    public string ListEntitySortColumn{get;set;}
    public string ListEntitySortDirection{get;set;}
    
    public string InlineEntityId{get;set;}
	
	public boolean IsStakeholder{get;set;}
	public boolean IsHeadCandidate{get;set;}
	public boolean IsPartyAgent{get;set;}
    public boolean IsOfficialAct{get;set;}
    
    public boolean IsStakeholderAct{get;set;}
	public boolean IsHeadCandidateAct{get;set;}
	public boolean IsPartyAgentAct{get;set;}
    //this is to work-around a weird issue on VF page that cannot reference Political_Party__r.Party_Agent__r.Name
    public string PartyAgentName{get{ return this.Registration.Political_Party__r.Party_Agent__r.Name; }}
    
    public string StartUpScript{get;set;}
    public boolean IsPostBack{get;set;}
    
	public OfficialAgentAppointmentController(ApexPages.StandardController sc){
        if(this.IsPostBack != true){
            this.Entity = (Official_Agent_Appointment__c)sc.GetRecord();
            this.Entity.Registration__c = ApexPages.CurrentPage().GetParameters().Get('regid');
            this.Labels = Static_Label__c.GetAll();
            this.IsStakeholder = this.IsHeadCandidate = this.IsPartyAgent = false;
            this.IsOfficialAct = false;
            
            this.Entity = this.GetEntityById(this.Entity.Id);
            this.Registration = this.GetRegistrationById(this.Entity.Registration__c);
            System.debug('value of Registration constructor: ' + Registration.Stakeholder__r.RecordType.Name + ', ' + Registration.Stakeholder__c + ', '+ Registration.Authorised_Person__c);
            //set value for this.IsStakeholder, this.IsHeadCandidate, this.IsPartyAgent
            setValueForCheckbox(this.Registration);  
            
            System.Debug('test2: ' + this.Entity.Official_Agent__c);
            this.OfficialAgent = this.GetAccountById(this.Entity.Official_Agent__c);
            System.Debug('test3: ' + this.OfficialAgent);
            this.ListEntity = this.GetEntitiesByRegId(this.Entity.Registration__c, 'Name', 'ASC');
            if(this.ListEntity.IsEmpty()){
                this.Entity.Status__C = 'Active';
            }
            this.IsPostBack = true;            
        }
	}
    /*
    private void setValueForCheckbox(Registration__c reg) {
        if (reg.RecordType.Name == 'Candidate' && reg.Political_Party__c != null){
            this.IsPartyAgentAct = true;
        } else if (reg.RecordType.Name == 'Candidate' && reg.Political_Party__c == null){
            this.IsStakeholderAct = true;
        }
        if (reg.RecordType.Name == 'Group of Candidates' && reg.Political_Party__c != null){
            this.IsPartyAgentAct = true;
        } else if (reg.RecordType.Name == 'Group of Candidates' && reg.Political_Party__c == null){
            this.IsHeadCandidateAct = true;
        }
        if (reg.RecordType.Name == 'Third-Party Campaigner'){
            this.IsStakeholderAct = true;
        }
        if (reg.RecordType.Name == 'Elected Member' && reg.Political_Party__c != null){
            this.IsPartyAgentAct = true;
        } else if (reg.RecordType.Name == 'Elected Member' && reg.Political_Party__c == null){
            this.IsStakeholderAct = true;
        } 
    }
     */   
    private void setValueForCheckbox(Registration__c reg) {
        //For DE4425
        if(((reg.RecordType.Name == 'Candidate' || reg.RecordType.Name == 'Elected Member') && reg.Political_Party__c == null) 
           || reg.RecordType.Name == 'Third-Party Campaigner'){
            this.IsStakeholderAct = true;
        } else if(reg.RecordType.Name == 'Group of Candidates' && reg.Political_Party__c == null){
            this.IsHeadCandidateAct = true;
        }
        
        /*
        if(reg.Political_Party__c == null || reg.Election_Event__r == null){
            return;
        }*/       
        else if((reg.RecordType.Name == 'Candidate' || reg.RecordType.Name == 'Elected Member') && reg.Election_Event1__r.RecordType.Name == 'Local Government Election Event'){
            this.IsStakeholderAct = true;
        }
        else if(reg.RecordType.Name == 'Group of Candidates' && reg.Election_Event1__r.RecordType.Name == 'Local Government Election Event'){
            this.IsHeadCandidateAct = true;
        }
        else if(reg.Election_Event1__r.RecordType.Name == 'State Election Event'){
            this.IsPartyAgentAct = true;
        }
    }
    
    public Account GetAccountById(string id){
        List<Account> results = [
			SELECT Id, Training_Status__c,Online_Training_Status__c,Online_Training_Completed_Date_Time__c,FADMS_Elector_ID__c 
				,CPA_Membership_Number__c,ICAA_Membership_Number__c,IPA_Membership_Number__c, Online_Training_Attempt_Count__c
			FROM Account 
			WHERE Id = :id 
			LIMIT 1 
		];
		if(results.IsEmpty()){
			return null;
		}
		else{
			return results[0];
		}
    }
    
    public Registration__c GetRegistrationById(string id){
        List<Registration__c> results = [
			SELECT Id, Official_Agent__c, RecordTypeId, RecordType.Name
            	, Stakeholder__c, Stakeholder__r.Name, Stakeholder__r.RecordType.Name
            	, Authorised_Person__c, Authorised_Person__r.Name
            	//, Political_Party__c,Political_Party__r.Name
            	, Political_Party__r.Party_Agent__c, Political_Party__r.Party_Agent__r.Name
            	, Election_Event1__c, Election_Event1__r.RecordType.Name
			FROM Registration__c 
			WHERE Id = :id 
			LIMIT 1
		];
		if(results.IsEmpty()){
			return null;
		}
		else{
			return results[0];
		}
    }
	
	public Official_Agent_Appointment__c GetEntityById(string entityId){
		List<Official_Agent_Appointment__c> results = [
			SELECT Id, Name, Official_Agent__c, Status__c, Date_From__c, Date_To__c, Registration__c
				,Confirm_Signed_By_Official_Agent__c,Date_Signed_By_Official_Agent__c,Received_By__c
				,Confirm_Signed_By_Stakeholder__c,Date_Signed_By_Stakeholder__c,Date_Received__c
				,Confirm_Signed_By_Party_Agent__c,Date_Signed_By_Party_Agent__c
				,Official_Agent__r.Id,Official_Agent__r.Training_Status__c,Official_Agent__r.Online_Training_Status__c,Official_Agent__r.Online_Training_Completed_Date_Time__c
				,Official_Agent__r.CPA_Membership_Number__c,Official_Agent__r.ICAA_Membership_Number__c,Official_Agent__r.IPA_Membership_Number__c
			FROM Official_Agent_Appointment__c 
			WHERE Id = :entityId 
			LIMIT 1
		];
		if(results.IsEmpty()){
			return new Official_Agent_Appointment__c(Registration__c = this.Entity.Registration__c, Official_Agent__c = this.Registration.Official_Agent__c);
		}
		else{
			return results[0];
		}
	}
	
	public List<Official_Agent_Appointment__c> GetEntitiesByRegId(string regId, string orderBy, string direction){
        string query = 
			'SELECT Id, Name, Official_Agent__c, Official_Agent__r.Name, Official_Agent__r.Training_Status__c, Status__c, Date_From__c, Date_To__c'
			+ ' FROM Official_Agent_Appointment__c'
            + ' WHERE Registration__c = \'' + regId + '\''
            + ((orderBy == null || direction == null) ? '' : ' ORDER BY ' + orderBy + ' ' + direction);
        
        return Database.Query(query);
	}
    
    public void lkpOfficialAgent_Change(){
        System.Debug('test4: ' + this.Entity.Official_Agent__c);
        this.OfficialAgent = this.GetAccountById(this.Entity.Official_Agent__c);
    }
    
    public void OfficialAgent_Validated(){
        Account temp = this.GetAccountById(this.Entity.Official_Agent__c);
        for(string fieldName :new string[]{'CPA_Membership_Number__c','ICAA_Membership_Number__c','IPA_Membership_Number__c'}){
            System.Debug('test: ' + FieldName);
            System.Debug('test1: ' + this.OfficialAgent);
            temp.Put(FieldName, this.OfficialAgent.Get(FieldName));
        }
        this.OfficialAgent = temp;
    }
    
    public void updateOfficialAgent(){
        System.debug('Official ID2: ' + this.IsStakeholder + ', '+ this.IsHeadCandidate+ ', ' +this.IsPartyAgent + ', '+this.Entity.Official_Agent__c);
        if(this.IsStakeholder) {
            if (Registration.Stakeholder__r.RecordType.Name == 'Person') {
                this.Entity.Official_Agent__c = Registration.Stakeholder__c;
                System.debug('Official ID1: ' + this.Entity.Official_Agent__c);
            }else{
                this.Entity.Official_Agent__c = Registration.Authorised_Person__c;
            }
            this.IsOfficialAct = true;
        } else if (this.IsHeadCandidate) {
            this.Entity.Official_Agent__c = Registration.Stakeholder__c;
            this.IsOfficialAct = true;
        } else if (this.IsPartyAgent) {
            this.Entity.Official_Agent__c = Registration.Political_Party__r.Party_Agent__c;
            this.IsOfficialAct = true;
        } else{
            this.IsOfficialAct = false;
        }
        System.debug('Official ID: ' + this.Entity.Official_Agent__c);
        this.OfficialAgent = this.GetAccountById(this.Entity.Official_Agent__c);
    }    
    
    public void btnSortOap_Click(){
        this.ListEntitySortColumn = ApexPages.CurrentPage().GetParameters().Get('ListEntitySortColumn');
        this.ListEntitySortDirection = this.ListEntitySortDirection == null ? 'ASC' : (this.ListEntitySortDirection == 'ASC' ? 'DESC' : null);
        
        this.ListEntity = this.GetEntitiesByRegId(this.Entity.Registration__c, this.ListEntitySortColumn, this.ListEntitySortDirection);
    }
    
	public void btnCreateOap_Click(){
        this.Entity = this.GetEntityById(null);
        this.Entity.Official_Agent__c = null;
        this.OfficialAgent = this.GetAccountById(this.Entity.Official_Agent__c);
        //ApexPages.AddMessage(new ApexPages.Message(ApexPages.severity.INFO, this.Entity.Official_Agent__c));
        //DE4592
        this.IsStakeholder = false;
		this.IsHeadCandidate = false;
		this.IsPartyAgent = false;
        this.IsOfficialAct = false;
	}
	
	public void btnInlineEditOap_Click(){
		string oapId = ApexPages.CurrentPage().GetParameters().Get('oapId');
		if(string.IsNotEmpty(oapId)){
			this.InlineEntityId = oapId;
		}
	}
    
	public void btnSaveInlineEditOap_Click(){
        try{
            Official_Agent_Appointment__c ent;
            for(Official_Agent_Appointment__c item: this.ListEntity){
                if(item.Id == this.InlineEntityId){
                    ent = item;
                    break;
                }
            }
              
            if(ent == null || !this.ValidateActiveOfficialAgent(ent)){
                return;
            }
            
            if(ApexPages.CurrentPage().GetParameters().Get('hdnIsByPassing1ActiveAgent') == 'true'){
                for(Official_Agent_Appointment__c item: this.ListEntity){
                    if(item.Id != ent.Id && item.Status__c == 'Active'){
                        item.Status__c = 'InActive';
                        item.Date_To__c = ent.Date_From__c.addDays(-1);
                    }
                }
                upsert this.ListEntity;
            }
            
            upsert ent;
            
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.SEVERITY.CONFIRM, 'Record updated successfully'));
            
            this.InlineEntityId = null;
        }
        catch(Exception ex){
            ApexPages.AddMessages(ex);
        }
	}
    
	public void btnCancelInlineEditOap_Click(){
        this.InlineEntityId = null;
	}
	
	public void btnEditOap_Click(){
		string oapId = ApexPages.CurrentPage().GetParameters().Get('oapId');
		if(string.IsNotEmpty(oapId)){
			this.Entity = this.GetEntityById(oapId);
            this.OfficialAgent = this.GetAccountById(this.Entity.Official_Agent__c);
		}
	}
	
	public void btnDelOap_Click(){
		string oapId = ApexPages.CurrentPage().GetParameters().Get('oapId');
		if(string.IsNotEmpty(oapId)){
            try{
                delete [SELECT Id FROM Official_Agent_Appointment__c WHERE Id = :oapId];
                
                for(integer i = 0; i < this.ListEntity.Size(); i++){
                    if(this.ListEntity[i].Id == oapId){
                        this.ListEntity.Remove(i);
                        break;
                    }
                }
            }
            catch(Exception ex){
                ApexPages.AddMessages(ex);
            }
		}
	}
	
	public PageReference btnSave_Click(){
		if(this.SubmitChanges()){
			for(Official_Agent_Appointment__c item: this.ListEntity){
                if(item.Status__c == 'Active' && item.Date_From__c != null){
                    if(ApexPages.CurrentPage().GetParameters().Get('isdtp') == 'vw'){
                        this.StartUpScript = 'top.window.opener.pickCustomLookup("'+ApexPages.CurrentPage().GetParameters().Get('fid')+'","'+item.Official_Agent__c+'","'+item.Official_Agent__r.Name+'");top.window.close();';
                    }
                    else{
                        return new PageReference('/' + this.Entity.Registration__c);
                    }
                    break;
                }
            }
            
            //HanhLuu:US5256:start
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.SEVERITY.CONFIRM, 'Record updated successfully. Please ensure there is an \'Active\' Official Agent'));
            //HanhLuu:US5256:end
            
            String retURL = ApexPages.CurrentPage().GetParameters().Get('retURL');
            if(retURL!=null){
                PageReference newPage = new PageReference(retURL);
                newPage.setRedirect(true);
                return newPage;
            }
            //return new PageReference('/' + retURL);
                
		}
		
		return null;
	}
	
	public PageReference btnQuickSave_Click(){
        if(this.SubmitChanges()){
            //reload record;
            this.Entity = this.GetEntityById(this.Entity.Id);
            this.OfficialAgent = this.GetAccountById(this.Entity.Official_Agent__c);
            
            for(Official_Agent_Appointment__c item: this.ListEntity){
                if(item.Status__c == 'Active' && item.Date_From__c != null){
                    return null;
                }
            }
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.SEVERITY.CONFIRM, 'Record updated successfully. Please ensure there is an \'Active\' Official Agent'));
             
            /*ApexPages.AddMessage(new ApexPages.Message(ApexPages.SEVERITY.CONFIRM, 'Record updated successfully.'));
            /*
            if(this.Entity.Status__c == 'Active' && this.Entity.Date_From__c != null){
                ApexPages.AddMessage(new ApexPages.Message(ApexPages.SEVERITY.CONFIRM, 'Record updated successfully.'));
            }
            else if(this.ListEntity.Size() > 1){
                ApexPages.AddMessage(new ApexPages.Message(ApexPages.SEVERITY.CONFIRM, 'Record updated successfully. Please ensure there is an \'Active\' Official Agent'));
            }*/
        }
		
		return null;
	}
    
	private boolean SubmitChanges(){
        try {         
            upsert this.OfficialAgent;
            this.OfficialAgent = this.GetAccountById(this.OfficialAgent.Id);
        } catch (Exception ex) {
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.SEVERITY.ERROR, 'Party Agent does not exist for the Political Party.  Please navigate to the Political Party and update the Party Agent.'));
            //ApexPages.AddMessages(ex);
            return false;
        }
        // Create save Point
        Savepoint sp = Database.setSavepoint();
		try{
            System.debug('OK');            
            if(!this.ValidateActiveOfficialAgent(this.Entity)){
                System.debug('ValidateActiveOfficialAgent false');
                return false;
            }
            
            //HanhLuu:De4682:start            
            //this.Entity.Date_From__c = null;
            //this.Entity.Date_To__c = null;
            //HanhLuu:De4682:end   
            
            upsert this.Entity;
            
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Mess: ' + this.Entity.Id));
            
            if(ApexPages.CurrentPage().GetParameters().Get('hdnIsByPassing1ActiveAgent') == 'true'){
                List<Official_Agent_Appointment__c> tempListEntity = new List<Official_Agent_Appointment__c>();
                for(Official_Agent_Appointment__c item: this.ListEntity){
                    if(item.Id != this.Entity.Id) {
                        if (item.Status__c == 'Active'){
                           // ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Mess22: ' + item.Id));
                            item.Status__c = 'InActive';
                            item.Date_To__c = this.Entity.Date_From__c.addDays(-1);
                        }
                        tempListEntity.add(item);
                    }
                }
                upsert tempListEntity;
                //upsert this.ListEntity;
            }
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Mess1: ' + this.Entity.Status__c));
            
            if(this.Entity.Status__c == 'Active'){
                this.Registration.Official_Agent__c = this.Entity.Official_Agent__c;
                upsert this.Registration;                
            }
            
            /* => error when not retrieve this.ListEntity again
            for(Official_Agent_Appointment__c item: this.ListEntity){
                if(item.Status__c == 'Active'){
                    System.debug('value of Official_Agent__c: ' + item.Official_Agent__c);
                    System.debug('value of Registration: ' + this.Registration);
                    this.Registration.Official_Agent__c = item.Official_Agent__c;
                    System.debug('upsert this.OfficialAgent; OK '+ this.Registration.Official_Agent__c);
                    upsert this.Registration;
                    break;
                }
            }
            */
            
            this.ListEntity = this.GetEntitiesByRegId(this.Entity.Registration__c, 'Name', 'ASC');
            //ApexPages.AddMessage(new ApexPages.Message(ApexPages.SEVERITY.CONFIRM, 'Record updated successfully.'));
            
            return true;            
		}	
		catch(Exception ex){
			ApexPages.AddMessages(ex);
			Database.rollback(sp);
			return false;
		}
	}
    
    private boolean ValidateActiveOfficialAgent(Official_Agent_Appointment__c ent){
        boolean condition1 = ent.Status__c != 'Active';
        boolean condition2 = ent.Date_From__c != null;
        boolean condition3 = [SELECT COUNT() FROM Account WHERE Id = :ent.Official_Agent__c AND (NOT Online_Training_Status__c LIKE 'Training Complete')] > 0;
       	boolean condition4 = !(this.IsStakeholder || this.IsHeadCandidate || this.IsPartyAgent);
       
       	if(condition1 && condition2 && condition3/* && condition4*/){
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.SEVERITY.ERROR, this.Labels.Get('OfficialAgentApp.Msg.ActiveAgent').Content__c));
            
            return false;
        }
        return true;
    }
}