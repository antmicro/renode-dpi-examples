*** Settings ***
Resource                            ${CURDIR}/../../robot/dpi.robot
Test Teardown                       Run Keywords
...                                 Test Teardown
...                                 Terminate And Log


*** Variables ***
${BASIC_PLATFORM}                   ${CURDIR}/platform_basic.resc
${BUILD_DIRECTORY}                  ${CURDIR}/build
${VERILATED_BINARY}                 ${BUILD_DIRECTORY}/verilated
${QUESTA_WORK_LIBRARY}              ${BUILD_DIRECTORY}/work_questa


*** Keywords ***
Create Machine
    Execute Command                 include @${BASIC_PLATFORM}

Transaction Should Finish
    ${val}=                         Execute Command  dma ReadDoubleWord 0x4
    Should Contain                  ${val}  0x00000000

Configure DMA
    [Arguments]                     ${src}  ${dst}
    # Reader start address
    Execute Command                 dma WriteDoubleWord 0x10 ${src}
    # Reader line length in 32-bit words
    Execute Command                 dma WriteDoubleWord 0x14 1024
    # Number of lines to read
    Execute Command                 dma WriteDoubleWord 0x18 1
    # Stride size between consecutive lines in 32-bit words
    Execute Command                 dma WriteDoubleWord 0x1c 0

    # Writer start address
    Execute Command                 dma WriteDoubleWord 0x20 ${dst}
    # Writer line length in 32-bit words
    Execute Command                 dma WriteDoubleWord 0x24 1024
    # Number of lines to write
    Execute Command                 dma WriteDoubleWord 0x28 1
    # Stride size between consecutive lines in 32-bit words
    Execute Command                 dma WriteDoubleWord 0x2c 0

Start DMA Transaction
    # Do not wait fo external synchronization signal
    Execute Command                 dma WriteDoubleWord 0x00 0x0f

Memory Should Contain
    [Arguments]                     ${addr}  ${val}
    ${res}=                         Execute Command  mem ReadDoubleWord ${addr}
    Should Contain                  ${res}  ${val}

Test DMA Transaction
    Execute Command                 mem WriteDoubleWord 0x80000 0x12345678
    Execute Command                 mem WriteDoubleWord 0x80004 0xCAFEBABE
    Execute Command                 mem WriteDoubleWord 0x80008 0x5A5A5A5A
    Execute Command                 mem WriteDoubleWord 0x80400 0xDEADBEEF

    Memory Should Contain           0x0  0x00000000

    Configure DMA                   0x20080000  0x20000000
    Start DMA Transaction

    Execute Command                 emulation RunFor "00:00:0.1"

    Transaction Should Finish

    Memory Should Contain           0x0  0x12345678
    Memory Should Contain           0x4  0xCAFEBABE
    Memory Should Contain           0x8  0x5A5A5A5A
    Memory Should Contain           0xC  0x00000000
    Memory Should Contain           0x3FC  0x00000000
    Memory Should Contain           0x400  0xDEADBEEF
    Memory Should Contain           0x404  0x00000000

Test DMA Interrupt
    Configure DMA                   0x20080000  0x20000000
    # Enable interrupts
    Execute Command                 dma WriteDoubleWord 0x08 0x3
    Start DMA Transaction

    Execute Command                 emulation RunFor "00:00:0.1"

    Transaction Should Finish
    Wait For Log Entry              plic: Setting GPIO number #2 to value True  timeout=0
    Wait For Log Entry              plic: Setting GPIO number #1 to value True  timeout=0

    # Clean the interrupt
    Execute Command                 dma WriteDoubleWord 0x0C 0x01
    Execute Command                 emulation RunFor "00:00:0.1"
    Wait For Log Entry              plic: Setting GPIO number #1 to value False  timeout=0

    # Clean the another interrupt
    Execute Command                 dma WriteDoubleWord 0x0C 0x02
    Execute Command                 emulation RunFor "00:00:0.1"
    Wait For Log Entry              plic: Setting GPIO number #2 to value False  timeout=0


*** Test Cases ***
Should Connect Verilator
    [Tags]                          verilator
    Create Log Tester               0
    Execute Command                 logLevel 0
    Create Machine
    Connect Verilator               dma  ${VERILATED_BINARY}

    Wait For Log Entry              dma: Connected
    Execute Command                 dma Reset

Should Connect Questa
    [Tags]                          questa
    Create Log Tester               0
    Execute Command                 logLevel 0
    Create Machine
    Connect Questa                  dma  ${QUESTA_WORK_LIBRARY}

    Wait For Log Entry              dma: Connected
    Execute Command                 dma Reset

Should Run DMA Transaction In Verilator
    [Tags]                          verilator
    Create Machine
    Connect Verilator               dma  ${VERILATED_BINARY}
    Test DMA Transaction

Should Run DMA Transaction In Questa
    [Tags]                          questa
    Create Machine
    Connect Questa                  dma  ${QUESTA_WORK_LIBRARY}
    Test DMA Transaction

Should Trigger DMA Interrupt In Verilator
    [Tags]                          verilator
    Create Log Tester               0
    Create Machine
    Execute Command                 logLevel -1 plic
    Connect Verilator               dma  ${VERILATED_BINARY}

    Test DMA Interrupt

Should Trigger DMA Interrupt In Questa
    [Tags]                          questa
    Create Log Tester               0
    Create Machine
    Execute Command                 logLevel -1 plic
    Connect Questa                  dma  ${QUESTA_WORK_LIBRARY}

    Test DMA Interrupt
