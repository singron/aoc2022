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

ret=
get_vis() {
  local tx ty x y t tt n w e s
  tx=$1
  ty=$2
  tt=${grid[$ty]:$tx:1}

  e=0
  for ((x=tx+1; x < width; ++x)); do
    t=${grid[$ty]:$x:1}
    e=$((e+1))
    if [[ "$t" -ge "$tt" ]]; then
      break
    fi
  done

  w=0
  for ((x=tx-1; x >= 0; --x)); do
    t=${grid[$ty]:$x:1}
    w=$((w+1))
    if [[ "$t" -ge "$tt" ]]; then
      break
    fi
  done

  s=0
  for ((y=ty+1; y < height; ++y)); do
    t=${grid[$y]:$tx:1}
    s=$((s+1))
    if [[ "$t" -ge "$tt" ]]; then
      break
    fi
  done

  n=0
  for ((y=ty-1; y >= 0; --y)); do
    t=${grid[$y]:$tx:1}
    n=$((n+1))
    if [[ "$t" -ge "$tt" ]]; then
      break
    fi
  done

  ret=$((n * w * e * s))
}

max=0
for ((y=0; y < height; ++y)); do
  for ((x=0; x < width; ++x)); do
    get_vis "$x" "$y"
    if [[ "$ret" -gt "$max" ]]; then
      max=$ret
    fi
  done
done

echo "$max"
