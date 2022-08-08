#Include %A_LineFile%\..\CsvAwareWorkflowError.ahk

#Include %A_LineFile%\..\wf\BackgroundWorkflow.ahk
#Include %A_LineFile%\..\wf\DefaultProgramWorkflow.ahk
#Include %A_LineFile%\..\wf\DirectoryWorkflow.ahk
#Include %A_LineFile%\..\wf\FileWorkflow.ahk
#Include %A_LineFile%\..\wf\IconWorkflow.ahk
#Include %A_LineFile%\..\wf\NewFileWorkflow.ahk
#Include %A_LineFile%\..\wf\SubMenuWorkflow.ahk
#Include %A_LineFile%\..\wf\DeleteWorkflow.ahk

/*
    ContextMenuWriteWorkflow

    each method has following params:
    @param ContextMenuWriteSession sessionContext
    @param ContextMenuWriteAction actionContext
*/
class ContextMenuWriteWorkflowClass {

    __New(ByRef sessionContext) {
        this.sessionContext:= sessionContext
        this.errors:= []        
        this.wfHelpers:= {}
        this.wfHelpers["Background"]:= new BackgroundWorkflow()
        this.wfHelpers["DefaultProgram"]:= new DefaultProgramWorkflow()
        this.wfHelpers["Directory"]:= new DirectoryWorkflow()
        this.wfHelpers["File"]:= new FileWorkflow()
        this.wfHelpers["Icon"]:= new IconWorkflow(sessionContext)
        this.wfHelpers["NewFile"]:= new NewFileWorkflow()
        this.wfHelpers["SubMenu"]:= new SubMenuWorkflow(sessionContext)
        this.wfHelpers["Delete"]:= new DeleteWorkflow()
    }

    executeWorkflow(ByRef actionContext) {
        writeType:= actionContext.writeType
        logger.INFO("WorkflowService ~ ExecuteWorkflow ~ Write type: " writeType)
        psrlogger.enter("WorkflowService~Execute~" writeType)
        workflowImpl:= this.wfHelpers[writeType]
        if (!(workflowImpl)) {
            return
        }
        
        if (!this.isNoDuplicateModels(actionContext)) {
            return
        }
        if (this.sessionContext.registryPermissionError) {
            return
        }

        beforeExecuteRef:= ObjBindMethod(workflowImpl, "beforeExecute")
        beforeExecuteRef.call(actionContext, actionContext.modelsForWrite)
        beforeExecuteErrorModel:= (actionContext.findFirstErrorModel())
        if (beforeExecuteErrorModel) {
            this.errors.push(this.createWorkflowModelError(beforeExecuteErrorModel))
            return
        }

        for i, model in actionContext.modelsForWrite {
            try {
                workflowImpl.execute(actionContext, model)
                if (model.error) {
                    throw model.error
                }
            } catch e {
                workflowModelError:= this.createWorkflowModelError(model, e)
                this.errors.push(workflowModelError)

                if (e.what = "RegWrite") {
                    this.sessionContext.registryPermissionError:= true
                    break
                }
            }
            actionContext.getSuccessModels().push(model)
        }

        ;callback section. Use Func Ref so error isnt thrown if class doesnt implement it
        onExecuteRef:= ObjBindMethod(workflowImpl, "onExecute")
        successModels:= actionContext.getSuccessModels()
        onExecuteRef.call(actionContext, successModels)
        if (successModels.count() < 1) {
            logger.DEBUG("No models written for write type:" writeType)
        }
        psrlogger.exit("WorkflowService~Execute~" writeType)
    }

    getWorkflowHelper(writeType) {
        return this.wfHelpers[writeType]
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
                
                m1Meta:= existing.getMetadata()
                m2Meta:= model.getMetadata()
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
            msgForAllErrors.= CombineArray(errors, "`n`n")
            logger.DEBUG(msgForAllErrors)
            this.errors.push(msgForAllErrors)
            return false
        }
        return true
    }

    createWorkflowModelError(ByRef model, error="") {
        msg:= ""
        if (!error) {
            error:= model.error
        }
        if (error.what = "RegWrite") {
            msg:= "Unexpected error on RegWrite command. Check that script is run as administrator.`n`nhttps://www.autohotkey.com/docs/commands/RegWrite.htm"
        }
        if (error.getMessage) {
            msg.= "Detailed message:`n`n"
            if (IsObject(error.getMessage)) {
                    msg.= error.getMesage()
            } else {
                msg.= error.getMesage
            }
        } else {
            msg.= error
        }

        we:= new CsvAwareWorkflowError(msg)

        metadata:= model.getMetaData()
        if (IsObject(metadata) && (metadata.filePath || metadata.rowNum)) {
            we.where:= metadata.filePath
            we.rowNum:= metadata.rowNum
        }
        return we
    }
}
