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

## Implementation of JAPL call frames. A call frame
## is a subset of the VM's stack that represents
## function-local space

import ../types/function
import ../types/baseObject
import ../types/arraylist
{.experimental: "implicitDeref".}


type
    CallFrame* = ref object
        function*: ptr Function
        ip*: int
        slot*: int
        stack*: ptr ArrayList[ptr Obj]


proc clear*(self: CallFrame): int =
    ## Returns how much to clear, and clears that many
    while self.stack.len() > self.slot:
        discard self.stack.pop()
        inc result

proc getView*(self: CallFrame): ptr ArrayList[ptr Obj] =
    result = self.stack[self.slot..self.stack.len()]


proc len*(self: CallFrame): int =
    result = len(self.getView())


proc `[]`*(self: CallFrame, idx: int): ptr Obj =
    result = self.stack[idx + self.slot]


proc `[]=`*(self: CallFrame, idx: int, val: ptr Obj) =
    self.stack[idx + self.slot] = val


proc delete*(self: CallFrame, idx: int) =
    self.stack.delete(idx + self.slot)
