*** Settings ***
Test Teardown                       Run Keywords
...                                     Test Teardown
...                                     Terminate And Log
Resource                            ${CURDIR}/../../robot/dpi-keywords.robot
Resource                            ${CURDIR}/../../robot/access-peripheral-keywords.robot

*** Variables ***
${DUT}                              mem
${TEST_DATA}                        12345678CAFEBABE5A5A5A5ADEADBEEF
${TEST_DATA_32BIT_TRUNCATED}        1234567800000000

${DPI_PLATFORM}                     ${CURDIR}/platform.resc
${BUILD_DIRECTORY}                  ${CURDIR}/build

*** Keywords ***
Create Machine
    Execute Command                 include @${DPI_PLATFORM}

Memory Should Contain
    [Arguments]                     ${addr}  ${val}
    ${res}=                         Execute Command  ${DUT} ReadDoubleWord ${addr}
    Should Contain                  ${res}  ${val}

Test Read And Write Memory
    Write To Peripheral             ${DUT}  QuadWord  0x0  ${TEST_DATA}
    # The APB3 bus data width in the example is 32-bits. The platform specifies
    # maxWidth as 64, so there must be no error, but the result must be
    # truncated to the APB3 bus data width
    Should Peripheral Contain       ${DUT}  QuadWord  0x0  ${TEST_DATA_32BIT_TRUNCATED}
    Write To Peripheral             ${DUT}  DoubleWord  0x0  ${TEST_DATA}
    Should Peripheral Contain       ${DUT}  DoubleWord  0x0  ${TEST_DATA}
    Write To Peripheral             ${DUT}  Word  0x0  ${TEST_DATA}
    Should Peripheral Contain       ${DUT}  Word  0x0  ${TEST_DATA}
    Write To Peripheral             ${DUT}  Byte  0x0  ${TEST_DATA}
    Should Peripheral Contain       ${DUT}  Byte  0x0  ${TEST_DATA}

Should Connect, Read And Write
    [Arguments]                     ${peripheral}  ${run_simulation_keyword}
    Create Machine
    Connect To Simulation           ${peripheral}  ${run_simulation_keyword}

    Start Emulation
    Test Read And Write Memory

*** Test Cases ***
Should Connect Verilator
    [Tags]                          verilator
    Should Connect To Simulation And Reset Peripheral  ${DUT}  Create Machine  Run Verilator

Should Connect Questa
    [Tags]                          questa
    Should Connect To Simulation And Reset Peripheral  ${DUT}  Create Machine  Run Questa


Should Read And Write Memory In Verilator
    [Tags]                          verilator
    Should Connect, Read And Write  ${DUT}  Run Verilator

Should Read And Write Memory In Questa
    [Tags]                          questa
    Should Connect, Read And Write  ${DUT}  Run Questa

