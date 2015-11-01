scriptencoding utf-8

if exists("b:current_syntax")
    finish
endif


syntax match ToDoTitle  '^".*'
syntax match ToDoTag    '\v\@[^\ ]+(\ [^\ ]+)?' contains=ToDoTagArg
syntax match ToDoTagArg '\v\ [^\ ]+' contained
syntax match ToDoType   '\v^\[\w+\]'


hi def link ToDoTitle   Comment
hi def link ToDoTag     Special
hi def link ToDoTagArg  Statement
hi def link ToDoType    PreProc

let b:current_syntax = "todo"
