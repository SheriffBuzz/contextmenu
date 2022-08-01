
#Include %A_LineFile%\..\..\..\Util.ahk
#Include %A_LineFile%\..\..\Constants.ahk
#Include %A_LineFile%\..\WorkflowUtil.ahk
#Include %A_LineFile%\..\..\SubMenuUtil.ahk

/*
    SubMenuWorkflow

    keyShorthand - shorthand path representation. Should start with either File, Directory, Background or a file extension. Each following segment in the path represents \{segment}\shell. This way, user does not have to specify shell every time.
*/
class SubMenuWorkflow {
    defaultParams:=
    
    __New() {
        this.defaultParams:= {}
    }

    execute(ByRef actionContext, ByRef model) {
        keyShorthand:= model.keyShortHand
        displayName:= model.displayName
        icon:= model.icon

        segments:= StrSplit(keyShorthand, "\")
        SubMenuUtil.resolveAliases(segments)

        fullPath:= segments[1]
        unprocessedDepth:= 0
        for i, segment in segments {
            if (i = 1) { ;first path segment should lead to a \shell, not a valid submenu
                continue
            }
            fullPath.= "\shell\" segment
            if(!this.isSubMenu(fullPath)) {
                unprocessedDepth:= unprocessedDepth + 1
            }
        }
        if (unprocessedDepth > 1) {
            model.error:= "Cannot process submenu. Processing is not done recursively, so for multiple sub menus, define the top level ones first."
            return
        }
        if (unprocessedDepth < 1) {
            return
        }
        this.createSubMenu(fullPath, (displayName) ? displayName : segments[segments.maxIndex()], icon)
    }

    createSubMenu(keyPath, displayName, icon) {
        iconResourcePath:= locateIconPath(icon)

        RegWrite(keyPath,,,,true, true)
        RegWrite(keyPath "\Shell",,,,true, true)
        RegWrite(keyPath, "MUIVerb", displayName,,true, true)
        RegWrite(keyPath, "Subcommands", "",,true, true)
        if (iconResourcePath) {
            RegWrite(keyPath, "Icon", """" iconResourcePath """", "REG_EXPAND_SZ", true, true)
        }
    }

    isSubMenu(keyPath) {
        muiVerb:= RegRead(keyPath, "MUIVerb")
        return (muiVerb) ? 1 : 0
    }
}
