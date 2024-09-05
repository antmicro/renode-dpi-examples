*** Settings ***
Test Teardown                       Run Keywords
...                                     Test Teardown
...                                     Terminate And Log
Resource                            ${CURDIR}/../../robot/dpi-keywords.robot
Resource                            ${CURDIR}/../../robot/access-peripheral-keywords.robot

*** Variables ***
${SUBORDINATE_PERIPHERAL}           ahb_subordinate

${PLATFORM}                         ${CURDIR}/platform.resc
${BUILD_DIRECTORY}                  ${CURDIR}/build
${VERILATED_BINARY}                 ${BUILD_DIRECTORY}/verilated
${QUESTA_WORK_LIBRARY}              ${BUILD_DIRECTORY}/work_questa

*** Keywords ***
Create Machine
    Execute Command                 include @${PLATFORM}

Test Subordinate
# The values below are hardcoded in the HDL model of the Manager.
    Should Peripheral Contain       mem  Byte  0x0  12
    Should Peripheral Contain       mem  Word  0x4  5634
    Should Peripheral Contain       mem  DoubleWord  0x8  DEBC9A78

*** Test Cases ***
Should Connect Verilator
    [Tags]                          verilator
    Should Connect To Verilator And Reset Peripheral  ${SUBORDINATE_PERIPHERAL}  ${VERILATED_BINARY}  Create Machine

Should Connect Questa
    [Tags]                          questa
    Should Connect To Questa And Reset Peripheral  ${SUBORDINATE_PERIPHERAL}  ${QUESTA_WORK_LIBRARY}  Create Machine

Should Run Subordinate In Verilator
    [Tags]                          verilator
    Create Machine
    Connect To Verilator            ${SUBORDINATE_PERIPHERAL}  ${VERILATED_BINARY}

    Execute Command                 emulation RunFor "0.01"
    Test Subordinate

Should Run Subordinate In Questa
    [Tags]                          questa
    Create Machine
    Connect To Questa               ${SUBORDINATE_PERIPHERAL}  ${VERILATED_BINARY}

    Execute Command                 emulation RunFor '0.01'
    Test Subordinate
