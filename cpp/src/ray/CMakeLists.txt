
cmake_minimum_required(VERSION 3.2)
set(CMAKE_CXX_FLAGS "-g -Wall -Werror -std=c++11")

include_directories(${PROTOBUF_INCLUDE_DIRS})
include_directories(../../thirdparty/)

add_definitions(-DASIO_STANDALONE)

add_subdirectory(proto)
add_subdirectory(util)
add_subdirectory(gcs)

set(HIREDIS_SRCS
  ../../thirdparty/hiredis/async.c
  ../../thirdparty/hiredis/dict.c
  ../../thirdparty/hiredis/hiredis.c
  ../../thirdparty/hiredis/net.c
  ../../thirdparty/hiredis/read.c
  ../../thirdparty/hiredis/sds.c
)

set(RAY_SRCS
  client.cc
  id.cc
  io.cc
  status.cc
  gcs/client.cc
  gcs/asio.cc
)

install(FILES
  api.h
  client.h
  id.h
  status.h
  DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/ray")

# pkg-config support
configure_file(ray.pc.in
  "${CMAKE_CURRENT_BINARY_DIR}/ray.pc"
  @ONLY)
install(
  FILES "${CMAKE_CURRENT_BINARY_DIR}/ray.pc"
  DESTINATION "${CMAKE_INSTALL_LIBDIR}/pkgconfig/")

ADD_RAY_LIB(ray
    SOURCES ${RAY_SRCS} ${HIREDIS_SRCS}
    SHARED_LINK_LIBS ${PROTOBUF_STATIC_LIBRARIES} proto
    STATIC_LINK_LIBS ${PROTOBUF_STATIC_LIBRARIES} proto
    DEPENDENCIES proto)
