/*
	LoggerClass
	@param workingDirectory

	Remarks - varsetcapacity isnt yet implemented nor is flushing the buffer when it gets too big.

	TODO rotating log
*/
class LoggerClass {
	__New(workingDirectory, fileName="serverlog.txt") {
		this.workingDirectory:= workingDirectory
		this.loggingDirectory:= this.workingDirectory "\log"
		this.buffer:= ""
		this.logLevel:= "2"
		this.fileName:= fileName
		this.filePath:= this.loggingDirectory "\" this.fileName
		this.objectPrintDepth:= 15
		this.DEBUG_LEVEL:= 3
		this.INFO_LEVEL:= 2
		this.WARN_LEVEL:= 1
		this.OFF_LEVEL:= 0
		this.shouldPrintObjects:= true
		OnExit(ObjBindMethod(this, "flushBuffer"))
		if (FileExist(this.filePath)) {
			FileDelete, % this.filePath
		}
		VarSetCapacity(this.buffer, 1024000)
	}

	flushBuffer() {
		if (this.buffer) {
			this.LogToFile(this.buffer)
		}
	}

	LogToBuffer(text) {
		this.buffer.= text "`n"
	}

	LogToFile(text) {
		if (this.loggingDirectory) {
			FileAppend, % text . "`n", % this.filePath
		}
	}

	isDebugEnabled() {
		return (this.loglevel >= this.DEBUG_LEVEL)
	}

	/*
		LOG

		Remarks - currently debug level is only for msgbox warnings, everything gets logged.
	*/
	LOG(level, msg, params*) {
		if (this.logLevel >= level && level > 0) {
			if (level <= this.WARN_LEVEL) {
				Msgbox, % msg
			}
			for i, obj in params {
				if (IsObject(obj) && this.shouldPrintObjects) {
					if (this.logLevel > this.INFO_LEVEL) {
						try {
							obj:= this.dump(obj, obj.__class)
						}
					} else {
						obj:= "[Object - Enable DebugLogging for json]"
					}
				}
				msg:= StrReplace(msg, "{" i "}", obj)
			}
			this.logToBuffer(msg)
		}
	}

	WARN(msg, params*) {
		this.LOG(this.WARN_LEVEL, msg, params*)
	}
	INFO(msg, params*) {
		this.LOG(this.INFO_LEVEL, msg, params*)
	}
	DEBUG(msg, params*) {
		this.LOG(this.DEBUG_LEVEL, msg, params*)
	}

	setLogLevel(var="") {
		if var is number
			this.logLevel:= var
		if (var = "Debug") {
			this.logLevel:= this.DEBUG_LEVEL
		}else if (var = "Info") {
			this.logLevel:= this.INFO_LEVEL
		}else if (var = "Warn") {
			this.logLevel:= this.WARN_LEVEL
		} else {
			this.logLevel:= this.OFF_LEVEL
		}
	}

	;;https://github.com/cocobelgica/AutoHotkey-JSON/blob/master/Jxon.ahk
	;modified slightly so it doesnt blow the stack with cyclical references, removed json escaping
	dump(obj, clazz, indent:="", lvl:=1) {
		static q := Chr(34)
		static ptrCache:= []

		if (lvl = 1) {
			ptrCache:= []
		}
		if IsObject(obj)
		{
			if (ptrCache[&obj] = 1 && clazz) {
				return "[Object backlink]"
			}
			ptrCache[&obj]:= 1
			static Type := Func("Type")
			if Type ? (Type.Call(obj) != "Object") : (ObjGetCapacity(obj) == "")
				throw Exception("Object type not supported.", -1, Format("<Object at 0x{:p}>", &obj))

			is_array := 0
			for k in obj
				is_array := k == A_Index
			until !is_array

			static integer := "integer"
			if indent is %integer%
			{
				if (indent < 0)
					throw Exception("Indent parameter must be a postive integer.", -1, indent)
				spaces := indent, indent := ""
				Loop % spaces
					indent .= " "
			}
			indt := ""
			Loop, % indent ? lvl : 0
				indt .= indent

			lvl += 1, out := "" ; Make #Warn happy
			for k, v in obj
			{
				if IsObject(k) || (k == "")
					throw Exception("Invalid object key.", -1, k ? Format("<Object at 0x{:p}>", &obj) : "<blank>")
				
				if !is_array
					out .= (q . k . q ) ;// key
						.  ( indent ? ": " : ":" ) ; token + padding
				
				if (v.__class && clazz.__class && v.__class = clazz) {
					out .= "[BackReference to " clazz "]" .  ( indent ? ",`n" . indt : "," ) ; token + indent
				} else if (lvl > this.objectPrintDepth) {
					out .= "[max print depth " this.objectPrintDepth "]" .  ( indent ? ",`n" . indt : "," ) ; token + indent
				} else {
					out .= this.dump(v, v.__class, indent, lvl) .  ( indent ? ",`n" . indt : "," ) ; token + indent
				}
					
			}

			if (out != "")
			{
				out := Trim(out, ",`n" . indent)
				if (indent != "")
					out := "`n" . indt . out . "`n" . SubStr(indt, StrLen(indent)+1)
			}
			
			return is_array ? "[" . out . "]" : "{" . out . "}"
		}

		; Number
		else if (ObjGetCapacity([obj], 1) == "")
			return obj

		; String (null -> not supported by AHK)
		if (obj != "")
		{
			/*
			obj := StrReplace(obj,  "\",    "\\")
			, obj := StrReplace(obj,  "/",    "\/")
			, obj := StrReplace(obj,    q, "\" . q)
			, obj := StrReplace(obj, "`b",    "\b")
			, obj := StrReplace(obj, "`f",    "\f")
			, obj := StrReplace(obj, "`n",    "\n")
			, obj := StrReplace(obj, "`r",    "\r")
			, obj := StrReplace(obj, "`t",    "\t")
			*/
			

			static needle := (A_AhkVersion<"2" ? "O)" : "") . "[^\x20-\x7e]"
			while RegExMatch(obj, needle, m)
				obj := StrReplace(obj, m[0], Format("\u{:04X}", Ord(m[0])))
		}	
		return (obj = "true" || obj = "false" || obj = "null") ? obj : q . obj . q
	}
}
