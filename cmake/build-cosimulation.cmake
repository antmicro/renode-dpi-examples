cmake_minimum_required(VERSION 3.8)

if(POLICY CMP0074)
  cmake_policy(SET CMP0074 NEW)
endif()

if(NOT USER_RENODE_DIR AND DEFINED ENV{RENODE_ROOT})
  message(STATUS "Using RENODE_ROOT from environment as USER_RENODE_DIR")
  set(USER_RENODE_DIR $ENV{RENODE_ROOT} CACHE PATH "Absolute (!) path to Renode root directory or any other that contains VerilatorIntegrationLibrary.")
else()
  set(USER_RENODE_DIR CACHE PATH "Path to Renode root directory or any other that contains VerilatorIntegrationLibrary, relative to build directory.")
  get_filename_component(USER_RENODE_DIR "${USER_RENODE_DIR}" ABSOLUTE BASE_DIR ${CMAKE_CURRENT_BINARY_DIR})
endif()

if(CMAKE_HOST_WIN32)
  macro(_try_repair_path PATH_VAR_NAME IS_ENV)
    if(${IS_ENV})
      set(PATH $ENV{${PATH_VAR_NAME}})
    else()
      set(PATH ${${PATH_VAR_NAME}})
    endif()

    if(${PATH} MATCHES "^/" AND NOT IS_DIRECTORY ${PATH})
      find_program(CYGPATH_BIN NAMES "cygpath.exe" "cygpath")

      if(CYGPATH_BIN)
        execute_process(COMMAND ${CYGPATH_BIN} -m -a ${PATH} OUTPUT_VARIABLE CYGPATHED_PATH OUTPUT_STRIP_TRAILING_WHITESPACE)

        if(IS_DIRECTORY ${CYGPATHED_PATH})
          if(${IS_ENV})
            set(ENV{${PATH_VAR_NAME}} "${CYGPATHED_PATH}")
          else()
            set(${PATH_VAR_NAME} "${CYGPATHED_PATH}")
          endif()

          message(STATUS "Repaired ${PATH_VAR_NAME}: '${CYGPATHED_PATH}'")
        endif()
      endif()
    endif()
  endmacro()

  _try_repair_path(USER_RENODE_DIR FALSE)
  _try_repair_path(USER_VERILATOR_DIR FALSE)
  _try_repair_path(VERILATOR_ROOT TRUE)
endif()

# Default arguments for compilation and linking
list(APPEND PROJECT_COMP_ARGS -Wall)

if(${CMAKE_SYSTEM_NAME} STREQUAL "Linux")
  if(${CMAKE_CXX_COMPILER_ID} STREQUAL "GNU")
    list(APPEND PROJECT_LINK_ARGS -static-libstdc++ -static-libgcc)
  endif()
endif()

if(CMAKE_HOST_WIN32)
  list(APPEND PROJECT_LINK_ARGS ws2_32)
  list(APPEND PROJECT_COMP_ARGS -DVL_TIME_CONTEXT)
  if(${CMAKE_CXX_COMPILER_ID} STREQUAL "GNU")
    list(APPEND PROJECT_COMP_ARGS -Wno-unknown-pragmas)
    # Link all MinGW/Cygwin libraries statically
    list(APPEND PROJECT_LINK_ARGS -static)
  endif()
endif()

if(NOT VIL_DIR)
  if(NOT USER_RENODE_DIR OR NOT IS_ABSOLUTE "${USER_RENODE_DIR}")
    message(FATAL_ERROR "Please set the CMake's USER_RENODE_DIR variable to an absolute (!) path to Renode root directory or any other that contains VerilatorIntegrationLibrary.\nPass the '-DUSER_RENODE_DIR=<ABSOLUTE_PATH>' switch if you configure with the 'cmake' command. Optionally, consider using 'ccmake' or 'cmake-gui' which make it easier.")
  endif()
  
  message(STATUS "Looking for Renode VerilatorIntegrationLibrary inside ${USER_RENODE_DIR}...")
  set(VIL_FILE verilator-integration-library.cmake)
  # Look for the ${VIL_FILE} in the whole ${USER_RENODE_DIR} tree
  #   (don't use `/*/` as then an additional directory is required between the two)
  file(GLOB_RECURSE VIL_FOUND ${USER_RENODE_DIR}*/${VIL_FILE})
  
  list(LENGTH VIL_FOUND VIL_FOUND_N)
  if(${VIL_FOUND_N} EQUAL 1)
    string(REPLACE "/${VIL_FILE}" "" VIL_DIR ${VIL_FOUND})
  elseif(${VIL_FOUND_N} GREATER 1)
    string(REGEX REPLACE "/${VIL_FILE}" " " ALL_FOUND ${VIL_FOUND})
    message(FATAL_ERROR "Found more than one directory with VerilatorIntegrationLibrary inside USER_RENODE_DIR. Please choose one of them: ${ALL_FOUND}")
  endif()
  
  if(NOT VIL_DIR OR NOT EXISTS "${VIL_DIR}/${VIL_FILE}")
    message(FATAL_ERROR "Couldn't find valid VerilatorIntegrationLibrary inside USER_RENODE_DIR!")
  endif()
  
  include(${VIL_DIR}/${VIL_FILE})  # sets VIL_VERSION variable
  message(STATUS "Renode VerilatorIntegrationLibrary (version ${VIL_VERSION}) found in ${VIL_DIR}.")
  
  # Save VIL_DIR in cache
  set(VIL_DIR ${VIL_DIR} CACHE INTERNAL "")
endif()

# Prepare list of Renode DPI Integration files
set(VERILOG_LIBRARY ${VIL_DIR}/hdl)
file(GLOB_RECURSE RENODE_SOURCES ${VIL_DIR}/libs/socket-cpp/*.cpp)
list(APPEND RENODE_SOURCES ${VIL_DIR}/src/communication/socket_channel.cpp)
list(APPEND RENODE_SOURCES ${VIL_DIR}/src/renode_dpi.cpp)

if(NOT SIM_TOP OR NOT SIM_TOP_FILE)
  message(FATAL_ERROR "'SIM_TOP' and 'SIM_TOP_FILE' variable have to be set!")
endif()
set(ALL_SIM_FILES ${SIM_TOP_FILE})
list(APPEND ALL_SIM_FILES ${SIM_FILES})
foreach(SIM_FILE ${ALL_SIM_FILES})
  get_filename_component(SIM_FILE ${SIM_FILE} ABSOLUTE BASE_DIR)
  list(APPEND FINAL_SIM_FILES ${SIM_FILE})
endforeach()

###
### Prepare Verilator target
###
set(USER_VERILATOR_ARGS ${VERILATOR_ARGS} CACHE STRING "Extra arguments/switches for Verilating")
separate_arguments(USER_VERILATOR_ARGS)
set(FINAL_VERILATOR_ARGS ${USER_VERILATOR_ARGS})
list(APPEND FINAL_VERILATOR_ARGS "-I${VERILOG_LIBRARY}")
set(FINAL_LINK_ARGS ${PROJECT_LINK_ARGS})
set(FINAL_COMP_ARGS ${PROJECT_COMP_ARGS})

# Find Verilator
if(IS_DIRECTORY "${USER_VERILATOR_DIR}")
  # Verilator CMake logic prioritizes VERILATOR_ROOT environment variable
  message(STATUS "Using USER_VERILATOR_DIR instead of VERILATOR_ROOT environmental variable")
  get_filename_component(USER_VERILATOR_DIR ${USER_VERILATOR_DIR} ABSOLUTE BASE_DIR ${CMAKE_CURRENT_BINARY_DIR})
  set(ENV{VERILATOR_ROOT} ${USER_VERILATOR_DIR})
endif()
find_package(verilator HINTS ${USER_VERILATOR_DIR} $ENV{VERILATOR_ROOT})
if(NOT verilator_FOUND)
  set(USER_VERILATOR_DIR CACHE PATH "Path to the Verilator's root directory, relative to build directory.")
  message(NOTICE "There's no Verilator installed. This target will be ignored.")
else()
  if(NOT VERILATOR_CSOURCES)
    message(FATAL_ERROR "'VERILATOR_CSOURCES' it's required to set this variable for Verilator target!")
  endif()
  add_executable(verilated ${VERILATOR_CSOURCES} ${RENODE_SOURCES})
  target_include_directories(verilated PRIVATE ${VIL_DIR})
  target_compile_options(verilated PRIVATE ${FINAL_COMP_ARGS})
  target_link_libraries(verilated PRIVATE ${FINAL_LINK_ARGS})
  verilate(verilated SOURCES ${SIM_TOP_FILE} VERILATOR_ARGS ${FINAL_VERILATOR_ARGS})
endif()

###
### Prepare Questa target
###
set(USER_QUESTA_PATH CACHE STRING "Path to Questa bin directory")
find_program(QUESTA_VLIB vlib ${USER_QUESTA_PATH})
find_program(QUESTA_VLOG vlog ${USER_QUESTA_PATH})
find_program(QUESTA_VOPT vopt ${USER_QUESTA_PATH})
find_program(QUESTA_VSIM vsim ${USER_QUESTA_PATH})

set(USER_QUESTA_WORKDIR_NAME work_questa CACHE STRING "Name of Questa workdir")
set(USER_QUESTA_OPTIMIZED_DESIGN design_optimized CACHE STRING "Name of Questa optimized design")
set(USER_QUESTA_ARGS ${QUESTA_ARGS} CACHE STRING "Extra arguments/switches used for build and run Questa commands (vlog, vopt, vsim)")
separate_arguments(USER_QUESTA_ARGS)
set(FINAL_QUESTA_ARGS ${USER_QUESTA_ARGS})
list(APPEND FINAL_QUESTA_ARGS -work ${USER_QUESTA_WORKDIR_NAME})

set(USER_QUESTA_OPTIMIZATION_ARGS ${QUESTA_OPTIMIZATION_ARGS} CACHE STRING "Extra arguments/switches used for all Questa vlog command")

if(NOT QUESTA_VLIB OR NOT QUESTA_VLOG OR NOT QUESTA_VOPT OR NOT QUESTA_VSIM)
  message(NOTICE "There's no Questa available. This target will be ignored.")
else()
  add_custom_command(OUTPUT questa_workdir
    COMMAND ${QUESTA_VLIB} ${USER_QUESTA_WORKDIR_NAME}
  )
  add_custom_command(OUTPUT questa_compiled
    COMMAND ${QUESTA_VLOG} ${FINAL_QUESTA_ARGS} ${FINAL_SIM_FILES} ${RENODE_SOURCES} "+incdir+${VERILOG_LIBRARY}"
    DEPENDS questa_workdir ${FINAL_SIM_FILES} ${RENODE_SOURCES}
  )
  add_custom_command(OUTPUT questa_optimized
    COMMAND ${QUESTA_VOPT} ${FINAL_QUESTA_ARGS} ${SIM_TOP} ${USER_QUESTA_OPTIMIZATION_ARGS} -o ${USER_QUESTA_OPTIMIZED_DESIGN}
    DEPENDS questa_compiled
  )
  add_custom_target(questa-build ALL DEPENDS questa_optimized)
endif()
