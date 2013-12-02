/* used for reviewing the ‘Vouching Status’ of the record by querying and rendering any related Vouched_Line_Item__c 
** records.
*/
public class ReviewVouchingStatusTRIMRecordController{
    public Vouched_Line_Item__c Entity{get;set;}
    public Map<String, Static_Label__c> Labels{get;set;}
    public List<litWrapper> lineItemTypeWrap{get;set;}
    public transient Map<string, Schema.FieldSet> MapLineItemFieldSets;    
    public String trcId{get;set;}
    public static String lineItemrecordType = [SELECT Id, name FROM RecordType WHERE name = 'Audit Line Item' LIMIT 1].Id;
    public static String lineItemAllFieldsQuery = LineItemAllFields();    
    public List<SelectOption> numberItemPerPageOptions{get;set;}    
    public Map<string, Schema.FieldSet> GetMapLineItemFieldSets(){
        return Schema.SObjectType.Line_Item__c.fieldSets.getMap();
    }
    
    public ReviewVouchingStatusTRIMRecordController(ApexPages.StandardController sc){
        this.Entity = (Vouched_Line_Item__c)sc.GetRecord();
        //this.Entity = GetEntityById(this.Entity.Id);
        
        trcId = ApexPages.currentPage().getParameters().get('trc');
        //ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'aa: ' + trcId));
        List<Vouched_Line_Item__c> listVLI = [SELECT Line_Item__r.Line_Item_Type__c, Line_Item__c 
                                              FROM Vouched_Line_Item__c WHERE Trim_Record__c =: trcId];        
        // Set Id of LineItemType
        Set<String> litIdList = new Set<String>();
        //Set Id of LineItem
        Set<String> lineItemIdList = new Set<String>();
        for (Vouched_Line_Item__c vli : listVLI) {
            litIdList.add(vli.Line_Item__r.Line_Item_Type__c);
            lineItemIdList.add(vli.Line_Item__c);
        }
                
        List<Line_Item_Type__c> lineItemTypeList = [
            SELECT Id, Name, Line_Item_Category__r.Line_Item_Category__c,
            Line_Item_Category__r.Reference_Number__c,
            Calculated_Amount__c,Form_Amount__c,Calculated_Count__c,Form_Count__c,
            Line_Item_Category__r.Calculated_Total_Amount__c,Line_Item_Category__r.Form_Total_Amount__c,
            Line_Item_Category__r.Calculated_Total_Count__c,Line_Item_Category__r.Form_Total_Count__c,
            Line_Item_Category__r.Remove_Row__c,Line_Item_Category__r.Default_Number_of_Rows__c,
            Disclosure_Claim_for_Payment__r.Name,Nil_Disclosure_Claim_for_Payment__c,
            Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Expenditure_Cap__c,
            Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Expenditure_Cap__r.Name,
            Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Expenditure_Cap__r.Amount__c,
            Disclosure_Claim_for_Payment__r.Electoral_Expenditure__c,
            Disclosure_Claim_for_Payment__r.Cloned_Disclosure_Claim_for_Payment__c
            FROM Line_Item_Type__c 
            WHERE Id IN :litIdList
            ORDER BY Order_Number__c
        ];
        
        this.Labels = Static_Label__c.GetAll();
        lineItemTypeWrap = new List<litWrapper>();
        numberItemPerPageOptions = getItemPerPage();
        
        // Query to get All Line Items
        List<Line_Item__c> lineItemList = getLineItemBySetId(lineItemIdList);
        //ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'A: ' + lineItemList.size()));
        
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
    private List<Line_Item__c> getLineItemBySetId (Set<String> liIdList) {
        String query = lineItemAllFieldsQuery;
        query += ' FROM Line_Item__c WHERE Id IN (\'' + String.Join(new List<string>(liIdList),'\',\'')+'\')'
            		+ ' AND RecordTypeId=\'' + lineItemrecordType + '\' AND Active__c = true ORDER BY CreatedDate' ;
        //ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'a: ' + query));
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
                            + ' AND RecordTypeId=\'' + lineItemrecordType + '\' AND Active__c = true';
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
            if(s.getDescribe().isAccessible()){
               String theName = s.getDescribe().getName();
               theQuery += theName + ',';
            }
        }
        theQuery += ' Line_Item_Type__r.Line_Item_Category__r.Reference_Number__c, Cloned_Line_Item__r.Name ';
        /*
        //Remove fields not visible
        theQuery = theQuery.Replace('Recipient_Type__c,','');
        theQuery = theQuery.Replace('Product_or_Service_Provided__c,','');
        theQuery = theQuery.Replace('Period_of_Employment_over_Calendar_Year__c,','');
        theQuery = theQuery.Replace('SearchDecs_Update_Difference__c,','');
*/
        // Trim last comma
        //theQuery = theQuery.subString(0, theQuery.length() - 1);
        return theQuery;
    }
}