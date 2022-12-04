#! /usr/bin/env bash

set -eu

total=0
while read -r line; do
  [[ "$line" =~ ([0-9]+)-([0-9]+),([0-9]+)-([0-9]+) ]]
  a=${BASH_REMATCH[1]}
  b=${BASH_REMATCH[2]}
  c=${BASH_REMATCH[3]}
  d=${BASH_REMATCH[4]}
  if (( a <= d && b >= c )); then
    total=$((total + 1))
  fi
done
echo "$total"
