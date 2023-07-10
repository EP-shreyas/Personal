trigger ContentDocument on ContentDocumentLink (after insert) {
try{
        if(Trigger.isAfter && Trigger.isInsert){
            documentRecordCreate.DocUpload(trigger.new);
        }
    }
    catch(exception ex){
        system.debug(ex.getMessage());
    }
}