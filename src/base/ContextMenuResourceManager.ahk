#Include %A_LineFile%\..\..\Util.ahk
#Include %A_LineFile%\..\ResourceModule.ahk
/*
    ContextMenuResourceManager

    Abstraction of FolderContents, and provides shorthands to fetch specific fileInfo detail needed by all sub actions of WriteContextMenu.ahk
*/
class ContextMenuResourceManagerClass {

	__New(ByRef sessionContext, ByRef folderContents, defaultResourcesPath) {
		this.sessionContext:= sessionContext
		this.folderContents:= folderContents
		this.defaultResourcesPath:= defaultResourcesPath
		this.moduleNameHierarchyCache:= {} ; map from module name to list of modules and ancestor modules, bottom up
		this.moduleCache:= this.getModuleCache(this.folderContents) ;cache from module (partial path segment of everything after resources dir) to fileInfo
	}

	/*
		getModuleCache 
		@return moduleCache = {
			admin/hotswap: {
				sqlDeveloper.ico: <FILE INFO OBJECT HERE>,
				"eclipse"
			}
		}

		Remarks - for /ico and /ico/ext, module becomes 
	*/
	getModuleCache(ByRef folderContents) {
		moduleCache:= {}
		fileInfos:= folderContents.fileInfos
		for i, fileInfo in fileInfos {
			moduleName:= fileInfo.module
			isIco:= false
			if (InStr(moduleName, "ico") = 1) {
				isIco:= true
				if (InStr(moduleName, "ico\ext") = 1) {
					moduleName:= SubStr(moduleName, 9)
				} else {
					moduleName:= SubStr(moduleName, 5)
				}
				moduleName:= (moduleName = "") ? "\" : moduleName
			}
			fileInfo.module:= moduleName
			module:= moduleCache[moduleName]
			this.moduleNameHierarchyCache[moduleName]:= this.getModuleNameHierarchy(moduleName)
			if (!IsObject(module)) {
				moduleCache[moduleName]:= new ResourceModuleClass()
				module:= moduleCache[moduleName]
			}
			
			if (fileInfo.ext = ".csv") {
				module.addCsv(fileInfo)
			}
			if (isIco) {
				module.addIcon(fileInfo)
			}
		}
		return moduleCache
	}
	GetActionCsvFilePathsByResourceRequest(resourceRequest) {
		funcRef:= this.ContextMenuFileInfoToCsvCurry(resourceRequest)
		return this.folderContents.GetFilePathsFromFileInfos(funcRef)
	}

	GetActionCsvFileInfosByResourceRequest(resourceRequest) {
		funcRef:= this.ContextMenuFileInfoToCsvCurry(resourceRequest)
		return this.folderContents.GetFileInfos(funcRef)
	}

	/*
		ContextMenuFileInfoToCsvBase

		BiPredicate<ResourceRequest, FileInfo, Boolean>

		This predicate function is used by FolderContents class to see if the file resource matches our request criteria. See resourceRequest for more info.
	*/
	ContextMenuFileInfoToCsvBase(ByRef resourceRequest, ByRef fileInfo) {
		fileNamePattern:= resourceRequest.writeType
		if (!fileNamePattern) {
			resourceRequest.error:= "WriteType missing for ResourceRequest"
			return false
		}
		resourcesPath:= (resourceRequest.resourcesPath) ? resourceRequest.resourcesPath : this.defaultResourcesPath
		resourcespath:= ExpandEnvironmentVariables(resourcesPath)

		resourceRequest.setResourcesPath(resourcesPath)

		if (!resourceRequest.isMatch(fileInfo)) {
			return false
		}
		idx:= InStr(fileInfo.fileName, fileNamePattern)
		shouldAdd:= fileInfo.ext = ".csv" && (idx= 1)
		if (shouldAdd && resourceRequest.isForDelete) {
			resourceRequest.addFileInfoForDelete(fileInfo)
		}
		return shouldAdd
	}

	/*
		ContextMenuFileInfoToCsvCurry
		return funcRef - predicate (fileInfo) -> boolean should file be returned
	*/
	ContextMenuFileInfoToCsvCurry(ByRef resourceRequest) {
		funcRef:= ObjBindMethod(this, "ContextMenuFileInfoToCsvBase", resourceRequest)
		return funcRef
	}
	
	/*
		locateIconPath

		Locate icon path based on "module".

		Module is a logical grouping of \resources folder based on folder structure.

		@param module name - partial path segment in \resources
		@param pathPattern - file path, .ext in \resources\ico\ext, or filename (must include ext) in \resources\ico.

		@return unexpanded path
	*/
	locateIconPath(pathPattern, moduleName="") {
		if (pathPattern = "") {
			return ""
		}
		if(FileExist(ExpandEnvironmentVariables(pathPattern))) {
			return pathPattern
		}

		if (!moduleName) {
			logger.WARN(A_ThisFunc " ~ Absolute path not found, module is missing so cant to lookup based on resources cache ~ " pathPattern)
			return
		}
		moduleNameHierarchy:= this.moduleNameHierarchyCache[moduleName]
		extensionTestPattern:= StrReplace(pathPattern, ".", "") ".ico"

		for i, moduleName in moduleNameHierarchy {
			module:= this.moduleCache[moduleName]
			if (module.icons[pathPattern]) {
				fileInfo:= module.icons[pathPattern]
				break
			}
			if (module.icons[extensionTestPattern]) {
				fileInfo:= module.icons[extensionTestPattern]
				break
			}
		}

		if (fileInfo) {
			return fileInfo.filePath
		}
		logger.WARN(A_ThisFunc " ~ Path not found ~ " pathPattern)
	}

	/*
		Get hierarchy of modules, bottom up.

		If an action comes from \resources\admin\hotswap, we should allow user to be able to define resources in \admin\hotswap, \admin, and \ (root of resources)
	*/
	getModuleNameHierarchy(modulePattern) {
		if (modulePattern = "\") {
			return [modulePattern]
		}
		split:= StrSplit(modulePattern, "\")
		hierarchy:= []
		while (split.count() > 0) {
			hierarchy.push(CombineArray(split, "\"))
			split.pop()
		}
		hierarchy.push("\")
		return hierarchy
	}
}
