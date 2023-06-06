*** Settings ***
Test Teardown                       Run Keywords
...                                 Test Teardown
...                                 Terminate And Log

*** Variables ***
${URI}                              https://dl.antmicro.com/projects/renode
${VFASTDMA_SOCKET_LINUX}            ${URI}/Vfastvdma-Linux-x86_64-1116123840-s_1616232-37fd8031dec810475ac6abf68a789261ce6551b0
${VFASTDMA_SOCKET_WINDOWS}          ${URI}/Vfastvdma-Windows-x86_64-1116123840.exe-s_14833257-3a1fef7953686e58a00b09870c5a57e3ac91621d
${VERILATED_BINARY}                 ${CURDIR}/build/verilated
${QUESTA_COMMAND}                   vsim
${QUESTA_WORK_LIBRARY}              ${CURDIR}/build/work_questa
${QUESTA_DESIGN}                    design_optimized
${QUESTA_ARGUMENTS}                 ${EMPTY}


*** Keywords ***
Create Machine
    Execute Command                 using sysbus
    Execute Command                 mach create
    Execute Command                 machine LoadPlatformDescriptionFromString 'cpu: CPU.RiscV32 @ sysbus { cpuType: "rv32imaf"; timeProvider: empty }'
    Execute Command                 machine LoadPlatformDescriptionFromString 'dma: Verilated.BaseDoubleWordVerilatedPeripheral @ sysbus <0x10000000, +0x100> { frequency: 100000; limitBuffer: 100000; timeout: 10000; address: "127.0.0.1" }'
    Execute Command                 machine LoadPlatformDescriptionFromString 'mem: Verilated.BaseDoubleWordVerilatedPeripheral @ sysbus <0x20000000, +0x100000> { frequency: 10; limitBuffer: 10000000; timeout: 10000; address: "127.0.0.1" }'
    Execute Command                 machine LoadPlatformDescriptionFromString 'ram: Memory.MappedMemory @ sysbus 0xA0000000 { size: 0x06400000 }'
    Execute Command                 sysbus WriteDoubleWord 0xA2000000 0x10500073  # wfi
    Execute Command                 cpu PC 0xA2000000
    Execute Command                 dma SimulationFilePathLinux @${VFASTDMA_SOCKET_LINUX}
    Execute Command                 dma SimulationFilePathWindows @${VFASTDMA_SOCKET_WINDOWS}

Connect Verilator
    ${connectionParameters}=        Execute Command  mem ConnectionParameters
    ${simulationArguments}=         Split String  ${connectionParameters}
    ${logFile}=                     Allocate Temporary File
    Start Process                   ${VERILATED_BINARY}  @{simulationArguments}  stdout=${logFile}
    Execute Command                 mem Connect

Connect Questa
    ${connectionParameters}=        Execute Command  mem ConnectionParameters
    ${connectionArguments}=         Split String  ${connectionParameters}
    ${simulationArguments}=         Split String  ${QUESTA_ARGUMENTS}

    ${system}=                      Evaluate  platform.system()  modules=platform
    Append To List                  ${simulationArguments}  -work  ${QUESTA_WORK_LIBRARY}
    Append To List                  ${simulationArguments}  -c  -do  run -all  -onfinish  exit
    Append To List                  ${simulationArguments}  -GReceiverPort\=${connectionArguments}[0]  -GSenderPort\=${connectionArguments}[1]  -GAddress\="${connectionArguments}[2]"
    IF  '${system}' == 'Windows'
        Append To List                  ${simulationArguments}  -ldflags  -lws2_32
    END
    ${logFile}=                     Allocate Temporary File
    Start Process                   ${QUESTA_COMMAND}  ${QUESTA_DESIGN}  @{simulationArguments}  stdout=${logFile}
    Execute Command                 mem Connect

Terminate And Log
    ${result}=                      Wait For Process  timeout=5 secs  on_timeout=terminate
    Log                             ${result.stdout}
    IF  ${result.rc} != 0
        Log                             RC = ${result.rc}  ERROR
        Log                             ${result.stderr}  ERROR
    END

Transaction Should Finish
    ${val}=                         Execute Command  dma ReadDoubleWord 0x4
    Should Contain                  ${val}  0x00000000

Prepare Data
    [Arguments]                     ${addr}

    # dummy data for verification
    ${addr}=                        Evaluate  ${addr} + 0x0
    Execute Command                 sysbus WriteDoubleWord ${addr} 0xDEADBEA7
    ${addr}=                        Evaluate  ${addr} + 0x4
    Execute Command                 sysbus WriteDoubleWord ${addr} 0xDEADC0DE
    ${addr}=                        Evaluate  ${addr} + 0x4
    Execute Command                 sysbus WriteDoubleWord ${addr} 0xCAFEBABE
    ${addr}=                        Evaluate  ${addr} + 0x4
    Execute Command                 sysbus WriteDoubleWord ${addr} 0x5555AAAA

Configure DMA
    [Arguments]                     ${src}
    ...                             ${dst}
    # reader start address
    Execute Command                 dma WriteDoubleWord 0x10 ${src}
    # reader line length in 32-bit words
    Execute Command                 dma WriteDoubleWord 0x14 1024
    # number of lines to read
    Execute Command                 dma WriteDoubleWord 0x18 1
    # stride size between consecutive lines in 32-bit words
    Execute Command                 dma WriteDoubleWord 0x1c 0

    # writer start address
    Execute Command                 dma WriteDoubleWord 0x20 ${dst}
    # writer line length in 32-bit words
    Execute Command                 dma WriteDoubleWord 0x24 1024
    # number of lines to write
    Execute Command                 dma WriteDoubleWord 0x28 1
    # stride size between consecutive lines in 32-bit words
    Execute Command                 dma WriteDoubleWord 0x2c 0

    # do not wait fo external synchronization signal
    Execute Command                 dma WriteDoubleWord 0x00 0x0f

Ensure Memory Is Clear
    [Arguments]                     ${periph}

    # Verify that there are 0's under the writer start address before starting the transaction
    Memory Should Contain           ${periph}  0x0  0x00000000
    Memory Should Contain           ${periph}  0x4  0x00000000
    Memory Should Contain           ${periph}  0x8  0x00000000
    Memory Should Contain           ${periph}  0xC  0x00000000

Ensure Memory Is Written
    [Arguments]                     ${periph}

    # Verify data after the transaction
    Memory Should Contain           ${periph}  0x0  0xDEADBEA7
    Memory Should Contain           ${periph}  0x4  0xDEADC0DE
    Memory Should Contain           ${periph}  0x8  0xCAFEBABE
    Memory Should Contain           ${periph}  0xC  0x5555AAAA

Memory Should Contain
    [Arguments]                     ${periph}  ${addr}  ${val}
    ${res}=                         Execute Command  ${periph} ReadDoubleWord ${addr}
    Should Contain                  ${res}  ${val}

Test Read Write Verilated Memory
    Ensure Memory Is Clear          mem

    # Write to memory
    Prepare Data                    0x20000000

    Ensure Memory Is Written        mem

Test DMA Transaction From Verilated Memory to Verilated Memory
    Prepare Data                    0x20080000

    Configure DMA                   0x20080000  0x20000000

    Ensure Memory Is Clear          mem

    Execute Command                 emulation RunFor "00:00:10.000000"
    Transaction Should Finish

    Ensure Memory Is Written        mem

*** Test Cases ***
Should Connect Verilator
    [Tags]                          verilator
    Create Log Tester               0
    Execute Command                 logLevel 0
    Create Machine
    Connect Verilator

    Wait For Log Entry              mem: Connected
    Execute Command                 mem Reset

Should Connect Questa
    [Tags]                          questa
    Create Log Tester               0
    Execute Command                 logLevel 0
    Create Machine
    Connect Questa

    Wait For Log Entry              mem: Connected
    Execute Command                 mem Reset

Should Read Write Verilated Memory In Verilator
    [Tags]                          verilator
    Create Machine
    Connect Verilator
    Test Read Write Verilated Memory

Should Read Write Verilated Memory In Questa
    [Tags]                          questa
    Create Machine
    Connect Questa
    Test Read Write Verilated Memory

Should Run DMA Transaction From Verilated Memory to Verilated Memory In Verilator
    [Tags]                          verilator
    Create Machine
    Connect Verilator
    Test DMA Transaction From Verilated Memory to Verilated Memory

Should Run DMA Transaction From Verilated Memory to Verilated Memory In Questa
    [Tags]                          questa
    Create Machine
    Connect Questa
    Test DMA Transaction From Verilated Memory to Verilated Memory
