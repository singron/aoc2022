#! /usr/bin/env bash

set -eu

hcycle=1
x=1
width=40
row=

clock() {
  hcycle=$((hcycle + 1))
  if [[ "$hcycle" -gt "$width" ]]; then
    hcycle=$((hcycle - width))
  fi
}

draw() {
  pos=$((hcycle-1))
  if [[ "$x" -ge $((pos - 1)) && "$x" -le $((pos + 1)) ]]; then
    row+='#'
  else
    row+='.'
  fi
  if [[ "$hcycle" = "$width" ]]; then
    echo "$row"
    row=
  fi
}

while read -r op amt; do
  case "$op" in
    noop)
      draw
      clock
      ;;
    addx)
      draw
      clock
      draw
      clock
      x=$((x + amt))
      ;;
    *)
      echo "Unknown op: $op">&2
      exit 1
      ;;
  esac
done
