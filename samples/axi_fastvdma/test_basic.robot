*** Settings ***
Test Teardown                       Run Keywords
...                                     Test Teardown
...                                     Terminate And Log
Resource                            ${CURDIR}/../../robot/dpi-keywords.robot
Resource                            ${CURDIR}/../../robot/access-peripheral-keywords.robot

*** Variables ***
${BUS_WIDTH}                        32
${TRANSACTION_LENGTH}               1024
${DMA_PERIPHERAL}                   dma
${PLIC_PERIPHERAL}                  plic

${TEST_DATA}                        12345678CAFEBABEDEADBEEF5A5A5A5A
${TEST_BYTE}                        A5
${ADDRESS_SOURCE}                   0x20080000
${ADDRESS_DESTINATION}              0x20000000

${BASIC_PLATFORM}                   ${CURDIR}/platform_basic.resc
${BUILD_DIRECTORY}                  ${CURDIR}/build

*** Keywords ***
Create Machine
    Execute Command                 include @${BASIC_PLATFORM}

Transaction Should Finish
    ${val}=                         Execute Command  ${DMA_PERIPHERAL} ReadDoubleWord 0x4
    Should Contain                  ${val}  0x00000000

Make Repeated DMA Writes
    # The purpose of this keyword is to make sure a timeout isn't triggered.
    FOR  ${i}  IN RANGE  100
        Execute Command                 ${DMA_PERIPHERAL} WriteDoubleWord 0x0 0
    END

Configure DMA
    [Arguments]                     ${source_address}  ${destination_address}  ${transaction_length}
    # Reader start address
    Execute Command                 ${DMA_PERIPHERAL} WriteDoubleWord 0x10 ${source_address}
    # Reader length in bus widths
    Execute Command                 ${DMA_PERIPHERAL} WriteDoubleWord 0x14 ${transaction_length}
    # Number of lines to read
    Execute Command                 ${DMA_PERIPHERAL} WriteDoubleWord 0x18 1
    # Stride size between consecutive lines in 32-bit words
    Execute Command                 ${DMA_PERIPHERAL} WriteDoubleWord 0x1c 0

    # Writer start address
    Execute Command                 ${DMA_PERIPHERAL} WriteDoubleWord 0x20 ${destination_address}
    # Write length in bus widths
    Execute Command                 ${DMA_PERIPHERAL} WriteDoubleWord 0x24 ${transaction_length}
    # Number of lines to write
    Execute Command                 ${DMA_PERIPHERAL} WriteDoubleWord 0x28 1
    # Stride size between consecutive lines in 32-bit words
    Execute Command                 ${DMA_PERIPHERAL} WriteDoubleWord 0x2c 0

Start DMA Transaction
    # Do not wait fo external synchronization signal
    Execute Command                 ${DMA_PERIPHERAL} WriteDoubleWord 0x00 0x0f

Memory Should Contain
    [Arguments]                     ${address}  ${value}
    ${result}=                      Execute Command  mem ReadDoubleWord ${address}
    Should Contain                  ${result}  ${value}

Test DMA Transaction
    ${last_byte_offset}=            Set Variable  ${{ int(${BUS_WIDTH}) // 8 * int(${TRANSACTION_LENGTH}) - 1 }}
    Write To Peripheral             sysbus  DoubleWord  ${ADDRESS_SOURCE}  ${TEST_DATA}
    Write To Peripheral             sysbus  Byte  ${{ hex(int(${ADDRESS_SOURCE}) + $last_byte_offset) }}  ${TEST_BYTE}

    Configure DMA                   ${ADDRESS_SOURCE}  ${ADDRESS_DESTINATION}  ${TRANSACTION_LENGTH}
    Start DMA Transaction

    Execute Command                 emulation RunFor "0.1"

    Transaction Should Finish

    Should Peripheral Contain       sysbus  DoubleWord  ${ADDRESS_DESTINATION}  ${TEST_DATA}
    ${destination_last_byte}=       Evaluate  int(${ADDRESS_DESTINATION}) + $last_byte_offset
    Should Peripheral Contain       sysbus  Byte  ${{ hex($destination_last_byte - 1) }}  00
    Should Peripheral Contain       sysbus  Byte  ${{ hex($destination_last_byte) }}  ${TEST_BYTE}
    Should Peripheral Contain       sysbus  Byte  ${{ hex($destination_last_byte + 1) }}  00

Test DMA Interrupt
    Configure DMA                   ${ADDRESS_SOURCE}  ${ADDRESS_DESTINATION}  ${TRANSACTION_LENGTH}
    # Enable interrupts
    Execute Command                 ${DMA_PERIPHERAL} WriteDoubleWord 0x08 0x3
    Start DMA Transaction

    Execute Command                 emulation RunFor "0.1"

    Transaction Should Finish
    Wait For Log Entry              ${PLIC_PERIPHERAL}: Setting GPIO number #2 to value True  timeout=0
    Wait For Log Entry              ${PLIC_PERIPHERAL}: Setting GPIO number #1 to value True  timeout=0

    # Clean the interrupt
    Execute Command                 ${DMA_PERIPHERAL} WriteDoubleWord 0x0C 0x01
    Execute Command                 emulation RunFor "0.1"
    Wait For Log Entry              ${PLIC_PERIPHERAL}: Setting GPIO number #1 to value False  timeout=0

    # Clean the another interrupt
    Execute Command                 ${DMA_PERIPHERAL} WriteDoubleWord 0x0C 0x02
    Execute Command                 emulation RunFor "0.1"
    Wait For Log Entry              ${PLIC_PERIPHERAL}: Setting GPIO number #2 to value False  timeout=0

Should Write DMA Registers
    [Arguments]                     ${peripheral}  ${run_simulation_keyword}
    Create Machine
    Connect To Simulation           ${peripheral}  ${run_simulation_keyword}
    Make Repeated DMA Writes

Should Run DMA Transaction
    [Arguments]                     ${peripheral}  ${run_simulation_keyword}
    Create Machine
    Connect To Simulation           ${peripheral}  ${run_simulation_keyword}
    Test DMA Transaction

Should Trigger DMA Interrupt
    [Arguments]                     ${peripheral}  ${run_simulation_keyword}
    Create Log Tester               0
    Create Machine
    Execute Command                 logLevel -1 plic
    Connect To Simulation           ${peripheral}  ${run_simulation_keyword}

    Test DMA Interrupt

*** Test Cases ***
Should Connect Verilator
    [Tags]                          verilator
    Should Connect To Simulation And Reset Peripheral  ${DMA_PERIPHERAL}  Create Machine  Run Verilator

Should Connect Questa
    [Tags]                          questa
    Should Connect To Simulation And Reset Peripheral  ${DMA_PERIPHERAL}  Create Machine  Run Questa


Should Write DMA Registers In Verilator
    [Tags]                          verilator
    Should Write DMA Registers      ${DMA_PERIPHERAL}  Run Verilator

Should Write DMA Registers In Questa
    [Tags]                          questa
    Should Write DMA Registers      ${DMA_PERIPHERAL}  Run Questa


Should Run DMA Transaction In Verilator
    [Tags]                          verilator
    Should Run DMA Transaction      ${DMA_PERIPHERAL}  Run Verilator

Should Run DMA Transaction In Questa
    [Tags]                          questa
    Should Run DMA Transaction      ${DMA_PERIPHERAL}  Run Questa


Should Trigger DMA Interrupt In Verilator
    [Tags]                          verilator
    Should Trigger DMA Interrupt    ${DMA_PERIPHERAL}  Run Verilator

Should Trigger DMA Interrupt In Questa
    [Tags]                          questa
    Should Trigger DMA Interrupt    ${DMA_PERIPHERAL}  Run Questa

