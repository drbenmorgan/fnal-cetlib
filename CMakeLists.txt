# - Toplevel CMake script for fnal::cetlib
cmake_minimum_required(VERSION 3.3)
project(cetlib VERSION 1.17.2)

# Mock cetbuildtools
list(INSERT CMAKE_MODULE_PATH 0 "${PROJECT_SOURCE_DIR}/cbt")
include(MiniCet)

# C++ Standard Config
set(CMAKE_CXX_EXTENSIONS OFF)
set(cetlib_COMPILE_FEATURES
  cxx_auto_type
  cxx_generic_lambdas
  )

# Need Boost for
# - Filesystem
# - Regex(? std::regex used elsewhere)
# - Unit Test
find_package(Boost 1.50.0 REQUIRED
  filesystem
  system
  regex
  unit_test_framework
  )

# Make sure testign is enabled
enable_testing()

#-----------------------------------------------------------------------
# Process components
add_subdirectory(cetlib)
add_subdirectory(test)
#add_subdirectory( perllib )          # Modular plugin skeleton generator
#add_subdirectory( ups )              # ups files

#-----------------------------------------------------------------------
# Documentation
#
find_package(Doxygen 1.8)
if(DOXYGEN_FOUND)
  set(DOXYGEN_OUTPUT_DIR "${CMAKE_CURRENT_BINARY_DIR}/Doxygen")
  configure_file(Doxyfile.in Doxyfile @ONLY)
  add_custom_command(
    OUTPUT "${DOXYGEN_OUTPUT_DIR}/html/index.html"
    COMMAND "${DOXYGEN_EXECUTABLE}" "${CMAKE_CURRENT_BINARY_DIR}/Doxyfile"
    WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
    DEPENDS "${CMAKE_CURRENT_BINARY_DIR}/Doxyfile" cetlib
    COMMENT "Generating Doxygen docs for ${PROJECT_NAME}"
    )
  add_custom_target(doc ALL DEPENDS "${DOXYGEN_OUTPUT_DIR}/html/index.html")
endif()

install(DIRECTORY "${DOXYGEN_OUTPUT_DIR}/"
  DESTINATION "${CMAKE_INSTALL_DATAROOTDIR}/${PROJECT_NAME}/API"
  )

# ----------------------------------------------------------------------
# Packaging utility

#include(UseCPack)

#
# ======================================================================
