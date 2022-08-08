#Include %A_LineFile%\..\..\Util.ahk
#Include %A_LineFile%\..\ContextMenuResourceManager.ahk
#Include %A_LineFile%\..\ContextMenuWriteAction.ahk
#Include %A_LineFile%\..\..\FolderContents.ahk

/*
	ContextMenuWriteSession

	Contains all state needed to write context menus to the registry
*/
class ContextMenuWriteSessionClass {
	__New(defaultCfg) {
		if (!defaultCfg.workingDirectory) {
			throw "ContextMenuWriteSession - defaultCfg workingDirectory is required"
		}
		this.actions:= new ContextMenuActionsClass(this, defaultCfg)
		this.registryPermissionError:= false ;if we get registry permission error, all write actions will probably fail. Skip additional actions and only display one error.
		this.workingDirectory:= defaultCfg.workingDirectory
		for i, action in this.actions.actions {
			action.setWorkingDirectory(this.workingDirectory)
			action.setSessionContext(this)
		}
		this.resourcesDirectory:= this.workingDirectory "\resources"
		this.workflowService:= new ContextMenuWriteWorkflowClass(this)
		this.folderContents:= new FolderContentsClass(this.resourcesDirectory, true, true)
		this.resourceRequest:= defaultCfg.resourceRequest
		this.resourceManager:= new ContextMenuResourceManagerClass(this, this.folderContents, this.resourcesDirectory)
		this.expandEnvironmentVariables:= EXPAND_ENVIRONMENT_VARIABLES
		this.commandsToIgnoreDefaultParameter:= ["HotswapContextMenu.exe"]
		this.forceDeleteSubMenus:= (defaultCfg.forceDeleteSubMenus = "") ? false : defaultCfg.forceDeleteSubMenus ;skip submenu delete if an child menu is excluded for delete
		this.csvConfigValidator:= new ContextMenuCsvConfigValiator()

		logger.INFO("ContextMenuWriteSession created {1}", this)
	}

	getResourceManager() {
		return this.resourceManager
	}

	getWorkflowService() {
		return this.workflowService
	}

	getWorkingDirectory() {
		return this.workingDirectory
	}

	getResourceRequestCopy() {
		return this.resourceRequest.clone()
	}

	getSupportedWriteTypesForDelete() {
		return ["Background", "File", "Directory", "SubMenu", "NewFile"]
	}

	getCsvConfigValidator() {
		return this.getCsvConfigValidator
	}

	isExpandEnvironmentVariables() {
		return this.expandEnvironmentVariables
	}

	isForceDeleteSubMenus() {
		return this.forceDeleteSubMenus
	}

	write(writeType) {
		errors:= []
		actionResults:= []

		filteredActions:= this.actions.getFilteredAndSortedActions(writeType)
		
		ForEach(filteredActions, "loadForWrite", "this", errors)
		
		if (writeType = "Delete" && filteredActions.count() = 1) { ;for delete, do preprocessing so we have access to menu items we need to delete, but dont execute their workflows
			subMenuHandles:= new ISet()
			deleteAction:= filteredActions[1]
			actionsForDelete:= this.actions.getActionsForDelete()
			ForEach(actionsForDelete, "loadForWrite", "this", errors)			
			for j, actionForDelete in actionsForDelete {
				for k, modelForWrite in actionForDelete.getModelsForWrite() {
					actionForDelete.addModelForDelete(modelForWrite)
					if (actionForDelete.writeType != "SubMenu") {
						subMenuHandles.add(SubMenuUtil.getSubMenuHandle(actionForDelete, modelForWrite))
					}
				}
				actionForDelete.loadFileInfosForWrite(true) ;sets flag on resourcesRequest for fileInfosForDelete
			}
			deleteAction.setSubMenuHandles(subMenuHandles)
		}
		
		this.displayErrors(errors)

		for i, action in filteredActions {
			this.workflowService.executeWorkflow(action)
			if (action.result) {
				actionResults.push(action.result)
			}
		}
		this.displayErrors(this.workflowService.errors)
		;this.displayErrors(actionResults) ;refactor with logging service
	}

	displayErrors(errors) {
		;hack to make msgbox wider, useful for displaying long file paths
		title:= "-----------------------------------------------------------------------------------------------------------------------------"
		for i, error in errors {
			if (error.getMessage) {
				ref:= ObjBindMethod(error, "getMessage")
				msg:= ref.call()
				logger.WARN(error.class "`n`n" ((msg) ? msg : error.getMessage))
				;Msgbox,, %title%, % error.class "`n`n" ((msg) ? msg : error.getMessage)
			} else {
				logger.WARN(error)
				;Msgbox,, %title%, % error
			}
		}
	}
}
class ContextMenuActionsClass {
	__New(ByRef sessionContext, ByRef defaultCfg) {
		this.sessionContext:= sessionContext
		this.actions:= [] ;array order determines which will run first for writeType All
		this.actions.push(new ContextMenuWriteActionClass("Delete",defaultCfg))
		this.actions.push(new ContextMenuWriteActionClass("SubMenu",defaultCfg))
		this.actions.push(new ContextMenuWriteActionClass("File",defaultCfg))
		this.actions.push(new ContextMenuWriteActionClass("Directory",defaultCfg))
		this.actions.push(new ContextMenuWriteActionClass("Background",defaultCfg))
		this.actions.push(new ContextMenuWriteActionClass("DefaultProgram",defaultCfg))
		this.actions.push(new ContextMenuWriteActionClass("Icon",defaultCfg))
		this.actions.push(new ContextMenuWriteActionClass("NewFile",defaultCfg))
	}

	/*
		writeType - write type, or multiple write types, pipe delimited

		Remarks - if Delete is passed, only delete action will run. This is a safeguard to prevent unexpected behavior but may be supported in the future.
	*/
	getFilteredAndSortedActions(writeType) {
		filtered:= []
		types:= StrSplit(writeType, "|")
		if (ArrayContains(types, "Delete")) {
			for i, action in this.actions {
				if (action.writeType = "Delete") {
					filtered.push(action)
					break
				}
			}
			return filtered
		}
		if (writeType = WRITE_TYPE_ALL) {
			for i, action in this.actions {
				if (action.writeType != "Delete") {
					filtered.push(action)
				}
			}
		} else {
			for i, action in this.actions {
				if (ArrayContains(types, action.writeType)) {
					filtered.push(action)
				}
			}
		}
		return filtered
	}

	getActionsForDelete() {
		filtered:= []
		filter:= this.sessionContext.getSupportedWriteTypesForDelete()
		for i, action in this.actions {
			if (ArrayContains(filter, action.writeType)) {
				filtered.push(action)
			}
		}
		return filtered
	}
}
