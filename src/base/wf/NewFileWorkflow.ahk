
#Include %A_LineFile%\..\..\..\Util.ahk
#Include %A_LineFile%\..\..\Constants.ahk

/*
	Write new file entry

	steps done by the script: 
		make value called NullFile under HKCR\.{ext}\ShellNew
		check the default value of HKCR\.{ext}. This is the handler/proc id. For this key, add Default value as the name in the context menu, and delete the "FriendlyTypeValue" name. we add \DefaultIcon as a subkey, with ico path as default value.

		There is one more step to get the icon to work. Currently there is something caller UserChoice, that assoicates applications with a large number of file extensions. The key name is hashed and is different for each user, so for now, use FileTypeMan from Nirsoft to go to the extension, click the popup for User Choice, and click "Detatch file Type". You may get an error popup from FileTypeMan but it still works. If you attempt to set the image before doing that, it will change the ico for every file type that is associated with the program the current file type was. After you delete the association, you can double click the file type to bring up the same menu. You should not see the list of associated file types at the top. Select the icon path.
		Some file types like xml have an icon handler, in the key {procId}\ShellExtensions. Delete this key as well.

	Remarks
		- validatations are minimal on passed ext
*/
class NewFileWorkflow {
    defaultParams:=
    
    __New() {
        this.defaultParams:= {}
    }

    execute(ByRef actionContext, ByRef model) {
        extension:= model.extension
        menuDescription:= model.menuDescription
        shouldUpdateDescripton:= true

        rawExtension:= RawFileExtension(extension)
        extensionKey:= GetExtensionKey(extension)
        fileTypeName:= GetFileTypeName(extension)
        fileTypePath:= GetFileTypePath(extension)

        ;if fileType key doesnt have default prop set, newfile wont show. But only add it if it doesnt already exist
        expectedFileTypeName:= GetExpectedFileTypeName(extension)
        if (!(expectedFileTypeName = fileTypeName)) {
            fileTypeDefaultName:= RegRead(fileTypePath)
            if (fileTypeDefaultName) {
                shouldUpdateDescripton:= false
            }
        }

        shellNewPath:= GetExtensionKey(extension) "\ShellNew"
        RegWrite(shellNewPath, "NullFile",,, true, true)

        if (RegRead(fileTypePath, "FriendlyTypeName")) {
				RegDelete, %fileTypePath%, FriendlyTypeName
		}
        
        if (shouldUpdateDescripton) {
            if (!menuDescription) {
                ;TODO allow user to pass format options
                extensionLength:= StrLen(rawExtension)
                menuDescription:= (extensionLength <= 3) ? (StringUpper(rawExtension) " File") : (StringUpper(rawExtension, true) " File")
            }
            RegWrite(fileTypePath,, menuDescription,, true, true)
        }
    }
}
