cmake_minimum_required(VERSION 3.19)
# FOR COMMAND_ERROR_IS_FATAL

project(SideAssist.Dashboard.Flutter)

find_program(
  FLUTTER_EXECUTABLE
  NAME flutter
  REQUIRED
)

list(APPEND FLUTTER_BUILD_COMMAND
  ${FLUTTER_EXECUTABLE} build)

if (WIN32)
  list(APPEND FLUTTER_BUILD_COMMAND windows)
else()
  message(FATAL_ERROR "Platform is not supported")
endif()

if (CMAKE_BUILD_TYPE STREQUAL "Debug")
  list(APPEND FLUTTER_BUILD_COMMAND --debug)
else()
  list(APPEND FLUTTER_BUILD_COMMAND --release)
endif()

add_custom_target(SideAssist.Dashboard.Flutter ALL
  COMMAND ${FLUTTER_BUILD_COMMAND}
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)
