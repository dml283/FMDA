// 09/09/2013 Vinh moved all logic here to Disclosure Trigger Handler
trigger AssociateLineItemTypeAsPerTemp on Disclosure_Claim_for_Payment__c (before insert, after insert) {
    /*
    if(Trigger.isBefore){
        if (Trigger.isInsert) {
            for(Disclosure_Claim_for_Payment__c dcp : Trigger.new) {
            //Add condition ensure that this checkbox is marked as TRUE when a Disclosure record is associated 
            //to the Disclosure Obligation
                List<Disclosure_Obligation__c> doc = [SELECT Id, Disclosure_Lodged__c FROM Disclosure_Obligation__c WHERE Id=:dcp.Disclosure_Obligation__c];
                if(doc!=null && doc.size()>0){
                    doc[0].Disclosure_Lodged__c = true;
                    upsert doc[0];
                }
            }
        }
    }
    else if(Trigger.isAfter){
        if (Trigger.isInsert) {
            for(Disclosure_Claim_for_Payment__c dcp : Trigger.new) {
                if(dcp.Cloned_Disclosure_Claim_for_Payment__c == null){
                    List<Disclosure_Claim_for_Payment__c> tmpDCP = [SELECT Id, Name
                                                                    FROM Disclosure_Claim_for_Payment__c 
                                                                    WHERE RecordTypeId =: dcp.RecordTypeId AND IsTemplate__c = true];
                    
                    if (tmpDCP !=null && tmpDCP.size()>0) {
                        CloneDisclosureClaimForPaymentController handler = new CloneDisclosureClaimForPaymentController(tmpDCP[0].Id, dcp.Id);
                        handler.CloneTempt();
                    }
                }
            }
        }
    }*/
}