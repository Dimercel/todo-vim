let g:loaded_todo = 1

let s:buf_name = "__todo__"
let s:todo_info = {}
let s:todo_pattern = "TODO "


function! s:goto_win(winnr, ...) abort
    let cmd = type(a:winnr) == type(0) ? a:winnr . 'wincmd w'
                \ : 'wincmd ' . a:winnr
    let noauto = a:0 > 0 ? a:1 : 0

    if noauto
        noautocmd execute cmd
    else
        execute cmd
    endif
endfunction

function! s:ToggleWindow() abort
    let todowinnr = bufwinnr(s:buf_name)
    if todowinnr == -1
        call s:OpenWindow()
    else
        call s:CloseWindow()
    endif

endfunction

function! s:ToDoUpdate()
    let result = {}
    let cur_pos = getcurpos()

    execute "normal! gg"

    let find_inx = searchpos(s:todo_pattern, 'cn')

    while find_inx != [0,0]
        let line_text = getline(find_inx[0])
        let todo_text = strpart(line_text, matchend(line_text, s:todo_pattern))
        let result[find_inx[0]] = todo_text

        call setpos(".", [0, find_inx[0]+1, 0, 0])

        if find_inx[0] == line("$")
            break
        endif

        let find_inx = searchpos(s:todo_pattern, 'cn', line("$"))
    endwhile

    call setpos(".", cur_pos)
    let s:todo_info = result
endfunction

function! s:OpenWindow()
    let todowinnr = bufwinnr(s:buf_name)

    if todowinnr == -1
        call s:ToDoUpdate()

        silent keepalt botright vertical 30 split __todo__

        setlocal modifiable
        setlocal noreadonly
        execute "normal! ggdG"

        silent 0put = '\" TODO'
        silent  put _

        let sort_keys = sort(keys(s:todo_info), 'n')
        for line_inx in sort_keys
            silent put = line_inx . ': ' . s:todo_info[line_inx]
        endfor

        call s:InitWindow()
        call s:goto_win("p")
    endif
endfunction

function! s:CloseWindow()
    let todowinnr = bufwinnr(s:buf_name)

    if todowinnr != -1
        call s:goto_win(todowinnr)
        close
        call s:goto_win("p")
    endif
endfunction

function! s:InitWindow() abort

    setlocal filetype=todo

    setlocal readonly
    setlocal buftype=nofile
    setlocal bufhidden=hide
    setlocal noswapfile
    setlocal nobuflisted
    setlocal nomodifiable
    setlocal nolist
    setlocal wrap
    setlocal winfixwidth
    setlocal textwidth=0
    setlocal nospell
    setlocal nonumber
endfunction

function! todo#ToggleWindow() abort
    call s:ToggleWindow()
endfunction
