#Include %A_LineFile%\..\..\Util.ahk
#Include %A_LineFile%\..\ContextMenuWriteWorkflow.ahk
#Include %A_LineFile%\..\ContextMenuCsvConfigValidator.ahk
#Include %A_LineFile%\..\Model.ahk


/*
    ContextMenuWriteAction

    Store info for each write type, that determines which csv files it pulls from, registry keys, etc..
*/

class ContextMenuWriteActionClass {
    __New(writeType, defaultCfg) {
        this.workingDirectory:= ""
        this.writeType:= writeType
        this.registryPath:= ""
        this.fileInfosForWrite:= [] ;filepaths of csv files
        this.csvHeader:= []
        this.csvConfig:= [] ;cfg data from 1 or more files
        this.csvConfigMetadataByRowIdx:= [] ; maintain map of row idx to config. Later along in the pipeline we need access to which csv file and row the data came from for giving relevant error msg. Alternative would be store each csv cell as an object and maintain cfg there.
        this.modelsForWrite:= []
        this.modelsForDelete:= [] ;Delete action only
        this.result:= "" ;return value
        this.successModels:= []
        this.sessionContext:=
        this.resourceRequest:= {} ;copy of a resourceRequest with write type to be applied
        this.subMenuHandles:= {} ;delete action, used to skip deleting parent SubMenus if the child menu item was excluded from delete based on resource request exclude paths
    }

    loadForWrite(ByRef errors) {
		this.setResourceRequest(this.getSessionContext().getResourceRequestCopy())
		this.loadFileInfosForWrite()
		loadErrors:= this.loadCsvDataForWrite()
		if (loadErrors.count() > 0) {
			ArrayAddAll(errors, loadErrors)
			return
		}
		this.loadModelsForWrite()
	}

    /*
        loadFileInfosForWrite

        Get the csv files associated with our write type.
        @param resourceRequest - not ByRef - we mutate the request by setting a write type. in future this should be avoided
    */
    loadFileInfosForWrite(isForDelete=false) {
        this.resourceRequest.isForDelete:= isForDelete
        this.fileInfosForWrite:= this.getSessionContext().getResourceManager().GetActionCsvFileInfosByResourceRequest(this.resourceRequest)
    }

    /*
        loadCsvDataForWrite

        Loads csv data from one or more files, and merges them into a single collection.
        -Calls this.processCsvHeader and this.addCsvConfigRow to process each csv file.
        @return errors
    */
    loadCsvDataForWrite() {
        errors:= []
        ;read csv 1 or more csv files per action and merge the rows
		for j, fileInfo in this.getFileInfosForWrite() {
            actionCsvCfgPath:= fileInfo.filePath
			FileRead, csv, %actionCsvCfgPath%
			headerAndData:= csvToHeaderAndData(csv, true)
			csvData:= headerAndData.data
			csvHeader:= headerAndData.header
			error:= this.processCsvHeader(csvHeader)
			if (error) {
				error.where:= actionCsvCfgPath
				errors.push(error)
				continue
			}
			for k, row in csvData {
				error:= this.addCsvConfigRow(row, fileInfo, k)
				if (IsObject(error)) {
					error.where:= actionCsvCfgPath
					error.rowNum:= k
					errors.push(error)
					continue
				}
			}
		}
        return errors
    }

    /*

        LoadModelsForWrite

        Translate csv into object, apply default params.
        - If the model has the field "Extension", then explode it into multiple models, that all have single extension each
    */
    loadModelsForWrite() {
        csvHeader:= this.csvHeader
        modelsForWrite:= this.modelsForWrite
        writeType:= this.writeType
        wfHelper:= this.getSessionContext().getWorkflowService().getWorkflowHelper(writeType)

        for i, row in this.csvConfig {
            model:= this.csvRowToModel(row, csvHeader)
            model.applyDefaults(wfHelper.defaultParams)

            metadata:= this.csvConfigMetadataByRowIdx[i]

            ;explode models based on extension field, pipe delimited extensions.
            if (model.extension) {
                extensionsSplit:= StrSplit(model.extension, "|")
                for j, extension in extensionsSplit {
                    clone:= model.clone() ; params is single level object, so no risk of shallow copied objects
                    clone.extension:= FullFileExtension(extension)
                    clone.setMetadata(metadata)
                    this.getModelsForWrite().push(clone)
                    
                }
            } else {
                model.setMetadata(metadata)
                this.getModelsForWrite().push(model)
            }
        }
    }

    /*
        addCsvConfigRow
        
        adds csvConfigRow if validation is successful.
        @param csvRow
        @param fileInfo
        @param rowNum - metadata for error handling. optional
        @return errorDef ContextMenuCsvConfigErrorDef
    */
    addCsvConfigRow(ByRef csvRow, fileInfo="", rowNum="") {
        errorDef:= this.getCsvConfigValidator().validateCsvRow(this.writeType, csvRow)
        if (errorDef) {
            return errorDef
        }
        this.csvConfig.push(csvRow)
        this.csvConfigMetadataByRowIdx[this.csvConfig.MaxIndex()]:= {filePath: fileInfo.filePath, rowNum: rowNum, module: fileInfo.module}
    }

    processCsvHeader(ByRef csvHeader) {
        errorDef:= this.getCsvConfigValidator().validateCsvHeader(this, csvHeader)
        if (errorDef) {
            return errorDef
        }
        this.csvHeader:= csvHeader
    }

    csvRowToModel(ByRef row, ByRef header) {
        obj:= new ModelClass()
        for j, cell in row {
            if (!(cell = "")) {
                columnName:= header[j]
                obj[columnName]:= cell
            }
        }
        return obj
    }

    setModelsForWrite(ByRef arr) {
        this.modelsForWrite:= arr
    }

    getModelsForWrite() {
        return this.modelsForWrite
    }
    /*
        add copy of model for delete. (No ByRef)
    */
    addModelForDelete(model) {
        this.modelsForDelete.push(model)
    }
    addModelForWrite(model) {
        this.modelsForWrite.push(model)
    }
    getModelsForDelete() {
        return this.modelsForDelete
    }
    setSessionContext(ByRef sessionContext) {
        this.sessionContext:= sessionContext
    }
    getSessionContext() {
        return this.sessionContext
    }
    setWorkingDirectory(ByRef dir) {
        this.workingDirectory:= dir
    }
    setSubMenuHandles(ByRef subMenuHandles) {
        this.subMenuHandles:= subMenuHandles
    }
    getSubMenuHandles() {
        return this.subMenuHandles
    }
    /*
        copy of global resource request, which will be mutated with write level info
        @Param template - not ByRef
    */
    setResourceRequest(template) {
        this.resourceRequest:= template
        this.resourceRequest.writeType:= this.writeType
        this.resourceRequest.action:= this
    }
    getResourceRequest() {
        return this.resourceRequest
    }
    getFileInfosForWrite() {
        return this.fileInfosForWrite
    }
    getCsvConfig() {
        return this.csvConfig
    }
    getCsvConfigValidator() {
        return this.getSessionContext().getCsvConfigValidator()
    }

    /*
        getSuccessModels

        models are added here after each model is processed in WriteWorkflow executeWorkflow
        This makes sure models are only marked success if they finish processing. If a model breaks the enitre workflow loop, the rest of the models might not have an error set.
    */
    getSuccessModels() {
        return this.successModels
    }

    findFirstErrorModel() {
        for i, model in this.modelsForWrite {
            if (model.error) {
                return model
            }
        }
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
