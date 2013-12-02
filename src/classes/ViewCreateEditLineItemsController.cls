/* This is replaced by LineItemForm
*/
public class ViewCreateEditLineItemsController{
    public Disclosure_Claim_for_Payment__c Entity{get;set;}
    public integer recordCounter{get;set;}
    public List<Line_Item_Type__c> ListTabs{get;set;}
    public Map<string, List<LineItemWrapper>> MapTabLineItems{get;set;}
    public transient Map<string, Schema.FieldSet> MapLineItemFieldSets;
    public Map<String, Static_Label__c> Labels{get;set;}
    public boolean IsInline{get{ return ApexPages.CurrentPage().GetParameters().Get('inline') == '1'; }}
    public boolean IsEdit{get;set;}
    public String EdittingLineItemTypeId{get;set;}
    public boolean hasRecordOnLineItemType{get;set;}
    public ApexPages.StandardController SController{get;set;}
    
    public Map<string, Schema.FieldSet> GetMapLineItemFieldSets(){
        return Schema.SObjectType.Line_Item__c.fieldSets.getMap();
    }
    
    public ViewCreateEditLineItemsController(ApexPages.StandardController sc){
        try{
            this.Entity = (Disclosure_Claim_for_Payment__c)sc.GetRecord();
            this.Entity = this.GetEntityById(this.Entity.Id, ApexPages.CurrentPage().GetParameters().Get('RecordType'));
            
            this.Labels = Static_Label__c.GetAll();
            this.IsEdit = !this.IsInline;
            this.SController = sc;
            
            this.EdittingLineItemTypeId = null;
            
            this.Reload(true);
            
            if(this.Entity.IsTemplate__c == true){
                for(Line_Item_Type__c item :this.ListTabs){
                    List<LineItemWrapper> temp = this.MapTabLineItems.Get(item.Line_Item_Category__r.Reference_Number__c);
                    if(temp != null && temp.IsEmpty()){
                        for(integer i=0; i<item.Line_Item_Category__r.Default_Number_of_Rows__c; i++){
                            temp.Add(new LineItemWrapper(this.RecordCounter++, new Line_Item__c(), false, true));
                        }
                    }
                }
            }
        }
        catch(Exception ex){
            ApexPages.AddMessages(ex);
        }
    }
    
    public Disclosure_Claim_for_Payment__c GetEntityById(string id, string recordTypeId){
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
    
    private List<Line_Item_Type__c> GetLineItemTypesByEntityId(string id){
        return [
            SELECT Id, Name, Line_Item_Category__r.Line_Item_Category__c, Line_Item_Category__r.Reference_Number__c
            	, Nil_Disclosure_Claim_for_Payment__c,Line_Item_Category__r.Add_Row__c
            	,Calculated_Amount__c,Form_Amount__c,Calculated_Count__c,Form_Count__c
            	,Line_Item_Category__r.Calculated_Total_Amount__c,Line_Item_Category__r.Form_Total_Amount__c
            	,Line_Item_Category__r.Calculated_Total_Count__c,Line_Item_Category__r.Form_Total_Count__c
            	,Line_Item_Category__r.Remove_Row__c,Line_Item_Category__r.Default_Number_of_Rows__c
            FROM Line_Item_Type__c
            WHERE Disclosure_Claim_for_Payment__c = :id
            ORDER BY Order_Number__c//Line_Item_Category__r.Order_Number__c
        ];
    }
    
    private List<Line_Item__c> GetLineItemsByLineItemTypeIds(set<Id> litIds){
        String query = LineItemAllFields();
        query += ' FROM Line_Item__c WHERE Line_Item_Type__c IN :litIds ORDER BY CreatedDate' ;
        return Database.query(query);
    }
    
    private Map<string, List<LineItemWrapper>> GroupLineItemByLineItemType(set<string> litNos, List<Line_Item__c> lineItems, boolean isTemplate){
        Map<string, List<LineItemWrapper>> temp = new Map<string, List<LineItemWrapper>>();
        for(string litNo :litNos){
            if(!temp.ContainsKey(litNo)){
                temp.Put(litNo, new List<LineItemWrapper>());
            }
        }
        for(Line_Item__c item: lineItems){
            LineItemWrapper t = new LineItemWrapper(recordCounter++, item, isTemplate != true, false);
            temp.Get(item.Line_Item_Type__r.Line_Item_Category__r.Reference_Number__c).Add(t);
        }
        return temp;
    }
    
    public void btnEditRow_Click(){
        integer lineitemid = integer.ValueOf(ApexPages.CurrentPage().GetParameters().Get('lineitemid'));
        string lineitemtypeno = ApexPages.CurrentPage().GetParameters().Get('lineitemtypeno');
        List<LineItemWrapper> temp = MapTabLineItems.Get(lineitemtypeno);
            
        for(integer i = 0; i < temp.Size(); i++){
            if(temp[i].Id == lineitemid){
                temp[i].IsEdit = true;
                break;
            }
        }
    }
    
    public void btnAddRow_Click(){
        try{
            string lineitemtypeno = ApexPages.CurrentPage().GetParameters().Get('lineitemtypeno');
            
            this.MapTabLineItems.Get(lineitemtypeno).Add(new LineItemWrapper(this.RecordCounter++, new Line_Item__c(), false, true));
        }
        catch(Exception ex){
            ApexPages.AddMessages(ex);
        }
    }
    
    public void btnDelRow_Click(){
        try{
            integer lineitemid = integer.ValueOf(ApexPages.CurrentPage().GetParameters().Get('lineitemid'));
            string lineitemtypeno = ApexPages.CurrentPage().GetParameters().Get('lineitemtypeno');
            
            List<LineItemWrapper> temp = MapTabLineItems.Get(lineitemtypeno);
            
            for(integer i = 0; i < temp.Size(); i++){
                if(temp[i].Id == lineitemid){
                    if (this.Entity.IsTemplate__c == true) {
                        temp.Remove(i);
                        break;
                    }
                    if (temp[i].IsExist) {
                        delete temp[i].Item;
                        this.Reload(false);
                    }
                   	temp.Remove(i);
                    break;
                }
            }
            hasRecordOnLineItemType = temp.size() > 0;
        }
        catch(Exception ex){
            ApexPages.AddMessages(ex);
        }
    }
    
	public void btnSaveRow_Click(){
        Savepoint sp = Database.setSavepoint();
		try{
            integer lineitemid = integer.ValueOf(ApexPages.CurrentPage().GetParameters().Get('lineitemid'));
            string lineitemtypeno = ApexPages.CurrentPage().GetParameters().Get('lineitemtypeno');
            string lineitemtypeid = ApexPages.CurrentPage().GetParameters().Get('lineitemtypeid');
            
            List<LineItemWrapper> temp = MapTabLineItems.Get(lineitemtypeno);
            
            for(integer i = 0; i < temp.Size(); i++){
                if(temp[i].Id == lineitemid){
                    if(!temp[i].IsExist){
                    	temp[i].Item = temp[i].Item.Clone(false,false);
						temp[i].Item.Line_Item_Type__c = lineitemtypeid;
                    }
                    upsert temp[i].Item;
					// If Line Item Type Reference number is 1001 or 1005, create new Disclosure Obligation
					if ((lineitemtypeno.equals('1001') || lineitemtypeno.equals('1005')) && temp[i].Item.Stakeholder__c!=null) {
						Integer count = [SELECT COUNT()
										 FROM Disclosure_Obligation__c
										 WHERE Reporting_Period__c = :Entity.Disclosure_Obligation__r.Reporting_Period__c
										 AND Stakeholder__c=:temp[i].Item.Stakeholder__c];
						if (count == 0) {
							Disclosure_Obligation__c disclosure_ob = new Disclosure_Obligation__c();
							disclosure_ob.Reporting_Period__c = Entity.Disclosure_Obligation__r.Reporting_Period__c;
							disclosure_ob.Stakeholder__c = temp[i].Item.Stakeholder__c;
							upsert disclosure_ob;
						}
					}
					// End adding new Disclosure Obligation
                    this.Reload(false);
                    
                    String query = LineItemAllFields();
                    query += ' FROM Line_Item__c WHERE Id = \'' + temp[i].Item.Id + '\' LIMIT 1';
                    List<Line_Item__c> liList = Database.query(query);
                    if (liList.size() > 0) {
                        temp[i].Item = liList.get(0);
                    }
                    
					temp[i].IsExist = true;
					temp[i].IsEdit 	= false;
                    break;
                }
            }
            hasRecordOnLineItemType = true;
        }
        catch(Exception ex){
            ApexPages.AddMessages(ex);
            Database.rollback(sp);
        }
	}
    
    public void btnQuickSave_Click(){
        if(this.btnSave_Click()){
            EdittingLineItemTypeId = null;
            this.Reload(true);
        }
    }
    
    public PageReference btnSaveClose_Click(){
        if(this.btnSave_Click()){
            if(this.IsInline == true){
                this.IsEdit = false;
                this.Reload(true);
            }
            else{
                return this.SController.Cancel();
            }
        }   
        return null;
    }
    
    public boolean saveLineItems(Line_Item_Type__c lit) {
		//clone and upsert line item
		// If Line Item Type Reference number is 1001 or 1005, create new Disclosure Obligation for the Line Item
		Set<String> StakeHolderList = new Set<String>();
		
		List<Line_Item__c> lineItemToInsert = new List<Line_Item__c>();

        boolean isBelongToList = false;
        String referenceNumber = lit.Line_Item_Category__r.Reference_Number__c;
        if (referenceNumber.equals('1001') || referenceNumber.equals('1005')) {
            isBelongToList = true;
        }
        for(LineItemWrapper li :this.MapTabLineItems.get(referenceNumber)){
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

		upsert lineItemToInsert;
		List<Disclosure_Obligation__c> existDOList = [
				SELECT Stakeholder__c
				FROM Disclosure_Obligation__c
				WHERE Reporting_Period__c = :Entity.Disclosure_Obligation__r.Reporting_Period__c
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
				disclosure_ob.Reporting_Period__c = Entity.Disclosure_Obligation__r.Reporting_Period__c;
				disclosure_ob.Stakeholder__c = stakeHolderId;
				upsertDOList.add(disclosure_ob);
			}
		}
		
		upsert upsertDOList;
		
		//insert success
        for(LineItemWrapper li :this.MapTabLineItems.get(lit.Line_Item_Category__r.Reference_Number__c)){
            li.IsExist = true;
            li.IsEdit = false;
        }
		return true;
	}
    public boolean btnSave_Click(){
        Savepoint sp = Database.setSavepoint();
        
        try {
            string lineitemtypeid = ApexPages.CurrentPage().GetParameters().Get('lineitemtypeid');
            Line_Item_Type__c tempLIT = new Map<Id,Line_Item_Type__c>(ListTabs).get(lineitemtypeid);
            if (tempLIT != null) {
            	upsert tempLIT;
                if (tempLIT.Nil_Disclosure_Claim_for_Payment__c != true) {
                    if (saveLineItems(tempLIT)) {
                        ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Record saved successfully'));
                    }
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
        string lineitemtypeno = ApexPages.CurrentPage().GetParameters().Get('lineitemtypeno');
        string lineitemtypeid = ApexPages.CurrentPage().GetParameters().Get('lineitemtypeid');
        
        List<LineItemWrapper> temp = MapTabLineItems.Get(lineitemtypeno);
        
        for(integer i = 0; i < temp.Size(); i++){
            if(temp[i].Id == lineitemid){
                if(this.Entity.IsTemplate__c == true){
                    
                }
                else{
                    temp[i].IsEdit = false;
                    if (temp[i].IsExist) {
                        String query = LineItemAllFields();
                        query += ' FROM Line_Item__c WHERE Id = \'' + temp[i].Item.Id + '\' LIMIT 1';
                        List<Line_Item__c> liList = Database.query(query);
                        if (liList.size() > 0) {
                            temp[i].Item = liList.get(0);
                        }
                    } else {
                        temp.remove(i);
                    }
                }
                
                break;
            }
        }
    }
    
    public void btnEdit_Click(){
        this.IsEdit = true;
        EdittingLineItemTypeId = ApexPages.CurrentPage().GetParameters().Get('EdittingLineItemTypeId');
        Reload(true);
        for (Line_Item_Type__c lit : ListTabs) {
            if (lit.Id == EdittingLineItemTypeId) {
                hasRecordOnLineItemType = false;
                for(LineItemWrapper li :this.MapTabLineItems.get(lit.Line_Item_Category__r.Reference_Number__c)){
                    li.IsEdit = true;
                    hasRecordOnLineItemType = true;
                }
                break;
            }
        }
    }
    
    public PageReference btnCancel_Click(){
        if(this.IsInline == true){
            this.IsEdit = false;
            EdittingLineItemTypeId = null;
            this.Reload(true);
            
            return null;
        }
        else{
            return this.SController.Cancel();
        }
    }
    
    public boolean SubmitChanges(){
        return true;
    }
    
    public void Reload(boolean reloadLineItem){
        this.ListTabs = this.GetLineItemTypesByEntityId(this.Entity.Id);
        this.RecordCounter = 0;
        if(reloadLineItem == true){
            set<id> litIds = new Map<Id, sObject>(this.ListTabs).KeySet();
            List<Line_Item__c> lineItems = this.GetLineItemsByLineItemTypeIds(litIds);
            Set<string> litNos = new Set<string>();
            for(Line_Item_Type__c item :this.ListTabs){
                litNos.Add(item.Line_Item_Category__r.Reference_Number__c);
            }
            
            this.MapTabLineItems = this.GroupLineItemByLineItemType(litNos, lineItems, this.Entity.IsTemplate__c);
        }
    }
    
    public class LineItemWrapper{
        public integer Id{get;set;}
        public Line_Item__c Item{get;set;}
        public boolean IsExist{get;set;}
        public boolean IsEdit{get;set;}
        
        public LineItemWrapper(integer idCounter, Line_Item__c li, boolean isExist, boolean isEdit){
            this.Id = idCounter;
            this.Item = li;
            this.IsExist = isExist;
            this.IsEdit = isEdit;
        }
    }
    
    private string LineItemAllFields(){
        Map<String, Schema.SObjectField> fldObjMap = schema.SObjectType.Line_Item__c.fields.getMap();
		List<Schema.SObjectField> fldObjMapValues = fldObjMap.values();
        
        String theQuery = 'SELECT ';
        for(Schema.SObjectField s : fldObjMapValues)
        {
           String theName = s.getDescribe().getName();
           theQuery += theName + ',';
        }
        theQuery += ' Line_Item_Type__r.Line_Item_Category__r.Reference_Number__c, Cloned_Line_Item__r.Name ';
        // Trim last comma
        //theQuery = theQuery.subString(0, theQuery.length() - 1);
        return theQuery;
    }
}