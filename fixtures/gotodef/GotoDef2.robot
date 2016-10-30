
*** Keywords ***
test gotodef 3
    test gotodef 1
test gotodef 4
    test gotodef 3
test gotodef 5
    [Arguments]    ${arg1}    &{arg2}
    test gotodef 6    ${arg1}    ${arg2}
    [Return]    ${arg1}
test gotodef 7
    [Arguments]    ${arg1}    &{arg2}
    test gotodef 8    ${arg1}    ${arg2}
    [Return]    ${arg1}
