*settings*
Library  Collections
Library  LibdocLib




*testcases*
t1
  ${col}  Create List  a1  a2
  Append To List  ${col}  a3
  Log To Console  ${col}
  Libdoc Lib Kw 1  arg1  arg2
