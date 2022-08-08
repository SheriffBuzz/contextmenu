/*
    ResourceModule

    Logical grouping of of resources within the resources directory. It is based on a relative filepath in the resources directory.

    Module is maintained as a relative filepath.
    for \resources\admin\hotswap, the module would be admin\hotswap.
    for \resources (root) module, the module is a special value, "\".

    Remarks
    -This class maintains lookup structures which the values are "FileInfo" objects. See FolderContents.ahk for details as this is a plain object.
    -ModulePatterns are the full relative path from resources.
    -File Names in resources\ico\ext with "." in the name are not supported
*/

class ResourceModuleClass {
    __New() {
        this.csvs:= {} ;csv's in \resources\{modulePath}
        this.icons:= {} ;icons in \resources\ico\{modulePath} or \resources\ico\ext\{modulepath}
    }

    addCsv(ByRef fileInfo) {
        this.csvs[fileInfo.fileName]:= fileInfo
    }

    addIcon(ByRef fileInfo) {
        this.icons[fileInfo.fileName]:= fileInfo
    }

    getCsvFilePath(pattern) {
        return this.csvs[pattern]
    }

    getIconFilePath(pattern) {
        return this.cons[pattern]
    }
}
