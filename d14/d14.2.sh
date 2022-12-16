#! /usr/bin/env bash

set -eu

lines=()
while read -r line; do
  if [[ -n "$line" ]]; then
    lines+=("$line")
  fi
done

minx=500
miny=0
maxx=500
maxy=0

segs=()

for line in "${lines[@]}"; do
  [[ "$line" =~ ([0-9]+),([0-9]+).* ]]
  sx=${BASH_REMATCH[1]}
  sy=${BASH_REMATCH[2]}
  line=${line:$(( ${#BASH_REMATCH[1]} + ${#BASH_REMATCH[2]} + 1 ))}

  if [[ "$sx" -gt "$maxx" ]]; then
    maxx=$sx
  fi
  if [[ "$sy" -gt "$maxy" ]]; then
    maxy=$sy
  fi
  if [[ "$sy" -lt "$miny" ]]; then
    miny=$sy
  fi
  if [[ "$sx" -lt "$minx" ]]; then
    minx=$sx
  fi

  while [[ -n "$line" ]]; do
    re=' -> ([0-9]+),([0-9]+).*'
    [[ "$line" =~ $re ]]
    ex=${BASH_REMATCH[1]}
    ey=${BASH_REMATCH[2]}

    if [[ "$ex" -gt "$maxx" ]]; then
      maxx=$ex
    fi
    if [[ "$ey" -gt "$maxy" ]]; then
      maxy=$ey
    fi
    if [[ "$ey" -lt "$miny" ]]; then
      miny=$ey
    fi
    if [[ "$ex" -lt "$minx" ]]; then
      minx=$ex
    fi

    segs+=("$sx,$sy,$ex,$ey")

    line=${line:$(( 4 + ${#BASH_REMATCH[1]} + ${#BASH_REMATCH[2]} + 1 ))}
    sx=$ex
    sy=$ey
  done
done

maxy=$((maxy + 2)) # for bottom line
maxx=$((500 + maxy + 2))
minx=$((500 - maxy - 2))

pwidth=$((maxx - minx + 1))

grid=()
for ((i=0; i < (maxx - minx + 1)*(maxy - miny + 1); ++i)); do
  grid[$i]=.
done
for ((x=minx; x <= maxx; ++x)); do
  y=$maxy
  i=$(( (x - minx) + pwidth * (y - miny) ))
  grid[$i]='#'
done

for seg in "${segs[@]}"; do
  [[ "$seg" =~ ([0-9]+),([0-9]+),([0-9]+),([0-9]+) ]]
  sx=${BASH_REMATCH[1]}
  sy=${BASH_REMATCH[2]}
  ex=${BASH_REMATCH[3]}
  ey=${BASH_REMATCH[4]}
  dx=0
  dy=0
  if [[ "$ex" -gt "$sx" ]]; then
    dx=1
  elif [[ "$ex" -lt "$sx" ]]; then
    dx=-1
  fi
  if [[ "$ey" -gt "$sy" ]]; then
    dy=1
  elif [[ "$ey" -lt "$sy" ]]; then
    dy=-1
  fi
  x=$sx
  y=$sy
  while [[ "$x" != "$ex" || "$y" != "$ey" ]]; do
    i=$(( (x - minx) + pwidth * (y - miny) ))
    grid[$i]='#'

    x=$((x + dx))
    y=$((y + dy))
  done
  i=$(( (x - minx) + pwidth * (y - miny) ))
  grid[$i]='#'
done

# Just for fun, print the grid.
print_grid() {
  ypad='   '
  lpos="v-- $minx"
  rpos="$maxx --v"
  padding=''
  while [[ ${#padding} -lt $(( pwidth - ${#lpos} - ${#rpos} )) ]]; do
    padding+=' '
  done
  echo "$ypad$lpos$padding$rpos"

  for ((y=$miny; y <= $maxy; ++y)); do
    o=''
    for ((x=$minx; x <= $maxx; ++x)); do
      i=$(( (x - minx) + pwidth * (y - miny) ))
      o+=${grid[$i]}
    done
    printf '%3d%s\n' "$y" "$o"
  done
  echo
}

off=
rest=0
while [[ -z "$off" ]]; do
  x=500
  y=0
  i=$(( (x - minx) + pwidth * (y - miny) ))
  if [[ "${grid[$i]}" != . ]]; then
    break
  fi
  while true; do
    ny=$((y + 1))
    found=
    for nx in $x $((x - 1)) $((x + 1)); do
      if [[ "$nx" -lt "$minx" || "$nx" -gt "$maxx" || "$ny" -gt "$maxy" ]]; then
        off=1
        break
      fi
      i=$(( (nx - minx) + pwidth * (ny - miny) ))
      if [[ "${grid[$i]}" = . ]]; then
        x=$nx
        y=$ny
        found=1
        break
      fi
    done
    if [[ -n "$off" ]]; then
      break
    fi
    if [[ -z "$found" ]]; then
      i=$(( (x - minx) + pwidth * (y - miny) ))
      grid[$i]='o'
      rest=$((rest + 1))
      if [[ $((rest % 1000)) = 0 ]]; then
        print_grid
      fi
      break
    fi
  done
done

print_grid

grid[$(( 500-minx ))]=+

echo "$rest"
