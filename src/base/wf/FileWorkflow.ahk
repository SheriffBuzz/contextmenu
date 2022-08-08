
#Include %A_LineFile%\..\..\..\Util.ahk
#Include %A_LineFile%\..\..\Constants.ahk
#Include %A_LineFile%\..\WorkflowUtil.ahk
#Include %A_LineFile%\..\..\..\logging\PSRLogger.ahk


class FileWorkflow {
    defaultParams:=
    
    __New() {
        this.defaultParams:= {keyPath: REGISTRY_KEY_FILE}
    }

    beforeExecute(ByRef actionContext, ByRef models="") {
        for i, model in actionContext.getModelsForWrite() {
            extension:= model.extension
            userChoice:= model.userChoice
            
            keyName:= model.keyName
            keyPath:= model.keyPath
            fileType:= model.fileType
            
            errors:= []
            if (userChoice) {
                userChoice:= resolveUserChoice(userChoice)
                model.keyPath:= StrReplace(keyPath, "*", userChoice)
                if (extension) {
                    errors.push("Both UserChoice and extension were given. Menu will be written to ""HKCR\" userChoice """ instead of ""HKCR\" getFileTypeName(extension) """")
                }
                if (fileType) {
                    errors.push("Both UserChoice and fileType were given. Menu will be written to ""HKCR\" userChoice """ instead of " """HKCR\" fileType """")
                }
            } else if (fileType) {
                model.keyPath:= StrReplace(keyPath, "*", fileType)
                if (extension) {
                    errors.push("Both fileType and ext were given. Menu will be written to ""HKCR\" fileType " instead of " """HKCR\" getFileTypeName(extension) """")
                }
            } else {
                if (extension) {
                    fileType:= (fileType) ? updateFileType(extension, fileType) : CreateOrUpdateFileType(extension, true)
                    DeleteUserChoice(extension) ;if you are altering a specific extension, it is assumed that user choice isn't used. set default programs and custom context menu actions.
                    model.keyPath:= StrReplace(keyPath, "*", fileType)
                }
            }
            if (errors.count() > 0) {
                model.error:= CombineArray(errors, "`n")
            }
        }
    }

    execute(ByRef actionContext, ByRef model) {
        ;psrLogger.enter("FileWorkflow", A_ThisFunc)
        WorkflowUtil.executeFileOrFolder(actionContext, model)
        ;psrLogger.exit("FileWorkflow", A_ThisFunc)
    }
}
