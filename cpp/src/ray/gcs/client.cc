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

#include "ray/gcs/client.h"

#include <unistd.h>

#include <map>
#include <sstream>
#include <vector>

#include "hiredis/hiredis.h"
#include "ray/proto/ray.pb.h"

namespace ray {

namespace gcs {

class DBConn {
 public:
  DBConn(redisContext* context) : context_(context) {}
  ~DBConn() { redisFree(context_); }
  redisContext* get() { return context_; }
 private:
  redisContext* context_;
};

constexpr int64_t kRedisConnectionAttempts = 50;
constexpr int64_t kConnectTimeoutMillisecs = 100;

#define REDIS_CHECK_ERROR(CONTEXT, REPLY) \
    if (REPLY == nullptr || REPLY->type == REDIS_REPLY_ERROR) { \
      return Status::RedisError(CONTEXT->errstr); \
    }

/*
Status RedisHmset(redisContext* context, const std::string& key, const std::map<std::string,std::string>& data) {
  std::vector<const char *> argv;
  std::vector<size_t> argvlen;

  static char cmd[] = "HMSET";
  argv.push_back(cmd);
  argvlen.push_back(sizeof(cmd) - 1);

  argv.push_back(key.c_str());
  argvlen.push_back(key.size());

  for (const auto& elem : data) {
    argv.push_back(elem.first.c_str());
    argvlen.push_back(elem.first.size());
    argv.push_back(elem.second.c_str());
    argvlen.push_back(elem.second.size());
  }

  void *r = redisCommandArgv(context, argv.size(), &(argv[0]), &(argvlen[0]));
  if (r == nullptr) {
    return Status::RedisError(context->errstr);
  }
  freeReplyObject(r);
  return Status::OK();
}
*/

Status RedisSetCommand(redisContext* context, const std::string& key, const std::string& value) {
  redisReply *reply = reinterpret_cast<redisReply*>(
    redisCommand(context, "SET %b %b", &key[0], key.size(), &value[0], value.size()));
  REDIS_CHECK_ERROR(context, reply);
  if (strcmp(reply->str, "OK") != 0) {
    return Status::RedisError(reply->str);
  }
  freeReplyObject(reply);
  return Status::OK();
}

Status RedisGetCommand(redisContext* context, const std::string& key, std::string* value) {
  redisReply *reply = reinterpret_cast<redisReply*>(
    redisCommand(context, "GET %b", &key[0], key.size()));
  REDIS_CHECK_ERROR(context, reply);
  value->assign(reply->str, reply->len);
  freeReplyObject(reply);
  return Status::OK();
}

Status RedisRPushCommand(redisContext* context, const std::string& key, const std::string& value) {
  redisReply *reply = reinterpret_cast<redisReply*>(
    redisCommand(context, "RPUSH %b %b", &key[0], key.size(), &value[0], value.size()));
  REDIS_CHECK_ERROR(context, reply);
  freeReplyObject(reply);
  return Status::OK();
}

Client::Client() = default;
Client::~Client() = default;

Status Client::Connect(const std::string& address, int port) {
  int connection_attempts = 0;
  redisContext *context = redisConnect(address.c_str(), port);
  while (context == nullptr || context->err) {
    if (connection_attempts >= kRedisConnectionAttempts) {
      if (context == nullptr) {
        RAY_LOG(FATAL) << "Could not allocate redis context.";
      }
      if (context->err) {
        RAY_LOG(FATAL) << "Could not establish connection to redis " << address << ":" << port;
      }
      break;
    }
    RAY_LOG(WARNING) << "Failed to connect to Redis, retrying.";
    // Sleep for a little.
    usleep(kConnectTimeoutMillisecs * 1000);
    context = redisConnect(address.c_str(), port);
    connection_attempts += 1;
  }
  redisReply *reply = reinterpret_cast<redisReply*>(
    redisCommand(context, "CONFIG SET notify-keyspace-events Kl"));
  REDIS_CHECK_ERROR(context, reply);
  conn_.reset(new DBConn(context));
  return Status::OK();
}

Status Client::RegisterFunction(const JobID& job_id, const FunctionID& function_id, const std::string& name, const std::string& data) {
  redisContext *context = conn_->get();
  std::ostringstream ss;
  ss << "RemoteFunction:" << job_id.binary() << ":" << function_id.binary();
  std::string key = ss.str();
  FunctionDefinition definition;
  definition.set_job_id(job_id.binary());
  definition.set_function_id(function_id.binary());
  definition.set_name(name);
  definition.set_data(data);
  std::string value;
  definition.SerializeToString(&value);
  RETURN_NOT_OK(RedisSetCommand(context, key, value));
  RETURN_NOT_OK(RedisRPushCommand(context, "Exports", key));
  return Status::OK();
}

Status Client::RetrieveFunction(const JobID& job_id, const FunctionID& function_id, std::string* name, std::string* data) {
  redisContext *context = conn_->get();
  std::ostringstream ss;
  ss << "RemoteFunction:" << job_id.binary() << ":" << function_id.binary();
  std::string key = ss.str();
  std::string value;
  RETURN_NOT_OK(RedisGetCommand(context, key, &value));
  FunctionDefinition definition;
  definition.ParseFromString(value);
  *name = definition.name();
  *data = definition.data();
  return Status::OK();
}

Status Client::NotifyError(const JobID& job_id, const std::map<std::string, std::string>& error_info) {
  return Status::NotImplemented("error notification not implemented");
}

}  // namespace gcs

}  // namespace ray
