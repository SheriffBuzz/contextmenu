#NoEnv
path:= A_Args[1]
folderSplit:= StrSplit(path, "\")
maxIdx:= folderSplit.MaxIndex()
folderName:= folderSplit[maxIdx]
folderName:= StrReplace(folderName, """", "") ;directory background leaves a trailing quote with both %1 and %v, so as a hack, just remove it
Clipboard:=
Clipboard:= folderName
Clipwait
