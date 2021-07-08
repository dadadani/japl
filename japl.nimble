# Package

version       = "0.0.1"
author        = "nocturn9x"
description   = "An interpreted, dynamically-typed, garbage-collected, and minimalistic programming language with C- and Java-like syntax"
license       = "Apache-2.0"
srcDir        = "src"
bin           = @["japl"]


# Dependencies
 
requires "nim >= 1.2.0"
requires "https://github.com/japl-lang/jale#master"

# Config generator

import parsecfg, parseutils, strutils, streams

const FULL_CONFIG = """# Copyright 2020 Mattia Giambirtone
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

## THIS FILE IS AUTOMATICALLY GENERATED, SEE "japl.nimble" ON THE ROOT DIRECTORY

import strformat

const MAP_LOAD_FACTOR* = {map_load_factor}  # Load factor for builtin hashmaps
const ARRAY_GROW_FACTOR* = {array_grow_factor}   # How much extra memory to allocate for dynamic arrays when resizing
const FRAMES_MAX* = {frames_max}  # The maximum recursion limit
const JAPL_VERSION* = "0.3.0"
const JAPL_RELEASE* = "alpha"
const DEBUG_TRACE_VM* = {debug_vm} # Traces VM execution
const SKIP_STDLIB_INIT* = {skip_stdlib_init} # Skips stdlib initialization in debug mode
const DEBUG_TRACE_GC* = {debug_gc}    # Traces the garbage collector (TODO)
const DEBUG_TRACE_ALLOCATION* = {debug_alloc}   # Traces memory allocation/deallocation
const DEBUG_TRACE_COMPILER* = {debug_compiler}  # Traces the compiler
const JAPL_VERSION_STRING* = &"JAPL {JAPL_VERSION} ({JAPL_RELEASE}, {CompileDate} {CompileTime})"
const HELP_MESSAGE* = \"\"\"The JAPL runtime interface, Copyright (C) 2020 Mattia Giambirtone

This program is free software, see the license distributed with this program or check
http://www.apache.org/licenses/LICENSE-2.0 for more info.

Basic usage
-----------

$ jpl  -> Starts the REPL

$ jpl filename.jpl -> Runs filename.jpl


Command-line options
--------------------

-h, --help  -> Shows this help text and exit
-v, --version -> Prints the JAPL version number and exit
-s, --string -> Executes the passed string as if it was a file
-i, --interactive -> Enables interactive mode, which opens a REPL session after execution of a file or source string
\"\"\" """
var configStream = newStringStream(staticRead("build.cfg"))
var config = loadConfig(configStream)
var debug_vm = if config.getSectionValue("japl","debug_vm") == "True": true else: false
var skip_stdlib_init = if config.getSectionValue("japl","skip_stdlib_init") == "True": true else: false
var debug_gc = if config.getSectionValue("japl","debug_gc") == "True": true else: false
var debug_compiler = if config.getSectionValue("japl","debug_compiler") == "True": true else: false
var debug_alloc = if config.getSectionValue("japl","debug_alloc") == "True": true else: false


var map_load_factor: float64
discard parseBiggestFloat(config.getSectionValue("japl","map_load_factor"), map_load_factor)

var array_grow_factor: int64
discard parseBiggestInt(config.getSectionValue("japl","array_grow_factor"), array_grow_factor)

var frames_max: int64
discard parseBiggestInt(config.getSectionValue("japl","frames_max"), frames_max)


writeFile("src/config.nim", FULL_CONFIG.replace("{map_load_factor}", $map_load_factor).replace("{array_grow_factor}", $array_grow_factor).replace("{frames_max}", $frames_max).replace("{debug_vm}", $debug_vm).replace("{skip_stdlib_init}", $skip_stdlib_init).replace("{debug_gc}", $debug_gc).replace("{debug_alloc}", $debug_alloc).replace("{debug_compiler}", $debug_compiler).replace("""\"\"\"""", "\"\"\""))
