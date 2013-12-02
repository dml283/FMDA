// 09/09/2013 Vinh moved all logic here to Disclosure Trigger Handler
trigger DisclosureTriggerTRIM on Disclosure_Claim_for_Payment__c (after insert) 
{
    /*
    System.debug('Trigger Called: DisclosureTriggerTRIM');

    try
    {
        DisclosureTriggerHandler handler = new DisclosureTriggerHandler(true);  

        if (Trigger.isInsert && Trigger.isAfter)
        {
            handler.OnAfterInsert(Trigger.new);
        }
    }
    catch (Exception e)
    {
        System.debug('Error Occurred:' + '[' + e.getMessage() +' ]');
        throw new FADMSException(e.getMessage());
    }*/
}