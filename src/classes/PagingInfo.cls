/* This is used for paging
*/
public class PagingInfo{
    public string ListName { get; set; }
    public string Query { get; set; }
    public string CountQuery { get; set; }
    private integer fPageSize;
    public integer TotalCount { get; set; }
    public integer PageIndex { get; set; }
    public integer PageCount { get{
        return integer.ValueOf(((decimal)this.TotalCount).Divide((decimal)this.PageSize, 0, System.RoundingMode.UP));
    }}
    public integer CurrentPageSize{ get; set; }
    public integer PageSize { get{
        if(fPageSize != null && fPageSize > 0){ 
            return fPageSize;
        }
        fPageSize = 10;
        return fPageSize;
    }set{fPageSize = value;}}
    public boolean HasPrevious { get{ 
        return ((PageIndex-1) > 0); 
    }}
    public boolean HasNext { get{ 
        return (PageIndex * PageSize) < TotalCount; 
    }}
    public string OrderBy{get;set;}
    public string OrderDirection{get;set;}
    
    
    public PagingInfo(){}
    public PagingInfo(string listName, string query, string countQuery){
        this(listName,query,countQuery,'','');
    }
    public PagingInfo(string listName, string query, string countQuery, string OrderBy, string OrderDirection){
        this.ListName = listName;
        this.Query = query;
        this.CountQuery = countQuery;
        this.OrderBy = OrderBy;
        this.OrderDirection = OrderDirection;
        this.TotalCount = 0;
    }
    
    
    public PagingInfo OrderBy(string column, string direction){
        this.OrderBy = column;
        this.OrderDirection = direction;
        return this;
    }
    
    public List<sObject> GetRecords(){
        
        this.PageIndex = 1;
		string pageIndexParam = ApexPages.CurrentPage().GetParameters().Get(this.ListName + '.PageIndex');
        integer pageIndex = string.IsNotEmpty(pageIndexParam) ? integer.ValueOf(pageIndexParam) : this.PageIndex;        
        this.PageIndex = pageIndex;
        integer skip = (this.PageIndex - 1) * this.PageSize;
        integer take = this.PageSize;
        String tempQuery = this.Query;
        if (string.isNotEmpty(orderby)) {
            tempQuery += ' ORDER BY ' + orderby + ' ' + OrderDirection + ' NULLS LAST';
        } 
        tempQuery += ' LIMIT '+take+' OFFSET '+skip+'';
        //ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.Info, tempQuery));
        //ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.Info, CountQuery));
        List<sObject> temp = Database.Query(tempQuery);
        
        this.TotalCount = Database.CountQuery(this.CountQuery);
        this.CurrentPageSize = temp.Size();
        
        return temp;
    }
    
    //the below region are for linq-inspired chained methods
    
    public string soqlSelect{get;set;}
    public string soqlFrom{get;set;}
    public string soqlWhere{get;set;}
    public string soqlOrder{get;set;}
    
    public PagingInfo(string listName){
    	this.ListName = listName;
    	this.soqlSelect = '';
    	this.soqlFrom = '';
    	this.soqlWhere = '';
    	this.soqlOrder = '';
    }
    public PagingInfo QSelect(List<string> val){
    	this.soqlSelect = string.Join(val, ',');
        return this;
    }
    public PagingInfo QFrom(string val){
        this.soqlFrom = val;
        return this;
    }
    public PagingInfo QWhere(string val){
        this.soqlWhere = val;
        return this;
    }
    public PagingInfo QOrderByAsc(string column){
        return this.QOrderBy(column, 'ASC', false);
    }
    public PagingInfo QOrderByAsc(string column, boolean reset){
        return this.QOrderBy(column, 'ASC', true);
    }
    public PagingInfo QOrderByDesc(string column){
        return this.QOrderBy(column, 'DESC', false);
    }
    public PagingInfo QOrderByDesc(string column, boolean reset){
        return this.QOrderBy(column, 'DESC', true);
    }
    public PagingInfo QOrderBy(string column, string direction, boolean reset){
		if(reset == true){
			this.soqlOrder = '';
		}
        this.OrderBy = column;
        this.OrderDirection = direction;
		if(string.IsNotEmpty(this.soqlOrder)){
			this.soqlOrder += ',' + column + ' ' + direction;
        } else {
            this.soqlOrder = column + ' ' + direction;
        }
        return this;
    }
        
    public List<SObject> ToList(){
        this.PageIndex = 1;
		string pageIndexParam = ApexPages.CurrentPage().GetParameters().Get(this.ListName + '.PageIndex');
        integer pageIndex = string.IsNotEmpty(pageIndexParam) ? integer.ValueOf(pageIndexParam) : this.PageIndex;        
        this.PageIndex = pageIndex;
        integer skip = (this.PageIndex - 1) * this.PageSize;
        integer take = this.PageSize;
        
        this.Query = '';
        this.CountQuery = 'SELECT COUNT() ';
        
        if (string.isNotEmpty(this.soqlSelect)) {
            this.Query += ' SELECT ' + this.soqlSelect;
        }
        if (string.isNotEmpty(this.soqlFrom)) {
            this.Query += ' FROM ' + this.soqlFrom;
            this.CountQuery += ' FROM ' + this.soqlFrom;
        }
        if (string.isNotEmpty(this.soqlWhere)) {
            this.Query += ' WHERE ' + this.soqlWhere;
            this.CountQuery += ' WHERE ' + this.soqlWhere;
        }
        if (string.isNotEmpty(this.soqlOrder)) {
            this.Query += ' ORDER BY ' + this.soqlOrder;
        }
        this.Query += ' LIMIT '+take+' OFFSET '+skip+'';
        //ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.Info,Query));
        System.Debug('#Final query#' +Query);
        try{
            List<sObject> temp = Database.Query(this.Query);
            
            this.TotalCount = Database.CountQuery(this.CountQuery);
            System.Debug('#Query Total Count#' + this.TotalCount);
            
            this.CurrentPageSize = temp.Size();
            System.Debug('#Query Current Page Records#' + this.CurrentPageSize);
                
            return temp;
        }
        catch(Exception ex){
            ApexPages.addMessages(ex);
            return null;
        }
    }
}