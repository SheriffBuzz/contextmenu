/*
    ContextMenuCopyPath
    
    Program to copy a filepath/folder path to the clipboard. This is an alternative to the Ctrl Shift Right Click "Copy as Path" Context menu item with 2 main differences - The value is not quoted, (easier use for piping into other applications) and the entry is added to the regular file context menu, not just ctrl shift click. 3rd difference is visual, add an icon (snipping tool) and prefix the registry key with a z to make it appear at the end of all other context menu items defined in rootshell.csv (registry keys added from this application)
*/
#NoEnv
Clipboard:=
Clipboard:= A_Args[1]
Clipwait
