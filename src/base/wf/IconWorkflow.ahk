
#Include %A_LineFile%\..\..\..\Util.ahk
#Include %A_LineFile%\..\..\Constants.ahk

/*
	writeIconEntry - writes DefaultIcon key into the handler associated witha file type. In the registry, there will be a key .{ext} under HCKR with a default value. That default value points to another key (The handler) where we set our DefaultIcon key.
	-The source of our ico will be in ./resources/ico/ext with file named {ext}.ico. Run this script again if this containing folder moves locations.
	-TODO this is similar to new file method, merge these
	-Removed functionality to delete the entry. If you want to change the ico, use FileTypeMan or delete the registry entries from regedit. Must edit the user choice first in FileTypeMan if you change the ico there, otherwise it will change the ico for all the associated apps with its controlling user choice program. Using this script will not change the icon for the other file types in the user choice.
	-remarks - you may need to remove user choice from fileTypeMan, then run the script. It overrides this config if some other application has said that it is controlling this file type.
		- (eg. lots of icons for text files are defaulted to np++ when you install it)
*/
class IconWorkflow {
    defaultParams:=
    
    __New() {
        this.defaultParams:= {add: true, deleteShellExtensions: true}
    }

    execute(ByRef actionContext, ByRef model) {
        extension:= model.extension
        add:= model.add
        deleteShellExtensions:= model.deleteShellExtensions
        icon:= model.icon

        rawExtension:= RawFileExtension(extension)
        extensionKey:= GetExtensionKey(extension)
        fileType:= GetFileTypeName(extension)
        fileTypePath:= GetFileTypePath(extension)
        expectedFileTypeName:= GetExpectedFileTypeName(extension)

        if (!fileType) {
            model.error:= "Filetype not set for extension """ FullFileExtension(extension) """. Set the default key under " GetExtensionKey(extension) " to " expectedFileTypeName " and create key HKCR\" expectedFileTypeName
            return
        }

        if (!(expectedFileType = fileType)) {
            ;TODO throw an error/warning to the user if the filetype doesnt match. Find a way to allow certain extensions (eg. .ahk by default filetype is autohotkey instead of ahkfile), or maybe only check for common system file types (images)
        }

        iconKey:= "HKCR\" fileType "\DefaultIcon"

        if (add) {		
            ;icon
            iconResourcePath:= (icon) ? locateIconPath(icon) : locateIconPath(extension)
            if (iconResourcePath) {                
                previousIcon:= RegRead(iconKey)
                previousIconBackup:= RegRead(iconKey, "_Default")
                
                RegWrite, REG_EXPAND_SZ, %iconKey%,, %iconResourcePath%
                if (!previousIconBackup) {
                    RegWrite, REG_SZ, %iconKey%, _Default, %previousIcon%
                }
            } else {
                TrayTip, WriteNewFileEntry, % "Icon not set, checked " iconResourcePath
            }

            shellExtensionsValue:= RegRead(fileTypePath, "ShellExtensions")
            if (shellExtensionsValue && deleteShellExtensions) {
                RegDelete, % fileTypePath "\ShellExtensions",
            }
        } else {
            ;Not supported, use FileTypeMan
        }
    }

    onExecute(ByRef actionContext, ByRef successModels) {
        if (successModels.count() > 0) {
            Run, % WORKING_DIRECTORY "\bin\ShChangeNotify.exe"
        }
    }
}
