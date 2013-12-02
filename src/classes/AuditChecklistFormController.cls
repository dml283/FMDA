public class AuditChecklistFormController{
    public String doID{get;set;}
    public Audit_Checklist__c Entity{get;set;}
    public Disclosure_Claim_for_payment__c EntityDisclosure{get;set;}
    public List<SelectOption> ListSectionOptions{get{
        List<SelectOption> temp = new List<SelectOption>();
        Integer cnt = 0;
        temp.add(new SelectOption((cnt++)+'', 'Audit Checklist Info'));
        for (Audit_Checklist_Section__c sec : this.ListChecklistSection) {
            temp.add(new SelectOption(cnt + '',sec.Name + ' (section ' + cnt++ + ')' ));
        }
        
        return temp;
    }}
    public List<Audit_Checklist_Section__c> ListChecklistSection{get;set;}
    public Integer SelectedSection{get;set;}
    public Map<Id, List<SelectOption>> MapItemPicklist{get;set;}
    public Map<Id, string[]> MapItemMultiPicklistHolder{get;set;}
    public integer Step{get;set;}
    public boolean isMapSectionLiNcContainCurrentSection{get{return MapSectionLiNc.containsKey(CurrentSection.id);}set;}
    public Audit_Checklist_Section__c CurrentSection{get{return (Step>0)?ListChecklistSection[Step - 1]:ListChecklistSection[0];}}
    
    public List<Line_Item__c> ListLi{get;set;}
    public Map<Id, Id> MapCatLit{get;set;}
    public List<Task> ListAllTask{get;set;}
    
    public Map<String, List<Task>> MapSectionDoNc{get;set;}
    //public Map<Id, Map<Id, NcList>> MapSectionTask{get;set;}
    //The following 'Map' properties are used for rendering non-compliance list in each checklistsection
    //1st lvl grouping
    public Map<Id, List<Task>> MapSectionLiNc{get;set;}
    //2nd lvl grouping
    public Map<string, List<Line_Item__c>> MapNcLi{get;set;}
    //3rd lvl grouping
    public Map<Id, List<Task>> MapLiTask{get;set;}
    //2lvl grouping by NC_number, LineItem.Name
    public Map<String, Map<String, List<Task>>> MapNcLiTask{get;set;}
    
    public Disclosure_Claim_for_Payment__c relDO{get;set;}

    public boolean isContainCurrentSecion{
    	get{    		
    		return (MapSectionDoNc.containsKey(CurrentSection.id + '') && ((MapSectionDoNc.get(CurrentSection.Id + '')).size()>0));
    	}
    	set;}
    
    //public Map<Id, Map<Id, NcList>> MapSectionTask{get;set;}
    
    //public Map<string, SortInfo> MapSortInfo{get;set;}
    public boolean IsEdit{get{return this.Entity.IsTemplate__c != true;}}
    public Map<Id, Integer> MapAciNcCount{get;set;}
    
    public Map<string, Schema.FieldSet> GetMapLineItemFieldSets(){
        return Schema.SObjectType.Line_Item__c.fieldSets.getMap();
    }
    
    public AuditChecklistFormController(ApexPages.Standardcontroller controller){
        try{
            this.Step = 0;
            this.SelectedSection = 0;
            
            this.Entity = (Audit_Checklist__c)controller.GetRecord();
            this.Entity = this.GetChecklistById(this.Entity.Id);
            this.MapAciNcCount = new Map<Id, Integer>();
            this.MapSectionLiNc = new Map<Id, List<Task>>();
            this.MapSectionDoNc = new Map<String, List<Task>>();
            this.MapNcLi = new Map<string, List<Line_Item__c>>();
            this.MapNcLiTask= new Map<String, Map<String, List<Task>>>();
            this.MapLiTask = new Map<Id, List<Task>>();
            
            if(this.Entity == null){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'The Disclosure/Claim for payment record does not have an audit checklist associated with it.'));
                return;
            }
            this.doID = ApexPages.currentPage().getParameters().get('doID');
            System.debug('hanhluu::doID::before' + this.doID);
            if (this.doID == null || this.doID == '') this.doID = this.Entity.Disclosure_Claim_for_Payment__c;
            System.debug('hanhluu::doID::after' + this.doID);
            
            this.EntityDisclosure = this.getDisclosureById(doID);
            this.ListChecklistSection = this.GetChecklistSectionByParentId(this.Entity.Id);
            this.ListLi = this.PrepListLi(this.DoId);
            this.MapCatLit = this.PrepMapCatLit(this.DoId);
            this.ListAllTask = this.PrepListAllTask(this.DoId, this.ListLi);
            
            this.PrepItemResponse(this.ListChecklistSection);
            this.PrepNonCompliance(this.ListChecklistSection);
            //this.relDO = this.PreRelatedDisclosure();
         
        }
        catch(Exception ex){
            ApexPages.AddMessages(ex);
            System.debug('HanhLuu::AuditChecklistFormController::Exception::'+ ex);	
            //throw ex;
        }
    }
    
    private void PreLineItemCategory(Id tempId){
       LIst<Audit_Checklist_Section__c> checklistSections = [SELECT Audit_Checklist_Section_Id__c,Audit_Checklist__c,Line_Item_Category__c 
       							   FROM Audit_Checklist_Section__c
								   WHERE Audit_Checklist__c = :tempId];
    
    }
    
    public List<Line_Item__c> PrepListLi(Id varDoId){
        List<string> listLiField = new List<string>();
        for(Schema.SObjectField f :schema.SObjectType.Line_Item__c.fields.getMap().values()){
            if (f.GetDescribe().GetName() != 'LastReferencedDate'){
                listLiField.Add(f.GetDescribe().GetName());
            }
        }
      
        List<Audit_Checklist_Section__c> checklistSectionsItemCate = [SELECT Line_Item_Category__c
       							   			 						  FROM Audit_Checklist_Section__c
								   									  WHERE Audit_Checklist__c = :this.Entity.id];
		List<Line_Item__c> lineItems = Database.Query(
            'SELECT Line_item_Type__r.Line_Item_Category__c, Line_item_Type__r.Line_Item_Category__r.Reference_Number__c, ' + string.join(listLiField, ',') 
            + ' FROM Line_Item__c'
            + ' WHERE Line_Item_Type__r.Disclosure_Claim_For_Payment__c = :varDoId'
            + ' AND Line_item_Type__r.Line_Item_Category__r.Reference_Number__c != null'
            + ' AND RecordType.Name = \'Audit Line Item\'' 
            + ' AND Active__c = true'
        );
        
        //filter line item list
        List<Line_Item__c> selectedItems = new List<Line_Item__c>();
        for(Line_Item__c item:lineItems){
        	boolean isExist = false;
        	for(Audit_Checklist_Section__c listitem: checklistSectionsItemCate){
        		if (item.getSObject('Line_item_Type__r').getSObject('Line_Item_Category__r').id ==listitem.Line_Item_Category__c){
        			isExist = true;
        			break;
        		}        		
        	}
        	if (isExist) selectedItems.add(item);
        }
            								   											 
        return selectedItems; 
    }

    /*
    public Map<Id,List<Non_Compliance__c>> PreMapSectionNc(Id varDoId){
    	List<Non_Compliance__c> tempListNc = new List<Non_Compliance__c>();
    }
    */
    
    public Map<Id, Id> PrepMapCatLit(Id varDoId){
        Map<Id, Id> temp = new Map<Id, Id>();
        List<Line_Item_Type__c> tempListLit = [SELECT Id, Line_Item_Category__c FROM Line_Item_Type__c WHERE Disclosure_Claim_For_Payment__c = :doId AND Line_Item_Category__c != null];
        for(Line_Item_Type__c item :tempListLit){
            temp.Put(item.Line_Item_Category__c, item.Id);
        }
        
        return temp;
    }
    
    public List<Task> PrepListAllTask(Id varDoId, List<Line_Item__c> varListLi){
        
        Set<String> setLiId = new Set<String>{varDoId};
        setLiId.AddAll(new Map<String, sObject>(varListLi).KeySet());
        
        List<string> listTaskField = new List<string>();
        //System.debug('HanhLuu::PrepListAllTask::Schema.SObjectType.Task.fieldSets.Non_Compliance.GetFields()=' + Schema.SObjectType.Task.fieldSets.Non_Compliance.GetFields().size());
        for(Schema.FieldSetMember f :Schema.SObjectType.Task.fieldSets.Non_Compliance.GetFields()){
        	//System.debug('HanhLuu::PrepListAllTask::FieldPath=' + f.FieldPath ); 
            listTaskField.Add(f.FieldPath);
        }
        
        return Database.Query('SELECT WhatId, What.Name, ' + string.join(listTaskField, ',') + ' FROM Task WHERE WhatId IN :setLiId ORDER BY What.Name, Non_Compliance_Number__c');
    }
    
    public PageReference btnQuickSave_Click(){
        if(this.SubmitChanges()){
            PageReference pageRef = new PageReference('/apex/auditchecklistform?id=' + this.Entity.Id);
            pageRef.SetRedirect(false);
            return pageRef;
        }        
        return null;
        
    }
    
    public PageReference btnSaveAndClose_Click(){
        if(this.SubmitChanges()){
            return new PageReference('/' + this.doID);
        }
        return null;
    }
    
    public PageReference btnSaveAndPDF_Click(){
        if(this.SubmitChanges()){
            return Page.AuditChecklistFormPDF;
        }
        return null;
    }
    
    private boolean SubmitChanges(){
        SavePoint sp = Database.SetSavePoint();
        try{
            upsert this.EntityDisclosure;
            if(this.IsEdit){
                List<sObject> upsertList = new List<sObject>();   
                List<Audit_Checklist_Section__c> tempSections = new List<Audit_Checklist_Section__c>();  
                List<Audit_Checklist_Item__c> tempItems = new List<Audit_Checklist_Item__c>();   
                
                upsertList.Add(this.Entity);
                for(Audit_Checklist_Section__c section :this.ListChecklistSection){
                    tempSections.Add(section);
                    for(Audit_Checklist_Item__c item :section.Audit_Checklist_Questions__r){
                        tempItems.Add(item);
                    }
                }
                upsertList.AddAll((List<sObject>)tempSections);
                upsertList.AddAll((List<sObject>)tempItems);
                
                update upsertList;
            }
            else{
                this.Entity = this.Entity.Clone();
                this.Entity.IsTemplate__c = false;
                this.Entity.Disclosure_Claim_for_Payment__c = EntityDisclosure.Id;
                upsert this.Entity;
                
                List<Audit_Checklist_Section__c> tempSections = new List<Audit_Checklist_Section__c>();      
                for(Audit_Checklist_Section__c section :this.ListChecklistSection){
                    Audit_Checklist_Section__c tempSection = section.Clone();
                    tempSection.Audit_Checklist__c = this.Entity.Id;
                    if(tempSection.Line_Item_Category__c != null && this.MapCatLit.ContainsKey(tempSection.Line_Item_Category__c)){
                        tempSection.Line_Item_Type__c = this.MapCatLit.Get(tempSection.Line_Item_Category__c);
                    }
                    else{
                        tempSection.Line_Item_Type__c = null;
                    }
                    tempSections.Add(tempSection);
                }
                upsert tempSections;
                
                Map<String, List<String>> mapChecklistItem = new Map<String,List<String>>();
                Set<String> ChecklistItemIds = new Set<String>();
                Integer index = 0;
                List<Audit_Checklist_Item__c> tempItems = new List<Audit_Checklist_Item__c>();        
                for(Audit_Checklist_Section__c section :tempSections){
                    for(Audit_Checklist_Item__c item :section.Audit_Checklist_Questions__r){
                        Audit_Checklist_Item__c tempItem = item.Clone();
                        tempItem.Audit_Checklist_Section__c = section.Id;
                        
                        if(item.Response_Field_Type__c == 'Multi-Select Picklist'){
                            tempItem.Response_Field_Text__c = string.Join(this.MapItemMultiPicklistHolder.Get(item.Id), ';');
                        }
                        
                        tempItems.Add(tempItem);
                        ChecklistItemIds.add(item.Id);
                        mapChecklistItem.put(index+'', new List<String>());
                        mapChecklistItem.get(index+'').add(item.Id);
                        index++;
                    }
                }
                upsert tempItems;
                /*
List<Audit_Checklist_Item_Non_Compliance_Join__c> tempAciNcs = new List<Audit_Checklist_Item_Non_Compliance_Join__c>();        
for(Audit_Checklist_Section__c section :tempSections){
for(Audit_Checklist_Item__c item :section.Audit_Checklist_Questions__r){
for(Audit_Checklist_Item_Non_Compliance_Join__c aciNc :item.Audit_Checklist_Item_Non_Compliance_Join__r){                   
Audit_Checklist_Item_Non_Compliance_Join__c tempAciNc = aciNc.Clone();
tempAciNc.Audit_Checklist_Item__c = item.Id;
tempAciNcs.Add(tempAciNc);
}
}
}
upsert tempAciNcs;*/
                index = 0;
                for (Audit_Checklist_Item__c item : tempItems) {
                    mapChecklistItem.get((index++)+'').add(item.Id);
                }
                Map<String,String> checklistIdFromOldId = new Map<String,String>();
                for (String key : mapChecklistItem.keySet()) {
                    checklistIdFromOldId.put(mapChecklistItem.get(key).get(0),mapChecklistItem.get(key).get(1));
                }
                // Query all Audit_Checklist_Item_Non_Compliance_Join__c
                List<Audit_Checklist_Item_Non_Compliance_Join__c> joinItems = [Select Id, Audit_Checklist_Item__c, Non_Compliance__c
                                                                               FROM Audit_Checklist_Item_Non_Compliance_Join__c
                                                                               Where Audit_Checklist_Item__c IN :ChecklistItemIds];
                
                List<Audit_Checklist_Item_Non_Compliance_Join__c> cloneJoinList = new List<Audit_Checklist_Item_Non_Compliance_Join__c>();
                for(Audit_Checklist_Item_Non_Compliance_Join__c item : joinItems){
                    Audit_Checklist_Item_Non_Compliance_Join__c cloneItem = item.Clone(false,true);
                    cloneItem.Audit_Checklist_Item__c = checklistIdFromOldId.get(cloneItem.Audit_Checklist_Item__c);
                    cloneJoinList.add(cloneItem);
                }
                upsert cloneJoinList;
            }
            return true;
        }
        catch(Exception ex){
            ApexPages.AddMessages(ex);
            Database.RollBack(sp);
            
            return false;
        }
    }
    
    public void btnNavigate_Click(){
        this.SelectedSection = this.Step;
    }
    private Disclosure_Claim_For_payment__c getDisclosureById(String Id) {
        List<Disclosure_Claim_For_payment__c> temp = [
            SELECT Id, Stakeholder__c, Name,TRIM_Record_Number__c,
            Disclosure_Obligation__r.Registration__r.Election_Event1__r.Electorate__c,
            Disclosure_Obligation__r.Registration__r.Political_Party__c,
            Disclosure_Obligation__r.Lodgement_Due_Date__c,Initial_Audit_Officer__c,
            Initial_Audit_Date_Commenced__c, Initial_Audit_Date_Completed__c,
            Initial_Audit_Comments_Recommendations__c,Initial_Audit_Date_Approved__c,
            Initial_Audit_Approval_Comments__c,Final_Audit_Date_Completed__c,
            Final_Audit_Comments_Recommendations__c,Final_Audit_Date_Approved__c,
            Final_Audit_Approval_Comments__c,Final_Audit_Officer__c
            FROM Disclosure_Claim_For_payment__c
            WHERE Id = :Id
        ];
        if(temp.IsEmpty()){
            return null;
        }
        else{
            return temp[0];
        }
    }
    private Audit_Checklist__c GetChecklistById(string id){
        List<Audit_Checklist__c> temp = [
            SELECT Id,Disclosure_Claim_For_Payment__c
            , IsTemplate__c
            FROM Audit_Checklist__c
            WHERE Id = :id
        ];
        if(temp.IsEmpty()){
            return null;
        }
        else{
        	//temp[0].Disclosure_Claim_For_Payment__c = this.doID;
            return temp[0];
        }
    }
    
    private List<Audit_Checklist_Section__c> GetChecklistSectionByParentId(string parentId){
    	String entityId = ''+this.Entity.Id;
    	//System.debug('HanhLuu::GetChecklistSectionByParentId::this.Entity.Id=' + this.Entity.Id);
    	 
    	
        return [
            SELECT Id, Name, Comments__c, Description__c, Not_Applicable__c, Line_Item_Type__c,Line_Item_Category__c, Audit_Checklist__c
            , (
                SELECT Id, Name,Comments__c,Item_Description__c,Response_Field__c,Response_Field_Type__c,Response_Field_Type_Picklist__c,Sub_Section__c
                , Response_Field_Text__c, Response_Field_Number__c, Response_Field_Date__c, Response_Field_Currency__c, Response_Field_Type_Formula__c
                
                FROM Audit_Checklist_Questions__r
                ORDER BY Audit_Checklist_Item_Number_Formula__c
            )
            FROM Audit_Checklist_Section__c
            WHERE Audit_Checklist__c = :this.Entity.Id
            ORDER BY Order_Number__c
        ];                 
         
    }
    
 
    
    private  Disclosure_Claim_for_Payment__c PreRelatedDisclosure(){
    	return [SELECT Auditor_Registration_Number__c,Disclosure_Obligation__r.Lodgement_Due_Date__c,Fundraising_Events_Net__c,Audit_Small_Donations_Received_Average__c,Disclosure_Obligation__r.Registration__r.Date_of_First_Official_Agent_Appointment__c,Small_Donations_Received__c,Fundraising_Events_Gross__c,Audit_Small_Donations_Received_Count__c,Total_Funds_Received__c,Date_Received__c,Disclosure_Obligation__r.Request_for_Extension_Date__c,Disclosure_Obligation__r.Request_for_Extension_Received__c,Auditor_Name__c,Total_EE_Incurred__c,Funding_Expenditure_Amount__c,Expenditure_Funding_Percentage__c FROM Disclosure_Claim_For_Payment__c WHERE Id =:this.doID LIMIT 1];
    }
    
    private void PrepItemResponse(List<Audit_Checklist_Section__c> listSection){
        this.MapItemPicklist = new Map<Id, List<SelectOption>>();
        this.MapItemMultiPicklistHolder = new Map<Id, string[]>();
        //this.MapSectionTask = new Map<Id, Map<Id, NcList>>();
        
        Set<string> fields = new Set<string>();
        System.debug('hanhluu::PrepItemResponse::');
        for(Audit_Checklist_Section__c section :listSection){
            Set<string> setNcNumber = new Set<string>();
            //prep checklist item
            for(Audit_Checklist_Item__c item :section.Audit_Checklist_Questions__r){
                //item = mapAciNc.Get(item.Id);
                this.MapItemPicklist.Put(item.Id, new List<SelectOption>());
                this.MapItemMultiPicklistHolder.Put(item.Id, new string[]{});
                //prep picklist options
                if(item.Response_Field__c == 'Editable' && string.IsNotEmpty(item.Response_Field_Type__c) &&item.Response_Field_Type__c.ContainsIgnoreCase('picklist') && string.IsNotEmpty(item.Response_Field_Type_Picklist__c)){
                    List<SelectOption> listOption = new List<SelectOption>();
                    
                    for(string option :item.Response_Field_Type_Picklist__c.Split(';')){
                        listOption.Add(new SelectOption(option, option));
                    }
                    
                    this.MapItemPicklist.Put(item.Id, listOption);
                    
                    if(item.Response_Field_Type__c == 'Multi-Select Picklist'){
                        string[] mplValues = item.Response_Field_Text__c == null ? new string[]{} : item.Response_Field_Text__c.Split(';');
                        
                        this.MapItemMultiPicklistHolder.Put(item.Id, mplValues);
                    }
                }
                //prep formula field value
                else if(item.Response_Field__c == 'Formula' && string.IsNotEmpty(item.Response_Field_Type_Formula__c)){
                    fields.Add(item.Response_Field_Type_Formula__c);
                }
            }        
            // ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, string.valueof(mapTask.keySet())));
            for(Task nc :this.ListAllTask){
                if(setNcNumber.contains(nc.Non_Compliance_Number__c)){
                    //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, section.Name +': ' +nc.Non_Compliance_Number__c+'-'+nc.WhatId));
                    //if ((section.Line_Item_Category__c == mapCategoryFromLineItem.get(nc.WhatId)) || !mapCategoryFromLineItem.containsKey(nc.WhatId)) {
                        //mapTask.Get(nc.WhatId).Items.Add(new NonCompliance(nc));
                    //}
                }
            }
            //this.MapSectionTask.Put(section.Id, mapTask);
        }
        
        if(!fields.IsEmpty()){        	
            System.Debug('hanhluu::sql::SELECT ' + string.Join(new List<string>(fields),',') );
            Audit_Checklist__c temp = Database.Query('SELECT ' + string.Join(new List<string>(fields),',') +  ' FROM Audit_Checklist__c WHERE Id = \'' + this.Entity.Id + '\' LIMIT 1');
            String queryFields = '';
			if (this.Entity.Disclosure_Claim_For_Payment__c != this.doID){
				
				for(String fieldName:fields){
					//if(fieldName.indexOf('.')>-1){
						queryFields += fieldName.subString(fieldName.indexOf('.')+1) + ','; 	
					//}else{
					//	queryFields += fieldName +',';
					//}				
				}
	            queryFields = queryFields.substring(0,queryFields.length()-1);            
	            Disclosure_Claim_For_Payment__c tempDOC = Database.query('SELECT ' + queryFields + ' FROM Disclosure_Claim_For_Payment__c WHERE id = \''+ this.doID +'\''); 
				/*
	            Disclosure_Claim_For_Payment__c tempDOC = [SELECT Auditor_Registration_Number__c,Disclosure_Obligation__r.Lodgement_Due_Date__c,Fundraising_Events_Net__c,Audit_Small_Donations_Received_Average__c,Disclosure_Obligation__r.Registration__r.Date_of_First_Official_Agent_Appointment__c,Small_Donations_Received__c,Fundraising_Events_Gross__c,Audit_Small_Donations_Received_Count__c,Total_Funds_Received__c,Date_Received__c,Disclosure_Obligation__r.Request_for_Extension_Date__c,Disclosure_Obligation__r.Request_for_Extension_Received__c,Auditor_Name__c,Total_EE_Incurred__c,Funding_Expenditure_Amount__c,Expenditure_Funding_Percentage__c
													       FROM Disclosure_Claim_For_Payment__c
													       WHERE id = :this.doID];
				*/				
				SObject	tempDO	= tempDOC;
				boolean isContinue= true;										         
	            for(Audit_Checklist_Section__c section :listSection){
	                for(Audit_Checklist_Item__c item :section.Audit_Checklist_Questions__r){
	                    if(item.Response_Field__c == 'Formula' && string.IsNotEmpty(item.Response_Field_Type_Formula__c)){
	                        SObject obj = temp;
	                        object value;
	                        system.debug('hanhluu::formular::' + item.Response_Field_Type_Formula__c);
	                        isContinue=true;
	                        for(string f :item.Response_Field_Type_Formula__c.Split('\\.')){
	                            //ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.INFO, f));	                                                        
	                            if(f.EndsWith('r')){
	                            	if (f.containsIgnoreCase('Disclosure_Claim_For_Payment')){
	                            		obj=tempDO;
	                            	}
	                            	else{ 
	                            		system.debug('hanhluu::formular::f::' + f);
	                            		try{
	                                		obj = obj.GetSObject(f);
	                            		}catch( exception ex){
	                            			break;
	                            		}
	                            	}	                            	
	                            }
	                            /*
	                            else{
	                                try{
	                                    if(f == null){
	                                    }
	                                    else if(item.Response_Field_Type__c == 'Date'){
	                                        item.Response_Field_Date__c = (Date)obj.Get(f);
	                                    }
	                                    else if(item.Response_Field_Type__c == 'Text'){
	                                        item.Response_Field_Text__c = (string)obj.Get(f);
	                                    }
	                                    else if(item.Response_Field_Type__c == 'Currency'){
	                                        item.Response_Field_Currency__c = (Decimal)obj.Get(f);
	                                    }
	                                    else if(item.Response_Field_Type__c == 'Number'){
	                                        item.Response_Field_Number__c = (Decimal)obj.Get(f);
	                                    }
	                                }
	                                catch(Exception ex){}
	                            }
	                           */ 
	                        }
	                    }
	                }
	            }
        }
        else{
            for(Audit_Checklist_Section__c section :listSection){
                for(Audit_Checklist_Item__c item :section.Audit_Checklist_Questions__r){
                    if(item.Response_Field__c == 'Formula' && string.IsNotEmpty(item.Response_Field_Type_Formula__c)){
                        SObject obj = temp;
                        for(string f :item.Response_Field_Type_Formula__c.Split('\\.')){
                            //ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.INFO, f));                            
                            if(f.EndsWith('r')){
                               	obj = obj.GetSObject(f);
                            }
                            else{
                                try{
                                    if(f == null){
                                    }
                                    else if(item.Response_Field_Type__c == 'Date'){
                                        item.Response_Field_Date__c = (Date)obj.Get(f);
                                    }
                                    else if(item.Response_Field_Type__c == 'Text'){
                                        item.Response_Field_Text__c = (string)obj.Get(f);
                                    }
                                    else if(item.Response_Field_Type__c == 'Currency'){
                                        item.Response_Field_Currency__c = (Decimal)obj.Get(f);
                                    }
                                    else if(item.Response_Field_Type__c == 'Number'){
                                        item.Response_Field_Number__c = (Decimal)obj.Get(f);
                                    }
                                }
                                catch(Exception ex){}
                            }
                        }
                    }
                }
            }        	
        }
     }        
     //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, String.valueOf(MapSectionTask.get('a0gN0000000dVsaIAE').Get('a0HN0000002hy7AMAQ').Items)));
    }
    
    public void PrepNonCompliance(List<Audit_Checklist_Section__c> varListSection){
    	try{
	        Map<Id, Audit_Checklist_Item__c> mapAciNc = new Map<Id, Audit_Checklist_Item__c>([
	            SELECT Id
	            , (
	                SELECT Non_Compliance__r.Non_Compliance_Number__c
	                FROM Audit_Checklist_Item_Non_Compliance_Join__r                    
	            )
	            FROM Audit_Checklist_Item__c
	            WHERE Audit_Checklist_Section__r.Audit_Checklist__c = :this.Entity.Id
	        ]);
	        
	        //hold li against each nc, this map is to de-duplicate for this.MapNcLi
	        Map<string, Set<Id>> tempMapNcLi = new Map<string, Set<Id>>();
	        //hold the first task for each non-compliance number
	        Map<string, Task> tempMapTaskByNo = new Map<string, Task>();
	        Map<Id, Line_Item__c> tempMapLi = new Map<Id, Line_Item__c>(this.ListLi);
	        Map<string, Task> tempDoMapTask = new Map<string,Task>();
	        
	        for(Task nc :this.ListAllTask){
	            
	            if(this.DoId == nc.WhatId){
	                tempDoMapTask.Put(nc.Non_Compliance_Number__c, nc);
	            }
	            else if(tempMapLi.ContainsKey(nc.WhatId)){
	                if(this.MapLiTask.ContainsKey(nc.WhatId)){
	                    this.MapLiTask.Get(nc.WhatId).Add(nc);
	                }
	                else{
	                    this.MapLiTask.Put(nc.WhatId, new List<Task>{nc});
	                }
	                if(tempMapNcLi.ContainsKey(nc.Non_Compliance_Number__c) && tempMapNcLi.Get(nc.Non_Compliance_Number__c).Add(nc.WhatId)){                
	                    this.MapNcLi.Get(nc.Non_Compliance_Number__c).Add(tempMapLi.Get(nc.WhatId));                                        
	                }
	                else{
	                	                	
	                    tempMapTaskByNo.Put(nc.Non_Compliance_Number__c, nc);
	                    tempMapNcLi.Put(nc.Non_Compliance_Number__c, new Set<Id>{nc.WhatId});
	                    this.MapNcLi.Put(nc.Non_Compliance_Number__c, new List<Line_Item__c>{tempMapLi.Get(nc.WhatId)});
	                }
	            }
	        }
	        
	        System.debug('HanhLuu::MapAciNcCount::key::value=');
	        for (Id key : mapAciNc.keySet()) {
	            Audit_Checklist_Item__c temp = mapAciNc.get(key);
	            System.debug('HanhLuu::MapAciNcCount::key::value=' + key +' - ' + temp.Audit_Checklist_Item_Non_Compliance_Join__r.size());
	            this.MapAciNcCount.put(key, temp.Audit_Checklist_Item_Non_Compliance_Join__r.size());
	        }
	        
	        for(Audit_Checklist_Section__c section :varListSection){
	            //init nc list per section
	            List<Task> listSectionNc = new List<Task>();
	            
	            List<Task> listSectionLiNc = new List<Task>();
	            
				//Set<Id> setSectionLiNc = new Set<Id>();
				Set<String> setSectionLiNc = new Set<String>();
	            
	            List<Task> listSectionDoNc = new List<Task>();
				//Set<Id> setSectionDoNc = new Set<Id>();
				Set<String> setSectionDoNc = new Set<String>();
	            
	            for(Audit_Checklist_Item__c item :section.Audit_Checklist_Questions__r){
	                //prep non-compliance number according to section
	                for(Audit_Checklist_Item_Non_Compliance_Join__c aciNcJoin :mapAciNc.Get(item.Id).Audit_Checklist_Item_Non_Compliance_Join__r){
	                    if(this.MapNcLi.ContainsKey(aciNcJoin.Non_Compliance__r.Non_Compliance_Number__c) && setSectionLiNc.Add(aciNcJoin.Non_Compliance__r.Non_Compliance_Number__c)){
	                        listSectionLiNc.Add(tempMapTaskByNo.Get(aciNcJoin.Non_Compliance__r.Non_Compliance_Number__c));
	                    }
	                    if(tempDoMapTask.ContainsKey(aciNcJoin.Non_Compliance__r.Non_Compliance_Number__c) && setSectionDoNc.Add(aciNcJoin.Non_Compliance__r.Non_Compliance_Number__c)){
	                        listSectionDoNc.Add(tempDoMapTask.Get(aciNcJoin.Non_Compliance__r.Non_Compliance_Number__c));
	                    }
	                }
	            }   
	            
	            this.MapSectionLiNc.Put(section.Id, listSectionLiNc);            
	            
	            this.MapSectionDoNc.Put(section.Id + '', listSectionDoNc);
	        }
	        
	        
			
	        for (String nc_number:this.MapNcLi.keyset() ){ 
	        	//List<Line_Item__c> listNcLi = this.MapNcLi.get(nc_number);
	        	Map<String, List<Task>> TempMapLiTask = new Map<String, List<Task>>(); 
				for (Line_Item__c li:this.MapNcLi.get(nc_number)){				
					//List<Task> listNcLiTask = this.MapLiTask.get(item.id);
					List<Task> TempListLiTask = new List<Task>();
					for(Task listNcLiTaskItem:this.MapLiTask.get(li.id) ){
						if (listNcLiTaskItem.Non_Compliance_Number__c.equals(nc_number) &&  (listNcLiTaskItem.WhatId == li.id)){
							TempListLiTask.add(listNcLiTaskItem);
						}
					}
					TempMapLiTask.put(li.Name, TempListLiTask);
				}        	       	         	
				this.MapNcLiTask.put(nc_number,TempMapLiTask );
	        }
    	}catch (Exception ex){
			System.debug('HanhLuu::PrepNonCompliance::Exception::'+ ex);			    	
    	}
    	
    }
    
    public void SectionDropdown_OnChange() {
        this.Step = Integer.valueOf(this.SelectedSection);
    }
    public class SortInfo{
        public string SortBy{get;set;}
        public string SortDirection{get;set;}
        
        public SortInfo(string sortBy, string sortDirection){
            this.SortBy = sortBy;
            this.SortDirection = sortDirection;
        }
    }
}