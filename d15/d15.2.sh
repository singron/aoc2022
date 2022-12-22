#! /usr/bin/env bash

set -eu

# Each sensor defines a (diagonal) square shape. We are looking for a point
# inside the large bounding square that isn't covered by any of the sensor
# squares.
#
# We will proceed diagonally from the top left corner of the bounding box. We
# will sort the sensor squares by the distance of their closest side to
# diagonal line tangent to the top left corner. The idea is that once we
# process a square, we won't again process a square any closer. This means that
# if there are uncovered points closer than the square, they will never be
# covered.
#
# To track whether there are uncovered points, we will keep track of line
# segments tracking the expanding edge of covered points. If we process a
# square beyond the expanding edge, we know the uncovered point is in the gap.
# Otherwise, we edit the line segments to cover the newly covered points.

bbmin=0
bbmax=4000000
if [[ "${1:-}" = 'example' ]]; then
  bbmax=20
fi

ret=
qcmp() {
  local l r lb rb
  l=( $1 )
  r=( $2 )
  # Sort by y intersept of the closest edge.
  # y+x=b
  lb=$(( ${l[0]} + ${l[1]} ))
  rb=$(( ${r[0]} + ${r[1]} ))
  if [[ "$lb" -eq "$rb" ]]; then
    ret=0
  elif [[ "$lb" -lt "$rb" ]]; then
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

d=$((bbmax/2))
# We actually only need to track segments with slope -1.
segs=("$((bbmax - d )) $(( 0 - d )) $((0 - d)) $((bbmax - d))")
squares=()

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
  squares+=("$sx $((sy - d)) $((sx - d)) $sy $sx $((sy + d)) $((sx + d)) $sy")
done

qsort squares

echo "bbmax=$bbmax"

for s in "${squares[@]}"; do
  echo "square $s"
  s=($s)
  sx=${s[0]}
  sy=${s[1]}
  ex=${s[2]}
  ey=${s[3]}
  b1=$(( sx + sy )) # y intercept near edge
  b2=$(( ${s[4]} + ${s[5]} )) # y intercept far edge
  pb1=$(( sy - sx )) # y int top
  pb2=$(( ey - ex )) # y int bot
  echo "b1=$b1 b2=$b2 pb1=$pb1 pb2=$pb2"
  if [[ "$b2" -lt 0 ]]; then
    continue
  fi

  # edge after bounding box
  i=0
  while [[ "$i" -lt ${#segs[@]} ]]; do
    seg=(${segs[i]})
    echo "seg=${seg[*]}"
    sb=$(( ${seg[0]} + ${seg[1]} ))
    [[ "$sb" -eq $(( ${seg[2]} + ${seg[3]} )) ]]
    spb1=$(( ${seg[1]} - ${seg[0]} ))
    spb2=$(( ${seg[3]} - ${seg[2]} ))
    echo "sb=$sb spb1=$spb1 spb2=$spb2"
    [[ "$spb1" -le "$spb2" ]]
    if [[ "$spb1" -gt "$pb2" || "$pb1" -gt "$spb2" ]]; then
      echo no intersection
      i=$(( i + 1 ))
      continue
    fi
    if [[ "$sb" -gt "$b2" ]]; then
      echo line ahead
      i=$(( i + 1 ))
      continue
    fi
    if [[ "$spb1" -lt "$pb1" ]]; then
      # split seg
      d=$(( pb1 - spb1 ))
      if [[ $(( d % 2 )) = 0 ]]; then
        d2=$((d/2))
        out="${seg[0]} ${seg[1]} $(( ${seg[0]} - d2 + 1 )) $(( ${seg[1]} + d2 - 1))"
        out2="$(( ${seg[0]} - d2 + 1 )) $(( ${seg[1]} + d2)) $(( ${seg[0]} - d2 + 1 )) $(( ${seg[1]} + d2))"
        in="$(( ${seg[0]} - d2)) $(( ${seg[1]} + d2)) ${seg[2]} ${seg[3]}"
        echo "split top ${segs[i]} out=[$out] out2=[$out2] in=[$in]"
        segs[i]=$out
        segs+=("$out2")
        segs+=("$in")
        continue
      else
        # out in2 in

        # ...x...
        # ..x....
        # .x..#..
        # ...###.
        # ..#####
        # ...###.
        # ....#..
        
        # ...a...
        # ..cb...
        # .c..#..
        # ...###.
        # ..#####
        # ...###.
        # ....#..
        d2=$((d/2))
        out="${seg[0]} ${seg[1]} $(( ${seg[0]} - d2)) $(( ${seg[1]} + d2))"
        in2="$(( ${seg[0]} - d2)) $(( ${seg[1]} + d2 + 1)) $(( ${seg[0]} - d2)) $(( ${seg[1]} + d2 + 1))"
        in="$(( ${seg[0]} - d2 - 1)) $(( ${seg[1]} + d2 + 1)) ${seg[2]} ${seg[3]}"
        echo "split top ${segs[i]} out=[$out] in2=[$in2] in=[$in]"
        segs[i]=$out
        segs+=("$in2")
        segs+=("$in")
        continue
      fi
    fi
    if [[ "$spb2" -gt "$pb2" ]]; then
      d=$(( spb2 - pb2 ))
      if [[ $(( d % 2 )) = 0 ]]; then
        d2=$((d/2))
        in="${seg[0]} ${seg[1]} $(( ${seg[2]} + d2 )) $(( ${seg[3]} - d2 ))"
        out2="$(( ${seg[2]} + d2 )) $(( ${seg[3]} - d2 + 1)) $(( ${seg[2]} + d2 )) $(( ${seg[3]} - d2 + 1))"
        out="$(( ${seg[2]} + d2 - 1 )) $(( ${seg[3]} - d2 + 1 )) ${seg[2]} ${seg[3]}"
        echo "split bot ${segs[i]} out=[$out] out2=[$out2] in=[$in]"
        segs[i]=$out
        segs+=("$out2")
        segs+=("$in")
        continue
      else
        # ........
        # ...x....
        # ..x..#..
        # .x..###.
        # ...#####
        # ....###.
        # .....#..
        #
        # ........
        # ...c....
        # ..c..#..
        # .ab.###.
        # ...#####
        # ....###.
        # .....#..
        d2=$((d/2))
        in="${seg[0]} ${seg[1]} $(( ${seg[2]} + d2 + 1)) $(( ${seg[3]} - d2 - 1))"
        in2="$(( ${seg[2]} + d2 + 1)) $(( ${seg[3]} - d2)) $(( ${seg[2]} + d2 + 1 )) $(( ${seg[3]} - d2 ))"
        out="$(( ${seg[2]} + d2)) $(( ${seg[3]} - d2)) ${seg[2]} ${seg[3]}"
        echo "split bot ${segs[i]} out=[$out] in2=[$in2] in=[$in]"
        segs[i]=$out
        segs+=("$in2")
        segs+=("$in")
        continue
      fi
    fi

    d=$((b1 - sb))
    if [[ "$d" -gt 0 && (${seg[0]} -ge 0 && ${seg[0]} -le "$bbmax" && ${seg[1]} -ge 0 && ${seg[1]} -le "$bbmax") ]]; then
      echo "gap [${seg[@]}] [${s[@]}]"
      echo $(( ${seg[0]}*4000000 + ${seg[1]} ))
      exit 0
    fi

    d=$((b2 - sb))
    if [[ "$d" -gt 0 ]]; then
      echo advance
      d2=$((d/2))
      r=$((d % 2))
      # advance edge
      segs[i]="$(( ${seg[0]} + d2 + r )) $(( ${seg[1]} + d2 )) $(( ${seg[2]} + d2 )) $(( ${seg[3]} + d2 + r ))"
    fi
    i=$(( i + 1 ))
  done
  # advance line segments within bounding box
done

echo 'Did not find gap'>&2
exit 1
