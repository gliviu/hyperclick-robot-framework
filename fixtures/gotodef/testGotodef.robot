**** Keywords ***
test gotodef 0
    test gotodef 0
    test gotodef 1
    test gotodef 2
    test gotodef 3
    test gotodef 4
    test gotodef 5
    test gotodef 6
    test gotodef 7
    test gotodef 8
test gotodef 5
    test gotodef 0
    test gotodef 1
    test gotodef 2
    test gotodef 3
    test gotodef 4
    test gotodef 5
    test gotodef 6
    test gotodef 7
    test gotodef 8
    Run Keyword If    cond=true
    log  Run Keyword If    condition=true    test gotodef 3    ${aa}
