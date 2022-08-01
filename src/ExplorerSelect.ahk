/*
    ExplorerSelect.ahk

    Runs an arbitrary path in a new explorer window.

    Purpose: Wrapper for explorer that can open both files and folders. By default, if you try running explorer with a file as input, it will open the file isntead of selecting it in explorer.

    @A_Args 1) Path to open. Environment variables are ok.
*/
#SingleInstance, Force
#NoEnv
#Include %A_LineFile%\..\Util.ahk

ExplorerSelect()

ExplorerSelect() {
    explore:= ConvertPathToExplorerCommand(A_Args[1])
    run, %explore%
}

ConvertPathToExplorerCommand(path) {
    path:= ExpandEnvironmentVariables(path)
    if (!FileExist(path)) {
        return
    }
    SplitPath, path,,, ext,,
    return (ext) ? ((ext = "lnk") ? "" path "" :  "explorer /select, " path) : "explorer " """" path """"
}