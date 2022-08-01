#Include %A_LineFile%\..\CsvAwareWorkflowError.ahk

#Include %A_LineFile%\..\wf\BackgroundWorkflow.ahk
#Include %A_LineFile%\..\wf\DefaultProgramWorkflow.ahk
#Include %A_LineFile%\..\wf\DirectoryWorkflow.ahk
#Include %A_LineFile%\..\wf\FileWorkflow.ahk
#Include %A_LineFile%\..\wf\IconWorkflow.ahk
#Include %A_LineFile%\..\wf\NewFileWorkflow.ahk
#Include %A_LineFile%\..\wf\SubMenuWorkflow.ahk

/*
    ContextMenuWriteWorkflow

    each method has following params:
    @param ContextMenuWriteSession sessionContext
    @param ContextMenuWriteAction actionContext
*/
class ContextMenuWriteWorkflowClass {

    __New(ByRef ContextMenuWriteSession) {
        this.session:= contextMenuWriteSession
        this.errors:= []
        this.MODEL_METADATA_FIELD_NAME:= "$METADATA$"
        
        this.wfHelpers:= {}
        this.wfHelpers["Background"]:= new BackgroundWorkflow()
        this.wfHelpers["DefaultProgram"]:= new DefaultProgramWorkflow()
        this.wfHelpers["Directory"]:= new DirectoryWorkflow()
        this.wfHelpers["File"]:= new FileWorkflow()
        this.wfHelpers["Icon"]:= new IconWorkflow()
        this.wfHelpers["NewFile"]:= new NewFileWorkflow()
        this.wfHelpers["SubMenu"]:= new SubMenuWorkflow()
    }

    executeWorkflow(ByRef actionContext) {
        writeType:= actionContext.writeType
        workflowImpl:= this.wfHelpers[writeType]
        if (!(workflowImpl)) {
            return
        }
        actionContext.defaultParams:= workflowImpl.defaultParams
        this.setModelsForWrite(actionContext)
        
        if (!this.isNoDuplicateModels(actionContext)) {
            return
        }
        if (this.session.registryPermissionError) {
            return
        }
        for i, model in actionContext.modelsForWrite {
            try {
                workflowImpl.execute(actionContext, model)
                if (model.error) {
                    throw model.error
                }
            } catch e {
                msg:= ""
                if (e.what = "RegWrite") {
                    msg:= "Unexpected error on RegWrite command. Check that script is run as administrator.`n`nhttps://www.autohotkey.com/docs/commands/RegWrite.htm"
                }
                if (e.getMessage) {
                    msg.= "Detailed message:`n`n"
                    if (IsObject(e.getMessage)) {
                         msg.= e.getMesage()
                    } else {
                       msg.= e.getMesage
                    }
                } else {
                    msg.= e
                }

                we:= new CsvAwareWorkflowError(msg)

                metadata:= model[this.MODEL_METADATA_FIELD_NAME]
                if (IsObject(metadata) && (metadata.filePath || metadata.rowNum)) {
                    we.where:= metadata.filePath
                    we.rowNum:= metadata.rowNum
                }
                this.errors.push(we)

                if (e.what = "RegWrite") {
                    this.session.registryPermissionError:= true
                    break
                }
            }
        }

        ;callback section. Use Func Ref so error isnt thrown if class doesnt implement it
        onExecuteRef:= ObjBindMethod(workflowImpl, "onExecute")
        onExecuteRef.call(actionContext, actionContext.getSuccessModels())
    }

    /*
        SetModelsForWrite

        Translate csv into object, apply default params, set models on actionContext.

        @param actionContext
    */
    setModelsForWrite(ByRef action) {
        csvHeader:= action.csvHeader
        modelsForWrite:= action.modelsForWrite
        writeType:= action.writeType

        for i, row in action.csvConfig {
            params:= this.parseCsv(row, csvHeader)
            defaultParams:= action.defaultParams
            this.applyDefaults(params, defaultParams)

            metadata:= action.csvConfigMetadataByRowIdx[i]

            ;explode models based on extension field, pipe delimited extensions.
            if (params.extension) {
                extensionsSplit:= StrSplit(params.extension, "|")
                for j, extension in extensionsSplit {
                    clone:= params.clone() ; params is single level object, so no risk of shallow copied objects
                    clone.extension:= FullFileExtension(extension)
                    if (IsObject(metadata)) {
                        clone[this.MODEL_METADATA_FIELD_NAME]:= metadata
                    }
                    modelsForWrite.push(clone)
                    
                }
            } else {
                if (IsObject(metadata)) {
                    params[this.MODEL_METADATA_FIELD_NAME]:= metadata
                }
                modelsForWrite.push(params)
            }
        }
    }

    /*
        ParseCsv

        Translate csv rows of actionContext into objects
    */
    parseCsv(ByRef row, ByRef header) {
        obj:= {}
        for j, cell in row {
            columnName:= header[j]
            obj[columnName]:= cell
        }
        return obj
    }

    applyDefaults(ByRef source, defaults) {
        if (!IsObject(defaults)) {
            return source
        }
        ;use defaults as the base object and rewrite/overwrite with our actual values
        for key, val in defaults {
            sourceVal:= source[key]
            if (sourceVal = "") {
                source[key]:= val
            }
        }
    }

    setSessionContext(ContextMenuWriteSession) {
        this.sessionContext:= contextMenuWriteSession
    }

    
    isNoDuplicateModels(actionContext) {
        ; allow duplicate registry keys for acitons that accept keys, but warn the user (no error from registry writing perspective, but it may be hard for user to find out why their menu entry isnt acting as expected)
		cache:= []
        models:= actionContext.modelsForWrite
        errors:= []
        
        for i, model in models {
            cacheKey:=
            if (model.KeyName) { ;here KeyName refers to registry key name
                cacheKey.= model.KeyName "~"
                if (model.extension) {
                    cacheKey.= model.extension "~"
                }
                if (model.userChoice) {
                    cacheKey.= model.userChoice "~"
                }
            } else {
                if (model.extension) {
                    cacheKey.= model.Extension "~"
                }
            }

            if (actionContext.writeType = "SubMenu") {
                cacheKey.= model.KeyShorthand "~"
            }

            if (!cacheKey) { ;we are not validating any fields
                return true
            }

            if (IsObject(cache[cacheKey])) {
                existing:= cache[cacheKey]
                
                m1Meta:= existing[this.MODEL_METADATA_FIELD_NAME]
                m2Meta:= model[this.MODEL_METADATA_FIELD_NAME]
                if (IsObject(m1Meta) && IsObject(m2meta)) {
                    msg.= "Lines: `n"
                    msg.= "`t"m1Meta.filePath " Row " m1Meta.rowNum "`n"
                    msg.= "`t" m2Meta.filePath " Row " m2Meta.rowNum "`n"
                    msg.= "Rows are not distinguishable on these values:`n"
                    keySplit:= StrSplit(cacheKey, "~")
                    msg.= "`t" CombineArray(keySplit, ", ") "`n"
                    errors.push(msg)
                }
            } else {
                cache[cacheKey]:= model
            }
        }
        if (errors.count() > 0) {
            msgForAllErrors:= "Models are not unique from csv. This is not allowed, to avoid the user not easily knowing which context menu items will be written. Please correct and run again.`n`n"
            this.errors.push(msgForAllErrors CombineArray(errors, "`n`n"))
            return false
        }
        return true
    }
}
