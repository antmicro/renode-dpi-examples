*** Settings ***
Test Teardown                       Run Keywords
...                                     Test Teardown
...                                     Terminate And Log
Resource                            ${CURDIR}/../../robot/dpi-keywords.robot

*** Variables ***
${BUILD_DIRECTORY}                  ${CURDIR}/build

*** Test Cases ***
Should Pass Assertions In Verilator
    [Tags]                          verilator
    # This test case just runs simulator and checks its return code
    ${arguments}=                   Create List
    Run Verilator                   ${arguments}
