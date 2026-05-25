#!/usr/bin/env bash
# Toggle (or explicitly set) macOS notification/alert sounds.
# Output volume and UI sound effects are left untouched.
#
# Usage:
#   notif-sounds.sh           — toggle
#   notif-sounds.sh on        — enable (restore saved level, or 100)
#   notif-sounds.sh off       — disable
#   notif-sounds.sh status    — print current state

BACKUP="$HOME/.config/notif-volume-backup"
mkdir -p "$(dirname "$BACKUP")"

# ── helpers ──────────────────────────────────────────────────────────────────

get_alert() {
    osascript -e "set s to (get volume settings)" -e "return alert volume of s"
}

set_alert() {
    osascript -e "set volume alert volume $1" >/dev/null
}

notify() {
    # Posts a macOS banner so you can see the change without opening a terminal
    osascript -e "display notification \"$2\" with title \"Notification Sounds\" subtitle \"$1\""
}

do_off() {
    local current
    current=$(get_alert)
    if [ "$current" -eq 0 ]; then
        echo "Already off (alert volume is 0)."
        return
    fi
    echo "$current" > "$BACKUP"
    set_alert 0
    echo "Notification sounds OFF  (saved level: ${current}%)"
    notify "Disabled" "Alert volume muted — output volume unchanged"
}

do_on() {
    local target=100
    if [ -f "$BACKUP" ]; then
        target=$(cat "$BACKUP")
    fi
    set_alert "$target"
    echo "Notification sounds ON  (alert volume: ${target}%)"
    notify "Enabled" "Alert volume restored to ${target}%"
}

do_status() {
    local current
    current=$(get_alert)
    local output_vol
    output_vol=$(osascript -e "output volume of (get volume settings)")
    if [ "$current" -eq 0 ]; then
        echo "Notification sounds: OFF  (output volume: ${output_vol}%)"
    else
        echo "Notification sounds: ON   (alert volume: ${current}%  |  output volume: ${output_vol}%)"
    fi
}

do_toggle() {
    local current
    current=$(get_alert)
    if [ "$current" -gt 0 ]; then
        do_off
    else
        do_on
    fi
}

# ── main ─────────────────────────────────────────────────────────────────────

case "${1:-toggle}" in
    toggle|"")  do_toggle ;;
    on|enable)  do_on ;;
    off|disable) do_off ;;
    status)     do_status ;;
    *)
        echo "Usage: $(basename "$0") [toggle|on|off|status]"
        exit 1
        ;;
esac
