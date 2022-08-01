#SingleInstance, Force

global WORKING_DIRECTORY:= GetWorkingDirectory()
#Include %A_LineFile%\..\src\base\Constants.ahk

#Include %A_LineFile%\..\src\Util.ahk
#Include %A_LineFile%\..\src\base\ContextMenuResourceManager.ahk
#Include %A_LineFile%\..\src\base\ContextMenuWriteAction.ahk
#Include %A_LineFile%\..\src\FolderContents.ahk

/*
	WriteContextMenu

	IMPORTANT! This script must be run as administrator to reflect registry changes
	This file automates writes the registry to set context menu items. This script contains a directory structure as follows

	./WriteContextMenu.ahk
	./bin - Compiled Authotkey scripts that do custom behavior instead of just opening a program
	./resoucres
		- ./ico - icons if not specified in input csv. If no icon specified or not an ico file in this dir, we will attempt to use the ico of the exe being invoked as the command
		- 
	./src - Source ahk scripts.

	Remarks 
		- Environment variables are supported. All registry keys are stored as expandable string. They could be expanded from ahk with ddl, but leaving it alone so they wont break if someone were to export the registry keys and use them on a different machine.
		-All keys are written as expandable string, so wont be able to use if the key value is dWord.
		-Keys arent deleted, so if you change the name of an existing entry, you will have to delete the old one manually with regedit. Existing values of a key can be updated if the key name itself isnt changing.
		-The effects of registry writes are immediate, however regedit does not update right away if a key was changed from ahk, so close either close and reopen regedit or press F5 to refresh.
		-If the command has no arguments (it is a plain filepath leading to an exe or other executable file, quoted is fine) then inject %1 as a parameter. This refers to the current file or folder the context menu item was invoked on.
*/

;TODO
/*
	getWorkingDirectory
	We want to refer to current working directory, but Functions like FileExist dont resolve paths like #Include does. Include allows you to do %A_LineFile%\.. to refere to current directory.
	if current file is C:\some\full\path\WriteContextMenu.ahk, it will return C:\some\full\path
	;https://www.autohotkey.com/docs/commands/SplitPath.htm
*/
GetWorkingDirectory() {
	SplitPath, A_LineFile,, dir
	return dir
}

WriteContextMenu()
WriteContextMenu() {
	writeType:= (A_Args[1]) ? A_Args[1] : WRITE_TYPE_ALL

	defaultCfg:= {}
	defaultCfg.suppressErrorMessages:= false
	ContextMenuWriteSession:= new ContextMenuWriteSessionClass(WORKING_DIRECTORY, defaultCfg)

	ContextMenuWriteSession.write(writeType)
}

/*
	ContextMenuWriteSession

	Contains all state needed to write context menus to the registry
*/
class ContextMenuWriteSessionClass {
	__New(workingDirectory, defaultCfg="") {
		if (!workingDirectory) {
			throw "ContextMenuWriteSession - constructor arg workingDirectory is null"
		}
		this.workingDirectory:= workingDirectory
		this.resourcesContents:= new FolderContentsClass(this.workingDirectory "\resources", true, true)
		this.resourceManager:= new ContextMenuResourceManagerClass(this.resourcesContents)
		
		this.actions:= new ContextMenuActionsClass()
		this.init() ;cant use foreach inside constructor against a prop

		if (IsObject(defaultCfg)) {
			this.suppressErrorMessages:= defaultCfg.suppressErrorMessages
			this.workflowService:= new ContextMenuWriteWorkflowClass(this)
		}

		this.registryPermissionError:= false ;if we get registry permission error, all write actions will probably fail. Skip additional actions and only display one error.
	}
	init() {
		for i, action in this.actions {
			action.setWorkingDirectory(this.workingDirectory)
		}
		this.workflowService.setSessionContext(this)
	}

	write(writeType) {
		errors:= []
		actionResults:= []

		filteredActions:= this.actions.getFilteredAndSortedActions(writeType)

		for i, action in filteredActions {
			actionCsvCfgPaths:= action.getEligibleResources(this.resourceManager)

			;read csv 1 or more csv files per action and merge the rows
			for j, actionCsvCfgPath in actionCsvCfgPaths {
				FileRead, csv, %actionCsvCfgPath%
				headerAndData:= csvToHeaderAndData(csv, true)
				csvData:= headerAndData.data
				csvHeader:= headerAndData.header
				error:= action.processCsvHeader(csvHeader)
				if (error) {
					error.where:= actionCsvCfgPath
					errors.push(error)
					continue
				}
				for k, row in csvData {
					error:= action.addCsvConfigRow(row, actionCsvCfgPath, k)
					if (IsObject(error)) {
						error.where:= actionCsvCfgPath
						error.rowNum:= k
						errors.push(error)
						continue
					}
				}
			}
		}
		
		this.displayErrors(errors)

		for i, action in filteredActions {
			this.workflowService.executeWorkflow(action)
			if (action.result) {
				actionResults.push(action.result)
			}
		}
		this.displayErrors(this.workflowService.errors)
		this.displayErrors(actionResults)
	}

	displayErrors(errors) {
		;hack to make msgbox wider, useful for displaying long file paths
		title:= "-----------------------------------------------------------------------------------------------------------------------------"
		for i, error in errors {
			if (this.suppressErrorMessages) {
				break
			}
			if (error.getMessage) {
				ref:= ObjBindMethod(error, "getMessage")
				msg:= ref.call()
				Msgbox,, %title%, % error.class "`n`n" ((msg) ? msg : error.getMessage)
			} else {
				Msgbox,, %title%, % error
			}
		}
	}
}
class ContextMenuActionsClass {
	__New() {
		this.actions:= [] ;array order determines which will run first for writeType All
		this.actions.push(new ContextMenuWriteActionClass("SubMenu", "SubMenu"))
		this.actions.push(new ContextMenuWriteActionClass("File", "File"))
		this.actions.push(new ContextMenuWriteActionClass("Directory", "Directory"))
		this.actions.push(new ContextMenuWriteActionClass("Background", "Background"))
		this.actions.push(new ContextMenuWriteActionClass("DefaultProgram", "DefaultProgram"))
		this.actions.push(new ContextMenuWriteActionClass("Icon", "Icon"))
		this.actions.push(new ContextMenuWriteActionClass("NewFile", "NewFile"))
	}

	getFilteredAndSortedActions(writeType) {
		filtered:= []
		if (writeType = WRITE_TYPE_ALL) {
			filtered:= this.actions
		} else {
			for i, action in this.actions {
				if (action.writeType = writeType) {
					filtered.push(action)
				}
			}
		}
		return filtered
	}
}
