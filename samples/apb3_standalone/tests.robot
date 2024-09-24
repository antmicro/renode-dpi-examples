*** Settings ***
Test Teardown                       Run Keywords
...                                     Test Teardown
...                                     Terminate And Log
Resource                            ${CURDIR}/../../robot/dpi-keywords.robot

*** Variables ***
${BUILD_DIRECTORY}                  ${CURDIR}/build
${VERILATED_BINARY}                 ${BUILD_DIRECTORY}/verilated
${QUESTA_WORK_LIBRARY}              ${BUILD_DIRECTORY}/work_questa


*** Test Cases ***
Should Pass Assertions In Verilator
    [Tags]                          verilator
    # This test case just runs simulator and checks its return code
    ${simulationArguments}=         Create List
    Run Verilator                   ${VERILATED_BINARY}  ${simulationArguments}
