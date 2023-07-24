*** Variables ***
${QUESTA_COMMAND}                   vsim
${QUESTA_DESIGN}                    design_optimized
${QUESTA_ARGUMENTS}                 ${EMPTY}


*** Keywords ***
Connect To Verilator
    [Arguments]                     ${peripheral_name}  ${binary}
    ${connectionParameters}=        Execute Command  ${peripheral_name} ConnectionParameters
    ${simulationArguments}=         Split String  ${connectionParameters}
    ${logFile}=                     Allocate Temporary File
    # The process standard output is redirected to the file to prevent a buffer from filling up
    Start Process                   ${binary}  @{simulationArguments}  stdout=${logFile}
    Execute Command                 ${peripheral_name} Connect

Connect To Questa
    [Arguments]                     ${peripheral_name}  ${work_library}
    ${connectionParameters}=        Execute Command  ${peripheral_name} ConnectionParameters
    ${connectionArguments}=         Split String  ${connectionParameters}
    ${simulationArguments}=         Split String  ${QUESTA_ARGUMENTS}

    ${system}=                      Evaluate  platform.system()  modules=platform
    Append To List                  ${simulationArguments}  -work  ${work_library}
    Append To List                  ${simulationArguments}  -c  -do  run -all  -onfinish  exit
    Append To List                  ${simulationArguments}  -GReceiverPort\=${connectionArguments}[0]  -GSenderPort\=${connectionArguments}[1]  -GAddress\="${connectionArguments}[2]"
    IF  '${system}' == 'Windows'
        Append To List                  ${simulationArguments}  -ldflags  -lws2_32
    END
    ${logFile}=                     Allocate Temporary File
    # The process standard output is redirected to the file to prevent a buffer from filling up
    Start Process                   ${QUESTA_COMMAND}  ${QUESTA_DESIGN}  @{simulationArguments}  stdout=${logFile}
    Execute Command                 ${peripheral_name} Connect

Terminate And Log
    ${result}=                      Wait For Process  timeout=5 secs  on_timeout=terminate
    Log                             ${result.stdout}
    IF  ${result.rc} != 0
        Log                             RC = ${result.rc}  ERROR
        Log                             ${result.stderr}  ERROR
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
