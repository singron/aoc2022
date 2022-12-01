#! /usr/bin/env gawk -f
function endGroup() {
	maxes[4] = count;
	asort(maxes);
	maxes[1] = maxes[4];
	delete maxes[4];
	count = 0;
}

BEGIN { maxes[1]=0; maxes[2]=0; maxes[3]=0; count=0 }

/[0-9]+/ { count += $1 }

/^$/ { endGroup() }

END { endGroup(); print(maxes[1] + maxes[2] + maxes[3]) }
