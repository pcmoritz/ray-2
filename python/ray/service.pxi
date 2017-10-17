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

import os
import sys

cdef class Service:
    def main_loop(self):
        while True:
            function_id, task_id, arg_ids, return_ids = self.client.get_next_task()
            print("executing task ", task_id)

    @property
    def job_id(self):
        return self.job_id

    @property
    def client(self):
        return self.client

cdef class Driver(Service):

    @property
    def gcs_client(self):
        return self.gcs_client

cdef class Worker(Service):
    pass

def start_worker(socket):
    cdef Service service = Service()
    service.client = Service.connect_to_fd(3)
    return service

def start_driver(socket, addr, port):
    cdef Driver driver = Driver()
    driver.client = Client.connect_to_socket(socket.encode("ascii"))
    print("connecting with addr {} and port {}".format(addr, port))
    driver.gcs_client = connect_gcs(addr, port)
    driver.job_id = JobID.from_random()
    return driver
