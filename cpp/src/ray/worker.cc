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

#include "ray/id.h"
#include "ray/io.h"
#include "ray/util/logging.h"
#include "ray/status.h"
#include "ray/worker.h"
#include "ray/proto/ray.pb.h"

namespace ray {

Status Worker::Connect(const std::string& address) {
  return ConnectUnixSocketRetry(address, -1, -1, &conn_);
}

Status Worker::GetNextTask(FunctionID* function_id, TaskID* task_id, std::vector<ObjectID>* args, std::vector<ObjectID>* return_ids) {
  int64_t type;
  std::string buffer;
  RETURN_NOT_OK(ReadMessage(conn_, &type, &buffer));
  RAY_CHECK(type == MessageType::GetTask);
  Task task;
  task.ParseFromString(buffer);
  *function_id = FunctionID::from_binary(task.function_id());
  *task_id = FunctionID::from_binary(task.task_id());
  for (auto arg_id : task.arg_ids()) {
    args->push_back(ObjectID::from_binary(arg_id));
  }
  for (auto return_id : task.return_ids()) {
    return_ids->push_back(ObjectID::from_binary(return_id));
  }
  return Status::OK();
}

}  // namespace ray

int main() {
  return 0;
}
