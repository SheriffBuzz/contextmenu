#Include %A_LineFile%\..\Util.ahk
#NoEnv
/*
    CopyGitHubMarkdownLink

    This script constructs the link markdown for a file that will be used as an asset in a readme, elsewhere in a git repo. If the file is an image (png, jpg, jpeg), then the image will be inlined using ![]() otherwise it will use []()

    Purpose: 
        - Create link markdown quickly for locally hosted files - ![urltext](/pathto/assets/asset.png). It is intended to be called from a context menu where the file path is passed to the script.
        - Host assets within git repo instead of github user content, so assets from private repos are not accessable from the public web (if you were to guess/crawl the uuid/url path)
    

    This script accepts the following A_Args:
    1 - FileName
    2 - LinkTextIncludesExt - should link text include file name extension

    Output:
    Images (png, jpg, jpeg)
        ![FileName](/some/rel/link)
    Everything else
        [FileName](/some/rel/link)

    Remarks
        - The file passed to the script should belong to a git repo.
            - We dont check gitignore, so it is possible the link might not work if you try linking a file that is gitignored. Only check the containing directory or any of its parent directories contains a .git folder
        - The file that includes the asset might not be at the root of a git repo. In this case, the path /pathto/assets/asset.png still refers to the root of the git repo (..\ to the root is also ok). This allows us to statically set asset paths relative to the git repo, instead of the target file to the asset file.
        - Above assertion holds true for markdown viewing in GitHub, and Markdown All In One VSCode plugin (but only when you have the git repo open as folder, not a blank workspace with a single file from that repo open). Markdown files outside git repo's trying to use relative links may be supported by a markdown viewer, but is not guaranteed.
        - spaces in links must be encoded to %20
*/

Clipboard:= CopyGitHubMarkdownLink(A_Args[1], [A_Args[2]])

CopyGitHubMarkdownLink(fileName, linkTextIncludesExt=false) {
    link:= ""
    fileName:= ExpandEnvironmentVariables(fileName)
    showInline:= false ;show linked resource in line, (images)
    if (!FileExist(fileName)) {
        TrayTip, CopyGitHubMarkdownLink, % "Invalid path"
        return
    }

    splitExt:= StrSplit(fileName, ".")
    ext:= splitExt[splitExt.MaxIndex()]
    exts:= {"png": 1, "jpg": 1, "jpeg": 1}
    if (exts[ext] = 1) {
        showInline:= true
    }

    SplitPath, fileName, OutFileName, OutDir, OutExtension, OutNameNoExt
    gitFolderName:= ".git"
    linkText:= (linkTextIncludesExt) ? OutFileName : OutNameNoExt
    assetPath:= "/" OutFileName

    filePath:= StrReplace(outDir, "/", "\")
    gitFolderFound:= false
    while (InStr(outDir, "\")) {
        gitTestPath:= outDir "\" gitFolderName
        if (FileExist(gitTestPath)) {
            gitFolderFound:= true
            break
        }

        dirSplit:= StrSplit(outDir, "\")
        lastSegment:= dirSplit[dirSplit.MaxIndex()]
        assetPath:= "/" lastSegment assetPath
        outDir:= StrGetBeforeLastIndexOf(outDir, "\") ;process parent dir
    }
    if (!gitFolderFound) {
        TrayTip, CopyGitHubMarkdownLink, "Directory structure does not contain a git repo"
        return
    }
    assetPath:= StrReplace(assetPath, " ", "%20")

    link.= (showInline) ? "!" : ""
    link.= "[" linkText "]"
    link.= "(" assetPath ")"
    return link
}