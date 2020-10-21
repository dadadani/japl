# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at

#  http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

## Base structure for objects in JAPL, all
## types inherit from this simple structure


type
    ObjectType* {.pure.} = enum
        ## The type of the object
        ## (Also see meta/valueobject/ValueType)
        String, Exception, Function,
        Class, Module
    Obj* = object of RootObj
        kind*: ObjectType
        hashValue*: uint32


func objType*(obj: ptr Obj): ObjectType =
    ## Returns the type of the object
    return obj.kind


proc stringify*(obj: ptr Obj): string =
    ## Returns a string representation
    ## of the object
    result = "<object (built-in type)>"


proc typeName*(obj: ptr Obj): string =
    ## This method should return the
    ## name of the object type
    result = "object"


proc isFalsey*(obj: ptr Obj): bool =
    ## Returns wheter the object should
    ## be considered a falsey value
    ## or not. Returns true if the
    ## object IS falsey
    result = false


proc valuesEqual*(a: ptr Obj, b: ptr Obj): bool =
    ## Base method to compare 2 objects.
    ## Should never be used in normal
    ## circumstances, as it is not reliable.
    ## This is only a last option if an object
    ## hasn't this method defined
    result = a.kind == b.kind


proc hash*(self: ptr Obj): uint32 =
    # TODO: Make this actually useful
    result = 2166136261u32


proc add(self, other: ptr Obj): ptr Obj =
    ## Returns the result of self + other
    ## or nil if the operation is unsupported
    result = nil  # Not defined for base objects!


proc sub(self, other: ptr Obj): ptr Obj =
    ## Returns the result of self - other
    ## or nil if the operation is unsupported
    result = nil


proc mul(self, other: ptr Obj): ptr Obj =
    ## Returns the result of self * other
    ## or nil if the operation is unsupported
    result = nil


proc trueDiv(self, other: ptr Obj): ptr Obj =
    ## Returns the result of self / other
    ## or nil if the operation is unsupported
    result = nil


proc exp(self, other: ptr Obj): ptr Obj =
    ## Returns the result of self ** other
    ## or nil if the operation is unsupported
    result = nil


proc binaryAnd(self, other: ptr Obj): ptr Obj =
    ## Returns the result of self & other
    ## or nil if the operation is unsupported
    result = nil


proc binaryOr(self, other: ptr Obj): ptr Obj =
    ## Returns the result of self | other
    ## or nil if the operation is unsupported
    result = nil


proc binaryNot(self: ptr Obj): ptr Obj =
    ## Returns the result of ~self
    ## or nil if the operation is unsupported
    result = nil


proc binaryXor(self, other: ptr Obj): ptr Obj =
    ## Returns the result of self ^ other
    ## or nil if the operation is unsupported
    result = nil