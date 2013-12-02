/* Used for selecting Task/Non-Compliance RecordType & redirect to create that record.
*/
public class TaskNonComplianceRecordSelectController{
	private Id RecordTypeId = null;
    
    public TaskNonComplianceRecordSelectController (ApexPages.StandardController controller){
    }
    
    public PageReference Redirect(){
        String param = getParameters();// + '&(your field id)=(your field value)';
        String url = '/apex/';
        Map<Id, RecordType> recordTypes = new Map<Id, RecordType>([
            SELECT ID, Name 
            FROM RecordType 
            WHERE SObjectType = 'Task' AND IsActive = true
        ]);
        
        if(!recordTypes.ContainsKey(this.RecordTypeId)){
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.SEVERITY.WARNING, 'No task record type was selected!'));
            return null;
        }
        String recordType = recordTypes.Get(this.RecordTypeId).Name;
        if(recordType == 'Non-Compliance'){
            url += 'NonComplianceCreate';
        }
        /*
        else if(recordType == 'Task'){
            url += '';
        }
        */
            else{
            String prefix = Task.SObjectType.getDescribe().getKeyPrefix();
            url = '/' + prefix + '/e?nooverride=1&' + param;
            return new PageReference(url);
        }
        return new PageReference(url + '?' + param);   
    }
    public String GetParameters(){
        string param = '';
    	Map<String, String> strMap = ApexPages.currentPage().getParameters();
        if(strMap.ContainsKey('RecordType')){
            this.RecordTypeId = strMap.Get('RecordType');
        }
        strMap.Remove('save_new');
    	//String[] keys = new String[]{'RecordType', 'saveURL','retURL', 'cancelURL'};
    	//for(String s : keys){
    		//if(strMap.containsKey(S)) 
        for(String s: strMap.KeySet()){
            ApexPages.AddMessage(new ApexPages.message(ApexPages.severity.ERROR, s + ' : '+ strmap.get(s)));
            param += s + '=' + EncodingUtil.urlEncode(strMap.get(s),'UTF-8') + '&';
        }
        ApexPages.AddMessage(new ApexPages.message(ApexPages.severity.ERROR, param));
    	//}
    	if(param.length() > 0) param = param.substring(0, param.length()-1);
    	return param;
    }
}