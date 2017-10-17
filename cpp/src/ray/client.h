// Licensed to the Apache Software Foundation (ASF) under one
// or more contributor license agreements.  See the NOTICE file
// distributed with this work for additional information
// regarding copyright ownership.  The ASF licenses this file
// to you under the Apache License, Version 2.0 (the
// "License"); you may not use this file except in compliance
// with the License.  You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

#include <vector>

#include "ray/status.h"
#include "ray/id.h"

namespace ray {

class Client {
 public:
  // Connect the client to a Unix domain socket with address "address"
  Status Connect(const std::string& address);
  // Connect the client to an already opened file descriptor
  Status Connect(int fd);
  Status Submit(const FunctionID& function_id, const std::vector<ObjectID>& args, TaskID* task_id, std::vector<ObjectID>* return_ids);
  Status GetNextTask(FunctionID* function_id, TaskID* task_id, std::vector<ObjectID>* args, std::vector<ObjectID>* return_ids);
 private:
  int conn_;
};

}  // namespace ray
