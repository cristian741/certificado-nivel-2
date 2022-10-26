*** Settings ***
Documentation       Template robot main suite.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.FileSystem
Library             RPA.HTTP
Library             RPA.Archive
Library             Dialogs
Library             RPA.Robocloud.Secrets
Library             RPA.core.notebook


*** Tasks ***
Listas de tareas a ejecutar
    Ciclo if para crear directorio de carpeta
    Descargar csv
    ${dato}=    Leer el archivo pedido
    Abrir navegador
    Repetir carga    ${dato}
    Zip the reciepts folder
    [Teardown]    Close Browser


*** Keywords ***
Abrir navegador
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order
    Maximize Browser Window

Descargar csv
    ${csv_archivo}=    Get Value From User
    ...    Ingrese la url del archivo csv
    ...    https://robotsparebinindustries.com/orders.csv
    Download    ${csv_archivo}    orders.csv
    Sleep    2 seconds

Crear directorio y eliminar directorio
    [Arguments]    ${folder}
    Remove Directory    ${folder}    True
    Create Dictionary    ${folder}

Ciclo if para crear directorio de carpeta
    Remove File    ${CURDIR}${/}orders.csv
    ${reciept_folder}=    Does Directory Exist    ${CURDIR}${/}recipiente
    ${robots_folder}=    Does Directory Exist    ${CURDIR}${/}robots
    IF    '${reciept_folder}'=='True'
        Crear directorio y eliminar directorio    ${CURDIR}${/}recipiente
    ELSE
        Create Directory    ${CURDIR}${/}recipiente
    END
    IF    '${robots_folder}'=='True'
        Crear directorio y eliminar directorio    ${CURDIR}${/}robots
    ELSE
        Create Directory    ${CURDIR}${/}robots
    END

Leer el archivo pedido
    ${dato}=    Read table from CSV    ${CURDIR}${/}orders.csv    header='True'
    RETURN    ${dato}

Precionar boton ok ventana principal y llenar formulario
    [Arguments]    ${valor}
    Wait Until Page Contains Element    //button[@class="btn btn-dark"]
    Click Button    //button[@class="btn btn-dark"]
    Select From List By Value    //select[@name="head"]    ${valor}[Head]
    Click Element    //input[@value=${valor}[Body]]
    Input Text    //input[@placeholder="Enter the part number for the legs"]    ${valor}[Legs]
    Input Text    //input[@id="address"]    ${valor}[Address]
    Click Button    //button[@id="preview"]
    Wait Until Page Contains Element    //div[@id="robot-preview-image"]
    Sleep    5 seconds
    Click Button    //button[@id="order"]
    Sleep    5 seconds

Cierre e inicie el navegador antes de otra transacción
    Close Browser
    Open Browser

Cargar
    FOR    ${i}    IN RANGE    ${100}
        ${alerta}=    Is Element Visible    //div[@class="alert alert-danger"]
        IF    '${alerta}'=='True'    Click Button    //button[@id="order"]
        IF    '${alerta}'=='False'            BREAK
    END
    IF    '${alerta}'=='True'
        Cierre e inicie el navegador antes de otra transacción
    END

Recibir los resultados finales y pasar a PDF
    [Arguments]    ${valor}
    Sleep    5 seconds
    ${reciept_data}=    Get Element Attribute    //div[@id="receipt"]    outerHTML
    Html To Pdf    ${reciept_data}    ${CURDIR}${/}recipiente${/}${valor}[Order number].pdf
    Screenshot    //div[@id="robot-preview-image"]    ${CURDIR}${/}robots${/}${valor}[Order number].png
    Add Watermark Image To Pdf
    ...    ${CURDIR}${/}robots${/}${valor}[Order number].png
    ...    ${CURDIR}${/}recipiente${/}${valor}[Order number].pdf
    ...    ${CURDIR}${/}recipiente${/}${valor}[Order number].pdf
    Click Button    //button[@id="order-another"]

Repetir carga
    [Arguments]    ${dato}
    FOR    ${valor}    IN    @{dato}
        Precionar boton ok ventana principal y llenar formulario    ${valor}
        Cargar
        Recibir los resultados finales y pasar a PDF    ${valor}
    END

Zip the reciepts folder
    Archive Folder With Zip    ${CURDIR}${/}recipiente    ${OUTPUT_DIR}${/}recipiente.zip
