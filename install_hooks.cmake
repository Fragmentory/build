# Copyright (c) 2023, Roman Koch, koch.roman@gmail.com
# SPDX-License-Identifier: MIT

function(install_hooks script_path)
    
    set(BUILD_MACROS_DIRECTORY "${CMAKE_CURRENT_FUNCTION_LIST_DIR}")

    set(PRE_COMMIT_SCRIPT "${script_path}")
    set(GIT_HOOKS_DIR "${CMAKE_SOURCE_DIR}/.git/hooks")
    set(TARGET_HOOK "${GIT_HOOKS_DIR}/pre-commit")

    message(STATUS "Copy hook ${BUILD_MACROS_DIRECTORY}/${PRE_COMMIT_SCRIPT} to ${GIT_HOOKS_DIR}")

    add_custom_target(
        install_hooks ALL
        COMMAND ${CMAKE_COMMAND} -E make_directory ${GIT_HOOKS_DIR}
        COMMAND ${CMAKE_COMMAND} -E copy_if_different "${BUILD_MACROS_DIRECTORY}/${PRE_COMMIT_SCRIPT}" "${GIT_HOOKS_DIR}"
        COMMAND /bin/sh -c "chmod +x ${TARGET_HOOK}"
        COMMENT "Kopiere Pre-Commit-Hook-Skript nach ${TARGET_HOOK}, falls es nicht vorhanden ist"
    )

    set_target_properties(install_hooks PROPERTIES EXCLUDE_FROM_ALL TRUE)
endfunction()
