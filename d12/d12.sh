#! /usr/bin/env bash

set -eu

declare -A onemore
alphabet='abcdefghijklmnopqrstuvwxyz{'
for ((i=0; i < 26; ++i)); do
  onemore[${alphabet:$i:1}]=${alphabet:$((i + 1)):1}
done

grid=()
sx=
sy=
ex=
ey=
y=0
while read -r line; do
  if [[ -z "$line" ]]; then
    continue
  fi
  grid+=("$line")
  for ((x=0; x < ${#line}; ++x)); do
    if [[ "${line:$x:1}" = S ]]; then
      sx=$x
      sy=$y
    elif [[ "${line:$x:1}" = E ]]; then
      ex=$x
      ey=$y
    fi
  done
  y=$((y + 1))
done
height=${#grid[@]}
width=${#grid[0]}

[[ -n "$sx" && -n "$sy" && -n "$ex" && -n "$ey" ]]

declare -A costs
costs["$sx,$sy"]=0
heap=("$sx,$sy")
declare -A vis
vis["$sx,$sy"]=1
ret=

#         0
#    1         2
#  3   4     5    6
# 7 8 9 10 11 12 13 14

pop() {
  local top last idx l r c lc rc tmp
  top=${heap[0]}
  last=$(( ${#heap[@]} - 1 ))
  heap[0]=${heap[$last]}
  unset heap[$last]

  idx=0
  while true; do
    if [[ "${#heap[@]}" = 0 ]]; then
      break
    fi

    l=$((2 * idx + 1))
    r=$((l + 1))

    if [[ "$l" -ge "${#heap[@]}" ]]; then
      break
    fi
    c=${costs[${heap[$idx]}]}
    lc=${costs[${heap[$l]}]}
    if [[ "$r" -ge "${#heap[@]}" && "$lc" -lt "$c" ]]; then
      tmp=${heap[$idx]}
      heap[$idx]=${heap[$l]}
      heap[$l]=$tmp
      break
    elif [[ "$r" -lt "${#heap[@]}" ]]; then
      rc=${costs[${heap[$r]}]}
      if [[ "$lc" -lt "$c" && "$lc" -le "$rc" ]]; then
        tmp=${heap[$idx]}
        heap[$idx]=${heap[$l]}
        heap[$l]=$tmp
        idx=$l
      elif [[ "$rc" -lt "$c" ]]; then
        tmp=${heap[$idx]}
        heap[$idx]=${heap[$r]}
        heap[$r]=$tmp
        idx=$r
      else
        break
      fi
    else
      break
    fi
  done

  ret=$top
}

insert() {
  local idx c uidx uc tmp
  idx=${#heap[@]}
  heap+=("$1")
  c=${costs[$1]}

  while [[ "$idx" -gt 0 ]]; do
    uidx=$(( (idx - 1)/2 ))
    uc=${costs[${heap[$uidx]}]}

    if [[ "$c" -ge "$uc" ]]; then
      break
    fi

    tmp=${heap[$uidx]}
    ${heap[$uidx]}=${heap[$idx]}
    ${heap[$idx]}=$tmp

    idx=$uidx
  done
}

while true; do
  [[ "${#heap[@]}" -gt 0 ]] || ( echo 'empty heap'; exit 1)
  pop
  x=${ret%,*}
  y=${ret#*,}
  if [[ "$x" = "$ex" && "$y" = "$ey" ]]; then
    echo "${costs["$x,$y"]}"
    break
  fi

  h=${grid[$y]:$x:1}
  if [[ "$h" = S ]]; then
    h=a
  fi
  hp=${onemore[$h]}
  for c in -1,0 1,0 0,-1 0,1; do
    cx=$(( ${c%,*} + x ))
    cy=$(( ${c#*,} + y ))
    if [[ "$cx" -ge "$width" || "$cx" -lt 0 || "$cy" -ge "$height" || "$cy" -lt 0 ]]; then
      continue
    fi
    cc="$cx,$cy"
    ch=${grid[$cy]:$cx:1}
    if [[ "$ch" = E ]]; then
      ch=z
    fi
    if [[ -z "${vis[$cc]:-}" && ( "$ch" < "$hp" || "$ch" = "$hp" ) ]]; then
      vis[$cc]=1
      costs[$cc]=$((${costs["$x,$y"]} + 1))
      insert "$cc"
    fi
  done
done
