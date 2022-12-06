#! /usr/bin/env bash

set -eu

read -r s

i=0
r=3
while true; do
  dup=
  for ((e=i+r; e > i; e--)); do
    if [[ "${s:$i:1}" = "${s:$e:1}" ]]; then
      i=$((i + 1))
      r=3
      dup=1
      break
    fi
  done
  if [[ -n "$dup" ]]; then
    continue
  fi
  r=$((r - 1))
  if [[ "$r" = 0 ]]; then
    echo "$((i+2))"
    break
  fi
  i=$((i + 1))
  if [[ "$i" -gt "${#s}" ]]; then
    echo 'Error'>&2
    exit 1
  fi
done
