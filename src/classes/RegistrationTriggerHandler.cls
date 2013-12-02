public class RegistrationTriggerHandler 
{
    private boolean m_isExecuting = false;
	private boolean m_isTestMode = false;
    
    // Constructor
    public RegistrationTriggerHandler(boolean isExecuting)
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

    public void OnAfterInsert(List<Registration__c> registrationList)
    {
        System.debug('Method Called: OnAfterInsert');

        String stakeHolderId = '';   
        String stakeHolderName = '';
        String electorateName = '';
        String eventName = '';
        String recTypeName = '';
        String objectId = '';
        String title = '';

        Map<ID, Schema.RecordTypeInfo> rtMap = Schema.SObjectType.Registration__c.getRecordTypeInfosById();

        try
        {                
            for (Registration__c reg : registrationList) 
            {
                //System.debug('going through a reg in the list: ');
    
                // Get Record Type          
                recTypeName = rtMap.get(reg.RecordTypeId).getName();
                System.debug('recTypeName: ' + recTypeName);
                
                // Get Object Id
                objectId = reg.ID;
                System.debug('objectId: ' + objectId);
                                
                if (recTypeName == 'Candidate' || recTypeName == 'Group of Candidates' || recTypeName == 'Elected Member')
                {
                    System.debug('OnAfterInsert> multi IF branch');
                
                    stakeHolderId = reg.Stakeholder__c;                   
                    System.debug('stakeHolderId: ' + stakeHolderId);
                    
                    Registration__c qReg = [SELECT ID,                                      
                                                   Stakeholder__r.Name,
                                                   Election_Event1__r.ID,
                                                   Election_Event1__r.Name,
                                                   Election_Event1__r.Area__r.Name,
                                                   TRIM_Container_Name__c                                                   
                                            FROM Registration__c
                                            WHERE ID = :reg.ID LIMIT 1];
    
                    stakeHolderName = qReg.Stakeholder__r.Name;
                    System.debug('stakeHolderName: ' + stakeHolderName);
    
                    electorateName = qReg.Election_Event1__r.Area__r.Name;                                      
                    System.debug('electorateName: ' + electorateName);    
                    
                    eventName = qReg.Election_Event1__r.Name;
                    System.debug('eventName: ' + eventName);
                    
                    title = qReg.TRIM_Container_Name__c;
                    System.debug('title: ' + title); 
                }
                else if (recTypeName == 'Third-Party Campaigner')
                {
                    System.debug('OnAfterInsert> ' + recTypeName + ' IF branch');
                
                    stakeHolderId = reg.Stakeholder__c;                    
                    System.debug('stakeHolderId: ' + stakeHolderId);
                    
                    Registration__c qReg = [SELECT ID,                                      
                                                   Stakeholder__r.Name,
                                                   Election_Event1__r.ID,
                                                   Election_Event1__r.Name,
                                                   TRIM_Container_Name__c
                                            FROM Registration__c
                                            WHERE ID = :reg.ID LIMIT 1];
    
                    stakeHolderName = qReg.Stakeholder__r.Name;   
                    System.debug('stakeHolderName: ' + stakeHolderName);            
                    
                    eventName = qReg.Election_Event1__r.Name;
                    System.debug('eventName: ' + eventName);     
                    
                    title = qReg.TRIM_Container_Name__c;
                    System.debug('title: ' + title);                                                                        
                }
                else
                {           
                    throw new FADMSException('Unknown Registration Record Type detected: ' + recTypeName);              
                }                       
    
                // Ensure there are no nulls
                if (electorateName == null)
                {
                    electorateName = '';
                }
                
                if (eventName == null)
                {
                    eventName = '';
                }
    
                // Create container
                CreateTrimContainer(title, recTypeName, objectId, stakeHolderId, stakeHolderName, electorateName, eventName, m_isTestMode);
            }
        }
        catch (Exception e)
        {
            System.debug('Error Occurred:' + '[' + e.getMessage() +' ]');            
            throw new FADMSException(e.getMessage());
        }
    }
   
    @future(callout=true)
    public static void CreateTrimContainer(String title, String recTypeName, String objectId, String stakeHolderId, String stakeHolderName, String electorateName, String eventName, boolean isTest)
    {
        System.debug('Method Called: CreateTrimContainer');

        String TRIM_SERVER_ID = GetTrimServerId();
        String REC_TYPE_PREFIX = 'name:';
        
        // FADMS Custom Rec Types
        String fadmsRecType = '';            
                
        try
        {      
            Map<String, String> inputProperties = new Map<String, String>(); 

            if (recTypeName == 'Candidate')
            {
                System.debug('CreateTrimContainer > ' + recTypeName + ' IF branch');
                
                fadmsRecType = 'Candidate Folder';
                               
                // TRIM custom user fields
                inputProperties.put('udf:Stakeholder ID', stakeHolderId);
                inputProperties.put('udf:Stakeholder Name', stakeHolderName);
                inputProperties.put('udf:Council/State Electorate Name', electorateName);    
                inputProperties.put('udf:Event Name', eventName);                  
            }
            else if (recTypeName == 'Group of Candidates')
            {
                System.debug('CreateTrimContainer > ' + recTypeName + ' IF branch');
           
                fadmsRecType = 'Group Folder';
                
                // TRIM custom user fields
                inputProperties.put('udf:Stakeholder ID', stakeHolderId);
                inputProperties.put('udf:Stakeholder Name', stakeHolderName);
                inputProperties.put('udf:Council/State Electorate Name', electorateName);    
                inputProperties.put('udf:Event Name', eventName);                                 
            }
            else if (recTypeName == 'Third-Party Campaigner')
            {
                System.debug('CreateTrimContainer > ' + recTypeName + ' IF branch');
            
                fadmsRecType = 'Third Party Campaigner Folder';               
               
                // TRIM custom user fields
                inputProperties.put('udf:Stakeholder ID', stakeHolderId);
                inputProperties.put('udf:Stakeholder Name', stakeHolderName);
                inputProperties.put('udf:Event Name', eventName);                
            }
            else if (recTypeName == 'Elected Member')
            {
                System.debug('CreateTrimContainer > ' + recTypeName + ' IF branch');
            
                fadmsRecType = 'Elected Member File';
                
                // TRIM custom user fields
                inputProperties.put('udf:Stakeholder ID', stakeHolderId);
                inputProperties.put('udf:Stakeholder Name', stakeHolderName);
                inputProperties.put('udf:Council/State Electorate Name', electorateName);
                inputProperties.put('udf:Event Name', eventName);                             
            }
            else
            {           
                throw new FADMSException('Unknown Registration Record Type detected: ' + recTypeName);              
            }            

            System.debug('title: '+ title);

            // Set TRIM rec type
            String recordType = REC_TYPE_PREFIX + fadmsRecType;          
        
            inputProperties.put('recRecordType', recordType); //Name of the Record Type e.g. Folder 
            inputProperties.put('recTitle', title); 
            inputProperties.put('recDateCreated', Datetime.now().format('yyyy-MM-dd HH:mm:ss')); 
            inputProperties.put('recExternalReference', objectId); 
            
            // TRIM custom user fields
            inputProperties.put('udf:Stakeholder ID', stakeHolderId);
            inputProperties.put('udf:Stakeholder Name', stakeHolderName);
            inputProperties.put('udf:Council/State Electorate Name', electorateName);   
            inputProperties.put('udf:Event Name', eventName);  
    
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
                   
        // Select Registration to update (in context)
        Registration__c reg = [SELECT Id 
                               FROM Registration__c 
                               WHERE Id = :inputObjectId LIMIT 1];

        reg.TRIM_Container_URI__c = uri;
        reg.HP_TRIM_File_No__c = recNumber;


        System.debug('Attempting to update Registration with TRIM uri: ' + uri);

        try 
        {
            update reg;
        } 
        catch (DmlException e)
        {
            System.debug('Registration not updated.');   
            System.debug('Error Occurred:' + '[' + e.getMessage() +' ]');
            throw new FADMSException(e.getMessage());
        }
        
        System.debug('Registration uri updated successfully');
    }        
}