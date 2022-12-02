#! /usr/bin/env awk -f

BEGIN {
	shape["A"]=1
	shape["B"]=2
	shape["C"]=3
	outcome["X"]=0
	outcome["Y"]=3
	outcome["Z"]=6
}

function pick(l, o) {
	if (o == "Y") {
		return l;
	}
	if (o == "X") {
		if (l == "A") { return "C" }
		if (l == "B") { return "A" }
		if (l == "C") { return "B" }
	}
	if (o == "Z") {
		if (l == "A") { return "B" }
		if (l == "B") { return "C" }
		if (l == "C") { return "A" }
	}
	print("ERROR " l " " o)
	exit 1
}

{ score += outcome[$2] + shape[pick($1, $2)] }

END { print(score) }
