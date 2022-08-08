#Include %A_LineFile%\..\..\SubMenuUtil.ahk
#Include %A_LineFile%\..\..\..\Util.ahk
#Include %A_LineFile%\..\FileOrFolderWriteContext.ahk


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
        SubMenuUtil.processNestedMenuForModel(actionContext, model)

        try {
            this.writeFileOrFolderEntry(actionContext, model)
        } catch e {
            model.error:= (model.error) ? model.error "`n" e : e
        }
    }

    
    /*
        WriteFileOrFolderEntry
        remarks
            - Environment variables
                Environment variables are expanded in place unless the entire command is an environment variable like %var%. They should be one of the following:
                    -partial path segment with no quotes
                    -full path segment with no quotes
                    -parameter value, either quoted in the env var itself, or quoted in csv with no quotes in env var.
                    -We will inject %1 (default parameter) to environment variable commands Iff the whole environment variable currently resolves to a valid filepath at the time of running WriteContextMenu.ahk. (If the env variable stores a path and arguments, do not inject anything). If the value changes later, unexpected behavior may happen.

            - All Command line parameters must be quoted.
                -we inject %1 as convenience if user does not submit, so we need to validate the params.
                -it could be supported if needed, but it makes the parsing easier.
            - Quotes in the path wont work correctly.
                - shouldnt have quotes in the path, but user could send invalid input.
            
    */
    writeFileOrFolderEntry(ByRef actionContext, model) {
        errors:= []
        context:= new FileOrFolderWriteContextClass(actionContext, model)
        context.assertRequiredFields()
        context.setShouldValidateCommand()
        if (context.isShouldValidateCommand()) {
            context.setCommandPath(context.getCommand())
            if (!context.isCommandPathValid()) {
                binDirectory:= context.getActionContext().getSessionContext().getWorkingDirectory() . "\bin"
                context.setCommandPath(binDirectory "\" context.getCommand())
                if (!context.isCommandPathValid()) {
                    errors.push("Command not valid")
                }
            }
        } else {
            context.commandPath:= context.getCommand()
        }

        if (errors.count() > 0) {
            return errors
        }

        if (!context.isIconLocationSet()) {
            context.setIconLocation(context.getIconLocation(context.commandPath))
        }
        psrlogger.enter("ExecuteWrite~" writeType)
        context.executeWrite()
        psrlogger.exit("ExecuteWrite~" writeType)
    }

    ;TODO add error handling. refactored this code but some of error handling is missing, see comments and code fragment for details
    /*
        writeFileOrFolderEntry

        @Param KeyPath - partial path up until the context menu item keys. ie. [HKEY_CLASSES_ROOT\*\shell\
        @Param KeyName - key name of the context menu item key (Not a full registry key path)	
        @Param command - exe and arguements. see https://ss64.com/nt/syntax-args.html.
            If the exe does not start with a drive like C: or percent (environment variable), then we assume it a program under ./bin/. We test this using FileExist(). Important that this script does not define #NoEnv directive. This allows you to place compiled ahk exe's and refer to them in the csv config files as just the file name + extention. Example:
            
            zCopy Path,ContextMenuCopyPath.exe \"%V\"",C:\WINDOWS\system32\SnippingTool.exe,Copy Path

            You for ahk files, you can either compile to exe or specify your ahk runtime as first argument, and pass in script path followed by %1
            
            Ie. DBeaver,"\"C:\Program Files\AutoHotkey\Autohotkey.exe\" \"%USER_PROFILE%\Desktop\workspace\ahk\ContextMenu.ahk\" \"%V\" \"DBeaver\"",C:\Program Files\DBeaver\DBeaver.exe,
        @Param iconLocation - location as determined by locateIconPath Function. if blank, if not exists, the exe or command location will be used.
        @Param displayName - specify this for the readable name on the context menu. Optional if it is the same as the key name. The ordering of items on the context menu is based on the key name, so you can specify some prefix for the key (ie. zOpenWithNotepad) and OpenWithNotepad as displayName, so that entry shows up at the bottom of the context menu items, but does not have that prefix on the context menu itself..

        Remarks
            we perform the following validations on commands:
                if the command has no arguments, check if it is a path with spaces without surrounding quotes
                if the command has arguments, test that the path portion is quoted.
                if the command is unquoted and there are quoted params, verify the path has no spaces.
                if the command has no quoted path nor quoted arguments, skip validation but warn the user.
    */

/*

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

*/
}
global WorkflowUtil:= new WorkflowUtilClass() ;@Export WorkflowUtil
