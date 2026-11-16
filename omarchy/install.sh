#!/usr/bin/env bash
# Install (or update) the Basecamp Live bar widget for Omarchy.
#
#   ./omarchy/install.sh               from a checkout
#   curl -fsSL https://raw.githubusercontent.com/zoltanhosszu/basecamp-live/main/omarchy/install.sh | bash
#   ./omarchy/install.sh --uninstall
set -euo pipefail

id="zoltanhosszu.basecamp-live"
repo="https://github.com/zoltanhosszu/basecamp-live.git"
dest="$HOME/.config/omarchy/plugins/$id"

fail() { echo "basecamp-live: $*" >&2; exit 1; }

command -v omarchy >/dev/null && command -v omarchy-shell >/dev/null ||
  fail "this installs a widget for the Omarchy shell, which wasn't found"

if [[ ${1:-} == "--uninstall" ]]; then
  omarchy plugin remove "$id" --yes
  exit 0
fi
[[ $# -eq 0 ]] || fail "usage: install.sh [--uninstall]"

# Use the widget beside this script when run from a checkout; otherwise
# (piped from curl) fetch the repo into a temporary directory.
src=""
script="${BASH_SOURCE[0]:-}"
if [[ -n $script && -f $script ]]; then
  here="$(cd "$(dirname "$script")" && pwd)"
  [[ -f $here/manifest.json ]] && src="$here"
fi
if [[ -z $src ]]; then
  command -v git >/dev/null || fail "git is needed to download the widget"
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  git clone --quiet --depth 1 "$repo" "$tmp/basecamp-live"
  src="$tmp/basecamp-live/omarchy"
fi

[[ $(jq -r .id "$src/manifest.json") == "$id" ]] || fail "$src doesn't hold the $id widget"

if [[ -L $dest ]]; then
  fail "$dest is a symlink (a development checkout?); remove it first"
fi

updating=0
[[ -d $dest ]] && updating=1

mkdir -p "$(dirname "$dest")"
rm -rf "$dest"
mkdir "$dest"
cp -r "$src"/. "$dest"/

omarchy-shell shell rescanPlugins >/dev/null 2>&1 || true

if omarchy plugin list --json | jq -e --arg id "$id" 'any(.[]; .id == $id and .enabled)' >/dev/null; then
  if (( updating )); then
    echo "Updated Basecamp Live."
  else
    echo "Installed Basecamp Live."
  fi
else
  omarchy plugin enable "$id" right >/dev/null
  echo "Installed Basecamp Live and added it to the right of your bar."
  echo "Move it with: omarchy bar move $id --section <left|centerBegin|centerEnd|right>"
fi
