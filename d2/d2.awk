#! /usr/bin/env awk -f

BEGIN {
	x2a["X"]="A"
	x2a["Y"]="B"
	x2a["Z"]="C"
	shape["X"]=1
	shape["Y"]=2
	shape["Z"]=3
}

function outcome(o, p) {
	p = x2a[p];
	if (o == p) {
		return 3;
	}
	if ((o == "A" && p == "B") || (o == "B" && p == "C") || (o == "C" && p == "A")) {
		return 6;
	}
	return 0;
}

{ score += outcome($1, $2) + shape[$2] }

END { print(score) }
