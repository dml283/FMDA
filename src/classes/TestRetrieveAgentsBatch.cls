@isTest(SeeAllData=true)
public class TestRetrieveAgentsBatch
{
    //static testMethod void TestRetrieveAgents()
    @isTest public static void testMain()
    {            
    	// getMoodleFormattedDate
        Datetime date1 = datetime.newInstance(2013, 10, 05, 12, 30, 0);
        String moodleDate1 = RetrieveAgentsBatch.getMoodleFormattedDate(date1);        
        System.assertEquals(moodleDate1, '2013-10-05');
                
        // getFormattedDateTime
        Datetime date2 = RetrieveAgentsBatch.getFormattedDateTime('2013-10-05T12:30:00');        
        System.assertEquals(date2, date1);        
        
        // buildEndpoint
        String baseEndpoint = 'http://training.efa.nsw.gov.au/test/local/trainingrecord/trainingdetailsindex.php?mode=LastRunDate&batchfromdt=2013-10-05';
        //String baseEndpoint = 'http://www.mocky.io/v2/52308ce8fd83b35c01fd862b?mode=LastRunDate&amp;BatchFromDt=20131005';
        String endpoint1 = RetrieveAgentsBatch.buildEndpoint(date1);
        System.assertEquals(endpoint1, baseEndpoint);

		// getBatchFromDate
        Datetime date3 = datetime.newInstance(2013, 10, 13, 23, 0, 6);        
        Datetime date4 = RetrieveAgentsBatch.getBatchFromDate();
        System.assertEquals(date3, date4);
        
        // buildWebServiceRequest
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();      

		Datetime date5 = datetime.newInstance(2013, 10, 05, 23, 0, 0);        
        req = RetrieveAgentsBatch.buildWebServiceRequest(date5);            

		// Test Invoke svc
        Http h3 = new Http();
        
		Test.setMock(HttpCalloutMock.class, new MoodleSvc2MockHttpRespGen());
        
        //HttpResponse res3 = RetrieveAgentsBatch.invokeWebService(h3, req);	
        
        //HttpResponse res2 = cntl.invokeWebService(h2, req);
        HttpResponse res3 = RetrieveAgentsBatch.invokeWebService(h3, req);	
       
        // Write apex code to build a sample HttpResponse object 
        HttpResponse res2 = new HttpResponse();        
        
        Dom.Document doc = new DOM.Document();
        
        Dom.XmlNode trainingRecNode = doc.createRootElement('TrainingRecords', null, null);
        
        trainingRecNode.addChildElement('BatchFromDt', null, null).addTextNode('2013-12-25T12:30:00');
        trainingRecNode.addChildElement('BatchToDt', null, null).addTextNode('');   
              
		// Build Users node              
        Dom.XmlNode usersNode = trainingRecNode.addChildElement('Users', null, null);
        usersNode.setAttribute('count', '1');
        
        // Build User node
        Dom.XmlNode userNode = usersNode.addChildElement('User', null, null);
        userNode.setAttribute('userId', '111');        
        
        userNode.addChildElement('FadmsElectorId', null, null).addTextNode('ZZZZZZZ1');
        userNode.addChildElement('FirstName', null, null).addTextNode('Joseph'); 
        userNode.addChildElement('LastName', null, null).addTextNode('Bloggs'); 
        userNode.addChildElement('DateOfBirth', null, null).addTextNode('1988-12-24'); 
        userNode.addChildElement('Email', null, null).addTextNode('jbloggs@gmail.com'); 
        userNode.addChildElement('Occupation', null, null).addTextNode('Doctor'); 
        userNode.addChildElement('Phone', null, null).addTextNode('02 9658 8588'); 
        userNode.addChildElement('Mobile', null, null).addTextNode('0412 658 558'); 
        userNode.addChildElement('Fax', null, null).addTextNode('0296 588 554'); 
        userNode.addChildElement('PostalLocality', null, null).addTextNode('Sydney');
        userNode.addChildElement('PostalAddress', null, null).addTextNode('123 Main Street'); 
        userNode.addChildElement('PostCode', null, null).addTextNode('2000'); 
        userNode.addChildElement('ElectoralRollLocality', null, null).addTextNode('Paramatta'); 
        userNode.addChildElement('ElectoralRollAddress', null, null).addTextNode('123 Main Street'); 
        userNode.addChildElement('ElectoralRollPostCode', null, null).addTextNode('2000'); 
        userNode.addChildElement('OfficialAgentTrainingResultOutcome', null, null).addTextNode('Passed');
        userNode.addChildElement('Status', null, null).addTextNode('Active');            
       
       // Build Attempts node
        Dom.XmlNode attemptsNode = userNode.addChildElement('Attempts', null, null);
        attemptsNode.setAttribute('count', '1');
        
        Dom.XmlNode attemptNode = attemptsNode.addChildElement('Attempt', null, null);
        attemptNode.setAttribute('attemptId', '1001');
        
        attemptNode.addChildElement('AttemptNumber', null, null).addTextNode('1');  
        attemptNode.addChildElement('Started', null, null).addTextNode('2012-12-24T10:30:00');
        attemptNode.addChildElement('TimeTaken', null, null).addTextNode('0 hrs 15 min 0 secs');
        attemptNode.addChildElement('Completed', null, null).addTextNode('2012-12-24T10:30:00');
        attemptNode.addChildElement('Marks', null, null).addTextNode('32');
        attemptNode.addChildElement('Grade', null, null).addTextNode('80');
        attemptNode.addChildElement('GradeOutcome', null, null).addTextNode('Passed');
        
       	// Output response xml
        System.debug(doc.toXmlString());
        
        res2.setBody(doc.toXmlString());        
        res2.setStatusCode(200);
        
        // handleWebServiceResponse
        RetrieveAgentsBatch.handleWebServiceResponse(res2);  
        
        // execute method
        //SchedulableContext ctx;
        
        //RetrieveAgentsBatch.execute(ctx);
        
        // createBatchLogEntry
        RetrieveAgentsBatch.createBatchLogEntry('Failed', date1, date4, 'EAI Error');
        RetrieveAgentsBatch.createBatchLogEntry('Success', date1, date4, '');       
    }
    
    static void InitialData() 
    {
    	/*
        List<RecordType> recordTypes = [SELECT Id, Name FROM RecordType];
        
        // Map Name, Id of RecordType
        Map<String, String> listRecordType = new Map<String,String>();
        for (RecordType r : recordTypes) 
        {
            listRecordType.put (r.Name, r.Id);
        }
        
        Account accountPerson = new Account(Salutation='Mr.',LastName = 'Test', FirstName='Name',RecordTypeId=listRecordType.get('Person'),FADMS_Elector_ID__c ='X1');
        upsert accountPerson;
        */
    }
}