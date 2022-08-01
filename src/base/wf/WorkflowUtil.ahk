class WorkflowUtilClass {
    processNestedMenus(ByRef keyPath, ByRef keyName, action) {
        keySplit:= StrSplit(keyName, "|",, 2) ;TODO support more than 1 layer of nesting
        if (keySplit.count() > 1) {
            for i, shorthand in keySplit {
                if (i < keySplit.MaxIndex()) {
                    keySplit[i]:= shorthand "\shell"
                }
            }
            expandedKey:= CombineArray(keySplit, "\")

            parentMenuKey:= keySplit[1]
            muiVerb:= RegRead(keyPath "\" parentMenuKey, "MUIVerb")
            if (!muiVerb) {
                throw "SubMenu not resolved. Create SubMenu entries first."
            }
            keyPath:= keyPath "\" parentMenuKey "\shell"
        }
    }

    executeFileOrFolder(actionContext, model) {
        keyName:= model.keyName
        command:= model.command
        icon:= model.icon
        contextMenuName:= model.contextMenuName
        keyPath:= model.keyPath

        if (InStr(keyName, "\")) {
            rootShorthand:= SubMenuUtil.getRootAlias(actionContext, model)
            SubMenuUtil.processNestedMenu(rootShorthand, keyPath, keyName)
        }
        try {
            this.writeFileOrFolderEntry(keyPath, keyName, command, icon, contextMenuName)
        } catch e {
            model.error:= (model.error) ? model.error "`n" e : e
        }
    }
    
    /*
        writeFileOrFolderEntry

        @Param KeyPath - partial path up until the context menu item keys. ie. [HKEY_CLASSES_ROOT\*\shell\
        @Param KeyName - key name of the context menu item key (Not a full registry key path)	
        @Param command - exe and arguements. see https://ss64.com/nt/syntax-args.html.
            If the exe does not start with a drive like C: or percent (environment variable), then we assume it a program under ./bin/. We test this using FileExist(). Important that this script does not define #NoEnv directive. This allows you to place compiled ahk exe's and refer to them in the csv config files as just the file name + extention. Example:
            
            zCopy Path,ContextMenuCopyPath.exe \"%V\"",C:\WINDOWS\system32\SnippingTool.exe,Copy Path

            You for ahk files, you can either compile to exe or specify your ahk runtime as first argument, and pass in script path followed by %1
            
            Ie. DBeaver,"\"C:\Program Files\AutoHotkey\Autohotkey.exe\" \"%USER_PROFILE%\Desktop\workspace\ahk\ContextMenu.ahk\" \"%V\" \"DBeaver\"",C:\Program Files\DBeaver\DBeaver.exe,
        @Param icon - path to icon file. if blank, check ./resources/ico for a file named %keyname%.ico. if not exists, the exe or command location will be used.
        @Param contextMenuName - specify this for the readable name on the context menu. Optional if it is the same as the key name. The ordering of items on the context menu is based on the key name, so you can specify some prefix for the key (ie. zOpenWithNotepad) and OpenWithNotepad as contextMenuName, so that entry shows up at the bottom of the context menu items, but does not have that prefix on the context menu itself..

        Remarks
            we perform the following validations on commands:
                if the command has no arguments, check if it is a path with spaces without surrounding quotes
                if the command has arguments, test that the path portion is quoted.
                if the command is unquoted and there are quoted params, verify the path has no spaces.
                if the command has no quoted path nor quoted arguments, skip validation but warn the user.
    */
    writeFileOrFolderEntry(keyPath, keyName, command, icon="", contextMenuName="") {
        if (!keyName || !command) {
            throw "Key or command is blank"
        }

        if (InStr(command, "rundll32") = 1 
            || (!InStr(command, ".exe") && !InStr(command, """"))) { ;if user is running a simple system verb, dont try to validate it
            goto WriteContextMenuEntryCommandProcessed
        }
        ;our command could be plain exe or have args. need to see if path portion is valid so we can decide to leave it as is, or look in /bin for command and /ico for icon if those arent explicit as this functions parameters.
        command:= Trim(command)
        expandedCommand:= ExpandEnvironmentVariables(command) ;we might want to expand it or not, but we have to expand to test path bc FileExist doesnt respect env variables
        
        ;if command has no arguments (it is a plain exe file path), we inject %1 for convenience. It could be quoted or unquoted so check against expanded command with quotes stripped off (StrExtractBetween non greedy version, the end strips off the last quote)
        ;07/29/22 we must also check that the quoted section comes after .exe, because we could have an unquoted exe with quoted params where param is a valid path..
        commandHasArguments:= (FileExist(StrExtractBetween(expandedCommand, """", """", false, false))) ? false : true

        expandedQuoteStrippedCommand:= StrExtractBetween(expandedCommand, """", """", false, false) ;quotes stripped, non greedy version
        
        exeIdx:= InStr(expandedCommand, ".exe")
        unquotedExeWithQuotedParams:= (exeIdx > 0 && (InStr(expandedCommand, """") > exeIdx))
        
        commandStartsWithQuote:= (SubStr(command, 1, 1) = """") ? true : false
        commandExePath:= (!unquotedExeWithQuotedParams && (!commandHasArguments || commandStartsWithQuote)) ? StrExtractBetween(command, """", """", false, true) : StrSplit(command, " ",,2)[1]
        if (InStr(command, expandedQuoteStrippedCommand) > (InStr(command, "."))) { ;if the exe is unquoted but the args are, check if exe has spaces.
            if (InStr(command, " ") < InStr(command, ".")) {
                throw "Path was unquoted but has spaces. Must quote it in the csv if it has spaces. Path:`n`t" command
            }
        }
        expandedCommandExePath:= ExpandEnvironmentVariables(commandExePath)


        
        if (!FileExist(expandedCommandExePath)) { ;if command isnt a valid file, then check .\bin.
            originalCommand:= command
            originalCommandExePath:= WORKING_DIRECTORY "\bin\" commandExePath
            command:= WORKING_DIRECTORY "\bin\" command
            expandedCommand:= WORKING_DIRECTORY "\bin\" expandedCommand
            expandedCommandExePath:= WORKING_DIRECTORY "\bin\" expandedCommandExePath
            commandHasArguments:= (unquotedExeWithQuotedParams) ? true : (FileExist(StrExtractBetween(expandedCommand, """", """", false, false))) ? false : true
        }

        if (!commandHasArguments && InStr(expandedCommandExePath, " ") && expandedCommand = expandedQuoteStrippedCommand) {
            throw "Path was unquoted but has spaces. Must quote it in the csv if it has spaces. Path:`n`t" command
        }
        if (commandHasArguments && !commandStartsWithQuote && InStr(expandedCommandExePath, " ")) {
            throw "Path was unquoted but has spaces. Must quote it in the csv if it has spaces. Path:`n`t" command
        }

        if (!(FileExist(expandedCommand) || FileExist(expandedCommandExePath))) {
            throw "Command or file path not found. Make sure the file path is correct (paths with spaces are quoted), and/or there matches a file in .\bin with the same name.`n`nCommand:`n`t" originalCommand "`n`nPaths checked:`n`t" originalCommandExePath "`n`t" commandExePath	
        }
        if (!InStr(command, """") && InStr(command, " ")) {
            Msgbox, % "WARNING! the command (path or arguments) has spaces characters but no values are quoted. Verify that you intend to send each space delimited word as a separate command line argument. Kill the script or press ok to continue. `n`nCommand:`n`t" command
        }
        commandValidated:= true

        WriteContextMenuEntryCommandProcessed:

        ;If icon is given in csv, test it for full path. If not full path, try ./resources/ico/{value}.ico. if still no match, use exe from command. (The first portion of the command, as it could have arguments).
        if (icon) {
                expandedIcon:= ExpandEnvironmentVariables(icon)
            if (!FileExist(expandedIcon)) {
                if (FileExist(WORKING_DIRECTORY "\resources\ico\" icon)) {
                    icon:= WORKING_DIRECTORY "\resources\ico\" icon
                    expandedIcon:= WORKING_DIRECTORY "\resources\ico\" expandedIcon
                } else {
                    SplitPath, % commandExePath,,,, commandExeNameNoExt
                    expandedCommandExeNameNoExt:= ExpandEnvironmentVariables(commandExeNameNoExt)
                    if (FileExist(WORKING_DIRECTORY "\resources\ico\" expandedCommandExeNameNoExt ".ico")) {
                        icon:= WORKING_DIRECTORY "\resources\ico\" commandExeNameNoExt ".ico"
                        expandedIcon:= WORKING_DIRECTORY "\resources\ico\" expandedCommandExeNameNoExt ".ico"
                    }
                }
            }	
            if (!FileExist(expandedIcon)) {
                throw "Icon file [" icon "] not found. Checked absolute path, ./resources/ico/" icon ", ./resources/ico/" commandExeNameNoExt ".ico `n`nTo Use the icon of the called exe, leave icon field blank in the csv."
            }
        } else {
            icon:= commandExePath
            expandedIcon:= ExpandEnvironmentVariables(icon)
        }

        if (unquotedExeWithQuotedParams) {
                expandedCommand:= StrReplace(expandedcommand, expandedCommandExePath, """" expandedCommandExePath """")
                command:= StrReplace(command, originalCommandExePath, """" originalCommandExePath """")
        }

        if (!contextMenuName) {
            contextMenuName:= keyName
        }
        
        command:= (EXPAND_ENVIRONMENT_VARIABLES) ? expandedCommand : command
        icon:= (EXPAND_ENVIRONMENT_VARIABLES) ? expandedIcon : icon

        if (commandValidated && !commandHasArguments && (!InStr(commandExePath, "cmd.exe"))) { ;skip adding default param when starting program from cmd as it causes issues if program isnt expecting any arg (powershell_ise is expecting path of a ps script, not any old file)
            command.= " ""%1""" ;"%1" passes the name of the file or folder the context menu item was invoked on.
        }
        fullKey:= keyPath "\" keyName
        commandKey:= fullKey "\command"
        RegWrite, REG_SZ, %fullKey%,,%contextMenuName%
        RegWrite, REG_EXPAND_SZ, %commandKey%,,%command%
        RegWrite, REG_EXPAND_SZ, %fullKey%, Icon, %icon%

        red:=
        pth:= REGISTRY_KEY_ROOT_SHELL "VSCode\command"
        ;RegRead, red, HKCR, %fullKey%,
        ;Msgbox % red
        ;RegWrite, %command%, REG_EXPAND_SZ, %commandKey%,
    }
}
global WorkflowUtil:= new WorkflowUtilClass() ;@Export WorkflowUtil
