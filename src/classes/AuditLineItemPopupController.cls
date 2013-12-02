/* This is a popup that is called from ReconcileLineItems (VF page) via button 'Add Audit Line Item for Selected'
This allows the user to add an Audit Line Item to the 
Disclosure/Claim for Payment record without the need to have an existing Line Item.
*/
public class AuditLineItemPopupController{
	public boolean IsPostBack{get;set;}
    public Line_Item_Type__c LineItemType{get;set;}
    public Line_Item__c record{get;set;}
    public String StartUpScript{get;set;}
    public boolean ShowForm{get;set;}
    public string ReconcileType{get;set;}
    public string disclosureId{get;set;}
    Public String stakeholderRegId{get;set;}
    Public String candidateReportId{get;set;}
    Public Boolean isSameReportId{get;set;}
    Public Map<String,String> mapLineItemType{get;set;}
    Public String discObligationId{get;set;}
    public List<Schema.FieldSetMember> GetLineItemFieldSets(){
        if(this.Record.Line_Item_Type__r == null){
            this.Record.Line_Item_Type__r = [SELECT Id, Line_Item_Category__r.Reference_Number__c FROM Line_Item_Type__c WHERE Id = :this.Record.Line_Item_Type__c];
        }
        return Schema.SObjectType.Line_Item__c.fieldSets.getMap().get('X' + this.Record.Line_Item_Type__r.Line_Item_Category__r.Reference_Number__c).Fields;
    }
    
    public AuditLineItemPopupController() {
        if(this.IsPostBack == null){
            try{
                this.ShowForm = false;
                this.disclosureId = ApexPages.CurrentPage().GetParameters().Get('disclosureId');
                this.ReconcileType = ApexPages.CurrentPage().GetParameters().Get('reconciletype');
                String lineItemId = ApexPages.CurrentPage().GetParameters().Get('lineitemId');
                String auditRecordType = [SELECT Id FROM RecordType WHERE Name='Audit Line Item' LIMIT 1].Id;                                               
                
                isSameReportId = false;
                if(this.ReconcileType == 'Donations Made'){
                    //DE4622
                    String discId = ApexPages.CurrentPage().GetParameters().Get('discId');                
                    List<Disclosure_Claim_for_Payment__c> listDCP = [SELECT Id, Disclosure_Obligation__r.Registration__c,
                                                                     Disclosure_Obligation__r.Reporting_Period__c
                                                                     FROM Disclosure_Claim_for_Payment__c
                                                                     WHERE Id =: discId LIMIT 1];
                    if(listDCP != null && listDCP.size() >0){
                        candidateReportId = listDCP[0].Disclosure_Obligation__r.Reporting_Period__c;
                        stakeholderRegId = listDCP[0].Disclosure_Obligation__r.Registration__c;
                        //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'ID: ' + this.disclosureId+ ', ID1: ' + stakeholderRegId));                    
                    }
                    
                    //DE4640
                    String donorId = ApexPages.CurrentPage().GetParameters().Get('donorId');
                    /*List<Disclosure_Obligation__c> listDO = [SELECT Id, Reporting_Period__c
                                                             FROM Disclosure_Obligation__c
                                                             WHERE Stakeholder__c =: donorId];*/
                    List<Disclosure_Claim_for_Payment__c> listDCP1 = [SELECT Id, Disclosure_Obligation__r.Registration__c,
                                                                     Disclosure_Obligation__r.Reporting_Period__c
                                                                     FROM Disclosure_Claim_for_Payment__c
                                                                     WHERE Stakeholder__c =: donorId];
                    for(Disclosure_Claim_for_Payment__c item : listDCP1){
                        if(item.Disclosure_Obligation__r.Reporting_Period__c == candidateReportId){
                            isSameReportId = true;
                            //add audit line item for this reporting period
                            discObligationId = item.Id;
                            break;
                        }
                    }
                    //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'a: '+donorId + 'b: ' + candidateReportId + 'c: ' + disclosureId + 'd: '+discId));                    
                }
                
                if(lineItemId != null){
                    Line_Item__c lineItem = [SELECT Line_Item_Type__c, Stakeholder__c, Id FROM Line_Item__c WHERE Id = :lineItemId LIMIT 1];
                    this.record = new Line_Item__c(
                        Stakeholder__c = lineItem.Stakeholder__c
                        , Line_Item__c = lineItem.Id
                        , Line_Item_Type__c = lineItem.Line_Item_Type__c
                        , RecordTypeId = auditRecordType
                    );
                    if(stakeholderRegId!=null){
                        this.record.Stakeholder_Registration__c = stakeholderRegId;
                        //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'a: '));
                    }
                    this.ShowForm = true;
                }
                else{
                	String stakeholderId = ApexPages.CurrentPage().GetParameters().Get('stakeholderId');
                    
                    //this.record = new Line_Item__c(RecordTypeId=auditRecordType,Stakeholder__c=stakeholderId);
                    this.record = new Line_Item__c(RecordTypeId=auditRecordType,Stakeholder__c=stakeholderId);
                    if(stakeholderRegId!=null){
                        this.record.Stakeholder_Registration__c = stakeholderRegId;
                        //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'a1: '));
                    }
                    
                	this.IsPostBack = false;
                }
                
            } catch (Exception e) {
                ApexPages.addMessages(e);
            }
        }
    }
    
    public List<SelectOption> GetLineItemTypes(){
        mapLineItemType = new Map<String,String>();
        List<SelectOption> temp = new List<SelectOption>();
        List<Line_Item_Type__c> listLineItemTypes = [
        	SELECT Id, Name,Disclosure_Claim_for_Payment__r.Name,Line_Item_Category__r.Line_Item_Category__c
            FROM Line_Item_Type__c
            WHERE Disclosure_Claim_For_Payment__c = :disclosureId
            	AND Line_Item_Category__r.Reconcile_Type__c = :this.ReconcileType
            //DE4596
            ORDER BY Line_Item_Category__r.Line_Item_Category__c DESC
        ];
        for(Line_Item_Type__c item :listLineItemTypes){
            temp.Add(new SelectOption(item.Id, item.Line_Item_Category__r.Line_Item_Category__c));
            mapLineItemType.put(item.Id, item.Line_Item_Category__r.Line_Item_Category__c);
        }
        
        return temp;
    }
    
    public void btnSelectLineItemType_Click(){
        this.ShowForm = true;
    }
    
    public void Save(){
        try {
            //DE4640
            if((this.ReconcileType == 'Donations Made' && isSameReportId) || this.ReconcileType == 'Donations Received'){
                //DE4595
                record.Active__c = true;
                
                //add audit line item for this reporting period
                List<Disclosure_Claim_for_Payment__c> DCP1 = [SELECT Id 
                                                              FROM Disclosure_Claim_for_Payment__c
                                                              WHERE Active__c = TRUE AND Disclosure_Obligation__c =: discObligationId];
                if(DCP1 != NULL && DCP1.size() > 0){
                    List<Line_Item_Type__c> LIT = [SELECT Id
                                                   FROM Line_Item_Type__c
                                                   WHERE Disclosure_Claim_for_Payment__c =: DCP1[0].Id
                                                   AND Line_Item_Category__r.Line_Item_Category__c =: mapLineItemType.get(this.record.Line_Item_Type__c)];
                    if(LIT != NULL && LIT.size() > 0){
                        this.record.Line_Item_Type__c = LIT[0].Id;
                    }
                }
                
                upsert record;
                this.StartUpScript = 'top.opener.lineItemAdded("' + record.Id + '"); top.window.close();';
            }else{
                String errorMess = 'An Audit Line Item cannot be created as the Donor has not submitted a Disclosure for the relevant reporting period.';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, '' + errorMess));
            }
        } catch (Exception e) {
            ApexPages.addMessages(e);
        }
    }
    public void Cancel() {
        this.StartUpScript = 'top.window.close()';
    }
}