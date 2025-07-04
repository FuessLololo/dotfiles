# If not running interactively, don't do anything
case $- in
	    *i*) ;;
	          *) return;;
	  esac

	  if command -v tmux &>/dev/null && [ -z "$TMUX" ] && [ "$TERM" != "screen" ] && [ "$TERM_PROGRAM" != "vscode" ]; then
		              tmux attach-session -t default || tmux new-session -s default
	  fi


