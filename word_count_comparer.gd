
var word_count_totals = {}

func compare(cname_a, cname_b):
	var wca = -1
	var wcb = -1
	# It's possible the character has no occurrence
	if word_count_totals.has(cname_a):
		wca = word_count_totals[cname_a]
	if word_count_totals.has(cname_b):
		wcb = word_count_totals[cname_b]
	# Tie break by name if word counts are equal
	if wca == wcb:
		return cname_a < cname_b
	# Highest word counts come first
	return wca > wcb
