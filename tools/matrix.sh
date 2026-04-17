#!/usr/bin/env bash
#
# matrix: matrix-style terminal screensaver
# Usage: bash matrix.sh [DENSITY [TIMEOUT]]
#        curl -fsSL https://b.guisso.dev/matrix.sh | bash -s -- [DENSITY [TIMEOUT]]
#
# DENSITY  drop chance per column/frame (1-100, default 30)
# TIMEOUT  auto-exit after N seconds (0 = forever, default 0)
#
# Env vars: MATRIX_DENSITY, MATRIX_TIMEOUT
# Press any key or Ctrl+C to exit.

### Customization
_C_GLOW="\033[1;97m"    # bright white    — head + rare sparks
_C_HOT="\033[1;32m"     # bright green    — near-head zone
_C_MID="\033[0;32m"     # green           — mid trail
_C_FADE="\033[2;32m"    # dim green       — fading tail
_C_DARK="\033[0;30m"    # dark grey       — tail end
_C_R="\033[0m"          # reset
### End customization

_chars=(ｱ ｲ ｳ ｴ ｵ ｶ ｷ ｸ ｹ ｺ ｻ ｼ ｽ ｾ ｿ ﾀ ﾁ ﾂ ﾃ ﾄ ﾅ ﾆ ﾇ ﾈ ﾉ ﾊ ﾋ ﾌ ﾍ ﾎ ﾏ ﾐ ﾑ ﾒ ﾓ ﾔ ﾕ ﾖ ﾗ ﾘ ﾙ ﾚ ﾛ ﾜ ﾝ)
_count=${#_chars[@]}

if [[ "${1:-}" =~ ^(-h|--help) ]]; then
    cat <<'EOF'
matrix - Matrix-style terminal screensaver

Usage:  matrix [DENSITY [TIMEOUT]]
        curl -fsSL https://b.guisso.dev/matrix.sh | bash -s -- [DENSITY [TIMEOUT]]

  DENSITY   Drop density (1-100, higher = more drops, default 30)
  TIMEOUT   Auto-exit after N seconds (0 = forever, default 0)

Env vars: MATRIX_DENSITY, MATRIX_TIMEOUT
Press any key or Ctrl+C to exit.
EOF
    exit 0
fi

_density=${1:-${MATRIX_DENSITY:-30}}
_timeout=${2:-${MATRIX_TIMEOUT:-0}}

# --- Cleanup ---
_cleanup() {
    trap - EXIT SIGTERM SIGINT SIGHUP
    kill "$_key_pid" 2>/dev/null || true
    tput rmcup 2>/dev/null || true
    tput cnorm 2>/dev/null || true
    tput sgr0
    stty echo 2>/dev/null || true
}
trap '_cleanup; exit' SIGTERM SIGINT SIGHUP
trap _cleanup EXIT

# --- Terminal setup ---
tput smcup 2>/dev/null || true
tput civis 2>/dev/null || true
stty -echo 2>/dev/null || true
clear

# --- Dimensions ---
_lines=0; _cols=0
_get_size() {
    _lines=$(tput lines)
    _cols=$(( $(tput cols) / 2 - 1 ))
}
_get_size

# --- Key listener (works when stdin is a pipe) ---
(
    read -r -s -n1 </dev/tty 2>/dev/null || sleep 86400
    kill -INT $$
) &
_key_pid=$!

# --- Drop state (one entry per logical column) ---
# _hd[j] = head row (-1 = inactive)
# _tl[j] = trail length
# _sp[j] = speed (frames between row advances, 1-3)
# _tk[j] = tick counter
declare -a _hd _tl _sp _tk

_init_drops() {
    for (( j = 0; j < _cols; j++ )); do
        # Pre-seed some drops already in progress for a natural start
        if (( RANDOM % 2 )); then
            _hd[j]=$(( RANDOM % _lines ))
            _tl[j]=$(( RANDOM % 14 + 8 ))
        else
            _hd[j]=-1
            _tl[j]=$(( RANDOM % 14 + 8 ))
        fi
        _sp[j]=$(( RANDOM % 3 + 1 ))
        _tk[j]=$(( RANDOM % 3 ))
    done
}
_init_drops

trap '_get_size; _init_drops' SIGWINCH

# --- Update: advance drops by one frame ---
_update_drops() {
    local j
    for (( j = 0; j < _cols; j++ )); do
        (( _tk[j]++ ))
        if (( _tk[j] < _sp[j] )); then continue; fi
        _tk[j]=0

        if (( _hd[j] == -1 )); then
            if (( RANDOM % 100 < _density )); then
                _hd[j]=0
                _tl[j]=$(( RANDOM % 14 + 8 ))
                _sp[j]=$(( RANDOM % 3 + 1 ))
            fi
        else
            (( _hd[j]++ ))
            # Deactivate once the entire trail has scrolled past the bottom
            if (( _hd[j] - _tl[j] >= _lines )); then
                _hd[j]=-1
            fi
        fi
    done
}

# --- Render: draw every cell this frame ---
_render() {
    printf "\033[H"  # cursor home (faster than tput cup 0 0)
    local i j delta half_tl char

    for (( i = 0; i < _lines - 1; i++ )); do
        for (( j = 0; j < _cols; j++ )); do

            if (( _hd[j] == -1 )); then
                printf "  "
                continue
            fi

            delta=$(( _hd[j] - i ))

            if (( delta < 0 || delta >= _tl[j] )); then
                # Outside the drop — blank (clears old content)
                printf "  "
            elif (( delta == 0 )); then
                # Head — bright white glow
                char=${_chars[$RANDOM % _count]}
                printf "${_C_GLOW}${char} ${_C_R}"
            elif (( delta <= 3 )); then
                # Hot zone — bright green, characters changing fast
                char=${_chars[$RANDOM % _count]}
                printf "${_C_HOT}${char} ${_C_R}"
            else
                half_tl=$(( _tl[j] / 2 ))
                char=${_chars[$RANDOM % _count]}
                if (( RANDOM % 30 == 0 )); then
                    # Rare glow spark anywhere in the trail
                    printf "${_C_GLOW}${char} ${_C_R}"
                elif (( delta <= half_tl )); then
                    # Mid trail — steady green
                    printf "${_C_MID}${char} ${_C_R}"
                elif (( delta < _tl[j] - 2 )); then
                    # Fading — dim green
                    printf "${_C_FADE}${char} ${_C_R}"
                else
                    # Tail end — near black
                    printf "${_C_DARK}${char} ${_C_R}"
                fi
            fi
        done
        printf "\n"
    done
}

# --- Main loop ---
_start=$SECONDS
while true; do
    if (( _timeout > 0 && SECONDS - _start >= _timeout )); then break; fi
    _update_drops
    _render
done
