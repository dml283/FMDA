@isTest(SeeAllData=true)
private class MoodleTestClass1 
{
    
    // Test methods
    // Add test method logic using 
    // System.assert(), 
    // System.assertEquals() 
    // System.assertNotEquals() 
    
    
    // Methods for testing
    @isTest public static void testMain() 
    {
        try
        {
        
            RetrieveAgentTrainingDetailsController cntl = new RetrieveAgentTrainingDetailsController();
    
            // Test setInputText
            cntl.setInputText('aaa1');
            System.assertEquals(cntl.getInputText(), 'aaa1');
            
            // Test getInputText
            String id1 = 'aaa1';    
            String id2 = cntl.getInputText();
            System.assertEquals(id1, id2);
            
            //System.debug('test2: ' + test2);
            
            // Test getFadmsId
            cntl.setFadmsId('X1'); 
            String id3 = cntl.getFadmsId();
            System.assertEquals(id3, 'X1');
            
            //startTest;
            
            //System.assert
            
            //stopTest;
            
            // Test buildEndpoint
            
            //cntl.setFadmsId('X1');
    
            System.debug('Test buildEndpoint');
            //String tEndpoint = 'http://www.mocky.io/v2/5200e593e90a7bba00d817d0?fadmsid=' + cntl.getFadmsId();
            String tEndpoint = 'http://training.efa.nsw.gov.au/test/local/trainingrecord/index.php?fadmsid=' + cntl.getFadmsId();        
             
            String endpoint = cntl.buildEndpoint();
            
            System.assertEquals(endpoint, tEndpoint);
            
            // Test buildWebServiceRequest
            
            //First, build the http request
            //Http h = new Http();
            HttpRequest req = cntl.buildWebServiceRequest();
            
            //write apex code to build a sample HttpResponse object 
            HttpResponse res = new HttpResponse();
            
    
            Dom.Document doc = new DOM.Document();
    
            Dom.XmlNode trainingRecNode
                = doc.createRootElement('TrainingRecord', null, null);
    
            Dom.XmlNode userNode = trainingRecNode.addChildElement('User', null, null);
            trainingRecNode.setAttribute('userId', 'aaa1');    
                
            userNode.addChildElement('FadmsElectorId', null, null).addTextNode('X1');            
            userNode.addChildElement('OfficialAgentTrainingResultOutcome', null, null).addTextNode('Passed');
            userNode.addChildElement('Status', null, null).addTextNode('Suspended');            
            
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
            HttpResponse res2 = cntl.invokeWebService(h2, req);

            
            // Test handleWebServiceResponse using manually built up xml
            cntl.handleWebServiceResponse(res);

            if (res.getStatusCode() == 200)
            {
                System.debug('HTTP Status Code ok: ' + res.getStatusCode());
            }
            else
            {
                throw new FADMSException('HTTP Status Code not 200: ' + res.getStatusCode());
            }

        }
        catch (Exception e)
        {
            System.debug('Error Occurred:' + '[' + e.getMessage() +' ]');
            throw new FADMSException(e.getMessage());
        }
    }


}