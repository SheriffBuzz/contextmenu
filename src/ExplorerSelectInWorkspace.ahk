/*
    ExplorerSelectInWorkspace.ahk

    Opens a path within the current explorer window. User can pass a "workspaceRoot" which is a partial path segment. Along with the path passed as default param to the file, you can construct a path that is relative to the workspace, based on where the context menu is triggered. This is ideal for p4, where each workspace is a similar structure for different versions of software, where the only difference is version number in the workspace root path. The user can use this to jump to important folders, regardless of the current directory is.

    Purpose:
        - Wrapper for explorer that can open both files and folders in the current view. By default, if you try running explorer with a file as input, it will open the file isntead of selecting it in explorer.
        - Alternative to quick access bar that allows relative paths. Quick access only allows absolute paths.

    Remarks
        - workspaceRegex should be unique
        - If user's path is outside the given workspace, attempt to use the last known used workspace, by storing the value in a file. This is convenient when the user does not change their workspace often as it allows us to trigger the workspace anywhere, but not still not hardcode the paths.
            - TODO store workspace for each relative path
        - If triggered from a directory, the last path segment can have a ".", Except in the case where the text following the . is a valid extension.
        - Ie C:\toolkit\CodeProject1.0.24   here SplitPath returns .24 for the ext, even though it is not a file. if the last path segment is an invalid file extension, then add it back to the path. This doesnt cover 100% scenerios, but should cover common case of a project that has version numbers.
            - Exceptions: .386 file. https://fileinfo.com/extension/386#:~:text=386%20file%20is%20a%20read,VXD%20file%20extension.
            - .git folder or any folder that is the name of an extension with a leading "."
*/
#NoEnv
#Include %A_LineFile%\..\Util.ahk
SendMode, Input
SetBatchLines, -1
global MRU_CONFIG_PATH:= A_ScriptDir "\" "ExplorerSelectMRU.config"

;ExplorerSelectInWorkspace("C:\Users\Steve\Documents", "Toolkit", "\registry\contextMenu\resources", "C:")
;ExplorerSelectInWorkspace("C:\toolkit\registry\contextmenu\src", "Toolkit", "\registry\contextMenu\resources", "C:")
ExplorerSelectInWorkspace(A_Args[1], A_Args[2], A_Args[3], A_Args[4], A_Args[5])

/*
    ExplorerSelectInWorkspace
    @param currentPath - If invoked from context menu, this will be the current directory
    @param workspaceRegex - substring (Regex not supported currently) of the workspace, where workspace is a path segment within currentPath.
    @param pathFromWorkspaceRoot - relative path from workspace root. It may include or omit the leading slash.
    @param workspaceParentDirectoryPath - optional. In the event there is an intermediate folder that workspaceRegex is a substring of, we cant determine which path segement to use as root. Passing the directory parent path (no trailing slash) allows us to match only a specific containing parent folder of our workspace.
        - The goal is to avoid the user having to pass in a full path segement instead of a regex/substring. If we did that, the caller would have to compute what the full path segment is to avoid intermediate path segment conflict.
*/
ExplorerSelectInWorkspace(currentPath, workspaceRegex, pathFromWorkspaceRoot, workspaceParentDirectoryPath="", runFile:=false) {
    workspacePath:= GetWorkspacePath(currentPath, workspaceRegex, workspaceParentDirectoryPath)
    if (!pathFromWorkspaceRoot || !workspaceRegex) {
        Msgbox, % "workspaceRegex or pathFromWorkspaceRoot is empty."
        return
    }

    mru:= ReadFileAsString(MRU_CONFIG_PATH)
    if (!workspacePath) {
        scriptDir:= A_ScriptDir
        if (mru) {
            workspacePath:= mru
        }
    }
    if (workspacePath) {
        if (!(workspacePath = mru)) {
            FileDelete, %MRU_CONFIG_PATH%
            FileAppend, %workspacePath%, %MRU_CONFIG_PATH%
        }

        if (!(InStr(pathFromWorkspaceRoot, "\") = 1)) {
            pathFromWorkspaceRoot:= "\" pathFromWorkspaceRoot
        }
        fullPath:= workspacePath pathFromWorkspaceRoot
        if (!FileExist(fullPath)) {
            TrayTip, ExplorerSelectInWorkspace, % "Path not found:`n" fullPath
            return
        }
        ExplorerSelectInCurrentWindow(fullPath, currentPath, runFile)
    }
}

GetWorkspacePath(currentPath, workspaceRegex, workspaceParentDirectoryPath) {
    SplitPath, currentPath, fullfileName, dir, ext, nameNoExt, outDrive
    dirSplit:= StrSplit(dir, "\")

    if (ext) { ;it's possible ext here is the final directory segment with a "." in it. Unlikely a well named user path has a ext as the last part of its final path segment.
        fileType:= GetFileTypeName("." ext)
        if (!fileType) {
            nameNoExt.= "." ext
            ext:= ""
        }
    }

    if (!ext && nameNoExt) {
        dirSplit.push(nameNoExt)
    }
    workspacePath:= ""

    while (dirSplit.count() > 0) {
        pathSegment:= dirSplit.Pop()
        if (InStr(pathSegment, workspaceRegex)) {
            parentPath:= CombineArray(dirSplit, "\")
            if (workspaceParentDirectoryPath) {
                if (workspaceParentDirectoryPath = parentPath) {
                    workspacePath:= parentPath "\" pathSegment
                }
            } else {
                continue
            }
            workspacePath:= parentPath "\" pathSegment
        }
    }
    return workspacePath
}

;need to use SHOpenFolderAndSelectItems
ExplorerSelectInCurrentWindow(path, currentPath="", runFile=false) {
    SplitPath, path, outPath, dir, ext, namenoext
    fileType:= GetFileTypeName("." ext)

    if (ext) {
        if (!fileType) {
            nameNoExt.= "." ext
            ext:= ""
        }
    }

    if (fileType) {
        containingfolder:= (ext) ? dir : path
    } else {
        containingfolder:= dir
    }

    if (runFile) {
        if (ext) {
            run, %path%
        }
        return
    }

    if (WinActive("ahk_exe Explorer.EXE")) {
        Send, ^l
        sleep, 20
        savedClip:= ClipboardAll
        Clipboard:=
        Clipboard:= containingfolder
        Send, ^v{Enter}
        sleep, 200
       
        if (currentPath = containingfolder) { ;if the path didnt change, then the input by default will be on the address bar not the main window. so send tabs to get to the main pane. Alternatively, we could copy the clip after pressing Ctrl+L and see if it matches our computed path.
            Send, {Tab}
            sleep, 1
            Send, {Tab}
            sleep,1
            Send, {Tab}
            Sleep, 20
        }

        if (ext) {
            SetKeyDelay, -1
            SendEvent, %nameNoExt%
        }
        Clipboard:= ClipboardAll

    } else {
        TrayTip, ExplorerSelectInWorkspace, "Open in current window - Explorer not active"
    }
}
