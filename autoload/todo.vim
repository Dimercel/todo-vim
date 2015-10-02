let g:loaded_todo = 1

let s:buf_name = "__todo__"

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

function! s:GetToDoPositions()
    let result = []
    let cur_pos = getcurpos()
    
    execute "normal! gg"
    
    let find_inx = searchpos('TODO', 'n')

    while find_inx != [0,0]
        call add(result, find_inx[0]) 

        call setpos(".", [0, find_inx[0]+1, 0, 0])
        let find_inx = searchpos('TODO', 'n', line("$"))
    endwhile

    call setpos(".", cur_pos)
    return result
endfunction

function! s:OpenWindow()
    let todowinnr = bufwinnr(s:buf_name)

    if todowinnr == -1
        let todo_inx = s:GetToDoPositions()

        silent keepalt botright vertical 30 split __todo__

        setlocal modifiable
        setlocal noreadonly
        execute "normal ggdG"

        silent  put =' ----------- TODO ----------- '

        if len(todo_inx) > 0
            for inx in todo_inx
                silent  put =' ' . inx . ' Text here.'
            endfor
        endif

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
    setlocal nowrap
    setlocal winfixwidth
    setlocal textwidth=0
    setlocal nospell
    setlocal nonumber
endfunction

function! todo#ToggleWindow() abort
    call s:ToggleWindow()
endfunction
