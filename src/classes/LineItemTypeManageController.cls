public class LineItemTypeManageController{
    public Disclosure_Claim_For_Payment__c Entity{get;set;}
    public List<SelectOptionWrap> SelectOptionList{get;set;}
    
    public LineItemTypeManageController(ApexPages.StandardController controller) {
        this.Entity = (Disclosure_Claim_For_Payment__c)controller.GetRecord();
        this.Entity = getEntityById(this.Entity.Id);
		SelectOptionList = new List<SelectOptionWrap>();
		
        List<Line_Item_Type__c> litList = [SELECT Id, Name, Line_Item_Category__r.Line_Item_Category__c,
        									Calculated_Audit_Count__c, Calculated_Count__c
                                           FROM Line_Item_Type__c 
                                           WHERE Disclosure_Claim_for_Payment__c =:this.Entity.Id
                                           AND Line_Item_Category__c != null 
                                           ORDER BY Order_Number__c
                                           ];
		
		Set<String> litIds = new Set<String>();
		for (Line_Item_Type__c lit : litList) {
			litIds.add(lit.Id);
		}
		
		Map<Id, AggregateResult> litLiCount = new Map<Id, AggregateResult>(
            				[SELECT Line_Item_Type__c Id, COUNT(Id) Cnt FROM Line_Item__c 
                             WHERE Line_Item_Type__c IN :litIds 
                             AND RecordType.Name = 'Line Item'
                             GROUP BY Line_Item_Type__c]);
                             
        for (Line_Item_Type__c lit : litList) {
            String typeStr = lit.Line_Item_Category__r.Line_Item_Category__c;
            String typeId  = lit.Id;
            String color = '';
            
            if(typeStr == 'Small Political Donations Received General (Not received at a Fundraising Function or Venture)'
              || typeStr == 'Electoral Expenditure Other'
              || typeStr == 'Small Political Donations Made'){
            	if(lit.Calculated_Count__c > 0){
                    color = 'color:green';
                }else{
                    color = 'color:red';
                } 
            } else{
                if (litLiCount.containsKey(lit.Id)){
                    color = 'color:green';
                }else{
                    color = 'color:red';
                } 
            }
            SelectOptionList.add(new SelectOptionWrap(typeId, typeStr,color));
        }
    }
    
    private Disclosure_Claim_For_Payment__c getEntityById(String id) {
    	return [SELECT Id,Name from Disclosure_Claim_For_Payment__c where Id=:id];
    }
    
    public class SelectOptionWrap {
    	public String Id{get;set;}
    	public String Text{get;set;}
    	public String color{get;set;}
    	public SelectOptionWrap(String Id, String Text, String color) {
    		this.Id = Id;
    		this.Text = Text;
    		this.color = color;
    	}
    
    }
}