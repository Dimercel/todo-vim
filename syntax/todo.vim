scriptencoding utf-8

if exists("b:current_syntax")
    finish
endif


syntax match ToDoLineNum '\v^\d+'
syntax match ToDoTitle   '^".*'
syntax match ToDoTag     '\v\@[^\ ]+'


hi def link ToDoLineNum Number
hi def link ToDoTitle   Comment
hi def link ToDoTag     Special

let b:current_syntax = "todo"
