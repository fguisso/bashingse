# matrix.ps1 - Matrix-style terminal screensaver
# Usage: irm https://b.guisso.dev/matrix.ps1 | iex
#        powershell -NoProfile -File matrix.ps1 [DENSITY [TIMEOUT]]
#
# Env vars: MATRIX_DENSITY, MATRIX_TIMEOUT
# Press any key or Ctrl+C to exit.
# Requires PowerShell 7+ or Windows Terminal with ANSI support.

$density = if ($args.Count -gt 0) { [int]$args[0] } elseif ($env:MATRIX_DENSITY) { [int]$env:MATRIX_DENSITY } else { 30 }
$timeout = if ($args.Count -gt 1) { [int]$args[1] } elseif ($env:MATRIX_TIMEOUT) { [int]$env:MATRIX_TIMEOUT } else { 0 }

$esc  = [char]27
$C_GLOW = "$esc[1;97m"    # bright white  — head + rare sparks
$C_HOT  = "$esc[1;32m"    # bright green  — near-head zone
$C_MID  = "$esc[0;32m"    # green         — mid trail
$C_FADE = "$esc[2;32m"    # dim green     — fading tail
$C_DARK = "$esc[0;30m"    # dark grey     — tail end
$C_R    = "$esc[0m"       # reset

$chars = [char[]]'ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝ'

# Save terminal state
$origBg     = [Console]::BackgroundColor
$origFg     = [Console]::ForegroundColor
$origCursor = [Console]::CursorVisible

function Restore-Terminal {
    [Console]::Write("$esc[?25h")    # show cursor
    [Console]::Write("$esc[?1049l")  # exit alternate screen
    [Console]::BackgroundColor = $origBg
    [Console]::ForegroundColor = $origFg
    [Console]::CursorVisible   = $origCursor
    [Console]::ResetColor()
}

# Setup
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::Write("$esc[?1049h")   # enter alternate screen buffer
[Console]::Write("$esc[?25l")     # hide cursor
[Console]::BackgroundColor = [ConsoleColor]::Black
Clear-Host

$rng   = [System.Random]::new()
$start = [DateTime]::UtcNow

# --- Drop state ---
# Arrays: head row, trail length, speed, tick
$h   = [Console]::WindowHeight
$w   = [int]([Console]::WindowWidth / 2) - 1

$dropHead  = [int[]]::new($w)
$dropLen   = [int[]]::new($w)
$dropSpeed = [int[]]::new($w)
$dropTick  = [int[]]::new($w)

# Pre-seed drops already in progress for a natural start
for ($j = 0; $j -lt $w; $j++) {
    if ($rng.Next(2) -eq 0) {
        $dropHead[$j]  = $rng.Next($h)
        $dropLen[$j]   = $rng.Next(8, 22)
    } else {
        $dropHead[$j]  = -1
        $dropLen[$j]   = $rng.Next(8, 22)
    }
    $dropSpeed[$j] = $rng.Next(1, 4)
    $dropTick[$j]  = $rng.Next(3)
}

function Update-Drops {
    param($cols, $rows)
    for ($j = 0; $j -lt $cols; $j++) {
        $dropTick[$j]++
        if ($dropTick[$j] -lt $dropSpeed[$j]) { continue }
        $dropTick[$j] = 0

        if ($dropHead[$j] -eq -1) {
            if ($rng.Next(100) -lt $density) {
                $dropHead[$j]  = 0
                $dropLen[$j]   = $rng.Next(8, 22)
                $dropSpeed[$j] = $rng.Next(1, 4)
            }
        } else {
            $dropHead[$j]++
            if ($dropHead[$j] - $dropLen[$j] -ge $rows) {
                $dropHead[$j] = -1
            }
        }
    }
}

function Render-Frame {
    param($cols, $rows)
    $sb = [System.Text.StringBuilder]::new(($cols * $rows * 16))

    $null = $sb.Append("$esc[H")  # cursor home

    for ($i = 0; $i -lt $rows - 1; $i++) {
        for ($j = 0; $j -lt $cols; $j++) {
            $head = $dropHead[$j]

            if ($head -eq -1) {
                $null = $sb.Append('  ')
                continue
            }

            $delta   = $head - $i
            $trailLen = $dropLen[$j]

            if ($delta -lt 0 -or $delta -ge $trailLen) {
                $null = $sb.Append('  ')
            } elseif ($delta -eq 0) {
                # Head — bright white glow
                $c = $chars[$rng.Next($chars.Length)]
                $null = $sb.Append("${C_GLOW}${c} ${C_R}")
            } elseif ($delta -le 3) {
                # Hot zone — bright green
                $c = $chars[$rng.Next($chars.Length)]
                $null = $sb.Append("${C_HOT}${c} ${C_R}")
            } else {
                $halfLen = [int]($trailLen / 2)
                $c = $chars[$rng.Next($chars.Length)]
                if ($rng.Next(30) -eq 0) {
                    # Rare glow spark in trail
                    $null = $sb.Append("${C_GLOW}${c} ${C_R}")
                } elseif ($delta -le $halfLen) {
                    $null = $sb.Append("${C_MID}${c} ${C_R}")
                } elseif ($delta -lt $trailLen - 2) {
                    $null = $sb.Append("${C_FADE}${c} ${C_R}")
                } else {
                    $null = $sb.Append("${C_DARK}${c} ${C_R}")
                }
            }
        }
        if ($i -lt $rows - 2) { $null = $sb.Append("`n") }
    }

    [Console]::Write($sb.ToString())
}

try {
    while ($true) {
        # Timeout check
        if ($timeout -gt 0 -and ([DateTime]::UtcNow - $start).TotalSeconds -ge $timeout) { break }

        # Any key exits
        if ([Console]::KeyAvailable) {
            [Console]::ReadKey($true) | Out-Null
            break
        }

        # Adapt to terminal resize
        $newH = [Console]::WindowHeight
        $newW = [int]([Console]::WindowWidth / 2) - 1

        if ($newW -ne $w -or $newH -ne $h) {
            $h = $newH; $w = $newW
            $dropHead  = [int[]]::new($w)
            $dropLen   = [int[]]::new($w)
            $dropSpeed = [int[]]::new($w)
            $dropTick  = [int[]]::new($w)
            for ($j = 0; $j -lt $w; $j++) {
                $dropHead[$j]  = -1
                $dropLen[$j]   = $rng.Next(8, 22)
                $dropSpeed[$j] = $rng.Next(1, 4)
                $dropTick[$j]  = $rng.Next(3)
            }
            Clear-Host
        }

        Update-Drops -cols $w -rows $h
        Render-Frame -cols $w -rows $h
    }
} finally {
    Restore-Terminal
    Clear-Host
}
