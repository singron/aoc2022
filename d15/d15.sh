#! /usr/bin/env bash

set -eu

# Each sensor defines a diamond shape area with a hole where no beacon can be
# present.
#
# In a given row, each shape can be decomposed into a line segment (or 2 line
# segments if it crosses a hole). Our question is what is the length of the
# union of these line segments?

ty=2000000
if [[ "${1:-}" = 'example' ]]; then
  ty=10
fi

segs=()

ret=
qcmp() {
  local l r
  l=${1%,*}
  r=${2%,*}
  if [[ "$l" -eq "$r" ]]; then
    ret=0
  elif [[ "$l" -lt "$r" ]]; then
    ret=-1
  else
    ret=1
  fi
}

qpartition() {
  local l r p lcmp rcmp tmp
  l=$1
  r=$2
  p=$3

  # Put the pivot at the beginning of the range
  tmp=${arr[$l]}
  arr[$l]=${arr[$p]}
  arr[$p]=$tmp
  p=$l
  l=$((l+1))

  while [[ "$l" != "$r" ]]; do
    qcmp "${arr[$l]}" "${arr[$p]}"
    lcmp=$ret
    if [[ "$lcmp" -le 0 ]]; then
      l=$((l + 1))
      continue
    fi
    while [[ "$l" != "$r" ]]; do
      qcmp "${arr[$r]}" "${arr[$p]}"
      rcmp=$ret
      if [[ "$rcmp" -ge 0 ]]; then
        r=$((r - 1))
        continue
      fi
      break
    done
    tmp=${arr[$l]}
    arr[$l]=${arr[$r]}
    arr[$r]=$tmp
  done

  # l == r, but we don't know what side of the pivot it belongs to.
  qcmp "${arr[$l]}" "${arr[$p]}"
  lcmp=$ret
  if [[ "$lcmp" -ge 0 ]]; then
    # swap pivot with previous item instead.
    l=$((l - 1))
  fi

  tmp=${arr[$l]}
  arr[$l]=${arr[$p]}
  arr[$p]=$tmp

  # Return pivot location
  ret=$l
}

qsort() {
  declare -n arr="$1"
  qsort_ 0 $(( ${#arr[@]} - 1 ))
}

qsort_() {
  local l r p tmp
  l=$1
  r=$2
  if [[ $((r - l)) -lt 1 ]]; then
    return
  elif [[ $((r - l)) -eq 1 ]]; then
    qcmp "${arr[$l]}" "${arr[$r]}"
    if [[ "$ret" -gt 0 ]]; then
      tmp=${arr[$l]}
      arr[$l]=${arr[$r]}
      arr[$r]=$tmp
    fi
    return
  fi
  p=$l
  qpartition "$l" "$r" "$p"
  p=$ret
  qsort_ "$l" $((p - 1))
  qsort_ $((p + 1)) "$r"
}

block_xs=()

while read -r line; do
  if [[ -z "$line" ]]; then
    continue
  fi
  re='Sensor at x=(-?[0-9]+), y=(-?[0-9]+): closest beacon is at x=(-?[0-9]+), y=(-?[0-9]+)'
  [[ "$line" =~ $re ]]
  sx=${BASH_REMATCH[1]}
  sy=${BASH_REMATCH[2]}
  bx=${BASH_REMATCH[3]}
  by=${BASH_REMATCH[4]}
  dx=$((bx - sx))
  dy=$((by - sy))
  if [[ "$dx" -lt 0 ]]; then
    dx=$(( -dx ))
  fi
  if [[ "$dy" -lt 0 ]]; then
    dy=$(( -dy ))
  fi
  d=$((dx + dy))
  dty=$((sy - ty))
  if [[ "$dty" -lt 0 ]]; then
    dty=$(( -dty ))
  fi
  rd=$((d - dty))
  l=$((sx - rd))
  r=$((sx + rd)) # inclusive
  if [[ "$by" -eq "$ty" ]]; then
    block_xs+=("$bx")
    if [[ "$l" -eq "$bx" ]]; then
      l=$((l + 1))
    fi
    if [[ "$r" -eq "$bx" ]]; then
      r=$((r - 1))
    fi
  fi
  if [[ $((r - l)) -lt 0 ]]; then
    continue
  fi
  segs+=("$l,$r")
done

for ((i=0; i < ${#segs[@]}; ++i)); do
  l=${segs[$i]%,*}
  r=${segs[$i]#*,}
  for bx in "${block_xs[@]}"; do
    if [[ "$bx" -ge "$l" && "$bx" -le "$r" ]]; then
      m1=$((bx - 1))
      m2=$((bx + 1))
      segs[$i]="$l,$m1"
      segs+=("$m2,$r")
      r="$m1"
    fi
  done
done

qsort segs

total=0
last=-99999999
for s in "${segs[@]}"; do
  l=${s%,*}
  r=${s#*,}
  if [[ "$r" -le "$last" ]]; then
    continue
  fi
  if [[ "$l" -le "$last" ]]; then
    total=$((total + r - last))
  else
    total=$((total + r - l + 1))
  fi
  last=$r
done

echo "$total"
