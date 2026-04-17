# Overrides on top of upstream p10k-lean.zsh.
# Wizard choices preserved: nerdfont-v3 + moderate icons, 2 lines, fluent prefixes,
# os_icon + time segments, nerdfont battery, sparse ruler.
# Regenerate the base via `p10k configure` or edit here.

'builtin' 'local' '-a' 'p10k_config_opts'
[[ ! -o 'aliases'         ]] || p10k_config_opts+=('aliases')
[[ ! -o 'sh_glob'         ]] || p10k_config_opts+=('sh_glob')
[[ ! -o 'no_brace_expand' ]] || p10k_config_opts+=('no_brace_expand')
'builtin' 'setopt' 'no_aliases' 'no_sh_glob' 'brace_expand'

() {
  emulate -L zsh -o extended_glob

  local p10k_base
  for p10k_base in \
    /opt/homebrew/share/powerlevel10k/config/p10k-lean.zsh \
    "$HOME/.local/share/powerlevel10k/config/p10k-lean.zsh"; do
    if [[ -r "$p10k_base" ]]; then
      source "$p10k_base"
      break
    fi
  done

  # --- Segment list ---
  typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
    os_icon dir vcs newline prompt_char
  )
  POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
    "${POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS[@]:#newline}"
    time
    newline
  )

  # --- Icons ---
  typeset -g POWERLEVEL9K_MODE=nerdfont-v3
  typeset -g POWERLEVEL9K_ICON_PADDING=moderate
  typeset -g POWERLEVEL9K_VCS_BRANCH_ICON='\uF126 '
  unset POWERLEVEL9K_BATTERY_STAGES
  typeset -g POWERLEVEL9K_BATTERY_STAGES='\UF008E\UF007A\UF007B\UF007C\UF007D\UF007E\UF007F\UF0080\UF0081\UF0082\UF0079'

  # --- Sparse ruler ---
  typeset -g POWERLEVEL9K_RULER_FOREGROUND=242
  typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_GAP_FOREGROUND=242

  # --- Fluent prefixes ---
  typeset -g POWERLEVEL9K_VCS_PREFIX='%fon '
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_PREFIX='%ftook '
  typeset -g POWERLEVEL9K_CONTEXT_PREFIX='%fwith '
  typeset -g POWERLEVEL9K_KUBECONTEXT_PREFIX='%fat '
  typeset -g POWERLEVEL9K_TOOLBOX_PREFIX='%fin '
  typeset -g POWERLEVEL9K_TIME_PREFIX='%fat '
}

(( ${#p10k_config_opts} )) && setopt ${p10k_config_opts[@]}
'builtin' 'unset' 'p10k_config_opts'
