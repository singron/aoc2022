#! /usr/bin/env bash

set -eu

read -r s

# This is a little like the KMP string searching algorithm.
#
# https://en.wikipedia.org/wiki/Knuth%E2%80%93Morris%E2%80%93Pratt_algorithm
#
# Whenever we find a pair of duplicate characters within our window, we know
# that we can the advance the start of the window beyond the first duplicate
# (any less, and the pair are still in the window). This lets us potentially
# skip inputs and avoid some redundant searching.
#
# We search for duplicate pairs starting at the end of the window so we can
# maximize the size of these jumps.

n=14
i=0
j=$((i + n - 1))
while true; do
  dup=
  for ((e=i+n-1; e > j; e--)); do
    if [[ "${s:$j:1}" = "${s:$e:1}" ]]; then
      i=$((j + 1))
      j=$((i + n - 1))
      dup=1
      if [[ "$i" -gt "${#s}" ]]; then
        echo 'Error'>&2
        exit 1
      fi
      break
    fi
  done
  if [[ -n "$dup" ]]; then
    continue
  fi
  if [[ "$j" = "$i" ]]; then
    echo "$((i+n))"
    break
  fi
  j=$((j - 1))
done
