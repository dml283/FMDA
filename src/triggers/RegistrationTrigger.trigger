/* Use for calling handler after insert Registration__c
*/
trigger RegistrationTrigger on Registration__c (after insert)
{
    System.debug('Trigger Called: RegistrationTrigger');

    try
    {
        RegistrationTriggerHandler handler = new RegistrationTriggerHandler(true);  

        if (Trigger.isInsert && Trigger.isAfter)
        {
            handler.OnAfterInsert(Trigger.new);            
        }
    }
    catch (Exception e)
    {
        System.debug('Error Occurred:' + '[' + e.getMessage() +' ]');
        throw new FADMSException(e.getMessage());
    }
}