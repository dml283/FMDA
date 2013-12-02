/* - Required on the Disclosure/Claim for Payment object.
** - Carry out some actions related specifically to the Vouching process for a Disclosure/Claim for Payment.
**   + Create multiple TRIM Records (Vouching Items) within one page
**   + Update the attributes of multiple TRIM Records (Vouching Items) within one page
**   + Synchronise multiple records within one page
**   + Review the ‘Vouching Status’ of TRIM Records within one page
**   + Review the specific related Line Items to a Vouching Item
*/
public class VouchingTRIMRecordController{
    public String doID{get;set;}
    // US5066, get Trim records from all Disclosure Claim that belong to Disclosure Obligation
    // public String cloneDoID{get;set;}
    private Set<String> allDisclosureId;
    public Map<String,String> locationUrlMap{get;set;}
    public string FilterKey{get;set;}
    public Integer RecordCounter{get;set;}
    private fuseit_s2t__Trim__c trimServer {get;set;}
    public PagingInfo TRIMRecordPagingInfo{get;set;}
    public Map<String,List<SelectOption>> lineItemTypeOptionMap{get;set;}
    public List<SelectOption> numberItemPerPageOptions{get;set;}
    public List<TRIMWrapper> TRIMWrapperList{get;set;}
	public List<string> FilterKeys{get{return new List<string>{'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','X','Y','Z','All'};}}
    public Map<string, Schema.FieldSet> GetMapTRIMRecordFieldSets(){
        return Schema.SObjectType.fuseit_s2t__Trim_record__c.fieldSets.getMap();
    }
    
    public VouchingTRIMRecordController() {
        try {
            doID = ApexPages.currentPage().getParameters().get('do');
            if (doId != null) {
                if (doId.length() < 18) {
                    doId = (Id)doId;
                }
            }
            // cloneDoID = '';
            allDisclosureId = new Set<String>();
            locationUrlMap = new Map<String,String>();
            Disclosure_Claim_for_payment__c temp = [SELECT TRIM_Container_URI__c,Cloned_Disclosure_Claim_for_Payment__c,
                                                            		Disclosure_Obligation__c
                                                            FROM Disclosure_Claim_for_payment__c
                                                            WHERE Id=:doID LIMIT 1];
            allDisclosureId.add(temp.Id);
            locationUrlMap.put(temp.Id,temp.TRIM_Container_URI__c);
            lineItemTypeOptionMap = new Map<String,List<SelectOption>>();
            trimServer = getTrimServer();
            List<Disclosure_Claim_for_payment__c> doList = [SELECT Id,TRIM_Container_URI__c,Cloned_Disclosure_Claim_for_Payment__c,
            													Disclosure_Obligation__c
                                                            FROM Disclosure_Claim_for_payment__c
                                                            WHERE Id=:doID LIMIT 1];
            if (doList.size() > 0) {
                // cloneDoID = doList.get(0).Cloned_Disclosure_Claim_for_Payment__c;
                String disObId = doList.get(0).Disclosure_Obligation__c;
                // get all Disclosure Id from Disclosure Obligation
                Map<String,Disclosure_Claim_for_payment__c> tempAllDis = new Map<String, Disclosure_Claim_for_payment__c>([
                    	SELECT Id,TRIM_Container_URI__c from Disclosure_Claim_for_payment__c where Disclosure_Obligation__c = :disObId
                	]);
                for (String key : tempAllDis.keySet()) {
                    allDisclosureId.add(key);
                    locationUrlMap.put(key, tempAllDis.get(key).TRIM_Container_URI__c);
                }
            }
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, String.valueOf(allDisclosureId)));
            List<Line_Item_Type__c> lineItemTypeList = [SELECT Id, Line_Item_Category__r.Line_Item_Category__c,Disclosure_Claim_for_Payment__c
                                                            FROM Line_Item_Type__c 
                                                            WHERE Disclosure_Claim_for_Payment__c IN :allDisclosureId
                                                            ORDER BY Order_Number__c
                                                           ];
            for (Line_Item_Type__c lit : lineItemTypeList) {
                if (!lineItemTypeOptionMap.containsKey(lit.Disclosure_Claim_for_Payment__c)) {
					lineItemTypeOptionMap.put(lit.Disclosure_Claim_for_Payment__c, new List<SelectOption>());
                    lineItemTypeOptionMap.get(lit.Disclosure_Claim_for_Payment__c).add(new SelectOption('', '--None--'));
                }
                lineItemTypeOptionMap.get(lit.Disclosure_Claim_for_Payment__c).add(new SelectOption(lit.Id, lit.Line_Item_Category__r.Line_Item_Category__c));
            }
            this.FilterKey = 'All';
            this.TRIMWrapperList = new List<TRIMWrapper>();
            numberItemPerPageOptions = getItemPerPage();
            buildPagingInfo();
        } catch (Exception e) {
            ApexPages.addMessages(e);
        }
    }
    
    public List<SelectOption> getItemPerPage() {
        List<SelectOption> numberItemPerPageOptions = new List<SelectOption>();
        numberItemPerPageOptions.add(new SelectOption('5', '5'));
        numberItemPerPageOptions.add(new SelectOption('10', '10'));
        numberItemPerPageOptions.add(new SelectOption('20', '20'));
        numberItemPerPageOptions.add(new SelectOption('50', '50'));
        numberItemPerPageOptions.add(new SelectOption('100', '100'));
        return numberItemPerPageOptions;
    }
    
    private static fuseit_s2t__Trim__c getTrimServer() {
    	fuseit_s2t__Trim__c trimServerTemp;
        String trimServerName = 'NSWEC TRIM';
        // Sandbox and production use same trim server name, comment these code
        // String s  =  System.URL.getSalesforceBaseUrl().getHost();
        // Sandbox
        // if (Pattern.matches('(.*\\.)?cs[0-9]*(-api)?\\..*force.com',s)) {
        //     trimServerName = 'NSWEC TRIM DEV';
        // } else {    //Production
        //     trimServerName = 'NSWEC TRIM';
        // }
        try
        {
        trimServerTemp = [SELECT ID,Name,fuseit_s2t__Trim_Light_IP_Address__c,fuseit_s2t__Trim_IP_Address__c,
        				fuseit_s2t__Trim_Default_Location_ID__c,fuseit_s2t__Key__c,fuseit_s2t__ClientCertificateName__c
                       FROM fuseit_s2t__Trim__c
                       WHERE Name = :trimServerName LIMIT 1];
            
        }      
        catch (Exception e)
        {
            System.debug('Error Occurred:' + '[' + e.getMessage() +' ]');            
            throw new FADMSException(e.getMessage());
        }
        return trimServerTemp;
    }
    //Build Paging Info And Build Wrapper////////////////////////////////////////////////////
    public void buildPagingInfo() {
        String query = TRIMRecordAllFields();
        String filter = ' FROM fuseit_s2t__Trim_record__c WHERE Vouching_Item__c = true AND fuseit_s2t__Parent_ID__c IN (';
        for (String Id : allDisclosureId) {
            filter += '\'' + Id + '\', ';
        }
        //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'B4 TRIM'));
        // TRIM last comma
        filter = filter.subString(0,filter.Length()-2) + ') AND Name LIKE \'' + (this.FilterKey == 'All' ? '' : this.FilterKey) + '%\' ';
        query += filter;
        //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, query));
        String countQuery = 'SELECT COUNT() ' + filter;
        try {
            //this.LineItemPagingInfo = new PagingInfo('LineItemPagingInfo', query, countQuery, 'CreatedDate','DESC');
            this.TRIMRecordPagingInfo = new PagingInfo('TRIMRecordPagingInfo', query, countQuery, 'CreatedDate','');
            TRIMRecordPagingInfo.PageSize = 5;
            QueryTRIMRecords();
        } catch(Exception ex){
            ApexPages.AddMessages(ex);
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, query));
        }
    }
    
    public void QueryTRIMRecords() {
        try {
            this.RecordCounter = 0;
            //ApexPages.addmessage (new ApexPages.Message(ApexPages.Severity.INFO,TRIMRecordPagingInfo.Query));
            List<fuseit_s2t__Trim_record__c > TRIMRecords = TRIMRecordPagingInfo.GetRecords();
            this.TRIMWrapperList = buildTRIMRecordWrapper(TRIMRecords);
        } catch(Exception ex){
            ApexPages.AddMessages(ex);
        }
    }
    
    private List<TRIMWrapper> buildTRIMRecordWrapper (List<fuseit_s2t__Trim_record__c> TRIMRecords) {
        List<TRIMWrapper> temp = new List<TRIMWrapper>();
        Set<String> trimSetId = new Set<String>();
        for (fuseit_s2t__Trim_record__c record : TRIMRecords) {
            trimSetId.add(record.Id);
        }
        
        // Check if Trim record has vouching
        Map<Id, AggregateResult> trimRecordVouchingCount = new Map<Id, AggregateResult>(
            				[SELECT Trim_Record__c Id, COUNT(Id) Cnt FROM Vouched_Line_Item__c 
                             WHERE Trim_Record__c IN :trimSetId 
                             GROUP BY Trim_Record__c]);
        
        for (fuseit_s2t__Trim_record__c record : TRIMRecords) {
            boolean hasVouching = false;
            if (trimRecordVouchingCount.containsKey(record.Id)) {
                hasVouching = true;
            }
            TRIMWrapper t = new TRIMWrapper(RecordCounter++, record, record.Line_Item_Type__r.Disclosure_Claim_For_Payment__c, false,true,hasVouching);
            temp.add(t);
        }
        return temp;
    }
    private static string TRIMRecordAllFields(){
        Map<String, Schema.SObjectField> fldObjMap = schema.SObjectType.fuseit_s2t__Trim_record__c.fields.getMap();
		List<Schema.SObjectField> fldObjMapValues = fldObjMap.values();
        
        String theQuery = 'SELECT ';
        for(Schema.SObjectField s : fldObjMapValues)
        {
           if (s.getDescribe().isAccessible()) {
           		String theName = s.getDescribe().getName();
           		theQuery += theName + ',';
            }
        }
        theQuery += ' Line_Item_Type__r.Line_Item_Category__r.Line_Item_Category__c, Line_Item_Type__r.Disclosure_Claim_for_Payment__c ';
        // Trim last comma
        // theQuery = theQuery.subString(0, theQuery.length() - 1);
        theQuery = theQuery.replaceAll('LastReferencedDate,','');
        // Remove LastReferencedDate;
        
        return theQuery;
    }
    // End
    
    // Action Function Add, Del, Edit, Cancel////////////////////////////////////////////
    public void btnAddRowClick() {
        fuseit_s2t__Trim_record__c record = new fuseit_s2t__Trim_record__c(
            fuseit_s2t__Parent_ID__c=doID,Vouching_Item__c = true,
            fuseit_s2t__Attachment_Type__c = 'Attachment',
            fuseit_s2t__Trim_Location_ID__c = locationUrlMap.get(doId)
        );
        
        if (trimServer != null) {
            record.fuseit_s2t__Trim_ID__c = trimServer.Id;
        }
		if (TRIMWrapperList.size() > 0)
        	TRIMWrapperList.add(0,new TRIMWrapper(RecordCounter++, record, doId));
        else
            TRIMWrapperList.add(new TRIMWrapper(RecordCounter++, record, doId));
    }

    public void btnEditRowClick() {
        try{
            Integer recordId = Integer.valueOf(ApexPages.CurrentPage().GetParameters().Get('recordID'));
        	Integer index = findTRIMRecordWrap(recordId);
            if (index != -1) {
                TRIMWrapper record = TRIMWrapperList.get(index);
                record.isEdit = true;
            }
        } catch(Exception ex){
            ApexPages.AddMessages(ex);
        }
    }
    
    public void btnSaveRowClick() {
        try{
            //ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.Info,'1'));
            Integer recordId = Integer.valueOf(ApexPages.CurrentPage().GetParameters().Get('recordID'));
        	Integer index = findTRIMRecordWrap(recordId);
            if (index != -1) {
                TRIMWrapper record = TRIMWrapperList.get(index);
                // Store more fields
                String extension = '';String tempName = record.item.fuseit_s2t__Attachment_Name__c;
                if (tempName.contains('.')) {
                    extension = tempName.subString(tempName.lastIndexOf('.') + 1);
                } 
                record.item.fuseit_s2t__File_Extension__c = extension;
                record.item.fuseit_s2t__Attachment_Type__c = 'Attachment';
                upsert record.item;
                record.isEdit = false;
                record.isExist = true;
                List<fuseit_s2t__Trim_record__c> tempList = getTrimRecord(record.Item.Id);
                record.Item = tempList.get(0);
                //ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.Info,'Trim Record Id:' + record.Item.Id));
            }
        } catch(Exception ex){
            ApexPages.AddMessages(ex);
        }
    }
    
    public void btnDelRowClick() {
        try{
            Integer recordId = Integer.valueOf(ApexPages.CurrentPage().GetParameters().Get('recordID'));
        	Integer index = findTRIMRecordWrap(recordId);
            if (index != -1) {
                TRIMWrapper record = TRIMWrapperList.get(index);
                delete record.item;
                TRIMWrapperList.remove(index);
            }
        } catch(Exception ex){
            ApexPages.AddMessages(ex);
        }
    }
    
    public void btnCancelRowClick() {
        try{
            Integer recordId = Integer.valueOf(ApexPages.CurrentPage().GetParameters().Get('recordID'));
        	Integer index = findTRIMRecordWrap(recordId);
            if (index != -1) {
                TRIMWrapper record = TRIMWrapperList.get(index);
                if (record.isExist) {
                    List<fuseit_s2t__Trim_record__c> tempList = getTrimRecord(record.Item.Id);
					if (tempList.size() > 0) {
						record.Item = tempList.get(0);
					}
                    record.isEdit = false;
                } else {
	                TRIMWrapperList.remove(index);
                }
            }
        } catch(Exception ex){
            ApexPages.AddMessages(ex);
        }
    }
    private List<fuseit_s2t__Trim_record__c> getTrimRecord(String Id) {
        String query = TRIMRecordAllFields();
        query += ' FROM fuseit_s2t__Trim_record__c WHERE Id=\'' + Id + '\' LIMIT 1';
        return Database.query(query);
    }
    private List<fuseit_s2t__Trim_record__c> getTrimRecords(Set<String> Ids) {
        String query = TRIMRecordAllFields();
        query += ' FROM fuseit_s2t__Trim_record__c WHERE Id IN :Ids';
        return Database.query(query);
    }
    public PageReference btnBackClick() {
        return new PageReference('/'+doID);
    }
    
    public void btnSyncClick() {
        Savepoint sp = Database.setSavepoint();
        try{
            if (!Schema.sObjectType.fuseit_s2t__Trim_record__c.fields.fuseit_s2t__Trim_Status__c.isUpdateable()){
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to Synchronize record'));
				return;
			}
			if (trimServer == null) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'TRIM server not found'));
				return;
			}
            List<fuseit_s2t__Trim_record__c> upsertList = new List<fuseit_s2t__Trim_record__c>();
            Set<String> TrimRecordIds = new Set<String>();
            for (Integer i = 0; i < TRIMWrapperList.size(); i++) {
                TRIMWrapper record = TRIMWrapperList.get(i);
                if (record.isInclude && record.isExist && !record.isEdit) {
                    record.Item.fuseit_s2t__Trim_Status__c = 'Processing';
                    record.Item.fuseit_s2t__Logging__c = '';
                    upsertList.add(record.Item);
                    TrimRecordIds.add(record.Item.Id);
                }
            }
            upsert upsertList;
            Database.executeBatch(new TrimRecordSynBatchController(TrimRecordIds), 5);
            //bulkSynchronize(TrimRecordIds);
        } catch (DMLException e) {
        	Database.rollback(sp);
			ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Error trying to Sync record.\n Message:' + e.getMessage()));
	    }
    }
    
//    @future(callout=true)
//    public static void bulkSynchronize(Set<String> trimRecordIds) {
//        String query = TRIMRecordAllFields();
//        query += ' FROM fuseit_s2t__Trim_record__c WHERE Id IN :trimRecordIds';
//        List<fuseit_s2t__Trim_record__c> records = Database.query(query);
//        fuseit_s2t__Trim__c trimServer = getTrimServer();
//    	Set<String> attIds = new Set<String>();
//    	for (fuseit_s2t__Trim_record__c rec : records) {
//    		attIds.add(rec.fuseit_s2t__Attachment_ID__c);
//    	}
//    	Map<Id, Attachment> attachmentsMap = new Map<Id,Attachment>(
//    		[Select Id, ParentId, Name, Body, CreatedDate
//    			FROM Attachment WHERE Id IN :attIds]
//    	);
//        Integer i = 1;
//        for (fuseit_s2t__Trim_record__c rec : records) {
//        	System.debug('vinhvinh: Callout time: ' + (i++));
//            //rec = fuseit_s2t.TrimConnector.synchronizeRecord(trimServer, rec, UserInfo.getUserId(), null,
//            //                                                 attachmentsMap.get(rec.fuseit_s2t__Attachment_ID__c).Body, 
//            //                                                 attachmentsMap.get(rec.fuseit_s2t__Attachment_ID__c).CreatedDate,
//            //                                                 false);
//        }
//        upsert records;
//    }
    
    public void btnRefreshClick() {
    	Set<String> trimIds = new Set<String>();
    	for (Integer i = 0; i < TRIMWrapperList.size(); i++) {
            TRIMWrapper record = TRIMWrapperList.get(i);
            if (record.isExist && !record.isEdit) {
                trimIds.add(record.Item.Id);
            }
        }
        List<fuseit_s2t__Trim_record__c> tempList = getTrimRecords(trimIds);
        Map<Id,fuseit_s2t__Trim_record__c> tempMap = new Map<Id,fuseit_s2t__Trim_record__c>();
        for(fuseit_s2t__Trim_record__c rec : tempList) {
        	tempMap.put(rec.Id, rec);
        }
        for (Integer i = 0; i < TRIMWrapperList.size(); i++) {
            TRIMWrapper record = TRIMWrapperList.get(i);
            if (record.isExist && !record.isEdit) {
                record.Item = tempMap.get(record.Item.Id);
            }
        }
    }
    
    private Integer findTRIMRecordWrap(Integer recordId) {
        Integer index = -1;
        for (Integer i = 0; i < TRIMWrapperList.size(); i++) {
            if (TRIMWrapperList[i].Id == recordId) {
                index = i;
                break;
            }
        }
        return index;
    }
    // End Action Function Add, Del, Edit, Cancel/////////////////////////////////////////
    //TRIM Record Wrapper/////////////////////////////////////////////////////////////////
    public class TRIMWrapper {
        public fuseit_s2t__Trim_record__c item{get;set;}
        public Integer Id{get;set;}
        public boolean isEdit{get;set;}
        public boolean isExist{get;set;}
        public boolean isInclude{get;set;}
        public boolean hasVouching{get;set;}
        public String disclosureId{get;set;}
        public TRIMWrapper(Integer IdCounter, fuseit_s2t__Trim_record__c  item, String disclosureId) {
            this(IdCounter, item,disclosureId, true, false);
        }
        public TRIMWrapper(Integer IdCounter, fuseit_s2t__Trim_record__c  item, String disclosureId, boolean isEdit, boolean isExist) {
            this(IdCounter, item, disclosureId, isEdit, isExist, false);
        }
        public TRIMWrapper(Integer IdCounter, fuseit_s2t__Trim_record__c  item, String disclosureId, boolean isEdit, boolean isExist, boolean hasVouching) {
            this.Id = IdCounter;
            this.item = item;
            this.isEdit = isEdit;
            this.isExist = isExist;
            this.isInclude = false;
            this.hasVouching = hasVouching;
            this.disclosureId = disclosureId;
        }
    }
    // End TRIM Record Wrapper///////////////////////////////////////////////////////////
}