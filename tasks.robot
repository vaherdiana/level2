*** Settings ***
Library    RPA.Browser.Selenium
Library    RPA.Tables
Library    RPA.HTTP
Library    RPA.PDF
Library    RPA.FileSystem
Library    RPA.Archive


Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Run Keyword And Ignore Error    Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Wait Until Keyword Succeeds    5x    2s    Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    
    [Teardown]    Close All Browsers
    Create a ZIP file of receipt PDF files



*** Variables ***
${FILE_LOCATION}=    https://robotsparebinindustries.com/orders.csv
${FILE_NAME}=    orders.csv
${ORDERING_PAGE}=    https://robotsparebinindustries.com/#/robot-order
${TEMP_FILE}=    -screenshot.png
${SCREENSHOTS}=     ${OUTPUT_DIR}${/}screenshots
${RESULT}=  ${OUTPUT_DIR}${/}result

*** Keywords ***
Open the robot order website
    Open Available Browser     ${ORDERING_PAGE}

Get orders
    Download    ${FILE_LOCATION}    overwrite=True
    ${data}=    Read Table From CSV    ${FILE_NAME}
    RETURN    ${data}

Close the annoying modal
    Click Button    css:.btn.btn-warning

Fill the form
    [Arguments]    ${row}
    Select From List By Value    id:head    ${row}[Head]
    Click Button    css=input[type='radio'][name='body'][value='${row}[Body]']
    Input Text    css=input[type='number']    ${row}[Legs]
    Input Text    id:address    ${row}[Address]

Preview the robot
    Click Button    id:preview
    # Capture Element Screenshot    id:robot-preview-image    filename=${TEMP_IMAGE_FILENAME}

Submit the order
    Click Button    id:order
    Page Should Contain Element    id:receipt

Store the receipt as a PDF file
    [Arguments]    ${order_no}
    ${receipt}=    Get Element Attribute    id:receipt    outerHTML
    ${file_path}=  Join Path    ${RESULT}    ${order_no}.pdf
    HTML To PDF    ${receipt}    ${file_path}    
    ...    margin=50
    RETURN    ${file_path}

Take a screenshot of the robot
    [Arguments]    ${order_no}
    Wait Until Element Is Visible    css:img[src*="heads"]
    Wait Until Element Is Visible    css:img[src*="bodies"]
    Wait Until Element Is Visible    css:img[src*="legs"]
    ${location}=     Set Variable    ${SCREENSHOTS}${/}${order_no}${TEMP_FILE}
    Capture Element Screenshot    id:robot-preview-image    ${location}
    RETURN    ${location}
    

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf_location}
    Open Pdf    ${pdf_location}
    Open Pdf    ${screenshot}
    ${files}=    Create List    ${screenshot}
    Add Files To PDF    ${files}    ${pdf_location}    append=True
    Close Pdf    ${pdf_location}
    Close Pdf    ${screenshot}


Go to order another robot
    Click Button    id:order-another

Create a ZIP file of receipt PDF files
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}${/}PDFs.zip
    Archive Folder With Zip
    ...    ${RESULT}
    ...    ${zip_file_name}
    Empty Directory    ${RESULT}
    Empty Directory    ${SCREENSHOTS}
    Remove Directory    ${RESULT}
    Remove Directory    ${SCREENSHOTS}


