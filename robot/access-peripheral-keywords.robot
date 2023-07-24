*** Keywords ***
Get Bytes Count For Access Type
    [Arguments]                     ${access_type}
    IF  "${access_type}" == "QuadWord"
        RETURN                          8
    ELSE IF  "${access_type}" == "DoubleWord"
        RETURN                          4
    ELSE IF  "${access_type}" == "Word"
        RETURN                          2
    ELSE IF  "${access_type}" == "Byte"
        RETURN                          1
    ELSE
        Fatal Error                     Unknown access type: ${access_type}
    END

Write To Peripheral
    [Arguments]                     ${peripheral}  ${access_type}  ${address_start}  ${data_hex}
    ${bytes_count}=                 Get Bytes Count For Access Type  ${access_type}
    ${digits_count}=                Evaluate  int(${bytes_count}) * 2

    FOR  ${index}  IN RANGE  0  ${{ math.ceil(len($data_hex) / ${digits_count}) }}
        ${addr}=                        Evaluate  hex(int(${address_start}) + ${index} * ${bytes_count})
        ${data_end}=                    Evaluate  len($data_hex) - ${index} * ${digits_count}
        ${data_start}=                  Evaluate  ${data_end} - ${digits_count}
        Execute Command                 ${peripheral} Write${access_type} ${addr} 0x${data_hex}[${data_start} : ${data_end}]
    END

Should Peripheral Contain
    [Arguments]                     ${peripheral}  ${access_type}  ${address_start}  ${expected_hex}
    ${bytes_count}=                 Get Bytes Count For Access Type  ${access_type}
    ${digits_count}=                Evaluate  int(${bytes_count}) * 2

    FOR  ${index}  IN RANGE  0  ${{ math.ceil(len($expected_hex) / ${digits_count}) }}
        ${addr}=                        Evaluate  hex(int(${address_start}) + ${index} * ${bytes_count})
        ${result}=                      Execute Command  ${peripheral} Read${access_type} ${addr}
        ${result_stripped}=             Strip String  ${result}
        ${expected_end}=                Evaluate  len($expected_hex) - ${index} * ${digits_count}
        ${expected_start}=              Evaluate  ${expected_end} - ${digits_count}
        Should Be Equal                 ${result_stripped}  0x${expected_hex}[${expected_start} : ${expected_end}]
    END

