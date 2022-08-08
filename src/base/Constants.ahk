FOLDER_PATH_RESOURCES:= WORKING_DIRECTORY "\resources\"
global FILE_PATH_ALL_FILE_EXT:= FOLDER_PATH_RESOURCES "HKEY_CLASSES_ROOT_AllFileExt.csv"
global FILE_PATH_DIRECTORY:= FOLDER_PATH_RESOURCES "HKEY_CLASSES_ROOT_Directory.csv"
global FILE_PATH_DIRECTORY_BACKGROUND:= FOLDER_PATH_RESOURCES "HKEY_CLASSES_ROOT_DirectoryBackground.csv"

global FILE_PATH_NEW_FILE:= FOLDER_PATH_RESOURCES "HKEY_CLASSES_ROOT_NewFile.csv"
global FILE_PATH_ICONS_ONLY:= FOLDER_PATH_RESOURCES "HKEY_CLASSES_ROOT_IconsOnly.csv"
global FILE_PATH_DEFAULT_PROGRAMS:= FOLDER_PATH_RESOURCES "DefaultPrograms.csv"


global REGISTRY_KEY_FILE:= "HKCR\*\shell"
global REGISTRY_KEY_DIRECTORY:="HKCR\Directory\shell"
global REGISTRY_KEY_DIRECTORY_BACKGROUND:="HKCR\Directory\Background\shell"

global FILETYPE_SUFFIX:= "file" ;suffix for file extension. ie. if ext is ".csv", fileType is "csvfile". Used when creating new extensions, or unlinking file ext's from default programs to a new default program

global EXPAND_ENVIRONMENT_VARIABLES:= (ReadIniCfg(WORKING_DIRECTORY "\settings.ini", "settings", "ExpandEnvironmentVariables")) ? true : false
global WRITE_TYPE_ALL:= "All"
