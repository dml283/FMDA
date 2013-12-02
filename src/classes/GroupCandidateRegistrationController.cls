/* used for creating a Group of Candidates Registration record and associated data 
** include list of Disclosure_Obligation__c
*/
public class GroupCandidateRegistrationController{
	public Map<String, Static_Label__c> Labels{get;set;}
    public Registration__c Registration{get;set;}
    public Table_Settings__c table {get;set;}
	public Table_Settings__c tableGroup {get;set;}
    public List<Selectoption> partyList{get;set;}
    public Group_Member__c headCandidate{get;set;}
    public String headParty{get;set;}
    public boolean IsPostBack{get;set;}
    private Integer incrId;
    // Custom ID for Disclosure Obligation Wrapper
    public static final String CUSTOM_ID = 'DO_WRAPPER_ID';
	public static final String CUSTOM_ID_GROUP = 'GR_WRAPPER_ID';
	// For Disclosure Obligation Table
//    public List<DisclosureObligationWrapper> DOWrapper{get;set;}
	// For Group Details Table
    public List<GroupMemberWrapper> GMWrapper{get;set;}
    // Reporting period picklist
    private List<Selectoption> reportingPeriodPickList;
    //RecordType Name
    private String recordTypeName = '';
    // For Sorting Disclosure Obligation
    public String sortByColumn{get;set;}
    private String preSortColumn;
    public Boolean orderAsc{get;set;}
	// For Sorting Group Member
    public String sortByColumnGroup{get;set;}
    private String preSortColumnGroup;
    public Boolean orderAscGroup{get;set;}
    // For selected Row
    public String selectedID{get;set;}
    // List all Accounts
    private Map<Id, Account> accountList;
    public ApexPages.StandardController BaseController{get;set;}
    
    public Date DateOfElection{get;set;}
    public Boolean isChangeEvent{get;set;}
    
    public GroupCandidateRegistrationController(ApexPages.StandardController stdController) {
        if(this.IsPostBack == null || !this.IsPostBack){
            this.BaseController = stdController;
            this.Registration = (Registration__c)stdController.getRecord();
            // If from Election event, use retURL to get ElectionEvent ID
            String electionEvtId  =  ApexPages.CurrentPage().GetParameters().Get('retURL');
            if (electionEvtId == null) {
                electionEvtId = '';
            } else {
            	electionEvtId = electionEvtId.replaceAll('/', '');
            }
            
            String recordTypeId = ApexPages.currentPage().getParameters().get('RecordType');
            if (recordTypeId == null || String.isEmpty(recordTypeId)) {
                recordTypeName = 'Group of Candidates';
                recordTypeId = [Select Id from RecordType Where Name=:recordTypeName Limit 1][0].Id;
            } else {
            	recordTypeName = [Select Name from RecordType Where Id=:recordTypeId Limit 1][0].Name;
            }
            Registration.RecordTypeId = recordTypeId;
            if (electionEvtId.length() >= 15) {
            	List<Election_Event__c> ele = [SELECT Id, Date_of_Election__c FROM Election_Event__c WHERE Id=:electionEvtId LIMIT 1];
            	if (ele.size() > 0) {
            		this.Registration.Election_Event1__c = ele.get(0).Id;
            		DateOfElection = ele.get(0).Date_of_Election__c;
            	}
            }
            this.Labels = Static_Label__c.GetAll();
            this.IsPostBack = true;
            incrId = 1;
            
            //get table columns' name
			table = Table_Settings__c.getValues('DisclosureObligation');
            tableGroup = Table_Settings__c.getValues('GroupCandiate');
            
             // For Sorting on Disclosure Obligation
            preSortColumn = table.Column1_Name__c;
        	sortByColumn = preSortColumn;
        	orderAsc = true;
            
			preSortColumnGroup = tableGroup.Column1_Name__c;
        	sortByColumnGroup = preSortColumnGroup;
        	orderAscGroup = true;
            partyList = new List<SelectOption>();
            partyList.add(new SelectOption('', '--None--'));
            for (Account account : [SELECT Id, Name FROM Account
										WHERE Date_of_Deregistration__c = null 
                                      	AND RecordType.Name='Political Party']) {
                partyList.add(new SelectOption(account.Id, account.Name));
            }
//            DOWrapper = new List<DisclosureObligationWrapper>();
//            // Build Reporting Period Picklist
//            buildReportingPeriodPicklist();
//            // Add new DO to Wrapper
//            addNewDo();
			this.isChangeEvent = false;
			
            // Get all account
            accountList = new Map<Id, Account> ([Select Id, Name from Account]);
			// For Group Member
			GMWrapper = new List<GroupMemberWrapper>();
			// Create Head Candidate
			headCandidate = new Group_Member__c(Head_Candidate__c=true,Active__c=true);
            headParty ='';
            /*if (partyList.size() > 0) {
                headParty = partyList.get(0).getLabel();
            }*/
			// If creating a new Registration from the Account related list, update Account ID
            headCandidate.Candidate__c = Registration.Stakeholder__c;
			//headParty = getValueFromOptions(partyList,headCandidate.Political_Party__c);
			GMWrapper.add(new GroupMemberWrapper(headCandidate, partyList, incrId++));
            
        }
    }
    
//    private void buildReportingPeriodPicklist() {
//        reportingPeriodPickList = new List<Selectoption>();
//        for (Reporting_Period__c reportP : [Select Id, Name, Date_From__c, Date_To__c from Reporting_Period__c
//                                            Where Type__c = 'Financial Year' AND Active__c = true
//                                           	order by Date_From__c, Date_To__c]) {
//			reportingPeriodPickList.add(new SelectOption(reportP.Id, reportP.Name));
//    	   //reportingPeriodPickList.add(new SelectOption(reportP.Id, 
//           //                                             reportP.Date_From__c.year() + ' - ' + reportP.Date_To__c.year()));
//	    }
//    }
//    
//    private List<SelectOption> buildDonationReceivedCapList(String reportingPeriod){
//		
//		List<Selectoption> options = new List<SelectOption>();
//            options.add(new SelectOption('','--None--'));
//        // If Election_Event__r.RecordType.Name contains the word State build the list
//        List<Election_Event__c> campList = [
//            SELECT RecordType.Name/*, Reporting_Period__c */
//            FROM Election_Event__c
//            WHERE Id =:Registration.Election_Event1__c
//            	AND (State_Election_Type__c = 'Legislative Assembly Election' OR State_Election_Type__c = 'Legislative Council Election')            
//        ];
//        if (campList.size() > 0 ) {
//            for(Donation_Expenditure_Cap__c de : [
//                SELECT Id, Name FROM Donation_Expenditure_Cap__c
//                WHERE RecordType.Name = 'Donation Cap'
//                    AND Active__c = true
//                    AND Reporting_Period__c = :reportingPeriod
//                    AND Donation_Cap_Type__c = 'Group of Candidates'
//                ORDER by Name
//            ]){
//                options.add(new SelectOption(de.Id,de.Name));	
//            }
//        }
//        return options;
//	}
//    /*
//	private List<SelectOption> buildDonationGivenCapList(String reportingPeriod){
//		List<Selectoption> options = new List<SelectOption>();
//            options.add(new SelectOption('','--None--'));
//        // If Election_Event__r.RecordType.Name contains the word State build the list
//        List<Campaign> campList = [SELECT RecordType.Name, Reporting_Period__c FROM Campaign
//                                	WHERE Id =:Registration.Election_Event__c];
//        String campRecordTypeName = '';
//        if (campList.size() > 0 ) {
//            campRecordTypeName = campList.get(0).RecordType.Name;
//        }
//		if (campRecordTypeName.equalsIgnoreCase('State Election Event')) {
//			String queryPolitical = 'SELECT Id, Name FROM Donation_Expenditure_Cap__c '
//                                    + ' WHERE RecordType.Name = \'Donations (Given) Cap\' '
//									+ ' AND Active__c = true '
//                                    + ' AND Reporting_Period__c = :reportingPeriod '
//									+ ' AND Stakeholder_Type__c = :recordTypeName ';
//			if (Registration.Political_Party__c != null ) {
//			
//				queryPolitical += ' AND Endorsed_Type__c = \'Party Endorsed\' ';
//			} else {
//				queryPolitical += ' AND Endorsed_Type__c = \'Independent\' ';
//			}
//			queryPolitical += ' order by Name ';
//                              
//            for(Donation_Expenditure_Cap__c de : Database.query(queryPolitical)){
//                options.add(new SelectOption(de.Id,de.Name));	
//            }
//        }
//        return options;
//	}
//	*/
//    private List<SelectOption> buildExpenditureCapList(String reportingPeriod){
//        List<Selectoption> options = new List<SelectOption>();
//        options.add(new SelectOption('','--None--'));
//        
//        List<Election_Event__c> campList = [SELECT State_Election_Type__c FROM Election_Event__c WHERE Id =:Registration.Election_Event1__c];
//        String campType = '';
//        if (campList.size() > 0 ) {
//            campType = campList[0].State_Election_Type__c;
//        }
//		if (campType == 'Legislative Council Election' && this.Registration.Political_Party__c == null) {
//			List<Donation_Expenditure_Cap__c> temp = [
//                SELECT Id, Name FROM Donation_Expenditure_Cap__c
//                WHERE RecordType.Name = 'Expenditure Cap'
//                	AND Active__c = true
//                	AND Reporting_Period__c = :reportingPeriod
//                	AND Expenditure_Cap_Type__c = 'Group of unendorsed candidates for the Legislative Council'
//            ];
//            
//            for(Donation_Expenditure_Cap__c de :temp){
//                options.add(new SelectOption(de.Id,de.Name));	
//            }
//        }
//        return options;
//    }
//    
//    private void addNewDo() {
//        // Add new Disclosure Obligation to the table
//        Disclosure_Obligation__c discloserOb = new Disclosure_Obligation__c(Status__c='Obliged to Disclose');
//        // Add to Wrapper
//		String reportPeriod = '';
//		if (reportingPeriodPickList.size() > 0) {
//			reportPeriod = reportingPeriodPickList.get(0).getValue();
//		}
//        DOWrapper.add(new DisclosureObligationWrapper(discloserOb, reportingPeriodPickList, 
//                                                      buildDonationReceivedCapList(reportPeriod),buildExpenditureCapList(reportPeriod),
//													  incrId++));
//    }
//    public class DisclosureObligationWrapper {
//        public String Id{get;set;}
//        public boolean include{get;set;}
//        public Disclosure_Obligation__c disclosureOb{get;set;}
//        public List<SelectOption> reportingPeriodOps{get;set;}
//        public List<SelectOption> donationReceivedCapOps{get;set;}
//		//public List<SelectOption> donationGivenCapOps{get;set;}
//        public List<SelectOption> expenditureCapOps{get;set;}
//        public DisclosureObligationWrapper(Disclosure_Obligation__c disclosureOb,List<SelectOption>  reportingPeriodOps ,
//                                          List<SelectOption> donationReceivedCapOps, List<SelectOption> expenditureCapOps,
//                                          Integer Id) {
//			this.include = false;
//			this.disclosureOb = disclosureOb;
//			this.reportingPeriodOps = reportingPeriodOps;
//			this.donationReceivedCapOps = donationReceivedCapOps;
//			this.expenditureCapOps = expenditureCapOps;
//			//this.donationGivenCapOps = donationGivenCapOps;
//			this.Id = CUSTOM_ID + '_' + Id;                                           
//        }
//    }
    public class GroupMemberWrapper {
		public String Id{get;set;}
        public boolean include{get;set;}
		public Group_Member__c groupMember{get;set;}
		public List<SelectOption> politicalPartyOps{get;set;}
		public GroupMemberWrapper (Group_Member__c groupMember, List<SelectOption> politicalPartyOps,Integer Id) {
			this.groupMember = groupMember;
			this.politicalPartyOps = politicalPartyOps;
			this.Id = CUSTOM_ID_GROUP + '_' + Id;
            this.include = false;
		}
	}
    
    //Quick Save Function
    public PageReference Quicksave() {
        if(this.Registration.Official_Agent__c == null){
            Apexpages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR,  'You must denote 1 \'Active\' Official Agent against the Registration.  Please appoint an \'Active\' Official Agent.'));
            return null;
        }
        if (this.SubmitChanges()) {
            String newPageUrl = '/apex/groupcandidateedit?id='+ Registration.Id;
            PageReference newPage = new PageReference(newPageUrl);
            newPage.setRedirect(true);
            return newPage;
        }
        return null;
    }
    
    
    public PageReference quickSaveAndLookupOaa() {
        if(this.SubmitChanges()){
            String newPageUrl = '/apex/groupcandidateedit';
            PageReference newPage = new PageReference(newPageUrl);
            newPage.getParameters().Put('id', Registration.Id);
            newPage.getParameters().Put('allowEditOOA', 'true');
            newPage.getParameters().Put('deleteoncancel', '1');
            newPage.getParameters().Put('startUpScript', 'openCustomLookup("OfficialAgentAppointment",$("a.f-Official_Agent__c")[0],"regid='+this.Registration.Id+'")');
            //newPage.setRedirect(true);
            return newPage;
            
            //this.StartUpScript = 'openCustomLookup("OfficialAgentAppointment",$("a.f-Official_Agent__c")[0],"regid='+this.Registration.Id+'")';
        }
        return null;
    }
    
    public boolean SubmitChanges() {
        // Create save Point
        Savepoint sp = Database.setSavepoint();
        try {
            // Update the name Field of Registration__c
            // Query to get Stakeholder Name
            List<Account> accList = [Select Name, LastName from Account Where Id=:Registration.Stakeholder__c Limit 1];
            String stakeHolderName = '';
            String stakeHolderLastName = '';
            if (accList.size() > 0){
            	 stakeHolderName = accList.get(0).Name;
            	 stakeHolderLastName = accList.get(0).LastName;
            }
            // Query to get Election Event Name
            List<Election_Event__c> campList = [SELECT Date_of_Election__c FROM Election_Event__c WHERE Id =:Registration.Election_Event1__c  Limit 1];
            Integer campName;
            if (campList.size() > 0) {
                if(campList[0].Date_of_Election__c != null) {
                    campName = campList[0].Date_of_Election__c.Year();
                }
            }
            Registration.Name = (stakeHolderName + ' - ' + recordTypeName + ' Registration - ' + campName).Left(80);
            //Test set active = true
            Registration.Active__c = true;
            
            //Upsert Registration
            upsert Registration;
            Registration__c reg = [select Active__c from Registration__c where id =: Registration.id];
            reg.Active__c = true;
            upsert reg;
            //System.debug('Khuong get active__c after upsertReg: ' + [select Active__c from Registration__c where id =: Registration.id].Active__c);
            // Update Field Name and StackHolder of Disclosure_Obligation__c
            //US4808
            //List<Disclosure_Obligation__c> saveDOList = new List<Disclosure_Obligation__c>();
            //for (DisclosureObligationWrapper doW : DOWrapper) {
            //    doW.disclosureOb = doW.disclosureOb.Clone(false, false);
            //    doW.disclosureOb.Stakeholder__c = Registration.Stakeholder__c;
            //    doW.disclosureOb.Registration__c = Registration.Id;
            //    
            //    String reportingPeriod;
            //    Reporting_Period__c reportPerId = [SELECT Date_From__c, Date_To__c FROM Reporting_Period__c WHERE Id =:doW.disclosureOb.Reporting_Period__c  Limit 1];
            //    reportingPeriod = (reportPerId.Date_From__c != null ? reportPerId.Date_From__c.Year() + '' : '') 
            //        	+ '/' + (reportPerId.Date_To__c != null ? reportPerId.Date_To__c.Year() + '' : '');
            //    doW.disclosureOb.Name = (stakeHolderName + ' - ' + recordTypeName + ' Disclosure Obligation ' + reportingPeriod).Left(80);
            //    //doW.disclosureOb.Name = (stakeHolderName + ' - Disclosure Obligation - ' + campName).Left(80);
            //    saveDOList.add(doW.disclosureOb);
            //}
            //// Upsert DO
            //upsert saveDOList;
            List<Disclosure_Obligation__c> listDO = [SELECT Id, name FROM Disclosure_Obligation__c WHERE Registration__c =: Registration.Id];
            if(listDO.size() == 0){
            	CreateDisclosureObligation(stakeHolderLastName);
            }else if(listDO.size() > 0 && this.isChangeEvent){
            	//Remove disclosure obligation
            	delete listDO;
            	//Re-Create Disclosure Obligation
            	CreateDisclosureObligation(stakeHolderLastName);
            }
            
            //System.debug('Khuong get active__c after upsertDOW: ' + Registration.Active__c);
            // For Group Member
            List<Group_Member__c> saveGMList = new List<Group_Member__c>();
            for (GroupMemberWrapper gmW : GMWrapper) {
                gmW.groupMember = gmW.groupMember.Clone(false, false);
                gmW.groupMember.Registration__c = Registration.Id;
                saveGMList.add(gmW.groupMember);
            }
            // Upsert Group
            upsert saveGMList;
            //System.debug('Khuong get active__c after upsertGMW: ' + Registration.Active__c);
			return true;
        } catch(Exception e){
            // An exception was caught. We need to revert back to our Savepoint
            Database.rollback(sp);
            this.Registration = this.Registration.Clone(false, true);
            // Add the error to the page for the user to see
            ApexPages.addMessages(e);
            return false;
        }
    }
	
    public PageReference save() {
        if(this.Registration.Official_Agent__c == null){
            Apexpages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR,  'You must denote 1 \'Active\' Official Agent against the Registration.  Please appoint an \'Active\' Official Agent.'));
            return null;
        }
        if (this.SubmitChanges()) {
            String newPageUrl = '/'+ Registration.Id;
            PageReference newPage = new PageReference(newPageUrl);
            newPage.setRedirect(true);
            return newPage;
        }
        return null;
    }
    
    //US4808
    private void CreateDisclosureObligation(string stakeHolderName){
    	if(DateOfElection!=null){
    		List<Disclosure_Obligation__c> listDO = new List<Disclosure_Obligation__c>();
    		Integer year = DateOfElection.year();
    		Date compareDate = Date.newInstance(year, 7, 1);
    		if(DateOfElection < compareDate){
    			for (Reporting_Period__c reportP : [Select Id, Name, Date_From__c, Date_To__c from Reporting_Period__c
                                            Where Type__c = 'Financial Year' AND Active__c = true AND CALENDAR_YEAR(date_from__c) >= :Date.Today().Year()
                                            AND CALENDAR_YEAR(Date_To__c) <= :year
                                            Order by Name]) {					
    	   			Disclosure_Obligation__c disclosureOb = new Disclosure_Obligation__c();                    
                    disclosureOb.Stakeholder__c = Registration.Stakeholder__c;
                    disclosureOb.Registration__c = Registration.Id;
                	disclosureOb.Reporting_Period__c = reportP.Id;
                	Donation_Expenditure_Cap__c temp = pickupCorrectExpentureCap(reportP.Id);
                	if (temp<>null){
                		disclosureOb.Expenditure_Cap__c = temp.Id;
                	}
                	temp = pickupCorrectDonationCap(reportP.Id);
                	if (temp<>null){
                		disclosureOb.Donations_Received_Cap__c = temp.Id;
                	}
                	String reportingPeriod;	                
	                reportingPeriod = (reportP.Date_From__c != null ? reportP.Date_From__c.Year() + '' : '') 
	                    	+ '/' + (reportP.Date_To__c != null ? reportP.Date_To__c.Year() + '' : '');
	                disclosureOb.Name = (stakeHolderName + ' - ' + recordTypeName + ' Disclosure Obligation ' + reportingPeriod).Left(80);
	                System.debug('Result: ' + disclosureOb.Reporting_Period__c);
	                listDO.add(disclosureOb);
	    		}	
    			
    		}else{
    			for (Reporting_Period__c reportP : [Select Id, Name, Date_From__c, Date_To__c from Reporting_Period__c
                                            Where Type__c = 'Financial Year' AND Active__c = true AND CALENDAR_YEAR(date_from__c) >= :Date.Today().Year()
                                            AND CALENDAR_YEAR(Date_To__c) <= :year + 1
                                            Order by Name]) {					
    	   			Disclosure_Obligation__c disclosureOb = new Disclosure_Obligation__c();                    
                    disclosureOb.Stakeholder__c = Registration.Stakeholder__c;
                    disclosureOb.Registration__c = Registration.Id;
                	disclosureOb.Reporting_Period__c = reportP.Id;
                	Donation_Expenditure_Cap__c temp = pickupCorrectExpentureCap(reportP.Id);
                	if (temp<>null){
                		disclosureOb.Expenditure_Cap__c = temp.Id;
                	}
                	temp = pickupCorrectDonationCap(reportP.Id);
                	if (temp<>null){
                		disclosureOb.Donations_Received_Cap__c = temp.Id;
                	}	                String reportingPeriod;	                
	                reportingPeriod = (reportP.Date_From__c != null ? reportP.Date_From__c.Year() + '' : '') 
	                    	+ '/' + (reportP.Date_To__c != null ? reportP.Date_To__c.Year() + '' : '');
	                disclosureOb.Name = (stakeHolderName + ' - ' + recordTypeName + ' Disclosure Obligation ' + reportingPeriod).Left(80);
	                System.debug('Result1: ' + disclosureOb.Reporting_Period__c);
	                listDO.add(disclosureOb);
	    		}
    		}
    		System.debug('Result2: ' + listDO.size());
    		upsert listDO;
    		this.isChangeEvent = false;
    	}
    }
    
    //HanhLuu:US4925 -start
    public Donation_Expenditure_Cap__c pickupCorrectExpentureCap(String reportingPeriod){
        List<Selectoption> options = new List<SelectOption>();
        options.add(new SelectOption('','--None--'));
        Donation_Expenditure_Cap__c correctExpCap = null; 

        
        List<Election_Event__c> campList = [SELECT State_Election_Type__c FROM Election_Event__c WHERE Id =:Registration.Election_Event1__c];
        String campType = '';
        if (campList.size() > 0 ) {
            campType = campList[0].State_Election_Type__c;
        }
		if (campType == 'Legislative Council Election' && this.Registration.Political_Party__c == null) {
			correctExpCap = [
                SELECT Id, Name FROM Donation_Expenditure_Cap__c
                WHERE RecordType.Name = 'Expenditure Cap'
                	AND Active__c = true
                	AND Reporting_Period__c = :reportingPeriod
                	AND Expenditure_Cap_Type__c = 'Group of unendorsed candidates for the Legislative Council'
                	LIMIT 1
            ];
        }
        return correctExpCap;
    }
    //HanhLuu:US4925 -end    


    //Hanhluu:US5381 - start
     private Donation_Expenditure_Cap__c pickupCorrectDonationCap(String reportingPeriod){
     	Donation_Expenditure_Cap__c donation = null ;
        List<Election_Event__c> campList = [SELECT RecordType.Name, Reporting_Period__c FROM Election_Event__c
                                	WHERE Id =:Registration.Election_Event1__c];
        String campRecordTypeName = '';
        if (campList.size() > 0 ) {
            campRecordTypeName = campList.get(0).RecordType.Name;
        }
		if (campRecordTypeName.equalsIgnoreCase('Legislative Council') || campRecordTypeName.equalsIgnoreCase('Legislative Assembly') ) {
			String queryPolitical = 'SELECT Id, Name FROM Donation_Expenditure_Cap__c '
                                    + ' WHERE RecordType.Name = \'Donations (Given) Cap\' '
									+ ' AND Active__c = true '
                                    + ' AND Reporting_Period__c = :reportingPeriod '
									+ ' AND Donation_Cap_Type__c = \'Group of Candidates \''
									+ ' order by Name ';
			             
            donation = Database.query(queryPolitical);             
                              
        }
          return donation;
        
	}
    //Hanhluu:US5381 - end


//    public PageReference deleteDO() {
//        for (Integer i = DOWrapper.size() - 1; i >= 0; i--) {
//            if (DOWrapper.get(i).include) {
//                DOWrapper.remove(i);
//            }
//        }
//        return null;
//    }
//    public PageReference addDO() {
//       	addNewDo();
//        return null;
//    }
	public PageReference deleteGM() {
        for (Integer i = GMWrapper.size() - 1; i >= 0; i--) {
            if (GMWrapper.get(i).include) {
                GMWrapper.remove(i);
            }
        }
        return null;
    }
    public PageReference addGM() {
        //string partyDetailsId = ApexPages.currentPage().getParameters().get('partyDetailsId');
        //string partyDetailsId = Registration.Political_Party__c;
        //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Go here: ' + Registration.Political_Party__c));
        Group_Member__c gm = new Group_Member__c(Active__c=true);
        //if(partyDetailsId != ''){
        //	gm.Political_Party__c = partyDetailsId;    
        //}
       	
		GMWrapper.add(new GroupMemberWrapper(gm, partyList, incrId++));
        return null;
    }
    public PageReference updateElectionDetail() {
//        for (DisclosureObligationWrapper doW : DOWrapper) {
//            doW.donationReceivedCapOps = buildDonationReceivedCapList(doW.disclosureOb.Reporting_Period__c);
//            doW.ExpenditureCapOps = buildExpenditureCapList(doW.disclosureOb.Reporting_Period__c);
//			//doW.donationGivenCapOps = buildDonationGivenCapList(doW.disclosureOb.Reporting_Period__c);
//        }

		this.isChangeEvent = true;
        // DateOfElection = [SELECT Date_of_Election__c FROM Election_Event__c WHERE Id=:Registration.Election_Event__c LIMIT 1].Date_of_Election__c;
        List<Election_Event__c> ele = [SELECT Date_of_Election__c FROM Election_Event__c WHERE Id=:Registration.Election_Event1__c LIMIT 1];
        if (ele.size() > 0) {
            DateOfElection = ele.get(0).Date_of_Election__c;
        } else {
            DateOfElection = null;
        }
        return null;
    }
//    public PageReference updateDonationExpenditure() {
//        for (DisclosureObligationWrapper doW : DOWrapper) {
//            if (doW.Id == selectedID) {
//                doW.donationReceivedCapOps = buildDonationReceivedCapList(doW.disclosureOb.Reporting_Period__c);
//                doW.ExpenditureCapOps = buildExpenditureCapList(doW.disclosureOb.Reporting_Period__c);
//                //doW.donationGivenCapOps = buildDonationGivenCapList(doW.disclosureOb.Reporting_Period__c);
//                break;
//            }
//        }
//        return null;
//    }
     public PageReference updateHeadCandidate() {
         headCandidate.Candidate__c = Registration.Stakeholder__c;
         headCandidate.Confirm_Signed_By_Candidate__c = Registration.Confirm_Signed_By_Stakeholder__c;
         //Registration.Political_Party__c = headCandidate.Political_Party__c;
         //headParty = getValueFromOptions(partyList,headCandidate.Political_Party__c);
         headCandidate.Political_Party__c = headParty;
         updateElectionDetail();
         /*for (Integer i = 0; i < GMWrapper.size(); i++) {
             if (GMWrapper.get(i).groupMember.Head_Candidate__c) {
                 GMWrapper.remove(i);
                 if (i != GMWrapper.size()) {
                 	GMWrapper.add(i,new GroupMemberWrapper(headCandidate, partyList, incrId++));
                 } else {
                     GMWrapper.add(new GroupMemberWrapper(headCandidate, partyList, incrId++));
                 }
                 break;
             }
         }*/
        return null;
    }
    public void updateHeadCandidateInTable() {
        headParty = headCandidate.Political_Party__c;
        updateHeadCandidate();
    }
//    public PageReference sortData(){
//        if (sortByColumn.equalsIgnoreCase(preSortColumn)) {
//            orderAsc = !orderAsc;
//        } else {
//            orderAsc = true;
//        }
//        sortList(DOWrapper);
//        preSortColumn = sortByColumn;
//        return null;
//    }
	public PageReference sortDataGroup(){
        if (sortByColumnGroup.equalsIgnoreCase(preSortColumnGroup)) {
            orderAscGroup = !orderAscGroup;
        } else {
            orderAscGroup = true;
        }
        sortListGroup(GMWrapper);
        preSortColumnGroup = sortByColumnGroup;
        return null;
    }
//    private void sortList(List<DisclosureObligationWrapper> items){
//        List<DisclosureObligationWrapper> resultList = new List<DisclosureObligationWrapper>();
//    
//        //Create a map that can be used for sorting
//        Map<object, List<DisclosureObligationWrapper>> objectMap = new Map<object, List<DisclosureObligationWrapper>>();
//        
//        if (sortByColumn.equalsIgnoreCase(table.Column1_Name__c)) {	// Reporting Period
//            for(DisclosureObligationWrapper ob : items){
//                String property = getValueFromOptions(ob.reportingPeriodOps,ob.disclosureOb.Reporting_Period__c) ;
//                property = property.toLowerCase();
//                if(objectMap.get(property) == null){
//                    objectMap.put(property, new List<DisclosureObligationWrapper>());
//                }
//                objectMap.get(property).add(ob);
//            }
//        } else if (sortByColumn.equalsIgnoreCase(table.Column2_Name__c)) {	// Status
//            for(DisclosureObligationWrapper ob : items){
//                String property = (String) ob.disclosureOb.Status__c;
//                if (property == null || property =='') {
//                    property = ' ';
//                }
//                property = property.toLowerCase();
//                if(objectMap.get(property) == null){
//                    objectMap.put(property, new List<DisclosureObligationWrapper>());
//                }
//                objectMap.get(property).add(ob);
//            }
//        } else if (sortByColumn.equalsIgnoreCase(table.Column3_Name__c)) {	// Donation Received Cap
//            for(DisclosureObligationWrapper ob : items){
//                // Integer property = -1;
//                // String propertyTemp = getValueFromOptions(ob.donationReceivedCapOps,ob.disclosureOb.Donations_Received_Cap__c) ;
//                // if (propertyTemp != null && propertyTemp != '') {
//                //	property = Integer.valueof((String)propertyTemp.trim());
//                // }
//                String property = getValueFromOptions(ob.donationReceivedCapOps,ob.disclosureOb.Donations_Received_Cap__c) ;
//                if (property == null || property =='') {
//                    property = ' ';
//                }
//                if(objectMap.get(property) == null){
//                    objectMap.put(property, new List<DisclosureObligationWrapper>());
//                }
//                objectMap.get(property).add(ob);
//            }
//        } else if (sortByColumn.equalsIgnoreCase(table.Column4_Name__c)) {	// Expenditure Cap
//            for(DisclosureObligationWrapper ob : items){
//                String property = getValueFromOptions(ob.expenditureCapOps,ob.disclosureOb.Expenditure_Cap__c) ;
//                if (property == null || property =='') {
//                    property = ' ';
//                }
//                if(objectMap.get(property) == null){
//                    objectMap.put(property, new List<DisclosureObligationWrapper>());
//                }
//                objectMap.get(property).add(ob);
//            }
//        }
//        /*
//        else if (sortByColumn.equalsIgnoreCase(table.Column5_Name__c)) {	// Donation Given Cap
//            for(DisclosureObligationWrapper ob : items){
//                String property = getValueFromOptions(ob.donationGivenCapOps,ob.disclosureOb.Donation_Given_Cap__c) ;
//                if (property == null || property =='') {
//                    property = ' ';
//                }
//                if(objectMap.get(property) == null){
//                    objectMap.put(property, new List<DisclosureObligationWrapper>());
//                }
//                objectMap.get(property).add(ob);
//            }
//        }
//		*/
//		else {
//            return;
//        }       
//        //Sort the keys
//        List<object> keys = new List<object>(objectMap.keySet());
//        keys.sort();
//    
//        for(object key : keys){
//            resultList.addAll(objectMap.get(key));
//        }
//    
//        //Apply the sorted values to the source list
//        items.clear();
//        if(orderAsc){
//            for(DisclosureObligationWrapper ob : resultList){
//                items.add(ob);
//            }
//        }else {
//            for(integer i = resultList.size()-1; i >= 0; i--){
//                items.add(resultList[i]); 
//            }
//        }
//    }
	private void sortListGroup(List<GroupMemberWrapper> items){
        List<GroupMemberWrapper> resultList = new List<GroupMemberWrapper>();
    
        //Create a map that can be used for sorting
        Map<object, List<GroupMemberWrapper>> objectMap = new Map<object, List<GroupMemberWrapper>>();
        
        if (sortByColumnGroup.equalsIgnoreCase(tableGroup.Column1_Name__c)) {	//Candidate Name
            for(GroupMemberWrapper ob : items){
                String property = getAccountNameById(ob.groupMember.Candidate__c);
				if (property == null || property =='') {
                    property = ' ';
                }
                property = property.toLowerCase();
                if(objectMap.get(property) == null){
                    objectMap.put(property, new List<GroupMemberWrapper>());
                }
                objectMap.get(property).add(ob);
            }
        } else if (sortByColumnGroup.equalsIgnoreCase(tableGroup.Column2_Name__c)) {	// Political Party
            for(GroupMemberWrapper ob : items){
                String property = (String) ob.groupMember.Political_Party__c;
                if (property == null || property =='') {
                    property = ' ';
                }
                property = property.toLowerCase();
                if(objectMap.get(property) == null){
                    objectMap.put(property, new List<GroupMemberWrapper>());
                }
                objectMap.get(property).add(ob);
            }
        } else if (sortByColumnGroup.equalsIgnoreCase(tableGroup.Column3_Name__c)) {	// Head Candidate
            for(GroupMemberWrapper ob : items){
                Integer property = -1;
				if (ob.groupMember.Head_Candidate__c) {
					property = 1;
				}
                if(objectMap.get(property) == null){
                    objectMap.put(property, new List<GroupMemberWrapper>());
                }
                objectMap.get(property).add(ob);
            }
        } else if (sortByColumnGroup.equalsIgnoreCase(tableGroup.Column4_Name__c)) {	// Confirm Signed by Candidate
           for(GroupMemberWrapper ob : items){
                Integer property = -1;
				if (ob.groupMember.Confirm_Signed_By_Candidate__c) {
					property = 1;
				}
                if(objectMap.get(property) == null){
                    objectMap.put(property, new List<GroupMemberWrapper>());
                }
                objectMap.get(property).add(ob);
            }
        } else {
            return;
        }      
        //Sort the keys
        List<object> keys = new List<object>(objectMap.keySet());
        keys.sort();
    
        for(object key : keys){
            resultList.addAll(objectMap.get(key));
        }
    
        //Apply the sorted values to the source list
        items.clear();
        if(orderAscGroup){
            for(GroupMemberWrapper ob : resultList){
                items.add(ob);
            }
        }else {
            for(integer i = resultList.size()-1; i >= 0; i--){
                items.add(resultList[i]); 
            }
        }
    }
    private String getValueFromOptions (List<SelectOption> opList, String key){
        String strRet = '';
        for (SelectOption op : opList) {
            if (op.getValue().equals(key)) {
                strRet = op.getLabel();
                break;
            }
        }
        return strRet;
    }
	private String getAccountNameById (String Id){
        String strRet = '';
        if (accountList.containsKey(Id)) {
            strRet = accountList.get(Id).Name;
        }
        return strRet;
    }
    
    public void ElectionEventRequired(){
        ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Please select an Election Event for the Registration before choosing the Candidates.'));
    }
}