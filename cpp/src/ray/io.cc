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

#include "ray/io.h"

#include <sstream>

#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>

#include "ray/util/logging.h"

namespace ray {

// The version of the network protocol.
constexpr int64_t kRayProtocolVersion = 0;

// Number of times we try connecting to a socket.
constexpr int64_t kNumConnectAttempts = 50;
constexpr int64_t kConnectTimeoutMillisecs = 100;

constexpr int64_t kDisconnectClientType = 0;

Status ConnectUnixSocket(const std::string& pathname, int* fd) {
  struct sockaddr_un socket_address;

  *fd = socket(AF_UNIX, SOCK_STREAM, 0);
  if (*fd < 0) {
    RAY_LOG(ERROR) << "socket() failed for pathname " << pathname;
    return Status::IOError("");
  }

  memset(&socket_address, 0, sizeof(socket_address));
  socket_address.sun_family = AF_UNIX;
  if (pathname.size() + 1 > sizeof(socket_address.sun_path)) {
    RAY_LOG(ERROR) << "Socket pathname is too long.";
    return Status::IOError("");
  }
  strncpy(socket_address.sun_path, pathname.c_str(), pathname.size() + 1);

  if (connect(*fd, (struct sockaddr*)&socket_address, sizeof(socket_address)) != 0) {
    close(*fd);
    return Status::IOError("");
  }

  return Status::OK();
}

Status ConnectUnixSocketRetry(const std::string& pathname, int num_retries,
                              int64_t timeout, int* fd) {
  // Pick the default values if the user did not specify.
  num_retries = num_retries < 0 ? kNumConnectAttempts : num_retries;
  timeout = timeout < 0 ? kConnectTimeoutMillisecs : timeout;

  *fd = -1;
  for (int num_attempts = 0; num_attempts < num_retries; ++num_attempts) {
    Status s = ConnectUnixSocket(pathname, fd);
    if (s.ok()) {
      break;
    }
    if (num_attempts == 0) {
      RAY_LOG(ERROR) << "Connection to IPC socket failed for pathname " << pathname
                     << ", retrying " << num_retries << " times";
    }
    /* Sleep for timeout milliseconds. */
    usleep(static_cast<int>(timeout * 1000));
  }
  /* If we could not connect to the socket, exit. */
  if (*fd == -1) {
    std::stringstream ss;
    ss << "Could not connect to socket " << pathname;
    return Status::IOError(ss.str());
  }
  return Status::OK();
}

Status WriteBytes(int fd, uint8_t* cursor, size_t length) {
  ssize_t nbytes = 0;
  size_t bytesleft = length;
  size_t offset = 0;
  while (bytesleft > 0) {
    /* While we haven't written the whole message, write to the file descriptor,
     * advance the cursor, and decrease the amount left to write. */
    nbytes = write(fd, cursor + offset, bytesleft);
    if (nbytes < 0) {
      if (errno == EAGAIN || errno == EWOULDBLOCK || errno == EINTR) {
        continue;
      }
      return Status::IOError(std::string(strerror(errno)));
    } else if (nbytes == 0) {
      return Status::IOError("Encountered unexpected EOF");
    }
    RAY_CHECK(nbytes > 0);
    bytesleft -= nbytes;
    offset += nbytes;
  }

  return Status::OK();
}

Status WriteMessage(int fd, int64_t type, int64_t length, uint8_t* bytes) {
  int64_t version = kRayProtocolVersion;
  RETURN_NOT_OK(WriteBytes(fd, reinterpret_cast<uint8_t*>(&version), sizeof(version)));
  RETURN_NOT_OK(WriteBytes(fd, reinterpret_cast<uint8_t*>(&type), sizeof(type)));
  RETURN_NOT_OK(WriteBytes(fd, reinterpret_cast<uint8_t*>(&length), sizeof(length)));
  return WriteBytes(fd, bytes, length * sizeof(char));
}

Status ReadBytes(int fd, uint8_t* cursor, size_t length) {
  ssize_t nbytes = 0;
  /* Termination condition: EOF or read 'length' bytes total. */
  size_t bytesleft = length;
  size_t offset = 0;
  while (bytesleft > 0) {
    nbytes = read(fd, cursor + offset, bytesleft);
    if (nbytes < 0) {
      if (errno == EAGAIN || errno == EWOULDBLOCK || errno == EINTR) {
        continue;
      }
      return Status::IOError(std::string(strerror(errno)));
    } else if (0 == nbytes) {
      return Status::IOError("Encountered unexpected EOF");
    }
    RAY_CHECK(nbytes > 0);
    bytesleft -= nbytes;
    offset += nbytes;
  }

  return Status::OK();
}

Status ReadMessage(int fd, int64_t* type, std::string* buffer) {
  int64_t version;
  RETURN_NOT_OK_ELSE(ReadBytes(fd, reinterpret_cast<uint8_t*>(&version), sizeof(version)),
                     *type = kDisconnectClientType);
  RAY_CHECK(version == kRayProtocolVersion) << "version = " << version;
  size_t length;
  RETURN_NOT_OK_ELSE(ReadBytes(fd, reinterpret_cast<uint8_t*>(type), sizeof(*type)),
                     *type = kDisconnectClientType);
  RETURN_NOT_OK_ELSE(ReadBytes(fd, reinterpret_cast<uint8_t*>(&length), sizeof(length)),
                     *type = kDisconnectClientType);
  if (length > buffer->size()) {
    buffer->resize(length);
  }
  RETURN_NOT_OK_ELSE(ReadBytes(fd, reinterpret_cast<uint8_t*>(&buffer[0]), length), *type = kDisconnectClientType);
  return Status::OK();
}

}  // namespace ray
