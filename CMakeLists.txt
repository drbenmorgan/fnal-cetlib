# - Toplevel CMake script for fnal::cetlib
cmake_minimum_required(VERSION 3.3)
project(cetlib VERSION 1.17.4)

# - Cetbuildtools, version2
find_package(cetbuildtools2 0.1.0 REQUIRED)
set(CMAKE_MODULE_PATH ${cetbuildtools2_MODULE_PATH})
include(CetInstallDirs)
include(CetCMakeSettings)
include(CetCompilerSettings)

# Putative settings...
# CET projects are (universally?) laid out so that the root source and
# build directories are equivalent to the root of the include
# directory. Set up so these are always added to the include directories
# property in the build interface, and that they always appear first
# to avoid clashes with any installed.
# Could also set the install interface using CMAKE_INSTALL_INCLUDEDIR
# though this would only account for a single use case (e.g. if
# a library installed both arch independent AND dependent headers)
# However, that's a special case and could be handled by additional
# calls to target_include_directories. Advantage of setting
# INSTALL_INTERFACE here is that it'll always appear FIRST in the
# interface include dirs, so avoiding one source of clashes (if
# INTERFACE_INCLUDE_DIRS has absolute paths relating to deps. may
# be resolved by going to fully imported targets)
#set(CMAKE_INCLUDE_DIRECTORIES_PROJECT_BEFORE ON)
set_directory_properties(PROPERTIES
  INCLUDE_DIRECTORIES
  "$<BUILD_INTERFACE:${PROJECT_SOURCE_DIR};${PROJECT_BINARY_DIR}>;$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>"
    )

# - Helpful to avoid relinking when only implementation of shared lib
# has changed
set(CMAKE_LINK_DEPENDS_NO_SHARED ON)

# Default to shared libs if not specified
option(BUILD_SHARED_LIBS "Build shared libraries by default" ON)

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
endif()

install(DIRECTORY "${DOXYGEN_OUTPUT_DIR}/"
  DESTINATION "${CMAKE_INSTALL_DATAROOTDIR}/${PROJECT_NAME}/API"
  )

# ----------------------------------------------------------------------
# Packaging utility

#include(UseCPack)

#
# ======================================================================
