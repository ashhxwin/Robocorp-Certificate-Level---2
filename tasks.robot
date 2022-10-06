*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Robocorp.Vault
Library           RPA.Dialogs
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.PDF
Library           RPA.Archive
Library           RPA.FileSystem
Task Setup        Reset Temp Folder
Task Teardown     Reset Temp Folder

*** Variables ***
&{ASSETS}
${TEMP_DIR}=      temp

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${ASSETS}=    Get Secret    assets
    Open the robot order website    ${ASSETS}[target_url]
    ${orders}=    Get orders    ${ASSETS}[orderfile_url]
    FOR    ${order}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${order}
        Wait Until Keyword Succeeds    30s    1s    Preview the robot
        Wait Until Keyword Succeeds    30s    1s    Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${order}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${order}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    [Teardown]    myTeardown

*** Keywords ***
Reset Temp Folder
    ${dir_exists}=    Does Directory Exist    ${TEMP_DIR}
    IF    ${dir_exists}
        Remove Directory    ${TEMP_DIR}    recursive=True
    END
    Create Directory    ${TEMP_DIR}

Open the robot order website
    [Arguments]    ${url}
    Log    ${url}
    Open Available Browser    ${url}    maximized=true

Get orders
    [Arguments]    ${url}
    Download    ${url}    ${TEMP_DIR}${/}orders.csv    overwrite=True
    ${orders}=    Read table from CSV    ${TEMP_DIR}${/}orders.csv
    Log    Found columns: ${orders.columns}
    [Return]    ${orders}

Close the annoying modal
    Click Button    xpath://button[contains(.,'OK')]

Fill the form
    [Arguments]    ${row}
    Wait Until Element Is Visible    id:head
    Select From List By Value    id:head    ${row}[Head]
    Click Element    xpath=//*[@id="id-body-${row}[Body]"]
    Input Text    xpath=//input[@placeholder="Enter the part number for the legs"]    ${row}[Legs]
    Input Text    css:#address    ${row}[Address]

Preview the robot
    Click Element    id:preview
    Wait Until Element Is Visible    id:preview    2s

Submit the order
    Click Element    id:order
    Wait Until Element Is Visible    id:order-completion    2s

Store the receipt as a PDF file
    [Arguments]    ${order_number}
    ${order_completion_html}=    Get Element Attribute    id:order-completion    innerHTML
    Html To Pdf    ${order_completion_html}    ${TEMP_DIR}${/}orders${/}order_${order_number}.pdf

Take a screenshot of the robot
    [Arguments]    ${order_number}
    Screenshot    id:robot-preview-image    ${TEMP_DIR}${/}previews${/}robot_preview_${order_number}.png
    Open Pdf    ${TEMP_DIR}${/}orders${/}order_${order_number}.pdf
    ${files}=    Create List    ${TEMP_DIR}${/}previews${/}robot_preview_${order_number}.png
    Add Files To Pdf    ${files}    ${TEMP_DIR}${/}orders${/}order_${order_number}.pdf    append=True
    Close Pdf

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    No Operation

Go to order another robot
    Click Element    id:order-another

Create a ZIP file of the receipts
    Archive Folder With ZIP    ${TEMP_DIR}${/}orders    ${OUTPUT_DIR}${/}orders.zip    recursive=False    include=order*.pdf

Close the browser
    Add icon    Warning
    Add heading    Close the browser?
    Add submit buttons    buttons=No,Yes    default=Yes
    ${result}=    Run dialog
    IF    $result.submit == "Yes"
        Close Browser
    END

myTeardown
    Create a ZIP file of the receipts
    Close the browser
    Reset Temp Folder
