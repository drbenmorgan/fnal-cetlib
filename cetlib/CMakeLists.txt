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
  os_libpath.h
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
  test_macros.h
  trim.h
  value_ptr.h
  zero_init.h
  )

set(cetlib_DETAIL_HEADERS
  detail/wrapLibraryManagerException.h
  )

#-----------------------------------------------------------------------
# Sources
#
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/shlib_utils.cc.in
  ${CMAKE_CURRENT_BINARY_DIR}/shlib_utils.cc @ONLY
  )
set(cetlib_SOURCES
  ${CMAKE_CURRENT_BINARY_DIR}/shlib_utils.cc
  MD5Digest.cc
  BasicPluginFactory.cc
  LibraryManager.cc
  MD5Digest.cc
  PluginFactory.cc
  base_converter.cc
  canonical_number.cc
  canonical_string.cc
  column_width.cc
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
  sha1.cc
  simple_stats.cc
  split_by_regex.cc
  split_path.cc
  detail/wrapLibraryManagerException.cc
  )

#-----------------------------------------------------------------------
# Create libraries and properties
# - Dynamic
add_library(cetlib SHARED
  ${cetlib_PUBLIC_HEADERS}
  ${cetlib_DETAIL_HEADERS}
  ${cetlib_SOURCES}
  )
target_compile_features(cetlib PUBLIC ${cetlib_COMPILE_FEATURES})
target_include_directories(cetlib
  PUBLIC
    $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
  )
target_link_libraries(cetlib
  Boost::filesystem
  Boost::regex
  ${CMAKE_DL_LIBS}
  -lcrypto
  -lssl
  )

# - Archive
add_library(cetlib-static STATIC
  ${cetlib_PUBLIC_HEADERS}
  ${cetlib_DETAIL_HEADERS}
  ${cetlib_SOURCES}
  )
target_compile_features(cetlib-static PUBLIC ${cetlib_COMPILE_FEATURES})
target_include_directories(cetlib-static
  PUBLIC
    $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
  )

target_link_libraries(cetlib-static
  Boost::filesystem
  Boost::regex
  ${CMAKE_DL_LIBS}
  -lcrypto
  -lssl
  )
set_target_properties(cetlib-static PROPERTIES OUTPUT_NAME cetlib)

#-----------------------------------------------------------------------
# Program
add_executable(inc-expand inc-expand.cc)
target_link_libraries(inc-expand cetlib-static)

#-----------------------------------------------------------------------
# Install
#
install(TARGETS cetlib cetlib-static inc-expand
  EXPORT ${PROJECT_NAME}Targets
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
  LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
  ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
  )
# Install directory for headers - do this way as we don't have
# optional headers so no filtering/selection required
install(DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/"
  DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/${PROJECT_NAME}
  FILES_MATCHING PATTERN "*.h" PATTERN "*.hpp" PATTERN "*.icc"
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

