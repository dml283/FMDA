global class RetrieveAgentTrainingDetailsController 
{
    // Method Properties

    // Stakeholder / Moodle User fields 
    global static String fadmsId = '';
    global static ID acctId;
    global static String userOutcome = '';
    global static String userStatus = '';
    global static Integer userAttemptCount = 0;
    global static String respErrorMessage = 'Integration Error: ';
    global static boolean validResponseFlg;
    
    // Endpoint
    // Sample real endpoint: 
    // http://training.efa.nsw.gov.au/test/local/trainingrecord/index.php?fadmsid=3
    
    // Change hardcode URL to custom setting url
    // private static final String ENDPOINT_DOMAIN = 'http://training.efa.nsw.gov.au';
    // private static final String ENDPOINT_RESOURCE = '/test/local/trainingrecord/fadmsindex.php';
    // private static final String SVC_ENDPOINT = ENDPOINT_DOMAIN + ENDPOINT_RESOURCE;
    private static final String SVC_ENDPOINT = Webservice_URL__c.getValues('Moodle Real Time').URL__c;
    
    // List of Attempts
    global static List<Attempt> trainingAttempts {get;set;}

    global static String getFadmsId() 
    {
        return fadmsId;
    }

    global static void setFadmsId(String id) 
    {
        fadmsId = id;
    }

    // REMOTE ACTION method
    // Vinh modified: change return type to retWrapper (instead of list<Attempt>), add some variables to retWrapper
    @RemoteAction
    global static retWrapper getUserAttempts(String inputId)     
    {        
        try
        {
            System.debug('Method Called: getUserAttempts');            
			
            // Set class fadmsId
            setFadmsId(inputId);
    
            System.debug('VF INPUT FADMS ID: ' + getFadmsId());
    
            // Validate fadmsid
            if (getFadmsId().length() <= 0)
            {
                throw new FADMSException('Fadms ID was not supplied. Cannot perform Moodle Service callout.');
            }
            else
            {
                // Validate against spaces  
                if (getFadmsId().containsWhitespace())
                {
                    throw new FADMSException('Fadms ID is invalid - cannot contain spaces. Cannot perform Moodle Service callout.');
                }
            }           
			
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            HttpResponse res = new HttpResponse();      
            
            // Build rq
            req = buildWebServiceRequest();
            
            // Invoke svc
            res = invokeWebService(http, req);
    
            // Process res
            handleWebServiceResponse(res, 'Search');
        }
        catch (Exception e)
        {
            System.debug('Error Occurred:' + '[' + e.getMessage() +' ]');
            throw new FADMSException(e.getMessage());
        }
                
        //return tableData;
        retWrapper result = new retWrapper();
        result.trainingAttemptsInWrap 	= trainingAttempts;
        result.userOutcomeInWrap	= userOutcome;
        result.userStatusInWrap		= userStatus;
        result.userAttemptCountInWrap	= userAttemptCount;
        
        return result;        
    }    

    // REMOTE ACTION method
    @RemoteAction
    global static void upsertMoodleData(String inputId) 
    {        
        try
        {
            System.debug('Method Called: upsertMoodleData');

            // Set class fadmsId
            setFadmsId(inputId);
    
            System.debug('VF INPUT FADMS ID: ' + getFadmsId());
    
            // Validate fadmsid
            if (getFadmsId().length() <= 0)
            {
                throw new FADMSException('Fadms ID was not supplied. Cannot perform Moodle Service callout.');
            }
            else
            {
                // Validate against spaces  
                if (getFadmsId().containsWhitespace())
                {
                    throw new FADMSException('Fadms ID is invalid - cannot contain spaces. Cannot perform Moodle Service callout.');
                }
            }           

            Http http = new Http();
            HttpRequest req = new HttpRequest();
            HttpResponse res = new HttpResponse();      
            
            // Build rq
            req = buildWebServiceRequest();
            
            // Invoke svc
            res = invokeWebService(http, req);
    
            // Process res
            handleWebServiceResponse(res, 'Save');
        }
        catch (Exception e)
        {
            System.debug('Error Occurred:' + '[' + e.getMessage() +' ]');
            throw new FADMSException(e.getMessage());
        }
    }  

    global static String buildEndpoint()
    {  
        System.debug('Method Called: buildEndpoint');

        String ERR_PSK = 'PSK was not supplied.';
        String ERR_RQID = 'RequestId was not supplied.';
        String ERR_TOKEN = 'Token was not supplied.';

        String endpoint = '';

        try
        {
	        // Sample real endpoint: 
	        // http://training.efa.nsw.gov.au/test/local/trainingrecord/index.php?fadmsid=3
	
	        // Stub setup
	        // String stubDomain = 'http://www.mocky.io/v2/';
	        // String stubInstanceId = '';
	
	        // Set stub instance
	        //stubInstanceId = '51fc15122677bb6d03ad4572';  // 2 attempts (active)
	        //stubInstanceId = '51fcebe2e05e80cf000ab1e3';  // stub 3 - 2 attempts (active)
	        //stubInstanceId = '51fdd857581ed2510014b3bd';  // stub 4
	        //stubInstanceId = '51fd3695e05e800d010ab1e9';  // stub 5
	        //stubInstanceId = '51fddc99581ed2510014b3bf';  // stub 7
	        //stubInstanceId = '51fde2e8581ed2510014b3c1';  // stub 8
	        //stubInstanceId = '51fe01b8581ed27e0014b3c3';  // stub 9 - No Matching User found (200 OK)
	        //stubInstanceId = '52001bdd969e4a80029c1987';  // stub 10 - User not enrolled in course (200 OK)
	        //stubInstanceId = '520003da969e4a6b029c1986';  // stub 11 
	        //stubInstanceId = '520a95f02d437ecd03269be8';  // stub 14 - User suspended       
	        //stubInstanceId = '520aa0892d437ef503269bea';  // stub 15 - User suspended / no attempt               
	        
	        //stubInstanceId = '5200e593e90a7bba00d817d0';  
	        //stubInstanceId = '5206dc0585dc563d00cbee70';    // stub - 400 Bad Request
	        //stubInstanceId = '5206e76885dc564600cbee72';    // stub - 401 Unauthorized
	        //stubInstanceId = '5206e6c985dc564600cbee71';    // stub - 408 Request Timeout                
	
	        // CD 31/10/13: Added security token logic 
	        String PSK = Webservice_URL__c.getValues('Moodle Real Time').PSK__c;
	        System.debug('PSK: ' + PSK);
	        
	        if (PSK == null)
	        {
	        	throw new FADMSException(ERR_PSK);
	        }
	        
	        String REQUEST_ID = generateGUID();
	        System.debug('REQUEST_ID: ' + REQUEST_ID);

	        if (REQUEST_ID == null)
	        {
	        	throw new FADMSException(ERR_RQID);
	        }
	        else if (REQUEST_ID.length() <= 0)
	        {
	        	throw new FADMSException(ERR_RQID);
	        }	        
	        
	        String SEC_TOKEN = generateSecurityToken(PSK, REQUEST_ID);
	        System.debug('SEC_TOKEN: ' + SEC_TOKEN);             		

	        if (SEC_TOKEN == null)
	        {
	        	throw new FADMSException(ERR_TOKEN);
	        }
	        else if (SEC_TOKEN.length() <= 0)
	        {
	        	throw new FADMSException(ERR_TOKEN);
	        }
	        
	        // Construct Stub Endpoint
	        //endpoint = stubDomain + stubInstanceId + '?fadmsid=' + getFadmsId() + '&requestid=' + REQUEST_ID + '&token=' + secToken;
	        
	        // Construct real Endpoint
	        endpoint = SVC_ENDPOINT + '?fadmsid=' + getFadmsId() + '&requestid=' + REQUEST_ID + '&token=' + SEC_TOKEN;              
	        
	        System.debug('endpoint: ' + endpoint);
        }
		catch (Exception e)
		{
			throw new FADMSException(e.getMessage());			
		}

        return endpoint;
    }

    // Build out details of request 
    global static HttpRequest buildWebServiceRequest()
    {
        System.debug('Method Called: buildWebServiceRequest');
        
        HttpRequest req = new HttpRequest();
        String serviceEndpoint = '';

        // Build Endpoint
        serviceEndpoint = buildEndpoint();
        
        // plug in headers - TBC
        // plug in security nodes - TBC

        // Construct Authorization and Content header
        req.setHeader('Content-Type', 'text/xml; charset=utf-8');
        // Set custom headers
        // msgid, system, userid, timestamp

        // Set Method and Endpoint and Body
        req.setEndpoint(serviceEndpoint);
        req.setMethod('GET');
        // req.setClientCertificateName('EFA_Training_Test_Certificate');

        // Set timeout in milliseconds (30 secs)
        req.setTimeout(30000); 

        // Set client certificate
        //req.setClientCertificateName('DocSampleCert');

        return req;
    }

    global static HttpResponse invokeWebService(Http http, HttpRequest req)  
    {
        System.debug('Method Called: invokeWebService');
    
        String ERR_400 = 'HTTP Status Code 400: Bad Request. An issue was encountered with the request.';
        String ERR_401 = 'HTTP Status Code 401: Unauthorized. User is unauthorised to use this service.';
        String ERR_408 = 'HTTP Status Code 408: Request Timeout. Request has timed out.';        

        HttpResponse res = new HttpResponse();
        Integer httpStatusCode = 0;
        String httpStatus = '';
        String resBody = '';

        try
        {
            // Send the request, and return a response
            res = http.send(req);

            // Get status details
            httpStatusCode = res.getStatusCode();
            httpStatus = res.getStatus();
            resBody = res.getBody();

            System.debug('CD - Response received:');
            System.debug(res.toString());   // displays status / code
            System.debug('CD - Response Body:');
            System.debug('\n\n' + resBody);

            System.debug('STATUS CODE:' + httpStatusCode);

            // Error handling for all HTTP statuses
            if (httpStatusCode == 200)
            {
                // do nothing
                //System.debug('if stamnt for HTTP 200');
            }
            else if (httpStatusCode == 400)
            {
                respErrorMessage += ERR_400; 
                throw new FADMSException(respErrorMessage);
            }
            else if (httpStatusCode == 401)
            {
                respErrorMessage += ERR_401; 
                throw new FADMSException(respErrorMessage);
            }            
            else if (httpStatusCode == 408)
            {
                respErrorMessage += ERR_408;
                throw new FADMSException(respErrorMessage);
            }
            else
            {
                respErrorMessage += 'HTTP Status Code: ' + httpStatusCode + '\n' + 'HTTP Status Description: ' + httpStatus;
                throw new FADMSException(respErrorMessage);
            }
        }
        catch (System.CalloutException e)
        {         
            System.debug('STATUS CODE:' + httpStatusCode);
            System.debug('STATUS:' + httpStatus);
            System.debug('Error Occurred:' + '[' + e.getMessage() +' ]');
            throw new FADMSException(e.getMessage());
        }

        return res;
    }
    
    // Processes Web Service Response
    global static void handleWebServiceResponse(HttpResponse res, String command)
    {
        String SUSPENDED = 'Suspended';
        String ERR_USR_NO_GRADES = 'No Grades currently exist for this user.';
    
        try
        {
            System.debug('Method Called: handleWebServiceResponse');
            
            // Parse and apply logic to the res message                 
            Dom.Document doc = res.getBodyDocument();
    
            Dom.XMLNode rootnode = doc.getRootElement();

            // Process everything
            System.debug('Processing XML...' + '\n');

            // Instantiate new class list
            trainingAttempts = new List<Attempt>();

            parseResponse(rootnode);
            
            //System.debug('Attempts List size: ' + trainingAttempts.size());
            
            // Only perform data updates if valid xml data is returned
            if (validResponseFlg)
            {
                System.debug('A valid response with xml data was found');
                
                System.debug('command: ' + command);
                
                // Only Display data from service response for command Search
                if (command == 'Save')
                {    
                    // Only Upsert data for command Save
                    // Perform updates/upserts
                    Savepoint sp = Database.setSavepoint();
                    try {
                        updateStakeholder(getFadmsId());
                        
                        // Upsert Agent Training Detail/Attempt records
                        if (userAttemptCount > 0)
                        {
                            System.debug('Attempts count > 0. Proceeding to upsert Attempts...');
                            upsertAgentTrainingAttempts();
                        }
                    } catch (Exception e) {
                        Database.rollback(sp);
                        throw new FADMSException(e.getMessage());
                        return;
                    }
                }
                
                // Throw error back to user on screen if user is suspended
                if (userStatus == SUSPENDED)
                {
                    System.debug('Suspended user was processed - now displaying msg to user...');
                    throw new FADMSException(respErrorMessage);
                }

                if (userAttemptCount <= 0)
                {
                    // Set user msg to no grades exist msg    
                    respErrorMessage = ERR_USR_NO_GRADES;
                    System.debug('User was processed but has no grades - now displaying msg to user...');
                    //throw new FADMSException(respErrorMessage);                    
                }                
            }
            else
            {   
                //System.debug('No valid response with xml data was found');        
                throw new FADMSException(respErrorMessage);
            }       
        }
        catch (Exception e)
        {
            System.debug('Error Occurred:' + '[' + e.getMessage() +' ]');
            throw new FADMSException(e.getMessage());
        }
    }

    // Processes the xml response
    global static void parseResponse(Dom.XMLNode node) 
    {
        //System.debug('Method Called: parseResponse');
        
        String ERR_USR_SUSPENDED = 'The user matching the FADMSID is suspended in Moodle.';
        String SUSPENDED = 'Suspended';
        
        // TEMP - Holds fadms id in resp - NOT USED
        String tempFadmsId = '';

        //System.debug('Node Name: ' + node.getName());
        //System.debug('Node Type: ' + node.getNodeType());

        // Set class var validResponseFlg to true by default
        validResponseFlg = true;

        try
        {
            if (node.getNodeType() == Dom.XMLNodeType.ELEMENT) 
            {                   
                if (node.getName() == 'User')
                {
                    System.debug('\n\n');
                    
                    tempFadmsId = node.getChildElement('FadmsElectorId', null).getText();
                    System.debug('tempFadmsId: ' + tempFadmsId);
                    
                    // Set class field
                    userOutcome = node.getChildElement('OfficialAgentTrainingResultOutcome', null).getText();
                    System.debug('OfficialAgentTrainingResultOutcome: ' + userOutcome);
                    
                    // Set class field
                    userStatus = node.getChildElement('Status', null).getText();
                    System.debug('Status: ' + userStatus);
                    
                    // If User Status = 'Suspended' - populate class var for output to user
                    if (userStatus == SUSPENDED)
                    {
                        respErrorMessage = ERR_USR_SUSPENDED;
                        System.debug('User Status - user suspended in Moodle');
                        System.debug('Response Message: ' + respErrorMessage);
                    }
                }
    
                if (node.getName() == 'Attempts')
                {
                    if (node.getAttributeCount() > 0) 
                    { 
                        // Store attribute count for class
                      userAttemptCount = Integer.valueOf(node.getAttributeValue(node.getAttributeKeyAt(0), node.getAttributeKeyNsAt(0)));     
                      System.debug('Attempts - Count: ' + userAttemptCount);
                    }
                }

                if (node.getName() == 'Attempt')
                {   
                    // Get xml data
                    Attempt atmpt = new Attempt();
                    
                    // Parse and extract resp data
                    atmpt.getXMLData(node);
                    
                    // Add to class attempt list
                    trainingAttempts.add(atmpt);
                }
            
                // Handling HTTP 200 responses with no data (contains message node)
                if (node.getName() == 'Message')
                {   
                    //System.debug('Found a message node!!!');
                    
                    // Catch message and populate class var for output to user
                    //respErrorMessage += node.getText();
                    respErrorMessage = node.getText();
                    System.debug('Response Message: ' + respErrorMessage);
                    
                    validResponseFlg = false;
                    System.debug('validResponseFlg: false');
                }

                // Loop through all child nodes (if some exist)     
                for (Dom.XMLNode child: node.getChildElements()) 
                {
                    if (node.getNodeType() == Dom.XMLNodeType.ELEMENT)
                    { 
                        parseResponse(child);
                    }
                }
            }           
        }
        catch (Exception e)
        {
            System.debug('Error Occurred:' + '[' + e.getMessage() +' ]');
            throw new FADMSException(e.getMessage());
        }
    }

    // Update method
    // Vinh modified the query: add Online_Training_Attempt_Count__c
    global static void updateStakeholder(String inputFadmsId)
    {
        System.debug('Method Called: updateStakeholder');
		
        // Select account to update (acct in context)
        List<Account> curAcctList = [SELECT Id, 
                                  FADMS_Elector_ID__c, 
                                  Online_Training_Result_Outcome__c, 
                                  Online_Training_User_Status__c,
                           		  Online_Training_Attempt_Count__c
                           FROM Account 
                           WHERE FADMS_Elector_ID__c = :inputFadmsId LIMIT 1];
		if (curAcctList.size() ==0 ) return;
        
        Account curAcct = curAcctList[0];
        // Store acctID against class for use with upsert
        acctId = curAcct.Id;    

        // Update account with DML stmnt - use class fields as source fields 
        curAcct.Online_Training_Result_Outcome__c = userOutcome;
        curAcct.Online_Training_User_Status__c = userStatus;
        curAcct.Online_Training_Attempt_Count__c = userAttemptCount;

        System.debug('Attempting to update Account with Acct ID: ' + acctId + ' and Fadms ID: ' + inputFadmsId);
        System.debug('Account field values to update with:' + '\n');    
        System.debug('User Outcome: ' + userOutcome);   
        System.debug('User Status: ' + userStatus);

        try 
        {
            // Update existing account
            update curAcct;
            
            System.debug('Account with Fadms ID: ' + inputFadmsId + ' updated successfully');
        } 
        catch (DmlException e)
        {
            System.debug('Account not updated.');   
            System.debug('Error Occurred:' + '[' + e.getMessage() +' ]');
            throw new FADMSException(e.getMessage());
        }
    }
    
    global static String generateGUID()
    {
        System.debug('Method Called: generateGUID');
		
		String guid = '';				
		
        try 
        {       
			Blob b = Crypto.GenerateAESKey(128);
			String h = EncodingUtil.ConvertTohex(b);
			guid = h.SubString(0,8) + '-' + h.SubString(8,12) + '-' + h.SubString(12,16) + '-' + h.SubString(16,20) + '-' + h.substring(20);
			System.debug('guid: ' + guid);
        } 
        catch (Exception e)
        {
            throw new FADMSException(e.getMessage());
        }              
                
        return guid;
    }
    
    global static String generateSecurityToken(String psk, String requestId)
    {
        System.debug('Method Called: generateSecurityToken');
		
		// Token Formula:
		// SHA1(psk+requestId)
		
		String ALGORITHM = 'SHA1';
			
		String algoInput = '';
		String secToken = '';
		
        try 
        {       
			algoInput = psk + requestId;
			System.debug('psk: ' + psk);
			System.debug('requestId: ' + requestId);
			System.debug('algoInput: ' + algoInput);        	
        	 						
			secToken = EncodingUtil.convertToHex(Crypto.generateDigest(ALGORITHM, Blob.valueOf(algoInput)));
			System.debug('secToken: ' + secToken);
        } 
        catch (Exception e)
        {
            throw new FADMSException(e.getMessage());
        }        
        
        return secToken;
    }    

    // Upsert Agent Training Attempts
    global static void upsertAgentTrainingAttempts()
    {
        System.debug('Method Called: upsertAgentTrainingAttempts');
        
        // Create an array of online training records
        Online_Training__c[] upsertAttemptsList = new Online_Training__c[]{};
        
        // Loop thru our class list of training attempts and add an array item for each training record
        for (Attempt tempAttempt : trainingAttempts)
        {                               
            Online_Training__c attempt = new Online_Training__c(Stakeholder__c = acctId,
                                                                Attempt_Id__c = tempAttempt.attemptId,
                                                                Name = tempAttempt.attemptId,
                                                                Attempt_Number__c = tempAttempt.attemptNumber,
                                                                Started__c = tempAttempt.startedDt,
                                                                Time_Taken__c = tempAttempt.timeTaken,
                                                                Completed__c = tempAttempt.completedDt,
                                                                Marks__c = tempAttempt.marks,
                                                                Grade__c = tempAttempt.grade,
                                                                Outcome__c = tempAttempt.gradeOutcome);
                                                                
            // Add current Attempt details rec (from class attempts list) to the attempts array 
            upsertAttemptsList.add(attempt);
        }

        System.debug('Attempting to upsert Online Training Detail records for Account with Fadms ID:' + getFadmsId());

        try 
        {
            // Upsert all Attempts using Attempt Id as key
            upsert upsertAttemptsList Attempt_Id__c;
            
            System.debug('Account Training Details for Account with Fadms ID: ' + getFadmsId() + ' upserted successfully');
        }    
        catch (DmlException e)
        {
            System.debug('Account Training Details not upserted - error occurred');
            System.debug('Error Occurred:' + '[' + e.getMessage() +' ]');
            throw new FADMSException(e.getMessage());
        }       
    }
	
    // Vinh added 16/08/2013: Wrapper to return more data (instead a list of attemp)
    global class retWrapper {
        List<Attempt> trainingAttemptsInWrap {get;set;}
        public String userOutcomeInWrap{get;set;}
        public String userStatusInWrap{get;set;}
        public Integer userAttemptCountInWrap{get;set;}
    }
    // Helper inner class to retrieve data from xml response
    global class Attempt 
    {
        public String attemptId {get;set;}
        public Integer attemptNumber {get;set;}
        public String dateStarted {get;set;}
        public String timeTaken {get;set;}
        public String dateCompleted {get;set;}
        public Integer marks {get;set;}
        public Decimal grade {get;set;}
        public String gradeOutcome {get;set;}
        public Datetime startedDt;
        public Datetime completedDt;

        public void getXMLData(Dom.XmlNode node) 
        {
            System.debug('Method Called: Attempt.getXMLData');

            if (node.getAttributeCount() > 0) 
            {
                // Get attribute attemptId
                attemptId = node.getAttributeValue(node.getAttributeKeyAt(0), node.getAttributeKeyNsAt(0));
            }

            // Get data
            attemptNumber = Integer.valueOf(node.getChildElement('AttemptNumber', null).getText());
            dateStarted = node.getChildElement('Started', null).getText();
            timeTaken = node.getChildElement('TimeTaken', null).getText();
            dateCompleted = node.getChildElement('Completed', null).getText();
            marks = Integer.valueOf(node.getChildElement('Marks', null).getText());
            //grade = Integer.valueOf(node.getChildElement('Grade', null).getText());
            grade = Decimal.valueOf(node.getChildElement('Grade', null).getText());            
            gradeOutcome = node.getChildElement('GradeOutcome', null).getText();
            // convert to date format ready for upsert
            //System.debug('Converting startedDt...');
            startedDt = getFormattedDate(dateStarted);
            //System.debug('Converting completedDt...');
            completedDt = getFormattedDate(dateCompleted);
        }
        
        // Convert date to SF format
        public Datetime getFormattedDate(String inputDt)
        {
            // Source format: 2012-12-24T10:30:00
            // Target format: SF Date
            
            // Vars
            Integer day;
            Integer month;
            Integer year;
            Integer hours;
            Integer mins;
            Integer secs;
            
            // Objects
            Datetime outputDt;

            day = Integer.valueOf(inputDt.substring(8, 10)); 
            month = Integer.valueOf(inputDt.substring(5, 7));
            year = Integer.valueOf(inputDt.substring(0, 4));
            hours = Integer.valueOf(inputDt.substring(11, 13));
            mins = Integer.valueOf(inputDt.substring(14, 16));
            secs = Integer.valueOf(inputDt.substring(17, 19));

            System.debug('Date format before: ' + inputDt);

            System.debug('day: ' + day);
            System.debug('month: ' + month);
            System.debug('year: ' + year);
            System.debug('hours: ' + hours);
            System.debug('mins: ' + mins);
            System.debug('secs: ' + secs);
            
            outputDt = datetime.newInstance(year, month, day, hours, mins, secs);
            
            return outputDt;
        }
        
    }// end inner class   
    
}