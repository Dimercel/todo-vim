let g:loaded_todo = 1

let s:buf_name        = '__todo__'
let s:todo_info       = []
let s:todo_type       = ['todo', 'fixme', 'note']
let s:todo_patterns   = ["TODO[^a-zA-Z]", "FIXME[^a-zA-Z]", "NOTE[^a-zA-Z]"]
let s:tag_arg_pattern = '\v\:(\"[^\"]+\"|[^\ ]+)'
let s:tag_pattern     = '\v\@[^\ ]+(\ ' . strpart(s:tag_arg_pattern, 2) . ')?'
let s:sort_comp       = 's:LineComparator' " Default sort labels by line
let s:help_view       = 0


" Functions for working with windows
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
    setlocal textwidth=0
    setlocal nospell
    setlocal nonumber

    call s:MappingKeys()

    if exists('g:todo_winheight')
        execute 'resize ' . g:todo_winheight . '<CR>'
    endif

    if exists('g:todo_vertical') && exists('g:todo_right') 
      execute 'wincmd L'
    endif

    if exists('g:todo_winwidth')
      execute 'vertical resize ' . g:todo_winwidth . '<CR>'
    endif

endfunction

function! s:OpenWindow()
    let todowinnr = bufwinnr(s:buf_name)

    if todowinnr == -1
        call s:OpenWinAndStay()
        call s:goto_win("p")
    endif
endfunction

function! s:OpenWinAndStay()
    let todowinnr = bufwinnr(s:buf_name)
    let ksplit = exists('g:todo_vertical') ? 'vsplit' : 'split'

    if todowinnr == -1
        call s:ToDoUpdate()

        execute 'silent keepalt topleft '.ksplit.' '.s:buf_name

        call s:InitWindow()
        call s:UpdateWindow()

        call setpos('.', [0,0,0,0])
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

function! s:ToggleWindow() abort
    let todowinnr = bufwinnr(s:buf_name)
    if todowinnr == -1
        call s:OpenWindow()
    else
        call s:CloseWindow()
    endif

endfunction

function! s:UpdateWindow()
    if s:help_view == 1
        return
    endif

    let cursor_pos = getcurpos()

    setlocal modifiable
    setlocal noreadonly
    execute "normal! ggdG"

    if len(s:todo_info) == 0
        silent 0put ='\" Nothing yet'
    else
        silent 0put ='\" Press ? for help'
        silent put _

        let s:todo_info = sort(s:todo_info, s:sort_comp)
        for item in s:todo_info
            silent put = s:GetInfoStr(item)
        endfor
    endif

    " Erase last space string
    execute "normal! Gdd"

    setlocal nomodifiable
    setlocal readonly

    call setpos('.', cursor_pos)
endfunction


" Functions for sorting labels
function! s:TypeComparator(lval, rval)
    return a:lval.type == a:rval.type ? 0 : a:lval.type < a:rval.type ? -1 : 1
endfunction

function! s:LineComparator(lval, rval)
    return a:lval.line == a:rval.line ? 0 : a:lval.line > a:rval.line ? 1 : -1
endfunction

function! s:PriorityComparator(lval, rval)
    let lpriority = -1
    let lpri_tag = filter(copy(a:lval.tags), 'v:val.name ==# "@p"')

    if len(lpri_tag) != 0
        let lpriority = str2nr(lpri_tag[0].arg)
    endif

    let rpriority = -1
    let rpri_tag = filter(copy(a:rval.tags), 'v:val.name ==# "@p"')

    if len(rpri_tag) != 0
        let rpriority = str2nr(rpri_tag[0].arg)
    endif

    return lpriority == rpriority ? 0 : lpriority < rpriority ? 1 : -1
endfunction

function! s:AuthorComparator(lval, rval)
    let lauthor = "\uFFFF"
    let laut_tag = filter(copy(a:lval.tags), 'v:val.name ==# "@author"')

    if len(laut_tag) != 0
        let lauthor = laut_tag[0].arg
    endif

    let rauthor = "\uFFFF"
    let raut_tag = filter(copy(a:rval.tags), 'v:val.name ==# "@author"')

    if len(raut_tag) != 0
        let rauthor = raut_tag[0].arg
    endif

    return lauthor == rauthor ? 0 : lauthor > rauthor ? 1 : -1
endfunction

function! s:SetSortByType()
    let s:sort_comp = 's:TypeComparator'
endfunction

function! s:SetSortByPriority()
    let s:sort_comp = 's:PriorityComparator'
endfunction

function! s:SetSortByLine()
    let s:sort_comp = 's:LineComparator'
endfunction

function! s:SetSortByAuthor()
    let s:sort_comp = 's:AuthorComparator'
endfunction


" Utilites function
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

function! s:StrTrim(str, ... )
    let re = '\s+'

    if a:0 > 0
        let re = a:1
    endif

    let result = substitute(a:str, '\v^'.re, '', '')
    let result = substitute(result, '\v'.re.'$', '', '')

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


" Functions for working with labels
function! s:ParseToDoLine(text, pattern)
    let result = {}

    let result.patt = s:GetMatch(a:text, a:pattern, 0)
    let tags = s:GetAllMatches(a:text, s:tag_pattern)
    let result.tags = []

    for tag_text in tags
        call add(result.tags, s:ParseTag(tag_text))
    endfor

    let result.text = strpart(a:text, matchend(a:text, result.patt))
    let result.text = s:StrTrim(substitute(result.text, s:tag_pattern, '', 'g'))

    return result
endfunction

function! s:ParseTag(text)
    let tag = {}

    let tag.arg = s:StrTrim(s:GetMatch(a:text, s:tag_arg_pattern, 0))
    let tag.name = s:StrTrim(strpart(a:text, 0, strlen(a:text) - strlen(tag.arg)))

    " cut off ':'
    if strlen(tag.arg) != 0
        let tag.arg = strpart(tag.arg, 1)
    endif

    " cut '"' if exist
    let tag.arg = s:StrTrim(tag.arg, '\"')

    return tag
endfunction

function! s:ToDoUpdate()
    let result = []
    let cur_pos = getcurpos()

    for inx in range(len(s:todo_patterns))
        call setpos('.', [0,0,0,0])

        let search_pat = s:todo_patterns[inx]
        let pat_type = s:todo_type[inx]
        let find_inx = searchpos(search_pat, 'cn')

        while find_inx != [0,0]
            let line_text = getline(find_inx[0])
            let info = s:ParseToDoLine(line_text, search_pat)
            let info.type = pat_type
            let info.line = find_inx[0]

            call add(result, info)

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

" Create string describing label
function! s:GetInfoStr(todo_item)

    let result = '[' . a:todo_item.type . '] ' .  a:todo_item.text

    if len(a:todo_item.tags) > 0
        let result .= " "
        for tag in a:todo_item.tags
            if !has_key(tag, 'arg') || tag.arg == ''
                let result .= tag.name . " "
            else
                let result .= tag.name . " " . tag.arg . " "
            endif
        endfor
    endif

    return s:StrTrim(result)
endfunction



function! s:GetLabelByCursorPos()
    let label_info_line_inx = 3

    if bufname('%') != s:buf_name
        return {}
    endif

    "range of string indexes with info about labels
    let avail_range = [label_info_line_inx, label_info_line_inx +
                \ (len(s:todo_info)-1)]

    let cur_line = line(".")
    if cur_line < avail_range[0] || cur_line > avail_range[1]
        return {}
    endif

    return get(s:todo_info, cur_line - avail_range[0], {})
endfunction

function! s:ViewActiveLabel()
    let label_info = s:GetLabelByCursorPos()

    if label_info == {}
        return
    endif

    call s:goto_win('p')
    call setpos('.', [0,label_info.line,0,0])
    normal! zz
    call s:goto_win(bufwinnr(s:buf_name))
endfunction

function! s:MoveToActiveLabel()
    call s:ViewActiveLabel()
    call s:CloseWindow()
endfunction

" Deletes label under cursor
function! s:RemoveLabel()
    let label_info = s:GetLabelByCursorPos()

    if label_info == {}
        return
    endif

    call s:goto_win('p')
    call setpos('.', [0,label_info.line,0,0])
    normal! dd

    call s:ToDoUpdate()
    call s:goto_win(bufwinnr(s:buf_name))
endfunction

function! s:getTagArg(label, tag_name, null)
    if len(a:label.tags) == 0
        return a:null
    endif

    for tag in a:label.tags
        if tag.name ==# a:tag_name && has_key(tag, 'arg')
            return tag.arg
        endif
    endfor

    return a:null
endfunction

function! s:setTagArg(label, tag_name, arg)
    if len(a:label.tags) == 0
        return
    endif

    for tag in a:label.tags
        if tag.name ==# a:tag_name
            let tag.arg = a:arg
        endif
    endfor
endfunction

function! s:ChangeLabelPriority(inc_val)
    let label = s:GetLabelByCursorPos()

    if label == {}
        return
    endif

    let arg = s:getTagArg(label, '@p', -1)

    if arg == 0 && arg + a:inc_val < 0
        return
    endif

    call s:goto_win('p')
    if arg == -1
        call add(label.tags, {'name': '@p', 'arg' : '0'})

        let label_text = getline(label.line)
        let label_text .= ' @p :0'

        call setline(label.line, label_text)
    else
        call s:setTagArg(label, '@p', ''.arg + a:inc_val)

        let label_text = getline(label.line)
        let priority_str = '@p :' . (arg + a:inc_val)

        let label_text = substitute(label_text, '\v\@p\ :\d+', priority_str, '')
        call setline(label.line, label_text)
    endif

    call s:goto_win(bufwinnr(s:buf_name))
endfunction


function! s:ToggleHelp()
    if s:help_view == 1
        let s:help_view = 0

        call s:UpdateWindow()
        return
    else
        let s:help_view = 1
    endif

    setlocal modifiable
    setlocal noreadonly
    execute "normal! ggdG"

    silent 0put ='\" Press ? for help'
    silent put _
    silent put = '\" ---------General-------- -------Sorting------ ------Priority-------'
    silent put = '\" <CR>: Jump to the label  sp: Sort by priority ip: Increase priority'
    silent put = '\" q: Close todo-vim window sl: Sort by line     dp: Decrease priority'
    silent put = '\" p: View label in buffer  st: Sort by type   '
    silent put = '\" dd: Delete label         sa: Sort by author '
    silent put = '\" r: Update window                            '

    " Erase last space string
    execute "normal! Gdd"

    setlocal nomodifiable
    setlocal readonly

    call setpos('.', [0,0,0,0])
endfunction

function! s:BuildAutoCmds() abort
    augroup TODOAutoCmds
        autocmd!
        if g:todo_autopreview
            execute 'autocmd CursorMoved ' . s:buf_name . ' nested call s:ViewActiveLabel()'
        endif
    augroup END
endfunction

function! s:MappingKeys() abort
    nnoremap <script> <silent> <buffer> sp :call <SID>SetSortByPriority()<CR> :call <SID>UpdateWindow()<CR>
    nnoremap <script> <silent> <buffer> sl :call <SID>SetSortByLine()<CR> :call <SID>UpdateWindow()<CR>
    nnoremap <script> <silent> <buffer> st :call <SID>SetSortByType()<CR> :call <SID>UpdateWindow()<CR>
    nnoremap <script> <silent> <buffer> sa :call <SID>SetSortByAuthor()<CR> :call <SID>UpdateWindow()<CR>
    nnoremap <script> <silent> <buffer> r  :call <SID>UpdateWindow()<CR>
    nnoremap <script> <silent> <buffer> q  :call <SID>CloseWindow()<CR>
    nnoremap <script> <silent> <buffer> <CR> :call <SID>MoveToActiveLabel()<CR>
    nnoremap <script> <silent> <buffer> p  :call <SID>ViewActiveLabel()<CR>
    nnoremap <script> <silent> <buffer> ip :call <SID>ChangeLabelPriority(1)<CR> :call <SID>UpdateWindow()<CR>
    nnoremap <script> <silent> <buffer> dp :call <SID>ChangeLabelPriority(-1)<CR> :call <SID>UpdateWindow()<CR>
    map      <script> <silent> <buffer> dd :call <SID>RemoveLabel()<CR> :call <SID>UpdateWindow()<CR>
    map      <script> <silent> <buffer> ?  :call <SID>ToggleHelp()<CR>
endfunction

function! s:Init() abort
    call s:BuildAutoCmds()
endfunction

call s:Init()

function! todo#ToggleWindow() abort
    call s:ToggleWindow()
endfunction

function! todo#OpenWindow() abort
    call s:OpenWinAndStay()
endfunction

function! todo#CloseWindow() abort
    call s:CloseWindow()
endfunction
