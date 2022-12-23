#! /usr/bin/env bash

set -eu

# Only 15 valves have non-zero pressure. We don't really care about passing
# through valves with zero pressure and can instead calculate end-to-end
# distance between non-zero valves. Traveling to and opening a valve takes at
# least 2 minutes, so we have to simulate at most 15 steps. Most traveling
# distances are more than 2 minutes, so in practice it's probably much better.

# 15 non-zero valves
# 15 steps
# (2**14 * 15) = 491520

# We run a dynamic programming on an objective function of (valve states,
# current position, remaining time).
#
# Total runtime is about 20 seconds.

declare -A edges
nvalves=()
valves=()
declare -A rates

while read -r line; do
  if [[ -z "$line" ]]; then
    continue
  fi
  re='Valve ([A-Z]+) has flow rate=([0-9]+); tunnels? leads? to valves? (.*)'
  [[ "$line" =~ $re ]]
  v=${BASH_REMATCH[1]}
  r=${BASH_REMATCH[2]}
  if [[ "$v" = AA || "$r" -gt 0 ]]; then
    nvalves+=("$v")
    rates[$v]=$r
  fi
  valves+=("$v")
  rest=${BASH_REMATCH[3]}
  dsts=()
  while [[ -n "$rest" ]]; do
    [[ "$rest" =~ ([A-Z]+)(,(.*))? ]]
    dsts+=("${BASH_REMATCH[1]}")
    rest=${BASH_REMATCH[3]}
  done
  edges["$v"]="${dsts[*]}"
done

hpop() {
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

hinsert() {
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
    heap[$uidx]=${heap[$idx]}
    heap[$idx]=$tmp

    idx=$uidx
  done
}

# end to end distance between non-zero valves
declare -A distance

setdistance() {
  local s=$1
  local v c
  declare -a heap
  declare -A vis
  declare -A costs
  costs["$s"]=0
  heap+=("$s")
  while [[ "${#heap[@]}" -gt 0 ]]; do
    hpop
    v=$ret
    for c in ${edges[$v]}; do
      if [[ -z "${vis[$c]:-}" ]]; then
        vis[$c]=1
        costs["$c"]=$((${costs[$v]}+1))
        hinsert "$c"
      fi
    done
  done
  for v in "${nvalves[@]}"; do
    distance["$s,$v"]=${costs[$v]}
  done
}

for s in "${nvalves[@]}"; do
  setdistance "$s"
done

# Assign index for each valve
declare -A v2i
for ((i=0; i < ${#nvalves[@]}; ++i)); do
  v2i[${nvalves[$i]}]=$i
done

declare -A vals

vs=0 # bitset of valves we have visited
time=30
pressure=0
maxpressure=0
walk() {
  local v=$1
  local vb=$(( 1 << ${v2i[$v]} ))
  local d db dc
  [[ $((vs & vb)) -eq 0 ]]
  vs=$((vs | vb))

  if [[ "$pressure" -lt "${vals[$vs,$v,$time]:-0}" ]]; then
    vs=$((vs ^ vb))
    return
  fi
  vals[$vs,$v,$time]=$pressure
  if [[ "$pressure" -gt maxpressure ]]; then
    maxpressure=$pressure
    echo "max: vs=$vs $pressure">&2
  fi

  for d in "${nvalves[@]}"; do
    db=$(( 1 << ${v2i[$d]} ))
    dc=$(( ${distance[$v,$d]} + 1))
    if [[ "$dc" -le "$time" && $(( vs & db )) -eq 0 ]]; then
      time=$((time - dc))
      pressure=$((pressure + time * ${rates[$d]}))
      walk "$d"
      pressure=$((pressure - time * ${rates[$d]}))
      time=$((time + dc))
    fi
  done

  vs=$((vs ^ vb))
}

walk AA

echo "$maxpressure"
