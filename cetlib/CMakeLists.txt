#-----------------------------------------------------------------------
# Define sources
# - Headers : Public, Detail, Polarssl
set(cetlib_PUBLIC_HEADERS
  BasicPluginFactory.h
  LibraryManager.h
  MD5Digest.h
  PluginFactory.h
  PluginTypeDeducer.h
  base_converter.h
  bit_manipulation.h
  canonical_number.h
  canonical_string.h
  coded_exception.h
  column_width.h
  compiler_macros.h
  container_algorithms.h
  cpu_timer.h
  crc32.h
  demangle.h
  exception.h
  exception_collector.h
  exempt_ptr.h
  filepath_maker.h
  filesystem.h
  getenv.h
  hard_cast.h
  hypot.h
  include.h
  includer.h
  lpad.h
  make_unique.h
  map_vector.h
  maybe_ref.h
  name_of.h
  no_delete.h
  ntos.h
  nybbler.h
  ostream_handle.h
  pow.h
  registry.h
  registry_via_id.h
  replace_all.h
  rpad.h
  search_path.h
  sha1.h
  shlib_utils.h
  simple_stats.h
  split.h
  split_by_regex.h
  split_path.h
  ston.h
  trim.h
  value_ptr.h
  zero_init.h
  )

set(cetlib_DETAIL_HEADERS
  detail/wrapLibraryManagerException.h
  )

set(cetlib_POLARSSL_HEADERS
  polarssl/config.h
  polarssl/md5.h
  polarssl/sha1.h
  polarssl/version.h
  )

#-----------------------------------------------------------------------
# Sources
#
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/shlib_utils.cc.in
  ${CMAKE_CURRENT_BINARY_DIR}/shlib_utils.cc @ONLY
  )
set(cetlib_SOURCES
  ${CMAKE_CURRENT_BINARY_DIR}/shlib_utils.cc
  BasicPluginFactory.cc
  LibraryManager.cc
  MD5Digest.cc
  PluginFactory.cc
  base_converter.cc
  canonical_number.cc
  canonical_string.cc
  cpu_timer.cc
  crc32.cc
  demangle.cc
  exception.cc
  exception_collector.cc
  filepath_maker.cc
  filesystem.cc
  getenv.cc
  include.cc
  includer.cc
  lpad.cc
  nybbler.cc
  replace_all.cc
  rpad.cc
  search_path.cc
  simple_stats.cc
  split_by_regex.cc
  split_path.cc
  detail/wrapLibraryManagerException.cc
  polarssl/md5.cc
  polarssl/sha1.cc
  )

#-----------------------------------------------------------------------
# Create libraries and properties
# - Dynamic
add_library(cetlib SHARED
  ${cetlib_PUBLIC_HEADERS}
  ${cetlib_DETAIL_HEADERS}
  ${cetlib_POLARSSL_HEADERS}
  ${cetlib_SOURCES}
  )
target_compile_features(cetlib PUBLIC ${cetlib_COMPILE_FEATURES})
target_include_directories(cetlib PUBLIC ${PROJECT_SOURCE_DIR} ${Boost_INCLUDE_DIRS})
target_link_libraries(cetlib
  ${Boost_FILESYSTEM_LIBRARY}
  ${Boost_REGEX_LIBRARY}
  ${Boost_SYSTEM_LIBRARY}
  ${CMAKE_DL_LIBS}
  )

# - Archive
add_library(cetlib-static STATIC
  ${cetlib_PUBLIC_HEADERS}
  ${cetlib_DETAIL_HEADERS}
  ${cetlib_POLARSSL_HEADERS}
  ${cetlib_SOURCES}
  )
target_compile_features(cetlib-static PUBLIC ${cetlib_COMPILE_FEATURES})
target_include_directories(cetlib-static PUBLIC ${PROJECT_SOURCE_DIR} ${Boost_INCLUDE_DIRS})
target_link_libraries(cetlib-static
  ${Boost_FILESYSTEM_LIBRARY}
  ${Boost_REGEX_LIBRARY}
  ${Boost_SYSTEM_LIBRARY}
  ${CMAKE_DL_LIBS}
  )
set_target_properties(cetlib-static PROPERTIES OUTPUT_NAME cetlib)

## ======================================================================
##
## Build/install script
##
## ======================================================================
#
#include(CetMake)
#
## ----------------------------------------------------------------------
## Build and install this project's library:
#
#set( LIB_NAME ${PROJECT_NAME} )
#
#configure_file(${CMAKE_CURRENT_SOURCE_DIR}/shlib_utils.cc.in
#  ${CMAKE_CURRENT_BINARY_DIR}/shlib_utils.cc @ONLY
#  )
#
#cet_make_library(LIBRARY_NAME ${LIB_NAME}
#  SOURCE
#  ${CMAKE_CURRENT_BINARY_DIR}/shlib_utils.cc
#  ../polarssl/md5.cc
#  MD5Digest.cc
#  ../polarssl/sha1.cc
#  BasicPluginFactory.cc
#  LibraryManager.cc
#  PluginFactory.cc
#  base_converter.cc
#  canonical_number.cc
#  canonical_string.cc
#  cpu_timer.cc
#  crc32.cc
#  demangle.cc
#  detail/wrapLibraryManagerException.cc
#  exception.cc
#  exception_collector.cc
#  filepath_maker.cc
#  filesystem.cc
#  getenv.cc
#  include.cc
#  includer.cc
#  lpad.cc
#  nybbler.cc
#  replace_all.cc
#  rpad.cc
#  search_path.cc
#  simple_stats.cc
#  split_path.cc
#  split_by_regex.cc
#  LIBRARIES
#  ${Boost_FILESYSTEM_LIBRARY}
#  ${Boost_REGEX_LIBRARY}
#  ${Boost_SYSTEM_LIBRARY}
#  -ldl
#  )
#
#
## ----------------------------------------------------------------------
## Build and install this project's executables:
#
#cet_make_exec( inc-expand
#               LIBRARIES ${LIB_NAME} ${Boost_FILESYSTEM_LIBRARY} ${Boost_REGEX_LIBRARY})
#
## ----------------------------------------------------------------------
## Install this project's headers and sources:
#
#install_headers(SUBDIRS detail)
#install_source(SUBDIRS detail)
#
##
## ======================================================================
