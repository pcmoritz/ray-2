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

from cython.operator import address

cdef class Client:

    def __cinit__(self):
        self.client.reset(new CClient())

    def submit(self, FunctionID function_id, list args):
        cdef vector[CObjectID] object_ids
        cdef ObjectID object_id
        for arg in args:
            if isinstance(arg, ObjectID):
                object_id = arg
                object_ids.push_back(object_id.data)
        cdef CUniqueID task_id
        cdef vector[CObjectID] return_ids
        with nogil:
            check_status(self.client.get().Submit(function_id.data, object_ids, address(task_id), address(return_ids)))
        return object_id_list(return_ids)

def connect(c_string socket_name):
    cdef Client result = Client()
    with nogil:
        check_status(result.client.get().Connect(socket_name))
    return result
