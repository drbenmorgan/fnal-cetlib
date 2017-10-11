#-----------------------------------------------------------------------
# Configure generated sources
#

# - Is cebin/cend available in std:: namespace?
#   Create public config header to hold result
try_compile(CET_HAVE_STD_CBEGIN_CEND
  ${CMAKE_CURRENT_BINARY_DIR}/config
  ${CMAKE_CURRENT_SOURCE_DIR}/config/test-cbegin.cc
  # See also https://gitlab.kitware.com/cmake/cmake/issues/16456
  CMAKE_FLAGS "-DCMAKE_CXX_STANDARD=${CMAKE_CXX_STANDARD}"
  )
configure_file(cetconfig.h.in ${CMAKE_CURRENT_BINARY_DIR}/cetconfig.h @ONLY)

# - Configure shared library interfaces for build platform
configure_file(shlib_utils.cc.in ${CMAKE_CURRENT_BINARY_DIR}/shlib_utils.cc @ONLY)

#-----------------------------------------------------------------------
# List sources and headers
set(cetlib_SOURCES
  # Generated
  ${CMAKE_CURRENT_BINARY_DIR}/cetconfig.h
  ${CMAKE_CURRENT_BINARY_DIR}/shlib_utils.cc
  # Core
  BasicPluginFactory.cc
  BasicPluginFactory.h
  HorizontalRule.h
  LibraryManager.cc
  LibraryManager.h
  MD5Digest.cc
  MD5Digest.h
  PluginFactory.cc
  PluginFactory.h
  PluginTypeDeducer.h
  ProvideFilePathMacro.cc
  ProvideFilePathMacro.h
  SimultaneousFunctionSpawner.h
  assert_only_one_thread.h
  base_converter.cc
  base_converter.h
  bit_manipulation.h
  canonical_number.cc
  canonical_number.h
  canonical_string.cc
  canonical_string.h
  coded_exception.h
  column_width.cc
  column_width.h
  compiler_macros.h
  container_algorithms.h
  cpu_timer.cc
  cpu_timer.h
  crc32.cc
  crc32.h
  exception.h
  exception_collector.h
  exempt_ptr.h
  filepath_maker.cc
  filepath_maker.h
  filesystem.cc
  filesystem.h
  getenv.cc
  getenv.h
  hard_cast.h
  hypot.h
  include.cc
  include.h
  includer.cc
  includer.h
  lpad.cc
  lpad.h
  map_vector.h
  maybe_ref.h
  metaprogramming.h
  name_of.h
  no_delete.h
  nybbler.cc
  nybbler.h
  os_libpath.h
  ostream_handle.h
  pow.h
  propagate_const.h
  registry.h
  registry_via_id.h
  replace_all.cc
  replace_all.h
  rpad.cc
  rpad.h
  search_path.cc
  search_path.h
  sha1.cc
  sha1.h
  shlib_utils.h
  simple_stats.cc
  simple_stats.h
  split.h
  split_by_regex.cc
  split_by_regex.h
  split_path.cc
  split_path.h
  test_macros.h
  trim.h
  value_ptr.h
  zero_init.h
  # Detail
  detail/ostream_handle_impl.h
  detail/wrapLibraryManagerException.cc
  detail/wrapLibraryManagerException.h
  # SQLite
  sqlite/Connection.cc
  sqlite/Connection.h
  # Not used - doesn't appear in CMakeLists.txt, header only impl?
  #sqlite/ConnectionFactory.cc
  sqlite/ConnectionFactory.h
  sqlite/Exception.cc
  sqlite/Exception.h
  sqlite/Ntuple.h
  sqlite/Transaction.cc
  sqlite/Transaction.h
  sqlite/column.h
  sqlite/create_table.h
  sqlite/exec.cc
  sqlite/exec.h
  sqlite/helpers.cc
  sqlite/helpers.h
  sqlite/insert.h
  sqlite/query_result.cc
  sqlite/query_result.h
  sqlite/select.cc
  sqlite/select.h
  sqlite/statistics.cc
  sqlite/statistics.h
  sqlite/detail/DefaultDatabaseOpenPolicy.cc
  sqlite/detail/DefaultDatabaseOpenPolicy.h
  sqlite/detail/bind_parameters.cc
  sqlite/detail/bind_parameters.h
  sqlite/detail/column_constraint.cc
  sqlite/detail/column_constraint.h
  sqlite/detail/convert.h
  sqlite/detail/extract.h
  sqlite/detail/get_result.h
  sqlite/detail/normalize_statement.cc
  sqlite/detail/normalize_statement.h
  )

#-----------------------------------------------------------------------
# Create libraries and properties
# - Dynamic
add_library(cetlib SHARED ${cetlib_SOURCES})
target_include_directories(cetlib
  PUBLIC
    $<BUILD_INTERFACE:${PROJECT_BINARY_DIR}>
    $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
  )
target_link_libraries(cetlib
  Boost::filesystem
  Boost::regex
  SQLite::SQLite
  cetlib_except::cetlib_except
  ${CMAKE_DL_LIBS}
  )
if(NOT APPLE)
  target_link_libraries(cetlib OpenSSL::SSL OpenSSL::Crypto)
endif()

#-----------------------------------------------------------------------
# Program
add_executable(inc-expand inc-expand.cc)
target_link_libraries(inc-expand cetlib)

#-----------------------------------------------------------------------
# Install
#
install(TARGETS cetlib inc-expand
  EXPORT ${PROJECT_NAME}Targets
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
  LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
  ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
  )

# Install directory for headers - do this way as we don't have
# optional headers so no filtering/selection required
install(DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/" "${CMAKE_CURRENT_BINARY_DIR}/"
  DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/${PROJECT_NAME}
  FILES_MATCHING PATTERN "*.h" PATTERN "*.hpp" PATTERN "*.icc"
  PATTERN "test" EXCLUDE
  PATTERN "CMakeFiles" EXCLUDE
  )


#-----------------------------------------------------------------------
# Create exports file(s)
include(CMakePackageConfigHelpers)

# - Common to both trees
write_basic_package_version_file(
  "${PROJECT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
  COMPATIBILITY SameMajorVersion
  )

# - Build tree (EXPORT only for now, config file needs some thought,
#   dependent on the use of multiconfig)
export(
  EXPORT ${PROJECT_NAME}Targets
  NAMESPACE ${PROJECT_NAME}::
  FILE "${PROJECT_BINARY_DIR}/${PROJECT_NAME}Targets.cmake"
  )

# - Install tree
configure_package_config_file("${PROJECT_SOURCE_DIR}/${PROJECT_NAME}Config.cmake.in"
  "${PROJECT_BINARY_DIR}/InstallCMakeFiles/${PROJECT_NAME}Config.cmake"
  INSTALL_DESTINATION "${CMAKE_INSTALL_CMAKEDIR}/${PROJECT_NAME}"
  PATH_VARS CMAKE_INSTALL_INCLUDEDIR
  )

install(
  FILES
    "${PROJECT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
    "${PROJECT_BINARY_DIR}/InstallCMakeFiles/${PROJECT_NAME}Config.cmake"
  DESTINATION
    "${CMAKE_INSTALL_CMAKEDIR}/${PROJECT_NAME}"
    )

install(
  EXPORT ${PROJECT_NAME}Targets
  NAMESPACE ${PROJECT_NAME}::
  DESTINATION "${CMAKE_INSTALL_CMAKEDIR}/${PROJECT_NAME}"
  )


# ======================================================================
# Testing
if(BUILD_TESTING)
  add_subdirectory(test)
endif()

