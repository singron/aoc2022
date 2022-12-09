#! /usr/bin/env bash

set -eu

xs=()
ys=()
tails=9
for ((i=0; i <= tails; i++)); do
  xs+=(0)
  ys+=(0)
done

declare -A vis

total=0

while read -r dir amt; do
  for ((; amt > 0; --amt)); do
    case "$dir" in 
      U)
        ys[0]=$((ys[0]+1))
        ;;
      D)
        ys[0]=$((ys[0]-1))
        ;;
      L)
        xs[0]=$((xs[0]-1))
        ;;
      R)
        xs[0]=$((xs[0]+1))
        ;;
      *)
        echo "Unknown $dir">&2
        exit 1
        ;;
    esac

    for ((i=1; i <= tails; ++i)); do
      hx=${xs[$((i-1))]}
      hy=${ys[$((i-1))]}
      tx=${xs[$i]}
      ty=${ys[$i]}

      dx=$((hx - tx))
      dy=$((hy - ty))

      if [[ "$dy" -gt 0 ]]; then
        sy=1
      else
        sy=-1
      fi
      if [[ "$dx" -gt 0 ]]; then
        sx=1
      else
        sx=-1
      fi

      if [[ "$dy" -ge -1 && "$dy" -le 1 && "$dx" -ge -1 && "$dx" -le 1 ]]; then
        true # still
      elif [[ "$dx" -eq 0 ]]; then
        ys[$i]=$((ty + dy - sy)) # col
      elif [[ "$dy" -eq 0 ]]; then
        xs[$i]=$((tx + dx - sx)) # row
      else
        ys[$i]=$((ty + sy)) # diag
        xs[$i]=$((tx + sx))
      fi
    done

    tx=${xs[$tails]}
    ty=${ys[$tails]}

    if [[ -z "${vis["$tx,$ty"]:-}" ]]; then
      total=$((total+1))
      vis["$tx,$ty"]=1
    fi
  done
done

echo "$total"
