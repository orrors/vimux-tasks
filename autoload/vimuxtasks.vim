scriptencoding utf-8

" ==================================
" Default tasks.json file
let s:DefaultTasks='
\{
\  "tasks": [
\    {
\      "type": "shell",
\      "label": "Hello World",
\      "command": "echo Hello World!"
\    }
\  ]
\}'

" ==================================
" Load task files

function! s:LoadTasksJson() abort
  let tasksFile = '.vim/tasks.json'
  if filereadable(tasksFile)
    let json = readfile(tasksFile)
    let content = join(json, "\n")
    let tasks = json_decode(content)
    " TODO parse the json for valid content ?
    return tasks.tasks
  else
    return []
  endif
endfunction

function! s:LoadPackageJson() abort
  let json = readfile('package.json')
  if filereadable('yarn.lock')
    let node = 'yarn'
  elseif filereadable('pnpm-lock.yaml')
    let node = 'pnpm'
  else
    let node = 'npm'
  endif
  let content = join(json, "\n")
  let tasks = json_decode(content)

  let tasksArray = []
  for key in keys(tasks.scripts)
    let l:label = node . ': ' . key
    call add(tasksArray, {'label': l:label, 'command': node . ' run ' . key})
  endfor
  return tasksArray
endfunction

function! s:VimuxTasksSinkFZF(tasks, selection) abort
  if match(a:selection,'>>>>') == 0
    let l:select = a:selection[5:]
    let l:action = 'type'
  else
    let l:select = a:selection
    let l:action = 'run'
  endif
  for task in a:tasks
    if task.label ==# l:select
      if l:action ==# 'run'
        call VimuxRunCommand(task.command)
      else
        call VimuxOpenRunner()
        call VimuxSendText(task.command . ' ')
        call VimuxTmux('select-'.VimuxOption('VimuxRunnerType').' -t '.g:VimuxRunnerIndex)
      endif
      break
    endif
  endfor
endfunction

function! s:RunTaskFZF(tasks) abort
  let l:tasks = deepcopy(a:tasks)
  call fzf#run({
    \ 'source': map(l:tasks, {key, task -> task.label}) ,
    \ 'sink': function('s:VimuxTasksSinkFZF', [a:tasks]),
    \ 'options': "--prompt 'Run Task > ' --no-info '--bind=ctrl-l:execute@printf \">>>> \"@+accept' --header ':: \e[1;33mEnter\e[m Run command. \e[1;33mctrl-l\e[m Type command'",
    \ 'tmux': '-p40%,30%'})
endfunction

" ==================================
" Main Popup function

function! vimuxtasks#RunTasks() abort
  let tasks = s:LoadTasksJson()
  if len(tasks) == 0
    let tasks = [{ 'label': 'Generate tasks file', 'command': "cat > .vim/tasks.json <<< '" . s:DefaultTasks . "'" }]
  endif
  if index(VimuxOption('VimuxTaskAutodetect'), 'package.json') >= 0 && filereadable('package.json')
    let packageTasks = s:LoadPackageJson()
    call extend(tasks, packageTasks)
  endif

  if VimuxOption('VimuxTaksSelect') ==# 'tmux-fzf'
    call s:RunTaskFZF(tasks)
  endif
endfunction
