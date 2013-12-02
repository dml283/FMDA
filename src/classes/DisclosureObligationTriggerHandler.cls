/* This handler contains methods used for handling insert or update a Disclosure_Obligation__c record
** - Create TrimContainer
*/
public class DisclosureObligationTriggerHandler 
{
    private boolean m_isExecuting = false;
	private boolean m_isTestMode = false;
    
    // Constructor
    public DisclosureObligationTriggerHandler(boolean isExecuting)
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

    public void OnAfterInsert(List<Disclosure_Obligation__c> disclObligationList)
    {
        System.debug('Method Called: OnAfterInsert');

        String stakeHolderType = '';
        String disclObligName = '';
        String objectId = '';    
        String title = '';    

        try
        {                
            for (Disclosure_Obligation__c disclObligation : disclObligationList) 
            {
                System.debug('Processing a disclosure obligation in the list... ');                
                
                stakeHolderType = disclObligation.Stakeholder_Type__c;
                System.debug('stakeHolderType: ' + stakeHolderType);
                                
                // Get Object Id
                objectId = disclObligation.ID;
                System.debug('objectId: ' + objectId);

                disclObligName = disclObligation.Name;
                System.debug('disclObligName: ' + disclObligName);
    
    			title = disclObligation.TRIM_Container_Name__c;
    			System.debug('title: ' + title);
    
                // Create container
                CreateTrimContainer(title, objectId, stakeHolderType, disclObligName,m_isTestMode);
            }
        }
        catch (Exception e)
        {
            System.debug('Error Occurred:' + '[' + e.getMessage() +' ]');            
            throw new FADMSException(e.getMessage());
        }
    }
   
    @future(callout=true)
    public static void CreateTrimContainer(String title, String objectId, String stakeHolderType, String disclObligName,boolean isTest)
    {
        System.debug('Method Called: CreateTrimContainer');

        String TRIM_SERVER_ID = GetTrimServerId();
        String REC_TYPE_PREFIX = 'name:';
        
        // FADMS Custom Rec Types
        String fadmsRecType = '';            
        
        try
        {      
            if (stakeHolderType == 'Major Political Donor')
            {
                fadmsRecType = 'Donor Folder';
            }
            else if (stakeHolderType == 'Political Party')
            {
                fadmsRecType = 'Party Folder';
            }
            else if (stakeHolderType == 'Third-Party Campaigner')
            {
                fadmsRecType = 'Third Party Campaigner Folder';
            }
            else if (stakeHolderType == 'Candidate')
            {
                fadmsRecType = 'Candidate Folder';
            }
            else if (stakeHolderType == 'Group of Candidates')
            {
                fadmsRecType = 'Group Folder';
            }
            else if (stakeHolderType == 'Elected Member')
            {
                fadmsRecType = 'Elected Member File';
            }
            else
            {
                throw new FADMSException('Unknown Disclosure Obligation Stakeholder Record Type detected: ' + stakeHolderType);
            }

            Map<String, String> inputProperties = new Map<String, String>(); 
             
            // Set TRIM rec type
            String recordType = REC_TYPE_PREFIX + fadmsRecType;          
        
            inputProperties.put('recRecordType', recordType); //Name of the Record Type e.g. Folder 
            inputProperties.put('recTitle', title);              
            inputProperties.put('recDateCreated', Datetime.now().format('yyyy-MM-dd HH:mm:ss')); 
            inputProperties.put('recExternalReference', objectId); 

            //Optional param, can be left out. The values below are the default if null. 
            List<String> outputProperties = new List<String>(); 

            outputProperties.add('recContainer'); 
            outputProperties.add('recNumber'); 
            outputProperties.add('recTitle'); 
            outputProperties.add('recIsContainer'); // Will come back false unless a TRIM Record exists within the Container 
    
            fuseit_s2t.TrimResult newContainer = fuseit_s2t.TrimConnector.createContainer(TRIM_SERVER_ID, inputProperties, outputProperties, UserInfo.getUserId(), isTest);
    
            System.debug('newContainer uri: ' + newContainer.uri);
            System.debug('newContainer recordNumber: ' + newContainer.recordNumber);

            // Save new container uri to parent object
            updateParentObject(objectId, newContainer.uri);
                
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
    
    public static void updateParentObject(String inputObjectId, String uri)
    {
        System.debug('Method Called: updateParentObject');
		
		if (uri == '' || uri == null)
		{
			throw new FADMSException('Container uri was not supplied.');
		}
		
        // Select Disclosure Obligation to update
        Disclosure_Obligation__c disclOblg = [SELECT Id 
                           	   				  FROM Disclosure_Obligation__c 
                           	   				  WHERE Id = :inputObjectId LIMIT 1];

        disclOblg.TRIM_Container_URI__c = uri;

        System.debug('Attempting to update Disclosure Obligation with TRIM uri: ' + uri);

        try 
        {
            update disclOblg;
        } 
        catch (DmlException e)
        {
            System.debug('Disclosure Obligation not updated.');   
            System.debug('Error Occurred:' + '[' + e.getMessage() +' ]');
            throw new FADMSException(e.getMessage());
        }
        
        System.debug('Disclosure Obligation uri updated successfully');
    }          
}