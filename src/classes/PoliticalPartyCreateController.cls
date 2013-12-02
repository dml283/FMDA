/* Used for creating a new Stakeholder with recordtype is Political Party.
*/
public class PoliticalPartyCreateController{
    public Account Acc{get;set;}
    public boolean IsPostBack{get;set;}
    public boolean ShowForm{get;set;}
    public List<SelectOption> recordTypeList{get;set;}
    public String PoliticalRecordType{get;set;}
    private Id RecordTypeId = null;
    public PoliticalPartyCreateController(ApexPages.StandardController stdController) {
		if(this.IsPostBack == null || !this.IsPostBack){
            ShowForm = false;
            recordTypeList = new List<SelectOption>();
            this.Acc = (Account)stdController.getRecord();
            //ApexPages.AddMessage(new ApexPages.Message(ApexPages.severity.INFO, 'a ' + this.Acc.Id));
            PoliticalRecordType = [SELECT Id FROM RecordType WHERE Name='Political Party' LIMIT 1][0].Id;
            recordTypeList.add(new SelectOption(PoliticalRecordType,'Political Party'));
            this.Acc.RecordTypeId = PoliticalRecordType;
            IsPostBack = true;
        }
    }
    
    public PageReference Redirect(){
        if(this.Acc.Id != null){
            this.Acc = getEntityById(this.Acc.Id);
            if(this.Acc.RecordTypeId == PoliticalRecordType){                    
                ShowForm = true;
                return null;
            } else {
                String param = getParameters();
                String url = '/apex/';
                String prefix = Account.SObjectType.getDescribe().getKeyPrefix();
                url = '/' + prefix + '/e?nooverride=1&' + param;
                return new PageReference(url);
            }
        }
        return null;
    }
    
    public String GetParameters(){
        string param = '';
    	Map<String, String> strMap = ApexPages.currentPage().getParameters();
        if(strMap.ContainsKey('RecordType')){
            this.RecordTypeId = strMap.Get('RecordType');
        }
        for(String s: strMap.KeySet()){
            ApexPages.AddMessage(new ApexPages.message(ApexPages.severity.ERROR, s + ' : '+ strmap.get(s)));
            param += s + '=' + EncodingUtil.urlEncode(strMap.get(s),'UTF-8') + '&';
        }
        ApexPages.AddMessage(new ApexPages.message(ApexPages.severity.ERROR, param));    
    	if(param.length() > 0) param = param.substring(0, param.length()-1);
    	return param;
    }
    
    private Account getEntityById(String strId){
        return [SELECT Id, name, isPersonAccount, Party_Agent__c, Date_of_Registration__c, Registered_Officer__c,
                Date_of_Deregistration__c, BillingStreet, ShippingStreet, BillingCity, ShippingCity,
				BillingState, ShippingState, BillingPostalCode, ShippingPostalCode, BillingCountry,
				ShippingCountry, ParentId,Registration_Type__c
               FROM Account
               WHERE Id =: strId LIMIT 1];
    }
    
    public PageReference save(){
        try{
            upsert this.Acc;
            String retURL = '/' + this.Acc.Id;
            PageReference newPage = new PageReference(retURL);
            newPage.setRedirect(true);
            return newPage;
        }catch(Exception ex){
            //1. An exception was caught. We need to revert back to our Savepoint
            ApexPages.AddMessages(ex);
            return null;
        }
    }
    
    public void btnSelectRecordType_Click() {
        ShowForm = true;
    }
}