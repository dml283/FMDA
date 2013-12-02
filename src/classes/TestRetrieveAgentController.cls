@isTest(SeeAllData=true)
public with sharing class TestRetrieveAgentController{
	static testMethod void TestRetrieveAgent() {
        //InitialData();
        String fadmsId = 'X1';
        RetrieveAgentTrainingDetailsController.setFadmsId(fadmsId);
        RetrieveAgentTrainingDetailsController.getFadmsId();
        
        String tEndpoint = 'http://training.efa.nsw.gov.au/test/local/trainingrecord/index.php?fadmsid=' + RetrieveAgentTrainingDetailsController.getFadmsId();        
        
        String endpoint = RetrieveAgentTrainingDetailsController.buildEndpoint();
        
        System.assertEquals(endpoint, tEndpoint);
        //First, build the http request
        //Http h = new Http();
        HttpRequest req = RetrieveAgentTrainingDetailsController.buildWebServiceRequest();
        
        //write apex code to build a sample HttpResponse object 
        HttpResponse res = new HttpResponse();
        
        
        Dom.Document doc = new DOM.Document();
        
        Dom.XmlNode trainingRecNode
            = doc.createRootElement('TrainingRecord', null, null);
        
        Dom.XmlNode userNode = trainingRecNode.addChildElement('User', null, null);
        trainingRecNode.setAttribute('userId', 'aaa1');    
        
        userNode.addChildElement('FadmsElectorId', null, null).addTextNode('X1');            
        userNode.addChildElement('OfficialAgentTrainingResultOutcome', null, null).addTextNode('Passed');
        userNode.addChildElement('Status', null, null).addTextNode('');            
        
        Dom.XmlNode attemptsNode = trainingRecNode.addChildElement('Attempts', null, null);
        trainingRecNode.setAttribute('count', '1');
        
        Dom.XmlNode attemptNode = attemptsNode.addChildElement('Attempt', null, null);
        attemptNode.setAttribute('attemptId', '31');
        
        attemptNode.addChildElement('AttemptNumber', null, null).addTextNode('1');  
        attemptNode.addChildElement('Started', null, null).addTextNode('2012-12-24T10:30:00');
        attemptNode.addChildElement('TimeTaken', null, null).addTextNode('0 hrs 15 min 0 secs');
        attemptNode.addChildElement('Completed', null, null).addTextNode('2012-12-24T10:30:00');
        attemptNode.addChildElement('Marks', null, null).addTextNode('32');
        attemptNode.addChildElement('Grade', null, null).addTextNode('80');
        attemptNode.addChildElement('GradeOutcome', null, null).addTextNode('Passed');
        
        System.debug(doc.toXmlString());
        
        res.setBody(doc.toXmlString());
        
        res.setStatusCode(200);
        
        // Test getAgentTrainingDetails
        //PageReference temp = getAgentTrainingDetails();
        
        // Test updateStakeholder
        
        Test.setMock(HttpCalloutMock.class, new MoodleSvc1MockHttpRespGen());
        
        // Invoke svc
        Http h2 = new Http();
        HttpResponse res2 = RetrieveAgentTrainingDetailsController.invokeWebService(h2, req);
        
        
        // Test handleWebServiceResponse using manually built up xml
        RetrieveAgentTrainingDetailsController.handleWebServiceResponse(res,'Search');
        RetrieveAgentTrainingDetailsController.handleWebServiceResponse(res,'Save');
        //RetrieveAgentTrainingDetailsController.upsertAgentTrainingAttempts();
        RetrieveAgentTrainingDetailsController.retWrapper  retW = new RetrieveAgentTrainingDetailsController.retWrapper();
        //RetrieveAgentTrainingDetailsController.getUserAttempts(fadmsId);
        /*if (res.getStatusCode() == 200)
        {
        	System.debug('HTTP Status Code ok: ' + res.getStatusCode());
        }
        else
        {
        	throw new FADMSException('HTTP Status Code not 200: ' + res.getStatusCode());
        }*/
        
        try {
	        RetrieveAgentTrainingDetailsController.getUserAttempts(fadmsId);
        } catch (Exception e){
        }
        try {
        	RetrieveAgentTrainingDetailsController.upsertMoodleData(fadmsId);
        } catch (Exception e){
        }
    }
    
    static void InitialData() {
        List<RecordType> recordTypes = [SELECT Id, Name FROM RecordType];
		
		// Map Namae, Id of RecordType
		Map<String, String> listRecordType = new Map<String,String>();
		for (RecordType r : recordTypes) {
			listRecordType.put (r.Name, r.Id);
		}
        Account accountPerson = new Account(Salutation='Mr.',LastName = 'Test', FirstName='Name',RecordTypeId=listRecordType.get('Person'),FADMS_Elector_ID__c ='X1');
		upsert accountPerson;
    }
}