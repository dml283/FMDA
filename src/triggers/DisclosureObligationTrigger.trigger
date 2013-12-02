/* Use for calling handler after insert Disclosure_Obligation__c
*/
trigger DisclosureObligationTrigger on Disclosure_Obligation__c (after insert)
{
    System.debug('Trigger Called: DisclosureObligationTrigger');

    try
    {
        DisclosureObligationTriggerHandler handler = new DisclosureObligationTriggerHandler(true);  

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