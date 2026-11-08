# persona-modes: switchable agent modes (character cards) for ZCode.
# Subcommands:
#   list            list all cards and the active mode
#   use <name>      activate a mode (prints the card body)
#   off             deactivate the current mode
#   current         print the active mode only
#   hook <event>    used by plugin hooks: event = sessionstart | prompt | pretool | toolfail
# State file: ~/.zcode/persona-modes/state.json
# Cards live in <plugin-root>/modes/*.md; plugin root = parent of this script's dir.
# NOTE: keep string literals in this file ASCII-only. Localized text lives in the
# UTF-8 data files (guidance.txt, reminders.txt) and the cards, always read with
# an explicit UTF-8 encoding. 0.3.0 rule: repeated hook injections give direction,
# never concrete material - see the header of guidance.txt.

param(
    [Parameter(Position = 0)]
    [string]$Sub = 'current',
    [Parameter(Position = 1)]
    [string]$Arg = ''
)

$ErrorActionPreference = 'Stop'
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}

$PluginRoot = Split-Path -Parent $PSScriptRoot
$ModesDir = Join-Path $PluginRoot 'modes'
$StateDir = Join-Path $HOME '.zcode\persona-modes'
$StateFile = Join-Path $StateDir 'state.json'
$GuardEveryN = 5

function Get-ActiveMode {
    if (-not (Test-Path -LiteralPath $StateFile)) { return $null }
    try {
        $state = Get-Content -LiteralPath $StateFile -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($state.active) { return [string]$state.active }
    } catch {}
    return $null
}

function Get-Cards {
    if (-not (Test-Path -LiteralPath $ModesDir)) { return @() }
    return @(Get-ChildItem -LiteralPath $ModesDir -Filter '*.md' -File | Sort-Object Name)
}

function Get-CardField {
    param([string]$Text, [string]$Field)
    $m = [regex]::Match($Text, '(?m)^' + [regex]::Escape($Field) + ':\s*(.+?)\s*$')
    if ($m.Success) {
        $v = $m.Groups[1].Value
        if ($v.Length -ge 2) {
            $first = $v[0]; $last = $v[$v.Length - 1]
            if (($first -eq '"' -and $last -eq '"') -or ($first -eq "'" -and $last -eq "'")) {
                $v = $v.Substring(1, $v.Length - 2)
            }
        }
        return $v
    }
    return ''
}

function Get-CardBody {
    param([string]$Text)
    $m = [regex]::Match($Text, '(?s)^---\s*?\r?\n.*?\r?\n---\s*?\r?\n?(.*)$')
    if ($m.Success) { return $m.Groups[1].Value.Trim() }
    return $Text.Trim()
}

function Find-Card {
    param([string]$Name)
    foreach ($card in (Get-Cards)) {
        $text = Get-Content -LiteralPath $card.FullName -Raw -Encoding UTF8
        $n = Get-CardField $text 'name'
        if (-not $n) { $n = $card.BaseName }
        if ($n -eq $Name -or $card.BaseName -eq $Name) { return $card }
    }
    return $null
}

function Set-ActiveMode {
    param([string]$Name)
    if (-not (Test-Path -LiteralPath $StateDir)) {
        New-Item -ItemType Directory -Path $StateDir -Force | Out-Null
    }
    if ($Name) {
        $obj = @{ active = $Name; activatedAt = (Get-Date).ToString('o') }
        $obj | ConvertTo-Json | Set-Content -LiteralPath $StateFile -Encoding UTF8
    } else {
        if (Test-Path -LiteralPath $StateFile) { Remove-Item -LiteralPath $StateFile -Force }
    }
}

function Out-HookJson {
    param([string]$Text)
    @{ additionalContext = $Text } | ConvertTo-Json -Compress
}

function Write-Usage {
    Write-Output 'usage: persona.ps1 <list | use <name> | off | current | hook <sessionstart|prompt|pretool|toolfail>>'
}

# Read one keyed line (key=<text>) from the UTF-8 guidance file.
function Get-GuidanceLine {
    param([string]$Key)
    $gf = Join-Path $PSScriptRoot 'guidance.txt'
    if (Test-Path -LiteralPath $gf) {
        foreach ($l in (Get-Content -LiteralPath $gf -Encoding UTF8)) {
            if ($l -match ('^' + [regex]::Escape($Key) + '=(.+)$')) { return $Matches[1] }
        }
    }
    return ''
}

function Test-Throttle {
    # Returns $true when the named throttle flag allows an emission now, and
    # records the new timestamp. $Name -> flag file .last-$Name; $Ms = window.
    param([string]$Name, [int]$Ms)
    $now = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
    $flag = Join-Path $StateDir ('.last-' + $Name)
    $last = [int64]0
    try { if (Test-Path -LiteralPath $flag) { [void][int64]::TryParse((Get-Content -LiteralPath $flag -Raw), [ref]$last) } } catch {}
    if ($now - $last -lt $Ms) { return $false }
    if (-not (Test-Path -LiteralPath $StateDir)) { New-Item -ItemType Directory -Path $StateDir -Force | Out-Null }
    Set-Content -LiteralPath $flag -Value $now -Encoding ASCII
    return $true
}

switch ($Sub) {
    'list' {
        $active = Get-ActiveMode
        if ($active) { Write-Output ("active: " + $active) }
        else { Write-Output 'active: (none)' }
        foreach ($card in (Get-Cards)) {
            $text = Get-Content -LiteralPath $card.FullName -Raw -Encoding UTF8
            $name = Get-CardField $text 'name'
            if (-not $name) { $name = $card.BaseName }
            $display = Get-CardField $text 'display_name'
            $emoji = Get-CardField $text 'emoji'
            $desc = Get-CardField $text 'description'
            Write-Output ("- {0} | {1} | {2} | {3}" -f $name, $display, $emoji, $desc)
        }
    }
    'use' {
        if (-not $Arg) {
            Write-Output 'ERR: usage: persona.ps1 use <name>'
            exit 1
        }
        $card = Find-Card $Arg
        if (-not $card) {
            Write-Output ("ERR: mode not found: " + $Arg)
            Write-Output 'run: persona.ps1 list'
            exit 1
        }
        $text = Get-Content -LiteralPath $card.FullName -Raw -Encoding UTF8
        $name = Get-CardField $text 'name'
        if (-not $name) { $name = $card.BaseName }
        if ($name -match '["\\]') {
            Write-Output ("ERR: mode name must not contain quotes or backslash (fix the card frontmatter): " + $name)
            exit 1
        }
        Set-ActiveMode $name
        Write-Output ("=== mode activated: {0} ===" -f $name)
        Write-Output ("card file: {0}" -f $card.FullName)
        Write-Output '--- card body: adopt this persona right now ---'
        Write-Output (Get-CardBody $text)
    }
    'off' {
        Set-ActiveMode ''
        Write-Output '=== mode off: persona cleared, back to the default assistant style ==='
    }
    'current' {
        $active = Get-ActiveMode
        if ($active) { Write-Output ("active: " + $active) }
        else { Write-Output 'active: (none)' }
    }
    'hook' {
        $active = Get-ActiveMode
        if (-not $active) { exit 0 }
        $card = Find-Card $active
        if (-not $card) { exit 0 }
        $text = Get-Content -LiteralPath $card.FullName -Raw -Encoding UTF8
        $display = Get-CardField $text 'display_name'
        if (-not $display) { $display = $active }
        if ($Arg -eq 'sessionstart') {
            $header = "[persona-modes] Mode active: {0} ({1}). Adopt this persona for the whole session; all technical work stays accurate and professional. Full character card follows." -f $display, $active
            Out-HookJson ($header + "`n`n" + (Get-CardBody $text))
        } elseif ($Arg -eq 'prompt') {
            # GUARD reminder once every Nth user message (persisted counter):
            # keeps the per-turn context tax low and stops same-shape text from
            # accumulating every turn (0.3.0).
            $count = 0
            $cf = Join-Path $StateDir '.guard-count'
            try { if (Test-Path -LiteralPath $cf) { [void][int64]::TryParse((Get-Content -LiteralPath $cf -Raw), [ref]$count) } } catch {}
            $count++
            if (-not (Test-Path -LiteralPath $StateDir)) { New-Item -ItemType Directory -Path $StateDir -Force | Out-Null }
            Set-Content -LiteralPath $cf -Value $count -Encoding ASCII
            $reminder = ''
            if (($count % $GuardEveryN) -eq 1) {
                $remindersFile = Join-Path $PSScriptRoot 'reminders.txt'
                if (Test-Path -LiteralPath $remindersFile) {
                    $lines = @(Get-Content -LiteralPath $remindersFile -Encoding UTF8 | Where-Object { $t = $_.Trim(); $t -ne '' -and -not $t.StartsWith('#') })
                    if ($lines.Count -gt 0) {
                        $reminder = $lines[(Get-Random -Minimum 0 -Maximum $lines.Count)]
                    }
                }
            }
            if ($reminder) {
                $header = "[persona-modes] Mode active: {0} ({1}). {2} Card: {3}" -f $display, $active, $reminder, $card.FullName
            } else {
                $header = "[persona-modes] Mode still active: {0} ({1}) - keep this persona and tone; technical content stays accurate. Card file: {2}" -f $display, $active, $card.FullName
            }
            Out-HookJson $header
        } elseif ($Arg -eq 'pretool') {
            # Scope guard (throttled): a short directive that keeps persona tone
            # OUT of tool-call arguments, file contents, code, and commands.
            # Directive only - no concrete lines to weave or quote (0.3.0).
            if (-not (Test-Throttle -Name 'flavor' -Ms 90000)) { exit 0 }
            $line = Get-GuidanceLine -Key 'scope'
            if (-not $line) { $line = 'Persona tone applies to chat replies only; keep it out of tool-call arguments, file contents, code, and commands.' }
            Out-HookJson ("[persona-modes] " + $line)
        } elseif ($Arg -eq 'toolfail') {
            # Dry factual reminder after a failed tool call (throttled): failure
            # windows are the most fragile moments for decoding - keep it short,
            # impersonal, and never stack repeats (0.3.0).
            if (-not (Test-Throttle -Name 'toolfail' -Ms 120000)) { exit 0 }
            $line = Get-GuidanceLine -Key 'toolfail'
            if (-not $line) { $line = 'The last tool call failed. State the facts first: cause, impact, next step. Stay dry; do not dramatize.' }
            Out-HookJson ("[persona-modes] " + $line)
        }
        exit 0
    }
    default {
        Write-Usage
        exit 1
    }
}
