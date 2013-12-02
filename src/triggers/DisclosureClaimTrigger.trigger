/* Use for calling handler before, after insert or update a Disclosure_Claim_for_Payment__c
*/
trigger DisclosureClaimTrigger on Disclosure_Claim_for_Payment__c (before insert,before update, after insert, after update, after delete) {
    System.debug('Trigger Called: DisclosureClaimTrigger');
    try
    {
        DisclosureTriggerHandler handler = new DisclosureTriggerHandler(true);  
        if (Trigger.isInsert)
        {
            if (Trigger.isBefore) {
                handler.OnBeforeInsert(Trigger.new);
            } else if (Trigger.isAfter) {
                handler.OnAfterInsert(Trigger.new);
            }
        } else if (Trigger.isUpdate) {
            if (Trigger.isBefore) {
                handler.OnBeforeUpdate(Trigger.new);
            } else if (Trigger.isAfter) {
                handler.OnAfterUpdate(Trigger.new);
            }
        }else if (Trigger.isDelete){            
            //HanhLuu:DE4680
            handler.afterDeleteDisclosureClaim(Trigger.old);
        }        
    }
    catch (Exception e)
    {
        System.debug('Error Occurred:' + '[' + e.getMessage() +' ]');
        throw new FADMSException(e.getMessage());
    }
}