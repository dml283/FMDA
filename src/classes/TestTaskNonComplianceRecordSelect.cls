@IsTest(SeeAllData = true)
public with sharing class TestTaskNonComplianceRecordSelect{
	static TestMethod void TestNewRedirect(){
        ApexPages.StandardController sc = new ApexPages.StandardController(new Task());
        TaskNonComplianceRecordSelectController controller = new TaskNonComplianceRecordSelectController(sc);
        Test.SetCurrentPage(Page.TaskNonComplianceRecordTypeSelect);
        controller.Redirect();
        
        List<RecordType> recordTypes = [
            SELECT ID, Name 
            FROM RecordType 
            WHERE SObjectType = 'Task' AND IsActive = true
        ];
        for(RecordType item: recordTypes){
        	ApexPages.currentPage().getParameters().put('RecordType', item.Id);
            controller.Redirect();            
        }
    }
}