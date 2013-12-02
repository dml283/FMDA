/* Get ('Donation Received'/'Donation Made') Line Item information according to Reconcile Status
*/
public class PopupReconciledLineItemInfoController{
	public Line_Item__c Entity{get;set;}
    public List<Line_Item__c> ListLI{get;set;}    
    public PopupReconciledLineItemInfoController(ApexPages.StandardController sc){
        try{
            this.Entity = (Line_Item__c)sc.GetRecord();            
            this.Entity = [SELECT Id, Line_Item_Type__r.Line_Item_Category__r.Reference_Number__c, 
                           Line_Item_Type__r.Line_Item_Category__r.Reconcile_Type__c 
                           FROM Line_Item__c WHERE Id=:this.Entity.Id LIMIT 1];
            
            List<string> fieldPaths = new List<string>();
            for(Schema.FieldSetMember f :Schema.SObjectType.Line_Item__c.fieldSets.getMap().Get('X' + this.Entity.Line_Item_Type__r.Line_Item_Category__r.Reference_Number__c).Fields){
                fieldPaths.Add(f.FieldPath);
            }
            //ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'a ' + String.valueof(this.Entity.Line_Item_Type__r.Line_Item_Category__r.Reconcile_Type__c)));
            if(this.Entity.Line_Item_Type__r.Line_Item_Category__r.Reconcile_Type__c == 'Donations Received'){
                //ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.INFO, this.Entity.Line_Item_Type__r.Line_Item_Category__r.Reconcile_Type__c));
                Set<string> listRLItem = new Map<string, AggregateResult>([SELECT Line_Item_Donation_Made__c Id
                           FROM Reconciled_Line_Item__c
                           WHERE Line_Item_Donation_Received__c =: this.Entity.Id AND Line_Item_Donation_Made__c != NULL
                           GROUP BY Line_Item_Donation_Made__c]).KeySet();
                //ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'SELECT Id, Name, 1'));
                String whereQuery = 'WHERE Id IN (\''+ String.Join(new List<string>(listRLItem),'\',\'')+'\')';
                
                //ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'SELECT Id, Name, ' + whereQuery));
                //ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'SELECT Id, Name, ' + string.Join(fieldPaths, ',') + ' FROM Line_Item__c WHERE Id IN ' + whereQuery));
                this.ListLI = Database.Query('SELECT Id, Name, ' + string.Join(fieldPaths, ',') + ' FROM Line_Item__c ' + whereQuery);                
                //ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'SELECT Id, Name, ' + string.Join(fieldPaths, ',') + ' FROM Line_Item__c WHERE Id IN ' + mapId.Keyset()));
            } else if(this.Entity.Line_Item_Type__r.Line_Item_Category__r.Reconcile_Type__c == 'Donations Made'){
                Set<string> listRLItem = new Map<string, AggregateResult>([SELECT Line_Item_Donation_Received__c Id
                           FROM Reconciled_Line_Item__c
                           WHERE Line_Item_Donation_Made__c =: this.Entity.Id AND Line_Item_Donation_Received__c != NULL
                           GROUP BY Line_Item_Donation_Received__c]).KeySet();
                
                String whereQuery = 'WHERE Id IN (\''+ String.Join(new List<String>(listRLItem),'\',\'')+'\')';
                //ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'SELECT Id, Name, ' + string.Join(fieldPaths, ',') + ' FROM Line_Item__c WHERE Id IN ' + whereQuery));                
                this.ListLI = Database.Query('SELECT Id, Name, ' + string.Join(fieldPaths, ',') + ' FROM Line_Item__c ' + whereQuery);
                //ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.INFO, String.valueof(this.ListLI.size())));
            } else {
                this.ListLI = new List<Line_Item__c>();
            }               
            //ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.INFO, String.valueof(this.ListLI.size())));
        }
        catch(Exception ex){
            //ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'SELECT Id, Nam'));
            ApexPages.AddMessages(ex);
        }
    }
}