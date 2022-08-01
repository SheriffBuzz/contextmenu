/*
    ContextMenuResourceManager

    Abstraction of FolderContents, and provides shorthands to fetch specific fileInfo detail needed by all sub actions of WriteContextMenu.ahk
*/
class ContextMenuResourceManagerClass {

	__New(ByRef folderContentsClass) {
		this.folderContents:= folderContentsClass
	}

	GetActionCsvFilePathsByWriteType(writeType) {
		funcRef:= this.ContextMenuFileInfoToCsvCurry(writeType)
		return this.folderContents.GetFilePathsFromFileInfos(funcRef)
	}

	/*
		ContextMenuFileInfoToCsvBase

		We want to allow for multiple csv files, if they start with our given pattern.
	*/
	ContextMenuFileInfoToCsvBase(ByRef filePattern, ByRef fileInfo) {
		idx:= InStr(fileInfo.fileName, filePattern)
		return fileInfo.ext = ".csv" && (idx= 1)
	}

	/*
		ContextMenuFileInfoToCsvCurry
		return funcRef - predicate (fileInfo) -> boolean should file be returned
	*/
	ContextMenuFileInfoToCsvCurry(filePattern) {
		funcRef:= ObjBindMethod(this, "ContextMenuFileInfoToCsvBase", filePattern)
		return funcRef
	}
}