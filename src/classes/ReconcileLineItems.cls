/* - Allows for the matching of Audit Line Items based on the attributes being captured during the Disclosure process. 
** - Provide groupings by Stakeholder of any ‘Donations Received’ alongside ‘Donations Made’ from other Disclosures 
** where the Stakeholder is denoted. This will allow the end user to evaluate these matched Audit Line Items 
** and where applicable create a related ‘Reconciled_Line_Item__c’ record linking to the 2 records
*/
public class ReconcileLineItems{
    public Disclosure_Claim_For_Payment__c Entity{get;set;}
    public string SearchKey{get;set;}
    public List<string> FilterKeys{get{return new List<string>{'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z', 'All','Reconciled','Not Reconciled'};}}
    public string FilterKey{get;set;}
    public List<ResultBlock> Results{get;set;}
    public Map<string, SortInfo> MapSortInfo{get;set;}
    public static SortInfo SortInfo{get;set;}
    public transient string StartUpScript{get;set;}
    public Integer RecordId{get;set;}
    public Map<String,List<SelectOption>> DMLineItemTypeOptionMap{get;set;}
    public Map<String,List<SelectOption>> DRLineItemTypeOptionMap{get;set;}
    private Set<String> allDisclosureID;
    public Map<string, Schema.FieldSet> GetMapLineItemFieldSets(){
        return Schema.SObjectType.Line_Item__c.fieldSets.getMap();
    }
    
    public ReconcileLineItems(ApexPages.StandardController controller){
        this.Entity = (Disclosure_Claim_For_Payment__c)controller.GetRecord();
        this.Entity = GetEntityById(this.Entity.Id);
        
        allDisclosureID = new Set<String>();
        allDisclosureID.add(this.Entity.Id);
        this.MapSortInfo = new Map<string, SortInfo>();
        this.SearchKey = '';
        this.FilterKey = 'All';
        this.RecordId = 0;
        this.btnSearch_Click();
        for(ResultBlock rb :this.Results){
            if (rb.DisclosureId != null) {
                if (!String.isEmpty(rb.DisclosureId))
                    allDisclosureID.add(rb.DisclosureId);
            }
        }
        this.buildLineItemTypeOption();
    }
    private void buildLineItemTypeOption() {
        DMLineItemTypeOptionMap = new Map<String,List<SelectOption>>();
        DRLineItemTypeOptionMap = new Map<String,List<SelectOption>>();
        List<Line_Item_Type__c> lineItemTypeList = [SELECT Id, Line_Item_Category__r.Line_Item_Category__c,
                                                    	Line_Item_Category__r.Reconcile_Type__c,Disclosure_Claim_for_Payment__c
                                                    FROM Line_Item_Type__c 
                                                    WHERE Disclosure_Claim_for_Payment__c = :allDisclosureID
                                                    AND (Line_Item_Category__r.Reconcile_Type__c = 'Donations Made'
                                                         OR Line_Item_Category__r.Reconcile_Type__c = 'Donations Received')
                                                    ORDER BY Order_Number__c
                                                   ];
        for (Line_Item_Type__c lit : lineItemTypeList) {
            if (lit.Line_Item_Category__r.Reconcile_Type__c == 'Donations Made') {
                if (!DMLineItemTypeOptionMap.containsKey(lit.Disclosure_Claim_for_Payment__c)) {
                    DMLineItemTypeOptionMap.put(lit.Disclosure_Claim_for_Payment__c, new List<SelectOption>());
                    DMLineItemTypeOptionMap.get(lit.Disclosure_Claim_for_Payment__c).add(new SelectOption('', '--None--'));
                }
                DMLineItemTypeOptionMap.get(lit.Disclosure_Claim_for_Payment__c).add(new SelectOption(lit.Id, lit.Line_Item_Category__r.Line_Item_Category__c));
            } else {
                if (!DRLineItemTypeOptionMap.containsKey(lit.Disclosure_Claim_for_Payment__c)) {
                    DRLineItemTypeOptionMap.put(lit.Disclosure_Claim_for_Payment__c, new List<SelectOption>());
                    DRLineItemTypeOptionMap.get(lit.Disclosure_Claim_for_Payment__c).add(new SelectOption('', '--None--'));
                }
                DRLineItemTypeOptionMap.get(lit.Disclosure_Claim_for_Payment__c).add(new SelectOption(lit.Id, lit.Line_Item_Category__r.Line_Item_Category__c));
            }
        }
    }
    public Disclosure_Claim_For_Payment__c GetEntityById(string strId){
        return [
            SELECT Id, Stakeholder__c, name, Disclosure_Obligation__r.Reporting_Period__c, Disclosure_Obligation__r.Registration__c
            FROM Disclosure_Claim_For_Payment__c 
            WHERE Id = :strId	
            LIMIT 1
        ];
    }
    private String SelectLineItemField() {
        String query = 'SELECT ';
        Schema.FieldSet LineItemFieldSet;
        query += ' Line_Item__c, Stakeholder__c, Stakeholder__r.Name, Stakeholder__r.LastName, Name, Line_Item_Type__r.Line_Item_Category__r.Reconcile_Type__c '
            	+ ' ,Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Stakeholder__c, Line_Item_Type__r.Disclosure_Claim_for_Payment__c '
            	+ ' ,Line_Item_Type__r.Line_Item_Category__r.Line_Item_Category__c,Line_Item_Type__r.Name '
            	+ ' , Stakeholder_Registration__c, ';
        LineItemFieldSet = Schema.SObjectType.Line_Item__c.fieldSets.Reconciled_Donations_Made;
        for(Schema.FieldSetMember f : LineItemFieldSet.getFields()) {
            if (!query.contains(f.getFieldPath())) {
            	query += f.getFieldPath() + ', ';
            }
        }
        LineItemFieldSet = Schema.SObjectType.Line_Item__c.fieldSets.Reconcile_Donations_Received;
        for(Schema.FieldSetMember f : LineItemFieldSet.getFields()) {
            if (!query.contains(f.getFieldPath())) {
                query += f.getFieldPath() + ', ';
            }
        }
		query += ' Id ';
        
        return query;
    }
    public Line_Item__c GetLineItemById(string lineItemId){
        String query = SelectLineItemField();
        query += 'FROM Line_Item__c WHERE Id = :lineItemId LIMIT 1';
        return Database.query(query);
    }
    
    public void btnSearch_Click(){
        string qSelect = SelectLineItemField();
        string qFrom = ' FROM Line_Item__c ';
        string qWhere = ' WHERE Active__c = TRUE AND RecordType.Name = \'Audit Line Item\' AND Stakeholder__r.Name LIKE \'%' + this.SearchKey +'%\' AND Line_Item_Type__r.Line_Item_Category__r.Reconcile_Type__c = \'Donations Received\' AND Line_Item_Type__r.Disclosure_Claim_For_Payment__c = \''+this.Entity.Id+'\'';
        string qOrder = ' ORDER BY CreatedDate ';
        
        List<Line_Item__c> listLineItem = Database.Query(qSelect + qFrom + qWhere + qOrder);
        
        qWhere = 'WHERE Active__c = TRUE '
            +' AND Stakeholder__c = \'' + this.Entity.Stakeholder__c + '\''
            +' AND RecordType.Name = \'Audit Line Item\' AND Line_Item_Type__r.Line_Item_Category__r.Reconcile_Type__c = \'Donations Made\' '
            +' AND Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Reporting_Period__c = \'' +this.Entity.Disclosure_Obligation__r.Reporting_Period__c + '\''
            +' AND Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Active__c = true';
        List<Line_Item__c> listLineItem1 = Database.Query(qSelect + qFrom + qWhere + qOrder);
        //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, listLineItem1.size() + 'ab'));
        //listLineItem.addAll(listLineItem1);
        this.Results = this.GroupResults(listLineItem,listLineItem1);
    }
    
    public void btnFilter_Click(){
        List<Line_Item__c> listLineItem = new List<Line_Item__c>();
        string qSelect = SelectLineItemField();
        string qFrom = ' FROM Line_Item__c ';
        string qWhere = ' WHERE Active__c = TRUE AND RecordType.Name = \'Audit Line Item\' AND Stakeholder__c != NULL AND Line_Item_Type__r.Line_Item_Category__r.Reconcile_Type__c = \'Donations Received\' AND Line_Item_Type__r.Disclosure_Claim_For_Payment__c = \''+this.Entity.Id+'\'';
        string qOrder = ' ORDER BY CreatedDate ';
        string qWhereDMade = 'WHERE Active__c = TRUE '
                            +' AND Stakeholder__c = \'' + this.Entity.Stakeholder__c + '\''
                            +' AND RecordType.Name = \'Audit Line Item\' AND Line_Item_Type__r.Line_Item_Category__r.Reconcile_Type__c = \'Donations Made\' '
                            +' AND Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Reporting_Period__c = \'' +this.Entity.Disclosure_Obligation__r.Reporting_Period__c + '\''
                            +' AND Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Active__c = true';
        if(this.FilterKey == 'All'){
        }
        else if(this.FilterKey == 'Reconciled'){
            Set<string> setReconciledDonationMadeItemId = new Map<string, AggregateResult>([SELECT Line_Item_Donation_Made__c Id FROM Reconciled_Line_Item__c WHERE Line_Item_Donation_Made__c != null GROUP BY Line_Item_Donation_Made__c]).KeySet();
            Set<string> setReconciledDonationReceivedItemId = new Map<string, AggregateResult>([SELECT Line_Item_Donation_Received__c Id FROM Reconciled_Line_Item__c WHERE Line_Item_Donation_Received__c != null GROUP BY Line_Item_Donation_Received__c]).KeySet();
            //qWhere += ' AND ((Line_Item_Type__r.Line_Item_Category__r.Reconcile_Type__c = \'Donations Made\' AND Id IN :setReconciledDonationMadeItemId)'
            //    + ' OR (Line_Item_Type__r.Line_Item_Category__r.Reconcile_Type__c = \'Donations Received\' AND ID IN :setReconciledDonationReceivedItemId))';
            qWhere += ' AND Id IN  (\'' + String.Join(new List<string>(setReconciledDonationReceivedItemId), '\',\'') + '\')';              
            qWhereDMade += ' AND Id IN  (\'' + String.Join(new List<string>(setReconciledDonationMadeItemId), '\',\'') + '\')'; 
        }
        else if(this.FilterKey == 'Not Reconciled'){
            Set<string> setReconciledDonationMadeItemId = new Map<string, AggregateResult>([SELECT Line_Item_Donation_Made__c Id FROM Reconciled_Line_Item__c WHERE Line_Item_Donation_Made__c != null GROUP BY Line_Item_Donation_Made__c]).KeySet();
            Set<string> setReconciledDonationReceivedItemId = new Map<string, AggregateResult>([SELECT Line_Item_Donation_Received__c Id FROM Reconciled_Line_Item__c WHERE Line_Item_Donation_Received__c != null GROUP BY Line_Item_Donation_Received__c]).KeySet();
                
            qWhere += ' AND Id NOT IN (\'' + String.Join(new List<string>(setReconciledDonationReceivedItemId), '\',\'') + '\')';            
            qWhereDMade += ' AND Id NOT IN  (\'' + String.Join(new List<string>(setReconciledDonationMadeItemId), '\',\'') + '\')'; 
        }
        else{
            qWhere += ' AND Stakeholder__r.LastName LIKE \'' + this.FilterKey + '%\' ';
        }
        //try{
        listLineItem = Database.Query(qSelect + qFrom + qWhere + qOrder);  
        // Don't show all audits line items , Vinh commented below codes
        /*
        // If reconcile or not reconcile, select all audit line items
        if (this.FilterKey == 'Not Reconciled' || this.FilterKey == 'Reconciled') {
            Set<String> listLineItemId = new Set<String>();
            Set<String> listAccId = new Set<String>();
            for (Line_Item__c li : listLineItem) {
                listLineItemId.add(li.Id);
                listAccId.add(li.Stakeholder__c);
            }
            String tempqWhere = ' WHERE ID Not IN :listLineItemId AND Active__c = TRUE AND RecordType.Name = \'Audit Line Item\' AND Stakeholder__c In :listAccId  AND Line_Item_Type__r.Line_Item_Category__r.Reconcile_Type__c = \'Donations Received\' AND Line_Item_Type__r.Disclosure_Claim_For_Payment__c = \''+this.Entity.Id+'\'';
            List<Line_Item__c> additionLiList = Database.Query(qSelect + qFrom + tempqWhere + qOrder);    
            listLineItem.addAll(additionLiList);
        }
		
        qWhere = 'WHERE Active__c = TRUE AND RecordType.Name = \'Audit Line Item\' AND Line_Item_Type__r.Line_Item_Category__r.Reconcile_Type__c = \'Donations Made\'' +
           		+' AND Stakeholder__c = \'' + this.Entity.Stakeholder__c + '\''
            	+' AND Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Reporting_Period__c = \'' +this.Entity.Disclosure_Obligation__r.Reporting_Period__c + '\'';
		*/
        List<Line_Item__c> listLineItem1 = Database.Query(qSelect + qFrom + qWhereDMade + qOrder);
        
        
        this.Results = this.GroupResults(listLineItem,listLineItem1);
        // ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, qSelect + qFrom + qWhere));
        //}
        //catch(Exception ex){
		//	ApexPages.AddMessages(ex);
            //ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getStackTraceString()));
        //}
        /*for(ResultBlock rb: this.Results){
            this.MapSortInfo.Put(rb.Stakeholder.Id + 'Donations Received', new SortInfo('CreatedDate', 'ASC'));
            this.MapSortInfo.Put(rb.Stakeholder.Id + 'Donations Made', new SortInfo('CreatedDate', 'ASC'));
        }*/
    }
    
    public void btnReconcile_Click(){
        string stakeholderId = ApexPages.CurrentPage().GetParameters().Get('stakeholderId');
        List<Reconciled_Line_Item__c> insertList = new List<Reconciled_Line_Item__c>();
  
        for(ResultBlock rb :this.Results){
            if(rb.Stakeholder.Id == stakeholderId){
                for(LineItemWrapper receivedItem :rb.DonationReceivedItems){
                    if(receivedItem.IsChecked){
                        for(LineItemWrapper madeItem :rb.DonationMadeItems){
                            if(madeItem.IsChecked){
                                insertList.Add(
                                    new Reconciled_Line_Item__c(
                                        Line_Item_Donation_Received__c = receivedItem.Item.Id, 
                                        Line_Item_Donation_Made__c = madeItem.Item.Id
                                    )
                                );
                                
                                receivedItem.IsReconciled = true;
                                madeItem.IsReconciled = true;
                            }
                        }
                    }
                }
                insert insertList;
                
                for(LineItemWrapper item :rb.DonationReceivedItems){
                    item.IsChecked = false;
                }
                
                for(LineItemWrapper item :rb.DonationMadeItems){
                    item.IsChecked = false;
                }
                
                break;
            }
        }
        this.StartUpScript = 'alert("Successfully Reconciled")';
    }
    
    private List<ResultBlock> GroupResults(List<Line_Item__c> listLineItem, List<Line_Item__c> listLineItemMade){
        Map<string, ResultBlock> temp = new Map<string, ResultBlock>();
        Set<string> setReconciledDonationMadeItemId = new Map<string, AggregateResult>([SELECT Line_Item_Donation_Made__c Id FROM Reconciled_Line_Item__c WHERE Line_Item_Donation_Made__c != null GROUP BY Line_Item_Donation_Made__c]).KeySet();
        Set<string> setReconciledDonationReceivedItemId = new Map<string, AggregateResult>([SELECT Line_Item_Donation_Received__c Id FROM Reconciled_Line_Item__c WHERE Line_Item_Donation_Received__c != null GROUP BY Line_Item_Donation_Received__c]).KeySet();
        Boolean isLoad = false;
        
        for(Line_Item__c item :listLineItem){            
            ResultBlock rb;
            if(item.Line_Item_Type__r.Line_Item_Category__r.Reconcile_Type__c == 'Donations Received'){
                if(temp.ContainsKey(item.Stakeholder__c)){
                    rb = temp.Get(item.Stakeholder__c);
                    isLoad = true;
                }
                else{
                    rb = new ResultBlock(item.Stakeholder__r);
                    temp.Put(item.Stakeholder__c, rb);
                    isLoad = false;
                }
            }            
            //if(item.Line_Item_Type__r.Line_Item_Category__r.Reconcile_Type__c == 'Donations Made'){
            //    rb.DonationMadeItems.Add(new LineItemWrapper(item, setReconciledDonationMadeItemId.Contains(item.Id)));
            //}
            //else if(item.Line_Item_Type__r.Line_Item_Category__r.Reconcile_Type__c == 'Donations Received'){
                rb.DonationReceivedItems.Add(new LineItemWrapper(RecordId++, item, setReconciledDonationReceivedItemId.Contains(item.Id))); 
            //}
            if(!isLoad){
                for(Line_Item__c itemMade :listLineItemMade){
                    if(itemMade.Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Stakeholder__c == item.Stakeholder__c){
                        rb.DisclosureId = itemMade.Line_Item_Type__r.Disclosure_Claim_for_Payment__c;
                        rb.DonationMadeItems.Add(new LineItemWrapper(RecordId++, itemMade, setReconciledDonationMadeItemId.Contains(itemMade.Id)));
                        //isLoad = true;
                    }
                }
            }
        }
        //ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, string.ValueOf(listLineItem)));
        //ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, string.ValueOf(temp)));
        List<ResultBlock> result = new List<ResultBlock>();
        //List<string> accountId = new List<string>(temp.KeySet());
        /*accountNames.Sort();
        for(string accountName :accountNames){
            ResultBlock rb = temp.Get(accountName);
            this.MapSortInfo.Put(rb.Stakeholder.Id + 'Donations Received', new SortInfo('CreatedDate', 'ASC'));
            this.MapSortInfo.Put(rb.Stakeholder.Id + 'Donations Made', new SortInfo('CreatedDate', 'ASC'));
            result.Add(rb);
        }*/
        // Sort by last name
        List<Account> accountList = [Select Id, LastName from Account Where Id IN :temp.KeySet() order By LastName];
        for (Account acc : accountList) {
            ResultBlock rb = temp.Get(acc.Id);
            this.MapSortInfo.Put(rb.Stakeholder.Id + 'Donations Received', new SortInfo('CreatedDate', 'ASC'));
            this.MapSortInfo.Put(rb.Stakeholder.Id + 'Donations Made', new SortInfo('CreatedDate', 'ASC'));
            result.Add(rb);
        }
        return result;
    }
    
    public void btnSort_Click(){
        SortInfo sInfo = new SortInfo(ApexPages.CurrentPage().GetParameters().Get('sortBy'), ApexPages.CurrentPage().GetParameters().Get('sortDirection'));
        ReconcileLineItems.SortInfo = sInfo;
        this.MapSortInfo.Put(ApexPages.CurrentPage().GetParameters().Get('stakeholderId') + ApexPages.CurrentPage().GetParameters().Get('blockType'), sInfo);
        for(ResultBlock rb :this.Results){
            if(rb.Stakeholder.Id == ApexPages.CurrentPage().GetParameters().Get('stakeholderId')){
                if(ApexPages.CurrentPage().GetParameters().Get('blockType') == 'Donations Received'){
                 	rb.DonationReceivedItems.Sort();
                }
                else{
                    rb.DonationMadeItems.Sort();
                }
                
                return;
            }
        }
    }
    /*
    public void listLineItem_Added(){
        string lineItemId = ApexPages.CurrentPage().GetParameters().Get('lineItemId');        
        LineItemWrapper temp = new LineItemWrapper(RecordId++, this.GetLineItemById(lineItemId), false);
        for(ResultBlock rb :this.Results){
            if(rb.Stakeholder.Id == temp.Item.Stakeholder__c || rb.Stakeholder.Id == temp.Item.Line_Item_Type__r.Disclosure_Claim_for_Payment__r.Stakeholder__c){
                if(temp.Item.Line_Item_Type__r.Line_Item_Category__r.Reconcile_Type__c == 'Donations Received'){
                 	rb.DonationReceivedItems.Add(temp);
                }
                else{
                    rb.DonationMadeItems.Add(temp);
                }
                
                break;
            }
        }
    }*/
    
    public void listLineItem_Added(){
        string stakeholderId = ApexPages.CurrentPage().GetParameters().Get('stakeholderId');
        string blockType = ApexPages.CurrentPage().GetParameters().Get('blockType');
        
        List<LineItemWrapper> tempList = new List<LineItemWrapper>();
        for(ResultBlock rb :this.Results){
            if(rb.Stakeholder.Id == stakeholderId){
                if ((rb.DisclosureId == null || String.isEmpty(rb.DisclosureId)) && blockType== 'Donations Made') {
                    // Check if the donor has submitted a Disclosure for the relevant reporting period
                    List<Disclosure_Claim_for_Payment__c> tempActiveDis = [
                        	SELECT Id, Name
                        	FROM Disclosure_Claim_for_payment__c
                        	WHERE Stakeholder__c = :rb.Stakeholder.Id
                        	AND Disclosure_Obligation__r.Reporting_Period__c =:this.Entity.Disclosure_Obligation__r.Reporting_Period__c
                        	AND Active__c = true
                        ];
                    if (tempActiveDis.size() > 0) {
                        rb.DisclosureId = tempActiveDis.get(0).Id;
                        if (!DMLineItemTypeOptionMap.containsKey(rb.DisclosureId)) {
                            List<Line_Item_Type__c> lineItemTypeList = [SELECT Id, Line_Item_Category__r.Line_Item_Category__c,
                                                            Line_Item_Category__r.Reconcile_Type__c,Disclosure_Claim_for_Payment__c
                                                        FROM Line_Item_Type__c 
                                                        WHERE Disclosure_Claim_for_Payment__c = :rb.DisclosureId
                                                        AND (Line_Item_Category__r.Reconcile_Type__c = 'Donations Made')
                                                        ORDER BY Order_Number__c
                                                       ];
                        
                            DMLineItemTypeOptionMap.put(rb.DisclosureId, new List<SelectOption>());
                            DMLineItemTypeOptionMap.get(rb.DisclosureId).add(new SelectOption('', '--None--'));
                            for (Line_Item_Type__c lit : lineItemTypeList) {
                                DMLineItemTypeOptionMap.get(rb.DisclosureId).add(new SelectOption(lit.Id, lit.Line_Item_Category__r.Line_Item_Category__c));
                            }
                        }
                    } else {
                        this.StartUpScript = 'alert("An Audit Line Item cannot be created as the Donor has not submitted a Disclosure for the relevant reporting period.")';
	                    ApexPages.addMessage(new ApexPages.Message (ApexPages.Severity.ERROR,'An Audit Line Item cannot be created as the Donor has not submitted a Disclosure for the relevant reporting period.'));
                        return;
                    }
                }
                String auditRecordType = [Select Id from Recordtype where Name='Audit Line Item'][0].Id;
                Line_Item__c tempLi = new Line_Item__c(RecordTypeId = auditRecordType);
                tempLi.Stakeholder__c = stakeholderId;
                tempLi.Active__c = true;
                if(blockType == 'Donations Received'){
                    tempList = rb.DonationReceivedItems;
                }
                else{
                    tempList = rb.DonationMadeItems;
                    //tempLi.Stakeholder_Registration__c = this.Entity.Disclosure_Obligation__r.Registration__c;
                }
                LineItemWrapper tempWrapper = new LineItemWrapper(RecordId++, tempLi,false);
                tempWrapper.IsEdit = true;
                tempWrapper.isCloned = false;
                if (tempList.size() == 0) {
                    tempList.add(tempWrapper);
                } else {
                    tempList.add(0, tempWrapper);
                }
                break;
            }
        }
    }
    
    public void listLineItem_Command(){
        string stakeholderId = ApexPages.CurrentPage().GetParameters().Get('stakeholderId');
        string blockType = ApexPages.CurrentPage().GetParameters().Get('blockType');
        Integer lineItemId = Integer.valueof(ApexPages.CurrentPage().GetParameters().Get('lineItemId'));
        string command = ApexPages.CurrentPage().GetParameters().Get('command');
        
        List<LineItemWrapper> tempList = new List<LineItemWrapper>();
        try {
            for(ResultBlock rb :this.Results){
                if(rb.Stakeholder.Id == ApexPages.CurrentPage().GetParameters().Get('stakeholderId')){
                    if(ApexPages.CurrentPage().GetParameters().Get('blockType') == 'Donations Received'){
                        tempList = rb.DonationReceivedItems;
                    }
                    else{
                        tempList = rb.DonationMadeItems;
                    }
                    
                    break;
                }
            }
        
            for(integer i = 0; i < tempList.Size(); i++){
                LineItemWrapper item = tempList[i];
                
                if(item.Id == lineItemId){
                    if(command == 'edit'){
                        item.IsEdit = true;
                    }
                    else if(command == 'save'){
                        if (item.Item.Line_Item_Type__c == null) {
                            this.StartUpScript = 'alert("Please select Line Item Type before saving!")';
                            ApexPages.addMessage(new ApexPages.Message (ApexPages.Severity.ERROR, 'Please select Line Item Type before saving!'));
                            return;
                        }
                        List<Line_Item__c> uplist = new List<Line_Item__c>();
                        // Change active to inative if any
                        for (integer j = tempList.Size() - 1; j >= 0; j--) {
                            Line_Item__c tempActive = tempList[j].Item;
                            if (tempActive.Active__c == true && j != i &&tempActive.Line_Item__c == item.Item.Line_Item__c) {
                                tempActive.Active__c = false;
                                uplist.add(tempActive);
                                tempList.remove(j);
                                break;
                            }
                        }
                        uplist.add(item.Item);
                        upsert uplist;
                        // Reload Item
                        item.Item = this.GetLineItemById(item.Item.Id);
                        item.IsEdit = false;
                    }
                    else if(command == 'cancel'){
                        if (item.Item.Id != null) {
                            item.Item = this.GetLineItemById(item.Item.Id);
                            item.IsEdit = false;
                        } else {
                            tempList.remove(i);
                        }
                    }
                    else if(command == 'delete'){
                        delete item.Item;
                        tempList.Remove(i);   
                    }
                    else if (command == 'add') {
                        Line_Item__c tempLi = item.Item.Clone(false,true);
                        tempLi.Line_Item__c = item.Item.Line_Item__c;
                        tempLi.Cloned_Line_Item__c = item.Item.Id;
                        LineItemWrapper tempWrapper = new LineItemWrapper(RecordId++, tempLi,false);
                        tempWrapper.IsEdit = true;
                        tempWrapper.isCloned = true;
                        if (i == (tempList.size() - 1)) {
                            tempList.add(tempWrapper);
                        } else {
                            tempList.add(i+1, tempWrapper);
                        }
                    }
                    break;
                }
            }
        } catch (Exception e) {
            this.StartUpScript = 'alert("' + e.getMessage() +'")';
            ApexPages.addMessages(e);
        }
    }
    
    public class SortInfo{
        public string SortBy{get;set;}
        public string SortDirection{get;set;}
        
        public SortInfo(string sortBy, string sortDirection){
            this.SortBy = sortBy;
            this.SortDirection = sortDirection;
        }
    }            
    
    public class ResultBlock{
        public List<LineItemWrapper> DonationReceivedItems{get;set;}
        public List<LineItemWrapper> DonationMadeItems{get;set;}
        public Account Stakeholder {get;set;}
        public String DisclosureId {get;set;}
        //public Disclosure_Claim_For_Payment__c DisclosureClaim{get;set;}

        public ResultBlock(Account stakeholder){
            this.Stakeholder = stakeholder;
            DonationMadeItems = new List<LineItemWrapper>();
            DonationReceivedItems = new List<LineItemWrapper>();
        }
    }
    
    public class LineItemWrapper implements Comparable{
        public Line_Item__c Item{get;set;}
        public Integer Id{get;set;}
        public boolean IsChecked{get;set;}
        public boolean IsReconciled{get;set;}
        public boolean IsEdit{get;set;}
        public boolean IsExist{get{return Item.Id != null;}}
        public boolean IsCloned{get;set;}
        public LineItemWrapper(Integer incrId, Line_Item__c lineitem, boolean isReconciled){
            this.Id = incrId;
            this.Item = lineitem;
            this.IsChecked = false;
            this.IsReconciled = isReconciled;
            this.IsEdit = false;
            this.IsCloned = false;
        }
        
        public Integer compareTo(Object compareTo) {
            LineItemWrapper target = (LineItemWrapper)compareTo;
            if (!IsExist || !target.IsExist) {
                return -1;
            }
            integer sortAsc = ReconcileLineItems.SortInfo.SortDirection == 'ASC' ? 1 : -1;
            //return this.Item.Get(ReconcileLineItems.SortBy).CompareTo(target.Item.Get(ReconcileLineItems.SortBy)) * sortAsc;
            
            if (ReconcileLineItems.SortInfo.SortBy.equals('Stakeholder__c')){
                return this.Item.Stakeholder__r.Name.CompareTo(target.Item.Stakeholder__r.Name) * sortAsc;
            }
            else if (ReconcileLineItems.SortInfo.SortBy.equals('Name')){
                return this.Item.Name.CompareTo(target.Item.Name) * sortAsc;
            }
            else if (ReconcileLineItems.SortInfo.SortBy.equals('Line_Item_Type__c')){
                return this.Item.Line_Item_Type__r.Line_Item_Category__r.Line_Item_Category__c.CompareTo(target.Item.Line_Item_Type__r.Line_Item_Category__r.Line_Item_Category__c) * sortAsc;
            }
            else if (ReconcileLineItems.SortInfo.SortBy.equals('Amount_or_Value_of_Donation__c')){
                return (this.Item.Amount_or_Value_of_Donation__c >= target.Item.Amount_or_Value_of_Donation__c ? 1 : -1) * sortAsc;
            }
            else if (ReconcileLineItems.SortInfo.SortBy.equals('Date_Donation_was_made__c')){
                return (this.Item.Date_Donation_was_made__c >= target.Item.Date_Donation_was_made__c ? 1 : -1) * sortAsc;
            }
            else if (ReconcileLineItems.SortInfo.SortBy.equals('Receipt_Number__c')){
                return this.Item.Receipt_Number__c.CompareTo(target.Item.Receipt_Number__c) * sortAsc;
            }
            else if (ReconcileLineItems.SortInfo.SortBy.equals('Gift_Type__c')){
                return this.Item.Gift_Type__c.CompareTo(target.Item.Gift_Type__c) * sortAsc;
            }
            else if (ReconcileLineItems.SortInfo.SortBy.equals('Purpose_State_LG_Admin__c')){
                return this.Item.Purpose_State_LG_Admin__c.CompareTo(target.Item.Purpose_State_LG_Admin__c) * sortAsc;
            }
            return 0;
        }
    }
}