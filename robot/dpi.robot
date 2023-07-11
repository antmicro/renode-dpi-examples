*** Variables ***
${QUESTA_COMMAND}                   vsim
${QUESTA_DESIGN}                    design_optimized
${QUESTA_ARGUMENTS}                 ${EMPTY}


*** Keywords ***
Connect Verilator
    [Arguments]                     ${PERIPHERAL_NAME}  ${BINARY}
    ${connectionParameters}=        Execute Command  ${PERIPHERAL_NAME} ConnectionParameters
    ${simulationArguments}=         Split String  ${connectionParameters}
    ${logFile}=                     Allocate Temporary File
    Start Process                   ${BINARY}  @{simulationArguments}  stdout=${logFile}
    Execute Command                 ${PERIPHERAL_NAME} Connect

Connect Questa
    [Arguments]                     ${PERIPHERAL_NAME}  ${WORK_LIBRARY}
    ${connectionParameters}=        Execute Command  ${PERIPHERAL_NAME} ConnectionParameters
    ${connectionArguments}=         Split String  ${connectionParameters}
    ${simulationArguments}=         Split String  ${QUESTA_ARGUMENTS}

    ${system}=                      Evaluate  platform.system()  modules=platform
    Append To List                  ${simulationArguments}  -work  ${WORK_LIBRARY}
    Append To List                  ${simulationArguments}  -c  -do  run -all  -onfinish  exit
    Append To List                  ${simulationArguments}  -GReceiverPort\=${connectionArguments}[0]  -GSenderPort\=${connectionArguments}[1]  -GAddress\="${connectionArguments}[2]"
    IF  '${system}' == 'Windows'
        Append To List                  ${simulationArguments}  -ldflags  -lws2_32
    END
    ${logFile}=                     Allocate Temporary File
    Start Process                   ${QUESTA_COMMAND}  ${QUESTA_DESIGN}  @{simulationArguments}  stdout=${logFile}
    Execute Command                 ${PERIPHERAL_NAME} Connect

Terminate And Log
    ${result}=                      Wait For Process  timeout=5 secs  on_timeout=terminate
    Log                             ${result.stdout}
    IF  ${result.rc} != 0
        Log                             RC = ${result.rc}  ERROR
        Log                             ${result.stderr}  ERROR
    END

