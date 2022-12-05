#! /usr/bin/env bash

set -eu

for s in {1..9}; do
  declare -a "s$s"
done

while IFS= read -r line; do
  if [[ "$line" != *[* ]]; then
    break
  fi
  [[ $((${#line} % 4)) -eq 3 ]]
  for (( i=1; i < ${#line}; i=i+4 )); do
    c=${line:$i:1}
    if [[ -n "$c" && "$c" != ' ' ]]; then
      s=$((i / 4 + 1))
      declare -n tmp="s$s"
      tmp+=("$c")
    fi
  done
done

# Reverse stacks so top of stack is at end of array
for s in {1..9}; do
  declare -n tmp="s$s"
  for (( i=0; i < ${#tmp[@]}/2; i++ )); do
    ie=$(( ${#tmp[@]} - $i - 1 ))
    c=${tmp[$i]}
    tmp[$i]=${tmp[$ie]}
    tmp[$ie]=$c
  done
done

IFS= read -r line
[[ -z "$line" ]]

while IFS= read -r line; do
  re='move ([0-9]+) from ([0-9]+) to ([0-9]+)'
  [[ "$line" =~ $re ]]
  amt=${BASH_REMATCH[1]}
  src=${BASH_REMATCH[2]}
  dst=${BASH_REMATCH[3]}

  if [[ "$amt" -lt 1 ]]; then
    continue
  fi

  declare -n srca="s$src"
  declare -n dsta="s$dst"
  for (( ; amt > 0; amt-- )); do
    if [[ "${#srca[@]}" = 0 ]]; then
      echo "empty stack">&2
      exit 1
    fi
    idx=$(( ${#srca[@]} - 1))
    c=${srca[$idx]}
    dsta+=("$c")
    unset srca[$idx]
  done
done

o=''
for s in {1..9}; do
  declare -n tmp="s$s"
  o+=${tmp[$((${#tmp[@]} - 1))]}
done

echo "$o"
