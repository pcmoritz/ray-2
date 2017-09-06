cmake_minimum_required(VERSION 3.2)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake")

## Python and libraries
find_package(PythonLibsNew REQUIRED)
find_package(NumPy REQUIRED)
include(UseCython)

# This ensures that things like gnu++11 get passed correctly
set(CMAKE_CXX_STANDARD 11)

# We require a C++11 compliant compiler
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include_directories(SYSTEM
  ${NUMPY_INCLUDE_DIRS}
  ${PYTHON_INCLUDE_DIRS})

############################################################
# Dependencies
############################################################

find_package(Ray REQUIRED)
include_directories(SYSTEM ${RAY_INCLUDE_DIR})

set(CYTHON_EXTENSIONS
  lib
)

set(LINK_LIBS
  ray
)

foreach(module ${CYTHON_EXTENSIONS})
    string(REPLACE "." ";" directories ${module})
    list(GET directories -1 module_name)
    list(REMOVE_AT directories -1)

    string(REPLACE "." "/" module_root "${module}")
    set(module_SRC ray/${module_root}.pyx)
    set_source_files_properties(${module_SRC} PROPERTIES CYTHON_IS_CXX 1)

    cython_add_module(${module_name}
      ${module_name}_pyx
      ${module_name}_output
      ${module_SRC})

    if (directories)
        string(REPLACE ";" "/" module_output_directory ${directories})
        set_target_properties(${module_name} PROPERTIES
          LIBRARY_OUTPUT_DIRECTORY ${module_output_directory})
    endif()

    target_link_libraries(${module_name} ${LINK_LIBS})
endforeach(module)
