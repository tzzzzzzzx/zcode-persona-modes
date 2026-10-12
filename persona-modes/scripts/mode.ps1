# persona-modes: switchable agent modes (character cards) for ZCode.
# Subcommands:
#   list            list all cards and the active mode
#   use <name>      activate a mode (prints the card body)
#   off             deactivate the current mode
#   current         print the active mode only
#   hook <event>    used by plugin hooks: event = sessionstart | prompt
# State file: ~/.zcode/persona-modes/state.json
# Cards live in <plugin-root>/modes/*.md; plugin root = parent of this script's dir.
# NOTE: keep string literals in this file ASCII-only. Localized text comes from
# the card files, which are always read with an explicit UTF-8 encoding.

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
    if ($m.Success) { return $m.Groups[1].Value }
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
    Write-Output ''
}

function Write-Usage {
    Write-Output 'usage: mode.ps1 <list | use <name> | off | current | hook <sessionstart|prompt>>'
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
            Write-Output 'ERR: usage: mode.ps1 use <name>'
            exit 1
        }
        $card = Find-Card $Arg
        if (-not $card) {
            Write-Output ("ERR: mode not found: " + $Arg)
            Write-Output 'run: mode.ps1 list'
            exit 1
        }
        $text = Get-Content -LiteralPath $card.FullName -Raw -Encoding UTF8
        $name = Get-CardField $text 'name'
        if (-not $name) { $name = $card.BaseName }
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
            $reminder = ''
            $remindersFile = Join-Path $PSScriptRoot 'reminders.txt'
            if (Test-Path -LiteralPath $remindersFile) {
                $lines = @(Get-Content -LiteralPath $remindersFile -Encoding UTF8 | Where-Object { $_.Trim() -ne '' })
                if ($lines.Count -gt 0) {
                    $reminder = $lines[(Get-Random -Minimum 0 -Maximum $lines.Count)]
                }
            }
            if ($reminder) {
                $header = "[persona-modes] Mode active: {0} ({1}). {2} Card: {3}" -f $display, $active, $reminder, $card.FullName
            } else {
                $header = "[persona-modes] Mode still active: {0} ({1}) - keep this persona and tone; technical content stays accurate. Card file: {2}" -f $display, $active, $card.FullName
            }
            Out-HookJson $header
        }
        exit 0
    }
    default {
        Write-Usage
        exit 1
    }
}
