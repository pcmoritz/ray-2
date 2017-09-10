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

import sys

cdef class Worker:

    def __cinit__(self):
        self.worker.reset(new CWorker())

    def get_next_task(self):
        cdef FunctionID function_id = FunctionID()
        cdef TaskID task_id = TaskID()
        cdef vector[CObjectID] object_ids
        cdef vector[CObjectID] return_ids
        with nogil:
            check_status(self.worker.get().GetNextTask(address(function_id.data), address(task_id.data), address(object_ids), address(return_ids)))
        return function_id, task_id, object_id_list(object_ids), object_id_list(return_ids)


def register_worker(c_string socket_name):
    cdef Worker result = Worker()
    with nogil:
        check_status(result.worker.get().Connect(socket_name))
    return result

def start_worker(socket):
    worker = register_worker(socket.encode("ascii"))
    while True:
        function_id, task_id, arg_ids, return_ids = worker.get_next_task()
        print("executing task ", task_id)
