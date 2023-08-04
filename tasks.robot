*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Archive
Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.Tables
Library             RPA.HTTP
Library             RPA.PDF
Library             String


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the Website
    Download the Order CSV
    Get Orders
    Close the annoying modal
    Fill the form using the csv file
    Create a ZIP file of receipt PDF files
    Log    Done.


*** Keywords ***
Open the Website
    Open Available Browser    https://robotsparebinindustries.com

Download the Order CSV
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True

Get Orders
    ${orders}=    Read table from CSV    orders.csv
    Log    Found columns: ${orders.columns}
    RETURN    ${orders}

Fill the form using the csv file
    ${orders}=    Get Orders
    FOR    ${order}    IN    @{orders}
        Log    ${order}
        Select From List By Index    id:head    ${order}[Head]
        Select Radio Button    body    ${order}[Body]
        Input Text    class:form-control    ${order}[Legs]
        Input Text    address    ${order}[Address]
        Click Button    Preview
        ${screenshot}=    Take a screenshot of the robot    ${order}
        Wait Until Keyword Succeeds    5    0.5s    Try to submit order    ${order}

        Embed the robot screenshot to the receipt PDF file    ${order}    ${screenshot}
        Click Button    Yep
    END

Close the annoying modal
    Click Link    Order your robot!
    Click Button    Yep

Try to submit order
    [Arguments]    ${order}
    Click Button    Order
    Store the receipt as a PDF    ${order}
    Click Button    order-another

Store the receipt as a PDF
    [Arguments]    ${order}
    ${order_receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${order_receipt_html}    $(OUTPUT_DIR)${/}receipts${/}${order}[Order number].Pdf

Take a screenshot of the robot
    [Arguments]    ${order}
    Screenshot    id:robot-preview-image    $(OUTPUT_DIR)${/}screenshots${/}${order}[Order number].png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${order}    ${screenshot}

    Open Pdf    $(OUTPUT_DIR)${/}receipts${/}${order}[Order number].Pdf
    Add Watermark Image To Pdf
    ...    $(OUTPUT_DIR)${/}screenshots${/}${order}[Order number].png
    ...    $(OUTPUT_DIR)${/}receipts${/}${order}[Order number].Pdf
    Close PDF

Create a ZIP file of receipt PDF files
    Archive Folder With Zip    $(OUTPUT_DIR)${/}receipts    $(OUTPUT_DIR)${/}Final Receipts.zip
