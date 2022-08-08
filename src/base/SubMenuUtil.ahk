#Include %A_LineFile%\..\..\Util.ahk

class SubMenuUtilClass {
    resolveAliases(ByRef segments) {
        first:= segments[1]
        if (first = "Background") {
            segments[1]:= REGISTRY_KEY_DIRECTORY_BACKGROUND
        } else if (first = "Directory") {
            segments[1]:= REGISTRY_KEY_DIRECTORY
        } else if (first = "File") {
            segments[1]:= REGISTRY_KEY_FILE
        } else {
            fileTypePath:= GetFileTypePath(first)
            if (fileTypePath) {
                segments[1]:= fileTypePath
            }
        }
        segments[1]:= StrTrimSuffix(segments[1], "\shell")
    }

    /*
        getFullPath

        Construct a full registry path given an array of segments
        Inject \shell between our segments, except after the last segment. The \shell is added later to the last key in the workflow (that is the target reg KeyPath that a write action writes a keyName), so we can first do some processing on the last key
    */
    getFullPath(ByRef segments) {
        if (segments.count() <= 1) {
            return segments
        }
        modified:= []
        for i, segment in segments {
            modified[i]:= (i < segments.MaxIndex()) ? segment "\shell" : segment
        }
        return CombineArray(modified, "\")
    }

    /*
        getRootAlias

        Get shorthand identifier for sub menu. In SubMenu.csv the root must be given, but for our file or folder actions it is ommitted, but can be calculated.
        
        @return shorthand - For folder types (Directory, Background) and File with no extension, it is the writeType of the action. For files with specific extensions, it is the extension with leading "."
    */
    getRootAlias(ByRef action, ByRef model) {
        writeType:= action.writeType
        extension:= model.extension
        return (extension) ? extension : writeType
    }

    /*
        processNestedMenu

        @param rootPath
        @param keyPath - set ByRef
        @param keyName - set ByRef
        @param rootShorthand
    */
    processNestedMenu(ByRef rootPath, ByRef keyPath, ByRef keyName) {
        segments:= StrSplit(keyName, "\")
        segments.InsertAt(1, rootPath)
        if (segments.count() > 2) {
            leafKeyName:= segments[segments.MaxIndex()]

            this.resolveAliases(segments)

            leafPath:= segments.pop()

            deepestSubMenuContainingPath:= this.getFullPath(segments)

            muiVerb:= RegRead(deepestSubMenuContainingPath, "MUIVerb")
            if (!muiVerb) {
                throw "SubMenu not resolved. Create SubMenu entries first.`n" deepestSubMenuContainingPath
            }
            keyPath:= deepestSubMenuContainingPath "\shell"
            keyName:= leafKeyName
        }
    }

    processNestedMenuForModel(ByRef actionContext, ByRef model) {
        keyName:= model.keyName
        keyPath:= model.keyPath

        if (!keyName || !keyPath) {
            throw "SubMenuUtil - Unable to process nested menu - key name or path not set on model."
        }

        if (InStr(keyName, "\")) {
            rootShorthand:= this.getRootAlias(actionContext, model)
            this.processNestedMenu(rootShorthand, keyPath, keyName)
        }
        model.keyName:= keyName
        model.keyPath:= keyPath
    }

    /*
        getSubMenuHandle

        Return non-root submenu segments for a model's KeyName. This can be used by the delete action to skip deleting parent submenus, when the resourceRequest file pattern requests to delete items in the parent path for delete but excludes the child path.

        @return SubMenuPartialPath - SubMenu Segments joined by "\". This should match the csv representation for keyName, (It isnt the full registry path, as those have \shell between the key segments)
    */
    getSubMenuHandle(ByRef action, ByRef model, skipRoot=false) {
        if (!model.keyName || !InStr(model.keyName, "\")) {
            return ""
        }
        rootShorthand:= this.getRootAlias(action, model)
        segments:= StrSplit(model.keyName, "\")
        if (!(action.writeType = "SubMenu")) {
            segments.pop() ;last item is a menu item for write types other than SubMenu
        }
        if (!skipRoot) {
            segments.InsertAt(1, rootShortHand)
        }
        return CombineArray(segments, "\")
    }
}
global SubMenuUtil:= new SubMenuUtilClass() ;@Export SubMenuUtil
