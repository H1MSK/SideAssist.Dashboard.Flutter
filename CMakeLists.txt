cmake_minimum_required(VERSION 3.19)
# FOR COMMAND_ERROR_IS_FATAL

project(SideAssist.Dashboard.Flutter)

option(${PROJECT_NAME}_BUILD_VERBOSE "Output verbose information when building(-v)" ON)

find_program(
  FLUTTER_EXECUTABLE
  NAME flutter
  REQUIRED
)

list(APPEND FLUTTER_BUILD_COMMAND
  ${FLUTTER_EXECUTABLE} build)

if (WIN32)
  list(APPEND FLUTTER_BUILD_COMMAND windows)
  set(PLATFORM_EPHEMERAL_FOLDER "${CMAKE_CURRENT_SOURCE_DIR}/windows/flutter/ephemeral")
else()
  message(FATAL_ERROR "Platform is not supported")
endif()

if (CMAKE_BUILD_TYPE STREQUAL "Debug")
  list(APPEND FLUTTER_BUILD_COMMAND --debug)
else()
  list(APPEND FLUTTER_BUILD_COMMAND --release)
endif()

if (${PROJECT_NAME}_BUILD_VERBOSE)
list(APPEND FLUTTER_BUILD_COMMAND -v)
endif()

add_custom_target(SideAssist.Dashboard.Flutter ALL
  COMMAND ${FLUTTER_BUILD_COMMAND}
  BYPRODUCTS
    "${CMAKE_CURRENT_SOURCE_DIR}/$.dart_tool"
    "${CMAKE_CURRENT_SOURCE_DIR}/build"
    "${CMAKE_CURRENT_SOURCE_DIR}/.flutter-plugins-dependencies"
    "${CMAKE_CURRENT_SOURCE_DIR}/.flutter-plugins"
    ${PLATFORM_EPHEMERAL_FOLDER}
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)
