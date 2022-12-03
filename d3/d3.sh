#! /usr/bin/env bash

set -eu

letters=abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ
declare -A priorities
for (( i=0; i < ${#letters}; i+=1 )); do
  priorities[${letters:$i:1}]=$((i + 1))
done

total=0
while read -r line; do
  h=$(( ${#line} / 2 ))
  l=${line:0:$h}
  r=${line:$h}
  c=
  for (( i=0; i < ${#l}; i+=1 )); do
    if [[ "$r" = *${l:$i:1}* ]]; then
      c=${l:$i:1}
      break
    fi
  done
  total=$(( total + ${priorities[$c]} ))
done

echo "$total"
