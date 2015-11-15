scriptencoding utf-8


if &cp || exists('g:loaded_todo')
    finish
endif

if !exists('g:todo_autopreview')
    let g:todo_autopreview = 0
endif

command! -nargs=0 TODOToggle call todo#ToggleWindow()
command! -nargs=0 TODOOpen   call todo#OpenWindow()
command! -nargs=0 TODOClose  call todo#OpenWindow()
