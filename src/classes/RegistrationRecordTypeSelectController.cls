/* Used for selecting Registration RecordType & redirect to Registration pages
*/
public with sharing class RegistrationRecordTypeSelectController{
    private Id RecordTypeId = null;
    
    public RegistrationRecordTypeSelectController (ApexPages.StandardController controller){
    }
    
    public PageReference Redirect(){
        String param = getParameters();// + '&(your field id)=(your field value)';
        String url = '/apex/';
        Map<Id, RecordType> recordTypes = new Map<Id, RecordType>([
            SELECT ID, Name 
            FROM RecordType 
            WHERE SObjectType = 'Registration__c' AND IsActive = true
        ]);
        
        if(!recordTypes.ContainsKey(this.RecordTypeId)){
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.SEVERITY.WARNING, 'No registration record type was selected!'));
            return null;
        }
        String recordType = recordTypes.Get(this.RecordTypeId).Name;
        if(recordType == 'Candidate'){
            url += 'CandidateRegistration';
        }
        else if(recordType == 'Third-Party Campaigner'){
            url += 'CampaignerReg';
        }
        else if(recordType == 'Group of Candidates'){
            url += 'GroupCandidateRegistration';
        }
        else if(recordType == 'Elected Member'){
            url += 'ElectedMemReg';
        }
        else{
            String prefix = Registration__c.SObjectType.getDescribe().getKeyPrefix();
            url = '/' + prefix + '/e?nooverride=1&' + param;
            return new PageReference(url);
        }
        return new PageReference(url + '?' + param);   
    }
    
    private String GetParameters(){
    	string param = '';
    	Map<String, String> strMap = ApexPages.currentPage().getParameters();
        if(strMap.ContainsKey('RecordType')){
            this.RecordTypeId = strMap.Get('RecordType');
        }
    	//String[] keys = new String[]{'RecordType', 'saveURL','retURL', 'cancelURL'};
    	//for(String s : keys){
    		//if(strMap.containsKey(S)) 
        for(String s: strMap.KeySet()){
            param += s + '=' + EncodingUtil.urlEncode(strMap.get(s),'UTF-8') + '&';
        }
    	//}
    	if(param.length() > 0) param = param.substring(0, param.length()-1);
    	return param;
    }
}