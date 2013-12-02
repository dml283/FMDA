public class AttachmentPopupController{
    public String StartupScript{get;set;}
    public String doID{get;set;}
    public String fileName{get;set;}
    public String attachmentId{get;set;}
    public String parentId{get;set;}
    public String TrimRecId{get;set;}
    public String fileDescription{get;set;}
    public Boolean isOverwrite{get;set;}
    public transient Blob fileBody{get;set;}
    
    
    public AttachmentPopupController() {
        parentId = ApexPages.currentPage().getParameters().get('do');
        
        parentId = get18CharsId(parentId);
        TrimRecId = ApexPages.currentPage().getParameters().get('trimRecId');
        StartupScript='';
    }
    
    private String get18CharsId(String inId) {
        if (inId != null) {
            if (inId.length() < 18) {
                inId = (Id)inId;
            }
        }
        return inId;
    }
    /**
     * Upload new Attachment and also make a new Trim Record for the attachment
     **/
 	public PageReference upload() {
 
 		System.debug('---------------- Debug ---------  upload() ');
 		
 		if (!Attachment.sObjectType.getDescribe().isCreateable() || !Attachment.sObjectType.getDescribe().isUpdateable()){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to upload attachment.'));
			return null;
 		}
 		
 		if(this.fileName == '' || this.fileBody == null) 
 		{
 			ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO,'File Required for upload'));
 			return null;
 		}
	 
	    try {
	    	
	    	Attachment newAttachment = null;
			
			System.debug('---------------- Debug ---------  upload() try statement');
	      
	 		if(this.isOverwrite && this.attachmentId != null && !String.isBlank(this.attachmentId)) {
	 			newAttachment = [select a.Id, a.Name, a.body, a.Description, a.ParentId, a.OwnerId from Attachment a where a.Id =: this.attachmentId limit 1];
				System.debug('---------------- Debug ---------  upload overwrite attachment ');
	 		} else {
	 			newAttachment = new Attachment();
				System.debug('---------------- Debug ---------  selectedAttachment set Parent ID  ' +  this.parentId);
				newAttachment.ParentId = this.parentId;
	 		}
		
			System.debug('---------------- Debug ---------  upload() UserInfo.getUserId() = ' + UserInfo.getUserId());
		    newAttachment.OwnerId = UserInfo.getUserId();
	    
	    	newAttachment.Body = this.fileBody;
			newAttachment.Name = this.fileName;
			System.debug('---------------- Debug ---------  upload() this.fileDescription = ' + this.fileDescription);
			newAttachment.Description = this.fileDescription;
      	
	      	System.debug('---------------- Debug ---------  upload() upsert');
	      	
			upsert newAttachment;
			//this.attachmentId = newAttachment.Id;
			//this.fileBody = null;
            String str = JSON.serialize(newAttachment);
            StartupScript = 'top.window.opener.ReloadSection(\'' + TrimRecId + '\',' + str + ');';
            StartupScript += 'top.window.close();';
			return null;
	      
	    } catch (DMLException e) {
	    	System.debug('---------------- ERROR --------- Error saving Trim Record ' + e.getMessage());
			ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Error uploading attachment and saving record ' + e.getMessage()));
	      	return null;
	    }

		return null;

  	}
    
        /**
     * Get the current Attachment and any other non Trim Record attachmants
     **/
	public List<SelectOption> getAttachmentItems() {
    	
		System.debug('---------------- Debug ---------  getAttachmentItems');
		
		if (Schema.sObjectType.Attachment.isAccessible()){
		
	        List<SelectOption> options = new List<SelectOption>();
	            
	        List<fuseit_s2t__Trim_Record__c> Records = [Select fuseit_s2t__Attachment_ID__c From fuseit_s2t__Trim_Record__c  where fuseit_s2t__Parent_ID__c =: this.ParentId];
	        Boolean isFound = false;
	        
	        for(Attachment att : [select Id, Name from Attachment where ParentId =: this.ParentId]) {
	        	isFound = false;
	        	
	        	System.debug('---------------- Debug ---------  getAttachmentItems att ID = ' + att.Id);
	        	
	        	for(fuseit_s2t__Trim_Record__c record : Records) {
	        		if(record.fuseit_s2t__Attachment_ID__c.equals(att.Id)) {
	        			isFound = true;
	        			System.debug('---------------- Debug ---------  getAttachmentItems isFound = true');
	        			break;
	        		}
	        	}
	        	
	        	if(!isFound) {
	        		System.debug('---------------- Debug ---------  getAttachmentItems isFound = false and this.attachmentId ' + this.attachmentId + ' not equal id ' + att.Id);
	        		options.add(new SelectOption(att.Id, att.Name));
	        	}
	        }
	        
			System.debug('---------------- Debug ---------  getAttachmentItems options count = ' + options.size());
            if (options.size() == 0) {
                isOverwrite = false;
		        options.add(new SelectOption('','--None--'));
            } else {
                isOverwrite =true;
            }
	        return options;
		} else {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to view Attachments'));
			return null;
		}

	}
}