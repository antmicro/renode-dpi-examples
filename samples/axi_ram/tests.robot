*** Settings ***
Resource                            ${CURDIR}/../../robot/dpi.robot
Test Teardown                       Run Keywords
...                                 Test Teardown
...                                 Terminate And Log

*** Variables ***
${DPI_PLATFORM}                     ${CURDIR}/platform.resc
${BUILD_DIRECTORY}                  ${CURDIR}/build
${VERILATED_BINARY}                 ${BUILD_DIRECTORY}/verilated
${QUESTA_WORK_LIBRARY}              ${BUILD_DIRECTORY}/work_questa

${TEST_DATA}                        12345678CAFEBABE000000005A5A5A5A


*** Keywords ***
Create Machine
    Execute Command                 include @${DPI_PLATFORM}

Terminate And Log
    ${result}=                      Wait For Process  timeout=5 secs  on_timeout=terminate
    Log                             ${result.stdout}
    IF  ${result.rc} != 0
        Log                             RC = ${result.rc}  ERROR
        Log                             ${result.stderr}  ERROR
    END

Get Bytes Count For Access Type
    [Arguments]                     ${access_type}
    IF  "${access_type}" == "DoubleWord"
        RETURN                          4
    ELSE IF  "${access_type}" == "Word"
        RETURN                          2
    ELSE IF  "${access_type}" == "Byte"
        RETURN                          1
    ELSE
        Fatal Error                     Unknown access type: ${access_type}
    END

Write To Memory
    [Arguments]                     ${address_start}  ${data_hex}  ${access_type}
    ${bytes_count}=                 Get Bytes Count For Access Type  ${access_type}
    ${digits_count}=                Evaluate  int(${bytes_count}) * 2

    FOR  ${index}  IN RANGE  0  ${{ math.ceil(len($data_hex) / ${digits_count}) }}
        ${addr}=                        Evaluate  hex(int(${address_start}) + ${index} * ${bytes_count})
        ${data_end}=                    Evaluate  len($data_hex) - ${index} * ${digits_count}
        ${data_start}=                  Evaluate  ${data_end} - ${digits_count}
        Execute Command                 mem Write${access_type} ${addr} 0x${data_hex}[${data_start} : ${data_end}]
    END

Should Memory Contains
    [Arguments]                     ${address_start}  ${expected_hex}  ${access_type}
    ${bytes_count}=                 Get Bytes Count For Access Type  ${access_type}
    ${digits_count}=                Evaluate  int(${bytes_count}) * 2

    FOR  ${index}  IN RANGE  0  ${{ math.ceil(len($expected_hex) / ${digits_count}) }}
        ${addr}=                        Evaluate  hex(int(${address_start}) + ${index} * ${bytes_count})
        ${result}=                      Execute Command  mem Read${access_type} ${addr}
        ${result_stripped}=             Strip String  ${result}
        ${expected_end}=                Evaluate  len($expected_hex) - ${index} * ${digits_count}
        ${expected_start}=              Evaluate  ${expected_end} - ${digits_count}
        Should Be Equal                 ${result_stripped}  0x${expected_hex}[${expected_start} : ${expected_end}]
    END

Test Read And Write Memory
    ${all_access_types}=            Create List  DoubleWord
    FOR  ${write_access_type}  IN  @{all_access_types}
        Write To Memory                 0x0  ${TEST_DATA}  ${write_access_type}
        FOR  ${read_access_type}  IN  @{all_access_types}
            Should Memory Contains          0x0  ${TEST_DATA}  ${read_access_type}
        END
    END


*** Test Cases ***
Should Connect Verilator
    [Tags]                          verilator
    Create Log Tester               0
    Execute Command                 logLevel 0
    Create Machine
    Connect Verilator               mem  ${VERILATED_BINARY}

    Wait For Log Entry              mem: Connected
    Execute Command                 mem Reset

Should Connect Questa
    [Tags]                          questa
    Create Log Tester               0
    Execute Command                 logLevel 0
    Create Machine
    Connect Questa                  mem  ${QUESTA_WORK_LIBRARY}

    Wait For Log Entry              mem: Connected
    Execute Command                 mem Reset

Should Read And Write Memory In Verilator
    [Tags]                          verilator
    Create Machine
    Connect Verilator               mem  ${VERILATED_BINARY}

    Start Emulation
    Test Read And Write Memory

Should Read And Write Memory In Questa
    [Tags]                          questa
    Create Machine
    Connect Questa                  mem  ${QUESTA_WORK_LIBRARY}

    Start Emulation
    Test Read And Write Memory
