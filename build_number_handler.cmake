# Copyright (c) 2024, Roman Koch, koch.roman@gmail.com
# SPDX-License-Identifier: MIT

function(handle_build_number target)
    set(BUILDNUMBER_FILEPATH "${CMAKE_SOURCE_DIR}/bin")
    set(ENV{BUILDNUMBER_FILEPATH} ${BUILDNUMBER_FILEPATH})

    set(BUILD_MACROS_DIRECTORY "${CMAKE_CURRENT_FUNCTION_LIST_DIR}")

    if(NOT EXISTS "${BUILDNUMBER_FILEPATH}/build_number.h")
        execute_process(
            COMMAND ${CMAKE_COMMAND} -P "${BUILD_MACROS_DIRECTORY}/build_number_inc.cmake"
            WORKING_DIRECTORY "${BUILD_MACROS_DIRECTORY}"
        )
    else()
        if(CMAKE_BUILD_TYPE MATCHES "Release")
            add_custom_command(
                TARGET ${target}
                COMMAND ${CMAKE_COMMAND} -P "${BUILD_MACROS_DIRECTORY}/build_number_inc.cmake"
                WORKING_DIRECTORY "${BUILD_MACROS_DIRECTORY}"
            )
        endif()
    endif()
endfunction()
