/* Used for viewing information of Line Item object with fields in its fieldset.
*/
public class ViewLineItemController{
    public Line_Item__c Entity{get;set;}
    public ViewLineItemController(ApexPages.StandardController sc){
        try{
            this.Entity = (Line_Item__c)sc.GetRecord();
            this.Entity = [SELECT Id, Line_Item_Type__r.Line_Item_Category__r.Reference_Number__c FROM Line_Item__c WHERE Id=:this.Entity.Id LIMIT 1];
            
            List<string> fieldPaths = new List<string>();
            for(Schema.FieldSetMember f :Schema.SObjectType.Line_Item__c.fieldSets.getMap().Get('X' + this.Entity.Line_Item_Type__r.Line_Item_Category__r.Reference_Number__c).Fields){
                fieldPaths.Add(f.FieldPath);
            }
            
            this.Entity = Database.Query('SELECT Id, Name, ' + string.Join(fieldPaths, ',') + ' FROM Line_Item__c WHERE Id = \'' + this.Entity.Id + '\' LIMIT 1');
        }
        catch(Exception ex){
            ApexPages.AddMessages(ex);
        }
    }
}