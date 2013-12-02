/* Showing a list of records from the Non_Compliance_Issue__c object for lookup.
*/
public class NonComplianceSearchController{
    public boolean IsPostBack{get;set;}
    public PagingInfo ItemPagingInfo{get;set;}
    public String Keyword{get;set;}
    public List<Non_Compliance__c> Items{get;set;}
    public boolean NoMatches{get{ return this.Items.IsEmpty(); }}
    public List<SelectOption> numberItemPerPageOptions{get;set;}
    public String StartUpScript{get;set;}
    private String recordTypeName;
    private String itemIdParam;
    public transient Map<string, Schema.FieldSet> AllComFieldSet;
    public Map<string, Schema.FieldSet> GetAllComFieldSet(){
        return Schema.SObjectType.Non_Compliance__c.fieldSets.getMap();
    } 
    public string LineItemType{get;set;}
    
    public NonComplianceSearchController() {
        try {
            if(this.IsPostBack == null){
                this.Keyword = ApexPages.CurrentPage().GetParameters().Get('keyword');
                this.Keyword = (this.Keyword == null ? '':this.Keyword);
                this.recordTypeName = ApexPages.CurrentPage().GetParameters().Get('recordTypeName');
                //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,String.valueOf(recordTypeName=='undefined')));
                this.itemIdParam = ApexPages.CurrentPage().GetParameters().Get('itemIdParam');
                this.LineItemType = '';
                String litId = ApexPages.CurrentPage().GetParameters().Get('litId');
                if(litId != null && litId != 'undefined'){
                    this.LineItemType = [Select Line_Item_Type_Aggregated_Category__c from Line_Item_Type__c 
                                    Where Id=:litId Limit 1].get(0).Line_Item_Type_Aggregated_Category__c;
                }
        		this.Items = new List<Non_Compliance__c>();
                this.StartUpScript = '';
                numberItemPerPageOptions = new List<SelectOption>();
                numberItemPerPageOptions.add(new SelectOption('5', '5'));
                numberItemPerPageOptions.add(new SelectOption('10', '10'));
                numberItemPerPageOptions.add(new SelectOption('20', '20'));
                numberItemPerPageOptions.add(new SelectOption('50', '50'));
                numberItemPerPageOptions.add(new SelectOption('100', '100'));
                
                buildItems();
                this.IsPostBack = false;
            }
        } catch (Exception e) {
            ApexPages.addMessages(e);
        }
    }
    public void buildItems () {
        try {
        	Items = GetListItem();
        } catch (Exception e) {
            ApexPages.addMessages(e);
        }
    }
    
    private List<Non_Compliance__c> GetListItem () {
        if(this.ItemPagingInfo == null){
            this.ItemPagingInfo = 
                new PagingInfo('ItemPagingInfo')
                .QFrom('Non_Compliance__c')
                .QOrderByAsc('Name');
            
        	this.ItemPagingInfo.soqlSelect = CompSelectField();
        }
        
        // Build Filter
        String tempKey = String.escapeSingleQuotes(Keyword);
        this.ItemPagingInfo.soqlWhere = CompWhereField(tempKey);
        return this.ItemPagingInfo.ToList();
    }
    
    public void Sort(){
        /*if(ApexPages.CurrentPage().GetParameters().Get('orderDirection') == 'ASC'){
            this.ItemPagingInfo.QOrderByAsc(ApexPages.CurrentPage().GetParameters().Get('orderBy'),true);
        }
        else{
            this.ItemPagingInfo.QOrderByDesc(ApexPages.CurrentPage().GetParameters().Get('orderBy'),true);
        }*/
        ItemPagingInfo.soqlOrder = ItemPagingInfo.OrderBy + ' ' + ItemPagingInfo.OrderDirection;
        buildItems();
    }
    
    public void PickItem() {
        try {
            String itemId = ApexPages.CurrentPage().GetParameters().Get('itemId');
            for (Non_Compliance__c item : Items) {
                if (item.Id == itemId) {
                    String str = JSON.serialize(item);
                    //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'a '+ str));
                    this.StartupScript = 'top.window.opener.ReloadSection(\'' + itemIdParam + '\',' + str + ');';
                    this.StartupScript += 'top.window.close();';
                    break;
                }
            }
        } catch (Exception e) {
            ApexPages.addMessages(e);
        }
    }
    
    private String CompSelectField () {
        String query = '';
        Schema.FieldSet CompFieldSet = Schema.SObjectType.Non_Compliance__c.fieldSets.Non_Compliance;
        for(Schema.FieldSetMember f : CompFieldSet.getFields()) {
            query += f.getFieldPath() + ', ';
        }
        query += 'Id, Active__c ';
        return query;
    }
    private String CompWhereField (String key) {
        String query = '';
        Schema.FieldSet CompFieldSet = Schema.SObjectType.Non_Compliance__c.fieldSets.Non_Compliance;
        for(Schema.FieldSetMember f : CompFieldSet.getFields()) {
            if (f.getFieldPath() == 'Offender__c' || f.getFieldPath() == 'RecordType.Name'
               || f.getFieldPath() == 'Line_Item_Category__c' || f.getFieldPath() == 'Comments__c'
               || f.getFieldPath() == 'Line_Item_Aggregated_Categories__c') continue;
            query += f.getFieldPath() + ' LIKE \'%' + key + '%\' OR ';
        }
        // Trim last OR
		query = query.subString(0, query.length() - 3);
        query = ' (' + query + ' ) And Active__c=true ';
        //DE4653
        Boolean flag = false;
        String fromPage = ApexPages.CurrentPage().GetParameters().Get('fromPage');
        if(fromPage == 'Expenditure'){
            query += ' And (RecordType.Name =\'Disclosure Non-Compliance\' OR Line_Item_Aggregated_Categories__c  includes (\'Electoral Communication Expenditure\',\'Electoral Expenditure\'))';
            flag = true;
        }else if(fromPage == 'Donation'){
            query += ' And (RecordType.Name =\'Disclosure Non-Compliance\' OR Line_Item_Aggregated_Categories__c  includes (\'Reportable Donations Received\'))';
            flag = true;
        }
        //if(this.recordTypeName == 'Disclosure Non-Compliance' || this.LineItemType == 'Electoral Expenditure' ||
        //  this.LineItemType == 'Electoral Communication Expenditure'){
        //    flag = true;
        //}
        if (this.recordTypeName != null && this.recordTypeName != 'undefined' && !flag) {
            //  Non_Compliance__c.RecordType.Name
            query += ' And RecordType.Name =\'' + String.escapeSingleQuotes(this.recordTypeName) + '\' ';
        }
        if(this.LineItemType != '' && !flag){
        	query += ' AND Line_Item_Aggregated_Categories__c includes (\''+ String.escapeSingleQuotes(this.LineItemType) + '\') ';
        }
        
        //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'query: ' + query));
        return query;
    }
}