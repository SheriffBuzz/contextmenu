
#Include %A_LineFile%\..\..\..\Util.ahk
#Include %A_LineFile%\..\..\Constants.ahk

/*
        WriteDefaultOpenAction

        Creates a new shell action to be used as default. changes filetype default key from blank to "open" or the name of the default action.

        Purpose - after user choice is unhooked, filetype most likely wont have any default open action. You can still open the ext using another context menu entry, but double clicking the file in file explorer will either bring up the menu of associated programs, or throw an error (non standard file ext's that havent been opened in any program before)

        @param actionKeyOrCommand - registry key in HKCR\{extension}\shell or command
        @param isCreateNewFileType - new file type will be created, unless isCreateNewFileType is false. Then the default action will be created there. Handy for some ext's that share file types (png, bmp, etc...)

        Remarks - operation overwrites any existing "open" key
                - unlinks user choice.
                - if any fileType is there already and doesnt match {ext}{FILETYPE_SUFFIX}, create a new file type. (while user choice is unlinked, we could be inadvertently changing other file ext's if they share a filetype, which we dont want. If you want multiple ext's to have the same action, it is easy to define in AllFileExt.csv with extension field accepting multiple ext's, delimited by a pipe "|". The downside is that the action is defined on multiple filetype keys, so if you wanted to change it manually in RegEdit you would need to change it in multiple places. The upside is if you only change ext's via default programs csv, then you wont need any manual registry writes and the script will alter the actions in every ext they are defined, even if there are multiple. (And also the other exts associated with the previous filetype wont be changed inadvertently)
                - if filetype is altered, it doesnt automatically create other keys (defaultIcon, shellNew) so run the other scripts again for changing ico's and new files. Does not delete old filetype (may be useful to keep it for troubleshooting)
    */
    ;        WriteDefaultOpenAction(extension, actionKeyOrCommand, isCreateNewFileType=true)

class DefaultProgramWorkflow {
    defaultParams:=

    __New() {
        this.defaultParams:= {isCreateNewFileType: true}
    }

    execute(ByRef actionContext, ByRef model) {
        extension:= model.extension
        actionKeyOrCommand:= model.actionKeyOrCommand
        isCreateNewFileType:= model.isCreateNewFileType

		DeleteUserChoice(extension) ;if you are altering a specific extension, it is assumed that user choice isn't used. set default programs and custom context menu actions.
        fileTypeName:= GetFileTypeName(extension)
        fileTypePath:= GetFileTypePath(extension)
        expectedFileTypeName:= GetExpectedFileTypeName(extension)

        if (!(fileTypeName = expectedFileTypeName) && isCreateNewFileType) { ;we dont want to add actions to other file types if the filetype is shared between exts. See remarks for more details
            createFileType(expectedFileTypeName)
            RegWrite("HKCR\" extension,, expectedFileTypeName,, true)
        }
        if (!fileTypePath) {
            model.error:="WriteDefaultOpenAction - fileType cant be resolved. If file type was passed in csv, verify that it is accurate. Otherwise, default file type should have been created"
            return
        }
        command:= getCommandForFileExtension(extension, actionKeyOrCommand)
        defaultAction:= "Open"
        if (command) {
            RegWrite(fileTypePath "\shell\",,defaultAction,, true, true)
            RegWrite(fileTypePath "\shell\" defaultAction "\command",,command,"REG_EXPAND_SZ", true, true)
            DeleteUserChoice(extension)
        }
    }
}
