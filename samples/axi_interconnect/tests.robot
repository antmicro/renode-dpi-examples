*** Settings ***
Resource                            ${CURDIR}/../../robot/dpi-keywords.robot
Resource                            ${CURDIR}/../../robot/access-peripheral-keywords.robot
Test Teardown                       Run Keywords
...                                 Test Teardown
...                                 Terminate And Log

*** Variables ***
${BUS_WIDTH}                        64
${VERILATOR_CONNECTION}             verilator_connection
${PERIPHERAL0}                      peripheral0
${PERIPHERAL1}                      peripheral1
${PERIPHERAL0_ADDR}                 0x100000
${PERIPHERAL1_ADDR}                 0x300000
${TEST_DATA_PERIPHERAL_INIT}        00000000000000000000000000000000
${TEST_DATA_PERIPHERAL0}            12345678CAFEBABE000000005A5A5A5A
${TEST_DATA_PERIPHERAL1}            AA11BB22CC33DD44EE55FF6600771188
${RW_ADDRESS}                       0x110

${DPI_PLATFORM}                     ${CURDIR}/platform.resc
${CONNECTION}                       host.my_connection


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

    FOR  ${read_access_type}  IN  @{all_access_types}
        Should Peripheral Contain       sysbus  ${read_access_type}  ${PERIPHERAL0_ADDR}  ${TEST_DATA_PERIPHERAL_INIT}
    END

    FOR  ${write_access_type}  IN  @{all_access_types}
        Write To Peripheral             sysbus  ${write_access_type}  ${PERIPHERAL0_ADDR}  ${TEST_DATA_PERIPHERAL0}
        FOR  ${read_access_type}  IN  @{all_access_types}
            Should Peripheral Contain       sysbus  ${read_access_type}  ${PERIPHERAL0_ADDR}  ${TEST_DATA_PERIPHERAL0}
        END
    END

    FOR  ${read_access_type}  IN  @{all_access_types}
        Should Peripheral Contain       sysbus  ${read_access_type}  ${PERIPHERAL1_ADDR}  ${TEST_DATA_PERIPHERAL_INIT}
    END

    FOR  ${write_access_type}  IN  @{all_access_types}
        Write To Peripheral             sysbus  ${write_access_type}  ${PERIPHERAL1_ADDR}  ${TEST_DATA_PERIPHERAL1}
        FOR  ${read_access_type}  IN  @{all_access_types}
            Should Peripheral Contain       sysbus  ${read_access_type}  ${PERIPHERAL1_ADDR}  ${TEST_DATA_PERIPHERAL1}
        END
    END

    FOR  ${read_access_type}  IN  @{all_access_types}
        Should Peripheral Contain       sysbus  ${read_access_type}  ${PERIPHERAL0_ADDR}  ${TEST_DATA_PERIPHERAL0}
    END

    FOR  ${read_access_type}  IN  @{all_access_types}
        Should Peripheral Contain       sysbus  ${read_access_type}  ${PERIPHERAL1_ADDR}  ${TEST_DATA_PERIPHERAL1}
    END

Check LEDs
    [Arguments]  ${all_leds}  ${triggered_led}

    FOR  ${led}  IN  @{all_leds}
        ${state}=           Evaluate  '${led}' == '${triggered_led}'
        Assert LED State            ${state}  testerId=${led}
    END

Test GPIO Dispatch
    ${led0}=                    Create LED Tester  sysbus.led0  defaultTimeout=0.2
    ${led1}=                    Create LED Tester  sysbus.led1  defaultTimeout=0.2
    ${led2}=                    Create LED Tester  sysbus.led2  defaultTimeout=0.2
    ${led3}=                    Create LED Tester  sysbus.led3  defaultTimeout=0.2
    ${led4}=                    Create LED Tester  sysbus.led4  defaultTimeout=0.2

    ${leds}=                    Create List  ${led0}  ${led1}  ${led2}  ${led3}  ${led4}

    FOR  ${triggered_led}  IN  @{leds}
        Execute Command             button PressAndRelease
        Check LEDs                  ${leds}  ${triggered_led}
    END

*** Test Cases ***
Should Connect Verilator
    [Tags]                          verilator
    Should Connect To Simulation And Reset Peripheral  ${CONNECTION}  Create Machine  Run Verilator

Should Connect Questa
    [Tags]                          questa
    Should Connect To Simulation And Reset Peripheral  ${CONNECTION}  Create Machine  Run Questa

Should Connect VCS
    [Tags]                          vcs
    Should Connect To Simulation And Reset Peripheral  ${CONNECTION}  Create Machine  Run VCS

Should Read And Write Memory In Verilator
    [Tags]                          verilator
    Create Machine
    Connect To Simulation           ${CONNECTION}  Run Verilator

    Test Read And Write Memory

Should Read And Write Memory In Questa
    [Tags]                          questa
    Create Machine
    Connect To Simulation           ${CONNECTION}  Run Questa

    Test Read And Write Memory

Should Read And Write Memory In VCS
    [Tags]                          vcs
    Create Machine
    Connect To Simulation           ${CONNECTION}  Run VCS

    Test Read And Write Memory

Should Dispatch GPIO In Verilator
    [Tags]                          verilator
    Create Machine
    Connect To Simulation           ${CONNECTION}  Run Verilator

    Test GPIO Dispatch

Should Dispatch GPIO In Questa
    [Tags]                          questa
    Create Machine
    Connect To Simulation           ${CONNECTION}  Run Questa

    Test GPIO Dispatch

Should Dispatch GPIO In VCS
    [Tags]                          vcs
    Create Machine
    Connect To Simulation           ${CONNECTION}  Run VCS

    Test GPIO Dispatch
