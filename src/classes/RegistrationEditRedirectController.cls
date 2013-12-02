/* Used for selecting Registration RecordType & redirect to Edit Registration pages
*/
public with sharing class RegistrationEditRedirectController {
	public Registration__c Entity{get;set;}
	
	public RegistrationEditRedirectController (ApexPages.StandardController controller){
		this.Entity = (Registration__c)controller.GetRecord();
    }
    
    public PageReference Redirect(){
    	this.Entity = [SELECT RecordType.Name FROM Registration__c WHERE Id = :this.Entity.Id LIMIT 1];
    	if(this.Entity.RecordType.Name == 'Group of Candidates'){
    		return new PageReference('/apex/groupcandidateedit?' + this.GetParameters());
        } else if (this.Entity.RecordType.Name == 'Candidate'){
            return new PageReference('/apex/CandidateRegistration?' + this.GetParameters());
        } else if (this.Entity.RecordType.Name == 'Third-Party Campaigner'){
            return new PageReference('/apex/CampaignerReg?' + this.GetParameters());
        }else if (this.Entity.RecordType.Name == 'Elected Member'){
            return new PageReference('/apex/ElectedMemReg?' + this.GetParameters());
        }else{
	    	String prefix = Registration__c.SObjectType.getDescribe().getKeyPrefix();
	        String param = getParameters();
	        return new PageReference('/'+prefix+'/e?nooverride=1&'+param);   
    	}
    	
    	return null;
    }
    private String GetParameters(){
    	string param = '';
    	Map<String, String> strMap = ApexPages.currentPage().getParameters();
        for(String s: strMap.KeySet()){
            param += s + '=' + EncodingUtil.urlEncode(strMap.get(s),'UTF-8') + '&';
        }
    	if(param.length() > 0) param = param.substring(0, param.length()-1);
    	return param;
    }
}