public class ReviewDonationCapController{
    /////////////////////
    //PUBLIC PROPERTIES//
    /////////////////////
    public Map<String, Static_Label__c> Labels{get;set;}
    public Disclosure_Claim_For_Payment__c Entity{get;set;}
    public string SearchKey{get;set;}
    public List<string> FilterKeys{get{return new List<string>{'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','X','Y','Z', 'All'};}}
    public List<string> FilterTypes{get{return new List<string>{'Within Cap','Exceeded Cap'};}}
    public string FilterKey{get;set;}
    public string CapType{get;set;}
    public Map<string, PagingInfo> MapPagingInfo{get;set;}
    public Map<string, string> Params{get{return ApexPages.CurrentPage().GetParameters();}}
    public List<AccWrapper> Results{get;set;}
    public List<SelectOption> ListPageSize{get;set;}
    public Map<string, Schema.FieldSet> GetMapLineItemFieldSets(){
        return Schema.SObjectType.Line_Item__c.fieldSets.getMap();
    }
    public List<string> LineItemFields{get;set;}
    public String recordTypeName{get;set;}
    /////////////////////////////////
    //CONTRUCTOR & RUN ONCE METHODS//
    /////////////////////////////////
    public ReviewDonationCapController(ApexPages.StandardController controller){
        this.Entity = (Disclosure_Claim_For_Payment__c)controller.GetRecord();
        this.Searchkey = '';
        this.FilterKey = 'All';
        this.Results = new List<AccWrapper>();
        this.ListPageSize = this.BuildListPageSize();
        this.MapPagingInfo = new Map<string, PagingInfo>();
        this.Labels = Static_Label__c.GetAll();
        this.LineItemFields = new List<string>();
        String tempRecordName = [Select RecordType.Name from Disclosure_Claim_for_payment__c where id=:Entity.Id][0].RecordType.Name;
        if (tempRecordname.startsWith('Disclosure')) {
            this.RecordTypeName = 'Disclosure Non-Compliance';
        } else {
            this.RecordTypeName = 'Claim for Payment Non-Compliance';
        }
        //get all line item fields
        for(Schema.SObjectField f :schema.SObjectType.Line_Item__c.fields.getMap().values()){
            if (f.GetDescribe().GetName() != 'LastReferencedDate'){
            	this.LineItemFields.Add(f.GetDescribe().GetName());
            }
        }
        this.lnkSearch_OnClick();
    }
    //////////////////
    //EVENT HANDLERS//
    //////////////////
    public void lnkSearch_OnClick(){
        try{
            this.Results = new List<AccWrapper>();
            Set<Id> accIds = new Set<Id>();
            Set<Id> litIds = new Set<Id>();
            List<Account> listAcc =  new List<Account>();
            Map<Id, Line_Item_Type__c> mapLit = new Map<Id, Line_Item_Type__c>();
            Map<Id, Map<Id, decimal>> mapAccLit = new Map<Id, Map<Id, decimal>>();
            List<string> liFields = new List<string>();
            Map<Id, AggregateResult> mapAccTotalDonations = new Map<Id, AggregateResult>();
            //retrieve id group of stakeholders and line item types for line items matching search criteria
            List<AggregateResult> accLitIds = [
                SELECT Stakeholder__c, Line_Item_Type__c, SUM(Amount_Roll_Up__c) Cnt
                FROM Line_Item__c
                WHERE 
                    RecordType.Name = 'Audit Line Item'
                	AND Active__c = true
                    AND Line_Item_Type__r.Disclosure_Claim_For_Payment__c = :this.Entity.Id
                	AND Line_Item_Type__r.Line_Item_Category__r.Aggregated_Category__c = 'Reportable Donations Received'
                    AND Stakeholder__r.Name LIKE :('%'+this.SearchKey+'%') 
                    AND Stakeholder__r.LastName LIKE :(this.FilterKey == 'All' ? '%' : this.FilterKey + '%')
                GROUP BY Stakeholder__c, Line_Item_Type__c
            ];
            for(AggregateResult item :accLitIds){
                if(mapAccLit.ContainsKey((Id)item.Get('Stakeholder__c'))){
                    mapAccLit.Get((Id)item.Get('Stakeholder__c')).Put((Id)item.Get('Line_Item_Type__c'), (decimal)item.Get('Cnt'));
                }
                else{
                    Map<Id, decimal> tempMap = new Map<Id, decimal>();
                    tempMap.Put((Id)item.Get('Line_Item_Type__c'), (decimal)item.Get('Cnt'));
                    mapAccLit.Put((Id)item.Get('Stakeholder__c'), tempMap);
                }
                accIds.Add((Id)item.Get('Stakeholder__c'));
                litIds.Add((Id)item.Get('Line_Item_Type__c'));
            }
            //get line item types
            mapLit = new Map<Id, Line_Item_Type__c>([
                SELECT Id, Name, Line_Item_Category__r.Line_Item_Category__c, Line_Item_Category__r.Description__c, Line_Item_Category__r.Reference_Number__c,Nil_Disclosure_Claim_For_Payment__c
                , Calculated_Count__c, Calculated_Amount__c 
                FROM Line_Item_Type__c
                WHERE Id IN :litIds
            ]);
            //get stakeholders
            listAcc = [
                SELECT Id, Name
                FROM Account
                WHERE Id IN :accIds
                ORDER BY Name
            ];
            //retrieve the total donations for each stakeholder
            /*
            mapAccTotalDonations = new Map<Id,AggregateResult>([
                SELECT Stakeholder__c Id, SUM(Amount_Roll_Up__c) Cnt
                FROM Line_Item__c
                WHERE RecordType.Name = 'Line Item'
                	AND Line_Item_Type__r.Line_Item_Category__r.Aggregated_Category__c = 'Reportable Donations Received'
                    AND Line_Item_Type__r.Disclosure_Claim_For_Payment__c = :this.Entity.Id
                    AND Stakeholder__c IN :accIds
                GROUP BY Stakeholder__c
            ]); 
*/
            //build result blocks
            for(Account acc :listAcc){
                AccWrapper tempAcc = new accWrapper();
                tempAcc.Item = acc;
                tempAcc.LineItemTypes =  new List<LitWrapper>();
                tempAcc.TotalDonations = 0;//(decimal)mapAccTotalDonations.Get(acc.Id).Get('Cnt');
                tempAcc.Amount = this.Entity.Disclosure_Obligation__r.Donations_Received_Cap__r.Amount__c == null ? 0 : this.Entity.Disclosure_Obligation__r.Donations_Received_Cap__r.Amount__c;
                
                for(Id litId :mapAccLit.Get(acc.Id).KeySet()){
                    LitWrapper tempLit = new LitWrapper();
                    tempLit.Item = mapLit.Get(litId);                
                    tempLit.StakeholderId = acc.Id;
                    tempLit.LineItemFields = this.LineItemFields;
                    tempLit.CalculatedAmount = mapAccLit.Get(acc.Id).Get(litId);
                    tempLit.QueryLineItems();
                    tempAcc.LineItemTypes.Add(tempLit);
                    tempAcc.TotalDonations += tempLit.CalculatedAmount;
                }
                tempAcc.LineItemTypes.Sort();
                this.Results.Add(tempAcc);
            }
        }
        catch(Exception ex){
            ApexPages.AddMessages(ex);
        }
    }
    
    public void lnkCapType_OnClick(){
        //Don't need to do anything
    }
    
    public void ReloadLitTable(){
        string stakeholderId = this.Params.Get('stakeholderId'); 
        string lineItemTypeId = this.Params.Get('lineItemTypeId');  
        for(AccWrapper acc: this.Results){
            if(acc.Item.Id == stakeholderId){
                for(LitWrapper liType: acc.LineItemTypes){
                    if(liType.Item.Id == lineItemTypeId){
                        liType.QueryLineItems();
                    }
                }
            }
        }
    }
    //////////////////
    //HELPER METHODS//
    //////////////////
    
    public List<SelectOption> BuildListPageSize() {
        List<SelectOption> numberItemPerPageOptions = new List<SelectOption>();
        numberItemPerPageOptions.add(new SelectOption('1', '1'));
        numberItemPerPageOptions.add(new SelectOption('5', '5'));
        numberItemPerPageOptions.add(new SelectOption('10', '10'));
        numberItemPerPageOptions.add(new SelectOption('20', '20'));
        numberItemPerPageOptions.add(new SelectOption('50', '50'));
        numberItemPerPageOptions.add(new SelectOption('100', '100'));
        return numberItemPerPageOptions;
    }
    ///////////////////
    //WRAPPER CLASSES//
    ///////////////////
    public class AccWrapper{
        public Account Item{get;set;}
        public decimal Amount{get;set;}
        public decimal TotalDonations{get;set;}
        public decimal Difference{get{return this.TotalDonations - this.Amount;}}
        //DE4597
        public string CapType{get{return Difference <= 0 ? 'Within Cap' : 'Exceeded Cap';}}
        //public string CapType{get{return Difference < 0 ? 'Within Cap' : 'Exceeded Cap';}}
        public List<LitWrapper> LineItemTypes{get;set;}        
    }
    
    public class LitWrapper implements Comparable{
        public Line_Item_Type__c Item{get;set;}
        public id StakeholderId {get;set;}
        public boolean IsEdit{get;set;}
        public List<LiWrapper> LineItems{get;set;}
        public PagingInfo LiPagingInfo{get;set;}
        public decimal CalculatedAmount{get;set;}
        
        public List<string> LineItemFields{get;set;}
        /*// For DE4551
        public String Calculated_Count {get;set;}
        public String Calculated_Amount {get;set;}*/
        // End For DE4551
        public void QueryLineItems(){
			LineItems = new List<LiWrapper>();
            if(this.LiPagingInfo == null){
                this.LiPagingInfo = new PagingInfo(this.StakeholderId + '-' + this.Item.Id)
                    .QSelect(this.LineItemFields)
                    .QFrom('Line_Item__c')
                    .QWhere(string.Format('RecordType.Name = \'\'Audit Line Item\'\' AND Active__c = true AND Stakeholder__c = \'\'{0}\'\' AND Line_Item_Type__c = \'\'{1}\'\'', new string[]{StakeholderId, this.Item.Id}));
            	
            }
            for(SObject li :this.LiPagingInfo.ToList()){
                Liwrapper tempLi = new LiWrapper();
                tempLi.Item = (Line_Item__c)li;
                 
                LineItems.Add(tempLi);
            }
        }
        public void Sort(){
            string orderBy = ApexPages.CurrentPage().GetParameters().Get('sortByColumn');
            string orderDirection = ApexPages.CurrentPage().GetParameters().Get('sortDirection');
            this.LiPagingInfo.QOrderBy(orderBy, orderDirection, true);
            this.QueryLineItems();
        }
        
        public Integer compareTo(Object compareTo) {
            return this.Item.Line_Item_Category__r.Reference_Number__c >= ((LitWrapper)compareTo).Item.Line_Item_Category__r.Reference_Number__c ? 1 : -1;
        }
    }
    
    public class LiWrapper{
        public Line_Item__c Item{get;set;}
        public boolean IsNoteExist{get;set;}
    }
}