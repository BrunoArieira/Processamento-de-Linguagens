BEGIN		{ FS = "\t" ; var = 0 ; string = "" }
/<\/mwe>/	{ var = 0; words[tolower(string)]++ } 
var == 1	{ string = string" "$1 }
/<mwe /		{ var = 1; string = "" }
END 		{ for( i in words) print i,"=", words[i] }
