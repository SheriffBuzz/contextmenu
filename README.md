# Contextmenu
Manage context menus by automating registry writes using ahk. Additional visual guides for FileTypesMan.

## Resources
[How to open Registry Editor](https://support.microsoft.com/en-us/windows/how-to-open-registry-editor-in-windows-10-deab38e6-91d6-e0aa-4b7c-8878d9e07b11)

[FileTypesMan](https://www.nirsoft.net/utils/file_types_manager.html) *Scroll to the bottom of the page for the download*

[FileTypes in Windows](https://docs.microsoft.com/en-us/windows/win32/shell/fa-file-types)

## Best Practices when working with the Registry
 * [Backup your Windows Registry](https://support.microsoft.com/en-us/topic/how-to-back-up-and-restore-the-registry-in-windows-855140ad-e318-2a13-2829-d428a2ab0692)

 * If you download registry (.reg) scripts from the internet, open them in a text editor and inspect the keys they are modifying, before running them. This script modifies registry keys that have the following patterns:
   * **Computer\HKEY_CLASSES_ROOT\*\shell** - Context menu when right clicking a file of any extension
   * **Computer\HKEY_CLASSES_ROOT\\.{fileExtension}\shell** - Context menu when right clicking a file of a specific extension
   * **Computer\HKEY_CLASSES_ROOT\Directory\shell** - Context menu when right clicking a folder
   * **Computer\HKEY_CLASSES_ROOT\Directory\Background\shell** - Context menu when right clicking the empty space in a folder
## Goals
  * Automate registry writes via script instead of using RegEdit or 3rd Party programs
    * Don't need to use GUI every time on each device when working with multiple devices
  * Allow storing configuration details for ahk scripts and icon files in non-absolute paths

# Project setup
Find below the project setup and structure.
  * Clone the project to any location.
  * Open [settings.ini](/settings.ini)
    * Expand environment variables - 0 or 1. Determines what is stored in the "command" registry key. If you specify a program path %SYSTEMDRIVE%\Program Files\SomeProgram\SomeExecutable.exe with the flag on, it will be expanded to C:\Program Files\SomeProgram\SomeExecutable.exe where "C:" is the value of SYSTEMDRIVE.
  * [\resources](/resources) - stores context menu options as csv
    * [HKEY_CLASSES_ROOT_AllFileExt.csv](/resources/HKEY_CLASSES_ROOT_AllFileExt.csv)
      * Context menu when right clicking a file of any extension
    * [HKEY_CLASSES_ROOT_Directory.csv](/resources/HKEY_CLASSES_ROOT_Directory.csv)
      * Context menu when right clicking a folder
    * [HKEY_CLASSES_ROOT_DictoryBackground.csv](/resources/HKEY_CLASSES_ROOT_DirectoryBackground.csv)
      * Context menu when right clicking the empty space in a folder
    * [HKEY_CLASSES_ROOT_IconsOnly.csv](/resources/HKEY_CLASSES_ROOT_IconsOnly.csv)
      * Change icons for file extensions, system-wide.
      * Only takes affect after system restart or calling [SHChangeNotify](https://docs.microsoft.com/en-us/windows/win32/api/shlobj_core/nf-shlobj_core-shchangenotify). You can also open a file extension in [FileTypesMan](https://www.nirsoft.net/utils/file_types_manager.html) and click ok on the popup without changing anything, which calls this function.
      * Icon is affected by Default programs/User Choice. to avoid changing the icon for all associated file types see, [**Detach file extension from user choice**](#detach-file-extension-from-user-choice)
    * [HKEY_CLASSES_ROOT_NewFile.csv](/resources/HKEY_CLASSES_ROOT_NewFile.csv)
      * Context menu when clicking "New " Dialog when right clicking in the empty space of a folder
    * [\ico](/resources/ico)
      * [\ext](/resources/ico/ext)
        * stores .ico files for [WriteContextMenuIconsOnly.ahk](/WriteContextMenuIconsOnly.ahk), for changing icons for file types, system-wide
      * Location to store .ico files that can be used in our csv config without specifying an absolute path. Otherwise, we need to point to absolute file paths.
  * [\bin](/bin) - location for compiled ahk scripts and other executables. Can refer to a file name + extension in our csv config if programs are stored here, otherwise they must be referred to by an absolute path or one with environment variables

# Add context menu entry for a specific file type
  * Menu entry will appear at the top of the context menu, above any entries that are defined for all file extensions
  * Certain file extensions get associated with an application, often called user choice. The way it is set up in Windows 8+ makes it harder to edit the registry directly, as described [here](https://stackoverflow.com/a/27004486)
    
    > Microsoft decided in Windows 8 (probably for security reasons) that users should be able to set default programs only via the built in GUI. I.e. by design, you are not supposed to be able to set default handlers in a script or programmatically.

    > The Hash value is used to prove that the UserChoice ProgId value was set by the user, and not by any other means. This works as long as Microsoft keeps the algorithm which generates the Hash, and the mechanism for verifying the ProgId using the Hash, a secret.

    > In theory you could figure out the secret to set the Hash (and possibly other hidden OS settings), but you would have no guarantee of it's reliability; the next Windows Update might break your method, for example. You probably just need to adapt to the change, and live with using the new methods Microsoft built in to the OS.
    
The easy way around this is to use [FileTypesMan](https://www.nirsoft.net/utils/file_types_manager.html)

1) Navigate to the extension and click on it, so it is selected in the top view
2) Right Click the bottom menu -> New Action
3) Give a name, and command as "C:\Program Files\HandBrake\HandBrake.exe" "%1".
   * *"%1" specifies that the file/folder path selected in Windows Explorer will be passed to the application.*
   * Alternatively, select the program from the list of running programs.
4) Optionally select the path of an .ico or .exe to set the icon



https://user-images.githubusercontent.com/83767022/179375758-696d19da-63b6-4f68-b981-a286051a6a0d.mp4

### Multiple context menu entries of the same file extension
If you already have menu entries for the same extension, the one you add might not be at the top. The order is determined by the name of the registry keys. For FileTypesMan, this field is read only, but you can change it with RegEdit.
  * If your file extension is not associated with a User Choice, it will lead you to **Computer\HKEY_CLASSES_ROOT\.{extension}\shell** instead of **Computer\HKEY_CLASSES_ROOT\AppX6eg8h5sxqq90pv53845wmnbewywdqq5h\Shell\\** but the process is the same.

![image](https://user-images.githubusercontent.com/83767022/179375947-0563795f-4dc1-438d-987d-92ea8096267a.png)

1) Click on the key on the explorer view (left side of registry editor). For our demo it will be "Open with Handbrake"
   * Make sure the key that is selected is the name of the action, not "shell" or "command"
2) Double click the "Default" key in the right hand side. Set the value to what you want to be displayed on the context menu.
3) On the left side in the explorer view, right click on the key you want to be at the top, and prepend it with a number or special character so it comes first alphabetically.
   * Make sure the key that is selected is the name of the action, not "shell" or "command"

https://user-images.githubusercontent.com/83767022/179377027-da54d134-4f0d-46a3-9e05-1be1980efc96.mp4

Now the menu option will be on top.

![image](https://user-images.githubusercontent.com/83767022/179376935-009294c2-b642-48b7-9d51-2131814d2c97.png)

# Detach file extension from User Choice
To avoid changing the icon or adding context menu items for all file extensions associated with a User Choice, remove User Choice using [FileTypesMan](https://www.nirsoft.net/utils/file_types_manager.html). Optionally change the [FileType](https://docs.microsoft.com/en-us/windows/win32/shell/fa-file-types) if multiple extensions share the same file type.

1) Open the ext in FileTypesMan and click the ... for User Choice. Click *Detach File Type*.
   * You may get an error, but it should still work.

2) Open RegEdit and navigate to **Computer\HKEY_CLASSES_ROOT\\.{extension}**
3) For the default key, rename it to something else, commonly {extension}file or .{extension}_auto_file
4) Create a new key under **Computer\HKEY_CLASSES_ROOT** with the same name
5) Run [WriteContextMenu.ahk](/WriteContextMenu.ahk), or follow the steps for [**Add Context menu entry for a specific file type**](#add-context-menu-entry-for-a-specific-file-type) again.
   * The script will write context menu entries or icons to the new handler. Other file extensions that use the old handler will be unaffected.
   * Only takes effect after system restart or calling [SHChangeNotify](https://docs.microsoft.com/en-us/windows/win32/api/shlobj_core/nf-shlobj_core-shchangenotify). You can also open a file extension in [FileTypesMan](https://www.nirsoft.net/utils/file_types_manager.html) and click ok on the popup without changing anything, which calls this function.

https://user-images.githubusercontent.com/83767022/179415439-e0eefc9e-f894-4afc-93bf-2c65ba8f10ce.mp4

https://user-images.githubusercontent.com/83767022/179416028-a466f453-33f2-49cc-82c3-983db2746d74.mp4
