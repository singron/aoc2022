#! /usr/bin/env bash

set -eu

pwd=/
pwdnum=
nextdir=1
declare -A dnum
declare -A dsize

while read -r -a l; do
  if [[ "${l[0]}" == '$' && "${l[1]}" == 'cd' ]]; then
    t=${l[2]}
    if [[ "$t" = /* ]]; then
      pwd="$t"
    elif [[ "$t" = .. ]]; then
      pwd=${pwd%/*}
    else
      pwd="${pwd%/}/${t%/}"
    fi
  elif [[ "${l[0]}" == '$' && "${l[1]}" == 'ls' ]]; then
    if [[ -z "${dnum[$pwd]:-}" ]]; then
      pwdnum=$nextdir
      dnum[$pwd]=$pwdnum
      dsize[$pwdnum]=0
      declare -a "dirent_$pwdnum"
      nextdir=$(( nextdir + 1 ))
    else
      echo "Dup ls $pwd">&2
      exit 1
    fi
  elif [[ "${l[0]}" =~ [0-9]+ ]]; then
    dsize[$pwdnum]=$(( ${dsize[$pwdnum]:-0} + ${l[0]} ))
  elif [[ "${l[0]}" = dir ]]; then
    declare -n tmp=dirent_$pwdnum
    tmp+=("${l[1]}")
  else
    echo "Unknown ${l[*]}">&2
    exit 1
  fi
done

sizes=()

ret=

walk() {
  local size num pwd
  pwd=$1
  num=${dnum[$1]}
  size=${dsize[$num]}
  declare -n "tmp=dirent_$num"
  for sub in "${tmp[@]}"; do
    walk "${pwd%/}/$sub"
    size=$(( size + ret ))
  done
  sizes+=("$size")
  ret=$size
}

walk /

total=$ret
free=$((70000000 - total))
want=$((30000000 - free))

min=$total


for s in "${sizes[@]}"; do
  if [[ "$s" -lt "$min" && "$s" -ge "$want" ]]; then
    min="$s"
  fi
done

echo "$min"
