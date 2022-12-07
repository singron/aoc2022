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

p1total=0
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
  if [[ "$size" -le 100000 ]]; then
    p1total=$(( p1total + size ))
  fi
  ret=$size
}

walk /

echo "$p1total"
