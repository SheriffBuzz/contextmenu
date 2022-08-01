
#Include %A_LineFile%\..\..\..\Util.ahk
#Include %A_LineFile%\..\..\Constants.ahk
#Include %A_LineFile%\..\WorkflowUtil.ahk


class BackgroundWorkflow {
    defaultParams:=
    
    __New() {
        this.defaultParams:= {keyPath: REGISTRY_KEY_DIRECTORY_BACKGROUND}
    }

    execute(ByRef actionContext, ByRef model) {
        WorkflowUtil.executeFileOrFolder(actionContext, model)
    }
}
