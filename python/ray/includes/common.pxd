# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

# distutils: language = c++

from libcpp cimport bool as c_bool, nullptr
from libcpp.memory cimport shared_ptr, unique_ptr, make_shared
from libcpp.string cimport string as c_string
from libcpp.vector cimport vector

cdef extern from "ray/api.h" namespace "ray" nogil:
    cdef CStatus CStatus_OK "Status::OK"()
    cdef CStatus CStatus_Invalid "Status::Invalid"()

    cdef cppclass CStatus "ray::Status":
        CStatus()

        c_string ToString()
        c_string message()

        c_bool ok()
        c_bool IsIOError()
        c_bool IsOutOfMemory()
        c_bool IsInvalid()
        c_bool IsKeyError()
        c_bool IsNotImplemented()
        c_bool IsTypeError()
