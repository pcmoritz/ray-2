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

set(GFLAGS_VERSION "2.2.0")
set(GTEST_VERSION "1.8.0")

# Boost

set(BOOST_PREFIX "${CMAKE_CURRENT_BINARY_DIR}/boost_ep-prefix/src/boost_ep")
set(BOOST_LIB_DIR "${BOOST_PREFIX}/stage/lib")
set(BOOST_STATIC_SYSTEM_LIBRARY
    "${BOOST_LIB_DIR}/${CMAKE_STATIC_LIBRARY_PREFIX}boost_system${CMAKE_STATIC_LIBRARY_SUFFIX}")
set(BOOST_SYSTEM_LIBRARY "${BOOST_STATIC_SYSTEM_LIBRARY}")
set(BOOST_BUILD_LINK "static")
set(BOOST_CONFIGURE_COMMAND
      "./bootstrap.sh"
      "--prefix=${BOOST_PREFIX}"
      "--with-libraries=filesystem,system")
if ("${CMAKE_BUILD_TYPE}" STREQUAL "DEBUG")
  set(BOOST_BUILD_VARIANT "debug")
else()
  set(BOOST_BUILD_VARIANT "release")
endif()
set(BOOST_BUILD_COMMAND
  "./b2"
  "link=${BOOST_BUILD_LINK}"
  "variant=${BOOST_BUILD_VARIANT}"
  "cxxflags=-fPIC")

set(Boost_ADDITIONAL_VERSIONS
  "1.66.0" "1.66"
  "1.65.0" "1.65"
  "1.64.0" "1.64"
  "1.63.0" "1.63"
  "1.62.0" "1.61"
  "1.61.0" "1.62"
  "1.60.0" "1.60")
list(GET Boost_ADDITIONAL_VERSIONS 0 BOOST_LATEST_VERSION)
string(REPLACE "." "_" BOOST_LATEST_VERSION_IN_PATH ${BOOST_LATEST_VERSION})
set(BOOST_LATEST_URL
  "https://dl.bintray.com/boostorg/release/${BOOST_LATEST_VERSION}/source/boost_${BOOST_LATEST_VERSION_IN_PATH}.tar.gz")

ExternalProject_Add(boost_ep
    URL ${BOOST_LATEST_URL}
    BUILD_IN_SOURCE 1
    CONFIGURE_COMMAND ${BOOST_CONFIGURE_COMMAND}
    BUILD_COMMAND ${BOOST_BUILD_COMMAND}
    INSTALL_COMMAND ""
    ${EP_LOG_OPTIONS})
set(Boost_INCLUDE_DIR "${BOOST_PREFIX}")
set(Boost_INCLUDE_DIRS "${BOOST_INCLUDE_DIR}")
add_dependencies(ray_dependencies boost_ep)

# Google Test

if(RAY_BUILD_TESTS OR RAY_BUILD_BENCHMARKS)
  add_custom_target(unittest ctest -L unittest)

  if(APPLE)
    set(GTEST_CMAKE_CXX_FLAGS "-fPIC -DGTEST_USE_OWN_TR1_TUPLE=1 -Wno-unused-value -Wno-ignored-attributes")
  elseif(NOT MSVC)
    set(GTEST_CMAKE_CXX_FLAGS "-fPIC")
  endif()
  string(TOUPPER ${CMAKE_BUILD_TYPE} UPPERCASE_BUILD_TYPE)
  set(GTEST_CMAKE_CXX_FLAGS "${EP_CXX_FLAGS} ${CMAKE_CXX_FLAGS_${UPPERCASE_BUILD_TYPE}} ${GTEST_CMAKE_CXX_FLAGS}")

  set(GTEST_PREFIX "${CMAKE_CURRENT_BINARY_DIR}/googletest_ep-prefix/src/googletest_ep")
  set(GTEST_INCLUDE_DIR "${GTEST_PREFIX}/include")
  set(GTEST_STATIC_LIB
    "${GTEST_PREFIX}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}gtest${CMAKE_STATIC_LIBRARY_SUFFIX}")
  set(GTEST_MAIN_STATIC_LIB
    "${GTEST_PREFIX}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}gtest_main${CMAKE_STATIC_LIBRARY_SUFFIX}")
  set(GTEST_CMAKE_ARGS -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
                       -DCMAKE_INSTALL_PREFIX=${GTEST_PREFIX}
                       -DCMAKE_CXX_FLAGS=${GTEST_CMAKE_CXX_FLAGS})
  if (MSVC AND NOT ARROW_USE_STATIC_CRT)
    set(GTEST_CMAKE_ARGS ${GTEST_CMAKE_ARGS} -Dgtest_force_shared_crt=ON)
  endif()

  ExternalProject_Add(googletest_ep
    URL "https://github.com/google/googletest/archive/release-${GTEST_VERSION}.tar.gz"
    BUILD_BYPRODUCTS ${GTEST_STATIC_LIB} ${GTEST_MAIN_STATIC_LIB}
    CMAKE_ARGS ${GTEST_CMAKE_ARGS}
    ${EP_LOG_OPTIONS})

  message(STATUS "GTest include dir: ${GTEST_INCLUDE_DIR}")
  message(STATUS "GTest static library: ${GTEST_STATIC_LIB}")
  include_directories(SYSTEM ${GTEST_INCLUDE_DIR})
  ADD_THIRDPARTY_LIB(gtest
    STATIC_LIB ${GTEST_STATIC_LIB})
  ADD_THIRDPARTY_LIB(gtest_main
    STATIC_LIB ${GTEST_MAIN_STATIC_LIB})

  add_dependencies(gtest googletest_ep)
  add_dependencies(gtest_main googletest_ep)

  set(GFLAGS_CMAKE_CXX_FLAGS ${EP_CXX_FLAGS})

  set(GFLAGS_URL "https://github.com/gflags/gflags/archive/v${GFLAGS_VERSION}.tar.gz")
  set(GFLAGS_PREFIX "${CMAKE_CURRENT_BINARY_DIR}/gflags_ep-prefix/src/gflags_ep")
  set(GFLAGS_HOME "${GFLAGS_PREFIX}")
  set(GFLAGS_INCLUDE_DIR "${GFLAGS_PREFIX}/include")
  if(MSVC)
    set(GFLAGS_STATIC_LIB "${GFLAGS_PREFIX}/lib/gflags_static.lib")
  else()
    set(GFLAGS_STATIC_LIB "${GFLAGS_PREFIX}/lib/libgflags.a")
  endif()
  set(GFLAGS_CMAKE_ARGS -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
                        -DCMAKE_INSTALL_PREFIX=${GFLAGS_PREFIX}
                        -DBUILD_SHARED_LIBS=OFF
                        -DBUILD_STATIC_LIBS=ON
                        -DBUILD_PACKAGING=OFF
                        -DBUILD_TESTING=OFF
                        -BUILD_CONFIG_TESTS=OFF
                        -DINSTALL_HEADERS=ON
                        -DCMAKE_CXX_FLAGS_${UPPERCASE_BUILD_TYPE}=${EP_CXX_FLAGS}
                        -DCMAKE_C_FLAGS_${UPPERCASE_BUILD_TYPE}=${EP_C_FLAGS}
                        -DCMAKE_CXX_FLAGS=${GFLAGS_CMAKE_CXX_FLAGS})

  ExternalProject_Add(gflags_ep
    URL ${GFLAGS_URL}
    ${EP_LOG_OPTIONS}
    BUILD_IN_SOURCE 1
    BUILD_BYPRODUCTS "${GFLAGS_STATIC_LIB}"
    CMAKE_ARGS ${GFLAGS_CMAKE_ARGS})

  message(STATUS "GFlags include dir: ${GFLAGS_INCLUDE_DIR}")
  message(STATUS "GFlags static library: ${GFLAGS_STATIC_LIB}")
  include_directories(SYSTEM ${GFLAGS_INCLUDE_DIR})
  ADD_THIRDPARTY_LIB(gflags
    STATIC_LIB ${GFLAGS_STATIC_LIB})

  add_dependencies(gflags gflags_ep)
endif()
