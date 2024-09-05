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
${VERILATED_BINARY}                 ${BUILD_DIRECTORY}/verilated
${QUESTA_WORK_LIBRARY}              ${BUILD_DIRECTORY}/work_questa

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
