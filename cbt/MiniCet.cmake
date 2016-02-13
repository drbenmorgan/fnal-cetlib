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
#                      [DEFAULT <item>]
#                      [CASE_INSENSITIVE])
#          Declare a cache variable <option> that can only take values
#          listed in VALUES. TYPE may be FILEPATH, PATH or STRING.
#          <docstring> should describe that option, and will appear in
#          the interactive CMake interfaces. If DEFAULT is provided,
#          <item> will be taken as the element in VALUES
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
  list(GET _ENUMOP_VALUES 0 _default)
  if(_ENUMOP_DEFAULT)
    list(FIND _ENUMOP_VALUES "${_ENUMOP_DEFAULT}" _default_index)
    if(_default_index GREATER -1)
      list(GET _ENUMOP_VALUES ${_default_index} _default)
    else()
      message(FATAL_ERROR "enum_option DEFAULT value '${_ENUMOP_DEFAULT}' not present in value set '${_ENUMOP_VALUES}'\n")
    endif()
  endif()

  if(NOT DEFINED ${_var})
    set(${_var} ${_default} CACHE ${_ENUMOP_TYPE} "${_ENUMOP_DOC} (${_ENUMOP_VALUES})")
  else()
    set(_var_tmp ${${_var}})
    if(_ENUMOP_CASE_INSENSITIVE)
      string(TOLOWER ${_var_tmp} _var_tmp)
    endif()

    list(FIND _ENUMOP_VALUES ${_var_tmp} _elem)
    if(_elem LESS 0)
      message(FATAL_ERROR "enum_option value '${${_var}}' for variable ${_var} is not allowed\nIt must be selected from the set: ${_ENUMOP_VALUES} (DEFAULT: ${_default})\n")
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
# CET UTILITY FUNCTIONS
#-----------------------------------------------------------------------
# cet_get_dotted_version(UPSVERSION OUTPUTVAR)
# - convert UPS style version to standard dotted version
function(cet_get_dotted_version _upsversion _outputvar)
  string(REPLACE "_" "." _dottedvar "${_upsversion}")
  string(REGEX REPLACE "^v" "" _dottedvar "${_dottedvar}")
  set(${_outputvar} "${_dottedvar}" PARENT_SCOPE)
endfunction()

# cet_have_qualifier(QUALIFIERPATH MATCHSTRING OUTPUTVAR)
# - Search for entry MATCHSTRING in QUALIFIERPATH, setting OUTPUTVAR
#   to TRUE (FALSE) if (not) found.
function(cet_have_qualifier _qualpath _query _outputvar)
  string(REGEX MATCH "(^|:)${_query}(:|$)" _gotmatch "${_qualpath}")
  if(_gotmatch)
    set(${_outputvar} TRUE PARENT_SCOPE)
  else()
    set(${_outputvar} FALSE PARENT_SCOPE)
  endif()
endfunction()

# map primary qualifier to compiler
# e2 => GNU 4.7.1 std=c++11, std=gnu (fortran)
# e4 => GNU 4.8.1 std=c++11, std=gnu (fortran)
# e5 => GNU 4.8.2 std=c++11, std=gnu (fortran)
# e6 => GNU 4.9.1 std=c++1y, std=gnu (fortran)
# e7 => GNU 4.9.2 std=c++1y, std=gnu (fortran)
# e8 => GNU 5.2.0 std=c++14, std=gnu (fortran)
# e9 => GNU 4.9.3 std=c++14, std=gnu (fortran)
# i1 => Intel 14.0.2 std=c++11, GCC 4.8.2 backend
# Implement as a function, but maybe better as a lookup table/properties
# Set output var to compiler "VENDOR-VERSION" for input qualifier
function(cet_get_compiler_for_qualifier _qualifier _outputvar)
  set(_cet_compiler_vendor "UNKNOWN")
  set(_cet_compiler_version "UNKNOWN")

  # GNU...
  if(_qualifier MATCHES "e[0-9]")
    set(_cet_compiler_vendor "GNU")
    if(_qualifier STREQUAL "e2")
      set(_cet_compiler_version "4.7.1")
    elseif(_qualifier STREQUAL "e4")
      set(_cet_compiler_version "4.8.1")
    elseif(_qualifier STREQUAL "e5")
      set(_cet_compiler_version "4.8.2")
    elseif(_qualifier STREQUAL "e6")
      set(_cet_compiler_version "4.9.1")
    elseif(_qualifier STREQUAL "e7")
      set(_cet_compiler_version "4.9.2")
    elseif(_qualifier STREQUAL "e8")
      set(_cet_compiler_version "5.2.0")
    elseif(_qualifier STREQUAL "e9")
      set(_cet_compiler_version "4.9.3")
    endif()
  # - Intel
  elseif(_qualifier MATCHES "i[0-9]")
    set(_cet_compiler_vendor "Intel")
    if(_qualifier STREQUAL "i1")
      set(_cet_compiler_version "14.0.2")
    endif()
  endif()

  set(${_outputvar} "${_cet_compiler_vendor}-${_cet_compiler_version}" PARENT_SCOPE)
endfunction()



# - Check primary compiler/version qualifier
function(cet_validate_primary_qualifier _qualpath)
  # There can only be one
  string(REGEX MATCHALL "(e|i)[0-9]" _primaryquals "${_qualpath}")
  list(LENGTH _primaryquals _pqcount)
  if(_pqcount GREATER 1)
    message(FATAL_ERROR
      "More than one primary qualifier specificed in '${_qualpath}'\n"
      "${_primaryquals}\n"
      )
  endif()

  # Now have primary qualifier, so check we match up against the
  # in use compiler(s)
  cet_get_compiler_for_qualifier(${_primaryquals} _vendorinfo)
  foreach(_language C CXX Fortran)
    # Only process loaded languages
    if(CMAKE_${_language}_COMPILER_LOADED)
      if(NOT (_vendorinfo STREQUAL "${CMAKE_${_language}_COMPILER_ID}-${CMAKE_${_language}_COMPILER_VERSION}"))
        message(FATAL_ERROR "${_language} compiler '${_vendorinfo}' for qualifier '${_primaryquals}' does not match that loaded by CMake:\n"
        "${CMAKE_${_language}_COMPILER_ID}-${CMAKE_${_language}_COMPILER_VERSION}\n"
        )
      endif()
    endif()
  endforeach()
endfunction()

#-----------------------------------------------------------------------
# END OF CET UTILITY FUNCTION SECTION
#-----------------------------------------------------------------------


#-----------------------------------------------------------------------
# DECIDE ON UPSification OR NOT
#-----------------------------------------------------------------------
# "UPSification" means
# 1) Changing default locations for installation
#    ...
# 2) Using "qualifier" to fix build type, supported compiler(*),
#    language standard to compile against(**)
#    (*) This could mean failing if things don't match
#    (**) e.g. code only needs C++11, but want to compile against C++14
#         Vice Versa, failures will be handled by compile features
#
# https://cdcvs.fnal.gov/redmine/projects/cet-is-public/wiki/AboutQualifiers
#
# 3) Generation of install products (table files etc)
# 4) May be others
#

# To begin with, lets activate manually
# Strictly should be one-time because it affects so many things and
# like changing compiler, want to confine it to specific build dir.
if(UPS_BUILD_AND_INSTALL)
  # UPS Build/Install cannot support multimode generators
  if(CMAKE_CONFIGURATION_TYPES)
    message(FATAL_ERROR
      "UPS Build/Install fails for multimode generators (using ${CMAKE_GENERATOR} ${CMAKE_EXTRA_GENERATOR})"
      )
  endif()

  # -- Load "cetpkg_info_file.cmake" from build dir, custom handling
  #    failure so that message is specific
  # Can/should expect the following variables to be set/cached:
  # (deived from product_deps files by report_product_info program
  # CETPKG_NAME -> "product" var in CBT (==PROJECT_NAME)
  # CETPKG_VERSION -> "version" var in CBT (UPS style version)
  # CETPKG_DEFAULT_VERSION -> "default_version" var in CBT
  # CETPKG_ONLY_FOR_BUILD -> list of buildtime only deps
  # CETPKG_QUAL -> "full_qualifier" var in CBT (: separated list of q's)
  #                CAN BE OVERIDDEN BY MRB_QUALS FROM THE ENV...
  #                "<product>_full_qualifier" var in CBT
  #                NOT overrriden
  # CETPKG_TYPE -> doesn't map, used in env to set CMAKE_BUILD_TYPE
  #                Here, read and use it as default build type...
  # CETPKG_CC -> filename of C compiler
  # CETPKG_CXX -> filename of CXX compiler
  # CETPKG_FC -> filename of Fortran compiler
  # CETPKG_SOURCE -> ==PROJECT_SOURCE_DIR
  # CETPKG_BUILD -> ==PROJECT_BINARY_DIR
  #
  # Additional var set in the processing of these:
  #
  # "cet_ups_dir" == ${PROJECT_SOURCE_DIR}/ups
  # "qualifier" == "<product>_full_qualifier" stripped of ":(debug|opt|prof)"
  # "cet_dot_version" == PROJECT_VERSION
  #                      BUT... UPS/Proper versions must match
  #                      i.e. "1.2.3" == "v1_2_3" == "v1_02_0003" etc
  # "flavorqual_dir" = <product>/<version>/<flavorqual>
  #                    See SetFlavorQual module for how <flavorqual>
  #                    is derived (needs UPS and cetpkgsupport)
  #                    Effectively "OS.ARCH.quals"
  #
  # ADDITIONAL variables for install locations are derived from running
  # the report_XXXdir programs. Those query the product_deps file
  # directly, so no reason these can't be added to the above file:
  # There is however processing based on the value returned by the
  # report_XXXdir returns. All can return "flags"
  # - DEFAULT
  # - NONE
  # - ERROR
  #
  # Otherwise some postprocessing is done, mostly, if not exclusively
  # to regex replace "tags" "flavorqual_dir" and "product_dir" with
  # the CMake values "${flavorqual_dir}" and "${product}/${version}"
  # respectively. NB - these are all considered relative to
  # CMAKE_PREFIX_PATH.
  #
  # <product>_lib_dir -> DEFAULT = "${flavorqual_dir}/lib"
  # <product>_bin_dir -> DEFAULT = "${flovorqual_dir}/bin"
  # <product>_inc_dir -> DEFAULT = "${product}/${version}/include
  # <product>_fcl_dir -> DEFAULT = "${product}/${version}/fcl"
  # <product>_fw_dir  -> DEFAULT = NONE
  # <product>_gdml_dir -> DEFAULT = NONE(? but similar to fcl?)
  # <product>_perllib -> DEFAULT = NONE
  # <product>_ups_perllib ->
  # <product>_perllib_subdir ->
  # <product>_test_dir -> DEFAULT = "${product}/${version}/test"
  #
  # Though these are processed, they are either derived from info
  # in the product_deps or already in the cetpkg_info_file file.
  # TODO: THIS FILE NEEDS CREATING BY set_dev_products PROGRAM OR SIMILAR
  include("${PROJECT_BINARY_DIR}/cetpkg_variable_report.cmake"
    OPTIONAL
    RESULT_VARIABLE CETPKG_FILE_LOADED
    )
  if(NOT CETPKG_FILE_LOADED)
    message(FATAL_ERROR
      "UPS build and install requested, but required cache file:\n"
      "cetpkg_variable_report.cmake\n"
      "is not present in the build directory. Run setup_for_development first\n"
      )
  endif()

  # - Validate gross features:
  # -- CETPKG_NAME == PROJECT_NAME
  if(NOT (CETPKG_NAME STREQUAL PROJECT_NAME))
    message(FATAL_ERROR
      "UPS Product Name (${CETPKG_NAME}) != CMake Project Name ${PROJECT_NAME}\n"
      "The CMake project name is the definitive name"
      )
  endif()

  # -- Dotified(CETPKG_VERSION) == PROJECT_VERSION
  cet_get_dotted_version("${CETPKG_VERSION}" CETPKG_DOT_VERSION)
  if(NOT (CETPKG_DOT_VERSION VERSION_EQUAL PROJECT_VERSION))
    message(FATAL_ERROR
      "UPS Product Dot Version (${CETPKG_DOT_VERSION}) != CMake Project Version (${PROJECT_VERSION})\n"
      "The CMake project version is the definitive version and must be set as a dotted version in the top level project() call, e.g.\n"
      "project(foo VERSION 1.2.3)\n"
      )
  endif()

  # -- Validate qualifiers
  # The "qualifier" var
  string(REGEX REPLACE ":(debug|opt|prof)" "" qualifier "${CETPKG_QUAL}")
  message(STATUS "qualifier = ${qualifier}")
  # Get "primary qualifier" approx regex [ei][0-9]
  # Map it to compiler ID/Version
  # - fail if they don't match
  cet_validate_primary_qualifier(${CETPKG_QUAL})
  # Adjust minimum C++ standard for primary via compile features
  # - leave to CMake to determine if compiler supports the requisite
  #   features, and user to set their own min set of features.

  # -- Build mode
  # Should be able to take this directly from CETPKG_TYPE rather than
  # throught the qualifier.
  set(CMAKE_BUILD_TYPE "${CETPKG_TYPE}")

  # -- Install directories
  # Hard set defaults, i.e. overwrite even if -D'd
  # runtime     -> <product>_bin_dir
  # lib/archive -> <product>_lib_dir
  # cmakefile   -> distdir = <product>/<version>/cmake IF NOFLAVOR
  #                        = <flavorqual_dir>/lib/<product>/cmake ELSE
  # headers     -> header_install_dir = <product>_inc_dir
  #                ... usually, but not always, appends <product>
  #                ...plus subdir structures...
  # source      -> <product>/<version>/source/...subdirs...
  #
  # scripts     -> <product>_bin_dir
  # fhicl       -> <product>_fcl_dir
  # gdml        -> <product>_gdml_dir
  # Override and force to the cache all entries from GNUInstallDirs
  # Though items are visible in the cache for clarity, they cannot
  # be mofified as CET enforces a specific build policy
  # TODO: example below is just for illustration. There's no construction
  # /replacement of things like product_dir/flavorqual_dir from the
  # info from the .cmake file (could be
  # predone in the included .cmake file (or string_configure)
  set(product_base_dir "${CETPKG_NAME}/${CETPKG_VERSION}")
  set(product_flavorqual_dir "${product_base_dir}/OS.ARCH.QUALS")

  # - BINDIR
  set(CMAKE_INSTALL_BINDIR "${product_flavorqual_dir}/bin" CACHE PATH "user executables (UPS/CET policy)" FORCE)
  # - SBINDIR
  set(CMAKE_INSTALL_SBINDIR "${product_flavorqual_dir}/sbin" CACHE PATH "system admin executables (UPS/CET policy)" FORCE)
  # - LIBEXECDIR
  set(CMAKE_INSTALL_LIBEXECDIR "${product_flavorqual_dir}/libexec" CACHE PATH "program executables (UPS/CET policy)" FORCE)
  # - SYSCONFDIR
  set(CMAKE_INSTALL_SYSCONFDIR "${product_base_dir}/etc" CACHE PATH "read-only single-machine data (UPS/CET policy)" FORCE)
  # - SHAREDSTATEDIR
  set(CMAKE_INSTALL_SHAREDSTATEDIR "${product_base_dir}/com" CACHE PATH "modifiable architecture-independent data (UPS/CET policy)" FORCE)
  # - LOCALSTATEDIR
  set(CMAKE_INSTALL_LOCALSTATEDIR "${product_base_dir}/var" CACHE PATH "modifiable single-machine data (UPS/CET policy)" FORCE)
  # - LIBDIR
  set(CMAKE_INSTALL_LIBDIR "${product_flavorqual_dir}/lib" CACHE PATH "object code libraries (UPS/CET policy)" FORCE)
  # - INCLUDEDIR
  set(CMAKE_INSTALL_INCLUDEDIR "${product_base_dir}/include" CACHE PATH "C header files (UPS/CET policy)" FORCE)
  # - OLDINCLUDEDIR (CHECK GNU DOCS ON THIS)
  set(CMAKE_INSTALL_OLDINCLUDEDIR "/usr/include" CACHE PATH "C header files for non-gcc (/usr/include)" FORCE)
  # - DATAROOTDIR
  set(CMAKE_INSTALL_DATAROOTDIR "${product_base_dir}/share" CACHE PATH "read-only architecture-independent data root (UPS/CET policy)")

  # - The following are derived from datarootdir in GNUInstallDirs,
  #   we do the same, but with Cache forcing
  # - DATADIR
  set(CMAKE_INSTALL_DATADIR "" CACHE PATH "read-only architecture-independent data (DATAROOTDIR)" FORCE)
  set(CMAKE_INSTALL_DATADIR "${CMAKE_INSTALL_DATAROOTDIR}")
  # - INFODIR
  set(CMAKE_INSTALL_INFODIR "" CACHE PATH "info documentation (DATAROOTDIR/info)" FORCE)
  set(CMAKE_INSTALL_INFODIR "${CMAKE_INSTALL_DATAROOTDIR}/info")
  # - LOCALEDIR
  set(CMAKE_INSTALL_LOCALEDIR "" CACHE PATH "locale-dependent data (DATAROOTDIR/locale)" FORCE)
  set(CMAKE_INSTALL_LOCALEDIR "${CMAKE_INSTALL_DATAROOTDIR}/locale")
  # - MANDIR
  set(CMAKE_INSTALL_MANDIR "" CACHE PATH "man documentation (DATAROOTDIR/man)" FORCE)
  set(CMAKE_INSTALL_MANDIR "${CMAKE_INSTALL_DATAROOTDIR}/man")
  # - DOCDIR
  set(CMAKE_INSTALL_DOCDIR "" CACHE PATH "documentation root (DATAROOTDIR/doc/PROJECT_NAME)" FORCE)
  set(CMAKE_INSTALL_DOCDIR "${CMAKE_INSTALL_DATAROOTDIR}/doc/${PROJECT_NAME}")

  # CMAKE/CET Extensions
  # - Some copying from later on. Might be able to refactor these into
  # functions as main difference is FORCE to cache.
  # - CMAKEDIR
  set(CMAKE_INSTALL_CMAKEDIR "" CACHE PATH "CMake package configuration files (LIBDIR/cmake)" FORCE)
  set(CMAKE_INSTALL_CMAKEDIR "${CMAKE_INSTALL_LIBDIR}/cmake")
  # - FHICLDIR
  set(CMAKE_INSTALL_FHICLDIR "" CACHE PATH "FHICL configuration files (DATAROOTDIR/fhicl/PROJECT_NAME)" FORCE)
  set(CMAKE_INSTALL_FHICLDIR "${CMAKE_INSTALL_DATAROOTDIR}/fhicl/${PROJECT_NAME}")
  # - GDMLDIR
  set(CMAKE_INSTALL_GDMLDIR "" CACHE PATH "GDML configuration files (DATAROOTDIR/gdml/PROJECT_NAME)" FORCE)
  set(CMAKE_INSTALL_GDMLDIR "${CMAKE_INSTALL_DATAROOTDIR}/gdml/${PROJECT_NAME}")
  # - PERLLIB??
  # - TESTDIR??
  # - FWDIR??

endif()
#-----------------------------------------------------------------------
# END OF UPSificiation
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

#-----------------------------------------------------------------------
# Assertion management functions
#
# - PRIVATE: encapsulate the generator expression used to set NDEBUG
function(__cet_get_assert_genexp VAR)
  set(${VAR} "$<$<OR:$<CONFIG:Release>,$<CONFIG:MinSizeRel>>:NDEBUG>" PARENT_SCOPE)
endfunction()

# - Enable Asserts for all build modes
function(cet_enable_asserts)
  cmake_parse_arguments(CDA
    ""
    "DIRECTORY"
    ""
    ${ARGN}
    )
  set_ifnot(CDA_DIRECTORY "${CMAKE_CURRENT_LIST_DIR}")

  get_directory_property(_local_compile_defs DIRECTORY "${CDA_DIRECTORY}" COMPILE_DEFINITIONS)
  # Remove genexp and NDEBUG from list of compile definitions
  list(REMOVE_ITEM _local_compile_defs "NDEBUG")
  __cet_get_assert_genexp(_assert_genexp)
  list(REMOVE_ITEM _local_compile_defs "${_assert_genexp}")

  set_property(DIRECTORY "${CDA_DIRECTORY}"
    PROPERTY COMPILE_DEFINITIONS "${_local_compile_defs}"
    )
endfunction()

# - Disable asserts for all modes
function(cet_disable_asserts)
    cmake_parse_arguments(CDA
    ""
    "DIRECTORY"
    ""
    ${ARGN}
    )
  set_ifnot(CDA_DIRECTORY "${CMAKE_CURRENT_LIST_DIR}")

  get_directory_property(_local_compile_defs DIRECTORY "${CDA_DIRECTORY}" COMPILE_DEFINITIONS)

  # Remove genexp (not strictly neccessary, but avoids duplication
  __cet_get_assert_genexp(_assert_genexp)
  list(REMOVE_ITEM _local_compile_defs "${_assert_genexp}")
  list(APPEND _local_compile_defs "NDEBUG")

  set_property(DIRECTORY "${CDA_DIRECTORY}"
    PROPERTY COMPILE_DEFINITIONS "${_local_compile_defs}"
    )
endfunction()

# - Set assertions for "release style" modes only
function(cet_default_asserts)
  cmake_parse_arguments(CDA
    ""
    "DIRECTORY"
    ""
    ${ARGN}
    )
  set_ifnot(CDA_DIRECTORY "${CMAKE_CURRENT_LIST_DIR}")

  # Remove settings from all modes
  cet_enable_asserts(DIRECTORY "${CDA_DIRECTORY}")

  # Disable assertions for Release-style modes
  __cet_get_assert_genexp(_cetgexp)
  set_property(DIRECTORY "${CDA_DIRECTORY}"
    APPEND PROPERTY COMPILE_DEFINITIONS ${_cetgexp}
    )
endfunction()

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
# NOTE: Clang doesn't provide -gstrict-dwarf flag (simply ignores it and
# warns it's unused), but has further options for emitting debugging
# such as tuning output for gdb, lldb, sce.
# Dwarf version may also not be needed here.
foreach(_lang "C" "CXX")
  if(CMAKE_${_lang}_COMPILER_ID MATCHES "GNU|(Apple)+Clang|Intel")
    set(CET_COMPILER_${_lang}_DWARF_FLAGS "-gdwarf-${CET_COMPILER_DWARF_VERSION}")
    if(CET_COMPILER_DWARF_STRICT)
      set(CET_COMPILER_${_lang}_DWARF_FLAGS "${CET_COMPILER_${_lang}_DWARF_FLAGS} -gstrict-dwarf")
    endif()
  endif()
endforeach()

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

# Per-Mode flags (Release, Debug, RelWithDebInfo, MinSizeRel)
# DWARF done here as it's not completely generic like warnings
# - C Language
if(CMAKE_C_COMPILER_ID MATCHES "GNU|(Apple)+Clang|Intel")
  set(CMAKE_C_FLAGS_RELEASE        "-O3 -g ${CET_COMPILER_C_DWARF_FLAGS}")
  set(CMAKE_C_FLAGS_DEBUG          "-O0 -g ${CET_COMPILER_C_DWARF_FLAGS}")
  set(CMAKE_C_FLAGS_MINSIZEREL     "-O3 -g ${CET_COMPILER_C_DWARF_FLAGS} -fno-omit-frame-pointer")
  set(CMAKE_C_FLAGS_RELWITHDEBINFO "-O2 -g")
endif()

# - CXX Language
if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|(Apple)+Clang|Intel")
  set(CMAKE_CXX_FLAGS_RELEASE        "-O3 -g ${CET_COMPILER_CXX_DWARF_FLAGS}")
  set(CMAKE_CXX_FLAGS_DEBUG          "-O0 -g ${CET_COMPILER_CXX_DWARF_FLAGS}")
  set(CMAKE_CXX_FLAGS_MINSIZEREL     "-O3 -g ${CET_COMPILER_CXX_DWARF_FLAGS} -fno-omit-frame-pointer")
  set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "-O2 -g")
endif()

# SSE2 flags only in release (optimized) modes?

# Assertions are handled by compile definitions so they can be changed
# on a per directory tree basis. Set defaults here for project
cet_default_asserts(DIRECTORY "${PROJECT_SOURCE_DIR}")

# - If user requested, enable assertions in all modes
if(CET_COMPILER_ENABLE_ASSERTS)
  cet_enable_asserts(DIRECTORY "${PROJECT_SOURCE_DIR}")
endif()


# If we're generating for single-mode and no build type has been set,
# default to RelWithDebInfo
if(NOT CMAKE_CONFIGURATION_TYPES)
  if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE RelWithDebInfo
      CACHE STRING "Choose the type of build, options are: None Release MinSizeRel Debug RelWithDebInfo"
      FORCE
      )
  else()
    # Force to the cache, but use existing value, translating if
    # required from CET -> CMake types
    string(TOUPPER "${CMAKE_BUILD_TYPE}" _local_build_type)
    if(_local_build_type STREQUAL "PROF")
      set(CMAKE_BUILD_TYPE "MinSizeRel")
    endif()
    if(_local_build_type STREQUAL "OPT")
      set(CMAKE_BUILD_TYPE "Release")
    endif()

    set(CMAKE_BUILD_TYPE "${CMAKE_BUILD_TYPE}"
      CACHE STRING "Choose the type of build, options are: None Release MinSizeRel Debug RelWithDebInfo"
      FORCE
      )
  endif()
endif()

#-----------------------------------------------------------------------
# Configure compile features
# - Done here because we will want to perform any library feature checks
#   with all our requisite flags in place
# - What is the required standard?
#   - Project itself requires a minimum standard for use, determined
#     by its own code.
#   - It may be compiled against a higher standard if the user selects
#     this (USE CASE: installs for use by client packages that require
#     the higher standard)
#   - Project may link to lower level packages compiled against its
#     minimum or a higher standard.
#     - CMake cannot (out the box) tell if a package found by find_package
#       was compiled against the same standard. It's the job of the
#       config management system to ensure CMAKE_PREFIX_PATH is set
#       correctly so the compatible packages are located.
#       In fact that's exactly what CET/UPS does at the moment as
#       it's the primary qualifier that is used for setup of deps
#       and then to determine the standard to compile against
#
# - CMake's compile features are useful here, and will propagate/promote
#   the compile standard as needed, but need to think about error cases.
# - Qualifier translates to a specific compiler/version/std so can
#   translate that to the equivalent compile feature lists.
# - We'll *want* to set compile features to take advantage of their
#   usefulness outside the CET environment (and also within, they easily
#   abstract out and take care of setting any flags to enable std support)
#   , but will need care to integrate them with the minimum feature
#   sets implied by qualifiers (e.g. "e9" implies that the package
#   can only use the compile features supported by GNU 4.9.3 in C++14
#   mode).
#
# - Use Case: Allow user to specify minimum standard required, and to
#   promote standard above that. Some hard coding at present
set(__cet_cxx_standard_minimum 11)

enum_option(CET_COMPILER_CXX_STANDARD
  VALUES 11 14 17
  TYPE STRING
  DEFAULT ${__cet_cxx_standard_minimum}
  DOC "Set C++ Standard to compile against"
  CASE_INSENSITIVE
  )
mark_as_advanced(CET_COMPILER_CXX_STANDARD)

# - Compile Features
# Always disable vendor extensions
set(CMAKE_CXX_EXTENSIONS OFF)

# If requested standard is higher than minimum, add compile features
# for that standard to the main list. If compiler has no known features
# for the standard, exit with an error
if(CET_COMPILER_CXX_STANDARD GREATER __cet_cxx_standard_minimum)
  if(CMAKE_CXX${CET_COMPILER_CXX_STANDARD}_COMPILE_FEATURES)
    list(APPEND CET_TARGET_COMPILE_FEATURES ${CMAKE_CXX${CET_COMPILER_CXX_STANDARD}_COMPILE_FEATURES})
  else()
    message(FATAL_ERROR "Compilation requested against C++ standard '${CET_COMPILER_CXX_STANDARD}'\nbut detected compiler '${CMAKE_CXX_COMPILER_ID}', version '${CMAKE_CXX_COMPILER_VERSION}'\ndoes not support any features of that standard")
  endif()
endif()
message(STATUS "Compile features: ${CET_TARGET_COMPILE_FEATURES}")


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

