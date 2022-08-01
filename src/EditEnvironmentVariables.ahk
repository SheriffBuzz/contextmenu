/*
    EditEnvironmentVariables.ahk
    
    Wrapper for dll call. It shows the Environment variables without showing the system properties popup. This is convenient because you dont have to exit out of 2 windows when done.

    Using the run command directly is preferred for context menu, as ahk does not add any functionality. This script is reserved for future use.
*/

EditEnvironmentVariables()

EditEnvironmentVariables() {
    command:= "rundll32 sysdm.cpl,EditEnvironmentVariables"
    Run, %command%
}