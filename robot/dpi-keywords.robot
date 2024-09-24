*** Variables ***
${BUILD_DIRECTORY}                  ./build

${VERILATOR_SIMULATION}             ${BUILD_DIRECTORY}/verilated

${VCS_SIMULATION}                   ${BUILD_DIRECTORY}/simv
@{VCS_ARGUMENTS}                    -sv_lib  ${BUILD_DIRECTORY}/librenode_dpi

${QUESTA_SIMULATION}                vsim
${QUESTA_USER_ARGUMENTS}            ${EMPTY}
@{QUESTA_ARGUMENTS}                 design_optimized
...                                 -work  ${BUILD_DIRECTORY}/work_questa
...                                 -c
...                                 -do  run -all
...                                 -onfinish  exit

*** Keywords ***
Should Connect To Simulation And Reset Peripheral
    [Arguments]                     ${peripheral}  ${create_machine_keyword}  ${run_simulation_keyword}
    Create Log Tester               0
    Execute Command                 logLevel 0

    Run Keyword                     ${create_machine_keyword}
    Connect To Simulation           ${peripheral}  ${run_simulation_keyword}

    Wait For Log Entry              ${peripheral}: Connected
    Execute Command                 ${peripheral} Reset

Connect To Simulation
    [Arguments]                     ${peripheral_name}  ${run_simulation_keyword}
    ${connection_arguments}=        Get Connection Plus Args  ${peripheral_name}

    Run Keyword                     ${run_simulation_keyword}  ${connection_arguments}
    Execute Command                 ${peripheral_name} Connect

Get Connection Plus Args
    [Arguments]                     ${peripheral_name}
    ${connection_string}=           Execute Command  ${peripheral_name} ConnectionParameters
    ${parameters}=                  Split String  ${connection_string}
    ${arguments}=                   Create List  +RENODE_RECEIVER_PORT\=${parameters}[0]
    ...                             +RENODE_SENDER_PORT\=${parameters}[1]
    ...                             +RENODE_ADDRESS\=${parameters}[2]
    RETURN   ${arguments}

Run VCS
    [Arguments]                     ${additional_arguments}
    ${arguments}=                   Combine Lists  ${VCS_ARGUMENTS}  ${additional_arguments}
    Run Executable                  ${VCS_SIMULATION}  ${arguments}

Run Verilator
    [Arguments]                     ${arguments}
    Run Executable                  ${VERILATOR_SIMULATION}  ${arguments}

Run Questa
    [Arguments]                     ${additional_arguments}
    ${user_arguments}=              Split String  ${QUESTA_USER_ARGUMENTS}
    ${arguments}=                   Combine Lists  ${QUESTA_ARGUMENTS}  ${user_arguments}  ${additional_arguments}

    ${system}=                      Evaluate  platform.system()  modules=platform
    IF  '${system}' == 'Windows'
        Append To List                  ${arguments}  -ldflags  -lws2_32
    END

    Run Executable                  ${QUESTA_SIMULATION}  ${arguments}

Run Executable
    [Arguments]                     ${executable}  ${arguments}
    ${logFile}=                     Allocate Temporary File
    # The process standard output is redirected to the file to prevent a buffer from filling up
    Start Process                   ${executable}  @{arguments}  stdout=${logFile}

Terminate And Log
    ${result}=                      Wait For Process  timeout=5 secs  on_timeout=terminate
    Log                             ${result.stdout}
    IF  ${result.rc} != 0
        Fail                            ${result.stderr}
        Log                             RC = ${result.rc}  ERROR
    END
