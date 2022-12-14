#! /usr/bin/env bash

set -eu

lex() {
  local s="$1"
  local i=0
  declare -n dst="$2"
  dst=()
  while ((i < ${#s})); do
    if [[ "${s:$i}" =~ ([0-9]+|\[|\]).* ]]; then
      dst+=("${BASH_REMATCH[1]}")
      i=$((i + ${#BASH_REMATCH[1]}))
    elif [[ "${s:$i}" =~ ,.* ]]; then
      i=$((i + 1))
    else
      echo "Unknown string $s">&2
      exit 1
    fi
  done
}

total=0
pair_idx=0

while true; do
  pair_idx=$((pair_idx+1))
  read -r l1 || break
  read -r l2
  [[ -n "$l1" && -n "$l2" ]]

  lex "$l1" t1s
  lex "$l2" t2s

  i1=0
  i2=0
  w1=0
  w2=0
  d1=0
  d2=0

  while true; do
    t1=${t1s[$i1]}
    t2=${t2s[$i2]}
    if [[ "$d1" = 0 && "$w1" -gt 0 ]]; then
      w1=$((w1-1))
      t1=']'
      i1=$((i1 - 1)) # does this work with continue?
    fi
    if [[ "$d2" = 0 && "$w2" -gt 0 ]]; then
      w2=$((w2-1))
      t2=']'
      i2=$((i2 - 1))
    fi
    if [[ "$d1" -gt 0 ]]; then
      d1=$((d1 - 1))
    fi
    if [[ "$d2" -gt 0 ]]; then
      d2=$((d2 - 1))
    fi

    if [[ "$t1" =~ [0-9]+ && "$t2" =~ [0-9]+ ]]; then
      if [[ "$t1" -lt "$t2" ]]; then
        total=$((total + pair_idx))
        break
      elif [[ "$t1" -gt "$t2" ]]; then
        break
      fi
      # equal numbers, continue
    elif [[ "$t1" = '[' && "$t2" = '[' ]]; then
      true
    elif [[ "$t1" = ']' && "$t2" = ']' ]]; then
      true
    elif [[ "$t1" = ']' && "$t2" != ']' ]]; then
      total=$((total + pair_idx))
      break
    elif [[ "$t1" != ']' && "$t2" = ']' ]]; then
      break
    elif [[ "$t1" =~ [0-9]+ ]]; then
      [[ "$t2" = '[' ]]
      w1=$((w1 + 1))
      d1=$((d1 + 1))
      i2=$((i2+1))
      continue
    elif [[ "$t2" =~ [0-9]+ ]]; then
      [[ "$t1" = '[' ]]
      w2=$((w2 + 1))
      d2=$((d2 + 1))
      i1=$((i1+1))
      continue
    fi

    i1=$((i1+1))
    i2=$((i2+1))
  done

  if read -r l3; then
    [[ -z "$l3" ]]
  else
    break
  fi
done

echo "$total"
