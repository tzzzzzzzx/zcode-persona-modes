#!/usr/bin/env bash
# persona-modes: switchable agent modes (character cards) for ZCode.
# macOS / Linux engine — mirrors scripts/persona.ps1 (Windows PowerShell).
# Subcommands:
#   list            list all cards and the active mode
#   use <name>      activate a mode (prints the card body)
#   off             deactivate the current mode
#   current         print the active mode only
#   hook <event>    used by plugin hooks: event = sessionstart | prompt
# State file: ~/.zcode/persona-modes/state.json
# Cards live in <plugin-root>/modes/*.md; plugin root = parent of this script's dir.
# Install note: on macOS/Linux replace hooks/hooks.json content with
# hooks/hooks.mac-linux.json so hooks invoke this script via bash.

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(dirname "$SCRIPT_DIR")"
MODES_DIR="$PLUGIN_ROOT/modes"
STATE_DIR="$HOME/.zcode/persona-modes"
STATE_FILE="$STATE_DIR/state.json"
REMINDERS_FILE="$SCRIPT_DIR/reminders.txt"

get_active() {
    [ -f "$STATE_FILE" ] || return 0
    awk '/"active"/ {print; exit}' "$STATE_FILE" \
        | sed 's/.*:[[:space:]]*"//; s/"*[[:space:]]*,*[[:space:]]*$//'
}

frontmatter() {
    # print frontmatter block (without delimiters) of $1
    if head -n 1 "$1" | grep -q '^---[[:space:]]*$'; then
        sed -n '2,/^---$/p' "$1" | sed '$d'
    fi
}

card_body() {
    awk 'NR==1 { fm = ($0 ~ /^---[[:space:]]*$/) ? 1 : 0; if (!fm) print; next }
         fm==1 { if ($0 ~ /^---[[:space:]]*$/) fm = 2; next }
         { print }' "$1"
}

card_field() {
    # $1 = file, $2 = field name
    frontmatter "$1" | grep "^$2:" | head -n 1 | sed "s/^$2:[[:space:]]*//; s/[[:space:]]*$//"
}

card_name() {
    n=$(card_field "$1" 'name')
    [ -n "$n" ] || n=$(basename "$1" .md)
    printf '%s' "$n"
}

find_card() {
    # $1 = name; match frontmatter name or file slug
    for f in "$MODES_DIR"/*.md; do
        [ -e "$f" ] || return 0
        if [ "$(card_name "$f")" = "$1" ] || [ "$(basename "$f" .md)" = "$1" ]; then
            printf '%s' "$f"
            return 0
        fi
    done
}

set_active() {
    # $1 = mode name, empty = clear
    mkdir -p "$STATE_DIR"
    if [ -n "$1" ]; then
        printf '{\n  "active": "%s",\n  "activatedAt": "%s"\n}\n' "$1" "$(date -u +%Y-%m-%dT%H:%M:%S.%NZ 2>/dev/null || date +%s)" > "$STATE_FILE"
    else
        rm -f "$STATE_FILE"
    fi
}

escape_and_join() {
    # stdin -> single-line JSON-string-safe text
    awk '{ gsub(/\\/,"\\\\"); gsub(/"/,"\\\""); if (NR>1) printf "\\n"; printf "%s", $0 } END { printf "\n" }'
}

cmd_list() {
    active=$(get_active)
    [ -n "$active" ] && echo "active: $active" || echo "active: (none)"
    for f in "$MODES_DIR"/*.md; do
        [ -e "$f" ] || break
        n=$(card_name "$f"); d=$(card_field "$f" 'display_name'); e=$(card_field "$f" 'emoji'); ds=$(card_field "$f" 'description')
        echo "- $n | $d | $e | $ds"
    done
}

cmd_use() {
    [ -n "$1" ] || { echo 'ERR: usage: persona.sh use <name>'; exit 1; }
    f=$(find_card "$1")
    if [ -z "$f" ] || [ ! -e "$f" ]; then
        echo "ERR: mode not found: $1"
        echo 'run: persona.sh list'
        exit 1
    fi
    n=$(card_name "$f")
    set_active "$n"
    echo "=== mode activated: $n ==="
    echo "card file: $f"
    echo '--- card body: adopt this persona right now ---'
    card_body "$f"
}

cmd_hook() {
    active=$(get_active)
    [ -n "$active" ] || exit 0
    f=$(find_card "$active")
    [ -n "$f" ] && [ -e "$f" ] || exit 0
    d=$(card_field "$f" 'display_name'); [ -n "$d" ] || d=$active
    if [ "$1" = "sessionstart" ]; then
        esc=$( { printf '[persona-modes] Mode active: %s (%s). Adopt this persona for the whole session; all technical work stays accurate and professional. Full character card follows.\n\n' "$d" "$active"; card_body "$f"; } | escape_and_join )
        printf '{"additionalContext":"%s"}\n' "$esc"
    elif [ "$1" = "prompt" ]; then
        reminder=''
        if [ -f "$REMINDERS_FILE" ]; then
            lines=()
            while IFS= read -r l; do
                [ -n "$l" ] && lines+=("$l")
            done < "$REMINDERS_FILE"
            [ ${#lines[@]} -gt 0 ] && reminder=${lines[$((RANDOM % ${#lines[@]}))]}
        fi
        if [ -n "$reminder" ]; then
            esc=$(printf '[persona-modes] Mode active: %s (%s). %s Card: %s' "$d" "$active" "$reminder" "$f" | escape_and_join)
        else
            esc=$(printf '[persona-modes] Mode still active: %s (%s) - keep this persona and tone; technical content stays accurate. Card file: %s' "$d" "$active" "$f" | escape_and_join)
        fi
        printf '{"additionalContext":"%s"}\n' "$esc"
    fi
    exit 0
}

case "${1:-current}" in
    list)    cmd_list ;;
    use)     shift; cmd_use "${1:-}" ;;
    off)     set_active ''; echo '=== mode off: persona cleared, back to the default assistant style ===' ;;
    current) a=$(get_active); [ -n "$a" ] && echo "active: $a" || echo 'active: (none)' ;;
    hook)    shift; cmd_hook "${1:-}" ;;
    *)       echo 'usage: persona.sh <list | use <name> | off | current | hook <sessionstart|prompt>>'; exit 1 ;;
esac
