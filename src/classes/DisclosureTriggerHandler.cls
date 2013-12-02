/* This handler contains methods used for handling the trigger on insert or update a Disclosure_Claim_for_Payment__c record
** - Clone a template
** - handle Duplicate Active Disclosure
** - Create TrimContainer
*/
public class DisclosureTriggerHandler 
{
    private boolean m_isExecuting = false;
	private boolean m_isTestMode = false;
    
    // Constructor
    public DisclosureTriggerHandler(boolean isExecuting)
    {
        m_isExecuting = isExecuting;
        if (Test_Mode__c.getValues('TestMode') != null) {
            m_isTestMode = Test_Mode__c.getValues('TestMode').isTestMode__c;
        }
    }

    public boolean IsTriggerContext
    {
        get{ return m_isExecuting;}
    }
    // Vinh added 09/09/2013
    public void onBeforeInsert(List<Disclosure_Claim_for_Payment__c> disclosureList) {
        System.debug('Method Called: onBeforeInsert');
        AssociateLineItemTypeAsPerTemp(disclosureList, 'isBefore');
        handleDuplicateActiveDisclosure(disclosureList);
    }
    // Vinh added 09/09/2013
    public void onBeforeUpdate(List<Disclosure_Claim_for_Payment__c> disclosureList) {
        System.debug('Method Called: OnBeforeUpdate');
        handleDuplicateActiveDisclosure(disclosureList);
    }
    // Vinh added 09/09/2013
    public void OnAfterUpdate(List<Disclosure_Claim_for_Payment__c> disclosureList) {
        System.debug('Method Called: OnAfterUpdate');
    }
    public void OnAfterInsert(List<Disclosure_Claim_for_Payment__c> disclosureList)
    {
        System.debug('Method Called: OnAfterInsert');
        // Vinh added 09/09/2013
        AssociateLineItemTypeAsPerTemp(disclosureList, 'isAfter');
        // End adding
        String stakeHolderId = '';
        String stakeHolderName = '';      
        String disclPeriodComYear = '';
        String disclPeriodEndYear = '';     

        String recTypeName = '';
        String objectId = '';
        String title = '';

        Map<ID, Schema.RecordTypeInfo> rtMap = Schema.SObjectType.Disclosure_Claim_for_Payment__c.getRecordTypeInfosById();

        try
        {                
            for (Disclosure_Claim_for_Payment__c disclosure : disclosureList) 
            {
                System.debug('Processing a disclosure in the list... ');
    
                // Get Record Type          
                recTypeName = rtMap.get(disclosure.RecordTypeId).getName();
                System.debug('recTypeName: ' + recTypeName);
                                
                // Get Object Id
                objectId = disclosure.ID;
                System.debug('objectId: ' + objectId);

                stakeHolderId = disclosure.Stakeholder__c;                   
                System.debug('stakeHolderId: ' + stakeHolderId);         

                Disclosure_Claim_for_Payment__c qDisclosure = [SELECT ID,                                      
                                                                      Stakeholder__r.Name,
                                                                      TRIM_Container_Name__c                                                   
                                                               FROM Disclosure_Claim_for_Payment__c
                                                               WHERE ID = :disclosure.ID LIMIT 1];

                stakeHolderName = qDisclosure.Stakeholder__r.Name;
                System.debug('stakeHolderName: ' + stakeHolderName);     

                disclPeriodComYear = disclosure.Disclosure_Period_Commences_Year__c;
                System.debug('disclPeriodComYear: ' + string.valueof(disclPeriodComYear));
                
                disclPeriodEndYear = disclosure.Disclosure_Period_Ends_Year__c;
                System.debug('disclPeriodEndYear: ' + disclPeriodEndYear);                 

                // Set title
                title = qDisclosure.TRIM_Container_Name__c;
                System.debug('title: ' + title);                
                
/*
                title = stakeHolderId + ' - ' + recTypeName;
                
                if (disclPeriodComYear != null && disclPeriodEndYear != null)
                {
                    title += ' ' + disclPeriodComYear + '/' + disclPeriodEndYear;
                }
                
                System.debug('title: ' + title);
*/

                if (recTypeName != 'Claim for Payment (Elections Campaign Fund)')
                {
                    // Create registration related container
                    CreateTrimContainer(recTypeName, objectId, title, stakeHolderId, stakeHolderName,m_isTestMode);
                }
            }
        }
        catch (Exception e)
        {
            System.debug('Error Occurred:' + '[' + e.getMessage() +' ]');            
            throw new FADMSException(e.getMessage());
        }
    }
    // Vinh added 09/09/2013 to replace AssociateLineItemTypeAsPerTemp trigger
    public static void AssociateLineItemTypeAsPerTemp(List<Disclosure_Claim_for_Payment__c> disclosureList, String TriggerType) {
        
        System.Debug('Method Called: AssociateLineItemTypeAsPerTemp ' + TriggerType);
        if (TriggerType == 'isBefore') {
            Set<String> disclosureIdList = new Set<String>();
            for(Disclosure_Claim_for_Payment__c dcp : disclosureList) {
                disclosureIdList.add(dcp.Disclosure_Obligation__c);
            }
            //Add condition ensure that this checkbox is marked as TRUE when a Disclosure record is associated 
            //to the Disclosure Obligation
            List<Disclosure_Obligation__c> docList = [SELECT Id, Disclosure_Lodged__c FROM Disclosure_Obligation__c WHERE Id IN :disclosureIdList];
            for (Disclosure_Obligation__c doc : docList) {
                doc.Disclosure_Lodged__c = true;
            }
            upsert docList;
        } else if(TriggerType == 'isAfter') {
            for(Disclosure_Claim_for_Payment__c dcp : disclosureList) {
                // US5255 Vinh added condition for  Disclosure__c
                if(dcp.Cloned_Disclosure_Claim_for_Payment__c == null && dcp.Disclosure__c == null){
                    List<Disclosure_Claim_for_Payment__c> tmpDCP = [SELECT Id, Name
                                                                    FROM Disclosure_Claim_for_Payment__c 
                                                                    WHERE RecordTypeId =: dcp.RecordTypeId AND IsTemplate__c = true];
                    
                    if (tmpDCP !=null && tmpDCP.size()>0) {
                        System.Debug('Method Called: AssociateLineItemTypeAsPerTemp Before Handler' );
                        CloneDisclosureClaimForPaymentController handler = new CloneDisclosureClaimForPaymentController(tmpDCP[0].Id, dcp.Id);
                        handler.CloneTempt();
                    }
                }
            }
        }
    }
    // Vinh added 09/09/2013 to replace 'duplicate active disclosure trigger'
    public static void handleDuplicateActiveDisclosure(List<Disclosure_Claim_for_Payment__c> inDisclosureList) {
        Set<String> DisclosureObIds = new Set<String>();
        Boolean isDuplicateActive = false;
        String duplicateId = '';
        Integer index = 0;
        Set<String> disclosureList = new Set<String>();
        for(Disclosure_Claim_for_Payment__c item :inDisclosureList){
            if (item.Active__c == true) {
                if (item.Disclosure_Obligation__c != null) {
                    if (DisclosureObIds.contains(item.Disclosure_Obligation__c)) {
                        isDuplicateActive = true;
                        duplicateId = item.Disclosure_Obligation__c;
                        break;
                    }
                    DisclosureObIds.add(item.Disclosure_Obligation__c);
                }
            }
            index++;
        }
        
        if (isDuplicateActive) {
            String duplicateName = [SELECT Name from Disclosure_Obligation__c Where Id=:duplicateId LIMIT 1][0].Name;
            Trigger.new[index].addError('There cannot be more than one active Disclosure/Claim for Payment associated to the same Disclosure Obligation.'); 
            //throw new CustomException('\'Two or more active Disclosure Claim for Payment found on Disclosure Obligation ' 
            //                    + duplicateId + ', ' + duplicateName + '\'');
        }
        
        
        // Get all active Disclosure Claim For Payment
        MAP<String,Disclosure_Claim_for_Payment__c> ActiveDOCMap = new Map<String,Disclosure_Claim_for_Payment__c>(
                                                                    [SELECT ID FROM Disclosure_Claim_for_Payment__c
                                                                    WHERE Active__c = true
                                                                    AND Disclosure_Obligation__c IN :DisclosureObIds]);
        
        // Check if DisClosure_Obligation already contains an active Disclosure_Claim_for_Payment__c
        Map<Id, AggregateResult> activeCount = new Map<Id, AggregateResult>(
                                [SELECT Disclosure_Obligation__c Id, COUNT(Id) Cnt FROM Disclosure_Claim_for_Payment__c 
                                 WHERE Disclosure_Obligation__c IN :DisclosureObIds
                                 AND Active__c = true
                                 GROUP BY Disclosure_Obligation__c]);
        index = 0;
        for(Disclosure_Claim_for_Payment__c item :inDisclosureList){
            if (item.Active__c == true) {
                if (activeCount.containsKey(item.Disclosure_Obligation__c) && !ActiveDOCMap.containsKey(item.Id)) {
                    isDuplicateActive = true;
                    duplicateId = item.Disclosure_Obligation__c;
                    break;
                }
            }
            index++;
        }
        if (isDuplicateActive) {
            String duplicateName = [SELECT Name from Disclosure_Obligation__c Where Id=:duplicateId LIMIT 1][0].Name;
            Trigger.new[index].addError('There cannot be more than one active Disclosure/Claim for Payment associated to the same Disclosure Obligation.'); 
            //throw new CustomException('\'2 Two or more active Disclosure Claim for Payment found on Disclosure Obligation ' 
            //                    + duplicateId + ', ' + duplicateName + '\'');
        }
    }
    @future(callout=true)
    public static void CreateTrimContainer(String recTypeName, String objectId, String title, String stakeHolderId, String stakeHolderName, boolean isTest)
    {
        System.debug('Method Called: CreateTrimContainer');

        String TRIM_SERVER_ID = GetTrimServerId();
        String REC_TYPE_PREFIX = 'name:';
        
        // FADMS Custom Rec Types
        String fadmsRecType = '';            
                
        String classification = '';                
        boolean classRequired = false;
                
        try
        {      
            Map<String, String> inputProperties = new Map<String, String>(); 

            System.debug('Creating internal disclosure container');
                       
            // 1 - Create internal disclosure container 
            if (recTypeName == 'Disclosure (Elected Member - Local Government Councillor)'
                        || recTypeName == 'Disclosure (Elected Member - Member of Parliament)')
            { 
                fadmsRecType = 'Elected Member File';
                
                // TRIM custom user fields
                inputProperties.put('udf:Stakeholder ID', stakeHolderId);
                inputProperties.put('udf:Stakeholder Name', stakeHolderName);               
            }
            else if (recTypeName == 'Disclosure (Group of Local Government Candidates)'
                        || recTypeName == 'Disclosure (Group of State Candidates)')
            { 
                fadmsRecType = 'Group Folder';
                
                // TRIM custom user fields
                inputProperties.put('udf:Stakeholder ID', stakeHolderId);
                inputProperties.put('udf:Stakeholder Name', stakeHolderName);               
            }
            else if (recTypeName == 'Disclosure (Local Government Candidate)'
                        || recTypeName == 'Disclosure (State Candidate)')
            { 
                fadmsRecType = 'Candidate Folder';
                
                // TRIM custom user fields
                inputProperties.put('udf:Stakeholder ID', stakeHolderId);
                inputProperties.put('udf:Stakeholder Name', stakeHolderName);               
            }
            else if (recTypeName == 'Disclosure (Major Political Donor)')
            { 
                fadmsRecType = 'Donor Folder';
                
                // TRIM custom user fields
                inputProperties.put('udf:Stakeholder ID', stakeHolderId);
                inputProperties.put('udf:Stakeholder Name', stakeHolderName);
            }
            else if (recTypeName == 'Disclosure (Political Party)')
            { 
                fadmsRecType = 'Party Folder';
            }
            else if (recTypeName == 'Disclosure (Third-Party Campaigner)')
            { 
                fadmsRecType = 'Third Party Campaigner Folder';
                
                // TRIM custom user fields
                inputProperties.put('udf:Stakeholder ID', stakeHolderId);
                inputProperties.put('udf:Stakeholder Name', stakeHolderName);               
            }
            else if (recTypeName == 'Claim for Payment (Administration Fund)')
            { 
                /*          
                The title for the administration fund containers should be: EFA – Administration Funding – Fund Management – Claim for Quarterly Payment – (Claimant’s Name) – (Quarter and Year)
                e.g. EFA – Administration Funding – Fund Management – Claim for Quarterly Payment – National Party of Australia NSW – March 2013
                */                                          

                fadmsRecType = 'EFA Admin Folders';

                // Set title
                //title = 'EFA – Administration Funding – Fund Management – Claim for Quarterly Payment – ' + stakeHolderName;
                //System.debug('title: ' + title);
                
                classRequired = true;               
                classification = 'name:EFA - Administration Funding - Fund Management';
            }
            else if (recTypeName == 'Claim for Payment (Policy Development Fund)')
            { 
                /*
                The title for the Policy Development fund containers should be: EFA – Policy Development Funding – Fund Management – Entitlement as at 31 December (Year in which the claim relates) – (Party Name)
                e.g. EFA – Policy Development Funding – Fund Management – Entitlement as at 31 December 2013– Save Our State
                */
                
                fadmsRecType = 'EFA Admin Folders';

                // Set title
                //title = 'EFA – Policy Development Funding – Fund Management – Entitlement as at ' + stakeHolderName;
                //System.debug('title: ' + title);
                
                classRequired = true;               
                classification = 'name:EFA - Policy Development Funding - Fund Management';
            }
            else
            {           
                throw new FADMSException('Unknown Disclosure/Claim for Payment Record Type detected: ' + recTypeName);              
            }            
                              
            // Set TRIM rec type
            String recordType = REC_TYPE_PREFIX + fadmsRecType;          
        
            inputProperties.put('recRecordType', recordType); //Name of the Record Type e.g. Folder 
            inputProperties.put('recTitle', title); 
            //inputProperties.put('recContainer', '98504'); //Parent Container Uri this Container will be created under. 
            inputProperties.put('recDateCreated', Datetime.now().format('yyyy-MM-dd HH:mm:ss')); 
            inputProperties.put('recExternalReference', objectId); //Salesforce sObject Id if you wish to set the TRIM external ID to help searches                        
            
            if (classRequired)
            {               
                // Only add an explicit classification if required
                inputProperties.put('recClassification', classification);
            }
    
            //Optional param, can be left out. The values below are the default if null. 
            List<String> outputProperties = new List<String>(); 
    
            outputProperties.add('recContainer'); 
            outputProperties.add('recNumber'); 
            outputProperties.add('recTitle'); 
            outputProperties.add('recIsContainer'); // Will come back false unless a TRIM Record exists within the Container 
    
            fuseit_s2t.TrimResult newContainer = fuseit_s2t.TrimConnector.createContainer(TRIM_SERVER_ID, inputProperties, outputProperties, UserInfo.getUserId(), isTest);
    
            System.debug('newContainer uri: ' + newContainer.uri);
            System.debug('newContainer recordNumber: ' + newContainer.recordNumber);

            // Save new container ids to parent object
            updateParentObject(objectId, newContainer.uri, newContainer.recordNumber);
                
            for (String key : newContainer.properties.keySet()) 
            {
                System.debug('---------------- Debug ---------  properties key: ' + key + ' value: ' + newContainer.properties.get(key));
            }         
        }
        catch (Exception e)
        {
            System.debug('Error Occurred:' + '[' + e.getMessage() +' ]');            
            throw new FADMSException(e.getMessage());
        }           
    }
    
    public static String GetTrimServerId()
    {
        System.debug('Method Called: GetTrimServerId');
        
        String TRIM_NAME = 'NSWEC TRIM';
        String trimServerId = '';       
         
        try
        {
            fuseit_s2t__Trim__c trimRec = [SELECT ID                                      
                                           FROM fuseit_s2t__Trim__c
                                           WHERE Name = :TRIM_NAME LIMIT 1];
                                           
            trimServerId = trimRec.ID;   
            System.debug('trimServerId: ' + trimServerId);
        }      
        catch (Exception e)
        {
            System.debug('Error Occurred:' + '[' + e.getMessage() +' ]');            
            throw new FADMSException(e.getMessage());
        }   
        
        return trimServerId;                           
    }   
    
    public static void updateParentObject(String inputObjectId, String uri, String recNumber)
    {
        System.debug('Method Called: updateParentObject');
        
        if (uri == '' || uri == null)
        {
            throw new FADMSException('Container uri was not supplied.');
        }
        
        if (recNumber == '' || recNumber == null)
        {
            throw new FADMSException('Container record number was not supplied.');
        }       
        
        // Select Disclosure Claim for Payment to update
        Disclosure_Claim_for_Payment__c discl = [SELECT Id 
                                                 FROM Disclosure_Claim_for_Payment__c 
                                                 WHERE Id = :inputObjectId LIMIT 1];

        discl.TRIM_Container_URI__c = uri;
        discl.TRIM_Container_Record_Number__c = recNumber;

        System.debug('Attempting to update Disclosure Claim for Payment with TRIM uri: ' + uri );

        try 
        {
            update discl;
        } 
        catch (DmlException e)
        {
            System.debug('Disclosure Claim for Payment not updated.');   
            System.debug('Error Occurred:' + '[' + e.getMessage() +' ]');
            throw new FADMSException(e.getMessage());
        }
        
        System.debug('Disclosure Claim for Payment TRIM container uri and record number updated successfully');
    }          
    //HanhLuu:DE4680:Start
    public void afterDeleteDisclosureClaim(List<Disclosure_Claim_for_Payment__c> disclosureList){
	   	/*
			get disclosure obiligation id
            count disclosure claim belong to the obiligation 
			if count = 0 then upate obiligation.dis
		*/
        System.debug('Method Called: afterDeleteDisclosureClaim :begin');
        Set<String> disclosureIdList = new Set<String>();
        Set<String> noChildDisclosureIdList = new Set<String>();
        
        for(Disclosure_Claim_for_Payment__c dcp : disclosureList) {
            disclosureIdList.add(dcp.Disclosure_Obligation__c);
        }

        AggregateResult[] nums = [SELECT count(id) numOfChildren, Disclosure_Obligation__c
                                  FROM Disclosure_Claim_for_Payment__c                                   
                                  WHERE id IN :disclosureIdList
                                  GROUP BY Disclosure_Obligation__c
                                 ];
        
        List<Disclosure_Obligation__c> disclosureIds=  new List<Disclosure_Obligation__c>();
        if (nums.size()>0){
        	System.debug('hanhluu::afterDeleteDisclosureClaim::numsize>0');
            for(AggregateResult item:nums){
                Integer numOfChildren = (Integer)item.get('numOfChildren');
                if(numOfChildren==0){
                    noChildDisclosureIdList.add(''+item.get('Disclosure_Obligation__c'));
                }
            }
            disclosureIds = [SELECT id,Disclosure_Lodged__c
                             FROM Disclosure_Obligation__c
                             WHERE id in :noChildDisclosureIdList];

        }else{
        	System.debug('hanhluu::afterDeleteDisclosureClaim::numsize<>0');
            disclosureIds = [SELECT id,Disclosure_Lodged__c
                             FROM Disclosure_Obligation__c
                             WHERE id in :disclosureIdList];
        }            
        
        for(integer i=0; i<disclosureIds.size();i++){
            disclosureIds.get(i).Disclosure_Lodged__c = false;            
        }
        update disclosureIds;
		System.debug('Method Called: afterDeleteDisclosureClaim :end');
    }
    //HanhLuu:DE4680:Start
    
}