/* allowing the User to run through the audit of a Disclosure or Claim for Payment 
forms Line Items once they have been input by the Disclosure Team
*/
public class AuditLineItemFormController{
    public integer recordCounter{get;set;}
    public List<LineItemWrapper> LineItemWrapperList{get;set;}
    public transient Map<string, Schema.FieldSet> MapLineItemFieldSets;
    public Map<String, Static_Label__c> Labels{get;set;}
    //public boolean IsEdit{get;set;}
    
    public Line_Item_Type__c LineItemType{get;set;}
    public boolean isCloneDisclosureObject{get;set;}
    public boolean isLineItemHidden{get;set;}
    public PagingInfo LineItemPagingInfo{get;set;}
    public String doID{get;set;}
    private String sortByColumn;
    private String sortOrder;
    private String lineItemrecordType;
    private String auditLineItemrecordType;
    public String selectedLineItemType{get;set;}
    public String reloadId{get;set;}
    public List<SelectOption> LineItemTypeOptions{get;set;}
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
    
	public AuditLineItemFormController(){
        try{
            doID = ApexPages.currentPage().getParameters().get('do');
            String litId = ApexPages.currentPage().getParameters().get('litId');
            LineItemTypeOptions = new List<SelectOption>();
            List<Line_Item_Type__c> lineItemTypeList = [SELECT Id, Name, Line_Item_Category__r.Line_Item_Category__c,
                                                        		Disclosure_Claim_for_Payment__r.Name,Nil_Disclosure_Claim_for_Payment__c
                                                        FROM Line_Item_Type__c 
                                                        WHERE Disclosure_Claim_for_Payment__c = :doID
                                                        ORDER BY Order_Number__c
                                                       ];
            if (lineItemTypeList.size() == 0) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'No Line Item Type found on this Disclosures/Claim for Payments Record.'));
                return;
            }
            for(Line_Item_Type__c lit : lineItemTypeList) {
                 // LineItemTypeOptions.add(new SelectOption(lit.Id, lit.Disclosure_Claim_for_Payment__r.Name
                 //                                       + ' ' + lit.Line_Item_Category__r.Line_Item_Category__c));
                // Remove Number BF line item type
                LineItemTypeOptions.add(new SelectOption(lit.Id, lit.Line_Item_Category__r.Line_Item_Category__c + ''));
            }
            if (litId != null && litId != 'undefined') {
                selectedLineItemType = litId;
            } else {
            	selectedLineItemType = LineItemTypeOptions.get(0).getValue();
            }
            LineItemType = GetEntityById(selectedLineItemType);
            this.lineItemrecordType = [SELECT Id, name FROM RecordType WHERE name = 'Line Item' LIMIT 1].Id;
            this.auditLineItemrecordType = [SELECT Id, name FROM RecordType WHERE name = 'Audit Line Item' LIMIT 1].Id;
            this.Labels = Static_Label__c.GetAll(); /*
            
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'dostake' + LineItemType.Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Stakeholder__c));
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'dorep' + LineItemType.Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Reporting_Period__c ));
            
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'ecstake' + LineItemType.Disclosure_Claim_for_Payment__r.Eligible_Claim_for_Payment__r.Stakeholder__c));
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'ecrep' + LineItemType.Disclosure_Claim_for_Payment__r.Eligible_Claim_for_Payment__r.Reporting_Period__c ));*/
            //US5201
            changeLineItemTypeLabel(); 
            this.isLineItemHidden = false;
            //this.IsEdit = false;
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
            for(FieldSetMember item :Schema.SObjectType.Line_Item__c.fieldSets.getMap().get('Audit_' + LineItemType.Line_Item_Category__r.Reference_Number__c).Fields){
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
            //US5090
        	ExpandAll();
        }
        catch(Exception ex){
            ApexPages.AddMessages(ex);
        }
    }    
    
    private void changeLineItemTypeLabel(){
        List<Account> stakeholders = [
            SELECT Name 
            FROM Account 
            WHERE id =: LineItemType.Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Stakeholder__c
            	OR id =: LineItemType.Disclosure_Claim_for_Payment__r.Eligible_Claim_For_Payment__r.Stakeholder__c
        ];
        List<Reporting_Period__c> reportPeriods = [
            SELECT Name 
            FROM Reporting_Period__c 
            WHERE Id =: LineItemType.Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Reporting_Period__c
            	OR id =: LineItemType.Disclosure_Claim_for_Payment__r.Eligible_Claim_For_Payment__r.Reporting_Period__c
        ];
        this.lineItemTypeLabel = '';
        
        if(!stakeholders.isEmpty()){
            this.lineItemTypeLabel += stakeholders[0].Name + ' - ';
        }
        this.lineItemTypeLabel += LineItemType.Disclosure_Claim_for_Payment__r.RecordType.Name + ' ';
        
        if(!reportPeriods.isEmpty()){
            this.lineItemTypeLabel += reportPeriods[0].Name;// + ' - ';
        }
        this.lineItemTypeLabel +=  ' - ' + LineItemType.Line_Item_Category__r.Line_Item_Category__c;
    }
    
    public void ChangeLineItemType() {
        LineItemType = GetEntityById(selectedLineItemType);
        isCloneDisclosureObject = LineItemType.Disclosure_Claim_for_Payment__r.Cloned_Disclosure_Claim_for_Payment__c != null;
        buildPagingInfo();
        //US5090
        ExpandAll();
        //US5201
        changeLineItemTypeLabel();    
    }
    public Line_Item_Type__c GetEntityById(string id){
        return [
            SELECT Id, Name, Line_Item_Category__r.Line_Item_Category__c, Line_Item_Category__r.Reference_Number__c
            	, Nil_Disclosure_Claim_for_Payment__c,Line_Item_Category__r.Add_Row__c
            	,Calculated_Amount__c,Form_Amount__c,Calculated_Count__c,Form_Count__c
            	,Calculated_Audit_Amount__c,Calculated_Audit_Count__c,Difference_Amount__c,Difference_Count__c
            	,Line_Item_Category__r.Calculated_Total_Amount__c,Line_Item_Category__r.Form_Total_Amount__c
            	,Line_Item_Category__r.Calculated_Total_Count__c,Line_Item_Category__r.Form_Total_Count__c
            	,Line_Item_Category__r.Calculated_Total_Audit_Count__c,Line_Item_Category__r.Calculated_Total_Audit_Amount__c
            	,Line_Item_Category__r.Remove_Row__c,Line_Item_Category__r.Default_Number_of_Rows__c
            	,Line_Item_Category__r.Reconcile_Type__c,Line_Item_Category__r.Show_Advertising_Material__c
            	,Disclosure_Claim_for_Payment__r.Cloned_Disclosure_Claim_for_Payment__c
            	,Disclosure_Claim_for_Payment__r.Version_Number__c
            	,Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Reporting_Period__c
                ,Disclosure_Claim_for_Payment__r.Disclosure_Obligation__r.Stakeholder__c
            	,Disclosure_Claim_for_Payment__r.RecordType.Name
            	,Disclosure_Claim_for_Payment__c
            	,Disclosure_Claim_for_Payment__r.Eligible_Claim_for_Payment__r.Reporting_Period__c
            	,Disclosure_Claim_for_Payment__r.Eligible_Claim_for_Payment__r.Stakeholder__c

            FROM Line_Item_Type__c
            WHERE Id = :id
            LIMIT 1
        ];
    }
    /*
    private List<Line_Item__c> GetLineItemsByLineItemTypeIds(String litIds, String recordType){
        String query = LineItemAllFields();
        query += ' FROM Line_Item__c WHERE Line_Item_Type__c=:litIds'
            		+ ' AND RecordTypeId=\'' + recordType + '\' ORDER BY CreatedDate' ;
        return Database.query(query);
    }*/
    
    private List<LineItemWrapper> buildLineItemWrapper (List<Line_Item__c> lineItems) {

        
        List<LineItemWrapper> temp = new List<LineItemWrapper>();
       	// Add all Audit Line Items which are used for Line Item Type Record
        String queryAuditOnLineItemType = LineItemAllFields();
        queryAuditOnLineItemType += ' FROM Line_Item__c WHERE Line_Item_Type__c=\'' + LineItemType.Id 
            		+ '\' AND Line_Item__c = null AND RecordTypeId=:auditLineItemrecordType ORDER BY CreatedDate DESC' ;
        List<Line_Item__c> AuditLineItemTypes =	Database.query(queryAuditOnLineItemType);
        // End
        // For the other audit line items
        Set<String> LineItemIds = new Set<String>();
        // Get Id of line Item
        for(Line_Item__c item: lineItems){
            LineItemIds.add(item.Id);
        }
        // Query To get all Audit Line Items
        String query = LineItemAllFields();
        query += ' FROM Line_Item__c WHERE Line_Item_Type__c=\'' + LineItemType.Id 
            		+ '\' AND Line_Item__c IN:LineItemIds ORDER BY CreatedDate DESC' ;
        List<Line_Item__c> AuditLineItems =	Database.query(query);
        
        // Create a Map with key is line item and value is list of audit for that line item
        Map<String, List<Line_Item__c>> lineItemMaps = new Map<String, List<Line_Item__c>>();
        for(Line_Item__c item : AuditLineItems){
            if (lineItemMaps.get(item.Line_Item__c) == null) {
                lineItemMaps.put(item.Line_Item__c, new List<Line_Item__c>());
            }
            lineItemMaps.get(item.Line_Item__c).add(item);
            LineItemIds.add(item.Id);
        }
        
        // Add Audit line item type for checking note and non-compliance
        for(Line_Item__c item : AuditLineItemTypes){
            LineItemIds.add(item.Id);
        }
        
        // For note
        Map<Id, AggregateResult> LineItemsNoteCount = new Map<Id, AggregateResult>(
            				[SELECT ParentId Id, COUNT(Id) Cnt FROM Note 
                             WHERE ParentId IN :LineItemIds 
                             GROUP BY ParentId]);
        // For Non-Compliance
        Map<Id, AggregateResult> LineItemsNonComplianceCount = new Map<Id, AggregateResult>(
            				[SELECT WhatId Id, COUNT(Id) Cnt FROM Task 
                             WHERE WhatId IN :LineItemIds 
                             GROUP BY WhatId]);
        // For Reconcile
        Map<Id, AggregateResult> LineItemsReconcileCount = new Map<Id, AggregateResult>();
        if (this.LineItemType.Line_Item_Category__r.Reconcile_Type__c == 'Donations Received'){
            LineItemsReconcileCount = new Map<Id, AggregateResult>(
                [SELECT Line_Item_Donation_Received__c Id, COUNT(Line_Item_Donation_Made__c) Cnt FROM Reconciled_Line_Item__c 
                 WHERE Line_Item_Donation_Received__c IN :LineItemIds 
                 GROUP BY Line_Item_Donation_Received__c]);
        } else if (this.LineItemType.Line_Item_Category__r.Reconcile_Type__c == 'Donations Made'){
            LineItemsReconcileCount = new Map<Id, AggregateResult>(
                [SELECT Line_Item_Donation_Made__c Id, COUNT(Line_Item_Donation_Received__c) Cnt FROM Reconciled_Line_Item__c 
                 WHERE Line_Item_Donation_Made__c IN :LineItemIds 
                 GROUP BY Line_Item_Donation_Made__c]);
        }
        // For Vouching
        Map<Id, AggregateResult> lineItemsVouchingCount = new Map<Id, AggregateResult>(
            				[SELECT Line_Item__c Id, COUNT(Id) Cnt FROM Vouched_Line_Item__c 
                             WHERE Line_Item__c IN :LineItemIds
                             AND Trim_Record__r.Vouching_Type__c != 'Advertising Material'
                             GROUP BY Line_Item__c]);
        // For Advertising Material
        Map<Id, AggregateResult> lineItemsAdMaterialCount = new Map<Id, AggregateResult>(
            				[SELECT Line_Item__c Id, COUNT(Id) Cnt FROM Vouched_Line_Item__c 
                             WHERE Line_Item__c IN :LineItemIds
                             AND Trim_Record__r.Vouching_Type__c = 'Advertising Material'
                             GROUP BY Line_Item__c]);
        // Build wrapper foreach audit line item type
        for(Line_Item__c item: AuditLineItemTypes){
            Boolean hasNoteOnLineItem = false;
            Boolean hasNonComplianceOnLineItem = false;
            Boolean hasReconcileOnLineItem = false;
            Boolean hasVouchingOnLineItem = false;
            String advertisingMaterial = 'Not Yet Provided';
            if (LineItemsNoteCount.containsKey(item.Id)) {
                hasNoteOnLineItem = true;
            }
            if (LineItemsNonComplianceCount.containsKey(item.Id)) {
                hasNonComplianceOnLineItem = true;
            }
            if (LineItemsReconcileCount.containsKey(item.Id)) {
                hasReconcileOnLineItem = true;
            }
            if (lineItemsVouchingCount.containsKey(item.Id)) {
                hasVouchingOnLineItem = true;
            }
            if (lineItemsAdMaterialCount.containsKey(item.Id)) {
                advertisingMaterial = 'Advertising Material Provided';
            } else {
                if (item.No_Advertising_Material_Provided__c == true) 
                	advertisingMaterial = 'No Advertising Material Provided';
            }
            LineItemWrapper t = new LineItemWrapper(recordCounter++,item, false,hasNoteOnLineItem,hasNonComplianceOnLineItem,hasReconcileOnLineItem,hasVouchingOnLineItem,advertisingMaterial,true,false,false);
            t.IsExpand = true;
            temp.Add(t);
        }
		
        // Build wrapper foreach line item
        for(Line_Item__c item: lineItems){
            Boolean hasNoteOnLineItem = false;
            Boolean hasNonComplianceOnLineItem = false;
            Boolean hasReconcileOnLineItem = false;
            Boolean hasVouchingOnLineItem = false;
            if (LineItemsNoteCount.containsKey(item.Id)) {
                hasNoteOnLineItem = true;
            }
            if (LineItemsNonComplianceCount.containsKey(item.Id)) {
                hasNonComplianceOnLineItem = true;
            }
            if (LineItemsReconcileCount.containsKey(item.Id)) {
                hasReconcileOnLineItem = true;
            }
            if (lineItemsVouchingCount.containsKey(item.Id)) {
                hasVouchingOnLineItem = true;
            }
            
            LineItemWrapper t = new LineItemWrapper(recordCounter++,item, true,hasNoteOnLineItem,hasNonComplianceOnLineItem,hasReconcileOnLineItem,hasVouchingOnLineItem,'',true,false,false);
            
            temp.Add(t);
            if (lineItemMaps.containsKey(item.Id)) {
                for(Line_Item__c audit : lineItemMaps.get(item.Id)) {
                    Boolean hasNoteOnAudit = false;
                    Boolean hasNonComplianceOnAutdit = false;
                    Boolean hasReconcileOnAutdit = false;
            		Boolean hasVouchingOnAutdit = false;
            		String advertisingMaterial = 'Not Yet Provided';
                    if (LineItemsNoteCount.containsKey(audit.Id)) {
                        hasNoteOnAudit = true;
                    }
                    if (LineItemsNonComplianceCount.containsKey(audit.Id)) {
                        hasNonComplianceOnAutdit = true;
                    }
                    if (LineItemsReconcileCount.containsKey(audit.Id)) {
                        hasReconcileOnAutdit = true;
                    }
                    if (lineItemsVouchingCount.containsKey(audit.Id)) {
                        hasVouchingOnAutdit = true;
                    }
                    if (lineItemsAdMaterialCount.containsKey(audit.Id)) {
                        advertisingMaterial = 'Advertising Material Provided';
                    } else {
                        if (audit.No_Advertising_Material_Provided__c == true) 
                            advertisingMaterial = 'No Advertising Material Provided';
                    }
                    LineItemWrapper auditItem = new LineItemWrapper(recordCounter++,audit, false,hasNoteOnAudit,hasNonComplianceOnAutdit,hasReconcileOnAutdit,hasVouchingOnAutdit,advertisingMaterial,true,false,false);
                    temp.Add(auditItem);
                }
            }
        }
        
        //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Temp SIZE ' + temp.size()));
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
    
    public void QueryLineItemTypes(){
        //ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.Info, LineItemPagingInfo.OrderDirection));
        try {
            this.RecordCounter = 0;
            List<Line_Item__c> lineItems = LineItemPagingInfo.GetRecords();
            this.LineItemWrapperList = buildLineItemWrapper(lineItems);
        } catch(Exception ex){
            ApexPages.AddMessages(ex);
        }
    }
    private Line_Item__c getLineItemById(String Id) {
    	String query = LineItemAllFields();
        query += ' FROM Line_Item__c WHERE Id = \'' + Id + '\' LIMIT 1';
        List<Line_Item__c> liList = Database.query(query);
        if (liList.size() > 0) {
            return liList.get(0);
        }
        return null;
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
        theQuery += ' Line_Item_Type__r.Line_Item_Category__r.Reference_Number__c, Cloned_Line_Item__r.Name, Line_Item__r.Name ';
        if (theQuery.contains('LastReferencedDate,'))
        	theQuery = theQuery.remove('LastReferencedDate,');
        // Trim last comma
        //theQuery = theQuery.subString(0, theQuery.length() - 1);
        // ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,theQuery));
        return theQuery;
    }
    
    public void btnEditRow_Click(){
       Integer lineItemIdTemp = Integer.valueof(ApexPages.CurrentPage().GetParameters().Get('LineItemId'));
        for (Integer i = 0; i < LineItemWrapperList.size(); i++) {
            if (LineItemWrapperList[i].Id == lineItemIdTemp) {
                LineItemWrapperList[i].isEdit = true;
                break;
            }
        }
    }
    
    public void btnAddRow_Click(){
        try{
            Integer lineItemIdTemp = Integer.valueof(ApexPages.CurrentPage().GetParameters().Get('LineItemId'));
            String tempStr = ApexPages.CurrentPage().GetParameters().Get('IsAddFromExistALI');
            Boolean IsAddFromExistALI = false;
            if(tempStr!=null && tempStr.length()>0){
				IsAddFromExistALI = Boolean.ValueOf(tempStr);
            }
            
            for (Integer i = 0; i < LineItemWrapperList.size(); i++) {
                if (LineItemWrapperList[i].Id == lineItemIdTemp) {
                    Line_Item__c tempAudit;
                    if(LineItemWrapperList[i].Item.RecordTypeId == this.auditLineItemrecordType){
                        tempAudit = LineItemWrapperList[i].Item.Clone(false, true);
                        tempAudit.Cloned_Line_Item__c = LineItemWrapperList[i].Item.Id;
                    }else {
                        tempAudit = LineItemWrapperList[i].Item.Clone(false, true);
                        tempAudit.Line_Item__c=LineItemWrapperList[i].Item.Id;
                        tempAudit.RecordTypeId=this.auditLineItemrecordType;
                        tempAudit.Line_Item_Status__c = 'Not Audited';
                    	//tempAudit = new Line_Item__c (Line_Item__c=LineItemWrapperList[i].Item.Id, Line_Item_Type__c = LineItemType.Id, RecordTypeId=this.auditLineItemrecordType);
                    }
                    LineItemWrapper temp = new LineItemWrapper(recordCounter++,tempAudit, false, false, false, false, false, true, IsAddFromExistALI);
                    temp.IsExpand = true;
                    Boolean isAllowedToAdd = true;
                    //DE4623
                    //for (Integer j = i+1; j < LineItemWrapperList.size(); j++) {
                    Integer j = 0;
                    if(!IsAddFromExistALI){
                        j = i+1;
                    }else{
                        j=i;
                    }
                    for (j = j; j < LineItemWrapperList.size(); j++) {                        
                        if (LineItemWrapperList[j].isLineItem) {
                            break;
                        }
                        if (LineItemWrapperList[j].Item.Line_Item_Status__c == 'Not Audited') {
                            isAllowedToAdd = false;
                            break;
                        }
                    }
                    if (isAllowedToAdd) {
                        if (i == (LineItemWrapperList.size() - 1)) {
                            LineItemWrapperList.add(temp);
                        } else {
                            LineItemWrapperList.add(i+1,temp);
                        }
                    } else {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please change the status of Audit Line Item to something other than "Not Audited" before adding new record'));
                    }
                    break;
                }
            }
        }
        catch(Exception ex){
            ApexPages.AddMessages(ex);
        }
    }
    
    public void btnDelRow_Click(){
        try{
            integer lineItemIdTemp = integer.ValueOf(ApexPages.CurrentPage().GetParameters().Get('LineItemId'));
            for (Integer i = 0; i < LineItemWrapperList.size(); i++) {
                if(LineItemWrapperList[i].Id == lineItemIdTemp){
                    if (LineItemWrapperList[i].IsExist) {
                        delete LineItemWrapperList[i].Item;
                    }
                   	LineItemWrapperList.Remove(i);
                    break;
                }
            }
        } catch(Exception ex){
            ApexPages.AddMessages(ex);
        }
    }
    
	public void btnSaveRow_Click(){
        Savepoint sp = Database.setSavepoint();
        try	{
            integer lineItemIdTemp = integer.ValueOf(ApexPages.CurrentPage().GetParameters().Get('LineItemId'));
            List<Line_Item__c> upsertList = new List<Line_Item__c>();
            Integer tempLineItemIndex = 0;
            for (Integer i = 0; i < LineItemWrapperList.size(); i++) {
                if (LineItemWrapperList[i].isLineItem) {
                    tempLineItemIndex = i;
                }
                if (LineItemWrapperList[i].Id == lineItemIdTemp) {
                    if (!LineItemWrapperList[i].isExist) {
                        LineItemWrapperList[i].Item.Active__c = true;
                        // For DE4557, If audit line item type, not change to inactive
                        if (LineItemWrapperList[i].Item.Line_Item__c != null) {
                            // Update other audit line items to inactive
                            for (Integer j = tempLineItemIndex+1; j < LineItemWrapperList.size(); j++) {
                                if (LineItemWrapperList[j].isLineItem) {
                                    break;
                                }
                                if (j == i) {
                                    continue;
                                }
                                if (LineItemWrapperList[j].isExist) {
                                    LineItemWrapperList[j].Item.Active__c = false;
                                    LineItemWrapperList[j].Item.Line_Item_Status__c = 'Audited';
                                    upsertList.add(LineItemWrapperList[j].Item);
                                }
                            }
                            
                        }
                    }
                    upsertList.add(LineItemWrapperList[i].Item);
            		upsert upsertList;
                    //CloneRelatedInfo
                    if(LineItemWrapperList[i].Id == lineItemIdTemp && LineItemWrapperList[i].IsAddFromExistALI){
                        //ApexPages.AddMessage(new ApexPages.message(ApexPages.Severity.INFO, 'LineItemWrapperList[i].Item ' + LineItemWrapperList[i].Item.recordtypeid + ' '+ auditLineItemrecordType));
                        CloneRelatedInfo(LineItemWrapperList[i].Item);
                        LineItemWrapperList[i].IsAddFromExistALI = false;
                        reloadId = LineItemWrapperList[i].Item.Id;
                        ReloadLineItem();
                    }
                    LineItemWrapperList[i].Item = getLineItemById(LineItemWrapperList[i].Item.Id);
                    LineItemWrapperList[i].isExist = true;
                    LineItemWrapperList[i].isEdit = false;
                    break;
                }
            }
        } catch(Exception ex){
            ApexPages.AddMessages(ex);
            Database.rollback(sp);
        }
	}        
    
     public void btnCancelRow_Click(){
         integer lineItemIdTemp = integer.ValueOf(ApexPages.CurrentPage().GetParameters().Get('LineItemId'));
         for (Integer i = 0; i < LineItemWrapperList.size(); i++) {
             if (LineItemWrapperList[i].Id == lineItemIdTemp) {
                 LineItemWrapperList[i].IsEdit = false;
                 if (LineItemWrapperList[i].IsExist) {
	                 LineItemWrapperList[i].Item = getLineItemById(LineItemWrapperList[i].Item.Id);
				} else {
					LineItemWrapperList.remove(i);
				}
                break;
             }
         }
    }
    
    public void btnExpandRow_Click(){
         integer lineItemIdTemp = integer.ValueOf(ApexPages.CurrentPage().GetParameters().Get('LineItemId'));
         for (Integer i = 0; i < LineItemWrapperList.size(); i++) {
             if (LineItemWrapperList[i].Id == lineItemIdTemp) {
                 LineItemWrapperList[i].IsExpand = true;
                 for (Integer j = i + 1; j < LineItemWrapperList.size(); j++) {
                     if (LineItemWrapperList[j].IsLineItem) {
                         break;
                     }
                     LineItemWrapperList[j].IsExpand = true;
                 }
                break;
             }
         }
    }
    public void btnCollapseRow_Click(){
         integer lineItemIdTemp = integer.ValueOf(ApexPages.CurrentPage().GetParameters().Get('LineItemId'));
         for (Integer i = 0; i < LineItemWrapperList.size(); i++) {
             if (LineItemWrapperList[i].Id == lineItemIdTemp) {
                 LineItemWrapperList[i].IsExpand = false;
                 for (Integer j = i + 1; j < LineItemWrapperList.size(); j++) {
                     if (LineItemWrapperList[j].IsLineItem) {
                         break;
                     }
                     LineItemWrapperList[j].IsExpand = false;
                 }
                break;
             }
         }
    }
    public void btnAdd_Click(){
        Line_Item__c tempAudit = new Line_Item__c (Line_Item_Type__c = LineItemType.Id, RecordTypeId=this.auditLineItemrecordType);
        LineItemWrapper temp = new LineItemWrapper(recordCounter++,tempAudit, false, false, false,false, false, true, false);
        temp.IsExpand = true;
        if (LineItemWrapperList.size() == 0) {
            LineItemWrapperList.add(temp);
        } else {
            LineItemWrapperList.add(0,temp);
        }
    }
    
    public void CollapseAll(){
        boolean foundFirstLineItem = false;
        for(LineItemWrapper item : LineItemWrapperList ) {
            if (item.IsLineItem) {
                foundFirstLineItem = true;
            }
            if (foundFirstLineItem) {
                item.isExpand = false;
            }
        }
    }
    
    public void ExpandAll(){
        for(LineItemWrapper item : LineItemWrapperList ) {
            item.isExpand = true;
        }
    }
    
    public void btnHideLineItem_OnClick() {
        if (isLineItemHidden) {
            ExpandAll();
        }
    }
    public void btnQuickSave_Click(){
        saveAllRecords();
    }
    
    public PageReference btnSaveClose_Click(){
        if(this.saveAllRecords()){
            this.StartUpScript = 'top.window.location.href="/'+this.LineItemType.Disclosure_Claim_for_Payment__c+'"';
        }
        return null;
    }
    
    public void btnRefresh_OnClick() {
        LineItemType = GetEntityById(LineItemType.Id);
    }
    public void ReloadLineItem() {
        if (String.isEmpty(reloadId)) return;
        for (Integer i = 0; i < LineItemWrapperList.size(); i++) {
             if (LineItemWrapperList[i].Item.Id == reloadId) {
                 List<Note> noteList = [Select Id FROM Note WHERE ParentId =:reloadId];
                 List<Task> taskList = [Select Id FROM Task WHERE WhatId =:reloadId];
                 List<Reconciled_Line_Item__c> recList = new List<Reconciled_Line_Item__c>();
                 if (this.LineItemType.Line_Item_Category__r.Reconcile_Type__c == 'Donations Received'){
                     recList = [Select Line_Item_Donation_Made__c FROM Reconciled_Line_Item__c 
                 				WHERE Line_Item_Donation_Received__c =:reloadId ];
                 } else if (this.LineItemType.Line_Item_Category__r.Reconcile_Type__c == 'Donations Made'){
                     recList = [Select Line_Item_Donation_Received__c FROM Reconciled_Line_Item__c 
                 				WHERE Line_Item_Donation_Made__c =:reloadId ];
                 }
                 List<Vouched_Line_Item__c> vouchedLIList = [Select Id FROM Vouched_Line_Item__c 
                                                             WHERE Line_Item__c =:reloadId
                                                             AND Trim_Record__r.Vouching_Type__c != 'Advertising Material'];
                 List<Vouched_Line_Item__c> AdMaterialLIList = [Select Id FROM Vouched_Line_Item__c 
                                                             WHERE Line_Item__c =:reloadId
                                                             AND Trim_Record__r.Vouching_Type__c = 'Advertising Material'];
                 LineItemWrapperList[i].IsNoteExist = (noteList.size() > 0);
                 LineItemWrapperList[i].IsNonComplianceExist = (taskList.size() > 0);
                 LineItemWrapperList[i].IsReconcileExist = (recList.size() > 0);
                 LineItemWrapperList[i].IsVouchingExist = (vouchedLIList.size() > 0);
                 if (AdMaterialLIList.size() > 0) {
                     LineItemWrapperList[i].AdMaterial = 'Advertising Material Provided';
                 } else {
                     if (LineItemWrapperList[i].Item.No_Advertising_Material_Provided__c == true) 
                		LineItemWrapperList[i].AdMaterial = 'No Advertising Material Provided';
                     else 
                        LineItemWrapperList[i].AdMaterial = 'Not Yet Provided';
                 }
                 break;
             }
        }
    }
    private boolean saveAllRecords() {
        /*Savepoint sp = Database.setSavepoint();
        try {
            List<Line_Item__c> upsertList = new List<Line_Item__c>();
            for(LineItemWrapper item : LineItemWrapperList ) {
                if (!item.IsExist) {
                    item.Item = item.Item.Clone(false,true);
                }
                if (item.IsEdit) {
                    upsertList.add(item.Item);
                }
            }
            upsert upsertList;
            for(LineItemWrapper item : LineItemWrapperList ) {
                if (item.IsEdit) {
                    item.IsExist = true;
                    item.IsEdit = false;
                }
            }
        } catch(Exception e){
            Database.rollback(sp);
            ApexPages.addMessages(e);
            return false;
        }*/
        return true;
    }
    /*
    public void btnEdit_Click(){
        //ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.INFO, String.Valueof(LineItemType.Line_Item_Category__r.Add_Row__c)));        
        //Check AddRow checkbox?
        this.IsEdit = true;
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
    }*/
    
    public class LineItemWrapper{
        public integer Id{get;set;}
        public Line_Item__c Item{get;set;}
        public boolean IsNoteExist{get;set;}
        public boolean IsNonComplianceExist{get;set;}
        public boolean IsReconcileExist{get;set;}
        public boolean IsVouchingExist{get;set;}
        public boolean IsExist{get;set;}
        public boolean IsExpand{get;set;}
        public boolean IsLineItem{get;set;}
        public boolean IsEdit{get;set;}
        public boolean IsAddFromExistALI{get;set;}
        public String AdMaterial{get;set;}
        /*public LineItemWrapper(integer idCounter, Line_Item__c li, boolean IsLineItem, boolean IsNoteExist) {
            this(idCounter,li,IsLineItem,IsNoteExist,false, false,true,false);
        }
        public LineItemWrapper(integer idCounter, Line_Item__c li, boolean IsLineItem, boolean IsNoteExist,boolean IsNonComplianceExist) {
            this(idCounter,li,IsLineItem,IsNoteExist,IsNonComplianceExist,false);
        }
        public LineItemWrapper(integer idCounter, Line_Item__c li, boolean IsLineItem, boolean IsNoteExist,boolean IsNonComplianceExist,boolean IsReconcileExist) {
            this(idCounter,li,IsLineItem,IsNoteExist,IsNonComplianceExist,IsReconcileExist,true,false);
        }*/
        public LineItemWrapper(integer idCounter, Line_Item__c li, boolean IsLineItem, boolean IsNoteExist, boolean IsNonComplianceExist, boolean IsReconcileExist, boolean IsExist,boolean IsEdit, boolean IsAddFromExistALI) {
            this(idCounter,li,IsLineItem,IsNoteExist,IsNonComplianceExist,IsReconcileExist,false,'',IsExist,IsEdit, IsAddFromExistALI);
        }
        public LineItemWrapper(integer idCounter, Line_Item__c li, boolean IsLineItem, boolean IsNoteExist, boolean IsNonComplianceExist, boolean IsReconcileExist,boolean IsVouchingExist,String AdMaterial, boolean IsExist,boolean IsEdit, boolean IsAddFromExistALI) {
            this.Id = idCounter;
            this.Item = li;
            this.IsLineItem = IsLineItem;
            this.IsNoteExist = IsNoteExist;
            this.IsExist = IsExist;
            this.IsEdit = IsEdit;
            this.IsExpand = false;
            this.IsNonComplianceExist = IsNonComplianceExist;
            this.IsReconcileExist = IsReconcileExist;
            this.IsVouchingExist = IsVouchingExist;
			this.IsAddFromExistALI = IsAddFromExistALI;
            this.AdMaterial = AdMaterial;
        }
    }
    
    private void CloneRelatedInfo(Line_Item__c lineItem){
        String clonedId = lineItem.Cloned_Line_Item__c;
        Line_Item__c clonedLI = [SELECT id, name FROM Line_Item__c WHERE id =: clonedId LIMIT 1];
        //Clone Non-Compliance
        //ApexPages.AddMessage(new ApexPages.message(ApexPages.Severity.INFO, 'Clone Non-Compliance'));
        String whatId = clonedId.length() < 18 ? (Id)clonedId : clonedId;
        List<Task> allTasks = GetTaskById(whatId);
        List<Task> cloneTasks = new List<Task>();
        for (Task item : allTasks) {
            Task temp = item.clone(false,true);
            //ApexPages.AddMessage(new ApexPages.message(ApexPages.Severity.INFO, 'lineItem.Id ' + lineItem.Id));
            String tempWhatID = lineItem.Id;
            //ApexPages.AddMessage(new ApexPages.message(ApexPages.Severity.INFO, 'temp ' + temp.WhatId));
            tempWhatID = (tempWhatID.length() < 18 ? (Id)tempWhatId : tempWhatID);
            //ApexPages.AddMessage(new ApexPages.message(ApexPages.Severity.INFO, 'temp1232 ' + temp.WhatId));
            temp.WhatId = tempWhatID;             
            cloneTasks.add(temp);
        }
        upsert cloneTasks;
        
        //Clone Vouched Line Item
        //ApexPages.AddMessage(new ApexPages.message(ApexPages.Severity.INFO, 'Clone Vouched Line Item'));
        List<Vouched_Line_Item__c> VouchedLineItems = GetVouchedLineItem(clonedId);
        //ApexPages.AddMessage(new ApexPages.message(ApexPages.Severity.INFO, 'Clone Vouched Line Item 1'));
        List<Vouched_Line_Item__c> cloneVouchedLineItems = new List<Vouched_Line_Item__c>();
        for (Vouched_Line_Item__c item : VouchedLineItems) {
            Vouched_Line_Item__c rec = item.clone(false,true);
            rec.Cloned_Vouched_Line_Item__c  = item.Id;
            rec.Line_Item__c = lineItem.Id;
            cloneVouchedLineItems.add(rec);
        }
        upsert cloneVouchedLineItems;
        
        //Clone Reconciled Line Item
        //ApexPages.AddMessage(new ApexPages.message(ApexPages.Severity.INFO, 'Clone Reconciled Line Item'));
        List<Reconciled_Line_Item__c> lstRLI = new List<Reconciled_Line_Item__c>();
        for (Reconciled_Line_Item__c rli : GetReconciledLineItemsByLineItemIds(clonedId)) {
            Reconciled_Line_Item__c newRLI = rli.clone(false,true);
            if(newRLI.Line_Item_Donation_Received__c == clonedId){
            	newRLI.Line_Item_Donation_Received__c = lineItem.Id;
            }
            if(newRLI.Line_Item_Donation_Made__c == clonedId){
            	newRLI.Line_Item_Donation_Made__c = lineItem.Id;
            }
            newRLI.Cloned_Reconciled_Line_Item__c = rli.Id;
            lstRLI.add(newRLI);
        }
        insert lstRLI;
    }
    private string getAllFields(string sObjectName){
        String objectName = sObjectName;
        String query = 'SELECT';
        Map<String, Schema.SObjectField> objectFields = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();         
        
        for(String s : objectFields.keySet()) {
            if (objectFields.get(s).getDescribe().isAccessible())
           query += ' ' + s + ', ';
        }
        query = query.subString(0,query.Length()-2);
        return query;
    }
    private List<Task> GetTaskById(String LiId){
        String objectName = 'Task';
        String query = getAllFields(objectName);
        query += ' FROM ' + objectName;
        query += ' WHERE RecordType.Name =\'Non-Compliance\' AND WhatId = \'' + LiId +'\'';
        try {
            //ApexPages.AddMessage(new ApexPages.message(ApexPages.Severity.INFO, 'Query '+ query));
            return database.query(query);
        } catch (QueryException e){
            return null;
        }
    }
    private List<Vouched_Line_Item__c> GetVouchedLineItem(String LiId){
        String objectName = 'Vouched_Line_Item__c';
        String query = getAllFields(objectName);
        query += ' FROM ' + objectName;
        query += ' WHERE Trim_Record__r.fuseit_s2t__Trim_Status__c=\'Synchronized\' ' +
            	' AND Trim_Record__r.Vouching_Item__c=true AND Line_Item__c = \'' + LiId+'\'';
        try {
            //System.debug('Exception: GetVouchedLineItem: ' + query);
            return database.query(query);
        } catch (QueryException e){
            return null;
        }
    }
    private List<Reconciled_Line_Item__c> GetReconciledLineItemsByLineItemIds(String LiId){
        String objectName = 'Reconciled_Line_Item__c';
        String query = getAllFields(objectName);
        // Add FROM statement
        query += ' FROM ' + objectName;
        query += ' WHERE Line_Item_Donation_Received__c = \'' + LiId+'\'';
        query = query + ' OR Line_Item_Donation_Made__c = \'' + LiId+'\'';
        try {
            //System.debug('Exception: GetReconciledLineItemsByLineItemIds: ' + query);
            return database.query(query);
        } catch (QueryException e){
            return null;
        }
    }
}