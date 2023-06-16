*** Settings ***
Test Teardown                       Run Keywords
...                                 Test Teardown
...                                 Terminate And Log

*** Variables ***
${DPI_PLATFORM}                     ${CURDIR}/platform.resc
${VERILATED_BINARY}                 ${CURDIR}/build/verilated

${QUESTA_COMMAND}                   vsim
${QUESTA_WORK_LIBRARY}              ${CURDIR}/build/work_questa
${QUESTA_DESIGN}                    design_optimized
${QUESTA_ARGUMENTS}                 ${EMPTY}


*** Keywords ***
Create Machine
    Execute Command                 include @${DPI_PLATFORM}

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

Memory Should Contain
    [Arguments]                     ${addr}  ${val}
    ${res}=                         Execute Command  mem ReadDoubleWord ${addr}
    Should Contain                  ${res}  ${val}

Test Read And Write Memory
    Memory Should Contain           0x0  0x00000000
    Memory Should Contain           0x1000  0x00000000

    Execute Command                 mem WriteDoubleWord 0x0 0x12345678
    Execute Command                 mem WriteDoubleWord 0x4 0xCAFEBABE
    Execute Command                 mem WriteDoubleWord 0x8 0x5A5A5A5A
    Execute Command                 mem WriteDoubleWord 0x1000 0xDEADBEEF

    Memory Should Contain           0x0  0x12345678
    Memory Should Contain           0x4  0xCAFEBABE
    Memory Should Contain           0x8  0x5A5A5A5A
    Memory Should Contain           0xC  0x00000000
    Memory Should Contain           0xFFFC  0x00000000
    Memory Should Contain           0x1000  0xDEADBEEF
    Memory Should Contain           0x1004  0x00000000

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

Should Read And Write Memory In Verilator
    [Tags]                          verilator
    Create Machine
    Connect Verilator

    Start Emulation
    Test Read And Write Memory

Should Read And Write Memory In Questa
    [Tags]                          questa
    Create Machine
    Connect Questa

    Start Emulation
    Test Read And Write Memory
