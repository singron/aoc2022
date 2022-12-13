#! /usr/bin/env bash

set -eu

m_op_ops=()
m_op_args=()
m_tests=()
m_trues=()
m_falses=()
m_insps=()

declare -A item_worry
n_items=0

# Parse input
while read -r line; do
  re='Monkey ([0-9]+):'
  [[ "$line" =~ $re ]]
  m=${BASH_REMATCH[1]}

  read -r s1 s2 items
  [[ "$s1" = Starting && "$s2" = items: ]]
  declare -a "m_items_$m"
  declare -n tmp="m_items_$m"
  for i in $items; do
    [[ "$i" =~ ([0-9]+),? ]]
    w=${BASH_REMATCH[1]}
    it=$n_items
    n_items=$((n_items+1))
    item_worry[$it]=$w
    tmp+=("$it")
  done

  read -r s1 new eq old op arg
  [[ "$s1" = Operation: && "$new" = new && "$eq" = '=' && "$old" = old ]]
  [[ "$op" = '*' || "$op" = '+' ]]
  [[ "$arg" =~ [0-9]+ || "$arg" = old ]]
  m_op_ops+=( "$op" )
  m_op_args+=( "$arg" )

  read -r s1 s2 s3 div
  [[ "$s1 $s2 $s3" = 'Test: divisible by' ]]
  m_tests+=( "$div" )

  read -r s1 s2 s3 s4 s5 target
  [[ "$s1 $s2 $s3 $s4 $s5" = 'If true: throw to monkey' ]]
  m_trues+=("$target")

  read -r s1 s2 s3 s4 s5 target
  [[ "$s1 $s2 $s3 $s4 $s5" = 'If false: throw to monkey' ]]
  m_falses+=("$target")

  m_insps+=(0)

  if read -r s1; then
    [[ -z "$s1" ]]
  fi
done

monkeys=$(( m + 1 ))
rounds=10000

# At 10000 rounds and no worry decrease, the prompt hints that worry might get
# too large. I.e. either it will overflow or maybe a bignum would get too slow.
# The actual worry isn't important, just its divisibility in the tests. If we
# instead track worry mod lcm where lcm is some multiple of the divisibility
# tests, we should get the same result for monkey business.
#
# lcm isn't the least common multiple since I'm too lazy to do that.
lcm=1
for t in "${m_tests[@]}"; do
  lcm=$(( lcm * t ))
done

for ((round=0; round < rounds; ++round)); do
  for ((m=0; m < monkeys; ++m)); do
    declare -n tmp="m_items_$m"
    for it in "${tmp[@]}"; do
      m_insps[$m]=$(( ${m_insps[$m]} + 1 ))
      w=${item_worry[$it]}

      # Worry increase
      arg=${m_op_args[$m]}
      if [[ "$arg" = old ]]; then
        arg=$w
      fi
      op=${m_op_ops[$m]}
      case "$op" in
        '*')
          w=$((w * arg))
          ;;
        '+')
          w=$((w + arg))
          ;;
        *)
          echo "Unknown op $op">&2
          exit 1
          ;;
      esac

      # No worry decrease
      w=$(( w % lcm ))

      item_worry["$it"]=$w

      # Test
      if [[ $(( w % ${m_tests[$m]} )) = 0 ]]; then
        target=${m_trues[$m]}
      else
        target=${m_falses[$m]}
      fi

      # Throw
      declare -n dst="m_items_$target"
      dst+=("$it")
    done
    tmp=()
  done
done

max1=-1
max2=-1
for i in "${m_insps[@]}"; do
  if [[ "$i" -gt "$max2" ]]; then
    max2="$i"
    if [[ "$max2" -gt "$max1" ]]; then
      t=$max1
      max1=$max2
      max2=$t
    fi
  fi
done

echo $((max1 * max2))
