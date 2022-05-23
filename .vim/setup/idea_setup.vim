## keybindings
#    - `:actionlist <actionid or keymap>` to search idea actions 
#    * `double shift` to search everything
#    * `C-M-O` to clear unused import
#    * `shift-F9` to debug the application
#    * `shift-F6` to rename
#    * `ctrl-F9` to hot load the application when debuging
#    * `alt-F12` open terminal
#
#    * <ctrl-alt-m> to extract a function
#    * <ctrl-alt-n> to inline a function    
  
" can not get these to work
" map \ <Action>(Tree-selectNextExtendSelection)
" nmap <M-p> <Action>(Tree-selectPreviousExtendSelection)

" nmap <Leader>si <Action>(ShowIntentionActions)
nmap sd <Action>(QuickJavaDoc)
nmap gr <Action>(FindUsages)
nmap gi <Action>(GotoImplementation)
nmap gd <Action>(GotoDeclaration)
nmap ]e <Action>(GotoNextError)
nmap [e <Action>(GotoPreviousError)
nmap <C-h> <Action>(Back)
nmap <C-l> <Action>(Forward)

nmap <Leader>gc <Action>(GenerateConstructor)
nmap <Leader>gg <Action>(GenerateGetter)
nmap <Leader>gs <Action>(GenerateSetter)
nmap <Leader>gi <Action>(OverrideMethods)
" nmap <Leader>gi <Action>(QuickImplementations)

nmap <Leader>rn <Action>(RenameElement)
nmap <Leader>rv <Action>(IntroduceVariable)
nmap <Leader>re <Action>(ExtractMethod)
nmap <Leader>ri <Action>(Inline)
nmap <Leader>rt <Action>(ChangeTypeSignature)

nmap <Leader>fn <Action>(NewClass)
nmap <Leader>ff <Action>(SelectIn)

nmap <Leader>gb <Action>(Annotate)

nmap <Leader>qr <Action>(RestartIde)
nmap <Leader>cc <Action>(ShowSettings)
nmap <Leader>tt <Action>(ActivateTerminalToolWindow)
nmap <C-M-O> <Action>(OptimizeImports)

nmap <Leader>db <Action>(ToggleLineBreakpoint)
nmap <Leader>dd <Action>(Debug)
nmap <Leader>dh <Action>(CompileDirty)
nmap \1 <Action>(StepOver)
nmap \2 <Action>(StepInto)
nmap \3 <Action>(Resume)


nmap <C-w>v <Action>(MoveTabRight)
nmap <C-w>s <Action>(MoveTabDown)
nmap <C-w>x <Action>(MoveEditorToOppositeTabGroup)
nmap <C-w>y <Action>(OpenEditorInOppositeTabGroup)
nmap <C-w>o <Action>(CloseAllEditorsButActive)
nmap <C-n> <Down>
nmap <C-p> <Up>

set idearefactormode=keep
set keep-english-in-normal-and-restore-in-insert
set commentary
" set ReplaceWithRegister
set argtextobj
set exchange
set textobj-indent

" set easymotion
" let g:EasyMotion_do_mapping = 0
" unmap <C-;>
" unmap <C-S-;>

