########################################################################
# RunAndCompare.cmake
#
# This script is used by cet_test (via ${CMAKE_COMMAND} -P) when the REF
# option is used.  Not for independent inclusion or use outside
# CetTest.cmake
#
# Required parameters (via -D):
#
# TEST_EXEC
#   Exec to be tested.
# TEST_REF
#   File against which to compare STDOUT.
# TEST_OUT
#   Name of file to which STDOUT should be sent.
#
# Optional parameters (via -D):
#
# TEST_ARGS
#   CMake list (;-separated) of test exec arguments.
# TEST_REF_ERR
#   File against which to compare STDERR.
# TEST_ERR
#   Name of file to which STDERR should be sent.
# OUTPUT_FILTER
#   Filter program: must be able to take input by filename and output on STDOUT.
# OUTPUT_FILTER_ARGS
#   Filter program arguments.
########################################################################

# Utility function.
function(filter_and_compare FILE REF)
  set(filtered_file "${FILE}-filtered")
  execute_process(COMMAND ${OUTPUT_FILTER} ${OUTPUT_FILTER_ARGS} "${FILE}"
    OUTPUT_FILE "${filtered_file}"
    RESULT_VARIABLE FILTER_FAILED
    )

  if(FILTER_FAILED)
    message(FATAL_ERROR "Production of filtered output from ${FILE} failed.")
  endif()

  # - ?? Assumes diff (any particular variation?) ???
  execute_process(COMMAND diff -u "${REF}" "${filtered_file}"
    OUTPUT_VARIABLE DIFF_OUTPUT
    ERROR_VARIABLE DIFF_ERROR
    RESULT_VARIABLE COMPARE_FAILED
    )

  if(COMPARE_FAILED)
    if(DIFF_ERROR)
      set(err_message ${DIFF_ERROR})
    else()
      set(err_message ${DIFF_OUTPUT})
    endif()

    message("Comparison of filtered output ${filtered_file} with ${REF} failed:\n${err_message}")
    message(FATAL_ERROR "Error comparing ${filtered_file} and ${REF}.")
  endif()
endfunction()

# Input checks.
if(NOT TEST_EXEC)
  message(FATAL_ERROR "CMake variable TEST_EXEC not defined.")
endif()

if(NOT TEST_REF)
  message(FATAL_ERROR "CMake variable TEST_REF not defined.")
endif()

if(NOT TEST_OUT)
  message(FATAL_ERROR "CMake variable TEST_REF not defined.")
endif()

if(TEST_REF_ERR AND NOT TEST_ERR)
  message(FATAL_ERROR "TEST_REF_ERR is defined but TEST_ERR is not.")
endif()

if(TEST_REF_ERR)
  set(TEST_REF_ERR_CMD "ERROR_FILE")
endif()

if(NOT OUTPUT_FILTER)
  set(OUTPUT_FILTER filter-output)
endif()

# Run the test command and save the output.
execute_process(COMMAND ${TEST_EXEC} ${TEST_ARGS}
  RESULT_VARIABLE TEST_FAILED
  OUTPUT_FILE "${TEST_OUT}"
  ${TEST_REF_ERR_CMD} ${TEST_ERR}
  )

# Check for test failure.
if(TEST_FAILED)
  message(FATAL_ERROR "Execution of ${TEST_EXEC} ${TEST_ARGS} failed")
endif()

# Filter and compare output with reference.
filter_and_compare("${TEST_OUT}" "${TEST_REF}")

# Optionally filter and compare STDERR with reference.
if(TEST_REF_ERR)
  filter_and_compare("${TEST_ERR}" "${TEST_REF_ERR}")
endif()

