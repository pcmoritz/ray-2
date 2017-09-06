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

include(FindPkgConfig)

pkg_check_modules(RAY ray)

if (RAY_FOUND)
  pkg_get_variable(RAY_ABI_VERSION ray abi_version)
  message(STATUS "Ray ABI version: ${RAY_ABI_VERSION}")
  pkg_get_variable(RAY_SO_VERSION ray so_version)
  message(STATUS "Ray SO version: ${RAY_SO_VERSION}")
  set(RAY_INCLUDE_DIR ${RAY_INCLUDE_DIRS})
  set(RAY_LIBS ${RAY_LIBRARY_DIRS})
  set(RAY_SEARCH_LIB_PATH ${RAY_LIBRARY_DIRS})
	message(STATUS "Ray RAY_INCLUDE_DIR: ${RAY_INCLUDE_DIRS}")
endif()
