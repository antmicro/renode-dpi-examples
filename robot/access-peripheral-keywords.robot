*** Keywords ***
Get Width Of Access Type
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

Get Addresses For Data
    [Arguments]                     ${data}  ${access_width}  ${address_stride}=None

    ${address_stride}               Set Variable If  ${address_stride} == None  int(${access_width})  ${address_stride}

    ${range}=                       Evaluate  range(0, len($data), ${address_stride})
    RETURN                          ${range}

Get Value From Bytes
    [Arguments]                     ${bytes}  ${byte_start}  ${value_width}
    # Value is interpreted as little-endian.
    # Start byte is the least significant byte.
    ${start}=                       Evaluate  int(${byte_start}) + int(${value_width}) - 1
    ${stop}=                        Evaluate  - len($bytes) - 1 + int(${byte_start})
    ${data}=                        Evaluate  $bytes[$start : $stop : -1]
    RETURN                          ${data}

Get Hexadecimal Value From Bytes
    [Arguments]                     ${bytes}  ${start_byte}  ${value_width}
    ${value}=                       Get Value From Bytes  ${bytes}  ${start_byte}  ${value_width}
    ${hex_value}=                   Evaluate  "0x" + $value.hex().upper()
    RETURN                          ${hex_value}

Simple Write To Peripheral
    [Arguments]                     ${peripheral}  ${access_type}  ${address}  ${value}
    Execute Command                 ${peripheral} Write${access_type} ${address} ${value}

Should Peripheral Contain At Address
    [Arguments]                     ${peripheral}  ${access_type}  ${address}  ${value}
    ${result}=                      Execute Command  ${peripheral} Read${access_type} ${address}
    ${result_stripped}=             Strip String  ${result}
    Should Be Equal                 ${result_stripped}  ${value}

Loop Keyword Over Peripheral
    [Arguments]                     ${keyword}  ${peripheral}  ${access_type}  ${address_start}  ${data_hex}  ${address_stride}=None

    ${access_width}=                Get Width Of Access Type  ${access_type}
    ${data_bytes}=                  Evaluate  bytearray.fromhex("${data_hex}")
    ${byte_addresses}=              Get Addresses For Data  ${data_bytes}  ${access_width}  ${address_stride}

    FOR  ${byte_addr}  IN  @{byte_addresses}
        ${address}=                     Evaluate  hex(${address_start} + ${byte_addr})
        ${value}=                       Get Hexadecimal Value From Bytes  ${data_bytes}  ${byte_addr}  ${access_width}
        Run Keyword                     ${keyword}  ${peripheral}  ${access_type}  ${address}  ${value}
    END

Write To Peripheral
    [Arguments]                     ${peripheral}  ${access_type}  ${address_start}  ${data_hex}  ${address_stride}=None
    Loop Keyword Over Peripheral    Simple Write To Peripheral  ${peripheral}  ${access_type}  ${address_start}  ${data_hex}  ${address_stride}

Should Peripheral Contain
    [Arguments]                     ${peripheral}  ${access_type}  ${address_start}  ${data_hex}  ${address_stride}=None
    Loop Keyword Over Peripheral    Should Peripheral Contain At Address  ${peripheral}  ${access_type}  ${address_start}  ${data_hex}  ${address_stride}
