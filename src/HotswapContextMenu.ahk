#NoEnv
#Include %A_LineFile%\..\Util.ahk
#Include %A_LineFile%\..\json\JXON.ahk

#Include %A_LineFile%\..\..\WriteContextMenu.ahk

HotswapContextMenu(A_Args[1], A_Args[2])

HotswapContextMenu(cfgPath, configurationName) {
    global defaultCfg
    if (!cfgPath || !configurationName) {
        Msgbox, % "Missing command line arguments.`n`nExpected: [Cfg Path] [configurationName]`nActual: [" cfgPath "] [" configurationName "]"
        return
    }
    json:= getJsonCfg(cfgPath)
    config:= getConfigurationByName(json, configurationName)
    applyConfigurationLevelConfig(json.defaultCfg, config)

    if (!IsObject(config)) {
        Msgbox, % "Config for " configurationName " not found in:`n" cfgPath
        return
    }
    if (config.writeType && !IsObject(config.writeType)) {
        if (!IsObject(config.resourcePatterns)) {
            config.resourcePatterns:= []
        }
        if (IsObject(json.defaultCfg)) {
            global defaultCfg
            defaultCfg:= json.defaultCfg
        }
        WriteContextMenuMain(config.writeType, config.resourcePatterns)
    } else {
        MsgBox, % "WriteType Field missing on configuration"
    }
}

getJsonCfg(path) {
    try {
        file:= ReadFileAsString(path)
        return Jxon.load(file)
    } catch e {
        Msgbox, % "HotswapContextMenu - error reading json config for path:`n" path "`n`n" e.message
        ExitApp
    }
}

getConfigurationByName(json, name) {
    return json.configurations[name]
}

applyConfigurationLevelConfig(ByRef default, ByRef configuration) {
    apply(default, {forceDeleteSubMenus: configuration.forceDeleteSubMenus}, true)
}
