@isTest
public class TestDisclosureNewOverrideController{
    static testMethod void Test(){
        ApexPages.StandardController sc = new ApexPages.StandardController(new Disclosure_Claim_For_Payment__c());  
        Test.SetCurrentPage(Page.DisclosureNewOverride);
        
        ApexPages.CurrentPage().GetParameters().Put('retURL', '/a0D/o');        
        DisclosureNewOverrideController controller = new DisclosureNewOverrideController(sc);
        controller.Back();
        
        ApexPages.StandardController sc1 = new ApexPages.StandardController(new Disclosure_Obligation__c());  
        Test.SetCurrentPage(Page.DisclosureObligationNewOverride);
        
        ApexPages.CurrentPage().GetParameters().Put('retURL', '/a07/o');        
        DisclosureNewOverrideController controller1 = new DisclosureNewOverrideController(sc1);
        controller1.Back();
    }
}