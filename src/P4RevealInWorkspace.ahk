/*P4RevealInWorkspace.ahk - modifed version of P4.ahk P4RevealPathInP4WorkspaceTree with bare minimum function calls, and no includes.
Requirements:
    - P4V version is 2020.2 or later for Jump to Address Bar shortcut
    - verify shortcut in p4v. Edit -> Preferences -> shortcuts -> Jump to Address Bar. Currently using Ctrl Shift V as default using alt doesnt work properly (opens nav bar for view). Edit it in the script on line 24.
    - You must select a valid path that is open for the client view. Ie if you open for workspace branch 2.0 and select a file not under that view, you will get an error msg in p4v.
*/
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force
SetTitleMatchMode, 2
RevealPathInP4WorkspaceTree(path) {
    if (!path || path = "") {
        return
    }
    winTitle:= "Perforce Helix P4V" ; not tested that this doesnt conflict with other popup windows
    
    ;WindowUtils.ahk
    maxWaitSeconds:= 5
    WinActivate, %winTitle%
    WinWaitActive, %winTitle%,,%maxWaitSeconds%
    if (!(WinActive(winTitle))) {
        Msgbox, % "Error:" winTitle " not found, waited 5 seconds. If not checking for window active in calling code, kill the script now to avoid unintended behavior." ;TODO pass a callback function to execute when win is activated/not found
        return
    }
    Sleep, 100
    SendInput, ^+v
    Sleep, 100

    text:= path

    ;Unload(path) ClipboardUtils.ahk
	SavedClip := ClipboardAll
	Clipboard := text
	Send ^v
	Sleep, 100
	Clipboard := SavedClip ;dont need to clipwait as we arent using the clipboard

    Sleep, 5
    Send {Tab} ;inject tab to avoid rare timing edge case where cursor is stuck in address bar. If this happens, the new path will be appended to the old creating an invalid workspace path. Tabing to the next control (bookmark) is fine since user will not be using tabs immediately, they would most likely be clicking a file in workspace view with the mouse and dragging it to a specific cl
}

RevealPathInP4WorkspaceTree(A_Args[1])
