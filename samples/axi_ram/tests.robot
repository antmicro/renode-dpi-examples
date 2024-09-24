*** Settings ***
Test Teardown                       Run Keywords
...                                     Test Teardown
...                                     Terminate And Log
Resource                            ${CURDIR}/../../robot/dpi-keywords.robot
Resource                            ${CURDIR}/../../robot/access-peripheral-keywords.robot

*** Variables ***
${BUS_WIDTH}                        64
${MEMORY_PERIPHERAL}                mem
${TEST_DATA}                        12345678CAFEBABE000000005A5A5A5A

${DPI_PLATFORM}                     ${CURDIR}/platform.resc
${BUILD_DIRECTORY}                  ${CURDIR}/build

*** Keywords ***
Create Machine
    Execute Command                 include @${DPI_PLATFORM}

Test Read And Write Memory
    ${all_access_types}=            Create List  Byte
    IF  ${BUS_WIDTH} >= 16
        Append To List                  ${all_access_types}  Word
    END
    IF  ${BUS_WIDTH} >= 32
        Append To List                  ${all_access_types}  DoubleWord
    END
    IF  ${BUS_WIDTH} >= 64
        Append To List                  ${all_access_types}  QuadWord
    END

    FOR  ${write_access_type}  IN  @{all_access_types}
        Write To Peripheral             ${MEMORY_PERIPHERAL}  ${write_access_type}  0x0  ${TEST_DATA}
        FOR  ${read_access_type}  IN  @{all_access_types}
            Should Peripheral Contain       ${MEMORY_PERIPHERAL}  ${read_access_type}  0x0  ${TEST_DATA}
        END
    END

Should Connect, Read And Write
    [Arguments]                     ${peripheral}  ${run_simulation_keyword}
    Create Machine
    Connect To Simulation           ${peripheral}  ${run_simulation_keyword}

    Start Emulation
    Test Read And Write Memory

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
