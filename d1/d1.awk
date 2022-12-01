#! /usr/bin/env awk -f
function endGroup() {
	if (count > max) { max = count }
	count = 0;
}

BEGIN { max=0; count=0 }

/[0-9]+/ { count += $1 }

/^$/ { endGroup() }

END { endGroup(); print(max) }
