#Include %A_LineFile%\..\FolderContents.ahk

;Taken from GridFactory.csvHeaderAndData in Grid.ahk
csvToHeaderAndData(ByRef csv, ByRef hasHeader, ByRef separator="`,") {
	data:= []

	rows:= StrSplit(csv, "`n", "`r")
	if (rows.count() > 0) {
		if (hasHeader) {
			header:= csvRowToArray(rows.RemoveAt(1), """", separator)
		}
	} else {
		return {header: [], data: []}
	}

	if (rows.count() > 0) { ;check size again after header consumed in case csv has header with no data
		lastRowContents:= rows.MaxIndex()
		if (rows[lastRowContents] = "") { ;if file ends in `n, trim it off. If you did want an empty row for some reason, you could have 2 empty lines in the csv
			rows.pop()
		}
		if (!hasHeader && rows[1] = "") {
			throw "CsvToHeaderAndData - file was requested with no header and has blank first column. Either remove the row or insert n-1 commas for n number of rows."
		}
	}

	for i, row in rows {
		data.push(csvRowToArray(row, """", separator))
	}
	if (!hasHeader) {
		if (data.MaxIndex() > 0) { ;infer the header row from the first data row
			header:= []
			for i, row in data[1] {
				header.push("ROW" i)
			}
		} else {
			data:= []
		}
	}
	return {header: header, data: data}
}


ExceptionMsg(ByRef e) {
    if (!IsObject(e)) {
        return e
    }
    str:= ""
    str.= "Exception:`n`n"
    str.= "File: " e.File "`n"
    str.= "Line: " e.Line "`n"
    str.= "Message: " e.Message "`n"
    str.= "Extra: " e.Extra "`n"
    str.= "What: " e.What "`n"
    return str
}

;Taken from GridFactory.csvRowToArray in Grid.ahk
csvRowToArray(ByRef text, ByRef aroundCellDelimiter="""", ByRef separator="`,") {
	if (!InStr(text, aroundCellDelimiter)) { ;20x performance speedup on large csv's with no around separator
		return StrSplit(text, separator)
	}
	row:= []
	length:= StrLen(text)
	currentCell:= ""
	handleFirstChar:= false
	isEscape:= false
	openDelimiter:= -1
	Loop, parse, text
	{
		if (!handleFirstChar) {
			handleFirstChar:= true
			if (A_LoopField = aroundCellDelimiter) {
				if (openDelimiter < 0) {
					openDelimiter:= A_Index
				}
				continue
			}
		}
		
		if (A_LoopField = separator && openDelimiter < 0) {
			row.push(currentCell)
			currentCell:= ""
			handleFirstChar:= false
			continue
		}
		
		if (A_LoopField = aroundCellDelimiter && openDelimiter > 0) { ;how to handle quote literals: first check open delimiter is a quote. if encounter another quote, look ahead to see if its an escaped double quote or the close delimiter (end of the cell)
			if (isEscape) {
				currentCell.= A_LoopField
				isEscape:= false
			} else {
				if (A_Index < StrLen(text) && (CharAt(text, A_Index + 1) = aroundCellDelimiter)) {
					isEscape:= true
					continue
				}
				openDelimiter:= -1 ; if its a closing delimiter, eat the character
			}
		} else {
			currentCell.= A_LoopField
		}
		
		if (A_Index = length) {
			row.push(currentCell)
			return row
		} 
	}
	if (SubStr(text, StrLen(text) - StrLen(separator) + 1) = separator) { ;if we end in the separator, add empty val
		row.push("")
	}
	return row
}

;StringUtils - CharAt
;returns a char at the specified index
;Remarks - index is 1 indexed, not 0 indexed. 
CharAt(ByRef text, index) {
	return SubStr(text, index, 1)
}

;StringUtils StringExtractBetween
StrExtractBetween(ByRef text, prefix, suffix, includeEnds=false, greedy=false) {
	prefixIdx:= InStr(text, prefix)
	if (!prefixIdx) {
		return text
	}
	if (greedy) {
			suffixIdx:= InStr(text, suffix,,prefixIdx + 1) ; search from the end of the string, backwards (lastIndexOf in java)
	} else {
		suffixIdx:= InStr(text, suffix,,0) ; search from the end of the string, backwards (lastIndexOf in java)
	}
	if (!includeEnds) {
		if (prefixIdx) {
			prefixIdx:= prefixIdx + 1
		}
		if (suffixIdx) {
			suffixIdx:= suffixIdx - 1
		}
	}
	if (prefixIdx && suffixIdx) {
		return SubStr(text, prefixIdx, suffixIdx - prefixIdx + 1) ; last param is length not end index
	} else {
		return text
	}
}

ReadIniCfg(path, section, key) {
    IniRead, OutputVar, %path%, %section%, %key%
    return OutputVar
}

/*
	ExpandEnvironmentVariables - expand env varaibles (without using EnvGet, as #NoEnv may be enabled)
	https://www.autohotkey.com/board/topic/9516-function-expand-paths-with-environement-variables/
*/
ExpandEnvironmentVariables(ByRef path) {
	VarSetCapacity(dest, 2000) 
	DllCall("ExpandEnvironmentStrings", "str", path, "str", dest, int, 1999, "Cdecl int") 
	return dest
}

/*
	abstraction of RegRead command, that wraps in a try statement to return empty string if no value was read. However, it is up to the caller to know if they key they read was valid, as blank default keys and non existent keys will return "".
	@param key
	@param value - value to read. if default value, leave this blank.
*/
RegRead(key, value="") {
	try {
		if (value) {
			RegRead, result, %key%, %value%
		} else {
			RegRead, result, %key%
		}
	}
	return result
}

RegWrite(key, valueName="", value="", valueType="REG_SZ", overwrite=true, createNew=false) {
	existing:= RegRead(key, valueName)
	if (existing) {
		if (!overwrite) {
			return
		}
	}
	if (!existing && !createNew) {
		return
	}

	RegWrite, %valueType%, %key%, %valueName%, %value%
}

RegDelete(key, valueName="") {
	try {
		if (valueName) {
			RegDelete, %key%, %valueName%

		} else {
			RegDelete, %key%
		}
	}
}
StringUpper(string, titleCase=false) {
	StringUpper, string, string, % (titleCase) ? "T" : ""
	return string
}

;remarks - if cell value is null, skip the element. invalid for csv. See combineArrayAdvanced
CombineArray(ByRef arr, ByRef combiner="`,") {
	token:= ""
	accumulator:= ""
	for key, val in arr {
		if (!(val = "")) { ;TODO check code for if (variable) definition, it doesnt handle string literal zero like other languages
			accumulator.= val combiner
		}
	}
	return SubStr(accumulator, 1, StrLen(accumulator) - (StrLen(combiner)))
}

ReadFileAsString(path) {
	FileRead, fileContents, %path%
	return fileContents
}

GetFileTypeName(ext) {
	extKey:= "HKCR\" FullFileExtension(ext)
	return RegRead(extKey)
}

GetExpectedFileTypeName(ext) {
	rawExtension:= RawFileExtension(ext)
    return rawExtension FILETYPE_SUFFIX
}

GetExtensionKey(ext) {
	return "HKCR\" FullFileExtension(ext)
}

GetFileTypePath(ext) {
	fileType:= GetFileTypeName(ext)
	if (fileType) {
		return "HKCR\" fileType
	}
}

;folderContents:= new FolderContentsClass("C:\views", true, true)
;ContextMenuResourceManager:= new ContextMenuResourceManagerClass(folderContents)

;csvs:= ContextMenuResourceManager.GetFilePathsByWriteType("HKEY_CLASSES_ROOT_Directory")


/*
	ArrayRemoveDuplicates - remove duplicates using "hashset"
	@param arr.
	@return modified unique arr
*/
ArrayRemoveDuplicates(ByRef arr) {
	set:=[]
	for i, val in arr {
		set[val]:= 1
	}
	unique:= []
	for i, val in arr {
		if (set[val] = 1) {
			set[val]:= 0
			unique.push(val)
		}
	}
	return unique
}

/*
	RawFileExtention

	Given a file extension that may or may not have leading period, return only the contents without period
*/
RawFileExtension(ext) {
	return StrReplace(ext, ".", "")
}

/*
	FullFileExtension

	Given a file extension that may or may not have leading period, return .{ext}
*/
FullFileExtension(ext) {
	return (InStr(ext, ".")) ? ext : "." ext
}

;StringUtils
;Get all text before the last index of a char sequence. More formally, Substring(1, indexOf(charseq) - 1)
StrGetBeforeLastIndexOf(ByRef text, charSeq) {
	lastIdx:= InStr(text, charSeq,,0)
	return SubStr(text, 1, lastIdx - 1)
}

StrGetAfterFirstIndexOf(ByRef text, charSeq) {
	foundIdx:= InStr(text, charSeq)
	firstIdx:= (foundIdx > 0) ? foundIdx + StrLen(charSeq) : 1
	return SubStr(text, firstIdx)
}

DeleteUserChoice(extension) {
	extPath:= "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts\" extension
	userChoice:= extPath "\UserChoice"
	RegDelete(extPath) ;prompts user to pick
	;RegDelete(userChoice)

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
CreateOrUpdateFileType(ext, force=true) {
	if (ext = "") {
		throw "GetOrCreateFileTypeHandler - ext param is blank"
	}
	fileType:= getFileTypeName(ext)
	if (fileType = "" || force = true) {
		fileType:= ""
		fileType:= RawFileExtension(ext) FILETYPE_SUFFIX
		RegWrite("HKCR\" ext,, fileType,, force, true) ;here we can create the new ext key if doesnt exist, but still dont overwrite if it exists. Creating new ext will be rare, but might be useful so you can run the script before programs that use those ext's are downloaded
		createFileType(fileType)
	}

	return fileType
}

updateFileType(ext, fileType, force=true) {
	RegWrite("HKCR\" ext,, fileType,, force, true)
	return fileType
}

createFileType(fileType) {
	RegWrite, REG_SZ, % "HKCR\" fileType
	return fileType
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

createOrUpdateNestedMenu(containingShellPath, keyName, iconPath="", displayName="") {
	keyPath:= containingShellPath "\" keyName
	menuExists:= RegRead(keyPath, "MUIVerb")

	displayname:= (displayName) ? displayName : keyName
	if (!menuExists) {
		RegDelete(keyPath)
		RegWrite(keyPath)
		RegWrite(keyPath "\" Shell)
		RegWrite(keyPath, "MUIVerb" displayName)
		RegWrite(keyPath, "SubCommands", "")
	}
	if (icon) {
		RegWrite(keyPath, "Icon", iconPath)
	}
}

/*
	locateIconPath

	Locate icon path based on absolute path (env variables are ok) or relative in \resources\ico\ext.

	@param pathPattern - file path, .ext in \resources\ico\ext, or filename (must include ext) in \resources\ico.

	@return unexpanded path
*/
locateIconPath(pathPattern) {
	expandedPathPattern:= ExpandEnvironmentVariables(pathPattern)
	if (!FileExist(expandedPathPattern)) {
		split:= StrSplit(pathPattern, ".")
		if (split[split.maxIndex()] = "ico") {
			pathPattern:= WORKING_DIRECTORY "\resources\ico\" pathPattern
		} else {
			pathPattern:= WORKING_DIRECTORY "\resources\ico\ext\" RawFileExtension(pathPattern) ".ico"
		}
		expandedPathPattern:= ExpandEnvironmentVariables(pathPattern)
		if (!FileExist(expandedPathPattern)) {
			return
		}
	}
	return (EXPAND_ENVIRONMENT_VARIABLES) ? expandedPathPattern : pathPattern
}

/*
	resolveUserChoice

	User choice keys can be in HKCR\Application for Regular apps or HKCR\ for windows store apps. windows store apps are a hashed value, something like AppX4320202...
	User can give the key name in either location, and this method will return the correct key path segment.

	Implementation:
		3rd party keys dont have standard naming. They may or may not have a default value. So instead, check the if it is a Microsoft App, by checking {UserChoicePattern}\Application @ApplicationName key/value pair.

	Remarks
		- No validation is done on path. Caller should validate paths if trying to write keys.

	@param userChoicePattern - either something like AppX3cx04417ybaf9kz7fem54fc937697n6k or notepad++.exe
	@return partial path segment.
		-if microsoft app, userChoicePattern is returned.
		-else, return Applications\{userChoicePattern}
*/
resolveUserChoice(userChoicePattern) {
	if (InStr(userChoicePattern, "Applications\") = 1) {
		return userChoicePattern
	}
	testPath:= "HKCR\" userChoicePattern "\Application"
	isMicrosoftApp:= (RegRead(testPath, "ApplicationName")) ? true : false
	return (isMicrosoftApp) ? userChoicePattern : "Applications\" userChoicePattern
}

/*
	StrTrimSuffix

	Trim trailing suffix. Compared to StrGetBeforeLastIndexOf, this method only checks matches at the very end of the string. text before matches in the middle of the string wont be returned.
*/
StrTrimSuffix(str, suffix) {
	suffixLength:= StrLen(suffix)
	strLength:= StrLen(str)
	startIdx:= strLength - suffixLength + 1
	if (InStr(SubStr(str, startIdx), suffix) = 1) {
		return SubStr(str, 1, startIdx - 1)
	}
	return str
}
