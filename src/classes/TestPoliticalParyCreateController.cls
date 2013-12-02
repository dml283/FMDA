@isTest
public with sharing class TestPoliticalParyCreateController{
    static Account Entity;
	static testMethod void newTest() { 
        Init();
    	PageReference pageRef = Page.PoliticalPartyCreate;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController stdController = new ApexPages.StandardController(Entity);
    	PoliticalPartyCreateController controller = new PoliticalPartyCreateController(stdController);
        controller.save();
        controller.btnSelectRecordType_Click();
    }
    static void Init(){
        Entity = new Account(name= 'Test Political Party name');
        upsert Entity;
    }
}