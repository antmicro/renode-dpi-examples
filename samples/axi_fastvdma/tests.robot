*** Settings ***
Test Teardown                       Run Keywords
...                                 Test Teardown
...                                 Terminate And Log

*** Variables ***
${BASIC_PLATFORM}                   ${CURDIR}/platform_basic.resc
${VERILATED_BINARY}                 ${CURDIR}/build/verilated

${QUESTA_COMMAND}                   vsim
${QUESTA_WORK_LIBRARY}              ${CURDIR}/build/work_questa
${QUESTA_DESIGN}                    design_optimized
${QUESTA_ARGUMENTS}                 ${EMPTY}

${LINUX_PROMPT}                     zynq>
${LINUX_PLATFORM}                   ${CURDIR}/platform_linux.resc
${LINUX_UART}                       sysbus.uart1
${FASTVDMA_DRIVER}                  /lib/modules/5.10.0-xilinx/kernel/drivers/dma/fastvdma/fastvdma.ko
${FASTVDMA_DEMO_DRIVER}             /lib/modules/5.10.0-xilinx/kernel/drivers/dma/fastvdma/fastvdma-demo.ko


*** Keywords ***
Create Machine
    Execute Command                 include @${BASIC_PLATFORM}

Create Linux Machine
    Execute Command                 include @${LINUX_PLATFORM}

Connect Verilator
    ${connectionParameters}=        Execute Command  dma ConnectionParameters
    ${simulationArguments}=         Split String  ${connectionParameters}
    ${logFile}=                     Allocate Temporary File
    Start Process                   ${VERILATED_BINARY}  @{simulationArguments}  stdout=${logFile}
    Execute Command                 dma Connect

Connect Questa
    ${connectionParameters}=        Execute Command  dma ConnectionParameters
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
    Execute Command                 dma Connect

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

Compare Parts Of Images On Linux
    [Arguments]                     ${img0}  ${img1}  ${count}  ${skip0}  ${skip1}

    Write Line To Uart              dd if=${img0} of=test.rgba bs=128 count=${count} skip=${skip0}
    Wait For Prompt On Uart         ${LINUX_PROMPT}
    Write Line To Uart              dd if=${img1} of=otest.rgba bs=128 count=${count} skip=${skip1}
    Wait For Prompt On Uart         ${LINUX_PROMPT}

    Write Line To Uart              cmp test.rgba otest.rgba
    Wait For Prompt On Uart         ${LINUX_PROMPT}

# Check if exit status is 0 (the input files are the same)
    Write Line To Uart              echo $?
    Wait For Line On Uart           0
    Wait For Prompt On Uart         ${LINUX_PROMPT}

Test DMA Driver On Linux
    Start Emulation

    Wait For Prompt On Uart         ${LINUX_PROMPT}  timeout=30

# Suppress messages from kernel space
    Write Line To Uart              echo 0 > /proc/sys/kernel/printk

# Write Line To Uart for some reason breaks this line into two.
    Write To Uart                   insmod ${FASTVDMA_DRIVER} ${\n}
    Wait For Prompt On Uart         ${LINUX_PROMPT}

    Write To Uart                   insmod ${FASTVDMA_DEMO_DRIVER} ${\n}
    Wait For Prompt On Uart         ${LINUX_PROMPT}

    Write Line To Uart              lsmod
    Wait For Line On Uart           Module
    Wait For Line On Uart           fastvdma_demo
    Wait For Line On Uart           fastvdma

    Write Line To Uart              ./demo
    Wait For Prompt On Uart         ${LINUX_PROMPT}  timeout=20

    Write Line To Uart              chmod +rw out.rgba
    Wait For Prompt On Uart         ${LINUX_PROMPT}  timeout=20

    Compare Parts Of Images On Linux  img0.rgba  out.rgba  2048  0  0
    FOR  ${i}  IN RANGE  8
        Compare Parts Of Images On Linux  img0.rgba  out.rgba  4  ${2048 + ${i} * 16}  ${2048 + ${i} * 16}
        Compare Parts Of Images On Linux  img1.rgba  out.rgba  8  ${${i} * 8}  ${2052 + ${i} * 16}
        Compare Parts Of Images On Linux  img0.rgba  out.rgba  4  ${2060 + ${i} * 16}  ${2060 + ${i} * 16}
    END
    Compare Parts Of Images On Linux  img0.rgba  out.rgba  2052  6140  6140

*** Test Cases ***
Should Connect Verilator
    [Tags]                          verilator
    Create Log Tester               0
    Execute Command                 logLevel 0
    Create Machine
    Connect Verilator

    Wait For Log Entry              dma: Connected
    Execute Command                 dma Reset

Should Connect Questa
    [Tags]                          questa
    Create Log Tester               0
    Execute Command                 logLevel 0
    Create Machine
    Connect Questa

    Wait For Log Entry              dma: Connected
    Execute Command                 dma Reset

Should Run DMA Transaction In Verilator
    [Tags]                          verilator
    Create Machine
    Connect Verilator
    Test DMA Transaction

Should Run DMA Transaction In Questa
    [Tags]                          questa
    Create Machine
    Connect Questa
    Test DMA Transaction

Should Trigger DMA Interrupt In Verilator
    [Tags]                          verilator
    Create Log Tester               0
    Create Machine
    Execute Command                 logLevel -1 plic
    Connect Verilator

    Test DMA Interrupt

Should Trigger DMA Interrupt In Questa
    [Tags]                          questa
    Create Log Tester               0
    Create Machine
    Execute Command                 logLevel -1 plic
    Connect Questa

    Test DMA Interrupt

Should Boot Linux And Use DMA In Verilator
    [Tags]                          verilator  linux
    Create Linux Machine
    Connect Verilator
    Create Terminal Tester          ${LINUX_UART}

    Test DMA Driver On Linux

Should Boot Linux And Use DMA In Questa
    [Tags]                          questa  linux
    Create Linux Machine
    Connect Questa
    Create Terminal Tester          ${LINUX_UART}

    Test DMA Driver On Linux
