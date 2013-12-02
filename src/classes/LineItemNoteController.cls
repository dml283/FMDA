/* Used for showing all existing Notes associated with the Line Item 
** as well as provide the ability to Create/Edit/Delete records.
*/
public class LineItemNoteController{
	public boolean IsPostBack{get;set;}
    public List<NoteWrapper> NoteWrapperList{get;set;}
    public PagingInfo NotePagingInfo{get;set;}
    public String LineItemId{get;set;}
    public String litId{get;set;}
    public Integer RecordCounter{get;set;}
    public List<SelectOption> numberItemPerPageOptions{get;set;}
    public LineItemNoteController() {
        if(this.IsPostBack == null){
            try {
                LineItemId = ApexPages.CurrentPage().GetParameters().Get('lineItemId');
                litId = ApexPages.CurrentPage().GetParameters().Get('litId');
                numberItemPerPageOptions = new List<SelectOption>();
                numberItemPerPageOptions.add(new SelectOption('5', '5'));
                numberItemPerPageOptions.add(new SelectOption('10', '10'));
                numberItemPerPageOptions.add(new SelectOption('20', '20'));
                numberItemPerPageOptions.add(new SelectOption('50', '50'));
                numberItemPerPageOptions.add(new SelectOption('100', '100'));
                buildNoteWrapper();
                
                this.IsPostBack = false;
            } catch (Exception e){
                ApexPages.addMessages(e);
            }
        }
    }
    
    public void buildNoteWrapper () {
        this.RecordCounter = 0;
        List<Note> temp = GetListNote();
        NoteWrapperList = new List<NoteWrapper>();
            
        for(Note note: temp){
            NoteWrapperList.Add(new NoteWrapper(recordCounter++, note, true));
        }
    }
    
    private List<Note> GetListNote () { 
        if(this.NotePagingInfo == null){
	        this.NotePagingInfo = 
	        	new PagingInfo('NotePagingInfo')
	        	.QFrom('Note')
	        	.QSelect(new string[]{'Title','Body','Owner.Name','LastModifiedDate'})
	        	.QWhere('ParentId=\'' + LineItemId + '\'')
	        	.QOrderByAsc('LastModifiedDate');
        }
        return this.NotePagingInfo.ToList();
    }
    
    private Note GetNote(String Id) {
        return [SELECT Title, Body, Owner.Name, LastModifiedDate 
            	FROM Note WHERE Id=:Id LIMIT 1];
    }
    public void Sort(){
    	if(ApexPages.CurrentPage().GetParameters().Get('orderDirection') == 'ASC'){
    		this.NotePagingInfo.QOrderByAsc(ApexPages.CurrentPage().GetParameters().Get('orderBy'),true);
    	}
    	else{
    		this.NotePagingInfo.QOrderByDesc(ApexPages.CurrentPage().GetParameters().Get('orderBy'),true);
    	}
    	
    	buildNoteWrapper();
    }
    public void btnAddRow_Click(){
        Note note = new Note(ParentId=LineItemId);
        if (NoteWrapperList.size() > 0) {
            NoteWrapperList.Add(0,new NoteWrapper(recordCounter++, note, false,true));
        } else {
        	NoteWrapperList.Add(new NoteWrapper(recordCounter++, note, false,true));
        }
    }
    
    public void btnEditRow_Click(){
        Integer editId = Integer.valueOf(ApexPages.CurrentPage().GetParameters().Get('editId'));
        for (NoteWrapper item : NoteWrapperList) {
            if (item.Id == editId) {
                item.isEdit = true;
                break;
            }
        }
    }
    
    public void btnDelRow_Click(){
        Integer delId = Integer.valueOf(ApexPages.CurrentPage().GetParameters().Get('delId'));
        for (Integer i = 0; i < NoteWrapperList.size(); i++) {
            NoteWrapper item = NoteWrapperList.get(i);
            if (item.Id == delId) {
                try {
                    delete item.note;
                } catch (Exception e){
                    ApexPages.addMessages(e);
                    return;
                }
                NoteWrapperList.remove(i);
                break;
            }
        }
    }
    
    public void btnSaveRow_Click(){
        Integer saveId = Integer.valueOf(ApexPages.CurrentPage().GetParameters().Get('saveId'));
        for (NoteWrapper item: NoteWrapperList) {
            if (item.Id == saveId) {
                try {
                    upsert item.note;
                } catch (Exception e){
                    ApexPages.addMessages(e);
                    return;
                }
                item.note = GetNote(item.note.Id);
                item.IsExist = true;
                item.IsEdit = false;
                break;
            }
        }
    }
    public void btnCancelRow_Click(){
        Integer cancelId = Integer.valueOf(ApexPages.CurrentPage().GetParameters().Get('cancelId'));
        for (Integer i = NoteWrapperList.size() - 1; i >= 0; i--) {
            NoteWrapper item = NoteWrapperList.get(i);
            if (item.Id == cancelId) {
                if (item.IsExist) {
                    item.note = GetNote(item.note.Id);
                    item.isEdit = false;
                } else {
                	NoteWrapperList.remove(i);
                }
                break;
            }
        }
    }
    public class NoteWrapper {
        public Integer Id {get;set;}
        public Note note{get;set;}
        public boolean IsExist{get;set;}
        public boolean IsEdit{get;set;}
        
        public NoteWrapper(integer idCounter, Note note, boolean isExist) {
            this(idCounter, note, isExist, false);
        }
        public NoteWrapper(integer idCounter, Note note, boolean isExist, boolean isEdit){
            this.Id = idCounter;
            this.note = note;
            this.IsExist = isExist;
            this.IsEdit = isEdit;
        }
    }
}