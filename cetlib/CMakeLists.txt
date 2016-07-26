# ALT_CMAKE construct
if(ALT_CMAKE)
  include(altCMakeLists.cmake)
else()

# ======================================================================
#
# Build/install script
#
# ======================================================================

include(CetMake)

# ----------------------------------------------------------------------
# Build and install this project's library:

set( LIB_NAME ${PROJECT_NAME} )

configure_file(${CMAKE_CURRENT_SOURCE_DIR}/shlib_utils.cc.in
  ${CMAKE_CURRENT_BINARY_DIR}/shlib_utils.cc @ONLY
  )

cet_make_library(LIBRARY_NAME ${LIB_NAME}
  SOURCE
  ${CMAKE_CURRENT_BINARY_DIR}/shlib_utils.cc
  MD5Digest.cc
  BasicPluginFactory.cc
  LibraryManager.cc
  PluginFactory.cc
  base_converter.cc
  canonical_number.cc
  canonical_string.cc
  column_width.cc
  cpu_timer.cc
  crc32.cc
  demangle.cc
  detail/wrapLibraryManagerException.cc
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
  sha1.cc
  simple_stats.cc
  split_path.cc
  split_by_regex.cc
  LIBRARIES
  ${Boost_FILESYSTEM_LIBRARY}
  ${Boost_REGEX_LIBRARY}
  ${Boost_SYSTEM_LIBRARY}
  ${CMAKE_DL_LIBS}
  -lcrypto
  -lssl
  )


# ----------------------------------------------------------------------
# Build and install this project's executables:

cet_make_exec( inc-expand
               LIBRARIES ${LIB_NAME} ${Boost_FILESYSTEM_LIBRARY} ${Boost_REGEX_LIBRARY} )

# ----------------------------------------------------------------------
# Install this project's headers and sources:

install_headers(SUBDIRS detail)
install_source(SUBDIRS detail)

#
# ======================================================================
# Testing
add_subdirectory(test)

endif() #ALT_CMAKE
