#Include %A_LineFile%\..\Logger.ahk
/*
    PSRLogger

    Performance, Scalability, Reliabilty logger. Benchmark function calls
*/
class PSRLoggerClass {

    __New() {
        this.nodeTree:= {}
        this.currentNode:= new PSRNode({startTime: A_TickCount, thisFunc: "PSRROOT", level: 0})
        this.maxLevel:= 10
        this.logger:= new LoggerClass("C:\toolkit\registry\contextmenu", "PSR.log")
        this.logger.loglevel:= 3
        this.logger.shouldPrintObjects:= false ;stopgap to prevent unhandled infinite recursion (tree structure)
    }

    push(ByRef psrNode) {
        psrNode.startTime:= A_TickCount
        psrNode.level:= (IsObject(this.currentNode)) ? this.currentNode.level + 1 : 1
        if (psrNode.level > this.maxLevel) {
            Msgbox, % "Max psr depth: " this.maxLevel
            return
        }
        ;check max nodes
        
        this.currentNode.childNodes.push(psrNode)
        psrNode.parentNode:= this.currentNode
        this.currentNode:= psrNode
    }

    pop() {
        if (this.currentNode) {
            this.currentNode.endTime:= A_TickCount
            nodeValue:= this.currentNode.name " " this.getTimeInSeconds(this.currentNode.startTime, this.currentNode.endTime)


            this.currentNode:= this.currentNode.parentNode
        }
        return nodeValue
    }

    enter(name, thisFunc="") {
        if (!this.logger.isDebugEnabled()) {
            return
        }
        ;this.logger.debug(name ((thisFunc) ? ("~" thisFunc) : "") " - start")
        /*
        if (!thisFunc) {
            thisFunc:= A_ThisFunc
        }
        */
        this.push(new PSRNode({name: name, thisFunc: thisFunc}))
    }

    exit(name, thisFunc="") {
        if (!this.logger.isDebugEnabled()) {
            return
        }
        while (this.currentNode.name != (name . thisFunc) && this.currentNode.level >= 1) {
            nodeValue:= this.pop()
            this.logger.debug(nodeValue)
        }
        nodeValue:= this.pop()
        this.logger.debug(nodeValue)
    }

    getTimeInSeconds(start, end) {
        if (!start || !end) {
            return
        }
        ms:= end - start
        sec:= floor(mod((ms / 1000), 60))
        msMod:= floor((mod((ms / 1000), 60) - sec) * 1000)
        return sec "." ((msMod < 100) ? "0" msMod : msMod) "s"
    }

    getTimeInMillis(start, end) {
        if (!start || !end) {
            return
        }
        ms:= end - start
        return ms "ms"
    }

    /*
        record time between start and stop, and save it to temp object used to construct log message
    */
    record(ByRef message) {
        this.records.Push([message, this.getTimeInSeconds()])
    }

    stopAndRecord(ByRef message) {
        this.stop()
        this.records.Push([message, this.getTimeInSeconds()])
    }

    stopAndRecordMillis(ByRef message) {
        this.stop()
        this.records.Push([message, this.getTimeInMillis()])
    } 

    getLogMessage() {
        msg:= ""
        for i, record in this.records {
            msg.= record[1] ": " record[2] "`n"
        }
        return msg
    }

}

class PSRNode {
    __New(cfg) {
        this.parentNode:= cfg.parentNode
        this.childNodes:= []
        this.startTime:= cfg.startTime
        this.endTime:=
        this.thisFunc:= cfg.thisFunc
        this.name:= cfg.name this.thisFunc
        this.level:= (cfg.level) ? cfg.level : 0
    }
}

global PSRLogger:= new PSRLoggerClass() ;@Export PSRLogger
