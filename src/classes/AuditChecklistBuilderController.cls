public class AuditChecklistBuilderController{
    public Audit_Checklist__c auditChecklist{get;set;}
    public boolean isEditChecklist{get;set;}
    public String allHiddenId{get;set;}
    private String doID;
    private String auditID;
    private Integer RecordCounter;
    public List<AuditSectionWrapper> SectionWrapperList{get;set;}
    
    public Map<string, Schema.FieldSet> GetMapSectionFieldSets(){
        return Schema.SObjectType.Audit_Checklist_Section__c.fieldSets.getMap();
    }
    public Map<string, Schema.FieldSet> GetMapItemFieldSets(){
        return Schema.SObjectType.Audit_Checklist_Item__c.fieldSets.getMap();
    }
    
    public AuditChecklistBuilderController() {
        try {
            doID = ApexPages.currentPage().getParameters().get('doID');
            auditID = ApexPages.currentPage().getParameters().get('auditID');
            String cloneSuccess = ApexPages.currentPage().getParameters().get('cloneSuccess');
            if (cloneSuccess == 'true') {
        		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Cloned successfully! This is the cloned template'));
            }
            allHiddenId = '';
            RecordCounter = 0;
            SectionWrapperList = new List<AuditSectionWrapper>();
            if (auditID == null) {
                // Create new Audit checklist
                auditChecklist = new Audit_Checklist__c(IsTemplate__c = true,Disclosure_Claim_for_Payment__c=doID);
                // add 1 new section
                btnAddSection_OnClick();
                isEditChecklist = true;
            } else {
                // Edit Audit checklist
                // Select audit Checklist
                isEditChecklist = false;
                List<Audit_Checklist__c> tempAuditList = [Select Id, Name, Disclosure_Claim_for_Payment__c, IsTemplate__c,
                                    Template_Description__c, Template_Name__c
                                  From Audit_Checklist__c
                                  WHERE Id = :auditId And IsTemplate__c = true Limit 1];
                if (tempAuditList.size() > 0) {
                    auditChecklist = tempAuditList.get(0);
                    doID = tempAuditList.get(0).Disclosure_Claim_for_Payment__c;
                } else {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Audit Checklist Template not found!!!'));
                    return;
                }
                // Find all checklist section
                String query = allSectionField();
                query += ' FROM Audit_Checklist_Section__c  WHERE Audit_Checklist__c=\'' 
                    	+ auditChecklist.Id + '\' Order by Order_Number__c ASC';
                List<Audit_Checklist_Section__c> sectionTemps = Database.Query(query);
                
                if (sectionTemps.size() > 0) {
                    // Build a map with key is section Id
                    Map<String,List<Audit_Checklist_Item__c>> auditItemMap = new Map<String,List<Audit_Checklist_Item__c>>();
                    // Find all checkList Item
                    query = allItemField();
                    query += 'FROM Audit_Checklist_Item__c  WHERE Audit_Checklist_Section__c IN (';
                    for (Audit_Checklist_Section__c sec : sectionTemps) {
                        String IdTemp = sec.Id;
                        query += '\'' + IdTemp + '\', ';
                    }
                    // TRIM last comma
                    query = query.subString(0,query.Length()-2) + ') Order by Audit_Checklist_Item_Number_Formula__c ASC';
                    Set<String> checlistItemIDs = new Set<String>();
                    for (Audit_Checklist_Item__c item : database.Query(query)) {
                        if (!auditItemMap.containsKey(item.Audit_Checklist_Section__c)) {
                            auditItemMap.put(item.Audit_Checklist_Section__c,new List<Audit_Checklist_Item__c>());
                        }
                        auditItemMap.get(item.Audit_Checklist_Section__c).add(item);
                        checlistItemIDs.add(item.Id);
                    }
                    //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,sectionTemps.size()+String.valueof(sectionTemps)));
                    // For Non-Compliance
        			Map<Id, AggregateResult> ItemsNonComplianceCount = new Map<Id, AggregateResult>(
            				[SELECT Audit_Checklist_Item__c Id, COUNT(Id) Cnt FROM Audit_Checklist_Item_Non_Compliance_Join__c 
                             WHERE Audit_Checklist_Item__c IN :checlistItemIDs 
                             GROUP BY Audit_Checklist_Item__c]);
                    // Build Wrapper
                    for (Audit_Checklist_Section__c sec : sectionTemps) {
                        AuditSectionWrapper tempSecWrap = new AuditSectionWrapper(RecordCounter++, sec, true, false);
                        if (auditItemMap.containsKey(sec.Id)) {
                            for (Audit_Checklist_Item__c item : auditItemMap.get(sec.Id)) {
                                Boolean hasCompliance = ItemsNonComplianceCount.containsKey(item.Id);
                                AuditItemWrapper tempItemWrap = new AuditItemWrapper(RecordCounter++, item, true, false,hasCompliance);
                                tempSecWrap.Items.add(tempItemWrap);
                            }
                        }
                        SectionWrapperList.add(tempSecWrap);
                    }
                }
            }
        } catch (Exception e) {
            ApexPages.addMessages(e);
        }
    }
    
    private List<Audit_Checklist_Section__c> GetChecklistSectionByParentId(string parentId){
        String query = allSectionField() + ',(' + allItemField() + ' From Audit_Checklist_Questions__r)'
            			+ ' FROM Audit_Checklist_Section__c WHERE Audit_Checklist__c=\'' + parentId + '\'';
        System.debug('hanhluu:GetChecklistSectionByParentId::SQL string = ' + query);
        return Database.query(query);
    }
    
    private String allSectionField () {
        String query = 'SELECT ';
        Schema.FieldSet SectionFieldSet = Schema.SObjectType.Audit_Checklist_Section__c.fieldSets.Audit_Checklist_Section_Template;
        for(Schema.FieldSetMember f : SectionFieldSet.getFields()) {
            query += f.getFieldPath() + ', ';
        }
        query += ' Id ';
        
        return query;
    }
    
    private String allItemField () {
        String query = 'SELECT ';
        Schema.FieldSet SectionFieldSet = Schema.SObjectType.Audit_Checklist_Item__c.fieldSets.Audit_Checklist_Item_Template;
        for(Schema.FieldSetMember f : SectionFieldSet.getFields()) {
            query += f.getFieldPath() + ', ';
        }
        query += ' Id ';
        return query;
    }
    
    private Audit_Checklist_Item__c getAuditChecklistItem (String Id) {
        String query = allItemField();
        query += 'FROM Audit_Checklist_Item__c  Where Id=\'' + Id + '\' LIMIT 1';
        return Database.query(query);
    }
    
    public void btnAddSection_OnClick() {
        //if (SectionWrapperList.size() == 0) {
	        SectionWrapperList.add(new AuditSectionWrapper(RecordCounter++));
        //} else {
        //    SectionWrapperList.add(0,new AuditSectionWrapper(RecordCounter++));
        //}
    }
    
    public PageReference btnBack_OnClick() {
        return new PageReference('/'+auditChecklist.Disclosure_Claim_for_payment__c);
    }
    
    public void btnQuickSave_OnClick() {
        Boolean temp = isEditChecklist;
        if (Save()) {
            isEditChecklist = temp;
        }
    }
    
    public PageReference btnSave_OnClick() {
        if (Save()) {
            return btnBack_OnClick();
        }
        return null;
    }
    
    public boolean Save() {
        try {
            btnSaveAuditCheckList_OnClick();
            for (AuditSectionWrapper secWrap : SectionWrapperList) {
                SectionQuickSave(true,secWrap.Id);
            }
        } catch (Exception e) {
            return false;
        }
        return true;
    }
    
    public PageReference btnClone_OnClick() {
    	System.debug('hanhluu:btnClone_OnClick:start');
    	
    	/*
        Savepoint sp = Database.setSavepoint();
        try {
            if (auditChecklist.Id == null) return null;
            Audit_Checklist__c cloneAuditChecklist = auditChecklist.clone(false,true);
            upsert cloneAuditChecklist;
            
            List<Audit_Checklist_Section__c> tempSection = GetChecklistSectionByParentId(auditChecklist.Id);
            System.debug('hanhluu:btnClone_OnClick:GetChecklistSectionByParentId');            
            
            // Clone Checklist Section
            List<Audit_Checklist_Section__c> cloneSectionList = new List<Audit_Checklist_Section__c>();
            for (Audit_Checklist_Section__c sec : tempSection) {
                Audit_Checklist_Section__c cloneSec = sec.clone(false,true);
                cloneSec.Audit_Checklist__c = cloneAuditChecklist.Id;
                cloneSectionList.add(cloneSec);
            }
            upsert cloneSectionList;
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
            index = 0;
            for (Audit_Checklist_Item__c item : cloneItemList) {
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
           
            PageReference pageRef = new PageReference('/apex/AuditChecklistBuilder?auditID=' + cloneAuditChecklist.Id+'&cloneSuccess=true');
            pageRef.setRedirect(true);
            return pageRef;
        } catch (Exception e) {
            Database.rollback(sp);
            ApexPages.addMessages(e);
        } */
        Savepoint sp = Database.setSavepoint();
        try {
	        List<Audit_Checklist__c> auditChecklists = new List<Audit_Checklist__c>();
	        auditChecklists.add(auditChecklist);
	        String cloneid = AuditUtilities.cloneAuditCheckLists(auditChecklists).get(0).id;
	        PageReference pageRef = new PageReference('/apex/AuditChecklistBuilder?auditID=' + cloneid+'&cloneSuccess=true');
			pageRef.setRedirect(true);
			return pageRef;
        } catch (Exception e) {
            Database.rollback(sp);
            ApexPages.addMessages(e);
        }
        return null;
    }
    public void btnSaveAuditCheckList_OnClick() {
        try {
        	upsert this.auditChecklist;
            isEditChecklist = false; 
        } catch (Exception e) {
            ApexPages.addMessages(e);
        }
    }
    
    public void btnEditAuditCheckList_OnClick() {
        isEditChecklist = true; 
    }
    
    public void btnEditSection_OnClick() {
        try{
        Integer sectionId = Integer.valueOf(ApexPages.currentPage().getParameters().get('sectionId'));
        Integer index = findSectionIndex(sectionId);
        if (index != -1) {
            SectionWrapperList.get(index).isEdit = true;
        }
        } catch(Exception e) {
            ApexPages.addMessages(e);
        }
    }
    
    public void btnDeleteSection_OnClick() {
        try {
            Integer sectionId = Integer.valueOf(ApexPages.currentPage().getParameters().get('sectionId'));
            Integer index = findSectionIndex(sectionId);
            if (index != -1) {
                AuditSectionWrapper wrap = SectionWrapperList.get(index);
                delete wrap.Section;
                SectionWrapperList.remove(index);
            }
        } catch (Exception e) {
            ApexPages.addMessages(e);
        }
    }
    
    public void btnSaveSection_OnClick() {
        Integer sectionId = Integer.valueOf(ApexPages.currentPage().getParameters().get('sectionId'));
        SectionQuickSave(false,sectionId);
    }
    public void btnQuickSaveSection_OnClick() {
        Integer sectionId = Integer.valueOf(ApexPages.currentPage().getParameters().get('sectionId'));
        SectionQuickSave(true,sectionId);
    }
    public boolean SectionQuickSave(boolean keepState,Integer sectionId) {
        if (this.auditChecklist.Id == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,'Please save Audit Checklist Template first'));
            return false;
        }
        // Create save Point
        Savepoint sp = Database.setSavepoint();
        try {
            Integer index = findSectionIndex(sectionId);
            if (index != -1) {
                AuditSectionWrapper wrap = SectionWrapperList.get(index);
                if (!wrap.isExist) {
                    wrap.Section = wrap.Section.Clone(false,false);
                    wrap.Section.Audit_Checklist__c = auditChecklist.Id;
                }
                upsert wrap.Section;
                // upsert CheckList Item;
                List<Audit_Checklist_Item__c> ItemUpsertList = new List<Audit_Checklist_Item__c>();
                for (AuditItemWrapper ItemWrap : wrap.Items) {
                    if (!ItemWrap.isExist) {
                        ItemWrap.Item = ItemWrap.Item.Clone(false, false);
                        ItemWrap.Item.Audit_Checklist_Section__c = wrap.Section.Id;
                    }
                    ItemUpsertList.add(ItemWrap.item);
                }
                upsert ItemUpsertList;
                for (AuditItemWrapper ItemWrap : wrap.Items) {
                    ItemWrap.isExist = true;
                    ItemWrap.isEdit	= ItemWrap.isEdit && keepState;
                }
                wrap.isExist = true;
                wrap.isEdit = keepState;
            }
        } catch (Exception e) {
            //1. An exception was caught. We need to revert back to our Savepoint
            Database.rollback(sp);
            //2. Add the error to the page for the user to see
            ApexPages.addMessages(e);
            return false;
        }
        return true;
    }
    public void btnAddChecklistItem_OnClick(){
        //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,ApexPages.currentPage().getParameters().get('sectionId')+'\nab'));
        Integer sectionId = Integer.valueOf(ApexPages.currentPage().getParameters().get('sectionId'));
        Integer index = findSectionIndex(sectionId);
        if (index != -1) {
            AuditSectionWrapper wrap = SectionWrapperList.get(index);
            AuditItemWrapper temp = new AuditItemWrapper(RecordCounter++, new Audit_Checklist_Item__c(), false, true);
            //if (wrap.Items.size() == 0) {
            wrap.Items.add(temp);
            //} else {
            //    wrap.Items.add(0,temp);
            //}
        }
    }
    
    public void btnSaveRow_onClick() {
        try {
            Integer sectionId = Integer.valueOf(ApexPages.currentPage().getParameters().get('sectionId'));
            Integer itemId = Integer.valueOf(ApexPages.currentPage().getParameters().get('itemId'));
            Integer sectionIndex = findSectionIndex(sectionId);
            if (sectionIndex != -1) {
                AuditSectionWrapper wrap = SectionWrapperList.get(sectionIndex);
                if (!wrap.isExist) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,'Please save Audit Checklist Section'));
                    return;
                }
                Integer itemIndex = findItemIndex(itemId, wrap.Items);
                if (itemIndex != -1) {
                    AuditItemWrapper ItemWrap = wrap.Items.get(itemIndex);
                    if (!ItemWrap.isExist)
                    	ItemWrap.Item.Audit_Checklist_Section__c = wrap.Section.Id;
                    upsert ItemWrap.Item;
                    ItemWrap.isEdit = false;
                    ItemWrap.isExist = true;
                }
            }
        } catch (Exception e) {
            ApexPages.addMessages(e);
        }
    }
    public void btnDeleteRow_OnClick() {
        try {
            Integer sectionId = Integer.valueOf(ApexPages.currentPage().getParameters().get('sectionId'));
            Integer itemId = Integer.valueOf(ApexPages.currentPage().getParameters().get('itemId'));
            Integer sectionIndex = findSectionIndex(sectionId);
            if (sectionIndex != -1) {
                AuditSectionWrapper wrap = SectionWrapperList.get(sectionIndex);
                Integer itemIndex = findItemIndex(itemId, wrap.Items);
                if (itemIndex != -1) {
                    AuditItemWrapper ItemWrap = wrap.Items.get(itemIndex);
                    Delete ItemWrap.Item;
                    wrap.Items.remove(itemIndex);
                }
            }
        } catch (Exception e) {
            ApexPages.addMessages(e);
        }
    }
    
    public void btnEditRow_OnClick() {
        try {
            Integer sectionId = Integer.valueOf(ApexPages.currentPage().getParameters().get('sectionId'));
            Integer itemId = Integer.valueOf(ApexPages.currentPage().getParameters().get('itemId'));
            Integer sectionIndex = findSectionIndex(sectionId);
            if (sectionIndex != -1) {
                AuditSectionWrapper wrap = SectionWrapperList.get(sectionIndex);
                Integer itemIndex = findItemIndex(itemId, wrap.Items);
                if (itemIndex != -1) {
                    wrap.Items.get(itemIndex).isEdit = true;
                    //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,wrap.Items.get(itemIndex).Item.Id +''));
                }
            }
        } catch (Exception e) {
            ApexPages.addMessages(e);
        }
    }
    
    public void btnCancelRow_OnClick() {
        try {
            Integer sectionId = Integer.valueOf(ApexPages.currentPage().getParameters().get('sectionId'));
            Integer itemId = Integer.valueOf(ApexPages.currentPage().getParameters().get('itemId'));
            Integer sectionIndex = findSectionIndex(sectionId);
            if (sectionIndex != -1) {
                AuditSectionWrapper wrap = SectionWrapperList.get(sectionIndex);
                Integer itemIndex = findItemIndex(itemId, wrap.Items);
                if (itemIndex != -1) {
                    AuditItemWrapper ItemWrap = wrap.Items.get(itemIndex);
                    if (ItemWrap.isExist) {
                        ItemWrap.Item = getAuditChecklistItem(ItemWrap.Item.Id);
                        ItemWrap.isEdit = false;
                    } else {
                        wrap.Items.remove(itemIndex);
                    }
                }
            }
        } catch (Exception e) {
            ApexPages.addMessages(e);
        }
    }
    
    public void reloadItem() {
        try {
            Integer sectionId = Integer.valueOf(ApexPages.currentPage().getParameters().get('sectionId'));
            // Item Id in DB, not in Wrapper
            String itemId = ApexPages.currentPage().getParameters().get('itemId');
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,sectionId +' ' + itemId));
            Integer sectionIndex = findSectionIndex(sectionId);
            if (sectionIndex != -1) {
                List<AuditItemWrapper> temp = SectionWrapperList.get(sectionIndex).Items;
                for (Integer i = 0; i < temp.size(); i++) {
                    AuditItemWrapper ItemWrap = temp.get(i);
                    if (ItemWrap.Item.Id == itemId) {
                        Integer count = [Select Count() from Audit_Checklist_Item_Non_Compliance_Join__c
                                    	WHERE Audit_Checklist_Item__c=:ItemWrap.Item.Id];
                    	ItemWrap.isNonComplianceExist = count > 0;
                        break;
                    }
                }
            }
        } catch (Exception e) {
            ApexPages.addMessages(e);
        }
    }
    private Integer findSectionIndex(Integer Id) {
        for (Integer i = 0; i < SectionWrapperList.size(); i++) {
            AuditSectionWrapper wrap = SectionWrapperList.get(i);
            if (wrap.Id == Id) {
                return i;
            }
        }
        return -1;
    }
    private Integer findItemIndex(Integer Id, List<AuditItemWrapper> temp) {
        for (Integer i = 0; i < temp.size(); i++) {
            AuditItemWrapper wrap = temp.get(i);
            if (wrap.Id == Id) {
                return i;
            }
        }
        return -1;
    }
    public class AuditSectionWrapper {
        public Audit_Checklist_Section__c Section{get;set;}
        public List<AuditItemWrapper> Items{get;set;}
        public boolean isExist{get;set;}
        public boolean isEdit{get;set;}
        public Integer Id{get;set;}
        public AuditSectionWrapper(Integer IdCounter) {
            this(IdCounter,new Audit_Checklist_Section__c(), false,true);
        }
        
        public AuditSectionWrapper(Integer IdCounter,Audit_Checklist_Section__c Section, boolean isExist, boolean isEdit) {
            this.Section 	= Section;
            this.Items	 	= new List<AuditItemWrapper>();
            this.isExist	= isExist;
            this.isEdit		= isEdit;
            this.Id 		= IdCounter;
        }
    }
    
    public class AuditItemWrapper {
        public Audit_Checklist_Item__c Item{get;set;}
        public Integer Id{get;set;}
        public boolean isExist{get;set;}
        public boolean isEdit{get;set;}
        public boolean isNonComplianceExist{get;set;}
        public AuditItemWrapper(Integer IdCounter, Audit_Checklist_Item__c Item, boolean isExist, boolean isEdit) {
            this(IdCounter, Item, isExist, isEdit, false);
        }
        public AuditItemWrapper(Integer IdCounter, Audit_Checklist_Item__c Item, boolean isExist, boolean isEdit, boolean isNonComplianceExist) {
            this.isExist = isExist;
            this.Item = Item;
            this.Id = IdCounter;
            this.isEdit = isEdit;
            this.isNonComplianceExist = isNonComplianceExist;
        }
    }
}