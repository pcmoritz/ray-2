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

import cloudpickle

cdef class GCSClient:

    def __cinit__(self):
        self.client.reset(new CGCSClient())

    def register_function(self, JobID job_id, FunctionID function_id, function, invoker):
        cdef c_string function_name = "{}.{}".format(function.__module__, function.__name__).encode("ascii")
        cdef c_string pickled_function
        # Work around limitations of Python pickling
        function_globals = function.__globals__.get(function.__name__)
        function.__globals__[function.__name__] = invoker
        try:
            pickled_function = cloudpickle.dumps(function)
        finally:
            # Undo our changes
            if function_globals:
                function.__globals__[function.__name__] = function_globals
            else:
                del function.__globals__[function.__name__]
        with nogil:
            check_status(self.client.get().RegisterFunction(job_id.data, function_id.data, function_name, pickled_function))

    def retrieve_function(self, JobID job_id, FunctionID function_id):
        cdef c_string name
        cdef c_string data
        with nogil:
            check_status(self.client.get().RetrieveFunction(job_id.data, function_id.data, address(name), address(data)))
        def function():
            raise Exception("This function was not imported properly")
        try:
            function = cloudpickle.loads(data)
        except:
            # TODO(pcm): Implement error handling here
            pass
        return name, function

def connect_gcs(addr, int port):
    cdef c_string ip_addr = addr.encode("ascii")
    cdef GCSClient result = GCSClient()
    with nogil:
        check_status(result.client.get().Connect(ip_addr, port))
    return result
