# - Module for isolating minimal set of CET buildtools functionality,
#   sans UPS.
# - Real mix for now, to be refactored into modules later
#
# Additional notes
# ----------------
# Enforcement of Compiler ID/Version
# ----------------------------------
# NOTIMPLEMENTED. Note however the content of the "PackageConfigVersion.cmake"
# file that CMake's CMakePackageConfigHelpers module generates.
# It also checks that 32/64 bitness of found package matches that being built
# for, and marks the found package version as "unsuitable".
# That needs further checking for behaviour, but this could be extended
# to Compiler ID/Version. I.e. mark package version as unsuitable if
# it was built with a different compiler/version than that in use
# by the client project.
# Could also be implemented by *optional* inclusion of a module file
# to check this. That way clients could switch between hard/soft
# checks (e.g. hard requirement in UPS land).
#
# Likely ordering of UPS/Default switching
# ----------------------------------------
# Setup that may be derived from the ups/product_deps file is a mix
# of install directory policy and compiler/build mode options.
# These are somewhat orthogonal, but need to have this setup
# before either the compiler flags can be set or the install dirs
# populated. A UPS style build also implies CACHE FORCE or some
# vars so the user can never override them in this mode.
#
# Install policy shouldn't affect CMAKE_INSTALL_PREFIX, but may modify
# bindir/libdir/cmakedir and so on
#
# It's qualifiers that affect build mode and flags, clear that:
#
# eN : Implies a GNU compiler version plus C++ standard
#      - Could validate version at least here
#      - Package defines a minimum standard, but might compile
#        against a newer one (e.g. code uses C++11, but compile
#        using C++14).
#      - Can probably be dealt with using compile features plus
#        typical option to "promote" standard by adding features
#        for the "promoted" standard.
# debug:opt:prof : Implies the build mode selected, and SINGLE MODE
#                  GENERATORS only (resolved if UPS, via
#                  CMAKE_PREFIX_PATH and suitable PackageConfig files,
#                  can find all modes at once!) ((but only a limitation
#                  in terms of *forcing* no mixing of, e.g., debug and
#                  release libs).
#                : At least there are easy sensible defaults here
#
# anything else ?
#
#

#-----------------------------------------------------------------------
# Copyright 2016 Ben Morgan <Ben.Morgan@warwick.ac.uk>
# Copyright 2016 University of Warwick

#-----------------------------------------------------------------------
# Upstream CMake modules
#
include(CMakeParseArguments)

#-----------------------------------------------------------------------
# UTILITY FUNCTIONS
#-----------------------------------------------------------------------
# macro set_ifnot(<var> <value>)
#       If variable var is not set, set its value to that provided
#
macro(set_ifnot _var _value)
  if(NOT ${_var})
    set(${_var} ${_value})
  endif()
endmacro()

#-----------------------------------------------------------------------
# function enum_option(<option>
#                      VALUES <value1> ... <valueN>
#                      TYPE   <valuetype>
#                      DOC    <docstring>
#                      [DEFAULT <elem>]
#                      [CASE_INSENSITIVE])
#          Declare a cache variable <option> that can only take values
#          listed in VALUES. TYPE may be FILEPATH, PATH or STRING.
#          <docstring> should describe that option, and will appear in
#          the interactive CMake interfaces. If DEFAULT is provided,
#          <elem> will be taken as the zero-indexed element in VALUES
#          to which the value of <option> should default to if not
#          provided. Otherwise, the default is taken as the first
#          entry in VALUES. If CASE_INSENSITIVE is present, then
#          checks of the value of <option> against the allowed values
#          will ignore the case when performing string comparison.
#
function(enum_option _var)
  set(options CASE_INSENSITIVE)
  set(oneValueArgs DOC TYPE DEFAULT)
  set(multiValueArgs VALUES)
  cmake_parse_arguments(_ENUMOP "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  # - Validation as needed arguments
  if(NOT _ENUMOP_VALUES)
    message(FATAL_ERROR "enum_option must be called with non-empty VALUES\n(Called for enum_option '${_var}')")
  endif()

  # - Set argument defaults as needed
  if(_ENUMOP_CASE_INSENSITIVE)
    set(_ci_values )
    foreach(_elem ${_ENUMOP_VALUES})
      string(TOLOWER "${_elem}" _ci_elem)
      list(APPEND _ci_values "${_ci_elem}")
    endforeach()
    set(_ENUMOP_VALUES ${_ci_values})
  endif()

  set_ifnot(_ENUMOP_TYPE STRING)
  set_ifnot(_ENUMOP_DEFAULT 0)
  list(GET _ENUMOP_VALUES ${_ENUMOP_DEFAULT} _default)

  if(NOT DEFINED ${_var})
    set(${_var} ${_default} CACHE ${_ENUMOP_TYPE} "${_ENUMOP_DOC} (${_ENUMOP_VALUES})")
  else()
    set(_var_tmp ${${_var}})
    if(_ENUMOP_CASE_INSENSITIVE)
      string(TOLOWER ${_var_tmp} _var_tmp)
    endif()

    list(FIND _ENUMOP_VALUES ${_var_tmp} _elem)
    if(_elem LESS 0)
      message(FATAL_ERROR "Value '${${_var}}' for variable ${_var} is not allowed\nIt must be selected from the set: ${_ENUMOP_VALUES} (DEFAULT: ${_default})\n")
    else()
      # - convert to lowercase
      if(_ENUMOP_CASE_INSENSITIVE)
        set(${_var} ${_var_tmp} CACHE ${_ENUMOP_TYPE} "${_ENUMOP_DOC} (${_ENUMOP_VALUES})" FORCE)
      endif()
    endif()
  endif()
endfunction()
#-----------------------------------------------------------------------
# END OF UTILITY FUNCTION SECTION
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# SETCOMPILERFLAGs.cmake Implementation
#-----------------------------------------------------------------------
# Replace hardcoded arguments to cet_set_compiler_flags() with
# options such that defaults match common uses cases
#-----------------------------------------------------------------------
# Diagnostics - applied as addendum to ALL build modes
# - cavalier
# - cautious (default, in *most* but not *all* use cases)
# - vigilant
# - paranoid
# (*) - could wrap in a macro to allow a default option to be set
enum_option(CET_COMPILER_DIAGNOSTIC_LEVEL
  VALUES CAUTIOUS CAVALIER VIGILANT PARANOID
  TYPE STRING
  DOC "Set warning diagnostic level"
  CASE_INSENSITIVE
  )
mark_as_advanced(CET_COMPILER_DIAGNOSTIC_LEVEL)

# - Diagnostics by language/compiler
foreach(_lang "C" "CXX")
  # GNU/Clang/Intel are mostly common...
  if(CMAKE_${_lang}_COMPILER_ID MATCHES "GNU|(Apple)+Clang|Intel")
    # C/C++ common
    set(CET_COMPILER_${_lang}_DIAGFLAGS_CAVALIER "")
    set(CET_COMPILER_${_lang}_DIAGFLAGS_CAUTIOUS "${CET_COMPILER_${_lang}_DIAGFLAGS_CAVALIER} -Wall -Werror=return-type")
    set(CET_COMPILER_${_lang}_DIAGFLAGS_VIGILANT "${CET_COMPILER_${_lang}_DIAGFLAGS_CAUTIOUS} -Wextra -Wno-long-long -Winit-self")

    # We want -Wno-unused-local-typedef in VIGILANT, but Intel doesn't know this
    if(NOT CMAKE_${_lang}_COMPILER_ID STREQUAL "Intel")
      set(CET_COMPILER_${_lang}_DIAGFLAGS_VIGILANT "${CET_COMPILER_${_lang}_DIAGFLAGS_VIGILANT} -Wno-unused-local-typedefs")
    endif()

    # Additional CXX option for VIGILANT
    if(${_lang} STREQUAL "CXX")
      set(CET_COMPILER_CXX_DIAGFLAGS_VIGILANT "${CET_COMPILER_CXX_DIAGFLAGS_VIGILANT} -Woverloaded-virtual")
    endif()

    set(CET_COMPILER_${_lang}_DIAGFLAGS_PARANOID "${CET_COMPILER_${_lang}_DIAGFLAGS_VIGILANT} -pedantic -Wformat-y2k -Wswitch-default -Wsync-nand -Wtrampolines -Wlogical-op -Wshadow -Wcast-qual")
  endif()
endforeach()

#-----------------------------------------------------------------------
# Assertions (i.e. no -DNDEBUG) in all build modes
#
option(CET_COMPILER_ENABLE_ASSERTS "enable assertions for all build modes" OFF)
mark_as_advanced(CET_COMPILER_ENABLE_ASSERTS)
# TODO all needed functions/calls

#-----------------------------------------------------------------------
# Treat warnings as errors
option(CET_COMPILER_WARNINGS_ARE_ERRORS "treat all warnings as errors" ON)
# - Allow override for deprecations
option(CET_COMPILER_ALLOW_DEPRECATIONS "ignore deprecation warnings" ON)

mark_as_advanced(
  CET_COMPILER_WARNINGS_ARE_ERRORS
  CET_COMPILER_ALLOW_DEPRECATIONS
  )

if(CET_COMPILER_WARNINGS_ARE_ERRORS)
  foreach(_lang "C" "CXX")
    if(CMAKE_${_lang}_COMPILER_ID MATCHES "GNU|(Apple)+Clang|Intel")
      set(CET_COMPILER_${_lang}_ERROR_FLAGS "-Werror")
      if(CET_COMPILER_ALLOW_DEPRECATIONS)
        set(CET_COMPILER_${_lang}_ERROR_FLAGS "${CET_COMPILER_${_lang}_ERROR_FLAGS} -Wno-error=deprecated-declarations")
      endif()
    endif()
  endforeach()
endif()

#-----------------------------------------------------------------------
# DWARF debugging levels
#
option(CET_COMPILER_DWARF_STRICT "only emit DWARF debugging info at defined level" ON)
# NB: this is a number, so again an enum option
enum_option(CET_COMPILER_DWARF_VERSION
  VALUES 2 3 4
  TYPE STRING
  DOC "Set version of DWARF standard to emit"
  )

mark_as_advanced(
  CET_COMPILER_DWARF_STRICT
  CET_COMPILER_DWARF_VERSION
  )

# Probably also need check that compiler in use supports DWARF...
if(CET_COMPILER_DWARF_STRICT)
  foreach(_lang "C" "CXX")
    if(CMAKE_${_lang}_COMPILER_ID MATCHES "GNU|(Apple)+Clang|Intel")
      set(CET_COMPILER_${_lang}_DWARF_FLAGS "-gdwarf-${CET_COMPILER_DWARF_VERSION} -gstrict-dwarf")
    endif()
  endforeach()
endif()

#-----------------------------------------------------------------------
# Undefined symbol policy
#
option(CET_COMPILER_NO_UNDEFINED_SYMBOLS "required full symbol resolution for shared libs" ON)
mark_as_advanced(CET_COMPILER_NO_UNDEFINED_SYMBOLS)

if(CET_COMPILER_NO_UNDEFINED_SYMBOLS)
  if(APPLE)
    set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,-undefined,error")
  else()
    set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,--no-undefined")
  endif()
elseif(APPLE)
  set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,-undefined,dynamic_lookup")
endif()

#-----------------------------------------------------------------------
# SSE2/Arch optimizations
#
option(CET_COMPILER_ENABLE_SSE2 "enable SSE2 specific optimizations" OFF)
mark_as_advanced(CET_COMPILER_ENABLE_SSE2)

if(CET_COMPILER_ENABLE_SSE2)
  foreach(_lang "C" "CXX")
    if(CMAKE_${_lang}_COMPILER_ID MATCHES "GNU|(Apple)+Clang|Intel")
      set(CET_COMPILER_${_lang}_SSE2_FLAGS "-msse2 -ftree-vectorizer-verbose")
    endif()
  endforeach()
endif()


#-----------------------------------------------------------------------
# Compile compiler flags
# TODO : Review which of these might be better as compile properties
# - General, All Mode Options
string(TOUPPER "${CET_COMPILER_DIAGNOSTIC_LEVEL}" CET_COMPILER_DIAGNOSTIC_LEVEL)
set(CMAKE_C_FLAGS "${CET_COMPILER_C_DIAGFLAGS_${CET_COMPILER_DIAGNOSTIC_LEVEL}} ${CET_COMPILER_C_ERROR_FLAGS} ${CMAKE_C_FLAGS}")
set(CMAKE_CXX_FLAGS "${CET_COMPILER_CXX_DIAGFLAGS_${CET_COMPILER_DIAGNOSTIC_LEVEL}} ${CET_COMPILER_CXX_ERROR_FLAGS} ${CMAKE_CXX_FLAGS}")

# DWARF flags only in debugging modes?

# SSE2 flags only in release (optimized) modes?

#-----------------------------------------------------------------------
# END OF SETCOMPILERFLAGS Implementation
#-----------------------------------------------------------------------


#-----------------------------------------------------------------------
# INSTALL/OUTPUT POLICIES
#-----------------------------------------------------------------------
# - Default to GNU-style
# -- Provide switch to use UPS-style install tree
# -- Essentially only needs to change defaults for binary dirs per
#    UPS's conventions. Naming structure should be derivable from
#    CMake builtins to query OS/bit/package
include(GNUInstallDirs)

# -- Provide additional variables for CMake/FHICL/GDML dirs
# Assumed that CMake Package Configuration files are architecture dependent
# Not *always* true, but gives a good default
if(NOT DEFINED CMAKE_INSTALL_CMAKEDIR)
  set(CMAKE_INSTALL_CMAKEDIR "" CACHE PATH "CMake package configuration files (LIBDIR/cmake)")
  set(CMAKE_INSTALL_CMAKEDIR "${CMAKE_INSTALL_LIBDIR}/cmake")
endif()

# FHICL files are always architecture independent
# - Policy at present is to follow other man/doc style and use "fhicl/PROJECT_NAME"
#   Could equally use PROJECT_NAME/fhicl as default if better fit
if(NOT DEFINED CMAKE_INSTALL_FHICLDIR)
  set(CMAKE_INSTALL_FHICLDIR "" CACHE PATH "FHICL configuration files (DATAROOTDIR/fhicl/PROJECT_NAME)")
  set(CMAKE_INSTALL_FHICLDIR "${CMAKE_INSTALL_DATAROOTDIR}/fhicl/${PROJECT_NAME}")
endif()

# GDML files are always architecture independent
# - Policy at present is to follow other man/doc style and use "gdml/PROJECT_NAME"
#   Could equally use PROJECT_NAME/gdml as default if better fit
if(NOT DEFINED CMAKE_INSTALL_GDMLDIR)
  set(CMAKE_INSTALL_GDMLDIR "" CACHE PATH "GDML configuration files (DATAROOTDIR/gdml/PROJECT_NAME)")
  set(CMAKE_INSTALL_GDMLDIR "${CMAKE_INSTALL_DATAROOTDIR}/gdml/${PROJECT_NAME}")
endif()

# ANY OTHERS?? (Discounting perllib as this is extremely limited and not critical for functionality)

# - As with other dirs,
#   - provide absolute path variables
#   - mark as advanced
# None of these variables are special cases like etc/var, so handling is simple
foreach(dir CMAKEDIR FHICLDIR GDMLDIR)
  mark_as_advanced(CMAKE_INSTALL_${dir})
  if(NOT IS_ABSOLUTE "${CMAKE_INSTALL_${dir}}")
    set(CMAKE_INSTALL_FULL_${dir} "${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_${dir}}")
  else()
    set(CMAKE_INSTALL_FULL_${dir} "${CMAKE_INSTALL_${dir}}")
  endif()
endforeach()

# - With those in place, can create buildtree layout for products
# Again, a policy decision, but sensible default is:
# - root directory for everything, efFectively mapping to
#   CMAKE_INSTALL_PREFIX
# - Separate directories under that for binary products in different
#   modes
# Could be extended to other install location variables if required
#
set(${PROJECT_NAME}_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}/BuildProducts")

# - Single mode generators, by default
# +- BuildProducts/
#    +- bin/
#    +- lib/
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${${PROJECT_NAME}_OUTPUT_DIRECTORY}/${CMAKE_INSTALL_BINDIR}")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${${PROJECT_NAME}_OUTPUT_DIRECTORY}/${CMAKE_INSTALL_LIBDIR}")
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${${PROJECT_NAME}_OUTPUT_DIRECTORY}/${CMAKE_INSTALL_LIBDIR}")

# - Multi mode generators, by default
# BuildProducts/
# +- Release/
# |  +- bin/
# |  +- lib/
# +- Debug/
# |  +- bin/
# |  +- lib/
# | ...
foreach(_conftype ${CMAKE_CONFIGURATION_TYPES})
  string(TOUPPER ${_conftype} _conftype_uppercase)
  set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_${_conftype_uppercase}
    "${${PROJECT_NAME}_OUTPUT_DIRECTORY}/${_conftype}/${CMAKE_INSTALL_BINDIR}"
    )
  set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_${_conftype_uppercase}
    "${${PROJECT_NAME}_OUTPUT_DIRECTORY}/${_conftype}/${CMAKE_INSTALL_LIBDIR}"
    )
  set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY_${_conftype_uppercase}
    "${${PROJECT_NAME}_OUTPUT_DIRECTORY}/${_conftype}/${CMAKE_INSTALL_LIBDIR}"
    )
endforeach()

#-----------------------------------------------------------------------
# CETTEST.cmake ET AL
#-----------------------------------------------------------------------
# - Clarify cet_test implementation/properties/running
# ALSO - USING A STANDARD BUILD PRODUCT BREAKS BASE CET_TEST...
# Current system doesn't allow for multiconfig generators, and test
# runners like cet_exec_test are not very portable (in that case,
# requires GNU getopt implementation).
# Also would like better factorization of
# - Build tests
# - Running tests
# - Handling results
#-----------------------------------------------------------------------
# END OF CETTEST.cmake IMPLEMENTATION
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# BOOST.UNIT HELPERS
#-----------------------------------------------------------------------
# Many places where Boost.unit is used.
# Generally always boils down to setting a couple of target properties
# and linking said target to the Boost.Unit library.
# Encapsulate this in a function taking the target to be "Boost.Unitified"
# Will need review if additional use cases/styles of use are encountered
# TODO: Error checking

# - Apply needed properties
function(set_boost_unit_properties _target)
  if(NOT TARGET ${_target})
    message(FATAL_ERROR "set_boost_unit_properties: input '${_target}' is not a valid CMake target")
  endif()

  # Append, don't overwrite, compile definitions.
  # All target types need(or rather use) BOOST_TEST_DYN_LINK
  # BOOST_TEST_MAIN for executables only
  set_property(TARGET ${_target}
    APPEND PROPERTY
      COMPILE_DEFINITIONS
        BOOST_TEST_DYN_LINK
        $<$<STREQUAL:$<TARGET_PROPERTY:${_target},TYPE>,EXECUTABLE>:BOOST_TEST_MAIN>
    )

  # PRIVATE incs/libs for now as is assumed tests will not be installed
  # include directories - make private for now
  target_include_directories(${_target} PRIVATE ${Boost_INCLUDE_DIRS})
  # libs to link - can't specify link rule here as others may use it.
  target_link_libraries(${_target} ${Boost_UNIT_TEST_FRAMEWORK_LIBRARY})
endfunction()
#-----------------------------------------------------------------------
# END OF BOOST.UNIT HELPERS
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# TBB.OFFLOAD HELPERS
#-----------------------------------------------------------------------
# Several places where "find_tbb_offloads" occurs. This command does
# not (apparently) appear anywhere in the cetbuildtools code, so
# seems to be a placeholder. Nevertheless, can provide a suitable
# wrapper to apply the additional properties needed
# TODO: Note that the CMake Variable TBB_OFFLOAD_FLAG also needs to be
# set... plus whatever other links... but that can all be co-located here.
function(set_tbb_offload_properties _target)
  if(NOT TARGET ${_target})
    message(FATAL_ERROR "set_tbb_offload_properties: input '${_target}' is not a valid CMake target")
  endif()

  # Only apply if the find_tbb_offloads command exists...
  if(COMMAND find_tbb_offloads)
    get_target_property(_target_sources ${_target} SOURCES)
    find_tbb_offloads(FOUND_VAR have_tbb_offload ${_target_sources})
    if(have_tbb_offload)
      set_property(TARGET ${_target}
        APPEND PROPERTY
          LINK_FLAGS ${TBB_OFFLOAD_FLAG}
        )
    endif()
  endif()
endfunction()
#-----------------------------------------------------------------------
# END OF TBB.OFFLOAD HELPERS
#-----------------------------------------------------------------------

