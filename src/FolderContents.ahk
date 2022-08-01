/*
	FolderContents

	Purpose - Get various details about files and directories. It abstracts the file loops and returns objects. It returns top level details about files and folders, as well as a list of custom object fileInfo that has the file details per file.



	@return object {} - props : fileNames[], directories[], fileNamesNoExt[], fullPaths[]
		-fileInfos[] - fileInfo {}: fileName, dir, filePath, fileNameNoExt, ext, rawExt

	Remarks - Files and folders are looped separately, to avoid edge case where A_LoopFileExt returns an ext even though the path is a folder. This happens when the last path segment of a directory contains a . with only numbers or letters following it. ie C:\views\App-1.34
*/
class FolderContentsClass {
	/*
		__New()

		@param folderpath - env variables allowed
		@param recurse
		@param includeDirectories - bool
		@param extension - match extension. pass include directories = true if you want to pick up folders with an ext name (ie. .git)
	*/
	__New(folderPath, recurse:=false, includeDirectories:=false, extension="") {
		this.fileNames:= []
		this.directories:= []
		this.fileNamesNoExt:= []
		this.fullPaths:= []
		this.fileInfos:= []
		fileNames:=[]
		folderContents:= new FolderContentsClass()

		folderPath:= ExpandEnvironmentVariables(folderPath)
		if (!FileExist(folderPath)) {
			return {}
		}
		filePattern:= folderPath "\*" extension
		mode:= "" ;Ahk remarks F = Include files. If both F and D are omitted, files are included but not folders.
		if (recurse) {
			mode.= "R"
		}
		;process files and folders separately, to avoid ambigous folders with .ext in the last path segment
		Loop, Files, %filePattern%, % "F" mode
		{
			fileName:= A_LoopFileName
			dir:= A_LoopFileDir
			rawExt:= A_LoopFileExt
			filePath:= A_LoopFilepath
			ext:= FullFileExtension(rawExt)
			if (!ext) {
				throw "Get Folder Contents - file was parsed but no ext was found."
			}
			fileNameNoExt:= StrGetBeforeLastIndexOf(fileName, ext)

			fi:= {}
			fi.fileName:= fileName
			fi.dir:= dir
			fi.filePath:= filePath
			fi.fileNameNoExt:= fileNameNoExt
			fi.ext:= ext
			fi.rawExt:= rawExt
			this.fileInfos.push(fi)

			this.fileNames.push(fileName)
			this.directories.push(dir)
			this.fullPaths.push(filePath)
			this.fileNamesNoExt.push(fileNameNoExt)
		}
		
		
		if (includeDirectories) {
			Loop, Files, %filePattern%, % "D" mode
			{
				;we dont need the other infos for folders, but they are inaccurate if last path segment contains .something and interpreted as a file. So beware of caveats if extending this functionality
				filePath:= A_LoopFilepath

				this.directories.push(filePath)
				this.fullPaths.push(filePath)
			}
		}
		this.directories:= ArrayRemoveDuplicates(this.directories)
		this.fullPaths:= ArrayRemoveDuplicates(this.fullPaths)
		this.fileNames:= ArrayRemoveDuplicates(this.fileNames)
		this.fileNamesNoExt:= ArrayRemoveDuplicates(this.fileNamesNoExt)
	}

	/*
		GetFilePathsFromFileInfos
		@param FileInfoPredicateRef - (fileInfo) -> boolean
	*/
	GetFilePathsFromFileInfos(FileInfoPredicateRef="") {
		paths:= []
		for i, fileInfo in this.fileInfos {
			if (FileInfoPredicateRef) {
				if (%FileInfoPredicateRef%(fileInfo) = true) {
					paths.push(fileInfo.FilePath)
				}
			} else {
				paths.push(fileInfo.FilePath)
			}
		}
		return paths
	}
}
