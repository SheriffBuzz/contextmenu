#NoEnv
path:= A_Args[1]
SplitPath, % path,,,, nameNoExt
Clipboard:=
Clipboard:= nameNoExt
Clipwait
