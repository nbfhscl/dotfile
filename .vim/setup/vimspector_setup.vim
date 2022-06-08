let s:mapped = {}
if has('nvim') 
    let maplocalleader = "\\"
else 
    let maplocalleader = "\\"
endif

nnoremap <leader>dD :VimspectorReset<CR>

command! -nargs=* GoLaunch :call vimspector#LaunchWithConfigurations({
            \  "Go Launch": {
            \    "adapter": "delve", 
            \    "configuration": {
            \      "request":"launch",
            \      "program": "${cwd}",
            \      "mode":"debug",
            \      "args": [<f-args>]
            \    }
            \  }
            \})
autocmd FileType go nnoremap <buffer> ;dd :GoLaunch<CR>

" let g:vimspector_install_gadgets = ['delve']
" let g:vimspector_enable_mappings = 'HUMAN'
nmap <silent><nowait> <leader>bb <Plug>VimspectorToggleBreakpoint
nmap <silent><nowait> <leader>bf <Plug>VimspectorAddFunctionBreakpoint
nmap <silent><nowait> <leader>bc <Plug>VimspectorToggleConditionalBreakpoint
nmap <silent><nowait> <leader>K <Plug>VimspectorBalloonEval<CR>

" ask/always/never
let g:ycm_java_hotcodereplace_mode = 'ask'

" " prevent breakpoint override by gitgutter
" let g:vimspector_sign_priority = {
"   \    'vimspectorBP':         31,
"   \    'vimspectorBPCond':     21,
"   \    'vimspectorBPLog':      21,
"   \    'vimspectorBPDisabled': 11,
"   \    'vimspectorPC':         999,
"   \ }

function! s:OnJumpToFrame() abort
  if has_key( s:mapped, string( bufnr() ) )
    return
  endif

  nmap <silent><nowait><buffer> <LocalLeader>1 <Plug>VimspectorStepOver
  nmap <silent><nowait><buffer> <LocalLeader>2 <Plug>VimspectorStepInto
  nmap <silent><nowait><buffer> <LocalLeader>3 <Plug>VimspectorContinue
  nmap <silent><nowait><buffer> <LocalLeader>4 <Plug>VimspectorStepOut
  nmap <silent><nowait><buffer> <LocalLeader>5 <Plug>VimspectorRunToCursor
  nmap <silent><nowait><buffer> <LocalLeader>6 <Plug>VimspectorBalloonEval
  nmap <silent><nowait><buffer> <LocalLeader>7 <Plug>VimspectorPause
  nmap <silent><nowait><buffer> <LocalLeader>8 <Plug>VimspectorRestart
  nmap <silent><nowait><buffer> <LocalLeader>9 <Plug>VimspectorStop

  let s:mapped[ string( bufnr() ) ] = { 'modifiable': &modifiable }

  " setlocal nomodifiable

endfunction

function! s:OnDebugEnd() abort

  let original_buf = bufnr()
  let hidden = &hidden
  augroup VimspectorSwapExists
    au!
    autocmd SwapExists * let v:swapchoice='o'
  augroup END

  try
    set hidden
    for bufnr in keys( s:mapped )
      try
        execute 'buffer' bufnr

        silent! nunmap <silent> <buffer> <LocalLeader>1
        silent! nunmap <silent> <buffer> <LocalLeader>2
        silent! nunmap <silent> <buffer> <LocalLeader>3  
        silent! nunmap <silent> <buffer> <LocalLeader>4
        silent! nunmap <silent> <buffer> <LocalLeader>5
        silent! nunmap <silent> <buffer> <LocalLeader>6
        silent! nunmap <silent> <buffer> <LocalLeader>7
        silent! nunmap <silent> <buffer> <LocalLeader>8
        silent! nunmap <silent> <buffer> <LocalLeader>9

        let &l:modifiable = s:mapped[ bufnr ][ 'modifiable' ]
      endtry
    endfor
  finally
    execute 'noautocmd buffer' original_buf
    let &hidden = hidden
  endtry

  au! VimspectorSwapExists

  let s:mapped = {}
endfunction

augroup TestCustomMappings
  au!
  autocmd User VimspectorJumpedToFrame call s:OnJumpToFrame()
  autocmd User VimspectorDebugEnded ++nested call s:OnDebugEnd()
augroup END
