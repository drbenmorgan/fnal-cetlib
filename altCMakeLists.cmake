# - Toplevel CMake script for fnal::cetlib
cmake_minimum_required(VERSION 3.3)
project(cetlib VERSION 1.18.2)

# - Cetbuildtools, version2
find_package(cetbuildtools2 0.1.0 REQUIRED)
set(CMAKE_MODULE_PATH ${cetbuildtools2_MODULE_PATH})
include(CetInstallDirs)
include(CetCMakeSettings)
include(CetCompilerSettings)

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
find_package(Boost 1.60.0 REQUIRED
  filesystem
  system
  regex
  unit_test_framework
  )

# Need OpenSSL on non-Apple for MD5/SHA1 implementations
# On Apple, always use builtin CommonCrypto
if(NOT APPLE)
  find_package(OpenSSL REQUIRED)

  # If we have CMake < 3.4, then will need to match imported targets
endif()

#-----------------------------------------------------------------------
# Process components
add_subdirectory(cetlib)

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
  install(DIRECTORY "${DOXYGEN_OUTPUT_DIR}/"
    DESTINATION "${CMAKE_INSTALL_DATAROOTDIR}/${PROJECT_NAME}/API"
    )
endif()

# ----------------------------------------------------------------------
# Packaging utility

#include(UseCPack)

#
# ======================================================================
