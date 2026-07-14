#Requires AutoHotkey v2.0.18+
#SingleInstance Force
SetTitleMatchMode(3)
CoordMode("ToolTip","Screen")
SetWinDelay(-1)
http(verb,url) {
    h := ComObject("WinHttp.WinHttpRequest.5.1")
    h.Open(verb,url)
    h.Send()
    h.WaitForResponse()
    text := h.ResponseText
    return Jxon_Load(&text)
}
getServerList(placeID) {
    static lastPlaceID := "", lastServerList := [] 
    try {
        lastPlaceID := placeID
        lastServerList := http("GET", "https://games.roblox.com/v1/games/" placeID "/servers/0?limit=100")["data"]
        return lastServerList
    } catch {
        if(placeID = lastPlaceID && lastServerList.Length) {
            return lastServerList ;bad solution? returns a not up to date server list
        } else {
           MsgBox("You have probably been rate limited or you dont have access to roblox, maybe no internet?",,"T5")
        }
    }
}
msTime() {
    static f := _freq()
    x := 0
    DllCall("QueryPerformanceCounter","int64*",&x)
    return x//f
    _freq() {
        x := 0
        DllCall("QueryPerformanceFrequency","int64*",&x)
        return x//1000
    }
}
waitForFinish(PID,timeout:=5000) {
    time := msTime()
    if(PID!="") {
        while ProcessExist(PID)&&msTime()-time<timeout {
            Sleep 1
        }
    }
}
robloxes := ["Roblox Game Client","Roblox","RobloxPlayerBeta.exe","RobloxPlayerInstaller.exe","RobloxPlayerInstaller.exe (32 bit)","Roblox (32 bit)","RobloxPlayerInstaller.exe (64 bit)","Roblox (64 bit)"]
close() {
    try {
        WinClose("Pick an app")
    }
    RobloxWindows := WinGetList("Roblox")
    loop RobloxWindows.Length {
        PID := WinGetPID(RobloxWindows[A_Index])
        if(ProcessGetName(PID)=="RobloxPlayerBeta.exe") { ;only supports single instance roblox
            ProcessClose(PID)
            waitForFinish(PID)
        }
    }
    closed := false
    while(!closed&&A_Index<20) {
        closed := true
        loop robloxes.Length {
            try {
                if(ProcessExist(robloxes[A_Index])) {
                    closed := false
                }
                ProcessClose(robloxes[A_Index])
            }
        }
    }
}
ToolTip("PRESS ALT E TO ACTIVATE MACRO BOT`nPRESS ALT X TO CLOSE MACRO",A_ScreenWidth,A_ScreenHeight)
*!e:: {
    serverHopEvery := Number(InputBox("serverhop every what second?",,,2).Value)*1000
    if(WinExist("Roblox")) {
        WinHide("Roblox")
    }
    toCloneMyselfIn := getServerList("391104146")
    timeSinceAPI := A_Now
    ToolTip("MACRO BOT IS ACTIVE`nPRESS ALT R TO STOP`nPRESS ALT X TO CLOSE MACRO",A_ScreenWidth,A_ScreenHeight)
    while true {
        if(DateDiff(A_Now,timeSinceAPI,"Seconds")>60) {
            toCloneMyselfIn := getServerList("391104146")
            timeSinceAPI := A_Now
        }
        loop toCloneMyselfIn.Length {
            rand := Ceil(Random()*toCloneMyselfIn.Length)
            if(!rand) {
                rand := 1
            }
            temp := toCloneMyselfIn[A_Index]
            toCloneMyselfIn[A_Index] := toCloneMyselfIn[rand]
            toCloneMyselfIn[rand] := temp
        }
		if(!Mod(A_Index,4)) {
			close()
            Run "roblox://experiences/start?placeId=1"
            time := msTime()
            redo:
			try {
                WinHide("Roblox")
            } catch {
                if(msTime()-time<10000) {
                    goto redo
                }
            }
		}
        loop toCloneMyselfIn.Length {
            job := toCloneMyselfIn[A_Index]["id"]
            if(WinExist("Roblox")) {
                WinHide("Roblox")
            }
			try {
            	Run "roblox://experiences/start?placeId=391104146&gameInstanceId=" job
                WinClose("Pick an app")
			}
            Sleep serverHopEvery
        }
    }
}
*!r::{
    try {
        WinShow("Roblox")
    }
    Reload()
    ExitApp()
}
*!x::{
    try {
        WinShow("Roblox")
    }
    ExitApp()
}
;CREDITS GO TO https://github.com/TheArkive/JXON_ahk2
Jxon_Load(&src, args*) {
	key := "", is_key := false
	stack := [ tree := [] ]
	next := '"{[01234567890-tfn'
	pos := 0
	
	while ( (ch := SubStr(src, ++pos, 1)) != "" ) {
		if InStr(" `t`n`r", ch)
			continue
		if !InStr(next, ch, true) {
			testArr := StrSplit(SubStr(src, 1, pos), "`n")
			
			ln := testArr.Length
			col := pos - InStr(src, "`n",, -(StrLen(src)-pos+1))

			msg := Format("{}: line {} col {} (char {})"
			,   (next == "")      ? ["Extra data", ch := SubStr(src, pos)][1]
			  : (next == "'")     ? "Unterminated string starting at"
			  : (next == "\")     ? "Invalid \escape"
			  : (next == ":")     ? "Expecting ':' delimiter"
			  : (next == '"')     ? "Expecting object key enclosed in double quotes"
			  : (next == '"}')    ? "Expecting object key enclosed in double quotes or object closing '}'"
			  : (next == ",}")    ? "Expecting ',' delimiter or object closing '}'"
			  : (next == ",]")    ? "Expecting ',' delimiter or array closing ']'"
			  : [ "Expecting JSON value(string, number, [true, false, null], object or array)"
			    , ch := SubStr(src, pos, (SubStr(src, pos)~="[\]\},\s]|$")-1) ][1]
			, ln, col, pos)

			throw Error(msg, -1, ch)
		}
		
		obj := stack[1]
        is_array := (obj is Array)
		
		if i := InStr("{[", ch) { ; start new object / map?
			val := (i = 1) ? Map() : Array()	; ahk v2
			
			is_array ? obj.Push(val) : obj[key] := val
			stack.InsertAt(1,val)
			
			next := '"' ((is_key := (ch == "{")) ? "}" : "{[]0123456789-tfn")
		} else if InStr("}]", ch) {
			stack.RemoveAt(1)
            next := (stack[1]==tree) ? "" : (stack[1] is Array) ? ",]" : ",}"
		} else if InStr(",:", ch) {
			is_key := (!is_array && ch == ",")
			next := is_key ? '"' : '"{[0123456789-tfn'
		} else { ; string | number | true | false | null
			if (ch == '"') { ; string
				i := pos
				while i := InStr(src, '"',, i+1) {
					val := StrReplace(SubStr(src, pos+1, i-pos-1), "\\", "\u005C")
					if (SubStr(val, -1) != "\")
						break
				}
				if !i ? (pos--, next := "'") : 0
					continue

				pos := i ; update pos

				val := StrReplace(val, "\/", "/")
				val := StrReplace(val, '\"', '"')
				, val := StrReplace(val, "\b", "`b")
				, val := StrReplace(val, "\f", "`f")
				, val := StrReplace(val, "\n", "`n")
				, val := StrReplace(val, "\r", "`r")
				, val := StrReplace(val, "\t", "`t")

				i := 0
				while i := InStr(val, "\",, i+1) {
					if (SubStr(val, i+1, 1) != "u") ? (pos -= StrLen(SubStr(val, i)), next := "\") : 0
						continue 2

					xxxx := Abs("0x" . SubStr(val, i+2, 4)) ; \uXXXX - JSON unicode escape sequence
					if (xxxx < 0x100)
						val := SubStr(val, 1, i-1) . Chr(xxxx) . SubStr(val, i+6)
				}
				
				if is_key {
					key := val, next := ":"
					continue
				}
			} else { ; number | true | false | null
				val := SubStr(src, pos, i := RegExMatch(src, "[\]\},\s]|$",, pos)-pos)
				
                if IsInteger(val)
                    val += 0
                else if IsFloat(val)
                    val += 0
                else if (val == "true" || val == "false")
                    val := (val == "true")
                else if (val == "null")
                    val := ""
                else if is_key {
                    pos--, next := "#"
                    continue
                }
				
				pos += i-1
			}
			
			is_array ? obj.Push(val) : obj[key] := val
			next := obj == tree ? "" : is_array ? ",]" : ",}"
		}
	}
	
	return tree[1]
}
