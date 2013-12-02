public class DisclosureNewOverrideController{
    public String retURL {get;set;}
    public DisclosureNewOverrideController(ApexPages.standardController sc){
        retURL = ApexPages.CurrentPage().GetParameters().Get('retURL');
        //ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'This: ' + retURL));
        string objectName = getObjectName(retURL);
        if(objectName == 'Disclosure_Claim_for_Payment__c'){
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'This button has been disabled to help ensure the correct Disclosure/Claim for Payment is created.'));
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'To create a New Disclosure, please navigate to the Stakeholder record -> Disclosure Obligation record to create a new Disclosure.'));
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'To create a New Claim for Payment, please navigate to the Stakeholder record -> Eligible Claim for Payment record to create a new Claim for Payment.'));
        }else if(objectName == 'Disclosure_Obligation__c'){
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'This button has been disabled to help ensure the correct Disclosure Obligation is created.'));
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'To create a new Disclosure Obligation, please navigate to the Stakeholder record to create a new Disclosure Obligation.'));
        }
    }
    
    public PageReference Back() {        
        return new PageReference(retURL);
    }
    
    private String getObjectName(String whatId) {
        String tPrefix = whatId.subString(1,4);
        String objectName = '';
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe(); 
        Set<String> keyPrefixSet = gd.keySet();
        for(String sObj : keyPrefixSet){
           Schema.DescribeSObjectResult r =  gd.get(sObj).getDescribe();
            if (r.getKeyPrefix() != null) {
                if (r.getKeyPrefix().compareTo(tPrefix) == 0) {
                    objectName =  r.getName();
                    break;
                }
            }
        }
        return objectName;
    }
}