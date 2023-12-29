*** Settings ***
Test Teardown                       Run Keywords
...                                     Test Teardown
...                                     Terminate And Log
Resource                            ${CURDIR}/../../robot/dpi-keywords.robot
Resource                            ${CURDIR}/../../robot/access-peripheral-keywords.robot

*** Variables ***
${BUS_WIDTH}                        32
${DMA_PERIPHERAL}                   dma
${PLIC_PERIPHERAL}                  plic

${TEST_DATA}                        12345678CAFEBABEDEADBEEF5A5A5A5A
${TEST_BYTE}                        A5

${REGISTER_NAME0}                   0x00
${REGISTER_NAME1}                   0x04
${REGISTER_CONTROL}                 0x30
${REGISTER_NUM}                     0x40
${REGISTER_SOURCE}                  0x44
${REGISTER_DESTINATION}             0x48

${PLATFORM}                         ${CURDIR}/platform.resc
${BUILD_DIRECTORY}                  ${CURDIR}/build
${VERILATED_BINARY}                 ${BUILD_DIRECTORY}/verilated
${QUESTA_WORK_LIBRARY}              ${BUILD_DIRECTORY}/work_questa

*** Keywords ***
Create Machine
    Execute Command                 include @${PLATFORM}

Configure Transaction
    [Arguments]                     ${source_address}  ${destination_address}

    Execute Command                 ${DMA_PERIPHERAL} WriteDoubleWord ${REGISTER_SOURCE} ${source_address}
    Execute Command                 ${DMA_PERIPHERAL} WriteDoubleWord ${REGISTER_DESTINATION} ${destination_address}

    # Enable DMA and interrupt
    Execute Command                 ${DMA_PERIPHERAL} WriteDoubleWord ${REGISTER_CONTROL} ${{ (1 << 31) | (1 << 0) }}

Start Transaction
    [Arguments]                     ${transaction_count}

    # Start transaction, set burst length and number of bytes to move
    Execute Command                 ${DMA_PERIPHERAL} WriteDoubleWord ${REGISTER_NUM} ${{ (1 << 31) | (0x4 << 16) | (int(${transaction_count}) * 4) }}

Get And Clear Interrupt Flag
    ${control}=                     Execute Command  ${DMA_PERIPHERAL} ReadDoubleWord ${REGISTER_CONTROL}
    ${flag}=                        Evaluate  bool(int(${control}) & (0b1 << 1))
    Execute Command                 ${DMA_PERIPHERAL} WriteDoubleWord ${REGISTER_CONTROL} ${control}
    RETURN                          ${flag}

Should Identify Peripheral
    Should Peripheral Contain       ${DMA_PERIPHERAL}  DoubleWord  ${REGISTER_NAME0}  ${{ "DMA "[::-1].encode().hex() }}
    Should Peripheral Contain       ${DMA_PERIPHERAL}  DoubleWord  ${REGISTER_NAME1}  ${{ "AHB "[::-1].encode().hex() }}

Should Not Be Busy
    ${num}=                         Execute Command  ${DMA_PERIPHERAL} ReadDoubleWord ${REGISTER_NUM}
    Should Not Be True              ${{ bool(int(${num}) & (0b111 << 29)) }}

Should Interrupt Has Value
    [Arguments]                     ${expected}
    # The keyword clears interrupt too.
    Wait For Log Entry              ${PLIC_PERIPHERAL}: Setting GPIO number #1 to value ${expected}  timeout=0
    ${flag}=                        Get And Clear Interrupt Flag
    Should Be True                  ${{ $flag == bool(${expected}) }}

Should Make Transaction
    [Arguments]                     ${source}  ${destination}  ${length}
    Should Not Be Busy

    ${last_byte_offset}=            Set Variable  ${{ int(${BUS_WIDTH}) // 8 * int(${length}) - 1 }}
    Write To Peripheral             sysbus  DoubleWord  ${source}  ${TEST_DATA}
    Write To Peripheral             sysbus  Byte  ${{ hex(int(${source}) + $last_byte_offset) }}  ${TEST_BYTE}

    Configure Transaction           ${source}  ${destination}
    Start Transaction               ${length}

    Execute Command                 emulation RunFor "0.1"
    Should Not Be Busy

    Should Peripheral Contain       sysbus  DoubleWord  ${destination}  ${TEST_DATA}
    ${destination_last_byte}=       Evaluate  int(${destination}) + $last_byte_offset
    Should Peripheral Contain       sysbus  Byte  ${{ hex($destination_last_byte - 1) }}  00
    Should Peripheral Contain       sysbus  Byte  ${{ hex($destination_last_byte) }}  ${TEST_BYTE}
    Should Peripheral Contain       sysbus  Byte  ${{ hex($destination_last_byte + 1) }}  00

Test DMA
    Execute Command                 logLevel -1 ${PLIC_PERIPHERAL}
    Should Identify Peripheral
    Should Make Transaction         0x20080000  0x20000000  1024

    Should Interrupt Has Value      True
    Execute Command                 emulation RunFor "0.1"
    Should Interrupt Has Value      False

*** Test Cases ***
Should Connect Verilator
    [Tags]                          verilator
    Should Connect To Verilator And Reset Peripheral  ${DMA_PERIPHERAL}  ${VERILATED_BINARY}  Create Machine

Should Connect Questa
    [Tags]                          questa
    Should Connect To Questa And Reset Peripheral  ${DMA_PERIPHERAL}  ${QUESTA_WORK_LIBRARY}  Create Machine

Should Run DMA In Verilator
    [Tags]                          verilator
    Create Machine
    Connect To Verilator            ${DMA_PERIPHERAL}  ${VERILATED_BINARY}

    Test DMA

Should Run DMA In Questa
    [Tags]                          questa
    Create Machine
    Connect To Questa               ${DMA_PERIPHERAL}  ${QUESTA_WORK_LIBRARY}

    Test DMA
