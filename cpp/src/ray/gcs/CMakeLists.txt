install(FILES
  client.h
  DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/ray/gcs")

ADD_RAY_TEST(asio_test STATIC_LINK_LIBS ray_static ${PLASMA_STATIC_LIB} ${ARROW_STATIC_LIB} gtest gtest_main pthread ${BOOST_SYSTEM_LIBRARY})
