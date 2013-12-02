global class RetrieveAgentsBatch implements Schedulable 
{
    // Method Properties
    // List of Agents/Stakeholders
    global static List<Agent> agents = new List<Agent>();
    global static Datetime batchFromDt;
    global static Datetime batchToDt;
    global static Integer userCount;

    global static String respErrorMessage = 'Integration Error: ';
    global static boolean validResponseFlg;
    
    // Endpoint   
    // Change hardcode URL to custom setting url
    private static final String SVC_ENDPOINT = Webservice_URL__c.getValues('Moodle Batch').URL__c;

    global void execute(SchedulableContext ctx)
    {
        System.debug('Method Called: SchedulableContext');   
        
        try
        {
            retrieveMoodleData();
        }
        catch (Exception e)
        {
            System.debug('Error Occurred:' + '[' + e.getMessage() +' ]');
            throw new FADMSException(e.getMessage());
        }       
    }
 
    @future(callout=true)
    global static void retrieveMoodleData()
    {        
        System.debug('Method Called: retrieveMoodleData');
        
        String status = 'Success';
        Datetime batchFromDate;
        //Datetime batchToDate = null;  // not used atm
        String errorDesc = '';
        
        try
        {
            // Get batch from date
            batchFromDate = getBatchFromDate();
            
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            HttpResponse res = new HttpResponse();      

            // Build rq
            req = buildWebServiceRequest(batchFromDate);

            // Invoke svc
            res = invokeWebService(http, req);
    
            // Process res
            handleWebServiceResponse(res);
        }
        catch (Exception e)
        {   
            status = 'Failure';
            errorDesc = e.getMessage();         

            System.debug('Error Occurred:' + '[' + e.getMessage() +' ]');            
            //throw new FADMSException(e.getMessage());
        }
        finally
        {
            // Create new Moodle Batch Log entry
            createBatchLogEntry(status, batchFromDate, batchToDt, errorDesc);
        }
    }

    global static String buildEndpoint(Datetime batchFromDate)
    {  
        System.debug('Method Called: buildEndpoint');

        String ERR_PSK = 'PSK was not supplied.';
        String ERR_RQID = 'RequestId was not supplied.';
        String ERR_TOKEN = 'Token was not supplied.';
        String MODE = 'LastRunDate';
        String batchFromDateStr = '';
        String endpoint = '';
        // Sample real endpoint: 
        // http://training.efa.nsw.gov.au/test/local/trainingrecords/fadmsindex.php?

        // Stub setup
        String stubDomain = 'http://www.mocky.io/v2/';
        String stubInstanceId = '';

        try
        {
            // Set stub instance
            //stubInstanceId = '522ebf574034866e00d9e352';  // 1 user
            //stubInstanceId = '522eb5dc4034864a00d9e34d';  // 1 user - Salma Landy
            stubInstanceId = '52308ce8fd83b35c01fd862b';         
                        
            //stubInstanceId = '522ebcb34034865c00d9e34f';  // 2 users
            //stubInstanceId = '522e4d59fdddc95d03ae96e9';  // no user data
            //stubInstanceId = '522e525cfdddc96f03ae96eb';  // user with no attempt data
            
            //stubInstanceId = '522ee976403486de00d9e357';  // 10 new users         
            
            //stubInstanceId = '522edab8403486b300d9e355';    // stub - 200 Heap size exceeded             
            
            //stubInstanceId = '522c5364925e658800ea7319';    // stub - 400 Bad Request
            //stubInstanceId = '5206e76885dc564600cbee72';    // stub - 401 Unauthorized
            //stubInstanceId = '522ec0734034867100d9e353';    // stub - 408 Request Timeout       
    
            // Transform batchFromDate to service input format
            batchFromDateStr = getMoodleFormattedDate(batchFromDate);
            System.debug('batchFromDateStr: ' + batchFromDateStr);
            
            if (batchFromDateStr == '')
            {
                throw new FADMSException('An unexpected error occurred with processing the Batch From Date.');
            }

	        // CD 7/11/13: Added security token logic 
	        String PSK = Webservice_URL__c.getValues('Moodle Batch').PSK__c;
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
            //endpoint = stubDomain + stubInstanceId + '?mode=' + MODE + '&batchFromDt=' + batchFromDateStr;
            //endpoint = stubDomain + stubInstanceId + '?mode=' + MODE + '&batchFromDt=' + batchFromDateStr + '&requestid=' + REQUEST_ID + '&token=' + SEC_TOKEN;
    
            // Construct real Endpoint
            //endpoint = SVC_ENDPOINT + '?mode=' + MODE + '&batchfromdt=' + batchFromDateStr;
            endpoint = SVC_ENDPOINT + '?mode=' + MODE + '&batchfromdt=' + batchFromDateStr + '&requestid=' + REQUEST_ID + '&token=' + SEC_TOKEN;
                                    
            System.debug('SVC_ENDPOINT: ' + SVC_ENDPOINT);
            System.debug('endpoint: ' + endpoint);  
        }
        catch (Exception e)
        {
            System.debug('Error Occurred:' + '[' + e.getMessage() +' ]');
            throw new FADMSException(e.getMessage());
        }   

        return endpoint;
    }

    // Convert SF date to service input format
    global static String getMoodleFormattedDate(Datetime inputDt)
    {
        System.debug('Method Called: getMoodleFormattedDate');

        // Source format: SF Datetime
        // Target format: YYYY-MM-DD (eg. 2012-12-24)

        String day = '';
        String month = '';
        String year = '';
        
        String dateStr = '';

        try
        {       
            day = string.valueof(inputDt.day());
            month = string.valueof(inputDt.month());
            year = string.valueof(inputDt.year());

            if (day.length() <= 1)
            {
                day = '0' + day; 
            }
            
            if (month.length() <= 1)
            {
                month = '0' + month; 
            }        

            System.debug('day: ' + day);
            System.debug('month: ' + month);
            System.debug('year: ' + year);
            
            dateStr = year + '-' +  month + '-' + day;
        }
        catch (Exception e)
        {
            System.debug('Error Occurred:' + '[' + e.getMessage() +' ]');
            throw new FADMSException(e.getMessage());
        }           
            
        return dateStr;
    }

    global static Datetime getBatchFromDate()
    {
        System.debug('Method Called: getBatchFromDate');
        
        Datetime batchFromDate;
        
        try
        {
            List<Moodle_Batch_Log__c> batLog = [SELECT Id,
                                                       Batch_Run_Date__c
                                                FROM Moodle_Batch_Log__c 
                                                WHERE Status__c = 'Success'
                                                ORDER BY Batch_Run_Date__c DESC LIMIT 1];
            
            // Check results and if none - set batchFromDate to 01/01/1900
            if (batLog.size() > 0)
            {
                System.debug('A valid Moodle Batch Log rec was found');
                batchFromDate = batLog[0].Batch_Run_Date__c;
            }
            else
            {
                System.debug('No valid Moodle Batch recs found. Setting Batch From Date to 01/01/1900');
                batchFromDate = datetime.newInstance(1900, 01, 01);
            }           
        }
        catch (DmlException e)
        {
            System.debug('Error Occurred:' + '[' + e.getMessage() +' ]');
            throw new FADMSException(e.getMessage());
        }

        return batchFromDate;
    }
 
    public static void createBatchLogEntry(String status, Datetime fromDate, Datetime toDate, String errorDesc)
    {
        System.debug('Method called: createBatchLogEntry');
        
        // Set fromDate time component in Moodle Batch Log to start of day 
        Datetime upsertFromDate = datetime.newInstance(fromDate.year(), fromDate.month(), fromDate.day(), 0, 0, 0);
        
        Moodle_Batch_Log__c batLog = new Moodle_Batch_Log__c();             
                
        batLog.Status__c = status;  
        batLog.Batch_Run_Date__c = Datetime.now();
        batLog.Batch_From_Date__c = upsertFromDate;
        batLog.Batch_To_Date__c = toDate;
        batLog.Error_Description__c = errorDesc;
        
        try
        {
            insert batLog;
        }
        catch (DmlException e)
        {
            System.debug('Moodle Batch Log entry not inserted.');   
            System.debug('Error Occurred:' + '[' + e.getMessage() +' ]');
            throw new FADMSException(e.getMessage());
        }
        
        System.debug('Moodle Batch Log entry inserted.');
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

    // Build out details of request 
    global static HttpRequest buildWebServiceRequest(Datetime batchFromDate)
    {
        System.debug('Method Called: buildWebServiceRequest');

        String serviceEndpoint = '';        
        HttpRequest req = new HttpRequest();

        try
        {
            // Build Endpoint
            serviceEndpoint = buildEndpoint(batchFromDate);
               
            // Construct Authorization and Content header
            req.setHeader('Content-Type', 'text/xml; charset=utf-8');
            req.setHeader('Content-Encoding', 'gzip');
			req.setHeader('Accept-Encoding', 'gzip');
    
            // Set Method and Endpoint and Body
            req.setEndpoint(serviceEndpoint);
            req.setMethod('GET');
    
            // Set timeout in milliseconds (60 secs)
            req.setTimeout(60000); 

            // Turn compression on
            req.setCompressed(true);
    
            // Set client certificate
            //req.setClientCertificateName('DocSampleCert');
        }
        catch (Exception e)
        {
            System.debug('Error Occurred:' + '[' + e.getMessage() +' ]');
            throw new FADMSException(e.getMessage());
        }        

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
    global static void handleWebServiceResponse(HttpResponse res)
    {
        System.debug('Method Called: handleWebServiceResponse');        
    
        try
        {
        	System.debug('Displaying headers received... ');
        	//get the list of header names (keys)
        	String[] headerkeys = res.getHeaderKeys();        	
        	
        	// Iterate through the headers
        	for (String stemp : headerkeys)
        	{
        		if (stemp != null)
        		{
        			system.debug('header: ' + stemp + ' value: ' + res.getHeader(stemp));
        		}
        	}
        	
            // Parse and apply logic to the res message                 
            Dom.Document doc = res.getBodyDocument();
               		
            Dom.XMLNode rootnode = doc.getRootElement();

            // Process everything
            System.debug('Processing XML...' + '\n');
            
            // Instantiate new class list of Users
            agents = new List<Agent>();            

            parseResponse(rootnode);
            
            System.debug('Agents List size: ' + agents.size());
                        
            // Only perform data updates if valid xml data is returned
            if (validResponseFlg)
            {
                System.debug('A valid response with xml data was found');          
   
                if (userCount > 0)
                {
                    try 
                    {
                        upsertStakeholders();                   
                    } 
                    catch (Exception e) 
                    {                    
                        throw new FADMSException(e.getMessage());
                    }  
                }
            }
            else
            {   
                System.debug('No valid response with xml data was found');        
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
        
        //System.debug('Node Name: ' + node.getName());
        //System.debug('Node Type: ' + node.getNodeType());

        String fromDate = '';
        String toDate = '';

        // Set class var validResponseFlg to true by default
        validResponseFlg = true;

        try
        {
            if (node.getNodeType() == Dom.XMLNodeType.ELEMENT) 
            {         
                //if (node.getName() == '')
                if (node.getName() == 'BatchFromDt')                
                {
                    // Store date for class                  
                    fromDate = node.getText();  
                    System.debug('fromDate: ' + fromDate);
                                        
                    // CD 20/10/13: Added check for empty string
                    if (fromDate != '')
                    {
                    	batchFromDt = getFormattedDateTime(fromDate);
                    }
                }                   
                                          
                if (node.getName() == 'BatchToDt')
                {
                    // Store date for class                  
                    toDate = node.getText();  
                    System.debug('toDate: ' + toDate);      
                                       
                    // CD 20/10/13: Added check for empty string
                    if (toDate != '')
                    {
                    	batchToDt = getFormattedDateTime(toDate);
                    }                                
                }                                         
                                          
                if (node.getName() == 'Users')
                {
                    if (node.getAttributeCount() > 0) 
                    { 
                        // Store attribute user count for class
                        userCount = Integer.valueOf(node.getAttributeValue(node.getAttributeKeyAt(0), node.getAttributeKeyNsAt(0)));     
                        System.debug('userCount: ' + userCount);
                    }
                }               
                
                if (node.getName() == 'User')
                {
                    // Get xml data
                    Agent agent = new Agent();
                                        
                    // Parse and extract resp data
                    agent.getAgentXMLData(node);
                    
                    // Add to class agents list
                    agents.add(agent);
                }
            
                // Handling HTTP 200 responses with no data (contains message node)
                if (node.getName() == 'Message')
                {   
                    System.debug('Found a message node!!!');
                    
                    // Catch message and populate class var for output to user
                    respErrorMessage += node.getText();
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

    // Upsert method
    global static void upsertStakeholders()
    {
        System.debug('Method Called: upsertStakeholders');

        ID acctId;
        Account stakeholder;    
           
        // Loop thru our class list of Agents and upsert each one individually 
        for (Agent tempAgent : agents)
        {               
            // Perfrom a SOQL query to determine if agent exists already
            List<Account> stakeholderList = [Select Id 
                                             FROM Account
                                             WHERE FADMS_Elector_ID__c = :tempAgent.fadmsId];
                                    
            if (stakeholderList.size() > 0)
            {
                System.debug('Stakeholder with FADMS ID: ' + tempAgent.fadmsId + ' already exists.');
                
                // Only upsert Agent Training Data related user fields from Moodle
                stakeholder = new Account(FADMS_Elector_ID__c = tempAgent.fadmsId,
                                                  Online_Training_Result_Outcome__c = tempAgent.userOutcome,
                                                  Online_Training_User_Status__c = tempAgent.userStatus,
                                                  Online_Training_Attempt_Count__c = tempAgent.attemptCount);                   
            }
            else
            {
                System.debug('Stakeholder with FADMS ID: ' + tempAgent.fadmsId + ' does not exist.');
                
                // Upsert all user fields from Moodle
                stakeholder = new Account(FADMS_Elector_ID__c = tempAgent.fadmsId,
                                                  FirstName = tempAgent.firstName,
                                                  LastName = tempAgent.lastName,
                                                  PersonBirthdate = tempAgent.dobDt,
                                                  PersonEmail = tempAgent.email,
                                                  Occupation__c = tempAgent.occupation,
                                                  Phone = tempAgent.phone,
                                                  PersonMobilePhone = tempAgent.mobile,
                                                  Fax = tempAgent.fax,
                                                  ShippingCity = tempAgent.postalLocality,
                                                  ShippingStreet = tempAgent.postalAddress,
                                                  ShippingPostalCode = tempAgent.postCode,
                                                  // ER fields
                                                  PersonMailingCity = tempAgent.erLocality,
                                                  PersonMailingStreet = tempAgent.erAddress,
                                                  PersonMailingPostalCode = tempAgent.erPostCode,
                                                  Online_Training_Result_Outcome__c = tempAgent.userOutcome,
                                                  Online_Training_User_Status__c = tempAgent.userStatus,
                                                  Online_Training_Attempt_Count__c = tempAgent.attemptCount);               
            }                                  
                                                      
            System.debug('Attempting to upsert Stakeholder with FADMS ID:' + stakeholder.FADMS_Elector_ID__c);

            // Create save Point
            Savepoint sp = Database.setSavepoint();
    
            try 
            {
                // Upsert each SH by itself using FADMS ID as key
                upsert stakeholder FADMS_Elector_ID__c;
            }
            catch (DmlException e)
            {
                System.debug('Stakeholder not upserted - error occurred');
                System.debug('Error Occurred:' + '[' + e.getMessage() +' ]');
                Database.rollback(sp);
                throw new FADMSException(e.getMessage());
            }                 
            
            // Get acctId
            acctId = stakeholder.Id;
            
            System.debug('Stakeholder with Fadms ID: ' + stakeholder.FADMS_Elector_ID__c + ' upserted successfully');
            
            // Now upsert all the attempts for this 1 stakeholder
            // Upsert Agent Training Detail/Attempt records
            if (tempAgent.attemptCount > 0)
            {
                System.debug('Attempts count > 0. Proceeding to upsert Attempts for Stakeholder with Fadms ID: ' + stakeholder.FADMS_Elector_ID__c);
                upsertAgentTrainingAttempts(acctId, tempAgent.trainingAttempts);
            }
        }        
    }

    // Upsert Agent Training Attempts
    global static void upsertAgentTrainingAttempts(ID acctId, List<Attempt> trainingAttempts)
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

        System.debug('Attempting to upsert Online Training Detail records for Account ID:' + acctId);

        // Create save Point
        Savepoint sp = Database.setSavepoint();

        try 
        {
            // Upsert all Attempts using Attempt Id as key
            upsert upsertAttemptsList Attempt_Id__c;
            
            System.debug('Account Training Details for Account ID: ' + acctId + ' upserted successfully');
        }    
        catch (DmlException e)
        {
            System.debug('Account Training Details not upserted - error occurred');
            System.debug('Error Occurred:' + '[' + e.getMessage() +' ]');
            
            Database.rollback(sp);
            
            throw new FADMSException(e.getMessage());
        }       
    }  

    // Convert date to SF format
    global static Datetime getFormattedDateTime(String inputDt)
    {
        System.debug('Method Called: Attempt.getFormattedDateTime');
        
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

        try
        {
        	System.debug('Date format before: ' + inputDt);
        	
            day = Integer.valueOf(inputDt.substring(8, 10)); 
            System.debug('LINE 1');
            month = Integer.valueOf(inputDt.substring(5, 7));
            System.debug('LINE 2');
            year = Integer.valueOf(inputDt.substring(0, 4));
            System.debug('LINE 3');
            hours = Integer.valueOf(inputDt.substring(11, 13));
            System.debug('LINE 4');
            mins = Integer.valueOf(inputDt.substring(14, 16));
            System.debug('LINE 5');
            secs = Integer.valueOf(inputDt.substring(17, 19));
            System.debug('LINE 6');

            System.debug('day: ' + day);
            System.debug('month: ' + month);
            System.debug('year: ' + year);
            System.debug('hours: ' + hours);
            System.debug('mins: ' + mins);
            System.debug('secs: ' + secs);
            
            outputDt = datetime.newInstance(year, month, day, hours, mins, secs);
        }
        catch (Exception e)
        {
            System.debug('Error Occurred:' + '[' + e.getMessage() +' ]');
            throw new FADMSException(e.getMessage());
        }           
        
        return outputDt;
    }

    // Helper inner class to retrieve user data from xml response
    global class Agent 
    {
        // User fields
        public String userId {get;set;}     // not used
        public String fadmsId {get;set;}
        public String firstName {get;set;}
        public String lastName {get;set;}
        public String dob {get;set;}
        public Date dobDt {get;set;}        
        public String email {get;set;}
        public String occupation {get;set;}
        public String phone {get;set;}
        public String mobile {get;set;}
        public String fax {get;set;}
        public String postalLocality {get;set;}
        public String postalAddress {get;set;}
        public String postCode {get;set;}
        public String erLocality {get;set;}
        public String erAddress {get;set;}
        public String erPostCode {get;set;}
        public String userOutcome {get;set;}
        public String userStatus {get;set;}

        // List of Attempts
        public List<Attempt> trainingAttempts {get;set;}

        // Attempt fields
        public Integer attemptCount;

        public void getAgentXMLData(Dom.XmlNode node) 
        {
            System.debug('Method Called: MoodleUser.getAgentXMLData');

            try
            {
                if (node.getAttributeCount() > 0) 
                {
                    // Get UserId
                    userId = node.getAttributeValue(node.getAttributeKeyAt(0), node.getAttributeKeyNsAt(0));
                }

                // Get data
                fadmsId = node.getChildElement('FadmsElectorId', null).getText();
                firstName = node.getChildElement('FirstName', null).getText();
                lastName = node.getChildElement('LastName', null).getText();
                dob = node.getChildElement('DateOfBirth', null).getText();
                email = node.getChildElement('Email', null).getText();
                occupation = node.getChildElement('Occupation', null).getText();
                phone = node.getChildElement('Phone', null).getText();
                mobile = node.getChildElement('Mobile', null).getText();
                fax = node.getChildElement('Fax', null).getText();
                postalLocality = node.getChildElement('PostalLocality', null).getText();
                postalAddress = node.getChildElement('PostalAddress', null).getText();
                postCode = node.getChildElement('PostCode', null).getText();
                erLocality = node.getChildElement('ElectoralRollLocality', null).getText();
                erAddress = node.getChildElement('ElectoralRollAddress', null).getText();
                erPostCode = node.getChildElement('ElectoralRollPostCode', null).getText();
                userOutcome = node.getChildElement('OfficialAgentTrainingResultOutcome', null).getText();
                userStatus = node.getChildElement('Status', null).getText(); 

                System.debug('fadmsId: ' + fadmsId);
                System.debug('firstName: ' + firstName);
                System.debug('lastName: ' + lastName);
                System.debug('dob: ' + dob);
                System.debug('email: ' + email);
                System.debug('occupation: ' + occupation);
                System.debug('phone: ' + phone);
                System.debug('mobile: ' + mobile);
                System.debug('fax: ' + fax);
                System.debug('postLocality: ' + postalLocality);
                System.debug('postalAddress: ' + postalAddress);
                System.debug('postCode: ' + postCode);
                System.debug('erLocality: ' + erLocality);
                System.debug('erAddress: ' + erAddress);
                System.debug('erPostCode: ' + erPostCode);
                System.debug('userOutcome: ' + userOutcome);
                System.debug('userStatus: ' + userStatus);

                System.debug('Converting DOB...');
                dobDt = getFormattedDate(dob);

                // Instantiate new class list
                trainingAttempts = new List<Attempt>();
    
                parseAttemptsData(node);
            }
            catch (Exception e)
            {
                System.debug('Error Occurred:' + '[' + e.getMessage() +' ]');
                throw new FADMSException(e.getMessage());
            }            
        }
        
        // Processes the xml response
        public void parseAttemptsData(Dom.XMLNode node) 
        {
            //System.debug('Method Called: parseAttemptsData');
            
            //System.debug('Node Name: ' + node.getName());
            //System.debug('Node Type: ' + node.getNodeType());
    
            try
            {
                if (node.getNodeType() == Dom.XMLNodeType.ELEMENT) 
                {                   
                    if (node.getName() == 'Attempts')
                    {
                        if (node.getAttributeCount() > 0) 
                        { 
                            // Store attribute attempt count for class
                            attemptCount = Integer.valueOf(node.getAttributeValue(node.getAttributeKeyAt(0), node.getAttributeKeyNsAt(0)));     
                            System.debug('attemptCount: ' + attemptCount);
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

                    // Loop through all child nodes (if some exist)     
                    for (Dom.XMLNode child: node.getChildElements()) 
                    {
                        if (node.getNodeType() == Dom.XMLNodeType.ELEMENT)
                        { 
                            parseAttemptsData(child);
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
        
        // Convert date to SF format
        public Date getFormattedDate(String inputDt)
        {
            System.debug('Method Called: Agent.getFormattedDate');
            
            // Source format: 2012-12-24
            // Target format: SF Date
            
            // Vars
            Integer day;
            Integer month;
            Integer year;
            
            // Objects
            Date outputDt;

            try
            {
                day = Integer.valueOf(inputDt.substring(8, 10)); 
                month = Integer.valueOf(inputDt.substring(5, 7));
                year = Integer.valueOf(inputDt.substring(0, 4));
    
                System.debug('Date format before: ' + inputDt);
    
                System.debug('day: ' + day);
                System.debug('month: ' + month);
                System.debug('year: ' + year);
    
                outputDt = date.newinstance(year, month, day);
            }
            catch (Exception e)
            {
                System.debug('Error Occurred:' + '[' + e.getMessage() +' ]');
                throw new FADMSException(e.getMessage());
            }

            return outputDt;
        }                    
    }// end inner class    
    
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

            try
            {
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
                grade = Decimal.valueOf(node.getChildElement('Grade', null).getText());        
                gradeOutcome = node.getChildElement('GradeOutcome', null).getText();
                // convert to date format ready for upsert
                startedDt = getFormattedDateTime(dateStarted);
                completedDt = getFormattedDateTime(dateCompleted);
            }
            catch (Exception e)
            {
                System.debug('Error Occurred:' + '[' + e.getMessage() +' ]');
                throw new FADMSException(e.getMessage());
            }           
        }
        
    }// end inner class         
}