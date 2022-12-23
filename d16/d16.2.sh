#! /usr/bin/env bash

set -eu

# Same as part1, but after calculating all the subproblems for a single person
# dynamic programming, we try to recombine pairs of compatible subproblems as
# if 2 people ran in parallel.

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
  declare -n heap="$1"
  declare -n costs="$2"
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
  declare -n heap="$1"
  declare -n costs="$2"
  local idx c uidx uc tmp
  idx=${#heap[@]}
  heap+=("$3")
  c=${costs[$3]}

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
  declare -a dheap
  declare -A vis
  declare -A dcosts
  dcosts["$s"]=0
  dheap+=("$s")
  while [[ "${#dheap[@]}" -gt 0 ]]; do
    hpop dheap dcosts
    v=$ret
    for c in ${edges[$v]}; do
      if [[ -z "${vis[$c]:-}" ]]; then
        vis[$c]=1
        dcosts["$c"]=$((${dcosts[$v]}+1))
        hinsert dheap dcosts "$c"
      fi
    done
  done
  for v in "${nvalves[@]}"; do
    distance["$s,$v"]=${dcosts[$v]}
  done
}

for s in "${nvalves[@]}"; do
  setdistance "$s"
done

# Assign index for each valve
declare -A v2i
full_vs=0
for ((i=0; i < ${#nvalves[@]}; ++i)); do
  v2i[${nvalves[$i]}]=$i
  full_vs=$(( full_vs | (1 << i) ))
done

declare -A vals
declare -A vsmax

vs=0 # bitset of valves we have visited
time=26
pressure=0
maxpressure=0
startt=$(printf '%(%s)T')
walk() {
  local v=$1
  local d db dc

  if [[ "$pressure" -lt "${vals[$vs,$v,$time]:-0}" ]]; then
    return
  fi
  vals[$vs,$v,$time]=$pressure
  if [[ "$pressure" -gt ${vsmax[$vs]:-0} ]]; then
    vsmax[$vs]=$pressure
  fi
  if [[ "$pressure" -gt "$maxpressure" ]]; then
    maxpressure=$pressure
    nowt=$(printf '%(%s)T')
    echo "$((nowt - startt)): max: vs=$vs $pressure">&2
  fi

  for d in "${nvalves[@]}"; do
    db=$(( 1 << ${v2i[$d]} ))
    if [[ $(( vs & db )) -ne 0 ]]; then
      continue
    fi
    dc=$(( ${distance[$v,$d]} + 1))
    if [[ "$dc" -gt "$time" ]]; then
      continue
    fi
    time=$((time - dc))
    pressure=$((pressure + time * ${rates[$d]}))
    [[ $(( vs & db)) -eq 0 ]]
    vs=$((vs | db))
    walk "$d"
    vs=$((vs ^ db))
    pressure=$((pressure - time * ${rates[$d]}))
    time=$((time + dc))
  done
}

vs=$((vs | (1 << ${v2i[AA]}) ))
walk AA

max2=0
aa=$((1 << ${v2i[AA]}))
for vs1 in "${!vsmax[@]}"; do
  v1=${vsmax[$vs1]}
  # It would probably be faster to enumerate the specific vs2s that compliment
  # vs1, but I'm lazy.
  for vs2 in "${!vsmax[@]}"; do
    if [[ $(( vs1 & vs2 )) -ne "$aa" ]]; then
      continue
    fi
    v2=${vsmax[$vs2]}
    total=$(( v1 + v2 ))
    if [[ "$total" -gt "$max2" ]]; then
      max2="$total"
      echo "max2: $total vs1=$vs1 vs2=$vs2 v1=$v1 v2=$v2">&2
    fi
  done
done

echo "$max3"
