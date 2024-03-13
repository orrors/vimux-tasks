# Check if vimux is loaded
if !g:loaded_vimux
  finish
endif

" Set up all global options with defaults right away, in one place
let g:VimuxTasksSelect    = get(g:, 'VimuxTasksSelect', 'tmux-fzf')
let g:VimuxTaskAutodetect = get(g:, 'VimuxTaskAutodetect',   [ 'package.json' ])

command -nargs=0 VimuxTasks :call vimux#RunTasks()

