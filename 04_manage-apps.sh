#!/bin/bash
# ============================================================
#  Workshop-Diy — App Manager
#  List apps, change status, update app.js
# ============================================================

APPJS="app.js"
GREEN='\033[0;32m'  YELLOW='\033[1;33m'  PURPLE='\033[0;35m'
RED='\033[0;31m'    CYAN='\033[0;36m'    BOLD='\033[1m'
DIM='\033[2m'       RESET='\033[0m'

# Check app.js exists
if [ ! -f "$APPJS" ]; then
  echo -e "${RED}Error: $APPJS not found. Run this script from the 'all' repo folder.${RESET}"
  exit 1
fi

# ─── Parse apps from app.js ───
get_apps() {
  python3 -c "
import re
with open('$APPJS') as f:
    block = f.read().split('const INLINE_APPS')[1].split('];')[0]
for line in block.split('\n'):
    m_name = re.search(r'name:\"([^\"]+)\"', line)
    m_cats = re.search(r'categories:\[([^\]]*)\]', line)
    m_status = re.search(r'status:\"([^\"]+)\"', line)
    if m_name and m_status:
        name = m_name.group(1)
        cats = m_cats.group(1).replace('\"','').replace(\"'\",\"\") if m_cats else 'tools'
        status = m_status.group(1)
        print(f'{name}|{cats}|{status}')
"
}

# ─── Color a status ───
color_status() {
  case "$1" in
    stable)  echo -e "${GREEN}stable${RESET}" ;;
    beta)    echo -e "${YELLOW}beta${RESET}" ;;
    dev)     echo -e "${PURPLE}dev${RESET}" ;;
    offline) echo -e "${RED}offline${RESET}" ;;
    *)       echo -e "${CYAN}${1}${RESET}" ;;
  esac
}

# ─── List all apps ───
list_apps() {
  echo ""
  echo -e "${BOLD}${CYAN}  #   App Name                 Category      Status${RESET}"
  echo -e "${DIM}  ──────────────────────────────────────────────────────${RESET}"
  local i=1
  while IFS='|' read -r name cat status; do
    local colored=$(color_status "$status")
    printf "  ${BOLD}%-3s${RESET} %-24s ${DIM}%-13s${RESET} %b\n" "$i" "$name" "$cat" "$colored"
    i=$((i + 1))
  done <<< "$(get_apps)"
  echo ""
}

# ─── Update a single app's status ───
update_status() {
  local app_name="$1"
  local new_status="$2"

  # Use perl (handles emoji/unicode safely unlike sed)
  perl -i -pe "s/(name:\"${app_name}\".*?status:\")[^\"]*\"/\${1}${new_status}\"/" "$APPJS"

  if grep -qF "name:\"${app_name}\"" "$APPJS" && grep -F "name:\"${app_name}\"" "$APPJS" | grep -qF "status:\"${new_status}\""; then
    echo -e "  ${GREEN}✓${RESET} ${BOLD}${app_name}${RESET} → $(color_status "$new_status")"
  else
    echo -e "  ${RED}✗ Failed to update ${app_name}${RESET}"
  fi
}

# ─── Scroll through all apps one by one ───
scroll_apps() {
  echo ""
  echo -e "  ${BOLD}${CYAN}Scroll through all apps${RESET}"
  echo -e "  ${DIM}Press Enter to skip, type a status to change, or 'q' to stop${RESET}"
  echo -e "  ${DIM}Valid: ${GREEN}stable${RESET} ${YELLOW}beta${RESET} ${PURPLE}dev${RESET} ${RED}offline${RESET} ${DIM}or any custom label${RESET}"
  echo -e "  ${DIM}──────────────────────────────────────────────────────${RESET}"
  echo ""

  local i=1
  local changed=0
  while IFS='|' read -r name cat status; do
    local colored=$(color_status "$status")
    printf "  ${BOLD}%-3s${RESET} %-24s ${DIM}%-13s${RESET} %b" "$i" "$name" "$cat" "$colored"

    # Read input on same line
    read -p "  → " input < /dev/tty

    input=$(echo "$input" | tr '[:upper:]' '[:lower:]' | xargs)

    if [ "$input" = "q" ] || [ "$input" = "quit" ]; then
      echo ""
      echo -e "  ${DIM}Stopped at #${i}${RESET}"
      break
    elif [ -n "$input" ]; then
      update_status "$name" "$input"
      changed=$((changed + 1))
    fi

    i=$((i + 1))
  done <<< "$(get_apps)"

  echo ""
  if [ "$changed" -gt 0 ]; then
    echo -e "  ${GREEN}✓ Updated ${BOLD}${changed}${RESET}${GREEN} app(s)${RESET}"
  else
    echo -e "  ${DIM}No changes made${RESET}"
  fi
  echo ""
}

# ─── Interactive menu ───
menu() {
  while true; do
    echo ""
    echo -e "${BOLD}${CYAN}  ╔══════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${CYAN}  ║     🛠️  Workshop-Diy App Manager     ║${RESET}"
    echo -e "${BOLD}${CYAN}  ╚══════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "  ${BOLD}1${RESET}) List all apps"
    echo -e "  ${BOLD}2${RESET}) Change app status"
    echo -e "  ${BOLD}3${RESET}) Bulk set status by category"
    echo -e "  ${BOLD}4${RESET}) Show summary"
    echo -e "  ${BOLD}5${RESET}) Add a new app"
    echo -e "  ${BOLD}6${RESET}) Scroll through all apps"
    echo -e "  ${BOLD}q${RESET}) Quit"
    echo ""
    read -p "  Choose: " choice

    case "$choice" in
      1) list_apps ;;
      2) change_status ;;
      3) bulk_status ;;
      4) summary ;;
      5) add_app ;;
      6) scroll_apps ;;
      q|Q) echo -e "\n  ${GREEN}Bye! 🚀${RESET}\n"; exit 0 ;;
      *) echo -e "  ${RED}Invalid choice${RESET}" ;;
    esac
  done
}

# ─── Pick status from menu ───
pick_status() {
  echo ""
  echo -e "  ${BOLD}Pick status:${RESET}"
  echo ""
  echo -e "    ${GREEN}stable${RESET}    ── fully working, tested, ready for users"
  echo -e "    ${YELLOW}beta${RESET}      ── works but may have rough edges or missing features"
  echo -e "    ${PURPLE}dev${RESET}       ── under active development, may not work yet"
  echo -e "    ${RED}offline${RESET}   ── temporarily down, broken, or deprecated"
  echo -e "    ${CYAN}custom${RESET}    ── type any label you want"
  echo ""
  read -p "  Type status name: " s
  s=$(echo "$s" | tr '[:upper:]' '[:lower:]' | xargs)
  case "$s" in
    stable|beta|dev|offline) echo "$s" ;;
    custom)
      read -p "  Enter custom status: " custom
      if [ -z "$custom" ]; then
        echo ""
      else
        echo "$custom"
      fi
      ;;
    "")  echo "" ;;
    *)
      # Accept any typed value as custom
      echo -e "  ${DIM}(using '${s}' as custom status)${RESET}" >&2
      echo "$s"
      ;;
  esac
}

# ─── Change single app status ───
change_status() {
  list_apps

  # Build array of app names
  mapfile -t names < <(get_apps | cut -d'|' -f1)
  local total=${#names[@]}

  read -p "  App number (1-$total): " num
  if [[ ! "$num" =~ ^[0-9]+$ ]] || [ "$num" -lt 1 ] || [ "$num" -gt "$total" ]; then
    echo -e "  ${RED}Invalid number${RESET}"
    return
  fi

  local app="${names[$((num - 1))]}"
  local current_status=$(get_apps | sed -n "${num}p" | cut -d'|' -f3)
  echo -e "\n  Selected: ${BOLD}${app}${RESET}  (currently $(color_status "$current_status"))"

  local new_status=$(pick_status)
  if [ -z "$new_status" ]; then
    echo -e "  ${RED}Cancelled${RESET}"
    return
  fi

  update_status "$app" "$new_status"
}

# ─── Bulk set status by category ───
bulk_status() {
  # Get unique categories
  mapfile -t cats < <(get_apps | cut -d'|' -f2 | sort -u)

  echo ""
  echo -e "  ${BOLD}Categories:${RESET}"
  for i in "${!cats[@]}"; do
    local count=$(get_apps | grep "|${cats[$i]}|" | wc -l)
    printf "    ${BOLD}%d${RESET}) %-15s ${DIM}(%d apps)${RESET}\n" "$((i + 1))" "${cats[$i]}" "$count"
  done
  echo ""
  read -p "  Category number: " cnum

  if [[ ! "$cnum" =~ ^[0-9]+$ ]] || [ "$cnum" -lt 1 ] || [ "$cnum" -gt "${#cats[@]}" ]; then
    echo -e "  ${RED}Invalid${RESET}"
    return
  fi

  local cat="${cats[$((cnum - 1))]}"
  echo -e "\n  All ${BOLD}${cat}${RESET} apps will be updated."

  local new_status=$(pick_status)
  if [ -z "$new_status" ]; then
    echo -e "  ${RED}Cancelled${RESET}"
    return
  fi

  echo ""
  while IFS='|' read -r name c s; do
    if [ "$c" = "$cat" ]; then
      update_status "$name" "$new_status"
    fi
  done <<< "$(get_apps)"
}

# ─── Summary ───
summary() {
  echo ""
  echo -e "  ${BOLD}${CYAN}Status Summary${RESET}"
  echo -e "  ${DIM}────────────────────${RESET}"

  local total=$(get_apps | wc -l)
  local stable=$(get_apps | grep '|stable$' | wc -l)
  local beta=$(get_apps | grep '|beta$' | wc -l)
  local dev=$(get_apps | grep '|dev$' | wc -l)
  local offline=$(get_apps | grep '|offline$' | wc -l)

  echo -e "  Total:   ${BOLD}${total}${RESET}"
  echo -e "  ${GREEN}Stable:  ${stable}${RESET}"
  echo -e "  ${YELLOW}Beta:    ${beta}${RESET}"
  echo -e "  ${PURPLE}Dev:     ${dev}${RESET}"
  echo -e "  ${RED}Offline: ${offline}${RESET}"

  echo ""
  echo -e "  ${BOLD}By Category:${RESET}"
  while IFS='|' read -r cat; do
    local count=$(get_apps | grep "|${cat}|" | wc -l)
    printf "    %-15s %d\n" "$cat" "$count"
  done <<< "$(get_apps | cut -d'|' -f2 | sort -u)"
  echo ""
}

# ─── Add a new app ───
add_app() {
  echo ""
  read -p "  App name (repo name): " name
  if [ -z "$name" ]; then echo -e "  ${RED}Cancelled${RESET}"; return; fi

  # Check if already exists
  if grep -q "name:\"${name}\"" "$APPJS"; then
    echo -e "  ${RED}App '${name}' already exists!${RESET}"
    return
  fi

  read -p "  Emoji: " emoji
  [ -z "$emoji" ] && emoji="🛠️"

  # Pick category
  mapfile -t cats < <(get_apps | cut -d'|' -f2 | sort -u)
  echo ""
  echo -e "  ${BOLD}Categories:${RESET}"
  for i in "${!cats[@]}"; do
    printf "    ${BOLD}%d${RESET}) %s\n" "$((i + 1))" "${cats[$i]}"
  done
  read -p "  Category number: " cnum
  local category="${cats[$((cnum - 1))]}"
  [ -z "$category" ] && category="tools"

  local new_status=$(pick_status)
  [ -z "$new_status" ] && new_status="dev"

  read -p "  Description (EN): " desc_en
  [ -z "$desc_en" ] && desc_en="${name} — explore and experiment!"

  read -p "  Tags (comma-separated): " tags_raw
  [ -z "$tags_raw" ] && tags_raw="${category},${name}"
  # Format tags as "tag1","tag2"
  local tags=$(echo "$tags_raw" | sed 's/[[:space:]]*,[[:space:]]*/","/g; s/^/"/; s/$/"/')

  # Build the app entry lines
  local line1="  { name:\"${name}\", emoji:\"${emoji}\", categories:[\"${category}\"], badge:\"new\", status:\"${new_status}\","
  local line2="    tags:[${tags}],"
  local line3="    desc:{ en:\"${desc_en}\", fr:\"${desc_en}\", ar:\"${desc_en}\" }},"

  # Insert before the first ]; (INLINE_APPS closing) using awk
  awk -v l1="$line1" -v l2="$line2" -v l3="$line3" -v done=0 \
    '/^];$/ && !done { print l1; print l2; print l3; done=1 } { print }' "$APPJS" > "${APPJS}.tmp" \
    && mv "${APPJS}.tmp" "$APPJS"

  if grep -q "name:\"${name}\"" "$APPJS"; then
    echo ""
    echo -e "  ${GREEN}✓${RESET} Added ${BOLD}${name}${RESET} to ${category} as $(color_status "$new_status")"
    echo -e "  ${DIM}Don't forget to create the repo: github.com/abourdim/${name}${RESET}"
  else
    echo -e "  ${RED}✗ Failed to add ${name}. Try adding it manually.${RESET}"
  fi
}

# ─── Start ───
menu
