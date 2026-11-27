#!/bin/bash
# Runs as the desktop user; started by modules/cedilla.sh.
# Makes ' + c type ç (and ' + C type Ç) on the US international layout.

set -euo pipefail
trap 'printf "Cedilla: error on line %s.\n" "$LINENO" >&2' ERR

compose_file="$HOME/.XCompose"
include_pattern='^[[:space:]]*include[[:space:]]+"%L"'

# Key typed after the dead acute, the character it produces and its keysym.
rules=(
  'c ç ccedilla'
  'C Ç Ccedilla'
)

# When a sequence is defined twice, the last definition wins, and an include
# line can bring in a new one. So a rule only works if it comes after every
# include line and after any other definition of the same sequence.
rule_is_active() {
  local key="$1" char="$2" last_line rule_pattern
  last_line="$(grep -E "^[[:space:]]*(include[[:space:]]|<dead_acute>[[:space:]]+<$key>[[:space:]]*:)" "$compose_file" | tail -n 1 || true)"
  rule_pattern="^[[:space:]]*<dead_acute>[[:space:]]+<$key>[[:space:]]*:[[:space:]]*\"$char\""
  [[ "$last_line" =~ $rule_pattern ]]
}

# Without the locale's default table, some apps lose every other compose
# sequence. It goes first, so the existing rules still override it.
if ! grep -qE "$include_pattern" "$compose_file" 2> /dev/null; then
  existing=""
  if [[ -s "$compose_file" ]]; then
    existing="$(< "$compose_file")"
  fi
  # Write in place, so a symlinked file and its permissions are kept.
  {
    echo '# Load the default compose sequences for the current locale.'
    echo 'include "%L"'
    if [[ -n "$existing" ]]; then
      printf '\n%s\n' "$existing"
    fi
  } > "$compose_file"
fi

# Append only the rules that do not already win, so a new run adds nothing.
missing=()
for rule in "${rules[@]}"; do
  read -r key char keysym <<< "$rule"
  if ! rule_is_active "$key" "$char"; then
    missing+=("<dead_acute> <$key> : \"$char\" $keysym")
  fi
done

if [[ ${#missing[@]} -gt 0 ]]; then
  # Do not join the first rule to a last line without a newline.
  if [[ -n "$(tail -c 1 "$compose_file")" ]]; then
    echo >> "$compose_file"
  fi
  {
    echo
    echo "# Cedilla on the US international layout: ' + c = ç"
    printf '%s\n' "${missing[@]}"
  } >> "$compose_file"
fi

# Read back what was saved.
if ! grep -qE "$include_pattern" "$compose_file"; then
  printf 'Cedilla: %s does not include the default compose table.\n' "$compose_file" >&2
  exit 1
fi
for rule in "${rules[@]}"; do
  read -r key char _ <<< "$rule"
  if ! rule_is_active "$key" "$char"; then
    printf 'Cedilla: the rule for <dead_acute> <%s> is not the last one in %s.\n' "$key" "$compose_file" >&2
    exit 1
  fi
done
printf 'Saved compose rules in %s:\n' "$compose_file"
grep -nE "$include_pattern|^[[:space:]]*<dead_acute>[[:space:]]+<[cC]>" "$compose_file"

# IBus and GTK read these files before ~/.XCompose, which is then ignored.
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
for other_file in "$config_dir/ibus/Compose" "$config_dir/gtk-4.0/Compose" "$config_dir/gtk-3.0/Compose"; do
  if [[ -e "$other_file" ]]; then
    printf 'Warning: %s exists and may be read instead of %s. Add the same rules to it.\n' "$other_file" "$compose_file" >&2
  fi
done

# IBus loads the compose file when it starts. Without a user session to
# restart it in, the change applies at the next login.
if [[ -S "${XDG_RUNTIME_DIR:-}/bus" ]] && command -v ibus > /dev/null && ibus restart > /dev/null 2>&1; then
  echo "IBus restarted. Apps that do not use IBus apply the change when reopened."
else
  echo "Could not restart IBus from here. Log out and log back in to apply the cedilla rules."
fi
