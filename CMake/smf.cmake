#  1. over time this should become a proper cmake module

function(smfc_gen)
  set(options CPP GOLANG VERBOSE)
  set(oneValueArgs TARGET_NAME OUTPUT_DIRECTORY)
  set(multiValueArgs SOURCES INCLUDE_DIRS)
  cmake_parse_arguments(SMFC_GEN "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  # We need one per generator so we can pass it to the flatc compiler
  #
  set(flatc_generated_includes)
  set(smfc_generated_includes)

  # need to know the language we are generating
  set(smfc_language)
  set(flatc_language)
  if(SMFC_GEN_CPP)
    set(smfc_language "--language=cpp")
    set(flatc_language "--cpp")
  endif()
  if(SMFC_GEN_GOLANG)
    set(smfc_language "--language=go")
    set(flatc_language "--go")
  endif()
  # needed for the 'return' value
  set(SMF_GEN_OUTPUTS)

  # gen include dirs for each
  if(SMFC_GEN_INCLUDE_DIRS)
    foreach(d ${SMFC_GEN_INCLUDE_DIRS})
      list(APPEND flatc_generated_includes -I ${d})
    endforeach()
    string(REGEX REPLACE ";" ","
        smfc_generated_includes ${SMFC_GEN_INCLUDE_DIRS})
    set(smfc_generated_includes
        "--include_dirs=${smfc_generated_includes}")
  endif()

  foreach(FILE ${SMFC_GEN_SOURCES})
    get_filename_component(BASE_NAME ${FILE} NAME_WE)
    set(FLATC_OUTPUT
      "${SMFC_GEN_OUTPUT_DIRECTORY}/${BASE_NAME}_generated.h")
    set(SMF_GEN_OUTPUT
      "${SMFC_GEN_OUTPUT_DIRECTORY}/${BASE_NAME}.smf.fb.h")
    list(APPEND SMF_GEN_OUTPUTS ${FLATC_OUTPUT} ${SMF_GEN_OUTPUT})
    # flatc
    add_custom_command(OUTPUT ${FLATC_OUTPUT}
      COMMAND flatc
      ARGS --gen-name-strings --gen-object-api ${flatc_language}
      ARGS ${flatc_generated_includes} --force-empty
      ARGS --keep-prefix --json --reflect-names --defaults-json
      ARGS --gen-mutable --cpp-str-type 'seastar::sstring'
      ARGS -o "${SMFC_GEN_OUTPUT_DIRECTORY}/" "${FILE}"
      COMMENT "Building C++ header for ${FILE}"
      DEPENDS flatc
      DEPENDS ${FILE}
      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})
    # smfc
    add_custom_command(OUTPUT ${SMF_GEN_OUTPUT}
      COMMAND smfc
      ARGS --logtostderr --filename ${FILE}
      ARGS "${smfc_language}"
      ARGS "${smfc_generated_includes}"
      ARGS --output_path="${SMFC_GEN_OUTPUT_DIRECTORY}"
      COMMENT "Generating smf rpc stubs for ${FILE}"
      DEPENDS smfc
      DEPENDS ${FILE}
      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})
  endforeach()
  set(${SMFC_GEN_TARGET_NAME} ${SMF_GEN_OUTPUTS} PARENT_SCOPE)
endfunction()
