#Include %A_LineFile%\..\..\..\logging\LoggingUtils.ahk

#NoEnv
/*
    FileOrFolderWriteContext

    State Management for building file, directory, background menus.

    @param isExpand - should final values for command and icon be expanded in the registry value 

    Remarks - may behave unexpectedly if NoEnv is not enabled
*/
class FileOrFolderWriteContextClass {
    __New(ByRef actionContext, ByRef model) {
        this.actionContext:= actionContext
        this.model:= model
        this.sessionContext:= this.actionContext.getSessionContext()
        this.expandEnvironmentVariables:= this.sessionContext.isExpandEnvironmentVariables()
        this.resourceManager:= this.sessionContext.getResourceManager()
        this.moduleName:= this.model.getMetadataValue("module")
        this.keyPath:= model.keyPath
        this.keyName:= model.keyName
        this.command:= model.command
        this.iconLocation:= this.getIconLocation(model.iconLocation)
        this.displayName:= (model.displayName) ? model.displayName : this.keyName
        this.shouldValidateCommand:= true

        this.commandPath ;path of the command, without arguments, stored unquoted

        this.unquotedCommandPath:=
        this.paramsStr:= "" ;stores params string as is (everything after command)
    }

    getActionContext() {
        return this.actionContext
    }
    isExpand() {
        return this.expandEnvironmentVariables
    }
    assertRequiredFields() {
        if (!this.keyName || !this.command) {
            throw "Key or command is blank"
        }
    }

    /*
        SetShouldValidateCommand

        if user is running a simple system verb, dont try to validate it    
    */
    setShouldValidateCommand() {
        this.shouldValidateCommand:= !(InStr(this.command, "rundll32") = 1 || (!InStr(this.command, ".exe") && !InStr(this.command, """")) || isEnvironmentVariable(this.command))
    }

    isShouldValidateCommand() {
        return this.shouldValidateCommand
    }

    /*
        getIconLocation

        This method is called on the constructor for the iconLocation given from csv. If not found, it is attempted to be set again from the exe in the command field.
        @param pattern see locateIconPath function
    */
    getIconLocation(pattern) {
        path:= this.resourceManager.locateIconPath(pattern, this.moduleName)
        if (!path) {
            return ""
        }
        if (this.isExpand()) {
            path:= ExpandEnvironmentVariables(path)
        } else if (isEnvironmentVariable(pattern)) {
            path:= pattern
        }
        return path
    }

    isIconLocationSet() {
        return (this.iconLocation) ? true : false
    }

    setIconLocation(iconLocation) {
        this.iconLocation:= iconLocation
    }

    isUnquotedCommandPath() {
        return this.unquotedCommandPath
    }

    getCommandPath() {
        return this.commandPath
    }

    getCommand() {
        return this.command
    }

    /*
        setCommandPath

        Attempt to set the command path, in unquoted form. Since we may need to attempt multiple paths (absolute location, \bin), take command as parameter instead of current this ref.

        Only sets commandPath if file exists, so system commands should already be filtered out.
    */
    setCommandPath(command) {
        command:= Trim(command)
        expandedCommand:= ExpandEnvironmentVariables(command) ;we dont expand or not until the end, but we need to check if the env variable contains .exe to determine if the command has an unquoted exe with quoted parameters
        
        firstQuotedSegment:= StrExtractBetween(command, """", """", false, true)
        exeIdx:= InStr(command, ".exe")
        quoteIdx:= InStr(command, """")
        quote2Idx:= InStr(command, """",, quoteIdx + 1)
        spaceIdx:= InStr(command, " ")
        startsWithQuote:= (quoteIdx = 1) ? true : false

        expandedQuoteIdx:= InStr(expandedCommand, """")
        expandedExeIdx:= InStr(expandedCommand, ".exe")

        ;system commands should be filtered out by this step

        ;command can be one environment variable that contains a full command + args, otherwise it is only a path segment without quotes or parameters
        if (isEnvironmentVariable(command)) {
            commandPath:= command
            this.paramsStr:= ""
        } else {
            if (!quoteIdx) {
                commandPath:= StrSplit(command, " ")[1]
                paramsStartIdx:= StrLen(commandPath) + 1
                this.unquotedCommandPath:= true
            } else if (quoteIdx && (expandedExeIdx < expandedQuoteIdx)) { ;unquoted exe with quoted params
                commandPath:= StrSplit(command, " ")[1]
                paramsStartIdx:= quoteIdx
                this.unquotedCommandPath:= true
            } else {
                commandPath:= StrExtractBetween(command, """", """", false, true)
                paramsStartIdx:= InStr(command, commandPath) + StrLen(commandPath)
                if (startsWithQuote) {
                    paramsStartIdx:= paramsStartIdx + 1
                    this.unquotedCommandPath:= true
                }
            }
            if (!FileExist(ExpandEnvironmentVariables(commandPath))) { ;it might be in \bin. Caller can check multiple locations
                return
            }
            this.paramsStr:= SubStr(command, paramsStartIdx)
        }
        this.commandPath:= commandPath
    }

    /*
        ShouldInjectDefaultParam
        
        inject default param if it isnt a system command, contains cmd.exe, has no parameters defined, and the first param isnt already "%1"

        ;if the entire command is an environment variable like %NotepadPath%, check to see if the variable value is just a filepath or if it has params. Independent of if it should be expanded in the registry entry (this.isExpanded()), we need to see if what it will get expanded into eventually. Only inject %1 if the entire variable value is a single valid path at the time of writing to the registry.
    */
    shouldInjectDefaultParam() {
        params:= []
        if (!this.shouldValidateCommand && !isEnvironmentVariable(this.command)) {
            return false
        }
        if (!this.command) {
            throw "getQuotedParameters() - command must be set"
        }

        if (isEnvironmentVariable(this.command)) {
            expanded:= ExpandEnvironmentVariables(this.command)
            expanded:= Trim(expanded)
            quotecount:= StrCountOccurences(expanded, """")
            if (quoteCount = 0) {
                return FileExist(expanded)
            } else if (quoteCount = 2) {
                return FileExist(StrExtractBetween(expanded, """", """",, true))
            } else {
                return false
            }
        }

        paramsStr:= LTrim(this.paramsStr)
        len:= StrLen(paramsStr)
        if (!len) {
            return true
        }

        ;HACK
        SplitPath, % this.commandPath, outName, dir, 
        if (ArrayContains(this.actionContext.getSessionContext().commandsToIgnoreDefaultParameter, outName)) {
            return false
        }

        ;return (StrExtractBetween(paramsStr, """", """", false, true) = "%1") ? false : true
        firstParam:= StrExtractBetween(paramsStr, """", """", false, true)
        return !(SubStr(firstParam, 1, 1) = "%")
    }

    /*
        getEnvironmentVariableValueMeta

        Get meta about the value of an environment variable
        @return object - {quoteCount: quoteCount, isValidPath: isValidPath, isQuoted: isQuoted}
    */
    getEnvironmentVariableValueMeta(var) {
        if (!isEnvironmentVariable(var)) {
            return
        }
        expanded:= ExpandEnvironmentVariables(var)
        expanded:= Trim(expanded)
        quotecount:= StrCountOccurences(expanded, """")
        isValidPath:= false
        isQuoted:= false
        if (quoteCount = 0) {
            isValidPath:= (FileExist(expanded)) ? 1 : 0
        } else if (quoteCount = 2) {
            isValidPath:= (FileExist(StrExtractBetween(expanded, """", """",, true))) ? 1 : 0
            isQuoted:= true
        }
        return {quoteCount: quoteCount, isValidPath: isValidPath, isQuoted: isQuoted, expanded: expanded}
    }

    isCommandPathValid() {
        if (!this.commandPath) {
            return false
        }
        if (isEnvironmentVariable(this.commandPath)) {
            return true
        }
        return FileExist(ExpandEnvironmentVariables(this.commandPath))
    }

    executeWrite() {
        commandPath:= this.getCommandPath()
        command:= this.getCommand()
        shouldQuoteIconLocation:= true
        shouldQuotePath:= (this.isUnquotedCommandPath() && this.isShouldValidateCommand()) || isEnvironmentVariable(command)
        
        if (isEnvironmentVariable(command)) {
            cmdPathEVMeta:= this.getEnvironmentVariableValueMeta(command)
            if (!cmdPathEVMeta.isValidPath || cmdPathEVMeta.isQuoted) {
                shouldQuotePath:= false
            }
        }

        iconEVMeta:= this.getEnvironmentVariableValueMeta(this.iconLocation)
        if (IsObject(iconEVMeta)) {
            if (iconEVMeta.isValidPath) {
                if (!iconEVMeta.isQuoted) {
                    shouldQuoteIconLocation:= false
                }
            } else {
                shouldQuoteIconLocation:= false
                errorMsg:= "Error when resolving Icon path: IconLocation was given as an environment variable, but the variable didnt resolve to a valid path.`n" this.iconLocation "`n"
                logger.WARN(errorMsg)
            }
        }
        
        iconLocation:= (this.isExpand()) ? ExpandEnvironmentVariables(this.iconLocation) : this.iconLocation
        if (iconlocation && shouldQuoteIconLocation) { ;item location is not required so validate it is present as well
            iconLocation:= """" iconLocation """"
        }

        if (shouldQuotePath) {
            commandPath:= """" commandPath """"
        }

        if (this.shouldInjectDefaultParam()) {
            commandPath.= " ""%1"""
        }
        
        ;add back any trimmed command space
        if (this.paramsStr) {
            commandPath.= " "
        }

        fullCommand:= commandPath this.paramsStr
        fullCommand:= (this.isExpand()) ? ExpandEnvironmentVariables(fullCommand) : fullCommand
        fullKey:= this.keyPath "\" this.keyName
        commandKey:= fullKey "\command"
        displayName:= this.displayName
        
        if (logger.isDebugEnabled()) {
            logArr:= [[fullKey "@", displayName],[commandKey, fullCommand],[fullKey "@Icon", iconlocation ]]
			logger.DEBUG("FileOrFolderWriteContext ~ onExecute: `n`tModel:    {1}`n{2}", this.model, LoggingUtils.prettyPrintArr2D(logArr))
        }
        
        RegWrite, REG_SZ, %fullKey%,,%displayName%
        RegWrite, REG_EXPAND_SZ, %commandKey%,,%fullCommand%
        if (this.isIconLocationSet()) {
            RegWrite, REG_EXPAND_SZ, %fullKey%, Icon, %iconLocation%
        }
    }
}
