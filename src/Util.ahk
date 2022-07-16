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