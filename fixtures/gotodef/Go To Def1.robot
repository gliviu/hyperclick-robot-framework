


*** Keywords ***
test gotodef 1
    test gotodef 4
test gotodef 2
    test gotodef 1
test gotodef 5
    [Arguments]    ${arg1}    &{arg2}
    test gotodef 2
    [Return]    ${arg1}
test gotodef 6
    [Arguments]    ${arg1}    &{arg2}
    test gotodef 2
    [Return]    ${arg1}

