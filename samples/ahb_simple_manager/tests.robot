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

*** Keywords ***
Create Machine
    Execute Command                 include @${PLATFORM}

Should Run Subordinate
    [Arguments]                     ${peripheral}  ${run_simulation_keyword}
    Create Machine
    Connect To Simulation           ${peripheral}  ${run_simulation_keyword}

    Execute Command                 emulation RunFor "0.01"

# The values below are hardcoded in the HDL model of the Manager.
    Should Peripheral Contain       mem  Byte  0x0  12
    Should Peripheral Contain       mem  Word  0x4  5634
    Should Peripheral Contain       mem  DoubleWord  0x8  DEBC9A78

*** Test Cases ***
Should Connect Verilator
    [Tags]                          verilator
    Should Connect To Simulation And Reset Peripheral  ${SUBORDINATE_PERIPHERAL}  Create Machine  Run Verilator

Should Connect Questa
    [Tags]                          questa
    Should Connect To Simulation And Reset Peripheral  ${SUBORDINATE_PERIPHERAL}  Create Machine  Run Questa


Should Run Subordinate In Verilator
    [Tags]                          verilator
    Should Run Subordinate          ${SUBORDINATE_PERIPHERAL}  Run Verilator

Should Run Subordinate In Questa
    [Tags]                          questa
    Should Run Subordinate          ${SUBORDINATE_PERIPHERAL}  Run Questa

