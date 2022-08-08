#Include %A_LineFile%\..\..\..\Util.ahk
#Include %A_LineFile%\..\..\Constants.ahk
#Include %A_LineFile%\..\WorkflowUtil.ahk
#Include %A_LineFile%\..\..\SubMenuUtil.ahk

class DeleteWorkflow {
    defaultParams:=
    
    __New() {
        this.defaultParams:= {}
    }

    /*
        execute

        The delete workflow gets the other models in the session, filters by deletable actions, and constructs the registry key to delete.

        Assumptions:
            - Other actions in the session have the field modelsForWrite set, containing a "model" (a single csv row or flatmapped row into an object where key/value mapping is csvHeader: csvValue)
            - Models of action "File" with UserChoice set have their path resolved to either HKCR\ or KHCR\Applications. This workflow does not expand the shorthand.
            - Nested sub menus should have been expanded.

        This method expects DeleteWorkflow.beforeExecute Listener transforms and flatmaps the models for delete, into a new models with just one field, writeType.
    
    */
    execute(ByRef actionContext, ByRef model) {
        writeTypeForDelete:= model.writeType ;this is the write type being deleted, not "Delete"
        sessionContext:= actionContext.sessionContext
        resourceManager:= sessionContext.resourceManager
        pathPatterns:= resourceManager.resourcesPathPatterns
        forceDeleteSubMenus:= sessionContext.isForceDeleteSubMenus()
        subMenuHandles:= actionContext.getSubMenuHandles()
        
        ;The actions in the sessionContext to delete are already processed but not executed. They should have all info set on them at this point
        actions:= sessionContext.actions.getFilteredAndSortedActions(writeTypeForDelete)
        if (actions.count() != 1) {
            model.error:= "Unable to resolve single delete action for write type: " writeTypeForDelete
            return
        }
        actionForDelete:= actions[1]
        modelsForDelete:= actionForDelete.getModelsForDelete()
        if (modelsForDelete.count() < 1) {
            return
        }

        resourceRequestForDelete:= actionForDelete.getResourceRequest()
        for i, modelForDelete in modelsForDelete {
            shouldDelete:= ArrayContains(resourceRequestForDelete.getFilePathsForDelete(), modelForDelete.getMetadata().filePath)
            if (!shouldDelete) {
                continue
            }
            
            if (writeTypeForDelete = "SubMenu") {
                if (!forceDeleteSubMenus && subMenuHandles.contains(modelForDelete.keyShortHand)) {
                    continue
                }
                segments:= StrSplit(modelForDelete.keyShortHand, "\")
                SubMenuUtil.resolveAliases(segments)
                keyForDelete:= SubMenuUtil.getFullPath(segments)
            } else if (writeTypeForDelete = "NewFile") {
                extension:= modelForDelete.extension
                shellNewPath:= GetExtensionKey(extension) "\ShellNew"
                keyForDelete:= shellNewPath
            } else {
                try { ; if action is in a nested sub menu, it may have already been deleted with the parent. ignore
                    SubMenuUtil.processNestedMenuForModel(actionForDelete, modelForDelete)
                } catch e {
                    continue
                }
                keyForDelete:= modelForDelete.keyPath "\" modelForDelete.keyName
            }
            RegDelete(keyForDelete)
        }
    }

    /*
        beforeExecute

        Unlike the other actions, we only want delete to run once per writetype. Filter them if user erroneously sends multiple between different lines in the csv, or pipe delimitation

        For each write type passed, verify it is allowed based on session context. method is getActionsForDelete()
    */
    beforeExecute(ByRef actionContext, ByRef models) {       
        adjustedModels:= []
        writeTypesByModel:= []
        metaPropName:= actionContext

        actionsForDelete:= actionContext.sessionContext.actions.getActionsForDelete()
 
        allowedWriteTypesByCsvRow:= []
        for i, model in models {
            allowedWriteTypesByCsvRow.push(this.getWriteTypes(model))
        }
        allowedWriteTypes:= this.flatMap(allowedWriteTypesByCsvRow)

        if (allowedWriteTypes.count() < 1) {
            logger.WARN("Delete - no actions passed. Make sure Delete.csv is defined in the target folder you want to delete.")
        }
        for i, actionForDelete in actionsForDelete {
            if (ArrayContains(allowedWriteTypes, actionForDelete.writeType)) {
                adjustedModels.push({writeType: actionForDelete.writeType}) ;we loose metadata field but shouldnt matter
            }
        }
        actionContext.setModelsForWrite(adjustedModels)
    }

    getWriteTypes(ByRef model) {
        writeTypes:= model.writeTypes
        if (!IsObject(writeTypes)) {
            writeTypes:= StrSplit(writeTypes, "|") ; assertion - write type doesnt have "|" in it
        }
        return writeTypes
    }

    flatMap(ByRef arr, filter="") {
        container:= []
        for i, arr2 in arr {
            for j, val in arr2 {
                if (!filter || val = filter) {
                    container.push(val)
                }
            }
        }
        return container
    }
}
