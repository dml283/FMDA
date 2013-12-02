public class EligibleClaimController {
	
	public String searchKeyWord{get;set;}
	public list<Election_Event__c> electionEvents{get;set;}
	public String registrationId{get;set;}
	public String stakeholderId{get;set;}
	public String StartUpScript{get;set;}
	
		
	public EligibleClaimController() {
		try{
			stakeholderId  = ApexPages.currentPage().getParameters().get('StakeID');
			registrationId = ApexPages.currentPage().getParameters().get('RegID');
			doSearch();
		}catch (Exception ex){
			stakeholderId  = '';
			registrationId = '';
		}
	}
	
	public void doSearch(){
		boolean isContinue = true;
		Registration__c reg;

		if ('000000000000000'.equals(registrationId) || ''.equals(registrationId) ){
			electionEvents = [SELECT id,name, Ward__c,Term_Start_Date__c
							  FROM Election_Event__c];
		
		}else{
			try{
				reg = [SELECT id, Election_Event1__c
									   FROM Registration__c
									   WHERE id = :registrationId]; 
				electionEvents = [SELECT id,name, Ward__c,Term_Start_Date__c
								  FROM Election_Event__c
								  WHERE id = :reg.Election_Event1__c ];
									   
			}catch (Exception ex){
				ApexPages.addMessages(ex);
				
			}
		}
	}
	
	public void PickItem() {
        try {
            String itemId = ApexPages.CurrentPage().GetParameters().Get('itemId');
            for (Election_Event__c item : electionEvents) {
                if (item.Id == itemId) {
                    String str = JSON.serialize(item);
                    //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'a '+ str));
                    this.StartupScript  = 'top.window.opener.ReloadSection(\'' +itemId+ ' \',' + str + ');';
                    this.StartupScript  += 'top.window.close();';
                    break;
                }
            }
        } catch (Exception e) {
            ApexPages.addMessages(e);
        }
    }
}