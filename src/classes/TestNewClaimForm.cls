@IsTest 
public class TestNewClaimForm{
 static Map<string, SObject> Entities{get;set;}
    
    static TestMethod void Test(){
        Init();
        PageReference pageRef = Page.NewClaimForm;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('doID',Entities.get('do').Id);
        
        NewClaimFormController ctl = new NewClaimFormController();
        ctl.save();
        ctl.cancel();
    }
     
    static void Init(){
        Entities = new Map<string, Sobject>();
        List<sObject> uplist = new List<sObject>();
        Map<String, String> listRecordType = new Map<String,String>();
		for (RecordType r : [SELECT Id, Name FROM RecordType]) {
			listRecordType.put (r.Name, r.Id);
		}
        
        Account accountPerson = new Account(LastName = 'Test', FirstName='Name',RecordTypeId=listRecordType.get('Person') );
        insert accountPerson;
        Election_Event__c localCamp = new Election_Event__c(RecordTypeId=listRecordType.get('Local Government Election Event'), Name='Test Campaign', By_Election__c=true, Date_of_Election__c = Date.parse('30/05/2014'));
        insert localCamp;
        Registration__c reg1 = new Registration__c(RecordTypeId=listRecordType.get('Elected Member'), Election_Event1__c = localCamp.Id, Stakeholder__c = accountPerson.Id);
        uplist.add(reg1);
        Reporting_Period__c reportP = new Reporting_Period__c(RecordTypeId=listRecordType.get('Claim for Payment Period'), Name='Sample Period', Type__c='Financial Year');        
		reportP.Date_From__c = Date.parse('03/05/2014');
		reportP.Date_To__c = Date.parse('03/05/2015');
        uplist.add(reportP);
        insert uplist;
        uplist = new List<sObject>();
        Disclosure_Obligation__c disclosureOb = new Disclosure_Obligation__c(Name='Test',StakeHolder__c = accountPerson.Id, Reporting_Period__c=reportP.Id,Registration__c=reg1.Id);
        uplist.add(disclosureOb);
        Eligible_Claim_for_Payment__c ecp = new  Eligible_Claim_for_Payment__c(Registration__c = reg1.Id, Stakeholder__c = accountPerson.Id,Public_Fund__c = 'Elections Campaign Fund');
        uplist.add(ecp);
        insert uplist;
		Disclosure_Claim_for_Payment__c dcp = new Disclosure_Claim_for_Payment__c(RecordTypeId=listRecordType.get('Disclosure (State Candidate)'),
                                                                                 Disclosure_Obligation__c = disclosureOb.Id,Stakeholder__c = accountPerson.Id,
                                                                                 Official_Agent__c=accountPerson.Id);
		insert dcp;
        uplist = new List<sObject>();
		Line_Item_Category__c lic1 = new Line_Item_Category__c(Add_Row__c=true,Reference_Number__c='9999');
		uplist.add(lic1);
		Line_Item_Category__c lic2 = new Line_Item_Category__c(Add_Row__c=true,Reference_Number__c='9998');
		uplist.add(lic2);
        insert uplist;
        
        uplist = new List<sObject>();
		Line_Item_Type__c lit1 = new Line_Item_Type__c(Line_Item_Category__c=lic1.Id,Disclosure_Claim_for_Payment__c=dcp.Id,Line_Item_Type_Aggregated_Category__c='Electoral Communication Expenditure');
		uplist.add(lit1);
		Line_Item_Type__c lit2 = new Line_Item_Type__c(Line_Item_Category__c=lic2.Id,Disclosure_Claim_for_Payment__c=dcp.Id,Line_Item_Type_Aggregated_Category__c='Electoral Communication Expenditure');
		uplist.add(lit2);
        insert uplist;
        
        uplist = new List<sObject>();
        Line_Item__c li1 = new Line_Item__c(Line_Item_Type__c=lit1.Id);
		uplist.add(li1);
		Line_Item__c li2 = new Line_Item__c(Line_Item_Type__c=lit2.Id);
		uplist.add(li2);
        insert uplist;
        
        uplist = new List<sObject>();
        Reconciled_Line_Item__c rli1 = new Reconciled_Line_Item__c(Line_Item_Donation_Received__c=li1.Id);
		uplist.add(rli1);
		Reconciled_Line_Item__c rli2 = new Reconciled_Line_Item__c(Line_Item_Donation_Received__c=li2.Id, Line_Item_Donation_Made__c=li2.Id);
		uplist.add(rli2);
        Reconciled_Line_Item__c rli3 = new Reconciled_Line_Item__c(Line_Item_Donation_Made__c=li1.Id);
		uplist.add(rli3);
        
        Note note = new Note(parentId=li1.Id,Title='Note');
        uplist.add(note);
        
        insert uplist;
        Entities.put('do',dcp);
    }
}