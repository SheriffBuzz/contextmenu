#NoEnv
#SingleInstance, Force

global WORKING_DIRECTORY:= GetWorkingDirectory()
#Include %A_LineFile%\..\src\base\Constants.ahk
#Include %A_LineFile%\..\src\Util.ahk
#Include %A_LineFile%\..\src\base\ContextMenuWriteSession.ahk
#Include %A_LineFile%\..\src\base\ResourceRequest.ahk
#Include %A_LineFile%\..\src\json\JXON.ahk

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
	if (A_IsCompiled) { ;HACK ;assuming if our program is compiled is in \bin
		SplitPath, dir,, dir
	}
	SetWorkingDir, %dir% ;needed by WriteFileOrFolder. Edge case where script "command" key has the same name as the local filepath in \bin (HotswapContextMenu.exe)
	return dir
}
;Arguments are required for this script. By checking if args are present, we can call the main method or not. This gives the option to call either via cmd args, or #Include and call the function directly
if (A_Args.count() > 0) { 
	WriteContextMenu()
}

WriteContextMenu() {	
	writeType:= A_Args[1]
	resourcesPathPatterns:= []
	i:= 2
	while (i <= A_Args.MaxIndex()) {
		resourcesPathPatterns.push(A_Args[i])
		i:= i + 1
	}
	resourceRequest:= {}
	resourceRequest.includes:= resourcesPathPatterns
	WriteContextMenuMain(writeType, resourceRequest)
}
WriteContextMenuMain(writeType, resourceRequest) {
	global defaultCfg ;scripts that #Include this one can set cfg directly
	writeType:= (writeType) ? writeType : WRITE_TYPE_ALL
	;Debug
	;writeType:= "Delete"
	;writeType:= "SubMenu|Directory|Background"
	;writeType:= "SubMenu"
	;resourcesPathPatterns.push("/")
	;resourcesPathPatterns.push("one")
	;Debug
	if (!IsObject(defaultCfg)) {
		;defaultCfg that might be set in external cfg goes here.
		defaultCfg:= {}
	}
	logger.setLogLevel(defaultCfg.logLevel)

	;defaultCfg that isnt in external cfg goes here
	defaultCfg.resourceRequest:= new ResourceRequestClass(resourceRequest)
	defaultCfg.workingDirectory:= WORKING_DIRECTORY
	ContextMenuWriteSession:= new ContextMenuWriteSessionClass(defaultCfg)

	ContextMenuWriteSession.write(writeType)
}

