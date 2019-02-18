*settings*
Library  gotodeflib1
Library  gotodeflib2
Resource  ${1}/kw1.robot
Resource  ${2}/kw2.robot

Resource  ${2}/kw4.robot








*** test cases ***
test gotodef 1
    Impkw
    impkwx
    impkwy
    gotodeflib1.My Third Keyword
    gotodeflib2.My Third Keyword
