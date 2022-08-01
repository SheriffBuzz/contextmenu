#Include %A_LineFile%\..\..\Util.ahk
#Include %A_LineFile%\..\ContextMenuWriteWorkflow.ahk
#Include %A_LineFile%\..\ContextMenuCsvConfigValidator.ahk

/*
    ContextMenuWriteAction

    Store info for each write type, that determines which csv files it pulls from, registry keys, etc..
*/

class ContextMenuWriteActionClass {
    __New(writeType, csvRegex:="") {
        this.workingDirectory:= ""
        this.writeType:= writeType
        this.csvRegex:= csvRegex
        this.registryPath:= ""
        this.csvHeader:= []
        this.csvConfig:= [] ;cfg data from 1 or more files
        this.csvConfigMetadataByRowIdx:= [] ; maintain map of row idx to config. Later along in the pipeline we need access to which csv file and row the data came from for giving relevant error msg. Alternative would be store each csv cell as an object and maintain cfg there.
        this.csvConfigValidator:= new ContextMenuCsvConfigValiator()
        this.modelsForWrite:= []
        this.defaultParams:= {}
        this.result:= "" ;return value
    }

    setWorkingDirectory(dir) {
        this.workingDirectory:= dir
    }

    /*
        getEligibleResources

        Get the csv files associated with our write type.
        @param resourceManager - ContextMenuResourceManager
        @param array of csv file paths
    */
    getEligibleResources(ByRef resourceManager) {
        return resourceManager.GetActionCsvFilePathsByWriteType(this.writeType)
    }

    /*
        addCsvConfigRow
        
        adds csvConfigRow if validation is successful.
        @param csvRow
        @param filePath - metadata for error handling. optional.
        @param rowNum - metadata for error handling. optional
        @return errorDef ContextMenuCsvConfigErrorDef
    */
    addCsvConfigRow(ByRef csvRow, filePath="", rowNum="") {
        errorDef:= this.csvConfigValidator.validateCsvRow(this, csvRow)
        if (errorDef) {
            return errorDef
        }
        this.csvConfig.push(csvRow)
        this.csvConfigMetadataByRowIdx[this.csvConfig.MaxIndex()]:= {filePath: filePath, rowNum: rowNum}
    }

    processCsvHeader(ByRef csvHeader) {
        errorDef:= this.csvConfigValidator.validateCsvHeader(this, csvHeader)
        if (errorDef) {
            return errorDef
        }
        this.csvHeader:= csvHeader
    }

    getCsvConfig() {
        return this.csvConfig
    }

    /*
        getSuccessModels

        return copy of modelsForWrite, where !model.error
    */
    getSuccessModels() {
        successModels:= []
        for i, model in this.modelsForWrite {
            if (!model.error) {
                successModels.push(model)
            }
        }
        return successModels
    }
}

class ContextMenuCsvConfigErrorDefClass {
    __New(message, ByRef csvRow="") {
        this.csvRow:= csvRow
        this.message:= message
        this.where:= ""
        this.class:= "CsvConfigValidationError"
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


