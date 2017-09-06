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

from ray.includes.common cimport *

cdef extern from "ray/api.h" namespace "ray" nogil:

    cdef cppclass CUniqueID" ray::UniqueID":

        @staticmethod
        CUniqueID nil()

        @staticmethod
        CUniqueID from_binary(const c_string& binary)

        @staticmethod
        CUniqueID from_random()

        c_bool operator==(const CUniqueID& rhs) const

        c_string hex() const

        c_string binary() const

    ctypedef CUniqueID CObjectID" ray::ObjectID"
    ctypedef CUniqueID CFunctionID" ray::FunctionID"
    ctypedef CUniqueID CTaskID" ray::TaskID"

    cdef cppclass CWorker" ray::Worker":

        CStatus Connect(const c_string& address)

        CStatus GetNextTask(CFunctionID* function_id, CTaskID* task_id, vector[CObjectID]* args, vector[CObjectID]* return_ids)

    cdef cppclass CClient" ray::Client":

        CStatus Connect(const c_string& address)

        CStatus Submit(const CFunctionID& function_id, const vector[CObjectID]& args, CTaskID* task_id, vector[CObjectID]* return_ids)
