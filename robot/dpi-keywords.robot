*** Variables ***
${QUESTA_COMMAND}                   vsim
${QUESTA_DESIGN}                    design_optimized
${QUESTA_ARGUMENTS}                 ${EMPTY}


*** Keywords ***
Run Verilator
    [Arguments]                     ${binary}  ${arguments}
    ${logFile}=                     Allocate Temporary File
    # The process standard output is redirected to the file to prevent a buffer from filling up
    Start Process                   ${binary}  @{arguments}  stdout=${logFile}

Connect To Verilator
    [Arguments]                     ${peripheral_name}  ${binary}
    ${connectionParameters}=        Execute Command  ${peripheral_name} ConnectionParameters
    ${simulationArguments}=         Split String  ${connectionParameters}
    Run Verilator                   ${binary}  ${simulationArguments}
    Execute Command                 ${peripheral_name} Connect

Run Questa
    [Arguments]                     ${work_library}  ${arguments}
    ${global_arguments}=            Split String  ${QUESTA_ARGUMENTS}
    Append To List                  ${arguments}  @{global_arguments}
    Append To List                  ${arguments}  -work  ${work_library}
    Append To List                  ${arguments}  -c  -do  run -all  -onfinish  exit
    ${system}=                      Evaluate  platform.system()  modules=platform
    IF  '${system}' == 'Windows'
        Append To List                  ${arguments}  -ldflags  -lws2_32
    END
    ${logFile}=                     Allocate Temporary File
    # The process standard output is redirected to the file to prevent a buffer from filling up
    Start Process                   ${QUESTA_COMMAND}  ${QUESTA_DESIGN}  @{arguments}  stdout=${logFile}

Connect To Questa
    [Arguments]                     ${peripheral_name}  ${work_library}
    ${connectionParameters}=        Execute Command  ${peripheral_name} ConnectionParameters
    ${connectionArguments}=         Split String  ${connectionParameters}

    ${simulationArguments}=         Create List  -GReceiverPort\=${connectionArguments}[0]  -GSenderPort\=${connectionArguments}[1]  -GAddress\="${connectionArguments}[2]"
    Run Questa                      ${work_library}  ${simulationArguments}
    Execute Command                 ${peripheral_name} Connect

Terminate And Log
    ${result}=                      Wait For Process  timeout=5 secs  on_timeout=terminate
    Log                             ${result.stdout}
    IF  ${result.rc} != 0
        Fail                            ${result.stderr}
        Log                             RC = ${result.rc}  ERROR
    END

Should Connect To Verilator And Reset Peripheral
    [Arguments]                     ${peripheral}  ${verilated_binary}  ${create_machine_keyword}
    Create Log Tester               0
    Execute Command                 logLevel 0

    Run Keyword                     ${create_machine_keyword}
    Connect To Verilator            ${peripheral}  ${verilated_binary}

    Wait For Log Entry              ${peripheral}: Connected
    Execute Command                 ${peripheral} Reset

Should Connect To Questa And Reset Peripheral
    [Arguments]                     ${peripheral}  ${work_library}  ${create_machine_keyword}
    Create Log Tester               0
    Execute Command                 logLevel 0

    Run Keyword                     ${create_machine_keyword}
    Connect To Questa               ${peripheral}  ${work_library}

    Wait For Log Entry              ${peripheral}: Connected
    Execute Command                 ${peripheral} Reset
