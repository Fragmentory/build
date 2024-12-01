# Copyright (c) 2024, Roman Koch, koch.roman@gmail.com
# SPDX-License-Identifier: MIT

function(revision_header target)
    set(GIT_HASH_SIZE 8)
    execute_process(COMMAND bash -c "git rev-parse --short=${GIT_HASH_SIZE} HEAD | tr -d '\n'" OUTPUT_VARIABLE GIT_HASH)

    execute_process(COMMAND bash -c "git config --get user.name| tr -d '\n'" OUTPUT_VARIABLE GIT_USER_NAME)
    execute_process(COMMAND bash -c "git config --get user.email| tr -d '\n'" OUTPUT_VARIABLE GIT_USER_EMAIL)
    message(STATUS "User contact info: ${GIT_USER_NAME} ${GIT_USER_EMAIL}")

    set(REVISION_FILEPATH "${PROJECT_SOURCE_DIR}/bin" CACHE INTERNAL "Path to the directory for generated files")
    set(REVISION_TEMPLATE_FILE "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/revision.h.in")

    configure_file(${REVISION_TEMPLATE_FILE} ${REVISION_FILEPATH}/revision.h @ONLY)

    if(NOT TARGET ${target})
        message(FATAL_ERROR "Target ${target} does not exist.")
    endif()

    target_include_directories(${target} PRIVATE ${REVISION_FILEPATH})
endfunction()
