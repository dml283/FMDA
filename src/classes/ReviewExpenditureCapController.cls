public class ReviewExpenditureCapController{
    public Map<String, Static_Label__c> Labels{get;set;}
    public List<litWrapper> lineItemTypeWrap{get;set;}
    public transient Map<string, Schema.FieldSet> MapLineItemFieldSets;
    public String doId{get;set;}
    public String recordTypeName{get;set;}
    public static String lineItemrecordType = [SELECT Id, name FROM RecordType WHERE name = 'Audit Line Item' LIMIT 1].Id;
    public static String lineItemAllFieldsQuery = LineItemAllFields();
    public String reloadLitId{get;set;}
    public List<SelectOption> numberItemPerPageOptions{get;set;}
    public boolean isCloneDisclosureObject{get;set;}
    public Map<string, Schema.FieldSet> GetMapLineItemFieldSets(){
        return Schema.SObjectType.Line_Item__c.fieldSets.getMap();
    }
    public String ExpenditureCap {
        get{
            String temp = lineItemTypeWrap.get(0).lit.Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Expenditure_Cap__r.Name;
            return (temp == null ? '' : temp);
        }
    }
    public String Amount {
        get{
            Decimal temp = lineItemTypeWrap.get(0).lit.Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Expenditure_Cap__r.Amount__c;
            return (temp == null ? '0' : String.valueof(temp));
        }
    }
    public String TotalExpenditure {
        get{
            Decimal temp = lineItemTypeWrap.get(0).lit.Disclosure_Claim_for_Payment__r.Electoral_Expenditure__c;
            return (temp == null ? '0' : String.valueof(temp));
        }
    }
    public String Difference {
        get{
            Decimal temp1 = lineItemTypeWrap.get(0).lit.Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Expenditure_Cap__r.Amount__c;
            Decimal temp2 = lineItemTypeWrap.get(0).lit.Disclosure_Claim_for_Payment__r.Electoral_Expenditure__c;
            temp1 = (temp1 == null ? 0 : temp1);
            temp2 = (temp2 == null ? 0 : temp2);
            return String.valueof(temp1 - temp2);
        }
    }
    //For US5063
    public String TotalECE {
        get{
            Decimal temp = lineItemTypeWrap.get(0).lit.Disclosure_Claim_for_Payment__r.Electoral_Communication_Expenditure__c;
            return (temp == null ? '0' : String.valueof(temp));
        }
    }
    public String DifferenceECE {
        get{
            Decimal temp1 = lineItemTypeWrap.get(0).lit.Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Expenditure_Cap__r.Amount__c;
            Decimal temp2 = lineItemTypeWrap.get(0).lit.Disclosure_Claim_for_Payment__r.Electoral_Communication_Expenditure__c;
            temp1 = (temp1 == null ? 0 : temp1);
            temp2 = (temp2 == null ? 0 : temp2);
            return String.valueof(temp1 - temp2);
        }
    }
    //End US5063
    
	public ReviewExpenditureCapController(){
        try{
            this.doID = ApexPages.currentPage().getParameters().get('do');
            String tempRecordName = [Select RecordType.Name from Disclosure_Claim_for_payment__c where id=:doID][0].RecordType.Name;
            if (tempRecordname.startsWith('Disclosure')) {
                this.RecordTypeName = 'Disclosure Non-Compliance';
            } else {
                this.RecordTypeName = 'Claim for Payment Non-Compliance';
            }
            List<Line_Item_Type__c> lineItemTypeList = [
                SELECT Id, Name, Line_Item_Category__r.Line_Item_Category__c,
                Line_Item_Category__r.Reference_Number__c,
                Calculated_Amount__c,Form_Amount__c,Calculated_Count__c,Form_Count__c,
                Calculated_Audit_Amount__c,Calculated_Audit_Count__c,
            	Line_Item_Category__r.Calculated_Total_Amount__c,Line_Item_Category__r.Form_Total_Amount__c,
            	Line_Item_Category__r.Calculated_Total_Count__c,Line_Item_Category__r.Form_Total_Count__c,
                Line_Item_Category__r.Calculated_Total_Audit_Amount__c,Line_Item_Category__r.Calculated_Total_Audit_Count__c,
            	Line_Item_Category__r.Remove_Row__c,Line_Item_Category__r.Default_Number_of_Rows__c,
                Disclosure_Claim_for_Payment__r.Name,Nil_Disclosure_Claim_for_Payment__c,
                Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Expenditure_Cap__c,
                Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Expenditure_Cap__r.Name,
                Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Expenditure_Cap__r.Amount__c,
                Disclosure_Claim_for_Payment__r.Electoral_Expenditure__c, 
                Disclosure_Claim_for_Payment__r.Electoral_Communication_Expenditure__c ,
                Disclosure_Claim_for_Payment__r.Cloned_Disclosure_Claim_for_Payment__c
                FROM Line_Item_Type__c 
                WHERE Disclosure_Claim_for_Payment__c = :doID
                AND (Line_Item_Category__r.Aggregated_Category__c = 'Electoral Expenditure' OR 
                     Line_Item_Category__r.Aggregated_Category__c = 'Electoral Communication Expenditure')
                ORDER BY Order_Number__c
            ];
            if (lineItemTypeList.size() == 0) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'No Electoral Expenditure'));
	            isCloneDisclosureObject = false;
            } else {
                isCloneDisclosureObject = (lineItemTypeList.get(0).Disclosure_Claim_for_Payment__r.Cloned_Disclosure_Claim_for_Payment__c != null);
            }
            this.Labels = Static_Label__c.GetAll();
            lineItemTypeWrap = new List<litWrapper>();
            numberItemPerPageOptions = getItemPerPage();
            // Set Id of LineItemType
            Set<String> litIdList = new Set<String>();
            for (Line_Item_Type__c lit : lineItemTypeList) {
				litIdList.add(lit.Id);
            }
            // Query to get All Line Items
            List<Line_Item__c> lineItemList = getLineItemBySetId(litIdList);
            //Set Id of LineItem
            Set<String> lineItemIdList = new Set<String>();
            // Add to Map
            Map<String, List<Line_Item__c>> lineItemMap = new Map<String, List<Line_Item__c>>();
            for (Line_Item__c li : lineItemList) {
                if (lineItemMap.get(li.Line_Item_Type__c) == null) {
                    lineItemMap.put(li.Line_Item_Type__c, new List<Line_Item__c>());
                }
                lineItemMap.get(li.Line_Item_Type__c).add(li);
                lineItemIdList.add(li.Id);
            }
            // For note
       	 	Map<Id, AggregateResult> LineItemsNoteCount = new Map<Id, AggregateResult>(
            				[SELECT ParentId Id, COUNT(Id) Cnt FROM Note 
                             WHERE ParentId IN :lineItemIdList 
                             GROUP BY ParentId]);
            
            for (Line_Item_Type__c lit : lineItemTypeList) {
                litWrapper temp = new litWrapper(lit);
                
                if (lineItemMap.get(lit.Id) != null) {
                    List<Line_Item__c> tempList = lineItemMap.get(lit.Id);
                    temp.LineItemPagingInfo.TotalCount = tempList.size();
                    if (tempList.size() <= 5) {
						// Add all
                        temp.LineItemPagingInfo.CurrentPageSize = tempList.size();
                        // build Wrapper
                        temp.liList = buildliWrapper(LineItemsNoteCount,tempList,tempList.size());
                    } else {
                        // Just add 5 records
                        temp.LineItemPagingInfo.CurrentPageSize = 5;
                        temp.liList = buildliWrapper(LineItemsNoteCount,tempList,5);
                    }
                } else {
                    temp = new litWrapper(lit);
                }
                lineItemTypeWrap.add(temp);
            }
            reloadLitId = '';
            /* Old Method, query in loop -> should not
            for (Line_Item_Type__c lit : lineItemTypeList) {
                litWrapper temp = new litWrapper(lit);
                lineItemTypeWrap.add(temp);
            }*/
            
        } catch (Exception e) {
            ApexPages.addMessages(e);
        }
    }
    private List<liWrapper> buildliWrapper(Map<Id, AggregateResult> LineItemsNoteCount, List<Line_Item__c> tempList, Integer count) {
        List<liWrapper> retLiWrap = new List<liWrapper>();
        for (Integer i = 0; i < count; i++) {
            Boolean hasNote = LineItemsNoteCount.containsKey(tempList.get(i).Id);
            liWrapper t = new liWrapper(tempList.get(i),hasNote);
            retLiWrap.add(t);
        }
        return retLiWrap;
    }
    private List<Line_Item__c> getLineItemBySetId (Set<String> litIdList) {
        String query = lineItemAllFieldsQuery;
        query += ' FROM Line_Item__c WHERE Line_Item_Type__c IN (\'' + String.Join(new List<string>(litIdList),'\',\'')+'\')'
            		+ ' AND Active__c = true AND Line_Item_Status__c=\'Audited\' AND RecordTypeId=\'' + lineItemrecordType + '\' ORDER BY CreatedDate' ;
        return Database.query(query);
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
    public void ReloadLitTable() {
        
        for(litWrapper litW : lineItemTypeWrap) {
            if (reloadLitId == litW.lit.Id ) {
                litW.QueryLineItemTypes();
                break;
            }
        }
    }
    public class litWrapper {
        public Line_Item_Type__c lit{get;set;}
        public List<liWrapper> liList{get;set;}
	    public PagingInfo LineItemPagingInfo{get;set;}
        public litWrapper (Line_Item_Type__c lit) {
            this (lit,new List<liWrapper>());
        }
        public litWrapper (Line_Item_Type__c lit, List<liWrapper> liList) {
            this.lit = lit;
            this.liList = liList;
            buildPagingInfo();
        }
        public void buildPagingInfo() {
            String query = lineItemAllFieldsQuery;
            String filter = ' FROM Line_Item__c WHERE Line_Item_Type__c=\'' + lit.Id + '\''
                            + ' AND Active__c = true AND Line_Item_Status__c=\'Audited\' AND RecordTypeId=\'' + lineItemrecordType + '\' ';
            query += filter;
        	String countQuery = 'SELECT COUNT() ' + filter;
            try {
                LineItemPagingInfo = new PagingInfo('LineItemPagingInfo', query, countQuery, 'CreatedDate','');
                LineItemPagingInfo.PageSize = 5;
                LineItemPagingInfo.PageIndex = 1;
                LineItemPagingInfo.TotalCount = 0;
                LineItemPagingInfo.CurrentPageSize = 0;
                // Comment because query in loop, just build the paging info in this function
                //QueryLineItemTypes();
            } catch(Exception ex){
                ApexPages.AddMessages(ex);
            }
        }
        public void QueryLineItemTypes(){
            try {
                List<Line_Item__c> liListTemp = LineItemPagingInfo.GetRecords();
                liList = buildLiWrapper(liListTemp);
            } catch(Exception ex){
                ApexPages.AddMessages(ex);
            }
        }
        private List<liWrapper> buildLiWrapper(List<Line_Item__c> liList) {
            Set<String> liIdList = new Set<String>();
            for (Line_Item__c li : liList) {
                liIdList.add(li.Id);
            }
            // For note
        	Map<Id, AggregateResult> LineItemsNoteCount = new Map<Id, AggregateResult>(
            				[SELECT ParentId Id, COUNT(Id) Cnt FROM Note 
                             WHERE ParentId IN :liIdList 
                             GROUP BY ParentId]);
            List<liWrapper> retLiWrap = new List<liWrapper>();
            for (Line_Item__c li : liList) {
                Boolean hasNote = LineItemsNoteCount.containsKey(li.Id);
                liWrapper t = new liWrapper(li,hasNote);
                retLiWrap.add(t);
            }
            return retLiWrap;
        }
        public void Sort() {
            this.LineItemPagingInfo.OrderBy = ApexPages.currentPage().getParameters().get('sortByColumn');
            this.LineItemPagingInfo.OrderDirection = ApexPages.currentPage().getParameters().get('sortDirection') ;
            QueryLineItemTypes();
        }
    }
    public class liWrapper {
        public Line_Item__c Item{get;set;}
        public boolean isNoteExist{get;set;}
        public liWrapper (Line_Item__c Item, boolean isNoteExist) {
            this.Item = Item;
            this.isNoteExist = isNoteExist;
        }
    }
    public static String LineItemAllFields() {
        Map<String, Schema.SObjectField> fldObjMap = schema.SObjectType.Line_Item__c.fields.getMap();
        List<Schema.SObjectField> fldObjMapValues = fldObjMap.values();
        
        String theQuery = 'SELECT ';
        for(Schema.SObjectField s : fldObjMapValues)
        {
            String theName = s.getDescribe().getName();
            theQuery += theName + ',';
        }
        if (theQuery.contains('LastReferencedDate,'))
        	theQuery = theQuery.remove('LastReferencedDate,');
        theQuery += ' Line_Item_Type__r.Line_Item_Category__r.Reference_Number__c, Cloned_Line_Item__r.Name ';
        // Trim last comma
        //theQuery = theQuery.subString(0, theQuery.length() - 1);
        return theQuery;
    }
    /*
    public void ReloadLineItemType() {
        String litId = ApexPages.currentPage().getParameters().get('lineItemTypeIdReload');
        //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'No Electoral Expenditure' + litId + ' af'));
        for (litWrapper litW : lineItemTypeWrap) {
            if (litId == litW.lit.Id) {
                litW.QueryLineItemTypes();
                break;
            }
        }
    }*/
    public PageReference Back() {
        return new PageReference('/'+doId);
    }
}