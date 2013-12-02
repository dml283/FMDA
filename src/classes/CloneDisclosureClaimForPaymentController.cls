/* -  Clones the Disclosure/Claim for Payment record, 
** along with any associated Line Item Types, Line Items, Reconciled Line Items and Vouched Line Item records.
** - Clone template record (called from AssociateLineItemTypeAsPerTemp function of DisclosureTriggerHandler)
*/
public with sharing class CloneDisclosureClaimForPaymentController{
    // For LineItemTrigger
    public static boolean isCloning = false;
    
    Public String DCPId {get;set;}
    Public String tmpDCPId {get;set;}
    Map<String, Boolean> isBelongToList{get;set;}
    Map<String, String> listRecordType = new Map<String,String>();
    public CloneDisclosureClaimForPaymentController(ApexPages.StandardController sc) {
        this.DCPId = ((Disclosure_Claim_for_Payment__c)sc.getRecord()).Id;
        System.debug('Get ID: ' + DCPId);
        
        for (RecordType r : [SELECT Id, Name FROM RecordType]) {
            listRecordType.put (r.Name, r.Id);
        }
        //deepClone(DCPId,'');
    }
    public CloneDisclosureClaimForPaymentController() {
        this.DCPId = ApexPages.CurrentPage().GetParameters().Get('Id');
        System.debug('Get ID33: ' + DCPId);
        for (RecordType r : [SELECT Id, Name FROM RecordType]) {
            listRecordType.put (r.Name, r.Id);
        }
        //deepClone(DCPId,'');
    }
    public CloneDisclosureClaimForPaymentController(String tmpId, String Id) {
        this.tmpDCPId = tmpId;
        this.DCPId = Id;
        for (RecordType r : [SELECT Id, Name FROM RecordType]) {
            listRecordType.put (r.Name, r.Id);
        }
    }
    
    //deepClone Disclosure_Claim_for_Payment__c by Id & recordTypeId
    //public PageReference deepClone(string Id, string recordTypeId) {
    
    /*
    public PageReference deepClone(){
        return executeDeepClone(null);
    }*/
        
    public PageReference deepClone() {
        String Id = DCPId;
        //System.debug('Get ID1: ' + Id);
        //setup the save point for rollback
        Savepoint sp = Database.setSavepoint();
        //System.debug('Get ID: OK sp');
        Disclosure_Claim_for_Payment__c newDCP;
        List<Line_Item_Type__c> lstLIT;
        List<Line_Item__c> lstLI;
        List<Line_Item_Type__c> curLstLIT;
        List<Line_Item__c> curLstLI;
        List<Vouched_Line_Item__c> lstVLI;
        List<Reconciled_Line_Item__c> lstRLI;
        Set<Id> setLIT;
        Set<String> setLI;
        
        String doId = Id;
        if (doId.length() < 18) {
            doId = (Id)doId;
        }
        try {
            //Clone Disclosure/Claim for Payment
            Disclosure_Claim_for_Payment__c curDCP = GetEntityById(Id, null);
            //System.debug('get curDCP: OK ' + curDCP.Id);
            //if(newDCP == null){
                newDCP = curDCP.clone(false,true);
            	newDCP.Cloned_Disclosure_Claim_for_Payment__c = curDCP.Id;
                newDCP.Active__c = true;
                newDCP.Version_Number__c = curDCP.Version_Number__c + 1;
            //}
            curDCP.Active__c = false;
            upsert curDCP;
            //System.debug('upsert curDCP: OK');
            upsert newDCP;
            //System.debug('insert newDCP: OK');
            
            //Clone Line Item Type
            lstLIT = new List<Line_Item_Type__c>();
            setLIT = new Set<Id>();
            curLstLIT = GetLineItemTypesByEntityId(Id);
            if (curLstLIT != null && curLstLIT.size()>0) {
                Map<String,String> newCloneFromOldLineItemType = new Map<String,String>();
                for (Line_Item_Type__c lit : curLstLIT) {
                    Line_Item_Type__c newLIT = lit.clone(false,true);
                    newLIT.Disclosure_Claim_for_Payment__c = newDCP.Id;
                    newLIT.Cloned_Line_Item_Type__c = lit.Id;
                    setLIT.add(newDCP.Id);
                    lstLIT.add(newLIT);
                }
                insert lstLIT;
                for (Line_Item_Type__c lit : lstLIT) {
                    newCloneFromOldLineItemType.put(lit.Cloned_Line_Item_Type__c,lit.Id);
                }
                //System.debug('insert lstLIT: OK');
                
                //Clone Line Item
                // This map is to store the Clone Line Item Id
                Map<String,String> newCloneFromOldLineItem = new Map<String,String>();
                lstLI = new List<Line_Item__c>();
                curLstLI = GetLineItemsByLineItemTypeIds(curLstLIT,'Line Item');
                if (curLstLI != null && curLstLI.size()>0) {
                    setLI = new Set<String>();
                    for (Line_Item__c li : curLstLI) {
                        Line_Item__c newLI = li.clone(false,true);
                        newLI.Line_Item_Type__c = newCloneFromOldLineItemType.get(li.Line_Item_Type__c);
                        newLI.Cloned_Line_Item__c = li.Id;
                        setLI.add(li.Id);
                        lstLI.add(newLI);
                        System.debug('add lstLI: ' + newLI.Id);
                    }
                	isCloning = true;
                    insert lstLI;
                	isCloning = false;
                    //System.debug('insert lstLI: OK');
                    // Put to map
                    for (Line_Item__c item : lstLI) {
                        newCloneFromOldLineItem.put(item.Cloned_Line_Item__c,item.Id);
                    }
                    // Clone Audit Line Item
                    List<Line_Item__c> curAuditLstLI = GetLineItemsByLineItemTypeIds(curLstLIT,'Audit Line Item');
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
                    isCloning = true;
                    insert  cloneAuditList;
                    isCloning = false;
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
                    lstRLI = new List<Reconciled_Line_Item__c>();
                    for (Reconciled_Line_Item__c rli : GetReconciledLineItemsByLineItemIds(curLstLI)) {
                        Reconciled_Line_Item__c newRLI = rli.clone(false,true);
                        newRLI.Line_Item_Donation_Received__c = getOldLineItemId(lstLI,newRLI.Line_Item_Donation_Received__c);
                        newRLI.Line_Item_Donation_Made__c = getOldLineItemId(lstLI,newRLI.Line_Item_Donation_Made__c);
                        newRLI.Cloned_Reconciled_Line_Item__c = rli.Id;
                        lstRLI.add(newRLI);
                    }
                    insert lstRLI;
                    //System.debug('insert lstRLI: OK');
                    
            		// Clone Non-Compliance
                    
                    setLI.add(doID);
                    newCloneFromOldLineItem.put(doID,doID);
                    List<Task> allTasks = GetTaskById(setLi);
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
                    
                    // Clone Audit checklist...
                    
                    List<Audit_Checklist__c> auditChecklists = [SELECT id,Disclosure_Claim_for_Payment__c,IsTemplate__c,Template_Description__c,	Template_Name__c
                    										    FROM Audit_Checklist__c 
                    										    WHERE Disclosure_Claim_for_Payment__c	= :Id];	        		
                    List<Audit_Checklist__c> clonedAuditCheckList =  AuditUtilities.cloneAuditCheckLists(auditChecklists);
                    
                    for(Audit_Checklist__c item:clonedAuditCheckList){
                    	item.Disclosure_Claim_for_Payment__c = newDCP.id;
                    }
                    update clonedAuditCheckList;                   
                    
                }
            }
            
            String newPageUrl = '/'+ newDCP.Id;
            PageReference newPage = new PageReference(newPageUrl);
            newPage.setRedirect(true);
            return newPage;
        } catch (Exception e) {
            Database.rollback(sp);
            ApexPages.addMessages(e);
            return null;        	  
        }
        return null;
    }
    
    public void CloneTempt() {
        //setup the save point for rollback
        Savepoint sp = Database.setSavepoint();
        System.debug('Get ID: OK sp' + this.tmpDCPId);
        List<Line_Item_Type__c> lstLIT;
        List<Line_Item__c> lstLI;
        List<Line_Item_Type__c> curLstLIT;
        List<Line_Item__c> curLstLI;
        
        try {
            Set<String> StakeHolderList = new Set<String>();
            this.isBelongToList = new Map<String, Boolean>();
            Disclosure_Claim_for_Payment__c curDCP = GetEntityByIdTemp(this.DCPId, null);
            System.debug('Disclosure_Claim_for_Payment__c curDCP: ' + this.DCPId);
            //Clone Line Item Type
            //Because clone from template => Cloned_Line_Item_Type__c = null
            //=> we use Map<String, String> to link to previous Line_Item_Type__c
            Map<String, String> LineItemTypeCollection = new Map<String, String>();
            lstLIT = new List<Line_Item_Type__c>();
            curLstLIT = GetLineItemTypesByEntityId(this.tmpDCPId);
            if (curLstLIT != null && curLstLIT.size()>0) {
                for (Line_Item_Type__c lit : curLstLIT) {
                    Line_Item_Type__c newLIT = lit.clone(false);
                    newLIT.Disclosure_Claim_for_Payment__c = this.DCPId;
                    insert newLIT;
                    LineItemTypeCollection.Put(lit.Id, newLIT.Id);
                    System.debug('put Line_Item_Type__c: ' + lit.Id);
                    //lstLIT.add(newLIT);
                    //String referenceNumber = lit.Line_Item_Category__r.Reference_Number__c;
                    Line_Item_Category__c lic = [SELECT Id, Reference_Number__c FROM Line_Item_Category__c WHERE Id=:lit.Line_Item_Category__c];
                    String referenceNumber = lic.Reference_Number__c;
                    System.debug('isBelongToList: ' + referenceNumber);
                    if (referenceNumber.equals('1001') || referenceNumber.equals('1005')) {
                        System.debug('isBelongToList_if: OK');
        				this.isBelongToList.Put(lit.Id, true);
                    }else{
                        System.debug('isBelongToList_else: OK');
                        this.isBelongToList.Put(lit.Id, false);
                    }
                    System.debug('isBelongToList: OK');
                }
                //insert lstLIT;
                System.debug('insert lstLIT_Clone Tmp: OK');
                
                //Clone Line Item
                lstLI = new List<Line_Item__c>();
                curLstLI = GetLineItemsByLineItemTypeIds(curLstLIT, 'Line Item');
                if (curLstLI != null && curLstLI.size()>0) {
                    for (Line_Item__c li : curLstLI) {
                        Line_Item__c newLI = li.clone(false,true);
                        //newLI.Line_Item_Type__c = getOldLineItemTypeId(lstLIT,newLI.Line_Item_Type__c);
                        System.debug('get Line_Item_Type__c: ' + newLI.Line_Item_Type__c);
                        newLI.Line_Item_Type__c = LineItemTypeCollection.Get(newLI.Line_Item_Type__c);
                        lstLI.add(newLI);
                        System.debug('add lstLI: ' + newLI.Id);
                        // Add stakeholder to list if line item type is 1001 or 1005
                        //for(string key: this.isBelongToList.KeySet()){
                            if(this.isBelongToList.Get(li.Line_Item_Type__c)&& li.Stakeholder__c!=null){
                                StakeHolderList.Add(li.Stakeholder__c);
                            }
                        //}
                    }
                    insert lstLI;
                    System.debug('insert lstLI_Clone Tmp: OK');
                    
                    List<Disclosure_Obligation__c> existDOList = [
                            SELECT Stakeholder__c
                            FROM Disclosure_Obligation__c
                            WHERE Reporting_Period__c = :curDCP.Disclosure_Obligation__r.Reporting_Period__c
                            AND Stakeholder__c IN :StakeHolderList
                    ];
                    Set<String> existStakeHolder = new Set<String>();
                    for (Disclosure_Obligation__c disO : existDOList) {
                        existStakeHolder.add(disO.Stakeholder__c);
                    }
                    List<Disclosure_Obligation__c> upsertDOList = new List<Disclosure_Obligation__c>();
                    
                    for (String stakeHolderId : StakeHolderList) {
                        // If there's no DO for current stakeholder, adding it to upsertList
                        if (!existStakeHolder.contains(stakeHolderId)) {
                            Disclosure_Obligation__c disclosure_ob = new Disclosure_Obligation__c();
                            disclosure_ob.Reporting_Period__c = curDCP.Disclosure_Obligation__r.Reporting_Period__c;
                            disclosure_ob.Stakeholder__c = stakeHolderId;
                            upsertDOList.add(disclosure_ob);
                        }
                    }
                    
                    upsert upsertDOList;
                }
            }
        } catch (Exception e) {
            Database.rollback(sp);
        }
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
        // Strip off the last comma if it exists.
        //if (query.subString(query.Length()-1,query.Length()) == ', '){
            query = query.subString(0,query.Length()-2);
        //}
        return query;
    }
    
    private string getOldLineItemTypeId(List<Line_Item_Type__c> lst, string Id) {
        for(Line_Item_Type__c lit : lst) {
            if (lit.Cloned_Line_Item_Type__c == Id) {
                return lit.Id;
            }
        }
        return null;
    }
    
    private string getOldLineItemId(List<Line_Item__c> lst, string Id) {
        for(Line_Item__c lit : lst) {
            if (lit.Cloned_Line_Item__c == Id) {
                return lit.Id;
            }
        }
        return null;
    }
    
    public Disclosure_Claim_for_Payment__c GetEntityByIdTemp(string id, string recordTypeId){
        if(id == null && recordTypeId != null){//load template record
            return [
                SELECT Id, Name, IsTemplate__c,Disclosure_Obligation__r.Reporting_Period__c
                FROM Disclosure_Claim_for_Payment__c
                WHERE RecordTypeId = :recordTypeId AND IsTemplate__c = true
                LIMIT 1
            ];
        }
        else if(id != null){
            return [
                SELECT Id, Name, IsTemplate__c, Cloned_Disclosure_Claim_for_Payment__c,Disclosure_Obligation__r.Reporting_Period__c
                FROM Disclosure_Claim_for_Payment__c
                WHERE Id = :id
                LIMIT 1
            ];
        }
    	return null;
    }
    
    public Disclosure_Claim_for_Payment__c GetEntityById(string id, string recordTypeId){
        String objectName = 'Disclosure_Claim_for_Payment__c';
        String query = getAllFields(objectName);
        // Add FROM statement
        query += ' FROM ' + objectName;
        // Add on a WHERE/ORDER/LIMIT statement as needed
        if(id == null && recordTypeId != null){//load template record
            query += ' WHERE RecordTypeId = : ' + recordTypeId + ' LIMIT 1';
        }
        else if(id != null){
            query += ' WHERE Id = \'' + id + '\' LIMIT 1';
        }
        
        try {
            System.debug('Exception: GetEntityById1: ' + query);
            return database.query(query);
            
        } catch (QueryException e){
            System.debug('Exception: GetEntityById');
            return null;
        }    	
    }
    
    private List<Line_Item_Type__c> GetLineItemTypesByEntityId(string id){
        String objectName = 'Line_Item_Type__c';
        String query = getAllFields(objectName);
        // Add FROM statement
        query += ' FROM ' + objectName;
        // Add on a WHERE/ORDER/LIMIT statement as needed
        query += ' WHERE Disclosure_Claim_for_Payment__c = \'' + id + '\'';        
        try {
            System.debug('Exception: GetLineItemTypesByEntityId: ' + query);
            return database.query(query);
        } catch (QueryException e){
            return null;
        }
    }
    // RecordTypeName: Audit Line Item or Line Item
    private List<Line_Item__c> GetLineItemsByLineItemTypeIds(List<Line_Item_Type__c> litIds, String recordTypeName){
        String objectName = 'Line_Item__c';
        String query = getAllFields(objectName);
        // Add FROM statement
        query += ' FROM ' + objectName;
        // Add on a WHERE/ORDER/LIMIT statement as needed
        query += ' WHERE RecordType.Name=\'' + recordTypeName + '\' AND Line_Item_Type__c IN (\'';
        for(Line_Item_Type__c lit : litIds) {
            query += lit.Id + '\',\'';
        }
        query = query.subString(0,query.Length()-2);
        query = query + ')';
        try {
            System.debug('Exception: GetLineItemsByLineItemTypeIds: ' + query);
            return database.query(query);
        } catch (QueryException e){
            return null;
        }
    } 
     
    private List<Reconciled_Line_Item__c> GetReconciledLineItemsByLineItemIds(List<Line_Item__c> litIds){
        String objectName = 'Reconciled_Line_Item__c';
        String query = getAllFields(objectName);
        // Add FROM statement
        query += ' FROM ' + objectName;
        // Add on a WHERE/ORDER/LIMIT statement as needed
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
            System.debug('Exception: GetReconciledLineItemsByLineItemIds: ' + query);
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
            System.debug('Exception: GetVouchedLineItem: ' + query);
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
            //System.debug('Exception: GetTaskById: ' + query);
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
    
    private List<Audit_Checklist__c> GetAuditChecklistByParent(String parentId) {
        return [Select Id, Name, Disclosure_Claim_for_Payment__c, IsTemplate__c,
                Template_Description__c, Template_Name__c
                From Audit_Checklist__c
                WHERE Disclosure_Claim_for_Payment__c = :parentId ];
    }
}