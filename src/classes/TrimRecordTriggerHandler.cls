public class TrimRecordTriggerHandler 
{
    private boolean m_isExecuting = false;

    // Constructor
    public TrimRecordTriggerHandler(boolean isExecuting)
    {
        m_isExecuting = isExecuting;
    }

    public boolean IsTriggerContext
    {
        get{ return m_isExecuting;}
    }

    public void OnAfterUpdate(List<fuseit_s2t__Trim_Record__c> trimRecList)
    {
        System.debug('Method Called: OnAfterUpdate');

        String trimRecId = '';
        String trimRecStatus = '';
        String trimRecNumber = '';
        String trimDocRecType = '';
        String attachmentId = '';   
        String objectId = '';    

        try
        {                
            for (fuseit_s2t__Trim_Record__c trimRec : trimRecList) 
            {
                //System.debug('going through a rec in the list: ');

                trimRecId = trimRec.ID;
                System.debug('trimRecId: ' + trimRecId);

                trimRecStatus = trimRec.fuseit_s2t__Trim_Status__c;
                System.debug('trimRecStatus: ' + trimRecStatus + ' ' + trimRecStatus.length());
                
                trimDocRecType = trimRec.fuseit_s2t__Trim_Record_Type__c;
                System.debug('trimDocRecType: ' + trimDocRecType);

                // Get Attachment Id
                attachmentId = trimRec.fuseit_s2t__Attachment_ID__c;
                System.debug('attachmentId: ' + attachmentId);

                if (trimRecStatus == 'Synchronized') 
                {
                	System.debug('previous condition failed');
                }
                if (trimRecStatus.equalsIgnoreCase('Synchronized')) 
                {
                	System.debug('new condition failed');
                }
                
                if (trimRecStatus == 'Synchronized')
                {
                    System.debug('Now deleting attachment - attachmentId: ' + attachmentId);
                    
                    Attachment delAttachment = [SELECT Id FROM Attachment 
                                                WHERE ID = :attachmentId LIMIT 1]; 
                
                    try 
                    {
                        delete delAttachment;
                    } 
                    catch (DmlException e) 
                    {
                        System.debug('Error Occurred:' + '[' + e.getMessage() +' ]');            
                        throw new FADMSException(e.getMessage());
                    }
                    
                    System.debug('Attachment deleted successfully');
                    
                    // Get parent object id and TRIM Record Number
                    objectId = trimRec.fuseit_s2t__Parent_ID__c;
                    trimRecNumber = trimRec.fuseit_s2t__Record_Number__c;
                    
                    System.debug('objectId: ' + objectId);
                    System.debug('trimRecNumber: ' + trimRecNumber);
                    
                    // Update parent Disclosure rec with TRIM Record number 
                    updateParentObject(objectId, trimRecNumber, trimDocRecType);
                }
            }
        }
        catch (Exception e)
        {
            System.debug('Error Occurred:' + '[' + e.getMessage() +' ]');            
            throw new FADMSException(e.getMessage());
        }
    }

    public static void updateParentObject(String inputObjectId, String recNumber, String docRecType)
    {
        System.debug('Method Called: updateParentObject');
		
		List<sObject> objList;
		Disclosure_Claim_for_Payment__c discl;

		if (recNumber == '' || recNumber == null)
		{
			throw new FADMSException('TRIM Record number was not supplied.');
		}		

        objList = [SELECT Id 
               	   FROM Disclosure_Claim_for_Payment__c 
                   WHERE Id = :inputObjectId LIMIT 1];		
			
		System.debug('objList.size: ' + objList.size());		
								
		if (objList.size() > 0) 
		{
			System.debug('Object Type: ' + objList[0].getSObjectType());
		
			// Perform update only for Disclosure_Claim_for_Payment object 
			if (objList[0].getSObjectType() == Disclosure_Claim_for_Payment__c.sObjectType)
			{
				System.debug('Object is a Disclosure_Claim_for_Payment__c rec');
				
				if (docRecType == 'EFA External Document')
				{				
					discl = (Disclosure_Claim_for_Payment__c)objList[0];
					
					// Update Disclosure TRIM Record Number
			        discl.TRIM_Record_Number__c = recNumber;
			
			        System.debug('Attempting to update Disclosure Claim for Payment with TRIM Record Number: ' + recNumber);
			
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
			        
			        System.debug('Disclosure Claim for Payment TRIM record number updated successfully');
				}
	        }
		}
    }   
}