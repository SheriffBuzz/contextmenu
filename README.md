# Contextmenu
Manage context menus by automating registry writes using ahk. Additional visual guides for FileTypesMan.

## Resources
[How to open Registry Editor](https://support.microsoft.com/en-us/windows/how-to-open-registry-editor-in-windows-10-deab38e6-91d6-e0aa-4b7c-8878d9e07b11)

[FileTypesMan](https://www.nirsoft.net/utils/file_types_manager.html) *Scroll to the bottom of the page for the download*

## Best Practices when working with the Registry
 * [Backup your Windows Registry](https://support.microsoft.com/en-us/topic/how-to-back-up-and-restore-the-registry-in-windows-855140ad-e318-2a13-2829-d428a2ab0692)

 * If you download registry (.reg) scripts from the internet, open then in a text editor and inspect the keys they are modifying, before running them. This script modifies registry keys that have the following patterns:
   * **Computer\HKEY_CLASSES_ROOT\*\shell** - Context menu when right clicking a file of any extension
   * **Computer\HKEY_CLASSES_ROOT\\.{fileExtension}\shell** - Context menu when right clicking a file of a specific extension
   * **Computer\HKEY_CLASSES_ROOT\Directory\shell** - Context menu when right clicking a folder
   * **Computer\HKEY_CLASSES_ROOT\Directory\Background\shell** - Context menu when right clicking the empty space in a folder
## Goals
  * Automate registry writes via script instead of using RegEdit or 3rd Party programs
    * Don't need to use GUI every time on each device when working with multiple devices
  * Allow storing configuration details for ahk scripts and icon files in non-absolute paths
  
# Add context menu entry for a specific file type
  * Menu entry will appear at the top of the context menu, above any entries that are defined for all file extensions
  * Certain file extensions get associated with an application, often called user choice. The way it is set up in Windows 8+ makes it harder to edit the registry directly, as described [here](https://stackoverflow.com/a/27004486)
    
    > Microsoft decided in Windows 8 (probably for security reasons) that users should be able to set default programs only via the built in GUI. I.e. by design, you are not supposed to be able to set default handlers in a script or programmatically.

    > The Hash value is used to prove that the UserChoice ProgId value was set by the user, and not by any other means. This works as long as Microsoft keeps the algorithm which generates the Hash, and the mechanism for verifying the ProgId using the Hash, a secret.

    > In theory you could figure out the secret to set the Hash (and possibly other hidden OS settings), but you would have no guarantee of it's reliability; the next Windows Update might break your method, for example. You probably just need to adapt to the change, and live with using the new methods Microsoft built in to the OS.
    
The easy way around this is to use [FileTypesMan](https://www.nirsoft.net/utils/file_types_manager.html)

1) Navigate to the extension
2) Right Click the bottom menu -> New Action
3) Give a name, and command as "C:\Program Files\HandBrake\HandBrake.exe" "%1".
   * *"%1" refers to the file/folder path that will be passed to the application.*
   * Alternatively, select the program from the list of running programs.
4) Optionally select the path of an .ico or .exe to set the icon



https://user-images.githubusercontent.com/83767022/179375758-696d19da-63b6-4f68-b981-a286051a6a0d.mp4

### Multiple context menu entries of the same file extension
If you already have menu entries for the same extension, the one you add might not be at the top. The order is determined by the name of the registry keys. For FileTypesMan, this field is read only, but you can change it with RegEdit.
  * If your file extension is not associated with a User Choice, it will lead you to **Computer\HKEY_CLASSES_ROOT\.{extension}\shell** instead of **Computer\HKEY_CLASSES_ROOT\AppX6eg8h5sxqq90pv53845wmnbewywdqq5h\Shell\\** but the process is the same.

![image](https://user-images.githubusercontent.com/83767022/179375947-0563795f-4dc1-438d-987d-92ea8096267a.png)

1) Click on the key on the explorer view (left side of registry editor). For our demo it will be "Open with Handbrake"
2) Double click the "Default" key in the right hand side. Set the value to what you want to be displayed on the context menu.
3) Right click on the key you want to be at the top, and prepend it with a number or special character so it comes first alphabetically.

https://user-images.githubusercontent.com/83767022/179377027-da54d134-4f0d-46a3-9e05-1be1980efc96.mp4

Now the menu option will be on top.

![image](https://user-images.githubusercontent.com/83767022/179376935-009294c2-b642-48b7-9d51-2131814d2c97.png)


  
