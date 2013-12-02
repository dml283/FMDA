/* Use for calling handler after update fuseit_s2t__Trim_Record__c
*/
trigger TrimRecordTrigger on fuseit_s2t__Trim_Record__c (after update) 
{
    System.debug('Trigger Called: TrimRecordTrigger');

    try
    {
        TrimRecordTriggerHandler handler = new TrimRecordTriggerHandler(true);  

        if (Trigger.isUpdate && Trigger.isAfter)
        {
            handler.OnAfterUpdate(Trigger.new);            
        }
    }
    catch (Exception e)
    {
        System.debug('Error Occurred:' + '[' + e.getMessage() +' ]');
        System.debug('Trigger error detected [' + e.getTypeName() + ']: ' + e.getMessage() + ' - ' + e.getStackTraceString());
        throw new FADMSException('THIS SAVE WILL FAIL: ' + e.getMessage());
    }
}