/*
	Wrapper for resourceRequest. It captures the state of a request - which paths in our resources folder should be included or excluded
*/
class ResourceRequestClass {
	__New(json) {
		this.json:= json
		this.fileInfosForDelete:= []
		this.resourcesPath:=
		this.isForDelete:= false
	}

    clone() {
        return new ResourceRequestClass(this.json)
    }

	setResourcesPath(resourcesPath) {
		this.resourcespath:= resourcesPath
	}
	
	addFileInfoForDelete(ByRef fileInfo) {
		this.fileInfosForDelete.push(fileInfo)
	}

	getFileInfosForDelete() {
		return this.fileInfosForDelete
	}

    getFilePathsForDelete() {
        return ArrayMapByPropertyName(this.getFileInfosForDelete(), "filePath")
    }

	isMatch(ByRef fileInfo) {
        if (!this.resourcesPath) {
            throw "ResourceRequest - resources path not set"
        }
		if ((InStr(fileInfo.dir, this.resourcesPath "\ico") = 1)) { ;filter out /ico resources as they arent used by script, only set in Registry Keys
			return false
		}
		shouldFilterIncludes:= IsObject(this.json.includePaths) && this.json.includePaths.count() > 0
		shouldFilterExcludes:= IsObject(this.json.excludePaths) && this.json.excludePaths.count() > 0

		shouldInclude:= (shouldFilterIncludes) ? (this.isFilterMatch(fileInfo, this.resourcesPath, this.json.includePaths)) : true
		shouldExclude:= (shouldFilterExcludes) ? (this.isFilterMatch(fileInfo, this.resourcesPath, this.json.excludePaths)) : false

		return (shouldInclude && !shouldExclude)
	}

	/*
		isResourcesRootMatch

		tests if a path is resources root. Caller can pass "\" or "/" to specify root of the resources folder. This is less ambiguous that sending an empty path, but also means the filepath wouldnt be correct if the resourcespath + testPattern were combined (ie. your root is C:\project\resources and testPattern is "\", you would get "C:\project\resources\, which would fail InStr() = 1)
	*/
	isResourcesRootMatch(fileInfo, resourcesPath, testPattern) {
		if (testPattern = "\" || testPattern = "/") { ;if send / or \, then only files in root of resources are allowed
			if (fileInfo.dir = resourcesPath) {
				return true
			}
		}
		return false
	}

	isFilterMatch(fileInfo, resourcesPath, testPaths) {
		for i, testPath in testPaths {
			testPath:= StrReplace(testPath, "/", "\")
			if (this.isResourcesRootMatch(fileInfo, resourcesPath, testPath) || (InStr(fileInfo.filePath, resourcesPath "\" testPath) = 1)) {
				return true
			}
		}
		return false
	}
}
