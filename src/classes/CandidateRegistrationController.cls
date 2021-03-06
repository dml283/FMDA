/* used for creating a Candidates Registration record and associated data include list of Disclosure_Obligation__c
*/
public class CandidateRegistrationController{
	public Map<String, Static_Label__c> Labels{get;set;}
    public Registration__c Registration{get;set;}
    public Table_Settings__c table {get;set;}
    public List<Selectoption> partyList{get;set;}
    public boolean IsPostBack{get;set;}
    public boolean IsEditMode{get;set;}
    private Integer incrId;
    // Custom ID for Disclosure Obligation Wrapper
    public static final String CUSTOM_ID = 'DO_WRAPPER_ID';
//    public List<DisclosureObligationWrapper> DOWrapper{get;set;}
    // Reporting period picklist
    private List<Selectoption> reportingPeriodPickList;
    //RecordType Name
    private String recordTypeName = '';
    // For Sorting
    public String sortByColumn{get;set;}
    private String preSortColumn;
    public Boolean orderAsc{get;set;}
    // For selected Row
    public String selectedID{get;set;}
    
    public Date DateOfElection{get;set;}
    public Boolean isChangeEvent{get;set;}
    
    public transient string StartUpScript{get;set;}
    //control whether the registration is permanently persisted or just temporary for official agent appointment
    public boolean IsPersisted{get;set;}
    public ApexPages.StandardController BaseController{get;set;}
    
    public CandidateRegistrationController(ApexPages.StandardController stdController) {
        if(this.IsPostBack == null || !this.IsPostBack){
            this.BaseController = stdController;
            String RegistrationId = ((Registration__c)stdController.getRecord()).Id;
            // If from Election event, use retURL to get ElectionEvent ID
            String electionEvtId  =  ApexPages.CurrentPage().GetParameters().Get('retURL');
            if (electionEvtId == null) {
                electionEvtId = '';
            } else {
            	electionEvtId = electionEvtId.replaceAll('/', '');
            }
            if (RegistrationId == null || String.isEmpty(RegistrationId)) {
                IsEditMode = false;
                this.Registration = (Registration__c)stdController.getRecord();
                if (electionEvtId.length() >= 15) {
                	List<Election_Event__c> ele = [SELECT Id, Date_of_Election__c FROM Election_Event__c WHERE Id=:electionEvtId LIMIT 1];
                	if (ele.size() > 0) {
                		this.Registration.Election_Event1__c = ele.get(0).Id;
                		DateOfElection = ele.get(0).Date_of_Election__c;
                	}
                }
            } else {
                IsEditMode = true;
                List<Registration__c> tempList = getEntityById(RegistrationId);
                if(tempList.size() > 0) {
                    this.Registration = tempList.get(0);
                } else {
	                this.Registration = (Registration__c)stdController.getRecord();
                }
                updateElectionDetail();
            }
            
            String recordTypeId = ApexPages.currentPage().getParameters().get('RecordType');
            if (recordTypeId == null || String.isEmpty(recordTypeId)) {
                recordTypeName = 'Candidate';
                recordTypeId = [Select Id from RecordType Where Name=:recordTypeName Limit 1][0].Id;
            } else {
            	recordTypeName = [Select Name from RecordType Where Id=:recordTypeId Limit 1][0].Name;
            }
            Registration.RecordTypeId = recordTypeId;
            this.Labels = Static_Label__c.GetAll();
            this.IsPostBack = true;
            incrId = 1;
            //get table columns' name
			table = Table_Settings__c.getValues('DisclosureObligation');
            
            // For Sorting
            preSortColumn = table.Column1_Name__c;
        	sortByColumn = preSortColumn;
        	orderAsc = true;
            
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
//            if (!IsEditMode) {
//                // Add new DO to Wrapper
//                addNewDo();
//            }
            
            this.isChangeEvent = false;
        }
    }
   	private List<Registration__c> getEntityById (String Id) {
        return [SELECT Id,Name,Group_Name__c,Confirm_Signed_By_Stakeholder__c,Date_Signed_By_Stakeholder__c, 
                            	RecordTypeId,Stakeholder__c,Election_Event1__c,Political_Party__c,Official_Agent__c,
                            	Date_Received__c,Received_By__c,Additional_Details__c, EMA_ID__c, HP_TRIM_File_No__c, Source__c,
                            	Recordtype.Name, Active__c, Ballot_Label__c
                            FROM Registration__c
                            WHERE Id = :Id];
    }
//    /*
//    private void buildDOWrapper() {
//        // Get all Disclosure Obligation
//        List<Disclosure_Obligation__c> doList = [SELECT Id, Registration__c, Reporting_Period__c, Status__c, 
//                                                 Donations_Received_Cap__c,Expenditure_Cap__c
//                                                 FROM Disclosure_Obligation__c
//                                                 WHERE Registration__c = :this.Registration.Id
//                                                 order By Reporting_Period__c
//                                                ];
//        for (Disclosure_Obligation__c discloserOb : doList) {
//            DOWrapper.add(new DisclosureObligationWrapper(discloserOb, reportingPeriodPickList, 
//                                                          buildDonationReceivedCapList(discloserOb.Reporting_Period__c),buildExpenditureCapList(discloserOb.Reporting_Period__c),
//                                                          incrId++, true));
//        }
//    }*/
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
//    private List<SelectOption> buildDonationReceivedCapList(String reportingPeriod){
//		List<Selectoption> options = new List<SelectOption>();
//            options.add(new SelectOption('','--None--'));
//        // If Election_Event__r.RecordType.Name contains the word State build the list
//        List<Election_Event__c> campList = [
//            SELECT RecordType.Name /*, Reporting_Period__c */
//            FROM Election_Event__c
//            WHERE Id =:Registration.Election_Event1__c
//            	AND (State_Election_Type__c = 'Legislative Assembly Election' OR State_Election_Type__c = 'Legislative Council Election')            
//        ];
//        
//        if (campList.size() > 0 ) {
//            for(Donation_Expenditure_Cap__c de : [
//                SELECT Id, Name FROM Donation_Expenditure_Cap__c
//                WHERE RecordType.Name = 'Donation Cap'
//                    AND Active__c = true
//                    AND Reporting_Period__c = :reportingPeriod
//                    AND Donation_Cap_Type__c = 'Candidate'
//                ORDER by Name
//            ]){
//                options.add(new SelectOption(de.Id,de.Name));	
//            }
//        }
//        return options;
//	}
// 
/*   
    private List<SelectOption> buildExpenditureCapList(String reportingPeriod){
        List<Selectoption> options = new List<SelectOption>();
        options.add(new SelectOption('','--None--'));
        
        if(this.Registration.Election_Event1__c == null){
            return options;
        }
        string ecType = '';
        Election_Event__c event = [SELECT State_Election_Type__c, By_Election__c FROM Election_Event__c WHERE Id =:Registration.Election_Event1__c];
        
        if(event.State_Election_Type__c == 'Legislative Council Election'){
            ecType = 'Ungrouped candidate for the Legislative Council';
        }
        else if(event.State_Election_Type__c == 'Legislative Assembly Election'){
            if(event.By_Election__c == true){
                ecType = 'Candidate for a Legislative Assembly by-election';
            }
            else if(this.Registration.Political_Party__c == null){
                ecType = 'Unendorsed candidate for the Legislative Assembly';
            }
            else{
                ecType = 'Endorsed candidate for the Legislative Assembly';
            }
        }
            
        List<Donation_Expenditure_Cap__c> temp = [
            SELECT Id, Name FROM Donation_Expenditure_Cap__c
            WHERE RecordType.Name = 'Expenditure Cap'
            AND Active__c = true
            AND Reporting_Period__c = :reportingPeriod
            AND Expenditure_Cap_Type__c = :ecType
            ORDER by Name
        ];
        
        for(Donation_Expenditure_Cap__c de :temp){
            options.add(new SelectOption(de.Id,de.Name));	
        }
        return options;
    }
*/    
//    
//    private void addNewDo() {
//        // Add new Disclosure Obligation to the table
//        Disclosure_Obligation__c discloserOb = new Disclosure_Obligation__c(Status__c='Obliged to Disclose');
//        // Add to Wrapper
//		String reportPeriod = '';
//		if (reportingPeriodPickList.size() > 0) {
//			reportPeriod = reportingPeriodPickList.get(0).getValue();
//		}
//        /*
//        DOWrapper.add(new DisclosureObligationWrapper(discloserOb, reportingPeriodPickList, 
//                                                      buildDonationReceivedCapList(reportPeriod),buildExpenditureCapList(reportPeriod),
//													  buildDonationGivenCapList(reportPeriod),incrId++));
//		*/
//        DOWrapper.add(new DisclosureObligationWrapper(discloserOb, reportingPeriodPickList, 
//                                                      buildDonationReceivedCapList(reportPeriod),buildExpenditureCapList(reportPeriod),
//													  incrId++, false));
//    }
//    public class DisclosureObligationWrapper {
//        public String Id{get;set;}
//        public boolean include{get;set;}
//        public boolean isExist;
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
//        
//        public DisclosureObligationWrapper(Disclosure_Obligation__c disclosureOb,List<SelectOption>  reportingPeriodOps ,
//                                          List<SelectOption> donationReceivedCapOps, List<SelectOption> expenditureCapOps,
//                                          Integer Id, boolean isExist) {
//			this.include = false;
//			this.disclosureOb = disclosureOb;
//			this.reportingPeriodOps = reportingPeriodOps;
//			this.donationReceivedCapOps = donationReceivedCapOps;
//			this.expenditureCapOps = expenditureCapOps;
//			//this.donationGivenCapOps = donationGivenCapOps;
//			this.Id = CUSTOM_ID + '_' + Id;
//            this.isExist = isExist;                             
//        }
//    }
    
    public PageReference Cancel(){
        if(this.Registration.Id != null && this.IsPersisted != true && !IsEditMode){
            delete [SELECT Id FROM Disclosure_Obligation__c WHERE Registration__c = :this.Registration.Id];
            delete [SELECT Id FROM Official_Agent_Appointment__c WHERE Registration__c = :this.Registration.Id];
            delete this.Registration;
        }
        return this.BaseController.Cancel();
    }
    
    //Quick save Function
    public void quickSave() {
        if(this.Registration.Official_Agent__c == null){
            Apexpages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR,  'You must denote 1 \'Active\' Official Agent against the Registration.  Please appoint an \'Active\' Official Agent.'));
            return;
        }
        this.SubmitChanges();
        this.IsPersisted = true;
    }
    
    public void quickSaveAndLookupOaa() {
        if(this.SubmitChanges()){
            this.StartUpScript = 'openCustomLookup("OfficialAgentAppointment",$("a.f-Official_Agent__c")[0],"regid='+this.Registration.Id+'")';
        }
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
            //System.debug('SELECT Date_of_Election__c FROM Campaign WHERE Id =:'+Registration.Election_Event__c +' Limit 1');
            List<Election_Event__c> campList = [SELECT Date_of_Election__c FROM Election_Event__c WHERE Id =:Registration.Election_Event1__c  Limit 1];
            Integer campName = 0;
            if (campList.size() > 0) {
                if(campList[0].Date_of_Election__c != null) {
                    campName = campList[0].Date_of_Election__c.Year();
                }
            }
            Registration.Name = (stakeHolderName + ' - ' + recordTypeName + ' Registration - ' + campName).Left(80);
            //Upsert Registration
            upsert Registration;
            
            // Update Field Name and StackHolder of Disclosure_Obligation__c
            //US4808            
            //List<Disclosure_Obligation__c> saveDOList = new List<Disclosure_Obligation__c>();
            //for (DisclosureObligationWrapper doW : DOWrapper) {
            //    //ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.Info, String.ValueOf(doW.Id) + ' ' + doW.disclosureOb.Reporting_Period__c));
            //    if (!doW.isExist) {
            //        doW.disclosureOb = doW.disclosureOb.Clone(false, false);
            //        doW.disclosureOb.Stakeholder__c = Registration.Stakeholder__c;
            //        doW.disclosureOb.Registration__c = Registration.Id;
            //    }
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
            //for (DisclosureObligationWrapper doW : DOWrapper) {
            //    doW.isExist = true;
            //}           
            List<Disclosure_Obligation__c> listDO = [SELECT Id, name FROM Disclosure_Obligation__c WHERE Registration__c =: Registration.Id];
            if(listDO.size() == 0){
            	CreateDisclosureObligation(stakeHolderLastName);
            }else if(listDO.size() > 0 && this.isChangeEvent){
            	//Remove disclosure obligation
            	delete listDO;
            	//Re-Create Disclosure Obligation
            	CreateDisclosureObligation(stakeHolderLastName);
            }
            return true;
        } catch(Exception e){
            //1. An exception was caught. We need to revert back to our Savepoint
            Database.rollback(sp);
            this.Registration = this.Registration.Clone(false, true);
            //2. Add the error to the page for the user to see
            ApexPages.addMessages(e);
            return false;
        }
    }
    
    public PageReference save() {
        if(this.Registration.Official_Agent__c == null){
            Apexpages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR,  'You must denote 1 \'Active\' Official Agent against the Registration.  Please appoint an \'Active\' Official Agent.'));
            return null;
        }
        if (this.SubmitChanges()){
            String newPageUrl = '/'+ Registration.Id;
            PageReference newPage = new PageReference(newPageUrl);
            newPage.setRedirect(true);
            return newPage;
        } else {
            return null;
        }
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
                	}
                	String reportingPeriod;                
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
        
        if(this.Registration.Election_Event1__c == null){
            return correctExpCap ;
        }
        string ecType = '';
        Election_Event__c event = [SELECT State_Election_Type__c, By_Election__c FROM Election_Event__c WHERE Id =:Registration.Election_Event1__c];
        
        if(event.State_Election_Type__c == 'Legislative Council Election'){
            ecType = 'Ungrouped candidate for the Legislative Council';
        }
        else if(event.State_Election_Type__c == 'Legislative Assembly Election'){
            if(event.By_Election__c == true){
                ecType = 'Candidate for a Legislative Assembly by-election';
            }
            else if(this.Registration.Political_Party__c == null){
                ecType = 'Unendorsed candidate for the Legislative Assembly';
            }
            else{
                ecType = 'Endorsed candidate for the Legislative Assembly';
            }
        }
            
        correctExpCap = [
            SELECT Id, Name FROM Donation_Expenditure_Cap__c
            WHERE RecordType.Name = 'Expenditure Cap'
            AND Active__c = true
            AND Reporting_Period__c = :reportingPeriod
            AND Expenditure_Cap_Type__c = :ecType
            ORDER by Name 
            LIMIT 1
        ];
        
    	return correctExpCap;
    }
    //HanhLuu:US4925 -end
    
    //Hanhluu:US5381 - start
     private Donation_Expenditure_Cap__c pickupCorrectDonationCap(String reportingPeriod){
     	Donation_Expenditure_Cap__c donation = null ;
        List<Election_Event__c> campList = [
            SELECT RecordType.Name /*, Reporting_Period__c */
            FROM Election_Event__c
            WHERE Id =:Registration.Election_Event1__c
            	AND (State_Election_Type__c = 'Legislative Assembly Election' OR State_Election_Type__c = 'Legislative Council Election')            
        ];

        if (campList.size() > 0 ) {
            donation = [SELECT Id, Name FROM Donation_Expenditure_Cap__c
                		WHERE RecordType.Name = 'Donation Cap'
	                    AND Active__c = true
	                    AND Reporting_Period__c = :reportingPeriod
	                    AND Donation_Cap_Type__c = 'Candidate'
	                	ORDER by Name
	                	LIMIT 1
		            ];
        }
        
        return donation;
	}
    //Hanhluu:US5381 - end
    
    
//    public PageReference deleteDO() {
//        List<String> deleteIdList = new List<String>();
//        for (Integer i = DOWrapper.size() - 1; i >= 0; i--) {
//            if (DOWrapper.get(i).include) {
//                if (DOWrapper.get(i).isExist && DOWrapper.get(i).disclosureOb.Id != null) {
//                    deleteIdList.add(DOWrapper.get(i).disclosureOb.Id);
//                }
//                DOWrapper.remove(i);
//            }
//        }
//
//        try {
//			List<Disclosure_Obligation__c> deleteDOList = [SELECT Id FROM Disclosure_Obligation__c
//																		WHERE Registration__c=:Registration.Id AND Id IN :deleteIdList];
//			delete deleteDOList;
//		} catch (Exception e) {
//            ApexPages.addMessages(e);
//        }
//        return null;
//        /*======================
//        for (Integer i = DOWrapper.size() - 1; i >= 0; i--) {
//            if (DOWrapper.get(i).include) {
//                DOWrapper.remove(i);
//            }
//        }
//        return null;
//		=========================*/
//    }
//    public PageReference addDO() {
//       	addNewDo();
//        return null;
//    }
    public PageReference updateElectionDetail() {
//        for (DisclosureObligationWrapper doW : DOWrapper) {
//            doW.donationReceivedCapOps = buildDonationReceivedCapList(doW.disclosureOb.Reporting_Period__c);
//            doW.ExpenditureCapOps = buildExpenditureCapList(doW.disclosureOb.Reporting_Period__c);
//			//doW.donationGivenCapOps = buildDonationGivenCapList(doW.disclosureOb.Reporting_Period__c);
//        }
        
        this.isChangeEvent = true;
        //DateOfElection = [SELECT Date_of_Election__c FROM Election_Event__c WHERE Id=:Registration.Election_Event__c LIMIT 1].Date_of_Election__c;
        List<Election_Event__c> ele = [SELECT Date_of_Election__c FROM Election_Event__c WHERE Id=:Registration.Election_Event1__c LIMIT 1];
        if (ele.size() > 0) {
            DateOfElection = ele.get(0).Date_of_Election__c;
        } else {
            DateOfElection = null;
        }
        return null;
    }
//    public PageReference updateDonationExpenditure() {
//        //ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.Info, String.ValueOf(DOWrapper.size()) + selectedID));
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
//        /*else if (sortByColumn.equalsIgnoreCase(table.Column5_Name__c)) {	// Donation Given Cap
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
//        */
//            else {
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
//    private String getValueFromOptions (List<SelectOption> opList, String key){
//        String strRet = '';
//        for (SelectOption op : opList) {
//            if (op.getValue().equals(key)) {
//                strRet = op.getLabel();
//                break;
//            }
//        }
//        return strRet;
//    }
}