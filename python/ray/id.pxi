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

def make_unique_id(unique_id):
    return UniqueID(unique_id)

cdef class UniqueID:
    """
    A UniqueID is a string of bytes.
    """

    cdef:
        CUniqueID data

    def __cinit__(self):
        self.data = CUniqueID.nil()

    def __cinit__(self, unique_id):
        self.data = CUniqueID.from_binary(unique_id)

    def __richcmp__(UniqueID self, UniqueID unique_id, operation):
        if operation != 2:
            raise ValueError("operation != 2 (only equality is supported)")
        return self.data == unique_id.data

    def __hash__(self):
        return hash(self.data.binary())

    def __repr__(self):
        return "ObjectID(" + self.data.hex().decode() + ")"

    def __reduce__(self):
        return (make_unique_id, (self.data.binary(),))

    def binary(self):
        """
        Return the binary representation of this ObjectID.
        Returns
        -------
        bytes
            Binary representation of the ObjectID.
        """
        return self.data.binary()

    @staticmethod
    def from_random():
        cdef CUniqueID data = CUniqueID.from_random()
        return UniqueID(data.binary())

cdef class ObjectID(UniqueID):

    @staticmethod
    def from_random():
        cdef CUniqueID data = CUniqueID.from_random()
        return ObjectID(data.binary())

cdef class FunctionID(UniqueID):

    @staticmethod
    def from_random():
        cdef CUniqueID data = CUniqueID.from_random()
        return FunctionID(data.binary())

cdef class TaskID(UniqueID):

    @staticmethod
    def from_random():
        cdef CUniqueID data = CUniqueID.from_random()
        return TaskID(data.binary())

cdef class JobID(UniqueID):

    @staticmethod
    def from_random():
        cdef CUniqueID data = CUniqueID.from_random()
        return JobID(data.binary())
