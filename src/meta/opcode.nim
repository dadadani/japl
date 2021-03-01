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

## Implementation for bytecode chunks and the VM's opcodes
## A chunk is a piece of bytecode together with its constants

import ../types/baseObject
import ../types/arraylist

type
    Chunk* = object
        ## A piece of bytecode.
        ## Consts represents the constants table the code is referring to
        ## Code is the compiled bytecode
        ## Lines maps bytecode instructions to line numbers (1 to 1 correspondence)
        consts*: ptr ArrayList[ptr Obj]
        code*: ptr ArrayList[uint8]
        lines*: ptr ArrayList[int]   # TODO: Run-length encoding
    OpCode* {.pure.} = enum
        ## Enum of possible opcodes
        Constant = 0u8,
        Return,
        Negate,
        Add,
        Subtract,
        Divide,
        Multiply,
        Pow,
        Mod,
        Nil,
        True,
        False,
        Greater,
        Less,
        Equal,
        GreaterOrEqual,
        LessOrEqual,
        Not,
        GetItem,
        Slice,
        Pop,
        DefineGlobal,
        GetGlobal,
        SetGlobal,
        DeleteGlobal,
        SetLocal,
        GetLocal,
        DeleteLocal,
        JumpIfFalse,
        Jump,
        Loop,
        Break,
        Shr,
        Shl,
        Nan,
        Inf,
        Xor,
        Call,
        Bor,
        Band,
        Bnot,
        Is,
        As



const simpleInstructions* = {OpCode.Return, OpCode.Add, OpCode.Multiply,
                             OpCode.Divide, OpCode.Subtract,
                             OpCode.Mod, OpCode.Pow, OpCode.Nil,
                             OpCode.True, OpCode.False, OpCode.Nan,
                             OpCode.Inf, OpCode.Shl, OpCode.Shr,
                             OpCode.Xor, OpCode.Not, OpCode.Equal,
                             OpCode.Greater, OpCode.Less, OpCode.GetItem,
                             OpCode.Slice, OpCode.Pop, OpCode.Negate,
                             OpCode.Is, OpCode.As, OpCode.GreaterOrEqual,
                             OpCode.LessOrEqual, OpCode.Bor, OpCode.Band,
                             OpCode.Bnot}
const constantInstructions* = {OpCode.Constant, OpCode.DefineGlobal,
                               OpCode.GetGlobal, OpCode.SetGlobal,
                               OpCode.DeleteGlobal}
const byteInstructions* = {OpCode.SetLocal, OpCode.GetLocal, OpCode.DeleteLocal,
                           OpCode.Call}
const jumpInstructions* = {OpCode.JumpIfFalse, OpCode.Jump, OpCode.Loop}


proc newChunk*(): Chunk =
    ## Initializes a new, empty chunk
    result = Chunk(consts: newArrayList[ptr Obj](), code: newArrayList[uint8](), lines: newArrayList[int]())


proc writeChunk*(self: Chunk, newByte: uint8, line: int) =
    ## Appends newByte at line to a chunk.
    self.code.append(newByte)
    self.lines.append(line)


proc writeChunk*(self: Chunk, bytes: array[3, uint8], line: int) =
    ## Appends bytes (an array of 3 bytes) to a chunk
    for cByte in bytes:
        self.writeChunk(cByte, line)


proc addConstant*(self: Chunk, constant: ptr Obj): array[3, uint8] =
    ## Writes a constant to a chunk. Returns its index casted to an array
    self.consts.append(constant)
    let index = self.consts.high()
    result = cast[array[3, uint8]](index)
