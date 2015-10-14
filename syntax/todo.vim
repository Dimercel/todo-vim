scriptencoding utf-8

if exists("b:current_syntax")
    finish
endif


syntax match ToDoLineNum '\v^\d+'
syntax match ToDoTitle   '^".*'


hi def link ToDoLineNum Number
hi def link ToDoTitle   Comment

let b:current_syntax = "todo"
