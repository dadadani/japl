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


# Just Another Test Runner for running JAPL tests
# a testrunner process

import ../src/vm


var btvm = initVM()
    
try:
    var source: string
    while true:
        let ch = stdin.readChar()
        if ch == char(4):
            break
        else:
            source &= ch
    discard btvm.interpret(source, "")
    quit(0)
except:
    let error = getCurrentException()
    writeLine stderr, error.msg
    writeLine stderr, error.getStacktrace()
    quit(1)
       
