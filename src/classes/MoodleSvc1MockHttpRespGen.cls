@isTest
global class MoodleSvc1MockHttpRespGen implements HttpCalloutMock 
{
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) 
    {
        // Optionally, only send a mock response for a specific endpoint
        // and method.
        System.assertEquals('http://training.efa.nsw.gov.au/test/local/trainingrecord/index.php?fadmsid=X1', req.getEndpoint());
        System.assertEquals('GET', req.getMethod());
        
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'text/xml');
        
        // Set response values
        //res.setBody('{"foo":"bar"}');
        res.setStatusCode(200);
        
        System.assertEquals(200, res.getStatusCode());
        
        // return resp
        return res;
    }
}