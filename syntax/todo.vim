scriptencoding utf-8

if exists("b:current_syntax")
    finish
endif


syntax match ToDoLine '^\d+\:'


hi def link ToDoLine Identifier 

let b:current_syntax = "todo"
