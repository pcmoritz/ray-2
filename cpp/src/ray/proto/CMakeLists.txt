include (ExternalProject)

set(PROTOBUF_INCLUDE_DIRS "${CMAKE_CURRENT_BINARY_DIR}/protobuf/src/protobuf/src" CACHE string "protobuf include dir")
set(PROTOBUF_URL "https://github.com/google/protobuf/archive/v3.4.0.tar.gz")

set(PROTOBUF_STATIC_LIBRARIES ${CMAKE_CURRENT_BINARY_DIR}/protobuf/src/protobuf/libprotobuf.a CACHE string "protobuf library")
set(PROTOBUF_PROTOC_EXECUTABLE ${CMAKE_CURRENT_BINARY_DIR}/protobuf/src/protobuf/protoc)

ExternalProject_Add(protobuf
    PREFIX protobuf
    URL ${PROTOBUF_URL}
    BUILD_IN_SOURCE 1
    DOWNLOAD_DIR ${CMAKE_CURRENT_BINARY_DIR}
    CONFIGURE_COMMAND ${CMAKE_COMMAND} cmake/
        -Dprotobuf_BUILD_TESTS=OFF
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON
        ${PROTOBUF_ADDITIONAL_CMAKE_OPTIONS}
    INSTALL_COMMAND ""
    CMAKE_CACHE_ARGS
        -DCMAKE_BUILD_TYPE:STRING=Release
        -DCMAKE_VERBOSE_MAKEFILE:BOOL=OFF
        -DCMAKE_POSITION_INDEPENDENT_CODE:BOOL=ON)

include_directories(SYSTEM ${PROTOBUF_INCLUDE_DIRS})

set(PROTO_HEADER "${CMAKE_CURRENT_SOURCE_DIR}/ray.pb.cc")
set(PROTO_SRC "${CMAKE_CURRENT_SOURCE_DIR}/ray.pb.h")

add_custom_command(
  OUTPUT ${PROTO_HEADER}
         ${PROTO_SRC}
  COMMAND ${PROTOBUF_PROTOC_EXECUTABLE}
  ARGS "--cpp_out=${DLL_EXPORT_DECL}${CMAKE_CURRENT_SOURCE_DIR}" --proto_path ${CMAKE_CURRENT_SOURCE_DIR} "${CMAKE_CURRENT_SOURCE_DIR}/ray.proto"
  DEPENDS protobuf
  COMMENT "Running C++ protocol buffer compiler on ${CMAKE_CURRENT_SOURCE_DIR}/ray.proto"
  VERBATIM)

add_library(proto ${PROTO_HEADER} ${PROTO_SRC} protobuf)
