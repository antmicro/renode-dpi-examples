*** Settings ***
Resource                            ${CURDIR}/../../robot/dpi-keywords.robot
Resource                            ${CURDIR}/../../robot/access-peripheral-keywords.robot
Test Teardown                       Run Keywords
...                                 Test Teardown
...                                 Terminate And Log

*** Variables ***
${BUS_WIDTH}                        64
${MEMORY_PERIPHERAL}                mem
${TEST_DATA}                        12345678CAFEBABE000000005A5A5A5A

${DPI_PLATFORM}                     ${CURDIR}/platform.resc
${BUILD_DIRECTORY}                  ${CURDIR}/build
${VERILATED_BINARY}                 ${BUILD_DIRECTORY}/verilated
${QUESTA_WORK_LIBRARY}              ${BUILD_DIRECTORY}/work_questa


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


*** Test Cases ***
Should Connect Verilator
    [Tags]                          verilator
    Should Connect To Verilator And Reset Peripheral  ${MEMORY_PERIPHERAL}  ${VERILATED_BINARY}  Create Machine

Should Connect Questa
    [Tags]                          questa
    Should Connect To Questa And Reset Peripheral  ${MEMORY_PERIPHERAL}  ${QUESTA_WORK_LIBRARY}  Create Machine

Should Read And Write Memory In Verilator
    [Tags]                          verilator
    Create Machine
    Connect To Verilator            ${MEMORY_PERIPHERAL}  ${VERILATED_BINARY}

    Start Emulation
    Test Read And Write Memory

Should Read And Write Memory In Questa
    [Tags]                          questa
    Create Machine
    Connect To Questa               ${MEMORY_PERIPHERAL}  ${QUESTA_WORK_LIBRARY}

    Start Emulation
    Test Read And Write Memory
