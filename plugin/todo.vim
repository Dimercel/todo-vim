scriptencoding utf-8


if &cp || exists('g:loaded_todo')
    finish
endif

if !exists('g:todo_win_width')
    let g:todo_win_width = 30
endif

command! -nargs=0 TODOToggle  call todo#ToggleWindow()
