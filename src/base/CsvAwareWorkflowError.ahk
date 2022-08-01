class CsvAwareWorkflowError {
    __New(message) {
        this.csvRow:= csvRow
        this.message:= message
        this.where:= ""
        this.class:= "WorkflowError"
        this.rowNum:= 0
    }

    getMessage() {
        msg:= this.class "`n`n"
        if (this.where) {
            msg.= "Error in " this.where
            if (this.rowNum) {
                msg.= "`nRow: " this.rowNum
            }
            msg.= "`n`n"
        }
        msg.= this.message
        return msg
    }
}
