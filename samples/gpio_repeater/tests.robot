*** Settings ***
Test Teardown                       Run Keywords
...                                 Test Teardown
...                                 Terminate And Log
Resource                            ${CURDIR}/../../robot/dpi-keywords.robot
Resource                            ${CURDIR}/../../robot/access-peripheral-keywords.robot

*** Variables ***
${REPEATER_PERIPHERAL}              repeater
${BUTTON_PERIPHERAL0}               sysbus.button0
${LED_PERIPHERAL0}                  sysbus.led0
${BUTTON_PERIPHERAL1}               sysbus.button1
${LED_PERIPHERAL1}                  sysbus.led1

${DPI_PLATFORM}                     ${CURDIR}/platform.resc
${BUILD_DIRECTORY}                  ${CURDIR}/build

*** Keywords ***
Create Machine
    Execute Command                 include @${DPI_PLATFORM}

One LED Should Blink After Pressing Button While The Other Stays Off
    [Arguments]                     ${led0}  ${led1}  ${button}
    Assert LED State                false  testerId=${led0}
    Assert LED State                false  testerId=${led1}
    Execute Command                 ${button} Press
    Assert LED State                true  testerId=${led0}
    Assert LED State                false  testerId=${led1}
    Execute Command                 ${button} Release
    Assert LED State                false  testerId=${led0}
    Assert LED State                false  testerId=${led1}

Should Repeat GPIO Signal
    [Arguments]                     ${peripheral}  ${run_simulation_keyword}
    Create Machine
    Connect To Simulation           ${peripheral}  ${run_simulation_keyword}

    ${led0}=                        Create LED Tester  ${LED_PERIPHERAL0}  defaultTimeout=1
    ${led1}=                        Create LED Tester  ${LED_PERIPHERAL1}  defaultTimeout=1

    Start Emulation

    One LED Should Blink After Pressing Button While The Other Stays Off  ${led0}  ${led1}  ${BUTTON_PERIPHERAL0}
    One LED Should Blink After Pressing Button While The Other Stays Off  ${led1}  ${led0}  ${BUTTON_PERIPHERAL1}

*** Test Cases ***
Should Connect Verilator
    [Tags]                          verilator
    Should Connect To Simulation And Reset Peripheral  ${REPEATER_PERIPHERAL}  Create Machine  Run Verilator

Should Connect Questa
    [Tags]                          questa
    Should Connect To Simulation And Reset Peripheral  ${REPEATER_PERIPHERAL}  Create Machine  Run Questa

Should Repeat GPIO Signal In Verilator
    [Tags]                          verilator
    Should Repeat GPIO Signal       ${REPEATER_PERIPHERAL}  Run Verilator 

Should Repeat GPIO Signal In Questa
    [Tags]                          questa
    Should Repeat GPIO Signal       ${REPEATER_PERIPHERAL}  Run Questa

