@IsTest
public class TestPagingInfo {
	public static testmethod void Test(){
        List<Contact> contacts = new List<Contact>();
        for(Integer i = 0; i < 10000; i++){
            contacts.Add(new Contact(FirstName = 'FirstName ' + i, LastName = 'LastName ' + i));
        }
        insert contacts;
        
    	string query = 'SELECT Id FROM Contact';
        string countQuery = 'SELECT COUNT() FROM Contact';
        
        PagingInfo pager = new PagingInfo();
        pager = new PagingInfo('contacts', query, countQuery);
        
        contacts = pager.GetRecords();
        
        boolean hasNext = pager.HasNext;
        boolean hasPrevious = pager.HasPrevious;
        integer pageCount = pager.PageCount;
    }
}