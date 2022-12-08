#! /usr/bin/env bash

set -eu

grid=()
while read -r line; do
  grid+=("$line")
done

width="${#grid[0]}"
height="${#grid[@]}"

[[ "$width" -gt 1 ]]
[[ "$height" -gt 1 ]]

declare -A vis

for ((y=0; y < height; ++y)); do
  max=-1
  for ((x=0; x < width; ++x)); do
    t=${grid[$y]:$x:1}
    if [[ "$t" -gt "$max" ]]; then
      vis["$x,$y"]=1
      max="$t"
    fi
  done

  max=-1
  for ((x=width - 1; x >= 0; --x)); do
    t=${grid[$y]:$x:1}
    if [[ "$t" -gt "$max" ]]; then
      vis["$x,$y"]=1
      max="$t"
    fi
  done
done

for ((x=0; x < width; ++x)); do
  max=-1
  for ((y=0; y < height; ++y)); do
    t=${grid[$y]:$x:1}
    if [[ "$t" -gt "$max" ]]; then
      vis["$x,$y"]=1
      max="$t"
    fi
  done

  max=-1
  for ((y=height - 1; y >= 0; --y)); do
    t=${grid[$y]:$x:1}
    if [[ "$t" -gt "$max" ]]; then
      vis["$x,$y"]=1
      max="$t"
    fi
  done
done

total=0
for ((y=0; y < height; ++y)); do
  for ((x=0; x < width; ++x)); do
    if [[ -n "${vis["$x,$y"]:-}" ]]; then
      total=$((total + 1))
    fi
  done
done

echo "$total"
