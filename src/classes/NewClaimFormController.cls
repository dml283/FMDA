public class NewClaimFormController{
	public Disclosure_Claim_For_Payment__c Entity{get;set;}
    private String doID;
    //public boolean IsMajorPoliticalDonor{get;set;}
    public NewClaimFormController() {
    	try {
	        this.doID = ApexPages.currentPage().getParameters().get('doID');
	        RecordType ECFRecordtype = [SELECT Id, Name FROM RecordType
	        							WHERE Name='Claim for Payment (Elections Campaign Fund)'
	        							LIMIT 1];
	        Disclosure_Claim_For_Payment__c temp = getDisclosureRecordById(this.doID);
	        this.Entity = new Disclosure_Claim_For_Payment__c(RecordTypeID = ECFRecordtype.Id,
	                                                          Disclosure_Obligation__c = temp.Disclosure_Obligation__c,
	                                                          Stakeholder__c = temp.Stakeholder__c,
	                                                          Official_Agent__c = temp.Official_Agent__c,
	                                                          Disclosure__c = doID,
	                                                          OwnerId = UserInfo.GetUserId()
	                                                         );
	        // Populate Eligible Claim
	        List<Eligible_Claim_for_Payment__c> tempEliList = [
	            SELECT Id , Stakeholder__c,Reporting_Period__c
	            FROM Eligible_Claim_for_Payment__c
	            WHERE Stakeholder__c =:temp.Stakeholder__c
	            AND Reporting_Period__c =:temp.Disclosure_Obligation__r.Reporting_Period__c
	            AND Public_Fund__c = 'Elections Campaign Fund'
	        ];
	        if (tempEliList.size() > 0) {
	            this.Entity.Eligible_Claim_for_Payment__c = tempEliList[0].Id;
	        }
	        //this.IsMajorPoliticalDonor = (temp.RecordType.Name == 'Disclosure (Major Political Donor)');
    	} catch (Exception e) {
    		ApexPages.addMessages(e);
    	}
    }
    
    private Disclosure_Claim_For_Payment__c getDisclosureRecordById(String id) {
        return [SELECT Id, RecordTypeID, RecordType.Name, Disclosure_Obligation__c,Stakeholder__c,Official_Agent__c,
                	Disclosure_Obligation__r.Reporting_Period__c
                FROM Disclosure_Claim_For_Payment__c
                WHERE Id=:Id];
    }
    
    public PageReference Save() {
        Savepoint sp = Database.setSavepoint();
        try {
            // Change active record to inactive 
            List<Disclosure_Claim_for_payment__c> tempActivelist = [SELECT Id, Active__c
                                                                    FROM Disclosure_Claim_for_payment__c
                                                                    WHERE Disclosure_Obligation__c = :this.Entity.Disclosure_Obligation__c
                                                                    AND Active__c = true
                                                                   ];
            for (Disclosure_Claim_for_payment__c temp : tempActivelist) {
                temp.Active__c = false;
            }
            this.Entity.Active__c = true;
            upsert tempActivelist;
            upsert this.Entity;
                
            //Clone Line Item Type
            List<Line_Item_Type__c> cloneLITlist = new List<Line_Item_Type__c>();
            List<Line_Item_Type__c> LITlist = GetLineItemTypesByEntityId(this.doID);
            if (LITlist != null && LITlist.size() > 0) {
                Map<String,String> newCloneFromOldLineItemType = new Map<String,String>();
                for (Line_Item_Type__c lit : LITlist) {
                    Line_Item_Type__c newLIT = lit.clone(false,true);
                    newLIT.Disclosure_Claim_for_Payment__c = this.Entity.Id;
                    newLIT.Cloned_Line_Item_Type__c = lit.Id;
                    cloneLITlist.add(newLIT);
                }
                insert cloneLITlist;
                for (Line_Item_Type__c lit : cloneLITlist) {
                    newCloneFromOldLineItemType.put(lit.Cloned_Line_Item_Type__c,lit.Id);
                }
                
                //Clone Line Item
                // This map is to store the Clone Line Item Id
                Map<String,String> newCloneFromOldLineItem = new Map<String,String>();
                List<Line_Item__c> cloneLIlist = new List<Line_Item__c>();
                List<Line_Item__c> LIlist = GetLineItemsByLineItemTypeObj(LITlist,'Line Item');
                if (LIlist != null && LIlist.size()>0) {
                    Set<String> setLI = new Set<String>();
                    for (Line_Item__c li : LIlist) {
                        Line_Item__c newLI = li.clone(false,true);
                        newLI.Line_Item_Type__c = newCloneFromOldLineItemType.get(li.Line_Item_Type__c);
                        newLI.Cloned_Line_Item__c = li.Id;
                        setLI.add(li.Id);
                        cloneLIlist.add(newLI);
                    }
                    CloneDisclosureClaimForPaymentController.isCloning = true;
                    insert cloneLIlist;
                    CloneDisclosureClaimForPaymentController.isCloning = false;
                    // Put to map
                    for (Line_Item__c item : cloneLIlist) {
                        newCloneFromOldLineItem.put(item.Cloned_Line_Item__c,item.Id);
                    }
                    // Clone Audit Line Item
                    List<Line_Item__c> curAuditLstLI = GetLineItemsByLineItemTypeObj(LITlist,'Audit Line Item');
                    List<Line_Item__c> cloneAuditList = new List<Line_Item__c>();
                    for (Line_Item__c li : curAuditLstLI) {
                        setLI.add(li.Id);
                        Line_Item__c newLI = li.clone(false,true);
                        newLI.Cloned_Line_Item__c = li.Id;
                        newLI.Line_Item_Type__c = newCloneFromOldLineItemType.get(li.Line_Item_Type__c);
                        // Link to new Cloned Line Item
                        newLI.Line_Item__c = newCloneFromOldLineItem.get(li.Line_Item__c);
                        cloneAuditList.add(newLI);
                    }
                    CloneDisclosureClaimForPaymentController.isCloning = true;
                    insert cloneAuditList;
                    CloneDisclosureClaimForPaymentController.isCloning = false;
                    // Put to map
                    for (Line_Item__c item : cloneAuditList) {
                        newCloneFromOldLineItem.put(item.Cloned_Line_Item__c,item.Id);
                    }
                    
                    // Clone Vouching_Trim_Line_Item for Audit line item, Where Trim record's status is Synchronized
                    List<Vouched_Line_Item__c> VouchedLineItems = GetVouchedLineItem(setLI);
                    List<Vouched_Line_Item__c> cloneVouchedLineItems = new List<Vouched_Line_Item__c>();
                    for (Vouched_Line_Item__c item : VouchedLineItems) {
                        Vouched_Line_Item__c rec = item.clone(false,true);
                        rec.Cloned_Vouched_Line_Item__c  = item.Id;
                        rec.Line_Item__c = newCloneFromOldLineItem.get(item.Line_Item__c);
                        cloneVouchedLineItems.add(rec);
                    }
                    upsert cloneVouchedLineItems;
                    
                    //Clone Reconciled Line Item
                    List<Reconciled_Line_Item__c> lstRLI = new List<Reconciled_Line_Item__c>();
                    for (Reconciled_Line_Item__c rli : GetReconciledLineItemsByLineItemIds(LIlist)) {
                        Reconciled_Line_Item__c newRLI = rli.clone(false,true);
                        newRLI.Line_Item_Donation_Received__c = getOldLineItemId(cloneLIlist,newRLI.Line_Item_Donation_Received__c);
                        newRLI.Line_Item_Donation_Made__c = getOldLineItemId(cloneLIlist,newRLI.Line_Item_Donation_Made__c);
                        newRLI.Cloned_Reconciled_Line_Item__c = rli.Id;
                        lstRLI.add(newRLI);
                    }
                    insert lstRLI;
                    
                    // Clone Non-Compliance
                    List<Task> allTasks = GetTaskById(setLI);
                    List<Task> cloneTasks = new List<Task>();
                    for (Task item : allTasks) {
                        Task temp = item.clone(false,true);
                        String tempWhatID = newCloneFromOldLineItem.get(item.WhatId);
                        tempWhatID = (tempWhatID.length() < 18 ? (Id)tempWhatId : tempWhatID);
                        temp.WhatId = tempWhatID;
                        cloneTasks.add(temp);
                    }
                    upsert cloneTasks;
                    
                    // Clone Note
                    List<Note> allNotes = GetNoteById(setLI);
                    List<Note> cloneNotes = new List<Note>();
                    for (Note item : allNotes) {
                        Note temp = item.clone(false,true);
                        String tempParentID = newCloneFromOldLineItem.get(item.ParentID);
                        tempParentID = (tempParentID.length() < 18 ? (Id)tempParentID : tempParentID);
                        temp.ParentID = tempParentID;
                        cloneNotes.add(temp);
                    }
                    upsert cloneNotes;
                }
            }
        }
        catch (Exception e) {
            Database.rollback(sp);
            ApexPages.addMessages(e);
        	return null;    
        }
        String newPageUrl = '/'+ this.Entity.Id;
        PageReference newPage = new PageReference(newPageUrl);
        newPage.setRedirect(true);
        return newPage;
    }
    
    public PageReference Cancel() {
        String newPageUrl = '/'+ this.doID;
        PageReference newPage = new PageReference(newPageUrl);
        newPage.setRedirect(true);
        return newPage;
    }
    
    private string getAllFields(string sObjectName){
        String objectName = sObjectName;
        String query = 'SELECT';
        Map<String, Schema.SObjectField> objectFields = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();         
        
        // Grab the fields from the describe method and append them to the queryString one by one.
        for(String s : objectFields.keySet()) {
            if (objectFields.get(s).getDescribe().isAccessible())
                query += ' ' + s + ', ';
        }
        query = query.subString(0,query.Length()-2);
        return query;
    }
    private string getOldLineItemId(List<Line_Item__c> lst, string Id) {
        for(Line_Item__c lit : lst) {
            if (lit.Cloned_Line_Item__c == Id) {
                return lit.Id;
            }
        }
        return null;
    }
    private List<Line_Item_Type__c> GetLineItemTypesByEntityId(string id){
        String objectName = 'Line_Item_Type__c';
        String query = getAllFields(objectName);
        query += ' FROM ' + objectName;
        query += ' WHERE Disclosure_Claim_for_Payment__c = \'' + id + '\' ' 
            	+' AND Line_Item_Type_Aggregated_Category__c=\'Electoral Communication Expenditure\'';        
        try {
            return database.query(query);
        } catch (QueryException e){
            return null;
        }
    }
    
    private List<Line_Item__c> GetLineItemsByLineItemTypeObj(List<Line_Item_Type__c> LITlist, String recordTypeName){
        String objectName = 'Line_Item__c';
        String query = getAllFields(objectName);
        query += ' FROM ' + objectName;
        query += ' WHERE RecordType.Name=\'' + recordTypeName + '\' AND Line_Item_Type__c IN (\'';
        for(Line_Item_Type__c lit : LITlist) {
            query += lit.Id + '\',\'';
        }
        query = query.subString(0,query.Length()-2);
        query = query + ')';
        try {
            return database.query(query);
        } catch (QueryException e){
            return null;
        }
    } 
    
    private List<Reconciled_Line_Item__c> GetReconciledLineItemsByLineItemIds(List<Line_Item__c> litIds){
        String objectName = 'Reconciled_Line_Item__c';
        String query = getAllFields(objectName);
        query += ' FROM ' + objectName;
        query += ' WHERE Line_Item_Donation_Received__c IN (\'';
        for(Line_Item__c lit : litIds) {
            query += lit.Id + '\',\'';
        }
        query = query.subString(0,query.Length()-2);
        query = query + ') OR Line_Item_Donation_Made__c IN (\'';
        for(Line_Item__c lit : litIds) {
            query += lit.Id + '\',\'';
        }
        query = query.subString(0,query.Length()-2);
		query = query + ')';        
        try {
            return database.query(query);
        } catch (QueryException e){
            return null;
        }
    }
    private List<Vouched_Line_Item__c> GetVouchedLineItem(Set<String> Ids){
        String objectName = 'Vouched_Line_Item__c';
        String query = getAllFields(objectName);
        query += ' FROM ' + objectName;
        query += ' WHERE Trim_Record__r.fuseit_s2t__Trim_Status__c=\'Synchronized\' ' +
            	' AND Trim_Record__r.Vouching_Item__c=true AND Line_Item__c IN (';
        
        for (String IdTemp : Ids) {
            query += '\'' + IdTemp + '\', ';
        }
        // TRIM last comma
        query = query.subString(0,query.Length()-2) + ')';
        try {
            return database.query(query);
        } catch (QueryException e){
            return null;
        }
    }
    private List<Task> GetTaskById(Set<String> Ids){
        String objectName = 'Task';
        String query = getAllFields(objectName);
        query += ' FROM ' + objectName;
        query += ' WHERE RecordType.Name =\'Non-Compliance\' AND WhatId IN (';
        for (String IdTemp : Ids) {
            if (IdTemp.length() < 18) {
            	IdTemp = (Id)IdTemp;
        	}
            query += '\'' + IdTemp + '\', ';
        }
        // TRIM last comma
        query = query.subString(0,query.Length()-2) + ')';
        try {
            return database.query(query);
        } catch (QueryException e){
            return null;
        }
    }
    
    private List<Note> GetNoteById(Set<String> Ids){
        String objectName = 'Note';
        String query = getAllFields(objectName);
        query += ' FROM ' + objectName;
        query += ' WHERE ParentId IN (';
        for (String IdTemp : Ids) {
            if (IdTemp.length() < 18) {
            	IdTemp = (Id)IdTemp;
        	}
            query += '\'' + IdTemp + '\', ';
        }
        // TRIM last comma
        query = query.subString(0,query.Length()-2) + ')';
        try {
            return database.query(query);
        } catch (QueryException e){
            return null;
        }
    }
}