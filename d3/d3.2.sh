#! /usr/bin/env bash

set -eu

letters=abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ
declare -A priorities
for (( i=0; i < ${#letters}; i+=1 )); do
  priorities[${letters:$i:1}]=$((i + 1))
done

group=()
total=0
while read -r line; do
  group+=( "$line" )
  if [[ "${#group[@]}" = 3 ]]; then
    x=${group[0]}
    y=${group[1]}
    z=${group[2]}
    for (( i=0; i < ${#x}; i+=1 )); do
      c=${x:$i:1}
      if [[ "$y" = *${c}* && "$z" = *${c}* ]]; then
        break
      fi
    done
    total=$(( total + ${priorities[$c]} ))
    group=()
  fi
done

echo "$total"
