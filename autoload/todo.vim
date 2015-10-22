let g:loaded_todo = 1

let s:buf_name = "__todo__"
let s:todo_info = {}
let s:todo_patterns = ["TODO[^a-zA-Z]", "FIXME[^a-zA-Z]"]
let s:tag_pattern = "\@[^\ ]+"

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

function! s:GetAllMatches(text, pattern)
    let result = []

    let offset = 0
    while offset != -1
        let find_inx_end = matchend(a:text, a:pattern, offset)
        let find_inx_begin = match(a:text, a:pattern, offset)

        if find_inx_end != -1 && find_inx_begin != -1
            let match = strpart(a:text, find_inx_begin, find_inx_end - find_inx_begin)
            call add(result, match)
        endif

        let offset = find_inx_end
    endwhile

    return result
endfunction

function! s:StrTrim(str)
    let result = substitute(a:str, '\v^\s+', '', '')
    let result = substitute(result, '\v\s+$', '', '')

    return result
endfunction

function! s:GetMatch(text, pattern, start)
    let result = ""

    let find_inx_end = matchend(a:text, a:pattern, a:start)
    let find_inx_begin = match(a:text, a:pattern, a:start)

    if find_inx_end == -1
        return ""
    endif

    let result = strpart(a:text, find_inx_begin, find_inx_end - find_inx_begin)

    return result
endfunction

function! s:ParseToDoLine(text, pattern)
    let result = {}

    let result.patt = s:GetMatch(a:text, a:pattern, 0)
    let result.tags = s:GetAllMatches(a:text, s:tag_pattern)

    let result.text = s:StrTrim(strpart(a:text, matchend(a:text, result.patt)))

    return result
endfunction

function! s:ToDoUpdate()
    let result = {}
    let cur_pos = getcurpos()

    call setpos('.', [0,0,0,0])


    for search_pat in s:todo_patterns
        let find_inx = searchpos(search_pat, 'cn')

        while find_inx != [0,0]
            let line_text = getline(find_inx[0])
            let info = s:ParseToDoLine(line_text, search_pat)

            let result[find_inx[0]] = info

            call setpos(".", [0, find_inx[0]+1, 0, 0])

            if find_inx[0] == line("$")
                break
            endif

            let find_inx = searchpos(search_pat, 'cn', line("$"))
        endwhile
    endfor

    call setpos(".", cur_pos)
    let s:todo_info = result
endfunction

function! s:OpenWindow()
    let todowinnr = bufwinnr(s:buf_name)

    if todowinnr == -1
        call s:ToDoUpdate()

        execute 'silent keepalt botright vertical '.g:todo_win_width.' split __todo__'

        setlocal modifiable
        setlocal noreadonly
        execute "normal! ggdG"

        silent 0put = '\" TODO'
        silent  put _

        let sort_keys = sort(map(keys(s:todo_info), 'str2nr(v:val)'), 'n')
        for line_inx in sort_keys
            silent put = line_inx . ': ' . s:todo_info[line_inx].text
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
