# - Toplevel CMake script for fnal::cetlib
cmake_minimum_required(VERSION 3.3)
project(cetlib VERSION 1.17.2)

# Mock cetbuildtools
list(INSERT CMAKE_MODULE_PATH 0 "${PROJECT_SOURCE_DIR}/cbt")

include(GNUInstallDirs)

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

# ----------------------------------------------------------------------
# Packaging utility

#include(UseCPack)

#
# ======================================================================
