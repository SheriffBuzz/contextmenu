/*
	OpenInEclipseWorkspace -
	
	This script allows you to open a file in eclipse or similar ecosystem from the context menu, where the file is in a workspace. It is useful when the application takes
	a significant amount time to start up, or is not set up to view files outside of its workspace.
	
	Instead of running the program's exe, it activates an already running window with WinActive and sends Ctrl Shift R (Open resource). Then the user just has to press Enter
	to open the file. This script does not auto press enter, so they can confirm the correct file to open, in case multiple files with the same name
	exist inj the workspace.
*/
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
ContextMenuMain() { ;avoid polluting global scope. TODO come up with a standard to avoid this going forward (encountered when including other files, which script is growing in complexity. Especially for loop indexes)
	SetTitleMatchMode, 2
	FileName:= A_Args[1]
	Msgbox, % "v param: " A_Args[1]
	Arr:= StrSplit(FileName, "`\", "`r")
	Idx:= Arr.MaxIndex()
	Part:= Arr[Idx]
	winTitle:= A_Args[2]
	ActivateApplicationAndWait(winTitle)
	if (WinActive(winTitle)) {
		Send, ^+r
		sleep, 10
		Send, %Part%
	}
}

;Lib/WindowUtils.ahk
ActivateApplicationAndWait(winTitle, maxWaitSeconds=5) {
	WinActivate, %winTitle%
	WaitForApplicationActive(winTitle)
}
;Lib/WindowUtils.ahk
WaitForApplicationActive(ByRef winTitle, maxWaitSeconds=5) {
	WinWaitActive, %winTitle%,,%maxWaitSeconds%
	if (!(WinActive(winTitle))) {
		Msgbox, % "OpenInEclipseWorkspace - Error: window with title""" winTitle """ not found, waited 5 seconds.
	}
}
ContextMenuMain()
