# Copyright (c) 2023, Roman Koch, koch.roman@gmail.com
# SPDX-License-Identifier: MIT

add_custom_target(generate_authors
    COMMAND ${CMAKE_COMMAND} -E env bash ${CMAKE_SOURCE_DIR}/build/generate_authors.sh ${CMAKE_SOURCE_DIR}/bin/authors.txt
    COMMENT "Generating list of copyright holders"
)

find_program(FIGLET figlet)
if(WIN32)
    if(FIGLET)
        add_custom_target(
            ascii_art
            COMMAND ${FIGLET} ${PROJECT_NAME} ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR} && ${FIGLET} -f small ${PROJECT_DESCRIPTION} && echo && type ${PROJECT_SOURCE_DIR}/bin/authors.txt && echo
            VERBATIM
        )
    else()
        add_custom_target(
            ascii_art
            COMMAND echo && echo ${PROJECT_NAME} ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR} && echo ${PROJECT_DESCRIPTION} && echo && type ${PROJECT_SOURCE_DIR}/bin/authors.txt && echo
            VERBATIM
        )
    endif()
else()
    if(FIGLET)
        add_custom_target(
            ascii_art
            COMMAND sh -c "figlet ${PROJECT_NAME} ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR} && figlet -f small ${PROJECT_DESCRIPTION} && echo && cat ${PROJECT_SOURCE_DIR}/bin/authors.txt && echo"
            VERBATIM
        )
    else()
        add_custom_target(
            ascii_art
            COMMAND sh -c "echo && echo ${PROJECT_NAME} ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR} && echo ${PROJECT_DESCRIPTION} && echo && cat ${PROJECT_SOURCE_DIR}/bin/authors.txt && echo"
            VERBATIM
        )
    endif()
endif()

add_dependencies(ascii_art generate_authors)
