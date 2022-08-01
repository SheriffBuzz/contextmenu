
# File

[File.csv](/resources/File.csv)

|KeyName                 |Command                                                          |Icon                                           |ContextMenuName       |Extension      |UserChoice                          |filetype|
|------------------------|-----------------------------------------------------------------|-----------------------------------------------|----------------------|---------------|------------------------------------|--------|
|GIMP                    |"C:\Program Files\GIMP 2\bin\gimp-2.10.exe" "%1"                 |                                               |                      |               |AppX43hnxtbyyps62jhe9sqpdzxn1790zetc|        |
|GIMP                    |"C:\Program Files\GIMP 2\bin\gimp-2.10.exe" "%1"                 |                                               |                      |.ico           |                                    |        |
|Paint                   |"C:\WINDOWS\system32\mspaint.exe" "%1"                           |                                               |                      |               |AppX43hnxtbyyps62jhe9sqpdzxn1790zetc|        |
|Notepad                 |C:\Windows\System32\notepad.exe                                  |                                               |                      |               |                                    |        |
|zSciTE4                 |"C:\Program Files\AutoHotkey\SciTE\SciTE.exe" %1                 |                                               |SciTE4                |.ahk           |                                    |        |
|VSCode                  |"%USERPROFILE%\AppData\Local\Programs\Microsoft VS Code\Code.exe"|                                               |                      |               |                                    |        |
|!Notepad++              |"C:\Program Files\Notepad++\notepad++.exe"                       |                                               |Notepad++             |               |                                    |        |
|Excel                   |"C:\Program Files (x86)\Microsoft Office\root\Office16\EXCEL.exe"|                                               |                      |.csv&#124;.xls&#124;.xlsx|                                    |        |
|z6CopyGitHubMarkdownLink|CopyGitHubMarkdownLink.exe                                       |githubdesktop.ico                              |CopyGitHubMarkdownLink|.md            |                                    |        |
|z1Copy Path             |CopyFilepath.exe "%V"                                            |%SYSTEMDRIVE%\WINDOWS\system32\SnippingTool.exe|Copy Path             |               |                                    |        |
|z2Copy Name             |CopyFilenameNoExt.exe                                            |%SYSTEMDRIVE%\WINDOWS\system32\SnippingTool.exe|Copy Name             |               |                                    |        |

  * KeyName [**required**] Registry key name. The name of the keys determines the menu order. If you would like to alter the order, prefix or postfix the keyName with a special character or Z. Then, set the display name with **ContextMenuName**
  * Command [**required**] System command, Exe, or path relative to [**\bin**](/bin)
    * Arguments are supported. Pass them in quotes following the executable path.
    * Quoting the exe is optional if the path does not have spaces, but recommended
  * Icon [**optional**]
    * Extension name - *.{Extension}* in [**\resources\ico\ext\\{extension}.ico**](/resources/ico/ext)
    * IconName.ico in [**\resources\ico**](/resources/ico)
    * Full file path. Environment variables like %PROGRAMFILES% are allowed
  * ContextMenuName [**optional**] Display name for context menu. Uses KeyName if omitted
  * Extension [**optional**] - one or more extensions separated by the pipe "|" symbol. Actions will be created on each extension's filetype handler, they are not shared.
  * UserChoice [**optional**]
    * User choice overrides the shell menus of an extension's filetype. Remove the association using FileTypesMan if you do not wish to use it.    
    * User choice keys can be in HKCR\Application for Regular apps or HKCR\ for windows store apps. windows store apps are a hashed value, something like AppX4320202...
	  * User can give the key name in either location, and this method will return the correct key path segment.
	  * This is useful for default Microsoft apps that have a user choice on picture file types. You cannot remove the user choice if it is controlled by a Microsoft app, the registry keys will reassociate immediately if deleted. For some file types like pictures, it is not a big deal if we add menus to multiple extensions, especially if they are all related.
  * FileType [**optional**] - Creates menu on a filetype, and associates the extension with that filetype.
    * This may be useful when an extension has an existing shared filetype, and you want to keep the menu entries on it.
    * Using shared file types means less csv config needed by the project, but greater chance you get a menu item you dont want on the many possible extensions that share the filetype.
    * If **FileType** or **UserChoice** are not specified, a new filetype will be created, "**{extension}file**". The original file type will be unlinked. You can relink it manually with RegEdit or FileTypesMan. In RegEdit, change the default value for HKCR\.{extension} to the filetype.

### Remarks
  - You can specify UserChoice, Filetype, Extension, but only one will be written. The order of precedence is UserChoice, FileType, Extension. If you have enabled errors to be shown in the script, you will get a message as to which location will be written to.

![FileExplorerView](https://user-images.githubusercontent.com/83767022/182270933-a825f52b-3453-4623-b12b-13b53b3ddd1b.png)

# Directory (Folder)

[Directory.csv](/resources/Directory.csv)

|KeyName                 |Command                                                          |Icon                                           |ContextMenuName       |
|------------------------|-----------------------------------------------------------------|-----------------------------------------------|----------------------|
|cmd2                    |"%SYSTEMROOT%\system32\cmd.exe" /s /k pushd "%V"                 |%SYSTEMROOT%\System32\cmd.exe                  |Open with cmd         |
|zCopy aPath             |CopyFilepath.exe "%V"                                            |%SYSTEMROOT%\system32\SnippingTool.exe         |Copy Path             |
|zCopy FolderName        |CopyFolderName.exe ""%V"""                                       |%SYSTEMROOT%\system32\SnippingTool.exe         |Copy Name             |

  * KeyName [**required**] Registry key name. The name of the keys determines the menu order. If you would like to alter the order, prefix or postfix the keyName with a special character or Z. Then, set the display name with **ContextMenuName**
  * Command [**required**] System command, Exe, or path relative to [**\bin**](/bin)
    * Arguments are supported. Pass them in quotes following the executable path.
    * Quoting the exe is optional if the path does not have spaces, but recommended
  * Icon [**optional**]
    * IconName.ico in [**\resources\ico**](/resources/ico)
    * Full file path. Environment variables like %PROGRAMFILES% are allowed
  * ContextMenuName [**optional**] Display name for context menu. Uses KeyName if omitted

![DirectoryExplorerView](https://user-images.githubusercontent.com/83767022/182274072-7500902f-be0b-49dc-8ada-c137f84fed7a.png)

# Background (Directory Background)

[Background.csv](resources/Background.csv)

|KeyName                 |Command                                                          |Icon                                           |ContextMenuName       |
|------------------------|-----------------------------------------------------------------|-----------------------------------------------|----------------------|
|cmd2                    |"%SYSTEMROOT%\system32\cmd.exe" /s /k pushd "%V"                 |%SYSTEMROOT%\System32\cmd.exe                  |Open with cmd         |
|pwshise                 |"%SYSTEMROOT%\system32\cmd.exe" /c start powershell_ise.exe      |%SYSTEMROOT%\System32\WindowsPowerShell\v1.0\powershell_ise.exe|Powershell ISE Here   |
|zCopy aPath             |CopyFilepath.exe "%V"                                            |%SYSTEMROOT%\system32\SnippingTool.exe         |Copy Path             |
|zCopy FolderName        |CopyFolderName.exe "%V"                                          |%SYSTEMROOT%\system32\SnippingTool.exe         |Copy Name             |
|!Toolkit\StartMenu      |ExplorerSelect.exe "%ProgramData%\Microsoft\Windows\Start Menu\Programs"|toolkit.ico                                    |Start Menu            |
|!Toolkit\ipconfig       |"%SYSTEMROOT%\System32\cmd.exe" /s /k ipconfig                   |%SYSTEMROOT%\System32\cmd.exe                  |ipconfig              |
|!Toolkit\EditEnvironmentVariables|rundll32 sysdm.cpl,EditEnvironmentVariables                      |SystemProperties.ico                           |Environment Variables |
|!Toolkit\RegEdit        |RegEdit                                                          |RegEdit.ico                                    |Registry Editor       |
|!Toolkit\ToolkitOpenContextMenuResources|ExplorerSelectInWorkspace.exe "%V" "Toolkit" "\registry\contextMenu\resources" "C:"|toolkit.ico                                    |ContextMenu - Resources|
|!Toolkit\IconDll\imageres|ExplorerSelect.exe "%SystemRoot%\system32\imageres.dll"          |                                               |                      |

  * KeyName [**required**] Registry key name. The name of the keys determines the menu order. If you would like to alter the order, prefix or postfix the keyName with a special character or Z. Then, set the display name with **ContextMenuName**
  * Command [**required**] System command, Exe, or path relative to [**\bin**](/bin)
    * Arguments are supported. Pass them in quotes following the executable path.
    * Quoting the exe is optional if the path does not have spaces, but recommended
  * Icon [**optional**]
    * IconName.ico in [**\resources\ico**](/resources/ico)
    * Full file path. Environment variables like %PROGRAMFILES% are allowed
  * ContextMenuName [**optional**] Display name for context menu. Uses KeyName if omitted

![BackgroundExplorerView](https://user-images.githubusercontent.com/83767022/182273961-cf600a85-bb41-45a3-ab46-4ee55b5222c0.png)

# SubMenu

[SubMenu.csv](resources/SubMenu.csv)

|KeyShorthand|DisplayName                             |Icon       |
|------------|----------------------------------------|-----------|
|Background\\!Toolkit|Toolkit                                 |toolkit.ico|
|Background\\!Toolkit\IconDll|IconDll                                 |           |
|.ahk\AhkSubmenu|AhkSubmenu                              |           |

  * KeyShorthand - Sub menus delimited by "\"
    * Root - Must start with one of the following: [Background, Directory, File, .{extension}, AbsolutePath]
      * Background
      * Directory
      * File - added for all file types
      * Extension - added for specific file extension.
        * See Absolute path if the extension is tied to a UserChoice. Either delete the association from extension to UserChoice or use absolute path.
    * AbsolutePath - Absolute Registry path to registry key.
      * HKCR\AppX43hnxtbyyps62jhe9sqpdzxn1790zetc\PhotosSubmenu
      * HKCR\Directory\Background\Toolkit
   * DisplayName - name that shows up on menu
   * Icon [**optional**]
     * Relative link in **\resources\ico**
       * **toolkit.ico**
       * **ext/java.ico**
     * Full file path. Environment variables like %PROGRAMFILES% are allowed

**Remarks**

Multi Level sub menu definitions are not supported. If you have a submenu that is nested inside another, define that submenu first in the csv.

![SubMenuExplorerView](https://user-images.githubusercontent.com/83767022/182251299-872ff92f-f340-4982-ac20-0333e2e8f7cd.png)

![SubMenuExplorerViewExtension](https://user-images.githubusercontent.com/83767022/182253010-2f49c5fd-a528-463e-99c4-6ac6e0e4db4b.png)

# DefaultProgram

[DefaultProgram.csv](/resources/DefaultProgram.csv)

|Extension|ActionKeyOrCommand                      |IsCreateNewFileType|
|---------|----------------------------------------|-------------------|
|.csv&#124;.sqldefs&#124;.sql&#124;.java|!Notepad++                              |                   |
|.md      |VSCode                                  |                   |
|.xls&#124;.xlsx|Excel                                   |                   |
|.ps1     |"%SYSTEMROOT%\System32\WindowsPowerShell\v1.0\powershell.exe" "-Command" "if((Get-ExecutionPolicy ) -ne 'AllSigned') { Set-ExecutionPolicy -Scope Process Bypass }; & '%1'"|1                  |

 * Extension [**required**] - one or more extensions separated by the pipe "|" symbol. Default actions will be created on each extension's filetype handler, they are not shared.
 * ActionKeyOrCommand [**required**] console command, or the **KeyName** of any entry in [File.csv](/resources/File.csv). It will use the **Command** key for matching KeyName.
   * The row in File.csv does not need extension. The extension filetype is checked first, but if no KeyName matches, then it will check the location for all file extensions (HKCR\*\shell)
   * Limitation - wont work with a KeyName that contains .exe

 * IsCreateNewFileType [**optional**] default is 1. Value is 0 or 1.
   * If enabled, a new filetype will be created with the name {extension}File and the file extension will use the new filetype.
   * This setting which is on by default, and protects the user from overriding other file extension's default program if they have a shared filetype. You can configure multiple extensions in one line with the pipe separator (See extension)
   * UserChoice is not supported. You will need to unlink the extension from any UserChoice to see the changes.

![DefaultProgramExplorerView](https://user-images.githubusercontent.com/83767022/182257468-a1191613-dd2a-4d71-864d-f0d5c2050f56.png)

# Icon

[Icon.csv](/resources/Icon.csv)

|extension|Icon                                    |
|---------|----------------------------------------|
|.csv     |C:\Program Files\Notepad++\notepad++.exe|
|.java    |                                        |


  * Extension
  * Icon [**optional**] if file exists in [**\resources\ico\ext\\{extension}.ico**](/resources/ico/ext), otherwise [**required**]
    * Relative link [**\resources\ico\ext\\csv.ico**](/resources/ico/ext/csv.ico)
    * IconName.ico in [**\resources\ico**](/resources/ico)
    * Full file path. Environment variables like %PROGRAMFILES% are allowed

![IconExplorerView](https://user-images.githubusercontent.com/83767022/182250792-2c990ec1-af62-407c-9afc-73e0f8342041.png)


# NewFile

[NewFile.csv](resources/NewFile.csv)

|extension|menuDescription|
|---------|---------------|
|.png     |PNG Image      |
|js       |               |

  * Extension
  * Menu Description [**optional**] Display name for context menu. Appropriate name will be given if omitted.

![NewFile](https://user-images.githubusercontent.com/83767022/182247535-4efb6e68-7c5c-45d1-8975-60aafbbac0ff.png)
