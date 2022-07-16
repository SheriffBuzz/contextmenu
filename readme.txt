---Context menu v2.
Goals 
- Target machine might not have ahk project so the #Import statements may be invalid. duplicate the functions instead of importing.
- Similarly, the csv file containing cfg should be located relative to contextmenu folder, not the ahk project resources
- Make the csv resource file independent of drive name, so either user USER_PROFILE or SYSTEMDRIVE
- Remove .reg template files as they wont be necessary with new changes. As well you cant use expandable string which our changes require
- The script the writes the reg should be located the same place/sibling folder as ahk scripts that are invoked from context menu. If the script doesnt invoke an exe, we should allow the user to put %bin%\ScriptName.ahk or something and resolve it using %A_LineFile%\bin\ScriptName.ahk


WriteContextMenuIconsOnly - if the file ext is associated with User Choice key, you need to remove that. Can do it with FileTypesMan app from Nirsoft.

To see the updated changes to your current shell, you need to call SHChangeNotify windows function. You can do it indirectly by opening any file extension with FileTypesMan, and hitting ok without changing anything. Otherwise you may need to restart your machine.

https://docs.microsoft.com/en-us/windows/win32/shell/fa-file-types
https://docs.microsoft.com/en-us/windows/win32/api/shlobj_core/nf-shlobj_core-shchangenotify

/*
	writeIconEntry - writes DefaultIcon key into the handler associated witha file type. In the registry, there will be a key .{ext} under HCKR with a default value. That default value points to another key (The handler) where we set our DefaultIcon key.
	-The source of our ico will be in ./resources/ico/ext with file named {ext}.ico. Run this script again if this containing folder moves locations.
	-TODO this is similar to new file method, merge these
	-Removed functionality to delete the entry. If you want to change the ico, use FileTypeMan or delete the registry entries from regedit. Must edit the user choice first in FileTypeMan if you change the ico there, otherwise it will change the ico for all the associated apps with its controlling user choice program. Using this script will not change the icon for the other file types in the user choice.
	-remarks - you may need to remove user choice from fileTypeMan, then run the script. It overrides this config if some other application has said that it is controlling this file type.
		- (eg. lots of icons for text files are defaulted to np++ when you install it)
*/


