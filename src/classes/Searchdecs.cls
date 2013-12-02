@RestResource(urlMapping='/Searchdecs/*')
global class Searchdecs 
{
    public static String dataSetType;

    public static void setDataSetType(String dsType)
    {
        System.debug('Method called: setDataSetType');
        dataSetType = dsType;
    }
    
    public static String getDataSetType()
    {
        System.debug('Method called: getDataSetType');
        return dataSetType;
    }   

    @HttpGet
    global static List<sObject> doGet() 
    {
        System.debug('Method called: doGet');
        
        String DS_ERROR = 'Invalid service parameter DataSetType: ';
        
        RestRequest req = RestContext.request;
        RestResponse resp = RestContext.response;
    
        String status = 'Success';
        String dsType = '';
        String errorDesc = '';
        
        List<sObject> result;
        
        try
        {               
            // Get input rest parameters       
            setDataSetType(req.params.get('datasettype').toUpperCase());

            System.debug('dataSetType: ' + getDataSetType());

            dsType = getDataSetType();

            // Validate dataSetType
            if (dsType != 'XVW_CGP_EXPENSES' && dsType != 'XVW_DONATION_MADE' && dsType != 'XVW_DONATION_REC'
                    && dsType != 'XVW_DONOR_EXPENSES' && dsType != 'XVW_DONOR_REC' && dsType != 'XVW_FUNDRAISING'
                    && dsType != 'XVW_LOANS' && dsType != 'XVW_PARTY_SUBSCRIPT' && dsType != 'XVW_SMALL_DONATION'
                    && dsType != 'XVW_UNION_CGPD' && dsType != 'XVW_SUBMITTED_DOC' && dsType != 'XVW_REPORTPERIOD' 
                    && dsType != 'XVW_ELECTION_EVENT')
            {
                throw new FADMSException(DS_ERROR + dsType);
            }     
            
            result = retrieveData();
            
            // check the heap size at runtime
            //if (Limits.getHeapSize > 3000000) 
            //{
                // implement logic to reduce
                //createXMLAttachment();
            //}                         
            
            System.debug('Heapsize: ' + Limits.getHeapSize());                                                                                                                                             
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
            createBatchLogEntry('RETRIEVE', dsType, status, errorDesc);
        }        

        return result;
    }

    @HttpPut
    global static String doPut() 
    {
        System.debug('Method called: doPut');
        
        String DS_ERROR = 'Invalid service parameter DataSetType: ';
        
        RestRequest req = RestContext.request;
        RestResponse resp = RestContext.response;

        String dsType = '';        
        String result = '';

        try
        {                
            // Get input rest parameters       
            setDataSetType(req.params.get('datasettype').toUpperCase());             

            System.debug('dataSetType: ' + getDataSetType());
    
            dsType = getDataSetType();

            // Validate dataSetType
            if (dsType != 'XVW_CGP_EXPENSES' && dsType != 'XVW_DONATION_MADE' && dsType != 'XVW_DONATION_REC'
                    && dsType != 'XVW_DONOR_EXPENSES' && dsType != 'XVW_DONOR_REC' && dsType != 'XVW_FUNDRAISING'
                    && dsType != 'XVW_LOANS' && dsType != 'XVW_PARTY_SUBSCRIPT' && dsType != 'XVW_SMALL_DONATION'
                    && dsType != 'XVW_UNION_CGPD' && dsType != 'XVW_SUBMITTED_DOC' 
                    && dsType != 'XVW_REPORTPERIOD' && dsType != 'XVW_ELECTION_EVENT' )
            {
                throw new FADMSException(DS_ERROR + dsType);
            }               

            result = processCallback(dsType);
        }
        catch (Exception e)
        {            
            System.debug('Error Occurred:' + '[' + e.getMessage() +' ]');
            throw new FADMSException(e.getMessage());
        }    
        
        return result;
    }
    
    // Retrieve method
    public static List<sObject> retrieveData()
    {
        System.debug('Method called: retrieveData');    

        String DS_ERROR = 'Invalid DataSetType: ';

        String dsType = getDataSetType();
        List<sObject> result;
    
        try
        {                                   
            if (dsType == 'XVW_CGP_EXPENSES')
            {
                result = processCGPExpensesQuery();
            }       
            else if (getDataSetType() == 'XVW_DONATION_MADE')
            {
                result = processDonationMadeQuery();
            }                   
            else if (dsType == 'XVW_DONATION_REC')
            {
                result = processDonationRecQuery();
            }               
            else if (dsType == 'XVW_DONOR_EXPENSES')
            {
                result = processDonorExpensesQuery();
            }               
            else if (dsType == 'XVW_DONOR_REC')
            {
                result = processDonorRecQuery();
            }               
            else if (dsType == 'XVW_FUNDRAISING')
            {
                result = processFundraisingQuery();
            }               
            else if (dsType == 'XVW_LOANS')
            {
                result = processLoansQuery();
            }               
            else if (dsType == 'XVW_PARTY_SUBSCRIPT')
            {
                result = processPartySubscriptQuery();
            }               
            else if (dsType == 'XVW_SMALL_DONATION')
            {
                result = processSmallDonationQuery();
            }               
            else if (dsType == 'XVW_UNION_CGPD')
            {
                result = processUnionCGPDQuery();
            }                       
            else if (dsType == 'XVW_SUBMITTED_DOC')
            {
                result = processSubmittedDocQuery();
            }             
            else if (dsType == 'XVW_REPORTPERIOD')
            {
                result = processReportPeriodQuery();
            }                       
            else if (dsType == 'XVW_ELECTION_EVENT')
            {
                result = processElectionEventQuery();
            }
            else
            {
                throw new FADMSException(DS_ERROR + dsType);
            }                                       
        }
        catch (Exception e)
        {
            System.debug('Error Occurred:' + '[' + e.getMessage() +' ]');
            throw new FADMSException(e.getMessage());            
        }
        
        // return data in object type as required
        return result;
    }    

    // Callback method
    public static String processCallback(String dsType)
    {       
        System.debug('Method called: processCallback');     

        String result = 'Success';
    
        try
        {                                               
            createBatchLogEntry('CALLBACK', dsType, 'Success', '');                                   
        }
        catch (Exception e)
        {
            result = 'Failure';
            
            System.debug('Error Occurred:' + '[' + e.getMessage() +' ]');
            throw new FADMSException(e.getMessage());            
        }
        
        return result;              
    }    

    public static List<Line_Item__c> processCGPExpensesQuery()
    {
        System.debug('Method called: processCGPExpensesQuery');
        
        List<Line_Item__c> qLineItemList;   
        Integer recCount = 0;
                
        try
        {               
            qLineItemList = [SELECT ID,    
                                    Line_Item_Type__r.SearchDecs_Type__c,
                                    //Published_Flag__c, //temp
                                    //Last_Published_Date__c, //temp
                                    //Updated_Since_Last_Published_Flg__c, //temp
                                    //LastModifiedDate, //temp
                                    //Line_Item_Status__c, //temp
                                    //Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Status__c, //temp
                                    //Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Reporting_Period__r.Publish_Date__c, // temp
                                    //Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Active__c, // temp
                                    // REPORTINGPERIOD_ID           
                                    Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Reporting_Period__r.SearchDecs_Reporting_ID__c,
                                    // EFID
                                    Line_Item_Type__r.Disclosure_Claim_for_Payment__c,                       
                                    // ID1
                                    Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Stakeholder__c,
                                    // DOCUMENTID
                                    Line_Item_Type__r.Disclosure_Claim_for_Payment__r.TRIM_Record_Number__c,
                                    // EXPENSELINENUMBER
                                    Name,
                                    // ELECTIONEXPENSETYPECODE / TYPEDESC - allows for detailed lookup of OTHER 
                                    Line_Item_Type__r.Line_Item_Category__r.Line_Item_Category__c, 
                                    Line_Item__c.Type_of_Expenditure__c,
                                    // EXPENSEBEGINDATE
                                    Expenditure_Incurred_From_Date__c,
                                    // SUPPLIERNAME
                                    Name_of_Supplier_or_Service_Provider__c,
                                    // EXPENSEDETAILS
                                    Product_or_Service_Provided__c,
                                    // EXPENSEAMOUNT
                                    Amount_Roll_Up__c,
                                    // REPORTINGBEGINDATE
                                    Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Reporting_Period__r.Date_From__c,
                                    // REPORTINGENDDATE
                                    Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Reporting_Period__r.Date_To__c
                            FROM    Line_Item__c 
                            WHERE   Line_Item_Type__r.SearchDecs_Type__c = 'XVW_CGP_EXPENSES'
                            AND     RecordType.Name = 'Line Item'
                            AND     Line_Item_Type__r.Disclosure_Claim_for_Payment__r.SearchDecs_DisclosureType__c <> ''
                            AND     Line_Item_Status__c <> 'Deletion'                             
                            AND     Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Active__c = true
                            AND     Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Status__c = 'Complete'                                                                            
                            AND     Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Reporting_Period__r.Publish_Date__c <= TODAY];

            recCount = qLineItemList.size();                    
            System.debug('recCount: ' + recCount);   
        }
        catch (DmlException e)
        {
            System.debug('Error Occurred:' + '[' + e.getMessage() +' ]');
            throw new FADMSException(e.getMessage());
        }                                                       
                    
        return qLineItemList;
    }

    public static List<Line_Item__c> processDonationMadeQuery()
    {
        System.debug('Method called: processDonationMadeQuery');    

        List<Line_Item__c> qLineItemList;
        Integer recCount = 0;

        try
        {               
            qLineItemList = [SELECT ID,    
                                    Line_Item_Type__r.SearchDecs_Type__c,
                                    //Published_Flag__c, //temp
                                    //Last_Published_Date__c, //temp
                                    //Updated_Since_Last_Published_Flg__c, //temp
                                    //LastModifiedDate, //temp
                                    //SearchDecs_Update_Difference__c, // temp
                                    //Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Status__c,
                                    //Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Reporting_Period__r.Publish_Date__c,
                                    //Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Registration__r.RecordType.Name,                                               
                                    // REPORTINGPERIOD_ID           
                                    Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Reporting_Period__r.SearchDecs_Reporting_ID__c,
                                    // EFID
                                    Line_Item_Type__r.Disclosure_Claim_for_Payment__c,                       
                                    // ID1
                                    Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Stakeholder__c,
                                    // DOCUMENTID
                                    Line_Item_Type__r.Disclosure_Claim_for_Payment__r.TRIM_Record_Number__c,
                                    // EXPENSELINENUMBER
                                    Name,
                                    // EXPENSETYPECODE
                                    Gift_Type__c,
                                    // EXPENSEBEGINDATE
                                    Date_Donation_was_made__c,
                                    // RECIPIENTEFID / ID2
                                    Stakeholder__c,
                                    // RECIPIENTTYPE
                                    Recipient_Type__c,
                                    // EXPENSEAMOUNT
                                    Amount_Roll_Up__c,
                                    // RECIPIENT
                                    Stakeholder__r.Name,
                                    // AREANAME
                                    Stakeholder_Registration__r.Election_Event1__r.Electorate__c,
                                    // AREACODE
                                    Stakeholder_Registration__r.Election_Event1__r.Electorate_Area_Code__c,                                    
                                    // ELEC_TYPE
                                    Stakeholder_Registration__r.Election_Event1__r.State_Election_Type__c,                                                  
                                    // REPORTINGBEGINDATE
                                    Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Reporting_Period__r.Date_From__c,
                                    // REPORTINGENDDATE
                                    Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Reporting_Period__r.Date_To__c
                            FROM    Line_Item__c 
                            WHERE   Line_Item_Type__r.SearchDecs_Type__c = 'XVW_DONATION_MADE'  
                            AND     RecordType.Name = 'Line Item'   
                            AND     Line_Item_Type__r.Disclosure_Claim_for_Payment__r.SearchDecs_DisclosureType__c <> ''                            
                            AND     Line_Item_Status__c <> 'Deletion'
                            AND     Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Active__c = true
                            AND     Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Status__c = 'Complete'
                            /////////////////////temp/////////////////////////////
                            //AND   Stakeholder_Registration__r.Election_Event1__r.State_Election_Type__c <> ''
                            //AND       Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Registration__r.RecordType.Name NOT IN ('Candidate', 'Group of Candidates', 'Elected Member')
                            //and       Stakeholder__r.RecordType.Name = 'Political Party'
                            //and       Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Registration__c = null
                            //AND       Recipient_Type__c = 'EFRECIPIENT'
                            //and       Stakeholder_Registration__r.Election_Event_Area_Code__c <> ''
                            //AND       Line_Item_Type__r.Disclosure_Claim_for_Payment__r.TRIM_Record_Number__c <> NULL
                            /////////////////////temp/////////////////////////////
                            AND     Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Reporting_Period__r.Publish_Date__c <= TODAY];                           
    
            recCount = qLineItemList.size();                    
            System.debug('recCount: ' + recCount);          
        }
        catch (DmlException e)
        {
            System.debug('Error Occurred:' + '[' + e.getMessage() +' ]');
            throw new FADMSException(e.getMessage());
        }        
                    
        return qLineItemList;
    }

    public static List<Line_Item__c> processDonationRecQuery()
    {
        System.debug('Method called: processDonationRecQuery');     

        List<Line_Item__c> qLineItemList;
        Integer recCount = 0;

        try
        {               
            qLineItemList = [SELECT ID,    
                                    Line_Item_Type__r.SearchDecs_Type__c,
                                    //Published_Flag__c, //temp
                                    //Last_Published_Date__c, //temp
                                    //Updated_Since_Last_Published_Flg__c, //temp
                                    //LastModifiedDate, //temp
                                    //SearchDecs_Update_Difference__c, // temp
                                    //Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Status__c,
                                    //Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Reporting_Period__r.Publish_Date__c,        
                                    // REPORTINGPERIOD_ID           
                                    Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Reporting_Period__r.SearchDecs_Reporting_ID__c,
                                    // EFID
                                    Line_Item_Type__r.Disclosure_Claim_for_Payment__c,                       
                                    // ID1
                                    Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Stakeholder__c,
                                    // DOCUMENTID
                                    Line_Item_Type__r.Disclosure_Claim_for_Payment__r.TRIM_Record_Number__c,
                                    // CONTRIBUTIONID / CONTRIBUTIONLINENUMBER
                                    Name,
                                    // DONOR_EFID / ID2
                                    Stakeholder__c,
                                    // AMOUNTDONATED
                                    Amount_Roll_Up__c,
                                    // DONATIONDATE
                                    Date_Donation_was_made__c,                                                                                                  
                                    // DONATIONTYPE
                                    Gift_Type__c,
                                    // DONOR NAME
                                    Stakeholder__r.Name,                                                    
                                    // REPORTINGBEGINDATE
                                    Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Reporting_Period__r.Date_From__c,
                                    // REPORTINGENDDATE
                                    Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Reporting_Period__r.Date_To__c
                            FROM    Line_Item__c 
                            WHERE   Line_Item_Type__r.SearchDecs_Type__c = 'XVW_DONATION_REC'   
                            AND     RecordType.Name = 'Line Item'   
                            AND     Line_Item_Type__r.Disclosure_Claim_for_Payment__r.SearchDecs_DisclosureType__c <> ''
                            AND     Line_Item_Status__c <> 'Deletion'                               
                            AND     Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Active__c = true
                            AND     Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Status__c = 'Complete'
                            /////////////////////temp/////////////////////////////
                            //AND       Gift_Type__c <> ''
                            /////////////////////temp/////////////////////////////
                            AND     Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Reporting_Period__r.Publish_Date__c <= TODAY];                               
    
            recCount = qLineItemList.size();                    
            System.debug('recCount: ' + recCount);
        }
        catch (DmlException e)
        {
            System.debug('Error Occurred:' + '[' + e.getMessage() +' ]');
            throw new FADMSException(e.getMessage());
        }         
                            
        return qLineItemList;
    }

    public static List<Line_Item__c> processDonorExpensesQuery()
    {
        System.debug('Method called: processDonorExpensesQuery');

        List<Line_Item__c> qLineItemList;
        Integer recCount = 0;

        try
        {               
            qLineItemList = [SELECT ID,    
                                    Line_Item_Type__r.SearchDecs_Type__c,
                                    //Published_Flag__c,
                                    //Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Status__c,
                                    //Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Reporting_Period__r.Publish_Date__c,
                                    // REPORTINGPERIOD_ID           
                                    Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Reporting_Period__r.SearchDecs_Reporting_ID__c,
                                    // EFID
                                    Line_Item_Type__r.Disclosure_Claim_for_Payment__c,                       
                                    // ID1
                                    Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Stakeholder__c,
                                    // DOCUMENTID
                                    Line_Item_Type__r.Disclosure_Claim_for_Payment__r.TRIM_Record_Number__c,                                        
                                    // EXPENSELINENUMBER
                                    Name,
                                    // EXPENSETYPECODE / TYPEDESC
                                    //Line_Item_Type__r.Line_Item_Category_Text__c,
                                    Line_Item_Type__r.Line_Item_Category__r.Line_Item_Category__c,
                                    // EXPENSEBEGINDATE
                                    Expenditure_Incurred_From_Date__c,
                                    // SUPPLIERNAME
                                    Name_of_Supplier_or_Service_Provider__c,
                                    // EXPENSEDETAILS
                                    Product_or_Service_Provided__c,
                                    // EXPENSEAMOUNT
                                    Amount_Roll_Up__c,                                                  
                                    // REPORTINGBEGINDATE
                                    Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Reporting_Period__r.Date_From__c,
                                    // REPORTINGENDDATE
                                    Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Reporting_Period__r.Date_To__c
                            FROM    Line_Item__c 
                            WHERE   Line_Item_Type__r.SearchDecs_Type__c = 'XVW_DONOR_EXPENSES' 
                            AND     RecordType.Name = 'Line Item'
                            AND     Line_Item_Type__r.Disclosure_Claim_for_Payment__r.SearchDecs_DisclosureType__c <> ''
                            AND     Line_Item_Status__c <> 'Deletion'                                                           
                            AND     Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Active__c = true
                            AND     Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Status__c = 'Complete'
                            /////////////////////temp/////////////////////////////
                            //AND       Amount_or_Value_of_Donation__c <> null
                            //AND       Line_Item_Type__r.Disclosure_Claim_for_Payment__c = 'a0DN0000000P2yx'
                            /////////////////////temp/////////////////////////////
                            AND     Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Reporting_Period__r.Publish_Date__c <= TODAY];                           
    
            recCount = qLineItemList.size();                    
            System.debug('recCount: ' + recCount);
        }
        catch (DmlException e)
        {
            System.debug('Error Occurred:' + '[' + e.getMessage() +' ]');
            throw new FADMSException(e.getMessage());
        }         
                    
        return qLineItemList;
    }

    public static List<Line_Item__c> processDonorRecQuery()
    {
        System.debug('Method called: processDonorRecQuery');    

        List<Line_Item__c> qLineItemList;
        Integer recCount = 0;

        try
        {               
            qLineItemList = [SELECT ID,    
                                    Line_Item_Type__r.SearchDecs_Type__c,
                                    //Published_Flag__c,
                                    //Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Status__c,
                                    //Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Reporting_Period__r.Publish_Date__c,
                                    // REPORTINGPERIOD_ID           
                                    Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Reporting_Period__r.SearchDecs_Reporting_ID__c,
                                    // EFID
                                    Line_Item_Type__r.Disclosure_Claim_for_Payment__c,                       
                                    // ID1
                                    Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Stakeholder__c,
                                    // DOCUMENTID
                                    Line_Item_Type__r.Disclosure_Claim_for_Payment__r.TRIM_Record_Number__c,                                    
                                    // CONTRIBUTIONLINENUMBER
                                    Name,
                                    // DONOR NAME
                                    Stakeholder__r.Name,
                                    // AMOUNTDONATED
                                    Amount_Roll_Up__c,
                                    // DONATIONDATE
                                    Date_Donation_was_made__c,
                                    // DONATIONTYPE
                                    Gift_Type__c,                                               
                                    // REPORTINGBEGINDATE
                                    Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Reporting_Period__r.Date_From__c,
                                    // REPORTINGENDDATE
                                    Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Reporting_Period__r.Date_To__c
                            FROM    Line_Item__c 
                            WHERE   Line_Item_Type__r.SearchDecs_Type__c = 'XVW_DONOR_REC'
                            AND     RecordType.Name = 'Line Item'
                            AND     Line_Item_Type__r.Disclosure_Claim_for_Payment__r.SearchDecs_DisclosureType__c <> ''                            
                            AND     Line_Item_Status__c <> 'Deletion'
                            AND     Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Active__c = true
                            AND     Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Status__c = 'Complete'
                            /////////////////////temp/////////////////////////////
                            //WHERE Line_Item_Type__r.Disclosure_Claim_for_Payment__c = 'a0DN0000000P2yYMAS'
                            /////////////////////temp/////////////////////////////
                            AND     Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Reporting_Period__r.Publish_Date__c <= TODAY];                               
    
            recCount = qLineItemList.size();                    
            System.debug('recCount: ' + recCount);
        }
        catch (DmlException e)
        {
            System.debug('Error Occurred:' + '[' + e.getMessage() +' ]');
            throw new FADMSException(e.getMessage());
        }        
                    
        return qLineItemList;
    }

    public static List<Line_Item__c> processFundraisingQuery()
    {
        System.debug('Method called: processFundraisingQuery');     

        List<Line_Item__c> qLineItemList;
        Integer recCount = 0;

        try
        {               
            qLineItemList = [SELECT ID,    
                                    Line_Item_Type__r.SearchDecs_Type__c,
                                    //Published_Flag__c,
                                    //Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Status__c,
                                    //Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Reporting_Period__r.Publish_Date__c,                                   
                                    // REPORTINGPERIOD_ID           
                                    Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Reporting_Period__r.SearchDecs_Reporting_ID__c,
                                    // EFID
                                    Line_Item_Type__r.Disclosure_Claim_for_Payment__c,                       
                                    // ID1
                                    Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Stakeholder__c,
                                    // DOCUMENTID
                                    Line_Item_Type__r.Disclosure_Claim_for_Payment__r.TRIM_Record_Number__c,    
                                    // EVENTTITLE
                                    Description_Name_of_Function_or_Venture__c,
                                    // EVENTDATE
                                    Date_of_Function_or_Venture__c,
                                    // NUMBEROFCONTRIBUTIONS
                                    //Total_Number_of_Small_Donations_Received__c,
                                    // TOTALAMOUNT
                                    Amount_Roll_Up__c,
                                    // PROCEEDSTYPE
                                    Net_or_Gross__c,                                    
                                    // REPORTINGBEGINDATE
                                    Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Reporting_Period__r.Date_From__c,
                                    // REPORTINGENDDATE
                                    Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Reporting_Period__r.Date_To__c
                            FROM    Line_Item__c 
                            WHERE   Line_Item_Type__r.SearchDecs_Type__c = 'XVW_FUNDRAISING'    
                            AND     RecordType.Name = 'Line Item'   
                            AND     Line_Item_Type__r.Disclosure_Claim_for_Payment__r.SearchDecs_DisclosureType__c <> ''
                            AND     Line_Item_Status__c <> 'Deletion'                                       
                            AND     Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Active__c = true
                            AND     Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Status__c = 'Complete'
                            /////////////////////temp/////////////////////////////
                            //AND       Total_Value_of_Small_Donations_Received__c > 0
                            /////////////////////temp/////////////////////////////
                            AND     Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Reporting_Period__r.Publish_Date__c <= TODAY];                           
    
            recCount = qLineItemList.size();                    
            System.debug('recCount: ' + recCount);
        }
        catch (DmlException e)
        {
            System.debug('Error Occurred:' + '[' + e.getMessage() +' ]');
            throw new FADMSException(e.getMessage());
        }                 
                    
        return qLineItemList;
    }

    public static List<Line_Item__c> processLoansQuery()
    {
        System.debug('Method called: processLoansQuery');   

        List<Line_Item__c> qLineItemList;
        Integer recCount = 0;
 
        try
        {               
            qLineItemList = [SELECT ID,    
                                    Line_Item_Type__r.SearchDecs_Type__c,
                                    //Published_Flag__c,
                                    //Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Status__c,
                                    //Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Reporting_Period__r.Publish_Date__c,
                                    // REPORTINGPERIOD_ID           
                                    Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Reporting_Period__r.SearchDecs_Reporting_ID__c,
                                    // EFID
                                    Line_Item_Type__r.Disclosure_Claim_for_Payment__c,                       
                                    // ID1
                                    Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Stakeholder__c,
                                    // DOCUMENTID
                                    Line_Item_Type__r.Disclosure_Claim_for_Payment__r.TRIM_Record_Number__c,
                                    // LOANAMOUNT
                                    Amount_Roll_Up__c,
                                    // DATEOFLOAN
                                    Date_Loan_was_made__c,
                                    // LOANLINENUMBER
                                    Name,
                                    // LENDERID
                                    Stakeholder__c,
                                    // LENDERTYPE
                                    Stakeholder__r.RecordType.Name,
                                    // NAME AND ADDRESS
                                    Stakeholder__r.Name,
                                    Enrolled_Address_of_Lender__c,
                                    // ABN
                                    Stakeholder__r.ABN_ACN_Other__c,    // CURRENTLY NO DATA IN DEV
                                    // REPORTINGBEGINDATE
                                    Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Reporting_Period__r.Date_From__c,
                                    // REPORTINGENDDATE
                                    Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Reporting_Period__r.Date_To__c
                            FROM    Line_Item__c 
                            WHERE   Line_Item_Type__r.SearchDecs_Type__c = 'XVW_LOANS'  
                            AND     RecordType.Name = 'Line Item'
                            AND     Line_Item_Type__r.Disclosure_Claim_for_Payment__r.SearchDecs_DisclosureType__c <> ''
                            AND     Line_Item_Status__c <> 'Deletion'                                   
                            AND     Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Active__c = true
                            AND     Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Status__c = 'Complete'
                            /////////////////////temp/////////////////////////////
                            //AND   Loan_Amount__c > 0
                            //AND   Line_Item_Type__r.Disclosure_Claim_for_Payment__c = 'a0DN0000000P32QMAS'
                            /////////////////////temp/////////////////////////////
                            AND     Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Reporting_Period__r.Publish_Date__c <= TODAY];               
    
            recCount = qLineItemList.size();                    
            System.debug('recCount: ' + recCount);
        }
        catch (DmlException e)
        {
            System.debug('Error Occurred:' + '[' + e.getMessage() +' ]');
            throw new FADMSException(e.getMessage());
        }                
                    
        return qLineItemList;
    }

    public static List<Line_Item__c> processPartySubscriptQuery()
    {
        System.debug('Method called: processPartySubscriptQuery');      

        List<Line_Item__c> qLineItemList;
        Integer recCount = 0;

        try
        {               
            qLineItemList = [SELECT ID,    
                                    Line_Item_Type__r.SearchDecs_Type__c,
                                    //Published_Flag__c,
                                    //Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Status__c,
                                    //Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Reporting_Period__r.Publish_Date__c,
                                    // REPORTINGPERIOD_ID           
                                    Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Reporting_Period__r.SearchDecs_Reporting_ID__c,
                                    // EFID
                                    Line_Item_Type__r.Disclosure_Claim_for_Payment__c,                       
                                    // ID1
                                    Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Stakeholder__c,
                                    // DOCUMENTID
                                    Line_Item_Type__r.Disclosure_Claim_for_Payment__r.TRIM_Record_Number__c,
                                    // SUBSCRIPTIONLINENUMBER
                                    Name,
                                    // SUBSCRIPTIONTITLE
                                    Rate__c,
                                    // NUMBEROFMEMBERS
                                    Number_of_Individuals_who_Paid_Each_Rate__c,
                                    // TOTALAMOUNT
                                    Amount_Roll_Up__c,
                                    // REPORTINGBEGINDATE
                                    Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Reporting_Period__r.Date_From__c,
                                    // REPORTINGENDDATE
                                    Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Reporting_Period__r.Date_To__c
                            FROM    Line_Item__c 
                            WHERE   Line_Item_Type__r.SearchDecs_Type__c = 'XVW_PARTY_SUBSCRIPT'    
                            AND     RecordType.Name = 'Line Item'
                            AND     Line_Item_Type__r.Disclosure_Claim_for_Payment__r.SearchDecs_DisclosureType__c <> ''
                            AND     Line_Item_Status__c <> 'Deletion'                                   
                            AND     Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Active__c = true
                            AND     Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Status__c = 'Complete'
                            /////////////////////temp/////////////////////////////
                            //AND       Rate__c <> NULL
                            /////////////////////temp/////////////////////////////
                            AND     Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Reporting_Period__r.Publish_Date__c <= TODAY];                                       
    
            recCount = qLineItemList.size();                    
            System.debug('recCount: ' + recCount);
        }
        catch (DmlException e)
        {
            System.debug('Error Occurred:' + '[' + e.getMessage() +' ]');
            throw new FADMSException(e.getMessage());
        }        
                    
        return qLineItemList;
    }

    public static List<Line_Item__c> processSmallDonationQuery()
    {
        System.debug('Method called: processSmallDonationQuery');   

        List<Line_Item__c> qLineItemList;
        Integer recCount = 0;

        try
        {               
            qLineItemList = [SELECT ID,    
                                    // temp
                                    Line_Item_Type__r.SearchDecs_Type__c,
                                    //Published_Flag__c,
                                    //Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Status__c,
                                    //Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Reporting_Period__r.Publish_Date__c,
                                    // REPORTINGPERIOD_ID           
                                    Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Reporting_Period__r.SearchDecs_Reporting_ID__c,
                                    // EFID
                                    Line_Item_Type__r.Disclosure_Claim_for_Payment__c,                       
                                    // ID1
                                    Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Stakeholder__c,
                                    // DOCUMENTID
                                    Line_Item_Type__r.Disclosure_Claim_for_Payment__r.TRIM_Record_Number__c,
                                    // NUMBEROFCONTRIBUTIONS
                                    Line_Item_Type__r.Calculated_Count__c,
                                    // TOTALAMOUNT
                                    //Amount_Roll_Up__c,
                                     Line_Item_Type__r.Calculated_Amount__c,
                                    // SELFFUNDINGAMOUNT
                                    Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Self_Funding__c
                            FROM    Line_Item__c 
                            WHERE   Line_Item_Type__r.SearchDecs_Type__c = 'XVW_SMALL_DONATION' 
                            AND     RecordType.Name = 'Line Item'
                            AND     Line_Item_Type__r.Disclosure_Claim_for_Payment__r.SearchDecs_DisclosureType__c <> ''
                            AND     Line_Item_Status__c <> 'Deletion'                                   
                            AND     Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Active__c = true
                            AND     Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Status__c = 'Complete'
                            AND     Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Reporting_Period__r.Publish_Date__c <= TODAY]; 

            recCount = qLineItemList.size();                    
            System.debug('recCount: ' + recCount);
        }          
        catch (DmlException e)
        {
            System.debug('Error Occurred:' + '[' + e.getMessage() +' ]');
            throw new FADMSException(e.getMessage());
        }                        
            
        return qLineItemList;
    }

    public static List<Disclosure_Claim_for_Payment__c> processUnionCGPDQuery()
    {
        System.debug('Method called: processUnionCGPDQuery');   

        List<Disclosure_Claim_for_Payment__c> qDisclList;       
        Integer recCount = 0;

        try
        {                           
                                    // EFID
            qDisclList = [SELECT    ID,                                                                          
                                    // ID
                                    Stakeholder__c,
                                    // NAME / ORGANISATIONNAME
                                    Stakeholder__r.Name,
                                    // ORGANISATION NAME
                                    Disclosure_Obligation__r.Registration__r.Group_Name__c,
                                    // ELEC_GRP_ID
                                    Disclosure_Obligation__r.Registration__r.Election_Event1__r.Parent_Election_Event__c,
                                    // ELEC_TYPE
                                    Disclosure_Obligation__r.Registration__r.Election_Event_Record_Type__c,
                                    // AREACODE
                                    Disclosure_Obligation__r.Registration__r.Election_Event_Area_Code__c, 
                                    // AREANAME
                                    Disclosure_Obligation__r.Registration__r.Election_Event1__r.Electorate__c,
                                    // ELEC_GRP_ID
                                    Disclosure_Obligation__r.Registration__r.Election_Event1__r.Parent_Election_Event__r.Election_Event_ID__c,
                                    // ADDRESS                                                  
                                    Stakeholder__r.PersonMailingStreet,
                                    Stakeholder__r.PersonMailingCity,
                                    Stakeholder__r.PersonMailingPostalCode,
                                    Stakeholder__r.PersonMailingState,
                                    Stakeholder__r.PersonMailingCountry,
                                    // ABN
                                    Stakeholder__r.ABN_ACN_Other__c,
                                    // TYPE
                                    Disclosure_Obligation__r.Registration_Record_Type__c,
                                    // AFFILIATION
                                    Disclosure_Obligation__r.Registration__r.Political_Party__r.Name,   
                                    // REPORTINGPERIOD_ID           
                                    Disclosure_Obligation__r.Reporting_Period__r.SearchDecs_Reporting_ID__c,                                    
                                    // REPORTINGBEGINDATE
                                    Disclosure_Obligation__r.Reporting_Period__r.Date_From__c,
                                    // REPORTINGENDDATE
                                    Disclosure_Obligation__r.Reporting_Period__r.Date_To__c,
                                    // TYPE
                                    SearchDecs_DisclosureType__c,
                                    // TYPE 
                                    SearchDecs_StakeholderType__c,
                                    // SURNAME
                                    Stakeholder__r.LastName,
                                    // GIVENNAME
                                    Stakeholder__r.FirstName
                            FROM    Disclosure_Claim_for_Payment__c 
                            WHERE   Disclosure_Obligation__r.Reporting_Period__r.Publish_Date__c <= TODAY
                            AND     SearchDecs_DisclosureType__c <> '' 
                            AND     Active__c = true
                            /////////////////////temp/////////////////////////////
                            //AND   Disclosure_Obligation__r.Registration__r.Election_Event_Record_Type__c <> '' limit 1
                            /////////////////////temp/////////////////////////////                          
                            AND     Status__c = 'Complete'];                        

            recCount = qDisclList.size();                   
            System.debug('recCount: ' + recCount);
        }
        catch (DmlException e)
        {
            System.debug('Error Occurred:' + '[' + e.getMessage() +' ]');
            throw new FADMSException(e.getMessage());
        }                
                    
        return qDisclList;
    }

    public static List<Disclosure_Claim_for_Payment__c> processSubmittedDocQuery()
    {
        System.debug('Method called: processSubmittedDocQuery');    

        List<Disclosure_Claim_for_Payment__c> qDisclList;       
        Integer recCount = 0;

        try
        {               
                                 // EFID
            qDisclList = [SELECT ID,                    
                                 // ID1
                                 Stakeholder__c,
                                 // EFTYPE
                                 SearchDecs_DisclosureType__c,
                                 // FILENUMBER 
                                 TRIM_Container_Record_Number__c,
                                 // DECLARATIONCOMPLETE
                                 Signed_By_Official_Agent_Date__c,
                                 // DECLARATIONCOMPLETE
                                 Signed_by_Political_Donor_Date__c,
                                 // DOCUMENTID / IMAGEFILENAME
                                 TRIM_Record_Number__c,
                                 // DATERECEIVED / DATEENTERED
                                 Date_Received__c, 
                                 // DATECHECKED
                                 Date_Checked__c,
                                 // REPORTINGPERIOD_ID           
                                 Disclosure_Obligation__r.Reporting_Period__r.SearchDecs_Reporting_ID__c,
                                 // REPORTINGBEGINDATE
                                 Disclosure_Obligation__r.Reporting_Period__r.Date_From__c,
                                 // REPORTINGENDDATE
                                 Disclosure_Obligation__r.Reporting_Period__r.Date_To__c,
                                 // REPORTINGDUEDATE
                                 Disclosure_Obligation__r.Lodgement_Due_Date__c
                          FROM   Disclosure_Claim_for_Payment__c 
                          WHERE  Disclosure_Obligation__r.Reporting_Period__r.Publish_Date__c <= TODAY
                          AND    SearchDecs_DisclosureType__c <> ''
                          AND    Active__c = true
                          /////////////////////temp/////////////////////////////
                          //AND     TRIM_Container_Record_Number__c <> NULL
                          //AND TRIM_Record_Number__c <> NULL
                          /////////////////////temp/////////////////////////////                              
                          AND    Status__c = 'Complete'];                               

            recCount = qDisclList.size();                   
            System.debug('recCount: ' + recCount);
        }
        catch (DmlException e)
        {
            System.debug('Error Occurred:' + '[' + e.getMessage() +' ]');
            throw new FADMSException(e.getMessage());
        }                  
                    
        return qDisclList;
    }

    public static List<Reporting_Period__c> processReportPeriodQuery()
    {
        System.debug('Method called: processReportPeriodQuery');    

        List<Reporting_Period__c> qDisclList;       
        Integer recCount = 0;

        try
        {               
                                    // EFID
            qDisclList = [SELECT    ID,    
                                    //REPORTINGPERIOD_ID
                                    SearchDecs_Reporting_ID__c,
                                    //REPORTINGBEGINDATE
                                    Date_From__c,
                                    //REPORTINGENDDATE
                                    Date_To__c,
                                    //REPORTINGDUEDATE
                                    Lodgement_Start_Date__c
                            FROM    Reporting_Period__c  
                            WHERE   Type__c = 'Financial Year'
                            AND     Active__c = TRUE
                            ORDER BY Date_From__c];
                            
            recCount = qDisclList.size();                   
            System.debug('recCount: ' + recCount);
        }
        catch (DmlException e)
        {
            System.debug('Error Occurred:' + '[' + e.getMessage() +' ]');
            throw new FADMSException(e.getMessage());
        }                  
                    
        return qDisclList;
    }
        
    public static List<Election_Event__c> processElectionEventQuery()
    {
        System.debug('Method called: processElectionEventQuery');    

        List<Election_Event__c> qDisclList;       
        Integer recCount = 0;

        try
        {               
                                    // EFID
            qDisclList = [SELECT    ID,    
                                    //ELECTION_GROUP_ID
                                    Election_Event_ID__c,
                                    //ELECTION_GROUP_TYPE
                                    By_Election__c,
                                    //EVENT_NAME
                                    Name,
                                    //ELECTION_GROUP_DATE
                                    Date_of_Election__c
                            FROM    Election_Event__c  
                            WHERE   RecordType.Name = 'State Election Group'
                            OR      RecordType.Name = 'Local Government Election Group'];
                            
            recCount = qDisclList.size();                   
            System.debug('recCount: ' + recCount);
        }
        catch (DmlException e)
        {
            System.debug('Error Occurred:' + '[' + e.getMessage() +' ]');
            throw new FADMSException(e.getMessage());
        }                  
                    
        return qDisclList;
    }
   
    @future
    public static void createBatchLogEntry(String op, String dsType, String status, String errorDesc)
    {
        System.debug('Method called: createBatchLogEntry');
    
        Searchdecs_Batch_Log__c batLog = new Searchdecs_Batch_Log__c();
        
        batLog.Operation__c = op;
        batLog.Data_Set_Type__c = dsType;
        batLog.Status__c = status;
        batLog.Operation_Date__c = Datetime.now();  
        batLog.Error_Description__c = errorDesc;        
        
        try
        {
            insert batLog;                                  
        }
        catch (DmlException e)
        {
            System.debug('Searchdecs Batch Log not inserted.');   
            System.debug('Error Occurred:' + '[' + e.getMessage() +' ]');
            throw new FADMSException(e.getMessage());
        }
        
        System.debug('Searchdecs Batch Log inserted.');
    }   

    /*
    public static void createXMLAttachment()
    {
        System.debug('Method called: createXMLAttachment');
        
        String txt = '<?xml version="1.0" encoding="UTF-8"?><response xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">  <item xsi:type="sObject">    <type>Line_Item__c</type>    <Id>a0HN0000002CpA5MAK</Id>    <RecordTypeId>012N00000008ZldIAE</RecordTypeId>    <Published_Flag__c>false</Published_Flag__c>    <Line_Item_Type__c>a0GN0000000uhF3MAI</Line_Item_Type__c>    <Line_Item_Type__r xsi:type="sObject">      <type>Line_Item_Type__c</type>      <Id>a0GN0000000uhF3MAI</Id>      <Calculated_Count__c>7</Calculated_Count__c>      <SearchDecs_Type__c>XVW_SMALL_DONATION</SearchDecs_Type__c>      <Disclosure_Claim_for_Payment__c>a0DN0000000OlnjMAC</Disclosure_Claim_for_Payment__c>      <Disclosure_Claim_for_Payment__r xsi:type="sObject">        <type>Disclosure_Claim_for_Payment__c</type>        <Id>a0DN0000000OlnjMAC</Id>        <Disclosure_Obligation__r xsi:type="sObject">          <type>Disclosure_Obligation__c</type>          <Id>a07N0000002275WIAQ</Id>          <Reporting_Period__c>a08N0000001ZDIVIA4</Reporting_Period__c>          <Reporting_Period__r xsi:type="sObject">            <type>Reporting_Period__c</type>            <Id>a08N0000001ZDIVIA4</Id>            <Publish_Date__c>2013-09-02</Publish_Date__c>          </Reporting_Period__r>        </Disclosure_Obligation__r>        <Self_Funding__c>22000.00</Self_Funding__c>        <Stakeholder__c>001N00000073k3pIAA</Stakeholder__c>        <Disclosure_Obligation__c>a07N0000002275WIAQ</Disclosure_Obligation__c>        <Status__c>Complete</Status__c>      </Disclosure_Claim_for_Payment__r>    </Line_Item_Type__r>    <Amount_Roll_Up__c>4000.00</Amount_Roll_Up__c>  </item></response>';
        
        Blob txtBlob = Blob.valueOf(txt); //Convert it to a blob
    
        Attachment attach = new Attachment(); //Make an attachment
        attach.Name ='text.xml';  
        attach.Body = txtBlob;
        attach.ContentType= 'application/xml'; //Signal what the file's MIME type is
        attach.ParentID = 'a0dN000000065PW';
        insert attach;      
    }    
    */  
}