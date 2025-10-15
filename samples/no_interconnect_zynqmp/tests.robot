*** Settings ***
Resource                            ${CURDIR}/../../robot/dpi-keywords.robot
Resource                            ${CURDIR}/../../robot/access-peripheral-keywords.robot
Test Teardown                       Run Keywords
...                                 Test Teardown
...                                 Terminate And Log

*** Variables ***
${BUS_WIDTH}                        64
${DMA_BUS_WIDTH}                    32
${PERIPHERAL0}                      peripheral0
${PERIPHERAL1}                      peripheral1
${DMA_PERIPHERAL}                   dma
${MEM_PERIPHERAL}                   mem
${INT_PERIPHERAL}                   apuGic
${MEM_ADDR}                         0x80001000
${PERIPHERAL0_ADDR}                 0x80100000
${PERIPHERAL1_ADDR}                 0x80300000
${ADDRESS_SOURCE}                   ${PERIPHERAL1_ADDR}
${ADDRESS_DESTINATION}              ${{ hex(int(${MEM_ADDR}) + 0x1000) }}
${TEST_DATA_PERIPHERAL_INIT}        00000000000000000000000000000000
${TEST_DATA_PERIPHERAL0}            12345678CAFEBABE000000005A5A5A5A
${TEST_DATA_PERIPHERAL1}            AA11BB22CC33DD44EE55FF6600771188
${TEST_DATA_DMA}                    12345678CAFEBABEDEADBEEF5A5A5A5A
${TEST_BYTE_DMA}                    A5
${TRANSACTION_LENGTH}               256

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

Test Write To Renode Memory
    # Must run long enough for writes to complete, Start Emulation isn't enough for complex platforms
    Execute Command                 emulation RunFor "0.001"
    # The values below are hardcoded in the HDL model of the Manager.
    Should Peripheral Contain       ${MEM_PERIPHERAL}  Byte  0x0  12
    Should Peripheral Contain       ${MEM_PERIPHERAL}  Word  0x4  5634
    Should Peripheral Contain       ${MEM_PERIPHERAL}  DoubleWord  0x8  DEBC9A78

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
    # Reader length in number of 32-bit words
    Execute Command                 ${DMA_PERIPHERAL} WriteDoubleWord 0x14 ${transaction_length}
    # Number of lines to read
    Execute Command                 ${DMA_PERIPHERAL} WriteDoubleWord 0x18 1
    # Stride size between consecutive lines in 32-bit words
    Execute Command                 ${DMA_PERIPHERAL} WriteDoubleWord 0x1c 0

    # Writer start address
    Execute Command                 ${DMA_PERIPHERAL} WriteDoubleWord 0x20 ${destination_address}
    # Write length in number of 32-bit words
    Execute Command                 ${DMA_PERIPHERAL} WriteDoubleWord 0x24 ${transaction_length}
    # Number of lines to write
    Execute Command                 ${DMA_PERIPHERAL} WriteDoubleWord 0x28 1
    # Stride size between consecutive lines in 32-bit words
    Execute Command                 ${DMA_PERIPHERAL} WriteDoubleWord 0x2c 0

Start DMA Transaction
    # Do not wait for external synchronization signal
    Execute Command                 ${DMA_PERIPHERAL} WriteDoubleWord 0x00 0x0f

Test DMA Transaction
    [Arguments]                     ${address_source}=${ADDRESS_SOURCE}  ${address_destination}=${ADDRESS_DESTINATION}  ${skip_asserts}=false
    ${last_byte_offset}=            Set Variable  ${{ int(${DMA_BUS_WIDTH}) // 8 * int(${TRANSACTION_LENGTH}) - 1 }}
    Write To Peripheral             sysbus  DoubleWord  ${address_source}  ${TEST_DATA_DMA}
    Write To Peripheral             sysbus  Byte  ${{ hex(int(${address_source}) + $last_byte_offset) }}  ${TEST_BYTE_DMA}

    Configure DMA                   ${address_source}  ${address_destination}  ${TRANSACTION_LENGTH}
    Start DMA Transaction

    Execute Command                 emulation RunFor "0.001"

    IF  '${skip_asserts}' == 'false'
        Transaction Should Finish

        Should Peripheral Contain       sysbus  DoubleWord  ${address_destination}  ${TEST_DATA_DMA}
        ${destination_last_byte}=       Evaluate  int(${address_destination}) + $last_byte_offset
        Should Peripheral Contain       sysbus  Byte  ${{ hex($destination_last_byte - 1) }}  00
        Should Peripheral Contain       sysbus  Byte  ${{ hex($destination_last_byte) }}  ${TEST_BYTE_DMA}
        Should Peripheral Contain       sysbus  Byte  ${{ hex($destination_last_byte + 1) }}  00
    END

Test DMA Interrupt
    Create Log Tester               0
    Execute Command                 logLevel -1 ${INT_PERIPHERAL}

    Configure DMA                   ${ADDRESS_SOURCE}  ${ADDRESS_DESTINATION}  ${TRANSACTION_LENGTH}
    # Enable interrupts
    Execute Command                 ${DMA_PERIPHERAL} WriteDoubleWord 0x08 0x3
    Start DMA Transaction

    Execute Command                 emulation RunFor "0.001"

    Transaction Should Finish
    Wait For Log Entry              ${INT_PERIPHERAL}: Setting Shared Peripheral Interrupt #98 signal to True  timeout=0
    Wait For Log Entry              ${INT_PERIPHERAL}: Setting Shared Peripheral Interrupt #97 signal to True  timeout=0

    # Clean the interrupt
    Execute Command                 ${DMA_PERIPHERAL} WriteDoubleWord 0x0C 0x01
    Execute Command                 emulation RunFor "0.001"
    Wait For Log Entry              ${INT_PERIPHERAL}: Setting Shared Peripheral Interrupt #97 signal to False  timeout=0

    # Clean the another interrupt
    Execute Command                 ${DMA_PERIPHERAL} WriteDoubleWord 0x0C 0x02
    Execute Command                 emulation RunFor "0.001"
    Wait For Log Entry              ${INT_PERIPHERAL}: Setting Shared Peripheral Interrupt #98 signal to False  timeout=0

Should Not Crash On Unaligned Access
    # Test manager accesses
    Execute Command                 ${DMA_PERIPHERAL} WriteDoubleWord 0x1 0xffffffff
    Execute Command                 ${DMA_PERIPHERAL} ReadDoubleWord 0x1
    # Test subordinate accesses
    Test DMA Transaction            ${${ADDRESS_SOURCE} + 1}  ${${ADDRESS_DESTINATION} + 1}  true

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

Should Write To Renode Memory In Verilator
    [Tags]                          verilator
    Create Machine
    Connect To Simulation           ${CONNECTION}  Run Verilator

    Test Write To Renode Memory

Should Write To Renode Memory In Questa
    [Tags]                          questa
    Create Machine
    Connect To Simulation           ${CONNECTION}  Run Questa

    Test Write To Renode Memory

Should Write To Renode Memory In VCS
    [Tags]                          vcs
    Create Machine
    Connect To Simulation           ${CONNECTION}  Run VCS

    Test Write To Renode Memory

Should Write DMA Registers In Verilator
    [Tags]                          verilator
    Create Machine
    Connect To Simulation           ${CONNECTION}  Run Verilator

    Make Repeated DMA Writes

Should Write DMA Registers In Questa
    [Tags]                          questa
    Create Machine
    Connect To Simulation           ${CONNECTION}  Run Questa

    Make Repeated DMA Writes

Should Write DMA Registers In VCS
    [Tags]                          vcs
    Create Machine
    Connect To Simulation           ${CONNECTION}  Run VCS

    Make Repeated DMA Writes

Should Run DMA Transaction In Verilator
    [Tags]                          verilator
    Create Machine
    Connect To Simulation           ${CONNECTION}  Run Verilator

    Test DMA Transaction

Should Run DMA Transaction In Questa
    [Tags]                          questa
    Create Machine
    Connect To Simulation           ${CONNECTION}  Run Questa

    Test DMA Transaction

Should Run DMA Transaction In VCS
    [Tags]                          vcs
    Create Machine
    Connect To Simulation           ${CONNECTION}  Run VCS

    Test DMA Transaction

Should Trigger DMA Interrupt In Verilator
    [Tags]                          verilator
    Create Machine
    Connect To Simulation           ${CONNECTION}  Run Verilator

    Test DMA Interrupt

Should Trigger DMA Interrupt In Questa
    [Tags]                          questa
    Create Machine
    Connect To Simulation           ${CONNECTION}  Run Questa

    Test DMA Interrupt

Should Trigger DMA Interrupt In VCS
    [Tags]                          vcs
    Create Machine
    Connect To Simulation           ${CONNECTION}  Run VCS

    Test DMA Interrupt

Should Not Crash On Unaligned Access In Verilator
    [Tags]                          verilator
    Create Machine
    Connect To Simulation           ${CONNECTION}  Run Verilator

    Should Not Crash On Unaligned Access

Should Not Crash On Unaligned Access In Questa
    [Tags]                          questa
    Create Machine
    Connect To Simulation           ${CONNECTION}  Run Questa

    Should Not Crash On Unaligned Access

Should Not Crash On Unaligned Access In VCS
    [Tags]                          vcs
    Create Machine
    Connect To Simulation           ${CONNECTION}  Run VCS

    Should Not Crash On Unaligned Access
