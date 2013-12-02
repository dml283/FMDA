/* used for creating and updating Party Agent Appointment records against a Political Party (Stakeholder) record.
*/
public with sharing class PartyAgentAppointmentController{
    public boolean IsPostBack{get;set;}
    public Map<String, Static_Label__c> Labels{get;set;}
    public Table_Settings__c table{get;set;}
    public static final String CUSTOM_ID = 'PARTY_AGENT_WRAPPER_ID';
    public Party_Agent_Appointment__c partyAgentApp {get;set;}
    public Account onlinePartyAgent{get;set;}
    
    public boolean hasRecord{get{return (PartyAgentWrapper.size() > 0);}}
    public string PartyAgent{get{ return this.PoliticalParty.Party_Agent__r.Name; }}
    public string RegisteredOfficer{get{ return this.PoliticalParty.Registered_Officer__r.Name; }}
    // For Party Details Section
    public String PoliticalId{get;set;}
    public Account PoliticalParty {get;set;}
    public boolean isRegisterOfficerActing{get;set;}
    // Increment ID for wrapper
    private Integer incrId;
    // Wrapper
    public List<PartyAgentAppointmentWrapper> PartyAgentWrapper{get;set;}
    public String editid{get;set;}
    public String delid{get;set;}
    // For Sorting
    public String sortByColumn{get;set;}
    private String preSortColumn;
    public Boolean orderAsc{get;set;}
    public Boolean isEdit{get;set;}
    
    public PartyAgentAppointmentController(ApexPages.StandardController sc) {
        if(this.IsPostBack == null || !this.IsPostBack){
            this.partyAgentApp = (Party_Agent_Appointment__c)sc.GetRecord();
            this.Labels = Static_Label__c.GetAll();
            this.table = Table_Settings__c.getValues('PartyAgentAppointments');
            this.IsPostBack = true;
            
            System.debug('OK: ' + this.partyAgentApp.Id);
            if(this.partyAgentApp.Id != null) {	//Edit mode
                //Get partyAgentApp if this.partyAgentApp.Id != null => edit else Create new                
            	this.partyAgentApp = this.GetEntityById(this.partyAgentApp.Id);
                PoliticalId = this.partyAgentApp.Political_Party__c;
                initializeWrapperWithoutCreatingNew();
                //Get onlinePartyAgent
                isRegisterOfficerActing = false;
                loadPartyAgentDetails();
                loadOnlineTrainingDetails();
                isEdit = true;
            } else {	//Create new
                PoliticalId = ApexPages.currentPage().getParameters().get('AccountId');                
                //System.debug('OK PoliticalId: ' + PoliticalId);
                initilizeWrapper();
                isEdit = false;                
            }
        }
    }
    
    private Party_Agent_Appointment__c GetEntityById(String Id) {
        List<Party_Agent_Appointment__c> results = [
			SELECT Id, Name, Party_Agent__c, Political_Party__c, Status__c, Date_From__c, Date_To__c
				,Confirm_Signed_By_Party_Agent__c,Date_Signed_By_Party_Agent__c,Received_By__c
            	,Name_of_Party_Official__c, Position_of_Party_Official__c
				,Confirm_Signed_By_Party_Official__c,Date_Signed_By_Party_Official__c,Date_Received__c
			FROM Party_Agent_Appointment__c 
			WHERE Id = :Id 
			LIMIT 1
		];
        return results[0];
		
    }
    
    private void initilizeWrapper() {
        initializeWrapperWithoutCreatingNew();
        CreateNewPartyAgentApp();
    }
    private void initializeWrapperWithoutCreatingNew() {
        incrId = 1;
        PartyAgentWrapper = new List<PartyAgentAppointmentWrapper>();
        // For Sorting
        //preSortColumn = table.Column1_Name__c;
        preSortColumn = '';
        sortByColumn = preSortColumn;
        orderAsc = true;
        // TODO Query and add to Party Agent Table
        List<Party_Agent_Appointment__c> partyAgentList = [SELECT Name,Party_Agent__c,Status__c,Date_From__c,Party_Agent__r.Name,
                                                           Date_To__c,Party_Agent__r.Training_Status__c,Political_Party__c, Date_Received__c
                                                           FROM Party_Agent_Appointment__c
                                                           WHERE Political_Party__c=:PoliticalId];
        // Add to Wrapper
        for (Party_Agent_Appointment__c pa : partyAgentList) {
            PartyAgentWrapper.add(new PartyAgentAppointmentWrapper(pa,incrId++));
            System.Debug('PartyAgentWrapper: ' + PartyAgentWrapper.size());
        }
    }
    public void CreateNewPartyAgentApp() {
        partyAgentApp = new Party_Agent_Appointment__c(Status__c='Active',Political_Party__c=PoliticalId);
        if (PartyAgentWrapper.size() > 0) {
            partyAgentApp.Status__c = '';
        }
        isRegisterOfficerActing = false;
        loadPartyAgentDetails();
        loadOnlineTrainingDetails();
    }
    public void loadPartyAgentDetails() {
        PoliticalParty = [SELECT Id, Party_Agent__c, Registered_Officer__c, Party_Agent__r.Name, Registered_Officer__r.Name
                             FROM Account
                             WHERE Id=:PoliticalId Limit 1];
    }
    public void loadOnlineTrainingDetails() {
        onlinePartyAgent = new Account();
        if (partyAgentApp.Party_Agent__c != null) {
            onlinePartyAgent = [SELECT Id, Training_Status__c ,Online_Training_Status__c,Online_Training_Completed_Date_Time__c,
                         			CPA_Membership_Number__c,ICAA_Membership_Number__c,IPA_Membership_Number__c,
                                	Online_Training_Attempt_Count__c,FADMS_Elector_ID__c
                          		FROM Account
                          		WHERE Id =:partyAgentApp.Party_Agent__c LIMIT 1
                               ];
        }
    }
    
    public void CreateNew() {
		Savepoint sp = Database.setSavepoint();
		try {
			if (partyAgentApp.Status__c == 'Active') {
				// Query to get Old
				String oldActiveId = '';
				List<Party_Agent_Appointment__c> activePartyAgentList = [Select Id, Status__c from Party_Agent_Appointment__c
																		Where Political_Party__c =:PoliticalParty.Id
																		And	Status__c = 'Active' Limit 1];
				if (activePartyAgentList.size() > 0) oldActiveId = (String)activePartyAgentList.get(0).Id;
				
				if (SaveCurrentPartyAgent()) {
					// Replace the old Active with new Active
					SaveActiveAgent(oldActiveId);
					CreateNewPartyAgentApp();
				}
			} else {
				if (SaveCurrentPartyAgent()) {
					CreateNewPartyAgentApp();
				}
			}
        } catch (Exception e) {
			Database.rollback(sp);
			ApexPages.addMessages(e);
		} 
    }
    
    public void QuickSave() {
        SaveAllRecords();
        loadOnlineTrainingDetails();
    }
    
    private String getActivePartyAgent() {
        // Query to get Old
        String oldActiveId = null;
        List<Party_Agent_Appointment__c> activePartyAgentList = [Select Id, Status__c from Party_Agent_Appointment__c
                                                                 Where Political_Party__c =:PoliticalParty.Id
                                                                 And	Status__c = 'Active' Limit 1];
        if (activePartyAgentList.size() > 0) oldActiveId = (String)activePartyAgentList.get(0).Id;
        return oldActiveId;
    }
    private void SaveActiveAgent(String oldActiveId) {
        boolean isChangeActive = false;
        for (PartyAgentAppointmentWrapper paW : PartyAgentWrapper) {
            if (paW.partyAgentApp.Status__c == 'Active' && paW.partyAgentApp.Id != oldActiveId) {
				Party_Agent_Appointment__c activeAgent = paW.partyAgentApp;
                Account politicalPartyTemp = [Select Id, Party_Agent__c from Account where Id =:activeAgent.Political_Party__c Limit 1];
                // TODO Select Active Party Agent and save : requirement #12
                List<Party_Agent_Appointment__c> partyAgentList = [Select Id, Party_Agent__r.Name,Status__c, Date_To__c from Party_Agent_Appointment__c
                                                                  	Where Id=:oldActiveId Limit 1];
                politicalPartyTemp.Party_Agent__c = activeAgent.Party_Agent__c;

				upsert politicalPartyTemp;
				loadPartyAgentDetails();
				if (partyAgentList.size() > 0) {
					Party_Agent_Appointment__c oldActiveAgent = partyAgentList.get(0);
					if (oldActiveAgent.Id != activeAgent.Id) {
						// Update oldActiveAgent Status to inActive and Date To to 'Date From' of Active Agent
						oldActiveAgent.Status__c ='Inactive';
						oldActiveAgent.Date_To__c = ((activeAgent.Date_From__c != null) ? activeAgent.Date_From__c.addDays(-1) : Date.Today().addDays(-1));
						upsert oldActiveAgent;
						// Requirement #12
						//	Retrieve all ‘Active’ Registrations based on the below criteria
					   List<Registration__c> regList = [SELECT Id, Official_Agent__c 
														FROM Registration__c
														WHERE Official_Agent__c =:oldActiveAgent.Party_Agent__c
														AND Political_Party__c =:activeAgent.Political_Party__c
														AND Active__c = true
													   ];
						if (regList.size() > 0) {
							Set<String> regListId = new Set<String>();
							List<Official_Agent_Appointment__c> newOAAList = new List<Official_Agent_Appointment__c>();
							for (Registration__c reg : regList) {
								reg.Official_Agent__c = activeAgent.Party_Agent__c;
								regListId.add(reg.Id);
								Official_Agent_Appointment__c newOAA = new Official_Agent_Appointment__c();
								newOAA.Registration__c = reg.Id;
								newOAA.Official_Agent__c = activeAgent.Party_Agent__c;
								newOAA.Status__c = 'Active';
                                newOAA.Date_From__c = ((activeAgent.Date_Received__c != null) ? activeAgent.Date_Received__c : Date.Today());
								newOAAList.add(newOAA);
							}
							upsert regList;
							//Retrieve all ‘Active’ Official Agent Appointment records related to the Registration records selected in the 1st step with the following criteria
							List<Official_Agent_Appointment__c> oaaList = [SELECT Status__c, Date_To__c, Official_Agent__r.Name,Confirm_Signed_By_Party_Agent__c, Date_From__c,Registration__c
																		   FROM Official_Agent_Appointment__c
																		   WHERE Official_Agent__c =:oldActiveAgent.Party_Agent__c
																		   AND Status__c = 'Active'
																		   AND Registration__c IN :regListId
																		  ];
                            //ApexPages.addmessage(new apexPages.Message(apexPages.Severity.INFO,'Size is ' +String.valueof(regListId.size()) + '  ' +String.valueof(regListId)));
							for (Official_Agent_Appointment__c oaa : oaaList) {
								oaa.Status__c = 'Inactive';
								oaa.Date_To__c = ((activeAgent.Date_Received__c != null) ? activeAgent.Date_Received__c.addDays(-1) : Date.Today().addDays(-1));
							}
							upsert oaaList;
							upsert newOAAList;
						}
						
					}
				}
                isChangeActive = true;
                break;
            }
        }
        if (isChangeActive) {
            for (PartyAgentAppointmentWrapper paW : PartyAgentWrapper) {
                if (paW.partyAgentApp.Id == oldActiveId) {
                    paW.partyAgentApp = getPartyAgent(oldActiveId);
                    break;
                }
            }
        }
    }
    public PageReference Save() {
        
        if (SaveAllRecords()) {
            String newPageUrl = '/'+ PoliticalId;
            PageReference newPage = new PageReference(newPageUrl);
            newPage.setRedirect(true);
            return newPage;
        }
        return null;
    }
    public boolean SaveAllRecords() {
        boolean isSave = false;
        Savepoint sp = Database.setSavepoint();
		try {
			if (partyAgentApp.Status__c == 'Active') {
				// Query to get Old
				String oldActiveId = getActivePartyAgent();
				if (SaveCurrentPartyAgent()) {
					// Replace the old Active with new Active
					SaveActiveAgent(oldActiveId);
					isSave = true;
				}
			} else {
				if (SaveCurrentPartyAgent()) {
					isSave = true;
				}
			}
		} catch (Exception e) {
			Database.rollback(sp);
			ApexPages.addMessages(e);
		}
        return isSave;
    }
    public PageReference Cancel() {
        String newPageUrl = '/'+ PoliticalId;
        PageReference newPage = new PageReference(newPageUrl);
        newPage.setRedirect(true);
        return newPage;
    }
    
    public void editPartyAgent() {
        editid = getParam('editid');
        partyAgentApp = getPartyAgentDetails(editid);
        loadPartyAgentDetails();
        loadOnlineTrainingDetails();
    }
    // Edit single row
    public void editRow() {
        editid = getParam('editid');
        for (PartyAgentAppointmentWrapper paW : PartyAgentWrapper) {
            if (paW.Id == editid) {
                paW.isEdited = true;
                break;
            }
        }
    }
    
    //Cancel single row
    public void cancelRow() {
        editid = getParam('editid');
        for (PartyAgentAppointmentWrapper paW : PartyAgentWrapper) {
            if (paW.Id == editid) {
                paW.partyAgentApp = getPartyAgent(paW.partyAgentApp.Id);
                paW.trainingStatus = paW.partyAgentApp.Party_Agent__r.Training_Status__c;
                paW.isEdited = false;
                break;
            }
        }
    }
    
    // Delete single row
    public void delRow() {
        delid = getParam('delid');
        for (Integer i = 0; i < PartyAgentWrapper.size(); i++) {
            PartyAgentAppointmentWrapper paW = PartyAgentWrapper.get(i);
            if (paW.Id == delid) {
                try {
                    delete paW.partyAgentApp;
                    PartyAgentWrapper.remove(i);
                    // If delete current editted record, create new
                    if (paW.partyAgentApp.Id == partyAgentApp.Id) {
                        CreateNewPartyAgentApp();
                    }
                    // Show or Hide Create New Button
                    //hasRecord = PartyAgentWrapper.size() > 0;
                } catch (Exception e){
                    ApexPages.addMessages(e);
                }
                break;
            }
        }
    }
    
    // Save single row
    public void saveRow() {
        editid = getParam('editid');
		Savepoint sp = Database.setSavepoint();
		try {
			for (PartyAgentAppointmentWrapper paW : PartyAgentWrapper) {
				if (paW.Id == editid) {
					if (paW.partyAgentApp.Party_Agent__c == null) break;
					// Validate before Saving
					if (!cancelValidation(paW.partyAgentApp)) {
						break;
					}
					String oldActiveAgent = getActivePartyAgent();
					upsert paW.partyAgentApp;
					if (paW.partyAgentApp.Status__c == 'Active' && paW.partyAgentApp.Id != oldActiveAgent) {
						SaveActiveAgent(oldActiveAgent);
					}
					paW.partyAgentApp = getPartyAgent(paW.partyAgentApp.Id);
					paW.trainingStatus = paW.partyAgentApp.Party_Agent__r.Training_Status__c;

					paW.isEdited = false;
					break;
				}
			}
		} catch (Exception e){
			Database.rollback(sp);
			ApexPages.addMessages(e);
		}
    }
    // Check if has one active party Agent
    private boolean hasOneActive() {
		return hasOneActive(null);
	}
    
    private boolean hasOneActive(String Id) {
		boolean hasOneActive = false;
		for (PartyAgentAppointmentWrapper apW : PartyAgentWrapper) {
			if (apW.partyAgentApp.Status__c == 'Active' && apW.partyAgentApp.Id != Id) {
				hasOneActive = true;
				break;
			}
		}
		return hasOneActive;
	}
    // User try to save a record with status other than active
    private boolean cancelValidation (Party_Agent_Appointment__c paa) {
        String errorMessage = Labels.get('PartyAgentApp.Msg.2ActiveAgent').Content__c;
        //There are no other Party Agent Appointment records related to the Political Party
        if (!(paa.Status__c == 'Active')) {
            /*//There are no other Party Agent Appointment records related to the Political Party
            if (PartyAgentWrapper.size() == 0) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,errorMessage) );
                return false;
            }*/
            //There is another related Party Agent Appointment record but its Status has not been changed to ‘Active’
            if (!hasOneActive(paa.Id)) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,errorMessage) );
                return false;
            }
        }
        return true;
    }
    /*
    // Validation rule to ensure only 1 Active Party Agent
    private boolean OneActiveValidation (Party_Agent_Appointment__c paa) {
        String errorMessage = 'There can only be 1 \'Active\' Party Agent Appointment against a Political Party. '
            				+ 'To cancel an existing record edit it in the related list at the bottom of the page.'
            				+ ' Also ensure that the \'Date To\' is populated.';
        if (paa.Status__c == 'Active' && hasOneActive(paa.Id)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,errorMessage) );
            return false;
        }
        return true;
    }
	*/
    private boolean SaveCurrentPartyAgent() {
        // Validate Cancellation before Saving
        if (!cancelValidation(partyAgentApp)) {
            return false;
        }
        //
        
        // Save current partyAgent

		//boolean isNew = true;
		//if (partyAgentApp.Id != null) isNew = false;
        
		if (onlinePartyAgent.Id != null) {
			upsert onlinePartyAgent;
		}
		upsert partyAgentApp;
		partyAgentApp = getPartyAgentDetails(partyAgentApp.Id);
		/*
		if (isNew) {
			Party_Agent_Appointment__c temp =  getPartyAgent(partyAgentApp.Id);
			PartyAgentWrapper.add(new PartyAgentAppointmentWrapper(temp, incrId++));
		}
		for (PartyAgentAppointmentWrapper paW : PartyAgentWrapper) {
			if (paW.partyAgentApp.Id == partyAgentApp.Id) {
				paW.partyAgentApp = getPartyAgent(partyAgentApp.Id);
				paW.trainingStatus = paW.partyAgentApp.Party_Agent__r.Training_Status__c;
			}
			paW.isEdited = false;
		}*/
		initializeWrapperWithoutCreatingNew();

        return true;
    }
    
    public void updatePoliticalParty() {
        if (partyAgentApp.Political_Party__c != null) {
            PoliticalId = partyAgentApp.Political_Party__c;
        	initilizeWrapper();
        }
    }
    public void updatePartyAgent() {
        if (isRegisterOfficerActing) {
            partyAgentApp.Party_Agent__c = PoliticalParty.Registered_Officer__c;
            updateOnlineTrainingDetails();
        }
    }
    public void updateOnlineTrainingDetails() {
        loadOnlineTrainingDetails();
    }
    public void updateTrainingStatus() {
        for (PartyAgentAppointmentWrapper paW : PartyAgentWrapper) {
            if (paW.Id == editid && paW.partyAgentApp.Party_Agent__c != null) {
                paW.trainingStatus = [SELECT Training_Status__c FROM Account WHERE Id=:paW.partyAgentApp.Party_Agent__c LIMIT 1][0].Training_Status__c;
                break;
            }
        }
    }
    public String getParam(String name) {
		return ApexPages.currentPage().getParameters().get(name);  
    }
    private Party_Agent_Appointment__c getPartyAgent(String Id) {
        return [SELECT Name,Party_Agent__c,Status__c,Date_From__c,
                Date_To__c,Party_Agent__r.Training_Status__c,Political_Party__c,Party_Agent__r.Name
                FROM Party_Agent_Appointment__c
                WHERE Id=:Id
                LIMIT 1
               ];
    }
    private Party_Agent_Appointment__c getPartyAgentDetails(String Id) {
        return [SELECT Name,Party_Agent__c,Status__c,Date_From__c,Date_To__c,Party_Agent__r.Training_Status__c,Party_Agent__r.Name,
                	Political_Party__c,Confirm_Signed_By_Party_Agent__c,Date_Signed_By_Party_Agent__c,Name_of_Party_Official__c,
                	Position_of_Party_Official__c,Received_By__c,Confirm_Signed_By_Party_Official__c,Date_Signed_By_Party_Official__c,Date_Received__c
                FROM Party_Agent_Appointment__c
                WHERE Id=:Id
                LIMIT 1
               ];
    }
    // Wrapper for Party_Agent_Appointment__c
    public class PartyAgentAppointmentWrapper {
        public boolean isEdited{get;set;}
        public String Id{get;set;}
        public Party_Agent_Appointment__c partyAgentApp{get;set;}
        public String trainingStatus{get;set;}
        public PartyAgentAppointmentWrapper(Party_Agent_Appointment__c partyAgentApp, Integer Id) {
            this.isEdited = false;
            this.Id = CUSTOM_ID + '_' + Id;
            this.partyAgentApp = partyAgentApp;
            this.trainingStatus = partyAgentApp.Party_Agent__r.Training_Status__c;
        }
    }
    public PageReference sortData(){
        
        if (getParam('tableHeaderName') != null && getParam('tableHeaderName') != '') {
            sortByColumn = getParam('tableHeaderName');
        }
        if (sortByColumn.equalsIgnoreCase(preSortColumn)) {
            orderAsc = !orderAsc;
        } else {
            orderAsc = true;
        }
        sortList(PartyAgentWrapper);
        preSortColumn = sortByColumn;
        return null;
    }
    private void sortList(List<PartyAgentAppointmentWrapper> items){
        List<PartyAgentAppointmentWrapper> resultList = new List<PartyAgentAppointmentWrapper>();
    
        //Create a map that can be used for sorting
        Map<object, List<PartyAgentAppointmentWrapper>> objectMap = new Map<object, List<PartyAgentAppointmentWrapper>>();
        
        if (sortByColumn.equalsIgnoreCase(table.Column1_Name__c)) {	// Party Agent Appointment Number
            for(PartyAgentAppointmentWrapper ob : items){
                String property = ob.partyAgentApp.Name;
                if (property == null || property =='') {
                    property = ' ';
                }
                property = property.toLowerCase();
                if(objectMap.get(property) == null){
                    objectMap.put(property, new List<PartyAgentAppointmentWrapper>());
                }
                objectMap.get(property).add(ob);
            }
        } else if (sortByColumn.equalsIgnoreCase(table.Column2_Name__c)) {	// Party Agent
            for(PartyAgentAppointmentWrapper ob : items){
                String property = ob.partyAgentApp.Party_Agent__r.Name;
                if (property == null || property =='') {
                    property = ' ';
                }
                property = property.toLowerCase();
                if(objectMap.get(property) == null){
                    objectMap.put(property, new List<PartyAgentAppointmentWrapper>());
                }
                objectMap.get(property).add(ob);
            }
        } else if (sortByColumn.equalsIgnoreCase(table.Column3_Name__c)) {	// Status
            for(PartyAgentAppointmentWrapper ob : items){
                String property = ob.partyAgentApp.Status__c;
                if (property == null || property =='') {
                    property = ' ';
                }
                property = property.toLowerCase();
                if(objectMap.get(property) == null){
                    objectMap.put(property, new List<PartyAgentAppointmentWrapper>());
                }
                objectMap.get(property).add(ob);
            }
        } else if (sortByColumn.equalsIgnoreCase(table.Column4_Name__c)) {	// Training Status
            for(PartyAgentAppointmentWrapper ob : items){
                String property = ob.partyAgentApp.Party_Agent__r.Training_Status__c;
                if (property == null || property =='') {
                    property = ' ';
                }
                property = property.toLowerCase();
                if(objectMap.get(property) == null){
                    objectMap.put(property, new List<PartyAgentAppointmentWrapper>());
                }
                objectMap.get(property).add(ob);
            }
        } else if (sortByColumn.equalsIgnoreCase(table.Column5_Name__c)) {	// Date From
            for(PartyAgentAppointmentWrapper ob : items){
                String property = String.ValueOf(ob.partyAgentApp.Date_From__c);
                if (property == null || property =='') {
                    property = ' ';
                }
                if(objectMap.get(property) == null){
                    objectMap.put(property, new List<PartyAgentAppointmentWrapper>());
                }
                objectMap.get(property).add(ob);
            }
        } else if (sortByColumn.equalsIgnoreCase(table.Column6_Name__c)) {	// Date To
            for(PartyAgentAppointmentWrapper ob : items){
                String property =  String.ValueOf(ob.partyAgentApp.Date_To__c);
                if (property == null || property =='') {
                    property = ' ';
                }
                if(objectMap.get(property) == null){
                    objectMap.put(property, new List<PartyAgentAppointmentWrapper>());
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
        if(orderAsc){
            for(PartyAgentAppointmentWrapper ob : resultList){
                items.add(ob);
            }
        }else {
            for(integer i = resultList.size()-1; i >= 0; i--){
                items.add(resultList[i]); 
            }
        }
    }
}