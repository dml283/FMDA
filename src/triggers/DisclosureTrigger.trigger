// 09/09/2013 Vinh moved all logic here to Disclosure Trigger Handler
trigger DisclosureTrigger on Disclosure_Claim_for_Payment__c (before insert, before update) {
    /*Set<String> DisclosureObIds = new Set<String>();
    Boolean isDuplicateActive = false;
    String duplicateId = '';
    Integer index = 0;
    Set<String> disclosureList = new Set<String>();
    for(Disclosure_Claim_for_Payment__c item :Trigger.New){
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
    for(Disclosure_Claim_for_Payment__c item :Trigger.New){
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
    }*/
}