*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library            RPA.Browser.Selenium        auto_close=${FALSE}
Library            RPA.HTTP
Library            RPA.Tables
Library            RPA.PDF
Library            RPA.Archive
Library            RPA.Dialogs
Library        RPA.Robocorp.Vault
*** Variables ***
${CSV_FILE_NAME}=                      orders.csv
${CSV_FILE_URL}=                       https://robotsparebinindustries.com/${CSV_FILE_NAME}
${PDF_TEMP_OUTPUT_DIRECTORY}=          ${OUTPUT_DIR}        


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    # ${CSV_FILE_URL}=    Input CSV file URL
    ${var}=    Get Secret    Orders_Data_URL
    ${CSV_FILE_URL}=    set Variable    ${var}[Order_Data]
    Open the robot order website
    ${orders}=    Get orders
    Log    ${orders}
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Wait Until Keyword Succeeds    5x    3s    Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts

*** Keywords ***
Input CSV file URL
    Add text input    CSVInputFile    label=Enter Orders CSV File URL
    ${response}=    Run dialog
    RETURN    ${response.CSVInputFile}
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order
    Maximize Browser Window
Get orders
     Download    ${CSV_FILE_URL}    overwrite=True
     ${orders}=    Read table from CSV        ${CSV_FILE_NAME}
     RETURN        ${orders}
Close the annoying modal
    Click Button    //button[text()='OK']
Fill the form
    [Arguments]    ${Order}
    Select From List By Index    head   ${Order}[Head]
    ${Radio_button_Xpath}=    Set Variable    //input[contains(@id,'id-body-${Order}[Body]')]
    # ${Radio_button_Xpath}=    Evaluate    //input[@id='id-body-${Order}[Body]']
    Click Element    ${Radio_button_Xpath}
    Input Text    //label[contains(text(),'Legs')]//..//input    ${Order}[Legs]
    Input Text    address    ${Order}[Address]
    
    
Preview the robot
    Click Button    preview
    Capture Element Screenshot    robot-preview-image
Submit the order
    Click Button    order
    # Wait Until Element Is Visible    receipt
    Element Should Be Visible    receipt
Store the receipt as a PDF file
    [Arguments]    ${FileName}
    Wait Until Element Is Visible    receipt
    ${sales_results_html}=    Get Element Attribute    receipt    outerHTML
    Html To Pdf    ${sales_results_html}    ${OUTPUT_DIR}${/}${FileName}.pdf
    RETURN     ${OUTPUT_DIR}${/}${FileName}.pdf
Take a screenshot of the robot
    [Arguments]    ${FileName}
    Screenshot    robot-preview-image    ${OUTPUT_DIR}${/}Images${/}${FileName}.png
    RETURN     ${OUTPUT_DIR}${/}Images${/}${FileName}.png
Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    ${files}=    Create List
    ...        ${screenshot}
    Add Files To Pdf    ${files}    ${pdf}    true
    Close Pdf
Go to order another robot
    Click Button    order-another
    Wait Until Element Is Visible    //button[text()='OK']
    # Close the annoying modal
Create a ZIP file of the receipts
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/PDFs.zip
    Archive Folder With Zip
    ...    ${PDF_TEMP_OUTPUT_DIRECTORY}
    ...    ${zip_file_name}