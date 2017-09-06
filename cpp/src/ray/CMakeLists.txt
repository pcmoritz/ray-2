
CMAKE_MINIMUM_REQUIRED (VERSION 2.6)
SET(CMAKE_CXX_FLAGS "-g -Wall -Werror -std=c++11")

ADD_SUBDIRECTORY(proto)
ADD_SUBDIRECTORY(util)

INCLUDE_DIRECTORIES(${PROTOBUF_INCLUDE_DIRS})

set(RAY_SRCS
  client.cc
  id.cc
  io.cc
  status.cc
  worker.cc
)

install(FILES
  api.h
  client.h
  id.h
  status.h
  worker.h
  DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/ray")

# pkg-config support
configure_file(ray.pc.in
  "${CMAKE_CURRENT_BINARY_DIR}/ray.pc"
  @ONLY)
install(
  FILES "${CMAKE_CURRENT_BINARY_DIR}/ray.pc"
  DESTINATION "${CMAKE_INSTALL_LIBDIR}/pkgconfig/")

ADD_RAY_LIB(ray
    SOURCES ${RAY_SRCS}
    SHARED_LINK_LIBS ${PROTOBUF_STATIC_LIBRARIES} proto
    STATIC_LINK_LIBS ${PROTOBUF_STATIC_LIBRARIES} proto)
