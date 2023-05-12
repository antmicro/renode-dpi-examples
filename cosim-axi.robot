*** Settings ***
Suite Setup                   Setup
Suite Teardown                Teardown
Test Setup                    Run Keywords
...                           Reset Emulation
Test Teardown                 Run Keywords
...                           Test Teardown
Resource                      ${RENODEKEYWORDS}

*** Variables ***
${URI}                              https://dl.antmicro.com/projects/renode
${VFASTDMA_SOCKET_LINUX}            ${URI}/Vfastvdma-Linux-x86_64-1116123840-s_1616232-37fd8031dec810475ac6abf68a789261ce6551b0
${VFASTDMA_SOCKET_WINDOWS}          ${URI}/Vfastvdma-Windows-x86_64-1116123840.exe-s_14833257-3a1fef7953686e58a00b09870c5a57e3ac91621d
${COSIM_BIN}                        ../artifacts/Vcosim_bfm_axi_dpi.exe

*** Keywords ***
Create Machine
    Set Test Variable   ${dma_args}             ; address: "127.0.0.1"
    Set Test Variable   ${vfastdma_linux}       ${VFASTDMA_SOCKET_LINUX}
    Set Test Variable   ${vfastdma_windows}     ${VFASTDMA_SOCKET_WINDOWS}
    Set Test Variable   ${mem_args}             ; address: "127.0.0.1"

    Execute Command                             using sysbus
    Execute Command                             mach create
    Execute Command                             machine LoadPlatformDescriptionFromString 'cpu: CPU.RiscV32 @ sysbus { cpuType: "rv32imaf"; timeProvider: empty }'
    Execute Command                             machine LoadPlatformDescriptionFromString 'dma: Verilated.BaseDoubleWordVerilatedPeripheral @ sysbus <0x10000000, +0x100> { frequency: 100000; limitBuffer: 100000; timeout: 10000 ${dma_args} }'
    Execute Command                             machine LoadPlatformDescriptionFromString 'mem: Cosimulated.CosimulatedPeripheral @ sysbus <0x20000000, +0x100000> { maxWidth: 4}'
    Execute Command                             machine LoadPlatformDescriptionFromString 'ram: Memory.MappedMemory @ sysbus 0xA0000000 { size: 0x06400000 }'
    Execute Command                             sysbus WriteDoubleWord 0xA2000000 0x10500073   # wfi
    Execute Command                             cpu PC 0xA2000000
    Execute Command                             dma SimulationFilePathLinux @${vfastdma_linux}
    Execute Command                             dma SimulationFilePathWindows @${vfastdma_windows}
    Execute Command                             mem SimulationFilePathLinux @${COSIM_BIN}
    Execute Command                             mem SimulationFilePathWindows @${COSIM_BIN}

Transaction Should Finish
    ${val} =            Execute Command         dma ReadDoubleWord 0x4
    Should Contain      ${val}                  0x00000000

Prepare Data
    [Arguments]         ${addr}

    # dummy data for verification
    ${addr} =                                   Evaluate  ${addr} + 0x0
    Execute Command                             sysbus WriteDoubleWord ${addr} 0xDEADBEA7
    ${addr} =                                   Evaluate  ${addr} + 0x4
    Execute Command                             sysbus WriteDoubleWord ${addr} 0xDEADC0DE
    ${addr} =                                   Evaluate  ${addr} + 0x4
    Execute Command                             sysbus WriteDoubleWord ${addr} 0xCAFEBABE
    ${addr} =                                   Evaluate  ${addr} + 0x4
    Execute Command                             sysbus WriteDoubleWord ${addr} 0x5555AAAA


Clear Data
    [Arguments]         ${addr}

    # dummy data for verification
    ${addr} =                                   Evaluate  ${addr} + 0x0
    Execute Command                             sysbus WriteDoubleWord ${addr} 0
    ${addr} =                                   Evaluate  ${addr} + 0x4
    Execute Command                             sysbus WriteDoubleWord ${addr} 0
    ${addr} =                                   Evaluate  ${addr} + 0x4
    Execute Command                             sysbus WriteDoubleWord ${addr} 0
    ${addr} =                                   Evaluate  ${addr} + 0x4
    Execute Command                             sysbus WriteDoubleWord ${addr} 0


Configure DMA
    [Arguments]         ${src}
    ...                 ${dst}
    # reader start address
    Execute Command                             dma WriteDoubleWord 0x10 ${src}
    # reader line length in 32-bit words
    Execute Command                             dma WriteDoubleWord 0x14 8
    # number of lines to read
    Execute Command                             dma WriteDoubleWord 0x18 1
    # stride size between consecutive lines in 32-bit words
    Execute Command                             dma WriteDoubleWord 0x1c 0

    # writer start address
    Execute Command                             dma WriteDoubleWord 0x20 ${dst}
    # writer line length in 32-bit words
    Execute Command                             dma WriteDoubleWord 0x24 8
    # number of lines to write
    Execute Command                             dma WriteDoubleWord 0x28 1
    # stride size between consecutive lines in 32-bit words
    Execute Command                             dma WriteDoubleWord 0x2c 0

    # do not wait fo external synchronization signal
    Execute Command                             dma WriteDoubleWord 0x00 0x0f


Ensure Memory Is Clear
    [Arguments]         ${periph}

    # Verify that there are 0's under the writer start address before starting the transaction
    Memory Should Contain                       ${periph}  0x0  0x00000000
    Memory Should Contain                       ${periph}  0x4  0x00000000
    Memory Should Contain                       ${periph}  0x8  0x00000000
    Memory Should Contain                       ${periph}  0xC  0x00000000


Ensure Memory Is Written
    [Arguments]         ${periph}

    # Verify data after the transaction
    Memory Should Contain                       ${periph}  0x0  0xDEADBEA7
    Memory Should Contain                       ${periph}  0x4  0xDEADC0DE
    Memory Should Contain                       ${periph}  0x8  0xCAFEBABE
    Memory Should Contain                       ${periph}  0xC  0x5555AAAA


Memory Should Contain
    [Arguments]         ${periph}
    ...                 ${addr}
    ...                 ${val}
    ${res}=             Execute Command         ${periph} ReadDoubleWord ${addr}
    Should Contain                              ${res}             ${val}

Memory Should Contain Read By Sysbus
    [Arguments]         ${addr}
    ...                 ${val}
    ${res}=             Execute Command         sysbus ReadDoubleWord ${addr}
    Should Contain                              ${res}             ${val}

Test Read Write Cosimulated Memory
    Execute Command                             mem Init 0 0
    Ensure Memory Is Clear                      mem

    # Write to memory
    Prepare Data                                0x20000000

    Ensure Memory Is Written                    mem
    Execute Command                             mem Close 0

Test DMA Transaction From Mapped Memory to Cosimulated Memory
    Execute Command                             mem Init 0 0
    Prepare Data                                0xA1000000

    Configure DMA                               0xA1000000  0x20000000

    Ensure Memory Is Clear                      mem

    Execute Command                             emulation RunFor "00:00:10.000000"
    Transaction Should Finish
    Execute Command                             pause

    Ensure Memory Is Written                    mem
    Execute Command                             mem Close 0

Test DMA Transaction From Cosimulated Memory to Mapped Memory
    Execute Command                             mem Init 0 0
    Prepare Data                                0x20080000

    Configure DMA                               0x20080000  0xA0000000

    Ensure Memory Is Clear                      ram

    Execute Command                             emulation RunFor "00:00:20.000000"
    Transaction Should Finish

    ## Ensure Memory Is Written                    ram
    Memory Should Contain Read By Sysbus        0xA0000000  0xDEADBEA7
    Memory Should Contain Read By Sysbus        0xA0000004  0xDEADC0DE
    Memory Should Contain Read By Sysbus        0xA0000008  0xCAFEBABE
    Memory Should Contain Read By Sysbus        0xA000000C  0x5555AAAA

    Execute Command                             mem Close 0

Test DMA Transaction From Cosimulated Memory to Cosimulated Memory
    Execute Command                             mem Init 0 0
    Prepare Data                                0x20080000

    Configure DMA                               0x20080000  0x20000100

    Memory Should Contain Read By Sysbus        0x20000100  0
    Memory Should Contain Read By Sysbus        0x20000104  0
    Memory Should Contain Read By Sysbus        0x20000108  0
    Memory Should Contain Read By Sysbus        0x2000010C  0
    Execute Command                             emulation RunFor "00:00:10.000000"
    Transaction Should Finish

    Memory Should Contain Read By Sysbus        0x20000100  0xDEADBEA7
    Memory Should Contain Read By Sysbus        0x20000104  0xDEADC0DE
    Memory Should Contain Read By Sysbus        0x20000108  0xCAFEBABE
    Memory Should Contain Read By Sysbus        0x2000010C  0x5555AAAA

    Execute Command                             mem Close 0

*** Test Cases ***
Should Read Write Cosimulated Memory Using Socket
    Create Machine
    Test Read Write Cosimulated Memory

Should Run DMA Transaction From Mapped Memory to Cosimulated Memory Using Socket
    Create Machine
    Test DMA Transaction From Mapped Memory to Cosimulated Memory

Should Run DMA Transaction From Cosimulated Memory to Mapped Memory Using Socket
    Create Machine
    Test DMA Transaction From Cosimulated Memory To Mapped Memory

Should Run DMA Transaction From Cosimulated Memory to Cosimulated Memory Using Socket
    Create Machine
    Test DMA Transaction From Cosimulated Memory To Cosimulated Memory
