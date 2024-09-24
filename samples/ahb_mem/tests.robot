*** Settings ***
Test Teardown                       Run Keywords
...                                     Test Teardown
...                                     Terminate And Log
Resource                            ${CURDIR}/../../robot/dpi-keywords.robot
Resource                            ${CURDIR}/../../robot/access-peripheral-keywords.robot

*** Variables ***
${MEMORY_PERIPHERAL}                mem
${TEST_DATA}                        12345678CAFEBABE000000005A5A5A5A

${PLATFORM}                         ${CURDIR}/platform.resc
${BUILD_DIRECTORY}                  ${CURDIR}/build

*** Keywords ***
Create Machine
    Execute Command                 include @${PLATFORM}

Test Read And Write Memory
    ${access_types}=                Create List  DoubleWord  Word  Byte

    FOR  ${write_access_type}  IN  @{access_types}
        Write To Peripheral             ${MEMORY_PERIPHERAL}  ${write_access_type}  0x0  ${TEST_DATA}  4
        FOR  ${read_access_type}  IN  @{access_types}
            Should Peripheral Contain       ${MEMORY_PERIPHERAL}  ${read_access_type}  0x0  ${TEST_DATA}  4
        END
    END

Test Return Zero On Invalid QuadWord Access
    Execute Command                 ${MEMORY_PERIPHERAL} WriteQuadWord 0x0 0xffffffffffffffff
    Should Peripheral Contain       ${MEMORY_PERIPHERAL}  QuadWord  0x0  0000000000000000

Test Trivial Access
    Write To Peripheral             ${MEMORY_PERIPHERAL}  DoubleWord  0x0  ${TEST_DATA}  4
    Should Peripheral Contain       ${MEMORY_PERIPHERAL}  DoubleWord  0x0  ${TEST_DATA}  4

Should Connect, Read And Write
    [Arguments]                     ${peripheral}  ${run_simulation_keyword}
    Create Machine
    Connect To Simulation           ${peripheral}  ${run_simulation_keyword}

    Start Emulation
    Test Read And Write Memory

Should Return Zero on Invalid Access
    [Arguments]                     ${peripheral}  ${run_simulation_keyword}
    Create Machine
    Connect To Simulation           ${peripheral}  ${run_simulation_keyword}

    Start Emulation
    Test Return Zero On Invalid QuadWord Access
    Test Trivial Access

*** Test Cases ***
Should Connect Verilator
    [Tags]                          verilator
    Should Connect To Simulation And Reset Peripheral  ${MEMORY_PERIPHERAL}  Create Machine  Run Verilator

Should Connect Questa
    [Tags]                          questa
    Should Connect To Simulation And Reset Peripheral  ${MEMORY_PERIPHERAL}  Create Machine  Run Questa

Should Connect VCS
    [Tags]                          vcs
    Should Connect To Simulation And Reset Peripheral  ${MEMORY_PERIPHERAL}  Create Machine  Run VCS

Should Read And Write Memory In Verilator
    [Tags]                          verilator
    Should Connect, Read And Write  ${MEMORY_PERIPHERAL}  Run Verilator

Should Read And Write Memory In Questa
    [Tags]                          questa
    Should Connect, Read And Write  ${MEMORY_PERIPHERAL}  Run Questa

Should Read And Write Memory In VCS
    [Tags]                          vcs
    Should Connect, Read And Write  ${MEMORY_PERIPHERAL}  Run VCS

Should Return Zero on Invalid Access In Verilator
    [Tags]                          verilator
    Should Return Zero on Invalid Access  ${MEMORY_PERIPHERAL}  Run Verilator

Should Return Zero on Invalid Access In Questa
    [Tags]                          questa
    Should Return Zero on Invalid Access  ${MEMORY_PERIPHERAL}  Run Questa

Should Return Zero on Invalid Access In VCS
    [Tags]                          vcs
    Should Return Zero on Invalid Access  ${MEMORY_PERIPHERAL}  Run VCS
