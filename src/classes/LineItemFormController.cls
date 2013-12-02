/* Used for viewing, creating, editing a Line Item.
** - Dynamically render the correct Line Item Fields based on a Field Set 
** determined by the Line Items parent Line Item Types, Line Item Category.
*/
public class LineItemFormController{
    public integer recordCounter{get;set;}
    public List<LineItemWrapper> LineItemWrapperList{get;set;}
    public transient Map<string, Schema.FieldSet> MapLineItemFieldSets;
    public Map<String, Static_Label__c> Labels{get;set;}
    //public boolean IsInline{get{ return ApexPages.CurrentPage().GetParameters().Get('inline') == '1'; }}
    public boolean IsEdit{get;set;}
    public boolean isAddRowClick{get;set;}
    public ApexPages.StandardController SController{get;set;}
    public Line_Item_Type__c LineItemType{get;set;}
    //US4811
    public Disclosure_Claim_for_Payment__c Disclosure{get;set;}
    //End US4811
    public boolean isCloneDisclosureObject{get;set;}
    public PagingInfo LineItemPagingInfo{get;set;}
    private String sortByColumn;
    private String sortOrder;
    private String lineItemrecordType;
    public List<SelectOption> numberItemPerPageOptions{get;set;}    
    public List<SelectOption> OptionsFunctionOrVenture{get;set;}
    public Map<string, Schema.FieldSet> GetMapLineItemFieldSets(){
        return Schema.SObjectType.Line_Item__c.fieldSets.getMap();
    }
    public string StartUpScript{get;set;}
    public boolean IsFunctionOrVenture{get;set;}
    public boolean FieldSetContainsFunctionOrVenture{get;set;}
    public boolean hasRow{get;set;}
    public string lineItemTypeLabel{get;set;}
    
    // For LineItemTrigger
    public static boolean inFutureContext = false;
	public LineItemFormController(ApexPages.StandardController sc){
        try{
            LineItemType = (Line_Item_Type__c)sc.GetRecord();
            LineItemType = GetEntityById(LineItemType.Id);
            this.Disclosure = GetDCPEntity(LineItemType.Disclosure_Claim_for_Payment__c);
            //US5201
            
            System.Debug('#retrieve stakeholderName#' + LineItemType.Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Stakeholder__c);            
            //String stakeholderName = [SELECT Name FROM Account WHERE id =: LineItemType.Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Stakeholder__c].Name;
            String stakeholderName = '';
            List<Account> AccountList = [SELECT Name FROM Account WHERE id =: LineItemType.Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Stakeholder__c LIMIT 1];
            if(AccountList != null && AccountList.size() > 0){
                stakeholderName = AccountList[0].Name;
            }else{
                List<Account> AccountList1 = [SELECT Name FROM Account WHERE id =: LineItemType.Disclosure_Claim_for_Payment__r.Eligible_Claim_for_Payment__r.Stakeholder__c LIMIT 1];
                if(AccountList1 != null && AccountList1.size() > 0){
                    stakeholderName = AccountList1[0].Name;
                }
            }
            
            System.Debug('#retrieve reportPeriod#');
            //String reportPeriod = [SELECT Name FROM Reporting_Period__c WHERE Id =: LineItemType.Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Reporting_Period__c].Name;
            String reportPeriod = '';
            List<Reporting_Period__c> ReportList = [SELECT Name FROM Reporting_Period__c WHERE Id =: LineItemType.Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Reporting_Period__c];
            if(ReportList != null && ReportList.size() > 0){
                reportPeriod = AccountList[0].Name;
            }else{
                List<Reporting_Period__c> ReportList1 = [SELECT Name FROM Reporting_Period__c WHERE Id =: LineItemType.Disclosure_Claim_for_Payment__r.Eligible_Claim_for_Payment__r.Reporting_Period__c];
                if(ReportList1 != null && ReportList1.size() > 0){
                    reportPeriod = ReportList1[0].Name;
                }
            }
            
            this.lineItemTypeLabel = '' + stakeholderName
                + ' - ' + LineItemType.Disclosure_Claim_for_Payment__r.RecordType.Name 
                + ' ' + reportPeriod
                + ' - ' + LineItemType.Line_Item_Category__r.Line_Item_Category__c;
            
            this.lineItemrecordType = [SELECT Id, name FROM RecordType WHERE name = 'Line Item' LIMIT 1].Id;
            
            this.Labels = Static_Label__c.GetAll();
            this.IsEdit = false;
            this.isAddRowClick = false;
            this.SController = sc;
            isCloneDisclosureObject = LineItemType.Disclosure_Claim_for_Payment__r.Cloned_Disclosure_Claim_for_Payment__c != null;
            //this.QueryLineItemTypes();
            numberItemPerPageOptions = new List<SelectOption>();
            numberItemPerPageOptions.add(new SelectOption('5', '5'));
            numberItemPerPageOptions.add(new SelectOption('10', '10'));
            numberItemPerPageOptions.add(new SelectOption('20', '20'));
            numberItemPerPageOptions.add(new SelectOption('50', '50'));
            numberItemPerPageOptions.add(new SelectOption('100', '100'));
            
            this.buildPagingInfo();
            
            this.IsFunctionOrVenture = LineItemType.Line_Item_Category__r.Reference_Number__c == '1004' || LineItemType.Line_Item_Category__r.Reference_Number__c == '1005';
            for(FieldSetMember item :Schema.SObjectType.Line_Item__c.fieldSets.getMap().get('X' + LineItemType.Line_Item_Category__r.Reference_Number__c).Fields){
                if(item.FieldPath == 'Function_or_Venture__c'){
                    this.FieldSetContainsFunctionOrVenture = true;  
                    break;
                }
            }
            this.OptionsFunctionOrVenture = new List<SelectOption>();
            if(this.IsFunctionOrVenture==true || this.FieldSetContainsFunctionOrVenture==true){
                for(Line_Item__c item :[
                    SELECT Id,Name,Description_Name_of_Function_or_Venture__c 
                    FROM Line_Item__c 
                    WHERE Line_Item_Type__r.Disclosure_Claim_for_Payment__c = :this.LineItemType.Disclosure_Claim_for_Payment__c
                    	AND Line_Item_Type__r.Line_Item_Category__r.Reference_Number__c = '1003'
                    	AND RecordTypeId =:lineItemrecordType
                ]){
                    this.OptionsFunctionOrVenture.Add(new SelectOption(item.Id, item.Description_Name_of_Function_or_Venture__c == null ? item.Name : item.Description_Name_of_Function_or_Venture__c));
                }
            }
            
        }
        catch(Exception ex){
            ApexPages.AddMessages(ex);
            
            System.Debug('#Exception#' + ex.getMessage());
        }
    }
    /*
    public boolean hasNoteRow(String Id){
        Integer count = [SELECT Count() FROM Note WHERE ParentId =:Id];
        if(count>0) {
            return true;
        }else{
            return false;
        }
    }*/
    
    public Line_Item_Type__c GetEntityById(string id){
        return [
            SELECT Id, Name, Line_Item_Category__r.Line_Item_Category__c, Line_Item_Category__r.Reference_Number__c
            	, Nil_Disclosure_Claim_for_Payment__c,Line_Item_Category__r.Add_Row__c
            	,Calculated_Amount__c,Form_Amount__c,Calculated_Count__c,Form_Count__c
            	,Line_Item_Category__r.Calculated_Total_Amount__c,Line_Item_Category__r.Form_Total_Amount__c
            	,Line_Item_Category__r.Calculated_Total_Count__c,Line_Item_Category__r.Form_Total_Count__c
            	,Line_Item_Category__r.Remove_Row__c,Line_Item_Category__r.Default_Number_of_Rows__c
            	,Line_Item_Category__r.Reconcile_Type__c
            	,Disclosure_Claim_for_Payment__r.Cloned_Disclosure_Claim_for_Payment__c
            	,Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Reporting_Period__c
            	,Disclosure_Claim_for_Payment__r.RecordType.Name
                ,Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Stakeholder__c
            	,Disclosure_Claim_for_Payment__r.Eligible_Claim_for_Payment__r.Stakeholder__c
            	,Disclosure_Claim_for_Payment__r.Eligible_Claim_for_Payment__r.Reporting_Period__c
            	//,Disclosure_Claim_for_Payment__r.Nil_Disclosure__c
            	,Disclosure_Claim_for_Payment__c
            	,Line_Item_Category__r.Aggregated_Category__c
            FROM Line_Item_Type__c
            WHERE Id = :id
            LIMIT 1
        ];
    }
    
    public Disclosure_Claim_for_Payment__c GetDCPEntity(String dcpId){
        return [SELECT Id, Nil_Disclosure__c FROM Disclosure_Claim_for_Payment__c WHERE Id =: dcpId LIMIT 1];
    }
   
    /* NOT USE FUNC
    private List<Line_Item__c> GetLineItemsByLineItemTypeIds(String litIds){
        String query = LineItemAllFields();
        query += ' FROM Line_Item__c WHERE Line_Item_Type__c=:litIds'
            		+ ' AND RecordTypeId=\'' + lineItemrecordType + '\' ORDER BY CreatedDate' ;
        return Database.query(query);
    }*/
    
    private List<LineItemWrapper> buildLineItemWrapper (List<Line_Item__c> lineItems) {
        String lineitemtypeno = LineItemType.Line_Item_Category__r.Reference_Number__c;
        // Get list of line Item Id
        Set<String> lineItemsId = new Set<String>();
        for (Line_Item__c item : lineItems) {
            lineItemsId.add(item.Id);
        }
        Map<Id, AggregateResult> LineItemsNoteCount = new Map<Id, AggregateResult>(
            				[SELECT ParentId Id, COUNT(Id) Cnt FROM Note 
                             WHERE ParentId IN :lineItemsId 
                             GROUP BY ParentId]);
        
        List<LineItemWrapper> temp = new List<LineItemWrapper>();
        for(Line_Item__c item: lineItems){
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, String.valueof((Integer)LineItemsNoteCount.get(item.Id).get('Cnt'))));
            Boolean hasNote = false;
            if (LineItemsNoteCount.containsKey(item.Id)) {
                hasNote = true;
            }
            //US4626 & US4670
            if(lineitemtypeno.equals('1000')||lineitemtypeno.equals('0999')||lineitemtypeno.equals('1007')||lineitemtypeno.equals('1016')){
                if(LineItemType.Nil_Disclosure_Claim_for_Payment__c){
                    if(lineitemtypeno.equals('1000')||lineitemtypeno.equals('0999')){
                        item.Total_Number_of_Small_Donations_Received__c = NULL;
                        item.Total_Value_of_Small_Donations_Received__c = NULL;                        
                    }else if(lineitemtypeno.equals('1007')){
                        item.Total_Number_of_Small_Donations_Made__c = NULL;
                        item.Total_Value_of_Small_Donations_Made__c = NULL;                        
                    }else if(lineitemtypeno.equals('1016')){
                        item.Amount__c = NULL;                        
                    }
                }
                IF(item.Total_Number_of_Small_Donations_Received__c == 0)
                    item.Total_Number_of_Small_Donations_Received__c = NULL;
                IF(item.Total_Number_of_Small_Donations_Made__c == 0)
                    item.Total_Number_of_Small_Donations_Made__c = NULL;
                IF(item.Amount__c == 0)
                    item.Amount__c = NULL;                
            }
            
            LineItemWrapper t = new LineItemWrapper(recordCounter++, item, true, hasNote, this.IsEdit);
            temp.Add(t);
        }
        return temp;
    }
    
    public void buildPagingInfo() {
        String query = LineItemAllFields();
        String filter = ' FROM Line_Item__c WHERE Line_Item_Type__c=\'' + LineItemType.Id + '\''
            			+ ' AND RecordTypeId=\'' + lineItemrecordType + '\' ';
        query += filter;
        String countQuery = 'SELECT COUNT() ' + filter;
        try {
            this.RecordCounter = 0;
            //this.LineItemPagingInfo = new PagingInfo('LineItemPagingInfo', query, countQuery, 'CreatedDate','DESC');
            // Store page size
            Integer pageSize = 5;
            if (this.LineItemPagingInfo != null) {
                pageSize = this.LineItemPagingInfo.PageSize;
            }
            this.LineItemPagingInfo = new PagingInfo('LineItemPagingInfo', query, countQuery, 'CreatedDate','');
            LineItemPagingInfo.PageSize = pageSize;
            QueryLineItemTypes();
        } catch(Exception ex){
            ApexPages.AddMessages(ex);
        }
    }
    
    public void Nil_Checked(){
        if(this.Disclosure.Nil_Disclosure__c == true){
            integer count = [SELECT COUNT() FROM Line_Item__c WHERE Line_Item_Type__c = :this.LineItemType.Id AND Amount__c = 0];
            if(count > 0){
                ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please add a valid amount for all line items!'));
                this.Disclosure.Nil_Disclosure__c = false;
                
                return;
            }
        }
        this.QueryLineItemTypes();
    }
    
    public void QueryLineItemTypes(){
        //ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.Info, string.valueof(LineItemPagingInfo.PageSize)));
        //ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.Info, LineItemPagingInfo.OrderDirection));
        try {
            this.RecordCounter = 0;
            System.Debug('#Invoking LineItemPagingInfo.GetRecords()#');
            List<Line_Item__c> lineItems = LineItemPagingInfo.GetRecords();
            System.Debug('#Invoked LineItemPagingInfo.GetRecords()#success#');
            
            this.LineItemWrapperList = buildLineItemWrapper(lineItems);
            //ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.Info, string.valueof(this.LineItemWrapperList)));
        } catch(Exception ex){
            ApexPages.AddMessages(ex);
        }
    }
    private string LineItemAllFields(){
        Map<String, Schema.SObjectField> fldObjMap = schema.SObjectType.Line_Item__c.fields.getMap();
		List<Schema.SObjectField> fldObjMapValues = fldObjMap.values();
        
        String theQuery = 'SELECT ';
        for(Schema.SObjectField s : fldObjMapValues)
        {
			if (s.getDescribe().isAccessible()) {
	           String theName = s.getDescribe().getName();
	           theQuery += theName + ',';
			}
        }
        theQuery += ' Line_Item_Type__r.Line_Item_Category__r.Reference_Number__c, Cloned_Line_Item__r.Name ';
        if (theQuery.contains('LastReferencedDate,'))
        	theQuery = theQuery.remove('LastReferencedDate,');
        // Trim last comma
        //theQuery = theQuery.subString(0, theQuery.length() - 1);
        System.Debug('aa: '+ theQuery);
        //ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'a: ' + theQuery));
        return theQuery;
    }
    
    public void btnEditRow_Click(){
        integer lineitemid = integer.ValueOf(ApexPages.CurrentPage().GetParameters().Get('lineitemid'));
        for(integer i = 0; i < LineItemWrapperList.Size(); i++){
            if(LineItemWrapperList[i].Id == lineitemid){
                LineItemWrapperList[i].IsEdit = true;
                break;
            }
        }
    }
    
    public void btnAddRow_Click(){
        try{
			if (LineItemWrapperList.size() > 0) {
				this.LineItemWrapperList.Add(0,new LineItemWrapper(this.RecordCounter++, new Line_Item__c(RecordTypeId = this.lineItemrecordType), false, false, true));
			} else {
				this.LineItemWrapperList.Add(new LineItemWrapper(this.RecordCounter++, new Line_Item__c(RecordTypeId = this.lineItemrecordType), false, false, true));
			}
            isAddRowClick = true;
        }
        catch(Exception ex){
            ApexPages.AddMessages(ex);
        }
    }
    
    public void btnDelRow_Click(){
        try{
            integer lineitemid = integer.ValueOf(ApexPages.CurrentPage().GetParameters().Get('lineitemid'));
            for(integer i = 0; i < LineItemWrapperList.Size(); i++){
                if(LineItemWrapperList[i].Id == lineitemid){
                    if (LineItemWrapperList[i].IsExist) {
                        delete LineItemWrapperList[i].Item;
                    }
                   	LineItemWrapperList.Remove(i);
            		this.LineItemType = GetEntityById(LineItemType.Id);
                    break;
                }
            }
        }
        catch(Exception ex){
            ApexPages.AddMessages(ex);
        }
    }
    
	public void btnSaveRow_Click(){
        Savepoint sp = Database.setSavepoint();
		try{
            integer lineitemid = integer.ValueOf(ApexPages.CurrentPage().GetParameters().Get('lineitemid'));
			String lineitemtypeno = LineItemType.Line_Item_Category__r.Reference_Number__c;
            for(integer i = 0; i < LineItemWrapperList.Size(); i++){
                if(LineItemWrapperList[i].Id == lineitemid){
                    if(!LineItemWrapperList[i].IsExist){
                    	LineItemWrapperList[i].Item = LineItemWrapperList[i].Item.Clone(false,false);
						LineItemWrapperList[i].Item.Line_Item_Type__c = LineItemType.Id;
                    }
                    if (lineitemtypeno.equals('1000')||lineitemtypeno.equals('0999')) {                        
                        if(LineItemWrapperList[i].Item.Total_Number_of_Small_Donations_Received__c == NULL)
                          	LineItemWrapperList[i].Item.Total_Number_of_Small_Donations_Received__c = 0;
                    }
                    else if (lineitemtypeno.equals('1007')) {                        
                        if(LineItemWrapperList[i].Item.Total_Number_of_Small_Donations_Made__c == NULL)
                          	LineItemWrapperList[i].Item.Total_Number_of_Small_Donations_Made__c = 0;
                    }
                    else if (lineitemtypeno.equals('1016')) {                        
                        if(LineItemWrapperList[i].Item.Amount__c == NULL)
                          	LineItemWrapperList[i].Item.Amount__c = 0;
                    }  
                    upsert LineItemWrapperList[i].Item;
					// If Line Item Type Reference number is 1001 or 1005, create new Disclosure Obligation
					if ((lineitemtypeno.equals('1001') || lineitemtypeno.equals('1005')) && LineItemWrapperList[i].Item.Stakeholder__c!=null) {
						Integer count = [SELECT COUNT()
										 FROM Disclosure_Obligation__c
										 WHERE Reporting_Period__c = :LineItemType.Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Reporting_Period__c
										 AND Stakeholder__c=:LineItemWrapperList[i].Item.Stakeholder__c];
						if (count == 0) {
							Disclosure_Obligation__c disclosure_ob = new Disclosure_Obligation__c();
							disclosure_ob.Reporting_Period__c = LineItemType.Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Reporting_Period__c;
							disclosure_ob.Stakeholder__c = LineItemWrapperList[i].Item.Stakeholder__c;
                            //US4494 ==>
                            List<Account> accList = [Select Name from Account Where Id=:LineItemWrapperList[i].Item.Stakeholder__c];
                            String stakeHolderName = '';
                            if (accList.size() > 0) stakeHolderName = accList.get(0).Name;
                            String reportingPeriod;
                            List<Reporting_Period__c> reportPerId = [SELECT Date_From__c, Date_To__c 
                                                       FROM Reporting_Period__c 
                                                       WHERE Id =:disclosure_ob.Reporting_Period__c];
                            if(reportPerId.size()>0){
                            reportingPeriod = (reportPerId[0].Date_From__c != null ? reportPerId[0].Date_From__c.Year() + '' : '') 
                                + '/' + (reportPerId[0].Date_To__c != null ? reportPerId[0].Date_To__c.Year() + '' : '');                
                            }
                            disclosure_ob.Name = stakeHolderName + ' - Donor Disclosure Obligation ' + reportingPeriod;
                            //<== US4494
							upsert disclosure_ob;
						}
					}
					// End adding new Disclosure Obligation
                    
                    String query = LineItemAllFields();
                    query += ' FROM Line_Item__c WHERE Id = \'' + LineItemWrapperList[i].Item.Id + '\' LIMIT 1';
                    List<Line_Item__c> liList = Database.query(query);
                    if (liList.size() > 0) {
                        LineItemWrapperList[i].Item = liList.get(0);
                    }
                    
					LineItemWrapperList[i].IsExist = true;
					LineItemWrapperList[i].IsEdit 	= false;
                    
            		this.LineItemType = GetEntityById(LineItemType.Id);
                    break;
                }
            }
        }
        catch(Exception ex){
            ApexPages.AddMessages(ex);
            Database.rollback(sp);
        }
	}
    
    public void btnQuickSaveJS_Click(){
        Savepoint sp = Database.setSavepoint();
        try {
            upsert Disclosure;
			upsert LineItemType;
			if (Disclosure.Nil_Disclosure__c != true) {
				if (saveLineItems(LineItemType)) {
					
				}
			}
            this.LineItemType = GetEntityById(LineItemType.Id);
            this.IsEdit = false;
            if(!LineItemType.Nil_Disclosure_Claim_for_Payment__c && LineItemType.Line_Item_Category__r.Add_Row__c) {
                this.IsEdit = true;
            	btnAddRow_Click();
            }
        } 
        catch(Exception ex){
            ApexPages.AddMessages(ex);
            Database.rollback(sp);
            //return false;
        }
    }
    
    public void btnQuickSave_Click(){
        if(this.btnSave_Click()){
            this.IsEdit = false;
            //ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'a: ' + this.IsEdit));
            //this.QueryLineItemTypes();
            this.LineItemType = GetEntityById(LineItemType.Id);
        }
    }
    
    public PageReference btnSaveClose_Click(){
        if(this.btnSave_Click()){
            this.StartUpScript = 'top.window.location.href="/'+this.LineItemType.Disclosure_Claim_for_Payment__c+'"';
        }   
        return null;
    }
    
    public boolean saveLineItems(Line_Item_Type__c lit) {
        try{
            //clone and upsert line item
            // If Line Item Type Reference number is 1001 or 1005, create new Disclosure Obligation for the Line Item
            Set<String> StakeHolderList = new Set<String>();
            
            List<Line_Item__c> lineItemToInsert = new List<Line_Item__c>();
    
            boolean isBelongToList = false;
            String referenceNumber = lit.Line_Item_Category__r.Reference_Number__c;
            //if (referenceNumber.equals('1001') || referenceNumber.equals('1005')) {//commented and replaced for DE4522
            if(lit.Line_Item_Category__r.Aggregated_Category__c == 'Reportable Donations Received'){
                isBelongToList = true;
            }            
            // Before US4417
            /*for(LineItemWrapper li :LineItemWrapperList){
                if(!li.IsExist){
                    li.Item = li.Item.Clone(false,false);
                    li.Item.Line_Item_Type__c = lit.Id;
                }
                lineItemToInsert.Add(li.Item);
                // Add stakeholder to list if line item type is 1001 or 1005
                if (isBelongToList && li.Item.Stakeholder__c!=null) {
                    StakeHolderList.Add(li.Item.Stakeholder__c);
                }
            }*/
            // US4417, order of new line item upon save
            
            if (referenceNumber.equals('1000') || referenceNumber.equals('0999') || referenceNumber.equals('1007') || referenceNumber.equals('1016')) {
                for(Integer i = LineItemWrapperList.size() - 1; i >= 0; i--){
                    LineItemWrapper li = LineItemWrapperList.get(i);
                    if (li.IsEdit) {
                        if(!li.IsExist){
                            li.Item = li.Item.Clone(false,false);
                            li.Item.Line_Item_Type__c = lit.Id;
                        }
                        if((referenceNumber.equals('1000')||referenceNumber.equals('0999')) && li.Item.Total_Number_of_Small_Donations_Received__c == NULL)
                          	li.Item.Total_Number_of_Small_Donations_Received__c = 0;
                        if(referenceNumber.equals('1007') && li.Item.Total_Number_of_Small_Donations_Made__c == NULL)
                          	li.Item.Total_Number_of_Small_Donations_Made__c = 0;
                        if(referenceNumber.equals('1016') && li.Item.Amount__c == NULL)
                          	li.Item.Amount__c = 0;
                        lineItemToInsert.Add(li.Item);
                    }
                }
            } else {
                for(Integer i = LineItemWrapperList.size() - 1; i >= 0; i--){
                    LineItemWrapper li = LineItemWrapperList.get(i);
                    if (li.IsEdit) {
                        if(!li.IsExist){
                            li.Item = li.Item.Clone(false,false);
                            li.Item.Line_Item_Type__c = lit.Id;
                        }
                        lineItemToInsert.Add(li.Item);
                        // Add stakeholder to list if line item type is 1001 or 1005
                        if (isBelongToList && li.Item.Stakeholder__c!=null) {
                            StakeHolderList.Add(li.Item.Stakeholder__c);
                        }
                    }
                }
            }
            //ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'a: ' + lineItemToInsert.size()));
            upsert lineItemToInsert;
            /*//Test
            for (Line_Item__c li : lineItemToInsert){
                ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'a: ' + li.Total_Number_of_Small_Donations_Received__c));
            }
			*/
            List<Disclosure_Obligation__c> existDOList = [
                    SELECT Stakeholder__c
                    FROM Disclosure_Obligation__c
                    WHERE Reporting_Period__c = :LineItemType.Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Reporting_Period__c
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
                    disclosure_ob.Reporting_Period__c = LineItemType.Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Reporting_Period__c;
                    disclosure_ob.Stakeholder__c = stakeHolderId;
                    //==> US4494
                    List<Account> accList = [Select Name from Account Where Id=:stakeHolderId];
                    String stakeHolderName = '';
                    if (accList.size() > 0) stakeHolderName = accList.get(0).Name;
                    String reportingPeriod;
                    List<Reporting_Period__c> reportPerId = [SELECT Date_From__c, Date_To__c 
                                                       FROM Reporting_Period__c 
                                                       WHERE Id =:disclosure_ob.Reporting_Period__c];
                    if(reportPerId.size()>0){
                    reportingPeriod = (reportPerId[0].Date_From__c != null ? reportPerId[0].Date_From__c.Year() + '' : '') 
                        + '/' + (reportPerId[0].Date_To__c != null ? reportPerId[0].Date_To__c.Year() + '' : '');                
                    }
                    disclosure_ob.Name = stakeHolderName + ' - Donor Disclosure Obligation ' + reportingPeriod;
                    //<== US4494
                    upsertDOList.add(disclosure_ob);
                }
            }
            
            upsert upsertDOList;
            
            //For US4417
            this.buildPagingInfo();
            
            //insert success
            for(LineItemWrapper li :LineItemWrapperList){
                li.IsExist = true;
                li.IsEdit = false;
            }
            
            
            return true;
        }catch(exception e){
            //ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'a: '));
            return false;
        }
	}
    public boolean btnSave_Click(){
        Savepoint sp = Database.setSavepoint();
        try {
            upsert Disclosure;
			upsert LineItemType;
			//if (LineItemType.Nil_Disclosure_Claim_for_Payment__c != true) {
            if (Disclosure.Nil_Disclosure__c != true) {
				if (saveLineItems(LineItemType)) {
					ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Record saved successfully'));
				}
			}
        } 
        catch(Exception ex){
            ApexPages.AddMessages(ex);
            Database.rollback(sp);
            return false;
        }
        
        
        return true;
    }
    
    public void btnCancelRow_Click(){
        integer lineitemid = integer.ValueOf(ApexPages.CurrentPage().GetParameters().Get('lineitemid'));
        
        for(integer i = 0; i < LineItemWrapperList.Size(); i++){
            if(LineItemWrapperList[i].Id == lineitemid){
				LineItemWrapperList[i].IsEdit = false;
				if (LineItemWrapperList[i].IsExist) {
					String query = LineItemAllFields();
					query += ' FROM Line_Item__c WHERE Id = \'' + LineItemWrapperList[i].Item.Id + '\' LIMIT 1';
					List<Line_Item__c> liList = Database.query(query);
					if (liList.size() > 0) {
						LineItemWrapperList[i].Item = liList.get(0);
					}
				} else {
					LineItemWrapperList.remove(i);
				}
			
                break;
            }
        }
    }
    
    public void btnEdit_Click(){
        //ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.INFO, String.Valueof(LineItemType.Line_Item_Category__r.Add_Row__c)));        
        //Check AddRow checkbox?
        this.IsEdit = true;
        this.isAddRowClick = false;
		for(LineItemWrapper li :LineItemWrapperList){
			li.IsEdit = true;
		}
    }
    
    public void btnCancel_Click(){
        this.IsEdit = false;
        this.QueryLineItemTypes();
        LineItemType = GetEntityById(LineItemType.Id);
    }
    
    public boolean SubmitChanges(){
        return true;
    }
    
    public class LineItemWrapper{
        public integer Id{get;set;}
        public Line_Item__c Item{get;set;}
        public boolean IsExist{get;set;}
        public boolean IsNoteExist{get;set;}
        public boolean IsEdit{get;set;}
        
        public LineItemWrapper(integer idCounter, Line_Item__c li, boolean isExist, boolean IsNoteExist) {
            this(idCounter, li, isExist, IsNoteExist, true);
        }
        public LineItemWrapper(integer idCounter, Line_Item__c li, boolean isExist, boolean IsNoteExist, boolean isEdit){
            this.Id = idCounter;
            this.Item = li;
            this.IsExist = isExist;
            this.IsNoteExist = IsNoteExist;
            this.IsEdit = isEdit;
        }
    }
}