# Copyright 2020 Mattia Giambirtone
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Just Another Test Suite for running JAPL tests

import nim/nimtests
import testobject
import logutils
import testconfig
import testbuilder
import testrun
import testeval
import localization

import os
import strformat
import parseopt
import strutils
import terminal
import re

type 
    Action {.pure.} = enum
        Run, Help, Version
    DebugAction {.pure.} = enum
        Interactive, Stdout
    QuitValue {.pure.} = enum
        Success, Failure, ArgParseErr, InternalErr, Interrupt

when isMainModule:
    var optparser = initOptParser(commandLineParams())
    var action: Action = Action.Run
    var debugActions: seq[DebugAction]
    var targetFiles: seq[string]
    var verbose = true
    var crash = false

    var quitVal = QuitValue.Success
    proc evalKey(key: string) =
        let key = key.toLower()
        if key == "h" or key == "help":
            action = Action.Help
        elif key == "v" or key == "version":
            action = Action.Version
        elif key == "i" or key == "interactive":
            debugActions.add(DebugAction.Interactive)
        elif key == "s" or key == "silent":
            verbose = false
        elif key == "crash":
            crash = true
        elif key == "stdout":
            debugActions.add(DebugAction.Stdout)
        else:
            echo &"Unknown flag: {key}"
            action = Action.Help
            quitVal = QuitValue.ArgParseErr


    proc evalKeyVal(key: string, val: string) =
        let key = key.toLower()
        if key == "o" or key == "output":
            targetFiles.add(val)
        elif key == "j" or key == "jobs":
            if val.match(re"^[0-9]*$"):
                maxAliveTests = parseInt(val)
            else:
                echo "Can't parse non-integer option passed to -j/--jobs."
                action = Action.Help
                quitVal = QuitValue.ArgParseErr
        else:
            echo &"Unknown option: {key}"
            action = Action.Help
            quitVal = QuitValue.ArgParseErr


    proc evalArg(key: string) =
        echo &"Unexpected argument"
        action = Action.Help
        quitVal = QuitValue.ArgParseErr

    while true:
        optparser.next()
        case optparser.kind:
            of cmdEnd: break
            of cmdShortOption, cmdLongOption:
                if optparser.val == "":
                    evalKey(optparser.key)
                else:
                    evalKeyVal(optparser.key, optparser.val)
            of cmdArgument:
                evalArg(optparser.key)


    proc printUsage =
        echo """
JATS - Just Another Test Suite

Usage:
jats 
Runs the tests
Flags:
-i (or --interactive) displays all debug info
-o:<filename> (or --output:<filename>) saves debug info to a file
-s (or --silent) will disable all output (except --stdout)
--stdout will put all debug info to stdout
-j:<parallel test count> (or --jobs:<parallel test count>) to specify number of tests to run parallel
-h (or --help) displays this help message
-v (or --version) displays the version number of JATS
"""

    proc printVersion =
        echo &"JATS - Just Another Test Suite version {jatsVersion}"

    if action == Action.Help:
        printUsage()
        quit int(quitVal)
    elif action == Action.Version:
        printVersion()
        quit int(quitVal)
    elif action == Action.Run:
        discard
    else:
        echo &"Unknown action {action}, please contact the devs to fix this."
        quit int(QuitValue.InternalErr)
    setVerbosity(verbose)
    setLogfiles(targetFiles)
    # start of JATS
    try:
        if crash: 
            raise newException(CatchableError, "Crash.")
        log(LogLevel.Debug, &"Welcome to JATS")
        runNimTests()
        var jatr = "jatr"
        var testDir = "japl"
        if not fileExists(jatr) and fileExists("tests" / jatr):
            log(LogLevel.Debug, &"Must be in root: prepending \"tests\" to paths")
            jatr = "tests" / jatr
            testDir = "tests" / testDir
        log(LogLevel.Info, &"Running JAPL tests.")
        log(LogLevel.Info, &"Building tests...")
        let tests: seq[Test] = buildTests(testDir)
        log(LogLevel.Debug, &"Tests built.")
        proc ctrlc() {.noconv.} =
            showCursor()
            tests.killTests()
            echo "Interrupted by ^C."
            quit(int(QuitValue.Interrupt))
        setControlCHook(ctrlc)
        log(LogLevel.Info, &"Running tests...")
        tests.runTests(jatr)
        log(LogLevel.Debug, &"Tests ran.")
        log(LogLevel.Debug, &"Evaluating tests...")
        tests.evalTests()
        log(LogLevel.Debug, &"Tests evaluated.")
        if not tests.printResults():
            quitVal = QuitValue.Failure
        log(LogLevel.Debug, &"Quitting JATS.")
        # special options to view the entire debug log
    except:
        errorDisplay()  
        writeLine stderr, getCurrentExceptionMsg()
        writeStacktrace()
        
    finally:
        let logs = getTotalLog()
        for action in debugActions:
            case action:
                of DebugAction.Interactive:
                    let lessExe = findExe("less", extensions = @[""])
                    let moreExe = findExe("more", extensions = @[""])
                    var viewer = if lessExe == "": moreExe else: lessExe
                    if viewer != "":
                        writeFile("testresults.txt", logs) # yes, testresults.txt is reserved
                        discard execShellCmd(viewer & " testresults.txt") # this way because of pipe buffer sizes
                        removeFile("testresults.txt")
                    else:
                        write stderr, "Interactive mode not supported on your platform, try --stdout and piping, or install/alias 'more' or 'less' to a terminal pager.\n"
                of DebugAction.Stdout:
                    echo logs
    quit int(quitVal)

