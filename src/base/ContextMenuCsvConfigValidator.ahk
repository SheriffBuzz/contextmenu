class ContextMenuCsvConfigValiator {
    __New() {
        this.expectedColCount:= {}
        this.cols:= {}
        this.init(this.cols, this.expectedColCount)
    }

    init(ByRef cols, ByRef expectedColCount) { ;avoid having to use this param on every entry
        cols.file:= "KeyName,Command,IconLocation,DisplayName,Extension,UserChoice,FileType"
        cols.directory:= "KeyName,Command,IconLocation,DisplayName"
        cols.background:= "KeyName,Command,IconLocation,DisplayName"
        cols.newFile:= "extension,menuDescription"
        cols.icon:= "extension,IconLocation"
        cols.defaultProgram:= "Extension,actionKeyOrCommand,isCreateNewFileType"
        cols.subMenu:= "KeyShorthand,DisplayName,IconLocation"
        cols.delete:= "WriteTypes"

        
        for key, val in cols {
            splitVal:= StrSplit(val, ",") ;simple comma parse, above headers shouldnt have comma or quotes. (Its fine in the actual csv)
            expectedColCount[key]:= splitVal.count()
        }
    }

    /*
        validateCsvRow

        @return error, otherwise do nothing
    */
    validateCsvRow(writeType, csvRow) {
        validCsvConfig:= []
        msg:= ""
        
        columnCount:= csvRow.count()
        if (columnCount = this.expectedColCount[writeType]) {

        } else {
            errorMessage:= "Invalid number of columns. Expected: " this.expectedColCount[writeType] " Actual: " columnCount
            errorDef:= new ContextMenuCsvConfigErrorDefClass(errorMessage, csvRow)
            return errorDef
        }
    }

    /*
        validateCsvHeader
        
        @param action
        @param csvHeader - simple arr
    */
    validateCsvHeader(ByRef action, ByRef csvHeader) {
        writeType:= action.writeType
        expectedStr:= this.cols[writeType]
        expected:= StrSplit(expectedStr, ",")
        actual:= csvHeader        
        if (actual.count() != expected.count()) {
            msg:= "CsvHeader row column count does not match expected count."
            msg.= "`n"
            msg.= "Actual: " actual.count() " Expected: " expected.count()
            msg.= "`n"
            msg.= "Expected header: " expectedStr
            return new ContextMenuCsvConfigErrorDefClass(msg)
        }
        for i, expectedCell in expected {
            actualCell:= actual[i]
            if (!(actualCell = expectedCell)) {
                msg:= "CsvHeader column name does not match expected column name. As an extra layer of protection when writing to the registry, columns must match.`n`n"
                msg.= "Actual: " actualCell " Expected: " expectedCell
                return new ContextMenuCsvConfigErrorDefClass(msg)
            }
        }
    }
}
