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

lines=('[[2]]' '[[6]]')

while read -r line; do
  if [[ -n "$line" ]]; then
    lines+=("$line")
  fi
done

ret=

partition() {
  local l r p lcmp rcmp tmp
  l=$1
  r=$2
  p=$3

  # Put the pivot at the beginning of the range
  tmp=${lines[$l]}
  lines[$l]=${lines[$p]}
  lines[$p]=$tmp
  p=$l
  l=$((l+1))

  while [[ "$l" != "$r" ]]; do
    pcmp "${lines[$l]}" "${lines[$p]}"
    lcmp=$ret
    if [[ "$lcmp" -le 0 ]]; then
      l=$((l + 1))
      continue
    fi
    while [[ "$l" != "$r" ]]; do
      pcmp "${lines[$r]}" "${lines[$p]}"
      rcmp=$ret
      if [[ "$rcmp" -ge 0 ]]; then
        r=$((r - 1))
        continue
      fi
      break
    done
    tmp=${lines[$l]}
    lines[$l]=${lines[$r]}
    lines[$r]=$tmp
  done

  # l == r, but we don't know what side of the pivot it belongs to.
  pcmp "${lines[$l]}" "${lines[$p]}"
  lcmp=$ret
  if [[ "$lcmp" -ge 0 ]]; then
    # swap pivot with previous item instead.
    l=$((l - 1))
  fi

  tmp=${lines[$l]}
  lines[$l]=${lines[$p]}
  lines[$p]=$tmp

  # Return pivot location
  ret=$l
}

pcmp() {
  lex "$1" t1s
  lex "$2" t2s

  i1=0
  i2=0
  w1=0
  w2=0
  d1=0
  d2=0
  ret=

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
        ret=-1
        break
      elif [[ "$t1" -gt "$t2" ]]; then
        ret=1
        break
      fi
      # equal numbers, continue
    elif [[ "$t1" = '[' && "$t2" = '[' ]]; then
      true
    elif [[ "$t1" = ']' && "$t2" = ']' ]]; then
      true
    elif [[ "$t1" = ']' && "$t2" != ']' ]]; then
      ret=-1
      break
    elif [[ "$t1" != ']' && "$t2" = ']' ]]; then
      ret=1
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
}


partition 0 "$(( ${#lines[@]} - 1 ))" 0 # pivot on '[[2]]'
p2=$ret
for ((i=p2+1; i < ${#lines[@]}; ++i)); do
  if [[ "${lines[$i]}" = '[[6]]' ]]; then
    p3=$i
    break
  fi
done

partition $((p2 + 1)) $(( ${#lines[@]} - 1 )) "$p3" # pivot on '[[6]]'
p3=$ret

echo $(((p2+1) * (p3+1)))
