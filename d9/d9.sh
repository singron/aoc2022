#! /usr/bin/env bash

set -eu

hx=0
hy=0
tx=0
ty=0

declare -A vis

total=0

while read -r dir amt; do
  for ((; amt > 0; --amt)); do
    case "$dir" in 
      U)
        hy=$((hy+1))
        ;;
      D)
        hy=$((hy-1))
        ;;
      L)
        hx=$((hx-1))
        ;;
      R)
        hx=$((hx+1))
        ;;
      *)
        echo "Unknown $dir">&2
        exit 1
        ;;
    esac

    dx=$((hx - tx))
    dy=$((hy - ty))

    if [[ "$dy" -gt 0 ]]; then
      ys=1
    else
      ys=-1
    fi
    if [[ "$dx" -gt 0 ]]; then
      xs=1
    else
      xs=-1
    fi

    if [[ "$dy" -ge -1 && "$dy" -le 1 && "$dx" -ge -1 && "$dx" -le 1 ]]; then
      true # still
    elif [[ "$dx" -eq 0 ]]; then
      ty=$((ty + dy - ys)) # col
    elif [[ "$dy" -eq 0 ]]; then
      tx=$((tx + dx - xs)) # row
    else
      ty=$((ty + ys)) # diag
      tx=$((tx + xs))
    fi

    if [[ -z "${vis["$tx,$ty"]:-}" ]]; then
      total=$((total+1))
      vis["$tx,$ty"]=1
    fi
  done
done

echo "$total"
