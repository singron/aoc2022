#! /usr/bin/env bash

set -eu

cycle=1
x=1
checks=(20 60 100 140 180 220)
total=0

check() {
  for c in "${checks[@]}"; do
    if [[ "$cycle" = "$c" ]]; then
      total=$((total + cycle * x))
    fi
  done
}

while read -r op amt; do
  case "$op" in
    noop)
      cycle=$((cycle+1))
      check
      ;;
    addx)
      cycle=$((cycle+1))
      check

      x=$((x + amt))
      cycle=$((cycle+1))
      check
      ;;
    *)
      echo "Unknown op: $op">&2
      exit 1
      ;;
  esac
done

echo "$total"
