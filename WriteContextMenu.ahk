#SingleInstance, Force
#Include %A_LineFile%\..\src\Util.ahk
;#NoEnv ;do not enable NoEnv, we use it to test paths that may contain environment variables. Leaving this commented out so it is not added later erroneously
/*
	WriteContextMenu

	IMPORTANT! This script must be run as administrator to reflect registry changes
	This file automates writes the registry to set context menu items. This script contains a directory structure as follows

	./WriteContextMenu.ahk
	./bin - Compiled Authotkey scripts that do custom behavior instead of just opening a program
	./resoucres
		- ./ico - icons if not specified in input csv. If no icon specified or not an ico file in this dir, we will attempt to use the ico of the exe being invoked as the command
		- 
	./src - Source ahk scripts.

	Remarks 
		- Environment variables are supported. All registry keys are stored as expandable string. They could be expanded from ahk with ddl, but leaving it alone so they wont break if someone were to export the registry keys and use them on a different machine.
		-All keys are written as expandable string, so wont be able to use if the key value is dWord.
		-Keys arent deleted, so if you change the name of an existing entry, you will have to delete the old one manually with regedit. Existing values of a key can be updated if the key name itself isnt changing.
		-The effects of registry writes are immediate, however regedit does not update right away if a key was changed from ahk, so close either close and reopen regedit or press F5 to refresh.
		-If the command has no arguments (it is a plain filepath leading to an exe or other executable file, quoted is fine) then inject %1 as a parameter. This refers to the current file or folder the context menu item was invoked on.
*/

global WORKING_DIRECTORY:= GetWorkingDirectory()
FOLDER_PATH_RESOURCES:= WORKING_DIRECTORY "\resources\"
global FILE_PATH_ALL_FILE_EXT:= FOLDER_PATH_RESOURCES "HKEY_CLASSES_ROOT_AllFileExt.csv"
global FILE_PATH_DIRECTORY:= FOLDER_PATH_RESOURCES "HKEY_CLASSES_ROOT_Directory.csv"
global FILE_PATH_DIRECTORY_BACKGROUND:= FOLDER_PATH_RESOURCES "HKEY_CLASSES_ROOT_DirectoryBackground.csv"

global FILE_PATH_NEW_FILE:= FOLDER_PATH_RESOURCES "HKEY_CLASSES_ROOT_NewFile.csv"
global FILE_PATH_ICONS_ONLY:= FOLDER_PATH_RESOURCES "HKEY_CLASSES_ROOT_IconsOnly.csv"
global FILE_PATH_DEFAULT_PROGRAMS:= FOLDER_PATH_RESOURCES "DefaultPrograms.csv"


global REGISTRY_KEY_ALL_FILE_EXT:= "HKCR\*\shell\"
global REGISTRY_KEY_DIRECTORY:="HKCR\Directory\shell\"
global REGISTRY_KEY_DIRECTORY_BACKGROUND:="HKCR\Directory\Background\shell\"

global FILETYPE_SUFFIX:= "file" ;suffix for file extension. ie. if ext is ".csv", fileType is "csvfile". Used when creating new extensions, or unlinking file ext's from default programs to a new default program

global EXPAND_ENVIRONMENT_VARIABLES:= ReadIniCfg(WORKING_DIRECTORY "\settings.ini", "settings", "ExpandEnvironmentVariables")

;WriteNewFileEntry(".reports", true, "Report")
WriteContextMenu()

WriteContextMenu() {
		choice:= A_Args[1]
		Traytip, WriteContextMenu, %choice%
		if (choice = "DefaultPrograms") {
			WriteDefaultOpenActionFromCsv()
		} else if (choice = "AllFileExt") {
			WriteContextMenuFromCsv(REGISTRY_KEY_ALL_FILE_EXT, FILE_PATH_ALL_FILE_EXT)
		} else if (choice = "Directory") {
			WriteContextMenuFromCsv(REGISTRY_KEY_DIRECTORY, FILE_PATH_DIRECTORY)
		} else if (choice = "DirectoryBackground") {
			WriteContextMenuFromCsv(REGISTRY_KEY_DIRECTORY_BACKGROUND, FILE_PATH_DIRECTORY_BACKGROUND)
		} else if (choice = "NewFile") {
			WriteContextMenuNewFileFromCsv()
		} else if (choice = "IconsOnly") {
			WriteContextMenuIconsOnlyFromCsv()
		} else {
			WriteDefaultOpenActionFromCsv()
			WriteContextMenuFromCsv(REGISTRY_KEY_ALL_FILE_EXT, FILE_PATH_ALL_FILE_EXT)
			WriteContextMenuFromCsv(REGISTRY_KEY_DIRECTORY, FILE_PATH_DIRECTORY)
			WriteContextMenuFromCsv(REGISTRY_KEY_DIRECTORY_BACKGROUND, FILE_PATH_DIRECTORY_BACKGROUND)
			WriteContextMenuNewFileFromCsv()
			WriteContextMenuIconsOnlyFromCsv()
		}
	TrayTip, "Context Menu", "Done Writing to the registry"
}

/*
	WriteContextMenuEntry

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
WriteContextMenuEntry(keyPath, keyName, command, icon="", contextMenuName="") {
	if (!keyName || !command) {
		throw "Key or command is blank"
	}

	;our command could be plain exe or have args. need to see if path portion is valid so we can decide to leave it as is, or look in /bin for command and /ico for icon if those arent explicit as this functions parameters.
	command:= Trim(command)
	expandedCommand:= ExpandEnvironmentVariables(command) ;we might want to expand it or not, but we have to expand to test path bc FileExist doesnt respect env variables
	
	;if command has no arguments (it is a plain exe file path), we inject %1 for convenience. It could be quoted or unquoted so check against expanded command with quotes stripped off (StrExtractBetween non greedy version, the end strips off the last quote)
	commandHasArguments:= (FileExist(StrExtractBetween(expandedCommand, """", """", false, false))) ? false : true

	expandedQuoteStrippedCommand:= StrExtractBetween(expandedCommand, """", """", false, false) ;quotes stripped, non greedy version
	commandStartsWithQuote:= (SubStr(command, 1, 1) = """") ? true : false
	commandExePath:= (!commandHasArguments || commandStartsWithQuote) ? StrExtractBetween(command, """", """", false, true) : StrSplit(command, " ",,2)[1]
	if (InStr(command, expandedQuoteStrippedCommand) > (InStr(command, "."))) { ;if the exe is unquoted but the args are, check if exe has spaces.
		if (InStr(command, " ") < InStr(command, ".")) {
			throw "Path was unquoted but has spaces. Must quote it in the csv if it has spaces. Path:`n`t" command
		}
	}
	expandedCommandExePath:= ExpandEnvironmentVariables(commandExePath)


	
	if (!FileExist(expandedCommandExePath)) { ;if command isnt a valid file, then check .\bin.
		originalCommand:= command
		originalCommandExePath:= commandExePath
		command:= WORKING_DIRECTORY "\bin\" command
		expandedCommand:= WORKING_DIRECTORY "\bin\" expandedCommand
		expandedCommandExePath:= WORKING_DIRECTORY "\bin\" expandedCommandExePath
		commandHasArguments:= (FileExist(StrExtractBetween(expandedCommand, """", """", false, false))) ? false : true
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

	if (!contextMenuName) {
		contextMenuName:= keyName
	}
	
	command:= (EXPAND_ENVIRONMENT_VARIABLES) ? expandedCommand : command
	icon:= (EXPAND_ENVIRONMENT_VARIABLES) ? expandedIcon : icon

	if (!commandHasArguments) {
		command.= " ""%1""" ;"%1" passes the name of the file or folder the context menu item was invoked on.
	}
	fullKey:= keyPath keyName
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


WriteDefaultOpenActionFromCsv() {
	filePath:= FILE_PATH_DEFAULT_PROGRAMS
	FileRead, csv, %filePath%
	data:= csvToHeaderAndData(csv, true).data
	for i, row in data {
		extensions:=
		if (row.count() < 1) {
			continue
		}
		if (row.count() != 2) {
			Msgbox, % "Error reading csv: " filePath ".`n`nRow " i " has invalid number of columns (" row.count() "). Each row should have 1 comma for 2 columns.`nExtension,DefaultProgram"
			ExitApp
		}
		

		try {
			WriteDefaultOpenAction(row[1], row[2])
		} catch e {
			if (e.what = "RegWrite") {
				Msgbox, % "Unexpected error on RegWrite command. Check that script is run as administrator.`n`nhttps://www.autohotkey.com/docs/commands/RegWrite.htm"
				exitapp
			}
			Msgbox, % "Error found on row " i " in :`n`t" filePath "`n`n`n" e
		}
	}
}
WriteContextMenuFromCsv(keyPath, filePath) {
	FileRead, csv, %filePath%
	data:= csvToHeaderAndData(csv, true).data
	for i, row in data {
		extensions:=
		if (row.count() < 1) {
			continue
		}
		if (keyPath = REGISTRY_KEY_ALL_FILE_EXT) {
			if (row.count() != 5) {
				Msgbox, % "Error reading csv: " filePath ".`n`nRow " i " has invalid number of columns (" row.count() "). Each row should have 4 commas for 5 columns.`nKeyName,Command,Icon,ContextMenuNamekeyName,Extension"
				ExitApp
			}
		} else {
			if (row.count() != 4) {
				Msgbox, % "Error reading csv: " filePath ".`n`nRow " i " has invalid number of columns (" row.count() "). Each row should have 3 commas for 4 columns.`nKeyName,Command,Icon,ContextMenuNamekeyName"
				ExitApp
			}
		}
		

		try {
			
			extensions:= row[5]
			if (extensions) {
				extensionsSplit:= StrSplit(extensions, "|")
				for j, extension in extensionsSplit {
					if (!InStr(extension, "`.")) {
						throw "Cant parse extensions. Should be pipe delimited in the form `.{ext}"
					}
					fileType:= CreateOrUpdateFileType(extension)
					WriteContextMenuEntry("HKCR\" fileType "\shell\", row[1], row[2], row[3], row[4])
				}
			} else {
				WriteContextMenuEntry(keyPath, row[1], row[2], row[3], row[4])
			}

		} catch e {
			if (e.what = "RegWrite") {
				Msgbox, % "Unexpected error on RegWrite command. Check that script is run as administrator.`n`nhttps://www.autohotkey.com/docs/commands/RegWrite.htm"
				exitapp
			}
			Msgbox, % "Error found on row " i " in :`n`t" filePath "`n`n`n" e
		}
	}
}

GetFileTypeName(ext) {
	extKey:= "HKCR\" ext
	return RegRead(extKey)
}

GetFileTypePath(ext) {
	fileType:= GetFileTypeName(ext)
	if (fileType) {
		return "HKCR\" fileType
	}
}

/*
	CreateOrUpdateFileType
	Creates or returns the filetype associated with a file extension.

	Remarks
		- does not change user choice. up to the user to override with FileTypesMan
		- only use when "Open" key handling is set up or is not needed.
			- /TODO support open key in our csv to specify open logic


	@param ext - ext in the format .{ext} example is .txt
	@return fileType name.
*/
CreateOrUpdateFileType(ext) {
	if (ext = "") {
		throw "GetOrCreateFileTypeHandler - ext param is blank"
	}
	fileType:= getFileTypeName(ext)
	if (fileType = "") {
		fileType:= ""
		fileType:= StrReplace(ext, ".", "") FILETYPE_SUFFIX
		RegWrite("HKCR\" ext,, fileType,, false, true) ;here we can create the new ext key if doesnt exist, but still dont overwrite if it exists. Creating new ext will be rare, but might be useful so you can run the script before programs that use those ext's are downloaded
		createFileType(fileType)
	}

	return fileType
}

createFileType(fileType) {
	RegWrite, REG_SZ, % "HKCR\" fileType
}

/*
	GetCommandForFileExtension
	Get given an extension and a command or shell action, get the value of command.
	@param extension
	@param actionKeyOrCommand - command, or shell action. can also be a keyname under HKCR\Applications

	If actionKeyOrCommand contains ".exe", return actionKeyOrCommand. (use simple string match, so wont work if any of your actions have .exe in it for some reason)
		Else, lookup fileType using HKCR\.{ext}\Default
		Lookup action command using HKCR\filetype\shell\{actionKeyOrCommand}\command
*/
getCommandForFileExtension(extension, actionKeyOrCommand) {
	if (InStr(actionKeyOrCommand, ".exe")) {
		return actionKeyOrCommand
	}

	CreateOrUpdateFileType(extension)

	fileTypePath:= GetFileTypePath(extension)
	command:= RegRead(fileTypePath "\shell\" actionKeyOrCommand "\command")
	if (!command) {
		command:= RegRead("HKCR\*\shell\" actionKeyOrCommand "\command") ;attempt to read from global/AllExt actions if no action defined on filetype
	}
	return command
}

DeleteUserChoice(extension) {
	key:= "Computer\HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts\" extension "\UserChoice"
	RegDelete(key)
}

/*
	WriteDefaultOpenAction

	Creates a new shell action to be used as default. changes filetype default key from blank to "open" or the name of the default action.

	Purpose - after user choice is unhooked, filetype most likely wont have any default open action. You can still open the ext using another context menu entry, but double clicking the file in file explorer will either bring up the menu of associated programs, or throw an error (non standard file ext's that havent been opened in any program before)

	Remarks - operation overwrites any existing "open" key
			- unlinks user choice.
			- if any fileType is there already and doesnt match {ext}{FILETYPE_SUFFIX}, create a new file type. (while user choice is unlinked, we could be inadvertently changing other file ext's if they share a filetype, which we dont want. If you want multiple ext's to have the same action, it is easy to define in AllFileExt.csv with extension field accepting multiple ext's, delimited by a pipe "|". The downside is that the action is defined on multiple filetype keys, so if you wanted to change it manually in RegEdit you would need to change it in multiple places. The upside is if you only change ext's via default programs csv, then you wont need any manual registry writes and the script will alter the actions in every ext they are defined, even if there are multiple. (And also the other exts associated with the previous filetype wont be changed inadvertently)
			- if filetype is altered, it doesnt automatically create other keys (defaultIcon, shellNew) so run the other scripts again for changing ico's and new files. Does not delete old filetype (may be useful to keep it for troubleshooting)
*/
WriteDefaultOpenAction(extension, actionKeyOrCommand) {
	fileType:= GetFileTypeName(extension)
	rawExt:= StrReplace(extension, ".", "")
	expectedFileType:= rawExt FILETYPE_SUFFIX
	if (!(fileType = expectedFileType)) { ;we dont want to add actions to other file types if the filetype is shared between exts. See remarks for more details
		createFileType(expectedFileType)
		RegWrite("HKCR\" extension,, expectedFileType,, true)
	}
	fileTypePath:= GetFileTypePath(extension)
	command:= getCommandForFileExtension(extension, actionKeyOrCommand)
	defaultAction:= "open"
	if (command) {
		RegWrite(fileTypePath "\shell\" defaultAction "\command",,command,, true, true)
		DeleteUserChoice(extension)
	}
}

WriteContextMenuNewFileFromCsv() {
	FileRead, csv, %FILE_PATH_NEW_FILE%
	data:= csvToHeaderAndData(csv, true).data
	for i, row in data {
		if (row.count() < 1) {
			continue
		}
		if (row.count() != 3) {
			Msgbox, % "Error reading csv: " filePath ".`n`nRow " i " has invalid number of columns (" row.count() "). Each row should have 2 commas for 3 columns.`extension,enabled,menuDescription"
			ExitApp
		}
		try {
			writeNewFileEntry(row[1], row[2], row[3])
		} catch e {
			if (e.what = "RegWrite" || e.what = "RegRead" || e.what = "RegDelete") {
				Msgbox, % "Unexpected error on " e.what " command. Check that script is run as administrator.`n`nhttps://www.autohotkey.com/docs/commands/" e.what ".htm"
				exitapp
			}
			Msgbox, % "Error found on row " i " in :`n`t" filePath "`n`n`n" e
		}
	}
}

WriteContextMenuIconsOnlyFromCsv() {
	FileRead, csv, %FILE_PATH_ICONS_ONLY%
	data:= csvToHeaderAndData(csv, true).data
	for i, row in data {
		if (row.count() < 1) {
			continue
		}
		if (row.count() != 1) {
			Msgbox, % "Error reading csv: " filePath ".`n`nRow " i " has invalid number of columns (" row.count() "). Each row should have 1 column (Extension)"
			ExitApp
		}
		try {
			writeIconEntry(row[1])
		} catch e {
			if (e.what = "RegWrite" || e.what = "RegRead" || e.what = "RegDelete") {
				Msgbox, % "Unexpected error on " e.what " command. Check that script is run as administrator.`n`nhttps://www.autohotkey.com/docs/commands/" e.what ".htm"
				exitapp
			}
			Msgbox, % "Error found on row " i " in :`n`t" filePath "`n`n`n" e
		}
	}
}

/*
	Write new file entry

	steps done by the script: 
		make value called NullFile under HKCR\.{ext}\ShellNew
		check the default value of HKCR\.{ext}. This is the handler/proc id. For this key, add Default value as the name in the context menu, and delete the "FriendlyTypeValue" name. we add \DefaultIcon as a subkey, with ico path as default value.

		There is one more step to get the icon to work. Currently there is something caller UserChoice, that assoicates applications with a large number of file extensions. The key name is hashed and is different for each user, so for now, use FileTypeMan from Nirsoft to go to the extension, click the popup for User Choice, and click "Detatch file Type". You may get an error popup from FileTypeMan but it still works. If you attempt to set the image before doing that, it will change the ico for every file type that is associated with the program the current file type was. After you delete the association, you can double click the file type to bring up the same menu. You should not see the list of associated file types at the top. Select the icon path.
		Some file types like xml have an icon handler, in the key {procId}\ShellExtensions. Delete this key as well.

	it is possible to change the name of the entry, but we have to delete the key FriendlyTypeName as well as set default value on the {ext}File key . If the user wanted to revert those change back to default, we will create a new key with preceeding underscore, so the script can restore the value. If the @param add is false, we will attempt to restore the FriendlyTypeName key with the value of _FriendlyType name.

	Remarks
		- validatations are minimal on passed ext
*/
writeNewFileEntry(ext, add=true, description="") {
	ext:= StrReplace(ext, "`.", "")
	shellNewKey:= "HKCR\." ext "\ShellNew\"
	extKey:= "HKCR\." ext
	nullFileKey:= "NullFile"
	nullFileValue:= ""

	FriendlyTypeNameValue:= "FriendlyTypeName"
	
	procId:= RegRead(extKey)
	if (!procId) {
		throw "procId/Type name not found for extenstion " ext ". procId is the default value for the key " extKey ". To avoid pointing to a new procid key that doesnt have ""Open with"" set, make sure this key exists first."
	}
	handlerKey:="HKCR\" procId
	iconKey:= "HKCR\" procId "\DefaultIcon"


	previousDefaultDescription:= RegRead(handlerKey)
	previousDefaultDescriptionBackup:= RegRead(handlerKey, "_Default")
	previousFriendlyTypeName:= RegRead(handlerKey, "FriendlyTypeName")
	previousFriendlyTypeNameBackup:= RegRead(handlerKey, "_FriendlyTypeName")

	if (add) {
		RegWrite, REG_SZ, %shellNewKey%,%nullFileKey%,%nullFileValue%

		if (!(description = "")) {
			;we want to back up the value, but only if it wasnt backed up before. if we dont check if the backup is there, we will overwrite the backup with a new value that wasnt the original value of the registry key

			RegWrite, REG_SZ, %handlerKey%,, %description%
			if (!previousDefaultDescriptionBackup) {
				RegWrite, REG_SZ, %handlerKey%, _Default, %previousDefaultDescription%
			}

			if (RegRead(handlerKey, "FriendlyTypeName")) {
				RegDelete, %handlerKey%, FriendlyTypeName
			}

			if (!previousFriendlyTypeNameBackup) {
				RegWrite, REG_SZ, %handlerKey%, _FriendlyTypeName, %previousFriendlyTypeName%
			}
		}
	} else {
		;we want to back up the value, but only if it wasnt backed up before. if we dont check if the backup is there, we will overwrite the backup with a new value that wasnt the original value of the registry key

		if (previousDefaultDescriptionBackup) {
			RegWrite, REG_SZ, %handlerKey%,, %previousDefaultDescriptionBackup%
			RegDelete, %handlerKey%, _Default
		} ;if we dont have a backup, dont delete whats there since it wasnt added from the script. Deleting the null file is enough to hide the entry

		if (previousFriendlyTypeNameBackup) {
			RegDelete, %handlerKey%, FriendlyTypeNameBackup
			RegWrite, REG_SZ, %handlerKey%, FriendlyTypeName, %previousFriendlyTypeNameBackup%
		}
	}
}

/*
	writeIconEntry - writes DefaultIcon key into the handler associated witha file type. In the registry, there will be a key .{ext} under HCKR with a default value. That default value points to another key (The handler) where we set our DefaultIcon key.
	-The source of our ico will be in ./resources/ico/ext with file named {ext}.ico. Run this script again if this containing folder moves locations.
	-TODO this is similar to new file method, merge these
	-Removed functionality to delete the entry. If you want to change the ico, use FileTypeMan or delete the registry entries from regedit. Must edit the user choice first in FileTypeMan if you change the ico there, otherwise it will change the ico for all the associated apps with its controlling user choice program. Using this script will not change the icon for the other file types in the user choice.
	-remarks - you may need to remove user choice from fileTypeMan, then run the script. It overrides this config if some other application has said that it is controlling this file type.
		- (eg. lots of icons for text files are defaulted to np++ when you install it)
*/
writeIconEntry(ext, add=true) {
	ext:= StrReplace(ext, "`.", "")
	shellNewKey:= "HKCR\." ext "\ShellNew\"
	extKey:= "HKCR\." ext

	FriendlyTypeNameValue:= "FriendlyTypeName"
	
	procId:= RegRead(extKey)
	if (!procId) {
		;only for new icon, if it doesnt exist, create a new .ext key with a handler. Open with wont be set, but that may be added later (or can do in FileTypesMan)
		RegWrite, REG_SZ, %extKey%,, % ext FILETYPE_SUFFIX
		procId:= RegRead(extKey)
		if (!procId) {
			throw "procId/Type name not found for extenstion " ext ". procId is the default value for the key " extKey ". To avoid pointing to a new procid key that doesnt have ""Open with"" set, make sure this key exists first."
		}
	}
	handlerKey:="HKCR\" procId
	iconKey:= "HKCR\" procId "\DefaultIcon"

	if (add) {		
		icon:= WORKING_DIRECTORY "\resources\ico\ext\" ext ".ico"
		expandedIcon:= ExpandEnvironmentVariables(icon)

		if (FileExist(expandedIcon)) {
			icon:= (EXPAND_ENVIRONMENT_VARIABLES) ? expandedIcon : icon
			
			previousIcon:= RegRead(iconKey)
			previousIconBackup:= RegRead(iconKey, "_Default")
			
			RegWrite, REG_EXPAND_SZ, %iconKey%,, %icon%
			if (!previousIconBackup) {
				RegWrite, REG_SZ, %iconKey%, _Default, %previousIcon%
			}
		} else {
			TrayTip, WriteNewFileEntry, % "Icon not set, checked " icon
		}

		iconHandler:= RegRead(handlerKey, "ShellExtensions")
		if (iconHandler) {
			RegDelete, % handlerKey "\ShellExtensions",
		}
	} else {
		;Not supported, use FileTypeMan
	}
}


/*
	getWorkingDirectory
	We want to refer to current working directory, but Functions like FileExist dont resolve paths like #Include does. Include allows you to do %A_LineFile%\.. to refere to current directory.
	if current file is C:\some\full\path\WriteContextMenu.ahk, it will return C:\some\full\path
	;https://www.autohotkey.com/docs/commands/SplitPath.htm
*/
GetWorkingDirectory() {
	SplitPath, A_LineFile,, dir
	return dir
}
