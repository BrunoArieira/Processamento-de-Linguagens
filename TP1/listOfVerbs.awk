BEGIN		{ FS = "\t" }
$5 == "V"	{ verbs[$4]++ }
END		{ for (i in verbs) print i, "=", verbs[i] }	
