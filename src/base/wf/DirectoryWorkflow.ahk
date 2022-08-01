
#Include %A_LineFile%\..\..\..\Util.ahk
#Include %A_LineFile%\..\..\Constants.ahk
#Include %A_LineFile%\..\WorkflowUtil.ahk

class DirectoryWorkflow {
    defaultParams:=
    
    __New() {
        this.defaultParams:= {keyPath: REGISTRY_KEY_DIRECTORY}
    }

    execute(ByRef actionContext, ByRef model) {
        WorkflowUtil.executeFileOrFolder(actionContext, model)
    }
}
