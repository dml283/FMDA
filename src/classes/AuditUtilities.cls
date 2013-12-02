public with sharing class AuditUtilities {
	public static List<Audit_Checklist__c> cloneAuditCheckLists(List<Audit_Checklist__c> auditChecklists){
            String auditCheckListIds = '';
            List<Audit_Checklist__c> clonedList = new List<Audit_Checklist__c>();
            
            for(Audit_Checklist__c item : auditChecklists){
            	auditCheckListIds +=  '\'' + item.id + '\', ';
            }            
            auditCheckListIds = auditCheckListIds.substring(0,auditCheckListIds.length()-2);
            List<Audit_Checklist_Section__c> tempSection = GetChecklistSectionByParentId(auditCheckListIds);
			Map<id, List<Audit_Checklist_Section__c>> mapSections  =new Map<id,List<Audit_Checklist_Section__c>>();
			List<Audit_Checklist_Section__c>  secs = new List<Audit_Checklist_Section__c>();
			String Audit_Checklist_id = '';
			Audit_Checklist__c cloneAuditChecklist;
			
			for (Audit_Checklist_Section__c sec : tempSection) {
		       if(Audit_Checklist_id.equals('' + sec.Audit_Checklist__c)){
		       		secs.add(sec);
		       }else{
		       		if (secs.size()>0){
						mapSections.put(Audit_Checklist_id ,secs );
						System.debug('hanhluu:utilities:mapSections:key=' + Audit_Checklist_id);
		       		}
					Audit_Checklist_id = '' + sec.Audit_Checklist__c;
					secs = new List<Audit_Checklist_Section__c>();
					secs.add(sec);			       
		       }
			}
	
	   		if (secs.size()>0){
				mapSections.put(Audit_Checklist_id ,secs );
				System.debug('hanhluu:utilities:mapSections:key=' + Audit_Checklist_id);
       		}
	
			System.debug('hanhluu:utilities:numOfSections=' + secs.size());
			System.debug('hanhluu:utilities:mapSections=' + mapSections.size());
			System.debug('hanhluu:utilities:mapSections=' + mapSections.keySet());
			
			List<Audit_Checklist_Section__c> cloneSectionList;
            for(Audit_Checklist__c auditChecklist: auditChecklists){
	            if (auditChecklist.Id != null){	            	
		            cloneAuditChecklist = auditChecklist.clone(false,true);
		            upsert cloneAuditChecklist;
		            clonedList.add(cloneAuditChecklist); 
		            System.debug('hanhluu:utilities:cloneAuditChecklist=' + cloneAuditChecklist.id);
		            
		            // Clone Checklist Section
		            cloneSectionList = new List<Audit_Checklist_Section__c>();
		            tempSection = (List<Audit_Checklist_Section__c>)mapSections.get(auditChecklist.id);
		            System.debug('hanhluu:utilities:getSections');
		            for (Audit_Checklist_Section__c sec : tempSection) {
		            	if(sec.Audit_Checklist__c == auditChecklist.id){
			                Audit_Checklist_Section__c cloneSec = sec.clone(false,true);
			                cloneSec.Audit_Checklist__c = cloneAuditChecklist.Id;
			                cloneSectionList.add(cloneSec);
		            	}
		            }
		            upsert cloneSectionList;
				    System.debug('hanhluu:utilities:cloneSectionList=' + cloneSectionList.size());
				    
				    //clone checklistitem
				    Map<String, List<String>> mapChecklistItem = new Map<String,List<String>>();
		            Set<String> ChecklistItemIds = new Set<String>();
		            Integer index = 0;
		            List<Audit_Checklist_Item__c> cloneItemList = new List<Audit_Checklist_Item__c>();
		            for(Audit_Checklist_Section__c sec :cloneSectionList){
		                for(Audit_Checklist_Item__c item :sec.Audit_Checklist_Questions__r){
		                    Audit_Checklist_Item__c cloneItem = item.Clone(false,true);
		                    cloneItem.Audit_Checklist_Section__c = sec.Id;
		                    cloneItemList.Add(cloneItem);
		                    ChecklistItemIds.add(item.Id);
		                    mapChecklistItem.put(index+'', new List<String>());
		                    mapChecklistItem.get(index+'').add(item.Id);
		                    index++;
		                }
		            }
		            upsert cloneItemList;
		            System.debug('hanhluu:utilities:numOfItems=' + index);
		            System.debug('hanhluu:utilities:cloneItemList=' + cloneItemList.size());
		            
		            // Query all Audit_Checklist_Item_Non_Compliance_Join__c
		            index = 0;
		            for (Audit_Checklist_Item__c item : cloneItemList) {
		                mapChecklistItem.get((index++)+'').add(item.Id);
		            }
		            Map<String,String> checklistIdFromOldId = new Map<String,String>();
		            for (String key : mapChecklistItem.keySet()) {
		                checklistIdFromOldId.put(mapChecklistItem.get(key).get(0),mapChecklistItem.get(key).get(1));
		            }
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
		            System.debug('hanhluu:utilities:cloneJoinList=' + cloneJoinList.size());
		             
	            }	            	
            }            
			
            return clonedList;
	}
	
	
	private static List<Audit_Checklist_Section__c> GetChecklistSectionByParentId(string parentId){
        String query = allSectionField() + ',(' + allItemField() + ' From Audit_Checklist_Questions__r)'
            			+ ' FROM Audit_Checklist_Section__c WHERE Audit_Checklist__c IN (' + parentId + ')'
            			+ ' ORDER BY Audit_Checklist__c';        
        System.debug('hanhluu:utilities:SQLstring=' + query);
        return Database.query(query);
    }
    
    private static String allSectionField () {
        String query = 'SELECT ';
        Schema.FieldSet SectionFieldSet = Schema.SObjectType.Audit_Checklist_Section__c.fieldSets.Audit_Checklist_Section_Template;
        for(Schema.FieldSetMember f : SectionFieldSet.getFields()) {
            query += f.getFieldPath() + ', ';
        }
        query += ' Id ';
        
        return query;
    }
    
    private static String allItemField () {
        String query = 'SELECT ';
        Schema.FieldSet SectionFieldSet = Schema.SObjectType.Audit_Checklist_Item__c.fieldSets.Audit_Checklist_Item_Template;
        for(Schema.FieldSetMember f : SectionFieldSet.getFields()) {
            query += f.getFieldPath() + ', ';
        }
        query += ' Id ';
        return query;
    }
    

}