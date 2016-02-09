# cet_make
#
# Identify the files in the current source directory and deal with them appropriately
# Users may opt to just include cet_make() in their CMakeLists.txt
# This implementation is intended to be called NO MORE THAN ONCE per subdirectory.
#
# NOTE: cet_make_exec and cet_make_test_exec are no longer part of
# cet_make or art_make and must be called explicitly.
#
# cet_make( [LIBRARY_NAME <library name>]
#           [LIBRARIES <library link list>]
#           [SUBDIRS <source subdirectory>] (e.g., detail)
#           [USE_PRODUCT_NAME]
#           [EXCLUDE <ignore these files>] )
#
#   If USE_PRODUCT_NAME is specified, the product name will be prepended
#   to the calculated library name
#   USE_PRODUCT_NAME and LIBRARY_NAME are mutually exclusive
#
#   NOTE: if your code includes art plugins, you MUST use art_make
#   instead of cet_make: cet_make will ignore all known plugin code.
#
# cet_make_library( LIBRARY_NAME <library name>
#                   SOURCE <source code list>
#                   [LIBRARIES <library list>]
#                   [WITH_STATIC_LIBRARY]
#                   [NO_INSTALL] )
#
#   Make the named library.
#
# cet_make_exec( <executable name>
#                [SOURCE <source code list>]
#                [LIBRARIES <library link list>]
#                [USE_BOOST_UNIT]
#                [NO_INSTALL] )
#
#   Build a regular executable.
#
# cet_script( <script-names> ...
#             [DEPENDENCIES <deps>]
#             [NO_INSTALL]
#             [GENERATED]
#             [REMOVE_EXTENSIONS] )
#
#   Copy the named scripts to ${${product}_bin_dir} (usually bin/).
#
#   If the GENERATED option is used, the script will be copied from
#   ${CMAKE_CURRENT_BINARY_DIR} (after being made by a CONFIGURE
#   command, for example); otherwise it will be copied from
#   ${CMAKE_CURRENT_SOURCE_DIR}.
#
#   If REMOVE_EXTENSIONS is specified, extensions will be removed from script names
#   when they are installed.
#
#   NOTE: If you wish to use one of these scripts in a CUSTOM_COMMAND,
#   list its name in the DEPENDS clause of the CUSTOM_COMMAND to ensure
#   it gets re-run if the script chagees.
#
# cet_lib_alias(LIB_TARGET <alias>+)
#
#   Create a courtesy link to the library specified by LIB_TARGET for
#   each specified <alias>, for e.g. backward compatibility
#   reasons. LIB_TARGET must be a target defined (ultimately) by
#   add_library.
#
#   e.g. cet_lib_alias(nutools_SimulationBase SimulationBase) would
#   create a new link (e.g.) libSimulationBase.so to the generated
#   library libnutools_SimulationBase.so (replace .so with .dylib for OS
#   X systems).
#
########################################################################
cmake_policy(VERSION 3.0.1) # We've made this work for 3.0.1.

include(CetParseArgs)
include(InstallSource)

# - ??
macro(_cet_check_lib_directory)
  # find $CETBUILDTOOLS_DIR/bin/report_libdir
  if(${${product}_lib_dir} MATCHES "NONE")
    message(FATAL_ERROR "Please specify a lib directory in product_deps")
  elseif(${${product}_lib_dir} MATCHES "ERROR")
    message(FATAL_ERROR "Invalid lib directory in product_deps")
  endif()
endmacro()

# - ??
macro(_cet_check_bin_directory)
  if(${${product}_bin_dir} MATCHES "NONE")
    message(FATAL_ERROR "Please specify a bin directory in product_deps")
  elseif(${${product}_bin_dir} MATCHES "ERROR")
    message(FATAL_ERROR "Invalid bin directory in product_deps")
  endif()
endmacro()

# - add_executable wrapper
macro(cet_make_exec cet_exec_name)
  set(cet_exec_file_list "")
  set(cet_make_exec_usage "USAGE: cet_make_exec( <executable name> [SOURCE <exec source>] [LIBRARIES <library list>] )")
  cet_parse_args( CME "LIBRARIES;SOURCE" "USE_BOOST_UNIT;NO_INSTALL" ${ARGN})

  # there are no default arguments
  if(CME_DEFAULT_ARGS)
    message(FATAL_ERROR  " undefined arguments ${CME_DEFAULT_ARGS} \n ${cet_make_exec_usage}")
  endif()

  file(GLOB exec_src ${cet_exec_name}.c ${cet_exec_name}.cc ${cet_exec_name}.cpp ${cet_exec_name}.C ${cet_exec_name}.cxx)
  list(LENGTH exec_src n_sources)
  if(n_sources EQUAL 1) # If there's more than one, let the user specify explicitly.
    list(INSERT CME_SOURCE 0 ${exec_src})
  endif()

  add_executable(${cet_exec_name} ${CME_SOURCE})

  # - TBB offload-ify
  set_tbb_offload_properties(${cet_exec_name})

  # - Boost.Unit.ify
  if(CME_USE_BOOST_UNIT)
    set_boost_unit_properties(${cet_exec_name})
  endif()

  # - Linking, but path vs what?
  if(CME_LIBRARIES)
    set(link_lib_list "")
    foreach(lib ${CME_LIBRARIES})
      string(REGEX MATCH [/] has_path "${lib}")
      if(has_path)
        list(APPEND link_lib_list ${lib})
      else()
        string(TOUPPER ${lib} ${lib}_UC)
        if(${${lib}_UC})
          _cet_debug_message("changing ${lib} to ${${${lib}_UC}}")
          list(APPEND link_lib_list ${${${lib}_UC}})
        else()
          list(APPEND link_lib_list ${lib})
        endif()
      endif()
    endforeach()
    target_link_libraries(${cet_exec_name} ${link_lib_list})
  endif()

  if(NOT CME_NO_INSTALL)
    _cet_check_bin_directory()
    install(TARGETS ${cet_exec_name} DESTINATION ${${product}_bin_dir})
  endif()
endmacro()


# - Build something?
macro(cet_make)
  set(cet_file_list "")
  set(cet_make_usage "USAGE: cet_make( [LIBRARY_NAME <library name>] [LIBRARIES <library list>] [SUBDIRS <source subdirectory>] [EXCLUDE <ignore these files>] )")
  cet_parse_args(CM "LIBRARY_NAME;LIBRARIES;SUBDIRS;EXCLUDE" "WITH_STATIC_LIBRARY;USE_PRODUCT_NAME" ${ARGN})

  # there are no default arguments
  if(CM_DEFAULT_ARGS)
    message(FATAL_ERROR  " undefined arguments ${CM_DEFAULT_ARGS} \n ${cet_make_usage}")
  endif()

  # use either LIBRARY_NAME or USE_PRODUCT_NAME, not both
  if(CM_USE_PRODUCT_NAME AND CM_LIBRARY_NAME)
    message(FATAL_ERROR "CET_MAKE: USE_PRODUCT_NAME and LIBRARY_NAME are mutually exclusive.")
  endif()

  # check for extra link libraries
  if(CM_LIBRARIES)
    set(cet_liblist "")
    foreach(lib ${CM_LIBRARIES})
      string(REGEX MATCH [/] has_path "${lib}")
      if(has_path)
        list(APPEND cet_liblist ${lib})
      else()
        string(TOUPPER  ${lib} ${lib}_UC)
        if(${${lib}_UC})
          _cet_debug_message( "changing ${lib} to ${${${lib}_UC}}")
          list(APPEND cet_liblist ${${${lib}_UC}})
        else()
          list(APPEND cet_liblist ${lib})
        endif()
      endif()
    endforeach()
  endif()

  # now look for other source files in this directory
  file(GLOB src_files *.c *.cc *.cpp *.C *.cxx )
  file(GLOB ignore_dot_files  .*.c .*.cc .*.cpp .*.C .*.cxx )
  file(GLOB ignore_plugins
    *_generator.cc
    *_module.cc
    *_plugin.cc
    *_service.cc
    *_source.cc
    *_dict.cpp
    *_map.cpp
    )
  # check subdirectories and also CMAKE_CURRENT_BINARY_DIR for generated code
  list(APPEND CM_SUBDIRS ${CMAKE_CURRENT_BINARY_DIR})
  foreach(sub ${CM_SUBDIRS})
    file(GLOB subdir_src_files ${sub}/*.c ${sub}/*.cc ${sub}/*.cpp ${sub}/*.C ${sub}/*.cxx)
    file(GLOB subdir_ignore_dot_files ${sub}/.*.c ${sub}/.*.cc ${sub}/.*.cpp ${sub}/.*.C ${sub}/.*.cxx)
    file(GLOB subdir_ignore_plugins
      ${sub}/*_generator.cc
      ${sub}/*_module.cc
      ${sub}/*_plugin.cc
      ${sub}/*_service.cc
      ${sub}/*_source.cc
      ${sub}/*_dict.cpp
      ${sub}/*_map.cpp
      )
    if(subdir_src_files)
      list(APPEND src_files ${subdir_src_files})
    endif()

    if(subdir_ignore_plugins)
      list(APPEND ignore_plugins ${subdir_ignore_plugins})
    endif()

    if(subdir_ignore_dot_files)
      list(APPEND ignore_dot_files ${subdir_ignore_dot_files})
    endif()
  endforeach()

  if(ignore_plugins)
    list(REMOVE_ITEM src_files ${ignore_plugins} )
  endif()

  if(ignore_dot_files)
    list(REMOVE_ITEM src_files ${ignore_dot_files})
  endif()

  if(CM_EXCLUDE)
    foreach(exclude_file ${CM_EXCLUDE})
      list(REMOVE_ITEM src_files ${CMAKE_CURRENT_SOURCE_DIR}/${exclude_file})
    endforeach()
  endif()

  set(have_library FALSE)
  foreach(file ${src_files})
    set(have_file FALSE)
    foreach(known_file ${cet_file_list})
      if("${file}" MATCHES "${known_file}")
        set(have_file TRUE)
      endif()
    endforeach()
    if(NOT have_file)
      set(cet_file_list ${cet_file_list} ${file})
      set(cet_make_library_src ${cet_make_library_src} ${file})
      set(have_library TRUE)
    endif()
  endforeach()
  #message(STATUS "cet_make debug: known files ${cet_file_list}")

  # calculate base name
  if(PACKAGE_TOP_DIRECTORY)
    string(REGEX REPLACE "^${PACKAGE_TOP_DIRECTORY}/(.*)" "\\1" CURRENT_SUBDIR "${CMAKE_CURRENT_SOURCE_DIR}")
  else()
    string(REGEX REPLACE "^${CMAKE_SOURCE_DIR}/(.*)" "\\1" CURRENT_SUBDIR "${CMAKE_CURRENT_SOURCE_DIR}")
  endif()

  string(REGEX REPLACE "/" "_" cet_make_name "${CURRENT_SUBDIR}")

  if(CM_USE_PRODUCT_NAME)
    set(cet_make_name ${product}_${cet_make_name})
  endif()

  if(have_library)
    if(CM_LIBRARY_NAME)
      set(cet_make_library_name ${CM_LIBRARY_NAME})
    else()
      set(cet_make_library_name ${cet_make_name})
    endif()
    _cet_debug_message("cet_make: building library ${cet_make_library_name} for ${CMAKE_CURRENT_SOURCE_DIR}")
    if(CM_LIBRARIES)
      cet_make_library(LIBRARY_NAME ${cet_make_library_name}
        SOURCE ${cet_make_library_src}
        LIBRARIES  ${cet_liblist}
        )
    else()
      cet_make_library(LIBRARY_NAME ${cet_make_library_name}
        SOURCE ${cet_make_library_src}
        )
    endif()
    #message( STATUS "cet_make debug: library ${cet_make_library_name} will be installed in ${${product}_lib_dir}")
  else()
    _cet_debug_message("cet_make: no library for ${CMAKE_CURRENT_SOURCE_DIR}")
  endif()

  # is there a dictionary?
  file(GLOB dictionary_header classes.h)
  file(GLOB dictionary_xml classes_def.xml)
  if(dictionary_header AND dictionary_xml)
    _cet_debug_message("cet_make: found dictionary in ${CMAKE_CURRENT_SOURCE_DIR}")
    set(cet_file_list ${cet_file_list} ${dictionary_xml} ${dictionary_header} )
    if(CM_LIBRARIES)
      build_dictionary(DICTIONARY_LIBRARIES ${cet_liblist})
    else()
      build_dictionary()
    endif()
  endif()
endmacro()

# - Builds, presumably a library
macro(cet_make_library)
  set(cet_file_list "")
  set(cet_make_library_usage "USAGE: cet_make_library( LIBRARY_NAME <library name> SOURCE <source code list> [LIBRARIES <library link list>] )")
  cet_parse_args( CML "LIBRARY_NAME;LIBRARIES;SOURCE" "WITH_STATIC_LIBRARY;NO_INSTALL" ${ARGN})
  # there are no default arguments
  if(CML_DEFAULT_ARGS)
    message(FATAL_ERROR  " undefined arguments ${CML_DEFAULT_ARGS} \n ${cet_make_library_usage}")
  endif()

  # check for a source code list
  if(CML_SOURCE)
    set(cet_src_list ${CML_SOURCE})
  else()
    message(FATAL_ERROR  "SOURCE is required \n ${cet_make_library_usage}")
  endif()

  # verify that the library name has been specified
  if(CML_LIBRARY_NAME)
    add_library( ${CML_LIBRARY_NAME} SHARED ${cet_src_list})
  else()
    message(FATAL_ERROR  "LIBRARY_NAME is required \n ${cet_make_library_usage}")
  endif()

  if(CML_LIBRARIES)
    set(cml_lib_list "")
    foreach (lib ${CML_LIBRARIES})
      string(REGEX MATCH [/] has_path "${lib}")
      if(has_path)
        list(APPEND cml_lib_list ${lib})
      else()
        string(TOUPPER  ${lib} ${lib}_UC)
        if(${${lib}_UC})
          _cet_debug_message("changing ${lib} to ${${${lib}_UC}}")
          list(APPEND cml_lib_list ${${${lib}_UC}})
        else()
          list(APPEND cml_lib_list ${lib})
        endif()
      endif()
    endforeach()
    target_link_libraries(${CML_LIBRARY_NAME} ${cml_lib_list})
  endif()

  # TBB.offload-ify
  set_tbb_offload_properties(${CML_LIBRARY_NAME})

  if(NOT CML_NO_INSTALL)
    _cet_check_lib_directory()
    cet_add_to_library_list(${CML_LIBRARY_NAME})
    install( TARGETS  ${CML_LIBRARY_NAME}
      RUNTIME DESTINATION ${${product}_bin_dir}
      LIBRARY DESTINATION ${${product}_lib_dir}
      ARCHIVE DESTINATION ${${product}_lib_dir}
      )
  endif()

  if(CML_WITH_STATIC_LIBRARY)
    add_library( ${CML_LIBRARY_NAME}S STATIC ${cet_src_list})
    if(CML_LIBRARIES)
      target_link_libraries( ${CML_LIBRARY_NAME}S ${cml_lib_list})
    endif()
    set_target_properties(${CML_LIBRARY_NAME}S PROPERTIES OUTPUT_NAME ${CML_LIBRARY_NAME})
    set_target_properties(${CML_LIBRARY_NAME}  PROPERTIES OUTPUT_NAME ${CML_LIBRARY_NAME})
    set_target_properties(${CML_LIBRARY_NAME}S PROPERTIES CLEAN_DIRECT_OUTPUT 1 )
    set_target_properties(${CML_LIBRARY_NAME}  PROPERTIES CLEAN_DIRECT_OUTPUT 1 )

    if(NOT CML_NO_INSTALL)
      install(TARGETS  ${CML_LIBRARY_NAME}S
        RUNTIME DESTINATION ${${product}_bin_dir}
        LIBRARY DESTINATION ${${product}_lib_dir}
        ARCHIVE DESTINATION ${${product}_lib_dir}
        )
    endif()
  endif()
endmacro()

# PROBABLY NOT NEEDED: USE CMAKE'S RUNTIME_OUTPUT_PATH INSTEAD
file(MAKE_DIRECTORY "${EXECUTABLE_OUTPUT_PATH}/")

# - Scripts
macro(cet_script)
  cet_parse_args(CS "DEPENDENCIES" "GENERATED;NO_INSTALL;REMOVE_EXTENSIONS" ${ARGN})
  if(CS_GENERATED)
    set(CS_SOURCE_DIR ${CMAKE_CURRENT_BINARY_DIR})
  else()
    set(CS_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR})
  endif()

  foreach(target_name ${CS_DEFAULT_ARGS})
    if(CS_REMOVE_EXTENSIONS)
      get_filename_component(target ${target_name} NAME_WE)
    else()
      set(target ${target_name})
    endif()
    cet_copy(${CS_SOURCE_DIR}/${target_name}
      PROGRAMS
      NAME ${target}
      NAME_AS_TARGET
      DESTINATION "${CMAKE_CURRENT_BINARY_DIR}"
      )
    # Install in product if desired.
    if(NOT CS_NO_INSTALL)
      install(PROGRAMS "${EXECUTABLE_OUTPUT_PATH}/${target}"
        DESTINATION "${${product}_bin_dir}")
    endif()
  endforeach()
endmacro()

# - ? use case for this?
function(cet_lib_alias LIB_TARGET)
  foreach(alias ${ARGN})
    add_custom_command(TARGET ${LIB_TARGET}
      POST_BUILD
      COMMAND ln -sf $<TARGET_LINKER_FILE_NAME:${LIB_TARGET}>
      ${CMAKE_SHARED_LIBRARY_PREFIX}${alias}${CMAKE_SHARED_LIBRARY_SUFFIX}
      COMMENT "Generate / refresh courtesy link ${CMAKE_SHARED_LIBRARY_PREFIX}${alias}${CMAKE_SHARED_LIBRARY_SUFFIX} -> $<TARGET_LINKER_FILE_NAME:${LIB_TARGET}>"
      VERBATIM
      WORKING_DIRECTORY ${LIBRARY_OUTPUT_PATH})
  endforeach()
endfunction()

